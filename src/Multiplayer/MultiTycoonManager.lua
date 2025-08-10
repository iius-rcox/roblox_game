-- MultiTycoonManager.lua
-- Manages multiple tycoon ownership and cross-tycoon progression

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Constants = require(script.Parent.Parent.Utils.Constants)
local NetworkManager = require(script.Parent.NetworkManager)

local MultiTycoonManager = {}
MultiTycoonManager.__index = MultiTycoonManager

-- RemoteEvents for client-server communication
local RemoteEvents = {
    PlayerTycoonUpdate = "PlayerTycoonUpdate",
    PlotSwitchRequest = "PlotSwitchRequest",
    PlotSwitchResponse = "PlotSwitchResponse",
    CrossTycoonBonusUpdate = "CrossTycoonBonusUpdate",
    MultiTycoonDataSync = "MultiTycoonDataSync"
}

function MultiTycoonManager.new()
    local self = setmetatable({}, MultiTycoonManager)
    
    -- Core data structures
    self.playerTycoons = {}           -- Player -> [Tycoon IDs]
    self.tycoonData = {}              -- Tycoon ID -> Data
    self.crossTycoonBonuses = {}      -- Player -> Bonus Data
    self.plotSwitchingCooldowns = {}  -- Player -> Cooldown Timers
    self.playerCurrentTycoon = {}     -- Player -> Current Active Tycoon ID
    
    -- Network manager reference
    self.networkManager = nil
    
    -- Initialize remote events
    self.remoteEvents = {}
    
    return self
end

function MultiTycoonManager:Initialize(networkManager)
    self.networkManager = networkManager
    
    -- Set up remote events
    self:SetupRemoteEvents()
    
    -- Connect to player events
    self:ConnectPlayerEvents()
    
    -- Set up periodic maintenance
    self:SetupPeriodicMaintenance()
    
    print("MultiTycoonManager: Initialized successfully!")
end

-- NEW: Set up periodic maintenance tasks
function MultiTycoonManager:SetupPeriodicMaintenance()
    -- Run data integrity checks every 5 minutes
    local integrityCheckConnection
    integrityCheckConnection = RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        if not self.lastIntegrityCheck then
            self.lastIntegrityCheck = 0
        end
        
        if currentTime - self.lastIntegrityCheck >= 300 then -- 5 minutes
            self.lastIntegrityCheck = currentTime
            self:ValidateDataIntegrity()
        end
    end)
    
    -- Clean up old preserved data every hour
    local cleanupConnection
    cleanupConnection = RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        if not self.lastCleanup then
            self.lastCleanup = 0
        end
        
        if currentTime - self.lastCleanup >= 3600 then -- 1 hour
            self.lastCleanup = currentTime
            self:CleanupOldPreservedData()
        end
    end)
    
    -- Store connections for cleanup
    self.maintenanceConnections = {
        integrityCheck = integrityCheckConnection,
        cleanup = cleanupConnection
    }
    
    print("MultiTycoonManager: Periodic maintenance tasks configured")
end

function MultiTycoonManager:SetupRemoteEvents()
    -- Create remote events in ReplicatedStorage
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    
    for eventName, _ in pairs(RemoteEvents) do
        local remoteEvent = Instance.new("RemoteEvent")
        remoteEvent.Name = eventName
        remoteEvent.Parent = ReplicatedStorage
        self.remoteEvents[eventName] = remoteEvent
    end
    
    -- Set up event handlers
    self.remoteEvents.PlotSwitchRequest.OnServerEvent:Connect(function(player, targetTycoonId)
        self:HandlePlotSwitchRequest(player, targetTycoonId)
    end)
    
    print("MultiTycoonManager: Remote events configured!")
end

function MultiTycoonManager:ConnectPlayerEvents()
    -- Handle player joining
    Players.PlayerAdded:Connect(function(player)
        self:HandlePlayerJoined(player)
    end)
    
    -- Handle player leaving
    Players.PlayerRemoving:Connect(function(player)
        self:HandlePlayerLeaving(player)
    end)
    
    print("MultiTycoonManager: Player events connected!")
end

-- Core Multi-Tycoon Management Functions

function MultiTycoonManager:AddTycoonToPlayer(player, tycoonId)
    local startTime = self:StartPerformanceTimer()
    
    -- Enhanced validation
    if not self:ValidatePlayer(player) or not self:ValidateTycoonId(tycoonId) then
        return false
    end
    
    local userId = player.UserId
    local currentTycoons = self.playerTycoons[userId] or {}
    
    -- Check ownership limit
    if #currentTycoons >= Constants.MULTI_TYCOON.MAX_PLOTS_PER_PLAYER then
        warn("AddTycoonToPlayer: Player " .. player.Name .. " has reached the maximum number of tycoons!")
        return false
    end
    
    -- Check if player already owns this tycoon
    for _, existingId in ipairs(currentTycoons) do
        if existingId == tycoonId then
            warn("AddTycoonToPlayer: Player " .. player.Name .. " already owns tycoon " .. tycoonId)
            return false
        end
    end
    
    -- Add tycoon to player
    table.insert(currentTycoons, tycoonId)
    self.playerTycoons[userId] = currentTycoons
    
    -- Set as current tycoon if it's the first one
    if #currentTycoons == 1 then
        self.playerCurrentTycoon[userId] = tycoonId
    end
    
    -- Update cross-tycoon bonuses
    self:UpdateCrossTycoonBonuses(player)
    
    -- Sync data to client
    self:SyncPlayerData(player)
    
    self:EndPerformanceTimer(startTime, "AddTycoonToPlayer")
    print("MultiTycoonManager: Added tycoon " .. tycoonId .. " to player " .. player.Name)
    return true
end

function MultiTycoonManager:RemoveTycoonFromPlayer(player, tycoonId)
    local startTime = self:StartPerformanceTimer()
    
    -- Enhanced validation
    if not self:ValidatePlayer(player) or not self:ValidateTycoonId(tycoonId) then
        return false
    end
    
    local userId = player.UserId
    local currentTycoons = self.playerTycoons[userId] or {}
    
    -- Find and remove tycoon
    for i, existingId in ipairs(currentTycoons) do
        if existingId == tycoonId then
            table.remove(currentTycoons, i)
            break
        end
    end
    
    self.playerTycoons[userId] = currentTycoons
    
    -- Update current tycoon if needed
    if self.playerCurrentTycoon[userId] == tycoonId then
        if #currentTycoons > 0 then
            self.playerCurrentTycoon[userId] = currentTycoons[1]
        else
            self.playerCurrentTycoon[userId] = nil
        end
    end
    
    -- Update cross-tycoon bonuses
    self:UpdateCrossTycoonBonuses(player)
    
    -- Sync data to client
    self:SyncPlayerData(player)
    
    self:EndPerformanceTimer(startTime, "RemoveTycoonFromPlayer")
    print("MultiTycoonManager: Removed tycoon " .. tycoonId .. " from player " .. player.Name)
    return true
end

function MultiTycoonManager:SwitchPlayerToTycoon(player, tycoonId)
    local startTime = self:StartPerformanceTimer()
    
    -- Enhanced validation
    if not self:ValidatePlayer(player) or not self:ValidateTycoonId(tycoonId) then
        return false
    end
    
    local userId = player.UserId
    local currentTycoons = self.playerTycoons[userId] or {}
    
    -- Check if player owns this tycoon
    local ownsTycoon = false
    for _, existingId in ipairs(currentTycoons) do
        if existingId == tycoonId then
            ownsTycoon = true
            break
        end
    end
    
    if not ownsTycoon then
        warn("SwitchPlayerToTycoon: Player " .. player.Name .. " doesn't own tycoon " .. tycoonId)
        return false
    end
    
    -- Check cooldown
    if not self:CanPlayerSwitchPlots(player) then
        warn("SwitchPlayerToTycoon: Player " .. player.Name .. " is on cooldown")
        return false
    end
    
    -- Perform the switch
    local oldTycoonId = self.playerCurrentTycoon[userId]
    self.playerCurrentTycoon[userId] = tycoonId
    
    -- Set cooldown
    self:SetPlotSwitchCooldown(player)
    
    -- Preserve data during switch
    self:PreserveTycoonData(player, oldTycoonId)
    
    -- Sync to client
    self:SyncPlayerData(player)
    
    -- Broadcast update to all clients
    self:BroadcastPlayerUpdate(player, {
        type = "PlotSwitch",
        oldTycoonId = oldTycoonId,
        newTycoonId = tycoonId,
        playerName = player.Name
    })
    
    self:EndPerformanceTimer(startTime, "SwitchPlayerToTycoon")
    print("MultiTycoonManager: Player " .. player.Name .. " switched from tycoon " .. tostring(oldTycoonId) .. " to " .. tycoonId)
    return true
end

function MultiTycoonManager:GetPlayerTycoons(player)
    if not player then return {} end
    return self.playerTycoons[player.UserId] or {}
end

function MultiTycoonManager:GetPlayerCurrentTycoon(player)
    if not player then return nil end
    return self.playerCurrentTycoon[player.UserId]
end

function MultiTycoonManager:GetPlayerTycoonCount(player)
    if not player then return 0 end
    local tycoons = self.playerTycoons[player.UserId] or {}
    return #tycoons
end

-- Cross-Tycoon Bonus System

function MultiTycoonManager:UpdateCrossTycoonBonuses(player)
    if not player then return end
    
    local userId = player.UserId
    local tycoonCount = self:GetPlayerTycoonCount(player)
    
    -- Calculate bonuses based on Constants
    local cashBonus = math.min(
        Constants.ECONOMY.MULTI_TYCOON_CASH_BONUS * (tycoonCount - 1),
        Constants.ECONOMY.MAX_MULTI_TYCOON_BONUS
    )
    
    local abilityBonus = math.min(
        Constants.ECONOMY.MULTI_TYCOON_ABILITY_BONUS * (tycoonCount - 1),
        Constants.ECONOMY.MAX_MULTI_TYCOON_BONUS / 2
    )
    
    self.crossTycoonBonuses[userId] = {
        tycoonCount = tycoonCount,
        cashMultiplier = 1 + cashBonus,
        abilityCostReduction = abilityBonus,
        totalBonus = cashBonus + abilityBonus
    }
    
    -- Sync bonus data to client
    self:SendCrossTycoonBonusUpdate(player)
end

function MultiTycoonManager:GetCrossTycoonBonuses(player)
    if not player then return nil end
    return self.crossTycoonBonuses[player.UserId]
end

function MultiTycoonManager:CalculateCrossTycoonBonuses(player)
    local bonuses = self:GetCrossTycoonBonuses(player)
    if not bonuses then return 1, 0 end
    
    return bonuses.cashMultiplier, bonuses.abilityCostReduction
end

-- Plot Switching Cooldown System

function MultiTycoonManager:SetPlotSwitchCooldown(player)
    if not player then return end
    
    local userId = player.UserId
    self.plotSwitchingCooldowns[userId] = tick() + Constants.MULTI_TYCOON.PLOT_SWITCHING_COOLDOWN
    
    print("MultiTycoonManager: Set plot switch cooldown for " .. player.Name .. " until " .. self.plotSwitchingCooldowns[userId])
end

function MultiTycoonManager:CanPlayerSwitchPlots(player)
    if not player then return false end
    
    local userId = player.UserId
    local cooldownTime = self.plotSwitchingCooldowns[userId]
    
    if not cooldownTime then return true end
    
    return tick() >= cooldownTime
end

function MultiTycoonManager:GetPlotSwitchCooldownRemaining(player)
    if not player then return 0 end
    
    local userId = player.UserId
    local cooldownTime = self.plotSwitchingCooldowns[userId]
    
    if not cooldownTime then return 0 end
    
    local remaining = cooldownTime - tick()
    return math.max(0, remaining)
end

-- Data Synchronization

function MultiTycoonManager:SyncPlayerData(player)
    if not player then return end
    
    local userId = player.UserId
    local data = {
        ownedTycoons = self.playerTycoons[userId] or {},
        currentTycoon = self.playerCurrentTycoon[userId],
        crossTycoonBonuses = self.crossTycoonBonuses[userId],
        plotSwitchCooldown = self:GetPlotSwitchCooldownRemaining(player)
    }
    
    -- Send to client
    self.remoteEvents.MultiTycoonDataSync:FireClient(player, data)
    
    print("MultiTycoonManager: Synced data to " .. player.Name)
end

function MultiTycoonManager:BroadcastPlayerUpdate(player, data)
    if not player or not data then return end
    
    -- Send to all clients
    self.remoteEvents.PlayerTycoonUpdate:FireAllClients(data)
    
    print("MultiTycoonManager: Broadcasted update for " .. player.Name)
end

function MultiTycoonManager:SendCrossTycoonBonusUpdate(player)
    if not player then return end
    
    local bonuses = self:GetCrossTycoonBonuses(player)
    if not bonuses then return end
    
    self.remoteEvents.CrossTycoonBonusUpdate:FireClient(player, bonuses)
    
    print("MultiTycoonManager: Sent bonus update to " .. player.Name)
end

-- Event Handlers

function MultiTycoonManager:HandlePlayerJoined(player)
    -- Initialize player data
    self.playerTycoons[player.UserId] = {}
    self.playerCurrentTycoon[player.UserId] = nil
    self.plotSwitchingCooldowns[player.UserId] = nil
    
    print("MultiTycoonManager: Player " .. player.Name .. " joined, initialized data")
end

function MultiTycoonManager:HandlePlayerLeaving(player)
    local userId = player.UserId
    
    -- Clean up player data
    self.playerTycoons[userId] = nil
    self.playerCurrentTycoon[userId] = nil
    self.crossTycoonBonuses[userId] = nil
    self.plotSwitchingCooldowns[userId] = nil
    
    print("MultiTycoonManager: Player " .. player.Name .. " left, cleaned up data")
end

function MultiTycoonManager:HandlePlotSwitchRequest(player, targetTycoonId)
    print("MultiTycoonManager: Received plot switch request from " .. player.Name .. " to tycoon " .. targetTycoonId)
    
    local success = self:SwitchPlayerToTycoon(player, targetTycoonId)
    
    -- Send response to client
    self.remoteEvents.PlotSwitchResponse:FireClient(player, {
        success = success,
        targetTycoonId = targetTycoonId,
        cooldownRemaining = self:GetPlotSwitchCooldownRemaining(player)
    })
end

-- Data Preservation

function MultiTycoonManager:PreserveTycoonData(player, tycoonId)
    if not player or not tycoonId then return end
    
    local userId = player.UserId
    
    -- Create or update preserved data for this tycoon
    if not self.tycoonData[tycoonId] then
        self.tycoonData[tycoonId] = {}
    end
    
    -- Preserve essential tycoon state
    local preservedData = {
        lastActiveTime = tick(),
        playerId = userId,
        playerName = player.Name,
        -- These will be populated by other systems when they're available
        cash = 0,  -- Will be updated by economy system
        abilities = {},  -- Will be updated by progression system
        buildings = {},  -- Will be updated by building system
        upgrades = {},   -- Will be updated by upgrade system
        theme = "default",  -- Will be updated by theme system
        prestige = 1,    -- Will be updated by prestige system
        decorations = {} -- Will be updated by decoration system
    }
    
    -- Store the preserved data
    self.tycoonData[tycoonId] = preservedData
    
    -- Notify other systems to preserve their data
    self:NotifyDataPreservation(tycoonId, player)
    
    print("MultiTycoonManager: Preserved comprehensive data for tycoon " .. tycoonId .. " (player: " .. player.Name .. ")")
end

-- NEW: Notify other systems to preserve their data
function MultiTycoonManager:NotifyDataPreservation(tycoonId, player)
    if not tycoonId or not player then return end
    
    -- This function will be called by other systems to update preserved data
    -- For now, we'll set up the structure for future integration
    
    print("MultiTycoonManager: Notified data preservation for tycoon " .. tycoonId)
end

-- NEW: Update preserved data from other systems
function MultiTycoonManager:UpdatePreservedData(tycoonId, dataType, data)
    if not tycoonId or not dataType or not data then return end
    
    if not self.tycoonData[tycoonId] then
        self.tycoonData[tycoonId] = {}
    end
    
    self.tycoonData[tycoonId][dataType] = data
    self.tycoonData[tycoonId].lastUpdateTime = tick()
    
    print("MultiTycoonManager: Updated preserved data for tycoon " .. tycoonId .. " - " .. dataType)
end

-- NEW: Restore tycoon data when player returns
function MultiTycoonManager:RestoreTycoonData(player, tycoonId)
    if not player or not tycoonId then return nil end
    
    local preservedData = self.tycoonData[tycoonId]
    if not preservedData then
        print("MultiTycoonManager: No preserved data found for tycoon " .. tycoonId)
        return nil
    end
    
    -- Check if this is the player's own tycoon
    if preservedData.playerId ~= player.UserId then
        warn("MultiTycoonManager: Player " .. player.Name .. " attempted to restore data from tycoon " .. tycoonId .. " which they don't own")
        return nil
    end
    
    print("MultiTycoonManager: Restoring data for tycoon " .. tycoonId .. " (player: " .. player.Name .. ")")
    return preservedData
end

-- NEW: Get all preserved data for a player
function MultiTycoonManager:GetPlayerPreservedData(player)
    if not player then return {} end
    
    local userId = player.UserId
    local playerData = {}
    
    for tycoonId, data in pairs(self.tycoonData) do
        if data.playerId == userId then
            playerData[tycoonId] = data
        end
    end
    
    return playerData
end

-- NEW: Clean up old preserved data
function MultiTycoonManager:CleanupOldPreservedData()
    local currentTime = tick()
    local maxPreservationTime = Constants.MULTI_TYCOON.MAX_PRESERVATION_TIME or (7 * 24 * 60 * 60) -- 7 days default
    
    local cleanedCount = 0
    for tycoonId, data in pairs(self.tycoonData) do
        if data.lastActiveTime and (currentTime - data.lastActiveTime) > maxPreservationTime then
            self.tycoonData[tycoonId] = nil
            cleanedCount = cleanedCount + 1
        end
    end
    
    if cleanedCount > 0 then
        print("MultiTycoonManager: Cleaned up " .. cleanedCount .. " old preserved tycoon data entries")
    end
end

-- Utility Functions

function MultiTycoonManager:GetAllPlayerData()
    local allData = {}
    
    for userId, tycoons in pairs(self.playerTycoons) do
        local player = Players:GetPlayerByUserId(userId)
        if player then
            allData[player.Name] = {
                tycoons = tycoons,
                currentTycoon = self.playerCurrentTycoon[userId],
                bonuses = self.crossTycoonBonuses[userId]
            }
        end
    end
    
    return allData
end

function MultiTycoonManager:GetSystemStats()
    local totalPlayers = 0
    local totalTycoons = 0
    local playersWithMultipleTycoons = 0
    
    for userId, tycoons in pairs(self.playerTycoons) do
        totalPlayers = totalPlayers + 1
        totalTycoons = totalTycoons + #tycoons
        
        if #tycoons > 1 then
            playersWithMultipleTycoons = playersWithMultipleTycoons + 1
        end
    end
    
    return {
        totalPlayers = totalPlayers,
        totalTycoons = totalTycoons,
        playersWithMultipleTycoons = playersWithMultipleTycoons,
        averageTycoonsPerPlayer = totalPlayers > 0 and (totalTycoons / totalPlayers) or 0
    }
end

-- NEW: Enhanced error handling and validation
function MultiTycoonManager:ValidatePlayer(player)
    if not player then
        warn("MultiTycoonManager: Player parameter is nil")
        return false
    end
    
    if not player:IsDescendantOf(game) then
        warn("MultiTycoonManager: Player " .. tostring(player) .. " is not in the game")
        return false
    end
    
    if not player.UserId then
        warn("MultiTycoonManager: Player " .. tostring(player) .. " has no UserId")
        return false
    end
    
    return true
end

function MultiTycoonManager:ValidateTycoonId(tycoonId)
    if not tycoonId then
        warn("MultiTycoonManager: TycoonId parameter is nil")
        return false
    end
    
    if type(tycoonId) ~= "string" then
        warn("MultiTycoonManager: TycoonId must be a string, got " .. type(tycoonId))
        return false
    end
    
    if tycoonId == "" then
        warn("MultiTycoonManager: TycoonId cannot be empty")
        return false
    end
    
    return true
end

-- NEW: Performance monitoring
function MultiTycoonManager:StartPerformanceTimer()
    return tick()
end

function MultiTycoonManager:EndPerformanceTimer(startTime, operationName)
    if not startTime then return end
    
    local duration = tick() - startTime
    if duration > 0.1 then -- Log slow operations
        warn("MultiTycoonManager: " .. (operationName or "Operation") .. " took " .. string.format("%.3f", duration) .. " seconds")
    end
    
    return duration
end

-- NEW: Enhanced data integrity checks
function MultiTycoonManager:ValidateDataIntegrity()
    local issues = {}
    
    -- Check for orphaned data
    for userId, _ in pairs(self.playerTycoons) do
        local player = Players:GetPlayerByUserId(userId)
        if not player then
            table.insert(issues, "Orphaned player data for UserId: " .. userId)
        end
    end
    
    -- Check for data consistency
    for userId, tycoons in pairs(self.playerTycoons) do
        local currentTycoon = self.playerCurrentTycoon[userId]
        if currentTycoon then
            local hasCurrentTycoon = false
            for _, tycoonId in ipairs(tycoons) do
                if tycoonId == currentTycoon then
                    hasCurrentTycoon = true
                    break
                end
            end
            
            if not hasCurrentTycoon then
                table.insert(issues, "Player " .. userId .. " has current tycoon " .. currentTycoon .. " but doesn't own it")
            end
        end
    end
    
    -- Check for expired cooldowns
    local currentTime = tick()
    for userId, cooldownTime in pairs(self.plotSwitchingCooldowns) do
        if currentTime > cooldownTime then
            -- Clean up expired cooldown
            self.plotSwitchingCooldowns[userId] = nil
        end
    end
    
    if #issues > 0 then
        warn("MultiTycoonManager: Data integrity issues found:")
        for _, issue in ipairs(issues) do
            warn("  - " .. issue)
        end
    else
        print("MultiTycoonManager: Data integrity check passed")
    end
    
    return issues
end

-- NEW: Emergency recovery functions
function MultiTycoonManager:EmergencyRecovery(player)
    if not self:ValidatePlayer(player) then return false end
    
    local userId = player.UserId
    print("MultiTycoonManager: Performing emergency recovery for player " .. player.Name)
    
    -- Reset all player data to safe defaults
    self.playerTycoons[userId] = {}
    self.playerCurrentTycoon[userId] = nil
    self.crossTycoonBonuses[userId] = nil
    self.plotSwitchingCooldowns[userId] = nil
    
    -- Clear any preserved data for this player
    for tycoonId, data in pairs(self.tycoonData) do
        if data.playerId == userId then
            self.tycoonData[tycoonId] = nil
        end
    end
    
    -- Sync clean state to client
    self:SyncPlayerData(player)
    
    print("MultiTycoonManager: Emergency recovery completed for " .. player.Name)
    return true
end

-- NEW: Debug and diagnostic functions
function MultiTycoonManager:GetDebugInfo(player)
    if not self:ValidatePlayer(player) then return nil end
    
    local userId = player.UserId
    local debugInfo = {
        playerName = player.Name,
        userId = userId,
        ownedTycoons = self.playerTycoons[userId] or {},
        currentTycoon = self.playerCurrentTycoon[userId],
        crossTycoonBonuses = self.crossTycoonBonuses[userId],
        plotSwitchCooldown = self:GetPlotSwitchCooldownRemaining(player),
        preservedData = self:GetPlayerPreservedData(player),
        systemStats = self:GetSystemStats()
    }
    
    return debugInfo
end

function MultiTycoonManager:LogDebugInfo(player)
    local debugInfo = self:GetDebugInfo(player)
    if not debugInfo then return end
    
    print("=== MultiTycoonManager Debug Info for " .. player.Name .. " ===")
    for key, value in pairs(debugInfo) do
        if key ~= "systemStats" then
            print(key .. ": " .. tostring(value))
        end
    end
    
    if debugInfo.systemStats then
        print("=== System Stats ===")
        for key, value in pairs(debugInfo.systemStats) do
            print(key .. ": " .. tostring(value))
        end
    end
    print("==========================================")
end

-- Cleanup

function MultiTycoonManager:Cleanup()
    print("MultiTycoonManager: Starting cleanup...")
    
    -- Clean up maintenance connections
    if self.maintenanceConnections then
        for name, connection in pairs(self.maintenanceConnections) do
            if connection and typeof(connection) == "RBXScriptConnection" then
                connection:Disconnect()
                print("MultiTycoonManager: Disconnected maintenance connection: " .. name)
            end
        end
        self.maintenanceConnections = {}
    end
    
    -- Clean up remote events
    for _, remoteEvent in pairs(self.remoteEvents) do
        if remoteEvent and remoteEvent.Parent then
            remoteEvent:Destroy()
        end
    end
    
    -- Clear data
    self.playerTycoons = {}
    self.tycoonData = {}
    self.crossTycoonBonuses = {}
    self.plotSwitchingCooldowns = {}
    self.playerCurrentTycoon = {}
    
    -- Clear timers
    self.lastIntegrityCheck = nil
    self.lastCleanup = nil
    
    print("MultiTycoonManager: Cleaned up successfully!")
end

return MultiTycoonManager
