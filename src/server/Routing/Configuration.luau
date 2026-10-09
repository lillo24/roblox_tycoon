--!strict
local Configuration = {}
export type Manifest = { Enabled: boolean, UniverseId: number, Places: { [string]: number } }
export type Resolved = { role: string, places: { [string]: number }, enabled: boolean, issue: string? }
local function positive(value: any): boolean
	return typeof(value) == "number" and value > 0 and value < 9007199254740992 and value % 1 == 0
end
-- knownPlaces comes only from AssetService (or an explicit Studio test adapter).
function Configuration.resolve(
	manifest: Manifest,
	universeId: number,
	placeId: number,
	studioRole: string?,
	knownPlaces: { [number]: boolean }?
): Resolved
	local function invalid(issue: string): Resolved
		return { role = "Unavailable", places = {}, enabled = false, issue = issue }
	end
	if not manifest.Enabled then
		local role = studioRole or "Prototype"
		if not table.find({ "Entry", "Prototype", "Infinite" }, role) then
			return invalid("Invalid Studio role")
		end
		return {
			role = role,
			places = {},
			enabled = false,
			issue = "Mode destinations are not configured for this build.",
		}
	end
	if not positive(manifest.UniverseId) or manifest.UniverseId ~= universeId then
		return invalid("Routing universe does not match this experience")
	end
	local used: { [number]: boolean } = {}
	local role: string? = nil
	for _, name in { "Entry", "Prototype", "Infinite" } do
		local id = manifest.Places[name]
		if not positive(id) then
			return invalid("Missing or invalid " .. name .. " destination")
		end
		if used[id] then
			return invalid("Place roles must have distinct IDs; self-routing refused")
		end
		if not knownPlaces or not knownPlaces[id] then
			return invalid(name .. " destination is not confirmed in this experience")
		end
		used[id] = true
		if id == placeId then
			role = name
		end
	end
	if not role or studioRole and studioRole ~= role then
		return invalid("This place does not match its configured role")
	end
	return { role = role, places = table.clone(manifest.Places), enabled = true }
end
return Configuration
