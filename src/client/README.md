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
| `WorldLabels.luau` | Scoped local styling/visibility adapters for known factory labels in both PlotWorld hierarchies |
| `SupplyFeedback.luau` | FIX-01 supplied-time retention, snapshot matching, expiry and timeout invalidation |

The default HUD shows cash, income converted from `Config.IncomeInterval`, factory
identity and public event status. Factory starts closed. It lists actual ownership,
costs, income effects, prerequisites and availability; purchases use world pads.
Help explains the existing loop and session reset, with hints from actual prompt
keys and the current preferred input. No menu pauses the shared game.

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
views move beside chat. Wide views keep the public event above the center and
place Settings/Help below a conservative player-list reservation. Chat/menu/CoreGui
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
