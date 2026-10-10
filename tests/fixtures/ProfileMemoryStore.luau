--!strict

-- Explicit test/preview backend, outside production Rojo mappings. Copies mimic
-- serialization; there is no disk persistence and no automatic error fallback.
local HttpService = game:GetService("HttpService")
local Memory = {}
export type Memory = {
	values: { [string]: any },
	calls: number,
	failBefore: number,
	failAfter: number,
	beforeReturn: (() -> ())?,
	update: (string, (any) -> any) -> any,
}
local function copy(value: any): any
	if value == nil then
		return nil
	end
	return HttpService:JSONDecode(HttpService:JSONEncode(value))
end
function Memory.new(): Memory
	local result: Memory = {
		values = {},
		calls = 0,
		failBefore = 0,
		failAfter = 0,
		update = function()
			error("Memory fixture not initialized")
		end,
	}
	result.update = function(key, transform)
		result.calls += 1
		if result.failBefore > 0 then
			result.failBefore -= 1
			error("INF01 injected pre-write service failure")
		end
		local nextValue = transform(copy(result.values[key]))
		if nextValue == nil then
			return nil
		end
		result.values[key] = copy(nextValue)
		local hook = result.beforeReturn
		result.beforeReturn = nil
		if hook then
			hook()
		end
		if result.failAfter > 0 then
			result.failAfter -= 1
			error("INF01 injected lost write response")
		end
		return copy(nextValue)
	end
	return result
end
return Memory
