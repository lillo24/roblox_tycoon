--!strict

-- Disposable observer installed in StarterPlayerScripts only by -IncludeQA.
local player = game:GetService("Players").LocalPlayer
assert(player, "INF01 client observer needs a real client")
local shared = game:GetService("ReplicatedStorage").TycoonShared
local config, rules = require(shared.Config), require(shared.SupplyRules)
local gui = player:WaitForChild("PlayerGui"):WaitForChild(config.HudName)
task.wait(11) -- Observe beyond the ordinary dependency deadline.
assert(player:GetAttribute(config.Attributes.Assignment) == "Ready", "INF01 client: expected ready account")
assert(gui:FindFirstChild("Persistence", true), "INF01 client: missing mode/saving status")
assert(not gui:FindFirstChild("Event", true), "INF01 client: event HUD must be absent")
assert(not game.ReplicatedStorage:FindFirstChild(rules.StateName), "INF01 client: unexpected event state")
assert(not game.ReplicatedStorage:FindFirstChild(rules.FeedbackName), "INF01 client: unexpected event remote")
local runtime = workspace:FindFirstChild(config.RuntimeName)
assert(runtime and not runtime:FindFirstChild(rules.WorldName), "INF01 client: unexpected shared event")
print("INF01 ACTUAL client calm-mode assertions: 6", player.Name)
