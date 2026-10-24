--!strict
-- Actual Studio client automation; aim replays are network fixtures, not humans.
local root = game:GetService("ReplicatedStorage")
local object = root:WaitForChild("INTEGRATE01Receipt", 20)
if not object then
	return -- Normal interactive previews do not start automation.
end
assert(object:IsA("RemoteEvent"), "Integration test receipt channel expected")
local receipt: RemoteEvent = object
local player = game:GetService("Players").LocalPlayer
assert(player, "Integration fixture requires a real Studio client")
local parent = script.Parent
assert(parent, "Client fixture parent expected")
local checks = parent:WaitForChild("INTEGRATE01ClientQA")
-- Unmapped QA specs use actual engine resolution; see IntegrationServer.
local loadFixture = require
local function waitFor(condition: () -> boolean, message: string)
	local deadline = os.clock() + 60
	while not condition() and os.clock() < deadline do
		task.wait(0.05)
	end
	assert(condition(), message)
end
local ok, result = xpcall(function()
	local chooser = player.PlayerGui:WaitForChild("TycoonModeChooser", 20)
	assert(chooser, "Mode chooser expected")
	task.wait(12) -- Observe beyond startup readiness and allow client observers.
	receipt:FireServer("ready")
	waitFor(function()
		return receipt:GetAttribute("Ready") == true
	end, "All expected clients must be ready")
	local role = root:GetAttribute("TycoonServerRole")
	if role == "Clash" then
		local remote = root:FindFirstChild("AimClash")
		assert(remote and remote:IsA("RemoteEvent"), "Clash remote expected")
		if receipt:GetAttribute("Duel") == true then
			local completed = false
			task.spawn(function()
				local clash = player.PlayerGui:FindFirstChild("AimClash")
				assert(clash, "Clash interface expected")
				local motion = clash:FindFirstChild("Motion", true) :: TextButton
				local count =
					loadFixture(checks:WaitForChild("AimClashClient"))(true, motion.Text:find("reduced") ~= nil)
				print("INTEGRATE01 ACTUAL scripted duel assertions:", count)
				completed = true
			end)
			task.wait(0.2)
			remote:FireServer("queue")
			waitFor(function()
				return completed
			end, "Both actual clients must complete the server-judged duel")
		else
			local began, ended = false, false
			local connection = remote.OnClientEvent:Connect(function(packet: any)
				if packet.kind == "start" then
					assert(packet.practice == true and packet.other == nil, "Practice must be solo")
					began = true
				elseif packet.kind == "result" then
					assert(packet.other == nil, "Solo result cannot invent an opponent")
					ended = true
				end
			end)
			remote:FireServer("practice")
			waitFor(function()
				return began and ended
			end, "Practice completes on one client")
			connection:Disconnect()
			print("INTEGRATE01 ACTUAL solo Practice completed")
		end
		print("INTEGRATE01 ACTUAL Clash display assertions:", loadFixture(checks:WaitForChild("AimClashDisplay"))())
	elseif role == "Prototype" then
		waitFor(function()
			return receipt:GetAttribute("WalkingComplete") == true
		end, "Actual Humanoid walk-on smoke must finish")
	end
	-- The two-player duel covers queue/scoring. Test cancellation/return in a
	-- separate solo run; concurrent simulated pointer clicks share Studio input.
	if receipt:GetAttribute("Duel") ~= true then
		print("INTEGRATE01 ACTUAL selection smoke count:", loadFixture(checks:WaitForChild("ModeSelection"))())
	end
	return "Client assertions completed"
end, function(message: any): string
	return debug.traceback(tostring(message))
end)
if ok then
	receipt:FireServer("passed")
else
	warn("INTEGRATE01 CLIENT FAILED", result)
	receipt:FireServer("failed", tostring(result))
end
