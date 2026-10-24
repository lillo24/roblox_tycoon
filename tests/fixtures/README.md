# Studio QA fixtures

These files are outside the production Rojo mappings.

- `ProfileMemoryStore.luau` supplies detached serialized records and explicit
  before/after-write failures or delayed returns for persistence/lifecycle suites.
  The local playable preview also injects it explicitly; it never persists across
  Stop and never replaces an unavailable real backend.
- `InfiniteClient.client.luau` observes a real client's readiness, HUD and missing
  event services after the usual startup deadline. `-IncludeQA` installs it in
  disposable StarterPlayerScripts; ordinary playable previews exclude it.
- `InfiniteShowcase.luau` supplies explicit development presets for migration/growth
  checks and opt-in showcase previews. These are not new-user release profiles.
- `ModePreview.luau` simulates immediate/late/missing-destination failures using
  fake IDs. `ModeClient.client.luau` checks actual role isolation and UI presence.
- `IntegrationServer.server.luau` and `IntegrationClient.client.luau` coordinate
  opt-in StudioTestService checks only when passed `{Kind="INTEGRATE01", Players=1}`
  (or two clients with Duel). The server requires suite completion and explicit
  client results; failures/timeouts end as failures. Factory `WalkOn=true` uses
  the actual movement fixture. Normal Play has no automated movement/input.

Build/run instructions and observed versus pending gates live in
[`docs/INTEGRATE_01_REVIEW.md`](../../docs/INTEGRATE_01_REVIEW.md). Domain fault injection tests
ordering and rejection, not Roblox DataStore durability.
