# Development deployment boundary

This folder owns offline-verifiable deployment policy, gameplay artifact checks
and the single Open Cloud publish request. It does not own map authoring or game
behavior. Requires PowerShell 7; no extra package/deployment service is used.

- `GameplayArtifact.psm1` wraps the existing gameplay-only UI builder, verifies
  every mapped script against disk and all other scene content against the saved
  map, and rejects QA/fixtures and API-limited instance classes/subclasses.
  Legacy validators run in a child scope with their original non-strict property
  semantics; the new module itself uses strict mode. XML comparisons normalize
  empty-element syntax symmetrically without discarding scene properties.
- `DevelopmentDeployment.psm1` validates manual/main/target credentials, requires
  a clean unchanged checkout, runs validation then fresh assembly, hashes exact
  payload bytes and sends one XML POST. `Validate`, `Build`, `CheckCheckout` and
  `Transport` scriptblocks are trusted **test seams**; the command-line wrapper
  exposes none of them. Dry run always stops before transport. HTTP errors are
  replaced at the transport boundary to prevent header/credential disclosure;
  no response body or raw network exception is returned. The only success is
  a 2xx response containing a positive integer version number.

`../Invoke-DevelopmentDeployment.ps1` reads credentials from process environment
only and writes allowlisted audit fields to the GitHub job summary. The manual
workflow uses it without overrides. `../New-DevelopmentPlace.ps1` builds the
same scene without publishing, for the owner's first Studio publish.
`../Test-DevelopmentDeployment.ps1` exercises these modules with mocked HTTP and
real scene mutations; it is part of `../Validate-Project.ps1` and never needs
Roblox credentials. Operator setup and limitations are in
[`docs/MOBILE_DEPLOYMENT.md`](../../docs/MOBILE_DEPLOYMENT.md).
