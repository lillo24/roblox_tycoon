param([switch]$DryRun)

# Credentials are read only from the process environment, never CLI arguments.
$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $PSScriptRoot 'deployment/DevelopmentDeployment.psm1') -Force
Push-Location -LiteralPath $repositoryRoot
try {
    $commitSha = & git rev-parse HEAD
    if ($LASTEXITCODE -ne 0) { throw 'Cannot resolve deployment checkout commit.' }
    if (-not $DryRun) {
        if (-not $env:GITHUB_STEP_SUMMARY) { throw 'Development publishing requires the GitHub Actions job summary path.' }
        $changes = & git status --porcelain --untracked-files=normal
        if ($LASTEXITCODE -ne 0 -or $changes) { throw 'Deployment checkout must be clean before validating/publishing the commit.' }
    }
    $result = Invoke-DevelopmentDeployment -DryRun:$DryRun -CommitSha $commitSha `
        -EventName $env:GITHUB_EVENT_NAME -Ref $env:GITHUB_REF -DefaultBranch $env:DEPLOY_DEFAULT_BRANCH `
        -UniverseId $env:ROBLOX_DEV_UNIVERSE_ID -PlaceId $env:ROBLOX_DEV_PLACE_ID -ApiKey $env:ROBLOX_OPEN_CLOUD_API_KEY
    if ($DryRun) {
        Write-Output "DRY RUN ONLY: validated $($result.CommitSha), built $($result.BuildPath), SHA256 $($result.Sha256). Nothing published."
    } else {
        $summary = @"
## Development place published

| Field | Value |
| --- | --- |
| Universe ID | $($result.UniverseId) |
| Place ID | $($result.PlaceId) |
| Validated checkout commit | $($result.CommitSha) |
| Gameplay build SHA256 | $($result.Sha256) |
| Published version | $($result.VersionNumber) |

Close and rejoin in the Roblox app. Existing servers can still run an older version.
"@
        $summary | Out-File -LiteralPath $env:GITHUB_STEP_SUMMARY -Encoding utf8 -Append
        Write-Output "Published development place $($result.PlaceId), version $($result.VersionNumber), commit $($result.CommitSha), SHA256 $($result.Sha256)."
    }
} finally { Pop-Location }
