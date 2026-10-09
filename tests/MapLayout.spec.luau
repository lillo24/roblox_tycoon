--!strict

-- Run in Edit against the actual saved map; mutations are restored even on failure.
local Map = require(game:GetService("ServerScriptService").TycoonServer.MapLayout)
local World = require(game:GetService("ServerScriptService").TycoonServer.PlotWorld)
local Catalogue = require(game:GetService("ReplicatedStorage").TycoonShared.UpgradeCatalogue)
local Config = require(game:GetService("ReplicatedStorage").TycoonShared.Config)

return function(): number
	local checks = 0
	local function check(value: boolean, message: string)
		assert(value, message)
		checks += 1
	end
	local layout = World.inspect()
	check(#layout.lots == 6, "Six actual saved lots")
	for i, lot in layout.lots do
		check((lot.entrance.Position - layout.cache.Position).Magnitude > 70, "Generous inward route")
		check(lot.frame.LookVector:Dot((layout.cache.Position - lot.frame.Position).Unit) > 0.999, "Inward orientation")
		for j = i + 1, 6 do
			check(Map.gap(lot, layout.lots[j]) > 22, "Actual oriented foundations have clearance")
		end
	end
	check(Map.gap(layout.lots[1], layout.lots[1]) == 0, "SAT detects actual footprint intersection")
	local first = layout.lots[1].foundation.Parent
	assert(first, "Saved foundation must have a lot parent")
	local anchor = first:FindFirstChild("Anchor")
	assert(anchor, "Saved lot must have Anchor")
	anchor.Name = "MissingAnchor"
	local ok, message = pcall(World.inspect)
	anchor.Name = "Anchor"
	check(
		not ok and string.find(tostring(message), "/Anchor expected once", 1, true) ~= nil,
		"Missing anchor fails before runtime"
	)
	local duplicate = anchor:Clone()
	duplicate.Parent = first
	ok, message = pcall(World.inspect)
	duplicate:Destroy()
	check(not ok and string.find(tostring(message), "found 2", 1, true) ~= nil, "Duplicate anchor fails")
	first:SetAttribute("LotId", 7)
	ok, message = pcall(World.inspect)
	first:SetAttribute("LotId", 1)
	check(not ok and string.find(tostring(message), "wrong stable LotId", 1, true) ~= nil, "Wrong stable ID fails")
	assert(anchor:IsA("Part"), "Saved Anchor must be Part")
	local originalAnchor, originalFloor = anchor.CFrame, layout.lots[1].foundation.CFrame
	anchor.CFrame = anchor.CFrame * CFrame.Angles(0, math.pi, 0)
	layout.lots[1].foundation.CFrame = anchor.CFrame * CFrame.new(0, -layout.lots[1].foundation.Size.Y / 2, 0)
	ok, message = pcall(World.inspect)
	anchor.CFrame, layout.lots[1].foundation.CFrame = originalAnchor, originalFloor
	check(not ok and string.find(tostring(message), "front must face", 1, true) ~= nil, "Wrong facing fails")
	local second = layout.lots[2].foundation.Parent
	assert(second and second:IsA("Model"), "Second saved lot must be Model")
	local originalPivot = second:GetPivot()
	second:PivotTo(layout.lots[1].frame * layout.lots[2].frame:Inverse() * originalPivot)
	ok, message = pcall(World.inspect)
	second:PivotTo(originalPivot)
	check(
		not ok and string.find(tostring(message), "footprints intersect", 1, true) ~= nil,
		"Intersecting actual saved lots fail"
	)
	local obstacle = Instance.new("Part")
	obstacle.Name, obstacle.Anchored, obstacle.Size = "MAP01_BlockerProbe", true, Vector3.new(3, 4, 3)
	obstacle.CFrame = layout.lots[1].frame * CFrame.new(-10, 2, -15)
	obstacle.Parent = workspace
	ok, message = pcall(World.inspect)
	obstacle:Destroy()
	check(not ok and string.find(tostring(message), "interaction blocked", 1, true) ~= nil, "Blocked interaction fails")
	check(workspace:FindFirstChild(Config.RuntimeName) == nil, "Rejected preflight leaves no partial runtime")
	local success, result = xpcall(function()
		local plots = World.create(World.inspect())
		for i, plot in plots do
			local lot = layout.lots[i]
			World.reconcile(
				plot,
				{ income_booster = true, workshop = true, booster_tuning = true, workshop_expansion = true },
				0
			)
			for _, definition in Catalogue.Definitions do
				local pad = plot.pads[definition.Id].part
				local localPosition = lot.frame:PointToObjectSpace(pad.Position)
				check(
					math.abs(math.abs(localPosition.X) - 10) < 0.001
						and math.abs(localPosition.Z) <= 15.01
						and localPosition.Y > 0,
					"Pads above actual rotated foundation"
				)
				check(pad.CFrame.LookVector:Dot(lot.frame.LookVector) > 0.999, "Pad faces with lot")
			end
			for _, p in plot.upgrades:GetDescendants() do
				if p:IsA("BasePart") then
					local localPosition = lot.frame:PointToObjectSpace(p.Position)
					check(
						math.abs(localPosition.X) + p.Size.X / 2 < 30 and math.abs(localPosition.Z) + p.Size.Z / 2 < 35,
						"Purchased equipment stays inside its lot"
					)
					check(p.Anchored and not p.CanTouch, "No decorative physics/touch processing")
				end
			end
			World.reconcile(plot, {}, 0)
			check(#plot.upgrades:GetChildren() == 0, "Reset removes equipment, retains authored floor")
		end
		return checks
	end, function(errorText: string): string
		return debug.traceback(errorText)
	end)
	local runtime = workspace:FindFirstChild(Config.RuntimeName)
	if runtime then
		runtime:Destroy()
	end
	assert(success, tostring(result))
	return checks
end
