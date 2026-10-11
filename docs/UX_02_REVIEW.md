# Combined prototype: UX-02 / QA-01 review packet

**Engine and live multiplayer QA have executed. Remaining manual QA is follow-up.**
[PR #11](https://github.com/lillo24/roblox_tycoon/pull/11) is the shared development foundation.
On 2026-10-09 the owner explicitly authorized its merge despite the previous founder-review
hold, after reconciliation with latest main and required checks. This replaces the historical
hold below; it does not authorize publication or merging experiments #14–#16 or INF-01.

## Foundation integration checkpoint (2026-10-09)

Reconciled main `8d44a5e` into the existing integration branch without conflicts. The incoming
changes are four implementation briefs; gameplay and the canonical scene hash are unchanged.
Reviewed the integrated source boundaries, map contract, runtime authority, UI recovery and
QA evidence. Full `scripts/Validate-Project.ps1` validation passed locally after reconciliation;
required full CI passed on reconciled head `088f9e1`
([run 37901119410](https://github.com/lillo24/roblox_tycoon/actions/runs/37901119410)).
PR #11 merged as `36a5caa`. Prior engine observations below remain historical
evidence for unchanged code, not a claim that every manual scenario was rerun today.

Manual follow-up remains: meaningful touch scrolling/Reset and a touch cache claim; sustained
walking and native controller world-X prompts; simultaneous live contention; live world-prompt
insufficient-funds/non-owner attempts; combined visual/play review; live system-preference
changes; and physical-device performance. Domain coverage is not a substitute for those
observations. These are explicitly deferred by the owner's foundation-merge instruction.

## Provenance

| Source | Exact revision |
| --- | --- |
| Current main including QA-01 | 2c2f04decc1a2ff1015464bf3e07e2d5de1627db |
| Incorporated MAP-01 / PR #8 | 56fb72feb538add13a863e6b4eef2f970fa9bba8 |
| Incorporated UI-01 / PR #9 | 33b7f5ac46ed6e968c7ec23b8eb18352b3a6736f |
| UX-02 production baseline | 17fe09f583b5a4db15d984129de9ca5d7010419d |
| QA fixture capability repair | 67e2a14b236945a879d93e43b1d10a83d3f179f3 |
| Binding recovery repair | 04c45324d9961cd34cf739a4d6badd6b2e770111 |
| Final behavior / layout repair | ebbd8c1e0c8d23361145bd9806e2a02dd30a5126 |
| Evidence-only head | Current PR head; final SHA/CI result in PR description and checks |
| Canonical scene SHA256 | 9D6A9FE65A25E0C1D8CF6FA4FE7D4E582EA234FF618DC758BC71FD4675C9F8E8 |

Integration retained MAP/UI ancestry and reconciled current main. After the UX baseline,
production changes are confined to RuntimeBindings and wide navigation in HudView, with
nearest documentation/regression tests. Server/shared code, prices, income 12/tick at four
upgrades, event timing/+10 reward, FIX-01, mappings, pins and canonical scene are unchanged.
Phone placement uses the unchanged narrow/short branches. Earlier observations below are
inherited only for unchanged responsibilities, not presented as final-build captures.

## Demonstrated defects repaired

- Protected Player construction prevented the isolated guidance suite from running.
  Its UserId/Character-only fixture now uses a structural double; test intent is unchanged.
- After the startup deadline, an existing unbound dependency renamed to its expected name
  never recovered. A bound instance renamed away/back also failed. Owned Name listeners now
  cover every direct root child until removal/teardown. Seven new regression assertions cover
  recovery, duplicate-name resolution and exact cleanup; PlayerGuidance now executes 59.
- At three, then six live players, Roblox's list obscured Settings/Help. HudView now reserves
  48 screen pixels for header/clearance plus 40 per player, independent of local scale, without
  the height cap that moved controls behind rows. Four conditional lifecycle assertions check
  the actual controls at Standard/Large in wide views. The new test failed against the old
  six-client HUD at “Wide Settings clears the native player list.”

## One review build and reproducible preparation

Historical integration checkout (archived after merge):
C:/Users/utente/.codex/worktrees/ux-02-integrated-player-basics/roblox_tycoon

**Gameplay-only founder copy preserved after cleanup:**
C:/Users/utente/Documents/GitHub/roblox_tycoon/build/foundation-11/ui-review-founder.rbxlx
SHA256: `A93ED8A61649E05E25C25F4669572565F342846CA637D3E0C9E2BF036A1B64AE`.

Historical QA copy (regenerate in the current checkout):
C:/Users/utente/.codex/worktrees/ux-02-integrated-player-basics/roblox_tycoon/build/ui-review-qa-01.rbxlx

From the current checkout:

```powershell
$env:PATH = "$env:USERPROFILE\.rokit\bin;$env:PATH"
./scripts/Validate-Project.ps1
./scripts/New-UiReviewPlace.ps1 -OutputName ui-review-qa-01.rbxlx
./scripts/New-UiReviewPlace.ps1 -OutputName ui-review-founder.rbxlx -GameplayOnly
```

Open the exact file through native Studio Ctrl+O. Both variants share exact production code,
classes and canonical Workspace; the helper regression verifies that boundary. GameplayOnly
excludes every QA module/remote/assertion/display fixture. The default retains them.
Never save Play/build over place/tycoon.rbxlx. Its captured scripts remain older MAP copies;
fresh code is installed into disposable previews. Loaded-source equality and a real viewport
were verified separately from Rojo; **no Rojo plugin connection was verified**.

Before Play, invoke the guarded Edit-only map test:

```luau
require(game.ServerScriptService.UI01QA.RunMapAssertions)()
```

During a non-idle Supply phase, use the actual LocalScript module cache:

```luau
local runner = game.ReplicatedStorage.UI01ClientQA.RunClientAssertions:Clone()
runner.Parent = game.Players.LocalPlayer.PlayerScripts
```

Keep it until Stop Play: its caller owns recreated-HUD connections. Command-bar requires
use a separate preference cache. Readiness/display/order fixtures inject their state;
none is ordinary gameplay or proof of a naturally occurring network race.

## Executed validation, 2026-10-08

Studio version: 0.741.19.7411056. Clean ebbd8c1 loaded all 37 exact production/QA script
sources/classes in a real viewport. All ten engine suites **executed**, totaling **1,111**:

| Suite | Assertions | Actual method |
| --- | ---: | --- |
| MapLayout | 522 | Saved six-lot scene, Edit-only |
| Session | 186 | Production modules, isolated domain state |
| SupplyEvent | 196 | Production modules, controlled time/state |
| SupplyFeedback | 65 | Supplied-time ordering/expiry |
| UiState / preferences | 40 | Production presentation/preferences |
| WorldLabels | 13 | Isolated known label hierarchies |
| PlayerGuidance / bindings | 59 | Ownership, anchors, timeout/name/replacement recovery |
| HUD lifecycle | 15 | Actual LocalScript teardown/recreation, six-player Standard/Large clearance |
| HUD ordering | 7 | Actual LocalScript receipt-before-snapshot injection |
| HUD readiness | 8 | Actual LocalScript, real ten-second timeout, malformed/late/replaced state |

This is one executed revision, not a sum of historical totals. Server suites executed at
18:18:34–35 UTC; Edit MapLayout at 18:18:05; actual client suites at 18:26:49–18:27:03.
The earlier 04c4532 run totaled 1,107; final layout regression adds four actual assertions.
Sanitized engine/delivery output is retained in [execution evidence](qa-01/execution.txt).

Full CLI passed after each repair and in clean detached checkout at ebbd8c1: formatting,
lint, fresh build/sourcemap, source/tests analysis, 12 structure probes, 5 negative type
probes, six-lot contracts, 7 negative map probes, ignore rules and both preview variants.
Ignored logs: build/qa-01-recovery-validation.log, build/qa-01-clean-recovery-validation.log,
build/qa-01-layout-validation.log and build/qa-01-clean-layout-validation.log.

The [final-head Validate check](https://github.com/lillo24/roblox_tycoon/pull/11/checks)
and PR description record the exact final pushed SHA/run/result. Only full validation at
that head counts. Historical e388bd3 run 37773749650 passed attempt 2; attempt 1 failed
downloading pinned luau-lsp with HTTP 403 before validation. One bounded rerun preserved pins/checks.

## General QA matrix

| Area | Observed outcome / evidence boundary |
| --- | --- |
| A: assignment / locator | Native Factory → Find closed the panel and displayed offscreen direction/distance. Live Player3/rotated lot 3 with Labels Off had one enabled local marker at exactly FactoryHub/Lots/Lot3/Entrance; Player2 had no marker. Native Stop worked in the earlier combined desktop run. Arrival/ownership/anchor loss/replacement/cleanup passed isolated engine fixtures. **Held-key walking to arrival was not observed**; position fixtures are not walking. |
| A: onboarding / retention | Actual replicated purchases completed the hint. Native Help reopening, completed guidance after real menu-driven respawn, one HUD, retained Large/Labels Off/cash/income 12, and Reset without cash change or hint replay were observed on UX production + 67e2a14. Pre-initialization purchase, dismissal and restart passed module tests. |
| B: readiness / lifecycle | **Passed at ebbd8c1:** 59 binding/guidance and 8 actual HUD readiness assertions cover real ten-second timeout, invalid JSON/class/duplicate cases, late/replacement/name recovery, known cash preservation and cleanup. Actual LocalScript lifecycle/ordering passed, including six-player Standard/Large clearance. Negative state is labeled injection, not natural replication. |
| C: purchases | Native desktop prompts deducted 10/30/25/60 and produced distinct equipment at income 2/5/7/12. Tuning before Booster was rejected. Clean 04c4532 first Booster deducted exactly 10 and rate became 2. All positioning used labeled Character:PivotTo only; no Session/cash/purchase writes. Domain tests cover insufficient funds, replay and non-owner rejection; live insufficient-funds/non-owner prompts were not separately observed. |
| C: event | Natural countdown/warning/open/expiry/later events and continued ordinary income were observed. Native single-client claim awarded exactly +10 separately from income ticks, also at clean 04c4532. Three-second retention/independent purchase results passed 65/7 controlled checks. Timed multiplayer attempts that missed the open window receive no credit. |
| D: assignment / capacity / reuse | **Passed live at 04c4532:** Players1–6 had unique lots 1–6 and matching owners. Player3's native Booster changed its rate/equipment while others retained base rates. Native Close cleared lot 3 owner/equipment. Player7 joined lot 3 with cash 1 after a tick, rate 1, purchase false, owner -7 and zero equipment; others retained IDs/growing balances. Add Clients retained count 3 and launched Players7/8/9; Players8/9 were explicitly Full with no plot/cash/rate/purchases. Eight native clients were connected after replacement; this is actual capacity evidence. |
| D: local state / delivery | Earlier Player3 was Large/Labels Off with guidance/purchase; Player2 stayed Standard/Labels On, no marker and first-purchase hint. Player3's panel gated its own prompts. **Final ebbd8c1 delivery passed for Player1/Player6:** both exact client sources verified; passive private/public/cash observers attached before Workshop and event 41. Only Player1 received Workshop private feedback and claim-41 private result/+10; Player6 received the exact same public winner snapshot, with no private result or reward delta. Final Player1 used native Large/Labels Off, Player6 Standard. **Simultaneous live contest remains unobserved**; domain atomicity passed separately. |
| E: desktop / controller | Native mouse navigation, controls, wheel scrolling, Reset, Close and world prompts were exercised. Supported controller D-pad traversed Factory/Settings/Help/Find and lower Reset/Restart controls; A, B/Close, focus return and native Start/Y/A respawn were observed. Direct SelectedObject writes were not credited. **Native controller world-X purchase/claim and sustained walking were not observed.** |
| E: touch / layout | XR native device emulation rendered portrait/landscape Standard/Large, closed/open panels, synthetic long balance/winner/separate messages, notch/jump controls and visible Close. Final ebbd8c1 founder rerun rendered both sizes/orientations, native touch Labels Off/Find/Stop, and first Booster: actual TouchTap, exact -10, income 2. **Usable swipe remains unproven:** supported drag emitted touch begin/end about 17ms apart and moved CanvasPosition only 0.527 pixels, without reaching Reset. Wheel fallback is not swipe evidence. Two bounded final touch-claim attempts arrived after expiry; neither is a pass. |
| F: restore | **Passed at clean ebbd8c1:** full CLI/regeneration, 37 loaded QA sources, all ten suites/1,111, native first purchase/claim, six-player session and clean Stop. Independent founder copy verified 22 exact production sources/no QA; fresh start/Stop/restart and native touch first purchase passed. Final Edit assertions confirm six lots and no runtime/event/player residue. Temporary clean checkout removed after verification. |

### Final behavior continuation

Final behavior: ebbd8c1e0c8d23361145bd9806e2a02dd30a5126.
Clean detached checkout used: build/qa-01-restore under the integration checkout;
removed after verification, with logs/evidence preserved and the independent founder copy retained.
Clean status, full CLI and both fresh variants passed. Studio loaded-source verification
passed 37 exact final sources and MapLayout executed 522; all ten suites executed 1,111.
Native six-player Standard/Large Settings opened below the player list. Native Booster
deducted exactly 10 (18:35:42); keyboard claim 34 awarded exactly +10 (18:36:32), separate
from income 2. Workshop private feedback was observed with both subscribers attached;
its cash replication coalesced the 30 cost with a +5 income tick (net -25), so that observer
alone is not an isolated exact-cost measurement. Claim 41 gave a separate +10 and the same
public winner to Player6. Native End Session closed all six clients/server; clean Edit
restored six empty lots. Root gameplay-only founder copy opened visibly and verified 22
exact production sources/classes and no QA folders at 18:44:10. Fresh assignment/ordinary
HUD, native Stop, fresh restart into XR, and touch first purchase at 18:53:30 passed.
Phone closed/open panels rechecked Standard/Large landscape and portrait. Native portrait
Labels Off → Factory → Find showed the offscreen “Behind you / 60 studs” cue; native Stop
dismissed it. Portrait uses a labeled, client-only PlayerGui.ScreenOrientation fixture,
not a saved scene/default-orientation change; see the [supported orientation API](https://create.roblox.com/docs/reference/engine/classes/PlayerGui/ScreenOrientation).
Two final touch-claim taps occurred after expiry; final desktop/keyboard claims passed
in the clean QA session. Stop removes all transient client observers/position/orientation
fixtures. The founder file is left in desktop Edit for review.

## Actual Studio captures

Earlier captures apply to unchanged owners at their stated revisions; none is user approval.

| Capture | Revision / method |
| --- | --- |
| [Overhead](qa-01/combined-overhead.png) | Final ebbd8c1 founder Edit, 22-source/fixture-boundary and no-residue verified |
| [Factory growth](qa-01/factory-growth.png) / [Factory panel](qa-01/factory-panel.png) | UX production + 67e2a14, native four purchases, position-only fixture; panel after real respawn |
| [Clean purchase/claim](qa-01/clean-purchase-claim.png) | Clean 04c4532, native +10 claim, income 2, position-only fixture |
| [Controller Help](qa-01/controller-help.png) | Earlier revision, native D-pad lower Restart control |
| [Landscape](qa-01/phone-landscape-standard.png) / [Settings](qa-01/phone-portrait-large-settings.png) | Final ebbd8c1 founder, native XR Standard landscape / Large portrait; temporary client-only orientation fixture |
| [Portrait long text](qa-01/phone-portrait-large-synthetic.png) / [Landscape long text](qa-01/phone-landscape-standard-synthetic.png) | Earlier revision, real HudView/synthetic display data; not swipe proof |
| [Overlap before repair](qa-01/player-list-overlap-before.png) | 04c4532, native six-player list, Player3 Large |
| [Standard after](qa-01/player-list-standard-after.png) / [Large Settings after](qa-01/player-list-large-after.png) | Final ebbd8c1, native six-player list and Settings action |
| [Final native claim](qa-01/final-native-claim.png) / [Six-player overhead](qa-01/final-six-player-overhead.png) | Final ebbd8c1, natural claim 34 and running six-player map; position-only fixture |
| [Touch guidance](qa-01/final-touch-guidance.png) / [Founder touch purchase](qa-01/final-founder-touch-purchase.png) | Final ebbd8c1 founder; native touch Find with Labels Off, native exact -10 purchase; temporary portrait/position fixtures |

## Corrected attempts and environment

Initial UX/QA previews did not open. Official local MCP initialized, but tools/list timed out
twice after ten seconds; its task-owned proxy was closed. No bridge/plugin or security/auth
setting changed. After explicit user cleanup authorization, old task windows were saved/backed
up and closed natively. Source worktrees/backups remain; windowless processes were not killed.
Later exact previews opened and executed the checks above, so initial failures are history.

The protected-Player failure led to the fixture repair. The first rename probe recovered via an
outstanding timer; the corrected post-deadline probe reproduced unavailable/zero bindings.
Two stale lexical source-verifier attempts failed on RuntimeBindings; the explicit corrected
verifier passed all 37. Wrong unprefixed attribute/cache paths failed loudly before corrected
Config/runtime-based position fixtures. Duplicate observers from a failed fixture logged the
same one +10 change twice, not two awards; Stop removed them. The pre-repair six-client HUD
failed the new regression. A discarded intermediate unpushed layout revision was refined to
retain the existing header clearance before final validation.
The first final-client scheduling wrapper had a quoting syntax error; a corrected literal
wrapper waited for a natural warning, then executed all 15/7/8 client assertions. Additional
native menu captures timed out and indexed Run clicks lacked geometry. The documented
[Ctrl+9 / Ctrl+Enter command-bar shortcuts](https://create.roblox.com/docs/studio/ui-overview)
recovered source verification/passive observations without changing security settings.

Roblox profile-service HTTP 429 errors continued during usable multiplayer, with no exposed
Retry-After. They did not prevent observed assignments, purchases, preferences, capacity or
reuse; no causal project-bug claim is made. Capture intermittently failed with
“window capture timed out: timed out waiting on channel”; bounded refresh recovered clients,
and server recovery followed a real disconnect. Indexed End Session coordinates failed twice;
a fresh screenshot/observed native menu action stopped the task-owned session. Timed claim
misses and negative-fixture diagnostics are distinguished from production failures.

## Remaining observations and one combined review

Complete together in one usable input session: meaningful touch swipe with reachable Reset,
touch claim, sustained normal walking/controller world-X prompts, and
a simultaneous live two-client contest. Live insufficient-funds/non-owner world-prompt cases
were not separately observed; engine domain rejection checks passed. Requester-only
results/public winner and touch Labels-Off Find/Stop now passed.
Instantaneous key injection
and the short supported touch drag did not establish these behaviors; no product defect was
inferred from that limitation.

Use the single gameplay-only copy for the combined review: inspect factory scale/spacing and
neighboring growth, locate a factory, buy an upgrade, try Settings/Help and observe an event.
Approve that build or identify specific adjustments once. Live system-preference changes
were not exercised; implementation/fixture coverage is separate. Physical device performance
is a hardware-dependent pre-release follow-up. Hosted maximum 6 remains a pre-publication setting.

The original founder-review hold is superseded by the 2026-10-09 foundation authorization
above. Merge through PR #11 after required checks, retaining source ancestry. Do not independently
merge/close #8/#9 or the experiments. Publishing remains unauthorized. The disposable restore
checkout was removed after final verification;
task-owned Play/server/client sessions were stopped, and the independent founder copy remains open.

Historical references: [MAP-01](../place/MAP_01_REVIEW.md), [UI-01](UI_01_REVIEW.md),
[UX-02](../history-implementations/UX_02_INTEGRATED_PLAYER_BASICS.md),
[QA-01](../history-implementations/QA_01_INTEGRATED_PROTOTYPE.md).
