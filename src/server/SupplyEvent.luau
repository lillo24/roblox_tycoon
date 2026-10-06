--!strict

-- Deadline state and the one atomic reward operation; no Instances or clock reads.
local Rules = require(game:GetService("ReplicatedStorage").TycoonShared.SupplyRules)
local Session = require(script.Parent.Session)

local SupplyEvent = {}
SupplyEvent.__index = SupplyEvent
type Data = {
	tuning: Rules.Tuning,
	serial: number,
	firstOpensAt: number?,
	index: number,
	opensAt: number,
	closesAt: number,
	resultUntil: number,
	winnerUserId: number?,
	winnerName: string?,
	lastNow: number,
	phase: Rules.Phase,
}
export type Event = typeof(setmetatable({} :: Data, SupplyEvent))
export type ClaimReason = "claimed" | "inactive" | "stale" | "closed" | "already-claimed"

function SupplyEvent.new(tuning: Rules.Tuning): Event
	return setmetatable({
		tuning = Rules.validate(tuning),
		serial = 0,
		firstOpensAt = nil,
		index = 0,
		opensAt = 0,
		closesAt = 0,
		resultUntil = 0,
		winnerUserId = nil,
		winnerName = nil,
		lastNow = 0,
		phase = "idle" :: Rules.Phase,
	}, SupplyEvent)
end

local function validTime(self: Event, now: number)
	assert(now >= 0 and now < math.huge, "Supply Cache: time must be finite and nonnegative")
	assert(now >= self.lastNow, "Supply Cache: time must not move backwards")
	assert(now + self.tuning.Interval > now, "Supply Cache: time is too large for deadlines")
end

function SupplyEvent.sync(self: Event, now: number, assignedCount: number)
	validTime(self, now)
	assert(assignedCount >= 0 and assignedCount % 1 == 0, "Supply Cache: assigned count must be a nonnegative integer")
	self.lastNow = now
	if assignedCount == 0 then
		if self.firstOpensAt then
			self.serial += 1
		end -- Invalidate every old interaction, including pending ones.
		self.firstOpensAt = nil
		self.opensAt, self.closesAt, self.resultUntil = 0, 0, 0
		self.winnerUserId, self.winnerName = nil, nil
		self.phase = "idle"
		return
	end
	local first = self.firstOpensAt
	if not first then
		first = now + self.tuning.FirstDelay
		self.firstOpensAt = first
		self.index = 0
		self.serial += 1
		self.opensAt = first
		self.closesAt = first + self.tuning.Window
	end
	-- Jump directly to the current warning/window; never replay missed openings.
	assert(first, "Supply Cache: active schedule lacks its first deadline")
	local index = math.max(0, math.floor((now - first + self.tuning.Warning) / self.tuning.Interval))
	if index > self.index then
		self.serial += index - self.index
		self.index = index
		self.opensAt = first + index * self.tuning.Interval
		self.closesAt = self.opensAt + self.tuning.Window
		self.resultUntil = 0
		self.winnerUserId, self.winnerName = nil, nil
	end
	if self.winnerUserId then
		self.phase = if now < self.resultUntil then "result" else "waiting"
	elseif now >= self.closesAt then
		self.resultUntil = self.closesAt + self.tuning.ResultDuration
		self.phase = if now < self.resultUntil then "result" else "waiting"
	elseif now >= self.opensAt then
		self.phase = "open"
	elseif now >= self.opensAt - self.tuning.Warning then
		self.phase = "warning"
	else
		self.phase = "waiting"
	end
end

function SupplyEvent.snapshot(self: Event): Rules.Snapshot
	local nextOpening = if self.phase == "idle" then 0 else self.opensAt
	if self.phase ~= "idle" and (self.winnerUserId or self.lastNow >= self.closesAt) then
		nextOpening += self.tuning.Interval
	end
	local deadline = if self.phase == "idle"
		then 0
		elseif self.phase == "open" then self.closesAt
		elseif self.phase == "result" then self.resultUntil
		else nextOpening
	return table.freeze({
		id = self.serial,
		phase = self.phase,
		opensAt = self.opensAt,
		closesAt = self.closesAt,
		nextOpensAt = nextOpening,
		deadline = deadline,
		reward = self.tuning.Reward,
		winnerUserId = if self.phase == "result" then self.winnerUserId else nil,
		winnerName = if self.phase == "result" then self.winnerName else nil,
	})
end

-- First valid request processed by the server wins; not local press order or latency compensation.
-- Credit and resolution cannot yield. A failed Session credit never consumes this event.
function SupplyEvent.claim(
	self: Event,
	session: Session.Session,
	userId: number,
	name: string,
	id: number,
	now: number
): (boolean, ClaimReason)
	validTime(self, now)
	if not session:get(userId) then
		return false, "inactive"
	end
	self:sync(now, session:assignedCount())
	if id ~= self.serial then
		return false, "stale"
	end
	if not self.firstOpensAt or now < self.opensAt or now >= self.closesAt then
		return false, "closed"
	end
	if self.winnerUserId then
		return false, "already-claimed"
	end
	if not session:credit(userId, self.tuning.Reward) then
		return false, "inactive"
	end
	self.winnerUserId, self.winnerName = userId, name
	self.resultUntil = now + self.tuning.ResultDuration
	self.phase = "result"
	return true, "claimed"
end

return SupplyEvent
