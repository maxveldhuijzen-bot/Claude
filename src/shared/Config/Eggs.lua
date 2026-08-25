--[[
	Eggs — hatch pools.

	Weights are relative, not percentages: the odds UI derives real percentages
	from them (and from the player's luck) at display time, so tuning a pool is
	just editing a number here.
]]

local W = {
	Common = 1000,
	Uncommon = 300,
	Rare = 90,
	Epic = 20,
	Legendary = 4,
	Mythic = 0.6,
	Secret = 0.04,
}

local Eggs = {
	{
		id = "meadow",
		name = "Meadow Egg",
		zone = "meadow",
		cost = 150,
		hatchTime = 1.6,
		color = Color3.fromRGB(255, 236, 180),
		pool = {
			pebble_sprite = W.Common,
			meadow_bunny = W.Common * 0.8,
			sun_moth = W.Uncommon,
			dawn_fox = W.Rare,
			gilded_ladybug = W.Epic,
			sunrise_phoenix = W.Legendary,
		},
	},
	{
		id = "grove",
		name = "Neon Egg",
		zone = "grove",
		cost = 4000,
		hatchTime = 1.7,
		color = Color3.fromRGB(120, 255, 214),
		pool = {
			neon_slime = W.Common,
			circuit_mouse = W.Common * 0.8,
			glow_beetle = W.Uncommon,
			laser_lynx = W.Rare,
			hologram_wolf = W.Epic,
			neon_dragon = W.Legendary,
			prism_overlord = W.Mythic,
		},
	},
	{
		id = "frost",
		name = "Frost Egg",
		zone = "frost",
		cost = 95000,
		hatchTime = 1.8,
		color = Color3.fromRGB(190, 230, 255),
		pool = {
			snow_pup = W.Common,
			icicle_crab = W.Common * 0.8,
			frost_owl = W.Uncommon,
			glacier_bear = W.Rare,
			aurora_stag = W.Epic,
			blizzard_wyrm = W.Legendary,
			absolute_zero = W.Mythic,
		},
	},
	{
		id = "ember",
		name = "Ember Egg",
		zone = "ember",
		cost = 1700000,
		hatchTime = 1.9,
		color = Color3.fromRGB(255, 150, 80),
		pool = {
			cinder_imp = W.Common,
			ash_hound = W.Common * 0.8,
			magma_slug = W.Uncommon,
			ember_drake = W.Rare,
			inferno_titan = W.Epic,
			solar_phoenix = W.Legendary,
			heat_death = W.Mythic,
		},
	},
	{
		id = "void",
		name = "Void Egg",
		zone = "void",
		cost = 34000000,
		hatchTime = 2.0,
		color = Color3.fromRGB(168, 110, 255),
		pool = {
			void_wisp = W.Common,
			null_crawler = W.Common * 0.8,
			shadow_serpent = W.Uncommon,
			eclipse_panther = W.Rare,
			void_leviathan = W.Epic,
			entropy_warden = W.Legendary,
			event_horizon = W.Secret,
		},
	},
	{
		id = "reef",
		name = "Celestial Egg",
		zone = "reef",
		cost = 750000000,
		hatchTime = 2.1,
		color = Color3.fromRGB(130, 226, 255),
		pool = {
			star_kitten = W.Common,
			comet_hare = W.Common * 0.8,
			nebula_ray = W.Uncommon,
			galaxy_guardian = W.Rare,
			quasar_djinn = W.Epic,
			astral_sovereign = W.Legendary,
			big_bang = W.Secret,
		},
	},
	{
		id = "spire",
		name = "Mythic Egg",
		zone = "spire",
		cost = 13000000000,
		hatchTime = 2.2,
		color = Color3.fromRGB(255, 190, 120),
		pool = {
			rune_golem = W.Common,
			myth_serpent = W.Common * 0.8,
			oracle_sphinx = W.Uncommon,
			titan_of_ages = W.Rare,
			worldtree_drake = W.Epic,
			mythic_ascendant = W.Legendary,
			the_author = W.Mythic,
		},
	},
	{
		id = "singularity",
		name = "Singularity Egg",
		zone = "singularity",
		cost = 220000000000,
		hatchTime = 2.4,
		color = Color3.fromRGB(255, 120, 190),
		pool = {
			quark_pup = W.Common,
			tachyon_moth = W.Common * 0.8,
			gravity_wraith = W.Uncommon,
			horizon_stalker = W.Rare,
			infinity_hydra = W.Epic,
			omega_sovereign = W.Legendary,
			the_singularity = W.Secret,
		},
	},
}

--- Batch sizes offered on the hatch UI. Cost is linear; the appeal is time.
Eggs.batchSizes = { 1, 3, 8 }

local byId = {}
for _, egg in ipairs(Eggs) do
	byId[egg.id] = egg
end

function Eggs.get(id)
	return byId[id]
end

return Eggs
