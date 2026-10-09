# Verification map

Specs are engine-run ModuleScripts, outside production Rojo mappings. The PowerShell preview builders install them only into disposable QA copies. `Validate-Project.ps1` checks all source/specs with the pinned formatter, linter, type checker, build and structural probes; this does not execute Studio assertions.

- Session/SupplyEvent cover the existing economy, purchases, ownership and event rules. SupplyFeedback/UiState/WorldLabels/PlayerGuidance cover their client state and presentation boundaries.
- Persistence/ProfileLifecycle cover atomic profile storage, lease/receipt fences, stale callbacks and shutdown. Property/PropertyWorld cover editing, migration, lot frames and reconstruction. InfiniteState covers the calm UI state.
- Growth covers catalogue rules, old-schema preservation, ordinary-earnings pacing, limits and six developed properties.
- Routing covers trusted configuration, choices, duplicates, immediate/late failures, bounded retry and stale callbacks. Handoff covers freeze/snapshot ordering behind an autosave, failed writes, current-data reacquisition, source/destination overlap, late cleanup and deadlines.
- `fixtures` contains explicit memory backends, isolated examples and actual-client observers. These are omitted from production and are never automatic fallbacks for service errors.

Use New-UiReviewPlace, New-InfiniteReviewPlace and New-ModeReviewPlace as documented in scripts/README. The combined review/evidence guide is docs/MODE_01_REVIEW.md; hosted and device observations remain separate from these controlled tests.
