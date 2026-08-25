--[[
	Aura Farm Simulator — server bootstrap.

	Services are plain modules with optional init(services) and start()
	functions. Every service receives the same registry table, which is how
	they reach each other without circular requires.

	init() runs in list order and must not yield: it wires up connections.
	start() runs afterwards in its own thread and may loop forever.

	DataService is deliberately last so that everything listening to its
	`loaded` signal is already connected before the first profile arrives.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = require(Shared.Config.Settings)

-- Creating the remotes first means a fast-loading client never misses them.
require(Shared.Modules.Net)

local SERVICE_ORDER = {
	"Notify",
	"Replicator",
	"StatService",
	"BoostService",
	"RewardService",
	"MonetizationService",
	"WorldService",
	"ZoneService",
	"FarmService",
	"ShopService",
	"PetService",
	"EggService",
	"RebirthService",
	"QuestService",
	"LeaderboardService",
	"ActionRouter",
	"DataService",
}

local started = os.clock()
local Services = {}

for _, name in ipairs(SERVICE_ORDER) do
	local module = script.Services:FindFirstChild(name)
	assert(module, "Missing service module: " .. name)
	Services[name] = require(module)
end

for _, name in ipairs(SERVICE_ORDER) do
	local service = Services[name]
	if type(service.init) == "function" then
		local ok, err = pcall(service.init, Services)
		if not ok then
			warn(string.format("[Bootstrap] %s.init failed: %s", name, tostring(err)))
		end
	end
end

for _, name in ipairs(SERVICE_ORDER) do
	local service = Services[name]
	if type(service.start) == "function" then
		task.spawn(function()
			local ok, err = pcall(service.start)
			if not ok then
				warn(string.format("[Bootstrap] %s.start failed: %s", name, tostring(err)))
			end
		end)
	end
end

print(string.format(
	"[%s] server ready in %.0f ms (%s)",
	Settings.GameName,
	(os.clock() - started) * 1000,
	RunService:IsStudio() and "Studio" or "live"
))
