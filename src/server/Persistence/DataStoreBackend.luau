--!strict

local Settings = require(script.Parent.Settings)
local Backend = {}

function Backend.open(): (((string, (any) -> any) -> any)?, string?)
	if game.GameId == 0 then
		return nil, "An isolated published test experience is required"
	end
	if game:GetService("RunService"):IsStudio() and game.GameId ~= Settings.StudioTestUniverseId then
		return nil, "Studio DataStore access is disabled for this universe; configure the isolated test universe"
	end
	local store = game:GetService("DataStoreService"):GetDataStore(Settings.StoreName)
	return function(key: string, transform: (any) -> any): any
		return store:UpdateAsync(key, function(current, info)
			local nextValue = transform(current)
			if nextValue == nil then
				return nil
			end
			-- Preserve service metadata when updating a profile envelope.
			return nextValue, if info then info:GetUserIds() else {}, if info then info:GetMetadata() else {}
		end)
	end,
		nil
end

return Backend
