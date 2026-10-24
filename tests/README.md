# Verification map

Specs are ModuleScripts outside production Rojo mappings. PowerShell builders install them only into disposable QA copies. The full validator formats/lints/type-checks all specs, checks builds/structure and executes selected domain suites in pinned Lune. Engine/client tests still require Studio; Lune is not a Roblox client or service simulation.

- Session/SupplyEvent cover the existing economy, purchases, ownership and event rules. SupplyFeedback/UiState/WorldLabels/PlayerGuidance cover their client state and presentation boundaries.
- Persistence/ProfileLifecycle cover atomic profile storage, lease/receipt fences, stale callbacks and shutdown. Property/PropertyWorld cover editing, migration, lot frames and reconstruction. InfiniteState covers the calm UI state.
- Growth covers catalogue rules, old-schema preservation, ordinary-earnings pacing, limits and six developed properties.
- PropertyRendering verifies selective reconstruction, storage/re-placement, palette identity and exact fresh-model color equivalence across all silhouettes, plus departure/reuse metadata cleanup. It runs with Infinite IncludeQA, outside timed performance scenes.
- Routing covers trusted configuration, choices, duplicates, immediate/late failures, bounded retry and stale callbacks. Handoff covers freeze/snapshot ordering behind an autosave, failed writes, current-data reacquisition, source/destination overlap, late cleanup and deadlines.
- FactoryPurchases covers walk-on bounds, visit/nonce/character/exit fencing, costs and modal input policy. FactoryPurchasesLive and FactoryPurchasesPresentation are opt-in actual-client observers for walking and machine/reduced-motion behavior.
- AimClash covers shared schedule, server adjudication, private intermediate totals, independent Precision/combo scoring, spam/replay bounds, ties and Practice. AimClashClient/AimClashDisplay require actual client rounds and viewport bounds; they do not represent physical-device tapping or human duels.
- `fixtures` contains explicit memory backends, isolated examples and actual-client observers. These are omitted from production and are never automatic fallbacks for service errors.

Use New-UiReviewPlace, New-InfiniteReviewPlace and New-ModeReviewPlace as documented in scripts/README. The current evidence guide is docs/INTEGRATE_01_REVIEW.md; old review packets apply to their own revisions. Hosted and device observations remain separate from controlled checks.
