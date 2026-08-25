--[[
	Panels — the contents of every menu window.

	Each function receives the Window it should fill and a small context table
	(state access, an action dispatcher, a toast function). Panels rebuild from
	scratch on every refresh; the lists are small and rebuilding removes any
	chance of a stale row lying about a price.
]]

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Settings = require(Shared.Config.Settings)
local Collectors = require(Shared.Config.Collectors)
local Backpacks = require(Shared.Config.Backpacks)
local Zones = require(Shared.Config.Zones)
local Eggs = require(Shared.Config.Eggs)
local Pets = require(Shared.Config.Pets)
local RebirthConfig = require(Shared.Config.Rebirth)
local QuestsConfig = require(Shared.Config.Quests)
local Palette = require(Shared.Modules.Palette)
local Format = require(Shared.Modules.Format)
local Rng = require(Shared.Modules.Rng)

local UI = script.Parent.Parent.UI
local Elements = require(UI.Elements)
local Widgets = require(UI.Widgets)
local PetBuilder = require(UI.PetBuilder)
local create = Elements.create

local Panels = {}

-- Helpers ---------------------------------------------------------------------

local function act(ctx, action, payload)
	task.spawn(function()
		local ok, message = ctx.request(action, payload)
		if not ok then
			ctx.toast({ title = "Not yet", body = tostring(message), kind = "bad" })
		end
		ctx.refresh()
	end)
end

--- A pet's picture. ViewportFrames look far better but each one is a real
--- render pass, and the Index tab shows 55 at once — so "Reduce effects" swaps
--- them for flat swatches instead of being a setting that does nothing.
local function petVisual(ctx, config)
	local prefs = ctx.state.profile.prefs or {}
	if not prefs.lowGraphics then
		return PetBuilder.viewport(config)
	end

	local swatch = create("Frame", {
		Name = "Swatch",
		BackgroundColor3 = config.definition.color,
		Size = config.size,
		Position = config.position,
		AnchorPoint = config.anchorPoint,
		LayoutOrder = config.layoutOrder,
		Parent = config.parent,
	}, {
		Elements.corner(9),
		Elements.stroke(Palette.rarityColor(config.definition.rarity), 2, 0.15),
	})

	Elements.text({
		Size = UDim2.fromScale(1, 1),
		Text = string.sub(config.definition.name, 1, 1),
		Font = Enum.Font.GothamBlack,
		TextSize = 24,
		TextColor3 = Color3.fromRGB(20, 20, 30),
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = swatch,
	})

	return swatch
end

local function gridHolder(parent, cell, order)
	return create("Frame", {
		Name = "Grid",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = order or 1,
		Parent = parent,
	}, { Elements.grid(cell, UDim2.fromOffset(8, 8)) })
end

local function emptyState(parent, text)
	Elements.text({
		Size = UDim2.new(1, 0, 0, 60),
		Text = text,
		TextSize = 14,
		TextColor3 = Palette.textDim,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextWrapped = true,
		Parent = parent,
	})
end

-- Shop --------------------------------------------------------------------------

local function tierList(window, ctx, list, ownedIndex, action, describe, icon)
	local coins = ctx.state.hot.coins or 0

	for index, entry in ipairs(list) do
		local owned = index <= ownedIndex
		local current = index == ownedIndex
		local affordable = coins >= entry.cost

		local buttonText = current and "EQUIPPED" or (owned and "OWNED" or Format.abbreviate(entry.cost))
		local buttonColor = current and Palette.positive
			or (owned and Palette.panelAlt or (affordable and Palette.coins or Palette.panelAlt))

		local _, button = Widgets.row({
			parent = window.content,
			layoutOrder = index,
			icon = icon,
			accent = current and Palette.positive or Palette.coins,
			title = string.format("%d. %s", index, entry.name),
			titleColor = current and Palette.positive or Palette.text,
			subtitle = describe(entry),
			buttonText = buttonText,
			buttonColor = buttonColor,
			onClick = function()
				act(ctx, action, { index = index })
			end,
		})

		if button and owned then
			Widgets.setDisabled(button, true)
		elseif button and not affordable then
			button.TextColor3 = Palette.textDim
		end
	end
end

function Panels.shop(window, ctx)
	local profile = ctx.state.profile

	if window.activeTab == "backpacks" then
		window:setSubtitle("Carry more aura between vault runs.")
		tierList(window, ctx, Backpacks, profile.backpackIndex or 1, "buyBackpack", function(entry)
			return "Holds " .. Format.abbreviate(entry.capacity) .. " aura."
		end, "🎒")
	else
		window:setSubtitle("Raw power per swing, before multipliers.")
		tierList(window, ctx, Collectors, profile.collectorIndex or 1, "buyCollector", function(entry)
			return Format.abbreviate(entry.power) .. " base aura per swing."
		end, "⛏️")
	end
end

-- Pets ---------------------------------------------------------------------------

local function petCard(parent, ctx, definition, tier, count, order, equipped, uid)
	local rarityColor = Palette.rarityColor(definition.rarity)

	local card = Widgets.card({
		parent = parent,
		layoutOrder = order,
		size = UDim2.fromOffset(136, 178),
		stroke = equipped and Palette.positive or rarityColor,
	})

	petVisual(ctx, {
		parent = card,
		definition = definition,
		tier = tier,
		size = UDim2.fromOffset(74, 74),
		position = UDim2.new(0.5, 0, 0, 8),
		anchorPoint = Vector2.new(0.5, 0),
	})

	if count and count > 1 then
		local badge = create("Frame", {
			Name = "Count",
			BackgroundColor3 = Palette.panel,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -8, 0, 8),
			Size = UDim2.fromOffset(34, 20),
			ZIndex = 12,
			Parent = card,
		}, { Elements.corner(10), Elements.stroke(rarityColor, 1.2, 0.3) })

		Elements.text({
			Size = UDim2.fromScale(1, 1),
			Text = "x" .. count,
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			TextColor3 = rarityColor,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 13,
			Parent = badge,
		})
	end

	Elements.text({
		Size = UDim2.new(1, -10, 0, 17),
		Position = UDim2.fromOffset(5, 86),
		Text = (Palette.tierName[tier] or "") .. definition.name,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = Palette.text,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = card,
	})

	Elements.text({
		Size = UDim2.new(1, -10, 0, 15),
		Position = UDim2.fromOffset(5, 103),
		Text = definition.rarity,
		TextSize = 11,
		TextColor3 = rarityColor,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = card,
	})

	local scaled = definition.mult * (Settings.TierMultipliers[tier] or 1)
	Elements.text({
		Size = UDim2.new(1, -10, 0, 15),
		Position = UDim2.fromOffset(5, 118),
		Text = "+" .. Format.abbreviate(scaled) .. " aura",
		TextSize = 11,
		TextColor3 = Palette.aura,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = card,
	})

	return card
end

local function petsInventory(window, ctx)
	local profile = ctx.state.profile
	local hot = ctx.state.hot
	local pets = profile.pets or {}

	window:setSubtitle(string.format(
		"%d pets · %d/%d equipped · %s multiplier",
		#pets,
		hot.equippedPets or 0,
		hot.petSlots or Settings.BasePetSlots,
		Format.multiplier(hot.petMult or 1)
	))

	-- Bulk actions ----------------------------------------------------------
	local actions = create("Frame", {
		Name = "Actions",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 38),
		LayoutOrder = 0,
		Parent = window.content,
	}, { Elements.list(6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left) })

	Widgets.button({
		parent = actions,
		text = "Equip Best",
		color = Palette.positive,
		size = UDim2.fromOffset(120, 34),
		layoutOrder = 1,
		onClick = function()
			act(ctx, "equipBest")
		end,
	})
	Widgets.button({
		parent = actions,
		text = "Unequip All",
		color = Palette.panelAlt,
		textColor = Palette.text,
		size = UDim2.fromOffset(120, 34),
		layoutOrder = 2,
		onClick = function()
			act(ctx, "unequipAll")
		end,
	})
	Widgets.button({
		parent = actions,
		text = "Release Weak",
		color = Palette.negative,
		size = UDim2.fromOffset(126, 34),
		layoutOrder = 3,
		onClick = function()
			act(ctx, "deleteWeak")
		end,
	})

	if #pets == 0 then
		emptyState(window.content, "No pets yet. Hatch one at the egg stand in any zone.")
		return
	end

	-- Equipped ---------------------------------------------------------------
	local equipped = {}
	for _, pet in ipairs(pets) do
		if pet.equipped then
			table.insert(equipped, pet)
		end
	end

	if #equipped > 0 then
		Widgets.heading(window.content, "EQUIPPED", 1)
		local grid = gridHolder(window.content, UDim2.fromOffset(136, 178), 2)

		for index, pet in ipairs(equipped) do
			local definition = Pets.get(pet.id)
			if definition then
				local card = petCard(grid, ctx, definition, pet.tier, nil, index, true, pet.uid)
				Widgets.button({
					parent = card,
					text = "Unequip",
					color = Palette.panelAlt,
					textColor = Palette.text,
					size = UDim2.fromOffset(118, 28),
					position = UDim2.new(0.5, 0, 1, -8),
					anchorPoint = Vector2.new(0.5, 1),
					textSize = 12,
					onClick = function()
						act(ctx, "unequipPet", { uid = pet.uid })
					end,
				})
			end
		end
	end

	-- Collection, stacked by pet + tier ---------------------------------------
	local stacks = {}
	local order = {}

	for _, pet in ipairs(pets) do
		if not pet.equipped then
			local key = pet.id .. "#" .. pet.tier
			if not stacks[key] then
				stacks[key] = { id = pet.id, tier = pet.tier, count = 0, firstUid = pet.uid }
				table.insert(order, key)
			end
			stacks[key].count += 1
		end
	end

	table.sort(order, function(a, b)
		local defA, defB = Pets.get(stacks[a].id), Pets.get(stacks[b].id)
		local valueA = defA and defA.mult * (Settings.TierMultipliers[stacks[a].tier] or 1) or 0
		local valueB = defB and defB.mult * (Settings.TierMultipliers[stacks[b].tier] or 1) or 0
		return valueA > valueB
	end)

	if #order == 0 then
		return
	end

	Widgets.heading(window.content, "COLLECTION", 3)
	local grid = gridHolder(window.content, UDim2.fromOffset(136, 178), 4)

	for index, key in ipairs(order) do
		local stack = stacks[key]
		local definition = Pets.get(stack.id)
		if definition then
			local card = petCard(grid, ctx, definition, stack.tier, stack.count, index, false, stack.firstUid)

			local canFuse = stack.count >= Settings.FuseCount and stack.tier < 3
			local buttons = create("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -12, 0, 28),
				Position = UDim2.new(0.5, 0, 1, -8),
				AnchorPoint = Vector2.new(0.5, 1),
				Parent = card,
			}, { Elements.list(4, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center) })

			Widgets.button({
				parent = buttons,
				text = "Equip",
				color = Palette.aura,
				size = UDim2.fromOffset(canFuse and 58 or 118, 28),
				textSize = 12,
				layoutOrder = 1,
				onClick = function()
					act(ctx, "equipPet", { uid = stack.firstUid })
				end,
			})

			if canFuse then
				Widgets.button({
					parent = buttons,
					text = "Fuse",
					color = Palette.premium,
					size = UDim2.fromOffset(56, 28),
					textSize = 12,
					layoutOrder = 2,
					onClick = function()
						act(ctx, "fusePet", { id = stack.id, tier = stack.tier })
					end,
				})
			end

			-- Release one copy from the stack.
			Widgets.button({
				parent = card,
				name = "Release",
				text = "✕",
				color = Palette.negative,
				size = UDim2.fromOffset(22, 22),
				position = UDim2.fromOffset(6, 6),
				radius = 11,
				textSize = 12,
				onClick = function()
					act(ctx, "deletePet", { uid = stack.firstUid })
				end,
			}).ZIndex = 12
		end
	end
end

local function petsIndex(window, ctx)
	local profile = ctx.state.profile
	local discovered = profile.index or {}

	local found = 0
	for _ in pairs(discovered) do
		found += 1
	end

	window:setSubtitle(string.format("%d of %d pets discovered.", found, Pets.count()))

	local order = 0
	for _, egg in ipairs(Eggs) do
		order += 1
		Widgets.heading(window.content, egg.name:upper(), order)

		order += 1
		local grid = gridHolder(window.content, UDim2.fromOffset(112, 122), order)

		local ids = {}
		for id, definition in pairs(Pets.all()) do
			if definition.egg == egg.id then
				table.insert(ids, id)
			end
		end
		table.sort(ids, function(a, b)
			return Pets.get(a).mult < Pets.get(b).mult
		end)

		for index, id in ipairs(ids) do
			local definition = Pets.get(id)
			local count = discovered[id] or 0
			local rarityColor = Palette.rarityColor(definition.rarity)

			local card = Widgets.card({
				parent = grid,
				layoutOrder = index,
				size = UDim2.fromOffset(112, 122),
				stroke = count > 0 and rarityColor or Palette.stroke,
			})

			if count > 0 then
				petVisual(ctx, {
					parent = card,
					definition = definition,
					tier = 1,
					size = UDim2.fromOffset(58, 58),
					position = UDim2.new(0.5, 0, 0, 8),
					anchorPoint = Vector2.new(0.5, 0),
				})
			else
				Elements.text({
					Size = UDim2.fromOffset(58, 58),
					Position = UDim2.new(0.5, 0, 0, 8),
					AnchorPoint = Vector2.new(0.5, 0),
					Text = "?",
					Font = Enum.Font.GothamBlack,
					TextSize = 30,
					TextColor3 = Palette.textDim,
					TextXAlignment = Enum.TextXAlignment.Center,
					Parent = card,
				})
			end

			Elements.text({
				Size = UDim2.new(1, -8, 0, 16),
				Position = UDim2.fromOffset(4, 70),
				Text = count > 0 and definition.name or "???",
				Font = Enum.Font.GothamBold,
				TextSize = 11,
				TextColor3 = count > 0 and Palette.text or Palette.textDim,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = card,
			})

			Elements.text({
				Size = UDim2.new(1, -8, 0, 14),
				Position = UDim2.fromOffset(4, 86),
				Text = definition.rarity,
				TextSize = 10,
				TextColor3 = rarityColor,
				TextXAlignment = Enum.TextXAlignment.Center,
				Parent = card,
			})

			Elements.text({
				Size = UDim2.new(1, -8, 0, 14),
				Position = UDim2.fromOffset(4, 100),
				Text = count > 0 and ("hatched x" .. count) or "undiscovered",
				TextSize = 10,
				TextColor3 = Palette.textDim,
				TextXAlignment = Enum.TextXAlignment.Center,
				Parent = card,
			})
		end
	end
end

function Panels.pets(window, ctx)
	if window.activeTab == "index" then
		petsIndex(window, ctx)
	else
		petsInventory(window, ctx)
	end
end

-- Eggs ----------------------------------------------------------------------------

function Panels.eggs(window, ctx)
	local hot = ctx.state.hot
	local luck = hot.luck or 1

	window:setSubtitle(string.format("Luck %s — rarer pets are %s more likely.", Format.multiplier(luck), Format.percent(math.max(0, luck - 1), 0)))

	for index, egg in ipairs(Eggs) do
		local zone = Zones.get(egg.zone)
		local unlocked = ctx.state.hasZone(egg.zone) or (zone and zone.requiresPass and ctx.state.owns(zone.requiresPass))

		local card = Widgets.card({
			parent = window.content,
			layoutOrder = index,
			size = UDim2.new(1, 0, 0, 168),
			stroke = unlocked and egg.color or Palette.stroke,
		})

		Elements.text({
			Size = UDim2.new(1, -24, 0, 22),
			Position = UDim2.fromOffset(14, 10),
			Text = egg.name,
			Font = Enum.Font.GothamBold,
			TextSize = 17,
			TextColor3 = unlocked and egg.color or Palette.textDim,
			Parent = card,
		})

		Elements.text({
			Size = UDim2.new(1, -24, 0, 18),
			Position = UDim2.fromOffset(14, 30),
			Text = unlocked
					and (Format.abbreviate(egg.cost) .. " coins each · found in " .. (zone and zone.name or "?"))
				or ("Locked — unlock " .. (zone and zone.name or "the zone") .. " first"),
			TextSize = 12,
			TextColor3 = Palette.textDim,
			Parent = card,
		})

		-- Odds, ranked rarest first so the exciting numbers are on top.
		local odds = Rng.odds(egg.pool, luck)
		local rows = {}
		for petId, chance in pairs(odds) do
			table.insert(rows, { id = petId, chance = chance })
		end
		table.sort(rows, function(a, b)
			return a.chance < b.chance
		end)

		local oddsHolder = create("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(14, 54),
			Size = UDim2.new(1, -28, 0, 58),
			Parent = card,
		}, { Elements.list(3) })

		for rank = 1, math.min(3, #rows) do
			local row = rows[rank]
			local definition = Pets.get(row.id)
			if definition then
				local line = create("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 17),
					LayoutOrder = rank,
					Parent = oddsHolder,
				})

				Elements.text({
					Size = UDim2.new(0.6, 0, 1, 0),
					Text = definition.name,
					TextSize = 12,
					TextColor3 = Palette.rarityColor(definition.rarity),
					Parent = line,
				})

				Elements.text({
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.fromScale(1, 0),
					Size = UDim2.new(0.4, 0, 1, 0),
					Text = row.chance < 0.001 and string.format("1 in %s", Format.abbreviate(1 / math.max(row.chance, 1e-9)))
						or Format.percent(row.chance, 2),
					TextSize = 12,
					TextColor3 = Palette.textDim,
					TextXAlignment = Enum.TextXAlignment.Right,
					Parent = line,
				})
			end
		end

		local buttons = create("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(14, 120),
			Size = UDim2.new(1, -28, 0, 36),
			Parent = card,
		}, { Elements.list(8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left) })

		for batchIndex, batch in ipairs(Eggs.batchSizes) do
			local cost = egg.cost * batch
			local affordable = (hot.coins or 0) >= cost

			local button = Widgets.button({
				parent = buttons,
				text = string.format("Hatch %dx", batch),
				color = unlocked and (affordable and egg.color or Palette.panelAlt) or Palette.panelAlt,
				size = UDim2.fromOffset(112, 34),
				layoutOrder = batchIndex,
				onClick = function()
					act(ctx, "hatch", { egg = egg.id, count = batch })
				end,
			})

			if not unlocked then
				Widgets.setDisabled(button, true, "Locked")
			elseif not affordable then
				button.TextColor3 = Palette.textDim
			end
		end
	end
end

-- Rebirth ---------------------------------------------------------------------------

local function rebirthSummary(window, ctx)
	local hot = ctx.state.hot
	local cost = hot.rebirthCost or 0
	local ready = (hot.coins or 0) >= cost

	window:setSubtitle("Reset coins and tiers. Keep pets, prisms and zones.")

	local hero = Widgets.card({
		parent = window.content,
		layoutOrder = 1,
		size = UDim2.new(1, 0, 0, 150),
		stroke = ready and Palette.positive or Palette.prisms,
	})

	Elements.text({
		Size = UDim2.new(1, -28, 0, 26),
		Position = UDim2.fromOffset(16, 14),
		Text = "Rebirth " .. ((hot.rebirths or 0) + 1),
		Font = Enum.Font.GothamBold,
		TextSize = 20,
		TextColor3 = Palette.prisms,
		Parent = hero,
	})

	Elements.text({
		Size = UDim2.new(1, -28, 0, 40),
		Position = UDim2.fromOffset(16, 42),
		Text = string.format(
			"Costs %s coins.\nPays %d prisms and takes your permanent aura bonus to +%d%%.",
			Format.abbreviate(cost),
			hot.rebirthReward or 0,
			math.floor(((hot.rebirths or 0) + 1) * Settings.RebirthAuraBonus * 100)
		),
		TextSize = 13,
		TextColor3 = Palette.textDim,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = hero,
	})

	local _, fill = Widgets.progressBar({
		parent = hero,
		size = UDim2.new(1, -32, 0, 10),
		position = UDim2.fromOffset(16, 92),
		color = ready and Palette.positive or Palette.prisms,
	})
	fill.Size = UDim2.fromScale(math.clamp((hot.coins or 0) / math.max(1, cost), 0, 1), 1)

	local button = Widgets.button({
		parent = hero,
		text = ready and "REBIRTH NOW" or ("Need " .. Format.abbreviate(cost - (hot.coins or 0)) .. " more"),
		color = ready and Palette.positive or Palette.panelAlt,
		textColor = ready and Color3.fromRGB(16, 16, 26) or Palette.textDim,
		size = UDim2.new(1, -32, 0, 36),
		position = UDim2.fromOffset(16, 108),
		onClick = function()
			act(ctx, "rebirth")
		end,
	})

	if not ready then
		Widgets.setDisabled(button, true)
	end
end

local function rebirthUpgrades(window, ctx)
	local prisms = ctx.state.hot.prisms or 0
	window:setSubtitle(Format.comma(prisms) .. " prisms available.")

	for index, upgrade in ipairs(RebirthConfig.upgrades) do
		local level = ctx.state.upgradeLevel(upgrade.id)
		local maxed = level >= upgrade.maxLevel
		local cost = RebirthConfig.upgradeCost(upgrade, level)
		local affordable = prisms >= cost

		local _, button = Widgets.row({
			parent = window.content,
			layoutOrder = index,
			icon = "💠",
			accent = maxed and Palette.positive or Palette.prisms,
			title = string.format("%s  ·  %d/%d", upgrade.name, level, upgrade.maxLevel),
			subtitle = upgrade.desc,
			buttonText = maxed and "MAXED" or (cost .. " 💠"),
			buttonColor = maxed and Palette.panelAlt or (affordable and Palette.prisms or Palette.panelAlt),
			onClick = function()
				act(ctx, "buyUpgrade", { id = upgrade.id })
			end,
		})

		if button and maxed then
			Widgets.setDisabled(button, true)
		elseif button and not affordable then
			button.TextColor3 = Palette.textDim
		end
	end
end

local function rebirthAuras(window, ctx)
	local profile = ctx.state.profile
	local prisms = ctx.state.hot.prisms or 0
	window:setSubtitle("Cosmetic trails. No stats, pure flex.")

	for index, aura in ipairs(RebirthConfig.auras) do
		local owned = aura.id == "none" or (profile.auras and profile.auras[aura.id])
		local equipped = profile.auraEquipped == aura.id
		local affordable = prisms >= aura.cost

		local _, button = Widgets.row({
			parent = window.content,
			layoutOrder = index,
			icon = "✨",
			accent = aura.color,
			title = aura.name,
			subtitle = owned and (equipped and "Currently equipped." or "Owned.")
				or (aura.cost .. " prisms."),
			buttonText = equipped and "ON" or (owned and "Equip" or (aura.cost .. " 💠")),
			buttonColor = equipped and Palette.positive
				or (owned and Palette.aura or (affordable and Palette.prisms or Palette.panelAlt)),
			onClick = function()
				if owned then
					act(ctx, "equipAura", { id = aura.id })
				else
					act(ctx, "buyAura", { id = aura.id })
				end
			end,
		})

		if button and equipped then
			Widgets.setDisabled(button, true)
		end
	end
end

function Panels.rebirth(window, ctx)
	if window.activeTab == "upgrades" then
		rebirthUpgrades(window, ctx)
	elseif window.activeTab == "auras" then
		rebirthAuras(window, ctx)
	else
		rebirthSummary(window, ctx)
	end
end

-- Rewards ------------------------------------------------------------------------------

local function questsTab(window, ctx)
	local quests = (ctx.state.profile.quests and ctx.state.profile.quests.active) or {}
	local rerollAt = ctx.state.profile.quests and ctx.state.profile.quests.rerollAt or 0
	local remaining = math.max(0, rerollAt - (ctx.state.hot.serverTime or os.time()))

	window:setSubtitle("New quests in " .. Format.duration(remaining) .. ".")

	if #quests == 0 then
		emptyState(window.content, "Quests are being assigned…")
		return
	end

	for index, quest in ipairs(quests) do
		local done = quest.progress >= quest.goal
		local reward = quest.reward.kind == "coins" and (Format.abbreviate(quest.reward.amount) .. " coins")
			or (quest.reward.kind == "prisms" and (quest.reward.amount .. " prisms"))
			or (QuestsConfig.boosts[quest.reward.boostId] and QuestsConfig.boosts[quest.reward.boostId].name)
			or "a reward"

		local card, button = Widgets.row({
			parent = window.content,
			layoutOrder = index,
			height = 86,
			icon = quest.claimed and "✅" or (done and "🎉" or "📜"),
			accent = quest.claimed and Palette.textDim or (done and Palette.positive or Palette.aura),
			title = string.format(quest.text, Format.abbreviate(quest.goal)),
			subtitle = string.format(
				"%s / %s   ·   reward: %s",
				Format.abbreviate(quest.progress),
				Format.abbreviate(quest.goal),
				reward
			),
			buttonText = quest.claimed and "CLAIMED" or (done and "CLAIM" or "IN PROGRESS"),
			buttonColor = quest.claimed and Palette.panelAlt or (done and Palette.positive or Palette.panelAlt),
			onClick = function()
				act(ctx, "claimQuest", { index = index })
			end,
		})

		if button and (quest.claimed or not done) then
			Widgets.setDisabled(button, true)
		end

		local _, fill = Widgets.progressBar({
			parent = card,
			size = UDim2.new(1, -160, 0, 6),
			position = UDim2.fromOffset(74, 70),
			color = done and Palette.positive or Palette.aura,
		})
		fill.Size = UDim2.fromScale(math.clamp(quest.progress / math.max(1, quest.goal), 0, 1), 1)
	end
end

local function dailyTab(window, ctx)
	local daily = ctx.daily or {}
	window:setSubtitle(daily.canClaim and "Your reward is ready." or ("Next in " .. Format.duration(daily.nextIn or 0) .. "."))

	Widgets.heading(window.content, "STREAK: " .. (daily.streak or 0) .. " DAYS", 0)

	for index, reward in ipairs(QuestsConfig.daily) do
		local isToday = index == (daily.day or 1)
		local claimable = isToday and daily.canClaim

		local _, button = Widgets.row({
			parent = window.content,
			layoutOrder = index,
			icon = isToday and "🎁" or "📦",
			accent = isToday and Palette.premium or Palette.stroke,
			title = "Day " .. reward.day,
			titleColor = isToday and Palette.premium or Palette.text,
			subtitle = ctx.describeReward(reward),
			buttonText = claimable and "CLAIM" or (isToday and "SOON" or "LOCKED"),
			buttonColor = claimable and Palette.positive or Palette.panelAlt,
			onClick = function()
				act(ctx, "claimDaily")
			end,
		})

		if button and not claimable then
			Widgets.setDisabled(button, true)
		end
	end
end

local function playtimeTab(window, ctx)
	local profile = ctx.state.profile
	local playtime = profile.playtime or { session = 0, claimed = {} }

	window:setSubtitle("Session time: " .. Format.duration(playtime.session or 0) .. ".")

	for index, minutes in ipairs(Settings.PlaytimeRewards) do
		local claimed = table.find(playtime.claimed or {}, index) ~= nil
		local ready = (playtime.session or 0) >= minutes * 60
		local reward = QuestsConfig.playtime[index] or {}

		local _, button = Widgets.row({
			parent = window.content,
			layoutOrder = index,
			icon = claimed and "✅" or (ready and "⏰" or "⏳"),
			accent = ready and Palette.positive or Palette.stroke,
			title = minutes .. " minutes",
			subtitle = ctx.describeReward(reward),
			buttonText = claimed and "CLAIMED" or (ready and "CLAIM" or Format.duration(minutes * 60 - (playtime.session or 0))),
			buttonColor = (ready and not claimed) and Palette.positive or Palette.panelAlt,
			onClick = function()
				act(ctx, "claimPlaytime", { index = index })
			end,
		})

		if button and (claimed or not ready) then
			Widgets.setDisabled(button, true)
		end
	end
end

local function codesTab(window, ctx)
	window:setSubtitle("Codes are announced in the game description and group.")

	local card = Widgets.card({
		parent = window.content,
		layoutOrder = 1,
		size = UDim2.new(1, 0, 0, 96),
	})

	local box = create("TextBox", {
		Name = "Code",
		BackgroundColor3 = Palette.background,
		Size = UDim2.new(1, -150, 0, 40),
		Position = UDim2.fromOffset(14, 14),
		Font = Enum.Font.GothamBold,
		PlaceholderText = "Enter a code…",
		PlaceholderColor3 = Palette.textDim,
		Text = "",
		TextColor3 = Palette.text,
		TextSize = 15,
		ClearTextOnFocus = false,
		Parent = card,
	}, { Elements.corner(9), Elements.stroke(Palette.stroke, 1.2, 0.3), Elements.padding(10) })

	local status = Elements.text({
		Size = UDim2.new(1, -28, 0, 22),
		Position = UDim2.fromOffset(14, 60),
		Text = "",
		TextSize = 12,
		TextColor3 = Palette.textDim,
		Parent = card,
	})

	local function submit()
		local code = box.Text
		if code == "" then
			return
		end
		task.spawn(function()
			local ok, message = ctx.request("redeemCode", { code = code })
			status.Text = ok and "Redeemed." or tostring(message)
			status.TextColor3 = ok and Palette.positive or Palette.negative
			if ok then
				box.Text = ""
			end
			ctx.refresh()
		end)
	end

	Widgets.button({
		parent = card,
		text = "Redeem",
		color = Palette.premium,
		size = UDim2.fromOffset(120, 40),
		position = UDim2.new(1, -14, 0, 14),
		anchorPoint = Vector2.new(1, 0),
		onClick = submit,
	})

	box.FocusLost:Connect(function(enter)
		if enter then
			submit()
		end
	end)

	local used = ctx.state.profile.codes or {}
	local names = {}
	for code in pairs(used) do
		table.insert(names, code)
	end
	table.sort(names)

	if #names > 0 then
		Widgets.heading(window.content, "ALREADY REDEEMED", 2)
		Elements.text({
			Size = UDim2.new(1, 0, 0, 40),
			Text = table.concat(names, ", "),
			TextSize = 12,
			TextColor3 = Palette.textDim,
			TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top,
			LayoutOrder = 3,
			Parent = window.content,
		})
	end
end

function Panels.rewards(window, ctx)
	if window.activeTab == "daily" then
		dailyTab(window, ctx)
	elseif window.activeTab == "playtime" then
		playtimeTab(window, ctx)
	elseif window.activeTab == "codes" then
		codesTab(window, ctx)
	else
		questsTab(window, ctx)
	end
end

-- Zones ---------------------------------------------------------------------------------

function Panels.zones(window, ctx)
	local hot = ctx.state.hot
	local unlockedCount = 0

	for index, zone in ipairs(Zones) do
		local unlocked = ctx.state.hasZone(zone.id)
			or (zone.requiresPass and ctx.state.owns(zone.requiresPass))
		if unlocked then
			unlockedCount += 1
		end

		local previous = Zones[index - 1]
		local previousDone = previous == nil or previous.requiresPass or ctx.state.hasZone(previous.id)
		local meetsRebirth = (hot.rebirths or 0) >= zone.rebirthReq
		local affordable = (hot.coins or 0) >= zone.unlockCost

		local subtitle
		if unlocked then
			subtitle = string.format("%s aura · %s sell rate", Format.multiplier(zone.auraMult), Format.multiplier(zone.sellMult))
		elseif zone.requiresPass then
			subtitle = "Included with the VIP gamepass."
		elseif not previousDone then
			subtitle = "Unlock " .. previous.name .. " first."
		elseif not meetsRebirth then
			subtitle = string.format("Requires %d rebirths (you have %d).", zone.rebirthReq, hot.rebirths or 0)
		else
			subtitle = Format.abbreviate(zone.unlockCost) .. " coins to unlock."
		end

		local canUnlock = not unlocked and not zone.requiresPass and previousDone and meetsRebirth and affordable
		local isHere = hot.zone == zone.id

		local _, button = Widgets.row({
			parent = window.content,
			layoutOrder = index,
			icon = unlocked and "🚀" or "🔒",
			accent = zone.accent,
			title = string.format("%d. %s", zone.order, zone.name),
			titleColor = unlocked and Palette.text or Palette.textDim,
			subtitle = subtitle,
			buttonText = isHere and "YOU ARE HERE" or (unlocked and "Travel" or (canUnlock and "UNLOCK" or "LOCKED")),
			buttonColor = isHere and Palette.panelAlt
				or (unlocked and zone.accent or (canUnlock and Palette.coins or Palette.panelAlt)),
			onClick = function()
				if unlocked then
					act(ctx, "teleport", { zone = zone.id })
				else
					act(ctx, "unlockZone", { zone = zone.id })
				end
			end,
		})

		if button and (isHere or (not unlocked and not canUnlock)) then
			Widgets.setDisabled(button, true)
		end
	end

	window:setSubtitle(string.format("%d of %d zones unlocked.", unlockedCount, #Zones))
end

-- Store -----------------------------------------------------------------------------------

function Panels.store(window, ctx)
	local MarketplaceService = game:GetService("MarketplaceService")
	local Players = game:GetService("Players")
	local catalog = ctx.catalog

	if not catalog then
		emptyState(window.content, "Loading the store…")
		return
	end

	local isPasses = window.activeTab ~= "products"
	local list = isPasses and catalog.gamepasses or catalog.products

	window:setSubtitle(isPasses and "Permanent upgrades." or "One-time boosts and currency.")

	if #list == 0 then
		emptyState(window.content, "Nothing here yet.")
		return
	end

	for index, entry in ipairs(list) do
		local label
		if not entry.configured then
			label = "NOT SET UP"
		elseif entry.owned then
			label = "OWNED"
		elseif entry.price then
			label = entry.price .. " R$"
		else
			label = "BUY"
		end

		local _, button = Widgets.row({
			parent = window.content,
			layoutOrder = index,
			icon = isPasses and "🎟️" or "💎",
			accent = Palette.premium,
			title = entry.name,
			subtitle = entry.configured and entry.desc
				or (entry.desc .. "  —  paste the asset ID into Config/Monetization.lua"),
			buttonText = label,
			buttonColor = entry.owned and Palette.panelAlt
				or (entry.configured and Palette.premium or Palette.panelAlt),
			onClick = function()
				if not entry.configured or entry.owned then
					return
				end
				if isPasses then
					MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, entry.id)
				else
					MarketplaceService:PromptProductPurchase(Players.LocalPlayer, entry.id)
				end
			end,
		})

		if button and (entry.owned or not entry.configured) then
			Widgets.setDisabled(button, true)
		end
	end
end

-- Settings ---------------------------------------------------------------------------------

function Panels.settings(window, ctx)
	local profile = ctx.state.profile
	local prefs = profile.prefs or {}
	local stats = profile.stats or {}

	window:setSubtitle("Preferences follow your account between servers.")

	local toggles = {
		{ key = "autoEquip", name = "Auto equip better pets", desc = "Swap a new hatch in when it beats your worst equipped pet." },
		{ key = "music", name = "Music", desc = "Background music." },
		{ key = "sfx", name = "Sound effects", desc = "Hits, sells and hatches." },
		{ key = "lowGraphics", name = "Reduce effects", desc = "Fewer particles and floating numbers." },
	}

	for index, toggle in ipairs(toggles) do
		local value = prefs[toggle.key] == true
		Widgets.row({
			parent = window.content,
			layoutOrder = index,
			icon = value and "🔛" or "⭕",
			accent = value and Palette.positive or Palette.stroke,
			title = toggle.name,
			subtitle = toggle.desc,
			buttonText = value and "ON" or "OFF",
			buttonColor = value and Palette.positive or Palette.panelAlt,
			onClick = function()
				act(ctx, "setPref", { key = toggle.key, value = not value })
			end,
		})
	end

	Widgets.heading(window.content, "LIFETIME STATS", 10)

    local rows = {
		{ "Aura farmed", Format.abbreviate(stats.totalAura or 0) },
		{ "Coins earned", Format.abbreviate(stats.totalCoins or 0) },
		{ "Nodes shattered", Format.comma(stats.nodes or 0) },
		{ "Eggs hatched", Format.comma(stats.hatches or 0) },
		{ "Vault sales", Format.comma(stats.sells or 0) },
		{ "Pets fused", Format.comma(stats.fuses or 0) },
		{ "Time played", Format.duration(stats.playtime or 0) },
		{ "Times joined", Format.comma(stats.joins or 0) },
	}

	local card = Widgets.card({
		parent = window.content,
		layoutOrder = 11,
		size = UDim2.new(1, 0, 0, #rows * 24 + 16),
	})

	for index, row in ipairs(rows) do
		local line = create("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(14, 8 + (index - 1) * 24),
			Size = UDim2.new(1, -28, 0, 22),
			Parent = card,
		})

		Elements.text({
			Size = UDim2.fromScale(0.6, 1),
			Text = row[1],
			TextSize = 13,
			TextColor3 = Palette.textDim,
			Parent = line,
		})

		Elements.text({
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(1, 0),
			Size = UDim2.fromScale(0.4, 1),
			Text = row[2],
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			TextColor3 = Palette.text,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = line,
		})
	end
end

return Panels
