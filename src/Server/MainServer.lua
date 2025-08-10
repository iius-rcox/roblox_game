-- MainServer.lua
-- Main server script for Milestone 1: Multiplayer Hub with Plot System

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(script.Parent.Parent.Utils.Constants)
local HelperFunctions = require(script.Parent.Parent.Utils.HelperFunctions)
local PlayerController = require(script.Parent.Parent.Player.PlayerController)
local SaveSystem = require(script.Parent.SaveSystem)

-- New Hub and Multiplayer systems
local HubManager = require(script.Parent.Parent.Hub.HubManager)
local NetworkManager = require(script.Parent.Parent.Multiplayer.NetworkManager)
local PlayerSync = require(script.Parent.Parent.Multiplayer.PlayerSync)
local TycoonSync = require(script.Parent.Parent.Multiplayer.TycoonSync)

local MainServer = {}

-- Game state for Milestone 1
local gameState = {
    isInitialized = false,
    hubManager = nil,
    networkManager = nil,
    playerSync = nil,
    tycoonSync = nil,
    saveInterval = Constants.SAVE.AUTO_SAVE_INTERVAL,
    lastSave = tick()
}

-- Initialize the game
function MainServer:Initialize()
    if gameState.isInitialized then return end
    
    print("Initializing Roblox Tycoon Game - Milestone 1: Multiplayer Hub...")
    
    -- Initialize save system FIRST (NEW: Required for HubManager)
    self:SetupSaveSystem()
    
    -- Initialize multiplayer systems
    self:InitializeMultiplayerSystems()
    
    -- Initialize hub system (after SaveSystem is ready)
    self:InitializeHubSystem()
    
    -- Set up player management
    self:SetupPlayerManagement()
    
    -- Set up cross-system integration
    self:SetupSystemIntegration()
    
    gameState.isInitialized = true
    print("Milestone 1 game initialized successfully!")
end

-- Initialize multiplayer systems
function MainServer:InitializeMultiplayerSystems()
    print("Initializing multiplayer systems...")
    
    -- Initialize NetworkManager
    gameState.networkManager = NetworkManager
    gameState.networkManager:Initialize()
    
    -- Initialize PlayerSync
    gameState.playerSync = PlayerSync
    gameState.playerSync:Initialize()
    
    -- Initialize TycoonSync
    gameState.tycoonSync = TycoonSync
    gameState.tycoonSync:Initialize()
    
    print("Multiplayer systems initialized successfully!")
end

-- Initialize hub system
function MainServer:InitializeHubSystem()
    print("Initializing hub system...")
    
    -- HubManager is auto-initialized when required
    gameState.hubManager = HubManager
    
    print("Hub system initialized successfully!")
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
    print("Auto-saving all game data...")
    
    -- Save player data through PlayerSync
    if gameState.playerSync then
        gameState.playerSync:SaveAllPlayerData()
    end
    
    -- Save tycoon data through TycoonSync
    if gameState.tycoonSync then
        gameState.tycoonSync:SaveAllTycoonData()
    end
    
    -- Save hub data through HubManager
    if gameState.hubManager then
        gameState.hubManager:SaveHubData()
    end
    
    print("Auto-save completed!")
end

-- Setup player management
function MainServer:SetupPlayerManagement()
    print("Setting up player management...")
    
    -- Handle players joining
    Players.PlayerAdded:Connect(function(player)
        self:HandlePlayerJoined(player)
    end)
    
    -- Handle players leaving
    Players.PlayerRemoving:Connect(function(player)
        self:HandlePlayerLeft(player)
    end)
    
    -- Handle existing players
    for _, player in ipairs(Players:GetPlayers()) do
        self:HandlePlayerJoined(player)
    end
end

-- Handle player joining
function MainServer:HandlePlayerJoined(player)
    print("MainServer: Player " .. player.Name .. " joined the game")
    
    -- Initialize player through PlayerSync
    if gameState.playerSync then
        gameState.playerSync:InitializePlayer(player)
    end
    
    -- Player will be handled by HubManager for spawning and plot assignment
    print("MainServer: Player " .. player.Name .. " initialized successfully")
end

-- Handle player leaving
function MainServer:HandlePlayerLeft(player)
    print("MainServer: Player " .. player.Name .. " left the game")
    
    -- Clean up player data through PlayerSync
    if gameState.playerSync then
        gameState.playerSync:CleanupPlayer(player)
    end
    
    -- HubManager will handle plot cleanup
    print("MainServer: Player " .. player.Name .. " cleaned up successfully")
end

-- Setup system integration
function MainServer:SetupSystemIntegration()
    print("Setting up system integration...")
    
    -- Connect HubManager with PlayerSync
    if gameState.hubManager and gameState.playerSync then
        -- Set up callbacks for plot assignment
        gameState.hubManager.OnPlotAssigned = function(player, plotId)
            gameState.playerSync:OnPlotAssigned(player, plotId)
        end
        
        gameState.hubManager.OnPlotFreed = function(plotId)
            gameState.playerSync:OnPlotFreed(plotId)
        end
    end
    
    -- Connect TycoonSync with PlayerSync
    if gameState.tycoonSync and gameState.playerSync then
        gameState.tycoonSync.OnPlayerDataUpdate = function(player, data)
            gameState.playerSync:UpdatePlayerData(player, data)
        end
    end
    
    print("System integration completed!")
end

-- Get game state info
function MainServer:GetGameState()
    return {
        isInitialized = gameState.isInitialized,
        hubActive = gameState.hubManager ~= nil,
        networkActive = gameState.networkManager ~= nil,
        playerCount = #Players:GetPlayers(),
        plotCount = gameState.hubManager and gameState.hubManager:GetAllPlots() and #gameState.hubManager:GetAllPlots() or 0
    }
end

-- Initialize when the script runs
MainServer:Initialize()

-- Return the MainServer for external use
return MainServer
