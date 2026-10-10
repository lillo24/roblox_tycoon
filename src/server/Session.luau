--!strict

-- Server-only session state. No Instances, player attributes, timers, or persistence.
local Catalogue = require(game:GetService("ReplicatedStorage").TycoonShared.UpgradeCatalogue)
export type Tuning = {
	read PlotCount: number,
	read StartingCash: number,
	read BaseIncome: number,
	read CashLimit: number?,
}

export type State = {
	userId: number,
	plotId: number,
	cash: number,
	incomeRate: number,
	purchases: Catalogue.Purchases,
	paused: boolean?, -- Only Infinite handoff sets this; ordinary Session is unchanged.
}

local Session = {}
Session.__index = Session

type Data = {
	tuning: Tuning,
	definitions: { [string]: Catalogue.Definition },
	states: { [number]: State },
	owners: { [number]: number },
}
export type Session = typeof(setmetatable({} :: Data, Session))

function Session.new(tuning: Tuning, definitions: { Catalogue.Definition }): Session
	assert(tuning.PlotCount > 0 and tuning.PlotCount % 1 == 0, "Tycoon: PlotCount must be a positive integer")
	assert(
		tuning.StartingCash >= 0 and tuning.StartingCash % 1 == 0,
		"Tycoon: StartingCash must be a nonnegative integer"
	)
	assert(tuning.BaseIncome > 0 and tuning.BaseIncome % 1 == 0, "Tycoon: BaseIncome must be a positive integer")
	assert(
		not tuning.CashLimit
			or tuning.CashLimit >= tuning.StartingCash
				and tuning.CashLimit < math.huge
				and tuning.CashLimit % 1 == 0,
		"Tycoon: CashLimit must be a finite integer at least StartingCash"
	)
	local byId = Catalogue.validate(definitions)
	local snapshot = table.freeze({
		PlotCount = tuning.PlotCount,
		StartingCash = tuning.StartingCash,
		BaseIncome = tuning.BaseIncome,
		CashLimit = tuning.CashLimit,
	})
	return setmetatable({ tuning = snapshot, definitions = byId, states = {}, owners = {} }, Session)
end

function Session.get(self: Session, userId: number): State?
	return self.states[userId]
end

-- Optional restoration is server-owned, validated before allocation. Income is
-- always rebuilt from this session's trusted catalogue, never a saved rate.
function Session.assign(
	self: Session,
	userId: number,
	initial: { cash: number, purchases: Catalogue.Purchases }?
): State?
	local cash, purchases, rate = self.tuning.StartingCash, {}, self.tuning.BaseIncome
	if initial then
		assert(
			initial.cash >= 0 and initial.cash < math.huge and initial.cash % 1 == 0,
			"Tycoon: invalid restored cash"
		)
		cash = initial.cash
		assert(not self.tuning.CashLimit or cash <= self.tuning.CashLimit, "Tycoon: restored cash exceeds CashLimit")
		for id, owned in initial.purchases do
			local definition = self.definitions[id]
			assert(definition and owned == true, "Tycoon: invalid restored purchase")
			assert(
				not definition.Requires or initial.purchases[definition.Requires],
				"Tycoon: missing restored prerequisite"
			)
			purchases[id] = true
			rate += definition.IncomeDelta
		end
	end
	local existing = self.states[userId]
	if existing then
		return existing
	end
	for plotId = 1, self.tuning.PlotCount do
		if self.owners[plotId] == nil then
			local state: State = {
				userId = userId,
				plotId = plotId,
				cash = cash,
				incomeRate = rate,
				purchases = purchases,
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

function Session.assignedCount(self: Session): number
	local count = 0
	for _ in self.states do
		count += 1
	end
	return count
end

-- Server-only additive reward, with no yield, attribute writes, income or purchase effects.
-- Inactive/replaced owners cannot receive a credit. Amount is resolved by the event.
function Session.credit(self: Session, userId: number, amount: number): boolean
	assert(amount > 0 and amount < math.huge and amount % 1 == 0, "Tycoon: credit must be a finite positive integer")
	local state = self.states[userId]
	if not state or state.paused or self.owners[state.plotId] ~= userId then
		return false
	end
	state.cash = math.min(state.cash + amount, self.tuning.CashLimit or math.huge)
	return true
end

function Session.accrue(self: Session, ticks: number)
	assert(ticks >= 0 and ticks % 1 == 0, "Tycoon: income ticks must be nonnegative integers")
	for _, state in self.states do
		if state.paused then
			continue
		end
		-- Persistent integer storage has an exact-integer ceiling; Prototype leaves
		-- CashLimit absent and retains its existing behavior.
		state.cash = math.min(state.cash + state.incomeRate * ticks, self.tuning.CashLimit or math.huge)
	end
end

-- No yields: eligibility, deduction, and application form one server transaction.
-- Returns accepted, reason, missing cash (zero for other results). IDs resolve on
-- the server; neither price nor effect is supplied by the caller.
function Session.purchase(
	self: Session,
	userId: number,
	plotId: number,
	upgradeId: string
): (boolean, Catalogue.PurchaseReason, number)
	local state = self.states[userId]
	if not state or state.paused then
		return false, "inactive", 0
	end
	if state.plotId ~= plotId or self.owners[plotId] ~= userId then
		return false, "not-owner", 0
	end
	local definition = self.definitions[upgradeId]
	if not definition then
		return false, "unknown-upgrade", 0
	end
	local availability, missing = Catalogue.availability(definition, state.purchases, state.cash)
	if availability == "purchased" then
		return false, "already-purchased", 0
	end
	if availability == "locked" then
		return false, "locked", 0
	end
	if availability == "unaffordable" then
		return false, "insufficient-cash", missing
	end
	state.cash -= definition.Cost
	state.purchases[definition.Id] = true
	state.incomeRate += definition.IncomeDelta
	return true, "purchased", 0
end

return Session
