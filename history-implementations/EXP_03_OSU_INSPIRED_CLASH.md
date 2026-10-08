# EXP-03 — Osu!-Inspired Aim-and-Reaction Clash

## Intent

Prototype a **short, intense one-versus-one special-ability clash** for `lillo24/roblox_tycoon`. It could later interrupt combat when special attacks collide or appear in a finale; choose neither integration now.

**Confirmed direction (8 October 2026): direct clicking/tapping of appearing circles, without musical-beat alignment.** The osu! reference concerns aiming, visual anticipation, successive targets, and escalating intensity. Music is optional atmosphere. This clarification supersedes earlier descriptions of rhythmic targets, a composed beatmap, or music-led timing.

## What the player should experience

- A roughly circular play area is centered on the screen. Targets appear **inside** it, not necessarily around its circumference.
- Circles appear successively with a short delay. A subtle trail hints at where the sequence is heading, helping the player anticipate the next location without obscuring targets.
- Click or tap appearing circles directly. Do not require a musical beat, keyboard-letter prompts, or additional rhythm-game inputs. Choose readable target lifetimes and hit rules.
- The sequence becomes faster during the brief clash. Both players receive the same pattern and acceleration schedule. Consecutive successful hits build a combo; successful hits in faster sections are worth more.
- An increasingly hot screen treatment or another striking overlay communicates **the player's own performance**. Preserve target visibility. Do not reveal the opponent's score, relative lead, or winner before the end.
- Finish with the winner and a clear score breakdown, including **“Combo Extra points”** and a separate **Precision percentage**. Precision stays independent of combo bonuses and speed weighting. Define it transparently, accounting for missed targets and inaccurate inputs so selective clicking or spam cannot produce misleading results.

## Direction, not a prescribed solution

Build a **fast standalone playable duel** first. Work should choose the short default duration, target sizes, pattern, acceleration, scoring formula, tie handling, trail, effects, and practical architecture. Keep these easy to tune or replace; avoid a generic rhythm engine or large pattern catalogue.

Focus on responsiveness and an understandable result. Keep scoring opportunities comparable between contestants. Check whether combo bonuses or late high-value hits overwhelm precision enough to make the result feel arbitrary, and explain the trade-off.

Take desktop clicking, mobile tapping, latency, and server validation seriously. Identical patterns alone do not establish equal device difficulty. Test what is available, explain limitations, and assess controller practicality without turning the main interaction into a button QTE. Do not trust a client-submitted total as the authoritative result.

Audio can reinforce hits, misses, acceleration, and the result, but no music synchronization is needed. Use original or appropriately licensed assets. Respect reduced-motion preferences and keep the play area legible as intensity rises.

## Working context and handoff

Inspect the repository and current status of combined PR #11 before implementation. Keep the experiment isolated, modular, and reversible. Preserve the main factory economy and authored scene. Follow the repository's PR and validation conventions, and **leave the prototype draft for founder play review**.

Deliver an easy way to start and replay a duel in Studio, plus concise evidence separating real two-player/input checks from synthetic tests. Explain the scoring in plain language and provide a **keep / revise / drop** assessment. Test whether the trail helps anticipation, acceleration stays readable, combos feel rewarding, and the final result feels earned.
