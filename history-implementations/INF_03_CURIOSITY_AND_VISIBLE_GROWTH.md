# INF-03 — Infinite: Curiosity and Visible Growth

Reviewed continuation brief — 2026-10-09. Use this version from latest `main` together with INF-02 and MODE-01.

## Direction

Give Infinite enough playable content that the owner can explore it before choosing the final design. Its core is **Curiosity and satisfaction from looking back at what you grew**. Think: “What will that become?”, “Which part of my place do I want next?” and “Come see what I built.”

This is creative implementation authorization for **Infinite only**. Session's growth/management is a challenge and optimization system; preserve its existing content and economy. Do not rebalance it to accommodate this catalogue.

Choose an appealing provisional style, content, unlock structure and prices, then build them. The brief intentionally leaves hard design and implementation decisions to Work. Prefer coherent, interesting differences over a large catalogue of recolored income boosts.

## Starting point and isolation

Follow AGENTS.md and inspect current state. Stack an isolated implementation branch/worktree on the current INF-02 head, which should include INF-01 and merged #11. If predecessors have merged, use the equivalent updated main. Open a draft PR into main, record the immediate predecessor's exact head, identify inherited changes and link a comparison that isolates this slice. Read this brief from latest main if needed.

Continue coding before founder review. No gameplay merge or publication is authorized by this brief. Missing published-service observations must remain visible, but do not block the independent coding and local preview. Leave experiment branches/PRs #14–#16 intact.

## A place with things to discover

Create several compatible growth directions that can produce visibly different properties: for example a busy workshop, a greener/cozier space or a more unusual technology corner. These are inspiration, not mandatory themes. Include meaningful alternatives early enough to experience during review; a single mandatory chain followed by cosmetic recolors does not test this direction. Players should choose what interests them and later explore or combine other directions without restarting or permanently spoiling their build. Different choices can change appearance, activities or unlocks; they need not become competing efficiency builds.

Make expansion unlock new possibilities: more usable space, new equipment behavior, architectural changes, decoration families or small optional interactions. Distinct machinery should look and act differently. Keep some things worth watching or trying after the purchase animation finishes, with readable production and restrained feedback. Let earlier investments remain recognizable as the place grows; replacing everything with an unrelated larger model can erase the satisfaction of looking back. This does not require a separate history, screenshot or achievement system.

Give the catalogue understandable previews, prices, effects and requirements. Reveal enough of future possibilities to prompt curiosity, while making the next available choices easy to find. A reasonable play session should show early rewards, a noticeable milestone and another appealing possibility, rather than immediately exhausting the four original upgrades or requiring long idle waits. Check pacing from a genuinely fresh profile using ordinary earnings, not only a rich development preset. Decoration spending, storage and branch choices must leave a viable way to keep progressing; do not make the relaxing mode depend on constant collection chores or an undisclosed optimal purchase order.

Support varied arrangements using INF-02. Properties should have room for personality and clear routes for visitors. Expansion must fit the available world and cannot take over another lot; choose a coherent growth model instead of promising limitless geometry inside six fixed lots. Check it against the provisional footprints/envelope from INF-02 and extend that model where needed. Rebuilding a property after an expansion or reload must preserve the player's arrangement rather than repeatedly resetting it to a designer layout. Keep visiting focused on properties loaded in the current lobby.

Keep the mode calm: no forced reset, final winner, mandatory lobby contest or imported combat system. Exploration is voluntary; a player can keep building while others visit. Retain online-only earnings for now. Offline income, trading, monetization and prestige are separate decisions.

## Content that is easy to change

Keep Infinite content/tuning separate from the Session catalogue even where runtime machinery is shared. Shared refactors must preserve the Session baseline. Do not merely append items to the four-upgrade shared catalogue and thereby change both modes.

Use stable content identities and evolve profile data intentionally. Existing cash/assets/placements from INF-01 and INF-02 must survive, with income derived from trusted rules. Preserve the existing data-store identity and explicitly handle unsupported schema/content versions. Decide how a later catalogue revision can retire or replace an owned item without silently deleting it or making the whole profile unusable; no generic live content-migration framework is required. Handle multiple owned objects and upgrades without duplication. Choose documented limits for placed objects, profile size and numeric growth; indefinite play does not justify unbounded work or corrupting saved data. Reaching a limit must be explained and leave existing possessions usable.

Prefer bounded, lightweight presentation: machinery can look productive without accumulating hundreds of server-simulated pieces or saving animated debris. Check the cost of a lobby with six developed properties, not just one empty plot; reduce distant/hidden effects and clean them up on replacement or departure as appropriate. New families and milestones should be addable through the established content boundary, without copying an entire gameplay stack for each one.

The Sell Lemons reference and EXP-02 purchase experiment may inform Infinite presentation. Inspect PR #15 if useful, but do not merge that entire experiment or silently change Session purchasing. If implementing walk-on purchases here, make spending deliberate, owner-validated and resistant to repeated contact. Never chain-buy newly revealed items under a stationary player, or spend because they spawned or closed a menu on a pad. The player must be able to enter/leave editing without accidentally buying behind a panel.

## Evidence and handoff

Deliver a playable fresh-player path and two substantially different developed-property examples in a disposable review preview. Show real purchases, continuing equipment activity, expansion, decoration, visiting, and save/restore through the profile path. Development presets must be clearly isolated from live progression.

Test catalogue/unlock validity, migrations across the stack, ownership, duplicate purchase/edit handling, income restoration and property limits. Observe desktop/mobile usability and multiplayer visibility where available, including the developed-property workload. Verify the Session economy and purchase flow retain their previous behavior.

Give a concise account of what the player can explore, what was chosen provisionally and how content can be extended. A finite prototype catalogue is not proof of endless compelling progression; report its actual size, reachable milestones and indicative time to the first choices/milestone, distinguishing estimates from observed play. Deliver a draft PR and evidence with exact revisions and unobserved checks. Use change-relevant checks and one coherent review path; do not repeat the entire historical QA packet after every content addition.

**Then continue to MODE-01 without a founder-review pause.** The eventual review will judge the combined Infinite loop, style and content rather than requiring approval of every intermediate catalogue decision.
