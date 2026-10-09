--!nonstrict
-- Bounded development-only series. Times are milliseconds; network fields retain
-- Stats' exposed Kbps units. Heartbeat/PreRender intervals are not script CPU.
local Http = game:GetService("HttpService")
local Stats = game:GetService("Stats")
local Sampler = {}
function Sampler.new(label)
	local buffers, totals = {}, {}
	local sampler = {}
	function sampler.emit(kind, values)
		values.kind, values.side = kind, label
		values.time = math.round(workspace:GetServerTimeNow() * 1000) / 1000
		print("PERF01 " .. Http:JSONEncode(values))
	end
	function sampler.flush()
		for key, values in buffers do
			if #values > 0 then
				sampler.emit("series", { metric = key, values = values })
				table.clear(values)
			end
		end
	end
	function sampler.add(key, value)
		totals[key] = (totals[key] or 0) + 1
		if totals[key] > 40000 then
			return -- A single run cannot retain unbounded samples.
		end
		local values = buffers[key] or {}
		buffers[key] = values
		table.insert(values, math.round(value * 1000) / 1000)
		-- Studio's text log truncates Creator output at about 1 KiB per line.
		-- Small complete chunks retain every raw sample without changing the cadence.
		if #values == 64 then
			sampler.emit("series", { metric = key, values = values })
			table.clear(values)
		end
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
