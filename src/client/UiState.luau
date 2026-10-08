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
	unavailable: string?,
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
	local assignment = read(Config.Attributes.Assignment)
	local issue: string? = nil
	local numeric: { [string]: any } = { Cash = cash, IncomeRate = income, PlotId = plot }
	for name, value in numeric do
		if value ~= nil and (typeof(value) ~= "number" or value ~= value or value < 0 or value >= math.huge) then
			issue = `Invalid {name} attribute`
		end
	end
	if typeof(plot) == "number" and (plot < 1 or plot % 1 ~= 0) then
		issue = "Invalid PlotId attribute"
	end
	if assignment ~= nil and assignment ~= "Assigned" and assignment ~= "Full" then
		issue = "Invalid assignment attribute"
	end
	local assigned = assignment == "Assigned"
		and typeof(cash) == "number"
		and typeof(income) == "number"
		and typeof(plot) == "number"
		and issue == nil
	local purchases: Catalogue.Purchases = {}
	local count = 0
	for _, definition in Catalogue.Definitions do
		local value = read(Catalogue.purchaseAttribute(definition.Id))
		if value ~= nil and typeof(value) ~= "boolean" then
			issue = `Invalid purchase attribute {definition.Id}`
		end
		local owned = assigned and value == true
		purchases[definition.Id] = owned
		if owned then
			count += 1
		end
	end
	if issue then
		assigned, purchases, count = false, {}, 0
	end
	return {
		assigned = assigned,
		plot = if assigned then plot :: number else nil,
		cash = if assigned then cash :: number else nil,
		income = if assigned then income :: number else nil,
		full = read(Config.Attributes.Assignment) == "Full",
		purchases = purchases,
		count = count,
		unavailable = issue,
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
	if economy.unavailable then
		return "Factory state unavailable\nHelp and Settings remain available"
	end
	return if economy.full then "Factories full\nNo income this session" else "Joining…\nWaiting for factory state"
end

-- Validate the external atomic snapshot before its fields reach SupplyFeedback.
-- JSON syntax errors are handled at the decoding boundary, not around the HUD.
function State.snapshot(value: any): (Rules.Snapshot?, string?)
	if typeof(value) ~= "table" then
		return nil, "expected snapshot object"
	end
	for _, key in { "id", "opensAt", "closesAt", "nextOpensAt", "deadline", "reward" } do
		local field = value[key]
		if typeof(field) ~= "number" or field ~= field or field < 0 or field >= math.huge then
			return nil, `invalid snapshot {key}`
		end
	end
	if value.id % 1 ~= 0 or value.reward % 1 ~= 0 or value.reward <= 0 then
		return nil, "invalid snapshot id/reward"
	end
	if not table.find({ "idle", "waiting", "warning", "open", "result" }, value.phase) then
		return nil, "invalid snapshot phase"
	end
	if
		value.winnerUserId ~= nil
		and (
			typeof(value.winnerUserId) ~= "number"
			or value.winnerUserId % 1 ~= 0
			or math.abs(value.winnerUserId) >= math.huge
		)
	then
		return nil, "invalid snapshot winnerUserId"
	end
	if value.winnerName ~= nil and typeof(value.winnerName) ~= "string" then
		return nil, "invalid snapshot winnerName"
	end
	if (value.winnerUserId == nil) ~= (value.winnerName == nil) then
		return nil, "incomplete snapshot winner"
	end
	return value :: Rules.Snapshot, nil
end

-- Short landscape views need a single compact row above the panel.
function State.compactSummary(economy: Economy): string
	if not economy.assigned then
		return State.summary(economy)
	end
	assert(economy.plot and economy.cash and economy.income, "UI: assigned economy is incomplete")
	return `F{economy.plot} • Cash {State.number(economy.cash)} • {State.rate(economy.income, Config.IncomeInterval)}`
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
