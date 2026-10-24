--!strict
local Gate =
	require(game:GetService("StarterPlayer").StarterPlayerScripts.TycoonClient.Experiments.FactoryPurchases.VisitGate)
return function(): number
	local count = 0
	local function check(ok: boolean, message: string)
		assert(ok, message)
		count += 1
	end
	local gate = Gate.new()
	local character = {}
	local on = { { key = "Pad_workshop", inside = true, withinExit = true } }
	gate:sample(character, false, on)
	check(gate:respond("Pad_workshop"), "Open entry may acknowledge its exact target")
	check(not gate:respond("Pad_income_booster"), "Never acknowledge another pad's delayed offer")
	gate:sample(character, true, on)
	check(not gate:respond("Pad_workshop"), "Menu blocks entry")
	gate:sample(character, false, on)
	check(not gate:respond("Pad_workshop"), "Closing menu cannot release a blocked visit")
	for _ = 1, 10 do
		gate:sample(character, false, on)
	end
	check(not gate:respond("Pad_workshop"), "Late offer remains blocked while standing")
	gate:sample(character, false, { { key = "Pad_workshop", inside = false, withinExit = true } })
	check(not gate:respond("Pad_workshop"), "Hysteresis edge is not a fresh entry")
	gate:sample(character, false, { { key = "Pad_workshop", inside = false, withinExit = false } })
	gate:sample(character, false, on)
	check(gate:respond("Pad_workshop"), "True exit and re-entry release the local block")
	gate:sample(character, true, on)
	gate:sample({}, false, on)
	check(gate:respond("Pad_workshop"), "New character cannot retain another character's local visit")
	gate:sample(character, true, on)
	gate:sample(character, false, {})
	check(not gate:respond("Pad_workshop"), "Missing/reassigned pad clears stale occupancy")
	gate:sample(character, true, {})
	gate:sample(character, false, on)
	check(not gate:respond("Pad_workshop"), "Menu-close boundary is conservatively blocked before the next sample")
	return count
end
