-- GuildSystem.lua
-- Enhanced guild and alliance system for Milestone 3: Competitive & Social Systems
-- Handles guild creation, management, benefits, and social features
-- STEP 10: Enhanced with anime fandom guild features

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Constants = require(script.Parent.Parent.Utils.Constants)
local NetworkManager = require(script.Parent.Parent.Multiplayer.NetworkManager)

local GuildSystem = {}
GuildSystem.__index = GuildSystem

-- Add table.find function for compatibility
if not table.find then
    function table.find(t, value)
        for i, v in ipairs(t) do
            if v == value then
                return i
            end
        end
        return nil
    end
end

-- RemoteEvents for client-server communication
local RemoteEvents = {
    GuildCreated = "GuildCreated",
    GuildJoined = "GuildJoined",
    GuildLeft = "GuildLeft",
    GuildUpdate = "GuildUpdate",
    GuildChat = "GuildChat",
    GuildEvent = "GuildEvent",
    GuildWar = "GuildWar",
    GuildInvite = "GuildInvite",
    GuildApplication = "GuildApplication",
    -- New anime-specific events
    AnimeGuildCreated = "AnimeGuildCreated",
    AnimeGuildWarStarted = "AnimeGuildWarStarted",
    AnimeGuildThemeChanged = "AnimeGuildThemeChanged",
    AnimeGuildBonusActivated = "AnimeGuildBonusActivated"
}

-- Guild roles and permissions (enhanced for anime features)
local GUILD_ROLES = {
    LEADER = {
        name = "Leader",
        level = 4,
        permissions = {
            "INVITE_MEMBERS",
            "KICK_MEMBERS", 
            "PROMOTE_MEMBERS",
            "DEMOTE_MEMBERS",
            "MANAGE_GUILD",
            "START_GUILD_WAR",
            "MANAGE_TREASURY",
            "MANAGE_UPGRADES",
            "CHANGE_ANIME_THEME",
            "MANAGE_ANIME_BONUSES",
            "DECLARE_ANIME_WAR"
        }
    },
    OFFICER = {
        name = "Officer",
        level = 3,
        permissions = {
            "INVITE_MEMBERS",
            "KICK_MEMBERS",
            "PROMOTE_MEMBERS",
            "MANAGE_UPGRADES",
            "MANAGE_ANIME_BONUSES"
        }
    },
    VETERAN = {
        name = "Veteran",
        level = 2,
        permissions = {
            "INVITE_MEMBERS",
            "ACTIVATE_ANIME_BONUSES"
        }
    },
    MEMBER = {
        name = "Member",
        level = 1,
        permissions = {}
    }
}

-- Anime guild themes and bonuses
local ANIME_GUILD_THEMES = {
    SOLO_LEVELING = {
        name = "Solo Leveling",
        displayName = "Solo Leveling Guild",
        description = "A guild focused on individual power and shadow soldiers",
        colors = {
            primary = Color3.fromRGB(75, 0, 130),    -- Purple
            secondary = Color3.fromRGB(25, 25, 112), -- Dark blue
            accent = Color3.fromRGB(138, 43, 226)    -- Blue violet
        },
        bonuses = {
            SHADOW_SOLDIER_BOOST = {
                name = "Shadow Soldier Boost",
                description = "Increases shadow soldier effectiveness by 25%",
                effect = "shadowSoldierMultiplier",
                value = 1.25,
                duration = 3600, -- 1 hour
                cooldown = 7200   -- 2 hours
            },
            SOLO_POWER_SCALING = {
                name = "Solo Power Scaling",
                description = "Individual members gain 15% more power when alone",
                effect = "soloPowerMultiplier",
                value = 1.15,
                duration = 1800, -- 30 minutes
                cooldown = 3600   -- 1 hour
            }
        },
        warBonus = {
            name = "Shadow Army",
            description = "Summon additional shadow soldiers during guild wars",
            effect = "extraShadowSoldiers",
            value = 3
        }
    },
    NARUTO = {
        name = "Naruto",
        displayName = "Hidden Village Guild",
        description = "A guild based on ninja villages and chakra mastery",
        colors = {
            primary = Color3.fromRGB(255, 69, 0),    -- Orange red
            secondary = Color3.fromRGB(255, 140, 0), -- Dark orange
            accent = Color3.fromRGB(255, 215, 0)     -- Gold
        },
        bonuses = {
            CHAKRA_BOOST = {
                name = "Chakra Boost",
                description = "Increases chakra regeneration by 30%",
                effect = "chakraRegenerationMultiplier",
                value = 1.30,
                duration = 2400, -- 40 minutes
                cooldown = 4800   -- 1.3 hours
            },
            NINJA_TEAMWORK = {
                name = "Ninja Teamwork",
                description = "Team-based activities gain 20% bonus",
                effect = "teamworkMultiplier",
                value = 1.20,
                duration = 3600, -- 1 hour
                cooldown = 7200   -- 2 hours
            }
        },
        warBonus = {
            name = "Rasengan Formation",
            description = "Coordinated attacks deal 25% more damage",
            effect = "coordinatedAttackBonus",
            value = 1.25
        }
    },
    ONE_PIECE = {
        name = "One Piece",
        displayName = "Pirate Crew Guild",
        description = "A guild focused on adventure and devil fruit powers",
        colors = {
            primary = Color3.fromRGB(255, 0, 0),     -- Red
            secondary = Color3.fromRGB(139, 0, 0),   -- Dark red
            accent = Color3.fromRGB(255, 165, 0)     -- Orange
        },
        bonuses = {
            DEVIL_FRUIT_POWER = {
                name = "Devil Fruit Power",
                description = "Devil fruit abilities are 20% more effective",
                effect = "devilFruitMultiplier",
                value = 1.20,
                duration = 3000, -- 50 minutes
                cooldown = 6000   -- 1.7 hours
            },
            CREW_MORALE = {
                name = "Crew Morale",
                description = "Guild activities provide 15% more rewards",
                effect = "crewMoraleMultiplier",
                value = 1.15,
                duration = 3600, -- 1 hour
                cooldown = 7200   -- 2 hours
            }
        },
        warBonus = {
            name = "Haki Coordination",
            description = "Guild members can share haki abilities",
            effect = "hakiSharing",
            value = true
        }
    },
    BLEACH = {
        name = "Bleach",
        displayName = "Soul Society Guild",
        description = "A guild focused on spiritual pressure and zanpakuto",
        colors = {
            primary = Color3.fromRGB(0, 0, 139),     -- Dark blue
            secondary = Color3.fromRGB(70, 130, 180), -- Steel blue
            accent = Color3.fromRGB(135, 206, 235)    -- Sky blue
        },
        bonuses = {
            SPIRITUAL_PRESSURE = {
                name = "Spiritual Pressure",
                description = "Increases spiritual pressure by 25%",
                effect = "spiritualPressureMultiplier",
                value = 1.25,
                duration = 2400, -- 40 minutes
                cooldown = 4800   -- 1.3 hours
            },
            ZANPAKUTO_MASTERY = {
                name = "Zanpakuto Mastery",
                description = "Zanpakuto abilities are 20% more powerful",
                effect = "zanpakutoMultiplier",
                value = 1.20,
                duration = 3000, -- 50 minutes
                cooldown = 6000   -- 1.7 hours
            }
        },
        warBonus = {
            name = "Bankai Formation",
            description = "Multiple bankai can be activated simultaneously",
            effect = "bankaiFormation",
            value = true
        }
    },
    MY_HERO_ACADEMIA = {
        name = "My Hero Academia",
        displayName = "Hero Academy Guild",
        description = "A guild focused on hero training and quirk development",
        colors = {
            primary = Color3.fromRGB(255, 20, 147),  -- Deep pink
            secondary = Color3.fromRGB(255, 105, 180), -- Hot pink
            accent = Color3.fromRGB(255, 182, 193)    -- Light pink
        },
        bonuses = {
            QUIRK_DEVELOPMENT = {
                name = "Quirk Development",
                description = "Quirk training is 30% more effective",
                effect = "quirkDevelopmentMultiplier",
                value = 1.30,
                duration = 3600, -- 1 hour
                cooldown = 7200   -- 2 hours
            },
            HERO_TRAINING = {
                name = "Hero Training",
                description = "Hero activities provide 20% more experience",
                effect = "heroTrainingMultiplier",
                value = 1.20,
                duration = 3000, -- 50 minutes
                cooldown = 6000   -- 1.7 hours
            }
        },
        warBonus = {
            name = "Plus Ultra Formation",
            description = "Coordinated hero attacks gain 30% bonus",
            effect = "plusUltraBonus",
            value = 1.30
        }
    }
}

-- Enhanced guild levels with anime-specific benefits
local GUILD_LEVELS = {
    [1] = {
        name = "Recruit Guild",
        minMembers = 1,
        maxMembers = 10,
        benefits = {
            cashMultiplier = 1.05,
            experienceMultiplier = 1.05,
            abilityCostReduction = 0.02
        },
        upgrades = {
            "GUILD_CHAT",
            "BASIC_BONUSES"
        },
        animeFeatures = {
            "BASIC_ANIME_THEME",
            "ANIME_CHAT_CHANNELS"
        }
    },
    [2] = {
        name = "Apprentice Guild",
        minMembers = 5,
        maxMembers = 25,
        benefits = {
            cashMultiplier = 1.10,
            experienceMultiplier = 1.10,
            abilityCostReduction = 0.05,
            guildTreasury = true
        },
        upgrades = {
            "GUILD_TREASURY",
            "ENHANCED_BONUSES",
            "GUILD_EVENTS"
        },
        animeFeatures = {
            "ANIME_BONUS_ACTIVATION",
            "THEME_CUSTOMIZATION"
        }
    },
    [3] = {
        name = "Journeyman Guild",
        minMembers = 10,
        maxMembers = 50,
        benefits = {
            cashMultiplier = 1.15,
            experienceMultiplier = 1.15,
            abilityCostReduction = 0.08,
            guildTreasury = true,
            guildWars = true
        },
        upgrades = {
            "GUILD_WARS",
            "ADVANCED_BONUSES",
            "GUILD_ACHIEVEMENTS"
        },
        animeFeatures = {
            "ANIME_GUILD_WARS",
            "CROSS_THEME_COLLABORATION"
        }
    },
    [4] = {
        name = "Expert Guild",
        minMembers = 20,
        maxMembers = 100,
        benefits = {
            cashMultiplier = 1.20,
            experienceMultiplier = 1.20,
            abilityCostReduction = 0.10,
            guildTreasury = true,
            guildWars = true,
            customThemes = true
        },
        upgrades = {
            "AVATAR_THE_LAST_AIRBENDER_THEMES",
            "ELITE_BONUSES",
            "GUILD_LEADERBOARDS"
        },
        animeFeatures = {
            "MULTI_THEME_WARS",
            "ANIME_TOURNAMENTS"
        }
    },
    [5] = {
        name = "Master Guild",
        minMembers = 50,
        maxMembers = 200,
        benefits = {
            cashMultiplier = 1.25,
            experienceMultiplier = 1.25,
            abilityCostReduction = 0.12,
            guildTreasury = true,
            guildWars = true,
            customThemes = true,
            exclusiveItems = true
        },
        upgrades = {
            "EXCLUSIVE_ITEMS",
            "MASTER_BONUSES",
            "GUILD_TOURNAMENTS"
        },
        animeFeatures = {
            "LEGENDARY_ANIME_WARS",
            "ANIME_FESTIVALS"
        }
    }
}

-- Enhanced guild upgrades with anime features
local GUILD_UPGRADES = {
    GUILD_CHAT = {
        name = "Guild Chat",
        cost = 1000,
        description = "Enable guild-wide chat communication",
        effect = "Unlocks guild chat system"
    },
    GUILD_TREASURY = {
        name = "Guild Treasury",
        cost = 5000,
        description = "Create a shared guild bank for resources",
        effect = "Enables guild treasury and shared resources"
    },
    GUILD_EVENTS = {
        name = "Guild Events",
        cost = 10000,
        description = "Host special guild events and activities",
        effect = "Unlocks guild events and special activities"
    },
    GUILD_WARS = {
        name = "Guild Wars",
        cost = 25000,
        description = "Declare war on other guilds for rewards",
        effect = "Enables guild vs guild battles"
    },
    GUILD_ACHIEVEMENTS = {
        name = "Guild Achievements",
        cost = 15000,
        description = "Track guild progress and milestones",
        effect = "Unlocks guild achievement system"
    },
    AVATAR_THE_LAST_AIRBENDER_THEMES = {
        name = "Avatar: The Last Airbender Themes",
        cost = 50000,
        description = "Create unique guild visual themes with bending elements",
        effect = "Enables avatar bending themes and element-based cosmetics"
    },
    GUILD_LEADERBOARDS = {
        name = "Guild Leaderboards",
        cost = 30000,
        description = "Compete on guild-specific leaderboards",
        effect = "Unlocks guild ranking and competition"
    },
    EXCLUSIVE_ITEMS = {
        name = "Exclusive Items",
        cost = 100000,
        description = "Access to guild-exclusive items and cosmetics",
        effect = "Unlocks guild-exclusive content"
    },
    GUILD_TOURNAMENTS = {
        name = "Guild Tournaments",
        cost = 75000,
        description = "Participate in guild tournaments",
        effect = "Enables competitive guild tournaments"
    },
    -- New anime-specific upgrades
    ANIME_THEME_CUSTOMIZATION = {
        name = "Anime Theme Customization",
        cost = 20000,
        description = "Customize guild with anime-specific themes and colors",
        effect = "Enables anime theme customization and bonuses"
    },
    ANIME_GUILD_WARS = {
        name = "Anime Guild Wars",
        cost = 35000,
        description = "Participate in anime-themed guild wars",
        effect = "Enables anime-specific war mechanics and bonuses"
    },
    CROSS_ANIME_COLLABORATION = {
        name = "Cross-Anime Collaboration",
        cost = 45000,
        description = "Collaborate with guilds of different anime themes",
        effect = "Enables cross-theme events and bonuses"
    },
    ANIME_FESTIVALS = {
        name = "Anime Festivals",
        cost = 60000,
        description = "Host anime-themed festivals and celebrations",
        effect = "Enables seasonal anime events and special rewards"
    }
}

function GuildSystem.new()
    local self = setmetatable({}, GuildSystem)
    
    -- Core data structures
    self.guilds = {}              -- Guild ID -> Guild Data
    self.playerGuilds = {}        -- Player ID -> Guild ID
    self.guildInvites = {}        -- Player ID -> Pending Invites
    self.guildApplications = {}    -- Guild ID -> Pending Applications
    self.guildWars = {}           -- War ID -> War Data
    self.guildEvents = {}         -- Event ID -> Event Data
    
    -- New anime-specific data structures
    self.animeGuildWars = {}      -- Anime-themed guild wars
    self.animeGuildBonuses = {}   -- Active anime guild bonuses
    self.animeGuildThemes = {}    -- Guild anime theme assignments
    self.crossAnimeCollaborations = {} -- Cross-theme collaborations
    self.animeFestivals = {}      -- Anime-themed festivals
    
    -- Network manager reference
    self.networkManager = nil
    
    -- Initialize remote events
    self.remoteEvents = {}
    
    -- Guild management
    self.nextGuildId = 1
    self.guildUpdateInterval = 10 -- Update guilds every 10 seconds
    
    return self
end

function GuildSystem:Initialize(networkManager)
    self.networkManager = networkManager
    
    -- Set up remote events
    self:SetupRemoteEvents()
    
    -- Connect to player events
    self:ConnectPlayerEvents()
    
    -- Start update loop
    self:StartUpdateLoop()
    
    print("GuildSystem: Initialized successfully!")
end

function GuildSystem:SetupRemoteEvents()
    -- Create remote events in ReplicatedStorage
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    
    for eventName, _ in pairs(RemoteEvents) do
        local remoteEvent = Instance.new("RemoteEvent")
        remoteEvent.Name = eventName
        remoteEvent.Parent = ReplicatedStorage
        self.remoteEvents[eventName] = remoteEvent
    end
    
    -- Set up event handlers
    self.remoteEvents.GuildInvite.OnServerEvent:Connect(function(player, targetPlayer, guildId)
        self:SendGuildInvite(player, targetPlayer, guildId)
    end)
    
    self.remoteEvents.GuildApplication.OnServerEvent:Connect(function(player, guildId, message)
        self:SubmitGuildApplication(player, guildId, message)
    end)
    
    self.remoteEvents.GuildChat.OnServerEvent:Connect(function(player, guildId, message)
        self:SendGuildChat(player, guildId, message)
    end)
    
    -- New anime-specific event handlers
    self.remoteEvents.AnimeGuildCreated.OnServerEvent:Connect(function(player, guildName, description, tag, animeTheme)
        self:CreateAnimeGuild(player, guildName, description, tag, animeTheme)
    end)
    
    self.remoteEvents.AnimeGuildThemeChanged.OnServerEvent:Connect(function(player, guildId, newTheme)
        self:ChangeGuildAnimeTheme(guildId, newTheme, player)
    end)
    
    self.remoteEvents.AnimeGuildBonusActivated.OnServerEvent:Connect(function(player, guildId, bonusId)
        self:ActivateAnimeGuildBonus(guildId, bonusId, player)
    end)
    
    self.remoteEvents.AnimeGuildWarStarted.OnServerEvent:Connect(function(player, guild1Id, guild2Id)
        self:StartAnimeGuildWar(guild1Id, guild2Id, player)
    end)
    
    print("GuildSystem: Remote events configured!")
end

function GuildSystem:ConnectPlayerEvents()
    -- Handle player joining
    Players.PlayerAdded:Connect(function(player)
        self:HandlePlayerJoined(player)
    end)
    
    -- Handle player leaving
    Players.PlayerRemoving:Connect(function(player)
        self:HandlePlayerLeaving(player)
    end)
    
    print("GuildSystem: Player events connected!")
end

-- Player event handlers
function GuildSystem:HandlePlayerJoined(player)
    local userId = player.UserId
    
    -- Check if player was in a guild before
    local guildId = self.playerGuilds[userId]
    if guildId then
        local guild = self.guilds[guildId]
        if guild then
            -- Update member's last active time
            if guild.members[userId] then
                guild.members[userId].lastActive = time()
            end
            
            -- Broadcast player rejoined
            self:BroadcastGuildUpdate(guildId, "MEMBER_REJOINED", {playerId = userId, playerName = player.Name})
        end
    end
    
    print("GuildSystem: Player joined:", player.Name)
end

function GuildSystem:HandlePlayerLeaving(player)
    local userId = player.UserId
    local guildId = self.playerGuilds[userId]
    
    if guildId then
        local guild = self.guilds[guildId]
        if guild then
            -- Update member's last active time
            if guild.members[userId] then
                guild.members[userId].lastActive = time()
            end
            
            -- Broadcast player leaving
            self:BroadcastGuildUpdate(guildId, "MEMBER_LEFT", {playerId = userId, playerName = player.Name})
        end
    end
    
    print("GuildSystem: Player leaving:", player.Name)
end

-- Guild update functions
function GuildSystem:UpdateAllGuilds()
    local currentTime = time()
    
    for guildId, guild in pairs(self.guilds) do
        -- Update guild experience and level
        if guild.experience >= guild.experienceToNext then
            self:LevelUpGuild(guildId)
        end
        
        -- Update member activity
        for memberId, memberData in pairs(guild.members) do
            if currentTime - memberData.lastActive > 7 * 24 * 60 * 60 then -- 7 days
                -- Mark member as inactive
                memberData.status = "INACTIVE"
            end
        end
        
        -- Update guild last active time
        guild.lastActive = currentTime
    end
end

function GuildSystem:LevelUpGuild(guildId)
    local guild = self.guilds[guildId]
    if not guild then
        return false
    end
    
    -- Level up guild
    guild.level = guild.level + 1
    guild.experience = guild.experience - guild.experienceToNext
    guild.experienceToNext = self:CalculateExperienceToNext(guild.level)
    
    -- Get new benefits for this level
    local newBenefits = GUILD_LEVELS[guild.level].benefits
    if newBenefits then
        for _, benefit in pairs(newBenefits) do
            if not table.find(guild.upgrades, benefit) then
                table.insert(guild.upgrades, benefit)
            end
        end
    end
    
    -- Broadcast guild leveled up
    self:BroadcastGuildUpdate(guildId, "GUILD_LEVELED_UP", {
        newLevel = guild.level,
        newBenefits = newBenefits or {}
    })
    
    print("GuildSystem: Guild", guild.name, "leveled up to", guild.level)
    return true
end

function GuildSystem:StartUpdateLoop()
    -- Update guilds and process events
    RunService.Heartbeat:Connect(function()
        local currentTime = time()
        
        -- Process guild updates
        if currentTime % self.guildUpdateInterval < 0.1 then
            self:UpdateAllGuilds()
        end
        
        -- Process guild wars
        self:ProcessGuildWars()
        
        -- Process anime guild wars
        self:ProcessAnimeGuildWars()
        
        -- Process cross-anime collaborations
        self:ProcessCrossAnimeCollaborations()
        
        -- Process anime festivals
        self:ProcessAnimeFestivals()
        
        -- Process guild events
        self:ProcessGuildEvents()
    end)
end

-- Core Guild Functions

function GuildSystem:CreateGuild(leader, guildName, description, tag)
    local userId = leader.UserId
    
    -- Check if player is already in a guild
    if self.playerGuilds[userId] then
        return false, "Player is already in a guild"
    end
    
    -- Validate guild name and tag
    if not self:ValidateGuildName(guildName) then
        return false, "Invalid guild name"
    end
    
    if not self:ValidateGuildTag(tag) then
        return false, "Invalid guild tag"
    end
    
    -- Check if name/tag is already taken
    if self:IsGuildNameTaken(guildName) then
        return false, "Guild name already taken"
    end
    
    if self:IsGuildTagTaken(tag) then
        return false, "Guild tag already taken"
    end
    
    -- Create guild
    local guildId = self.nextGuildId
    self.nextGuildId = self.nextGuildId + 1
    
    local guild = {
        id = guildId,
        name = guildName,
        tag = tag,
        description = description,
        leader = userId,
        members = {[userId] = {
            role = "LEADER",
            joinedAt = time(),
            contribution = 0,
            lastActive = time()
        }},
        level = 1,
        experience = 0,
        experienceToNext = self:CalculateExperienceToNext(1),
        treasury = 0,
        upgrades = {"GUILD_CHAT", "BASIC_BONUSES"},
        createdAt = time(),
        lastActive = time(),
        settings = {
            autoAccept = false,
            minLevel = 1,
            public = true
        }
    }
    
    -- Store guild data
    self.guilds[guildId] = guild
    self.playerGuilds[userId] = guildId
    
    -- Broadcast guild creation
    self:BroadcastGuildCreated(guild)
    
    print("GuildSystem: Guild created:", guildName, "by", leader.Name)
    return true, guildId
end

-- New anime-specific guild functions

function GuildSystem:CreateAnimeGuild(leader, guildName, description, tag, animeTheme)
    local userId = leader.UserId
    
    -- Check if player is already in a guild
    if self.playerGuilds[userId] then
        return false, "Player is already in a guild"
    end
    
    -- Validate anime theme
    if not ANIME_GUILD_THEMES[animeTheme] then
        return false, "Invalid anime theme"
    end
    
    -- Create regular guild first
    local success, guildId = self:CreateGuild(leader, guildName, description, tag)
    if not success then
        return false, guildId
    end
    
    -- Add anime theme to guild
    local guild = self.guilds[guildId]
    guild.animeTheme = animeTheme
    guild.animeThemeData = ANIME_GUILD_THEMES[animeTheme]
    guild.animeBonuses = {}
    guild.animeWarHistory = {}
    
    -- Store anime guild data
    self.animeGuildThemes[guildId] = animeTheme
    
    -- Broadcast anime guild creation
    self:BroadcastAnimeGuildCreated(guild)
    
    print("GuildSystem: Anime guild created:", guildName, "with theme", animeTheme, "by", leader.Name)
    return true, guildId
end

function GuildSystem:ChangeGuildAnimeTheme(guildId, newTheme, changer)
    local guild = self.guilds[guildId]
    if not guild then
        return false, "Guild not found"
    end
    
    local changerId = changer.UserId
    
    -- Check permissions
    if not self:HasPermission(changerId, guildId, "CHANGE_ANIME_THEME") then
        return false, "Insufficient permissions"
    end
    
    -- Validate anime theme
    if not ANIME_GUILD_THEMES[newTheme] then
        return false, "Invalid anime theme"
    end
    
    -- Check if guild has theme customization upgrade
    if not self:HasUpgrade(guildId, "ANIME_THEME_CUSTOMIZATION") then
        return false, "Guild needs anime theme customization upgrade"
    end
    
    -- Change theme
    local oldTheme = guild.animeTheme
    guild.animeTheme = newTheme
    guild.animeThemeData = ANIME_GUILD_THEMES[newTheme]
    
    -- Update stored data
    self.animeGuildThemes[guildId] = newTheme
    
    -- Broadcast theme change
    self:BroadcastAnimeGuildThemeChanged(guildId, oldTheme, newTheme)
    
    print("GuildSystem: Guild theme changed from", oldTheme, "to", newTheme)
    return true
end

function GuildSystem:ActivateAnimeGuildBonus(guildId, bonusId, activator)
    local guild = self.guilds[guildId]
    if not guild then
        return false, "Guild not found"
    end
    
    local activatorId = activator.UserId
    
    -- Check if guild has anime theme
    if not guild.animeTheme then
        return false, "Guild does not have an anime theme"
    end
    
    -- Check permissions
    if not self:HasPermission(activatorId, guildId, "ACTIVATE_ANIME_BONUSES") then
        return false, "Insufficient permissions"
    end
    
    -- Get anime theme data
    local themeData = ANIME_GUILD_THEMES[guild.animeTheme]
    if not themeData or not themeData.bonuses[bonusId] then
        return false, "Bonus not found for this theme"
    end
    
    local bonus = themeData.bonuses[bonusId]
    
    -- Check if bonus is on cooldown
    local currentBonus = self.animeGuildBonuses[guildId] and self.animeGuildBonuses[guildId][bonusId]
    if currentBonus and time() < currentBonus.expiresAt + bonus.cooldown then
        local remainingCooldown = (currentBonus.expiresAt + bonus.cooldown) - time()
        return false, "Bonus on cooldown. Remaining time: " .. math.floor(remainingCooldown / 60) .. " minutes"
    end
    
    -- Activate bonus
    if not self.animeGuildBonuses[guildId] then
        self.animeGuildBonuses[guildId] = {}
    end
    
    self.animeGuildBonuses[guildId][bonusId] = {
        effect = bonus.effect,
        value = bonus.value,
        activatedAt = time(),
        expiresAt = time() + bonus.duration,
        activatorId = activatorId
    }
    
    -- Apply bonus to all guild members
    self:ApplyAnimeGuildBonusToMembers(guildId, bonusId, bonus)
    
    -- Broadcast bonus activation
    self:BroadcastAnimeGuildBonusActivated(guildId, bonusId, bonus)
    
    print("GuildSystem: Anime guild bonus activated:", bonusId, "in guild", guild.name)
    return true
end

function GuildSystem:ApplyAnimeGuildBonusToMembers(guildId, bonusId, bonus)
    local guild = self.guilds[guildId]
    if not guild then
        return false
    end
    
    -- Apply bonus to all online members
    for memberId, _ in pairs(guild.members) do
        local player = Players:GetPlayerByUserId(memberId)
        if player then
            -- This would integrate with your existing systems
            -- For now, we'll just log the application
            print("Applying anime bonus", bonusId, "to player", player.Name, "with effect", bonus.effect, "value", bonus.value)
            
            -- Example integration points:
            -- if bonus.effect == "shadowSoldierMultiplier" then
            --     -- Apply to shadow soldier system
            -- elseif bonus.effect == "chakraRegenerationMultiplier" then
            --     -- Apply to chakra system
            -- end
        end
    end
    
    return true
end

function GuildSystem:StartAnimeGuildWar(guild1Id, guild2Id, initiator)
    local guild1 = self.guilds[guild1Id]
    local guild2 = self.guilds[guild2Id]
    
    if not guild1 or not guild2 then
        return false, "One or both guilds not found"
    end
    
    -- Check if initiator is guild leader
    if guild1.leader ~= initiator.UserId then
        return false, "Only guild leader can start war"
    end
    
    -- Check if guilds have anime war capability
    if not self:HasUpgrade(guild1Id, "ANIME_GUILD_WARS") or not self:HasUpgrade(guild2Id, "ANIME_GUILD_WARS") then
        return false, "One or both guilds cannot participate in anime wars"
    end
    
    -- Check if guilds have anime themes
    if not guild1.animeTheme or not guild2.animeTheme then
        return false, "Both guilds must have anime themes to participate in anime wars"
    end
    
    -- Check if already at war
    if self:AreGuildsAtAnimeWar(guild1Id, guild2Id) then
        return false, "Guilds are already at anime war"
    end
    
    -- Create anime war
    local warId = HttpService:GenerateGUID()
    local war = {
        id = warId,
        guild1Id = guild1Id,
        guild2Id = guild2Id,
        guild1Theme = guild1.animeTheme,
        guild2Theme = guild2.animeTheme,
        startTime = time(),
        duration = 7 * 24 * 60 * 60, -- 7 days
        status = "ACTIVE",
        warType = "ANIME_WAR",
        scores = {
            [guild1Id] = 0,
            [guild2Id] = 0
        },
        participants = {
            [guild1Id] = {},
            [guild2Id] = {}
        },
        animeWarEvents = {},
        themeAdvantages = self:CalculateThemeAdvantages(guild1.animeTheme, guild2.animeTheme)
    }
    
    -- Store anime war
    self.animeGuildWars[warId] = war
    
    -- Broadcast anime war started
    self:BroadcastAnimeGuildWarStarted(war)
    
    print("GuildSystem: Anime guild war started between", guild1.name, "(" .. guild1.animeTheme .. ")", "and", guild2.name, "(" .. guild2.animeTheme .. ")")
    return true, warId
end

function GuildSystem:CalculateThemeAdvantages(theme1, theme2)
    local advantages = {
        [theme1] = {},
        [theme2] = {}
    }
    
    -- Theme-specific advantages (rock-paper-scissors style)
    if theme1 == "SOLO_LEVELING" and theme2 == "NARUTO" then
        advantages[theme1].description = "Shadow soldiers can infiltrate ninja villages"
        advantages[theme1].bonus = 1.15
        advantages[theme2].description = "Chakra sensing can detect shadow soldiers"
        advantages[theme2].bonus = 1.10
    elseif theme1 == "NARUTO" and theme2 == "ONE_PIECE" then
        advantages[theme1].description = "Ninja techniques are effective against pirates"
        advantages[theme1].bonus = 1.20
        advantages[theme2].description = "Devil fruit powers can counter ninja techniques"
        advantages[theme2].bonus = 1.10
    elseif theme1 == "ONE_PIECE" and theme2 == "BLEACH" then
        advantages[theme1].description = "Haki can affect spiritual beings"
        advantages[theme1].bonus = 1.15
        advantages[theme2].description = "Spiritual pressure can overwhelm physical strength"
        advantages[theme2].bonus = 1.20
    elseif theme1 == "BLEACH" and theme2 == "MY_HERO_ACADEMIA" then
        advantages[theme1].description = "Spiritual powers can nullify quirks"
        advantages[theme1].bonus = 1.25
        advantages[theme2].description = "Hero training provides resistance to spiritual attacks"
        advantages[theme2].bonus = 1.10
    elseif theme1 == "MY_HERO_ACADEMIA" and theme2 == "SOLO_LEVELING" then
        advantages[theme1].description = "Hero teamwork can counter individual power"
        advantages[theme1].bonus = 1.15
        advantages[theme2].description = "Shadow soldiers can overwhelm hero formations"
        advantages[theme2].bonus = 1.20
    end
    
    return advantages
end

function GuildSystem:AreGuildsAtAnimeWar(guild1Id, guild2Id)
    for _, war in pairs(self.animeGuildWars) do
        if war.status == "ACTIVE" and war.warType == "ANIME_WAR" and
           ((war.guild1Id == guild1Id and war.guild2Id == guild2Id) or
            (war.guild1Id == guild2Id and war.guild2Id == guild1Id)) then
            return true
        end
    end
    return false
end

function GuildSystem:ProcessAnimeGuildWars()
    local currentTime = time()
    
    for warId, war in pairs(self.animeGuildWars) do
        if war.status == "ACTIVE" and war.warType == "ANIME_WAR" then
            -- Check if war should end
            if currentTime - war.startTime >= war.duration then
                self:EndAnimeGuildWar(warId)
            else
                -- Process ongoing anime war events
                self:ProcessAnimeWarEvents(warId)
            end
        end
    end
end

function GuildSystem:ProcessAnimeWarEvents(warId)
    local war = self.animeGuildWars[warId]
    if not war then
        return
    end
    
    local currentTime = time()
    
    -- Generate random anime war events
    if currentTime % 3600 < 0.1 then -- Every hour
        self:GenerateAnimeWarEvent(warId)
    end
    
    -- Process existing events
    for eventId, event in pairs(war.animeWarEvents) do
        if event.status == "ACTIVE" and currentTime >= event.expiresAt then
            self:CompleteAnimeWarEvent(warId, eventId)
        end
    end
end

function GuildSystem:GenerateAnimeWarEvent(warId)
    local war = self.animeGuildWars[warId]
    if not war then
        return
    end
    
    local eventTypes = {
        "THEME_CHALLENGE",
        "ANIME_BOSS_RAID",
        "CROSS_THEME_BATTLE",
        "ANIME_ARTIFACT_COLLECTION"
    }
    
    local eventType = eventTypes[math.random(1, #eventTypes)]
    local eventId = HttpService:GenerateGUID()
    
    local event = {
        id = eventId,
        type = eventType,
        startTime = time(),
        expiresAt = time() + 1800, -- 30 minutes
        status = "ACTIVE",
        participants = {},
        rewards = self:CalculateAnimeWarEventRewards(eventType)
    }
    
    war.animeWarEvents[eventId] = event
    
    -- Broadcast event to both guilds
    self:BroadcastAnimeGuildWar(war.guild1Id, "ANIME_WAR_EVENT_STARTED", event)
    self:BroadcastAnimeGuildWar(war.guild2Id, "ANIME_WAR_EVENT_STARTED", event)
    
    print("GuildSystem: Anime war event generated:", eventType, "for war", warId)
end

function GuildSystem:CalculateAnimeWarEventRewards(eventType)
    local baseRewards = {
        cash = 1000,
        experience = 500,
        animePoints = 100
    }
    
    local multipliers = {
        THEME_CHALLENGE = 1.0,
        ANIME_BOSS_RAID = 1.5,
        CROSS_THEME_BATTLE = 1.3,
        ANIME_ARTIFACT_COLLECTION = 1.2
    }
    
    local multiplier = multipliers[eventType] or 1.0
    
    return {
        cash = math.floor(baseRewards.cash * multiplier),
        experience = math.floor(baseRewards.experience * multiplier),
        animePoints = math.floor(baseRewards.animePoints * multiplier)
    }
end

function GuildSystem:CompleteAnimeWarEvent(warId, eventId)
    local war = self.animeGuildWars[warId]
    if not war then
        return
    end
    
    local event = war.animeWarEvents[eventId]
    if not event then
        return
    end
    
    event.status = "COMPLETED"
    
    -- Award points based on participation
    local guild1Participants = 0
    local guild2Participants = 0
    
    for guildId, participants in pairs(event.participants) do
        if guildId == war.guild1Id then
            guild1Participants = #participants
        elseif guildId == war.guild2Id then
            guild2Participants = #participants
        end
    end
    
    -- Award points (more participants = more points)
    if guild1Participants > 0 then
        war.scores[war.guild1Id] = war.scores[war.guild1Id] + (guild1Participants * 10)
    end
    if guild2Participants > 0 then
        war.scores[war.guild2Id] = war.scores[war.guild2Id] + (guild2Participants * 10)
    end
    
    -- Broadcast event completion
    self:BroadcastAnimeGuildWar(war.guild1Id, "ANIME_WAR_EVENT_COMPLETED", event)
    self:BroadcastAnimeGuildWar(war.guild2Id, "ANIME_WAR_EVENT_COMPLETED", event)
    
    print("GuildSystem: Anime war event completed:", event.type, "in war", warId)
end

function GuildSystem:EndAnimeGuildWar(warId)
    local war = self.animeGuildWars[warId]
    if not war then
        return false, "War not found"
    end
    
    -- Determine winner
    local winnerId = war.scores[war.guild1Id] > war.scores[war.guild2Id] and war.guild1Id or war.guild2Id
    local loserId = winnerId == war.guild1Id and war.guild2Id or war.guild1Id
    
    -- Update war status
    war.status = "COMPLETED"
    war.winner = winnerId
    war.endTime = time()
    
    -- Award anime war rewards
    self:AwardAnimeWarRewards(warId, winnerId, loserId)
    
    -- Broadcast war ended
    self:BroadcastAnimeGuildWar(war.guild1Id, "ANIME_WAR_ENDED", war)
    self:BroadcastAnimeGuildWar(war.guild2Id, "ANIME_WAR_ENDED", war)
    
    print("GuildSystem: Anime guild war ended. Winner:", self.guilds[winnerId].name, "(" .. self.guilds[winnerId].animeTheme .. ")")
end

function GuildSystem:AwardAnimeWarRewards(warId, winnerId, loserId)
    local winnerGuild = self.guilds[winnerId]
    local loserGuild = self.guilds[loserId]
    
    if not winnerGuild or not loserGuild then
        return
    end
    
    -- Winner rewards
    local winnerRewards = {
        cash = 10000,
        experience = 5000,
        animePoints = 1000,
        animeTheme = winnerGuild.animeTheme
    }
    
    -- Loser rewards (consolation)
    local loserRewards = {
        cash = 2000,
        experience = 1000,
        animePoints = 200,
        animeTheme = loserGuild.animeTheme
    }
    
    -- Apply rewards to guild members
    self:ApplyAnimeWarRewardsToGuild(winnerId, winnerRewards)
    self:ApplyAnimeWarRewardsToGuild(loserId, loserRewards)
    
    print("GuildSystem: Anime war rewards distributed to", winnerGuild.name, "and", loserGuild.name)
end

function GuildSystem:ApplyAnimeWarRewardsToGuild(guildId, rewards)
    local guild = self.guilds[guildId]
    if not guild then
        return
    end
    
    for memberId, _ in pairs(guild.members) do
        local player = Players:GetPlayerByUserId(memberId)
        if player then
            -- This would integrate with your existing reward systems
            print("Awarding anime war rewards to", player.Name, ":", rewards.cash, "cash,", rewards.experience, "exp,", rewards.animePoints, "anime points")
            
            -- Example integration:
            -- if self.cashSystem then
            --     self.cashSystem:AddCash(player, rewards.cash)
            -- end
            -- if self.experienceSystem then
            --     self.experienceSystem:AddExperience(player, rewards.experience)
            -- end
        end
    end
end

-- Cross-Anime Collaboration System
function GuildSystem:CreateCrossAnimeCollaboration(guild1Id, guild2Id, collaborationType, initiator)
    local guild1 = self.guilds[guild1Id]
    local guild2 = self.guilds[guild2Id]
    
    if not guild1 or not guild2 then
        return false, "One or both guilds not found"
    end
    
    -- Check if both guilds have anime themes
    if not guild1.animeTheme or not guild2.animeTheme then
        return false, "Both guilds must have anime themes to collaborate"
    end
    
    -- Check if guilds are different themes
    if guild1.animeTheme == guild2.animeTheme then
        return false, "Guilds must have different anime themes to collaborate"
    end
    
    -- Check if guilds have collaboration capability
    if not self:HasUpgrade(guild1Id, "CROSS_ANIME_COLLABORATION") or 
       not self:HasUpgrade(guild2Id, "CROSS_ANIME_COLLABORATION") then
        return false, "One or both guilds cannot participate in cross-anime collaborations"
    end
    
    -- Check if already collaborating
    for _, collab in pairs(self.crossAnimeCollaborations) do
        if collab.status == "ACTIVE" and 
           ((collab.guild1Id == guild1Id and collab.guild2Id == guild2Id) or
            (collab.guild1Id == guild2Id and collab.guild2Id == guild1Id)) then
            return false, "Guilds are already collaborating"
        end
    end
    
    -- Create collaboration
    local collaborationId = HttpService:GenerateGUID()
    local collaboration = {
        id = collaborationId,
        guild1Id = guild1Id,
        guild2Id = guild2Id,
        guild1Theme = guild1.animeTheme,
        guild2Theme = guild2.animeTheme,
        type = collaborationType,
        startTime = time(),
        duration = 3 * 24 * 60 * 60, -- 3 days
        status = "ACTIVE",
        participants = {
            [guild1Id] = {},
            [guild2Id] = {}
        },
        collaborationEvents = {},
        rewards = {
            cash = 5000,
            experience = 2500,
            animePoints = 500,
            crossThemeBonus = 1.25
        }
    }
    
    -- Store collaboration
    self.crossAnimeCollaborations[collaborationId] = collaboration
    
    -- Broadcast collaboration started
    self:BroadcastCrossAnimeCollaborationStarted(collaboration)
    
    print("GuildSystem: Cross-anime collaboration started between", guild1.name, "(" .. guild1.animeTheme .. ")", "and", guild2.name, "(" .. guild2.animeTheme .. ")")
    return true, collaborationId
end

function GuildSystem:ProcessCrossAnimeCollaborations()
    local currentTime = time()
    
    for collabId, collab in pairs(self.crossAnimeCollaborations) do
        if collab.status == "ACTIVE" then
            -- Check if collaboration should end
            if currentTime - collab.startTime >= collab.duration then
                self:EndCrossAnimeCollaboration(collabId)
            else
                -- Generate collaboration events periodically
                if #collab.collaborationEvents == 0 or 
                   currentTime - collab.collaborationEvents[#collab.collaborationEvents].startTime >= 3600 then -- 1 hour
                    self:GenerateCrossAnimeCollaborationEvent(collabId)
                end
            end
        end
    end
end

function GuildSystem:GenerateCrossAnimeCollaborationEvent(collaborationId)
    local collab = self.crossAnimeCollaborations[collaborationId]
    if not collab then
        return false
    end
    
    local eventTypes = {
        "THEME_FUSION_CHALLENGE",
        "CROSS_ANIME_BOSS_RAID",
        "ANIME_COMBINATION_ATTACK",
        "THEME_SYNERGY_TRAINING"
    }
    
    local eventType = eventTypes[math.random(1, #eventTypes)]
    local eventId = HttpService:GenerateGUID()
    
    local event = {
        id = eventId,
        type = eventType,
        startTime = time(),
        expiresAt = time() + 1800, -- 30 minutes
        status = "ACTIVE",
        participants = {},
        rewards = self:CalculateCrossAnimeCollaborationEventRewards(eventType)
    }
    
    collab.collaborationEvents[eventId] = event
    
    -- Broadcast event generated
    self:BroadcastCrossAnimeCollaborationEvent(collab.guild1Id, "EVENT_GENERATED", event)
    self:BroadcastCrossAnimeCollaborationEvent(collab.guild2Id, "EVENT_GENERATED", event)
    
    print("GuildSystem: Cross-anime collaboration event generated:", eventType)
    return eventId
end

function GuildSystem:CalculateCrossAnimeCollaborationEventRewards(eventType)
    local baseRewards = {
        cash = 1500,
        experience = 750,
        animePoints = 150,
        crossThemeBonus = 1.25
    }
    
    local multipliers = {
        THEME_FUSION_CHALLENGE = 1.0,
        CROSS_ANIME_BOSS_RAID = 1.5,
        ANIME_COMBINATION_ATTACK = 1.3,
        THEME_SYNERGY_TRAINING = 1.2
    }
    
    local multiplier = multipliers[eventType] or 1.0
    
    return {
        cash = math.floor(baseRewards.cash * multiplier),
        experience = math.floor(baseRewards.experience * multiplier),
        animePoints = math.floor(baseRewards.animePoints * multiplier),
        crossThemeBonus = baseRewards.crossThemeBonus
    }
end

function GuildSystem:EndCrossAnimeCollaboration(collaborationId)
    local collab = self.crossAnimeCollaborations[collaborationId]
    if not collab then
        return false
    end
    
    -- Update status
    collab.status = "COMPLETED"
    collab.endTime = time()
    
    -- Award rewards to both guilds
    self:AwardCrossAnimeCollaborationRewards(collaborationId)
    
    -- Broadcast collaboration ended
    self:BroadcastCrossAnimeCollaborationEnded(collab)
    
    print("GuildSystem: Cross-anime collaboration ended between guilds", collab.guild1Id, "and", collab.guild2Id)
end

function GuildSystem:AwardCrossAnimeCollaborationRewards(collaborationId)
    local collab = self.crossAnimeCollaborations[collaborationId]
    if not collab then
        return
    end
    
    -- Award rewards to both guilds
    self:ApplyCrossAnimeCollaborationRewardsToGuild(collab.guild1Id, collab.rewards)
    self:ApplyCrossAnimeCollaborationRewardsToGuild(collab.guild2Id, collab.rewards)
    
    print("GuildSystem: Cross-anime collaboration rewards distributed")
end

function GuildSystem:ApplyCrossAnimeCollaborationRewardsToGuild(guildId, rewards)
    local guild = self.guilds[guildId]
    if not guild then
        return
    end
    
    for memberId, _ in pairs(guild.members) do
        local player = Players:GetPlayerByUserId(memberId)
        if player then
            print("Awarding cross-anime collaboration rewards to", player.Name, ":", rewards.cash, "cash,", rewards.experience, "exp,", rewards.animePoints, "anime points")
        end
    end
end

-- Anime Festival System
function GuildSystem:CreateAnimeFestival(guildId, festivalType, data, creator)
    local guild = self.guilds[guildId]
    if not guild then
        return false, "Guild not found"
    end
    
    -- Check if guild has anime theme
    if not guild.animeTheme then
        return false, "Guild must have an anime theme to host festivals"
    end
    
    -- Check if guild has festival capability
    if not self:HasUpgrade(guildId, "ANIME_FESTIVALS") then
        return false, "Guild cannot host anime festivals"
    end
    
    -- Check permissions
    if not self:HasPermission(creator.UserId, guildId, "MANAGE_GUILD") then
        return false, "Insufficient permissions"
    end
    
    -- Create festival
    local festivalId = HttpService:GenerateGUID()
    local festival = {
        id = festivalId,
        guildId = guildId,
        guildTheme = guild.animeTheme,
        type = festivalType,
        data = data,
        creatorId = creator.UserId,
        startTime = time(),
        duration = 24 * 60 * 60, -- 24 hours
        status = "ACTIVE",
        participants = {},
        festivalEvents = {},
        rewards = {
            cash = 3000,
            experience = 1500,
            animePoints = 300,
            themeBonus = 1.20
        }
    }
    
    -- Store festival
    self.animeFestivals[festivalId] = festival
    
    -- Broadcast festival created
    self:BroadcastAnimeFestivalCreated(festival)
    
    print("GuildSystem: Anime festival created:", festivalType, "in", guild.name, "(" .. guild.animeTheme .. ")")
    return true, festivalId
end

function GuildSystem:ProcessAnimeFestivals()
    local currentTime = time()
    
    for festivalId, festival in pairs(self.animeFestivals) do
        if festival.status == "ACTIVE" then
            -- Check if festival should end
            if currentTime - festival.startTime >= festival.duration then
                self:EndAnimeFestival(festivalId)
            else
                -- Generate festival events periodically
                if #festival.festivalEvents == 0 or 
                   currentTime - festival.festivalEvents[#festival.festivalEvents].startTime >= 1800 then -- 30 minutes
                    self:GenerateAnimeFestivalEvent(festivalId)
                end
            end
        end
    end
end

function GuildSystem:GenerateAnimeFestivalEvent(festivalId)
    local festival = self.animeFestivals[festivalId]
    if not festival then
        return false
    end
    
    local eventTypes = {
        "THEME_CELEBRATION",
        "ANIME_CHARACTER_PARADE",
        "THEME_POWER_DEMONSTRATION",
        "ANIME_ARTIFACT_EXHIBITION"
    }
    
    local eventType = eventTypes[math.random(1, #eventTypes)]
    local eventId = HttpService:GenerateGUID()
    
    local event = {
        id = eventId,
        type = eventType,
        startTime = time(),
        expiresAt = time() + 900, -- 15 minutes
        status = "ACTIVE",
        participants = {},
        rewards = self:CalculateAnimeFestivalEventRewards(eventType)
    }
    
    festival.festivalEvents[eventId] = event
    
    -- Broadcast event generated
    self:BroadcastAnimeFestivalEvent(festival.guildId, "EVENT_GENERATED", event)
    
    print("GuildSystem: Anime festival event generated:", eventType)
    return eventId
end

function GuildSystem:CalculateAnimeFestivalEventRewards(eventType)
    local baseRewards = {
        cash = 800,
        experience = 400,
        animePoints = 80,
        themeBonus = 1.20
    }
    
    local multipliers = {
        THEME_CELEBRATION = 1.0,
        ANIME_CHARACTER_PARADE = 1.3,
        THEME_POWER_DEMONSTRATION = 1.4,
        ANIME_ARTIFACT_EXHIBITION = 1.2
    }
    
    local multiplier = multipliers[eventType] or 1.0
    
    return {
        cash = math.floor(baseRewards.cash * multiplier),
        experience = math.floor(baseRewards.experience * multiplier),
        animePoints = math.floor(baseRewards.animePoints * multiplier),
        themeBonus = baseRewards.themeBonus
    }
end

function GuildSystem:EndAnimeFestival(festivalId)
    local festival = self.animeFestivals[festivalId]
    if not festival then
        return false
    end
    
    -- Update status
    festival.status = "COMPLETED"
    festival.endTime = time()
    
    -- Award rewards to guild
    self:AwardAnimeFestivalRewards(festivalId)
    
    -- Broadcast festival ended
    self:BroadcastAnimeFestivalEnded(festival)
    
    print("GuildSystem: Anime festival ended in guild", festival.guildId)
end

function GuildSystem:AwardAnimeFestivalRewards(festivalId)
    local festival = self.animeFestivals[festivalId]
    if not festival then
        return
    end
    
    -- Award rewards to guild
    self:ApplyAnimeFestivalRewardsToGuild(festival.guildId, festival.rewards)
    
    print("GuildSystem: Anime festival rewards distributed")
end

function GuildSystem:ApplyAnimeFestivalRewardsToGuild(guildId, rewards)
    local guild = self.guilds[guildId]
    if not guild then
        return
    end
    
    for memberId, _ in pairs(guild.members) do
        local player = Players:GetPlayerByUserId(memberId)
        if player then
            print("Awarding anime festival rewards to", player.Name, ":", rewards.cash, "cash,", rewards.experience, "exp,", rewards.animePoints, "anime points")
        end
    end
end

function GuildSystem:DisbandGuild(guildId, leader)
    local guild = self.guilds[guildId]
    if not guild then
        return false, "Guild not found"
    end
    
    -- Check if player is guild leader
    if guild.leader ~= leader.UserId then
        return false, "Only guild leader can disband guild"
    end
    
    -- Remove all members
    for memberId, _ in pairs(guild.members) do
        self.playerGuilds[memberId] = nil
    end
    
    -- Remove guild
    self.guilds[guildId] = nil
    
    -- Broadcast guild disbanded
    self:BroadcastGuildDisbanded(guildId)
    
    print("GuildSystem: Guild disbanded:", guild.name)
    return true
end

function GuildSystem:AddGuildMember(guildId, player, role)
    local guild = self.guilds[guildId]
    if not guild then
        return false, "Guild not found"
    end
    
    local userId = player.UserId
    
    -- Check if player is already in a guild
    if self.playerGuilds[userId] then
        return false, "Player is already in a guild"
    end
    
    -- Check guild capacity
    local currentMembers = self:GetGuildMemberCount(guildId)
    local maxMembers = GUILD_LEVELS[guild.level].maxMembers
    
    if currentMembers >= maxMembers then
        return false, "Guild is at maximum capacity"
    end
    
    -- Add member
    guild.members[userId] = {
        role = role or "MEMBER",
        joinedAt = time(),
        contribution = 0,
        lastActive = time()
    }
    
    self.playerGuilds[userId] = guildId
    
    -- Broadcast member joined
    self:BroadcastGuildJoined(guildId, player)
    
    print("GuildSystem: Member added to guild:", player.Name, "->", guild.name)
    return true
end

function GuildSystem:RemoveGuildMember(guildId, player, remover)
    local guild = self.guilds[guildId]
    if not guild then
        return false, "Guild not found"
    end
    
    local userId = player.UserId
    local removerId = remover.UserId
    
    -- Check if member exists
    if not guild.members[userId] then
        return false, "Player is not a member of this guild"
    end
    
    -- Check permissions
    if not self:HasPermission(removerId, guildId, "KICK_MEMBERS") then
        return false, "Insufficient permissions"
    end
    
    -- Cannot kick leader
    if userId == guild.leader then
        return false, "Cannot kick guild leader"
    end
    
    -- Remove member
    guild.members[userId] = nil
    self.playerGuilds[userId] = nil
    
    -- Broadcast member left
    self:BroadcastGuildLeft(guildId, player)
    
    print("GuildSystem: Member removed from guild:", player.Name, "->", guild.name)
    return true
end

function GuildSystem:ChangeMemberRole(guildId, player, newRole, changer)
    local guild = self.guilds[guildId]
    if not guild then
        return false, "Guild not found"
    end
    
    local userId = player.UserId
    local changerId = changer.UserId
    
    -- Check if member exists
    if not guild.members[userId] then
        return false, "Player is not a member of this guild"
    end
    
    -- Check permissions
    if not self:HasPermission(changerId, guildId, "PROMOTE_MEMBERS") then
        return false, "Insufficient permissions"
    end
    
    -- Validate role
    if not GUILD_ROLES[newRole] then
        return false, "Invalid role"
    end
    
    -- Cannot change leader role
    if userId == guild.leader then
        return false, "Cannot change guild leader role"
    end
    
    -- Change role
    guild.members[userId].role = newRole
    
    -- Broadcast role change
    self:BroadcastGuildUpdate(guildId, "MEMBER_ROLE_CHANGED", {
        playerId = userId,
        newRole = newRole
    })
    
    print("GuildSystem: Member role changed:", player.Name, "->", newRole)
    return true
end

function GuildSystem:AddGuildExperience(guildId, amount)
    local guild = self.guilds[guildId]
    if not guild then
        return false, "Guild not found"
    end
    
    -- Add experience
    guild.experience = guild.experience + amount
    
    -- Check for level up
    while guild.experience >= guild.experienceToNext do
        guild.experience = guild.experience - guild.experienceToNext
        guild.level = guild.level + 1
        guild.experienceToNext = self:CalculateExperienceToNext(guild.level)
        
        -- Unlock new upgrades
        self:UnlockGuildUpgrades(guildId)
        
        -- Broadcast level up
        self:BroadcastGuildUpdate(guildId, "LEVEL_UP", {
            newLevel = guild.level,
            newBenefits = GUILD_LEVELS[guild.level].benefits
        })
    end
    
    return true
end

function GuildSystem:UnlockGuildUpgrades(guildId)
    local guild = self.guilds[guildId]
    if not guild then
        return false, "Guild not found"
    end
    
    local level = guild.level
    local availableUpgrades = GUILD_LEVELS[level].upgrades
    
    for _, upgradeId in ipairs(availableUpgrades) do
        if not table.find(guild.upgrades, upgradeId) then
            table.insert(guild.upgrades, upgradeId)
            
            -- Broadcast upgrade unlocked
            self:BroadcastGuildUpdate(guildId, "UPGRADE_UNLOCKED", {
                upgradeId = upgradeId,
                upgrade = GUILD_UPGRADES[upgradeId]
            })
        end
    end
    
    return true
end

function GuildSystem:ProcessGuildBenefits(guildId)
    local guild = self.guilds[guildId]
    if not guild then
        return false, "Guild not found"
    end
    
    local level = guild.level
    local benefits = GUILD_LEVELS[level].benefits
    
    -- Apply benefits to all members
    for memberId, memberData in pairs(guild.members) do
        local player = Players:GetPlayerByUserId(memberId)
        if player then
            -- Apply cash multiplier
            if benefits.cashMultiplier then
                -- This would integrate with your cash system
                print("Applying cash multiplier to", player.Name, ":", benefits.cashMultiplier)
            end
            
            -- Apply experience multiplier
            if benefits.experienceMultiplier then
                -- This would integrate with your experience system
                print("Applying experience multiplier to", player.Name, ":", benefits.experienceMultiplier)
            end
            
            -- Apply ability cost reduction
            if benefits.abilityCostReduction then
                -- This would integrate with your ability system
                print("Applying ability cost reduction to", player.Name, ":", benefits.abilityCostReduction)
            end
        end
    end
    
    return true
end

-- Guild Social Features

function GuildSystem:SendGuildChat(player, guildId, message)
    local guild = self.guilds[guildId]
    if not guild then
        return false, "Guild not found"
    end
    
    local userId = player.UserId
    
    -- Check if player is guild member
    if not guild.members[userId] then
        return false, "Player is not a member of this guild"
    end
    
    -- Validate message
    if not self:ValidateChatMessage(message) then
        return false, "Invalid message"
    end
    
    -- Broadcast chat message
    self:BroadcastGuildChat(guildId, {
        playerId = userId,
        playerName = player.Name,
        message = message,
        timestamp = time()
    })
    
    return true
end

function GuildSystem:SendGuildInvite(sender, targetPlayer, guildId)
    local guild = self.guilds[guildId]
    if not guild then
        return false, "Guild not found"
    end
    
    local senderId = sender.UserId
    local targetId = targetPlayer.UserId
    
    -- Check if sender is guild member
    if not guild.members[senderId] then
        return false, "Player is not a member of this guild"
    end
    
    -- Check permissions
    if not self:HasPermission(senderId, guildId, "INVITE_MEMBERS") then
        return false, "Insufficient permissions"
    end
    
    -- Check if target is already in a guild
    if self.playerGuilds[targetId] then
        return false, "Player is already in a guild"
    end
    
    -- Create invite
    local invite = {
        guildId = guildId,
        guildName = guild.name,
        senderId = senderId,
        senderName = sender.Name,
        targetId = targetId,
        timestamp = time(),
        expiresAt = time() + 24 * 60 * 60 -- 24 hours
    }
    
    -- Store invite
    if not self.guildInvites[targetId] then
        self.guildInvites[targetId] = {}
    end
    table.insert(self.guildInvites[targetId], invite)
    
    -- Send invite to target
    self:SendGuildInviteToPlayer(targetPlayer, invite)
    
    print("GuildSystem: Guild invite sent:", sender.Name, "->", targetPlayer.Name)
    return true
end

function GuildSystem:AcceptGuildInvite(player, inviteId)
    local userId = player.UserId
    local invites = self.guildInvites[userId]
    
    if not invites then
        return false, "No pending invites"
    end
    
    local invite = invites[inviteId]
    if not invite then
        return false, "Invite not found"
    end
    
    -- Check if invite expired
    if time() > invite.expiresAt then
        table.remove(invites, inviteId)
        return false, "Invite has expired"
    end
    
    -- Accept invite
    local success, error = self:AddGuildMember(invite.guildId, player, "MEMBER")
    if success then
        -- Remove invite
        table.remove(invites, inviteId)
        return true
    else
        return false, error
    end
end

function GuildSystem:SubmitGuildApplication(player, guildId, message)
    local guild = self.guilds[guildId]
    if not guild then
        return false, "Guild not found"
    end
    
    local userId = player.UserId
    
    -- Check if player is already in a guild
    if self.playerGuilds[userId] then
        return false, "Player is already in a guild"
    end
    
    -- Check guild settings
    if not guild.settings.public then
        return false, "Guild is not accepting applications"
    end
    
    -- Create application
    local application = {
        playerId = userId,
        playerName = player.Name,
        message = message,
        timestamp = time(),
        status = "PENDING"
    }
    
    -- Store application
    if not self.guildApplications[guildId] then
        self.guildApplications[guildId] = {}
    end
    table.insert(self.guildApplications[guildId], application)
    
    -- Notify guild officers
    self:NotifyGuildOfficers(guildId, "NEW_APPLICATION", application)
    
    print("GuildSystem: Guild application submitted:", player.Name, "->", guild.name)
    return true
end

-- Guild War System

function GuildSystem:StartGuildWar(guild1Id, guild2Id, initiator)
    local guild1 = self.guilds[guild1Id]
    local guild2 = self.guilds[guild2Id]
    
    if not guild1 or not guild2 then
        return false, "One or both guilds not found"
    end
    
    -- Check if initiator is guild leader
    if guild1.leader ~= initiator.UserId then
        return false, "Only guild leader can start war"
    end
    
    -- Check if guilds have war capability
    if not self:HasUpgrade(guild1Id, "GUILD_WARS") or not self:HasUpgrade(guild2Id, "GUILD_WARS") then
        return false, "One or both guilds cannot participate in wars"
    end
    
    -- Check if already at war
    if self:AreGuildsAtWar(guild1Id, guild2Id) then
        return false, "Guilds are already at war"
    end
    
    -- Create war
    local warId = HttpService:GenerateGUID()
    local war = {
        id = warId,
        guild1Id = guild1Id,
        guild2Id = guild2Id,
        startTime = time(),
        duration = 7 * 24 * 60 * 60, -- 7 days
        status = "ACTIVE",
        scores = {
            [guild1Id] = 0,
            [guild2Id] = 0
        },
        participants = {
            [guild1Id] = {},
            [guild2Id] = {}
        }
    }
    
    -- Store war
    self.guildWars[warId] = war
    
    -- Broadcast war started
    self:BroadcastGuildWar(guild1Id, "WAR_STARTED", war)
    self:BroadcastGuildWar(guild2Id, "WAR_STARTED", war)
    
    print("GuildSystem: Guild war started between", guild1.name, "and", guild2.name)
    return true, warId
end

function GuildSystem:ProcessGuildWars()
    local currentTime = time()
    
    for warId, war in pairs(self.guildWars) do
        if war.status == "ACTIVE" then
            -- Check if war should end
            if currentTime - war.startTime >= war.duration then
                self:EndGuildWar(warId)
            end
        end
    end
end

function GuildSystem:EndGuildWar(warId)
    local war = self.guildWars[warId]
    if not war then
        return false, "War not found"
    end
    
    -- Determine winner
    local winnerId = war.scores[war.guild1Id] > war.scores[war.guild2Id] and war.guild1Id or war.guild2Id
    local loserId = winnerId == war.guild1Id and war.guild2Id or war.guild1Id
    
    -- Update war status
    war.status = "COMPLETED"
    war.winner = winnerId
    war.endTime = time()
    
    -- Award rewards
    self:AwardWarRewards(warId, winnerId, loserId)
    
    -- Broadcast war ended
    self:BroadcastGuildWar(war.guild1Id, "WAR_ENDED", war)
    self:BroadcastGuildWar(war.guild2Id, "WAR_ENDED", war)
    
    print("GuildSystem: Guild war ended. Winner:", self.guilds[winnerId].name)
end

-- Guild Event System

function GuildSystem:CreateGuildEvent(guildId, eventType, data, creator)
    local guild = self.guilds[guildId]
    if not guild then
        return false, "Guild not found"
    end
    
    local creatorId = creator.UserId
    
    -- Check permissions
    if not self:HasPermission(creatorId, guildId, "MANAGE_GUILD") then
        return false, "Insufficient permissions"
    end
    
    -- Check if guild has events capability
    if not self:HasUpgrade(guildId, "GUILD_EVENTS") then
        return false, "Guild cannot host events"
    end
    
    -- Create event
    local eventId = HttpService:GenerateGUID()
    local event = {
        id = eventId,
        guildId = guildId,
        type = eventType,
        data = data,
        creatorId = creatorId,
        startTime = time(),
        status = "ACTIVE",
        participants = {}
    }
    
    -- Store event
    self.guildEvents[eventId] = event
    
    -- Broadcast event created
    self:BroadcastGuildEvent(guildId, "EVENT_CREATED", event)
    
    print("GuildSystem: Guild event created:", eventType, "in", guild.name)
    return true, eventId
end

-- Guild event processing functions
function GuildSystem:ProcessResourceCollectionEvent(eventId)
    local event = self.guildEvents[eventId]
    if not event then
        return
    end
    
    -- Process resource collection event
    local guild = self.guilds[event.guildId]
    if guild then
        -- Award experience to guild
        guild.experience = guild.experience + 100
        
        -- Award rewards to participants
        for memberId, _ in pairs(event.participants) do
            local player = Players:GetPlayerByUserId(memberId)
            if player then
                print("Awarding resource collection rewards to", player.Name)
            end
        end
        
        -- Mark event as completed
        event.status = "COMPLETED"
        
        -- Broadcast event completed
        self:BroadcastGuildEvent(event.guildId, "EVENT_COMPLETED", event)
    end
end

function GuildSystem:ProcessBuildingCompetitionEvent(eventId)
    local event = self.guildEvents[eventId]
    if not event then
        return
    end
    
    -- Process building competition event
    local guild = self.guilds[event.guildId]
    if guild then
        -- Award experience to guild
        guild.experience = guild.experience + 200
        
        -- Award rewards to participants
        for memberId, _ in pairs(event.participants) do
            local player = Players:GetPlayerByUserId(memberId)
            if player then
                print("Awarding building competition rewards to", player.Name)
            end
        end
        
        -- Mark event as completed
        event.status = "COMPLETED"
        
        -- Broadcast event completed
        self:BroadcastGuildEvent(event.guildId, "EVENT_COMPLETED", event)
    end
end

function GuildSystem:ProcessBossRaidEvent(eventId)
    local event = self.guildEvents[eventId]
    if not event then
        return
    end
    
    -- Process boss raid event
    local guild = self.guilds[event.guildId]
    if guild then
        -- Award experience to guild
        guild.experience = guild.experience + 300
        
        -- Award rewards to participants
        for memberId, _ in pairs(event.participants) do
            local player = Players:GetPlayerByUserId(memberId)
            if player then
                print("Awarding boss raid rewards to", player.Name)
            end
        end
        
        -- Mark event as completed
        event.status = "COMPLETED"
        
        -- Broadcast event completed
        self:BroadcastGuildEvent(event.guildId, "EVENT_COMPLETED", event)
    end
end

function GuildSystem:ProcessGuildEvents()
    local currentTime = time()
    
    for eventId, event in pairs(self.guildEvents) do
        if event.status == "ACTIVE" then
            -- Process event based on type
            if event.type == "RESOURCE_COLLECTION" then
                self:ProcessResourceCollectionEvent(eventId)
            elseif event.type == "BUILDING_COMPETITION" then
                self:ProcessBuildingCompetitionEvent(eventId)
            elseif event.type == "BOSS_RAID" then
                self:ProcessBossRaidEvent(eventId)
            end
        end
    end
end

-- Utility Functions

function GuildSystem:HasPermission(playerId, guildId, permission)
    local guild = self.guilds[guildId]
    if not guild then
        return false
    end
    
    local member = guild.members[playerId]
    if not member then
        return false
    end
    
    local role = GUILD_ROLES[member.role]
    if not role then
        return false
    end
    
    return table.find(role.permissions, permission) ~= nil
end

function GuildSystem:HasUpgrade(guildId, upgradeId)
    local guild = self.guilds[guildId]
    if not guild then
        return false
    end
    
    return table.find(guild.upgrades, upgradeId) ~= nil
end

function GuildSystem:GetGuildMemberCount(guildId)
    local guild = self.guilds[guildId]
    if not guild then
        return 0
    end
    
    local count = 0
    for _ in pairs(guild.members) do
        count = count + 1
    end
    return count
end

function GuildSystem:CalculateExperienceToNext(level)
    return level * 1000 + (level - 1) * 500
end

function GuildSystem:ValidateGuildName(name)
    return name and #name >= 3 and #name <= 20
end

function GuildSystem:ValidateGuildTag(tag)
    return tag and #tag >= 2 and #tag <= 4
end

function GuildSystem:ValidateChatMessage(message)
    return message and #message >= 1 and #message <= 200
end

function GuildSystem:IsGuildNameTaken(name)
    for _, guild in pairs(self.guilds) do
        if guild.name == name then
            return true
        end
    end
    return false
end

function GuildSystem:IsGuildTagTaken(tag)
    for _, guild in pairs(self.guilds) do
        if guild.tag == tag then
            return true
        end
    end
    return false
end

function GuildSystem:AreGuildsAtWar(guild1Id, guild2Id)
    for _, war in pairs(self.guildWars) do
        if war.status == "ACTIVE" and 
           ((war.guild1Id == guild1Id and war.guild2Id == guild2Id) or
            (war.guild1Id == guild2Id and war.guild2Id == guild1Id)) then
            return true
        end
    end
    return false
end

-- Broadcasting Functions

function GuildSystem:BroadcastGuildCreated(guild)
    if self.remoteEvents.GuildCreated then
        self.remoteEvents.GuildCreated:FireAllClients(guild)
    end
end

function GuildSystem:BroadcastGuildJoined(guildId, player)
    if self.remoteEvents.GuildJoined then
        self.remoteEvents.GuildJoined:FireAllClients(guildId, player)
    end
end

function GuildSystem:BroadcastGuildLeft(guildId, player)
    if self.remoteEvents.GuildLeft then
        self.remoteEvents.GuildLeft:FireAllClients(guildId, player)
    end
end

function GuildSystem:BroadcastGuildUpdate(guildId, updateType, data)
    if self.remoteEvents.GuildUpdate then
        self.remoteEvents.GuildUpdate:FireAllClients(guildId, updateType, data)
    end
end

function GuildSystem:BroadcastGuildChat(guildId, chatData)
    if self.remoteEvents.GuildChat then
        self.remoteEvents.GuildChat:FireAllClients(guildId, chatData)
    end
end

function GuildSystem:BroadcastGuildWar(guildId, warType, warData)
    if self.remoteEvents.GuildWar then
        self.remoteEvents.GuildWar:FireAllClients(guildId, warType, warData)
    end
end

function GuildSystem:BroadcastGuildEvent(guildId, eventType, eventData)
    if self.remoteEvents.GuildEvent then
        self.remoteEvents.GuildEvent:FireAllClients(guildId, eventType, eventData)
    end
end

-- New anime-specific broadcasting functions

function GuildSystem:BroadcastAnimeGuildCreated(guild)
    if self.remoteEvents.AnimeGuildCreated then
        self.remoteEvents.AnimeGuildCreated:FireAllClients(guild)
    end
end

function GuildSystem:BroadcastAnimeGuildWarStarted(war)
    if self.remoteEvents.AnimeGuildWarStarted then
        self.remoteEvents.AnimeGuildWarStarted:FireAllClients(war)
    end
end

function GuildSystem:BroadcastAnimeGuildThemeChanged(guildId, oldTheme, newTheme)
    if self.remoteEvents.AnimeGuildThemeChanged then
        self.remoteEvents.AnimeGuildThemeChanged:FireAllClients(guildId, oldTheme, newTheme)
    end
end

function GuildSystem:BroadcastAnimeGuildBonusActivated(guildId, bonusId, bonus)
    if self.remoteEvents.AnimeGuildBonusActivated then
        self.remoteEvents.AnimeGuildBonusActivated:FireAllClients(guildId, bonusId, bonus)
    end
end

function GuildSystem:BroadcastAnimeGuildWar(guildId, warType, warData)
    if self.remoteEvents.GuildWar then
        self.remoteEvents.GuildWar:FireAllClients(guildId, warType, warData)
    end
end

-- Cross-anime collaboration broadcasting functions
function GuildSystem:BroadcastCrossAnimeCollaborationStarted(collaboration)
    if self.remoteEvents.GuildEvent then
        self.remoteEvents.GuildEvent:FireAllClients(collaboration.guild1Id, "CROSS_ANIME_COLLABORATION_STARTED", collaboration)
        self.remoteEvents.GuildEvent:FireAllClients(collaboration.guild2Id, "CROSS_ANIME_COLLABORATION_STARTED", collaboration)
    end
end

function GuildSystem:BroadcastCrossAnimeCollaborationEvent(guildId, eventType, eventData)
    if self.remoteEvents.GuildEvent then
        self.remoteEvents.GuildEvent:FireAllClients(guildId, eventType, eventData)
    end
end

function GuildSystem:BroadcastCrossAnimeCollaborationEnded(collaboration)
    if self.remoteEvents.GuildEvent then
        self.remoteEvents.GuildEvent:FireAllClients(collaboration.guild1Id, "CROSS_ANIME_COLLABORATION_ENDED", collaboration)
        self.remoteEvents.GuildEvent:FireAllClients(collaboration.guild2Id, "CROSS_ANIME_COLLABORATION_ENDED", collaboration)
    end
end

-- Anime festival broadcasting functions
function GuildSystem:BroadcastAnimeFestivalCreated(festival)
    if self.remoteEvents.GuildEvent then
        self.remoteEvents.GuildEvent:FireAllClients(festival.guildId, "ANIME_FESTIVAL_CREATED", festival)
    end
end

function GuildSystem:BroadcastAnimeFestivalEvent(guildId, eventType, eventData)
    if self.remoteEvents.GuildEvent then
        self.remoteEvents.GuildEvent:FireAllClients(guildId, eventType, eventData)
    end
end

function GuildSystem:BroadcastAnimeFestivalEnded(festival)
    if self.remoteEvents.GuildEvent then
        self.remoteEvents.GuildEvent:FireAllClients(festival.guildId, "ANIME_FESTIVAL_ENDED", festival)
    end
end

-- Additional missing broadcast functions
function GuildSystem:BroadcastGuildDisbanded(guildId)
    if self.remoteEvents.GuildUpdate then
        self.remoteEvents.GuildUpdate:FireAllClients(guildId, "GUILD_DISBANDED", {})
    end
end

function GuildSystem:BroadcastGuildInvite(guildId, invite)
    if self.remoteEvents.GuildInvite then
        self.remoteEvents.GuildInvite:FireAllClients(guildId, invite)
    end
end

function GuildSystem:BroadcastGuildApplication(guildId, application)
    if self.remoteEvents.GuildApplication then
        self.remoteEvents.GuildApplication:FireAllClients(guildId, application)
    end
end

function GuildSystem:SendGuildInviteToPlayer(player, invite)
    if self.remoteEvents.GuildInvite then
        self.remoteEvents.GuildInvite:FireClient(player, invite)
    end
end

function GuildSystem:NotifyGuildOfficers(guildId, notificationType, data)
    local guild = self.guilds[guildId]
    if not guild then
        return
    end
    
    for memberId, memberData in pairs(guild.members) do
        if memberData.role == "LEADER" or memberData.role == "OFFICER" then
            local player = Players:GetPlayerByUserId(memberId)
            if player then
                -- Send notification to officer
                print("Notifying officer:", player.Name, "of", notificationType)
            end
        end
    end
end

-- Public API

function GuildSystem:GetGuild(guildId)
    return self.guilds[guildId]
end

function GuildSystem:GetPlayerGuild(playerId)
    local guildId = self.playerGuilds[playerId]
    if guildId then
        return self.guilds[guildId]
    end
    return nil
end

function GuildSystem:GetGuildMembers(guildId)
    local guild = self.guilds[guildId]
    if not guild then
        return {}
    end
    
    local members = {}
    for memberId, memberData in pairs(guild.members) do
        local player = Players:GetPlayerByUserId(memberId)
        if player then
            table.insert(members, {
                player = player,
                data = memberData
            })
        end
    end
    
    return members
end

function GuildSystem:GetGuildInvites(playerId)
    return self.guildInvites[playerId] or {}
end

function GuildSystem:GetGuildApplications(guildId)
    return self.guildApplications[guildId] or {}
end

function GuildSystem:GetGuildWars(guildId)
    local wars = {}
    for warId, war in pairs(self.guildWars) do
        if war.guild1Id == guildId or war.guild2Id == guildId then
            table.insert(wars, war)
        end
    end
    return wars
end

function GuildSystem:GetGuildEvents(guildId)
    local events = {}
    for eventId, event in pairs(self.guildEvents) do
        if event.guildId == guildId then
            table.insert(events, event)
        end
    end
    return events
end

-- New anime-specific public API functions

function GuildSystem:GetAnimeGuildThemes()
    return ANIME_GUILD_THEMES
end

function GuildSystem:GetGuildAnimeTheme(guildId)
    return self.animeGuildThemes[guildId]
end

function GuildSystem:GetAnimeGuildBonuses(guildId)
    return self.animeGuildBonuses[guildId] or {}
end

function GuildSystem:GetActiveAnimeGuildBonus(guildId, bonusId)
    local guildBonuses = self.animeGuildBonuses[guildId]
    if guildBonuses and guildBonuses[bonusId] then
        local bonus = guildBonuses[bonusId]
        if time() < bonus.expiresAt then
            return bonus
        end
    end
    return nil
end

function GuildSystem:GetAnimeGuildWars(guildId)
    local wars = {}
    for warId, war in pairs(self.animeGuildWars) do
        if war.guild1Id == guildId or war.guild2Id == guildId then
            table.insert(wars, war)
        end
    end
    return wars
end

function GuildSystem:GetAnimeGuildWar(warId)
    return self.animeGuildWars[warId]
end

function GuildSystem:GetAnimeGuildWarEvents(warId)
    local war = self.animeGuildWars[warId]
    if war then
        return war.animeWarEvents
    end
    return {}
end

function GuildSystem:GetAnimeGuildsByTheme(animeTheme)
    local guilds = {}
    for guildId, theme in pairs(self.animeGuildThemes) do
        if theme == animeTheme then
            local guild = self.guilds[guildId]
            if guild then
                table.insert(guilds, guild)
            end
        end
    end
    return guilds
end

function GuildSystem:GetAnimeGuildStats(guildId)
    local guild = self.guilds[guildId]
    if not guild or not guild.animeTheme then
        return nil
    end
    
    local stats = {
        theme = guild.animeTheme,
        themeData = guild.animeThemeData,
        activeBonuses = {},
        warHistory = guild.animeWarHistory or {},
        themeMastery = 0,
        animePoints = 0
    }
    
    -- Get active bonuses
    local guildBonuses = self.animeGuildBonuses[guildId]
    if guildBonuses then
        for bonusId, bonus in pairs(guildBonuses) do
            if time() < bonus.expiresAt then
                stats.activeBonuses[bonusId] = bonus
            end
        end
    end
    
    -- Calculate theme mastery based on guild level and experience
    stats.themeMastery = math.floor((guild.level * 100 + guild.experience / 100) / 10)
    
    -- Calculate anime points (placeholder for future integration)
    stats.animePoints = guild.level * 100 + guild.experience / 10
    
    return stats
end

function GuildSystem:GetAnimeGuildLeaderboard(animeTheme)
    local guilds = self:GetAnimeGuildsByTheme(animeTheme)
    
    -- Sort by anime points (theme mastery)
    table.sort(guilds, function(a, b)
        local aStats = self:GetAnimeGuildStats(a.id)
        local bStats = self:GetAnimeGuildStats(b.id)
        
        if aStats and bStats then
            return aStats.animePoints > bStats.animePoints
        end
        return false
    end)
    
    return guilds
end

function GuildSystem:GetCrossAnimeCollaborations()
    return self.crossAnimeCollaborations
end

function GuildSystem:GetAnimeFestivals()
    return self.animeFestivals
end

function GuildSystem:GetAnimeGuildMetrics()
    local metrics = {
        totalAnimeGuilds = 0,
        animeThemeDistribution = {},
        activeAnimeWars = 0,
        activeAnimeBonuses = 0,
        animeGuildLevels = {}
    }
    
    -- Count anime guilds and themes
    for guildId, theme in pairs(self.animeGuildThemes) do
        metrics.totalAnimeGuilds = metrics.totalAnimeGuilds + 1
        metrics.animeThemeDistribution[theme] = (metrics.animeThemeDistribution[theme] or 0) + 1
        
        local guild = self.guilds[guildId]
        if guild then
            metrics.animeGuildLevels[guild.level] = (metrics.animeGuildLevels[guild.level] or 0) + 1
        end
    end
    
    -- Count active anime wars
    for _, war in pairs(self.animeGuildWars) do
        if war.status == "ACTIVE" and war.warType == "ANIME_WAR" then
            metrics.activeAnimeWars = metrics.activeAnimeWars + 1
        end
    end
    
    -- Count active anime bonuses
    for guildId, bonuses in pairs(self.animeGuildBonuses) do
        for _, bonus in pairs(bonuses) do
            if time() < bonus.expiresAt then
                metrics.activeAnimeBonuses = metrics.activeAnimeBonuses + 1
            end
        end
    end
    
    return metrics
end

-- Get guild system metrics
function GuildSystem:GetGuildMetrics()
    local metrics = {
        totalGuilds = 0,
        totalMembers = 0,
        activeGuilds = 0,
        guildLevels = {},
        roleDistribution = {}
    }
    
    for guildId, guildData in pairs(self.guilds) do
        metrics.totalGuilds = metrics.totalGuilds + 1
        
        if guildData.members then
            local memberCount = 0
            for role, members in pairs(guildData.members) do
                memberCount = memberCount + #members
                metrics.roleDistribution[role] = (metrics.roleDistribution[role] or 0) + #members
            end
            metrics.totalMembers = metrics.totalMembers + memberCount
            
            if memberCount > 0 then
                metrics.activeGuilds = metrics.activeGuilds + 1
            end
        end
        
        if guildData.level then
            metrics.guildLevels[guildData.level] = (metrics.guildLevels[guildData.level] or 0) + 1
        end
    end
    
    return metrics
end

-- Cleanup

function GuildSystem:Cleanup()
    print("GuildSystem: Cleaning up...")
    
    -- Disconnect all connections
    -- Clean up remote events
    -- Reset data structures
    
    print("GuildSystem: Cleanup completed")
end

return GuildSystem
