--!strict

local Config = require(game:GetService("ReplicatedStorage").TycoonShared.Config)
local Theme = require(script.Parent.UiTheme)
local Guidance = {}
Guidance.ArrivalDistance = 8
export type Handle = {
	assignment: (number?, boolean) -> (),
	start: () -> (),
	stop: () -> (),
	tick: (number) -> (),
	pause: (boolean) -> (),
	destroy: () -> (),
}

-- Resolve only the assigned IDs. Runtime ownership, not ambient label text,
-- cross-checks the saved lot. No server-only module or ring coordinates here.
function Guidance.resolve(root: Instance, plot: number, userId: number): (Part?, string)
	local runtime, map = root:FindFirstChild(Config.RuntimeName), root:FindFirstChild(Config.MapName)
	local owned = if runtime then runtime:FindFirstChild(`Plot{plot}`) else nil
	if not owned or not owned:IsA("Model") or owned:GetAttribute(Config.Attributes.PlotId) ~= plot then
		return nil, "Locating factory ownership…"
	end
	if owned:GetAttribute(Config.Attributes.OwnerUserId) ~= userId then
		return nil, "Waiting for your factory ownership…"
	end
	local lots = if map and map:IsA("Model") then map:FindFirstChild("Lots") else nil
	local lot = if lots then lots:FindFirstChild(`Lot{plot}`) else nil
	if not lot or not lot:IsA("Model") or lot:GetAttribute("LotId") ~= plot then
		return nil, "Locating factory entrance…"
	end
	local entrance = lot:FindFirstChild("Entrance")
	if not entrance then
		return nil, "Locating factory entrance…"
	end
	if not entrance:IsA("Part") or not entrance.Anchored then
		return nil, `Factory {plot} entrance unavailable`
	end
	return entrance, ""
end

function Guidance.cue(position: Vector3, camera: CFrame, target: Vector3, plot: number): (string, boolean)
	local delta = Vector3.new(target.X - position.X, 0, target.Z - position.Z)
	local distance = delta.Magnitude
	if distance <= Guidance.ArrivalDistance and math.abs(target.Y - position.Y) <= 10 then
		return `Factory {plot} entrance reached`, true
	end
	local right, forward = camera.RightVector, camera.LookVector
	local angle = math.deg(math.atan2(delta:Dot(right), delta:Dot(forward)))
	local direction = if math.abs(angle) <= 30
		then "Ahead"
		elseif math.abs(angle) >= 150 then "Behind you"
		elseif angle > 0 then "To your right"
		else "To your left"
	return `Factory {plot} • {direction} • {math.ceil(distance)} studs`, false
end

function Guidance.new(player: Player, gui: ScreenGui, changed: (string, boolean) -> (), world: Instance?): Handle
	local plot: number? = nil
	local full, active, paused, alive = false, false, false, true
	local elapsed, started = 0, 0
	local retained: Part? = nil
	local reported = false
	local marker: BillboardGui? = nil
	local function createMarker(entrance: Part, id: number): BillboardGui
		local object = Instance.new("BillboardGui")
		object.Name, object.Size, object.StudsOffset =
			"FactoryEntranceGuide", UDim2.fromOffset(170, 32), Vector3.new(0, 4, 0)
		object.AlwaysOnTop, object.MaxDistance, object.Adornee = false, 200, entrance
		object.Parent = gui
		local label = Instance.new("TextLabel")
		label.Size, label.BackgroundColor3 = UDim2.fromScale(1, 1), Theme.Background
		label.TextColor3, label.Font, label.TextSize = Theme.Accent, Theme.StrongFont, Theme.TextSize
		label.TextWrapped, label.Text, label.Parent = true, `Your factory {id} entrance`, object
		label.BackgroundTransparency = Theme.Transparency * game:GetService("GuiService").PreferredTransparency
		return object
	end
	local function stop()
		active = false
		retained = nil
		if marker then
			marker:Destroy()
			marker = nil
		end
		changed("", false)
	end
	return {
		assignment = function(nextPlot: number?, nextFull: boolean)
			if nextPlot ~= plot then
				stop()
			end
			plot, full = nextPlot, nextFull
		end,
		start = function()
			if not alive then
				return
			end
			if not plot then
				changed(
					if full
						then "Factories are full; no target or waiting queue this session."
						else "Waiting for a factory assignment.",
					false
				)
				return
			end
			active, started, elapsed, reported = true, os.clock(), 0.25, false
			changed("Locating factory entrance…", true)
		end,
		stop = stop,
		pause = function(value: boolean)
			paused = value
			if marker then
				marker.Enabled = not paused and active
			end
		end,
		tick = function(delta: number)
			elapsed += delta
			if not alive or not active or not plot or elapsed < 0.25 then
				return
			end
			elapsed = 0
			local targetPlot = plot
			if not targetPlot then
				return
			end
			-- Fixed-name lookups at 4 Hz; never scan the Workspace per frame.
			local entrance, reason = Guidance.resolve(world or workspace, targetPlot, player.UserId)
			if retained and retained ~= entrance then
				stop()
				return
			end
			retained = entrance
			if not entrance then
				if os.clock() - started >= 10 and not reported then
					reported = true
					warn(`Tycoon HUD: factory {plot} entrance unavailable: {reason}`)
				end
				changed(
					if os.clock() - started >= 10
						then `Factory {plot} location unavailable; try again later.`
						else reason,
					true
				)
				return
			end
			local currentMarker = marker
			if not currentMarker then
				currentMarker = createMarker(entrance, targetPlot)
				marker = currentMarker
			end
			assert(currentMarker, "Factory guidance marker creation failed")
			currentMarker.Enabled = not paused
			local character, camera = player.Character, workspace.CurrentCamera
			local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
			if not root or not root:IsA("BasePart") or not camera then
				changed("Factory guidance resumes when your character is ready.", true)
				return
			end
			local value, arrived = Guidance.cue(root.Position, camera.CFrame, entrance.Position, targetPlot)
			if arrived then
				stop()
			else
				changed(value, true)
			end
		end,
		destroy = function()
			alive = false
			stop()
		end,
	}
end

return Guidance
