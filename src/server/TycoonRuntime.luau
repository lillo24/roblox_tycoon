--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage.TycoonShared.Config)
local Catalogue = require(ReplicatedStorage.TycoonShared.UpgradeCatalogue)
local Session = require(script.Parent.Session)
local PlotWorld = require(script.Parent.PlotWorld)
local SupplyRuntime = require(script.Parent.SupplyRuntime)
local Mode = require(ReplicatedStorage.TycoonShared.GameMode)
local Profiles = require(script.Parent.Persistence.Profiles)
local ProfileStore = require(script.Parent.Persistence.ProfileStore)
local Backend = require(script.Parent.Persistence.DataStoreBackend)
local Schema = require(script.Parent.Persistence.ProfileSchema)

local TycoonRuntime = {}
local started = false

-- Injection is restricted to disposable Studio previews/tests; production has no
-- in-memory fallback. The preview label replaces every save claim in that copy.
function TycoonRuntime.start(preview: { update: (string, (any) -> any) -> any, label: string }?)
	assert(RunService:IsServer(), "Tycoon: runtime must start on the server")
	assert(not started, "Tycoon: runtime started twice")
	local infinite = Mode.read() == "Infinite"
	assert(
		not preview or RunService:IsStudio() and infinite and #preview.label > 0,
		"Tycoon: preview backend is Studio-only"
	)
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
		CashLimit = if infinite then Schema.MaxCash else nil,
	}
	local session = Session.new(tuning, Catalogue.Definitions)
	local layout = PlotWorld.inspect() -- All authored geometry is validated before writes.
	local supplyCenter = if infinite then nil else SupplyRuntime.inspect()
	local plots = PlotWorld.create(layout)
	-- Outbound only: no client purchase remote, message forwarding, or broadcast.
	local feedback = Instance.new("RemoteEvent")
	feedback.Name = Config.FeedbackName
	feedback.Archivable = false
	feedback.Parent = ReplicatedStorage
	local active: { [number]: Player } = {}
	local nextRequest: { [number]: number } = {}
	local profiles: Profiles.Profiles? = nil
	local publishedPlots: { [number]: number } = {}
	started = true

	local function publish(player: Player, state: Session.State)
		for _, definition in Catalogue.Definitions do
			player:SetAttribute(Catalogue.purchaseAttribute(definition.Id), state.purchases[definition.Id] == true)
		end
		player:SetAttribute(Config.Attributes.Cash, state.cash)
		player:SetAttribute(Config.Attributes.IncomeRate, state.incomeRate)
		player:SetAttribute(Config.Attributes.PlotId, state.plotId)
		player:SetAttribute(Config.Attributes.Assignment, if infinite then "Ready" else "Assigned")
		local data = if profiles then profiles:snapshot(player.UserId) else nil
		PlotWorld.reconcile(plots[state.plotId], state.purchases, state.cash, if data then data.placements else nil)
	end

	local function clear(player: Player)
		player:SetAttribute(Config.Attributes.Assignment, nil)
		player:SetAttribute(Config.Attributes.SaveStatus, nil)
		for _, definition in Catalogue.Definitions do
			player:SetAttribute(Catalogue.purchaseAttribute(definition.Id), nil)
		end
		player:SetAttribute(Config.Attributes.Cash, nil)
		player:SetAttribute(Config.Attributes.IncomeRate, nil)
		player:SetAttribute(Config.Attributes.PlotId, nil)
	end
	local runtimeFolder = workspace:FindFirstChild(Config.RuntimeName)
	assert(runtimeFolder, "Tycoon: runtime geometry is missing")
	local supply = if supplyCenter
		then SupplyRuntime.new(session, active, publish, runtimeFolder, supplyCenter)
		else nil
	local backendIssue: string? = nil
	if infinite then
		local update = if preview then preview.update else nil
		if not update then
			update, backendIssue = Backend.open()
		end
		if update then
			profiles = Profiles.new(
				session,
				ProfileStore.new(update),
				function(userId: number, status: string, saveStatus: string, state: Session.State?, _data: Schema.Data?)
					local player = active[userId]
					if not player or player.Parent ~= Players then
						return
					end
					local previous = publishedPlots[userId]
					if previous and (not state or previous ~= state.plotId) then
						PlotWorld.setOwner(plots[previous], nil)
						publishedPlots[userId] = nil
					end
					if state then
						if not publishedPlots[userId] then
							PlotWorld.setOwner(plots[state.plotId], player)
						end
						publishedPlots[userId] = state.plotId
						publish(player, state)
					else
						clear(player)
					end
					player:SetAttribute(Config.Attributes.SaveStatus, if preview then preview.label else saveStatus)
					player:SetAttribute(Config.Attributes.Assignment, status)
				end
			)
		else
			warn(`Infinite persistence unavailable: {backendIssue}`)
		end
	end

	local function join(player: Player)
		if player.Parent ~= Players or active[player.UserId] == player then
			return
		end
		assert(active[player.UserId] == nil, `Tycoon: duplicate active user {player.UserId}`)
		clear(player)
		active[player.UserId] = player
		if infinite then
			if profiles then
				profiles:join(player.UserId)
			else
				player:SetAttribute(Config.Attributes.Assignment, "Unavailable")
				player:SetAttribute(
					Config.Attributes.SaveStatus,
					"Saving is not configured for this preview. Your saved data has not been changed."
				)
			end
			return
		end
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
		if supply then
			supply:sync(workspace:GetServerTimeNow())
		end
	end

	local function leave(player: Player)
		nextRequest[player.UserId] = nil
		if active[player.UserId] == player then
			active[player.UserId] = nil
			local state = session:get(player.UserId)
			local id = if state then state.plotId else nil
			if profiles then
				profiles:leave(player.UserId)
			else
				session:release(player.UserId)
			end
			publishedPlots[player.UserId] = nil
			if id then
				PlotWorld.setOwner(plots[id], nil)
			end
		end
		clear(player)
		if supply then
			supply:leave(player)
		end
	end

	local function sendResult(player: Player, message: string)
		local state = session:get(player.UserId)
		feedback:FireClient(player, if state then state.plotId else nil, message)
	end

	for plotId, plot in plots do
		for upgradeId, pad in plot.pads do
			pad.prompt.Triggered:Connect(function(player: Player)
				-- Attributes and prompt visibility are presentation, never eligibility inputs.
				if player.Parent ~= Players or active[player.UserId] ~= player then
					return
				end
				if infinite and (not profiles or not profiles:ready(player.UserId)) then
					sendResult(player, "Your place must be ready before buying")
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
			end)
		end
	end
	Players.PlayerAdded:Connect(join)
	Players.PlayerRemoving:Connect(leave)
	if profiles then
		local persistent = profiles
		game:BindToClose(function()
			persistent:shutdown()
		end)
	end
	for _, player in Players:GetPlayers() do
		join(player)
	end

	-- One shared clock; accrue completed intervals, including elapsed time after a stall.
	-- Joining players enter this server-wide cadence (first tick may be less than 1s away).
	local elapsed = 0
	RunService.Heartbeat:Connect(function(delta: number)
		if supply then
			supply:sync(workspace:GetServerTimeNow())
		end
		if profiles then
			profiles:step()
		end
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
