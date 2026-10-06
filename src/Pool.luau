--[[
    Object pooling
]]
local Pool = {}
Pool.__index = Pool

function Pool.new(template: Instance, Count: number?)
	local self = setmetatable({ template = template, pool = {} }, Pool)
	for _ = 1, Count or 0 do
		table.insert(self.pool, template:Clone())
	end
	return self
end

function Pool:Get(Parent: Instance?): Instance
	local Obj = table.remove(self.pool) or self.template:Clone()
	if Parent then
		Obj.Parent = Parent
	end
	return Obj
end

function Pool:Return(obj: Instance)
	obj.Parent = nil
	table.insert(self.pool, obj)
end

return Pool
