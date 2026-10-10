param(
    [ValidateSet('Fresh','Developed','Dense','SixOwners')][string]$Workload = 'Fresh',
    [string]$OutputName = '',
    [switch]$CaptureDiagnostics
)
$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path $PSScriptRoot -Parent
if (-not $OutputName) { $OutputName = 'mode-perf-' + $Workload.ToLowerInvariant() + '.rbxlx' }
if ($OutputName -notmatch '^mode-perf-[a-z0-9-]+\.rbxlx$') { throw 'OutputName must be a mode-perf-*.rbxlx basename inside build.' }
$output = Join-Path $repositoryRoot "build/$OutputName"
if (Test-Path -LiteralPath $output) {
    $item = Get-Item -LiteralPath $output -Force
    if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or $item.LinkType) { throw "Linked preview output refused: $output" }
}
& (Join-Path $PSScriptRoot 'New-ModeReviewPlace.ps1') -Role Infinite -OutputName 'mode-perf-base.rbxlx'
[xml]$scene = [IO.File]::ReadAllText((Join-Path $repositoryRoot 'build/mode-perf-base.rbxlx'))
function Add-Item($Parent, [string]$Class, [string]$Name, [string]$Source = '') {
    $item = $scene.CreateElement('Item'); $item.SetAttribute('class',$Class); $item.SetAttribute('referent','PERF01_' + [guid]::NewGuid().ToString('N'))
    $properties = $scene.CreateElement('Properties')
    $nameNode = $scene.CreateElement('string'); $nameNode.SetAttribute('name','Name'); $nameNode.InnerText = $Name
    [void]$properties.AppendChild($nameNode)
    if ($Source) {
        $code = $scene.CreateElement('ProtectedString'); $code.SetAttribute('name','Source'); $code.InnerText = $Source
        [void]$properties.AppendChild($code)
    }
    [void]$item.AppendChild($properties); [void]$Parent.AppendChild($item); return $item
}
$server = $scene.SelectSingleNode('/roblox/Item[@class="ServerScriptService"]/Item[Properties/string[@name="Name"]="INF01Preview"]')
$modeAdapter = $scene.SelectSingleNode('//Item[@class="ModuleScript"][Properties/string[@name="Name"]="ModePreview"]')
[void]$server.AppendChild($modeAdapter.CloneNode($true))
foreach ($file in @('Server','Workloads')) {
    [void](Add-Item $server 'ModuleScript' $file ([IO.File]::ReadAllText((Join-Path $repositoryRoot "tests/fixtures/Performance/$file.luau"))))
}
[void](Add-Item $server 'ModuleScript' 'InfiniteShowcase' ([IO.File]::ReadAllText((Join-Path $repositoryRoot 'tests/fixtures/InfiniteShowcase.luau'))))
$start = $server.SelectSingleNode('Item[@class="Script"][Properties/string[@name="Name"]="StartLocalPreview"]/Properties/ProtectedString[@name="Source"]')
$start.InnerText = "require(script.Parent.Server).start('$Workload')"
$replicated = $scene.SelectSingleNode('/roblox/Item[@class="ReplicatedStorage"]')
$control = Add-Item $replicated 'Folder' 'PERF01'
[void](Add-Item $control 'ModuleScript' 'Sampler' ([IO.File]::ReadAllText((Join-Path $repositoryRoot 'tests/fixtures/Performance/Sampler.luau'))))
$starter = $scene.SelectSingleNode('/roblox/Item[@class="StarterPlayer"]/Item[@class="StarterPlayerScripts"]')
[void](Add-Item $starter 'LocalScript' 'PERF01Client' ([IO.File]::ReadAllText((Join-Path $repositoryRoot 'tests/fixtures/Performance/Client.client.luau'))))
if ($CaptureDiagnostics) {
    [void](Add-Item $starter 'LocalScript' 'PERF03Capture' ([IO.File]::ReadAllText((Join-Path $repositoryRoot 'tests/fixtures/Performance/Capture.client.luau'))))
}
$settings = [Xml.XmlWriterSettings]::new(); $settings.OmitXmlDeclaration = $true; $settings.Indent = $true; $settings.Encoding = [Text.UTF8Encoding]::new($false)
$writer = [Xml.XmlWriter]::Create($output,$settings)
try { $scene.Save($writer) } finally { $writer.Dispose() }
Write-Output "PERF01 $Workload (local memory, unmapped probes): $output"
