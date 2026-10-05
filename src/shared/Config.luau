--!strict

-- Temporary GAMEPLAY-01 tuning; these values have no persistence semantics.
return table.freeze({
	PlotCount = 4,
	StartingCash = 0,
	BaseIncome = 1,
	UpgradedIncome = 2,
	UpgradeCost = 10,
	IncomeInterval = 1,
	PromptDistance = 10,
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
		Purchased = "TycoonUpgradePurchased",
	}),
})
