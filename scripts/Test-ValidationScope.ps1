$ErrorActionPreference = 'Stop'
$scopeScript = Join-Path $PSScriptRoot 'Get-ValidationScope.ps1'

$cases = @(
    @{ Name = 'Markdown-only PR'; Event = 'pull_request'; Files = @('README.md', 'AGENTS.md', 'scripts/README.md'); Expected = $false },
    @{ Name = 'Server source'; Event = 'pull_request'; Files = @('src/server/Bootstrap.server.luau'); Expected = $true },
    @{ Name = 'Client source deletion'; Event = 'pull_request'; Files = @('src/client/Bootstrap.client.luau'); Expected = $true },
    @{ Name = 'Source renamed to Markdown'; Event = 'pull_request'; Files = @('src/server/Bootstrap.server.luau', 'src/server/Bootstrap.md'); Expected = $true },
    @{ Name = 'Root configuration'; Event = 'pull_request'; Files = @('rokit.toml', 'stylua.toml', 'selene.toml', 'default.project.json', '.gitattributes', '.editorconfig', '.gitignore'); Expected = $true },
    @{ Name = 'CI workflow'; Event = 'pull_request'; Files = @('.github/workflows/validate.yml'); Expected = $true },
    @{ Name = 'Tooling scripts'; Event = 'pull_request'; Files = @('scripts/Get-ValidationScope.ps1'); Expected = $true },
    @{ Name = 'Mixed documentation/source'; Event = 'pull_request'; Files = @('README.md', 'src/shared/Example.luau'); Expected = $true },
    @{ Name = 'Unknown future file type'; Event = 'pull_request'; Files = @('future.config'); Expected = $true },
    @{ Name = 'Manual full checkpoint'; Event = 'workflow_dispatch'; Files = @(); Expected = $true },
    @{ Name = 'Manual Markdown-only checkpoint'; Event = 'workflow_dispatch'; Files = @('README.md'); Expected = $true }
)

foreach ($case in $cases) {
    $actual = & $scopeScript -EventName $case.Event -ChangedFiles $case.Files
    if ($actual -isnot [bool] -or $actual -ne $case.Expected) {
        throw "Validation scope '$($case.Name)': expected $($case.Expected), got '$actual'."
    }
}

Write-Output "Validation scope: all $($cases.Count) cases passed."
