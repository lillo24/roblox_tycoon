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
	if kind == "plant" then
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
	return model
end
return Models
