# Repository validation

This folder owns the PowerShell validation used locally and by CI.
It does not contain gameplay code or require additional packages.

- `Get-ValidationScope.ps1` returns whether the complete CLI suite is required:
  manual runs always require it, while PRs skip it only when every changed file is
  Markdown. The workflow supplies paths from the PR merge commit's diff against
  its first parent (the base branch), including deleted paths. `--no-renames`
  includes both old and new paths so renaming source to Markdown still validates.
- `Test-ValidationScope.ps1` exercises that policy for documentation, source,
  deleted source, root configuration, workflow/tooling, unknown file types,
  mixed changes, and manual checkpoints. A mismatch throws and fails validation.
- `Validate-Project.ps1` is the full validation entry point. It runs scope tests,
  formatting/lint of `src` and the unmapped `tests` folder, a fresh build at the
  fixed `build/validation.rbxlx` path, Git
  tracking/ignore checks, structure assertions, and their regression probes.
  Native exit codes are checked explicitly, including exit 1 for a non-ignored
  canonical snapshot. Linked build directories/files are rejected before writing.
- `Assert-ProjectStructure.ps1` checks the project's ownership boundary and the
  generated XML's unique folder/script paths, classes, and exact source contents
  (normalizing only CRLF versus LF). It checks files, not a live Studio hierarchy.
- `Test-ProjectStructure.ps1` mutates copies of a fresh build and config in memory
  to ensure missing/duplicate/wrong-class instances, stale code, and broadened
  ownership or server binding are rejected. It never changes mapped Luau or a scene.

The workflow runs these policy tests on every PR and manual run before deciding
whether to install tools. Run them locally from the repository root with:

```powershell
./scripts/Test-ValidationScope.ps1
```

For the complete suite, with the installed pinned tools available on PATH:

```powershell
./scripts/Validate-Project.ps1
```

The helper can also be invoked by absolute path from another directory; it selects
its own checkout root. A passing CLI check reports a missing authored snapshot as
**pending**, rather than manufacturing one or claiming a Studio pass. A present
snapshot must be tracked. Save/reopen/restore and runtime gates remain separately
required by `place/README.md`.

The standalone gameplay session tests run in Studio against the actual server
module; CLI/CI formats and lints them but does not execute Luau. See
[`src/README.md`](../src/README.md) for execution and runtime QA procedures.

On macOS/Linux, these checks need PowerShell (`pwsh -File
./scripts/Validate-Project.ps1`). Alternatively, use the manual full GitHub
Actions run described in the root README; it supplies PowerShell on the runner.
