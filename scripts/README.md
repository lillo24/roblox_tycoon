# CI validation scope

This folder owns the small PowerShell policy used by the validation workflow.
It does not contain gameplay code or require additional packages.

- `Get-ValidationScope.ps1` returns whether the complete CLI suite is required:
  manual runs always require it, while PRs skip it only when every changed file is
  Markdown. The workflow supplies paths from the PR merge commit's diff against
  its first parent (the base branch), including deleted paths. `--no-renames`
  includes both old and new paths so renaming source to Markdown still validates.
- `Test-ValidationScope.ps1` exercises that policy for documentation, source,
  deleted source, root configuration, workflow/tooling, unknown file types,
  mixed changes, and manual checkpoints. A mismatch throws and fails validation.

The workflow runs these policy tests on every PR and manual run before deciding
whether to install tools. Run them locally from the repository root with:

```powershell
./scripts/Test-ValidationScope.ps1
```

On macOS/Linux, these policy tests need PowerShell (`pwsh -File
./scripts/Test-ValidationScope.ps1`). Alternatively, use the manual full GitHub
Actions run described in the root README; it supplies PowerShell on the runner.
