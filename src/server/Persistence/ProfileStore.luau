--!strict

local HttpService = game:GetService("HttpService")
local Schema = require(script.Parent.ProfileSchema)
local Settings = require(script.Parent.Settings)
local Store = {}
Store.__index = Store
export type Handle = {
	key: string,
	token: string,
	data: Schema.Data,
	expiresAt: number,
	sequence: number,
	busy: boolean,
	closed: boolean,
}
type Dependencies = {
	update: (string, (any) -> any) -> any,
	now: () -> number,
	wait: (number) -> (),
	token: () -> string,
	jitter: () -> number,
}
export type Store = typeof(setmetatable({} :: Dependencies, Store))

function Store.new(update: (string, (any) -> any) -> any, dependencies: Dependencies?): Store
	return setmetatable(dependencies or {
		update = update,
		now = function()
			return os.time()
		end,
		wait = function(seconds)
			task.wait(seconds)
		end,
		token = function()
			return HttpService:GenerateGUID(false)
		end,
		jitter = function()
			return math.random()
		end,
	}, Store)
end

local function backoff(self: Store, attempt: number)
	self.wait(math.min(8, 2 ^ attempt + self.jitter()))
end

-- The atomic claim reads and validates before writing. Nil is the ONLY new-user
-- case. A network exception, invalid record or another lease cannot create defaults.
function Store.load(self: Store, userId: number, present: () -> boolean, requireExisting: boolean?): (Handle?, string)
	local key, token = `user_{userId}`, self.token()
	local issue = "load did not complete"
	for attempt = 1, Settings.Attempts do
		if not present() then
			return nil, "arrival cancelled"
		end
		local terminal = false
		local ok, result = pcall(self.update, key, function(current: any): any
			if not present() then
				issue, terminal = "arrival cancelled", true
				return nil
			end
			local record: Schema.Record?
			if current == nil then
				if requireExisting then
					issue, terminal = "saved profile disappeared during recovery", true
					return nil
				end
				local fresh: Schema.Record = { version = 1, data = Schema.new() }
				record = fresh
			else
				local invalid: string?
				record, invalid = Schema.record(current)
				if not record then
					issue, terminal = `invalid saved profile: {invalid}`, true
					return nil
				end
			end
			assert(record, "Profile load: validated record disappeared")
			local lease, now = record.lease, self.now()
			if lease and lease.token ~= token and lease.expiresAt > now then
				issue = "profile is still owned by another session; rejoin shortly"
				return nil
			end
			record.lease = { token = token, expiresAt = now + Settings.LeaseSeconds }
			return record
		end)
		if ok and result ~= nil then
			local record, invalid = Schema.record(result)
			if not record or not record.lease or record.lease.token ~= token then
				return nil, `load {key}: invalid confirmation ({invalid})`
			end
			return {
				key = key,
				token = token,
				data = record.data,
				expiresAt = record.lease.expiresAt,
				sequence = 0,
				busy = false,
				closed = false,
			},
				"loaded"
		elseif not ok then
			issue = `DataStore load {key}: {tostring(result)}`
		end
		if terminal then
			break
		end
		if attempt < Settings.Attempts then
			backoff(self, attempt)
		end
	end
	return nil, issue
end

function Store.usable(self: Store, handle: Handle): boolean
	return not handle.closed and self.now() < handle.expiresAt - Settings.SafetySeconds
end

-- One operation per handle, including all retries. A sequence makes an ambiguous
-- successful write idempotent; token fencing also rejects an old writer after a
-- successor has acquired AND released the profile. No SetAsync/unlocked overwrite.
function Store.save(self: Store, handle: Handle, data: Schema.Data, release: boolean): (boolean, string)
	if handle.closed then
		return false, "profile ownership ended"
	end
	assert(not handle.busy, `Profile {handle.key}: concurrent save would reorder writes`)
	local snapshot, invalid = Schema.decode(data)
	assert(snapshot, `Profile {handle.key}: invalid save snapshot: {invalid}`)
	handle.busy = true
	handle.sequence += 1
	local sequence, issue = handle.sequence, "save did not complete"
	for attempt = 1, Settings.Attempts do
		local lost = false
		local ok, result = pcall(self.update, handle.key, function(current: any): any
			local record, reason = Schema.record(current)
			if not record then
				issue, lost = `saved record invalid: {reason}`, true
				return nil
			end
			local receipt = record.lastWrite
			if receipt and receipt.token == handle.token and receipt.sequence == sequence then
				return record -- Confirm a committed response lost in transit; preserve successor ownership/data.
			end
			local lease, now = record.lease, self.now()
			if not lease or lease.token ~= handle.token or lease.expiresAt <= now then
				issue, lost = "profile ownership expired or moved to another session", true
				return nil
			end
			record.data = snapshot
			record.lastWrite = { token = handle.token, sequence = sequence }
			record.lease = if release then nil else { token = handle.token, expiresAt = now + Settings.LeaseSeconds }
			return record
		end)
		if ok and result ~= nil then
			local record = Schema.record(result)
			local receipt = if record then record.lastWrite else nil
			if record and receipt and receipt.token == handle.token and receipt.sequence == sequence then
				handle.busy = false
				handle.data = snapshot
				if release then
					handle.closed = true
				elseif record.lease and record.lease.token == handle.token then
					handle.expiresAt = record.lease.expiresAt
				else
					handle.closed = true
					return false, "save confirmed but profile ownership has moved"
				end
				return true, "saved"
			end
			issue, lost = "save returned an invalid confirmation", true
		elseif not ok then
			issue = `DataStore save {handle.key}: {tostring(result)}`
		end
		if lost then
			handle.closed = true
			break
		end
		if attempt < Settings.Attempts then
			backoff(self, attempt)
		end
	end
	handle.busy = false
	if release then
		handle.closed = true
	end
	return false, issue
end

return Store
