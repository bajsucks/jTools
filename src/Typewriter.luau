local Writer = {}

function Writer.Typewrite(box: TextLabel|TextBox, str: string, Time: number, onCharacter: ()->()?, onEnd: ()->()?): ()->()
	local cancelled = false
	
	local displayText = str:gsub("<br%s*/>", "\n")
	displayText = displayText:gsub("<[^<>]->", "")
	box.Text = displayText
	local index = 0
	
	task.spawn(function()
		for _ in utf8.graphemes(displayText) do
			index += 1
			box.MaxVisibleGraphemes = index
			if onCharacter then
                onCharacter()
            end
			task.wait(Time)
			if cancelled then
				box.Text = str
			    break
            end
		end
		if onEnd then
            onEnd()
        end
	end)
	
	local function cancel()	
		cancelled = true
	end
	return cancel
end

return Writer