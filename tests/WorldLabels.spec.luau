--!strict

local Client = game:GetService("StarterPlayer").StarterPlayerScripts.TycoonClient
local LabelTypes = require(Client.WorldLabels)
local Config = require(game:GetService("ReplicatedStorage").TycoonShared.Config)

return function(Labels: typeof(LabelTypes)): number
	assert(Labels == LabelTypes, "Label tests require the actual production adapter")
	local checks = 0
	local function check(condition: boolean, message: string)
		assert(condition, message)
		checks += 1
	end
	local root = Instance.new("Folder")
	root.Name = Config.RuntimeName
	local plot = Instance.new("Model")
	plot.Name = "Plot6"
	plot:SetAttribute(Config.Attributes.PlotId, 6)
	plot.Parent = root
	for _, ownerPart in { "Generator", "OwnerPanel" } do
		local part = Instance.new("Part")
		part.Name, part.Parent = ownerPart, plot
		local gui = Instance.new("BillboardGui")
		gui.Name, gui.Parent = "Ownership", part
		local label = Instance.new("TextLabel")
		label.Parent = gui
		check(Labels.kind(gui, root) == "ownership", `Known {ownerPart} ownership hierarchy`)
		check(Labels.kind(label, root) == "ownerText", "Known owner text")
		gui.Name = "SharedMarker"
		check(Labels.kind(gui, root) == nil and Labels.kind(label, root) == nil, "Shared marker excluded")
		part:Destroy()
	end
	local pad = Instance.new("Part")
	pad.Name, pad.Parent = "Pad_income_booster", plot
	for _, name in { "UpgradeLabel", "Label" } do
		local surface = Instance.new("SurfaceGui")
		surface.Name, surface.Parent = name, pad
		local label = Instance.new("TextLabel")
		label.Parent = surface
		check(Labels.kind(label, root) == "surfaceText", "Both known pad surface hierarchies")
		surface.Name = "Unrelated"
		check(Labels.kind(label, root) == nil, "Unknown GUI excluded")
		surface:Destroy()
	end
	pad.Name = "Decoration"
	local surface = Instance.new("SurfaceGui")
	surface.Name, surface.Parent = "Label", pad
	local label = Instance.new("TextLabel")
	label.Parent = surface
	check(Labels.kind(label, root) == nil, "Decoration excluded even with matching GUI name")
	local upgrades = Instance.new("Folder")
	upgrades.Name, upgrades.Parent = "Upgrades", plot
	local machine = Instance.new("Model")
	machine.Parent = upgrades
	pad.Parent = machine
	check(Labels.kind(label, root) == "surfaceText", "Nested MAP-01 machine surface")
	plot:SetAttribute(Config.Attributes.PlotId, nil)
	check(Labels.kind(label, root) == nil, "Matching names without plot identity excluded")
	root:Destroy()
	return checks
end
