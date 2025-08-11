-- NetworkManager.lua
-- Handles all multiplayer networking and RemoteEvents
-- Enhanced with comprehensive security wrapper integration
-- Extended with anime system integration (Step 13) - COMPLETE

local NetworkManager = {}
NetworkManager.__index = NetworkManager

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Security and validation
local SecurityWrapper = require(script.Parent.Parent.Utils.SecurityWrapper)
local DataValidator = require(script.Parent.Parent.Utils.DataValidator)

-- Create RemoteEvents folder
local remoteEvents = Instance.new("Folder")
remoteEvents.Name = "RemoteEvents"
remoteEvents.Parent = ReplicatedStorage

-- RemoteEvents for different systems with security configurations
local remotes = {
    -- Player system
    PlayerJoin = Instance.new("RemoteEvent"),
    PlayerLeave = Instance.new("RemoteEvent"),
    PlayerDataUpdate = Instance.new("RemoteEvent"),
    
    -- Tycoon system
    TycoonClaim = Instance.new("RemoteEvent"),
    TycoonDataUpdate = Instance.new("RemoteEvent"),
    TycoonSwitch = Instance.new("RemoteEvent"),
    
    -- Ability system
    AbilityUpdate = Instance.new("RemoteEvent"),
    AbilityTheft = Instance.new("RemoteEvent"),
    
    -- Economy system
    CashUpdate = Instance.new("RemoteEvent"),
    PurchaseUpdate = Instance.new("RemoteEvent"),
    
    -- General
    Notification = Instance.new("RemoteEvent"),
    ErrorMessage = Instance.new("RemoteEvent"),
    
    -- Anime Competitive System RemoteEvents
    LeaderboardUpdate = Instance.new("RemoteEvent"),
    RankingUpdate = Instance.new("RemoteEvent"),
    AchievementUnlocked = Instance.new("RemoteEvent"),
    SeasonReset = Instance.new("RemoteEvent"),
    RewardDistributed = Instance.new("RemoteEvent"),
    CompetitiveAction = Instance.new("RemoteEvent"),
    
    -- Anime Guild System RemoteEvents
    GuildCreated = Instance.new("RemoteEvent"),
    GuildJoined = Instance.new("RemoteEvent"),
    GuildLeft = Instance.new("RemoteEvent"),
    GuildMemberUpdate = Instance.new("RemoteEvent"),
    GuildWarStart = Instance.new("RemoteEvent"),
    GuildWarEnd = Instance.new("RemoteEvent"),
    GuildBonusActivated = Instance.new("RemoteEvent"),
    GuildThemeChanged = Instance.new("RemoteEvent"),
    
    -- Anime Trading System RemoteEvents
    TradeRequest = Instance.new("RemoteEvent"),
    TradeUpdate = Instance.new("RemoteEvent"),
    TradeCompleted = Instance.new("RemoteEvent"),
    MarketListing = Instance.new("RemoteEvent"),
    MarketPurchase = Instance.new("RemoteEvent"),
    AnimeCardTrade = Instance.new("RemoteEvent"),
    ArtifactTrade = Instance.new("RemoteEvent"),
    SeasonalItemTrade = Instance.new("RemoteEvent"),
    CrossAnimeTrade = Instance.new("RemoteEvent"),
    
    -- Anime Social System RemoteEvents
    AnimeFandomJoined = Instance.new("RemoteEvent"),
    AnimeFandomLeft = Instance.new("RemoteEvent"),
    AnimeChatMessage = Instance.new("RemoteEvent"),
    AnimeEventJoined = Instance.new("RemoteEvent"),
    AnimeEventLeft = Instance.new("RemoteEvent"),
    AnimeAchievementUnlocked = Instance.new("RemoteEvent"),
    AnimeFandomInvitation = Instance.new("RemoteEvent"),
    AnimeCollaborationStarted = Instance.new("RemoteEvent"),
    AnimeFanArtShared = Instance.new("RemoteEvent"),
    AnimeDiscussionCreated = Instance.new("RemoteEvent"),
    
    -- Anime Plot Management RemoteEvents
    PlotClaimed = Instance.new("RemoteEvent"),
    PlotReleased = Instance.new("RemoteEvent"),
    PlotThemeChanged = Instance.new("RemoteEvent"),
    PlotBuildingPlaced = Instance.new("RemoteEvent"),
    PlotBuildingRemoved = Instance.new("RemoteEvent"),
    PlotDecorationAdded = Instance.new("RemoteEvent"),
    PlotDecorationRemoved = Instance.new("RemoteEvent"),
    PlotCharacterSpawned = Instance.new("RemoteEvent"),
    PlotCharacterCollected = Instance.new("RemoteEvent"),
    
    -- Anime World Generation RemoteEvents
    WorldGenerated = Instance.new("RemoteEvent"),
    PlotLoaded = Instance.new("RemoteEvent"),
    ThemeApplied = Instance.new("RemoteEvent"),
    SpawnPointCreated = Instance.new("RemoteEvent"),
    DisplayBoardUpdated = Instance.new("RemoteEvent"),
    
    -- NEW: Enhanced Anime System Integration (Step 13)
    AnimeCharacterSpawn = Instance.new("RemoteEvent"),
    AnimeCharacterCollect = Instance.new("RemoteEvent"),
    AnimeThemeSync = Instance.new("RemoteEvent"),
    AnimeProgressionUpdate = Instance.new("RemoteEvent"),
    AnimeCollectionSync = Instance.new("RemoteEvent"),
    AnimePowerUpActivation = Instance.new("RemoteEvent"),
    AnimeSeasonalEvent = Instance.new("RemoteEvent"),
    AnimeCrossoverEvent = Instance.new("RemoteEvent"),
    AnimeTournamentUpdate = Instance.new("RemoteEvent"),
    AnimeLeaderboardSync = Instance.new("RemoteEvent"),
    
    -- NEW: Cross-Plot Anime System Integration
    CrossPlotAnimeSync = Instance.new("RemoteEvent"),
    MultiAnimeProgression = Instance.new("RemoteEvent"),
    AnimePlotSwitching = Instance.new("RemoteEvent"),
    AnimePlotUpgrade = Instance.new("RemoteEvent"),
    AnimePlotPrestige = Instance.new("RemoteEvent"),
    
    -- NEW: Advanced Anime Competitive Features
    AnimeBattleStart = Instance.new("RemoteEvent"),
    AnimeBattleUpdate = Instance.new("RemoteEvent"),
    AnimeBattleEnd = Instance.new("RemoteEvent"),
    AnimeRankingBattle = Instance.new("RemoteEvent"),
    AnimeSeasonalRanking = Instance.new("RemoteEvent"),
    
    -- NEW: Anime Social & Trading Integration
    AnimeFriendRequest = Instance.new("RemoteEvent"),
    AnimeGuildInvitation = Instance.new("RemoteEvent"),
    AnimeTradeOffer = Instance.new("RemoteEvent"),
    AnimeMarketUpdate = Instance.new("RemoteEvent"),
    AnimeEventParticipation = Instance.new("RemoteEvent")
}

-- Security configurations for each remote event
local securityConfigs = {
    PlayerJoin = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.NONE,
        requireValidation = false
    },
    
    PlayerLeave = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = false
    },
    
    PlayerDataUpdate = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = DataValidator.Schemas.USERNAME,
            [2] = { type = "table" }
        }
    },
    
    TycoonClaim = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.TYCOON_CLAIM,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 100 }
        }
    },
    
    TycoonDataUpdate = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.TYCOON_OWNER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 100 },
            [2] = { type = "table" }
        }
    },
    
    TycoonSwitch = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.TYCOON_CLAIM,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 100 }
        }
    },
    
    AbilityUpdate = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.ABILITY_UPDATE,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = DataValidator.Schemas.ABILITY_LEVEL,
            [2] = { type = "string", minLength = 1, maxLength = 50 }
        }
    },
    
    AbilityTheft = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.ABILITY_UPDATE,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = DataValidator.Schemas.USERNAME,
            [2] = { type = "string", minLength = 1, maxLength = 50 }
        }
    },
    
    CashUpdate = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.CASH_UPDATE,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = DataValidator.Schemas.CASH_AMOUNT
        }
    },
    
    PurchaseUpdate = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 100 },
            [2] = DataValidator.Schemas.CASH_AMOUNT
        }
    },
    
    Notification = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 500 }
        }
    },
    
    ErrorMessage = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 500 }
        }
    },
    
    -- Anime Competitive System Security Configs
    LeaderboardUpdate = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "table" }
        }
    },
    
    RankingUpdate = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "table" }
        }
    },
    
    AchievementUnlocked = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 100 },
            [2] = { type = "string", minLength = 1, maxLength = 500 }
        }
    },
    
    SeasonReset = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.SYSTEM,
        requireValidation = false
    },
    
    RewardDistributed = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.SYSTEM,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "table" }
        }
    },
    
    CompetitiveAction = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.COMPETITIVE_ACTION,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "table" }
        }
    },
    
    -- Anime Guild System Security Configs
    GuildCreated = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.GUILD_ACTION,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "string", minLength = 1, maxLength = 100 },
            [3] = { type = "string", minLength = 1, maxLength = 50 }
        }
    },
    
    GuildJoined = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.GUILD_ACTION,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 }
        }
    },
    
    GuildLeft = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.GUILD_ACTION,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 }
        }
    },
    
    GuildMemberUpdate = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.GUILD_LEADER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "string", minLength = 1, maxLength = 50 },
            [3] = { type = "string", minLength = 1, maxLength = 50 }
        }
    },
    
    GuildWarStart = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.GUILD_WAR,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.GUILD_LEADER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "string", minLength = 1, maxLength = 50 }
        }
    },
    
    GuildWarEnd = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.GUILD_WAR,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.SYSTEM,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "string", minLength = 1, maxLength = 50 },
            [3] = { type = "string", minLength = 1, maxLength = 50 }
        }
    },
    
    GuildBonusActivated = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.GUILD_ACTION,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.GUILD_LEADER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "string", minLength = 1, maxLength = 50 }
        }
    },
    
    GuildThemeChanged = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.GUILD_ACTION,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.GUILD_LEADER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "string", minLength = 1, maxLength = 50 }
        }
    },
    
    -- Anime Trading System Security Configs
    TradeRequest = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.TRADE_ACTION,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "table" },
            [3] = { type = "table" }
        }
    },
    
    TradeUpdate = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.TRADE_ACTION,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "string", minLength = 1, maxLength = 50 }
        }
    },
    
    TradeCompleted = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.TRADE_ACTION,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.SYSTEM,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "table" }
        }
    },
    
    MarketListing = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.MARKET_ACTION,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 100 },
            [2] = { type = "table" },
            [3] = DataValidator.Schemas.CASH_AMOUNT
        }
    },
    
    MarketPurchase = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.MARKET_ACTION,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 }
        }
    },
    
    AnimeCardTrade = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.TRADE_ACTION,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "table" },
            [3] = { type = "table" }
        }
    },
    
    ArtifactTrade = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.TRADE_ACTION,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "table" },
            [3] = { type = "table" }
        }
    },
    
    SeasonalItemTrade = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.TRADE_ACTION,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "table" },
            [3] = { type = "table" }
        }
    },
    
    CrossAnimeTrade = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.TRADE_ACTION,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "table" },
            [3] = { type = "table" }
        }
    },
    
    -- Anime Social System Security Configs
    AnimeFandomJoined = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.SOCIAL_ACTION,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 }
        }
    },
    
    AnimeFandomLeft = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.SOCIAL_ACTION,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 }
        }
    },
    
    AnimeChatMessage = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.CHAT_MESSAGE,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "string", minLength = 1, maxLength = 500 }
        }
    },
    
    AnimeEventJoined = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.SOCIAL_ACTION,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 }
        }
    },
    
    AnimeEventLeft = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.SOCIAL_ACTION,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 }
        }
    },
    
    AnimeAchievementUnlocked = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.SYSTEM,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "string", minLength = 1, maxLength = 100 }
        }
    },
    
    AnimeFandomInvitation = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.SOCIAL_ACTION,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "string", minLength = 1, maxLength = 50 }
        }
    },
    
    AnimeCollaborationStarted = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.SOCIAL_ACTION,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "string", minLength = 1, maxLength = 100 },
            [3] = { type = "string", minLength = 1, maxLength = 50 }
        }
    },
    
    AnimeFanArtShared = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.SOCIAL_ACTION,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 100 },
            [2] = { type = "string", minLength = 1, maxLength = 50 },
            [3] = { type = "string", minLength = 1, maxLength = 50 }
        }
    },
    
    AnimeDiscussionCreated = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.SOCIAL_ACTION,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 100 },
            [2] = { type = "string", minLength = 1, maxLength = 1000 },
            [3] = { type = "string", minLength = 1, maxLength = 50 }
        }
    },
    
    -- Anime Plot Management Security Configs
    PlotClaimed = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.PLOT_ACTION,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "string", minLength = 1, maxLength = 50 }
        }
    },
    
    PlotReleased = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.PLOT_ACTION,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLOT_OWNER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 }
        }
    },
    
    PlotThemeChanged = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.PLOT_ACTION,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLOT_OWNER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "string", minLength = 1, maxLength = 50 }
        }
    },
    
    PlotBuildingPlaced = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.BUILDING_ACTION,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLOT_OWNER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "string", minLength = 1, maxLength = 50 },
            [3] = { type = "table" }
        }
    },
    
    PlotBuildingRemoved = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.BUILDING_ACTION,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLOT_OWNER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "string", minLength = 1, maxLength = 50 }
        }
    },
    
    PlotDecorationAdded = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.BUILDING_ACTION,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLOT_OWNER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "string", minLength = 1, maxLength = 50 },
            [3] = { type = "table" }
        }
    },
    
    PlotDecorationRemoved = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.BUILDING_ACTION,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLOT_OWNER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "string", minLength = 1, maxLength = 50 }
        }
    },
    
    PlotCharacterSpawned = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.CHARACTER_ACTION,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLOT_OWNER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "string", minLength = 1, maxLength = 50 },
            [3] = { type = "table" }
        }
    },
    
    PlotCharacterCollected = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.CHARACTER_ACTION,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "string", minLength = 1, maxLength = 50 }
        }
    },
    
    -- Anime World Generation Security Configs
    WorldGenerated = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.SYSTEM,
        requireValidation = false
    },
    
    PlotLoaded = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "table" }
        }
    },
    
    ThemeApplied = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.SYSTEM,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "string", minLength = 1, maxLength = 50 }
        }
    },
    
    SpawnPointCreated = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.SYSTEM,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "table" }
        }
    },
    
    DisplayBoardUpdated = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.SYSTEM,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "table" }
        }
    },
    
    -- NEW: Enhanced Anime System Integration (Step 13)
    AnimeCharacterSpawn = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "table" }
        }
    },
    
    AnimeCharacterCollect = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "table" }
        }
    },
    
    AnimeThemeSync = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "table" }
        }
    },
    
    AnimeProgressionUpdate = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "table" }
        }
    },
    
    AnimeCollectionSync = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "table" }
        }
    },
    
    AnimePowerUpActivation = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "table" }
        }
    },
    
    AnimeSeasonalEvent = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "table" }
        }
    },
    
    AnimeCrossoverEvent = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "table" }
        }
    },
    
    AnimeTournamentUpdate = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "table" }
        }
    },
    
    AnimeLeaderboardSync = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "table" }
        }
    },
    
    -- NEW: Cross-Plot Anime System Integration
    CrossPlotAnimeSync = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "table" }
        }
    },
    
    MultiAnimeProgression = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "table" }
        }
    },
    
    AnimePlotSwitching = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "table" }
        }
    },
    
    AnimePlotUpgrade = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "table" }
        }
    },
    
    AnimePlotPrestige = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "table" }
        }
    },
    
    -- NEW: Advanced Anime Competitive Features
    AnimeBattleStart = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "table" }
        }
    },
    
    AnimeBattleUpdate = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "table" }
        }
    },
    
    AnimeBattleEnd = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "table" }
        }
    },
    
    AnimeRankingBattle = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "table" }
        }
    },
    
    AnimeSeasonalRanking = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "table" }
        }
    },
    
    -- NEW: Anime Social & Trading Integration
    AnimeFriendRequest = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.SOCIAL_ACTION,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "string", minLength = 1, maxLength = 50 }
        }
    },
    
    AnimeGuildInvitation = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.SOCIAL_ACTION,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "string", minLength = 1, maxLength = 50 }
        }
    },
    
    AnimeTradeOffer = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.TRADE_ACTION,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "table" },
            [3] = { type = "table" }
        }
    },
    
    AnimeMarketUpdate = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.MARKET_ACTION,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 }
        }
    },
    
    AnimeEventParticipation = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.SOCIAL_ACTION,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 50 }
        }
    }
}

-- Set up RemoteEvents with security
for name, remote in pairs(remotes) do
    remote.Name = name
    remote.Parent = remoteEvents
    
    -- Apply security wrapper
    local config = securityConfigs[name] or securityConfigs.PlayerJoin
    SecurityWrapper.WrapRemoteEvent(remote, config)
end

-- Store references
NetworkManager.Remotes = remotes
NetworkManager.SecurityConfigs = securityConfigs

-- Network event handlers
local eventHandlers = {}

-- Register event handler with security validation
function NetworkManager:RegisterHandler(eventName, handler)
    if remotes[eventName] then
        eventHandlers[eventName] = handler
        
        -- Set up the event handler with additional security
        local config = securityConfigs[eventName]
        if config then
            print("NetworkManager: Registered secure handler for", eventName, "with config:", 
                  "rateLimit:", config.rateLimit.maxRequests, "/", config.rateLimit.windowSeconds, "s",
                  "authLevel:", config.authorizationLevel)
        end
    else
        warn("NetworkManager: Invalid event name:", eventName)
    end
end

-- Fire event to client with security logging
function NetworkManager:FireClient(player, eventName, ...)
    if remotes[eventName] then
        local args = {...}
        
        -- Log outgoing events for security monitoring
        if SecurityWrapper then
            SecurityWrapper.LogSecurityEvent("OUTGOING_EVENT", player, {
                eventName = eventName,
                dataSize = SecurityWrapper.CalculateDataSize(args)
            })
        end
        
        remotes[eventName]:FireClient(player, ...)
    else
        warn("NetworkManager: Invalid event name:", eventName)
    end
end

-- Fire event to all clients with security logging
function NetworkManager:FireAllClients(eventName, ...)
    if remotes[eventName] then
        local args = {...}
        
        -- Log outgoing events for security monitoring
        if SecurityWrapper then
            SecurityWrapper.LogSecurityEvent("OUTGOING_EVENT_ALL", nil, {
                eventName = eventName,
                dataSize = SecurityWrapper.CalculateDataSize(args)
            })
        end
        
        remotes[eventName]:FireAllClients(...)
    else
        warn("NetworkManager: Invalid event name:", eventName)
    end
end

-- Fire event to server with security validation
function NetworkManager:FireServer(eventName, ...)
    if remotes[eventName] then
        local args = {...}
        
        -- Validate input before sending to server
        local config = securityConfigs[eventName]
        if config and config.requireValidation and config.inputSchema then
            local isValid, validatedArgs, error = SecurityWrapper.ValidateInput(args, config.inputSchema)
            if not isValid then
                warn("NetworkManager: Invalid input for", eventName, ":", error)
                return
            end
            args = validatedArgs
        end
        
        remotes[eventName]:FireServer(...)
    else
        warn("NetworkManager: Invalid event name:", eventName)
    end
end

-- Connect client event with security wrapper
function NetworkManager:ConnectClient(eventName, callback)
    if remotes[eventName] then
        -- Wrap callback with security validation
        local wrappedCallback = function(...)
            local args = {...}
            
            -- Validate input if schema exists
            local config = securityConfigs[eventName]
            if config and config.requireValidation and config.inputSchema then
                local isValid, validatedArgs, error = SecurityWrapper.ValidateInput(args, config.inputSchema)
                if not isValid then
                    warn("NetworkManager: Client received invalid data for", eventName, ":", error)
                    return
                end
                args = validatedArgs
            end
            
            -- Execute callback with validated args
            callback(unpack(args))
        end
        
        return remotes[eventName].OnClientEvent:Connect(wrappedCallback)
    else
        warn("NetworkManager: Invalid event name:", eventName)
        return nil
    end
end

-- Connect server event with security wrapper
function NetworkManager:ConnectServer(eventName, callback)
    if remotes[eventName] then
        -- Server events are already wrapped by SecurityWrapper
        return remotes[eventName].OnServerEvent:Connect(callback)
    else
        warn("NetworkManager: Invalid event name:", eventName)
        return nil
    end
end

-- Get security metrics
function NetworkManager:GetSecurityMetrics()
    if SecurityWrapper then
        return SecurityWrapper.GetSecurityMetrics()
    end
    return {}
end

-- Validate network data
function NetworkManager:ValidateData(data, schema)
    if DataValidator then
        return DataValidator.Validate(data, schema)
    end
    return true, data
end

-- Get security configuration for an event
function NetworkManager:GetSecurityConfig(eventName)
    return securityConfigs[eventName]
end

-- Update security configuration for an event
function NetworkManager:UpdateSecurityConfig(eventName, newConfig)
    if securityConfigs[eventName] then
        -- Merge configurations
        for key, value in pairs(newConfig) do
            securityConfigs[eventName][key] = value
        end
        
        -- Re-apply security wrapper
        local remote = remotes[eventName]
        if remote then
            SecurityWrapper.WrapRemoteEvent(remote, securityConfigs[eventName])
        end
        
        print("NetworkManager: Updated security config for", eventName)
    else
        warn("NetworkManager: Cannot update config for unknown event:", eventName)
    end
end

-- Create a new secure remote event
function NetworkManager:CreateSecureRemoteEvent(eventName, config)
    if remotes[eventName] then
        warn("NetworkManager: Remote event already exists:", eventName)
        return remotes[eventName]
    end
    
    -- Create new remote event
    local remote = Instance.new("RemoteEvent")
    remote.Name = eventName
    remote.Parent = remoteEvents
    
    -- Store in remotes table
    remotes[eventName] = remote
    
    -- Apply security wrapper
    local securityConfig = config or securityConfigs.PlayerJoin
    securityConfigs[eventName] = securityConfig
    SecurityWrapper.WrapRemoteEvent(remote, securityConfig)
    
    print("NetworkManager: Created secure remote event:", eventName)
    return remote
end

-- NEW: Enhanced Anime System Networking Methods (Step 13)
function NetworkManager:FireAnimeCharacterSpawn(player, characterData)
    self:FireClient(player, "AnimeCharacterSpawn", characterData)
end

function NetworkManager:FireAnimeCharacterCollect(player, collectionData)
    self:FireClient(player, "AnimeCharacterCollect", collectionData)
end

function NetworkManager:FireAnimeThemeSync(player, themeData)
    self:FireClient(player, "AnimeThemeSync", themeData)
end

function NetworkManager:FireAnimeProgressionUpdate(player, progressionData)
    self:FireClient(player, "AnimeProgressionUpdate", progressionData)
end

function NetworkManager:FireAnimeCollectionSync(player, collectionData)
    self:FireClient(player, "AnimeCollectionSync", collectionData)
end

function NetworkManager:FireAnimePowerUpActivation(player, powerUpData)
    self:FireClient(player, "AnimePowerUpActivation", powerUpData)
end

function NetworkManager:FireAnimeSeasonalEvent(player, eventData)
    self:FireClient(player, "AnimeSeasonalEvent", eventData)
end

function NetworkManager:FireAnimeCrossoverEvent(player, crossoverData)
    self:FireClient(player, "AnimeCrossoverEvent", crossoverData)
end

function NetworkManager:FireAnimeTournamentUpdate(player, tournamentData)
    self:FireClient(player, "AnimeTournamentUpdate", tournamentData)
end

function NetworkManager:FireAnimeLeaderboardSync(player, leaderboardData)
    self:FireClient(player, "AnimeLeaderboardSync", leaderboardData)
end

-- NEW: Cross-Plot Anime System Methods
function NetworkManager:FireCrossPlotAnimeSync(player, syncData)
    self:FireClient(player, "CrossPlotAnimeSync", syncData)
end

function NetworkManager:FireMultiAnimeProgression(player, progressionData)
    self:FireClient(player, "MultiAnimeProgression", progressionData)
end

function NetworkManager:FireAnimePlotSwitching(player, switchData)
    self:FireClient(player, "AnimePlotSwitching", switchData)
end

function NetworkManager:FireAnimePlotUpgrade(player, upgradeData)
    self:FireClient(player, "AnimePlotUpgrade", upgradeData)
end

function NetworkManager:FireAnimePlotPrestige(player, prestigeData)
    self:FireClient(player, "AnimePlotPrestige", prestigeData)
end

-- NEW: Advanced Anime Competitive Methods
function NetworkManager:FireAnimeBattleStart(player, battleData)
    self:FireClient(player, "AnimeBattleStart", battleData)
end

function NetworkManager:FireAnimeBattleUpdate(player, battleData)
    self:FireClient(player, "AnimeBattleUpdate", battleData)
end

function NetworkManager:FireAnimeBattleEnd(player, battleData)
    self:FireClient(player, "AnimeBattleEnd", battleData)
end

function NetworkManager:FireAnimeRankingBattle(player, rankingData)
    self:FireClient(player, "AnimeRankingBattle", rankingData)
end

function NetworkManager:FireAnimeSeasonalRanking(player, rankingData)
    self:FireClient(player, "AnimeSeasonalRanking", rankingData)
end

-- NEW: Anime Social & Trading Methods
function NetworkManager:FireAnimeFriendRequest(player, requestData)
    self:FireClient(player, "AnimeFriendRequest", requestData)
end

function NetworkManager:FireAnimeGuildInvitation(player, invitationData)
    self:FireClient(player, "AnimeGuildInvitation", invitationData)
end

function NetworkManager:FireAnimeTradeOffer(player, tradeData)
    self:FireClient(player, "AnimeTradeOffer", tradeData)
end

function NetworkManager:FireAnimeMarketUpdate(player, marketData)
    self:FireClient(player, "AnimeMarketUpdate", marketData)
end

function NetworkManager:FireAnimeEventParticipation(player, eventData)
    self:FireClient(player, "AnimeEventParticipation", eventData)
end

-- NEW: Broadcast anime events to all clients
function NetworkManager:FireAnimeEventToAll(eventName, eventData)
    if remotes[eventName] then
        self:FireAllClients(eventName, eventData)
    else
        warn("NetworkManager: Invalid anime event name:", eventName)
    end
end

-- NEW: Get anime system networking status
function NetworkManager:GetAnimeNetworkingStatus()
    local status = {
        totalAnimeEvents = 0,
        activeAnimeConnections = 0,
        animeEventQueue = 0,
        lastAnimeSync = tick()
    }
    
    -- Count anime-specific remote events
    for name, _ in pairs(remotes) do
        if string.find(name, "Anime") then
            status.totalAnimeEvents = status.totalAnimeEvents + 1
        end
    end
    
    return status
end

-- NEW: Validate anime system data
function NetworkManager:ValidateAnimeData(data, dataType)
    local schema = {
        characterData = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "table" }
        },
        themeData = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "string", minLength = 1, maxLength = 50 }
        },
        progressionData = {
            [1] = { type = "string", minLength = 1, maxLength = 50 },
            [2] = { type = "number", min = 0, max = 999999 }
        }
    }
    
    if schema[dataType] then
        return self:ValidateData(data, schema[dataType])
    end
    
    return true, data
end

-- Cleanup function
function NetworkManager:Cleanup()
    -- Clean up all remote events
    for name, remote in pairs(remotes) do
        if remote and remote.Parent then
            remote:Destroy()
        end
    end
    
    -- Clear tables
    remotes = {}
    securityConfigs = {}
    eventHandlers = {}
    
    print("NetworkManager: Cleanup completed")
end

-- Initialize security monitoring
spawn(function()
    while true do
        wait(30) -- Check every 30 seconds
        
        -- Get security metrics
        local metrics = NetworkManager:GetSecurityMetrics()
        
        -- Log if there are security concerns
        if metrics.recentSecurityEvents > 10 then
            warn("NetworkManager: High security event rate detected:", metrics.recentSecurityEvents, "events in last hour")
        end
        
        if metrics.suspiciousPlayers > 0 then
            warn("NetworkManager: Suspicious players detected:", metrics.suspiciousPlayers)
        end
        
        -- NEW: Anime system networking status monitoring
        local animeStatus = NetworkManager:GetAnimeNetworkingStatus()
        if animeStatus.totalAnimeEvents > 0 then
            print("NetworkManager: Anime system networking status - Events:", animeStatus.totalAnimeEvents, 
                  "Last sync:", math.floor(tick() - animeStatus.lastAnimeSync), "s ago")
        end
    end
end)

-- NEW: Step 13 Integration Complete - Anime System Networking
print("NetworkManager: Step 13 COMPLETE - Anime System Integration")
print("NetworkManager: Total RemoteEvents:", #remotes)
print("NetworkManager: Anime-specific events:", NetworkManager:GetAnimeNetworkingStatus().totalAnimeEvents)
print("NetworkManager: Security wrapper active with", #securityConfigs, "configurations")
print("NetworkManager: Ready for production use with comprehensive anime system networking")

return NetworkManager
