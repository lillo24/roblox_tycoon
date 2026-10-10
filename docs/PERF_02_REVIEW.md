# PERF-02 — six-client hitch diagnosis

Two clean six-owner repeats establish variability, **not a fixed hitch**. Run 1
meets the frame references; run 2 misses the >50 ms rate at **0.1209%**, with a
**192.175 ms** maximum. All three exported native timelines contain ordinary
frames only. The earlier **314.415 ms** PERF-01 hitch and the cause of the new
192.175 ms interval remain unresolved. No production optimization is justified
by these captures. This slice corrects fixture measurement and delivers evidence.

## Provenance and unchanged gameplay

- Tested predecessor: draft [PERF-01 #25](https://github.com/lillo24/roblox_tycoon/pull/25),
  `c096eb691667d7961a38cb5dadf0843724b36ea5`, inheriting #23 → #22 → #21 → #18.
- Brief pulled from main `d2c9823`; merge `ed72302` brings only that brief onto
  the predecessor. Timed fixture revision:
  **`fbf7b111277a35ed3585fb6a195d19d4946d2a67`**.
- [PERF-02 comparison against the tested predecessor](https://github.com/lillo24/roblox_tycoon/compare/c096eb691667d7961a38cb5dadf0843724b36ea5...codex/perf-02-six-client-hitches).
  `src/`, the authored scene, configuration and gameplay limits are identical.
  PERF-01's retained-geometry repair is preserved. Final additions are reports,
  evidence, offline readers and a fail-loud missing-Studio collector guard; they
  do not change the tested fixture or game.
- SixOwners build: `build/mode-perf-sixowners-buffered.rbxlx`, SHA256
  `50A1E0071E29D8631C4EF9507790152CF363B73DD92C2B1821FA24D51720A227`.
  Canonical map SHA256:
  `9D6A9FE65A25E0C1D8CF6FA4FE7D4E582EA234FF618DC758BC71FD4675C9F8E8`.
- Studio **0.742.0.7421053**, Windows 11 build 22000, Intel i5-4690 3.50 GHz,
  four cores/threads, 16,325 MB system memory, GTX 1660 SUPER,
  driver 32.0.16.1088. Native video-memory metadata is not used as physical VRAM.

All gameplay PRs remain draft for combined review. Experiments #14–#16 remain
separate. No publication, production service access or hosted setting changed.

## Measurement correction and architecture

`tests/fixtures/Performance/Sampler.luau` owns probe retention/export; Client owns
actual frame/event observations and ordinary owner edits; Server owns phase
control and synchronous wrappers. These existing unmapped boundaries are reused.
PERF-01 printed chunks during sampling. PERF-02 buffers records, retains original
timestamps and begins JSON encoding/printing **three seconds after Idle**. It
excludes Idle observations and resets each run. Limits are 40,000 samples per
metric and 6,000 records per side; exceeding either asserts and invalidates the
run rather than dropping slow frames. All exports below fit and count-check.

Fixed profiling labels identify fixture sampling and editor create/destroy.
`slowFrame` records preserve phase, frame ordinal, client clock, server time,
camera slot and last requested edit. `PERF02 slow interval end` marks the **end**
of a wall interval; it is not its CPU cause. No production source is instrumented.
About 4,500 background 15 Hz intervals per client exceed the 33.3 ms event
threshold, so deferred instrumentation consumes bounded additional memory. This
is a measurement correction with different overhead from PERF-01, not proof
that streamed logging caused its hitch or that gameplay became faster.

`Observe-PerformanceHost.ps1` retains timestamped raw WMI CPU/core, GPU 3D-engine,
memory/paging and Studio process observations every five seconds. It buffers
output until the end, records its own collection time/CPU, and changes no process
priority, affinity or app setting. Offline readers run only after sampling.

## Clean repeat conditions

Each repeat reopened the identical build, started a zero-client server, added
six actual clients, and reset disposable profiles. Native command-bar checks
found all six owners Ready, each with a valid Garden profile: **10 owned / 9
placed / 1 stored**, revision **20**, and **372 world / 90 animated BaseParts**.
Characters were put at their own lot arrival points before measurement. No
synthetic resident reserves a lot.

All six cameras reported **801 × 413**, iPhone XR landscape. The actual native
phone rendering area is about **604 × 279/280** inside a 1282 × 922 Studio window.
Graphics stayed **Automatic**. The configured FPS cap is unobserved; a roughly
60 Hz cadence is not proof of a selected cap. Diagnostic native metadata later
reported **21 (auto)**; that does not establish the internally chosen quality
throughout earlier clean windows. The emulator is not a physical-device test.

The existing route visits lots 1–6 at 20-second stops. Churn lasts 180 seconds:
ordinary store/re-place/half-turn/restore, palette changes, five initial lantern
purchases and editor create/destroy cycles; quiet lasts 120 seconds. All six
owners run the same schedule. No screenshot, log read/export, build, test,
window switch or detailed profiler interaction occurred inside either clean
window. The lightweight host collector is the explicit exception, with overhead
reported below. Profiler work used separate diagnostic windows.

| Repeat | Six clients launched (UTC) | All Ready / scene verified | Actual foreground, native input before start | Churn / Quiet / Complete, server UTC seconds |
| --- | --- | --- | --- | --- |
| clean-1 | 08:03:03–08:03:08 | 08:05:31 | owner1; focus setup complete 08:08:05.730 | 1791619690.075 / 1791619870.082 / 1791619990.095 |
| clean-2 | 08:22:53–08:22:59 | 08:24:24.897 | owner2; focus setup complete 08:25:37.712 | 1791620750.643 / 1791620930.651 / 1791621050.665 |

Starts were 08:08:10.075 and 08:25:50.643 UTC on 2026-10-10. Warm-up from client
launch differs: about five minutes versus three. Actual observers were selected
through native viewport input and checked by command bar. Studio left all six
WindowFocused flags true; raw flags are retained, **not used to pool foreground
clients**. The other five clients ran about 15 Hz in both repeats. PERF-01's raw
inactive clients also ran about 15 Hz, so no new background-throttling change is
established here.

## Clean results and budgets

Nearest-rank distributions, milliseconds. Only the verified observer is used
for the foreground frame verdict. Every raw series remains in the archive.

| Run / phase | Frames | p50 | p95 | p99 | Max | >50 ms count / rate | Verdict |
| --- | ---: | ---: | ---: | ---: | ---: | --- | --- |
| clean-1 churn, owner1 | 10,800 | 16.712 | 19.089 | 22.204 | 36.892 | 0 / 0% | Pass |
| clean-1 quiet, owner1 | 7,202 | 16.741 | 18.708 | 21.275 | 33.122 | 0 / 0% | Pass |
| clean-2 churn, owner2 | 10,750 | 16.686 | 19.851 | 23.206 | 192.175 | 13 / **0.1209%** | **Spike-rate miss** |
| clean-2 quiet, owner2 | 7,201 | 16.686 | 18.599 | 19.332 | 20.743 | 0 / 0% | Pass |

References remain p95 ≤20 ms, p99 ≤33.3 ms, >50 ms rate **below 0.1%**.
Both churn p95/p99 values pass, but run 2's spike-rate failure prevents a general
six-client pass. PERF-01's 21.518 ms p95 / 18 of 10,713 >50 ms / 314.415 ms max
remain historical failures; changed instrumentation and warm-up prevent a
matched before/after gameplay speedup claim. The exact 314 ms value did not recur
in clean repeats. Diagnostic multi-second export stalls are a different condition.

| Churn work | clean-1 count; p50 / p95 / p99 / max | clean-2 count; p50 / p95 / p99 / max | Budget |
| --- | --- | --- | --- |
| Observer ordinary edit RTT | 241; 33.459 / 36.167 / 48.961 / 50.522 | 240; 33.789 / 38.983 / 55.153 / 86.487 | p95 ≤150: Pass both |
| Synchronous snapshot | 6,084; .065 / .192 / .514 / 4.365 | 6,075; .065 / .193 / .393 / 2.410 | p95 ≤2: Pass both |
| Synchronous world reconciliation | 2,595; .346 / 1.386 / 2.451 / 5.752 | 2,592; .356 / 1.439 / 2.346 / 3.658 | p95 ≤2: Pass both |
| Accepted transaction work | 1,443; .086 / .239 / .560 / 2.133 | 1,440; .089 / .296 / .611 / 2.308 | Context; no separate budget |

All six clients' RTT p95 values are below 150 ms (largest 54.090 and 52.251 ms).
Quiet snapshot/reconcile p95 are .265/.005 ms and .134/.004 ms. Low per-call
p95 does not exclude short bursts, client work or replication cost.

| Load, owner order 1–6 | clean-1 | clean-2 |
| --- | --- | --- |
| Requested = accepted edits | 241, 243, 241, 242, 236, 240 (**1,443**) | 240 each (**1,440**) |
| Rejected edits | 0 | 0 |
| Editor cycles | 48, 48, 48, 48, 47, 47 | 48, 47, 48, 47, 47, 48 |
| Churn world parts min / max / mean | 351 / 372 / 367.722 | 344 / 372 / 369.472 |
| Churn animated parts min / max / mean | 81 / 90 / 88.167 | 78 / 90 / 88.917 |
| Quiet world / animated parts | **351 / 81** | **372 / 90** |

The schedule can stop between a store and re-place. Run 1 quiet therefore has a
smaller scene; it is not an exact quiet-scene match to run 2. Its totals are 6,318
added / 5,967 removed, versus run 2's 6,318 / 5,946. Quiet geometry counts plateau.
Both runs preserve 180 churn and 120 quiet income ticks, approximately one second
apart. No ordinary-edit rejection, assertion, timeout or capacity overflow was
observed. This is local memory checkpoint work, not DataStore latency.

## Host pressure: supported correlation, unproven cause

There are 70 raw host samples per clean repeat; summaries use 35 wholly contained
churn intervals and 23 wholly contained quiet intervals. Cross-phase intervals
are excluded from phase summaries and retained raw. CPU is the inverse raw idle
delta over its own 100 ns timestamp; each GPU engine is busy delta over its own
timestamp, **not a sum of unrelated engines**. Paging uses the performance counter
clock/frequency. Process CPU seconds divided by UTC interval gives used cores.

| Host metric | clean-1 churn / quiet | clean-2 churn / quiet |
| --- | --- | --- |
| Total CPU mean; max (%) | 60.36; 66.48 / 61.83; 89.16 | 66.99; **97.11** / 58.61; 75.81 |
| Highest core utilization max (%) | 69.14 / 92.26 | **98.12** / 82.60 |
| Studio CPU mean used cores | 1.960 / 1.870 | 2.006 / 1.794 |
| Available RAM min–max MB | 4141–4378 / 3899–4988 | **607–5696** / 5312–5883 |
| Highest individual GPU 3D engine max (%) | 9.43 / 8.39 | 10.26 / 10.89 |
| Collector mean CPU used cores | .0128 / .0081 | .0126 / .0076 |
| Collection duration mean; max ms | 148; 1618 / 101; 124 | 119; 180 / 102; 194 |

Run 2's eight-interval cluster at server times **1791620835.810–1791620837.206**
includes 54–99 ms frames. The overlapping host interval
**1791620836.291–1791620841.307** reports **97.108% total CPU**, all four cores
**95.936–98.124%**, Studio **2.053 used cores** (~51.3% of this host), 1749 MB
available RAM and 289.31 pages input/sec. Collector CPU was .0031 core and
collection time 149.9 ms. Prior interval CPU was 71.61%, with 989 MB available.
This supports host-wide contention as a candidate. It does **not** identify the
other CPU consumer or prove an OS scheduling delay caused any individual frame.
All-process CPU/scheduler traces and a native timeline of that hitch are absent.
Five-second intervals cannot assign a millisecond cause; collection is sequential
and its UTC timestamp follows the counter queries.

The maximum 192.175 ms frame is near startup (frame 18, clock 167.5766502,
server time 1791620751.162), with lastAction `none`, before the observer's first
ordinary edit. The clean-2 archive retains all 13 slow intervals and their events.
This rules out a first foreground edit as a prerequisite for that particular
interval, not all game/startup work. Render/scheduler/GC explanations remain open.
GPU counters do not prove GPU saturation; sparse utilization cannot exclude a
short GPU wait. Studio memory drops during run 2 while free host memory recovers;
these counters include editor/runtime overhead and do not establish a game leak.
Run 1 quiet has a 5,244 pages/sec interval without a >50 ms foreground frame,
so paging correlation alone is insufficient. CIM initialization (1.6/2.2 seconds)
occurred before timing; the occasional 1.6-second collection during run 1 remains
an instrumentation limitation, not silently excluded.

## Native captures and controlled phase comparison

Separate diagnostics used the same production/fixture build with six owners,
actual observer **owner3**. Native Ctrl+F6 enabled MicroProfiler, Ctrl+P froze its
recent buffer, then Dump → 512 frames → Legacy HTML exported a self-contained
native timeline. Three exports each contain **506 complete frames**, about 8.43
seconds. The dump's UTC/quality/display metadata describes export time; it must
not be substituted for the earlier pause time or captured viewport.

| Capture / diagnostic | Native pause verified UTC | Phase and approximate captured interval | Native frame maximum; local index/start/end ms | >50 ms |
| --- | --- | --- | --- | ---: |
| `microprofile-20261010-104634.html`, diag-1 | 08:44:56.930 | churn, roughly 21–29 s after start | 21.030; 503 / 8383.152 / 8404.183 | 0 |
| `microprofile-20261010-105656.html`, diag-2 | 08:56:40.739 | churn, roughly 94–103 s after start | 22.553; 130 / 2168.422 / 2190.976 | 0 |
| `microprofile-20261010-105856.html`, diag-2 | 08:58:48.836 | quiet, roughly 42–51 s after transition | 19.150; 435 / 7249.038 / 7268.188 | 0 |

Local native indexes start at zero, not the probe's run ordinal. Pause times are
UI completion observations with input/capture latency; exact native-frame ↔ probe
ordinal alignment is **unobserved**. Probe clock/server time/frame stats and fixed
PERF02 labels provide phase/run context, not a fabricated exact hitch match.
All captures lack even a >33.3 ms native frame. **None captures or explains the
192 ms or historical 314 ms hitch.** The 60-frame aggregate timer statistics can
include paused/export time; the offline reader instead derives spans from the
actual captured frames and complete timeline events.

Diag-1 reset profiles and reached 372/90. Five inactive clients started in the
desktop viewport; observer capture started at 801 × 413, then the observer was
changed to desktop **after freezing** for export. Its native export metadata says
1096 × 635; this is not the captured phone viewport. The default `.x.html` export
of that same frozen buffer was replaced by the retained compatible Legacy HTML,
not treated as another run. Subsequent viewport/menu/file interactions contaminate
diag-1's full timing distributions. Raw data remains in the diagnostic archive.

Diag-2 reused those processes and profiles, so it is **not a third clean repeat**.
Before starting, owner3 had **15 owned / 9 placed / 6 stored, revision 255**.
It returned to 801 × 413; five background desktop viewports remained. Profiler
was still paused through startup and resumed only at 08:56:04.100, missing startup
hitches. It resumed again at 08:57:47.866 before the quiet capture. These limits
are retained, not counted as clean six-client passes.

The smallest useful comparison is ordinary churn versus quiet within diag-2,
with the same observer, viewport, graphics and profiler. Both native traces show
normal render/present/sleep scopes. Two editor creates/destroys occur in the churn
capture: maximum labelled inclusive elapsed create **1.621 ms**, destroy **.745
ms**. The client sample label max is **.303 ms** churn and **.625 ms** quiet.
Captured `GC` scope maxima are **.277 ms** and **.055 ms**, respectively. These
are elapsed nested scopes, **not exclusive CPU or proof about uncaptured hitches**.
There are no editor labels in the quiet capture. The quiet scene is **358/84**;
churn sparse samples vary between stored/re-placed states (e.g. 365/87–372/90).
Thus phase removes edits/editor work but also freezes an intermediate scene;
the comparison is contextual, not perfectly scene matched or a causal fix.

Diag-1 completed 1,434 accepted edits; diag-2 completed 1,437, zero rejects in
both. Diag-2 has 4,150 ms churn and 3,202 ms quiet probe intervals ending at
08:57:01.095 and 08:58:59.844, during native HTML export work. They occur **after
the frozen capture buffers**. These are identifiable capture-interference
intervals, not clean-budget evidence or a trace of the original hitch. Other
diagnostic >50 ms intervals also remain raw; no individual cause is invented.

For completeness, these contaminated observer series are **diagnostic only**:

| Diagnostic / phase / raw focus flag | Frames | p50 / p95 / p99 / max ms | >50 ms |
| --- | ---: | --- | --- |
| diag-1 churn / true | 8,862 | 16.705 / 20.182 / 22.552 / 4230.087 | 2 (0.0226%) |
| diag-1 churn / false | 1,612 | 16.719 / 20.560 / 24.803 / 336.863 | 5 (0.3102%) |
| diag-1 quiet / false | 7,192 | 16.702 / 19.662 / 21.905 / 72.501 | 2 (0.0278%) |
| diag-2 churn / true | 10,552 | 16.745 / 20.365 / 23.810 / 4150.392 | 2 (0.0190%) |
| diag-2 quiet / true | 7,008 | 16.760 / 19.696 / 23.428 / 3201.713 | 3 (0.0428%) |

`MicroProfilerService:DumpToFileAsync(0,512)` was tried once at 08:49:49.226 and
explicitly rejected: current thread lacks **RobloxScript** capability. Native UI
export works, but automatic hitch-triggered export through the available command
bar does not. No bypass was attempted. Installed tools exposed no Studio capture
connector. The capability error is a diagnostic tooling check, not an ordinary
gameplay exception. Studio also logged periodic plugin OTA lock/HTTP warnings;
without a hitch trace, these are not assigned as its cause.

Two clean repeats and three native capture attempts have answered variability
and available-capture questions. More generic short captures would not identify
the missing cause. To resolve it, obtain a foreground native timeline containing
an actual >50 ms interval, with preceding/following frames and unambiguous probe
alignment; if that timeline points to contention/gaps, add scheduler/all-process
observations on the same run. Isolate the indicated path under matched conditions
before changing game code. New hardware or publication is not required for this
evidence/fixture delivery.

## Reproduction and evidence

From this checkout, pinned Rokit tools on PATH:

```powershell
./scripts/Validate-Project.ps1
./scripts/New-PerformanceReviewPlace.ps1 -Workload SixOwners -OutputName mode-perf-sixowners-buffered.rbxlx
./scripts/Observe-PerformanceHost.ps1 -Name clean-repeat -Seconds 350 -Interval 5
```

Open the performance place. Server & Clients → zero-client server → add six
with the count spinner (typing alone did not commit Studio's count). Verify every
owner Ready and Garden counts, settle, identify/focus the native observer, then
schedule `task.delay(20,function() game.ReplicatedStorage.PERF01.Control:FireServer("churn") end)`
from that client's command bar and refocus the viewport before start. Run the
collector before scheduling. Leave the window untouched until Complete + export.
Reopen/reset for the next comparable repeat. Do not enable detailed profiling
in clean budget runs.

```powershell
./scripts/Export-PerformanceEvidence.ps1 -LogPaths <seven-actual-log-paths> -Name clean-repeat -OutputDirectory build/perf-repeat
Expand-Archive docs/perf-02/samples.zip build/perf-02-samples
Expand-Archive docs/perf-02/native-captures.zip build/perf-02-native
node scripts/Summarize-PerformanceHost.mjs build/perf-02-samples/clean-2.jsonl build/perf-02-samples/host-clean-2.jsonl build/host-recomputed.json
node scripts/Read-PerformanceDump.mjs build/perf-02-native/microprofile-20261010-105656.html build/trace-recomputed.json
```

Node **24.19.0** was used only for offline readers; no dependency is added to
gameplay/validation. The native reader executes the embedded vendor decoder of
trusted local Studio 742 Legacy HTML, requires complete frames and rejects other
formats/truncated payloads. It is not a sandbox for arbitrary downloaded HTML.
Native HTML also opens directly offline for timeline inspection.

[`perf-02/archive-manifest.json`](perf-02/archive-manifest.json) records entry and
archive SHA256, sizes and raw row counts. `samples.zip` retains clean-1 (27,905
records), clean-2 (27,890), both diagnostic windows together (55,773), and both
70-sample host files. All 28 side/run export counts match retained records;
no overflow or truncated JSON. Diagnostic summaries are separated per run as
well as an explicitly pooled source export; the latter is not a budget verdict.
`native-captures.zip` retains all three original Legacy HTML timelines. ZIP CRC
and byte-for-byte verification passed. Summaries, paused screenshots and the
after-window screenshots are alongside the archives. Arbitrary Studio/account
logs are not committed. The diagnostic capability failure and native observations
are transcribed separately in `native-observations.txt`.

## Validation, cleanup and playable handoff

`Validate-Project.ps1` passed before measurement and again after the final helper
changes: formatting, zero lint diagnostics, fresh build/sourcemap, Luau analysis
and five deliberate failure probes, source/map/Git contracts and preview startup
boundaries. Node syntax checks and actual reconstruction of all three native
summaries and both host summaries passed. Malformed/native wrong-format and
incomplete-window reader checks fail explicitly. The final collector completed
a five-second smoke observation with Studio present; this is outside timed runs.

Native Edit-only `SamplerCheck.luau` passed at **08:00:27.127 UTC**: no output
during sampling, all 130 values retained as 64+64+2 chunks, original timestamps,
Idle exclusion and reset for the next run. Its sanitized output is retained.
This does not replace gameplay runtime QA; production is unchanged from #25.

All task six-client sessions were stopped normally, their fixture editors closed,
native profiler hidden and its temporary Legacy HTML option restored. Automatic
graphics and the phone preset are retained; no process priority/affinity/OS
setting was changed. No unrelated process was killed. A new **Test/Play** preview
uses the normal local-memory/failed-return adapter with two labelled examples
and four human lots, without QA runners or performance probes:

```powershell
./scripts/New-ModeReviewPlace.ps1 -Role Infinite -Showcase -OutputName mode-infinite-perf-02-review.rbxlx
```

Open `build/mode-infinite-perf-02-review.rbxlx` and Play. It is left running in
Studio. Native observation at **09:18:41.189 UTC** verified Ready and absence of
the PERF remote folder/control UI, viewport 801 × 413. See
[`gameplay-preview.png`](perf-02/gameplay-preview.png). Generated build SHA256:
`224AEFDDAC9F37A27AD44B1AFE9E31E9E0A0238869841F2ACC6F368385A8B729`.
Preview cash accrues normally; Stop resets memory. Do not publish this fixture.

Keep this PR **draft** for the founder's combined gameplay/style/pacing review.
Performance sign-off still needs the uncaptured hitch explained or a justified
matched fix with repeats. Physical-device comfort/performance and real-service
DataStore/teleport outcomes remain separate unobserved follow-ups. No historical
manual QA is relabelled passed here.

References: [Roblox MicroProfiler](https://create.roblox.com/docs/performance-optimization/microprofiler),
[using native captures](https://create.roblox.com/docs/performance-optimization/microprofiler/use-microprofiler),
[identifying performance problems](https://create.roblox.com/docs/performance-optimization/identify),
[Windows raw timer counter formulas](https://learn.microsoft.com/en-us/windows/win32/wmisdk/timer-algorithm-counter-types).

The [PERF-03 preparatory review](PERF_03_REVIEW.md) describes a separate opt-in
signal and calibration fixture for capturing an actual slow native interval.
No new Studio capture or performance sign-off is inferred from that code.
