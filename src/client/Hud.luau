--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.TycoonShared.Config)
local Catalogue = require(ReplicatedStorage.TycoonShared.UpgradeCatalogue)
local SupplyRules = require(ReplicatedStorage.TycoonShared.SupplyRules)
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local SupplyFeedback = require(script.Parent.SupplyFeedback)

local Hud = {}

function Hud.start()
	local player = Players.LocalPlayer
	assert(player, "Tycoon: HUD must start on a client with a LocalPlayer")
	local playerGui = player:WaitForChild("PlayerGui")
	assert(not playerGui:FindFirstChild(Config.HudName), "Tycoon: HUD started twice")
	local running = true
	local connections: { RBXScriptConnection } = {}
	local function track(connection: RBXScriptConnection)
		table.insert(connections, connection)
	end
	local eventFeedback = SupplyFeedback.new(SupplyRules.Tuning.ResultDuration)
	local gui = Instance.new("ScreenGui")
	gui.Name = Config.HudName
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.ClipToDeviceSafeArea = true
	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0)
	panel.Position = UDim2.new(0.5, 0, 0, 12)
	panel.Size = UDim2.new(0.86, 0, 0, 300)
	panel.BackgroundColor3 = Color3.fromRGB(24, 28, 36)
	panel.BackgroundTransparency = 0.12
	panel.Parent = gui
	local constraint = Instance.new("UISizeConstraint")
	constraint.MaxSize = Vector2.new(360, 300)
	constraint.Parent = panel
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = panel
	local cash = Instance.new("TextLabel")
	cash.Name = "Cash"
	cash.Position = UDim2.fromOffset(12, 8)
	cash.Size = UDim2.new(1, -24, 0, 30)
	cash.BackgroundTransparency = 1
	cash.TextColor3 = Color3.new(1, 1, 1)
	cash.Font = Enum.Font.GothamBold
	cash.TextSize = 22
	cash.Parent = panel
	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.Position = UDim2.fromOffset(12, 36)
	status.Size = UDim2.new(1, -24, 0, 36)
	status.BackgroundTransparency = 1
	status.TextColor3 = Color3.fromRGB(219, 231, 245)
	status.Font = Enum.Font.Gotham
	status.TextSize = 14
	status.TextWrapped = true
	status.Parent = panel
	local eventLine = Instance.new("TextLabel")
	eventLine.Name = "SupplyEvent"
	eventLine.Position = UDim2.fromOffset(12, 76)
	eventLine.Size = UDim2.new(1, -24, 0, 44)
	eventLine.BackgroundTransparency = 1
	eventLine.TextColor3 = Color3.fromRGB(141, 238, 233)
	eventLine.Font = Enum.Font.Gotham
	eventLine.TextSize = 12
	eventLine.TextWrapped = true
	eventLine.Parent = panel
	local upgradeList = Instance.new("ScrollingFrame")
	upgradeList.Name = "UpgradeList"
	upgradeList.Position = UDim2.fromOffset(12, 124)
	upgradeList.Size = UDim2.new(1, -24, 0, 136)
	upgradeList.CanvasSize = UDim2.fromOffset(0, #Catalogue.Definitions * 34)
	upgradeList.BackgroundTransparency = 1
	upgradeList.BorderSizePixel = 0
	upgradeList.ScrollBarThickness = 4
	upgradeList.ScrollingDirection = Enum.ScrollingDirection.Y
	upgradeList.Parent = panel
	local rows: { [Catalogue.Id]: TextLabel } = {}
	for index, definition in Catalogue.Definitions do
		local row = Instance.new("TextLabel")
		row.Name = definition.Id
		row.Position = UDim2.fromOffset(0, (index - 1) * 34)
		row.Size = UDim2.new(1, -6, 0, 32)
		row.BackgroundTransparency = 1
		row.TextColor3 = Color3.fromRGB(219, 231, 245)
		row.Font = Enum.Font.Gotham
		row.TextSize = 12
		row.TextWrapped = true
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.Parent = upgradeList
		rows[definition.Id] = row
	end
	local result = Instance.new("TextLabel")
	result.Name = "PurchaseResult"
	result.Position = UDim2.fromOffset(12, 218)
	result.Size = UDim2.new(1, -24, 0, 24)
	result.BackgroundTransparency = 1
	result.TextColor3 = Color3.fromRGB(255, 223, 123)
	result.Font = Enum.Font.GothamBold
	result.TextSize = 14
	result.TextWrapped = true
	result.Text = ""
	result.Parent = panel
	local function resize()
		if not running then
			return
		end
		-- Keep feedback visible on short landscape/editor viewports; scroll the list.
		local height = math.min(300, math.max(196, gui.AbsoluteSize.Y - 24))
		panel.Size = UDim2.new(0.86, 0, 0, height)
		constraint.MaxSize = Vector2.new(360, height)
		upgradeList.Size = UDim2.new(1, -24, 0, height - 164)
		result.Position = UDim2.fromOffset(12, height - 34)
	end
	track(gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize))
	local resultVersion = 0
	local lastPlot: number? = nil
	local lastAssigned = false
	local eventSnapshot: SupplyRules.Snapshot? = nil
	local function renderEvent()
		local snapshot = eventSnapshot
		if running and snapshot then
			local message = eventFeedback:read(os.clock())
			eventLine.Text = SupplyRules.describe(snapshot, workspace:GetServerTimeNow(), lastAssigned)
				.. (if message ~= "" then "\n" .. message else "")
		end
	end
	gui.Destroying:Connect(function()
		running = false
		resultVersion += 1
		eventFeedback:reset()
		for _, connection in connections do
			connection:Disconnect()
		end
	end)

	local function update()
		if not running then
			return
		end
		local balance = player:GetAttribute(Config.Attributes.Cash)
		local income = player:GetAttribute(Config.Attributes.IncomeRate)
		local plot = player:GetAttribute(Config.Attributes.PlotId)
		local assigned = player:GetAttribute(Config.Attributes.Assignment) == "Assigned"
			and typeof(plot) == "number"
			and typeof(balance) == "number"
			and typeof(income) == "number"
		local currentPlot = if assigned and typeof(plot) == "number" then plot else nil
		if currentPlot ~= lastPlot or assigned ~= lastAssigned then
			resultVersion += 1
			result.Text = ""
			eventFeedback:reset()
		end
		lastPlot = currentPlot
		lastAssigned = assigned
		local purchases: Catalogue.Purchases = {}
		local count = 0
		for _, definition in Catalogue.Definitions do
			local purchased = assigned and player:GetAttribute(Catalogue.purchaseAttribute(definition.Id)) == true
			purchases[definition.Id] = purchased
			if purchased then
				count += 1
			end
		end
		for _, definition in Catalogue.Definitions do
			local state = if assigned and typeof(balance) == "number"
				then Catalogue.stateText(definition, purchases, balance)
				else "Awaiting plot"
			local row = rows[definition.Id]
			row.Text = `{definition.DisplayName} • {definition.Cost} cash • +{definition.IncomeDelta}/tick\n{state}`
			row.TextColor3 = if purchases[definition.Id]
				then Color3.fromRGB(143, 246, 164)
				else Color3.fromRGB(219, 231, 245)
		end
		cash.Text = if typeof(balance) == "number" then `Cash: {balance}` else "Cash: —"
		if assigned then
			local hint = if count == #Catalogue.Definitions
				then "Complete — income continues"
				else `{count}/{#Catalogue.Definitions} owned • Choose a pad`
			status.Text = `Plot {plot} • +{income}/sec\n{hint}`
		else
			status.Text = if player:GetAttribute(Config.Attributes.Assignment) == "Full"
				then "Plots full — no income this session"
				else "Joining…"
		end
		renderEvent()
	end
	for _, definition in Catalogue.Definitions do
		track(player:GetAttributeChangedSignal(Catalogue.purchaseAttribute(definition.Id)):Connect(update))
	end
	for _, attribute in
		{ Config.Attributes.Cash, Config.Attributes.IncomeRate, Config.Attributes.PlotId, Config.Attributes.Assignment }
	do
		track(player:GetAttributeChangedSignal(attribute):Connect(update))
	end
	update()
	-- Listen before either the purchase/state waits or the first snapshot read.
	-- RemoteEvent delivery does not order the replicated StringValue ahead of it.
	local supplyFeedback = ReplicatedStorage:WaitForChild(SupplyRules.FeedbackName, 10)
	assert(supplyFeedback and supplyFeedback:IsA("RemoteEvent"), "Tycoon: missing Supply Cache feedback")
	track(supplyFeedback.OnClientEvent:Connect(function(id: number, message: string)
		if not running then
			return
		end
		local version = eventFeedback:receive(id, message, os.clock())
		if not version then
			return
		end
		renderEvent()
		task.delay(SupplyRules.Tuning.ResultDuration, function()
			if running and eventFeedback:expire(version, os.clock()) then
				renderEvent()
			end
		end)
	end))
	local feedback = ReplicatedStorage:WaitForChild(Config.FeedbackName, 10)
	assert(feedback and feedback:IsA("RemoteEvent"), `Tycoon: missing feedback RemoteEvent {Config.FeedbackName}`)
	track(feedback.OnClientEvent:Connect(function(resultPlot: number?, message: string)
		-- Late results for a previous assignment cannot contaminate the new HUD.
		if not running or resultPlot ~= lastPlot then
			return
		end
		resultVersion += 1
		local version = resultVersion
		result.Text = message -- Repeated identical results still refresh the lifetime.
		task.delay(Config.FeedbackDuration, function()
			if version == resultVersion then
				result.Text = ""
			end
		end)
	end))
	local supplyState = ReplicatedStorage:WaitForChild(SupplyRules.StateName, 10)
	assert(supplyState and supplyState:IsA("StringValue"), "Tycoon: missing Supply Cache snapshot")
	local function readEvent()
		if not running then
			return
		end
		-- A server-authored atomic JSON value; this cast is presentation, never claim authority.
		local snapshot = HttpService:JSONDecode(supplyState.Value) :: SupplyRules.Snapshot
		if eventFeedback:snapshot(snapshot.id, snapshot.phase == "idle", os.clock()) then
			eventSnapshot = snapshot
			renderEvent()
		end
	end
	track(supplyState:GetPropertyChangedSignal("Value"):Connect(readEvent))
	readEvent() -- Subscribe before reading so initialization/late joins cannot miss state.
	local eventElapsed = 0
	track(RunService.Heartbeat:Connect(function(delta: number)
		eventElapsed += delta
		if eventElapsed >= 0.25 then
			eventElapsed = 0
			renderEvent()
		end
	end))
	gui.Parent = playerGui
	resize()
end

return Hud
