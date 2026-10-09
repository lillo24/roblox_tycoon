--!strict
local Shared = game:GetService("ReplicatedStorage").TycoonShared
local Models = require(Shared.Infinite.Models)
local Catalogue = require(Shared.Infinite.Catalogue)
local PlotWorld = require(script.Parent.PlotWorld)
local Schema = require(script.Parent.Persistence.ProfileSchema)
local World = {}
function World.prepare(plot: PlotWorld.Plot)
	plot.model:SetAttribute("InfiniteProperty", true)
	plot.model:SetAttribute("PropertyFrame", plot.frame)
	for _, pad in plot.pads do
		pad.prompt.Enabled = false
		pad.part:Destroy()
	end
	plot.pads = {}
end
function World.reconcile(plot: PlotWorld.Plot, data: Schema.Data)
	if plot.model:GetAttribute("PropertyRevision") == data.revision then
		return
	end
	plot.upgrades:ClearAllChildren()
	for id, object in data.objects do
		if not object.stored then
			local model = Models.create(
				object.content,
				data.theme,
				plot.frame * CFrame.new(object.x, 0, object.z) * CFrame.Angles(0, math.rad(90 * object.rotation), 0)
			)
			model.Name = id
			model:SetAttribute("Content", object.content)
			model.Parent = plot.upgrades
		end
	end
	local path = Instance.new("Part")
	path.Name, path.Size, path.CFrame = "VisitorPath", Vector3.new(9, 0.08, 59), plot.frame * CFrame.new(0, 0.04, -1)
	path.Anchored, path.CanCollide, path.CanTouch = true, false, false
	path.Color, path.Material, path.Parent = Catalogue.Colors[data.theme], Enum.Material.Pebble, plot.upgrades
	plot.model:SetAttribute("PropertyRevision", data.revision)
end
return World
