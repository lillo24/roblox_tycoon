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
	local expanded = false
	for id, object in data.objects do
		if object.content == "rear_garden" then
			expanded = true
		end
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
	local rear = Instance.new("Part")
	rear.Name, rear.Size, rear.CFrame =
		if expanded then "OpenGarden" else "FutureGarden",
		Vector3.new(50, 0.06, 16),
		plot.frame * CFrame.new(0, 0.03, 20)
	rear.Anchored, rear.CanCollide, rear.CanTouch = true, false, false
	rear.Color, rear.Material, rear.Parent =
		if expanded then Color3.fromRGB(181, 156, 118) else Color3.fromRGB(73, 90, 67),
		Enum.Material.WoodPlanks,
		plot.upgrades
	if expanded then
		local arch = Models.create("rear_garden", data.theme, plot.frame * CFrame.new(0, 0, 14))
		arch.Name, arch.Parent = "GardenArch", plot.upgrades
	end
	plot.model:SetAttribute("PropertyRevision", data.revision)
end
return World
