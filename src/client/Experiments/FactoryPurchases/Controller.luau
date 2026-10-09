--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local Config = require(ReplicatedStorage.TycoonShared.Config)
local Rules = require(ReplicatedStorage.TycoonShared.Experiments.FactoryPurchases.Rules)
local Hud = require(script.Parent.Parent.Parent.Hud)
local Activity = require(script.Parent.Activity)
local Controller = {}

function Controller.start(): ScreenGui
	assert(Players.LocalPlayer, "Factory purchases requires LocalPlayer")
	local remote = ReplicatedStorage:WaitForChild(Rules.RemoteName, 10)
	assert(remote and remote:IsA("RemoteEvent"), "Factory walk-on channel missing after 10 seconds")
	local focused = true
	local gui: ScreenGui? = nil
	local released = UserInputService.WindowFocusReleased:Connect(function()
		focused = false
	end)
	local gained = UserInputService.WindowFocused:Connect(function()
		focused = true
	end)
	local offer = remote.OnClientEvent:Connect(function(token: number)
		local current = gui
		if not current or not current.Enabled then
			return
		end
		local panel = current:FindFirstChild("Panel", true)
		assert(panel and panel:IsA("Frame"), "Factory walk-on HUD panel missing")
		if Rules.canRespond(panel.Visible, GuiService.MenuIsOpen, ProximityPromptService.Enabled, focused) then
			remote:FireServer(token)
		end
	end)
	local actual = Hud.startWalkOn()
	gui = actual
	local runtime = workspace:WaitForChild(Config.RuntimeName, 10)
	assert(runtime, "Factory activity runtime missing after 10 seconds")
	local stopActivity = Activity.start(runtime)
	local feedback = ReplicatedStorage:WaitForChild(Config.FeedbackName, 10)
	assert(feedback and feedback:IsA("RemoteEvent"), "Factory purchase feedback missing after 10 seconds")
	-- Roblox-bundled UI tone, no uploaded/external audio dependency.
	local tone = Instance.new("Sound")
	tone.Name, tone.SoundId, tone.Volume, tone.PlaybackSpeed =
		"FactoryPurchaseTone", "rbxasset://sounds/volume_slider.ogg", 0.12, 1.25
	tone.Parent = SoundService
	local result = feedback.OnClientEvent:Connect(function(_plot: number?, message: string)
		if string.sub(message, 1, 10) == "Purchased " then
			SoundService:PlayLocalSound(tone)
		end
	end)
	actual.Destroying:Connect(function()
		gui = nil
		offer:Disconnect()
		released:Disconnect()
		gained:Disconnect()
		result:Disconnect()
		stopActivity()
		tone:Destroy()
	end)
	return actual
end

return Controller
