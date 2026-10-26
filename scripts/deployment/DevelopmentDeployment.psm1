Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:RepositoryRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Import-Module (Join-Path $PSScriptRoot 'GameplayArtifact.psm1')
$script:PublishOrder = @('Session','Infinite','Clash','Entry')

function Invoke-DevelopmentValidation {
    param([string]$ValidationScript = (Join-Path $script:RepositoryRoot 'scripts/Validate-Project.ps1'))
    # The regression suite imports this publisher itself. A separate process
    # prevents that re-entry from rebinding the active module's script scope.
    $PSNativeCommandUseErrorActionPreference = $false
    & (Join-Path $PSHOME 'pwsh') -NoProfile -NonInteractive -File $ValidationScript
    if ($LASTEXITCODE -ne 0) { throw "Development validation failed with exit code $LASTEXITCODE. Nothing published." }
}

function Get-DevelopmentConfiguration {
    param([string]$UniverseId, [string]$PlaceId, [string]$SessionPlaceId, [string]$InfinitePlaceId, [string]$ClashPlaceId)
    $values = [ordered]@{
        ROBLOX_DEV_UNIVERSE_ID = $UniverseId; ROBLOX_DEV_PLACE_ID = $PlaceId
        ROBLOX_DEV_SESSION_PLACE_ID = $SessionPlaceId; ROBLOX_DEV_INFINITE_PLACE_ID = $InfinitePlaceId; ROBLOX_DEV_CLASH_PLACE_ID = $ClashPlaceId
    }
    foreach ($entry in $values.GetEnumerator()) {
        $parsed = 0L
        if ($entry.Value -cnotmatch '^[1-9][0-9]*$' -or -not [long]::TryParse($entry.Value, [ref]$parsed) -or $parsed -ge 9007199254740992) {
            throw "Set Actions variable $($entry.Key) to a positive decimal ID below 2^53 (no spaces/leading zeros)."
        }
    }
    if (@(@($PlaceId,$SessionPlaceId,$InfinitePlaceId,$ClashPlaceId) | Select-Object -Unique).Count -ne 4) { throw 'The four development Place IDs must be distinct.' }
    return @{ Enabled = $true; UniverseId = $UniverseId; Places = @{ Entry = $PlaceId; Session = $SessionPlaceId; Infinite = $InfinitePlaceId; Clash = $ClashPlaceId } }
}

function Assert-DevelopmentConfiguration {
    param([string]$EventName, [string]$Ref, [string]$DefaultBranch, [string]$UniverseId, [string]$PlaceId,
        [string]$SessionPlaceId, [string]$InfinitePlaceId, [string]$ClashPlaceId, [string]$ApiKey)
    if ($EventName -cne 'workflow_dispatch' -or $Ref -cne 'refs/heads/main' -or $DefaultBranch -cne 'main') {
        throw 'Development deployment requires an explicit workflow_dispatch on refs/heads/main with main as the default branch. Select main in Run workflow.'
    }
    Get-DevelopmentConfiguration -UniverseId $UniverseId -PlaceId $PlaceId -SessionPlaceId $SessionPlaceId -InfinitePlaceId $InfinitePlaceId -ClashPlaceId $ClashPlaceId | Out-Null
    if ([string]::IsNullOrWhiteSpace($ApiKey)) {
        throw 'Set Actions secret ROBLOX_OPEN_CLOUD_API_KEY to a single-development-experience universe-places Write key. Never paste it into logs or source.'
    }
    if ($ApiKey.Contains("`r") -or $ApiKey.Contains("`n")) { throw 'ROBLOX_OPEN_CLOUD_API_KEY must be a single-line secret.' }
}

function Invoke-RobloxHttp($Request) {
    # No redirects, cookies, or retry; GET membership calls carry no credential.
    $handler = [Net.Http.HttpClientHandler]::new()
    $handler.AllowAutoRedirect = $false; $handler.UseCookies = $false
    $client = [Net.Http.HttpClient]::new($handler)
    $client.Timeout = [TimeSpan]::FromSeconds($Request.TimeoutSeconds)
    $message = [Net.Http.HttpRequestMessage]::new([Net.Http.HttpMethod]::new($Request.Method), $Request.Uri)
    if ($Request.Method -ceq 'POST') {
        $message.Headers.Add('x-api-key', $Request.Headers['x-api-key'])
        $message.Content = [Net.Http.ByteArrayContent]::new([byte[]]$Request.Payload)
        $message.Content.Headers.ContentType = [Net.Http.Headers.MediaTypeHeaderValue]::new($Request.ContentType)
    }
    $response = $null
    try {
        $response = $client.SendAsync($message).GetAwaiter().GetResult()
        return @{ StatusCode = [int]$response.StatusCode; Body = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult() }
    } finally {
        if ($response) { $response.Dispose() }
        $message.Dispose(); $client.Dispose()
    }
}

function Read-RobloxReply($Reply, [string]$Context) {
    if ($Reply -isnot [System.Collections.IDictionary] -or -not $Reply.Contains('StatusCode') -or
        $Reply.StatusCode -isnot [int] -or $Reply.StatusCode -lt 200 -or $Reply.StatusCode -ge 300) {
        $status = if ($Reply -is [System.Collections.IDictionary] -and $Reply.Contains('StatusCode') -and $Reply.StatusCode -is [int]) { [string]$Reply.StatusCode } else { 'invalid response' }
        throw "$Context failed: HTTP $status. Check target configuration, permissions and Roblox status. No automatic retry."
    }
    if (-not $Reply.Contains('Body') -or $Reply.Body -isnot [string]) { throw "$Context returned an invalid response body." }
    try { $body = ConvertFrom-Json -InputObject $Reply.Body -AsHashtable -NoEnumerate -ErrorAction Stop }
    catch { throw [InvalidOperationException]::new("$Context returned invalid JSON.") }
    if ($body -isnot [System.Collections.IDictionary]) { throw "$Context returned an invalid response object." }
    return $body
}

function Assert-ExperiencePlaces($Configuration, [scriptblock]$Transport) {
    $universe = $Configuration.UniverseId
    # These documented public read endpoints also work for private experiences;
    # no extra API key Read scope, login cookie, or audience change is needed.
    $request = @{ Method = 'GET'; Uri = "https://develop.roblox.com/v1/universes/$universe"; Headers = @{}; TimeoutSeconds = 30 }
    try { $reply = & $Transport $request }
    catch { throw [InvalidOperationException]::new("Cannot verify development universe $universe (network/timeout). Nothing published.") }
    $body = Read-RobloxReply $reply 'Universe verification'
    if (-not $body.Contains('id') -or [string]$body.id -cne $universe -or -not $body.Contains('rootPlaceId') -or [string]$body.rootPlaceId -cne $Configuration.Places.Entry) {
        throw 'Universe verification: ROBLOX_DEV_PLACE_ID must remain the existing Entry/start place of this experience.'
    }
    $known = @{}; $cursor = ''; $seen = @{}
    for ($page = 0; $page -lt 100; $page++) {
        $uri = "https://develop.roblox.com/v1/universes/$universe/places?sortOrder=Asc&limit=100"
        if ($cursor) { $uri += '&cursor=' + [Uri]::EscapeDataString($cursor) }
        try { $reply = & $Transport @{ Method = 'GET'; Uri = $uri; Headers = @{}; TimeoutSeconds = 30 } }
        catch { throw [InvalidOperationException]::new("Cannot verify places in development universe $universe (network/timeout). Nothing published.") }
        $body = Read-RobloxReply $reply 'Place membership verification'
        if (-not $body.Contains('data') -or $body.data -isnot [array] -or -not $body.Contains('nextPageCursor')) { throw 'Place membership verification returned an invalid page.' }
        foreach ($place in $body.data) {
            if ($place -isnot [System.Collections.IDictionary] -or -not $place.Contains('id') -or -not $place.Contains('universeId') -or [string]$place.universeId -cne $universe) {
                throw 'Place membership verification returned an invalid or foreign place.'
            }
            $known[[string]$place.id] = $true
        }
        $cursor = $body.nextPageCursor
        if ($null -ne $cursor -and $cursor -isnot [string]) { throw 'Place membership verification returned an invalid cursor.' }
        if (-not $cursor) {
            foreach ($role in @('Entry','Session','Infinite','Clash')) {
                if (-not $known.ContainsKey($Configuration.Places[$role])) { throw "The $role place is not confirmed in development universe $universe. Nothing published." }
            }
            return
        }
        if ($seen.ContainsKey($cursor)) { throw 'Place membership verification repeated a cursor; nothing published.' }
        $seen[$cursor] = $true
    }
    throw 'Place membership verification exceeded 100 pages; nothing published.'
}

function Assert-DeploymentCheckout([string]$CommitSha) {
    $head = & git -C $script:RepositoryRoot rev-parse HEAD
    if ($LASTEXITCODE -ne 0 -or $head -cne $CommitSha) { throw 'Deployment checkout commit changed during validation/build.' }
    $changes = & git -C $script:RepositoryRoot status --porcelain --untracked-files=normal
    if ($LASTEXITCODE -ne 0 -or $changes) { throw 'Deployment checkout must remain clean through validation/build.' }
}

function Invoke-DevelopmentDeployment {
    param(
        [string]$EventName, [string]$Ref, [string]$DefaultBranch,
        [string]$UniverseId, [string]$PlaceId, [string]$SessionPlaceId, [string]$InfinitePlaceId, [string]$ClashPlaceId, [string]$ApiKey,
        [Parameter(Mandatory)][string]$CommitSha, [switch]$DryRun,
        [scriptblock]$Validate = { Invoke-DevelopmentValidation },
        [scriptblock]$Build = { param($configuration) New-DevelopmentPlaces -Configuration $configuration },
        [scriptblock]$CheckCheckout = { param($commit) Assert-DeploymentCheckout $commit },
        [scriptblock]$Transport = { param($request) Invoke-RobloxHttp $request },
        [scriptblock]$Record = { param($result) }
    )
    # Snapshot and validate the exact order before callbacks. Missing module
    # state must never skip verification/uploads and report an empty success.
    $orderState = Get-Variable -Name PublishOrder -Scope Script -ErrorAction Ignore
    $publishOrder = @(if ($null -ne $orderState) { $orderState.Value })
    if ($publishOrder.Count -ne 4 -or ($publishOrder -join ',') -cne 'Session,Infinite,Clash,Entry') {
        throw 'Deployment requires the exact four-place publish order: Session, Infinite, Clash, Entry. Nothing published.'
    }
    $configuration = @{ Enabled = $false; UniverseId = '0'; Places = @{ Entry = '0'; Session = '0'; Infinite = '0'; Clash = '0' } }
    if (-not $DryRun) {
        Assert-DevelopmentConfiguration -EventName $EventName -Ref $Ref -DefaultBranch $DefaultBranch -UniverseId $UniverseId -PlaceId $PlaceId -SessionPlaceId $SessionPlaceId -InfinitePlaceId $InfinitePlaceId -ClashPlaceId $ClashPlaceId -ApiKey $ApiKey
        $configuration = Get-DevelopmentConfiguration -UniverseId $UniverseId -PlaceId $PlaceId -SessionPlaceId $SessionPlaceId -InfinitePlaceId $InfinitePlaceId -ClashPlaceId $ClashPlaceId
    }
    if ($CommitSha -cnotmatch '^[0-9a-f]{40}$') { throw 'Deployment requires the actual checked-out Git commit SHA.' }
    if (-not $DryRun) { & $CheckCheckout $CommitSha }
    & $Validate | ForEach-Object { Write-Host $_ }
    $paths = & $Build $configuration
    if ($paths -isnot [System.Collections.IDictionary] -or $paths.Count -ne 4) { throw 'Deployment build must return four fresh gameplay-only place files.' }
    $buffers = @{}; $records = [Collections.Generic.List[object]]::new()
    # Read/verify/hash ALL four immutable buffers before any network operation.
    foreach ($role in $publishOrder) {
        if (-not $paths.Contains($role) -or $paths[$role] -isnot [string] -or -not (Test-Path -LiteralPath $paths[$role] -PathType Leaf)) { throw "Deployment build missing fresh gameplay-only $role place file." }
        [byte[]]$payload = [IO.File]::ReadAllBytes($paths[$role])
        [xml]$place = [Text.Encoding]::UTF8.GetString($payload)
        Assert-DevelopmentPlace -PlaceXml $place -Role $role -Configuration $configuration
        $buffers[$role] = $payload
        $records.Add([pscustomobject][ordered]@{ Role = $role; PlaceId = $configuration.Places[$role]; BuildPath = $paths[$role]; Sha256 = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($payload)); Status = 'Built'; VersionNumber = $null })
    }
    $result = [pscustomobject][ordered]@{ CommitSha = $CommitSha; UniverseId = $configuration.UniverseId; DryRun = [bool]$DryRun; Complete = $false; Places = $records }
    if ($DryRun) { return $result }
    & $CheckCheckout $CommitSha
    Assert-ExperiencePlaces $configuration $Transport
    # Audit the full build set before the first upload, then each confirmed
    # version. A later failure still records exactly which places changed.
    & $Record $result | Out-Null
    foreach ($placeRecord in $records) {
        $placeRecord.Status = 'Outcome unknown'
        & $Record $result | Out-Null
        $request = @{
            Uri = "https://apis.roblox.com/universes/v1/$UniverseId/places/$($placeRecord.PlaceId)/versions?versionType=Published"
            Method = 'POST'; ContentType = 'application/xml'; Headers = @{ 'x-api-key' = $ApiKey }; Payload = $buffers[$placeRecord.Role]; TimeoutSeconds = 120
        }
        try { $reply = & $Transport $request }
        catch {
            throw [InvalidOperationException]::new("Roblox publish request failed for $($placeRecord.Role), universe $UniverseId, place $($placeRecord.PlaceId) (network/timeout). Outcome unknown; inspect Creator Dashboard version history before a manual retry. No automatic retry was attempted. Earlier confirmed versions are in the job summary; remaining places were not attempted.")
        }
        $body = Read-RobloxReply $reply "Roblox publish $($placeRecord.Role) (outcome unknown; inspect version history before retrying)"
        if (-not $body.Contains('versionNumber') -or ($body.versionNumber -isnot [long] -and $body.versionNumber -isnot [int]) -or $body.versionNumber -le 0) {
            throw 'Roblox publish did not return a positive integer versionNumber. Outcome unknown; inspect Creator Dashboard version history before retrying.'
        }
        $placeRecord.Status = 'Published'; $placeRecord.VersionNumber = $body.versionNumber
        & $Record $result | Out-Null
    }
    $result.Complete = $true
    & $Record $result | Out-Null
    return $result
}

Export-ModuleMember -Function Assert-DevelopmentConfiguration, Get-DevelopmentConfiguration, Invoke-DevelopmentDeployment
