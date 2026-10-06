--!strict

-- The inspected neutral footprint and primitive marker; no economy or scheduling.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rules = require(ReplicatedStorage.TycoonShared.SupplyRules)

local SupplyWorld = {}
export type World = { model: Model, cache: Part, label: TextLabel }

function SupplyWorld.inspect(): Vector3
	local spawn: SpawnLocation? = nil
	for _, instance in workspace:GetDescendants() do
		if instance:IsA("SpawnLocation") then
			assert(not spawn, "Supply Cache: expected one authored SpawnLocation")
			spawn = instance
		end
	end
	assert(spawn, "Supply Cache: missing authored SpawnLocation")
	local terrain = workspace.Terrain
	assert(terrain, "Supply Cache: placement requires Terrain")
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { terrain }
	local position = spawn.Position + Rules.Offset
	local high = -math.huge
	for x = -3, 3, 3 do
		for z = -3, 3, 3 do
			local hit = workspace:Raycast(
				Vector3.new(position.X + x, spawn.Position.Y + 100, position.Z + z),
				Vector3.new(0, -250, 0),
				params
			)
			assert(
				hit and hit.Material ~= Enum.Material.Water,
				"Supply Cache: footprint requires dry terrain ahead of spawn"
			)
			high = math.max(high, hit.Position.Y)
		end
	end
	local center = Vector3.new(position.X, high + 0.6, position.Z)
	for _, part in workspace:GetPartBoundsInBox(CFrame.new(center + Vector3.new(0, 3, 0)), Vector3.new(6, 7, 6)) do
		assert(not part.CanCollide, `Supply Cache: overlaps authored part {part:GetFullName()}`)
	end
	return center
end

local function block(parent: Instance, name: string, size: Vector3, position: Vector3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.Material = Enum.Material.SmoothPlastic
	part.Color = Color3.fromRGB(105, 114, 129)
	part.Parent = parent
	return part
end

function SupplyWorld.create(parent: Instance, center: Vector3): World
	assert(
		not parent:FindFirstChild(Rules.WorldName),
		`Supply Cache: reserved {parent:GetFullName()}/{Rules.WorldName} exists`
	)
	-- Inspect the actual purchase-pad geometry, rather than duplicating its offsets.
	for _, instance in parent:GetDescendants() do
		if instance:IsA("ProximityPrompt") then
			local part = instance.Parent
			assert(part and part:IsA("BasePart"), "Supply Cache: purchase prompt must have a part")
			assert(
				(part.Position - (center + Vector3.new(0, 2, 0))).Magnitude
					> Rules.Tuning.Radius + instance.MaxActivationDistance,
				`Supply Cache: claim range overlaps purchase prompt {instance:GetFullName()}`
			)
		end
	end
	local model = Instance.new("Model")
	model.Name = Rules.WorldName
	model.Archivable = false
	local floor = block(model, "Floor", Vector3.new(6, 1, 6), center)
	floor.Color = Color3.fromRGB(105, 114, 129)
	local cache = block(model, "Cache", Vector3.new(3, 2, 3), center + Vector3.new(0, 2, 0))
	local marker = Instance.new("BillboardGui")
	marker.Name = "SharedMarker"
	marker.Size = UDim2.fromOffset(230, 64)
	marker.StudsOffset = Vector3.new(0, 5, 0)
	marker.AlwaysOnTop = true
	marker.MaxDistance = 100
	marker.Parent = cache
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(24, 28, 36)
	label.BackgroundTransparency = 0.1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 16
	label.TextWrapped = true
	label.Parent = marker
	model.Parent = parent
	return { model = model, cache = cache, label = label }
end

function SupplyWorld.render(world: World, state: Rules.Snapshot)
	local hint = if state.phase == "open"
		then "CLAIM NOW"
		elseif state.phase == "warning" then "Opening soon"
		elseif state.phase == "result" then (if state.winnerName
			then `{state.winnerName} claimed it`
			else "Expired — nobody claimed")
		elseif state.phase == "idle" then "Waiting for a plot owner"
		else "Next opening scheduled"
	world.label.Text = `Shared Supply Cache • +{state.reward} cash\n{hint}`
	world.cache.Color = if state.phase == "open"
		then Color3.fromRGB(85, 225, 220)
		elseif state.phase == "warning" then Color3.fromRGB(255, 218, 91)
		elseif state.phase == "result" and state.winnerName then Color3.fromRGB(92, 232, 117)
		else Color3.fromRGB(130, 130, 140)
end

return SupplyWorld
