-- PlayerData.lua
-- Manages player data including cash, abilities, and tycoon ownership

local Players = game:GetService("Players")
local Constants = require(script.Parent.Parent.Utils.Constants)

local PlayerData = {}
PlayerData.__index = PlayerData

-- Player data structure
local DefaultPlayerData = {
    Cash = Constants.ECONOMY.STARTING_CASH,
    OwnedTycoons = {},  -- Array of tycoon IDs the player owns
    CurrentTycoon = nil,  -- Current active tycoon ID
    Abilities = {},  -- Shared abilities across all tycoons
    LastSave = tick(),
    Level = 1,
    Experience = 0,
    -- NEW: Cross-tycoon progression data
    TotalCashGenerated = 0,  -- Total cash generated across all tycoons
    TycoonStats = {},  -- Individual stats for each owned tycoon
    LastTycoonSwitch = tick(),
    PlotSwitchingCooldown = 5  -- 5 second cooldown between plot switches
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

-- Get cash amount (shared across all tycoons)
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
        self.data.Cash = newAmount
        return true
    end
    return false
end

-- Check if player can afford something
function PlayerData:CanAfford(cost)
    return self:GetCash() >= cost
end

-- NEW: Get total cash generated across all tycoons
function PlayerData:GetTotalCashGenerated()
    return self.data.TotalCashGenerated or 0
end

-- NEW: Add to total cash generated
function PlayerData:AddTotalCashGenerated(amount)
    if type(amount) == "number" and amount >= 0 then
        self.data.TotalCashGenerated = (self.data.TotalCashGenerated or 0) + amount
        return true
    end
    return false
end

-- Get ability level (shared across all tycoons)
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

-- NEW: Check if player owns a specific tycoon
function PlayerData:OwnsTycoon(tycoonId)
    if not self.data.OwnedTycoons then return false end
    
    for _, ownedId in ipairs(self.data.OwnedTycoons) do
        if ownedId == tycoonId then
            return true
        end
    end
    return false
end

-- NEW: Add tycoon ownership
function PlayerData:AddTycoonOwnership(tycoonId)
    if type(tycoonId) == "string" or type(tycoonId) == "number" then
        if not self.data.OwnedTycoons then
            self.data.OwnedTycoons = {}
        end
        
        -- Check if already owned
        if not self:OwnsTycoon(tycoonId) then
            table.insert(self.data.OwnedTycoons, tycoonId)
            
            -- Initialize tycoon stats
            if not self.data.TycoonStats then
                self.data.TycoonStats = {}
            end
            self.data.TycoonStats[tostring(tycoonId)] = {
                CashGenerated = 0,
                UpgradesPurchased = 0,
                LastActive = tick(),
                Theme = "Unknown"
            }
            
            -- Set as current if this is the first tycoon
            if #self.data.OwnedTycoons == 1 then
                self:SetCurrentTycoon(tycoonId)
            end
            
            return true
        end
    end
    return false
end

-- NEW: Remove tycoon ownership
function PlayerData:RemoveTycoonOwnership(tycoonId)
    if not self.data.OwnedTycoons then return false end
    
    for i, ownedId in ipairs(self.data.OwnedTycoons) do
        if ownedId == tycoonId then
            table.remove(self.data.OwnedTycoons, i)
            
            -- Clean up tycoon stats
            if self.data.TycoonStats then
                self.data.TycoonStats[tostring(tycoonId)] = nil
            end
            
            -- If this was the current tycoon, set a new one
            if self.data.CurrentTycoon == tycoonId then
                if #self.data.OwnedTycoons > 0 then
                    self:SetCurrentTycoon(self.data.OwnedTycoons[1])
                else
                    self:SetCurrentTycoon(nil)
                end
            end
            
            return true
        end
    end
    return false
end

-- NEW: Get all owned tycoons
function PlayerData:GetOwnedTycoons()
    if not self.data.OwnedTycoons then
        return {}
    end
    return table.clone(self.data.OwnedTycoons)
end

-- NEW: Get number of owned tycoons
function PlayerData:GetTycoonCount()
    if not self.data.OwnedTycoons then
        return 0
    end
    return #self.data.OwnedTycoons
end

-- NEW: Check if player can own more tycoons
function PlayerData:CanOwnMoreTycoons()
    return self:GetTycoonCount() < 3  -- Maximum of 3 tycoons
end

-- Set current tycoon
function PlayerData:SetCurrentTycoon(tycoonId)
    if tycoonId == nil or type(tycoonId) == "string" or type(tycoonId) == "number" then
        -- NEW: Check cooldown for tycoon switching
        local currentTime = tick()
        local timeSinceLastSwitch = currentTime - (self.data.LastTycoonSwitch or 0)
        
        if timeSinceLastSwitch < self.data.PlotSwitchingCooldown then
            print("PlayerData: Tycoon switching on cooldown. Wait " .. math.ceil(self.data.PlotSwitchingCooldown - timeSinceLastSwitch) .. " more seconds.")
            return false
        end
        
        self.data.CurrentTycoon = tycoonId
        self.data.LastTycoonSwitch = currentTime
        
        -- Update last active time for the tycoon
        if tycoonId and self.data.TycoonStats then
            local stats = self.data.TycoonStats[tostring(tycoonId)]
            if stats then
                stats.LastActive = currentTime
            end
        end
        
        return true
    end
    return false
end

-- Get current tycoon
function PlayerData:GetCurrentTycoon()
    return self.data.CurrentTycoon
end

-- NEW: Get tycoon statistics
function PlayerData:GetTycoonStats(tycoonId)
    if not self.data.TycoonStats then return nil end
    return self.data.TycoonStats[tostring(tycoonId)]
end

-- NEW: Update tycoon statistics
function PlayerData:UpdateTycoonStats(tycoonId, stats)
    if not self.data.TycoonStats then
        self.data.TycoonStats = {}
    end
    
    if not self.data.TycoonStats[tostring(tycoonId)] then
        self.data.TycoonStats[tostring(tycoonId)] = {
            CashGenerated = 0,
            UpgradesPurchased = 0,
            LastActive = tick(),
            Theme = "Unknown"
        }
    end
    
    -- Update provided stats
    for key, value in pairs(stats) do
        if key == "CashGenerated" and type(value) == "number" then
            self.data.TycoonStats[tostring(tycoonId)][key] = value
            -- Also add to total
            self:AddTotalCashGenerated(value - (self.data.TycoonStats[tostring(tycoonId)][key] or 0))
        elseif key == "UpgradesPurchased" and type(value) == "number" then
            self.data.TycoonStats[tostring(tycoonId)][key] = value
        elseif key == "Theme" and type(value) == "string" then
            self.data.TycoonStats[tostring(tycoonId)][key] = value
        end
    end
    
    return true
end

-- NEW: Get all tycoon statistics
function PlayerData:GetAllTycoonStats()
    if not self.data.TycoonStats then
        return {}
    end
    return table.clone(self.data.TycoonStats)
end

-- NEW: Get switching cooldown remaining
function PlayerData:GetSwitchingCooldownRemaining()
    local currentTime = tick()
    local timeSinceLastSwitch = currentTime - (self.data.LastTycoonSwitch or 0)
    local remaining = math.max(0, self.data.PlotSwitchingCooldown - timeSinceLastSwitch)
    return remaining
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
