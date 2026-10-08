--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Rules = require(ReplicatedStorage.TycoonShared.Experiments.ParryLab.Rules)
local Match = require(script.Parent.Match)
local T = Rules.Tuning
local Runtime = {}
type Round = {
	match: Match.Battle,
	players: { Player },
	bot: BasePart?,
	center: Vector3,
	botAt: number,
	geometry: { [Match.Attack]: boolean },
	floor: BasePart,
}

local function part(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3): Part
	local value = Instance.new("Part")
	value.Name, value.Anchored, value.Size, value.Position = name, true, size, position
	value.Color, value.Material, value.Parent = color, Enum.Material.SmoothPlastic, parent
	return value
end

function Runtime.start()
	assert(RunService:IsServer(), "Parry Lab requires server context")
	assert(not workspace:FindFirstChild("ParryLabArena"), "Parry Lab already started")
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "ParryLabArena", workspace
	local remote = Instance.new("RemoteEvent")
	remote.Name, remote.Parent = Rules.RemoteName, ReplicatedStorage
	local rounds: { [Player]: Round } = {}
	local nextInput: { [Player]: number } = {}
	local queued: Player? = nil
	local serial = 0
	local function root(player: Player): BasePart?
		local character = player.Character
		local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
		local value = character and character:FindFirstChild("HumanoidRootPart")
		return if humanoid and humanoid.Health > 0 and value and value:IsA("BasePart") then value else nil
	end
	local function place(player: Player, position: Vector3, target: Vector3)
		local character = player.Character
		if character then
			character:PivotTo(CFrame.lookAt(position, target))
		end
	end
	local function release(player: Player)
		local round = rounds[player]
		if not round then
			return
		end
		for _, member in round.players do
			rounds[member] = nil
			member:SetAttribute(
				Rules.StateName,
				HttpService:JSONEncode({ mode = "ended", message = "Opponent left or restarted. Start a new practice." })
			)
		end
		if round.bot then
			round.bot:Destroy()
		end
		round.floor:Destroy()
	end
	local function start(first: Player, second: Player?)
		release(first)
		if second then
			release(second)
		end
		serial += 1
		local center = Vector3.new(serial * 45, 7, 420)
		local floor = part(
			folder,
			`Station{serial}`,
			Vector3.new(38, 1, 38),
			center - Vector3.new(0, 4, 0),
			Color3.fromRGB(28, 37, 51)
		)
		local members = { first }
		if second then
			table.insert(members, second)
		end
		local bot = if second
			then nil
			else part(
				folder,
				"PracticeOpponent",
				Vector3.new(3, 5, 2),
				center + Vector3.new(0, 0, -8),
				Color3.fromRGB(255, 160, 64)
			)
		local round: Round = {
			match = Match.new(),
			players = members,
			bot = bot,
			center = center,
			botAt = workspace:GetServerTimeNow() + 2,
			geometry = {},
			floor = floor,
		}
		for i, player in members do
			rounds[player] = round
			local position = center + Vector3.new(0, 0, if i == 1 then 0 else -8)
			place(player, position, center + Vector3.new(0, 0, if i == 1 then -8 else 0))
		end
	end
	local function join(player: Player)
		player.CharacterAdded:Connect(function()
			task.wait(0.2)
			if player.Parent == Players then
				start(player, nil)
			end
		end)
		if player.Character then
			start(player, nil)
		end
	end
	remote.OnServerEvent:Connect(function(player: Player, action: any, timestamp: any)
		local now = workspace:GetServerTimeNow()
		if player.Parent ~= Players or typeof(action) ~= "string" or not Rules.validTime(timestamp, now) then
			return
		end
		if now < (nextInput[player] or 0) then
			return
		end
		nextInput[player] = now + T.InputInterval
		if action == "restart" then
			if queued == player then
				queued = nil
			end
			start(player, nil)
			return
		elseif action == "queue" then
			if queued and queued ~= player and queued.Parent == Players then
				local other = queued
				queued = nil
				start(other, player)
			else
				queued = player
			end
			return
		end
		local round = rounds[player]
		if not round or not root(player) then
			return
		end
		local actor = table.find(round.players, player)
		assert(actor, "Parry Lab participant missing")
		-- Attacks start at receipt, preserving the opponent's whole windup cue.
		Match.action(round.match, actor, action, if action == "parry" then timestamp else now)
	end)
	Players.PlayerAdded:Connect(join)
	Players.PlayerRemoving:Connect(function(player)
		release(player)
		nextInput[player] = nil
		if queued == player then
			queued = nil
		end
	end)
	for _, player in Players:GetPlayers() do
		join(player)
	end
	local elapsed = 0
	RunService.Heartbeat:Connect(function(delta)
		elapsed += delta
		local now = workspace:GetServerTimeNow()
		local seen: { [Round]: boolean } = {}
		for _, round in rounds do
			if seen[round] then
				continue
			end
			seen[round] = true
			if round.bot and now >= round.botAt then
				Match.action(round.match, 2, "attack", now)
				round.botAt = now + T.BotInterval
			end
			for _, attack in round.match.attacks do
				if now >= attack.impact and round.geometry[attack] == nil then
					local first, second =
						root(round.players[1]), if round.players[2] then root(round.players[2]) else round.bot
					local attacker, defender =
						if attack.actor == 1 then first else second, if attack.actor == 1 then second else first
					local valid = false
					if attacker and defender then
						local offset = defender.Position - attacker.Position
						valid = offset.Magnitude <= T.Range
							and (
								attack.actor == 2 and round.bot ~= nil
								or offset.Magnitude < 0.01
								or attacker.CFrame.LookVector:Dot(offset.Unit) >= 0.35
							)
					end
					round.geometry[attack] = valid
				end
			end
			Match.step(round.match, now, function(actor, impact)
				for attack, value in round.geometry do
					if attack.actor == actor and attack.impact == impact then
						round.geometry[attack] = nil
						return value
					end
				end
				return false
			end)
			if elapsed >= 0.05 then
				for index, player in round.players do
					local opponentImpact, ownImpact = 0, 0
					for _, attack in round.match.attacks do
						if attack.actor == index then
							ownImpact = attack.impact
						else
							opponentImpact = attack.impact
						end
					end
					local self, other = round.match.fighters[index], round.match.fighters[3 - index]
					player:SetAttribute(
						Rules.StateName,
						HttpService:JSONEncode({
							mode = if round.bot then "Practice opponent" else "Player duel",
							health = self.health,
							opponentHealth = other.health,
							message = self.message,
							parries = self.parries,
							impact = opponentImpact,
							ownImpact = ownImpact,
							parryAt = self.parryAt == -math.huge and 0 or self.parryAt,
							ready = self.parryReady,
							counterUntil = self.counterUntil,
							winner = round.match.winner,
							actor = index,
							queued = queued == player,
						})
					)
				end
			end
		end
		if elapsed >= 0.05 then
			elapsed = 0
		end
	end)
	print("EXP01 Parry Lab ready; temporary arena, factory bootstrap disabled in this preview.")
end

return Runtime
