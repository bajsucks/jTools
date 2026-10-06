--[[
    This module handles dev products & gamepasses
    
    It takes up the .ProcessReceipt callback
    If you want to create a new connection to the callback, please, care to use this wrapper.
]]

local Cashier = {}

local RunService = game:GetService("RunService")

if RunService:IsClient() then
	return Cashier
end -- server-only tool!

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local t = require(script.Parent.t)

local Register = {}
local cache: { [Player]: { [string]: boolean } } = {} -- [Player] = { [label]: boolean }
local GamepassLabels: { number | string } = {} -- [1]: Id, [2]: label

local function GetCache(Player: Player)
	local PlayerCache = cache[Player]
	if not PlayerCache then
		PlayerCache = {}
		cache[Player] = PlayerCache
	end
	return PlayerCache
end

Players.PlayerRemoving:Connect(function(Player)
	cache[Player] = nil
end)

local function GetLabelFromId(Id: number): string
	for _, v in GamepassLabels do
		if v[1] == Id then
			return v[2]
		end
	end
	error("Tried to get a label that was not yet defined!")
end

local function GetIdFromLabel(label: string): number
	for _, v in GamepassLabels do
		if v[2] == label then
			return v[1]
		end
	end
	error("Tried to get an ID that was not yet defined!")
end

local function GetRegisterEntry(LabelOrId: number | string)
	local Id: number
	if not LabelOrId then
		error("tried to get a nothingpass??")
	end
	if typeof(LabelOrId) == "string" then
		Id = GetIdFromLabel(LabelOrId) -- turn the ambiguous thing into a real id
	else
		Id = LabelOrId -- it's already an id
	end
	return Register[tostring(Id)]
end

local function DevproductPurchase(Receipt)
	local Entry = GetRegisterEntry(Receipt.ProductId)
	if not Entry then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local Player = Players:GetPlayerByUserId(Receipt.PlayerId)
	if not Player or not Entry.OnPurchase then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if Entry.OnPurchase(Player) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

local function GamepassPurchase(Player: Player, GamepassId: number, WasPurchased: boolean)
	if not WasPurchased or not Player then
		return
	end
	local Entry = GetRegisterEntry(GamepassId)
	if not Entry then
		return
	end
	local label = GetLabelFromId(GamepassId)
	GetCache(Player)[label] = true
	if Entry.OnPurchase then
		Entry.OnPurchase(Player)
	end
end

--[[
    Binds a function to when a dev product is purchased
    OnPurchase returns success
]]
function Cashier.AddProduct(ProductId: number, OnPurchase: (Player) -> boolean)
	local c = t.tuple(t.number, t.callback)
	assert(c(ProductId, OnPurchase))
	Register[tostring(ProductId)] = {
		Id = ProductId,
		OnPurchase = OnPurchase,
	}
end
--[[
    Binds a function to when a gamepass is purchased, and a second function that allows to easily repeat some action associated with that gamepass.
    Also provides a label alias for that pass
]]
function Cashier.AddPass(GamepassId: number, label: string, OnReapply: (Player) -> ()?, OnPurchase: (Player) -> ()?)
	local c = t.tuple(t.number, t.string, t.optional(t.callback), t.optional(t.callback))
	assert(c(GamepassId, OnReapply, label, OnPurchase))
	table.insert(GamepassLabels, { GamepassId, label })
	Register[tostring(GamepassId)] = {
		Id = GamepassId,
		OnPurchase = OnPurchase,
		OnReapply = OnReapply,
	}
end
--[[
    :UserOwnsGamePassAsync but label and actually changes in real time when a player buys a gamepass
]]
function Cashier.HasPass(Player: Player, label: string): boolean
	if not Player or not label then
		return false
	end
	local pCache = GetCache(Player)
	-- false is a valid cache
	if pCache[label] == nil then
		local success, owns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(Player.UserId, GetIdFromLabel(label))
		end)
		pCache[label] = success and owns or false
	end
	return pCache[label]
end
--[[
    Reapply a function bound to that gamepass
]]
function Cashier.Reapply(Player: Player, label: string)
	if not Player or not label then
		return
	end
	if not Cashier.HasPass(Player, label) then
		return
	end
	local Entry = GetRegisterEntry(label)
	assert(Entry, `Cannot reapply gamepass \"{label}\": Something's not right!`)
	if Entry.OnReapply then
		Entry.OnReapply(Player)
	end
end
--[[
    Reapply all of player's gamepasses
    (useful for when, for example, a player respawns in a pvp game)
]]
function Cashier.ReapplyAll(Player: Player)
	for _, v in GamepassLabels do
		Cashier.Reapply(Player, v[2])
	end
end
--[[
    Dumps all registered ids
]]
function Cashier.Dump()
	local tbl = {}
	for _, v in Register do
		table.insert(tbl, v.Id)
	end
	return tbl
end
--[[
    Get price of a product
]]
function Cashier.GetProductPrice(DevProductId: number)
	local success, info = pcall(function()
		return MarketplaceService:GetProductInfoAsync(DevProductId, Enum.InfoType.Product)
	end)
	if success and info then
		return info.PriceInRobux
	end
	success, info = pcall(function()
		return MarketplaceService:GetProductInfoAsync(DevProductId, Enum.InfoType.GamePass)
	end)
	if success and info then
		return info.PriceInRobux
	end
	return nil
end

MarketplaceService.ProcessReceipt = DevproductPurchase
MarketplaceService.PromptGamePassPurchaseFinished:Connect(GamepassPurchase)

return Cashier
