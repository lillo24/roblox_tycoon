--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.TycoonShared.Config)
local Catalogue = require(ReplicatedStorage.TycoonShared.UpgradeCatalogue)

export type Pad = { part: Part, prompt: ProximityPrompt, label: TextLabel }
export type Plot = {
	model: Model,
	pads: { [Catalogue.Id]: Pad },
	upgrades: Folder,
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

-- Geometry only: costs, effects, prerequisites, and state text come from the catalogue.
local layouts: { [Catalogue.Id]: { pad: Vector3, visual: Vector3, size: Vector3, color: Color3 } } = {
	income_booster = {
		pad = Vector3.new(-2.8, 0.7, -3),
		visual = Vector3.new(-2.8, 2, 2.6),
		size = Vector3.new(2.2, 3, 2.2),
		color = Color3.fromRGB(92, 232, 117),
	},
	workshop = {
		pad = Vector3.new(2.8, 0.7, -3),
		visual = Vector3.new(2.8, 2, 2.6),
		size = Vector3.new(2.2, 3, 2.2),
		color = Color3.fromRGB(94, 173, 255),
	},
	booster_tuning = {
		pad = Vector3.new(-2.8, 0.7, 0),
		visual = Vector3.new(-2.8, 4.2, 2.6),
		size = Vector3.new(1.6, 1.4, 1.6),
		color = Color3.fromRGB(244, 222, 85),
	},
	workshop_expansion = {
		pad = Vector3.new(2.8, 0.7, 0),
		visual = Vector3.new(2.8, 4.5, 2.6),
		size = Vector3.new(2.8, 2, 2.8),
		color = Color3.fromRGB(197, 126, 255),
	},
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

local function surfaceLabel(part: Part, face: Enum.NormalId): TextLabel
	local surface = Instance.new("SurfaceGui")
	surface.Name = "UpgradeLabel"
	surface.Face = face
	surface.CanvasSize = Vector2.new(260, 160)
	surface.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(15, 20, 28)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 25
	label.TextWrapped = true
	label.Parent = surface
	return label
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
		model.Parent = folder
		local upgrades = Instance.new("Folder")
		upgrades.Name = "Upgrades"
		upgrades.Parent = model
		local color = colors[(id - 1) % #colors + 1]
		block(model, "Floor", Vector3.new(10, 1, 10), center, color)
		local generator = block(model, "Generator", Vector3.new(1.4, 2, 1.4), center + Vector3.new(0, 1.5, 2.6), color)
		local pads: { [Catalogue.Id]: Pad } = {}
		for _, definition in Catalogue.Definitions do
			local part = block(
				model,
				`Pad_{definition.Id}`,
				Vector3.new(2.2, 0.4, 1.8),
				center + layouts[definition.Id].pad,
				Color3.fromRGB(90, 90, 90)
			)
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "Purchase"
			prompt.ObjectText = `{definition.DisplayName} (+{definition.IncomeDelta}/tick)`
			prompt.MaxActivationDistance = Config.PurchasePromptDistance
			prompt.RequiresLineOfSight = false
			prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
			prompt.ClickablePrompt = true
			prompt.HoldDuration = 0
			prompt.Enabled = false
			prompt.Parent = part
			pads[definition.Id] = { part = part, prompt = prompt, label = surfaceLabel(part, Enum.NormalId.Top) }
		end
		local sign = Instance.new("BillboardGui")
		sign.Name = "Ownership"
		sign.Size = UDim2.fromOffset(180, 64)
		sign.StudsOffset = Vector3.new(0, 6.5, 0)
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
		plots[id] = { model = model, pads = pads, upgrades = upgrades, label = label, center = center, color = color }
		PlotWorld.setOwner(plots[id], nil)
	end
	folder.Parent = workspace
	return plots
end

function PlotWorld.reconcile(plot: Plot, purchases: Catalogue.Purchases, cash: number)
	local owned = plot.model:GetAttribute(Config.Attributes.OwnerUserId) ~= nil
	for _, definition in Catalogue.Definitions do
		local id = definition.Id
		local purchased = purchases[id] == true
		local visual = plot.upgrades:FindFirstChild(id)
		if purchased and not visual then
			local layout = layouts[id]
			local part = block(plot.upgrades, id, layout.size, plot.center + layout.visual, layout.color)
			surfaceLabel(part, Enum.NormalId.Front).Text = definition.DisplayName
		elseif not purchased and visual then
			visual:Destroy()
		end
		plot.model:SetAttribute(Catalogue.purchaseAttribute(id), purchased)
		local pad = plot.pads[id]
		local availability = Catalogue.availability(definition, purchases, cash)
		local state = if owned then Catalogue.stateText(definition, purchases, cash) else "No owner"
		pad.label.Text = `{definition.DisplayName}\n{definition.Cost} cash • +{definition.IncomeDelta}/tick\n{state}`
		pad.prompt.ActionText = if availability == "affordable" then `Buy ({definition.Cost} cash)` else state
		-- Locked/unaffordable prompts remain usable, so the server can explain rejection.
		pad.prompt.Enabled = owned and not purchased
		pad.part.Color = if not owned or availability == "locked"
			then Color3.fromRGB(130, 130, 140)
			elseif purchased then Color3.fromRGB(92, 232, 117)
			elseif availability == "affordable" then Color3.fromRGB(95, 220, 218)
			else Color3.fromRGB(242, 192, 73)
	end
end

function PlotWorld.setOwner(plot: Plot, player: Player?)
	plot.model:SetAttribute(Config.Attributes.OwnerUserId, if player then player.UserId else nil)
	plot.label.Text = if player
		then `Plot {plot.model:GetAttribute(Config.Attributes.PlotId)}\n{player.DisplayName}`
		else `Plot {plot.model:GetAttribute(Config.Attributes.PlotId)}\nAvailable`
	PlotWorld.reconcile(plot, {}, 0)
end

return PlotWorld
