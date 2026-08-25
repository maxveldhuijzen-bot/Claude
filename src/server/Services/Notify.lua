--[[ Notify — server-to-client toast messages. ]]

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Net = require(Shared.Modules.Net)

local Notify = {}

--- kind is one of: good, bad, info, premium.
function Notify.send(player, message)
	if not player or not player.Parent then
		return
	end
	Net.toClient("Notify", player, {
		title = message.title,
		body = message.body,
		kind = message.kind or "info",
		duration = message.duration,
	})
end

function Notify.broadcast(message)
	Net.toAll("Notify", {
		title = message.title,
		body = message.body,
		kind = message.kind or "info",
		duration = message.duration,
	})
end

--- One-shot visual (hatch reveal, node shatter, rebirth flash).
function Notify.effect(player, payload)
	if not player or not player.Parent then
		return
	end
	Net.toClient("Effect", player, payload)
end

function Notify.effectAll(payload)
	Net.toAll("Effect", payload)
end

return Notify
