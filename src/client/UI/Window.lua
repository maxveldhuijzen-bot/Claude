--[[
	Window — the panel shell every menu is built inside.

	Handles the backdrop, header, optional tab strip, scrolling body and the
	open/close animation, so a panel module only has to fill rows in.
]]

local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Palette = require(Shared.Modules.Palette)
local Signal = require(Shared.Modules.Signal)

local Elements = require(script.Parent.Elements)
local Widgets = require(script.Parent.Widgets)
local create = Elements.create

local OPEN_TWEEN = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local CLOSE_TWEEN = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local Window = {}
Window.__index = Window

function Window.new(parent, config)
	local self = setmetatable({}, Window)

	self.name = config.name
	self.accent = config.accent or Palette.aura
	self.isOpen = false
	self.opened = Signal.new()
	self.tabChanged = Signal.new()
	self.activeTab = nil

	local width = config.width or 520
	local height = config.height or 420

	self.backdrop = create("TextButton", {
		Name = config.name .. "Backdrop",
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.55,
		Size = UDim2.fromScale(1, 1),
		Text = "",
		AutoButtonColor = false,
		Visible = false,
		ZIndex = 8,
		Parent = parent,
	})

	self.frame = create("Frame", {
		Name = config.name,
		BackgroundColor3 = Palette.panel,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(width, height),
		ZIndex = 9,
		Parent = self.backdrop,
	}, {
		Elements.corner(16),
		Elements.stroke(self.accent, 2, 0.3),
		create("UISizeConstraint", { MaxSize = Vector2.new(width, height) }),
	})

	-- Header ---------------------------------------------------------------
	local header = create("Frame", {
		Name = "Header",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 62),
		ZIndex = 9,
		Parent = self.frame,
	})

	Elements.text({
		Name = "Title",
		Size = UDim2.new(1, -70, 0, 26),
		Position = UDim2.fromOffset(20, 12),
		Text = config.title,
		Font = Enum.Font.GothamBold,
		TextSize = 20,
		TextColor3 = self.accent,
		ZIndex = 9,
		Parent = header,
	})

	self.subtitle = Elements.text({
		Name = "Subtitle",
		Size = UDim2.new(1, -70, 0, 18),
		Position = UDim2.fromOffset(20, 36),
		Text = config.subtitle or "",
		TextSize = 13,
		TextColor3 = Palette.textDim,
		ZIndex = 9,
		Parent = header,
	})

	Widgets.button({
		parent = header,
		name = "Close",
		text = "✕",
		color = Palette.panelAlt,
		textColor = Palette.text,
		size = UDim2.fromOffset(34, 34),
		position = UDim2.new(1, -16, 0, 14),
		anchorPoint = Vector2.new(1, 0),
		radius = 17,
		onClick = function()
			self:close()
		end,
	}).ZIndex = 10

	-- Tabs -------------------------------------------------------------------
	self.tabBar = create("Frame", {
		Name = "Tabs",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -32, 0, 34),
		Position = UDim2.fromOffset(16, 62),
		Visible = false,
		ZIndex = 9,
		Parent = self.frame,
	}, { Elements.list(6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left) })

	-- Body -------------------------------------------------------------------
	self.content = create("ScrollingFrame", {
		Name = "Content",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(16, 70),
		Size = UDim2.new(1, -32, 1, -86),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = self.accent,
		ScrollBarImageTransparency = 0.4,
		ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
		ZIndex = 9,
		Parent = self.frame,
	}, {
		Elements.list(8),
		Elements.padding(2, { PaddingRight = UDim.new(0, 8) }),
	})

	self.backdrop.Activated:Connect(function()
		self:close()
	end)

	return self
end

--- tabs: { { id = "collectors", name = "Collectors" }, ... }
function Window:setTabs(tabs)
	for _, child in ipairs(self.tabBar:GetChildren()) do
		if child:IsA("GuiButton") then
			child:Destroy()
		end
	end

	self.tabButtons = {}
	self.tabBar.Visible = #tabs > 0

	self.content.Position = UDim2.fromOffset(16, #tabs > 0 and 104 or 70)
	self.content.Size = UDim2.new(1, -32, 1, #tabs > 0 and -120 or -86)

	for index, tab in ipairs(tabs) do
		local button = Widgets.button({
			parent = self.tabBar,
			name = tab.id,
			text = tab.name,
			color = Palette.panelAlt,
			textColor = Palette.textDim,
			size = UDim2.fromOffset(math.max(78, #tab.name * 9 + 22), 32),
			layoutOrder = index,
			radius = 8,
			onClick = function()
				self:selectTab(tab.id)
			end,
		})
		button.ZIndex = 10
		self.tabButtons[tab.id] = button
	end

	if tabs[1] then
		self:selectTab(tabs[1].id)
	end
end

function Window:selectTab(id)
	if not self.tabButtons then
		return
	end

	self.activeTab = id

	for tabId, button in pairs(self.tabButtons) do
		local active = tabId == id
		button.BackgroundColor3 = active and self.accent or Palette.panelAlt
		button.TextColor3 = active and Color3.fromRGB(16, 16, 26) or Palette.textDim
	end

	self.tabChanged:Fire(id)
end

function Window:setSubtitle(text)
	self.subtitle.Text = text
end

--- Clears the body. Panels rebuild rather than diff — these lists are small and
--- rebuilding removes a whole class of stale-state bug.
function Window:clear()
	for _, child in ipairs(self.content:GetChildren()) do
		if not child:IsA("UILayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

function Window:open()
	if self.isOpen then
		return
	end

	self.isOpen = true
	self.backdrop.Visible = true
	self.backdrop.BackgroundTransparency = 1
	self.frame.Size = UDim2.fromOffset(self.frame.AbsoluteSize.X * 0.85, self.frame.AbsoluteSize.Y * 0.85)

	local target = self.frame:FindFirstChildOfClass("UISizeConstraint").MaxSize

	TweenService:Create(self.backdrop, OPEN_TWEEN, { BackgroundTransparency = 0.55 }):Play()
	TweenService:Create(self.frame, OPEN_TWEEN, { Size = UDim2.fromOffset(target.X, target.Y) }):Play()

	self.opened:Fire()
end

function Window:close()
	if not self.isOpen then
		return
	end

	self.isOpen = false

	local tween = TweenService:Create(self.frame, CLOSE_TWEEN, {
		Size = UDim2.fromOffset(self.frame.AbsoluteSize.X * 0.9, self.frame.AbsoluteSize.Y * 0.9),
	})
	TweenService:Create(self.backdrop, CLOSE_TWEEN, { BackgroundTransparency = 1 }):Play()
	tween:Play()

	tween.Completed:Once(function()
		if not self.isOpen then
			self.backdrop.Visible = false
		end
	end)
end

function Window:toggle()
	if self.isOpen then
		self:close()
	else
		self:open()
	end
end

return Window
