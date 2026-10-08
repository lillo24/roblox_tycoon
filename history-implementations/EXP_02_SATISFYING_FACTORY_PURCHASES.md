# EXP-02 — Satisfying Factory Purchases

## Intent

Experiment with the pleasure of **buying, owning, and watching factory equipment work** in `lillo24/roblox_tycoon`.

The existing prototype provides server-authoritative cash, purchase pads, income upgrades, and visible upgrade models; the combined map preview adds the larger six-lot factory setting. Use the verified repository state as the foundation. A purchase should feel consequential: equipment appears or assembles satisfyingly, the player understands what improved, and nearby players can see another factory growing.

**Confirmed reference (8 October 2026): [Sell Lemons](https://www.roblox.com/games/79268393072444/Sell-Lemons).** The user specifically likes buying by walking onto a pad. Use it as a reference for an effortless purchase loop and visible growth. A final art style or preference between more machines, larger machines, and larger buildings has not been selected. The public listing was checked; live gameplay was not independently playtested for this brief. The walk-on preference comes directly from the user.

## Direction, not a prescribed solution

Explore construction motion, machinery activity, sound, and compact feedback. Aim for **clarity and satisfaction without filling the screen with numbers or effects**. A purchase must leave a lasting, readable improvement after its animation ends: equipment continues to look active, its benefit is clear, and neighboring growth remains visible.

Include **walk-on purchase pads**: entering an eligible pad buys the upgrade without a separate click, key press, or confirmation. The inspected purchase paths on `main` and combined PR #11 (`ba8c813`) use `ProximityPrompt.Triggered`; automatic walk-on buying is new work. Recheck current code before implementation.

Make activation dependable during ordinary walking and touch movement. Preserve server checks for the player, ownership, proximity, prerequisites, and money. Repeated contacts must not cause duplicate charges, rewards, or message spam. Make unavailable states clear. Choose and document predictable behavior when someone stays on an unaffordable pad or opens a menu nearby; retain the UI's protection against unintended purchases behind panels. Leave trigger geometry and implementation details to Work.

Keep **existing income calculations, catalogue rules, and server authority** intact. Visual droppers or moving output may be simulated; physical conveyors and an item-production economy are not required. Avoid a large asset pipeline, progression rebalance, or complex decoration system. Consider six neighboring factories and mobile performance.

This experiment tests interaction and presentation. Attractive purchases alone do not demonstrate strategic depth or interesting production management.

## Working context and handoff

Inspect the repository and pending MAP/UI/combined PRs first; PR #11 may still be draft. Choose an isolated preview or stacked experimental branch without merging or modifying pending review work. Keep the purchase trigger and presentation easy to replace or remove. Follow the repo's PR/validation process, but **hold the prototype as a draft until we judge the feel in Studio**.

Deliver a playable before/after example of a starter and purchased machine, concise input/performance evidence, and the checks needed to trust walk-on activation. Separate observations from untested claims. Assess whether purchasing and continued factory activity are **satisfying, readable, and reusable**, then recommend **keep / revise / drop**.
