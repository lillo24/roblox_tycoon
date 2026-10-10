# PERF-03 — Triggered Hitch Capture and Attribution

## Goal and starting point

Capture a natural six-client slow interval inside a native timeline, attribute the cost as far as the evidence permits, and fix any demonstrated game bottleneck. First establish a capture method that reacts to a hitch quickly enough to preserve it. Reuse the PERF-02 fixtures and readers; implementation choices belong to Work. Continue through available diagnosis and supported repairs without intermediate founder approval.

Read `AGENTS.md`, `docs/PERF_02_REVIEW.md`, the PERF-01 findings and the performance-fixture README. At briefing time the complete stack is draft PR #27, `codex/perf-02-six-client-hitches`, head `ab7ba14350cb12258a69f3a021b2e8853a295d46`, inheriting #25 → #23 → #22 → #21 → #18. Obtain this brief from latest main, resolve the current implementation head and work in an isolated branch/worktree from it, or updated main if merged. Record intervening changes. Open a draft PR into main with an explicit comparison against the tested predecessor. Keep the gameplay stack and experiments #14–#16 unmerged. Publication, hosted settings and new hardware are outside this task.

## Evidence to build on

PERF-02 changed measurement, not production gameplay. Its two clean churn runs passed p95/p99 at 19.089/22.204 ms and 19.851/23.206 ms. The second retained **13/10,750 frames over 50 ms (0.1209%)**, maximum **192.175 ms**, failing the unchanged <0.1% reference. The maximum occurred about half a second after churn began, before the observer's first ordinary edit, after the clients had warmed up. A later cluster overlapped 97.1% total host CPU while Studio accounted for about 2.05 of four cores. Other consumers and scheduler delays were not identified. This supports a hypothesis, not a causal conclusion.

Three native dumps contained 506 complete frames each, roughly 8.4 seconds, with maxima of only 19–23 ms. None retained an observed hitch. In one diagnostic the profiler remained paused through phase startup. Repeating that capture schedule is unlikely to answer the question.

The command-bar call to `MicroProfilerService:DumpToFileAsync` was denied by RobloxScript capability. Native pause/export works. Do not retry restricted methods, alter permissions or assume a Studio connector exists. Use the supported capabilities actually available in the local environment.

## Prove capture before repeating the workload

Build the smallest diagnostic-only path that signals a slow interval and promptly pauses the **correct foreground client's** running MicroProfiler while its history still contains that interval. A bounded one-shot signal plus supported native UI control is a possible approach; a supported connected profiler interface is another if already available. Keep the observer explicitly selected: background clients naturally run around 15 Hz, and their unreliable WindowFocused flags must not trigger capture.

Record the run, observer, phase, frame ordinal, interval duration and clock, with a recognizable profiler marker. The marker occurs after the observed interval; preserve preceding frames and establish the relationship instead of calling the marker the cause. Bound signal count and re-arm deliberately. A diagnostic signal may be emitted immediately after the event; keep ordinary sample output deferred. Label monitoring, signal, pause and export overhead and keep these runs separate from clean budget measurements.

Validate this capture path once with a clearly labelled, short, fixture-only artificial stall. Confirm the native export contains that known stall and marker, preceding/following frames, and enough timing information to align it with the probe. Measure reaction time against the retention actually observed in this Studio build. The artificial event validates tooling only; it is excluded from natural-hitch evidence and performance verdicts, and must be disabled for subsequent runs and absent from the gameplay preview.

If the available control path cannot preserve even the known event, stop long repetitions and report the exact missing capability or operator action. Do not substitute another collection of ordinary-frame dumps. Keep a ready-to-run capture setup and concise instructions if local assistance is genuinely required.

## Capture the natural event and test the leading cause

Use the established six actual Garden owners, fresh disposable profiles, camera route, viewport/quality conditions and ordinary edit workload. Have the profiler recording **before** churn starts, after a documented warm-up. Include phase-start events; do not discard the early 192 ms class of interval by redefining warm-up. Trigger on an observed foreground interval over 50 ms, pause promptly, then export the frozen buffer. Verify the target event is retained before analysing it. A >50 ms natural event is useful; matching the historical 192 or 314 ms value is unnecessary. Try a second event only to resolve a specific ambiguity or test the finding. Bound unsuccessful attempts, for example to three five-minute windows once capture is proven.

Extend host observation only enough to identify significant CPU consumers across processes with timestamps overlapping the event. Preserve process identity across samples and distinguish Studio, the collector/automation and other work. The collector's own CPU does not include all work done on its behalf by other services. Retain relevant names/timing/CPU/memory metrics without copying unrelated command lines or private logs. Use an already available bounded scheduler trace if the native timeline shows unexplained gaps and the tooling permits it; sparse process totals alone do not establish a millisecond scheduling cause. Do not stop unrelated user processes or change system priorities to manufacture a pass.

Choose the smallest matched comparison indicated by the capture. This may isolate game/UI/render/replication/GC work, fixture overhead, or a repeatable host condition. Keep scene, offered edit load, observer, quality and sampling settings comparable, and record differences. Do not assign every slow frame to the same cause from one example. A capture can establish a game cost, external contention, measurement interference, mixed causes or an unresolved gap.

Apply a small game repair only when justified. Preserve PERF-01's reconciliation fix, content, visual effects, player/object limits, validation, earnings, saving and Session behavior. Fix harness defects as harness defects; do not report them as gameplay optimizations. If no game repair is supported, retain that finding without speculative code changes.

## Verification and handoff

For any claimed improvement, repeat matched clean measurements with capture triggers, detailed profiling and artificial stalls disabled. Retain per-run frame p50/p95/p99/max, >50 ms count/rate, requested/accepted edits and latency. Budgets stay p95 <=20 ms, p99 <=33.3 ms, >50 ms share <0.1%, edit RTT p95 <=150 ms, synchronous reconcile/snapshot p95 <=2 ms. Report churn and quiet separately and keep failed/inconclusive runs. Run changed-area regressions and the repository's required validation; check cleanup of any added helpers.

Deliver `docs/PERF_03_REVIEW.md` with the capture-path verification, exact revisions/settings, a native timeline containing the natural event if obtained, probe alignment, relevant host evidence, the causal comparison and any repair/retest. Keep native evidence and compact raw records inspectable. Link it from PERF-02 and update the combined review guide without rewriting historical results. Distinguish a successful capture from an explained cause and from a verified fix. If unresolved, name the concrete evidence still missing; do not claim overall performance passed.

Stop task-owned sessions/helpers, restore test settings and leave a reproducible probe-free gameplay preview. Keep the PR draft. Physical-device, real DataStore/teleport and subjective play review remain separate.

Official guidance checked 2026-10-10: [MicroProfiler pause/export and retained frames](https://create.roblox.com/docs/performance-optimization/microprofiler), [native walkthrough and profiling labels](https://create.roblox.com/docs/performance-optimization/microprofiler/use-microprofiler). Verify controls against the installed Studio version.
