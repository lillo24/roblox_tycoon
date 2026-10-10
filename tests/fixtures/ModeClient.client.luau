--!strict
-- Actual destination isolation observation, installed only in disposable QA copies.
local Players = game:GetService("Players")
local root = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
assert(player, "MODE01 requires actual client")
local remote = root:WaitForChild("TycoonRoutes", 20)
assert(remote and remote:IsA("RemoteEvent"), "MODE01 route remote expected")
local gui = player:WaitForChild("PlayerGui"):WaitForChild("TycoonModeChooser", 20)
assert(gui, "MODE01 chooser expected")
task.wait(11)
local role = root:GetAttribute("TycoonServerRole")
local shared = root:WaitForChild("TycoonShared")
local Config, Rules = require(shared.Config), require(shared.SupplyRules)
if role == "Entry" or role == "Unavailable" then
	assert(not workspace:FindFirstChild(Config.RuntimeName), "Entry cannot allocate factories")
	assert(player:GetAttribute(Config.Attributes.Cash) == nil, "Entry cannot earn")
	assert(not root:FindFirstChild(Rules.StateName), "Entry cannot start SupplyCache")
	assert(not root:FindFirstChild("TycoonProperty"), "Entry cannot expose profile edits")
	assert(not player.PlayerGui:FindFirstChild(Config.HudName), "Entry cannot start gameplay HUD")
	print("MODE01 ACTUAL entry isolation assertions: 5")
elseif role == "Prototype" then
	assert(player:GetAttribute(Config.Attributes.Assignment) == "Assigned", "Session assignment")
	assert(root:FindFirstChild(Rules.StateName), "Session event state")
	assert(not root:FindFirstChild("TycoonProperty"), "Session cannot edit Infinite")
	assert(player:GetAttribute(Config.Attributes.SaveStatus) == nil, "Session cannot claim persistence")
	local cash = player:GetAttribute(Config.Attributes.Cash)
	assert(typeof(cash) == "number" and cash > 0, "Session income")
	print("MODE01 ACTUAL Session isolation assertions: 5")
elseif role == "Infinite" then
	assert(player:GetAttribute(Config.Attributes.Assignment) == "Ready", "Infinite restoration")
	assert(not root:FindFirstChild(Rules.StateName), "Infinite calm")
	assert(root:FindFirstChild("TycoonProperty"), "Infinite editing")
	print("MODE01 ACTUAL Infinite isolation assertions: 3")
end
if role == "Prototype" or role == "Infinite" then
	local hud = player.PlayerGui:FindFirstChild(Config.HudName)
	local launcher = gui:FindFirstChild("Modes")
	assert(hud and hud:IsA("ScreenGui") and launcher and launcher:IsA("TextButton"), "Gameplay controls expected")
	local wasEnabled = hud.Enabled
	hud.Enabled = false
	task.wait()
	assert(not launcher.Visible, "Modes launcher must not cover the property editor")
	hud.Enabled = wasEnabled
	print("MODE01 ACTUAL modal clearance assertion: 1")
end
