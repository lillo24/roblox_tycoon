# PERF-03 — triggered hitch capture, preparatory implementation

Tested predecessor: draft PERF-02 PR #27,
`ab7ba14350cb12258a69f3a021b2e8853a295d46`. This branch inherits the
draft gameplay stack. `src/`, the authored scene and production configurations
are unchanged. This report covers the diagnostic fixture only; it is not a
six-client performance result.

PERF-02's clean repeat still missed the >50 ms share at 13/10,750 frames
(0.1209%), maximum 192.175 ms. Its three native MicroProfiler dumps did not
contain a slow interval. A 97.1% host CPU interval overlapped a later cluster,
but neither the 192 ms frame nor that cluster has a proven game or host cause.

## Prepared path

The generator accepts `-CaptureDiagnostics` only for a disposable performance
place. It injects a separate client LocalScript, leaving ordinary samples and
the production/client modules unchanged. After a real viewport click to arm,
one observed foreground Churn/Quiet interval over 50 ms displays a red pause
cue and writes a single bounded `PERF03_SIGNAL` with phase, frame ordinal,
interval, client clock and server time. A fixed MicroProfiler marker labels the
**end** of that interval, not its cause. An Idle-only button can produce a
labelled 100 ms fixture stall to check capture/reaction timing before natural
six-client attempts. Signals are opt-in diagnostic overhead, never budget runs.
Focus loss and completion disarm the observer. Inactive Studio clients' stale
WindowFocused flags are not used to select it.

`Test-PerformanceReviewPlace.ps1` now checks that the extra client is present
only in the opt-in generated place and absent from ordinary timed and production
builds. See [fixture instructions](../tests/fixtures/Performance/README.md).
An opt-in `-IncludeProcesses` host collector mode records process CPU deltas and
available start identities. Its offline summary retains the leading consumers
for each interval, labelling uncertain identities. This has not been run on the
Studio host; five-second host samples alone cannot assign a frame's cause.

Local checks: the host summary reader parsed the unchanged PERF-02 clean-2
archive (58 contained intervals), then paired synthetic process counters while
marking unknown starts uncertain and fencing a reused PID with a different
start time. `node --check` and `git diff --check` passed. These checks are not a
native hitch capture or a Windows PowerShell validation run. Required project
validation is delegated to this draft PR's Windows CI.

## Required native gate

This checkout runs on Linux without Roblox Studio or PowerShell. The artificial
stall, native viewport click, Ctrl+P, profiler export and six-client natural
capture have **not** been executed here. No native timeline containing a hitch,
matched host attribution, gameplay optimization or new frame-budget pass is
claimed. Run `./scripts/New-PerformanceReviewPlace.ps1 -Workload SixOwners
-CaptureDiagnostics -OutputName mode-perf-sixowners-capture.rbxlx` on the Studio
host; use the fixture README to verify calibration first. If the stall does not
appear with preceding/following frames in the native dump, stop and diagnose
the capture path rather than running repeated churn. If it works, capture a
natural event and compare the indicated cause under matched conditions before
any game change. The original PERF-02 misses remain open until then.

The probe-free Infinite gameplay preview can be regenerated independently:

```powershell
./scripts/New-ModeReviewPlace.ps1 -Role Infinite -Showcase -OutputName mode-infinite-perf-03-review.rbxlx
```

That command has not been run in this environment; it does not publish the game
or substitute for a Studio preview observation. Physical-device and real-service
QA, along with the founder's style/pacing review, remain separate.
