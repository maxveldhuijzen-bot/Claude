--[[
	PetService — equipping, deleting and fusing.

	Pets are rows on the profile: { uid, id, tier, equipped }. uid is a stable
	per-profile counter so the client can address a specific duplicate without
	the server trusting an array index.
]]

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Settings = require(Shared.Config.Settings)
local Pets = require(Shared.Config.Pets)
local Palette = require(Shared.Modules.Palette)

local PetService = {}
local Services

function PetService.init(services)
	Services = services
end

local function findByUid(profile, uid)
	for index, pet in ipairs(profile.pets) do
		if pet.uid == uid then
			return pet, index
		end
	end
	return nil
end

--- Adds a pet and updates the discovery index. Returns the new row.
function PetService.grant(profile, petId, tier)
	if #profile.pets >= Settings.MaxPetsOwned then
		return nil
	end

	profile.petUid += 1
	local pet = { uid = profile.petUid, id = petId, tier = tier or 1, equipped = false }
	table.insert(profile.pets, pet)

	profile.index[petId] = (profile.index[petId] or 0) + 1
	return pet
end

function PetService.displayName(pet)
	local definition = Pets.get(pet.id)
	if not definition then
		return "Unknown Pet"
	end
	return (Palette.tierName[pet.tier] or "") .. definition.name
end

function PetService.equip(player, payload)
	local profile = Services.DataService.get(player)
	if not profile then
		return false, "Still loading."
	end

	local pet = findByUid(profile, payload and payload.uid)
	if not pet then
		return false, "You do not own that pet."
	end

	if pet.equipped then
		return false, "Already equipped."
	end

	local stats = Services.StatService.compute(player, profile)
	if stats.equippedPets >= stats.petSlots then
		return false, "All pet slots are full."
	end

	pet.equipped = true
	Services.Replicator.markProfile(player)
	return true, { uid = pet.uid }
end

function PetService.unequip(player, payload)
	local profile = Services.DataService.get(player)
	if not profile then
		return false, "Still loading."
	end

	local pet = findByUid(profile, payload and payload.uid)
	if not pet or not pet.equipped then
		return false, "That pet is not equipped."
	end

	pet.equipped = false
	Services.Replicator.markProfile(player)
	return true, { uid = pet.uid }
end

--- Fills every slot with the highest-multiplier pets owned.
function PetService.equipBest(player)
	local profile = Services.DataService.get(player)
	if not profile then
		return false, "Still loading."
	end

	local stats = Services.StatService.compute(player, profile)

	local ranked = table.clone(profile.pets)
	table.sort(ranked, function(a, b)
		local defA = Pets.get(a.id)
		local defB = Pets.get(b.id)
		local valueA = defA and defA.mult * (Settings.TierMultipliers[a.tier] or 1) or 0
		local valueB = defB and defB.mult * (Settings.TierMultipliers[b.tier] or 1) or 0
		return valueA > valueB
	end)

	for _, pet in ipairs(profile.pets) do
		pet.equipped = false
	end

	local equipped = 0
	for _, pet in ipairs(ranked) do
		if equipped >= stats.petSlots then
			break
		end
		pet.equipped = true
		equipped += 1
	end

	Services.Replicator.markProfile(player)
	return true, { equipped = equipped }
end

function PetService.unequipAll(player)
	local profile = Services.DataService.get(player)
	if not profile then
		return false, "Still loading."
	end

	for _, pet in ipairs(profile.pets) do
		pet.equipped = false
	end

	Services.Replicator.markProfile(player)
	return true, {}
end

function PetService.delete(player, payload)
	local profile = Services.DataService.get(player)
	if not profile then
		return false, "Still loading."
	end

	local pet, index = findByUid(profile, payload and payload.uid)
	if not pet then
		return false, "You do not own that pet."
	end

	if pet.equipped then
		return false, "Unequip it first."
	end

	table.remove(profile.pets, index)
	Services.Replicator.markProfile(player)
	return true, { uid = payload.uid }
end

--- Bulk cleanup: removes every unequipped pet whose multiplier is below
--- `threshold` times the best equipped pet. Keeps the collection tidy without
--- ever touching something the player is actively using.
function PetService.deleteWeak(player)
	local profile = Services.DataService.get(player)
	if not profile then
		return false, "Still loading."
	end

	local bestEquipped = 0
	for _, pet in ipairs(profile.pets) do
		if pet.equipped then
			local definition = Pets.get(pet.id)
			if definition then
				bestEquipped = math.max(bestEquipped, definition.mult * (Settings.TierMultipliers[pet.tier] or 1))
			end
		end
	end

	if bestEquipped <= 0 then
		return false, "Equip a pet first so we know what to keep."
	end

	local threshold = bestEquipped * 0.02
	local removed = 0

	for index = #profile.pets, 1, -1 do
		local pet = profile.pets[index]
		local definition = Pets.get(pet.id)
		if not pet.equipped and definition then
			local value = definition.mult * (Settings.TierMultipliers[pet.tier] or 1)
			if value < threshold then
				table.remove(profile.pets, index)
				removed += 1
			end
		end
	end

	Services.Replicator.markProfile(player)
	Services.Notify.send(player, {
		title = removed > 0 and ("Released " .. removed .. " pets") or "Nothing to release",
		body = removed > 0 and "Anything under 2% of your best pet." or "Your collection is already tidy.",
		kind = removed > 0 and "good" or "info",
	})

	return true, { removed = removed }
end

--- Combines FuseCount identical pets into one of the next tier.
function PetService.fuse(player, payload)
	local profile = Services.DataService.get(player)
	if not profile then
		return false, "Still loading."
	end

	local petId = payload and payload.id
	local tier = tonumber(payload and payload.tier) or 1

	if not Pets.get(petId) then
		return false, "Unknown pet."
	end

	if tier >= 3 then
		return false, "Rainbow is the highest tier."
	end

	local matches = {}
	for index = #profile.pets, 1, -1 do
		local pet = profile.pets[index]
		if pet.id == petId and pet.tier == tier and not pet.equipped then
			table.insert(matches, index)
			if #matches >= Settings.FuseCount then
				break
			end
		end
	end

	if #matches < Settings.FuseCount then
		return false, string.format("Need %d unequipped copies (you have %d).", Settings.FuseCount, #matches)
	end

	-- Indices were collected back-to-front, so removing in order stays valid.
	for _, index in ipairs(matches) do
		table.remove(profile.pets, index)
	end

	local created = PetService.grant(profile, petId, tier + 1)
	profile.stats.fuses += 1

	Services.QuestService.progress(player, "fuse", 1)
	Services.Replicator.markProfile(player)

	local name = created and PetService.displayName(created) or "pet"
	Services.Notify.send(player, {
		title = "Fused into " .. name,
		body = string.format("x%.1f the stats of a normal one.", Settings.TierMultipliers[tier + 1]),
		kind = "premium",
	})
	Services.Notify.effect(player, { kind = "fuse", pet = petId, tier = tier + 1 })

	return true, { uid = created and created.uid, tier = tier + 1 }
end

return PetService
