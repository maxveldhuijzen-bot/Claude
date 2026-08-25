--[[
	Net — the single place remote instances are declared.

	The server creates the folder on require; the client waits for it. Nothing
	else in the codebase touches Instance.new("RemoteEvent"), so the full
	client/server surface area is the list below.

	Channels
	  State   S -> C  hot stats (aura, coins, power) at up to 10 Hz
	  Profile S -> C  inventory, quests, upgrades — only when they change
	  Notify  S -> C  toast messages
	  Effect  S -> C  one-shot visuals (hatch reveal, node shatter, rebirth)
	  Collect C -> S  a swing at a node; rate limited server side
	  Action  C -> S  every menu action, as (name, payload) -> ok, result
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "AuraNetwork"
local EVENTS = { "State", "Profile", "Notify", "Effect", "Collect" }
local FUNCTIONS = { "Action" }

local Net = {}

local folder

local function build()
	local created = Instance.new("Folder")
	created.Name = FOLDER_NAME

	for _, name in ipairs(EVENTS) do
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = created
	end

	for _, name in ipairs(FUNCTIONS) do
		local remote = Instance.new("RemoteFunction")
		remote.Name = name
		remote.Parent = created
	end

	created.Parent = ReplicatedStorage
	return created
end

local function root()
	if folder and folder.Parent then
		return folder
	end

	if RunService:IsServer() then
		folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME) or build()
	else
		folder = ReplicatedStorage:WaitForChild(FOLDER_NAME, 30)
		assert(folder, "AuraNetwork never replicated — is the server script running?")
	end

	return folder
end

--- Returns the RemoteEvent / RemoteFunction named `name`.
function Net.get(name)
	local remote = root():WaitForChild(name, 20)
	assert(remote, string.format("Remote %q does not exist", name))
	return remote
end

--- Server: bind a handler to an inbound RemoteEvent.
function Net.onEvent(name, handler)
	assert(RunService:IsServer(), "Net.onEvent is server only")
	return Net.get(name).OnServerEvent:Connect(handler)
end

--- Server: bind the Action RemoteFunction router.
function Net.onInvoke(name, handler)
	assert(RunService:IsServer(), "Net.onInvoke is server only")
	Net.get(name).OnServerInvoke = handler
end

--- Server: push to one player.
function Net.toClient(name, player, ...)
	Net.get(name):FireClient(player, ...)
end

--- Server: push to everyone.
function Net.toAll(name, ...)
	Net.get(name):FireAllClients(...)
end

--- Client: listen to a server push.
function Net.listen(name, handler)
	assert(RunService:IsClient(), "Net.listen is client only")
	return Net.get(name).OnClientEvent:Connect(handler)
end

--- Client: fire an event at the server.
function Net.send(name, ...)
	assert(RunService:IsClient(), "Net.send is client only")
	Net.get(name):FireServer(...)
end

--- Client: call the Action router. Always returns (ok, resultOrError).
function Net.invoke(actionName, payload)
	assert(RunService:IsClient(), "Net.invoke is client only")
	local ok, result, err = pcall(function()
		return Net.get("Action"):InvokeServer(actionName, payload)
	end)
	if not ok then
		return false, "Request failed"
	end
	if result == false then
		return false, err or "Request refused"
	end
	return true, err
end

return Net
