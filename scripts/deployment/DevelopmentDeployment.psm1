Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:RepositoryRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Import-Module (Join-Path $PSScriptRoot 'GameplayArtifact.psm1')

function Assert-DevelopmentConfiguration {
    param([string]$EventName, [string]$Ref, [string]$DefaultBranch, [string]$UniverseId, [string]$PlaceId, [string]$ApiKey)
    if ($EventName -cne 'workflow_dispatch' -or $Ref -cne 'refs/heads/main' -or $DefaultBranch -cne 'main') {
        throw 'Development deployment requires an explicit workflow_dispatch on refs/heads/main with main as the default branch. Select main in Run workflow.'
    }
    foreach ($entry in @(@{ Name = 'ROBLOX_DEV_UNIVERSE_ID'; Value = $UniverseId }, @{ Name = 'ROBLOX_DEV_PLACE_ID'; Value = $PlaceId })) {
        if ($entry.Value -cnotmatch '^[1-9][0-9]*$') {
            throw "Set Actions variable $($entry.Name) to the private development target's positive decimal ID (no spaces/leading zeros)."
        }
    }
    if ([string]::IsNullOrWhiteSpace($ApiKey)) {
        throw 'Set Actions secret ROBLOX_OPEN_CLOUD_API_KEY to a single-development-experience universe-places Write key. Never paste it into logs or source.'
    }
    if ($ApiKey.Contains("`r") -or $ApiKey.Contains("`n")) { throw 'ROBLOX_OPEN_CLOUD_API_KEY must be a single-line secret.' }
}

function Invoke-PublishHttp($Request) {
    # No automatic redirects (credential forwarding) or retry. A timeout can
    # occur after Roblox created a version, so its outcome is ambiguous.
    $handler = [Net.Http.HttpClientHandler]::new()
    $handler.AllowAutoRedirect = $false
    $client = [Net.Http.HttpClient]::new($handler)
    $client.Timeout = [TimeSpan]::FromSeconds($Request.TimeoutSeconds)
    $message = [Net.Http.HttpRequestMessage]::new([Net.Http.HttpMethod]::Post, $Request.Uri)
    $message.Headers.Add('x-api-key', $Request.Headers['x-api-key'])
    $message.Content = [Net.Http.ByteArrayContent]::new([byte[]]$Request.Payload)
    $message.Content.Headers.ContentType = [Net.Http.Headers.MediaTypeHeaderValue]::new($Request.ContentType)
    $response = $null
    try {
        $response = $client.SendAsync($message).GetAwaiter().GetResult()
        return @{ StatusCode = [int]$response.StatusCode; Body = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult() }
    } finally {
        if ($response) { $response.Dispose() }
        $message.Dispose()
        $client.Dispose()
    }
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
        [string]$UniverseId, [string]$PlaceId, [string]$ApiKey,
        [Parameter(Mandatory)][string]$CommitSha,
        [switch]$DryRun,
        [scriptblock]$Validate = { Set-StrictMode -Off; & (Join-Path $script:RepositoryRoot 'scripts/Validate-Project.ps1') },
        [scriptblock]$Build = { New-DevelopmentPlace },
        [scriptblock]$CheckCheckout = { param($commit) Assert-DeploymentCheckout $commit },
        [scriptblock]$Transport = { param($request) Invoke-PublishHttp $request }
    )
    if (-not $DryRun) {
        Assert-DevelopmentConfiguration -EventName $EventName -Ref $Ref -DefaultBranch $DefaultBranch -UniverseId $UniverseId -PlaceId $PlaceId -ApiKey $ApiKey
    }
    if ($CommitSha -cnotmatch '^[0-9a-f]{40}$') { throw 'Deployment requires the actual checked-out Git commit SHA.' }
    if (-not $DryRun) { & $CheckCheckout $CommitSha }
    # Scriptblock seams are for offline regression tests; production always runs
    # the full validator, fresh builder and real transport in this order.
    & $Validate | ForEach-Object { Write-Host $_ }
    $path = & $Build
    if ($path -isnot [string] -or -not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw 'Deployment build did not return one fresh gameplay-only place file.'
    }
    # Verify and hash the same immutable byte buffer that the transport receives.
    [byte[]]$payload = [IO.File]::ReadAllBytes($path)
    [xml]$place = [Text.Encoding]::UTF8.GetString($payload)
    Assert-DevelopmentPlace -PlaceXml $place
    $sha256 = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($payload))
    $result = [ordered]@{ CommitSha = $CommitSha; BuildPath = $path; Sha256 = $sha256; UniverseId = $UniverseId; PlaceId = $PlaceId; Published = $false; VersionNumber = $null }
    if ($DryRun) { return [pscustomobject]$result }
    & $CheckCheckout $CommitSha
    $request = @{
        Uri = "https://apis.roblox.com/universes/v1/$UniverseId/places/$PlaceId/versions?versionType=Published"
        Method = 'POST'; ContentType = 'application/xml'; Headers = @{ 'x-api-key' = $ApiKey }; Payload = $payload; TimeoutSeconds = 120
    }
    try {
        $reply = & $Transport $request
    } catch {
        # The transport boundary deliberately replaces ALL exception text/inner
        # exceptions: HTTP libraries and mocks may include credential headers.
        throw [InvalidOperationException]::new("Roblox publish request failed for universe $UniverseId, place $PlaceId (network/timeout). Outcome unknown; inspect Creator Dashboard version history before a manual retry. No automatic retry was attempted.")
    }
    if ($reply -isnot [System.Collections.IDictionary] -or -not $reply.Contains('StatusCode') -or
        $reply.StatusCode -isnot [int] -or $reply.StatusCode -lt 200 -or $reply.StatusCode -ge 300) {
        $status = if ($reply -is [System.Collections.IDictionary] -and $reply.Contains('StatusCode') -and $reply.StatusCode -is [int]) { [string]$reply.StatusCode } else { 'invalid response' }
        # Do not echo response bodies, headers, reason phrases or raw exceptions.
        throw "Roblox publish failed: HTTP $status for universe $UniverseId, place $PlaceId. Check target IDs, universe-places Write scope, key expiry/IP restrictions and Roblox status. Inspect version history before retrying; no automatic retry."
    }
    if (-not $reply.Contains('Body') -or $reply.Body -isnot [string]) {
        throw 'Roblox publish returned an invalid response body. Outcome unknown; inspect Creator Dashboard version history before retrying.'
    }
    try { $body = ConvertFrom-Json -InputObject $reply.Body -AsHashtable -NoEnumerate -ErrorAction Stop }
    catch { throw [InvalidOperationException]::new('Roblox publish returned invalid JSON. Outcome unknown; inspect Creator Dashboard version history before retrying.') }
    if ($body -isnot [System.Collections.IDictionary] -or -not $body.Contains('versionNumber') -or
        ($body.versionNumber -isnot [long] -and $body.versionNumber -isnot [int]) -or $body.versionNumber -le 0) {
        throw 'Roblox publish did not return a positive integer versionNumber. Outcome unknown; inspect Creator Dashboard version history before retrying.'
    }
    $result.Published = $true
    $result.VersionNumber = $body.versionNumber
    return [pscustomobject]$result
}

Export-ModuleMember -Function Assert-DevelopmentConfiguration, Invoke-DevelopmentDeployment
