# Private phone testing: one experience, four places

INTEGRATE-01 migrates the existing manual **Deploy Development** action to **Deploy Development Modes**, in the same workflow file. Merging code never publishes Roblox content. Do not rerun an old build/artifact. The new action checks out current `main`, validates its complete source, and builds all four places before uploading anything.

The current start place becomes **Entry**, with Factory Challenge, Infinite World and Aim Clash buttons. Their destinations are **Session**, **Infinite**, and **Clash** in the **same existing private development experience**, not separate Roblox games. Until the owner completes this setup and runs the new workflow, phone players still receive the previously published prototype. No new Roblox publication, visibility change, or live DataStore test is implied by code/CI success.

## One-time owner setup

1. Pull merged `main`, install the pinned tools (`rokit install`), then run:

   ```powershell
   ./scripts/New-DevelopmentPlace.ps1
   ```

   This builds four current-source, authored-map files under `build/`:

   | File | Destination |
   | --- | --- |
   | `ui-review-development-entry.rbxlx` | Existing start place, after workflow setup |
   | `ui-review-development-session.rbxlx` | New Session / Factory Challenge place |
   | `ui-review-development-infinite.rbxlx` | New Infinite World place |
   | `ui-review-development-clash.rbxlx` | New Aim Clash place |

   Without configured IDs these have explicit **disabled routing** and zero destination IDs. They are suitable for creating the three private places; a hosted unconfigured build shows Unavailable instead of running the wrong economy. Do not manually replace Entry with an offline file.

2. For each of **Session, Infinite and Clash**, open its fresh corresponding file in Roblox Studio. Choose **File → Publish to Roblox As… → select the existing private development experience → Add as a new place**. Name each place clearly. Repeat three times, keeping the existing Entry/start place. This is the owner publishing action; the repository does not create places or change account settings automatically. See [Roblox's multi-place instructions](https://create.roblox.com/docs/production/publishing/publish-games-and-places).

3. In Creator Dashboard → that experience → Places, copy each new Place ID from its configuration URL. Keep the experience's existing Universe ID and existing start Place ID. Set suitable per-place player caps: **Session 6, Infinite 6, Clash at least 2** (Entry can also use 6). Keep the audience private; a second human duelist needs authorized playtester access. No public launch is needed.

4. In GitHub → repository Settings → Secrets and variables → Actions, retain the existing secret and variables and add three variables:

   | Kind | Name | Value |
   | --- | --- | --- |
   | Secret | `ROBLOX_OPEN_CLOUD_API_KEY` | Existing restricted development-experience `universe-places` **Write** key |
   | Variable | `ROBLOX_DEV_UNIVERSE_ID` | Existing private experience's Universe ID |
   | Variable | `ROBLOX_DEV_PLACE_ID` | Existing **Entry/start** Place ID |
   | Variable | `ROBLOX_DEV_SESSION_PLACE_ID` | New Session Place ID |
   | Variable | `ROBLOX_DEV_INFINITE_PLACE_ID` | New Infinite Place ID |
   | Variable | `ROBLOX_DEV_CLASH_PLACE_ID` | New Clash Place ID |

   IDs must be positive decimal integers below 2^53, without whitespace or leading zeros; all four Place IDs must differ. The same experience-scoped key covers its added places if its scope/expiry/IP restrictions remain valid. Do not grant all-experience access, add billing permissions, copy cookies, or place credentials in source/CLI arguments. If the existing key expired, replace it with the same limited scope. The `roblox-development` GitHub environment must permit `main`; environment variables of the same names override repository variables, so remove stale overrides.

5. **Leave Studio API access to live DataStores disabled.** Infinite uses Roblox DataStoreService from published servers in this experience, with account keys in `InfiniteProfiles_v1`. Studio memory previews are explicitly temporary. Real Studio DataStore testing is separately gated by `Persistence/Settings.StudioTestUniverseId = 0` and requires a deliberately isolated test universe; don't enable live production access to bypass this gate. DataStores are [experience-scoped across places](https://create.roblox.com/docs/cloud-services/data-stores).

## Deploy the integrated build

On GitHub, select **Actions → Deploy Development Modes → Run workflow → main**. This manual publishing action is the owner's decision. It requires no special local phone connection.

The workflow checks the real checkout commit and clean tree, runs the full validator, assembles and verifies all four source-fresh scenes, then captures immutable XML buffers and SHA256 hashes. Only `Routing/Settings` is generated: each server gets the same four-place manifest plus its expected build role. The public documented [universe/place listing APIs](https://create.roblox.com/docs/cloud/reference/domains/develop) verify same-experience membership and that Entry is still the root/start place, without sending the API key. Unavailable, malformed, foreign or uncertain configuration stops before uploads.

Publication order is **Session → Infinite → Clash → Entry**. Each upload must return HTTP success and a positive integer `versionNumber` before the next starts. This is publish-response verification, not a live gameplay test. The job summary records the exact commit and every place's SHA256, confirmed version and status, including partial failures. A complete successful run retains only the four verified release files for three days. No QA/showcase/profiler fixtures enter them.

The action stays manual-only and main-only, uses read-only GitHub permissions, and serializes the entire experience with DEPLOY-01's existing concurrency group. It never cancels an upload, follows redirects, or retries an ambiguous request. Missing new IDs causes a clear failure; there is no single-place fallback and no second misleading deploy button.

## Test on your phone

1. After the workflow reports **all four Published / Complete true**, fully leave and rejoin the same private experience in the Roblox phone app using the authorized owner account. Existing servers may still run an older version; use a fresh server when comparing versions. You should first see **Choose your game mode** and exactly three named choices.
2. **Factory Challenge:** tap its button, then walk to your assigned factory. With enough cash, walk into Income Booster's pad without tapping a purchase prompt. It buys once and income rises from 1 to 2. Stay on an unaffordable pad while cash grows: it must not buy later; step completely off and back on to retry. Another owner's pad must not buy for you. Try an open Factory/Settings/Modes panel, respawn, and touch walking. Machinery should show activity; reduced motion keeps it calm. Supply Cache still uses its deliberate claim prompt. Factory progress ends on leaving its server.
3. Tap **Modes → Return to mode selection**, then **Infinite World**. Wait for a Ready property and readable save status. Buy/place/move/rotate/store an object, change a theme, visit another lot, and confirm visitors cannot edit it. Return through Modes: saving pauses edits/earnings and must confirm its final checkpoint before teleport. Re-enter Infinite, and later leave/rejoin the app; confirm the arrangement and balance return. Loading/saving/ownership errors must stay explicit and must never create replacement progress. Factory cash must not appear here. There is no Supply Cache or forced reset.
4. Return to Entry and select **Aim Clash → Practice**. Tap circles through a complete round and check Precision, combo and final breakdown. Live scores stay private. Test standard/reduced motion and portrait/landscape; Controls and Modes must stay reachable. Practice works with one account. For **Duel queue**, join the same Clash server with a second authorized human account and have both choose Duel queue. Verify the shared sequence, server results and disconnect/return cancellation without a manufactured winner. Aim input currently supports mouse/touch; gamepad can navigate menus but has no aim cursor.
5. Test one failed/late join where reproducible: no fake arrival, automatic click loop, or overlapping teleport; source remains paused until failure is confirmed. Infinite must reload safely on failure or give an honest recovery error. Roblox documents that [real teleports cannot be exercised in Studio](https://create.roblox.com/docs/projects/teleport).

Record phone model, orientation, place/version, expected/observed behavior, and screenshots or an error. Phone responsiveness, network fairness, actual cross-place travel and live DataStore durability remain live QA until observed. Historical six-client Infinite hitch measurements remain an open performance risk; CLI success is not a physical-mobile performance pass.

## Offline checks and local previews

```powershell
./scripts/Validate-Project.ps1
./scripts/Invoke-DevelopmentDeployment.ps1 -DryRun
./scripts/New-ModeReviewPlace.ps1 -Role Entry -IncludeQA
./scripts/New-ModeReviewPlace.ps1 -Role Prototype -IncludeQA
./scripts/New-ModeReviewPlace.ps1 -Role Infinite -IncludeQA
./scripts/New-ModeReviewPlace.ps1 -Role Clash -IncludeQA
```

Dry-run ignores credentials/IDs and makes **no HTTP requests**. It builds four explicitly unconfigured artifacts, not publishable configured releases. Local `mode-*.rbxlx` previews use fake destinations and an explicit simulated failure adapter: menu choices report the requested destination, then you open its separate file. They cannot demonstrate a real teleport. Infinite preview saves to memory and resets on Stop. These fixture-bearing previews must never be uploaded.

## Failure, retry and coordinated restore

Multi-place publication is **not atomic**. A failure before Entry leaves the previously published landing place intact, but earlier destinations may already be updated. A failure during Entry can have an unknown outcome. The summary distinguishes **Published** (confirmed version), **Outcome unknown** (request attempted; inspect version history), and **Built** (not attempted). Stop and inspect those exact places in Creator Dashboard before retrying. Never assume a failed/timeout request created no version.

For a transient issue with unchanged intended code/configuration, verify version histories and manually rerun the current workflow; it rebuilds/validates all four and can create additional versions. There is no automatic resume or retry. For a regression, use Creator Dashboard/Studio version history to restore the last known compatible set: restore the earlier Entry first to stop new routing, then restore its matching destinations, keeping IDs and account DataStore schema compatibility. Do not reset DataStores as a rollback. If source must be reverted, do it through a reviewed PR, merge, then manually deploy the compatible four-place revision.

The old single-place prototype remains available in the existing start place's version history. Restoring it is a conscious rollback that removes the integrated menu; don't redeploy its old artifact as an integration update. Restoring one destination alone may break routing or profile expectations. Audience changes, server shutdowns, key changes and external publications remain owner actions.

If publishing rejects API-limited instances, the verifier fails before upload and directs you to manual Studio publishing; it must not omit unsupported scene content. See Roblox's [Place Publishing guide and limitations](https://create.roblox.com/docs/cloud/guides/usage-place-publishing).
