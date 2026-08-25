--[[
	HudController — the always-on screen furniture.

	Reads exclusively from StateController, so every number on screen comes from
	the same snapshot the server sent. Nothing here computes gameplay values.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Palette = require(Shared.Modules.Palette)
local Format = require(Shared.Modules.Format)
local Zones = require(Shared.Config.Zones)

local UI = script.Parent.Parent.UI
local Elements = require(UI.Elements)
local Widgets = require(UI.Widgets)
local create = Elements.create

local player = Players.LocalPlayer

local HudController = {}
local Controllers

local screen
local labels = {}
local auraFill
local boostHolder
local menuButtons = {}

local MENU_ITEMS = {
	{ id = "shop", icon = "🛠️", label = "Shop", accent = Palette.coins },
	{ id = "pets", icon = "🐾", label = "Pets", accent = Palette.aura },
	{ id = "eggs", icon = "🥚", label = "Eggs", accent = Palette.premium },
	{ id = "rebirth", icon = "♻️", label = "Rebirth", accent = Palette.prisms },
	{ id = "rewards", icon = "🎁", label = "Rewards", accent = Palette.positive },
	{ id = "zones", icon = "🚀", label = "Travel", accent = Palette.warning },
	{ id = "store", icon = "💎", label = "Store", accent = Palette.premium },
	{ id = "settings", icon = "⚙️", label = "Settings", accent = Palette.textDim },
}

function HudController.init(controllers)
	Controllers = controllers

	screen = create("ScreenGui", {
		Name = "AuraHud",
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 10,
		Parent = player:WaitForChild("PlayerGui"),
	})

	-- Currency stack ---------------------------------------------------------
	local currencies = create("Frame", {
		Name = "Currencies",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 14),
		Size = UDim2.fromOffset(168, 140),
		Parent = screen,
	}, { Elements.list(6, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left) })

	local _, coinValue = Widgets.chip({
		parent = currencies,
		name = "Coins",
		icon = "🪙",
		text = "0",
		accent = Palette.coins,
		layoutOrder = 1,
		size = UDim2.fromOffset(168, 38),
	})
	labels.coins = coinValue

	local _, prismValue = Widgets.chip({
		parent = currencies,
		name = "Prisms",
		icon = "💠",
		text = "0",
		accent = Palette.prisms,
		layoutOrder = 2,
		size = UDim2.fromOffset(168, 38),
	})
	labels.prisms = prismValue

	local _, rebirthValue = Widgets.chip({
		parent = currencies,
		name = "Rebirths",
		icon = "♻️",
		text = "0",
		accent = Palette.positive,
		layoutOrder = 3,
		size = UDim2.fromOffset(168, 38),
	})
	labels.rebirths = rebirthValue

	-- Aura capacity ----------------------------------------------------------
	local auraPanel = create("Frame", {
		Name = "AuraPanel",
		BackgroundColor3 = Palette.panel,
		BackgroundTransparency = 0.08,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 14),
		Size = UDim2.fromOffset(360, 72),
		Parent = screen,
	}, {
		Elements.corner(14),
		Elements.stroke(Palette.aura, 1.5, 0.3),
	})

	Elements.text({
		Name = "Caption",
		Size = UDim2.new(1, -24, 0, 18),
		Position = UDim2.fromOffset(14, 8),
		Text = "AURA",
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = Palette.textDim,
		Parent = auraPanel,
	})

	labels.aura = Elements.text({
		Name = "Value",
		Size = UDim2.new(1, -24, 0, 20),
		Position = UDim2.fromOffset(14, 24),
		Text = "0 / 0",
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextColor3 = Palette.text,
		Parent = auraPanel,
	})

	labels.multiplier = Elements.text({
		Name = "Multiplier",
		AnchorPoint = Vector2.new(1, 0),
		Size = UDim2.fromOffset(180, 20),
		Position = UDim2.new(1, -14, 0, 24),
		Text = "",
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = Palette.aura,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = auraPanel,
	})

	local _, fill = Widgets.progressBar({
		parent = auraPanel,
		size = UDim2.new(1, -28, 0, 12),
		position = UDim2.fromOffset(14, 50),
		color = Palette.aura,
	})
	auraFill = fill

	-- Menu rail --------------------------------------------------------------
	local rail = create("Frame", {
		Name = "Menu",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 14, 0.5, 20),
		Size = UDim2.fromOffset(76, #MENU_ITEMS * 70),
		Parent = screen,
	}, { Elements.list(6, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left) })

	for index, item in ipairs(MENU_ITEMS) do
		local button = create("TextButton", {
			Name = item.id,
			BackgroundColor3 = Palette.panel,
			BackgroundTransparency = 0.08,
			Size = UDim2.fromOffset(70, 64),
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = index,
			Parent = rail,
		}, {
			Elements.corner(12),
			Elements.stroke(item.accent, 1.5, 0.45),
		})

		Elements.text({
			Size = UDim2.new(1, 0, 0, 30),
			Position = UDim2.fromOffset(0, 8),
			Text = item.icon,
			TextSize = 24,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = button,
		})

		Elements.text({
			Size = UDim2.new(1, 0, 0, 16),
			Position = UDim2.fromOffset(0, 40),
			Text = item.label,
			Font = Enum.Font.GothamBold,
			TextSize = 11,
			TextColor3 = item.accent,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = button,
		})

		local badge = create("Frame", {
			Name = "Badge",
			BackgroundColor3 = Palette.negative,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -4, 0, 4),
			Size = UDim2.fromOffset(12, 12),
			Visible = false,
			Parent = button,
		}, { Elements.corner(6) })

		button.Activated:Connect(function()
			Controllers.MenuController.toggle(item.id)
		end)

		button.MouseEnter:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.12), { BackgroundTransparency = 0 }):Play()
		end)
		button.MouseLeave:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.12), { BackgroundTransparency = 0.08 }):Play()
		end)

		menuButtons[item.id] = { button = button, badge = badge }
	end

	-- Boost strip ------------------------------------------------------------
	boostHolder = create("Frame", {
		Name = "Boosts",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 14, 1, -14),
		Size = UDim2.fromOffset(200, 120),
		Parent = screen,
	}, { Elements.list(6, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left) })

	-- Footer -----------------------------------------------------------------
	local footer = create("Frame", {
		Name = "Footer",
		BackgroundColor3 = Palette.panel,
		BackgroundTransparency = 0.15,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -14),
		Size = UDim2.fromOffset(430, 46),
		Parent = screen,
	}, { Elements.corner(12), Elements.stroke(Palette.stroke, 1.5, 0.4) })

	labels.zone = Elements.text({
		Name = "Zone",
		Size = UDim2.new(0.55, -16, 1, 0),
		Position = UDim2.fromOffset(14, 0),
		Text = "Sunrise Meadow",
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		TextColor3 = Palette.text,
		Parent = footer,
	})

	labels.perSwing = Elements.text({
		Name = "PerSwing",
		AnchorPoint = Vector2.new(1, 0),
		Size = UDim2.new(0.45, -16, 1, 0),
		Position = UDim2.new(1, -14, 0, 0),
		Text = "",
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = Palette.aura,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = footer,
	})
end

local function refreshBoosts(hot)
	for _, child in ipairs(boostHolder:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	for index, boost in ipairs(hot.boosts or {}) do
		local remaining = boost.endsAt - (hot.serverTime or os.time())
		local _, value = Widgets.chip({
			parent = boostHolder,
			name = boost.id,
			icon = boost.luckMult and "🍀" or "⚡",
			text = string.format("%s  %s", boost.name, Format.duration(remaining)),
			accent = boost.luckMult and Palette.positive or Palette.warning,
			layoutOrder = index,
			size = UDim2.fromOffset(200, 32),
		})
		value.TextSize = 12
	end
end

local function refresh()
	local hot = Controllers.StateController.hot
	if not hot.capacity then
		return
	end

	labels.coins.Text = Format.abbreviate(hot.coins or 0)
	labels.prisms.Text = Format.abbreviate(hot.prisms or 0)
	labels.rebirths.Text = Format.comma(hot.rebirths or 0)

	local ratio = math.clamp((hot.aura or 0) / math.max(1, hot.capacity), 0, 1)
	labels.aura.Text = string.format("%s / %s", Format.abbreviate(hot.aura or 0), Format.abbreviate(hot.capacity))
	labels.multiplier.Text = Format.multiplier(hot.auraMult or 1) .. " aura"

	TweenService:Create(auraFill, TweenInfo.new(0.18), { Size = UDim2.fromScale(ratio, 1) }):Play()

	local full = ratio >= 1
	auraFill.BackgroundColor3 = full and Palette.negative or Palette.aura
	labels.aura.TextColor3 = full and Palette.negative or Palette.text

	local zone = Zones.get(hot.zone)
	labels.zone.Text = zone and zone.name or "Unknown"
	labels.perSwing.Text = Format.abbreviate(hot.auraPerSwing or 0) .. " per swing"

	refreshBoosts(hot)
end

--- Red dot on a rail button, used for claimable quests and rewards.
function HudController.setBadge(menuId, visible)
	local entry = menuButtons[menuId]
	if entry then
		entry.badge.Visible = visible
	end
end

function HudController.start()
	Controllers.StateController.changed:Connect(refresh)
	Controllers.StateController.profileChanged:Connect(refresh)

	-- Boost countdowns tick locally between server pushes.
	task.spawn(function()
		while true do
			task.wait(1)
			if Controllers.StateController.ready then
				refreshBoosts(Controllers.StateController.hot)
			end
		end
	end)

	refresh()
end

return HudController
