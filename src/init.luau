--!nocheck
--[[
	jTools
	Made by baj
	This module is simply a cluster of all the cool functions and things that are necessary in development
]]
local jTools = {}

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

return jTools :: typeof({
	jMath = require(script.jMath), 				-- math functions: lerp, bezier, perlin (todo), etc.
	jUtil = require(script.jUtil), 				-- utility functions: get children which are, get descendants which are, etc.
	Lootbag = require(script.Lootbag), 			-- weighted RNG module (made by meowtsun)
	Time = require(script.Time),				-- basic day/night cycle with custom cycle speed
	jSound = require(script.jSound),			-- basic sound stuff: sfx, playlists etc.
	Camera = require(script.Camera),			-- camera stuff: blur, FOV, cutscenes
	spr = require(script.spr),					-- spring motion module (made by Fractality)
	PerSecond = require(script.PerSecond),		-- unit/s calculations made easy
	Typewriter = require(script.Typewriter),	-- typewriter fx for textlabel and textbox
	jUILib = require(script.jUILib),			-- sliders and switches
	Haptic = require(script.Haptic),			-- gamepad haptics
	Badges = require(script.Badges),			-- give badges without worrying about API timeouts
	Cps = require(script.Cps),					-- clicks per second measure (via PerSecond + UIS)
	Collect = require(script.Collect),			-- CollectionService utils
	Janitor = require(script.Janitor),			-- Janitor
	SignalPlus = require(script.SignalPlus)		-- Signal
})