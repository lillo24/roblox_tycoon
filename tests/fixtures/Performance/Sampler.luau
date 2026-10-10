--!nonstrict
-- Bounded development-only series. Times are milliseconds; network fields retain
-- Stats' exposed Kbps units. Heartbeat/PreRender intervals are not script CPU.
local Http = game:GetService("HttpService")
local Stats = game:GetService("Stats")
local Sampler = {}
function Sampler.new(label)
	local buffers, totals, records = {}, {}, {}
	local active, exporting = false, false
	local sampler = {}
	function sampler.begin()
		assert(not active and not exporting, "PERF sampler run/export still active")
		table.clear(buffers)
		table.clear(totals)
		table.clear(records)
		active = true
	end
	function sampler.emit(kind, values)
		if not active then
			return
		end
		assert(#records < 6000, "PERF sampler record capacity exceeded; run is invalid")
		values.kind, values.side = kind, label
		values.time = math.round(workspace:GetServerTimeNow() * 1000) / 1000
		table.insert(records, values)
	end
	function sampler.flush()
		for key, values in buffers do
			if #values > 0 then
				sampler.emit("series", { metric = key, values = values })
				buffers[key] = {}
			end
		end
	end
	function sampler.add(key, value)
		if not active then
			return
		end
		totals[key] = (totals[key] or 0) + 1
		assert(totals[key] <= 40000, "PERF sampler series capacity exceeded; run is invalid: " .. key)
		local values = buffers[key] or {}
		buffers[key] = values
		table.insert(values, math.round(value * 1000) / 1000)
		-- Retain complete chunks in memory. JSON encoding/log output happens only
		-- after Idle, so logging/Studio Output cannot perturb the timing window.
		if #values == 64 then
			sampler.emit("series", { metric = key, values = values })
			buffers[key] = {}
		end
	end
	function sampler.finish()
		if not active then
			return
		end
		sampler.flush()
		active, exporting = false, true
		-- All sides have left Quiet before this burst. Timestamps belong to the
		-- observation, never the later log write. Idle stats/checkpoints are dropped.
		task.delay(3, function()
			for _, record in records do
				print("PERF01 " .. Http:JSONEncode(record))
			end
			print("PERF01 " .. Http:JSONEncode({
				kind = "exported",
				side = label,
				records = #records,
				time = math.round(workspace:GetServerTimeNow() * 1000) / 1000,
			}))
			table.clear(records)
			exporting = false
		end)
	end
	function sampler.stats(phase)
		local result = { phase = phase, instances = Stats.InstanceCount, luaKB = gcinfo() }
		local errors = {}
		local function read(name, getter)
			local ok, value = pcall(getter)
			if ok then
				result[name] = value
			else
				errors[name] = tostring(value)
			end
		end
		read("totalMB", function()
			return Stats:GetTotalMemoryUsageMb()
		end)
		read("luaMB", function()
			return Stats:GetMemoryUsageMbForTag(Enum.DeveloperMemoryTag.LuaHeap)
		end)
		read("instanceMB", function()
			return Stats:GetMemoryUsageMbForTag(Enum.DeveloperMemoryTag.Instances)
		end)
		read("receiveKbps", function()
			return Stats.DataReceiveKbps
		end)
		read("sendKbps", function()
			return Stats.DataSendKbps
		end)
		read("renderCPUms", function()
			return Stats.RenderCPUFrameTime * 1000
		end)
		read("renderGPUms", function()
			return Stats.RenderGPUFrameTime * 1000
		end)
		read("heartbeatWorkMs", function()
			return Stats.HeartbeatTime * 1000
		end)
		read("physicsWorkMs", function()
			return Stats.PhysicsStepTime * 1000
		end)
		result.errors = if next(errors) then errors else nil
		return result
	end
	return sampler
end
return Sampler
