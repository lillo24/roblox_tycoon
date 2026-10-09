# MODE-01 — Mode Entry and Server Routing

Reviewed continuation brief — 2026-10-09. Use this version from latest `main` together with INF-02 and INF-03.

## Direction

Build the entry flow for one Roblox experience with two clear choices:

- **Session — Challenge:** the existing session prototype, preserving its present growth and management.
- **Infinite — Curiosity:** the relaxed, saved personal-space mode developed by INF-01–INF-03.

The intended hosted behavior is a chooser followed by a server dedicated to the selected mode. Everyone in a gameplay server shares that server's mode. An individual's choice must not switch the mode of other players already playing. These are shared social lobbies: use ordinary public gameplay servers unless there is a demonstrated need otherwise, not a new private server for every selecting player. Custom matchmaking, parties and a cross-server property browser are outside this slice.

Keep the entry explanation short and truthful. The Session prototype does not yet implement every planned round/finale mechanic, so do not advertise those as existing. Infinite saving labels must reflect the backend actually running.

## Starting point and continuous work

Inspect AGENTS.md and current repository state. Stack an isolated implementation branch/worktree on current INF-03, or updated main if its predecessors have merged. Open a draft PR into main, record the immediate predecessor's tested head, identify inherited changes and link a comparison that isolates this slice. Keep all experiments separate.

This is implementation work before the combined founder review. Continue without asking for approval of routine routing or UI decisions. Do not merge the gameplay stack, publish an experience, change hosted configuration or create external destinations under this instruction.

At briefing time there are no supplied isolated published test destinations. Complete code, configuration, reproducible entry/destination previews, and service-independent tests anyway. Record the real-service setup and observations still needed; do not turn absent destinations into fake successful teleports or weaken INF-01's saving guards.

## A working choice and recoverable transition

Implement a readable, responsive mode chooser, with clear joining/busy/failure behavior. Prevent repeated clicks, stale callbacks and retry handlers from creating competing transitions. Handle both an immediate teleport error and a later `TeleportInitFailed`; an accepted API call is not proof of arrival. Bound retries and give an actionable recovery path. Offer cancellation only while it can truthfully be honored, not as a promise to undo a teleport already in progress.

Prepare the trusted server configuration and place/build setup for an entry place and mode-specific gameplay destinations within the same experience. Resolve mode before gameplay starts, using trusted destination configuration, not a client declaration, teleport payload or an event dependency being absent. The entry place must not allocate a factory, earn income, run SupplyCache or acquire an Infinite profile lease. Session must not load/write Infinite progression. Preserve existing direct Studio previews and the ordinary `Prototype` default; `Session` is its player-facing name, not permission to redesign its rules.

Let Work choose the simplest modular router suitable for Roblox. Validate allowed destinations and make missing/invalid configuration explicit, including self-routing loops and place-role mismatches. Keep production routing distinct from local test adapters. Consult current official Roblox guidance for teleporting between places and its testing limits before implementation.

Keep Infinite data in its existing universe/store/account-key scope. A different place in the same experience is not an isolated data environment, and teleport data must never be trusted as the player's balance, inventory or write permission. Use a separate test experience for the later real-service checks. Document destination access settings, direct/friend-join behavior and player limits consistent with available lots. Destinations must start correctly without assuming a chooser payload is always present. Full or unavailable arrivals need an understandable way back/retry, with no fresh-profile fallback or silent teleport loop; elaborate seat reservation is not required.

Give players an understandable way to leave gameplay for mode selection when the infrastructure supports it. Going between modes must never reset Infinite progression or copy its cash/assets into Session. Session progression keeps its existing session-only behavior; returning does not imply a new persistence contract.

Treat departure from Infinite as part of the implementation, not merely a call to its existing leave handler. At the reviewed INF-01 head, `Profiles.leave` removes the live entry/lot and starts an asynchronous final save; that alone cannot support a recoverable mode switch. Coordinate in-flight saves, accepted edits, income and the last snapshot so newer changes cannot be lost behind a supposed final checkpoint.

Choose and document a bounded handoff policy: confirm the intended progress before an intentional departure, preserve single-writer ownership through source/destination overlap, and recover from failure without granting a fresh profile or force-expiring another writer. If a lease has been released, normal earning/editing may resume only after safely reacquiring current data; retaining an old in-memory snapshot is not sufficient. If safe recovery is unavailable, show an explicit unavailable/retry state instead of promising the source remains playable. Do not rely only on `PlayerRemoving`, assume arrival occurs after release, or present an unconfirmed write as saved. Preserve INF-01's honest crash-loss limits; this task does not promise zero loss after a server crash.

## Evidence and handoff

Provide reproducible entry, Session and Infinite review previews built from the stack. Exercise choice, retry, duplicate activation, missing/rejected destinations and both immediate and late teleport failures. Cover a save failure before departure, failed teleport after lease release, destination arrival before source cleanup, and stale callbacks after a retry/departure through controlled test seams. Observe actual desktop/mobile chooser behavior and ensure the normal gameplay UI remains usable.

Verify each gameplay destination starts with only its intended mode behavior: Session retains its economy/event flow; Infinite restores personal space and remains calm. A Studio adapter can verify routing intent and lifecycle decisions, but is not a real cross-server teleport or DataStore durability pass.

Deliver concise setup instructions for the later isolated published test, exact revisions, a draft PR, and one combined review guide covering INF-01, personalization, growth and entry. Keep available automated/Studio evidence separate from the remaining live persistence/teleport and human play checks.

The owner should be able to return to a substantial playable stack, not a collection of empty menus. Stop after this queue is implemented, checked and handed off; more systems beyond this scope need a new direction.

Platform references, checked 2026-10-09: [teleport behavior and testing limits](https://create.roblox.com/docs/projects/teleport), [DataStore scope and test isolation](https://create.roblox.com/docs/cloud-services/data-stores), and [player-data ownership/retries](https://create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing). Recheck current guidance when implementing; these are behavioral constraints, not instructions to copy a reference architecture.
