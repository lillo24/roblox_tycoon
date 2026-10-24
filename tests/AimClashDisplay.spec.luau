--!strict

-- Read-only opt-in check on an actual Play client after a completed round.
-- Device emulation validates layout, not physical tapping or device fairness.
return function(): number
	local Players = game:GetService("Players")
	local GuiService = game:GetService("GuiService")
	local player = Players.LocalPlayer
	assert(player and game:GetService("RunService"):IsClient(), "Clash display check requires an actual client")
	local gui = player.PlayerGui:FindFirstChild("AimClash")
	assert(gui and gui:IsA("ScreenGui"), "Clash display check requires active interface")
	local whole = GuiService:GetInsetArea(Enum.ScreenInsets.None)
	local core = GuiService:GetInsetArea(Enum.ScreenInsets.CoreUISafeInsets)
	-- AbsolutePosition and InputObject.Position use the core-relative UI origin;
	-- the full-screen ScreenGui itself has whole.Min as its absolute position.
	local minimum, maximum = core.Min, core.Max
	local count = 0
	local function check(value: boolean, message: string)
		assert(value, message)
		count += 1
	end
	local function widget(name: string): GuiObject
		local object = gui:FindFirstChild(name, true)
		assert(object and object:IsA("GuiObject"), `Clash widget missing: {name}`)
		return object
	end
	check(gui.AbsolutePosition == whole.Min, "Full-screen GUI matches measured UI coordinate origin")
	for _, name in { "Practice", "Queue", "Leave", "Motion", "Arena", "Status", "Feedback", "Result" } do
		local object = widget(name)
		local start, finish = object.AbsolutePosition, object.AbsolutePosition + object.AbsoluteSize
		check(start.X >= minimum.X - 1 and finish.X <= maximum.X + 1, `{name} fits horizontal core-safe bounds`)
		check(start.Y >= minimum.Y - 1 and finish.Y <= maximum.Y + 1, `{name} fits vertical core-safe bounds`)
	end
	local result = widget("Result")
	check(result.Visible, "Display check requires real completed-round UI")
	for _, name in { "Winner", "OwnBreakdown", "OtherBreakdown", "PrecisionRule" } do
		local label = widget(name)
		assert(label:IsA("TextLabel"), `Clash result label missing: {name}`)
		check(label.TextBounds.Y <= label.AbsoluteSize.Y + 1, `{name} text fits actual result height`)
	end
	local arena = widget("Arena")
	local status = widget("Status")
	local feedback = widget("Feedback")
	check(status.AbsolutePosition.Y + status.AbsoluteSize.Y <= arena.AbsolutePosition.Y, "Status clears arena")
	check(arena.AbsolutePosition.Y + arena.AbsoluteSize.Y <= feedback.AbsolutePosition.Y, "Arena clears footer")
	print("EXP03 DISPLAY:", "assertions", count, "viewport", gui.AbsoluteSize, "core-safe", minimum, maximum)
	return count
end
