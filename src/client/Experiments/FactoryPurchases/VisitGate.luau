--!strict
-- Non-authoritative input suppression. Remember locally blocked entries even
-- when server position/offer replication arrives after a menu has closed.
local Gate = {}
Gate.__index = Gate
export type Sample = { key: string, inside: boolean, withinExit: boolean }
type Data = { character: any, blocked: { [string]: boolean }, inside: { [string]: boolean }, wasModal: boolean }
export type Gate = typeof(setmetatable({} :: Data, Gate))
function Gate.new(): Gate
	return setmetatable({ character = nil, blocked = {}, inside = {}, wasModal = false }, Gate)
end
function Gate.sample(self: Gate, character: any, modal: boolean, samples: { Sample })
	if character ~= self.character then
		table.clear(self.blocked)
		self.wasModal = false
		self.character = character
	end
	local blocked, inside: { [string]: boolean } = {}, {}
	for _, item in samples do
		inside[item.key] = item.inside
		if item.withinExit and (self.blocked[item.key] or item.inside and (modal or self.wasModal)) then
			blocked[item.key] = true
		end
	end
	self.blocked, self.inside, self.wasModal = blocked, inside, modal
end
function Gate.respond(self: Gate, key: string): boolean
	return self.inside[key] == true and not self.blocked[key] and not self.wasModal
end
return Gate
