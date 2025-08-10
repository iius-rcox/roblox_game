-- PlayerData.lua
-- Manages player data including cash, abilities, and tycoon ownership

local Players = game:GetService("Players")
local Constants = require(script.Parent.Parent.Utils.Constants)

local PlayerData = {}
PlayerData.__index = PlayerData

-- Player data structure
local DefaultPlayerData = {
    Cash = Constants.ECONOMY.STARTING_CASH,
    OwnedTycoons = {},
    CurrentTycoon = nil,
    Abilities = {},
    LastSave = tick(),
    Level = 1,
    Experience = 0
}

-- Store player data
local playerDataStore = {}

-- Create new player data
function PlayerData.new(player)
    if not player or not player:IsA("Player") then
        warn("Invalid player provided to PlayerData.new")
        return nil
    end
    
    local self = setmetatable({}, PlayerData)
    self.player = player
    self.userId = player.UserId
    
    -- Initialize with default data
    self.data = table.clone(DefaultPlayerData)
    
    -- Store in global store
    playerDataStore[player.UserId] = self
    
    return self
end

-- Get player data by player or userId
function PlayerData.GetPlayerData(playerOrUserId)
    local userId = type(playerOrUserId) == "number" and playerOrUserId or playerOrUserId.UserId
    return playerDataStore[userId]
end

-- Get cash amount
function PlayerData:GetCash()
    return self.data.Cash or 0
end

-- Set cash amount
function PlayerData:SetCash(amount)
    if type(amount) == "number" and amount >= 0 then
        self.data.Cash = amount
        return true
    end
    return false
end

-- Add cash (can be negative for spending)
function PlayerData:AddCash(amount)
    local newAmount = self:GetCash() + amount
    if newAmount >= 0 then
        self:SetCash(newAmount)
        return true
    end
    return false
end

-- Check if player can afford something
function PlayerData:CanAfford(cost)
    return self:GetCash() >= cost
end

-- Get ability level
function PlayerData:GetAbilityLevel(abilityName)
    return self.data.Abilities[abilityName] or 0
end

-- Set ability level
function PlayerData:SetAbilityLevel(abilityName, level)
    if type(level) == "number" and level >= 0 and level <= Constants.ECONOMY.MAX_UPGRADE_LEVEL then
        self.data.Abilities[abilityName] = level
        return true
    end
    return false
end

-- Upgrade ability
function PlayerData:UpgradeAbility(abilityName)
    local currentLevel = self:GetAbilityLevel(abilityName)
    local newLevel = currentLevel + 1
    
    if newLevel <= Constants.ECONOMY.MAX_UPGRADE_LEVEL then
        self:SetAbilityLevel(abilityName, newLevel)
        return true
    end
    return false
end

-- Get all abilities
function PlayerData:GetAllAbilities()
    return table.clone(self.data.Abilities)
end

-- Check if player owns a tycoon
function PlayerData:OwnsTycoon(tycoonId)
    return self.data.OwnedTycoons[tycoonId] == true
end

-- Add tycoon ownership
function PlayerData:AddTycoonOwnership(tycoonId)
    if type(tycoonId) == "string" then
        self.data.OwnedTycoons[tycoonId] = true
        return true
    end
    return false
end

-- Remove tycoon ownership
function PlayerData:RemoveTycoonOwnership(tycoonId)
    if type(tycoonId) == "string" then
        self.data.OwnedTycoons[tycoonId] = nil
        return true
    end
    return false
end

-- Get owned tycoons
function PlayerData:GetOwnedTycoons()
    local owned = {}
    for tycoonId, _ in pairs(self.data.OwnedTycoons) do
        table.insert(owned, tycoonId)
    end
    return owned
end

-- Set current tycoon
function PlayerData:SetCurrentTycoon(tycoonId)
    if tycoonId == nil or type(tycoonId) == "string" then
        self.data.CurrentTycoon = tycoonId
        return true
    end
    return false
end

-- Get current tycoon
function PlayerData:GetCurrentTycoon()
    return self.data.CurrentTycoon
end

-- Get player level
function PlayerData:GetLevel()
    return self.data.Level or 1
end

-- Get experience
function PlayerData:GetExperience()
    return self.data.Experience or 0
end

-- Add experience
function PlayerData:AddExperience(amount)
    if type(amount) == "number" and amount > 0 then
        self.data.Experience = self:GetExperience() + amount
        
        -- Check for level up
        local currentLevel = self:GetLevel()
        local experienceNeeded = currentLevel * 100 -- Simple leveling formula
        
        if self.data.Experience >= experienceNeeded then
            self.data.Level = currentLevel + 1
            self.data.Experience = self.data.Experience - experienceNeeded
            return true, self.data.Level -- Return true and new level
        end
        
        return false, currentLevel
    end
    return false, self:GetLevel()
end

-- Get all player data for saving
function PlayerData:GetAllData()
    return table.clone(self.data)
end

-- Load player data
function PlayerData:LoadData(data)
    if type(data) == "table" then
        -- Validate and load data
        for key, defaultValue in pairs(DefaultPlayerData) do
            if data[key] ~= nil then
                self.data[key] = data[key]
            else
                self.data[key] = defaultValue
            end
        end
        
        -- Ensure data integrity
        self.data.Cash = math.max(0, self.data.Cash or 0)
        self.data.Level = math.max(1, self.data.Level or 1)
        self.data.Experience = math.max(0, self.data.Experience or 0)
        
        return true
    end
    return false
end

-- Reset player data to defaults
function PlayerData:ResetData()
    self.data = table.clone(DefaultPlayerData)
    return true
end

-- Clean up when player leaves
function PlayerData:Destroy()
    if self.player then
        playerDataStore[self.userId] = nil
        self.player = nil
    end
end

-- Clean up all player data (call when server shuts down)
function PlayerData.CleanupAll()
    for userId, playerData in pairs(playerDataStore) do
        if playerData.Destroy then
            playerData:Destroy()
        end
    end
    playerDataStore = {}
end

-- Auto-cleanup when players leave
Players.PlayerRemoving:Connect(function(player)
    local playerData = PlayerData.GetPlayerData(player)
    if playerData then
        playerData:Destroy()
    end
end)

return PlayerData
