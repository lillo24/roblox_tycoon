# First playable tycoon slice

This source tree owns runtime gameplay inside the existing three code-only Rojo
folders. Bootstraps compose the feature and retain the setup startup messages.

| File | Responsibility |
| --- | --- |
| `shared/Config.luau` | Frozen prototype tuning, runtime names, plot offsets, and replicated attribute names |
| `server/Bootstrap.server.luau` | Starts the server runtime once |
| `server/TycoonRuntime.luau` | Connects player lifecycle, one income clock, validated prompt purchases, and state replication |
| `server/Session.luau` | Instance-free server session state and atomic assignment/release/purchase operations |
| `server/PlotWorld.luau` | Validates placement, generates temporary plots, and presents ownership/upgrades |
| `client/Bootstrap.client.luau` | Starts the HUD once |
| `client/Hud.luau` | Creates a responsive HUD and observes attributes; never sends economy values |

There are no remotes, packages, persistence, or round/reset rules. The broader
round-based versus persistent/infinite design remains unresolved.

## Prototype tuning and gameplay

`shared/Config.luau` is the tuning source of truth: **4 plots**, **0 starting cash**,
**1 cash per one-second tick**, **10 cash** for the one Income Booster, and
**2 cash per tick** afterward. These are temporary defaults. One shared Heartbeat
accumulator accrues completed intervals, including elapsed intervals after a
stall. A new owner joins the server-wide cadence; their first tick can occur in
less than one second. There is no offline income.

Walk from the authored spawn toward world +Z, approximately 42–54 studs, to the
four colored plots. Stand near your yellow purchase pad and use its built-in
ProximityPrompt (keyboard, gamepad, or touch). The HUD shows cash, plot, income,
and the price. Before 10 cash, interaction has no effect. A successful purchase
deducts 10 once, creates one green `IncomeBooster`, turns the pad green, disables
its prompt, and doubles income. Ownership persists through character respawns.

If all plots are occupied, a join gets `TycoonAssignment = "Full"`, no economy
attributes/income, a HUD explanation, and a server warning. Existing owners keep
their plots. There is no waiting queue in this slice; a later join can claim a
released plot. Leaving clears the player's attributes and resets the plot,
including removing the booster. The next owner starts fresh.

## Runtime ownership and authority

`Workspace/TycoonRuntime` is reserved for this feature and must not already exist
in the authored scene. Startup fails with context if it does. The server creates
it once with `Archivable = false`; all four Models, anchored primitive parts,
ownership signs, prompts, and boosters live below it. It disappears when Play
stops. The client creates only `PlayerGui/TycoonHud`, with `ResetOnSpawn = false`.
Neither is permanently authored into the place.

Plot centers use Config's world X/Z offsets from the single authored spawn.
Their 10×10 floors sit 0.1 studs above the maximum dry-terrain height sampled at
nine points. Before generating anything in Workspace, startup checks all plot
volumes for collidable authored parts and fails with the offending plot/path
if a scene change blocks placement. Terrain and existing models are never moved
or carved. The prototype requires the current scene's single spawn and dry
terrain; updating the scene may require updating offsets and repeating QA.

Server-written attributes are **presentation copies**, not purchase inputs:

| Instance | Attributes |
| --- | --- |
| Assigned Player | `TycoonCash`, `TycoonPlotId`, `TycoonIncomeRate`, `TycoonAssignment = "Assigned"` |
| Unassigned/full Player | Only `TycoonAssignment = "Full"`; cash, income, and plot attributes are absent |
| Plot Model | Stable `TycoonPlotId` (1–4), optional `TycoonOwnerUserId`, `TycoonUpgradePurchased` |

The Session table in ServerScriptService owns the truth. The prompt adapter checks
that the exact Player is still active, has a living character, and is within
10 studs of the anchored pad. The session then checks current assignment,
ownership, cash, and the one-time flag. Deduction/application do not yield, so
duplicate triggers cannot charge twice. Client visibility and attributes cannot
grant a purchase. Only `Triggered` is used; see Roblox's
[client/server boundary guidance](https://create.roblox.com/docs/scripting/security/client-server-boundary).

## Validation and Studio QA

Run `./scripts/Validate-Project.ps1` from the checkout. Formatting/lint covers
`src` and `tests`; the build still owns exactly the original three folders.
`tests/Session.spec.luau` is deliberately outside the Rojo mapping. It returns a
function `(Session, Config) -> assertionCount` and exercises capacity, stable
assignment, income, rejected purchases, exact deduction, replay, and reuse.

Run that test in a disposable Studio playtest/server context by creating a
temporary ModuleScript outside `TycoonServer`, setting its Source to the test
file through the command bar or official MCP, then invoking:

```luau
local count = require(testModule)(
    require(game.ServerScriptService.TycoonServer.Session),
    require(game.ReplicatedStorage.TycoonShared.Config)
)
print("Session assertions passed:", count)
testModule:Destroy()
```

Remove the temporary module even on failure; do not save it or add it to the
mapping. It is not an autorun script or production test backdoor. CI formats/lints
these tests but does not execute Roblox runtime code; observed Studio execution
is recorded in the gameplay PR.

For runtime QA, open a disposable filesystem copy of `place/tycoon.rbxlx`, connect
Rojo to this task checkout, and inspect exact synced sources before Play. Observe
the four unique plots, one assignment, base income, HUD, insufficient-cash attempt,
one purchase, one booster, increased income, and duplicate rejection. Inspect
server state directly and Script Analysis separately. Repeat with two clients:
different plots, funded non-owner rejection, independent purchases/income, and no
server/client errors. Disconnect an owner and add another client to verify reset,
reuse, and fresh cash; an equivalent observed lifecycle test is acceptable when
Studio cannot replace the client. Stop afterward and verify no runtime content
remains in Edit. Device simulation can observe HUD and built-in touch prompts;
record actual input observation separately from API compatibility.
