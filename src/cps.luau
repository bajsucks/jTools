local cps = {}

local PerSecond = require(script.Parent.PerSecond)

local UserInputService = game:GetService("UserInputService")
local calc = PerSecond.new(3)

UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		calc:AddItem(1)
	end
end)

function cps.Get()
	return calc:GetPerSecond()
end

return cps