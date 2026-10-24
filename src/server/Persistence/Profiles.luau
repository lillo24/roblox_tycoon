--!strict

-- Account lifecycle around Session. Entry identity fences every yielding load,
-- save and departure callback; lot allocation happens only after a confirmed load.
local Session = require(script.Parent.Parent.Session)
local Store = require(script.Parent.ProfileStore)
local Schema = require(script.Parent.ProfileSchema)
local Settings = require(script.Parent.Settings)
local Edits = require(script.Parent.Parent.PropertyEdits)
local HttpService = game:GetService("HttpService")
local Profiles = {}
Profiles.__index = Profiles
type Entry = {
	userId: number,
	status: string,
	saveStatus: string,
	handle: Store.Handle?,
	data: Schema.Data?,
	nextSave: number,
	loadDeadline: number,
	saving: boolean,
	epoch: string,
	requestId: number,
	fingerprint: string?,
	result: string?,
	accepted: boolean?,
	handoff: boolean?,
	finalizing: boolean?,
	recovering: boolean?,
	handoffDeadline: number?,
	departureConfirmed: boolean?,
	loading: boolean?,
}
type Data = {
	session: Session.Session,
	store: Store.Store,
	entries: { [number]: Entry },
	changed: (number, string, string, Session.State?, Schema.Data?) -> (),
	spawn: (() -> ()) -> (),
	pending: number,
	closing: boolean,
}
export type Profiles = typeof(setmetatable({} :: Data, Profiles))

function Profiles.new(
	session: Session.Session,
	store: Store.Store,
	changed: (number, string, string, Session.State?, Schema.Data?) -> (),
	spawn: ((() -> ()) -> ())?
): Profiles
	return setmetatable({
		session = session,
		store = store,
		entries = {},
		changed = changed,
		spawn = spawn or function(work)
			task.spawn(work)
		end,
		pending = 0,
		closing = false,
	}, Profiles)
end

local function launch(self: Profiles, work: () -> ())
	self.pending += 1
	self.spawn(function()
		local ok, issue = xpcall(function()
			work()
			return true
		end, function(failure: any): string
			return debug.traceback(tostring(failure))
		end)
		self.pending -= 1
		if not ok then
			error(issue)
		end -- Internal defects retain diagnostics; never become a successful load.
	end)
end

local function notify(self: Profiles, entry: Entry)
	if self.entries[entry.userId] == entry then
		self.changed(entry.userId, entry.status, entry.saveStatus, self.session:get(entry.userId), entry.data)
	end
end

function Profiles.snapshot(self: Profiles, userId: number): Schema.Data?
	local entry, state = self.entries[userId], self.session:get(userId)
	if not entry or not entry.data or not state then
		return nil
	end
	entry.data = Schema.capture(state.cash, state.purchases, entry.data)
	return entry.data
end

local function finalSave(self: Profiles, handle: Store.Handle, data: Schema.Data)
	-- Await a previous autosave's whole retry operation; never let a delayed older
	-- snapshot run after the final snapshot. Roblox's shutdown deadline bounds this.
	while handle.busy do
		self.store.wait(0.05)
	end
	local ok, issue = self.store:save(handle, data, true)
	if not ok then
		warn(`Infinite final save {handle.key} unconfirmed: {issue}`)
	end
end

function Profiles.join(self: Profiles, userId: number)
	assert(not self.entries[userId], `Infinite: duplicate arrival {userId}`)
	local reserved = 0
	for _, entry in self.entries do
		if entry.status == "Loading" or entry.recovering or self.session:get(entry.userId) then
			reserved += 1
		end
	end
	local status = if self.closing
		then "Unavailable"
		elseif reserved >= self.session.tuning.PlotCount then "Full"
		else "Loading"
	local entry: Entry = {
		userId = userId,
		status = status,
		saveStatus = "",
		nextSave = 0,
		saving = false,
		loadDeadline = self.store.now() + Settings.LoadSeconds,
		epoch = HttpService:GenerateGUID(false),
		requestId = 0,
		loading = status == "Loading",
	}
	self.entries[userId] = entry
	notify(self, entry)
	if status ~= "Loading" then
		return
	end
	launch(self, function()
		local handle, issue = self.store:load(userId, function()
			return self.entries[userId] == entry and entry.status == "Loading" and not self.closing
		end)
		entry.loading = false
		if not handle then
			if self.entries[userId] == entry and entry.status == "Loading" then
				entry.status, entry.saveStatus = "Unavailable", "Your saved place could not be loaded. Rejoin to retry."
				warn(`Infinite load user_{userId}: {issue}`)
				notify(self, entry)
			end
			return
		end
		if self.entries[userId] ~= entry or entry.status ~= "Loading" or self.closing then
			entry.finalizing = true
			finalSave(self, handle, handle.data)
			entry.finalizing = false
			return
		end
		if not self.store:usable(handle) then
			entry.finalizing = true
			entry.status, entry.saveStatus = "Unavailable", "Loading took too long. Rejoin to retry."
			notify(self, entry)
			finalSave(self, handle, handle.data)
			entry.finalizing = false
			return
		end
		local state = self.session:assign(userId, { cash = handle.data.cash, purchases = handle.data.assets })
		assert(state, "Infinite: reserved lot was consumed outside the profile lifecycle")
		state.incomeRate = Schema.income(handle.data)
		entry.handle, entry.data = handle, handle.data
		entry.status, entry.saveStatus = "Ready", "Place loaded • autosave active"
		entry.nextSave = self.store.now() + Settings.AutoSaveSeconds
		notify(self, entry)
	end)
end

function Profiles.ready(self: Profiles, userId: number): boolean
	local entry = self.entries[userId]
	return entry ~= nil and entry.status == "Ready" and entry.handle ~= nil and self.store:usable(entry.handle)
end

function Profiles.read(self: Profiles, userId: number): any
	local entry, state = self.entries[userId], self.session:get(userId)
	if not entry or not state or not self:ready(userId) then
		return { available = false, message = "Your saved place is not ready" }
	end
	return {
		available = true,
		data = self:snapshot(userId),
		epoch = entry.epoch,
		sequence = entry.requestId,
		plot = state.plotId,
	}
end

function Profiles.edit(self: Profiles, userId: number, request: any): (boolean, string)
	local entry, state = self.entries[userId], self.session:get(userId)
	if not self:ready(userId) or not entry or not state then
		return false, "Your saved place is not ready"
	end
	if typeof(request) ~= "table" then
		return false, "Invalid edit"
	end
	local keys = 0
	for key, value in request do
		keys += 1
		if
			keys > 10
			or not table.find({
				"epoch",
				"sequence",
				"plot",
				"revision",
				"action",
				"content",
				"object",
				"x",
				"z",
				"rotation",
				"theme",
			}, key)
			or (typeof(value) ~= "string" and typeof(value) ~= "number")
			or (typeof(value) == "string" and #value > 80)
		then
			return false, "Invalid edit fields"
		end
	end
	if request.epoch ~= entry.epoch or request.plot ~= state.plotId then
		return false, "This editing session has ended"
	end
	if
		typeof(request.sequence) ~= "number"
		or request.sequence % 1 ~= 0
		or request.sequence < 1
		or request.sequence > 1000000000
	then
		return false, "Invalid edit sequence"
	end
	local parts = {}
	for _, key in { "revision", "action", "content", "object", "x", "z", "rotation", "theme" } do
		table.insert(parts, tostring(request[key]))
	end
	local fingerprint = table.concat(parts, "|")
	if request.sequence == entry.requestId and fingerprint == entry.fingerprint then
		return entry.accepted == true, entry.result or "No result"
	end
	if request.sequence <= entry.requestId then
		return false, "Stale edit; refresh your place"
	end
	local snapshot = self:snapshot(userId)
	assert(snapshot, "Ready property has no snapshot")
	local data, message = Edits.apply(snapshot, request)
	entry.requestId, entry.fingerprint, entry.result, entry.accepted =
		request.sequence, fingerprint, message, data ~= nil
	if data then
		entry.data = data
		state.cash, state.purchases, state.incomeRate = data.cash, data.assets, Schema.income(data)
		notify(self, entry)
	end
	return data ~= nil, message
end

function Profiles.leave(self: Profiles, userId: number)
	local entry = self.entries[userId]
	if not entry then
		return
	end
	local snapshot = self:snapshot(userId)
	self.entries[userId] = nil -- Invalidate callbacks before freeing/reusing the lot.
	self.session:release(userId)
	local handle = entry.handle
	if handle and snapshot and not entry.handoff then
		launch(self, function()
			finalSave(self, handle, snapshot)
		end)
	end
end

-- Call before income/purchases. Losing the renewal margin ends the live economy;
-- a late successful autosave can never revive this entry or a reused lot.
function Profiles.step(self: Profiles)
	for userId, entry in self.entries do
		if entry.handoff and entry.handoffDeadline and self.store.now() >= entry.handoffDeadline then
			if entry.status ~= "Unavailable" then
				entry.status, entry.saveStatus =
					"Unavailable", "Departure save is taking too long. Keep this session open; progress is paused."
				notify(self, entry)
			end
		end
		if entry.status == "Loading" and self.store.now() >= entry.loadDeadline then
			entry.status, entry.saveStatus = "Unavailable", "Loading timed out. Rejoin to retry."
			notify(self, entry)
		end
		local handle = entry.handle
		if entry.status ~= "Ready" or not handle then
			continue
		end
		if not self.store:usable(handle) then
			local snapshot = self:snapshot(userId)
			self.session:release(userId)
			entry.status, entry.saveStatus =
				"Unavailable", "Saving connection lost. Rejoin to recover your last saved place."
			notify(self, entry)
			entry.handle = nil
			if snapshot then
				entry.finalizing = true
				launch(self, function()
					finalSave(self, handle, snapshot)
					entry.finalizing = false
				end)
			end
		elseif not entry.saving and self.store.now() >= entry.nextSave then
			local snapshot = self:snapshot(userId)
			assert(snapshot, "Infinite autosave: ready profile has no snapshot")
			entry.saving, entry.saveStatus = true, "Saving checkpoint…"
			notify(self, entry)
			launch(self, function()
				local ok, issue = self.store:save(handle, snapshot, false)
				entry.saving = false
				if self.entries[userId] ~= entry or entry.status ~= "Ready" then
					return
				end
				entry.nextSave = self.store.now() + Settings.AutoSaveSeconds
				entry.saveStatus = if ok
					then "Checkpoint saved • online earnings continue"
					else "Save failed • recent changes are not confirmed"
				if not ok then
					warn(`Infinite autosave user_{userId}: {issue}`)
				end
				notify(self, entry)
			end)
		end
	end
end

-- Intentional departure owns the final writer. Freeze before capturing, then
-- serialize after the ENTIRE autosave operation. PlayerRemoving must not queue
-- another stale snapshot after this operation releases ownership.
function Profiles.prepare(self: Profiles, userId: number, done: (boolean, string) -> ())
	local entry, state = self.entries[userId], self.session:get(userId)
	if not entry or self.closing or entry.handoff or entry.recovering or entry.finalizing or entry.loading then
		done(false, "Profile operation still pending. Please wait.")
		return
	end
	if not state and not entry.handle and entry.status ~= "Loading" then
		done(true, "No active profile to release") -- Full/unavailable arrival can return to entry.
		return
	end
	if entry.departureConfirmed and not entry.handle then
		done(true, "Departure checkpoint already confirmed")
		return
	end
	local handle = entry.handle
	if not self:ready(userId) or not state or not handle then
		done(false, "Your saved place is not ready to leave. Reload it first.")
		return
	end
	state.paused = true
	entry.handoff, entry.status = true, "Transferring"
	entry.handoffDeadline = self.store.now() + Settings.HandoffSeconds
	entry.saveStatus = "Saving before leaving… earnings and editing are paused"
	local snapshot = self:snapshot(userId)
	assert(snapshot, "Handoff requires a final snapshot")
	notify(self, entry)
	launch(self, function()
		local deadline = entry.handoffDeadline :: number
		while (entry.saving or handle.busy) and self.store.now() < deadline do
			self.store.wait(0.05)
		end
		if self.entries[userId] ~= entry then
			finalSave(self, handle, snapshot)
			return
		end
		if entry.saving or handle.busy or not self.store:usable(handle) or self.store.now() >= deadline then
			entry.handoff = false
			entry.status, entry.saveStatus = "Unavailable", "Departure was not confirmed. Reload your place to resume."
			notify(self, entry)
			done(false, entry.saveStatus)
			return
		end
		local ok, issue = self.store:save(handle, snapshot, true)
		entry.handle, entry.handoff = nil, false -- Even an ambiguous release closes this handle.
		entry.departureConfirmed = ok
		if self.entries[userId] ~= entry then
			return
		end
		local timely = ok and self.store.now() < deadline
		entry.status = if timely then "Departing" else "Unavailable"
		entry.saveStatus = if ok
			then "Departure checkpoint confirmed • earnings paused"
			else "Departure save unconfirmed • earnings paused"
		if not ok then
			warn(`Infinite handoff user_{userId}: {issue}`)
		end
		notify(self, entry)
		done(
			timely,
			if timely then "Checkpoint confirmed" else "Departure did not finish in time. Reload your place to resume."
		)
	end)
end

-- Recovery after a released/ambiguous lease always claims CURRENT storage data
-- with a fresh token. Never replay the source snapshot or force-expire a writer.
function Profiles.recover(self: Profiles, userId: number, done: (boolean, string) -> ())
	local entry = self.entries[userId]
	if
		not entry
		or self.closing
		or entry.handoff
		or entry.saving
		or entry.recovering
		or entry.finalizing
		or entry.loading
		or entry.status == "Loading"
	then
		done(false, "A profile operation is still pending. Wait, then reload your place.")
		return
	end
	local existing = self.session:get(userId)
	if entry.handle and self.store:usable(entry.handle) and existing then
		existing.paused = false -- No release was attempted (e.g. autosave wait deadline).
		entry.status, entry.saveStatus = "Ready", "Departure cancelled before release • online earnings continue"
		notify(self, entry)
		done(true, "Your place is ready again")
		return
	end
	local reserved = 0
	for id, other in self.entries do
		if id ~= userId and (other.status == "Loading" or other.recovering or self.session:get(id)) then
			reserved += 1
		end
	end
	if not existing and reserved >= self.session.tuning.PlotCount then
		entry.status, entry.saveStatus = "Full", "This lobby is full. Return to modes and choose another lobby."
		notify(self, entry)
		done(false, entry.saveStatus)
		return
	end
	entry.status, entry.recovering = "Recovering", true
	entry.saveStatus = "Reloading current saved data… earnings remain paused"
	entry.loadDeadline = self.store.now() + Settings.LoadSeconds
	notify(self, entry)
	launch(self, function()
		local handle, issue = self.store:load(userId, function()
			return self.entries[userId] == entry and not self.closing and self.store.now() < entry.loadDeadline
		end, entry.data ~= nil)
		entry.recovering = false
		if self.entries[userId] ~= entry or self.closing then
			if handle then
				finalSave(self, handle, handle.data)
			end
			return
		end
		if not handle or not self.store:usable(handle) or self.store.now() >= entry.loadDeadline then
			entry.status, entry.saveStatus =
				"Unavailable", "Could not reacquire your saved place. Wait and reload, or return to modes."
			if handle then
				entry.finalizing = true
				finalSave(self, handle, handle.data)
				entry.finalizing = false
			end
			warn(`Infinite recovery user_{userId}: {issue}`)
			notify(self, entry)
			done(false, entry.saveStatus)
			return
		end
		local state = self.session:get(userId)
			or self.session:assign(userId, { cash = handle.data.cash, purchases = handle.data.assets })
		assert(state, "Infinite recovery lost its reserved lot")
		state.cash, state.purchases, state.incomeRate, state.paused =
			handle.data.cash, handle.data.assets, Schema.income(handle.data), false
		entry.handle, entry.data = handle, handle.data
		entry.departureConfirmed = false
		entry.epoch, entry.requestId, entry.fingerprint, entry.result, entry.accepted =
			HttpService:GenerateGUID(false), 0, nil, nil, nil
		entry.status, entry.saveStatus = "Ready", "Current saved place restored • online earnings continue"
		entry.nextSave = self.store.now() + Settings.AutoSaveSeconds
		notify(self, entry)
		done(true, "Your current saved place is ready again")
	end)
end

function Profiles.shutdown(self: Profiles)
	self.closing = true
	local users = {}
	for userId in self.entries do
		table.insert(users, userId)
	end
	for _, userId in users do
		self:leave(userId)
	end
	local deadline = os.clock() + Settings.ShutdownSeconds
	while self.pending > 0 and os.clock() < deadline do
		self.store.wait(0.05)
	end
	if self.pending > 0 then
		warn(`Infinite shutdown: {self.pending} profile operations remain unconfirmed`)
	end
end

return Profiles
