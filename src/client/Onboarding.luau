--!strict

local State = require(script.Parent.UiState)
local Onboarding = {}
export type Progress = { completed: boolean, dismissed: boolean, acknowledgement: number?, replay: boolean }

function Onboarding.new(): Progress
	return { completed = false, dismissed = false, acknowledgement = nil, replay = false }
end

-- Client-session memory; separate from interface preferences and character/HUD life.
local session = Onboarding.new()
function Onboarding.session(): Progress
	return session
end

function Onboarding.observe(progress: Progress, economy: State.Economy, now: number)
	if economy.assigned and economy.count > 0 and not progress.completed then
		progress.completed = true
		progress.replay = false
		progress.acknowledgement = if progress.dismissed then nil else now + 4
	end
end

function Onboarding.dismiss(progress: Progress)
	progress.dismissed, progress.acknowledgement, progress.replay = true, nil, false
end

function Onboarding.restart(progress: Progress)
	-- Completion is retained; Help explicitly reopens guidance, not a new tutorial.
	progress.dismissed, progress.acknowledgement, progress.replay = false, nil, true
end

function Onboarding.text(progress: Progress, economy: State.Economy, now: number): string
	if progress.dismissed or not economy.assigned then
		return ""
	end
	if progress.completed then
		if progress.replay then
			return Onboarding.help(progress, economy)
		end
		return if progress.acknowledgement and now < progress.acknowledgement
			then "First upgrade owned. Income continues automatically."
			else ""
	end
	return "Your factory is assigned. Use Factory → Find my factory. Cash grows automatically; buy any available upgrade at its world pad."
end

function Onboarding.help(progress: Progress, economy: State.Economy): string
	if economy.unavailable then
		return "Factory state unavailable. Help and Settings remain usable."
	end
	if not economy.assigned then
		return if economy.full
			then "Factories are full. There is no waiting queue this session."
			else "Factory assignment is pending."
	end
	return if progress.completed
		then "First purchase complete. Find your factory from Factory; use its world pads for further available upgrades."
		else "Find your assigned factory from Factory. Cash accrues automatically. Any available first upgrade completes this guidance."
end

return Onboarding
