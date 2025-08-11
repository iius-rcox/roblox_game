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
    },
    ANIME_MASTERY = {
        FIRST_ANIME_THEME = { id = "FIRST_ANIME_THEME", name = "First Anime Theme", description = "Unlock your first anime theme", points = 150, category = "Anime Mastery" },
        ANIME_COLLECTOR = { id = "ANIME_COLLECTOR", name = "Anime Collector", description = "Collect 50 anime character cards", points = 300, category = "Anime Mastery" },
        THEME_MASTER = { id = "THEME_MASTER", name = "Theme Master", description = "Master 5 different anime themes", points = 600, category = "Anime Mastery" },
        LEGENDARY_HUNTER = { id = "LEGENDARY_HUNTER", name = "Legendary Hunter", description = "Collect 10 legendary or mythic characters", points = 800, category = "Anime Mastery" },
        ANIME_TOURNAMENT_WINNER = { id = "ANIME_TOURNAMENT_WINNER", name = "Tournament Champion", description = "Win an anime-themed tournament", points = 1000, category = "Anime Mastery" },
        CROSS_ANIME_EXPERT = { id = "CROSS_ANIME_EXPERT", name = "Cross-Anime Expert", description = "Participate in cross-anime collaboration events", points = 1200, category = "Anime Mastery" }
    },
    SERIES_SPECIFIC = {
        SOLO_LEVELING_MASTER = { id = "SOLO_LEVELING_MASTER", name = "Solo Leveling Master", description = "Complete Solo Leveling progression", points = 400, category = "Series Specific" },
        NARUTO_MASTER = { id = "NARUTO_MASTER", name = "Naruto Master", description = "Complete Naruto progression", points = 400, category = "Series Specific" },
        ONE_PIECE_MASTER = { id = "ONE_PIECE_MASTER", name = "One Piece Master", description = "Complete One Piece progression", points = 400, category = "Series Specific" },
        DRAGON_BALL_MASTER = { id = "DRAGON_BALL_MASTER", name = "Dragon Ball Master", description = "Complete Dragon Ball progression", points = 400, category = "Series Specific" },
        DEMON_SLAYER_MASTER = { id = "DEMON_SLAYER_MASTER", name = "Demon Slayer Master", description = "Complete Demon Slayer progression", points = 400, category = "Series Specific" },
        AVATAR_MASTER = { id = "AVATAR_MASTER", name = "Avatar Master", description = "Complete Avatar: The Last Airbender progression", points = 400, category = "Series Specific" }
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
    
    -- Initialize anime-specific systems
    self:InitializeAnimeCompetitiveSystems()
    
    -- Anime-specific competitive features
    self.animeLeaderboards = {}      -- Anime theme -> Leaderboard Data
    self.animeEvents = {}            -- Event -> Event Data
    self.crossAnimeTournaments = {} -- Tournament -> Tournament Data
    self.animeSeasonalEvents = {}    -- Seasonal -> Event Data
    self.animeCharacterBattles = {} -- Character battle system
    self.themeSpecificChallenges = {} -- Theme-specific challenges
    self.animeCollaborationEvents = {} -- Cross-anime collaboration events
    self.characterRankings = {}      -- Individual character rankings
    self.animeTournamentBrackets = {} -- Tournament bracket system
    self.animeAchievementProgress = {} -- Anime-specific achievement tracking
    
    -- Enhanced anime competitive systems
    self.animeFusionBattles = {}     -- Character fusion battle system
    self.animeSeasonalChallenges = {} -- Seasonal anime challenges
    self.animePowerScaling = {}      -- Power scaling system
    self.animeCharacterEvolution = {} -- Character evolution tracking
    self.animeWorldEvents = {}       -- World-wide anime events
    self.animeGuildWars = {}         -- Anime guild warfare system
    self.animeTradingCards = {}      -- Anime trading card system
    self.animeCharacterMentorship = {} -- Character mentorship system
    self.animeCrossOverEvents = {}   -- Special crossover events
    self.animeRankingSeasons = {}    -- Anime-specific ranking seasons
    
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
    
    -- Anime-specific leaderboard categories
    self.animeLeaderboardCategories = {
        "SOLO_LEVELING",
        "NARUTO", 
        "ONE_PIECE",
        "BLEACH",
        "MY_HERO_ACADEMIA",
        "ONE_PUNCH_MAN",
        "CHAINSAW_MAN",
        "DRAGON_BALL",
        "DEMON_SLAYER",
        "ATTACK_ON_TITAN",
        "JUJUTSU_KAISEN",
        "HUNTER_X_HUNTER",
        "FULLMETAL_ALCHEMIST",
        "DEATH_NOTE",
        "TOKYO_GHOUL",
        "MOB_PSYCHO_100",
        "OVERLORD",
        "AVATAR_THE_LAST_AIRBENDER"
    }
    
    -- Anime character battle system categories
    self.characterBattleCategories = {
        "POWER_LEVEL",
        "SKILL_MASTERY", 
        "CHARACTER_DEVELOPMENT",
        "THEME_SYNERGY",
        "CROSS_ANIME_COMPATIBILITY"
    }
    
    -- Theme-specific challenge types
    self.themeChallengeTypes = {
        "ELEMENTAL_MASTERY",
        "POWER_SCALING",
        "CHARACTER_GROWTH",
        "WORLD_BUILDING",
        "STORY_PROGRESSION"
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

-- Initialize anime-specific competitive systems
function CompetitiveManager:InitializeAnimeCompetitiveSystems()
    -- Initialize anime leaderboards
    for _, animeTheme in ipairs(self.animeLeaderboardCategories) do
        self.animeLeaderboards[animeTheme] = {
            data = {},
            lastUpdate = 0,
            theme = animeTheme,
            totalParticipants = 0,
            topPerformers = {},
            characterRankings = {},
            themeChallenges = {},
            seasonalProgress = {}
        }
    end
    
    -- Initialize seasonal anime events
    self:InitializeAnimeSeasonalEvents()
    
    -- Initialize cross-anime tournaments
    self:InitializeCrossAnimeTournaments()
    
    -- Initialize character battle system
    self:InitializeCharacterBattleSystem()
    
    -- Initialize theme-specific challenges
    self:InitializeThemeSpecificChallenges()
    
    -- Initialize anime collaboration events
    self:InitializeAnimeCollaborationEvents()
    
    -- Initialize enhanced anime competitive systems
    self:InitializeEnhancedAnimeSystems()
    
    print("CompetitiveManager: Anime competitive systems initialized")
end

-- Initialize enhanced anime competitive systems
function CompetitiveManager:InitializeEnhancedAnimeSystems()
    -- Initialize fusion battle system
    self:InitializeAnimeFusionBattles()
    
    -- Initialize seasonal challenges
    self:InitializeAnimeSeasonalChallenges()
    
    -- Initialize power scaling system
    self:InitializeAnimePowerScaling()
    
    -- Initialize character evolution tracking
    self:InitializeAnimeCharacterEvolution()
    
    -- Initialize world events
    self:InitializeAnimeWorldEvents()
    
    -- Initialize guild warfare system
    self:InitializeAnimeGuildWars()
    
    -- Initialize trading card system
    self:InitializeAnimeTradingCards()
    
    -- Initialize character mentorship
    self:InitializeAnimeCharacterMentorship()
    
    -- Initialize crossover events
    self:InitializeAnimeCrossOverEvents()
    
    -- Initialize ranking seasons
    self:InitializeAnimeRankingSeasons()
    
    print("CompetitiveManager: Enhanced anime competitive systems initialized")
end

-- Initialize anime seasonal events
function CompetitiveManager:InitializeAnimeSeasonalEvents()
    local currentTime = tick()
    
    -- Create seasonal events for each anime theme
    for _, animeTheme in ipairs(self.animeLeaderboardCategories) do
        local eventId = "SEASONAL_" .. animeTheme .. "_" .. self.currentSeason
        self.animeSeasonalEvents[eventId] = {
            id = eventId,
            animeTheme = animeTheme,
            season = self.currentSeason,
            startTime = currentTime,
            endTime = currentTime + self.seasonDuration,
            participants = {},
            rewards = {},
            leaderboard = {},
            status = "Active"
        }
    end
    
    print("CompetitiveManager: Anime seasonal events initialized")
end

-- Initialize cross-anime tournaments
function CompetitiveManager:InitializeCrossAnimeTournaments()
    -- Create cross-anime collaboration tournaments
    local tournamentTypes = {
        { name = "Elemental Clash", themes = {"AVATAR_THE_LAST_AIRBENDER", "DEMON_SLAYER", "FULLMETAL_ALCHEMIST"} },
        { name = "Power Tournament", themes = {"DRAGON_BALL", "ONE_PUNCH_MAN", "MY_HERO_ACADEMIA"} },
        { name = "Supernatural Battle", themes = {"JUJUTSU_KAISEN", "BLEACH", "TOKYO_GHOUL"} },
        { name = "Adventure Quest", themes = {"ONE_PIECE", "HUNTER_X_HUNTER", "NARUTO"} }
    }
    
    for _, tournamentData in ipairs(tournamentTypes) do
        local tournamentId = "CROSS_" .. tournamentData.name:gsub(" ", "_"):upper()
        self.crossAnimeTournaments[tournamentId] = {
            id = tournamentId,
            name = tournamentData.name,
            themes = tournamentData.themes,
            participants = {},
            brackets = {},
            status = "Registration",
            startTime = tick(),
            endTime = tick() + (7 * 24 * 60 * 60), -- 7 days
            rewards = {
                first = { points = 1000, currency = "Universal", amount = 5000 },
                second = { points = 500, currency = "Universal", amount = 2500 },
                third = { points = 250, currency = "Universal", amount = 1000 }
            }
        }
    end
    
    print("CompetitiveManager: Cross-anime tournaments initialized")
end

-- Initialize character battle system
function CompetitiveManager:InitializeCharacterBattleSystem()
    for _, category in ipairs(self.characterBattleCategories) do
        self.animeCharacterBattles[category] = {
            activeBattles = {},
            battleHistory = {},
            rankings = {},
            lastUpdate = 0
        }
    end
    
    -- Initialize character rankings for each anime theme
    for _, animeTheme in ipairs(self.animeLeaderboardCategories) do
        self.characterRankings[animeTheme] = {
            characters = {},
            powerLevels = {},
            skillRatings = {},
            developmentProgress = {}
        }
    end
    
    print("CompetitiveManager: Character battle system initialized")
end

-- Initialize theme-specific challenges
function CompetitiveManager:InitializeThemeSpecificChallenges()
    for _, animeTheme in ipairs(self.animeLeaderboardCategories) do
        self.themeSpecificChallenges[animeTheme] = {}
        
        -- Create challenges for each theme
        for _, challengeType in ipairs(self.themeChallengeTypes) do
            self.themeSpecificChallenges[animeTheme][challengeType] = {
                activeChallenges = {},
                completedChallenges = {},
                leaderboard = {},
                rewards = {}
            }
        end
    end
    
    print("CompetitiveManager: Theme-specific challenges initialized")
end

-- Initialize anime collaboration events
function CompetitiveManager:InitializeAnimeCollaborationEvents()
    local collaborationTypes = {
        "CROSS_ANIME_BATTLE",
        "THEME_FUSION",
        "CHARACTER_EXCHANGE",
        "WORLD_MERGE",
        "STORY_COLLABORATION"
    }
    
    for _, eventType in ipairs(collaborationTypes) do
        self.animeCollaborationEvents[eventType] = {
            activeEvents = {},
            eventHistory = {},
            participants = {},
            rewards = {}
        }
    end
    
    print("CompetitiveManager: Anime collaboration events initialized")
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

-- Anime-Specific Competitive Functions

-- Start a character battle between two players
function CompetitiveManager:StartCharacterBattle(player1, player2, animeTheme, battleType)
    local battleId = HttpService:GenerateGUID(false)
    local currentTime = tick()
    
    local battle = {
        id = battleId,
        player1 = player1.UserId,
        player2 = player2.UserId,
        animeTheme = animeTheme,
        battleType = battleType,
        startTime = currentTime,
        status = "Active",
        rounds = {},
        winner = nil,
        rewards = {}
    }
    
    -- Add battle to active battles
    if not self.animeCharacterBattles[battleType] then
        self.animeCharacterBattles[battleType] = { activeBattles = {} }
    end
    
    self.animeCharacterBattles[battleType].activeBattles[battleId] = battle
    
    -- Notify players
    self:NotifyBattleStart(player1, player2, battle)
    
    print("CompetitiveManager: Character battle started between", player1.Name, "and", player2.Name)
    return battleId
end

-- Process character battle round
function CompetitiveManager:ProcessBattleRound(battleId, roundData)
    local battle = self:FindBattle(battleId)
    if not battle then return false end
    
    local round = {
        roundNumber = #battle.rounds + 1,
        player1Action = roundData.player1Action,
        player2Action = roundData.player2Action,
        winner = roundData.winner,
        timestamp = tick()
    }
    
    table.insert(battle.rounds, round)
    
    -- Check if battle is complete
    if #battle.rounds >= 3 or roundData.winner then
        battle.status = "Completed"
        battle.winner = roundData.winner
        battle.endTime = tick()
        
        -- Process battle completion
        self:CompleteCharacterBattle(battle)
    end
    
    return true
end

-- Complete character battle and award rewards
function CompetitiveManager:CompleteCharacterBattle(battle)
    local winner = Players:GetPlayerByUserId(battle.winner)
    local loser = Players:GetPlayerByUserId(battle.player1 == battle.winner and battle.player2 or battle.player1)
    
    if winner and loser then
        -- Calculate rewards based on battle performance
        local rewards = self:CalculateBattleRewards(battle)
        
        -- Award rewards to winner
        self:GrantBattleRewards(winner, rewards.winner)
        
        -- Award consolation rewards to loser
        self:GrantBattleRewards(loser, rewards.loser)
        
        -- Update character rankings
        self:UpdateCharacterRankings(battle)
        
        -- Move battle to history
        self:MoveBattleToHistory(battle)
        
        -- Notify players of battle completion
        self:NotifyBattleCompletion(winner, loser, battle, rewards)
        
        print("CompetitiveManager: Character battle completed. Winner:", winner.Name)
    end
end

-- Calculate battle rewards
function CompetitiveManager:CalculateBattleRewards(battle)
    local baseRewards = {
        winner = { points = 100, cash = 500, experience = 200 },
        loser = { points = 25, cash = 100, experience = 50 }
    }
    
    -- Apply multipliers based on battle performance
    local roundCount = #battle.rounds
    local performanceMultiplier = math.min(2.0, 1.0 + (roundCount * 0.2))
    
    return {
        winner = {
            points = math.floor(baseRewards.winner.points * performanceMultiplier),
            cash = math.floor(baseRewards.winner.cash * performanceMultiplier),
            experience = math.floor(baseRewards.winner.experience * performanceMultiplier)
        },
        loser = baseRewards.loser
    }
end

-- Grant battle rewards to player
function CompetitiveManager:GrantBattleRewards(player, rewards)
    if not player or not rewards then return false end
    
    -- Grant points
    if rewards.points and rewards.points > 0 then
        self:GrantPointsToPlayer(player, rewards.points)
    end
    
    -- Grant cash
    if rewards.cash and rewards.cash > 0 then
        self:GrantCashToPlayer(player, rewards.cash)
    end
    
    -- Grant experience
    if rewards.experience and rewards.experience > 0 then
        self:GrantExperienceToPlayer(player, rewards.experience)
    end
    
    return true
end

-- Update character rankings after battle
function CompetitiveManager:UpdateCharacterRankings(battle)
    local winner = battle.winner
    local loser = battle.player1 == winner and battle.player2 or battle.player1
    
    -- Update winner ranking
    if not self.characterRankings[battle.animeTheme] then
        self.characterRankings[battle.animeTheme] = { characters = {} }
    end
    
    if not self.characterRankings[battle.animeTheme].characters[winner] then
        self.characterRankings[battle.animeTheme].characters[winner] = {
            wins = 0,
            losses = 0,
            rating = 1000,
            rank = 999999
        }
    end
    
    local winnerData = self.characterRankings[battle.animeTheme].characters[winner]
    winnerData.wins = winnerData.wins + 1
    winnerData.rating = winnerData.rating + 25
    
    -- Update loser ranking
    if not self.characterRankings[battle.animeTheme].characters[loser] then
        self.characterRankings[battle.animeTheme].characters[loser] = {
            wins = 0,
            losses = 0,
            rating = 1000,
            rank = 999999
        }
    end
    
    local loserData = self.characterRankings[battle.animeTheme].characters[loser]
    loserData.losses = loserData.losses + 1
    loserData.rating = math.max(100, loserData.rating - 15)
    
    -- Recalculate rankings
    self:RecalculateCharacterRankings(battle.animeTheme)
end

-- Recalculate character rankings for a theme
function CompetitiveManager:RecalculateCharacterRankings(animeTheme)
    if not self.characterRankings[animeTheme] then return end
    
    local characters = {}
    for userId, data in pairs(self.characterRankings[animeTheme].characters) do
        table.insert(characters, { userId = userId, data = data })
    end
    
    -- Sort by rating (highest first)
    table.sort(characters, function(a, b)
        return a.data.rating > b.data.rating
    end)
    
    -- Assign ranks
    for rank, character in ipairs(characters) do
        self.characterRankings[animeTheme].characters[character.userId].rank = rank
    end
end

-- Create theme-specific challenge
function CompetitiveManager:CreateThemeChallenge(animeTheme, challengeType, challengeData)
    local challengeId = HttpService:GenerateGUID(false)
    local currentTime = tick()
    
    local challenge = {
        id = challengeId,
        animeTheme = animeTheme,
        challengeType = challengeType,
        title = challengeData.title,
        description = challengeData.description,
        requirements = challengeData.requirements,
        rewards = challengeData.rewards,
        startTime = currentTime,
        endTime = currentTime + (challengeData.duration or 86400), -- Default 24 hours
        participants = {},
        leaderboard = {},
        status = "Active"
    }
    
    -- Add challenge to theme challenges
    if not self.themeSpecificChallenges[animeTheme] then
        self.themeSpecificChallenges[animeTheme] = {}
    end
    
    if not self.themeSpecificChallenges[animeTheme][challengeType] then
        self.themeSpecificChallenges[animeTheme][challengeType] = { activeChallenges = {} }
    end
    
    self.themeSpecificChallenges[animeTheme][challengeType].activeChallenges[challengeId] = challenge
    
    -- Broadcast challenge creation
    self:BroadcastChallengeCreated(challenge)
    
    print("CompetitiveManager: Theme challenge created:", challenge.title)
    return challengeId
end

-- Join theme challenge
function CompetitiveManager:JoinThemeChallenge(player, challengeId)
    local challenge = self:FindChallenge(challengeId)
    if not challenge or challenge.status ~= "Active" then
        return false, "Challenge not available"
    end
    
    local userId = player.UserId
    
    -- Check if player already joined
    if challenge.participants[userId] then
        return false, "Already joined challenge"
    end
    
    -- Check requirements
    if not self:CheckChallengeRequirements(player, challenge) then
        return false, "Requirements not met"
    end
    
    -- Add player to challenge
    challenge.participants[userId] = {
        playerName = player.Name,
        joinTime = tick(),
        progress = 0,
        completed = false
    }
    
    -- Initialize leaderboard entry
    challenge.leaderboard[userId] = {
        playerName = player.Name,
        progress = 0,
        lastUpdate = tick()
    }
    
    print("CompetitiveManager: Player", player.Name, "joined challenge:", challenge.title)
    return true
end

-- Update challenge progress
function CompetitiveManager:UpdateChallengeProgress(player, challengeId, progress)
    local challenge = self:FindChallenge(challengeId)
    if not challenge then return false end
    
    local userId = player.UserId
    local participant = challenge.participants[userId]
    
    if not participant then return false end
    
    -- Update progress
    participant.progress = math.max(participant.progress, progress)
    challenge.leaderboard[userId].progress = participant.progress
    challenge.leaderboard[userId].lastUpdate = tick()
    
    -- Check if challenge completed
    if participant.progress >= 100 and not participant.completed then
        participant.completed = true
        participant.completionTime = tick()
        
        -- Award completion rewards
        self:GrantChallengeRewards(player, challenge)
        
        -- Check if challenge should end
        self:CheckChallengeCompletion(challenge)
    end
    
    return true
end

-- Check challenge requirements
function CompetitiveManager:CheckChallengeRequirements(player, challenge)
    local userId = player.UserId
    
    -- Check anime theme mastery level
    if challenge.requirements.themeMastery then
        local masteryLevel = self:GetPlayerThemeMastery(userId, challenge.animeTheme)
        if masteryLevel < challenge.requirements.themeMastery then
            return false
        end
    end
    
    -- Check character collection
    if challenge.requirements.characterCount then
        local characterCount = self:GetPlayerCharacterCount(userId, challenge.animeTheme)
        if characterCount < challenge.requirements.characterCount then
            return false
        end
    end
    
    -- Check power level
    if challenge.requirements.powerLevel then
        local powerLevel = self:GetPlayerPowerLevel(userId, challenge.animeTheme)
        if powerLevel < challenge.requirements.powerLevel then
            return false
        end
    end
    
    return true
end

-- Grant challenge rewards
function CompetitiveManager:GrantChallengeRewards(player, challenge)
    if not player or not challenge or not challenge.rewards then return false end
    
    local rewards = challenge.rewards
    
    -- Grant points
    if rewards.points and rewards.points > 0 then
        self:GrantPointsToPlayer(player, rewards.points)
    end
    
    -- Grant cash
    if rewards.cash and rewards.cash > 0 then
        self:GrantCashToPlayer(player, rewards.cash)
    end
    
    -- Grant items
    if rewards.items and #rewards.items > 0 then
        for _, item in ipairs(rewards.items) do
            self:GrantItemToPlayer(player, item.id, item.quantity or 1)
        end
    end
    
    -- Grant achievement progress
    if rewards.achievementProgress then
        self:UpdateAnimeAchievementProgress(player, challenge.animeTheme, rewards.achievementProgress)
    end
    
    print("CompetitiveManager: Granted challenge rewards to", player.Name)
    return true
end

-- Helper functions for anime competitive system
function CompetitiveManager:FindBattle(battleId)
    for _, battleCategory in pairs(self.animeCharacterBattles) do
        if battleCategory.activeBattles and battleCategory.activeBattles[battleId] then
            return battleCategory.activeBattles[battleId]
        end
    end
    return nil
end

function CompetitiveManager:FindChallenge(challengeId)
    for _, themeChallenges in pairs(self.themeSpecificChallenges) do
        for _, challengeType in pairs(themeChallenges) do
            if challengeType.activeChallenges and challengeType.activeChallenges[challengeId] then
                return challengeType.activeChallenges[challengeId]
            end
        end
    end
    return nil
end

function CompetitiveManager:MoveBattleToHistory(battle)
    -- Remove from active battles
    for _, battleCategory in pairs(self.animeCharacterBattles) do
        if battleCategory.activeBattles and battleCategory.activeBattles[battle.id] then
            battleCategory.activeBattles[battle.id] = nil
            break
        end
    end
    
    -- Add to battle history
    if not self.animeCharacterBattles[battle.battleType] then
        self.animeCharacterBattles[battle.battleType] = { battleHistory = {} }
    end
    
    self.animeCharacterBattles[battle.battleType].battleHistory[battle.id] = battle
end

function CompetitiveManager:CheckChallengeCompletion(challenge)
    local completedCount = 0
    local totalParticipants = 0
    
    for _, participant in pairs(challenge.participants) do
        totalParticipants = totalParticipants + 1
        if participant.completed then
            completedCount = completedCount + 1
        end
    end
    
    -- End challenge if all participants completed or time expired
    if completedCount >= totalParticipants or tick() >= challenge.endTime then
        challenge.status = "Completed"
        self:EndThemeChallenge(challenge)
    end
end

function CompetitiveManager:EndThemeChallenge(challenge)
    -- Calculate final rankings
    local finalRankings = {}
    for userId, leaderboardEntry in pairs(challenge.leaderboard) do
        table.insert(finalRankings, {
            userId = userId,
            playerName = leaderboardEntry.playerName,
            progress = leaderboardEntry.progress,
            completed = challenge.participants[userId] and challenge.participants[userId].completed
        })
    end
    
    -- Sort by progress (highest first)
    table.sort(finalRankings, function(a, b)
        if a.completed and not b.completed then return true end
        if not a.completed and b.completed then return false end
        return a.progress > b.progress
    end)
    
    -- Award final rewards
    for rank, entry in ipairs(finalRankings) do
        local player = Players:GetPlayerByUserId(entry.userId)
        if player then
            local finalRewards = self:CalculateFinalChallengeRewards(rank, entry.completed)
            self:GrantChallengeRewards(player, { rewards = finalRewards })
        end
    end
    
    -- Move challenge to completed
    if not self.themeSpecificChallenges[challenge.animeTheme] then
        self.themeSpecificChallenges[challenge.animeTheme] = {}
    end
    
    if not self.themeSpecificChallenges[challenge.animeTheme][challenge.challengeType] then
        self.themeSpecificChallenges[challenge.animeTheme][challenge.challengeType] = { completedChallenges = {} }
    end
    
    self.themeSpecificChallenges[challenge.animeTheme][challenge.challengeType].completedChallenges[challenge.id] = challenge
    
    print("CompetitiveManager: Theme challenge ended:", challenge.title)
end

function CompetitiveManager:CalculateFinalChallengeRewards(rank, completed)
    local baseRewards = {
        points = 50,
        cash = 200,
        experience = 100
    }
    
    -- Apply rank multipliers
    local rankMultiplier = math.max(0.1, 1.0 - (rank - 1) * 0.1)
    local completionBonus = completed and 2.0 or 1.0
    
    return {
        points = math.floor(baseRewards.points * rankMultiplier * completionBonus),
        cash = math.floor(baseRewards.cash * rankMultiplier * completionBonus),
        experience = math.floor(baseRewards.experience * rankMultiplier * completionBonus)
    }
end

-- Notification functions
function CompetitiveManager:NotifyBattleStart(player1, player2, battle)
    -- Send battle start notification to both players
    if self.remoteEvents.CompetitiveAction then
        self.remoteEvents.CompetitiveAction:FireClient(player1, "BATTLE_START", battle)
        self.remoteEvents.CompetitiveAction:FireClient(player2, "BATTLE_START", battle)
    end
end

function CompetitiveManager:NotifyBattleCompletion(winner, loser, battle, rewards)
    -- Send battle completion notification to both players
    if self.remoteEvents.CompetitiveAction then
        self.remoteEvents.CompetitiveAction:FireClient(winner, "BATTLE_COMPLETE", { battle = battle, rewards = rewards.winner, result = "WIN" })
        self.remoteEvents.CompetitiveAction:FireClient(loser, "BATTLE_COMPLETE", { battle = battle, rewards = rewards.loser, result = "LOSS" })
    end
end

function CompetitiveManager:BroadcastChallengeCreated(challenge)
    -- Broadcast challenge creation to all clients
    if self.remoteEvents.CompetitiveAction then
        self.remoteEvents.CompetitiveAction:FireAllClients("CHALLENGE_CREATED", challenge)
    end
end

-- Placeholder functions for integration with existing systems
function CompetitiveManager:GetPlayerThemeMastery(userId, animeTheme)
    -- This would integrate with your existing theme mastery system
    return self.playerRankings[userId] and self.playerRankings[userId].themeMastery and self.playerRankings[userId].themeMastery[animeTheme] or 0
end

function CompetitiveManager:GetPlayerCharacterCount(userId, animeTheme)
    -- This would integrate with your existing character collection system
    return self.playerRankings[userId] and self.playerRankings[userId].characterCount and self.playerRankings[userId].characterCount[animeTheme] or 0
end

function CompetitiveManager:GetPlayerPowerLevel(userId, animeTheme)
    -- This would integrate with your existing power level system
    return self.playerRankings[userId] and self.playerRankings[userId].powerLevel and self.playerRankings[userId].powerLevel[animeTheme] or 0
end

function CompetitiveManager:GrantPointsToPlayer(player, points)
    -- This would integrate with your existing points system
    if not player or not points or points <= 0 then return false end
    
    -- Example integration - replace with your actual points system
    local success, result = pcall(function()
        -- Try to access your existing points system
        if player:FindFirstChild("leaderstats") then
            local pointsValue = player.leaderstats:FindFirstChild("Points")
            if pointsValue then
                pointsValue.Value = pointsValue.Value + points
                return true
            end
        end
        return false
    end)
    
    return success and result or false
end

function CompetitiveManager:UpdateAnimeAchievementProgress(player, animeTheme, progress)
    -- This would integrate with your existing achievement system
    local userId = player.UserId
    
    if not self.animeAchievementProgress[userId] then
        self.animeAchievementProgress[userId] = {}
    end
    
    if not self.animeAchievementProgress[userId][animeTheme] then
        self.animeAchievementProgress[userId][animeTheme] = 0
    end
    
    self.animeAchievementProgress[userId][animeTheme] = self.animeAchievementProgress[userId][animeTheme] + progress
    
    -- Check for achievement unlocks
    self:CheckAnimeAchievementUnlocks(player, animeTheme)
end

function CompetitiveManager:CheckAnimeAchievementUnlocks(player, animeTheme)
    local userId = player.UserId
    local progress = self.animeAchievementProgress[userId] and self.animeAchievementProgress[userId][animeTheme] or 0
    
    -- Check for theme-specific achievements
    local themeAchievements = {
        { id = "THEME_MASTER_" .. animeTheme, requirement = 1000, points = 500 },
        { id = "THEME_EXPERT_" .. animeTheme, requirement = 500, points = 250 },
        { id = "THEME_APPRENTICE_" .. animeTheme, requirement = 100, points = 100 }
    }
    
    for _, achievement in ipairs(themeAchievements) do
        if progress >= achievement.requirement then
            self:AwardAchievement(player, achievement.id)
        end
    end
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
    -- Anime-specific competitive actions
    elseif actionType == "REQUEST_ANIME_LEADERBOARD" then
        local animeTheme = data.animeTheme
        if self.animeLeaderboards[animeTheme] then
            self:SendAnimeLeaderboard(player, animeTheme)
        end
    elseif actionType == "REQUEST_CHARACTER_RANKINGS" then
        local animeTheme = data.animeTheme
        if self.characterRankings[animeTheme] then
            self:SendCharacterRankings(player, animeTheme)
        end
    elseif actionType == "REQUEST_ACTIVE_CHALLENGES" then
        local challenges = self:GetActiveChallenges(data.animeTheme, data.challengeType)
        self:SendActiveChallenges(player, challenges)
    elseif actionType == "JOIN_CHALLENGE" then
        local success, message = self:JoinThemeChallenge(player, data.challengeId)
        self:SendChallengeJoinResult(player, success, message)
    elseif actionType == "UPDATE_CHALLENGE_PROGRESS" then
        local success = self:UpdateChallengeProgress(player, data.challengeId, data.progress)
        self:SendChallengeProgressUpdate(player, success)
    elseif actionType == "REQUEST_BATTLE" then
        local targetPlayer = Players:GetPlayerByUserId(data.targetUserId)
        if targetPlayer then
            local battleId = self:StartCharacterBattle(player, targetPlayer, data.animeTheme, data.battleType)
            self:SendBattleRequestResult(player, battleId)
        end
    elseif actionType == "BATTLE_ACTION" then
        local success = self:ProcessBattleRound(data.battleId, data.roundData)
        self:SendBattleActionResult(player, success)
    elseif actionType == "JOIN_TOURNAMENT" then
        local success, message = self:JoinTournament(player, data.tournamentId)
        self:SendTournamentJoinResult(player, success, message)
    elseif actionType == "REQUEST_ANIME_STATS" then
        local stats = self:GetPlayerAnimeStats(player.UserId, data.animeTheme)
        self:SendAnimeStats(player, stats)
    -- Enhanced anime competitive actions
    elseif actionType == "REQUEST_FUSION_BATTLE" then
        local targetPlayer = Players:GetPlayerByUserId(data.targetUserId)
        if targetPlayer then
            local fusionId = self:StartFusionBattle(player, targetPlayer, data.animeTheme, data.fusionType)
            self:SendFusionBattleRequestResult(player, fusionId)
        end
    elseif actionType == "FUSION_BATTLE_ACTION" then
        local success = self:ProcessFusionBattle(data.fusionId, data.fusionData)
        self:SendFusionBattleActionResult(player, success)
    elseif actionType == "JOIN_SEASONAL_CHALLENGE" then
        local success, message = self:JoinSeasonalAnimeChallenge(player, data.challengeId)
        self:SendSeasonalChallengeJoinResult(player, success, message)
    elseif actionType == "UPDATE_SEASONAL_CHALLENGE_PROGRESS" then
        local success = self:UpdateSeasonalChallengeProgress(player, data.challengeId, data.objectiveId, data.progress)
        self:SendSeasonalChallengeProgressUpdate(player, success)
    elseif actionType == "REQUEST_FUSION_RANKINGS" then
        local rankings = self:GetFusionRankings(data.animeTheme)
        self:SendFusionRankings(player, rankings)
    elseif actionType == "REQUEST_SEASONAL_CHALLENGES" then
        local challenges = self:GetSeasonalChallenges(data.animeTheme)
        self:SendSeasonalChallenges(player, challenges)
    elseif actionType == "REQUEST_GUILD_WARS" then
        local wars = self:GetActiveGuildWars(data.animeTheme)
        self:SendGuildWars(player, wars)
    elseif actionType == "REQUEST_ENHANCED_ANIME_METRICS" then
        local metrics = self:GetEnhancedAnimeCompetitiveMetrics()
        self:SendEnhancedAnimeMetrics(player, metrics)
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

-- Anime Competitive System Send Functions

function CompetitiveManager:SendAnimeLeaderboard(player, animeTheme)
    local leaderboard = self.animeLeaderboards[animeTheme]
    if leaderboard then
        local sortedData = {}
        for userId, data in pairs(leaderboard.data) do
            table.insert(sortedData, data)
        end
        
        table.sort(sortedData, function(a, b)
            return a.value > b.value
        end)
        
        if self.remoteEvents.LeaderboardUpdate then
            self.remoteEvents.LeaderboardUpdate:FireClient(player, "ANIME_" .. animeTheme, sortedData)
        end
    end
end

function CompetitiveManager:SendCharacterRankings(player, animeTheme)
    local rankings = self.characterRankings[animeTheme]
    if rankings and self.remoteEvents.RankingUpdate then
        self.remoteEvents.RankingUpdate:FireClient(player, "CHARACTER_" .. animeTheme, rankings)
    end
end

function CompetitiveManager:SendActiveChallenges(player, challenges)
    if self.remoteEvents.CompetitiveAction then
        self.remoteEvents.CompetitiveAction:FireClient(player, "ACTIVE_CHALLENGES", challenges)
    end
end

function CompetitiveManager:SendChallengeJoinResult(player, success, message)
    if self.remoteEvents.CompetitiveAction then
        self.remoteEvents.CompetitiveAction:FireClient(player, "CHALLENGE_JOIN_RESULT", { success = success, message = message })
    end
end

function CompetitiveManager:SendChallengeProgressUpdate(player, success)
    if self.remoteEvents.CompetitiveAction then
        self.remoteEvents.CompetitiveAction:FireClient(player, "CHALLENGE_PROGRESS_UPDATE", { success = success })
    end
end

function CompetitiveManager:SendBattleRequestResult(player, battleId)
    if self.remoteEvents.CompetitiveAction then
        self.remoteEvents.CompetitiveAction:FireClient(player, "BATTLE_REQUEST_RESULT", { battleId = battleId })
    end
end

function CompetitiveManager:SendBattleActionResult(player, success)
    if self.remoteEvents.CompetitiveAction then
        self.remoteEvents.CompetitiveAction:FireClient(player, "BATTLE_ACTION_RESULT", { success = success })
    end
end

function CompetitiveManager:SendTournamentJoinResult(player, success, message)
    if self.remoteEvents.CompetitiveAction then
        self.remoteEvents.CompetitiveAction:FireClient(player, "TOURNAMENT_JOIN_RESULT", { success = success, message = message })
    end
end

function CompetitiveManager:SendAnimeStats(player, stats)
    if self.remoteEvents.CompetitiveAction then
        self.remoteEvents.CompetitiveAction:FireClient(player, "ANIME_STATS", stats)
    end
end

-- Enhanced anime competitive system send functions
function CompetitiveManager:SendFusionBattleRequestResult(player, fusionId)
    if self.remoteEvents.CompetitiveAction then
        self.remoteEvents.CompetitiveAction:FireClient(player, "FUSION_BATTLE_REQUEST_RESULT", { fusionId = fusionId })
    end
end

function CompetitiveManager:SendFusionBattleActionResult(player, success)
    if self.remoteEvents.CompetitiveAction then
        self.remoteEvents.CompetitiveAction:FireClient(player, "FUSION_BATTLE_ACTION_RESULT", { success = success })
    end
end

function CompetitiveManager:SendSeasonalChallengeJoinResult(player, success, message)
    if self.remoteEvents.CompetitiveAction then
        self.remoteEvents.CompetitiveAction:FireClient(player, "SEASONAL_CHALLENGE_JOIN_RESULT", { success = success, message = message })
    end
end

function CompetitiveManager:SendSeasonalChallengeProgressUpdate(player, success)
    if self.remoteEvents.CompetitiveAction then
        self.remoteEvents.CompetitiveAction:FireClient(player, "SEASONAL_CHALLENGE_PROGRESS_UPDATE", { success = success })
    end
end

function CompetitiveManager:SendFusionRankings(player, rankings)
    if self.remoteEvents.CompetitiveAction then
        self.remoteEvents.CompetitiveAction:FireClient(player, "FUSION_RANKINGS", rankings)
    end
end

function CompetitiveManager:SendSeasonalChallenges(player, challenges)
    if self.remoteEvents.CompetitiveAction then
        self.remoteEvents.CompetitiveAction:FireClient(player, "SEASONAL_CHALLENGES", challenges)
    end
end

function CompetitiveManager:SendGuildWars(player, wars)
    if self.remoteEvents.CompetitiveAction then
        self.remoteEvents.CompetitiveAction:FireClient(player, "GUILD_WARS", wars)
    end
end

function CompetitiveManager:SendEnhancedAnimeMetrics(player, metrics)
    if self.remoteEvents.CompetitiveAction then
        self.remoteEvents.CompetitiveAction:FireClient(player, "ENHANCED_ANIME_METRICS", metrics)
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

-- Enhanced Anime Competitive Systems Public API

function CompetitiveManager:GetFusionBattles(animeTheme)
    if animeTheme then
        return self.animeFusionBattles[animeTheme] or {}
    end
    return self.animeFusionBattles
end

function CompetitiveManager:GetSeasonalChallenges(animeTheme)
    if animeTheme then
        return self.animeSeasonalChallenges[animeTheme] or {}
    end
    return self.animeSeasonalChallenges
end

function CompetitiveManager:GetActiveGuildWars(animeTheme)
    if animeTheme then
        return self.animeGuildWars[animeTheme] or {}
    end
    return self.animeGuildWars
end

function CompetitiveManager:GetFusionRankings(animeTheme)
    if animeTheme then
        return self.animeFusionBattles[animeTheme] and self.animeFusionBattles[animeTheme].rankings or {}
    end
    return {}
end

function CompetitiveManager:GetAnimePowerScaling(animeTheme)
    if animeTheme then
        return self.animePowerScaling[animeTheme] or {}
    end
    return self.animePowerScaling
end

function CompetitiveManager:GetCharacterEvolution(animeTheme)
    if animeTheme then
        return self.animeCharacterEvolution[animeTheme] or {}
    end
    return self.animeCharacterEvolution
end

function CompetitiveManager:GetWorldEvents(animeTheme)
    if animeTheme then
        return self.animeWorldEvents[animeTheme] or {}
    end
    return self.animeWorldEvents
end

function CompetitiveManager:GetTradingCards(animeTheme)
    if animeTheme then
        return self.animeTradingCards[animeTheme] or {}
    end
    return self.animeTradingCards
end

function CompetitiveManager:GetCharacterMentorship(animeTheme)
    if animeTheme then
        return self.animeCharacterMentorship[animeTheme] or {}
    end
    return self.animeCharacterMentorship
end

function CompetitiveManager:GetCrossOverEvents(animeTheme)
    if animeTheme then
        return self.animeCrossOverEvents[animeTheme] or {}
    end
    return self.animeCrossOverEvents
end

function CompetitiveManager:GetAnimeRankingSeasons(animeTheme)
    if animeTheme then
        return self.animeRankingSeasons[animeTheme] or {}
    end
    return self.animeRankingSeasons
end

function CompetitiveManager:GetEnhancedAnimeCompetitiveMetrics()
    local metrics = {
        fusionBattles = {},
        seasonalChallenges = {},
        guildWars = {},
        powerScaling = {},
        characterEvolution = {},
        worldEvents = {},
        tradingCards = {},
        characterMentorship = {},
        crossOverEvents = {},
        rankingSeasons = {}
    }
    
    -- Collect metrics for each anime theme
    for theme, _ in pairs(self.animeFusionBattles) do
        metrics.fusionBattles[theme] = {
            activeBattles = self.animeFusionBattles[theme] and #(self.animeFusionBattles[theme].activeBattles or {}) or 0,
            totalBattles = self.animeFusionBattles[theme] and #(self.animeFusionBattles[theme].battleHistory or {}) or 0
        }
        
        metrics.seasonalChallenges[theme] = {
            activeChallenges = self.animeSeasonalChallenges[theme] and #(self.animeSeasonalChallenges[theme].activeChallenges or {}) or 0,
            completedChallenges = self.animeSeasonalChallenges[theme] and #(self.animeSeasonalChallenges[theme].completedChallenges or {}) or 0
        }
        
        metrics.guildWars[theme] = {
            activeWars = self.animeGuildWars[theme] and #(self.animeGuildWars[theme].activeWars or {}) or 0,
            completedWars = self.animeGuildWars[theme] and #(self.animeGuildWars[theme].warHistory or {}) or 0
        }
        
        metrics.powerScaling[theme] = {
            totalCharacters = self.animePowerScaling[theme] and #(self.animePowerScaling[theme].characters or {}) or 0,
            maxPowerLevel = self.animePowerScaling[theme] and self.animePowerScaling[theme].maxPowerLevel or 0
        }
        
        metrics.characterEvolution[theme] = {
            totalEvolutions = self.animeCharacterEvolution[theme] and #(self.animeCharacterEvolution[theme].evolutions or {}) or 0,
            activeEvolutions = self.animeCharacterEvolution[theme] and #(self.animeCharacterEvolution[theme].activeEvolutions or {}) or 0
        }
        
        metrics.worldEvents[theme] = {
            activeEvents = self.animeWorldEvents[theme] and #(self.animeWorldEvents[theme].activeEvents or {}) or 0,
            completedEvents = self.animeWorldEvents[theme] and #(self.animeWorldEvents[theme].eventHistory or {}) or 0
        }
        
        metrics.tradingCards[theme] = {
            totalCards = self.animeTradingCards[theme] and #(self.animeTradingCards[theme].cards or {}) or 0,
            activeTrades = self.animeTradingCards[theme] and #(self.animeTradingCards[theme].activeTrades or {}) or 0
        }
        
        metrics.characterMentorship[theme] = {
            activeMentorships = self.animeCharacterMentorship[theme] and #(self.animeCharacterMentorship[theme].activeMentorships or {}) or 0,
            completedMentorships = self.animeCharacterMentorship[theme] and #(self.animeCharacterMentorship[theme].mentorshipHistory or {}) or 0
        }
        
        metrics.crossOverEvents[theme] = {
            activeEvents = self.animeCrossOverEvents[theme] and #(self.animeCrossOverEvents[theme].activeEvents or {}) or 0,
            completedEvents = self.animeCrossOverEvents[theme] and #(self.animeCrossOverEvents[theme].eventHistory or {}) or 0
        }
        
        metrics.rankingSeasons[theme] = {
            currentSeason = self.animeRankingSeasons[theme] and self.animeRankingSeasons[theme].currentSeason or nil,
            totalSeasons = self.animeRankingSeasons[theme] and #(self.animeRankingSeasons[theme].seasons or {}) or 0
        }
    end
    
    return metrics
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

-- Anime Competitive System Public API

function CompetitiveManager:GetAnimeLeaderboard(animeTheme)
    return self.animeLeaderboards[animeTheme]
end

function CompetitiveManager:GetCharacterRankings(animeTheme)
    return self.characterRankings[animeTheme]
end

function CompetitiveManager:GetActiveChallenges(animeTheme, challengeType)
    if not animeTheme then
        -- Return all active challenges across all themes
        local allChallenges = {}
        for theme, themeChallenges in pairs(self.themeSpecificChallenges) do
            for type, typeChallenges in pairs(themeChallenges) do
                for challengeId, challenge in pairs(typeChallenges.activeChallenges or {}) do
                    table.insert(allChallenges, challenge)
                end
            end
        end
        return allChallenges
    end
    
    if not challengeType then
        -- Return all active challenges for a specific theme
        local themeChallenges = {}
        if self.themeSpecificChallenges[animeTheme] then
            for type, typeChallenges in pairs(self.themeSpecificChallenges[animeTheme]) do
                for challengeId, challenge in pairs(typeChallenges.activeChallenges or {}) do
                    table.insert(themeChallenges, challenge)
                end
            end
        end
        return themeChallenges
    end
    
    -- Return active challenges for specific theme and type
    if self.themeSpecificChallenges[animeTheme] and self.themeSpecificChallenges[animeTheme][challengeType] then
        local challenges = {}
        for challengeId, challenge in pairs(self.themeSpecificChallenges[animeTheme][challengeType].activeChallenges or {}) do
            table.insert(challenges, challenge)
        end
        return challenges
    end
    
    return {}
end

function CompetitiveManager:GetActiveBattles(battleType)
    if not battleType then
        -- Return all active battles across all types
        local allBattles = {}
        for _, battleCategory in pairs(self.animeCharacterBattles) do
            for battleId, battle in pairs(battleCategory.activeBattles or {}) do
                table.insert(allBattles, battle)
            end
        end
        return allBattles
    end
    
    -- Return active battles for specific type
    if self.animeCharacterBattles[battleType] and self.animeCharacterBattles[battleType].activeBattles then
        local battles = {}
        for battleId, battle in pairs(self.animeCharacterBattles[battleType].activeBattles) do
            table.insert(battles, battle)
        end
        return battles
    end
    
    return {}
end

function CompetitiveManager:GetPlayerAnimeStats(userId, animeTheme)
    local stats = {
        themeMastery = self:GetPlayerThemeMastery(userId, animeTheme),
        characterCount = self:GetPlayerCharacterCount(userId, animeTheme),
        powerLevel = self:GetPlayerPowerLevel(userId, animeTheme),
        achievements = self.animeAchievementProgress[userId] and self.animeAchievementProgress[userId][animeTheme] or 0,
        ranking = nil,
        battleStats = { wins = 0, losses = 0, rating = 1000 }
    }
    
    -- Get character ranking data
    if self.characterRankings[animeTheme] and self.characterRankings[animeTheme].characters[userId] then
        local charData = self.characterRankings[animeTheme].characters[userId]
        stats.ranking = charData.rank
        stats.battleStats = {
            wins = charData.wins,
            losses = charData.losses,
            rating = charData.rating
        }
    end
    
    return stats
end

function CompetitiveManager:GetAnimeTournamentInfo(tournamentId)
    return self.crossAnimeTournaments[tournamentId]
end

function CompetitiveManager:GetActiveTournaments()
    local activeTournaments = {}
    for tournamentId, tournament in pairs(self.crossAnimeTournaments) do
        if tournament.status == "Active" or tournament.status == "Registration" then
            table.insert(activeTournaments, tournament)
        end
    end
    return activeTournaments
end

function CompetitiveManager:JoinTournament(player, tournamentId)
    local tournament = self.crossAnimeTournaments[tournamentId]
    if not tournament then
        return false, "Tournament not found"
    end
    
    if tournament.status ~= "Registration" then
        return false, "Tournament registration closed"
    end
    
    local userId = player.UserId
    
    -- Check if player already joined
    if tournament.participants[userId] then
        return false, "Already joined tournament"
    end
    
    -- Add player to tournament
    tournament.participants[userId] = {
        playerName = player.Name,
        joinTime = tick(),
        theme = self:GetPlayerPrimaryTheme(userId),
        status = "Active"
    }
    
    print("CompetitiveManager: Player", player.Name, "joined tournament:", tournament.name)
    return true
end

function CompetitiveManager:GetPlayerPrimaryTheme(userId)
    -- Determine player's primary anime theme based on their progress
    local themeProgress = {}
    
    for _, animeTheme in ipairs(self.animeLeaderboardCategories) do
        local mastery = self:GetPlayerThemeMastery(userId, animeTheme)
        local characters = self:GetPlayerCharacterCount(userId, animeTheme)
        local power = self:GetPlayerPowerLevel(userId, animeTheme)
        
        themeProgress[animeTheme] = (mastery * 0.4) + (characters * 0.3) + (power * 0.3)
    end
    
    -- Find theme with highest progress
    local primaryTheme = self.animeLeaderboardCategories[1]
    local highestProgress = themeProgress[primaryTheme] or 0
    
    for theme, progress in pairs(themeProgress) do
        if progress > highestProgress then
            highestProgress = progress
            primaryTheme = theme
        end
    end
    
    return primaryTheme
end

function CompetitiveManager:GetAnimeCollaborationEvents(eventType)
    if not eventType then
        -- Return all collaboration events
        local allEvents = {}
        for _, eventCategory in pairs(self.animeCollaborationEvents) do
            for eventId, event in pairs(eventCategory.activeEvents or {}) do
                table.insert(allEvents, event)
            end
        end
        return allEvents
    end
    
    -- Return events for specific type
    if self.animeCollaborationEvents[eventType] and self.animeCollaborationEvents[eventType].activeEvents then
        local events = {}
        for eventId, event in pairs(self.animeCollaborationEvents[eventType].activeEvents) do
            table.insert(events, event)
        end
        return events
    end
    
    return {}
end

function CompetitiveManager:GetAnimeCompetitiveMetrics()
    local metrics = {
        totalAnimeThemes = #self.animeLeaderboardCategories,
        activeChallenges = 0,
        activeBattles = 0,
        activeTournaments = 0,
        activeCollaborationEvents = 0,
        totalParticipants = 0
    }
    
    -- Count active challenges
    for _, themeChallenges in pairs(self.themeSpecificChallenges) do
        for _, typeChallenges in pairs(themeChallenges) do
            metrics.activeChallenges = metrics.activeChallenges + #(typeChallenges.activeChallenges or {})
        end
    end
    
    -- Count active battles
    for _, battleCategory in pairs(self.animeCharacterBattles) do
        metrics.activeBattles = metrics.activeBattles + #(battleCategory.activeBattles or {})
    end
    
    -- Count active tournaments
    for _, tournament in pairs(self.crossAnimeTournaments) do
        if tournament.status == "Active" or tournament.status == "Registration" then
            metrics.activeTournaments = metrics.activeTournaments + 1
        end
    end
    
    -- Count active collaboration events
    for _, eventCategory in pairs(self.animeCollaborationEvents) do
        metrics.activeCollaborationEvents = metrics.activeCollaborationEvents + #(eventCategory.activeEvents or {})
    end
    
    -- Count total participants across all systems
    local uniqueParticipants = {}
    for _, themeChallenges in pairs(self.themeSpecificChallenges) do
        for _, typeChallenges in pairs(themeChallenges) do
            for _, challenge in pairs(typeChallenges.activeChallenges or {}) do
                for userId, _ in pairs(challenge.participants or {}) do
                    uniqueParticipants[userId] = true
                end
            end
        end
    end
    
    metrics.totalParticipants = 0
    for _ in pairs(uniqueParticipants) do
        metrics.totalParticipants = metrics.totalParticipants + 1
    end
    
    return metrics
end

-- Cleanup

function CompetitiveManager:Cleanup()
    print("CompetitiveManager: Cleaning up...")
    
    -- Disconnect all connections
    -- Clean up remote events
    -- Reset data structures
    
    print("CompetitiveManager: Cleanup completed")
end

-- Initialize anime ranking seasons
function CompetitiveManager:InitializeAnimeRankingSeasons()
    local currentTime = tick()
    
    -- Create ranking seasons for each anime theme
    for _, animeTheme in ipairs(self.animeLeaderboardCategories) do
        local seasonId = "RANKING_" .. animeTheme .. "_" .. self.currentSeason
        self.animeRankingSeasons[seasonId] = {
            id = seasonId,
            animeTheme = animeTheme,
            season = self.currentSeason,
            startTime = currentTime,
            endTime = currentTime + self.seasonDuration,
            participants = {},
            rankings = {},
            rewards = {},
            status = "Active"
        }
    end
    
    print("CompetitiveManager: Anime ranking seasons initialized")
end

-- Initialize anime fusion battle system
function CompetitiveManager:InitializeAnimeFusionBattles()
    self.animeFusionBattles = {
        activeFusions = {},
        fusionHistory = {},
        fusionRules = {},
        fusionRewards = {},
        fusionRankings = {}
    }
    
    -- Initialize fusion rules for different anime themes
    local fusionTypes = {
        "POWER_FUSION",
        "SKILL_FUSION", 
        "ELEMENTAL_FUSION",
        "CHARACTER_FUSION",
        "THEME_FUSION"
    }
    
    for _, fusionType in ipairs(fusionTypes) do
        self.animeFusionBattles.fusionRules[fusionType] = {
            requirements = {},
            multipliers = {},
            restrictions = {},
            specialEffects = {}
        }
    end
    
    print("CompetitiveManager: Anime fusion battle system initialized")
end

-- Initialize anime seasonal challenges
function CompetitiveManager:InitializeAnimeSeasonalChallenges()
    self.animeSeasonalChallenges = {
        activeChallenges = {},
        challengeHistory = {},
        seasonalRewards = {},
        challengeLeaderboards = {}
    }
    
    -- Create seasonal challenges for each anime theme
    for _, animeTheme in ipairs(self.animeLeaderboardCategories) do
        local challengeId = "SEASONAL_CHALLENGE_" .. animeTheme .. "_" .. self.currentSeason
        self.animeSeasonalChallenges.activeChallenges[challengeId] = {
            id = challengeId,
            animeTheme = animeTheme,
            season = self.currentSeason,
            title = "Seasonal " .. animeTheme .. " Challenge",
            description = "Complete seasonal objectives for " .. animeTheme,
            objectives = {},
            rewards = {},
            participants = {},
            startTime = tick(),
            endTime = tick() + self.seasonDuration,
            status = "Active"
        }
    end
    
    print("CompetitiveManager: Anime seasonal challenges initialized")
end

-- Initialize anime power scaling system
function CompetitiveManager:InitializeAnimePowerScaling()
    self.animePowerScaling = {
        powerLevels = {},
        scalingFactors = {},
        powerCurves = {},
        scalingEvents = {},
        powerRankings = {}
    }
    
    -- Initialize power scaling for each anime theme
    for _, animeTheme in ipairs(self.animeLeaderboardCategories) do
        self.animePowerScaling.powerLevels[animeTheme] = {
            basePower = 100,
            maxPower = 10000,
            scalingRate = 1.5,
            powerCurve = "exponential",
            specialMultipliers = {}
        }
    end
    
    print("CompetitiveManager: Anime power scaling system initialized")
end

-- Initialize anime character evolution tracking
function CompetitiveManager:InitializeAnimeCharacterEvolution()
    self.animeCharacterEvolution = {
        evolutionPaths = {},
        evolutionRequirements = {},
        evolutionRewards = {},
        evolutionHistory = {},
        evolutionRankings = {}
    }
    
    -- Initialize evolution paths for each anime theme
    for _, animeTheme in ipairs(self.animeLeaderboardCategories) do
        self.animeCharacterEvolution.evolutionPaths[animeTheme] = {
            stages = {},
            requirements = {},
            rewards = {},
            specialEvolutions = {}
        }
    end
    
    print("CompetitiveManager: Anime character evolution system initialized")
end

-- Initialize anime world events
function CompetitiveManager:InitializeAnimeWorldEvents()
    self.animeWorldEvents = {
        activeEvents = {},
        eventHistory = {},
        eventTypes = {},
        worldRewards = {},
        eventLeaderboards = {}
    }
    
    -- Initialize world event types
    local eventTypes = {
        "WORLD_INVASION",
        "DIMENSIONAL_RIFT",
        "CHARACTER_INVASION",
        "THEME_COLLISION",
        "UNIVERSAL_THREAT"
    }
    
    for _, eventType in ipairs(eventTypes) do
        self.animeWorldEvents.eventTypes[eventType] = {
            description = "",
            requirements = {},
            rewards = {},
            duration = 0,
            maxParticipants = 0
        }
    end
    
    print("CompetitiveManager: Anime world events system initialized")
end

-- Initialize anime guild warfare system
function CompetitiveManager:InitializeAnimeGuildWars()
    self.animeGuildWars = {
        activeWars = {},
        warHistory = {},
        warTypes = {},
        warRewards = {},
        warRankings = {}
    }
    
    -- Initialize war types
    local warTypes = {
        "THEME_WAR",
        "POWER_WAR",
        "SKILL_WAR",
        "RESOURCE_WAR",
        "TERRITORY_WAR"
    }
    
    for _, warType in ipairs(warTypes) do
        self.animeGuildWars.warTypes[warType] = {
            description = "",
            requirements = {},
            duration = 0,
            maxGuilds = 0,
            rewards = {}
        }
    end
    
    print("CompetitiveManager: Anime guild warfare system initialized")
end

-- Initialize anime trading card system
function CompetitiveManager:InitializeAnimeTradingCards()
    self.animeTradingCards = {
        cardDatabase = {},
        playerCollections = {},
        tradingMarket = {},
        cardRarities = {},
        cardEffects = {}
    }
    
    -- Initialize card rarities
    local rarities = {
        "COMMON",
        "UNCOMMON", 
        "RARE",
        "EPIC",
        "LEGENDARY",
        "MYTHIC"
    }
    
    for _, rarity in ipairs(rarities) do
        self.animeTradingCards.cardRarities[rarity] = {
            dropRate = 0,
            powerMultiplier = 1.0,
            specialEffects = {}
        }
    end
    
    print("CompetitiveManager: Anime trading card system initialized")
end

-- Initialize anime character mentorship system
function CompetitiveManager:InitializeAnimeCharacterMentorship()
    self.animeCharacterMentorship = {
        activeMentorships = {},
        mentorshipHistory = {},
        mentorshipTypes = {},
        mentorshipRewards = {},
        mentorshipRankings = {}
    }
    
    -- Initialize mentorship types
    local mentorshipTypes = {
        "POWER_TRAINING",
        "SKILL_DEVELOPMENT",
        "CHARACTER_GROWTH",
        "THEME_MASTERY",
        "BATTLE_STRATEGY"
    }
    
    for _, mentorshipType in ipairs(mentorshipTypes) do
        self.animeCharacterMentorship.mentorshipTypes[mentorshipType] = {
            description = "",
            requirements = {},
            duration = 0,
            rewards = {},
            maxStudents = 0
        }
    end
    
    print("CompetitiveManager: Anime character mentorship system initialized")
end

-- Initialize anime crossover events
function CompetitiveManager:InitializeAnimeCrossOverEvents()
    self.animeCrossOverEvents = {
        activeCrossovers = {},
        crossoverHistory = {},
        crossoverTypes = {},
        crossoverRewards = {},
        crossoverRankings = {}
    }
    
    -- Initialize crossover types
    local crossoverTypes = {
        "CHARACTER_CROSSOVER",
        "THEME_CROSSOVER",
        "POWER_CROSSOVER",
        "STORY_CROSSOVER",
        "WORLD_CROSSOVER"
    }
    
    for _, crossoverType in ipairs(crossoverTypes) do
        self.animeCrossOverEvents.crossoverTypes[crossoverType] = {
            description = "",
            requirements = {},
            duration = 0,
            rewards = {},
            maxParticipants = 0
        }
    end
    
    print("CompetitiveManager: Anime crossover events system initialized")
end

-- Core functionality for enhanced anime competitive systems

-- Start a fusion battle between characters
function CompetitiveManager:StartFusionBattle(player1, player2, animeTheme, fusionType)
    local fusionId = HttpService:GenerateGUID(false)
    local currentTime = tick()
    
    local fusion = {
        id = fusionId,
        player1 = player1.UserId,
        player2 = player2.UserId,
        animeTheme = animeTheme,
        fusionType = fusionType,
        startTime = currentTime,
        status = "Active",
        fusionProgress = 0,
        winner = nil,
        rewards = {}
    }
    
    -- Add fusion to active fusions
    self.animeFusionBattles.activeFusions[fusionId] = fusion
    
    -- Notify players
    self:NotifyFusionBattleStart(player1, player2, fusion)
    
    print("CompetitiveManager: Fusion battle started between", player1.Name, "and", player2.Name)
    return fusionId
end

-- Process fusion battle
function CompetitiveManager:ProcessFusionBattle(fusionId, fusionData)
    local fusion = self.animeFusionBattles.activeFusions[fusionId]
    if not fusion then return false end
    
    -- Update fusion progress
    fusion.fusionProgress = math.min(100, fusion.fusionProgress + (fusionData.progress or 10))
    
    -- Check if fusion is complete
    if fusion.fusionProgress >= 100 then
        fusion.status = "Completed"
        fusion.winner = fusionData.winner or fusion.player1
        fusion.endTime = tick()
        
        -- Process fusion completion
        self:CompleteFusionBattle(fusion)
    end
    
    return true
end

-- Complete fusion battle and award rewards
function CompetitiveManager:CompleteFusionBattle(fusion)
    local winner = Players:GetPlayerByUserId(fusion.winner)
    local loser = Players:GetPlayerByUserId(fusion.player1 == fusion.winner and fusion.player2 or fusion.player1)
    
    if winner and loser then
        -- Calculate fusion rewards
        local rewards = self:CalculateFusionRewards(fusion)
        
        -- Award rewards
        self:GrantFusionRewards(winner, rewards.winner)
        self:GrantFusionRewards(loser, rewards.loser)
        
        -- Update fusion rankings
        self:UpdateFusionRankings(fusion)
        
        -- Move fusion to history
        self:MoveFusionToHistory(fusion)
        
        -- Notify players
        self:NotifyFusionBattleCompletion(winner, loser, fusion, rewards)
        
        print("CompetitiveManager: Fusion battle completed. Winner:", winner.Name)
    end
end

-- Calculate fusion battle rewards
function CompetitiveManager:CalculateFusionRewards(fusion)
    local baseRewards = {
        winner = { points = 200, cash = 1000, experience = 400, fusionPoints = 50 },
        loser = { points = 50, cash = 200, experience = 100, fusionPoints = 10 }
    }
    
    -- Apply fusion type multipliers
    local fusionMultiplier = 1.0
    if fusion.fusionType == "POWER_FUSION" then
        fusionMultiplier = 1.5
    elseif fusion.fusionType == "SKILL_FUSION" then
        fusionMultiplier = 1.3
    elseif fusion.fusionType == "ELEMENTAL_FUSION" then
        fusionMultiplier = 1.4
    elseif fusion.fusionType == "CHARACTER_FUSION" then
        fusionMultiplier = 1.6
    elseif fusion.fusionType == "THEME_FUSION" then
        fusionMultiplier = 1.8
    end
    
    return {
        winner = {
            points = math.floor(baseRewards.winner.points * fusionMultiplier),
            cash = math.floor(baseRewards.winner.cash * fusionMultiplier),
            experience = math.floor(baseRewards.winner.experience * fusionMultiplier),
            fusionPoints = math.floor(baseRewards.winner.fusionPoints * fusionMultiplier)
        },
        loser = baseRewards.loser
    }
end

-- Grant fusion rewards to player
function CompetitiveManager:GrantFusionRewards(player, rewards)
    if not player or not rewards then return false end
    
    -- Grant all reward types
    if rewards.points and rewards.points > 0 then
        self:GrantPointsToPlayer(player, rewards.points)
    end
    
    if rewards.cash and rewards.cash > 0 then
        self:GrantCashToPlayer(player, rewards.cash)
    end
    
    if rewards.experience and rewards.experience > 0 then
        self:GrantExperienceToPlayer(player, rewards.experience)
    end
    
    if rewards.fusionPoints and rewards.fusionPoints > 0 then
        self:GrantFusionPointsToPlayer(player, rewards.fusionPoints)
    end
    
    return true
end

-- Update fusion rankings after battle
function CompetitiveManager:UpdateFusionRankings(fusion)
    local winner = fusion.winner
    local loser = fusion.player1 == winner and fusion.player2 or fusion.player1
    
    -- Update winner ranking
    if not self.animeFusionBattles.fusionRankings[fusion.animeTheme] then
        self.animeFusionBattles.fusionRankings[fusion.animeTheme] = {}
    end
    
    if not self.animeFusionBattles.fusionRankings[fusion.animeTheme][winner] then
        self.animeFusionBattles.fusionRankings[fusion.animeTheme][winner] = {
            wins = 0,
            losses = 0,
            rating = 1000,
            fusionPoints = 0
        }
    end
    
    local winnerData = self.animeFusionBattles.fusionRankings[fusion.animeTheme][winner]
    winnerData.wins = winnerData.wins + 1
    winnerData.rating = winnerData.rating + 30
    winnerData.fusionPoints = winnerData.fusionPoints + 50
    
    -- Update loser ranking
    if not self.animeFusionBattles.fusionRankings[fusion.animeTheme][loser] then
        self.animeFusionBattles.fusionRankings[fusion.animeTheme][loser] = {
            wins = 0,
            losses = 0,
            rating = 1000,
            fusionPoints = 0
        }
    end
    
    local loserData = self.animeFusionBattles.fusionRankings[fusion.animeTheme][loser]
    loserData.losses = loserData.losses + 1
    loserData.rating = math.max(100, loserData.rating - 20)
    loserData.fusionPoints = loserData.fusionPoints + 10
end

-- Move fusion battle to history
function CompetitiveManager:MoveFusionToHistory(fusion)
    -- Remove from active fusions
    self.animeFusionBattles.activeFusions[fusion.id] = nil
    
    -- Add to fusion history
    self.animeFusionBattles.fusionHistory[fusion.id] = fusion
end

-- Create seasonal anime challenge
function CompetitiveManager:CreateSeasonalAnimeChallenge(animeTheme, challengeData)
    local challengeId = HttpService:GenerateGUID(false)
    local currentTime = tick()
    
    local challenge = {
        id = challengeId,
        animeTheme = animeTheme,
        title = challengeData.title,
        description = challengeData.description,
        objectives = challengeData.objectives or {},
        rewards = challengeData.rewards or {},
        participants = {},
        startTime = currentTime,
        endTime = currentTime + (challengeData.duration or 86400),
        status = "Active"
    }
    
    -- Add challenge to seasonal challenges
    self.animeSeasonalChallenges.activeChallenges[challengeId] = challenge
    
    -- Broadcast challenge creation
    self:BroadcastSeasonalChallengeCreated(challenge)
    
    print("CompetitiveManager: Seasonal anime challenge created:", challenge.title)
    return challengeId
end

-- Join seasonal anime challenge
function CompetitiveManager:JoinSeasonalAnimeChallenge(player, challengeId)
    local challenge = self.animeSeasonalChallenges.activeChallenges[challengeId]
    if not challenge or challenge.status ~= "Active" then
        return false, "Challenge not available"
    end
    
    local userId = player.UserId
    
    -- Check if player already joined
    if challenge.participants[userId] then
        return false, "Already joined challenge"
    end
    
    -- Add player to challenge
    challenge.participants[userId] = {
        playerName = player.Name,
        joinTime = tick(),
        progress = 0,
        objectives = {},
        completed = false
    }
    
    print("CompetitiveManager: Player", player.Name, "joined seasonal challenge:", challenge.title)
    return true
end

-- Update seasonal challenge progress
function CompetitiveManager:UpdateSeasonalChallengeProgress(player, challengeId, objectiveId, progress)
    local challenge = self.animeSeasonalChallenges.activeChallenges[challengeId]
    if not challenge then return false end
    
    local userId = player.UserId
    local participant = challenge.participants[userId]
    
    if not participant then return false end
    
    -- Update objective progress
    if not participant.objectives[objectiveId] then
        participant.objectives[objectiveId] = 0
    end
    
    participant.objectives[objectiveId] = math.max(participant.objectives[objectiveId], progress)
    
    -- Calculate overall progress
    local totalProgress = 0
    local objectiveCount = 0
    
    for _, objProgress in pairs(participant.objectives) do
        totalProgress = totalProgress + objProgress
        objectiveCount = objectiveCount + 1
    end
    
    participant.progress = objectiveCount > 0 and (totalProgress / objectiveCount) or 0
    
    -- Check if challenge completed
    if participant.progress >= 100 and not participant.completed then
        participant.completed = true
        participant.completionTime = tick()
        
        -- Award completion rewards
        self:GrantSeasonalChallengeRewards(player, challenge)
    end
    
    return true
end

-- Grant seasonal challenge rewards
function CompetitiveManager:GrantSeasonalChallengeRewards(player, challenge)
    if not player or not challenge or not challenge.rewards then return false end
    
    local rewards = challenge.rewards
    
    -- Grant all reward types
    if rewards.points and rewards.points > 0 then
        self:GrantPointsToPlayer(player, rewards.points)
    end
    
    if rewards.cash and rewards.cash > 0 then
        self:GrantCashToPlayer(player, rewards.cash)
    end
    
    if rewards.experience and rewards.experience > 0 then
        self:GrantExperienceToPlayer(player, rewards.experience)
    end
    
    if rewards.items and #rewards.items > 0 then
        for _, item in ipairs(rewards.items) do
            self:GrantItemToPlayer(player, item.id, item.quantity or 1)
        end
    end
    
    print("CompetitiveManager: Granted seasonal challenge rewards to", player.Name)
    return true
end

-- Start anime guild war
function CompetitiveManager:StartAnimeGuildWar(guild1, guild2, warType, animeTheme)
    local warId = HttpService:GenerateGUID(false)
    local currentTime = tick()
    
    local war = {
        id = warId,
        guild1 = guild1.id,
        guild2 = guild2.id,
        warType = warType,
        animeTheme = animeTheme,
        startTime = currentTime,
        duration = 7 * 24 * 60 * 60, -- 7 days
        status = "Active",
        battles = {},
        guild1Score = 0,
        guild2Score = 0,
        winner = nil,
        rewards = {}
    }
    
    -- Add war to active wars
    self.animeGuildWars.activeWars[warId] = war
    
    -- Notify guilds
    self:NotifyGuildWarStart(guild1, guild2, war)
    
    print("CompetitiveManager: Guild war started between", guild1.name, "and", guild2.name)
    return warId
end

-- Process guild war battle
function CompetitiveManager:ProcessGuildWarBattle(warId, battleData)
    local war = self.animeGuildWars.activeWars[warId]
    if not war then return false end
    
    local battle = {
        id = HttpService:GenerateGUID(false),
        player1 = battleData.player1,
        player2 = battleData.player2,
        winner = battleData.winner,
        timestamp = tick()
    }
    
    table.insert(war.battles, battle)
    
    -- Update guild scores
    if battle.winner == battle.player1 then
        war.guild1Score = war.guild1Score + 1
    else
        war.guild2Score = war.guild2Score + 1
    end
    
    -- Check if war should end
    if #war.battles >= 10 or (tick() - war.startTime) >= war.duration then
        self:EndGuildWar(war)
    end
    
    return true
end

-- End guild war and determine winner
function CompetitiveManager:EndGuildWar(war)
    if war.guild1Score > war.guild2Score then
        war.winner = war.guild1
    elseif war.guild2Score > war.guild1Score then
        war.winner = war.guild2
    else
        war.winner = "Tie"
    end
    
    war.status = "Completed"
    war.endTime = tick()
    
    -- Award war rewards
    self:AwardGuildWarRewards(war)
    
    -- Move war to history
    self:MoveGuildWarToHistory(war)
    
    print("CompetitiveManager: Guild war ended. Winner:", war.winner)
end

-- Award guild war rewards
function CompetitiveManager:AwardGuildWarRewards(war)
    if war.winner == "Tie" then
        -- Award consolation rewards to both guilds
        self:AwardGuildWarRewardsToGuild(war.guild1, war.rewards.consolation)
        self:AwardGuildWarRewardsToGuild(war.guild2, war.rewards.consolation)
    else
        -- Award winner rewards
        self:AwardGuildWarRewardsToGuild(war.winner, war.rewards.winner)
        
        -- Award loser consolation rewards
        local loser = war.winner == war.guild1 and war.guild2 or war.guild1
        self:AwardGuildWarRewardsToGuild(loser, war.rewards.loser)
    end
end

-- Award guild war rewards to guild
function CompetitiveManager:AwardGuildWarRewardsToGuild(guildId, rewards)
    -- This would integrate with your existing guild system
    -- For now, we'll use a placeholder
    print("CompetitiveManager: Would award guild war rewards to guild", guildId, ":", rewards)
end

-- Move guild war to history
function CompetitiveManager:MoveGuildWarToHistory(war)
    -- Remove from active wars
    self.animeGuildWars.activeWars[war.id] = nil
    
    -- Add to war history
    self.animeGuildWars.warHistory[war.id] = war
end

-- Helper functions for enhanced anime competitive systems
function CompetitiveManager:GrantFusionPointsToPlayer(player, points)
    -- This would integrate with your existing fusion points system
    if not player or not points or points <= 0 then return false end
    
    -- Example integration - replace with your actual fusion points system
    local success, result = pcall(function()
        -- Try to access your existing fusion points system
        if player:FindFirstChild("leaderstats") then
            local fusionPointsValue = player.leaderstats:FindFirstChild("FusionPoints")
            if fusionPointsValue then
                fusionPointsValue.Value = fusionPointsValue.Value + points
                return true
            end
        end
        return false
    end)
    
    return success and result or false
end

-- Notification functions for enhanced anime competitive systems
function CompetitiveManager:NotifyFusionBattleStart(player1, player2, fusion)
    if self.remoteEvents.CompetitiveAction then
        self.remoteEvents.CompetitiveAction:FireClient(player1, "FUSION_BATTLE_START", fusion)
        self.remoteEvents.CompetitiveAction:FireClient(player2, "FUSION_BATTLE_START", fusion)
    end
end

function CompetitiveManager:NotifyFusionBattleCompletion(winner, loser, fusion, rewards)
    if self.remoteEvents.CompetitiveAction then
        self.remoteEvents.CompetitiveAction:FireClient(winner, "FUSION_BATTLE_COMPLETE", { fusion = fusion, rewards = rewards.winner, result = "WIN" })
        self.remoteEvents.CompetitiveAction:FireClient(loser, "FUSION_BATTLE_COMPLETE", { fusion = fusion, rewards = rewards.loser, result = "LOSS" })
    end
end

function CompetitiveManager:BroadcastSeasonalChallengeCreated(challenge)
    if self.remoteEvents.CompetitiveAction then
        self.remoteEvents.CompetitiveAction:FireAllClients("SEASONAL_CHALLENGE_CREATED", challenge)
    end
end

function CompetitiveManager:NotifyGuildWarStart(guild1, guild2, war)
    -- This would integrate with your existing guild system to notify all guild members
    print("CompetitiveManager: Notifying guilds of war start:", guild1.name, "vs", guild2.name)
end

-- Duplicate functions removed - these are already defined earlier in the file

return CompetitiveManager
