--!strict

local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Catalogue = require(ReplicatedStorage.TycoonShared.UpgradeCatalogue)
local State = require(script.Parent.UiState)
local Preferences = require(script.Parent.UiPreferences)
local Theme = require(script.Parent.UiTheme)

local View = {}
export type Handle = {
	economy: (State.Economy) -> (),
	event: (string, string?) -> (),
	feedback: (string, string) -> (),
	guidance: (string, boolean, boolean) -> (),
	context: (string, boolean, string, string) -> (),
	refresh: () -> (),
	destroy: () -> (),
}
export type Actions = { find: () -> (), stop: () -> (), dismiss: () -> (), restart: () -> (), panel: (boolean) -> () }

local function list(parent: Instance, gap: number)
	local layout = Instance.new("UIListLayout")
	layout.Padding, layout.SortOrder = UDim.new(0, gap), Enum.SortOrder.LayoutOrder
	layout.Parent = parent
end

local function text(parent: Instance, name: string, value: string): TextLabel
	local label = Instance.new("TextLabel")
	label.Name, label.Text = name, value
	label.Size, label.AutomaticSize = UDim2.fromScale(1, 0), Enum.AutomaticSize.Y
	label.BackgroundTransparency = 1
	label.Font, label.TextSize, label.TextColor3 = Theme.Font, Theme.TextSize, Theme.Text
	label.TextWrapped, label.TextScaled = true, false
	label.TextXAlignment, label.TextYAlignment = Enum.TextXAlignment.Left, Enum.TextYAlignment.Top
	label.Active, label.Selectable = false, false
	label.Parent = parent
	return label
end

local function frame(parent: Instance, name: string): Frame
	local object = Instance.new("Frame")
	object.Name, object.BackgroundColor3 = name, Theme.Background
	object.BorderSizePixel = 0
	object.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0, 8), object
	return object
end

local function button(parent: Instance, name: string, value: string): TextButton
	local object = Instance.new("TextButton")
	object.Name, object.Text = name, value
	object.Size, object.AutomaticSize = UDim2.new(1, 0, 0, Theme.Target), Enum.AutomaticSize.Y
	object.Font, object.TextSize = Theme.StrongFont, Theme.TextSize
	object.TextColor3, object.BackgroundColor3 = Theme.Text, Theme.Surface
	object.TextWrapped, object.AutoButtonColor = true, true
	object.BorderSizePixel, object.Selectable = 0, true
	object.Parent = parent
	local padding = Instance.new("UIPadding")
	padding.PaddingTop, padding.PaddingBottom = UDim.new(0, 10), UDim.new(0, 10)
	padding.PaddingLeft, padding.PaddingRight = UDim.new(0, 8), UDim.new(0, 8)
	padding.Parent = object
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0, 6), object
	return object
end

function View.new(gui: ScreenGui, changed: () -> (), actions: Actions?): Handle
	local connections: { RBXScriptConnection } = {}
	local function track(connection: RBXScriptConnection)
		table.insert(connections, connection)
	end
	local root = frame(gui, "Interface")
	root.BackgroundTransparency = 1
	local scale = Instance.new("UIScale")
	scale.Parent = root
	local summary = text(root, "Summary", "Joining…")
	summary.Font, summary.TextSize = Theme.StrongFont, 18
	local navigation = frame(root, "Navigation")
	navigation.BackgroundTransparency = 1
	local factory = button(navigation, "Factory", "Factory")
	local settings = button(navigation, "Settings", "Settings")
	local help = button(navigation, "Help", "? Help")
	local event = text(root, "Event", "Supply Cache\nWaiting for server state")
	event.TextXAlignment = Enum.TextXAlignment.Center
	local feedback = frame(root, "Feedback")
	feedback.BackgroundTransparency = 1
	feedback.AutomaticSize = Enum.AutomaticSize.Y
	list(feedback, 4)
	local purchase = text(feedback, "PurchaseResult", "")
	local supply = text(feedback, "SupplyResult", "")
	purchase.LayoutOrder, supply.LayoutOrder = 1, 2
	local panel = frame(root, "Panel")
	panel.Visible, panel.Active, panel.ClipsDescendants = false, true, true
	panel.SelectionGroup = true
	local title = text(panel, "Title", "")
	title.Font, title.TextSize = Theme.StrongFont, 20
	local close = button(panel, "Close", "Close")
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name, scroll.BackgroundTransparency, scroll.BorderSizePixel = "Content", 1, 0
	scroll.AutomaticCanvasSize, scroll.CanvasSize = Enum.AutomaticSize.Y, UDim2.new()
	scroll.ScrollingDirection, scroll.ScrollBarThickness = Enum.ScrollingDirection.Y, 6
	scroll.Active, scroll.Selectable = true, true
	scroll.Parent = panel
	list(scroll, Theme.Gap)
	local content = frame(scroll, "Pages")
	content.BackgroundTransparency, content.AutomaticSize = 1, Enum.AutomaticSize.Y
	content.Size = UDim2.new(1, -10, 0, 0)
	local pages: { [State.Panel]: Frame } = {}
	for _, name: State.Panel in { "Factory", "Settings", "Help" } do
		local page = frame(content, name)
		page.BackgroundTransparency, page.AutomaticSize = 1, Enum.AutomaticSize.Y
		page.Size, page.Visible = UDim2.fromScale(1, 0), false
		list(page, 12)
		pages[name] = page
	end
	local factorySummary = text(pages.Factory, "FactorySummary", "")
	factorySummary.LayoutOrder = 1
	local find = button(pages.Factory, "FindFactory", "Find my factory")
	find.LayoutOrder = 2
	local location = text(pages.Factory, "Location", "")
	location.LayoutOrder = 3
	local readiness = text(pages.Factory, "Readiness", "")
	readiness.LayoutOrder = 4
	text(
		pages.Factory,
		"PurchaseHelp",
		"Information only. Buy at nearby world pads; this panel does not pause production."
	).LayoutOrder =
		5
	local rows: { [Catalogue.Id]: TextLabel } = {}
	for index, definition in Catalogue.Definitions do
		local row = text(pages.Factory, definition.Id, "")
		row.LayoutOrder = index + 5
		rows[definition.Id] = row
	end
	text(pages.Settings, "Session", "Applies to this session. Changes take effect immediately; the game keeps running.").LayoutOrder =
		1
	local sizeButton = button(pages.Settings, "InterfaceSize", "")
	local motionButton = button(pages.Settings, "ReduceMotion", "")
	local labelsButton = button(pages.Settings, "FactoryLabels", "")
	local reset = button(pages.Settings, "Reset", "Reset interface settings")
	sizeButton.LayoutOrder, motionButton.LayoutOrder, labelsButton.LayoutOrder, reset.LayoutOrder = 2, 3, 4, 5
	text(
		pages.Settings,
		"Platform",
		"Roblox text size, transparency and reduced motion preferences are respected. Reset affects only these interface settings."
	).LayoutOrder =
		6
	local helpText = text(
		pages.Help,
		"Loop",
		"You receive an available factory when joining. If factories are full, no factory income is assigned.\n\nEarn cash automatically. Approach your factory's pads to buy an available upgrade. Read its price and prerequisite; owned upgrades increase income.\n\nWatch Supply Cache status. Approach its shared marker when OPEN and use its prompt. The first valid claim processed by the server wins.\n\nProgress resets when you leave. These panels do not pause the game."
	)
	helpText.LayoutOrder = 1
	local controls = text(pages.Help, "Controls", "")
	controls.LayoutOrder = 2
	local helpGuidance = text(pages.Help, "GuidanceHelp", "")
	helpGuidance.LayoutOrder = 3
	local restart = button(pages.Help, "RestartGuidance", "Show purchase guidance")
	restart.LayoutOrder = 4
	local optional = frame(root, "Guidance")
	optional.Visible, optional.Active, optional.ClipsDescendants = false, true, true
	local optionalScroll = Instance.new("ScrollingFrame")
	optionalScroll.Name, optionalScroll.BackgroundTransparency, optionalScroll.BorderSizePixel = "Text", 1, 0
	optionalScroll.AutomaticCanvasSize, optionalScroll.CanvasSize = Enum.AutomaticSize.Y, UDim2.new()
	optionalScroll.ScrollingDirection, optionalScroll.ScrollBarThickness = Enum.ScrollingDirection.Y, 4
	optionalScroll.Active, optionalScroll.Selectable, optionalScroll.Parent = true, true, optional
	local optionalText = text(optionalScroll, "Hint", "")
	optionalText.Size = UDim2.new(1, -8, 0, 0)
	local dismiss = button(optional, "DismissGuidance", "Dismiss hint")
	local optionalAllowed, optionalActive = false, false
	local current: State.Panel? = nil
	local returnFocus: GuiObject? = nil
	local promptEnabled: boolean? = nil
	local tween: Tween? = nil
	local panelScale = Instance.new("UIScale")
	panelScale.Parent = panel
	local alive = true
	local summaryValue, compactSummaryValue = "Joining…", "Joining…"
	local eventValue, compactEventValue = event.Text, event.Text
	local resizing = false
	local buttons: { TextButton } =
		{ factory, settings, help, close, find, restart, dismiss, sizeButton, motionButton, labelsButton, reset }
	factory.NextSelectionRight, factory.NextSelectionLeft = settings, help
	settings.NextSelectionRight, settings.NextSelectionLeft = help, factory
	help.NextSelectionRight, help.NextSelectionLeft = factory, settings
	find.NextSelectionUp, find.NextSelectionDown = close, scroll
	restart.NextSelectionUp, restart.NextSelectionDown = scroll, close
	optionalScroll.NextSelectionDown, dismiss.NextSelectionUp = dismiss, optionalScroll
	dismiss.NextSelectionDown = factory
	for index, object in { sizeButton, motionButton, labelsButton, reset } do
		local settingsControls = { sizeButton, motionButton, labelsButton, reset }
		object.NextSelectionUp = if index == 1 then close else settingsControls[index - 1]
		object.NextSelectionDown = if index == #settingsControls then close else settingsControls[index + 1]
	end
	local function updateControls()
		local input = UserInputService.PreferredInput
		local key, gamepad = Enum.KeyCode.E, Enum.KeyCode.ButtonX
		local runtime = workspace:FindFirstChild("TycoonRuntime")
		if runtime then
			for _, instance in runtime:GetDescendants() do
				if instance:IsA("ProximityPrompt") and instance.Name == "Purchase" then
					key, gamepad = instance.KeyboardKeyCode, instance.GamepadKeyCode
					break
				end
			end
		end
		controls.Text = if input == Enum.PreferredInput.Touch
			then "Touch: tap a nearby native world prompt. Tap interface buttons; scroll panels with a swipe."
			elseif
				input == Enum.PreferredInput.Gamepad
			then `Controller: use the world prompt's {gamepad.Name} hint. Select interface buttons and activate with A; B closes an open panel.`
			else `Keyboard / mouse: use a nearby prompt's {key.Name} hint or click it. Click interface buttons; scroll panels with the wheel.`
	end
	local function resize()
		if not alive or resizing then
			return
		end
		resizing = true
		local factor = Preferences.scale(Preferences.read())
		scale.Scale = factor
		local width, height = gui.AbsoluteSize.X / factor, gui.AbsoluteSize.Y / factor
		root.Size = UDim2.fromOffset(width, height)
		local usable = math.max(1, width - 24)
		local wide = width >= 940
		local compactWidth = if width >= 600 then 320 else usable
		-- Reserve native chat bounds (including its input bar), without disabling CoreGui.
		local startY = 12
		local startX, chatRight = 12, 0
		for _, config in { TextChatService.ChatWindowConfiguration, TextChatService.ChatInputBarConfiguration } do
			if config.Enabled and config.AbsoluteSize.Y > 0 then
				startY = math.max(
					startY,
					(config.AbsolutePosition.Y + config.AbsoluteSize.Y - gui.AbsolutePosition.Y) / factor + 12
				)
				chatRight = math.max(chatRight, (config.AbsolutePosition.X + config.AbsoluteSize.X) / factor)
			end
		end
		local chatBottom = startY
		local short = height < 420 and width >= 600
		-- The marker hint is repeated in Help; keep short views on the public status line.
		local nextEvent = if short then compactEventValue else eventValue
		if event.Text ~= nextEvent then
			event.Text = nextEvent
		end
		local nextSummary = if short then compactSummaryValue else summaryValue
		if summary.Text ~= nextSummary then
			summary.Text = nextSummary
		end
		if short then
			-- Collapsed chat can be very narrow; still reserve a readable message column.
			startX, startY = math.max(chatRight + 12, 304), 12
			compactWidth = math.min(compactWidth, width - startX - 12)
		end
		summary.Position, summary.Size =
			UDim2.fromOffset(startX, startY), UDim2.fromOffset(if wide then 260 else compactWidth, 0)
		local summaryHeight = summary.AbsoluteSize.Y / factor
		local target = math.max(
			Theme.Target,
			factory.AbsoluteSize.Y / factor,
			settings.AbsoluteSize.Y / factor,
			help.AbsoluteSize.Y / factor
		)
		local top = startY + summaryHeight + 8
		if wide then
			navigation.Position, navigation.Size = UDim2.fromOffset(12, top), UDim2.fromOffset(usable, target)
			factory.Position, factory.Size = UDim2.fromOffset(0, 0), UDim2.fromOffset(140, Theme.Target)
			-- Native list rows occupy screen pixels, independent of our interface scale.
			-- Keep the 48px header/clearance reservation, with 40px rows; a height cap overlapped six rows.
			local listBottom = (48 + #Players:GetPlayers() * 40) / factor
			settings.Position, settings.Size =
				UDim2.fromOffset(usable - 212, -top + listBottom), UDim2.fromOffset(108, Theme.Target)
			help.Position, help.Size =
				UDim2.fromOffset(usable - 96, -top + listBottom), UDim2.fromOffset(96, Theme.Target)
		else
			navigation.Position, navigation.Size = UDim2.fromOffset(startX, top), UDim2.fromOffset(compactWidth, target)
			local each = (compactWidth - 16) / 3
			for index, object in { factory, settings, help } do
				object.Position, object.Size =
					UDim2.fromOffset((index - 1) * (each + 8), 0), UDim2.fromOffset(each, Theme.Target)
			end
		end
		if short then
			-- Leave room for a usable panel above native touch controls in landscape.
			event.Position, event.Size =
				UDim2.fromOffset(12, chatBottom), UDim2.fromOffset(math.max(140, math.min(280, startX - 24)), 0)
		elseif wide then
			event.Position, event.Size = UDim2.fromOffset(292, 12), UDim2.fromOffset(usable - 520, 0)
		else
			event.Position, event.Size = UDim2.fromOffset(startX, top + target + 8), UDim2.fromOffset(compactWidth, 0)
		end
		local bottom = math.max(top + target, event.Position.Y.Offset + event.AbsoluteSize.Y / factor) + 8
		local feedbackWidth = if short then event.Size.X.Offset elseif wide then 350 else compactWidth
		feedback.Size = UDim2.fromOffset(feedbackWidth, 0)
		-- Feedback has its own bounded, noninteractive space, even with all panels closed.
		local panelTop = if short
			then top + target + 8
			else bottom + (if wide then 0 else feedback.AbsoluteSize.Y / factor) + 8
		local touchReserve = 0
		if UserInputService.TouchEnabled then
			touchReserve = 90 / factor
			local playerGui = gui.Parent
			local touchGui = if playerGui then playerGui:FindFirstChild("TouchGui") else nil
			local jump = if touchGui then touchGui:FindFirstChild("JumpButton", true) else nil
			if jump and jump:IsA("GuiObject") then
				touchReserve = math.max(
					touchReserve,
					(gui.AbsolutePosition.Y + gui.AbsoluteSize.Y - jump.AbsolutePosition.Y) / factor
				)
			end
		end
		panel.Position = UDim2.fromOffset(startX, panelTop)
		panel.Size = UDim2.fromOffset(
			if width >= 600 then math.min(360, width - startX - 12) else usable,
			math.max(80, math.min(height - panelTop - 12 - touchReserve, height * 0.65))
		)
		-- Reuse the closed panel's bounded space. Explicit navigation takes the
		-- optional hint's slot; authoritative event/result regions retain priority.
		optional.Position = panel.Position
		optional.Size = UDim2.fromOffset(panel.Size.X.Offset, math.min(144, panel.Size.Y.Offset))
		optional.Visible = current == nil and optionalAllowed and optionalText.Text ~= ""
		optionalScroll.Position, optionalScroll.Size = UDim2.fromOffset(10, 8), UDim2.new(1, -20, 1, -64)
		dismiss.Position, dismiss.Size = UDim2.new(0, 10, 1, -52), UDim2.new(1, -20, 0, Theme.Target)
		-- Private feedback moves to the opposite side while a wide panel is open.
		if current then
			feedback.Position = if short
				then UDim2.fromOffset(12, bottom)
				elseif wide then UDim2.fromOffset(width - 374, bottom)
				else UDim2.fromOffset(startX, bottom)
		else
			feedback.Position = UDim2.fromOffset(if short then 12 else startX, bottom)
		end
		title.Position, title.Size = UDim2.fromOffset(12, 12), UDim2.new(1, -124, 0, 0)
		close.Position, close.Size = UDim2.new(1, -104, 0, 4), UDim2.fromOffset(92, Theme.Target)
		local header = math.max(52, title.AbsoluteSize.Y / factor + 16, close.AbsoluteSize.Y / factor + 8)
		scroll.Position, scroll.Size = UDim2.fromOffset(12, header), UDim2.new(1, -24, 1, -header - 12)
		resizing = false
	end
	local function restoreInput()
		if promptEnabled ~= nil then
			ProximityPromptService.Enabled = promptEnabled
			promptEnabled = nil
		end
		local selected = GuiService.SelectedObject
		if selected and selected:IsDescendantOf(gui) then
			GuiService.SelectedObject = if returnFocus and returnFocus.Parent then returnFocus else nil
		end
		returnFocus = nil
	end
	local function setPanel(nextPanel: State.Panel?, opener: TextButton?)
		if tween then
			tween:Cancel()
			tween = nil
		end
		panelScale.Scale = 1
		if nextPanel and not current then
			returnFocus = opener or GuiService.SelectedObject
			promptEnabled = ProximityPromptService.Enabled
			-- Temporary client input gate: prevents native purchase/claim activation behind a panel.
			ProximityPromptService.Enabled = false
		elseif not nextPanel then
			restoreInput()
		end
		current = nextPanel
		panel.Visible = current ~= nil
		for name, page in pages do
			page.Visible = name == current
		end
		for _, object in { factory, settings, help } do
			object.TextColor3 = if object.Name == current then Theme.Accent else Theme.Text
		end
		if current then
			title.Text = current
			scroll.CanvasPosition = Vector2.zero
			updateControls()
			close.NextSelectionDown = if current == "Settings"
				then sizeButton
				elseif current == "Factory" then find
				else scroll
			close.NextSelectionUp = if current == "Settings" then reset elseif current == "Help" then restart else scroll
			scroll.NextSelectionUp = if current == "Factory" then find else close
			scroll.NextSelectionDown = if current == "Help" then restart else close
			if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
				GuiService.SelectedObject = close
			end
			if not Preferences.motionReduced(Preferences.read(), GuiService.ReducedMotionEnabled) then
				panelScale.Scale = 0.98
				local animation = TweenService:Create(panelScale, TweenInfo.new(0.12), { Scale = 1 })
				tween = animation
				animation:Play()
			end
		end
		if actions then
			actions.panel(current ~= nil)
		end
		resize()
	end
	for _, object in { factory, settings, help } do
		track(object.Activated:Connect(function()
			setPanel(State.toggle(current, object.Name :: State.Panel), object)
		end))
	end
	track(close.Activated:Connect(function()
		setPanel(nil, nil)
	end))
	track(find.Activated:Connect(function()
		setPanel(nil, nil)
		if actions then
			if optionalActive then
				actions.stop()
			else
				actions.find()
			end
		end
	end))
	track(restart.Activated:Connect(function()
		setPanel(nil, nil)
		if actions then
			actions.restart()
		end
	end))
	track(dismiss.Activated:Connect(function()
		if actions then
			if optionalActive then
				actions.stop()
			else
				actions.dismiss()
			end
		end
	end))
	for object, key in { [sizeButton] = "large", [motionButton] = "reduceMotion", [labelsButton] = "labels" } do
		track(object.Activated:Connect(function()
			local typed = key :: "large" | "reduceMotion" | "labels"
			Preferences.set(typed, not Preferences.value(Preferences.read(), typed))
			changed()
		end))
	end
	track(reset.Activated:Connect(function()
		Preferences.reset()
		changed()
	end))
	track(UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed or UserInputService:GetFocusedTextBox() or GuiService.MenuIsOpen then
			return
		end
		if current and input.KeyCode == Enum.KeyCode.ButtonB then
			setPanel(nil, nil)
		end
	end))
	track(UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
		updateControls()
		if current and UserInputService.PreferredInput == Enum.PreferredInput.Gamepad and not GuiService.MenuIsOpen then
			GuiService.SelectedObject = close
		end
	end))
	track(gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize))
	track(Players.PlayerAdded:Connect(resize))
	track(Players.PlayerRemoving:Connect(resize))
	for _, config in { TextChatService.ChatWindowConfiguration, TextChatService.ChatInputBarConfiguration } do
		for _, property in { "AbsolutePosition", "AbsoluteSize", "Enabled" } do
			track(config:GetPropertyChangedSignal(property):Connect(resize))
		end
	end
	for _, object in { summary, event, title, close, factory, settings, help, feedback } do
		track(object:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize))
	end
	-- Native selection highlight plus explicit focus/hover states; labels are always visible.
	for _, object in buttons do
		track(object.SelectionGained:Connect(function()
			object.BackgroundColor3 = Theme.Accent
			object.TextColor3 = Theme.Background
		end))
		track(object.SelectionLost:Connect(function()
			object.BackgroundColor3 = Theme.Surface
			object.TextColor3 = Theme.Text
		end))
	end
	local function refresh()
		local values = Preferences.read()
		sizeButton.Text = "Interface size: " .. (if values.large then "Large" else "Standard")
		motionButton.Text = "Reduce UI motion: "
			.. (
				if GuiService.ReducedMotionEnabled
					then "On (Roblox preference)"
					elseif values.reduceMotion then "On"
					else "Off"
			)
		labelsButton.Text = "Factory labels: " .. (if values.labels then "On" else "Off")
		if tween and Preferences.motionReduced(values, GuiService.ReducedMotionEnabled) then
			tween:Cancel()
			tween = nil
			panelScale.Scale = 1
		end
		panel.BackgroundTransparency = Theme.Transparency * GuiService.PreferredTransparency
		optional.BackgroundTransparency = panel.BackgroundTransparency
		for _, label in { summary, event, purchase, supply } do
			label.BackgroundColor3 = Theme.Background
			label.BackgroundTransparency = Theme.Transparency * GuiService.PreferredTransparency
		end
		resize()
	end
	refresh()
	return {
		economy = function(economy: State.Economy)
			summaryValue, compactSummaryValue = State.summary(economy), State.compactSummary(economy)
			resize()
			factorySummary.Text = State.summary(economy)
				.. (
					if economy.assigned
						then `\n{economy.count}/{#Catalogue.Definitions} owned` .. (if economy.count
								== #Catalogue.Definitions
							then " — income continues"
							else "")
						else ""
				)
			for _, definition in Catalogue.Definitions do
				rows[definition.Id].Text = State.entry(definition, economy)
				rows[definition.Id].TextColor3 = if economy.purchases[definition.Id] then Theme.Owned else Theme.Text
			end
		end,
		event = function(value: string, phase: string?)
			eventValue = value
			compactEventValue = if phase then string.match(value, "^[^\n]+") or value else value
			resize()
			event.TextColor3 = if phase == "warning"
				then Theme.Warning
				elseif phase == "open" then Theme.Accent
				else Theme.Muted
		end,
		feedback = function(purchaseText: string, supplyText: string)
			purchase.Text, supply.Text = purchaseText, supplyText
			purchase.Visible, supply.Visible = purchaseText ~= "", supplyText ~= ""
		end,
		guidance = function(value: string, active: boolean, allowed: boolean)
			optionalText.Text, optionalActive, optionalAllowed = value, active, allowed
			dismiss.Text = if active then "Stop guidance" else "Dismiss hint"
			resize()
		end,
		context = function(value: string, active: boolean, hint: string, pending: string)
			find.Text = if active then "Stop factory guidance" else "Find my factory"
			location.Text, location.Visible = value, value ~= ""
			helpGuidance.Text = hint
			readiness.Text, readiness.Visible = pending, pending ~= ""
		end,
		refresh = refresh,
		destroy = function()
			alive = false
			if tween then
				tween:Cancel()
			end
			if returnFocus and returnFocus:IsDescendantOf(gui) then
				returnFocus = nil
			end
			restoreInput()
			for _, connection in connections do
				connection:Disconnect()
			end
		end,
	}
end

return View
