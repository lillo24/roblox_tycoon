--!strict

local Shared = game:GetService("ReplicatedStorage").TycoonShared
local Config = require(Shared.Config)
local Catalogue = require(Shared.UpgradeCatalogue)
local MapLayout = require(script.Parent.MapLayout)

export type Pad = { part: Part, prompt: ProximityPrompt, label: TextLabel }
export type Plot = {
	model: Model,
	pads: { [Catalogue.Id]: Pad },
	upgrades: Folder,
	label: TextLabel,
	frame: CFrame,
	color: Color3,
}
local PlotWorld = {}
-- Local geometry only. World positions/orientation come exclusively from saved anchors.
local layouts: { [Catalogue.Id]: { pad: Vector3, machine: Vector3 } } = {
	income_booster = { pad = Vector3.new(-10, 0, -15), machine = Vector3.new(-18, 0, -10) },
	booster_tuning = { pad = Vector3.new(-10, 0, 0), machine = Vector3.new(-18, 0, 5) },
	workshop = { pad = Vector3.new(10, 0, -15), machine = Vector3.new(18, 0, -10) },
	workshop_expansion = { pad = Vector3.new(10, 0, 0), machine = Vector3.new(18, 0, 5) },
}

local function block(parent: Instance, name: string, size: Vector3, frame: CFrame, color: Color3, solid: boolean?): Part
	local part = Instance.new("Part")
	part.Name, part.Size, part.CFrame, part.Color = name, size, frame, color
	part.Anchored = true
	part.CanCollide = solid == true
	part.CanTouch = false
	part.Material = Enum.Material.Metal
	part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function surfaceLabel(part: Part, face: Enum.NormalId): TextLabel
	local surface = Instance.new("SurfaceGui")
	surface.Name, surface.Face = "Label", face
	surface.CanvasSize = Vector2.new(420, 220)
	surface.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(235, 242, 247)
	label.Font, label.TextSize, label.TextWrapped = Enum.Font.GothamBold, 30, true
	label.Parent = surface
	return label
end

-- Anchored equipment silhouettes; only the base/housing collide. No moving products.
local function machine(parent: Instance, name: string, frame: CFrame, color: Color3, extended: boolean): Model
	local model = Instance.new("Model")
	model.Name, model.Parent = name, parent
	local steel = Color3.fromRGB(49, 60, 68)
	local height = if extended then 6 else 4
	block(model, "Base", Vector3.new(7, 0.5, 7), frame * CFrame.new(0, 0.25, 0), steel, true)
	for _, x in { -2.6, 2.6 } do
		block(model, "Support", Vector3.new(0.6, height, 0.7), frame * CFrame.new(x, height / 2 + 0.5, 2.3), steel)
	end
	local housing = block(model, "Housing", Vector3.new(5, 2.6, 3.5), frame * CFrame.new(0, height, 1), steel, true)
	block(model, "Hopper", Vector3.new(5.6, 0.7, 4), frame * CFrame.new(0, height + 1.6, 1), color)
	block(
		model,
		"Output",
		Vector3.new(2.2, 1, 2),
		frame * CFrame.new(0, height - 0.5, -1.5),
		Color3.fromRGB(137, 148, 154)
	)
	block(model, "WorkStation", Vector3.new(4.5, 0.4, 2), frame * CFrame.new(0, 1.3, -2), steel)
	block(
		model,
		"StatusLight",
		Vector3.new(0.6, 0.4, 0.12),
		frame * CFrame.new(1.7, height + 0.6, -0.81),
		Color3.fromRGB(145, 217, 187)
	).Material =
		Enum.Material.Neon
	surfaceLabel(housing, Enum.NormalId.Front).Text = if name == "Generator"
		then "STARTER UNIT\n+1 / sec"
		else Catalogue.ById[name :: Catalogue.Id].DisplayName
	if extended then
		block(model, "ControlCabinet", Vector3.new(1.5, 3, 2), frame * CFrame.new(2.3, 2, -0.5), color)
		block(
			model,
			"UpperPipe",
			Vector3.new(0.7, 3, 0.7),
			frame * CFrame.new(-1.8, height + 1, 1.5),
			Color3.fromRGB(142, 155, 166)
		)
	end
	return model
end

function PlotWorld.inspect(): MapLayout.Layout
	assert(
		not workspace:FindFirstChild(Config.RuntimeName),
		`Tycoon: reserved Workspace/{Config.RuntimeName} already exists`
	)
	local layout = MapLayout.inspect()
	for id, lot in layout.lots do
		MapLayout.clear(
			lot.frame * CFrame.new(-19, 0, -25),
			Vector3.new(8, 10, 8),
			lot.foundation,
			`Lot{id} starter machine`
		)
		for upgradeId, slot in layouts do
			MapLayout.clear(
				lot.frame * CFrame.new(slot.machine),
				Vector3.new(8, 11, 8),
				lot.foundation,
				`Lot{id}/{upgradeId} equipment`
			)
			MapLayout.clear(
				lot.frame * CFrame.new(slot.pad),
				Vector3.new(5, 7, 5),
				lot.foundation,
				`Lot{id}/{upgradeId} interaction`
			)
			assert(
				(lot.frame:PointToWorldSpace(slot.pad) - layout.cache.Position).Magnitude > 10,
				`Lot{id}/{upgradeId} overlaps cache prompt range`
			)
		end
	end
	return layout
end

function PlotWorld.create(layout: MapLayout.Layout): { Plot }
	local folder = Instance.new("Folder")
	folder.Name, folder.Archivable = Config.RuntimeName, false
	local plots: { Plot } = {}
	for id, lot in layout.lots do
		local model = Instance.new("Model")
		model.Name = `Plot{id}`
		model:SetAttribute(Config.Attributes.PlotId, id)
		model.Parent = folder
		local upgrades = Instance.new("Folder")
		upgrades.Name, upgrades.Parent = "Upgrades", model
		machine(model, "Generator", lot.frame * CFrame.new(-19, 0, -25), lot.accent, false)
		local pads: { [Catalogue.Id]: Pad } = {}
		for _, definition in Catalogue.Definitions do
			local p = block(
				model,
				`Pad_{definition.Id}`,
				Vector3.new(4, 0.3, 3),
				lot.frame * CFrame.new(layouts[definition.Id].pad + Vector3.new(0, 0.15, 0)),
				Color3.fromRGB(90, 90, 90)
			)
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name, prompt.ObjectText = "Purchase", `{definition.DisplayName} (+{definition.IncomeDelta}/tick)`
			prompt.MaxActivationDistance = Config.PurchasePromptDistance
			prompt.RequiresLineOfSight, prompt.ClickablePrompt = false, true
			prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
			prompt.HoldDuration, prompt.Enabled, prompt.Parent = 0, false, p
			pads[definition.Id] = { part = p, prompt = prompt, label = surfaceLabel(p, Enum.NormalId.Top) }
		end
		local signPart =
			block(model, "OwnerPanel", Vector3.new(7, 2.5, 0.4), lot.frame * CFrame.new(23, 3, -30), lot.accent)
		local sign = Instance.new("BillboardGui")
		sign.Name, sign.Size = "Ownership", UDim2.fromOffset(130, 36)
		sign.StudsOffset = Vector3.new(0, 1.5, 0)
		-- Show nearby ownership without six large labels filling the plaza view.
		sign.AlwaysOnTop, sign.MaxDistance, sign.Parent = false, 90, signPart
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundColor3, label.BackgroundTransparency = Color3.fromRGB(24, 28, 36), 0.25
		label.TextColor3, label.Font, label.TextSize = Color3.new(1, 1, 1), Enum.Font.GothamBold, 12
		label.TextWrapped, label.Parent = true, sign
		plots[id] =
			{ model = model, pads = pads, upgrades = upgrades, label = label, frame = lot.frame, color = lot.accent }
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
			machine(
				plot.upgrades,
				id,
				plot.frame * CFrame.new(layouts[id].machine),
				plot.color,
				id == "booster_tuning" or id == "workshop_expansion"
			)
		elseif not purchased and visual then
			visual:Destroy()
		end
		plot.model:SetAttribute(Catalogue.purchaseAttribute(id), purchased)
		local pad = plot.pads[id]
		local availability = Catalogue.availability(definition, purchases, cash)
		local state = if owned then Catalogue.stateText(definition, purchases, cash) else "No owner"
		pad.label.Text = `{definition.DisplayName}\n{definition.Cost} cash • +{definition.IncomeDelta}/tick\n{state}`
		pad.prompt.ActionText = if availability == "affordable" then `Buy ({definition.Cost} cash)` else state
		pad.prompt.Enabled = owned and not purchased
		pad.part.Color = if not owned or availability == "locked"
			then Color3.fromRGB(86, 96, 105)
			elseif purchased then Color3.fromRGB(92, 186, 137)
			elseif availability == "affordable" then Color3.fromRGB(67, 158, 157)
			else Color3.fromRGB(192, 148, 62)
	end
end

function PlotWorld.setOwner(plot: Plot, player: Player?)
	plot.model:SetAttribute(Config.Attributes.OwnerUserId, if player then player.UserId else nil)
	plot.label.Text = `FACTORY {plot.model:GetAttribute(Config.Attributes.PlotId)}\n`
		.. (if player then player.DisplayName else "Available")
	PlotWorld.reconcile(plot, {}, 0)
end
return PlotWorld
