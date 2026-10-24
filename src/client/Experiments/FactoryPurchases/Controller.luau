--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage.TycoonShared.Config)
local Rules = require(ReplicatedStorage.TycoonShared.Experiments.FactoryPurchases.Rules)
local Hud = require(script.Parent.Parent.Parent.Hud)
local Activity = require(script.Parent.Activity)
local VisitGate = require(script.Parent.VisitGate)
local Controller = {}

function Controller.start(): ScreenGui
	local player = Players.LocalPlayer
	assert(player, "Factory purchases requires LocalPlayer")
	local remote = ReplicatedStorage:WaitForChild(Rules.RemoteName, 10)
	assert(remote and remote:IsA("RemoteEvent"), "Factory walk-on channel missing after 10 seconds")
	local focused = true
	local gui: ScreenGui? = nil
	local gate = VisitGate.new()
	local function sample()
		local current = gui
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local panel = current and current:FindFirstChild("Panel", true)
		local chooser = current and current.Parent and current.Parent:FindFirstChild("TycoonModeChooser")
		local modal = not current
			or not current.Enabled
			or not panel
			or not panel:IsA("Frame")
			or panel.Visible
			or (chooser ~= nil and chooser:GetAttribute("ModalOpen") == true)
			or GuiService.MenuIsOpen
			or UserInputService:GetFocusedTextBox() ~= nil
			or not ProximityPromptService.Enabled
			or not focused
		local samples: { VisitGate.Sample } = {}
		local world = workspace:FindFirstChild(Config.RuntimeName)
		local plot = world and world:FindFirstChild(`Plot{player:GetAttribute(Config.Attributes.PlotId)}`)
		if
			root
			and root:IsA("BasePart")
			and plot
			and plot:GetAttribute(Config.Attributes.OwnerUserId) == player.UserId
		then
			for _, pad in plot:GetChildren() do
				if pad:IsA("BasePart") and pad.Name:sub(1, 4) == "Pad_" then
					local position = pad.CFrame:PointToObjectSpace(root.Position)
					table.insert(samples, {
						key = pad.Name,
						inside = Rules.contains(position, pad.Size, false),
						withinExit = Rules.contains(position, pad.Size, true),
					})
				end
			end
		end
		gate:sample(character, modal, samples)
	end
	local released = UserInputService.WindowFocusReleased:Connect(function()
		focused = false
	end)
	local gained = UserInputService.WindowFocused:Connect(function()
		focused = true
	end)
	local elapsed = 0
	local sampler = RunService.Heartbeat:Connect(function(delta)
		elapsed += delta
		if elapsed >= Rules.SampleInterval then
			elapsed = 0
			sample()
		end
	end)
	local offer = remote.OnClientEvent:Connect(function(token: number, plotId: number, upgradeId: string)
		sample()
		if
			plotId ~= player:GetAttribute(Config.Attributes.PlotId)
			or typeof(upgradeId) ~= "string"
			or not gate:respond("Pad_" .. upgradeId)
		then
			return
		end
		local current = gui
		if not current or not current.Enabled then
			return
		end
		local panel = current:FindFirstChild("Panel", true)
		assert(panel and panel:IsA("Frame"), "Factory walk-on HUD panel missing")
		local chooser = current.Parent and current.Parent:FindFirstChild("TycoonModeChooser")
		local modal = panel.Visible or (chooser ~= nil and chooser:GetAttribute("ModalOpen") == true)
		if
			Rules.canRespond(
				modal,
				GuiService.MenuIsOpen or UserInputService:GetFocusedTextBox() ~= nil,
				ProximityPromptService.Enabled,
				focused
			)
		then
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
		sampler:Disconnect()
		released:Disconnect()
		gained:Disconnect()
		result:Disconnect()
		stopActivity()
		tone:Destroy()
	end)
	return actual
end

return Controller
