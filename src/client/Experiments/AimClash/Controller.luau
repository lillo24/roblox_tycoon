--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local StarterGui = game:GetService("StarterGui")
local Rules = require(ReplicatedStorage.TycoonShared.Experiments.AimClash.Rules)
local Preferences = require(script.Parent.Parent.Parent.UiPreferences)
local View = require(script.Parent.View)
local Controller = {}

function Controller.start(): ScreenGui
	local player = Players.LocalPlayer
	assert(player, "Aim clash requires LocalPlayer")
	local remote = ReplicatedStorage:WaitForChild(Rules.RemoteName, 10)
	assert(remote and remote:IsA("RemoteEvent"), "Aim clash input channel unavailable after 10 seconds")
	local view = View.new()
	local gui = view.gui
	local connections: { RBXScriptConnection } = {}
	local round: any = nil
	local own: any = nil
	local pending: { [number]: number } = {}
	local reduced, focused = false, true
	local function track(connection: RBXScriptConnection)
		table.insert(connections, connection)
	end
	local function control(action: string)
		remote:FireServer(action)
	end
	track(view.practice.Activated:Connect(function()
		control("practice")
	end))
	track(view.queue.Activated:Connect(function()
		control("queue")
	end))
	track(view.leave.Activated:Connect(function()
		control("leave")
	end))
	track(view.motion.Activated:Connect(function()
		reduced = not reduced
	end))
	track(UserInputService.WindowFocusReleased:Connect(function()
		focused = false
	end))
	track(UserInputService.WindowFocused:Connect(function()
		focused = true
	end))
	track(remote.OnClientEvent:Connect(function(packet: any)
		assert(typeof(packet) == "table" and typeof(packet.kind) == "string", "Aim clash malformed server packet")
		if packet.kind == "start" then
			round, own = packet, nil
			round.pattern = Rules.pattern(packet.seed)
			table.clear(pending)
			view.result.Visible = false
			View.controls(view, true)
		elseif packet.kind == "own" and round and packet.id == round.id then
			own = packet.own
		elseif packet.kind == "result" and round and packet.id == round.id then
			round = nil
			View.result(view, packet)
			view.status.Text = "AIM CLASH · result"
			view.feedback.Text = "Replay practice or queue another duel · totals are final server judgements"
		elseif packet.kind == "queued" or packet.kind == "lobby" or packet.kind == "cancel" then
			round, own = nil, nil
			view.result.Visible = false
			View.target(view, nil, nil, nil, true, 0)
			View.controls(view, false)
			view.status.Text, view.feedback.Text = "AIM CLASH", packet.message
		end
	end))
	track(UserInputService.InputBegan:Connect(function(input: InputObject, _processed: boolean)
		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end
		local current = round
		if
			not current
			or not focused
			or GuiService.MenuIsOpen
			or UserInputService:GetFocusedTextBox()
			or not gui.Enabled
		then
			return
		end
		local now = workspace:GetServerTimeNow()
		if now < current.start or now > current.start + Rules.duration(current.pattern) then
			return
		end
		local x, y = View.point(view, input.Position)
		if not x or not y then
			return
		end
		remote:FireServer("input", current.id, now, x, y)
		local index = Rules.targetAt(current.pattern, now - current.start)
		if index and Rules.quality(current.pattern[index], x, y) then
			-- Immediate local hit feedback; the next private server projection confirms
			-- or corrects it. Prediction never contributes to the authoritative result.
			pending[index] = now + 0.25
			view.feedback.Text = "Contact · confirming"
		end
	end))
	track(gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		View.layout(view)
	end))
	track(GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(function()
		View.layout(view)
	end))
	local listEnabled = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
	track(RunService.RenderStepped:Connect(function()
		local quiet = reduced or Preferences.motionReduced(Preferences.read(), GuiService.ReducedMotionEnabled)
		view.motion.Text = if quiet then "Motion: reduced" else "Motion: standard"
		local current = round
		if not current then
			return
		end
		local now = workspace:GetServerTimeNow()
		local elapsed = now - current.start
		local index = Rules.targetAt(current.pattern, elapsed)
		local combo = if own then own.combo else 0
		local target = if index then current.pattern[index] else nil
		local predicted = index and pending[index]
		if index and ((own and own.judgements[index] == 1) or (predicted and now < predicted)) then
			target = nil
		end
		View.target(view, target, index, current.pattern, quiet, math.min(combo / 10, 1))
		local mode = if current.practice then "Practice" else "Duel · opponent score hidden"
		if elapsed < 0 then
			view.status.Text = `{mode} · begins in {math.ceil(-elapsed)}`
			view.feedback.Text = "Click / tap each circle directly · center aim earns higher precision"
		else
			local remaining = math.max(0, math.ceil(Rules.duration(current.pattern) - elapsed))
			local phase = Rules.phase(current.pattern, elapsed)
			view.status.Text = `{mode} · {phase} · {remaining}s · your combo {combo}`
			if own then
				view.feedback.Text = `{own.message} · your points {own.total}`
			end
		end
	end))
	track(gui.Destroying:Connect(function()
		for _, connection in connections do
			connection:Disconnect()
		end
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, listEnabled)
	end))
	gui.Parent = player:WaitForChild("PlayerGui")
	View.layout(view)
	print("EXP03 Aim Clash client ready; click/tap targets, no keyboard QTE or music clock.")
	return gui
end

return Controller
