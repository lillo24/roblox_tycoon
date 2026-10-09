--!strict
-- Resolve the server's role before starting any gameplay or profile lifecycle.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Mode = require(ReplicatedStorage.TycoonShared.GameMode)
local Configuration = require(script.Parent.Routing.Configuration)
local Settings = require(script.Parent.Routing.Settings)
local Routing = require(script.Parent.Routing.Runtime)
local Tycoon = require(script.Parent.TycoonRuntime)
local App = {}
export type Preview = {
	manifest: Configuration.Manifest,
	universe: number,
	place: number,
	known: { [number]: boolean },
	adapter: Routing.Preview,
}
local function membership(): ({ [number]: boolean }?, string?)
	local ok, result = pcall(function()
		local pages = game:GetService("AssetService"):GetGamePlacesAsync()
		assert(pages:IsA("Pages"), "Expected place pages from AssetService")
		local known: { [number]: boolean } = {}
		for _ = 1, 100 do
			for _, item in pages:GetCurrentPage() do
				known[item.PlaceId] = true
			end
			if pages.IsFinished then
				return known
			end
			pages:AdvanceToNextPageAsync()
		end
		error("Experience place listing exceeded 100 pages")
	end)
	if not ok then
		return nil, "Could not verify experience destinations: " .. tostring(result)
	end
	return result, nil
end
function App.start(backend: Tycoon.Preview?, preview: Preview?)
	assert(RunService:IsServer(), "App starts on server only")
	assert(not preview or RunService:IsStudio(), "Routing fixture is Studio-only")
	assert(ReplicatedStorage:GetAttribute("TycoonServerRole") == nil, "App started twice")
	local known, issue
	if not preview and Settings.Enabled then
		known, issue = membership()
	end
	local configuration = if preview
		then Configuration.resolve(preview.manifest, preview.universe, preview.place, Mode.read(), preview.known)
		else Configuration.resolve({
			Enabled = Settings.Enabled,
			UniverseId = Settings.UniverseId,
			Places = {
				Entry = Settings.Places.Entry,
				Prototype = Settings.Places.Prototype,
				Infinite = Settings.Places.Infinite,
			},
		}, game.GameId, game.PlaceId, if RunService:IsStudio() then Mode.read() else nil, known)
	if issue then
		configuration.issue = issue
		warn(issue)
	end
	if configuration.role == "Unavailable" then
		warn("Mode startup: " .. (configuration.issue or "Invalid configuration"))
	end
	ReplicatedStorage:SetAttribute("TycoonServerRole", configuration.role)
	ReplicatedStorage:SetAttribute("TycoonModeIssue", configuration.issue or "")
	local lifecycle = if configuration.role == "Prototype" or configuration.role == "Infinite"
		then Tycoon.start(backend)
		else nil
	Routing.start(configuration, lifecycle, if preview then preview.adapter else nil)
end
return App
