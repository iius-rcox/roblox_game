-- MainServer.lua
-- Main server script for Milestone 3: Advanced Competitive & Social Systems
-- Enhanced with Roblox best practices for performance and memory management

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(script.Parent.Parent.Utils.Constants)
local HelperFunctions = require(script.Parent.Parent.Utils.HelperFunctions)
local PlayerController = require(script.Parent.Parent.Player.PlayerController)
local SaveSystem = require(script.Parent.SaveSystem)

-- Milestone 1: Hub and Multiplayer systems
local HubManager = require(script.Parent.Parent.Hub.HubManager)
local NetworkManager = require(script.Parent.Parent.Multiplayer.NetworkManager)
local PlayerSync = require(script.Parent.Parent.Multiplayer.PlayerSync)
local TycoonSync = require(script.Parent.Parent.Multiplayer.TycoonSync)

-- Milestone 2: Multiple Tycoon Ownership systems
local MultiTycoonManager = require(script.Parent.Parent.Multiplayer.MultiTycoonManager)
local CrossTycoonProgression = require(script.Parent.Parent.Multiplayer.CrossTycoonProgression)
local AdvancedPlotSystem = require(script.Parent.Parent.Hub.AdvancedPlotSystem)

-- NEW: Milestone 3: Advanced Competitive & Social Systems
local CompetitiveManager = require(script.Parent.Parent.Competitive.CompetitiveManager)
local GuildSystem = require(script.Parent.Parent.Competitive.GuildSystem)
local TradingSystem = require(script.Parent.Parent.Competitive.TradingSystem)
local SocialSystem = require(script.Parent.Parent.Competitive.SocialSystem)
local SecurityManager = require(script.Parent.Parent.Competitive.SecurityManager)

-- NEW: Memory category tagging for better memory tracking (Roblox best practice)
debug.setmemorycategory("MainServer")

local MainServer = {}

-- NEW: Enhanced game state with performance monitoring (Roblox best practice)
local gameState = {
    isInitialized = false,
    startTime = tick(),
    -- Milestone 1 systems
    hubManager = nil,
    networkManager = nil,
    playerSync = nil,
    tycoonSync = nil,
    -- Milestone 2 systems
    multiTycoonManager = nil,
    crossTycoonProgression = nil,
    advancedPlotSystem = nil,
    -- NEW: Milestone 3 systems
    competitiveManager = nil,
    guildSystem = nil,
    tradingSystem = nil,
    socialSystem = nil,
    securityManager = nil,
    saveInterval = Constants.SAVE.AUTO_SAVE_INTERVAL,
    lastSave = tick(),
    -- NEW: Performance monitoring
    performanceMetrics = {
        lastUpdate = 0,
        updateInterval = 1, -- Update every second instead of every frame
        systemHealth = 100,
        memoryUsage = 0,
        activeConnections = 0,
        playerCount = 0
    }
}

-- NEW: Connection tracking for proper cleanup (Roblox best practice)
local connections = {}

-- NEW: Error handling wrapper (Roblox best practice)
function MainServer:SafeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        warn("MainServer error in", debug.traceback(), ":", result)
        return nil
    end
    return result
end

-- NEW: Performance monitoring method (Roblox best practice)
function MainServer:UpdatePerformanceMetrics()
    local currentTime = tick()
    local timeSinceLastUpdate = currentTime - gameState.performanceMetrics.lastUpdate
    
    if timeSinceLastUpdate >= gameState.performanceMetrics.updateInterval then
        -- Count active connections
        local connectionCount = 0
        for _, connection in pairs(connections) do
            if connection and typeof(connection) == "RBXScriptConnection" then
                connectionCount = connectionCount + 1
            end
        end
        gameState.performanceMetrics.activeConnections = connectionCount
        
        -- Update player count
        gameState.performanceMetrics.playerCount = #Players:GetPlayers()
        
        -- Update system health based on performance
        if connectionCount > 100 then
            gameState.performanceMetrics.systemHealth = math.max(0, gameState.performanceMetrics.systemHealth - 5)
        elseif connectionCount < 50 then
            gameState.performanceMetrics.systemHealth = math.min(100, gameState.performanceMetrics.systemHealth + 1)
        end
        
        gameState.performanceMetrics.lastUpdate = currentTime
    end
end

-- Initialize the game
function MainServer:Initialize()
    if gameState.isInitialized then return end
    
    print("Initializing Roblox Tycoon Game - Milestone 3: Advanced Competitive & Social Systems...")
    
    -- NEW: Performance monitoring start (Roblox best practice)
    gameState.performanceMetrics.lastUpdate = tick()
    
    -- Initialize save system FIRST (Required for HubManager)
    self:SafeCall(function()
        self:SetupSaveSystem()
    end)
    
    -- Initialize multiplayer systems
    self:SafeCall(function()
        self:InitializeMultiplayerSystems()
    end)
    
    -- Initialize hub system (after SaveSystem is ready)
    self:SafeCall(function()
        self:InitializeHubSystem()
    end)
    
    -- Initialize Milestone 2 systems
    self:SafeCall(function()
        self:InitializeMilestone2Systems()
    end)
    
    -- NEW: Initialize Milestone 3 systems
    self:SafeCall(function()
        self:InitializeMilestone3Systems()
    end)
    
    -- Set up player management
    self:SafeCall(function()
        self:SetupPlayerManagement()
    end)
    
    -- Set up cross-system integration
    self:SafeCall(function()
        self:SetupSystemIntegration()
    end)
    
    -- NEW: Set up performance monitoring (Roblox best practice)
    self:SetupPerformanceMonitoring()
    
    gameState.isInitialized = true
    print("Milestone 3 game initialized successfully!")
end

-- NEW: Setup performance monitoring (Roblox best practice)
function MainServer:SetupPerformanceMonitoring()
    -- Use Heartbeat sparingly - only update every second instead of every frame
    connections.performanceMonitoring = RunService.Heartbeat:Connect(function()
        self:UpdatePerformanceMetrics()
    end)
    
    print("Performance monitoring initialized successfully!")
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

-- NEW: Initialize Milestone 2 systems
function MainServer:InitializeMilestone2Systems()
    print("Initializing Milestone 2 systems...")
    
    -- Initialize MultiTycoonManager
    gameState.multiTycoonManager = MultiTycoonManager.new()
    gameState.multiTycoonManager:Initialize(gameState.networkManager)
    
    -- Initialize CrossTycoonProgression
    gameState.crossTycoonProgression = CrossTycoonProgression.new()
    gameState.crossTycoonProgression:Initialize(gameState.networkManager)
    
    -- Initialize AdvancedPlotSystem
    gameState.advancedPlotSystem = AdvancedPlotSystem.new()
    gameState.advancedPlotSystem:Initialize(gameState.networkManager)
    
    print("Milestone 2 systems initialized successfully!")
end

-- NEW: Initialize Milestone 3 systems
function MainServer:InitializeMilestone3Systems()
    print("Initializing Milestone 3 systems...")
    
    -- Initialize CompetitiveManager
    gameState.competitiveManager = CompetitiveManager.new()
    gameState.competitiveManager:Initialize(gameState.networkManager)
    
    -- Initialize GuildSystem
    gameState.guildSystem = GuildSystem.new()
    gameState.guildSystem:Initialize(gameState.networkManager)
    
    -- Initialize TradingSystem
    gameState.tradingSystem = TradingSystem.new()
    gameState.tradingSystem:Initialize(gameState.networkManager)
    
    -- Initialize SocialSystem
    gameState.socialSystem = SocialSystem.new()
    gameState.socialSystem:Initialize(gameState.networkManager)
    
    -- Initialize SecurityManager
    gameState.securityManager = SecurityManager.new()
    gameState.securityManager:Initialize(gameState.networkManager)
    
    print("Milestone 3 systems initialized successfully!")
end

-- Setup save system
function MainServer:SetupSaveSystem()
    -- Initialize save system
    SaveSystem:Initialize()
    
    -- NEW: Use task.wait instead of RunService.Heartbeat for non-critical operations (Roblox best practice)
    -- This prevents save operations from blocking the main thread every frame
    connections.autoSave = task.spawn(function()
        while gameState.isInitialized do
            task.wait(gameState.saveInterval)
            if gameState.isInitialized then
                self:SafeCall(function()
                    self:SaveAllData()
                end)
            end
        end
    end)
end

-- Update save system (auto-save) - DEPRECATED in favor of task.spawn
function MainServer:UpdateSaveSystem()
    -- This function is now deprecated - auto-save is handled by task.spawn
    -- Kept for backward compatibility
end

-- Save all game data
function MainServer:SaveAllData()
    print("Auto-saving all game data...")
    
    -- Save player data through PlayerSync
    if gameState.playerSync then
        self:SafeCall(function()
            gameState.playerSync:SaveAllPlayerData()
        end)
    end
    
    -- Save tycoon data through TycoonSync
    if gameState.tycoonSync then
        self:SafeCall(function()
            gameState.tycoonSync:SaveAllTycoonData()
        end)
    end
    
    -- Save hub data through HubManager
    if gameState.hubManager then
        self:SafeCall(function()
            gameState.hubManager:SaveHubData()
        end)
    end
    
    -- NEW: Save Milestone 3 data
    if gameState.competitiveManager then
        self:SafeCall(function()
            gameState.competitiveManager:SaveCompetitiveData()
        end)
    end
    
    if gameState.guildSystem then
        self:SafeCall(function()
            gameState.guildSystem:SaveGuildData()
        end)
    end
    
    if gameState.tradingSystem then
        self:SafeCall(function()
            gameState.tradingSystem:SaveTradingData()
        end)
    end
    
    if gameState.socialSystem then
        self:SafeCall(function()
            gameState.socialSystem:SaveSocialData()
        end)
    end
    
    print("Auto-save completed!")
end

-- NEW: Public API for system monitoring and metrics
function MainServer:GetSystemMetrics()
    local metrics = {
        timestamp = tick(),
        serverUptime = tick() - gameState.startTime,
        activePlayers = #game.Players:GetPlayers(),
        systems = {},
        -- NEW: Performance metrics (Roblox best practice)
        performance = gameState.performanceMetrics
    }
    
    -- Core system metrics
    if gameState.networkManager then
        metrics.systems.network = gameState.networkManager:GetNetworkMetrics()
    end
    
    if gameState.saveSystem then
        metrics.systems.save = gameState.saveSystem:GetSaveMetrics()
    end
    
    -- Milestone 2 system metrics
    if gameState.playerSync then
        metrics.systems.playerSync = gameState.playerSync:GetPlayerMetrics()
    end
    
    if gameState.tycoonSync then
        metrics.systems.tycoonSync = gameState.tycoonSync:GetTycoonMetrics()
    end
    
    if gameState.multiTycoonManager then
        metrics.systems.multiTycoon = gameState.multiTycoonManager:GetMultiTycoonMetrics()
    end
    
    if gameState.crossTycoonProgression then
        metrics.systems.progression = gameState.crossTycoonProgression:GetProgressionMetrics()
    end
    
    if gameState.hubManager then
        metrics.systems.hub = gameState.hubManager:GetHubMetrics()
    end
    
    if gameState.advancedPlotSystem then
        metrics.systems.plotSystem = gameState.advancedPlotSystem:GetPlotMetrics()
    end
    
    -- Milestone 3 system metrics
    if gameState.competitiveManager then
        metrics.systems.competitive = gameState.competitiveManager:GetCompetitiveMetrics()
    end
    
    if gameState.guildSystem then
        metrics.systems.guild = gameState.guildSystem:GetGuildMetrics()
    end
    
    if gameState.tradingSystem then
        metrics.systems.trading = gameState.tradingSystem:GetTradingMetrics()
    end
    
    if gameState.socialSystem then
        metrics.systems.social = gameState.socialSystem:GetSocialMetrics()
    end
    
    if gameState.securityManager then
        metrics.systems.security = gameState.securityManager:GetSecurityMetrics()
    end
    
    return metrics
end

-- NEW: Get system health status
function MainServer:GetSystemHealth()
    local health = {
        status = "HEALTHY",
        issues = {},
        recommendations = {},
        systems = {},
        -- NEW: Performance health (Roblox best practice)
        performance = gameState.performanceMetrics
    }
    
    -- Check each system's health
    if gameState.securityManager then
        local securityHealth = gameState.securityManager:GetSystemHealth()
        health.systems.security = securityHealth
        
        if securityHealth.status ~= "HEALTHY" then
            health.status = "WARNING"
            for _, issue in ipairs(securityHealth.issues) do
                table.insert(health.issues, "Security: " .. issue)
            end
            for _, rec in ipairs(securityHealth.recommendations) do
                table.insert(health.recommendations, "Security: " .. rec)
            end
        end
    end
    
    -- Check for other potential issues
    local metrics = self:GetSystemMetrics()
    if metrics.activePlayers > 100 then
        table.insert(health.recommendations, "High player count - monitor performance")
    end
    
    if metrics.serverUptime > 86400 then -- 24 hours
        table.insert(health.recommendations, "Server running for over 24 hours - consider restart")
    end
    
    -- NEW: Check performance health (Roblox best practice)
    if gameState.performanceMetrics.systemHealth < 70 then
        health.status = "WARNING"
        table.insert(health.issues, "Low system health: " .. gameState.performanceMetrics.systemHealth .. "/100")
        table.insert(health.recommendations, "Check for memory leaks or excessive connections")
    end
    
    if gameState.performanceMetrics.activeConnections > 100 then
        table.insert(health.recommendations, "High connection count - review connection cleanup")
    end
    
    return health
end

-- Setup player management
function MainServer:SetupPlayerManagement()
    print("Setting up player management...")
    
    -- Handle players joining
    connections.playerAdded = Players.PlayerAdded:Connect(function(player)
        self:SafeCall(function()
            self:HandlePlayerJoined(player)
        end)
    end)
    
    -- Handle players leaving
    connections.playerRemoving = Players.PlayerRemoving:Connect(function(player)
        self:SafeCall(function()
            self:HandlePlayerLeft(player)
        end)
    end)
    
    -- Handle existing players
    for _, player in ipairs(Players:GetPlayers()) do
        self:SafeCall(function()
            self:HandlePlayerJoined(player)
        end)
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
            self:SafeCall(function()
                gameState.playerSync:OnPlotAssigned(player, plotId)
            end)
        end
        
        gameState.hubManager.OnPlotFreed = function(plotId)
            self:SafeCall(function()
                gameState.playerSync:OnPlotFreed(plotId)
            end)
        end
    end
    
    -- Connect TycoonSync with PlayerSync
    if gameState.tycoonSync and gameState.playerSync then
        gameState.tycoonSync.OnPlayerDataUpdate = function(player, data)
            self:SafeCall(function()
                gameState.playerSync:UpdatePlayerData(player, data)
            end)
        end
    end
    
    -- NEW: Connect Milestone 2 systems
    self:SetupMilestone2Integration()
    
    print("System integration completed!")
end

-- NEW: Setup Milestone 2 system integration
function MainServer:SetupMilestone2Integration()
    print("Setting up Milestone 2 system integration...")
    
    -- Connect MultiTycoonManager with HubManager
    if gameState.multiTycoonManager and gameState.hubManager then
        -- When a plot is assigned, add it to the player's tycoon list
        gameState.hubManager.OnPlotAssigned = function(player, plotId)
            -- Original callback
            if gameState.playerSync then
                self:SafeCall(function()
                    gameState.playerSync:OnPlotAssigned(player, plotId)
                end)
            end
            
            -- NEW: Add to MultiTycoonManager
            self:SafeCall(function()
                gameState.multiTycoonManager:AddTycoonToPlayer(player, plotId)
            end)
        end
        
        -- When a plot is freed, remove it from the player's tycoon list
        gameState.hubManager.OnPlotFreed = function(plotId)
            -- Original callback
            if gameState.playerSync then
                self:SafeCall(function()
                    gameState.playerSync:OnPlotFreed(plotId)
                end)
            end
            
            -- NEW: Find and remove from all players
            for _, player in ipairs(Players:GetPlayers()) do
                local tycoons = gameState.multiTycoonManager:GetPlayerTycoons(player)
                for _, tycoonId in ipairs(tycoons) do
                    if tycoonId == plotId then
                        self:SafeCall(function()
                            gameState.multiTycoonManager:RemoveTycoonFromPlayer(player, plotId)
                        end)
                        break
                    end
                end
            end
        end
    end
    
    -- Connect CrossTycoonProgression with MultiTycoonManager
    if gameState.crossTycoonProgression and gameState.multiTycoonManager then
        -- When tycoon ownership changes, update progression
        gameState.multiTycoonManager.OnTycoonOwnershipChanged = function(player, tycoonId, action)
            self:SafeCall(function()
                if action == "added" then
                    gameState.crossTycoonProgression:OnTycoonAdded(player, tycoonId)
                elseif action == "removed" then
                    gameState.crossTycoonProgression:OnTycoonRemoved(player, tycoonId)
                end
            end)
        end
    end
    
    -- Connect AdvancedPlotSystem with MultiTycoonManager
    if gameState.advancedPlotSystem and gameState.multiTycoonManager then
        -- When plot switching is requested, validate through AdvancedPlotSystem
        gameState.advancedPlotSystem.OnPlotSwitchRequest = function(player, targetPlotId)
            self:SafeCall(function()
                local currentTycoon = gameState.multiTycoonManager:GetPlayerCurrentTycoon(player)
                if currentTycoon and currentTycoon ~= targetPlotId then
                    gameState.multiTycoonManager:SwitchPlayerToTycoon(player, targetPlotId)
                end
            end)
        end
    end
    
    print("Milestone 2 system integration completed!")
end

-- Get game state info
function MainServer:GetGameState()
    return {
        isInitialized = gameState.isInitialized,
        -- Milestone 1 systems
        hubActive = gameState.hubManager ~= nil,
        networkActive = gameState.networkManager ~= nil,
        playerCount = #Players:GetPlayers(),
        plotCount = gameState.hubManager and gameState.hubManager:GetAllPlots() and #gameState.hubManager:GetAllPlots() or 0,
        -- NEW: Milestone 2 systems
        multiTycoonActive = gameState.multiTycoonManager ~= nil,
        crossProgressionActive = gameState.crossTycoonProgression ~= nil,
        advancedPlotActive = gameState.advancedPlotSystem ~= nil,
        multiTycoonStats = gameState.multiTycoonManager and gameState.multiTycoonManager:GetSystemStats() or {},
        -- NEW: Performance info (Roblox best practice)
        performance = {
            systemHealth = gameState.performanceMetrics.systemHealth,
            activeConnections = gameState.performanceMetrics.activeConnections,
            serverUptime = tick() - gameState.startTime
        }
    }
end

-- NEW: Cleanup method following Roblox best practices
function MainServer:Cleanup()
    print("MainServer: Cleaning up connections and resources...")
    
    -- Disconnect all connections to prevent memory leaks
    for name, connection in pairs(connections) do
        if connection and typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
            print("Disconnected connection:", name)
        end
    end
    connections = {}
    
    -- Clean up child systems
    if gameState.hubManager then
        gameState.hubManager:Cleanup()
    end
    
    if gameState.networkManager then
        gameState.networkManager:Cleanup()
    end
    
    if gameState.playerSync then
        gameState.playerSync:Cleanup()
    end
    
    if gameState.tycoonSync then
        gameState.tycoonSync:Cleanup()
    end
    
    if gameState.multiTycoonManager then
        gameState.multiTycoonManager:Cleanup()
    end
    
    if gameState.crossTycoonProgression then
        gameState.crossTycoonProgression:Cleanup()
    end
    
    if gameState.advancedPlotSystem then
        gameState.advancedPlotSystem:Cleanup()
    end
    
    if gameState.competitiveManager then
        gameState.competitiveManager:Cleanup()
    end
    
    if gameState.guildSystem then
        gameState.guildSystem:Cleanup()
    end
    
    if gameState.tradingSystem then
        gameState.tradingSystem:Cleanup()
    end
    
    if gameState.socialSystem then
        gameState.socialSystem:Cleanup()
    end
    
    if gameState.securityManager then
        gameState.securityManager:Cleanup()
    end
    
    -- Reset state
    gameState.isInitialized = false
    print("MainServer: Cleanup completed")
end

-- Initialize when the script runs
MainServer:Initialize()

-- Return the MainServer for external use
return MainServer
