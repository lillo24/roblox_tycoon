--!strict

local Rules = {}
Rules.RemoteName = "FactoryWalkOn"
Rules.SampleInterval = 0.05
Rules.OfferLifetime = 0.75
Rules.ExitSlack = 0.6
Rules.AnimationDuration = 0.55
Rules.ActivityDistance = 140
Rules.ActivityInterval = 1 / 30

-- Root-center occupancy of the oriented pad. A small entry margin and a larger
-- exit margin prevent physics jitter from creating repeated visits.
function Rules.contains(point: Vector3, size: Vector3, exiting: boolean): boolean
	local slack = if exiting then Rules.ExitSlack else 0.1
	return math.abs(point.X) <= size.X / 2 + slack
		and math.abs(point.Z) <= size.Z / 2 + slack
		and point.Y >= -0.5
		and point.Y <= 6 + (if exiting then slack else 0)
end

function Rules.canRespond(panelOpen: boolean, menuOpen: boolean, promptsEnabled: boolean, focused: boolean): boolean
	return not panelOpen and not menuOpen and promptsEnabled and focused
end

return table.freeze(Rules)
