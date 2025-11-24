local Cam = {}
local Storage = {
	["Blur"] = {}
}
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
if RunService:IsServer() then
    return {}
end
local Lighting = game:GetService("Lighting")
local Player = game.Players.LocalPlayer
local te = require(script.TimedEffects)
local grad = te.new()
local DOF = te.new()

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
		warn("received")
		if c then return end
		if not nv then return end
		c = true
		warn("begun")
		local tween = TweenService:Create(nv, TweenInfo.new(tr2), {Value = 0})
		tween:Play()
		warn("played")
		tween.Completed:Wait()
		warn("completed")
		nv:Destroy()
	end
end

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

function Cam.NewGrad()
	local uuid = grad:Add()
	return grad, uuid
end

function Cam.NewDOF()
	local uuid = DOF:Add()
	return DOF, uuid
end

RunService.Heartbeat:Connect(function()
	local Blur = Lighting:FindFirstChild("Blur")
	if not Blur then
		Blur = Instance.new("BlurEffect")
		Blur.Name = "Blur"
		Blur.Parent = Lighting
	end
	local DefaultBlur = 0
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
	do
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
	
	do
		local total = DOF:GetValue()
		local DefaultDOF = 0.1
		Lighting.DepthOfField.FarIntensity = math.min(DefaultDOF + total, 1)
		Lighting.DepthOfField.FocusDistance = math.min(DefaultDOF + total, 1)
	end
end)

return Cam
