--[[
    Baj's UI Utilities
]]
local Juice = {}

--[[
    Autoscales a ScrollingFrame based on it's child UIListLayout's AbsoluteContentSize
    
    Why: SF AutomaticCanvasSize has really bad support for children with size defined by Scale + UIAspectRatio

    @return Cancel function
]]
function Juice.AutoscaleScroll(sf: ScrollingFrame, Axis: "X" | "Y" | "XY"): () -> ()
	local layout = sf:FindFirstChildWhichIsA("UIListLayout")
	if not layout then
		warn("AutoscaleScroll can only be used on ScrollingFrames with a UIListLayout child!")
		return function() end
	end
	local function Update()
		local s = layout.AbsoluteContentSize
		sf.CanvasSize = UDim2.fromOffset(Axis:find("X") and s.X or 0, Axis:find("Y") and s.Y or 0)
	end
	local con = layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(Update)
	Update()
	return function()
		con:Disconnect()
	end
end

return Juice
