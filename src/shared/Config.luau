--!strict

-- Provisional session tuning; catalogue prices/effects live only in UpgradeCatalogue.
return table.freeze({
	PlotCount = 6,
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
	-- Layout belongs to the saved scene; see place/README.md for the anchor contract.
	MapName = "FactoryHub",
	Attributes = table.freeze({
		Cash = "TycoonCash",
		PlotId = "TycoonPlotId",
		IncomeRate = "TycoonIncomeRate",
		Assignment = "TycoonAssignment",
		SaveStatus = "TycoonSaveStatus",
		OwnerUserId = "TycoonOwnerUserId",
	}),
})
