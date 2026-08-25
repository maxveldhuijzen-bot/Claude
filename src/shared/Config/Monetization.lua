--[[
	Monetization — gamepasses and developer products.

	Every `id` here is 0 on purpose. Create the passes/products on the Creator
	Hub, paste the numeric IDs in, and every button, prompt and grant starts
	working. Until then the game runs fine: the shop marks them "Not configured"
	and MarketplaceService is never called with an invalid ID.
]]

local Monetization = {}

Monetization.gamepasses = {
	vip = {
		key = "vip",
		id = 0,
		name = "VIP",
		desc = "x2 aura forever, +1 pet slot, and the Aurora Sanctum zone.",
		auraMult = 2,
		petSlots = 1,
		order = 1,
	},
	auto_collect = {
		key = "auto_collect",
		id = 0,
		name = "Auto Farm",
		desc = "Your collector swings on its own while you stand near a node.",
		grantsAutoCollect = true,
		order = 2,
	},
	lucky = {
		key = "lucky",
		id = 0,
		name = "x2 Luck",
		desc = "Doubles hatch luck. Stacks with Fortune upgrades.",
		luckMult = 2,
		order = 3,
	},
	pet_slots = {
		key = "pet_slots",
		id = 0,
		name = "+2 Pet Slots",
		desc = "Equip two more pets, permanently.",
		petSlots = 2,
		order = 4,
	},
	big_backpack = {
		key = "big_backpack",
		id = 0,
		name = "x3 Backpack",
		desc = "Triples carry capacity on every backpack tier.",
		capacityMult = 3,
		order = 5,
	},
}

--- Coin products grant a fraction of the player's *current* rebirth cost, so a
--- purchase is worth roughly the same amount of progress at every stage.
Monetization.products = {
	coins_small = {
		key = "coins_small",
		id = 0,
		name = "Pouch of Coins",
		desc = "35% of your current rebirth cost.",
		coinsAsRebirthFraction = 0.35,
		order = 1,
	},
	coins_medium = {
		key = "coins_medium",
		id = 0,
		name = "Chest of Coins",
		desc = "120% of your current rebirth cost.",
		coinsAsRebirthFraction = 1.2,
		order = 2,
	},
	coins_large = {
		key = "coins_large",
		id = 0,
		name = "Vault of Coins",
		desc = "400% of your current rebirth cost.",
		coinsAsRebirthFraction = 4.0,
		order = 3,
	},
	boost_2x = {
		key = "boost_2x",
		id = 0,
		name = "x2 Aura (30m)",
		desc = "Double aura for thirty minutes.",
		boost = { id = "product_2x", name = "x2 Aura", auraMult = 2, duration = 1800 },
		order = 4,
	},
	luck_potion = {
		key = "luck_potion",
		id = 0,
		name = "Luck Potion (15m)",
		desc = "x3 hatch luck for fifteen minutes.",
		boost = { id = "luck_potion", name = "x3 Luck", luckMult = 3, duration = 900 },
		order = 5,
	},
	prism_pack = {
		key = "prism_pack",
		id = 0,
		name = "Prism Bundle",
		desc = "25 prisms for the rebirth shop.",
		prisms = 25,
		order = 6,
	},
}

--- True when a real ID has been pasted in, i.e. safe to call MarketplaceService.
function Monetization.isConfigured(entry)
	return type(entry) == "table" and type(entry.id) == "number" and entry.id > 0
end

function Monetization.passById(assetId)
	for _, pass in pairs(Monetization.gamepasses) do
		if pass.id == assetId then
			return pass
		end
	end
	return nil
end

function Monetization.productById(assetId)
	for _, product in pairs(Monetization.products) do
		if product.id == assetId then
			return product
		end
	end
	return nil
end

--- Stable display order for shop grids.
function Monetization.sorted(collection)
	local list = {}
	for _, entry in pairs(collection) do
		table.insert(list, entry)
	end
	table.sort(list, function(a, b)
		return (a.order or 99) < (b.order or 99)
	end)
	return list
end

return Monetization
