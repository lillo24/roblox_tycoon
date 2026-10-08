--!strict

-- A small aim sequence, not a beatmap. Coordinates are fractions of the same
-- square play area on every device; its circle and targets scale together.
local Rules = {}
Rules.RemoteName = "AimClash"
Rules.TargetCount = 24
Rules.TargetRadius = 0.11
Rules.StartDelay = 2
Rules.LatencyGrace = 0.18
Rules.FutureSlack = 0.03
Rules.InputInterval = 0.025
Rules.MaxInputs = 128
Rules.InaccuratePenalty = 15
Rules.ComboStep = 0.015
Rules.ComboCap = 10
Rules.SnapshotInterval = 0.1
export type Target = { x: number, y: number, at: number, lifetime: number, weight: number }
local locations: { Vector2 } = {
	Vector2.new(0.5, 0.5),
	Vector2.new(0.3, 0.3),
	Vector2.new(0.63, 0.26),
	Vector2.new(0.76, 0.46),
	Vector2.new(0.57, 0.7),
	Vector2.new(0.29, 0.63),
	Vector2.new(0.25, 0.45),
	Vector2.new(0.5, 0.25),
	Vector2.new(0.7, 0.65),
	Vector2.new(0.43, 0.77),
	Vector2.new(0.32, 0.42),
	Vector2.new(0.63, 0.5),
}

function Rules.pattern(seed: number): { Target }
	local result: { Target } = {}
	local at = 0
	for index = 1, Rules.TargetCount do
		local section = math.floor((index - 1) / 8)
		local interval = if section == 0 then 1 else if section == 1 then 0.7 else 0.46
		local position = locations[((index - 1 + seed) % #locations) + 1]
		-- Alternating reflection changes replay direction without creating a catalogue.
		local x = if seed % 2 == 0 then position.X else 1 - position.X
		table.insert(result, { x = x, y = position.Y, at = at, lifetime = interval * 0.9, weight = 1 + section * 0.15 })
		at += interval
	end
	return result
end

function Rules.duration(pattern: { Target }): number
	local last = pattern[#pattern]
	return last.at + last.lifetime
end

function Rules.targetAt(pattern: { Target }, elapsed: number): number?
	for index, target in pattern do
		if elapsed >= target.at and elapsed <= target.at + target.lifetime then
			return index
		end
	end
	return nil
end

function Rules.phase(pattern: { Target }, elapsed: number): string
	local current = 1
	for index, target in pattern do
		if elapsed >= target.at then
			current = index
		end
	end
	return if current <= 8 then "FOCUS" else if current <= 16 then "FASTER" else "FINAL SURGE"
end

function Rules.finite(value: any): boolean
	return typeof(value) == "number" and value == value and math.abs(value) < math.huge
end

function Rules.validTime(value: any, received: number): boolean
	return Rules.finite(value) and value >= received - Rules.LatencyGrace and value <= received + Rules.FutureSlack
end

function Rules.quality(target: Target, x: number, y: number): number?
	local distanceSquared = (x - target.x) ^ 2 + (y - target.y) ^ 2
	if distanceSquared > Rules.TargetRadius ^ 2 then
		return nil
	end
	-- Center = 1, edge = 0.5. Missed targets contribute zero to fixed denominator.
	return 1 - 0.5 * distanceSquared / Rules.TargetRadius ^ 2
end

-- Width/height describe usable viewport bounds. controlsTop is measured in
-- whole-screen coordinates so camera notches and the Roblox top bar stay clear.
function Rules.boardSize(width: number, height: number, controlsTop: number?): (number, number)
	local top = (controlsTop or 52) + (if height < 430 then 64 else 92)
	local bottom = if height < 430 then 32 else 48
	return math.max(1, math.min(width - 24, height - top - bottom, 560)), (top + height - bottom) / 2
end

return table.freeze(Rules)
