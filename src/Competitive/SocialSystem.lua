-- SocialSystem.lua
-- Advanced social system for Milestone 3: Competitive & Social Systems
-- Handles friends, chat, communication, and community features
-- Enhanced with anime-themed social features (Step 12)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")

local Constants = require(script.Parent.Parent.Utils.Constants)
local NetworkManager = require(script.Parent.Parent.Multiplayer.NetworkManager)

local SocialSystem = {}
SocialSystem.__index = SocialSystem

-- RemoteEvents for client-server communication
local RemoteEvents = {
    FriendRequest = "FriendRequest",
    FriendAdded = "FriendAdded",
    FriendRemoved = "FriendRemoved",
    FriendOnline = "FriendOnline",
    FriendOffline = "FriendOffline",
    ChatMessage = "ChatMessage",
    PrivateMessage = "PrivateMessage",
    SocialGroupCreated = "SocialGroupCreated",
    SocialGroupJoined = "SocialGroupJoined",
    SocialGroupLeft = "SocialGroupLeft",
    VoiceChatUpdate = "VoiceChatUpdate",
    EmoteUsed = "EmoteUsed",
    -- Anime-specific social events
    AnimeFandomJoined = "AnimeFandomJoined",
    AnimeFandomLeft = "AnimeFandomLeft",
    AnimeChatMessage = "AnimeChatMessage",
    AnimeEventJoined = "AnimeEventJoined",
    AnimeEventLeft = "AnimeEventLeft",
    AnimeAchievementUnlocked = "AnimeAchievementUnlocked",
    AnimeFandomInvitation = "AnimeFandomInvitation",
    AnimeCollaborationStarted = "AnimeCollaborationStarted",
    AnimeFanArtShared = "AnimeFanArtShared",
    AnimeDiscussionCreated = "AnimeDiscussionCreated"
}

-- Chat channel types
local CHAT_CHANNELS = {
    GLOBAL = "GLOBAL",
    GUILD = "GUILD",
    TRADE = "TRADE",
    COMPETITIVE = "COMPETITIVE",
    LOCAL = "LOCAL",
    -- Anime-specific chat channels
    NARUTO = "NARUTO",
    DRAGON_BALL = "DRAGON_BALL",
    ONE_PIECE = "ONE_PIECE",
    ATTACK_ON_TITAN = "ATTACK_ON_TITAN",
    MY_HERO_ACADEMIA = "MY_HERO_ACADEMIA",
    DEMON_SLAYER = "DEMON_SLAYER",
    JUJUTSU_KAISEN = "JUJUTSU_KAISEN",
    HUNTER_X_HUNTER = "HUNTER_X_HUNTER",
    FAIRY_TAIL = "FAIRY_TAIL",
    BLEACH = "BLEACH",
    FULLMETAL_ALCHEMIST = "FULLMETAL_ALCHEMIST",
    DEATH_NOTE = "DEATH_NOTE",
    CODE_GEASS = "CODE_GEASS",
    STEINS_GATE = "STEINS_GATE",
    EVANGELION = "EVANGELION",
    COWBOY_BEBOP = "COWBOY_BEBOP",
    GHOST_IN_THE_SHELL = "GHOST_IN_THE_SHELL",
    AKIRA = "AKIRA",
    SPIRITED_AWAY = "SPIRITED_AWAY",
    PRINCESS_MONONOKE = "PRINCESS_MONONOKE"
}

-- Friend request status
local FRIEND_STATUS = {
    PENDING = "PENDING",
    ACCEPTED = "ACCEPTED",
    DECLINED = "DECLINED",
    BLOCKED = "BLOCKED"
}

-- Social group types
local GROUP_TYPES = {
    TRADING = "TRADING",
    COMPETITIVE = "COMPETITIVE",
    SOCIAL = "SOCIAL",
    CREATIVE = "CREATIVE",
    -- Anime-specific group types
    ANIME_FANDOM = "ANIME_FANDOM",
    ANIME_DISCUSSION = "ANIME_DISCUSSION",
    ANIME_COLLABORATION = "ANIME_COLLABORATION",
    ANIME_FAN_ART = "ANIME_FAN_ART",
    ANIME_THEORY = "ANIME_THEORY"
}

-- Anime fandom types
local ANIME_FANDOM_TYPES = {
    NARUTO = "NARUTO",
    DRAGON_BALL = "DRAGON_BALL",
    ONE_PIECE = "ONE_PIECE",
    ATTACK_ON_TITAN = "ATTACK_ON_TITAN",
    MY_HERO_ACADEMIA = "MY_HERO_ACADEMIA",
    DEMON_SLAYER = "DEMON_SLAYER",
    JUJUTSU_KAISEN = "JUJUTSU_KAISEN",
    HUNTER_X_HUNTER = "HUNTER_X_HUNTER",
    FAIRY_TAIL = "FAIRY_TAIL",
    BLEACH = "BLEACH",
    FULLMETAL_ALCHEMIST = "FULLMETAL_ALCHEMIST",
    DEATH_NOTE = "DEATH_NOTE",
    CODE_GEASS = "CODE_GEASS",
    STEINS_GATE = "STEINS_GATE",
    EVANGELION = "EVANGELION",
    COWBOY_BEBOP = "COWBOY_BEBOP",
    GHOST_IN_THE_SHELL = "GHOST_IN_THE_SHELL",
    AKIRA = "AKIRA",
    SPIRITED_AWAY = "SPIRITED_AWAY",
    PRINCESS_MONONOKE = "PRINCESS_MONONOKE"
}

-- Anime event types
local ANIME_EVENT_TYPES = {
    WATCH_PARTY = "WATCH_PARTY",
    DISCUSSION_GROUP = "DISCUSSION_GROUP",
    FAN_ART_CONTEST = "FAN_ART_CONTEST",
    THEORY_CRAFTING = "THEORY_CRAFTING",
    CHARACTER_DEBATE = "CHARACTER_DEBATE",
    EPISODE_REVIEW = "EPISODE_REVIEW",
    MANGA_DISCUSSION = "MANGA_DISCUSSION",
    COSPLAY_SHOWCASE = "COSPLAY_SHOWCASE",
    VOICE_ACTOR_APPRECIATION = "VOICE_ACTOR_APPRECIATION",
    ANIME_MUSIC_SHARING = "ANIME_MUSIC_SHARING"
}

-- Anime achievement categories
local ANIME_ACHIEVEMENT_CATEGORIES = {
    FANDOM_LEADER = "FANDOM_LEADER",
    DISCUSSION_MASTER = "DISCUSSION_MASTER",
    COLLABORATION_EXPERT = "COLLABORATION_EXPERT",
    FAN_ART_ARTIST = "FAN_ART_ARTIST",
    THEORY_CRAFTER = "THEORY_CRAFTER",
    EVENT_ORGANIZER = "EVENT_ORGANIZER",
    COMMUNITY_BUILDER = "COMMUNITY_BUILDER",
    ANIME_KNOWLEDGE = "ANIME_KNOWLEDGE",
    SOCIAL_BUTTERFLY = "SOCIAL_BUTTERFLY",
    CROSS_FANDOM_BRIDGE = "CROSS_FANDOM_BRIDGE"
}

function SocialSystem.new()
    local self = setmetatable({}, SocialSystem)
    
    -- Core data structures
    self.friends = {}                 -- Player -> Friend Data
    self.chatChannels = {}            -- Channel -> Chat Data
    self.privateMessages = {}         -- Player -> Message Data
    self.socialGroups = {}            -- Group -> Member Data
    self.voiceChat = {}               -- Voice communication
    self.emoteSystem = {}             -- Custom emotes and expressions
    
    -- Anime-specific social data structures
    self.animeFandoms = {}            -- Anime -> Fandom Data
    self.animeEvents = {}             -- Event -> Event Data
    self.animeAchievements = {}       -- Player -> Achievement Data
    self.animeDiscussions = {}        -- Discussion -> Discussion Data
    self.animeCollaborations = {}     -- Collaboration -> Collaboration Data
    self.animeFanArt = {}             -- Fan Art -> Fan Art Data
    self.animeTheories = {}           -- Theory -> Theory Data
    self.animeFandomMembers = {}      -- Player -> Fandom Memberships
    self.animeEventParticipants = {}  -- Event -> Participants
    self.animeSocialMetrics = {}      -- Anime -> Social Metrics
    
    -- Network manager reference
    self.networkManager = nil
    
    -- Initialize remote events
    self.remoteEvents = {}
    
    -- Social settings
    self.maxFriends = 100             -- Maximum friends per player
    self.maxPrivateMessages = 50      -- Maximum stored private messages
    self.chatCooldown = 1             -- Seconds between chat messages
    self.maxGroupMembers = 20         -- Maximum members per social group
    
    -- Anime-specific social settings
    self.maxAnimeFandoms = 5          -- Maximum anime fandoms per player
    self.maxAnimeEvents = 10          -- Maximum anime events per player
    self.animeChatCooldown = 2        -- Seconds between anime chat messages
    self.maxAnimeDiscussions = 50     -- Maximum anime discussions per fandom
    self.maxAnimeCollaborations = 15  -- Maximum anime collaborations per player
    self.maxAnimeFanArt = 100         -- Maximum fan art pieces per player
    self.maxAnimeTheories = 25        -- Maximum theories per player
    
    -- Performance tracking
    self.lastChatUpdate = 0
    self.chatUpdateInterval = 5       -- Update chat every 5 seconds
    self.lastAnimeSocialUpdate = 0
    self.animeSocialUpdateInterval = 10 -- Update anime social every 10 seconds
    
    return self
end

function SocialSystem:Initialize(networkManager)
    self.networkManager = networkManager
    
    -- Set up remote events
    self:SetupRemoteEvents()
    
    -- Connect to player events
    self:ConnectPlayerEvents()
    
    -- Initialize chat channels
    self:InitializeChatChannels()
    
    -- Initialize emote system
    self:InitializeEmoteSystem()
    
    -- Initialize anime social systems
    self:InitializeAnimeSocialSystems()
    
    -- Set up periodic updates
    self:SetupPeriodicUpdates()
    
    print("SocialSystem: Initialized successfully with anime social features!")
end

-- Set up remote events for client-server communication
function SocialSystem:SetupRemoteEvents()
    for eventName, eventId in pairs(RemoteEvents) do
        local remoteEvent = Instance.new("RemoteEvent")
        remoteEvent.Name = eventId
        remoteEvent.Parent = self.networkManager:GetRemoteFolder()
        
        self.remoteEvents[eventName] = remoteEvent
    end
end

-- Connect to player events
function SocialSystem:ConnectPlayerEvents()
    Players.PlayerAdded:Connect(function(player)
        self:InitializePlayerData(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:CleanupPlayerData(player)
    end)
end

-- Initialize player social data
function SocialSystem:InitializePlayerData(player)
    local userId = player.UserId
    
    if not self.friends[userId] then
        self.friends[userId] = {
            friends = {},
            pendingRequests = {},
            blockedPlayers = {},
            lastOnline = time(),
            status = "ONLINE"
        }
    end
    
    if not self.privateMessages[userId] then
        self.privateMessages[userId] = {
            messages = {},
            unreadCount = 0
        }
    end
    
    -- Notify friends that player is online
    self:NotifyFriendsOnline(player)
end

-- Clean up player data when they leave
function SocialSystem:CleanupPlayerData(player)
    local userId = player.UserId
    
    -- Notify friends that player is offline
    self:NotifyFriendsOffline(player)
    
    -- Remove from social groups
    for groupId, groupData in pairs(self.socialGroups) do
        if groupData.members[userId] then
            self:RemoveFromSocialGroup(groupId, player)
        end
    end
    
    -- Remove from friends lists
    self.friends[userId] = nil
    self.privateMessages[userId] = nil
end

-- Friend system functions
function SocialSystem:SendFriendRequest(sender, receiver)
    if not sender or not receiver then
        return false, "Invalid players"
    end
    
    local senderId = sender.UserId
    local receiverId = receiver.UserId
    
    -- Check if already friends
    if self:ArePlayersFriends(senderId, receiverId) then
        return false, "Players are already friends"
    end
    
    -- Check if request already exists
    if self:HasFriendRequest(senderId, receiverId) then
        return false, "Friend request already sent"
    end
    
    -- Check if blocked
    if self:IsPlayerBlocked(senderId, receiverId) then
        return false, "Cannot send friend request to blocked player"
    end
    
    -- Check friend limits
    local senderFriends = self.friends[senderId]
    local receiverFriends = self.friends[receiverId]
    
    if senderFriends and #senderFriends.friends >= self.maxFriends then
        return false, "Sender has reached maximum friends limit"
    end
    
    if receiverFriends and #receiverFriends.friends >= self.maxFriends then
        return false, "Receiver has reached maximum friends limit"
    end
    
    -- Create friend request
    local requestId = HttpService:GenerateGUID()
    local request = {
        id = requestId,
        sender = senderId,
        senderName = sender.Name,
        receiver = receiverId,
        receiverName = receiver.Name,
        timestamp = time(),
        status = FRIEND_STATUS.PENDING
    }
    
    -- Add to pending requests
    if not self.friends[receiverId] then
        self.friends[receiverId] = {
            friends = {},
            pendingRequests = {},
            blockedPlayers = {},
            lastOnline = time(),
            status = "OFFLINE"
        }
    end
    
    table.insert(self.friends[receiverId].pendingRequests, request)
    
    -- Notify receiver
    self:NotifyFriendRequest(receiver, request)
    
    print("SocialSystem: " .. sender.Name .. " sent friend request to " .. receiver.Name)
    
    return requestId
end

function SocialSystem:AcceptFriendRequest(player, requestId)
    local userId = player.UserId
    local playerData = self.friends[userId]
    
    if not playerData then
        return false, "Player data not found"
    end
    
    -- Find the request
    local request = nil
    local requestIndex = nil
    
    for i, req in ipairs(playerData.pendingRequests) do
        if req.id == requestId then
            request = req
            requestIndex = i
            break
        end
    end
    
    if not request then
        return false, "Friend request not found"
    end
    
    -- Check if both players can still be friends
    local senderData = self.friends[request.sender]
    if not senderData then
        return false, "Sender data not found"
    end
    
    if #playerData.friends >= self.maxFriends then
        return false, "Player has reached maximum friends limit"
    end
    
    if #senderData.friends >= self.maxFriends then
        return false, "Sender has reached maximum friends limit"
    end
    
    -- Add to friends lists
    table.insert(playerData.friends, {
        userId = request.sender,
        name = request.senderName,
        addedAt = time()
    })
    
    table.insert(senderData.friends, {
        userId = userId,
        name = player.Name,
        addedAt = time()
    })
    
    -- Remove from pending requests
    table.remove(playerData.pendingRequests, requestIndex)
    
    -- Mark request as accepted
    request.status = FRIEND_STATUS.ACCEPTED
    
    -- Notify both players
    self:NotifyFriendAdded(player, request)
    self:NotifyFriendAdded(Players:GetPlayerByUserId(request.sender), request)
    
    print("SocialSystem: " .. player.Name .. " accepted friend request from " .. request.senderName)
    
    return true
end

function SocialSystem:DeclineFriendRequest(player, requestId)
    local userId = player.UserId
    local playerData = self.friends[userId]
    
    if not playerData then
        return false, "Player data not found"
    end
    
    -- Find and remove the request
    for i, req in ipairs(playerData.pendingRequests) do
        if req.id == requestId then
            req.status = FRIEND_STATUS.DECLINED
            table.remove(playerData.pendingRequests, i)
            
            print("SocialSystem: " .. player.Name .. " declined friend request from " .. req.senderName)
            return true
        end
    end
    
    return false, "Friend request not found"
end

function SocialSystem:RemoveFriend(player, friendUserId)
    local userId = player.UserId
    local playerData = self.friends[userId]
    local friendData = self.friends[friendUserId]
    
    if not playerData or not friendData then
        return false, "Player data not found"
    end
    
    -- Remove from both friends lists
    for i, friend in ipairs(playerData.friends) do
        if friend.userId == friendUserId then
            table.remove(playerData.friends, i)
            break
        end
    end
    
    for i, friend in ipairs(friendData.friends) do
        if friend.userId == userId then
            table.remove(friendData.friends, i)
            break
        end
    end
    
    -- Notify both players
    local friendPlayer = Players:GetPlayerByUserId(friendUserId)
    if friendPlayer then
        self:NotifyFriendRemoved(friendPlayer, player)
    end
    
    self:NotifyFriendRemoved(player, friendPlayer or { Name = "Unknown", UserId = friendUserId })
    
    print("SocialSystem: " .. player.Name .. " removed friend " .. (friendPlayer and friendPlayer.Name or "Unknown"))
    
    return true
end

function SocialSystem:BlockPlayer(player, targetUserId)
    local userId = player.UserId
    local playerData = self.friends[userId]
    
    if not playerData then
        return false, "Player data not found"
    end
    
    -- Remove from friends if they were friends
    self:RemoveFriend(player, targetUserId)
    
    -- Add to blocked list
    table.insert(playerData.blockedPlayers, {
        userId = targetUserId,
        blockedAt = time()
    })
    
    print("SocialSystem: " .. player.Name .. " blocked player " .. targetUserId)
    
    return true
end

function SocialSystem:UnblockPlayer(player, targetUserId)
    local userId = player.UserId
    local playerData = self.friends[userId]
    
    if not playerData then
        return false, "Player data not found"
    end
    
    -- Remove from blocked list
    for i, blocked in ipairs(playerData.blockedPlayers) do
        if blocked.userId == targetUserId then
            table.remove(playerData.blockedPlayers, i)
            
            print("SocialSystem: " .. player.Name .. " unblocked player " .. targetUserId)
            return true
        end
    end
    
    return false, "Player not found in blocked list"
end

-- Chat system functions
function SocialSystem:SendChatMessage(player, channelId, message)
    if not player or not message or message == "" then
        return false, "Invalid message"
    end
    
    -- Check chat cooldown
    local userId = player.UserId
    local lastMessageTime = self.lastChatUpdate
    if time() - lastMessageTime < self.chatCooldown then
        return false, "Message sent too quickly"
    end
    
    -- Filter inappropriate content
    local filteredMessage = self:FilterMessage(message)
    if filteredMessage ~= message then
        return false, "Message contains inappropriate content"
    end
    
    -- Create chat message
    local chatMessage = {
        id = HttpService:GenerateGUID(),
        sender = userId,
        senderName = player.Name,
        channel = channelId,
        message = filteredMessage,
        timestamp = time()
    }
    
    -- Add to chat channel
    if not self.chatChannels[channelId] then
        self.chatChannels[channelId] = {
            messages = {},
            lastMessage = 0
        }
    end
    
    table.insert(self.chatChannels[channelId].messages, chatMessage)
    
    -- Keep only last 100 messages per channel
    if #self.chatChannels[channelId].messages > 100 then
        table.remove(self.chatChannels[channelId].messages, 1)
    end
    
    self.chatChannels[channelId].lastMessage = time()
    
    -- Broadcast to channel
    self:BroadcastChatMessage(channelId, chatMessage)
    
    print("SocialSystem: " .. player.Name .. " sent message in " .. channelId .. ": " .. filteredMessage)
    
    return true
end

function SocialSystem:SendPrivateMessage(sender, receiver, message)
    if not sender or not receiver or not message or message == "" then
        return false, "Invalid message or players"
    end
    
    local senderId = sender.UserId
    local receiverId = receiver.UserId
    
    -- Check if blocked
    if self:IsPlayerBlocked(senderId, receiverId) then
        return false, "Cannot send message to blocked player"
    end
    
    -- Filter inappropriate content
    local filteredMessage = self:FilterMessage(message)
    if filteredMessage ~= message then
        return false, "Message contains inappropriate content"
    end
    
    -- Create private message
    local privateMessage = {
        id = HttpService:GenerateGUID(),
        sender = senderId,
        senderName = sender.Name,
        receiver = receiverId,
        receiverName = receiver.Name,
        message = filteredMessage,
        timestamp = time(),
        read = false
    }
    
    -- Add to receiver's private messages
    if not self.privateMessages[receiverId] then
        self.privateMessages[receiverId] = {
            messages = {},
            unreadCount = 0
        }
    end
    
    table.insert(self.privateMessages[receiverId].messages, privateMessage)
    self.privateMessages[receiverId].unreadCount = self.privateMessages[receiverId].unreadCount + 1
    
    -- Keep only last N messages
    if #self.privateMessages[receiverId].messages > self.maxPrivateMessages then
        table.remove(self.privateMessages[receiverId].messages, 1)
        if self.privateMessages[receiverId].unreadCount > 0 then
            self.privateMessages[receiverId].unreadCount = self.privateMessages[receiverId].unreadCount - 1
        end
    end
    
    -- Notify receiver
    self:NotifyPrivateMessage(receiver, privateMessage)
    
    print("SocialSystem: " .. sender.Name .. " sent private message to " .. receiver.Name)
    
    return true
end

-- Social group functions
function SocialSystem:CreateSocialGroup(creator, groupName, groupType, description)
    if not creator or not groupName or groupName == "" then
        return false, "Invalid creator or group name"
    end
    
    local userId = creator.UserId
    
    -- Check if player is already in a group
    for groupId, groupData in pairs(self.socialGroups) do
        if groupData.members[userId] then
            return false, "Player is already in a social group"
        end
    end
    
    -- Create new group
    local groupId = HttpService:GenerateGUID()
    local group = {
        id = groupId,
        name = groupName,
        type = groupType or GROUP_TYPES.SOCIAL,
        description = description or "",
        creator = userId,
        creatorName = creator.Name,
        members = {},
        maxMembers = self.maxGroupMembers,
        createdAt = time(),
        settings = {
            public = true,
            allowInvites = true,
            requireApproval = false
        }
    }
    
    -- Add creator as leader
    group.members[userId] = {
        role = "LEADER",
        joinedAt = time(),
        permissions = {
            "INVITE_MEMBERS",
            "KICK_MEMBERS",
            "MANAGE_GROUP",
            "CHANGE_SETTINGS"
        }
    }
    
    self.socialGroups[groupId] = group
    
    -- Notify group creation
    self:NotifySocialGroupCreated(creator, group)
    
    print("SocialSystem: " .. creator.Name .. " created social group: " .. groupName)
    
    return groupId
end

function SocialSystem:JoinSocialGroup(player, groupId)
    local userId = player.UserId
    local group = self.socialGroups[groupId]
    
    if not group then
        return false, "Group not found"
    end
    
    -- Check if player is already in a group
    for existingGroupId, existingGroup in pairs(self.socialGroups) do
        if existingGroup.members[userId] then
            return false, "Player is already in a social group"
        end
    end
    
    -- Check if group is full
    if self:GetGroupMemberCount(groupId) >= group.maxMembers then
        return false, "Group is full"
    end
    
    -- Check if group requires approval
    if group.settings.requireApproval then
        -- Add to pending members
        if not group.pendingMembers then
            group.pendingMembers = {}
        end
        
        table.insert(group.pendingMembers, {
            userId = userId,
            name = player.Name,
            requestedAt = time()
        })
        
        print("SocialSystem: " .. player.Name .. " requested to join group: " .. group.name)
        return false, "Request sent, waiting for approval"
    end
    
    -- Add to group
    group.members[userId] = {
        role = "MEMBER",
        joinedAt = time(),
        permissions = {}
    }
    
    -- Notify group join
    self:NotifySocialGroupJoined(player, group)
    
    print("SocialSystem: " .. player.Name .. " joined group: " .. group.name)
    
    return true
end

function SocialSystem:LeaveSocialGroup(player, groupId)
    local userId = player.UserId
    local group = self.socialGroups[groupId]
    
    if not group then
        return false, "Group not found"
    end
    
    if not group.members[userId] then
        return false, "Player is not in this group"
    end
    
    -- Remove from group
    group.members[userId] = nil
    
    -- If group is empty, disband it
    if self:GetGroupMemberCount(groupId) == 0 then
        self.socialGroups[groupId] = nil
        print("SocialSystem: Group " .. group.name .. " disbanded (no members left)")
    else
        -- Notify group leave
        self:NotifySocialGroupLeft(player, group)
        print("SocialSystem: " .. player.Name .. " left group: " .. group.name)
    end
    
    return true
end

function SocialSystem:InviteToSocialGroup(inviter, targetPlayer, groupId)
    local inviterId = inviter.UserId
    local targetId = targetPlayer.UserId
    local group = self.socialGroups[groupId]
    
    if not group then
        return false, "Group not found"
    end
    
    if not group.members[inviterId] then
        return false, "Inviter is not in this group"
    end
    
    if not group.settings.allowInvites then
        return false, "Group does not allow invites"
    end
    
    if group.members[targetId] then
        return false, "Player is already in this group"
    end
    
    -- Check if group is full
    if self:GetGroupMemberCount(groupId) >= group.maxMembers then
        return false, "Group is full"
    end
    
    -- Create invitation
    local invitationId = HttpService:GenerateGUID()
    local invitation = {
        id = invitationId,
        groupId = groupId,
        groupName = group.name,
        inviter = inviterId,
        inviterName = inviter.Name,
        target = targetId,
        targetName = targetPlayer.Name,
        timestamp = time(),
        expiresAt = time() + (24 * 60 * 60) -- 24 hours
    }
    
    -- Add to group invitations
    if not group.invitations then
        group.invitations = {}
    end
    
    group.invitations[invitationId] = invitation
    
    -- Notify target player
    self:NotifyGroupInvitation(targetPlayer, invitation)
    
    print("SocialSystem: " .. inviter.Name .. " invited " .. targetPlayer.Name .. " to group: " .. group.name)
    
    return invitationId
end

-- Voice chat system (placeholder for future implementation)
function SocialSystem:JoinVoiceChat(player, channelId)
    local userId = player.UserId
    
    if not self.voiceChat[channelId] then
        self.voiceChat[channelId] = {
            participants = {},
            settings = {
                maxParticipants = 10,
                voiceEnabled = true,
                muteEnabled = true
            }
        }
    end
    
    local channel = self.voiceChat[channelId]
    
    if #channel.participants >= channel.settings.maxParticipants then
        return false, "Voice chat channel is full"
    end
    
    -- Add participant
    channel.participants[userId] = {
        player = player,
        joinedAt = time(),
        muted = false,
        speaking = false
    }
    
    -- Notify voice chat update
    self:NotifyVoiceChatUpdate(channelId, "JOINED", player)
    
    print("SocialSystem: " .. player.Name .. " joined voice chat: " .. channelId)
    
    return true
end

function SocialSystem:LeaveVoiceChat(player, channelId)
    local userId = player.UserId
    local channel = self.voiceChat[channelId]
    
    if not channel or not channel.participants[userId] then
        return false, "Not in voice chat channel"
    end
    
    -- Remove participant
    channel.participants[userId] = nil
    
    -- Notify voice chat update
    self:NotifyVoiceChatUpdate(channelId, "LEFT", player)
    
    print("SocialSystem: " .. player.Name .. " left voice chat: " .. channelId)
    
    return true
end

-- Emote system
function SocialSystem:UseEmote(player, emoteId)
    local userId = player.UserId
    
    -- Check if player has access to this emote
    if not self:PlayerHasEmote(player, emoteId) then
        return false, "Player does not have access to this emote"
    end
    
    -- Get emote data
    local emote = self.emoteSystem[emoteId]
    if not emote then
        return false, "Emote not found"
    end
    
    -- Use emote
    local emoteUsage = {
        player = userId,
        playerName = player.Name,
        emoteId = emoteId,
        emoteName = emote.name,
        timestamp = time()
    }
    
    -- Notify emote usage
    self:NotifyEmoteUsed(player, emoteUsage)
    
    print("SocialSystem: " .. player.Name .. " used emote: " .. emote.name)
    
    return true
end

-- Utility functions
function SocialSystem:ArePlayersFriends(userId1, userId2)
    local player1Data = self.friends[userId1]
    local player2Data = self.friends[userId2]
    
    if not player1Data or not player2Data then
        return false
    end
    
    -- Check if they're in each other's friends list
    for _, friend in ipairs(player1Data.friends) do
        if friend.userId == userId2 then
            return true
        end
    end
    
    return false
end

function SocialSystem:HasFriendRequest(senderId, receiverId)
    local receiverData = self.friends[receiverId]
    if not receiverData then
        return false
    end
    
    for _, request in ipairs(receiverData.pendingRequests) do
        if request.sender == senderId then
            return true
        end
    end
    
    return false
end

function SocialSystem:IsPlayerBlocked(userId1, userId2)
    local player1Data = self.friends[userId1]
    if not player1Data then
        return false
    end
    
    for _, blocked in ipairs(player1Data.blockedPlayers) do
        if blocked.userId == userId2 then
            return true
        end
    end
    
    return false
end

function SocialSystem:GetGroupMemberCount(groupId)
    local group = self.socialGroups[groupId]
    if not group then
        return 0
    end
    
    local count = 0
    for _ in pairs(group.members) do
        count = count + 1
    end
    
    return count
end

function SocialSystem:PlayerHasEmote(player, emoteId)
    -- This would integrate with the player's emote collection
    -- For now, return true for basic emotes
    local basicEmotes = { "WAVE", "DANCE", "LAUGH", "CLAP" }
    for _, emote in ipairs(basicEmotes) do
        if emoteId == emote then
            return true
        end
    end
    
    return false
end

function SocialSystem:FilterMessage(message)
    -- Basic content filtering (would integrate with TextService for more advanced filtering)
    local filtered = message
    
    -- Remove excessive caps
    if string.len(message) > 10 and string.upper(message) == message then
        filtered = string.lower(message)
    end
    
    -- Remove excessive punctuation
    filtered = string.gsub(filtered, "!+", "!")
    filtered = string.gsub(filtered, "%?+", "?")
    filtered = string.gsub(filtered, "%.+", ".")
    
    return filtered
end

-- Initialize chat channels
function SocialSystem:InitializeChatChannels()
    for channelType, _ in pairs(CHAT_CHANNELS) do
        self.chatChannels[channelType] = {
            messages = {},
            lastMessage = 0,
            settings = {
                enabled = true,
                moderated = false,
                cooldown = self.chatCooldown
            }
        }
    end
end

-- Initialize emote system
function SocialSystem:InitializeEmoteSystem()
    self.emoteSystem = {
        WAVE = { name = "Wave", description = "Wave hello", category = "Greeting" },
        DANCE = { name = "Dance", description = "Dance celebration", category = "Celebration" },
        LAUGH = { name = "Laugh", description = "Laugh out loud", category = "Emotion" },
        CLAP = { name = "Clap", description = "Applaud", category = "Celebration" },
        THUMBS_UP = { name = "Thumbs Up", description = "Show approval", category = "Gesture" },
        THUMBS_DOWN = { name = "Thumbs Down", description = "Show disapproval", category = "Gesture" }
    }
end

-- Initialize anime social systems
function SocialSystem:InitializeAnimeSocialSystems()
    self:InitializeAnimeFandoms()
    self:InitializeAnimeEvents()
    self:InitializeAnimeAchievements()
    self:InitializeAnimeDiscussions()
    self:InitializeAnimeCollaborations()
    self:InitializeAnimeFanArt()
    self:InitializeAnimeTheories()
    self:InitializeAnimeSocialMetrics()
end

-- Initialize anime fandoms
function SocialSystem:InitializeAnimeFandoms()
    for animeType, _ in pairs(ANIME_FANDOM_TYPES) do
        self.animeFandoms[animeType] = {
            members = {},
            discussions = {},
            events = {},
            fanArt = {},
            theories = {},
            collaborations = {},
            leaderboard = {},
            settings = {
                public = true,
                allowInvites = true,
                requireApproval = false,
                maxMembers = 1000,
                discussionEnabled = true,
                eventCreationEnabled = true,
                fanArtSharingEnabled = true,
                theoryCraftingEnabled = true
            },
            stats = {
                totalMembers = 0,
                activeDiscussions = 0,
                totalEvents = 0,
                totalFanArt = 0,
                totalTheories = 0,
                totalCollaborations = 0
            }
        }
    end
end

-- Initialize anime events
function SocialSystem:InitializeAnimeEvents()
    self.animeEvents = {}
    self.animeEventParticipants = {}
end

-- Initialize anime achievements
function SocialSystem:InitializeAnimeAchievements()
    self.animeAchievements = {}
end

-- Initialize anime discussions
function SocialSystem:InitializeAnimeDiscussions()
    self.animeDiscussions = {}
end

-- Initialize anime collaborations
function SocialSystem:InitializeAnimeCollaborations()
    self.animeCollaborations = {}
end

-- Initialize anime fan art
function SocialSystem:InitializeAnimeFanArt()
    self.animeFanArt = {}
end

-- Initialize anime theories
function SocialSystem:InitializeAnimeTheories()
    self.animeTheories = {}
end

-- Initialize anime social metrics
function SocialSystem:InitializeAnimeSocialMetrics()
    for animeType, _ in pairs(ANIME_FANDOM_TYPES) do
        self.animeSocialMetrics[animeType] = {
            totalMembers = 0,
            activeDiscussions = 0,
            totalEvents = 0,
            totalFanArt = 0,
            totalTheories = 0,
            totalCollaborations = 0,
            chatActivity = 0,
            eventParticipation = 0,
            fanArtEngagement = 0,
            theoryEngagement = 0,
            collaborationSuccess = 0
        }
    end
end

-- Anime fandom management functions
function SocialSystem:JoinAnimeFandom(player, animeType)
    if not player or not animeType or not ANIME_FANDOM_TYPES[animeType] then
        return false, "Invalid player or anime type"
    end
    
    local userId = player.UserId
    local fandom = self.animeFandoms[animeType]
    
    if not fandom then
        return false, "Anime fandom not found"
    end
    
    -- Check if player is already in this fandom
    if fandom.members[userId] then
        return false, "Player is already in this anime fandom"
    end
    
    -- Check player's fandom limit
    local playerFandoms = self.animeFandomMembers[userId] or {}
    if #playerFandoms >= self.maxAnimeFandoms then
        return false, "Player has reached maximum anime fandom limit"
    end
    
    -- Check fandom member limit
    if fandom.stats.totalMembers >= fandom.settings.maxMembers then
        return false, "Anime fandom is full"
    end
    
    -- Add player to fandom
    fandom.members[userId] = {
        playerName = player.Name,
        joinedAt = time(),
        role = "MEMBER",
        contributions = {
            discussions = 0,
            events = 0,
            fanArt = 0,
            theories = 0,
            collaborations = 0
        },
        lastActivity = time()
    }
    
    -- Update fandom stats
    fandom.stats.totalMembers = fandom.stats.totalMembers + 1
    
    -- Add to player's fandom list
    if not self.animeFandomMembers[userId] then
        self.animeFandomMembers[userId] = {}
    end
    table.insert(self.animeFandomMembers[userId], {
        animeType = animeType,
        joinedAt = time(),
        role = "MEMBER"
    })
    
    -- Update social metrics
    self.animeSocialMetrics[animeType].totalMembers = fandom.stats.totalMembers
    
    -- Notify fandom join
    self:NotifyAnimeFandomJoined(player, animeType)
    
    print("SocialSystem: " .. player.Name .. " joined anime fandom: " .. animeType)
    return true
end

function SocialSystem:LeaveAnimeFandom(player, animeType)
    if not player or not animeType or not ANIME_FANDOM_TYPES[animeType] then
        return false, "Invalid player or anime type"
    end
    
    local userId = player.UserId
    local fandom = self.animeFandoms[animeType]
    
    if not fandom or not fandom.members[userId] then
        return false, "Player is not in this anime fandom"
    end
    
    -- Remove player from fandom
    fandom.members[userId] = nil
    fandom.stats.totalMembers = fandom.stats.totalMembers - 1
    
    -- Remove from player's fandom list
    if self.animeFandomMembers[userId] then
        for i, fandomData in ipairs(self.animeFandomMembers[userId]) do
            if fandomData.animeType == animeType then
                table.remove(self.animeFandomMembers[userId], i)
                break
            end
        end
    end
    
    -- Update social metrics
    self.animeSocialMetrics[animeType].totalMembers = fandom.stats.totalMembers
    
    -- Notify fandom leave
    self:NotifyAnimeFandomLeft(player, animeType)
    
    print("SocialSystem: " .. player.Name .. " left anime fandom: " .. animeType)
    return true
end

function SocialSystem:InviteToAnimeFandom(inviter, targetPlayer, animeType)
    if not inviter or not targetPlayer or not animeType or not ANIME_FANDOM_TYPES[animeType] then
        return false, "Invalid players or anime type"
    end
    
    local inviterId = inviter.UserId
    local targetId = targetPlayer.UserId
    local fandom = self.animeFandoms[animeType]
    
    if not fandom then
        return false, "Anime fandom not found"
    end
    
    -- Check if inviter is in the fandom
    if not fandom.members[inviterId] then
        return false, "Inviter is not in this anime fandom"
    end
    
    -- Check if target is already in the fandom
    if fandom.members[targetId] then
        return false, "Target player is already in this anime fandom"
    end
    
    -- Check if fandom allows invites
    if not fandom.settings.allowInvites then
        return false, "This anime fandom does not allow invites"
    end
    
    -- Create invitation
    local invitationId = HttpService:GenerateGUID()
    local invitation = {
        id = invitationId,
        animeType = animeType,
        inviter = inviterId,
        inviterName = inviter.Name,
        target = targetId,
        targetName = targetPlayer.Name,
        timestamp = time(),
        expiresAt = time() + (24 * 60 * 60) -- 24 hours
    }
    
    -- Add to fandom invitations
    if not fandom.invitations then
        fandom.invitations = {}
    end
    fandom.invitations[invitationId] = invitation
    
    -- Notify target player
    self:NotifyAnimeFandomInvitation(targetPlayer, invitation)
    
    print("SocialSystem: " .. inviter.Name .. " invited " .. targetPlayer.Name .. " to anime fandom: " .. animeType)
    return invitationId
end

-- Anime event management functions
function SocialSystem:CreateAnimeEvent(creator, animeType, eventType, eventName, description, startTime, endTime)
    if not creator or not animeType or not eventType or not eventName or not startTime or not endTime then
        return false, "Invalid event parameters"
    end
    
    if not ANIME_FANDOM_TYPES[animeType] or not ANIME_EVENT_TYPES[eventType] then
        return false, "Invalid anime type or event type"
    end
    
    local userId = creator.UserId
    local fandom = self.animeFandoms[animeType]
    
    if not fandom or not fandom.members[userId] then
        return false, "Creator must be a member of the anime fandom"
    end
    
    -- Check if fandom allows event creation
    if not fandom.settings.eventCreationEnabled then
        return false, "This anime fandom does not allow event creation"
    end
    
    -- Create event
    local eventId = HttpService:GenerateGUID()
    local event = {
        id = eventId,
        animeType = animeType,
        eventType = eventType,
        name = eventName,
        description = description or "",
        creator = userId,
        creatorName = creator.Name,
        startTime = startTime,
        endTime = endTime,
        participants = {},
        maxParticipants = 100,
        status = "UPCOMING",
        createdAt = time(),
        settings = {
            public = true,
            allowInvites = true,
            requireApproval = false,
            maxParticipants = 100
        }
    }
    
    -- Add creator as participant
    event.participants[userId] = {
        playerName = creator.Name,
        joinedAt = time(),
        role = "ORGANIZER"
    }
    
    -- Add to fandom events
    if not fandom.events then
        fandom.events = {}
    end
    fandom.events[eventId] = event
    
    -- Add to global events
    self.animeEvents[eventId] = event
    
    -- Update fandom stats
    fandom.stats.totalEvents = fandom.stats.totalEvents + 1
    
    -- Update social metrics
    self.animeSocialMetrics[animeType].totalEvents = fandom.stats.totalEvents
    
    print("SocialSystem: " .. creator.Name .. " created anime event: " .. eventName .. " for " .. animeType)
    return eventId
end

function SocialSystem:JoinAnimeEvent(player, eventId)
    if not player or not eventId then
        return false, "Invalid player or event"
    end
    
    local userId = player.UserId
    local event = self.animeEvents[eventId]
    
    if not event then
        return false, "Event not found"
    end
    
    -- Check if player is already participating
    if event.participants[userId] then
        return false, "Player is already participating in this event"
    end
    
    -- Check if event is full
    if self:GetEventParticipantCount(eventId) >= event.maxParticipants then
        return false, "Event is full"
    end
    
    -- Check if player is in the anime fandom
    local fandom = self.animeFandoms[event.animeType]
    if not fandom or not fandom.members[userId] then
        return false, "Player must be a member of the anime fandom to join events"
    end
    
    -- Add player to event
    event.participants[userId] = {
        playerName = player.Name,
        joinedAt = time(),
        role = "PARTICIPANT"
    }
    
    -- Update player's event list
    if not self.animeEventParticipants[userId] then
        self.animeEventParticipants[userId] = {}
    end
    table.insert(self.animeEventParticipants[userId], {
        eventId = eventId,
        eventName = event.name,
        animeType = event.animeType,
        joinedAt = time()
    })
    
    -- Notify event join
    self:NotifyAnimeEventJoined(player, event)
    
    print("SocialSystem: " .. player.Name .. " joined anime event: " .. event.name)
    return true
end

function SocialSystem:LeaveAnimeEvent(player, eventId)
    if not player or not eventId then
        return false, "Invalid player or event"
    end
    
    local userId = player.UserId
    local event = self.animeEvents[eventId]
    
    if not event or not event.participants[userId] then
        return false, "Player is not participating in this event"
    end
    
    -- Remove player from event
    event.participants[userId] = nil
    
    -- Remove from player's event list
    if self.animeEventParticipants[userId] then
        for i, eventData in ipairs(self.animeEventParticipants[userId]) do
            if eventData.eventId == eventId then
                table.remove(self.animeEventParticipants[userId], i)
                break
            end
        end
    end
    
    -- Notify event leave
    self:NotifyAnimeEventLeft(player, event)
    
    print("SocialSystem: " .. player.Name .. " left anime event: " .. event.name)
    return true
end

-- Anime discussion functions
function SocialSystem:CreateAnimeDiscussion(player, animeType, title, content, discussionType)
    if not player or not animeType or not title or not content then
        return false, "Invalid discussion parameters"
    end
    
    if not ANIME_FANDOM_TYPES[animeType] then
        return false, "Invalid anime type"
    end
    
    local userId = player.UserId
    local fandom = self.animeFandoms[animeType]
    
    if not fandom or not fandom.members[userId] then
        return false, "Player must be a member of the anime fandom to create discussions"
    end
    
    -- Check if fandom allows discussions
    if not fandom.settings.discussionEnabled then
        return false, "This anime fandom does not allow discussions"
    end
    
    -- Check discussion limit
    if #fandom.discussions >= self.maxAnimeDiscussions then
        return false, "Anime fandom has reached maximum discussion limit"
    end
    
    -- Create discussion
    local discussionId = HttpService:GenerateGUID()
    local discussion = {
        id = discussionId,
        animeType = animeType,
        title = title,
        content = content,
        discussionType = discussionType or "GENERAL",
        creator = userId,
        creatorName = player.Name,
        createdAt = time(),
        replies = {},
        likes = 0,
        views = 0,
        status = "ACTIVE"
    }
    
    -- Add to fandom discussions
    table.insert(fandom.discussions, discussion)
    
    -- Add to global discussions
    self.animeDiscussions[discussionId] = discussion
    
    -- Update fandom stats
    fandom.stats.activeDiscussions = fandom.stats.activeDiscussions + 1
    
    -- Update social metrics
    self.animeSocialMetrics[animeType].activeDiscussions = fandom.stats.activeDiscussions
    
    -- Notify discussion creation
    self:NotifyAnimeDiscussionCreated(player, discussion)
    
    print("SocialSystem: " .. player.Name .. " created anime discussion: " .. title .. " for " .. animeType)
    return discussionId
end

-- Anime achievement functions
function SocialSystem:UnlockAnimeAchievement(player, achievementCategory, achievementName, description)
    if not player or not achievementCategory or not achievementName then
        return false, "Invalid achievement parameters"
    end
    
    if not ANIME_ACHIEVEMENT_CATEGORIES[achievementCategory] then
        return false, "Invalid achievement category"
    end
    
    local userId = player.UserId
    
    -- Check if player already has this achievement
    if not self.animeAchievements[userId] then
        self.animeAchievements[userId] = {}
    end
    
    for _, achievement in ipairs(self.animeAchievements[userId]) do
        if achievement.category == achievementCategory and achievement.name == achievementName then
            return false, "Player already has this achievement"
        end
    end
    
    -- Create achievement
    local achievement = {
        id = HttpService:GenerateGUID(),
        category = achievementCategory,
        name = achievementName,
        description = description or "",
        unlockedAt = time(),
        playerName = player.Name
    }
    
    -- Add to player's achievements
    table.insert(self.animeAchievements[userId], achievement)
    
    -- Notify achievement unlock
    self:NotifyAnimeAchievementUnlocked(player, achievement)
    
    print("SocialSystem: " .. player.Name .. " unlocked anime achievement: " .. achievementName)
    return true
end

-- Anime collaboration functions
function SocialSystem:StartAnimeCollaboration(initiator, animeType, collaborationType, title, description, maxParticipants)
    if not initiator or not animeType or not collaborationType or not title then
        return false, "Invalid collaboration parameters"
    end
    
    if not ANIME_FANDOM_TYPES[animeType] then
        return false, "Invalid anime type"
    end
    
    local userId = initiator.UserId
    local fandom = self.animeFandoms[animeType]
    
    if not fandom or not fandom.members[userId] then
        return false, "Initiator must be a member of the anime fandom"
    end
    
    -- Create collaboration
    local collaborationId = HttpService:GenerateGUID()
    local collaboration = {
        id = collaborationId,
        animeType = animeType,
        collaborationType = collaborationType,
        title = title,
        description = description or "",
        initiator = userId,
        initiatorName = initiator.Name,
        participants = {},
        maxParticipants = maxParticipants or 10,
        status = "ACTIVE",
        createdAt = time(),
        progress = 0,
        completionDate = nil
    }
    
    -- Add initiator as participant
    collaboration.participants[userId] = {
        playerName = initiator.Name,
        joinedAt = time(),
        role = "LEADER",
        contributions = 0
    }
    
    -- Add to fandom collaborations
    if not fandom.collaborations then
        fandom.collaborations = {}
    end
    fandom.collaborations[collaborationId] = collaboration
    
    -- Add to global collaborations
    self.animeCollaborations[collaborationId] = collaboration
    
    -- Update fandom stats
    fandom.stats.totalCollaborations = fandom.stats.totalCollaborations + 1
    
    -- Update social metrics
    self.animeSocialMetrics[animeType].totalCollaborations = fandom.stats.totalCollaborations
    
    -- Notify collaboration start
    self:NotifyAnimeCollaborationStarted(initiator, collaboration)
    
    print("SocialSystem: " .. initiator.Name .. " started anime collaboration: " .. title .. " for " .. animeType)
    return collaborationId
end

-- Anime fan art functions
function SocialSystem:ShareAnimeFanArt(player, animeType, title, description, artType, artData)
    if not player or not animeType or not title then
        return false, "Invalid fan art parameters"
    end
    
    if not ANIME_FANDOM_TYPES[animeType] then
        return false, "Invalid anime type"
    end
    
    local userId = player.UserId
    local fandom = self.animeFandoms[animeType]
    
    if not fandom or not fandom.members[userId] then
        return false, "Player must be a member of the anime fandom to share fan art"
    end
    
    -- Check if fandom allows fan art sharing
    if not fandom.settings.fanArtSharingEnabled then
        return false, "This anime fandom does not allow fan art sharing"
    end
    
    -- Check fan art limit
    if #fandom.fanArt >= self.maxAnimeFanArt then
        return false, "Anime fandom has reached maximum fan art limit"
    end
    
    -- Create fan art entry
    local fanArtId = HttpService:GenerateGUID()
    local fanArt = {
        id = fanArtId,
        animeType = animeType,
        title = title,
        description = description or "",
        artType = artType or "DIGITAL",
        artData = artData or "",
        creator = userId,
        creatorName = player.Name,
        createdAt = time(),
        likes = 0,
        views = 0,
        comments = {},
        status = "ACTIVE"
    }
    
    -- Add to fandom fan art
    table.insert(fandom.fanArt, fanArt)
    
    -- Add to global fan art
    self.animeFanArt[fanArtId] = fanArt
    
    -- Update fandom stats
    fandom.stats.totalFanArt = fandom.stats.totalFanArt + 1
    
    -- Update social metrics
    self.animeSocialMetrics[animeType].totalFanArt = fandom.stats.totalFanArt
    
    -- Notify fan art sharing
    self:NotifyAnimeFanArtShared(player, fanArt)
    
    print("SocialSystem: " .. player.Name .. " shared anime fan art: " .. title .. " for " .. animeType)
    return fanArtId
end

-- Anime theory functions
function SocialSystem:CreateAnimeTheory(player, animeType, title, content, theoryType, evidence)
    if not player or not animeType or not title or not content then
        return false, "Invalid theory parameters"
    end
    
    if not ANIME_FANDOM_TYPES[animeType] then
        return false, "Invalid anime type"
    end
    
    local userId = player.UserId
    local fandom = self.animeFandoms[animeType]
    
    if not fandom or not fandom.members[userId] then
        return false, "Player must be a member of the anime fandom to create theories"
    end
    
    -- Check if fandom allows theory crafting
    if not fandom.settings.theoryCraftingEnabled then
        return false, "This anime fandom does not allow theory crafting"
    end
    
    -- Check theory limit
    if #fandom.theories >= self.maxAnimeTheories then
        return false, "Anime fandom has reached maximum theory limit"
    end
    
    -- Create theory
    local theoryId = HttpService:GenerateGUID()
    local theory = {
        id = theoryId,
        animeType = animeType,
        title = title,
        content = content,
        theoryType = theoryType or "GENERAL",
        evidence = evidence or "",
        creator = userId,
        creatorName = player.Name,
        createdAt = time(),
        likes = 0,
        views = 0,
        comments = {},
        status = "ACTIVE",
        verified = false
    }
    
    -- Add to fandom theories
    table.insert(fandom.theories, theory)
    
    -- Add to global theories
    self.animeTheories[theoryId] = theory
    
    -- Update fandom stats
    fandom.stats.totalTheories = fandom.stats.totalTheories + 1
    
    -- Update social metrics
    self.animeSocialMetrics[animeType].totalTheories = fandom.stats.totalTheories
    
    print("SocialSystem: " .. player.Name .. " created anime theory: " .. title .. " for " .. animeType)
    return theoryId
end

-- Utility functions for anime social systems
function SocialSystem:GetEventParticipantCount(eventId)
    local event = self.animeEvents[eventId]
    if not event then
        return 0
    end
    
    local count = 0
    for _ in pairs(event.participants) do
        count = count + 1
    end
    
    return count
end

function SocialSystem:GetPlayerAnimeFandoms(player)
    local userId = player.UserId
    local fandoms = self.animeFandomMembers[userId] or {}
    
    local result = {}
    for _, fandomData in ipairs(fandoms) do
        local fandom = self.animeFandoms[fandomData.animeType]
        if fandom then
            table.insert(result, {
                animeType = fandomData.animeType,
                role = fandomData.role,
                joinedAt = fandomData.joinedAt,
                memberCount = fandom.stats.totalMembers,
                activeDiscussions = fandom.stats.activeDiscussions,
                totalEvents = fandom.stats.totalEvents
            })
        end
    end
    
    return result
end

function SocialSystem:GetPlayerAnimeEvents(player)
    local userId = player.UserId
    local events = self.animeEventParticipants[userId] or {}
    
    local result = {}
    for _, eventData in ipairs(events) do
        local event = self.animeEvents[eventData.eventId]
        if event then
            table.insert(result, {
                eventId = eventData.eventId,
                eventName = eventData.eventName,
                animeType = eventData.animeType,
                eventType = event.eventType,
                startTime = event.startTime,
                endTime = event.endTime,
                status = event.status,
                participantCount = self:GetEventParticipantCount(eventData.eventId),
                maxParticipants = event.maxParticipants
            })
        end
    end
    
    return result
end

function SocialSystem:GetAnimeFandomInfo(animeType)
    if not ANIME_FANDOM_TYPES[animeType] then
        return nil
    end
    
    local fandom = self.animeFandoms[animeType]
    if not fandom then
        return nil
    end
    
    return {
        animeType = animeType,
        totalMembers = fandom.stats.totalMembers,
        activeDiscussions = fandom.stats.activeDiscussions,
        totalEvents = fandom.stats.totalEvents,
        totalFanArt = fandom.stats.totalFanArt,
        totalTheories = fandom.stats.totalTheories,
        totalCollaborations = fandom.stats.totalCollaborations,
        settings = fandom.settings
    }
end

function SocialSystem:GetAnimeSocialMetrics(animeType)
    if not ANIME_FANDOM_TYPES[animeType] then
        return nil
    end
    
    return self.animeSocialMetrics[animeType]
end

function SocialSystem:GetAllAnimeSocialMetrics()
    return self.animeSocialMetrics
end

-- Periodic updates
function SocialSystem:SetupPeriodicUpdates()
    RunService.Heartbeat:Connect(function()
        local currentTime = time()
        
        -- Update chat channels
        if currentTime - self.lastChatUpdate >= self.chatUpdateInterval then
            self:UpdateChatChannels()
            self.lastChatUpdate = currentTime
        end
        
        -- Update anime social systems
        if currentTime - self.lastAnimeSocialUpdate >= self.animeSocialUpdateInterval then
            self:UpdateAnimeSocialSystems()
            self.lastAnimeSocialUpdate = currentTime
        end
        
        -- Clean up expired invitations
        self:CleanupExpiredInvitations()
        
        -- Update voice chat status
        self:UpdateVoiceChatStatus()
    end)
end

function SocialSystem:UpdateChatChannels()
    -- This would implement chat moderation and cleanup
    -- For now, just log the update
    print("SocialSystem: Updated chat channels")
end

function SocialSystem:UpdateAnimeSocialSystems()
    -- Update anime event statuses
    self:UpdateAnimeEventStatuses()
    
    -- Clean up expired anime fandom invitations
    self:CleanupExpiredAnimeFandomInvitations()
    
    -- Update anime social metrics
    self:UpdateAnimeSocialMetrics()
    
    -- Clean up inactive anime discussions
    self:CleanupInactiveAnimeDiscussions()
    
    print("SocialSystem: Updated anime social systems")
end

function SocialSystem:UpdateAnimeEventStatuses()
    local currentTime = time()
    
    for eventId, event in pairs(self.animeEvents) do
        if event.status == "UPCOMING" and currentTime >= event.startTime then
            event.status = "ACTIVE"
            print("SocialSystem: Anime event " .. event.name .. " is now active")
        elseif event.status == "ACTIVE" and currentTime >= event.endTime then
            event.status = "COMPLETED"
            print("SocialSystem: Anime event " .. event.name .. " has completed")
        end
    end
end

function SocialSystem:CleanupExpiredAnimeFandomInvitations()
    local currentTime = time()
    
    for animeType, fandom in pairs(self.animeFandoms) do
        if fandom.invitations then
            local expiredInvitations = {}
            
            for invitationId, invitation in pairs(fandom.invitations) do
                if invitation.expiresAt < currentTime then
                    table.insert(expiredInvitations, invitationId)
                end
            end
            
            for _, invitationId in ipairs(expiredInvitations) do
                fandom.invitations[invitationId] = nil
            end
        end
    end
end

function SocialSystem:UpdateAnimeSocialMetrics()
    -- Update engagement metrics based on recent activity
    for animeType, metrics in pairs(self.animeSocialMetrics) do
        local fandom = self.animeFandoms[animeType]
        if fandom then
            -- Update chat activity based on recent messages
            metrics.chatActivity = math.max(0, metrics.chatActivity - 1)
            
            -- Update event participation based on active events
            local activeEvents = 0
            if fandom.events then
                for _, event in pairs(fandom.events) do
                    if event.status == "ACTIVE" then
                        activeEvents = activeEvents + 1
                    end
                end
            end
            metrics.eventParticipation = activeEvents
            
            -- Update fan art engagement based on recent likes/views
            metrics.fanArtEngagement = math.max(0, metrics.fanArtEngagement - 0.5)
            
            -- Update theory engagement based on recent activity
            metrics.theoryEngagement = math.max(0, metrics.theoryEngagement - 0.5)
            
            -- Update collaboration success based on completed collaborations
            metrics.collaborationSuccess = math.max(0, metrics.collaborationSuccess - 0.2)
        end
    end
end

function SocialSystem:CleanupInactiveAnimeDiscussions()
    local currentTime = time()
    local inactiveThreshold = 30 * 24 * 60 * 60 -- 30 days
    
    for animeType, fandom in pairs(self.animeFandoms) do
        if fandom.discussions then
            local inactiveDiscussions = {}
            
            for i, discussion in ipairs(fandom.discussions) do
                if currentTime - discussion.createdAt > inactiveThreshold and discussion.replies and #discussion.replies == 0 then
                    table.insert(inactiveDiscussions, i)
                end
            end
            
            -- Remove inactive discussions (in reverse order to maintain indices)
            for i = #inactiveDiscussions, 1, -1 do
                local discussionIndex = inactiveDiscussions[i]
                local discussion = fandom.discussions[discussionIndex]
                
                -- Remove from global discussions
                self.animeDiscussions[discussion.id] = nil
                
                -- Remove from fandom discussions
                table.remove(fandom.discussions, discussionIndex)
                
                -- Update stats
                fandom.stats.activeDiscussions = math.max(0, fandom.stats.activeDiscussions - 1)
                self.animeSocialMetrics[animeType].activeDiscussions = fandom.stats.activeDiscussions
            end
        end
    end
end

function SocialSystem:CleanupExpiredInvitations()
    local currentTime = time()
    
    for groupId, group in pairs(self.socialGroups) do
        if group.invitations then
            local expiredInvitations = {}
            
            for invitationId, invitation in pairs(group.invitations) do
                if invitation.expiresAt < currentTime then
                    table.insert(expiredInvitations, invitationId)
                end
            end
            
            for _, invitationId in ipairs(expiredInvitations) do
                group.invitations[invitationId] = nil
            end
        end
    end
end

function SocialSystem:UpdateVoiceChatStatus()
    -- This would implement voice chat status updates
    -- For now, just log the update
    print("SocialSystem: Updated voice chat status")
end

-- Notification functions
function SocialSystem:NotifyFriendRequest(player, request)
    if player then
        self.networkManager:SendToClient(player, RemoteEvents.FriendRequest, {
            requestId = request.id,
            sender = request.senderName,
            timestamp = request.timestamp
        })
    end
end

function SocialSystem:NotifyFriendAdded(player, request)
    if player then
        self.networkManager:SendToClient(player, RemoteEvents.FriendAdded, {
            friendId = request.sender,
            friendName = request.senderName,
            timestamp = time()
        })
    end
end

function SocialSystem:NotifyFriendRemoved(player, removedPlayer)
    if player then
        self.networkManager:SendToClient(player, RemoteEvents.FriendRemoved, {
            friendId = removedPlayer.UserId,
            friendName = removedPlayer.Name,
            timestamp = time()
        })
    end
end

function SocialSystem:NotifyFriendsOnline(player)
    local userId = player.UserId
    local playerData = self.friends[userId]
    
    if not playerData then
        return
    end
    
    for _, friend in ipairs(playerData.friends) do
        local friendPlayer = Players:GetPlayerByUserId(friend.userId)
        if friendPlayer then
            self.networkManager:SendToClient(friendPlayer, RemoteEvents.FriendOnline, {
                friendId = userId,
                friendName = player.Name,
                timestamp = time()
            })
        end
    end
end

function SocialSystem:NotifyFriendsOffline(player)
    local userId = player.UserId
    local playerData = self.friends[userId]
    
    if not playerData then
        return
    end
    
    for _, friend in ipairs(playerData.friends) do
        local friendPlayer = Players:GetPlayerByUserId(friend.userId)
        if friendPlayer then
            self.networkManager:SendToClient(friendPlayer, RemoteEvents.FriendOffline, {
                friendId = userId,
                friendName = player.Name,
                timestamp = time()
            })
        end
    end
end

function SocialSystem:BroadcastChatMessage(channelId, chatMessage)
    -- Broadcast to all players in the channel
    for _, player in pairs(Players:GetPlayers()) do
        self.networkManager:SendToClient(player, RemoteEvents.ChatMessage, {
            channelId = channelId,
            sender = chatMessage.senderName,
            message = chatMessage.message,
            timestamp = chatMessage.timestamp
        })
    end
end

function SocialSystem:NotifyPrivateMessage(receiver, message)
    if receiver then
        self.networkManager:SendToClient(receiver, RemoteEvents.PrivateMessage, {
            messageId = message.id,
            sender = message.senderName,
            message = message.message,
            timestamp = message.timestamp
        })
    end
end

function SocialSystem:NotifySocialGroupCreated(creator, group)
    if creator then
        self.networkManager:SendToClient(creator, RemoteEvents.SocialGroupCreated, {
            groupId = group.id,
            groupName = group.name,
            groupType = group.type,
            timestamp = time()
        })
    end
end

function SocialSystem:NotifySocialGroupJoined(player, group)
    if player then
        self.networkManager:SendToClient(player, RemoteEvents.SocialGroupJoined, {
            groupId = group.id,
            groupName = group.name,
            groupType = group.type,
            timestamp = time()
        })
    end
end

function SocialSystem:NotifySocialGroupLeft(player, group)
    if player then
        self.networkManager:SendToClient(player, RemoteEvents.SocialGroupLeft, {
            groupId = group.id,
            groupName = group.name,
            timestamp = time()
        })
    end
end

function SocialSystem:NotifyGroupInvitation(player, invitation)
    if player then
        self.networkManager:SendToClient(player, RemoteEvents.SocialGroupCreated, {
            invitationId = invitation.id,
            groupName = invitation.groupName,
            inviter = invitation.inviterName,
            timestamp = invitation.timestamp
        })
    end
end

function SocialSystem:NotifyVoiceChatUpdate(channelId, action, player)
    -- Notify all participants in the voice chat
    local channel = self.voiceChat[channelId]
    if not channel then
        return
    end
    
    for participantId, participant in pairs(channel.participants) do
        if participant.player ~= player then
            self.networkManager:SendToClient(participant.player, RemoteEvents.VoiceChatUpdate, {
                channelId = channelId,
                action = action,
                playerId = player.UserId,
                playerName = player.Name,
                timestamp = time()
            })
        end
    end
end

function SocialSystem:NotifyEmoteUsed(player, emoteUsage)
    -- Notify nearby players (could be expanded to show emote to all players)
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= player then
            self.networkManager:SendToClient(otherPlayer, RemoteEvents.EmoteUsed, {
                playerId = player.UserId,
                playerName = player.Name,
                emoteId = emoteUsage.emoteId,
                emoteName = emoteUsage.emoteName,
                timestamp = emoteUsage.timestamp
            })
        end
    end
end

-- Anime-specific notification functions
function SocialSystem:NotifyAnimeFandomJoined(player, animeType)
    if player then
        self.networkManager:SendToClient(player, RemoteEvents.AnimeFandomJoined, {
            animeType = animeType,
            timestamp = time()
        })
    end
end

function SocialSystem:NotifyAnimeFandomLeft(player, animeType)
    if player then
        self.networkManager:SendToClient(player, RemoteEvents.AnimeFandomLeft, {
            animeType = animeType,
            timestamp = time()
        })
    end
end

function SocialSystem:NotifyAnimeFandomInvitation(player, invitation)
    if player then
        self.networkManager:SendToClient(player, RemoteEvents.AnimeFandomInvitation, {
            invitationId = invitation.id,
            animeType = invitation.animeType,
            inviter = invitation.inviterName,
            timestamp = invitation.timestamp
        })
    end
end

function SocialSystem:NotifyAnimeEventJoined(player, event)
    if player then
        self.networkManager:SendToClient(player, RemoteEvents.AnimeEventJoined, {
            eventId = event.id,
            eventName = event.name,
            animeType = event.animeType,
            eventType = event.eventType,
            timestamp = time()
        })
    end
end

function SocialSystem:NotifyAnimeEventLeft(player, event)
    if player then
        self.networkManager:SendToClient(player, RemoteEvents.AnimeEventLeft, {
            eventId = event.id,
            eventName = event.name,
            animeType = event.animeType,
            timestamp = time()
        })
    end
end

function SocialSystem:NotifyAnimeAchievementUnlocked(player, achievement)
    if player then
        self.networkManager:SendToClient(player, RemoteEvents.AnimeAchievementUnlocked, {
            achievementId = achievement.id,
            category = achievement.category,
            name = achievement.name,
            description = achievement.description,
            timestamp = time()
        })
    end
end

function SocialSystem:NotifyAnimeCollaborationStarted(player, collaboration)
    if player then
        self.networkManager:SendToClient(player, RemoteEvents.AnimeCollaborationStarted, {
            collaborationId = collaboration.id,
            title = collaboration.title,
            animeType = collaboration.animeType,
            collaborationType = collaboration.collaborationType,
            timestamp = time()
        })
    end
end

function SocialSystem:NotifyAnimeFanArtShared(player, fanArt)
    if player then
        self.networkManager:SendToClient(player, RemoteEvents.AnimeFanArtShared, {
            fanArtId = fanArt.id,
            title = fanArt.title,
            animeType = fanArt.animeType,
            artType = fanArt.artType,
            timestamp = time()
        })
    end
end

function SocialSystem:NotifyAnimeDiscussionCreated(player, discussion)
    if player then
        self.networkManager:SendToClient(player, RemoteEvents.AnimeDiscussionCreated, {
            discussionId = discussion.id,
            title = discussion.title,
            animeType = discussion.animeType,
            discussionType = discussion.discussionType,
            timestamp = time()
        })
    end
end

-- Public API functions
function SocialSystem:GetPlayerFriends(player)
    local userId = player.UserId
    local playerData = self.friends[userId]
    
    if not playerData then
        return {}
    end
    
    local friends = {}
    for _, friend in ipairs(playerData.friends) do
        local friendPlayer = Players:GetPlayerByUserId(friend.userId)
        table.insert(friends, {
            userId = friend.userId,
            name = friend.name,
            online = friendPlayer ~= nil,
            lastSeen = friendPlayer and time() or (playerData.lastOnline or 0)
        })
    end
    
    return friends
end

function SocialSystem:GetPendingFriendRequests(player)
    local userId = player.UserId
    local playerData = self.friends[userId]
    
    if not playerData then
        return {}
    end
    
    return playerData.pendingRequests
end

function SocialSystem:GetPlayerSocialGroups(player)
    local userId = player.UserId
    local groups = {}
    
    for groupId, group in pairs(self.socialGroups) do
        if group.members[userId] then
            table.insert(groups, {
                id = groupId,
                name = group.name,
                type = group.type,
                memberCount = self:GetGroupMemberCount(groupId),
                maxMembers = group.maxMembers,
                role = group.members[userId].role
            })
        end
    end
    
    return groups
end

function SocialSystem:GetChatHistory(channelId, limit)
    local channel = self.chatChannels[channelId]
    if not channel then
        return {}
    end
    
    local messages = channel.messages
    if limit and #messages > limit then
        local startIndex = #messages - limit + 1
        local result = {}
        for i = startIndex, #messages do
            table.insert(result, messages[i])
        end
        return result
    end
    
    return messages
end

function SocialSystem:GetPrivateMessages(player)
    local userId = player.UserId
    local playerData = self.privateMessages[userId]
    
    if not playerData then
        return {}
    end
    
    return playerData.messages
end

-- Cleanup
function SocialSystem:Cleanup()
    print("SocialSystem: Starting cleanup...")
    
    -- Clean up remote events
    for _, remoteEvent in pairs(self.remoteEvents) do
        if remoteEvent and remoteEvent.Parent then
            remoteEvent:Destroy()
        end
    end
    
    -- Clean up social groups
    for groupId, group in pairs(self.socialGroups) do
        self.socialGroups[groupId] = nil
    end
    
    -- Clean up voice chat
    for channelId, channel in pairs(self.voiceChat) do
        self.voiceChat[channelId] = nil
    end
    
    print("SocialSystem: Cleanup completed!")
end

-- Get social system metrics
function SocialSystem:GetSocialMetrics()
    local metrics = {
        totalFriendships = 0,
        activeChatChannels = 0,
        socialGroups = 0,
        privateMessages = 0,
        friendRequests = 0,
        blockedPlayers = 0,
        voiceChatUsers = 0
    }
    
    -- Count friendships
    for userId, playerData in pairs(self.friends) do
        if playerData.friends then
            metrics.totalFriendships = metrics.totalFriendships + #playerData.friends
        end
        
        if playerData.pendingRequests then
            metrics.friendRequests = metrics.friendRequests + #playerData.pendingRequests
        end
        
        if playerData.blockedPlayers then
            metrics.blockedPlayers = metrics.blockedPlayers + #playerData.blockedPlayers
        end
    end
    
    -- Count active chat channels
    for channelId, channel in pairs(self.chatChannels) do
        if channel.active then
            metrics.activeChatChannels = metrics.activeChatChannels + 1
        end
    end
    
    -- Count social groups
    for groupId, group in pairs(self.socialGroups) do
        metrics.socialGroups = metrics.socialGroups + 1
    end
    
    -- Count private messages
    for userId, playerData in pairs(self.privateMessages) do
        if playerData.messages then
            metrics.privateMessages = metrics.privateMessages + #playerData.messages
        end
    end
    
    -- Count voice chat users
    for channelId, channel in pairs(self.voiceChat) do
        if channel.participants then
            metrics.voiceChatUsers = metrics.voiceChatUsers + #channel.participants
        end
    end
    
    return metrics
end

-- Anime social system public API functions
function SocialSystem:GetAnimeFandomTypes()
    return ANIME_FANDOM_TYPES
end

function SocialSystem:GetAnimeEventTypes()
    return ANIME_EVENT_TYPES
end

function SocialSystem:GetAnimeAchievementCategories()
    return ANIME_ACHIEVEMENT_CATEGORIES
end

function SocialSystem:GetAnimeFandomSettings(animeType)
    if not ANIME_FANDOM_TYPES[animeType] then
        return nil
    end
    
    local fandom = self.animeFandoms[animeType]
    if not fandom then
        return nil
    end
    
    return fandom.settings
end

function SocialSystem:GetAnimeFandomStats(animeType)
    if not ANIME_FANDOM_TYPES[animeType] then
        return nil
    end
    
    local fandom = self.animeFandoms[animeType]
    if not fandom then
        return nil
    end
    
    return fandom.stats
end

function SocialSystem:GetAnimeFandomMembers(animeType, limit)
    if not ANIME_FANDOM_TYPES[animeType] then
        return {}
    end
    
    local fandom = self.animeFandoms[animeType]
    if not fandom then
        return {}
    end
    
    local members = {}
    local count = 0
    
    for userId, memberData in pairs(fandom.members) do
        if not limit or count < limit then
            table.insert(members, {
                userId = userId,
                playerName = memberData.playerName,
                role = memberData.role,
                joinedAt = memberData.joinedAt,
                lastActivity = memberData.lastActivity,
                contributions = memberData.contributions
            })
            count = count + 1
        else
            break
        end
    end
    
    return members
end

function SocialSystem:GetAnimeFandomDiscussions(animeType, limit)
    if not ANIME_FANDOM_TYPES[animeType] then
        return {}
    end
    
    local fandom = self.animeFandoms[animeType]
    if not fandom or not fandom.discussions then
        return {}
    end
    
    local discussions = fandom.discussions
    if limit and #discussions > limit then
        local startIndex = #discussions - limit + 1
        local result = {}
        for i = startIndex, #discussions do
            table.insert(result, discussions[i])
        end
        return result
    end
    
    return discussions
end

function SocialSystem:GetAnimeFandomEvents(animeType, status)
    if not ANIME_FANDOM_TYPES[animeType] then
        return {}
    end
    
    local fandom = self.animeFandoms[animeType]
    if not fandom or not fandom.events then
        return {}
    end
    
    local events = {}
    for eventId, event in pairs(fandom.events) do
        if not status or event.status == status then
            table.insert(events, {
                id = eventId,
                name = event.name,
                eventType = event.eventType,
                description = event.description,
                startTime = event.startTime,
                endTime = event.endTime,
                status = event.status,
                participantCount = self:GetEventParticipantCount(eventId),
                maxParticipants = event.maxParticipants,
                creator = event.creatorName
            })
        end
    end
    
    return events
end

function SocialSystem:GetAnimeFandomFanArt(animeType, limit)
    if not ANIME_FANDOM_TYPES[animeType] then
        return {}
    end
    
    local fandom = self.animeFandoms[animeType]
    if not fandom or not fandom.fanArt then
        return {}
    end
    
    local fanArt = fandom.fanArt
    if limit and #fanArt > limit then
        local startIndex = #fanArt - limit + 1
        local result = {}
        for i = startIndex, #fanArt do
            table.insert(result, fanArt[i])
        end
        return result
    end
    
    return fanArt
end

function SocialSystem:GetAnimeFandomTheories(animeType, limit)
    if not ANIME_FANDOM_TYPES[animeType] then
        return {}
    end
    
    local fandom = self.animeFandoms[animeType]
    if not fandom or not fandom.theories then
        return {}
    end
    
    local theories = fandom.theories
    if limit and #theories > limit then
        local startIndex = #theories - limit + 1
        local result = {}
        for i = startIndex, #theories do
            table.insert(result, theories[i])
        end
        return result
    end
    
    return theories
end

function SocialSystem:GetAnimeFandomCollaborations(animeType, status)
    if not ANIME_FANDOM_TYPES[animeType] then
        return {}
    end
    
    local fandom = self.animeFandoms[animeType]
    if not fandom or not fandom.collaborations then
        return {}
    end
    
    local collaborations = {}
    for collaborationId, collaboration in pairs(fandom.collaborations) do
        if not status or collaboration.status == status then
            table.insert(collaborations, {
                id = collaborationId,
                title = collaboration.title,
                collaborationType = collaboration.collaborationType,
                description = collaboration.description,
                initiator = collaboration.initiatorName,
                participantCount = self:GetCollaborationParticipantCount(collaborationId),
                maxParticipants = collaboration.maxParticipants,
                status = collaboration.status,
                progress = collaboration.progress,
                createdAt = collaboration.createdAt
            })
        end
    end
    
    return collaborations
end

function SocialSystem:GetCollaborationParticipantCount(collaborationId)
    local collaboration = self.animeCollaborations[collaborationId]
    if not collaboration then
        return 0
    end
    
    local count = 0
    for _ in pairs(collaboration.participants) do
        count = count + 1
    end
    
    return count
end

function SocialSystem:GetPlayerAnimeAchievements(player)
    local userId = player.UserId
    return self.animeAchievements[userId] or {}
end

function SocialSystem:GetAnimeSocialSystemLimits()
    return {
        maxAnimeFandoms = self.maxAnimeFandoms,
        maxAnimeEvents = self.maxAnimeEvents,
        maxAnimeDiscussions = self.maxAnimeDiscussions,
        maxAnimeCollaborations = self.maxAnimeCollaborations,
        maxAnimeFanArt = self.maxAnimeFanArt,
        maxAnimeTheories = self.maxAnimeTheories
    }
end

return SocialSystem
