--[[
	Settings — every global tuning knob in one file.
	Balance passes should start and end here.
]]

return {
	GameName = "Aura Farm Simulator",

	-- Persistence -----------------------------------------------------------
	DataStoreName = "AuraFarm_Profile_v1",
	OrderedStoreRebirths = "AuraFarm_LB_Rebirths_v1",
	OrderedStoreAura = "AuraFarm_LB_Aura_v1",
	AutosaveInterval = 120,
	SaveRetries = 4,
	SessionLockStale = 900, -- a lock older than this is assumed dead
	StudioSaveEnabled = false, -- keep Studio playtests out of live data

	-- Farming ---------------------------------------------------------------
	CollectRange = 30, -- studs; server rejects swings past this (+ tolerance)
	CollectRangeTolerance = 14, -- lag/ping slack before a swing is refused
	CollectInterval = 0.28, -- seconds between accepted swings
	CollectBurst = 3, -- swings allowed before the interval throttles
	NodeRespawn = 6, -- seconds a shattered node stays down
	NodeBreakBonus = 4, -- shattering pays this many swings' worth
	SellRadius = 18, -- studs from a vault pad to auto-sell

	-- Progression -----------------------------------------------------------
	BasePetSlots = 3,
	MaxPetSlots = 12,
	MaxPetsOwned = 250,
	FuseCount = 5, -- identical pets needed to upgrade a tier
	TierMultipliers = { [1] = 1, [2] = 2.5, [3] = 7 }, -- normal, golden, rainbow
	RebirthAuraBonus = 0.35, -- +35% aura per rebirth
	BaseWalkSpeed = 20,
	BaseJumpPower = 52,

	-- Rewards ---------------------------------------------------------------
	PlaytimeRewards = { 5, 10, 20, 35, 60 }, -- minutes
	DailyResetSeconds = 20 * 60 * 60, -- claimable again after 20h
	DailyStreakExpiry = 48 * 60 * 60, -- streak breaks after 48h away
	QuestCount = 3,
	QuestRerollSeconds = 24 * 60 * 60,

	-- Replication -----------------------------------------------------------
	HotStateHz = 10, -- currency/power pushes per second
	ProfileStateHz = 2, -- inventory pushes per second
	LeaderboardRefresh = 90,

	-- Anti-abuse ------------------------------------------------------------
	ActionRateWindow = 1,
	ActionRateLimit = 14, -- menu actions per second per player
	MaxTeleportsPerMinute = 20,

	-- World -----------------------------------------------------------------
	ZoneSpacing = 340,
	PlatformSize = 240,
	VoidFloor = -120, -- fall below this and you are sent back to your zone
}
