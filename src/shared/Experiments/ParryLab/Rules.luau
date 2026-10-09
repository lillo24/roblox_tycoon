--!strict

-- All times are seconds on workspace:GetServerTimeNow(); no economy/progression.
local Rules = {}
Rules.RemoteName = "ParryLabInput"
Rules.StateName = "ParryLabState"
Rules.Tuning = table.freeze({
	Health = 100,
	Damage = 20,
	CounterDamage = 36,
	Windup = 0.62,
	Recovery = 0.38,
	ParryWindow = 0.11,
	ParryCooldown = 0.85,
	FailedRecovery = 0.55,
	Stun = 0.9,
	CounterWindow = 0.8,
	LatencyAllowance = 0.15,
	FutureAllowance = 0.03,
	Range = 11,
	BotInterval = 2.0,
	InputInterval = 0.06,
})

function Rules.validTime(value: any, now: number): boolean
	return typeof(value) == "number"
		and value == value
		and value >= now - Rules.Tuning.LatencyAllowance
		and value <= now + Rules.Tuning.FutureAllowance
end

return table.freeze(Rules)
