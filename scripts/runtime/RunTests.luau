-- Lune executes the exact production/test sources; it is not a Roblox client.
-- No network, TeleportService, DataStoreService, rendering, or physics is used.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local task = require("@lune/task")
local serial = 0
roblox.implementMethod("HttpService", "GenerateGUID", function()
	serial += 1
	return string.format("00000000-0000-0000-0000-%012x", serial)
end)
-- The in-memory profile fixture uses engine JSON solely for serialization.
roblox.implementMethod("HttpService", "JSONEncode", function(_, value)
	return serde.encode("json", value)
end)
roblox.implementMethod("HttpService", "JSONDecode", function(_, value)
	return serde.decode("json", value)
end)
local game = roblox.deserializePlace(fs.readFile("build/ui-review-development-base.rbxlx"))
local modules = game:GetService("ServerScriptService").TycoonServer
local shared = game:GetService("ReplicatedStorage").TycoonShared
local client = game:GetService("StarterPlayer").StarterPlayerScripts.TycoonClient
local cache = {}
local loading = {}
local loadModule
loadModule = function(module)
	assert(module:IsA("ModuleScript"), "Test loader only accepts ModuleScripts")
	if cache[module] ~= nil then
		return cache[module]
	end
	assert(not loading[module], "Circular module dependency: " .. module:GetFullName())
	loading[module] = true
	local environment =
		{ game = game, workspace = game:GetService("Workspace"), script = module, require = loadModule, task = task }
	for _, name in { "Instance", "Color3", "Vector2", "Vector3", "CFrame", "UDim", "UDim2", "Rect", "Enum" } do
		environment[name] = roblox[name]
	end
	local value = luau.load(module.Source, { debugName = module:GetFullName(), environment = environment })()
	assert(value ~= nil, "Module returned no value: " .. module:GetFullName())
	loading[module], cache[module] = nil, value
	return value
end
local function fromFile(path)
	local module = roblox.Instance.new("ModuleScript")
	module.Name, module.Source = path, fs.readFile(path)
	return loadModule(module)
end
local memory = fromFile("tests/fixtures/ProfileMemoryStore.luau")
local suites = {
	{ "Session", { loadModule(modules.Session), loadModule(shared.Config), loadModule(shared.UpgradeCatalogue) } },
	{
		"SupplyEvent",
		{
			loadModule(modules.SupplyEvent),
			loadModule(modules.Session),
			loadModule(shared.SupplyRules),
			loadModule(shared.UpgradeCatalogue),
		},
	},
	{ "SupplyFeedback", { loadModule(client.SupplyFeedback) } },
	{
		"UiState",
		{
			loadModule(client.UiState),
			loadModule(client.UiPreferences),
			loadModule(shared.Config),
			loadModule(shared.UpgradeCatalogue),
		},
	},
	{ "InfiniteState", {} },
	{ "Routing", {} },
	{ "FactoryPurchases", {} },
	{ "AimClash", {} },
	{ "Persistence", { memory } },
	{ "ProfileLifecycle", { memory } },
	{ "Handoff", { memory } },
}
local total = 0
for _, suite in suites do
	local count = fromFile("tests/" .. suite[1] .. ".spec.luau")(table.unpack(suite[2]))
	assert(type(count) == "number" and count > 0, "Suite did not report assertions: " .. suite[1])
	total += count
	print("EXECUTED " .. suite[1] .. ": " .. count .. " assertions")
end
print(
	"Executed "
		.. total
		.. " assertions across "
		.. #suites
		.. " suites in Lune; Roblox client/live-service QA is separate."
)
