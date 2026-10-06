# UI-01 review evidence

UI-01 is a separate draft for the first visual/usability review. MAP-01 / PR #8
remains pending and unmerged. Neither scene is approved by these compatibility
checks. Review the compact placement, panel readability, label density, touch
clearance and control wording before either task is considered for merge.

## Provenance

- Main baseline: `29ee28cfad8f8d3abaf905962723945257886f54` (four plots).
- UI implementation: `24d1450ceeca7f2fc7eeffc9d2fd868f09d9d610`.
  Later evidence-only commits do not change the preview's runtime source.
- MAP-01 preview base: `56fb72feb538add13a863e6b4eef2f970fa9bba8` (six lots).
- Studio: installed `0.741.19.7411056`, Windows, 2026-10-06.
- Source and server state are authoritative. No money, purchases, timing,
  prompt guards, tool pins, Rojo mappings or canonical scene bytes were changed.

The MAP preview uses a task-owned detached integration worktree at
`build/ui-map-preview`. Only this UI's client files and unmapped QA tests/helper
were copied over the inspected MAP branch. No MAP history enters the UI PR;
MAP's retained review checkout, screenshots and sessions were not edited.
The existing MAP change to the expanded prototype HUD is superseded only in
this disposable preview by the compact responsive view. The chosen source
layout keeps a side panel and reflows smaller views. Its actual clearance in
the six-lot scene still needs a Studio observation; CLI compatibility does not
prove the visual result.

Canonical SHA-256 before/after construction and validation:

| Scene | SHA-256 |
| --- | --- |
| Main `place/tycoon.rbxlx` | `E68D11363B1C2BF10EF37C12EA566F6E8839940F07579BDCE9DBE57FB38C4B49` |
| MAP `place/tycoon.rbxlx` | `9D6A9FE65A25E0C1D8CF6FA4FE7D4E582EA234FF618DC758BC71FD4675C9F8E8` |

## Controls and defaults

Factory is information only; buy using nearby native world pads. Factory,
Settings and Help start closed and share one scrollable panel with Close.
The screen shows exact cash, actual factory identifier, income converted from
the configured tick interval and public Supply Cache state. Reopen reads live
data. No panel pauses the game.

Settings default to Standard (100%), reduced UI motion Off, factory ownership
labels On. Large is 115%. Roblox reduced motion always wins. Reset affects
only these three session preferences. Module memory survives HUD recreation
and ordinary respawn; there is no cross-session saving or global preference
write. Ownership labels are nearby and occluded by geometry; prices, prompts
and the event marker stay visible when ownership labels are hidden.

Native `Activated` controls, selection links and unprocessed B support controller
navigation. Close returns focus. Escape/Start and Roblox menus remain native.
Opening a panel temporarily gates this client's ProximityPromptService; close
and destruction restore its previous state. Movement/camera are not paused.
Touch panels reserve native jump-control space; short landscape uses a compact
economy row and moves event/private messages beside an expanded panel.

Private purchase and supply results use independent latest-result slots.
Supply retention still uses FIX-01 unchanged: three seconds from receipt,
matching future snapshots with remaining lifetime, stale/expired/cancelled
discard, versioned timeout invalidation and assignment/teardown reset.
Panel toggles, settings, resize and respawn do not reset that state. Public
winners come only from the server snapshot.

## Reproduce the disposable QA route

With the repository's pinned Rokit tools on PATH:

```powershell
./scripts/Validate-Project.ps1
./scripts/New-UiReviewPlace.ps1 -OutputName ui-review-main-current.rbxlx
```

Open the generated file in Studio and Play. The helper preserves the canonical
scene, replaces only Rojo-owned source folders from a fresh build and adds
temporary QA outside production mappings. It rejects linked output paths.
`ServerScriptService/UI01QA` executes actual module assertions and prints counts.
No production remote or test hook is added by the repository's normal build.

Opt-in checks in the **Play client** command bar:

```lua
local c = game.Players.LocalPlayer.PlayerScripts.TycoonClient
local qa = game.ReplicatedStorage.UI01ClientQA
print("UI01 lifecycle", require(qa.HudLifecycle)(require(c.Hud), require(c.UiPreferences)))
```

Run lifecycle after opening a panel to include prompt-restoration teardown.
It creates/removes a local label fixture, recreates the actual HUD and verifies
retained preferences, singleton ownership and listener/instance cleanup.

During a **non-idle** Supply Cache phase:

```lua
local c = game.Players.LocalPlayer.PlayerScripts.TycoonClient
print("UI01 ordering", require(game.ReplicatedStorage.UI01ClientQA.HudFeedback)(require(c.Hud), game.ReplicatedStorage.UI01OrderQA))
```

This fixture briefly reparents only the client snapshot instance. The temporary
server delivery fixture sends identified QA prose through the actual existing
private feedback remotes without changing gameplay. It verifies GUI creation
and listener-before-wait, pending delivery, independent purchase feedback,
private/public separation and expiry from receipt. It restores the held
instance on success or error. Stop Play to remove the fixtures.

For MAP, create a separate detached preview from the recorded MAP SHA, copy
this exact UI's `src/client` files plus the four new specs and helper into it,
then run its complete validation and the same helper with
`-OutputName ui-review-map-current.rbxlx`. Use that generated copy only.
Do not overwrite the retained MAP review artifacts or save a canonical scene.

## Validation and observations

Complete CLI validation passed on main UI source and the MAP compatibility
checkout: formatting, Selene, fresh Rojo build/sourcemap, type analysis,
positive/negative analysis probes, source ownership, serialized structure and
ignore rules. MAP also passed its seven authored-scene negative probes.
CLI analysis is separate from engine execution and input observations.

Executed engine tests use the actual production modules:

| Suite | Assertions | Route |
| --- | ---: | --- |
| SupplyFeedback | 65 | Exact `24d1450` disposable main server runner |
| UiState/preferences | 40 | Exact `24d1450` main runner; includes four/six-plot values, exact formatting/rates, loading/full, catalogue states, platform motion precedence and reset |
| WorldLabels discovery | 13 | Exact `24d1450` main runner; both ownership hierarchies and unrelated-label exclusion |
| HUD lifecycle | 11 | Play-client fixture using `6dc0e4d` HUD source; actual HUD recreation and scoped label adapter |
| HUD feedback ordering | 7 | Actual `6dc0e4d` HUD/remote handlers with injected receipt-before-snapshot ordering |

Early source checks were repeated in an isolated Play-only clone to avoid
ModuleScript caching; the clone had Bootstrap removed and exact repository
sources applied. These were fixtures, not natural player input. Lifecycle and
delivery checks did not mutate authoritative economy. Layout QA caught and
repaired synchronous resize re-entry and touch-control overlap. The corrected
resize guard ran in a Play-only clone without further re-entry errors; the
subsequent header/Close clearance adjustment has CLI validation only. Earlier
screenshots are explicitly identified below and are not final-head visual proof.

Normal input observed compact default HUD, Factory/Settings/Help switching,
visible Close, immediate size/motion/label toggles and Reset. A real main mouse
purchase produced "Purchased Income Booster", actual ownership and +2/sec.
With Factory closed, cash/event countdown kept updating; reopening reflected
the current purchase. Ownership-off left the prices/shared marker intact.

iPhone XR Studio emulation delivered an actual unaffordable Workshop prompt
response and a successful Workshop purchase (+1/sec to +4/sec). Character
placement beside the pad was a Play-only position fixture; player funds were
earned naturally. Portrait and landscape, including Large, were observed with
native topbar/notch and movement controls. Initial short-landscape overlap
triggered the source correction. Final-source portrait/landscape confirmation
is pending. The panel's native canvas exceeded its viewport, but emulator wheel,
swipe and scrollbar attempts did not demonstrate scrolling: emulated touch
scrolling remains unverified. Desktop wheel scrolling was observed separately.
Emulated menu activation is separate from the native prompt taps.

Studio's generic controller emulator activated Settings with A (press/release),
closed it with B and returned selection to Settings. D-pad attempts did not
establish navigation between controls. This is partial emulator evidence;
complete controller navigation and physical ergonomics remain unverified.

## Screenshots and review limits

Images in `ui-01/` are bounded, real Studio captures (JPEG). They are outside
Rojo mappings and are not mockups. Review the world/prompt visibility as well
as text and panel bounds. Screenshots of natural purchases/rejections are
labelled separately from delivery fixtures. Click an image to inspect it:

| Capture | Source/meaning |
| --- | --- |
| [Default](ui-01/default-main.jpg), [Factory](ui-01/factory-main.jpg), [Settings](ui-01/settings-main.jpg), [Large Settings](ui-01/settings-large.jpg), [Help](ui-01/help-main.jpg) | Main scene with exact `6dc0e4d` client source in a Play-only clone; compact/panel controls and readable desktop content |
| [Mouse purchase](ui-01/purchase-main.jpg) | Same source; natural Income Booster purchase and independent public event status |
| [Initial landscape](ui-01/landscape-main.jpg), [initial Large landscape](ui-01/landscape-large.jpg) | Before the short/touch-clearance fixes; retained as regression evidence, with known overlap/clipping, not an accepted layout |
| [Portrait](ui-01/portrait-main.jpg), [Large portrait](ui-01/portrait-large.jpg) | Intermediate Play-only touch-reserve correction; not exact final-head source |
| [Touch insufficient funds](ui-01/touch-insufficient.jpg) | Actual native Workshop rejection; intermediate layout |
| [Touch purchase](ui-01/touch-purchase.jpg) | Actual native Workshop purchase after the resize-guard/position corrections, before the final header adjustment |

## Remaining QA and review gates

The exact final source was built into `ui-review-main-current.rbxlx`; its
server runner executed 65/40/13 assertions. A task-owned two-client session
was then attempted. The clients did not reach a usable game view, and their
logs repeatedly reported Roblox profile-service HTTP 429 responses. Native
window capture subsequently failed with `window capture timed out: timed out
waiting on channel`; element input also reported unavailable coordinate
geometry. Re-selection and recovery did not restore reliable control. No
further stale-coordinate input was attempted.

The following checks are **unperformed or incomplete**, rather than passed:

- Two-client private results/preferences and agreement on the public winner.
- A real successful Supply Cache claim/reward and a locked-prerequisite prompt
  rejection (public warning/open/expiry were observed).
- Ordinary character respawn; full/late state has module/fixture coverage only.
- Final-head wide, short desktop, portrait and landscape visual/input checks,
  including touch scrolling and complete controller navigation.
- Long display names/messages, large-balance view fixtures and native preferred
  text-size/transparency settings in a live view (formatting and APIs are checked).
- Live MAP six-lot Play compatibility and its screenshot; only the complete
  MAP CLI suite and label/state module fixtures passed.

Visual approval specifically needs compact placement, panel readability,
accessible Close/scroll controls, touch clearance, world-label density and
wording in both scenes. The technical gaps above also need completion before
any merge; visual approval alone does not waive them.

Physical phone/tablet/controller performance and ergonomics remain unperformed.
Native preferred text-size/transparency support is checked against the pinned
API and automatic wrapped layout; global Roblox accessibility preferences were
not altered to produce evidence. Source/API compatibility alone is not proof
of a physical input observation.

The draft checkout and ignored compatibility preview are retained for review.
Earlier task-owned solo Play sessions were stopped, and device emulation was
disabled before the multiplayer attempt. Ending that last task-owned session
could not be confirmed after control failed; its server and two client windows
may still be open. The XR orientation preference was changed during testing
and restoration is also unconfirmed. Once desktop control is available, use
Studio's End Session for this test and restore that emulator orientation.
Unrelated Studio sessions/backups were preserved. Before a later merge,
reconcile current main and rerun affected checks. UI-01 does not authorize
MAP-01 approval or deployment.
