--!strict

-- Opt-in on each actual Play client. replay=true manufactures individual aim
-- inputs through the real remote; it is a network fixture, NOT native reaction.
-- replay=false observes a round started/played through ordinary UI only.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Rules = require(ReplicatedStorage.TycoonShared.Experiments.AimClash.Rules)

return function(replay: boolean, quiet: boolean?): number
	local player = Players.LocalPlayer
	assert(player and RunService:IsClient(), "Clash observer requires an actual Play client")
	local remote = ReplicatedStorage:FindFirstChild(Rules.RemoteName)
	assert(remote and remote:IsA("RemoteEvent"), "Clash observer channel missing")
	local gui = player.PlayerGui:FindFirstChild("AimClash")
	assert(gui and gui:IsA("ScreenGui"), "Clash observer UI missing")
	local target = gui:FindFirstChild("Target", true)
	local trail = gui:FindFirstChild("AnticipationTrail", true)
	local arena = gui:FindFirstChild("Arena", true)
	local resultGui = gui:FindFirstChild("Result", true)
	local status = gui:FindFirstChild("Status", true)
	assert(
		target and target:IsA("TextLabel") and trail and trail:IsA("Frame") and arena and arena:IsA("Frame"),
		"Clash observer widgets missing"
	)
	assert(
		resultGui and resultGui:IsA("Frame") and status and status:IsA("TextLabel"),
		"Clash observer result/status missing"
	)
	local checks, packets, quietFrames = 0, 0, 0
	local started: any = nil
	local ended: any = nil
	local trailSeen, heatSeen = false, false
	local phases: { [string]: boolean } = {}
	local samples: { number } = {}
	local function check(value: boolean, message: string)
		assert(value, message)
		checks += 1
	end
	local inputFailures = 0
	local events = remote.OnClientEvent:Connect(function(packet: any)
		if packet.kind == "start" then
			started = packet
			check(not packet.practice, "Observer expects a real two-player duel")
			check(packet.other == nil and packet.winner == nil, "Start does not reveal comparison")
			print("EXP03 NETWORK start:", player.Name, packet.id, packet.seed, packet.start, "scripted input", replay)
			if replay then
				task.spawn(function()
					local pattern = Rules.pattern(packet.seed)
					for index, circle in pattern do
						if packet.actor == 2 and index <= 4 then
							continue
						end
						local time = packet.start + circle.at + circle.lifetime * 0.35
						while workspace:GetServerTimeNow() < time do
							RunService.Heartbeat:Wait()
						end
						remote:FireServer("input", packet.id, workspace:GetServerTimeNow(), circle.x, circle.y)
					end
				end)
			end
		elseif packet.kind == "own" and started and packet.id == started.id then
			assert(
				packet.other == nil and packet.winner == nil and packet.opponentScore == nil,
				"Live packet leaked opponent score"
			)
			assert(packet.own.other == nil and packet.own.winner == nil, "Own projection leaked comparison")
			packets += 1
			local border = arena:FindFirstChildWhichIsA("UIStroke")
			if packet.own.combo >= 10 and border and border.Color.R > 0.9 then
				heatSeen = true
			end
			if string.find(packet.own.message, "Late") then
				inputFailures += 1
			end
		elseif packet.kind == "result" and started and packet.id == started.id then
			ended = packet
		end
	end)
	local frames = RunService.RenderStepped:Connect(function(delta)
		if not started or ended then
			return
		end
		trailSeen = trailSeen or (trail.Visible and target.Visible)
		if quiet then
			local border = arena:FindFirstChildWhichIsA("UIStroke")
			assert(border and border.Thickness == 3, "Actual reduced-motion perimeter must not pulse")
			quietFrames += 1
		end
		for _, name in { "FOCUS", "FASTER", "FINAL SURGE" } do
			if string.find(status.Text, name) then
				phases[name] = true
			end
		end
		if #samples < 180 then
			table.insert(samples, delta * 1000)
		end
	end)
	local deadline = os.clock() + 180
	while not ended and os.clock() < deadline do
		task.wait(0.05)
	end
	events:Disconnect()
	frames:Disconnect()
	check(started ~= nil and ended ~= nil, "Network observer timed out waiting for a complete queued duel")
	check(
		workspace:GetServerTimeNow() >= started.start + Rules.duration(Rules.pattern(started.seed)),
		"Result waits for nominal end"
	)
	check(ended.other ~= nil and ended.own ~= nil, "Only final packet contains both breakdowns")
	check(packets > 0 and inputFailures == 0, "Private live updates and bounded local network inputs")
	check(trailSeen, "Actual trail and active target rendered together")
	check(phases.FOCUS and phases.FASTER and phases["FINAL SURGE"], "All acceleration phases rendered")
	check(arena.AbsoluteSize.X == arena.AbsoluteSize.Y, "Circular arena remains square")
	check(
		target.AbsoluteSize.X == target.AbsoluteSize.Y and target.TextColor3 ~= target.BackgroundColor3,
		"Target preserves size and contrast"
	)
	check(gui.IgnoreGuiInset and gui.ScreenInsets == Enum.ScreenInsets.None, "Input uses whole-viewport coordinates")
	local motion = gui:FindFirstChild("Motion", true)
	check(
		motion ~= nil and motion:IsA("TextButton") and (string.find(motion.Text, "reduced") ~= nil) == (quiet == true),
		"Observed native motion toggle matches requested mode"
	)
	if quiet then
		check(quietFrames > 0, "Reduced motion checked during actual rendered clash frames")
	end
	if replay then
		check(heatSeen, "Own validated combo drives actual hot perimeter")
		check(ended.winner == 1, "Center replay beats selective late replay")
		check(
			ended.own.hits == (if started.actor == 1 then 24 else 20),
			"Individual real-remote judgements match scripted opportunities"
		)
		check(ended.own.inaccurate == 0, "No unintended network input penalty")
		check(
			math.abs(ended.own.precision - (if started.actor == 1 then 100 else 100 * 20 / 24)) < 0.001,
			"Actual server precision ignores extras"
		)
	end
	task.wait(0.15)
	local ownText = gui:FindFirstChild("OwnBreakdown", true)
	local otherText = gui:FindFirstChild("OtherBreakdown", true)
	check(resultGui.Visible and not target.Visible, "Final UI replaces targets")
	check(
		ownText ~= nil
			and ownText:IsA("TextLabel")
			and string.find(ownText.Text, "Combo Extra points") ~= nil
			and string.find(ownText.Text, "Precision percentage") ~= nil,
		"Own final labels are explicit"
	)
	check(
		otherText ~= nil and otherText:IsA("TextLabel") and string.find(otherText.Text, "Precision percentage") ~= nil,
		"Opponent breakdown appears at end"
	)
	for _, member in Players:GetPlayers() do
		check(
			member:GetAttribute("AimClashScore") == nil and member:GetAttribute("AimClashState") == nil,
			"No public score attributes"
		)
	end
	table.sort(samples)
	print(
		"EXP03 NETWORK result:",
		player.Name,
		"assertions",
		checks,
		"private packets",
		packets,
		"winner",
		ended.winner,
		"actor",
		ended.actor,
		"own/other points",
		ended.own.total,
		ended.other.total,
		"precision",
		ended.own.precision,
		"frame p95/max ms",
		samples[math.max(1, math.ceil(#samples * 0.95))],
		samples[#samples]
	)
	return checks
end
