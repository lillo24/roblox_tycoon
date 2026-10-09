--!strict
-- Non-yielding property transactions. Lifecycle/epoch/rate guards belong to the adapter.
local Shared = game:GetService("ReplicatedStorage").TycoonShared
local Catalogue = require(Shared.Infinite.Catalogue)
local Legacy = require(Shared.UpgradeCatalogue)
local Placement = require(Shared.Infinite.Placement)
local Schema = require(script.Parent.Persistence.ProfileSchema)
local Edits = {}
function Edits.apply(data: Schema.Data, request: any): (Schema.Data?, string)
	if typeof(request) ~= "table" or request.revision ~= data.revision then
		return nil, "Your place changed. Refresh and try again."
	end
	if data.revision >= Schema.MaxCash then
		return nil, "Property revision limit reached; existing belongings remain usable"
	end
	local nextData = Schema.decode(data)
	assert(nextData, "Property transaction received invalid authoritative data")
	local action = request.action
	if action == "buy" then
		if typeof(request.content) ~= "string" then
			return nil, "Choose a catalogue item"
		end
		local definition = Catalogue.ById[request.content]
		if not definition then
			return nil, "Unknown catalogue item"
		end
		local owned, count = {}, 0
		for _, object in data.objects do
			owned[object.content] = true
			count += 1
		end
		if count >= Catalogue.MaxObjects or data.nextId >= 1000000 then
			return nil, "48 belongings maximum. Arrange or store your existing objects."
		end
		if definition.unique and owned[definition.id] then
			return nil, "Already owned"
		end
		if definition.requires and not owned[definition.requires] then
			return nil, "First discover " .. Catalogue.ById[definition.requires].name
		end
		if data.cash < definition.cost then
			return nil, "Need " .. tostring(definition.cost - data.cash) .. " more cash"
		end
		nextData.cash -= definition.cost
		if Legacy.ById[definition.id] then
			nextData.assets[definition.id :: Legacy.Id] = true
			nextData = Schema.capture(nextData.cash, nextData.assets, nextData)
		else
			nextData.objects["o" .. tostring(data.nextId)] =
				{ content = definition.id, x = -18, z = -10, rotation = 0, stored = true }
			nextData.nextId += 1
		end
	elseif action == "place" or action == "store" then
		if typeof(request.object) ~= "string" or not data.objects[request.object] then
			return nil, "Choose one of your belongings"
		end
		local object = table.clone(data.objects[request.object])
		object.stored = action == "store"
		if action == "place" then
			object.x, object.z, object.rotation = request.x, request.z, request.rotation
		end
		local expanded = false
		for _, item in data.objects do
			if item.content == "rear_garden" then
				expanded = true
			end
		end
		local valid, issue = Placement.valid(data.objects, request.object, object, expanded)
		if not valid then
			return nil, issue
		end
		nextData.objects[request.object] = object
	elseif action == "theme" then
		if not table.find(Catalogue.Themes, request.theme) then
			return nil, "Choose an available palette"
		end
		nextData.theme = request.theme
	else
		return nil, "Unknown property action"
	end
	nextData.revision += 1
	local valid, issue = Schema.decode(nextData)
	assert(valid, "Property transaction invalid: " .. tostring(issue))
	return valid, "Accepted here • next checkpoint will save this change"
end
return Edits
