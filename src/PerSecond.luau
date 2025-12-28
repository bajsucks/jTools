--[[
	Calculate stuff per second
]]
local t = require(script.Parent.t)
local module = {}
local List = {}
List.__index = List

function module.new(expire:number)
	return setmetatable({expire, {}}, List)
end
function List.AddItem(self:List, Value:number)
	assert(t.number(Value))
	table.insert(self[2], {os.clock(), Value})
	task.delay(self[1], table.remove, self[2], 1)
end

function List.GetPerSecond(self:List)
	local CurrentTime = os.clock()
	local OldestTime = CurrentTime
	local TotalVal = 0
	for _, tbl in self[2] do
		TotalVal += tbl[2]
		local RecordTime: number = tbl[1]
		OldestTime = math.min(OldestTime, RecordTime)
	end
	if TotalVal < 1 then return 0 end
	local result = TotalVal / self[1]
	return result < TotalVal and result or TotalVal
end

type List = typeof(module.new())


return module