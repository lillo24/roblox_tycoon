# Offline only: all HTTP is a mock, including failure/timeout paths. No key needed.
$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $PSScriptRoot 'deployment/GameplayArtifact.psm1')
Import-Module (Join-Path $PSScriptRoot 'deployment/DevelopmentDeployment.psm1')
$script:checks = 0
function Assert-Test([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "Deployment regression: $Message" }
    $script:checks++
}
function Assert-Rejected([string]$Name, [scriptblock]$Action, [string]$Pattern) {
    $rejected = $false
    try { & $Action | Out-Null }
    catch {
        $rejected = $true
        Assert-Test ($_.ToString() -match $Pattern) "$Name returned an unexpected failure: $_"
        Assert-Test ($_.ToString() -notmatch 'offline-credential-marker') "$Name exposed a credential"
    }
    Assert-Test $rejected "$Name did not fail"
}

$goodPath = New-DevelopmentPlace
[xml]$good = [IO.File]::ReadAllText($goodPath)
Assert-DevelopmentPlace -PlaceXml $good
Assert-Test (-not [IO.File]::ReadAllText($goodPath).StartsWith('<?xml')) 'Studio-incompatible XML declaration'
$state = @{ Events = [Collections.Generic.List[string]]::new(); Requests = [Collections.Generic.List[object]]::new() }
$base = @{
    EventName = 'workflow_dispatch'; Ref = 'refs/heads/main'; DefaultBranch = 'main'
    UniverseId = '123'; PlaceId = '456'; ApiKey = 'offline-credential-marker'; CommitSha = ('a' * 40)
    Validate = { $state.Events.Add('validate') }.GetNewClosure()
    Build = { $state.Events.Add('build'); return $goodPath }.GetNewClosure()
    CheckCheckout = { param($commit) $state.Events.Add('checkout') }.GetNewClosure()
    Transport = {
        param($request)
        $state.Events.Add('http'); $state.Requests.Add($request)
        return @{ StatusCode = 200; Body = '{"versionNumber":7}' }
    }.GetNewClosure()
}
foreach ($case in @(
    @{ Name = 'missing universe'; Key = 'UniverseId'; Value = ''; Pattern = 'ROBLOX_DEV_UNIVERSE_ID' },
    @{ Name = 'missing place'; Key = 'PlaceId'; Value = ''; Pattern = 'ROBLOX_DEV_PLACE_ID' },
    @{ Name = 'zero ID'; Key = 'PlaceId'; Value = '0'; Pattern = 'positive decimal' },
    @{ Name = 'negative ID'; Key = 'UniverseId'; Value = '-1'; Pattern = 'positive decimal' },
    @{ Name = 'nondecimal ID'; Key = 'PlaceId'; Value = '1e3'; Pattern = 'positive decimal' },
    @{ Name = 'ID injection'; Key = 'PlaceId'; Value = '456/versions?x=1'; Pattern = 'positive decimal' },
    @{ Name = 'missing secret'; Key = 'ApiKey'; Value = ''; Pattern = 'ROBLOX_OPEN_CLOUD_API_KEY' },
    @{ Name = 'blank secret'; Key = 'ApiKey'; Value = ' '; Pattern = 'ROBLOX_OPEN_CLOUD_API_KEY' },
    @{ Name = 'multiline secret'; Key = 'ApiKey'; Value = "offline-credential-marker`nheader"; Pattern = 'single-line' },
    @{ Name = 'feature branch'; Key = 'Ref'; Value = 'refs/heads/feature'; Pattern = 'manual|workflow_dispatch' },
    @{ Name = 'tag'; Key = 'Ref'; Value = 'refs/tags/main'; Pattern = 'manual|workflow_dispatch' },
    @{ Name = 'wrong default'; Key = 'DefaultBranch'; Value = 'other'; Pattern = 'default branch' },
    @{ Name = 'automatic event'; Key = 'EventName'; Value = 'push'; Pattern = 'workflow_dispatch' },
    @{ Name = 'bad SHA'; Key = 'CommitSha'; Value = 'main'; Pattern = 'commit SHA' }
)) {
    $state.Events.Clear(); $state.Requests.Clear()
    $arguments = $base.Clone(); $arguments[$case.Key] = $case.Value
    Assert-Rejected $case.Name { Invoke-DevelopmentDeployment @arguments } $case.Pattern
    Assert-Test ($state.Events.Count -eq 0 -and $state.Requests.Count -eq 0) "$($case.Name) passed preflight"
}
foreach ($case in @(
    @{ Name = 'validation failure'; Key = 'Validate'; Value = { throw 'mock validation failed' }; Pattern = 'validation failed' },
    @{ Name = 'build failure'; Key = 'Build'; Value = { throw 'mock build failed' }; Pattern = 'build failed' },
    @{ Name = 'missing build'; Key = 'Build'; Value = { return 'missing.rbxlx' }; Pattern = 'fresh gameplay-only' },
    @{ Name = 'checkout changed'; Key = 'CheckCheckout'; Value = { throw 'checkout changed' }; Pattern = 'checkout changed' }
)) {
    $state.Events.Clear(); $state.Requests.Clear()
    $arguments = $base.Clone(); $arguments[$case.Key] = $case.Value
    Assert-Rejected $case.Name { Invoke-DevelopmentDeployment @arguments } $case.Pattern
    Assert-Test ($state.Requests.Count -eq 0) "$($case.Name) attempted HTTP"
}

# Mutate real assembled XML in memory: production modules beyond bootstraps,
# class/path ownership, extra QA and non-code fidelity are all consequential gates.
foreach ($case in @(
    @{ Name = 'stale module'; XPath = "//Item[Properties/string[@name='Name']='UiTheme']/Properties/*[@name='Source']"; Change = { param($node) $node.InnerText = '-- stale' }; Pattern = 'current checkout source' },
    @{ Name = 'wrong module class'; XPath = "//Item[Properties/string[@name='Name']='UiTheme']"; Change = { param($node) $node.SetAttribute('class','Script') }; Pattern = 'ModuleScript' },
    @{ Name = 'missing module'; XPath = "//Item[Properties/string[@name='Name']='UiTheme']"; Change = { param($node) [void]$node.ParentNode.RemoveChild($node) }; Pattern = 'ModuleScript' },
    @{ Name = 'changed Workspace'; XPath = "//Item[Properties/string[@name='Name']='Ground']/Properties/string[@name='Name']"; Change = { param($node) $node.InnerText = 'changed-ground' }; Pattern = 'outside managed source' },
    @{ Name = 'QA residue'; XPath = "//Item[Properties/string[@name='Name']='TestService']/Properties/string[@name='Name']"; Change = { param($node) $node.InnerText = 'UI01QA' }; Pattern = 'QA/fixture' },
    @{ Name = 'fixture residue'; XPath = "//Item[Properties/string[@name='Name']='TestService']/Properties/string[@name='Name']"; Change = { param($node) $node.InnerText = 'RunDisplayFixture' }; Pattern = 'QA/fixture' },
    @{ Name = 'extra script'; XPath = "//Item[Properties/string[@name='Name']='UiTheme']"; Change = { param($node) [void]$node.ParentNode.AppendChild($node.CloneNode($true)) }; Pattern = 'ModuleScript' }
    @{ Name = 'script descendant'; XPath = "//Item[Properties/string[@name='Name']='UiTheme']"; Change = { param($node) [void]$node.AppendChild($node.CloneNode($true)) }; Pattern = 'unexpected descendants' }
)) {
    [xml]$mutated = $good.CloneNode($true)
    $node = $mutated.SelectSingleNode($case.XPath)
    Assert-Test ($null -ne $node) "test mutation target missing: $($case.Name)"
    & $case.Change $node
    Assert-Rejected $case.Name { Assert-DevelopmentPlace -PlaceXml $mutated } $case.Pattern
}
foreach ($class in @('EditableImage','EditableMesh','PartOperation','UnionOperation','NegateOperation','IntersectOperation','SurfaceAppearance','BaseWrap','WrapLayer','WrapTarget','WrapDeformer')) {
    [xml]$mutated = $good.CloneNode($true)
    $mutated.SelectSingleNode("//Item[Properties/string[@name='Name']='TestService']").SetAttribute('class', $class)
    Assert-Rejected "API-limited $class" { Assert-DevelopmentPlace -PlaceXml $mutated } 'manual Studio publishing'
}

$invalidPath = Join-Path $repositoryRoot ('build/deploy-regression-' + [guid]::NewGuid().ToString('N') + '.rbxlx')
try {
    [xml]$fixture = $good.CloneNode($true)
    $fixture.SelectSingleNode("//Item[Properties/string[@name='Name']='TestService']/Properties/string[@name='Name']").InnerText = 'RunDisplayFixture'
    $fixture.Save($invalidPath)
    $arguments = $base.Clone()
    $arguments.Build = { return $invalidPath }.GetNewClosure()
    $state.Requests.Clear()
    Assert-Rejected 'fixture through publisher' { Invoke-DevelopmentDeployment @arguments } 'QA/fixture'
    Assert-Test ($state.Requests.Count -eq 0) 'fixture artifact reached HTTP'
} finally { if (Test-Path -LiteralPath $invalidPath) { Remove-Item -LiteralPath $invalidPath } }

$state.Events.Clear(); $state.Requests.Clear()
$success = Invoke-DevelopmentDeployment @base
Assert-Test (($state.Events -join ',') -ceq 'checkout,validate,build,checkout,http') 'publish order must be checkout, validation, build, checkout, HTTP'
Assert-Test ($state.Requests.Count -eq 1 -and $success.Published -and $success.VersionNumber -eq 7) 'valid version must be recorded once'
$request = $state.Requests[0]
Assert-Test ($request.Method -ceq 'POST' -and $request.Uri -ceq 'https://apis.roblox.com/universes/v1/123/places/456/versions?versionType=Published') 'wrong publishing endpoint/method'
Assert-Test ($request.ContentType -ceq 'application/xml' -and $request.Headers['x-api-key'] -ceq $base.ApiKey -and $request.Headers.Count -eq 1 -and $request.TimeoutSeconds -eq 120) 'wrong XML/header/timeout contract'
Assert-Test ([Convert]::ToBase64String($request.Payload) -ceq [Convert]::ToBase64String([IO.File]::ReadAllBytes($goodPath))) 'payload must be exact verified XML bytes'
Assert-Test ($success.Sha256 -ceq (Get-FileHash -LiteralPath $goodPath -Algorithm SHA256).Hash -and $success.CommitSha -ceq $base.CommitSha) 'digest/commit audit mismatch'
Assert-Test (($success | ConvertTo-Json) -notmatch $base.ApiKey) 'result leaked the key'

foreach ($case in @(
    @{ Name = 'redirect'; Code = 302; Body = 'offline-credential-marker'; Pattern = 'HTTP 302' },
    @{ Name = 'unauthorized'; Code = 401; Body = 'offline-credential-marker'; Pattern = 'HTTP 401' },
    @{ Name = 'forbidden'; Code = 403; Body = 'offline-credential-marker'; Pattern = 'HTTP 403' },
    @{ Name = 'rate limit'; Code = 429; Body = 'offline-credential-marker'; Pattern = 'HTTP 429' },
    @{ Name = 'server error'; Code = 500; Body = 'offline-credential-marker'; Pattern = 'HTTP 500' },
    @{ Name = 'invalid JSON'; Code = 200; Body = 'offline-credential-marker'; Pattern = 'invalid JSON' },
    @{ Name = 'missing version'; Code = 200; Body = '{}'; Pattern = 'positive integer versionNumber' },
    @{ Name = 'zero version'; Code = 200; Body = '{"versionNumber":0}'; Pattern = 'positive integer versionNumber' },
    @{ Name = 'negative version'; Code = 200; Body = '{"versionNumber":-7}'; Pattern = 'positive integer versionNumber' },
    @{ Name = 'string version'; Code = 200; Body = '{"versionNumber":"7"}'; Pattern = 'positive integer versionNumber' },
    @{ Name = 'fractional version'; Code = 200; Body = '{"versionNumber":1.5}'; Pattern = 'positive integer versionNumber' },
    @{ Name = 'boolean version'; Code = 200; Body = '{"versionNumber":true}'; Pattern = 'positive integer versionNumber' },
    @{ Name = 'JSON array'; Code = 200; Body = '[{"versionNumber":7}]'; Pattern = 'positive integer versionNumber' },
    @{ Name = 'no content'; Code = 204; Body = ''; Pattern = 'invalid JSON|positive integer versionNumber' }
)) {
    $state.Requests.Clear()
    $arguments = $base.Clone()
    $reply = @{ StatusCode = $case.Code; Body = $case.Body }
    $arguments.Transport = { param($request) $state.Requests.Add($request); return $reply }.GetNewClosure()
    Assert-Rejected $case.Name { Invoke-DevelopmentDeployment @arguments } $case.Pattern
    Assert-Test ($state.Requests.Count -eq 1) "$($case.Name) retried HTTP"
}
foreach ($reply in @(@{}, @{ StatusCode = '200'; Body = 'offline-credential-marker' }, @{ StatusCode = 200 })) {
    $arguments = $base.Clone()
    $arguments.Transport = { param($request) $state.Requests.Add($request); return $reply }.GetNewClosure()
    $state.Requests.Clear()
    Assert-Rejected 'invalid transport reply' { Invoke-DevelopmentDeployment @arguments } 'invalid response'
    Assert-Test ($state.Requests.Count -eq 1) 'invalid transport reply retried HTTP'
}
$arguments = $base.Clone()
$state.Requests.Clear()
$arguments.Transport = { param($request) $state.Requests.Add($request); throw [TimeoutException]::new('offline-credential-marker') }.GetNewClosure()
Assert-Rejected 'ambiguous timeout' { Invoke-DevelopmentDeployment @arguments } 'Outcome unknown'
Assert-Test ($state.Requests.Count -eq 1) 'timeout retried HTTP'
$arguments = $base.Clone(); $arguments.ApiKey = ''; $arguments.UniverseId = ''; $arguments.PlaceId = ''; $arguments.DryRun = $true
$state.Requests.Clear()
$dryRun = Invoke-DevelopmentDeployment @arguments
Assert-Test (-not $dryRun.Published -and $null -eq $dryRun.VersionNumber -and $state.Requests.Count -eq 0) 'dry run must never publish, even without credentials'
$arguments = $base.Clone(); $arguments.DryRun = $true
$dryRunWithKey = Invoke-DevelopmentDeployment @arguments
Assert-Test (-not $dryRunWithKey.Published -and $state.Requests.Count -eq 0) 'dry run must never publish with credentials supplied either'

# Guard the actual Actions wiring without introducing a YAML dependency.
$workflow = [IO.File]::ReadAllText((Join-Path $repositoryRoot '.github/workflows/deploy-development.yml')).Replace("`r`n", "`n")
Assert-Test ($workflow -match '(?m)^on:\n  workflow_dispatch:\n\npermissions:') 'deployment must have exactly one manual trigger'
Assert-Test ($workflow -match '(?m)^permissions:\n  contents: read\n\njobs:') 'GITHUB_TOKEN permission broadened'
Assert-Test ($workflow -match "GITHUB_REF -cne 'refs/heads/main'" -and $workflow -match "DEPLOY_DEFAULT_BRANCH -cne 'main'") 'workflow must reject wrong refs/default branch before checkout'
Assert-Test ($workflow -match '(?m)^          ref: main$' -and $workflow -match 'persist-credentials: false') 'checkout must resolve main and discard Git credentials'
Assert-Test ($workflow -match 'group: roblox-development-start-place' -and $workflow -match 'cancel-in-progress: false') 'deployment serialization changed'
Assert-Test ($workflow -match 'run: ./scripts/Invoke-DevelopmentDeployment.ps1\s*\n' -and $workflow -notmatch 'Invoke-DevelopmentDeployment.ps1 -DryRun') 'workflow must call the validated publishing entry point'
Assert-Test ($workflow -match '(?m)^          path: build/ui-review-development.rbxlx$' -and $workflow -match 'retention-days: 3') 'artifact scope/retention changed'
Assert-Test ($workflow -notmatch '(?m)^\s*if:.*always\(') 'failed/ambiguous publishing must not upload build artifacts'
Write-Output "Development deployment: $script:checks offline assertions passed; no Roblox HTTP or credentials used."
