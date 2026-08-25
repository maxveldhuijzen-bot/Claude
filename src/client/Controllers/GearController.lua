--[[
	GearController — the collector in your hand and the aura trail behind you.

	Both read from Player attributes published by the server, so every client
	renders every other player's gear without extra remotes. The models are
	anchored and positioned each frame rather than welded, which keeps them out
	of the physics solver entirely.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Collectors = require(Shared.Config.Collectors)
local Rebirth = require(Shared.Config.Rebirth)

local localPlayer = Players.LocalPlayer

local GearController = {}

local SWING_DURATION = 0.26

local gear = {} -- [player] = { model, handle, index, swingStart }
local trails = {} -- [player] = { emitter, id }
local folder

local function buildCollector(index)
	local definition = Collectors[math.clamp(index, 1, #Collectors)]

	local model = Instance.new("Model")
	model.Name = "Collector"

	local function piece(size, offset, color, material)
		local part = Instance.new("Part")
		part.Size = size
		part.Color = color
		part.Material = material or Enum.Material.SmoothPlastic
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Massless = true
		part.Name = "Piece"
		part:SetAttribute("Offset", true)
		part.CFrame = offset
		part.Parent = model
		return part
	end

	local handle = piece(Vector3.new(0.28, 3.2, 0.28), CFrame.new(0, -0.6, 0), Color3.fromRGB(70, 62, 58))
	handle.Name = "Handle"

	piece(Vector3.new(0.7, 0.9, 0.7), CFrame.new(0, 1.1, 0) * CFrame.Angles(0, math.rad(45), 0), definition.color, Enum.Material.Neon)
	piece(Vector3.new(0.42, 1.5, 0.42), CFrame.new(0, 1.9, 0) * CFrame.Angles(math.rad(12), math.rad(45), 0), definition.color, Enum.Material.Neon)
	piece(Vector3.new(0.5, 0.22, 0.5), CFrame.new(0, 0.55, 0), definition.color:Lerp(Color3.new(1, 1, 1), 0.4), Enum.Material.Metal)

	local light = Instance.new("PointLight")
	light.Color = definition.color
	light.Brightness = 1.4
	light.Range = 9
	light.Parent = handle

	model.PrimaryPart = handle
	return model, handle
end

local function handOf(character)
	return character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
end

local function ensureGear(player)
	local index = player:GetAttribute("Collector") or 1
	local record = gear[player]

	if record and record.index == index and record.model.Parent then
		return record
	end

	if record then
		record.model:Destroy()
	end

	local model, handle = buildCollector(index)
	model.Parent = folder

	-- Offsets are baked relative to the handle so the whole model can be moved
	-- by pivoting the handle each frame.
	local offsets = {}
	for _, part in ipairs(model:GetChildren()) do
		if part:IsA("BasePart") then
			offsets[part] = handle.CFrame:ToObjectSpace(part.CFrame)
		end
	end

	record = { model = model, handle = handle, index = index, offsets = offsets, swingStart = -1 }
	gear[player] = record
	return record
end

local function ensureTrail(player)
	local id = player:GetAttribute("AuraTrail") or "none"
	local record = trails[player]

	-- The attachment dies with the old character, so an unchanged id is not
	-- enough on its own — the emitter has to still be parented to something.
	if record and record.id == id and (id == "none" or (record.emitter and record.emitter.Parent)) then
		return
	end

	if record and record.emitter then
		record.emitter:Destroy()
	end

	if id == "none" then
		trails[player] = { id = id }
		return
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		trails[player] = nil
		return
	end

	local aura = Rebirth.getAura(id)

	local attachment = Instance.new("Attachment")
	attachment.Name = "AuraTrail"
	attachment.Position = Vector3.new(0, -1.4, 0)
	attachment.Parent = root

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(aura.color)
	emitter.LightEmission = 0.9
	emitter.Lifetime = NumberRange.new(0.5, 1.1)
	emitter.Rate = 22
	emitter.Speed = NumberRange.new(1, 3)
	emitter.SpreadAngle = Vector2.new(22, 22)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.9),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Parent = attachment

	trails[player] = { id = id, emitter = attachment }
end

--- Called by CollectController when the local player swings.
function GearController.playSwing()
	local record = gear[localPlayer]
	if record then
		record.swingStart = os.clock()
	end
end

local function step()
	local now = os.clock()

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local hand = character and handOf(character)

		if hand then
			local record = ensureGear(player)
			ensureTrail(player)

			local swingAlpha = 0
			if record.swingStart > 0 then
				local elapsed = now - record.swingStart
				if elapsed < SWING_DURATION then
					-- Ease out and back: a quick chop rather than a linear sweep.
					swingAlpha = math.sin(elapsed / SWING_DURATION * math.pi)
				else
					record.swingStart = -1
				end
			end

			local base = hand.CFrame
				* CFrame.new(0, -1.1, -0.35)
				* CFrame.Angles(math.rad(-70 - swingAlpha * 95), 0, 0)

			record.handle.CFrame = base
			for part, offset in pairs(record.offsets) do
				if part ~= record.handle then
					part.CFrame = base * offset
				end
			end
		elseif gear[player] then
			gear[player].model:Destroy()
			gear[player] = nil
		end
	end
end

function GearController.init()
	folder = Instance.new("Folder")
	folder.Name = "ClientGear"
	folder.Parent = workspace

	Players.PlayerRemoving:Connect(function(player)
		if gear[player] then
			gear[player].model:Destroy()
			gear[player] = nil
		end
		trails[player] = nil
	end)
end

function GearController.start()
	RunService.RenderStepped:Connect(step)
end

return GearController
