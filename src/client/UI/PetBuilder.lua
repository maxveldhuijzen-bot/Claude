--[[
	PetBuilder — procedural pet models.

	Every pet in the game is assembled from primitives here, which is why the
	roster needs no uploaded meshes. `shape` in Config/Pets picks the silhouette;
	colour and tier do the rest.

	Also provides viewport() so pet cards in the UI show the real 3D model
	instead of a flat icon.
]]

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local SettingsConfig = require(Shared.Config.Settings)
local Palette = require(Shared.Modules.Palette)

local PetBuilder = {}

local function piece(parent, size, offset, color, material, shape)
	local part = Instance.new("Part")
	part.Size = size
	part.CFrame = offset
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Massless = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth

	if shape then
		part.Shape = shape
	end

	part.Parent = parent
	return part
end

local function eyes(model, forward, spread, height, size)
	for _, side in ipairs({ -1, 1 }) do
		piece(
			model,
			Vector3.new(size, size, size),
			CFrame.new(side * spread, height, forward),
			Color3.fromRGB(18, 18, 26),
			Enum.Material.SmoothPlastic,
			Enum.PartType.Ball
		)
	end
end

local shapes = {}

function shapes.ball(model, color, accent)
	piece(model, Vector3.new(2.2, 2.2, 2.2), CFrame.new(), color, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	piece(model, Vector3.new(1.1, 1.1, 1.1), CFrame.new(0, 1.1, -0.2), accent, Enum.Material.Neon, Enum.PartType.Ball)
	eyes(model, -1.0, 0.42, 0.24, 0.34)
end

function shapes.cube(model, color, accent)
	piece(model, Vector3.new(2, 1.8, 2.1), CFrame.new(), color)
	piece(model, Vector3.new(1.5, 0.5, 1.5), CFrame.new(0, 1.1, 0), accent, Enum.Material.Neon)
	piece(model, Vector3.new(0.45, 0.9, 0.45), CFrame.new(-0.6, 1.5, 0), accent, Enum.Material.Neon)
	piece(model, Vector3.new(0.45, 0.9, 0.45), CFrame.new(0.6, 1.5, 0), accent, Enum.Material.Neon)
	eyes(model, -1.06, 0.45, 0.2, 0.3)
end

function shapes.diamond(model, color, accent)
	piece(model, Vector3.new(1.7, 1.7, 1.7), CFrame.Angles(math.rad(45), 0, math.rad(45)), color, Enum.Material.Neon)
	piece(
		model,
		Vector3.new(1.1, 1.1, 1.1),
		CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(45), math.rad(45), 0),
		accent,
		Enum.Material.Neon
	)
	piece(model, Vector3.new(0.3, 2.8, 0.3), CFrame.Angles(0, 0, math.rad(90)), accent, Enum.Material.Neon)
end

function shapes.shard(model, color, accent)
	piece(model, Vector3.new(1.1, 2.6, 1.1), CFrame.Angles(math.rad(12), math.rad(30), math.rad(10)), color, Enum.Material.Neon)
	piece(model, Vector3.new(0.6, 1.5, 0.6), CFrame.new(0.8, -0.5, 0.3) * CFrame.Angles(0, 0, math.rad(-24)), accent, Enum.Material.Neon)
	piece(model, Vector3.new(0.5, 1.2, 0.5), CFrame.new(-0.8, -0.6, -0.2) * CFrame.Angles(0, 0, math.rad(20)), accent, Enum.Material.Neon)
end

function shapes.orb(model, color, accent)
	piece(model, Vector3.new(1.9, 1.9, 1.9), CFrame.new(), color, Enum.Material.Neon, Enum.PartType.Ball)
	piece(
		model,
		Vector3.new(0.22, 3, 3),
		CFrame.Angles(0, 0, math.rad(24)),
		accent,
		Enum.Material.Neon,
		Enum.PartType.Cylinder
	)
	piece(
		model,
		Vector3.new(0.18, 2.4, 2.4),
		CFrame.Angles(math.rad(70), 0, math.rad(-16)),
		accent,
		Enum.Material.Neon,
		Enum.PartType.Cylinder
	)
end

function shapes.wisp(model, color, accent)
	piece(model, Vector3.new(1.6, 1.6, 1.6), CFrame.new(), color, Enum.Material.Neon, Enum.PartType.Ball)
	local sizes = { 1.0, 0.7, 0.45 }
	for index, size in ipairs(sizes) do
		piece(
			model,
			Vector3.new(size, size, size),
			CFrame.new(0, -0.2 * index, 0.9 * index),
			accent,
			Enum.Material.Neon,
			Enum.PartType.Ball
		)
	end
	eyes(model, -0.8, 0.34, 0.18, 0.26)
end

function shapes.prism(model, color, accent)
	piece(model, Vector3.new(1.4, 2.4, 1.4), CFrame.Angles(0, math.rad(45), 0), color, Enum.Material.Glass)
	piece(model, Vector3.new(0.9, 0.9, 0.9), CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(45), 0, math.rad(45)), accent, Enum.Material.Neon)
	piece(model, Vector3.new(1.8, 0.25, 1.8), CFrame.new(0, -1.2, 0) * CFrame.Angles(0, math.rad(45), 0), accent, Enum.Material.Neon)
end

function shapes.star(model, color, accent)
	for index = 0, 2 do
		piece(
			model,
			Vector3.new(0.5, 2.9, 0.5),
			CFrame.Angles(0, 0, math.rad(60 * index)),
			index == 0 and color or accent,
			Enum.Material.Neon
		)
	end
	piece(model, Vector3.new(1.1, 1.1, 1.1), CFrame.new(), color, Enum.Material.Neon, Enum.PartType.Ball)
end

--- Builds an unparented pet model. PrimaryPart is an invisible root, so callers
--- can PivotTo() it without the visual parts drifting.
function PetBuilder.build(definition, tier)
	tier = tier or 1

	local model = Instance.new("Model")
	model.Name = definition.id or "Pet"

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(0.2, 0.2, 0.2)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.Massless = true
	root.Parent = model
	model.PrimaryPart = root

	local color = definition.color
	local accent = Palette.rarityColor(definition.rarity)

	if tier == 2 then
		color = color:Lerp(Palette.tier[2], 0.62)
		accent = Palette.tier[2]
	elseif tier == 3 then
		color = color:Lerp(Color3.fromRGB(255, 255, 255), 0.35)
	end

	local builder = shapes[definition.shape] or shapes.ball
	builder(model, color, accent)

	-- Shapes are authored around the origin and every part stays anchored, so
	-- model:PivotTo() moves the whole pet without involving the physics solver.

	local glow = Instance.new("PointLight")
	glow.Color = accent
	glow.Brightness = tier >= 2 and 2 or 1
	glow.Range = tier >= 2 and 10 or 6
	glow.Parent = root

	model:SetAttribute("Tier", tier)
	model:SetAttribute("PetId", definition.id)

	return model
end

--- A ViewportFrame showing the real model, used on pet cards.
function PetBuilder.viewport(config)
	local frame = Instance.new("ViewportFrame")
	frame.Name = "Preview"
	frame.BackgroundColor3 = config.background or Palette.background
	frame.BackgroundTransparency = config.transparency or 0.3
	frame.Size = config.size or UDim2.fromOffset(56, 56)
	frame.Position = config.position
	frame.AnchorPoint = config.anchorPoint
	frame.LayoutOrder = config.layoutOrder
	frame.Ambient = Color3.fromRGB(190, 190, 210)
	frame.LightColor = Color3.fromRGB(255, 255, 255)
	frame.LightDirection = Vector3.new(-0.4, -1, -0.6)
	frame.ZIndex = config.zIndex or 10

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 9)
	corner.Parent = frame

	local model = PetBuilder.build(config.definition, config.tier)
	model.Parent = frame

	local camera = Instance.new("Camera")
	camera.FieldOfView = 40
	camera.CFrame = CFrame.new(Vector3.new(3.6, 2.2, 4.6), Vector3.new(0, 0.2, 0))
	camera.Parent = frame
	frame.CurrentCamera = camera

	frame.Parent = config.parent
	return frame
end

--- Rainbow tier cycles hue over time; called from PetController's render loop.
function PetBuilder.animateTier(model, clock)
	if model:GetAttribute("Tier") ~= 3 then
		return
	end

	local hue = (clock * 0.25) % 1
	local color = Color3.fromHSV(hue, 0.72, 1)

	for _, part in ipairs(model:GetChildren()) do
		if part:IsA("BasePart") and part.Name ~= "Root" and part.Material == Enum.Material.Neon then
			part.Color = color
		end
	end
end

PetBuilder.MaxSlots = SettingsConfig.MaxPetSlots

return PetBuilder
