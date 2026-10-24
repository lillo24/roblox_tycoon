--!strict

-- Opt-in actual Play-client observer. Never changes preferences, camera, input,
-- cash, models or effects. Toggle reduced motion through the native Settings UI.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Config = require(game:GetService("ReplicatedStorage").TycoonShared.Config)

return function(reduced: boolean): (number, number, number, number)
	local count, units = 0, 0
	local function check(value: boolean, message: string)
		assert(value, message)
		count += 1
	end
	local player = Players.LocalPlayer
	assert(player and RunService:IsClient(), "Factory presentation observer requires actual client")
	local runtime = workspace:FindFirstChild(Config.RuntimeName)
	assert(runtime, "Factory presentation runtime missing")
	for _, item in runtime:GetDescendants() do
		if item:IsA("Folder") and item.Name == "LocalFactoryActivity" then
			units += 1
			check(#item:GetChildren() == 3, "Only three local decorative parts per machine")
			for _, part in item:GetChildren() do
				check(
					part:IsA("BasePart")
						and part.Anchored
						and not part.CanCollide
						and not part.CanTouch
						and not part.CanQuery,
					"Activity cannot create physics/query objects"
				)
			end
			local model = item.Parent
			assert(model, "Activity model missing")
			local plot = if model.Parent and model.Parent.Name == "Upgrades" then model.Parent.Parent else model.Parent
			local product = item:FindFirstChild("SimulatedOutput1")
			assert(plot and product and product:IsA("BasePart"), "Activity ownership/output missing")
			check(
				product.Transparency == (if plot:GetAttribute(Config.Attributes.OwnerUserId) ~= nil then 0 else 1),
				"Only owned factories show active production"
			)
		end
	end
	local plot = runtime:FindFirstChild(`Plot{player:GetAttribute(Config.Attributes.PlotId)}`)
	local upgrades = plot and plot:FindFirstChild("Upgrades")
	local machine = upgrades and upgrades:FindFirstChild("income_booster")
	local activity = machine and machine:FindFirstChild("LocalFactoryActivity")
	local product = activity and activity:FindFirstChild("SimulatedOutput1")
	assert(product and product:IsA("BasePart"), "Factory observer needs live purchased booster")
	task.wait(0.3)
	local before = product.CFrame
	task.wait(0.25)
	check((before == product.CFrame) == reduced, "Actual output moves normally and freezes in reduced motion")
	local samples: { number } = {}
	for _ = 1, 180 do
		table.insert(samples, RunService.RenderStepped:Wait() * 1000)
	end
	table.sort(samples)
	local p95, maximum = samples[171], samples[180]
	print(
		"EXP02 ACTUAL client presentation:",
		count,
		"units",
		units,
		"reduced",
		reduced,
		"frame p95/max ms",
		p95,
		maximum
	)
	return count, units, p95, maximum
end
