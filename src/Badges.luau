local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
if RunService:IsClient() then return {} end
local Badges = {}

local cache = {}

function Badges.Give(Player:Player, BadgeID:number)
	if not Player or not BadgeID then return end
	cache[Player] = cache[Player] or {}
	if cache[Player][BadgeID] then return end
	local success = pcall(BadgeService.AwardBadge, BadgeService, Player.UserId, BadgeID)
	if success then
        cache[Player][BadgeID] = true
    end
end

Players.PlayerRemoving:Connect(function(Player)
	cache[Player] = nil
end)

return Badges