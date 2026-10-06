--!strict

-- Roblox lifecycle/claim boundary and coherent current-state replication.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Rules = require(ReplicatedStorage.TycoonShared.SupplyRules)
local Session = require(script.Parent.Session)
local SupplyEvent = require(script.Parent.SupplyEvent)
local SupplyWorld = require(script.Parent.SupplyWorld)

local SupplyRuntime = {}
SupplyRuntime.__index = SupplyRuntime
type Data = {
	session: Session.Session,
	active: { [number]: Player },
	publish: (Player, Session.State) -> (),
	event: SupplyEvent.Event,
	world: SupplyWorld.World,
	state: StringValue,
	feedback: RemoteEvent,
	nextRequest: { [number]: number },
	prompt: ProximityPrompt?,
	promptId: number?,
}
export type Runtime = typeof(setmetatable({} :: Data, SupplyRuntime))

function SupplyRuntime.inspect(): Vector3
	for _, name in { Rules.StateName, Rules.FeedbackName } do
		assert(not ReplicatedStorage:FindFirstChild(name), `Supply Cache: reserved ReplicatedStorage/{name} exists`)
	end
	return SupplyWorld.inspect()
end

function SupplyRuntime.new(
	session: Session.Session,
	active: { [number]: Player },
	publish: (Player, Session.State) -> (),
	parent: Instance,
	center: Vector3
): Runtime
	local event = SupplyEvent.new(Rules.Tuning)
	local world = SupplyWorld.create(parent, center)
	SupplyWorld.render(world, event:snapshot())
	local state = Instance.new("StringValue")
	state.Name = Rules.StateName
	state.Archivable = false
	state:SetAttribute("Position", world.cache.Position)
	state.Value = HttpService:JSONEncode(event:snapshot())
	state.Parent = ReplicatedStorage
	local feedback = Instance.new("RemoteEvent")
	feedback.Name = Rules.FeedbackName
	feedback.Archivable = false
	feedback.Parent = ReplicatedStorage
	local self: Runtime = setmetatable({
		session = session,
		active = active,
		publish = publish,
		event = event,
		world = world,
		state = state,
		feedback = feedback,
		nextRequest = {},
	}, SupplyRuntime)
	self:sync(workspace:GetServerTimeNow())
	return self
end

function SupplyRuntime.sync(self: Runtime, now: number)
	self.event:sync(now, self.session:assignedCount())
	local snapshot = self.event:snapshot()
	if self.promptId ~= snapshot.id then
		if self.prompt then
			self.prompt:Destroy()
		end
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "Claim"
		prompt.ObjectText = "Shared Supply Cache"
		prompt.ActionText = `Claim +{snapshot.reward} cash`
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = Rules.Tuning.Radius
		prompt.RequiresLineOfSight = false
		prompt.ClickablePrompt = true
		prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
		prompt.Enabled = false
		prompt:SetAttribute("EventId", snapshot.id)
		prompt.Parent = self.world.cache
		local boundId = snapshot.id -- Captured on the server, never read back from client attributes.
		prompt.Triggered:Connect(function(player: Player)
			self:claim(player, boundId)
		end)
		self.prompt, self.promptId = prompt, boundId
	end
	local prompt = self.prompt
	assert(prompt, "Supply Cache: missing claim prompt")
	prompt.Enabled = snapshot.phase == "open"
	local encoded = HttpService:JSONEncode(snapshot)
	if self.state.Value ~= encoded then
		self.state.Value = encoded -- One atomic value: subscribers cannot read a half-written snapshot.
		SupplyWorld.render(self.world, snapshot)
	end
end

function SupplyRuntime.leave(self: Runtime, player: Player)
	self.nextRequest[player.UserId] = nil
	self:sync(workspace:GetServerTimeNow())
end

function SupplyRuntime.claim(self: Runtime, player: Player, boundId: number)
	if player.Parent ~= Players or self.active[player.UserId] ~= player then
		return
	end
	local requestTime = os.clock()
	if requestTime < (self.nextRequest[player.UserId] or 0) then
		return
	end
	self.nextRequest[player.UserId] = requestTime + Rules.Tuning.RequestInterval
	local now = workspace:GetServerTimeNow()
	self:sync(now)
	local message: string
	local state = self.session:get(player.UserId)
	if not state then
		message = "A plot is needed to claim"
	else
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		local humanoid = if character then character:FindFirstChildWhichIsA("Humanoid") else nil
		if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
			message = "Respawn before claiming"
		elseif (root.Position - self.world.cache.Position).Magnitude > Rules.Tuning.Radius then
			message = "Move closer to the cache"
		else
			local accepted, reason = self.event:claim(self.session, player.UserId, player.DisplayName, boundId, now)
			if accepted then
				self.publish(player, state)
				message = `Claimed +{Rules.Tuning.Reward} cash`
			else
				message = if reason == "stale"
					then "Cache changed — try the current event"
					elseif reason == "already-claimed" then "Already claimed"
					elseif reason == "inactive" then "A plot is needed to claim"
					else "Cache is closed"
			end
		end
	end
	self:sync(now)
	-- Separate from the purchase-only remote and its limiter. No client-to-server handler.
	self.feedback:FireClient(player, self.event:snapshot().id, message)
end

return SupplyRuntime
