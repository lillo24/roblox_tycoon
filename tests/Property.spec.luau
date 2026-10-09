--!strict
local Server = game:GetService("ServerScriptService").TycoonServer
local Shared = game:GetService("ReplicatedStorage").TycoonShared
local Schema = require(Server.Persistence.ProfileSchema)
local Profiles = require(Server.Persistence.Profiles)
local Store = require(Server.Persistence.ProfileStore)
local Session = require(Server.Session)
local Edits = require(Server.PropertyEdits)
local Catalogue = require(Shared.UpgradeCatalogue)
local Placement = require(Shared.Infinite.Placement)
return function(Memory: any): number
	local count = 0
	local function check(value: boolean, message: string)
		assert(value, "INF02: " .. message)
		count += 1
	end
	local old = {
		version = 1,
		cash = 123,
		assets = { income_booster = true, workshop = true, booster_tuning = true, workshop_expansion = true },
		placements = {
			income_booster = "east_back",
			workshop = "west_front",
			booster_tuning = "west_back",
			workshop_expansion = "east_front",
		},
	}
	local migrated = Schema.decode(old)
	assert(migrated, "v1 profile must migrate")
	check(
		migrated.version == 2 and migrated.cash == 123 and Schema.income(migrated) == 12,
		"v1 cash and four earnings survive"
	)
	check(
		migrated.objects.legacy_income_booster.x == 18 and migrated.objects.legacy_income_booster.z == 5,
		"v1 arrangement survives as local coordinates"
	)
	check(Schema.decode({ version = 99 }) == nil, "newer schemas refused")
	local invalid: any = Schema.decode(migrated)
	invalid.objects.legacy_workshop.content = "future_item"
	check(Schema.decode(invalid) == nil, "unknown content refused without loss")
	local memory = Memory.new()
	memory.values.user_1 = { version = 1, data = old }
	local now, serial = 1000, 0
	local store = Store.new(memory.update, {
		update = memory.update,
		now = function()
			return now
		end,
		wait = function(seconds)
			now += seconds
		end,
		jitter = function()
			return 0
		end,
		token = function()
			serial += 1
			return "property-" .. serial
		end,
	})
	local session = Session.new({ PlotCount = 2, StartingCash = 0, BaseIncome = 1 }, Catalogue.Definitions)
	local profiles = Profiles.new(session, store, function() end, function(work)
		work()
	end)
	profiles:join(1)
	profiles:join(2)
	local state = session:get(1)
	assert(state, "migrated profile must allocate")
	local function request(user: number, action: string, extra: any?): any
		local view = profiles:read(user)
		local result = extra or {}
		result.action, result.epoch, result.sequence, result.plot, result.revision =
			action, view.epoch, view.sequence + 1, view.plot, view.data.revision
		return result
	end
	local buy = request(1, "buy", { content = "planter" })
	check(not profiles:edit(2, buy), "visitor cannot edit owner's epoch or lot")
	check(profiles:edit(1, buy), "owner obtains decor")
	local cash = state.cash
	check(profiles:edit(1, buy) and state.cash == cash, "duplicate purchase returns same result without charge")
	local another = request(1, "buy", { content = "planter" })
	check(profiles:edit(1, another), "second copy has separate identity")
	local view = profiles:read(1)
	check(
		view.data.objects.o1.content == "planter" and view.data.objects.o2.content == "planter",
		"two owned instances"
	)
	local bad = request(1, "place", { object = "o1", x = 0, z = 0, rotation = 0 })
	check(not profiles:edit(1, bad) and profiles:read(1).data.objects.o1.stored, "path collision keeps previous state")
	check(profiles:edit(1, request(1, "place", { object = "o1", x = -9, z = -15, rotation = 0 })), "first arrangement")
	local stale = request(1, "place", { object = "o1", x = -9, z = 0, rotation = 1 })
	check(profiles:edit(1, request(1, "theme", { theme = "Terracotta" })), "appearance change")
	stale.sequence += 1
	check(
		not profiles:edit(1, stale) and profiles:read(1).data.objects.o1.z == -15,
		"stale layout cannot overwrite newer palette revision"
	)
	check(profiles:edit(1, request(1, "place", { object = "o1", x = 9, z = 6, rotation = 1 })), "second arrangement")
	check(
		profiles:edit(1, request(1, "store", { object = "legacy_workshop" })) and state.incomeRate == 12,
		"stored equipment still earns"
	)
	check(
		profiles:edit(1, request(1, "place", { object = "legacy_workshop", x = -18, z = -10, rotation = 3 })),
		"equipment re-placed without rebuy"
	)
	local before = profiles:read(1).data
	local proposal = table.clone(before.objects.o1)
	proposal.x = -9
	check(profiles:read(1).data.objects.o1.x == 9, "cancelled local preview never touches authority")
	for _, x in { math.huge, 0 / 0, 25, 1.5 } do
		check(
			not profiles:edit(1, request(1, "place", { object = "o1", x = x, z = 0, rotation = 0 })),
			"finite whole footprint enforced"
		)
	end
	local beforeSave = memory.values.user_1.data.cash
	memory.failBefore = 4
	now += 31
	profiles:step()
	check(
		memory.values.user_1.data.cash == beforeSave and profiles:read(1).data.theme == "Terracotta",
		"failed checkpoint preserves accepted state and prior record"
	)
	local departure = request(1, "theme", { theme = "Sage" })
	profiles:leave(1)
	check(not profiles:edit(1, departure), "departed owner cannot write")
	profiles:join(3)
	profiles:leave(2)
	profiles:join(1)
	check(
		profiles:read(1).plot == 2
			and profiles:read(1).data.objects.o1.x == 9
			and profiles:read(1).data.theme == "Terracotta",
		"profile restores arrangement to different lot"
	)
	check(not profiles:edit(1, departure), "old request cannot cross arrival epoch")
	local restored = profiles:read(1).data
	local World = require(Server.PropertyWorld)
	local PlotWorld = require(Server.PlotWorld)
	local root = Instance.new("Folder")
	root.Name, root.Parent = "INF02WorldFixture", workspace
	for lot = 1, 6 do
		local model, upgrades, label = Instance.new("Model"), Instance.new("Folder"), Instance.new("TextLabel")
		model.Parent, upgrades.Parent, label.Parent = root, model, model
		local hub = workspace:FindFirstChild("FactoryHub") :: Model
		local lots = hub:FindFirstChild("Lots") :: Folder
		local authored = lots:FindFirstChild("Lot" .. lot) :: Model
		local frame = (authored:FindFirstChild("Anchor") :: Part).CFrame
		local plot: PlotWorld.Plot =
			{ model = model, upgrades = upgrades, label = label, frame = frame, color = Color3.new(1, 1, 1), pads = {} }
		World.prepare(plot)
		World.reconcile(plot, restored)
		local clay = (upgrades:FindFirstChild("o1") :: Model):FindFirstChild("Clay") :: Part
		check(
			(clay.Position - frame:PointToWorldSpace(Vector3.new(9, 1, 6))).Magnitude < 0.01,
			"restored transform follows each actual oriented lot"
		)
		for _, part in upgrades:GetDescendants() do
			if part:IsA("BasePart") then
				check(part.Anchored and not part.CanTouch, "visitor cannot push or contact-spend")
			end
		end
		PlotWorld.setOwner(plot, nil)
		check(#upgrades:GetChildren() == 0, "departure clears rendered belongings")
		World.reconcile(plot, Schema.new())
		check(upgrades:FindFirstChild("o1") == nil, "reused lot has no prior objects")
	end
	root:Destroy()
	local full = Schema.new()
	full.cash = 100000
	for _ = 1, 48 do
		local result = Edits.apply(full, { action = "buy", content = "lantern", revision = full.revision })
		assert(result, "capacity setup")
		full = result
	end
	check(
		Edits.apply(full, { action = "buy", content = "planter", revision = full.revision }) == nil,
		"bounded belongings"
	)
	check(#game:GetService("HttpService"):JSONEncode(full) < 16384, "maximum property stays below 16 KiB")
	check(
		Edits.apply(
			restored,
			{ action = "place", revision = restored.revision, object = "o1", x = -18, z = -10, rotation = 0 }
		) == nil,
		"occupied footprint rejected"
	)
	check(
		not Placement.valid({}, "x", { content = "bench", x = 23, z = 0, rotation = 0, stored = false }),
		"edge includes width"
	)
	local expiredRequest = request(1, "theme", { theme = "Sage" })
	now += 120
	profiles:step()
	check(not profiles:edit(1, expiredRequest), "lease loss rejects edits")
	return count
end
