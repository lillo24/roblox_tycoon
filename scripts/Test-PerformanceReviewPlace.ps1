$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path $PSScriptRoot -Parent
$canonical = Join-Path $repositoryRoot 'place/tycoon.rbxlx'
$hash = (Get-FileHash -LiteralPath $canonical).Hash
[xml]$authored = [IO.File]::ReadAllText($canonical)
foreach ($workload in @('Fresh','SixOwners')) {
    $name = 'mode-perf-check-' + $workload.ToLowerInvariant() + '.rbxlx'
    & (Join-Path $PSScriptRoot 'New-PerformanceReviewPlace.ps1') -Workload $workload -OutputName $name
    [xml]$scene = [IO.File]::ReadAllText((Join-Path $repositoryRoot "build/$name"))
    if ($scene.SelectSingleNode('/roblox/Item[@class="Workspace"]').OuterXml -cne $authored.SelectSingleNode('/roblox/Item[@class="Workspace"]').OuterXml) { throw 'Performance preview changed authored geometry.' }
    $start = $scene.SelectSingleNode('//Item[@class="Script"][Properties/string[@name="Name"]="StartLocalPreview"]/Properties/ProtectedString[@name="Source"]')
    if ($start.InnerText -cne "require(script.Parent.Server).start('$workload')") { throw 'Performance workload startup mismatch.' }
    foreach ($file in @('Server','Workloads','Sampler')) {
        $source = $scene.SelectSingleNode("//Item[@class='ModuleScript'][Properties/string[@name='Name']='$file']/Properties/ProtectedString[@name='Source']")
        if (-not $source -or $source.InnerText.Replace("`r`n","`n") -cne [IO.File]::ReadAllText((Join-Path $repositoryRoot "tests/fixtures/Performance/$file.luau")).Replace("`r`n","`n")) { throw "Missing exact performance source: $file" }
    }
    $client = $scene.SelectSingleNode('//Item[@class="LocalScript"][Properties/string[@name="Name"]="PERF01Client"]/Properties/ProtectedString[@name="Source"]')
    if (-not $client -or $client.InnerText.Replace("`r`n","`n") -cne [IO.File]::ReadAllText((Join-Path $repositoryRoot 'tests/fixtures/Performance/Client.client.luau')).Replace("`r`n","`n")) { throw 'Missing exact performance client source.' }
    if ($scene.SelectSingleNode('//Item[Properties/string[@name="Name"]="INF02QA"]')) { throw 'Assertion runners must not contaminate timed previews.' }
}
[xml]$production = [IO.File]::ReadAllText((Join-Path $repositoryRoot 'build/validation.rbxlx'))
if ($production.SelectSingleNode('//Item[Properties/string[@name="Name"]="PERF01" or Properties/string[@name="Name"]="PERF01Client"]')) { throw 'Performance fixtures leaked into production.' }
if ((Get-FileHash -LiteralPath $canonical).Hash -ne $hash) { throw 'Canonical scene changed.' }
Write-Output 'Performance workload startup, exact probe source, production exclusion and unchanged map checks passed.'
