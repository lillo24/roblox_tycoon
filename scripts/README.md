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
  fixed `build/validation.rbxlx` path, structure assertions/regressions, a fresh
  Rojo sourcemap, standalone Luau analysis, type failure probes, and Git
  tracking/ignore checks.
  Native exit codes are checked explicitly, including exit 1 for a non-ignored
  canonical snapshot. Linked build directories/files are rejected before writing.
- `Assert-ProjectStructure.ps1` checks the project's ownership boundary and the
  generated XML's unique folder/script paths, classes, and exact source contents
  (normalizing only CRLF versus LF). It checks files, not a live Studio hierarchy.
- `Test-ProjectStructure.ps1` mutates copies of a fresh build and config in memory
  to ensure missing/duplicate/wrong-class instances, stale code, and broadened
  ownership or server binding are rejected. It never changes mapped Luau or a scene.
- `Assert-AuthoredMap.ps1` checks the canonical scene's six inward frames, dimensions,
  SAT separation, anchored geometry, single spawn, script ownership and no saved
  runtime/old terrain. `Test-AuthoredMap.ps1` runs seven malformed-scene probes on
  in-memory copies. Both run in full validation. For an authoring checkpoint,
  `./scripts/Assert-AuthoredMap.ps1 -CheckSnapshotCode` additionally verifies the
  captured script classes/counts and current source (CRLF/LF normalized). That
  option is not a permanent code-only save requirement: Git/Rojo remains the code
  authority, and later code-only work may leave captured scene scripts older.
- `Test-LuauAnalysis.ps1` receives the exact analyzer options from the full entry
  point. It uses one generated file below `build/` for a passing Roblox/Rojo
  control and five expected TypeErrors: ordinary scalar mismatch, Roblox
  property type, nullable Roblox return, resolved module value type, and frozen
  catalogue definition assigned to a writable record. It checks exit 1 and the expected diagnostic,
  so missing definitions cannot create a false pass. Cleanup runs in `finally`;
  source/test file hashes and the file set must remain unchanged.

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

The standalone Session, SupplyEvent and SupplyFeedback tests run in Studio against
the actual production modules, with supplied event/feedback times. The client
feedback helper is Instance-free and can run through the same server test route;
fixtures remain outside production Rojo mappings. CLI/CI formats, lints, and
type-checks them but does not execute Luau. See
[`src/README.md`](../src/README.md) for execution and runtime QA procedures.

## Standalone type analysis

The full entry point runs these commands from the checkout root:

```powershell
rojo sourcemap default.project.json --output build/sourcemap.json
luau-lsp analyze --platform roblox --definitions '@roblox=types/roblox.d.luau' --sourcemap build/sourcemap.json --flag:LuauSolverV2=true --no-strict-dm-types src tests
```

The sourcemap is regenerated on every validation, without `--watch`. It describes
only the code-owned Rojo tree. The unmapped `tests/` folder is still included in
analysis. No generated place XML, authored scene, caches, or vendored declaration
files are analyzed as source. Keep the default diagnostic formatter: this pinned
tool's `--formatter plain` unconditionally returns zero and is unsuitable as a gate.

The new solver flag is necessary for the existing `read` property annotations and
for frozen-table checking; the pinned binary defaults to the old solver. The
supported `--no-strict-dm-types` keeps DataModel strictness off. Both modes passed
the current code and caught the nullable-return/readonly probes; stricter mode
did not improve the known LocalPlayer/Terrain discrepancy. We retain API/module
checking while avoiding extra assumptions about Studio-only or runtime-created
hierarchy absent from the code-only map. No source exclusions, `any` casts, strict
pragmas removed, or diagnostic categories disabled were needed.

Standalone `--platform roblox` does not supply API declarations. The release-pinned,
versioned definitions and license in `types/` are required; validation makes no
definition download. The analyzer's one-shot client reports that watched-file
registration is unavailable; that log is expected because this command has no
watcher and consumes the freshly generated map. Source diagnostic failures still
exit nonzero and stop validation.

Historical coverage is precise: `GetPlayerByUserId()` returning `Player?` cannot be
assigned to `Player`, and a Rojo-imported frozen catalogue definition cannot satisfy
a writable `Cost` record. The positive/module probes use the real
`UpgradeCatalogue.ById.income_booster.Cost` API, replacing the removed Config price.
This definition snapshot declares `LocalPlayer` and `Terrain` non-optional,
so those exact Studio diagnostics are not replicated. Preserve their runtime
assertions and use Studio analysis when full-place context or a discrepancy matters.

On macOS/Linux, these checks need PowerShell (`pwsh -File
./scripts/Validate-Project.ps1`). Alternatively, use the manual full GitHub
Actions run described in the root README; it supplies PowerShell on the runner.
