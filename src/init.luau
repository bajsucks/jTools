--[[
	jTools is a collection of various tools and instruments that I find useful in development.
	https://github.com/bajsucks/jTools


      ███  ███████████                   ████         
     ░░░  ░█░░░███░░░█                  ░░███         
     █████░   ░███  ░   ██████   ██████  ░███   █████ 
    ░░███     ░███     ███░░███ ███░░███ ░███  ███░░  
     ░███     ░███    ░███ ░███░███ ░███ ░███ ░░█████ 
     ░███     ░███    ░███ ░███░███ ░███ ░███  ░░░░███
     ░███     █████   ░░██████ ░░██████  █████ ██████ 
     ░███    ░░░░░     ░░░░░░   ░░░░░░  ░░░░░ ░░░░░░  
 ███ ░███                                             
░░██████                                              
 ░░░░░░                                               

]]
local jTools: typeof({
	Badges = require(script.Badges),
	Cashier = require(script.Cashier),
	Crumbs = require(script.Crumbs),
	GridUtil = require(script.GridUtil),
	Haptic = require(script.Haptic),
	jChat = require(script.jChat),
	jMath = require(script.jMath),
	jSound = require(script.jSound),
	jUtil = require(script.jUtil),
	PerSecond = require(script.PerSecond),
	Pool = require(script.Pool),
	RangeEngine = require(script.RangeEngine),
	SAT = require(script.SAT),
	SocialTrickery = require(script.SocialTrickery),
	spr = require(script.spr),
	t = require(script.t),
}) =
	{}

for _, v in script:GetChildren() do
	local success, e = pcall(function()
		return require(v)
	end)
	if success then
		jTools[v.Name] = e
	else
		print("jTools module", v, "failed to load! Error message:", e)
	end
end

return jTools
