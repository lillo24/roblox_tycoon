--!strict
local Server = game:GetService("ServerScriptService").TycoonServer
local Configuration = require(Server.Routing.Configuration)
local Controller = require(Server.Routing.Controller)
return function(): number
	local count = 0
	local function check(ok: boolean, message: string)
		assert(ok, "MODE01 routing: " .. message)
		count += 1
	end
	local manifest = { Enabled = true, UniverseId = 10, Places = { Entry = 1, Prototype = 2, Infinite = 3 } }
	local known = { [1] = true, [2] = true, [3] = true }
	for role, id in manifest.Places do
		check(Configuration.resolve(manifest, 10, id, nil, known).role == role, "trusted direct arrival " .. role)
	end
	check(Configuration.resolve(manifest, 11, 1, nil, known).role == "Unavailable", "reject wrong universe")
	check(Configuration.resolve(manifest, 10, 99, nil, known).role == "Unavailable", "reject unlisted source")
	check(Configuration.resolve(manifest, 10, 1, "Infinite", known).role == "Unavailable", "reject role mismatch")
	check(
		Configuration.resolve(manifest, 10, 1, nil, { [1] = true, [2] = true }).role == "Unavailable",
		"reject foreign destination"
	)
	local invalid = { Enabled = true, UniverseId = 10, Places = { Entry = 1, Prototype = 1, Infinite = 3 } }
	check(not Configuration.resolve(invalid, 10, 1, nil, known).enabled, "reject self-route duplicate")
	invalid.Places.Prototype = 0
	check(not Configuration.resolve(invalid, 10, 1, nil, known).enabled, "reject missing destination")
	invalid.Places.Prototype = 0 / 0
	check(not Configuration.resolve(invalid, 10, 1, nil, known).enabled, "reject NaN")
	local disabled = { Enabled = false, UniverseId = 0, Places = {} }
	check(Configuration.resolve(disabled, 0, 0, nil, nil).role == "Prototype", "ordinary default")
	check(Configuration.resolve(disabled, 0, 0, "Infinite", nil).role == "Infinite", "direct Studio preview")
	local now, serial, calls = 0, 0, 0
	local jobs: { () -> () } = {}
	local preparations: { (boolean, string) -> () } = {}
	local recoveries: { (boolean, string) -> () } = {}
	local accepted = true
	local tokens: { string } = {}
	local router = Controller.new("Entry", manifest.Places, {
		now = function()
			return now
		end,
		token = function()
			serial += 1
			return tostring(serial)
		end,
		spawn = function(work)
			table.insert(jobs, work)
		end,
		prepare = function(_id, done)
			table.insert(preparations, done)
		end,
		recover = function(_id, done)
			table.insert(recoveries, done)
		end,
		changed = function() end,
		teleport = function(_id, _target, token)
			calls += 1
			table.insert(tokens, token)
			return accepted, "Injected immediate failure"
		end,
	})
	local function revision(): number
		local view = router:read(1)
		assert(view, "view expected")
		return view.revision
	end
	local function phase(): string
		local view = router:read(1)
		assert(view, "view expected")
		return view.phase
	end
	local function job()
		local work = table.remove(jobs, 1)
		assert(work, "job expected")
		work()
	end
	router:join(1)
	check(not router:choose(1, "unknown", revision()) and calls == 0, "reject arbitrary destinations")
	local firstRevision = revision()
	check(router:choose(1, "Infinite", firstRevision), "choice accepted")
	check(
		not router:choose(1, "Prototype", firstRevision) and #preparations == 1,
		"duplicate competing choice rejected"
	)
	local first = preparations[1]
	now += 31
	router:step()
	check(phase() == "Preparing" and calls == 0, "slow save stays explicit and cannot start a second transition")
	first(true, "confirmed")
	job()
	check(calls == 1 and phase() == "Joining", "accepted is pending, not arrived")
	now += 31
	router:step()
	check(
		phase() == "Waiting" and not router:choose(1, "Prototype", revision()),
		"timeout cannot create a second teleport"
	)
	router:failed(1, "wrong", 3, "stale")
	check(phase() == "Waiting", "nonce fence")
	router:failed(1, tokens[1], 2, "wrong target")
	check(phase() == "Waiting", "target fence")
	router:failed(1, tokens[1], 3, "Injected late failure")
	check(phase() == "Recovering" and #recoveries == 1, "late failure recovers")
	now += 46
	local beforeWarning = revision()
	router:step()
	check(phase() == "Recovering" and revision() > beforeWarning, "slow recovery warns without competing retry")
	recoveries[1](true, "safe")
	check(phase() == "Failed" and not router:choose(1, "Prototype", revision()), "retry cooldown")
	now += 3
	accepted = false
	check(router:choose(1, "Prototype", revision()), "manual retry")
	first(true, "late old preparation")
	check(#jobs == 0, "old prepare completion fenced after retry")
	preparations[2](true, "confirmed")
	job()
	check(phase() == "Recovering" and #recoveries == 2, "immediate error recovers")
	recoveries[1](true, "duplicate old recovery")
	check(phase() == "Recovering", "old recovery cannot finish new one")
	router:failed(1, tokens[1], 3, "old late failure")
	check(#recoveries == 2, "old failed event fenced")
	recoveries[2](false, "another writer owns data")
	check(phase() == "Unavailable", "unsafe source remains unavailable")
	now += 3
	check(router:retry(1, revision()), "explicit reload")
	recoveries[3](true, "freshly reacquired")
	now += 3
	check(router:choose(1, "Infinite", revision()), "third attempt")
	preparations[3](false, "save failed")
	check(#jobs == 0 and phase() == "Recovering", "save failure prevents teleport")
	recoveries[4](true, "recovered")
	now += 3
	check(not router:choose(1, "Infinite", revision()) and calls == 2, "joining attempts bounded to three")
	router:leave(1)
	recoveries[4](true, "late after departure")
	first(true, "late after departure")
	check(router:read(1) == nil and #jobs == 0, "all callbacks fenced after departure")
	local unconfigured = Controller.new("Entry", {}, router.dependencies)
	unconfigured:join(2)
	check(not unconfigured:choose(2, "Infinite", 1) and calls == 2, "missing config never teleports")
	return count
end
