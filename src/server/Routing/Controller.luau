--!strict
-- Service-independent single-flight router. Every yielding callback is fenced
-- by entry identity + attempt token + phase; accepted API calls are not arrivals.
local Controller = {}
Controller.__index = Controller
export type View = { phase: string, message: string, revision: number, attempts: number, recoveries: number }
type Entry = {
	view: View,
	token: string?,
	target: number?,
	nextTry: number,
	deadline: number,
	preparationWarned: boolean?,
	recoveryGeneration: number?,
}
export type Dependencies = {
	now: () -> number,
	token: () -> string,
	spawn: (() -> ()) -> (),
	prepare: (number, (boolean, string) -> ()) -> (),
	recover: (number, (boolean, string) -> ()) -> (),
	teleport: (number, number, string) -> (boolean, string),
	changed: (number, View) -> (),
}
type Data = { role: string, places: { [string]: number }, dependencies: Dependencies, entries: { [number]: Entry } }
export type Controller = typeof(setmetatable({} :: Data, Controller))
function Controller.new(role: string, places: { [string]: number }, dependencies: Dependencies): Controller
	return setmetatable({ role = role, places = places, dependencies = dependencies, entries = {} }, Controller)
end
local function publish(self: Controller, id: number, entry: Entry, phase: string, message: string)
	if self.entries[id] ~= entry then
		return
	end
	entry.view.phase, entry.view.message = phase, message
	entry.view.revision += 1
	self.dependencies.changed(id, table.clone(entry.view))
end
function Controller.join(self: Controller, id: number)
	assert(not self.entries[id], "Duplicate routing arrival")
	local entry: Entry = {
		view = { phase = "Idle", message = "", revision = 0, attempts = 0, recoveries = 0 },
		nextTry = 0,
		deadline = 0,
	}
	self.entries[id] = entry
	publish(self, id, entry, "Idle", "Choose how you would like to play")
end
function Controller.leave(self: Controller, id: number)
	self.entries[id] = nil
end
function Controller.read(self: Controller, id: number): View?
	local entry = self.entries[id]
	return if entry then table.clone(entry.view) else nil
end
local function recovering(self: Controller, id: number, entry: Entry, reason: string)
	entry.recoveryGeneration = (entry.recoveryGeneration or 0) + 1
	local generation = entry.recoveryGeneration
	entry.deadline, entry.preparationWarned = self.dependencies.now() + 45, false
	publish(self, id, entry, "Recovering", reason .. " • checking your current place…")
	self.dependencies.recover(id, function(ok, message)
		if self.entries[id] ~= entry or entry.view.phase ~= "Recovering" or entry.recoveryGeneration ~= generation then
			return
		end
		entry.nextTry = self.dependencies.now() + 3
		publish(self, id, entry, if ok then "Failed" else "Unavailable", reason .. " • " .. message)
	end)
end
function Controller.failed(self: Controller, id: number, token: string, target: number, reason: string)
	local entry = self.entries[id]
	if
		not entry
		or entry.token ~= token
		or entry.target ~= target
		or not table.find({ "Joining", "Waiting" }, entry.view.phase)
	then
		return
	end
	recovering(self, id, entry, reason)
end
function Controller.choose(self: Controller, id: number, choice: string, revision: number): boolean
	local entry = self.entries[id]
	if
		not entry
		or revision ~= entry.view.revision
		or not table.find({ "Idle", "Failed", "Unavailable" }, entry.view.phase)
	then
		return false
	end
	if self.dependencies.now() < entry.nextTry then
		return false
	end
	local allowed = if self.role == "Entry" then choice == "Prototype" or choice == "Infinite" else choice == "Entry"
	local target = self.places[choice]
	if not allowed or not target or target == self.places[self.role] then
		publish(self, id, entry, "Failed", "This destination is unavailable. Check the configured review destinations.")
		return false
	end
	if entry.view.attempts >= 3 then
		publish(self, id, entry, "Failed", "Three joining attempts used. Stay here or leave and rejoin from Roblox.")
		return false
	end
	entry.view.attempts += 1
	entry.token, entry.target = self.dependencies.token(), target
	entry.deadline, entry.preparationWarned = self.dependencies.now() + 30, false
	local token = entry.token :: string
	publish(
		self,
		id,
		entry,
		"Preparing",
		if self.role == "Infinite"
			then "Saving before leaving… earnings and editing pause"
			else "Preparing to join…"
	)
	self.dependencies.prepare(id, function(ok, issue)
		if self.entries[id] ~= entry or entry.token ~= token or entry.view.phase ~= "Preparing" then
			return
		end
		if not ok then
			recovering(self, id, entry, issue)
			return
		end
		entry.deadline = self.dependencies.now() + 30
		publish(self, id, entry, "Joining", "Joining… waiting for Roblox. Arrival is not yet confirmed.")
		self.dependencies.spawn(function()
			if self.entries[id] ~= entry or entry.token ~= token or entry.view.phase ~= "Joining" then
				return
			end
			local accepted, message = self.dependencies.teleport(id, target, token)
			if not accepted then
				self:failed(id, token, target, message)
			end
		end)
	end)
	return true
end
function Controller.retry(self: Controller, id: number, revision: number): boolean
	local entry = self.entries[id]
	if
		not entry
		or revision ~= entry.view.revision
		or not table.find({ "Idle", "Failed", "Unavailable" }, entry.view.phase)
		or self.dependencies.now() < entry.nextTry
	then
		return false
	end
	if entry.view.recoveries >= 3 then
		publish(self, id, entry, "Unavailable", "Three reload attempts used. Return to modes or rejoin from Roblox.")
		return false
	end
	entry.view.recoveries += 1
	recovering(self, id, entry, "Reload requested")
	return true
end
function Controller.step(self: Controller)
	for id, entry in self.entries do
		if
			entry.view.phase == "Recovering"
			and not entry.preparationWarned
			and self.dependencies.now() >= entry.deadline
		then
			entry.preparationWarned = true
			publish(
				self,
				id,
				entry,
				"Recovering",
				"Reload is still unconfirmed. Keep this session open, or leave and rejoin. Progress remains paused."
			)
		end
		if
			entry.view.phase == "Preparing"
			and not entry.preparationWarned
			and self.dependencies.now() >= entry.deadline
		then
			entry.preparationWarned = true
			publish(
				self,
				id,
				entry,
				"Preparing",
				"Departure save is still unconfirmed. No move has started. Keep this session open; progress stays paused."
			)
		end
		if entry.view.phase == "Joining" and self.dependencies.now() >= entry.deadline then
			-- Roblox offers no cancellation guarantee. Never start a competing
			-- teleport or resume an Infinite writer on an unconfirmed timeout.
			publish(
				self,
				id,
				entry,
				"Waiting",
				"Still waiting for Roblox. Keep this session open, or leave and rejoin. Progress stays paused until a confirmed failure."
			)
		end
	end
end
return Controller
