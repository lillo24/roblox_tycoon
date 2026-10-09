# Regression check for the disposable preview's QA/gameplay-only boundary.
$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path $PSScriptRoot -Parent
$canonical = Join-Path $repositoryRoot 'place/tycoon.rbxlx'
$initialHash = (Get-FileHash -LiteralPath $canonical -Algorithm SHA256).Hash
[xml]$authored = [IO.File]::ReadAllText($canonical)
$project = Get-Content -LiteralPath (Join-Path $repositoryRoot 'default.project.json') -Raw | ConvertFrom-Json
$variants = @(
    @{ Name = 'ui-review-helper-qa-test.rbxlx'; GameplayOnly = $false },
    @{ Name = 'ui-review-helper-gameplay-test.rbxlx'; GameplayOnly = $true }
)
foreach ($variant in $variants) {
    & (Join-Path $PSScriptRoot 'New-UiReviewPlace.ps1') -OutputName $variant.Name -GameplayOnly:$variant.GameplayOnly
    $output = Join-Path $repositoryRoot "build/$($variant.Name)"
    [xml]$preview = [IO.File]::ReadAllText($output)
    & (Join-Path $PSScriptRoot 'Assert-ProjectStructure.ps1') -PlaceXml $preview -Project $project -RepositoryRoot $repositoryRoot
    if ($preview.SelectSingleNode('/roblox/Item[@class="Workspace"]').OuterXml -cne $authored.SelectSingleNode('/roblox/Item[@class="Workspace"]').OuterXml) {
        throw "Preview Workspace differs from canonical scene: $output"
    }
    $qa = @($preview.SelectNodes("/roblox/Item[@class='ServerScriptService']/Item[Properties/string[@name='Name']='UI01QA']"))
    $clientQA = @($preview.SelectNodes("/roblox/Item[@class='ReplicatedStorage']/Item[Properties/string[@name='Name']='UI01ClientQA']"))
    $orderQA = @($preview.SelectNodes("/roblox/Item[@class='ReplicatedStorage']/Item[Properties/string[@name='Name']='UI01OrderQA']"))
    if ($variant.GameplayOnly) {
        if ($qa.Count -ne 0 -or $clientQA.Count -ne 0 -or $orderQA.Count -ne 0) {
            throw "Gameplay-only preview contains QA fixtures: $output"
        }
    } else {
        if ($qa.Count -ne 1 -or $clientQA.Count -ne 1 -or $orderQA.Count -ne 1) {
            throw "Default preview is missing unique QA fixtures: $output"
        }
        foreach ($test in @('Session', 'SupplyEvent', 'SupplyFeedback', 'UiState', 'WorldLabels', 'PlayerGuidance', 'MapLayout', 'HudLifecycle', 'HudFeedback', 'HudReadiness')) {
            $folder = if ($test -like 'Hud*') { $clientQA[0] } else { $qa[0] }
            $module = @($folder.SelectNodes("Item[@class='ModuleScript'][Properties/string[@name='Name']='$test']"))
            $expected = [IO.File]::ReadAllText((Join-Path $repositoryRoot "tests/$test.spec.luau")).Replace("`r`n", "`n")
            if ($module.Count -ne 1 -or $module[0].SelectSingleNode('Properties/ProtectedString[@name="Source"]').InnerText.Replace("`r`n", "`n") -cne $expected) {
                throw "QA module must contain exact test source: $test in $output"
            }
        }
        foreach ($route in @(
            @{ Folder = $qa[0]; Class = 'Script'; Name = 'RunAssertions' },
            @{ Folder = $qa[0]; Class = 'ModuleScript'; Name = 'RunMapAssertions' },
            @{ Folder = $clientQA[0]; Class = 'LocalScript'; Name = 'RunClientAssertions' }
        )) {
            if (@($route.Folder.SelectNodes("Item[@class='$($route.Class)'][Properties/string[@name='Name']='$($route.Name)']")).Count -ne 1) {
                throw "Preview test route missing or wrong class: $($route.Name)"
            }
        }
    }
    if ([IO.File]::ReadAllText($output).StartsWith('<?xml')) { throw "Preview has a Studio-incompatible XML declaration: $output" }
}
if ((Get-FileHash -LiteralPath $canonical -Algorithm SHA256).Hash -ne $initialHash) {
    throw 'Canonical scene changed during preview regression checks.'
}
Write-Output 'UI review variants passed: exact production/test sources, unchanged map/hash, default QA routes, fixture-free gameplay output.'
