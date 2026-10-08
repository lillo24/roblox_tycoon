# UX-02 — Integrated prototype and remaining player-facing basics

## Outcome

Prepare one coherent review build containing the six-factory map, the compact player
interface, and a small amount of missing navigation/onboarding/startup behavior.
Then stop feature work so the user can do general QA on that combined build.

The user has explicitly changed the sequence: finish this bounded feature batch
first, then conduct a consolidated visual, multiplayer and input QA pass. Do not
repeatedly stop implementation for a manual swipe, controller traversal or another
attempt at the previously rate-limited two-client check.

This is NOT permission to mark deferred tests passed, skip code validation, publish,
merge unreviewed drafts to main, or implement every possible future game feature.
Keep cheap automated checks and focused tests running. Fix reproducible bugs in
scope; keep unobserved behavior explicitly pending.

## Inspected repository state

Repository: `https://github.com/lillo24/roblox_tycoon.git`

At drafting:

- Main: `29ee28cfad8f8d3abaf905962723945257886f54`.
- MAP-01 / PR #8: draft, head `56fb72feb538add13a863e6b4eef2f970fa9bba8`,
  branch `codex/map-01-six-player-factory-hub`.
- UI-01 / PR #9: draft, head `33b7f5ac46ed6e968c7ec23b8eb18352b3a6736f`,
  branch `codex/ui-01-player-interface`. Last client-source commit recorded there:
  `ef64081577fce0f14c50ee7517d587ab263e0751`.
- PR #8 supplies the six-lot authored scene, oriented map anchors, machine geometry,
  six-player configuration and map validation.
- PR #9 supplies compact HUD, optional Factory/Settings/Help panels, session-only
  preferences, scoped world labels, layout fixes and preserved SupplyFeedback logic.
- The UI/map combination has been previewed in disposable copies, but the source
  branches have not yet been integrated into main.

Re-fetch current refs and open PRs; do not reset newer work to these historical SHAs.
Inspect `AGENTS.md`, the relevant root/source/place/scripts READMEs, both review
packets, validation helpers, client modules and affected tests before editing.
Check for an existing equivalent continuation before creating a duplicate.

External context: this prompt contains the needed product direction. No Google Doc
access is required. Local Studio is useful for a brief preview, but general device
and multiplayer QA is deferred. No new plugin, package, public tunnel, account or
production setting is required. Respect Computer Use approvals/stops and earlier
policy-blocked cleanup; this prompt does not override them.

## 1. Create a durable combined draft, without approving its dependencies

Use one new isolated integration branch/worktree from current main, for example
`codex/ux-02-integrated-player-basics`. Bring the exact current PR #8 and #9 heads
into it while preserving their ancestry. If either already merged, use that work
from current main rather than importing it twice.

This explicitly permits combining the two drafts on this new branch. It does NOT
permit editing their source branches/worktrees, merging them into main, treating
past "seems good" wording as visual approval, or deleting their review material.

Resolve integration intentionally:

- Keep MAP-01's six-lot scene, configuration, anchors, rotated placement and tests.
- Keep UI-01's modular Hud/HudView/UiState/UiPreferences/UiTheme/WorldLabels work,
  including the final long-message overlap fix, safe-area behavior, local prompt
  gating and focus restoration. Do not overwrite it with the earlier large HUD.
- Preserve FIX-01's actual SupplyFeedback implementation and tests.
- Update conflicting documentation by responsibility; do not leave main's obsolete
  four-lot directions as the combined prototype's current instructions.
- Check all affected callers and tests rather than selecting entire conflicting
  files from one side indiscriminately.

Open a new **draft PR into main**. Identify the exact incorporated heads and say
that the diff intentionally includes pending #8/#9 work plus UX-02. Keep the source
PRs open and unchanged. Final merge/consolidation and source-PR closure happen only
at the later approval/QA step; do not leave multiple competing merge instructions.

Do not change the six-lot geometry. The MAP-01 scene SHA256 at drafting is
`9D6A9FE65A25E0C1D8CF6FA4FE7D4E582EA234FF618DC758BC71FD4675C9F8E8`.
If that source evolves, record the new verified baseline. Re-sync current Git code
into a disposable copy for preview; never overwrite authored scene source with a
Rojo build or save transient UI/QA objects into it.

## 2. Find my factory — guidance, not teleportation

Add a clear **Find my factory** action inside the existing Factory panel, not a
new permanent top-bar menu. It closes the panel and temporarily guides the local
player to their assigned factory entrance. Provide a way to stop the guidance.

Use a restrained local marker and understandable direction/distance cue. It must
help when the entrance is outside the current view; a label that is only visible
when already looking at the target is not sufficient. Do not force camera movement,
teleport, auto-walk, reveal private gameplay state or add a purchase remote.

The saved MAP-01 contract already includes `Config.MapName`, `Lots/Lot{id}` with
`LotId`, and an `Entrance` Part. Inspect and reuse the actual replicated contract.
Do not import the server-only MapLayout module into client code or duplicate ring
coordinates. Resolve from the assigned plot ID, then cross-check the local player's
replicated ownership before retaining a target. Keep data-derived IDs; do not
hard-code factory 1 or a particular number of plots in the view.

Lifecycle and interaction requirements:

- Only one active target/indicator for this client.
- Clear it on assignment loss/change, target destruction or HUD teardown.
- On arrival at the entrance, retire the active guidance; the action can be used again.
- Ordinary respawn must not leave duplicate markers or connections.
- Handle absent/not-yet-replicated anchors by showing a locating/unavailable state,
  not pointing at world origin or another owner's lot. Handle later availability
  without assuming all descendants replicate together.
- With no assignment/full capacity, explain why there is no target.
- Preserve the ownership-label preference: this explicitly requested temporary
  navigation cue is separate from ambient owner labels. Turning labels off must
  not disable native prompts or silently make this action useless.
- Keep guidance clear of native touch controls, prompts and the existing feedback
  regions. Respect reduced motion. Avoid per-frame full-Workspace scans.

Implement the smallest reusable client helper needed; no minimap, route-planning
framework, map editor or navigation service.

## 3. First-purchase guidance without a forced tutorial

Add a brief, dismissible contextual hint to help a new player understand the
existing loop. Do not duplicate the Help panel as a large onboarding overlay.

The hint should explain, according to actual current state:

- A factory is assigned automatically; use Find my factory to locate it.
- Cash accrues automatically; use a world pad to buy an available upgrade.
- Once any valid first upgrade is owned, acknowledge completion briefly and retire
  the first-purchase hint. Do not force a particular build order or claim that one
  initial upgrade is the only correct choice.

Derive completion from server-written purchases, not a local click, a submitted
request, an income guess or parsed success text. Prices and prerequisites still
come from the real catalogue. It must also handle a player who has already bought
an upgrade before the hint initializes.

Allow dismissal and explicit access to guidance again through Help. Retain
completion/dismissal within the client session across ordinary respawn and HUD
recreation. No cross-session saving, DataStore, analytics service, tutorial rewards
or new gameplay state. Reset interface settings must not reset cash or unexpectedly
replay the tutorial; restarting guidance is a separate explicit action.

Avoid hint/notification piles: existing public event status and authoritative
purchase/supply results have priority. Pause/hide optional guidance while a panel
is open or there is no usable assignment. Do not suppress mandatory factual feedback.

## 4. Truthful startup and unavailable-state behavior

Reuse the existing Joining and Full states; do not pretend these are missing and
replace working behavior. Fill the narrow gap between waiting for runtime data
and an indefinite "Joining"/"Waiting for server state" after initialization fails.

Currently Hud waits for feedback remotes and the event snapshot with timeouts and
assertions. Inspect that path and make missing runtime dependencies understandable
without turning programmer errors into success-shaped fallbacks.

- Render the existing basic shell/Help/Settings when its own client dependencies
  are ready. No artificial loading bar or fullscreen cinematic loader.
- Keep factory assignment, factory location and event readiness distinct. An event
  dependency missing must not falsify a known cash balance or kill working settings.
- While waiting, say what is pending. On a bounded, documented wait timeout, show a
  concise unavailable message and retain an actionable diagnostic in developer logs.
- Recover if the valid expected runtime instance/state arrives later. Use bounded
  owned listeners or a deliberately small binding routine, not repeated unbounded
  polling or parallel retry loops.
- Wrong instance classes/malformed contracts must surface context rather than
  inventing default economy/winner state. Internal implementation errors must still
  be diagnosable and fail tests; do not wrap the entire HUD in a blanket silent pcall.
- Assignment loss must clear old target, purchase presentation and relevant feedback.
  Full capacity is not a transient network failure: preserve its actual behavior,
  which has no waiting queue. Do not imply a free lot will automatically be assigned.
- Keep Settings/Help usable where possible; do not show fake reconnect, save or
  server-restart controls. Do not replace Roblox's own disconnected-session UI.

Preserve feedback listener-before-snapshot-read ordering and subscribe-before-read
semantics. Late initialization/teardown must not create duplicate listeners, timers,
HUDs or stale messages. No broad UI architecture rewrite is required.

## 5. Input completeness, without making observation a per-task blocker

New controls use the same native cross-platform activation and UI conventions as
UI-01. Wire logical selection/focus order and keep Close/Back reachable. Avoid
click-through to world prompts. Keep one expanded panel at a time and restore
only prompt/input state this UI actually changed.

Inspect the existing scroll/selection paths while changing them. Fix a demonstrated
code problem, including regressions from this batch. Do not declare touch scrolling
or controller traversal broken merely because earlier automation did not prove it.
Do not declare them tested merely because the code looks right.

The outstanding actual swipe and full directional-navigation checks move into the
combined QA record below. Do not stop feature completion to ask the user to perform
them now, and do not repeatedly launch rate-limited multiplayer sessions.

## Non-goals and preserved behavior

Keep all catalogue IDs/prices/prerequisites/income, server authority, six-lot layout,
Supply Cache cadence/reward and receipt-based feedback lifetime unchanged. No
custom client purchase/claim authorization and no teleport shortcut.

No audio system or inactive volume sliders; no inventory/shop/achievements/daily
rewards; no persistence or save badge; no mandatory minigame, production pause,
parkour, combat, conveyor, prestige, round system or economy rebalance. Those are
separate design decisions, not prerequisites for this interface batch.

Do not add routine floating income text or parse private message strings to invent
cash rewards. Keep UI appearance centralized and alterable without changing logic.
No unrelated tool upgrades, CI-trigger changes or new UI framework.

## Validation during implementation

Run the existing `./scripts/Validate-Project.ps1` on the integrated code, including
formatting, lint, type analysis, build/map validation and regression controls. Keep
final draft-head CI green. Do not weaken tests to make a combined branch pass.

Add focused tests for the new guidance/target/lifecycle/readiness behavior using
the repository's existing style. Execute relevant tests where the established
engine route is available; distinguish execution from formatting/type checking.
Do not install a new runner merely to avoid Studio. If engine access is blocked,
finish safe source work, record which tests were not executed and keep the draft.

A brief single-client integration smoke is useful when Studio is available: one
HUD, working panels, guidance target, state updates and no introduced startup error.
Do not repeat the entire six-client/device/restore history in this implementation
task. Do not require the manual Script Analysis panel by default.

Reproducible defects in the new implementation should be fixed before handoff.
Environment-blocked observations do not halt the feature batch, but remain pending
for the general QA. No workarounds for approval denials or repeated 429 retries.

## One durable general-QA checkpoint — prepare now, run later

Create a concise combined review/QA document, using an existing suitable document
if present. Include exact source heads, integration head, scene source/hash,
reproducible startup commands and the actual existing local preview path.

Carry these outstanding checks forward explicitly:

- Map scale/spacing/factory feel, sightlines and label density: user review pending.
- Combined map + UI + new guidance: assignment/readiness and first purchase flow.
- Two-client private results/local preferences versus shared winner state; earlier
  UI-01 attempts were blocked by Roblox profile-service HTTP 429/capture failures.
- Touch scrolling demonstrated by a real supported swipe, changed CanvasPosition
  and reachable lower content; earlier touch events alone did not prove scrolling.
- Full controller directional traversal, activation, panel close/back and focus
  restoration; earlier A/B activation was only partial coverage.
- Standard/Large portrait/landscape, native chat/menu/safe-area/jump-control clearance,
  long text/results, and target/offscreen-marker behavior.
- Respawn, HUD recreation, delayed/absent state, full capacity, assignment loss and
  replacement, including no stale guidance/results/preferences leaking to others.
- A final combined gameplay regression and clean-checkout restore at the chosen
  QA head; old observations remain historical until carried forward appropriately.
- Physical-device performance and physical input: unperformed until hardware is
  available. Do not mislabel an emulator run as a device benchmark.
- Hosted maximum 6 is still a pre-publication setting, not set by client/UI code.

Use status labels such as passed at SHA, inherited evidence, not run, environment
blocked, confirmed failure and user review pending. Never copy historical passed
results into the current head's result column without justification.

This task prepares that checkpoint; it does not execute the full matrix or solicit
individual manual approvals. A later general QA can fix failures and rerun affected
areas; it is not a promise that only one test execution will ever be necessary.

## Handoff and stopping point

Push the combined draft and leave main and PR #8/#9 unchanged. Do not publish, merge,
close dependencies or delete retained review worktrees/backups. Stop only task-owned
servers/tests when finished; preserve unrelated Studio sessions and blocked leftovers.

Provide one reviewable preview location and exact commands, not another temporary
compatibility copy with unspecified source versions. Reuse the existing disposable
preview mechanism where practical. Verify code loaded into a preview matches the
integration head; Git remains authoritative over old code copies in the saved place.

Report what was implemented, reused, actually checked and deferred. Call it
**implementation ready for consolidated QA**, not release-ready or fully validated.
After this batch, stop adding features and hand over the combined QA checklist.

## References

Project evidence at drafting:
- https://github.com/lillo24/roblox_tycoon/pull/8
- https://github.com/lillo24/roblox_tycoon/pull/9
- https://github.com/lillo24/roblox_tycoon/blob/33b7f5ac46ed6e968c7ec23b8eb18352b3a6736f/src/client/Hud.luau
- https://github.com/lillo24/roblox_tycoon/blob/33b7f5ac46ed6e968c7ec23b8eb18352b3a6736f/src/client/UiState.luau
- https://github.com/lillo24/roblox_tycoon/blob/56fb72feb538add13a863e6b4eef2f970fa9bba8/src/server/MapLayout.luau

Official platform references; use APIs supported by the pinned toolchain/Studio:
- https://create.roblox.com/docs/reference/engine/classes/GuiButton#Activated
- https://create.roblox.com/docs/reference/engine/classes/BillboardGui
- https://create.roblox.com/docs/reference/engine/classes/Instance#WaitForChild
