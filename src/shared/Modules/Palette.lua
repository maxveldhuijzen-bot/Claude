--[[ Palette — one source of truth for UI colour, so panels stay consistent. ]]

local Palette = {}

Palette.background = Color3.fromRGB(18, 18, 30)
Palette.panel = Color3.fromRGB(28, 29, 48)
Palette.panelAlt = Color3.fromRGB(38, 40, 64)
Palette.stroke = Color3.fromRGB(64, 68, 105)
Palette.text = Color3.fromRGB(240, 242, 255)
Palette.textDim = Color3.fromRGB(158, 164, 196)

Palette.aura = Color3.fromRGB(140, 110, 255)
Palette.coins = Color3.fromRGB(255, 196, 74)
Palette.prisms = Color3.fromRGB(96, 232, 255)

Palette.positive = Color3.fromRGB(84, 226, 143)
Palette.negative = Color3.fromRGB(255, 96, 112)
Palette.warning = Color3.fromRGB(255, 176, 68)
Palette.premium = Color3.fromRGB(255, 138, 216)

Palette.rarity = {
	Common = Color3.fromRGB(176, 184, 204),
	Uncommon = Color3.fromRGB(108, 224, 142),
	Rare = Color3.fromRGB(84, 168, 255),
	Epic = Color3.fromRGB(186, 108, 255),
	Legendary = Color3.fromRGB(255, 178, 62),
	Mythic = Color3.fromRGB(255, 96, 132),
	Secret = Color3.fromRGB(64, 255, 226),
}

Palette.rarityOrder = {
	Common = 1,
	Uncommon = 2,
	Rare = 3,
	Epic = 4,
	Legendary = 5,
	Mythic = 6,
	Secret = 7,
}

--- Tier tint for pets: 1 normal, 2 golden, 3 rainbow (animated client side).
Palette.tier = {
	[1] = nil,
	[2] = Color3.fromRGB(255, 214, 82),
	[3] = Color3.fromRGB(255, 255, 255),
}

Palette.tierName = { [1] = "", [2] = "Golden ", [3] = "Rainbow " }

function Palette.rarityColor(rarity)
	return Palette.rarity[rarity] or Palette.textDim
end

return Palette
