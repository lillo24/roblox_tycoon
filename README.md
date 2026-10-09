# roblox_tycoon

An early-stage Roblox multiplayer tycoon. Each owner has a temporary plot and
session cash, and can choose the order of four one-time upgrades. This catalogue
is a reversible prototype experiment with provisional costs/effects. A compact
HUD observes server state and private purchase results. A provisional shared
Supply Cache opens first after 20 seconds, then every 30 seconds; the first valid
server-processed claim receives 10 cash. Six inward-facing factory lots and a shared plaza are saved in the editable
Studio scene; ownership, equipment, prompts and UI are created only during Play.
See [the MAP-01 checkpoint and visual review](place/MAP_01_REVIEW.md). See [gameplay behavior,
tuning, source responsibilities, and QA](src/README.md).

The **combined draft** includes MAP-01, UI-01 and UX-02 factory guidance,
first-purchase hints and recoverable startup states. Use the
[UX-02 preview and consolidated QA checkpoint](docs/UX_02_REVIEW.md) for current
startup/review instructions. The source review packets retain historical evidence;
final approval and consolidation belong to this combined checkpoint.

## Prerequisites

- [Git](https://git-scm.com/downloads), installed separately.
- [Roblox Studio](https://create.roblox.com/docs/studio/setup), installed manually
  for editing places and playtesting. CLI checks do not require Studio.
- [Rokit 1.2.0](https://github.com/rojo-rbx/rokit/releases/tag/v1.2.0), installed
  separately as the toolchain manager. It manages the exact versions below through
  `rokit.toml`; no Node/npm or Rust installation is required.

| Tool | Pinned version | Purpose |
| --- | --- | --- |
| Rojo | 7.7.1 | Synchronize Luau into Studio and validate the mapping |
| StyLua | 2.5.2 | Format Luau |
| Selene | 0.32.0 | Lint with Roblox globals and rules |
| luau-lsp | 1.70.1 | Standalone Luau type analysis with Roblox/Rojo resolution |

Run all project commands from the repository root so Rokit selects these versions.

## First-time setup

On Windows x64, install Rokit with PowerShell (skip if 1.2.0 is already installed):

```powershell
$rokitSetup = Join-Path $env:TEMP ('rokit-setup-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory $rokitSetup | Out-Null
$archive = Join-Path $rokitSetup 'rokit.zip'
Invoke-WebRequest 'https://github.com/rojo-rbx/rokit/releases/download/v1.2.0/rokit-1.2.0-windows-x86_64.zip' -OutFile $archive
$expected = 'f9ba1704014ff67d51e8005f605955c7c26d2429a5312a9419dc477fc310e96d'
if ((Get-FileHash $archive -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expected) {
    throw 'Rokit archive checksum mismatch.'
}
Expand-Archive $archive -DestinationPath $rokitSetup
& (Join-Path $rokitSetup 'rokit.exe') self-install
```

Open a new terminal after installation. If an already-running editor still has the
old PATH, restart it or refresh this PowerShell session with:

```powershell
$env:PATH = "$env:USERPROFILE\.rokit\bin;$env:PATH"
```

On other supported platforms, download the matching 1.2.0 archive from the release
page, extract it, and run `rokit self-install` using the extracted executable.

Clone the repository if needed, then install the pinned tools:

```powershell
git clone https://github.com/lillo24/roblox_tycoon.git
cd roblox_tycoon
rokit --version
rokit trust rojo-rbx/rojo johnnymorganz/stylua kampfkarren/selene johnnymorganz/luau-lsp
rokit install
rojo --version
stylua --version
selene --version
luau-lsp --version
```

If you already have the clone, just open its root and start with `rokit --version`.
The trust command records the four upstream tool repositories explicitly.
Installing tools and Selene's first Roblox definition download require internet
access. Selene uses its normal user cache and periodically refreshes definitions.

After installing and opening Studio once, close it and install the matching plugin:

```powershell
rojo plugin install
```

Reopen Studio to load the plugin. Repeat this command after changing Rojo versions.
See the [official Rojo installation guide](https://rojo.space/docs/v7/getting-started/installation/).

## Daily workflow

1. From the repository root, start `rojo serve default.project.json` and leave the
   terminal running. Stop it with Ctrl+C when finished.
2. Open the tracked Studio-authored `place/tycoon.rbxlx` in Studio. Follow
   [the Studio handoff](place/README.md) for save/restore steps and observed checks.
3. Open the Rojo plugin and connect to `127.0.0.1:34872`. Review the initial sync
   before accepting it, especially if these folder names already exist.
4. Confirm the three folders in the mapping below appear in Studio's Explorer.
5. Edit Luau under `src/`; Rojo syncs saved code into Studio. Create world, UI,
   terrain, models, animations, and other art directly in Studio.
6. Use **Play** (F5), then open Studio's Output window and confirm both messages:

   ```text
   [roblox_tycoon] Server bootstrap ready.
   [roblox_tycoon] Client bootstrap ready.
   ```

   Follow a spoke from the central plaza to your numbered factory (the HUD shows
   your assignment). Approach a labeled pad to use its built-in prompt. Income
   Booster costs 10 cash and raises income from 1 to 2/sec. Workshop is another
   initial option; each unlocks a follow-up. The shared Supply Cache is in the
   plaza, away from the spawn. Approach during its ten-second window to claim
   once, without resetting factories or changing income. See src/README.md.
7. Stop the playtest and run the CLI checks below before committing changes.
   Save scene changes in edit mode to `place/tycoon.rbxlx` and commit the snapshot
   with the source changes; scratch places and generated builds remain ignored.

For implementation work, follow `AGENTS.md`: use an isolated branch/worktree,
push the branch, and open a PR into `main`. Merge after the relevant CI passes
and any consequential review decisions are resolved, then clean up the branch
and task worktree. Do not push implementation changes directly to `main`.

## Source ownership

| Filesystem source | Studio destination |
| --- | --- |
| `src/server` | `ServerScriptService/TycoonServer` |
| `src/shared` | `ReplicatedStorage/TycoonShared` |
| `src/client` | `StarterPlayer/StarterPlayerScripts/TycoonClient` |

Filesystem/Git is authoritative for these three code folders. Keep them reserved
for repository content: Rojo may remove unknown instances **inside these folders**
so they match disk. Edit synced code on disk; Studio edits are not written back.
The shared folder contains general tuning in `Config.luau` and the typed, validated
upgrade source of truth in `UpgradeCatalogue.luau`, plus the provisional event
rules and snapshot schema in `SupplyRules.luau`; `.gitkeep` remains
as the original directory marker.

Studio is authoritative for all other world/UI/art content for now. The project
explicitly preserves unknown children at the DataModel and service/container
levels. It does not map Workspace, StarterGui, terrain, or whole services to disk.
Keep Studio-created content outside the three reserved folders. Their parents are
only routing containers, with no service properties configured.

Studio-authored non-code content is backed up through the tracked
`place/tycoon.rbxlx` snapshot. Scripts captured in it are copies; re-sync current disk code
when opening an older snapshot. A CLI build contains only the mapped code and
containers and cannot reconstruct the scene. Never build over the authored path.
See [save/restore steps and observed Studio gate status](place/README.md).

## Validation

Format all repository Luau:

```powershell
stylua src tests
```

Run the same complete validation used in CI:

```powershell
./scripts/Validate-Project.ps1
```

This runs scope tests, `stylua --check src tests`, `selene src tests`, a fresh
`rojo build default.project.json --output build/validation.rbxlx`, serialized
structure/source assertions, regression probes, a fresh one-shot Rojo sourcemap,
`luau-lsp analyze` of **src and tests**, type failure probes, and Git tracking/ignore
checks. The generated paths are fixed under ignored `build/`, and linked output paths are
rejected. The canonical Studio file is never a build target. Native failures stop
validation. A missing authored snapshot is reported as a pending Studio gate.
On macOS/Linux use `pwsh -File ./scripts/Validate-Project.ps1`; use manual CI below
if PowerShell is unavailable locally. These checks type-check Luau but do not
execute gameplay or the standalone Studio session tests.

Type analysis uses the [pinned Roblox definitions](types/README.md), without a
moving API-definition download. See [exact commands and regression coverage](scripts/README.md).
Ordinary Git/Rojo source type errors must fail this gate before Studio QA.

GitHub Actions validates PRs targeting `main`; it does not duplicate validation
on branch pushes or the resulting merge push. Every PR reports the same `validate`
job status. Scope-policy tests always run; tool installation and Luau/build checks
are skipped only when every changed path is Markdown. Every other change,
including root/tooling/workflow configuration or a deleted source file, runs the
complete suite. This keeps future file types covered without workflow path
filters that could leave a required check pending. See `scripts/README.md` for the
policy and its tests.

To run the complete suite regardless of changed files, select **Actions > Validate
> Run workflow** on GitHub, or use the GitHub CLI:

```powershell
gh workflow run validate.yml --ref main
```

Use this manual checkpoint for releases, integration checks, CI changes, or
debugging. The local commands above also run the complete suite. CI uses Rokit
1.2.0 and the pinned tools, downloads Rokit from its official release, verifies
the archive checksum, and skips interactive trust checks only on the CI runner.
It does not deploy or publish the game. Type analysis does not execute scripts or
replace runtime playtests. Studio Script Analysis is an integration check for
Studio-authored scripts outside Rojo, full-place/live DataModel context, suspected
analyzer discrepancies, major integration checkpoints, and Studio-only diagnostics.
Do not request a manual Script Analysis pass after every ordinary `src/` edit
covered by automated analysis. luau-lsp is not identical to Studio's analyzer;
the pinned API snapshot's known nullable-property differences are documented in
`types/README.md`.

## Initial setup status (2026-10-02)

The starting clone was empty, with no commit on `main`; GitHub also reported `main`
as the default branch. Git 2.53.0 and GitHub CLI 2.96.0 were available. Rokit, Rojo,
StyLua, and Selene were absent. No Roblox Studio executable, installed-app record,
protocol registration, or running Studio process was found.

At initial setup, Rokit and the pinned CLI tools were installed locally. Studio
and plugin checks were pending. The latest reinspection and separate live sync,
solo, Script Analysis, two-client, and save/restore gates are recorded in
[the Studio handoff](place/README.md); this historical section is not a live result.

Local validation passed: `rokit install`, all tool version commands,
`stylua --check src`, `selene src` (zero errors, warnings, or parse errors), and
`rojo build default.project.json --output build/validation.rbxlx`. The generated
place contains the expected three folders and server/client script classes.
`rojo serve default.project.json` also started and returned HTTP 200 for its local
dashboard and API; the temporary server was stopped after checking it. Routing
container preservation flags and Git's build-output ignore rule were checked.
Current remote validation results are recorded in PR checks and GitHub Actions.

Wally, packages, gameplay frameworks, persistence, custom purchase remotes, binary assets,
Git LFS, and publishing automation are deferred until there is an actual need.
