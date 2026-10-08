# QA-01 — Consolidated prototype QA, repairs, and review handoff

## Objective

Run the general QA checkpoint agreed after UX-02. Validate the combined six-factory map, compact player interface, factory locator, first-purchase guidance, readiness/recovery behavior, purchases, and Supply Cache. Fix demonstrated defects within these existing contracts, rerun affected checks, and provide one coherent build for the user's visual/play review.

Do not add another feature batch. This task executes the previously deferred QA; it must not merely produce another checklist saying the same work will be tested later.

Archiving this prompt in main does not execute it or approve/merge the prototype. Run it in local Codex with the repository and Roblox Studio available. All necessary product context is in the repository; Google Doc access is not required.

## Verified starting point

Repository: `https://github.com/lillo24/roblox_tycoon.git`

At drafting on 2026-10-08:

- Main: `2128f690b2a22534fce1fe8569e2c1caab89ab9b` (includes the archived UX-02 prompt).
- Combined prototype: **draft PR #11**, branch `codex/ux-02-integrated-player-basics`, head `87e5068797873f5516b423fe4ef9f922b78ba9f5`.
- UX implementation/source revision: `17fe09f583b5a4db15d984129de9ca5d7010419d`.
- Incorporated MAP-01 / PR #8: `56fb72feb538add13a863e6b4eef2f970fa9bba8`.
- Incorporated UI-01 / PR #9: `33b7f5ac46ed6e968c7ec23b8eb18352b3a6736f`.
- Canonical scene: `place/tycoon.rbxlx`, SHA256 `9D6A9FE65A25E0C1D8CF6FA4FE7D4E582EA234FF618DC758BC71FD4675C9F8E8`.
- PR #11's final-head CI passed. Its new guidance/readiness tests were statically checked but **not engine-executed**; the combined preview did not open in a usable Studio window. Earlier map/UI runtime evidence is historical, not a pass on this combined head.

Fetch current refs and inspect existing work before changing anything. These SHAs identify provenance, not instructions to reset newer work. The documentation commit adding this file will advance main without adding gameplay.

Read `AGENTS.md`, this prompt, `history-implementations/UX_02_INTEGRATED_PLAYER_BASICS.md`, `docs/UX_02_REVIEW.md`, `docs/UI_01_REVIEW.md`, `place/MAP_01_REVIEW.md`, the relevant source/client/place/scripts READMEs, validation/preview helpers, and affected production modules/tests.

## Continue the existing integration, not three separate review tracks

Continue PR #11 in its existing isolated task checkout where available. This explicitly authorizes a QA/repair continuation in that integration branch rather than creating another competing full-prototype PR. Do not edit a worktree actively used by another task; coordinate or use a clean isolated checkout of the same current branch without losing unpublished work.

Reconcile current main, including this documentation-only plan, without losing the incorporated map/UI ancestry. Do not merge PR #8 or #9 first, cherry-pick their whole content a second time, or alter their source branches, retained previews, or backups. Detect any newer dependency changes and record whether they are incorporated rather than silently ignoring them.

If PR #11 has already merged by execution time, inspect the merged state and use an isolated QA branch/PR from current main for residual fixes. Do not recreate the old integration or undo a verified merge.

**Default handoff: keep PR #11 draft/unmerged for one combined user visual/play review.** Passing technical checks does not supply the user's visual approval. This task does not authorize closing #8/#9, deleting retained review artifacts, publishing, or changing hosted settings. Describe the eventual single consolidation path in the review packet; execute it only after explicit approval of the combined build and all required technical gates are resolved.

## 1. Establish one usable, source-verified Studio target

Use supported local Studio/MCP capabilities first. Inspect existing windows, processes and test sessions so the target is unambiguous. The user has used different Windows accounts/computers; do not assume a `leona` or `utente` path from an old packet is valid on the current machine.

Reuse the existing preview mechanism, inspecting its current parameters:

```powershell
./scripts/Validate-Project.ps1
./scripts/New-UiReviewPlace.ps1 -OutputName ui-review-qa-01.rbxlx
```

The helper places current mapped code and temporary test fixtures in an ignored disposable copy; it is not a replacement for the authored scene. Its current default also includes QA scripts, so do not mistake their synthetic messages or instances for normal gameplay. Keep negative/display fixtures disabled during ordinary input tests unless explicitly exercising them.

Open the exact generated path in Studio. Confirm a real visible viewport, the six-lot scene, correct script classes, and normalized loaded source matching the chosen Git revision before crediting runtime results. A generated XML file, launched process, idle Home screen, old preview, or 1x1 viewport is not an executed combined test. Record programmatic source loading separately from a verified Rojo plugin connection.

Where desktop interaction is needed, use the installed Computer Use guidance and current authorization. Respect explicit stops and approval denials. Do not kill unrelated Studio processes, close unsaved user work, bypass a restriction, install another bridge, or change machine-wide settings to obtain a pass.

Historical HTTP 429/capture failures are neither current product bugs nor permission for repeated launches. Use bounded diagnosis/retry, honor service retry guidance where exposed, and stop the affected route when the environment remains unavailable. Continue independent tests and include one consolidated actionable blocker report; do not ask the user to perform individual checks after every subtest.

## 2. Execute the actual tests and preserve evidence boundaries

Run the complete existing validation entry point on the combined checkout. Keep formatting, lint, type analysis, Rojo/map validation, failure probes and CI intact. Do not add an unnecessary runner, framework or tool upgrade. Manual Script Analysis is not the default gate; use it only for a concrete Studio-only discrepancy or relevant authored context.

Execute applicable repository suites against the real production modules at this head, including Session, SupplyEvent, SupplyFeedback, MapLayout, UiState/preferences, WorldLabels, PlayerGuidance, and real HUD lifecycle/feedback/readiness. Inspect the actual test signatures and helper: its automatic route does not necessarily execute every suite. In particular, close UX-02's unexecuted guidance and readiness gap.

Use the documented opt-in **LocalScript module context** for client lifecycle/preferences tests rather than a separate command-bar module cache. The current preview route is:

```luau
local runner = game.ReplicatedStorage.UI01ClientQA.RunClientAssertions:Clone()
runner.Parent = game.Players.LocalPlayer.PlayerScripts
```

Verify that route still exists before use. Follow its non-idle-event prerequisite and lifetime rules. Keep temporary callers alive as required for the recreated HUD's subscriptions; stopping the disposable test removes fixtures. Do not run destructive/reset fixtures concurrently with normal input checks or retain them in the canonical scene.

Record executed counts per suite and source revision; do not target or sum historical assertion totals as a substitute for current execution. Controlled order/recovery injection is valid regression evidence, but label it as injection rather than natural network behavior. Static validation of tests is not test execution.

## 3. General QA matrix

Use the existing `docs/UX_02_REVIEW.md` as the single live checkpoint. Complete its matrix and add focused reproduction notes where needed instead of creating contradictory approval documents.

### A. First session, locator and onboarding

Start fresh and follow normal player controls: obtain a factory, open Factory, activate Find my factory, follow the direction/distance cue including an offscreen entrance, walk to the owned entrance, earn cash, and buy any valid initial upgrade.

Verify one local marker; correct ownership/entrance; Stop and arrival dismissal; no forced camera, teleport or auto-walk; and no marker on another owner's factory. Check alternate rotated lots. Missing/replaced anchors or lost ownership must clear stale guidance, show the specified locating/unavailable state, and recover when appropriate. Ambient labels Off must not make explicitly requested guidance unusable.

First-purchase completion follows actual replicated purchases, not a click, request, income guess or success string. Test dismissal, explicit Help reopening, a purchase before hint initialization, and session retention across respawn/HUD recreation. Reset interface settings must not reset cash or silently replay completed guidance. Optional hints yield to panels and priority feedback.

### B. Readiness, replacement and teardown

Exercise the new production binding path with labeled disposable fixtures: missing then late dependencies; the documented ten-second timeout; target/remote/snapshot removal and replacement; invalid class, duplicate name or malformed snapshot; and subsequent valid recovery.

Settings/Help should remain usable when event data is unavailable; valid known cash must not be erased by an unrelated event failure. No invented balance/winner, infinite Joining state for an identified timeout, swallowed programmer exception, duplicate subscription or stale message revival. Preserve listener-before-snapshot and subscribe-before-read ordering.

Destroy/recreate the HUD, repeat open/close and guidance cycles, then perform a real character respawn. Observe one HUD/marker, retained session preferences/onboarding, no stale callback clearing new feedback, restored prompt state, and no steadily accumulating task-owned connections or instances.

### C. Purchases and shared event on the combined build

Use normal prompts for actual purchase/claim evidence; direct Session calls are separate domain tests. Verify exact deductions, prerequisites, insufficient funds, replay and non-owner rejection, distinct rotated equipment, and four-upgrade completion at the unchanged total income of 12 per tick.

Verify countdown, warning, open/expiry/result, one exact cash-only +10 reward, continued ordinary income, later events, and no duplicate award. Separate income ticks from reward deltas in observers. Preserve the three-second receipt-based private feedback behavior and independent purchase notifications.

### D. Real multiplayer isolation, capacity and lifecycle

Obtain one usable two-client session rather than accepting prior 429 attempts as coverage. Give the clients different UI preferences, guidance/hint states and purchases. Check private results, label visibility, targets and preferences stay local; both clients agree on the public winner; a simultaneous contest awards only one reward; and opening a panel gates only that client's prompts.

Exercise all six assignments on the combined head with real clients where the existing Studio route permits it, using the minimum sessions needed. Verify no duplicate lot, independent cash/equipment and a real disconnect/replacement with fresh ownership/purchases, while others retain state. Confirm the map survives stop/restart without runtime residue.

Validate full-capacity refusal/no queue using the existing capacity tests and, where available, an additional real player. A synthetic Full fixture or seven-user domain test must not be reported as seven live clients. Missing live capacity coverage stays separately labeled rather than triggering unlimited launches.

### E. Real input, panels and device layouts

- Desktop: every navigation/action/control, Factory information, Help, settings, reset, close, scrolling, focus return, normal prompts and chat/menu coexistence. Panels do not pause production. No world action through an open panel; prior local prompt state returns on close/teardown.
- Touch: perform a supported swipe on the actual overflowing panel. Record a changed `CanvasPosition` and newly reachable lower content, including Reset and Close. Touch begin/change/end events alone, direct CanvasPosition writes or mouse-wheel scrolling do not prove swipe usability. Verify normal touch purchases/claims and new guidance controls too.
- Controller: demonstrate directional movement across navigation and panel controls, A activation, B/Close, focus return, scrolling/reaching lower content and native menu access using the supported emulator or real controller. Setting SelectedObject directly proves only state, not D-pad traversal. Earlier A/B observations do not cover this whole path.
- Layout: desktop and supported phone portrait/landscape, Standard/Large; closed/open panels; long synthetic balances/names/results; active marker/hint; chat, native menus, notches, jump/movement controls and world prompts. Check actual rendered overlap/clipping and accessible controls, not bounds alone. Label synthetic display data.

Respect existing text-size/transparency/reduced-motion behavior. Do not modify global user preferences without permission. Separate implemented/fixture coverage from observed live accessibility preferences. Physical-device input/performance remains a hardware-dependent pre-release follow-up, not an invented blocker requiring hardware for this local prototype checkpoint. Emulator rendering is not a physical performance benchmark.

### F. Clean-checkout restore and usable review build

After repairs, use a clean checkout of the final behavior-bearing commit. Regenerate the preview with pinned tools, verify canonical geometry/hash and loaded source, reopen in Studio, and perform a short fresh-start, first-purchase/claim, and stop/restart smoke. Do not repeat the entire matrix in the clean checkout unless differences invalidate it.

Provide one **gameplay-only founder preview** with current code and no autorunning negative/assertion/display fixtures. Reuse supported existing preparation paths, or add a minimal optional fixture switch to the helper if necessary; default automated-test coverage must not be silently removed. Verify the two preview variants share the exact production source and map. Keep both disposable and do not save transient QA objects into `place/tycoon.rbxlx`.

Record the actual machine path and exact reopen commands, not an assumed old path. Avoid leaving several indistinguishable review copies or claiming the canonical file already contains the latest captured scripts without checking it.

## 4. Repair scope and rerun policy

Fix demonstrated defects in existing map/UI/guidance/startup/input integration, including touch scrolling or controller focus if testing establishes a code defect. Reproduce first where possible; add a narrow regression test; repair the responsibility-owning module; rerun affected tests and the full CLI suite. Recheck shared HUD changes across the layouts/input routes they can affect.

Do not change catalogue prices, income, event timing/reward, six-lot dimensions, server authority, preference persistence semantics or the intended guidance behavior merely to simplify tests. No conveyors, audio/shop/inventory, persistence, production pause, parkour, combat, new minigame, rebalance or publishing in this task. Gameplay design findings go into review notes, not silent redesigns.

Keep FIX-01 ordering coverage, nullable guards and pinned tools/definitions. Preserve the canonical scene hash by default. A demonstrated scene defect may justify the smallest documented correction; record before/after and rerun affected map/restore checks. Aesthetic or consequential gameplay decisions remain for the user rather than automatic broad changes.

After any behavior change, mark invalidated evidence pending and rerun what it affects. Documentation/images-only commits may reuse runtime results only after confirming the production tree/scene are unchanged. Verify CI belongs to the exact final head and ran the appropriate suite. A dependency-download failure is not a passing code check; use a bounded retry without weakening pins or validation.

## 5. One report, then the user's combined review

In the existing combined packet, record for each check: source/scene revision, method, actual outcome, evidence and limitations. Use statuses such as `passed at SHA`, `inherited evidence`, `not run`, `environment blocked`, `confirmed failure`, and `user review pending`.

Separate project-script errors, expected negative-fixture diagnostics and Roblox/CoreGui/service failures. A platform error is not automatically harmless: explain what remained testable and what it prevented. Preserve corrected failed attempts in the execution history without representing them as successful first attempts.

Capture a small set of actual final-build Studio screenshots: overhead map, factory-eye growth, compact HUD, Factory/Settings, and representative phone views. Label source revision, synthetic fixtures, input method and device orientation. Do not use generated concept art as QA evidence or call a screenshot founder approval.

The founder review route should be one short normal playthrough: inspect scale/spacing and neighboring factory visibility; locate a factory; buy an upgrade; try a panel/settings; observe a shared event. Ask once for approval or specific adjustments after the technical pass, with any genuinely untestable manual actions grouped beside it. Do not ask for a manual compiler panel or separate routine approvals after each subtest.

If the environment blocks a required runtime check, complete safe independent work, push exact evidence/fixes, and report the minimal remaining action without claiming completion. If all technical gates pass, report **technically validated; awaiting combined visual/play approval**, not merged or release-ready.

## Handoff and stopping point

Push QA fixes and the updated packet to the existing integration PR and keep it draft for the user. Preserve source PRs #8/#9 and review backups until the eventual approved consolidation; do not delete policy-blocked leftovers or bypass cleanup restrictions. Stop only task-owned sessions; leave unrelated Studio work untouched. Hosted maximum 6 remains a pre-publication setting.

Final report: integration PR/head and tested behavior revision; scene hash; actual executed suites/counts; defects fixed; normal desktop/touch/controller and multiplayer results; clean-restore result; final CI; one gameplay-only preview path; a single list of outstanding checks/review decisions. State explicitly what was not observed.

After this QA/repair pass, stop. No next gameplay/UI feature or automatic merge is authorized by this prompt.

## Source references

- Combined work: https://github.com/lillo24/roblox_tycoon/pull/11
- Baseline review packet: https://github.com/lillo24/roblox_tycoon/blob/87e5068797873f5516b423fe4ef9f922b78ba9f5/docs/UX_02_REVIEW.md
- Prior task: history-implementations/UX_02_INTEGRATED_PLAYER_BASICS.md
- Existing preview helper: scripts/New-UiReviewPlace.ps1
- Source drafts, incorporated but not approved: https://github.com/lillo24/roblox_tycoon/pull/8 and https://github.com/lillo24/roblox_tycoon/pull/9
