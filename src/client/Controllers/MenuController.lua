--[[
	MenuController — owns every menu window and decides when to redraw one.

	Windows are built once at startup and re-rendered on open, on tab change and
	on state changes (throttled). Only the visible window redraws, so a busy
	farming loop never rebuilds a pet grid nobody is looking at.
]]

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Palette = require(Shared.Modules.Palette)
local Format = require(Shared.Modules.Format)
local Settings = require(Shared.Config.Settings)
local QuestsConfig = require(Shared.Config.Quests)

local Window = require(script.Parent.Parent.UI.Window)
local Panels = require(script.Parent.Panels)

local player = Players.LocalPlayer

local MenuController = {}
local Controllers

local screen
local windows = {}
local context
local lastRender = 0
local pendingRender = false

local DEFINITIONS = {
	{
		id = "shop",
		title = "Upgrade Shop",
		accent = Palette.coins,
		width = 580,
		height = 470,
		tabs = { { id = "collectors", name = "Collectors" }, { id = "backpacks", name = "Backpacks" } },
		render = Panels.shop,
	},
	{
		id = "pets",
		title = "Pets",
		accent = Palette.aura,
		width = 640,
		height = 500,
		tabs = { { id = "inventory", name = "Inventory" }, { id = "index", name = "Index" } },
		render = Panels.pets,
	},
	{
		id = "eggs",
		title = "Eggs",
		accent = Palette.premium,
		width = 580,
		height = 480,
		render = Panels.eggs,
	},
	{
		id = "rebirth",
		title = "Rebirth",
		accent = Palette.prisms,
		width = 580,
		height = 470,
		tabs = {
			{ id = "rebirth", name = "Rebirth" },
			{ id = "upgrades", name = "Upgrades" },
			{ id = "auras", name = "Auras" },
		},
		render = Panels.rebirth,
	},
	{
		id = "rewards",
		title = "Rewards",
		accent = Palette.positive,
		width = 600,
		height = 480,
		tabs = {
			{ id = "quests", name = "Quests" },
			{ id = "daily", name = "Daily" },
			{ id = "playtime", name = "Playtime" },
			{ id = "codes", name = "Codes" },
		},
		render = Panels.rewards,
	},
	{
		id = "zones",
		title = "Travel",
		accent = Palette.warning,
		width = 580,
		height = 470,
		render = Panels.zones,
	},
	{
		id = "store",
		title = "Store",
		accent = Palette.premium,
		width = 580,
		height = 440,
		tabs = { { id = "passes", name = "Gamepasses" }, { id = "products", name = "Boosts" } },
		render = Panels.store,
	},
	{
		id = "settings",
		title = "Settings",
		accent = Palette.textDim,
		width = 560,
		height = 460,
		render = Panels.settings,
	},
}

--- Client-side twin of RewardService.describe, for reward previews.
local function describeReward(reward)
	local pieces = {}
	local rebirthCost = Controllers.StateController.hot.rebirthCost or 0

	if reward.coins then
		table.insert(pieces, Format.abbreviate(reward.coins) .. " coins")
	end
	if reward.coinsAsRebirthFraction then
		table.insert(pieces, Format.abbreviate(rebirthCost * reward.coinsAsRebirthFraction) .. " coins")
	end
	if reward.prisms then
		table.insert(pieces, reward.prisms .. " prisms")
	end
	if reward.boost then
		table.insert(pieces, (reward.boost.name or "boost") .. " for " .. Format.duration(reward.boost.duration or 0))
	end

	return #pieces > 0 and table.concat(pieces, " + ") or "a reward"
end

local function render(entry)
	entry.window:clear()
	local ok, err = pcall(entry.definition.render, entry.window, context)
	if not ok then
		warn("[Menu] render failed for " .. entry.definition.id .. ": " .. tostring(err))
	end
end

local function renderOpen()
	for _, entry in pairs(windows) do
		if entry.window.isOpen then
			render(entry)
		end
	end
end

--- Coalesces bursts of state changes into at most four redraws a second.
local function requestRender()
	if pendingRender then
		return
	end

	local wait = math.max(0, 0.25 - (os.clock() - lastRender))
	pendingRender = true

	task.delay(wait, function()
		pendingRender = false
		lastRender = os.clock()
		renderOpen()
	end)
end

local function refreshBadges()
	local profile = Controllers.StateController.profile
	local claimable = false

	for _, quest in ipairs((profile.quests and profile.quests.active) or {}) do
		if not quest.claimed and quest.progress >= quest.goal then
			claimable = true
			break
		end
	end

	if not claimable and context.daily and context.daily.canClaim then
		claimable = true
	end

	if not claimable then
		local playtime = profile.playtime or { session = 0, claimed = {} }
		for index, minutes in ipairs(Settings.PlaytimeRewards) do
			if (playtime.session or 0) >= minutes * 60 and not table.find(playtime.claimed or {}, index) then
				claimable = true
				break
			end
		end
	end

	Controllers.HudController.setBadge("rewards", claimable)
end

function MenuController.init(controllers)
	Controllers = controllers

	screen = Instance.new("ScreenGui")
	screen.Name = "AuraMenus"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen.DisplayOrder = 15
	screen.Parent = player:WaitForChild("PlayerGui")

	context = {
		state = controllers.StateController,
		request = controllers.StateController.request,
		toast = controllers.EffectsController.toast,
		refresh = requestRender,
		describeReward = describeReward,
		catalog = nil,
		daily = nil,
	}

	for _, definition in ipairs(DEFINITIONS) do
		local window = Window.new(screen, {
			name = definition.id,
			title = definition.title,
			accent = definition.accent,
			width = definition.width,
			height = definition.height,
		})

		local entry = { window = window, definition = definition }
		windows[definition.id] = entry

		if definition.tabs then
			window:setTabs(definition.tabs)
			window.tabChanged:Connect(function()
				render(entry)
			end)
		end

		window.opened:Connect(function()
			render(entry)
		end)
	end
end

--- Opens one window and closes the others, so panels never stack up.
function MenuController.open(id, payload)
	local entry = windows[id]
	if not entry then
		return
	end

	for otherId, other in pairs(windows) do
		if otherId ~= id then
			other.window:close()
		end
	end

	if id == "store" and not context.catalog then
		task.spawn(function()
			local ok, result = Controllers.StateController.request("catalog")
			if ok then
				context.catalog = result
				requestRender()
			end
		end)
	end

	if id == "rewards" then
		task.spawn(function()
			local ok, result = Controllers.StateController.request("dailyState")
			if ok then
				context.daily = result
				requestRender()
			end
		end)
	end

	entry.window:open()
end

function MenuController.toggle(id)
	local entry = windows[id]
	if not entry then
		return
	end

	if entry.window.isOpen then
		entry.window:close()
	else
		MenuController.open(id)
	end
end

function MenuController.closeAll()
	for _, entry in pairs(windows) do
		entry.window:close()
	end
end

function MenuController.start()
	Controllers.StateController.changed:Connect(function()
		requestRender()
		refreshBadges()
	end)

	Controllers.StateController.profileChanged:Connect(function()
		requestRender()
		refreshBadges()
	end)

	-- Keep the daily timer honest without a request per frame.
	task.spawn(function()
		while true do
			task.wait(30)
			local ok, result = Controllers.StateController.request("dailyState")
			if ok then
				context.daily = result
				refreshBadges()
			end
		end
	end)
end

return MenuController
