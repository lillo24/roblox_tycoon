--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Rules = require(ReplicatedStorage.TycoonShared.Experiments.FactoryPurchases.Rules)
local Catalogue = require(ReplicatedStorage.TycoonShared.UpgradeCatalogue)
local PlotWorld = require(script.Parent.Parent.Parent.PlotWorld)
local Visits = require(script.Parent.Visits)
local WalkOn = {}

function WalkOn.presentation(plot: PlotWorld.Plot)
	for _, definition in Catalogue.Definitions do
		local pad = plot.pads[definition.Id]
		pad.prompt.Enabled = false
		pad.label.Text ..= "\nWalk on · exit to retry"
	end
end

function WalkOn.start(
	plots: { PlotWorld.Plot },
	eligible: (Player, Catalogue.Id) -> number?,
	purchase: (Player, number, Catalogue.Id, PlotWorld.Pad) -> ()
)
	assert(not ReplicatedStorage:FindFirstChild(Rules.RemoteName), "Factory walk-on channel already exists")
	local remote = Instance.new("RemoteEvent")
	remote.Name, remote.Parent = Rules.RemoteName, ReplicatedStorage
	local visits = Visits.new()
	local pads: { [string]: { plot: number, id: Catalogue.Id, pad: PlotWorld.Pad } } = {}
	for plotId, plot in plots do
		for id, pad in plot.pads do
			pads[`{plotId}/{id}`] = { plot = plotId, id = id, pad = pad }
		end
	end
	local function live(player: Player): (Model?, BasePart?)
		local character = player.Character
		local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if character and humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
			return character, root
		end
		return nil, nil
	end
	remote.OnServerEvent:Connect(function(player: Player, token: any)
		if player.Parent ~= Players then
			return
		end
		local character, root = live(player)
		if not character or not root then
			return
		end
		local key = visits:consume(player.UserId, token, os.clock(), character, function(candidate: string): boolean
			local entry = pads[candidate]
			return entry ~= nil
				and eligible(player, entry.id) == entry.plot
				and Rules.contains(entry.pad.part.CFrame:PointToObjectSpace(root.Position), entry.pad.part.Size, false)
		end)
		if key then
			local entry = pads[key]
			purchase(player, entry.plot, entry.id, entry.pad)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		visits:clear(player.UserId)
	end)
	local elapsed = 0
	RunService.Heartbeat:Connect(function(delta)
		elapsed += delta
		if elapsed < Rules.SampleInterval then
			return
		end
		elapsed = 0
		local now = os.clock()
		for _, player in Players:GetPlayers() do
			local character, root = live(player)
			if not character or not root then
				visits:clear(player.UserId)
				continue
			end
			for _, definition in Catalogue.Definitions do
				local plotId = eligible(player, definition.Id)
				if not plotId then
					continue
				end
				local pad = plots[plotId].pads[definition.Id]
				local token = visits:sample(
					player.UserId,
					character,
					`{plotId}/{definition.Id}`,
					pad.part.CFrame:PointToObjectSpace(root.Position),
					pad.part.Size,
					now
				)
				if token then
					remote:FireClient(player, token)
				end
			end
		end
	end)
end

return WalkOn
