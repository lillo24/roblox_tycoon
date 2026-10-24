# Mode routing

AppRuntime resolves the trusted server role before gameplay. Entry/Unavailable start only this router and the chooser. Prototype (the retained internal role for the Session/Factory Challenge place) starts the session economy, default walk-on purchases and Supply Cache. Infinite starts its own profile lifecycle/editor. Clash starts only the Aim Clash queue/match runtime. Destination startup never reads teleport data.

- Settings: disabled source defaults to Entry in Studio and Unavailable when hosted. The release builder injects the same explicit UniverseId and four distinct Places into all builds, plus an expected BuildRole. Its verifier allows only this exact generated server module to differ from disk. Actual GameId/PlaceId, AssetService membership and BuildRole must agree; swapping files is refused. Zero is unconfigured. A Studio-only authored TycoonMode StringValue selects a disposable preview while routing is disabled; it never determines a hosted role.
- Configuration: validates integers, experience membership, source role and duplicate/self-route IDs. AppRuntime obtains membership from AssetService:GetGamePlacesAsync; failure stops configured gameplay startup with an explicit issue. The listing is capped at 100 pages.
- Controller: one transition per player, revision/nonce/phase fences, three manual joining attempts and three manual reloads per arrival, three-second cooldown after recovery. No automatic teleport retry or cancellation promise.

- Runtime: active-player RemoteEvent adapter, four requests/second, lifecycle callbacks and UI state. It exposes role names, not client-selected place IDs. TycoonRoutePhase blocks fresh Factory offers and Clash controls during travel; Clash removes a departing player from queue or cancels an unfinished duel without a winner.
- TeleportAdapter: server TeleportAsync to public servers. Nonce in TeleportData correlates TeleportInitFailed, whose options object can differ; it carries no progression or permissions. Accepted calls remain Joining; after 30 seconds they remain Waiting until a terminal failure or PlayerRemoving, without competing calls or a new writer.

Preparing warns after 30 seconds and recovery after 45 seconds if still pending.
These warnings keep the source paused and do not launch competing operations.
A recovery generation fences callbacks independently of UI revision changes.

The Studio adapter lives only in tests/fixtures/ModePreview and is injected by New-ModeReviewPlace. It reports a requested destination and an immediate/late failure; it cannot perform a real teleport or change a running server's role. Profiles owns the safe Infinite handoff/recovery contract (see Persistence/README). See docs/MOBILE_DEPLOYMENT.md for the four-place setup and docs/INTEGRATE_01_REVIEW.md for evidence and observation limits.
