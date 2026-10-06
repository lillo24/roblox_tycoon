--!strict

-- Temporary Studio/server test module outside Rojo; invoke with actual mapped modules.
local SessionTypes = require(game:GetService("ServerScriptService").TycoonServer.Session)
local CatalogueTypes = require(game:GetService("ReplicatedStorage").TycoonShared.UpgradeCatalogue)

return function(Session: typeof(SessionTypes), Config: SessionTypes.Tuning, Catalogue: typeof(CatalogueTypes)): number
	local checks = 0
	local function check(condition: boolean, message: string)
		assert(condition, message)
		checks += 1
	end
	local function snapshot(state: SessionTypes.State): SessionTypes.State
		local copy = table.clone(state)
		copy.purchases = table.clone(state.purchases)
		return copy
	end
	local function unchanged(state: SessionTypes.State, before: SessionTypes.State)
		check(state.userId == before.userId and state.plotId == before.plotId, "Rejected purchase changed assignment")
		check(state.cash == before.cash and state.incomeRate == before.incomeRate, "Rejected purchase changed economy")
		for _, definition in Catalogue.Definitions do
			check(
				state.purchases[definition.Id] == before.purchases[definition.Id],
				`Rejected purchase changed {definition.Id}`
			)
		end
	end
	local function rejected(
		session: SessionTypes.Session,
		state: SessionTypes.State,
		id: string,
		reason: CatalogueTypes.PurchaseReason,
		plotId: number?
	)
		local before = snapshot(state)
		local ok, result = session:purchase(state.userId, plotId or state.plotId, id)
		check(not ok and result == reason, `Expected {reason} for {id}, got {result}`)
		unchanged(state, before)
	end
	local function freshSession(): SessionTypes.Session
		return Session.new(Config, Catalogue.Definitions)
	end
	local function assigned(session: SessionTypes.Session, userId: number): SessionTypes.State
		local state = session:assign(userId)
		assert(state, "Test requires a free plot")
		return state
	end

	check(
		#Catalogue.Definitions == 4 and table.isfrozen(Catalogue.Definitions),
		"Exactly four frozen prototype definitions"
	)
	local expected: { [CatalogueTypes.Id]: { number } } = {
		income_booster = { 10, 1 },
		workshop = { 30, 3 },
		booster_tuning = { 25, 2 },
		workshop_expansion = { 60, 5 },
	}
	for _, definition in Catalogue.Definitions do
		check(table.isfrozen(definition), `Definition {definition.Id} is frozen`)
		check(
			definition.Cost == expected[definition.Id][1] and definition.IncomeDelta == expected[definition.Id][2],
			"Provisional cost/effect contract"
		)
	end

	local session = freshSession()
	local first = assigned(session, 101)
	local second = assigned(session, 202)
	check(first.plotId ~= second.plotId, "Unique plots")
	check(first.cash == 0 and first.incomeRate == 1 and next(first.purchases) == nil, "Original fresh defaults")
	check(session:assign(101) == first, "Respawn/reassignment retains state")
	rejected(session, first, "income_booster", "insufficient-cash")
	local seen = { [first.plotId] = true, [second.plotId] = true }
	for userId = 303, 303 + Config.PlotCount - 3 do
		local state = assigned(session, userId)
		check(not seen[state.plotId], "No duplicate ownership at capacity")
		seen[state.plotId] = true
	end
	check(session:assign(999) == nil and session:get(999) == nil, "Capacity has no waiting economy")
	local before = snapshot(first)
	session:accrue(0)
	unchanged(first, before)
	session:accrue(9)
	check(first.cash == 9 and second.cash == 9, "Base income is independent")
	local ok, reason, missing = session:purchase(101, first.plotId, "income_booster")
	check(not ok and reason == "insufficient-cash" and missing == 1, "Exact missing-cash result")
	session:accrue(1)
	local secondBefore = snapshot(second)
	rejected(session, first, "income_booster", "not-owner", second.plotId)
	unchanged(second, secondBefore)
	rejected(session, first, "unknown_id", "unknown-upgrade")
	ok, reason = session:purchase(101, first.plotId, "income_booster")
	check(ok and reason == "purchased", "Original booster succeeds at exactly 10")
	check(
		first.cash == 0 and first.incomeRate == 2 and first.purchases.income_booster == true,
		"Original single deduction/effect"
	)
	check(second.cash == 10 and second.incomeRate == 1 and next(second.purchases) == nil, "Neighbor is independent")
	rejected(session, first, "income_booster", "already-purchased")
	session:accrue(12)
	check(first.cash == 24 and second.cash == 22, "Independent upgraded income")
	rejected(session, first, "income_booster", "already-purchased")
	check(session:assign(101) == first and first.purchases.income_booster == true, "Respawn keeps actual purchases")

	local lockedSession = freshSession()
	local locked = assigned(lockedSession, 11)
	lockedSession:accrue(200)
	rejected(lockedSession, locked, "booster_tuning", "locked")
	rejected(lockedSession, locked, "workshop_expansion", "locked")
	for _, id in { "income_booster", "booster_tuning", "workshop", "workshop_expansion" } do
		check(lockedSession:purchase(11, locked.plotId, id), `Correct prerequisite allows {id}`)
	end
	check(locked.cash == 75 and locked.incomeRate == 12, "All costs deduct once; deltas sum to 12")
	local complete = snapshot(locked)
	lockedSession:accrue(2)
	check(locked.cash == complete.cash + 24, "Income continues after completion")
	for _, definition in Catalogue.Definitions do
		rejected(lockedSession, locked, definition.Id, "already-purchased")
	end
	check(lockedSession:assign(11) == locked, "Complete catalogue survives respawn")

	-- Either initial upgrade may be first; equal sets have equal rates/deductions.
	local orders: { { CatalogueTypes.Id } } = {
		{ "income_booster", "booster_tuning", "workshop", "workshop_expansion" },
		{ "workshop", "workshop_expansion", "income_booster", "booster_tuning" },
	}
	for _, order in orders do
		local orderedSession = freshSession()
		local owner = assigned(orderedSession, 71)
		orderedSession:accrue(125)
		local cash, income = 125, 1
		for _, id in order do
			local definition = Catalogue.ById[id]
			check(orderedSession:purchase(71, owner.plotId, id), `Valid order accepts {id}`)
			cash -= definition.Cost
			income += definition.IncomeDelta
			check(
				owner.cash == cash and owner.incomeRate == income and owner.purchases[id] == true,
				"Exact additive transition"
			)
		end
		check(owner.cash == 0 and owner.incomeRate == 12, "Order-independent final set")
	end
	local rapidSession = freshSession()
	local rapid = assigned(rapidSession, 81)
	rapidSession:accrue(30)
	check(rapidSession:purchase(81, rapid.plotId, "workshop"), "Workshop can be the first purchase")
	rejected(rapidSession, rapid, "income_booster", "insufficient-cash")
	rejected(rapidSession, rapid, "workshop", "already-purchased")
	check(
		rapid.cash == 0 and rapid.incomeRate == 4 and not rapid.purchases.income_booster,
		"Rapid attempts cannot reuse the spent balance"
	)

	local released = session:release(101)
	check(released == first.plotId and session:get(101) == nil, "Leave removes state")
	check(session:release(101) == nil, "Repeated leave is harmless")
	local replacement = assigned(session, 404)
	check(
		replacement.plotId == released
			and replacement.cash == 0
			and replacement.incomeRate == 1
			and next(replacement.purchases) == nil,
		"Reused plot starts completely fresh"
	)
	before = snapshot(replacement)
	ok, reason = session:purchase(101, replacement.plotId, "workshop")
	check(not ok and reason == "inactive", "Old owner cannot affect replacement")
	unchanged(replacement, before)
	session:accrue(1)
	check(replacement.cash == 1 and second.cash == 23, "New owner and existing neighbor keep independent income")
	check(session:assign(404) == replacement, "Respawn retains the reused plot")

	local function invalid(definitions: { CatalogueTypes.Definition }, errorText: string)
		local accepted, message = pcall(function()
			Session.new(Config, definitions)
		end)
		check(
			not accepted and string.find(tostring(message), errorText, 1, true) ~= nil,
			`Invalid config must report {errorText}`
		)
	end
	local booster: CatalogueTypes.Definition =
		{ Id = "income_booster", DisplayName = "Income Booster", Cost = 10, IncomeDelta = 1 }
	invalid({ booster, booster }, "duplicate ID 'income_booster'")
	invalid(
		{ { Id = "booster_tuning", DisplayName = "Tuning", Cost = 25, IncomeDelta = 2, Requires = "income_booster" } },
		"missing prerequisite 'income_booster'"
	)
	invalid({
		{ Id = "income_booster", DisplayName = "Booster", Cost = 10, IncomeDelta = 1, Requires = "workshop" },
		{ Id = "workshop", DisplayName = "Workshop", Cost = 30, IncomeDelta = 3, Requires = "income_booster" },
	}, "prerequisite cycle")
	for _, value in { 0, -1, 1.5, math.huge, math.huge - math.huge } do
		invalid(
			{ { Id = "income_booster", DisplayName = "Booster", Cost = value, IncomeDelta = 1 } },
			"Cost must be a finite positive integer"
		)
		invalid(
			{ { Id = "income_booster", DisplayName = "Booster", Cost = 10, IncomeDelta = value } },
			"IncomeDelta must be a finite positive integer"
		)
	end
	check(assigned(freshSession(), 901).cash == 0, "Invalid construction leaves subsequent startup intact")
	check(
		Catalogue.stateText(Catalogue.ById.booster_tuning, {}, 200) == "Buy Income Booster first",
		"Locked presentation names prerequisite"
	)
	check(
		Catalogue.stateText(Catalogue.ById.income_booster, {}, 2) == "Need 8 more cash",
		"Presentation uses catalogue cost"
	)
	check(Catalogue.stateText(Catalogue.ById.workshop, {}, 30) == "Buy now", "Affordable presentation")
	check(
		Catalogue.stateText(Catalogue.ById.income_booster, first.purchases, 0) == "Owned",
		"Owned presentation uses purchase set"
	)
	return checks
end
