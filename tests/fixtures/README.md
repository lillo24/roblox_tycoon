# Persistence QA fixtures

These files are outside the production Rojo mappings.

- `ProfileMemoryStore.luau` supplies detached serialized records and explicit
  before/after-write failures or delayed returns for persistence/lifecycle suites.
  The local playable preview also injects it explicitly; it never persists across
  Stop and never replaces an unavailable real backend.
- `InfiniteClient.client.luau` observes a real client's readiness, HUD and missing
  event services after the usual startup deadline. `-IncludeQA` installs it in
  disposable StarterPlayerScripts; ordinary playable previews exclude it.

Build/run instructions and observed versus pending gates live in
[`docs/INF_01_REVIEW.md`](../../docs/INF_01_REVIEW.md). Domain fault injection tests
ordering and rejection, not Roblox DataStore durability.
