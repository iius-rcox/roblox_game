-- GuildSystem.lua
-- Advanced guild and alliance system for Milestone 3: Competitive & Social Systems
-- Handles guild creation, management, benefits, and social features

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Constants = require(script.Parent.Parent.Utils.Constants)
local NetworkManager = require(script.Parent.Parent.Multiplayer.NetworkManager)

local GuildSystem = {}
GuildSystem.__index = GuildSystem

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
    GuildApplication = "GuildApplication"
}

-- Guild roles and permissions
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
            "MANAGE_UPGRADES"
        }
    },
    OFFICER = {
        name = "Officer",
        level = 3,
        permissions = {
            "INVITE_MEMBERS",
            "KICK_MEMBERS",
            "PROMOTE_MEMBERS",
            "MANAGE_UPGRADES"
        }
    },
    VETERAN = {
        name = "Veteran",
        level = 2,
        permissions = {
            "INVITE_MEMBERS"
        }
    },
    MEMBER = {
        name = "Member",
        level = 1,
        permissions = {}
    }
}

-- Guild levels and benefits
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
            "CUSTOM_THEMES",
            "ELITE_BONUSES",
            "GUILD_LEADERBOARDS"
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
        }
    }
}

-- Guild upgrade costs and effects
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
    CUSTOM_THEMES = {
        name = "Custom Themes",
        cost = 50000,
        description = "Create unique guild visual themes",
        effect = "Enables custom guild themes and cosmetics"
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

function GuildSystem:StartUpdateLoop()
    -- Update guilds and process events
    RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        
        -- Process guild updates
        if currentTime % self.guildUpdateInterval < 0.1 then
            self:UpdateAllGuilds()
        end
        
        -- Process guild wars
        self:ProcessGuildWars()
        
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
            joinedAt = tick(),
            contribution = 0,
            lastActive = tick()
        }},
        level = 1,
        experience = 0,
        experienceToNext = self:CalculateExperienceToNext(1),
        treasury = 0,
        upgrades = {"GUILD_CHAT", "BASIC_BONUSES"},
        createdAt = tick(),
        lastActive = tick(),
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
        joinedAt = tick(),
        contribution = 0,
        lastActive = tick()
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
        timestamp = tick()
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
        timestamp = tick(),
        expiresAt = tick() + 24 * 60 * 60 -- 24 hours
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
    if tick() > invite.expiresAt then
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
        timestamp = tick(),
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
        startTime = tick(),
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
    local currentTime = tick()
    
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
    war.endTime = tick()
    
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
        startTime = tick(),
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

function GuildSystem:ProcessGuildEvents()
    local currentTime = tick()
    
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
