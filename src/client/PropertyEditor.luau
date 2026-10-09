--!strict
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local Prompts = game:GetService("ProximityPromptService")
local Shared = Replicated.TycoonShared
local Catalogue = require(Shared.Infinite.Catalogue)
local Placement = require(Shared.Infinite.Placement)
local Models = require(Shared.Infinite.Models)
local Editor = {}
function Editor.new(hud: ScreenGui): { open: () -> (), destroy: () -> () }
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.ResetOnSpawn, gui.Enabled, gui.DisplayOrder = "PropertyEditor", false, false, 8
	gui.ScreenInsets, gui.ClipToDeviceSafeArea = Enum.ScreenInsets.CoreUISafeInsets, true
	gui.Parent = hud.Parent
	local panel = Instance.new("Frame")
	panel.Name, panel.AnchorPoint, panel.Position = "Editor", Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
	panel.Size, panel.BackgroundColor3, panel.Parent = UDim2.fromScale(0.96, 0.96), Color3.fromRGB(27, 38, 37), gui
	local constraint = Instance.new("UISizeConstraint")
	constraint.MaxSize, constraint.Parent = Vector2.new(760, 850), panel
	local function text(parent: Instance, value: string, height: number): TextLabel
		local label = Instance.new("TextLabel")
		label.Text, label.Size, label.BackgroundTransparency = value, UDim2.new(1, -12, 0, height), 1
		label.Font, label.TextSize, label.TextColor3 = Enum.Font.Gotham, 16, Color3.fromRGB(239, 231, 208)
		label.TextWrapped, label.Parent = true, parent
		return label
	end
	local function button(parent: Instance, value: string, action: () -> ()): TextButton
		local b = Instance.new("TextButton")
		b.Text, b.Size = value, UDim2.new(1, -12, 0, 52)
		b.Font, b.TextSize, b.TextWrapped = Enum.Font.GothamMedium, 16, true
		b.BackgroundColor3, b.TextColor3, b.Parent = Color3.fromRGB(62, 82, 69), Color3.fromRGB(250, 239, 211), parent
		b.Activated:Connect(function()
			action()
		end)
		return b
	end
	local title = text(panel, "MY PLACE  •  make room for curiosity", 36)
	title.Position = UDim2.fromOffset(6, 0)
	local status = text(panel, "", 54)
	status.Position = UDim2.fromOffset(6, 36)
	local nav = Instance.new("Frame")
	nav.Size, nav.Position, nav.BackgroundTransparency, nav.Parent =
		UDim2.new(1, -12, 0, 48), UDim2.fromOffset(6, 94), 1, panel
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name, scroll.Size, scroll.Position = "Content", UDim2.new(1, -12, 1, -152), UDim2.fromOffset(6, 148)
	scroll.BackgroundTransparency, scroll.BorderSizePixel = 1, 0
	scroll.AutomaticCanvasSize, scroll.CanvasSize, scroll.ScrollBarThickness = Enum.AutomaticSize.Y, UDim2.new(), 6
	scroll.Parent = panel
	local snapshot: any = nil
	local page, selected, candidate = "Discover", nil :: string?, nil :: Placement.Object?
	local busy, generation, sequence, oldPrompts = false, 0, 0, true
	local ghost: Part? = nil
	local message = "Loading your belongings…"
	local function updateStatus()
		status.Text = message
			.. "\n"
			.. tostring(player:GetAttribute("TycoonCash") or 0)
			.. " cash • "
			.. tostring(player:GetAttribute("TycoonSaveStatus") or "")
	end
	local render: () -> ()
	local function clearGhost()
		if ghost then
			ghost:Destroy()
			ghost = nil
		end
	end
	local function close()
		gui.Enabled, hud.Enabled = false, true
		Prompts.Enabled = oldPrompts
		generation += 1
		busy, candidate, selected = false, nil, nil
		clearGhost()
	end
	local function request(payload: any)
		if busy then
			return
		end
		local remote = Replicated:FindFirstChild("TycoonProperty")
		if not remote or not remote:IsA("RemoteFunction") then
			message = "Property service unavailable. Close and reopen to retry."
			render()
			return
		end
		if payload ~= "read" then
			if not snapshot or not snapshot.available then
				return
			end
			sequence += 1
			payload.epoch, payload.sequence, payload.plot, payload.revision =
				snapshot.epoch, sequence, snapshot.plot, snapshot.data.revision
		end
		busy = true
		generation += 1
		local version = generation
		message = "Waiting for the server…"
		render()
		task.delay(12, function()
			if busy and generation == version then
				generation += 1
				busy = false
				snapshot = nil
				message = "Response unconfirmed. Refresh to check your belongings before buying again."
				render()
			end
		end)
		task.spawn(function()
			local ok, result = pcall(function()
				return remote:InvokeServer(payload)
			end)
			if generation ~= version or not gui.Enabled then
				return
			end
			busy = false
			if not ok then
				snapshot = nil
				message = "Connection failed. Refresh to check the last accepted change."
			elseif result.available then
				snapshot = result
				sequence = result.sequence
				message = if result.message ~= "" then result.message else "Choose, arrange, and make it yours."
				if result.accepted then
					selected, candidate = nil, nil
					clearGhost()
				end
			else
				snapshot = nil
				message = result.message or "Your place is unavailable"
			end
			render()
		end)
	end
	local function list()
		local layout = Instance.new("UIListLayout")
		layout.Padding, layout.SortOrder, layout.Parent = UDim.new(0, 8), Enum.SortOrder.LayoutOrder, scroll
	end
	local function preview(content: string, theme: string)
		local viewport = Instance.new("ViewportFrame")
		viewport.Name, viewport.Size, viewport.BackgroundColor3 =
			"ObjectPreview", UDim2.new(1, -12, 0, 160), Color3.fromRGB(42, 54, 51)
		local camera = Instance.new("Camera")
		camera.CFrame = CFrame.lookAt(Vector3.new(13, 12, 16), Vector3.new(0, 3, 0))
		camera.Parent, viewport.CurrentCamera = viewport, camera
		local model = Models.create(content, theme, CFrame.new())
		model.Parent, viewport.Parent = viewport, scroll
		local center, size = model:GetBoundingBox()
		local extent = math.max(size.X, size.Y, size.Z)
		camera.FieldOfView = 45
		camera.CFrame = CFrame.lookAt(center.Position + Vector3.new(1, 0.8, 1.3).Unit * extent * 1.8, center.Position)
	end
	local function drawMap(data: any)
		local object = candidate
		if not object or not selected then
			return
		end
		local expanded = false
		for _, item in data.objects do
			if item.content == "rear_garden" then
				expanded = true
			end
		end
		local valid, issue = Placement.valid(data.objects, selected :: string, object, expanded)
		text(scroll, issue .. " • local preview only", 44)
		local map = Instance.new("TextButton")
		map.Name, map.Text, map.Size = "PlotMap", "", UDim2.fromOffset(280, 280)
		map.BackgroundColor3, map.Parent = Color3.fromRGB(75, 88, 65), scroll
		local function rect(x: number, z: number, width: number, depth: number, tint: Color3)
			local frame = Instance.new("Frame")
			frame.Position, frame.Size =
				UDim2.fromScale((x + 25 - width / 2) / 50, (z + 31 - depth / 2) / 62),
				UDim2.fromScale(width / 50, depth / 62)
			frame.BackgroundColor3, frame.BorderSizePixel, frame.Parent = tint, 1, map
		end
		rect(0, 0, 10, 62, Color3.fromRGB(168, 161, 136))
		rect(-19, -25, 8, 8, Color3.fromRGB(63, 67, 65))
		if not expanded then
			rect(0, 22, 50, 20, Color3.fromRGB(47, 57, 47))
		end
		for id, item in data.objects do
			if not item.stored and id ~= selected then
				local width, depth = Placement.size(item)
				rect(item.x, item.z, width, depth, Color3.fromRGB(196, 151, 111))
			end
		end
		local width, depth = Placement.size(object)
		local tint = if valid then Color3.fromRGB(123, 225, 171) else Color3.fromRGB(238, 112, 89)
		rect(object.x, object.z, width, depth, tint)
		map.InputBegan:Connect(function(input: InputObject)
			if
				busy
				or (
					input.UserInputType ~= Enum.UserInputType.MouseButton1
					and input.UserInputType ~= Enum.UserInputType.Touch
				)
			then
				return
			end
			local point = Vector2.new(input.Position.X, input.Position.Y) - map.AbsolutePosition
			object.x, object.z =
				math.clamp(math.round(point.X / map.AbsoluteSize.X * 50 - 25), -25, 25),
				math.clamp(math.round(point.Y / map.AbsoluteSize.Y * 62 - 31), -19, 28)
			render()
		end)
		text(scroll, "Entrance at top • dark starter unit is fixed • tap map to position", 44)
		local world = workspace:FindFirstChild("TycoonRuntime")
		local plot = if world then world:FindFirstChild("Plot" .. tostring(snapshot.plot)) else nil
		local frame = if plot then plot:GetAttribute("PropertyFrame") else nil
		clearGhost()
		if typeof(frame) == "CFrame" then
			local p = Instance.new("Part")
			p.Name, p.Size, p.CFrame =
				"LocalPlacementPreview", Vector3.new(width, 0.4, depth), frame * CFrame.new(object.x, 0.5, object.z)
			p.Color, p.Transparency, p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery =
				tint, 0.4, true, false, false, false
			p.Parent, ghost = workspace, p
		end
		local controls = Instance.new("Frame")
		controls.Size, controls.BackgroundTransparency, controls.Parent = UDim2.new(1, -12, 0, 48), 1, scroll
		for index, direction in { { "←", -2, 0 }, { "↑", 0, -2 }, { "↓", 0, 2 }, { "→", 2, 0 } } do
			local b = button(controls, direction[1] :: string, function()
				if busy then
					return
				end
				object.x = math.clamp(object.x + (direction[2] :: number), -25, 25)
				object.z = math.clamp(object.z + (direction[3] :: number), -19, 28)
				render()
			end)
			b.Size, b.Position = UDim2.new(0.25, -4, 0, 48), UDim2.fromScale((index - 1) / 4, 0)
		end
		button(scroll, "Rotate 90°", function()
			if not busy then
				object.rotation = (object.rotation + 1) % 4
				render()
			end
		end)
		button(scroll, "Confirm arrangement", function()
			request({ action = "place", object = selected, x = object.x, z = object.z, rotation = object.rotation })
		end)
		button(scroll, "Cancel preview • keep previous arrangement", function()
			if not busy then
				selected, candidate = nil, nil
				clearGhost()
				render()
			end
		end)
		button(scroll, "Store this object • keep its income", function()
			request({ action = "store", object = selected })
		end)
	end
	render = function()
		scroll:ClearAllChildren()
		list()
		status.Text = message
			.. (
				if busy
					then ""
					else "\n" .. tostring(player:GetAttribute("TycoonCash") or 0) .. " cash • " .. tostring(
						player:GetAttribute("TycoonSaveStatus") or ""
					)
			)
		if not snapshot or not snapshot.available then
			button(scroll, "Refresh my place", function()
				request("read")
			end)
			return
		end
		local data = snapshot.data
		if page == "Arrange" then
			if selected and candidate then
				drawMap(data)
			else
				text(
					scroll,
					"Select a belonging to place, move, rotate or store. Starter unit and visitor path are fixed.",
					56
				)
				local ids = {}
				for id in data.objects do
					table.insert(ids, id)
				end
				table.sort(ids)
				for _, id in ids do
					local object = data.objects[id]
					if Catalogue.ById[object.content].fixed then
						text(scroll, Catalogue.ById[object.content].name .. " • fixed, already open", 52)
						continue
					end
					button(
						scroll,
						Catalogue.ById[object.content].name
							.. (if object.stored then " • stored — place" else " • placed — edit"),
						function()
							selected, candidate = id, table.clone(object);
							(candidate :: Placement.Object).stored = false
							render()
							scroll.CanvasPosition = Vector2.zero
						end
					)
				end
				if #ids == 0 then
					text(scroll, "Discover a first belonging to begin.", 48)
				end
			end
		elseif page == "Palette" then
			text(scroll, "Palette: " .. data.theme .. " • free, reversible, saved with your place", 48)
			for _, theme in Catalogue.Themes do
				button(scroll, theme, function()
					request({ action = "theme", theme = theme })
				end)
			end
		else
			text(
				scroll,
				"Choose any direction; combine them later. Income continues in storage. 64 belongings, including up to 48 decorations.",
				56
			)
			local ownedIds = {}
			for _, object in data.objects do
				ownedIds[object.content] = true
			end
			local choices = table.clone(Catalogue.Definitions)
			local function rank(item: Catalogue.Definition): number
				return if item.unique and ownedIds[item.id]
					then 3
					elseif item.requires and not ownedIds[item.requires] then 2
					elseif item.income > 0 or item.fixed then 0
					else 1
			end
			table.sort(choices, function(a: Catalogue.Definition, b: Catalogue.Definition)
				if rank(a) == rank(b) then
					return a.cost < b.cost
				end
				return rank(a) < rank(b)
			end)
			for _, item in choices do
				if item.retired then
					continue
				end
				local owned = false
				for _, object in data.objects do
					if object.content == item.id then
						owned = true
					end
				end
				button(
					scroll,
					item.name
						.. " • "
						.. item.cost
						.. " cash • "
						.. item.description
						.. (if item.requires then "\nRequires " .. Catalogue.ById[item.requires].name else "")
						.. (if owned and item.unique then " • OWNED" else ""),
					function()
						if busy then
							return
						end
						scroll:ClearAllChildren()
						list()
						preview(item.id, data.theme)
						text(
							scroll,
							item.name
								.. "\n"
								.. item.description
								.. " • "
								.. item.width
								.. "×"
								.. item.depth
								.. " studs",
							64
						)
						button(scroll, "Buy for " .. item.cost .. " cash", function()
							request({ action = "buy", content = item.id })
						end)
						button(scroll, "Back to discoveries", render)
					end
				)
			end
		end
	end
	for index, name in { "Discover", "Arrange", "Palette", "Close" } do
		local b = button(nav, name, function()
			if name == "Close" then
				close()
				return
			end
			if busy then
				return
			end
			page, selected, candidate = name, nil, nil
			clearGhost()
			render()
			scroll.CanvasPosition = Vector2.zero
		end)
		b.Size, b.Position = UDim2.new(0.25, -4, 0, 48), UDim2.fromScale((index - 1) / 4, 0)
	end
	local assignment = player:GetAttributeChangedSignal("TycoonAssignment"):Connect(function()
		if gui.Enabled and player:GetAttribute("TycoonAssignment") ~= "Ready" then
			close()
		end
	end)
	local cashChange = player:GetAttributeChangedSignal("TycoonCash"):Connect(updateStatus)
	local saveChange = player:GetAttributeChangedSignal("TycoonSaveStatus"):Connect(updateStatus)
	return {
		open = function()
			if gui.Enabled then
				return
			end
			oldPrompts = Prompts.Enabled
			Prompts.Enabled = false
			gui.Enabled, hud.Enabled = true, false
			page, snapshot = "Discover", nil
			request("read")
		end,
		destroy = function()
			close()
			assignment:Disconnect()
			cashChange:Disconnect()
			saveChange:Disconnect()
			gui:Destroy()
		end,
	}
end
return Editor
