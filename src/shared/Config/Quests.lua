--[[
	Quests — three rotating dailies.

	Goals scale off the best zone the player has unlocked rather than off a
	rebirth count, so a quest is always sized to what the player is currently
	farming. `scaled = true` rewards do the same.
]]

local Quests = {}

Quests.definitions = {
	{
		id = "farm_aura",
		type = "collect",
		text = "Farm %s aura",
		baseGoal = 40000,
		scaled = true,
		reward = { kind = "coins", amount = 9000, scaled = true },
	},
	{
		id = "sell_aura",
		type = "sell",
		text = "Sell %s aura at a vault",
		baseGoal = 90000,
		scaled = true,
		reward = { kind = "coins", amount = 16000, scaled = true },
	},
	{
		id = "shatter_nodes",
		type = "nodes",
		text = "Shatter %s aura nodes",
		baseGoal = 60,
		scaled = false,
		reward = { kind = "coins", amount = 12000, scaled = true },
	},
	{
		id = "shatter_nodes_big",
		type = "nodes",
		text = "Shatter %s aura nodes",
		baseGoal = 200,
		scaled = false,
		reward = { kind = "boost", boostId = "quest_2x", amount = 1 },
	},
	{
		id = "hatch_eggs",
		type = "hatch",
		text = "Hatch %s eggs",
		baseGoal = 15,
		scaled = false,
		reward = { kind = "coins", amount = 20000, scaled = true },
	},
	{
		id = "hatch_eggs_big",
		type = "hatch",
		text = "Hatch %s eggs",
		baseGoal = 40,
		scaled = false,
		reward = { kind = "prisms", amount = 2 },
	},
	{
		id = "do_rebirth",
		type = "rebirth",
		text = "Rebirth %s time(s)",
		baseGoal = 1,
		scaled = false,
		reward = { kind = "prisms", amount = 3 },
	},
	{
		id = "fuse_pets",
		type = "fuse",
		text = "Fuse %s pets into a higher tier",
		baseGoal = 2,
		scaled = false,
		reward = { kind = "prisms", amount = 2 },
	},
}

--- Boosts a quest can hand out. Duration is in seconds.
Quests.boosts = {
	quest_2x = { id = "quest_2x", name = "Quest Rush", auraMult = 2, duration = 900 },
}

local byId = {}
for _, definition in ipairs(Quests.definitions) do
	byId[definition.id] = definition
end

function Quests.get(id)
	return byId[id]
end

--- Rounds a scaled goal to something that reads well on the HUD.
function Quests.roundGoal(value)
	if value < 100 then
		return math.max(1, math.floor(value))
	end
	local magnitude = 10 ^ math.floor(math.log10(value) - 1)
	return math.floor(value / magnitude) * magnitude
end

--- Daily login ladder. Day 7 loops back to day 1 with the streak preserved.
Quests.daily = {
	{ day = 1, coinsAsRebirthFraction = 0.10 },
	{ day = 2, coinsAsRebirthFraction = 0.16 },
	{ day = 3, prisms = 2 },
	{ day = 4, coinsAsRebirthFraction = 0.30 },
	{ day = 5, boost = { id = "daily_2x", name = "x2 Aura", auraMult = 2, duration = 1800 } },
	{ day = 6, coinsAsRebirthFraction = 0.55 },
	{ day = 7, prisms = 6, boost = { id = "daily_luck", name = "x2 Luck", luckMult = 2, duration = 1800 } },
}

--- Session playtime ladder, paired index-for-index with Settings.PlaytimeRewards.
Quests.playtime = {
	{ coinsAsRebirthFraction = 0.08 },
	{ coinsAsRebirthFraction = 0.15 },
	{ prisms = 1 },
	{ boost = { id = "playtime_2x", name = "x2 Aura", auraMult = 2, duration = 900 } },
	{ prisms = 3, coinsAsRebirthFraction = 0.5 },
}

return Quests
