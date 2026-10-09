--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local ContextActionService = game:GetService("ContextActionService")
local Rules = require(ReplicatedStorage.TycoonShared.Experiments.ParryLab.Rules)
local Controller = {}

function Controller.start(): ScreenGui
	local player = Players.LocalPlayer
	assert(player, "Parry Lab requires LocalPlayer")
	local remote = ReplicatedStorage:WaitForChild(Rules.RemoteName, 10)
	assert(remote and remote:IsA("RemoteEvent"), "Parry Lab input channel unavailable after 10 seconds")
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.ResetOnSpawn = "ParryLab", false
	gui.ScreenInsets, gui.ClipToDeviceSafeArea = Enum.ScreenInsets.CoreUISafeInsets, true
	local panel = Instance.new("Frame")
	panel.Name, panel.Size, panel.BackgroundTransparency, panel.Parent = "Interface", UDim2.fromScale(1, 1), 1, gui
	local function label(name: string, text: string, position: UDim2, size: UDim2): TextLabel
		local value = Instance.new("TextLabel")
		value.Name, value.Text, value.Position, value.Size = name, text, position, size
		value.Font, value.TextSize, value.TextWrapped = Enum.Font.GothamMedium, 18, true
		value.TextColor3, value.BackgroundColor3, value.BackgroundTransparency =
			Color3.fromRGB(245, 249, 255), Color3.fromRGB(18, 26, 39), 0.12
		value.Parent = panel
		Instance.new("UICorner", value).CornerRadius = UDim.new(0, 10)
		return value
	end
	local header = label("Status", "PARRY LAB · connecting", UDim2.new(0.08, 0, 0, 12), UDim2.new(0.84, 0, 0, 60))
	header.TextSize = 20
	local cue = label("Cue", "Read the opponent", UDim2.fromScale(0.5, 0.43), UDim2.fromOffset(132, 132))
	cue.AnchorPoint = Vector2.new(0.5, 0.5)
	local cueCorner = cue:FindFirstChildWhichIsA("UICorner")
	assert(cueCorner, "Parry Lab cue corner missing")
	cueCorner.CornerRadius = UDim.new(1, 0)
	local stroke = Instance.new("UIStroke")
	stroke.Parent = cue
	stroke.Thickness, stroke.Color = 4, Color3.fromRGB(255, 178, 75)
	local message = label(
		"Feedback",
		"Q / L2: parry · F / R2: attack\nOr use the two large buttons below",
		UDim2.new(0.08, 0, 1, -150),
		UDim2.new(0.84, 0, 0, 62)
	)
	local reduced = false
	local predictedUntil = 0
	local function send(action: string)
		local now = workspace:GetServerTimeNow()
		remote:FireServer(action, now)
		if action == "parry" then
			predictedUntil = now + Rules.Tuning.ParryWindow
		end
	end
	local function button(name: string, text: string, x: number, callback: () -> ()): TextButton
		local value = Instance.new("TextButton")
		value.Name, value.Text, value.Size = name, text, UDim2.new(0.39, 0, 0, 54)
		value.Position, value.AnchorPoint = UDim2.new(x, 0, 1, -78), Vector2.new(0, 0)
		value.Font, value.TextSize, value.TextColor3 = Enum.Font.GothamBold, 20, Color3.fromRGB(255, 255, 255)
		value.BackgroundColor3, value.Parent = Color3.fromRGB(31, 98, 133), panel
		Instance.new("UICorner", value).CornerRadius = UDim.new(0, 12)
		value.Activated:Connect(function()
			callback()
		end)
		return value
	end
	local parryButton = button("Parry", "PARRY · Q / L2", 0.08, function()
		send("parry")
	end)
	local attackButton = button("Attack", "ATTACK · F / R2", 0.53, function()
		send("attack")
	end)
	attackButton.BackgroundColor3 = Color3.fromRGB(155, 82, 34)
	local restart = button("Restart", "Solo / restart", 0.08, function()
		send("restart")
	end)
	restart.Position, restart.Size, restart.TextSize = UDim2.new(0.08, 0, 0, 82), UDim2.new(0.25, 0, 0, 42), 14
	local queue = button("Queue", "Duel queue", 0.375, function()
		send("queue")
	end)
	queue.Position, queue.Size, queue.TextSize = UDim2.new(0.375, 0, 0, 82), UDim2.new(0.25, 0, 0, 42), 14
	local motion = button("Motion", "Motion: standard", 0.66, function()
		reduced = not reduced
	end)
	motion.Position, motion.Size, motion.TextSize = UDim2.new(0.66, 0, 0, 82), UDim2.new(0.26, 0, 0, 42), 14
	local compact = false
	local function layout()
		compact = gui.AbsoluteSize.Y < 420
		header.Position = UDim2.new(0.08, 0, 0, if compact then 6 else 12)
		header.Size = UDim2.new(0.84, 0, 0, if compact then 44 else 60)
		header.TextSize = if compact then 16 else 20
		for _, control in { restart, queue, motion } do
			control.Position = UDim2.new(control.Position.X.Scale, 0, 0, if compact then 56 else 82)
			control.Size = UDim2.new(control.Size.X.Scale, 0, 0, if compact then 32 else 42)
			control.TextSize = if compact then 12 else 14
		end
		for _, control in { parryButton, attackButton } do
			control.Position = UDim2.new(control.Position.X.Scale, 0, 1, if compact then -60 else -78)
			control.Size = UDim2.new(0.39, 0, 0, if compact then 44 else 54)
			control.TextSize = if compact then 16 else 20
		end
		message.Position = UDim2.new(0.08, 0, 1, if compact then -108 else -150)
		message.Size = UDim2.new(0.84, 0, 0, if compact then 40 else 62)
		message.TextSize = if compact then 14 else 18
		cue.Position = UDim2.fromScale(0.5, if compact then 0.47 else 0.43)
		cue.Size = UDim2.fromOffset(if compact then 84 else 132, if compact then 84 else 132)
	end
	local resized = gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	local function action(name: string, state: Enum.UserInputState): Enum.ContextActionResult
		if state == Enum.UserInputState.Begin then
			send(if name == "ParryLabGuard" then "parry" else "attack")
		end
		return Enum.ContextActionResult.Sink
	end
	ContextActionService:BindAction("ParryLabGuard", action, false, Enum.KeyCode.Q, Enum.KeyCode.ButtonL2)
	ContextActionService:BindAction("ParryLabAttack", action, false, Enum.KeyCode.F, Enum.KeyCode.ButtonR2)
	local snapshot: any = nil
	local function read()
		local value = player:GetAttribute(Rules.StateName)
		if typeof(value) == "string" then
			local ok, decoded = pcall(HttpService.JSONDecode, HttpService, value)
			assert(ok and typeof(decoded) == "table", "Parry Lab server state is invalid JSON")
			snapshot = decoded
		end
	end
	local changed = player:GetAttributeChangedSignal(Rules.StateName):Connect(read)
	read()
	local render = RunService.RenderStepped:Connect(function()
		motion.Text = if reduced or GuiService.ReducedMotionEnabled then "Motion: reduced" else "Motion: standard"
		if not snapshot then
			return
		end
		if snapshot.mode == "ended" then
			header.Text, message.Text, cue.Text = "Session ended", snapshot.message, "Restart"
			return
		end
		local now = workspace:GetServerTimeNow()
		header.Text =
			`{snapshot.mode} · You {snapshot.health} / Opponent {snapshot.opponentHealth}\nParries {snapshot.parries}`
		message.Text = snapshot.message
		queue.Text = if snapshot.queued then "Queued · waiting" else "Duel queue"
		if snapshot.winner ~= nil then
			cue.Text = if snapshot.winner == 0
				then "Trade / draw"
				elseif snapshot.winner == snapshot.actor then "YOU WIN"
				else "Try again"
		elseif snapshot.impact > 0 then
			local remaining = math.max(0, snapshot.impact - now)
			cue.Text = if remaining > 0 then `Incoming\n{string.format("%.2f", remaining)}s` else "IMPACT"
			local diameter = if reduced or GuiService.ReducedMotionEnabled
				then (if compact then 84 else 132)
				else (if compact then 66 else 108) + (if compact then 20 else 72) * math.clamp(
					remaining / Rules.Tuning.Windup,
					0,
					1
				)
			cue.Size = UDim2.fromOffset(diameter, diameter)
		elseif now < snapshot.counterUntil then
			cue.Text = "COUNTER\nAttack now"
		else
			cue.Text = if now >= snapshot.ready then "Parry ready" else "Guard recovering"
			cue.Size = UDim2.fromOffset(if compact then 84 else 132, if compact then 84 else 132)
		end
		stroke.Color = if now < predictedUntil
			then Color3.fromRGB(92, 225, 245)
			elseif now < snapshot.counterUntil then Color3.fromRGB(127, 245, 145)
			else Color3.fromRGB(255, 178, 75)
	end)
	gui.Destroying:Connect(function()
		changed:Disconnect()
		resized:Disconnect()
		render:Disconnect()
		ContextActionService:UnbindAction("ParryLabGuard")
		ContextActionService:UnbindAction("ParryLabAttack")
	end)
	gui.Parent = player:WaitForChild("PlayerGui")
	layout()
	return gui
end

return Controller
