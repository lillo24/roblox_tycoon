--!strict

local Match = require(game:GetService("ServerScriptService").TycoonServer.Experiments.ParryLab.Match)
local Rules = require(game:GetService("ReplicatedStorage").TycoonShared.Experiments.ParryLab.Rules)

return function(): number
	local count = 0
	local function check(value: boolean, message: string)
		assert(value, message)
		count += 1
	end
	local T = Rules.Tuning
	local battle = Match.new()
	check(battle:action(2, "attack", 1), "Opponent commits")
	check(not battle:action(2, "attack", 1.01), "No repeated attack while committed")
	check(battle:action(1, "parry", 1 + T.Windup - 0.05), "Demanding guard accepted")
	battle:step(1 + T.Windup + T.LatencyAllowance - 0.001, function()
		return true
	end)
	check(battle.fighters[1].parries == 0, "Wait for bounded delivery grace")
	battle:step(1 + T.Windup + T.LatencyAllowance, function()
		return true
	end)
	check(battle.fighters[1].health == 100 and battle.fighters[1].parries == 1, "Successful parry blocks damage")
	check(not battle:action(2, "attack", 1.9), "Attacker staggered")
	check(battle:action(1, "attack", 1.8), "Counter available")
	battle:step(1.8 + T.Windup + T.LatencyAllowance, function()
		return true
	end)
	check(battle.fighters[2].health == 64, "Counter gives exactly 36 damage")
	check(not battle:action(1, "parry", 1.81), "Cannot cancel commitment into guard")
	for _, offset in { -0.2, 0.01 } do
		local miss = Match.new()
		check(miss:action(2, "attack", 1), "Miss fixture attack")
		check(miss:action(1, "parry", 1 + T.Windup + offset), "Miss fixture guard")
		miss:step(1 + T.Windup + T.LatencyAllowance, function()
			return true
		end)
		check(miss.fighters[1].health == 80 and miss.fighters[1].parries == 0, "Early/late parry is a hit")
		check(
			string.find(miss.fighters[1].message, if offset < 0 then "early" else "late") ~= nil,
			"Explains timing failure"
		)
	end
	local spam = Match.new()
	check(spam:action(1, "parry", 1), "Initial guard")
	check(not spam:action(1, "parry", 1.56), "Cooldown blocks guard spam after recovery")
	check(spam:action(1, "parry", 1 + T.ParryCooldown), "Guard ready at boundary")
	local outside = Match.new()
	check(outside:action(1, "attack", 1), "Range fixture")
	outside:step(2, function()
		return false
	end)
	check(outside.fighters[2].health == 100, "Out of range cannot deal damage")
	for i = 1, 5 do
		check(outside:action(1, "attack", 2 + i * 2), "Repeated legal attacks")
		outside:step(3 + i * 2, function()
			return true
		end)
	end
	check(outside.winner == 1 and outside.fighters[2].health == 0, "Five ordinary attacks win without parry")
	check(not outside:action(2, "parry", 20), "Ended battle refuses input")
	local trade = Match.new()
	trade.fighters[1].health, trade.fighters[2].health = 20, 20
	check(trade:action(1, "attack", 1) and trade:action(2, "attack", 1), "Simultaneous committed strikes")
	trade:step(2, function()
		return true
	end)
	check(trade.winner == 0, "Already committed simultaneous lethal strikes trade")
	check(Rules.validTime(9.85, 10) and Rules.validTime(10.03, 10), "Time envelope inclusive")
	for _, value in { 9.849, 10.031, math.huge, -math.huge, 0 / 0, "10", {} } do
		check(not Rules.validTime(value, 10), "Reject malformed/stale/future timestamps")
	end
	check(not Match.new():action(3, "attack", 1), "Unknown participant refused")
	check(not Match.new():action(1, "unknown", 1), "Unknown action refused")
	return count
end
