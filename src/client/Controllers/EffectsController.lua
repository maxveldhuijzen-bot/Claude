--[[
	EffectsController — toasts, floating numbers and the hatch reveal.

	All feedback the player gets from a server event lands here, so timing and
	styling stay consistent across features.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Palette = require(Shared.Modules.Palette)
local Format = require(Shared.Modules.Format)
local Pets = require(Shared.Config.Pets)
local Eggs = require(Shared.Config.Eggs)
local Net = require(Shared.Modules.Net)

local UI = script.Parent.Parent.UI
local Elements = require(UI.Elements)
local Widgets = require(UI.Widgets)
local PetBuilder = require(UI.PetBuilder)
local create = Elements.create

local player = Players.LocalPlayer

local EffectsController = {}

local screen
local toastHolder
local hatchOverlay
local activeToasts = 0

local KIND_COLORS = {
	good = Palette.positive,
	bad = Palette.negative,
	info = Palette.aura,
	premium = Palette.premium,
}

-- Toasts ---------------------------------------------------------------------

local function showToast(message)
	if activeToasts > 5 then
		return
	end
	activeToasts += 1

	local accent = KIND_COLORS[message.kind] or Palette.aura

	local card = create("Frame", {
		Name = "Toast",
		BackgroundColor3 = Palette.panel,
		Size = UDim2.new(1, 0, 0, message.body and 62 or 42),
		Position = UDim2.fromOffset(40, 0),
		BackgroundTransparency = 1,
		LayoutOrder = -os.clock() * 100,
		Parent = toastHolder,
	}, {
		Elements.corner(10),
		Elements.stroke(accent, 1.5, 0.25),
	})

	create("Frame", {
		Name = "Accent",
		BackgroundColor3 = accent,
		Size = UDim2.new(0, 4, 1, -14),
		Position = UDim2.fromOffset(0, 7),
		BorderSizePixel = 0,
		Parent = card,
	}, { Elements.corner(2) })

	local title = Elements.text({
		Name = "Title",
		Size = UDim2.new(1, -24, 0, 20),
		Position = UDim2.fromOffset(16, message.body and 10 or 11),
		Text = message.title or "",
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		TextColor3 = accent,
		TextTransparency = 1,
		Parent = card,
	})

	local body
	if message.body then
		body = Elements.text({
			Name = "Body",
			Size = UDim2.new(1, -24, 0, 30),
			Position = UDim2.fromOffset(16, 28),
			Text = message.body,
			TextSize = 13,
			TextColor3 = Palette.textDim,
			TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextTransparency = 1,
			Parent = card,
		})
	end

	local enter = TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	TweenService:Create(card, enter, { Position = UDim2.fromOffset(0, 0), BackgroundTransparency = 0.05 }):Play()
	TweenService:Create(title, enter, { TextTransparency = 0 }):Play()
	if body then
		TweenService:Create(body, enter, { TextTransparency = 0 }):Play()
	end

	task.delay(message.duration or 3.4, function()
		local exit = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		TweenService:Create(card, exit, { Position = UDim2.fromOffset(50, 0), BackgroundTransparency = 1 }):Play()
		TweenService:Create(title, exit, { TextTransparency = 1 }):Play()
		if body then
			TweenService:Create(body, exit, { TextTransparency = 1 }):Play()
		end
		task.wait(0.22)
		card:Destroy()
		activeToasts -= 1
	end)
end

-- Floating combat text -------------------------------------------------------

local floaters = {}

local function floatText(worldPart, text, color, size)
	if not worldPart or not worldPart.Parent then
		return
	end

	local gui = create("BillboardGui", {
		Name = "Floater",
		Adornee = worldPart,
		Size = UDim2.fromScale(8, 3),
		StudsOffsetWorldSpace = Vector3.new(math.random(-15, 15) / 10, 3, 0),
		AlwaysOnTop = true,
		MaxDistance = 120,
		LightInfluence = 0,
		Parent = worldPart,
	})

	local label = Elements.text({
		Size = UDim2.fromScale(1, 1),
		Text = text,
		Font = Enum.Font.GothamBlack,
		TextSize = size or 26,
		TextColor3 = color,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextStrokeTransparency = 0.3,
		Parent = gui,
	})

	table.insert(floaters, {
		gui = gui,
		label = label,
		born = os.clock(),
		life = 0.85,
		base = gui.StudsOffsetWorldSpace,
	})
end

local function stepFloaters()
	local now = os.clock()

	for index = #floaters, 1, -1 do
		local floater = floaters[index]
		local alpha = (now - floater.born) / floater.life

		if alpha >= 1 or not floater.gui.Parent then
			floater.gui:Destroy()
			table.remove(floaters, index)
		else
			floater.gui.StudsOffsetWorldSpace = floater.base + Vector3.new(0, alpha * 4.5, 0)
			floater.label.TextTransparency = alpha ^ 2
			floater.label.TextStrokeTransparency = 0.3 + alpha * 0.7
		end
	end
end

-- Hatch reveal ---------------------------------------------------------------

local function revealHatch(payload)
	local egg = Eggs.get(payload.egg)
	if not egg then
		return
	end

	hatchOverlay.Visible = true
	hatchOverlay.BackgroundTransparency = 1

	for _, child in ipairs(hatchOverlay:GetChildren()) do
		child:Destroy()
	end

	TweenService:Create(hatchOverlay, TweenInfo.new(0.2), { BackgroundTransparency = 0.35 }):Play()

	-- Stage one: the egg shakes.
	local eggFrame = create("Frame", {
		Name = "Egg",
		BackgroundColor3 = egg.color,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.46),
		Size = UDim2.fromOffset(120, 150),
		Parent = hatchOverlay,
	}, {
		Elements.corner(70),
		Elements.stroke(Color3.new(1, 1, 1), 3, 0.5),
	})

	local caption = Elements.text({
		Name = "Caption",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.66),
		Size = UDim2.fromOffset(400, 30),
		Text = egg.name,
		Font = Enum.Font.GothamBold,
		TextSize = 20,
		TextColor3 = Palette.text,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = hatchOverlay,
	})

	local duration = math.max(0.5, payload.hatchTime or 1.6)
	local shakeStart = os.clock()

	while os.clock() - shakeStart < duration do
		local swing = math.sin((os.clock() - shakeStart) * 26) * 9
		eggFrame.Rotation = swing
		eggFrame.Size = UDim2.fromOffset(120 + math.abs(swing), 150 - math.abs(swing) * 0.5)
		task.wait()
	end

	eggFrame:Destroy()

	-- Stage two: the results.
	local results = payload.results or {}
	caption.Text = #results > 1 and (#results .. " pets hatched") or "You hatched"
	caption.Position = UDim2.fromScale(0.5, 0.22)

	local grid = create("Frame", {
		Name = "Results",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromOffset(math.min(#results, 4) * 132, math.ceil(#results / 4) * 152),
		Parent = hatchOverlay,
	}, { Elements.grid(UDim2.fromOffset(124, 144), UDim2.fromOffset(8, 8)) })

	for index, result in ipairs(results) do
		local definition = Pets.get(result.id)
		if definition then
			local rarityColor = Palette.rarityColor(result.rarity)

			local card = Widgets.card({
				parent = grid,
				layoutOrder = index,
				size = UDim2.fromOffset(124, 144),
				stroke = rarityColor,
			})
			card.BackgroundTransparency = 0.1

			PetBuilder.viewport({
				parent = card,
				definition = definition,
				tier = result.tier,
				size = UDim2.fromOffset(78, 78),
				position = UDim2.new(0.5, 0, 0, 10),
				anchorPoint = Vector2.new(0.5, 0),
			})

			Elements.text({
				Size = UDim2.new(1, -8, 0, 18),
				Position = UDim2.fromOffset(4, 92),
				Text = definition.name,
				Font = Enum.Font.GothamBold,
				TextSize = 13,
				TextColor3 = Palette.text,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = card,
			})

			Elements.text({
				Size = UDim2.new(1, -8, 0, 16),
				Position = UDim2.fromOffset(4, 110),
				Text = result.rarity,
				TextSize = 12,
				TextColor3 = rarityColor,
				TextXAlignment = Enum.TextXAlignment.Center,
				Parent = card,
			})

			Elements.text({
				Size = UDim2.new(1, -8, 0, 16),
				Position = UDim2.fromOffset(4, 124),
				Text = result.isNew and "NEW!" or ("+" .. Format.multiplier(definition.mult) .. " aura"),
				TextSize = 11,
				TextColor3 = result.isNew and Palette.positive or Palette.textDim,
				TextXAlignment = Enum.TextXAlignment.Center,
				Parent = card,
			})

			card.Size = UDim2.fromOffset(0, 0)
			TweenService:Create(
				card,
				TweenInfo.new(0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, index * 0.05),
				{ Size = UDim2.fromOffset(124, 144) }
			):Play()
		end
	end

	Widgets.button({
		parent = hatchOverlay,
		text = "Continue",
		color = Palette.aura,
		size = UDim2.fromOffset(180, 42),
		position = UDim2.fromScale(0.5, 0.82),
		anchorPoint = Vector2.new(0.5, 0.5),
		onClick = function()
			hatchOverlay.Visible = false
		end,
	})

	task.delay(3.2, function()
		if hatchOverlay.Visible then
			hatchOverlay.Visible = false
		end
	end)
end

-- Event routing --------------------------------------------------------------

local function onEffect(payload)
	if type(payload) ~= "table" then
		return
	end

	if payload.kind == "swing" then
		floatText(
			payload.node,
			"+" .. Format.abbreviate(payload.amount),
			payload.broke and Palette.coins or Palette.aura,
			payload.broke and 34 or 24
		)
	elseif payload.kind == "sell" then
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root then
			floatText(root, "+" .. Format.abbreviate(payload.coins) .. " coins", Palette.coins, 30)
		end
	elseif payload.kind == "hatch" then
		task.spawn(revealHatch, payload)
	elseif payload.kind == "rebirth" then
		showToast({
			title = "REBIRTH " .. payload.rebirths,
			body = "+" .. payload.prisms .. " prisms",
			kind = "premium",
			duration = 5,
		})
	end
end

function EffectsController.init()
	screen = create("ScreenGui", {
		Name = "AuraEffects",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 20,
		Parent = player:WaitForChild("PlayerGui"),
	})

	toastHolder = create("Frame", {
		Name = "Toasts",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 16),
		Size = UDim2.fromOffset(280, 400),
		Parent = screen,
	}, { Elements.list(8, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Right) })

	hatchOverlay = create("Frame", {
		Name = "Hatch",
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.35,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 30,
		Parent = screen,
	})

	Net.listen("Notify", showToast)
	Net.listen("Effect", onEffect)
end

function EffectsController.start()
	RunService.RenderStepped:Connect(stepFloaters)
end

EffectsController.toast = showToast

return EffectsController
