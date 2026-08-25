--[[
	WorldController — the parts of the world that only need to look alive.

	Node idle motion, node health bars and proximity-prompt routing all live on
	the client: none of it affects gameplay state, so none of it needs the
	server's time or bandwidth.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Palette = require(Shared.Modules.Palette)
local Zones = require(Shared.Config.Zones)

local UI = script.Parent.Parent.UI
local Elements = require(UI.Elements)
local create = Elements.create

local player = Players.LocalPlayer

local WorldController = {}
local Controllers

local tracked = {}

local ANIMATE_RANGE = 160

function WorldController.init(controllers)
	Controllers = controllers
end

local function attachHealthBar(core)
	local gui = create("BillboardGui", {
		Name = "Health",
		Adornee = core,
		Size = UDim2.fromScale(7, 0.9),
		StudsOffsetWorldSpace = Vector3.new(0, 6.4, 0),
		MaxDistance = 90,
		LightInfluence = 0,
		Parent = core,
	})

	local track = create("Frame", {
		BackgroundColor3 = Color3.fromRGB(14, 14, 22),
		Size = UDim2.fromScale(1, 1),
		Parent = gui,
	}, { Elements.corner(6), Elements.stroke(Palette.stroke, 1.5, 0.4) })

	local fill = create("Frame", {
		Name = "Fill",
		BackgroundColor3 = core:GetAttribute("Zone") and Palette.aura or Palette.positive,
		Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0,
		Parent = track,
	}, { Elements.corner(6) })

	local zone = Zones.get(core:GetAttribute("Zone"))
	if zone then
		fill.BackgroundColor3 = zone.accent
	end

	return gui, fill
end

local function trackNode(core)
	if tracked[core] then
		return
	end

	local model = core.Parent
	local shard = model and model:FindFirstChild("Shard")
	local gui, fill = attachHealthBar(core)

	local record = {
		core = core,
		shard = shard,
		gui = gui,
		fill = fill,
		origin = shard and shard.CFrame or nil,
		phase = math.random() * math.pi * 2,
		maxHp = core:GetAttribute("MaxHp") or 1,
	}

	local function updateHealth()
		local hp = core:GetAttribute("Hp") or record.maxHp
		local alpha = math.clamp(hp / math.max(1, record.maxHp), 0, 1)
		fill.Size = UDim2.fromScale(alpha, 1)
		gui.Enabled = alpha < 1
	end

	updateHealth()
	record.connection = core:GetAttributeChangedSignal("Hp"):Connect(updateHealth)

	tracked[core] = record
end

local function untrackNode(core)
	local record = tracked[core]
	if not record then
		return
	end
	if record.connection then
		record.connection:Disconnect()
	end
	tracked[core] = nil
end

local function animate()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local now = os.clock()
	local origin = root.Position

	for core, record in pairs(tracked) do
		if not core.Parent then
			untrackNode(core)
		elseif record.shard and record.origin then
			-- Cheap distance cull: idle motion off screen is wasted work.
			if (core.Position - origin).Magnitude < ANIMATE_RANGE then
				local bob = math.sin(now * 1.8 + record.phase) * 0.55
				record.shard.CFrame = record.origin
					* CFrame.new(0, bob, 0)
					* CFrame.Angles(0, now * 1.1 + record.phase, 0)
			end
		end
	end
end

function WorldController.start()
	for _, core in ipairs(CollectionService:GetTagged("AuraNode")) do
		trackNode(core)
	end

	CollectionService:GetInstanceAddedSignal("AuraNode"):Connect(trackNode)
	CollectionService:GetInstanceRemovedSignal("AuraNode"):Connect(untrackNode)

	-- Prompts carry a UiTarget attribute; the client opens the panel directly.
	ProximityPromptService.PromptTriggered:Connect(function(prompt, triggeredBy)
		if triggeredBy ~= player then
			return
		end

		local target = prompt:GetAttribute("UiTarget")
		if not target then
			return
		end

		Controllers.MenuController.open(target, {
			egg = prompt:GetAttribute("Egg"),
			zone = prompt:GetAttribute("Zone"),
		})
	end)

	RunService.RenderStepped:Connect(animate)
end

return WorldController
