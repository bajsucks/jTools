--[[
    This allows you to scale a multiplier with multiple multipliers.
    For example, if default is 1, and another thing scales it 0.5, and another thing scales it 0.5, the result will be 0.25.

    Currently this only supports multiplication - might add things like addition later.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Janitor = require(ReplicatedStorage.Packages.jTools.Janitor)
local SignalPlus = require(ReplicatedStorage.Packages.jTools.SignalPlus)

local module = {}
local Scaler = {}
Scaler.__index = Scaler

local Labels: {Scaler} = {}
local UIDs: {[Instance]: string} = {}
local UIDCounter = 0
--[[
    Create a new Scaler object
    @param Default baseline value
    @param label Optional label
]]
function module.new(Default:number, label:string?)
    local self = setmetatable({}, Scaler)
    self.Effects = {}
    self.Tweens = {}
    self.label = label
    self.Default = Default
    self.Changed = SignalPlus()
    self.Janitor = Janitor.new()
    if label then
        Labels[label] = self
    end

    return self
end
--[[
    Register a new property for an instance
]]
function module._newProperty(Instance:Instance, Property:string, DefaultValue:number)
    local UID = `{UIDs[Instance]}_{Property}`
    local self = module.new(DefaultValue, UID)
    self.Janitor:Add(self.Changed:Connect(function()
        local Result = self:GetResult()
        Instance[Property] = Result
    end), "Disconnect")
    Instance.Destroying:Once(function()
        UIDs[Instance] = nil
        self:Destroy()
    end)
    return self
end
--[[
    Register a new instance & property
]]
function module._newInstance(Instance:Instance, Property:string, DefaultValue:number)
    local InstanceUID = UIDs[Instance]
    if not InstanceUID then
        UIDCounter += 1
        UIDs[Instance] = UIDCounter
    end
    local UID = `{InstanceUID}_{Property}`
    if not Labels[UID] then
        return module._newProperty(Instance, Property, DefaultValue)
    else
        return Labels[UID]
    end
end
--[[
    Either gets the Scaler or creates a new one from instance & property

    @param DefaultValue The value without any modifications. If unspecified this will be set to 1. I am unsure if this works
]]
function module.FromInstance(Instance:Instance, Property:string, DefaultValue:number?)
    DefaultValue = DefaultValue or 1
    return module._newInstance(Instance, Property, DefaultValue)
end

--[[
    Assign a value to the effect
    @param EffectUID UID of the effect you're applying so that it doesn't interfere with other effects and so that you can modify it later
]]
function Scaler.Effect(self:Scaler, EffectUID:string, Value:number)
    local NumberVal = self:GetNumberval(EffectUID)
    NumberVal.Value = Value
end

function Scaler.GetNumberval(self:Scaler, EffectUID:string)
    local NumberVal:NumberValue? = self.Effects[EffectUID]
    if not NumberVal then
        NumberVal = Instance.new("NumberValue")
        NumberVal.Value = 1
        NumberVal.Changed:Connect(function()
            self.Changed:Fire()
        end)
        self.Effects[EffectUID] = NumberVal
    end
    return NumberVal
end
--[[
    Same as Effect but tweens from 1 to Value
]]
function Scaler.Tween(self:Scaler, EffectUID:string, Value:number, Info:TweenInfo)
    local nv = self:GetNumberval(EffectUID)
    return TweenService:Create(nv, Info, {Value = Value})
end

function Scaler.GetResult(self:Scaler)
    local Result = self.Default
    for _, nv:NumberValue in self.Effects do
        Result *= nv.Value
        if Result == 0 then break end
    end
    return Result
end

function Scaler.Destroy(self:Scaler)
    for _, nv:NumberValue in self.Effects do 
        nv:Destroy()
    end
    if not self.label then return end
    Labels[self.label] = nil
    self.Janitor:Destroy()
    self = nil
end

export type Scaler = typeof(module.new())

return module