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
	-- Render metadata lives on these bounded instances, so setOwner(nil)'s normal
	-- destruction also clears it. Never cache a departing owner's data globally.
	local retained: { [Instance]: boolean } = {}
	local function render(id: string, content: string, frame: CFrame)
		local existing = plot.upgrades:FindFirstChild(id)
		if
			existing
			and (
				not existing:IsA("Model")
				or existing:GetAttribute("Content") ~= content
				or existing:GetAttribute("PlacementFrame") ~= frame
			)
		then
			existing:Destroy()
			existing = nil
		end
		local model: Model
		if existing and existing:IsA("Model") then
			model = existing
			if model:GetAttribute("PropertyTheme") ~= data.theme then
				Models.setTheme(model, data.theme)
			end
		else
			model = Models.create(content, data.theme, frame)
			model.Name = id
			model:SetAttribute("Content", content)
			model:SetAttribute("PlacementFrame", frame)
			model.Parent = plot.upgrades
		end
		model:SetAttribute("PropertyTheme", data.theme)
		retained[model] = true
	end
	local function part(name: string, alternate: string?): Part
		local existing = plot.upgrades:FindFirstChild(name)
			or (if alternate then plot.upgrades:FindFirstChild(alternate) else nil)
		if existing and not existing:IsA("Part") then
			existing:Destroy()
			existing = nil
		end
		local result = if existing and existing:IsA("Part") then existing else Instance.new("Part")
		result.Name = name
		retained[result] = true
		return result
	end
	local expanded = false
	for id, object in data.objects do
		if object.content == "rear_garden" then
			expanded = true
		end
		if not object.stored then
			render(
				id,
				object.content,
				plot.frame * CFrame.new(object.x, 0, object.z) * CFrame.Angles(0, math.rad(90 * object.rotation), 0)
			)
		end
	end
	local path = part("VisitorPath")
	path.Name, path.Size, path.CFrame = "VisitorPath", Vector3.new(9, 0.08, 59), plot.frame * CFrame.new(0, 0.04, -1)
	path.Anchored, path.CanCollide, path.CanTouch = true, false, false
	path.Color, path.Material, path.Parent = Catalogue.Colors[data.theme], Enum.Material.Pebble, plot.upgrades
	local rear =
		part(if expanded then "OpenGarden" else "FutureGarden", if expanded then "FutureGarden" else "OpenGarden")
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
		render("GardenArch", "rear_garden", plot.frame * CFrame.new(0, 0, 14))
	end
	for _, child in plot.upgrades:GetChildren() do
		if not retained[child] then
			child:Destroy()
		end
	end
	plot.model:SetAttribute("PropertyRevision", data.revision)
end
return World
