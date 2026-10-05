$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path $PSScriptRoot -Parent
$assertScript = Join-Path $PSScriptRoot 'Assert-ProjectStructure.ps1'
$baselineXml = [System.IO.File]::ReadAllText((Join-Path $repositoryRoot 'build/validation.rbxlx'))
$baselineProject = [System.IO.File]::ReadAllText((Join-Path $repositoryRoot 'default.project.json'))

# Mutate copies in memory only; never write test instances or source onto disk.
$cases = @(
    @{ Name = 'missing shared folder'; Error = 'ReplicatedStorage/TycoonShared expected exactly one'; Mutate = {
        param($xml, $project)
        $node = $xml.SelectSingleNode('//Item[Properties/string[@name="Name"]="TycoonShared"]')
        $node.ParentNode.RemoveChild($node) | Out-Null
    } },
    @{ Name = 'duplicate server folder'; Error = 'ServerScriptService/TycoonServer expected exactly one'; Mutate = {
        param($xml, $project)
        $node = $xml.SelectSingleNode('//Item[Properties/string[@name="Name"]="TycoonServer"]')
        $node.ParentNode.AppendChild($node.CloneNode($true)) | Out-Null
    } },
    @{ Name = 'wrong folder class'; Error = 'TycoonShared expected Folder'; Mutate = {
        param($xml, $project)
        $xml.SelectSingleNode('//Item[Properties/string[@name="Name"]="TycoonShared"]').SetAttribute('class', 'Model')
    } },
    @{ Name = 'wrong server script class'; Error = 'TycoonServer/Bootstrap expected Script'; Mutate = {
        param($xml, $project)
        $xml.SelectSingleNode('//Item[@class="Script"]').SetAttribute('class', 'LocalScript')
    } },
    @{ Name = 'wrong client script class'; Error = 'TycoonClient/Bootstrap expected LocalScript'; Mutate = {
        param($xml, $project)
        $xml.SelectSingleNode('//Item[@class="LocalScript"]').SetAttribute('class', 'Script')
    } },
    @{ Name = 'stale bootstrap source'; Error = 'source differs from src/server/Bootstrap.server.luau'; Mutate = {
        param($xml, $project)
        $xml.SelectSingleNode('//Item[@class="Script"]/Properties/*[@name="Source"]').InnerText = '-- stale code'
    } },
    @{ Name = 'lost ancestor preservation'; Error = 'DataModel must preserve unknown'; Mutate = {
        param($xml, $project)
        $project.tree.'$ignoreUnknownInstances' = $false
    } },
    @{ Name = 'whole service ownership'; Error = 'ReplicatedStorage must preserve unknown'; Mutate = {
        param($xml, $project)
        $project.tree.ReplicatedStorage | Add-Member -NotePropertyName '$path' -NotePropertyValue 'src/shared'
    } },
    @{ Name = 'broadened Workspace ownership'; Error = 'unexpected Studio subtree Workspace'; Mutate = {
        param($xml, $project)
        $project.tree | Add-Member -NotePropertyName Workspace -NotePropertyValue ([pscustomobject]@{ '$path' = 'src/shared' })
    } },
    @{ Name = 'extra mapping under a service'; Error = 'only three code paths'; Mutate = {
        param($xml, $project)
        $project.tree.ReplicatedStorage | Add-Member -NotePropertyName Extra -NotePropertyValue ([pscustomobject]@{ '$path' = 'src/server' })
    } },
    @{ Name = 'incorrect shared path'; Error = 'TycoonShared must own only src/shared'; Mutate = {
        param($xml, $project)
        $project.tree.ReplicatedStorage.TycoonShared.'$path' = 'src/server'
    } },
    @{ Name = 'public server binding'; Error = 'Rojo must bind'; Mutate = {
        param($xml, $project)
        $project.serveAddress = '0.0.0.0'
    } }
)

foreach ($case in $cases) {
    [xml]$xmlCopy = $baselineXml
    $projectCopy = $baselineProject | ConvertFrom-Json
    & $case.Mutate $xmlCopy $projectCopy
    $rejected = $false
    try {
        & $assertScript -PlaceXml $xmlCopy -Project $projectCopy -RepositoryRoot $repositoryRoot
    } catch [System.Management.Automation.RuntimeException] {
        if (-not $_.Exception.Message.StartsWith('Project structure:') -or
            -not $_.Exception.Message.Contains($case.Error)) { throw }
        $rejected = $true
    }
    if (-not $rejected) { throw "Structural regression '$($case.Name)' was not rejected." }
}

Write-Output "Project structure: all $($cases.Count) regression probes passed."
