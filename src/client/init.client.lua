--[[
	Aura Farm Simulator — client bootstrap.

	Same shape as the server: controllers are modules with optional
	init(controllers) and start(). init() wires things up without yielding,
	start() may loop.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = require(Shared.Config.Settings)

local player = Players.LocalPlayer

local CONTROLLER_ORDER = {
	"StateController",
	"EffectsController",
	"HudController",
	"MenuController",
	"WorldController",
	"CollectController",
	"PetController",
	"GearController",
}

local Controllers = {}

for _, name in ipairs(CONTROLLER_ORDER) do
	local module = script.Controllers:FindFirstChild(name)
	assert(module, "Missing controller module: " .. name)
	Controllers[name] = require(module)
end

for _, name in ipairs(CONTROLLER_ORDER) do
	local controller = Controllers[name]
	if type(controller.init) == "function" then
		local ok, err = pcall(controller.init, Controllers)
		if not ok then
			warn(string.format("[Client] %s.init failed: %s", name, tostring(err)))
		end
	end
end

for _, name in ipairs(CONTROLLER_ORDER) do
	local controller = Controllers[name]
	if type(controller.start) == "function" then
		task.spawn(function()
			local ok, err = pcall(controller.start)
			if not ok then
				warn(string.format("[Client] %s.start failed: %s", name, tostring(err)))
			end
		end)
	end
end

print(string.format("[%s] client ready for %s", Settings.GameName, player.Name))
