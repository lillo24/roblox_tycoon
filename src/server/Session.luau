--!strict

-- Server-only session state. No Instances, player attributes, timers, or persistence.
export type Tuning = {
	PlotCount: number,
	StartingCash: number,
	BaseIncome: number,
	UpgradedIncome: number,
	UpgradeCost: number,
}

export type State = {
	userId: number,
	plotId: number,
	cash: number,
	incomeRate: number,
	purchased: boolean,
}

local Session = {}
Session.__index = Session

type Data = {
	tuning: Tuning,
	states: { [number]: State },
	owners: { [number]: number },
}
export type Session = typeof(setmetatable({} :: Data, Session))

function Session.new(tuning: Tuning): Session
	assert(tuning.PlotCount > 0 and tuning.PlotCount % 1 == 0, "Tycoon: PlotCount must be a positive integer")
	assert(
		tuning.StartingCash >= 0 and tuning.StartingCash % 1 == 0,
		"Tycoon: StartingCash must be a nonnegative integer"
	)
	assert(tuning.BaseIncome > 0 and tuning.BaseIncome % 1 == 0, "Tycoon: BaseIncome must be a positive integer")
	assert(
		tuning.UpgradedIncome > tuning.BaseIncome and tuning.UpgradedIncome % 1 == 0,
		"Tycoon: invalid UpgradedIncome"
	)
	assert(tuning.UpgradeCost > 0 and tuning.UpgradeCost % 1 == 0, "Tycoon: UpgradeCost must be a positive integer")
	return setmetatable({ tuning = tuning, states = {}, owners = {} }, Session)
end

function Session.get(self: Session, userId: number): State?
	return self.states[userId]
end

function Session.assign(self: Session, userId: number): State?
	local existing = self.states[userId]
	if existing then
		return existing
	end
	for plotId = 1, self.tuning.PlotCount do
		if self.owners[plotId] == nil then
			local state: State = {
				userId = userId,
				plotId = plotId,
				cash = self.tuning.StartingCash,
				incomeRate = self.tuning.BaseIncome,
				purchased = false,
			}
			self.owners[plotId] = userId
			self.states[userId] = state
			return state
		end
	end
	return nil -- Explicit full-capacity result; the adapter reports it to the player.
end

function Session.release(self: Session, userId: number): number?
	local state = self.states[userId]
	if not state then
		return nil
	end
	self.owners[state.plotId] = nil
	self.states[userId] = nil
	return state.plotId
end

function Session.accrue(self: Session, ticks: number)
	assert(ticks >= 0 and ticks % 1 == 0, "Tycoon: income ticks must be nonnegative integers")
	for _, state in self.states do
		state.cash += state.incomeRate * ticks
	end
end

-- No yields: eligibility, deduction, and application form one server transaction.
function Session.purchase(self: Session, userId: number, plotId: number): (boolean, string)
	local state = self.states[userId]
	if not state then
		return false, "inactive"
	end
	if state.plotId ~= plotId or self.owners[plotId] ~= userId then
		return false, "not-owner"
	end
	if state.purchased then
		return false, "already-purchased"
	end
	if state.cash < self.tuning.UpgradeCost then
		return false, "insufficient-cash"
	end
	state.cash -= self.tuning.UpgradeCost
	state.purchased = true
	state.incomeRate = self.tuning.UpgradedIncome
	return true, "purchased"
end

return Session
