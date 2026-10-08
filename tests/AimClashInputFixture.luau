--!strict

-- EDIT-only, disposable-copy input adapter check. Extends ONLY the first circle
-- to 27 seconds (30-second interval), allowing observation-driven native clicks.
-- It proves click/tap coordinates and authority, never normal reaction difficulty.
-- Regenerate/open the normal preview afterwards to restore the default schedule.
return function()
	local RunService = game:GetService("RunService")
	assert(RunService:IsStudio() and not RunService:IsRunning(), "Input fixture requires stopped Studio Edit")
	local module = game:GetService("ReplicatedStorage").TycoonShared.Experiments.AimClash.Rules
	local before = "local interval = if section == 0 then 1 else if section == 1 then 0.7 else 0.46"
	local after =
		"local interval = if index == 1 then 30 else if section == 0 then 1 else if section == 1 then 0.7 else 0.46"
	local position = string.find(module.Source, before, 1, true)
	assert(position, "Input fixture expected exact default interval source; regenerate preview first")
	module.Source = string.sub(module.Source, 1, position - 1) .. after .. string.sub(module.Source, position + #before)
	-- Default-duration assertions do not apply to this deliberate timing fixture.
	local runner = game:GetService("ServerScriptService"):FindFirstChild("RunExperimentAssertions")
	if runner and runner:IsA("Script") then
		runner.Disabled = true
	end
	print(
		"EXP03 INPUT FIXTURE: first circle 27s, following schedule unchanged; native coordinates only, not reaction timing."
	)
end
