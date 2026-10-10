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
