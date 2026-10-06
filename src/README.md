# Session tycoon prototype

This source tree owns gameplay inside the existing three code-only Rojo folders.
Bootstraps compose the feature and retain the setup startup messages. GAMEPLAY-02
is a reversible upgrade-order experiment; costs, names, and prerequisites below
are provisional. Technical tests do not establish balance, strategic depth, or fun.
GAMEPLAY-03 adds one provisional shared Supply Cache opportunity. Neither
experiment establishes balance, fairness under latency, or retention.
Round-based versus persistent/infinite progression remains unresolved.

| File | Responsibility |
| --- | --- |
| `shared/Config.luau` | Frozen general tuning, runtime names, offsets, attribute names |
| `shared/UpgradeCatalogue.luau` | Typed IDs/readonly definitions, startup validation, availability/result text, purchase attribute names |
| `shared/SupplyRules.luau` | Frozen provisional event constants, validation, snapshot types, HUD text, neutral offset/runtime names |
| `server/Bootstrap.server.luau` | Starts the server runtime once |
| `server/TycoonRuntime.luau` | Player lifecycle, one income clock, prompt validation/throttling, replication, private results |
| `server/Session.luau` | Instance-free authoritative state and non-yielding assignment/release/purchase operations |
| `server/SupplyEvent.luau` | Supplied-time schedule, identities, phases, atomic resolution plus Session credit |
| `server/SupplyRuntime.luau` | Exact Player/assignment/character/range guards, separate event limiter/feedback, coherent snapshot and server-bound prompts |
| `server/SupplyWorld.luau` | Neutral footprint validation, anchored cache/marker and phase presentation |
| `server/PlotWorld.luau` | Placement validation, temporary geometry, reconciliation of pads and purchased visuals |
| `client/Bootstrap.client.luau` | Starts the HUD once |
| `client/Hud.luau` | Observes purchase attributes/results and current event snapshot; deadline countdown, separate feedback, safe scrolling catalogue |

No packages, persistence, exclusivity, combat, prestige, finale, or round/reset rules.
There are separate outbound purchase/event feedback RemoteEvents, no custom
purchase/claim remote, and no client-to-server event handler.

## Provisional catalogue and tuning

`UpgradeCatalogue` is the only source of prices, prerequisites, and income deltas:

| Stable ID | Name | Cost | Additional income/tick | Requires |
| --- | --- | ---: | ---: | --- |
| `income_booster` | Income Booster | 10 | +1 | None |
| `workshop` | Workshop | 30 | +3 | None |
| `booster_tuning` | Booster Tuning | 25 | +2 | Income Booster |
| `workshop_expansion` | Workshop Expansion | 60 | +5 | Workshop |

Both initial upgrades are independent. All four can be owned; choices concern
order, with no permanent specialization. Definitions, their array/index, and the
module are frozen. Validation rejects duplicate IDs, missing prerequisites,
cycles, and nonfinite/nonpositive/fractional costs or deltas with ID/field context,
before Session or Workspace state is created. Session takes a validated frozen
copy so later edits to constructor input cannot change a running economy.

`Config` retains **4 plots**, **0 starting cash**, **1 base income**, and a **1-second
tick**. Income is base plus the deltas of the actual purchase set: the original
booster changes 1 to 2; all four produce 12. Cash keeps accruing after completion.
One Heartbeat accumulator accrues completed intervals, including elapsed time
after a stall. Joining owners enter the server-wide cadence; their first tick
may arrive in less than one second. There is no offline income.

General presentation/adapter defaults: 10-stud server distance guard, 4-stud
prompt display/interaction radius, 0.25-second per-player request interval, and
3-second feedback lifetime. The smaller prompt radius and separated pads help
select an upgrade within the existing footprint; it does not replace server
distance validation. Excess requests are silently dropped, without kicks. The
limiter applies before character/session checks and bounds feedback too; leaving
clears it. No client cooldown grants eligibility.

## Purchase contract and replication

`Session.new(tuning, definitions)` takes `PlotCount`, `StartingCash`, `BaseIncome`
and catalogue records. State has `userId`, `plotId`, `cash`, `incomeRate`, and a
`purchases` set keyed by upgrade ID (replacing the single boolean).
`purchase(userId, plotId, upgradeId)` returns `(accepted, reason, missingCash)`.
Reasons: `inactive`, `not-owner`, `unknown-upgrade`, `locked`, `already-purchased`,
`insufficient-cash`, `purchased`; `missingCash` is zero except for insufficient cash.
The session resolves the definition, checks current assignment/ownership,
prerequisites, replay, and funds, then deducts, records, and adds income without
yielding. Rejections change none of cash, rate, assignment, or purchases. Rapid
requests cannot spend the same balance twice.

Each `Triggered` callback closes over a server-known plot/upgrade pair. The
runtime independently checks the exact active Player, a living character/root,
and distance to the anchored pad. There are no client-supplied prices/effects or
custom purchase payloads. Attributes and prompt visibility are presentation only.
See Roblox's [client/server boundary guidance](https://create.roblox.com/docs/scripting/security/client-server-boundary).

Server-written presentation attributes:

| Instance | Attributes |
| --- | --- |
| Assigned Player | `TycoonCash`, `TycoonPlotId`, `TycoonIncomeRate`, `TycoonAssignment = "Assigned"`, `TycoonPurchased_<id>` booleans |
| Full Player | `TycoonAssignment = "Full"`; economy/purchase attributes absent |
| Plot Model | Stable `TycoonPlotId`, optional `TycoonOwnerUserId`, `TycoonPurchased_<id>` booleans |

The old `TycoonUpgradePurchased` attribute and Config's `UpgradeCost`/
`UpgradedIncome` fields are removed; all call sites and type probes use the new
catalogue API. HUD ownership comes from purchased IDs, never an inferred rate.
On short viewports the catalogue scrolls while cash/income/results remain visible
inside the safe area. Assignment loss/change clears stale feedback and upgrade presentation. Respawns
preserve the session and one `ResetOnSpawn = false` safe-area HUD. Disconnect
removes every purchase, resets visuals/pads, and clears attributes/throttle state.
The next join can reuse the plot with a fresh economy. Full capacity still has no
waiting queue, income, or stolen ownership.

The runtime creates non-archivable `ReplicatedStorage/TycoonPurchaseFeedback`.
Its sole contract is server-to-requesting-client `(ownPlotIdOrNil, message)`;
there is no `OnServerEvent` listener and no broadcast. Only server-produced
results such as "Purchased Workshop", "Need 8 more cash", "Buy Income Booster
first", and "Not your plot" are sent after acceptance/rejection. Identical results
refresh the lifetime. A version counter ensures an old timeout cannot erase a
new message; results for a previous plot are ignored.

## Runtime geometry and player interaction

Walk approximately 42–54 studs toward world +Z from the authored spawn. Four
10×10 floors use the existing offsets. The reserved non-archivable
`Workspace/TycoonRuntime` owns all geometry. Startup checks the single spawn,
samples dry terrain at nine points per floor, and rejects collidable authored
objects before creating anything. Nothing is moved/carved or saved to the scene;
Rojo does not own Workspace. All pads/machines stay inside the inspected footprint.

Each plot has four separated, surface-labeled pads. The built-in ProximityPrompt
shows the upgrade, delta, and price/state near the selected pad; clickable prompts
support the built-in keyboard/gamepad/touch route. One-per-button exclusivity avoids
stacking prompt controls. Gray means locked/unowned, amber unaffordable, cyan
affordable, green purchased. Locked/unaffordable prompts stay usable to explain
rejection; purchased prompts retire. The HUD lists name/cost/delta plus each state.
Completion reads "Complete — income continues".

`PlotWorld.reconcile` reads the authoritative set, creating missing visuals and
removing absent ones. Income Booster is a green tower, Workshop a blue machine,
Booster Tuning a yellow cap, Workshop Expansion a wider purple top. Each is named
and labeled separately below the plot's `Upgrades` folder. Repeated reconciliation
does not duplicate parts; replicated current geometry is visible to late observers.
Owner reset reconciles an empty set, restoring every prompt and removing visuals.

## Calculated purchase orders (not playtest results)

Assume cash starts at zero, ticks are discrete, and each next purchase happens
immediately when affordable, with no walking or input delay:

| Order | Purchase ticks | Rates after each purchase | Completion cash/rate |
| --- | --- | --- | --- |
| Booster → Tuning → Workshop → Expansion | 10, 23, 31, 40 | 2, 4, 7, 12 | 6 cash, 12/tick |
| Workshop → Expansion → Booster → Tuning | 30, 45, 47, 49 | 4, 9, 10, 12 | 3 cash, 12/tick |

Enumerating all six valid orders under those assumptions gives the fastest
completion at tick 39 for Booster → Workshop → Tuning → Expansion. Workshop-first
orders finish at ticks 47–49. Early booster purchases are strongly favored by
this calculation; adding choices has not demonstrated a balanced economy or
strategic depth. These provisional numbers are intentionally unchanged.

## Provisional shared Supply Cache

This is one recurring server opportunity, not a round or reset. `SupplyRules`
is the single typed configuration location:

| Setting | Provisional value |
| --- | ---: |
| First opening after first assigned owner | 20 seconds |
| Scheduled opening interval | 30 seconds |
| Warning | 5 seconds |
| Claim window | 10 seconds |
| One-time reward per event | 10 cash |
| Public/private event result duration | 3 seconds |
| Prompt/server claim radius | 6 studs |
| Separate per-player event request interval | 0.25 seconds |

Every numeric value must be finite and positive; reward must be an integer.
FirstDelay must exceed Warning, and Interval must exceed Warning + Window +
ResultDuration. Rules and constructor snapshots are frozen. Invalid tuning fails
before the runtime starts. No upgrades, prices, income rules or tool pins change.

The first assigned owner anchors time T: warning T+15, open T+20, expiry T+30,
next openings T+50/T+80. An early winner gets a three-second result, without
accelerating the next opening. Join/respawn does not reset the live anchor. If
the last assigned owner leaves, the event is cancelled with no reward, its ID is
invalidated, and a later first assignment gets a new T+20 schedule. Unassigned
full-capacity players neither keep it alive nor receive rewards; no queue is added.

`SupplyEvent.new(tuning)` owns an Instance-free deadline state machine.
`sync(now, assignedCount)` resolves `idle`, `waiting`, `warning`, `open`, or
`result`, using supplied finite, nonnegative, monotonic time. `snapshot()` returns
a frozen record: `id`, `phase`, `opensAt`, `closesAt`, `nextOpensAt`, `deadline`,
`reward`, and optional `winnerUserId`/`winnerName` during the result. Idle deadlines
are explicitly zero. Expiry has no winner. After the result, countdown targets
the next scheduled opening; a new ID is prepared at its warning. Delayed frames
jump directly to the current warning/window, skipping missed opportunities with
no backlog, offline payout or catch-up loop. `[opensAt, closesAt)` is authoritative.

`claim(session, userId, name, boundId, now)` returns `(accepted, reason)` with
`claimed`, `inactive`, `stale`, `closed`, or `already-claimed`. It resolves the
current deadline and ID, verifies an assigned unclaimed window, calls the narrow
`Session.credit(userId, amount)`, then records the winner without yielding.
Credit rejects inactive/replaced owners, accepts only finite positive integer
amounts, and changes cash only. `Session.assignedCount()` reports current owners.
The reward neither unlocks purchases nor changes income or another owner's cash.
An inactive/failed credit cannot consume the event.

Actual arbitration is **first valid request processed by the server**. It does
not establish the first local press, network-latency fairness, or compensation.
The adapter captures each ID in that event's server-created prompt callback; it
does not trust prompt attributes/Enabled/display range. It checks exact active
Player identity, current Session assignment, living Humanoid/root and six-stud
distance to the anchored cache. No client winner, amount, time, or deadline is
accepted. HoldDuration is zero. Per-player event requests/feedback are bounded
independently of purchases; the event limiter is cleared on leave. Excess requests
are dropped without punitive kicks. Rejections explain a needed plot, respawn,
distance, closed/stale event, or prior winner where meaningful.

Non-archivable `ReplicatedStorage/TycoonSupplyState` is a **StringValue** holding
one atomic server-authored JSON snapshot; its `Position` Vector3 attribute locates
the cache. This avoids reading half-written attribute bundles. The server writes
on snapshot changes, not a replicated decrementing countdown. Clients subscribe
before initial read, so late joins/respawns hydrate the current phase/result.
`Workspace:GetServerTimeNow()` drives both server deadlines and local countdown
display; client zero never opens or pays. See the [Workspace time API](https://create.roblox.com/docs/reference/engine/classes/Workspace#GetServerTimeNow).

`ReplicatedStorage/TycoonSupplyFeedback` is outbound only to the requester:
`(currentEventId, serverMessage)`. Public result comes from the replicated snapshot,
not arbitrary broadcasts through the purchase-only remote. Its private message
occupies the event line, with a separate versioned timeout; new event IDs or
assignment changes clear stale messages. Purchase feedback retains its own label
and timeout. The HUD grows up to 300 pixels; on short viewports, at least one
catalogue row remains scrollable below cash/status/event text and above purchase
results. Safe-area clipping and the one respawn-retained HUD are preserved.

### Shared scene location and design limits

`Workspace/TycoonRuntime/SupplyCache` owns the temporary 6×6 floor, one anchored
primitive cache, built-in prompt and labeled marker. It is 28 studs toward world
+Z from the unchanged authored spawn. Before writes, nine terrain samples must
be dry and the seven-stud-high footprint must contain no authored collidable part.
Reserved state/feedback/world names are checked. Runtime creation also verifies
the actual purchase prompts are outside the combined cache/pad radii, without
duplicating their layout. Marker text and color distinguish warning, open, result
and waiting. No forced player teleport, camera control, terrain edits or scene save
is part of gameplay. QA may relocate test avatars to set up input probes.

Inspected horizontal distance from plot centers is approximately 15 studs for
the front pair and 27 for the rear pair. This is obvious travel asymmetry, not
perfect fairness. Camping and repeat wins are possible; neither is silently
prevented. Ordinary income continues while away from a plot, so the trip does not
create an income opportunity cost. Rewards after completing all upgrades still
have no further spending use. No endgame/shop, rebalancing, paid advantage,
persistence, round rules, telemetry, or GAMEPLAY-04 feature is added.

The preceding purchase-order table is unchanged **without events**. A separately
calculated early reward example: an unupgraded owner with 20 ordinary ticks has
20 cash; one first-window +10 reward reaches Workshop's 30-cost milestone at tick
20 rather than tick 30, then buying Workshop gives cash 0 and rate 4. This assumes
an immediate claim/purchase and no travel/input delay. Runtime observations and
actual measured ticks are recorded separately in the PR, not substituted for this
arithmetic. The event has not proven balanced orders, strategic depth or fun.

## Validation and short Studio playtest

Run `./scripts/Validate-Project.ps1`. It formats/lints/type-checks `src` and `tests`
and validates the original three-folder build; it does not execute tests or gameplay.
Tool versions, API definitions, strict pragmas, and nullable guards remain intact.

`tests/Session.spec.luau` is outside Rojo. Load its exact file into a temporary
ModuleScript outside the owned folders in a disposable Studio server context.
Invoke the returned function with actual mapped modules:

```luau
local ok, count = xpcall(function()
    return require(testModule)(
        require(game.ServerScriptService.TycoonServer.Session),
        require(game.ReplicatedStorage.TycoonShared.Config),
        require(game.ReplicatedStorage.TycoonShared.UpgradeCatalogue)
    )
end, debug.traceback)
testModule:Destroy()
if not ok then error(count) end
print("Session assertions passed:", count)
```

It exercises original booster behavior, both initial choices, locked prerequisites,
exact deductions/additive rates for different orders, mutation-free rejection,
rapid spending, independent owners, respawn retention, reset/reuse, and invalid
catalogue construction. Test typing/formatting is distinct from observed execution.

Use a filesystem copy of `place/tycoon.rbxlx`; connect Rojo to the task checkout
and verify exact source before Play. Never save Play geometry or QA code.

1. Solo: approach pads and use normal keyboard input. Attempt locked/unaffordable
   options, buy Booster → Tuning → Workshop → Expansion, check result text,
   distinct visuals, 12 income and completion. Respawn: one HUD and retained state.
2. Two clients: give the other owner Workshop → Expansion → Booster → Tuning.
   Check independent deductions/rates, prerequisite states, and both observers'
   replicated visuals. Test funded non-owner and duplicate attempts through the
   actual prompt adapter (a disposable client-only re-enable can probe replay).
3. Lifecycle: real `StudioTestService:LeaveTest` then `AddPlayers`, as in GAMEPLAY-01,
   to disconnect an owner and observe a replacement after assignment. Verify
   reused plot, fresh cash/rate, no old visuals/feedback, and unaffected neighbor.
4. Stop/restart: no runtime folder, feedback remote, HUD, or temporary QA module
   remains in Edit; the next run starts fresh. Inspect relevant server/client logs.

Reserve Studio Script Analysis for concrete analyzer discrepancies, Studio-owned
scripts/context, or integration issues. Do not require the panel after ordinary
Git-source changes. A programmatic purchase is domain/adapter evidence, not normal
player input. Record normal desktop interaction, HUD viewport inspection, emulated
touch, and physical-device testing separately. Actual touch is supplementary;
disclose it when unavailable. Required unobserved runtime gates keep the PR open.

For the event suite, load exact `tests/SupplyEvent.spec.luau` into a temporary
server ModuleScript outside the owned folders and invoke its returned function
with actual `SupplyEvent`, `Session`, `SupplyRules`, and `UpgradeCatalogue` modules,
using the same `xpcall`/destroy/rethrow route above. It exercises supplied-time
warning/open/expiry/cadence, exclusive closing boundaries, stale IDs, delayed
frames, competing/replayed claims, exact credit without other mutation,
inactive/full players, join/respawn/replacement/cancellation, and invalid rules/
times/credits. Keep the original Session suite running too. Neither runs in CI.

For a two-player playtest, start Studio Server & Clients with two clients (or
supported `StudioTestService:ExecuteMultiplayerTestAsync(2, testArgs)`). Observe
one shared marker/countdown. Move both avatars near the cache, use their normal
prompts when open, and check one server-confirmed +10 payment/shared winner.
Let the other owner win the next event; try an expired event, then a normal
upgrade purchase. Check an ignored expiry, continued ordinary income, and no
extra payout on replay. For adapter range QA only, a temporary Play-only increase
of the prompt's display/engine distance can let a far-away request reach the
unchanged six-stud server guard; restore it afterward and distinguish this probe
from normal player input. Client-only re-enable can probe a closed/claimed prompt.

Join another real client during warning/open; compare its current snapshot/HUD.
Respawn and check one HUD/current schedule. Use real LeaveTest/AddPlayers to
verify replacement starts fresh while another owner preserves the anchor; remove
all assigned owners to verify cancellation, then add one to verify new T+20.
Inspect logs, stop/restart, and confirm Edit has no runtime cache/state/QA objects
and all live script strings match the checkout. Never save temporary QA code.
Check phone portrait/landscape HUD and the supported emulated Touch prompt route;
report physical-device testing separately, without inventing a new merge gate.
