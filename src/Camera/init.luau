local Cam = {}
local Storage = {
	["Blur"] = {}
}
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
if RunService:IsServer() then
    return {}
end
local Signal = require(script.Parent.SignalPlus)
local Janitor = require(script.Parent.Janitor)
local Lighting = game:GetService("Lighting")
local Player = game.Players.LocalPlayer
local te = require(script.TimedEffects)
local grad = te.new()
local DOF = te.new()

--[[
	Blur the camera for t seconds
	tr1 - tween time beginning
	tr2 - tween time ending
	val - blur power
]]
function Cam.Blur(t:number?, tr1:number, tr2:number, val:number)
    assert(val, "No blur value provided!")
	local nv = Instance.new("NumberValue")
	table.insert(Storage.Blur, nv)
	task.spawn(function()
		local tween = TweenService:Create(nv, TweenInfo.new(tr1), {Value = val})
		tween:Play()
		tween.Completed:Wait()
		if typeof(t) == "number" then
            task.wait(t)
        end
		if not nv then return end
		tween = TweenService:Create(nv, TweenInfo.new(tr2), {Value = 0})
		tween:Play()
		tween.Completed:Wait()
		nv:Destroy()
	end)
end
--[[
	Blur the camera permanently
	tr1 - tween time beginning
	tr2 - tween time ending
	val - blur power
	returns function that removes the blur when called
]]
function Cam._BlurPerm(tr1:number, tr2:number, val:number)
    assert(val, "No blur value provided!")
	local nv = Instance.new("NumberValue")
	table.insert(Storage.Blur, nv)
	task.spawn(function()
		local tween = TweenService:Create(nv, TweenInfo.new(tr1), {Value = val})
		tween:Play()
	end)
	local c = false -- idk if that's needed but just in case
	return function()
		if c then return end
		if not nv then return end
		c = true
		local tween = TweenService:Create(nv, TweenInfo.new(tr2), {Value = 0})
		tween:Play()
		tween.Completed:Wait()
		nv:Destroy()
	end
end
--[[
	clear all camera blurs with the specified tr2
	not having tr2 should be a thing, but
	I have no finished it yet apparently
]]
function Cam.ClearBlur(tr2:number?)
	if not tr2 then
		for i, v in Storage.Blur do
			v:Destroy()
			Storage.Blur[i] = nil
		end
	end
	for _, v in Storage.Blur do
		task.spawn(function()
			local tween = TweenService:Create(v, TweenInfo.new(tr2), {Value = 0})
			tween:Play()
			tween.Completed:Wait()
			v:Destroy()
		end)
	end
end

-- I forgot how to use this
function Cam.NewGrad()
	local uuid = grad:Add()
	return grad, uuid
end

-- I forgot how to use this
function Cam.NewDOF()
	local uuid = DOF:Add()
	return DOF, uuid
end

local Cutscene = {}
Cutscene.__index = Cutscene
--[[
	!!EXPERIMENTAL!!

	Creates a new cutscene.
	FocusPoint- Where the camera will be pointed to during the cutscene.
	If nil, camera will face the same direction as points.
]]
function Cam.Cutscene(FocusPoint:Vector3?)
	local self = {}
	self.Points = {}
	self.FocusPoint = FocusPoint
	self.FocusPointChanged = Signal()
	self.Playing = false
	self.Began = Signal()
	self.Ended = Signal()
	self.Cancelled = Signal()
	self._CutsceneCancelled = Signal()
	setmetatable(self, Cutscene)
	return self
end
--[[
	!!EXPERIMENTAL!!

	Plays a cutscene.
]]
function Cutscene.Play(self:Cutscene)
	task.spawn(function()

		if self.Playing then
			self:Cancel()
		end
		local j = Janitor.new()

		self.Began:Fire()
		local c:Camera = Player.CurrentCamera
		self.SavedCameraType = c.CameraType
		self.Playing = true
		c.CameraType = Enum.CameraType.Scriptable
		local _Cancelled = false
		local cfv = Instance.new("CFrameValue")
		j:Add(cfv, "Destroy")
		cfv.Value = c.CFrame
		j:Add(RunService.RenderStepped:Connect(function()
			local pos = cfv.Value.Position
			if self.FocusPoint then
				c.CFrame = CFrame.lookAt(pos, self.FocusPoint)
			else
				c.CFrame = cfv.Value
			end
		end))
		j:Add(self._CutsceneCancelled:Once(function()
			_Cancelled = true
		end), "Disconnect")
		for i, v in ipairs(self.Points) do
			if _Cancelled then break end
			if i >= #self.Points then break end
			local nextv = self.Points[i+1]
			local curcf: CFrame, Duration: number, SkipTween: boolean = table.unpack(v)
			local info = TweenInfo.new(Duration, Enum.EasingStyle.Linear)
			local nextcf: CFrame = nextv[1]
			if i == 1 then
				cfv.Value = curcf
			end
			if SkipTween then
				cfv.Value = nextcf
				continue
			end
			local Tween = TweenService:Create(cfv, info, {Value = nextcf})
			Tween:Play()
			j:Add(Tween, "Cancel")
			repeat
				task.wait()
			until Tween.Completed or _Cancelled
		end
		if not _Cancelled then
			self.Ended:Fire()
		end
		j:Destroy()
		self.Playing = false
		c.CameraType = self.SavedCameraType

	end)
end
--[[
	Cancels a cutscene.
]]
function Cutscene.Cancel(self:Cutscene)
	if not self.Playing then return end
	self._CutsceneCancelled:Fire()
	self.Cancelled:Fire()
end
--[[
	Adds a new point to the cutscene.
	SkipNext - Whether to skip the tween to next point
	Speed - In seconds, how long it takes for the camera to go from
	point A to point B
]]
function Cutscene.AddPoint(self:Cutscene, CFrame:CFrame, Duration:number, SkipTween:boolean?)
	assert(Duration > 0, "Cutscene point duration must be >0!")
	assert(CFrame, "Tried to create a point without CFrame!")
	table.insert(self.Points, {CFrame, Duration, SkipTween})
end
--[[
	Change the focus point of the cutscene.
]]
function Cutscene.ChangeFocusPoint(self:Cutscene, FocusPoint:CFrame?)
	self.FocusPoint = FocusPoint
	self.FocusPointChanged:Fire()
end

RunService.Heartbeat:Connect(function()
	local Blur = Lighting:FindFirstChild("Blur")
	if not Blur then
		Blur = Instance.new("BlurEffect")
		Blur.Name = "Blur"
		Blur.Parent = Lighting
	end

	local DefaultBlur = 0 -- TODO: fetch default blur from workspace
	local Largest = 0
	for _, v in Storage.Blur do
		if v.Value <= DefaultBlur then continue end
		if v.Value > Largest then
            Largest = v.Value
        end
	end
	Blur.Size = Largest
end)

RunService.RenderStepped:Connect(function()
	do -- grad
		local total = grad:GetValue()
		local DefaultGrad = 1
		local pgui = Player.PlayerGui
        if not pgui then return end
		local GradGui = pgui:FindFirstChild("Grad")
        if not GradGui then return end
		local img = GradGui:FindFirstChild("ImageLabel")
        if not img then return end
		img.ImageTransparency = math.max(DefaultGrad - total, 0.2)
	end
	
	do -- DOF
		local total = DOF:GetValue()
		local DefaultDOF = 0.1
		Lighting.DepthOfField.FarIntensity = math.min(DefaultDOF + total, 1)
		Lighting.DepthOfField.FocusDistance = math.min(DefaultDOF + total, 1)
	end
end)

export type Cutscene = typeof(Cam.Cutscene())

return Cam