--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.TycoonShared.Config)
local Catalogue = require(ReplicatedStorage.TycoonShared.UpgradeCatalogue)
local Rules = require(ReplicatedStorage.TycoonShared.SupplyRules)

local State = {}
export type Panel = "Factory" | "Settings" | "Help"
export type Economy = {
	assigned: boolean,
	plot: number?,
	cash: number?,
	income: number?,
	full: boolean,
	purchases: Catalogue.Purchases,
	count: number,
}

function State.number(value: number): string
	assert(value == value and math.abs(value) < math.huge, "UI: expected finite display value")
	local raw = if value % 1 == 0 then string.format("%.0f", value) else tostring(value)
	local sign, integer, rest = string.match(raw, "^(%-?)(%d+)(.*)$")
	assert(sign and integer and rest, `UI: cannot format '{raw}'`)
	local reversed = string.reverse(integer)
	local grouped = string.gsub(reversed, "(%d%d%d)", "%1,")
	grouped = string.gsub(grouped, ",$", "")
	return sign .. string.reverse(grouped) .. rest
end

-- Only converts a replicated per-tick value; never derives purchase eligibility.
function State.rate(income: number, interval: number): string
	assert(interval > 0 and interval < math.huge, "UI: IncomeInterval must be finite and positive")
	return `+{State.number(income / interval)}/sec`
end

function State.economy(read: (string) -> any): Economy
	local cash, income, plot =
		read(Config.Attributes.Cash), read(Config.Attributes.IncomeRate), read(Config.Attributes.PlotId)
	local assigned = read(Config.Attributes.Assignment) == "Assigned"
		and typeof(cash) == "number"
		and typeof(income) == "number"
		and typeof(plot) == "number"
	local purchases: Catalogue.Purchases = {}
	local count = 0
	for _, definition in Catalogue.Definitions do
		local owned = assigned and read(Catalogue.purchaseAttribute(definition.Id)) == true
		purchases[definition.Id] = owned
		if owned then
			count += 1
		end
	end
	return {
		assigned = assigned,
		plot = if assigned then plot :: number else nil,
		cash = if assigned then cash :: number else nil,
		income = if assigned then income :: number else nil,
		full = read(Config.Attributes.Assignment) == "Full",
		purchases = purchases,
		count = count,
	}
end

function State.summary(economy: Economy): string
	if economy.assigned then
		assert(economy.plot and economy.cash and economy.income, "UI: assigned economy is incomplete")
		return `Factory {economy.plot}  •  Cash {State.number(economy.cash)}\n{State.rate(
			economy.income,
			Config.IncomeInterval
		)}`
	end
	return if economy.full then "Factories full\nNo income this session" else "Joining…\nWaiting for factory state"
end

function State.entry(definition: Catalogue.Definition, economy: Economy): string
	local requirement = if definition.Requires then Catalogue.ById[definition.Requires].DisplayName else "None"
	local status = "Awaiting factory"
	if economy.assigned then
		assert(economy.cash, "UI: assigned cash missing")
		local availability, missing = Catalogue.availability(definition, economy.purchases, economy.cash)
		status = if availability == "purchased"
			then "Owned"
			elseif availability == "locked" then "Locked — prerequisite needed"
			elseif availability == "unaffordable" then `Unaffordable — need {State.number(missing)} more cash`
			else "Available — use the world pad"
	end
	return `{definition.DisplayName}\n{State.number(definition.Cost)} cash • {State.rate(
		definition.IncomeDelta,
		Config.IncomeInterval
	)}\nRequires: {requirement}\n{status}`
end

function State.event(snapshot: Rules.Snapshot?, now: number, assigned: boolean): string
	if not snapshot then
		return "Supply Cache\nWaiting for server state"
	end
	-- Shared rules own phases/deadlines/winners. Replace only their layout-specific hint.
	local description = Rules.describe(snapshot, now, assigned)
	local first = string.match(description, "^[^\n]+")
	assert(first, "UI: empty Supply Cache description")
	return first .. (if assigned then "\nAt the shared cache marker" else "\nA factory is needed to claim")
end

function State.toggle(current: Panel?, requested: Panel): Panel?
	return if current == requested then nil else requested
end

return State
