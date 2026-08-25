--[[
	Rng — weighted random selection with a luck stat.

	Luck raises the weight of rare entries while leaving the most common entry
	untouched:

	    adjusted = weight * luck ^ (1 - weight / maxWeight)

	The exponent is ~0 for the commonest row and ~1 for the rarest, so `luck`
	is the multiplier applied to the rarest drop and nothing gets more than
	that. A flatter curve (weight^(1/luck)) looks tempting but collapses the
	whole rarity spread at high luck — at luck 8 a Secret would land at 5% and
	the chase would be over.
]]

local Rng = {}

local generator = Random.new(os.clock() * 1e6 % 2 ^ 31)

function Rng.float(min, max)
	return generator:NextNumber(min, max)
end

function Rng.int(min, max)
	return generator:NextInteger(min, max)
end

function Rng.chance(probability)
	return generator:NextNumber() < probability
end

--- Applies luck to a pool, returning the adjusted weights and their total.
local function applyLuck(pool, luck)
	luck = math.max(luck or 1, 1)

	local maxWeight = 0
	for _, weight in pairs(pool) do
		maxWeight = math.max(maxWeight, weight)
	end

	local weights, total = {}, 0
	for key, weight in pairs(pool) do
		local adjusted = weight
		if luck > 1 and maxWeight > 0 then
			adjusted = weight * luck ^ (1 - weight / maxWeight)
		end
		weights[key] = adjusted
		total += adjusted
	end

	return weights, total
end

--- pool: { [key] = weight }. Returns the chosen key.
function Rng.weighted(pool, luck)
	local weights, total = applyLuck(pool, luck)

	if total <= 0 then
		return (next(pool))
	end

	local roll = generator:NextNumber() * total
	local cursor = 0
	for key, adjusted in pairs(weights) do
		cursor += adjusted
		if roll <= cursor then
			return key
		end
	end

	return (next(pool))
end

--- Odds of each key as a 0-1 fraction, for the "chances" UI on egg previews.
function Rng.odds(pool, luck)
	local weights, total = applyLuck(pool, luck)

	local out = {}
	for key, adjusted in pairs(weights) do
		out[key] = total > 0 and adjusted / total or 0
	end
	return out
end

function Rng.pick(list)
	if #list == 0 then
		return nil
	end
	return list[generator:NextInteger(1, #list)]
end

return Rng
