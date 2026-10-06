--!strict

-- Play-client-only fixture, outside Rojo. Tests actual teardown/recreation adapters.
local Client = game:GetService("StarterPlayer").StarterPlayerScripts.TycoonClient
local HudTypes = require(Client.Hud)
local PreferencesTypes = require(Client.UiPreferences)
local Config = require(game:GetService("ReplicatedStorage").TycoonShared.Config)

return function(Hud: typeof(HudTypes), Preferences: typeof(PreferencesTypes)): number
	assert(
		type(HudTypes.start) == "function" and type(PreferencesTypes.read) == "function",
		"Production HUD/preference interfaces required"
	)
	local player = game:GetService("Players").LocalPlayer
	assert(player, "HUD lifecycle tests require a Play client")
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	assert(playerGui, "HUD lifecycle tests require PlayerGui")
	local runtime = workspace:FindFirstChild(Config.RuntimeName)
	assert(runtime, "HUD lifecycle tests require the real running tycoon")
	local checks = 0
	local function check(condition: boolean, message: string)
		assert(condition, message)
		checks += 1
	end
	local values = Preferences.read()
	local fixture = Instance.new("Model")
	fixture.Name = "UI01LocalLabelFixture"
	fixture:SetAttribute(Config.Attributes.PlotId, 999)
	fixture.Parent = runtime
	local part = Instance.new("Part")
	part.Name, part.Anchored, part.CanCollide, part.Transparency = "Generator", true, false, 1
	part.Parent = fixture
	local function sign(): BillboardGui
		local gui = Instance.new("BillboardGui")
		gui.Name, gui.MaxDistance, gui.AlwaysOnTop = "Ownership", 75, true
		local text = Instance.new("TextLabel")
		text.Parent = gui
		gui.Parent = part
		return gui
	end
	local label = sign()
	task.wait()
	check(label.Enabled == values.labels, "Late ownership label uses current local setting")
	check(not label.AlwaysOnTop and label.MaxDistance == 65, "Scoped nearby label styling")
	local gui = Hud.start()
	task.wait()
	check(
		Preferences.read().large == values.large
			and Preferences.read().labels == values.labels
			and Preferences.read().reduceMotion == values.reduceMotion,
		"HUD recreation preserves session settings"
	)
	local count = 0
	for _, child in playerGui:GetChildren() do
		if child.Name == Config.HudName then
			count += 1
		end
	end
	check(count == 1, "HUD recreation is a singleton")
	check(not (gui:FindFirstChild("Panel", true) :: Frame).Visible, "Recreated HUD starts closed")
	check(game:GetService("ProximityPromptService").Enabled, "Teardown of open panel restores native prompt input")
	check(label.Enabled == values.labels, "Fresh adapter applies retained label preference")
	label.Parent = nil
	task.wait()
	check(
		label.Enabled and label.AlwaysOnTop and label.MaxDistance == 75,
		"Removed instance restores original presentation"
	)
	local replacement = sign()
	task.wait()
	check(
		replacement.Enabled == values.labels and not replacement.AlwaysOnTop,
		"Replacement uses current presentation; no stale restore"
	)
	gui:Destroy()
	task.wait()
	check(
		replacement.Enabled and replacement.AlwaysOnTop and replacement.MaxDistance == 75,
		"HUD destruction restores exact owned label instance"
	)
	local after = sign()
	task.wait()
	check(after.Enabled and after.AlwaysOnTop, "Destroyed adapter has no late listeners")
	label:Destroy()
	fixture:Destroy()
	Hud.start()
	return checks
end
