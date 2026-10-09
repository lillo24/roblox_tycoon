--!strict

local Client = game:GetService("StarterPlayer").StarterPlayerScripts.TycoonClient
local Shared = game:GetService("ReplicatedStorage").TycoonShared
local State = require(Client.UiState)
local Config = require(Shared.Config)

return function(): number
	local count = 0
	local function check(value: boolean, message: string)
		assert(value, "INF01 state: " .. message)
		count += 1
	end
	local attrs: { [string]: any } = {}
	local function read(key: string): any
		return attrs[key]
	end
	attrs[Config.Attributes.Assignment] = "Loading"
	local loading = State.economy(read, true)
	check(
		loading.loading == true and not loading.assigned and not loading.unavailable,
		"loading is explicit, not invalid"
	)
	check(string.find(State.summary(loading), "Loading", 1, true) ~= nil, "loading explains why earnings wait")
	attrs[Config.Attributes.Assignment] = "Unavailable"
	attrs[Config.Attributes.Cash] = 777
	check(
		not State.economy(read, true).assigned and State.economy(read, true).cash == nil,
		"old attributes cannot make unavailable account usable"
	)
	attrs[Config.Attributes.Assignment] = "Ready"
	check(not State.economy(read, true).assigned, "partial replication cannot claim readiness")
	attrs[Config.Attributes.PlotId], attrs[Config.Attributes.IncomeRate] = 3, 1
	attrs[Config.Attributes.SaveStatus] = "Save failed • recent changes are not confirmed"
	local ready = State.economy(read, true)
	check(ready.assigned and ready.plot == 3 and ready.cash == 777, "ready profile hydrates")
	check(string.find(State.persistence(ready), "Save failed", 1, true) ~= nil, "save failure stays truthful")
	check(string.find(State.persistence(ready), "Supply", 1, true) == nil, "calm mode has no event copy")
	check(not State.economy(read).assigned, "prototype does not infer mode from ready attribute")
	for _, status in { "Transferring", "Departing", "Recovering" } do
		attrs[Config.Attributes.Assignment] = status
		local paused = State.economy(read, true)
		check(
			paused.loading == true and not paused.assigned and paused.cash == nil and not paused.unavailable,
			status .. " blocks stale displayed earnings without claiming malformed data"
		)
	end
	attrs[Config.Attributes.Assignment] = "Assigned"
	check(State.economy(read).assigned, "ordinary assigned state still works")
	attrs[Config.Attributes.Assignment] = "Full"
	check(State.economy(read, true).full and State.economy(read, true).cash == nil, "full account has no economy")
	check(
		string.find(State.persistence(State.economy(read, true)), "another server", 1, true) ~= nil,
		"full lobby has actionable feedback"
	)
	return count
end
