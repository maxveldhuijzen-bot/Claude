--[[
	Backpacks — carry capacity tiers.

	`capacity` is the base figure at a x1 multiplier; StatService scales it by
	the player's aura multiplier and zone multiplier, exactly as it scales aura
	per swing. That makes time-to-fill depend only on capacity divided by
	collector power, so these numbers are tuned as "roughly 150 swings' worth of
	the matching collector tier" — which lands between 30 and 150 actual swings
	once node-shatter bonuses are counted.
]]

return {
	{ name = "Pocket", capacity = 150, cost = 0 },
	{ name = "Satchel", capacity = 600, cost = 160 },
	{ name = "Field Pack", capacity = 2100, cost = 1500 },
	{ name = "Duffel", capacity = 6800, cost = 13000 },
	{ name = "Reinforced Crate", capacity = 25000, cost = 110000 },
	{ name = "Vault Pack", capacity = 92000, cost = 850000 },
	{ name = "Frost Container", capacity = 345000, cost = 7000000 },
	{ name = "Ember Hauler", capacity = 1350000, cost = 55000000 },
	{ name = "Void Pouch", capacity = 5400000, cost = 440000000 },
	{ name = "Star Cache", capacity = 22500000, cost = 3600000000 },
	{ name = "Celestial Hold", capacity = 96000000, cost = 28000000000 },
	{ name = "Mythic Reliquary", capacity = 420000000, cost = 220000000000 },
	{ name = "Singularity Well", capacity = 1800000000, cost = 1800000000000 },
	{ name = "Infinity Locker", capacity = 8300000000, cost = 14000000000000 },
}
