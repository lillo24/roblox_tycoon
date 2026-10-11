param(
    [ValidateSet('LocalPreview', 'DataStore')][string]$Backend = 'LocalPreview',
    [switch]$IncludeQA,
    [switch]$Showcase,
    [string]$OutputName = 'inf-review.rbxlx'
)
$ErrorActionPreference = 'Stop'
if ($Showcase -and $Backend -ne 'LocalPreview') { throw 'Showcase presets are only allowed with the explicit local memory backend.' }
$repositoryRoot = Split-Path $PSScriptRoot -Parent
if ($OutputName -notmatch '^inf-[a-z0-9-]+\.rbxlx$') { throw 'OutputName must be an inf-*.rbxlx basename inside build.' }
$output = Join-Path $repositoryRoot "build/$OutputName"
if (Test-Path -LiteralPath $output) {
    $item = Get-Item -LiteralPath $output -Force
    if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or $item.LinkType) { throw "Linked preview output refused: $output" }
}
& (Join-Path $PSScriptRoot 'New-UiReviewPlace.ps1') -GameplayOnly -OutputName 'ui-review-inf-base.rbxlx'
[xml]$scene = [IO.File]::ReadAllText((Join-Path $repositoryRoot 'build/ui-review-inf-base.rbxlx'))
function Add-Item($Parent, [string]$Class, [string]$Name, [string]$Source = '') {
    $item = $scene.CreateElement('Item')
    $item.SetAttribute('class', $Class)
    $item.SetAttribute('referent', 'INF01_' + [guid]::NewGuid().ToString('N'))
    $properties = $scene.CreateElement('Properties')
    $nameNode = $scene.CreateElement('string'); $nameNode.SetAttribute('name', 'Name'); $nameNode.InnerText = $Name
    [void]$properties.AppendChild($nameNode)
    if ($Source) {
        $code = $scene.CreateElement('ProtectedString'); $code.SetAttribute('name', 'Source'); $code.InnerText = $Source
        [void]$properties.AppendChild($code)
    }
    [void]$item.AppendChild($properties); [void]$Parent.AppendChild($item)
    return $item
}
$replicated = $scene.SelectSingleNode('/roblox/Item[@class="ReplicatedStorage"]')
$server = $scene.SelectSingleNode('/roblox/Item[@class="ServerScriptService"]')
$mode = Add-Item $replicated 'StringValue' 'TycoonMode'
$value = $scene.CreateElement('string'); $value.SetAttribute('name', 'Value'); $value.InnerText = 'Infinite'
[void]$mode.SelectSingleNode('Properties').AppendChild($value)
if ($Backend -eq 'LocalPreview' -or $IncludeQA) {
    $qa = Add-Item $server 'Folder' 'INF01Preview'
    [void](Add-Item $qa 'ModuleScript' 'ProfileMemoryStore' ([IO.File]::ReadAllText((Join-Path $repositoryRoot 'tests/fixtures/ProfileMemoryStore.luau'))))
}
if ($Backend -eq 'LocalPreview') {
    if ($Showcase) { [void](Add-Item $qa 'ModuleScript' 'InfiniteShowcase' ([IO.File]::ReadAllText((Join-Path $repositoryRoot 'tests/fixtures/InfiniteShowcase.luau')))) }
    $bootstrap = $server.SelectSingleNode("Item[Properties/string[@name='Name']='TycoonServer']/Item[@class='Script'][Properties/string[@name='Name']='Bootstrap']/Properties")
    foreach ($old in @($bootstrap.SelectNodes("bool[@name='Disabled']"))) { [void]$bootstrap.RemoveChild($old) }
    $disabled = $scene.CreateElement('bool'); $disabled.SetAttribute('name', 'Disabled'); $disabled.InnerText = 'true'
    [void]$bootstrap.AppendChild($disabled)
    $start = @'
-- Disposable preview only. Does not call DataStoreService and resets on Stop.
local memory = require(script.Parent.ProfileMemoryStore).new()
local examples
if script.Parent:FindFirstChild("InfiniteShowcase") then
    local showcase = require(script.Parent.InfiniteShowcase)
    memory.values["user_-1001"] = { version = 1, data = showcase.make("Garden") }
    memory.values["user_-1002"] = { version = 1, data = showcase.make("Sky") }
    examples = { [-1001] = "The Glass Garden", [-1002] = "The Sky Workshop" }
end
require(game.ServerScriptService.TycoonServer.AppRuntime).start({
    update = memory.update,
    label = "Local preview • changes last only this server",
    examples = examples,
})
print("INF01 LOCAL PREVIEW: memory backend, no cross-session saving evidence")
'@
    [void](Add-Item $qa 'Script' 'StartLocalPreview' $start)
}
if ($IncludeQA) {
    foreach ($test in @('Persistence', 'ProfileLifecycle', 'PropertyWorld', 'PropertyRendering', 'InfiniteState', 'Session', 'SupplyEvent', 'Property', 'Growth')) {
        [void](Add-Item $qa 'ModuleScript' $test ([IO.File]::ReadAllText((Join-Path $repositoryRoot "tests/$test.spec.luau"))))
    }
    [void](Add-Item $qa 'ModuleScript' 'GrowthPresets' ([IO.File]::ReadAllText((Join-Path $repositoryRoot 'tests/fixtures/InfiniteShowcase.luau'))))
    $runner = @'
local memory = require(script.Parent.ProfileMemoryStore)
print("INF02 EXECUTED Property assertions:", require(script.Parent.Property)(memory))
print("INF03 EXECUTED Growth assertions:", require(script.Parent.Growth)(memory, require(script.Parent.GrowthPresets)))
print("PERF01 EXECUTED PropertyRendering assertions:", require(script.Parent.PropertyRendering)())
print("INF01 EXECUTED Persistence assertions:", require(script.Parent.Persistence)(memory))
print("INF01 EXECUTED ProfileLifecycle assertions:", require(script.Parent.ProfileLifecycle)(memory))
print("INF01 EXECUTED InfiniteState assertions:", require(script.Parent.InfiniteState)())
local server, shared = game.ServerScriptService.TycoonServer, game.ReplicatedStorage.TycoonShared
print("INF01 EXECUTED Session regression assertions:", require(script.Parent.Session)(require(server.Session), require(shared.Config), require(shared.UpgradeCatalogue)))
print("INF01 EXECUTED SupplyEvent regression assertions:", require(script.Parent.SupplyEvent)(require(server.SupplyEvent), require(server.Session), require(shared.SupplyRules), require(shared.UpgradeCatalogue)))
'@
    [void](Add-Item $qa 'Script' 'RunAssertions' $runner)
    $clientQA = Add-Item $replicated 'Folder' 'INF01ClientQA'
    [void](Add-Item $clientQA 'LocalScript' 'ObserveClient' ([IO.File]::ReadAllText((Join-Path $repositoryRoot 'tests/fixtures/InfiniteClient.client.luau'))))
    $starter = $scene.SelectSingleNode('/roblox/Item[@class="StarterPlayer"]/Item[@class="StarterPlayerScripts"]')
    [void](Add-Item $starter 'LocalScript' 'INF01ClientObserver' ([IO.File]::ReadAllText((Join-Path $repositoryRoot 'tests/fixtures/InfiniteClient.client.luau'))))
}
$settings = [Xml.XmlWriterSettings]::new()
$settings.OmitXmlDeclaration = $true; $settings.Indent = $true; $settings.Encoding = [Text.UTF8Encoding]::new($false)
$writer = [Xml.XmlWriter]::Create($output, $settings)
try { $scene.Save($writer) } finally { $writer.Dispose() }
Write-Output "Infinite preview ($Backend, IncludeQA=$IncludeQA): $output"
if ($Backend -eq 'LocalPreview') { Write-Output 'Explicit memory fixture: playable locally, resets on Stop; NOT real DataStore evidence.' }
else { Write-Output 'Real persistence path: requires an isolated published test universe configured in Persistence/Settings; no fallback.' }
