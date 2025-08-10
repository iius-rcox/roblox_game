-- SaveSystem.lua
-- Handles saving and loading player and tycoon data

local DataStoreService = game:GetService("DataStoreService")
local Constants = require(script.Parent.Parent.Utils.Constants)

local SaveSystem = {}

-- Data stores
local playerDataStore = nil
local tycoonDataStore = nil

-- Initialize save system
function SaveSystem:Initialize()
    print("Initializing Save System...")
    
    -- Create data stores
    playerDataStore = DataStoreService:GetDataStore("PlayerData_v1")
    tycoonDataStore = DataStoreService:GetDataStore("TycoonData_v1")
    
    print("Save System initialized successfully!")
end

-- Save player data
function SaveSystem:SavePlayerData(userId, data)
    if not playerDataStore or not userId or not data then
        warn("SavePlayerData: Invalid parameters")
        return false
    end
    
    local success, result = pcall(function()
        return playerDataStore:SetAsync(tostring(userId), data)
    end)
    
    if success then
        print("Saved player data for user: " .. userId)
        return true
    else
        warn("Failed to save player data for user " .. userId .. ": " .. tostring(result))
        return false
    end
end

-- Load player data
function SaveSystem:LoadPlayerData(userId)
    if not playerDataStore or not userId then
        warn("LoadPlayerData: Invalid parameters")
        return nil
    end
    
    local success, result = pcall(function()
        return playerDataStore:GetAsync(tostring(userId))
    end)
    
    if success and result then
        print("Loaded player data for user: " .. userId)
        return result
    else
        if success then
            print("No saved data found for user: " .. userId)
        else
            warn("Failed to load player data for user " .. userId .. ": " .. tostring(result))
        end
        return nil
    end
end

-- Save tycoon data
function SaveSystem:SaveTycoonData(tycoonId, data)
    if not tycoonDataStore or not tycoonId or not data then
        warn("SaveTycoonData: Invalid parameters")
        return false
    end
    
    local success, result = pcall(function()
        return tycoonDataStore:SetAsync(tycoonId, data)
    end)
    
    if success then
        print("Saved tycoon data for: " .. tycoonId)
        return true
    else
        warn("Failed to save tycoon data for " .. tycoonId .. ": " .. tostring(result))
        return false
    end
end

-- Load tycoon data
function SaveSystem:LoadTycoonData(tycoonId)
    if not tycoonDataStore or not tycoonId then
        warn("LoadTycoonData: Invalid parameters")
        return nil
    end
    
    local success, result = pcall(function()
        return tycoonDataStore:GetAsync(tycoonId)
    end)
    
    if success and result then
        print("Loaded tycoon data for: " .. tycoonId)
        return result
    else
        if success then
            print("No saved data found for tycoon: " .. tycoonId)
        else
            warn("Failed to load tycoon data for " .. tycoonId .. ": " .. tostring(result))
        end
        return nil
    end
end

-- Delete player data
function SaveSystem:DeletePlayerData(userId)
    if not playerDataStore or not userId then
        warn("DeletePlayerData: Invalid parameters")
        return false
    end
    
    local success, result = pcall(function()
        return playerDataStore:RemoveAsync(tostring(userId))
    end)
    
    if success then
        print("Deleted player data for user: " .. userId)
        return true
    else
        warn("Failed to delete player data for user " .. userId .. ": " .. tostring(result))
        return false
    end
end

-- Delete tycoon data
function SaveSystem:DeleteTycoonData(tycoonId)
    if not tycoonDataStore or not tycoonId then
        warn("DeleteTycoonData: Invalid parameters")
        return false
    end
    
    local success, result = pcall(function()
        return tycoonDataStore:RemoveAsync(tycoonId)
    end)
    
    if success then
        print("Deleted tycoon data for: " .. tycoonId)
        return true
    else
        warn("Failed to delete tycoon data for " .. tycoonId .. ": " .. tostring(result))
        return false
    end
end

-- Update player data (partial update)
function SaveSystem:UpdatePlayerData(userId, updates)
    if not playerDataStore or not userId or not updates then
        warn("UpdatePlayerData: Invalid parameters")
        return false
    end
    
    -- Load existing data
    local existingData = self:LoadPlayerData(userId)
    if not existingData then
        -- If no existing data, just save the updates
        return self:SavePlayerData(userId, updates)
    end
    
    -- Merge updates with existing data
    for key, value in pairs(updates) do
        existingData[key] = value
    end
    
    -- Save merged data
    return self:SavePlayerData(userId, existingData)
end

-- Update tycoon data (partial update)
function SaveSystem:UpdateTycoonData(tycoonId, updates)
    if not tycoonDataStore or not tycoonId or not updates then
        warn("UpdateTycoonData: Invalid parameters")
        return false
    end
    
    -- Load existing data
    local existingData = self:LoadTycoonData(tycoonId)
    if not existingData then
        -- If no existing data, just save the updates
        return self:SaveTycoonData(tycoonId, updates)
    end
    
    -- Merge updates with existing data
    for key, value in pairs(updates) do
        existingData[key] = value
    end
    
    -- Save merged data
    return self:SaveTycoonData(tycoonId, existingData)
end

-- Get all player data (for admin purposes)
function SaveSystem:GetAllPlayerData()
    if not playerDataStore then
        warn("GetAllPlayerData: Data store not initialized")
        return {}
    end
    
    -- Note: This is a simplified version. In a real implementation,
    -- you might want to use DataStoreService:ListDataStoreAsync() or similar
    -- to get a list of all stored keys.
    
    warn("GetAllPlayerData: Not implemented in this version")
    return {}
end

-- Get all tycoon data (for admin purposes)
function SaveSystem:GetAllTycoonData()
    if not tycoonDataStore then
        warn("GetAllTycoonData: Data store not initialized")
        return {}
    end
    
    -- Note: This is a simplified version. In a real implementation,
    -- you might want to use DataStoreService:ListDataStoreAsync() or similar
    -- to get a list of all stored keys.
    
    warn("GetAllTycoonData: Not implemented in this version")
    return {}
end

-- Check if player data exists
function SaveSystem:PlayerDataExists(userId)
    if not playerDataStore or not userId then
        return false
    end
    
    local success, result = pcall(function()
        return playerDataStore:GetAsync(tostring(userId))
    end)
    
    return success and result ~= nil
end

-- Check if tycoon data exists
function SaveSystem:TycoonDataExists(tycoonId)
    if not tycoonDataStore or not tycoonId then
        return false
    end
    
    local success, result = pcall(function()
        return tycoonDataStore:GetAsync(tycoonId)
    end)
    
    return success and result ~= nil
end

-- Get data store info
function SaveSystem:GetDataStoreInfo()
    return {
        PlayerDataStore = playerDataStore ~= nil,
        TycoonDataStore = tycoonDataStore ~= nil,
        IsInitialized = playerDataStore ~= nil and tycoonDataStore ~= nil
    }
end

-- Clean up save system
function SaveSystem:Cleanup()
    print("Cleaning up Save System...")
    
    -- Clear references
    playerDataStore = nil
    tycoonDataStore = nil
    
    print("Save System cleanup complete")
end

-- Export the module
return SaveSystem
