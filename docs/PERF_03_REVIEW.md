# PERF-03 — bounded native hitch investigation

**Outcome: natural hitches captured and aligned; render/present waits located;
their cause remains unresolved. No gameplay repair or overall performance pass
is claimed.** One calibration and three five-minute diagnostic windows were
completed on Windows. The first natural trigger was missed by a late pause, but
the same frozen buffer retained later natural hitches. The investigation ends
within the brief's attempt limit; gameplay development and combined founder
review can continue independently.

## Revision and conditions

Continues existing **draft [PR #29](https://github.com/lillo24/roblox_tycoon/pull/29)**,
branch `codex/perf-03-triggered-hitch-capture`. Starting head was
`cd5cf947350f2da63909a3a939a05185597ec623`. Latest main's revised brief,
`64e963a`, was merged as `eff67e0fcac31ddd6b49cf41f095ebde6e163761` before
building and running. The capture fixture/runtime at that revision is the
measured implementation; subsequent changes only extend the offline reader,
its regression and this evidence. It inherits #27 → #25 → #23 → #22 → #21 → #18.
Production `src/`, project settings and authored geometry remain identical to
PERF-02/#27, including PERF-01's geometry-retention repair. Gameplay and
experiment PRs #14–#16 remain unmerged. Nothing was published.

Generated with:

```powershell
./scripts/New-PerformanceReviewPlace.ps1 -Workload SixOwners -CaptureDiagnostics -OutputName mode-perf-sixowners-capture.rbxlx
```

Capture-place SHA256:
`D98696705F6E0A991994CA0E32FE41343EA589C6EFA1FE68A165F790CE794BA7`.
Canonical-map SHA256:
`9D6A9FE65A25E0C1D8CF6FA4FE7D4E582EA234FF618DC758BC71FD4675C9F8E8`.

Host: Studio 742 / `0.742.0.7421053`, Windows 11 build 22000, i5-4690,
four logical cores, 16,325 MB RAM, GTX 1660 SUPER, driver `32.0.16.1088`, D3D11.1.
Each natural run started six actual Ready Garden owners with fresh disposable
profiles: revision 20, ten owned objects, nine placed and one stored per owner;
372 runtime BaseParts / 90 animated parts before churn. Characters were moved
to their own arrival positions. The unchanged camera visits six lots in
20-second steps. Churn offers ordinary owner edits and editor open/destroy for
180 seconds, then 120 seconds quiet. Local memory resets on Stop.

All observer probes reported viewport **801 × 413**, iPhone XR landscape
emulation and `SavedQualitySetting.Automatic`. Physical rendered area in the
exports is 604 × 279. Important distinction: the calibration export reports
renderer quality **21 (auto)**; the six-client natural export reports **5
(manual)** despite the saved-user-setting probe. Actual renderer quality was
not exported for attempts 1/2. No graphics setting was changed during these
runs. This is not a verified fixed-quality comparison with historical runs or
with calibration. FPS cap was not independently inspected. Six local clients
share this computer; these are not six players on separate devices.

## Calibration and capture reaction

The existing opt-in `Capture.client.luau` was exercised natively. The profiler
was recording before one Idle-only **100 ms artificial stall**, after a real
viewport click to arm. No artificial stall was used in the natural sessions.

| Calibration observation | Result |
|---|---|
| Signal log UTC | 2026-10-11 10:16:28.805 |
| Signal | Idle, frame 2432, 107.794 ms, clock 83.382189, server time 1791713788.561650, calibration=true |
| Pause key / confirmed paused UTC | 10:16:35.184 / 10:16:35.731 |
| Export | `microprofile-20261011-121711.html`, retained as `calibration.html` |
| Native buffer | 506 complete frames, 8,516.264 ms, one frame >50 ms |
| Known stall | `PERF03 deliberate calibration stall`, native frame 108, 100.012 ms |
| Following cue | `PERF03 slow interval observed`, frame 109, after the stall |

There are 108 preceding frames and 397 frames after the stall. Pause input came
6.379 seconds after the signal log, within this measured 8.516-second history.
The 107.794 ms PreRender delta and 103.195 ms native frame have different
boundaries; the known stall and following marker establish their relationship.
This validates capture tooling only. It is excluded from natural evidence and
all frame-budget verdicts. The roughly 8.5-second history is not a guaranteed
reaction deadline on other hosts or under another frame rate.

`-IncludeProcesses` also completed a separate ten-second Windows smoke check:
two samples with 136 readable processes each. Cold CIM collection took 8,820 ms
then 126 ms; this smoke ran outside timing windows. It is retained to expose
collector startup overhead rather than hide it.

## Three natural windows

The profiler recorded before every Churn phase, including startup. Native
observer selection and arm clicks were explicit; stale WindowFocused flags
from inactive clients are not pooled. Capture `run` is a local phase generation,
and its frame counter resets on phase changes; it is not the sampler's global
window/frame ordinal. Each observer's first Churn signal uses generation 1.

Times below are the probes' **server-clock UTC**; host log UTC is a separate
clock. Warm-up is approximate wall time from six-client launch to Churn.

| Attempt | Native observer | Warm-up | Churn start | Quiet start | Complete | Capture outcome |
|---|---|---|---|---|---|---|
| 1 | owner6 | 5m37s | 10:25:20.956 | 10:28:20.965 | 10:30:20.978 | No observer interval >50 ms; no dump |
| 2 | owner3 | 4m57s | 10:38:19.206 | 10:41:19.217 | 10:43:19.231 | No observer interval >50 ms; no dump |
| 3 | owner3 | 4m36s | 10:49:39.894 | 10:52:39.903 | 10:54:39.915 | First signal missed; later natural hitches retained |

All three use the exact same generated capture place and fresh sessions.
An older stopped PERF-02 preview editor was closed between attempts 1 and 2;
other unrelated processes were left alone. Attempt 3 also showed late CoreGui/
chat appearance during setup. These differences and differing observers prevent
treating cross-run variation as a controlled causal comparison.

Attempt 3 signalled foreground frame **3**, **56.335 ms**, at clock
252.359672 / server time 1791715779.996460; log UTC was **10:49:40.948**.
The file watcher returned the already-existing signal at **10:49:46.760**;
pause input followed at **10:49:53.978**, confirmed at **10:49:55.064**.
The 13.030-second log-to-input delay exceeded retention. The original interval
and `PERF03 slow interval observed` are absent: this is a real capture failure,
not a retained first-trigger success. Calibration did not make the automation's
natural-run reaction reliable.

Nevertheless the frozen buffer contains **four later native frames >50 ms**,
with the corresponding ordinary PERF-02 slow-marker sequence. It has 506
complete frames over **8,817.764 ms**, at client clock approximately
257.559486–266.377250. The export was observed at 10:51:06.508 UTC,
`microprofile-20261011-125106.html`, retained as `natural-3-first.html`.
Export/decoding occurred after the freeze; they cannot have caused those
retained frames. They do contaminate the remainder of attempt 3.

## Alignment and the smallest matched comparison

Before interpreting scope cost, eight successive `PERF02 slow interval end`
markers were matched in order to owner3's deferred slowFrame records. Each
gives `probeClock * 1000 - nativeMarkerMs`; their median is
**257,559.485954 ms**, with maximum absolute residual **0.046 ms**. The same
offset places editor cycle 2/3 creation and destruction at their recorded
clocks. This sequence identifies the later natural intervals without pretending
native and probe frame numbers or boundaries are identical. Full pairs are in
[`alignment.json`](perf-03/alignment.json).

| Native frame / span | Matched probe end frame / interval | Selected elapsed native scope |
|---|---|---|
| 42 / 60.387 ms | 351 / 58.962 ms | Present 18.244 ms; this does not explain the whole frame |
| 81 / 78.125 ms | 390 / 75.973 ms | Present 53.333 ms |
| 148 / 57.670 ms | 457 / 62.381 ms | Present 17.361 ms; render-query fence crosses into frame 149 |
| 149 / 83.980 ms | 458 / 115.633 ms | Present 62.428 ms; 12.510 ms overlap with the 34.093 ms fence span |

The retained sequence also contains probe frame 387 / 51.474 ms whose native
frame is below 50 ms, another reason not to equate the two metrics. The marker
labels the **end** of an observed interval; it is not the cause.

The smallest useful comparison is ordinary spans against hitch-overlapping
spans **inside this same frozen capture**: same observer, route, scene, offered
load, graphics state and instrumentation. For 502 non-hitch-overlapping Present
spans, median/p95/max are **3.179 / 7.006 / 34.960 ms**; the four overlapping
spans reach **62.428 ms**. For the corresponding 502 ordinary
WaitOnRenderNodeQueryFence spans, median/p95/max are **0.000157 / 1.688 /
24.307 ms**; overlapping spans reach **34.093 ms**. This locates increased
elapsed time in the render/wait path; it does not establish CPU work, a driver
fault, GPU saturation, paging, scheduler preemption or a game bottleneck.
Nested/inclusive scopes and worker Sleep spans must not be summed as CPU.
See [`same-capture-comparison.json`](perf-03/same-capture-comparison.json).

Within the capture, `PERF02 client sample` peaks at 0.372 ms, editor creation
at 1.214 ms and destruction at 0.621 ms. Editor cycle 2 was destroyed roughly
0.823 seconds before the 115.633 ms probe interval ended, and its next creation
was roughly 2.610 seconds later. This specific hitch is not demonstrated to be
editor construction/destruction. It does not exonerate all script, replication,
GC or game render work, nor explain all other slow frames. Native GPU frame
values of 7.24 / 1.07 / 0.71 / 0.49 ms cannot resolve the wait cause alone.
No broader one-client comparison or extra natural window was justified by an
actionable game cost. No gameplay optimization was applied or claimed.

## Host evidence and remaining attribution gap

Each natural window has 73 sequential five-second host observations with
process names, PID/start identity and cumulative readable CPU, plus raw core,
3D-engine, memory/paging and Studio counters. No command lines or arbitrary
Studio logs are archived. Summaries retain 35 wholly-contained Churn and 23
Quiet intervals; phase boundaries are approximate across the host/server clocks.

Attempt 3's signal anchor has `log UTC - serverTime = 0.951540 seconds`;
the earlier native observer anchor gives 0.947169 seconds. Thus the retained
58.962–115.633 ms probe events, server-clock 10:49:45.980–48.056, broadly align
with host UTC **10:49:46.93–49.01**, not the deferred Output export time. These
anchors include log delivery/synchronization uncertainty. The nearby intervals
are preserved in [`host-event-context.json`](perf-03/host-event-context.json).

For host UTC **10:49:46.270–51.311**, aggregate CPU was **92.758%**; all
readable Studio processes used **2.105 cores** of four. The eight task-era
Studio processes dominate the readable list; two older Studio processes are
also included in aggregate Studio counters and were not terminated. Foreground
client identity must not be inferred solely from which PID used most CPU.
Other readable consumers include collector `pwsh` **0.0248 cores**, `codex`
**0.0186**, `audiodg` **0.0093**, and several **0.0031-core** consumers.
`codex-computer-use` consumed zero measurable CPU in this particular five-second
delta, then 0.0314 cores in the pause interval. It is still diagnostic overhead,
not proven harmless. Nearby host observations recorded available RAM of
526 / 607 / 1,547 / 2,148 MB; native free RAM at the four hitches was
557 / 813 / 1,081 / 1,098 MB. This supports memory/host-pressure investigation,
not a proven page-fault cause.

The process collector omits unavailable CPU values and labels unavailable start
identities; protected/kernel consumers and asynchronous counter boundaries
leave a substantial aggregate CPU balance unexplained. Collector CPU excludes
services working on its behalf. Across attempt 2, computer-use was a significant
readable consumer in some intervals while the observer had no >50 ms frames;
high aggregate CPU alone is insufficient attribution. Five-second CPU/GPU/
paging averages cannot prove or exclude a millisecond scheduling event.

The installed Windows Performance Recorder was idle. A bounded CPU-trace start
was attempted after the windows: `wpr -start CPU -filemode` failed with
**0xc5585011**, “Failed to enable the policy to profile system performance.”
No policy, permissions or priorities were changed; `wpr -status` confirmed no
recording remained. No scheduler trace of the retained hitch exists. The exact
missing evidence is a time-aligned scheduling/GPU/fault trace, or another
supported trace that distinguishes on-CPU game cost from render/present waits.

## Diagnostic measurements, not new budget passes

All following series include capture-script, profiler, monitoring and host
collector overhead. Attempt 1 used bounded 250 ms log polling initially, then
file notification; attempts 2/3 used a file watcher. After attempt 3's freeze,
native export and offline inspection overlapped continuing gameplay. Its
**3,324.271 ms** maximum occurred near export/inspection, outside the retained
native buffer; it remains in raw data and is not attributed to a game cause.

| Attempt / phase | Frames | p50 | p95 | p99 | Max | >50 ms count / share |
|---|---:|---:|---:|---:|---:|---:|
| 1 Churn | 10,801 | 16.644 | 19.539 | 21.406 | 35.478 | 0 / 0% |
| 1 Quiet | 7,201 | 16.696 | 19.210 | 20.298 | 23.255 | 0 / 0% |
| 2 Churn | 10,801 | 16.710 | 18.960 | 21.347 | 34.964 | 0 / 0% |
| 2 Quiet | 7,201 | 16.750 | 18.280 | 19.039 | 23.352 | 0 / 0% |
| 3 Churn, contaminated | 10,566 | 16.736 | 19.787 | 22.917 | 3,324.271 | 8 / 0.0757% |
| 3 Quiet, diagnostic | 7,200 | 16.680 | 18.689 | 20.278 | 33.051 | 0 / 0% |

Milliseconds throughout. Attempts 1/2/3 requested and accepted respectively
**1,438 / 1,442 / 1,442** ordinary edits across the six owners, with no rejected
edits. Observer requested/accepted: **242/242, 240/240, 238/238**; RTT p95:
**36.615, 50.695, 51.901 ms**. Server Churn snapshot p95:
**0.157, 0.197, 0.150 ms**; world-reconcile p95:
**1.343, 1.397, 1.304 ms**. Quiet snapshot p95:
**0.128, 0.255, 0.128 ms**, world-reconcile p95 **0.004, 0.005, 0.004 ms**.
Full series, per-side loads, checkpoints, memory and host summaries are retained.

References remain p95 ≤20 ms, p99 ≤33.3 ms, >50 ms share <0.1%, RTT p95 ≤150 ms,
synchronous reconcile/snapshot p95 ≤2 ms. **No clean improvement repeat is
claimed** because no game repair or improvement claim was made. PERF-02's
13/10,750 (0.1209%), maximum 192.175 ms miss and PERF-01's historical misses
are unchanged; this diagnostic evidence does not replace them.

## Verification, evidence and playable handoff

The full Windows `Validate-Project.ps1` passed locally: pinned formatting/lint,
fresh Rojo build/sourcemap, Luau analysis and failure probes, source/serialized
structure, authored-map checks and every disposable-preview boundary. See
[`validation.txt`](perf-03/validation.txt). The optional native reader regression
passed against the actual calibration and natural captures, including fixed
marker selection, retained hitch context, unchanged worstOverlap output and
explicit truncated-input failure. PERF-02's matching old native summary and
clean-2 host summary reproduced exactly on existing fields. Required PR CI is
reported by GitHub separately; historical manual QA is not relabelled passed.
The concise executed-check ledger is [`checks.txt`](perf-03/checks.txt), including
the failed original-trigger retention and unavailable scheduler trace.

[`native-captures.zip`](perf-03/native-captures.zip) contains the two byte-identical
native Legacy HTML exports. [`samples.zip`](perf-03/samples.zip) contains all
three sanitized probe streams and all-process host streams, including smoke.
[`archive-manifest.json`](perf-03/archive-manifest.json) records bytes, SHA256 and
record counts. These capture dumps are trusted local input to the offline vendor
decoder, not arbitrary HTML to execute. Reconstruct after extracting under build:

```powershell
Expand-Archive docs/perf-03/native-captures.zip build/perf-03-reproduce/native
Expand-Archive docs/perf-03/samples.zip build/perf-03-reproduce/samples
node scripts/Test-PerformanceDump.mjs build/perf-03-reproduce/native/calibration.html build/perf-03-reproduce/native/natural-3-first.html
node scripts/Read-PerformanceDump.mjs build/perf-03-reproduce/native/natural-3-first.html build/perf-03-reproduce/native-summary.json
node scripts/Summarize-PerformanceHost.mjs build/perf-03-reproduce/samples/natural-3.jsonl build/perf-03-reproduce/samples/host-natural-3.jsonl build/perf-03-reproduce/host-summary.json
```

Node 24.19.0, built-ins only. Readers execute offline, never control Studio.
`slowFrameOverlaps` now includes bounded context for every retained >50 ms
native frame, preserving existing summary fields. `fixtureEvents` distinguishes
fixed PERF-03 markers from the engine's similarly named script scopes.

All task-owned six-client sessions and host/watch helpers were stopped normally.
Legacy HTML was toggled back off and the profiler hidden. The remaining gameplay
preview is generated independently, without PERF capture/probes or QA runners:

```powershell
./scripts/New-ModeReviewPlace.ps1 -Role Infinite -Showcase -OutputName mode-infinite-perf-03-review.rbxlx
```

Open `build/mode-infinite-perf-03-review.rbxlx` and Play. It uses local memory,
two labelled examples, four player lots and the existing failed-return adapter;
it does not test real DataStore/teleport or cross-session durability. Generated
SHA256: `CF25D730E67A2582DE8E7E7984C57615C073DDB532DCB74EA3763E7199664377`.
Native observation at **11:15:03.730 UTC** verified Ready, 801 × 413 and absence
of the PERF remote, controls and capture/client scripts. It remains running in
Studio. See [`native-observations.txt`](perf-03/native-observations.txt) and
[`gameplay-preview.png`](perf-03/gameplay-preview.png).

Keep #29 **draft** for the combined gameplay/style/pacing review, with the
unresolved performance risk visible. Physical touch/controller comfort, actual
devices and real-service outcomes remain separate follow-ups. Reopen this
investigation when a supported time-aligned scheduler/GPU/fault capture can
resolve the observed waits, or a reproducible normal-play hitch provides an
actionable game scope. Do not require new hardware/publication, start another
profiling task automatically, or hold unrelated gameplay work on speculation.
