--!strict
-- Cosmetic activity only: no physics/products, no saving, no remote traffic.
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local Preferences = require(script.Parent.UiPreferences)
local Activity = {}
function Activity.start(): () -> ()
	local parts: { [BasePart]: boolean } = {}
	local root: Instance? = nil
	local added: RBXScriptConnection? = nil
	local removed: RBXScriptConnection? = nil
	local function track(object: Instance)
		-- Replication can deliver a part before its attributes. Track bounded world
		-- parts now and inspect RestFrame on each tick, including late metadata.
		if object:IsA("BasePart") then
			parts[object] = true
		end
	end
	local function attach(folder: Instance)
		if folder.Name ~= "TycoonRuntime" then
			return
		end
		root = folder
		for _, object in folder:GetDescendants() do
			track(object)
		end
		added = folder.DescendantAdded:Connect(track)
		removed = folder.DescendantRemoving:Connect(function(object)
			if object:IsA("BasePart") then
				parts[object] = nil
			end
		end)
	end
	local arrival = workspace.ChildAdded:Connect(attach)
	local current = workspace:FindFirstChild("TycoonRuntime")
	if current then
		attach(current)
	end
	local elapsed = 0
	local heartbeat = RunService.Heartbeat:Connect(function(delta: number)
		elapsed += delta
		if elapsed < 0.1 then
			return
		end
		elapsed = 0
		local camera = workspace.CurrentCamera
		if
			not camera
			or not root
			or not root.Parent
			or Preferences.motionReduced(Preferences.read(), GuiService.ReducedMotionEnabled)
		then
			return
		end
		-- CFrame rotation uses float precision: Unix-sized angles appear frozen.
		-- 24*pi is a common period of these fixed effects (including radii 1..3).
		local t = workspace:GetServerTimeNow() % (24 * math.pi)
		for part in parts do
			local frame = part:GetAttribute("RestFrame")
			if typeof(frame) ~= "CFrame" or (camera.CFrame.Position - frame.Position).Magnitude > 120 then
				continue
			end
			local _, visible = camera:WorldToViewportPoint(frame.Position)
			if not visible then
				continue
			end
			local motion = part:GetAttribute("Activity")
			if motion == "spin" then
				part.CFrame = CFrame.new(frame.Position) * CFrame.Angles(0, t * 0.5, 0) * frame.Rotation
			elseif motion == "scan" then
				part.CFrame = frame * CFrame.Angles(0, math.sin(t * 0.25) * 0.15, 0)
			elseif motion == "orbit" then
				local center, radius = part:GetAttribute("OrbitCenter"), part:GetAttribute("OrbitRadius")
				if typeof(center) == "CFrame" and typeof(radius) == "number" then
					part.CFrame = center * CFrame.new(math.cos(t / radius) * radius, 0, math.sin(t / radius) * radius)
				end
			elseif motion == "bloom" then
				part.CFrame = frame * CFrame.new(0, math.sin(t * 0.5) * 0.15, 0)
			elseif motion == "pulse" then
				local color = part:GetAttribute("RestColor")
				if typeof(color) == "Color3" then
					part.Color = color:Lerp(Color3.fromRGB(246, 215, 143), (math.sin(t * 0.5) + 1) * 0.25)
				end
			end
		end
	end)
	return function()
		heartbeat:Disconnect()
		arrival:Disconnect()
		if added then
			added:Disconnect()
		end
		if removed then
			removed:Disconnect()
		end
		table.clear(parts)
	end
end
return Activity
