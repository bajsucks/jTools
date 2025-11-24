--!nonstrict
local TimedEffects = {}
local HttpService = game:GetService("HttpService")
TimedEffects.__index = TimedEffects

function TimedEffects.new()
	return setmetatable({List = {}}, TimedEffects)
end

function TimedEffects:Add(StartVal: number?): string
	local uuid = HttpService:GenerateGUID(false)
	self.List[uuid] = Instance.new("NumberValue")
	self.List[uuid].Value = StartVal or 0
	return uuid
end

function TimedEffects:Instance(uuid:string): NumberValue
	return self.List[uuid]
end

function TimedEffects:Remove(uuid:string)
	self.List[uuid]:Destroy()
	self.List[uuid] = nil
end

function TimedEffects:Clear()
	for uuid, value in self.List do
		value:Destroy()
		self.List[uuid] = nil
	end
end

function TimedEffects:GetValue(): number
	local Sum = 0
	for _, value in self.List do
		if not value then
            warn("Your circuit's dead, there's something wrong!")
            continue
        end
		Sum += value.Value
	end
	return Sum
end

return TimedEffects
