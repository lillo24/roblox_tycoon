--!nonstrict
-- All wrappers, seeding, controls and observations are confined to this unmapped fixture.
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local Replicated = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local Server = game:GetService("ServerScriptService").TycoonServer
local Fixture = {}
function Fixture.start(workload)
	assert(Run:IsStudio(), "PERF01 is local Studio only")
	local control = Replicated.PERF01
	local sampler = require(control.Sampler).new("server")
	local memory = require(script.Parent.ProfileMemoryStore).new()
	local presets = require(script.Parent.Workloads)
	local showcase = require(script.Parent.InfiniteShowcase)
	local examples
	if workload == "Developed" then
		examples = {}
		for id = -2005, -2001 do
			memory.values["user_" .. id] =
				{ version = 1, data = presets.make(if id % 2 == 0 then "Sky" else "Garden", showcase) }
			examples[id] = "PERF CONTROL EXAMPLE"
		end
	end
	local originalUpdate = memory.update
	local update = function(key, transform)
		if memory.values[key] == nil and workload ~= "Fresh" then
			memory.values[key] =
				{ version = 1, data = presets.make(if workload == "Dense" then "Dense" else "Garden", showcase) }
		end
		local started = os.clock()
		local result = originalUpdate(key, transform)
		sampler.add("memoryCheckpointWorkMs", (os.clock() - started) * 1000)
		if result then
			sampler.emit("checkpoint", { bytes = #Http:JSONEncode(result), phase = control:GetAttribute("Phase") })
		end
		return result
	end
	for _, descriptor in
		{
			{ require(Server.Persistence.Profiles), "snapshot", "snapshotWorkMs" },
			{ require(Server.PropertyWorld), "reconcile", "worldWorkMs" },
			{ require(Server.PropertyEdits), "apply", "transactionWorkMs" },
		}
	do
		local target, method, metric = descriptor[1], descriptor[2], descriptor[3]
		local original = target[method]
		target[method] = function(...)
			local started = os.clock()
			local result = table.pack(original(...))
			if control:GetAttribute("Phase") ~= "Idle" then
				sampler.add(metric .. ":" .. control:GetAttribute("Phase"), (os.clock() - started) * 1000)
			end
			return table.unpack(result, 1, result.n)
		end
	end
	local churnAdded, churnRemoved = 0, 0
	local arrivals = workspace.DescendantAdded:Connect(function(item)
		local world = workspace:FindFirstChild("TycoonRuntime")
		if world and item:IsA("BasePart") and item:IsDescendantOf(world) then
			churnAdded += 1
		end
	end)
	local departures = workspace.DescendantRemoving:Connect(function(item)
		local world = workspace:FindFirstChild("TycoonRuntime")
		if world and item:IsA("BasePart") and item:IsDescendantOf(world) then
			churnRemoved += 1
		end
	end)
	control:SetAttribute("Workload", workload)
	control:SetAttribute("Phase", "Idle")
	local remote = Instance.new("RemoteEvent")
	remote.Name, remote.Parent = "Control", control
	local generation = 0
	remote.OnServerEvent:Connect(function(player, action)
		if action == "respawn" then
			player:LoadCharacterAsync()
			return
		end
		if control:GetAttribute("Phase") ~= "Idle" then
			return
		end
		if action ~= "sample" and action ~= "churn" then
			return
		end
		if workload == "SixOwners" then
			assert(#Players:GetPlayers() == 6, "SixOwners requires six ACTUAL clients")
		end
		for _, owner in Players:GetPlayers() do
			assert(owner:GetAttribute("TycoonAssignment") == "Ready", "Every actual owner must be ready")
		end
		generation += 1
		local current = generation
		task.spawn(function()
			local function phase(name, seconds)
				if current ~= generation then
					return
				end
				control:SetAttribute("Started", workspace:GetServerTimeNow())
				control:SetAttribute("Phase", name)
				sampler.emit(
					"phase",
					{ phase = name, seconds = seconds, clients = #Players:GetPlayers(), workload = workload }
				)
				task.wait(seconds)
				sampler.flush()
			end
			if action == "sample" then
				phase("Warmup", 30)
				phase("Stable", 120)
			else
				phase("Churn", 180)
				phase("Quiet", 120)
			end
			control:SetAttribute("Phase", "Idle")
			sampler.emit("complete", {
				action = action,
				clients = #Players:GetPlayers(),
				addedParts = churnAdded,
				removedParts = churnRemoved,
			})
		end)
	end)
	require(Server.AppRuntime).start(
		{ update = update, label = "PERF local memory • resets on Stop", examples = examples },
		require(script.Parent.ModePreview).new("Infinite", "LateFailure")
	)
	local seconds = 0
	local pulse = Run.Heartbeat:Connect(function(delta)
		local phase = control:GetAttribute("Phase")
		if phase ~= "Idle" then
			sampler.add("heartbeatIntervalMs:" .. phase, delta * 1000)
		end
		seconds += delta
		if seconds < 5 then
			return
		end
		seconds = 0
		local result = sampler.stats(phase)
		result.clients, result.addedParts, result.removedParts = #Players:GetPlayers(), churnAdded, churnRemoved
		local world = workspace:FindFirstChild("TycoonRuntime")
		local parts, animated = 0, 0
		if world then
			for _, item in world:GetDescendants() do
				if item:IsA("BasePart") then
					parts += 1
					if item:GetAttribute("Activity") then
						animated += 1
					end
				end
			end
		end
		result.worldParts, result.animatedParts = parts, animated
		sampler.emit("stats", result)
	end)
	game:BindToClose(function()
		pulse:Disconnect()
		arrivals:Disconnect()
		departures:Disconnect()
		sampler.flush()
	end)
	return memory
end
return Fixture
