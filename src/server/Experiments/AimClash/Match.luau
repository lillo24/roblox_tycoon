--!strict

local Rules = require(game:GetService("ReplicatedStorage").TycoonShared.Experiments.AimClash.Rules)
local Match = {}
export type Score = {
	judgements: { number }, -- 0 unresolved, 1 hit, 2 missed; private to its player.
	combo: number,
	bestCombo: number,
	hits: number,
	misses: number,
	inaccurate: number,
	base: number,
	speedExtra: number,
	comboExtra: number,
	qualitySum: number,
	inputs: number,
	lastTime: number,
	lastReceived: number,
	disqualified: boolean,
	message: string,
}
export type Battle = {
	start: number,
	pattern: { Rules.Target },
	scores: { Score },
	finished: boolean,
}
export type Result = {
	total: number,
	base: number,
	speedExtra: number,
	comboExtra: number,
	penalty: number,
	precision: number,
	hits: number,
	misses: number,
	inaccurate: number,
	bestCombo: number,
	disqualified: boolean,
}

function Match.new(start: number, seed: number, players: number): Battle
	assert(players == 1 or players == 2, "Aim clash requires one practice player or two duel players")
	local scores: { Score } = {}
	for _ = 1, players do
		table.insert(scores, {
			judgements = table.create(Rules.TargetCount, 0),
			combo = 0,
			bestCombo = 0,
			hits = 0,
			misses = 0,
			inaccurate = 0,
			base = 0,
			speedExtra = 0,
			comboExtra = 0,
			qualitySum = 0,
			inputs = 0,
			lastTime = -math.huge,
			lastReceived = -math.huge,
			disqualified = false,
			message = "Aim at appearing circles",
		})
	end
	return { start = start, pattern = Rules.pattern(seed), scores = scores, finished = false }
end

function Match.step(battle: Battle, now: number)
	if battle.finished then
		return
	end
	for _, score in battle.scores do
		for index, target in battle.pattern do
			-- Retain unresolved opportunities for bounded network arrival, not extra
			-- visible reaction time. Both clients hide the target at its nominal close.
			if
				score.judgements[index] == 0
				and now > battle.start + target.at + target.lifetime + Rules.LatencyGrace
			then
				score.judgements[index] = 2
				score.misses += 1
				score.combo = 0
				score.message = "Missed · rebuild your combo"
			end
		end
	end
	if now > battle.start + Rules.duration(battle.pattern) + Rules.LatencyGrace then
		battle.finished = true
	end
end

local function inaccurate(score: Score, message: string): boolean
	score.inaccurate += 1
	score.combo = 0
	score.message = message
	return false
end

-- Caller authenticates the round/player. No target ID, quality or total is trusted.
function Match.input(battle: Battle, actor: number, timestamp: any, x: any, y: any, received: number): boolean
	local score = battle.scores[actor]
	if not score or battle.finished or received < battle.start or score.disqualified then
		return false
	end
	Match.step(battle, received)
	if battle.finished then
		return false
	end
	score.inputs += 1
	if score.inputs > Rules.MaxInputs then
		score.disqualified = true
		return inaccurate(score, "Input limit exceeded · result disqualified")
	end
	local rapid = received < score.lastReceived + Rules.InputInterval
	score.lastReceived = received
	if rapid then
		return inaccurate(score, "Too many inputs · combo reset")
	end
	if not Rules.validTime(timestamp, received) or timestamp <= score.lastTime then
		return inaccurate(score, "Late, repeated or invalid input time")
	end
	score.lastTime = timestamp
	if not Rules.finite(x) or not Rules.finite(y) or x < 0 or x > 1 or y < 0 or y > 1 then
		return inaccurate(score, "Invalid aim position")
	end
	local index = Rules.targetAt(battle.pattern, timestamp - battle.start)
	if not index or score.judgements[index] ~= 0 then
		return inaccurate(score, "No available circle · combo reset")
	end
	local target = battle.pattern[index]
	local quality = Rules.quality(target, x, y)
	if not quality then
		return inaccurate(score, "Outside circle · combo reset")
	end
	-- Finish earlier missed opportunities before a later hit, even when their
	-- network grace has not elapsed, so a gap cannot artificially extend a combo.
	for previous = 1, index - 1 do
		if score.judgements[previous] == 0 then
			score.judgements[previous] = 2
			score.misses += 1
			score.combo = 0
		end
	end
	score.judgements[index] = 1
	score.hits += 1
	score.combo += 1
	score.bestCombo = math.max(score.bestCombo, score.combo)
	score.qualitySum += quality
	local base = math.floor(quality * 100 + 0.5)
	score.base += base
	score.speedExtra += math.floor(base * (target.weight - 1) + 0.5)
	score.comboExtra += math.floor(base * math.min(score.combo - 1, Rules.ComboCap) * Rules.ComboStep + 0.5)
	score.message = `Hit · combo {score.combo}`
	return true
end

function Match.result(score: Score): Result
	local penalty = score.inaccurate * Rules.InaccuratePenalty
	return {
		total = if score.disqualified
			then 0
			else math.max(0, score.base + score.speedExtra + score.comboExtra - penalty),
		base = score.base,
		speedExtra = score.speedExtra,
		comboExtra = score.comboExtra,
		penalty = penalty,
		precision = 100 * score.qualitySum / (Rules.TargetCount + score.inaccurate),
		hits = score.hits,
		misses = score.misses,
		inaccurate = score.inaccurate,
		bestCombo = score.bestCombo,
		disqualified = score.disqualified,
	}
end

-- Only a completed battle can expose a comparison. Ties remain ties.
function Match.winner(battle: Battle): number
	assert(battle.finished, "Aim clash cannot reveal a winner before the end")
	if #battle.scores == 1 then
		return 0
	end
	local first, second = Match.result(battle.scores[1]), Match.result(battle.scores[2])
	if first.disqualified ~= second.disqualified then
		return if first.disqualified then 2 else 1
	end
	return if first.total == second.total then 0 else if first.total > second.total then 1 else 2
end

-- A single-player projection, never a replicated Player attribute or shared total.
function Match.own(battle: Battle, actor: number): { [string]: any }
	local score = battle.scores[actor]
	return {
		combo = score.combo,
		hits = score.hits,
		message = score.message,
		total = Match.result(score).total,
		judgements = table.clone(score.judgements),
	}
end

return Match
