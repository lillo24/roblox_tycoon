# Local performance fixtures

These files are unmapped by the production Rojo project. New-PerformanceReviewPlace
injects them into a disposable local-memory Studio scene. Workloads builds valid
production transactions, Server wraps synchronous hot paths and controls timed
runs, Client samples actual frames and drives owner RPC/editor churn, and Sampler
prints bounded JSON series/stats. InfiniteShowcase and ProfileMemoryStore are reused.
Series use 64-value chunks because Studio truncates long Creator log lines.
Export-PerformanceEvidence reads only probe JSON, removes account identifiers and
rejects incomplete records; nearest-rank percentiles keep foreground samples separate.

Fresh is one empty actual owner. Developed is one actual Garden owner plus five
labelled synthetic properties, solely a same-scene control. SixOwners seeds actual
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
