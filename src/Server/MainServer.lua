-- MainServer.lua
-- Main server script for Milestone 0: Single tycoon prototype

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(script.Parent.Parent.Utils.Constants)
local HelperFunctions = require(script.Parent.Parent.Utils.HelperFunctions)
local PlayerController = require(script.Parent.Parent.Player.PlayerController)
local TycoonBase = require(script.Parent.Parent.Tycoon.TycoonBase)
local SaveSystem = require(script.Parent.SaveSystem)

local MainServer = {}

-- Create RemoteEvents for client-server communication
local RemoteEvents = Instance.new("Folder")
RemoteEvents.Name = "RemoteEvents"
RemoteEvents.Parent = ReplicatedStorage

local UpdatePlayerDataEvent = Instance.new("RemoteEvent")
UpdatePlayerDataEvent.Name = "UpdatePlayerData"
UpdatePlayerDataEvent.Parent = RemoteEvents

local UpdateTycoonDataEvent = Instance.new("RemoteEvent")
UpdateTycoonDataEvent.Name = "UpdateTycoonData"
UpdateTycoonDataEvent.Parent = RemoteEvents

local RequestPlayerDataEvent = Instance.new("RemoteEvent")
RequestPlayerDataEvent.Name = "RequestPlayerData"
RequestPlayerDataEvent.Parent = RemoteEvents

-- Game state
local gameState = {
    isInitialized = false,
    tycoons = {},
    nextTycoonId = 1,
    saveInterval = Constants.SAVE.AUTO_SAVE_INTERVAL,
    lastSave = tick()
}

-- Initialize the game
function MainServer:Initialize()
    if gameState.isInitialized then return end
    
    print("Initializing Roblox Tycoon Game...")
    
    -- Create the first tycoon (Naruto-themed for now)
    self:CreateFirstTycoon()
    
    -- Set up save system
    self:SetupSaveSystem()
    
    -- Set up player management
    self:SetupPlayerManagement()
    
    gameState.isInitialized = true
    print("Game initialized successfully!")
end

-- Create the first tycoon
function MainServer:CreateFirstTycoon()
    local tycoonId = "tycoon_" .. gameState.nextTycoonId
    local tycoonPosition = Vector3.new(0, 0, 0)
    
    -- Create tycoon without owner initially
    local tycoon = TycoonBase.new(tycoonId, tycoonPosition, nil)
    
    if tycoon then
        gameState.tycoons[tycoonId] = tycoon
        gameState.nextTycoonId = gameState.nextTycoonId + 1
        
        print("Created first tycoon: " .. tycoonId)
        
        -- Activate the tycoon
        tycoon:Activate()
    else
        warn("Failed to create first tycoon!")
    end
end

-- Setup save system
function MainServer:SetupSaveSystem()
    -- Initialize save system
    SaveSystem:Initialize()
    
    -- Set up auto-save
    RunService.Heartbeat:Connect(function()
        self:UpdateSaveSystem()
    end)
end

-- Update save system (auto-save)
function MainServer:UpdateSaveSystem()
    local currentTime = tick()
    local timeSinceLastSave = currentTime - gameState.lastSave
    
    if timeSinceLastSave >= gameState.saveInterval then
        self:SaveAllData()
        gameState.lastSave = currentTime
    end
end

-- Save all game data
function MainServer:SaveAllData()
    print("Auto-saving game data...")
    
    -- Save player data
    for _, player in ipairs(Players:GetPlayers()) do
        local playerController = PlayerController.GetPlayerController(player)
        if playerController then
            local playerData = playerController:GetPlayerData()
            if playerData then
                SaveSystem:SavePlayerData(player.UserId, playerData:GetAllData())
            end
        end
    end
    
    -- Save tycoon data
    for tycoonId, tycoon in pairs(gameState.tycoons) do
        local tycoonData = tycoon:GetData()
        SaveSystem:SaveTycoonData(tycoonId, tycoonData)
    end
    
    print("Game data saved successfully!")
end

-- Setup player management
function MainServer:SetupPlayerManagement()
    -- Handle new players joining
    Players.PlayerAdded:Connect(function(player)
        self:OnPlayerJoined(player)
    end)
    
    -- Handle players leaving
    Players.PlayerRemoving:Connect(function(player)
        self:OnPlayerLeft(player)
    end)
    
    -- Handle existing players
    for _, player in ipairs(Players:GetPlayers()) do
        self:OnPlayerJoined(player)
    end
    
    -- Set up client request handling
    self:SetupClientRequests()
end

-- Setup client request handling
function MainServer:SetupClientRequests()
    -- Handle player data requests
    RequestPlayerDataEvent.OnServerEvent:Connect(function(player)
        self:SendPlayerDataToClient(player)
    end)
    
    -- Send periodic updates to all clients
    RunService.Heartbeat:Connect(function()
        self:UpdateAllClients()
    end)
end

-- Send player data to a specific client
function MainServer:SendPlayerDataToClient(player)
    local playerController = PlayerController.GetPlayerController(player)
    if not playerController then return end
    
    local playerData = playerController:GetPlayerData()
    if not playerData then return end
    
    local dataToSend = {
        Cash = playerData:GetCash(),
        Abilities = playerData:GetAllAbilities(),
        CurrentTycoon = playerData:GetCurrentTycoon(),
        Level = playerData:GetLevel(),
        Experience = playerData:GetExperience()
    }
    
    UpdatePlayerDataEvent:FireClient(player, dataToSend)
end

-- Send tycoon data to a specific client
function MainServer:SendTycoonDataToClient(player, tycoonId)
    local tycoon = gameState.tycoons[tycoonId]
    if not tycoon then return end
    
    local dataToSend = {
        TycoonId = tycoonId,
        Owner = tycoon:GetOwner() and tycoon:GetOwner().Name or "None",
        Level = tycoon:GetLevel(),
        CashGenerated = tycoon:GetCashGenerated(),
        IsActive = tycoon:IsActive()
    }
    
    UpdateTycoonDataEvent:FireClient(player, dataToSend)
end

-- Update all clients with current data
function MainServer:UpdateAllClients()
    for _, player in ipairs(Players:GetPlayers()) do
        self:SendPlayerDataToClient(player)
        
        local playerController = PlayerController.GetPlayerController(player)
        if playerController then
            local playerData = playerController:GetPlayerData()
            if playerData then
                local currentTycoonId = playerData:GetCurrentTycoon()
                if currentTycoonId then
                    self:SendTycoonDataToClient(player, currentTycoonId)
                end
            end
        end
    end
end

-- Handle player joining
function MainServer:OnPlayerJoined(player)
    print("Player joined: " .. player.Name)
    
    -- Wait for player to load
    player.CharacterAdded:Wait()
    
    -- Load player data
    self:LoadPlayerData(player)
    
    -- Assign tycoon if they don't have one
    self:AssignTycoonToPlayer(player)
    
    -- Show tycoon UI
    self:ShowTycoonUI(player)
    
    print("Player " .. player.Name .. " setup complete")
end

-- Handle player leaving
function MainServer:OnPlayerLeft(player)
    print("Player left: " .. player.Name)
    
    -- Save player data before they leave
    local playerController = PlayerController.GetPlayerController(player)
    if playerController then
        local playerData = playerController:GetPlayerData()
        if playerData then
            SaveSystem:SavePlayerData(player.UserId, playerData:GetAllData())
        end
    end
    
    -- Hide tycoon UI
    self:HideTycoonUI(player)
end

-- Load player data
function MainServer:LoadPlayerData(player)
    local playerController = PlayerController.GetPlayerController(player)
    if not playerController then return end
    
    local playerData = playerController:GetPlayerData()
    if not playerData then return end
    
    -- Load from save system
    local savedData = SaveSystem:LoadPlayerData(player.UserId)
    if savedData then
        playerData:LoadData(savedData)
        print("Loaded data for player: " .. player.Name)
    else
        print("No saved data found for player: " .. player.Name .. ", using defaults")
    end
end

-- Assign tycoon to player
function MainServer:AssignTycoonToPlayer(player)
    local playerController = PlayerController.GetPlayerController(player)
    if not playerController then return end
    
    local playerData = playerController:GetPlayerData()
    if not playerData then return end
    
    -- Check if player already owns a tycoon
    local ownedTycoons = playerData:GetOwnedTycoons()
    if #ownedTycoons > 0 then
        -- Player already owns a tycoon, set it as current
        local currentTycoonId = ownedTycoons[1]
        playerData:SetCurrentTycoon(currentTycoonId)
        
        -- Set player as owner of the tycoon
        local tycoon = gameState.tycoons[currentTycoonId]
        if tycoon then
            tycoon:SetOwner(player)
        end
        
        print("Player " .. player.Name .. " assigned to existing tycoon: " .. currentTycoonId)
        return
    end
    
    -- Find an unowned tycoon
    for tycoonId, tycoon in pairs(gameState.tycoons) do
        if not tycoon:GetOwner() then
            -- Assign this tycoon to the player
            tycoon:SetOwner(player)
            playerData:AddTycoonOwnership(tycoonId)
            playerData:SetCurrentTycoon(tycoonId)
            
            print("Player " .. player.Name .. " assigned to tycoon: " .. tycoonId)
            return
        end
    end
    
    -- No unowned tycoons available
    print("No unowned tycoons available for player: " .. player.Name)
end

-- Show tycoon UI for player
function MainServer:ShowTycoonUI(player)
    local playerController = PlayerController.GetPlayerController(player)
    if not playerController then return end
    
    local playerData = playerController:GetPlayerData()
    if not playerData then return end
    
    local currentTycoonId = playerData:GetCurrentTycoon()
    if not currentTycoonId then return end
    
    local tycoon = gameState.tycoons[currentTycoonId]
    if tycoon then
        tycoon:ShowUI(player)
    end
end

-- Hide tycoon UI for player
function MainServer:HideTycoonUI(player)
    local playerController = PlayerController.GetPlayerController(player)
    if not playerController then return end
    
    local playerData = playerController:GetPlayerData()
    if not playerData then return end
    
    local currentTycoonId = playerData:GetCurrentTycoon()
    if not currentTycoonId then return end
    
    local tycoon = gameState.tycoons[currentTycoonId]
    if tycoon then
        tycoon:HideUI(player)
    end
end

-- Get tycoon by ID
function MainServer:GetTycoon(tycoonId)
    return gameState.tycoons[tycoonId]
end

-- Get all tycoons
function MainServer:GetAllTycoons()
    return table.clone(gameState.tycoons)
end

-- Create new tycoon
function MainServer:CreateTycoon(position, owner)
    local tycoonId = "tycoon_" .. gameState.nextTycoonId
    local tycoon = TycoonBase.new(tycoonId, position, owner)
    
    if tycoon then
        gameState.tycoons[tycoonId] = tycoon
        gameState.nextTycoonId = gameState.nextTycoonId + 1
        
        -- Activate the tycoon
        tycoon:Activate()
        
        print("Created new tycoon: " .. tycoonId)
        return tycoon
    end
    
    return nil
end

-- Remove tycoon
function MainServer:RemoveTycoon(tycoonId)
    local tycoon = gameState.tycoons[tycoonId]
    if tycoon then
        tycoon:Destroy()
        gameState.tycoons[tycoonId] = nil
        print("Removed tycoon: " .. tycoonId)
        return true
    end
    return false
end

-- Get game state
function MainServer:GetGameState()
    return table.clone(gameState)
end

-- Clean up game
function MainServer:Cleanup()
    print("Cleaning up game...")
    
    -- Save all data
    self:SaveAllData()
    
    -- Clean up tycoons
    for tycoonId, tycoon in pairs(gameState.tycoons) do
        tycoon:Destroy()
    end
    gameState.tycoons = {}
    
    -- Clean up player controllers
    PlayerController.CleanupAll()
    
    -- Clean up save system
    SaveSystem:Cleanup()
    
    gameState.isInitialized = false
    print("Game cleanup complete")
end

-- Initialize the game when the script runs
MainServer:Initialize()

-- Clean up when the game shuts down
game:BindToClose(function()
    MainServer:Cleanup()
end)

return MainServer
