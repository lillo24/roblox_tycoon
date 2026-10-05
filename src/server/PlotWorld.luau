--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.TycoonShared.Config)

export type Plot = {
	model: Model,
	pad: Part,
	prompt: ProximityPrompt,
	label: TextLabel,
	center: Vector3,
	color: Color3,
}

local PlotWorld = {}
local colors = {
	Color3.fromRGB(51, 127, 184),
	Color3.fromRGB(139, 88, 179),
	Color3.fromRGB(193, 113, 47),
	Color3.fromRGB(43, 146, 124),
}

local function block(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Anchored = true
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function centerAboveTerrain(spawn: SpawnLocation, offset: Vector3, plotId: number): Vector3
	local position = spawn.Position + offset
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	local terrain = workspace.Terrain
	assert(terrain, "Tycoon: plot placement requires Workspace Terrain")
	params.FilterDescendantsInstances = { terrain }
	local high = -math.huge
	-- Sample the floor's corners, edges, and center; never carve or move terrain.
	for x = -5, 5, 5 do
		for z = -5, 5, 5 do
			local hit = workspace:Raycast(
				Vector3.new(position.X + x, spawn.Position.Y + 100, position.Z + z),
				Vector3.new(0, -250, 0),
				params
			)
			assert(
				hit and hit.Material ~= Enum.Material.Water,
				`Tycoon: plot {plotId} needs dry terrain near the spawn`
			)
			high = math.max(high, hit.Position.Y)
		end
	end
	-- Floor bottom is 0.1 studs above the sampled terrain; all furniture stays in this box.
	local center = Vector3.new(position.X, high + 0.6, position.Z)
	for _, part in workspace:GetPartBoundsInBox(CFrame.new(center + Vector3.new(0, 5.5, 0)), Vector3.new(10, 12, 10)) do
		assert(
			not part.CanCollide,
			`Tycoon: plot {plotId} overlaps authored part {part:GetFullName()}; update PlotOffsets`
		)
	end
	return center
end

function PlotWorld.create(): { Plot }
	assert(
		not workspace:FindFirstChild(Config.RuntimeName),
		`Tycoon: reserved Workspace/{Config.RuntimeName} already exists`
	)
	assert(#Config.PlotOffsets == Config.PlotCount, "Tycoon: PlotOffsets must match PlotCount")
	local spawns: { SpawnLocation } = {}
	for _, instance in workspace:GetDescendants() do
		if instance:IsA("SpawnLocation") then
			table.insert(spawns, instance)
		end
	end
	assert(#spawns == 1, `Tycoon: expected one authored SpawnLocation, found {#spawns}`)
	local centers = {}
	for id, offset in Config.PlotOffsets do
		centers[id] = centerAboveTerrain(spawns[1], offset, id)
	end

	local folder = Instance.new("Folder")
	folder.Name = Config.RuntimeName
	folder.Archivable = false
	local plots: { Plot } = {}
	for id, center in centers do
		local model = Instance.new("Model")
		model.Name = `Plot{id}`
		model:SetAttribute(Config.Attributes.PlotId, id)
		model:SetAttribute(Config.Attributes.Purchased, false)
		model.Parent = folder
		local color = colors[(id - 1) % #colors + 1]
		block(model, "Floor", Vector3.new(10, 1, 10), center, color)
		local generator = block(model, "Generator", Vector3.new(3, 3, 3), center + Vector3.new(-2, 2, 1.5), color)
		local pad = block(
			model,
			"PurchasePad",
			Vector3.new(3, 0.4, 3),
			center + Vector3.new(0, 0.7, -3),
			Color3.fromRGB(90, 90, 90)
		)
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "BuyBooster"
		prompt.ActionText = `Buy (${Config.UpgradeCost} cash)`
		prompt.ObjectText = "Income Booster"
		prompt.MaxActivationDistance = Config.PromptDistance
		prompt.RequiresLineOfSight = false
		prompt.ClickablePrompt = true
		prompt.HoldDuration = 0
		prompt.Enabled = false
		prompt.Parent = pad
		local sign = Instance.new("BillboardGui")
		sign.Name = "Ownership"
		sign.Size = UDim2.fromOffset(180, 64)
		sign.StudsOffset = Vector3.new(2, 4, 0)
		sign.AlwaysOnTop = true
		sign.MaxDistance = 75
		sign.Parent = generator
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundColor3 = Color3.fromRGB(24, 28, 36)
		label.BackgroundTransparency = 0.15
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Font = Enum.Font.GothamBold
		label.TextSize = 16
		label.TextWrapped = true
		label.Text = `Plot {id}\nAvailable`
		label.Parent = sign
		plots[id] = { model = model, pad = pad, prompt = prompt, label = label, center = center, color = color }
	end
	folder.Parent = workspace
	return plots
end

function PlotWorld.setOwner(plot: Plot, player: Player?)
	local booster = plot.model:FindFirstChild("IncomeBooster")
	if booster then
		booster:Destroy()
	end
	plot.model:SetAttribute(Config.Attributes.OwnerUserId, if player then player.UserId else nil)
	plot.model:SetAttribute(Config.Attributes.Purchased, false)
	plot.label.Text = if player
		then `Plot {plot.model:GetAttribute(Config.Attributes.PlotId)}\n{player.DisplayName}`
		else `Plot {plot.model:GetAttribute(Config.Attributes.PlotId)}\nAvailable`
	plot.pad.Color = if player then Color3.fromRGB(242, 192, 73) else Color3.fromRGB(90, 90, 90)
	plot.prompt.Enabled = player ~= nil
end

function PlotWorld.applyUpgrade(plot: Plot)
	block(
		plot.model,
		"IncomeBooster",
		Vector3.new(3, 4, 3),
		plot.center + Vector3.new(2, 2.5, 1.5),
		Color3.fromRGB(92, 232, 117)
	)
	plot.model:SetAttribute(Config.Attributes.Purchased, true)
	plot.pad.Color = Color3.fromRGB(92, 232, 117)
	plot.prompt.Enabled = false
end

return PlotWorld
