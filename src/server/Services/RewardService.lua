--[[
	RewardService — one grant function shared by quests, dailies, playtime,
	codes and developer products.

	`coinsAsRebirthFraction` is the important one: a reward defined as "40% of
	your current rebirth cost" is worth the same amount of *progress* on day one
	and at rebirth 40, so reward tables never need rebalancing.
]]

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Rebirth = require(Shared.Config.Rebirth)
local Format = require(Shared.Modules.Format)

local RewardService = {}
local Services

function RewardService.init(services)
	Services = services
end

--- Returns a short human-readable summary of a reward table, for buttons.
function RewardService.describe(profile, reward)
	local pieces = {}

	if reward.coins then
		table.insert(pieces, Format.abbreviate(reward.coins) .. " coins")
	end

	if reward.coinsAsRebirthFraction then
		local amount = Rebirth.cost(profile.rebirths) * reward.coinsAsRebirthFraction
		table.insert(pieces, Format.abbreviate(amount) .. " coins")
	end

	if reward.prisms then
		table.insert(pieces, reward.prisms .. " prisms")
	end

	if reward.boost then
		table.insert(pieces, reward.boost.name or "a boost")
	end

	if #pieces == 0 then
		return "a reward"
	end

	return table.concat(pieces, " + ")
end

function RewardService.grant(player, reward)
	local profile = Services.DataService.get(player)
	if not profile or type(reward) ~= "table" then
		return false
	end

	local granted = {}

	local coins = reward.coins or 0
	if reward.coinsAsRebirthFraction then
		coins += math.floor(Rebirth.cost(profile.rebirths) * reward.coinsAsRebirthFraction)
	end

	if coins > 0 then
		profile.coins += coins
		profile.stats.totalCoins += coins
		granted.coins = coins
	end

	if reward.prisms and reward.prisms > 0 then
		profile.prisms += reward.prisms
		granted.prisms = reward.prisms
	end

	if reward.boost then
		Services.BoostService.grant(player, reward.boost)
		granted.boost = reward.boost.name
	end

	if reward.pets then
		for _, entry in ipairs(reward.pets) do
			Services.PetService.grant(profile, entry.id, entry.tier or 1)
		end
		granted.pets = #reward.pets
	end

	Services.Replicator.markProfile(player)
	return true, granted
end

return RewardService
