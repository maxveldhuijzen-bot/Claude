--[[
	ProfileTemplate — the shape of a save file.

	Anything added here is backfilled onto existing saves by TableUtil.reconcile
	on load, so shipping a new feature does not require a migration for missing
	keys. `version` exists for changes that reconcile cannot express (renames,
	rescales); handle those in ProfileTemplate.migrate.
]]

local ProfileTemplate = {}

ProfileTemplate.VERSION = 1

function ProfileTemplate.new()
	local now = os.time()
	return {
		version = ProfileTemplate.VERSION,

		-- Currencies
		coins = 0,
		aura = 0,
		prisms = 0,

		-- Progression
		collectorIndex = 1,
		backpackIndex = 1,
		rebirths = 0,
		zone = "meadow",
		zones = { meadow = true },

		-- Collection
		pets = {}, -- { { uid, id, tier, equipped } }
		petUid = 0,
		index = {}, -- [petId] = times hatched, drives the pet index UI

		-- Prism spending
		upgrades = {}, -- [upgradeId] = level
		auras = { none = true },
		auraEquipped = "none",

		-- Live effects
		boosts = {}, -- { { id, name, auraMult, luckMult, endsAt } }

		-- Reward tracking
		quests = { rerollAt = 0, active = {} },
		daily = { lastClaim = 0, streak = 0 },
		playtime = { session = 0, claimed = {} },
		codes = {},
		receipts = {}, -- [purchaseId] = true, guards against double grants

		-- Client preferences, round-tripped so they follow the player
		prefs = { music = true, sfx = true, autoEquip = true, lowGraphics = false },

		stats = {
			totalAura = 0,
			totalCoins = 0,
			nodes = 0,
			hatches = 0,
			sells = 0,
			fuses = 0,
			joins = 0,
			playtime = 0,
		},

		firstJoin = now,
		lastSeen = now,
	}
end

--- Applied before reconcile. Return the (possibly rewritten) profile.
function ProfileTemplate.migrate(profile)
	if type(profile) ~= "table" then
		return ProfileTemplate.new()
	end

	profile.version = profile.version or 0

	-- Example of the pattern for future versions:
	-- if profile.version < 2 then
	--     profile.prisms = math.floor((profile.prisms or 0) * 1.5)
	--     profile.version = 2
	-- end

	profile.version = ProfileTemplate.VERSION
	return profile
end

return ProfileTemplate
