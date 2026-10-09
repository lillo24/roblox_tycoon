# PERF-01 performance review

Immediate implementation predecessor: MODE-01 #23,
`c26c92652c745c22cff35276d84180a04320e4e1`; brief pulled from main `671d469`.
All earlier gameplay changes are inherited. Keep the gameplay stack draft.

Provisional desktop budgets set before measurement: foreground frame interval
p95 <=20 ms, p99 <=33.3 ms; >50 ms spikes below 0.1% of stable frames; ordinary
edit round trip p95 <=150 ms; synchronous snapshot/reconcile p95 <=2 ms each.
Five-minute churn/quiet should return task GUI/preview and world counts to their
explainable plateau, with no sustained post-warmup Lua-heap growth across repeated
quiet windows. A single heap increase is not a leak finding. Mobile's 33.3 ms
reference is a planning budget only; no physical mobile pass is inferred.

Host: Intel i5-4690 3.50 GHz (4 cores/4 threads), 17,118,912,512 bytes system RAM,
NVIDIA GTX 1660 SUPER, driver 32.0.16.1088. WMI's AdapterRAM truncates this card;
it is not used as a VRAM measurement. Studio/settings/builds and outcomes follow.

## Reproduction and measurement boundaries

Code/probe baseline is `1003caa`; its production code is identical to #23.
The rendering repair and final probes are `3273428f835face867f9f6de81a14f0662037782`.
The final same-geometry control is `91a81b6ddb92b0f0280d9b9747968a9c4732f6e4`;
that commit changes only the synthetic control from mixed presets to all Garden
and documents Studio focus ambiguity. Production remains the repaired revision.
[PERF-only comparison](https://github.com/lillo24/roblox_tycoon/compare/c26c92652c745c22cff35276d84180a04320e4e1...codex/perf-01-infinite-stack).
No gameplay stack or experiment was merged, and no game was published.

Studio `0.742.0.7421053`, Windows, GTX driver above. Rendering QualityLevel and
SavedQualityLevel were **Automatic** throughout the paired runs. The native
command bar could read those settings, but changing quality and reading the
frame-rate cap were denied by RobloxScript capability. The cap is unobserved;
the roughly 60 Hz cadence does not prove a configured 60 FPS cap. This is a
recorded desktop/automatic-settings observation, not a fixed-quality device certification.

One-client comparisons use the same iPhone XR landscape emulator: actual camera
ViewportSize **801 × 413**, displayed in a 604 × 280 phone canvas. The emulator
checks layout only. Studio was maximized during the dense runs. Prior generated
review windows were closed through Studio to free resources; no unrelated
process was killed. No CLI builds or test suites ran during timed sampling.

Workload definitions and bounded probes are in
[`tests/fixtures/Performance/README.md`](../tests/fixtures/Performance/README.md).
Sample is 30 seconds warm-up plus 120 seconds stable, visiting lots 1–6 in fixed
20-second camera stops. Churn is 180 seconds of ordinary RPC edits/editor cycles
plus 120 seconds quiet. Inspectable account-safe JSONL and nearest-rank summaries
are under [`perf-01/`](perf-01/); foreground and background series stay separate.
For six clients, only owner5's foreground state was verified by native viewport
input. Other inactive clients retained a true WindowFocused flag in Studio;
their raw flags are preserved but their actual foreground state is unverified.
An initial fresh run with truncated long log lines was discarded and repeated
using 64-value chunks; the exporter rejects incomplete JSON.

```powershell
./scripts/New-PerformanceReviewPlace.ps1 -Workload Fresh
./scripts/New-PerformanceReviewPlace.ps1 -Workload Developed
./scripts/New-PerformanceReviewPlace.ps1 -Workload Dense
./scripts/New-PerformanceReviewPlace.ps1 -Workload SixOwners
./scripts/Export-PerformanceEvidence.ps1 -LogPaths <actual-Studio-log-paths> -Name <run-name>
```

Open each generated `build/mode-perf-*.rbxlx` in Studio. Play and select PERF
sample, then PERF churn after completion. SixOwners needs Server & Clients with
six actual clients, no Showcase examples. Keep one foreground observer, focus
then blur every other client before sampling, and record actual client count.
Focus the game viewport after using the command bar: the command bar itself
produced background samples. The repeated six-owner foreground export selects
only probe records with server time 1791566070 through 1791566228 from the seven
logs before passing those lines to the same exporter. This keeps the repeat
separate from the earlier sample/churn in that session.
Stop resets the explicitly injected memory backend. These probes never enter
production startup. To reproduce the before run, use baseline `1003caa` in a
separate checkout. Do not use the current fixed renderer as a before result.

## One-client results before the repair

| Workload | Actual clients / developed properties | Owned / placed / stored (actual owner) | World / animated BaseParts | Stable frames | Frame ms p50 / p95 / p99 / max |
| --- | --- | --- | --- | --- | --- |
| Fresh | 1 / 0 | 0 / 0 / 0 | 56 / 0 | 7,201 | 16.863 / 18.059 / 18.456 / 25.613 |
| Developed control | 1 / 6 (5 synthetic) | Garden preset | 332 / 76 | 7,201 | 16.792 / 18.125 / 18.686 / 26.460 |
| Dense | 1 / 1 | 62 / 41 / 21 | 220 / 17 | 7,199 | 16.852 / 18.097 / 18.650 / 39.072 |

All three stable foreground windows had **zero frames over 50 ms** and met the
provisional frame budgets. The six-property control isolates extra scene content
from extra client processes; it is not six actual owners. Dense uses all 14
unique progression items and 48 lanterns. The current catalogue can reach 62
owned objects under the 64 ceiling, and this valid greedy packing leaves 21
stored; it is not a claim that 64 objects fit. The dense profile JSON was 4,788
bytes at revision 116, measured through the actual client RPC.

Five-second client Stats samples: Fresh mean render CPU/GPU 4.871/2.591 ms;
Developed 5.089/2.977 ms. These are sparse engine observations, not frame
percentiles or script CPU. Full observations include HeartbeatTime and physics.
PreRender delta measures frame interval; server Heartbeat delta measures cadence.
Neither is total script execution time. F5 Stats memory includes Studio/editor
and both simulations; client/server totals must not be summed. Script-VM
`gcinfo()` is reported separately from Stats' all-VM LuaHeap tag.
Metric interpretation follows Roblox's [Stats reference](https://create.roblox.com/docs/reference/engine/classes/Stats)
and [PreRender definition](https://create.roblox.com/docs/reference/engine/classes/RunService#PreRender).

## Confirmed bottleneck and repair

Dense before: 223 accepted edits in 180 seconds, ordinary owner round trip
p50/p95/p99 **86.184/88.986/103.031 ms**. Transaction work p95 0.863 ms and
snapshot work p95 0.536 ms were within budget. Reconcile work p95 **10.421 ms**
(max 11.716 ms) exceeded 2 ms, with **36,748 BaseParts added and removed** during
the churn window. Source inspection confirmed every revision destroyed the
whole upgrades folder, including stored purchases and palettes.

PropertyWorld now retains unchanged silhouettes and ground, removes stored
objects, and rebuilds only content/placement changes. Models owns explicit
palette-part metadata and recolors in place, including animated RestColor.
Replacement silhouettes get fresh RestFrame/OrbitCenter. Lot destruction clears
all render metadata; no owner cache survives departure. Schema validation,
capacity, income, saved data and Session code are unchanged. The measured dense
snapshot cost did not justify a validation/cache change.

The matched repaired stable dense window collected 7,201 foreground frames:
p50/p95/p99/max **16.822/18.099/18.703/26.337 ms**, zero over 50 ms. It retained
the same 220 world parts and 17 animated parts. Snapshot p95 was 0.587 ms.
Final-only income probes measured Session.accrue p95 0.005 ms and invocation
spacing p95 1,001.143 ms (max 1,017.010 ms). Accrue work excludes publishing;
invocation spacing is cadence, not CPU. Those two extra probes were absent from
the before build and are identified separately rather than compared as a speedup.

| Matched 180-second dense churn | Before | After |
| --- | --- | --- |
| Accepted ordinary edits | 223 | 231 |
| Reconcile ms p50 / p95 / p99 / max | 8.973 / 10.421 / 11.383 / 11.716 | 0.400 / 0.797 / 1.096 / 3.735 |
| Owner round trip ms p50 / p95 / p99 | 86.184 / 88.986 / 103.031 | 50.435 / 51.640 / 51.965 |
| Foreground frame ms p95 / p99 | 18.478 / 21.125 | 18.208 / 20.049 |
| BaseParts added / removed during churn | 36,748 / 36,748 | 828 / 834 |

Reconcile p95 improved about 92%; part additions per accepted edit fell from
164.8 to 3.6. Both builds had zero churn frames over 50 ms. These are single
paired windows on this host, not universal speed guarantees. The after run ended
after a store request: its actual RPC read confirmed 62 owned, 40 placed, 22 stored
at revision 347, explaining the six fewer world parts (214 instead of 220).
The before window ended with 41 placed. No limit/content was removed.

During the final 120 quiet seconds, before/after GUI counts stayed at 180,
placement ghosts stayed zero, and world/animated counts stayed 220/17 and 214/17
respectively. The cached closed placement map explains the 56 GUI descendants
above the initial 124. After client Lua heap was 2,393 -> 1,920 KB (range
1,860–2,870); server Lua heap 866 -> 959 KB (range 725–1,100). Client instance
count was constant 49,136; server count 46,169. Studio-inclusive memory fell
2,377 -> 2,277 MB. No sustained retained-growth defect was demonstrated in this
bounded run. Quiet frame p95/p99 was 18.058/18.364 ms.

## Six actual owners and host contention

Six actual Studio clients occupied all six lots, each initially owning the valid
Garden preset (10 owned, 9 placed, 1 stored). Native server input put each avatar
on the next owner's lot before sampling. Every client then ran ordinary edits
while its camera visited all six properties, including neighbours' changes.
This scene contains **372 world BaseParts / 90 animated parts**. No Showcase
example takes a player slot. See [native observations](perf-01/six-owner-native.txt).

The first stable window ran 17:02:38–17:04:38 UTC; churn ran
17:05:27–17:08:27, followed by 120 seconds quiet. All six clients completed
**240 accepted edits each (1,440 total)**. Each bought five stored lanterns,
ending with **15 owned / 9 placed / 6 stored**, revision 260; visible content
returned to 372/90. Server BasePart additions/removals during churn were
5,922/5,922. Server synchronous reconcile p50/p95/p99/max was
**0.361/1.817/2.722/5.456 ms**, snapshot p95 0.223 ms and transaction p95
0.350 ms. Income accrue p95 was 0.016 ms; invocation spacing p95/max was
1,006.184/1,017.649 ms. These per-call/cadence observations meet the stated
synchronous p95 budgets; they are not a total server-script CPU distribution.

Owner5's viewport was unfocused during that first sample/churn. Its background
frame p95/p99 was 21.439/25.527 ms stable and 21.623/26.617 ms churn; its 240
ordinary edit round trips measured p50/p95/p99 34.077/53.713/65.376 ms. Raw
[first-run samples](perf-01/six-owners-after.jsonl) preserve all six clients.
These are not foreground editing-frame passes. No visible-hitch judgment is
inferred from an unfocused viewport or the other clients' ambiguous flags.

A repeat in the same post-churn session used a verified foreground owner5 game
viewport, the same 801 × 413 camera size and unchanged 372/90 scene geometry.
Warm-up started 17:14:36; stable ran **17:15:06–17:17:06 UTC**. Its **7,196
foreground frames** measured p50/p95/p99/max **16.628/20.647/23.750/78.579 ms**;
one frame exceeded 50 ms (**0.0139%**). The **20 ms p95 budget missed** by
0.647 ms; p99 and spike rate passed. This is a six-process local Studio result
on a four-core host, not a target-device result. The repeat made no edits and
retained the five extra stored lanterns per owner. See
[foreground summary](perf-01/six-owners-foreground-summary.json).

During first-run quiet, every client's GUI count stayed 124 with zero ghosts;
each client and server instance count was constant. Client script-VM heaps
cycled within roughly 1,966–3,017 KB, and server heap within 808–1,186 KB.
The foreground repeat kept those counts constant, with owner5 heap
2,174 -> 2,053 KB (range 2,005–2,981), server 966 -> 812 KB. No sustained
retained growth was demonstrated. Multi-process Stats totals represent each
process's observed residency, affected by paging; they are not comparable to
F5's editor-plus-simulations total. Zero server memory tags are not proof of a
zero heap. The measured script-VM heap is kept separate.

Five-second server Stats.DataSendKbps observations increased from quiet mean
0.648 to churn mean **7.852** (range 1.892–15.931), in the engine field's
exposed units. Stats.DataReceiveKbps remained zero even with accepted RPCs;
that zero cannot establish absent traffic or a reliable receive-rate budget.
The local memory checkpoint wrapper across the exported session measured
p95/max **0.907/1.544 ms**;
serialized checkpoint records grew from 985 to 1,345 bytes. Record size is
neither replicated snapshot size nor measured wire bytes, and memory-backend
work is not DataStore latency. The exporter retains the underlying observations.

The final single-client control uses the same all-Garden 372/90 visible scene;
five properties are explicitly labelled synthetic. Its owners have the initial
10-object preset, so it isolates geometry/process pressure without claiming
identical stored inventories, avatars, palettes or server/client work. The
earlier mixed-preset baseline (332/76) is kept distinct above.

That matched control's stable window ran **17:32:35–17:34:35 UTC** and collected
7,201 foreground frames: p50/p95/p99/max **16.834/18.080/18.770/28.996 ms**,
zero over 50 ms. All provisional frame budgets passed. Sparse client render
CPU/GPU means were 5.127/3.600 ms. GUI stayed 124, ghosts zero, world 372/90,
and client instances constant at 49,293. Compared with this control, the verified
six-owner p95 is 2.567 ms higher. Additional processes/avatars/real publishers
compete on the same four-core host, so this difference alone does not identify a
game-code defect or support disabling effects. See the
[matched summary](perf-01/developed-matched-after-summary.json).

## Native interaction and lifecycle observations

Separate detailed captures used the desktop viewport after timed sampling, with
1 kHz Script Profiler sampling, Live off and GC overhead off. The
[client export](perf-01/dense-client-scriptprofiler.json) covers 37.980 seconds;
PropertyActivity's callback has 40.100 ms inclusive sampled duration, Hud.update
43.780 ms and HudView.resize 39.753 ms. Nested durations must not be summed. This
does not demonstrate an animation bottleneck. The
[server export](perf-01/dense-server-scriptprofiler.json) covers 47.798 seconds,
with 29.672 ms total sampled script duration; short functions are sparsely sampled
at 1 kHz, so the synchronous wrappers establish per-call costs. A separate native
64-frame [MicroProfiler dump](perf-01/dense-microprofile.zip) preserves engine
task detail. Unzip and open `dense-microprofile.html`; the archive preserves the
native export byte for byte. These short captures are diagnostic context, not the timed frame
distributions. The profiler was stopped/hidden afterward.

Outside the timed windows, desktop wheel input reached the bottom of the full
62-item Arrange list; [`dense-arrange-bottom.png`](perf-01/dense-arrange-bottom.png)
shows stored lanterns and the final equipment. The phone emulator's automated
wheel/drag attempt did not establish touch scrolling; physical touch comfort
remains unobserved. Selecting a discovery rendered its viewport model, and an
ordinary attempted 49th decoration was rejected with the expected capacity
message ([capture](perf-01/dense-capacity.png)). Placement-map close cleared the
local ghost. Forty-six churn cycles created/destroyed their own editors.

An actual-client LocalScript observation confirmed visible spin stops with the
native reduced-motion setting On, resumes Off, stops after HUD destruction and
resumes after Hud.start. The setting was restored Off. A direct command-bar
require saw a separate preference state, so that preliminary assertion was
discarded; the successful observation ran in the real client script environment.
Respawn preserved the property. Native Modes -> Return exercised the explicit
late-failure adapter; reacquisition retained all 62 belongings, 40 placed and
revision 347, with a new epoch ([recovery](perf-01/dense-return-recovered.png)).
The local adapter does not establish real teleport or DataStore durability.

Closing actual owner5 detached all 12 upgrade/ground instances and 53 BaseParts,
cleared PropertyRevision and left the lot empty. Retained test references had
nil parents and unchanged server frames after 0.6 seconds. Adding a replacement
through Studio unexpectedly launched five windows despite the edited count;
the server reported ten connected clients, of which six could own lots. This
happened **after all timed six-owner windows** and is excluded from them. A
replacement lot assertion could not execute during input/capture timeouts;
native post-arrival reuse is **unverified**, while the engine regression suite
passed lot reuse. The parent Test -> End Session control stopped all child
windows normally. No unrelated process was killed.

## Validation

`Validate-Project.ps1` passed on the repaired source: pinned formatting, lint,
Luau analysis and deliberate-failure probes, fresh build/sourcemap, authored-map
contract, exact source/production exclusion and all preview boundaries. The
performance builder adds two small boundary-check builds to this existing suite.

Studio executed PropertyRendering's identity, recolor, storage/re-place and lot
reuse regressions, including fresh-model palette equivalence for every catalogue
silhouette. The existing Property, Growth, Persistence, ProfileLifecycle,
InfiniteState, Routing, Handoff, Session and SupplyEvent suites also passed.
[`final-server-execution.txt`](perf-01/final-server-execution.txt) contains the
actual engine results; duplicate historical suite executions are not new coverage.

Final CLI validation also passed after the control-only fixture change at
`91a81b6`; the production regression execution is from `3273428`, whose runtime
source is unchanged. [Build hashes](perf-01/builds.txt) identify the observed
files, including generated QA files subsequently regenerated by validation.

## Playable review and remaining observations

```powershell
./scripts/New-ModeReviewPlace.ps1 -Role Infinite -Showcase -OutputName mode-infinite-perf-review.rbxlx
```

Open `build/mode-infinite-perf-review.rbxlx` in Studio and Play. This gameplay-only
preview uses explicit local memory and the late-failure mode adapter, two labelled
showcase examples and four actual player slots. It contains no performance probes
or QA assertion runners. Stop resets memory; keep this generated file local.
The delivered file reached Ready in native Play, earned cash at the initial
1/sec rate, opened My place and rendered the Seed nursery discovery model
([capture](perf-01/gameplay-preview.png)). Its exact repaired modules, unchanged
authored geometry and lack of PERF/QA runners were checked. Play was stopped;
the editable preview remains open. Reduced motion is Off, profilers stopped and
quality Automatic; no hosted settings were changed.

Measured passes: dense before/after foreground frame budgets, repaired reconcile
and snapshot p95, simultaneous six-owner edit processing, bounded editor/world
cleanup, native departure destruction, reduced-motion/activity stop/restart and
local failed-return recovery. Observed failure: the verified six-owner stable
frame p95 is 20.647 ms against 20 ms. Its p99/spike rate pass. Do not describe
this as an all-performance-checks pass or attribute that miss to a specific
script without supporting measurements.

Unobserved: native post-arrival lot reuse after the Studio input failure,
foreground six-owner edit-frame timing, a reliable receive-wire rate, configured
frame cap, physical touch/controller comfort and device CPU/thermal behavior,
real DataStore durability/cross-server teleport arrival, and founder style/pacing
approval. Engine lot reuse regressions passed separately. The bounded local pass
does not justify changing validation, earnings, capacity, effects or gameplay.
Hardware certification follows Roblox's [hardware-test guidance](https://create.roblox.com/docs/performance-optimization/test-on-hardware).
