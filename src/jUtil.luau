local Util = {}
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService('RunService')
local Players = game:GetService("Players")
local Janitor = require(script.Parent.Janitor)
local t = require(script.Parent.t)

local debug = false

-- Object:IsA() but supports a table of types
function Util.IsA(Obj:Object, Type:{string})
	for _, T in Type do
		if Obj:IsA(T) then
			return true
		end
	end
	return false
end

function Util.GetChildrenWhichAre(Inst:Instance, Type:{string}) : {Instance} | {}
	local res = {}
	for _, v in Inst:GetChildren() do
		if Util.IsA(v, Type) then
			table.insert(res, v)
		end
	end
	return res
end

function Util.ClearChildrenWhichAre(Inst:Instance, Type:{string})
	for _, v in Inst:GetChildren() do
		if Util.IsA(v, Type) then
			v:Destroy()
		end
	end
end

function Util.ClearChildrenExcept(Inst:Instance, Type:{string})
	for _, v in Inst:GetChildren() do
		if not Util.IsA(v, Type) then
            v:Destroy()
        end
	end
end

--[[
	Alias to Util.ClearChildrenExcept(Inst, {"UIComponent"})
]]
function Util.ClearGUI(Inst:Instance)
	Util.ClearChildrenExcept(Inst, {"UIComponent"})
end

function Util.ClearDescendantsWhichAre(Inst:Instance, Type:{string})
	for _, v in Inst:GetDescendants() do
		if Util.IsA(v, Type) then
            v:Destroy()
        end
	end
end

function Util.ClearDescendantsExcept(Inst:Instance, Type:{string})
	for _, v in Inst:GetDescendants() do
		if not Util.IsA(v, Type) then
            v:Destroy()
        end
	end
end

function Util.GetDescendantsWhichAre(Inst:Instance, Type:{string}) : {Instance} | {}
	local res = {}
	for _, v in Inst:GetDescendants() do
		for _, T in Type do
			if v:IsA(T) then
				table.insert(res, v)
				break
			end
		end
	end
	return res
end

function Util.DictHasValue(dict, value)
	for _, v in dict do
		if v == value then return true end
	end
	return false
end
--[[
	Returns the number of indecies in a dictionary, or 0 if empty
]]
function Util.DictCount(dict)
	local i = 0
	for _ in dict do
		i += 1
	end
	return i
end
--[[
	Gets a random index from the given dictionary.
	Uses `math.random()` to select the random.
]]
function Util.RandFromDict(dict)
	local dc = Util.DictCount(dict)
	if dc == 0 then return end
	local n = math.random(1, dc)
	local i = 0
	for _, v in dict do
		i += 1
		if i == n then return v end
	end
	error("something went wrong lol how")
end

--[[
	Abbreviates a number
	Supports max of ~1e66-1e68

]]
function Util.Abr(Num: number): string
	local suffixes = {"", "K", "M", "B", "T", "QA", "QI", "SX", "SP", "OC", "NO", "DC", "UD", "DD", "TD", "QAD", "QID", "SXD", "SPD", "OCD", "NOD", "VG", "UVG"}
	if Num < 1000 then
		return tostring(math.floor(Num*10)/10)
	end
	local i = math.floor(math.log10(math.abs(Num)) / 3)
	-- 51300 51.3K
	local abbreviatedNum = Num / (1000 ^ i)
	-- 51300 / (1000 ^ 5)
	local formattedNum = string.format("%.2f", abbreviatedNum)
	if string.match(formattedNum, "%.00$") then
		formattedNum = string.gsub(formattedNum, "%.00$", "")
	end
	return formattedNum..(suffixes)[i + 1]
end

--[[
	Modulo wrapper. Wraps the number around itself if Num > Max.
	(12, 10) -> 2
	(8, 10) -> 8
	(10, 10) -> 10
]]
function Util.WrapNumber(Num: number, Max:number)
    local rem = Num % Max
    if rem == 0 then
        return Max
    else
        return rem
    end
end
--[[
	Debris but better
	Minimum wait time - 1 frame
]]
function Util.Debris(Inst:Instance|{Instance}, s:number)
	if typeof(s) ~= "number" then
        s = 0
    end
	if typeof(Inst) == "table" then
		for _, v in Inst do
			task.delay(s, function()
                v:Destroy()
            end)
		end
	elseif typeof(Inst) == "Instance" then
		task.delay(s, function()
            Inst:Destroy()
        end)
	else
		error("Invalid instance provided for Debris!", 2)
	end
end
--[[
	Disable reset on the client
]]
function Util.ClientDisableReset()
	local coreCall do
		local MAX_RETRIES = 8
		local StarterGui = game:GetService('StarterGui')

		function coreCall(method, ...)
			local result = {}
			for _ = 1, MAX_RETRIES do
				result = {pcall(StarterGui[method], StarterGui, ...)}
				if result[1] then
					break
				end
				RunService.Stepped:Wait()
			end
			return unpack(result)
		end
	end
	coreCall('SetCore', 'ResetButtonCallback', false)
end
--[[
	Sets the Y axis of a vector to 0 and returns the resulting vector
]]
function Util.VectorNoY(Vec:Vector3): Vector3
	return Vector3.new(Vec.X, 0, Vec.Z)
end
--[[
	I'm not sure if this works
]]
function Util.Preload(List: {string})
	local result, err = pcall(function()
		ContentProvider:PreloadAsync(List)
	end)
	if not result then 
        error(err, 2)
    end
end

-- this finds new position value for part being scaled toward pivot
local function scaleToPivot(pivotPos, partPos, scaleFactor)
	return Vector3.new(
		(pivotPos.X + scaleFactor * (partPos.X - pivotPos.X)),
		(pivotPos.Y + scaleFactor * (partPos.Y - pivotPos.Y)),
		(pivotPos.Z + scaleFactor * (partPos.Z - pivotPos.Z))
	)
end
--[[
	Scale a part accounting for it's pivot
]]
function Util.PivotScale(inst: BasePart, scale: number)
	if not inst:IsA("BasePart") or not scale then
        error("Incorrect arguments passed!", 2)
    end
	local pivotPos = inst:GetPivot().Position

	inst.Size *= Vector3.new(scale, scale, scale)
	inst.Position = scaleToPivot(pivotPos, inst.Position, scale)
	inst.PivotOffset = CFrame.new(inst.PivotOffset.Position * scale)
end
--[[
	Converts seconds to a readable format
	@param format Available formats: 1 - XXd XXh XXm XXs, 2 - XX:XX:XX:XX Default: 1
]]
function Util.SecondsToReadableTime(s:number, format:number?): string
	if not s then
        warn("Convert fail: No seconds were provided!")
        return
    end
	format = format or 1
	local days = math.floor(s/86400)
	local hours = math.floor((s % 86400)/3600)
	local minutes = math.floor(((s % 86400) % 3600)/60)
	local seconds = math.floor((((s % 86400) % 3600)%60)/1)
	if format == 1 then
		if s >= 86400 then
			return string.format("%id %02ih %02im %02is", days, hours, minutes, seconds)
		end
		if s >= 3600 then
			return string.format("%02ih %02im %02is", hours, minutes, seconds)
		end
		if s >= 60 then
			return string.format("%02im %02is", minutes, seconds)
		end
		return string.format("%02is", seconds)
	else
		if s >= 86400 then
			return string.format("%i:%02i:%02i:%02i", days, hours, minutes, seconds)
		end
		if s >= 3600 then
			return string.format("%02i:%02i:%02i", hours, minutes, seconds)
		end
		if s >= 60 then
			return string.format("%02i:%02i", minutes, seconds)
		end
		return string.format("%02i", seconds)
	end
end
--[[
	Returns whether a table/dict is empty
]]
function Util.IsTableEmpty(dict:{[any]: any}): boolean
	for _ in dict do
		return false
	end
	return true
end
--[[
	Clone a table/dict and returns the clone.
	Does not support recursion!
]]
function Util.deepClone(original: {})
	if typeof(original) ~= "table" then
		error("Can only deep clone tables!", 2)
	end
	local clone = table.clone(original) 
	for key, value in original do
		if type(value) == "table" then
			clone[key] = Util.deepClone(value)
		end
	end
	return clone
end

--[[
	Randomizes indecies of a table
	Probably not entirely random
]]
function Util.ShuffleTable(tbl: {})
	local r = Random.new()
    for i = #tbl, 2, -1 do
        local j = r:NextInteger(1, i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
end

function Util.WaitForChildWhichIsA(instance:Instance, Types:{string}, timeout:number?)
	timeout = timeout or 10
	local currentTimeout = 0
	local child

	for _, v in instance:GetChildren() do
		if Util.IsA(v, Types) then return v end
	end

	local j = Janitor.new()
	j:Add(instance.ChildAdded:Connect(function(c)
		if Util.IsA(c, Types) then
			child = c
		end
	end), "Disconnect")

	repeat
        local delta = task.wait()
        currentTimeout += delta
    until child or currentTimeout > timeout

	if currentTimeout > timeout then
        error(`infinite yield possible on :WaitForChildWhichIsA({Types})!`, 2)
    end

	j:Destroy()
	return child
end
--[[
	Prompt the local player to add the game to favorites
]]
function Util.PromptAddGameToFavorites()
	local AvatarEditorService = game:GetService("AvatarEditorService")
	AvatarEditorService:PromptSetFavorite(game.PlaceId, Enum.AvatarItemType.Asset, true)
end
do
	local db = {}
	local queue = {}
	--[[
		This needs review
	]]
	function Util.GiveBadge(plr, id)
		if not plr or not id then return end
		if not db[plr] then db[plr] = true else
			queue[plr] = queue[plr] or {}
			table.insert(queue[plr], id)
			return
		end
		local BadgeService = game:GetService("BadgeService")
		local success, badgeInfo = pcall(BadgeService.GetBadgeInfoAsync, BadgeService, id)
		if success then
			if badgeInfo.IsEnabled then
				local awarded, errorMessage = pcall(BadgeService.AwardBadgeAsync, BadgeService, plr.UserId, id)
				task.delay(3, function()
					db[plr] = false
					if queue[plr] and queue[plr][1] then
						Util.GiveBadge(plr, table.remove(queue[plr], 1))
					end
				end)
				if not awarded then
					warn("Error while awarding badge:", errorMessage)
				end
			end
		else
			warn("Error while fetching badge info!")
			db[plr] = false
		end
	end
end

if RunService:IsClient() then
	--[[
		Switch player controls on/off
	]]
	function Util.ChangeControls(state: boolean)
		local LocalPlayer = Players.LocalPlayer
		local Controls = require(LocalPlayer.PlayerScripts.PlayerModule):GetControls()
		if state then
			Controls:Enable()
		else
			Controls:Disable()
		end
	end
	--[[
		Returns UserInputService.MouseEnabled
	]]
	function Util.HasMouse()
		local UserInputService = game:GetService("UserInputService")
		return UserInputService.MouseEnabled
	end
	--[[
		Returns UserInputService.PreferredInput
	]]
	function Util.GetPreferredInput()
		local UserInputService = game:GetService("UserInputService")
		return UserInputService.PreferredInput
	end
	--[[
		Sets leaderboard (player list) CoreGUI on/off
	]]
	function Util.PlayerList(state: boolean)
		game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, state)
	end
end

--[[
	Returns player's friends on this server.
	If PlayerList is provided, will search that list instead.
]]
function Util.GetFriendsOnServer(Player:Player, PlayerList:{Player}?)
	local result = {}
	for _, p in (PlayerList and PlayerList or Players:GetPlayers()) do
		if Player:IsFriendsWithAsync(p.UserId) then
			table.insert(result, p)
		end
	end
	return result
end

local checkGradientBar = t.tuple(t.userdata, t.table)
--[[
	Creates hard color transitions in a UIGradient.
	Useful for segmented progress bars
	
	@param gradient The UIGradient to modify.
	@param intersects A list of {Color1: Color3, Color2: Color3, Intersect: number (0-1)} tables.
]]
function Util.GradientBar(gradient: UIGradient, intersects: {Color1: Color3, Color2: Color3, Intersect: number}): ()
	if debug then
		assert(checkGradientBar(gradient, intersects))
	end
	table.sort(intersects, function(a, b)	
		return a.Intersect < b.Intersect
	end)
	local sequence = {}
	for _, v in intersects do
		local C1 = v.Color1
		local C2 = v.Color2
		local Intersect = v.Intersect
		if Intersect <= .001 then
			Intersect = 0
		end
		if Intersect >= .999 then
			Intersect = 1
		end
		if Intersect == 1 or Intersect == 0 then
			table.insert(sequence, ColorSequenceKeypoint.new(Intersect, C1))
			continue
		end
		table.insert(sequence, ColorSequenceKeypoint.new(Intersect - 0.01, C1))
		table.insert(sequence, ColorSequenceKeypoint.new(Intersect, C2))
	end
	gradient.Color = ColorSequence.new(sequence)
end
local checkTweenPivotTo = t.tuple(t.userdata, t.userdata, t.CFrame)
--[[
	Tween a model to a target CFrame;
	This needs review
]]
function Util.TweenPivotTo(PV:PVInstance, info:TweenInfo, targetcf:CFrame)
	if debug then
		assert(checkTweenPivotTo(PV, info, targetcf))
	end
	local TweenService = game:GetService("TweenService")
	task.spawn(function()
		local val = Instance.new("CFrameValue")
		val.Value = PV:GetPivot()
		local con = val.Changed:Connect(function()
			PV:PivotTo(val.Value)
		end)
		local tw = TweenService:Create(val, info, {Value = targetcf})
		tw:Play()
		tw.Completed:Wait()
		con:Disconnect()
	end)
end
local checkBulkPivotTo = t.tuple(t.table, t.table)
--[[
	workspace:BulkMoveTo, but accounts for pivot
]]
function Util.BulkPivotTo(models:{PVInstance}, CFrames:{CFrame}, mode:Enum.BulkMoveMode)
	if debug then
		assert(checkBulkPivotTo(models, CFrames))
	end
	local newCFrames = {}
	local newModels = {}
	for i, v in models do
		local pivotOffset = v:GetPivot():Inverse() * v.PrimaryPart.CFrame
		table.insert(newModels, v.PrimaryPart)
		table.insert(newCFrames, CFrames[i] * pivotOffset)
	end
	workspace:BulkMoveTo(newModels, newCFrames, mode)
end

function Util.HasProperty(Obj:Instance, Property:string)
	local has = pcall(function()
		local _ = Obj[Property]
	end)
	return has
end
local checkResolvePath = t.tuple(t.union(t.table, t.userdata), t.string)
--[[
	Get an object from a table/instance using a path
	Format: (PlayerData, "Inventory/Weapons/Weapon1")
	Will return nil if path is invalid
]]
function Util.ResolvePath(root:Instance|{[any]: any}, path: string): any?
	if debug then
		assert(checkResolvePath(root, path))
	end
    local segments = string.split(path, "/")
    local current: any = root

    for _, segment in segments do

        if type(current) == "table" then
            current = current[segment]
        elseif type(current) == "userdata" and current:IsA("Instance") then
            current = current:FindFirstChild(segment) or current[segment]
		else
			return nil
		end

        if current == nil then
            return nil
        end
    end

    return current
end
local checkRandom = t.tuple(t.number, t.number)
--[[
	math.random() but safe-ish (way harder to bruteforce)
]]
function Util.random(min:number, max:number)
	if debug then
		assert(checkRandom(min, max))
	end
    local Unsafe = math.random(min, max*10*math.random(1, 10))
    return Util.WrapNumber(Unsafe, max)
end

--[[
    Returns what day it is rn as a whole number
]]
function Util.Today()
    return math.floor(os.time() / 86400)
end

--[[
    Returns the number of seconds left until tomorrow
]]
function Util.SecondsUntilTomorrow()
    return 86400 - (os.time() % 86400)
end

local checkWeld = t.tuple(t.userdata, t.userdata)
--[[
	Weld a to b, parent weld to a and return the weld
]]
function Util.Weld(a:Instance, b:Instance)
	if debug then
		assert(checkWeld(a, b))
	end
	local Weld = Instance.new("WeldConstraint")
	Weld.Part0 = a
	Weld.Part1 = b
	Weld.Parent = a
	return Weld
end
local checkRanges = t.string
--[[]
	Iterate through ranges formatted as start:end
	example:
	Ranges("1:2 2:3 3:4") -> (1, 2), (2, 3), (3, 4)
]]
function Util.Ranges(str:string)
	if debug then
		assert(checkRanges(str))
	end
    local iterator = string.gmatch(str, "(%d+):(%d+)")
    
    return function()
        local startStr, endStr = iterator()
        if startStr and endStr then
            return tonumber(startStr), tonumber(endStr)
        end
        return nil
    end
end
local checkBindToHz = t.tuple(t.callback, t.number)
--[[
	Binds a callback to run on a set frequency
	sumdt - time delta accumulated since last call

	@param Hz Hz > 1 < 60, whole number

	@return Connection
]]
function Util.BindToHz(callback:(sumdt: number)->(), Hz:number)
	if debug then
		assert(checkBindToHz(callback, Hz))
	end
	Hz = math.clamp(math.floor(Hz), 1, 60)
	local Interval = 1/Hz
	local AccumulatedDt = 0
	return RunService.Heartbeat:Connect(function(dt)
		AccumulatedDt += dt
		if AccumulatedDt >= Interval then
			callback(AccumulatedDt)
			AccumulatedDt -= Interval
		end
	end)
end
local checkBindToFrame = t.tuple(t.callback, t.number, t.optional(t.string))
--[[
	Binds a callback to run every n-th fire of a RunService event
	If Event is not provided, defaults to Heartbeat
	sumdt - time delta accumulated through the frames

	@param Frame >= 1, whole number, how many frames to wait
	@param Event RunService event name, defaults to Heartbeat

	@return Connection
]]
function Util.BindToFrame(callback:(sumdt: number)->(), Frame:number, Event:string?)
	if debug then
		assert(checkBindToFrame(callback, Frame, Event))
	end
	Event = Event or "Heartbeat"
	if not RunService[Event] then
		error("Invalid RunService event!")
	end
	Frame = math.max(1, math.floor(Frame))
	local AccumulatedFrames = 0
	local AccumulatedDt = 0
	return RunService[Event]:Connect(function(dt)
		AccumulatedDt += dt
		AccumulatedFrames += 1
		if AccumulatedFrames >= Frame then
			callback(AccumulatedDt)
			AccumulatedFrames, AccumulatedDt = 0, 0
		end
	end)
end

function Util.GetGUID(wrapInCurly:boolean?)
	local HttpService = game:GetService("HttpService")
	return HttpService:GenerateGUID(wrapInCurly)
end

--[[
	Returns PlayerGui of local player
]]
function Util.GetLocalPlayerGui()
	return Players.LocalPlayer.PlayerGui
end

return Util