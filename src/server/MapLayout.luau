--!strict

-- Reads the authored map and validates it before gameplay writes any Instances.
local Config = require(game:GetService("ReplicatedStorage").TycoonShared.Config)
local MapLayout = {}
export type Lot = { frame: CFrame, foundation: Part, entrance: Part, accent: Color3 }
export type Layout = { root: Model, lots: { Lot }, cache: Part, plaza: Part, spawn: SpawnLocation }

local function unique(parent: Instance, name: string): Instance
	local matches = {}
	for _, child in parent:GetChildren() do
		if child.Name == name then
			table.insert(matches, child)
		end
	end
	assert(#matches == 1, `Factory hub: {parent:GetFullName()}/{name} expected once, found {#matches}`)
	return matches[1]
end

local function part(parent: Instance, name: string): Part
	local found = unique(parent, name)
	assert(found:IsA("Part") and found.Anchored, `Factory hub: {found:GetFullName()} must be an anchored Part`)
	return found
end

local function corners(lot: Lot): { Vector3 }
	local points: { Vector3 } = {}
	for _, offset in { Vector3.new(-1, 0, -1), Vector3.new(1, 0, -1), Vector3.new(1, 0, 1), Vector3.new(-1, 0, 1) } do
		local size = lot.foundation.Size
		local point = lot.frame:PointToWorldSpace(Vector3.new(offset.X * size.X / 2, 0, offset.Z * size.Z / 2))
		table.insert(points, point)
	end
	return points
end

local function pointSegment(p: Vector3, a: Vector3, b: Vector3): number
	local edge = b - a
	local t = math.clamp((p - a):Dot(edge) / edge:Dot(edge), 0, 1)
	return (p - (a + edge * t)).Magnitude
end

-- SAT catches intersecting oriented rectangles; segment distances measure the gap.
function MapLayout.gap(a: Lot, b: Lot): number
	local ac, bc = corners(a), corners(b)
	local separated = false
	for _, axis in { a.frame.RightVector, a.frame.LookVector, b.frame.RightVector, b.frame.LookVector } do
		local amin, amax, bmin, bmax = math.huge, -math.huge, math.huge, -math.huge
		for _, p in ac do
			amin = math.min(amin, p:Dot(axis))
			amax = math.max(amax, p:Dot(axis))
		end
		for _, p in bc do
			bmin = math.min(bmin, p:Dot(axis))
			bmax = math.max(bmax, p:Dot(axis))
		end
		if amax < bmin or bmax < amin then
			separated = true
		end
	end
	if not separated then
		return 0
	end
	local minimum = math.huge
	for i = 1, 4 do
		for j = 1, 4 do
			minimum =
				math.min(minimum, pointSegment(ac[i], bc[j], bc[j % 4 + 1]), pointSegment(bc[i], ac[j], ac[j % 4 + 1]))
		end
	end
	return minimum
end

-- Support rays include exactly the intended support. Clearance considers every
-- collidable authored part except that support, never an entire map exclusion.
function MapLayout.clear(frame: CFrame, size: Vector3, support: Part, context: string)
	local ray = RaycastParams.new()
	ray.FilterType = Enum.RaycastFilterType.Include
	ray.FilterDescendantsInstances = { support }
	for x = -1, 1 do
		for z = -1, 1 do
			local p = frame:PointToWorldSpace(Vector3.new(x * size.X / 2, 0, z * size.Z / 2))
			local hit = workspace:Raycast(p + Vector3.new(0, 10, 0), Vector3.new(0, -12, 0), ray)
			assert(
				hit and math.abs(hit.Position.Y - frame.Position.Y) < 0.05,
				`Factory hub: {context} lacks level support on {support:GetFullName()}`
			)
		end
	end
	for _, obstacle in workspace:GetPartBoundsInBox(frame * CFrame.new(0, size.Y / 2 + 0.05, 0), size) do
		assert(
			obstacle == support or not obstacle.CanCollide,
			`Factory hub: {context} blocked by {obstacle:GetFullName()}`
		)
	end
end

function MapLayout.inspect(): Layout
	local root = unique(workspace, Config.MapName)
	assert(root:IsA("Model"), "Factory hub: root must be a Model")
	local lotsFolder = unique(root, "Lots")
	assert(#lotsFolder:GetChildren() == Config.PlotCount, `Factory hub: expected {Config.PlotCount} authored lots`)
	local plaza = part(root, "Plaza")
	local cache = part(root, "CacheAnchor")
	assert(
		not cache.CanCollide and cache.Transparency == 1,
		"Factory hub: CacheAnchor must be invisible and noncolliding"
	)
	local spawns: { SpawnLocation } = {}
	for _, i in workspace:GetDescendants() do
		if i:IsA("SpawnLocation") then
			table.insert(spawns, i)
		end
	end
	assert(#spawns == 1 and spawns[1]:IsDescendantOf(root), "Factory hub: expected one hub SpawnLocation")
	local spawn = spawns[1]
	assert((spawn.Position - cache.Position).Magnitude > 10, "Factory hub: spawn overlaps cache approach")
	MapLayout.clear(cache.CFrame, Vector3.new(6, 7, 6), plaza, "cache approach")
	local lots: { Lot } = {}
	for id = 1, Config.PlotCount do
		local model = unique(lotsFolder, `Lot{id}`)
		assert(model:IsA("Model") and model:GetAttribute("LotId") == id, `Factory hub: Lot{id} has wrong stable LotId`)
		local foundation, anchor, entrance = part(model, "Foundation"), part(model, "Anchor"), part(model, "Entrance")
		assert(
			not anchor.CanCollide
				and anchor.Transparency == 1
				and not entrance.CanCollide
				and entrance.Transparency == 1,
			`Factory hub: Lot{id} anchors must be invisible/noncolliding`
		)
		local frame = anchor.CFrame
		assert(
			math.abs(frame.UpVector.Y - 1) < 0.001 and foundation.CanCollide,
			`Factory hub: Lot{id} must be upright and supported`
		)
		local top = foundation.CFrame * CFrame.new(0, foundation.Size.Y / 2, 0)
		assert(
			(top.Position - frame.Position).Magnitude < 0.01 and top.LookVector:Dot(frame.LookVector) > 0.999,
			`Factory hub: Lot{id} Anchor must match foundation top frame`
		)
		local inward = Vector3.new(cache.Position.X - frame.Position.X, 0, cache.Position.Z - frame.Position.Z).Unit
		assert(frame.LookVector:Dot(inward) > 0.999, `Factory hub: Lot{id} local -Z front must face the cache`)
		assert(
			(entrance.Position - frame:PointToWorldSpace(Vector3.new(0, 0, -foundation.Size.Z / 2))).Magnitude < 0.01,
			`Factory hub: Lot{id} Entrance must mark front midpoint`
		)
		assert(
			foundation.Size.X >= 40 and foundation.Size.Z >= 50,
			`Factory hub: Lot{id} foundation too small for production zones`
		)
		if id > 1 then
			assert(
				(foundation.Size - lots[1].foundation.Size).Magnitude < 0.01,
				"Factory hub: unequal foundation sizes"
			)
		end
		local accent = model:GetAttribute("Accent")
		assert(typeof(accent) == "Color3", `Factory hub: Lot{id} requires a Color3 Accent`)
		lots[id] = { frame = frame, foundation = foundation, entrance = entrance, accent = accent }
		MapLayout.clear(entrance.CFrame * CFrame.new(0, 0, 3), Vector3.new(10, 7, 5), foundation, `Lot{id} entrance`)
	end
	for i = 1, #lots do
		for j = i + 1, #lots do
			assert(
				MapLayout.gap(lots[i], lots[j]) > 1,
				`Factory hub: Lot{i}/Lot{j} footprints intersect or have no clearance`
			)
		end
	end
	return { root = root, lots = lots, cache = cache, plaza = plaza, spawn = spawn }
end

return MapLayout
