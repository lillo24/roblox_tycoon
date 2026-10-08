# UX-02 combined prototype checkpoint

**QA-01 incomplete: CLI and preview preparation passed; current-head Studio execution is environment blocked.**
This draft deliberately combines pending MAP-01/PR #8 and UI-01/PR #9
with the bounded UX-02 batch. Source drafts remain open and unchanged. This is
the current approval/consolidation checkpoint; historical source packets do not
provide approval of the combined build. No deployment or publication is authorized.

## Provenance

| Source | Exact revision |
| --- | --- |
| Current main, including QA-01 | `2c2f04decc1a2ff1015464bf3e07e2d5de1627db` |
| MAP-01 incorporated head | `56fb72feb538add13a863e6b4eef2f970fa9bba8` |
| UI-01 incorporated head | `33b7f5ac46ed6e968c7ec23b8eb18352b3a6736f` |
| Ancestry-preserving integration merge | `0ac574af850a9c7e4f50e43a11406d2c9b10f92a` |
| UX implementation/source head | `17fe09f583b5a4db15d984129de9ca5d7010419d` |
| QA-01 main reconciliation | `211ce37349ec6bfec2757c2dcc76de9153148f99` |
| QA-01 preview/validation preparation | `ddffadad13c8efaf206db13cf6ac1751fda7c78c` |
| Final draft/evidence head | The PR head; later evidence-only commits do not change tested source |
| Scene | `place/tycoon.rbxlx`, unchanged from incorporated MAP-01 |
| Scene SHA256 | `9D6A9FE65A25E0C1D8CF6FA4FE7D4E582EA234FF618DC758BC71FD4675C9F8E8` |

Integration resolved the two overlapping changes by retaining UI-01's final
modular HUD and long-message layout, plus MAP-01's six-lot contracts and current
source directions. Server/shared code, FIX-01 SupplyFeedback, mappings, tool pins,
economy, event cadence/reward and scene geometry are identical to their source heads.

## Current preview and exact preparation

Checkout:
`C:\Users\utente\.codex\worktrees\ux-02-integrated-player-basics\roblox_tycoon`

QA copy (automatic server assertions, opt-in client/display fixtures):
`C:\Users\utente\.codex\worktrees\ux-02-integrated-player-basics\roblox_tycoon\build\ui-review-qa-01.rbxlx`

Gameplay-only founder copy (no QA folders/remotes, assertion runners or display fixtures):
`C:\Users\utente\.codex\worktrees\ux-02-integrated-player-basics\roblox_tycoon\build\ui-review-founder.rbxlx`

From this checkout (installed pinned tools must be on PATH):

```powershell
$env:PATH = "$env:USERPROFILE\.rokit\bin;$env:PATH"
./scripts/Validate-Project.ps1
./scripts/New-UiReviewPlace.ps1 -OutputName ui-review-qa-01.rbxlx
./scripts/New-UiReviewPlace.ps1 -OutputName ui-review-founder.rbxlx -GameplayOnly
```

Open the QA copy for execution; use the gameplay-only copy for normal review.
Both remain generated-file evidence until their loaded Studio sources and viewport
are verified. The default helper retains its existing automatic QA behavior.
The helper replaces only the three reserved code folders using a fresh Rojo build;
saved Workspace geometry is preserved. Never save Play or build over the canonical
scene. Generated XML omits Studio's unsupported declaration. Server-side preview
tests print executed counts for Session, SupplyEvent, SupplyFeedback, UiState,
WorldLabels and PlayerGuidance. Before Play, invoke the Edit-only map route:

```luau
require(game.ServerScriptService.UI01QA.RunMapAssertions)()
```

It invokes the exact MapLayout suite against the saved scene; a guard rejects
Play because that test creates/removes temporary runtime geometry. Opt-in real
client tests use the actual LocalScript
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

## QA-01 execution record (2026-10-08)

Production Luau, tests, mappings, tool pins and canonical scene are unchanged
from `17fe09f`. QA preparation `ddffada` adds complete existing test routes and
the optional gameplay-only switch, with a regression check in full validation.
There is no demonstrated gameplay defect repaired in this pass. Runtime checks
below have **zero current-head executed assertions**, rather than historical totals.

| Check | Method and current result |
| --- | --- |
| Full local CLI | **Passed** with QA-01 helper/validation changes: formatting, lint, build/sourcemap, source/tests analysis, 12 structure probes, 5 negative type probes, six-lot scene contract and 7 negative map probes. Log: `build/qa-01-validation.log`. |
| Preview variants | **Passed** `Test-UiReviewPlace`: both outputs contain exact normalized mapped production sources and canonical Workspace; default contains all ten exact suite sources and correct runner classes; gameplay-only contains none of the QA fixtures; no XML declaration. This is file validation, not Luau execution. |
| Clean-checkout preparation | **Passed** at detached `ddffada`: clean status, full Validate-Project, exact-source preview regeneration and unchanged scene hash. Log: `build/qa-01-clean-validation.log` in the parent integration checkout. **Studio reopen/start/purchase/claim/stop/restart not run**; this does not complete the engine restore gate. |
| Scene/source preservation | **Passed** SHA256 below and Git comparisons of all Luau, scene, mappings and pins against `17fe09f`. Source PR #8/#9 heads remain the recorded incorporated SHAs. |
| Session / SupplyEvent / SupplyFeedback / UiState / WorldLabels / PlayerGuidance | **Not run at the combined head**; automatic server route prepared, no usable current preview. |
| MapLayout | **Not run at the combined head**; exact Edit-only route prepared. |
| HUD lifecycle / ordering / readiness | **Not run at the combined head**; actual LocalScript route retained, including real ten-second readiness fixture. |
| Normal desktop, touch swipe, full controller traversal and phone Standard/Large | **Environment blocked** before a current-source viewport; no normal inputs credited. Earlier UI evidence is inherited at its own revisions. |
| Two/six live clients, private state/shared contest/disconnect/reuse | **Not run at the combined head**; the preexisting old two-client session cannot establish coverage. Seven-user domain coverage also awaits actual Session/SupplyEvent execution here. |
| New combined screenshots | **Not captured**; old map/UI images remain inherited evidence, not images of this build. |
| CI | **Passed** full Validate at QA packet head `e84f4787293e15d15ebcfc2b4e5a3097147f83a4`: [run 37773551739](https://github.com/lillo24/roblox_tycoon/actions/runs/37773551739), job `113298730966`, including the new preview regression check. Later evidence-only commits leave validated source/tooling unchanged; the [current PR checks](https://github.com/lillo24/roblox_tycoon/pull/11/checks) and PR handoff identify the exact final-head result. |

### Current environment and bounded recovery

The installed official `%LOCALAPPDATA%\Roblox\mcp.bat` resolves to StudioMCP
alongside Studio `0.741.19.7411056`. Its local STDIO initialization answered
`RobloxStudio` version `1.0.0`; `tools/list` timed out after ten seconds, and
the proxy reported "Timed out waiting for tools to become available". The
temporary task-owned proxy was closed. No bridge, package, security preference
or persistent connection setting was installed/changed. This follows the
[official Studio MCP route](https://create.roblox.com/docs/studio/mcp).

Fresh Computer Use inventory found the old preview Edit windows and an existing
`ui-review-main-ready.rbxlx` parent with Server/Place1 clients; no UX-02 or QA-01
window existed. Opening the exact newly generated QA-01 file through native
Ctrl+O/file dialog from the idle `ui-review-main-final.rbxlx` window closed the
dialog but did not expose a QA-01 viewport. A fresh window inventory still
contained only the old previews/session. This failed opening attempt is retained;
no Play was started and no loaded-source, engine, input or gameplay pass is claimed.

Read-only process inspection found nine visible Studio windows plus two existing
windowless processes. The QA-01 file-open attempt also started process `22992`
at 13:48:24 local time, but it remained windowless and was not an executed test.
It was not terminated through another control route. The old client log
`0.741.19.7411056_20261007T115812Z_Studio_9F517_last.log` contains continuing
profile-service HTTP 429 responses around 11:49 UTC on 2026-10-08. These service
errors and the opening failure are environment observations, **not a proven
causal diagnosis or project-script defect**. Their effect is that current-source
runtime verification cannot start. No new multiplayer launch was attempted.

Ownership of the old sessions/windows was requested once before cleanup, because
QA-01 requires preserving unrelated/unsaved work. Until that is established,
they stay open; no process termination, unsaved-work discard or source-worktree
edit of PR #8/#9 is authorized by a failed opening attempt. The remaining action is to
establish one usable current QA-01 window (confirm old QA sessions may be stopped,
or preserve user work and reopen this exact QA copy). Codex can then execute the
whole matrix; the user is not being asked to run individual assertions.

The clean detached checkout remains available for the pending restore smoke:
`C:\Users\utente\.codex\worktrees\ux-02-integrated-player-basics\roblox_tycoon\build\qa-01-restore`
at `ddffadad13c8efaf206db13cf6ac1751fda7c78c`. Its `build/ui-review-qa-01.rbxlx`
and `build/ui-review-founder.rbxlx` were freshly generated by the same commands
above. No runtime scene/code change is hidden in either copy. Use the founder
copy only for the combined normal play review after technical execution passes.
The canonical scene's captured scripts remain the older MAP copies; current
production source is loaded into these disposable previews, not saved into
`place/tycoon.rbxlx`. No Rojo plugin connection was verified in QA-01.

## Historical UX-02 execution record

| Check | Current result |
| --- | --- |
| Complete local Validate-Project | **Passed at `17fe09f`**, including formatting/lint, fresh Rojo build/sourcemap, Luau analysis of src/tests, 12 structure probes, 5 negative type probes, six-lot map contract and 7 malformed-scene probes |
| Scene hash; MAP server/shared; FIX-01 unchanged | Passed byte/source comparisons |
| PlayerGuidance engine suite | **Not run: Studio preview launch unavailable in this task**; formatted, linted and type-checked |
| Real HUD lifecycle/ordering/readiness suites | **Not run at this head**; engine route included in preview |
| Single-client combined smoke | **Environment blocked: no usable window appeared for the exact generated preview** |
| Exact final draft-head CI | The combined draft's current-head `validate` check is authoritative; handoff records the observed result |

The generated preview's mapped script classes/counts and exact normalized sources
were checked against `17fe09f` with Assert-ProjectStructure. Its Workspace XML
matched canonical Workspace exactly, and the canonical scene SHA256 stayed unchanged.
No later evidence/documentation commit changes that runtime tree. This verifies
the generated file, not loaded Studio code: the preview did not finish opening.

CLI formatting, lint, type analysis and XML checks do not execute Luau. Runtime
results must be recorded separately with source revision and fixture limitations.

Studio 0.741.19.7411056 had a preexisting two-client session on the old UI preview;
it was not started by UX-02 and was preserved. Opening the exact combined file from
idle Studio Home and a retained idle Edit window, plus launching the installed
Studio app, did not produce a targetable combined preview window. A new startup
log appeared but no combined window was returned. This is an environment/control
observation, not proof that gameplay failed. No blocked cleanup, process termination,
new runner/plugin or repeated multiplayer retry was used. No UX-02 Play server was
started, so there is no new test session to stop. The preview remains available
at the exact path above for the later consolidated QA.

## Consolidated runtime/review gates still open

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
blocked, confirmed failure or user review pending. QA-01 attempted execution;
the unavailable Studio target currently prevents the full runtime matrix.
QA remains incomplete until those checks actually run. After general
QA/visual approval, reconcile latest main, rerun affected checks and choose one
final combined merge/consolidation path. Do not merge or close #8/#9 beforehand.

## Historical evidence

- [MAP-01 scene, gameplay and restore packet](../place/MAP_01_REVIEW.md).
- [UI-01 exact-source captures and partial/blocked input QA](UI_01_REVIEW.md).
- [UX-02 implementation requirements](../history-implementations/UX_02_INTEGRATED_PLAYER_BASICS.md).

Retain this draft checkout/preview and the two source review worktrees/backups.
Do not delete unrelated or previously blocked artifacts. The current task's
Play smoke never started; unrelated sessions stay intact. No visual approval,
automatic merge, source-PR closure, publishing or next feature batch has occurred.
