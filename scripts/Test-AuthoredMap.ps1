$ErrorActionPreference = 'Stop'
$baseline = [IO.File]::ReadAllText((Join-Path (Split-Path $PSScriptRoot -Parent) 'place/tycoon.rbxlx'))
$cases = @(
    @{ Name='missing anchor'; Error='Anchor expected one Part'; XPath="//Item[Properties/string[@name='Name']='Lot1']/Item[Properties/string[@name='Name']='Anchor']"; Action='remove' },
    @{ Name='duplicate anchor'; Error='Anchor expected one Part'; XPath="//Item[Properties/string[@name='Name']='Lot1']/Item[Properties/string[@name='Name']='Anchor']"; Action='duplicate' },
    @{ Name='wrong dimensions'; Error='dimensions changed'; XPath="//Item[Properties/string[@name='Name']='Lot1']/Item[Properties/string[@name='Name']='Foundation']/Properties/Vector3[@name='size']/X"; Action='change'; Value='30' },
    @{ Name='wrong front'; Error='inward orientation invalid'; XPath="//Item[Properties/string[@name='Name']='Lot1']/Item[Properties/string[@name='Name']='Anchor']/Properties/CoordinateFrame[@name='CFrame']/R22"; Action='change'; Value='-1' },
    @{ Name='unanchored geometry'; Error='unanchored map part'; XPath="//Item[Properties/string[@name='Name']='Lot1']/Item[Properties/string[@name='Name']='Foundation']/Properties/bool[@name='Anchored']"; Action='change'; Value='false' },
    @{ Name='obsolete terrain'; Error='obsolete terrain remains'; XPath="//Item[@class='Terrain']/Properties/BinaryString[@name='SmoothGrid']"; Action='change'; Value='obsolete' },
    @{ Name='unowned script'; Error='unreviewed script outside code-owned folders'; XPath="//Item[Properties/string[@name='Name']='FactoryHub']"; Action='script' }
)
foreach ($case in $cases) {
    [xml]$copy=$baseline
    $node=$copy.SelectSingleNode($case.XPath)
    if (-not $node) { throw "Regression fixture not found: $($case.Name)" }
    switch ($case.Action) {
        'remove' { $node.ParentNode.RemoveChild($node) | Out-Null }
        'duplicate' { $node.ParentNode.AppendChild($node.CloneNode($true)) | Out-Null }
        'change' { $node.InnerText=$case.Value }
        'script' {
            $probe=$copy.CreateElement('Item'); $probe.SetAttribute('class','Script')
            $properties=$copy.CreateElement('Properties'); $name=$copy.CreateElement('string'); $name.SetAttribute('name','Name'); $name.InnerText='UnownedProbe'
            $properties.AppendChild($name) | Out-Null; $probe.AppendChild($properties) | Out-Null; $node.AppendChild($probe) | Out-Null
        }
    }
    $rejected=$false
    try { & (Join-Path $PSScriptRoot 'Assert-AuthoredMap.ps1') -Scene $copy | Out-Null }
    catch [System.Management.Automation.RuntimeException] {
        if (-not $_.Exception.Message.StartsWith('Authored map:') -or -not $_.Exception.Message.Contains($case.Error)) { throw }
        $rejected=$true
    }
    if (-not $rejected) { throw "Authored regression '$($case.Name)' was not rejected." }
}
Write-Output "Authored map: all $($cases.Count) serialized regression probes passed."
