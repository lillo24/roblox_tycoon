--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Rules = require(ReplicatedStorage.TycoonShared.Experiments.AimClash.Rules)
local Match = require(script.Parent.Match)
local Runtime = {}
type Round = { id: number, battle: Match.Battle, players: { Player }, sentResult: boolean }

function Runtime.start()
	assert(RunService:IsServer(), "Aim clash requires server context")
	assert(not ReplicatedStorage:FindFirstChild(Rules.RemoteName), "Aim clash already started")
	local remote = Instance.new("RemoteEvent")
	remote.Name, remote.Parent = Rules.RemoteName, ReplicatedStorage
	local rounds: { [Player]: Round } = {}
	local queued: Player? = nil
	local serial = 0
	local nextControl: { [Player]: number } = {}
	local function release(player: Player, message: string)
		local round = rounds[player]
		if not round then
			return
		end
		for _, member in round.players do
			rounds[member] = nil
			if member.Parent == Players and not round.battle.finished then
				remote:FireClient(member, { kind = "cancel", message = message })
			end
		end
	end
	local function start(first: Player, second: Player?)
		release(first, "Round replaced")
		if second then
			release(second, "Round replaced")
		end
		serial += 1
		local members = { first }
		if second then
			table.insert(members, second)
		end
		local startTime = workspace:GetServerTimeNow() + Rules.StartDelay
		local seed = (serial - 1) % 12
		local round: Round =
			{ id = serial, battle = Match.new(startTime, seed, #members), players = members, sentResult = false }
		for index, member in members do
			rounds[member] = round
			remote:FireClient(member, {
				kind = "start",
				id = round.id,
				seed = seed,
				start = startTime,
				practice = second == nil,
				actor = index,
				opponent = if second then members[3 - index].DisplayName else "Practice",
			})
		end
	end
	remote.OnServerEvent:Connect(function(player: Player, action: any, id: any, timestamp: any, x: any, y: any)
		if player.Parent ~= Players then
			return
		end
		local now = workspace:GetServerTimeNow()
		if action == "input" then
			local round = rounds[player]
			if round and round.id == id then
				local actor = table.find(round.players, player)
				assert(actor, "Aim clash participant missing")
				Match.input(round.battle, actor, timestamp, x, y, now)
			end
			return
		end
		if action ~= "practice" and action ~= "queue" and action ~= "leave" then
			return
		end
		if now < (nextControl[player] or 0) then
			return
		end
		nextControl[player] = now + 0.5
		local current = rounds[player]
		if current and not current.battle.finished then
			return
		end -- Control changes wait for the end; an active duel cannot be rerolled.
		if action == "leave" then
			if queued == player then
				queued = nil
			end
			release(player, "Returned to lobby")
			remote:FireClient(player, { kind = "lobby", message = "Choose practice or duel queue" })
		elseif action == "practice" then
			if queued == player then
				queued = nil
			end
			start(player, nil)
		elseif queued and queued ~= player and queued.Parent == Players then
			local other = queued
			queued = nil
			start(other, player)
		else
			queued = player
			release(player, "Waiting for a challenger")
			remote:FireClient(player, { kind = "queued", message = "Waiting for another player to choose Duel queue" })
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		release(player, "Opponent disconnected · round cancelled without a winner")
		nextControl[player] = nil
		if queued == player then
			queued = nil
		end
	end)
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
			Match.step(round.battle, now)
			if round.battle.finished and not round.sentResult then
				round.sentResult = true
				local winner = Match.winner(round.battle)
				for index, member in round.players do
					remote:FireClient(member, {
						kind = "result",
						id = round.id,
						actor = index,
						winner = winner,
						own = Match.result(round.battle.scores[index]),
						other = if #round.players == 2 then Match.result(round.battle.scores[3 - index]) else nil,
						opponent = if #round.players == 2 then round.players[3 - index].DisplayName else "Practice",
					})
				end
			elseif not round.battle.finished and elapsed >= Rules.SnapshotInterval then
				for index, member in round.players do
					remote:FireClient(member, { kind = "own", id = round.id, own = Match.own(round.battle, index) })
				end
			end
		end
		if elapsed >= Rules.SnapshotInterval then
			elapsed = 0
		end
	end)
	print("EXP03 Aim Clash ready; private live scores, shared sequence, factory bootstrap disabled in this preview.")
end

return Runtime
