--!strict
local Legacy = require(script.Parent.LegacyProfile)
local Shared = game:GetService("ReplicatedStorage").TycoonShared
local Catalogue = require(Shared.Infinite.Catalogue)
local Placement = require(Shared.Infinite.Placement)
local SessionCatalogue = require(Shared.UpgradeCatalogue)
local Schema = {}
Schema.MaxCash, Schema.Slots, Schema.DefaultSlots = Legacy.MaxCash, Legacy.Slots, Legacy.DefaultSlots
export type Data = {
	version: number,
	cash: number,
	assets: SessionCatalogue.Purchases,
	placements: { [SessionCatalogue.Id]: string },
	objects: { [string]: Placement.Object },
	nextId: number,
	revision: number,
	theme: string,
}
export type Record = {
	version: number,
	data: Data,
	lease: { token: string, expiresAt: number }?,
	lastWrite: { token: string, sequence: number }?,
}
local positions = { west_front = { -18, -10 }, east_front = { 18, -10 }, west_back = { -18, 5 }, east_back = { 18, 5 } }
local function integer(value: any, maximum: number): boolean
	return typeof(value) == "number" and value >= 0 and value <= maximum and value % 1 == 0
end
local function fields(value: any, allowed: { string }): boolean
	if typeof(value) ~= "table" then
		return false
	end
	for key in value do
		if not table.find(allowed, key) then
			return false
		end
	end
	return true
end
local function migrated(old: Legacy.Data): Data
	local objects: { [string]: Placement.Object } = {}
	for id, slot in old.placements do
		local p = positions[slot]
		objects["legacy_" .. id] = { content = id, x = p[1], z = p[2], rotation = 0, stored = false }
	end
	return {
		version = 2,
		cash = old.cash,
		assets = old.assets,
		placements = old.placements,
		objects = objects,
		nextId = 1,
		revision = 0,
		theme = "Sage",
	}
end
function Schema.decode(value: any): (Data?, string?)
	if typeof(value) ~= "table" then
		return nil, "unsupported profile schema"
	end
	if value.version == 1 then
		local old, issue = Legacy.decode(value)
		return if old then migrated(old) else nil, issue
	end
	if
		value.version ~= 2
		or not fields(value, { "version", "cash", "assets", "placements", "objects", "nextId", "revision", "theme" })
	then
		return nil, "unsupported profile schema"
	end
	local old, issue =
		Legacy.decode({ version = 1, cash = value.cash, assets = value.assets, placements = value.placements })
	if not old then
		return nil, issue
	end
	if
		not integer(value.nextId, 1000000)
		or value.nextId < 1
		or not integer(value.revision, Schema.MaxCash)
		or not table.find(Catalogue.Themes, value.theme)
		or typeof(value.objects) ~= "table"
	then
		return nil, "invalid property metadata"
	end
	local data = migrated(old)
	data.objects, data.nextId, data.revision, data.theme = {}, value.nextId, value.revision, value.theme
	local count, owned = 0, {} :: { [string]: number }
	for id, object in value.objects do
		if
			typeof(id) ~= "string"
			or #id > 40
			or not fields(object, { "content", "x", "z", "rotation", "stored" })
			or typeof(object.content) ~= "string"
			or not Catalogue.ById[object.content]
		then
			return nil, "unsupported property content"
		end
		local serial = tonumber(string.match(id, "^o(%d+)$"))
		local legacy = SessionCatalogue.ById[object.content]
		if legacy then
			if id ~= "legacy_" .. object.content or not data.assets[object.content :: SessionCatalogue.Id] then
				return nil, "legacy ownership mismatch"
			end
		elseif not serial or serial < 1 or serial >= data.nextId or id ~= "o" .. tostring(serial) then
			return nil, "invalid object identity"
		end
		local valid = Placement.valid({}, id, object, true)
		if not valid then
			return nil, "invalid object transform"
		end
		data.objects[id] =
			{ content = object.content, x = object.x, z = object.z, rotation = object.rotation, stored = object.stored }
		owned[object.content] = (owned[object.content] or 0) + 1
		count += 1
		if count > Catalogue.MaxObjects then
			return nil, "property object limit exceeded"
		end
	end
	for id in data.assets do
		if owned[id] ~= 1 then
			return nil, "legacy asset missing its object"
		end
	end
	for id, object in data.objects do
		local definition = Catalogue.ById[object.content]
		if
			definition.unique and owned[object.content] ~= 1
			or definition.requires and not owned[definition.requires]
		then
			return nil, "invalid property prerequisites or duplicates"
		end
		local valid = Placement.valid(data.objects, id, object, owned.rear_garden ~= nil)
		if not valid then
			return nil, "invalid occupied footprint"
		end
	end
	return data, nil
end
function Schema.new(): Data
	return migrated(Legacy.new())
end
function Schema.record(value: any): (Record?, string?)
	if typeof(value) ~= "table" then
		return nil, "unsupported record schema"
	end
	-- The lease/receipt envelope remains v1; old servers refuse v2 data safely.
	local envelope = table.clone(value)
	envelope.data = Legacy.new()
	local old, issue = Legacy.record(envelope)
	if not old then
		return nil, issue
	end
	local data, invalid = Schema.decode(value.data)
	if not data then
		return nil, invalid
	end
	return { version = 1, data = data, lease = old.lease, lastWrite = old.lastWrite }, nil
end
function Schema.capture(cash: number, assets: SessionCatalogue.Purchases, previous: Data): Data
	local legacy = Legacy.capture(cash, assets, previous)
	local nextData = table.clone(previous)
	nextData.cash, nextData.assets, nextData.placements = cash, legacy.assets, legacy.placements
	nextData.objects = table.clone(previous.objects)
	for id, slot in legacy.placements do
		local key = "legacy_" .. id
		if not nextData.objects[key] then
			local p = positions[slot]
			local object: Placement.Object = { content = id, x = p[1], z = p[2], rotation = 0, stored = false }
			if not Placement.valid(nextData.objects, key, object) then
				object.stored = true
			end
			nextData.objects[key] = object
		end
	end
	local data, issue = Schema.decode(nextData)
	assert(data, "Infinite profile snapshot rejected: " .. tostring(issue))
	return data
end
function Schema.income(data: Data): number
	local rate = 1
	for _, object in data.objects do
		rate += Catalogue.ById[object.content].income
	end
	return rate
end
return table.freeze(Schema)
