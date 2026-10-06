--!strict

-- One source of truth for this reversible order-choice experiment, not a balanced economy.
export type Id = "income_booster" | "workshop" | "booster_tuning" | "workshop_expansion"
export type Definition = {
	read Id: Id,
	read DisplayName: string,
	read Cost: number,
	read IncomeDelta: number,
	read Requires: Id?,
}
export type Purchases = { [Id]: boolean }
export type Availability = "locked" | "unaffordable" | "affordable" | "purchased"
export type PurchaseReason =
	"inactive"
	| "not-owner"
	| "unknown-upgrade"
	| "locked"
	| "already-purchased"
	| "insufficient-cash"
	| "purchased"

local UpgradeCatalogue = {}

-- Validate before a session/world is created. Copy/freeze records so later edits to
-- constructor input cannot change a running server's prices or prerequisites.
function UpgradeCatalogue.validate(definitions: { Definition }): { [string]: Definition }
	assert(#definitions > 0, "Tycoon catalogue: at least one upgrade is required")
	local byId: { [string]: Definition } = {}
	for _, definition in definitions do
		local id = definition.Id
		assert(not byId[id], `Tycoon catalogue: duplicate ID '{id}'`)
		assert(#definition.DisplayName > 0, `Tycoon catalogue '{id}': DisplayName is empty`)
		local numbers: { [string]: number } = { Cost = definition.Cost, IncomeDelta = definition.IncomeDelta }
		for field, value in numbers do
			assert(
				value > 0 and value < math.huge and value % 1 == 0,
				`Tycoon catalogue '{id}': {field} must be a finite positive integer`
			)
		end
		byId[id] = table.freeze({
			Id = id,
			DisplayName = definition.DisplayName,
			Cost = definition.Cost,
			IncomeDelta = definition.IncomeDelta,
			Requires = definition.Requires,
		})
	end
	local visiting: { [string]: boolean } = {}
	local visited: { [string]: boolean } = {}
	local function visit(id: string)
		assert(not visiting[id], `Tycoon catalogue: prerequisite cycle at '{id}'`)
		if visited[id] then
			return
		end
		visiting[id] = true
		local required = byId[id].Requires
		if required then
			assert(byId[required], `Tycoon catalogue '{id}': missing prerequisite '{required}'`)
			visit(required)
		end
		visiting[id] = nil
		visited[id] = true
	end
	for id in byId do
		visit(id)
	end
	return table.freeze(byId)
end

-- Exactly four provisional one-time upgrades. All can eventually be owned.
local definitions: { Definition } = {
	{ Id = "income_booster", DisplayName = "Income Booster", Cost = 10, IncomeDelta = 1 },
	{ Id = "workshop", DisplayName = "Workshop", Cost = 30, IncomeDelta = 3 },
	{ Id = "booster_tuning", DisplayName = "Booster Tuning", Cost = 25, IncomeDelta = 2, Requires = "income_booster" },
	{
		Id = "workshop_expansion",
		DisplayName = "Workshop Expansion",
		Cost = 60,
		IncomeDelta = 5,
		Requires = "workshop",
	},
}
UpgradeCatalogue.ById = UpgradeCatalogue.validate(definitions)
-- Keep deterministic display order; records and the array are frozen independently.
for index, definition in definitions do
	definitions[index] = UpgradeCatalogue.ById[definition.Id]
end
UpgradeCatalogue.Definitions = table.freeze(definitions)

function UpgradeCatalogue.purchaseAttribute(id: Id): string
	return `TycoonPurchased_{id}`
end

function UpgradeCatalogue.availability(
	definition: Definition,
	purchases: Purchases,
	cash: number
): (Availability, number)
	if purchases[definition.Id] then
		return "purchased", 0
	end
	if definition.Requires and not purchases[definition.Requires] then
		return "locked", 0
	end
	if cash < definition.Cost then
		return "unaffordable", definition.Cost - cash
	end
	return "affordable", 0
end

function UpgradeCatalogue.stateText(definition: Definition, purchases: Purchases, cash: number): string
	local state, missing = UpgradeCatalogue.availability(definition, purchases, cash)
	if state == "purchased" then
		return "Owned"
	end
	if state == "locked" then
		local required = definition.Requires
		assert(required, "Tycoon catalogue: locked upgrade lacks a prerequisite")
		return `Buy {UpgradeCatalogue.ById[required].DisplayName} first`
	end
	if state == "unaffordable" then
		return `Need {missing} more cash`
	end
	return "Buy now"
end

function UpgradeCatalogue.resultMessage(id: string, reason: PurchaseReason, missing: number): string
	if reason == "inactive" then
		return "No assigned plot"
	end
	if reason == "not-owner" then
		return "Not your plot"
	end
	if reason == "unknown-upgrade" then
		return "Unknown upgrade"
	end
	if reason == "already-purchased" then
		return "Already purchased"
	end
	if reason == "insufficient-cash" then
		return `Need {missing} more cash`
	end
	local definition = UpgradeCatalogue.ById[id]
	assert(definition, `Tycoon catalogue: feedback for unknown upgrade '{id}'`)
	if reason == "locked" then
		local required = definition.Requires
		assert(required, "Tycoon catalogue: locked feedback lacks a prerequisite")
		return `Buy {UpgradeCatalogue.ById[required].DisplayName} first`
	end
	return `Purchased {definition.DisplayName}`
end

return table.freeze(UpgradeCatalogue)
