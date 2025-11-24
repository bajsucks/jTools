local Time = {}
local jMath = require(script.Parent.jMath)
local CycleChanged = Instance.new("BindableEvent")
Time.Changed = CycleChanged.Event -- Fires when cycle changes
local CycleChangedAllClients = script.CycleChanged

local RunService = game:GetService("RunService")

type Settings = {
	["Day"]: number,
	["Night"]: number,
}

local CurSettings:Settings = {}
local State = true
local DayStart = 6
local NightStart = 20
local TimeInCycle = 0
local DayDifference = NightStart - DayStart
local NightDifference = DayStart+24 - NightStart
local CurrentCycle = "Day"

local function SetCurrentCycle()
	if game.Lighting.ClockTime < DayStart or game.Lighting.ClockTime > NightStart then
		if CurrentCycle == "Night" then return end
		TimeInCycle = 0
		CurrentCycle = "Night"
		CycleChanged:Fire(CurrentCycle)
		CycleChangedAllClients:FireAllClients(CurrentCycle)
	else
		if CurrentCycle == "Day" then return end
		TimeInCycle = 0
		CurrentCycle = "Day"
		CycleChanged:Fire(CurrentCycle)
		CycleChangedAllClients:FireAllClients(CurrentCycle)
	end
end

-- Day, Night: Time in seconds those cycles take; TransitionTime: Time it takes to switch cycles. nil for realistic time flow; number for cartoony
-- TODO: TransitionTime
function Time.Flow(Day:number, Night:number)
	CurSettings = {["Day"] = Day, ["Night"] = Night}
	SetCurrentCycle()
	if CurrentCycle == "Day" then
		local TimePerHour = Day / DayDifference
		TimeInCycle = (game.Lighting.ClockTime - DayStart) * TimePerHour
	else
		local TimePerHour = Night / NightDifference
		if game.Lighting.ClockTime > NightStart then
			TimeInCycle = (game.Lighting.ClockTime - NightStart) * TimePerHour
		else
			TimeInCycle = (24 - (NightStart - game.Lighting.ClockTime)) * TimePerHour
		end
	end
end

function Time.Stop()
	State = false
end

function Time.Resume()
	State = true
end

RunService.Heartbeat:Connect(function(dt)
	if not State or not CurSettings.Day or not CurSettings.Night then return end
	TimeInCycle += dt
	if CurrentCycle == "Day" then
		game.Lighting:SetMinutesAfterMidnight(jMath.lerp(DayStart, NightStart, TimeInCycle/CurSettings.Day)*60)
	else
		game.Lighting:SetMinutesAfterMidnight(jMath.lerp(NightStart, 24+DayStart, TimeInCycle/CurSettings.Night)*60)
	end
	SetCurrentCycle()
end)

return Time
