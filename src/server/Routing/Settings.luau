--!strict
-- One identical manifest in all three places. Zero/disabled keeps the ordinary
-- Prototype default; no IDs are inferred from teleport payloads or clients.
return table.freeze({
	Enabled = false,
	UniverseId = 0,
	Places = table.freeze({ Entry = 0, Prototype = 0, Infinite = 0 }),
})
