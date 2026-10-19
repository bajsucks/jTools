local ServerList = {}

local MemoryStoreService = game:GetService("MemoryStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Janitor = require(script.Parent.Packages.Janitor)
local Promise = require(script.Parent.Packages.Promise)
local jUtil = require(script.Parent.jUtil)

export type Server = {
	jobId: string,
	players: number,
	maxPlayers: number,
	country_iso: string,
	country: string,
	region_name: string,
	city: string,
	v: number, -- version
}

if RunService:IsClient() then
	return ServerList
end -- server only

ServerList.TTL = 90 -- entry expires if not refreshed
ServerList.INTERVAL = 30 -- refresh rate
ServerList.CACHE_TIME = 30 -- how long the results are cached for
ServerList.DEBOUNCE = 2 -- Debounce for push
ServerList.KEY = "ActiveServers"
ServerList.MAX_PAGES = 10
ServerList.STALE = false
if RunService:IsStudio() then
	ServerList.KEY = `STUDIO_{ServerList.KEY}`
end
ServerList.KEY = `{game.PlaceId}_{ServerList.KEY}`
ServerList.PROVIDER = "https://ipconfig.io/json"

local PAGE_SIZE = 200
local FETCH_RETRIES = 4
local FETCH_RETRY_DELAY = 20
local FAILED_GET_RETRY = 5
local VERSION = 1

local JobId = game.JobId ~= "" and game.JobId or `STUDIO_{HttpService:GenerateGUID(false)}`

local serverMap = MemoryStoreService:GetSortedMap(ServerList.KEY)

local started = false
local closed = false
local stop: (() -> ())?

local lastPush = -math.huge
local pushPending = false

local janitor: Janitor.Janitor?
local cache: { Server } = {}
local cachedAt = -math.huge
local pending: Promise.Promise?

local Known = false
local ours = {
	country_iso = "??",
	country = "Unknown",
	region_name = "Unknown",
	city = "Unknown",
	v = VERSION,
}

local pendingSet: Promise.Promise?

local function close()
	closed = true
	if not started then
		return
	end
	if pendingSet then
		pendingSet:timeout(5):await()
	end
	pcall(serverMap.RemoveAsync, serverMap, JobId)
end
game:BindToClose(close)

local function push()
	if not started or closed or pushPending then
		return
	end
	pushPending = true
	task.spawn(function()
		task.wait(math.max(ServerList.DEBOUNCE - (os.clock() - lastPush), 0))
		pushPending = false
		if not started or closed then
			return
		end
		lastPush = os.clock()

		pendingSet = (pendingSet or Promise.resolve())
			:andThen(function()
				if closed then
					return
				end
				local us = ServerList.Self() -- snapshot taken when the write actually runs
				us.jobId = nil
				return Promise.try(serverMap.SetAsync, serverMap, JobId, us, ServerList.TTL)
			end)
			:catch(function(err)
				warn("ServerList push fail:", err)
			end)
	end)
end

local function fetchLocation()
	return Promise.retryWithDelay(function()
		return Promise.try(function()
			return HttpService:JSONDecode(HttpService:GetAsync(ServerList.PROVIDER))
		end):andThen(function(data)
			if type(data) ~= "table" then
				return Promise.reject("unexpected response")
			end
			return data
		end)
	end, FETCH_RETRIES, FETCH_RETRY_DELAY)
		:andThen(function(data)
			Known = true
			for field in ours do
				local value = data[field]
				if type(value) == "string" and value ~= "" then
					ours[field] = value
				end
			end
			push()
		end)
		:catch(function(err)
			warn("Could not fetch server data. Are HTTP requests allowed? Err:", err)
		end)
end

local function fetchServers(): { Server }
	local servers = {}
	local lowerBound: string? = nil
	for _ = 1, ServerList.MAX_PAGES do
		local items = serverMap:GetRangeAsync(Enum.SortDirection.Ascending, PAGE_SIZE, lowerBound)
		for _, item in items do
			if typeof(item.value) ~= "table" then
				continue
			end
			local server = table.clone(item.value) :: Server
			server.jobId = item.key
			if server.v == VERSION then
				table.insert(servers, server)
			end
		end
		if #items < PAGE_SIZE then
			break
		end
		lowerBound = items[#items].key
	end
	return servers
end

local function refresh()
	local current = pending
	if not current then
		current = Promise.try(fetchServers)
			:andThen(function(servers)
				cache = servers
				cachedAt = os.clock()
				ServerList.STALE = false
			end)
			:catch(function(err)
				warn("ServerList get fail:", err)
				ServerList.STALE = true
				cachedAt = os.clock() - ServerList.CACHE_TIME + FAILED_GET_RETRY
			end)
			:finally(function()
				pending = nil
			end)

		-- if it already settled, `finally` ran before this assignment; don't store a dead promise
		if current:getStatus() == Promise.Status.Started then
			pending = current
		end
	end
	current:await()
end

--[[
	Initializes our server and pushes it to the memory store.

	@return Cleanup
]]
function ServerList.Init(): () -> ()
	if stop then
		return stop
	end
	if game.PrivateServerId ~= "" then
		return function() end
	end
	closed = false
	started = true

	janitor = Janitor.new()
	janitor:Add(Players.PlayerAdded:Connect(push))
	janitor:Add(Players.PlayerRemoving:Connect(push))
	janitor:AddPromise(fetchLocation())
	push() -- because of this we will show up as unknown for a sec until it fetches

	local loop = task.spawn(function()
		while true do
			task.wait(ServerList.INTERVAL)
			push()
		end
	end)
	local failsafe = task.delay(180, function()
		while not Known do
			fetchLocation()
			task.wait(180)
		end
	end)
	janitor:Add(loop)
	janitor:Add(failsafe)

	stop = function()
		task.spawn(close)
		started = false
		stop = nil
		if janitor then
			janitor:Destroy()
			janitor = nil
		end
	end
	return stop :: () -> ()
end

--[[
	Returns the list of available servers

	@param excludeSelf whether our own server is excluded from the list

	@yields
]]
function ServerList.Get(excludeSelf: boolean?): { Server }
	if os.clock() - cachedAt > ServerList.CACHE_TIME then
		refresh()
	end
	local result = {}
	if not excludeSelf and started and not closed then
		table.insert(result, ServerList.Self())
	end
	for _, server in cache do
		if server.jobId == JobId then
			continue
		end
		table.insert(result, table.clone(server))
	end
	return result
end

--[[
	Returns our server's info
]]
function ServerList.Self(): Server
	local us = jUtil.deepClone(ours)
	us.jobId = JobId
	us.players = #Players:GetPlayers()
	us.maxPlayers = Players.MaxPlayers
	return us
end

return ServerList
