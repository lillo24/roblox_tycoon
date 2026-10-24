# INTEGRATE-01: integration evidence and handoff

The implementation composes Factory Challenge, Infinite World and Aim Clash on `main`'s authored-map/deployment foundation. It uses one experience with Entry, Session, Infinite and Clash places. Code integration does not publish Roblox content. Follow [MOBILE_DEPLOYMENT.md](MOBILE_DEPLOYMENT.md) for the three added places, Actions variables, manual publishing, rollback and phone checks.

## Implemented behavior

- Entry has three named, scrollable safe-area selection buttons. Each calls the server router for its trusted destination. It has no factory economy, Supply Cache, profile lease, editor or Clash queue. Destination servers also boot correctly without teleport data. Invalid IDs, wrong universe/membership or a swapped build role fail closed with a readable issue.
- Factory retains the six authored plots, unchanged prices/prerequisites/income, shared Supply Cache and guidance/HUD. EXP-02's walk-on path is the default: server-issued one-use visit nonce, current character/ownership/oriented-pad/proximity checks, one atomic purchase, and exit/re-entry after unaffordable, modal-blocked or expired attempts. Panels, Modes, native menu, text focus and lost window focus suppress acknowledgements. Machinery activity, purchase feedback/tone and reduced motion remain local presentation. Supply Cache stays deliberate.
- Infinite retains INF-01/02/03/MODE-01: experience/account-scoped `InfiniteProfiles_v1`, v1/v2→v3 data migration, single-writer leases, ordered checkpoint/final saves, fail-closed load/ownership errors, property restoration, owner-only discovery/editing, 22 discoveries, decoration/storage/palettes and calm online-only growth. Factory progress is separate. Geometry reconciliation preserves unchanged models and recolors in place; it clears owner metadata on lot reuse. No showcase/profiler fixture is released.
- Aim Clash is a separate destination with solo Practice and a two-human Duel queue, shared 24-target accelerating patterns, bounded server judgements, combo extras, independent Precision, private intermediate scores and terminal comparison. Disconnect/return cancels unfinished duels without inventing a winner. It supports mouse/touch aiming and reduced motion; controller aim is not implemented. It is not Parry, a factory event or a music-synchronized game.
- Modes/return controls exist in every gameplay role. Infinite freezes earnings/editing, confirms a final checkpoint/release before teleport, and reacquires current data after a confirmed failure. Nonces, revisions, phase/generation fences, bounded manual retries and honest Joining/Waiting/Unavailable states prevent overlapping transitions or fake arrivals. No automatic teleport retry or cancellation guarantee is introduced.
- The existing manual workflow is upgraded in place to **Deploy Development Modes**. It validates/builds all four current-source authored-map scenes before any upload, verifies same-universe/root-place membership using credential-free documented GETs, captures immutable bytes and hashes, then publishes Session → Infinite → Clash → Entry. Per-place confirmations and partial/unknown outcomes are summarized. Missing destination IDs cannot fall back to the old single-place release. Main/manual restrictions, minimal token/key scope, serialization, no redirects/ambiguous retries, source/scene fidelity and unsupported-instance gates remain.

## Provenance

Only the selected production features and associated tests were ported. Their old review packets describe their own revisions, not evidence for this integrated build.

| Source | Exact reviewed source head | Included |
| --- | --- | --- |
| [EXP-02 #15](https://github.com/lillo24/roblox_tycoon/pull/15) | `a67bd23f80b20778233a8bc1a2c7cc7c3050f5f8` | Factory walk-on authority, machine presentation, rules/specs; obsolete opt-in wrapper replaced by normal role startup |
| [EXP-03 #16](https://github.com/lillo24/roblox_tycoon/pull/16) | `3b9c320fdb777ae83c3da082c0e7a374b2a23dba` | Clash rules, Match/runtime, client/display and specs; dedicated trusted role and return integration added |
| [INF-01 #18](https://github.com/lillo24/roblox_tycoon/pull/18), [INF-02 #21](https://github.com/lillo24/roblox_tycoon/pull/21), [INF-03 #22](https://github.com/lillo24/roblox_tycoon/pull/22), [MODE-01 #23](https://github.com/lillo24/roblox_tycoon/pull/23) | stacked mode head `c26c92652c745c22cff35276d84180a04320e4e1` | Persistent property/schema/lifecycle, growth/editor, routing/handoff, preview helpers and associated tests |
| [PERF-01 #25](https://github.com/lillo24/roblox_tycoon/pull/25) | `c096eb691667d7961a38cb5dadf0843724b36ea5` | Production selective geometry reconciliation and PropertyRendering regressions; benchmark/diagnostic fixtures remain separate |
| [DEPLOY-01 #33](https://github.com/lillo24/roblox_tycoon/pull/33) and [integration brief #34](https://github.com/lillo24/roblox_tycoon/pull/34) | main `d0c5970b900464d24e9560aab1500119561dcb7b` | Current canonical map, validator and secure publisher foundation retained and extended |

EXP-01/#14 Parry and PERF-02/#27, PERF-03/#29 diagnostic work are not integrated or merged. The retained `Experiments` module paths identify their provenance; role bootstraps now make the requested Factory/Clash features ordinary gameplay.

## Validation

Run `./scripts/Validate-Project.ps1` for formatting, lint, strict Roblox/Rojo type analysis and negative probes, fresh code build/sourcemap, authored-map/ownership/fidelity regressions, all preview builders, mocked multi-place deployment and executed Lune suites. Pinned Lune 0.10.5 is a development dependency so CI executes assertions instead of only type-checking them. It has no Roblox network/service credentials; its memory backend is never a release fallback.

Observed locally on 2026-10-24:

- Full CLI validator passed. The publisher passed **347 offline assertions**, including missing/duplicate/inexact IDs, stale/wrong source, fixture/API-limited content, membership/root-place errors, all-builds-first ordering, destination-first/Entry-last order, redaction, ambiguous/partial failures and immutable upload buffers.
- **915 executed assertions in 12 Lune suites**: Session 186, SupplyEvent 196, SupplyFeedback 65, UiState 40, InfiniteState 14, Routing 48, FactoryPurchases 38, FactoryInputGate 10, AimClash 216, Persistence 46, ProfileLifecycle 21, Handoff 35. Expected injected service/lease failures print warnings and are asserted as refusals. Lune's unsupported Terrain metadata notice is not a scene fidelity or rendering pass; the XML verifier checks the exact saved scene independently.
- Roblox Studio **0.744.0.7441077** executed **2,083 server assertions**: Routing 48, Handoff 35, FactoryPurchases 38, FactoryInputGate 10, AimClash 216, Persistence 46, ProfileLifecycle 21, Property 246, Growth 296, PropertyRendering 731, InfiniteState 14, Session 186, SupplyEvent 196. Entry's actual client additionally passed nine isolation/three-button checks, then nine actual button/failure assertions in an iPhone XR portrait viewport (412×756 safe GUI area). These overlap domain coverage above; counts are not unique combined tests.
- Factory passed **21 native keyboard assertions** with ordinary earnings: unfunded Workshop entry, no purchase when funds arrive while standing, fresh entry buys the 30-cash Workshop/rate 4, Modes blocks a funded booster visit, closing Modes cannot buy, fresh entry buys the ten-cash booster/rate 5, and no repeated charge. Standard/reduced motion passed **41 actual presentation checks each**; Modes/return with simulated failure passed four checks. The desktop test focused the actual viewport and disabled avatar appearance loading only in its disposable copy, without modifying cash, income, purchases or purchase messages. Separate client isolation/modal-clearance checks also ran.
- Interactive gameplay/button and two-client smoke observations are being completed before final integration. No live upload or phone result is asserted here.

## Reproduce Studio checks

Generate a role with `./scripts/New-ModeReviewPlace.ps1 -Role Entry -IncludeQA` (also `Prototype`, `Infinite`, `Clash`), open its `build/mode-*.rbxlx`, and use Edit mode's command bar:

```lua
local result = game:GetService("StudioTestService"):ExecutePlayModeAsync({Kind = "INTEGRATE01", Players = 1})
print(result.Passed, result.Role, result.Issue)
```

For Factory add `WalkOn = true`, stop mobile simulation (`game:GetService("StudioDeviceSimulatorService"):StopSimulationAsync()`), and focus the game viewport as Play starts so native W/S reaches player controls. Disable `StarterPlayer.LoadCharacterAppearance` only in the disposable test copy for a timely unfunded start; restore it afterward. The original server MoveTo observer is retained as opt-in history but can be interrupted by normal player controls. The current FactoryInput smoke uses actual virtual keyboard events after one position/camera seed per pad, natural income and real offer/ack transactions; its rate assertions wait for separately replicated attributes.

For Clash's scripted two-client test use `ExecuteMultiplayerTestAsync(2, {Kind = "INTEGRATE01", Players = 2, Duel = true})`. StudioTestService is documented by [Roblox](https://create.roblox.com/docs/reference/engine/classes/StudioTestService). Normal Play without these explicit test arguments stays interactive. Fixtures are outside production mappings, require server suite completion and client results, and time out as failures. ModeSelection requires the local adapter, preventing accidental live teleports. Its VirtualInput clicks exercise actual button handlers; tests subtract `GetInsetArea(ScreenInsets.None).Min` from core-relative button centers to include device cutouts as well as the top bar. `GetGuiInset()` alone omits the portrait notch offset. Duel replays manufacture aim attempts through actual client remotes, not human reaction, physical-device fairness or network benchmarks.

Integration testing found and repaired two production issues: a standalone Modes launcher collided with the native player list in narrow Factory views (it now uses the HUD navigation slot); and a delayed walk-on offer could arrive just after closing a modal (VisitGate now remembers the locally blocked exact-pad visit through exit). The nonce acknowledgement remains server-authoritative and nonce-only; read-only offer metadata identifies the target for conservative client suppression.

The local adapter intentionally reports a requested destination followed by failure. Open each role's separate preview file to play it; never describe this as an actual cross-place transfer. Infinite's preview memory resets on Stop. Release files are the separate fixture-free `ui-review-development-{entry,session,infinite,clash}.rbxlx` set.

## Remaining live/owner checks

No new destination IDs or Roblox account settings were changed and **no build was deployed** in this integration task. The owner must create Session/Infinite/Clash inside the existing private experience, configure the three Actions variables, then manually run the updated workflow on merged main. Keep Entry as the existing start place. Use the same experience-restricted publishing key and suitable player caps (Factory/Infinite six, Clash at least two).

Real TeleportService travel/failure recovery, live DataStore save/rejoin/overlapping-server ownership and physical phone touch/orientation/performance remain unobserved until that setup. A two-human duel needs a second authorized account. Studio emulation, generated scenes, memory fault injection and scripted network clients do not satisfy these live checks. Historical six-client Infinite hitch observations and unresolved PERF-02/03 attribution remain risks; this integration makes no new overall performance or balance/fun claim.
