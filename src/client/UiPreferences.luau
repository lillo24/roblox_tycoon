--!strict

-- Module lifetime is the client session, independent of HUD/character lifetime.
local Preferences = {}
export type Values = { large: boolean, reduceMotion: boolean, labels: boolean }

function Preferences.defaults(): Values
	return { large = false, reduceMotion = false, labels = true }
end

function Preferences.scale(values: Values): number
	return if values.large then 1.15 else 1
end

function Preferences.motionReduced(values: Values, platformReduced: boolean): boolean
	return values.reduceMotion or platformReduced
end

local session = Preferences.defaults()
function Preferences.value(values: Values, key: "large" | "reduceMotion" | "labels"): boolean
	if key == "large" then
		return values.large
	end
	if key == "reduceMotion" then
		return values.reduceMotion
	end
	return values.labels
end
function Preferences.read(): Values
	return table.clone(session)
end

function Preferences.set(key: "large" | "reduceMotion" | "labels", value: boolean)
	if key == "large" then
		session.large = value
	elseif key == "reduceMotion" then
		session.reduceMotion = value
	else
		session.labels = value
	end
end

function Preferences.reset()
	session = Preferences.defaults()
end

return Preferences
