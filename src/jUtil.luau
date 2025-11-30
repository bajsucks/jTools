local Util = {}
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService('RunService')
local Players = game:GetService("Players")
local Janitor = require(script.Parent.Janitor)

-- Object:IsA() but supports a table of types
function Util.IsA(Obj:Object, Type:{string})
	for _, t in Type do
		if Obj:IsA(t) then
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
		for _, t in Type do
			if v:IsA(t) then
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

-- supports max of ~1e66-1e68
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

function Util.Debris(Inst:Instance|{Instance}, t:number)
	if typeof(t) ~= "number" then
        t = 0
    end
	if typeof(Inst) == "table" then
		for _, v in Inst do
			task.delay(t, function()
                v:Destroy()
            end)
		end
	elseif typeof(Inst) == "Instance" then
		task.delay(t, function()
            Inst:Destroy()
        end)
	else
		error("Invalid instance provided for Debris!", 2)
	end
end

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

function Util.VectorNoY(Vec:Vector3): Vector3
	return Vector3.new(Vec.X, 0, Vec.Z)
end

function Util.Preload(List: {string})
	local t, err = pcall(function()
		ContentProvider:PreloadAsync(List)
	end)
	if not t then 
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

function Util.PivotScale(inst: BasePart, scale: number)
	if not inst:IsA("BasePart") or not scale then
        error("Incorrect arguments passed!", 2)
    end
	local pivotPos = inst:GetPivot().Position

	inst.Size *= Vector3.new(scale, scale, scale)
	inst.Position = scaleToPivot(pivotPos, inst.Position, scale)
	inst.PivotOffset = CFrame.new(inst.PivotOffset.Position * scale)
end

function Util.SecondsToReadableTime(t:number)
	if not t then
        warn("Convert fail: No seconds were provided!")
        return
    end
	local days = math.floor(t/86400)
	local hours = math.floor((t % 86400)/3600)
	local minutes = math.floor(((t % 86400) % 3600)/60)
	local seconds = math.floor((((t % 86400) % 3600)%60)/1)
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
end

function Util.IsTableEmpty(dict:{[any]: any}): boolean
	for _ in dict do
		return false
	end
	return true
end

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
function Util.PromptAddGameToFavorites()
	local AvatarEditorService = game:GetService("AvatarEditorService")
	AvatarEditorService:PromptSetFavorite(game.PlaceId, Enum.AvatarItemType.Asset, true)
end
do
	local db = {}
	local queue = {}
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
				local awarded, errorMessage = pcall(BadgeService.AwardBadge, BadgeService, plr.UserId, id)
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
	function Util.ChangeControls(state)
		local LocalPlayer = Players.LocalPlayer
		local Controls = require(LocalPlayer.PlayerScripts.PlayerModule):GetControls()
		if state then
			Controls:Enable()
		else
			Controls:Disable()
		end
	end

	function Util.HasMouse()
		local UserInputService = game:GetService("UserInputService")
		return UserInputService.MouseEnabled
	end

	function Util.GetPreferredInput()
		local UserInputService = game:GetService("UserInputService")
		return UserInputService.PreferredInput
	end

	function Util.PlayerList(state)
		game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, state)
	end
end

-- boarding funnel wrapper (player, step, stepname)
--function Util.bfunnel(player, step, stepname) -- TODO DO NOT USE UNTIL MAKE THIS ONLY TRIGGER ONCE
--	AnalyticsService:LogOnboardingFunnelStepEvent(player, step, stepname)
--end

--[[
Returns player's friends on this server.
If PlayerList is provided, will search that list instead.
]]
function Util.GetFriendsOnServer(Player:Player, PlayerList:{Player}?)
	local result = {}
	for _, p in (PlayerList and PlayerList or Players:GetPlayers()) do
		if Player:IsFriendsWith(p.UserId) then
			table.insert(result, p)
		end
	end
	return result
end

function Util.GradientBar(gradient, intersects)
	--table.sort(intersects, function(a, b) return a.Intersect < b.Intersect end)
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

function Util.TweenPivotTo(PV:PVInstance, info:TweenInfo, targetcf:CFrame)
	local TweenService = game:GetService("TweenService")
	
	if not PV:IsA("PVInstance") or typeof(info) ~= "TweenInfo" or typeof(targetcf) ~= "CFrame" then
        error(`Invalid arguments provided for TweenModelCF! Types provided: {typeof(PV)}, {typeof(info)}, {typeof(targetcf)}`, 2)
    end
	
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

function Util.BulkPivotTo(models:{PVInstance}, CFrames:{CFrame}, mode:Enum.BulkMoveMode)
	local newCFrames = {}
	local newModels = {}
	for i, v in models do
		local pivotOffset = v:GetPivot():Inverse() * v.PrimaryPart.CFrame
		table.insert(newModels, v.PrimaryPart)
		table.insert(newCFrames, CFrames[i] * pivotOffset)
	end
	workspace:BulkMoveTo(newModels, newCFrames, mode)
end

return Util