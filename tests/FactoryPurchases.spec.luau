--!strict

local Visits = require(game:GetService("ServerScriptService").TycoonServer.Experiments.FactoryPurchases.Visits)
local Rules = require(game:GetService("ReplicatedStorage").TycoonShared.Experiments.FactoryPurchases.Rules)
local Session = require(game:GetService("ServerScriptService").TycoonServer.Session)
local Catalogue = require(game:GetService("ReplicatedStorage").TycoonShared.UpgradeCatalogue)
local Config = require(game:GetService("ReplicatedStorage").TycoonShared.Config)

return function(): number
	local count = 0
	local function check(value: boolean, message: string)
		assert(value, message)
		count += 1
	end
	local character, replacement = Instance.new("Model"), Instance.new("Model")
	local size, inside, outside = Vector3.new(4, 0.3, 3), Vector3.new(0, 3, 0), Vector3.new(4, 3, 0)
	local visits = Visits.new()
	check(visits:sample(1, character, "1/income_booster", outside, size, 0) == nil, "Outside cannot offer")
	local token = visits:sample(1, character, "1/income_booster", inside, size, 1)
	assert(token, "Inside visit must offer")
	check(visits:sample(1, character, "1/income_booster", inside, size, 1.1) == nil, "Staying never offers again")
	check(visits:consume(2, token, 1.1, character, function()
		return true
	end) == nil, "Other player cannot consume offer")
	check(visits:consume(1, token, 1.1, replacement, function()
		return true
	end) == nil, "Old character offer refused")
	local session = Session.new(Config, Catalogue.Definitions)
	local owner = session:assign(1)
	assert(owner, "Owner fixture")
	local key = visits:consume(1, token, 1.1, character, function()
		return true
	end)
	check(key == "1/income_booster", "Valid one-use server offer")
	local purchased, reason = session:purchase(1, 1, "income_booster")
	check(not purchased and reason == "insufficient-cash", "Unfunded entry refused by original domain")
	session:accrue(10)
	check(
		visits:sample(1, character, "1/income_booster", inside, size, 2) == nil,
		"Becoming funded while standing does not buy"
	)
	check(visits:consume(1, token, 2, character, function()
		return true
	end) == nil, "Replay does not charge/reward")
	check(
		visits:sample(1, character, "1/income_booster", Vector3.new(2.2, 3, 0), size, 2.1) == nil,
		"Small boundary jitter stays same visit"
	)
	check(visits:sample(1, character, "1/income_booster", outside, size, 2.2) == nil, "Exit rearms without purchasing")
	local second = visits:sample(1, character, "1/income_booster", inside, size, 2.3)
	assert(second, "Fresh entry")
	check(second ~= token, "Re-entry receives a fresh token")
	check(visits:consume(1, second, 2.4, character, function()
		return true
	end) ~= nil, "Funded visit accepted")
	check(session:purchase(1, 1, "income_booster"), "Same catalogue purchase succeeds")
	check(owner.cash == 0 and owner.incomeRate == 2, "Exact -10 / +1 rate")
	check(
		not session:purchase(1, 1, "income_booster") and owner.cash == 0 and owner.incomeRate == 2,
		"Duplicate has no mutation"
	)
	local expiry = Visits.new()
	local expiring = expiry:sample(1, character, "pad", inside, size, 0)
	assert(expiring, "Expiry fixture")
	check(expiry:consume(1, expiring, Rules.OfferLifetime, character, function()
		return true
	end) == nil, "Expiry is exclusive")
	check(expiry:sample(1, character, "pad", inside, size, 1) == nil, "Expired offer never retries on same visit")
	local exit = Visits.new()
	local exited = exit:sample(1, character, "pad", inside, size, 0)
	assert(exited, "Exit fixture")
	check(exit:consume(1, exited, 0.1, character, function()
		return false
	end) == nil, "Reply after leaving cannot buy")
	local reset = Visits.new()
	local stale = reset:sample(1, character, "pad", inside, size, 0)
	assert(stale, "Reset fixture")
	reset:clear(1)
	check(reset:consume(1, stale, 0.1, character, function()
		return true
	end) == nil, "Disconnect clears outstanding offer")
	check(reset:sample(1, replacement, "pad", inside, size, 0.2) ~= nil, "Replacement starts a fresh visit")
	for _, value in { "1", 0 / 0, math.huge, -1, 1.5, {} } do
		check(reset:consume(1, value, 0.3, replacement, function()
			return true
		end) == nil, "Malformed offer refused")
	end
	check(Rules.canRespond(false, false, true, true), "Closed/focused HUD replies automatically")
	check(not Rules.canRespond(true, false, true, true), "Factory/settings/help panel blocks")
	check(not Rules.canRespond(false, true, true, true), "Roblox menu blocks")
	check(not Rules.canRespond(false, false, false, true), "Existing prompt gate blocks")
	check(not Rules.canRespond(false, false, true, false), "Lost focus blocks")
	local blocked = Visits.new()
	check(blocked:sample(1, character, "pad", inside, size, 0) ~= nil, "Menu-blocked entry still consumes its visit")
	check(blocked:sample(1, character, "pad", inside, size, 0.2) == nil, "Closing menu on pad never offers again")
	for _, yaw in { 0, math.pi / 3, math.pi, -math.pi / 3 } do
		local frame = CFrame.new(10, 2, 20) * CFrame.Angles(0, yaw, 0)
		check(
			Rules.contains(frame:PointToObjectSpace(frame:PointToWorldSpace(inside)), size, false),
			"Oriented lot occupancy"
		)
	end
	-- At ordinary WalkSpeed 16, a 20 Hz sample moves .8 studs: each 3-stud pad
	-- crossing has several detected samples. This is a synthetic walking sweep.
	local sweep, offers = Visits.new(), 0
	for i = 0, 20 do
		if sweep:sample(9, character, "pad", Vector3.new(0, 3, -8 + i * 0.8), size, i * 0.05) then
			offers += 1
		end
	end
	check(offers == 1, "Ordinary-speed swept crossing offers exactly once")
	character:Destroy()
	replacement:Destroy()
	return count
end
