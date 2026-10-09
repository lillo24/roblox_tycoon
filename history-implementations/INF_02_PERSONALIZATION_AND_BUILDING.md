# INF-02 — Infinite: Personalization and Building

## Direction

Make the saved property feel like **my place**, rather than another copy of the same factory. Owners should be able to arrange what they own, add decoration and create a space other players can walk into and admire.

The owner has clarified the two modes:

- **Infinite = Curiosity:** discovering what can be built, exploring personal choices and feeling satisfaction when looking back at what has grown. Relaxed, persistent, no required reset or final goal.
- **Session = Challenge:** growth and management are part of its optimization problem. Preserve its current catalogue, prices, income, prerequisites and management behavior during this work.

Creative growth and style choices are authorized for Infinite. Make reasonable, reversible decisions and implement them; architecture, interaction design and tuning belong to the implementation model. Keep this brief at the level of outcomes rather than treating it as a prescribed class design.

## Starting point and continuous work

Read current repository state and AGENTS.md. At briefing time, PR #18 (`codex/inf-01-persistent-personal-space`, head `313de5fc49af0ec3f2fc3d1263a27d025c5fc210`) contains INF-01 on merged foundation #11. It is still draft. It has account-owned profiles, temporary lobby lots, server ownership boundaries, online income and a calm Infinite HUD. The first catalogue still contains four one-time upgrades and four placement slots.

**Build on the current INF-01 implementation without merging it merely to continue.** If #18 has since merged, use updated main. Otherwise create an isolated branch/worktree from its current head. Open a draft implementation PR into main as required by AGENTS.md; clearly identify inherited changes and link a comparison against the predecessor for this slice. Record the dependency and tested parent. Obtain this brief from latest main if it is absent from the predecessor branch.

The owner explicitly authorizes stacking further coding before visual/play review. Run **INF-02 → INF-03 → MODE-01** as one continuous work queue, in separate implementation branches/worktrees. Do not pause the queue at the old founder-review checkpoints. Keep gameplay PRs draft for a later combined review; do not interpret this as publication or merge authorization. Real DataStore durability remains unobserved and must be carried forward truthfully. It is not a reason to stop independent local implementation. Preserve its safeguards.

Leave experiment PRs #14–#16 and their branches/worktrees separate.

## Playable result

Build a usable owner-only editing loop: select an owned object, preview a new arrangement, move/rotate it, commit it or cancel without losing its previous state. Choose a practical placement model that works on desktop and touch. Give clear feedback for invalid placement and keep normal walking, visiting and the HUD usable outside editing.

Add a small, coherent starter decoration selection so the editor produces visible personality immediately. Allow different arrangements and appearance choices; do not build a generic editor with nothing interesting to put in it. Choose a visual direction suitable for expanding in INF-03.

Keep properties walkable and usable. Respect the assigned lot, neighboring properties, access paths and interactive objects. Choose honest, documented bounds that can support later expansion. Visitors can admire but cannot modify a property, spend its money or interfere with its editing.

Persist the accepted arrangement and appearance through the existing profile system, relative to the property rather than to a server's numbered/oriented lot. Preserve existing owners' cash, four assets and layouts. Inspect the strict version-1 schema before extending it: catalogue additions or a new placement representation need an intentional compatible migration, not a failed load or a fresh default profile.

Keep ownership, catalogue definitions and placed objects distinct enough to support multiple decorations and future machines. Moving, storing or restoring equipment must have clear income behavior and must not duplicate assets, charges or earnings. Let Work choose the smallest coherent policy and document it.

Use server validation for accepted edits, ownership, asset availability and bounds. A client preview is not permission to commit. Stale requests after departure, lot reuse or profile ownership loss must not mutate the new occupant. Reuse INF-01's write ownership and failure handling instead of adding another saver.

## Evidence and handoff

Demonstrate an owner creating two visibly different arrangements; cancel/rejection preserving the previous state; restoration on a differently oriented lot; visitor edit rejection; and departure/reuse without old objects or callbacks. Cover the new migration and repeated/stale edits with meaningful tests. Check actual desktop and mobile editor interactions where available, preserving Session behavior.

Deliver a reproducible playable preview, short evidence and setup notes, and a draft PR with an explicit predecessor. Record unobserved physical-device and real-service checks without claiming they passed. Run repository checks appropriate to the change.

**Then continue to INF-03 without waiting for founder review.** Fix confirmed defects that would prevent the next slice, but do not spend the whole queue refining this first editor's graphics.
