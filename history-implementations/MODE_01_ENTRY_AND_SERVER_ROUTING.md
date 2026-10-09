# MODE-01 — Mode Entry and Server Routing

## Direction

Build the entry flow for one Roblox experience with two clear choices:

- **Session — Challenge:** the existing session prototype, preserving its present growth and management.
- **Infinite — Curiosity:** the relaxed, saved personal-space mode developed by INF-01–INF-03.

The intended hosted behavior is a chooser followed by a server dedicated to the selected mode. Everyone in a gameplay server shares that server's mode. An individual's choice must not switch the mode of other players already playing.

Keep the entry explanation short and truthful. The Session prototype does not yet implement every planned round/finale mechanic, so do not advertise those as existing. Infinite saving labels must reflect the backend actually running.

## Starting point and continuous work

Inspect AGENTS.md and current repository state. Stack an isolated implementation branch/worktree on current INF-03, or updated main if its predecessors have merged. Open a draft PR into main, record the immediate predecessor's tested head, identify inherited changes and link a comparison that isolates this slice. Keep all experiments separate.

This is implementation work before the combined founder review. Continue without asking for approval of routine routing or UI decisions. Do not merge the gameplay stack, publish an experience, change hosted configuration or create external destinations under this instruction.

At briefing time there are no supplied isolated published test destinations. Complete code, configuration, reproducible entry/destination previews, and service-independent tests anyway. Record the real-service setup and observations still needed; do not turn absent destinations into fake successful teleports or weaken INF-01's saving guards.

## A working choice and recoverable transition

Implement a readable, responsive mode chooser, with clear joining/busy/failure behavior. Prevent repeated clicks from creating competing transitions. A failed or cancelled transition should leave the player in an understandable, usable state with a retry path.

Prepare the trusted server configuration and place/build setup for an entry place and mode-specific gameplay destinations within the same experience. Resolve mode on the server from trusted destination configuration, not from a client declaration or an event dependency being absent. Preserve existing direct Studio previews and the ordinary Prototype default used by the repository.

Let Work choose the simplest modular router suitable for Roblox. Validate allowed destinations and make missing/invalid configuration explicit. Keep production routing distinct from local test adapters. Consult current official Roblox guidance for teleporting between places and its testing limits before implementation.

Give players an understandable way to leave gameplay for mode selection when the infrastructure supports it. Going between modes must never reset Infinite progression or copy its cash/assets into Session. Session progression keeps its existing session-only behavior; returning does not imply a new persistence contract.

Coordinate departure from Infinite with INF-01's confirmed-write and session-ownership policy. An unconfirmed final save must not display as success, and an arriving server must not bypass an active lease. Handle the overlap between teleport arrival and source-server departure using the existing ownership rules. If saving or routing is unavailable, fail truthfully and preserve the playable source state rather than granting a fresh profile or force-expiring another writer.

## Evidence and handoff

Provide reproducible entry, Session and Infinite review previews built from the stack. Exercise choice, retry, duplicate activation, missing destination, rejected route and save-related transition failures through clear test seams. Observe actual desktop/mobile chooser behavior and ensure the normal gameplay UI remains usable.

Verify each gameplay destination starts with only its intended mode behavior: Session retains its economy/event flow; Infinite restores personal space and remains calm. A Studio adapter can verify routing intent and lifecycle decisions, but is not a real cross-server teleport or DataStore durability pass.

Deliver concise setup instructions for the later isolated published test, exact revisions, a draft PR, and one combined review guide covering INF-01, personalization, growth and entry. Keep available automated/Studio evidence separate from the remaining live persistence/teleport and human play checks.

The owner should be able to return to a substantial playable stack, not a collection of empty menus. Stop after this queue is implemented, checked and handed off; more systems beyond this scope need a new direction.
