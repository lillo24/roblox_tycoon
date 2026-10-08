# UX-02 combined prototype checkpoint

Implementation ready for consolidated QA once the execution results below are
recorded. This draft deliberately combines pending MAP-01/PR #8 and UI-01/PR #9
with the bounded UX-02 batch. Source drafts remain open and unchanged. This is
the current approval/consolidation checkpoint; historical source packets do not
provide approval of the combined build. No deployment or publication is authorized.

## Provenance

| Source | Exact revision |
| --- | --- |
| Current main, including the UX-02 plan | `2128f69` (full SHA recorded in Git ancestry) |
| MAP-01 incorporated head | `56fb72feb538add13a863e6b4eef2f970fa9bba8` |
| UI-01 incorporated head | `33b7f5ac46ed6e968c7ec23b8eb18352b3a6736f` |
| Ancestry-preserving integration merge | `0ac574af850a9c7e4f50e43a11406d2c9b10f92a` |
| UX implementation/source head | Pending recording after source commit |
| Final draft/evidence head | The PR head; later evidence-only commits do not change tested source |
| Scene | `place/tycoon.rbxlx`, unchanged from incorporated MAP-01 |
| Scene SHA256 | `9D6A9FE65A25E0C1D8CF6FA4FE7D4E582EA234FF618DC758BC71FD4675C9F8E8` |

Integration resolved the two overlapping changes by retaining UI-01's final
modular HUD and long-message layout, plus MAP-01's six-lot contracts and current
source directions. Server/shared code, FIX-01 SupplyFeedback, mappings, tool pins,
economy, event cadence/reward and scene geometry are identical to their source heads.

## One local preview

Checkout:
`C:\Users\utente\.codex\worktrees\ux-02-integrated-player-basics\roblox_tycoon`

Actual disposable file:
`C:\Users\utente\.codex\worktrees\ux-02-integrated-player-basics\roblox_tycoon\build\ui-review-ux-02.rbxlx`

From this checkout (installed pinned tools must be on PATH):

```powershell
$env:PATH = "$env:USERPROFILE\.rokit\bin;$env:PATH"
./scripts/Validate-Project.ps1
./scripts/New-UiReviewPlace.ps1 -OutputName ui-review-ux-02.rbxlx
```

Open that exact generated file in Studio and start a single-client Play session.
The helper replaces only the three reserved code folders using a fresh Rojo build;
saved Workspace geometry is preserved. Never save Play or build over the canonical
scene. Generated XML omits Studio's unsupported declaration. Server-side preview
tests print executed counts. Opt-in real client tests use the actual LocalScript
module cache; in the Play-client command bar:

```lua
local runner = game.ReplicatedStorage.UI01ClientQA.RunClientAssertions:Clone()
runner.Parent = game.Players.LocalPlayer.PlayerScripts
```

Run in a non-idle Supply phase. Keep the runner until Stop Play so recreated-HUD
connections stay alive. It executes lifecycle, FIX-01 ordering and UX readiness
checks. The readiness fixture temporarily holds/replaces event state locally for
the real ten-second timeout; it does not mutate server cash or purchases. Expected
unavailable diagnostics from negative fixtures are labelled by their object paths.
Optional synthetic long-text checks retain `RunDisplayFixture`; they are display
fixtures, not gameplay proof. Stop only this preview's Play session when finished.

## Implemented behavior

- Factory → Find my factory closes the panel and shows one temporary local entrance
  marker plus an offscreen-capable camera-relative direction/distance cue. Ownership
  is cross-checked from replicated runtime PlotId/OwnerUserId; anchors come from the
  saved lot contract. Stop, arrival, assignment/ownership loss, target loss and HUD
  teardown remove it. Missing anchors locate, time out visibly and recover later.
- A small dismissible first-purchase hint reads actual purchase attributes. Any valid
  first upgrade completes it; completion/dismissal persist in the client session.
  Help explicitly reopens guidance. Reset interface settings changes only preferences.
  Optional hints pause for open panels, unusable assignments and priority feedback.
- The basic shell remains usable while feedback/event dependencies are pending or
  unavailable. One ten-second wait deadline produces a concise unavailable message
  plus actionable developer diagnostics. Ordered owned listeners recover late or
  replacement dependencies. Known cash remains independent of event readiness.
  Invalid classes/duplicates/JSON/contracts are diagnosed; internal errors still fail.
- Native Activated, selection links, Close/Back, one-panel behavior, prompt gating,
  safe-area layout, reduced motion and scoped ambient labels are retained.

## Execution record

| Check | Current result |
| --- | --- |
| Complete local Validate-Project | Passed on the integrated source before the final documentation commit; final run recorded below |
| Scene hash; MAP server/shared; FIX-01 unchanged | Passed byte/source comparisons |
| PlayerGuidance engine suite | Not run yet |
| Real HUD lifecycle/ordering/readiness suites | Not run yet |
| Single-client combined smoke | Not run yet |
| Exact final draft-head CI | Pending PR creation |

CLI formatting, lint, type analysis and XML checks do not execute Luau. Runtime
results must be recorded separately with source revision and fixture limitations.

## Consolidated QA to run later

| Area | Status and required observation |
| --- | --- |
| Map scale/spacing/factory feel, sightlines and label density | **User review pending.** Walk the combined six-lot map; inspect neighboring/opposite growth. MAP-01 images are inherited evidence at its source head. |
| Combined assignment/readiness/first purchase | **Not run as general QA.** Locate your own factory, allow real income, buy any available first upgrade, observe authoritative completion and dismiss/reopen from Help. |
| Two-client isolation and public event | **Environment blocked historically.** UI-01 attempts hit Roblox profile-service HTTP 429/capture failures. Compare requester-only results, local preferences/hints/targets and identical public winners on this chosen QA head. |
| Supported touch swipe | **Not run.** Require actual CanvasPosition change, reachable lower content/Reset/Close and no world activation behind a panel. Earlier Touch events alone were insufficient. |
| Full controller traversal | **Not run.** Traverse directions, activate all new/existing controls, scroll, Close/B and focus return, then native Start. Earlier A/B is inherited partial evidence. |
| Portrait/landscape Standard/Large | **Not run at combined head.** Check native chat/menu/safe areas/jump controls, long balances/results, closed-panel hints and target/offscreen cue. UI-01 layout captures are inherited evidence only. |
| Respawn/HUD recreation/delayed or absent state | **Focused fixtures plus general QA pending.** Check one HUD/marker, retained settings/completion/dismissal, recovery and no stale feedback. |
| Full/assignment loss/replacement | **General QA pending.** No waiting-queue promise, no old purchases/results/targets; no state/preferences leak to another client. |
| Gameplay regression and clean-checkout restore | **Not run at the eventual chosen QA head.** Rebuild from clean Git source, verify loaded code/scene hash, real purchases/claims and stop/restart. MAP-01's six-client/restore runs remain historical. |
| Physical performance/input | **Not run; hardware required.** Emulator screenshots are not physical-device benchmarks. |
| Hosted maximum 6 | **Pre-publication setting pending.** Client/config code does not change hosted capacity. |

Keep statuses explicit: passed at SHA, inherited evidence, not run, environment
blocked, confirmed failure or user review pending. This task prepares this one
checkpoint, deferring the full matrix without marking it passed. After general
QA/visual approval, reconcile latest main, rerun affected checks and choose one
final combined merge/consolidation path. Do not merge or close #8/#9 beforehand.

## Historical evidence

- [MAP-01 scene, gameplay and restore packet](../place/MAP_01_REVIEW.md).
- [UI-01 exact-source captures and partial/blocked input QA](UI_01_REVIEW.md).
- [UX-02 implementation requirements](../history-implementations/UX_02_INTEGRATED_PLAYER_BASICS.md).

Retain this draft checkout/preview and the two source review worktrees/backups.
Do not delete unrelated or previously blocked artifacts. The current task's
single-client smoke will be stopped at handoff; unrelated sessions stay intact.
