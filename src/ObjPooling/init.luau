--!strict
--!native
--!optimize 2

--[[

	 _____       __                       ___                                   
	|_   _|     / _|                     / _ \                                  
	  | | _ __ | |_ ___ _ __ _ __   ___ / /_\ \_ __ ___   __ _ _ __ _   _  __ _ 
	  | || '_ \|  _/ _ \ '__| '_ \ / _ \|  _  | '_ ` _ \ / _` | '__| | | |/ _` |
	 _| || | | | ||  __/ |  | | | | (_) | | | | | | | | | (_| | |  | |_| | (_| |
	 \___/_| |_|_| \___|_|  |_| |_|\___/\_| |_/_| |_| |_|\__,_|_|   \__,_|\__, |
    	                                                                     | |
        	                                                                 |_|
       	                                                                 
]]

local Warn = warn

local RS = game:GetService("RunService")

local QueuedInstance = require(script:WaitForChild("QueuedInst"))
type QueuedInstance = QueuedInstance.QueuedInstance

local Signal = require(script.QueuedInst:WaitForChild("Signal"))
type Signal = Signal.Signal<any>

local Queue = require(script:WaitForChild("Queue"))
type Queue = Queue.Queue

export type Pool = {
	_PoolTable : Queue,
	TableSize : number,
	Params : CompleteParams,
	DefaultInstance : Instance?,
	new : (size:number,instance:Instance,params:PoolParams) -> Pool,
	Destroy : (self:Pool) -> nil,
	Get : (self:Pool,Availiable:boolean?) -> QueuedInstance?,
	Add : (self:Pool,Instance) -> QueuedInstance,
	Remove : (self:Pool,Index:number?) -> QueuedInstance?,
	GetIndex : (self:Pool,Obj:QueuedInstance) -> number,
	LoadItem : (self:Pool,Instance?) -> QueuedInstance,
	LoadAll : (self:Pool) -> {QueuedInstance},
	GetAll : (self:Pool) -> {QueuedInstance},
	UnloadAll : (self:Pool) -> {QueuedInstance},
	ItemLoaded : Signal,
	ItemUnloaded : Signal
}

type CompleteParams = {
	LiveReusing : boolean,
	LoadWait : number,
	AutoExpand : boolean,
	MaxPoolSize : number,
	UnloadTimer : number
}

export type PoolParams = {
	LiveReusing : boolean?,
	LoadWait : number?,
	AutoExpand : boolean?,
	MaxPoolSize : number?,
	UnloadTimer : number?
}

local function warnf(condition:any,statement:string?):any
	if not condition then
		Warn(statement or "Error: condition failed!")
	end
	return condition
end

local POOLING = {}
POOLING.__index = POOLING

function POOLING.__len(tbl:Pool)
	return tbl._PoolTable.len
end

--creates a new object pool
function POOLING.new(PoolSize:number?,Inst:Instance?,Params:PoolParams?) : Pool
	
	warnf(not (PoolSize and not Inst),"'Inst' no provided, created empty table")
	warnf(not (Inst and not PoolSize),"'PoolSize' not provided, created empty table")
	
	local PoolTable = Queue.new(PoolSize)
	
	local Params:CompleteParams = {
		LiveReusing = (Params and Params.LiveReusing) or false,
		LoadWait = (Params and Params.LoadWait) or 0,
		AutoExpand = (Params and Params.AutoExpand) or false,
		MaxPoolSize = (Params and Params.MaxPoolSize) or math.huge,
		UnloadTimer = (Params and Params.UnloadTimer) or -1
	}
	
	local Metatable:any = {
		_PoolTable = PoolTable,
		TableSize = PoolTable.len,
		DefaultInstance = Inst,
		Params = Params,
		ItemLoaded = Signal.new(),
		ItemUnloaded = Signal.new()
	}
	
	if PoolSize and Inst then
		for i = 1,PoolSize do
			local QInst = QueuedInstance.new(Inst:Clone(),Metatable)
			PoolTable:Push(QInst)
			for i = 1,Params.LoadWait do
				game:GetService("RunService").Heartbeat:Wait()
			end
		end
	end
	
	Metatable.TableSize = PoolTable.len
	
	local self = setmetatable(Metatable,POOLING) :: Pool
	
	return self
end

--destroys object pool and all instances within it
function POOLING:Destroy()
	local self = self :: Pool
	for i,v in pairs((self._PoolTable:Get())) do
		v:Destroy()
	end
	self._PoolTable:Clear()
	setmetatable(self,nil)
end

-- addds a new pool object
function POOLING:Add(Inst:Instance|QueuedInstance) : QueuedInstance
	local self = self :: Pool
	if typeof(Inst) == "Instance" then
		assert(Inst:IsA("Instance"),"No instance provided! Cannot add "..typeof(Inst))
		local PooledObject = QueuedInstance.new(Inst,self)
		self._PoolTable:Push(PooledObject)
		self.TableSize = self._PoolTable.len
		return PooledObject
	else
		self._PoolTable:Push(Inst)
		self.TableSize = self._PoolTable.len
		return Inst
	end
end

-- gets first non-busy instance
function POOLING:Get(Available:boolean?):QueuedInstance?
	local self = self :: Pool
	Available = Available ~= false

	for i = self._PoolTable._Front, self._PoolTable._Back do
		local v = self._PoolTable:GetAtIndex(i - self._PoolTable._Front + 1)
		if v and (v.Active == not Available or self.Params.LiveReusing) then
			return v
		end
	end

	warn("No available instance found!")
	return nil
end

local function Find(t:{},o:any) : number?
	for i,v in pairs(t) do
		if v == o then
			return i
		end
	end
	return
end

-- get index of an instance
function POOLING:GetIndex(Obj:QueuedInstance) : (number)
	local self = self :: Pool
	local v = warnf(Find(self._PoolTable._Cont,Obj),"No such item in table") + self._PoolTable._Front
	return v
end

-- remove an instance from the queue
function POOLING:Remove(Index:number?) : QueuedInstance?
	local self = self :: Pool
	local Index = Index or self._PoolTable.len
	local Item = self._PoolTable:Pop(Index)
	self.TableSize = self._PoolTable.len
	Item._Pool = nil
	
	return Item
end

function POOLING:LoadItem(parent:Instance?)
	local self = self :: Pool
	
	local Item = self:Get(true)
	
	if not Item then
		if self.DefaultInstance and self.Params.AutoExpand and self.TableSize < self.Params.MaxPoolSize then
			Item = self:Add(self.DefaultInstance:Clone())
		else
			return
		end
	end
	
	if not Item then return end
	
	Item.StateChanged:Fire()
	Item.Unloaded:Fire()
	Item:Load(parent)
	
	if self.Params.UnloadTimer > 0 then
		local ChangedStateCon
		local Changed = false
		
		task.delay(self.Params.UnloadTimer,function()
			if not Changed then
				ChangedStateCon:Disconnect()
				Item:Unload()
			end
		end)
		
		ChangedStateCon = Item.StateChanged:Once(function()
			Changed = true
		end)
	end
	self._PoolTable:Pop(self:GetIndex(Item))
	self._PoolTable:Push(Item)
	return Item
end

function POOLING:GetAll() : {QueuedInstance}
	local self = self :: Pool
	
	return (self._PoolTable:Get())
end

function POOLING:LoadAll()
	local self = self :: Pool
	
	for i,v in pairs((self._PoolTable:Get())) do
		if v.Active == false then
			v:Load()
		end
	end
	
	return (self._PoolTable:Get())
end

function POOLING:UnloadAll()
	local self = self :: Pool
	
	for i,v in pairs((self._PoolTable:Get())) do
		if v.Active then
			v:Unload()
		end
	end

	return (self._PoolTable:Get())
end

return POOLING