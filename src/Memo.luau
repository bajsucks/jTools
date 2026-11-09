--!strict
--[[
    Memoization
]]
local module = {}
local memo = {}
memo.__index = memo

export type memo<K, V> = {
	fn: (K) -> V,
	cache: { [K]: V },
}

function module.new<K, V>(fn: (K) -> V)
	local self = setmetatable({}, memo)
	self.fn = fn
	self.cache = {}
	return self
end

function memo.Do<K, V>(self: memo<K, V>, Key: K)
	local cached = self.cache[Key]
	if cached ~= nil then
		return cached
	end
	local result = self.fn(Key)
	self.cache[Key] = result
	return result
end

function memo.Release<K, V>(self: memo<K, V>, Key: K)
	self.cache[Key] = nil
end

function memo.Clear<K, V>(self: memo<K, V>)
	table.clear(self.cache)
end

return module
