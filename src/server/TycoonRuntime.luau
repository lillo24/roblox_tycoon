--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage.TycoonShared.Config)
local Session = require(script.Parent.Session)
local PlotWorld = require(script.Parent.PlotWorld)

local TycoonRuntime = {}
local started = false

function TycoonRuntime.start()
	assert(RunService:IsServer(), "Tycoon: runtime must start on the server")
	assert(not started, "Tycoon: runtime started twice")
	assert(Config.IncomeInterval > 0, "Tycoon: IncomeInterval must be positive")
	local session = Session.new(Config)
	local plots = PlotWorld.create()
	local active: { [number]: Player } = {}
	started = true

	local function publish(player: Player, state: Session.State)
		player:SetAttribute(Config.Attributes.Cash, state.cash)
		player:SetAttribute(Config.Attributes.IncomeRate, state.incomeRate)
		player:SetAttribute(Config.Attributes.PlotId, state.plotId)
		player:SetAttribute(Config.Attributes.Assignment, "Assigned")
	end

	local function clear(player: Player)
		player:SetAttribute(Config.Attributes.Cash, nil)
		player:SetAttribute(Config.Attributes.IncomeRate, nil)
		player:SetAttribute(Config.Attributes.PlotId, nil)
		player:SetAttribute(Config.Attributes.Assignment, nil)
	end

	local function join(player: Player)
		if player.Parent ~= Players or active[player.UserId] == player then
			return
		end
		assert(active[player.UserId] == nil, `Tycoon: duplicate active user {player.UserId}`)
		clear(player)
		local state = session:assign(player.UserId)
		if not state then
			player:SetAttribute(Config.Attributes.Assignment, "Full")
			warn(
				`[roblox_tycoon] No free plot for {player.Name} ({player.UserId}); all {Config.PlotCount} plots are occupied.`
			)
			return
		end
		active[player.UserId] = player
		PlotWorld.setOwner(plots[state.plotId], player)
		publish(player, state)
	end

	local function leave(player: Player)
		if active[player.UserId] == player then
			active[player.UserId] = nil
			local id = session:release(player.UserId)
			if id then
				PlotWorld.setOwner(plots[id], nil)
			end
		end
		clear(player)
	end

	for id, plot in plots do
		plot.prompt.Triggered:Connect(function(player: Player)
			-- Attributes and prompt visibility are presentation, never eligibility inputs.
			if player.Parent ~= Players or active[player.UserId] ~= player then
				return
			end
			local character = player.Character
			local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
			local humanoid = if character then character:FindFirstChildWhichIsA("Humanoid") else nil
			if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
				return
			end
			if (root.Position - plot.pad.Position).Magnitude > Config.PromptDistance then
				return
			end
			if session:purchase(player.UserId, id) then
				local state = session:get(player.UserId)
				assert(state, "Tycoon: purchased assignment disappeared")
				PlotWorld.applyUpgrade(plot)
				publish(player, state)
			end
		end)
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
		elapsed += delta
		local ticks = math.floor(elapsed / Config.IncomeInterval)
		if ticks == 0 then
			return
		end
		elapsed -= ticks * Config.IncomeInterval
		session:accrue(ticks)
		for userId, player in active do
			local state = session:get(userId)
			assert(state, `Tycoon: active user {userId} has no session state`)
			publish(player, state)
		end
	end)
end

return TycoonRuntime
