param(
    [string]$OutputName = 'ui-review-main.rbxlx'
)

# Disposable local QA only. No production mapping, scene save, or gameplay hook.
$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path $PSScriptRoot -Parent
if ($OutputName -notmatch '^ui-review-[a-z0-9-]+\.rbxlx$') {
    throw 'OutputName must be a ui-review-*.rbxlx basename inside build.'
}
$canonical = Join-Path $repositoryRoot 'place/tycoon.rbxlx'
$initialHash = (Get-FileHash -LiteralPath $canonical -Algorithm SHA256).Hash
$build = Join-Path $repositoryRoot 'build'
$mapped = Join-Path $build 'ui-review-source.rbxlx'
$output = Join-Path $build $OutputName
foreach ($path in @($build, $mapped, $output)) {
    if (Test-Path -LiteralPath $path) {
        $item = Get-Item -LiteralPath $path -Force
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or $item.LinkType) {
            throw "Review output cannot be linked: $path"
        }
    }
}
New-Item -ItemType Directory -Force -Path $build | Out-Null
Push-Location -LiteralPath $repositoryRoot
try {
    & rojo build default.project.json --output $mapped
    if ($LASTEXITCODE -ne 0) { throw 'UI review source build failed.' }
    [xml]$scene = [IO.File]::ReadAllText($canonical)
    [xml]$source = [IO.File]::ReadAllText($mapped)
    $routes = @(
        @{ Parent = '/roblox/Item[@class="ServerScriptService"]'; Folder = 'TycoonServer' },
        @{ Parent = '/roblox/Item[@class="ReplicatedStorage"]'; Folder = 'TycoonShared' },
        @{ Parent = '/roblox/Item[@class="StarterPlayer"]/Item[@class="StarterPlayerScripts"]'; Folder = 'TycoonClient' }
    )
    foreach ($route in $routes) {
        $targetParent = $scene.SelectSingleNode($route.Parent)
        if (-not $targetParent) { throw "Scene missing route $($route.Parent)" }
        $folder = $source.SelectSingleNode("$($route.Parent)/Item[Properties/string[@name='Name']='$($route.Folder)']")
        if (-not $folder) { throw "Build missing mapped folder $($route.Folder)" }
        foreach ($old in @($targetParent.SelectNodes("Item[Properties/string[@name='Name']='$($route.Folder)']"))) {
            [void]$targetParent.RemoveChild($old)
        }
        $imported = $scene.ImportNode($folder, $true)
        foreach ($item in @($imported) + @($imported.SelectNodes('.//Item'))) {
            $item.SetAttribute('referent', 'UI01_' + [guid]::NewGuid().ToString('N'))
        }
        [void]$targetParent.AppendChild($imported)
    }
    function Add-QAItem([System.Xml.XmlElement]$Parent, [string]$Class, [string]$Name, [string]$Code) {
        $item = $scene.CreateElement('Item')
        $item.SetAttribute('class', $Class)
        $item.SetAttribute('referent', 'UI01_' + [guid]::NewGuid().ToString('N'))
        $properties = $scene.CreateElement('Properties')
        $nameNode = $scene.CreateElement('string')
        $nameNode.SetAttribute('name', 'Name')
        $nameNode.InnerText = $Name
        [void]$properties.AppendChild($nameNode)
        if ($Code) {
            $sourceNode = $scene.CreateElement('ProtectedString')
            $sourceNode.SetAttribute('name', 'Source')
            $sourceNode.InnerText = $Code
            [void]$properties.AppendChild($sourceNode)
        }
        [void]$item.AppendChild($properties)
        [void]$Parent.AppendChild($item)
        return $item
    }
    $server = $scene.SelectSingleNode('/roblox/Item[@class="ServerScriptService"]')
    $qa = Add-QAItem $server 'Folder' 'UI01QA' ''
    foreach ($test in @('SupplyFeedback', 'UiState', 'WorldLabels')) {
        [void](Add-QAItem $qa 'ModuleScript' $test ([IO.File]::ReadAllText((Join-Path $repositoryRoot "tests/$test.spec.luau"))))
    }
    $runner = @'
local client = game.StarterPlayer.StarterPlayerScripts:WaitForChild("TycoonClient")
local shared = game.ReplicatedStorage:WaitForChild("TycoonShared")
local feedback = require(script.Parent.SupplyFeedback)(require(client.SupplyFeedback))
local ui = require(script.Parent.UiState)(require(client.UiState), require(client.UiPreferences), require(shared.Config), require(shared.UpgradeCatalogue))
local labels = require(script.Parent.WorldLabels)(require(client.WorldLabels))
print("UI01 EXECUTED SupplyFeedback assertions:", feedback, "UiState assertions:", ui, "WorldLabels assertions:", labels)
'@
    [void](Add-QAItem $qa 'Script' 'RunAssertions' $runner)
    $replicated = $scene.SelectSingleNode('/roblox/Item[@class="ReplicatedStorage"]')
    $clientQA = Add-QAItem $replicated 'Folder' 'UI01ClientQA' ''
    foreach ($test in @('HudLifecycle', 'HudFeedback')) {
        [void](Add-QAItem $clientQA 'ModuleScript' $test ([IO.File]::ReadAllText((Join-Path $repositoryRoot "tests/$test.spec.luau"))))
    }
    [void](Add-QAItem $replicated 'RemoteEvent' 'UI01OrderQA' '')
    $delivery = @'
-- Disposable preview fixture only. No gameplay mutation or production mapping.
local shared = game.ReplicatedStorage:WaitForChild("TycoonShared")
local config, rules = require(shared.Config), require(shared.SupplyRules)
game.ReplicatedStorage.UI01OrderQA.OnServerEvent:Connect(function(player)
    local state = game:GetService("HttpService"):JSONDecode(game.ReplicatedStorage[rules.StateName].Value)
    assert(state.phase ~= "idle", "UI01 feedback fixture: run during warning/open/resolved, not idle")
    game.ReplicatedStorage[rules.FeedbackName]:FireClient(player, state.id, "UI01 receipt-before-snapshot")
    game.ReplicatedStorage[config.FeedbackName]:FireClient(player, player:GetAttribute(config.Attributes.PlotId), "UI01 independent purchase")
end)
'@
    [void](Add-QAItem $qa 'Script' 'OrderFixture' $delivery)
    $scene.Save($output)
    if ((Get-FileHash -LiteralPath $canonical -Algorithm SHA256).Hash -ne $initialHash) {
        throw 'Canonical scene changed while constructing disposable preview.'
    }
    Write-Output "Disposable UI review: $output"
    Write-Output "Canonical scene unchanged: $initialHash"
    Write-Output 'Play executes SupplyFeedback/UiState/WorldLabels assertions. UI01ClientQA contains opt-in lifecycle/delivery checks; see docs/UI_01_REVIEW.md. QA exists only in this disposable place.'
} finally {
    Pop-Location
}
