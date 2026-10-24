--!strict
-- Actual Studio keyboard movement with one position/camera seed per pad.
-- Cash, income, purchases and purchase remotes are never manufactured.
return function(): number
	local Run = game:GetService("RunService")
	assert(Run:IsStudio() and Run:IsClient(), "Factory input smoke requires a Studio client")
	local player = game:GetService("Players").LocalPlayer
	assert(player, "Actual client expected")
	local shared = game:GetService("ReplicatedStorage").TycoonShared
	local Config, Catalogue = require(shared.Config), require(shared.UpgradeCatalogue)
	local Rules = require(shared.Experiments.FactoryPurchases.Rules)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	assert(character and root and root:IsA("BasePart"), "Live factory character expected")
	local runtime = workspace:FindFirstChild(Config.RuntimeName)
	local plot = runtime and runtime:FindFirstChild(`Plot{player:GetAttribute(Config.Attributes.PlotId)}`)
	assert(plot, "Assigned factory expected")
	local camera = workspace.CurrentCamera
	assert(camera, "Current camera expected")
	local oldType, oldFrame = camera.CameraType, camera.CFrame
	local input: any = game:GetService("UserInputService"):CreateVirtualInput()
	assert(input, "Studio VirtualInput expected")
	local checks = 0
	local function check(ok: boolean, message: string)
		assert(ok, message)
		checks += 1
	end
	local function waitFor(condition: () -> boolean, message: string, timeout: number)
		local deadline = os.clock() + timeout
		while not condition() and os.clock() < deadline do
			task.wait(0.03)
		end
		check(condition(), message)
	end
	local function cash(): number
		local value = player:GetAttribute(Config.Attributes.Cash)
		assert(typeof(value) == "number", "Actual cash expected")
		return value
	end
	local function owned(id: Catalogue.Id): boolean
		return player:GetAttribute(Catalogue.purchaseAttribute(id)) == true
	end
	local function seed(id: string): BasePart
		local pad = plot:FindFirstChild("Pad_" .. id)
		assert(pad and pad:IsA("BasePart"), "Actual pad expected")
		local start = pad.CFrame * CFrame.new(0, 3, 7)
		character:PivotTo(start)
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = CFrame.lookAt(
			start.Position - pad.CFrame.LookVector * 10 + Vector3.new(0, 6, 0),
			pad.Position + Vector3.new(0, 2, 0)
		)
		task.wait(0.3)
		return pad
	end
	local function walk(pad: BasePart, entering: boolean)
		local key = if entering then Enum.KeyCode.W else Enum.KeyCode.S
		input:SendKey(true, key, false)
		local ok, issue = pcall(function()
			waitFor(function()
				local inside = Rules.contains(pad.CFrame:PointToObjectSpace(root.Position), pad.Size, not entering)
				return inside == entering
			end, "Native keyboard movement must cross pad bounds", 5)
		end)
		input:SendKey(false, key, false)
		if not ok then
			local humanoid = character:FindFirstChildWhichIsA("Humanoid")
			print(
				"INTEGRATE01 INPUT DIAGNOSTIC",
				game:GetService("UserInputService").KeyboardEnabled,
				game:GetService("UserInputService").TouchEnabled,
				pad.CFrame:PointToObjectSpace(root.Position),
				humanoid and humanoid.MoveDirection,
				humanoid and humanoid.WalkSpeed,
				root.Anchored
			)
		end
		assert(ok, tostring(issue))
		task.wait(0.2)
	end
	local function click(button: TextButton)
		local origin = game:GetService("GuiService"):GetInsetArea(Enum.ScreenInsets.None).Min
		local position = button.AbsolutePosition + button.AbsoluteSize / 2 - origin
		input:SendMouseButton(position, Enum.UserInputType.MouseButton1, true, 0)
		task.wait(0.05)
		input:SendMouseButton(position, Enum.UserInputType.MouseButton1, false, 0)
		task.wait(0.2)
	end
	local ok, issue = pcall(function()
		check(cash() < 24, "Fresh test needs enough time to enter the 30-cash Workshop unfunded")
		check(
			Catalogue.ById.income_booster.Cost == 10 and Catalogue.ById.workshop.Cost == 30,
			"Economy prices unchanged"
		)
		local pad = seed("workshop")
		walk(pad, true)
		check(not owned("workshop"), "Unfunded native entry refuses")
		waitFor(function()
			return cash() >= 32
		end, "Ordinary income funds the standing player", 40)
		check(not owned("workshop"), "Funding while standing cannot purchase")
		walk(pad, false)
		walk(pad, true)
		waitFor(function()
			return owned("workshop")
		end, "Funded native re-entry purchases automatically", 5)
		-- Purchase and rate are separate replicated attributes; wait for both
		-- confirmations instead of assuming they arrive in one client frame.
		waitFor(function()
			return player:GetAttribute(Config.Attributes.IncomeRate) == 4
		end, "Workshop gives the unchanged 1+3 income", 5)
		waitFor(function()
			return cash() >= 12
		end, "Natural earnings fund the booster", 8)
		local chooser = player.PlayerGui:FindFirstChild("TycoonModeChooser")
		assert(chooser, "Modes chooser expected")
		click(player.PlayerGui:FindFirstChild("Modes", true) :: TextButton)
		check(chooser:GetAttribute("ModalOpen") == true, "Actual Modes button opens modal")
		local booster = seed("income_booster")
		walk(booster, true)
		check(not owned("income_booster"), "Open modal blocks a funded pad visit")
		click(chooser:FindFirstChild("Stay", true) :: TextButton)
		check(chooser:GetAttribute("ModalOpen") == false, "Actual Stay closes modal")
		task.wait(1)
		check(not owned("income_booster"), "Closing a modal while standing cannot buy")
		walk(booster, false)
		walk(booster, true)
		waitFor(function()
			return owned("income_booster")
		end, "Fresh native visit buys ten-cash booster", 5)
		waitFor(function()
			return player:GetAttribute(Config.Attributes.IncomeRate) == 5
		end, "Both unchanged machine rates apply once", 5)
		local balance = cash()
		task.wait(3)
		check(cash() >= balance, "Standing on a bought pad cannot charge again")
		print("INTEGRATE01 NATIVE keyboard Factory assertions:", checks)
	end)
	input:SendKey(false, Enum.KeyCode.W, false)
	input:SendKey(false, Enum.KeyCode.S, false)
	camera.CameraType, camera.CFrame = oldType, oldFrame
	assert(ok, tostring(issue))
	return checks
end
