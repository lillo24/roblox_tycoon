--!strict

-- Presentation tokens only; no tuning or authoritative gameplay state.
return table.freeze({
	Background = Color3.fromRGB(22, 29, 38),
	Surface = Color3.fromRGB(32, 43, 55),
	Text = Color3.fromRGB(239, 244, 249),
	Muted = Color3.fromRGB(188, 205, 219),
	Accent = Color3.fromRGB(110, 224, 207),
	Warning = Color3.fromRGB(255, 214, 122),
	Owned = Color3.fromRGB(159, 232, 177),
	Font = Enum.Font.Gotham,
	StrongFont = Enum.Font.GothamBold,
	TextSize = 16,
	Target = 44,
	Gap = 8,
	Margin = 12,
	Transparency = 0.08,
})
