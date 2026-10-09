# EXP-03 — Aim-and-reaction clash review

**Assessment: revise pending founder play review.** This is a playable, isolated
candidate for the confirmed direct click/tap direction. Technical checks establish
individual server scoring and private live results. They do not establish human
anticipation, rewarding combos, device fairness or whether the outcome feels earned.
Leave the PR draft, as explicitly required by `EXP_03_OSU_INSPIRED_CLASH.md`.

## Start and replay

Run in this experiment checkout with the repository's pinned tools on PATH:

```powershell
./scripts/New-ExperimentPlace.ps1 -Name AimClash
./scripts/New-ExperimentPlace.ps1 -Name AimClash -WithTests
./scripts/Validate-Project.ps1
```

Open `build/ui-review-exp-aimclash.rbxlx` in Studio. F5 Play and choose **Practice**
for one player. For a duel, choose **Server & Clients**, set **2 clients**, start
with F7, then choose **Duel queue** in both actual client windows. Both receive
the same pattern, seed and server start time. After the result, choose Practice
or Duel queue again. Leave queue returns a waiting player to the lobby; active
rounds must finish. A disconnect cancels an unfinished duel without a winner.
The other player's completed result remains available when a contestant requeues.

The `-qa` copy automatically executes the domain assertions in its Play server.
Normal bootstraps remain unchanged; only the generated copy opts into AimClash.
Regenerate after editing source; do not Rojo-sync normal bootstraps over this copy.
No factory income, purchase, supply or combat integration starts in this preview.
The authored scene's SHA256 remains
`9D6A9FE65A25E0C1D8CF6FA4FE7D4E582EA234FF618DC758BC71FD4675C9F8E8`.

The branch uses combined PR #11's `ba8c8134` source foundation and merges the
new main briefs at `c6c2aeed`. PR #11 was checked as open, draft and mergeable
before implementation. It has not been merged or rewritten. The PR into main
therefore also includes that prerequisite foundation. Experiment work starts
after the neutral preview-helper commit `bf7ace1`.

## Interaction and tuning

`src/shared/Experiments/AimClash/Rules.luau` owns the small 12-location reflected
sequence, 24 opportunities, geometry, timing, scoring constants and board bounds.
`server/Experiments/AimClash/Match.luau` owns individual judgements; `Runtime.luau`
owns authenticated Player/round membership, queue and private updates.
`client/Experiments/AimClash/View.luau` owns layout/visuals; `Controller.luau`
owns pointer input, shared time, provisional feedback and server correction.

The default sequence lasts **17.234 seconds**, after a **2-second countdown**;
results wait another **180 ms** for bounded arrival. Targets 1–8 have 1-second
intervals, 9–16 have 0.7-second intervals, and 17–24 have 0.46-second intervals.
Visible lifetimes are 90% of those intervals: 0.9 / 0.63 / 0.414 seconds.
There is no musical clock, music dependency, keyboard-letter prompt or audio asset.

Targets have radius 0.11 of the square arena width and sit entirely inside its
circular boundary. Two faint outlines and a thin connector show the next locations.
Own validated combo warms the perimeter from teal toward orange; the active
target's size and contrast stay constant. Standard motion adds a gentle perimeter
pulse. System, session or local reduced motion removes the pulse and retains color.

Layout measures Roblox's `CoreUISafeInsets` and `None` rectangles through
[`GuiService:GetInsetArea`](https://create.roblox.com/docs/reference/engine/classes/GuiService#GetInsetArea).
Their difference places local child coordinates below Core UI and inside hardware
margins. `GuiObject.AbsolutePosition` and `InputObject.Position` share the engine's
UI origin; no extra pointer inset is subtracted. Layout refreshes on viewport and
top-bar changes. This fixed an observed portrait overlap with the replay controls.
Portrait and landscape still have different arena/target pixel sizes; equal
normalized patterns do not establish equal physical difficulty.

## Score and precision

For a hit at distance `d` from the center, with target radius `r`:

```text
quality = 1 - 0.5 × (d / r)²                 (center 1; edge 0.5)
base = round(100 × quality)
Speed Extra = round(base × section extra)   (0 / 0.15 / 0.30)
Combo Extra points = round(base × min(combo - 1, 10) × 0.015)
total = max(0, sum(base + extras) - 15 × inaccurate inputs)
Precision percentage = 100 × sum(quality) / (24 + inaccurate inputs)
```

All rounding is positive half-up and occurs per hit. Combo starts at 1, resets on
a miss or inaccurate input, and adds at most 15% of each hit's base. A missed
opportunity contributes zero quality; the denominator still includes all 24.
Wrong aim, gap clicks, duplicate judgements, invalid timestamps and arrival spam
count as inaccurate, reduce precision and break combo. A failed attempt can be
retried while its circle remains unresolved. UI clicks outside the arena are ignored.

Exact equal totals draw; practice has no opponent. Over 128 input attempts
disqualifies that participant, forces total zero and loses to a valid zero. Two
disqualified players draw. The result shows both complete breakdowns, including
the exact **Combo Extra points** and **Precision percentage** labels. No opponent
score, comparison or winner is sent during play; live packets are per-player
`FireClient` projections, with no replicated score attributes.

Actual domain-suite comparison:

| Aim scenario | Precision | Total |
| --- | ---: | ---: |
| All 24 centers | 100% | 3,040 |
| All 24 at 90% spatial quality | 90% | 2,736 |
| Skip first 4, then 20 centers | 83.33% | 2,580 |
| All 24 at the circle edge | 50% | 1,523 |

Perfect aim consists of 2,400 base + 360 speed + 280 combo. Skipping the four
slow opportunities retains every fast target and a long ending combo, but loses
to consistent 90% aim. Bonuses still intentionally affect close outcomes: a
slightly lower precision can win through better late hits or uninterrupted combo.
Founder comparison should decide whether that trade-off feels earned. Precision
itself never uses bonuses or section weight.

The server chooses the target from each reported event timestamp, checks finite
coordinates and circle geometry, and derives every component. It accepts timestamps
up to 180 ms old and 30 ms ahead of receipt, rejects non-increasing event times,
limits arrival frequency to 25 ms, and caps attempts. Client prediction never adds
authoritative points. Bounded timestamp/coordinate validation is not proof of a
human gesture or prevention of automated aiming. There is no measured-ping or
device-specific equalization; longer real network delay can reject otherwise
correct clicks. Neither contestant sends a total or quality score.

## Executed QA and provenance

Roblox Studio **0.741.19.7411056**, Windows, 8 October 2026. Times below are UTC.
CLI/CI format, lint, analyze and build; they do not execute the Luau assertions.
The final full local `Validate-Project.ps1` passed formatting/lint, build, types and
failure probes, structure/map regressions and exact-source preview isolation.

- **216 domain assertions executed at 21:54:04.757** against actual mapped Rules
  and Match. Coverage includes same schedule, all target bounds, acceleration,
  phases, center/edge quality, miss/duplicate/spam accounting, invalid/backdated/
  late/future times, rate/attempt bounds, disqualification, ties, hidden early
  comparison, bonus trade-offs and inset-aware board bounds.
  After the touch fixture, exact default Rules were restored, the QA runner was
  re-enabled and all 216 assertions passed again at 22:02:55.677.
- **Two real Studio clients, default timing, scripted individual inputs:** the
  opt-in network observer executed 23 assertions in reduced motion and 22 in
  standard motion at 21:40:59.516 / 21:40:59.510. Both logged round 1, seed 0,
  start `1791495641.85752`, and 174 private packets each. Results agreed on
  winner actor 1: 3,040 versus 2,580, with precision 100% versus 83.33%. The
  observer saw all phases, the trail and own combo heat; reduced motion checked
  a static perimeter during actual rendered frames. Rules/Controller/View sources
  were checked byte-exact before injecting the unmapped probe. These logs precede
  the final safe-area layout change; scoring and default timing are unchanged.
- **Native replay/queue/disconnect:** native buttons started subsequent default
  duels, an untouched round drew at zero, and the completed peer result remained
  after requeue. Closing one actual client during the next countdown cancelled
  the peer without a winner (`native-disconnect.jpg`). No manufactured disconnect.
- **Final phone layouts:** iPhone XR emulation, actual Play UI. 24 read-only
  display assertions passed in portrait at 21:56:59.355 (413×895) and landscape
  at 21:57:30.345 (895×413), covering actual safe bounds, controls, arena, footer,
  result labels and text heights. Native rotation exercised layout refresh;
  native Motion toggling emitted an observed Touch input. These are emulated
  dimensions/input, not a physical phone test. The initial display test used the
  wrong absolute-coordinate origin; it was corrected from measured engine values.
- **Final desktop layout:** 24 read-only display assertions passed at
  22:04:26.131 on the 810×675 actual Play viewport after a native Practice start
  and its default-duration result. Rules and final View sources matched disk exactly.
- **Native desktop mouse adapter, slowed timing fixture:** one observed click
  received authoritative 100 points, combo 1. Its final result showed precision
  4.2%, 23 misses and zero inaccurate inputs. A first default-speed attempt was
  late during observation round trips and scored an inaccurate input; it is not
  counted as a default reaction pass.
- **Final emulated-touch adapter, same slowed fixture:** a native tap on the
  observed first circle received authoritative 100 points and combo 1 with the
  final safe-area layout. The first circle is deliberately visible for 27 seconds;
  all following intervals retain their defaults. This verifies input coordinates
  and server routing, not default reaction difficulty. Its final result showed
  4.2% precision, 23 misses and zero inaccurate inputs.

The first 180 duel frame intervals measured foreground p95/max **19.171 / 153.865 ms**
and background **68.061 / 180.729 ms**. Background Studio throttling and spikes are
explicit limitations. These samples do not establish mobile performance, equal
device opportunity or internet latency tolerance. Physical touch, sustained human
mouse aiming, controller targeting, latency across machines and subjective trail/
acceleration/combo/result feel remain unobserved.

Controller practicality: the prototype accepts direct mouse/touch coordinates.
It does not implement gamepad target selection or a button QTE. A platform pointer/
virtual cursor would require input and balance review; gamepad controls and fairness
have not been verified. No audio asset means no licensing or music timing dependency;
audio feel has not been tested.

## Opt-in probes and restoration

All four test files stay outside production Rojo mappings. To run a client probe,
copy its exact source into an unmapped ModuleScript under that actual Play client's
`PlayerScripts` and require it there, then destroy the probe after completion.
Do not require a second Controller: that would create duplicate listeners.

- `AimClashClient.spec.luau`: call `require(probe)(true, quiet)` on each actual
  client before choosing Duel queue. `true` sends synthetic individual coordinates
  through the real remote; actor 2 skips the first four. Toggle Motion natively to
  match `quiet` first. `false` observes ordinary UI play without manufacturing input.
  The probe waits up to 180 seconds and must observe a complete two-player duel.
- `AimClashDisplay.spec.luau`: call `require(probe)()` after a real result is visible;
  it reads actual bounds and text, writes no score or layout, and returns 24 checks.
- `AimClashInputFixture.luau`: copy into an unmapped ModuleScript in an **Edit-only
  disposable preview**, require once and destroy it. It extends only the first
  interval to 30 seconds / lifetime 27, and disables the default-duration assertion
  runner. Choose Practice normally and click/tap the observed circle. It prints an
  explicit fixture label and rejects Play or a nondefault starting source.

After the timing fixture, Stop Play and regenerate/reopen the normal or QA preview.
This restores exact Rules and re-enables default assertions in the QA copy. Never
save a fixture into the canonical scene. Temporary test scripts, synthetic inputs
and changed timing are excluded from the normal preview. Production bootstraps,
economy/catalogue and authored geometry remain untouched.

Screenshots under `docs/exp-03` are native captures: duel results use default-time
network replay inputs; `native-input-fixture*` use the prolonged desktop first target;
`phone-touch-input-fixture` and `phone-touch-fixture-result` use the prolonged
emulated-touch first target. `desktop-result-final` shows the restored defaults.
`phone-*-final` show corrected safe-area UI; `phone-landscape-default` precedes the
portrait safe-area repair. Screenshot presence alone is not a physical-device pass.

## Founder decision

Play several ordinary duels on desktop and a physical phone. Check whether the
two future outlines help anticipation, the 0.414-second final targets remain
readable, uninterrupted combo feels rewarding without obscuring aim, and the
winner plus independent precision explains the contest. Compare similarly skilled
players across devices and network delays before calling the competition fair.
Keep the isolated aim interaction as a candidate; revise defaults from that evidence.
Drop or reshape it if aiming/trail reading competes with the intended combat feel.
