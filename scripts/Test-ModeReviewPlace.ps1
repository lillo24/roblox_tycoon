$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path $PSScriptRoot -Parent
$canonical = Join-Path $repositoryRoot 'place/tycoon.rbxlx'
$hash = (Get-FileHash -LiteralPath $canonical).Hash
[xml]$authored = [IO.File]::ReadAllText($canonical)
foreach ($role in @('Entry','Prototype','Infinite')) {
    $name = 'mode-helper-' + $role.ToLowerInvariant() + '.rbxlx'
    & (Join-Path $PSScriptRoot 'New-ModeReviewPlace.ps1') -Role $role -IncludeQA -Showcase:($role -eq 'Infinite') -OutputName $name
    [xml]$scene = [IO.File]::ReadAllText((Join-Path $repositoryRoot "build/$name"))
    if ($scene.SelectSingleNode('/roblox/Item[@class="Workspace"]').OuterXml -cne $authored.SelectSingleNode('/roblox/Item[@class="Workspace"]').OuterXml) { throw 'Mode preview changed authored geometry.' }
    $mode = $scene.SelectSingleNode("//Item[@class='StringValue'][Properties/string[@name='Name']='TycoonMode']/Properties/string[@name='Value']")
    if ($mode.InnerText -cne $role) { throw 'Preview role mismatch.' }
    $adapter = $scene.SelectSingleNode("//Item[@class='ModuleScript'][Properties/string[@name='Name']='ModePreview']/Properties/ProtectedString[@name='Source']")
    if (-not $adapter -or $adapter.InnerText.Replace("`r`n","`n") -cne [IO.File]::ReadAllText((Join-Path $repositoryRoot 'tests/fixtures/ModePreview.luau')).Replace("`r`n","`n")) { throw 'Missing exact local adapter source.' }
    $start = if ($role -eq 'Infinite') { 'StartLocalPreview' } else { 'StartModePreview' }
    $source = $scene.SelectSingleNode("//Item[@class='Script'][Properties/string[@name='Name']='$start']/Properties/ProtectedString[@name='Source']")
    if (-not $source.InnerText.Contains('AppRuntime).start') -or -not $source.InnerText.Contains('ModePreview')) { throw 'Preview does not start the trusted app boundary.' }
    if ($role -ne 'Infinite' -and $scene.SelectSingleNode("//Item[Properties/string[@name='Name']='INF01Preview']")) { throw 'Infinite fixtures leaked into entry/Session gameplay.' }
}
if ((Get-FileHash -LiteralPath $canonical).Hash -ne $hash) { throw 'Canonical scene changed.' }
Write-Output 'Mode preview roles, explicit adapters, startup boundary and canonical map checks passed.'
