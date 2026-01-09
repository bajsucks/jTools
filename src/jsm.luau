--[[
    jStateManager
    Simple state manager

    structure:
    .new() -> SM
    SM.StateChanged is a signal that returns (label:string, SentByTween:boolean?)
]]
local Janitor = require(script.Parent.Janitor)
local Scaler = require(script.Parent.Scaler)
local SignalPlus = require(script.Parent.SignalPlus)
local Waiter = require(script.Parent.Waiter).new()

local module = {}
local SM = {}
SM.__index = SM
local Register = {}
module.Registered = SignalPlus()

export type SM = typeof(module.new())

--[[
    Creates a new SM object
]]
function module.new(SMLabel:string)
	local self = setmetatable({}, SM)
	self.StateChanged = SignalPlus()
    self.States = {} :: {[string]: any}
    self.j = Janitor.new()
    self.SMLabel = SMLabel
	Register[SMLabel] = self
    Waiter:Resolve(SMLabel, self)
    module.Registered:Fire(SMLabel)
	return self
end
--[[
    Gets a label
]]
function module.GetLabel(SMLabel:string): SM?
    return Register[SMLabel]
end

--[[
    Waits for the label to appear
]]
function module.WaitForLabel(SMLabel:string): SM?
    if Register[SMLabel] then return Register[SMLabel] end
    return Waiter:Wait(SMLabel)
end
--[[
    Sets multiple labels to the same value
]]
function SM.SetThese(self:SM, value:any, ...:string)
    for i = 1, select("#", ...) do
        local label = select(i, ...)
        self.States[label] = value
    end
end

function SM.Set(self:SM, label:string, value:any, duration:number?, SentByTween:boolean?)
    local oldValue = self.States[label]
    if oldValue == value then return end
	self.States[label] = value
    self.StateChanged:Fire(label, SentByTween)
    if duration then
        self.j:Add(task.delay(duration, function()
            self.States[label] = nil
            self.StateChanged:Fire(label, SentByTween)
        end))
    end
end
--[[
    Set a value to tween; Uses the Scaler library.
    Note that set of BeginValue and EndValue will still fire .StateChanged() with second argument being false, since they're outside the tween.
]]
function SM.SetTween(self:SM, label:string, BeginValue:any, EndValue:any, TweenInfo:TweenInfo, CancelOut:boolean?)
    self:Set(label, BeginValue)
    local s = Scaler.new(BeginValue)
    local tween = s:Tween("a", EndValue, TweenInfo)
    local nv = s:GetNumberval("a")
    local j2 = Janitor.new()
    self.j:Add(j2, "Destroy")
    self.j:Add(s, "Destroy")
    local function Cancel()
        j2:Destroy()
        s:Destroy()
    end
    local function TweenComplete()
        self:Set(label, EndValue)
        Cancel()
    end
    j2:Add(nv.Changed:Connect(function()
       self:Set(label, nv.Value, nil, true)
    end))
    if CancelOut then
        j2:Add(self.StateChanged:Connect(function(ChangedLabel:string, SentByTween:boolean?)
            if not SentByTween and ChangedLabel == label then
                Cancel()
            end
        end))
    end
    tween:Play()
    j2:Add(tween)
    tween.Completed:Once(TweenComplete)
end


--[[
    Returns whether this state ~= nil
]]
function SM.Has(self:SM, label:string): boolean
    return self.States[label] ~= nil
end

--[[
    Same as .Has() but for multiple labels
]]
function SM.HasThese(self:SM, ...:string): boolean
    for i = 1, select("#", ...) do
        local label = select(i, ...)
        if self.States[label] == nil then return false end
    end
    return true
end

--[[
    Returns a state
]]
function SM.Get(self:SM, label:string): any
    return self.States[label]
end

--[[
    Returns multiple states as a tuple
]]
function SM.GetThese(self:SM, ...:string)
    local toreturn = {}
    for i = 1, select("#", ...) do
        local label = select(i, ...)
        table.insert(toreturn, self.States[label])
    end
    return table.unpack(toreturn)
end

function SM.Clear(self:SM)
    self.States = {}
	self.j:Cleanup()
end

function SM.Destroy(self:SM)
	self.j:Destroy()
    self.StateChanged:DisconnectAll()
    Register[self.SMLabel] = nil
end

-- function SM.Track(self:SM)
	
-- end

-- function SM.Untrack(self:SM)
	
-- end

return module