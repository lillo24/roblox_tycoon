--!strict

-- AppRuntime publishes the trusted server role before gameplay. The authored
-- StringValue is only a Studio preview selector; absent opens the Entry menu.
-- Hosted resolution never trusts a client or teleport payload (Routing/README).
local Mode = {}
Mode.Name = "TycoonMode"
Mode.Roles = table.freeze({ "Entry", "Prototype", "Infinite", "Clash" })
Mode.Choices = table.freeze({
	table.freeze({
		role = "Prototype",
		name = "Factory Challenge",
		detail = "Build a six-player factory. Walk onto upgrade pads; progress lasts this visit.",
	}),
	table.freeze({
		role = "Infinite",
		name = "Infinite World",
		detail = "Grow, decorate and save your own calm social property.",
	}),
	table.freeze({
		role = "Clash",
		name = "Aim Clash",
		detail = "Click or tap the circles. Solo Practice or a two-player Duel queue.",
	}),
})

function Mode.read(): string
	local root = game:GetService("ReplicatedStorage")
	local trusted = root:GetAttribute("TycoonServerRole")
	if trusted ~= nil then
		assert(typeof(trusted) == "string", "Server role must be a string")
		assert(trusted == "Unavailable" or table.find(Mode.Roles, trusted), "Invalid server role")
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
		return "Entry"
	end
	assert(object:IsA("StringValue"), "TycoonMode must be a StringValue")
	assert(table.find(Mode.Roles, object.Value), "TycoonMode must be Entry, Prototype, Infinite or Clash")
	return object.Value
end

return table.freeze(Mode)
