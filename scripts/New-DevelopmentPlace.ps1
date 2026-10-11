# A fresh, verified scene for the owner's first Studio publish; no network calls.
# Requires PowerShell 7 (also supplied by windows-latest).
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'deployment/GameplayArtifact.psm1') -Force
New-DevelopmentPlace
