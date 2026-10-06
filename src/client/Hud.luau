--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local Config = require(ReplicatedStorage.TycoonShared.Config)
local Catalogue = require(ReplicatedStorage.TycoonShared.UpgradeCatalogue)
local Rules = require(ReplicatedStorage.TycoonShared.SupplyRules)
local SupplyFeedback = require(script.Parent.SupplyFeedback)
local State = require(script.Parent.UiState)
local Preferences = require(script.Parent.UiPreferences)
local View = require(script.Parent.HudView)
local Labels = require(script.Parent.WorldLabels)

local Hud = {}

function Hud.start(): ScreenGui
	local player = Players.LocalPlayer
	assert(player, "Tycoon HUD requires a LocalPlayer")
	local playerGui = player:WaitForChild("PlayerGui")
	local previous = playerGui:FindFirstChild(Config.HudName)
	if previous then
		previous:Destroy()
	end
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.ResetOnSpawn = Config.HudName, false
	gui.ScreenInsets, gui.ClipToDeviceSafeArea = Enum.ScreenInsets.CoreUISafeInsets, true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	local running = true
	local connections: { RBXScriptConnection } = {}
	local function track(connection: RBXScriptConnection)
		table.insert(connections, connection)
	end
	local supply = SupplyFeedback.new(Rules.Tuning.ResultDuration)
	local purchaseText, purchaseVersion = "", 0
	local purchaseTimer: thread? = nil
	local supplyTimer: thread? = nil
	local economy = State.economy(function(attribute: string)
		return player:GetAttribute(attribute)
	end)
	local snapshot: Rules.Snapshot? = nil
	local labels = Labels.start()
	local view: View.Handle
	local function applyPreferences()
		if not running then
			return
		end
		view.refresh()
		labels.refresh(Preferences.read().labels, GuiService.PreferredTransparency)
	end
	view = View.new(gui, applyPreferences)
	local function render()
		if not running then
			return
		end
		view.event(
			State.event(snapshot, workspace:GetServerTimeNow(), economy.assigned),
			if snapshot then snapshot.phase else nil
		)
		view.feedback(purchaseText, supply:read(os.clock()))
	end
	local function update()
		if not running then
			return
		end
		local nextEconomy = State.economy(function(attribute: string)
			return player:GetAttribute(attribute)
		end)
		if nextEconomy.plot ~= economy.plot or nextEconomy.assigned ~= economy.assigned then
			purchaseVersion += 1
			purchaseText = ""
			supply:reset()
		end
		economy = nextEconomy
		view.economy(economy)
		render()
	end
	track(gui.Destroying:Connect(function()
		running = false
		purchaseVersion += 1
		supply:reset()
		if purchaseTimer then
			task.cancel(purchaseTimer)
		end
		if supplyTimer then
			task.cancel(supplyTimer)
		end
		for _, connection in connections do
			connection:Disconnect()
		end
		view.destroy()
		labels.destroy()
	end))
	for _, definition in Catalogue.Definitions do
		track(player:GetAttributeChangedSignal(Catalogue.purchaseAttribute(definition.Id)):Connect(update))
	end
	for _, attribute in
		{ Config.Attributes.Cash, Config.Attributes.IncomeRate, Config.Attributes.PlotId, Config.Attributes.Assignment }
	do
		track(player:GetAttributeChangedSignal(attribute):Connect(update))
	end
	for _, property in { "PreferredTextSize", "PreferredTransparency", "ReducedMotionEnabled" } do
		track(GuiService:GetPropertyChangedSignal(property):Connect(applyPreferences))
	end
	update()
	applyPreferences()
	gui.Parent = playerGui
	-- FIX-01: attach private feedback before purchase/state waits and snapshot reads.
	local supplyRemote = ReplicatedStorage:WaitForChild(Rules.FeedbackName, 10)
	assert(supplyRemote and supplyRemote:IsA("RemoteEvent"), "Tycoon: missing Supply Cache feedback")
	if not running then
		return gui
	end
	track(supplyRemote.OnClientEvent:Connect(function(id: number, message: string)
		if not running then
			return
		end
		local version = supply:receive(id, message, os.clock())
		if not version then
			return
		end
		render()
		if supplyTimer then
			task.cancel(supplyTimer)
		end
		supplyTimer = task.delay(Rules.Tuning.ResultDuration, function()
			supplyTimer = nil
			if running and supply:expire(version, os.clock()) then
				render()
			end
		end)
	end))
	local purchaseRemote = ReplicatedStorage:WaitForChild(Config.FeedbackName, 10)
	assert(purchaseRemote and purchaseRemote:IsA("RemoteEvent"), `Tycoon: missing {Config.FeedbackName}`)
	if not running then
		return gui
	end
	track(purchaseRemote.OnClientEvent:Connect(function(plot: number?, message: string)
		if not running or plot ~= economy.plot then
			return
		end
		purchaseVersion += 1
		local version = purchaseVersion
		purchaseText = message
		render()
		if purchaseTimer then
			task.cancel(purchaseTimer)
		end
		purchaseTimer = task.delay(Config.FeedbackDuration, function()
			purchaseTimer = nil
			if running and purchaseVersion == version then
				purchaseText = ""
				render()
			end
		end)
	end))
	local supplyState = ReplicatedStorage:WaitForChild(Rules.StateName, 10)
	assert(supplyState and supplyState:IsA("StringValue"), "Tycoon: missing Supply Cache snapshot")
	if not running then
		return gui
	end
	local function readSnapshot()
		if not running then
			return
		end
		local nextSnapshot = HttpService:JSONDecode(supplyState.Value) :: Rules.Snapshot
		if supply:snapshot(nextSnapshot.id, nextSnapshot.phase == "idle", os.clock()) then
			snapshot = nextSnapshot
			render()
		end
	end
	track(supplyState:GetPropertyChangedSignal("Value"):Connect(readSnapshot))
	readSnapshot() -- Subscribe before reading; replication is not ordered with the remote.
	local elapsed = 0
	track(RunService.Heartbeat:Connect(function(delta: number)
		elapsed += delta
		if elapsed >= 0.25 then
			elapsed = 0
			render()
		end
	end))
	return gui
end

return Hud
