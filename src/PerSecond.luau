-- todo rewrite
local List = {}
local module = {}
module.__index = List

function module.new(expire:number)
	return setmetatable({expire = expire, list = {}}, module)
end

local t = 0
function List:AddItem(value: number)
	if typeof(value) ~= "number" then
        warn("incorrect value passed in Per second calculation!")
        return
    end
	t += 1
	local rec = tostring(t)
	task.spawn(function()
		self.list[rec] = {os.clock(), value}
		task.wait(self.expire)
		self.list[rec] = nil
	end)
end

function List:GetPerSecond()
	local totalValue = 0
	local oldestTime = math.huge
	local currentTime = os.clock()

	for _, tbl in self.list do
		totalValue += tbl[2]
		oldestTime = math.min(oldestTime, tbl[1])
	end

	if totalValue < 1 then return 0 end

	local actualWindow = currentTime - oldestTime
	if actualWindow < 0.1 then return 0 end -- avoid division by tiny numbers
	
	local result = totalValue / actualWindow
	return result < totalValue and result or totalValue
end


return module