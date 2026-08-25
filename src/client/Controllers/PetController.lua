--[[
	PetController — renders equipped pets for every nearby player.

	Pet data itself is private, but the *equipped* list is published as a Player
	attribute by the server, so everyone can see everyone's pets without the
	server replicating whole inventories. Models are client-side only: no
	physics, no network cost, and they can be culled freely.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Pets = require(Shared.Config.Pets)

local PetBuilder = require(script.Parent.Parent.UI.PetBuilder)


local PetController = {}
local Controllers

local RENDER_DISTANCE = 220
local FOLLOW_SPEED = 7

local rendered = {} -- [player] = { signature, entries = { {model, cframe, phase} } }
local folder

function PetController.init(controllers)
	Controllers = controllers

	folder = Instance.new("Folder")
	folder.Name = "ClientPets"
	folder.Parent = workspace

	Players.PlayerRemoving:Connect(function(player)
		local record = rendered[player]
		if record then
			for _, entry in ipairs(record.entries) do
				entry.model:Destroy()
			end
			rendered[player] = nil
		end
	end)
end

--- "sunrise_phoenix:2,neon_dragon:1" -> { {id, tier}, ... }
local function parseSignature(signature)
	local out = {}
	if type(signature) ~= "string" or signature == "" then
		return out
	end

	for _, chunk in ipairs(string.split(signature, ",")) do
		local pieces = string.split(chunk, ":")
		local definition = Pets.get(pieces[1])
		if definition then
			table.insert(out, { definition = definition, tier = tonumber(pieces[2]) or 1 })
		end
	end

	return out
end

--- Two rows of four behind the owner, centred.
local function slotOffset(index, total)
	local row = math.floor((index - 1) / 4)
	local column = (index - 1) % 4
	local inRow = math.min(4, total - row * 4)
	local x = (column - (inRow - 1) / 2) * 3.4
	return Vector3.new(x, 0, 5 + row * 3.4)
end

local function rebuild(player, signature)
	local record = rendered[player]

	if record then
		for _, entry in ipairs(record.entries) do
			entry.model:Destroy()
		end
	end

	local entries = {}
	for index, spec in ipairs(parseSignature(signature)) do
		local model = PetBuilder.build(spec.definition, spec.tier)
		model.Parent = folder
		table.insert(entries, {
			model = model,
			cframe = nil,
			phase = index * 0.7,
		})
	end

	rendered[player] = { signature = signature, entries = entries }
end

local function step(deltaTime)
	local camera = workspace.CurrentCamera
	local viewpoint = camera and camera.CFrame.Position
	if not viewpoint then
		return
	end

	local now = os.clock()

	for _, player in ipairs(Players:GetPlayers()) do
		local signature = player:GetAttribute("EquippedPets") or ""
		local record = rendered[player]

		if not record or record.signature ~= signature then
			rebuild(player, signature)
			record = rendered[player]
		end

		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local visible = root ~= nil and (root.Position - viewpoint).Magnitude < RENDER_DISTANCE

		local total = #record.entries
		for index, entry in ipairs(record.entries) do
			if not visible then
				if entry.model.Parent then
					entry.model.Parent = nil
				end
			else
				if not entry.model.Parent then
					entry.model.Parent = folder
					entry.cframe = nil
				end

				local offset = slotOffset(index, total)
				local bob = math.sin(now * 2.4 + entry.phase) * 0.35
				local target = root.CFrame * CFrame.new(offset + Vector3.new(0, 2.4 + bob, 0))
				target *= CFrame.Angles(0, math.sin(now * 1.3 + entry.phase) * 0.25, 0)

				if entry.cframe then
					-- Lerp toward the slot so pets trail rather than teleport.
					local alpha = math.clamp(deltaTime * FOLLOW_SPEED, 0, 1)
					entry.cframe = entry.cframe:Lerp(target, alpha)
				else
					entry.cframe = target
				end

				entry.model:PivotTo(entry.cframe)
				PetBuilder.animateTier(entry.model, now)
			end
		end
	end
end

function PetController.start()
	RunService.RenderStepped:Connect(step)
end

return PetController
