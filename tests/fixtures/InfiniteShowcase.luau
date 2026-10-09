--!strict
-- Unmapped, disposable development presets. They use production transactions/schema,
-- then enter through ProfileStore.load; never selected by a failed real load.
local Server = game:GetService("ServerScriptService").TycoonServer
local Schema = require(Server.Persistence.ProfileSchema)
local Edits = require(Server.PropertyEdits)
local Showcase = {}
function Showcase.make(kind: string): Schema.Data
	local data = Schema.new()
	data.cash = 10000 -- Explicit rich fixture, never pacing evidence.
	local function apply(request: any)
		request.revision = data.revision
		local changed, reason = Edits.apply(data, request)
		assert(changed, "Showcase: " .. reason)
		data = changed
	end
	local items = if kind == "Garden"
		then {
			"seed_table",
			"greenhouse",
			"clay_wheel",
			"kiln",
			"rear_garden",
			"pond",
			"bench",
			"planter",
			"flowerbed",
			"lantern",
		}
		else {
			"prism",
			"telescope",
			"clay_wheel",
			"kiln",
			"rear_garden",
			"orrery",
			"vases",
			"moon_lamp",
			"mosaic",
			"lantern",
		}
	local positions = {
		{ -18, -12 },
		{ 18, -12 },
		{ -18, 2 },
		{ 18, 2 },
		{ 0, 0 },
		{ -17, 21 },
		{ 17, 21 },
		{ -8, -12 },
		{ 8, 21 },
		{ 8, -12 },
	}
	for index, id in items do
		apply({ action = "buy", content = id })
		if id ~= "rear_garden" then
			apply({
				action = "place",
				object = "o" .. index,
				x = positions[index][1],
				z = positions[index][2],
				rotation = 0,
			})
		end
	end
	apply({ action = "theme", theme = if kind == "Garden" then "Sage" else "Midnight" })
	data.cash = 75
	return data
end
return Showcase
