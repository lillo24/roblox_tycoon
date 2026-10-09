--!strict

local Client = game:GetService("StarterPlayer").StarterPlayerScripts.TycoonClient
local HudTypes = require(Client.Hud)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.TycoonShared.Config)
local Rules = require(ReplicatedStorage.TycoonShared.SupplyRules)

return function(Hud: typeof(HudTypes)): number
	assert(type(HudTypes.start) == "function", "Production HUD required")
	local player = game:GetService("Players").LocalPlayer
	assert(player, "Readiness test needs a Play client")
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	assert(playerGui, "Readiness test needs PlayerGui")
	local state = ReplicatedStorage:FindFirstChild(Rules.StateName)
	assert(state and state:IsA("StringValue"), "Readiness test needs a real snapshot")
	local holder = Instance.new("Folder")
	local replacement = Instance.new("StringValue")
	replacement.Name, replacement.Value = Rules.StateName, "malformed external JSON"
	local checks = 0
	local function check(value: boolean, message: string)
		assert(value, message)
		checks += 1
	end
	local ok, failure = xpcall(function()
		state.Parent = holder -- Client-only delivery fixture, no server/economy mutation.
		local gui = Hud.start()
		task.wait(0.1)
		local event = gui:FindFirstChild("Event", true) :: TextLabel
		local summary = gui:FindFirstChild("Summary", true) :: TextLabel
		check(string.find(event.Text, "Waiting", 1, true) ~= nil, "Missing event remains pending initially")
		check(
			gui:FindFirstChild("Settings", true) ~= nil and gui:FindFirstChild("Help", true) ~= nil,
			"Basic shell remains usable"
		)
		task.wait(10.1)
		check(string.find(event.Text, "unavailable", 1, true) ~= nil, "Actual HUD exposes bounded timeout")
		check(string.find(summary.Text, "Cash", 1, true) ~= nil, "Event failure does not erase assigned cash")
		replacement.Parent = ReplicatedStorage
		task.wait(0.1)
		check(string.find(event.Text, "unavailable", 1, true) ~= nil, "Malformed JSON remains an unavailable state")
		replacement.Value = state.Value
		task.wait(0.1)
		check(string.find(event.Text, "unavailable", 1, true) == nil, "Valid later value recovers actual HUD")
		replacement:Destroy()
		state.Parent = ReplicatedStorage
		task.wait(0.1)
		check(string.find(event.Text, "unavailable", 1, true) == nil, "Exact dependency replacement recovers")
		gui:Destroy()
		task.wait()
		check(playerGui:FindFirstChild(Config.HudName) == nil, "Readiness teardown removes HUD")
		Hud.start()
		return checks
	end, function(message: any): string
		return debug.traceback(tostring(message), 2)
	end)
	replacement:Destroy()
	state.Parent = ReplicatedStorage
	holder:Destroy()
	if not ok then
		error(failure)
	end
	return checks
end
