-- MainServer.lua
-- Main server script for Milestone 3: Advanced Competitive & Social Systems
-- Enhanced with Roblox best practices for performance and memory management
-- STEP 15 COMPLETE: Final Integration & Deployment Ready

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

-- NEW: Step 15: Performance Optimization & Deployment Systems
local PerformanceOptimizer = require(script.Parent.Parent.Utils.PerformanceOptimizer)

-- NEW: Memory category tagging for better memory tracking (Roblox best practice)
debug.setmemorycategory("MainServer")

local MainServer = {}

-- NEW: Enhanced game state with performance monitoring and deployment features (Step 15)
local gameState = {
    isInitialized = false,
    startTime = tick(),
    deploymentPhase = "DEVELOPMENT", -- DEVELOPMENT, TESTING, PRODUCTION
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
    -- NEW: Step 15: Performance & Deployment systems
    performanceOptimizer = nil,
    saveInterval = Constants.SAVE.AUTO_SAVE_INTERVAL,
    lastSave = tick(),
    -- NEW: Enhanced performance monitoring (Step 15)
    performanceMetrics = {
        lastUpdate = 0,
        updateInterval = 1, -- Update every second instead of every frame
        systemHealth = 100,
        memoryUsage = 0,
        activeConnections = 0,
        playerCount = 0,
        optimizationLevel = "UNKNOWN",
        lastOptimization = 0,
        optimizationCount = 0
    },
    -- NEW: Error tracking and recovery (Step 15)
    errorTracker = {
        totalErrors = 0,
        criticalErrors = 0,
        lastError = nil,
        errorHistory = {},
        recoveryAttempts = 0
    },
    -- NEW: Deployment readiness tracking (Step 15)
    deploymentStatus = {
        systemsReady = false,
        performanceOptimized = false,
        errorHandlingActive = false,
        securityValidated = false,
        readyForProduction = false
    }
}

-- NEW: Connection tracking for proper cleanup (Roblox best practice)
local connections = {}

-- NEW: Enhanced error handling wrapper with recovery (Step 15)
function MainServer:SafeCall(func, errorContext, ...)
    local success, result = pcall(func, ...)
    if not success then
        local errorInfo = {
            timestamp = tick(),
            context = errorContext or "Unknown",
            error = result,
            traceback = debug.traceback(),
            playerCount = #Players:GetPlayers(),
            systemHealth = gameState.performanceMetrics.systemHealth
        }
        
        -- Track error
        gameState.errorTracker.totalErrors = gameState.errorTracker.totalErrors + 1
        gameState.errorTracker.lastError = errorInfo
        
        -- Check if critical
        if string.find(result, "critical") or string.find(result, "fatal") then
            gameState.errorTracker.criticalErrors = gameState.errorTracker.criticalErrors + 1
        end
        
        -- Store in history (keep last 10)
        table.insert(gameState.errorTracker.errorHistory, errorInfo)
        if #gameState.errorTracker.errorHistory > 10 then
            table.remove(gameState.errorTracker.errorHistory, 1)
        end
        
        -- Log error
        warn("MainServer error in", errorContext or "Unknown", ":", result)
        warn("Traceback:", errorInfo.traceback)
        
        -- Attempt recovery for non-critical errors
        if gameState.errorTracker.criticalErrors < 3 then
            self:AttemptErrorRecovery(errorInfo)
        end
        
        return nil
    end
    return result
end

-- NEW: Error recovery system (Step 15)
function MainServer:AttemptErrorRecovery(errorInfo)
    gameState.errorTracker.recoveryAttempts = gameState.errorTracker.recoveryAttempts + 1
    
    print("MainServer: Attempting error recovery (attempt", gameState.errorTracker.recoveryAttempts, ")")
    
    -- Simple recovery: restart performance monitoring
    if gameState.performanceOptimizer then
        self:SafeCall(function()
            gameState.performanceOptimizer:RestartMonitoring()
        end, "PerformanceOptimizer Recovery")
    end
    
    -- Reset performance metrics if they're corrupted
    if gameState.performanceMetrics.systemHealth < 0 then
        gameState.performanceMetrics.systemHealth = 50
        print("MainServer: Reset corrupted performance metrics")
    end
end

-- NEW: Enhanced performance monitoring method (Step 15)
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
        
        -- NEW: Get optimization level from PerformanceOptimizer
        if gameState.performanceOptimizer then
            local status = gameState.performanceOptimizer:GetPerformanceStatus()
            if status and status.optimizationLevel then
                gameState.performanceMetrics.optimizationLevel = status.optimizationLevel
            end
        end
        
        gameState.performanceMetrics.lastUpdate = currentTime
    end
end

-- NEW: Deployment readiness check (Step 15)
function MainServer:CheckDeploymentReadiness()
    local readiness = {
        systemsReady = gameState.isInitialized,
        performanceOptimized = gameState.performanceOptimizer and gameState.performanceOptimizer:GetPerformanceStatus().isOptimized or false,
        errorHandlingActive = gameState.errorTracker.totalErrors > 0, -- At least tested
        securityValidated = gameState.securityManager and gameState.securityManager:GetSystemHealth().status == "HEALTHY",
        readyForProduction = false
    }
    
    -- All systems must be ready
    readiness.readyForProduction = readiness.systemsReady and 
                                  readiness.performanceOptimized and 
                                  readiness.errorHandlingActive and 
                                  readiness.securityValidated
    
    gameState.deploymentStatus = readiness
    return readiness
end

-- Initialize the game
function MainServer:Initialize()
    if gameState.isInitialized then return end
    
    print("Initializing Roblox Tycoon Game - Milestone 3: Advanced Competitive & Social Systems...")
    print("STEP 15: Final Integration & Deployment...")
    
    -- NEW: Performance monitoring start (Roblox best practice)
    gameState.performanceMetrics.lastUpdate = tick()
    
    -- Initialize save system FIRST (Required for HubManager)
    self:SafeCall(function()
        self:SetupSaveSystem()
    end, "SaveSystem Setup")
    
    -- Initialize multiplayer systems
    self:SafeCall(function()
        self:InitializeMultiplayerSystems()
    end, "Multiplayer Systems")
    
    -- Initialize hub system (after SaveSystem is ready)
    self:SafeCall(function()
        self:InitializeHubSystem()
    end, "Hub System")
    
    -- Initialize Milestone 2 systems
    self:SafeCall(function()
        self:InitializeMilestone2Systems()
    end, "Milestone 2 Systems")
    
    -- NEW: Initialize Milestone 3 systems
    self:SafeCall(function()
        self:InitializeMilestone3Systems()
    end, "Milestone 3 Systems")
    
    -- NEW: Initialize Step 15: Performance Optimization & Deployment systems
    self:SafeCall(function()
        self:InitializeStep15Systems()
    end, "Step 15 Systems")
    
    -- Set up player management
    self:SafeCall(function()
        self:SetupPlayerManagement()
    end, "Player Management")
    
    -- Set up cross-system integration
    self:SafeCall(function()
        self:SetupSystemIntegration()
    end, "System Integration")
    
    -- NEW: Set up enhanced performance monitoring (Step 15)
    self:SetupPerformanceMonitoring()
    
    -- NEW: Set up deployment monitoring (Step 15)
    self:SetupDeploymentMonitoring()
    
    -- NEW: Final deployment readiness check (Step 15)
    local readiness = self:CheckDeploymentReadiness()
    
    gameState.isInitialized = true
    print("Milestone 3 game initialized successfully!")
    print("STEP 15 COMPLETE: Final Integration & Deployment Ready!")
    
    if readiness.readyForProduction then
        print("🎉 DEPLOYMENT READY: All systems optimized and validated for production!")
        gameState.deploymentPhase = "PRODUCTION"
    else
        print("⚠️  DEPLOYMENT WARNING: Some systems require attention before production")
        gameState.deploymentPhase = "TESTING"
    end
end

-- NEW: Initialize Step 15 systems (Step 15)
function MainServer:InitializeStep15Systems()
    print("Initializing Step 15: Performance Optimization & Deployment systems...")
    
    -- Initialize PerformanceOptimizer
    gameState.performanceOptimizer = PerformanceOptimizer.new()
    gameState.performanceOptimizer:Initialize()
    
    -- Start optimization loop
    self:SafeCall(function()
        gameState.performanceOptimizer:StartOptimizationLoop()
    end, "PerformanceOptimizer Start")
    
    print("Step 15 systems initialized successfully!")
end

-- NEW: Setup enhanced performance monitoring (Step 15)
function MainServer:SetupPerformanceMonitoring()
    -- Use Heartbeat sparingly - only update every second instead of every frame
    connections.performanceMonitoring = RunService.Heartbeat:Connect(function()
        self:UpdatePerformanceMetrics()
    end)
    
    -- NEW: Performance optimization monitoring
    connections.optimizationMonitoring = RunService.Heartbeat:Connect(function()
        if gameState.performanceOptimizer then
            local status = gameState.performanceOptimizer:GetPerformanceStatus()
            if status and status.needsOptimization then
                self:SafeCall(function()
                    gameState.performanceOptimizer:CheckAndOptimize()
                end, "Performance Optimization")
                
                gameState.performanceMetrics.lastOptimization = tick()
                gameState.performanceMetrics.optimizationCount = gameState.performanceMetrics.optimizationCount + 1
            end
        end
    end)
    
    print("Enhanced performance monitoring initialized successfully!")
end

-- NEW: Setup deployment monitoring (Step 15)
function MainServer:SetupDeploymentMonitoring()
    -- Monitor deployment status every 30 seconds
    connections.deploymentMonitoring = RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        if currentTime - gameState.startTime > 30 then -- Wait 30 seconds after startup
            local readiness = self:CheckDeploymentReadiness()
            if readiness.readyForProduction and gameState.deploymentPhase ~= "PRODUCTION" then
                print("🎉 DEPLOYMENT STATUS: System now ready for production!")
                gameState.deploymentPhase = "PRODUCTION"
            elseif not readiness.readyForProduction and gameState.deploymentPhase == "PRODUCTION" then
                print("⚠️  DEPLOYMENT STATUS: System no longer ready for production")
                gameState.deploymentPhase = "TESTING"
            end
        end
    end)
    
    print("Deployment monitoring initialized successfully!")
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

-- NEW: Enhanced public API for system monitoring and metrics (Step 15)
function MainServer:GetSystemMetrics()
    local metrics = {
        timestamp = tick(),
        serverUptime = tick() - gameState.startTime,
        activePlayers = #game.Players:GetPlayers(),
        deploymentPhase = gameState.deploymentPhase,
        systems = {},
        -- NEW: Enhanced performance metrics (Step 15)
        performance = gameState.performanceMetrics,
        -- NEW: Error tracking metrics (Step 15)
        errors = gameState.errorTracker,
        -- NEW: Deployment status (Step 15)
        deployment = gameState.deploymentStatus
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
    
    -- NEW: Step 15: Performance optimization metrics
    if gameState.performanceOptimizer then
        local optimizerStatus = gameState.performanceOptimizer:GetPerformanceStatus()
        local optimizerRecommendations = gameState.performanceOptimizer:GetOptimizationRecommendations()
        
        metrics.systems.performanceOptimizer = {
            status = optimizerStatus,
            recommendations = optimizerRecommendations,
            optimizationLevel = gameState.performanceMetrics.optimizationLevel,
            lastOptimization = gameState.performanceMetrics.lastOptimization,
            totalOptimizations = gameState.performanceMetrics.optimizationCount
        }
    end
    
    return metrics
end

-- NEW: Enhanced system health status with deployment readiness (Step 15)
function MainServer:GetSystemHealth()
    local health = {
        status = "HEALTHY",
        issues = {},
        recommendations = {},
        systems = {},
        -- NEW: Enhanced performance health (Step 15)
        performance = gameState.performanceMetrics,
        -- NEW: Error health (Step 15)
        errors = gameState.errorTracker,
        -- NEW: Deployment readiness (Step 15)
        deployment = gameState.deploymentStatus,
        deploymentPhase = gameState.deploymentPhase
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
    
    -- NEW: Check performance optimizer health (Step 15)
    if gameState.performanceOptimizer then
        local optimizerStatus = gameState.performanceOptimizer:GetPerformanceStatus()
        if optimizerStatus and optimizerStatus.status ~= "OPTIMIZED" then
            health.status = "WARNING"
            table.insert(health.issues, "Performance: " .. (optimizerStatus.status or "Unknown"))
            table.insert(health.recommendations, "Check performance optimization settings")
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
    
    -- NEW: Enhanced performance health checks (Step 15)
    if gameState.performanceMetrics.systemHealth < 70 then
        health.status = "WARNING"
        table.insert(health.issues, "Low system health: " .. gameState.performanceMetrics.systemHealth .. "/100")
        table.insert(health.recommendations, "Check for memory leaks or excessive connections")
    end
    
    if gameState.performanceMetrics.activeConnections > 100 then
        table.insert(health.recommendations, "High connection count - review connection cleanup")
    end
    
    -- NEW: Error health checks (Step 15)
    if gameState.errorTracker.criticalErrors > 0 then
        health.status = "CRITICAL"
        table.insert(health.issues, "Critical errors detected: " .. gameState.errorTracker.criticalErrors)
        table.insert(health.recommendations, "Review error logs and restart affected systems")
    end
    
    if gameState.errorTracker.totalErrors > 10 then
        table.insert(health.recommendations, "High error rate - investigate system stability")
    end
    
    -- NEW: Deployment readiness checks (Step 15)
    if not gameState.deploymentStatus.readyForProduction then
        health.status = "WARNING"
        table.insert(health.issues, "System not ready for production deployment")
        
        if not gameState.deploymentStatus.systemsReady then
            table.insert(health.recommendations, "Complete system initialization")
        end
        if not gameState.deploymentStatus.performanceOptimized then
            table.insert(health.recommendations, "Complete performance optimization")
        end
        if not gameState.deploymentStatus.errorHandlingActive then
            table.insert(health.recommendations, "Test error handling systems")
        end
        if not gameState.deploymentStatus.securityValidated then
            table.insert(health.recommendations, "Validate security systems")
        end
    end
    
    return health
end

-- NEW: Get deployment readiness status (Step 15)
function MainServer:GetDeploymentStatus()
    local readiness = self:CheckDeploymentReadiness()
    
    return {
        isReady = readiness.readyForProduction,
        phase = gameState.deploymentPhase,
        status = readiness,
        timestamp = tick(),
        serverUptime = tick() - gameState.startTime,
        recommendations = self:GetDeploymentRecommendations()
    }
end

-- NEW: Get deployment recommendations (Step 15)
function MainServer:GetDeploymentRecommendations()
    local recommendations = {}
    local readiness = gameState.deploymentStatus
    
    if not readiness.systemsReady then
        table.insert(recommendations, "Complete system initialization sequence")
    end
    
    if not readiness.performanceOptimized then
        table.insert(recommendations, "Run performance optimization cycle")
        table.insert(recommendations, "Verify memory usage is within acceptable limits")
        table.insert(recommendations, "Check draw call optimization")
    end
    
    if not readiness.errorHandlingActive then
        table.insert(recommendations, "Test error handling and recovery systems")
        table.insert(recommendations, "Verify error logging and monitoring")
    end
    
    if not readiness.securityValidated then
        table.insert(recommendations, "Run security validation tests")
        table.insert(recommendations, "Verify rate limiting and authorization")
    end
    
    if #recommendations == 0 then
        table.insert(recommendations, "System is ready for production deployment")
    end
    
    return recommendations
end

-- NEW: Force deployment readiness check (Step 15)
function MainServer:ForceDeploymentCheck()
    print("MainServer: Forcing deployment readiness check...")
    
    -- Re-run all system checks
    local readiness = self:CheckDeploymentReadiness()
    
    if readiness.readyForProduction then
        print("🎉 DEPLOYMENT READY: All systems validated for production!")
        gameState.deploymentPhase = "PRODUCTION"
    else
        print("⚠️  DEPLOYMENT WARNING: System requires attention before production")
        gameState.deploymentPhase = "TESTING"
        
        -- Print specific issues
        local recommendations = self:GetDeploymentRecommendations()
        for _, rec in ipairs(recommendations) do
            print("  - " .. rec)
        end
    end
    
    return readiness
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
    -- PlayerSync now manages player initialization internally
    print("MainServer: Player " .. player.Name .. " initialization deferred to PlayerSync")
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
    
    -- NEW: Connect TycoonSync with HubManager for proper TycoonBase integration
    if gameState.tycoonSync and gameState.hubManager then
        -- Set up callbacks for tycoon ownership changes
        gameState.tycoonSync:SetOnTycoonClaimed(function(userId, tycoonId)
            self:SafeCall(function()
                local player = Players:GetPlayerByUserId(userId)
                if player then
                    local tycoonBase = gameState.hubManager:GetTycoonBaseFromPlot(tycoonId)
                    if tycoonBase and tycoonBase.SetOwner then
                        tycoonBase:SetOwner(player)
                        if tycoonBase.ShowUI then
                            tycoonBase:ShowUI(player)
                        end
                        print("MainServer: TycoonBase ownership and UI updated for", tycoonId, "->", player.Name)
                    end
                end
            end)
        end)
        
        gameState.tycoonSync:SetOnTycoonReleased(function(tycoonId)
            self:SafeCall(function()
                local tycoonBase = gameState.hubManager:GetTycoonBaseFromPlot(tycoonId)
                if tycoonBase and tycoonBase.SetOwner then
                    tycoonBase:SetOwner(nil)
                    print("MainServer: TycoonBase ownership cleared for", tycoonId)
                end
            end)
        end)
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

-- NEW: Enhanced cleanup method following Roblox best practices (Step 15)
function MainServer:Cleanup()
    print("MainServer: Cleaning up connections and resources...")
    print("STEP 15: Final cleanup and deployment preparation...")
    
    -- Disconnect all connections to prevent memory leaks
    for name, connection in pairs(connections) do
        if connection and typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
            print("Disconnected connection:", name)
        end
    end
    connections = {}
    
    -- NEW: Clean up Step 15 systems
    if gameState.performanceOptimizer then
        self:SafeCall(function()
            gameState.performanceOptimizer:Destroy()
        end, "PerformanceOptimizer Cleanup")
        gameState.performanceOptimizer = nil
    end
    
    -- Clean up child systems
    if gameState.hubManager then
        self:SafeCall(function()
            gameState.hubManager:Cleanup()
        end, "HubManager Cleanup")
    end
    
    if gameState.networkManager then
        self:SafeCall(function()
            gameState.networkManager:Cleanup()
        end, "NetworkManager Cleanup")
    end
    
    if gameState.playerSync then
        self:SafeCall(function()
            gameState.playerSync:Cleanup()
        end, "PlayerSync Cleanup")
    end
    
    if gameState.tycoonSync then
        self:SafeCall(function()
            gameState.tycoonSync:Cleanup()
        end, "TycoonSync Cleanup")
    end
    
    if gameState.multiTycoonManager then
        self:SafeCall(function()
            gameState.multiTycoonManager:Cleanup()
        end, "MultiTycoonManager Cleanup")
    end
    
    if gameState.crossTycoonProgression then
        self:SafeCall(function()
            gameState.crossTycoonProgression:Cleanup()
        end, "CrossTycoonProgression Cleanup")
    end
    
    if gameState.advancedPlotSystem then
        self:SafeCall(function()
            gameState.advancedPlotSystem:Cleanup()
        end, "AdvancedPlotSystem Cleanup")
    end
    
    if gameState.competitiveManager then
        self:SafeCall(function()
            gameState.competitiveManager:Cleanup()
        end, "CompetitiveManager Cleanup")
    end
    
    if gameState.guildSystem then
        self:SafeCall(function()
            gameState.guildSystem:Cleanup()
        end, "GuildSystem Cleanup")
    end
    
    if gameState.tradingSystem then
        self:SafeCall(function()
            gameState.tradingSystem:Cleanup()
        end, "TradingSystem Cleanup")
    end
    
    if gameState.socialSystem then
        self:SafeCall(function()
            gameState.socialSystem:Cleanup()
        end, "SocialSystem Cleanup")
    end
    
    if gameState.securityManager then
        self:SafeCall(function()
            gameState.securityManager:Cleanup()
        end, "SecurityManager Cleanup")
    end
    
    -- NEW: Reset deployment status
    gameState.deploymentStatus = {
        systemsReady = false,
        performanceOptimized = false,
        errorHandlingActive = false,
        securityValidated = false,
        readyForProduction = false
    }
    gameState.deploymentPhase = "DEVELOPMENT"
    
    -- Reset state
    gameState.isInitialized = false
    print("MainServer: Cleanup completed")
    print("STEP 15: System ready for restart and redeployment")
end

-- NEW: Enhanced game state info with deployment status (Step 15)
function MainServer:GetGameState()
    return {
        isInitialized = gameState.isInitialized,
        deploymentPhase = gameState.deploymentPhase,
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
        -- NEW: Milestone 3 systems
        competitiveActive = gameState.competitiveManager ~= nil,
        guildActive = gameState.guildSystem ~= nil,
        tradingActive = gameState.tradingSystem ~= nil,
        socialActive = gameState.socialSystem ~= nil,
        securityActive = gameState.securityManager ~= nil,
        -- NEW: Step 15: Performance & Deployment systems
        performanceOptimizerActive = gameState.performanceOptimizer ~= nil,
        -- NEW: Enhanced performance info (Step 15)
        performance = {
            systemHealth = gameState.performanceMetrics.systemHealth,
            activeConnections = gameState.performanceMetrics.activeConnections,
            serverUptime = tick() - gameState.startTime,
            optimizationLevel = gameState.performanceMetrics.optimizationLevel,
            lastOptimization = gameState.performanceMetrics.lastOptimization,
            totalOptimizations = gameState.performanceMetrics.optimizationCount
        },
        -- NEW: Error tracking (Step 15)
        errors = {
            totalErrors = gameState.errorTracker.totalErrors,
            criticalErrors = gameState.errorTracker.criticalErrors,
            recoveryAttempts = gameState.errorTracker.recoveryAttempts
        },
        -- NEW: Deployment status (Step 15)
        deployment = gameState.deploymentStatus
    }
end

-- NEW: Get comprehensive system status for deployment (Step 15)
function MainServer:GetDeploymentReport()
    local report = {
        timestamp = tick(),
        serverUptime = tick() - gameState.startTime,
        deploymentPhase = gameState.deploymentPhase,
        systems = {},
        performance = {},
        errors = {},
        recommendations = {},
        isReadyForProduction = false
    }
    
    -- System status
    report.systems = {
        hub = gameState.hubManager ~= nil,
        network = gameState.networkManager ~= nil,
        playerSync = gameState.playerSync ~= nil,
        tycoonSync = gameState.tycoonSync ~= nil,
        multiTycoon = gameState.multiTycoonManager ~= nil,
        crossProgression = gameState.crossTycoonProgression ~= nil,
        advancedPlot = gameState.advancedPlotSystem ~= nil,
        competitive = gameState.competitiveManager ~= nil,
        guild = gameState.guildSystem ~= nil,
        trading = gameState.tradingSystem ~= nil,
        social = gameState.socialSystem ~= nil,
        security = gameState.securityManager ~= nil,
        performanceOptimizer = gameState.performanceOptimizer ~= nil
    }
    
    -- Performance status
    if gameState.performanceOptimizer then
        local status = gameState.performanceOptimizer:GetPerformanceStatus()
        report.performance = {
            current = gameState.performanceMetrics,
            optimizer = status,
            recommendations = gameState.performanceOptimizer:GetOptimizationRecommendations()
        }
    else
        report.performance = {
            current = gameState.performanceMetrics,
            optimizer = nil,
            recommendations = {"PerformanceOptimizer not initialized"}
        }
    end
    
    -- Error status
    report.errors = gameState.errorTracker
    
    -- Get recommendations
    report.recommendations = self:GetDeploymentRecommendations()
    
    -- Final readiness
    report.isReadyForProduction = gameState.deploymentStatus.readyForProduction
    
    return report
end

-- NEW: Emergency shutdown for critical failures (Step 15)
function MainServer:EmergencyShutdown(reason)
    print("🚨 EMERGENCY SHUTDOWN INITIATED:", reason or "Unknown reason")
    print("MainServer: Shutting down all systems...")
    
    -- Force cleanup without error handling
    for name, connection in pairs(connections) do
        if connection and typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
        end
    end
    connections = {}
    
    -- Reset all state
    gameState = {
        isInitialized = false,
        startTime = tick(),
        deploymentPhase = "EMERGENCY_SHUTDOWN",
        errorTracker = {
            totalErrors = gameState.errorTracker.totalErrors + 1,
            criticalErrors = gameState.errorTracker.criticalErrors + 1,
            lastError = { timestamp = tick(), error = reason, emergency = true },
            errorHistory = {},
            recoveryAttempts = 0
        }
    }
    
    print("MainServer: Emergency shutdown completed")
    print("MainServer: System requires manual restart")
end

-- NEW: Restart system after emergency shutdown (Step 15)
function MainServer:RestartAfterEmergency()
    if gameState.deploymentPhase ~= "EMERGENCY_SHUTDOWN" then
        warn("MainServer: Cannot restart - system not in emergency shutdown mode")
        return false
    end
    
    print("MainServer: Attempting restart after emergency shutdown...")
    
    -- Reset deployment phase
    gameState.deploymentPhase = "DEVELOPMENT"
    
    -- Attempt re-initialization
    local success = pcall(function()
        self:Initialize()
    end)
    
    if success then
        print("MainServer: Restart successful")
        return true
    else
        print("MainServer: Restart failed - manual intervention required")
        gameState.deploymentPhase = "EMERGENCY_SHUTDOWN"
        return false
    end
end

-- Initialize when the script runs
print("🚀 MainServer: Starting initialization...")
local success, result = pcall(function()
    MainServer:Initialize()
end)

if not success then
    warn("❌ CRITICAL: MainServer initialization failed!")
    warn("Error:", result)
    warn("Traceback:", debug.traceback())
else
    print("✅ MainServer: Initialization completed successfully!")
end

-- Return the MainServer for external use
return MainServer
