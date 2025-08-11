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
    TradeHistory = "TradeHistory",
    -- Anime-specific trading events
    AnimeCardTrade = "AnimeCardTrade",
    ArtifactTrade = "ArtifactTrade",
    SeasonalItemTrade = "SeasonalItemTrade",
    CrossAnimeTrade = "CrossAnimeTrade"
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
    SPECIAL_ITEMS = "SPECIAL_ITEMS",
    -- Anime-specific tradeable items
    ANIME_CHARACTER_CARDS = "ANIME_CHARACTER_CARDS",
    RARE_ARTIFACTS = "RARE_ARTIFACTS",
    ANIME_WEAPONS = "ANIME_WEAPONS",
    SEASONAL_EVENT_ITEMS = "SEASONAL_EVENT_ITEMS",
    CROSS_ANIME_ITEMS = "CROSS_ANIME_ITEMS"
}

-- Market categories
local MARKET_CATEGORIES = {
    BUILDING_MATERIALS = "Building Materials",
    COSMETIC_ITEMS = "Cosmetic Items",
    SPECIAL_ITEMS = "Special Items",
    ABILITY_POINTS = "Ability Points",
    -- Anime-specific market categories
    ANIME_CHARACTER_CARDS = "Anime Character Cards",
    RARE_ARTIFACTS = "Rare Artifacts",
    ANIME_WEAPONS = "Anime Weapons",
    SEASONAL_EVENT_ITEMS = "Seasonal Event Items",
    CROSS_ANIME_ITEMS = "Cross-Anime Items"
}

-- Anime character card rarities
local ANIME_CARD_RARITIES = {
    COMMON = { name = "Common", multiplier = 1.0, color = Color3.fromRGB(150, 150, 150) },
    UNCOMMON = { name = "Uncommon", multiplier = 1.5, color = Color3.fromRGB(0, 255, 0) },
    RARE = { name = "Rare", multiplier = 2.5, color = Color3.fromRGB(0, 100, 255) },
    EPIC = { name = "Epic", multiplier = 4.0, color = Color3.fromRGB(150, 0, 255) },
    LEGENDARY = { name = "Legendary", multiplier = 7.0, color = Color3.fromRGB(255, 215, 0) },
    MYTHIC = { name = "Mythic", multiplier = 12.0, color = Color3.fromRGB(255, 0, 100) }
}

-- Anime themes for character cards
local ANIME_THEMES = {
    "NARUTO", "DRAGON_BALL", "ONE_PIECE", "ATTACK_ON_TITAN", "MY_HERO_ACADEMIA",
    "DEMON_SLAYER", "JUJUTSU_KAISEN", "HUNTER_X_HUNTER", "FAIRY_TAIL", "BLEACH",
    "DEATH_NOTE", "FULLMETAL_ALCHEMIST", "STEINS_GATE", "CODE_GEASS", "EVANGELION",
    "COWBOY_BEBOP", "GHOST_IN_THE_SHELL", "AKIRA", "SPIRITED_AWAY", "PRINCESS_MONONOKE"
}

-- Rare artifact types
local ARTIFACT_TYPES = {
    "POWER_SCALING", "CHARACTER_EVOLUTION", "WORLD_EVENT", "GUILD_WAR", "CROSSOVER_EVENT",
    "SEASONAL_CHALLENGE", "FUSION_BATTLE", "MENTORSHIP", "TRADING_CARD", "ANIME_MASTERY"
}

-- Seasonal event types
local SEASONAL_EVENT_TYPES = {
    "SPRING_FESTIVAL", "SUMMER_TOURNAMENT", "AUTUMN_COLLECTION", "WINTER_WARFARE",
    "NEW_YEAR_CELEBRATION", "HALLOWEEN_SPECIAL", "VALENTINE_DAY", "CHRISTMAS_EVENT"
}

function TradingSystem.new()
    local self = setmetatable({}, TradingSystem)
    
    -- Core data structures
    self.activeTrades = {}           -- Trade ID -> Trade Data
    self.marketListings = {}         -- Item -> Market Data
    self.tradeHistory = {}           -- Player -> Trade History
    self.escrowSystem = {}           -- Secure trade handling
    self.marketAnalytics = {}        -- Price tracking and trends
    
    -- Anime-specific trading data structures
    self.animeCardTrades = {}        -- Anime character card trades
    self.artifactTrades = {}         -- Rare artifact trades
    self.seasonalItemTrades = {}     -- Seasonal event item trades
    self.crossAnimeTrades = {}       -- Cross-anime collaboration trades
    self.animeTradingMetrics = {}    -- Anime-specific trading analytics
    
    -- Network manager reference
    self.networkManager = nil
    
    -- Initialize remote events
    self.remoteEvents = {}
    
    -- Trade settings
    self.maxActiveTrades = 5         -- Maximum trades per player
    self.tradeTimeout = 300          -- 5 minutes to accept trade
    self.marketTaxRate = 0.05        -- 5% tax on market sales
    self.minTradeAmount = 100        -- Minimum cash amount for trades
    
    -- Anime trading settings
    self.animeCardTradeLimit = 10    -- Maximum anime cards per trade
    self.artifactTradeLimit = 5      -- Maximum artifacts per trade
    self.seasonalItemTradeLimit = 20 -- Maximum seasonal items per trade
    self.crossAnimeTradeLimit = 15   -- Maximum cross-anime items per trade
    
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
    
    -- Initialize anime trading systems
    self:InitializeAnimeTradingSystems()
    
    -- Set up periodic market updates
    self:SetupPeriodicUpdates()
    
    print("TradingSystem: Initialized successfully!")
end

-- Initialize anime-specific trading systems
function TradingSystem:InitializeAnimeTradingSystems()
    -- Initialize anime card trading
    self:InitializeAnimeCardTrading()
    
    -- Initialize artifact trading
    self:InitializeArtifactTrading()
    
    -- Initialize seasonal item trading
    self:InitializeSeasonalItemTrading()
    
    -- Initialize cross-anime trading
    self:InitializeCrossAnimeTrading()
    
    print("TradingSystem: Anime trading systems initialized!")
end

-- Initialize anime character card trading
function TradingSystem:InitializeAnimeCardTrading()
    self.animeCardTrades = {}
    self.animeTradingMetrics.characterCards = {
        totalTrades = 0,
        totalVolume = 0,
        rarityDistribution = {},
        themeDistribution = {},
        averagePrice = 0,
        priceHistory = {}
    }
    
    -- Initialize rarity distribution
    for rarity, _ in pairs(ANIME_CARD_RARITIES) do
        self.animeTradingMetrics.characterCards.rarityDistribution[rarity] = 0
    end
    
    -- Initialize theme distribution
    for _, theme in ipairs(ANIME_THEMES) do
        self.animeTradingMetrics.characterCards.themeDistribution[theme] = 0
    end
end

-- Initialize rare artifact trading
function TradingSystem:InitializeArtifactTrading()
    self.artifactTrades = {}
    self.animeTradingMetrics.artifacts = {
        totalTrades = 0,
        totalVolume = 0,
        typeDistribution = {},
        powerLevelDistribution = {},
        averagePrice = 0,
        priceHistory = {}
    }
    
    -- Initialize artifact type distribution
    for _, artifactType in ipairs(ARTIFACT_TYPES) do
        self.animeTradingMetrics.artifacts.typeDistribution[artifactType] = 0
    end
end

-- Initialize seasonal event item trading
function TradingSystem:InitializeSeasonalItemTrading()
    self.seasonalItemTrades = {}
    self.animeTradingMetrics.seasonalItems = {
        totalTrades = 0,
        totalVolume = 0,
        eventTypeDistribution = {},
        seasonalMultiplier = {},
        averagePrice = 0,
        priceHistory = {}
    }
    
    -- Initialize seasonal event type distribution
    for _, eventType in ipairs(SEASONAL_EVENT_TYPES) do
        self.animeTradingMetrics.seasonalItems.eventTypeDistribution[eventType] = 0
    end
end

-- Initialize cross-anime collaboration trading
function TradingSystem:InitializeCrossAnimeTrading()
    self.crossAnimeTrades = {}
    self.animeTradingMetrics.crossAnimeItems = {
        totalTrades = 0,
        totalVolume = 0,
        collaborationTypes = {},
        animeCombinations = {},
        averagePrice = 0,
        priceHistory = {}
    }
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

-- Anime-specific trading functions

-- Create anime character card trade
function TradingSystem:CreateAnimeCardTrade(player1, player2, cards1, cards2)
    if not player1 or not player2 then
        return nil, "Invalid players"
    end
    
    -- Validate card limits
    if #cards1 > self.animeCardTradeLimit or #cards2 > self.animeCardTradeLimit then
        return nil, "Exceeded maximum cards per trade"
    end
    
    -- Validate cards
    local validCards1, reason1 = self:ValidateAnimeCards(player1, cards1)
    local validCards2, reason2 = self:ValidateAnimeCards(player2, cards2)
    
    if not validCards1 then
        return nil, "Player 1 cards invalid: " .. reason1
    end
    
    if not validCards2 then
        return nil, "Player 2 cards invalid: " .. reason2
    end
    
    -- Create trade
    local tradeId = HttpService:GenerateGUID()
    local tradeData = {
        id = tradeId,
        type = "ANIME_CARD_TRADE",
        player1 = player1.UserId,
        player2 = player2.UserId,
        player1Name = player1.Name,
        player2Name = player2.Name,
        cards1 = cards1,
        cards2 = cards2,
        status = TRADE_STATUS.PENDING,
        createdAt = tick(),
        expiresAt = tick() + self.tradeTimeout,
        accepted1 = false,
        accepted2 = false,
        estimatedValue = self:CalculateAnimeCardTradeValue(cards1, cards2)
    }
    
    self.animeCardTrades[tradeId] = tradeData
    
    -- Update metrics
    self:UpdateAnimeCardTradeMetrics(tradeData)
    
    -- Notify players
    self:NotifyAnimeCardTradeCreated(tradeData)
    
    print("TradingSystem: Created anime card trade " .. tradeId .. " between " .. player1.Name .. " and " .. player2.Name)
    return tradeId
end

-- Validate anime character cards
function TradingSystem:ValidateAnimeCards(player, cards)
    if not cards or #cards == 0 then
        return false, "No cards provided"
    end
    
    for _, card in ipairs(cards) do
        -- Check if card has required properties
        if not card.id or not card.rarity or not card.theme or not card.powerLevel then
            return false, "Invalid card format"
        end
        
        -- Check if rarity is valid
        if not ANIME_CARD_RARITIES[card.rarity] then
            return false, "Invalid card rarity: " .. card.rarity
        end
        
        -- Check if theme is valid
        if not table.find(ANIME_THEMES, card.theme) then
            return false, "Invalid card theme: " .. card.theme
        end
        
        -- Check if player owns the card
        if not self:PlayerHasAnimeCard(player, card.id) then
            return false, "Player does not own card: " .. card.id
        end
    end
    
    return true
end

-- Check if player has anime card
function TradingSystem:PlayerHasAnimeCard(player, cardId)
    -- This would integrate with the player's anime card collection
    -- For now, return true as placeholder
    return true
end

-- Calculate anime card trade value
function TradingSystem:CalculateAnimeCardTradeValue(cards1, cards2)
    local value1 = self:CalculateAnimeCardsValue(cards1)
    local value2 = self:CalculateAnimeCardsValue(cards2)
    
    return {
        player1Value = value1,
        player2Value = value2,
        difference = math.abs(value1 - value2),
        isBalanced = math.abs(value1 - value2) < 1000 -- Consider balanced if within 1000 points
    }
end

-- Calculate value of anime cards
function TradingSystem:CalculateAnimeCardsValue(cards)
    local totalValue = 0
    
    for _, card in ipairs(cards) do
        local rarity = ANIME_CARD_RARITIES[card.rarity]
        if rarity then
            local baseValue = card.powerLevel * 100
            local rarityMultiplier = rarity.multiplier
            local themeBonus = self:GetAnimeThemeBonus(card.theme)
            
            local cardValue = math.floor(baseValue * rarityMultiplier * themeBonus)
            totalValue = totalValue + cardValue
        end
    end
    
    return totalValue
end

-- Get anime theme bonus
function TradingSystem:GetAnimeThemeBonus(theme)
    -- Some themes might have higher trading value
    local themeBonuses = {
        NARUTO = 1.1,
        DRAGON_BALL = 1.15,
        ONE_PIECE = 1.1,
        ATTACK_ON_TITAN = 1.2,
        MY_HERO_ACADEMIA = 1.05,
        DEMON_SLAYER = 1.25,
        JUJUTSU_KAISEN = 1.2,
        HUNTER_X_HUNTER = 1.1,
        FAIRY_TAIL = 1.05,
        BLEACH = 1.1
    }
    
    return themeBonuses[theme] or 1.0
end

-- Create rare artifact trade
function TradingSystem:CreateArtifactTrade(player1, player2, artifacts1, artifacts2)
    if not player1 or not player2 then
        return nil, "Invalid players"
    end
    
    -- Validate artifact limits
    if #artifacts1 > self.artifactTradeLimit or #artifacts2 > self.artifactTradeLimit then
        return nil, "Exceeded maximum artifacts per trade"
    end
    
    -- Validate artifacts
    local validArtifacts1, reason1 = self:ValidateArtifacts(player1, artifacts1)
    local validArtifacts2, reason2 = self:ValidateArtifacts(player2, artifacts2)
    
    if not validArtifacts1 then
        return nil, "Player 1 artifacts invalid: " .. reason1
    end
    
    if not validArtifacts2 then
        return nil, "Player 2 artifacts invalid: " .. reason2
    end
    
    -- Create trade
    local tradeId = HttpService:GenerateGUID()
    local tradeData = {
        id = tradeId,
        type = "ARTIFACT_TRADE",
        player1 = player1.UserId,
        player2 = player2.UserId,
        player1Name = player1.Name,
        player2Name = player2.Name,
        artifacts1 = artifacts1,
        artifacts2 = artifacts2,
        status = TRADE_STATUS.PENDING,
        createdAt = tick(),
        expiresAt = tick() + self.tradeTimeout,
        accepted1 = false,
        accepted2 = false,
        estimatedValue = self:CalculateArtifactTradeValue(artifacts1, artifacts2)
    }
    
    self.artifactTrades[tradeId] = tradeData
    
    -- Update metrics
    self:UpdateArtifactTradeMetrics(tradeData)
    
    -- Notify players
    self:NotifyArtifactTradeCreated(tradeData)
    
    print("TradingSystem: Created artifact trade " .. tradeId .. " between " .. player1.Name .. " and " .. player2.Name)
    return tradeId
end

-- Validate artifacts
function TradingSystem:ValidateArtifacts(player, artifacts)
    if not artifacts or #artifacts == 0 then
        return false, "No artifacts provided"
    end
    
    for _, artifact in ipairs(artifacts) do
        -- Check if artifact has required properties
        if not artifact.id or not artifact.type or not artifact.powerLevel then
            return false, "Invalid artifact format"
        end
        
        -- Check if artifact type is valid
        if not table.find(ARTIFACT_TYPES, artifact.type) then
            return false, "Invalid artifact type: " .. artifact.type
        end
        
        -- Check if player owns the artifact
        if not self:PlayerHasArtifact(player, artifact.id) then
            return false, "Player does not own artifact: " .. artifact.id
        end
    end
    
    return true
end

-- Check if player has artifact
function TradingSystem:PlayerHasArtifact(player, artifactId)
    -- This would integrate with the player's artifact collection
    -- For now, return true as placeholder
    return true
end

-- Calculate artifact trade value
function TradingSystem:CalculateArtifactTradeValue(artifacts1, artifacts2)
    local value1 = self:CalculateArtifactsValue(artifacts1)
    local value2 = self:CalculateArtifactsValue(artifacts2)
    
    return {
        player1Value = value1,
        player2Value = value2,
        difference = math.abs(value1 - value2),
        isBalanced = math.abs(value1 - value2) < 5000 -- Consider balanced if within 5000 points
    }
end

-- Calculate value of artifacts
function TradingSystem:CalculateArtifactsValue(artifacts)
    local totalValue = 0
    
    for _, artifact in ipairs(artifacts) do
        local baseValue = artifact.powerLevel * 1000
        local typeMultiplier = self:GetArtifactTypeMultiplier(artifact.type)
        local rarityMultiplier = self:GetArtifactRarityMultiplier(artifact.rarity or "COMMON")
        
        local artifactValue = math.floor(baseValue * typeMultiplier * rarityMultiplier)
        totalValue = totalValue + artifactValue
    end
    
    return totalValue
end

-- Get artifact type multiplier
function TradingSystem:GetArtifactTypeMultiplier(artifactType)
    local typeMultipliers = {
        POWER_SCALING = 1.5,
        CHARACTER_EVOLUTION = 2.0,
        WORLD_EVENT = 1.8,
        GUILD_WAR = 1.6,
        CROSSOVER_EVENT = 2.5,
        SEASONAL_CHALLENGE = 1.3,
        FUSION_BATTLE = 1.9,
        MENTORSHIP = 1.4,
        TRADING_CARD = 1.2,
        ANIME_MASTERY = 3.0
    }
    
    return typeMultipliers[artifactType] or 1.0
end

-- Get artifact rarity multiplier
function TradingSystem:GetArtifactRarityMultiplier(rarity)
    local rarityMultipliers = {
        COMMON = 1.0,
        UNCOMMON = 1.5,
        RARE = 2.5,
        EPIC = 4.0,
        LEGENDARY = 7.0,
        MYTHIC = 12.0
    }
    
    return rarityMultipliers[rarity] or 1.0
end

-- Create seasonal event item trade
function TradingSystem:CreateSeasonalItemTrade(player1, player2, items1, items2)
    if not player1 or not player2 then
        return nil, "Invalid players"
    end
    
    -- Validate item limits
    if #items1 > self.seasonalItemTradeLimit or #items2 > self.seasonalItemTradeLimit then
        return nil, "Exceeded maximum seasonal items per trade"
    end
    
    -- Validate items
    local validItems1, reason1 = self:ValidateSeasonalItems(player1, items1)
    local validItems2, reason2 = self:ValidateSeasonalItems(player2, items2)
    
    if not validItems1 then
        return nil, "Player 1 items invalid: " .. reason1
    end
    
    if not validItems2 then
        return nil, "Player 2 items invalid: " .. reason2
    end
    
    -- Create trade
    local tradeId = HttpService:GenerateGUID()
    local tradeData = {
        id = tradeId,
        type = "SEASONAL_ITEM_TRADE",
        player1 = player1.UserId,
        player2 = player2.UserId,
        player1Name = player1.Name,
        player2Name = player2.Name,
        items1 = items1,
        items2 = items2,
        status = TRADE_STATUS.PENDING,
        createdAt = tick(),
        expiresAt = tick() + self.tradeTimeout,
        accepted1 = false,
        accepted2 = false,
        estimatedValue = self:CalculateSeasonalItemTradeValue(items1, items2)
    }
    
    self.seasonalItemTrades[tradeId] = tradeData
    
    -- Update metrics
    self:UpdateSeasonalItemTradeMetrics(tradeData)
    
    -- Notify players
    self:NotifySeasonalItemTradeCreated(tradeData)
    
    print("TradingSystem: Created seasonal item trade " .. tradeId .. " between " .. player1.Name .. " and " .. player2.Name)
    return tradeId
end

-- Validate seasonal items
function TradingSystem:ValidateSeasonalItems(player, items)
    if not items or #items == 0 then
        return false, "No items provided"
    end
    
    for _, item in ipairs(items) do
        -- Check if item has required properties
        if not item.id or not item.eventType or not item.seasonalValue then
            return false, "Invalid seasonal item format"
        end
        
        -- Check if event type is valid
        if not table.find(SEASONAL_EVENT_TYPES, item.eventType) then
            return false, "Invalid event type: " .. item.eventType
        end
        
        -- Check if player owns the item
        if not self:PlayerHasSeasonalItem(player, item.id) then
            return false, "Player does not own item: " .. item.id
        end
    end
    
    return true
end

-- Check if player has seasonal item
function TradingSystem:PlayerHasSeasonalItem(player, itemId)
    -- This would integrate with the player's seasonal item collection
    -- For now, return true as placeholder
    return true
end

-- Calculate seasonal item trade value
function TradingSystem:CalculateSeasonalItemTradeValue(items1, items2)
    local value1 = self:CalculateSeasonalItemsValue(items1)
    local value2 = self:CalculateSeasonalItemsValue(items2)
    
    return {
        player1Value = value1,
        player2Value = value2,
        difference = math.abs(value1 - value2),
        isBalanced = math.abs(value1 - value2) < 2000 -- Consider balanced if within 2000 points
    }
end

-- Calculate value of seasonal items
function TradingSystem:CalculateSeasonalItemsValue(items)
    local totalValue = 0
    
    for _, item in ipairs(items) do
        local baseValue = item.seasonalValue * 100
        local eventMultiplier = self:GetSeasonalEventMultiplier(item.eventType)
        local seasonalBonus = self:GetCurrentSeasonalBonus(item.eventType)
        
        local itemValue = math.floor(baseValue * eventMultiplier * seasonalBonus)
        totalValue = totalValue + itemValue
    end
    
    return totalValue
end

-- Get seasonal event multiplier
function TradingSystem:GetSeasonalEventMultiplier(eventType)
    local eventMultipliers = {
        SPRING_FESTIVAL = 1.2,
        SUMMER_TOURNAMENT = 1.4,
        AUTUMN_COLLECTION = 1.3,
        WINTER_WARFARE = 1.5,
        NEW_YEAR_CELEBRATION = 2.0,
        HALLOWEEN_SPECIAL = 1.6,
        VALENTINE_DAY = 1.8,
        CHRISTMAS_EVENT = 1.9
    }
    
    return eventMultipliers[eventType] or 1.0
end

-- Get current seasonal bonus
function TradingSystem:GetCurrentSeasonalBonus(eventType)
    local currentMonth = os.date("*t").month
    
    local seasonalMonths = {
        SPRING_FESTIVAL = {3, 4, 5},
        SUMMER_TOURNAMENT = {6, 7, 8},
        AUTUMN_COLLECTION = {9, 10, 11},
        WINTER_WARFARE = {12, 1, 2},
        NEW_YEAR_CELEBRATION = {1},
        HALLOWEEN_SPECIAL = {10},
        VALENTINE_DAY = {2},
        CHRISTMAS_EVENT = {12}
    }
    
    local months = seasonalMonths[eventType]
    if months and table.find(months, currentMonth) then
        return 1.5 -- 50% bonus during relevant season
    end
    
    return 1.0
end

-- Create cross-anime collaboration trade
function TradingSystem:CreateCrossAnimeTrade(player1, player2, items1, items2)
    if not player1 or not player2 then
        return nil, "Invalid players"
    end
    
    -- Validate item limits
    if #items1 > self.crossAnimeTradeLimit or #items2 > self.crossAnimeTradeLimit then
        return nil, "Exceeded maximum cross-anime items per trade"
    end
    
    -- Validate items
    local validItems1, reason1 = self:ValidateCrossAnimeItems(player1, items1)
    local validItems2, reason2 = self:ValidateCrossAnimeItems(player2, items2)
    
    if not validItems1 then
        return nil, "Player 1 items invalid: " .. reason1
    end
    
    if not validItems2 then
        return nil, "Player 2 items invalid: " .. reason2
    end
    
    -- Create trade
    local tradeId = HttpService:GenerateGUID()
    local tradeData = {
        id = tradeId,
        type = "CROSS_ANIME_TRADE",
        player1 = player1.UserId,
        player2 = player2.UserId,
        player1Name = player1.Name,
        player2Name = player2.Name,
        items1 = items1,
        items2 = items2,
        status = TRADE_STATUS.PENDING,
        createdAt = tick(),
        expiresAt = tick() + self.tradeTimeout,
        accepted1 = false,
        accepted2 = false,
        estimatedValue = self:CalculateCrossAnimeTradeValue(items1, items2)
    }
    
    self.crossAnimeTrades[tradeId] = tradeData
    
    -- Update metrics
    self:UpdateCrossAnimeTradeMetrics(tradeData)
    
    -- Notify players
    self:NotifyCrossAnimeTradeCreated(tradeData)
    
    print("TradingSystem: Created cross-anime trade " .. tradeId .. " between " .. player1.Name .. " and " .. player2.Name)
    return tradeId
end

-- Validate cross-anime items
function TradingSystem:ValidateCrossAnimeItems(player, items)
    if not items or #items == 0 then
        return false, "No items provided"
    end
    
    for _, item in ipairs(items) do
        -- Check if item has required properties
        if not item.id or not item.collaborationType or not item.animeThemes then
            return false, "Invalid cross-anime item format"
        end
        
        -- Check if collaboration type is valid
        if not self:IsValidCollaborationType(item.collaborationType) then
            return false, "Invalid collaboration type: " .. item.collaborationType
        end
        
        -- Check if player owns the item
        if not self:PlayerHasCrossAnimeItem(player, item.id) then
            return false, "Player does not own item: " .. item.id
        end
    end
    
    return true
end

-- Check if collaboration type is valid
function TradingSystem:IsValidCollaborationType(collaborationType)
    local validTypes = {
        "FUSION_BATTLE", "CROSSOVER_EVENT", "THEME_COLLABORATION", "CHARACTER_CROSSOVER",
        "WORLD_MERGE", "POWER_COMBINATION", "STORY_INTEGRATION", "ARTIFACT_FUSION"
    }
    
    return table.find(validTypes, collaborationType) ~= nil
end

-- Check if player has cross-anime item
function TradingSystem:PlayerHasCrossAnimeItem(player, itemId)
    -- This would integrate with the player's cross-anime item collection
    -- For now, return true as placeholder
    return true
end

-- Calculate cross-anime trade value
function TradingSystem:CalculateCrossAnimeTradeValue(items1, items2)
    local value1 = self:CalculateCrossAnimeItemsValue(items1)
    local value2 = self:CalculateCrossAnimeItemsValue(items2)
    
    return {
        player1Value = value1,
        player2Value = value2,
        difference = math.abs(value1 - value2),
        isBalanced = math.abs(value1 - value2) < 3000 -- Consider balanced if within 3000 points
    }
end

-- Calculate value of cross-anime items
function TradingSystem:CalculateCrossAnimeItemsValue(items)
    local totalValue = 0
    
    for _, item in ipairs(items) do
        local baseValue = item.collaborationValue or 1000
        local collaborationMultiplier = self:GetCollaborationTypeMultiplier(item.collaborationType)
        local themeBonus = self:GetCrossAnimeThemeBonus(item.animeThemes)
        
        local itemValue = math.floor(baseValue * collaborationMultiplier * themeBonus)
        totalValue = totalValue + itemValue
    end
    
    return totalValue
end

-- Get collaboration type multiplier
function TradingSystem:GetCollaborationTypeMultiplier(collaborationType)
    local collaborationMultipliers = {
        FUSION_BATTLE = 2.0,
        CROSSOVER_EVENT = 2.5,
        THEME_COLLABORATION = 1.8,
        CHARACTER_CROSSOVER = 2.2,
        WORLD_MERGE = 3.0,
        POWER_COMBINATION = 2.8,
        STORY_INTEGRATION = 2.3,
        ARTIFACT_FUSION = 2.7
    }
    
    return collaborationMultipliers[collaborationType] or 1.0
end

-- Get cross-anime theme bonus
function TradingSystem:GetCrossAnimeThemeBonus(animeThemes)
    if not animeThemes or #animeThemes < 2 then
        return 1.0
    end
    
    -- More themes = higher bonus
    local themeCount = #animeThemes
    local baseBonus = 1.0 + (themeCount * 0.2)
    
    -- Check for special theme combinations
    local specialCombinations = {
        ["NARUTO_DRAGON_BALL"] = 1.5,
        ["ONE_PIECE_ATTACK_ON_TITAN"] = 1.6,
        ["MY_HERO_ACADEMIA_DEMON_SLAYER"] = 1.7,
        ["JUJUTSU_KAISEN_HUNTER_X_HUNTER"] = 1.4
    }
    
    -- Check if any special combination exists
    for combination, bonus in pairs(specialCombinations) do
        local themes = {}
        -- Split the combination key by underscore
        for theme in combination:gmatch("[^_]+") do
            table.insert(themes, theme)
        end
        
        local hasCombination = true
        for _, theme in ipairs(themes) do
            if not table.find(animeThemes, theme) then
                hasCombination = false
                break
            end
        end
        
        if hasCombination then
            return baseBonus * bonus
        end
    end
    
    return baseBonus
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

-- Anime-specific notification functions

-- Notify anime card trade created
function TradingSystem:NotifyAnimeCardTradeCreated(tradeData)
    local player1 = Players:GetPlayerByUserId(tradeData.player1)
    local player2 = Players:GetPlayerByUserId(tradeData.player2)
    
    local notificationData = {
        tradeId = tradeData.id,
        type = tradeData.type,
        partner = tradeData.player2Name,
        cards1 = tradeData.cards1,
        cards2 = tradeData.cards2,
        estimatedValue = tradeData.estimatedValue,
        status = tradeData.status
    }
    
    if player1 then
        self.networkManager:SendToClient(player1, RemoteEvents.AnimeCardTrade, notificationData)
    end
    
    if player2 then
        notificationData.partner = tradeData.player1Name
        self.networkManager:SendToClient(player2, RemoteEvents.AnimeCardTrade, notificationData)
    end
end

-- Notify artifact trade created
function TradingSystem:NotifyArtifactTradeCreated(tradeData)
    local player1 = Players:GetPlayerByUserId(tradeData.player1)
    local player2 = Players:GetPlayerByUserId(tradeData.player2)
    
    local notificationData = {
        tradeId = tradeData.id,
        type = tradeData.type,
        partner = tradeData.player2Name,
        artifacts1 = tradeData.artifacts1,
        artifacts2 = tradeData.artifacts2,
        estimatedValue = tradeData.estimatedValue,
        status = tradeData.status
    }
    
    if player1 then
        self.networkManager:SendToClient(player1, RemoteEvents.ArtifactTrade, notificationData)
    end
    
    if player2 then
        notificationData.partner = tradeData.player1Name
        self.networkManager:SendToClient(player2, RemoteEvents.ArtifactTrade, notificationData)
    end
end

-- Notify seasonal item trade created
function TradingSystem:NotifySeasonalItemTradeCreated(tradeData)
    local player1 = Players:GetPlayerByUserId(tradeData.player1)
    local player2 = Players:GetPlayerByUserId(tradeData.player2)
    
    local notificationData = {
        tradeId = tradeData.id,
        type = tradeData.type,
        partner = tradeData.player2Name,
        items1 = tradeData.items1,
        items2 = tradeData.items2,
        estimatedValue = tradeData.estimatedValue,
        status = tradeData.status
    }
    
    if player1 then
        self.networkManager:SendToClient(player1, RemoteEvents.SeasonalItemTrade, notificationData)
    end
    
    if player2 then
        notificationData.partner = tradeData.player1Name
        self.networkManager:SendToClient(player2, RemoteEvents.SeasonalItemTrade, notificationData)
    end
end

-- Notify cross-anime trade created
function TradingSystem:NotifyCrossAnimeTradeCreated(tradeData)
    local player1 = Players:GetPlayerByUserId(tradeData.player1)
    local player2 = Players:GetPlayerByUserId(tradeData.player2)
    
    local notificationData = {
        tradeId = tradeData.id,
        type = tradeData.type,
        partner = tradeData.player2Name,
        items1 = tradeData.items1,
        items2 = tradeData.items2,
        estimatedValue = tradeData.estimatedValue,
        status = tradeData.status
    }
    
    if player1 then
        self.networkManager:SendToClient(player1, RemoteEvents.CrossAnimeTrade, notificationData)
    end
    
    if player2 then
        notificationData.partner = tradeData.player1Name
        self.networkManager:SendToClient(player2, RemoteEvents.CrossAnimeTrade, notificationData)
    end
end

-- Anime trading metrics update functions

-- Update anime card trade metrics
function TradingSystem:UpdateAnimeCardTradeMetrics(tradeData)
    local metrics = self.animeTradingMetrics.characterCards
    
    metrics.totalTrades = metrics.totalTrades + 1
    metrics.totalVolume = metrics.totalVolume + #tradeData.cards1 + #tradeData.cards2
    
    -- Update rarity distribution
    for _, card in ipairs(tradeData.cards1) do
        if metrics.rarityDistribution[card.rarity] then
            metrics.rarityDistribution[card.rarity] = metrics.rarityDistribution[card.rarity] + 1
        end
    end
    
    for _, card in ipairs(tradeData.cards2) do
        if metrics.rarityDistribution[card.rarity] then
            metrics.rarityDistribution[card.rarity] = metrics.rarityDistribution[card.rarity] + 1
        end
    end
    
    -- Update theme distribution
    for _, card in ipairs(tradeData.cards1) do
        if metrics.themeDistribution[card.theme] then
            metrics.themeDistribution[card.theme] = metrics.themeDistribution[card.theme] + 1
        end
    end
    
    for _, card in ipairs(tradeData.cards2) do
        if metrics.themeDistribution[card.theme] then
            metrics.themeDistribution[card.theme] = metrics.themeDistribution[card.theme] + 1
        end
    end
    
    -- Update price history
    local tradeValue = tradeData.estimatedValue.player1Value + tradeData.estimatedValue.player2Value
    table.insert(metrics.priceHistory, {
        value = tradeValue,
        timestamp = tick(),
        cardCount = #tradeData.cards1 + #tradeData.cards2
    })
    
    -- Keep only last 100 price points
    if #metrics.priceHistory > 100 then
        table.remove(metrics.priceHistory, 1)
    end
    
    -- Update average price
    if metrics.totalVolume > 0 then
        metrics.averagePrice = (metrics.averagePrice * (metrics.totalVolume - #tradeData.cards1 - #tradeData.cards2) + tradeValue) / metrics.totalVolume
    end
end

-- Update artifact trade metrics
function TradingSystem:UpdateArtifactTradeMetrics(tradeData)
    local metrics = self.animeTradingMetrics.artifacts
    
    metrics.totalTrades = metrics.totalTrades + 1
    metrics.totalVolume = metrics.totalVolume + #tradeData.artifacts1 + #tradeData.artifacts2
    
    -- Update type distribution
    for _, artifact in ipairs(tradeData.artifacts1) do
        if metrics.typeDistribution[artifact.type] then
            metrics.typeDistribution[artifact.type] = metrics.typeDistribution[artifact.type] + 1
        end
    end
    
    for _, artifact in ipairs(tradeData.artifacts2) do
        if metrics.typeDistribution[artifact.type] then
            metrics.typeDistribution[artifact.type] = metrics.typeDistribution[artifact.type] + 1
        end
    end
    
    -- Update price history
    local tradeValue = tradeData.estimatedValue.player1Value + tradeData.estimatedValue.player2Value
    table.insert(metrics.priceHistory, {
        value = tradeValue,
        timestamp = tick(),
        artifactCount = #tradeData.artifacts1 + #tradeData.artifacts2
    })
    
    -- Keep only last 100 price points
    if #metrics.priceHistory > 100 then
        table.remove(metrics.priceHistory, 1)
    end
    
    -- Update average price
    if metrics.totalVolume > 0 then
        metrics.averagePrice = (metrics.averagePrice * (metrics.totalVolume - #tradeData.artifacts1 - #tradeData.artifacts2) + tradeValue) / metrics.totalVolume
    end
end

-- Update seasonal item trade metrics
function TradingSystem:UpdateSeasonalItemTradeMetrics(tradeData)
    local metrics = self.animeTradingMetrics.seasonalItems
    
    metrics.totalTrades = metrics.totalTrades + 1
    metrics.totalVolume = metrics.totalVolume + #tradeData.items1 + #tradeData.items2
    
    -- Update event type distribution
    for _, item in ipairs(tradeData.items1) do
        if metrics.eventTypeDistribution[item.eventType] then
            metrics.eventTypeDistribution[item.eventType] = metrics.eventTypeDistribution[item.eventType] + 1
        end
    end
    
    for _, item in ipairs(tradeData.items2) do
        if metrics.eventTypeDistribution[item.eventType] then
            metrics.eventTypeDistribution[item.eventType] = metrics.eventTypeDistribution[item.eventType] + 1
        end
    end
    
    -- Update price history
    local tradeValue = tradeData.estimatedValue.player1Value + tradeData.estimatedValue.player2Value
    table.insert(metrics.priceHistory, {
        value = tradeValue,
        timestamp = tick(),
        itemCount = #tradeData.items1 + #tradeData.items2
    })
    
    -- Keep only last 100 price points
    if #metrics.priceHistory > 100 then
        table.remove(metrics.priceHistory, 1)
    end
    
    -- Update average price
    if metrics.totalVolume > 0 then
        metrics.averagePrice = (metrics.averagePrice * (metrics.totalVolume - #tradeData.items1 - #tradeData.items2) + tradeValue) / metrics.totalVolume
    end
end

-- Update cross-anime trade metrics
function TradingSystem:UpdateCrossAnimeTradeMetrics(tradeData)
    local metrics = self.animeTradingMetrics.crossAnimeItems
    
    metrics.totalTrades = metrics.totalTrades + 1
    metrics.totalVolume = metrics.totalVolume + #tradeData.items1 + #tradeData.items2
    
    -- Update collaboration types
    for _, item in ipairs(tradeData.items1) do
        if not metrics.collaborationTypes[item.collaborationType] then
            metrics.collaborationTypes[item.collaborationType] = 0
        end
        metrics.collaborationTypes[item.collaborationType] = metrics.collaborationTypes[item.collaborationType] + 1
    end
    
    for _, item in ipairs(tradeData.items2) do
        if not metrics.collaborationTypes[item.collaborationType] then
            metrics.collaborationTypes[item.collaborationType] = 0
        end
        metrics.collaborationTypes[item.collaborationType] = metrics.collaborationTypes[item.collaborationType] + 1
    end
    
    -- Update price history
    local tradeValue = tradeData.estimatedValue.player1Value + tradeData.estimatedValue.player2Value
    table.insert(metrics.priceHistory, {
        value = tradeValue,
        timestamp = tick(),
        itemCount = #tradeData.items1 + #tradeData.items2
    })
    
    -- Keep only last 100 price points
    if #metrics.priceHistory > 100 then
        table.remove(metrics.priceHistory, 1)
    end
    
    -- Update average price
    if metrics.totalVolume > 0 then
        metrics.averagePrice = (metrics.averagePrice * (metrics.totalVolume - #tradeData.items1 - #tradeData.items2) + tradeValue) / metrics.totalVolume
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

-- Enhanced Anime Trading Public API

-- Get anime character card trades
function TradingSystem:GetAnimeCardTrades(player)
    local userId = player.UserId
    local playerTrades = {}
    
    for tradeId, tradeData in pairs(self.animeCardTrades) do
        if tradeData.player1 == userId or tradeData.player2 == userId then
            table.insert(playerTrades, tradeData)
        end
    end
    
    return playerTrades
end

-- Get artifact trades
function TradingSystem:GetArtifactTrades(player)
    local userId = player.UserId
    local playerTrades = {}
    
    for tradeId, tradeData in pairs(self.artifactTrades) do
        if tradeData.player1 == userId or tradeData.player2 == userId then
            table.insert(playerTrades, tradeData)
        end
    end
    
    return playerTrades
end

-- Get seasonal item trades
function TradingSystem:GetSeasonalItemTrades(player)
    local userId = player.UserId
    local playerTrades = {}
    
    for tradeId, tradeData in pairs(self.seasonalItemTrades) do
        if tradeData.player1 == userId or tradeData.player2 == userId then
            table.insert(playerTrades, tradeData)
        end
    end
    
    return playerTrades
end

-- Get cross-anime trades
function TradingSystem:GetCrossAnimeTrades(player)
    local userId = player.UserId
    local playerTrades = {}
    
    for tradeId, tradeData in pairs(self.crossAnimeTrades) do
        if tradeData.player1 == userId or tradeData.player2 == userId then
            table.insert(playerTrades, tradeData)
        end
    end
    
    return playerTrades
end

-- Get anime trading metrics
function TradingSystem:GetAnimeTradingMetrics()
    return {
        characterCards = self.animeTradingMetrics.characterCards,
        artifacts = self.animeTradingMetrics.artifacts,
        seasonalItems = self.animeTradingMetrics.seasonalItems,
        crossAnimeItems = self.animeTradingMetrics.crossAnimeItems
    }
end

-- Get anime card rarity information
function TradingSystem:GetAnimeCardRarities()
    return ANIME_CARD_RARITIES
end

-- Get anime themes
function TradingSystem:GetAnimeThemes()
    return ANIME_THEMES
end

-- Get artifact types
function TradingSystem:GetArtifactTypes()
    return ARTIFACT_TYPES
end

-- Get seasonal event types
function TradingSystem:GetSeasonalEventTypes()
    return SEASONAL_EVENT_TYPES
end

-- Get anime trading limits
function TradingSystem:GetAnimeTradingLimits()
    return {
        animeCardTradeLimit = self.animeCardTradeLimit,
        artifactTradeLimit = self.artifactTradeLimit,
        seasonalItemTradeLimit = self.seasonalItemTradeLimit,
        crossAnimeTradeLimit = self.crossAnimeTradeLimit
    }
end

-- Get anime theme bonus for trading
function TradingSystem:GetAnimeThemeBonus(theme)
    return self:GetAnimeThemeBonus(theme)
end

-- Get current seasonal bonus
function TradingSystem:GetCurrentSeasonalBonus(eventType)
    return self:GetCurrentSeasonalBonus(eventType)
end

-- Get collaboration type multiplier
function TradingSystem:GetCollaborationTypeMultiplier(collaborationType)
    return self:GetCollaborationTypeMultiplier(collaborationType)
end

-- Get cross-anime theme bonus
function TradingSystem:GetCrossAnimeThemeBonus(animeThemes)
    return self:GetCrossAnimeThemeBonus(animeThemes)
end

-- Get anime trading statistics
function TradingSystem:GetAnimeTradingStatistics()
    local stats = {
        totalAnimeCardTrades = 0,
        totalArtifactTrades = 0,
        totalSeasonalItemTrades = 0,
        totalCrossAnimeTrades = 0,
        totalAnimeTradeVolume = 0,
        averageAnimeTradeValue = 0,
        mostTradedAnimeTheme = nil,
        mostTradedArtifactType = nil,
        mostTradedSeasonalEvent = nil,
        mostTradedCollaborationType = nil
    }
    
    -- Count trades
    for _ in pairs(self.animeCardTrades) do
        stats.totalAnimeCardTrades = stats.totalAnimeCardTrades + 1
    end
    
    for _ in pairs(self.artifactTrades) do
        stats.totalArtifactTrades = stats.totalArtifactTrades + 1
    end
    
    for _ in pairs(self.seasonalItemTrades) do
        stats.totalSeasonalItemTrades = stats.totalSeasonalItemTrades + 1
    end
    
    for _ in pairs(self.crossAnimeTrades) do
        stats.totalCrossAnimeTrades = stats.totalCrossAnimeTrades + 1
    end
    
    -- Calculate total volume and average value
    local totalVolume = 0
    local totalValue = 0
    local tradeCount = 0
    
    for _, metrics in pairs(self.animeTradingMetrics) do
        if metrics.totalVolume then
            totalVolume = totalVolume + metrics.totalVolume
        end
        if metrics.averagePrice then
            totalValue = totalValue + (metrics.averagePrice * (metrics.totalVolume or 0))
            tradeCount = tradeCount + (metrics.totalVolume or 0)
        end
    end
    
    stats.totalAnimeTradeVolume = totalVolume
    stats.averageAnimeTradeValue = tradeCount > 0 and totalValue / tradeCount or 0
    
    -- Find most traded items
    local maxThemeCount = 0
    for theme, count in pairs(self.animeTradingMetrics.characterCards.themeDistribution) do
        if count > maxThemeCount then
            maxThemeCount = count
            stats.mostTradedAnimeTheme = theme
        end
    end
    
    local maxArtifactCount = 0
    for artifactType, count in pairs(self.animeTradingMetrics.artifacts.typeDistribution) do
        if count > maxArtifactCount then
            maxArtifactCount = count
            stats.mostTradedArtifactType = artifactType
        end
    end
    
    local maxSeasonalCount = 0
    for eventType, count in pairs(self.animeTradingMetrics.seasonalItems.eventTypeDistribution) do
        if count > maxSeasonalCount then
            maxSeasonalCount = count
            stats.mostTradedSeasonalEvent = eventType
        end
    end
    
    local maxCollaborationCount = 0
    for collaborationType, count in pairs(self.animeTradingMetrics.crossAnimeItems.collaborationTypes) do
        if count > maxCollaborationCount then
            maxCollaborationCount = count
            stats.mostTradedCollaborationType = collaborationType
        end
    end
    
    return stats
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
        escrowStatus = {},
        -- Anime trading metrics
        animeTradingMetrics = self.animeTradingMetrics,
        animeTradingStatistics = self:GetAnimeTradingStatistics()
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
    for escrowId, escrow in pairs(self.escrowSystem) do
        metrics.escrowStatus[escrowId] = {
            status = escrow.status,
            value = escrow.totalValue or 0,
            timeActive = tick() - escrow.createdAt
        }
    end
    
    return metrics
end

return TradingSystem

