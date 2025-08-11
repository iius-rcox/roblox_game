-- TycoonSync.lua
-- Handles real-time synchronization of tycoon data across the network

local TycoonSync = {}
TycoonSync.__index = TycoonSync

-- Callback functions for integration
TycoonSync.OnTycoonClaimed = nil
TycoonSync.OnTycoonReleased = nil

-- Services
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Constants
local TYCOON_SYNC_INTERVAL = 0.2 -- Sync every 200ms
local CASH_SYNC_INTERVAL = 1.0 -- Cash sync every 1 second
local OWNERSHIP_SYNC_INTERVAL = 0.5 -- Ownership sync every 500ms

-- Tycoon data cache
local tycoonData = {}
local lastSyncTime = {}
local tycoonOwners = {}

-- Network manager reference
local NetworkManager = require(script.Parent.NetworkManager)

-- Initialize tycoon sync
function TycoonSync:Initialize()
    print("TycoonSync initialized")
    
    -- Set up tycoon data structure
    self:SetupTycoonData()
    
    -- Start sync loops
    self:StartSyncLoops()
    
    -- Set up network handlers
    self:SetupNetworkHandlers()
end

-- Set up initial tycoon data structure
function TycoonSync:SetupTycoonData()
    -- Initialize with default tycoon data
    for i = 1, 8 do -- 8 tycoon plots
        local tycoonId = "Tycoon_" .. i
        tycoonData[tycoonId] = {
            Id = tycoonId,
            Name = "Tycoon " .. i,
            Owner = nil,
            CashGenerated = 0,
            Level = 1,
            Upgrades = {},
            LastActive = tick(),
            IsActive = false,
            Position = Vector3.new(i * 100, 0, 0), -- Spread out tycoons
            WallHealth = {},
            CashGeneratorLevel = 1,
            LastCashGeneration = tick()
        }
        
        lastSyncTime[tycoonId] = 0
        tycoonOwners[tycoonId] = nil
    end
    
    print("TycoonSync: Initialized", #tycoonData, "tycoons")
end

-- Set up network event handlers
function TycoonSync:SetupNetworkHandlers()
    -- Handle tycoon claiming
    NetworkManager:RegisterHandler("TycoonClaim", function(player, tycoonId)
        self:HandleTycoonClaim(player, tycoonId)
    end)
    
    -- Handle tycoon switching
    NetworkManager:RegisterHandler("TycoonSwitch", function(player, tycoonId)
        self:HandleTycoonSwitch(player, tycoonId)
    end)
end

-- Handle tycoon claim request
function TycoonSync:HandleTycoonClaim(player, tycoonId)
    if not tycoonData[tycoonId] then
        NetworkManager:SendError(player, "Invalid tycoon ID")
        return
    end
    
    local currentOwner = tycoonOwners[tycoonId]
    
    if currentOwner then
        if currentOwner == player.UserId then
            NetworkManager:NotifyClient(player, "You already own this tycoon!", "Info")
        else
            NetworkManager:SendError(player, "This tycoon is already owned by another player")
        end
        return
    end
    
    -- Claim the tycoon
    self:ClaimTycoon(player.UserId, tycoonId)
    NetworkManager:NotifyClient(player, "Successfully claimed " .. tycoonData[tycoonId].Name .. "!", "Success")
end

-- Handle tycoon switch request
function TycoonSync:HandleTycoonSwitch(player, tycoonId)
    if not tycoonData[tycoonId] then
        NetworkManager:SendError(player, "Invalid tycoon ID")
        return
    end
    
    local currentOwner = tycoonOwners[tycoonId]
    
    if not currentOwner or currentOwner ~= player.UserId then
        NetworkManager:SendError(player, "You don't own this tycoon")
        return
    end
    
    -- Switch to the tycoon
    self:SwitchToTycoon(player.UserId, tycoonId)
    NetworkManager:NotifyClient(player, "Switched to " .. tycoonData[tycoonId].Name, "Info")
end

-- Claim a tycoon for a player
function TycoonSync:ClaimTycoon(userId, tycoonId)
    if not tycoonData[tycoonId] then return false end
    
    -- Set ownership
    tycoonOwners[tycoonId] = userId
    tycoonData[tycoonId].Owner = userId
    tycoonData[tycoonId].LastActive = tick()
    tycoonData[tycoonId].IsActive = true
    
    -- Notify all clients
    NetworkManager:FireAllClients("TycoonDataUpdate", tycoonId, tycoonData[tycoonId])
    
    -- NEW: Trigger callback for TycoonBase integration
    if self.OnTycoonClaimed then
        self:OnTycoonClaimed(userId, tycoonId)
    end
    
    print("TycoonSync: Player", userId, "claimed", tycoonId)
    return true
end

-- Switch player to a tycoon they own
function TycoonSync:SwitchToTycoon(userId, tycoonId)
    if not tycoonData[tycoonId] then return false end
    
    local currentOwner = tycoonOwners[tycoonId]
    if currentOwner ~= userId then return false end
    
    -- Update last active time
    tycoonData[tycoonId].LastActive = tick()
    
    -- Notify all clients
    NetworkManager:FireAllClients("TycoonDataUpdate", tycoonId, tycoonData[tycoonId])
    
    print("TycoonSync: Player", userId, "switched to", tycoonId)
    return true
end

-- Release a tycoon (when player leaves or loses ownership)
function TycoonSync:ReleaseTycoon(tycoonId)
    if not tycoonData[tycoonId] then return false end
    
    local owner = tycoonOwners[tycoonId]
    if not owner then return false end
    
    -- Clear ownership
    tycoonOwners[tycoonId] = nil
    tycoonData[tycoonId].Owner = nil
    tycoonData[tycoonId].IsActive = false
    
    -- Notify all clients
    NetworkManager:FireAllClients("TycoonDataUpdate", tycoonId, tycoonData[tycoonId])
    
    -- NEW: Trigger callback for TycoonBase integration
    if self.OnTycoonReleased then
        self:OnTycoonReleased(tycoonId)
    end
    
    print("TycoonSync: Released", tycoonId, "from player", owner)
    return true
end

-- NEW: Set callback for tycoon claimed
function TycoonSync:SetOnTycoonClaimed(callback)
    self.OnTycoonClaimed = callback
end

-- NEW: Set callback for tycoon released
function TycoonSync:SetOnTycoonReleased(callback)
    self.OnTycoonReleased = callback
end

-- Update tycoon cash generation
function TycoonSync:UpdateTycoonCash(tycoonId, amount)
    if not tycoonData[tycoonId] then return false end
    
    tycoonData[tycoonId].CashGenerated = tycoonData[tycoonId].CashGenerated + amount
    tycoonData[tycoonId].LastCashGeneration = tick()
    
    -- Queue cash sync
    self:QueueCashSync(tycoonId)
    
    return true
end

-- Update tycoon level
function TycoonSync:UpdateTycoonLevel(tycoonId, newLevel)
    if not tycoonData[tycoonId] then return false end
    
    tycoonData[tycoonId].Level = newLevel
    
    -- Notify all clients immediately
    NetworkManager:FireAllClients("TycoonDataUpdate", tycoonId, tycoonData[tycoonId])
    
    return true
end

-- Update tycoon upgrades
function TycoonSync:UpdateTycoonUpgrades(tycoonId, upgrades)
    if not tycoonData[tycoonId] then return false end
    
    tycoonData[tycoonId].Upgrades = upgrades
    
    -- Notify all clients immediately
    NetworkManager:FireAllClients("TycoonDataUpdate", tycoonId, tycoonData[tycoonId])
    
    return true
end

-- Update wall health for a tycoon
function TycoonSync:UpdateWallHealth(tycoonId, wallId, health)
    if not tycoonData[tycoonId] then return false end
    
    if not tycoonData[tycoonId].WallHealth then
        tycoonData[tycoonId].WallHealth = {}
    end
    
    tycoonData[tycoonId].WallHealth[wallId] = health
    
    -- Queue sync
    self:QueueSync(tycoonId, "WallHealth")
    
    return true
end

-- Queue a sync update for a tycoon
function TycoonSync:QueueSync(tycoonId, dataType)
    if not lastSyncTime[tycoonId] then return end
    
    local currentTime = tick()
    if currentTime - lastSyncTime[tycoonId] >= TYCOON_SYNC_INTERVAL then
        self:SyncTycoonData(tycoonId)
        lastSyncTime[tycoonId] = currentTime
    end
end

-- Queue cash sync for a tycoon
function TycoonSync:QueueCashSync(tycoonId)
    if not lastSyncTime[tycoonId] then return end
    
    local currentTime = tick()
    if currentTime - lastSyncTime[tycoonId] >= CASH_SYNC_INTERVAL then
        self:SyncTycoonData(tycoonId)
        lastSyncTime[tycoonId] = currentTime
    end
end

-- Sync tycoon data to all clients
function TycoonSync:SyncTycoonData(tycoonId)
    if not tycoonData[tycoonId] then return end
    
    -- Update last sync time
    lastSyncTime[tycoonId] = tick()
    
    -- Send to all clients
    NetworkManager:FireAllClients("TycoonDataUpdate", tycoonId, tycoonData[tycoonId])
end

-- Start all sync loops
function TycoonSync:StartSyncLoops()
    -- Main tycoon sync loop
    RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        
        for tycoonId, lastSync in pairs(lastSyncTime) do
            if currentTime - lastSync >= TYCOON_SYNC_INTERVAL then
                self:SyncTycoonData(tycoonId)
            end
        end
    end)
    
    -- Cash generation loop
    RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        
        for tycoonId, data in pairs(tycoonData) do
            if data.Owner and data.IsActive then
                -- Generate cash based on level and upgrades
                local cashPerSecond = data.CashGeneratorLevel * 10
                local timeSinceLastGen = currentTime - data.LastCashGeneration
                
                if timeSinceLastGen >= 1.0 then
                    local cashGenerated = cashPerSecond * timeSinceLastGen
                    self:UpdateTycoonCash(tycoonId, cashGenerated)
                    data.LastCashGeneration = currentTime
                end
            end
        end
    end)
end

-- Get tycoon data
function TycoonSync:GetTycoonData(tycoonId)
    return tycoonData[tycoonId]
end

-- Get all tycoon data
function TycoonSync:GetAllTycoonData()
    return tycoonData
end

-- Get tycoon owner
function TycoonSync:GetTycoonOwner(tycoonId)
    return tycoonOwners[tycoonId]
end

-- Check if tycoon is owned
function TycoonSync:IsTycoonOwned(tycoonId)
    return tycoonOwners[tycoonId] ~= nil
end

-- Check if player owns tycoon
function TycoonSync:PlayerOwnsTycoon(userId, tycoonId)
    return tycoonOwners[tycoonId] == userId
end

-- Get player's owned tycoons
function TycoonSync:GetPlayerTycoons(userId)
    local ownedTycoons = {}
    
    for tycoonId, owner in pairs(tycoonOwners) do
        if owner == userId then
            table.insert(ownedTycoons, tycoonId)
        end
    end
    
    return ownedTycoons
end

-- Force sync a specific tycoon
function TycoonSync:ForceSync(tycoonId)
    if tycoonData[tycoonId] then
        self:SyncTycoonData(tycoonId)
        lastSyncTime[tycoonId] = tick()
    end
end

-- Force sync all tycoons
function TycoonSync:ForceSyncAll()
    for tycoonId, _ in pairs(tycoonData) do
        self:ForceSync(tycoonId)
    end
end

return TycoonSync
