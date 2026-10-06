--!strict

-- Private presentation only. One latest result may await its public snapshot;
-- its lifetime always starts at receipt, never at snapshot arrival.
local SupplyFeedback = {}
SupplyFeedback.__index = SupplyFeedback

type Message = { id: number, text: string, expiresAt: number }
type Data = {
	lifetime: number,
	snapshotId: number?,
	snapshotIdle: boolean,
	latestId: number?,
	message: Message?,
	version: number,
}
export type State = typeof(setmetatable({} :: Data, SupplyFeedback))

function SupplyFeedback.new(lifetime: number): State
	assert(lifetime > 0 and lifetime < math.huge, "Supply feedback: lifetime must be finite and positive")
	return setmetatable({ lifetime = lifetime, snapshotIdle = false, version = 0 }, SupplyFeedback)
end

-- Keep the public identity, but invalidate retained work and every old timeout.
-- Assignment changes/teardown call this; ordinary character respawn does not.
function SupplyFeedback.reset(self: State)
	self.version += 1
	self.message, self.latestId = nil, nil
end

function SupplyFeedback.expire(self: State, version: number, now: number): boolean
	local message = self.message
	if version ~= self.version or not message or now < message.expiresAt then
		return false
	end
	self.version += 1
	self.message = nil
	return true
end

function SupplyFeedback.read(self: State, now: number): string
	self:expire(self.version, now)
	local message = self.message
	return if message and message.id == self.snapshotId then message.text else ""
end

-- IDs describe the server's current event at response time, including rejections.
-- A newer response replaces the single retained record, without advancing public state.
function SupplyFeedback.receive(self: State, id: number, text: string, now: number): number?
	if (self.snapshotId and id < self.snapshotId) or (self.latestId and id < self.latestId) then
		return nil
	end
	self.version += 1
	self.latestId = id -- Retain this scalar after expiry so older responses cannot revive.
	self.message = { id = id, text = text, expiresAt = now + self.lifetime }
	return self.version -- Identical repeats still get a new lifetime/token.
end

function SupplyFeedback.snapshot(self: State, id: number, idle: boolean, now: number): boolean
	local previous = self.snapshotId
	if previous and id < previous then
		return false
	end
	local cancelled = idle and previous ~= nil and (id ~= previous or not self.snapshotIdle)
	self.snapshotId, self.snapshotIdle = id, idle
	if cancelled then
		self:reset() -- Cancellation discards even a buffered future response.
	elseif self.message and self.message.id < id then
		self.message = nil
		self.version += 1
	end
	self:read(now) -- A matching late snapshot cannot resurrect an expired result.
	return true
end

return SupplyFeedback
