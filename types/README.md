# Pinned Roblox analysis definitions

This folder supplies Roblox API declarations to standalone Luau analysis.
`roblox.d.luau` is an unmodified copy of luau-lsp's `scripts/globalTypes.d.luau`
from release **1.70.1**, commit **0382dc76ca9b73df3c8e7c9cd85a8dd493cbd0ae**.
`LICENSE.luau-lsp.txt` preserves the upstream MIT license. These files are inputs,
not gameplay source, and are outside the Rojo mapping and analyzed source scope.

The pinned binary's `--platform roblox` enables Roblox/Rojo resolution but does
**not** embed or download API declarations in standalone mode. Without
`--definitions`, Roblox globals/types are unknown. Versioning this file keeps
local/CI validation independent of moving downloads, user caches, and Studio.

Upstream file:
<https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/0382dc76ca9b73df3c8e7c9cd85a8dd493cbd0ae/scripts/globalTypes.d.luau>

SHA256 (original LF bytes):
`2857efa8245485f8c25c19c018ee1ef9b46afab4efd2ea70fc3257cd3faf7080`.
On a future tool upgrade, inspect its supported CLI, update the pinned definitions
and license from the same release commit, and rerun all type failure probes.

This API snapshot differs from Studio: `Players.LocalPlayer` and
`Workspace.Terrain` are declared non-optional, so the exact GAMEPLAY-01 nullable
diagnostics for those properties are not reproduced. Do not remove the runtime
assertions on that basis. `Players:GetPlayerByUserId()` is optional and the
nullable-return probe verifies rejection of `Player?` assigned to `Player`.
The frozen catalogue-definition/readonly mismatch is also rejected through Rojo resolution.
