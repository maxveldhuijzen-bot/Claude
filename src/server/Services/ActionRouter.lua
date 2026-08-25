--[[
	ActionRouter — the single client-to-server entry point for menu actions.

	Every request goes through one RemoteFunction, so rate limiting, payload
	validation and error handling live in exactly one place. Handlers return
	(ok, resultOrMessage); anything that throws is caught here and reported to
	the player as a generic failure rather than hanging their UI.
]]

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Settings = require(Shared.Config.Settings)
local Net = require(Shared.Modules.Net)

local ActionRouter = {}
local Services

local buckets = {}

local function allowed(player)
	local now = os.clock()
	local bucket = buckets[player]

	if not bucket then
		bucket = { tokens = Settings.ActionRateLimit, at = now }
		buckets[player] = bucket
	end

	local refill = (now - bucket.at) * (Settings.ActionRateLimit / Settings.ActionRateWindow)
	bucket.tokens = math.min(Settings.ActionRateLimit, bucket.tokens + refill)
	bucket.at = now

	if bucket.tokens < 1 then
		return false
	end

	bucket.tokens -= 1
	return true
end

local function buildHandlers()
	return {
		buyCollector = function(player, payload)
			return Services.ShopService.buyCollector(player, payload)
		end,
		buyBackpack = function(player, payload)
			return Services.ShopService.buyBackpack(player, payload)
		end,

		unlockZone = function(player, payload)
			return Services.ZoneService.unlock(player, payload and payload.zone)
		end,
		teleport = function(player, payload)
			return Services.ZoneService.sendToZone(player, payload and payload.zone)
		end,

		hatch = function(player, payload)
			return Services.EggService.hatch(player, payload)
		end,

		equipPet = function(player, payload)
			return Services.PetService.equip(player, payload)
		end,
		unequipPet = function(player, payload)
			return Services.PetService.unequip(player, payload)
		end,
		equipBest = function(player)
			return Services.PetService.equipBest(player)
		end,
		unequipAll = function(player)
			return Services.PetService.unequipAll(player)
		end,
		deletePet = function(player, payload)
			return Services.PetService.delete(player, payload)
		end,
		deleteWeak = function(player)
			return Services.PetService.deleteWeak(player)
		end,
		fusePet = function(player, payload)
			return Services.PetService.fuse(player, payload)
		end,

		rebirth = function(player)
			return Services.RebirthService.rebirth(player)
		end,
		buyUpgrade = function(player, payload)
			return Services.RebirthService.buyUpgrade(player, payload)
		end,
		buyAura = function(player, payload)
			return Services.RebirthService.buyAura(player, payload)
		end,
		equipAura = function(player, payload)
			return Services.RebirthService.equipAura(player, payload)
		end,

		claimQuest = function(player, payload)
			return Services.QuestService.claim(player, payload)
		end,
		claimDaily = function(player)
			return Services.QuestService.claimDaily(player)
		end,
		claimPlaytime = function(player, payload)
			return Services.QuestService.claimPlaytime(player, payload)
		end,
		redeemCode = function(player, payload)
			return Services.QuestService.redeem(player, payload)
		end,

		catalog = function(player)
			return Services.MonetizationService.catalog(player)
		end,

		dailyState = function(player)
			local profile = Services.DataService.get(player)
			if not profile then
				return false, "Still loading."
			end
			return true, Services.QuestService.dailyState(profile)
		end,

		setPref = function(player, payload)
			local profile = Services.DataService.get(player)
			if not profile then
				return false, "Still loading."
			end

			local key = payload and payload.key
			local value = payload and payload.value

			if profile.prefs[key] == nil or type(value) ~= "boolean" then
				return false, "Unknown setting."
			end

			profile.prefs[key] = value
			Services.Replicator.markProfile(player)
			return true, { key = key, value = value }
		end,

		resync = function(player)
			Services.Replicator.pushNow(player)
			return true, {}
		end,
	}
end

function ActionRouter.init(services)
	Services = services

	local handlers = buildHandlers()

	Players.PlayerRemoving:Connect(function(player)
		buckets[player] = nil
	end)

	Net.onInvoke("Action", function(player, action, payload)
		if type(action) ~= "string" then
			return false, "Malformed request."
		end

		if payload ~= nil and type(payload) ~= "table" then
			return false, "Malformed request."
		end

		local handler = handlers[action]
		if not handler then
			return false, "Unknown action."
		end

		if not allowed(player) then
			return false, "You are going too fast."
		end

		local ok, result, message = pcall(handler, player, payload)
		if not ok then
			warn(string.format("[ActionRouter] %s failed for %s: %s", action, player.Name, tostring(result)))
			return false, "Something went wrong."
		end

		if result == false then
			return false, message or "Not allowed."
		end

		return true, message or {}
	end)
end

return ActionRouter
