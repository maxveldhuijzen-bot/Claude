--[[
	StatService — derives every gameplay number from a profile.

	Nothing else computes power, capacity, luck or multipliers; services ask
	here. That keeps the client's displayed numbers and the server's authoritative
	numbers from drifting apart, because they come from one function.
]]

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Settings = require(Shared.Config.Settings)
local Zones = require(Shared.Config.Zones)
local Pets = require(Shared.Config.Pets)
local Collectors = require(Shared.Config.Collectors)
local Backpacks = require(Shared.Config.Backpacks)
local Rebirth = require(Shared.Config.Rebirth)
local Monetization = require(Shared.Config.Monetization)

local StatService = {}
local Services

function StatService.init(services)
	Services = services
end

function StatService.upgradeLevel(profile, id)
	return profile.upgrades[id] or 0
end

function StatService.collector(profile)
	return Collectors[math.clamp(profile.collectorIndex, 1, #Collectors)]
end

function StatService.backpack(profile)
	return Backpacks[math.clamp(profile.backpackIndex, 1, #Backpacks)]
end

function StatService.zone(profile)
	return Zones.get(profile.zone) or Zones.first()
end

--- 1 + the sum of every equipped pet's contribution.
function StatService.petMultiplier(profile)
	local total = 0
	for _, pet in ipairs(profile.pets) do
		if pet.equipped then
			local definition = Pets.get(pet.id)
			if definition then
				total += definition.mult * (Settings.TierMultipliers[pet.tier] or 1)
			end
		end
	end
	return 1 + total
end

function StatService.petLuck(profile)
	local total = 0
	for _, pet in ipairs(profile.pets) do
		if pet.equipped then
			local definition = Pets.get(pet.id)
			if definition then
				total += definition.luck * (Settings.TierMultipliers[pet.tier] or 1)
			end
		end
	end
	return total
end

function StatService.equippedCount(profile)
	local count = 0
	for _, pet in ipairs(profile.pets) do
		if pet.equipped then
			count += 1
		end
	end
	return count
end

--- The full derived stat block. Called on every swing, so it stays allocation
--- light and free of yields.
function StatService.compute(player, profile)
	profile = profile or Services.DataService.get(player)
	if not profile then
		return nil
	end

	local passes = Services.MonetizationService.passes(player)
	local boostAura, boostLuck = Services.BoostService.multipliers(profile)

	local collector = StatService.collector(profile)
	local backpack = StatService.backpack(profile)
	local zone = StatService.zone(profile)

	-- Aura multiplier ------------------------------------------------------
	local rebirthMult = 1 + profile.rebirths * Settings.RebirthAuraBonus
	local masteryMult = 1 + StatService.upgradeLevel(profile, "aura_mastery") * 0.12
	local petMult = StatService.petMultiplier(profile)

	local passAura = 1
	local passLuck = 1
	local passCapacity = 1
	local passPetSlots = 0
	local passAutoCollect = false

	for key, owned in pairs(passes) do
		if owned then
			local pass = Monetization.gamepasses[key]
			if pass then
				passAura *= pass.auraMult or 1
				passLuck *= pass.luckMult or 1
				passCapacity *= pass.capacityMult or 1
				passPetSlots += pass.petSlots or 0
				passAutoCollect = passAutoCollect or (pass.grantsAutoCollect == true)
			end
		end
	end

	local auraMult = rebirthMult * masteryMult * petMult * boostAura * passAura

	-- Luck ------------------------------------------------------------------
	local luck = (1 + StatService.petLuck(profile))
		* (1 + StatService.upgradeLevel(profile, "luck_mastery") * 0.08)
		* boostLuck
		* passLuck

	-- Selling ---------------------------------------------------------------
	local sellMult = zone.sellMult * (1 + StatService.upgradeLevel(profile, "sell_mastery") * 0.10)

	-- Auto collect ----------------------------------------------------------
	local autoLevel = StatService.upgradeLevel(profile, "auto_collect")
	local autoUnlocked = autoLevel > 0 or passAutoCollect
	local effectiveAutoLevel = math.max(autoLevel, passAutoCollect and 1 or 0)
	local autoInterval = Settings.CollectInterval * 1.5 * (1 - (effectiveAutoLevel - 1) * 0.12)
	autoInterval = math.max(autoInterval, Settings.CollectInterval)

	return {
		power = collector.power,
		collectorName = collector.name,
		backpackName = backpack.name,
		-- Capacity scales with the same multipliers as aura per swing. Without
		-- this, a fixed cap gets swamped the moment zone and pet multipliers
		-- start compounding, and a full backpack becomes less than one swing.
		-- Scaling both sides keeps time-to-fill a function of capacity/power
		-- alone, so the vault run stays the same length all game.
		capacity = backpack.capacity * auraMult * zone.auraMult * passCapacity,
		auraMult = auraMult,
		petMult = petMult,
		rebirthMult = rebirthMult,
		luck = luck,
		sellMult = sellMult,
		zoneMult = zone.auraMult,
		auraPerSwing = collector.power * auraMult * zone.auraMult,
		petSlots = math.clamp(
			Settings.BasePetSlots + StatService.upgradeLevel(profile, "pet_slots") + passPetSlots,
			1,
			Settings.MaxPetSlots
		),
		equippedPets = StatService.equippedCount(profile),
		walkSpeed = Settings.BaseWalkSpeed + StatService.upgradeLevel(profile, "swiftness") * 2,
		collectRange = Settings.CollectRange + StatService.upgradeLevel(profile, "magnetism") * 4,
		hatchTimeScale = 1 - StatService.upgradeLevel(profile, "hatch_haste") * 0.10,
		autoCollect = autoUnlocked,
		autoInterval = autoInterval,
		rebirthCost = Rebirth.cost(profile.rebirths),
		rebirthReward = Rebirth.prismReward(profile.rebirths),
	}
end

--- Pushes movement stats onto the character. Called on spawn and on upgrade.
function StatService.applyCharacter(player)
	local profile = Services.DataService.get(player)
	local character = player.Character
	if not profile or not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local stats = StatService.compute(player, profile)
	humanoid.WalkSpeed = stats.walkSpeed
	humanoid.JumpPower = Settings.BaseJumpPower
	humanoid.UseJumpPower = true
end

return StatService
