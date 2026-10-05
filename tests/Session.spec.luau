--!strict

-- Standalone Studio test module, outside all Rojo mappings; never runs in the game.
-- Invoke the returned function with the actual server Session module and shared Config.
return function(Session: any, Config: any): number
	local checks = 0
	local function check(condition: boolean, message: string)
		assert(condition, message)
		checks += 1
	end
	local function unchanged(state: any, before: any)
		for _, key in { "userId", "plotId", "cash", "incomeRate", "purchased" } do
			check(state[key] == before[key], `Rejected purchase changed {key}`)
		end
	end

	local session = Session.new(Config)
	local first = session:assign(101)
	local second = session:assign(202)
	check(first ~= nil and second ~= nil and first.plotId ~= second.plotId, "Players need unique plots")
	check(first.cash == 0 and first.incomeRate == 1 and not first.purchased, "Fresh prototype defaults")
	check(session:assign(101) == first, "Reassignment/respawn must preserve session state")
	local before = table.clone(first)
	local ok, reason = session:purchase(101, first.plotId)
	check(not ok and reason == "insufficient-cash", "Early purchase must fail")
	unchanged(first, before)
	local seen = { [first.plotId] = true, [second.plotId] = true }
	for userId = 303, 303 + Config.PlotCount - 3 do
		local state = session:assign(userId)
		check(state ~= nil and not seen[state.plotId], "No duplicate ownership at capacity")
		seen[state.plotId] = true
	end
	check(session:assign(999) == nil and session:get(999) == nil, "Full capacity must not grant state")
	session:accrue(0)
	unchanged(first, before)
	session:accrue(9)
	check(first.cash == 9 and second.cash == 9, "Base income accrues independently")
	before = table.clone(first)
	ok, reason = session:purchase(101, first.plotId)
	check(not ok and reason == "insufficient-cash", "One cash short must fail")
	unchanged(first, before)
	session:accrue(1)
	before = table.clone(first)
	local secondBefore = table.clone(second)
	ok, reason = session:purchase(101, second.plotId)
	check(not ok and reason == "not-owner", "Funded non-owner must be rejected")
	unchanged(first, before)
	unchanged(second, secondBefore)
	ok, reason = session:purchase(101, first.plotId)
	check(ok and reason == "purchased", "Exactly funded owner must succeed")
	check(first.cash == 0 and first.incomeRate == 2 and first.purchased, "Exact single deduction and upgrade")
	check(second.cash == 10 and second.incomeRate == 1 and not second.purchased, "Other economy stays independent")
	before = table.clone(first)
	ok, reason = session:purchase(101, first.plotId)
	check(not ok and reason == "already-purchased", "Immediate duplicate must fail")
	unchanged(first, before)
	session:accrue(12)
	check(first.cash == 24 and second.cash == 22, "Post-upgrade income is independent")
	before = table.clone(first)
	ok, reason = session:purchase(101, first.plotId)
	check(not ok and reason == "already-purchased", "Funded replay must fail")
	unchanged(first, before)
	local releasedId = session:release(101)
	check(releasedId == first.plotId and session:get(101) == nil, "Leaving removes the old session")
	check(session:release(101) == nil, "Repeated leave is harmless")
	local replacement = session:assign(404)
	check(replacement ~= nil and replacement.plotId == releasedId, "Released plot must be reused")
	check(replacement.cash == 0 and replacement.incomeRate == 1 and not replacement.purchased, "No old economy leaks")
	before = table.clone(replacement)
	ok, reason = session:purchase(101, releasedId)
	check(not ok and reason == "inactive", "Departed owner cannot affect replacement")
	unchanged(replacement, before)
	session:accrue(1)
	check(replacement.cash == 1 and second.cash == 23, "Replacement starts a fresh economy")
	check(session:assign(404) == replacement, "Respawn also preserves a reused plot")
	return checks
end
