--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.TycoonShared.Config)

local Hud = {}

function Hud.start()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	assert(not playerGui:FindFirstChild(Config.HudName), "Tycoon: HUD started twice")
	local gui = Instance.new("ScreenGui")
	gui.Name = Config.HudName
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.ClipToDeviceSafeArea = true
	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0)
	panel.Position = UDim2.new(0.5, 0, 0, 12)
	panel.Size = UDim2.new(0.86, 0, 0, 90)
	panel.BackgroundColor3 = Color3.fromRGB(24, 28, 36)
	panel.BackgroundTransparency = 0.12
	panel.Parent = gui
	local constraint = Instance.new("UISizeConstraint")
	constraint.MaxSize = Vector2.new(320, 90)
	constraint.Parent = panel
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = panel
	local cash = Instance.new("TextLabel")
	cash.Name = "Cash"
	cash.Position = UDim2.fromOffset(12, 8)
	cash.Size = UDim2.new(1, -24, 0, 30)
	cash.BackgroundTransparency = 1
	cash.TextColor3 = Color3.new(1, 1, 1)
	cash.Font = Enum.Font.GothamBold
	cash.TextSize = 22
	cash.Parent = panel
	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.Position = UDim2.fromOffset(12, 40)
	status.Size = UDim2.new(1, -24, 0, 42)
	status.BackgroundTransparency = 1
	status.TextColor3 = Color3.fromRGB(219, 231, 245)
	status.Font = Enum.Font.Gotham
	status.TextSize = 14
	status.TextWrapped = true
	status.Parent = panel

	local function update()
		local balance = player:GetAttribute(Config.Attributes.Cash)
		local income = player:GetAttribute(Config.Attributes.IncomeRate)
		local plot = player:GetAttribute(Config.Attributes.PlotId)
		cash.Text = if typeof(balance) == "number" then `Cash: {balance}` else "Cash: —"
		if typeof(plot) == "number" and typeof(income) == "number" then
			local hint = if income == Config.UpgradedIncome
				then "Booster active"
				else `Income Booster: {Config.UpgradeCost} cash at your plot`
			status.Text = `Plot {plot} • +{income}/sec\n{hint}`
		else
			status.Text = if player:GetAttribute(Config.Attributes.Assignment) == "Full"
				then "Plots full — no income this session"
				else "Joining…"
		end
	end
	for _, attribute in
		{ Config.Attributes.Cash, Config.Attributes.IncomeRate, Config.Attributes.PlotId, Config.Attributes.Assignment }
	do
		player:GetAttributeChangedSignal(attribute):Connect(update)
	end
	update()
	gui.Parent = playerGui
end

return Hud
