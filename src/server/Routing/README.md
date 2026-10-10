# Mode routing

AppRuntime resolves the trusted server role before calling TycoonRuntime. Entry/Unavailable start only this router and the chooser. Prototype starts the unchanged Session economy/event; Infinite starts its own profile lifecycle. Destination startup never reads teleport data. GameMode's authored StringValue is a Studio preview selector; hosted roles come from Settings, with the disabled configuration retaining the ordinary Prototype default.

- Settings: disabled by default; use the same explicit UniverseId and three distinct Places in all builds. Zero is unconfigured, never a guessed destination.
- Configuration: validates integers, experience membership, source role and duplicate/self-route IDs. AppRuntime obtains membership from AssetService:GetGamePlacesAsync; failure stops configured gameplay startup with an explicit issue. The listing is capped at 100 pages.
- Controller: one transition per player, revision/nonce/phase fences, three manual joining attempts and three manual reloads per arrival, three-second cooldown after recovery. No automatic teleport retry or cancellation promise.

- Runtime: active-player RemoteEvent adapter, four requests/second, lifecycle callbacks and UI state. It exposes role names, not client-selected place IDs.
- TeleportAdapter: server TeleportAsync to public servers. Nonce in TeleportData correlates TeleportInitFailed, whose options object can differ; it carries no progression or permissions. Accepted calls remain Joining; after 30 seconds they remain Waiting until a terminal failure or PlayerRemoving, without competing calls or a new writer.

Preparing warns after 30 seconds and recovery after 45 seconds if still pending.
These warnings keep the source paused and do not launch competing operations.
A recovery generation fences callbacks independently of UI revision changes.

The Studio adapter lives only in tests/fixtures/ModePreview and is injected by New-ModeReviewPlace. It reports a requested destination and an immediate/late failure; it cannot perform a real teleport or change a running server's role. Profiles owns the safe Infinite handoff/recovery contract (see Persistence/README). See docs/MODE_01_REVIEW.md for isolated published setup and observation limits.
