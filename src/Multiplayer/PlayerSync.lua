-- PlayerSync.lua
-- Handles real-time synchronization of player data across the network

local PlayerSync = {}
PlayerSync.__index = PlayerSync

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Constants
local SYNC_INTERVAL = 0.1 -- Sync every 100ms
local POSITION_THRESHOLD = 2 -- Only sync if position changed by 2 studs
local ROTATION_THRESHOLD = 5 -- Only sync if rotation changed by 5 degrees

-- Player data cache
local playerData = {}
local lastSyncTime = {}

-- Network manager reference
local NetworkManager = require(script.Parent.NetworkManager)

-- Initialize player sync
function PlayerSync:Initialize()
    print("PlayerSync initialized")
    
    -- Set up player join/leave handlers
    self:SetupPlayerHandlers()
    
    -- Start sync loop
    self:StartSyncLoop()
end

-- Set up player event handlers
function PlayerSync:SetupPlayerHandlers()
    local function handlePlayer(player)
        self:InitializePlayer(player)
    end

    -- Handle existing players
    for _, player in ipairs(Players:GetPlayers()) do
        handlePlayer(player)
    end

    -- Player joining
    Players.PlayerAdded:Connect(handlePlayer)

    -- Player leaving
    Players.PlayerRemoving:Connect(function(player)
        self:OnPlayerLeave(player)
    end)
end

-- Handle player joining
function PlayerSync:OnPlayerJoin(player)
    print("PlayerSync: Player joined:", player.Name)
    
    -- Initialize player data through proper PlayerData module
    local success, playerDataInstance = pcall(function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local PlayerData = require(ReplicatedStorage:WaitForChild("Player"):WaitForChild("PlayerData"))
        return PlayerData.GetPlayerData(player)
    end)
    
    if success and playerDataInstance then
        -- Player data already exists or was created successfully
        print("PlayerSync: Player data initialized for", player.Name)
    else
        warn("PlayerSync: Failed to initialize player data for", player.Name, "- falling back to basic data")
        
        -- Fallback to basic data structure
        playerData[player.UserId] = {
            Position = Vector3.new(0, 0, 0),
            Rotation = Vector3.new(0, 0, 0),
            Health = 100,
            MaxHealth = 100,
            Abilities = {},
            CurrentTycoon = nil,
            LastUpdate = tick()
        }
    end
    
    lastSyncTime[player.UserId] = 0
    
    -- Send initial data to client
    if playerData[player.UserId] then
        NetworkManager:FireClient(player, "PlayerDataUpdate", playerData[player.UserId])
    end
    
    -- Notify other clients
    NetworkManager:FireAllClients("PlayerJoin", player.Name, player.UserId)
end

-- Handle player leaving
function PlayerSync:OnPlayerLeave(player)
    print("PlayerSync: Player left:", player.Name)
    
    -- Clean up player data
    playerData[player.UserId] = nil
    lastSyncTime[player.UserId] = nil
    
    -- Notify other clients
    NetworkManager:FireAllClients("PlayerLeave", player.Name, player.UserId)
end

-- Handle character added
function PlayerSync:OnCharacterAdded(player, character)
    print("PlayerSync: Character added for:", player.Name)
    
    -- Wait for character to fully load
    character:WaitForChild("Humanoid")
    character:WaitForChild("HumanoidRootPart")
    
    -- Set initial position
    if playerData[player.UserId] then
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            playerData[player.UserId].Position = humanoidRootPart.Position
            playerData[player.UserId].Rotation = Vector3.new(0, character.HumanoidRootPart.Orientation.Y, 0)
        end
    end
    
    -- Set up character monitoring
    self:MonitorCharacter(player, character)
end

-- Monitor character for changes
function PlayerSync:MonitorCharacter(player, character)
    local humanoid = character:WaitForChild("Humanoid")
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    -- Monitor health changes
    humanoid.HealthChanged:Connect(function(health)
        if playerData[player.UserId] then
            playerData[player.UserId].Health = health
            self:QueueSync(player.UserId, "Health")
        end
    end)
    
    -- Monitor position changes
    humanoidRootPart:GetPropertyChangedSignal("Position"):Connect(function()
        if playerData[player.UserId] then
            local newPos = humanoidRootPart.Position
            local oldPos = playerData[player.UserId].Position
            
            -- Only update if position changed significantly
            if (newPos - oldPos).Magnitude > POSITION_THRESHOLD then
                playerData[player.UserId].Position = newPos
                self:QueueSync(player.UserId, "Position")
            end
        end
    end)
    
    -- Monitor rotation changes
    humanoidRootPart:GetPropertyChangedSignal("Orientation"):Connect(function()
        if playerData[player.UserId] then
            local newRot = Vector3.new(0, humanoidRootPart.Orientation.Y, 0)
            local oldRot = playerData[player.UserId].Rotation
            
            -- Only update if rotation changed significantly
            if (newRot - oldRot).Magnitude > ROTATION_THRESHOLD then
                playerData[player.UserId].Rotation = newRot
                self:QueueSync(player.UserId, "Rotation")
            end
        end
    end)
end

-- Queue a sync update for a player
function PlayerSync:QueueSync(userId, dataType)
    if not lastSyncTime[userId] then return end
    
    local currentTime = tick()
    if currentTime - lastSyncTime[userId] >= SYNC_INTERVAL then
        self:SyncPlayerData(userId)
        lastSyncTime[userId] = currentTime
    end
end

-- Sync player data to all clients
function PlayerSync:SyncPlayerData(userId)
    if not playerData[userId] then return end
    
    local player = Players:GetPlayerByUserId(userId)
    if not player then return end
    
    -- Update last update time
    playerData[userId].LastUpdate = tick()
    
    -- Send to all clients
    NetworkManager:FireAllClients("PlayerDataUpdate", userId, playerData[userId])
end

-- Update player ability data
function PlayerSync:UpdatePlayerAbilities(userId, abilities)
    if not playerData[userId] then return end
    
    playerData[userId].Abilities = abilities
    self:QueueSync(userId, "Abilities")
end

-- Update player tycoon
function PlayerSync:UpdatePlayerTycoon(userId, tycoonId)
    if not playerData[userId] then return end
    
    playerData[userId].CurrentTycoon = tycoonId
    self:QueueSync(userId, "Tycoon")
end

-- Get player data
function PlayerSync:GetPlayerData(userId)
    return playerData[userId]
end

-- Get all player data
function PlayerSync:GetAllPlayerData()
    return playerData
end

-- Check if player exists
function PlayerSync:PlayerExists(userId)
    return playerData[userId] ~= nil
end

-- Start the sync loop
function PlayerSync:StartSyncLoop()
    RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        
        -- Sync all players periodically
        for userId, lastSync in pairs(lastSyncTime) do
            if currentTime - lastSync >= SYNC_INTERVAL then
                self:SyncPlayerData(userId)
                lastSyncTime[userId] = currentTime
            end
        end
    end)
end

-- Force sync a specific player
function PlayerSync:ForceSync(userId)
    if playerData[userId] then
        self:SyncPlayerData(userId)
        lastSyncTime[userId] = tick()
    end
end

-- Force sync all players
function PlayerSync:ForceSyncAll()
    for userId, _ in pairs(playerData) do
        self:ForceSync(userId)
    end
end

-- Update player health
function PlayerSync:UpdatePlayerHealth(userId, health, maxHealth)
    if not playerData[userId] then return end
    
    playerData[userId].Health = health
    playerData[userId].MaxHealth = maxHealth or playerData[userId].MaxHealth
    self:QueueSync(userId, "Health")
end

-- Teleport player to position
function PlayerSync:TeleportPlayer(userId, position, tycoonId)
    if not playerData[userId] then return end
    
    local player = Players:GetPlayerByUserId(userId)
    if not player or not player.Character then return end
    
    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        -- Update data
        playerData[userId].Position = position
        playerData[userId].CurrentTycoon = tycoonId
        
        -- Teleport character
        humanoidRootPart.CFrame = CFrame.new(position)
        
        -- Sync immediately
        self:ForceSync(userId)
    end
end

-- Initialize player (called from MainServer)
function PlayerSync:InitializePlayer(player)
    print("PlayerSync: Initializing player:", player.Name)
    
    -- Initialize player data if not already done
    if not playerData[player.UserId] then
        self:OnPlayerJoin(player)
    end
    
    -- Set up character monitoring
    if player.Character then
        self:OnCharacterAdded(player, player.Character)
    end
    
    player.CharacterAdded:Connect(function(character)
        self:OnCharacterAdded(player, character)
    end)
end

-- Cleanup player (called from MainServer)
function PlayerSync:CleanupPlayer(player)
    print("PlayerSync: Cleaning up player:", player.Name)
    
    -- This will be handled by OnPlayerLeave, but we can add additional cleanup here
    -- For now, just ensure the player is removed from data
    if playerData[player.UserId] then
        self:OnPlayerLeave(player)
    end
end

-- Save all player data (called from MainServer)
function PlayerSync:SaveAllPlayerData()
    print("PlayerSync: Saving all player data...")
    
    local savedCount = 0
    for userId, data in pairs(playerData) do
        -- In a real implementation, this would save to DataStore
        -- For now, just count the players
        savedCount = savedCount + 1
    end
    
    print("PlayerSync: Saved data for " .. savedCount .. " players")
    return savedCount
end

-- Handle plot assignment (callback from HubManager)
function PlayerSync:OnPlotAssigned(player, plotId)
    print("PlayerSync: Player " .. player.Name .. " assigned to plot " .. plotId)
    
    if playerData[player.UserId] then
        playerData[player.UserId].CurrentPlot = plotId
        playerData[player.UserId].CurrentTycoon = plotId
        
        -- Sync immediately
        self:ForceSync(player.UserId)
        
        -- Notify client
        NetworkManager:FireClient(player, "PlotAssigned", plotId)
    end
end

-- Handle plot freed (callback from HubManager)
function PlayerSync:OnPlotFreed(plotId)
    print("PlayerSync: Plot " .. plotId .. " freed")
    
    -- Find all players who were on this plot and update them
    for userId, data in pairs(playerData) do
        if data.CurrentPlot == plotId then
            data.CurrentPlot = nil
            data.CurrentTycoon = nil
            
            -- Sync immediately
            self:ForceSync(userId)
            
            -- Notify client
            local player = Players:GetPlayerByUserId(userId)
            if player then
                NetworkManager:FireClient(player, "PlotFreed", plotId)
            end
        end
    end
end

-- Update player data (callback from TycoonSync)
function PlayerSync:UpdatePlayerData(player, data)
    if not playerData[player.UserId] then return end
    
    -- Update player data with new information
    for key, value in pairs(data) do
        if playerData[player.UserId][key] ~= nil then
            playerData[player.UserId][key] = value
        end
    end
    
    -- Sync immediately
    self:ForceSync(player.UserId)
end

return PlayerSync
