--!strict

-- Play-only injected delivery ordering through actual Hud/RemoteEvent handlers.
-- The caller installs UI01OrderQA temporarily; nothing here maps to production.
local Client = game:GetService("StarterPlayer").StarterPlayerScripts.TycoonClient
local HudTypes = require(Client.Hud)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rules = require(ReplicatedStorage.TycoonShared.SupplyRules)
local Config = require(ReplicatedStorage.TycoonShared.Config)

return function(Hud: typeof(HudTypes), fixtureRemote: RemoteEvent): number
	assert(type(HudTypes.start) == "function", "Actual HUD interface required")
	local player = game:GetService("Players").LocalPlayer
	assert(player, "HUD feedback test requires a Play client")
	local state = ReplicatedStorage:FindFirstChild(Rules.StateName)
	assert(state and state:IsA("StringValue"), "HUD feedback test requires live snapshot")
	local holder = Instance.new("Folder")
	holder.Name, holder.Parent = "UI01HeldSnapshot", ReplicatedStorage
	local checks = 0
	local function check(condition: boolean, message: string)
		assert(condition, message)
		checks += 1
	end
	local ok, failure = xpcall(function()
		state.Parent = holder -- Client-only; server snapshot/phase/economy is untouched.
		task.spawn(Hud.start)
		task.wait(0.2)
		local playerGui = player:FindFirstChildOfClass("PlayerGui")
		assert(playerGui, "HUD feedback test missing PlayerGui")
		local gui = playerGui:FindFirstChild(Config.HudName)
		assert(gui and gui:IsA("ScreenGui"), "HUD must exist before snapshot wait completes")
		local supply = gui:FindFirstChild("SupplyResult", true) :: TextLabel
		local purchase = gui:FindFirstChild("PurchaseResult", true) :: TextLabel
		local event = gui:FindFirstChild("Event", true) :: TextLabel
		check(string.find(event.Text, "Waiting for server state", 1, true) ~= nil, "Truthful event loading")
		fixtureRemote:FireServer()
		task.wait(0.3)
		check(supply.Text == "", "Private response before first snapshot remains pending")
		check(purchase.Text == "UI01 independent purchase", "Purchase result independent of pending supply")
		task.wait(0.8)
		state.Parent = ReplicatedStorage
		task.wait(0.1)
		check(supply.Text == "UI01 receipt-before-snapshot", "Listener-before-wait retained actual remote response")
		check(string.find(event.Text, "UI01 receipt", 1, true) == nil, "Private text never becomes public event state")
		task.wait(2)
		check(supply.Text == "", "Matching snapshot did not restart receipt lifetime")
		check(purchase.Text == "", "Independent purchase result expired")
		return checks
	end, function(message: any): string
		return debug.traceback(tostring(message), 2)
	end)
	state.Parent = ReplicatedStorage
	holder:Destroy()
	if not ok then
		error(failure)
	end
	return checks
end
