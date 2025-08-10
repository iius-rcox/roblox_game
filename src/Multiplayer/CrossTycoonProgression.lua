-- CrossTycoonProgression.lua
-- Handles cross-tycoon progression, shared abilities, and economy

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Constants = require(script.Parent.Parent.Utils.Constants)
local NetworkManager = require(script.Parent.NetworkManager)

local CrossTycoonProgression = {}
CrossTycoonProgression.__index = CrossTycoonProgression

-- RemoteEvents for client-server communication
local RemoteEvents = {
    SharedAbilityUpdate = "SharedAbilityUpdate",
    CrossTycoonProgressionSync = "CrossTycoonProgressionSync",
    AbilityTheftEvent = "AbilityTheftEvent",
    EconomyBonusUpdate = "EconomyBonusUpdate"
}

function CrossTycoonProgression.new()
    local self = setmetatable({}, CrossTycoonProgression)
    
    -- Core data structures
    self.sharedAbilities = {}         -- Player -> [Ability Data]
    self.abilityLevels = {}           -- Ability -> Level
    self.crossTycoonUpgrades = {}     -- Upgrade -> Cost
    self.theftProtection = {}         -- Anti-theft measures
    self.playerProgression = {}       -- Player -> Total Progression
    self.economyBonuses = {}          -- Player -> Economy Bonus Data
    
    -- Network manager reference
    self.networkManager = nil
    
    -- Initialize remote events
    self.remoteEvents = {}
    
    return self
end

function CrossTycoonProgression:Initialize(networkManager)
    self.networkManager = networkManager
    
    -- Set up remote events
    self:SetupRemoteEvents()
    
    -- Connect to player events
    self:ConnectPlayerEvents()
    
    -- Initialize ability system
    self:InitializeAbilitySystem()
    
    print("CrossTycoonProgression: Initialized successfully!")
end

function CrossTycoonProgression:SetupRemoteEvents()
    -- Create remote events in ReplicatedStorage
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    
    for eventName, _ in pairs(RemoteEvents) do
        local remoteEvent = Instance.new("RemoteEvent")
        remoteEvent.Name = eventName
        remoteEvent.Parent = ReplicatedStorage
        self.remoteEvents[eventName] = remoteEvent
    end
    
    -- Set up event handlers
    self.remoteEvents.SharedAbilityUpdate.OnServerEvent:Connect(function(player, abilityId, newLevel)
        self:HandleAbilityUpdateRequest(player, abilityId, newLevel)
    end)
    
    print("CrossTycoonProgression: Remote events configured!")
end

function CrossTycoonProgression:ConnectPlayerEvents()
    -- Handle player joining
    Players.PlayerAdded:Connect(function(player)
        self:HandlePlayerJoined(player)
    end)
    
    -- Handle player leaving
    Players.PlayerRemoving:Connect(function(player)
        self:HandlePlayerLeaving(player)
    end)
    
    print("CrossTycoonProgression: Player events connected!")
end

function CrossTycoonProgression:InitializeAbilitySystem()
    -- Initialize all abilities with base levels
    for abilityName, _ in pairs(Constants.ABILITIES) do
        self.abilityLevels[abilityName] = 1
        self.crossTycoonUpgrades[abilityName] = {
            baseCost = Constants.ECONOMY.ABILITY_BASE_COST,
            currentLevel = 1,
            maxLevel = Constants.ECONOMY.MAX_UPGRADE_LEVEL
        }
    end
    
    print("CrossTycoonProgression: Ability system initialized!")
end

-- Shared Ability System

function CrossTycoonProgression:UpdateSharedAbility(player, abilityId, newLevel)
    if not player or not abilityId or not newLevel then
        warn("UpdateSharedAbility: Invalid parameters")
        return false
    end
    
    local userId = player.UserId
    
    -- Initialize player abilities if needed
    if not self.sharedAbilities[userId] then
        self.sharedAbilities[userId] = {}
    end
    
    -- Update ability level
    self.sharedAbilities[userId][abilityId] = {
        level = newLevel,
        lastUpdated = tick(),
        tycoonSource = "cross_tycoon"
    }
    
    -- Update global ability levels
    if newLevel > (self.abilityLevels[abilityId] or 1) then
        self.abilityLevels[abilityId] = newLevel
    end
    
    -- Update player progression
    self:UpdatePlayerProgression(player)
    
    -- Sync to client
    self:SyncCrossTycoonProgression(player)
    
    -- Broadcast ability update
    self:BroadcastAbilityUpdate(player, abilityId, newLevel)
    
    print("CrossTycoonProgression: Updated " .. abilityId .. " to level " .. newLevel .. " for " .. player.Name)
    return true
end

function CrossTycoonProgression:GetSharedAbility(player, abilityId)
    if not player or not abilityId then return nil end
    
    local userId = player.UserId
    local playerAbilities = self.sharedAbilities[userId] or {}
    
    return playerAbilities[abilityId]
end

function CrossTycoonProgression:GetAllSharedAbilities(player)
    if not player then return {} end
    
    local userId = player.UserId
    return self.sharedAbilities[userId] or {}
end

function CrossTycoonProgression:GetAbilityLevel(abilityId)
    return self.abilityLevels[abilityId] or 1
end

function CrossTycoonProgression:GetAbilityUpgradeCost(abilityId, currentLevel)
    local upgradeData = self.crossTycoonUpgrades[abilityId]
    if not upgradeData then return 0 end
    
    local baseCost = upgradeData.baseCost
    local multiplier = Constants.ECONOMY.UPGRADE_COST_MULTIPLIER
    
    return math.floor(baseCost * (multiplier ^ (currentLevel - 1)))
end

-- Cross-Tycoon Progression Tracking

function CrossTycoonProgression:UpdatePlayerProgression(player)
    if not player then return end
    
    local userId = player.UserId
    local abilities = self.sharedAbilities[userId] or {}
    
    local totalLevel = 0
    local abilityCount = 0
    local maxLevel = 0
    
    for abilityId, abilityData in pairs(abilities) do
        totalLevel = totalLevel + abilityData.level
        abilityCount = abilityCount + 1
        maxLevel = math.max(maxLevel, abilityData.level)
    end
    
    self.playerProgression[userId] = {
        totalLevel = totalLevel,
        abilityCount = abilityCount,
        averageLevel = abilityCount > 0 and (totalLevel / abilityCount) or 0,
        maxLevel = maxLevel,
        lastUpdated = tick()
    }
    
    print("CrossTycoonProgression: Updated progression for " .. player.Name .. " (Total: " .. totalLevel .. ", Avg: " .. (self.playerProgression[userId].averageLevel) .. ")")
end

function CrossTycoonProgression:GetPlayerProgression(player)
    if not player then return nil end
    return self.playerProgression[player.UserId]
end

function CrossTycoonProgression:CalculateTotalProgression(player)
    local progression = self:GetPlayerProgression(player)
    if not progression then return 0 end
    
    -- Calculate weighted progression score
    local baseScore = progression.totalLevel
    local bonusScore = progression.abilityCount * 10  -- Bonus for variety
    local maxLevelBonus = progression.maxLevel * 5    -- Bonus for high-level abilities
    
    return baseScore + bonusScore + maxLevelBonus
end

-- Cross-Tycoon Economy System

function CrossTycoonProgression:CalculateCashBonus(player)
    -- This will be called by MultiTycoonManager
    -- Returns the cash multiplier for cross-tycoon bonuses
    return 1.0  -- Base multiplier, will be enhanced by MultiTycoonManager
end

function CrossTycoonProgression:CalculateAbilityCostReduction(player)
    -- This will be called by MultiTycoonManager
    -- Returns the ability cost reduction percentage
    return 0.0  -- Base reduction, will be enhanced by MultiTycoonManager
end

function CrossTycoonProgression:ProcessCrossTycoonPurchase(player, itemId, baseCost)
    if not player or not itemId or not baseCost then
        warn("ProcessCrossTycoonPurchase: Invalid parameters")
        return false, baseCost
    end
    
    local userId = player.UserId
    local progression = self:GetPlayerProgression(player)
    
    if not progression then
        return false, baseCost
    end
    
    -- Calculate progression-based discounts
    local progressionDiscount = math.min(progression.averageLevel * 0.01, 0.2)  -- Max 20% discount
    local finalCost = math.floor(baseCost * (1 - progressionDiscount))
    
    -- Update economy bonuses
    self.economyBonuses[userId] = {
        progressionDiscount = progressionDiscount,
        finalCost = finalCost,
        savings = baseCost - finalCost,
        lastUpdated = tick()
    }
    
    -- Send economy bonus update to client
    self:SendEconomyBonusUpdate(player)
    
    print("CrossTycoonProgression: Processed purchase for " .. player.Name .. " (Original: " .. baseCost .. ", Final: " .. finalCost .. ", Saved: " .. (baseCost - finalCost) .. ")")
    return true, finalCost
end

function CrossTycoonProgression:GetEconomyBonuses(player)
    if not player then return nil end
    return self.economyBonuses[player.UserId]
end

-- Ability Theft System

function CrossTycoonProgression:HandleAbilityTheft(stealer, target, abilityId)
    if not stealer or not target or not abilityId then
        warn("HandleAbilityTheft: Invalid parameters")
        return false
    end
    
    -- Check if target has the ability
    local targetAbility = self:GetSharedAbility(target, abilityId)
    if not targetAbility then
        warn("HandleAbilityTheft: Target " .. target.Name .. " doesn't have ability " .. abilityId)
        return false
    end
    
    -- Check theft protection
    if self:IsPlayerProtectedFromTheft(target) then
        warn("HandleAbilityTheft: Target " .. target.Name .. " is protected from theft")
        return false
    end
    
    -- Check stealer's current ability level
    local stealerAbility = self:GetSharedAbility(stealer, abilityId)
    local stealerLevel = stealerAbility and stealerAbility.level or 0
    
    -- Calculate theft result
    local theftLevel = math.min(targetAbility.level, stealerLevel + 1)
    local success = theftLevel > stealerLevel
    
    if success then
        -- Update stealer's ability
        self:UpdateSharedAbility(stealer, abilityId, theftLevel)
        
        -- Apply theft penalty to target (temporary level reduction)
        self:ApplyTheftPenalty(target, abilityId, targetAbility.level)
        
        -- Broadcast theft event
        self:BroadcastAbilityTheft(stealer, target, abilityId, theftLevel)
        
        print("CrossTycoonProgression: " .. stealer.Name .. " successfully stole " .. abilityId .. " level " .. theftLevel .. " from " .. target.Name)
    else
        print("CrossTycoonProgression: " .. stealer.Name .. " failed to steal " .. abilityId .. " from " .. target.Name)
    end
    
    return success
end

function CrossTycoonProgression:IsPlayerProtectedFromTheft(player)
    if not player then return false end
    
    local userId = player.UserId
    local protection = self.theftProtection[userId]
    
    if not protection then return false end
    
    -- Check if protection is still active
    return tick() < protection.expiresAt
end

function CrossTycoonProgression:ApplyTheftPenalty(player, abilityId, originalLevel)
    if not player or not abilityId or not originalLevel then return end
    
    local userId = player.UserId
    local penaltyLevel = math.max(1, originalLevel - 1)  -- Reduce by 1 level, minimum 1
    
    -- Update ability with penalty
    self:UpdateSharedAbility(player, abilityId, penaltyLevel)
    
    -- Set temporary theft protection
    self.theftProtection[userId] = {
        expiresAt = tick() + 300,  -- 5 minutes of protection
        stolenAbility = abilityId,
        originalLevel = originalLevel
    }
    
    print("CrossTycoonProgression: Applied theft penalty to " .. player.Name .. " for " .. abilityId .. " (Level " .. originalLevel .. " → " .. penaltyLevel .. ")")
end

-- Data Synchronization

function CrossTycoonProgression:SyncCrossTycoonProgression(player)
    if not player then return end
    
    local userId = player.UserId
    local data = {
        sharedAbilities = self.sharedAbilities[userId] or {},
        progression = self.playerProgression[userId],
        economyBonuses = self.economyBonuses[userId],
        theftProtection = self.theftProtection[userId]
    }
    
    -- Send to client
    self.remoteEvents.CrossTycoonProgressionSync:FireClient(player, data)
    
    print("CrossTycoonProgression: Synced progression data to " .. player.Name)
end

function CrossTycoonProgression:BroadcastAbilityUpdate(player, abilityId, newLevel)
    if not player or not abilityId or not newLevel then return end
    
    local data = {
        playerName = player.Name,
        abilityId = abilityId,
        newLevel = newLevel,
        timestamp = tick()
    }
    
    -- Send to all clients
    self.remoteEvents.SharedAbilityUpdate:FireAllClients(data)
    
    print("CrossTycoonProgression: Broadcasted ability update for " .. player.Name)
end

function CrossTycoonProgression:BroadcastAbilityTheft(stealer, target, abilityId, stolenLevel)
    if not stealer or not target or not abilityId or not stolenLevel then return end
    
    local data = {
        stealerName = stealer.Name,
        targetName = target.Name,
        abilityId = abilityId,
        stolenLevel = stolenLevel,
        timestamp = tick()
    }
    
    -- Send to all clients
    self.remoteEvents.AbilityTheftEvent:FireAllClients(data)
    
    print("CrossTycoonProgression: Broadcasted ability theft event")
end

function CrossTycoonProgression:SendEconomyBonusUpdate(player)
    if not player then return end
    
    local bonuses = self:GetEconomyBonuses(player)
    if not bonuses then return end
    
    self.remoteEvents.EconomyBonusUpdate:FireClient(player, bonuses)
    
    print("CrossTycoonProgression: Sent economy bonus update to " .. player.Name)
end

-- Event Handlers

function CrossTycoonProgression:HandlePlayerJoined(player)
    local userId = player.UserId
    
    -- Initialize player data
    self.sharedAbilities[userId] = {}
    self.playerProgression[userId] = {
        totalLevel = 0,
        abilityCount = 0,
        averageLevel = 0,
        maxLevel = 0,
        lastUpdated = tick()
    }
    self.economyBonuses[userId] = nil
    self.theftProtection[userId] = nil
    
    print("CrossTycoonProgression: Player " .. player.Name .. " joined, initialized progression data")
end

function CrossTycoonProgression:HandlePlayerLeaving(player)
    local userId = player.UserId
    
    -- Clean up player data
    self.sharedAbilities[userId] = nil
    self.playerProgression[userId] = nil
    self.economyBonuses[userId] = nil
    self.theftProtection[userId] = nil
    
    print("CrossTycoonProgression: Player " .. player.Name .. " left, cleaned up progression data")
end

function CrossTycoonProgression:HandleAbilityUpdateRequest(player, abilityId, newLevel)
    print("CrossTycoonProgression: Received ability update request from " .. player.Name .. " for " .. abilityId .. " to level " .. newLevel)
    
    local success = self:UpdateSharedAbility(player, abilityId, newLevel)
    
    -- Send response to client (could be enhanced with more detailed feedback)
    if success then
        print("CrossTycoonProgression: Successfully updated ability for " .. player.Name)
    else
        warn("CrossTycoonProgression: Failed to update ability for " .. player.Name)
    end
end

-- Utility Functions

function CrossTycoonProgression:GetAllPlayerProgression()
    local allProgression = {}
    
    for userId, progression in pairs(self.playerProgression) do
        local player = Players:GetPlayerByUserId(userId)
        if player then
            allProgression[player.Name] = progression
        end
    end
    
    return allProgression
end

function CrossTycoonProgression:GetSystemStats()
    local totalPlayers = 0
    local totalAbilities = 0
    local totalLevels = 0
    local playersWithAbilities = 0
    
    for userId, abilities in pairs(self.sharedAbilities) do
        totalPlayers = totalPlayers + 1
        local playerLevels = 0
        local abilityCount = 0
        
        for _, abilityData in pairs(abilities) do
            playerLevels = playerLevels + abilityData.level
            abilityCount = abilityCount + 1
        end
        
        totalAbilities = totalAbilities + abilityCount
        totalLevels = totalLevels + playerLevels
        
        if abilityCount > 0 then
            playersWithAbilities = playersWithAbilities + 1
        end
    end
    
    return {
        totalPlayers = totalPlayers,
        totalAbilities = totalAbilities,
        totalLevels = totalLevels,
        playersWithAbilities = playersWithAbilities,
        averageAbilitiesPerPlayer = totalPlayers > 0 and (totalAbilities / totalPlayers) or 0,
        averageLevelPerAbility = totalAbilities > 0 and (totalLevels / totalAbilities) or 0
    }
end

-- Cleanup

function CrossTycoonProgression:Cleanup()
    -- Clean up remote events
    for _, remoteEvent in pairs(self.remoteEvents) do
        if remoteEvent and remoteEvent.Parent then
            remoteEvent:Destroy()
        end
    end
    
    -- Clear data
    self.sharedAbilities = {}
    self.abilityLevels = {}
    self.crossTycoonUpgrades = {}
    self.theftProtection = {}
    self.playerProgression = {}
    self.economyBonuses = {}
    
    print("CrossTycoonProgression: Cleaned up successfully!")
end

return CrossTycoonProgression
