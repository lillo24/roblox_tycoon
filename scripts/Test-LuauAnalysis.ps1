param(
    [Parameter(Mandatory = $true)]
    [string[]]$AnalysisArguments
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$repositoryRoot = Split-Path $PSScriptRoot -Parent
$probePath = Join-Path $repositoryRoot 'build/typecheck-probe.luau'

# A positive control prevents absent definitions/config errors from masquerading as rejection.
$cases = @(
    @{ Name = 'positive Roblox/Rojo control'; Exit = 0; Error = ''; Source = @'
--!strict
local Catalogue = require(game:GetService("ReplicatedStorage").TycoonShared.UpgradeCatalogue)
local cost: number = Catalogue.ById.income_booster.Cost
local player: Player? = game:GetService("Players"):GetPlayerByUserId(123)
local part = Instance.new("Part")
part.Size = Vector3.new(1, 1, 1)
return cost, player, part
'@ },
    @{ Name = 'ordinary Luau type mismatch'; Exit = 1; Error = "Expected this to be 'number', but got 'string'"; Source = @'
--!strict
local value: number = "wrong"
return value
'@ },
    @{ Name = 'Roblox property type'; Exit = 1; Error = "Expected this to be 'Vector3', but got 'number'"; Source = @'
--!strict
local part = Instance.new("Part")
part.Size = 42
return part
'@ },
    @{ Name = 'nullable Roblox return'; Exit = 1; Error = "got 'Player?'"; Source = @'
--!strict
local player: Player = game:GetService("Players"):GetPlayerByUserId(123)
return player
'@ },
    @{ Name = 'Rojo-resolved module type'; Exit = 1; Error = "Expected this to be 'string', but got 'number'"; Source = @'
--!strict
local Catalogue = require(game:GetService("ReplicatedStorage").TycoonShared.UpgradeCatalogue)
local cost: string = Catalogue.ById.income_booster.Cost
return cost
'@ },
    @{ Name = 'frozen cross-module tuning'; Exit = 1; Error = 'read-only property'; Source = @'
--!strict
local Catalogue = require(game:GetService("ReplicatedStorage").TycoonShared.UpgradeCatalogue)
type WritableDefinition = { Cost: number }
local definition: WritableDefinition = Catalogue.ById.income_booster
return definition
'@ }
)

Push-Location -LiteralPath $repositoryRoot
try {
    if (-not (Test-Path -LiteralPath 'build/sourcemap.json' -PathType Leaf)) {
        throw 'Luau probes require the fresh sourcemap produced by Validate-Project.ps1.'
    }
    if (Test-Path -LiteralPath $probePath) {
        throw "Luau probe output already exists: $probePath. Remove the stale generated file before retrying."
    }
    $before = @{}
    foreach ($file in Get-ChildItem -LiteralPath src, tests -Recurse -File) {
        $before[$file.FullName] = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
    }
    try {
        foreach ($case in $cases) {
            [System.IO.File]::WriteAllText($probePath, $case.Source + "`n", [System.Text.UTF8Encoding]::new($false))
            $output = @(& luau-lsp @AnalysisArguments 'build/typecheck-probe.luau' 2>&1)
            $code = $LASTEXITCODE
            $diagnostics = $output -join "`n"
            if ($code -ne $case.Exit -or
                ($case.Exit -ne 0 -and (-not $diagnostics.Contains('TypeError:') -or -not $diagnostics.Contains($case.Error)))) {
                throw "Luau probe '$($case.Name)' expected exit $($case.Exit) and '$($case.Error)', got exit ${code}:`n$diagnostics"
            }
        }
    } finally {
        # Delete only our generated leaf, even when the analyzer/probe fails.
        if (Test-Path -LiteralPath $probePath) { Remove-Item -LiteralPath $probePath }
        $after = @(Get-ChildItem -LiteralPath src, tests -Recurse -File)
        if ($after.Count -ne $before.Count) { throw 'Luau probes changed the source/test file set.' }
        foreach ($file in $after) {
            if (-not $before.ContainsKey($file.FullName) -or
                (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash -ne $before[$file.FullName]) {
                throw "Luau probes changed source/test content: $($file.FullName)"
            }
        }
    }
    Write-Output 'Luau analysis probes: positive control and 5 expected type failures passed; source/tests unchanged.'
} finally {
    Pop-Location
}
