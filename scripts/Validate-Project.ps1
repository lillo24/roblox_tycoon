$ErrorActionPreference = 'Stop'
# Handle native exit codes explicitly, including check-ignore's expected exit 1.
$PSNativeCommandUseErrorActionPreference = $false
$repositoryRoot = Split-Path $PSScriptRoot -Parent

function Invoke-CheckedNative {
    param([string]$Command, [string[]]$Arguments)

    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Validation command '$Command $($Arguments -join ' ')' failed with exit code $LASTEXITCODE."
    }
}

Push-Location -LiteralPath $repositoryRoot
try {
    ./scripts/Test-ValidationScope.ps1
    Invoke-CheckedNative -Command git -Arguments @('ls-files', '--error-unmatch', '--',
        'src/server/Bootstrap.server.luau', 'src/client/Bootstrap.client.luau', 'src/shared/.gitkeep')

    # The output is fixed and cannot be redirected onto the authored snapshot.
    $buildDirectory = Join-Path $repositoryRoot 'build'
    $buildPath = Join-Path $buildDirectory 'validation.rbxlx'
    $sourcemapPath = Join-Path $buildDirectory 'sourcemap.json'
    foreach ($ignoredPath in @('build/validation.rbxlx', 'build/sourcemap.json', 'build/typecheck-probe.luau', 'place/scratch.rbxlx',
        'place/tycoon.rbxlx.lock', 'place/AutoSaves/tycoon.rbxlx')) {
        Invoke-CheckedNative -Command git -Arguments @('check-ignore', '--no-index', '-q', '--', $ignoredPath)
    }
    & git check-ignore --no-index -q -- place/tycoon.rbxlx
    if ($LASTEXITCODE -ne 1) {
        throw "Canonical place/tycoon.rbxlx must be trackable; git check-ignore returned $LASTEXITCODE (expected 1)."
    }

    # Refuse linked output locations instead of potentially overwriting source.
    foreach ($outputPath in @($buildDirectory, $buildPath, $sourcemapPath)) {
        if (Test-Path -LiteralPath $outputPath) {
            $outputItem = Get-Item -LiteralPath $outputPath -Force
            if (($outputItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0 -or $outputItem.LinkType) {
                throw "Validation output must not be a symbolic link, junction, or hard link: $outputPath"
            }
        }
    }

    Invoke-CheckedNative -Command stylua -Arguments @('--check', 'src', 'tests')
    Invoke-CheckedNative -Command selene -Arguments @('src', 'tests')
    New-Item -ItemType Directory -Force -Path $buildDirectory | Out-Null
    Invoke-CheckedNative -Command rojo -Arguments @('build', 'default.project.json', '--output', $buildPath)

    [xml]$placeXml = [System.IO.File]::ReadAllText($buildPath)
    $project = Get-Content -LiteralPath default.project.json -Raw | ConvertFrom-Json
    ./scripts/Assert-ProjectStructure.ps1 -PlaceXml $placeXml -Project $project -RepositoryRoot $repositoryRoot
    ./scripts/Test-ProjectStructure.ps1

    Invoke-CheckedNative -Command rojo -Arguments @('sourcemap', 'default.project.json', '--output', $sourcemapPath)
    # Standalone 1.70.1 needs supplied Roblox definitions and the new solver for read-only types.
    # Keep DataModel strictness off; the regression probes verify API and Rojo module typing anyway.
    $analysisArguments = @('analyze', '--platform', 'roblox', '--definitions', '@roblox=types/roblox.d.luau',
        '--sourcemap', 'build/sourcemap.json', '--flag:LuauSolverV2=true', '--no-strict-dm-types')
    Invoke-CheckedNative -Command luau-lsp -Arguments ($analysisArguments + @('src', 'tests'))
    ./scripts/Test-LuauAnalysis.ps1 -AnalysisArguments $analysisArguments

    if (-not (Test-Path -LiteralPath 'place/tycoon.rbxlx')) {
        Write-Output 'Studio snapshot/restoration gate PENDING: place/tycoon.rbxlx has not been saved from Studio.'
    } else {
        Invoke-CheckedNative -Command git -Arguments @('ls-files', '--error-unmatch', '--', 'place/tycoon.rbxlx')
        ./scripts/Assert-AuthoredMap.ps1
        ./scripts/Test-AuthoredMap.ps1
        # Two small pinned Rojo builds verify that review fixtures never enter the
        # gameplay-only handoff, while the default keeps its QA coverage intact.
        ./scripts/Test-UiReviewPlace.ps1
        # Experimental modules are dormant in normal builds; verify each opt-in
        # preview's exact-source and QA boundary separately.
        $experiments = Join-Path $repositoryRoot 'src/server/Experiments'
        if (Test-Path -LiteralPath $experiments -PathType Container) {
            foreach ($experiment in Get-ChildItem -LiteralPath $experiments -Directory) {
                ./scripts/Test-ExperimentPlace.ps1 -Name $experiment.Name
            }
        }
        Write-Output 'Canonical snapshot is tracked; Studio save/reopen/restore still requires observed evidence.'
    }
    Write-Output 'CLI checks passed: formatting, lint, fresh build/sourcemap, Luau type analysis and failure probes, source ownership, serialized structure, and Git ignore rules. Studio integration/runtime gates are separate.'
} finally {
    Pop-Location
}
