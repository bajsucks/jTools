--!strict
--[[
    Object pooling
]]
local Pool = {}
Pool.__index = Pool

export type Pool = typeof(setmetatable(
	{} :: {
		template: Instance,
		pool: { Instance },
	},
	Pool
))

function Pool.new(template: Instance, Count: number?): Pool
	local self = setmetatable({
		template = template,
		pool = {} :: { Instance },
	}, Pool)
	for _ = 1, Count or 0 do
		table.insert(self.pool, template:Clone())
	end
	return self
end

function Pool.Get(self: Pool, Parent: Instance?): Instance
	local Obj: Instance = table.remove(self.pool) or self.template:Clone()
	if Parent then
		Obj.Parent = Parent
	end
	return Obj
end

function Pool.Return(self: Pool, obj: Instance)
	obj.Parent = nil
	table.insert(self.pool, obj)
end

return Pool
