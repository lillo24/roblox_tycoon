# Private development deployment to Roblox mobile

After the one-time owner setup below, merge reviewed game changes to `main`, open
[Actions → Deploy Development](https://github.com/lillo24/roblox_tycoon/actions/workflows/deploy-development.yml)
on a PC or phone, select **Run workflow → main → Run workflow**, wait for success,
then close and rejoin the development game in the Roblox phone app. GitHub's
runner builds/publishes; your PC can be off. No USB, APK, running Rojo server or
repeated Studio publish is needed.

This workflow updates **one existing start place** in a **separate private
development experience**. It never runs on push, PR, merge, schedule or tag.
Merging the infrastructure does not dispatch it. Draft experiment/Infinite/mode/
performance PRs are absent until separately reviewed and merged into `main`.

## One-time owner setup

Codex can prepare these screens through enabled local Computer Use/Browser Use.
The owner completes login/MFA and explicitly approves creation of the private
experience immediately before its first Studio publish. API key **Save & Generate**
requires separate explicit approval after inspecting its scope. If secure UI
transfer without model/screenshot/log exposure is unavailable, the owner copies
the generated key directly into GitHub while automation/capture is stopped;
Codex then verifies only that the secret exists. The first workflow dispatch
remains an owner-initiated action.

1. Use Roblox Studio signed into the owner account. On a current clean `main`
   checkout with the pinned tools installed, use **PowerShell 7**:

   ```powershell
   ./scripts/Validate-Project.ps1
   ./scripts/New-DevelopmentPlace.ps1
   ```

   Open the freshly generated `build/ui-review-development.rbxlx` in Studio in
   Edit mode. This is the saved six-lot map plus current disk scripts, with no QA
   runners or synthetic data. A bare Rojo build omits the map; the canonical
   snapshot alone may contain old script copies. Do not use either for publishing.
   Never save this disposable output over `place/tycoon.rbxlx`.

2. Use **File → Publish to Roblox** to create a **new, separate development
   experience**, named clearly (for example, “FactoryHub Development”). Choose
   the intended owner and enable phone/tablet support in Devices. Keep its
   **Audience → Private** in Creator Dashboard. Do not overwrite a production
   experience or publish from a running Play session. New experiences default
   to Private. Account eligibility and access remain subject to Roblox's current
   [publishing and audience requirements](https://create.roblox.com/docs/production/publishing/publish-games-and-places).

3. In [Creator Dashboard](https://create.roblox.com/dashboard/creations), use the
   development experience thumbnail's **⋯ → Copy Universe ID**. Open that
   experience's **Places**, select its **start place**, and copy the Place ID
   from its configuration URL (`…/experiences/<UNIVERSE_ID>/places/<PLACE_ID>/configure`).
   These are different IDs even for a single-place experience. Confirm the
   selected place belongs to this development universe; retain its Roblox game
   page link for your phone. Never reuse production IDs.

4. In Creator Dashboard **Open Cloud → API Keys**, create a dedicated key. Keep
   **Restrict by Experience** enabled and select **only this development
   experience**. Add **universe-places → Write** and no other operations/scopes.
   Save the generated value directly into GitHub's secret entry below. Never
   paste it into chat, source, a command line, a place, logs or an artifact.
   GitHub-hosted runners use changing IPs: a key restricted only to your home IP
   will fail. Configure IP restrictions deliberately for your runner policy;
   this workflow does not change them or use your browser session.
   See [API key permissions, IP restrictions and expiry](https://create.roblox.com/docs/cloud/auth/api-keys).

5. In [repository Settings → Environments](https://github.com/lillo24/roblox_tycoon/settings/environments),
   create **`roblox-development`**. Under deployment branches/tags, select only
   the branch **`main`** (no tags). Add these **environment** entries:

   | Kind | Exact name | Value |
   | --- | --- | --- |
   | Variable | `ROBLOX_DEV_UNIVERSE_ID` | Development experience's Universe ID |
   | Variable | `ROBLOX_DEV_PLACE_ID` | That experience's start Place ID |
   | Secret | `ROBLOX_OPEN_CLOUD_API_KEY` | The restricted key from step 4 |

   IDs must be positive decimal digits without spaces or leading zeros. Values
   stay out of source. Environment settings are owner setup; the workflow does
   not configure them. A required reviewer is optional; enabling one adds an
   approval step to each run. Leave it unset if you want dispatch alone to start
   deployment. Protect `main` and restrict who can edit Actions/environment
   settings as appropriate for the repository.

6. Explicitly perform the first **Run workflow** on `main`, then complete the
   phone check below. No live API upload or physical-phone check was performed
   by implementing this infrastructure.

## Each update and phone check

1. Merge the intended reviewed game changes to `main` through their own PRs.
2. Open **Actions → Deploy Development → Run workflow**, choose **main** and run.
   The serialized job checks out the latest `main` when it starts. Its actual
   checkout SHA can be newer than the dispatch event SHA if the run was queued.
   It runs full repository validation on that checkout and assembles a new scene.
3. Confirm the run succeeded. The job summary records **Universe ID, Place ID,
   validated commit SHA, build SHA256 and returned published version**. Compare
   the version with the development place's version history in Creator Dashboard.
   A verified gameplay-only `.rbxlx` artifact is retained for **three days** after
   a successful job; it includes no credentials or QA. Artifact retention failure
   after publishing does not undo the Roblox version: inspect the summary/history.
4. Sign into the **Roblox phone app** with the same owner account (or a user with
   Edit permission). Open the saved development game page/link on the phone and
   launch it in the Roblox app. Search/discovery is not required for a private
   game. Check spawn/map, touch movement/jump, HUD readability, purchase prompts
   and the supply cache, then leave and rejoin once. Record the run/version and
   actual phone results separately from CLI/mock tests.

Publishing creates a version; it **does not hot-reload** a running client/server.
Close/leave and rejoin after the successful upload. Existing servers may still
run the previous version, so rejoining can reconnect to old code until a new
server starts. This workflow does not restart servers. Do not repeatedly upload
the same build to try to refresh a server.

Private audience allows the owner/creator team with **Edit** permission. A friend
with only Playtest permission is not assumed to be able to join Private. Additional
testers require a separate owner decision: suitable Edit permissions, or an
eligible **Limited → Playtesters** audience. This setup does not grant access,
change audience to Limited/Public, enable production DataStore access, create
monetization, restart servers or alter production settings.

## Failures and offline rehearsal

Missing configuration or a wrong ref fails before any Roblox publish request.
Check the named environment entries, select `main`, then run again. For HTTP
401/403, verify key status, single-experience `universe-places` Write scope,
target membership and IP restrictions. HTTP failures are redacted; raw response
bodies, headers and exception text are not logged.

There is **one POST, a 120-second timeout, no redirects and no automatic retry**.
A timeout/network failure or invalid/missing `versionNumber` can happen after
Roblox created a version. Check Creator Dashboard version history before a
manual retry to avoid unnecessary versions. A successful upload requires a 2xx
response with a positive integer `versionNumber`; command exit alone is not proof.

From any local implementation branch, with PowerShell 7 and pinned tools:

```powershell
./scripts/Invoke-DevelopmentDeployment.ps1 -DryRun
```

This executes the full validator and fresh assembly, prints commit/build digest,
and **never sends HTTP**, even if credentials exist. It needs no IDs/key and
allows local uncommitted work for rehearsal. Offline publisher regressions also
run in full validation/PR CI and can be run separately:

```powershell
./scripts/Test-DevelopmentDeployment.ps1
```

## Scene fidelity and future expansion

The builder reuses `New-UiReviewPlace.ps1 -GameplayOnly`. Verification requires
every managed script's name, class and source to match the checkout, and all
content outside those three folders (including Workspace) to match the canonical
scene. QA/fixture instance names and extra/stale managed children fail. The
verifier supports ordinary nested folders and `.luau`/`.lua` scripts; `init`
mappings, metadata/models and other mapped file formats require an audited
verifier update rather than silently accepting a new mapping convention.

[Roblox's Place Publishing API](https://create.roblox.com/docs/cloud/guides/usage-place-publishing)
does not reliably update modified **EditableImage, EditableMesh, PartOperation,
SurfaceAppearance or BaseWrap** instances. The current canonical scene contains
**none**, including their subclasses. Deployment scans the assembled scene and
rejects these classes and descendants from the pinned Roblox definitions (for
example UnionOperation and WrapLayer). If one is introduced, use an explicitly
authorized Studio publish for that change; the workflow has no override that
silently promises fidelity. Reassess the official limitation before expanding it.

Only the configured start place is updated through
`POST https://apis.roblox.com/universes/v1/{universeId}/places/{placeId}/versions?versionType=Published`
with XML bytes, `Content-Type: application/xml` and the `x-api-key` header.
Additional MODE-01/Infinite places, TeleportService routing, cross-server state
and DataStore persistence need a separate audited expansion with real target
IDs and appropriate checks. No destination IDs are guessed here.

Official API, audience and GitHub deployment documentation was rechecked on
2026-10-11. See also
[GitHub environment/deployment controls](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/control-deployments).
