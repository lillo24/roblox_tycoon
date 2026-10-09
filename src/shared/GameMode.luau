--!strict

-- Studio-owned ReplicatedStorage/TycoonMode StringValue, fixed before startup.
-- Absent means the existing session-only prototype. Never infer mode from a
-- missing event dependency: that could hide a broken ordinary-mode server.
local Mode = {}
Mode.Name = "TycoonMode"

function Mode.read(): string
	local root = game:GetService("ReplicatedStorage")
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
	assert(object.Value == "Prototype" or object.Value == "Infinite", "TycoonMode must be Prototype or Infinite")
	return object.Value
end

return table.freeze(Mode)
