--[[
	CollectController — turning input into swings.

	Click, tap or hold anywhere: the controller picks the node under the cursor
	if there is one, otherwise the nearest node in range. The server re-validates
	everything, so the worst a tampered client can do here is ask politely.
]]

local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Settings = require(Shared.Config.Settings)
local Net = require(Shared.Modules.Net)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local CollectController = {}
local Controllers

local holding = false
local lastSwing = 0

function CollectController.init(controllers)
	Controllers = controllers
end

local function nearestNode(position, range)
	local best, bestDistance = nil, range

	for _, core in ipairs(CollectionService:GetTagged("AuraNode")) do
		if core.Transparency < 1 then
			local distance = (core.Position - position).Magnitude
			if distance <= bestDistance then
				best, bestDistance = core, distance
			end
		end
	end

	return best
end

local function nodeUnderCursor()
	local location = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(location.X, location.Y)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character }

	local result = workspace:Raycast(ray.Origin, ray.Direction * 400, params)
	if result and result.Instance and CollectionService:HasTag(result.Instance, "AuraNode") then
		return result.Instance
	end

	return nil
end

local function swing()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local range = Controllers.StateController.hot.collectRange or Settings.CollectRange

	local target = nodeUnderCursor()
	if target and (target.Position - root.Position).Magnitude > range then
		target = nil
	end

	target = target or nearestNode(root.Position, range)
	if not target then
		return
	end

	Net.send("Collect", target)
	Controllers.GearController.playSwing()
end

local function step()
	if not holding then
		return
	end

	local now = os.clock()
	if now - lastSwing < Settings.CollectInterval then
		return
	end

	lastSwing = now
	swing()
end

function CollectController.start()
	ContextActionService:BindAction("AuraSwing", function(_, state)
		if state == Enum.UserInputState.Begin then
			holding = true
			-- Fire the first swing immediately so input feels instant.
			if os.clock() - lastSwing >= Settings.CollectInterval then
				lastSwing = os.clock()
				swing()
			end
		elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
			holding = false
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch, Enum.KeyCode.ButtonR2)

	RunService.Heartbeat:Connect(step)
end

return CollectController
