--!strict

local GuiService = game:GetService("GuiService")
local Rules = require(game:GetService("ReplicatedStorage").TycoonShared.Experiments.AimClash.Rules)
local View = {}
local calm, hot = Color3.fromRGB(86, 218, 217), Color3.fromRGB(255, 127, 64)
export type Handle = {
	gui: ScreenGui,
	board: Frame,
	target: TextLabel,
	hints: { Frame },
	trail: Frame,
	status: TextLabel,
	feedback: TextLabel,
	result: Frame,
	ownResult: TextLabel,
	otherResult: TextLabel,
	resultTitle: TextLabel,
	scoreRule: TextLabel,
	practice: TextButton,
	queue: TextButton,
	leave: TextButton,
	motion: TextButton,
	border: UIStroke,
	targetBorder: UIStroke,
}

local function rounded(object: GuiObject, radius: number)
	Instance.new("UICorner", object).CornerRadius = UDim.new(radius, 0)
end

function View.new(): Handle
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.ResetOnSpawn, gui.DisplayOrder = "AimClash", false, 30
	-- InputObject.Position and GuiObject.AbsolutePosition share the engine's UI
	-- origin; no manual pointer inset subtraction. Layout measures safe bounds so notches
	-- and Roblox controls cannot overlap the experiment's interactive controls.
	gui.IgnoreGuiInset, gui.ScreenInsets, gui.ClipToDeviceSafeArea = true, Enum.ScreenInsets.None, true
	local root = Instance.new("Frame")
	root.Name, root.Size, root.BackgroundColor3, root.BorderSizePixel, root.Parent =
		"Interface", UDim2.fromScale(1, 1), Color3.fromRGB(10, 16, 27), 0, gui
	local function text(parent: Instance, name: string, value: string): TextLabel
		local label = Instance.new("TextLabel")
		label.Name, label.Text, label.Font, label.TextSize = name, value, Enum.Font.GothamMedium, 18
		label.TextColor3, label.BackgroundTransparency, label.TextWrapped, label.Parent =
			Color3.fromRGB(237, 247, 253), 1, true, parent
		return label
	end
	local status = text(root, "Status", "AIM CLASH · direct click / tap")
	status.AnchorPoint, status.Position, status.Size =
		Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 100), UDim2.new(0.95, 0, 0, 30)
	local function button(name: string, value: string, slot: number): TextButton
		local object = Instance.new("TextButton")
		object.Name, object.Text, object.Font, object.TextSize = name, value, Enum.Font.GothamBold, 14
		object.TextColor3, object.BackgroundColor3, object.BorderSizePixel =
			Color3.fromRGB(237, 247, 253), Color3.fromRGB(30, 56, 76), 0
		object.Position, object.Size = UDim2.new(0.02 + slot * 0.24, 0, 0, 52), UDim2.new(0.22, 0, 0, 44)
		object.TextWrapped = true
		object.Parent = root
		rounded(object, 0.15)
		return object
	end
	local practice, queue, leave, motion =
		button("Practice", "Practice", 0),
		button("Queue", "Duel queue", 1),
		button("Leave", "Leave queue", 2),
		button("Motion", "Motion: standard", 3)
	local board = Instance.new("Frame")
	board.Name, board.AnchorPoint, board.BackgroundColor3, board.BorderSizePixel, board.Active =
		"Arena", Vector2.new(0.5, 0.5), Color3.fromRGB(18, 30, 45), 0, true
	board.Parent = root
	rounded(board, 1)
	local border = Instance.new("UIStroke")
	border.Thickness, border.Color, border.Transparency, border.Parent = 3, calm, 0.12, board
	local hints: { Frame } = {}
	for index = 1, 2 do
		local hint = Instance.new("Frame")
		hint.Name, hint.AnchorPoint, hint.Size = `Next{index}`, Vector2.new(0.5, 0.5), UDim2.fromScale(0.12, 0.12)
		hint.BackgroundTransparency, hint.BorderSizePixel, hint.ZIndex, hint.Parent = 1, 0, 2, board
		rounded(hint, 1)
		local outline = Instance.new("UIStroke")
		outline.Color, outline.Thickness, outline.Transparency, outline.Parent =
			calm, 1, 0.75 + (index - 1) * 0.12, hint
		table.insert(hints, hint)
	end
	local trail = Instance.new("Frame")
	trail.Name, trail.AnchorPoint, trail.BackgroundColor3, trail.BackgroundTransparency, trail.BorderSizePixel =
		"AnticipationTrail", Vector2.new(0.5, 0.5), calm, 0.86, 0
	trail.ZIndex, trail.Parent = 1, board
	local target = text(board, "Target", "1")
	target.Size, target.AnchorPoint, target.BackgroundTransparency, target.BackgroundColor3 =
		UDim2.fromScale(Rules.TargetRadius * 2, Rules.TargetRadius * 2), Vector2.new(0.5, 0.5), 0, calm
	target.TextColor3, target.Font, target.TextSize, target.ZIndex =
		Color3.fromRGB(9, 24, 34), Enum.Font.GothamBold, 26, 5
	rounded(target, 1)
	local targetBorder = Instance.new("UIStroke")
	targetBorder.Thickness, targetBorder.Color, targetBorder.Parent = 3, Color3.fromRGB(234, 255, 255), target
	local feedback = text(root, "Feedback", "Appearing circles only · anticipate the faint trail · no musical beat")
	feedback.AnchorPoint, feedback.Position, feedback.Size =
		Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, -8), UDim2.new(0.96, 0, 0, 40)
	local result = Instance.new("Frame")
	result.Name, result.AnchorPoint, result.BackgroundColor3, result.BorderSizePixel, result.ZIndex, result.Visible =
		"Result", Vector2.new(0.5, 0.5), Color3.fromRGB(19, 33, 47), 0, 10, false
	result.Parent = root
	rounded(result, 0.05)
	local title = text(result, "Winner", "")
	title.Position, title.Size, title.ZIndex, title.TextColor3 =
		UDim2.fromScale(0.03, 0.02), UDim2.fromScale(0.94, 0.12), 11, calm
	local own = text(result, "OwnBreakdown", "")
	own.Position, own.Size, own.ZIndex, own.TextYAlignment =
		UDim2.fromScale(0.03, 0.16), UDim2.fromScale(0.46, 0.65), 11, Enum.TextYAlignment.Top
	local other = text(result, "OtherBreakdown", "")
	other.Position, other.Size, other.ZIndex, other.TextYAlignment =
		UDim2.fromScale(0.51, 0.16), UDim2.fromScale(0.46, 0.65), 11, Enum.TextYAlignment.Top
	local rule = text(
		result,
		"PrecisionRule",
		"Precision = aim quality / (24 targets + inaccurate inputs). Misses contribute zero. Speed and combo do not change precision."
	)
	rule.Position, rule.Size, rule.ZIndex, rule.TextSize =
		UDim2.fromScale(0.03, 0.82), UDim2.fromScale(0.94, 0.16), 11, 13
	local handle: Handle = {
		gui = gui,
		board = board,
		target = target,
		hints = hints,
		trail = trail,
		status = status,
		feedback = feedback,
		result = result,
		ownResult = own,
		otherResult = other,
		resultTitle = title,
		scoreRule = rule,
		practice = practice,
		queue = queue,
		leave = leave,
		motion = motion,
		border = border,
		targetBorder = targetBorder,
	}
	View.target(handle, nil, nil, nil, false, 0)
	return handle
end

function View.layout(view: Handle)
	-- GetInsetArea rectangles share the core-safe origin. Subtract the whole-screen
	-- minimum to express child positions in the full-screen parent's local space.
	local whole = GuiService:GetInsetArea(Enum.ScreenInsets.None)
	local safe = GuiService:GetInsetArea(Enum.ScreenInsets.CoreUISafeInsets)
	local origin, safeSize = safe.Min - whole.Min, safe.Max - safe.Min
	local height = origin.Y + safeSize.Y
	local compact = height < 430
	local controlsTop = math.max(52, origin.Y + 8)
	local centerX = origin.X + safeSize.X / 2
	local diameter, y = Rules.boardSize(safeSize.X, height, controlsTop)
	local top = controlsTop + (if compact then 64 else 92)
	local bottom = if compact then 32 else 48
	view.board.Size, view.board.Position = UDim2.fromOffset(diameter, diameter), UDim2.fromOffset(centerX, y)
	view.result.Size, view.result.Position =
		UDim2.fromOffset(math.max(1, math.min(safeSize.X - 24, 640)), math.max(1, height - top - bottom)),
		UDim2.fromOffset(centerX, y)
	view.status.Position = UDim2.fromOffset(centerX, controlsTop + (if compact then 44 else 48))
	view.status.Size = UDim2.fromOffset(safeSize.X * 0.95, if compact then 20 else 30)
	view.status.TextSize, view.feedback.TextSize =
		if compact or safeSize.X < 450 then 14 else 18, if compact then 12 else 16
	view.feedback.Position = UDim2.fromOffset(centerX, height - 8)
	view.feedback.Size = UDim2.fromOffset(safeSize.X * 0.96, if compact then 24 else 40)
	view.ownResult.TextSize, view.otherResult.TextSize, view.scoreRule.TextSize =
		if compact then 12 else 16, if compact then 12 else 16, if compact then 10 else 13
	for slot, control in { view.practice, view.queue, view.leave, view.motion } do
		control.Position = UDim2.fromOffset(origin.X + (0.02 + (slot - 1) * 0.24) * safeSize.X, controlsTop)
		control.Size = UDim2.fromOffset(safeSize.X * 0.22, 44)
		control.TextSize = if safeSize.X < 450 then 11 else 14
	end
end

function View.controls(view: Handle, active: boolean)
	for _, control in { view.practice, view.queue, view.leave } do
		control.Interactable = not active
		control.BackgroundTransparency = if active then 0.75 else 0
	end
end

function View.target(
	view: Handle,
	target: Rules.Target?,
	index: number?,
	pattern: { Rules.Target }?,
	reduced: boolean,
	heat: number
)
	view.target.Visible = target ~= nil
	view.border.Color = calm:Lerp(hot, math.clamp(heat, 0, 1))
	-- Intensity lives on the perimeter; the target color/size never becomes harder
	-- to read. Reduced motion keeps that color but removes the gentle pulse.
	view.border.Thickness = if reduced then 3 else 3 + math.sin(os.clock() * 4) * heat
	for hintIndex, hint in view.hints do
		local nextTarget = if pattern and index then pattern[index + hintIndex] else nil
		hint.Visible = nextTarget ~= nil
		if nextTarget then
			hint.Position = UDim2.fromScale(nextTarget.x, nextTarget.y)
		end
	end
	view.trail.Visible = target ~= nil and pattern ~= nil and index ~= nil and index < #pattern
	if target and index then
		view.target.Position, view.target.Text = UDim2.fromScale(target.x, target.y), tostring(index)
		local nextTarget = pattern and pattern[index + 1]
		if nextTarget then
			local diameter = view.board.AbsoluteSize.X
			local offset = Vector2.new(nextTarget.x - target.x, nextTarget.y - target.y)
			view.trail.Position, view.trail.Size =
				UDim2.fromScale((target.x + nextTarget.x) / 2, (target.y + nextTarget.y) / 2),
				UDim2.fromOffset(offset.Magnitude * diameter, 2)
			view.trail.Rotation = math.deg(math.atan2(offset.Y, offset.X))
		end
	end
end

function View.point(view: Handle, position: Vector3): (number?, number?)
	local origin, size = view.board.AbsolutePosition, view.board.AbsoluteSize
	if size.X <= 0 then
		return nil, nil
	end
	local x, y = (position.X - origin.X) / size.X, (position.Y - origin.Y) / size.Y
	if x < 0 or x > 1 or y < 0 or y > 1 then
		return nil, nil
	end
	return x, y
end

function View.result(view: Handle, packet: any)
	local function breakdown(name: string, score: any): string
		return `{name}\n{score.total} points\nPrecision percentage {string.format("%.1f", score.precision)}%\nBase {score.base} · Speed Extra {score.speedExtra}\nCombo Extra points {score.comboExtra}\nMissed {score.misses} · Inaccurate {score.inaccurate}\nPenalty {score.penalty} · Best combo {score.bestCombo}`
			.. (if score.disqualified then "\nDISQUALIFIED" else "")
	end
	view.resultTitle.Text = if not packet.other
		then "Practice complete"
		else if packet.winner == 0
			then "DRAW"
			else if packet.winner == packet.actor then "YOU WIN" else `{packet.opponent} wins`
	view.ownResult.Text = breakdown("You", packet.own)
	view.otherResult.Text = if packet.other
		then breakdown(packet.opponent, packet.other)
		else "Replay to improve aim and anticipation.\n\nChoose Duel queue on two clients for the same pattern and start time."
	view.result.Visible = true
	view.target.Visible, view.trail.Visible = false, false
	for _, hint in view.hints do
		hint.Visible = false
	end
	View.controls(view, false)
end

return View
