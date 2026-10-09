# Infinite-mode persistence

This subsystem owns account data and the lifetime of the server's write permission.
`Session` still owns cash and the income clock; `PropertyWorld` renders Infinite
in the currently assigned lot's frame. Neither a lot number nor an Instance is saved.

| File | Owns |
| --- | --- |
| `ProfileSchema.luau` | v1→v2 migration, strict data validation, detached snapshots, individually owned objects and local footprints |
| `LegacyProfile.luau` | Frozen v1 validator and four-asset slot capture used by the migration |
| `ProfileStore.luau` | Atomic load/lease acquisition, fenced checkpoint/final writes, retry ordering and confirmations |
| `Profiles.luau` | Loading reservations, ready/full/unavailable states, stale arrival/save callbacks, final saves and shutdown |
| `DataStoreBackend.luau` | Roblox UpdateAsync adapter, metadata preservation and Studio destination guard |
| `Settings.luau` | Store name, isolated Studio universe allowlist and bounded timing policy |

## Mode and setup

The existing prototype remains the default. To select infinite mode **before Play**,
add one Studio-owned `StringValue` named `TycoonMode` in `ReplicatedStorage`, with
value `Infinite`. Missing means `Prototype`; wrong type/value fails loudly. Mode
is fixed for the server/client session. Do not hot-swap it. This object is outside
the three code-owned Rojo folders. Infinite mode creates no SupplyCache world,
state or event remote; its HUD binds only purchase feedback and shows saving status.

Real saving uses `DataStoreService:GetDataStore("InfiniteProfiles_v1")` and account
keys `user_<UserId>` within the current universe. No migration from the session-only
prototype is possible: it never stored departing players' progress. No dependency,
offline earnings or experiment mechanics are added. INF-02 adds the owner-only editor.

`StudioTestUniverseId = 0` deliberately disables real Studio access. Set it to the
**universe ID, not the place ID**, of an isolated published test experience that
contains no production player data. The owner must enable Studio API Services for
that test experience. An unpublished local place (`game.GameId == 0`) or another
Studio universe becomes `Unavailable` without a DataStore request. Never enable
Studio API access to production for QA. Hosted servers use the same store within
their own universe; publication/deployment requires separate authorization.

The disposable `New-InfiniteReviewPlace.ps1 -Backend LocalPreview` explicitly injects
a memory fixture outside the owned source tree, disables only its copied bootstrap,
and labels the HUD **Local preview • changes last only this server**. It is playable
without API access and clears on Stop. It is never selected after a failed real load.
`-Backend DataStore` includes the unchanged production bootstrap and no memory
fixture unless `-IncludeQA` explicitly requests isolated assertion modules.

## Version 1 migration input

```lua
{
    version = 1,
    data = {
        version = 1,
        cash = 91,
        assets = { income_booster = true, workshop = true },
        placements = { income_booster = "west_front", workshop = "east_front" },
    },
    lease = { token = "unique-per-arrival-GUID", expiresAt = 1700000120 },
    lastWrite = { token = "unique-per-arrival-GUID", sequence = 4 },
}
```

New checkpoints keep the **same store and user keys**, envelope version 1 and lease
protocol, but write data version 2. Cash, four assets and named slots survive.
Each legacy asset gains a stable `legacy_<content>` object at its old local slot
coordinates. The slots remain migration metadata; accepted movable transforms
live in `objects`. New copies use monotonic `o1`, `o2` identities.
`nextId`, `revision`, `theme` and object content/X/Z/quarter-turn/stored fields
are validated; no Instances, lot IDs or world transforms are saved. At most 48
objects and bounded primitive fields keep data below 16 KiB (the regression suite
also measures serialization as content grows). Revision max is 2^53−1, object
serial max 1,000,000. The editor explains limits and preserves existing objects.
Old servers refuse v2 data; newer unknown schema/content refuses without writing.
Deploy compatible servers together before enabling hosted access.

Moving/storing does not alter ownership or income. Base income always continues;
decoration spending cannot prevent eventual progress. Arrival epochs are separate
from the private DataStore lease token. An accepted edit is only an in-server
change until the existing scheduler confirms a checkpoint; there is no second saver.

`lease` is absent after a confirmed departure. `lastWrite` is an idempotency receipt,
not an income timestamp. `cash` is a nonnegative exact integer at most 2^53−1.
Infinite-mode income saturates at that technical ceiling so a valid loaded balance
can always be saved again; ordinary Prototype has no new cap. Out-of-range stored
data is still rejected, never clamped on load. Assets
are true-only keys from `UpgradeCatalogue`, including all required prerequisites.
Placements map each owned asset to one unique slot: `west_front`, `east_front`,
`west_back`, `east_back`. Defaults follow the existing layout. Ownership and slot
selection are separate; restored swapped slots do not depend on purchase order.
The fixed starter machine is implicit in the layout and base income.

Unknown versions/fields/IDs, malformed locks, invalid money and invalid layouts
are refused without writing. There is no silent repair or lossy downgrade. A future
schema must add an explicit migration. Live income is always rebuilt from trusted
catalogue deltas. Fresh 0 cash/no assets is allowed only inside a successful atomic
load of a truly absent key. Defaults are never used after a service error.

## Ownership, retries and failure behavior

Every arrival gets a fresh GUID, including same-server rejoins. `UpdateAsync` claims
and reads one validated envelope atomically. A live foreign lease causes bounded
waiting then `Unavailable`; the client can rejoin. There is no forced takeover.
After 120 seconds without renewal, another server may acquire the latest committed
data. Every subsequent write requires the exact token and an unexpired lease,
including when a successor has already released it. Servers use Unix seconds for
the lease and stop gameplay 15 seconds before local expiry. This assumes Roblox
server clocks are sufficiently aligned within that margin; it is not a promise
against arbitrary clock failure. Atomic token checks always fence actual writes.

Each account has at most one save operation in flight; its retries complete before
the final departure snapshot. Four attempts use delays of 2–3, 4–5 and 8 seconds.
Service request latency is controlled by Roblox and can extend these durations.
Only external DataStore calls are converted to explicit failures; internal defects
are rethrown. A receipt confirms a committed operation whose response was lost;
retrying it preserves any successor's data/lease. Failed loads never get a Session
state. Failed checkpoints remain visibly unconfirmed; failure to renew safely ends
the live economy and clears the lot. A delayed result cannot revive that entry.

Loading arrivals reserve capacity without earning/spending. A 45-second logical
arrival deadline frees that reservation and reports Unavailable even if Roblox
has not returned yet; a late successful claim is released without assigning a lot.
Full arrivals never
load a profile. Full/unavailable players have no waiting queue; rejoin to retry.
Departure invalidates the entry before releasing the Session/lot, then saves the
captured property. An arrival that completes after departure releases its claim
without assigning a lot. Autosaves are due every 30 seconds after the previous
operation completes; normal income/purchases stay in memory. Shutdown stops new
arrivals, starts final saves concurrently across accounts, and waits up to 25 seconds.
Unfinished/failed writes warn as **unconfirmed**, never as saved; crashed servers'
leases recover by expiry.

Healthy crash loss is about one 30-second checkpoint interval plus request latency.
During an outage, all changes since the last confirmed write may be lost; gameplay
stops at the lease safety margin. A completed purchase is an in-memory transaction,
not a guarantee that a checkpoint has reached Roblox. There is no offline accrual,
trading, paid currency or immediate per-purchase persistence in this slice.

## Verification references

`tests/Persistence.spec.luau` tests schema, restoration, ownership and ambiguous/
failed writes. `ProfileLifecycle.spec.luau` controls coroutine order around loading,
capacity, departure, reuse, autosaves and shutdown. Both use an explicitly injected
serialized memory fixture; they do not prove Roblox durability. `InfiniteState`
tests readiness/failure presentation. Existing Session and SupplyEvent regressions
must still execute. See [INF-01 review](../../../docs/INF_01_REVIEW.md) for observed
Studio evidence and remaining published-test gates.

Platform basis: [Roblox DataStores](https://create.roblox.com/docs/cloud-services/data-stores)
and [session ownership/retries](https://create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing),
consulted 2026-10-09. This implementation is project-specific; it does not copy the
reference system or add a generic persistence framework.

## INF-03 content revision

Data v3 accepts/migrates v1 and v2 intentionally. It retains legacy slot metadata and every individual object/appearance, with the same store and key identity. The 64-total/48-decoration limits reserve space for progression after a full v2 inventory. Retired catalogue definitions remain decodable/renderable and keep their trusted income, while new purchases are refused. Older servers refuse v3; no lossy downgrade path is offered.
