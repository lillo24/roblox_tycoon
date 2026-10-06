--!strict

-- Standalone Studio runner, actual client helper, supplied times and ordered inputs.
local FeedbackTypes = require(game:GetService("StarterPlayer").StarterPlayerScripts.TycoonClient.SupplyFeedback)

return function(Feedback: typeof(FeedbackTypes)): number
	local checks = 0
	local function check(condition: boolean, message: string)
		assert(condition, message)
		checks += 1
	end
	local function fresh(): FeedbackTypes.State
		return Feedback.new(3)
	end
	local function shown(state: FeedbackTypes.State, now: number, expected: string)
		check(state:read(now) == expected, `At {now}, expected private text '{expected}'`)
	end

	-- Matching current feedback displays immediately for the ordinary lifetime.
	local current = fresh()
	current:snapshot(10, false, 0)
	local token = current:receive(10, "Claimed +10 cash", 1)
	check(token ~= nil, "Current feedback accepted")
	shown(current, 1, "Claimed +10 cash")
	shown(current, 3.999, "Claimed +10 cash")
	shown(current, 4, "")

	-- The old equality guard lost this response; future text waits for its snapshot.
	local reordered = fresh()
	reordered:snapshot(10, false, 0)
	reordered:receive(11, "FIX01 ordered response", 0.5)
	shown(reordered, 0.5, "")
	reordered:snapshot(11, false, 1)
	shown(reordered, 1, "FIX01 ordered response")
	shown(reordered, 3.499, "FIX01 ordered response")
	shown(reordered, 3.5, "") -- Snapshot arrival did not restart receipt lifetime.

	-- Initialization may receive feedback before any usable snapshot.
	local initial = fresh()
	initial:receive(7, "Initial response", 0)
	shown(initial, 0.2, "")
	initial:snapshot(7, false, 1)
	shown(initial, 1, "Initial response")
	shown(initial, 3, "")

	-- An intermediate public ID must preserve a result for a still-newer ID.
	local intermediate = fresh()
	intermediate:snapshot(20, false, 0)
	intermediate:receive(22, "Future response", 0.1)
	intermediate:snapshot(21, false, 0.2)
	shown(intermediate, 0.2, "")
	intermediate:snapshot(22, false, 0.3)
	shown(intermediate, 0.3, "Future response")

	-- Truly stale responses cannot replace current feedback or refresh its expiry.
	local stale = fresh()
	stale:snapshot(21, false, 0)
	stale:receive(21, "Current response", 1)
	check(stale:receive(20, "Stale response", 2) == nil, "Old event response rejected")
	shown(stale, 2, "Current response")
	shown(stale, 4, "")

	-- A snapshot jumping beyond pending feedback discards it permanently.
	local skipped = fresh()
	skipped:snapshot(1, false, 0)
	skipped:receive(3, "Skipped response", 0.1)
	skipped:snapshot(4, false, 0.2)
	shown(skipped, 0.2, "")
	check(skipped:receive(3, "Skipped response", 0.3) == nil, "Skipped feedback remains stale")
	shown(skipped, 0.3, "")

	-- Keep only the latest relevant result; older messages cannot overwrite pending.
	local pending = fresh()
	pending:snapshot(1, false, 0)
	local oldPending = pending:receive(4, "Older pending", 0)
	check(pending:receive(3, "Out of order", 0.1) == nil, "Older pending input rejected")
	pending:receive(5, "Newest pending", 1)
	check(pending:receive(4, "Older pending", 2) == nil, "Newest pending cannot be overwritten")
	pending:snapshot(4, false, 2.1)
	shown(pending, 2.1, "")
	pending:snapshot(5, false, 2.2)
	shown(pending, 2.2, "Newest pending")
	assert(oldPending, "Pending feedback token required")
	check(not pending:expire(oldPending, 3), "Old pending timeout cannot clear newer feedback")
	shown(pending, 3, "Newest pending")
	shown(pending, 4, "")

	-- Identical repeated results refresh the deadline; an old timeout cannot win.
	local repeated = fresh()
	repeated:snapshot(1, false, 0)
	local old = repeated:receive(1, "Already claimed", 0)
	local newest = repeated:receive(1, "Already claimed", 1)
	assert(old and newest, "Repeat tokens required")
	check(old ~= newest, "Identical repeats invalidate the older timeout")
	check(not repeated:expire(old, 3), "Old repeat timeout ignored")
	shown(repeated, 3, "Already claimed")
	check(not repeated:expire(newest, 3.999), "Current timeout cannot expire early")
	check(repeated:expire(newest, 4), "Newest repeat expires at its own boundary")
	shown(repeated, 4, "")

	-- Reset clears buffered work and invalidates callbacks from the old scope.
	local reset = fresh()
	reset:snapshot(1, false, 0)
	local beforeReset = reset:receive(2, "Previous assignment", 0)
	reset:reset()
	reset:snapshot(2, false, 1)
	shown(reset, 1, "")
	reset:receive(2, "New assignment", 1.5)
	assert(beforeReset, "Old scope token required")
	check(not reset:expire(beforeReset, 3), "Old reset callback ignored")
	shown(reset, 3, "New assignment")
	shown(reset, 4.5, "")

	-- Matching at/beyond expiry cannot resurrect a buffered message.
	for _, arrival in { 3, 3.001, 10 } do
		local expired = fresh()
		expired:receive(2, "Expired pending", 0)
		expired:snapshot(2, false, arrival)
		shown(expired, arrival, "")
	end
	local justBefore = fresh()
	justBefore:receive(2, "Remaining lifetime", 0)
	justBefore:snapshot(2, false, 2.999)
	shown(justBefore, 2.999, "Remaining lifetime")
	shown(justBefore, 3, "")

	-- Phase-only updates preserve feedback, then cancellation clears current/future text.
	local phases = fresh()
	phases:snapshot(3, false, 0)
	phases:receive(3, "Phase response", 0)
	for _, now in { 0.5, 1, 1.5 } do
		phases:snapshot(3, false, now)
		shown(phases, now, "Phase response")
	end
	phases:snapshot(4, true, 2)
	shown(phases, 2, "")
	phases:receive(6, "Pre-cancellation future", 2.1)
	phases:snapshot(5, true, 2.2)
	phases:snapshot(6, false, 2.3)
	shown(phases, 2.3, "")
	phases:receive(6, "New event response", 2.4)
	phases:snapshot(7, false, 2.5)
	shown(phases, 2.5, "")

	-- Unassigned/Full rejection is meaningful even on an initial idle snapshot.
	local unassigned = fresh()
	unassigned:receive(0, "A plot is needed to claim", 0)
	unassigned:snapshot(0, true, 0.1)
	shown(unassigned, 0.1, "A plot is needed to claim")
	unassigned:snapshot(0, true, 0.2)
	shown(unassigned, 0.2, "A plot is needed to claim")
	unassigned:reset() -- Assignment loss/change uses this operation in Hud.
	shown(unassigned, 0.3, "")
	unassigned:receive(0, "A plot is needed to claim", 0.4)
	shown(unassigned, 0.4, "A plot is needed to claim")

	-- Ordinary respawn keeps the same scope; teardown resets and blocks old timers.
	local respawn = fresh()
	respawn:snapshot(7, false, 0)
	local retained = respawn:receive(7, "Respawn retained", 0)
	respawn:snapshot(7, false, 1)
	shown(respawn, 1, "Respawn retained")
	respawn:reset()
	assert(retained, "Teardown token required")
	check(not respawn:expire(retained, 3), "Teardown invalidates old timeout")
	shown(respawn, 3, "")

	-- Older property delivery cannot associate current text with an older public ID.
	local oldSnapshot = fresh()
	oldSnapshot:snapshot(5, false, 0)
	oldSnapshot:receive(5, "Current ID", 0)
	check(not oldSnapshot:snapshot(4, false, 0.1), "Regressive snapshot rejected")
	shown(oldSnapshot, 0.1, "Current ID")

	-- Many inputs still expose only the newest pending result, with no older replay.
	local many = fresh()
	many:snapshot(1, false, 0)
	for id = 2, 1000 do
		many:receive(id, `Response {id}`, 0)
	end
	check(many:receive(999, "Old result", 1) == nil, "Newest retained identity is not overwritten")
	many:snapshot(999, false, 1)
	shown(many, 1, "")
	many:snapshot(1000, false, 2)
	shown(many, 2, "Response 1000")
	shown(many, 3, "")
	check(many:receive(999, "Old after expiry", 3.1) == nil, "Older identity remains stale after expiry")

	for _, duration in { 0, -1, math.huge, 0 / 0 } do
		local ok = pcall(function()
			Feedback.new(duration)
		end)
		check(not ok, "Invalid presentation lifetime rejected")
	end
	return checks
end
