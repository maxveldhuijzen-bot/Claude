--[[
	DataService — session-locked persistence.

	One save per player, guarded by a lock record so two servers can never write
	the same profile (the classic duplication exploit: join, get items, rejoin
	fast, have the old server overwrite). A lock older than SessionLockStale is
	treated as a crashed server and taken over.

	In Studio the store is swapped for an in-memory mock unless
	Settings.StudioSaveEnabled is true, so playtesting never touches live data.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Settings = require(Shared.Config.Settings)
local Signal = require(Shared.Modules.Signal)
local TableUtil = require(Shared.Modules.TableUtil)

local ProfileTemplate = require(script.Parent.ProfileTemplate)

local KEY_PREFIX = "player_"
local JOB_ID = game.JobId ~= "" and game.JobId or "studio-" .. tostring(math.random(1, 1e6))

local DataService = {}

DataService.loaded = Signal.new() -- (player, profile)
DataService.releasing = Signal.new() -- (player, profile) — last chance to write

local profiles = {}
local loading = {}
local store

-- In-memory stand-in with the same surface as a GlobalDataStore --------------
local function mockStore()
	local memory = {}
	return {
		UpdateAsync = function(_, key, transform)
			local updated = transform(memory[key])
			if updated ~= nil then
				memory[key] = TableUtil.deepCopy(updated)
			end
			return memory[key]
		end,
	}
end

local function getStore()
	if store then
		return store
	end

	if RunService:IsStudio() and not Settings.StudioSaveEnabled then
		store = mockStore()
		warn("[DataService] Studio detected — using an in-memory store. Set Settings.StudioSaveEnabled to persist.")
	else
		store = DataStoreService:GetDataStore(Settings.DataStoreName)
	end

	return store
end

local function keyFor(player)
	return KEY_PREFIX .. player.UserId
end

local function lockIsForeign(lock)
	if not lock or lock.jobId == JOB_ID then
		return false
	end
	return (os.time() - (lock.at or 0)) < Settings.SessionLockStale
end

--- Takes the lock and returns the stored record, or nil if another live server
--- still holds it after every retry.
local function acquire(player)
	local key = keyFor(player)

	for attempt = 1, Settings.SaveRetries do
		local ok, record = pcall(function()
			return getStore():UpdateAsync(key, function(saved)
				saved = saved or {}
				if lockIsForeign(saved.lock) then
					return nil -- abort the write; another server is live
				end
				saved.lock = { jobId = JOB_ID, at = os.time() }
				return saved
			end)
		end)

		if ok and record then
			return record
		end

		if not ok then
			warn(string.format("[DataService] acquire failed for %s: %s", player.Name, tostring(record)))
		end

		if not player.Parent then
			return nil -- they left while we were retrying
		end

		task.wait(attempt * 2)
	end

	return nil
end

--- Writes `profile` back. `release` also clears the lock.
local function commit(player, profile, release)
	local key = keyFor(player)

	for attempt = 1, Settings.SaveRetries do
		local ok, err = pcall(function()
			getStore():UpdateAsync(key, function(saved)
				saved = saved or {}
				if lockIsForeign(saved.lock) then
					return nil -- we lost the lock; do not clobber the live session
				end
				saved.data = profile
				saved.lock = (not release) and { jobId = JOB_ID, at = os.time() } or nil
				return saved
			end)
		end)

		if ok then
			return true
		end

		warn(string.format("[DataService] save failed for %s: %s", player.Name, tostring(err)))
		task.wait(attempt * 2)
	end

	return false
end

local function onPlayerAdded(player)
	if loading[player] or profiles[player] then
		return
	end
	loading[player] = true

	local record = acquire(player)

	if not player.Parent then
		loading[player] = nil
		return
	end

	if not record then
		loading[player] = nil
		player:Kick("Your save is still active on another server. Rejoin in about a minute.")
		return
	end

	local profile = ProfileTemplate.migrate(record.data)
	TableUtil.reconcile(profile, ProfileTemplate.new())

	profile.stats.joins += 1
	profile.lastSeen = os.time()
	profile.playtime.session = 0

	profiles[player] = profile
	loading[player] = nil

	DataService.loaded:Fire(player, profile)
end

local function onPlayerRemoving(player)
	local profile = profiles[player]
	if not profile then
		loading[player] = nil
		return
	end

	profiles[player] = nil
	profile.lastSeen = os.time()

	DataService.releasing:FireSync(player, profile)
	commit(player, profile, true)
end

--- Returns the live profile, or nil when it has not finished loading.
function DataService.get(player)
	return profiles[player]
end

--- Runs `callback(profile)` once the profile exists. Fires immediately when it
--- is already loaded, which removes a class of race at join time.
function DataService.whenReady(player, callback)
	local profile = profiles[player]
	if profile then
		task.spawn(callback, profile)
		return nil
	end

	local connection
	connection = DataService.loaded:Connect(function(readyPlayer, readyProfile)
		if readyPlayer == player then
			connection:Disconnect()
			callback(readyProfile)
		end
	end)
	return connection
end

function DataService.all()
	return profiles
end

function DataService.save(player)
	local profile = profiles[player]
	if profile then
		return commit(player, profile, false)
	end
	return false
end

function DataService.init()
	Players.PlayerAdded:Connect(function(player)
		task.spawn(onPlayerAdded, player)
	end)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, player)
	end

	game:BindToClose(function()
		local pending = 0
		for player in pairs(profiles) do
			pending += 1
			task.spawn(function()
				onPlayerRemoving(player)
				pending -= 1
			end)
		end

		local deadline = os.clock() + 20
		while pending > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end

function DataService.start()
	while true do
		task.wait(Settings.AutosaveInterval)
		for player, profile in pairs(profiles) do
			profile.lastSeen = os.time()
			task.spawn(commit, player, profile, false)
			task.wait(0.4) -- stagger so we never burst the request budget
		end
	end
end

return DataService
