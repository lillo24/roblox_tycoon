--!strict
-- Opt-in StudioTestService coordinator, never mapped into production.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio(), "Integration fixture is Studio-only")
local service = game:GetService("StudioTestService")
local args = service:GetTestArgs()
if typeof(args) ~= "table" or args.Kind ~= "INTEGRATE01" then
	return
end
assert(args.Players == 1 or args.Players == 2, "Integration test expects one or two clients")
local Players = game:GetService("Players")
local root = game:GetService("ReplicatedStorage")
local qa = script.Parent
assert(qa, "Integration server fixture folder expected")
local remote = Instance.new("RemoteEvent")
local walking = args.WalkOn == true
remote.Name = "INTEGRATE01Receipt"
remote:SetAttribute("Players", args.Players)
remote:SetAttribute("Duel", args.Duel == true)
remote:SetAttribute("WalkOn", walking)
remote.Parent = root
local ready: { [Player]: boolean } = {}
local passed: { [Player]: boolean } = {}
local issue: string? = nil
remote.OnServerEvent:Connect(function(player: Player, kind: any, value: any)
	if player.Parent ~= Players then
		return
	end
	if kind == "ready" then
		ready[player] = true
		local count = 0
		for _ in ready do
			count += 1
		end
		remote:SetAttribute("Ready", count == args.Players)
	elseif kind == "passed" then
		passed[player] = true
	elseif kind == "walked" and walking and args.Players == 1 then
		walking = false
	elseif kind == "failed" then
		issue = tostring(value)
	end
end)
if walking then
	local startupDeadline = os.clock() + 20
	while root:GetAttribute("TycoonServerRole") == nil and os.clock() < startupDeadline do
		task.wait(0.05)
	end
	if root:GetAttribute("TycoonServerRole") ~= "Prototype" then
		service:EndTest({ Passed = false, Issue = "Walk-on smoke requires a ready Factory role" })
		return
	end
end
local deadline = os.clock() + 150
while os.clock() < deadline and not issue do
	local count = 0
	for _ in passed do
		count += 1
	end
	if count == args.Players and not walking and qa:GetAttribute("AssertionsPassed") == true then
		print("INTEGRATE01 ENGINE SMOKE PASSED", root:GetAttribute("TycoonServerRole"), count)
		service:EndTest({ Passed = true, Role = root:GetAttribute("TycoonServerRole"), Clients = count })
		return
	end
	task.wait(0.1)
end
warn("INTEGRATE01 ENGINE SMOKE FAILED", issue or "Timed out waiting for server/client assertions")
service:EndTest({ Passed = false, Issue = issue or "Timed out waiting for assertions" })
