param(
    [ValidateSet('Entry','Prototype','Infinite')][string]$Role = 'Entry',
    [ValidateSet('LateFailure','ImmediateFailure','MissingDestination')][string]$Scenario = 'LateFailure',
    [switch]$IncludeQA,
    [switch]$Showcase,
    [string]$OutputName = ''
)
$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path $PSScriptRoot -Parent
if (-not $OutputName) { $OutputName = 'mode-' + $(if ($Role -eq 'Prototype') { 'session' } else { $Role.ToLowerInvariant() }) + '.rbxlx' }
if ($OutputName -notmatch '^mode-[a-z0-9-]+\.rbxlx$') { throw 'OutputName must be a mode-*.rbxlx basename inside build.' }
if ($Showcase -and $Role -ne 'Infinite') { throw 'Showcase requires Infinite.' }
$output = Join-Path $repositoryRoot "build/$OutputName"
if (Test-Path -LiteralPath $output) {
    $item = Get-Item -LiteralPath $output -Force
    if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or $item.LinkType) { throw "Linked preview output refused: $output" }
}
if ($Role -eq 'Infinite') {
    & (Join-Path $PSScriptRoot 'New-InfiniteReviewPlace.ps1') -IncludeQA:$IncludeQA -Showcase:$Showcase -OutputName 'inf-mode-base.rbxlx'
    $base = 'build/inf-mode-base.rbxlx'
} else {
    & (Join-Path $PSScriptRoot 'New-UiReviewPlace.ps1') -GameplayOnly -OutputName 'ui-review-mode-base.rbxlx'
    $base = 'build/ui-review-mode-base.rbxlx'
}
[xml]$scene = [IO.File]::ReadAllText((Join-Path $repositoryRoot $base))
function Add-Item($Parent, [string]$Class, [string]$Name, [string]$Source = '') {
    $item = $scene.CreateElement('Item'); $item.SetAttribute('class',$Class); $item.SetAttribute('referent','MODE01_' + [guid]::NewGuid().ToString('N'))
    $properties = $scene.CreateElement('Properties')
    $nameNode = $scene.CreateElement('string'); $nameNode.SetAttribute('name','Name'); $nameNode.InnerText = $Name
    [void]$properties.AppendChild($nameNode)
    if ($Source) {
        $code = $scene.CreateElement('ProtectedString'); $code.SetAttribute('name','Source'); $code.InnerText = $Source
        [void]$properties.AppendChild($code)
    }
    [void]$item.AppendChild($properties); [void]$Parent.AppendChild($item); return $item
}
$server = $scene.SelectSingleNode('/roblox/Item[@class="ServerScriptService"]')
$replicated = $scene.SelectSingleNode('/roblox/Item[@class="ReplicatedStorage"]')
$folder = Add-Item $server 'Folder' 'MODE01Preview'
[void](Add-Item $folder 'ModuleScript' 'ModePreview' ([IO.File]::ReadAllText((Join-Path $repositoryRoot 'tests/fixtures/ModePreview.luau'))))
if ($Role -eq 'Infinite') {
    $source = $scene.SelectSingleNode("//Item[@class='Script'][Properties/string[@name='Name']='StartLocalPreview']/Properties/ProtectedString[@name='Source']")
    $source.InnerText = $source.InnerText.Replace('    examples = examples,' + "`n})", '    examples = examples,' + "`n}, require(game.ServerScriptService.MODE01Preview.ModePreview).new('Infinite', '$Scenario'))").Replace('    examples = examples,' + "`r`n})", '    examples = examples,' + "`r`n}, require(game.ServerScriptService.MODE01Preview.ModePreview).new('Infinite', '$Scenario'))")
    if (-not $source.InnerText.Contains('MODE01Preview.ModePreview')) { throw 'Could not install explicit Infinite routing adapter.' }
} else {
    $mode = Add-Item $replicated 'StringValue' 'TycoonMode'
    $value = $scene.CreateElement('string'); $value.SetAttribute('name','Value'); $value.InnerText = $Role
    [void]$mode.SelectSingleNode('Properties').AppendChild($value)
    $bootstrap = $scene.SelectSingleNode("//Item[@class='Script'][Properties/string[@name='Name']='Bootstrap']/Properties")
    foreach ($old in @($bootstrap.SelectNodes("bool[@name='Disabled']"))) { [void]$bootstrap.RemoveChild($old) }
    $disabled = $scene.CreateElement('bool'); $disabled.SetAttribute('name','Disabled'); $disabled.InnerText = 'true'; [void]$bootstrap.AppendChild($disabled)
    [void](Add-Item $folder 'Script' 'StartModePreview' "require(game.ServerScriptService.TycoonServer.AppRuntime).start(nil, require(script.Parent.ModePreview).new('$Role', '$Scenario'))")
}
if ($IncludeQA) {
    foreach ($test in @('Routing','Handoff','Session','SupplyEvent')) {
        [void](Add-Item $folder 'ModuleScript' $test ([IO.File]::ReadAllText((Join-Path $repositoryRoot "tests/$test.spec.luau"))))
    }
    [void](Add-Item $folder 'ModuleScript' 'ProfileMemoryStore' ([IO.File]::ReadAllText((Join-Path $repositoryRoot 'tests/fixtures/ProfileMemoryStore.luau'))))
    $runner = @'
print("MODE01 EXECUTED Routing assertions:", require(script.Parent.Routing)())
print("MODE01 EXECUTED Handoff assertions:", require(script.Parent.Handoff)(require(script.Parent.ProfileMemoryStore)))
local server, shared = game.ServerScriptService.TycoonServer, game.ReplicatedStorage.TycoonShared
print("MODE01 EXECUTED Session regression assertions:", require(script.Parent.Session)(require(server.Session), require(shared.Config), require(shared.UpgradeCatalogue)))
print("MODE01 EXECUTED SupplyEvent regression assertions:", require(script.Parent.SupplyEvent)(require(server.SupplyEvent), require(server.Session), require(shared.SupplyRules), require(shared.UpgradeCatalogue)))
'@
    [void](Add-Item $folder 'Script' 'RunAssertions' $runner)
    $starter = $scene.SelectSingleNode('/roblox/Item[@class="StarterPlayer"]/Item[@class="StarterPlayerScripts"]')
    [void](Add-Item $starter 'LocalScript' 'MODE01Observer' ([IO.File]::ReadAllText((Join-Path $repositoryRoot 'tests/fixtures/ModeClient.client.luau'))))
}
$settings = [Xml.XmlWriterSettings]::new(); $settings.OmitXmlDeclaration = $true; $settings.Indent = $true; $settings.Encoding = [Text.UTF8Encoding]::new($false)
$writer = [Xml.XmlWriter]::Create($output,$settings)
try { $scene.Save($writer) } finally { $writer.Dispose() }
Write-Output "Mode preview ($Role / $Scenario): $output"
Write-Output 'Local adapter only: no real teleport, publication or cross-session durability. Open each destination file separately.'
