# Owns the stricter publish boundary around the existing disposable scene builder.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:RepositoryRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$script:Routes = @(
    @{ Path = 'ServerScriptService/TycoonServer'; Source = 'src/server' },
    @{ Path = 'ReplicatedStorage/TycoonShared'; Source = 'src/shared' },
    @{ Path = 'StarterPlayer/StarterPlayerScripts/TycoonClient'; Source = 'src/client' }
)

function Assert-OrdinaryPath([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { throw "Deployment input/output missing: $Path" }
    $item = Get-Item -LiteralPath $Path -Force
    if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or $item.LinkType) {
        throw "Deployment input/output cannot be linked: $Path"
    }
}

function Find-ArtifactItem([xml]$Document, [string]$Path) {
    $xpath = '/roblox'
    foreach ($name in $Path.Split('/')) { $xpath += "/Item[Properties/string[@name='Name']='$name']" }
    $items = @($Document.SelectNodes($xpath))
    if ($items.Count -ne 1) { throw "Deployment scene: $Path expected once, found $($items.Count)." }
    return $items[0]
}

function Assert-SourceFolder($Folder, [string]$Directory, [string]$InstancePath, [string]$RoutingSource = '') {
    Assert-OrdinaryPath $Directory
    if ($Folder.GetAttribute('class') -cne 'Folder') { throw "Deployment source: $InstancePath must be a Folder." }
    $expected = @{}
    foreach ($file in Get-ChildItem -LiteralPath $Directory -Force) {
        Assert-OrdinaryPath $file.FullName
        if ($file.PSIsContainer) {
            $name, $class = $file.Name, 'Folder'
        } elseif ($file.Name -match '\.(luau|lua)$') {
            # This repository uses ordinary folders and script files. Fail closed
            # on Rojo init/model/metadata mappings until their contract is reviewed.
            if ($file.Name -match '^init(\.(server|client))?\.(luau|lua)$') {
                throw "Deployment source: init mappings need an audited verifier update: $($file.FullName)"
            }
            $name = $file.Name -replace '(\.(server|client))?\.(luau|lua)$', ''
            $class = if ($file.Name -match '\.server\.(luau|lua)$') { 'Script' }
                elseif ($file.Name -match '\.client\.(luau|lua)$') { 'LocalScript' } else { 'ModuleScript' }
        } elseif ($file.Name -like '*.md' -or $file.Name -ceq '.gitkeep') { continue }
        else { throw "Deployment source: unsupported mapped input $($file.FullName); review its Rojo/verifier contract." }
        if ($name.Contains("'") -or $expected.ContainsKey($name)) { throw "Deployment source: ambiguous instance name in $Directory." }
        $expected[$name] = $true
        $children = @($Folder.SelectNodes("Item[Properties/string[@name='Name']='$name']"))
        if ($children.Count -ne 1 -or $children[0].GetAttribute('class') -cne $class) {
            throw "Deployment source: $InstancePath/$name expected one $class."
        }
        if ($file.PSIsContainer) {
            Assert-SourceFolder $children[0] $file.FullName "$InstancePath/$name" $RoutingSource
        } else {
            if (@($children[0].SelectNodes('Item')).Count -ne 0) {
                throw "Deployment source: unexpected descendants in $InstancePath/$name."
            }
            $sources = @($children[0].SelectNodes('Properties/*[@name="Source"]'))
            $expectedSource = [IO.File]::ReadAllText($file.FullName)
            # The only allowed generated source is this exact server-only
            # manifest, reconstructed independently from the validated inputs.
            if ($RoutingSource -and "$InstancePath/$name" -ceq 'ServerScriptService/TycoonServer/Routing/Settings') {
                $expectedSource = $RoutingSource
            }
            if ($sources.Count -ne 1 -or $sources[0].InnerText.Replace("`r`n", "`n") -cne $expectedSource.Replace("`r`n", "`n")) {
                throw "Deployment source: $InstancePath/$name does not contain current checkout source."
            }
        }
    }
    if (@($Folder.SelectNodes('Item')).Count -ne $expected.Count) {
        throw "Deployment source: unexpected/stale children in $InstancePath."
    }
}

function Assert-DevelopmentPlace {
    param([Parameter(Mandatory)][xml]$PlaceXml, [string]$RepositoryRoot = $script:RepositoryRoot,
        [ValidateSet('Entry','Session','Infinite','Clash')][string]$Role = 'Entry', [System.Collections.IDictionary]$Configuration)
    $routingSource = if ($Configuration) { Get-DevelopmentRoutingSource -Role $Role -Configuration $Configuration } else { '' }
    $canonicalPath = Join-Path $RepositoryRoot 'place/tycoon.rbxlx'
    Assert-OrdinaryPath $canonicalPath
    Assert-OrdinaryPath (Join-Path $RepositoryRoot 'default.project.json')
    [xml]$canonical = [IO.File]::ReadAllText($canonicalPath)
    if ($PlaceXml.DocumentElement.Name -cne 'roblox' -or $PlaceXml.roblox.version -cne '4') {
        throw 'Deployment scene must be a Roblox XML place (version 4).'
    }
    & { Set-StrictMode -Off; & (Join-Path $RepositoryRoot 'scripts/Assert-AuthoredMap.ps1') -Scene $canonical -RepositoryRoot $RepositoryRoot } | Out-Null
    $project = Get-Content -LiteralPath (Join-Path $RepositoryRoot 'default.project.json') -Raw | ConvertFrom-Json
    & { Set-StrictMode -Off; & (Join-Path $RepositoryRoot 'scripts/Assert-ProjectStructure.ps1') -PlaceXml $PlaceXml -Project $project -RepositoryRoot $RepositoryRoot } | Out-Null

    # Include descendants of the documented API-limited bases from our pinned
    # Roblox definitions, so UnionOperation/WrapLayer/etc cannot bypass the gate.
    $limited = @('EditableImage', 'EditableMesh', 'PartOperation', 'SurfaceAppearance', 'BaseWrap')
    $definitions = [IO.File]::ReadAllText((Join-Path $RepositoryRoot 'types/roblox.d.luau'))
    $inheritance = [regex]::Matches($definitions, '(?m)^declare extern type (\w+) extends (\w+) with')
    do {
        $before = $limited.Count
        foreach ($match in $inheritance) {
            if ($match.Groups[2].Value -cin $limited -and $match.Groups[1].Value -cnotin $limited) {
                $limited += $match.Groups[1].Value
            }
        }
    } while ($limited.Count -ne $before)
    foreach ($item in $PlaceXml.SelectNodes('//Item')) {
        $name = $item.SelectSingleNode('Properties/string[@name="Name"]').InnerText
        if ($item.GetAttribute('class') -cin $limited) {
            throw "Deployment scene: API-limited $($item.GetAttribute('class')) '$name' requires manual Studio publishing; see docs/MOBILE_DEPLOYMENT.md."
        }
        if ($name -match '(?i)(QA$|^QA\d|Fixture|Synthetic|Assertions|\.spec$)') {
            throw "Deployment scene: QA/fixture instance '$name' is forbidden."
        }
    }
    # All non-code content, including Workspace and service settings, must be
    # identical. Only the three managed folders can differ from the saved scene.
    # Clone both documents: XmlDocument.CloneNode normalizes empty-element syntax.
    [xml]$actualScene = $PlaceXml.CloneNode($true)
    [xml]$expectedScene = $canonical.CloneNode($true)
    foreach ($route in $script:Routes) {
        $actual = Find-ArtifactItem $PlaceXml $route.Path
        Assert-SourceFolder $actual (Join-Path $RepositoryRoot $route.Source) $route.Path $routingSource
        foreach ($document in @($actualScene, $expectedScene)) {
            $folder = Find-ArtifactItem $document $route.Path
            [void]$folder.ParentNode.RemoveChild($folder)
        }
    }
    if ($actualScene.DocumentElement.OuterXml -cne $expectedScene.DocumentElement.OuterXml) {
        throw 'Deployment scene: Workspace or other content outside managed source differs from the canonical scene.'
    }
}

function Get-DevelopmentRoutingSource {
    param([ValidateSet('Entry','Session','Infinite','Clash')][string]$Role,
        [Parameter(Mandatory)][System.Collections.IDictionary]$Configuration)
    $roles = @('Entry','Session','Infinite','Clash')
    if (-not $Configuration.Contains('Enabled') -or $Configuration.Enabled -isnot [bool] -or
        -not $Configuration.Contains('UniverseId') -or -not $Configuration.Contains('Places')) { throw 'Incomplete routing build configuration.' }
    $ids = @([string]$Configuration.UniverseId)
    foreach ($name in $roles) {
        if (-not $Configuration.Places.Contains($name)) { throw "Routing build configuration missing $name." }
        $ids += [string]$Configuration.Places[$name]
    }
    foreach ($id in $ids) {
        if ($Configuration.Enabled) {
            if ($id -cnotmatch '^[1-9][0-9]*$' -or [decimal]$id -ge 9007199254740992) { throw 'Routing IDs must be positive exact Luau integers below 2^53.' }
        } elseif ($id -cne '0') { throw 'Offline routing builds must use disabled, all-zero IDs.' }
    }
    if ($Configuration.Enabled -and @($ids[1..4] | Select-Object -Unique).Count -ne 4) { throw 'Routing place IDs must be distinct.' }
    $internalRole = if ($Role -ceq 'Session') { 'Prototype' } else { $Role }
    $enabled = ([string]$Configuration.Enabled).ToLowerInvariant()
    return @"
--!strict
-- Generated server-only deployment manifest. Session retains the Prototype role contract.
return table.freeze({
    Enabled = $enabled,
    BuildRole = "$internalRole",
    UniverseId = $($ids[0]),
    Places = table.freeze({ Entry = $($ids[1]), Prototype = $($ids[2]), Infinite = $($ids[3]), Clash = $($ids[4]) }),
})
"@
}

function New-DevelopmentPlaces {
    param([System.Collections.IDictionary]$Configuration = @{
        Enabled = $false; UniverseId = '0'; Places = @{ Entry = '0'; Session = '0'; Infinite = '0'; Clash = '0' }
    })
    $canonicalPath = Join-Path $script:RepositoryRoot 'place/tycoon.rbxlx'
    Assert-OrdinaryPath $canonicalPath
    Assert-OrdinaryPath (Join-Path $script:RepositoryRoot 'default.project.json')
    # Reject linked/missing source inputs before the underlying Rojo build writes.
    foreach ($route in $script:Routes) {
        $directory = Join-Path $script:RepositoryRoot $route.Source
        Assert-OrdinaryPath $directory
        foreach ($inputItem in Get-ChildItem -LiteralPath $directory -Recurse -Force) {
            Assert-OrdinaryPath $inputItem.FullName
        }
    }
    $initialHash = (Get-FileHash -LiteralPath $canonicalPath -Algorithm SHA256).Hash
    & { Set-StrictMode -Off; & (Join-Path $script:RepositoryRoot 'scripts/Assert-AuthoredMap.ps1') } | Out-Null
    foreach ($role in @('Entry','Session','Infinite','Clash')) { Get-DevelopmentRoutingSource -Role $role -Configuration $Configuration | Out-Null }
    & { Set-StrictMode -Off; & (Join-Path $script:RepositoryRoot 'scripts/New-UiReviewPlace.ps1') -OutputName 'ui-review-development-base.rbxlx' -GameplayOnly } |
        ForEach-Object { Write-Host $_ }
    [xml]$base = [IO.File]::ReadAllText((Join-Path $script:RepositoryRoot 'build/ui-review-development-base.rbxlx'))
    $builds = [ordered]@{}
    foreach ($role in @('Entry','Session','Infinite','Clash')) {
        $path = Join-Path $script:RepositoryRoot ('build/ui-review-development-' + $role.ToLowerInvariant() + '.rbxlx')
        if (Test-Path -LiteralPath $path) { Assert-OrdinaryPath $path }
        [xml]$place = $base.CloneNode($true)
        $settingsModule = Find-ArtifactItem $place 'ServerScriptService/TycoonServer/Routing/Settings'
        $settingsModule.SelectSingleNode('Properties/*[@name="Source"]').InnerText = Get-DevelopmentRoutingSource -Role $role -Configuration $Configuration
        Assert-DevelopmentPlace -PlaceXml $place -Role $role -Configuration $Configuration
        $settings = [Xml.XmlWriterSettings]::new()
        $settings.OmitXmlDeclaration = $true; $settings.Indent = $true; $settings.Encoding = [Text.UTF8Encoding]::new($false)
        $writer = [Xml.XmlWriter]::Create($path, $settings)
        try { $place.Save($writer) } finally { $writer.Dispose() }
        $builds[$role] = $path
    }
    if ((Get-FileHash -LiteralPath $canonicalPath -Algorithm SHA256).Hash -cne $initialHash) {
        throw 'Deployment build changed the canonical scene.'
    }
    return $builds
}

Export-ModuleMember -Function Assert-DevelopmentPlace, New-DevelopmentPlaces, Get-DevelopmentRoutingSource
