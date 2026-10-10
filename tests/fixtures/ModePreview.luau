--!strict
-- Unmapped Studio adapter: fake IDs only select local review intentions. It
-- never calls TeleportService, changes the server mode, or claims an arrival.
local Preview = {}
function Preview.new(role: string, scenario: string): any
	assert(game:GetService("RunService"):IsStudio(), "Mode preview is Studio-only")
	assert(table.find({ "Entry", "Prototype", "Infinite" }, role), "Unknown preview role")
	assert(
		table.find({ "LateFailure", "ImmediateFailure", "MissingDestination" }, scenario),
		"Unknown preview scenario"
	)
	local places = { Entry = 101, Prototype = 102, Infinite = 103 }
	local source = places[role]
	if scenario == "MissingDestination" then
		places.Infinite = 0
	end
	return {
		manifest = { Enabled = true, UniverseId = 100, Places = places },
		universe = 100,
		place = source,
		known = { [101] = true, [102] = true, [103] = true },
		adapter = {
			label = "Studio review • local memory only; open the destination review file to play it.",
			send = function(_player: Player, destination: number, _token: string, failed: (string) -> ())
				local name = if destination == 102 then "Session" elseif destination == 103 then "Infinite" else "Entry"
				print("MODE01 LOCAL route intent:", name, scenario)
				local message = "Local review requested "
					.. name
					.. ". Open mode-"
					.. string.lower(name)
					.. ".rbxlx. No teleport occurred."
				if scenario == "ImmediateFailure" then
					return false, message
				end
				task.delay(1, function()
					failed(message)
				end)
				return true, "Local adapter pending"
			end,
		},
	}
end
return Preview
