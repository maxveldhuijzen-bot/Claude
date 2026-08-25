--[[
	Signal — a minimal, allocation-light event object.
	Used for server-internal and client-internal fan-out where a
	BindableEvent would be overkill (and would deep-copy arguments).
]]

local Connection = {}
Connection.__index = Connection

function Connection:Disconnect()
	if not self.connected then
		return
	end
	self.connected = false

	local signal = self._signal
	local index = table.find(signal._handlers, self)
	if index then
		table.remove(signal._handlers, index)
	end
end

Connection.Destroy = Connection.Disconnect

local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ _handlers = {} }, Signal)
end

function Signal:Connect(callback)
	assert(type(callback) == "function", "Signal:Connect expects a function")

	local connection = setmetatable({
		connected = true,
		_signal = self,
		_callback = callback,
	}, Connection)

	table.insert(self._handlers, connection)
	return connection
end

function Signal:Once(callback)
	local connection
	connection = self:Connect(function(...)
		connection:Disconnect()
		callback(...)
	end)
	return connection
end

function Signal:Fire(...)
	-- Iterate a copy: handlers may disconnect themselves mid-fire.
	for _, connection in ipairs(table.clone(self._handlers)) do
		if connection.connected then
			task.spawn(connection._callback, ...)
		end
	end
end

--- Fire synchronously — errors propagate to the caller. Use for ordered logic.
function Signal:FireSync(...)
	for _, connection in ipairs(table.clone(self._handlers)) do
		if connection.connected then
			connection._callback(...)
		end
	end
end

function Signal:Wait()
	local thread = coroutine.running()
	self:Once(function(...)
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

function Signal:Destroy()
	for _, connection in ipairs(table.clone(self._handlers)) do
		connection:Disconnect()
	end
	table.clear(self._handlers)
end

return Signal
