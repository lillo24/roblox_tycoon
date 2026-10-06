--!strict

-- Provisional session tuning; catalogue prices/effects live only in UpgradeCatalogue.
return table.freeze({
	PlotCount = 4,
	StartingCash = 0,
	BaseIncome = 1,
	IncomeInterval = 1,
	PromptDistance = 10,
	-- A smaller display radius lets players select one of four separated pads.
	PurchasePromptDistance = 4,
	RequestInterval = 0.25,
	FeedbackDuration = 3,
	FeedbackName = "TycoonPurchaseFeedback",
	RuntimeName = "TycoonRuntime",
	HudName = "TycoonHud",
	-- World X/Z offsets from the authored spawn, in the inspected clear corridor.
	PlotOffsets = table.freeze({
		Vector3.new(-6, 0, 42),
		Vector3.new(6, 0, 42),
		Vector3.new(-6, 0, 54),
		Vector3.new(6, 0, 54),
	}),
	Attributes = table.freeze({
		Cash = "TycoonCash",
		PlotId = "TycoonPlotId",
		IncomeRate = "TycoonIncomeRate",
		Assignment = "TycoonAssignment",
		OwnerUserId = "TycoonOwnerUserId",
	}),
})
