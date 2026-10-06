# Session tycoon prototype

This source tree owns gameplay inside the existing three code-only Rojo folders.
Bootstraps compose the feature and retain the setup startup messages. GAMEPLAY-02
is a reversible upgrade-order experiment; costs, names, and prerequisites below
are provisional. Technical tests do not establish balance, strategic depth, or fun.
Round-based versus persistent/infinite progression remains unresolved.

| File | Responsibility |
| --- | --- |
| `shared/Config.luau` | Frozen general tuning, runtime names, offsets, attribute names |
| `shared/UpgradeCatalogue.luau` | Typed IDs/readonly definitions, startup validation, availability/result text, purchase attribute names |
| `server/Bootstrap.server.luau` | Starts the server runtime once |
| `server/TycoonRuntime.luau` | Player lifecycle, one income clock, prompt validation/throttling, replication, private results |
| `server/Session.luau` | Instance-free authoritative state and non-yielding assignment/release/purchase operations |
| `server/PlotWorld.luau` | Placement validation, temporary geometry, reconciliation of pads and purchased visuals |
| `client/Bootstrap.client.luau` | Starts the HUD once |
| `client/Hud.luau` | Observes attributes/results, displays own-plot catalogue and feedback |

No packages, persistence, exclusivity, combat, prestige, finale, or round/reset rules.
There is one outbound feedback RemoteEvent and no custom purchase remote.

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
