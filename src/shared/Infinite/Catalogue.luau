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
	fixed: boolean?,
	retired: boolean?,
}
local definitions: { Definition } = {
	{
		id = "clay_wheel",
		name = "Potter's wheel",
		cost = 12,
		income = 2,
		width = 8,
		depth = 8,
		kind = "wheel",
		description = "CERAMICS • Watch a bowl turn. +2 / sec",
		unique = true,
	},
	{
		id = "seed_table",
		name = "Seed nursery",
		cost = 12,
		income = 2,
		width = 8,
		depth = 8,
		kind = "nursery",
		description = "GARDEN • Little leaves, room to grow. +2 / sec",
		unique = true,
	},
	{
		id = "prism",
		name = "Prism table",
		cost = 12,
		income = 2,
		width = 8,
		depth = 8,
		kind = "prism",
		description = "SKY • A slowly turning shard of light. +2 / sec",
		unique = true,
	},
	{
		id = "kiln",
		name = "Amber kiln",
		cost = 90,
		income = 5,
		width = 10,
		depth = 10,
		kind = "kiln",
		description = "CERAMICS • A gentle firing cycle. +5 / sec",
		requires = "clay_wheel",
		unique = true,
	},
	{
		id = "greenhouse",
		name = "Glasshouse",
		cost = 90,
		income = 5,
		width = 10,
		depth = 10,
		kind = "greenhouse",
		description = "GARDEN • A glass canopy over living colour. +5 / sec",
		requires = "seed_table",
		unique = true,
	},
	{
		id = "telescope",
		name = "Sky lens",
		cost = 90,
		income = 5,
		width = 12,
		depth = 10,
		kind = "telescope",
		description = "SKY • A slow scan of the horizon. +5 / sec",
		requires = "prism",
		unique = true,
	},
	{
		id = "rear_garden",
		name = "Open the rear garden",
		cost = 220,
		income = 0,
		width = 1,
		depth = 1,
		kind = "expansion",
		description = "Open 800 more square studs and a timber arch. Fixed; existing objects stay put.",
		unique = true,
		fixed = true,
	},
	{
		id = "gallery",
		name = "Ceramic gallery",
		cost = 450,
		income = 8,
		width = 10,
		depth = 8,
		kind = "gallery",
		description = "CERAMICS • Keep a colourful collection on display. +8 / sec",
		requires = "kiln",
		unique = true,
	},
	{
		id = "pond",
		name = "Lily pond",
		cost = 450,
		income = 8,
		width = 10,
		depth = 10,
		kind = "pond",
		description = "GARDEN • Ripples and floating leaves. +8 / sec",
		requires = "greenhouse",
		unique = true,
	},
	{
		id = "orrery",
		name = "Pocket solar system",
		cost = 450,
		income = 8,
		width = 12,
		depth = 10,
		kind = "orrery",
		description = "SKY • Planets trace unhurried orbits. +8 / sec",
		requires = "telescope",
		unique = true,
	},
	{
		id = "flowerbed",
		name = "Meadow box",
		cost = 18,
		income = 0,
		width = 6,
		depth = 4,
		kind = "flowers",
		description = "A bright garden border.",
		requires = "seed_table",
	},
	{
		id = "trellis",
		name = "Climbing trellis",
		cost = 24,
		income = 0,
		width = 6,
		depth = 4,
		kind = "trellis",
		description = "A leafy backdrop to your favourite corner.",
		requires = "greenhouse",
	},
	{
		id = "vases",
		name = "Three glazed vases",
		cost = 18,
		income = 0,
		width = 6,
		depth = 4,
		kind = "vases",
		description = "A handmade shelf for your ceramics.",
		requires = "clay_wheel",
	},
	{
		id = "moon_lamp",
		name = "Moon lantern",
		cost = 18,
		income = 0,
		width = 4,
		depth = 4,
		kind = "moon",
		description = "A soft globe for night-time dreaming.",
		requires = "prism",
	},
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
for _, item in definitions do
	local seen = { [item.id] = true }
	local parent = item.requires
	while parent do
		assert(byId[parent] and not seen[parent], "Infinite: missing or cyclic prerequisite")
		seen[parent] = true
		parent = byId[parent].requires
	end
	assert(
		item.cost % 1 == 0
			and item.cost <= 1000000
			and item.income % 1 == 0
			and item.income <= 100
			and item.width >= 1
			and item.width <= 12
			and item.depth >= 1
			and item.depth <= 10,
		"Infinite: content exceeds bounded tuning"
	)
end
Catalogue.ById = byId
Catalogue.MaxObjects = 64
Catalogue.MaxDecorations = 48 -- Preserve v2's full inventory and reserve room for all equipment/expansions.
Catalogue.Themes = { "Sage", "Terracotta", "Midnight" }
local colors: { [string]: Color3 } = {
	Sage = Color3.fromRGB(128, 171, 140),
	Terracotta = Color3.fromRGB(209, 134, 98),
	Midnight = Color3.fromRGB(113, 145, 198),
}
Catalogue.Colors = colors
return table.freeze(Catalogue)
