--!nonstrict
-- Opt-in Studio diagnostic. This script is never mapped to production or the
-- ordinary performance place; its one-shot Output signal is diagnostic overhead.
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local Input = game:GetService("UserInputService")

assert(Run:IsStudio(), "PERF03 capture is Studio only")
local player = Players.LocalPlayer
local control = Replicated:WaitForChild("PERF01")
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.DisplayOrder = "PERF03Capture", false, 51
gui.Parent = player.PlayerGui

local function button(text, y)
	local item = Instance.new("TextButton")
	item.Text, item.Size, item.Position = text, UDim2.fromOffset(215, 32), UDim2.fromOffset(8, y)
	item.Parent = gui
	return item
end

local armButton = button("PERF03 arm foreground", 112)
local calibrateButton = button("PERF03 test 100 ms stall", 148)
local status = Instance.new("TextLabel")
status.Text, status.Size, status.Position = "PERF03 disarmed", UDim2.fromOffset(335, 46), UDim2.fromOffset(8, 184)
status.BackgroundColor3 = Color3.fromRGB(30, 38, 45)
status.TextColor3 = Color3.fromRGB(255, 255, 255)
status.TextWrapped = true
status.Parent = gui

local armed, fired, calibrateNext, awaitingCalibration = false, false, false, false
local frame, runNumber = 0, 0
local phase = control:GetAttribute("Phase")
local function disarm(reason)
	armed, calibrateNext, awaitingCalibration = false, false, false
	status.Text = "PERF03 disarmed: " .. reason
	status.BackgroundColor3 = Color3.fromRGB(30, 38, 45)
end

local armedClick = armButton.Activated:Connect(function()
	-- This native viewport click selects the actual observer; WindowFocused was
	-- unreliable for identifying inactive Studio test clients in PERF-02.
	armed, fired = true, false
	status.Text = "PERF03 armed: leave profiler recording"
	status.BackgroundColor3 = Color3.fromRGB(35, 85, 45)
end)
local testClick = calibrateButton.Activated:Connect(function()
	-- Run only in a separate diagnostic scene before measuring natural hitches.
	-- A busy frame checks signal/reaction time, not game performance.
	if armed and phase == "Idle" then
		calibrateNext = true
		status.Text = "PERF03 calibration pending"
	end
end)
local blurred = Input.WindowFocusReleased:Connect(function()
	disarm("viewport lost focus")
end)
local changed = control:GetAttributeChangedSignal("Phase"):Connect(function()
	local newPhase = control:GetAttribute("Phase")
	if newPhase ~= phase then
		phase, frame = newPhase, 0
		runNumber += 1
		if phase == "Idle" then
			disarm("run complete")
		end
	end
end)
local render = Run.PreRender:Connect(function(delta)
	frame += 1
	if calibrateNext then
		calibrateNext, awaitingCalibration = false, true
		debug.profilebegin("PERF03 deliberate calibration stall")
		local started = os.clock()
		while os.clock() - started < 0.1 do end
		debug.profileend()
		-- The stall extends the NEXT PreRender interval; this callback's delta
		-- describes time before the deliberate work and cannot validate it.
		return
	end
	if not armed or fired or delta <= 0.05 then
		return
	end
	local calibration = awaitingCalibration
	if phase ~= "Churn" and phase ~= "Quiet" and not calibration then
		return
	end
	fired, awaitingCalibration = true, false
	local clock, serverTime = os.clock(), workspace:GetServerTimeNow()
	-- The label and signal follow the interval; they do not identify its cause.
	debug.profilebegin("PERF03 slow interval observed")
	print(string.format(
		"PERF03_SIGNAL run=%d phase=%s frame=%d intervalMs=%.3f clock=%.6f serverTime=%.6f calibration=%s",
		runNumber, tostring(phase), frame, delta * 1000, clock, serverTime, tostring(calibration)
	))
	debug.profileend()
	status.Text = if calibration then "PERF03 TEST HITCH: pause profiler Ctrl+P" else "PERF03 HITCH: pause profiler Ctrl+P"
	status.BackgroundColor3 = Color3.fromRGB(160, 30, 35)
end)
script.Destroying:Connect(function()
	armedClick:Disconnect()
	testClick:Disconnect()
	blurred:Disconnect()
	changed:Disconnect()
	render:Disconnect()
	gui:Destroy()
end)
