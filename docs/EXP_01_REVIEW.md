# EXP-01 · Parry Laboratory

Draft for play review. Independent experimental branch based on combined PR #11
`ba8c8134de54eeb6c8df5951c2ab308ff380b859`, plus main's three new briefs at
`c6c2aee`. PR #8/#9/#11 and their review work were not modified or merged.

## Run and replay

From this checkout, with the pinned Rokit tools on PATH:

```powershell
./scripts/New-ExperimentPlace.ps1 -Name ParryLab
```

Open `build/ui-review-exp-parrylab.rbxlx` in Studio; F5 starts solo practice.
Click/tap **Parry** / **Attack**, or Q/F; gamepad L2/R2 are bound. **Solo / restart**
starts a fresh round. For a real duel, start Server & Clients with two players,
then each selects **Duel queue**. The first waiting player pairs with the next.
Restart/respawn/disconnect ends the shared round; survivors can restart solo.

The disposable copy starts only the laboratory. Its runtime floor/opponent are
away from the authored factories; normal tycoon bootstraps, scene, catalogue,
cash and income remain untouched. Regenerate after edits. Rojo-syncing normal
bootstraps over this copy would start the ordinary factory instead.

## Rules and tradeoffs

Shared `ParryLab/Rules.luau` owns all tuning. Health 100; ordinary attacks deal 20.
Attack commits to 620 ms windup + 380 ms recovery. The opponent can see the full
server-receipt-based windup. Distance must be at most 11 studs and an attacking
player must face the target (dot product >= 0.35); geometry is retained at impact.
Walking out of range is counterplay, not a guaranteed block.

Guard lasts **110 ms**, with an 850 ms cooldown and 550 ms failed-attempt recovery.
A successful guard negates damage, staggers the attacker for 900 ms and offers
800 ms to commit a 36-damage counter. It cannot cancel one's own attack commitment.
The solo opponent attacks predictably every two seconds. Five ordinary attacks
can win without a parry. Already committed simultaneous lethal strikes can trade.
This bot tests reading/execution; it does not establish competitive balance.

Inputs carry synchronized server time. The server rejects non-finite/malformed
timestamps, more than 150 ms old or more than 30 ms ahead; input processing is
limited to one attempt per 60 ms. Impact resolution waits 150 ms for delayed guard
delivery. This is bounded timestamp tolerance, not secure proof of a client's
physical keypress time. Deliberate backdating within that envelope remains possible;
Internet latency, prediction/rollback and competitive anti-cheat are unproven.

An immediate local cyan guard cue provides input feedback; amber ring/countdown
communicates impact; green counter cue and explicit early/late explanations show
outcomes. Motion toggle and Roblox reduced-motion preference keep the numeric cue
without ring resizing. Short screens use smaller controls/cue and retain safe insets.
Prototype geometry/feedback are primitive; no external audio/animation assets.

## Evidence

- Complete local `Validate-Project.ps1` passed with the pinned tools: formatting,
  zero-error/warning lint, build, types/probes, authored-map checks and preview
  exact-source/class/QA isolation checks. CI result is recorded on the PR.
- **Actual Studio execution: 41 assertions**, recorded at
  `2026-10-08T20:37:58.685Z`. Tests use the production combat/rules with supplied
  times: successful/early/late guard, bounded delivery wait, counter deduction,
  commitment/cooldown, range refusal, ordinary victory, trade and malformed time.
  These are synthetic timing/domain tests, not native timed parries.
- Actual solo server/client startup, arena placement, bot windup/damage/defeat,
  native restart and **native F-key attack** observed. Opponent changed 100 → 80.
  [Native solo observation](exp-01/native-solo.png) predates the final short-screen
  layout addition; combat/server source is unchanged by that addition.
- Final CLI check includes the short-screen layout. Native successful timed parry,
  real two-player duel, touch/controller activation, latency/fairness, final compact
  layout and hardware performance remain **unobserved**. No pass is claimed.
- Stop returned the preview to Edit. The canonical map SHA256 stayed
  `9D6A9FE65A25E0C1D8CF6FA4FE7D4E582EA234FF618DC758BC71FD4675C9F8E8`.
  Studio's unrelated unpublished-place chat/profile HTTP errors were present;
  the experiment assertions and startup completed successfully.

## Assessment and play review

**Revise**, pending hands-on feel review. The prototype provides a demanding,
testable loop and explicit risk/reward; it does not demonstrate excitement or
network fairness. Review guard cue/feedback and primitive combat presentation
before widening scope. A keep decision requires playable desktop/touch sessions
and a real duel, including high-latency input and repeated defensive attempts.

Does it feel skillful? Is a successful parry satisfying? Do attacking and defending
both remain interesting? Is it readable and fair enough to justify deeper development?
