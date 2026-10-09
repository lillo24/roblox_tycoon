# PERF-01 — Infinite Stack Performance and Cleanup

## Goal and starting point

Run the remaining performance checks on the combined Infinite stack, fix demonstrated bottlenecks or resource-lifecycle defects, and leave a reproducible playable result for founder review. This is a focused measurement-and-repair pass; preserve Infinite content/pacing, Session behavior, ownership and saving guarantees. Architecture and profiling implementation belong to Work.

Read AGENTS.md and `docs/MODE_01_REVIEW.md`. At briefing time the complete stack is draft PR #23, `codex/mode-01-entry-routing`, head `c26c92652c745c22cff35276d84180a04320e4e1`, on #22 → #21 → #18. Resolve its current head before starting. Use an isolated branch/worktree from that implementation, or updated main if the stack has since merged. Obtain this brief from latest main. Open a draft PR into main, identify inherited changes and link the comparison against the tested predecessor. Keep the gameplay stack and experiments #14–#16 unmerged; publication and hosted configuration changes are outside this task.

Work in the local environment with Roblox Studio available. Continue through available checks and confirmed fixes without intermediate founder approval. If a capability is missing, complete the remaining useful work and report exactly which measurement could not run; source inspection, fixture counts and CI are not substitutes for client performance observations.

## Workloads worth measuring

Use disposable local-memory previews, a fixed source revision and reproducible property data. Keep seeding/probes outside production startup. The previous six-property result—258 anchored parts created in about 0.031 seconds—measures construction only; it is not a six-client or frame-rate result.

1. **Controlled baseline:** one real client with a fresh property, then one real client viewing six developed properties. Use the same camera route, window size and graphics settings so the extra scene cost can be distinguished from additional Studio processes.
2. **Six actual clients:** six real owners in one server, each with a developed property. Exercise simultaneous visiting, normal income/checkpoints, purchases, placement, storage and palette changes. Observe both the editing owner and another client looking at that property. Six synthetic profiles alone do not satisfy this check.
3. **Supported content pressure:** test representative developed layouts and a dense, valid layout near the actual placement capacity. Separately exercise inventories near the supported 64-object / 48-decoration limits, including stored items and the full Arrange list. Check current limits first. Do not bypass footprints/prerequisites or pretend all 64 objects necessarily fit on the ground. Report owned, placed, animated and rendered-part counts separately.
4. **Cleanup and sustained use:** repeat editor/preview open-close, move/store/re-place, theme changes, respawn, departure/lot reuse and local failed-mode-return recovery. Include quiet periods after churn to see whether retained objects, task-owned subscriptions and memory stabilize. Check that animation stops outside its intended lifetime and that a reused lot inherits no old callbacks or objects.

The normal `-Showcase` preview occupies two lots with examples and leaves only four player lots. Do not use that unchanged for the six-owner run. Adapt the existing unmapped showcase/memory fixtures to seed actual test owners, using valid production schema/transactions. Keep rendered-fixture tests distinct from real client sessions. No live DataStore writes, real teleports or physical-device access are prerequisites for this local pass.

## Measurement discipline

Record the tested commit/build, machine CPU/GPU/RAM, Studio version, graphics level, frame cap, viewport, client count and foreground/background state. Use fixed warm-up and sampling windows—for example 30–60 seconds warm-up and at least two minutes of stable sampling, plus a five-minute churn/quiet run. Keep logs/probes bounded; separate short detailed profiler captures from normal sampling so instrumentation does not dominate the result.

Capture useful evidence rather than an assertion-count score:

- Client frame-time distribution and spikes, with p50/p95/p99 where raw sampling supports them; client script/render cost and visible input hitches.
- Server script/physics cost, income-tick delay and accepted-edit processing time. A Heartbeat interval is not script CPU time; label each metric accurately.
- Client/server memory trends, Lua heap and relevant instance counts before/during/after repeated cycles. Retained references need investigation; a temporarily larger heap alone does not prove a leak. Use supported instrumentation, not an invented global connection count.
- Replication/network rate and edit response latency, especially during simultaneous edits; distinguish serialized snapshot size from measured wire traffic. Inspect saved-profile size and local checkpoint work without presenting memory-backend timings as Roblox DataStore latency.

Choose and state provisional budgets before evaluating results. The 60 FPS desktop reference corresponds to about 16.7 ms/frame; a possible 30 FPS mobile baseline is about 33.3 ms/frame, not a claim that phones passed. Interpret results on the recorded machine and workload. Six local clients compete for the same host resources, and inactive windows may be throttled: keep a foreground measurement client and use the one-client/same-scene control before attributing a slowdown to game code. Do not pool foreground and background samples into one misleading percentile.

Use Roblox's MicroProfiler, Script Profiler and supported client/server stats as appropriate. A phone-sized viewport checks layout, not physical-phone CPU, memory or thermal performance. If the host or Roblox throttling prevents six clients, record the largest successful run, distinguish the limitation from a product defect, and retain the six-client check as unobserved. Avoid repeated environment rebuilds or unrelated destructive process cleanup.

## Source-informed candidates, not predetermined fixes

At the reviewed head:

- `PropertyWorld.reconcile` clears and rebuilds the property's upgrade models whenever its revision changes, including edits with little visible impact. Measure instance churn, replication bursts and spectator frame spikes.
- The normal income publish path calls `Profiles.snapshot` → `ProfileSchema.capture` → full schema/placement validation. Measure the cost with dense placements and full inventories before choosing caching or incremental validation.
- `PropertyActivity` tracks runtime BaseParts and scans them at 10 Hz, applying distance/viewport checks to animated parts. Check visible/distant workloads, reduced motion and attach/detach cleanup.
- `PropertyEditor` rebuilds panel contents and local previews during navigation/editing. Exercise long inventories, rapid ordinary interactions and repeated closure for hitches or retained resources.

These observations come from code, not timing evidence. Start with measurements and investigate whichever path dominates. Apply small justified repairs, then repeat the affected workload under the same conditions. Do not improve a benchmark by weakening server validation, removing content, lowering player/object limits, changing earnings, or disabling expected effects silently. Shared refactors must retain Session behavior. Add targeted regressions for actual defects and run the repository's required validation for the final changes; do not rerun every historical manual test after each measurement.

## Deliverable

Commit a concise `docs/PERF_01_REVIEW.md` with the workload definitions, measurements, captures/raw samples needed to inspect them, exact revisions, confirmed findings, fixes and comparable before/after results. Distinguish measured passes, observed failures and unobserved checks. Add only the smallest reusable fixtures/probes needed to reproduce the run; no production telemetry service is required.

Update the combined review guide to reflect what this pass actually closed. Stop only task-owned sessions, restore any test settings you changed, and provide one reproducible gameplay-only preview for the founder. Keep the PR draft for combined review. Real-service durability/teleports, physical devices and subjective style/pacing remain separate unless actually observed under existing authorization. If no consequential bottleneck is found, report that bounded result without inventing optimization work.

Official references checked 2026-10-09: [Studio multi-client testing](https://create.roblox.com/docs/studio/testing-modes), [identify performance issues](https://create.roblox.com/docs/performance-optimization/identify), [MicroProfiler](https://create.roblox.com/docs/performance-optimization/microprofiler), and [hardware-test limits](https://create.roblox.com/docs/performance-optimization/test-on-hardware). Recheck platform guidance if needed during execution.
