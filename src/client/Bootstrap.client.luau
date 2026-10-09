--!strict

local Hud = require(script.Parent.Hud)
local Chooser = require(script.Parent.ModeChooser)
local root = game:GetService("ReplicatedStorage")
local deadline = os.clock() + 20
while root:GetAttribute("TycoonServerRole") == nil and os.clock() < deadline do
	task.wait(0.05)
end
local role = root:GetAttribute("TycoonServerRole") or "Unavailable"
if role == "Prototype" or role == "Infinite" then
	Hud.start()
end
Chooser.start(role :: string)

print("[roblox_tycoon] Client bootstrap ready.")
