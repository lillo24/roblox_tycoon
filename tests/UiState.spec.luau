--!strict

local Client = game:GetService("StarterPlayer").StarterPlayerScripts.TycoonClient
local StateTypes = require(Client.UiState)
local PreferencesTypes = require(Client.UiPreferences)
local ConfigTypes = require(game:GetService("ReplicatedStorage").TycoonShared.Config)
local CatalogueTypes = require(game:GetService("ReplicatedStorage").TycoonShared.UpgradeCatalogue)

return function(
	State: typeof(StateTypes),
	Preferences: typeof(PreferencesTypes),
	Config: typeof(ConfigTypes),
	Catalogue: typeof(CatalogueTypes)
): number
	local checks = 0
	assert(
		State == StateTypes
			and Preferences == PreferencesTypes
			and Config == ConfigTypes
			and Catalogue == CatalogueTypes,
		"UI tests require actual mapped production modules"
	)
	local function check(value: boolean, message: string)
		assert(value, message)
		checks += 1
	end
	for value, expected in
		{
			[0] = "0",
			[999] = "999",
			[1000] = "1,000",
			[1234567890] = "1,234,567,890",
			[-12345] = "-12,345",
			[0.4] = "0.4",
		}
	do
		check(State.number(value) == expected, `Exact formatting for {value}`)
	end
	check(State.rate(3, 2.5) == "+1.2/sec", "Rate uses configured interval")
	check(not pcall(State.rate, 1, 0), "Invalid interval fails loudly")
	check(not pcall(State.number, math.huge), "Nonfinite money fails loudly")
	local attributes: { [string]: any } = {}
	local function read(name: string): any
		return attributes[name]
	end
	local empty = State.economy(read)
	check(not empty.assigned and empty.cash == nil and empty.income == nil, "Loading never invents zero cash/rate")
	check(string.find(State.summary(empty), "Waiting", 1, true) ~= nil, "Truthful loading text")
	attributes[Config.Attributes.Assignment] = "Full"
	check(string.find(State.summary(State.economy(read)), "full", 1, true) ~= nil, "Truthful full capacity")
	attributes[Config.Attributes.Assignment] = "Assigned"
	attributes[Config.Attributes.Cash] = 0
	attributes[Config.Attributes.IncomeRate] = 1
	for _, plot in { 1, 4, 6 } do
		attributes[Config.Attributes.PlotId] = plot
		local economy = State.economy(read)
		check(
			economy.assigned and economy.plot == plot and economy.count == 0,
			"Actual plot identifier, no layout/count assumption"
		)
		check(string.find(State.summary(economy), `Factory {plot}`, 1, true) ~= nil, "Factory number is replicated")
	end
	local initial = State.economy(read)
	check(
		string.find(State.entry(Catalogue.ById.income_booster, initial), "Unaffordable", 1, true) ~= nil,
		"Exact affordability"
	)
	check(
		string.find(State.entry(Catalogue.ById.booster_tuning, initial), "Locked", 1, true) ~= nil,
		"Catalogue prerequisite gates state"
	)
	attributes[Config.Attributes.Cash] = 10
	check(
		string.find(State.entry(Catalogue.ById.income_booster, State.economy(read)), "Available", 1, true) ~= nil,
		"Available at exact cost"
	)
	attributes[Catalogue.purchaseAttribute("income_booster")] = true
	local owned = State.economy(read)
	check(owned.count == 1 and owned.purchases.income_booster, "Actual purchase count")
	check(string.find(State.entry(Catalogue.ById.income_booster, owned), "Owned", 1, true) ~= nil, "Owned state")
	check(
		string.find(State.entry(Catalogue.ById.booster_tuning, owned), "Unaffordable", 1, true) ~= nil,
		"Prerequisite unlock still needs funds"
	)
	attributes[Config.Attributes.IncomeRate] = nil
	check(not State.economy(read).assigned, "Partial late replication remains loading")
	check(State.toggle(nil, "Factory") == "Factory", "Open factory")
	check(State.toggle("Factory", "Settings") == "Settings", "One panel on switch")
	check(State.toggle("Help", "Help") == nil, "Same navigation closes")
	check(string.find(State.event(nil, 0, false), "Waiting for server", 1, true) ~= nil, "Loading event is truthful")
	Preferences.reset()
	local defaults = Preferences.read()
	check(not defaults.large and not defaults.reduceMotion and defaults.labels, "Session defaults")
	check(Preferences.scale(defaults) == 1, "Standard scale")
	check(Preferences.motionReduced(defaults, true), "Platform reduced motion always wins")
	check(not Preferences.motionReduced(defaults, false), "Motion off by default")
	Preferences.set("large", true)
	Preferences.set("labels", false)
	Preferences.set("reduceMotion", true)
	local values = Preferences.read()
	check(Preferences.scale(values) == 1.15 and not values.labels, "Immediate settings")
	check(Preferences.motionReduced(values, false), "Local reduced motion")
	values.labels = true
	check(not Preferences.read().labels, "Reads cannot mutate retained session preferences")
	check(Preferences.read().large, "Preferences survive another view's read")
	Preferences.reset()
	check(
		Preferences.read().labels and not Preferences.read().large and not Preferences.read().reduceMotion,
		"Reset only interface preferences"
	)
	return checks
end
