param([xml]$Scene, [string]$RepositoryRoot = (Split-Path $PSScriptRoot -Parent), [switch]$CheckSnapshotCode)
$ErrorActionPreference = 'Stop'
if (-not $Scene) { [xml]$Scene = [IO.File]::ReadAllText((Join-Path $RepositoryRoot 'place/tycoon.rbxlx')) }
function Find-One($Parent, [string]$Name, [string]$Class) {
    $nodes = @($Parent.SelectNodes("Item[Properties/string[@name='Name']='$Name']"))
    if ($nodes.Count -ne 1 -or $nodes[0].GetAttribute('class') -ne $Class) {
        throw "Authored map: $Name expected one $Class, found $($nodes.Count)."
    }
    return $nodes[0]
}
function Get-Vector($Node, [string]$Name) {
    $v = $Node.SelectSingleNode("Properties/Vector3[@name='$Name']")
    if (-not $v) { throw "Authored map: missing Vector3 $Name." }
    return @([double]$v.X, [double]$v.Y, [double]$v.Z)
}
function Get-Frame($Node) {
    $v = $Node.SelectSingleNode("Properties/CoordinateFrame[@name='CFrame']")
    if (-not $v) { throw 'Authored map: missing CFrame.' }
    return @{ X=[double]$v.X; Y=[double]$v.Y; Z=[double]$v.Z; R00=[double]$v.R00; R02=[double]$v.R02; R10=[double]$v.R10; R11=[double]$v.R11; R12=[double]$v.R12; R20=[double]$v.R20; R22=[double]$v.R22 }
}
$workspaceNode = Find-One $Scene.roblox 'Workspace' 'Workspace'
$hub = Find-One $workspaceNode 'FactoryHub' 'Model'
$lots = Find-One $hub 'Lots' 'Folder'
if (@($lots.SelectNodes('Item')).Count -ne 6) { throw 'Authored map: exactly six lots required.' }
$cache = Get-Frame (Find-One $hub 'CacheAnchor' 'Part')
$frames = @()
for ($id=1; $id -le 6; $id++) {
    $lot = Find-One $lots "Lot$id" 'Model'
    $foundation = Find-One $lot 'Foundation' 'Part'
    $size = Get-Vector $foundation 'size'
    if ([math]::Abs($size[0]-60) -gt .01 -or [math]::Abs($size[2]-70) -gt .01) { throw "Authored map: Lot$id dimensions changed; update reviewed map contract." }
    $frame = Get-Frame (Find-One $lot 'Anchor' 'Part')
    $floor = Get-Frame $foundation
    if ([math]::Abs($frame.Y-($floor.Y+$size[1]/2)) -gt .01 -or [math]::Abs($frame.R11-1) -gt .001) { throw "Authored map: Lot$id anchor not at upright foundation top." }
    $dx=$cache.X-$frame.X; $dz=$cache.Z-$frame.Z
    $radius=[math]::Sqrt($dx*$dx+$dz*$dz)
    if ([math]::Abs($radius-110) -gt .01 -or (-$frame.R02*$dx-$frame.R22*$dz)/$radius -lt .999) { throw "Authored map: Lot$id ring or inward orientation invalid." }
    $entrance = Get-Frame (Find-One $lot 'Entrance' 'Part')
    if ([math]::Abs($entrance.X-($frame.X-$frame.R02*35)) -gt .01 -or [math]::Abs($entrance.Z-($frame.Z-$frame.R22*35)) -gt .01) { throw "Authored map: Lot$id entrance is not its front midpoint." }
    $frames += $frame
}
# SAT against the actual serialized rectangles, using each lot's local X and Z axes.
for ($a=0; $a -lt 6; $a++) {
    for ($b=$a+1; $b -lt 6; $b++) {
        $separated=$false
        foreach ($axis in @(@($frames[$a].R00,$frames[$a].R20),@($frames[$a].R02,$frames[$a].R22),@($frames[$b].R00,$frames[$b].R20),@($frames[$b].R02,$frames[$b].R22))) {
            $intervals=@()
            foreach ($f in @($frames[$a],$frames[$b])) {
                $center=$f.X*$axis[0]+$f.Z*$axis[1]
                $radius=30*[math]::Abs($f.R00*$axis[0]+$f.R20*$axis[1])+35*[math]::Abs($f.R02*$axis[0]+$f.R22*$axis[1])
                $intervals += ,@(($center-$radius),($center+$radius))
            }
            if ($intervals[0][1] -lt $intervals[1][0] -or $intervals[1][1] -lt $intervals[0][0]) { $separated=$true }
        }
        if (-not $separated) { throw "Authored map: Lot$($a+1)/Lot$($b+1) footprints intersect." }
    }
}
if (@($Scene.SelectNodes("//Item[@class='SpawnLocation']")).Count -ne 1) { throw 'Authored map: expected one spawn.' }
foreach ($part in $hub.SelectNodes(".//Item[@class='Part' or @class='SpawnLocation']")) {
    if ($part.SelectSingleNode("Properties/bool[@name='Anchored']").InnerText -ne 'true') { throw 'Authored map: unanchored map part.' }
}
foreach ($script in $Scene.SelectNodes("//Item[@class='Script' or @class='LocalScript' or @class='ModuleScript']")) {
    $owned=$false; $parent=$script.ParentNode
    while ($parent.Name -eq 'Item') {
        if ($parent.SelectSingleNode("Properties/string[@name='Name']").InnerText -in @('TycoonServer','TycoonClient','TycoonShared')) { $owned=$true; break }
        $parent=$parent.ParentNode
    }
    if (-not $owned) { throw 'Authored map: unreviewed script outside code-owned folders.' }
}
# Optional authoring-checkpoint check. Later code-only changes remain authoritative
# through Rojo and must not require resaving the authored scene's captured copies.
if ($CheckSnapshotCode) {
foreach ($mapping in @(
    @{ Area='server'; XPath="/roblox/Item[@class='ServerScriptService']/Item[Properties/string[@name='Name']='TycoonServer']" },
    @{ Area='shared'; XPath="/roblox/Item[@class='ReplicatedStorage']/Item[Properties/string[@name='Name']='TycoonShared']" },
    @{ Area='client'; XPath="/roblox/Item[@class='StarterPlayer']/Item[@class='StarterPlayerScripts']/Item[Properties/string[@name='Name']='TycoonClient']" }
)) {
    $folder=$Scene.SelectSingleNode($mapping.XPath)
    if (-not $folder) { throw "Authored map: missing mapped $($mapping.Area) folder." }
    $files=@(Get-ChildItem -LiteralPath (Join-Path $RepositoryRoot "src/$($mapping.Area)") -Filter '*.luau')
    if (@($folder.SelectNodes('Item')).Count -ne $files.Count) { throw "Authored map: wrong mapped $($mapping.Area) script count." }
    foreach ($file in $files) {
        $name=$file.BaseName -replace '\.(server|client)$',''
        $class=if ($file.Name -like '*.server.luau') { 'Script' } elseif ($file.Name -like '*.client.luau') { 'LocalScript' } else { 'ModuleScript' }
        $node=Find-One $folder $name $class
        $source=$node.SelectSingleNode("Properties/*[@name='Source']")
        if (-not $source -or $source.InnerText.Replace("`r`n","`n") -cne [IO.File]::ReadAllText($file.FullName).Replace("`r`n","`n")) {
            throw "Authored map: source differs from src/$($mapping.Area)/$($file.Name)."
        }
    }
}
}
if ($workspaceNode.SelectNodes("Item[Properties/string[@name='Name']='TycoonRuntime']").Count -ne 0) { throw 'Authored map: runtime residue was saved.' }
foreach ($grid in $Scene.SelectNodes("//Item[@class='Terrain']/Properties/BinaryString[@name='SmoothGrid' or @name='PhysicsGrid']")) {
    if ($grid.InnerText.Length -ne 0) { throw 'Authored map: obsolete terrain remains.' }
}
Write-Output 'Authored map: saved six-lot contract, inward frames, SAT separation, anchored parts, one spawn, code ownership and residue checks passed.'
