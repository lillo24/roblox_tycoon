# Local performance fixtures

These files are unmapped by the production Rojo project. New-PerformanceReviewPlace
injects them into a disposable local-memory Studio scene. Workloads builds valid
production transactions, Server wraps synchronous hot paths and controls timed
runs, Client samples actual frames and drives owner RPC/editor churn, and Sampler
prints bounded JSON series/stats. InfiniteShowcase and ProfileMemoryStore are reused.
PERF-02 defers all probe output until three seconds after Idle. `begin` resets
each side's bounded in-memory run (40,000 samples per metric / 6,000 records);
overflow invalidates the run with an error rather than silently dropping values.
Chunks retain their original values/timestamps and are JSON encoded only at export.
Idle observations are excluded. This changes measurement overhead/memory relative
to PERF-01, not gameplay. `SamplerCheck.luau` is a separate Edit-only regression
for output timing, chunk retention, timestamps and resets; it is never injected
into the timed or gameplay-only copies.
Client records requested/accepted/rejected edits, editor counts and timestamped
edit/editor events. Slow intervals above 33.3 ms get a bounded record; the
MicroProfiler `PERF02 slow interval end` tag marks the end of that observed
interval, not measured CPU work or proof of its cause. Fixed probe/server labels
help identify fixture overhead in diagnostic captures. No production module is
instrumented. PERF-02's clean windows and separate traces are in `docs/PERF_02_REVIEW.md`.
Series use 64-value chunks because Studio truncates long Creator log lines.
Export-PerformanceEvidence reads only probe JSON, removes account identifiers and
rejects incomplete records; nearest-rank percentiles keep foreground samples separate.

Fresh is one empty actual owner. Developed is one actual Garden owner plus five
labelled synthetic Garden properties, solely a same-scene control for SixOwners'
six Garden arrivals. The earlier baseline used alternating Garden/Sky examples;
its recorded result is not an exact scene match for six actual Garden owners.
SixOwners seeds actual
arrivals without taking any lots with examples and requires six real clients.
Dense owns all 14 unique equipment/expansion items and 48 lantern decorations;
the current catalogue can reach 62 of the 64 global ceiling. Greedy valid packing
leaves objects stored when they cannot fit. It does not waive placement validation.

Sample uses 30 seconds warm-up and 120 seconds stable sampling. Churn uses 180
seconds of ordinary owner store/re-place/half-turn edits, palettes, purchases and
editor creation/destruction followed by 120 quiet
seconds. Frame intervals distinguish WindowFocused/background signals, and all
stats retain their actual side/phase. The camera visits the same six slots at
20-second stops. Memory checkpoint work is not DataStore latency. Wrappers do not
measure total script CPU. No global connection-count claim is made.
Studio can leave WindowFocused true in inactive test windows. Confirm the actual
foreground observer through native input and record that client separately; do
not pool clients based on this flag alone. Preserve ambiguous raw flags and label
those clients' foreground/background state unverified in the review.
Final probes additionally record Session.accrue work and actual invocation spacing;
the latter is income cadence, not CPU time, and does not include attribute/world publish.

## PERF-03 opt-in capture signal

`New-PerformanceReviewPlace.ps1 -Workload SixOwners -CaptureDiagnostics` adds
`Capture.client.luau` to the disposable performance place. The default build,
gameplay-only preview and production project do not contain it. The selected
observer clicks **PERF03 arm foreground** in its actual native viewport. The
first Churn/Quiet PreRender interval over 50 ms turns its label red and emits one
`PERF03_SIGNAL` log line with phase, local frame, interval, clocks and calibration
flag. It is disarmed on focus loss and at the end of a run; re-arm deliberately.
The profiler label and Output line occur **after** the interval and do not assign
its CPU cause. Signals and Output writes perturb diagnostic frames, so runs with
this option are not clean frame-budget comparisons.

To test the path, start the native profiler before clicking arm and then click
**PERF03 test 100 ms stall** while Idle. The next frame should trigger a red
signal. Press Ctrl+P promptly in that same native client, export 512 frames and
check that the native timeline contains `PERF03 deliberate calibration stall`,
preceding/following frames and `PERF03 slow interval observed`. Match the log
event to that native marker. The Idle calibration has no buffered PERF01 series;
for natural Churn/Quiet events, compare its clock and phase with those samples
after export without inventing an exact native frame-to-probe ordinal mapping.
This deliberate busy frame only tests capture timing, never natural performance.
Run a fresh diagnostic session after calibrating, with the profiler recording
before Churn. Arm only the confirmed foreground observer after focus setup; on
its red signal pause/export immediately, inspect the dump, then re-arm only if a
specific question needs another event. If the calibration stall is absent from
the dump, resolve that capture gap before repeating six-client churn. Native
Studio controls and capture timing have not been verified on this Linux checkout.
For host attribution, `Observe-PerformanceHost.ps1 -IncludeProcesses` additionally
buffers names, PIDs, available start times and cumulative CPU seconds for all
visible processes. The offline summary pairs samples using name/PID/start time
and labels missing start times uncertain. This option is diagnostic overhead;
review and sanitize raw process names before sharing evidence. Five-second CPU
deltas cannot attribute a particular millisecond stall or replace a native trace.
