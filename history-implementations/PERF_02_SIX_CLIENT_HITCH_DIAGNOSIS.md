# PERF-02 — Six-Client Hitch Diagnosis and Targeted Optimization

## Goal and starting point

Capture the remaining six-client frame hitches, distinguish game work from local Studio/host contention, and fix any demonstrated bottleneck. Continue through diagnosis, justified repairs and validation without intermediate founder approval. Profiling choices and implementation belong to Work. Do not turn this into another general QA pass or require the founder to play-review first.

Read `AGENTS.md`, `docs/PERF_01_REVIEW.md` and `tests/fixtures/Performance/README.md`. At briefing time the complete implementation is draft PR #25, `codex/perf-01-infinite-stack`, head `c096eb691667d7961a38cb5dadf0843724b36ea5`, inheriting #23 → #22 → #21 → #18. Obtain this brief from latest main, resolve the current implementation head, and use an isolated branch/worktree from it, or updated main if the stack has since merged. Record the exact tested revision and any intervening changes that affect comparisons. Open a draft PR into main with an explicit comparison against the tested predecessor. Keep the gameplay stack and experiments #14–#16 unmerged; no publication or hosted configuration changes are part of this task.

Work in the local environment with Roblox Studio. Reuse the existing disposable memory-backed fixtures, generator and evidence exporter. Do not rebuild the harness unnecessarily. Source review and CI cannot substitute for observing client frames. If a capture capability is unavailable, complete the useful available work and state precisely what remains unobserved.

## What remains unresolved

PERF-01 already fixed full-property reconstruction: dense reconciliation p95 fell from 10.421 to 0.797 ms. Preserve that repair. Snapshot validation was within budget and did not justify a cache/refactor.

The focused six-owner churn run still recorded:

- Frame p95 **21.518 ms**, p99 **27.343 ms**, maximum **314.415 ms**.
- **18 of 10,713 frames over 50 ms (0.1680%)**.
- Following quiet p95 **20.321 ms**; a separate six-owner stable repeat was **20.647 ms**.
- Owner edit RTT and synchronous server reconcile/snapshot p95 remained within their budgets.

The one-client, six-property control passed at 18.080 ms p95 with the same 372 world parts / 90 animated parts. It did not match avatars, stored inventory, active publishers or client/server work. Six Studio clients shared an i5-4690 four-core host. Host contention is plausible, not established. One screenshot and light log reads occurred during the hitch run; their contribution is also unknown. PERF-01's separate dense MicroProfiler/Script Profiler captures did not capture or explain this six-client hitch.

Retain the reference budgets: foreground frame p95 <=20 ms, p99 <=33.3 ms, frames over 50 ms below 0.1%; ordinary edit RTT p95 <=150 ms; synchronous reconcile and snapshot p95 <=2 ms each. Report churn and quiet separately. Do not relax budgets or discard slow frames to obtain a pass.

## Reproduce cleanly, then capture the cause

1. **Re-establish the workload.** Use six actual owners in SixOwners, valid Garden profiles and the existing camera/edit route. Reset disposable profiles between comparable runs. Keep the prior viewport, graphics conditions, warm-up and 180-second churn / 120-second quiet phases where possible. Record differences rather than claiming exact equivalence. Verify all six owners are Ready and identify the real foreground observer through native input; Studio's WindowFocused flags alone previously misidentified inactive clients. Record client count, source/build, Studio version, machine, viewport, observed quality/cap, profile/scene counts and timing. If changing Automatic quality to a fixed supported setting, establish a new matched baseline; do not compare it silently against PERF-01.
2. **Collect clean timing windows.** Keep screenshots, log reads/exports, builds, tests, window switching and detailed profiler interaction outside the measurement windows. Buffer bounded samples and export afterward. Make the action schedule/load comparable and report requested/accepted edits and errors so reduced work cannot masquerade as an improvement. Run two or three clean repeats to establish variability; keep each result separately. Use lightweight timestamped host/process observations where available to check CPU/core pressure, GPU use, memory and paging without creating a second workload. Clearly distinguish wall/frame intervals from measured CPU work.
3. **Capture a representative slow frame.** In separate diagnostic runs, capture the foreground client's MicroProfiler timeline around a reproduced hitch, with preceding/following frames. Verify the exported dump actually contains the slow frame; a generic short capture after the event is insufficient. Identify the run, client, phase and frame/timestamp relationship. Use server capture or Script Profiler only where needed to investigate the leading cause. Keep instrumentation/capture actions identifiable and compare against clean runs. Small temporary profiling labels or event markers are appropriate; keep probes bounded and outside production startup.

Follow the trace: script/UI work, allocations or GC, replication/instance updates, rendering/GPU waits, physics, or scheduling gaps. Correlate edit/editor/palette events and server activity where relevant. Low server per-call p95 does not rule out bursts or client work; a low average CPU reading does not rule out a short saturated core. A blank timeline gap or correlation alone does not prove an OS scheduling cause. State what the evidence supports and what remains uncertain.

## Separate causes with the smallest useful comparison

Choose a controlled comparison based on the trace, changing one relevant factor at a time. Reuse the one-client same-scene control as context, while preserving its workload limitations. Compare six-owner quiet/churn or isolate the suspected edit/editor/effect path if it helps explain the hitch.

If investigating host pressure by reducing background rendering or changing process count, document the change and verify how it affects scene, action rate, replication and script work. That is a diagnostic condition, not a passing six-client result. Temporary effect/UI suppression can help isolate cost but is not the shipped fix. Keep foreground/background series separate. If another representative setup is already available, use it to test the hypothesis; new hardware, physical devices and a published test experience are not prerequisites for this pass.

Do not chase the exact 314 ms value indefinitely. If it does not recur after the clean repeats and focused capture attempts, report non-reproduction, investigate any repeatable p95/spike-rate miss, and retain the original hitch as unresolved. A single clean run or absence of a captured spike does not establish a fix. Stop additional sampling when it no longer resolves a concrete remaining question.

## Repair, verify and hand off

Make the smallest supported repair when evidence identifies game-owned work or a fixture defect. Preserve ownership, validation, saving, Session behavior, content, object/player limits, earnings and expected visual effects. Do not invent optimizations when the cause remains unknown. If the harness caused the problem, fix it and rerun the unchanged game; label that as a measurement correction rather than a gameplay speedup.

Repeat the affected workload before/after under matched conditions and comparable action load. Report per-run p50/p95/p99/max, >50 ms counts and rates, accepted edits/latency, and the relevant cost/resource metrics. Retain failed and inconclusive runs. Check lifecycle/cleanup for changed resources, add regressions for actual behavior defects, and run the repository's required validation for the final changes. Detailed profiler runs remain diagnostic evidence, separate from budget runs.

Deliver `docs/PERF_02_REVIEW.md` with exact revisions, reproducible commands, compact raw samples and native captures, the trace-based finding, controlled comparisons, fixes and remaining limits. Clearly distinguish game defect, host/Studio limitation, instrumentation artifact and unresolved hypotheses; mixed causes are possible. Update the combined review guide and link the follow-up from PERF-01 without overwriting historical evidence. State which budgets pass, miss or remain unobserved. If no game-code change is justified, an evidence/fixture-only draft PR is a valid outcome; say what evidence would resolve the open question.

Stop only task-owned sessions, restore changed test settings, and leave a reproducible gameplay-only preview without probes. Keep this PR draft for combined review. Physical-device comfort/performance, real-service DataStore/teleport checks and subjective pacing remain separate.

Official references checked 2026-10-10: [MicroProfiler](https://create.roblox.com/docs/performance-optimization/microprofiler) and [identifying performance issues](https://create.roblox.com/docs/performance-optimization/identify). Use capabilities supported by the installed Studio version.
