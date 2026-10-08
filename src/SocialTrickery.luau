--[[
    This module provides social functions that are not a part of the default Roblox API.
    Examples of such include: IsPlayerFollowing(Player, userid), GetFollowerCount(Player)
]]
local module = {}
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--[[
    Beware of the API limit!
]]
function module.IsPlayerFollowing(FollowerUserId: number, FollowedUserId: number, cursor: string): boolean
	if RunService:IsClient() then
		return
	end
	local HttpService = game:GetService("HttpService")
	if cursor == nil then
		cursor = ""
	end

	local Str = "http://friends.roproxy.com/v1/users/"
		.. FollowerUserId
		.. "/followings?&cursor="
		.. cursor
		.. "&sortOrder=Asc&limit=100"
	local response = HttpService:RequestAsync({
		Url = Str,
		Method = "GET",
	})

	if response.Success then
		local Body = HttpService:JSONDecode(response.Body)
		local nextPageCursor = Body.nextPageCursor

		for _, v in pairs(Body.data) do
			if v.id == FollowedUserId then
				return true
			end
		end

		if nextPageCursor ~= nil then
			module.PlayerisFollowing(FollowerUserId, FollowedUserId, nextPageCursor)
		end
	end
	return false
end
--[[
    Beware of the API limit!
]]
function module.GetFollowerCount(UserId: number): number
	if RunService:IsClient() then
		return
	end
	local HttpService = game:GetService("HttpService")

	local Table = "https://friends.roproxy.com/v1/users/" .. UserId .. "/followers/count"
	local response = HttpService:RequestAsync({
		Url = Table,
		Method = "GET",
	})
	if not response.Success then
		return
	end
	local TableBody = HttpService:JSONDecode(response.Body)
	return TableBody.count
end

function module.IsFriends(Player: Player, UserId: number)
	local success, isFriends = pcall(function()
		return Player:IsFriendsWithAsync(UserId)
	end)
	if success and isFriends then
		return true
	end
	return false
end

--[[
	Returns player's friends on this server.
	If PlayerList is provided, will search that list instead.
]]
function module.GetFriendsOnServer(Player: Player, PlayerList: { Player }?)
	local result = {}
	for _, p in (PlayerList and PlayerList or Players:GetPlayers()) do
		if Player:IsFriendsWithAsync(p.UserId) then
			table.insert(result, p)
		end
	end
	return result
end

return module
