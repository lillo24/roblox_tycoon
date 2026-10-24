--!strict

local Rules = require(game:GetService("ReplicatedStorage").TycoonShared.Experiments.FactoryPurchases.Rules)
local Visits = {}
Visits.__index = Visits
type Visit = { inside: boolean, token: number? }
type Owner = { character: Model, pads: { [string]: Visit } }
type Offer = { user: number, key: string, character: Model, expires: number }
export type Ledger = typeof(setmetatable({
	owners = {} :: { [number]: Owner },
	offers = {} :: { [number]: Offer },
	serial = 0,
}, Visits))

function Visits.new(): Ledger
	return setmetatable({ owners = {}, offers = {}, serial = 0 }, Visits)
end

function Visits.clear(self: Ledger, user: number)
	local owner = self.owners[user]
	if owner then
		for _, visit in owner.pads do
			if visit.token then
				self.offers[visit.token] = nil
			end
		end
	end
	self.owners[user] = nil
end

function Visits.sample(
	self: Ledger,
	user: number,
	character: Model,
	key: string,
	position: Vector3,
	size: Vector3,
	now: number
): number?
	local owner = self.owners[user]
	if not owner or owner.character ~= character then
		self:clear(user)
		owner = { character = character, pads = {} }
		self.owners[user] = owner
	end
	local visit = owner.pads[key]
	if not visit then
		local created: Visit = { inside = false, token = nil }
		visit = created
		owner.pads[key] = created
	end
	if visit.inside then
		if not Rules.contains(position, size, true) then
			visit.inside = false
			if visit.token then
				self.offers[visit.token] = nil
			end
			visit.token = nil
		elseif visit.token then
			local offer = self.offers[visit.token]
			if offer and now >= offer.expires then
				self.offers[visit.token] = nil
			end
		end
		return nil
	end
	if not Rules.contains(position, size, false) then
		return nil
	end
	visit.inside = true
	self.serial += 1
	visit.token = self.serial
	self.offers[self.serial] = { user = user, key = key, character = character, expires = now + Rules.OfferLifetime }
	return self.serial
end

-- A reply only consumes a server-created visit. No client pad/user/money input.
function Visits.consume(
	self: Ledger,
	user: number,
	token: any,
	now: number,
	character: Model,
	stillInside: (string) -> boolean
): string?
	if typeof(token) ~= "number" or token ~= token or token % 1 ~= 0 then
		return nil
	end
	local offer = self.offers[token]
	if not offer or offer.user ~= user or offer.character ~= character then
		return nil
	end
	self.offers[token] = nil -- One-use even if the remaining checks or purchase refuse.
	if now >= offer.expires or not stillInside(offer.key) then
		return nil
	end
	return offer.key
end

return Visits
