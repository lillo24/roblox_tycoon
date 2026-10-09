--!strict
-- Bounded anchored silhouettes, shared by accepted world objects and catalogue previews.
local Catalogue = require(script.Parent.Catalogue)
local Models = {}
function Models.create(content: string, theme: string, frame: CFrame): Model
	local definition = Catalogue.ById[content]
	assert(definition, "Unknown Infinite model")
	local model = Instance.new("Model")
	model.Name = content
	local color = Catalogue.Colors[theme] or Catalogue.Colors.Sage
	local wood, metal = Color3.fromRGB(163, 108, 72), Color3.fromRGB(58, 69, 70)
	local function block(name: string, size: Vector3, offset: CFrame, tint: Color3, solid: boolean?): Part
		local p = Instance.new("Part")
		p.Name, p.Size, p.CFrame, p.Color = name, size, frame * offset, tint
		p.Anchored, p.CanCollide, p.CanTouch = true, solid == true, false
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = model
		return p
	end
	local kind = definition.kind
	local function animate(part: Part, motion: string)
		part:SetAttribute("Activity", motion)
		part:SetAttribute("RestFrame", part.CFrame)
		part:SetAttribute("RestColor", part.Color)
	end
	local function ball(name: string, diameter: number, position: Vector3, tint: Color3): Part
		local p = block(name, Vector3.one * diameter, CFrame.new(position), tint)
		p.Shape = Enum.PartType.Ball
		return p
	end
	if kind == "wheel" then
		block("Plinth", Vector3.new(6, 2, 6), CFrame.new(0, 1, 0), wood, true)
		local disc = block(
			"TurningWheel",
			Vector3.new(0.4, 5, 5),
			CFrame.new(0, 2.4, 0) * CFrame.Angles(0, 0, math.pi / 2),
			metal
		)
		disc.Shape = Enum.PartType.Cylinder
		animate(disc, "spin")
		local bowl = ball("ClayBowl", 2.5, Vector3.new(0, 3.1, 0), color)
		animate(bowl, "pulse")
	elseif kind == "kiln" then
		block("Kiln", Vector3.new(8, 6, 7), CFrame.new(0, 3, 0), wood, true)
		local glow = block("FiringWindow", Vector3.new(5, 3, 0.2), CFrame.new(0, 3, -3.6), Color3.fromRGB(248, 147, 58))
		glow.Material = Enum.Material.Neon
		animate(glow, "pulse")
		block("Chimney", Vector3.new(2, 3, 2), CFrame.new(2, 7.5, 1), metal)
	elseif kind == "nursery" or kind == "greenhouse" or kind == "flowers" or kind == "trellis" then
		local width = definition.width - 1
		block("Bed", Vector3.new(width, 1.5, definition.depth - 1), CFrame.new(0, 0.75, 0), wood, true)
		for _, x in { -width / 3, 0, width / 3 } do
			block("Stem", Vector3.new(0.3, 2, 0.3), CFrame.new(x, 2, 0), color)
			local bloom = ball(
				"Bloom",
				1.5,
				Vector3.new(x, 3, 0),
				if kind == "flowers" then Color3.fromRGB(236, 191, 138) else color
			)
			animate(bloom, "bloom")
		end
		if kind == "greenhouse" then
			for _, x in { -4.5, 4.5 } do
				for _, z in { -4.5, 4.5 } do
					block("Post", Vector3.new(0.3, 7, 0.3), CFrame.new(x, 3.5, z), metal)
				end
				local glass =
					block("Glass", Vector3.new(0.15, 6, 9), CFrame.new(x, 3.5, 0), Color3.fromRGB(178, 230, 219))
				glass.Material, glass.Transparency = Enum.Material.Glass, 0.65
			end
			local roof = block("Canopy", Vector3.new(9.5, 0.4, 9.5), CFrame.new(0, 7, 0), color)
			roof.Material, roof.Transparency = Enum.Material.Glass, 0.35
		elseif kind == "trellis" then
			for _, x in { -2, 0, 2 } do
				block("Trellis", Vector3.new(0.3, 6, 0.3), CFrame.new(x, 3, 1.5), wood)
			end
			for _, y in { 2, 4, 6 } do
				block("Rail", Vector3.new(5, 0.3, 0.3), CFrame.new(0, y, 1.5), wood)
			end
		end
	elseif kind == "prism" then
		block("Base", Vector3.new(6, 3, 6), CFrame.new(0, 1.5, 0), metal, true)
		local crystal =
			block("Crystal", Vector3.new(2.5, 3, 2.5), CFrame.new(0, 5, 0) * CFrame.Angles(0.3, 0.4, 0.4), color)
		crystal.Material = Enum.Material.Neon
		animate(crystal, "spin")
	elseif kind == "telescope" then
		block("Pedestal", Vector3.new(3, 4, 3), CFrame.new(0, 2, 0), wood, true)
		local barrel = block("Lens", Vector3.new(8, 2, 2), CFrame.new(0, 5, 0) * CFrame.Angles(0, 0, 0.25), color)
		barrel.Shape = Enum.PartType.Cylinder
		animate(barrel, "scan")
	elseif kind == "orrery" then
		block("Base", Vector3.new(9, 1, 8), CFrame.new(0, 0.5, 0), metal, true)
		ball("Sun", 2.5, Vector3.new(0, 4, 0), Color3.fromRGB(255, 211, 119)).Material = Enum.Material.Neon
		for index = 1, 3 do
			local planet = ball("Planet", 0.8, Vector3.new(index, 4, 0), color)
			planet:SetAttribute("OrbitCenter", frame * CFrame.new(0, 4, 0))
			planet:SetAttribute("OrbitRadius", index)
			animate(planet, "orbit")
		end
	elseif kind == "pond" then
		block("Rim", Vector3.new(9, 0.8, 9), CFrame.new(0, 0.4, 0), wood, true)
		local water = block("Water", Vector3.new(8, 0.1, 8), CFrame.new(0, 0.85, 0), Color3.fromRGB(85, 163, 181))
		animate(water, "pulse")
		for _, x in { -2, 2 } do
			local leaf = block("Lily", Vector3.new(1.5, 0.15, 1.5), CFrame.new(x, 1, x), color)
			animate(leaf, "bloom")
		end
	elseif kind == "gallery" or kind == "vases" then
		block("Shelf", Vector3.new(definition.width - 1, 1, 3), CFrame.new(0, 2, 0), wood, true)
		for _, x in { -2, 0, 2 } do
			ball("Vase", 1.4, Vector3.new(x, 3.3, 0), if x == 0 then wood else color)
		end
		if kind == "gallery" then
			block("Backdrop", Vector3.new(9, 6, 0.5), CFrame.new(0, 3, 2), color)
			block("UpperShelf", Vector3.new(9, 0.4, 3), CFrame.new(0, 5, 0), wood)
			for _, x in { -3, 0, 3 } do
				ball("Vase", 1.4, Vector3.new(x, 6, 0), Color3.fromRGB(224, 188, 129))
			end
		end
	elseif kind == "moon" then
		block("Stand", Vector3.new(1, 4, 1), CFrame.new(0, 2, 0), wood, true)
		ball("Moon", 3, Vector3.new(0, 4.5, 0), Color3.fromRGB(240, 227, 180)).Material = Enum.Material.Neon
	elseif kind == "expansion" then
		for _, x in { -4, 4 } do
			block("Post", Vector3.new(1, 7, 1), CFrame.new(x, 3.5, 0), wood)
		end
		block("Arch", Vector3.new(9, 1, 1), CFrame.new(0, 7, 0), color)
	elseif kind == "plant" then
		block("Clay", Vector3.new(3, 2, 3), CFrame.new(0, 1, 0), wood, true)
		for _, x in { -0.8, 0.8 } do
			block("Fern", Vector3.new(1.5, 2.4, 2), CFrame.new(x, 3, 0) * CFrame.Angles(0, 0, x * 0.3), color)
		end
	elseif kind == "bench" then
		block("Seat", Vector3.new(7, 0.5, 3), CFrame.new(0, 2, 0), wood, true)
		block("Back", Vector3.new(7, 2, 0.5), CFrame.new(0, 3, 1.5), color, true)
		for _, x in { -2.5, 2.5 } do
			block("Leg", Vector3.new(0.5, 2, 2.5), CFrame.new(x, 1, 0), metal, true)
		end
	elseif kind == "lantern" then
		block("Post", Vector3.new(0.5, 4, 0.5), CFrame.new(0, 2, 0), metal, true)
		block("Glow", Vector3.new(1.5, 1.5, 1.5), CFrame.new(0, 4, 0), Color3.fromRGB(255, 205, 112)).Material =
			Enum.Material.Neon
		block("Cap", Vector3.new(2, 0.3, 2), CFrame.new(0, 5, 0), color)
	elseif kind == "mosaic" then
		block("Clay", Vector3.new(6, 0.2, 4), CFrame.new(0, 0.1, 0), wood)
		for _, x in { -2, 0, 2 } do
			block("Inlay", Vector3.new(1, 0.1, 3), CFrame.new(x, 0.25, 0), color)
		end
	else
		block("Base", Vector3.new(7, 0.5, 7), CFrame.new(0, 0.25, 0), metal, true)
		for _, x in { -2.8, 2.8 } do
			block("Leg", Vector3.new(0.5, 4, 4), CFrame.new(x, 2.5, 0), wood, true)
		end
		block("Table", Vector3.new(7, 0.6, 6), CFrame.new(0, 4, 0), color, true)
		if kind == "press" then
			block("Press", Vector3.new(4, 3, 3), CFrame.new(0, 6, 1), metal, true)
			block("Product", Vector3.new(2, 0.7, 2), CFrame.new(0, 4.7, -1), Color3.fromRGB(228, 164, 98))
		else
			block("Tools", Vector3.new(6, 3, 0.5), CFrame.new(0, 6, 2.5), wood)
			for _, x in { -2, 0, 2 } do
				block("Tool", Vector3.new(0.4, 2, 0.4), CFrame.new(x, 6, 2), metal)
			end
		end
	end
	if definition.income > 0 then
		local anchor = model:FindFirstChildWhichIsA("BasePart")
		if anchor then
			local sign = Instance.new("BillboardGui")
			sign.Name, sign.Size, sign.StudsOffset, sign.MaxDistance =
				"Production", UDim2.fromOffset(140, 36), Vector3.new(0, 6, 0), 38
			sign.AlwaysOnTop, sign.Parent = false, anchor
			local label = Instance.new("TextLabel")
			label.Size, label.BackgroundTransparency, label.TextWrapped = UDim2.fromScale(1, 1), 0.2, true
			label.BackgroundColor3, label.TextColor3, label.TextSize = metal, Color3.new(1, 1, 1), 12
			label.Text, label.Parent = definition.name .. "\n+" .. definition.income .. " / sec", sign
		end
	end
	return model
end
return Models
