--[[
	MonetizationService — gamepasses and developer products.

	Every asset ID in Config/Monetization starts at 0. Nothing here calls
	MarketplaceService with an unconfigured ID, so the game is fully playable
	before a single product exists on the Creator Hub; fill the IDs in and the
	same code paths start working with no other changes.

	ProcessReceipt records the purchase id on the profile and only returns
	PurchaseGranted after a successful save, which is what stops a mid-purchase
	server crash from taking the player's Robux without the goods.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Monetization = require(Shared.Config.Monetization)
local Rebirth = require(Shared.Config.Rebirth)
local Format = require(Shared.Modules.Format)

local MonetizationService = {}
local Services

local ownership = {} -- [player] = { [passKey] = boolean }

local function refreshPasses(player)
	local owned = {}

	for key, pass in pairs(Monetization.gamepasses) do
		if Monetization.isConfigured(pass) then
			local ok, result = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.id)
			end)
			owned[key] = ok and result or false
		else
			owned[key] = false
		end
	end

	ownership[player] = owned
	return owned
end

function MonetizationService.passes(player)
	return ownership[player] or {}
end

function MonetizationService.ownsPass(player, key)
	local owned = ownership[player]
	return owned ~= nil and owned[key] == true
end

--- Applies a product's payload. Shared by ProcessReceipt and by admin grants.
local function applyProduct(player, product)
	local profile = Services.DataService.get(player)
	if not profile then
		return false
	end

	local reward = {}

	if product.coinsAsRebirthFraction then
		reward.coinsAsRebirthFraction = product.coinsAsRebirthFraction
	end
	if product.prisms then
		reward.prisms = product.prisms
	end
	if product.boost then
		reward.boost = product.boost
	end

	Services.RewardService.grant(player, reward)
	Services.Notify.send(player, {
		title = "Thanks for the support",
		body = product.name .. ": " .. Services.RewardService.describe(profile, reward),
		kind = "premium",
		duration = 6,
	})

	return true
end

local function processReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		-- They left; do not consume the receipt, Roblox will retry on rejoin.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local profile = Services.DataService.get(player)
	if not profile then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local purchaseId = tostring(receiptInfo.PurchaseId)
	if profile.receipts[purchaseId] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local product = Monetization.productById(receiptInfo.ProductId)
	if not product then
		warn("[Monetization] unmapped product id " .. tostring(receiptInfo.ProductId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local ok = pcall(applyProduct, player, product)
	if not ok then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	profile.receipts[purchaseId] = true

	-- Only confirm once the grant is actually on disk.
	if not Services.DataService.save(player) then
		profile.receipts[purchaseId] = nil
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

--- Prices for the shop UI, fetched once and cached.
local priceCache = {}

function MonetizationService.catalog(player)
	local out = { gamepasses = {}, products = {} }

	local function priceOf(assetId, infoType)
		if priceCache[assetId] ~= nil then
			return priceCache[assetId]
		end
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfo(assetId, infoType)
		end)
		local price = ok and info and info.PriceInRobux or nil
		priceCache[assetId] = price or false
		return price
	end

	for _, pass in ipairs(Monetization.sorted(Monetization.gamepasses)) do
		table.insert(out.gamepasses, {
			key = pass.key,
			id = pass.id,
			name = pass.name,
			desc = pass.desc,
			configured = Monetization.isConfigured(pass),
			owned = MonetizationService.ownsPass(player, pass.key),
			price = Monetization.isConfigured(pass) and priceOf(pass.id, Enum.InfoType.GamePass) or nil,
		})
	end

	local profile = Services.DataService.get(player)
	for _, product in ipairs(Monetization.sorted(Monetization.products)) do
		local desc = product.desc
		if product.coinsAsRebirthFraction and profile then
			desc = Format.abbreviate(Rebirth.cost(profile.rebirths) * product.coinsAsRebirthFraction) .. " coins"
		end
		table.insert(out.products, {
			key = product.key,
			id = product.id,
			name = product.name,
			desc = desc,
			configured = Monetization.isConfigured(product),
			price = Monetization.isConfigured(product) and priceOf(product.id, Enum.InfoType.Product) or nil,
		})
	end

	return true, out
end

function MonetizationService.init(services)
	Services = services

	MarketplaceService.ProcessReceipt = processReceipt

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
		if not wasPurchased then
			return
		end

		local pass = Monetization.passById(passId)
		if not pass then
			return
		end

		refreshPasses(player)
		Services.Replicator.markProfile(player)
		Services.StatService.applyCharacter(player)

		Services.Notify.send(player, {
			title = pass.name .. " active",
			body = pass.desc,
			kind = "premium",
			duration = 6,
		})
	end)

	Players.PlayerAdded:Connect(function(player)
		task.spawn(refreshPasses, player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		ownership[player] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(refreshPasses, player)
	end
end

return MonetizationService
