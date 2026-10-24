--!strict
-- Actual Instance identities and colors, separate from timed client workloads.
local Server = game:GetService("ServerScriptService").TycoonServer
local Shared = game:GetService("ReplicatedStorage").TycoonShared
local World = require(Server.PropertyWorld)
local PlotWorld = require(Server.PlotWorld)
local Schema = require(Server.Persistence.ProfileSchema)
local Edits = require(Server.PropertyEdits)
local Models = require(Shared.Infinite.Models)
local Catalogue = require(Shared.Infinite.Catalogue)
return function(): number
	local checks = 0
	local function check(value: boolean, message: string)
		assert(value, "PERF01 rendering: " .. message)
		checks += 1
	end
	local root, upgrades, label = Instance.new("Model"), Instance.new("Folder"), Instance.new("TextLabel")
	upgrades.Parent, label.Parent = root, root
	local plot: PlotWorld.Plot = {
		model = root,
		upgrades = upgrades,
		label = label,
		frame = CFrame.new(17, 0, -20) * CFrame.Angles(0, 0.7, 0),
		color = Color3.new(1, 1, 1),
		pads = {},
	}
	World.prepare(plot)
	local data = Schema.new()
	data.cash = 100000
	World.reconcile(plot, data)
	local function child(name: string): Instance
		local found = upgrades:FindFirstChild(name)
		assert(found, "Rendered child missing: " .. name)
		return found
	end
	local path, rear = child("VisitorPath"), child("FutureGarden")
	local function edit(request: any)
		request.revision = data.revision
		local updated, issue = Edits.apply(data, request)
		assert(updated, issue)
		data = updated
		World.reconcile(plot, data)
	end
	edit({ action = "buy", content = "seed_table" })
	check(#upgrades:GetChildren() == 2 and child("VisitorPath") == path, "stored purchase creates no geometry")
	edit({ action = "place", object = "o1", x = -15, z = -10, rotation = 0 })
	local nursery = child("o1")
	edit({ action = "buy", content = "lantern" })
	edit({ action = "place", object = "o2", x = 15, z = -10, rotation = 0 })
	local lantern = child("o2")
	check(child("o1") == nursery and child("FutureGarden") == rear, "other placement preserves existing geometry")
	edit({ action = "place", object = "o1", x = -15, z = 0, rotation = 1 })
	check(nursery.Parent == nil and child("o2") == lantern, "move replaces only the changed model")
	local moved = child("o1")
	local bloom = moved:FindFirstChild("Bloom") :: Part
	check(
		(bloom:GetAttribute("RestFrame") :: CFrame).Position == bloom.Position,
		"replacement activity uses new world frame"
	)
	edit({ action = "theme", theme = "Midnight" })
	check(
		child("o1") == moved and child("o2") == lantern and child("VisitorPath") == path,
		"theme preserves instance identities"
	)
	check(
		bloom.Color == Catalogue.Colors.Midnight and bloom:GetAttribute("RestColor") == bloom.Color,
		"theme updates animated resting color"
	)
	edit({ action = "store", object = "o1" })
	check(moved.Parent == nil and child("o2") == lantern, "storage removes only selected geometry")
	edit({ action = "place", object = "o1", x = -15, z = -10, rotation = 0 })
	check(child("o1") ~= moved and child("o2") == lantern, "re-place creates one fresh model")
	edit({ action = "buy", content = "rear_garden" })
	check(
		child("OpenGarden") == rear and upgrades:FindFirstChild("GardenArch") ~= nil,
		"expansion reuses ground and adds arch"
	)
	PlotWorld.setOwner(plot, nil)
	check(
		#upgrades:GetChildren() == 0 and root:GetAttribute("PropertyRevision") == nil,
		"departure clears geometry and render metadata"
	)
	World.reconcile(plot, Schema.new())
	check(
		#upgrades:GetChildren() == 2 and upgrades:FindFirstChild("o1") == nil,
		"new owner at revision zero inherits no old objects"
	)
	root:Destroy()
	-- Every recolored silhouette must match a freshly created target palette,
	-- including fixed colors, duplicate part names and cosmetic activity metadata.
	for _, definition in Catalogue.Definitions do
		local model = Models.create(definition.id, "Sage", CFrame.new())
		local parts = model:GetChildren()
		for _, theme in Catalogue.Themes do
			Models.setTheme(model, theme)
			local expected = Models.create(definition.id, theme, CFrame.new())
			local expectedParts = expected:GetChildren()
			for index, part in parts do
				local target = expectedParts[index]
				assert(part:IsA("BasePart") and target:IsA("BasePart"), "Silhouette children must be parts")
				check(part == model:GetChildren()[index], "recolor never replaces parts")
				check(
					part.Color == target.Color and part:GetAttribute("RestColor") == target:GetAttribute("RestColor"),
					"recolor matches fresh target palette: " .. definition.id
				)
			end
			expected:Destroy()
		end
		model:Destroy()
	end
	return checks
end
