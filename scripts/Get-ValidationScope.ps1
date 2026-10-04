param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('pull_request', 'workflow_dispatch')]
    [string]$EventName,

    [string[]]$ChangedFiles = @()
)

# Manual checkpoints always validate everything, including Markdown-only changes.
if ($EventName -eq 'workflow_dispatch') {
    return $true
}

# Markdown is the only known documentation-only format. Treat new file types
# conservatively so source, root configuration, and tooling always get checked.
return @($ChangedFiles | Where-Object { $_ -notlike '*.md' }).Count -gt 0
