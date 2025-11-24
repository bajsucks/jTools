local jUILib = {}

-- TODO: Add increment

function jUILib.Slider(holder:GuiObject, button:GuiObject, interact:{GuiObject}?, onChanged: (number)->(), onEnded: (number)->(), direction:number?): (number)->()
	if not direction then
        direction = 0
    end

	local dragging = false
	local startPos = 0
	local startButtonPos = 0

	local function ForceSlide(value)
		value = math.clamp(value, 0, 1)

		local holderSize = holder.AbsoluteSize.X
		local maxPos = holderSize

		button.Position = UDim2.new(0, value * maxPos, button.Position.Y.Scale, button.Position.Y.Offset)
		onChanged(value)
	end

	local function getSliderValue(inputPos)
		local holderPos = holder.AbsolutePosition.X
		local holderSize = holder.AbsoluteSize.X
		local buttonSize = button.Size.X.Offset
		local maxPos = holderSize - buttonSize

		local relativePos = inputPos - holderPos - (buttonSize / 2)
		local value = relativePos / maxPos
		return math.clamp(value, 0, 1)
	end
	-- Touch input
	local function began(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startPos = input.Position.X
			startButtonPos = button.Position.X.Offset
			local value = getSliderValue(input.Position.X)
			ForceSlide(value)
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			startPos = input.Position.X
			startButtonPos = button.Position.X.Offset
			local value = getSliderValue(input.Position.X)
			ForceSlide(value)
		end
	end
	button.InputBegan:Connect(began)
	holder.InputBegan:Connect(began)
	for _, v in interact do
		v.InputBegan:Connect(began)
	end
	
	-- End dragging
	local UserInputService = game:GetService("UserInputService")

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if dragging then
				dragging = false
				local value = getSliderValue(input.Position.X)
				ForceSlide(value)
				if onEnded then
					onEnded(value)
				end
			end
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			local value = getSliderValue(input.Position.X)
			ForceSlide(value)
		end
		if input.UserInputType == Enum.UserInputType.Touch then
			local value = getSliderValue(input.Position.X)
			ForceSlide(value)
		end
	end)

	return ForceSlide
end

function jUILib.Switch(interact:{GuiObject}?, onChanged: (boolean)->()): (boolean)->()
	local state = nil
	local debounce = false
	
	local function f(forced)
		if forced == nil and debounce then return end
		debounce = true
		task.delay(0.25, function()
            debounce = false
        end)
		if forced ~= nil then state = forced else
			if not state then
                state = false
            end
			state = not state
		end
		onChanged(state)
	end
	local function began(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            f() 
        end
	end
	for _, v in interact do
		v.InputBegan:Connect(began)
	end
	
	return f
end

return jUILib