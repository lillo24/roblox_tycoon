--!strict

local Shared = game:GetService("ReplicatedStorage").TycoonShared
local Catalogue = require(Shared.UpgradeCatalogue)
local Config = require(Shared.Config)
local Schema = {}
Schema.MaxCash = 9007199254740991 -- Largest exact integer; invalid data is refused, never clamped.
Schema.Slots = table.freeze({ "west_front", "east_front", "west_back", "east_back" })
local defaultSlots: { [Catalogue.Id]: string } = {
	income_booster = "west_front",
	workshop = "east_front",
	booster_tuning = "west_back",
	workshop_expansion = "east_back",
}
Schema.DefaultSlots = table.freeze(defaultSlots)
export type Data = {
	version: number,
	cash: number,
	assets: Catalogue.Purchases,
	placements: { [Catalogue.Id]: string },
}
export type Record = {
	version: number,
	data: Data,
	lease: { token: string, expiresAt: number }?,
	lastWrite: { token: string, sequence: number }?,
}

local function integer(value: any): boolean
	return typeof(value) == "number" and value >= 0 and value <= Schema.MaxCash and value % 1 == 0
end

local function fields(value: { [any]: any }, allowed: { string }): boolean
	for key in value do
		if typeof(key) ~= "string" or not table.find(allowed, key) then
			return false
		end
	end
	return true
end

-- Validation copies external tables and rejects unknown versions/IDs, holes in
-- prerequisites, duplicate slots, and extra fields (no silent lossy migration).
function Schema.decode(value: any): (Data?, string?)
	if
		typeof(value) ~= "table"
		or value.version ~= 1
		or not fields(value, { "version", "cash", "assets", "placements" })
	then
		return nil, "unsupported profile schema"
	end
	if not integer(value.cash) or typeof(value.assets) ~= "table" or typeof(value.placements) ~= "table" then
		return nil, "invalid cash/assets/placements"
	end
	local assets: Catalogue.Purchases = {}
	local placements: { [Catalogue.Id]: string } = {}
	local occupied: { [string]: boolean } = {}
	for key, owned in value.assets do
		if typeof(key) ~= "string" or not Catalogue.ById[key] or owned ~= true then
			return nil, "invalid owned asset"
		end
		local id = key :: Catalogue.Id
		local prerequisite = Catalogue.ById[id].Requires
		if prerequisite and value.assets[prerequisite] ~= true then
			return nil, "missing asset prerequisite"
		end
		local slot = value.placements[id]
		if typeof(slot) ~= "string" or not table.find(Schema.Slots, slot) or occupied[slot] then
			return nil, "missing, unknown or duplicate placement"
		end
		assets[id], placements[id], occupied[slot] = true, slot, true
	end
	for id in value.placements do
		if not assets[id] then
			return nil, "placement without owned asset"
		end
	end
	return { version = 1, cash = value.cash, assets = assets, placements = placements }, nil
end

function Schema.new(): Data
	return { version = 1, cash = Config.StartingCash, assets = {}, placements = {} }
end

function Schema.record(value: any): (Record?, string?)
	if
		typeof(value) ~= "table"
		or value.version ~= 1
		or not fields(value, { "version", "data", "lease", "lastWrite" })
	then
		return nil, "unsupported record schema"
	end
	local data, issue = Schema.decode(value.data)
	if not data then
		return nil, issue
	end
	local lease, lastWrite = value.lease, value.lastWrite
	if
		lease ~= nil
		and (
			typeof(lease) ~= "table"
			or not fields(lease, { "token", "expiresAt" })
			or typeof(lease.token) ~= "string"
			or #lease.token == 0
			or not integer(lease.expiresAt)
		)
	then
		return nil, "invalid profile lease"
	end
	if
		lastWrite ~= nil
		and (
			typeof(lastWrite) ~= "table"
			or not fields(lastWrite, { "token", "sequence" })
			or typeof(lastWrite.token) ~= "string"
			or #lastWrite.token == 0
			or not integer(lastWrite.sequence)
		)
	then
		return nil, "invalid write receipt"
	end
	return {
		version = 1,
		data = data,
		lease = if lease then { token = lease.token, expiresAt = lease.expiresAt } else nil,
		lastWrite = if lastWrite then { token = lastWrite.token, sequence = lastWrite.sequence } else nil,
	},
		nil
end

-- Ownership is independent of placement. New assets receive a stable default
-- slot, or the first free slot if a future/imported layout uses that position.
function Schema.capture(cash: number, assets: Catalogue.Purchases, previous: Data): Data
	local placements: { [Catalogue.Id]: string } = {}
	local occupied: { [string]: boolean } = {}
	for id, slot in previous.placements do
		if assets[id] then
			placements[id], occupied[slot] = slot, true
		end
	end
	for _, definition in Catalogue.Definitions do
		local id = definition.Id
		if assets[id] and not placements[id] then
			local slot = Schema.DefaultSlots[id]
			if occupied[slot] then
				for _, candidate in Schema.Slots do
					if not occupied[candidate] then
						slot = candidate
						break
					end
				end
			end
			placements[id], occupied[slot] = slot, true
		end
	end
	local data, issue = Schema.decode({ version = 1, cash = cash, assets = assets, placements = placements })
	assert(data, `Infinite profile snapshot rejected: {issue}`)
	return data
end

return table.freeze(Schema)
