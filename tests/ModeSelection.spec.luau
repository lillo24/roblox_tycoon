--!strict
-- Actual Studio client + simulated teleport adapter only. VirtualInput exercises
-- the real Activated handlers; this is not a physical touch/controller test.
return function(): number
	local RunService = game:GetService("RunService")
	assert(RunService:IsStudio() and RunService:IsClient(), "Mode selection smoke requires a Studio client")
	local root = game:GetService("ReplicatedStorage")
	local player = game:GetService("Players").LocalPlayer
	assert(player, "Mode selection requires LocalPlayer")
	local remote = root:FindFirstChild("TycoonRoutes")
	assert(
		remote and remote:IsA("RemoteEvent") and remote:GetAttribute("Preview") ~= "",
		"Simulated routing required; never test-click live teleports"
	)
	local gui = player.PlayerGui:FindFirstChild("TycoonModeChooser")
	assert(gui and gui:IsA("ScreenGui"), "Mode chooser expected")
	local role = root:GetAttribute("TycoonServerRole")
	local checks = 0
	local function check(ok: boolean, message: string)
		assert(ok, message)
		checks += 1
	end
	local function waitFor(condition: () -> boolean, message: string)
		local deadline = os.clock() + 20
		while not condition() and os.clock() < deadline do
			task.wait(0.05)
		end
		check(condition(), message)
	end
	-- The engine API returns Object in the pinned declarations; its documented
	-- VirtualInput methods are confined to this non-shipping Studio test boundary.
	local input: any = game:GetService("UserInputService"):CreateVirtualInput()
	assert(input, "Studio VirtualInput unavailable")
	local function click(button: TextButton)
		assert(button.Visible and button.Active, "Test action must be visible and active")
		-- Include device cutouts as well as the top bar. GetGuiInset alone omits
		-- the portrait notch offset used by Studio's virtual input coordinates.
		local origin = game:GetService("GuiService"):GetInsetArea(Enum.ScreenInsets.None).Min
		local center = button.AbsolutePosition + button.AbsoluteSize / 2 - origin
		input:SendMousePosition(center)
		input:SendMouseButton(center, Enum.UserInputType.MouseButton1, true, 0)
		task.wait(0.05)
		input:SendMouseButton(center, Enum.UserInputType.MouseButton1, false, 0)
	end
	local before: any = nil
	local property = root:FindFirstChild("TycoonProperty")
	if role == "Infinite" then
		assert(property and property:IsA("RemoteFunction"), "Infinite property channel expected")
		before = property:InvokeServer("read")
		check(before.available, "Infinite ready before departure")
	end
	if role ~= "Entry" then
		click(player.PlayerGui:FindFirstChild("Modes", true) :: TextButton)
		waitFor(function()
			return gui:GetAttribute("ModalOpen") == true
		end, "Modes button opens the return panel")
	end
	local scroll = gui:FindFirstChild("Content", true) :: ScrollingFrame
	assert(scroll, "Scrollable choices expected")
	local choices = if role == "Entry" then { "Prototype", "Infinite", "Clash" } else { "Entry" }
	for _, destination in choices do
		local button = scroll:FindFirstChild(destination) :: TextButton
		assert(button, "Named destination button expected")
		scroll.CanvasPosition =
			Vector2.new(0, math.max(0, scroll.CanvasPosition.Y + button.AbsolutePosition.Y - scroll.AbsolutePosition.Y))
		RunService.RenderStepped:Wait()
		RunService.RenderStepped:Wait()
		local previous = player:GetAttribute("TycoonRoutePhase")
		click(button)
		waitFor(function()
			return player:GetAttribute("TycoonRoutePhase") ~= previous
		end, "Real button requests " .. destination)
		waitFor(function()
			return player:GetAttribute("TycoonRoutePhase") == "Failed"
		end, "Simulated failure returns an honest retry state")
		check(root:GetAttribute("TycoonServerRole") == role, "A choice cannot change the running server role")
		task.wait(3.1)
	end
	if before then
		assert(property and property:IsA("RemoteFunction"), "Infinite property channel retained")
		local after = property:InvokeServer("read")
		check(after.available and after.epoch ~= before.epoch, "Infinite failure reacquires a fresh writer epoch")
		check(
			after.data.cash >= before.data.cash and after.data.revision == before.data.revision,
			"Confirmed source progress survives departure and recovery"
		)
	end
	print("INTEGRATE01 ACTUAL button/failure assertions:", role, checks, "viewport", gui.AbsoluteSize)
	return checks
end
