# INF-01 review — persistent personal space

Status: **draft for owner review; no publication or gameplay merge authorized**.
PR #11 was reconciled with main, validated locally and by required CI, then merged
with explicit owner authorization on 2026-10-09 as `36a5caa`. This isolated branch
starts there. Experiments #14, #15 and #16 remain separate. The brief's obsolete
unmerged-#11 starting point was replaced; its scope and evidence gates remain.

## Play locally

Run `./scripts/New-InfiniteReviewPlace.ps1`, open `build/inf-review.rbxlx` in Studio,
then Play. For multiplayer, select **Server & Clients**, set two clients before
starting, then start. Each player receives a ready lot, earns online, and can walk
to its pads or visit another player's lot. Factory / Find my factory, Help and
existing session preferences remain available.

The default preview explicitly uses temporary memory storage. Its HUD says
**Local preview • changes last only this server**. Stop clears that storage. This
preview is playable but is **not proof of persistence across real sessions**.
The four existing upgrades remain the entire first slice; there is no forced
reset, winner, offline income, SupplyCache event or new progression catalogue.

Handoff preview SHA256:
`08D208355303F104F42F9D47AE7996562C880D5252455F5B902F5EEC5C0DC3D1`.

`-Backend DataStore -OutputName inf-datastore.rbxlx` builds the real bootstrap path.
Without an isolated published universe it reports Unavailable and grants no
economy. See [setup, save format and failure policy](../src/server/Persistence/README.md).
Do not turn on production Studio API access to make this preview work.

## Observed evidence — 2026-10-09

Studio version **0.742.0.7421053**. The final production sources were verified in
the opened QA scene: all **28 source texts and classes** matched normalized
working-tree sources. The authored `place/tycoon.rbxlx` remains unchanged, SHA256
`9D6A9FE65A25E0C1D8CF6FA4FE7D4E582EA234FF618DC758BC71FD4675C9F8E8`.

| Gate | Observed result / limit |
| --- | --- |
| Standard command-line validation | `./scripts/Validate-Project.ps1` passed: formatting, lint, fresh Rojo build/sourcemap, strict Luau analysis/failure probes, ownership/scene/ignore checks and all preview boundaries. CLI does not execute engine suites. |
| Engine domain/lifecycle regressions | **460 assertions**: Persistence 46, ProfileLifecycle 21, InfiniteState 11, existing Session 186 and SupplyEvent 196. New-account confirmation, invalid/failed loads, returning cash/assets, a different lot, trusted income, swapped placement slots, contested/expired writers, ambiguous responses, serialized final saves, delayed arrivals, capacity, reuse and shutdown. Explicit serialized memory backend, not a real service. |
| Actual map restoration | **66 assertions** in Edit: two saved assets restored into swapped slots on all six rotated lots; exact local positions/orientations; departure clears equipment/owner and disables all four prompts. Temporary geometry removed afterward. |
| Actual client startup | Two simultaneous clients plus the replacement client each passed **6 assertions** after 11 seconds: Ready, Persistence label present, Event label/state/feedback/world absent. |
| Owner / visitor purchase | Player2 used Player1's native purchase prompt: “Not your plot”; neither acquired the asset and owner equipment stayed empty. Player1 used the same native prompt successfully: Income Booster created, income 2. No purchase remote or direct Session call in these attempts. |
| Visiting and departure | Owner moved to the second property; online income continued. Actual owner disconnect cleared identity/equipment and disabled four prompts. |
| Lot reuse | A newly added Player3 received lot 1 with its own initial cash, no assets and income 1; a delayed observation confirmed no old-owner mutation. |
| Real bootstrap without destination | In the disposable QA scene, disabled the explicit preview/QA runners and enabled the normal bootstrap. Actual client showed Unavailable, no cash/lot/owner, and no Event HUD. The unpublished-place guard prevents a DataStore call; this tests refusal, not real network failure/durability. |
| Ordinary Prototype regression | Selected Prototype before startup with the normal bootstrap. Actual client had Assigned status, increasing cash, Event HUD, event state/feedback and SupplyCache world; no Persistence widget. |
| Mobile rendering / native controls | Final gameplay-only preview in native iPhone XR simulation: Standard/Large landscape and portrait; saving notice retained both lines, Settings size toggles and Help/Close accepted native taps. Portrait Help copy wrapped within its panel. A synthetic client-only save-failure message remained fully visible in landscape. No swipe or physical-device performance pass claimed. |

Native prompt clicks were actual client input. Server command-bar positioning
fixtures moved the avatars to pads; these checks do not establish walking usability.
The owner was disconnected with a disposable test kick, then one replacement client
was added through Studio controls. Assertions were read from actual engine output.

- [Sanitized engine execution](inf-01/studio-execution.txt)
- [Visitor rejection](inf-01/visitor-rejected.jpg)
- [Owner purchase](inf-01/owner-purchase.jpg)
- [New occupant of lot 1](inf-01/lot-reuse.jpg)
- [Real path refuses unavailable saving](inf-01/unavailable.jpg)
- [Ordinary Prototype with SupplyCache](inf-01/prototype.jpg)
- [Landscape Standard](inf-01/mobile-landscape.jpg) / [Large](inf-01/mobile-landscape-large.jpg)
- [Portrait Large settings](inf-01/mobile-portrait-large.jpg) / [Standard Help](inf-01/mobile-portrait-help.jpg)
- [Synthetic save-failure copy, landscape](inf-01/mobile-save-failure-fixture.jpg)

Portrait used a temporary client-only `PlayerGui.ScreenOrientation` fixture;
the saved orientation is unchanged. The save-failure screenshot tests copy/layout
with a client attribute fixture, not a failed real DataStore operation. Stop removes
both fixtures. The real-source playable preview has no automatic QA runners.

## Reproduce the engine checks

1. Build `./scripts/New-InfiniteReviewPlace.ps1 -IncludeQA -OutputName inf-qa.rbxlx`.
2. Open it in Edit. Run `print(require(game.ServerScriptService.INF01Preview.PropertyWorld)())`
   in the command bar: expect 66 and no remaining TycoonRuntime geometry.
3. Select Server & Clients with two clients. Play executes the five domain suites;
   each client automatically observes the calm-mode startup after 11 seconds.
4. Visit another lot and use an unowned purchase prompt; confirm rejection and
   unchanged assets. Use the owner's same prompt and confirm cash/income/equipment.
5. Disconnect the owner, inspect vacant ownership/equipment/prompts, then use
   Studio's Add Clients dropdown with one client. Confirm the new account's state.

Fault-injection suites intentionally log expired final-save warnings for fixture
accounts. Those warnings are expected failure evidence, not claims of successful
writes. One preliminary zero-client server ended when calling AddPlayers through
the command bar; the recorded multiplayer run used native launch/add controls.

## Remaining review gates — not passed

**Real Roblox durability is unexecuted.** No isolated published test destination
was supplied or found in the repository, and publication is explicitly outside
this task's authorization. `StudioTestUniverseId` remains 0. An owner must supply
the isolated experience and enable its Studio API access before this gate can run.

In that isolated experience, record successful real writes and rejoin from a new
server with the same account: preserve cash/assets/placements on a different lot,
derive the same income, and apply no offline earnings. Exercise overlapping server
loads, rapid rejoin during final save, shutdown, service failures and stale-writer
rejection against the real service. Record the universe/place, revisions and
observed confirmations. Injected memory tests above do not replace these checks.

The existing [PR #11 manual QA follow-ups](UX_02_REVIEW.md) remain explicitly scoped
there. This task does not claim a physical-device performance pass, a successful
touch swipe to Reset, controller walking behavior, or the outstanding shared-event
contest/touch-claim checks. Those event checks concern Prototype, not Infinite.

Review the new mode's copy, lease/recovery policy and crash-loss tradeoff before
changing the draft status. Healthy crash loss is approximately the 30-second
checkpoint interval plus service latency; during an outage it can include all
changes since the last confirmed checkpoint. A purchase alone is not a confirmed
persistent write. Nothing in this branch publishes the game or merges an experiment.
