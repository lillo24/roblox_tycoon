--!strict

local Server = game:GetService("ServerScriptService").TycoonServer
local Shared = game:GetService("ReplicatedStorage").TycoonShared
local Session = require(Server.Session)
local Store = require(Server.Persistence.ProfileStore)
local Profiles = require(Server.Persistence.Profiles)
local Settings = require(Server.Persistence.Settings)
local Catalogue = require(Shared.UpgradeCatalogue)
type Memory = {
	new: (
	) -> {
		values: { [string]: any },
		calls: number,
		failBefore: number,
		failAfter: number,
		beforeReturn: (() -> ())?,
		update: (string, (any) -> any) -> any,
	},
}

return function(Memory: Memory): number
	local checks = 0
	local function check(condition: boolean, message: string)
		assert(condition, "INF01 lifecycle: " .. message)
		checks += 1
	end
	local memory = Memory.new()
	local now, serial = 1000, 0
	local jobs: { () -> () } = {}
	local notifications: { [number]: string } = {}
	local session = Session.new({ PlotCount = 2, StartingCash = 0, BaseIncome = 1 }, Catalogue.Definitions)
	local store = Store.new(memory.update, {
		update = memory.update,
		now = function()
			return now
		end,
		wait = function(seconds)
			if seconds < 1 then
				coroutine.yield()
			else
				now += seconds
			end
		end,
		token = function()
			serial += 1
			return `lifecycle-{serial}`
		end,
		jitter = function()
			return 0
		end,
	})
	local profiles = Profiles.new(session, store, function(userId, status)
		notifications[userId] = status
	end, function(work)
		table.insert(jobs, work)
	end)
	local function run(): thread
		local work = table.remove(jobs, 1)
		assert(work, "Expected queued profile operation")
		local thread = coroutine.create(work)
		local ok, issue = coroutine.resume(thread)
		assert(ok, tostring(issue))
		return thread
	end
	local function resume(thread: thread)
		local ok, issue = coroutine.resume(thread)
		assert(ok, tostring(issue))
	end
	profiles:join(1)
	profiles:join(2)
	profiles:join(3)
	check(
		notifications[1] == "Loading" and notifications[3] == "Full",
		"loading reserves capacity, overflow is explicit"
	)
	check(session:get(1) == nil and not profiles:ready(1), "loading is not an economy")
	session:accrue(10)
	check(memory.calls == 0 and #jobs == 2, "full player never touches persistence")
	run()
	run()
	local first, second = session:get(1), session:get(2)
	assert(first and second, "Both confirmed loads must allocate")
	check(
		first.cash == 0 and second.cash == 0 and profiles:ready(1),
		"income begins only after load, no loading-time accrual"
	)
	session:accrue(10)
	local accepted, reason = session:purchase(2, first.plotId, "income_booster")
	check(
		not accepted and reason == "not-owner" and first.cash == 10 and second.cash == 10,
		"visitor cannot spend either account on owner's pad"
	)
	check(session:purchase(1, first.plotId, "income_booster"), "ready owner can purchase")
	session:accrue(5)
	check(first.cash == 10 and second.cash == 15, "online earnings independent of location")
	now += Settings.AutoSaveSeconds
	profiles:step()
	check(#jobs == 2, "autosaves bounded to ready accounts")
	memory.beforeReturn = function()
		coroutine.yield()
	end
	local saving = run()
	check(coroutine.status(saving) == "suspended", "autosave in flight fixture")
	session:credit(1, 7)
	local oldPlot = first.plotId
	profiles:leave(1)
	profiles:join(4)
	check(session:get(1) == nil and not profiles:ready(4), "departure clears economy before replacement load")
	run() -- Account 2 autosave.
	local departing = run() -- Final save must wait behind account 1 autosave.
	check(coroutine.status(departing) == "suspended", "final save serializes behind older checkpoint")
	run() -- Account 4 claims the free lot.
	local replacement = session:get(4)
	assert(replacement, "Replacement must load")
	check(
		replacement.plotId == oldPlot and replacement.cash == 0 and next(replacement.purchases) == nil,
		"lot reused with only new owner's state"
	)
	resume(saving)
	resume(departing)
	check(
		memory.values.user_1.data.cash == 17 and memory.values.user_1.lease == nil,
		"final write cannot be overwritten by delayed autosave"
	)
	check(notifications[1] == "Ready" and replacement.cash == 0, "stale callback cannot mutate replacement")
	profiles:leave(4)
	run()
	profiles:join(1)
	run()
	local returned = session:get(1)
	assert(returned, "Returning owner must restore")
	check(
		returned.cash == 17 and returned.purchases.income_booster and returned.incomeRate == 2,
		"return restores owner progress"
	)
	profiles:leave(1)
	run()
	profiles:join(5)
	profiles:leave(5)
	profiles:join(6)
	run()
	run()
	check(
		memory.values.user_5 == nil and session:get(5) == nil and profiles:ready(6),
		"cancelled pending load cannot claim a reused lot"
	)
	profiles:leave(6)
	run()
	profiles:join(7)
	memory.beforeReturn = function()
		profiles:leave(7)
		profiles:join(8)
	end
	run()
	run()
	check(
		session:get(7) == nil and memory.values.user_7.lease == nil and profiles:ready(8),
		"departure during successful load releases late claim without touching successor"
	)
	profiles:leave(8)
	run()
	profiles:join(9)
	memory.beforeReturn = function()
		now += Settings.LoadSeconds
		profiles:step()
	end
	run()
	check(
		notifications[9] == "Unavailable" and session:get(9) == nil and memory.values.user_9.lease == nil,
		"late successful load cannot revive an arrival after its deadline"
	)
	profiles:leave(9)
	profiles:join(8)
	run()
	now += Settings.LeaseSeconds
	profiles:step()
	check(
		notifications[8] == "Unavailable" and session:get(8) == nil and not profiles:ready(8),
		"expired renewal stops income and actions"
	)
	while #jobs > 0 do
		run()
	end
	check(profiles.pending == 0, "all bounded lifecycle work finishes")
	profiles:shutdown()
	check(profiles.closing and next(profiles.entries) == nil, "shutdown stops arrivals and clears entries")
	return checks
end
