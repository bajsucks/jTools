local TextChatService = game:GetService("TextChatService")
local GeneralChannel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")

local module = {}

-- color in hex
function module.SendChatMessage(Message:string, tag:string?, tagcolor:string?)
	tagcolor = tagcolor or "#fbff0a"
	if tag then
		GeneralChannel:DisplaySystemMessage(`<font color='{tagcolor}'>[{tag}]</font> ` .. Message) 
	else
		GeneralChannel:DisplaySystemMessage(Message) 
	end
end

return module
