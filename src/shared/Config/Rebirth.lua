--[[
	Rebirth — the long-term loop.

	Rebirthing wipes coins and resets the collector/backpack tiers, but keeps
	pets, prisms, upgrades and unlocked zones. That combination is what makes
	each run faster than the last instead of feeling like a punishment.
]]

local Rebirth = {
	baseCost = 60000,
	growth = 3.25,
}

--- Coins required to perform rebirth number `rebirths + 1`.
function Rebirth.cost(rebirths)
	return math.floor(Rebirth.baseCost * Rebirth.growth ^ rebirths)
end

--- Prisms paid out for performing rebirth number `rebirths + 1`.
function Rebirth.prismReward(rebirths)
	return math.floor(3 + rebirths * 2 + rebirths ^ 1.4)
end

Rebirth.upgrades = {
	{
		id = "aura_mastery",
		name = "Aura Mastery",
		desc = "+12% aura from every swing.",
		maxLevel = 25,
		baseCost = 3,
		costGrowth = 1.3,
		perLevel = 0.12,
	},
	{
		id = "sell_mastery",
		name = "Vault Broker",
		desc = "+10% coins when you sell.",
		maxLevel = 20,
		baseCost = 4,
		costGrowth = 1.3,
		perLevel = 0.10,
	},
	{
		id = "luck_mastery",
		name = "Fortune",
		desc = "+8% hatch luck.",
		maxLevel = 20,
		baseCost = 4,
		costGrowth = 1.32,
		perLevel = 0.08,
	},
	{
		id = "pet_slots",
		name = "Pet Slots",
		desc = "+1 equipped pet.",
		maxLevel = 6,
		baseCost = 25,
		costGrowth = 2.1,
		perLevel = 1,
	},
	{
		id = "swiftness",
		name = "Swiftness",
		desc = "+2 walk speed.",
		maxLevel = 10,
		baseCost = 5,
		costGrowth = 1.45,
		perLevel = 2,
	},
	{
		id = "magnetism",
		name = "Magnetism",
		desc = "+4 studs of collect range.",
		maxLevel = 8,
		baseCost = 6,
		costGrowth = 1.5,
		perLevel = 4,
	},
	{
		id = "hatch_haste",
		name = "Hatch Haste",
		desc = "-10% hatch animation time.",
		maxLevel = 5,
		baseCost = 8,
		costGrowth = 1.6,
		perLevel = 0.10,
	},
	{
		id = "auto_collect",
		name = "Auto Collect",
		desc = "Level 1 farms for you. Higher levels swing faster.",
		maxLevel = 5,
		baseCost = 40,
		costGrowth = 1.8,
		perLevel = 0.12,
	},
}

local upgradeById = {}
for _, upgrade in ipairs(Rebirth.upgrades) do
	upgradeById[upgrade.id] = upgrade
end

function Rebirth.getUpgrade(id)
	return upgradeById[id]
end

--- Prism price to go from `level` to `level + 1`.
function Rebirth.upgradeCost(upgrade, level)
	return math.floor(upgrade.baseCost * upgrade.costGrowth ^ level)
end

--- One-off cosmetic trails bought with prisms.
Rebirth.auras = {
	{ id = "none", name = "None", cost = 0, color = Color3.fromRGB(255, 255, 255) },
	{ id = "ember_wake", name = "Ember Wake", cost = 15, color = Color3.fromRGB(255, 130, 60) },
	{ id = "frost_halo", name = "Frost Halo", cost = 25, color = Color3.fromRGB(160, 220, 255) },
	{ id = "void_rift", name = "Void Rift", cost = 45, color = Color3.fromRGB(168, 96, 255) },
	{ id = "star_dust", name = "Star Dust", cost = 80, color = Color3.fromRGB(255, 226, 140) },
	{ id = "prism_bloom", name = "Prism Bloom", cost = 140, color = Color3.fromRGB(130, 255, 226) },
	{ id = "event_ring", name = "Event Ring", cost = 260, color = Color3.fromRGB(255, 96, 168) },
}

function Rebirth.getAura(id)
	for _, aura in ipairs(Rebirth.auras) do
		if aura.id == id then
			return aura
		end
	end
	return Rebirth.auras[1]
end

return Rebirth
