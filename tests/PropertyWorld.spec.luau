--!strict

-- Edit-only, actual saved map. Always destroys temporary runtime geometry.
local Server = game:GetService("ServerScriptService").TycoonServer
local World = require(Server.PlotWorld)
local Schema = require(Server.Persistence.ProfileSchema)
local Config = require(game:GetService("ReplicatedStorage").TycoonShared.Config)

return function(): number
	assert(not game:GetService("RunService"):IsRunning(), "PropertyWorld assertions require Edit mode")
	local checks = 0
	local function check(value: boolean, message: string)
		assert(value, "INF01 property world: " .. message)
		checks += 1
	end
	local ok, issue = xpcall(function()
		local layout = World.inspect()
		local plots = World.create(layout)
		local data = Schema.capture(91, { income_booster = true, workshop = true }, Schema.new())
		data.placements.income_booster, data.placements.workshop = "east_back", "west_front"
		local expectedPositions: { [string]: Vector3 } =
			{ income_booster = Vector3.new(18, 0.25, 5), workshop = Vector3.new(-18, 0.25, -10) }
		for index, plot in plots do
			World.reconcile(plot, data.assets, data.cash, data.placements)
			check(#plot.upgrades:GetChildren() == 2, "returning property recreates exactly its assets")
			for id, position in expectedPositions do
				local model = plot.upgrades:FindFirstChild(id)
				assert(model, "Restored equipment missing")
				local base = model:FindFirstChild("Base")
				assert(base and base:IsA("Part"), "Restored base missing")
				check(
					(layout.lots[index].frame:PointToObjectSpace(base.Position) - position).Magnitude < 0.001,
					"saved slot restores relative to each oriented lot"
				)
				check(
					base.CFrame.LookVector:Dot(layout.lots[index].frame.LookVector) > 0.999,
					"restored machine rotates with the lot"
				)
			end
			World.setOwner(plot, nil)
			check(
				#plot.upgrades:GetChildren() == 0 and plot.model:GetAttribute(Config.Attributes.OwnerUserId) == nil,
				"departure removes owned equipment and owner identity"
			)
			for _, pad in plot.pads do
				check(not pad.prompt.Enabled, "vacant lot cannot accept purchases")
			end
			World.reconcile(plot, {}, 0, {})
			check(#plot.upgrades:GetChildren() == 0, "fresh replacement has no previous equipment")
		end
		return true
	end, function(failure: any): string
		return debug.traceback(tostring(failure))
	end)
	local runtime = workspace:FindFirstChild(Config.RuntimeName)
	if runtime then
		runtime:Destroy()
	end
	assert(ok, tostring(issue))
	return checks
end
