--!strict

local Client = game:GetService("StarterPlayer").StarterPlayerScripts.TycoonClient
local Guidance = require(Client.FactoryGuidance)
local Onboarding = require(Client.Onboarding)
local Bindings = require(Client.RuntimeBindings)
local State = require(Client.UiState)
local Config = require(game:GetService("ReplicatedStorage").TycoonShared.Config)
local Catalogue = require(game:GetService("ReplicatedStorage").TycoonShared.UpgradeCatalogue)

return function(): number
	local checks = 0
	local function check(value: boolean, message: string)
		assert(value, message)
		checks += 1
	end
	local attributes: { [string]: any } = {
		[Config.Attributes.Assignment] = "Assigned",
		[Config.Attributes.PlotId] = 6,
		[Config.Attributes.Cash] = 30,
		[Config.Attributes.IncomeRate] = 1,
	}
	local function economy(): State.Economy
		return State.economy(function(name: string): any
			return attributes[name]
		end)
	end
	local progress = Onboarding.new()
	check(Onboarding.text(progress, economy(), 0) ~= "", "Assigned beginner receives optional guidance")
	Onboarding.dismiss(progress)
	check(Onboarding.text(progress, economy(), 0) == "", "Dismissal retained")
	Onboarding.restart(progress)
	check(Onboarding.text(progress, economy(), 0) ~= "", "Explicit Help restart")
	attributes[Config.Attributes.IncomeRate] = 12
	Onboarding.observe(progress, economy(), 1)
	check(not progress.completed, "Income is not purchase completion")
	progress.replay = false
	attributes[Catalogue.purchaseAttribute("workshop")] = true
	Onboarding.observe(progress, economy(), 2)
	check(progress.completed and progress.acknowledgement == 6, "Any real catalogue purchase completes guidance")
	check(Onboarding.text(progress, economy(), 3) ~= "", "Brief acknowledgement")
	check(Onboarding.text(progress, economy(), 6) == "", "Acknowledgement retires without repeating")
	Onboarding.restart(progress)
	check(
		progress.completed and Onboarding.text(progress, economy(), 20) ~= "",
		"Completed player may explicitly access guidance again"
	)
	local existing = Onboarding.new()
	Onboarding.observe(existing, economy(), 0)
	check(existing.completed, "Preexisting purchase handled on initialization")
	attributes[Config.Attributes.Assignment] = "Full"
	check(Onboarding.text(progress, economy(), 0) == "", "Full capacity hides optional hint")
	check(
		string.find(Onboarding.help(progress, economy()), "no waiting queue", 1, true) ~= nil,
		"Full has no retry/queue promise"
	)
	attributes[Config.Attributes.Assignment] = "Assigned"
	attributes[Config.Attributes.Cash] = math.huge
	check(economy().unavailable ~= nil and not economy().assigned, "Nonfinite economy fails visibly")
	attributes[Config.Attributes.Cash] = 30
	attributes[Catalogue.purchaseAttribute("workshop")] = "true"
	check(economy().unavailable ~= nil and economy().count == 0, "Malformed purchase never completes hint")
	attributes[Catalogue.purchaseAttribute("workshop")] = true
	check(economy().assigned, "Valid economy recovers")
	local valid = { id = 1, phase = "open", opensAt = 20, closesAt = 30, nextOpensAt = 50, deadline = 30, reward = 10 }
	check(State.snapshot(valid) ~= nil, "Real snapshot shape accepted")
	for _, value in { "invalid", {}, { id = 1, phase = "open" } } do
		local snapshot, issue = State.snapshot(value)
		check(snapshot == nil and issue ~= nil, "Malformed snapshot rejected with context")
	end
	local invalidFields: { [string]: any } =
		{ phase = "resolved", reward = 0, deadline = math.huge, winnerName = 99, winnerUserId = 1 }
	for key, value in invalidFields do
		local malformed: { [string]: any } = table.clone(valid)
		malformed[key] = value
		check(State.snapshot(malformed) == nil, `Invalid {key} rejected`)
	end
	local origin, camera = Vector3.new(0, 3, 0), CFrame.new()
	for point, expected in
		{
			[Vector3.new(0, 0, -80)] = "Ahead",
			[Vector3.new(0, 0, 80)] = "Behind",
			[Vector3.new(80, 0, 0)] = "right",
			[Vector3.new(-80, 0, 0)] = "left",
		}
	do
		local cue, reached = Guidance.cue(origin, camera, point, 6)
		check(
			not reached and string.find(cue, expected, 1, true) ~= nil and string.find(cue, "80 studs", 1, true) ~= nil,
			"Offscreen direction and distance"
		)
	end
	local _, reached = Guidance.cue(origin, camera, Vector3.new(0, 0, 5), 6)
	check(reached, "Entrance arrival retires guidance")
	local _, above = Guidance.cue(Vector3.new(0, 30, 0), camera, Vector3.zero, 6)
	check(not above, "Vertical separation is not arrival")
	local root, runtime, map, lots, lot, owned =
		Instance.new("Folder"),
		Instance.new("Folder"),
		Instance.new("Model"),
		Instance.new("Folder"),
		Instance.new("Model"),
		Instance.new("Model")
	runtime.Name, runtime.Parent = Config.RuntimeName, root
	map.Name, map.Parent = Config.MapName, root
	lots.Name, lots.Parent = "Lots", map
	lot.Name, lot.Parent = "Lot6", lots
	lot:SetAttribute("LotId", 6)
	owned.Name, owned.Parent = "Plot6", runtime
	owned:SetAttribute(Config.Attributes.PlotId, 6)
	owned:SetAttribute(Config.Attributes.OwnerUserId, 0)
	check(Guidance.resolve(root, 6, 1) == nil, "Another owner cannot become target")
	check(Guidance.resolve(root, 1, 0) == nil, "No hardcoded factory 1 fallback")
	check(Guidance.resolve(root, 6, 0) == nil, "Partial anchor replication remains locating")
	local fakePlayer, gui = Instance.new("Player"), Instance.new("ScreenGui")
	local active = false
	local guide = Guidance.new(fakePlayer, gui, function(_text: string, value: boolean)
		active = value
	end, root)
	guide.assignment(6, false)
	guide.start()
	guide.tick(0.25)
	check(active and #gui:GetChildren() == 0, "Pending anchor has no origin marker")
	local entrance = Instance.new("Part")
	entrance.Name, entrance.Anchored, entrance.Parent = "Entrance", true, lot
	guide.tick(0.25)
	check(Guidance.resolve(root, 6, 0) == entrance and #gui:GetChildren() == 1, "Late entrance binds one local marker")
	guide.tick(0.25)
	guide.tick(0.25)
	check(#gui:GetChildren() == 1, "No repeated marker creation")
	guide.pause(true)
	check(not (gui:GetChildren()[1] :: BillboardGui).Enabled, "Open panel pauses world cue")
	guide.pause(false)
	check((gui:GetChildren()[1] :: BillboardGui).Enabled, "Closing panel resumes cue")
	owned:SetAttribute(Config.Attributes.OwnerUserId, 1)
	guide.tick(0.25)
	check(not active and #gui:GetChildren() == 0, "Ownership loss clears retained target")
	owned:SetAttribute(Config.Attributes.OwnerUserId, 0)
	guide.start()
	guide.tick(0.25)
	entrance:Destroy()
	guide.tick(0.25)
	check(not active and #gui:GetChildren() == 0, "Target destruction retires active guidance")
	guide.start()
	guide.assignment(nil, true)
	check(not active, "Assignment loss clears locating guidance")
	guide.start()
	check(not active, "Full capacity cannot start a target")
	guide.assignment(6, false)
	guide.start()
	guide.destroy()
	guide.tick(1)
	check(not active and #gui:GetChildren() == 0, "Teardown clears active state and marker")
	gui:Destroy()
	fakePlayer:Destroy()
	root:Destroy()
	local dependencies = Instance.new("Folder")
	local order: { string } = {}
	local releases = 0
	local function bind(name: string): (Instance) -> () -> ()
		return function(_instance: Instance): () -> ()
			table.insert(order, name)
			return function()
				releases += 1
			end
		end
	end
	local bindings = Bindings.start(dependencies, {
		{ name = "Feedback", class = "RemoteEvent", bind = bind("feedback") },
		{ name = "Snapshot", class = "StringValue", requires = { "Feedback" }, bind = bind("snapshot") },
	}, function() end, 0.03)
	check(bindings.status("Feedback") == "waiting", "Dependencies initially pending")
	task.wait(0.05)
	check(bindings.status("Snapshot") == "unavailable", "Bounded deadline shows unavailable")
	local snapshot = Instance.new("StringValue")
	snapshot.Name, snapshot.Parent = "Snapshot", dependencies
	task.wait()
	check(#order == 0, "Snapshot cannot bind before feedback listener")
	local wrong = Instance.new("Folder")
	wrong.Name, wrong.Parent = "Feedback", dependencies
	task.wait()
	check(bindings.status("Feedback") == "unavailable" and #order == 0, "Wrong class diagnosed without fallback")
	wrong:Destroy()
	local feedback = Instance.new("RemoteEvent")
	feedback.Name, feedback.Parent = "Feedback", dependencies
	task.wait()
	check(
		bindings.status("Snapshot") == "ready" and table.concat(order, ",") == "feedback,snapshot",
		"Late dependencies recover in order"
	)
	feedback.Name = "RemovedFeedback"
	task.wait()
	check(releases == 2 and bindings.status("Snapshot") == "unavailable", "Loss/rename unbinds dependents")
	feedback:Destroy()
	local replacement = Instance.new("RemoteEvent")
	replacement.Name, replacement.Parent = "Feedback", dependencies
	task.wait()
	check(#order == 4, "Replacement binds exactly once")
	local duplicate = replacement:Clone()
	duplicate.Parent = dependencies
	task.wait()
	check(bindings.status("Feedback") == "unavailable", "Duplicate contract rejected")
	duplicate:Destroy()
	task.wait()
	check(bindings.status("Snapshot") == "ready", "Duplicate removal recovers")
	bindings.destroy()
	local before = #order
	local late = replacement:Clone()
	late.Parent = dependencies
	task.wait()
	check(#order == before, "Destroyed bindings have no late listeners")
	dependencies:Destroy()
	return checks
end
