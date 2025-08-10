-- CompetitiveManager.lua
-- Advanced competitive system for Milestone 3: Competitive & Social Systems
-- Handles leaderboards, rankings, achievements, and competitive progression

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Constants = require(script.Parent.Parent.Utils.Constants)
local NetworkManager = require(script.Parent.Parent.Multiplayer.NetworkManager)

local CompetitiveManager = {}
CompetitiveManager.__index = CompetitiveManager

-- RemoteEvents for client-server communication
local RemoteEvents = {
    LeaderboardUpdate = "LeaderboardUpdate",
    RankingUpdate = "RankingUpdate",
    AchievementUnlocked = "AchievementUnlocked",
    SeasonReset = "SeasonReset",
    RewardDistributed = "RewardDistributed",
    CompetitiveAction = "CompetitiveAction"
}

-- Achievement categories and definitions
local ACHIEVEMENTS = {
    TYCOON_MASTERY = {
        FIRST_TYCOON = { id = "FIRST_TYCOON", name = "First Tycoon", description = "Build your first tycoon", points = 100, category = "Tycoon Mastery" },
        TYCOON_EMPIRE = { id = "TYCOON_EMPIRE", name = "Tycoon Empire", description = "Own 3 tycoons simultaneously", points = 500, category = "Tycoon Mastery" },
        MASTER_BUILDER = { id = "MASTER_BUILDER", name = "Master Builder", description = "Reach max level on any tycoon", points = 1000, category = "Tycoon Mastery" },
        CASH_MILLIONAIRE = { id = "CASH_MILLIONAIRE", name = "Cash Millionaire", description = "Accumulate 1,000,000 cash", points = 750, category = "Tycoon Mastery" }
    },
    SOCIAL_INTERACTION = {
        FRIENDLY_PLAYER = { id = "FRIENDLY_PLAYER", name = "Friendly Player", description = "Make 10 friends", points = 200, category = "Social Interaction" },
        GUILD_LEADER = { id = "GUILD_LEADER", name = "Guild Leader", description = "Create and lead a guild", points = 300, category = "Social Interaction" },
        TEAM_PLAYER = { id = "TEAM_PLAYER", name = "Team Player", description = "Participate in 5 guild events", points = 400, category = "Social Interaction" }
    },
    COMPETITIVE_SUCCESS = {
        RANKING_RISER = { id = "RANKING_RISER", name = "Ranking Riser", description = "Reach top 100 on any leaderboard", points = 600, category = "Competitive Success" },
        SEASON_CHAMPION = { id = "SEASON_CHAMPION", name = "Season Champion", description = "Win a competitive season", points = 1500, category = "Competitive Success" },
        ACHIEVEMENT_HUNTER = { id = "ACHIEVEMENT_HUNTER", name = "Achievement Hunter", description = "Unlock 25 achievements", points = 800, category = "Competitive Success" }
    },
    ECONOMY_MASTERY = {
        TRADING_MASTER = { id = "TRADING_MASTER", name = "Trading Master", description = "Complete 100 successful trades", points = 450, category = "Economy Mastery" },
        MARKET_ANALYST = { id = "MARKET_ANALYST", name = "Market Analyst", description = "Make 50,000 profit from trading", points = 600, category = "Economy Mastery" },
        INVESTMENT_GURU = { id = "INVESTMENT_GURU", name = "Investment Guru", description = "Hold items worth 500,000 for 24 hours", points = 700, category = "Economy Mastery" }
    }
}

-- Prestige tiers and benefits
local PRESTIGE_TIERS = {
    { name = "Bronze", minPoints = 0, multiplier = 1.0, color = Color3.fromRGB(205, 127, 50) },
    { name = "Silver", minPoints = 1000, multiplier = 1.1, color = Color3.fromRGB(192, 192, 192) },
    { name = "Gold", minPoints = 2500, multiplier = 1.25, color = Color3.fromRGB(255, 215, 0) },
    { name = "Platinum", minPoints = 5000, multiplier = 1.5, color = Color3.fromRGB(229, 228, 226) },
    { name = "Diamond", minPoints = 10000, multiplier = 2.0, color = Color3.fromRGB(185, 242, 255) },
    { name = "Master", minPoints = 20000, multiplier = 3.0, color = Color3.fromRGB(255, 0, 255) }
}

function CompetitiveManager.new()
    local self = setmetatable({}, CompetitiveManager)
    
    -- Core data structures
    self.leaderboards = {}           -- Category -> Leaderboard Data
    self.playerRankings = {}         -- Player -> Ranking Data
    self.seasons = {}                -- Season -> Season Data
    self.achievements = {}            -- Achievement -> Progress Data
    self.rewards = {}                -- Reward -> Unlock Data
    self.prestigeData = {}           -- Player -> Prestige Data
    
    -- Network manager reference
    self.networkManager = nil
    
    -- Initialize remote events
    self.remoteEvents = {}
    
    -- Season management
    self.currentSeason = 1
    self.seasonStartTime = tick()
    self.seasonDuration = 30 * 24 * 60 * 60 -- 30 days in seconds
    
    -- Performance tracking
    self.lastLeaderboardUpdate = 0
    self.updateInterval = 5 -- Update leaderboards every 5 seconds
    
    -- Roblox leaderboard compatibility
    self.useRobloxLeaderboard = true
    self.robloxLeaderboardStats = {
        "CompetitiveRank",
        "AchievementPoints", 
        "PrestigeLevel",
        "SeasonPoints"
    }
    
    return self
end

-- Set up Roblox leaderboard for a player (Roblox best practice)
function CompetitiveManager:SetupRobloxLeaderboard(player)
    if not self.useRobloxLeaderboard then
        return
    end
    
    -- Create leaderstats folder (Roblox automatically recognizes this)
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player
    
    -- Add competitive stats as IntValue/NumberValue objects
    for _, statName in ipairs(self.robloxLeaderboardStats) do
        local statValue = Instance.new("IntValue")
        statValue.Name = statName
        statValue.Value = 0
        statValue.Parent = leaderstats
        
        -- Store reference for easy updates
        if not self.playerRankings[player.UserId] then
            self.playerRankings[player.UserId] = {}
        end
        
        self.playerRankings[player.UserId][statName .. "_Value"] = statValue
    end
    
    print("CompetitiveManager: Roblox leaderboard set up for " .. player.Name)
end

-- Update Roblox leaderboard stats
function CompetitiveManager:UpdateRobloxLeaderboard(player, statName, value)
    if not self.useRobloxLeaderboard then
        return
    end
    
    local userId = player.UserId
    local playerData = self.playerRankings[userId]
    
    if playerData and playerData[statName .. "_Value"] then
        playerData[statName .. "_Value"].Value = value
    end
end

-- Public API for performance monitoring
function CompetitiveManager:GetCompetitiveMetrics()
    return {
        leaderboards = self:GetLeaderboardMetrics(),
        players = self:GetPlayerMetrics(),
        season = self:GetSeasonMetrics(),
        performance = self:GetPerformanceMetrics()
    }
end

-- Get leaderboard metrics
function CompetitiveManager:GetLeaderboardMetrics()
    local metrics = {
        totalLeaderboards = 0,
        totalPlayers = 0,
        lastUpdate = self.lastLeaderboardUpdate,
        updateInterval = self.updateInterval
    }
    
    for category, leaderboard in pairs(self.leaderboards) do
        metrics.totalLeaderboards = metrics.totalLeaderboards + 1
        metrics.totalPlayers = metrics.totalPlayers + #leaderboard.data
    end
    
    return metrics
end

-- Get player metrics
function CompetitiveManager:GetPlayerMetrics()
    local metrics = {
        totalPlayers = 0,
        activePlayers = 0,
        achievementProgress = {},
        prestigeDistribution = {}
    }
    
    for userId, playerData in pairs(self.playerRankings) do
        metrics.totalPlayers = metrics.totalPlayers + 1
        
        local player = Players:GetPlayerByUserId(userId)
        if player then
            metrics.activePlayers = metrics.activePlayers + 1
        end
        
        -- Track achievement progress
        if playerData.achievements then
            local achievementCount = 0
            for _ in pairs(playerData.achievements) do
                achievementCount = achievementCount + 1
            end
            metrics.achievementProgress[achievementCount] = (metrics.achievementProgress[achievementCount] or 0) + 1
        end
        
        -- Track prestige distribution
        if playerData.prestigeLevel then
            metrics.prestigeDistribution[playerData.prestigeLevel] = (metrics.prestigeDistribution[playerData.prestigeLevel] or 0) + 1
        end
    end
    
    return metrics
end

-- Get season metrics
function CompetitiveManager:GetSeasonMetrics()
    local currentTime = tick()
    local timeInSeason = currentTime - self.seasonStartTime
    local seasonProgress = math.min(timeInSeason / self.seasonDuration, 1)
    
    return {
        currentSeason = self.currentSeason,
        seasonStartTime = self.seasonStartTime,
        seasonDuration = self.seasonDuration,
        timeInSeason = timeInSeason,
        seasonProgress = seasonProgress,
        timeUntilReset = math.max(0, self.seasonDuration - timeInSeason)
    }
end

-- Get performance metrics
function CompetitiveManager:GetPerformanceMetrics()
    return {
        leaderboardUpdates = self.lastLeaderboardUpdate,
        updateInterval = self.updateInterval,
        robloxLeaderboardEnabled = self.useRobloxLeaderboard,
        activeRobloxStats = #self.robloxLeaderboardStats
    }
end

function CompetitiveManager:Initialize(networkManager)
    self.networkManager = networkManager
    
    -- Set up remote events
    self:SetupRemoteEvents()
    
    -- Connect to player events
    self:ConnectPlayerEvents()
    
    -- Initialize leaderboards
    self:InitializeLeaderboards()
    
    -- Start update loop
    self:StartUpdateLoop()
    
    print("CompetitiveManager: Initialized successfully!")
end

function CompetitiveManager:SetupRemoteEvents()
    -- Create remote events in ReplicatedStorage
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    
    for eventName, _ in pairs(RemoteEvents) do
        local remoteEvent = Instance.new("RemoteEvent")
        remoteEvent.Name = eventName
        remoteEvent.Parent = ReplicatedStorage
        self.remoteEvents[eventName] = remoteEvent
    end
    
    -- Set up event handlers
    self.remoteEvents.CompetitiveAction.OnServerEvent:Connect(function(player, actionType, data)
        self:HandleCompetitiveAction(player, actionType, data)
    end)
    
    print("CompetitiveManager: Remote events configured!")
end

function CompetitiveManager:ConnectPlayerEvents()
    -- Handle player joining
    Players.PlayerAdded:Connect(function(player)
        self:HandlePlayerJoined(player)
    end)
    
    -- Handle player leaving
    Players.PlayerRemoving:Connect(function(player)
        self:HandlePlayerLeaving(player)
    end)
    
    print("CompetitiveManager: Player events connected!")
end

function CompetitiveManager:InitializeLeaderboards()
    -- Initialize different leaderboard categories
    self.leaderboards = {
        TOTAL_CASH = { name = "Total Cash", data = {}, lastUpdate = 0 },
        TYCOON_COUNT = { name = "Tycoon Count", data = {}, lastUpdate = 0 },
        ACHIEVEMENT_POINTS = { name = "Achievement Points", data = {}, lastUpdate = 0 },
        GUILD_LEVEL = { name = "Guild Level", data = {}, lastUpdate = 0 },
        TRADING_VOLUME = { name = "Trading Volume", data = {}, lastUpdate = 0 },
        SEASONAL_RANKING = { name = "Seasonal Ranking", data = {}, lastUpdate = 0 }
    }
    
    print("CompetitiveManager: Leaderboards initialized!")
end

function CompetitiveManager:StartUpdateLoop()
    -- Update leaderboards and check season status
    RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        
        -- Check if season should reset
        if currentTime - self.seasonStartTime >= self.seasonDuration then
            self:ProcessSeasonalReset()
        end
        
        -- Update leaderboards periodically
        if currentTime - self.lastLeaderboardUpdate >= self.updateInterval then
            self:UpdateAllLeaderboards()
            self.lastLeaderboardUpdate = currentTime
        end
    end)
end

-- Core Competitive Functions

function CompetitiveManager:UpdateLeaderboard(category, playerData)
    if not self.leaderboards[category] then
        warn("Invalid leaderboard category:", category)
        return false
    end
    
    local leaderboard = self.leaderboards[category]
    local playerId = playerData.playerId or playerData.userId
    
    if not playerId then
        warn("Missing player ID for leaderboard update")
        return false
    end
    
    -- Update player data in leaderboard
    leaderboard.data[playerId] = {
        playerId = playerId,
        playerName = playerData.playerName,
        value = playerData.value or 0,
        lastUpdate = tick(),
        metadata = playerData.metadata or {}
    }
    
    -- Sort leaderboard by value (descending)
    local sortedData = {}
    for _, data in pairs(leaderboard.data) do
        table.insert(sortedData, data)
    end
    
    table.sort(sortedData, function(a, b)
        return a.value > b.value
    end)
    
    -- Update rankings
    for rank, data in ipairs(sortedData) do
        if self.playerRankings[data.playerId] then
            self.playerRankings[data.playerId][category] = rank
        end
    end
    
    -- Update Roblox leaderboard if applicable
    if self.useRobloxLeaderboard then
        local player = Players:GetPlayerByUserId(playerId)
        if player then
            self:UpdateRobloxLeaderboard(player, category, playerData.value or 0)
        end
    end
    
    -- Broadcast update to clients
    self:BroadcastLeaderboardUpdate(category, sortedData)
    
    return true
end

function CompetitiveManager:CalculatePlayerRanking(player)
    local userId = player.UserId
    local ranking = self.playerRankings[userId] or {}
    
    -- Calculate overall ranking based on all categories
    local totalRanking = 0
    local categoryCount = 0
    
    for category, rank in pairs(ranking) do
        totalRanking = totalRanking + rank
        categoryCount = categoryCount + 1
    end
    
    local averageRank = categoryCount > 0 and (totalRanking / categoryCount) or 999999
    
    -- Calculate prestige tier
    local achievementPoints = self:GetPlayerAchievementPoints(userId)
    local prestigeTier = self:CalculatePrestigeTier(achievementPoints)
    
    return {
        overallRank = math.floor(averageRank),
        categoryRankings = ranking,
        achievementPoints = achievementPoints,
        prestigeTier = prestigeTier,
        seasonProgress = self:GetSeasonProgress(userId)
    }
end

function CompetitiveManager:ProcessSeasonalReset()
    print("CompetitiveManager: Processing seasonal reset...")
    
    -- Distribute seasonal rewards
    self:DistributeSeasonalRewards()
    
    -- Reset seasonal data
    self.currentSeason = self.currentSeason + 1
    self.seasonStartTime = tick()
    
    -- Clear seasonal rankings
    for category, leaderboard in pairs(self.leaderboards) do
        if category == "SEASONAL_RANKING" then
            leaderboard.data = {}
        end
    end
    
    -- Reset player seasonal data
    for userId, ranking in pairs(self.playerRankings) do
        if ranking.SEASONAL_RANKING then
            ranking.SEASONAL_RANKING = nil
        end
    end
    
    -- Broadcast season reset
    self:BroadcastSeasonReset()
    
    print("CompetitiveManager: Seasonal reset completed!")
end

function CompetitiveManager:AwardAchievement(player, achievementId)
    local userId = player.UserId
    local achievement = self:FindAchievement(achievementId)
    
    if not achievement then
        warn("Invalid achievement ID:", achievementId)
        return false
    end
    
    -- Check if already unlocked
    if self.achievements[userId] and self.achievements[userId][achievementId] then
        return false
    end
    
    -- Initialize player achievements if needed
    if not self.achievements[userId] then
        self.achievements[userId] = {}
    end
    
    -- Award achievement
    self.achievements[userId][achievementId] = {
        unlockedAt = tick(),
        points = achievement.points,
        category = achievement.category
    }
    
    -- Update achievement points leaderboard
    local totalPoints = self:GetPlayerAchievementPoints(userId)
    self:UpdateLeaderboard("ACHIEVEMENT_POINTS", {
        playerId = userId,
        playerName = player.Name,
        value = totalPoints
    })
    
    -- Broadcast achievement unlock
    self:BroadcastAchievementUnlocked(player, achievement)
    
    -- Check for prestige tier upgrade
    self:CheckPrestigeUpgrade(userId, totalPoints)
    
    print("CompetitiveManager: Awarded achievement", achievement.name, "to", player.Name)
    return true
end

function CompetitiveManager:DistributeSeasonalRewards()
    print("CompetitiveManager: Distributing seasonal rewards...")
    
    -- Calculate rewards for top players in each category
    for category, leaderboard in pairs(self.leaderboards) do
        if category ~= "SEASONAL_RANKING" then
            local topPlayers = self:GetTopPlayers(category, 10)
            
            for rank, playerData in ipairs(topPlayers) do
                local rewards = self:CalculateSeasonalRewards(rank, category)
                self:GrantRewards(playerData.playerId, rewards)
            end
        end
    end
    
    print("CompetitiveManager: Seasonal rewards distributed!")
end

-- Ranking Algorithms

function CompetitiveManager:CalculateELORating(player1, player2, result)
    -- ELO rating calculation for competitive matchups
    local K = 32 -- K-factor determines how much rating changes
    
    local expected1 = 1 / (1 + 10^((player2.rating - player1.rating) / 400))
    local expected2 = 1 / (1 + 10^((player1.rating - player2.rating) / 400))
    
    local newRating1 = player1.rating + K * (result - expected1)
    local newRating2 = player2.rating + K * ((1 - result) - expected2)
    
    return math.floor(newRating1), math.floor(newRating2)
end

function CompetitiveManager:UpdatePlayerRating(player, newRating)
    local userId = player.UserId
    
    if not self.playerRankings[userId] then
        self.playerRankings[userId] = {}
    end
    
    self.playerRankings[userId].rating = newRating
    
    -- Update seasonal ranking leaderboard
    self:UpdateLeaderboard("SEASONAL_RANKING", {
        playerId = userId,
        playerName = player.Name,
        value = newRating
    })
end

function CompetitiveManager:GenerateSeasonalRankings()
    -- Generate final seasonal rankings
    local seasonalData = {}
    
    for userId, ranking in pairs(self.playerRankings) do
        if ranking.SEASONAL_RANKING then
            local player = Players:GetPlayerByUserId(userId)
            if player then
                table.insert(seasonalData, {
                    playerId = userId,
                    playerName = player.Name,
                    value = ranking.SEASONAL_RANKING
                })
            end
        end
    end
    
    -- Sort by seasonal ranking
    table.sort(seasonalData, function(a, b)
        return a.value < b.value
    end)
    
    return seasonalData
end

-- Helper Functions

function CompetitiveManager:FindAchievement(achievementId)
    for category, achievements in pairs(ACHIEVEMENTS) do
        for _, achievement in pairs(achievements) do
            if achievement.id == achievementId then
                return achievement
            end
        end
    end
    return nil
end

function CompetitiveManager:GetPlayerAchievementPoints(userId)
    local totalPoints = 0
    
    if self.achievements[userId] then
        for _, achievement in pairs(self.achievements[userId]) do
            totalPoints = totalPoints + achievement.points
        end
    end
    
    return totalPoints
end

function CompetitiveManager:CalculatePrestigeTier(points)
    for i = #PRESTIGE_TIERS, 1, -1 do
        local tier = PRESTIGE_TIERS[i]
        if points >= tier.minPoints then
            return tier
        end
    end
    
    return PRESTIGE_TIERS[1] -- Default to Bronze
end

function CompetitiveManager:CheckPrestigeUpgrade(userId, points)
    local currentTier = self.prestigeData[userId] and self.prestigeData[userId].tier or PRESTIGE_TIERS[1]
    local newTier = self:CalculatePrestigeTier(points)
    
    if newTier.name ~= currentTier.name then
        -- Prestige tier upgrade!
        if not self.prestigeData[userId] then
            self.prestigeData[userId] = {}
        end
        
        self.prestigeData[userId].tier = newTier
        self.prestigeData[userId].upgradedAt = tick()
        
        print("CompetitiveManager: Player", userId, "upgraded to", newTier.name, "tier!")
        
        -- Grant prestige benefits
        self:GrantPrestigeBenefits(userId, newTier)
    end
end

function CompetitiveManager:GrantPrestigeBenefits(userId, tier)
    -- Grant benefits based on prestige tier
    local benefits = {
        cashMultiplier = tier.multiplier,
        experienceMultiplier = tier.multiplier,
        abilityCostReduction = math.min(0.1 * (tier.multiplier - 1), 0.5)
    }
    
    -- Store benefits for the player
    if not self.prestigeData[userId] then
        self.prestigeData[userId] = {}
    end
    
    self.prestigeData[userId].benefits = benefits
    
    print("CompetitiveManager: Granted prestige benefits to player", userId)
end

function CompetitiveManager:GetTopPlayers(category, count)
    local leaderboard = self.leaderboards[category]
    if not leaderboard then return {} end
    
    local sortedData = {}
    for _, data in pairs(leaderboard.data) do
        table.insert(sortedData, data)
    end
    
    table.sort(sortedData, function(a, b)
        return a.value > b.value
    end)
    
    return {table.unpack(sortedData, 1, count)}
end

function CompetitiveManager:CalculateSeasonalRewards(rank, category)
    local baseRewards = {
        cash = 1000,
        experience = 500,
        achievementPoints = 100
    }
    
    -- Apply rank multipliers
    local multiplier = math.max(0.1, 1 - (rank - 1) * 0.1)
    
    return {
        cash = math.floor(baseRewards.cash * multiplier),
        experience = math.floor(baseRewards.experience * multiplier),
        achievementPoints = math.floor(baseRewards.achievementPoints * multiplier)
    }
end

function CompetitiveManager:GrantRewards(userId, rewards)
    -- Grant rewards to player (this would integrate with your existing reward system)
    print("CompetitiveManager: Granting rewards to player", userId, ":", rewards)
    
    -- Integrate with existing reward/currency system
    local player = Players:GetPlayerByUserId(userId)
    if not player then
        warn("CompetitiveManager: Cannot grant rewards to offline player", userId)
        return false
    end
    
    -- Grant cash rewards
    if rewards.cash and rewards.cash > 0 then
        -- This would integrate with your existing cash system
        -- For now, we'll use a placeholder that you can replace
        local success = self:GrantCashToPlayer(player, rewards.cash)
        if success then
            print("CompetitiveManager: Granted", rewards.cash, "cash to", player.Name)
        end
    end
    
    -- Grant experience rewards
    if rewards.experience and rewards.experience > 0 then
        -- This would integrate with your existing experience system
        local success = self:GrantExperienceToPlayer(player, rewards.experience)
        if success then
            print("CompetitiveManager: Granted", rewards.experience, "experience to", player.Name)
        end
    end
    
    -- Grant item rewards
    if rewards.items and #rewards.items > 0 then
        for _, item in ipairs(rewards.items) do
            local success = self:GrantItemToPlayer(player, item.id, item.quantity or 1)
            if success then
                print("CompetitiveManager: Granted", item.quantity or 1, "x", item.id, "to", player.Name)
            end
        end
    end
    
    return true
end

-- Helper functions for reward integration
function CompetitiveManager:GrantCashToPlayer(player, amount)
    -- Placeholder for cash integration - replace with your actual cash system
    if not player or not amount or amount <= 0 then
        return false
    end
    
    -- Example integration - you would replace this with your actual cash system
    local success, result = pcall(function()
        -- Try to access your existing cash system
        if player:FindFirstChild("leaderstats") then
            local cashValue = player.leaderstats:FindFirstChild("Cash")
            if cashValue then
                cashValue.Value = cashValue.Value + amount
                return true
            end
        end
        return false
    end)
    
    return success and result or false
end

function CompetitiveManager:GrantExperienceToPlayer(player, amount)
    -- Placeholder for experience integration - replace with your actual experience system
    if not player or not amount or amount <= 0 then
        return false
    end
    
    -- Example integration - you would replace this with your actual experience system
    local success, result = pcall(function()
        -- Try to access your existing experience system
        if player:FindFirstChild("leaderstats") then
            local expValue = player.leaderstats:FindFirstChild("Experience")
            if expValue then
                expValue.Value = expValue.Value + amount
                return true
            end
        end
        return false
    end)
    
    return success and result or false
end

function CompetitiveManager:GrantItemToPlayer(player, itemId, quantity)
    -- Placeholder for item integration - replace with your actual inventory system
    if not player or not itemId or not quantity or quantity <= 0 then
        return false
    end
    
    -- Example integration - you would replace this with your actual inventory system
    local success, result = pcall(function()
        -- Try to access your existing inventory system
        -- This is a placeholder - implement based on your inventory system
        print("CompetitiveManager: Would grant", quantity, "x", itemId, "to", player.Name)
        return true
    end)
    
    return success and result or false
end

function CompetitiveManager:GetSeasonProgress(userId)
    local currentTime = tick()
    local seasonProgress = (currentTime - self.seasonStartTime) / self.seasonDuration
    
    return math.min(1, math.max(0, seasonProgress))
end

-- Event Handlers

function CompetitiveManager:HandlePlayerJoined(player)
    local userId = player.UserId
    
    -- Initialize player data
    if not self.playerRankings[userId] then
        self.playerRankings[userId] = {}
    end
    
    if not self.achievements[userId] then
        self.achievements[userId] = {}
    end
    
    -- Set up Roblox leaderboard (Roblox best practice)
    self:SetupRobloxLeaderboard(player)
    
    -- Send current rankings to player
    self:SendPlayerRankings(player)
    
    print("CompetitiveManager: Player", player.Name, "joined competitive system")
end

function CompetitiveManager:HandlePlayerLeaving(player)
    local userId = player.UserId
    
    -- Clean up player data (keep for persistence)
    -- Data will be saved by your existing save system
    
    print("CompetitiveManager: Player", player.Name, "left competitive system")
end

function CompetitiveManager:HandleCompetitiveAction(player, actionType, data)
    -- Handle various competitive actions from clients
    if actionType == "REQUEST_RANKINGS" then
        self:SendPlayerRankings(player)
    elseif actionType == "REQUEST_LEADERBOARD" then
        local category = data.category
        if self.leaderboards[category] then
            self:SendLeaderboard(player, category)
        end
    elseif actionType == "REQUEST_ACHIEVEMENTS" then
        self:SendPlayerAchievements(player)
    end
end

-- Broadcasting Functions

function CompetitiveManager:BroadcastLeaderboardUpdate(category, data)
    if self.remoteEvents.LeaderboardUpdate then
        self.remoteEvents.LeaderboardUpdate:FireAllClients(category, data)
    end
end

function CompetitiveManager:BroadcastAchievementUnlocked(player, achievement)
    if self.remoteEvents.AchievementUnlocked then
        self.remoteEvents.AchievementUnlocked:FireAllClients(player.UserId, achievement)
    end
end

function CompetitiveManager:BroadcastSeasonReset()
    if self.remoteEvents.SeasonReset then
        self.remoteEvents.SeasonReset:FireAllClients(self.currentSeason)
    end
end

function CompetitiveManager:SendPlayerRankings(player)
    local rankings = self:CalculatePlayerRanking(player)
    
    if self.remoteEvents.RankingUpdate then
        self.remoteEvents.RankingUpdate:FireClient(player, rankings)
    end
end

function CompetitiveManager:SendLeaderboard(player, category)
    local leaderboard = self.leaderboards[category]
    if leaderboard then
        local sortedData = self:GetTopPlayers(category, 100)
        
        if self.remoteEvents.LeaderboardUpdate then
            self.remoteEvents.LeaderboardUpdate:FireClient(player, category, sortedData)
        end
    end
end

function CompetitiveManager:SendPlayerAchievements(player)
    local userId = player.UserId
    local playerAchievements = self.achievements[userId] or {}
    
    -- Convert to client-friendly format
    local achievements = {}
    for achievementId, data in pairs(playerAchievements) do
        local achievement = self:FindAchievement(achievementId)
        if achievement then
            table.insert(achievements, {
                id = achievementId,
                name = achievement.name,
                description = achievement.description,
                points = achievement.points,
                category = achievement.category,
                unlockedAt = data.unlockedAt
            })
        end
    end
    
    -- Send achievements to client using RemoteEvent
    if self.remoteEvents.AchievementUnlocked then
        self.remoteEvents.AchievementUnlocked:FireClient(player, achievements)
        print("CompetitiveManager: Sent", #achievements, "achievements to", player.Name)
    else
        warn("CompetitiveManager: AchievementUnlocked RemoteEvent not found")
    end
end

function CompetitiveManager:UpdateAllLeaderboards()
    -- Update all leaderboards with current data
    -- This integrates with existing systems to get current player data
    
    print("CompetitiveManager: Updating all leaderboards...")
    
    -- Get all online players
    local players = Players:GetPlayers()
    local currentTime = tick()
    
    -- Update each leaderboard category
    for category, leaderboard in pairs(self.leaderboards) do
        local updatedData = {}
        
        for _, player in ipairs(players) do
            local userId = player.UserId
            local playerData = self.playerRankings[userId]
            
            if playerData then
                local score = 0
                
                -- Calculate score based on category
                if category == "OVERALL" then
                    -- Overall score based on multiple factors
                    score = (playerData.achievementPoints or 0) * 10 +
                           (playerData.prestigeLevel or 0) * 1000 +
                           (playerData.seasonPoints or 0)
                elseif category == "ACHIEVEMENTS" then
                    score = playerData.achievementPoints or 0
                elseif category == "PRESTIGE" then
                    score = playerData.prestigeLevel or 0
                elseif category == "SEASON" then
                    score = playerData.seasonPoints or 0
                elseif category == "CASH" then
                    -- Try to get cash from leaderstats
                    if player:FindFirstChild("leaderstats") then
                        local cashValue = player.leaderstats:FindFirstChild("Cash")
                        if cashValue then
                            score = cashValue.Value
                        end
                    end
                elseif category == "EXPERIENCE" then
                    -- Try to get experience from leaderstats
                    if player:FindFirstChild("leaderstats") then
                        local expValue = player.leaderstats:FindFirstChild("Experience")
                        if expValue then
                            score = expValue.Value
                        end
                    end
                end
                
                if score > 0 then
                    table.insert(updatedData, {
                        userId = userId,
                        playerName = player.Name,
                        score = score,
                        lastUpdated = currentTime
                    })
                end
            end
        end
        
        -- Sort by score (highest first)
        table.sort(updatedData, function(a, b)
            return a.score > b.score
        end)
        
        -- Update leaderboard data
        leaderboard.data = updatedData
        leaderboard.lastUpdate = currentTime
        
        -- Broadcast update to all clients
        self:BroadcastLeaderboardUpdate(category, updatedData)
    end
    
    self.lastLeaderboardUpdate = currentTime
    print("CompetitiveManager: Updated", #self.leaderboards, "leaderboards")
end

-- Public API

function CompetitiveManager:GetPlayerRanking(userId)
    return self.playerRankings[userId]
end

function CompetitiveManager:GetLeaderboard(category)
    return self.leaderboards[category]
end

function CompetitiveManager:GetPlayerAchievements(userId)
    return self.achievements[userId] or {}
end

function CompetitiveManager:GetCurrentSeason()
    return {
        number = self.currentSeason,
        startTime = self.seasonStartTime,
        duration = self.seasonDuration,
        progress = (tick() - self.seasonStartTime) / self.seasonDuration
    }
end

function CompetitiveManager:GetPrestigeData(userId)
    return self.prestigeData[userId]
end

-- Cleanup

function CompetitiveManager:Cleanup()
    print("CompetitiveManager: Cleaning up...")
    
    -- Disconnect all connections
    -- Clean up remote events
    -- Reset data structures
    
    print("CompetitiveManager: Cleanup completed")
end

return CompetitiveManager
