--!strict

-- Studio must explicitly target a separate, already-published test universe.
-- Zero disables real Studio DataStore access; never fall back to memory on error.
return table.freeze({
	StoreName = "InfiniteProfiles_v1",
	StudioTestUniverseId = 0,
	AutoSaveSeconds = 30,
	LoadSeconds = 45,
	LeaseSeconds = 120,
	SafetySeconds = 15,
	Attempts = 4,
	ShutdownSeconds = 25,
	HandoffSeconds = 25, -- Deadline to confirm intentional departure; never cancel an in-flight write.
})
