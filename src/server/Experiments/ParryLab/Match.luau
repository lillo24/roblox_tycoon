--!strict

local Rules = require(game:GetService("ReplicatedStorage").TycoonShared.Experiments.ParryLab.Rules)
local T = Rules.Tuning
local Match = {}
Match.__index = Match
export type Fighter = {
	health: number,
	busyUntil: number,
	parryAt: number,
	parryReady: number,
	counterUntil: number,
	message: string,
	parries: number,
}
export type Attack = { actor: number, impact: number, counter: boolean }
export type Battle = typeof(setmetatable({
	fighters = {} :: { Fighter },
	attacks = {} :: { Attack },
	winner = nil :: number?,
}, Match))

function Match.new(): Battle
	local fighters: { Fighter } = {}
	for _ = 1, 2 do
		table.insert(fighters, {
			health = T.Health,
			busyUntil = 0,
			parryAt = -math.huge,
			parryReady = 0,
			counterUntil = 0,
			message = "Read the windup. Parry just before impact.",
			parries = 0,
		})
	end
	return setmetatable({ fighters = fighters, attacks = {}, winner = nil }, Match)
end

function Match.action(self: Battle, actor: number, action: string, at: number): boolean
	local fighter = self.fighters[actor]
	if self.winner or not fighter or fighter.health <= 0 or at < fighter.busyUntil then
		return false
	end
	if action == "attack" then
		local counter = at < fighter.counterUntil
		fighter.counterUntil = 0
		fighter.busyUntil = at + T.Windup + T.Recovery
		fighter.message = if counter then "Counter committed!" else "Attack committed"
		table.insert(self.attacks, { actor = actor, impact = at + T.Windup, counter = counter })
		return true
	elseif action == "parry" and at >= fighter.parryReady then
		fighter.parryAt = at
		fighter.parryReady = at + T.ParryCooldown
		fighter.busyUntil = at + T.FailedRecovery
		fighter.message = "Guard: a brief window, then recovery"
		return true
	end
	return false
end

-- Resolve after the bounded input-arrival grace. Check geometry at impact in the
-- adapter and retain it; moving after impact cannot escape or create a hit.
function Match.step(self: Battle, now: number, inRange: (number, number) -> boolean)
	for index = #self.attacks, 1, -1 do
		local attack = self.attacks[index]
		if now < attack.impact + T.LatencyAllowance then
			continue
		end
		table.remove(self.attacks, index)
		if self.winner then
			continue
		end
		local source, target = self.fighters[attack.actor], self.fighters[3 - attack.actor]
		if not inRange(attack.actor, attack.impact) then
			source.message = "Miss: opponent outside the facing/range check"
			continue
		end
		if target.parryAt <= attack.impact and attack.impact - target.parryAt <= T.ParryWindow then
			target.parries += 1
			target.busyUntil = attack.impact
			target.counterUntil = now + T.CounterWindow
			target.message = "PARRY! Attack now for a stronger counter"
			source.busyUntil = now + T.Stun
			source.message = "Parried: staggered"
			-- A parry cancels the staggered fighter's other pending strike.
			for pending = #self.attacks, 1, -1 do
				if self.attacks[pending].actor == attack.actor then
					table.remove(self.attacks, pending)
				end
			end
		else
			local damage = if attack.counter then T.CounterDamage else T.Damage
			target.health = math.max(0, target.health - damage)
			target.message = if target.parryAt > attack.impact
				then "Too late: the strike already landed"
				elseif attack.impact - target.parryAt < T.ParryCooldown then "Too early: guard ended before impact"
				else "Hit: read the approaching amber ring"
			source.message = if attack.counter then `COUNTER: {damage} damage` else `Hit: {damage} damage`
		end
	end
	if self.fighters[1].health == 0 or self.fighters[2].health == 0 then
		self.winner = if self.fighters[1].health == self.fighters[2].health
			then 0
			elseif self.fighters[1].health > self.fighters[2].health then 1
			else 2
		table.clear(self.attacks)
	end
end

return Match
