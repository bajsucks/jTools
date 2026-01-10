--[[
    This module provides social functions that are not a part of the default Roblox API.
    Examples of such include: IsPlayerFollowing(Player, userid), GetFollowerCount(Player)
]]
local module = {}
local RunService = game:GetService("RunService")

--[[
    Beware of the API limit!
]]
function module.IsPlayerFollowing(FollowerUserId:number, FollowedUserId:number, cursor:string): boolean
    if RunService:IsClient() then return end
    local HttpService = game:GetService("HttpService")
    if cursor == nil then
		cursor = ""
	end
	
	local Str = "http://friends.roproxy.com/v1/users/"..FollowerUserId.."/followings?&cursor="..cursor.."&sortOrder=Asc&limit=100"
	local response = HttpService:RequestAsync({
		Url = Str,
		Method = "GET"
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
function module.GetFollowerCount(UserId:number): number
    if RunService:IsClient() then return end
    local HttpService = game:GetService("HttpService")

    local Table = "https://friends.roproxy.com/v1/users/"..UserId.."/followers/count"
    local response = HttpService:RequestAsync({
        Url = Table,
        Method = "GET"
    });
    if not response.Success then return end
    local TableBody = HttpService:JSONDecode(response.Body)
    return TableBody.count
end

return module