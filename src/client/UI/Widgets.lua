--[[ Widgets — the repeated pieces of chrome: buttons, cards, rows, chips. ]]

local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Palette = require(Shared.Modules.Palette)

local Elements = require(script.Parent.Elements)
local create = Elements.create

local Widgets = {}

local HOVER = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

--- A filled button that lifts slightly on hover and dips on press.
function Widgets.button(config)
	local base = config.color or Palette.aura

	local button = create("TextButton", {
		Name = config.name or "Button",
		BackgroundColor3 = base,
		AutoButtonColor = false,
		Size = config.size or UDim2.fromOffset(140, 38),
		Position = config.position,
		AnchorPoint = config.anchorPoint,
		LayoutOrder = config.layoutOrder,
		Font = Enum.Font.GothamBold,
		Text = config.text or "",
		TextColor3 = config.textColor or Color3.fromRGB(16, 16, 26),
		TextSize = config.textSize or 15,
		Visible = config.visible ~= false,
		Parent = config.parent,
	}, {
		Elements.corner(config.radius or 9),
		Elements.stroke(base:Lerp(Color3.new(1, 1, 1), 0.25), 1.5, 0.4),
	})

	local function tint(amount)
		TweenService:Create(button, HOVER, {
			BackgroundColor3 = base:Lerp(Color3.new(1, 1, 1), amount),
		}):Play()
	end

	button.MouseEnter:Connect(function()
		if not button:GetAttribute("Disabled") then
			tint(0.14)
		end
	end)
	button.MouseLeave:Connect(function()
		tint(0)
	end)
	button.MouseButton1Down:Connect(function()
		TweenService:Create(button, HOVER, { BackgroundColor3 = base:Lerp(Color3.new(0, 0, 0), 0.18) }):Play()
	end)
	button.MouseButton1Up:Connect(function()
		tint(0.14)
	end)

	if config.onClick then
		button.Activated:Connect(function()
			if not button:GetAttribute("Disabled") then
				config.onClick(button)
			end
		end)
	end

	return button
end

function Widgets.setDisabled(button, disabled, label)
	button:SetAttribute("Disabled", disabled)
	button.BackgroundTransparency = disabled and 0.55 or 0
	button.TextTransparency = disabled and 0.4 or 0
	if label then
		button.Text = label
	end
end

--- A rounded panel used as a list row or a grid tile.
function Widgets.card(config)
	return create("Frame", {
		Name = config.name or "Card",
		BackgroundColor3 = config.color or Palette.panelAlt,
		BackgroundTransparency = config.transparency or 0,
		Size = config.size or UDim2.new(1, 0, 0, 74),
		LayoutOrder = config.layoutOrder,
		Parent = config.parent,
	}, {
		Elements.corner(config.radius or 10),
		Elements.stroke(config.stroke or Palette.stroke, 1.2, 0.35),
	})
end

--- Icon + title + subtitle + action button, the workhorse of every menu.
function Widgets.row(config)
	local card = Widgets.card({
		parent = config.parent,
		layoutOrder = config.layoutOrder,
		size = UDim2.new(1, 0, 0, config.height or 74),
		color = config.color,
	})

	local accent = config.accent or Palette.aura

	create("Frame", {
		Name = "Accent",
		BackgroundColor3 = accent,
		Size = UDim2.new(0, 4, 1, -18),
		Position = UDim2.fromOffset(0, 9),
		BorderSizePixel = 0,
		Parent = card,
	}, { Elements.corner(2) })

	local iconHolder = create("Frame", {
		Name = "Icon",
		BackgroundColor3 = accent,
		BackgroundTransparency = 0.82,
		Size = UDim2.fromOffset(48, 48),
		Position = UDim2.new(0, 14, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Parent = card,
	}, { Elements.corner(9) })

	Elements.text({
		Name = "Glyph",
		Size = UDim2.fromScale(1, 1),
		Text = config.icon or "",
		TextSize = 24,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = iconHolder,
	})

	Elements.text({
		Name = "Title",
		Size = UDim2.new(1, -220, 0, 20),
		Position = UDim2.fromOffset(74, 14),
		Text = config.title or "",
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = config.titleColor or Palette.text,
		Parent = card,
	})

	Elements.text({
		Name = "Subtitle",
		Size = UDim2.new(1, -220, 0, 34),
		Position = UDim2.fromOffset(74, 34),
		Text = config.subtitle or "",
		TextSize = 13,
		TextColor3 = Palette.textDim,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = card,
	})

	local button
	if config.buttonText then
		button = Widgets.button({
			parent = card,
			text = config.buttonText,
			color = config.buttonColor or accent,
			size = UDim2.fromOffset(126, 38),
			position = UDim2.new(1, -14, 0.5, 0),
			anchorPoint = Vector2.new(1, 0.5),
			onClick = config.onClick,
		})
	end

	return card, button
end

--- Small pill used for currencies and multipliers on the HUD.
function Widgets.chip(config)
	local chip = create("Frame", {
		Name = config.name or "Chip",
		BackgroundColor3 = Palette.panel,
		BackgroundTransparency = 0.08,
		Size = config.size or UDim2.fromOffset(150, 38),
		LayoutOrder = config.layoutOrder,
		Parent = config.parent,
	}, {
		Elements.corner(19),
		Elements.stroke(config.accent or Palette.stroke, 1.5, 0.25),
	})

	Elements.text({
		Name = "Glyph",
		Size = UDim2.fromOffset(34, 38),
		Position = UDim2.fromOffset(8, 0),
		Text = config.icon or "",
		TextSize = 19,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = chip,
	})

	local value = Elements.text({
		Name = "Value",
		Size = UDim2.new(1, -46, 1, 0),
		Position = UDim2.fromOffset(42, 0),
		Text = config.text or "0",
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		TextColor3 = config.accent or Palette.text,
		Parent = chip,
	})

	return chip, value
end

--- Section heading inside a scrolling panel.
function Widgets.heading(parent, text, order)
	return Elements.text({
		Name = "Heading",
		Size = UDim2.new(1, 0, 0, 26),
		Text = text,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = Palette.textDim,
		LayoutOrder = order,
		Parent = parent,
	})
end

function Widgets.progressBar(config)
	local track = create("Frame", {
		Name = config.name or "Progress",
		BackgroundColor3 = Palette.background,
		Size = config.size or UDim2.new(1, 0, 0, 10),
		Position = config.position,
		AnchorPoint = config.anchorPoint,
		LayoutOrder = config.layoutOrder,
		Parent = config.parent,
	}, { Elements.corner(5), Elements.stroke(Palette.stroke, 1, 0.5) })

	local fill = create("Frame", {
		Name = "Fill",
		BackgroundColor3 = config.color or Palette.aura,
		Size = UDim2.fromScale(0, 1),
		BorderSizePixel = 0,
		Parent = track,
	}, {
		Elements.corner(5),
		Elements.gradient(
			(config.color or Palette.aura):Lerp(Color3.new(1, 1, 1), 0.35),
			config.color or Palette.aura,
			90
		),
	})

	return track, fill
end

return Widgets
