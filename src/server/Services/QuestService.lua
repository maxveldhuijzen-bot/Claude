--[[
	QuestService — dailies, the login ladder, session playtime and codes.

	Quest goals scale off the best zone the player has unlocked rather than off
	a fixed table, so "farm 40k aura" becomes "farm 800M aura" naturally as they
	progress, and never becomes trivial or impossible.
]]

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Settings = require(Shared.Config.Settings)
local Quests = require(Shared.Config.Quests)
local Zones = require(Shared.Config.Zones)
local Codes = require(Shared.Config.Codes)
local Format = require(Shared.Modules.Format)

local QuestService = {}
local Services

function QuestService.init(services)
	Services = services

	Services.DataService.loaded:Connect(function(player, profile)
		QuestService.ensure(player, profile)
	end)
end

local function scaleFor(profile)
	return Zones.best(profile.zones).auraMult
end

local function buildQuest(profile, definition)
	local scale = scaleFor(profile)
	local goal = definition.baseGoal
	if definition.scaled then
		goal = Quests.roundGoal(definition.baseGoal * scale)
	end

	local reward = table.clone(definition.reward)
	if reward.scaled and reward.kind == "coins" then
		reward = { kind = "coins", amount = math.floor(definition.reward.amount * scale) }
	end

	return {
		id = definition.id,
		type = definition.type,
		text = definition.text,
		goal = goal,
		progress = 0,
		claimed = false,
		reward = reward,
	}
end

--- Rebuilds the quest list when the rotation has expired or is empty.
function QuestService.ensure(player, profile)
	profile = profile or Services.DataService.get(player)
	if not profile then
		return
	end

	local now = os.time()
	if #profile.quests.active > 0 and now < profile.quests.rerollAt then
		return
	end

	local pool = table.clone(Quests.definitions)
	for index = #pool, 2, -1 do
		local swap = math.random(1, index)
		pool[index], pool[swap] = pool[swap], pool[index]
	end

	local active = {}
	local usedTypes = {}

	for _, definition in ipairs(pool) do
		if #active >= Settings.QuestCount then
			break
		end
		-- One quest per type keeps the list from being three "hatch eggs".
		if not usedTypes[definition.type] then
			usedTypes[definition.type] = true
			table.insert(active, buildQuest(profile, definition))
		end
	end

	profile.quests.active = active
	profile.quests.rerollAt = now + Settings.QuestRerollSeconds

	Services.Replicator.markProfile(player)
end

--- Called by gameplay services whenever something quest-worthy happens.
function QuestService.progress(player, questType, amount)
	local profile = Services.DataService.get(player)
	if not profile or amount <= 0 then
		return
	end

	local changed = false
	for _, quest in ipairs(profile.quests.active) do
		if quest.type == questType and not quest.claimed and quest.progress < quest.goal then
			quest.progress = math.min(quest.goal, quest.progress + amount)
			changed = true
		end
	end

	if changed then
		Services.Replicator.markProfile(player)
	end
end

function QuestService.claim(player, payload)
	local profile = Services.DataService.get(player)
	if not profile then
		return false, "Still loading."
	end

	local index = tonumber(payload and payload.index)
	local quest = index and profile.quests.active[index]
	if not quest then
		return false, "Unknown quest."
	end

	if quest.claimed then
		return false, "Already claimed."
	end

	if quest.progress < quest.goal then
		return false, "Not finished yet."
	end

	quest.claimed = true

	local reward = {}
	if quest.reward.kind == "coins" then
		reward.coins = quest.reward.amount
	elseif quest.reward.kind == "prisms" then
		reward.prisms = quest.reward.amount
	elseif quest.reward.kind == "boost" then
		reward.boost = Quests.boosts[quest.reward.boostId]
	end

	Services.RewardService.grant(player, reward)
	Services.Notify.send(player, {
		title = "Quest complete",
		body = Services.RewardService.describe(profile, reward),
		kind = "good",
	})

	return true, { index = index }
end

-- Daily login ---------------------------------------------------------------

function QuestService.dailyState(profile)
	local now = os.time()
	local elapsed = now - (profile.daily.lastClaim or 0)
	local streak = profile.daily.streak or 0

	if elapsed > Settings.DailyStreakExpiry then
		streak = 0
	end

	return {
		streak = streak,
		canClaim = elapsed >= Settings.DailyResetSeconds,
		nextIn = math.max(0, Settings.DailyResetSeconds - elapsed),
		day = (streak % #Quests.daily) + 1,
	}
end

function QuestService.claimDaily(player)
	local profile = Services.DataService.get(player)
	if not profile then
		return false, "Still loading."
	end

	local state = QuestService.dailyState(profile)
	if not state.canClaim then
		return false, "Come back in " .. Format.duration(state.nextIn) .. "."
	end

	local reward = Quests.daily[state.day]
	profile.daily.streak = state.streak + 1
	profile.daily.lastClaim = os.time()

	Services.RewardService.grant(player, reward)
	Services.Notify.send(player, {
		title = "Day " .. state.day .. " claimed",
		body = Services.RewardService.describe(profile, reward),
		kind = "premium",
	})

	return true, { day = state.day, streak = profile.daily.streak }
end

-- Session playtime ----------------------------------------------------------

function QuestService.claimPlaytime(player, payload)
	local profile = Services.DataService.get(player)
	if not profile then
		return false, "Still loading."
	end

	local index = tonumber(payload and payload.index)
	local minutes = index and Settings.PlaytimeRewards[index]
	if not minutes then
		return false, "Unknown reward."
	end

	if table.find(profile.playtime.claimed, index) then
		return false, "Already claimed this session."
	end

	if profile.playtime.session < minutes * 60 then
		local remaining = minutes * 60 - profile.playtime.session
		return false, Format.duration(remaining) .. " to go."
	end

	table.insert(profile.playtime.claimed, index)

	local reward = Quests.playtime[index] or {}
	Services.RewardService.grant(player, reward)
	Services.Notify.send(player, {
		title = minutes .. " minute reward",
		body = Services.RewardService.describe(profile, reward),
		kind = "good",
	})

	return true, { index = index }
end

-- Codes ----------------------------------------------------------------------

function QuestService.redeem(player, payload)
	local profile = Services.DataService.get(player)
	if not profile then
		return false, "Still loading."
	end

	local raw = payload and payload.code
	if type(raw) ~= "string" or #raw == 0 or #raw > 32 then
		return false, "Enter a code."
	end

	local code = raw:upper():gsub("%s", "")
	local entry = Codes[code]

	if not entry then
		return false, "That code is not valid."
	end

	if not entry.active then
		return false, "That code has expired."
	end

	if profile.codes[code] then
		return false, "You already used that code."
	end

	profile.codes[code] = true
	Services.RewardService.grant(player, entry.reward)

	Services.Notify.send(player, {
		title = "Code redeemed",
		body = Services.RewardService.describe(profile, entry.reward),
		kind = "premium",
	})

	return true, { code = code }
end

function QuestService.start()
	while true do
		task.wait(1)
		for _, player in ipairs(Players:GetPlayers()) do
			local profile = Services.DataService.get(player)
			if profile then
				profile.playtime.session += 1
				profile.stats.playtime += 1
			end
		end
	end
end

return QuestService
