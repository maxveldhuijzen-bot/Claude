--[[
	StateController — the client's mirror of server state.

	Everything the UI draws reads from here. Nothing else calls Net directly for
	state, so there is exactly one copy of the truth on the client and one place
	that goes stale if replication breaks.
]]

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Net = require(Shared.Modules.Net)
local Signal = require(Shared.Modules.Signal)

local StateController = {}

StateController.hot = {}
StateController.profile = {}
StateController.ready = false

StateController.changed = Signal.new() -- hot stats moved
StateController.profileChanged = Signal.new() -- inventory / quests / upgrades moved

function StateController.init()
	Net.listen("State", function(payload)
		if type(payload) ~= "table" then
			return
		end
		StateController.hot = payload
		StateController.ready = true
		StateController.changed:Fire(payload)
	end)

	Net.listen("Profile", function(payload)
		if type(payload) ~= "table" then
			return
		end
		StateController.profile = payload
		StateController.profileChanged:Fire(payload)
	end)
end

function StateController.start()
	-- Ask for a full snapshot in case we finished loading after the server sent
	-- the join push.
	task.delay(1, function()
		if not StateController.ready then
			Net.invoke("resync")
		end
	end)
end

--- Fire-and-forget action. Returns (ok, resultOrMessage).
function StateController.request(action, payload)
	return Net.invoke(action, payload)
end

function StateController.owns(passKey)
	local passes = StateController.profile.passes
	return passes ~= nil and passes[passKey] == true
end

function StateController.upgradeLevel(id)
	local upgrades = StateController.profile.upgrades
	return (upgrades and upgrades[id]) or 0
end

function StateController.hasZone(zoneId)
	local zones = StateController.profile.zones
	return zones ~= nil and zones[zoneId] == true
end

return StateController
