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

-- Exercise real client replication ordering: descendants may precede attributes.
if not game:GetService("GuiService").ReducedMotionEnabled then
	local camera = workspace.CurrentCamera
	assert(camera and runtime, "INF03 activity fixture needs a camera/runtime")
	local part = Instance.new("Part")
	part.Name, part.Anchored, part.CanCollide, part.CanTouch = "INF03LateActivity", true, false, false
	part.CFrame, part.Parent = camera.CFrame * CFrame.new(0, 0, -10), runtime
	task.wait(0.2)
	part:SetAttribute("Activity", "spin")
	part:SetAttribute("RestFrame", part.CFrame)
	local before = part.CFrame
	task.wait(0.4)
	local moved = before ~= part.CFrame
	part:Destroy()
	assert(moved, "INF03: late animation metadata must start visible activity")
	print("INF03 ACTUAL late-metadata activity assertion: 1")
else
	print("INF03 activity observation skipped: platform reduced motion is enabled")
end
