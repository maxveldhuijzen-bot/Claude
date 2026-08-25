--[[
	WorldService — builds the entire map at runtime.

	Nothing in this game ships as a saved model: platforms, nodes, vaults, egg
	stands, kiosks, bridges and signage are all generated here from Config/Zones.
	Adding a zone is a config edit, and the place file stays tiny.

	Interactables are tagged with CollectionService so the client can bind
	ProximityPrompt handling locally — opening a shop panel needs no remote call.
]]

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Settings = require(Shared.Config.Settings)
local Zones = require(Shared.Config.Zones)
local Eggs = require(Shared.Config.Eggs)
local Format = require(Shared.Modules.Format)

local WorldService = {}
local Services

WorldService.nodes = {}
WorldService.nodesByPart = {}
WorldService.vaults = {}

local worldRoot

-- Building blocks ----------------------------------------------------------

local function part(props)
	local instance = Instance.new("Part")
	instance.Anchored = true
	instance.CanCollide = props.canCollide ~= false
	instance.CastShadow = props.castShadow ~= false
	instance.Material = props.material or Enum.Material.SmoothPlastic
	instance.Size = props.size or Vector3.new(4, 4, 4)
	instance.CFrame = props.cframe or CFrame.new(props.position or Vector3.zero)
	instance.Color = props.color or Color3.fromRGB(200, 200, 200)
	instance.Transparency = props.transparency or 0
	instance.Name = props.name or "Part"
	instance.TopSurface = Enum.SurfaceType.Smooth
	instance.BottomSurface = Enum.SurfaceType.Smooth

	if props.shape then
		instance.Shape = props.shape
	end

	instance.Parent = props.parent
	return instance
end

local function billboard(adornee, text, subtext, color, offsetY, size)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Sign"
	gui.Adornee = adornee
	gui.Size = size or UDim2.fromScale(14, 4.5)
	gui.StudsOffsetWorldSpace = Vector3.new(0, offsetY or 6, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 180
	gui.LightInfluence = 0

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.fromScale(1, subtext and 0.58 or 1)
	title.Font = Enum.Font.GothamBold
	title.Text = text
	title.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.TextStrokeTransparency = 0.35
	title.Name = "Title"
	title.Parent = gui

	if subtext then
		local body = Instance.new("TextLabel")
		body.BackgroundTransparency = 1
		body.Position = UDim2.fromScale(0, 0.58)
		body.Size = UDim2.fromScale(1, 0.42)
		body.Font = Enum.Font.Gotham
		body.Text = subtext
		body.TextColor3 = Color3.fromRGB(226, 232, 255)
		body.TextScaled = true
		body.TextStrokeTransparency = 0.5
		body.Name = "Body"
		body.Parent = gui
	end

	gui.Parent = adornee
	return gui
end

local function prompt(parent, actionText, objectText, uiTarget, extra)
	local instance = Instance.new("ProximityPrompt")
	instance.ActionText = actionText
	instance.ObjectText = objectText
	instance.HoldDuration = 0
	instance.MaxActivationDistance = 14
	instance.RequiresLineOfSight = false
	instance:SetAttribute("UiTarget", uiTarget)

	if extra then
		for key, value in pairs(extra) do
			instance:SetAttribute(key, value)
		end
	end

	instance.Parent = parent
	return instance
end

-- Nodes ---------------------------------------------------------------------

local function nodePositions(zone)
	local positions = {}
	local generator = Random.new(zone.order * 7717 + 13)
	local count = zone.nodeCount

	for index = 1, count do
		local angle = (index / count) * math.pi * 2 + zone.order
		local radius = 58 + (index % 3) * 11
		local jitter = generator:NextNumber(-5, 5)
		table.insert(
			positions,
			zone.origin
				+ Vector3.new(math.cos(angle) * radius + jitter, 7.5, math.sin(angle) * radius + jitter)
		)
	end

	return positions
end

local function buildNode(zone, position, parent, index)
	local model = Instance.new("Model")
	model.Name = string.format("Node_%s_%d", zone.id, index)

	local core = part({
		name = "Core",
		size = Vector3.new(4.4, 7.6, 4.4),
		cframe = CFrame.new(position) * CFrame.Angles(0, math.rad(45), math.rad(8)),
		color = zone.node,
		material = Enum.Material.Neon,
		canCollide = false,
		parent = model,
	})

	part({
		name = "Shard",
		size = Vector3.new(2.2, 3.4, 2.2),
		cframe = CFrame.new(position + Vector3.new(0, 5.6, 0)) * CFrame.Angles(0, math.rad(30), math.rad(-14)),
		color = zone.accent,
		material = Enum.Material.Neon,
		canCollide = false,
		castShadow = false,
		parent = model,
	})

	part({
		name = "Base",
		size = Vector3.new(6.5, 1, 6.5),
		position = position - Vector3.new(0, 4.2, 0),
		color = zone.accent,
		material = Enum.Material.Slate,
		canCollide = false,
		parent = model,
	})

	local light = Instance.new("PointLight")
	light.Color = zone.node
	light.Range = 18
	light.Brightness = 2
	light.Parent = core

	core:SetAttribute("MaxHp", zone.nodeHp)
	core:SetAttribute("Hp", zone.nodeHp)
	core:SetAttribute("Zone", zone.id)

	model.PrimaryPart = core
	model.Parent = parent

	CollectionService:AddTag(core, "AuraNode")

	local node = {
		part = core,
		model = model,
		zone = zone,
		hp = zone.nodeHp,
		maxHp = zone.nodeHp,
		alive = true,
		respawnAt = 0,
		position = position,
	}

	table.insert(WorldService.nodes, node)
	WorldService.nodesByPart[core] = node
	return node
end

-- Structures ----------------------------------------------------------------

local function buildVault(zone, parent)
	local base = zone.origin + Vector3.new(0, 0, 42)

	local pad = part({
		name = "VaultPad",
		size = Vector3.new(26, 1.4, 26),
		position = base + Vector3.new(0, 0.7, 0),
		color = zone.accent,
		material = Enum.Material.Neon,
		transparency = 0.25,
		canCollide = false,
		parent = parent,
	})

	part({
		name = "VaultPlinth",
		size = Vector3.new(30, 2, 30),
		position = base,
		color = Color3.fromRGB(38, 40, 60),
		material = Enum.Material.Slate,
		parent = parent,
	})

	for _, offset in ipairs({ Vector3.new(-13, 0, -13), Vector3.new(13, 0, -13), Vector3.new(-13, 0, 13), Vector3.new(13, 0, 13) }) do
		part({
			name = "VaultPylon",
			size = Vector3.new(2.4, 14, 2.4),
			position = base + offset + Vector3.new(0, 7, 0),
			color = Color3.fromRGB(52, 56, 84),
			material = Enum.Material.Metal,
			parent = parent,
		})
		part({
			name = "VaultLamp",
			size = Vector3.new(3, 1.6, 3),
			position = base + offset + Vector3.new(0, 14.6, 0),
			color = zone.accent,
			material = Enum.Material.Neon,
			castShadow = false,
			parent = parent,
		})
	end

	billboard(pad, "AURA VAULT", "Stand here to sell", zone.accent, 11, UDim2.fromScale(18, 5))
	CollectionService:AddTag(pad, "Vault")
	pad:SetAttribute("Zone", zone.id)

	table.insert(WorldService.vaults, { zone = zone, part = pad, position = base })
	return pad
end

local function buildEggStand(zone, parent)
	local egg = Eggs.get(zone.id)
	if not egg then
		return nil
	end

	local base = zone.origin + Vector3.new(-46, 0, -8)

	part({
		name = "EggPlinth",
		size = Vector3.new(14, 3, 14),
		position = base + Vector3.new(0, 1.5, 0),
		color = Color3.fromRGB(44, 46, 70),
		material = Enum.Material.Slate,
		parent = parent,
	})

	local shell = part({
		name = "EggShell",
		shape = Enum.PartType.Ball,
		size = Vector3.new(9, 11, 9),
		position = base + Vector3.new(0, 9, 0),
		color = egg.color,
		material = Enum.Material.Neon,
		canCollide = false,
		parent = parent,
	})

	billboard(
		shell,
		egg.name,
		Format.abbreviate(egg.cost) .. " coins",
		egg.color,
		8,
		UDim2.fromScale(16, 5)
	)
	prompt(shell, "Open", egg.name, "eggs", { Egg = egg.id })
	CollectionService:AddTag(shell, "EggStand")
	shell:SetAttribute("Egg", egg.id)

	return shell
end

local function buildKiosk(zone, parent)
	local base = zone.origin + Vector3.new(46, 0, -8)

	part({
		name = "KioskPlinth",
		size = Vector3.new(14, 3, 14),
		position = base + Vector3.new(0, 1.5, 0),
		color = Color3.fromRGB(44, 46, 70),
		material = Enum.Material.Slate,
		parent = parent,
	})

	local board = part({
		name = "KioskBoard",
		size = Vector3.new(12, 9, 1.4),
		position = base + Vector3.new(0, 8, 0),
		color = Color3.fromRGB(30, 32, 52),
		material = Enum.Material.Metal,
		parent = parent,
	})

	part({
		name = "KioskGlow",
		size = Vector3.new(12.4, 0.8, 1.8),
		position = base + Vector3.new(0, 12.8, 0),
		color = zone.accent,
		material = Enum.Material.Neon,
		castShadow = false,
		parent = parent,
	})

	billboard(board, "UPGRADES", "Collectors and backpacks", zone.accent, 7, UDim2.fromScale(16, 5))
	prompt(board, "Browse", "Upgrade Kiosk", "shop")
	CollectionService:AddTag(board, "Kiosk")

	return board
end

local function buildRebirthAltar(zone, parent)
	local base = zone.origin + Vector3.new(0, 0, -52)

	part({
		name = "AltarBase",
		size = Vector3.new(20, 2, 20),
		position = base + Vector3.new(0, 1, 0),
		color = Color3.fromRGB(36, 34, 58),
		material = Enum.Material.Slate,
		parent = parent,
	})

	for step = 1, 3 do
		part({
			name = "AltarStep",
			size = Vector3.new(20 - step * 4, 1.6, 20 - step * 4),
			position = base + Vector3.new(0, 1 + step * 1.4, 0),
			color = Color3.fromRGB(46, 44, 72),
			material = Enum.Material.Slate,
			parent = parent,
		})
	end

	local crystal = part({
		name = "RebirthCrystal",
		size = Vector3.new(5, 9, 5),
		cframe = CFrame.new(base + Vector3.new(0, 11, 0)) * CFrame.Angles(0, math.rad(45), 0),
		color = Color3.fromRGB(96, 232, 255),
		material = Enum.Material.Neon,
		canCollide = false,
		parent = parent,
	})

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(96, 232, 255)
	light.Range = 26
	light.Brightness = 3
	light.Parent = crystal

	billboard(crystal, "REBIRTH", "Trade coins for permanent power", Color3.fromRGB(96, 232, 255), 8, UDim2.fromScale(20, 5))
	prompt(crystal, "Open", "Rebirth Altar", "rebirth")
	CollectionService:AddTag(crystal, "RebirthAltar")

	return crystal
end

local function buildZoneSign(zone, parent)
	local anchor = part({
		name = "ZoneSign",
		size = Vector3.new(3, 22, 3),
		position = zone.origin + Vector3.new(0, 11, 96),
		color = Color3.fromRGB(34, 36, 56),
		material = Enum.Material.Metal,
		parent = parent,
	})

	billboard(
		anchor,
		string.format("%d. %s", zone.order, zone.name:upper()),
		zone.tagline,
		zone.accent,
		14,
		UDim2.fromScale(26, 6)
	)

	return anchor
end

local function buildPlatform(zone, parent)
	local half = Settings.PlatformSize / 2

	part({
		name = "Ground",
		size = Vector3.new(Settings.PlatformSize, 8, Settings.PlatformSize),
		position = zone.origin - Vector3.new(0, 4, 0),
		color = zone.ground,
		material = Enum.Material.SmoothPlastic,
		parent = parent,
	})

	part({
		name = "Trim",
		size = Vector3.new(Settings.PlatformSize + 8, 2, Settings.PlatformSize + 8),
		position = zone.origin - Vector3.new(0, 9, 0),
		color = zone.accent,
		material = Enum.Material.Neon,
		castShadow = false,
		parent = parent,
	})

	part({
		name = "Underside",
		size = Vector3.new(Settings.PlatformSize - 40, 44, Settings.PlatformSize - 40),
		position = zone.origin - Vector3.new(0, 32, 0),
		color = Color3.fromRGB(28, 28, 44),
		material = Enum.Material.Slate,
		parent = parent,
	})

	for index = 1, 8 do
		local angle = (index / 8) * math.pi * 2
		local position = zone.origin + Vector3.new(math.cos(angle) * (half - 12), 9, math.sin(angle) * (half - 12))
		part({
			name = "Pylon",
			size = Vector3.new(3, 18, 3),
			position = position,
			color = Color3.fromRGB(40, 42, 64),
			material = Enum.Material.Metal,
			parent = parent,
		})
		part({
			name = "PylonCap",
			size = Vector3.new(4, 1.6, 4),
			position = position + Vector3.new(0, 9.6, 0),
			color = zone.accent,
			material = Enum.Material.Neon,
			castShadow = false,
			parent = parent,
		})
	end
end

local function buildBridge(zone, nextZone, parent)
	local half = Settings.PlatformSize / 2
	local startX = zone.origin.X + half
	local endX = nextZone.origin.X - half
	local length = endX - startX
	local midX = (startX + endX) / 2

	part({
		name = "Bridge",
		size = Vector3.new(length, 2, 26),
		position = Vector3.new(midX, -1, 0),
		color = Color3.fromRGB(52, 54, 80),
		material = Enum.Material.Metal,
		parent = parent,
	})

	for _, side in ipairs({ -13, 13 }) do
		part({
			name = "BridgeRail",
			size = Vector3.new(length, 1.2, 1.2),
			position = Vector3.new(midX, 1.4, side),
			color = nextZone.accent,
			material = Enum.Material.Neon,
			castShadow = false,
			parent = parent,
		})
	end

	-- The barrier is cosmetic; ZoneService is what actually keeps players out,
	-- so no movement exploit can walk past it.
	local barrier = part({
		name = "ZoneGate",
		size = Vector3.new(2, 22, 26),
		position = Vector3.new(endX - 6, 10, 0),
		color = nextZone.accent,
		material = Enum.Material.ForceField,
		transparency = 0.4,
		canCollide = false,
		castShadow = false,
		parent = parent,
	})

	barrier:SetAttribute("Zone", nextZone.id)
	barrier:SetAttribute("Cost", nextZone.unlockCost)
	barrier:SetAttribute("RebirthReq", nextZone.rebirthReq)

	local requirement = nextZone.requiresPass and "VIP gamepass"
		or (Format.abbreviate(nextZone.unlockCost) .. " coins")
	local extra = nextZone.rebirthReq > 0 and (" + " .. nextZone.rebirthReq .. " rebirths") or ""

	billboard(
		barrier,
		nextZone.name:upper(),
		"Unlock: " .. requirement .. extra,
		nextZone.accent,
		13,
		UDim2.fromScale(22, 5.5)
	)
	prompt(barrier, "Unlock", nextZone.name, "zones", { Zone = nextZone.id })
	CollectionService:AddTag(barrier, "ZoneGate")
end

local function buildLeaderboards(parent)
	local zone = Zones.first()
	local boards = {
		{ key = "rebirths", title = "MOST REBIRTHS", offset = Vector3.new(-34, 0, -96) },
		{ key = "aura", title = "MOST AURA FARMED", offset = Vector3.new(34, 0, -96) },
	}

	for _, definition in ipairs(boards) do
		local base = zone.origin + definition.offset

		part({
			name = "BoardStand",
			size = Vector3.new(4, 8, 4),
			position = base + Vector3.new(0, 4, 0),
			color = Color3.fromRGB(34, 36, 56),
			material = Enum.Material.Metal,
			parent = parent,
		})

		local board = part({
			name = "Leaderboard_" .. definition.key,
			size = Vector3.new(26, 22, 1.4),
			position = base + Vector3.new(0, 19, 0),
			color = Color3.fromRGB(20, 21, 34),
			material = Enum.Material.SmoothPlastic,
			parent = parent,
		})

		local surface = Instance.new("SurfaceGui")
		surface.Name = "Display"
		surface.Face = Enum.NormalId.Front
		surface.CanvasSize = Vector2.new(520, 440)
		surface.LightInfluence = 0
		surface.Adornee = board

		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 4)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = surface

		local padding = Instance.new("UIPadding")
		padding.PaddingTop = UDim.new(0, 10)
		padding.PaddingLeft = UDim.new(0, 12)
		padding.PaddingRight = UDim.new(0, 12)
		padding.Parent = surface

		local header = Instance.new("TextLabel")
		header.Name = "Header"
		header.BackgroundTransparency = 1
		header.Size = UDim2.new(1, 0, 0, 46)
		header.Font = Enum.Font.GothamBold
		header.Text = definition.title
		header.TextColor3 = zone.accent
		header.TextScaled = true
		header.LayoutOrder = 0
		header.Parent = surface

		surface.Parent = board
		board:SetAttribute("Board", definition.key)
		CollectionService:AddTag(board, "Leaderboard")
	end
end

local function buildSpawn(parent)
	local zone = Zones.first()

	local spawnPart = Instance.new("SpawnLocation")
	spawnPart.Name = "MainSpawn"
	spawnPart.Anchored = true
	spawnPart.CanCollide = true
	spawnPart.Size = Vector3.new(24, 1.6, 24)
	spawnPart.Position = zone.origin + Vector3.new(0, 0.8, 92)
	spawnPart.Color = zone.accent
	spawnPart.Material = Enum.Material.Neon
	spawnPart.Neutral = true
	spawnPart.Duration = 0
	spawnPart.TopSurface = Enum.SurfaceType.Smooth
	spawnPart.Parent = parent

	return spawnPart
end

local function configureLighting()
	Lighting.Ambient = Color3.fromRGB(88, 90, 110)
	Lighting.OutdoorAmbient = Color3.fromRGB(118, 122, 150)
	Lighting.Brightness = 2.4
	Lighting.ClockTime = 15.6
	Lighting.GeographicLatitude = 12
	Lighting.ExposureCompensation = 0.15
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.6
	Lighting.GlobalShadows = true
	Lighting.FogStart = 260
	Lighting.FogEnd = 1600
	Lighting.FogColor = Color3.fromRGB(150, 168, 210)

	if not Lighting:FindFirstChildOfClass("Atmosphere") then
		local atmosphere = Instance.new("Atmosphere")
		atmosphere.Density = 0.28
		atmosphere.Offset = 0.1
		atmosphere.Color = Color3.fromRGB(199, 209, 233)
		atmosphere.Decay = Color3.fromRGB(106, 112, 145)
		atmosphere.Glare = 0.2
		atmosphere.Haze = 1.2
		atmosphere.Parent = Lighting
	end

	if not Lighting:FindFirstChildOfClass("BloomEffect") then
		local bloom = Instance.new("BloomEffect")
		bloom.Intensity = 0.75
		bloom.Size = 26
		bloom.Threshold = 1.1
		bloom.Parent = Lighting
	end

	if not Lighting:FindFirstChildOfClass("ColorCorrectionEffect") then
		local correction = Instance.new("ColorCorrectionEffect")
		correction.Saturation = 0.12
		correction.Contrast = 0.08
		correction.TintColor = Color3.fromRGB(255, 252, 250)
		correction.Parent = Lighting
	end

	if not Lighting:FindFirstChildOfClass("SunRaysEffect") then
		local rays = Instance.new("SunRaysEffect")
		rays.Intensity = 0.06
		rays.Spread = 0.4
		rays.Parent = Lighting
	end
end

-- Lifecycle ------------------------------------------------------------------

function WorldService.init(services)
	Services = services

	workspace.FallenPartsDestroyHeight = Settings.VoidFloor - 200

	worldRoot = Instance.new("Folder")
	worldRoot.Name = "World"
	worldRoot.Parent = workspace

	configureLighting()

	for index, zone in ipairs(Zones) do
		local zoneFolder = Instance.new("Folder")
		zoneFolder.Name = zone.id
		zoneFolder.Parent = worldRoot

		buildPlatform(zone, zoneFolder)
		buildZoneSign(zone, zoneFolder)
		buildVault(zone, zoneFolder)
		buildEggStand(zone, zoneFolder)
		buildKiosk(zone, zoneFolder)
		buildRebirthAltar(zone, zoneFolder)

		local nodeFolder = Instance.new("Folder")
		nodeFolder.Name = "Nodes"
		nodeFolder.Parent = zoneFolder

		for nodeIndex, position in ipairs(nodePositions(zone)) do
			buildNode(zone, position, nodeFolder, nodeIndex)
		end

		local nextZone = Zones[index + 1]
		-- The VIP zone sits off the main road; it is reached by teleport only.
		if nextZone and not nextZone.requiresPass then
			buildBridge(zone, nextZone, zoneFolder)
		end
	end

	buildLeaderboards(worldRoot)
	buildSpawn(worldRoot)

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.2)
			Services.StatService.applyCharacter(player)
			Services.ZoneService.sendToZone(player, nil, true)
		end)
	end)
end

--- Applies damage and returns (auraGained, broke).
function WorldService.damageNode(node, amount)
	if not node.alive then
		return 0, false
	end

	node.hp -= amount
	local broke = node.hp <= 0

	if broke then
		node.alive = false
		node.hp = 0
		node.respawnAt = os.clock() + Settings.NodeRespawn
		node.model:SetAttribute("Broken", true)
		for _, child in ipairs(node.model:GetChildren()) do
			if child:IsA("BasePart") then
				child.Transparency = 1
			end
		end
	end

	node.part:SetAttribute("Hp", node.hp)
	return amount, broke
end

function WorldService.start()
	while true do
		task.wait(0.5)
		local now = os.clock()

		for _, node in ipairs(WorldService.nodes) do
			if not node.alive and now >= node.respawnAt then
				node.alive = true
				node.hp = node.maxHp
				node.part:SetAttribute("Hp", node.hp)
				node.model:SetAttribute("Broken", false)
				for _, child in ipairs(node.model:GetChildren()) do
					if child:IsA("BasePart") then
						child.Transparency = 0
					end
				end
			end
		end
	end
end

return WorldService
