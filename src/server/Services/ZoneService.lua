--[[
	ZoneService — unlocking, teleporting, and keeping players where they belong.

	The force-field walls in the world are decoration. The real gate is the
	guard loop below: any player standing on a platform they have not unlocked
	is moved back, so teleport and fly exploits gain nothing.
]]

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Settings = require(Shared.Config.Settings)
local Zones = require(Shared.Config.Zones)
local Format = require(Shared.Modules.Format)

local ZoneService = {}
local Services

local lastTeleport = {}

function ZoneService.init(services)
	Services = services

	Players.PlayerRemoving:Connect(function(player)
		lastTeleport[player] = nil
	end)
end

function ZoneService.canEnter(player, profile, zone)
	if not zone then
		return false, "That zone does not exist."
	end

	if zone.requiresPass then
		if Services.MonetizationService.ownsPass(player, zone.requiresPass) then
			return true
		end
		return false, "Aurora Sanctum needs the VIP gamepass."
	end

	if profile.zones[zone.id] then
		return true
	end

	return false, zone.name .. " is locked."
end

--- Which zone platform a world position sits on, or nil for the space between.
function ZoneService.zoneAt(position)
	local half = Settings.PlatformSize / 2

	for _, zone in ipairs(Zones) do
		if math.abs(position.X - zone.origin.X) <= half and math.abs(position.Z - zone.origin.Z) <= half then
			return zone
		end
	end

	return nil
end

function ZoneService.unlock(player, zoneId)
	local profile = Services.DataService.get(player)
	if not profile then
		return false, "Still loading."
	end

	local zone = Zones.get(zoneId)
	if not zone then
		return false, "Unknown zone."
	end

	if profile.zones[zone.id] then
		return false, "Already unlocked."
	end

	if zone.requiresPass then
		return false, "That zone is unlocked with a gamepass."
	end

	local previous = Zones[zone.order - 1]
	if previous and not previous.requiresPass and not profile.zones[previous.id] then
		return false, "Unlock " .. previous.name .. " first."
	end

	if profile.rebirths < zone.rebirthReq then
		return false, string.format("Needs %d rebirths.", zone.rebirthReq)
	end

	if profile.coins < zone.unlockCost then
		return false, "Need " .. Format.abbreviate(zone.unlockCost - profile.coins) .. " more coins."
	end

	profile.coins -= zone.unlockCost
	profile.zones[zone.id] = true

	Services.Replicator.markProfile(player)
	Services.Notify.send(player, {
		title = zone.name .. " unlocked",
		body = zone.tagline,
		kind = "good",
	})
	Services.Notify.effect(player, { kind = "zoneUnlock", zone = zone.id })

	ZoneService.sendToZone(player, zone.id)
	return true, { zone = zone.id }
end

--- Moves the character to a zone spawn. `silent` skips the toast (used on
--- respawn and by the out-of-bounds guard).
function ZoneService.sendToZone(player, zoneId, silent)
	local profile = Services.DataService.get(player)
	if not profile then
		return false, "Still loading."
	end

	local now = os.clock()
	local history = lastTeleport[player]
	if not silent and history and now - history < 0.4 then
		return false, "Slow down."
	end
	lastTeleport[player] = now

	local zone = Zones.get(zoneId or profile.zone) or Zones.first()

	local allowed, reason = ZoneService.canEnter(player, profile, zone)
	if not allowed then
		if zoneId then
			return false, reason
		end
		zone = Zones.best(profile.zones)
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false, "Waiting for your character."
	end

	root.CFrame = CFrame.new(zone.spawn) * CFrame.Angles(0, math.pi, 0)
	profile.zone = zone.id
	Services.Replicator.markHot(player)

	if not silent then
		Services.Notify.send(player, { title = "Travelled to " .. zone.name, kind = "info" })
	end

	return true, { zone = zone.id }
end

--- Runs every half second: tracks which zone each player is standing in and
--- bounces anyone who should not be there.
function ZoneService.start()
	while true do
		task.wait(0.5)

		for _, player in ipairs(Players:GetPlayers()) do
			local profile = Services.DataService.get(player)
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")

			if profile and root then
				local position = root.Position

				if position.Y < Settings.VoidFloor then
					ZoneService.sendToZone(player, profile.zone, true)
					continue
				end

				local zone = ZoneService.zoneAt(position)
				if zone then
					local allowed = ZoneService.canEnter(player, profile, zone)
					if allowed then
						if profile.zone ~= zone.id then
							profile.zone = zone.id
							Services.Replicator.markHot(player)
						end
					else
						local home = Zones.best(profile.zones)
						root.CFrame = CFrame.new(home.spawn) * CFrame.Angles(0, math.pi, 0)
						profile.zone = home.id
						Services.Replicator.markHot(player)
						Services.Notify.send(player, {
							title = zone.name .. " is locked",
							body = "Unlock it at the gate first.",
							kind = "bad",
						})
					end
				end
			end
		end
	end
end

return ZoneService
