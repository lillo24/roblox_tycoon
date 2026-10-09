$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path $PSScriptRoot -Parent
$canonical = Join-Path $repositoryRoot 'place/tycoon.rbxlx'
$hash = (Get-FileHash -LiteralPath $canonical).Hash
[xml]$authored = [IO.File]::ReadAllText($canonical)
foreach ($variant in @(
    @{ Backend = 'LocalPreview'; QA = $true; Name = 'inf-helper-qa.rbxlx' },
    @{ Backend = 'LocalPreview'; QA = $false; Name = 'inf-helper-play.rbxlx' },
    @{ Backend = 'DataStore'; QA = $false; Name = 'inf-helper-real.rbxlx' },
    @{ Backend = 'LocalPreview'; QA = $false; Showcase = $true; Name = 'inf-helper-showcase.rbxlx' }
)) {
    & (Join-Path $PSScriptRoot 'New-InfiniteReviewPlace.ps1') -Backend $variant.Backend -IncludeQA:$variant.QA -Showcase:([bool]$variant.Showcase) -OutputName $variant.Name
    [xml]$scene = [IO.File]::ReadAllText((Join-Path $repositoryRoot "build/$($variant.Name)"))
    if ($scene.SelectSingleNode('/roblox/Item[@class="Workspace"]').OuterXml -cne $authored.SelectSingleNode('/roblox/Item[@class="Workspace"]').OuterXml) { throw 'Infinite preview changed the authored map.' }
    $mode = $scene.SelectSingleNode("/roblox/Item[@class='ReplicatedStorage']/Item[@class='StringValue'][Properties/string[@name='Name']='TycoonMode']/Properties/string[@name='Value']")
    if (-not $mode -or $mode.InnerText -cne 'Infinite') { throw 'Infinite preview lacks explicit mode.' }
    foreach ($route in @(
        @{ Area='server'; XPath="/roblox/Item[@class='ServerScriptService']/Item[Properties/string[@name='Name']='TycoonServer']" },
        @{ Area='shared'; XPath="/roblox/Item[@class='ReplicatedStorage']/Item[Properties/string[@name='Name']='TycoonShared']" },
        @{ Area='client'; XPath="/roblox/Item[@class='StarterPlayer']/Item[@class='StarterPlayerScripts']/Item[Properties/string[@name='Name']='TycoonClient']" }
    )) {
        $root = Join-Path $repositoryRoot "src/$($route.Area)"
        $files = @(Get-ChildItem -LiteralPath $root -Filter '*.luau' -Recurse)
        $folder = $scene.SelectSingleNode($route.XPath)
        if (@($folder.SelectNodes(".//Item[@class='Script' or @class='LocalScript' or @class='ModuleScript']")).Count -ne $files.Count) { throw "Unexpected mapped script count: $($route.Area)" }
        foreach ($file in $files) {
            $relative = [IO.Path]::GetRelativePath($root, $file.FullName) -replace '\.luau$','' -replace '\.(server|client)$',''
            $xpath = $route.XPath
            foreach ($part in ($relative -split '[\\/]')) { $xpath += "/Item[Properties/string[@name='Name']='$part']" }
            $node = $scene.SelectSingleNode($xpath)
            $class = if ($file.Name -like '*.server.luau') { 'Script' } elseif ($file.Name -like '*.client.luau') { 'LocalScript' } else { 'ModuleScript' }
            $sourceNode = if ($node) { $node.SelectSingleNode('Properties/*[@name="Source"]') } else { $null }
            if (-not $node -or -not $sourceNode -or $node.GetAttribute('class') -cne $class -or $sourceNode.InnerText.Replace("`r`n","`n") -cne [IO.File]::ReadAllText($file.FullName).Replace("`r`n","`n")) { throw "Preview must contain exact source/class: $($file.FullName)" }
        }
    }
    $fixture = $scene.SelectSingleNode("/roblox/Item[@class='ServerScriptService']/Item[Properties/string[@name='Name']='INF01Preview']")
    $showcase = $scene.SelectSingleNode("//Item[@class='ModuleScript'][Properties/string[@name='Name']='InfiniteShowcase']")
    if ([bool]$showcase -ne [bool]$variant.Showcase) { throw 'Development example fixture crossed its explicit preview boundary.' }
    $disabled = $scene.SelectSingleNode("/roblox/Item[@class='ServerScriptService']/Item[Properties/string[@name='Name']='TycoonServer']/Item[Properties/string[@name='Name']='Bootstrap']/Properties/bool[@name='Disabled']")
    if ($variant.Backend -eq 'DataStore') {
        if ($fixture -or ($disabled -and $disabled.InnerText -eq 'true')) { throw 'Real DataStore preview contains a fallback or disabled bootstrap.' }
    } else {
        if (-not $fixture -or -not $disabled -or $disabled.InnerText -ne 'true') { throw 'Local preview must explicitly replace the copied bootstrap.' }
        $runners = @($fixture.SelectNodes("Item[@class='Script']"))
        if ($runners.Count -ne $(if ($variant.QA) { 2 } else { 1 })) { throw 'Unexpected local preview scripts.' }
    }
}
if ((Get-FileHash -LiteralPath $canonical).Hash -ne $hash) { throw 'Canonical scene changed.' }
Write-Output 'Infinite preview: exact recursive source/class checks, local fixture boundary, real-backend bootstrap and unchanged map passed.'
