# INF-02 — Infinite: Personalization and Building

Reviewed continuation brief — 2026-10-09. Use this version from latest `main` together with INF-03 and MODE-01.

## Direction

Make the saved property feel like **my place**, rather than another copy of the same factory. Owners should be able to arrange what they own, add decoration and create a space other players can walk into and admire.

The owner has clarified the two modes:

- **Infinite = Curiosity:** discovering what can be built, exploring personal choices and feeling satisfaction when looking back at what has grown. Relaxed, persistent, no required reset or final goal.
- **Session = Challenge:** growth and management are part of its optimization problem. Preserve its current catalogue, prices, income, prerequisites and management behavior during this work.

Creative growth and style choices are authorized for Infinite. Make reasonable, reversible decisions and implement them; architecture, interaction design and tuning belong to the implementation model. Keep this brief at the level of outcomes rather than treating it as a prescribed class design.

## Starting point and continuous work

Read current repository state and AGENTS.md. At briefing time, PR #18 (`codex/inf-01-persistent-personal-space`, head `313de5fc49af0ec3f2fc3d1263a27d025c5fc210`) contains INF-01 on merged foundation #11. It is still draft. It has account-owned profiles, temporary lobby lots, server ownership boundaries, online income and a calm Infinite HUD. The first catalogue still contains four one-time upgrades and four placement slots.

**Build on the current INF-01 implementation without merging it merely to continue.** If #18 has since merged, use updated main. Otherwise create an isolated branch/worktree from its current head. Open a draft implementation PR into main as required by AGENTS.md; clearly identify inherited changes and link a comparison against the predecessor for this slice. Record the dependency and tested parent. Obtain this brief from latest main if it is absent from the predecessor branch.

The owner explicitly authorizes stacking further coding before visual/play review. Read all three briefs first, then run **INF-02 → INF-03 → MODE-01** as one continuous work queue, in separate implementation branches/worktrees. If a slice already exists, inspect and continue it rather than creating a competing implementation. Carry dependency fixes into affected descendants and record the revisions actually tested. Do not pause the queue at the old founder-review checkpoints. Keep gameplay PRs draft for a later combined review; do not interpret this as publication or merge authorization. Real DataStore durability remains unobserved and must be carried forward truthfully. It is not a reason to stop independent local implementation. Preserve its safeguards.

Leave experiment PRs #14–#16 and their branches/worktrees separate.

## Playable result

Build a usable owner-only editing loop: obtain an object, place it, select it again, preview a new arrangement, move/rotate it, and commit or cancel without losing its previous state. Provide a clear way to store and re-place movable objects so players can change their minds; destructive deletion or resale is not required. Make fixed structures distinguishable from editable objects. Choose a practical placement model that works on desktop and touch. Give clear feedback for invalid placement and keep normal walking, visiting and the HUD usable outside editing.

Add a small, coherent starter decoration selection with a clear acquisition path so the editor produces visible personality immediately. Allow different arrangements and appearance choices; do not build a generic editor with nothing interesting to put in it. Before fixing the placement model, sketch representative INF-03 object footprints and an expansion envelope. Choose a provisional style and simple placement rules that accommodate them; a full architecture/construction editor is not required.

Keep properties walkable and usable. Respect the assigned lot, neighboring properties, access paths and interactive objects. Validate occupied footprints, not just object centers. Visitors can admire currently loaded properties but cannot modify them, spend the owner's money or push their objects around. Keep previews local to the owner; visitors see accepted arrangements. Editing and menus must not accidentally trigger purchases underneath them. Offline property browsing and collaborative editing are outside this slice.

Persist the accepted arrangement and appearance through the existing profile system, relative to the property rather than to a server's numbered/oriented lot. Preserve existing owners' cash, four assets and layouts. Inspect the strict version-1 schema before extending it: catalogue additions or a new placement representation need an intentional migration. Keep existing account keys and store continuity; changing the schema version must not silently create an empty replacement store. Define behavior for old/new server versions and unsupported content without overwriting, dropping assets or inventing a fresh profile. A documented refusal to load an unsupported newer save is safer than a lossy downgrade; universal backward compatibility is not required.

Keep ownership, catalogue definitions and individual placed objects distinct enough to support multiple copies of a decoration and future machines. Moving, storing or restoring equipment must have clear income behavior and must not duplicate assets, charges or earnings or leave the player unable to progress. Let Work choose the smallest coherent policy and document it.

Use bounded server validation for accepted edits, ownership, asset availability, finite transforms and bounds. A client preview is not permission to commit. Handle duplicate commits without repeating their effects; reject delayed edits that would overwrite a newer arrangement and requests after departure, lot reuse or profile ownership loss. Accepted edits must update the authoritative property coherently; avoid saves/remotes for every preview movement. Reuse INF-01's checkpoint policy: acceptance in this server is not proof of durable saving, and the UI must preserve that distinction. Do not add another saver.

## Evidence and handoff

Demonstrate an owner creating two visibly different arrangements; storing/re-placing; cancel/rejection preserving the previous state; restoration on a differently oriented lot; visitor edit rejection; and departure/reuse without old objects or callbacks. Cover migration from v1, unsupported newer data, repeated/stale edits and a failed checkpoint with meaningful tests. Check actual desktop and mobile editor interactions where available, preserving Session behavior. New Infinite content must not leak into the Session catalogue or purchase flow.

Deliver a reproducible playable preview, short evidence and setup notes, and a draft PR with an explicit predecessor. Record unobserved physical-device and real-service checks without claiming they passed. Run repository checks appropriate to the change.

**Then continue to INF-03 without waiting for founder review.** Fix confirmed defects that would prevent the next slice, but do not spend the whole queue refining this first editor's graphics.
