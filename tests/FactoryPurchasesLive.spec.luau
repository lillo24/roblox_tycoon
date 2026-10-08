--!strict

-- Disposable QA variant only: position fixture, followed by actual Humanoid
-- walking and the untouched production offer/reply/purchase adapters. No cash,
-- income, purchase attributes or remote inputs are manufactured by this fixture.
local Players = game:GetService("Players")
local Config = require(game:GetService("ReplicatedStorage").TycoonShared.Config)
local Catalogue = require(game:GetService("ReplicatedStorage").TycoonShared.UpgradeCatalogue)
local Rules = require(game:GetService("ReplicatedStorage").TycoonShared.Experiments.FactoryPurchases.Rules)

return function(): number
	local count = 0
	local function check(value: boolean, message: string)
		assert(value, message)
		count += 1
	end
	local function waitFor(message: string, condition: () -> boolean, timeout: number)
		local deadline = os.clock() + timeout
		while not condition() and os.clock() < deadline do
			task.wait(0.05)
		end
		check(condition(), `Factory live fixture timed out: {message}`)
	end
	local player: Player? = nil
	waitFor("first assigned character", function()
		player = Players:GetPlayers()[1]
		return player ~= nil
			and player.Character ~= nil
			and typeof(player:GetAttribute(Config.Attributes.PlotId)) == "number"
	end, 12)
	assert(player, "Live fixture player missing")
	local character = player.Character
	assert(character, "Live fixture character missing")
	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	assert(humanoid and root and root:IsA("BasePart"), "Live fixture humanoid/root missing")
	local plotId = player:GetAttribute(Config.Attributes.PlotId)
	local runtime = workspace:FindFirstChild(Config.RuntimeName)
	local plot = runtime and runtime:FindFirstChild(`Plot{plotId}`)
	local pad = plot and plot:FindFirstChild("Pad_income_booster")
	assert(pad and pad:IsA("BasePart"), "Live fixture own starter pad missing")
	local function cash(): number
		local value = player:GetAttribute(Config.Attributes.Cash)
		assert(typeof(value) == "number", "Live fixture cash unavailable")
		return value
	end
	check(cash() < 10, "Live unaffordable fixture needs a fresh start below 10 cash")
	local deductions = 0
	local previous = cash()
	local changed = player:GetAttributeChangedSignal(Config.Attributes.Cash):Connect(function()
		local value = cash()
		if value < previous then
			check(previous - value == 10, "Live exact ten-cash deduction")
			deductions += 1
		end
		previous = value
	end)
	character:PivotTo(pad.CFrame * CFrame.new(0, 3, 6))
	task.wait(0.3)
	print("EXP02 LIVE FIXTURE: seed outside pad; following traversal is Humanoid walking, not native W/touch input.")
	humanoid:MoveTo((pad.CFrame * CFrame.new(0, 3, 0)).Position)
	waitFor("root walks into unaffordable pad", function()
		return Rules.contains(pad.CFrame:PointToObjectSpace(root.Position), pad.Size, false)
	end, 5)
	task.wait(1)
	check(
		player:GetAttribute(Catalogue.purchaseAttribute("income_booster")) == false,
		"Unaffordable live entry refused"
	)
	waitFor("ordinary income funds standing player", function()
		return cash() >= 12
	end, 15)
	check(
		player:GetAttribute(Catalogue.purchaseAttribute("income_booster")) == false and deductions == 0,
		"Standing through funding does not purchase"
	)
	humanoid:MoveTo((pad.CFrame * CFrame.new(0, 3, 6)).Position)
	waitFor("root exits hysteresis region", function()
		return not Rules.contains(pad.CFrame:PointToObjectSpace(root.Position), pad.Size, true)
	end, 5)
	task.wait(0.15)
	humanoid:MoveTo((pad.CFrame * CFrame.new(0, 3, 0)).Position)
	waitFor("funded re-entry automatically purchases", function()
		return player:GetAttribute(Catalogue.purchaseAttribute("income_booster")) == true
	end, 5)
	check(player:GetAttribute(Config.Attributes.IncomeRate) == 2, "Live rate rises from one to two")
	check(deductions == 1, "One live deduction")
	task.wait(3)
	check(deductions == 1, "Staying bought pad cannot repeat charge")
	local upgrades = plot and plot:FindFirstChild("Upgrades")
	check(
		upgrades ~= nil and upgrades:FindFirstChild("income_booster") ~= nil,
		"Purchased machine is replicated in world"
	)
	changed:Disconnect()
	print(
		"EXP02 LIVE FIXTURE complete: automatic walk-on, unaffordable stay, funded re-entry, exact charge/rate, persistent machine, no repeat."
	)
	return count
end
