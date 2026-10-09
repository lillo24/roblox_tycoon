--!strict
-- Infinite content only. Legacy identities preserve the four INF-01 investments.
local Catalogue = {}
export type Definition = {
	id: string,
	name: string,
	cost: number,
	income: number,
	width: number,
	depth: number,
	kind: string,
	description: string,
	requires: string?,
	unique: boolean?,
}
local definitions: { Definition } = {
	{
		id = "income_booster",
		name = "Copper press",
		cost = 10,
		income = 1,
		width = 8,
		depth = 8,
		kind = "press",
		description = "A sturdy first machine. +1 / sec",
		unique = true,
	},
	{
		id = "workshop",
		name = "Workbench",
		cost = 30,
		income = 3,
		width = 8,
		depth = 8,
		kind = "workshop",
		description = "Room for bright ideas. +3 / sec",
		unique = true,
	},
	{
		id = "booster_tuning",
		name = "Press control",
		cost = 25,
		income = 2,
		width = 8,
		depth = 8,
		kind = "press",
		description = "A companion to your press. +2 / sec",
		requires = "income_booster",
		unique = true,
	},
	{
		id = "workshop_expansion",
		name = "Tool station",
		cost = 60,
		income = 5,
		width = 8,
		depth = 8,
		kind = "workshop",
		description = "Keep the original bench and add tools. +5 / sec",
		requires = "workshop",
		unique = true,
	},
	{
		id = "planter",
		name = "Fern planter",
		cost = 3,
		income = 0,
		width = 4,
		depth = 4,
		kind = "plant",
		description = "A small patch of green. Buy more than one.",
	},
	{
		id = "bench",
		name = "Garden bench",
		cost = 6,
		income = 0,
		width = 8,
		depth = 4,
		kind = "bench",
		description = "A welcoming corner for visitors.",
	},
	{
		id = "lantern",
		name = "Amber lantern",
		cost = 2,
		income = 0,
		width = 2,
		depth = 2,
		kind = "lantern",
		description = "A warm glow without particles.",
	},
	{
		id = "mosaic",
		name = "Clay mosaic",
		cost = 4,
		income = 0,
		width = 6,
		depth = 4,
		kind = "mosaic",
		description = "A patterned island of colour.",
	},
}
Catalogue.Definitions = definitions
local byId: { [string]: Definition } = {}
for _, item in definitions do
	assert(not byId[item.id] and item.cost >= 0 and item.income >= 0, "Infinite: invalid catalogue")
	byId[item.id] = item
end
Catalogue.ById = byId
Catalogue.MaxObjects = 48
Catalogue.Themes = { "Sage", "Terracotta", "Midnight" }
local colors: { [string]: Color3 } = {
	Sage = Color3.fromRGB(128, 171, 140),
	Terracotta = Color3.fromRGB(209, 134, 98),
	Midnight = Color3.fromRGB(113, 145, 198),
}
Catalogue.Colors = colors
return table.freeze(Catalogue)
