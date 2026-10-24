--!strict

local Modules = game:GetService("ServerScriptService").TycoonServer
local Schema = require(Modules.Persistence.ProfileSchema)
local Store = require(Modules.Persistence.ProfileStore)
local Settings = require(Modules.Persistence.Settings)
local Session = require(Modules.Session)
local Shared = game:GetService("ReplicatedStorage").TycoonShared
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
	local count = 0
	local function check(condition: boolean, message: string)
		assert(condition, "INF01 persistence: " .. message)
		count += 1
	end
	local memory = Memory.new()
	local now, serial = 1000, 0
	local function store(): Store.Store
		return Store.new(memory.update, {
			update = memory.update,
			now = function()
				return now
			end,
			wait = function(seconds)
				now += math.floor(seconds)
			end,
			token = function()
				serial += 1
				return `test-{serial}`
			end,
			jitter = function()
				return 0
			end,
		})
	end
	local a, b = store(), store()
	local handle, message = a:load(101, function()
		return true
	end)
	assert(handle, message)
	check(handle.data.cash == 0 and next(handle.data.assets) == nil, "successful missing read creates starting state")
	check(memory.values.user_101.lease.token == handle.token, "load and claim must be atomic")
	local cancelled = a:load(999, function()
		return false
	end)
	check(cancelled == nil and memory.values.user_999 == nil, "cancelled arrival cannot create a profile")
	local calls = memory.calls
	local competing = b:load(101, function()
		return true
	end)
	check(competing == nil and memory.calls - calls == Settings.Attempts, "competing arrival has bounded retries")
	check(memory.values.user_101.lease.token == handle.token, "contender cannot steal a live lease")
	local data = Schema.capture(91, { income_booster = true, workshop = true }, handle.data)
	data.placements.income_booster, data.placements.workshop = "east_back", "west_front"
	local ok = a:save(handle, data, true)
	check(ok and memory.values.user_101.lease == nil, "final save atomically releases ownership")
	local restored = b:load(101, function()
		return true
	end)
	assert(restored, "returning player must load")
	check(restored.data.cash == 91 and restored.data.assets.workshop == true, "return restores exact cash/assets")
	check(restored.data.placements.income_booster == "east_back", "placement independent of purchase order")
	local session = Session.new({ PlotCount = 6, StartingCash = 0, BaseIncome = 1 }, Catalogue.Definitions)
	session:assign(202)
	local state = session:assign(101, { cash = restored.data.cash, purchases = restored.data.assets })
	assert(state, "restored state must allocate a different free lot")
	check(
		state.plotId == 2 and state.incomeRate == 5 and state.cash == 91,
		"new lot derives trusted income without offline earnings"
	)
	local before = memory.values.user_101.data.cash
	memory.failBefore = Settings.Attempts
	local failed = b:save(restored, Schema.capture(100, state.purchases, restored.data), false)
	check(not failed and memory.values.user_101.data.cash == before, "failed save is not confirmed or substituted")
	check(b:usable(restored), "short service failure retains bounded live ownership")
	memory.failAfter = 1
	check(b:save(restored, data, true), "ambiguous final response is idempotently confirmed")
	check(
		memory.values.user_101.data.cash == 91 and memory.values.user_101.lease == nil,
		"retry cannot duplicate or lose final data"
	)
	check(not b:save(restored, Schema.new(), false), "closed writer cannot resume")
	local old = a:load(101, function()
		return true
	end)
	assert(old, "expired-writer setup")
	now += Settings.LeaseSeconds
	local successor = b:load(101, function()
		return true
	end)
	assert(successor, "expired lease must recover")
	check(
		successor.token ~= old.token and successor.data.cash == 91,
		"recovery reads last committed data with a fresh fence"
	)
	check(b:save(successor, Schema.capture(150, data.assets, data), true), "successor writes and releases")
	check(not a:save(old, Schema.new(), true), "old writer rejected even after successor releases")
	check(memory.values.user_101.data.cash == 150, "old writer cannot overwrite newer progress")
	local expired = a:load(102, function()
		return true
	end)
	assert(expired, "expiry setup")
	now += Settings.LeaseSeconds
	check(
		not a:usable(expired) and not a:save(expired, Schema.new(), true),
		"expired owner cannot self-renew by saving"
	)
	local invalidProfiles: { any } = {
		false,
		"corrupt",
		{ version = 2 },
		{ version = 1, cash = -1, assets = {}, placements = {} },
		{ version = 1, cash = math.huge, assets = {}, placements = {} },
		{ version = 1, cash = 0 / 0, assets = {}, placements = {} },
		{ version = 1, cash = 1.5, assets = {}, placements = {} },
		{ version = 1, cash = 0, assets = { unknown = true }, placements = {} },
		{ version = 1, cash = 0, assets = { income_booster = false }, placements = {} },
		{
			version = 1,
			cash = 0,
			assets = { booster_tuning = true },
			placements = { booster_tuning = "west_back" },
		},
		{ version = 1, cash = 0, assets = { workshop = true }, placements = {} },
		{ version = 1, cash = 0, assets = {}, placements = { workshop = "east_front" } },
		{
			version = 1,
			cash = 0,
			assets = { income_booster = true, workshop = true },
			placements = { income_booster = "west_front", workshop = "west_front" },
		},
		{ version = 1, cash = 0, assets = {}, placements = {}, plotId = 1 },
	}
	for _, invalid in invalidProfiles do
		check(Schema.decode(invalid) == nil, "invalid schema must be refused")
	end
	for _, invalid in
		{
			false,
			{ version = 99 },
			{ version = 1, data = Schema.new(), lease = { token = "", expiresAt = 9 } },
			{ version = 1, data = Schema.new(), lastWrite = { token = "t", sequence = -1 } },
		}
	do
		memory.values.user_333 = invalid
		local initialCalls = memory.calls
		check(a:load(333, function()
			return true
		end) == nil, "invalid record cannot load")
		check(
			memory.calls == initialCalls + 1 and memory.values.user_333 == invalid,
			"invalid data is not retried or overwritten"
		)
	end
	memory.failBefore = Settings.Attempts
	check(a:load(444, function()
		return true
	end) == nil and memory.values.user_444 == nil, "failed new load does not invent defaults")
	local owned = Schema.capture(0, { workshop = true, income_booster = true, booster_tuning = true }, data)
	check(
		owned.placements.income_booster == "east_back" and owned.placements.booster_tuning == "west_back",
		"new purchase retains existing independent layout"
	)
	check(Schema.decode(owned) ~= nil, "captured layout is valid")
	local capped = Session.new(
		{ PlotCount = 1, StartingCash = 0, BaseIncome = 1, CashLimit = Schema.MaxCash },
		Catalogue.Definitions
	)
	local cappedState = capped:assign(500, { cash = Schema.MaxCash, purchases = {} })
	assert(cappedState, "Ceiling profile must restore")
	capped:accrue(100)
	check(cappedState.cash == Schema.MaxCash, "valid cash ceiling cannot become unsavable through income")
	check(
		Schema.decode(Schema.capture(cappedState.cash, cappedState.purchases, Schema.new())) ~= nil,
		"ceiling remains serializable"
	)
	return count
end
