--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage.TycoonShared.Config)
local Catalogue = require(ReplicatedStorage.TycoonShared.UpgradeCatalogue)
local Session = require(script.Parent.Session)
local PlotWorld = require(script.Parent.PlotWorld)
local SupplyRuntime = require(script.Parent.SupplyRuntime)

local TycoonRuntime = {}
local started = false

-- Default remains native prompts. Only the disposable EXP-02 entry opts in.
function TycoonRuntime.start(options: { walkOn: boolean }?)
	assert(RunService:IsServer(), "Tycoon: runtime must start on the server")
	assert(not started, "Tycoon: runtime started twice")
	local walkOn = if options and options.walkOn
		then require(script.Parent.Experiments.FactoryPurchases.WalkOn)
		else nil
	local numbers: { [string]: number } = {
		IncomeInterval = Config.IncomeInterval,
		PromptDistance = Config.PromptDistance,
		PurchasePromptDistance = Config.PurchasePromptDistance,
		RequestInterval = Config.RequestInterval,
		FeedbackDuration = Config.FeedbackDuration,
	}
	for field, value in numbers do
		assert(value > 0 and value < math.huge, `Tycoon: {field} must be finite and positive`)
	end
	assert(
		Config.PurchasePromptDistance <= Config.PromptDistance,
		"Tycoon: display distance exceeds server purchase distance"
	)
	assert(
		not ReplicatedStorage:FindFirstChild(Config.FeedbackName),
		`Tycoon: reserved ReplicatedStorage/{Config.FeedbackName} already exists`
	)
	-- Pass a typed value snapshot; shared Config is frozen and remains presentation-safe.
	local tuning: Session.Tuning = {
		PlotCount = Config.PlotCount,
		StartingCash = Config.StartingCash,
		BaseIncome = Config.BaseIncome,
	}
	local session = Session.new(tuning, Catalogue.Definitions)
	local layout = PlotWorld.inspect() -- All authored geometry is validated before writes.
	local supplyCenter = SupplyRuntime.inspect()
	local plots = PlotWorld.create(layout)
	-- Outbound only: no client purchase remote, message forwarding, or broadcast.
	local feedback = Instance.new("RemoteEvent")
	feedback.Name = Config.FeedbackName
	feedback.Archivable = false
	feedback.Parent = ReplicatedStorage
	local active: { [number]: Player } = {}
	local nextRequest: { [number]: number } = {}
	started = true

	local function publish(player: Player, state: Session.State)
		for _, definition in Catalogue.Definitions do
			player:SetAttribute(Catalogue.purchaseAttribute(definition.Id), state.purchases[definition.Id] == true)
		end
		player:SetAttribute(Config.Attributes.Cash, state.cash)
		player:SetAttribute(Config.Attributes.IncomeRate, state.incomeRate)
		player:SetAttribute(Config.Attributes.PlotId, state.plotId)
		player:SetAttribute(Config.Attributes.Assignment, "Assigned")
		PlotWorld.reconcile(plots[state.plotId], state.purchases, state.cash)
		if walkOn then
			walkOn.presentation(plots[state.plotId])
		end
	end

	local function clear(player: Player)
		player:SetAttribute(Config.Attributes.Assignment, nil)
		for _, definition in Catalogue.Definitions do
			player:SetAttribute(Catalogue.purchaseAttribute(definition.Id), nil)
		end
		player:SetAttribute(Config.Attributes.Cash, nil)
		player:SetAttribute(Config.Attributes.IncomeRate, nil)
		player:SetAttribute(Config.Attributes.PlotId, nil)
	end
	local runtimeFolder = workspace:FindFirstChild(Config.RuntimeName)
	assert(runtimeFolder, "Tycoon: runtime geometry is missing")
	local supply = SupplyRuntime.new(session, active, publish, runtimeFolder, supplyCenter)

	local function join(player: Player)
		if player.Parent ~= Players or active[player.UserId] == player then
			return
		end
		assert(active[player.UserId] == nil, `Tycoon: duplicate active user {player.UserId}`)
		clear(player)
		active[player.UserId] = player
		local state = session:assign(player.UserId)
		if not state then
			player:SetAttribute(Config.Attributes.Assignment, "Full")
			warn(
				`[roblox_tycoon] No free plot for {player.Name} ({player.UserId}); all {Config.PlotCount} plots are occupied.`
			)
			return
		end
		PlotWorld.setOwner(plots[state.plotId], player)
		publish(player, state)
		supply:sync(workspace:GetServerTimeNow())
	end

	local function leave(player: Player)
		nextRequest[player.UserId] = nil
		if active[player.UserId] == player then
			active[player.UserId] = nil
			local id = session:release(player.UserId)
			if id then
				PlotWorld.setOwner(plots[id], nil)
			end
		end
		clear(player)
		supply:leave(player)
	end

	local function sendResult(player: Player, message: string)
		local state = session:get(player.UserId)
		feedback:FireClient(player, if state then state.plotId else nil, message)
	end

	local function purchase(player: Player, plotId: number, upgradeId: Catalogue.Id, pad: PlotWorld.Pad)
		-- Attributes and prompt visibility are presentation, never eligibility inputs.
		if player.Parent ~= Players or active[player.UserId] ~= player then
			return
		end
		-- Bound both processing and private result messages to four attempts/sec.
		-- Excess attempts are dropped; balance/ownership checks still decide purchases.
		local now = os.clock()
		if now < (nextRequest[player.UserId] or 0) then
			return
		end
		nextRequest[player.UserId] = now + Config.RequestInterval
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		local humanoid = if character then character:FindFirstChildWhichIsA("Humanoid") else nil
		if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
			sendResult(player, "Respawn before buying")
			return
		end
		if (root.Position - pad.part.Position).Magnitude > Config.PromptDistance then
			sendResult(player, "Move closer to the pad")
			return
		end
		local accepted, reason, missing = session:purchase(player.UserId, plotId, upgradeId)
		if accepted then
			local state = session:get(player.UserId)
			assert(state, "Tycoon: purchased assignment disappeared")
			publish(player, state)
		end
		sendResult(player, Catalogue.resultMessage(upgradeId, reason, missing))
	end
	if walkOn then
		walkOn.start(plots, function(player: Player, id: Catalogue.Id): number?
			if player.Parent ~= Players or active[player.UserId] ~= player then
				return nil
			end
			local state = session:get(player.UserId)
			return if state and not state.purchases[id] then state.plotId else nil
		end, purchase)
	else
		for plotId, plot in plots do
			for upgradeId, pad in plot.pads do
				pad.prompt.Triggered:Connect(function(player: Player)
					purchase(player, plotId, upgradeId, pad)
				end)
			end
		end
	end
	Players.PlayerAdded:Connect(join)
	Players.PlayerRemoving:Connect(leave)
	for _, player in Players:GetPlayers() do
		join(player)
	end

	-- One shared clock; accrue completed intervals, including elapsed time after a stall.
	-- Joining players enter this server-wide cadence (first tick may be less than 1s away).
	local elapsed = 0
	RunService.Heartbeat:Connect(function(delta: number)
		supply:sync(workspace:GetServerTimeNow())
		elapsed += delta
		local ticks = math.floor(elapsed / Config.IncomeInterval)
		if ticks == 0 then
			return
		end
		elapsed -= ticks * Config.IncomeInterval
		session:accrue(ticks)
		for userId, player in active do
			local state = session:get(userId)
			if state then
				publish(player, state)
			end -- Full-capacity players have no economy.
		end
	end)
end

return TycoonRuntime
