# EXP-01 — Parry Laboratory

## Intent

Build a **small, playable experiment** for the Roblox multiplayer tycoon project (`lillo24/roblox_tycoon`) to discover whether parrying can become a fundamental, exciting combat mechanic.

The fantasy is simple: an opponent commits to a readable attack; the defender gets a tense, brief opportunity to parry; a successful parry feels powerful and creates a meaningful counterattack opportunity. A miss or poorly timed parry should be understandable, not arbitrary.

**Confirmed direction (8 October 2026): try demanding parries from the start.** Seek a satisfying skill test. Difficulty should come from reading and executing the action, not unclear cues or network delay. Leave exact windows and tuning to Work and make them easy to revise after play.

## Direction, not a prescribed solution

Use your judgement about timing, animations, feedback, movement, controls, and implementation. Focus on **responsiveness and feel** rather than a full combat system. Make it possible to try alone against a predictable opponent and, if practical, with another player. Take Roblox latency and desktop/touch/controller usability seriously without overengineering the first experiment.

Keep attacking worthwhile. Explore enough commitment and counterplay that waiting or repeatedly attempting parries is not automatically the best strategy. Choose the smallest useful way to test this.

Keep this separate from the game's unsettled round-based vs. persistent structure. Do not introduce character classes, a full progression tree, permanent PvP rules, or balance assumptions just to support this prototype.

## Working context and handoff

Inspect the GitHub repository and pending PRs, especially the combined prototype PR #11, before deciding where this experiment should live. Preserve the existing game and saved map; use a reversible demo/arena or isolated test place as appropriate. Follow the repository's PR/validation workflow, but **leave the experimental PR draft for play review, not automatic merge**.

Deliver a runnable Studio demonstration and concise evidence of what you tested. End with the questions a human playtest should answer: **Does it feel skillful? Is a successful parry satisfying? Do attacking and defending both remain interesting? Is it readable and fair enough to justify deeper development?** Separate observed results from untested claims, then recommend **keep / revise / drop**.
