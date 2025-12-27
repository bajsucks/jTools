--!strict
--!native
--!optimize 2

local Signal = {}
Signal.__index = Signal

export type Signal<T...> = {
	_connections : {(T...) -> ()},
	_yielding : boolean,
	_timeout : number,
	new : () -> Signal<T...>,
	Fire : (self:Signal<T...>,...any) -> nil,
	Once : (self:Signal<T...>,Callback:(T...)->()) -> any,
	Connect : (self:Signal<T...>,Callback:(T...)->()) ->  { Disconnect: () -> () },
	Wait : (self:Signal<T...>) -> T...
}

function Signal.new<T...>(yielding:boolean?,timeout:number?) : Signal<T...>
	local Tab = {_connections = {},_yielding = yielding or false,_timeout = timeout or 1} :: any
	return setmetatable(Tab,Signal) :: Signal<T...>
end

-- provided function fires every signal until disconnected
function Signal:Connect<T...>(Callback:(T...)->()) :  { Disconnect: () -> nil }
	local self = self :: Signal<T...>
	table.insert(self._connections,Callback)
	
	return {Disconnect = function()
		for i,con in ipairs(self._connections) do
			if con == Callback then
				table.remove(self._connections,i)
				break
			end
		end
	end}
end

-- fire the signal
function Signal:Fire<T...>(...:T...)
	local self = self :: Signal<T...>
	
	local RunningThreads = {}
	
	for _,callback in (self._connections) do
		local Thread = task.spawn(callback,...)
		if self._yielding then
			table.insert(RunningThreads,Thread)
		end
	end
	
	if self._yielding and #RunningThreads > 0 then
		local StartTime = os.clock()
		while os.clock() - StartTime < self._timeout do
			local Done = true
			
			for _,thread in RunningThreads do
				if coroutine.status(thread) ~= "dead" then
					Done = false
					break
				end
			end
			
			if Done then break end
			game:GetService("RunService").Heartbeat:Wait()
		end
	end
	
end

-- the provided function fires once
function Signal:Once<T...>(callback: (T...) -> ())
	local self = self :: Signal<T...>
	local Connection
	Connection = self:Connect(function(...)
		callback(...)
		Connection:Disconnect()
	end)
	return Connection
end

-- yields until signal
function Signal:Wait<T...>(callback:(T...)->()):T...
	local self = self :: Signal<T...>
	local Thread = coroutine.running()
	local Connection
	Connection = self:Connect(function(...)
		Connection:Disconnect()
		coroutine.resume(Thread,...)
	end)
	return coroutine.yield()
end

return Signal