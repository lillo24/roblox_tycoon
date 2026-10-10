--!strict
local TeleportService = game:GetService("TeleportService")
local Adapter = {}
function Adapter.send(player: Player, placeId: number, token: string): (boolean, string)
	local options = Instance.new("TeleportOptions")
	-- No reserved-server options: ordinary public social lobbies.
	-- This nonce is correlation only, never account data or write authorization.
	options:SetTeleportData({ modeAttempt = token })
	local ok, issue = pcall(function()
		TeleportService:TeleportAsync(placeId, { player }, options)
	end)
	if not ok then
		warn(`Mode teleport to {placeId} failed: {tostring(issue)}`)
		return false, "Roblox could not start joining. You can retry shortly."
	end
	return true, "Request accepted; arrival unconfirmed"
end
function Adapter.listen(failed: (Player, string, number, string) -> ()): RBXScriptConnection
	return TeleportService.TeleportInitFailed:Connect(function(player, result, _message, placeId, options)
		-- Roblox may return a NEW TeleportOptions object. Compare the nonce, not
		-- object identity; never trust a payload on destination arrival.
		if not options then
			return
		end
		local data: any = options:GetTeleportData()
		if typeof(data) ~= "table" or typeof(data.modeAttempt) ~= "string" then
			return
		end
		failed(player, data.modeAttempt, placeId, "Joining failed (" .. result.Name .. ").")
	end)
end
return Adapter
