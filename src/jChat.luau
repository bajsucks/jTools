local TextChatService = game:GetService("TextChatService")
local GeneralChannel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")

local module = {}

-- color in hex
function module.SendTagMessage(Message:string, tag:string?, tagcolor:string?)
	tagcolor = tagcolor or "#fbff0a"
	if tag then
		GeneralChannel:DisplaySystemMessage(`<font color='{tagcolor}'>[{tag}]</font> {Message}`) 
	else
		GeneralChannel:DisplaySystemMessage(Message) 
	end
end

function module.SendMessage(Message:string)
	GeneralChannel:DisplaySystemMessage(Message) 
end

-- returns the message with an appended tag
function module.AppendTag(Message:string, tag:string?, tagcolor:string?)
	return `<font color='{tagcolor}'>[{tag}]</font> {Message}`
end

return module
