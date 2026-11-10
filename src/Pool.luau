--!strict
--[[
    Object pooling
]]
local Pool = {}
Pool.__index = Pool

export type Pool<T> = typeof(setmetatable(
	{} :: {
		template: T,
		pool: { T },
	},
	Pool
))

function Pool.new<T>(template: T, Count: number?): Pool<T>
	local self = setmetatable({
		template = template,
		pool = {} :: { T },
	}, Pool)
	for _ = 1, Count or 0 do
		table.insert(self.pool, (template :: Instance):Clone())
	end
	return self
end

function Pool.Get<T>(self: Pool<T>, Parent: Instance?): T
	local Obj: Instance = table.remove(self.pool) or (self.template :: Instance):Clone()
	if Parent then
		Obj.Parent = Parent
	end
	return Obj :: T
end

function Pool.Return<T>(self: Pool<T>, Obj: T)
	(Obj :: Instance).Parent = nil
	table.insert(self.pool, Obj)
end

return Pool
