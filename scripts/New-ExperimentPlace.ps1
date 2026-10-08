param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z][A-Za-z0-9]*$')]
    [string]$Name,
    [switch]$WithTests
)

# Experiments opt in only in disposable output: normal bootstraps are untouched.
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
foreach ($area in @('server', 'client', 'shared')) {
    if (-not (Test-Path -LiteralPath (Join-Path $root "src/$area/Experiments/$Name") -PathType Container)) {
        throw "Experiment $Name missing src/$area/Experiments/$Name."
    }
}
$canonical = Join-Path $root 'place/tycoon.rbxlx'
$hash = (Get-FileHash -LiteralPath $canonical -Algorithm SHA256).Hash
$basename = 'ui-review-exp-' + $Name.ToLowerInvariant() + $(if ($WithTests) { '-qa' }) + '.rbxlx'
& "$PSScriptRoot/New-UiReviewPlace.ps1" -GameplayOnly -OutputName $basename
$output = Join-Path $root "build/$basename"
[xml]$scene = [IO.File]::ReadAllText($output)
$routes = @(
    @{ Path = '/roblox/Item[@class="ServerScriptService"]/Item[Properties/string[@name="Name"]="TycoonServer"]/Item[Properties/string[@name="Name"]="Bootstrap"]'; Code = "--!strict`nrequire(script.Parent.Experiments.$Name.Runtime).start()`n" },
    @{ Path = '/roblox/Item[@class="StarterPlayer"]/Item[@class="StarterPlayerScripts"]/Item[Properties/string[@name="Name"]="TycoonClient"]/Item[Properties/string[@name="Name"]="Bootstrap"]'; Code = "--!strict`nrequire(script.Parent.Experiments.$Name.Controller).start()`n" }
)
foreach ($route in $routes) {
    $items = @($scene.SelectNodes($route.Path))
    if ($items.Count -ne 1) { throw "Experiment preview missing unique bootstrap $($route.Path)." }
    $source = $items[0].SelectSingleNode('Properties/*[@name="Source"]')
    if (-not $source) { throw 'Experiment preview bootstrap has no Source.' }
    $source.InnerText = $route.Code
}
if ($WithTests) {
    $testPath = Join-Path $root "tests/$Name.spec.luau"
    if (-not (Test-Path -LiteralPath $testPath -PathType Leaf)) { throw "Experiment test missing: $testPath" }
    $parent = $scene.SelectSingleNode('/roblox/Item[@class="ServerScriptService"]')
    foreach ($definition in @(
        @{ Class = 'ModuleScript'; Name = 'ExperimentAssertions'; Code = [IO.File]::ReadAllText($testPath) },
        @{ Class = 'Script'; Name = 'RunExperimentAssertions'; Code = "print('EXECUTED $Name assertions:', require(script.Parent.ExperimentAssertions)())" }
    )) {
        $item = $scene.CreateElement('Item')
        $item.SetAttribute('class', $definition.Class)
        $item.SetAttribute('referent', 'EXP_' + [guid]::NewGuid().ToString('N'))
        $properties = $scene.CreateElement('Properties')
        foreach ($field in @(
            @{ Class = 'string'; Name = 'Name'; Value = $definition.Name },
            @{ Class = 'ProtectedString'; Name = 'Source'; Value = $definition.Code }
        )) {
            $node = $scene.CreateElement($field.Class)
            $node.SetAttribute('name', $field.Name)
            $node.InnerText = $field.Value
            [void]$properties.AppendChild($node)
        }
        [void]$item.AppendChild($properties)
        [void]$parent.AppendChild($item)
    }
    # Optional engine integration fixture belongs only to the explicit QA copy.
    # It may seed positions or walk the first test avatar; never included in demo.
    $livePath = Join-Path $root "tests/${Name}Live.spec.luau"
    if (Test-Path -LiteralPath $livePath -PathType Leaf) {
        $item = $scene.CreateElement('Item')
        $item.SetAttribute('class', 'ModuleScript')
        $item.SetAttribute('referent', 'EXP_' + [guid]::NewGuid().ToString('N'))
        $properties = $scene.CreateElement('Properties')
        $nameNode = $scene.CreateElement('string')
        $nameNode.SetAttribute('name', 'Name')
        $nameNode.InnerText = 'ExperimentLiveAssertions'
        $sourceNode = $scene.CreateElement('ProtectedString')
        $sourceNode.SetAttribute('name', 'Source')
        $sourceNode.InnerText = [IO.File]::ReadAllText($livePath)
        [void]$properties.AppendChild($nameNode)
        [void]$properties.AppendChild($sourceNode)
        [void]$item.AppendChild($properties)
        [void]$parent.AppendChild($item)
        $runner = $parent.SelectSingleNode('Item[Properties/string[@name="Name"]="RunExperimentAssertions"]/Properties/*[@name="Source"]')
        $runner.InnerText += "`nprint('EXECUTED $Name LIVE assertions:', require(script.Parent.ExperimentLiveAssertions)())"
    }
}
$settings = [Xml.XmlWriterSettings]::new()
$settings.OmitXmlDeclaration = $true
$settings.Indent = $true
$settings.Encoding = [Text.UTF8Encoding]::new($false)
$writer = [Xml.XmlWriter]::Create($output, $settings)
try { $scene.Save($writer) } finally { $writer.Dispose() }
if ((Get-FileHash -LiteralPath $canonical -Algorithm SHA256).Hash -ne $hash) { throw 'Experiment preview modified canonical scene.' }
Write-Output "Experiment preview: $output"
Write-Output 'Only these disposable bootstrap copies opt in. Do not Rojo-sync normal bootstraps over this preview; regenerate it after edits.'
