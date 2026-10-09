param([Parameter(Mandatory = $true)][string]$Name)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$hash = (Get-FileHash -LiteralPath (Join-Path $root 'place/tycoon.rbxlx') -Algorithm SHA256).Hash
foreach ($qa in @($false, $true)) {
    & "$PSScriptRoot/New-ExperimentPlace.ps1" -Name $Name -WithTests:$qa
    $suffix = if ($qa) { '-qa' } else { '' }
    $path = Join-Path $root "build/ui-review-exp-$($Name.ToLowerInvariant())$suffix.rbxlx"
    [xml]$scene = [IO.File]::ReadAllText($path)
    $tests = @($scene.SelectNodes('//Item[Properties/string[@name="Name"]="ExperimentAssertions"]'))
    if ($tests.Count -ne [int]$qa) { throw 'Experiment assertion isolation failed.' }
    $bootstraps = @($scene.SelectNodes('//Item[Properties/string[@name="Name"]="Bootstrap"]/Properties/*[@name="Source"]'))
    if ($bootstraps.Count -ne 2) { throw 'Experiment bootstrap count differs.' }
    foreach ($bootstrap in $bootstraps) {
        if ($bootstrap.InnerText -notmatch "Experiments\.$Name\.(Runtime|Controller)\)\.start\(\)") { throw 'Experiment bootstrap does not opt into selected module.' }
    }
    foreach ($route in @(
        @{ Path = 'ServerScriptService'; Folder = 'TycoonServer'; Area = 'server' },
        @{ Path = 'ReplicatedStorage'; Folder = 'TycoonShared'; Area = 'shared' },
        @{ Path = 'StarterPlayer/StarterPlayerScripts'; Folder = 'TycoonClient'; Area = 'client' }
    )) {
        $xpath = '/roblox'
        foreach ($segment in $route.Path.Split('/')) { $xpath += "/Item[Properties/string[@name='Name']='$segment']" }
        $xpath += "/Item[Properties/string[@name='Name']='$($route.Folder)']"
        foreach ($file in Get-ChildItem -LiteralPath (Join-Path $root "src/$($route.Area)") -Filter '*.luau' -Recurse) {
            $relative = [IO.Path]::GetRelativePath((Join-Path $root "src/$($route.Area)"), $file.FullName).Replace('\', '/')
            if ($relative -match '^Bootstrap\.') { continue }
            $names = $relative -replace '\.(server|client)\.luau$', '' -replace '\.luau$', ''
            $sourcePath = $xpath
            foreach ($segment in $names.Split('/')) { $sourcePath += "/Item[Properties/string[@name='Name']='$segment']" }
            $items = @($scene.SelectNodes($sourcePath))
            if ($items.Count -ne 1 -or $items[0].GetAttribute('class') -ne 'ModuleScript') { throw "Experiment source class/count failed: $relative" }
            $actual = $items[0].SelectSingleNode('Properties/*[@name="Source"]').InnerText.Replace("`r`n", "`n")
            if ($actual -cne [IO.File]::ReadAllText($file.FullName).Replace("`r`n", "`n")) { throw "Stale experiment source: $relative" }
        }
    }
}
if ((Get-FileHash -LiteralPath (Join-Path $root 'place/tycoon.rbxlx') -Algorithm SHA256).Hash -ne $hash) { throw 'Experiment regression modified canonical map.' }
Write-Output "Experiment preview assertions passed: $Name (exact modules, two opt-in bootstraps, isolated QA, canonical hash)."
