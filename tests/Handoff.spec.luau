--!strict
local Server = game:GetService("ServerScriptService").TycoonServer
local Shared = game:GetService("ReplicatedStorage").TycoonShared
local Session = require(Server.Session)
local Store = require(Server.Persistence.ProfileStore)
local Profiles = require(Server.Persistence.Profiles)
local Schema = require(Server.Persistence.ProfileSchema)
local Catalogue = require(Shared.UpgradeCatalogue)
return function(Memory: any): number
	local count = 0
	local function check(ok: boolean, message: string)
		assert(ok, "MODE01 handoff: " .. message)
		count += 1
	end
	local memory = Memory.new()
	local now, serial = 1000, 0
	local jobs: { () -> () } = {}
	local store = Store.new(memory.update, {
		update = memory.update,
		now = function()
			return math.floor(now) -- Match production os.time; lease timestamps are integers.
		end,
		wait = function(seconds)
			now += seconds
			if seconds < 1 then
				coroutine.yield()
			end
		end,
		token = function()
			serial += 1
			return "handoff-" .. serial
		end,
		jitter = function()
			return 0
		end,
	})
	local session = Session.new({ PlotCount = 2, StartingCash = 0, BaseIncome = 1 }, Catalogue.Definitions)
	local profiles = Profiles.new(session, store, function() end, function(work)
		table.insert(jobs, work)
	end)
	local function run(): thread
		local work = table.remove(jobs, 1)
		assert(work, "expected job")
		local co = coroutine.create(work)
		local ok, issue = coroutine.resume(co)
		assert(ok, tostring(issue))
		return co
	end
	local function resume(co: thread)
		local ok, issue = coroutine.resume(co)
		assert(ok, tostring(issue))
	end
	local result = false
	local function done(ok: boolean, _message: string)
		result = ok
	end
	profiles:join(1)
	run()
	local state = session:get(1)
	assert(state, "ready source")
	session:accrue(100)
	local r = profiles:read(1)
	check(
		profiles:edit(
			1,
			{ epoch = r.epoch, sequence = 1, revision = 0, plot = state.plotId, action = "buy", content = "seed_table" }
		),
		"accepted equipment"
	)
	now += 30
	profiles:step()
	memory.beforeReturn = function()
		coroutine.yield()
	end
	local saving = run()
	session:accrue(2)
	check(
		profiles:edit(1, {
			epoch = r.epoch,
			sequence = 2,
			revision = 1,
			plot = state.plotId,
			action = "place",
			object = "o1",
			x = 18,
			z = -12,
			rotation = 1,
		}),
		"layout accepted after autosave snapshot"
	)
	local finalCash = state.cash
	profiles:prepare(1, done)
	check(state.paused == true and not profiles:ready(1), "freeze synchronously before yielding")
	session:accrue(20)
	check(state.cash == finalCash and not session:credit(1, 10), "no income or credit after boundary")
	check(
		not profiles:edit(
			1,
			{ epoch = r.epoch, sequence = 2, revision = 1, plot = state.plotId, action = "theme", theme = "Midnight" }
		),
		"no edits after boundary"
	)
	local departing = run()
	check(coroutine.status(departing) == "suspended", "handoff waits behind autosave")
	resume(saving)
	resume(departing)
	check(
		result and memory.values.user_1.data.cash == finalCash and memory.values.user_1.lease == nil,
		"latest snapshot confirmed and lease released"
	)
	check(state.paused == true and not profiles:ready(1), "accepted teleport must not resume earning")
	local destination, destinationIssue = store:load(1, function()
		return true
	end, true)
	assert(destination, "destination must acquire before source cleanup: " .. destinationIssue)
	check(
		destination.data.objects.o1.x == 18 and destination.data.objects.o1.rotation == 1,
		"last accepted layout survives handoff"
	)
	check(
		destination.data.cash == finalCash and destination.data.objects.o1.content == "seed_table",
		"destination receives exact progress"
	)
	destination.data.cash += 50
	check(store:save(destination, destination.data, false), "destination checkpoint")
	result = true
	profiles:recover(1, done)
	run()
	check(
		not result and state.paused == true and not profiles:ready(1),
		"failed teleport cannot steal destination writer"
	)
	check(memory.values.user_1.lease.token == destination.token, "destination lease preserved")
	check(store:save(destination, destination.data, true), "destination leaves")
	profiles:recover(1, done)
	run()
	check(result and profiles:ready(1) and state.paused == false, "recovery reacquires current record")
	check(state.cash == finalCash + 50 and state.incomeRate == 3, "source discards stale memory and derives income")
	check(
		not profiles:edit(
			1,
			{ epoch = r.epoch, sequence = 2, revision = 1, plot = state.plotId, action = "theme", theme = "Midnight" }
		),
		"pre-departure editor epoch rejected"
	)
	profiles:prepare(1, done)
	run()
	local newer = store:load(1, function()
		return true
	end, true)
	assert(newer, "new destination")
	newer.data.cash += 80
	check(store:save(newer, newer.data, true), "new destination commits")
	local beforeCalls = memory.calls
	profiles:leave(1)
	check(
		#jobs == 0 and memory.calls == beforeCalls and memory.values.user_1.data.cash == finalCash + 130,
		"source PlayerRemoving cannot overwrite successor"
	)
	-- A pre-write failure is not a checkpoint and cannot resume from old memory.
	profiles:join(2)
	run()
	session:accrue(25)
	memory.failBefore = 4
	result = true
	profiles:prepare(2, done)
	run()
	local failedState = session:get(2)
	assert(failedState, "paused source retained")
	check(
		not result and failedState.paused == true and memory.values.user_2.data.cash == 0,
		"save failure visible; no success-shaped departure"
	)
	profiles:recover(2, done)
	run()
	check(not result and not profiles:ready(2), "ambiguous release does not resume old handle")
	now += 121
	profiles:recover(2, done)
	run()
	check(
		result and failedState.cash == 0 and profiles:ready(2),
		"only last confirmed data resumes after safe reacquisition"
	)
	-- No fresh default if an existing profile disappears during recovery.
	profiles:prepare(2, done)
	run()
	memory.values.user_2 = nil
	profiles:recover(2, done)
	run()
	check(
		not result and memory.values.user_2 == nil and not profiles:ready(2),
		"missing recovery record never becomes a fresh profile"
	)
	profiles:leave(2)
	-- Deadline after a successful but slow release: no teleport; reacquire safely.
	profiles:join(3)
	run()
	session:accrue(9)
	memory.beforeReturn = function()
		now += 26
	end
	result = true
	profiles:prepare(3, done)
	run()
	check(
		not result and memory.values.user_3.lease == nil and not profiles:ready(3),
		"late confirmation does not authorize teleport"
	)
	profiles:recover(3, done)
	run()
	check(result and profiles:ready(3), "slow release recovers through storage")
	-- Departure while save is yielding: final writer finishes, no stale callback.
	local called = false
	memory.beforeReturn = function()
		coroutine.yield()
	end
	profiles:prepare(3, function()
		called = true
	end)
	local inFlight = run()
	profiles:leave(3)
	check(#jobs == 0, "leave does not enqueue a second final writer")
	resume(inFlight)
	check(
		not called and memory.values.user_3.lease == nil and profiles.pending == 0,
		"late release cannot revive departed entry"
	)
	local missing = Schema.decode(memory.values.user_3.data)
	check(missing ~= nil, "final record remains valid")
	-- A timed-out initial load still owns its callback until cleanup finishes.
	profiles:join(4)
	memory.beforeReturn = function()
		coroutine.yield()
	end
	local slowLoad = run()
	now += 46
	profiles:step()
	result = true
	profiles:recover(4, done)
	check(not result and #jobs == 0, "retry cannot overlap unresolved initial load")
	resume(slowLoad)
	check(memory.values.user_4.lease == nil and not profiles:ready(4), "late initial claim releases before retry")
	profiles:recover(4, done)
	run()
	check(result and profiles:ready(4), "retry after initial cleanup restores normally")
	-- Waiting for an older autosave is bounded and never cancels that write.
	now += 30
	profiles:step()
	memory.beforeReturn = function()
		coroutine.yield()
	end
	local oldSave = run()
	result = true
	profiles:prepare(4, done)
	local waiting = run()
	now += 26
	profiles:step()
	resume(waiting)
	check(not result and not profiles:ready(4), "autosave wait deadline does not authorize a departure")
	profiles:recover(4, done)
	check(not result, "busy old save cannot be bypassed during recovery")
	resume(oldSave)
	profiles:recover(4, done)
	check(result and profiles:ready(4), "unreleased usable writer resumes only after serialized save ends")
	profiles:leave(4)
	run()
	check(profiles.pending == 0, "all handoff operations finish")
	return count
end
