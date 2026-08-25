--[[
	RebirthService — the reset loop and the prism shop.

	Rebirthing clears coins, carried aura and the two tier ladders. It keeps
	pets, prisms, upgrades, cosmetics and unlocked zones, so run two is
	dramatically faster than run one — which is the entire point.
]]

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Rebirth = require(Shared.Config.Rebirth)
local Format = require(Shared.Modules.Format)

local RebirthService = {}
local Services

function RebirthService.init(services)
	Services = services
end

function RebirthService.rebirth(player)
	local profile = Services.DataService.get(player)
	if not profile then
		return false, "Still loading."
	end

	local cost = Rebirth.cost(profile.rebirths)
	if profile.coins < cost then
		return false, "Need " .. Format.abbreviate(cost - profile.coins) .. " more coins."
	end

	local reward = Rebirth.prismReward(profile.rebirths)

	profile.coins = 0
	profile.aura = 0
	profile.collectorIndex = 1
	profile.backpackIndex = 1
	profile.rebirths += 1
	profile.prisms += reward

	Services.QuestService.progress(player, "rebirth", 1)
	Services.StatService.applyCharacter(player)
	Services.Replicator.pushNow(player)

	Services.Notify.send(player, {
		title = "Rebirth " .. profile.rebirths,
		body = string.format("+%d prisms, and +%d%% aura forever.", reward, math.floor(profile.rebirths * 35)),
		kind = "premium",
		duration = 6,
	})
	Services.Notify.effect(player, { kind = "rebirth", rebirths = profile.rebirths, prisms = reward })

	if profile.rebirths % 10 == 0 then
		Services.Notify.broadcast({
			title = player.DisplayName .. " hit rebirth " .. profile.rebirths,
			kind = "premium",
		})
	end

	Services.LeaderboardService.submit(player, profile)
	Services.DataService.save(player)

	return true, { rebirths = profile.rebirths, prisms = reward }
end

function RebirthService.buyUpgrade(player, payload)
	local profile = Services.DataService.get(player)
	if not profile then
		return false, "Still loading."
	end

	local upgrade = Rebirth.getUpgrade(payload and payload.id)
	if not upgrade then
		return false, "Unknown upgrade."
	end

	local level = profile.upgrades[upgrade.id] or 0
	if level >= upgrade.maxLevel then
		return false, upgrade.name .. " is maxed."
	end

	local cost = Rebirth.upgradeCost(upgrade, level)
	if profile.prisms < cost then
		return false, string.format("Need %d more prisms.", cost - profile.prisms)
	end

	profile.prisms -= cost
	profile.upgrades[upgrade.id] = level + 1

	Services.StatService.applyCharacter(player)
	Services.Replicator.markProfile(player)

	Services.Notify.send(player, {
		title = upgrade.name .. " " .. (level + 1),
		body = upgrade.desc,
		kind = "good",
	})

	return true, { id = upgrade.id, level = level + 1 }
end

function RebirthService.buyAura(player, payload)
	local profile = Services.DataService.get(player)
	if not profile then
		return false, "Still loading."
	end

	local aura = Rebirth.getAura(payload and payload.id)
	if not aura or aura.id == "none" then
		return false, "Unknown cosmetic."
	end

	if profile.auras[aura.id] then
		return false, "Already owned."
	end

	if profile.prisms < aura.cost then
		return false, string.format("Need %d more prisms.", aura.cost - profile.prisms)
	end

	profile.prisms -= aura.cost
	profile.auras[aura.id] = true
	profile.auraEquipped = aura.id

	Services.Replicator.markProfile(player)
	Services.Notify.send(player, { title = aura.name .. " unlocked", kind = "premium" })

	return true, { id = aura.id }
end

function RebirthService.equipAura(player, payload)
	local profile = Services.DataService.get(player)
	if not profile then
		return false, "Still loading."
	end

	local id = payload and payload.id
	if id ~= "none" and not profile.auras[id] then
		return false, "You do not own that."
	end

	profile.auraEquipped = id
	Services.Replicator.markProfile(player)
	return true, { id = id }
end

return RebirthService
