param([switch]$DryRun)

# Credentials are read only from the process environment, never CLI arguments.
$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $PSScriptRoot 'deployment/DevelopmentDeployment.psm1') -Force
Push-Location -LiteralPath $repositoryRoot
$audit = @{ Result = $null }
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
        -UniverseId $env:ROBLOX_DEV_UNIVERSE_ID -PlaceId $env:ROBLOX_DEV_PLACE_ID `
        -SessionPlaceId $env:ROBLOX_DEV_SESSION_PLACE_ID -InfinitePlaceId $env:ROBLOX_DEV_INFINITE_PLACE_ID -ClashPlaceId $env:ROBLOX_DEV_CLASH_PLACE_ID `
        -ApiKey $env:ROBLOX_OPEN_CLOUD_API_KEY -Record { param($record) $audit.Result = $record }
    if ($DryRun) {
        Write-Output "DRY RUN ONLY: validated $($result.CommitSha), built four disabled-routing places. No HTTP or publishing."
        $result.Places | Format-Table Role, BuildPath, Sha256
    } else {
        Write-Output "Published all four development places, Entry last, from commit $($result.CommitSha). See per-place versions and hashes in the job summary."
    }
} finally {
    if (-not $DryRun -and $env:GITHUB_STEP_SUMMARY) {
        $record = $audit.Result
        $summary = [Collections.Generic.List[string]]::new()
        $summary.Add('## Four-place development deployment')
        $summary.Add('')
        if ($record) {
            $summary.Add("Universe: $($record.UniverseId). Validated checkout: $($record.CommitSha). Complete: $($record.Complete).")
            $summary.Add('')
            $summary.Add('| Role | Place ID | SHA256 | Status | Confirmed version |')
            $summary.Add('| --- | --- | --- | --- | --- |')
            foreach ($place in $record.Places) { $summary.Add("| $($place.Role) | $($place.PlaceId) | $($place.Sha256) | $($place.Status) | $($place.VersionNumber) |") }
            $summary.Add('')
            $summary.Add('Publishing is non-atomic. Built means not attempted. Outcome unknown means inspect that place in Creator Dashboard before any manual retry. Confirmed earlier uploads remain published. See docs/MOBILE_DEPLOYMENT.md for coordinated restore/retry.')
        } else { $summary.Add('Stopped before publishing: configuration, checkout, validation, build, or destination verification did not complete. No place upload was attempted.') }
        $summary.Add('')
        $summary.Add('After a complete run, close and rejoin in Roblox. Existing servers can still run older versions. Physical-phone, live teleport and live DataStore QA remain separate.')
        $summary -join "`n" | Out-File -LiteralPath $env:GITHUB_STEP_SUMMARY -Encoding utf8 -Append
    }
    Pop-Location
}
