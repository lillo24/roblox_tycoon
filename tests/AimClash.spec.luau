--!strict

local shared = game:GetService("ReplicatedStorage").TycoonShared.Experiments.AimClash
local Rules = require(shared.Rules)
local Match = require(game:GetService("ServerScriptService").TycoonServer.Experiments.AimClash.Match)

return function(): number
	local count = 0
	local function check(value: boolean, message: string)
		assert(value, message)
		count += 1
	end
	local function near(a: number, b: number): boolean
		return math.abs(a - b) < 0.00001
	end
	local function finish(battle: Match.Battle)
		Match.step(battle, battle.start + Rules.duration(battle.pattern) + Rules.LatencyGrace + 0.01)
	end
	local function hit(battle: Match.Battle, actor: number, index: number, edge: boolean?): boolean
		local target = battle.pattern[index]
		local time = battle.start + target.at + target.lifetime * 0.5
		return Match.input(
			battle,
			actor,
			time,
			target.x + (if edge then Rules.TargetRadius else 0),
			target.y,
			time + 0.1
		)
	end
	local first, same = Rules.pattern(0), Rules.pattern(0)
	check(#first == 24 and #same == 24, "Short fixed opportunity count")
	for index, target in first do
		check(
			target.x == same[index].x and target.y == same[index].y and target.at == same[index].at,
			"Same seed means identical opportunities"
		)
		check(
			(Vector2.new(target.x, target.y) - Vector2.new(0.5, 0.5)).Magnitude + Rules.TargetRadius < 0.5,
			"Targets wholly inside circular area"
		)
	end
	check(
		first[1].lifetime > first[9].lifetime and first[9].lifetime > first[17].lifetime,
		"Accelerating readable lifetimes"
	)
	check(first[17].weight > first[9].weight and first[9].weight > first[1].weight, "Faster hits worth more")
	check(Rules.duration(first) < 18 and Rules.duration(first) > 16, "Brief standalone sequence")
	check(Rules.targetAt(first, -0.1) == nil and Rules.targetAt(first, 0.1) == 1, "Only appearing circles active")
	check(Rules.targetAt(first, 0.95) == nil, "Gap is not a beat-aligned hit window")
	check(Rules.phase(first, 0) == "FOCUS", "Initial anticipation phase")
	check(
		Rules.phase(first, 8.1) == "FASTER" and Rules.phase(first, 13.7) == "FINAL SURGE",
		"Phase follows shared target schedule"
	)
	check(Rules.quality(first[1], first[1].x + Rules.TargetRadius + 0.001, first[1].y) == nil, "Outside radius refused")
	check(
		not Rules.validTime(0 / 0, 0) and not Rules.validTime(math.huge, 0) and not Rules.validTime("0", 0),
		"Finite numeric timestamps required"
	)
	check(not Rules.validTime(1, 1.181) and not Rules.validTime(1.031, 1), "Timestamp bounds enforced")

	local perfect = Match.new(10, 0, 2)
	for index = 1, 24 do
		check(hit(perfect, 1, index), "Center hits accepted")
		check(hit(perfect, 2, index), "Equal second-player opportunities")
	end
	local hidden = Match.own(perfect, 1)
	check(
		hidden.other == nil and hidden.winner == nil and hidden.opponentScore == nil and hidden.precision == nil,
		"Own projection contains no opponent or premature result"
	)
	hidden.judgements[1] = 99
	check(perfect.scores[1].judgements[1] == 1, "Projection cannot mutate ledger")
	local ok = pcall(Match.winner, perfect)
	check(not ok, "No winner before the end")
	finish(perfect)
	local full = Match.result(perfect.scores[1])
	check(
		full.precision == 100 and full.base == 2400 and full.hits == 24 and full.misses == 0,
		"Perfect quality independent of bonuses"
	)
	check(
		full.speedExtra == 360 and full.comboExtra > 0 and full.comboExtra < 360,
		"Bounded acceleration and combo extras"
	)
	check(full.total == full.base + full.speedExtra + full.comboExtra, "Transparent score sum")
	check(Match.winner(perfect) == 0, "Exact tie stays draw")
	check(not hit(perfect, 1, 24), "Finished battle cannot accept more inputs")

	local edges = Match.new(10, 0, 1)
	for index = 1, 24 do
		check(hit(edges, 1, index, true), "Edge is still a hit")
	end
	finish(edges)
	local edgeResult = Match.result(edges.scores[1])
	check(
		near(edgeResult.precision, 50) and edgeResult.base == 1200,
		"Spatial edge quality lowers precision without changing combo"
	)
	check(edgeResult.bestCombo == 24 and edgeResult.comboExtra < full.comboExtra, "Bonuses scale from aim quality")

	local selective = Match.new(10, 0, 2)
	check(hit(selective, 1, 1), "Selective first hit")
	check(hit(selective, 1, 3), "Selective later hit")
	check(
		selective.scores[1].combo == 1 and selective.scores[1].misses == 1,
		"Skipped target breaks combo even within network grace"
	)
	finish(selective)
	local selected = Match.result(selective.scores[1])
	check(
		near(selected.precision, 100 * 2 / 24) and selected.misses == 22,
		"Misses stay in fixed precision denominator"
	)
	check(Match.winner(selective) == 1, "Authoritative completed winner")

	local spam = Match.new(10, 0, 1)
	check(hit(spam, 1, 1), "First spam-scenario hit")
	check(not Match.input(spam, 1, 10.55, 0.5, 0.5, 10.65), "Duplicate circle penalized")
	check(not Match.input(spam, 1, 11.2, 0, 0, 11.3), "Inaccurate position penalized")
	check(hit(spam, 1, 2), "Retry can earn hit but retains penalty")
	finish(spam)
	local spamResult = Match.result(spam.scores[1])
	check(spamResult.inaccurate == 2 and spamResult.penalty == 30, "Incorrect inputs counted and penalized")
	check(near(spamResult.precision, 200 / 26), "Spam cannot inflate precision")
	check(spamResult.bestCombo == 1, "Wrong aim breaks combo")

	local delayed = Match.new(10, 0, 1)
	check(Match.input(delayed, 1, 10.89, 0.5, 0.5, 11.04), "Legitimate bounded late arrival accepted")
	check(not Match.input(delayed, 1, 11.1, first[2].x, first[2].y, 11.29), "Beyond latency allowance refused")
	check(not Match.input(delayed, 1, 11.39, first[2].x, first[2].y, 11.35), "Future timestamp refused")
	check(not Match.input(delayed, 1, 11.35, 0 / 0, 0.3, 11.4), "Nonfinite aim refused")
	check(delayed.scores[1].lastTime == 11.35, "Valid time reaches aim validation outside rate-limit window")
	check(not Match.input(delayed, 1, 11.4, first[2].x, first[2].y, 11.41), "Rapid server-arrival spam refused")
	check(not Match.input(delayed, 1, 11.34, first[2].x, first[2].y, 11.45), "Backdated order refused")

	local inactive = Match.new(10, 0, 2)
	check(
		not Match.input(inactive, 1, 9.9, 0.5, 0.5, 9.9) and inactive.scores[1].inputs == 0,
		"Countdown cannot be penalized or scored"
	)
	for index = 1, Rules.MaxInputs + 1 do
		local time = 10 + index * 0.03
		Match.input(inactive, 1, time, 0, 0, time)
	end
	finish(inactive)
	check(
		Match.result(inactive.scores[1]).disqualified and Match.result(inactive.scores[1]).total == 0,
		"Excess input cannot yield a success-shaped score"
	)
	check(Match.winner(inactive) == 2, "Disqualified player loses even to legitimate zero")
	check(
		inactive.scores[2].misses == 24 and Match.result(inactive.scores[2]).precision == 0,
		"Idle targets are misses"
	)

	-- Compare aim against the largest practical bonus advantage: skipping the four
	-- slowest opportunities preserves all faster weights and a long ending combo.
	local balance = Match.new(10, 0, 2)
	for index = 1, 24 do
		local target = balance.pattern[index]
		local time = balance.start + target.at + target.lifetime * 0.5
		local offset = Rules.TargetRadius * math.sqrt(0.2) -- 90% spatial quality.
		check(Match.input(balance, 1, time, target.x + offset, target.y, time + 0.1), "Consistent 90-percent aim")
		if index > 4 then
			check(hit(balance, 2, index), "Selective late center aim")
		end
	end
	finish(balance)
	local consistent, late = Match.result(balance.scores[1]), Match.result(balance.scores[2])
	check(near(consistent.precision, 90) and near(late.precision, 100 * 20 / 24), "Independent comparison precision")
	check(
		consistent.total > late.total,
		"Four skipped slow hits cannot beat consistent ninety-percent aim through late/combo bonuses"
	)
	print(
		"EXP03 SCORE BALANCE:",
		"perfect",
		full.total,
		"90% all",
		consistent.total,
		"20 late centers",
		late.total,
		"edge all",
		edgeResult.total
	)

	for _, size in { Vector2.new(1280, 720), Vector2.new(390, 844), Vector2.new(844, 390), Vector2.new(320, 300) } do
		local diameter, y = Rules.boardSize(size.X, size.Y)
		check(
			diameter > 0 and diameter <= size.X - 24 and y - diameter / 2 >= 84 and y + diameter / 2 <= size.Y - 32,
			"Arena fits desktop/phone/compact bounds"
		)
	end
	for _, bounds in { Vector3.new(413, 861, 113), Vector3.new(790, 380, 66) } do
		local diameter, y = Rules.boardSize(bounds.X, bounds.Y, bounds.Z)
		check(
			y - diameter / 2 >= bounds.Z + 64 and y + diameter / 2 <= bounds.Y - 32,
			"Inset-aware phone arena clears controls and hardware-safe footer"
		)
	end
	return count
end
