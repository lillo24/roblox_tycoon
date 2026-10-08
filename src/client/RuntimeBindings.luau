--!strict

-- Three ordered runtime bindings. Event snapshots depend on attached feedback
-- listeners. One deadline and owned child listeners permit late recovery.
local Bindings = {}
Bindings.Timeout = 10
export type Spec = { name: string, class: string, requires: { string }?, bind: (Instance) -> () -> () }
export type Handle = { status: (string) -> string, destroy: () -> () }

function Bindings.start(root: Instance, specs: { Spec }, changed: () -> (), timeout: number?): Handle
	local statuses: { [string]: string } = {}
	local targets: { [string]: Instance } = {}
	local cleanup: { [string]: () -> () } = {}
	local reported: { [string]: string } = {}
	local alive, expired = true, false
	local connections: { RBXScriptConnection } = {}
	local names: { [Instance]: RBXScriptConnection } = {}
	local function refresh()
		if not alive then
			return
		end
		for _, spec in specs do
			local target = root:FindFirstChild(spec.name)
			local count = 0
			for _, child in root:GetChildren() do
				if child.Name == spec.name then
					count += 1
				end
			end
			local ready = target ~= nil and target:IsA(spec.class)
			local reason = if target and not ready then `expected {spec.class}, found {target.ClassName}` else "missing"
			if count > 1 then
				ready, reason = false, `expected one instance, found {count}`
			end
			for _, dependency in spec.requires or {} do
				if statuses[dependency] ~= "ready" then
					ready, reason = false, `waiting for {dependency}`
				end
			end
			if targets[spec.name] and (targets[spec.name] ~= target or not ready) then
				cleanup[spec.name]()
				cleanup[spec.name], targets[spec.name] = nil, nil
			end
			if ready and target then
				if not targets[spec.name] then
					targets[spec.name] = target
					local release = spec.bind(target)
					cleanup[spec.name] = release
				end
				statuses[spec.name], reported[spec.name] = "ready", nil
			else
				local invalid = count > 1 or target ~= nil and not target:IsA(spec.class)
				statuses[spec.name] = if expired or invalid then "unavailable" else "waiting"
				if statuses[spec.name] == "unavailable" and reported[spec.name] ~= reason then
					reported[spec.name] = reason
					warn(`Tycoon HUD: {root:GetFullName()}/{spec.name} unavailable: {reason}`)
				end
			end
		end
		changed()
	end
	-- Keep name watches on unbound children too: renaming a held/duplicate target
	-- must recover after the deadline, when no timer remains to rescan the root.
	local function watch(child: Instance)
		if not names[child] then
			names[child] = child:GetPropertyChangedSignal("Name"):Connect(refresh)
		end
	end
	-- Subscribe before the first lookup and own each child watch until removal.
	table.insert(
		connections,
		root.ChildAdded:Connect(function(child)
			watch(child)
			refresh()
		end)
	)
	table.insert(
		connections,
		root.ChildRemoved:Connect(function(child)
			local connection = names[child]
			if connection then
				connection:Disconnect()
				names[child] = nil
			end
			refresh()
		end)
	)
	for _, child in root:GetChildren() do
		watch(child)
	end
	local timer: thread? = nil
	timer = task.delay(timeout or Bindings.Timeout, function()
		timer = nil
		expired = true
		refresh()
	end)
	refresh()
	return {
		status = function(name: string): string
			return statuses[name] or "waiting"
		end,
		destroy = function()
			alive = false
			if timer then
				task.cancel(timer)
			end
			for _, connection in connections do
				connection:Disconnect()
			end
			for _, connection in names do
				connection:Disconnect()
			end
			table.clear(names)
			for _, release in cleanup do
				release()
			end
			table.clear(cleanup)
		end,
	}
end

return Bindings
