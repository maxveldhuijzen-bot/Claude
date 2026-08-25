--[[
	FarmService — collecting aura and selling it.

	Every swing is validated here: the node must exist and be alive, the player
	must be inside their own collect range, must have unlocked the node's zone,
	and must have swing budget left in their token bucket. The client sends
	intent only — it never sends an amount.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Settings = require(Shared.Config.Settings)
local Format = require(Shared.Modules.Format)
local Net = require(Shared.Modules.Net)

local FarmService = {}
local Services

-- Token bucket per player: CollectBurst swings in reserve, refilling at one
-- per CollectInterval. Bursty enough to feel responsive, capped over time.
local buckets = {}
local lastAuto = {}
local lastFullWarning = {}

function FarmService.init(services)
	Services = services

	Net.onEvent("Collect", function(player, nodePart)
		if typeof(nodePart) ~= "Instance" or not nodePart:IsA("BasePart") then
			return
		end
		FarmService.swing(player, Services.WorldService.nodesByPart[nodePart], false)
	end)

	Players.PlayerRemoving:Connect(function(player)
		buckets[player] = nil
		lastAuto[player] = nil
		lastFullWarning[player] = nil
	end)
end

local function takeToken(player)
	local now = os.clock()
	local bucket = buckets[player]

	if not bucket then
		bucket = { tokens = Settings.CollectBurst, at = now }
		buckets[player] = bucket
	end

	bucket.tokens = math.min(Settings.CollectBurst, bucket.tokens + (now - bucket.at) / Settings.CollectInterval)
	bucket.at = now

	if bucket.tokens < 1 then
		return false
	end

	bucket.tokens -= 1
	return true
end

--- The one place aura is created. `auto` skips the token bucket because the
--- auto-collect loop is already server-paced.
function FarmService.swing(player, node, auto)
	if not node or not node.alive then
		return false
	end

	local profile = Services.DataService.get(player)
	if not profile then
		return false
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return false
	end

	local stats = Services.StatService.compute(player, profile)
	if not stats then
		return false
	end

	local allowed = Services.ZoneService.canEnter(player, profile, node.zone)
	if not allowed then
		return false
	end

	local reach = stats.collectRange + Settings.CollectRangeTolerance
	if (root.Position - node.position).Magnitude > reach then
		return false
	end

	if not auto and not takeToken(player) then
		return false
	end

	local capacity = stats.capacity
	if profile.aura >= capacity then
		local now = os.clock()
		if not auto and now - (lastFullWarning[player] or 0) > 4 then
			lastFullWarning[player] = now
			Services.Notify.send(player, {
				title = "Backpack full",
				body = "Sell at the Aura Vault to keep farming.",
				kind = "bad",
			})
		end
		return false
	end

	-- Node's zone decides the payout, not whatever zone the profile last saw.
	local perSwing = stats.power * stats.auraMult * node.zone.auraMult
	local _, broke = Services.WorldService.damageNode(node, stats.power)

	local gained = perSwing
	if broke then
		gained += perSwing * Settings.NodeBreakBonus
		profile.stats.nodes += 1
		Services.QuestService.progress(player, "nodes", 1)
	end

	local room = capacity - profile.aura
	gained = math.min(gained, room)

	profile.aura += gained
	profile.stats.totalAura += gained

	Services.QuestService.progress(player, "collect", gained)
	Services.Replicator.markHot(player)

	Services.Notify.effect(player, {
		kind = "swing",
		node = node.part,
		amount = gained,
		broke = broke,
		full = profile.aura >= capacity,
	})

	return true, gained
end

--- Converts carried aura into coins.
---
--- The vault check lives here rather than at the call site, so this is safe to
--- call from anywhere — including from a remote — without it ever becoming a
--- sell-from-anywhere exploit that skips the walk back.
function FarmService.sell(player, silent)
	local profile = Services.DataService.get(player)
	if not profile then
		return false, "Still loading."
	end

	if profile.aura <= 0 then
		return false, "Nothing to sell."
	end

	if not FarmService.isAtVault(player) then
		return false, "Stand on a vault pad to sell."
	end

	local stats = Services.StatService.compute(player, profile)
	local amount = profile.aura
	local coins = math.floor(amount * stats.sellMult)

	profile.aura = 0
	profile.coins += coins
	profile.stats.totalCoins += coins
	profile.stats.sells += 1

	Services.QuestService.progress(player, "sell", amount)
	Services.Replicator.markHot(player)

	Services.Notify.effect(player, { kind = "sell", aura = amount, coins = coins })

	if not silent then
		Services.Notify.send(player, {
			title = "+" .. Format.abbreviate(coins) .. " coins",
			body = "Sold " .. Format.abbreviate(amount) .. " aura.",
			kind = "good",
		})
	end

	return true, { coins = coins, aura = amount }
end

--- True when the player is standing inside any vault pad's radius.
function FarmService.isAtVault(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end

	for _, vault in ipairs(Services.WorldService.vaults) do
		if (root.Position - vault.position).Magnitude <= Settings.SellRadius then
			return true
		end
	end

	return false
end

local function nearestNode(root, stats)
	local best, bestDistance = nil, stats.collectRange

	for _, node in ipairs(Services.WorldService.nodes) do
		if node.alive then
			local distance = (root.Position - node.position).Magnitude
			if distance <= bestDistance then
				best, bestDistance = node, distance
			end
		end
	end

	return best
end

function FarmService.start()
	-- Vault proximity: sell on arrival, then keep topping up while standing there.
	task.spawn(function()
		while true do
			task.wait(0.4)

			for _, player in ipairs(Players:GetPlayers()) do
				local profile = Services.DataService.get(player)
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")

				if profile and root and profile.aura > 0 then
					for _, vault in ipairs(Services.WorldService.vaults) do
						if (root.Position - vault.position).Magnitude <= Settings.SellRadius then
							FarmService.sell(player, false)
							break
						end
					end
				end
			end
		end
	end)

	-- Auto collect for players who bought or upgraded it.
	RunService.Heartbeat:Connect(function()
		local now = os.clock()

		for _, player in ipairs(Players:GetPlayers()) do
			local profile = Services.DataService.get(player)
			if profile then
				local stats = Services.StatService.compute(player, profile)
				if stats and stats.autoCollect and now - (lastAuto[player] or 0) >= stats.autoInterval then
					local character = player.Character
					local root = character and character:FindFirstChild("HumanoidRootPart")
					if root then
						local node = nearestNode(root, stats)
						if node then
							lastAuto[player] = now
							FarmService.swing(player, node, true)
						end
					end
				end
			end
		end
	end)
end

return FarmService
