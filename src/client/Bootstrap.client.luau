--!strict

local Hud = require(script.Parent.Hud)
local Chooser = require(script.Parent.ModeChooser)
local Factory = require(script.Parent.Experiments.FactoryPurchases.Controller)
local Clash = require(script.Parent.Experiments.AimClash.Controller)
local root = game:GetService("ReplicatedStorage")
local deadline = os.clock() + 20
while root:GetAttribute("TycoonServerRole") == nil and os.clock() < deadline do
	task.wait(0.05)
end
local role = root:GetAttribute("TycoonServerRole") or "Unavailable"
if role == "Prototype" then
	Factory.start()
elseif role == "Infinite" then
	Hud.start()
elseif role == "Clash" then
	Clash.start()
end
Chooser.start(role :: string)

print("[roblox_tycoon] Client bootstrap ready.")
