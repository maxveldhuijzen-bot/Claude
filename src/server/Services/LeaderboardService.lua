--[[
	LeaderboardService — leaderstats plus the two in-world boards.

	OrderedDataStore keys are capped at 2^31-1, so total aura is stored in
	thousands. The board renders it back with the same abbreviation used
	everywhere else.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Settings = require(Shared.Config.Settings)
local Format = require(Shared.Modules.Format)
local Palette = require(Shared.Modules.Palette)

local INT_MAX = 2 ^ 31 - 1

local LeaderboardService = {}
local Services

local stores = {}
local nameCache = {}
local live = false

local function getStore(name)
	if stores[name] == nil then
		local ok, store = pcall(function()
			return DataStoreService:GetOrderedDataStore(name)
		end)
		stores[name] = ok and store or false
	end
	return stores[name] or nil
end

local function nameFor(userId)
	if nameCache[userId] then
		return nameCache[userId]
	end

	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)

	nameCache[userId] = ok and name or ("User " .. userId)
	return nameCache[userId]
end

local function attachLeaderstats(player, profile)
	local folder = player:FindFirstChild("leaderstats")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "leaderstats"
		folder.Parent = player
	end

	local rebirths = folder:FindFirstChild("Rebirths") or Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = profile.rebirths
	rebirths.Parent = folder

	local aura = folder:FindFirstChild("Aura") or Instance.new("StringValue")
	aura.Name = "Aura"
	aura.Value = Format.abbreviate(profile.stats.totalAura)
	aura.Parent = folder
end

--- Writes the player's current standings. Cheap enough to call on rebirth and
--- on leave; the periodic loop handles everyone else.
function LeaderboardService.submit(player, profile)
	profile = profile or Services.DataService.get(player)
	if not profile or not live then
		return
	end

	local key = tostring(player.UserId)

	local rebirthStore = getStore(Settings.OrderedStoreRebirths)
	if rebirthStore then
		pcall(function()
			rebirthStore:SetAsync(key, math.clamp(math.floor(profile.rebirths), 0, INT_MAX))
		end)
	end

	local auraStore = getStore(Settings.OrderedStoreAura)
	if auraStore then
		pcall(function()
			-- Stored in thousands to stay inside the signed 32-bit key range.
			auraStore:SetAsync(key, math.clamp(math.floor(profile.stats.totalAura / 1000), 0, INT_MAX))
		end)
	end
end

local function fetchTop(storeName, limit)
	local store = getStore(storeName)
	if not store then
		return {}
	end

	local ok, pages = pcall(function()
		return store:GetSortedAsync(false, limit)
	end)

	if not ok then
		return {}
	end

	local rows = {}
	local okPage, page = pcall(function()
		return pages:GetCurrentPage()
	end)

	if not okPage then
		return {}
	end

	for rank, entry in ipairs(page) do
		table.insert(rows, {
			rank = rank,
			userId = tonumber(entry.key),
			value = entry.value,
		})
	end

	return rows
end

local function renderBoard(board, rows, formatter)
	local surface = board:FindFirstChild("Display")
	if not surface then
		return
	end

	for _, child in ipairs(surface:GetChildren()) do
		if child:IsA("TextLabel") and child.Name ~= "Header" then
			child:Destroy()
		end
	end

	if #rows == 0 then
		local empty = Instance.new("TextLabel")
		empty.Name = "Row"
		empty.BackgroundTransparency = 1
		empty.Size = UDim2.new(1, 0, 0, 34)
		empty.Font = Enum.Font.Gotham
		empty.Text = "No entries yet"
		empty.TextColor3 = Palette.textDim
		empty.TextScaled = true
		empty.LayoutOrder = 1
		empty.Parent = surface
		return
	end

	for _, row in ipairs(rows) do
		local label = Instance.new("TextLabel")
		label.Name = "Row"
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(1, 0, 0, 34)
		label.Font = row.rank <= 3 and Enum.Font.GothamBold or Enum.Font.Gotham
		label.Text = string.format("%s  %s", Format.ordinal(row.rank), nameFor(row.userId))
		label.TextColor3 = row.rank == 1 and Palette.coins
			or (row.rank <= 3 and Palette.text or Palette.textDim)
		label.TextScaled = true
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.LayoutOrder = row.rank
		label.Parent = surface

		local value = Instance.new("TextLabel")
		value.Name = "Value"
		value.BackgroundTransparency = 1
		value.AnchorPoint = Vector2.new(1, 0)
		value.Position = UDim2.fromScale(1, 0)
		value.Size = UDim2.fromScale(0.42, 1)
		value.Font = Enum.Font.GothamBold
		value.Text = formatter(row.value)
		value.TextColor3 = Palette.aura
		value.TextScaled = true
		value.TextXAlignment = Enum.TextXAlignment.Right
		value.Parent = label
	end
end

local function refreshBoards()
	local rebirthRows = fetchTop(Settings.OrderedStoreRebirths, 10)
	local auraRows = fetchTop(Settings.OrderedStoreAura, 10)

	for _, board in ipairs(CollectionService:GetTagged("Leaderboard")) do
		local key = board:GetAttribute("Board")
		if key == "rebirths" then
			renderBoard(board, rebirthRows, function(value)
				return Format.comma(value)
			end)
		elseif key == "aura" then
			renderBoard(board, auraRows, function(value)
				return Format.abbreviate(value * 1000)
			end)
		end
	end
end

function LeaderboardService.init(services)
	Services = services

	-- Ordered stores are unavailable in Studio without API access; skip rather
	-- than spamming the output with failures.
	live = not RunService:IsStudio() or Settings.StudioSaveEnabled

	Services.DataService.loaded:Connect(function(player, profile)
		attachLeaderstats(player, profile)
	end)

	Services.DataService.releasing:Connect(function(player, profile)
		LeaderboardService.submit(player, profile)
	end)
end

function LeaderboardService.start()
	task.spawn(function()
		while true do
			task.wait(5)
			for player, profile in pairs(Services.DataService.all()) do
				attachLeaderstats(player, profile)
			end
		end
	end)

	if not live then
		for _, board in ipairs(CollectionService:GetTagged("Leaderboard")) do
			renderBoard(board, {}, tostring)
		end
		return
	end

	while true do
		local ok, err = pcall(refreshBoards)
		if not ok then
			warn("[Leaderboard] refresh failed: " .. tostring(err))
		end

		for player, profile in pairs(Services.DataService.all()) do
			LeaderboardService.submit(player, profile)
			task.wait(0.5)
		end

		task.wait(Settings.LeaderboardRefresh)
	end
end

return LeaderboardService
