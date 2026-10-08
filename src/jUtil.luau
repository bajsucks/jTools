local Util = {}
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService: HttpService
if RunService:IsServer() then
	HttpService = game:GetService("HttpService")
end
local StarterGui: StarterGui
local UserInputService: UserInputService
local AvatarEditorService: AvatarEditorService
if RunService:IsClient() then
	StarterGui = game:GetService("StarterGui")
	UserInputService = game:GetService("UserInputService")
	AvatarEditorService = game:GetService("AvatarEditorService")
end
local Janitor = require(script.Parent.Parent.Janitor)
local Promise = require(script.Parent.Parent.Promise)

type Recursive<T> = T | { Recursive<T> }
type dict<T> = { [any]: T }
type tbl<T> = { [number]: T }
type Types = { string }

-- Object:IsA() but supports a table of types
function Util.IsA(Obj: Object, Types: Types)
	for _, t in Types do
		if Obj:IsA(t) then
			return true
		end
	end
	return false
end

function Util.GetChildrenWhichAre(Inst: Instance, Types: Types)
	if #Types == 0 then
		return {}
	end
	return Inst:QueryDescendants("> " .. table.concat(Types, ", > "))
end

function Util.GetDescendantsWhichAre(Inst: Instance, Types: Types)
	if #Types == 0 then
		return {}
	end
	return Inst:QueryDescendants(table.concat(Types, ", "))
end

function Util.GetChildrenExcept(Inst: Instance, Types: Types)
	if #Types == 0 then
		return Inst:GetChildren()
	end
	return Inst:QueryDescendants("> :not(" .. table.concat(Types, "):not(") .. ")")
end

function Util.GetDescendantsExcept(Inst: Instance, Types: Types)
	if #Types == 0 then
		return Inst:GetDescendants()
	end
	return Inst:QueryDescendants(":not(" .. table.concat(Types, "):not(") .. ")")
end

function Util.ClearChildrenWhichAre(Inst: Instance, Types: Types)
	for _, v in Util.GetChildrenWhichAre(Inst, Types) do
		v:Destroy()
	end
end

function Util.ClearDescendantsWhichAre(Inst: Instance, Types: Types)
	for _, v in Util.GetDescendantsWhichAre(Inst, Types) do
		v:Destroy()
	end
end

function Util.ClearChildrenExcept(Inst: Instance, Types: Types)
	for _, v in Util.GetChildrenExcept(Inst, Types) do
		v:Destroy()
	end
end

function Util.ClearDescendantsExcept(Inst: Instance, Types: Types)
	for _, v in Util.GetDescendantsExcept(Inst, Types) do
		v:Destroy()
	end
end

--[[
	Alias to Util.ClearChildrenExcept(Inst, {"UIComponent"})
]]
function Util.ClearGUI(Inst: Instance)
	Util.ClearChildrenExcept(Inst, { "UIComponent" })
end

function Util.DictHasValue<T>(dict: dict<T>, value: T): boolean
	for _, v in dict do
		if v == value then
			return true
		end
	end
	return false
end
--[[
	Returns the number of indecies in a dictionary, or 0 if empty
]]
function Util.DictCount<T>(dict: dict<T>): number
	if not dict or typeof(dict) ~= "table" then
		return 0
	end
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
function Util.RandFromDict<T>(dict: dict<T>): T
	local dc = Util.DictCount(dict)
	if dc == 0 then
		return
	end
	local n = math.random(1, dc)
	local i = 0
	for _, v in dict do
		i += 1
		if i == n then
			return v
		end
	end
	error("something went wrong lol how")
end

--[[
	Abbreviates a number
	Supports max of ~1e66-1e68

]]
function Util.Abr(Num: number): string
	local suffixes = {
		"",
		"K",
		"M",
		"B",
		"T",
		"QA",
		"QI",
		"SX",
		"SP",
		"OC",
		"NO",
		"DC",
		"UD",
		"DD",
		"TD",
		"QAD",
		"QID",
		"SXD",
		"SPD",
		"OCD",
		"NOD",
		"VG",
		"UVG",
	}
	if Num < 1000 then
		local trunc = math.modf(Num * 10)
		return tostring(trunc / 10)
	end
	local i = math.floor(math.log10(math.abs(Num)) / 3)
	-- 51300 51.3K
	local abbreviatedNum = Num / (1000 ^ i)
	-- 51300 / (1000 ^ 5)
	local formattedNum = string.format("%.2f", abbreviatedNum)
	if string.match(formattedNum, "%.00$") then
		formattedNum = string.gsub(formattedNum, "%.00$", "")
	end
	return formattedNum .. (suffixes)[i + 1]
end

--[[
	Modulo wrapper. Wraps the number around itself if Num > Max.
	(12, 10) -> 2
	(8, 10) -> 8
	(10, 10) -> 10
]]
function Util.WrapNumber(Num: number, Max: number): number
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
function Util.Debris(Inst: Recursive<Instance>, t: number)
	if typeof(t) ~= "number" then
		t = 0
	end
	if typeof(Inst) == "table" then
		for _, v in Inst do
			Util.Debris(v, t)
		end
	elseif typeof(Inst) == "Instance" then
		task.delay(t, function()
			Inst:Destroy()
		end)
	else
		error("Invalid instance provided for Debris!", 2)
	end
end
--[[
	Sets the Y axis of a vector to 0 and returns the resulting vector

	@deprecated Use vector multiplication *vec(1, 0, 1) instead
]]
function Util.VectorNoY(Vec: Vector3): Vector3
	return Vector3.new(Vec.X, 0, Vec.Z)
end
--[[
	I'm not sure if this works
]]
function Util.Preload(List: { string })
	local t, err = pcall(function()
		ContentProvider:PreloadAsync(List)
	end)
	if not t then
		error(err, 2)
	end
end

-- this finds new position value for part being scaled toward pivot
local function scaleToPivot(pivotPos: Vector3, partPos: Vector3, scaleFactor: number): Vector3
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
	local pivotPos = inst:GetPivot().Position

	inst.Size *= Vector3.new(scale, scale, scale)
	inst.Position = scaleToPivot(pivotPos, inst.Position, scale)
	inst.PivotOffset = CFrame.new(inst.PivotOffset.Position * scale)
end
--[[
	Converts seconds to a readable format
	@param format Available formats: 1 - XXd XXh XXm XXs, 2 - XX:XX:XX:XX Default: 1
]]
function Util.SecondsToReadableTime(t: number, format: number?): string
	if not t then
		return "N/A"
	end
	format = format or 1
	local days = math.floor(t / 86400)
	local hours = math.floor((t % 86400) / 3600)
	local minutes = math.floor(((t % 86400) % 3600) / 60)
	local seconds = math.floor((((t % 86400) % 3600) % 60) / 1)
	if format == 1 then
		if t >= 86400 then
			return string.format("%id %02ih %02im %02is", days, hours, minutes, seconds)
		end
		if t >= 3600 then
			return string.format("%02ih %02im %02is", hours, minutes, seconds)
		end
		if t >= 60 then
			return string.format("%02im %02is", minutes, seconds)
		end
		return string.format("%02is", seconds)
	else
		if t >= 86400 then
			return string.format("%i:%02i:%02i:%02i", days, hours, minutes, seconds)
		end
		if t >= 3600 then
			return string.format("%02i:%02i:%02i", hours, minutes, seconds)
		end
		if t >= 60 then
			return string.format("%02i:%02i", minutes, seconds)
		end
		return string.format("%02i", seconds)
	end
end
--[[
	@deprecated alias of .IsDictEmpty()
]]
function Util.IsTableEmpty(dict: dict<any>): boolean
	Util.IsDictEmpty(dict) -- not direct assignment because we need the big fat deprecated sign
end

--[[
	Returns whether a dict is empty
]]
function Util.IsDictEmpty<T>(dict: dict<T>): boolean
	for _ in dict do
		return false
	end
	return true
end
--[[
	Clone a table/dict and returns the clone.
	Does not support recursion!
]]
function Util.deepClone<T>(dict: dict<T>): dict<T>
	if typeof(dict) ~= "table" then
		return dict
	end
	local clone = {}
	for key, value in dict do
		clone[key] = Util.deepClone(value)
	end
	return clone
end

--[[
	Randomizes indecies of a table
	Probably not entirely random
]]
function Util.ShuffleTable<T>(tbl: tbl<T>): tbl<T>
	local r = Random.new()
	for i = #tbl, 2, -1 do
		local j = r:NextInteger(1, i)
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
end

function Util.WaitForChildWhichIsA(instance: Instance, Types: Types, timeout: number?): Instance
	return Promise.new(function(resolve, _, onCancel)
		for _, c in instance:GetChildren() do
			if Util.IsA(c, Types) then
				resolve(c)
			end
		end
		local con = instance.ChildAdded:Connect(function(c)
			if Util.IsA(c, Types) then
				resolve(c)
			end
		end)
		onCancel(function()
			con:Disconnect()
		end)
	end)
		:timeout(timeout or 10, `infinite yield possible on :WaitForChildWhichIsA({Types})!`)
		:expect()
end

--[[
	Prompt the local player to add the game to favorites
]]
function Util.PromptAddGameToFavorites()
	AvatarEditorService:PromptSetFavorite(game.PlaceId, Enum.AvatarItemType.Asset, true)
end

if RunService:IsClient() then

	--[[
		Disable reset on the client
	]]
	function Util.ClientDisableReset()
		return Promise.retryWithDelay(function()
			return Promise.try(StarterGui.SetCore, StarterGui, "ResetButtonCallback", false)
		end, 8, 0.1)
	end

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
		return UserInputService.MouseEnabled
	end

	--[[
		Returns UserInputService.PreferredInput
	]]
	function Util.GetPreferredInput()
		return UserInputService.PreferredInput
	end

	--[[
		Sets leaderboard (player list) CoreGUI on/off
	]]
	function Util.PlayerList(state: boolean)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, state)
	end
end

--[[
	Tween a model to a target CFrame

	@return Janitor object, tween. Cleaning the Janitor object will also cancel the tween.
]]
function Util.TweenPivotTo(PV: PVInstance, info: TweenInfo, targetcf: CFrame): (any, Tween)
	local j = Janitor.new()
	local val = Instance.new("CFrameValue")
	val.Value = PV:GetPivot()
	j:Add(val)
	j:Add(val.Changed:Connect(function()
		PV:PivotTo(val.Value)
	end))
	local tw = TweenService:Create(val, info, { Value = targetcf })
	tw:Play()
	j:Add(tw, "Cancel")
	j:Add(tw.Completed:Once(function()
		j:Destroy()
	end))
end

--[[
	workspace:BulkMoveTo, but accounts for pivot
]]
function Util.BulkPivotTo(models: { PVInstance }, CFrames: { CFrame }, mode: Enum.BulkMoveMode)
	local newCFrames = {}
	local newModels = {}
	for i, v in models do
		local pivotOffset = v:GetPivot():Inverse() * v.PrimaryPart.CFrame
		table.insert(newModels, v.PrimaryPart)
		table.insert(newCFrames, CFrames[i] * pivotOffset)
	end
	workspace:BulkMoveTo(newModels, newCFrames, mode)
end

--[[
	@return Whether the instance has a specific property available
]]
function Util.HasProperty(Obj: Instance, Property: string): boolean
	local has = pcall(function()
		local _ = Obj[Property]
	end)
	return has
end

--[[
	Get an object from a table/instance using a path
	Format: (PlayerData, "Inventory/Weapons/Weapon1")
	Will return nil if path is invalid
]]
function Util.ResolvePath(root: Instance | dict<any>, path: string, sep: string?): any?

	local segments = string.split(path, sep or "/")
	local current: Instance | dict<any> = root

	for _, segment in segments do
		if type(current) == "table" then
			current = current[segment]
		elseif type(current) == "userdata" and current:IsA("Instance") then
			current = current:FindFirstChild(segment) or current[segment]
		else
			return nil
		end
	end
	return current
end

--[[
    Returns what day it is rn as a whole number
]]
function Util.Today(): number
	return math.floor(os.time() / 86400)
end

--[[
    Returns the number of seconds left until tomorrow
]]
function Util.SecondsUntilTomorrow(): number
	return 86400 - (os.time() % 86400)
end

--[[
	Weld a to b, parent weld to a and return the weld
]]
function Util.Weld(a: Instance, b: Instance): WeldConstraint
	local Weld = Instance.new("WeldConstraint")
	Weld.Part0 = a
	Weld.Part1 = b
	Weld.Parent = a
	return Weld
end

--[[
	Iterate through ranges formatted as start:end
	i.e.
	for s, e in Ranges("1:2 2:3 3:4") do -> (1, 2), (2, 3), (3, 4)
]]
function Util.Ranges(str: string): (number?, number?)
	local iterator = string.gmatch(str, "(%d+):(%d+)")

	return function()
		local startStr, endStr = iterator()
		if startStr and endStr then
			return tonumber(startStr), tonumber(endStr)
		end
		return nil
	end
end

function Util.GetGUID(wrapInCurly: boolean?): string
	return HttpService:GenerateGUID(wrapInCurly)
end

--[[
	Returns PlayerGui of local player
]]
function Util.GetLocalPlayerGui(): PlayerGui
	return Players.LocalPlayer.PlayerGui
end

--[[
	Binds a function to run in specific intervals
	@param Hz How frequently, in hertz, the function should be called
]]
function Util.BindToHz(Hz: number, fn: () -> ())
	local Time = 1 / Hz
	local tdt = 0
	return RunService.Heartbeat:Connect(function(dt)
		tdt += dt
		if tdt > Time then
			tdt -= Time
			fn()
		end
	end)
end

return Util
