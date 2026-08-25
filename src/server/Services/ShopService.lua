--[[ ShopService — collector and backpack tiers. ]]

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Collectors = require(Shared.Config.Collectors)
local Backpacks = require(Shared.Config.Backpacks)
local Format = require(Shared.Modules.Format)

local ShopService = {}
local Services

function ShopService.init(services)
	Services = services
end

--- Shared logic for the two tier ladders. Players may skip ahead to any tier
--- they can actually afford, which keeps a big coin windfall satisfying.
local function buyTier(player, list, currentKey, index, label, onBought)
	local profile = Services.DataService.get(player)
	if not profile then
		return false, "Still loading."
	end

	index = tonumber(index)
	if not index or index % 1 ~= 0 or not list[index] then
		return false, "Unknown " .. label .. "."
	end

	if index <= profile[currentKey] then
		return false, "You already own that " .. label .. "."
	end

	local entry = list[index]
	if profile.coins < entry.cost then
		return false, "Need " .. Format.abbreviate(entry.cost - profile.coins) .. " more coins."
	end

	profile.coins -= entry.cost
	profile[currentKey] = index

	Services.Replicator.markProfile(player)
	Services.Notify.send(player, {
		title = entry.name .. " equipped",
		body = onBought(entry),
		kind = "good",
	})
	Services.Notify.effect(player, { kind = "upgrade", label = entry.name })

	return true, { index = index }
end

function ShopService.buyCollector(player, payload)
	return buyTier(player, Collectors, "collectorIndex", payload and payload.index, "collector", function(entry)
		return Format.abbreviate(entry.power) .. " base aura per swing."
	end)
end

function ShopService.buyBackpack(player, payload)
	return buyTier(player, Backpacks, "backpackIndex", payload and payload.index, "backpack", function(entry)
		return "Carries " .. Format.abbreviate(entry.capacity) .. " aura."
	end)
end

return ShopService
