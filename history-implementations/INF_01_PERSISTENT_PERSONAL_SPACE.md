# INF-01 — Infinite Mode: Persistence and Plot Logistics

## Intent

Build the first playable foundation for a **relaxed, persistent mode** in `lillo24/roblox_tycoon`: players keep growing their own place, and others can visit and admire it. There is no required reset, final winner, or compulsory event involving the whole lobby.

Personalization matters: the eventual game should support distinct places and choices, rather than one purchase sequence that makes every property identical. This first slice establishes trustworthy ownership and continuity before adding a builder or a larger economy.

**Working assumption:** “logistics” here means saving/restoring the player's place, assigning it a lobby lot, and separating owner actions from visitor access. Production chains, conveyors, and resource transport are a later design question.

## Starting point and isolation

Inspect current repository state before implementation. At briefing time, `main` (`c6c2aee`) stores cash and purchases only in the server session; leaving clears them. Its catalogue has four one-time upgrades, so persistence alone will not make progression infinite.

The owner superseded the original starting-point instruction on 2026-10-09: first reconcile,
validate and merge [PR #11](https://github.com/lillo24/roblox_tycoon/pull/11), then start INF-01
in a fresh isolated worktree from updated main. PR #11 merged as `36a5caa` after full local
validation and required CI; its remaining manual QA is documented follow-up. INF-01 starts
from that shared six-lot/UI foundation. Keep [experiment PRs #14–#16](https://github.com/lillo24/roblox_tycoon/pulls)
and their worktrees separate. INF-01 remains a draft for review; no game publication is authorized.
This replaces only the starting-point requirement, not the scope or evidence requirements below.

Follow repository boundaries and reuse established server-authoritative purchase/economy behavior. Leave module choices and the detailed implementation to Work.

## The first playable slice

### A saved place, a temporary lobby lot

Treat the player's account as the owner of the property. A numbered lot belongs only to the current server session: joining another server or receiving another oriented lot must restore the same property correctly.

Save cash and owned assets using stable identifiers. Validate and version saved data; derive live income from trusted catalogue rules. Keep ownership distinct from placement assumptions so future rearrangement or decoration does not depend on purchase order. Choose the simplest representation that supports this direction; a full placement editor is outside this slice.

Use the existing default layout and upgrades to prove restoration. Do not save world Instances or bind progress to a server's lot number. New players receive the documented starting state only after a successful load confirms they have no existing profile.

### Reliable arrival, departure, and recovery

Make loading, ready, full-lobby, and unavailable states explicit. Purchases and income start only when the player's profile and lot are ready. A failed or invalid load must never become an apparently new account that overwrites previous progress.

Ensure one authoritative writer owns each active profile across servers. Handle rapid rejoin while the old server is still saving, competing loads, and stale callbacks after lot reuse. Choose and document the ownership/recovery mechanism rather than relying on timing.

Keep ordinary gameplay in memory, with bounded saving/retries, departure handling, and shutdown handling appropriate to Roblox. Do not save every income tick. Report saving failures truthfully and document any remaining crash-loss window; “saved” must mean a confirmed write.

Use **online earnings only** for this first slice, continuing while the owner visits another lot. Offline earnings need a separate product decision.

### Visitors can admire, owners can act

Players can walk into another currently loaded property. Only its owner can spend its money, purchase or change its assets, or alter its saved state. Validate this on the server, including any purchase pads and remote requests.

When an owner leaves, clear their runtime lot and release profile ownership safely. The next occupant gets only their own restored state. Offline-home browsing, cross-server visiting, and visitor permissions beyond looking around are outside this slice.

### A calm mode with honest UI

Make the infinite mode explicit. Disable the shared SupplyCache event in this mode, including its client dependencies and HUD, while preserving existing prototype behavior elsewhere. An intentionally absent event should not display as a broken or unavailable service.

Show enough ownership and readiness feedback for players to understand whose place they are visiting and whether theirs is ready. Retain usable mobile controls and existing preferences. Do not introduce a run-complete screen, reset pressure, or a competitive lobby goal.

## Evidence and handoff

Demonstrate:

- A new player starts correctly; a returning player restores the same money and purchases after a new session, including a different lot.
- Two players can visit each other, and visitor purchase/edit attempts cannot change the owner's state.
- Departure and lot reuse leave no equipment, callbacks, money, or ownership from the previous occupant.
- Load/save failures and rapid rejoin cannot replace real data with defaults or let an old writer overwrite newer progress.
- Infinite mode works without the event HUD; ordinary mode remains functional.

Use meaningful domain/lifecycle checks and actual Studio multiplayer observation. Prove persistence against an isolated published test experience; in-memory fixtures alone are not real saving evidence. Keep Studio testing away from production data and report any unexecuted checks explicitly.

Deliver a playable preview, concise review notes, setup/save-format documentation, and the smallest relevant validation required by the repository. Open a **draft PR for review of this new mode**; do not merge or publish the gameplay implementation before that review.

The next slice can add owner-controlled layout/decor and distinct growth choices; sustained expansion follows. Do not silently bundle those into INF-01.

## Platform references

Use current official guidance when implementing persistence:

- [Roblox data stores](https://create.roblox.com/docs/cloud-services/data-stores)
- [Player data and session ownership](https://create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing)
