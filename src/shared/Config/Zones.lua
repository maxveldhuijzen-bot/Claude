--[[
	Zones — the progression spine.

	Each zone is a platform on the world axis. `auraMult` scales what nodes are
	worth, `sellMult` scales what the vault pays, so later zones are worth the
	walk twice over. Ordered array; `order` doubles as the array index.
]]

local Settings = require(script.Parent.Settings)

local function origin(index)
	return Vector3.new((index - 1) * Settings.ZoneSpacing, 0, 0)
end

local Zones = {
	{
		id = "meadow",
		name = "Sunrise Meadow",
		order = 1,
		unlockCost = 0,
		rebirthReq = 0,
		auraMult = 1,
		sellMult = 1,
		nodeCount = 16,
		nodeHp = 40,
		ground = Color3.fromRGB(126, 200, 116),
		accent = Color3.fromRGB(255, 214, 122),
		node = Color3.fromRGB(255, 236, 150),
		ambient = Color3.fromRGB(140, 140, 150),
		fog = Color3.fromRGB(200, 220, 255),
		tagline = "Where every farmer starts.",
	},
	{
		id = "grove",
		name = "Neon Grove",
		order = 2,
		unlockCost = 2500,
		rebirthReq = 0,
		auraMult = 3.5,
		sellMult = 1.15,
		nodeCount = 16,
		nodeHp = 110,
		ground = Color3.fromRGB(38, 46, 74),
		accent = Color3.fromRGB(94, 255, 226),
		node = Color3.fromRGB(120, 255, 214),
		ambient = Color3.fromRGB(70, 90, 110),
		fog = Color3.fromRGB(40, 90, 110),
		tagline = "Bioluminescent and buzzing.",
	},
	{
		id = "frost",
		name = "Frost Hollow",
		order = 3,
		unlockCost = 45000,
		rebirthReq = 0,
		auraMult = 13,
		sellMult = 1.35,
		nodeCount = 18,
		nodeHp = 320,
		ground = Color3.fromRGB(214, 232, 246),
		accent = Color3.fromRGB(126, 196, 255),
		node = Color3.fromRGB(168, 226, 255),
		ambient = Color3.fromRGB(150, 165, 190),
		fog = Color3.fromRGB(196, 220, 240),
		tagline = "Cold enough to crystallise aura.",
	},
	{
		id = "ember",
		name = "Ember Wastes",
		order = 4,
		unlockCost = 700000,
		rebirthReq = 0,
		auraMult = 52,
		sellMult = 1.6,
		nodeCount = 18,
		nodeHp = 950,
		ground = Color3.fromRGB(70, 40, 38),
		accent = Color3.fromRGB(255, 122, 60),
		node = Color3.fromRGB(255, 158, 74),
		ambient = Color3.fromRGB(110, 70, 60),
		fog = Color3.fromRGB(120, 60, 40),
		tagline = "Mind the heat. Farm anyway.",
	},
	{
		id = "void",
		name = "Void Beach",
		order = 5,
		unlockCost = 11000000,
		rebirthReq = 1,
		auraMult = 220,
		sellMult = 1.9,
		nodeCount = 20,
		nodeHp = 2800,
		ground = Color3.fromRGB(46, 38, 66),
		accent = Color3.fromRGB(168, 96, 255),
		node = Color3.fromRGB(186, 122, 255),
		ambient = Color3.fromRGB(60, 50, 80),
		fog = Color3.fromRGB(50, 34, 74),
		tagline = "The tide goes out and never comes back.",
	},
	{
		id = "reef",
		name = "Celestial Reef",
		order = 6,
		unlockCost = 180000000,
		rebirthReq = 3,
		auraMult = 950,
		sellMult = 2.3,
		nodeCount = 20,
		nodeHp = 8600,
		ground = Color3.fromRGB(30, 62, 96),
		accent = Color3.fromRGB(96, 214, 255),
		node = Color3.fromRGB(140, 236, 255),
		ambient = Color3.fromRGB(60, 90, 120),
		fog = Color3.fromRGB(30, 80, 120),
		tagline = "Coral made of starlight.",
	},
	{
		id = "spire",
		name = "Mythic Spire",
		order = 7,
		unlockCost = 3000000000,
		rebirthReq = 6,
		auraMult = 4200,
		sellMult = 2.8,
		nodeCount = 22,
		nodeHp = 26000,
		ground = Color3.fromRGB(58, 44, 84),
		accent = Color3.fromRGB(255, 168, 96),
		node = Color3.fromRGB(255, 196, 120),
		ambient = Color3.fromRGB(90, 70, 110),
		fog = Color3.fromRGB(70, 50, 100),
		tagline = "Only the rebirthed climb here.",
	},
	{
		id = "singularity",
		name = "Singularity",
		order = 8,
		unlockCost = 55000000000,
		rebirthReq = 10,
		auraMult = 20000,
		sellMult = 3.4,
		nodeCount = 22,
		nodeHp = 80000,
		ground = Color3.fromRGB(16, 16, 24),
		accent = Color3.fromRGB(255, 96, 168),
		node = Color3.fromRGB(255, 132, 196),
		ambient = Color3.fromRGB(40, 36, 56),
		fog = Color3.fromRGB(18, 14, 30),
		tagline = "Physics stopped applying a while ago.",
	},
	{
		id = "sanctum",
		name = "Aurora Sanctum",
		order = 9,
		unlockCost = 0,
		rebirthReq = 0,
		requiresPass = "vip", -- key into Config/Monetization.gamepasses
		auraMult = 2600,
		sellMult = 3.1,
		nodeCount = 20,
		nodeHp = 14000,
		ground = Color3.fromRGB(240, 236, 255),
		accent = Color3.fromRGB(255, 138, 216),
		node = Color3.fromRGB(255, 176, 232),
		ambient = Color3.fromRGB(170, 160, 200),
		fog = Color3.fromRGB(230, 210, 255),
		tagline = "VIP only. Worth it around rebirth 4.",
	},
}

for index, zone in ipairs(Zones) do
	zone.origin = origin(index)
	zone.spawn = zone.origin + Vector3.new(0, 6, 84)
end

local byId = {}
for _, zone in ipairs(Zones) do
	byId[zone.id] = zone
end

function Zones.get(id)
	return byId[id]
end

function Zones.first()
	return Zones[1]
end

--- Highest-order zone the player has unlocked — used for "return me home".
function Zones.best(unlocked)
	local best = Zones[1]
	for _, zone in ipairs(Zones) do
		if unlocked[zone.id] and zone.order > best.order then
			best = zone
		end
	end
	return best
end

return Zones
