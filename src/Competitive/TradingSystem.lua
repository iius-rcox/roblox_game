-- TradingSystem.lua
-- Advanced trading system for Milestone 3: Competitive & Social Systems
-- Handles player-to-player trading, market listings, and secure trade execution

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Constants = require(script.Parent.Parent.Utils.Constants)
local NetworkManager = require(script.Parent.Parent.Multiplayer.NetworkManager)

local TradingSystem = {}
TradingSystem.__index = TradingSystem

-- RemoteEvents for client-server communication
local RemoteEvents = {
    TradeCreated = "TradeCreated",
    TradeUpdated = "TradeUpdated",
    TradeAccepted = "TradeAccepted",
    TradeCancelled = "TradeCancelled",
    TradeCompleted = "TradeCompleted",
    MarketListing = "MarketListing",
    MarketPurchase = "MarketPurchase",
    TradeHistory = "TradeHistory"
}

-- Trade status constants
local TRADE_STATUS = {
    PENDING = "PENDING",
    ACCEPTED = "ACCEPTED",
    CANCELLED = "CANCELLED",
    COMPLETED = "COMPLETED",
    EXPIRED = "EXPIRED"
}

-- Item types that can be traded
local TRADEABLE_ITEMS = {
    CASH = "CASH",
    ABILITY_POINTS = "ABILITY_POINTS",
    BUILDING_MATERIALS = "BUILDING_MATERIALS",
    COSMETIC_ITEMS = "COSMETIC_ITEMS",
    SPECIAL_ITEMS = "SPECIAL_ITEMS"
}

-- Market categories
local MARKET_CATEGORIES = {
    BUILDING_MATERIALS = "Building Materials",
    COSMETIC_ITEMS = "Cosmetic Items",
    SPECIAL_ITEMS = "Special Items",
    ABILITY_POINTS = "Ability Points"
}

function TradingSystem.new()
    local self = setmetatable({}, TradingSystem)
    
    -- Core data structures
    self.activeTrades = {}           -- Trade ID -> Trade Data
    self.marketListings = {}         -- Item -> Market Data
    self.tradeHistory = {}           -- Player -> Trade History
    self.escrowSystem = {}           -- Secure trade handling
    self.marketAnalytics = {}        -- Price tracking and trends
    
    -- Network manager reference
    self.networkManager = nil
    
    -- Initialize remote events
    self.remoteEvents = {}
    
    -- Trade settings
    self.maxActiveTrades = 5         -- Maximum trades per player
    self.tradeTimeout = 300          -- 5 minutes to accept trade
    self.marketTaxRate = 0.05        -- 5% tax on market sales
    self.minTradeAmount = 100        -- Minimum cash amount for trades
    
    -- Performance tracking
    self.lastMarketUpdate = 0
    self.marketUpdateInterval = 10   -- Update market every 10 seconds
    
    return self
end

function TradingSystem:Initialize(networkManager)
    self.networkManager = networkManager
    
    -- Set up remote events
    self:SetupRemoteEvents()
    
    -- Connect to player events
    self:ConnectPlayerEvents()
    
    -- Initialize market analytics
    self:InitializeMarketAnalytics()
    
    -- Set up periodic market updates
    self:SetupPeriodicUpdates()
    
    print("TradingSystem: Initialized successfully!")
end

-- Set up remote events for client-server communication
function TradingSystem:SetupRemoteEvents()
    for eventName, eventId in pairs(RemoteEvents) do
        local remoteEvent = Instance.new("RemoteEvent")
        remoteEvent.Name = eventId
        remoteEvent.Parent = self.networkManager:GetRemoteFolder()
        
        self.remoteEvents[eventName] = remoteEvent
    end
end

-- Connect to player events
function TradingSystem:ConnectPlayerEvents()
    Players.PlayerAdded:Connect(function(player)
        self:InitializePlayerData(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:CleanupPlayerData(player)
    end)
end

-- Initialize player trading data
function TradingSystem:InitializePlayerData(player)
    local userId = player.UserId
    
    if not self.tradeHistory[userId] then
        self.tradeHistory[userId] = {
            completedTrades = 0,
            totalValue = 0,
            lastTradeTime = 0,
            reputation = 100,  -- Starting reputation
            tradeHistory = {}
        }
    end
end

-- Clean up player data when they leave
function TradingSystem:CleanupPlayerData(player)
    local userId = player.UserId
    
    -- Cancel any active trades
    for tradeId, tradeData in pairs(self.activeTrades) do
        if tradeData.player1 == userId or tradeData.player2 == userId then
            self:CancelTrade(tradeId, "Player left the game")
        end
    end
    
    -- Remove from trade history
    self.tradeHistory[userId] = nil
end

-- Create a new trade between two players
function TradingSystem:CreateTrade(player1, player2)
    if not player1 or not player2 then
        return nil, "Invalid players"
    end
    
    local userId1 = player1.UserId
    local userId2 = player2.UserId
    
    -- Check if players can trade
    local canTrade1, reason1 = self:CanPlayerTrade(player1)
    local canTrade2, reason2 = self:CanPlayerTrade(player2)
    
    if not canTrade1 then
        return nil, "Player 1 cannot trade: " .. reason1
    end
    
    if not canTrade2 then
        return nil, "Player 2 cannot trade: " .. reason2
    end
    
    -- Check if trade already exists
    for tradeId, tradeData in pairs(self.activeTrades) do
        if (tradeData.player1 == userId1 and tradeData.player2 == userId2) or
           (tradeData.player1 == userId2 and tradeData.player2 == userId1) then
            return nil, "Trade already exists between these players"
        end
    end
    
    -- Create new trade
    local tradeId = HttpService:GenerateGUID()
    local tradeData = {
        id = tradeId,
        player1 = userId1,
        player2 = userId2,
        player1Name = player1.Name,
        player2Name = player2.Name,
        player1Items = {},
        player2Items = {},
        status = TRADE_STATUS.PENDING,
        createdAt = tick(),
        expiresAt = tick() + self.tradeTimeout,
        accepted1 = false,
        accepted2 = false
    }
    
    self.activeTrades[tradeId] = tradeData
    
    -- Notify both players
    self:NotifyTradeCreated(tradeData)
    
    print("TradingSystem: Created trade " .. tradeId .. " between " .. player1.Name .. " and " .. player2.Name)
    
    return tradeId
end

-- Check if a player can trade
function TradingSystem:CanPlayerTrade(player)
    local userId = player.UserId
    
    -- Check active trade limit
    local activeTradeCount = 0
    for tradeId, tradeData in pairs(self.activeTrades) do
        if tradeData.player1 == userId or tradeData.player2 == userId then
            activeTradeCount = activeTradeCount + 1
        end
    end
    
    if activeTradeCount >= self.maxActiveTrades then
        return false, "Maximum active trades reached"
    end
    
    -- Check reputation (can't trade if reputation is too low)
    local playerData = self.tradeHistory[userId]
    if playerData and playerData.reputation < 50 then
        return false, "Reputation too low to trade"
    end
    
    return true
end

-- Add items to a trade
function TradingSystem:AddTradeItem(tradeId, player, itemType, itemId, quantity)
    local tradeData = self.activeTrades[tradeId]
    if not tradeData then
        return false, "Trade not found"
    end
    
    local userId = player.UserId
    if tradeData.player1 ~= userId and tradeData.player2 ~= userId then
        return false, "Player not part of this trade"
    end
    
    if tradeData.status ~= TRADE_STATUS.PENDING then
        return false, "Trade is no longer pending"
    end
    
    -- Validate item
    if not self:IsItemTradeable(itemType, itemId) then
        return false, "Item cannot be traded"
    end
    
    -- Check if player has the item
    if not self:PlayerHasItem(player, itemType, itemId, quantity) then
        return false, "Player does not have enough of this item"
    end
    
    -- Add item to trade
    local playerItems = (tradeData.player1 == userId) and tradeData.player1Items or tradeData.player2Items
    
    -- Check if item already exists in trade
    local existingItem = nil
    for i, item in ipairs(playerItems) do
        if item.type == itemType and item.id == itemId then
            existingItem = i
            break
        end
    end
    
    if existingItem then
        playerItems[existingItem].quantity = playerItems[existingItem].quantity + quantity
    else
        table.insert(playerItems, {
            type = itemType,
            id = itemId,
            quantity = quantity,
            name = self:GetItemName(itemType, itemId)
        })
    end
    
    -- Reset accept status since trade changed
    tradeData.accepted1 = false
    tradeData.accepted2 = false
    
    -- Notify both players
    self:NotifyTradeUpdated(tradeData)
    
    print("TradingSystem: Added " .. quantity .. "x " .. itemType .. ":" .. itemId .. " to trade " .. tradeId)
    
    return true
end

-- Accept a trade
function TradingSystem:AcceptTrade(tradeId, player)
    local tradeData = self.activeTrades[tradeId]
    if not tradeData then
        return false, "Trade not found"
    end
    
    local userId = player.UserId
    if tradeData.player1 ~= userId and tradeData.player2 ~= userId then
        return false, "Player not part of this trade"
    end
    
    if tradeData.status ~= TRADE_STATUS.PENDING then
        return false, "Trade is no longer pending"
    end
    
    -- Mark player as accepted
    if tradeData.player1 == userId then
        tradeData.accepted1 = true
    else
        tradeData.accepted2 = true
    end
    
    -- Check if both players accepted
    if tradeData.accepted1 and tradeData.accepted2 then
        self:ExecuteTrade(tradeId)
    else
        -- Notify trade update
        self:NotifyTradeUpdated(tradeData)
    end
    
    return true
end

-- Execute a trade when both players accept
function TradingSystem:ExecuteTrade(tradeId)
    local tradeData = self.activeTrades[tradeId]
    if not tradeData then
        return false, "Trade not found"
    end
    
    -- Validate trade items again
    local player1 = Players:GetPlayerByUserId(tradeData.player1)
    local player2 = Players:GetPlayerByUserId(tradeData.player2)
    
    if not player1 or not player2 then
        self:CancelTrade(tradeId, "One or both players left the game")
        return false
    end
    
    -- Check if players still have the items
    for _, item in ipairs(tradeData.player1Items) do
        if not self:PlayerHasItem(player1, item.type, item.id, item.quantity) then
            self:CancelTrade(tradeId, "Player 1 no longer has required items")
            return false
        end
    end
    
    for _, item in ipairs(tradeData.player2Items) do
        if not self:PlayerHasItem(player2, item.type, item.id, item.quantity) then
            self:CancelTrade(tradeId, "Player 2 no longer has required items")
            return false
        end
    end
    
    -- Execute the trade using escrow system
    local success = self:ProcessTradeExchange(tradeData)
    
    if success then
        -- Mark trade as completed
        tradeData.status = TRADE_STATUS.COMPLETED
        tradeData.completedAt = tick()
        
        -- Update trade history
        self:UpdateTradeHistory(tradeData)
        
        -- Notify completion
        self:NotifyTradeCompleted(tradeData)
        
        -- Remove from active trades
        self.activeTrades[tradeId] = nil
        
        print("TradingSystem: Trade " .. tradeId .. " completed successfully")
        
        return true
    else
        self:CancelTrade(tradeId, "Failed to process trade exchange")
        return false
    end
end

-- Process the actual exchange of items
function TradingSystem:ProcessTradeExchange(tradeData)
    local player1 = Players:GetPlayerByUserId(tradeData.player1)
    local player2 = Players:GetPlayerByUserId(tradeData.player2)
    
    if not player1 or not player2 then
        return false
    end
    
    -- Use escrow system to ensure safe exchange
    local escrowId = self:CreateEscrow(tradeData)
    
    -- Transfer items from player 1 to escrow
    for _, item in ipairs(tradeData.player1Items) do
        if not self:TransferItemToEscrow(player1, item, escrowId) then
            self:CancelEscrow(escrowId)
            return false
        end
    end
    
    -- Transfer items from player 2 to escrow
    for _, item in ipairs(tradeData.player2Items) do
        if not self:TransferItemToEscrow(player2, item, escrowId) then
            self:CancelEscrow(escrowId)
            return false
        end
    end
    
    -- Distribute items from escrow
    for _, item in ipairs(tradeData.player1Items) do
        self:TransferItemFromEscrow(player2, item, escrowId)
    end
    
    for _, item in ipairs(tradeData.player2Items) do
        self:TransferItemFromEscrow(player1, item, escrowId)
    end
    
    -- Close escrow
    self:CloseEscrow(escrowId)
    
    return true
end

-- Cancel a trade
function TradingSystem:CancelTrade(tradeId, reason)
    local tradeData = self.activeTrades[tradeId]
    if not tradeData then
        return false, "Trade not found"
    end
    
    tradeData.status = TRADE_STATUS.CANCELLED
    tradeData.cancelledAt = tick()
    tradeData.cancelReason = reason
    
    -- Notify cancellation
    self:NotifyTradeCancelled(tradeData)
    
    -- Remove from active trades
    self.activeTrades[tradeId] = nil
    
    print("TradingSystem: Trade " .. tradeId .. " cancelled: " .. reason)
    
    return true
end

-- Market listing system
function TradingSystem:ListMarketItem(player, itemType, itemId, quantity, price)
    if not self:IsItemTradeable(itemType, itemId) then
        return false, "Item cannot be listed on market"
    end
    
    if not self:PlayerHasItem(player, itemType, itemId, quantity) then
        return false, "Player does not have enough of this item"
    end
    
    if price < self.minTradeAmount then
        return false, "Price below minimum trade amount"
    end
    
    -- Create market listing
    local listingId = HttpService:GenerateGUID()
    local listing = {
        id = listingId,
        seller = player.UserId,
        sellerName = player.Name,
        itemType = itemType,
        itemId = itemId,
        quantity = quantity,
        price = price,
        listedAt = tick(),
        expiresAt = tick() + (7 * 24 * 60 * 60), -- 7 days
        status = "ACTIVE"
    }
    
    self.marketListings[listingId] = listing
    
    -- Remove item from player inventory
    self:RemoveItemFromPlayer(player, itemType, itemId, quantity)
    
    -- Update market analytics
    self:UpdateMarketAnalytics(itemType, itemId, price, quantity)
    
    -- Notify market listing
    self:NotifyMarketListing(listing)
    
    print("TradingSystem: Listed " .. quantity .. "x " .. itemType .. ":" .. itemId .. " for " .. price .. " cash")
    
    return listingId
end

-- Purchase item from market
function TradingSystem:PurchaseMarketItem(buyer, listingId)
    local listing = self.marketListings[listingId]
    if not listing then
        return false, "Listing not found"
    end
    
    if listing.status ~= "ACTIVE" then
        return false, "Listing is no longer active"
    end
    
    if listing.expiresAt < tick() then
        listing.status = "EXPIRED"
        return false, "Listing has expired"
    end
    
    -- Check if buyer has enough cash
    if not self:PlayerHasCash(buyer, listing.price) then
        return false, "Not enough cash to purchase item"
    end
    
    -- Process purchase
    local seller = Players:GetPlayerByUserId(listing.seller)
    
    -- Transfer cash from buyer to seller
    self:TransferCash(buyer, listing.price, false) -- Deduct from buyer
    if seller then
        local taxAmount = math.floor(listing.price * self.marketTaxRate)
        local sellerAmount = listing.price - taxAmount
        self:TransferCash(seller, sellerAmount, true) -- Add to seller (after tax)
    end
    
    -- Transfer item to buyer
    self:AddItemToPlayer(buyer, listing.itemType, listing.itemId, listing.quantity)
    
    -- Mark listing as sold
    listing.status = "SOLD"
    listing.soldAt = tick()
    listing.buyer = buyer.UserId
    listing.buyerName = buyer.Name
    
    -- Update market analytics
    self:UpdateMarketAnalytics(listing.itemType, listing.itemId, listing.price, -listing.quantity)
    
    -- Notify market purchase
    self:NotifyMarketPurchase(listing, buyer)
    
    print("TradingSystem: " .. buyer.Name .. " purchased " .. listing.quantity .. "x " .. listing.itemType .. ":" .. listing.itemId .. " for " .. listing.price .. " cash")
    
    return true
end

-- Utility functions for item management
function TradingSystem:IsItemTradeable(itemType, itemId)
    for _, tradeableType in pairs(TRADEABLE_ITEMS) do
        if itemType == tradeableType then
            return true
        end
    end
    return false
end

function TradingSystem:PlayerHasItem(player, itemType, itemId, quantity)
    -- This would integrate with the player's inventory system
    -- For now, return true as placeholder
    return true
end

function TradingSystem:PlayerHasCash(player, amount)
    -- This would integrate with the player's economy system
    -- For now, return true as placeholder
    return true
end

function TradingSystem:GetItemName(itemType, itemId)
    -- This would integrate with the item database
    -- For now, return a placeholder name
    return itemType .. "_" .. itemId
end

function TradingSystem:RemoveItemFromPlayer(player, itemType, itemId, quantity)
    -- This would integrate with the player's inventory system
    -- For now, just log the action
    print("TradingSystem: Removed " .. quantity .. "x " .. itemType .. ":" .. itemId .. " from " .. player.Name)
end

function TradingSystem:AddItemToPlayer(player, itemType, itemId, quantity)
    -- This would integrate with the player's inventory system
    -- For now, just log the action
    print("TradingSystem: Added " .. quantity .. "x " .. itemType .. ":" .. itemId .. " to " .. player.Name)
end

function TradingSystem:TransferCash(player, amount, isAddition)
    -- This would integrate with the player's economy system
    -- For now, just log the action
    local action = isAddition and "added" or "deducted"
    print("TradingSystem: " .. action .. " " .. amount .. " cash from " .. player.Name)
end

-- Escrow system for secure trading
function TradingSystem:CreateEscrow(tradeData)
    local escrowId = HttpService:GenerateGUID()
    self.escrowSystem[escrowId] = {
        id = escrowId,
        tradeId = tradeData.id,
        items = {},
        createdAt = tick(),
        status = "ACTIVE"
    }
    return escrowId
end

function TradingSystem:TransferItemToEscrow(player, item, escrowId)
    local escrow = self.escrowSystem[escrowId]
    if not escrow then
        return false
    end
    
    table.insert(escrow.items, {
        player = player.UserId,
        item = item
    })
    
    return true
end

function TradingSystem:TransferItemFromEscrow(player, item, escrowId)
    local escrow = self.escrowSystem[escrowId]
    if not escrow then
        return false
    end
    
    -- Find and remove item from escrow
    for i, escrowItem in ipairs(escrow.items) do
        if escrowItem.player ~= player.UserId and 
           escrowItem.item.type == item.type and 
           escrowItem.item.id == item.id and 
           escrowItem.item.quantity == item.quantity then
            table.remove(escrow.items, i)
            break
        end
    end
    
    -- Add item to player
    self:AddItemToPlayer(player, item.type, item.id, item.quantity)
    
    return true
end

function TradingSystem:CancelEscrow(escrowId)
    local escrow = self.escrowSystem[escrowId]
    if not escrow then
        return
    end
    
    -- Return items to original owners
    for _, escrowItem in ipairs(escrow.items) do
        local player = Players:GetPlayerByUserId(escrowItem.player)
        if player then
            self:AddItemToPlayer(player, escrowItem.item.type, escrowItem.item.id, escrowItem.item.quantity)
        end
    end
    
    escrow.status = "CANCELLED"
end

function TradingSystem:CloseEscrow(escrowId)
    local escrow = self.escrowSystem[escrowId]
    if escrow then
        escrow.status = "CLOSED"
        escrow.closedAt = tick()
    end
end

-- Market analytics
function TradingSystem:InitializeMarketAnalytics()
    for itemType, _ in pairs(TRADEABLE_ITEMS) do
        self.marketAnalytics[itemType] = {
            totalListings = 0,
            totalVolume = 0,
            averagePrice = 0,
            priceHistory = {},
            lastUpdated = 0
        }
    end
end

function TradingSystem:UpdateMarketAnalytics(itemType, itemId, price, quantity)
    local analytics = self.marketAnalytics[itemType]
    if not analytics then
        return
    end
    
    analytics.totalListings = math.max(0, analytics.totalListings + (quantity > 0 and 1 or -1))
    analytics.totalVolume = analytics.totalVolume + math.abs(quantity)
    
    -- Update average price
    if analytics.totalVolume > 0 then
        analytics.averagePrice = (analytics.averagePrice * (analytics.totalVolume - math.abs(quantity)) + price * math.abs(quantity)) / analytics.totalVolume
    end
    
    -- Add to price history
    table.insert(analytics.priceHistory, {
        price = price,
        quantity = math.abs(quantity),
        timestamp = tick()
    })
    
    -- Keep only last 100 price points
    if #analytics.priceHistory > 100 then
        table.remove(analytics.priceHistory, 1)
    end
    
    analytics.lastUpdated = tick()
end

-- Periodic updates
function TradingSystem:SetupPeriodicUpdates()
    RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        
        -- Update market prices
        if currentTime - self.lastMarketUpdate >= self.marketUpdateInterval then
            self:UpdateMarketPrices()
            self.lastMarketUpdate = currentTime
        end
        
        -- Clean up expired trades
        self:CleanupExpiredTrades()
        
        -- Clean up expired market listings
        self:CleanupExpiredListings()
    end)
end

function TradingSystem:UpdateMarketPrices()
    -- This would implement dynamic pricing based on supply/demand
    -- For now, just log the update
    print("TradingSystem: Updated market prices")
end

function TradingSystem:CleanupExpiredTrades()
    local currentTime = tick()
    local expiredTrades = {}
    
    for tradeId, tradeData in pairs(self.activeTrades) do
        if tradeData.expiresAt < currentTime then
            table.insert(expiredTrades, tradeId)
        end
    end
    
    for _, tradeId in ipairs(expiredTrades) do
        self:CancelTrade(tradeId, "Trade expired")
    end
end

function TradingSystem:CleanupExpiredListings()
    local currentTime = tick()
    local expiredListings = {}
    
    for listingId, listing in pairs(self.marketListings) do
        if listing.expiresAt < currentTime and listing.status == "ACTIVE" then
            listing.status = "EXPIRED"
            table.insert(expiredListings, listingId)
        end
    end
    
    for _, listingId in ipairs(expiredListings) do
        local listing = self.marketListings[listingId]
        if listing then
            -- Return item to seller
            local seller = Players:GetPlayerByUserId(listing.seller)
            if seller then
                self:AddItemToPlayer(seller, listing.itemType, listing.itemId, listing.quantity)
            end
            
            -- Remove from market
            self.marketListings[listingId] = nil
        end
    end
end

-- Update trade history
function TradingSystem:UpdateTradeHistory(tradeData)
    local player1Data = self.tradeHistory[tradeData.player1]
    local player2Data = self.tradeHistory[tradeData.player2]
    
    if player1Data then
        player1Data.completedTrades = player1Data.completedTrades + 1
        player1Data.lastTradeTime = tick()
        player1Data.totalValue = player1Data.totalValue + self:CalculateTradeValue(tradeData.player1Items)
        
        table.insert(player1Data.tradeHistory, {
            tradeId = tradeData.id,
            partner = tradeData.player2Name,
            items = tradeData.player1Items,
            timestamp = tick()
        })
    end
    
    if player2Data then
        player2Data.completedTrades = player2Data.completedTrades + 1
        player2Data.lastTradeTime = tick()
        player2Data.totalValue = player2Data.totalValue + self:CalculateTradeValue(tradeData.player2Items)
        
        table.insert(player2Data.tradeHistory, {
            tradeId = tradeData.id,
            partner = tradeData.player1Name,
            items = tradeData.player2Items,
            timestamp = tick()
        })
    end
end

function TradingSystem:CalculateTradeValue(items)
    local totalValue = 0
    for _, item in ipairs(items) do
        -- This would integrate with item pricing system
        -- For now, use placeholder values
        if item.type == "CASH" then
            totalValue = totalValue + item.quantity
        else
            totalValue = totalValue + (item.quantity * 100) -- Placeholder item value
        end
    end
    return totalValue
end

-- Notification functions
function TradingSystem:NotifyTradeCreated(tradeData)
    local player1 = Players:GetPlayerByUserId(tradeData.player1)
    local player2 = Players:GetPlayerByUserId(tradeData.player2)
    
    if player1 then
        self.networkManager:SendToClient(player1, RemoteEvents.TradeCreated, {
            tradeId = tradeData.id,
            partner = tradeData.player2Name,
            status = tradeData.status
        })
    end
    
    if player2 then
        self.networkManager:SendToClient(player2, RemoteEvents.TradeCreated, {
            tradeId = tradeData.id,
            partner = tradeData.player1Name,
            status = tradeData.status
        })
    end
end

function TradingSystem:NotifyTradeUpdated(tradeData)
    local player1 = Players:GetPlayerByUserId(tradeData.player1)
    local player2 = Players:GetPlayerByUserId(tradeData.player2)
    
    local updateData = {
        tradeId = tradeData.id,
        player1Items = tradeData.player1Items,
        player2Items = tradeData.player2Items,
        accepted1 = tradeData.accepted1,
        accepted2 = tradeData.accepted2
    }
    
    if player1 then
        self.networkManager:SendToClient(player1, RemoteEvents.TradeUpdated, updateData)
    end
    
    if player2 then
        self.networkManager:SendToClient(player2, RemoteEvents.TradeUpdated, updateData)
    end
end

function TradingSystem:NotifyTradeAccepted(tradeData)
    local player1 = Players:GetPlayerByUserId(tradeData.player1)
    local player2 = Players:GetPlayerByUserId(tradeData.player2)
    
    if player1 then
        self.networkManager:SendToClient(player1, RemoteEvents.TradeAccepted, {
            tradeId = tradeData.id,
            accepted = true
        })
    end
    
    if player2 then
        self.networkManager:SendToClient(player2, RemoteEvents.TradeAccepted, {
            tradeId = tradeData.id,
            accepted = true
        })
    end
end

function TradingSystem:NotifyTradeCancelled(tradeData)
    local player1 = Players:GetPlayerByUserId(tradeData.player1)
    local player2 = Players:GetPlayerByUserId(tradeData.player2)
    
    local cancelData = {
        tradeId = tradeData.id,
        reason = tradeData.cancelReason or "Unknown reason"
    }
    
    if player1 then
        self.networkManager:SendToClient(player1, RemoteEvents.TradeCancelled, cancelData)
    end
    
    if player2 then
        self.networkManager:SendToClient(player2, RemoteEvents.TradeCancelled, cancelData)
    end
end

function TradingSystem:NotifyTradeCompleted(tradeData)
    local player1 = Players:GetPlayerByUserId(tradeData.player1)
    local player2 = Players:GetPlayerByUserId(tradeData.player2)
    
    local completionData = {
        tradeId = tradeData.id,
        player1Items = tradeData.player1Items,
        player2Items = tradeData.player2Items,
        completedAt = tradeData.completedAt
    }
    
    if player1 then
        self.networkManager:SendToClient(player1, RemoteEvents.TradeCompleted, completionData)
    end
    
    if player2 then
        self.networkManager:SendToClient(player2, RemoteEvents.TradeCompleted, completionData)
    end
end

function TradingSystem:NotifyMarketListing(listing)
    -- Broadcast to all players (could be filtered based on interest)
    for _, player in pairs(Players:GetPlayers()) do
        self.networkManager:SendToClient(player, RemoteEvents.MarketListing, {
            listingId = listing.id,
            itemType = listing.itemType,
            itemId = listing.itemId,
            quantity = listing.quantity,
            price = listing.price,
            seller = listing.sellerName
        })
    end
end

function TradingSystem:NotifyMarketPurchase(listing, buyer)
    -- Notify seller
    local seller = Players:GetPlayerByUserId(listing.seller)
    if seller then
        self.networkManager:SendToClient(seller, RemoteEvents.MarketPurchase, {
            listingId = listing.id,
            itemType = listing.itemType,
            itemId = listing.itemId,
            quantity = listing.quantity,
            price = listing.price,
            buyer = buyer.Name,
            taxAmount = math.floor(listing.price * self.marketTaxRate)
        })
    end
    
    -- Notify buyer
    self.networkManager:SendToClient(buyer, RemoteEvents.MarketPurchase, {
        listingId = listing.id,
        itemType = listing.itemType,
        itemId = listing.itemId,
        quantity = listing.quantity,
        price = listing.price,
        seller = listing.sellerName
    })
end

-- Public API functions
function TradingSystem:GetPlayerTradeHistory(player)
    local userId = player.UserId
    return self.tradeHistory[userId]
end

function TradingSystem:GetActiveTrades(player)
    local userId = player.UserId
    local playerTrades = {}
    
    for tradeId, tradeData in pairs(self.activeTrades) do
        if tradeData.player1 == userId or tradeData.player2 == userId then
            table.insert(playerTrades, tradeData)
        end
    end
    
    return playerTrades
end

function TradingSystem:GetMarketListings(category)
    local listings = {}
    
    for listingId, listing in pairs(self.marketListings) do
        if listing.status == "ACTIVE" and (not category or listing.itemType == category) then
            table.insert(listings, listing)
        end
    end
    
    -- Sort by price (lowest first)
    table.sort(listings, function(a, b)
        return a.price < b.price
    end)
    
    return listings
end

function TradingSystem:GetMarketAnalytics(itemType)
    return self.marketAnalytics[itemType]
end

-- Cleanup
function TradingSystem:Cleanup()
    print("TradingSystem: Starting cleanup...")
    
    -- Clean up remote events
    for _, remoteEvent in pairs(self.remoteEvents) do
        if remoteEvent and remoteEvent.Parent then
            remoteEvent:Destroy()
        end
    end
    
    -- Clean up active trades
    for tradeId, tradeData in pairs(self.activeTrades) do
        self:CancelTrade(tradeId, "System cleanup")
    end
    
    -- Clean up market listings
    for listingId, listing in pairs(self.marketListings) do
        if listing.status == "ACTIVE" then
            local seller = Players:GetPlayerByUserId(listing.seller)
            if seller then
                self:AddItemToPlayer(seller, listing.itemType, listing.itemId, listing.quantity)
            end
        end
    end
    
    self.marketListings = {}
    
    print("TradingSystem: Cleanup completed!")
end

-- Get trading system metrics
function TradingSystem:GetTradingMetrics()
    local metrics = {
        activeTrades = 0,
        totalTrades = 0,
        marketListings = 0,
        tradeVolume = 0,
        marketAnalytics = {},
        escrowStatus = {}
    }
    
    -- Count active trades
    for tradeId, tradeData in pairs(self.activeTrades) do
        metrics.activeTrades = metrics.activeTrades + 1
    end
    
    -- Count total trades in history
    for userId, history in pairs(self.tradeHistory) do
        if history then
            metrics.totalTrades = metrics.totalTrades + #history
        end
    end
    
    -- Count market listings
    for listingId, listing in pairs(self.marketListings) do
        if listing.status == "ACTIVE" then
            metrics.marketListings = metrics.marketListings + 1
        end
    end
    
    -- Calculate trade volume
    for userId, history in pairs(self.tradeHistory) do
        if history then
            for _, trade in ipairs(history) do
                if trade.status == "COMPLETED" and trade.totalValue then
                    metrics.tradeVolume = metrics.tradeVolume + trade.totalValue
                end
            end
        end
    end
    
    -- Get market analytics summary
    for itemType, analytics in pairs(self.marketAnalytics) do
        metrics.marketAnalytics[itemType] = {
            totalVolume = analytics.totalVolume or 0,
            averagePrice = analytics.averagePrice or 0,
            listings = 0
        }
        
        -- Count active listings for this item type
        for listingId, listing in pairs(self.marketListings) do
            if listing.status == "ACTIVE" and listing.itemType == itemType then
                metrics.marketAnalytics[itemType].listings = metrics.marketAnalytics[itemType].listings + 1
            end
        end
    end
    
    -- Get escrow status
    for escrowId, escrow in pairs(self.activeEscrows) do
        metrics.escrowStatus[escrowId] = {
            status = escrow.status,
            value = escrow.totalValue or 0,
            timeActive = tick() - escrow.createdAt
        }
    end
    
    return metrics
end

return TradingSystem
