--!nonstrict
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local Input = game:GetService("UserInputService")
local player = Players.LocalPlayer
local control = Replicated:WaitForChild("PERF01")
local sampler = require(control:WaitForChild("Sampler")).new("client:" .. player.UserId)
local actions = control:WaitForChild("Control")
local property = Replicated:WaitForChild("TycoonProperty")
local client = player.PlayerScripts:WaitForChild("TycoonClient")
local editorModule = require(client.PropertyEditor)
local focused, seconds, epoch = true, 0, 0
local sampling, frameNumber = false, 0
local requested, accepted, rejected, editors, cycles = 0, 0, 0, 0, 0
local lastAction = "none"
local camera = workspace.CurrentCamera
local previousType, previousFrame = camera.CameraType, camera.CFrame
local screen = Instance.new("ScreenGui")
screen.Name, screen.ResetOnSpawn, screen.DisplayOrder = "PERF01Controls", false, 50
screen.Parent = player.PlayerGui
for index, choice in { "sample", "churn", "respawn" } do
	local button = Instance.new("TextButton")
	button.Text, button.Size, button.Position =
		"PERF " .. choice, UDim2.fromOffset(125, 32), UDim2.fromOffset(8 + (index - 1) * 130, 75)
	button.Parent = screen
	button.Activated:Connect(function()
		actions:FireServer(choice)
	end)
end
local focus = Input.WindowFocused:Connect(function()
	focused = true
end)
local blur = Input.WindowFocusReleased:Connect(function()
	focused = false
end)
local function phaseChanged()
	epoch += 1
	local phase = control:GetAttribute("Phase")
	if phase ~= "Idle" and not sampling then
		sampler.begin()
		sampling, frameNumber = true, 0
		requested, accepted, rejected, editors, cycles = 0, 0, 0, 0, 0
	end
	sampler.flush()
	sampler.emit("phase", {
		phase = phase,
		focused = focused,
		viewport = { camera.ViewportSize.X, camera.ViewportSize.Y },
		quality = tostring(UserSettings():GetService("UserGameSettings").SavedQualityLevel),
		clock = os.clock(),
		frame = frameNumber,
	})
	if phase == "Idle" then
		camera.CameraType, camera.CFrame = previousType, previousFrame
		sampler.emit("load", {
			requested = requested,
			accepted = accepted,
			rejected = rejected,
			editors = editors,
			cycles = cycles,
			frames = frameNumber,
		})
		sampling = false
		sampler.finish()
	end
	if phase ~= "Churn" then
		return
	end
	local current = epoch
	task.spawn(function()
		local cycle = 0
		while current == epoch do
			cycle += 1
			local snapshot = property:InvokeServer("read")
			if snapshot.available then
				local ids = {}
				for id, object in snapshot.data.objects do
					if
						not require(Replicated.TycoonShared.Infinite.Catalogue).ById[object.content].fixed
						and not object.stored
					then
						table.insert(ids, id)
					end
				end
				table.sort(ids)
				local id = ids[1]
				local function edit(payload)
					task.wait(0.3)
					if current ~= epoch then
						return
					end
					payload.epoch, payload.sequence, payload.plot, payload.revision =
						snapshot.epoch, snapshot.sequence + 1, snapshot.plot, snapshot.data.revision
					local start = os.clock()
					requested += 1
					lastAction = payload.action
					sampler.emit("edit", {
						stage = "request",
						action = payload.action,
						ordinal = requested,
						clock = start,
						revision = snapshot.data.revision,
					})
					local result = property:InvokeServer(payload)
					sampler.add(
						"editRoundTripMs:" .. (if focused then "focused" else "background"),
						(os.clock() - start) * 1000
					)
					if result.available and result.accepted then
						accepted += 1
					else
						rejected += 1
					end
					sampler.emit("edit", {
						stage = "response",
						action = payload.action,
						ordinal = requested,
						clock = os.clock(),
						accepted = result.available and result.accepted,
					})
					assert(
						result.available and result.accepted,
						"PERF ordinary edit rejected: " .. tostring(result.message)
					)
					snapshot = result
				end
				if id then
					local old = snapshot.data.objects[id]
					edit({ action = "store", object = id })
					edit({ action = "place", object = id, x = old.x, z = old.z, rotation = old.rotation })
					-- A half turn preserves the validated footprint, even in the dense layout.
					edit({ action = "place", object = id, x = old.x, z = old.z, rotation = (old.rotation + 2) % 4 })
					edit({ action = "place", object = id, x = old.x, z = old.z, rotation = old.rotation })
				end
				edit({ action = "theme", theme = ({ "Sage", "Terracotta", "Midnight" })[cycle % 3 + 1] })
				if cycle <= 5 and control:GetAttribute("Workload") ~= "Dense" then
					edit({ action = "buy", content = "lantern" })
				end
				task.wait(0.3)
				local hud = player.PlayerGui:FindFirstChild("TycoonHud")
				if hud then
					debug.profilebegin("PERF02 editor create")
					local editor = editorModule.new(hud)
					debug.profileend()
					editors += 1
					sampler.emit("editor", { stage = "open", clock = os.clock(), cycle = cycle })
					editor.open()
					task.wait(0.7)
					debug.profilebegin("PERF02 editor destroy")
					editor.destroy()
					debug.profileend()
					sampler.emit("editor", { stage = "destroy", clock = os.clock(), cycle = cycle })
				end
				cycles = cycle
				sampler.emit("cycle", {
					cycle = cycle,
					owned = (function()
						local n = 0
						for _ in snapshot.data.objects do
							n += 1
						end
						return n
					end)(),
					revision = snapshot.data.revision,
				})
			end
			task.wait(1)
		end
	end)
end
local changed = control:GetAttributeChangedSignal("Phase"):Connect(phaseChanged)
phaseChanged()
local render = Run.PreRender:Connect(function(delta)
	debug.profilebegin("PERF02 client sample")
	local phase = control:GetAttribute("Phase")
	if phase ~= "Idle" then
		frameNumber += 1
		sampler.add("frameIntervalMs:" .. phase .. ":" .. (if focused then "focused" else "background"), delta * 1000)
		camera.CameraType = Enum.CameraType.Scriptable
		local slot = math.floor((workspace:GetServerTimeNow() - control:GetAttribute("Started")) / 20) % 6 + 1
		if delta > 0.0333 then
			-- This tag marks the END of the observed interval, not its CPU cause.
			debug.profilebegin("PERF02 slow interval end")
			sampler.emit("slowFrame", {
				intervalMs = delta * 1000,
				frame = frameNumber,
				clock = os.clock(),
				phase = phase,
				focused = focused,
				slot = slot,
				lastAction = lastAction,
			})
			debug.profileend()
		end
		local world = workspace:FindFirstChild("TycoonRuntime")
		local plot = world and world:FindFirstChild("Plot" .. slot)
		local frame = plot and plot:GetAttribute("PropertyFrame")
		if typeof(frame) == "CFrame" then
			camera.CFrame = frame * CFrame.lookAt(Vector3.new(30, 28, 36), Vector3.new(0, 2, 3))
		end
	end
	seconds += delta
	if seconds < 5 then
		debug.profileend()
		return
	end
	seconds = 0
	local result = sampler.stats(phase)
	result.focused, result.guiInstances = focused, #player.PlayerGui:GetDescendants()
	result.ghosts = if workspace:FindFirstChild("LocalPlacementPreview") then 1 else 0
	result.viewport = { camera.ViewportSize.X, camera.ViewportSize.Y }
	result.assignment = player:GetAttribute("TycoonAssignment")
	result.clock, result.frame = os.clock(), frameNumber
	sampler.emit("stats", result)
	debug.profileend()
end)
script.Destroying:Connect(function()
	epoch += 1
	focus:Disconnect()
	blur:Disconnect()
	changed:Disconnect()
	render:Disconnect()
	camera.CameraType, camera.CFrame = previousType, previousFrame
	screen:Destroy()
	sampler.flush()
end)
