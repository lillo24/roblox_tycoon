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
    foreach ($ignoredPath in @('build/validation.rbxlx', 'place/scratch.rbxlx',
        'place/tycoon.rbxlx.lock', 'place/AutoSaves/tycoon.rbxlx')) {
        Invoke-CheckedNative -Command git -Arguments @('check-ignore', '--no-index', '-q', '--', $ignoredPath)
    }
    & git check-ignore --no-index -q -- place/tycoon.rbxlx
    if ($LASTEXITCODE -ne 1) {
        throw "Canonical place/tycoon.rbxlx must be trackable; git check-ignore returned $LASTEXITCODE (expected 1)."
    }

    # Refuse linked output locations instead of potentially overwriting source.
    foreach ($outputPath in @($buildDirectory, $buildPath)) {
        if (Test-Path -LiteralPath $outputPath) {
            $outputItem = Get-Item -LiteralPath $outputPath -Force
            if (($outputItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0 -or $outputItem.LinkType) {
                throw "Validation output must not be a symbolic link, junction, or hard link: $outputPath"
            }
        }
    }

    Invoke-CheckedNative -Command stylua -Arguments @('--check', 'src')
    Invoke-CheckedNative -Command selene -Arguments @('src')
    New-Item -ItemType Directory -Force -Path $buildDirectory | Out-Null
    Invoke-CheckedNative -Command rojo -Arguments @('build', 'default.project.json', '--output', $buildPath)

    [xml]$placeXml = [System.IO.File]::ReadAllText($buildPath)
    $project = Get-Content -LiteralPath default.project.json -Raw | ConvertFrom-Json
    ./scripts/Assert-ProjectStructure.ps1 -PlaceXml $placeXml -Project $project -RepositoryRoot $repositoryRoot
    ./scripts/Test-ProjectStructure.ps1
    if (-not (Test-Path -LiteralPath 'place/tycoon.rbxlx')) {
        Write-Output 'Studio snapshot/restoration gate PENDING: place/tycoon.rbxlx has not been saved from Studio.'
    } else {
        Invoke-CheckedNative -Command git -Arguments @('ls-files', '--error-unmatch', '--', 'place/tycoon.rbxlx')
        Write-Output 'Canonical snapshot is tracked; Studio save/reopen/restore still requires observed evidence.'
    }
    Write-Output 'CLI checks passed: formatting, lint, fresh build, source ownership, serialized structure, and Git ignore rules. Studio gates are separate.'
} finally {
    Pop-Location
}
