--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Controller = require(script.Parent.Controller)
local Configuration = require(script.Parent.Configuration)
local Adapter = require(script.Parent.TeleportAdapter)
local Runtime = {}
export type Lifecycle = {
	prepare: (number, (boolean, string) -> ()) -> (),
	recover: (number, (boolean, string) -> ()) -> (),
}
export type Preview = { send: (Player, number, string, (string) -> ()) -> (boolean, string), label: string }
function Runtime.start(configuration: Configuration.Resolved, lifecycle: Lifecycle?, preview: Preview?)
	assert(not preview or RunService:IsStudio(), "Routing preview is Studio-only")
	assert(not ReplicatedStorage:FindFirstChild("TycoonRoutes"), "Routing started twice")
	local remote = Instance.new("RemoteEvent")
	remote.Name = "TycoonRoutes"
	remote:SetAttribute("Role", configuration.role)
	remote:SetAttribute("Enabled", configuration.enabled)
	remote:SetAttribute("Issue", configuration.issue or "")
	remote:SetAttribute("Preview", if preview then preview.label else "")
	remote.Parent = ReplicatedStorage
	local active: { [number]: Player } = {}
	local nextRequest: { [number]: number } = {}
	local function ready(_id: number, done: (boolean, string) -> ())
		done(true, "Ready")
	end
	local router: Controller.Controller
	router = Controller.new(configuration.role, configuration.places, {
		now = os.clock,
		token = function()
			return HttpService:GenerateGUID(false)
		end,
		spawn = function(work)
			task.spawn(work)
		end,
		prepare = if lifecycle then lifecycle.prepare else ready,
		recover = if lifecycle then lifecycle.recover else ready,
		changed = function(id, view)
			local player = active[id]
			if player then
				remote:FireClient(player, view)
			end
		end,
		teleport = function(id, target, token)
			local player = active[id]
			if not player or player.Parent ~= Players then
				return false, "Player left"
			end
			if preview then
				return preview.send(player, target, token, function(message)
					if active[id] == player then
						router:failed(id, token, target, message)
					end
				end)
			end
			if RunService:IsStudio() then
				return false, "Real teleports require published test destinations and the Roblox client."
			end
			return Adapter.send(player, target, token)
		end,
	})
	Adapter.listen(function(player, token, placeId, message)
		if active[player.UserId] == player then
			router:failed(player.UserId, token, placeId, message)
		end
	end)
	local function join(player: Player)
		if active[player.UserId] == player then
			return
		end
		active[player.UserId] = player
		router:join(player.UserId)
	end
	Players.PlayerAdded:Connect(join)
	Players.PlayerRemoving:Connect(function(player)
		if active[player.UserId] ~= player then
			return
		end
		active[player.UserId], nextRequest[player.UserId] = nil, nil
		router:leave(player.UserId)
	end)
	for _, player in Players:GetPlayers() do
		join(player)
	end
	remote.OnServerEvent:Connect(function(player: Player, choice: any, revision: any)
		if active[player.UserId] ~= player or player.Parent ~= Players then
			return
		end
		local now = os.clock()
		if now < (nextRequest[player.UserId] or 0) then
			return
		end
		nextRequest[player.UserId] = now + 0.25
		if choice == "read" then
			remote:FireClient(player, router:read(player.UserId))
		elseif typeof(choice) == "string" and typeof(revision) == "number" then
			if choice == "reload" and configuration.role == "Infinite" then
				router:retry(player.UserId, revision)
			else
				router:choose(player.UserId, choice, revision)
			end
			remote:FireClient(player, router:read(player.UserId))
		end
	end)
	RunService.Heartbeat:Connect(function()
		router:step()
	end)
end
return Runtime
