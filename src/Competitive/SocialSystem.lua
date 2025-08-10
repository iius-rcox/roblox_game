-- SocialSystem.lua
-- Advanced social system for Milestone 3: Competitive & Social Systems
-- Handles friends, chat, communication, and community features

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
    EmoteUsed = "EmoteUsed"
}

-- Chat channel types
local CHAT_CHANNELS = {
    GLOBAL = "GLOBAL",
    GUILD = "GUILD",
    TRADE = "TRADE",
    COMPETITIVE = "COMPETITIVE",
    LOCAL = "LOCAL"
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
    CREATIVE = "CREATIVE"
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
    
    -- Network manager reference
    self.networkManager = nil
    
    -- Initialize remote events
    self.remoteEvents = {}
    
    -- Social settings
    self.maxFriends = 100             -- Maximum friends per player
    self.maxPrivateMessages = 50      -- Maximum stored private messages
    self.chatCooldown = 1             -- Seconds between chat messages
    self.maxGroupMembers = 20         -- Maximum members per social group
    
    -- Performance tracking
    self.lastChatUpdate = 0
    self.chatUpdateInterval = 5       -- Update chat every 5 seconds
    
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
    
    -- Set up periodic updates
    self:SetupPeriodicUpdates()
    
    print("SocialSystem: Initialized successfully!")
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
            lastOnline = tick(),
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
        timestamp = tick(),
        status = FRIEND_STATUS.PENDING
    }
    
    -- Add to pending requests
    if not self.friends[receiverId] then
        self.friends[receiverId] = {
            friends = {},
            pendingRequests = {},
            blockedPlayers = {},
            lastOnline = tick(),
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
        addedAt = tick()
    })
    
    table.insert(senderData.friends, {
        userId = userId,
        name = player.Name,
        addedAt = tick()
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
        blockedAt = tick()
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
    if tick() - lastMessageTime < self.chatCooldown then
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
        timestamp = tick()
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
    
    self.chatChannels[channelId].lastMessage = tick()
    
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
        timestamp = tick(),
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
        createdAt = tick(),
        settings = {
            public = true,
            allowInvites = true,
            requireApproval = false
        }
    }
    
    -- Add creator as leader
    group.members[userId] = {
        role = "LEADER",
        joinedAt = tick(),
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
            requestedAt = tick()
        })
        
        print("SocialSystem: " .. player.Name .. " requested to join group: " .. group.name)
        return false, "Request sent, waiting for approval"
    end
    
    -- Add to group
    group.members[userId] = {
        role = "MEMBER",
        joinedAt = tick(),
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
        timestamp = tick(),
        expiresAt = tick() + (24 * 60 * 60) -- 24 hours
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
        joinedAt = tick(),
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
        timestamp = tick()
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

-- Periodic updates
function SocialSystem:SetupPeriodicUpdates()
    RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        
        -- Update chat channels
        if currentTime - self.lastChatUpdate >= self.chatUpdateInterval then
            self:UpdateChatChannels()
            self.lastChatUpdate = currentTime
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

function SocialSystem:CleanupExpiredInvitations()
    local currentTime = tick()
    
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
            timestamp = tick()
        })
    end
end

function SocialSystem:NotifyFriendRemoved(player, removedPlayer)
    if player then
        self.networkManager:SendToClient(player, RemoteEvents.FriendRemoved, {
            friendId = removedPlayer.UserId,
            friendName = removedPlayer.Name,
            timestamp = tick()
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
                timestamp = tick()
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
                timestamp = tick()
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
            timestamp = tick()
        })
    end
end

function SocialSystem:NotifySocialGroupJoined(player, group)
    if player then
        self.networkManager:SendToClient(player, RemoteEvents.SocialGroupJoined, {
            groupId = group.id,
            groupName = group.name,
            groupType = group.type,
            timestamp = tick()
        })
    end
end

function SocialSystem:NotifySocialGroupLeft(player, group)
    if player then
        self.networkManager:SendToClient(player, RemoteEvents.SocialGroupLeft, {
            groupId = group.id,
            groupName = group.name,
            timestamp = tick()
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
                timestamp = tick()
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
            lastSeen = friendPlayer and tick() or (playerData.lastOnline or 0)
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

return SocialSystem
