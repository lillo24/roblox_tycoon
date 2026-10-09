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
local Bindings = require(script.Parent.RuntimeBindings)
local Guidance = require(script.Parent.FactoryGuidance)
local Onboarding = require(script.Parent.Onboarding)
local Mode = require(ReplicatedStorage.TycoonShared.GameMode)
local Editor = require(script.Parent.PropertyEditor)

local Hud = {}

function Hud.start(): ScreenGui
	local infinite = Mode.read() == "Infinite"
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
	local assignmentTimer: thread? = nil
	local assignmentExpired = false
	local reportedEconomy: string? = nil
	local snapshotError: string? = nil
	local runtime: Bindings.Handle? = nil
	local guidance: Guidance.Handle
	local guidanceText, guidanceActive, panelOpen = "", false, false
	local progress = Onboarding.session()
	local economy = State.economy(function(attribute: string)
		return player:GetAttribute(attribute)
	end, infinite)
	local snapshot: Rules.Snapshot? = nil
	local labels = Labels.start()
	local view: View.Handle
	local editor: { open: () -> (), destroy: () -> () }? = nil
	local render: () -> () = function() end
	local function applyPreferences()
		if not running then
			return
		end
		view.refresh()
		labels.refresh(Preferences.read().labels, GuiService.PreferredTransparency)
	end
	view = View.new(gui, applyPreferences, {
		edit = function()
			if editor then
				editor.open()
			end
		end,
		find = function()
			guidance.start()
		end,
		stop = function()
			guidance.stop()
		end,
		dismiss = function()
			Onboarding.dismiss(progress)
			render()
		end,
		restart = function()
			Onboarding.restart(progress)
			render()
		end,
		panel = function(open: boolean)
			panelOpen = open
			guidance.pause(open)
			render()
		end,
	})
	guidance = Guidance.new(player, gui, function(value: string, active: boolean)
		guidanceText, guidanceActive = value, active
		render()
	end)
	render = function()
		if not running then
			return
		end
		local eventText = State.event(snapshot, workspace:GetServerTimeNow(), economy.assigned)
		local binding = runtime
		if not snapshot and (snapshotError or binding and binding.status(Rules.StateName) == "unavailable") then
			eventText = "Supply Cache unavailable\nServer event state is not ready"
		elseif
			not snapshot
			and binding
			and (binding.status(Rules.FeedbackName) ~= "ready" or binding.status(Config.FeedbackName) ~= "ready")
		then
			eventText = "Supply Cache\nWaiting for feedback channels"
		end
		view.event(if infinite then State.persistence(economy) else eventText, if snapshot then snapshot.phase else nil)
		local supplyText = if infinite then "" else supply:read(os.clock())
		view.feedback(purchaseText, supplyText)
		local hint = if infinite then "" else Onboarding.text(progress, economy, os.clock())
		local urgent = snapshot
			and (snapshot.phase == "warning" or snapshot.phase == "open" or snapshot.phase == "result")
		view.guidance(
			if guidanceActive then guidanceText elseif urgent then "" else hint,
			guidanceActive,
			not panelOpen and purchaseText == "" and supplyText == ""
		)
		view.context(
			if economy.assigned then guidanceText else Onboarding.help(progress, economy),
			guidanceActive,
			Onboarding.help(progress, economy),
			if binding and binding.status(Config.FeedbackName) ~= "ready"
				then "Purchase feedback " .. binding.status(Config.FeedbackName)
				else ""
		)
	end
	local function update()
		if not running then
			return
		end
		local nextEconomy = State.economy(function(attribute: string)
			return player:GetAttribute(attribute)
		end, infinite)
		if
			not nextEconomy.assigned
			and not nextEconomy.full
			and not nextEconomy.loading
			and assignmentExpired
			and not nextEconomy.unavailable
		then
			nextEconomy.unavailable = "Factory assignment timed out"
		end
		if nextEconomy.unavailable and nextEconomy.unavailable ~= reportedEconomy then
			warn(`Tycoon HUD: {player:GetFullName()} factory state unavailable: {nextEconomy.unavailable}`)
		end
		reportedEconomy = nextEconomy.unavailable
		if nextEconomy.plot ~= economy.plot or nextEconomy.assigned ~= economy.assigned then
			purchaseVersion += 1
			purchaseText = ""
			supply:reset()
		end
		economy = nextEconomy
		guidance.assignment(economy.plot, economy.full)
		Onboarding.observe(progress, economy, os.clock())
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
		if assignmentTimer then
			task.cancel(assignmentTimer)
		end
		if runtime then
			runtime.destroy()
		end
		guidance.destroy()
		for _, connection in connections do
			connection:Disconnect()
		end
		view.destroy()
		if editor then
			editor.destroy()
		end
		labels.destroy()
	end))
	for _, definition in Catalogue.Definitions do
		track(player:GetAttributeChangedSignal(Catalogue.purchaseAttribute(definition.Id)):Connect(update))
	end
	for _, attribute in
		{
			Config.Attributes.Cash,
			Config.Attributes.IncomeRate,
			Config.Attributes.PlotId,
			Config.Attributes.Assignment,
			Config.Attributes.SaveStatus,
		}
	do
		track(player:GetAttributeChangedSignal(attribute):Connect(update))
	end
	for _, property in { "PreferredTextSize", "PreferredTransparency", "ReducedMotionEnabled" } do
		track(GuiService:GetPropertyChangedSignal(property):Connect(applyPreferences))
	end
	update()
	applyPreferences()
	gui.Parent = playerGui
	if infinite then
		editor = Editor.new(gui)
	end
	assignmentTimer = task.delay(Bindings.Timeout, function()
		assignmentTimer = nil
		assignmentExpired = true
		update()
	end)
	-- FIX-01: ordered non-yielding binding attaches feedback before snapshot reads,
	-- including dependencies arriving after the documented ten-second deadline.
	local specs: { Bindings.Spec } = {
		{
			name = Rules.FeedbackName,
			class = "RemoteEvent",
			bind = function(instance: Instance): () -> ()
				assert(instance:IsA("RemoteEvent"), "HUD supply binding expected RemoteEvent")
				local connection = instance.OnClientEvent:Connect(function(id: number, message: string)
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
				end)
				return function()
					connection:Disconnect()
					supply:reset()
				end
			end,
		},
		{
			name = Config.FeedbackName,
			class = "RemoteEvent",
			bind = function(instance: Instance): () -> ()
				assert(instance:IsA("RemoteEvent"), "HUD purchase binding expected RemoteEvent")
				local connection = instance.OnClientEvent:Connect(function(plot: number?, message: string)
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
				end)
				return function()
					connection:Disconnect()
					purchaseVersion += 1
					purchaseText = ""
				end
			end,
		},
		{
			name = Rules.StateName,
			class = "StringValue",
			requires = { Rules.FeedbackName, Config.FeedbackName },
			bind = function(instance: Instance): () -> ()
				assert(instance:IsA("StringValue"), "HUD snapshot binding expected StringValue")
				local function readSnapshot()
					if not running then
						return
					end
					-- Only this external JSON decoding operation is caught. Internal render,
					-- binding and helper errors retain their normal diagnostics/test failures.
					local decoded, value = pcall(HttpService.JSONDecode, HttpService, instance.Value)
					local nextSnapshot: Rules.Snapshot? = nil
					local issue: string? = nil
					if decoded then
						nextSnapshot, issue = State.snapshot(value)
					else
						issue = "invalid JSON: " .. tostring(value)
					end
					if not nextSnapshot then
						if issue ~= snapshotError then
							warn(`Tycoon HUD: {instance:GetFullName()} unavailable: {issue}`)
						end
						snapshotError, snapshot = issue, nil
						render()
						return
					end
					snapshotError = nil
					if supply:snapshot(nextSnapshot.id, nextSnapshot.phase == "idle", os.clock()) then
						snapshot = nextSnapshot
						render()
					end
				end
				local connection = instance:GetPropertyChangedSignal("Value"):Connect(readSnapshot)
				readSnapshot() -- Subscribe before reading; replication is not ordered with the remote.
				return function()
					connection:Disconnect()
					snapshot, snapshotError = nil, nil
				end
			end,
		},
	}
	if infinite then
		-- Keep only purchase feedback. Deliberately absent SupplyCache services
		-- have no listeners/deadlines/recovery watches in this mode.
		table.remove(specs, 3)
		table.remove(specs, 1)
	end
	runtime = Bindings.start(ReplicatedStorage, specs, render)
	render()
	local elapsed = 0
	track(RunService.Heartbeat:Connect(function(delta: number)
		guidance.tick(delta)
		elapsed += delta
		if elapsed >= 0.25 then
			elapsed = 0
			render()
		end
	end))
	return gui
end

return Hud
