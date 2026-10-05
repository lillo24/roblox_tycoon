param(
    [Parameter(Mandatory = $true)]
    [xml]$PlaceXml,

    [Parameter(Mandatory = $true)]
    [object]$Project,

    [Parameter(Mandatory = $true)]
    [string]$RepositoryRoot
)

$ErrorActionPreference = 'Stop'

function Get-UniqueItem {
    param([string]$Path, [string]$Class)

    $xpath = '/roblox'
    foreach ($name in $Path.Split('/')) {
        $xpath += "/Item[Properties/string[@name='Name']='$name']"
    }
    $items = @($PlaceXml.SelectNodes($xpath))
    if ($items.Count -ne 1) {
        throw "Project structure: $Path expected exactly one instance, found $($items.Count)."
    }
    if ($items[0].GetAttribute('class') -cne $Class) {
        throw "Project structure: $Path expected $Class, found $($items[0].GetAttribute('class'))."
    }
    return $items[0]
}

$routingNodes = @(
    @{ Name = 'DataModel'; Node = $Project.tree; Class = 'DataModel' },
    @{ Name = 'ServerScriptService'; Node = $Project.tree.ServerScriptService; Class = 'ServerScriptService' },
    @{ Name = 'ReplicatedStorage'; Node = $Project.tree.ReplicatedStorage; Class = 'ReplicatedStorage' },
    @{ Name = 'StarterPlayer'; Node = $Project.tree.StarterPlayer; Class = 'StarterPlayer' },
    @{ Name = 'StarterPlayer/StarterPlayerScripts'; Node = $Project.tree.StarterPlayer.StarterPlayerScripts; Class = 'StarterPlayerScripts' }
)
foreach ($routing in $routingNodes) {
    if ($null -eq $routing.Node -or $routing.Node.'$ignoreUnknownInstances' -ne $true -or
        $null -ne $routing.Node.'$path' -or $routing.Node.'$className' -cne $routing.Class) {
        throw "Project structure: $($routing.Name) must preserve unknown children and remain a routing container."
    }
    if ($routing.Name -ne 'DataModel') {
        Get-UniqueItem -Path $routing.Name -Class $routing.Class | Out-Null
    }
}
if ($Project.serveAddress -cne '127.0.0.1') {
    throw 'Project structure: Rojo must bind to the documented loopback address 127.0.0.1.'
}
foreach ($property in $Project.tree.PSObject.Properties) {
    if (-not $property.Name.StartsWith('$') -and
        $property.Name -cnotin @('ServerScriptService', 'ReplicatedStorage', 'StarterPlayer')) {
        throw "Project structure: root owns unexpected Studio subtree $($property.Name)."
    }
}

$destinations = @(
    @{ Path = 'ServerScriptService/TycoonServer'; Node = $Project.tree.ServerScriptService.TycoonServer; Source = 'src/server' },
    @{ Path = 'ReplicatedStorage/TycoonShared'; Node = $Project.tree.ReplicatedStorage.TycoonShared; Source = 'src/shared' },
    @{ Path = 'StarterPlayer/StarterPlayerScripts/TycoonClient'; Node = $Project.tree.StarterPlayer.StarterPlayerScripts.TycoonClient; Source = 'src/client' }
)
foreach ($destination in $destinations) {
    if ($null -eq $destination.Node -or $destination.Node.'$className' -cne 'Folder' -or
        $destination.Node.'$path' -cne $destination.Source -or $destination.Node.'$ignoreUnknownInstances' -ne $false) {
        throw "Project structure: $($destination.Path) must own only $($destination.Source) as a reconciled Folder."
    }
    Get-UniqueItem -Path $destination.Path -Class 'Folder' | Out-Null
    $folderName = $destination.Path.Split('/')[-1]
    if (@($PlaceXml.SelectNodes("//Item[Properties/string[@name='Name']='$folderName']")).Count -ne 1) {
        throw "Project structure: reserved folder $folderName must appear exactly once in the generated place."
    }
    if (-not (Test-Path -LiteralPath (Join-Path $RepositoryRoot $destination.Source) -PathType Container)) {
        throw "Project structure: source directory $($destination.Source) is missing."
    }
}

function Get-MappedPaths {
    param([object]$Node)

    if ($Node -is [pscustomobject]) {
        foreach ($property in $Node.PSObject.Properties) {
            if ($property.Name -ceq '$path') { $property.Value }
            else { Get-MappedPaths -Node $property.Value }
        }
    }
}
$mappedPaths = @(Get-MappedPaths -Node $Project.tree)
if ($mappedPaths.Count -ne 3) {
    throw "Project structure: only three code paths may be mapped; found $($mappedPaths.Count)."
}

$bootstraps = @(
    @{ Path = 'ServerScriptService/TycoonServer/Bootstrap'; Class = 'Script'; Source = 'src/server/Bootstrap.server.luau' },
    @{ Path = 'StarterPlayer/StarterPlayerScripts/TycoonClient/Bootstrap'; Class = 'LocalScript'; Source = 'src/client/Bootstrap.client.luau' }
)
foreach ($bootstrap in $bootstraps) {
    $item = Get-UniqueItem -Path $bootstrap.Path -Class $bootstrap.Class
    $sourceNodes = @($item.SelectNodes('Properties/*[@name="Source"]'))
    $expectedSource = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot $bootstrap.Source))
    if ($sourceNodes.Count -ne 1 -or
        $sourceNodes[0].InnerText.Replace("`r`n", "`n") -cne $expectedSource.Replace("`r`n", "`n")) {
        throw "Project structure: $($bootstrap.Path) source differs from $($bootstrap.Source)."
    }
}
