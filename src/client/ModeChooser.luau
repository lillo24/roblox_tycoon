--!strict
-- Local presentation of a server-owned transition. A click requests a role,
-- never a place ID or a change to the mode of this server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.TycoonShared.Config)
local Modes = require(ReplicatedStorage.TycoonShared.GameMode)
local GuiService = game:GetService("GuiService")
local Input = game:GetService("UserInputService")
local Chooser = {}
function Chooser.start(role: string): ScreenGui
	local player = Players.LocalPlayer
	assert(player, "Mode chooser requires a client")
	local hud = player:WaitForChild("PlayerGui"):FindFirstChild(Config.HudName)
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.ResetOnSpawn, gui.DisplayOrder = "TycoonModeChooser", false, 50
	gui.ScreenInsets, gui.ClipToDeviceSafeArea = Enum.ScreenInsets.CoreUISafeInsets, true
	local panel = Instance.new("Frame")
	panel.Name, panel.AnchorPoint, panel.Position = "Chooser", Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
	panel.Size, panel.BackgroundColor3, panel.Parent = UDim2.fromScale(0.94, 0.9), Color3.fromRGB(28, 43, 40), gui
	local bounds = Instance.new("UISizeConstraint")
	bounds.MaxSize, bounds.Parent = Vector2.new(620, 680), panel
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name, scroll.Position, scroll.Size = "Content", UDim2.fromOffset(18, 14), UDim2.new(1, -36, 1, -28)
	scroll.BackgroundTransparency, scroll.BorderSizePixel, scroll.ScrollBarThickness = 1, 0, 5
	scroll.CanvasSize, scroll.AutomaticCanvasSize, scroll.Parent = UDim2.new(), Enum.AutomaticSize.Y, panel
	local layout = Instance.new("UIListLayout")
	layout.Padding, layout.SortOrder, layout.Parent = UDim.new(0, 14), Enum.SortOrder.LayoutOrder, scroll
	local order = 0
	local function label(name: string, value: string, size: number): TextLabel
		order += 1
		local item = Instance.new("TextLabel")
		item.Name, item.Text, item.TextSize, item.Font = name, value, size, Enum.Font.Gotham
		item.Size, item.AutomaticSize, item.BackgroundTransparency = UDim2.new(1, -6, 0, 0), Enum.AutomaticSize.Y, 1
		item.TextColor3, item.TextWrapped, item.LayoutOrder, item.Parent =
			Color3.fromRGB(239, 237, 216), true, order, scroll
		return item
	end
	local function button(name: string, value: string): TextButton
		order += 1
		local item = Instance.new("TextButton")
		item.Name, item.Text, item.TextSize, item.Font = name, value, 17, Enum.Font.GothamMedium
		item.Size, item.BackgroundColor3, item.TextColor3 =
			UDim2.new(1, -6, 0, 58), Color3.fromRGB(83, 116, 94), Color3.fromRGB(255, 252, 235)
		item.TextWrapped, item.LayoutOrder, item.Parent = true, order, scroll
		return item
	end
	label("Title", if role == "Entry" then "Choose your game mode" else "Back to modes", 25)
	label("Intro", "Factory Challenge · Infinite World · Aim Clash", 16)
	local status = label("Status", "Connecting to the mode service…", 16)
	local preview = label("Preview", "", 14)
	local buttons: { [string]: TextButton } = {}
	local ordered: { TextButton } = {}
	if role == "Entry" then
		for _, choice in Modes.Choices do
			local item = button(choice.role, choice.name .. "\n" .. choice.detail)
			item.Size = UDim2.new(1, -6, 0, 94)
			item:SetAttribute("DestinationRole", choice.role)
			buttons[choice.role] = item
			table.insert(ordered, item)
		end
	elseif role ~= "Unavailable" then
		label(
			"ReturnDescription",
			if role == "Infinite"
				then "Leaving confirms a checkpoint first. Earnings and editing pause during the move."
				elseif
					role == "Clash"
				then "You can return at any time. Leaving cancels an unfinished duel without a winner."
				else "Factory progress ends when you leave this server.",
			17
		)
		buttons.Entry = button("Entry", "Return to mode selection")
		table.insert(ordered, buttons.Entry)
	end
	local reload = button("Reload", "Reload my saved place")
	local stay = button("Stay", "Stay in this server")
	local launcher = button("Modes", "Modes")
	launcher.Parent, launcher.Position, launcher.Size = gui, UDim2.new(1, -112, 0, 12), UDim2.fromOffset(100, 44)
	launcher.LayoutOrder = 0
	local open = role == "Entry" or role == "Unavailable"
	local remote: RemoteEvent? = nil
	local view = { phase = "Loading", message = "", revision = -1, attempts = 0 }
	local pending = false
	local enabled = false
	local connections: { RBXScriptConnection } = {}
	for index, item in ordered do
		item.Selectable = true
		item.NextSelectionUp = ordered[if index == 1 then #ordered else index - 1]
		item.NextSelectionDown = ordered[if index == #ordered then 1 else index + 1]
	end
	local function render()
		local assignment = player:GetAttribute(Config.Attributes.Assignment)
		local blocked = not table.find({ "Idle", "Failed", "Unavailable" }, view.phase) or pending
		panel.Visible = open
		gui:SetAttribute("ModalOpen", open)
		-- The property editor hides the HUD; keep its narrow-screen title clear.
		launcher.Visible = not open
			and role ~= "Entry"
			and role ~= "Unavailable"
			and (not hud or not hud:IsA("ScreenGui") or hud.Enabled)
		status.Text = if pending then "Requesting… please wait" else view.message
		for _, item in buttons do
			item.Active, item.AutoButtonColor = enabled and not blocked and view.attempts < 3, enabled and not blocked
			item.BackgroundColor3 = if item.Active then Color3.fromRGB(83, 116, 94) else Color3.fromRGB(59, 72, 67)
		end
		reload.Visible = role == "Infinite" and assignment ~= "Ready"
		reload.Active, reload.AutoButtonColor = not blocked, not blocked
		reload.BackgroundColor3 = if reload.Active then Color3.fromRGB(83, 116, 94) else Color3.fromRGB(59, 72, 67)
		stay.Visible = role ~= "Entry"
			and role ~= "Unavailable"
			and not blocked
			and (role ~= "Infinite" or assignment == "Ready")
		local navigation: { TextButton } = {}
		for _, item in ordered do
			item.Selectable = item.Active
			if item.Active then
				table.insert(navigation, item)
			end
		end
		for _, item in { reload, stay } do
			item.Selectable = item.Visible and item.Active
			if item.Selectable then
				table.insert(navigation, item)
			end
		end
		for index, item in navigation do
			item.NextSelectionUp = navigation[if index == 1 then #navigation else index - 1]
			item.NextSelectionDown = navigation[if index == #navigation then 1 else index + 1]
		end
		local selected = GuiService.SelectedObject
		if not open and selected and selected:IsDescendantOf(gui) then
			GuiService.SelectedObject = nil
		elseif
			open
			and Input.PreferredInput == Enum.PreferredInput.Gamepad
			and (not selected or not selected.Selectable)
		then
			GuiService.SelectedObject = navigation[1]
		end
	end
	local function send(choice: string)
		local currentRemote = remote
		if pending or not currentRemote or not table.find({ "Idle", "Failed", "Unavailable" }, view.phase) then
			return
		end
		pending = true
		scroll.CanvasPosition = Vector2.zero -- Keep joining/failure feedback visible after a mobile choice.
		render()
		currentRemote:FireServer(choice, view.revision)
		-- Lost response recovery reads state only. Never resubmit a transition.
		task.delay(8, function()
			if gui.Parent and pending and remote then
				remote:FireServer("read")
			end
		end)
	end
	for name, item in buttons do
		table.insert(
			connections,
			item.Activated:Connect(function()
				if item.Active then
					send(name)
				end
			end)
		)
	end
	table.insert(
		connections,
		reload.Activated:Connect(function()
			if reload.Active then
				send("reload")
			end
		end)
	)
	table.insert(
		connections,
		stay.Activated:Connect(function()
			open = false
			render()
		end)
	)
	table.insert(
		connections,
		launcher.Activated:Connect(function()
			open = true
			render()
			if Input.PreferredInput == Enum.PreferredInput.Gamepad then
				GuiService.SelectedObject = ordered[1] or stay
			end
		end)
	)
	table.insert(
		connections,
		Input.InputBegan:Connect(function(input, processed)
			if processed or Input:GetFocusedTextBox() or GuiService.MenuIsOpen then
				return
			end
			if input.KeyCode == Enum.KeyCode.M or input.KeyCode == Enum.KeyCode.ButtonSelect then
				if launcher.Visible then
					open = true
					render()
					GuiService.SelectedObject = ordered[1] or stay
				end
			elseif input.KeyCode == Enum.KeyCode.ButtonB and stay.Visible and stay.Active then
				open = false
				render()
			end
		end)
	)
	table.insert(
		connections,
		player:GetAttributeChangedSignal(Config.Attributes.Assignment):Connect(function()
			local assignment = player:GetAttribute(Config.Attributes.Assignment)
			if assignment == "Full" or assignment == "Unavailable" then
				open = true
			end
			render()
		end)
	)
	gui.Parent = player:WaitForChild("PlayerGui")
	if role == "Entry" and Input.PreferredInput == Enum.PreferredInput.Gamepad then
		GuiService.SelectedObject = ordered[1]
	end
	if hud and hud:IsA("ScreenGui") then
		table.insert(connections, hud:GetPropertyChangedSignal("Enabled"):Connect(render))
	end
	render()
	task.spawn(function()
		local object = ReplicatedStorage:WaitForChild("TycoonRoutes", 20)
		if not gui.Parent then
			return
		end
		if not object or not object:IsA("RemoteEvent") then
			view.message = "Mode service unavailable. Leave and rejoin after the server is ready."
			render()
			return
		end
		remote = object
		enabled = object:GetAttribute("Enabled") == true
		preview.Text = tostring(object:GetAttribute("Preview") or "")
		table.insert(
			connections,
			object.OnClientEvent:Connect(function(nextView: any)
				if
					typeof(nextView) ~= "table"
					or typeof(nextView.revision) ~= "number"
					or nextView.revision < view.revision
				then
					return
				end
				view, pending = nextView, false
				if not enabled then
					view.message = tostring(object:GetAttribute("Issue"))
				elseif role == "Unavailable" then
					-- Startup's bounded role wait expired before this service arrived.
					view.message =
						"This client could not confirm its mode in time. Leave and rejoin to load the ready server."
				end
				render()
			end)
		)
		object:FireServer("read")
	end)
	gui.Destroying:Connect(function()
		for _, connection in connections do
			connection:Disconnect()
		end
	end)
	return gui
end
return Chooser
