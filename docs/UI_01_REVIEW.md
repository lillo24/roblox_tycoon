# UI-01 review evidence

UI-01 is a separate draft for the first visual/usability review. MAP-01 / PR #8
remains pending and unmerged. Neither scene is approved by these compatibility
checks. Review the compact placement, panel readability, label density, touch
clearance and control wording before either task is considered for merge.

## Provenance

- Main baseline: `29ee28cfad8f8d3abaf905962723945257886f54` (four plots).
- Final client implementation: `ef64081577fce0f14c50ee7517d587ab263e0751`.
  Later commits change the disposable QA helper and evidence, not client behavior.
- MAP-01 preview base: `56fb72feb538add13a863e6b4eef2f970fa9bba8` (six lots).
- Studio: installed `0.741.19.7411056`, Windows, 2026-10-06/07.
- Source and server state are authoritative. No money, purchases, timing,
  prompt guards, tool pins, Rojo mappings or canonical scene bytes were changed.

The MAP preview uses a task-owned detached integration worktree at
`build/ui-map-preview`. Only this UI's client files and unmapped QA tests/helper
were copied over the inspected MAP branch. No MAP history enters the UI PR;
MAP's retained review checkout, screenshots and sessions were not edited.
The existing MAP change to the expanded prototype HUD is superseded only in
this disposable preview by the compact responsive view. The chosen source
layout keeps a side panel and reflows smaller views. Final-source solo Play in
the six-lot scene passed all five engine suites and showed the central cache
marker clear with Factory and Large Settings open. This is UI compatibility
evidence, not approval of MAP-01's geometry or usability.

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
economy row and keeps event/private messages left of navigation and the panel,
including when closed. Its message column is at least 280 logical pixels and
omits the redundant marker hint once public state arrives; loading remains explicit.

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
./scripts/New-UiReviewPlace.ps1 -OutputName ui-review-main-ready.rbxlx
```

Open the generated file in Studio and Play. The helper preserves the canonical
scene, replaces only Rojo-owned source folders from a fresh build and adds
temporary QA outside production mappings. It rejects linked output paths and
omits a leading XML declaration: Studio rejects that header even though general
XML parsers accept it. Only disposable output is normalized. Generated main and
MAP copies were checked for an unchanged Workspace and a single display fixture.
`ServerScriptService/UI01QA` executes actual module assertions and prints counts.
No production remote or test hook is added by the repository's normal build.

Open a panel and apply the settings to retain, then run this in the **Play client**
command bar during a non-idle Supply Cache phase:

```lua
local runner = game.ReplicatedStorage.UI01ClientQA.RunClientAssertions:Clone()
runner.Parent = game.Players.LocalPlayer.PlayerScripts
```

The opt-in LocalScript runs both lifecycle (11 assertions) and delivery ordering
(7 assertions). Its module context is the actual running client: requiring the
modules directly from Studio's command bar uses a separate module cache and can
read default preferences while the live UI uses changed preferences. Keep this
runner alive until Stop Play; destroying its script also disconnects the engine
connections created by the recreated HUD in that caller's context.

Lifecycle after an open panel includes prompt-restoration teardown. It
creates/removes a local label fixture, recreates the actual HUD and verifies
retained preferences, singleton ownership and listener/instance cleanup.

This fixture briefly reparents only the client snapshot instance. The temporary
server delivery fixture sends identified QA prose through the actual existing
private feedback remotes without changing gameplay. It verifies GUI creation
and listener-before-wait, pending delivery, independent purchase feedback,
private/public separation and expiry from receipt. It restores the held
instance on success or error. Stop Play to remove the fixtures.

To inspect difficult display values, clone this separate opt-in runner in the
Play client:

```lua
local runner = game.ReplicatedStorage.UI01ClientQA.RunDisplayFixture:Clone()
runner.Parent = game.Players.LocalPlayer.PlayerScripts
```

It temporarily hides the actual HUD and uses the production HudView with clearly
labelled synthetic cash (1,234,567,890), income (12,345/sec), factory 6, a long
winner name and two independent long private messages. It never changes player
attributes or server gameplay. It asserts safe-area Close, short-view separation
from the panel and native JumpButton clearance after resize/open/size changes.
Destroying its GUI restores the actual HUD; keep its caller alive until Stop Play.

For MAP, create a separate detached preview from the recorded MAP SHA, copy
this exact UI's `src/client` files plus all five UI specs and helper into it,
then run its complete validation and the same helper with
`-OutputName ui-review-map-ready.rbxlx`. Use that generated copy only.
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
| SupplyFeedback | 65 | Main `24d1450`, repeated with final `ef64081` modules in MAP solo Play |
| UiState/preferences | 40 | Same routes; four/six-plot values, exact formatting/rates, loading/full, catalogue states, platform motion precedence and reset |
| WorldLabels discovery | 13 | Same routes; both ownership hierarchies and unrelated-label exclusion |
| HUD lifecycle | 11 | Actual LocalScript context on main `24d1450` and final `ef64081` MAP; recreation, scoped labels, prompt restoration and cleanup |
| HUD feedback ordering | 7 | Same actual client contexts/remote handlers with injected receipt-before-snapshot ordering |

The final MAP engine run printed 65/40/13 at 09:10:39 UTC, lifecycle 11 at
09:11:47 and ordering 7 at 09:11:50 on 2026-10-07. Cash and public countdowns
continued after recreation. Main's repeated actual-context lifecycle/order
run passed at 08:26:52/56 UTC. These are executed fixtures, not natural input;
none mutates authoritative economy. Earlier command-bar preference failures
used a separate module cache. A temporary runner that destroyed itself also
disconnected its recreated HUD's engine connections; retaining the LocalScript
through Stop Play resolved that QA artifact.

Layout QA repaired resize re-entry, header/Close clearance and short-landscape
message overlap. Long-message bounds initially failed at Standard and Large,
then passed with exact final HudView in a Play-only source clone at Large with
the panel both closed (09:00:10 UTC) and open (09:00:27). The compact event
hint and fixed left message column are the final production corrections.
Earlier images are labelled by source below.

The generated final main copy repeated the display fixture directly (without a
source clone): portrait Standard bounds passed at 09:33:48 UTC, landscape
Standard closed/open at 09:34:09/28, and Large open/closed at 09:34:48/09:35:16.
The labelled long names/messages and large balance stayed above native jump
controls and separate from the panel. These assertions validate the final helper
route as well as the real view.

Normal input observed compact default HUD, Factory/Settings/Help switching,
visible Close, immediate size/motion/label toggles and Reset. A real main mouse
purchase produced "Purchased Income Booster", actual ownership and +2/sec.
With Factory closed, cash/event countdown kept updating; reopening reflected
the current purchase. Ownership-off left prices, prompts and the shared marker
intact. Desktop wheel scrolling at Standard and Large was observed.

Resumed main `24d1450` Play also verified a real native Booster Tuning rejection
("Buy Income Booster first"), panel prompt gating/restoration, and a successful
native Supply Cache prompt activation: the server reported public
"lillo204 claimed +10 cash" and private "Claimed +10 cash" while the marker
agreed. Character placement beside a pad/cache was a Play-only position fixture;
funds were earned naturally. Reward size comes from the server messages, not a
cash difference. The cache activation was mouse input, not a touch/keyboard claim.

Roblox's native menu → Rigenera → confirmation performed an ordinary respawn.
A client observer verified the same HUD instance and all three non-default
preferences (Large, reduced motion On, labels Off) survived at 08:30:48 UTC.
The native menu worked while Settings was open. Stop Play removed the observer.

iPhone XR Studio emulation delivered an actual unaffordable Workshop prompt
response and a successful Workshop purchase (+1/sec to +4/sec). Character
placement beside the pad was a Play-only position fixture; player funds were
earned naturally. Portrait and landscape, including Large, were observed with
native topbar/notch and movement controls. Initial short-landscape overlap
triggered source corrections. The resumed `24d1450` phone checks covered normal
portrait/landscape and Standard/Large with visible Close and native joystick/jump
controls; ef64081's later message correction has the final-source long-value
landscape fixture observations above. After control-session recovery, the
generated exact-final main copy also passed normal desktop and XR portrait/
landscape Standard/Large observations, panel switching, native touch activation,
Reset and Close. Native joystick/jump and Roblox menu areas remained visible.

The emulator delivered real Touch begin/change/end to the scroll canvas, but
Sky drag, wheel and scrollbar attempts did not change CanvasPosition. This is
an unresolved input observation, not a passing scroll test or a proven UI defect.
Desktop wheel scrolling passed. A manual swipe is still required. Controller
emulation was disabled during phone checks so native touch controls appeared;
the hand-icon menu only documents touch shortcuts. Menu activation is separate
from native prompt taps.

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
| [Resumed default](ui-01/final-default-main.jpg), [Factory](ui-01/final-factory-main.jpg), [Settings](ui-01/final-settings-main.jpg), [Large Settings](ui-01/final-settings-large.jpg) | Exact `24d1450` main source; header/Close fixes and native desktop controls observed |
| [Locked prerequisite](ui-01/final-locked-rejection.jpg), [open overlay](ui-01/final-overlay-main.jpg), [respawn](ui-01/final-respawn-main.jpg), [cache claim](ui-01/final-cache-claim-main.jpg) | Same source; real native prompt/menu actions, with Play-only positioning for pad/cache proximity |
| [Landscape](ui-01/final-landscape-main.jpg), [Large landscape](ui-01/final-landscape-large.jpg), [portrait](ui-01/final-portrait-main.jpg), [Large portrait](ui-01/final-portrait-large.jpg), [portrait Help](ui-01/final-help-portrait.jpg) | Exact `24d1450`; touch controls and usable Close, before ef64081's long-message column correction |
| [Long-value portrait](ui-01/final-long-values-portrait.jpg) | Labelled synthetic view values on `24d1450`; no economy mutation |
| [Long-value Standard landscape](ui-01/final-long-values-landscape.jpg) | Intermediate message-spacing correction before the final compact hint/closed-column change; synthetic values |
| [Long-value Large landscape](ui-01/final-long-values-landscape-large.jpg) | Exact final `ef64081` HudView in a Play-only clone; labelled synthetic values, panel/jump/Close bounds passed with panel open and closed |
| [Six-lot default](ui-01/final-default-map.jpg), [Factory](ui-01/final-factory-map.jpg), [Large Settings](ui-01/final-settings-map-large.jpg) | Exact `ef64081` client over recorded MAP SHA; real solo Play state and central marker clearance |
| [Final desktop default](ui-01/verified-default-main.jpg), [desktop Help](ui-01/verified-help-main.jpg), [landscape](ui-01/verified-landscape-main.jpg), [Large landscape](ui-01/verified-landscape-large.jpg), [portrait](ui-01/verified-portrait-main.jpg), [Large portrait](ui-01/verified-portrait-large.jpg), [portrait Help](ui-01/verified-help-portrait.jpg) | Exact `ef64081` generated main copy after control recovery; normal UI with real state and native touch controls; no synthetic values |
| [Final synthetic portrait](ui-01/verified-long-values-portrait.jpg), [landscape](ui-01/verified-long-values-landscape.jpg), [Large landscape](ui-01/verified-long-values-landscape-large.jpg) | Exact final HudView through the generated RunDisplayFixture LocalScript; labelled synthetic values and passing bounds assertions |

## Remaining QA and review gates

Two-client QA was retried on 2026-10-07 with final client source in
`ui-review-main-ready.rbxlx`, choosing two clients before launch. After more
than 60 seconds, both clients repeatedly returned Roblox profile-service
HTTP 429 and did not provide a usable captured game view. Fresh selection and
one capture recovery failed with `window capture timed out: timed out waiting
on channel`. The launch parent/server then also failed capture; read-only
accessibility still worked, but native clicks reported
`coordinate input geometry is unavailable`. Keyboard menu recovery did not
expose End Session. Resetting the Computer Use JavaScript session recovered
capture; native End Session closed the server and both clients, confirmed by
the window inventory. No stale coordinates or process termination were used.

This repeats the earlier platform/control blocker, rather than demonstrating
an application failure or two-client success.

The following checks are **unperformed or incomplete**, rather than passed:

- Two-client private results/preferences and agreement on the public winner:
  blocked by the repeated Studio/profile-service failure above.
- Emulated touch scrolling: Touch events reached the canvas, but no actual scroll
  was observed. In XR portrait and landscape at Standard/Large, manually swipe
  Settings/Factory; require CanvasPosition movement, reachable Reset and Close,
  and no activation of a pad behind the open panel.
- Complete controller D-pad selection: A/B activation and return focus passed
  previously, but directional traversal was not established. Manually traverse
  Factory/Settings/Help, panel controls and Close, then check B and native Start.
- Full-capacity/late state has executed module/fixture coverage, not a natural
  many-player observation. Native preferred text-size/transparency in a live view
  and physical-device ergonomics remain unperformed.

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
All task-owned solo Play sessions were stopped. The earlier failed multiplayer
session was successfully ended during the resumed run, and its windows disappeared.
XR orientation was restored to LandscapeLeft, scaling to PhysicalSize, with
device/controller emulation disabled before the new multiplayer attempt.
The **new** failed session was also ended through native End Session after the
control-session reset. Its server and both client windows disappeared from the
inventory. No task-owned multiplayer session remains running.
Unrelated Studio sessions/backups were preserved. Before a later merge,
reconcile current main and rerun affected checks. UI-01 does not authorize
MAP-01 approval or deployment.
