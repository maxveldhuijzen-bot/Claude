--[[
	Pets — the collection layer.

	`mult` is added into the aura multiplier sum (total = 1 + sum of equipped),
	`luck` is added into the hatch luck stat. Values climb roughly 4x per egg so
	that a fresh egg's Common still beats the previous egg's Rare — the reason
	players keep hatching instead of hoarding.

	`shape` selects a procedurally built model (see client/UI/PetBuilder), so the
	whole roster ships with zero uploaded assets.
]]

local defs = {}
local currentEgg

local function add(id, name, rarity, mult, luck, r, g, b, shape)
	defs[id] = {
		id = id,
		egg = currentEgg,
		name = name,
		rarity = rarity,
		mult = mult,
		luck = luck,
		color = Color3.fromRGB(r, g, b),
		shape = shape,
	}
end

-- Meadow Egg ---------------------------------------------------------------
currentEgg = "meadow"
add("pebble_sprite", "Pebble Sprite", "Common", 0.10, 0, 176, 168, 150, "ball")
add("meadow_bunny", "Meadow Bunny", "Common", 0.16, 0, 236, 226, 204, "ball")
add("sun_moth", "Sun Moth", "Uncommon", 0.34, 0.02, 255, 232, 150, "wisp")
add("dawn_fox", "Dawn Fox", "Rare", 0.72, 0.04, 255, 158, 92, "cube")
add("gilded_ladybug", "Gilded Ladybug", "Epic", 1.5, 0.08, 255, 196, 74, "orb")
add("sunrise_phoenix", "Sunrise Phoenix", "Legendary", 3.4, 0.18, 255, 130, 70, "star")

-- Neon Egg -----------------------------------------------------------------
currentEgg = "grove"
add("neon_slime", "Neon Slime", "Common", 0.55, 0, 120, 255, 190, "ball")
add("circuit_mouse", "Circuit Mouse", "Common", 0.80, 0, 150, 226, 255, "cube")
add("glow_beetle", "Glow Beetle", "Uncommon", 1.6, 0.03, 96, 255, 226, "orb")
add("laser_lynx", "Laser Lynx", "Rare", 3.2, 0.06, 255, 96, 214, "shard")
add("hologram_wolf", "Hologram Wolf", "Epic", 6.8, 0.12, 130, 200, 255, "prism")
add("neon_dragon", "Neon Dragon", "Legendary", 15, 0.26, 94, 255, 226, "star")
add("prism_overlord", "Prism Overlord", "Mythic", 38, 0.55, 226, 130, 255, "diamond")

-- Frost Egg ----------------------------------------------------------------
currentEgg = "frost"
add("snow_pup", "Snow Pup", "Common", 2.2, 0, 240, 248, 255, "ball")
add("icicle_crab", "Icicle Crab", "Common", 3.0, 0, 186, 226, 255, "cube")
add("frost_owl", "Frost Owl", "Uncommon", 6.5, 0.04, 214, 236, 255, "wisp")
add("glacier_bear", "Glacier Bear", "Rare", 14, 0.08, 150, 200, 246, "cube")
add("aurora_stag", "Aurora Stag", "Epic", 30, 0.16, 130, 255, 214, "star")
add("blizzard_wyrm", "Blizzard Wyrm", "Legendary", 68, 0.32, 96, 176, 255, "shard")
add("absolute_zero", "Absolute Zero", "Mythic", 165, 0.70, 255, 255, 255, "diamond")

-- Ember Egg ----------------------------------------------------------------
currentEgg = "ember"
add("cinder_imp", "Cinder Imp", "Common", 9, 0, 255, 140, 80, "ball")
add("ash_hound", "Ash Hound", "Common", 12, 0, 120, 100, 96, "cube")
add("magma_slug", "Magma Slug", "Uncommon", 26, 0.05, 255, 96, 40, "orb")
add("ember_drake", "Ember Drake", "Rare", 56, 0.10, 255, 168, 60, "shard")
add("inferno_titan", "Inferno Titan", "Epic", 120, 0.20, 226, 62, 40, "prism")
add("solar_phoenix", "Solar Phoenix", "Legendary", 270, 0.40, 255, 214, 96, "star")
add("heat_death", "Heat Death", "Mythic", 660, 0.85, 255, 60, 30, "diamond")

-- Void Egg -----------------------------------------------------------------
currentEgg = "void"
add("void_wisp", "Void Wisp", "Common", 40, 0, 150, 120, 200, "wisp")
add("null_crawler", "Null Crawler", "Common", 54, 0, 90, 70, 130, "cube")
add("shadow_serpent", "Shadow Serpent", "Uncommon", 115, 0.06, 120, 80, 190, "shard")
add("eclipse_panther", "Eclipse Panther", "Rare", 250, 0.12, 60, 44, 90, "prism")
add("void_leviathan", "Void Leviathan", "Epic", 540, 0.24, 168, 96, 255, "star")
add("entropy_warden", "Entropy Warden", "Legendary", 1200, 0.48, 214, 140, 255, "diamond")
add("event_horizon", "Event Horizon", "Secret", 3400, 1.20, 20, 20, 32, "orb")

-- Celestial Egg ------------------------------------------------------------
currentEgg = "reef"
add("star_kitten", "Star Kitten", "Common", 180, 0, 255, 240, 200, "ball")
add("comet_hare", "Comet Hare", "Common", 240, 0, 200, 236, 255, "wisp")
add("nebula_ray", "Nebula Ray", "Uncommon", 510, 0.07, 168, 140, 255, "prism")
add("galaxy_guardian", "Galaxy Guardian", "Rare", 1100, 0.14, 96, 214, 255, "cube")
add("quasar_djinn", "Quasar Djinn", "Epic", 2400, 0.28, 140, 255, 246, "shard")
add("astral_sovereign", "Astral Sovereign", "Legendary", 5200, 0.56, 255, 226, 140, "star")
add("big_bang", "Big Bang", "Secret", 15000, 1.40, 255, 255, 246, "diamond")

-- Mythic Egg ---------------------------------------------------------------
currentEgg = "spire"
add("rune_golem", "Rune Golem", "Common", 800, 0, 168, 140, 110, "cube")
add("myth_serpent", "Myth Serpent", "Common", 1100, 0, 120, 190, 140, "shard")
add("oracle_sphinx", "Oracle Sphinx", "Uncommon", 2300, 0.08, 255, 214, 150, "prism")
add("titan_of_ages", "Titan of Ages", "Rare", 5000, 0.16, 190, 170, 255, "cube")
add("worldtree_drake", "Worldtree Drake", "Epic", 11000, 0.32, 120, 226, 150, "star")
add("mythic_ascendant", "Mythic Ascendant", "Legendary", 24000, 0.64, 255, 168, 96, "diamond")
add("the_author", "The Author", "Mythic", 58000, 1.10, 255, 255, 255, "orb")

-- Singularity Egg ----------------------------------------------------------
currentEgg = "singularity"
add("quark_pup", "Quark Pup", "Common", 3600, 0, 255, 150, 200, "ball")
add("tachyon_moth", "Tachyon Moth", "Common", 4900, 0, 200, 160, 255, "wisp")
add("gravity_wraith", "Gravity Wraith", "Uncommon", 10000, 0.09, 96, 96, 140, "prism")
add("horizon_stalker", "Horizon Stalker", "Rare", 22000, 0.18, 150, 96, 226, "shard")
add("infinity_hydra", "Infinity Hydra", "Epic", 48000, 0.36, 255, 120, 180, "star")
add("omega_sovereign", "Omega Sovereign", "Legendary", 110000, 0.72, 255, 226, 255, "diamond")
add("the_singularity", "The Singularity", "Secret", 320000, 1.80, 10, 10, 16, "orb")

local Pets = {}

function Pets.get(id)
	return defs[id]
end

function Pets.all()
	return defs
end

--- Sorted list, best first — the pet menu's default ordering.
function Pets.sortedIds()
	local ids = {}
	for id in pairs(defs) do
		table.insert(ids, id)
	end
	table.sort(ids, function(a, b)
		return defs[a].mult > defs[b].mult
	end)
	return ids
end

function Pets.count()
	local n = 0
	for _ in pairs(defs) do
		n += 1
	end
	return n
end

return Pets
