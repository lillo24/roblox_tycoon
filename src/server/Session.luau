--!strict

-- Server-only session state. No Instances, player attributes, timers, or persistence.
local Catalogue = require(game:GetService("ReplicatedStorage").TycoonShared.UpgradeCatalogue)
export type Tuning = {
	read PlotCount: number,
	read StartingCash: number,
	read BaseIncome: number,
}

export type State = {
	userId: number,
	plotId: number,
	cash: number,
	incomeRate: number,
	purchases: Catalogue.Purchases,
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
	local byId = Catalogue.validate(definitions)
	local snapshot = table.freeze({
		PlotCount = tuning.PlotCount,
		StartingCash = tuning.StartingCash,
		BaseIncome = tuning.BaseIncome,
	})
	return setmetatable({ tuning = snapshot, definitions = byId, states = {}, owners = {} }, Session)
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
				purchases = {},
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
-- Returns accepted, reason, missing cash (zero for other results). IDs resolve on
-- the server; neither price nor effect is supplied by the caller.
function Session.purchase(
	self: Session,
	userId: number,
	plotId: number,
	upgradeId: string
): (boolean, Catalogue.PurchaseReason, number)
	local state = self.states[userId]
	if not state then
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
