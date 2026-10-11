--!strict

-- AppRuntime publishes the trusted server role before gameplay. The authored
-- StringValue is only a Studio preview selector; absent preserves Prototype.
-- Hosted resolution never trusts a client or teleport payload (Routing/README).
local Mode = {}
Mode.Name = "TycoonMode"

function Mode.read(): string
	local root = game:GetService("ReplicatedStorage")
	local trusted = root:GetAttribute("TycoonServerRole")
	if trusted ~= nil then
		assert(typeof(trusted) == "string", "Server role must be a string")
		assert(table.find({ "Prototype", "Infinite", "Entry", "Unavailable" }, trusted), "Invalid server role")
		return trusted :: string
	end
	local object = root:FindFirstChild(Mode.Name)
	local count = 0
	for _, child in root:GetChildren() do
		if child.Name == Mode.Name then
			count += 1
		end
	end
	assert(count <= 1, "TycoonMode must appear at most once")
	if not object then
		return "Prototype"
	end
	assert(object:IsA("StringValue"), "TycoonMode must be a StringValue")
	assert(
		table.find({ "Prototype", "Infinite", "Entry" }, object.Value),
		"TycoonMode must be Prototype, Infinite or Entry"
	)
	return object.Value
end

return table.freeze(Mode)
