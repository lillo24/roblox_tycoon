# Authored place and Studio handoff

`tycoon.rbxlx` is the reserved canonical **Studio-authored** scene source. It is
currently absent: an ignore exception is not a backup. Save a real scene from
Studio in edit mode before treating this setup milestone as complete.
`build/validation.rbxlx` is disposable code-only output and cannot restore a scene.

This folder owns the scene snapshot and its save/restore procedure. Luau under
the three mapped code folders remains authoritative on disk. Scripts captured
in a snapshot are copies; re-sync the current checkout before testing an older
snapshot. Never run `rojo build` with an output in this folder or edit the same
mapped scripts through Script Sync.

## Current evidence (2026-10-05)

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
- No Studio executable in the usual installation roots, Roblox installed-app
  entry, Studio protocol registration, or running Studio process was found.
  No matching plugin file or official `%LOCALAPPDATA%\Roblox\mcp.bat` launcher
  was found, and this session exposes no Studio tools. Studio/plugin versions
  and login are unverified; installation and connection were not attempted.
- Searches of Documents, Downloads, Desktop, and the local Roblox folder,
  including ignored files, found only the generated validation place.
  No authored snapshot, live hierarchy, or runtime observation is claimed.

| Studio gate | Observed result |
| --- | --- |
| A: initial sync/reconnect, markers, owned-folder reconciliation | Pending: Studio unavailable |
| B: saved disk edit and revert reach the correct scripts | Pending: Studio unavailable |
| C: two solo runs and separate Script Analysis | Pending: Studio unavailable |
| D: one local server with two clients | Pending: Studio unavailable |
| E: authored save, reopen, and restore from a clean checkout | Pending: no authored snapshot |

The PR must remain unmerged until these gates and snapshot tracking are observed.
CLI success does not establish readiness for gameplay.

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
  End Session afterward. A solo MCP play command does not establish this gate.
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
