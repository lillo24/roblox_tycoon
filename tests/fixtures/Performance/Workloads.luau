--!strict
-- Explicit rich local fixtures, built through the same non-yielding transactions.
-- Never used to infer pacing, loaded after a service failure, or mapped by Rojo.
local Server = game:GetService("ServerScriptService").TycoonServer
local Shared = game:GetService("ReplicatedStorage").TycoonShared
local Schema = require(Server.Persistence.ProfileSchema)
local Edits = require(Server.PropertyEdits)
local Catalogue = require(Shared.Infinite.Catalogue)
local Placement = require(Shared.Infinite.Placement)
local Workloads = {}
function Workloads.make(kind: string, showcase: any): Schema.Data
	if kind == "Fresh" then
		return Schema.new()
	end
	if kind ~= "Dense" then
		return showcase.make(if kind == "Sky" then "Sky" else "Garden")
	end
	local data = Schema.new()
	data.cash = 100000 -- Explicit fixture funding; all ownership still uses transactions.
	local function apply(request: any)
		request.revision = data.revision
		local nextData, issue = Edits.apply(data, request)
		assert(nextData, "PERF01 fixture: " .. issue)
		data = nextData
	end
	for _, item in Catalogue.Definitions do
		if item.unique then
			apply({ action = "buy", content = item.id })
			for id, object in data.objects do
				if object.content == item.id and not item.fixed then
					apply({ action = "store", object = id })
					break
				end
			end
		end
	end
	for _ = 1, Catalogue.MaxDecorations do
		apply({ action = "buy", content = "lantern" })
	end
	local ids = {}
	for id, object in data.objects do
		if not Catalogue.ById[object.content].fixed then
			table.insert(ids, id)
		end
	end
	-- Deterministic greedy packing, not a claim of an optimal packing solution.
	table.sort(ids, function(a: string, b: string)
		local left, right = Catalogue.ById[data.objects[a].content], Catalogue.ById[data.objects[b].content]
		local la, ra = left.width * left.depth, right.width * right.depth
		return if la == ra then a < b else la > ra
	end)
	for _, id in ids do
		local placed = false
		for z = -18, 27 do
			for x = -24, 24 do
				local object = table.clone(data.objects[id])
				object.x, object.z, object.stored = x, z, false
				if Placement.valid(data.objects, id, object, true) then
					apply({ action = "place", object = id, x = x, z = z, rotation = 0 })
					placed = true
					break
				end
			end
			if placed then
				break
			end
		end
	end
	assert(Schema.decode(data), "Dense fixture must retain full schema validation")
	return data
end
return Workloads
