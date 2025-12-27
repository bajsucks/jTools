--!strict
--!native
--!optimize 2

local Sign = require(script:WaitForChild("Signal"))
type Signal = Sign.Signal<any>

export type QueuedInstance = {
	Instance : Instance,
	Active : boolean,
	StateChanged : Signal,
	Unloaded : Signal,
	Loaded : Signal,
	OnUnloading : Signal,
	Destroy : (self:QueuedInstance) -> nil,
	new : (Instance,Pool:any) -> QueuedInstance,
	Load : (self:QueuedInstance,Parent:Instance?) -> QueuedInstance,
	Unload : (self:QueuedInstance) -> QueuedInstance,
	Destroying : Signal,
	_Pool : any,
}

local Inst = {}
Inst.__index = Inst

function Inst.new(Instance:Instance,Pool:any) : QueuedInstance
	assert(Instance,"No instance provided!")
	Instance.Parent = nil
	
	local Data = {
		Instance = Instance,
		Active = false,
		StateChanged = Sign.new() :: Signal,
		Destroying = Sign.new(),
		Unloaded = Sign.new(),
		Loaded = Sign.new(),
		OnUnloading = Sign.new(true),
		_Pool = Pool,
	}
	
	local self = setmetatable(Data::any,Inst)
	
	Instance.Destroying:Once(function()
		if self.Active == nil then return end
		self:Destroy()
	end)
	
	return self :: QueuedInstance
end

function Inst:Destroy()
	local self = self :: QueuedInstance
	
	local Pool = self._Pool
	
	if Pool then
		Pool:Remove(Pool:GetIndex(self))
	end
	
	self.Destroying:Fire()
	if self.Instance then
		self.Instance:Destroy()
	end
	table.clear(self)
	setmetatable(self,nil)
end

function Inst:Load(Parent:Instance?) : QueuedInstance
	local self = self :: QueuedInstance
	
	local Parent = Parent or workspace
	
	if self._Pool then
		local Pool = self._Pool
		Pool._PoolTable:Pop(Pool:GetIndex(self))
		Pool._PoolTable:Push(self)
		Pool.ItemLoaded:Fire(self)
	end
	
	self.Active = true
	self.Instance.Parent = Parent
	self.StateChanged:Fire()
	self.Loaded:Fire()
	
	return self
end

function Inst:Unload()
	local self = self :: QueuedInstance
	
	if not self.Active then return self end
	
	self.OnUnloading:Fire()
	self.Instance.Parent = nil
	self.Active = false
	self.StateChanged:Fire()
	self.Unloaded:Fire()
	
	if self._Pool then
		local Pool = self._Pool
		Pool.ItemUnloaded:Fire(self)
	end
	
	return self
end

return Inst
