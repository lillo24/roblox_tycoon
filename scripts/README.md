# Repository validation

This folder owns the PowerShell validation used locally and by CI, preview
generators and optional offline performance readers. It contains no gameplay code.

- `New-PerformanceReviewPlace.ps1 -Workload Fresh|Developed|Dense|SixOwners`
  injects bounded, unmapped probes into a local-memory Infinite copy. See
  `tests/fixtures/Performance/README.md` and `docs/PERF_01_REVIEW.md` for the route,
  timings and distinctions between six rendered properties and six actual owners.
  `Export-PerformanceEvidence.ps1 -LogPaths <Studio log paths> -Name <run-name>`
  extracts account-safe JSON and nearest-rank summaries under `docs/perf-01`.
  It rejects truncated records. `Test-PerformanceReviewPlace.ps1` verifies exact
  fixture sources/startup, unchanged authored geometry and exclusion from production.
  Full CLI/CI adds two small Rojo builds for this boundary check; it does not run
  clients or claim runtime performance from generated geometry.
  PERF-02 buffers probe records until Idle; see the fixture README for capacity,
  timestamps and the separate sampler check. `Observe-PerformanceHost.ps1
  -Name <run> -Seconds 360 -Interval 5` records bounded read-only WMI CPU/core,
  3D-engine, paging/memory and Studio-process counters in `build/perf-host-<run>.jsonl`.
  It writes only after observation and retains collection/collector CPU overhead.
  The raw counters need differences over their own timestamp intervals; five-second
  averages cannot prove or exclude a short saturated core or OS scheduling delay.
  GPU engines are per process/adapter/engine, not additive across unrelated engines.
  No app setting, process priority or affinity is changed.
  Studio must be running; a missing process is an explicit collector failure.
  `Summarize-PerformanceHost.mjs <probe.jsonl> <host.jsonl> <summary.json>` derives
  raw rates for one completed window, excluding mixed phase intervals. Studio CPU
  is used cores; GPU engines remain separate. `Read-PerformanceDump.mjs
  <legacy.html> <summary.json>` reads complete frame/event spans from trusted local
  Studio 742 Legacy HTML (R0FL), using its embedded vendor decoder offline. It
  rejects unsupported/truncated captures; do not use it on arbitrary HTML. Its
  inclusive elapsed scopes are not exclusive CPU accounting. These two optional
  readers were exercised with Node 24.19.0, use only built-ins, and add no runtime
  or CI dependency. Reproduction/capture limits: `docs/PERF_02_REVIEW.md`.

- `New-UiReviewPlace.ps1` creates an ignored disposable UI review copy under
  `build/`, combining the unchanged canonical scene with current mapped source.
  Play runs exact SupplyFeedback, UiState and WorldLabels tests via temporary
  unmapped QA instances. It rejects linked outputs and verifies the canonical
  hash. Run from the checkout whose scene/runtime you intend to review; default
  output is `ui-review-main.rbxlx`, or use `-OutputName ui-review-map.rbxlx` in an
  isolated map compatibility checkout. This helper never saves a canonical scene.
  Disposable output omits the XML declaration because Studio's place reader
  rejects that header even when the authored input is valid general-purpose XML.
  Opt-in HUD tests use `UI01ClientQA/RunClientAssertions`, cloned into the Play
  client's PlayerScripts. Direct command-bar module requires have a separate
  module cache. Keep the runner until Stop Play so its recreated HUD connections
  remain alive; see `docs/UI_01_REVIEW.md` for the exact route.
  `UI01ClientQA/RunDisplayFixture` is an opt-in LocalScript for labelled synthetic
  large balances, long names and independent messages in the actual HudView.
  It checks safe-area Close, short-view panel separation and native jump clearance;
  it never writes economy attributes. Stop Play removes all QA instances.
  UX-02 also runs `PlayerGuidance.spec` automatically in Play and adds
  `HudReadiness.spec` to the opt-in client runner (about 11 seconds for the real
  timeout). Generate the combined checkout with
  `./scripts/New-UiReviewPlace.ps1 -OutputName ui-review-ux-02.rbxlx`.
  See `docs/UX_02_REVIEW.md` for current provenance and consolidated QA.
  QA-01 additionally includes Session/SupplyEvent in the automatic server route.
  Before Play, run `require(game.ServerScriptService.UI01QA.RunMapAssertions)()`
  in Edit for the actual MapLayout suite; its guard rejects Play because the test
  creates/removes runtime geometry. `-GameplayOnly` omits all QA folders/remotes,
  assertion runners and synthetic fixtures while retaining identical mapped
  production source and Workspace. The default still includes the QA routes:

  ```powershell
  ./scripts/New-UiReviewPlace.ps1 -OutputName ui-review-qa-01.rbxlx
  ./scripts/New-UiReviewPlace.ps1 -OutputName ui-review-founder.rbxlx -GameplayOnly
  ```

  `Test-UiReviewPlace.ps1` builds both variants and checks exact mapped source,
  unchanged Workspace/scene hash, fixture inclusion/exclusion and exact test source.
  Full validation runs this check when the authored scene exists; the two additional
  pinned Rojo builds verify the handoff boundary without starting Studio or a server.

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

## INF-01 previews

`New-InfiniteReviewPlace.ps1` builds fresh sources on the unchanged canonical map.
Default `-Backend LocalPreview` explicitly injects temporary memory storage, labeled
in the HUD; it is never a production fallback. `-Backend DataStore` retains the normal
bootstrap and requires the isolated universe setup in `src/server/Persistence/README.md`.
`-IncludeQA` adds domain/lifecycle runners plus an opt-in actual-client observer outside
production mappings. Output is restricted to `build/inf-*.rbxlx` and linked output is refused.

`Test-InfiniteReviewPlace.ps1` checks the three local/QA/real-backend boundaries,
every nested source/class, and the unchanged authored map. The standard validation
runs these small Rojo builds because startup injection is a persistence safety boundary.
It does not execute the Luau suites or claim a real DataStore write.

INF-03: `New-InfiniteReviewPlace.ps1 -Showcase` is restricted to LocalPreview. It injects two clearly labelled, rich development profiles through the same profile load path, reserving two of six lots. Human clients still start fresh with 0 cash and ordinary earnings. The optional fixtures live outside mapped roots and never enter a real-backend build. IncludeQA also injects Growth and its own separately named presets module, without enabling showcase residents. Test-InfiniteReviewPlace checks all four variants and the fixture boundary.

MODE-01: `New-ModeReviewPlace.ps1 -Role Entry|Prototype|Infinite` creates `mode-entry`, `mode-session` or `mode-infinite` in build. `-Scenario LateFailure|ImmediateFailure|MissingDestination` selects an explicit unmapped Studio adapter; fake IDs never enter a real teleport. `-IncludeQA` adds routing/handoff/domain assertions and actual-client role observations; `-Showcase` only applies to Infinite. Production source remains exact, with copied bootstrap disabled in favour of AppRuntime plus explicit fixture injection. `Test-ModeReviewPlace` adds three small builds to the existing complete validator to check this startup isolation boundary; CI trigger policy is unchanged. Real-service setup and combined review: docs/MODE_01_REVIEW.md.

PERF-03: `New-PerformanceReviewPlace.ps1 -Workload SixOwners -CaptureDiagnostics -OutputName mode-perf-sixowners-capture.rbxlx` adds an opt-in, one-shot hitch signal and labelled calibration stall to a disposable Studio-only performance place. Ordinary timing and gameplay-only builds exclude this script; the boundary is checked by `Test-PerformanceReviewPlace.ps1`. The native pause/export procedure and its unverified Studio gate are in `tests/fixtures/Performance/README.md` and `docs/PERF_03_REVIEW.md`.
For diagnostic runs, `Observe-PerformanceHost.ps1 -Name hitch -Seconds 350 -IncludeProcesses` adds process identity and CPU counters to its otherwise unchanged read-only collector; the offline summary shows leading consumers per contained interval. Its presence and overhead must be recorded. Inspect process names before sharing raw data.
