--[[
    This module handles dev products & gamepasses
    
    It takes up the .ProcessReceipt callback
    If you want to create a new connection to the callback,
    please, care to use this wrapper. It's not hard.

    EXPERIMENTAL: Has not yet been tested
]]

local Cashier = {}

local RunService = game:GetService("RunService")

if RunService:IsClient() then return Cashier end -- server only tool!

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Register = {}
local cache = {}
local GamepassLabels: {number|string} = {} -- [1]: Id, [2]: label

local function GetLabelFromId(Id: number)
    for _, v in GamepassLabels do
        if v[1] == Id then return v[2] end
    end
    error("Tried to get a label that was not yet defined!")
end

local function GetIdFromLabel(label: string)
    for _, v in GamepassLabels do
        if v[2] == label then return v[1] end
    end
    error("Tried to get an ID that was not yet defined!")
end

local function GetRegisterEntry(LabelOrId: number|string)
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
    if not Entry then return Enum.ProductPurchaseDecision.NotProcessedYet end

    local Player = Players:GetPlayerByUserId(Receipt.PlayerId)
    if not Player or not Entry.OnPurchase then return Enum.ProductPurchaseDecision.NotProcessedYet end

    Entry.OnPurchase(Player)
    return Enum.ProductPurchaseDecision.PurchaseGranted
end

local function GamepassPurchase(Player: Player, GamepassId: number, WasPurchased: boolean)
    if not WasPurchased then return end
    local Entry = GetRegisterEntry(GamepassId)
    if not Player or not Entry or not Entry.OnPurchase then return end
    local label = GetLabelFromId(GamepassId)
    cache[Player][label] = true
    Entry.OnPurchase(Player)
end

-- binds a function to when a dev product is purchased
function Cashier.AddProduct(ProductId: number, OnPurchase: (Player)->())
    Register[tostring(ProductId)] = {
        Id = ProductId,
        OnPurchase = OnPurchase,
    }
end
--[[
    binds a function to when a gamepass is purchased, and a second function that allows to easily repeat some action associated with that gamepass
    also provides a label alias for that pass
]]
function Cashier.AddPass(GamepassId: number, OnReapply: (Player)->(), label: string, OnPurchase: (Player)->()?)
    table.insert(GamepassLabels, {GamepassId, label})
    Register[tostring(GamepassId)] = {
        Id = GamepassId,
        OnPurchase = OnPurchase,
        OnReapply = OnReapply
    }
end
-- :UserOwnsGamePassAsync but label and actually changes in real time when a player buys a gamepass
function Cashier.HasPass(Player: Player, label: string)
    if not cache[Player][label] or not GamepassLabels.label then return end
    cache[Player][label] = cache[Player][label] or MarketplaceService:UserOwnsGamePassAsync(Player.UserId, GetIdFromLabel(label))
    return cache[Player][label]
end
-- reapply a function binded to that gamepass
function Cashier.Reapply(Player: Player, label: string)
    if not Cashier.HasPass(Player, label) then return end
    if not Player then return end
    assert(label, "Tried to reapply nil, what?")
    local Entry = GetRegisterEntry(label)
    assert(Entry and Entry.OnReapply, `Cannot reapply gamepass \"{label}\": Something's not right!`)

    Entry.OnReapply(Player)
end
-- reapply all of player's gamepasses (useful for when, for example, a player respawns in a pvp game)
function Cashier.ReapplyAll(Player: Player)
    for _, v in GamepassLabels do
        Cashier.Reapply(Player, v[2])
    end
end
-- dumps all registered ids
function Cashier.Dump()
    local t = {}
    for _, v in Register do
        table.insert(t, v.Id)
    end
    return t
end

MarketplaceService.ProcessReceipt = DevproductPurchase
MarketplaceService.PromptGamePassPurchaseFinished:Connect(GamepassPurchase)

return Cashier