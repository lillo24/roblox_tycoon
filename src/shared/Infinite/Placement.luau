--!strict
-- Property-local footprints; one-stud coordinates, quarter turns, two-stud gaps.
local Catalogue = require(script.Parent.Catalogue)
local Placement = {}
export type Object = { content: string, x: number, z: number, rotation: number, stored: boolean }
local function integer(value: any, low: number, high: number): boolean
	return typeof(value) == "number" and value >= low and value <= high and value % 1 == 0
end
function Placement.size(object: Object): (number, number)
	local definition = Catalogue.ById[object.content]
	if object.rotation % 2 == 1 then
		return definition.depth, definition.width
	end
	return definition.width, definition.depth
end
function Placement.valid(
	objects: { [string]: Object },
	id: string,
	object: Object,
	expanded: boolean?
): (boolean, string)
	if
		not Catalogue.ById[object.content]
		or not integer(object.x, -25, 25)
		or not integer(object.z, -19, 28)
		or not integer(object.rotation, 0, 3)
		or typeof(object.stored) ~= "boolean"
	then
		return false, "Use whole grid positions and quarter turns"
	end
	if object.stored then
		return true, "Stored • equipment keeps earning"
	end
	local width, depth = Placement.size(object)
	local back = if expanded then 28 else 12
	if math.abs(object.x) + width / 2 > 25 or object.z - depth / 2 < -19 or object.z + depth / 2 > back then
		return false, "Keep the whole object inside the open garden"
	end
	if math.abs(object.x) - width / 2 < 5 then
		return false, "Keep the central visitor path clear"
	end
	for otherId, other in objects do
		if otherId ~= id and not other.stored then
			local w, d = Placement.size(other)
			if
				math.abs(other.x - object.x) < (w + width) / 2 + 2
				and math.abs(other.z - object.z) < (d + depth) / 2 + 2
			then
				return false, "Leave two studs between objects"
			end
		end
	end
	return true, "Ready to place • confirm to accept"
end
return table.freeze(Placement)
