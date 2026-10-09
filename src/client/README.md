# Player interface

This folder owns client presentation. Server attributes, catalogue availability,
native world prompts and the atomic Supply Cache snapshot remain authoritative.

| File | Owns |
| --- | --- |
| `Bootstrap.client.luau` | Starts `Hud.start()` once |
| `Hud.luau` | Subscriptions, assignment changes, independent private result lifetimes, countdown and teardown |
| `HudView.luau` | Native controls, responsive placement, one open panel, local prompt input gate, selection and view rendering |
| `UiState.luau` | Exact number/rate formatting and read-only economy/catalogue/event presentation |
| `UiPreferences.luau` | Session-only preferences, separate from HUD/character lifetime |
| `UiTheme.luau` | Colors, typography, spacing and touch target tokens |
| `FactoryGuidance.luau` | One local entrance marker, ownership-checked target, camera-relative direction/distance and arrival/loss cleanup |
| `Onboarding.luau` | First-purchase hint and completion/dismissal retained in client-session module memory |
| `RuntimeBindings.luau` | Ordered runtime subscriptions, bounded startup deadline, diagnostics and late replacement recovery |
| `WorldLabels.luau` | Scoped local styling/visibility adapters for known factory labels in both PlotWorld hierarchies |
| `PropertyEditor.luau` | Infinite-only discovery previews, explicit purchase, inventory, local map/ghost, cancel/commit/store and palettes |
| `SupplyFeedback.luau` | FIX-01 supplied-time retention, snapshot matching, expiry and timeout invalidation |

The default HUD shows cash, income converted from `Config.IncomeInterval`, factory
identity and public event status. Factory starts closed. It lists actual ownership,
costs, income effects, prerequisites and availability; purchases use world pads.
Help explains the existing loop and session reset, with hints from actual prompt
keys and the current preferred input. No menu pauses the shared game.

Factory's Find my factory closes the panel and resolves `FactoryHub/Lots/Lot{id}/Entrance`
only after `TycoonRuntime/Plot{id}` has matching PlotId and local OwnerUserId.
The local occluded marker is separate from ambient ownership labels. A stationary
HUD cue gives camera-relative Ahead/Behind/Left/Right and horizontal stud distance
even when the entrance is offscreen. Stop guidance is available in the cue and
Factory. Arrival within 8 horizontal studs and 10 vertical studs retires it.
Assignment/ownership loss, target replacement/destruction and teardown clear it.
Respawn reuses the single helper and waits for the new character. Fixed-name
lookups run at 4 Hz only while requested; no Workspace scans, camera movement,
walking, teleportation or remotes are added. Missing anchors show locating, then
unavailable after 10 seconds with a developer diagnostic; late replication recovers.
Panels pause the world cue. The optional `world` argument supports isolated engine
fixtures; production resolves the actual Workspace.

The optional hint uses any server-written valid catalogue purchase, including one
present at initialization. Completion acknowledges for four seconds, then retires.
Dismissal/completion survive HUD recreation and respawn. Reset interface settings
does not replay it. Help explicitly reopens guidance, including completed-player
reminders. Full/unassigned states and open panels hide the card. Private results
take its space immediately; warning/open/result phases pause onboarding. Requested
navigation uses the same card in the closed panel's bounded space. Text scrolls;
Dismiss/Stop stays outside that content. No additional animation is used.

The shell renders before runtime feedback/event data. RuntimeBindings attaches
supply feedback, purchase feedback, then subscribes to/reads the snapshot. One
10-second deadline from HUD creation changes absent dependencies/assignment to
unavailable, with exact paths/reasons in developer logs. Owned root child/name
listeners recover expected late/replacement instances without polling/retry loops.
Name watches remain attached to every direct child while it is in the root,
including unbound or duplicate children. Name-only recovery therefore works after
the deadline and after a bound target is renamed away and back. Removal and HUD
teardown disconnect those watches; binding cleanup still runs exactly once per loss.
Missing event data leaves known cash/rate intact. Wrong classes, duplicate named
dependencies, malformed JSON/snapshot fields and invalid economy attributes surface
unavailable status; valid later data recovers. Only external JSON decoding is caught.
Internal helper/view errors fail normally. Full capacity remains factual with no queue.

Factory, Settings and Help share one bounded scrollable panel and an explicit
Close button. Buttons use `Activated`, wrapped text, automatic height and a
44-pixel minimum at Standard size. Interface Large scales by 1.15 and reflows.
Text is never shrunk with `TextScaled` or a maximum text-size constraint. Native
Roblox preferred text size is honored by automatic bounds; preferred transparency
multiplies the theme's background transparency. Platform reduced motion always
wins over the local toggle. A 0.12-second panel scale entrance is the only motion;
reduced motion snaps it directly to its final size.

Placement uses CoreUISafeInsets and reported native chat/input bounds. Medium
editor views stack a compact column; portrait fills the usable width. Short wide
views move beside chat with an exact compact economy row. Short views keep
public status/private slots to the left, reserving a 280-pixel message
column even when chat is collapsed. Short views show the public status line;
the repeated marker hint remains in Help
and taller views. Touch panels reserve at least
90 screen pixels at the bottom and the reported native JumpButton bounds; Close
stays outside the scrolling content. Layout writes final dimensions once and
guards synchronous automatic-size re-entry. Wide views keep the public event above the center and
place Settings/Help below a conservative player-list reservation: 48 screen pixels
for the native header/clearance plus 40 per connected player, independent of the
local interface scale. This matches the tested Studio native list; its bounds
are not exposed to this view. The reservation is not capped by viewport height,
which previously put these buttons behind the six-player list. Chat/menu/CoreGui
are never disabled. Native menus retain their priority; Escape/Start are untouched.
Opening a panel temporarily disables `ProximityPromptService.Enabled` only for
this client so native purchase/claim inputs cannot activate through it; closing
or destruction restores its previous value. Individual prompts, server guards,
movement and camera controls remain unchanged. Gamepad navigation uses native
selection, explicit control links, A activation and unprocessed B to close;
focused text entry and Roblox menus take precedence. Focus returns to the opener
on close; teardown clears selection owned by the disappearing HUD.

Settings default to Standard, Reduce UI motion Off (effective On if Roblox
requires it), and Factory labels On. Reset interface settings affects only those
preferences. Module memory retains them over panel close, respawn and HUD
recreation within the client session. There is no account/device or cross-session
storage and no global Roblox preference write.

World label discovery is confined to `Workspace/<Config.RuntimeName>` and
identified plot models. Known `Ownership` billboards under `Generator`/`OwnerPanel`
are nearby, occluded by geometry, at most 65 studs away and 180×72 pixels. Known
`UpgradeLabel`/`Label` surfaces on pads, starter equipment and upgrades receive
the theme. Label settings hide only ownership billboards, including ones arriving
later. SharedMarker, native prompts and prices remain visible. The adapter owns
its connections and restores its exact instance's original presentation on
removal/replacement/teardown; it never changes text, geometry or attachments.

Private purchase and supply messages occupy independent latest-result slots.
Three-second supply lifetime begins at receipt; future results wait for the
matching public snapshot with only remaining lifetime. Passed/stale/expired/
cancelled results cannot return. Assignment changes and teardown invalidate work;
panel toggles, settings, resize and ordinary respawn do not. Supply feedback is
subscribed before purchase/state waits; snapshots are subscribed before initial
read. Public winners come exclusively from the snapshot. No cash-difference
inference, severity parsing, notification history or new transaction protocol.

Run `scripts/Validate-Project.ps1` for CLI checks. `tests/UiState.spec.luau`,
`tests/WorldLabels.spec.luau` and the existing SupplyFeedback suite are unmapped
production-module tests. `scripts/New-UiReviewPlace.ps1` constructs a disposable
`build/ui-review-*.rbxlx` from the canonical scene plus a fresh Rojo build and adds
temporary QA modules outside mapped folders. It refuses linked output locations
and verifies the canonical scene hash. Play reports executed assertion counts.
This generated review copy is never a canonical scene save. Exact source and
map provenance, observations and review limits belong in the UI review evidence.
The preview also includes opt-in `HudLifecycle` and `HudFeedback` client modules
and an unmapped `UI01OrderQA` delivery fixture. They exercise actual HUD handlers
without changing authoritative money; delivery must run in a non-idle phase.
Clone the preview's `RunClientAssertions` LocalScript into PlayerScripts to run
them in the live client's module context, and keep it until Stop Play. Studio
command-bar requires have a separate preference cache; destroying the runner
also disconnects the recreated HUD's engine connections in that caller context.
See [UI review evidence](../../docs/UI_01_REVIEW.md) for exact commands and limits.
The current combined continuation is [UX-02](../../docs/UX_02_REVIEW.md).
PlayerGuidance tests isolated ownership/anchor fixtures, cues, hint completion and
binding recovery. HudReadiness uses client-only held/replacement snapshots for
the real ten-second timeout, malformed JSON, late recovery and teardown, without
changing server cash. They are unmapped and execute only in disposable previews.
For the combined review, the helper's `-GameplayOnly` switch excludes every QA
fixture; omit it to retain automatic assertions and opt-in client tests. See
`scripts/README.md` for the Edit-only map route and preview boundary checks.

## INF-01 mode boundary

INF-02 changes Infinite's Factory opener to **My place**. Discover previews an
object before a separate Buy action; Arrange selects owned instances including
stored copies. Tap the plot map or use two-stud arrows, Rotate and Confirm.
Cancel discards only the local candidate. The accepted world stays visible to
visitors until a valid commit. Palette choices are free. The editor uses native
Activated controls, minimum 48px navigation and 52px rows in a bounded scroll
surface; normal HUD returns on Close. It locally gates prompts, never sends
preview movement, allows one RPC at a time, fences stale responses and reports
unconfirmed timeouts with an explicit Refresh. It closes on assignment loss.

`GameMode.read()` is fixed at HUD construction. Prototype keeps its existing event
bindings, status and session-reset help. Infinite binds only purchase feedback:
SupplyCache state/feedback have no deadline or recovery watch. Its `Persistence`
label shows mode/readiness and server saving status; there is no `Event` widget.
Loading/Ready/Full/Unavailable are explicit; only a complete Ready attribute set
enables the displayed economy. The ordinary ten-second assignment timeout does
not misreport an explicit Loading state. Server load retries remain bounded.
Settings, responsive placement, native prompts and guidance are shared. Owner
names stay on nearby world signs; visitors can inspect but server ownership
checks still decide every purchase. Infinite Help explains online-only income,
temporary lot numbers, checkpoint loss limits and the finite first catalogue.
