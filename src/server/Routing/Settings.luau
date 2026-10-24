--!strict
-- Release assembly injects the same four-place manifest plus this artifact's
-- expected BuildRole. IDs stay in Actions variables, never client/teleport data.
-- A source checkout opens Entry in Studio; hosted unconfigured builds fail closed.
return table.freeze({
	Enabled = false,
	BuildRole = "Entry",
	UniverseId = 0,
	Places = table.freeze({ Entry = 0, Prototype = 0, Infinite = 0, Clash = 0 }),
})
