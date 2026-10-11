--!nonstrict
-- Run separately in Edit, never in a timed scene. Covers retained chunk data,
-- delayed output, original timestamps, Idle exclusion and a second run reset.
return function(Sampler)
	local Http = game:GetService("HttpService")
	local rows = {}
	local connection = game:GetService("LogService").MessageOut:Connect(function(message)
		local json = message:match("^PERF01 (.*)$")
		if json then
			local row = Http:JSONDecode(json)
			if row.side == "sampler-check" then
				table.insert(rows, row)
			end
		end
	end)
	local sampler = Sampler.new("sampler-check")
	sampler.emit("ignored", {})
	sampler.add("ignored", 1)
	sampler.begin()
	for value = 1, 130 do
		sampler.add("retained", value)
	end
	sampler.flush()
	sampler.emit("observation", { sentinel = 17 })
	local observed = workspace:GetServerTimeNow()
	assert(#rows == 0, "Sampler wrote to Output during the measurement")
	sampler.finish()
	sampler.emit("ignored", {})
	task.wait(4)
	assert(#rows == 5 and rows[5].kind == "exported" and rows[5].records == 4, "Incomplete deferred export")
	local values = {}
	for _, row in rows do
		assert(row.kind ~= "ignored", "Idle record leaked")
		if row.kind == "series" then
			for _, value in row.values do
				table.insert(values, value)
			end
		elseif row.kind == "observation" then
			assert(row.sentinel == 17 and math.abs(row.time - observed) < 0.01, "Observation timestamp changed")
		end
	end
	assert(#values == 130, "Flush lost retained samples")
	for index, value in values do
		assert(index == value, "Chunk storage was cleared or overwritten")
	end
	table.clear(rows)
	sampler.begin()
	sampler.add("reset", 42)
	sampler.finish()
	task.wait(4)
	assert(#rows == 2 and rows[1].metric == "reset" and rows[1].values[1] == 42, "Second run retained stale data")
	connection:Disconnect()
	print("PERF02 sampler checks passed: deferred output, 130 intact samples, timestamps, Idle exclusion, run reset")
end
