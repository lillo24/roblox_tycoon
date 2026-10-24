--!strict
local Server = game:GetService("ServerScriptService").TycoonServer
local Shared = game:GetService("ReplicatedStorage").TycoonShared
local Schema = require(Server.Persistence.ProfileSchema)
local Store = require(Server.Persistence.ProfileStore)
local Profiles = require(Server.Persistence.Profiles)
local Session = require(Server.Session)
local Edits = require(Server.PropertyEdits)
local World = require(Server.PropertyWorld)
local PlotWorld = require(Server.PlotWorld)
local Content = require(Shared.Infinite.Catalogue)
local Legacy = require(Shared.UpgradeCatalogue)
return function(Memory: any, Showcase: any): number
	local count = 0
	local function check(condition: boolean, message: string)
		assert(condition, "INF03: " .. message)
		count += 1
	end
	check(#Content.Definitions == 22 and #Legacy.Definitions == 4, "finite Infinite catalogue, unchanged Session scope")
	local v2 = Schema.new()
	v2.version = 2
	v2.cash = 42
	local migrated = Schema.decode(v2)
	check(migrated ~= nil and migrated.version == 3 and migrated.cash == 42, "v2→v3 preserves values")
	check(Schema.decode({ version = 4 }) == nil, "newer saves refused")
	local capacity = Schema.new()
	capacity.cash = 100000
	for _ = 1, 48 do
		local changed = Edits.apply(capacity, { action = "buy", content = "lantern", revision = capacity.revision })
		assert(changed, "decoration setup")
		capacity = changed
	end
	check(
		Edits.apply(capacity, { action = "buy", content = "planter", revision = capacity.revision }) == nil,
		"decorations cannot consume progression reserve"
	)
	for _, item in Content.Definitions do
		if item.unique then
			local changed = Edits.apply(capacity, { action = "buy", content = item.id, revision = capacity.revision })
			assert(changed, "all progression remains buyable: " .. item.id)
			capacity = changed
		end
	end
	check(
		Schema.income(capacity) == 57,
		"trusted ownership income includes all paths, without offline/placement bonuses"
	)
	check(#game:GetService("HttpService"):JSONEncode(capacity) < 16384, "developed inventory remains below 16 KiB")
	check(
		Edits.apply(capacity, { action = "buy", content = "prism", revision = capacity.revision }) == nil,
		"unique discoveries cannot duplicate"
	)
	local retired = Content.ById.lantern
	retired.retired = true
	local preserved = Schema.decode(capacity)
	local rejected = Edits.apply(capacity, { action = "buy", content = "lantern", revision = capacity.revision })
	retired.retired = nil
	check(preserved ~= nil and rejected == nil, "retired definition retains owned objects while ending new sales")
	local fresh = Schema.new()
	local seconds = 0
	for index, id in { "seed_table", "greenhouse", "rear_garden", "pond" } do
		while fresh.cash < Content.ById[id].cost do
			seconds += 1
			fresh.cash += Schema.income(fresh)
		end
		local changed = Edits.apply(fresh, { action = "buy", content = id, revision = fresh.revision })
		assert(changed, "fresh path purchase")
		fresh = changed
		print("INF03 PACING simulated ordinary online seconds", seconds, id)
		check(seconds <= ({ 12, 42, 70, 126 })[index], "early choice/milestone without rich preset")
	end
	check(
		Edits.apply(
			fresh,
			{ action = "place", revision = fresh.revision, object = "o3", x = -18, z = 20, rotation = 0 }
		) == nil,
		"fixed expansion cannot be moved or stored"
	)
	local memory = Memory.new()
	local clock, token = 1000, 0
	local store = Store.new(memory.update, {
		update = memory.update,
		now = function()
			return clock
		end,
		wait = function(n)
			clock += n
		end,
		jitter = function()
			return 0
		end,
		token = function()
			token += 1
			return "growth-" .. token
		end,
	})
	local session = Session.new({ PlotCount = 6, StartingCash = 0, BaseIncome = 1 }, Legacy.Definitions)
	local profiles = Profiles.new(session, store, function() end, function(work)
		work()
	end)
	local root = Instance.new("Folder")
	root.Name, root.Parent = "INF03DevelopedFixture", workspace
	local started = os.clock()
	for user = 1, 6 do
		local data = Showcase.make(if user % 2 == 0 then "Sky" else "Garden")
		memory.values["user_" .. user] = { version = 1, data = data }
		profiles:join(user)
		local view = profiles:read(user)
		check(
			view.available and view.data.objects.o6.z == 21,
			"developed profile restores expanded layout through Store"
		)
		local state = session:get(user)
		assert(state, "developed profile ready")
		check(state.incomeRate == Schema.income(data) and state.cash == 75, "restoration derives exact trusted income")
		local model, upgrades, label = Instance.new("Model"), Instance.new("Folder"), Instance.new("TextLabel")
		model.Parent, upgrades.Parent, label.Parent = root, model, model
		local hub = workspace:FindFirstChild("FactoryHub") :: Model
		local lots = hub:FindFirstChild("Lots") :: Folder
		local lot = lots:FindFirstChild("Lot" .. user) :: Model
		local frame = (lot:FindFirstChild("Anchor") :: Part).CFrame
		local plot: PlotWorld.Plot =
			{ model = model, upgrades = upgrades, label = label, frame = frame, color = Color3.new(1, 1, 1), pads = {} }
		World.prepare(plot)
		World.reconcile(plot, view.data)
		check(
			upgrades:FindFirstChild("OpenGarden") ~= nil and upgrades:FindFirstChild("o6") ~= nil,
			"expansion and continuing original ownership render"
		)
		profiles:leave(user)
		check(
			memory.values["user_" .. user].lease == nil and memory.values["user_" .. user].data.objects.o6.z == 21,
			"developed checkpoint releases and preserves arrangement"
		)
	end
	local parts = 0
	for _, instance in root:GetDescendants() do
		if instance:IsA("BasePart") then
			parts += 1
			check(instance.Anchored and not instance.CanTouch, "six developed lots use anchored, non-touch objects")
		end
	end
	print("INF03 SIX DEVELOPED properties:", parts, "parts; build seconds", os.clock() - started)
	check(parts <= 1000, "six developed plots bounded instance workload")
	root:Destroy()
	return count
end
