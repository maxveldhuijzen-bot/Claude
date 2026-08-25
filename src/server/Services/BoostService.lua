--[[
	BoostService — temporary multipliers from products, codes and quests.

	Boosts are stored on the profile so they survive a rejoin, and are keyed by
	id: buying a second x2 potion extends the first rather than stacking two
	separate two-times multipliers.
]]

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Format = require(Shared.Modules.Format)

local BoostService = {}
local Services

function BoostService.init(services)
	Services = services
end

--- Adds or extends a boost. `definition` needs id, duration and a multiplier.
function BoostService.grant(player, definition)
	local profile = Services.DataService.get(player)
	if not profile or not definition or not definition.id then
		return false
	end

	local now = os.time()
	local endsAt = now + (definition.duration or 0)

	for _, boost in ipairs(profile.boosts) do
		if boost.id == definition.id then
			-- Extend from whichever is later: now, or the existing expiry.
			boost.endsAt = math.max(boost.endsAt, now) + (definition.duration or 0)
			Services.Replicator.markHot(player)
			return true, boost
		end
	end

	local boost = {
		id = definition.id,
		name = definition.name or definition.id,
		auraMult = definition.auraMult,
		luckMult = definition.luckMult,
		endsAt = endsAt,
	}
	table.insert(profile.boosts, boost)

	Services.Replicator.markHot(player)
	Services.Notify.send(player, {
		title = boost.name .. " active",
		body = "Runs for " .. Format.duration(definition.duration or 0) .. ".",
		kind = "good",
	})

	return true, boost
end

--- Combined aura and luck multipliers from every live boost.
function BoostService.multipliers(profile)
	local aura, luck = 1, 1
	local now = os.time()

	for _, boost in ipairs(profile.boosts) do
		if boost.endsAt > now then
			aura *= boost.auraMult or 1
			luck *= boost.luckMult or 1
		end
	end

	return aura, luck
end

--- Drops expired rows. Returns true when anything was removed.
function BoostService.prune(profile)
	local now = os.time()
	local removed = false

	for index = #profile.boosts, 1, -1 do
		if profile.boosts[index].endsAt <= now then
			table.remove(profile.boosts, index)
			removed = true
		end
	end

	return removed
end

function BoostService.start()
	while true do
		task.wait(1)
		for player, profile in pairs(Services.DataService.all()) do
			if BoostService.prune(profile) then
				Services.Replicator.markHot(player)
			end
		end
	end
end

return BoostService
