--!strict

-- Provisional, reversible Supply Cache rules; purchase tuning/catalogue are unchanged.
export type Tuning = {
	read FirstDelay: number,
	read Interval: number,
	read Warning: number,
	read Window: number,
	read Reward: number,
	read ResultDuration: number,
	read Radius: number,
	read RequestInterval: number,
}
export type Phase = "idle" | "waiting" | "warning" | "open" | "result"
export type Snapshot = {
	read id: number,
	read phase: Phase,
	read opensAt: number,
	read closesAt: number,
	read nextOpensAt: number,
	read deadline: number,
	read reward: number,
	read winnerUserId: number?,
	read winnerName: string?,
}

local SupplyRules = {}
SupplyRules.StateName = "TycoonSupplyState"
SupplyRules.FeedbackName = "TycoonSupplyFeedback"
SupplyRules.WorldName = "SupplyCache"

function SupplyRules.validate(tuning: Tuning): Tuning
	local values: { [string]: number } = {
		FirstDelay = tuning.FirstDelay,
		Interval = tuning.Interval,
		Warning = tuning.Warning,
		Window = tuning.Window,
		Reward = tuning.Reward,
		ResultDuration = tuning.ResultDuration,
		Radius = tuning.Radius,
		RequestInterval = tuning.RequestInterval,
	}
	for field, value in values do
		assert(value > 0 and value < math.huge, `Supply Cache: {field} must be finite and positive`)
	end
	assert(tuning.Reward % 1 == 0, "Supply Cache: Reward must be a positive integer")
	assert(tuning.FirstDelay > tuning.Warning, "Supply Cache: FirstDelay must exceed Warning")
	assert(
		tuning.Interval > tuning.Warning + tuning.Window + tuning.ResultDuration,
		"Supply Cache: Interval must exceed Warning + Window + ResultDuration"
	)
	return table.freeze({
		FirstDelay = tuning.FirstDelay,
		Interval = tuning.Interval,
		Warning = tuning.Warning,
		Window = tuning.Window,
		Reward = tuning.Reward,
		ResultDuration = tuning.ResultDuration,
		Radius = tuning.Radius,
		RequestInterval = tuning.RequestInterval,
	})
end

SupplyRules.Tuning = SupplyRules.validate({
	FirstDelay = 20,
	Interval = 30,
	Warning = 5,
	Window = 10,
	Reward = 10,
	ResultDuration = 3,
	Radius = 6,
	RequestInterval = 0.25,
})

function SupplyRules.describe(state: Snapshot, now: number, assigned: boolean): string
	local remaining = math.max(0, math.ceil(state.deadline - now))
	local line: string
	if state.phase == "idle" then
		line = "Supply Cache: waiting for an owner"
	elseif state.phase == "waiting" then
		line = `Supply Cache in {remaining}s • +{state.reward} cash`
	elseif state.phase == "warning" then
		line = `Supply Cache soon: {remaining}s • +{state.reward} cash`
	elseif state.phase == "open" then
		line = `Supply Cache OPEN • {remaining}s • +{state.reward} cash`
	else
		line = if state.winnerName then `{state.winnerName} claimed +{state.reward} cash` else "Supply Cache expired"
	end
	return line .. "\n" .. (if assigned then "Shared cache in the central plaza" else "A plot is needed to claim")
end

return table.freeze(SupplyRules)
