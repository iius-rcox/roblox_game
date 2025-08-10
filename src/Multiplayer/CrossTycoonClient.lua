-- CrossTycoonClient.lua
-- Client-side handler for cross-tycoon progression and shared abilities

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(script.Parent.Parent.Utils.Constants)

local CrossTycoonClient = {}
CrossTycoonClient.__index = CrossTycoonClient

-- RemoteEvents for client-server communication
local RemoteEvents = {
    SharedAbilityUpdate = "SharedAbilityUpdate",
    CrossTycoonProgressionSync = "CrossTycoonProgressionSync",
    AbilityTheftEvent = "AbilityTheftEvent",
    EconomyBonusUpdate = "EconomyBonusUpdate"
}

function CrossTycoonClient.new()
    local self = setmetatable({}, CrossTycoonClient)
    
    -- Client state
    self.player = Players.LocalPlayer
    self.sharedAbilities = {}
    self.abilityLevels = {}
    self.crossTycoonUpgrades = {}
    self.playerProgression = {}
    self.economyBonuses = {}
    
    -- Remote events
    self.remoteEvents = {}
    
    -- Callbacks
    self.onAbilityUpdate = nil
    self.onProgressionSync = nil
    self.onAbilityTheft = nil
    self.onEconomyUpdate = nil
    
    return self
end

function CrossTycoonClient:Initialize()
    -- Set up remote events
    self:SetupRemoteEvents()
    
    -- Connect to events
    self:ConnectToEvents()
    
    -- Initialize default abilities
    self:InitializeDefaultAbilities()
    
    print("CrossTycoonClient: Initialized successfully!")
end

function CrossTycoonClient:SetupRemoteEvents()
    -- Wait for remote events to be created by server
    for eventName, _ in pairs(RemoteEvents) do
        local remoteEvent = ReplicatedStorage:WaitForChild(eventName, 10)
        if remoteEvent then
            self.remoteEvents[eventName] = remoteEvent
        else
            warn("CrossTycoonClient: Failed to find remote event: " .. eventName)
        end
    end
end

function CrossTycoonClient:ConnectToEvents()
    -- Shared ability update
    if self.remoteEvents.SharedAbilityUpdate then
        self.remoteEvents.SharedAbilityUpdate.OnClientEvent:Connect(function(abilityId, newLevel)
            self:HandleSharedAbilityUpdate(abilityId, newLevel)
        end)
    end
    
    -- Cross-tycoon progression sync
    if self.remoteEvents.CrossTycoonProgressionSync then
        self.remoteEvents.CrossTycoonProgressionSync.OnClientEvent:Connect(function(data)
            self:HandleProgressionSync(data)
        end)
    end
    
    -- Ability theft event
    if self.remoteEvents.AbilityTheftEvent then
        self.remoteEvents.AbilityTheftEvent.OnClientEvent:Connect(function(data)
            self:HandleAbilityTheft(data)
        end)
    end
    
    -- Economy bonus update
    if self.remoteEvents.EconomyBonusUpdate then
        self.remoteEvents.EconomyBonusUpdate.OnClientEvent:Connect(function(bonuses)
            self:HandleEconomyUpdate(bonuses)
        end)
    end
end

function CrossTycoonClient:InitializeDefaultAbilities()
    -- Initialize all abilities with base levels
    for abilityName, _ in pairs(Constants.ABILITIES) do
        self.sharedAbilities[abilityName] = true
        self.abilityLevels[abilityName] = 1
        self.crossTycoonUpgrades[abilityName] = {
            baseCost = Constants.ECONOMY.ABILITY_BASE_COST,
            currentLevel = 1,
            maxLevel = Constants.ECONOMY.MAX_UPGRADE_LEVEL
        }
    end
end

-- Event Handlers

function CrossTycoonClient:HandleSharedAbilityUpdate(abilityId, newLevel)
    if not abilityId or not newLevel then return end
    
    -- Update ability level
    self.abilityLevels[abilityId] = newLevel
    
    -- Trigger callback
    if self.onAbilityUpdate then
        self.onAbilityUpdate(abilityId, newLevel)
    end
    
    print("CrossTycoonClient: Ability " .. abilityId .. " updated to level " .. newLevel)
end

function CrossTycoonClient:HandleProgressionSync(data)
    if not data then return end
    
    -- Update progression data
    if data.sharedAbilities then
        self.sharedAbilities = data.sharedAbilities
    end
    
    if data.abilityLevels then
        self.abilityLevels = data.abilityLevels
    end
    
    if data.crossTycoonUpgrades then
        self.crossTycoonUpgrades = data.crossTycoonUpgrades
    end
    
    if data.playerProgression then
        self.playerProgression = data.playerProgression
    end
    
    -- Trigger callback
    if self.onProgressionSync then
        self.onProgressionSync(data)
    end
    
    print("CrossTycoonClient: Received progression sync")
end

function CrossTycoonClient:HandleAbilityTheft(data)
    if not data then return end
    
    -- Handle ability theft event
    local stealerName = data.stealerName or "Unknown"
    local targetName = data.targetName or "Unknown"
    local abilityId = data.abilityId or "Unknown"
    
    -- Trigger callback
    if self.onAbilityTheft then
        self.onAbilityTheft(data)
    end
    
    print("CrossTycoonClient: " .. stealerName .. " stole " .. abilityId .. " from " .. targetName)
end

function CrossTycoonClient:HandleEconomyUpdate(bonuses)
    if not bonuses then return end
    
    self.economyBonuses = bonuses
    
    -- Trigger callback
    if self.onEconomyUpdate then
        self.onEconomyUpdate(bonuses)
    end
    
    print("CrossTycoonClient: Received economy update")
end

-- Public API

function CrossTycoonClient:GetSharedAbilities()
    return self.sharedAbilities
end

function CrossTycoonClient:GetAbilityLevel(abilityId)
    return self.abilityLevels[abilityId] or 1
end

function CrossTycoonClient:GetCrossTycoonUpgrade(abilityId)
    return self.crossTycoonUpgrades[abilityId]
end

function CrossTycoonClient:GetPlayerProgression()
    return self.playerProgression
end

function CrossTycoonClient:GetEconomyBonuses()
    return self.economyBonuses
end

function CrossTycoonClient:HasAbility(abilityId)
    return self.sharedAbilities[abilityId] == true
end

function CrossTycoonClient:GetTotalAbilityLevel()
    local total = 0
    for _, level in pairs(self.abilityLevels) do
        total = total + level
    end
    return total
end

function CrossTycoonClient:GetAbilityCount()
    local count = 0
    for _, hasAbility in pairs(self.sharedAbilities) do
        if hasAbility then
            count = count + 1
        end
    end
    return count
end

function CrossTycoonClient:RequestAbilityUpgrade(abilityId)
    if not self.remoteEvents.SharedAbilityUpdate then
        warn("CrossTycoonClient: SharedAbilityUpdate remote event not available")
        return false
    end
    
    -- Check if player has the ability
    if not self:HasAbility(abilityId) then
        warn("CrossTycoonClient: Player doesn't have ability " .. abilityId)
        return false
    end
    
    -- Check upgrade level
    local upgrade = self:GetCrossTycoonUpgrade(abilityId)
    if not upgrade or upgrade.currentLevel >= upgrade.maxLevel then
        warn("CrossTycoonClient: Ability " .. abilityId .. " is at max level")
        return false
    end
    
    -- Send request to server
    self.remoteEvents.SharedAbilityUpdate:FireServer(abilityId, upgrade.currentLevel + 1)
    print("CrossTycoonClient: Sent ability upgrade request for " .. abilityId)
    return true
end

-- Callback Setters

function CrossTycoonClient:SetOnAbilityUpdate(callback)
    self.onAbilityUpdate = callback
end

function CrossTycoonClient:SetOnProgressionSync(callback)
    self.onProgressionSync = callback
end

function CrossTycoonClient:SetOnAbilityTheft(callback)
    self.onAbilityTheft = callback
end

function CrossTycoonClient:SetOnEconomyUpdate(callback)
    self.onEconomyUpdate = callback
end

-- Cleanup

function CrossTycoonClient:Cleanup()
    -- Disconnect from events
    for _, remoteEvent in pairs(self.remoteEvents) do
        if remoteEvent then
            remoteEvent.OnClientEvent:Disconnect()
        end
    end
    
    -- Clear callbacks
    self.onAbilityUpdate = nil
    self.onProgressionSync = nil
    self.onAbilityTheft = nil
    self.onEconomyUpdate = nil
    
    print("CrossTycoonClient: Cleaned up successfully!")
end

return CrossTycoonClient
