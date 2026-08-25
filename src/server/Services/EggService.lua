--[[
	EggService — hatching.

	Rolls happen server side against Config/Eggs weights, biased by the player's
	luck stat. The client is told the results after the fact and plays the
	reveal animation; it never picks a pet.
]]

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Settings = require(Shared.Config.Settings)
local Eggs = require(Shared.Config.Eggs)
local Pets = require(Shared.Config.Pets)
local Zones = require(Shared.Config.Zones)
local Rng = require(Shared.Modules.Rng)
local Format = require(Shared.Modules.Format)

local EggService = {}
local Services

function EggService.init(services)
	Services = services
end

--- Swaps a freshly hatched pet in if it beats the weakest equipped one.
local function considerAutoEquip(profile, pet, stats)
	if not profile.prefs.autoEquip then
		return false
	end

	local definition = Pets.get(pet.id)
	if not definition then
		return false
	end

	local value = definition.mult * (Settings.TierMultipliers[pet.tier] or 1)

	local equipped = {}
	for _, owned in ipairs(profile.pets) do
		if owned.equipped then
			table.insert(equipped, owned)
		end
	end

	if #equipped < stats.petSlots then
		pet.equipped = true
		return true
	end

	local weakest, weakestValue = nil, math.huge
	for _, owned in ipairs(equipped) do
		local ownedDefinition = Pets.get(owned.id)
		if ownedDefinition then
			local ownedValue = ownedDefinition.mult * (Settings.TierMultipliers[owned.tier] or 1)
			if ownedValue < weakestValue then
				weakest, weakestValue = owned, ownedValue
			end
		end
	end

	if weakest and value > weakestValue then
		weakest.equipped = false
		pet.equipped = true
		return true
	end

	return false
end

function EggService.hatch(player, payload)
	local profile = Services.DataService.get(player)
	if not profile then
		return false, "Still loading."
	end

	local egg = Eggs.get(payload and payload.egg)
	if not egg then
		return false, "Unknown egg."
	end

	local count = tonumber(payload and payload.count) or 1
	if not table.find(Eggs.batchSizes, count) then
		return false, "Invalid hatch amount."
	end

	local zone = Zones.get(egg.zone)
	local allowed, reason = Services.ZoneService.canEnter(player, profile, zone)
	if not allowed then
		return false, reason
	end

	if #profile.pets + count > Settings.MaxPetsOwned then
		return false, string.format("Pet limit is %d. Release a few first.", Settings.MaxPetsOwned)
	end

	local cost = egg.cost * count
	if profile.coins < cost then
		return false, "Need " .. Format.abbreviate(cost - profile.coins) .. " more coins."
	end

	profile.coins -= cost

	local stats = Services.StatService.compute(player, profile)
	local results = {}

	for _ = 1, count do
		local petId = Rng.weighted(egg.pool, stats.luck)
		local definition = Pets.get(petId)
		if definition then
			local pet = Services.PetService.grant(profile, petId, 1)
			if pet then
				local autoEquipped = considerAutoEquip(profile, pet, stats)
				table.insert(results, {
					uid = pet.uid,
					id = petId,
					tier = 1,
					name = definition.name,
					rarity = definition.rarity,
					mult = definition.mult,
					isNew = (profile.index[petId] or 0) <= 1,
					equipped = autoEquipped,
				})
			end
		end
	end

	profile.stats.hatches += count
	Services.QuestService.progress(player, "hatch", count)
	Services.Replicator.markProfile(player)

	Services.Notify.effect(player, {
		kind = "hatch",
		egg = egg.id,
		results = results,
		hatchTime = egg.hatchTime * stats.hatchTimeScale,
	})

	return true, { results = results }
end

return EggService
