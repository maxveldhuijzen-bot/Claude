--[[
	Replicator — the only thing that pushes state to clients.

	Two channels at different rates, because they have different costs:
	  hot     currencies and multipliers; small, changes constantly, 10 Hz cap
	  profile inventory, quests, upgrades; large, changes rarely, 2 Hz cap

	Services call markHot / markProfile after mutating a profile and never
	build payloads themselves.
]]

local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Settings = require(Shared.Config.Settings)
local Net = require(Shared.Modules.Net)

local Replicator = {}
local Services

local hotDirty = {}
local profileDirty = {}
local lastHot = {}
local lastProfile = {}

function Replicator.init(services)
	Services = services
end

function Replicator.markHot(player)
	hotDirty[player] = true
end

function Replicator.markProfile(player)
	profileDirty[player] = true
	hotDirty[player] = true -- inventory changes almost always move a multiplier
end

function Replicator.markAll(player)
	Replicator.markProfile(player)
end

function Replicator.forget(player)
	hotDirty[player] = nil
	profileDirty[player] = nil
	lastHot[player] = nil
	lastProfile[player] = nil
end

local function hotSnapshot(player, profile)
	local stats = Services.StatService.compute(player, profile)
	if not stats then
		return nil
	end

	local boosts = {}
	local now = os.time()
	for _, boost in ipairs(profile.boosts) do
		if boost.endsAt > now then
			table.insert(boosts, {
				id = boost.id,
				name = boost.name,
				endsAt = boost.endsAt,
				auraMult = boost.auraMult,
				luckMult = boost.luckMult,
			})
		end
	end

	return {
		aura = profile.aura,
		coins = profile.coins,
		prisms = profile.prisms,
		rebirths = profile.rebirths,
		zone = profile.zone,

		power = stats.power,
		capacity = stats.capacity,
		auraPerSwing = stats.auraPerSwing,
		auraMult = stats.auraMult,
		petMult = stats.petMult,
		luck = stats.luck,
		sellMult = stats.sellMult,
		zoneMult = stats.zoneMult,
		petSlots = stats.petSlots,
		equippedPets = stats.equippedPets,
		collectorName = stats.collectorName,
		backpackName = stats.backpackName,
		collectRange = stats.collectRange,
		autoCollect = stats.autoCollect,
		rebirthCost = stats.rebirthCost,
		rebirthReward = stats.rebirthReward,

		boosts = boosts,
		serverTime = now,
	}
end

--- Equipped pets and cosmetics are published as Player attributes so *other*
--- clients can render them. Profile data itself stays private to its owner.
local function updatePublicState(player, profile)
	local encoded = {}
	for _, pet in ipairs(profile.pets) do
		if pet.equipped then
			table.insert(encoded, pet.id .. ":" .. pet.tier)
		end
	end

	player:SetAttribute("EquippedPets", table.concat(encoded, ","))
	player:SetAttribute("AuraTrail", profile.auraEquipped)
	player:SetAttribute("Rebirths", profile.rebirths)
	player:SetAttribute("Collector", profile.collectorIndex)
end

local function profileSnapshot(player, profile)
	return {
		pets = profile.pets,
		index = profile.index,
		upgrades = profile.upgrades,
		auras = profile.auras,
		auraEquipped = profile.auraEquipped,
		zones = profile.zones,
		collectorIndex = profile.collectorIndex,
		backpackIndex = profile.backpackIndex,
		quests = profile.quests,
		daily = profile.daily,
		playtime = profile.playtime,
		codes = profile.codes,
		prefs = profile.prefs,
		stats = profile.stats,
		passes = Services.MonetizationService.passes(player),
	}
end

--- Immediate, unthrottled push. Used on join and after a rebirth.
function Replicator.pushNow(player)
	local profile = Services.DataService.get(player)
	if not profile then
		return
	end

	local hot = hotSnapshot(player, profile)
	if hot then
		Net.toClient("State", player, hot)
		lastHot[player] = os.clock()
	end

	updatePublicState(player, profile)
	Net.toClient("Profile", player, profileSnapshot(player, profile))
	lastProfile[player] = os.clock()

	hotDirty[player] = nil
	profileDirty[player] = nil
end

function Replicator.start()
	local hotPeriod = 1 / Settings.HotStateHz
	local profilePeriod = 1 / Settings.ProfileStateHz

	RunService.Heartbeat:Connect(function()
		local now = os.clock()

		for player in pairs(hotDirty) do
			if player.Parent and now - (lastHot[player] or 0) >= hotPeriod then
				local profile = Services.DataService.get(player)
				if profile then
					local snapshot = hotSnapshot(player, profile)
					if snapshot then
						Net.toClient("State", player, snapshot)
					end
				end
				lastHot[player] = now
				hotDirty[player] = nil
			elseif not player.Parent then
				Replicator.forget(player)
			end
		end

		for player in pairs(profileDirty) do
			if player.Parent and now - (lastProfile[player] or 0) >= profilePeriod then
				local profile = Services.DataService.get(player)
				if profile then
					updatePublicState(player, profile)
					Net.toClient("Profile", player, profileSnapshot(player, profile))
				end
				lastProfile[player] = now
				profileDirty[player] = nil
			elseif not player.Parent then
				Replicator.forget(player)
			end
		end
	end)
end

return Replicator
