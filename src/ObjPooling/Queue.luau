--!strict
--!native
--!optimize 2

local Queue = {}
Queue.__index = Queue

export type Queue = {
	_Cont : {any},
	len:number,
	new : () -> Queue,
	Push : (self:Queue,v:any) -> Queue,
	Pop : (self:Queue,number) -> (any,Queue),
	Clear : (self:Queue) -> Queue,
	Get : (self:Queue) -> ({},Queue),
	Peek : (self:Queue,number) -> (any?,Queue),
	GetAtIndex : (self:Queue,number) -> any,
	Swap : (self:Queue,number,number) -> Queue,
	_Front : number,
	_Back : number
}

-- new queue
function Queue.new(allocate:number?) : Queue
	local Data = {
		_Cont = table.create(allocate or 0),
		len = 0,
		_Front = 1,
		_Back = 0
	}
	local self = setmetatable(Data::any,Queue)
	return self :: Queue
end

local function Reformat(Table:{})
	local NewTable = {}
	
	local Index = 1
	for _, Value in pairs(Table) do
		NewTable[Index] = Value
		Index = Index + 1
	end
	
	return NewTable
end

-- get the whole table of contents
function Queue:Get() : ({},Queue)
	local self = self :: Queue
	return self._Cont, self
end

-- adds a value to the bottom
function Queue:Push(v:any) : Queue
	local self = self :: Queue
	self._Back += 1
	self._Cont[self._Back] = v
	self.len += 1
	return self
end

-- removes top value from the queue and returns it
function Queue:Pop() : (any?, Queue)
	local self = self :: Queue
	if self._Front > self._Back then return nil, self end

	local Item = self._Cont[self._Front]
	self._Cont[self._Front] = nil
	self._Front += 1
	self.len -= 1

	return Item, self
end

-- returns top value without removing it
function Queue:Peek(index:number?) : (any?,Queue)
	local self = self :: Queue
	self.len = self._Back - self._Front + 1

	local Index = index or self.len
	local Item = self._Cont[Index]

	self.len = self._Back - self._Front + 1
	return Item,self
end

-- clears the queue
function Queue:Clear() : Queue
	local self = self :: Queue
	table.clear(self._Cont)
	self.len = self._Back - self._Front + 1
	return self
end

function Queue:Swap(a:number,b:number) : Queue
	local self = self :: Queue
	self._Cont[a], self._Cont[b] = self._Cont[b], self._Cont[a]
	return self
end

function Queue:GetAtIndex(n:number) : any
	local self = self :: Queue
	local index = self._Front + (n - 1)
	if index > self._Back then
		return nil
	end
	return self._Cont[index]
end

return Queue