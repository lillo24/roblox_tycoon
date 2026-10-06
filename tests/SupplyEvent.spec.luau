--!strict

-- Existing standalone Studio route, actual modules, supplied times, no wall-clock waits.
local EventTypes = require(game:GetService("ServerScriptService").TycoonServer.SupplyEvent)
local SessionTypes = require(game:GetService("ServerScriptService").TycoonServer.Session)
local RulesTypes = require(game:GetService("ReplicatedStorage").TycoonShared.SupplyRules)
local CatalogueTypes = require(game:GetService("ReplicatedStorage").TycoonShared.UpgradeCatalogue)

return function(
	Event: typeof(EventTypes),
	Session: typeof(SessionTypes),
	Rules: typeof(RulesTypes),
	Catalogue: typeof(CatalogueTypes)
): number
	local checks = 0
	local function check(value: boolean, message: string)
		assert(value, message)
		checks += 1
	end
	local function fresh(): (EventTypes.Event, SessionTypes.Session, SessionTypes.State, SessionTypes.State)
		local session = Session.new({ PlotCount = 4, StartingCash = 0, BaseIncome = 1 }, Catalogue.Definitions)
		local first, second = session:assign(101), session:assign(202)
		assert(first and second, "Supply tests require two assigned owners")
		local event = Event.new(Rules.Tuning)
		event:sync(0, session:assignedCount())
		return event, session, first, second
	end
	local function economyUnchanged(
		state: SessionTypes.State,
		cash: number,
		rate: number,
		purchases: CatalogueTypes.Purchases
	)
		check(state.cash == cash and state.incomeRate == rate, "Rejected claim changed cash/income")
		for _, definition in Catalogue.Definitions do
			check(state.purchases[definition.Id] == purchases[definition.Id], "Claim changed purchase state")
		end
	end
	local function blocked(
		event: EventTypes.Event,
		session: SessionTypes.Session,
		owner: SessionTypes.State,
		id: number,
		now: number,
		reason: EventTypes.ClaimReason
	)
		local cash, rate, purchases = owner.cash, owner.incomeRate, table.clone(owner.purchases)
		local ok, result = event:claim(session, owner.userId, "Owner", id, now)
		check(not ok and result == reason, `Expected claim {reason}, got {result}`)
		economyUnchanged(owner, cash, rate, purchases)
	end
	local function phase(event: EventTypes.Event, time: number, expected: RulesTypes.Phase, deadline: number)
		event:sync(time, 2)
		local snapshot = event:snapshot()
		check(snapshot.phase == expected and snapshot.deadline == deadline, `At {time}, expected {expected}/{deadline}`)
	end

	-- Exact provisional configuration and initial/timeout cadence.
	check(table.isfrozen(Rules.Tuning), "Rules are immutable")
	check(
		Rules.Tuning.FirstDelay == 20 and Rules.Tuning.Interval == 30 and Rules.Tuning.Warning == 5,
		"Provisional schedule"
	)
	check(
		Rules.Tuning.Window == 10
			and Rules.Tuning.ResultDuration == 3
			and Rules.Tuning.Reward == 10
			and Rules.Tuning.Radius == 6,
		"Provisional claim rules"
	)
	local event, session, first, second = fresh()
	local initial = event:snapshot()
	check(
		initial.opensAt == 20 and initial.closesAt == 30 and initial.nextOpensAt == 20 and initial.reward == 10,
		"First assigned owner anchors schedule"
	)
	check(table.isfrozen(initial), "Public snapshot is immutable")
	phase(event, 14.999, "waiting", 20)
	phase(event, 15, "warning", 20)
	check(event:snapshot().id == initial.id, "Warning retains event identity")
	phase(event, 19.999, "warning", 20)
	blocked(event, session, first, initial.id, 19.999, "closed")
	phase(event, 20, "open", 30)
	phase(event, 29.999, "open", 30)
	phase(event, 30, "result", 33)
	check(
		event:snapshot().winnerUserId == nil and event:snapshot().nextOpensAt == 50,
		"Expiry has no winner and keeps next opening"
	)
	blocked(event, session, first, initial.id, 30, "closed")
	phase(event, 33, "waiting", 50)
	phase(event, 44.999, "waiting", 50)
	phase(event, 45, "warning", 50)
	local secondId = event:snapshot().id
	check(secondId ~= initial.id, "Next warning binds a distinct identity")
	phase(event, 50, "open", 60)
	blocked(event, session, first, initial.id, 50, "stale")
	check(event:claim(session, 202, "Second", secondId, 50), "Valid next opening still claimable after stale attempt")
	check(second.cash == 10 and first.cash == 0, "Stale claim did not pay or consume next cache")

	-- First valid processed competitor wins, exactly +10, no income/unlock; no local-order claim.
	event, session, first, second = fresh()
	session:accrue(10)
	check(session:purchase(101, first.plotId, "income_booster"), "Owner may already have a purchase")
	local purchases = table.clone(first.purchases)
	local id = event:snapshot().id
	local accepted, reason = event:claim(session, 101, "First", id, 20)
	check(accepted and reason == "claimed" and first.cash == 10, "Opening boundary pays exact one-time reward")
	check(first.incomeRate == 2 and first.purchases.income_booster == true, "Reward preserves income and upgrade")
	for _, definition in Catalogue.Definitions do
		check(first.purchases[definition.Id] == purchases[definition.Id], "No reward unlocks")
	end
	blocked(event, session, second, id, 20, "already-claimed")
	blocked(event, session, first, id, 20, "already-claimed")
	check(event:snapshot().winnerUserId == 101 and event:snapshot().winnerName == "First", "One shared winner")
	check(second.cash == 10 and second.incomeRate == 1, "Loser keeps its ordinary economy")
	phase(event, 22.999, "result", 23)
	phase(event, 23, "waiting", 50)
	check(event:snapshot().winnerName == nil, "Result text clears after duration")
	blocked(event, session, second, id, 29.999, "already-claimed")
	blocked(event, session, first, id, 30, "closed")
	phase(event, 45, "warning", 50)
	check(event:snapshot().opensAt == 50, "Early winner cannot accelerate schedule")
	check(event:claim(session, 202, "Second", event:snapshot().id, 50), "Other owner can win a later event")
	check(second.cash == 20, "Second event pays only its current winner")
	session:accrue(2)
	check(first.cash == 14 and second.cash == 22, "Ordinary income continues independently")

	-- Inactive/full player cannot consume a cache or mutate an assigned owner's state.
	event, session, first, second = fresh()
	assert(session:assign(303) and session:assign(404), "Supply capacity test requires four owners")
	check(session:assign(505) == nil and session:assignedCount() == 4, "Unassigned capacity state")
	id = event:snapshot().id
	accepted, reason = event:claim(session, 505, "Full", id, 20)
	check(
		not accepted and reason == "inactive" and event:snapshot().winnerUserId == nil,
		"Unassigned claimant cannot consume event"
	)
	accepted, reason = event:claim(session, 999, "Gone", id, 20)
	check(not accepted and reason == "inactive", "Inactive claimant rejected")
	check(not session:credit(999, 10) and not session:credit(505, 10), "Inactive credits fail explicitly")
	check(first.cash == 0 and second.cash == 0, "Failed claim/credit leaves other balances unchanged")
	check(event:claim(session, 202, "Second", id, 20), "Failure leaves event available")

	-- Delayed frames never pay expired windows or replay a backlog.
	event, session, first, second = fresh()
	id = event:snapshot().id
	event:sync(101, 2)
	local delayed = event:snapshot()
	check(
		delayed.phase == "waiting" and delayed.opensAt == 80 and delayed.closesAt == 90 and delayed.nextOpensAt == 110,
		"Delay resolves current deadline, skips expired windows"
	)
	blocked(event, session, first, id, 101, "stale")
	blocked(event, session, first, delayed.id, 101, "closed")
	check(first.cash == 0 and second.cash == 0, "No catch-up/offline reward")
	event:sync(110, 2)
	check(
		event:claim(session, 101, "First", event:snapshot().id, 110),
		"Current open window remains claimable after stall"
	)
	check(first.cash == 10 and second.cash == 0, "Only current window paid")

	-- The last instant before closing is valid; constructor rules cannot change later.
	event, session, first, second = fresh()
	check(
		event:claim(session, 101, "Boundary", event:snapshot().id, 29.999),
		"Upper boundary is exclusive, preceding instant accepts"
	)
	check(first.cash == 10 and first.incomeRate == 1 and next(first.purchases) == nil, "Late valid reward is cash only")
	local mutable = {
		FirstDelay = 20,
		Interval = 30,
		Warning = 5,
		Window = 10,
		Reward = 10,
		ResultDuration = 3,
		Radius = 6,
		RequestInterval = 0.25,
	}
	local copied = Event.new(mutable)
	mutable.FirstDelay, mutable.Interval, mutable.Reward = 100, 300, 999
	copied:sync(0, 1)
	check(copied:snapshot().opensAt == 20 and copied:snapshot().reward == 10, "Constructor copies rules")
	copied:sync(45, 1)
	check(copied:snapshot().opensAt == 50, "External tuning changes do not alter live cadence")

	-- Join/respawn do not reset a live schedule; a replacement never inherits payout.
	event, session, first, second = fresh()
	id = event:snapshot().id
	event:sync(15, 2)
	check(session:assign(101) == first, "Respawn retains session")
	event:sync(16, 2)
	check(event:snapshot().id == id and event:snapshot().opensAt == 20, "Respawn/join leave live schedule intact")
	check(event:claim(session, 101, "Departed", id, 20), "Departing winner first credited")
	local plot = session:release(101)
	local replacement = session:assign(303)
	assert(replacement, "Supply replacement test needs a free plot")
	event:sync(21, session:assignedCount())
	check(
		replacement.plotId == plot
			and replacement.cash == 0
			and replacement.incomeRate == 1
			and next(replacement.purchases) == nil,
		"Replacement economy is fresh"
	)
	check(
		event:snapshot().winnerUserId == 101 and event:snapshot().winnerName == "Departed",
		"Brief result retains old winner identity"
	)
	blocked(event, session, replacement, id, 21, "already-claimed")
	check(event:snapshot().nextOpensAt == 50, "Remaining owner preserves original schedule")
	event:sync(50, session:assignedCount())
	check(
		event:claim(session, 303, "Replacement", event:snapshot().id, 50) and replacement.cash == 10,
		"Replacement can win only its own later reward"
	)

	-- Last-assignee cancellation invalidates callbacks and starts a fresh cadence later.
	event, session, first, second = fresh()
	id = event:snapshot().id
	event:sync(20, 2)
	session:release(101)
	session:release(202)
	event:sync(21, session:assignedCount())
	local cancelled = event:snapshot()
	check(
		cancelled.phase == "idle"
			and cancelled.id ~= id
			and cancelled.opensAt == 0
			and cancelled.nextOpensAt == 0
			and cancelled.winnerUserId == nil,
		"Zero assignees cancels without reward"
	)
	event:sync(34, 0)
	check(event:snapshot().id == cancelled.id, "Repeated idle updates do not create events")
	local restarted = session:assign(303)
	assert(restarted, "Supply restart test needs a free plot")
	event:sync(35, 1)
	check(
		event:snapshot().opensAt == 55 and event:snapshot().closesAt == 65,
		"Later first assignment gets new +20 schedule"
	)
	blocked(event, session, restarted, id, 55, "stale")
	check(
		event:claim(session, 303, "New", event:snapshot().id, 55) and restarted.cash == 10,
		"Fresh identity claims normally"
	)

	-- Invalid times/configuration/credits fail loudly before observable mutation.
	local function throws(callback: () -> (), text: string)
		local ok, message = pcall(callback)
		check(not ok and string.find(tostring(message), text, 1, true) ~= nil, `Expected actionable error: {text}`)
	end
	for _, value in { 0, -1, math.huge, math.huge - math.huge } do
		for _, field in
			{ "FirstDelay", "Interval", "Warning", "Window", "Reward", "ResultDuration", "Radius", "RequestInterval" }
		do
			local tuning = {
				FirstDelay = 20,
				Interval = 30,
				Warning = 5,
				Window = 10,
				Reward = 10,
				ResultDuration = 3,
				Radius = 6,
				RequestInterval = 0.25,
			}
			tuning[field] = value
			throws(function()
				Event.new(tuning)
			end, field .. " must be finite and positive")
		end
	end
	throws(function()
		Event.new({
			FirstDelay = 20,
			Interval = 30,
			Warning = 5,
			Window = 10,
			Reward = 1.5,
			ResultDuration = 3,
			Radius = 6,
			RequestInterval = 0.25,
		})
	end, "Reward must be a positive integer")
	throws(function()
		Event.new({
			FirstDelay = 5,
			Interval = 30,
			Warning = 5,
			Window = 10,
			Reward = 10,
			ResultDuration = 3,
			Radius = 6,
			RequestInterval = 0.25,
		})
	end, "FirstDelay must exceed Warning")
	throws(function()
		Event.new({
			FirstDelay = 20,
			Interval = 18,
			Warning = 5,
			Window = 10,
			Reward = 10,
			ResultDuration = 3,
			Radius = 6,
			RequestInterval = 0.25,
		})
	end, "Interval must exceed")
	event, session, first, second = fresh()
	id = event:snapshot().id
	for _, value in { -1, math.huge, math.huge - math.huge } do
		throws(function()
			event:sync(value, 2)
		end, "time must be finite and nonnegative")
		throws(function()
			event:claim(session, 101, "Owner", id, value)
		end, "time must be finite and nonnegative")
	end
	event:sync(10, 2)
	throws(function()
		event:sync(9, 2)
	end, "time must not move backwards")
	throws(function()
		event:sync(10, -1)
	end, "assigned count")
	throws(function()
		event:sync(10, 1.5)
	end, "assigned count")
	for _, value in { 0, -1, 1.5, math.huge, math.huge - math.huge } do
		throws(function()
			session:credit(101, value)
		end, "credit must be a finite positive integer")
	end
	check(
		event:snapshot().id == id and event:snapshot().opensAt == 20 and first.cash == 0 and second.cash == 0,
		"Invalid inputs leave event/economy intact"
	)
	check(
		string.find(Rules.describe(event:snapshot(), 10, false), "A plot is needed", 1, true) ~= nil,
		"Unassigned HUD explains eligibility"
	)
	return checks
end
