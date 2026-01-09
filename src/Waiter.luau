--[[
    No more constant task.wait() loops! Much more efficient and much more compact
    Pretty sure that's literally promise but doesn't store the state, so if the thing is resolved before :Wait() is called, it will yield forever unless resolved again
]]
local module = {}
local Waiter = {}
Waiter.__index = Waiter

export type Waiter = typeof(module.new())

function module.new()
    local self = setmetatable({}, Waiter)
    self.Queue = {} :: {[string]: thread}
    return self
end

--[[
    Yields the current thread until the key is resolved
]]
function Waiter.Wait(self:Waiter, key: string): ...any
    if not self.Queue[key] then
        self.Queue[key] = {}
    end

    table.insert(self.Queue[key], coroutine.running())
    return coroutine.yield()
end

--[[
    Resumes all threads waiting for the key
]]
function Waiter.Resolve(self:Waiter, key: string, ...: any)
    local threads = self.Queue[key]
    if not threads then return end

    self.Queue[key] = nil

    for _, thread in threads do
        task.spawn(thread, ...)
    end
end

function Waiter.Destroy(self:Waiter)
    for _, threads: {thread} in self.Queue do
        for _, thread: thread in threads do
            if coroutine.status(thread) == "suspended" then
                task.cancel(thread)
            end
        end
    end
    self.Queue = {}
    self = nil
end

return module