# Combined Infinite and mode-entry review

Latest performance follow-up: [PERF-02](PERF_02_REVIEW.md) retains two clean
six-owner repeats and three separate native captures. Both repeats pass frame
p95/p99 and server/edit-latency references, but one misses the >50 ms rate
(13/10,750 = 0.1209%, max 192.175 ms). The captures contain no representative
hitch; its cause and PERF-01's 314 ms hitch remain unresolved. Changes are confined
to fixtures, evidence and offline tooling; #25's production game is preserved.
Keep the entire gameplay stack draft for combined founder review. Physical devices,
real services, subjective pacing and performance sign-off remain distinct.

The latest probe-free playable copy is `build/mode-infinite-perf-02-review.rbxlx`:

```powershell
./scripts/New-ModeReviewPlace.ps1 -Role Infinite -Showcase -OutputName mode-infinite-perf-02-review.rbxlx
```

Open and Play. It uses local reset-on-Stop memory and two labelled examples, with
no performance controls or QA runners. PERF-02 records its native Ready/isolation
check and screenshot. Review Entry/Session using the commands below.

MODE-01 is stacked on INF-03 #22 at tested head `bc18ef0b66bac9cab403835bdac2355ba4ce8100`, inheriting INF-02 #21 and INF-01 #18. [MODE-01-only comparison](https://github.com/lillo24/roblox_tycoon/compare/bc18ef0b66bac9cab403835bdac2355ba4ce8100...codex/mode-01-entry-routing). Keep the complete gameplay stack draft for one founder review. Experiments #14–#16 are separate.

## Local playable review

Run these in this branch with the pinned Rokit tools on PATH:

```powershell
./scripts/New-ModeReviewPlace.ps1 -Role Entry -IncludeQA
./scripts/New-ModeReviewPlace.ps1 -Role Prototype -IncludeQA -Scenario ImmediateFailure
./scripts/New-ModeReviewPlace.ps1 -Role Infinite -IncludeQA -Showcase -OutputName mode-infinite-review.rbxlx
```

Open `build/mode-entry.rbxlx`, `build/mode-session.rbxlx` and `build/mode-infinite-review.rbxlx` separately in Studio. Play each. Entry has the responsive chooser; its explicit local adapter exercises Joining and a recoverable late failure. Session demonstrates immediate failure using Modes → Return. The adapter names the default destination file; use `mode-infinite-review.rbxlx` for the inspected Infinite copy here. It does not teleport or switch everybody in one server. Omit IncludeQA for gameplay-only copies. Infinite's two labelled examples leave four player lots; omit Showcase for six player lots.

A coherent review path:

1. Choose Infinite in entry; read the joining/failure status, retry Session and inspect the narrow/mobile layout.
2. Open Infinite. A real owner starts at zero. My place → Discover offers garden, ceramics and sky paths. Buy a 12-cash first machine, select it in Arrange, preview on the map, rotate and confirm. Storage keeps income; experiments are reversible and no contest/reset interrupts you.
3. Buy the matching 90-cash equipment and the 220-cash rear garden. Visit the Glass Garden and Sky Workshop examples, then combine paths, decorations and a palette. The finite catalogue has 22 discoveries, not infinite authored content. Earlier investments remain present. See INF_03_REVIEW for pacing estimates and content policy.
4. Open Modes → Return from Infinite. The local late-failure adapter exercises freeze, confirmed memory checkpoint/release and current-data reacquisition. Resume using Stay. These operations use the same lifecycle as production, with an explicit memory backend that resets on Stop.
5. Open Session. Buy its existing upgrades on the owner pads and join Supply Cache. Returning to entry has no Infinite saving effects and does not promise Session persistence.

## Handoff contract and limits

Intentional departure freezes accepted property edits, all credits and income before the final snapshot. It waits behind the entire previous autosave, confirms a final checkpoint and releases the writer lease before calling teleport. PlayerRemoving cannot queue a later stale source save. The confirmation deadline is 25 seconds; an in-flight service call cannot be cancelled. A late confirmation cannot start a teleport. A hung call leaves the source explicitly paused until it resolves or the player leaves.

An immediate or later teleport failure attempts to reacquire current stored data with a new token. It never resumes a released handle, replays a cached layout over the destination or force-expires a writer. Busy/foreign/invalid/missing profiles remain unavailable, with bounded reload controls. An existing profile disappearing during recovery cannot create defaults. Full arrivals can return to entry or retry loading after capacity frees. No seats are reserved across servers; a destination may still fill before arrival.

A failed pre-departure write is **unconfirmed**, and recovery may expose only the last confirmed checkpoint. Successful local adapter tests do not establish real DataStore durability. The existing crash-loss window remains: autosave every 30 seconds, lease 120 seconds with a 15-second safety margin, four ordered service attempts and bounded shutdown work. No zero-loss crash claim.

A recovery call still pending after 45 seconds shows an explicit unconfirmed/paused warning. It cannot start a competing reload; its eventual result is fenced by the recovery generation, even after that warning changes the visible status revision.

## Later isolated published test

No destinations were supplied or created; no publication or hosted settings were changed. Use a **separate test experience**, with an Entry start place and two ordinary public gameplay places. Copy the same source and Routing/Settings manifest to all three: enable it, set that experience's UniverseId and its actual Entry/Prototype/Infinite PlaceIds. They must be positive, distinct and members of that experience. AppRuntime verifies membership through AssetService before gameplay starts. A misconfigured source or destination fails visibly; client choices and teleport data cannot assign roles.

Use a maximum of six players for each gameplay place, matching authored lots; entry can also use six for a simple first test. No private/reserved server is created per player. With Fully open destination access, direct/friend joins can enter either dedicated gameplay place; startup therefore needs no chooser payload. If access is changed to Secure within universe only, verify Roblox's entry redirect and friend-join behavior as part of the hosted test rather than assuming direct entry. Keep the manifest identical when publishing destinations.

DataStore scope is the experience, not the place. Infinite retains `InfiniteProfiles_v1` and `user_<UserId>` in the default scope. Changing place IDs does not isolate or reset data. Studio real-store tests additionally require Persistence/Settings.StudioTestUniverseId to match that isolated experience; zero stays disabled here. Do not enable Studio access against live player data or publish any local preview fixture.

Observe in the published Roblox client: entry → both public destinations; direct/friend arrival; Infinite changes → Entry → Infinite restore; departure while an autosave is in flight; failed teleport and retry; destination arrival before source cleanup; two concurrent attempts for one account; full lobby return; service failure without a default profile. Record place IDs, revision, account-safe evidence and actual outcomes. A TeleportAsync return alone is not arrival evidence.

Sources rechecked 2026-10-09: [teleport behavior and Studio limits](https://create.roblox.com/docs/projects/teleport), [DataStore experience scope](https://create.roblox.com/docs/cloud-services/data-stores), [ordered writes and session ownership](https://create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing), [place membership API](https://create.roblox.com/docs/reference/engine/classes/AssetService#GetGamePlacesAsync).

## Evidence status

`Validate-Project.ps1` passed with the pinned toolchain: formatting, lint, Luau analysis and deliberate-failure probes, fresh build/sourcemap, source ownership, serialized map and all preview boundaries. Canonical map and Session catalogue remain unchanged.

The final Infinite review build executed **1,075 distinct server assertions**: Routing 35, Handoff 35, Property 246, Growth 296, Persistence 46, ProfileLifecycle 21, InfiniteState 14, Session 186 and SupplyEvent 196. The helper also repeats the last two regression suites; those repetitions are not added to the total. See `mode-01/final-server-execution.txt`.

Two actual Studio clients each passed 6 calm, 3 mode-isolation, 1 late-animation-metadata and 1 modal-clearance assertion. Native command-bar observations additionally verified separate player inventories, rejection of a foreign-plot edit, an earned nursery purchase/placement, replication to the other client, and uninterrupted neighbour income/writer/mode during one player's return attempt. See `mode-01/two-client-execution.txt`. This is two clients, not a six-client performance claim.

Observed iPhone XR landscape and portrait: discovery preview, ordinary-earnings purchase, placement map and Confirm; Modes → Joining → local late failure → Ready recovery. The placed nursery and cash survived, and the editor epoch changed after reacquisition. Screenshots and sanitized execution output are under `mode-01/`. The final editor screenshot includes the fix hiding Modes while My place is open. Desktop and portrait entry choices and late failure were also observed. Local adapter calls are not real teleports.

The final Entry client passed five isolation assertions and one injected late-startup UI assertion: an Unavailable client with a subsequently ready routing service receives an explicit rejoin instruction. This exercises the recovery branch, not a real delayed network startup. Selecting Infinite after scrolling on iPhone XR landscape brought Joining into view, then restored usable choices after the local late failure. See `mode-01/entry-execution.txt` and the joining/failure screenshots.

Session passed five isolation and one modal-clearance assertion. An actual native purchase prompt spent earned cash and built Income Booster (+2/sec); Supply Cache remained active. Modes → Return exercised the immediate-failure adapter and left Session available. See `mode-01/session-execution.txt` and its purchase/return screenshots. `mode-01/builds.txt` records the inspected and delivered preview hashes.

Physical touch/controller comfort, six simultaneous clients on target devices, real cross-server saving/teleports, and the founder's combined style/pacing judgment remain distinct follow-ups. No historical unobserved QA is marked passed by this slice. Studio hit a resource warning with earlier generated previews open; closing those copies and reconnecting the UI tool allowed the final two-client test to run.

## PERF-01 follow-up on the same draft stack

[PERF-01 review](PERF_01_REVIEW.md) records actual one-client and six-owner Studio
windows, dense inventories, simultaneous edits, quiet cleanup and native profiles.
Dense reconcile p95 fell from 10.421 to 0.797 ms by retaining unchanged geometry;
saved data, validation, income and Session behavior are preserved. Six actual
owners completed 1,440 accepted edits. Verified foreground six-owner stable frame
p95 was 20.647 ms, slightly above the provisional 20 ms desktop budget; this is
recorded as a miss. A separate verified foreground six-owner edit run recorded
21.518 ms churn p95 and 0.168% >50 ms spikes, also above the provisional references;
edit latency and reconcile/snapshot p95 passed. Native departure cleared its
objects/revision, and a single replacement owner reached Ready on the same lot
with fresh geometry and its own 10-object profile at revision 20. This closes
the earlier native post-arrival reuse gap. Physical devices and real services
remain follow-ups, along with the founder's combined style/pacing review.

The refreshed gameplay-only Infinite preview is reproduced with:

```powershell
./scripts/New-ModeReviewPlace.ps1 -Role Infinite -Showcase -OutputName mode-infinite-perf-review.rbxlx
```

Open `build/mode-infinite-perf-review.rbxlx` and Play. It uses local reset-on-Stop
memory and a failed-return adapter, with two labelled examples and four player
lots. It includes no PERF probes or QA runners. Do not publish this local fixture.
