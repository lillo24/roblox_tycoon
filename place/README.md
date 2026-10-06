# Authored place and Studio handoff

`tycoon.rbxlx` is the canonical Studio-authored FactoryHub scene. MAP-01 replaces
the old rolling-ball template; the old evidence below is historical. The map
already exists in Edit. No runtime generator is needed to restore it.
See [the current map checkpoint, screenshots and review gate](MAP_01_REVIEW.md).
`build/validation.rbxlx` remains disposable code-only output.

This folder owns the scene snapshot and its save/restore procedure. Luau under
the three mapped code folders remains authoritative on disk. Scripts captured
in a snapshot are copies; re-sync the current checkout before testing an older
snapshot. Never run `rojo build` with an output in this folder or edit the same
mapped scripts through Script Sync.

## FactoryHub map contract

- One Workspace/FactoryHub Model; its PrimaryPart is CacheAnchor.
- Lots/Lot1 through Lot6 Models have matching numeric LotId and Color3 Accent
  attributes. Each model's PrimaryPart is its invisible, anchored Anchor Part.
- Each Foundation is an anchored collidable 60×0.4×70 Part. Anchor is its top
  CFrame; local +X is tangential/right, local -Z points toward the plaza, +Y up.
  Entrance is an invisible Part at local (0,0,-35). Move/rotate the whole lot
  with PivotTo/the Studio pivot tools, including anchors and floor markings.
- Plaza is the known collidable circular support; CacheAnchor sits at its top
  center. One neutral HubSpawn is 15 studs away. Ground, Paths, Streetscape,
  empty floors/trim/numbers and landscaping belong to this saved scene.
- Owners, income equipment, purchase pads/prompts, event state/cache and HUD
  belong to the non-archivable runtime. Never save a Play session.
- Keep entrances and the local machine/pad zones clear. MapLayout validates
  intended support, upright/inward alignment and rectangle separation;
  PlotWorld preflights every interaction/equipment footprint before writes.
  Removing an anchor or inserting a collidable obstacle produces a named error.
- Stop Play before editing. Preserve IDs and transform the whole lot. Uniform
  dimension/ring changes also require updating the explicit reviewed dimensions
  in Assert-AuthoredMap.ps1 and repeating map/walking checks.
- Keep the live default.project.json limited to its three code folders.
  Later code-only changes re-sync current disk code; captured scripts are copies.

The MAP-01 file was persisted from Edit-mode Instances using Studio's native
SerializationService. A temporary project under ignored build/ used pinned Rojo
only to transcode that native model buffer to XML; an XML splice retained scene
service settings/sky and inserted current mapped code. No Rojo build targeted
the authored path, and no export project/generator is required to open or play
the committed scene. XML line endings were normalized to LF for the committed
checkpoint. Ordinary future authoring may use Studio File > Save to File in Edit.

## Historical SETUP-02 evidence (2026-10-05)

Starting main: `0574d7883f7d27138d3b64485b41524ac93f61f7`. The shared `.gitkeep`,
ancestor preservation flags, manual CI dispatch, and PR-only validation were
already present. Exact final tested head, clean-checkout result, and CI link are
recorded in the SETUP-02 PR.

- Verified tools: Rokit 1.2.0, Rojo 7.7.1, StyLua 2.5.2, Selene 0.32.0.
  Working installations were reused; no versions or dependencies changed.
- CLI formatting/lint/build/structural checks passed. The serialized server is
  `ServerScriptService/TycoonServer/Bootstrap` (Script); the client is
  `StarterPlayer/StarterPlayerScripts/TycoonClient/Bootstrap` (LocalScript).
  All three owned Folder destinations exist once and sources match disk.
- Studio 0.741.19.7411056 and the Rojo 7.7.1 plugin were observed running. The
  matching plugin was installed with the pinned CLI and loaded in a separate
  Studio instance opened with the official `EditFile` command-line task.
- The official `%LOCALAPPDATA%\Roblox\mcp.bat` launcher provided MCP inspection
  and play controls over local STDIO (RobloxStudio server 1.0.0). Native Studio
  controls provided plugin connection and the separate Script Analysis check.
  No third-party bridge, public tunnel, or changed security settings were used.
- The original authored XML contained 2,699 instances and 21 existing scripts,
  with no reserved Tycoon folders before sync. All probes used a filesystem copy.
  The user then saved the tested copy from Studio in edit mode; its XML was
  copied to the canonical path without generating or rewriting scene content.
  The final save contains 2,704 instances: every original instance and existing
  script source, plus only the three managed Folders and two bootstraps. Spawn
  CFrame, size, anchoring, and collision properties are unchanged; no probes remain.
  Canonical SHA256: `E68D11363B1C2BF10EF37C12EA566F6E8839940F07579BDCE9DBE57FB38C4B49`.

| Studio gate | Observed result |
| --- | --- |
| A: initial sync/reconnect, markers, owned-folder reconciliation | Passed: six external Folder markers retained their attributes through initial sync and reconnect; the disposable unknown child inside TycoonServer was removed. Exact classes, unique paths, source, and SpawnLocation properties were verified. |
| B: saved disk edit and revert reach the correct scripts | Passed: a distinctive saved server print reached the live Script; exact original source returned after reverting only that edit. |
| C: two solo runs | Passed: each run had exactly one server startup and one client startup in the respective runtime log histories, with no errors observed. |
| Script Analysis | Observed by Codex in the native UI on both the probe and clean restore: all-script analysis displayed zero errors, warnings, information, and hints; the current-script-only filter was unchecked. This is separate from MCP runtime evidence. |
| D: one local server with two clients | Passed: the official StudioTestService launched two clients, Player1 and Player2. The server logged one startup and each client logged one startup; all three context-specific histories contained no errors. The session ended afterward. |
| E: authored save, reopen, and restore from a clean checkout | Passed: user saved the tested scene in edit mode. The exact committed snapshot was reopened from a separate clean checkout and connected to that checkout's Rojo server on loopback port 34873. A saved-source comment and its exact revert were observed through MCP, proving the active server belonged to that checkout. Live hierarchy, spawn, 23 scripts, 2,584 Workspace descendants, and original source were verified. Connected restore play logged one server and one client startup with no errors; it stopped in edit mode. |

All Studio gates are now observed. The exact tested code/scene tree is
`2a05f92b1729ab7460a3d3ccfe267765879ad756`; the following evidence-only documentation
commit leaves that tree unchanged. Final-head CLI/CI results and merge status are
recorded in the SETUP-02 PR. This closes setup readiness for the separate first
gameplay slice; no tycoon gameplay or publishing was added.

Prefer CLI/CI and supported Studio MCP interfaces for QA. GUI-only steps are
manual unless the user explicitly authorizes desktop control for the current
session. Keep user-reported manual results distinct from programmatic checks;
leave a required unobserved Studio gate pending even when CI passes.

## Create or preserve the scene

1. Install/open [Roblox Studio](https://create.roblox.com/docs/studio/setup) and
   sign in. If a working place exists elsewhere, open and inspect it first;
   preserve it and use a disposable copy for probes. Otherwise create a minimal
   Baseplate with an anchored floor and safe SpawnLocation above it.
2. After Studio has initialized, install the matching plugin with
   `rojo plugin install` from this checkout, then reopen Studio. A plugin file
   alone is not connection evidence.
3. From this checkout run `rojo serve default.project.json`. Confirm this terminal
   serves the intended worktree. Connect its plugin to `127.0.0.1:34872` and review
   the sync proposal. If the port is occupied, leave the existing process alone;
   use `rojo serve default.project.json --port 34873` and that port in the plugin.
4. In **edit mode**, use **File > Save to File** (or **Download a Copy**) and choose
   XML place format at this checkout's `place/tycoon.rbxlx`. Keep scratch copies
   outside that exact path. Do not copy a generated build into it.
5. Run `git check-ignore --no-index place/tycoon.rbxlx` (expected exit 1), then
   `git add -- place/tycoon.rbxlx` and confirm `git ls-files --error-unmatch --
   place/tycoon.rbxlx` succeeds. Inspect and commit the real file. Locks, autosaves,
   other places, and `build/` remain ignored. No Git LFS is needed for this scene.

See [Roblox place-file documentation](https://create.roblox.com/docs/projects/place-files).

## Observe gates A-E on a disposable scene copy

- **A:** Add distinct Folder markers outside code-owned folders: Workspace,
  StarterGui, and siblings under ServerScriptService, ReplicatedStorage,
  StarterPlayer, and StarterPlayerScripts. Give each a distinctive Attribute.
  Verify marker classes/attributes survive initial sync and disconnect/reconnect.
  Inspect each owned path for exactly one Folder and the correct Bootstrap class.
  In the disposable copy only, add an unknown Folder inside TycoonServer;
  reconnect and verify it is removed, as configured.
- **B:** Save a distinctive temporary print edit to a bootstrap **on disk** and
  inspect that exact Studio script's Source. Revert only the probe edit on disk
  and observe the original Source return. Do not assume running code hot-reloads.
- **C:** Clear Output, start a solo **Test** (F5), and verify one server startup
  and one client startup in their respective contexts, with no project errors.
  Stop (Shift+F5), repeat, and inspect Script Analysis separately for both strict
  bootstrap scripts. Expected messages are in the root README.
- **D:** Select **Server & Clients**, choose **2** clients, and start (F7).
  Inspect the server's Output and each client's Output: one server startup and
  one client startup per client. Forwarded log display is not duplicate execution.
  End Session afterward. Supported automation can instead call
  `StudioTestService:ExecuteMultiplayerTestAsync(2, testArgs)` in edit mode,
  inspect each actual server/client instance, and call `EndTest` from that test's
  server. A solo MCP play command does not establish this gate. See the
  [StudioTestService API](https://create.roblox.com/docs/reference/engine/classes/StudioTestService).
- **E:** Remove probe markers, save the useful scene in edit mode at the canonical
  path, close/reopen it, reconnect the current checkout, and check scene content
  plus current script sources. Commit the snapshot. In a separate clean checkout
  of that commit, open its tracked snapshot and repeat reconnect/play checks.

For subsequent scene changes: open the tracked snapshot, sync this checkout's
code, edit non-code content in Studio, stop play, save in edit mode to the same
canonical path, inspect its diff, and commit it. Record the tested commit,
Studio/plugin versions, observed paths/classes, context-specific logs, Script
Analysis findings, and A-E results in this file or the PR before merging.

[Studio testing modes](https://create.roblox.com/docs/studio/testing-modes).

## Optional official Studio connection

In Studio's Assistant, choose **... > Manage MCP Servers**, enable **Studio as
MCP server**, and turn on **Codex CLI** under Quick connect. Restart the client
if needed. Preserve other server settings and normal tool approval controls.
Verify the connected-client indicator and actually exposed tools; identify the
correct Studio instance/place before writes. Use local connection only.

If quick connect is unavailable, first verify Roblox's `mcp.bat` exists, then use
the documented Codex STDIO configuration with that official launcher. Do not
configure a nonexistent executable. See the
[Roblox MCP guide](https://create.roblox.com/docs/studio/mcp) and
[official OpenAI MCP documentation](https://developers.openai.com/codex/mcp).
MCP is optional if the gates can be observed manually; it is not another script
source or proof that every documented tool is available in this session.
