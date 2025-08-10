-- MainClient.lua
-- Main client script for Milestone 3: Advanced Competitive & Social Systems
-- Enhanced with Roblox best practices for performance and memory management

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Constants = require(script.Parent.Parent.Utils.Constants)
local HelperFunctions = require(script.Parent.Parent.Utils.HelperFunctions)

-- NEW: Memory category tagging for better memory tracking (Roblox best practice)
debug.setmemorycategory("MainClient")

-- Milestone 1: Hub and Multiplayer systems
local HubUI = require(script.Parent.Parent.Hub.HubUI)
local PlotSelector = require(script.Parent.Parent.Hub.PlotSelector)

-- Milestone 2: Multiple Tycoon Ownership systems
local MultiTycoonClient = require(script.Parent.Parent.Multiplayer.MultiTycoonClient)
local CrossTycoonClient = require(script.Parent.Parent.Multiplayer.CrossTycoonClient)
local AdvancedPlotClient = require(script.Parent.Parent.Hub.AdvancedPlotClient)

-- NEW: Milestone 3: Advanced Competitive & Social Systems
local CompetitiveManager = require(script.Parent.Parent.Competitive.CompetitiveManager)
local GuildSystem = require(script.Parent.Parent.Competitive.GuildSystem)
local TradingSystem = require(script.Parent.Parent.Competitive.TradingSystem)
local SocialSystem = require(script.Parent.Parent.Competitive.SocialSystem)
local SecurityManager = require(script.Parent.Parent.Competitive.SecurityManager)

local MainClient = {}

-- NEW: Enhanced performance monitoring (Roblox best practice)
local performanceMetrics = {
    lastUpdate = 0,
    updateInterval = 1 / ((Constants.UI and Constants.UI.UI_UPDATE_RATE) or 30),
    averageUpdateTime = 0,
    memoryUsage = 0,
    playerCount = 0,
    systemHealth = 100,
    updateTimes = {},
    memorySnapshots = {},
    performanceHistory = {}
}

-- NEW: Initialize managers for critical fixes
local connectionManager = ConnectionManager.new()
local updateManager = UpdateManager.new()
local dataArchiver = DataArchiver.new()

-- Client state for Milestone 3
local clientState = {
    isInitialized = false,
    player = Players.LocalPlayer,
    playerGui = nil,
    -- Milestone 1 systems
    hubUI = nil,
    plotSelector = nil,
    -- Milestone 2 systems
    multiTycoonClient = nil,
    crossTycoonClient = nil,
    advancedPlotClient = nil,
    -- NEW: Milestone 3 systems
    competitiveManager = nil,
    guildSystem = nil,
    tradingSystem = nil,
    socialSystem = nil,
    securityManager = nil,
    playerData = {
        Cash = 0,
        Abilities = {},
        CurrentPlot = nil,
        Level = 1,
        Experience = 0,
        -- Milestone 2: Multi-tycoon data
        OwnedTycoons = {},
        CrossTycoonBonuses = {},
        PlotSwitchCooldown = 0,
        -- NEW: Milestone 3 data
        CompetitiveRank = 0,
        AchievementPoints = 0,
        PrestigeLevel = 0,
        GuildId = nil,
        GuildRole = nil,
        FriendList = {},
        TradeHistory = {},
        SecurityStatus = "CLEAN"
    },
    hubData = {
        AvailablePlots = {},
        PlayerCount = 0,
        IsInHub = true
    }
}

-- NEW: Connection tracking for proper cleanup (Roblox best practice)
local connections = {}
local ConnectionManager = require(script.Parent.Parent.Utils.ConnectionManager)
local UpdateManager = require(script.Parent.Parent.Utils.UpdateManager)
local DataArchiver = require(script.Parent.Parent.Utils.DataArchiver)

-- NEW: Error handling wrapper (Roblox best practice)
function MainClient:SafeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        warn("MainClient error in", debug.traceback(), ":", result)
        return nil
    end
    return result
end

-- NEW: Enhanced performance monitoring methods (Roblox best practice)
function MainClient:UpdatePerformanceMetrics()
    local currentTime = tick()
    local updateTime = currentTime - performanceMetrics.lastUpdate
    
    -- Track update times for averaging
    table.insert(performanceMetrics.updateTimes, updateTime)
    
    -- NEW: Use DataArchiver to prevent unbounded growth
    dataArchiver:ArchiveData("performance_updateTimes", performanceMetrics.updateTimes, Constants.MEMORY.MAX_HISTORY_SIZE)
    
    -- Calculate average update time
    local totalTime = 0
    for _, time in ipairs(performanceMetrics.updateTimes) do
        totalTime = totalTime + time
    end
    performanceMetrics.averageUpdateTime = totalTime / #performanceMetrics.updateTimes
    
    -- Update memory usage
    performanceMetrics.memoryUsage = self:GetMemoryUsage()
    
    -- NEW: Take periodic memory snapshots (Roblox best practice)
    if #performanceMetrics.updateTimes % 10 == 0 then -- Every 10 updates
        self:TakeMemorySnapshot()
    end
    
    -- Update system health based on performance
    if performanceMetrics.averageUpdateTime < 0.016 then -- 60 FPS target
        performanceMetrics.systemHealth = math.min(100, performanceMetrics.systemHealth + 1)
    else
        performanceMetrics.systemHealth = math.max(0, performanceMetrics.systemHealth - 1)
    end
    
    -- Store performance history
    table.insert(performanceMetrics.performanceHistory, {
        timestamp = currentTime,
        updateTime = updateTime,
        memoryUsage = performanceMetrics.memoryUsage,
        systemHealth = performanceMetrics.systemHealth
    })
    
    -- NEW: Use DataArchiver to prevent unbounded growth
    dataArchiver:ArchiveData("performance_history", performanceMetrics.performanceHistory, Constants.MEMORY.MAX_PERFORMANCE_DATA)
    
    performanceMetrics.lastUpdate = currentTime
end

-- NEW: Advanced memory profiling (Roblox best practice)
function MainClient:GetMemoryUsage()
    local memory = {
        clientState = 0,
        connections = 0,
        performanceMetrics = 0,
        systems = 0,
        total = 0
    }
    
    -- Estimate memory usage of client state
    memory.clientState = self:EstimateTableMemory(clientState)
    
    -- Count connections
    memory.connections = #connections
    
    -- Estimate performance metrics memory
    memory.performanceMetrics = self:EstimateTableMemory(performanceMetrics)
    
    -- Estimate systems memory
    local systemsMemory = 0
    if clientState.hubUI then systemsMemory = systemsMemory + 100 end
    if clientState.plotSelector then systemsMemory = systemsMemory + 100 end
    if clientState.multiTycoonClient then systemsMemory = systemsMemory + 100 end
    if clientState.crossTycoonClient then systemsMemory = systemsMemory + 100 end
    if clientState.advancedPlotClient then systemsMemory = systemsMemory + 100 end
    if clientState.competitiveManager then systemsMemory = systemsMemory + 100 end
    if clientState.guildSystem then systemsMemory = systemsMemory + 100 end
    if clientState.tradingSystem then systemsMemory = systemsMemory + 100 end
    if clientState.socialSystem then systemsMemory = systemsMemory + 100 end
    if clientState.securityManager then systemsMemory = systemsMemory + 100 end
    memory.systems = systemsMemory
    
    memory.total = memory.clientState + memory.connections + memory.performanceMetrics + memory.systems
    return memory
end

-- NEW: Helper function to estimate table memory usage (Roblox best practice)
function MainClient:EstimateTableMemory(tbl)
    if type(tbl) ~= "table" then
        return 0
    end
    
    local memory = 0
    for key, value in pairs(tbl) do
        memory = memory + 50 -- Base cost for key-value pair
        
        if type(value) == "table" then
            memory = memory + self:EstimateTableMemory(value)
        elseif type(value) == "string" then
            memory = memory + #value
        elseif type(value) == "number" then
            memory = memory + 8
        elseif type(value) == "boolean" then
            memory = memory + 1
        end
    end
    
    return memory
end

-- NEW: Get comprehensive performance metrics (Roblox best practice)
function MainClient:GetPerformanceMetrics()
    return {
        current = {
            averageUpdateTime = performanceMetrics.averageUpdateTime,
            memoryUsage = performanceMetrics.memoryUsage,
            systemHealth = performanceMetrics.systemHealth,
            playerCount = performanceMetrics.playerCount
        },
        history = performanceMetrics.performanceHistory,
        summary = {
            totalUpdates = #performanceMetrics.updateTimes,
            averageMemoryUsage = self:CalculateAverageMemoryUsage(),
            systemHealthTrend = self:CalculateSystemHealthTrend(),
            performanceScore = self:CalculatePerformanceScore()
        }
    }
end

-- NEW: Calculate average memory usage (Roblox best practice)
function MainClient:CalculateAverageMemoryUsage()
    if #performanceMetrics.memorySnapshots == 0 then
        return 0
    end
    
    local total = 0
    for _, snapshot in ipairs(performanceMetrics.memorySnapshots) do
        total = total + (snapshot.total or 0)
    end
    
    return total / #performanceMetrics.memorySnapshots
end

-- NEW: Calculate system health trend (Roblox best practice)
function MainClient:CalculateSystemHealthTrend()
    if #performanceMetrics.performanceHistory < 2 then
        return "stable"
    end
    
    local recent = performanceMetrics.performanceHistory[#performanceMetrics.performanceHistory]
    local previous = performanceMetrics.performanceHistory[#performanceMetrics.performanceHistory - 1]
    
    if recent.systemHealth > previous.systemHealth then
        return "improving"
    elseif recent.systemHealth < previous.systemHealth then
        return "declining"
    else
        return "stable"
    end
end

-- NEW: Calculate overall performance score (Roblox best practice)
function MainClient:CalculatePerformanceScore()
    local score = 0
    
    -- Update time score (target: < 16ms for 60 FPS)
    if performanceMetrics.averageUpdateTime < 0.016 then
        score = score + 40
    elseif performanceMetrics.averageUpdateTime < 0.033 then
        score = score + 30
    elseif performanceMetrics.averageUpdateTime < 0.05 then
        score = score + 20
    else
        score = score + 10
    end
    
    -- System health score
    score = score + performanceMetrics.systemHealth * 0.4
    
    -- Memory efficiency score
    local memoryEfficiency = math.max(0, 100 - (performanceMetrics.memoryUsage.total / 1000))
    score = score + memoryEfficiency * 0.2
    
    return math.floor(score)
end

-- NEW: Take memory snapshot for tracking (Roblox best practice)
function MainClient:TakeMemorySnapshot()
    local snapshot = {
        timestamp = tick(),
        memoryUsage = self:GetMemoryUsage(),
        systemHealth = performanceMetrics.systemHealth,
        playerCount = performanceMetrics.playerCount
    }
    
    table.insert(performanceMetrics.memorySnapshots, snapshot)
    
    -- NEW: Use DataArchiver to prevent unbounded growth
    dataArchiver:ArchiveData("performance_snapshots", performanceMetrics.memorySnapshots, Constants.MEMORY.MAX_SNAPSHOT_SIZE)
    
    return snapshot
end

-- NEW: Get memory usage trend analysis (Roblox best practice)
function MainClient:GetMemoryUsageTrend()
    if #performanceMetrics.memorySnapshots < 2 then
        return "insufficient_data"
    end
    
    local recent = performanceMetrics.memorySnapshots[#performanceMetrics.memorySnapshots]
    local previous = performanceMetrics.memorySnapshots[#performanceMetrics.memorySnapshots - 1]
    
    local memoryChange = recent.memoryUsage.total - previous.memoryUsage.total
    local timeChange = recent.timestamp - previous.timestamp
    
    if timeChange == 0 then
        return "stable"
    end
    
    local memoryChangeRate = memoryChange / timeChange
    
    if memoryChangeRate > 100 then
        return "increasing_rapidly"
    elseif memoryChangeRate > 10 then
        return "increasing"
    elseif memoryChangeRate < -100 then
        return "decreasing_rapidly"
    elseif memoryChangeRate < -10 then
        return "decreasing"
    else
        return "stable"
    end
end

-- Initialize the client
function MainClient:Initialize()
    if clientState.isInitialized then return end
    
    print("Initializing Client - Milestone 3: Advanced Competitive & Social Systems...")
    
    -- NEW: Performance monitoring start (Roblox best practice)
    performanceMetrics.lastUpdate = tick()
    
    -- Wait for player to load
    if not clientState.player then
        clientState.player = Players.LocalPlayer
    end
    
    if not clientState.player then
        warn("Failed to get local player")
        return
    end
    
    -- Wait for PlayerGui
    clientState.playerGui = clientState.player:WaitForChild("PlayerGui")
    
    -- Initialize systems with error handling
    local success = self:SafeCall(function()
        -- Initialize Hub UI
        self:InitializeHubUI()
        
        -- Initialize Plot Selector
        self:InitializePlotSelector()
        
        -- NEW: Initialize Milestone 2 systems
        self:InitializeMilestone2Systems()
        
        -- NEW: Initialize Milestone 3 systems
        self:InitializeMilestone3Systems()
        
        -- Set up input handling
        self:SetupInputHandling()
        
        -- Set up player monitoring
        self:SetupPlayerMonitoring()
    end)
    
    if not success then
        warn("Failed to initialize MainClient systems")
        return
    end
    
    clientState.isInitialized = true
    print("Milestone 3 client initialized successfully!")
end

-- Initialize Hub UI
function MainClient:InitializeHubUI()
    print("Initializing Hub UI...")
    
    clientState.hubUI = HubUI.new()
    clientState.hubUI:Initialize()
    
    print("Hub UI initialized successfully!")
end

-- Initialize Plot Selector
function MainClient:InitializePlotSelector()
    print("Initializing Plot Selector...")
    
    clientState.plotSelector = PlotSelector.new()
    
    print("Plot Selector initialized successfully!")
end

-- NEW: Initialize Milestone 2 systems
function MainClient:InitializeMilestone2Systems()
    print("Initializing Milestone 2 systems...")
    
    -- Initialize MultiTycoonClient
    clientState.multiTycoonClient = MultiTycoonClient.new()
    clientState.multiTycoonClient:Initialize()
    
    -- Initialize CrossTycoonClient
    clientState.crossTycoonClient = CrossTycoonClient.new()
    clientState.crossTycoonClient:Initialize()
    
    -- Initialize AdvancedPlotClient
    clientState.advancedPlotClient = AdvancedPlotClient.new()
    clientState.advancedPlotClient:Initialize()
    
    -- Set up callbacks and integration
    self:SetupMilestone2Callbacks()
    
    print("Milestone 2 systems initialized successfully!")
end

-- NEW: Initialize Milestone 3 systems
function MainClient:InitializeMilestone3Systems()
    print("Initializing Milestone 3 systems...")
    
    -- Initialize CompetitiveManager
    clientState.competitiveManager = CompetitiveManager.new()
    clientState.competitiveManager:Initialize()
    
    -- Initialize GuildSystem
    clientState.guildSystem = GuildSystem.new()
    clientState.guildSystem:Initialize()
    
    -- Initialize TradingSystem
    clientState.tradingSystem = TradingSystem.new()
    clientState.tradingSystem:Initialize()
    
    -- Initialize SocialSystem
    clientState.socialSystem = SocialSystem.new()
    clientState.socialSystem:Initialize()
    
    -- Initialize SecurityManager
    clientState.securityManager = SecurityManager.new()
    clientState.securityManager:Initialize()
    
    -- Set up callbacks and integration
    self:SetupMilestone3Callbacks()
    
    print("Milestone 3 systems initialized successfully!")
end

-- NEW: Setup Milestone 2 callbacks and integration
function MainClient:SetupMilestone2Callbacks()
    print("Setting up Milestone 2 callbacks...")
    
    -- MultiTycoonClient callbacks
    if clientState.multiTycoonClient then
        clientState.multiTycoonClient:SetOnTycoonDataUpdate(function(data)
            self:OnTycoonDataUpdate(data)
        end)
        
        clientState.multiTycoonClient:SetOnPlotSwitchResponse(function(data)
            self:OnPlotSwitchResponse(data)
        end)
        
        clientState.multiTycoonClient:SetOnBonusUpdate(function(bonuses)
            self:OnCrossTycoonBonusUpdate(bonuses)
        end)
    end
    
    -- CrossTycoonClient callbacks
    if clientState.crossTycoonClient then
        clientState.crossTycoonClient:SetOnAbilityUpdate(function(abilityId, newLevel)
            self:OnAbilityUpdate(abilityId, newLevel)
        end)
        
        clientState.crossTycoonClient:SetOnProgressionSync(function(data)
            self:OnProgressionSync(data)
        end)
        
        clientState.crossTycoonClient:SetOnAbilityTheft(function(data)
            self:OnAbilityTheft(data)
        end)
        
        clientState.crossTycoonClient:SetOnEconomyUpdate(function(bonuses)
            self:OnEconomyUpdate(bonuses)
        end)
    end
    
    -- AdvancedPlotClient callbacks
    if clientState.advancedPlotClient then
        clientState.advancedPlotClient:SetOnPlotUpgradeResponse(function(data)
            self:OnPlotUpgradeResponse(data)
        end)
        
        clientState.advancedPlotClient:SetOnThemeChangeResponse(function(data)
            self:OnThemeChangeResponse(data)
        end)
        
        clientState.advancedPlotClient:SetOnDecorationUpdate(function(data)
            self:OnPlotDecorationUpdate(data)
        end)
        
        clientState.advancedPlotClient:SetOnPrestigeUpdate(function(data)
            self:OnPlotPrestigeUpdate(data)
        end)
    end
    
    print("Milestone 2 callbacks set up successfully!")
end

-- NEW: Setup Milestone 3 callbacks and integration
function MainClient:SetupMilestone3Callbacks()
    print("Setting up Milestone 3 callbacks...")
    
    -- CompetitiveManager callbacks
    if clientState.competitiveManager then
        clientState.competitiveManager:SetOnRankUpdate(function(rank)
            self:OnCompetitiveRankUpdate(rank)
        end)
        
        clientState.competitiveManager:SetOnAchievementUpdate(function(points)
            self:OnAchievementPointsUpdate(points)
        end)
        
        clientState.competitiveManager:SetOnPrestigeUpdate(function(data)
            self:OnPrestigeUpdate(data)
        end)
    end
    
    -- GuildSystem callbacks
    if clientState.guildSystem then
        clientState.guildSystem:SetOnGuildDataUpdate(function(data)
            self:OnGuildDataUpdate(data)
        end)
        
        clientState.guildSystem:SetOnRoleUpdate(function(role)
            self:OnGuildRoleUpdate(role)
        end)
        
        clientState.guildSystem:SetOnMemberUpdate(function(member)
            self:OnGuildMemberUpdate(member)
        end)
    end
    
    -- TradingSystem callbacks
    if clientState.tradingSystem then
        clientState.tradingSystem:SetOnTradeOffer(function(offer)
            self:OnTradeOffer(offer)
        end)
        
        clientState.tradingSystem:SetOnTradeAccepted(function(offer)
            self:OnTradeAccepted(offer)
        end)
        
        clientState.tradingSystem:SetOnTradeDeclined(function(offer)
            self:OnTradeDeclined(offer)
        end)
    end
    
    -- SocialSystem callbacks
    if clientState.socialSystem then
        clientState.socialSystem:SetOnFriendRequest(function(request)
            self:OnFriendRequest(request)
        end)
        
        clientState.socialSystem:SetOnFriendAccepted(function(request)
            self:OnFriendAccepted(request)
        end)
        
        clientState.socialSystem:SetOnFriendDeclined(function(request)
            self:OnFriendDeclined(request)
        end)
    end
    
    -- SecurityManager callbacks
    if clientState.securityManager then
        clientState.securityManager:SetOnSecurityStatusUpdate(function(status)
            self:OnSecurityStatusUpdate(status)
        end)
    end
    
    print("Milestone 3 callbacks set up successfully!")
end

-- Create main UI (simplified for hub system)
function MainClient:CreateMainUI()
    -- Create main ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MainHubUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = clientState.playerGui
    
    -- Create basic hub info display
    self:CreateHubInfoDisplay(screenGui)
    
    -- Create player status display
    self:CreatePlayerStatusDisplay(screenGui)
    
    -- Create help button
    self:CreateHelpButton(screenGui)
    
    -- NEW: Create performance monitoring display (Roblox best practice)
    self:CreatePerformanceDisplay(screenGui)
end

-- Create hub info display
function MainClient:CreateHubInfoDisplay(parent)
    local frame = Instance.new("Frame")
    frame.Name = "HubInfoDisplay"
    frame.Size = UDim2.new(0, 250, 0, 100)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = parent
    
    -- Add title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Tycoon Hub"
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = frame
    
    -- Add player count
    local playerCountLabel = Instance.new("TextLabel")
    playerCountLabel.Size = UDim2.new(1, 0, 0, 25)
    playerCountLabel.Position = UDim2.new(0, 0, 0, 30)
    playerCountLabel.BackgroundTransparency = 1
    playerCountLabel.Text = "Players: 0"
    playerCountLabel.TextColor3 = Color3.new(1, 1, 1)
    playerCountLabel.TextScaled = true
    playerCountLabel.Font = Enum.Font.Gotham
    playerCountLabel.Parent = frame
    
    -- Add plot info
    local plotInfoLabel = Instance.new("TextLabel")
    plotInfoLabel.Size = UDim2.new(1, 0, 0, 25)
    plotInfoLabel.Position = UDim2.new(0, 0, 0, 55)
    plotInfoLabel.BackgroundTransparency = 1
    plotInfoLabel.Text = "Plots: 0/20 Available"
    plotInfoLabel.TextColor3 = Color3.new(1, 1, 1)
    plotInfoLabel.TextScaled = true
    plotInfoLabel.Font = Enum.Font.Gotham
    plotInfoLabel.Parent = frame
    
    -- Store references for updates
    clientState.hubInfoDisplay = {
        frame = frame,
        playerCount = playerCountLabel,
        plotInfo = plotInfoLabel
    }
end

-- Create player status display
function MainClient:CreatePlayerStatusDisplay(parent)
    local frame = Instance.new("Frame")
    frame.Name = "PlayerStatusDisplay"
    frame.Size = UDim2.new(0, 200, 0, 80)
    frame.Position = UDim2.new(1, -210, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = parent
    
    -- Add cash display
    local cashLabel = Instance.new("TextLabel")
    cashLabel.Size = UDim2.new(1, 0, 0, 25)
    cashLabel.Position = UDim2.new(0, 0, 0, 0)
    cashLabel.BackgroundTransparency = 1
    cashLabel.Text = "Cash: $0"
    cashLabel.TextColor3 = Color3.new(1, 1, 1)
    cashLabel.TextScaled = true
    cashLabel.Font = Enum.Font.GothamBold
    cashLabel.Parent = frame
    
    -- Add level display
    local levelLabel = Instance.new("TextLabel")
    levelLabel.Size = UDim2.new(1, 0, 0, 25)
    levelLabel.Position = UDim2.new(0, 0, 0, 25)
    levelLabel.BackgroundTransparency = 1
    levelLabel.Text = "Level: 1"
    levelLabel.TextColor3 = Color3.new(1, 1, 1)
    levelLabel.TextScaled = true
    levelLabel.Font = Enum.Font.Gotham
    levelLabel.Parent = frame
    
    -- Add plot status
    local plotStatusLabel = Instance.new("TextLabel")
    plotStatusLabel.Size = UDim2.new(1, 0, 0, 25)
    plotStatusLabel.Position = UDim2.new(0, 0, 0, 50)
    plotStatusLabel.BackgroundTransparency = 1
    plotStatusLabel.Text = "Plot: None"
    plotStatusLabel.TextColor3 = Color3.new(1, 1, 1)
    plotStatusLabel.TextScaled = true
    plotStatusLabel.Font = Enum.Font.Gotham
    plotStatusLabel.Parent = frame
    
    -- Store references for updates
    clientState.playerStatusDisplay = {
        frame = frame,
        cash = cashLabel,
        level = levelLabel,
        plotStatus = plotStatusLabel
    }
end

-- Create help button
function MainClient:CreateHelpButton(parent)
    local button = Instance.new("TextButton")
    button.Name = "HelpButton"
    button.Size = UDim2.new(0, 60, 0, 30)
    button.Position = UDim2.new(1, -70, 1, -40)
    button.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
    button.Text = "Help"
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextScaled = true
    button.Font = Enum.Font.GothamBold
    button.Parent = parent
    
    -- Add click handler
    button.MouseButton1Click:Connect(function()
        self:ShowHelp()
    end)
end

-- Show help information
function MainClient:ShowHelp()
    local helpMessage = [[
🎮 Tycoon Hub - Milestone 3

Welcome to the multiplayer tycoon hub!

🏠 Hub Features:
• 20 unique tycoon plots available
• Choose from different themes
• Interact with other players
• Steal abilities from others

🎯 How to Play:
1. Walk around the hub to see plots
2. Click on an available plot to claim it
3. Build and upgrade your tycoon
4. Interact with other players
5. Steal abilities to become stronger

💡 Tips:
• Plots are first-come, first-served
• You can only own one plot at a time
• Stay near other players to steal abilities
• Use the hub to find friends and trade

🔧 Debug Commands:
• Press P for plot menu
• Press H to toggle hub UI
• Type "/perf" in chat for performance metrics
• Type "/memory" in chat for memory usage

Good luck building your tycoon empire!
    ]]
    
    -- Create help popup
    HelperFunctions.CreateNotification(clientState.player, helpMessage, 10)
end

-- Set up input handling
function MainClient:SetupInputHandling()
    -- Toggle hub UI with H key
    connections.inputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.H then
            self:ToggleHubUI()
        elseif input.KeyCode == Enum.KeyCode.P then
            self:ShowPlotMenu()
        end
    end)
    
    -- NEW: Chat command handling for performance monitoring (Roblox best practice)
    if clientState.player then
        connections.chatted = clientState.player.Chatted:Connect(function(message)
            self:HandleChatCommand(message)
        end)
    end
end

-- NEW: Handle chat commands for debugging (Roblox best practice)
function MainClient:HandleChatCommand(message)
    local command = string.lower(message)
    
    if command == "/perf" or command == "/performance" then
        self:ShowPerformanceMetrics()
    elseif command == "/memory" then
        self:ShowMemoryUsage()
    elseif command == "/health" then
        self:ShowSystemHealth()
    elseif command == "/debug" then
        self:ShowDebugInfo()
    end
end

-- NEW: Show performance metrics in chat (Roblox best practice)
function MainClient:ShowPerformanceMetrics()
    local metrics = self:GetPerformanceMetrics()
    local message = string.format(
        "📊 Performance Metrics:\n" ..
        "• Performance Score: %d/100\n" ..
        "• System Health: %d/100\n" ..
        "• Average Update Time: %.3fms\n" ..
        "• Total Updates: %d",
        metrics.summary.performanceScore,
        metrics.current.systemHealth,
        metrics.current.averageUpdateTime * 1000,
        metrics.summary.totalUpdates
    )
    
    HelperFunctions.CreateNotification(clientState.player, message, 8)
end

-- NEW: Show memory usage in chat (Roblox best practice)
function MainClient:ShowMemoryUsage()
    local memory = self:GetMemoryUsage()
    local trend = self:GetMemoryUsageTrend()
    local message = string.format(
        "💾 Memory Usage:\n" ..
        "• Total: %d bytes\n" ..
        "• Client State: %d bytes\n" ..
        "• Systems: %d bytes\n" ..
        "• Trend: %s",
        memory.total,
        memory.clientState,
        memory.systems,
        trend
    )
    
    HelperFunctions.CreateNotification(clientState.player, message, 8)
end

-- NEW: Show system health in chat (Roblox best practice)
function MainClient:ShowSystemHealth()
    local health = performanceMetrics.systemHealth
    local trend = self:CalculateSystemHealthTrend()
    local recommendations = self:GetPerformanceRecommendations()
    
    local message = string.format(
        "🏥 System Health: %d/100 (%s)\n" ..
        "💡 Recommendations:\n%s",
        health,
        trend,
        table.concat(recommendations, "\n• ")
    )
    
    HelperFunctions.CreateNotification(clientState.player, message, 10)
end

-- NEW: Show comprehensive debug info (Roblox best practice)
function MainClient:ShowDebugInfo()
    local debugInfo = self:GetDetailedPerformanceReport()
    local message = string.format(
        "🔍 Debug Information:\n" ..
        "• Performance Score: %d/100\n" ..
        "• System Health: %d/100 (%s)\n" ..
        "• Memory Trend: %s\n" ..
        "• Update Time: %.3fms\n" ..
        "• Memory Usage: %d bytes",
        debugInfo.performanceScore,
        debugInfo.currentMetrics.current.systemHealth,
        debugInfo.systemHealthTrend,
        debugInfo.memoryTrend,
        debugInfo.currentMetrics.current.averageUpdateTime * 1000,
        debugInfo.currentMetrics.current.memoryUsage.total
    )
    
    HelperFunctions.CreateNotification(clientState.player, message, 12)
end

-- NEW: Create performance monitoring display (Roblox best practice)
function MainClient:CreatePerformanceDisplay(parent)
    local frame = Instance.new("Frame")
    frame.Name = "PerformanceDisplay"
    frame.Size = UDim2.new(0, 200, 0, 120)
    frame.Position = UDim2.new(0, 10, 1, -130)
    frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = parent
    
    -- Add title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 25)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🔧 Performance Monitor"
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = frame
    
    -- Add performance score
    local scoreLabel = Instance.new("TextLabel")
    scoreLabel.Size = UDim2.new(1, 0, 0, 20)
    scoreLabel.Position = UDim2.new(0, 0, 0, 25)
    scoreLabel.BackgroundTransparency = 1
    scoreLabel.Text = "Score: 0/100"
    scoreLabel.TextColor3 = Color3.new(1, 1, 0)
    scoreLabel.TextScaled = true
    scoreLabel.Font = Enum.Font.Gotham
    scoreLabel.Parent = frame
    
    -- Add system health
    local healthLabel = Instance.new("TextLabel")
    healthLabel.Size = UDim2.new(1, 0, 0, 20)
    healthLabel.Position = UDim2.new(0, 0, 0, 45)
    healthLabel.BackgroundTransparency = 1
    healthLabel.Text = "Health: 100/100"
    healthLabel.TextColor3 = Color3.new(0, 1, 0)
    healthLabel.TextScaled = true
    healthLabel.Font = Enum.Font.Gotham
    healthLabel.Parent = frame
    
    -- Add memory usage
    local memoryLabel = Instance.new("TextLabel")
    memoryLabel.Size = UDim2.new(1, 0, 0, 20)
    memoryLabel.Position = UDim2.new(0, 0, 0, 65)
    memoryLabel.BackgroundTransparency = 1
    memoryLabel.Text = "Memory: 0 bytes"
    memoryLabel.TextColor3 = Color3.new(1, 0.5, 0)
    memoryLabel.TextScaled = true
    memoryLabel.Font = Enum.Font.Gotham
    memoryLabel.Parent = frame
    
    -- Add update time
    local updateLabel = Instance.new("TextLabel")
    updateLabel.Size = UDim2.new(1, 0, 0, 20)
    updateLabel.Position = UDim2.new(0, 0, 0, 85)
    updateLabel.BackgroundTransparency = 1
    updateLabel.Text = "Update: 0ms"
    updateLabel.TextColor3 = Color3.new(0.5, 0.5, 1)
    updateLabel.TextScaled = true
    updateLabel.Font = Enum.Font.Gotham
    updateLabel.Parent = frame
    
    -- Store references for updates
    clientState.performanceDisplay = {
        frame = frame,
        score = scoreLabel,
        health = healthLabel,
        memory = memoryLabel,
        update = updateLabel
    }
    
    -- Make it toggleable with right-click
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            frame.Visible = not frame.Visible
        end
    end)
end

-- Toggle hub UI visibility
function MainClient:ToggleHubUI()
    if clientState.hubUI then
        clientState.hubUI:ToggleVisibility()
    end
end

-- Show plot selection menu
function MainClient:ShowPlotMenu()
    if clientState.plotSelector then
        -- This will be handled by the PlotSelector when a plot is clicked
        print("Plot selection is handled by clicking on plots in the hub")
    end
end

-- Set up player monitoring
function MainClient:SetupPlayerMonitoring()
    print("Setting up player monitoring...")
    
    -- NEW: Use UpdateManager instead of direct RunService connections
    updateManager:RegisterUpdate(
        function(deltaTime)
            self:UpdatePerformanceMetrics()
            self:UpdatePlayerDisplay()
        end,
        2, -- HIGH priority
        "PlayerMonitoring",
        0.5 -- Every 500ms instead of every frame
    )
    
    print("Player monitoring initialized successfully!")
end

-- Update player display
function MainClient:UpdatePlayerDisplay()
    if not clientState.playerStatusDisplay then return end
    
    -- Update cash display
    if clientState.playerStatusDisplay.cash then
        clientState.playerStatusDisplay.cash.Text = "Cash: $" .. clientState.playerData.Cash
    end
    
    -- Update level display
    if clientState.playerStatusDisplay.level then
        clientState.playerStatusDisplay.level.Text = "Level: " .. clientState.playerData.Level
    end
    
    -- Update plot status
    if clientState.playerStatusDisplay.plotStatus then
        local plotText = clientState.playerData.CurrentPlot and "Plot: " .. clientState.playerData.CurrentPlot or "Plot: None"
        clientState.playerStatusDisplay.plotStatus.Text = plotText
    end
    
    -- NEW: Update performance display (Roblox best practice)
    self:UpdatePerformanceDisplay()
end

-- NEW: Update performance monitoring display (Roblox best practice)
function MainClient:UpdatePerformanceDisplay()
    if not clientState.performanceDisplay then return end
    
    -- Update performance score
    if clientState.performanceDisplay.score then
        local score = self:CalculatePerformanceScore()
        clientState.performanceDisplay.score.Text = "Score: " .. score .. "/100"
        
        -- Color code based on score
        if score >= 80 then
            clientState.performanceDisplay.score.TextColor3 = Color3.new(0, 1, 0) -- Green
        elseif score >= 60 then
            clientState.performanceDisplay.score.TextColor3 = Color3.new(1, 1, 0) -- Yellow
        else
            clientState.performanceDisplay.score.TextColor3 = Color3.new(1, 0, 0) -- Red
        end
    end
    
    -- Update system health
    if clientState.performanceDisplay.health then
        local health = performanceMetrics.systemHealth
        clientState.performanceDisplay.health.Text = "Health: " .. health .. "/100"
        
        -- Color code based on health
        if health >= 80 then
            clientState.performanceDisplay.health.TextColor3 = Color3.new(0, 1, 0) -- Green
        elseif health >= 60 then
            clientState.performanceDisplay.health.TextColor3 = Color3.new(1, 1, 0) -- Yellow
        else
            clientState.performanceDisplay.health.TextColor3 = Color3.new(1, 0, 0) -- Red
        end
    end
    
    -- Update memory usage
    if clientState.performanceDisplay.memory then
        local memory = performanceMetrics.memoryUsage.total
        local memoryText = "Memory: " .. memory .. " bytes"
        
        -- Format large numbers
        if memory > 1000000 then
            memoryText = string.format("Memory: %.1f MB", memory / 1000000)
        elseif memory > 1000 then
            memoryText = string.format("Memory: %.1f KB", memory / 1000)
        end
        
        clientState.performanceDisplay.memory.Text = memoryText
        
        -- Color code based on memory usage
        if memory < 1000 then
            clientState.performanceDisplay.memory.TextColor3 = Color3.new(0, 1, 0) -- Green
        elseif memory < 5000 then
            clientState.performanceDisplay.memory.TextColor3 = Color3.new(1, 1, 0) -- Yellow
        else
            clientState.performanceDisplay.memory.TextColor3 = Color3.new(1, 0, 0) -- Red
        end
    end
    
    -- Update update time
    if clientState.performanceDisplay.update then
        local updateTime = performanceMetrics.averageUpdateTime * 1000 -- Convert to milliseconds
        clientState.performanceDisplay.update.Text = string.format("Update: %.1fms", updateTime)
        
        -- Color code based on update time (target: < 16ms for 60 FPS)
        if updateTime < 16 then
            clientState.performanceDisplay.update.TextColor3 = Color3.new(0, 1, 0) -- Green
        elseif updateTime < 33 then
            clientState.performanceDisplay.update.TextColor3 = Color3.new(1, 1, 0) -- Yellow
        else
            clientState.performanceDisplay.update.TextColor3 = Color3.new(1, 0, 0) -- Red
        end
    end
end

-- Update hub info display
function MainClient:UpdateHubInfoDisplay()
    if not clientState.hubInfoDisplay then return end
    
    -- Update player count
    if clientState.hubInfoDisplay.playerCount then
        clientState.hubInfoDisplay.playerCount.Text = "Players: " .. clientState.hubData.PlayerCount
    end
    
    -- Update plot info
    if clientState.hubInfoDisplay.plotInfo then
        local availablePlots = #clientState.hubData.AvailablePlots
        clientState.hubInfoDisplay.plotInfo.Text = "Plots: " .. availablePlots .. "/20 Available"
    end
end

-- Get client state info
function MainClient:GetClientState()
    return {
        isInitialized = clientState.isInitialized,
        player = clientState.player and clientState.player.Name or "Unknown",
        hubUI = clientState.hubUI ~= nil,
        plotSelector = clientState.plotSelector ~= nil,
        -- Milestone 2 systems
        multiTycoonClient = clientState.multiTycoonClient ~= nil,
        crossTycoonClient = clientState.crossTycoonClient ~= nil,
        advancedPlotClient = clientState.advancedPlotClient ~= nil,
        -- NEW: Milestone 3 systems
        competitiveManager = clientState.competitiveManager ~= nil,
        guildSystem = clientState.guildSystem ~= nil,
        tradingSystem = clientState.tradingSystem ~= nil,
        socialSystem = clientState.socialSystem ~= nil,
        securityManager = clientState.securityManager ~= nil,
        playerData = clientState.playerData,
        -- NEW: Performance monitoring info (Roblox best practice)
        performanceMetrics = {
            systemHealth = performanceMetrics.systemHealth,
            performanceScore = self:CalculatePerformanceScore(),
            memoryUsage = performanceMetrics.memoryUsage.total,
            updateTime = performanceMetrics.averageUpdateTime
        }
    }
end

-- NEW: Milestone 2 Callback Handlers

function MainClient:OnTycoonDataUpdate(data)
    if not data then return end
    
    -- Update client state
    clientState.playerData.OwnedTycoons = data.ownedTycoons or {}
    clientState.playerData.CurrentPlot = data.currentTycoon
    clientState.playerData.CrossTycoonBonuses = data.crossTycoonBonuses or {}
    clientState.playerData.PlotSwitchCooldown = data.plotSwitchCooldown or 0
    
    print("MainClient: Tycoon data updated, owned tycoons: " .. #clientState.playerData.OwnedTycoons)
    
    -- Update UI if available
    if clientState.hubUI then
        -- Trigger UI update for multi-tycoon information
        clientState.hubUI:UpdateMultiTycoonInfo(data)
    end
end

function MainClient:OnPlotSwitchResponse(data)
    if not data then return end
    
    if data.success then
        print("MainClient: Successfully switched to tycoon " .. data.targetTycoonId)
        clientState.playerData.CurrentPlot = data.targetTycoonId
        clientState.playerData.PlotSwitchCooldown = data.cooldownRemaining or 0
    else
        print("MainClient: Failed to switch tycoons, cooldown remaining: " .. data.cooldownRemaining)
        clientState.playerData.PlotSwitchCooldown = data.cooldownRemaining or 0
    end
    
    -- Update UI if available
    if clientState.hubUI then
        clientState.hubUI:OnPlotSwitchResponse(data)
    end
end

function MainClient:OnCrossTycoonBonusUpdate(bonuses)
    if not bonuses then return end
    
    clientState.playerData.CrossTycoonBonuses = bonuses
    
    print("MainClient: Cross-tycoon bonuses updated, total bonus: " .. (bonuses.totalBonus or 0))
    
    -- Update UI if available
    if clientState.hubUI then
        clientState.hubUI:UpdateCrossTycoonBonuses(bonuses)
    end
end

function MainClient:OnAbilityUpdate(abilityId, newLevel)
    if not abilityId or not newLevel then return end
    
    -- Update ability level in player data
    clientState.playerData.Abilities[abilityId] = newLevel
    
    print("MainClient: Ability " .. abilityId .. " updated to level " .. newLevel)
    
    -- Update UI if available
    if clientState.hubUI then
        clientState.hubUI:UpdateAbilityDisplay(abilityId, newLevel)
    end
end

function MainClient:OnProgressionSync(data)
    if not data then return end
    
    print("MainClient: Received progression sync")
    
    -- Update UI if available
    if clientState.hubUI then
        clientState.hubUI:UpdateProgressionDisplay(data)
    end
end

function MainClient:OnAbilityTheft(data)
    if not data then return end
    
    print("MainClient: Ability theft event - " .. (data.stealerName or "Unknown") .. " stole " .. (data.abilityId or "Unknown"))
    
    -- Update UI if available
    if clientState.hubUI then
        clientState.hubUI:ShowAbilityTheftNotification(data)
    end
end

function MainClient:OnEconomyUpdate(bonuses)
    if not bonuses then return end
    
    print("MainClient: Economy bonuses updated")
    
    -- Update UI if available
    if clientState.hubUI then
        clientState.hubUI:UpdateEconomyDisplay(bonuses)
    end
end

function MainClient:OnPlotUpgradeResponse(data)
    if not data then return end
    
    print("MainClient: Plot upgrade response received for plot " .. (data.plotId or "Unknown"))
    
    -- Update UI if available
    if clientState.hubUI then
        clientState.hubUI:OnPlotUpgradeResponse(data)
    end
end

function MainClient:OnThemeChangeResponse(data)
    if not data then return end
    
    print("MainClient: Theme change response received for plot " .. (data.plotId or "Unknown"))
    
    -- Update UI if available
    if clientState.hubUI then
        clientState.hubUI:OnThemeChangeResponse(data)
    end
end

function MainClient:OnPlotDecorationUpdate(data)
    if not data then return end
    
    print("MainClient: Plot decoration update received for plot " .. (data.plotId or "Unknown"))
    
    -- Update UI if available
    if clientState.hubUI then
        clientState.hubUI:OnPlotDecorationUpdate(data)
    end
end

function MainClient:OnPlotPrestigeUpdate(data)
    if not data then return end
    
    print("MainClient: Plot prestige update received for plot " .. (data.plotId or "Unknown"))
    
    -- Update UI if available
    if clientState.hubUI then
        clientState.hubUI:OnPlotPrestigeUpdate(data)
    end
end

-- NEW: Milestone 3 Callback Handlers

function MainClient:OnCompetitiveRankUpdate(rank)
    if not rank then return end
    
    clientState.playerData.CompetitiveRank = rank
    print("MainClient: Competitive rank updated to " .. rank)
    
    -- Update UI if available
    if clientState.hubUI then
        clientState.hubUI:UpdateCompetitiveRank(rank)
    end
end

function MainClient:OnAchievementPointsUpdate(points)
    if not points then return end
    
    clientState.playerData.AchievementPoints = points
    print("MainClient: Achievement points updated to " .. points)
    
    -- Update UI if available
    if clientState.hubUI then
        clientState.hubUI:UpdateAchievementPoints(points)
    end
end

function MainClient:OnPrestigeUpdate(data)
    if not data then return end
    
    clientState.playerData.PrestigeLevel = data.prestigeLevel or 0
    print("MainClient: Prestige level updated to " .. (data.prestigeLevel or 0))
    
    -- Update UI if available
    if clientState.hubUI then
        clientState.hubUI:UpdatePrestigeLevel(data.prestigeLevel or 0)
    end
end

function MainClient:OnGuildDataUpdate(data)
    if not data then return end
    
    clientState.playerData.GuildId = data.guildId
    clientState.playerData.GuildRole = data.role
    print("MainClient: Guild data updated, GuildId: " .. (data.guildId or "None"), "Role: " .. (data.role or "None"))
    
    -- Update UI if available
    if clientState.hubUI then
        clientState.hubUI:UpdateGuildInfo(data)
    end
end

function MainClient:OnGuildRoleUpdate(role)
    if not role then return end
    
    clientState.playerData.GuildRole = role
    print("MainClient: Guild role updated to " .. role)
    
    -- Update UI if available
    if clientState.hubUI then
        clientState.hubUI:UpdateGuildRole(role)
    end
end

function MainClient:OnGuildMemberUpdate(member)
    if not member then return end
    
    -- Add member to friend list if they are a friend
    if member.isFriend then
        table.insert(clientState.playerData.FriendList, member)
        print("MainClient: Added friend " .. member.name)
    end
    print("MainClient: Guild member updated: " .. member.name .. " (Friend: " .. tostring(member.isFriend) .. ")")
    
    -- Update UI if available
    if clientState.hubUI then
        clientState.hubUI:UpdateGuildMember(member)
    end
end

function MainClient:OnTradeOffer(offer)
    if not offer then return end
    
    print("MainClient: Received trade offer from " .. offer.senderName .. " for " .. offer.itemName .. " at " .. offer.price .. " cash")
    
    -- Update UI if available
    if clientState.hubUI then
        clientState.hubUI:ShowTradeOffer(offer)
    end
end

function MainClient:OnTradeAccepted(offer)
    if not offer then return end
    
    print("MainClient: Trade offer from " .. offer.senderName .. " accepted for " .. offer.itemName)
    
    -- Update UI if available
    if clientState.hubUI then
        clientState.hubUI:OnTradeAccepted(offer)
    end
end

function MainClient:OnTradeDeclined(offer)
    if not offer then return end
    
    print("MainClient: Trade offer from " .. offer.senderName .. " declined")
    
    -- Update UI if available
    if clientState.hubUI then
        clientState.hubUI:OnTradeDeclined(offer)
    end
end

function MainClient:OnFriendRequest(request)
    if not request then return end
    
    print("MainClient: Received friend request from " .. request.senderName)
    
    -- Update UI if available
    if clientState.hubUI then
        clientState.hubUI:ShowFriendRequest(request)
    end
end

function MainClient:OnFriendAccepted(request)
    if not request then return end
    
    print("MainClient: Friend request from " .. request.senderName .. " accepted")
    
    -- Update UI if available
    if clientState.hubUI then
        clientState.hubUI:OnFriendAccepted(request)
    end
end

function MainClient:OnFriendDeclined(request)
    if not request then return end
    
    print("MainClient: Friend request from " .. request.senderName .. " declined")
    
    -- Update UI if available
    if clientState.hubUI then
        clientState.hubUI:OnFriendDeclined(request)
    end
end

function MainClient:OnSecurityStatusUpdate(status)
    if not status then return end
    
    clientState.playerData.SecurityStatus = status
    print("MainClient: Security status updated to " .. status)
    
    -- Update UI if available
    if clientState.hubUI then
        clientState.hubUI:UpdateSecurityStatus(status)
    end
end

-- Public API for Milestone 2 features

function MainClient:RequestPlotSwitch(targetTycoonId)
    -- NEW: Input validation (Roblox security best practice)
    if not targetTycoonId or type(targetTycoonId) ~= "string" then
        warn("Invalid tycoon ID for plot switch")
        return false
    end
    
    if clientState.multiTycoonClient then
        return clientState.multiTycoonClient:RequestPlotSwitch(targetTycoonId)
    end
    return false
end

function MainClient:RequestAbilityUpgrade(abilityId)
    -- NEW: Input validation
    if not abilityId or type(abilityId) ~= "string" then
        warn("Invalid ability ID for upgrade")
        return false
    end
    
    if clientState.crossTycoonClient then
        return clientState.crossTycoonClient:RequestAbilityUpgrade(abilityId)
    end
    return false
end

function MainClient:RequestPlotUpgrade(plotId, upgradeType)
    -- NEW: Input validation
    if not plotId or not upgradeType then
        warn("Invalid plot upgrade parameters")
        return false
    end
    
    if clientState.advancedPlotClient then
        return clientState.advancedPlotClient:RequestPlotUpgrade(plotId, upgradeType)
    end
    return false
end

function MainClient:RequestThemeChange(plotId, newTheme)
    -- NEW: Input validation
    if not plotId or not newTheme then
        warn("Invalid theme change parameters")
        return false
    end
    
    if clientState.advancedPlotClient then
        return clientState.advancedPlotClient:RequestThemeChange(plotId, newTheme)
    end
    return false
end

function MainClient:GetOwnedTycoons()
    if clientState.multiTycoonClient then
        return clientState.multiTycoonClient:GetOwnedTycoons()
    end
    return {}
end

function MainClient:GetCrossTycoonBonuses()
    if clientState.multiTycoonClient then
        return clientState.multiTycoonClient:GetCrossTycoonBonuses()
    end
    return {}
end

function MainClient:GetSharedAbilities()
    if clientState.crossTycoonClient then
        return clientState.crossTycoonClient:GetSharedAbilities()
    end
    return {}
end

function MainClient:GetPlotStats(plotId)
    if clientState.advancedPlotClient then
        return clientState.advancedPlotClient:GetPlotStats(plotId)
    end
    return nil
end

-- NEW: Public API for Milestone 3 features
function MainClient:GetCompetitiveManager()
    return clientState.competitiveManager
end

function MainClient:GetGuildSystem()
    return clientState.guildSystem
end

function MainClient:GetTradingSystem()
    return clientState.tradingSystem
end

function MainClient:GetSocialSystem()
    return clientState.socialSystem
end

function MainClient:GetSecurityManager()
    return clientState.securityManager
end

-- Competitive system methods
function MainClient:GetPlayerRank()
    return clientState.playerData.CompetitiveRank
end

function MainClient:GetAchievementPoints()
    return clientState.playerData.AchievementPoints
end

function MainClient:GetPrestigeLevel()
    return clientState.playerData.PrestigeLevel
end

-- Guild system methods
function MainClient:GetGuildId()
    return clientState.playerData.GuildId
end

function MainClient:GetGuildRole()
    return clientState.playerData.GuildRole
end

function MainClient:IsInGuild()
    return clientState.playerData.GuildId ~= nil
end

-- Social system methods
function MainClient:GetFriendList()
    return clientState.playerData.FriendList
end

function MainClient:IsFriend(playerName)
    for _, friend in ipairs(clientState.playerData.FriendList) do
        if friend.name == playerName then
            return true
        end
    end
    return false
end

-- Trading system methods
function MainClient:GetTradeHistory()
    return clientState.playerData.TradeHistory
end

-- Security system methods
function MainClient:GetSecurityStatus()
    return clientState.playerData.SecurityStatus
end

-- NEW: Performance monitoring API (Roblox best practice)
function MainClient:GetPerformanceMetrics()
    return self:GetPerformanceMetrics()
end

function MainClient:GetMemoryUsage()
    return self:GetMemoryUsage()
end

function MainClient:GetSystemHealth()
    return performanceMetrics.systemHealth
end

function MainClient:GetPerformanceScore()
    return self:CalculatePerformanceScore()
end

function MainClient:GetPerformanceTrend()
    return {
        systemHealth = self:CalculateSystemHealthTrend(),
        memoryUsage = self:CalculateAverageMemoryUsage(),
        updateTime = performanceMetrics.averageUpdateTime
    }
end

function MainClient:TakeMemorySnapshot()
    return self:TakeMemorySnapshot()
end

function MainClient:GetMemoryUsageTrend()
    return self:GetMemoryUsageTrend()
end

function MainClient:GetDetailedPerformanceReport()
    return {
        currentMetrics = self:GetPerformanceMetrics(),
        memoryTrend = self:GetMemoryUsageTrend(),
        systemHealthTrend = self:CalculateSystemHealthTrend(),
        performanceScore = self:CalculatePerformanceScore(),
        recommendations = self:GetPerformanceRecommendations()
    }
end

function MainClient:GetPerformanceRecommendations()
    local recommendations = {}
    
    if performanceMetrics.averageUpdateTime > 0.033 then
        table.insert(recommendations, "Consider reducing update frequency to improve performance")
    end
    
    if performanceMetrics.systemHealth < 70 then
        table.insert(recommendations, "System health is low - check for memory leaks or heavy operations")
    end
    
    if performanceMetrics.memoryUsage.total > 5000 then
        table.insert(recommendations, "Memory usage is high - consider cleanup of unused resources")
    end
    
    if #recommendations == 0 then
        table.insert(recommendations, "Performance is optimal - no recommendations needed")
    end
    
    return recommendations
end

-- NEW: Cleanup method following Roblox best practices
function MainClient:Cleanup()
    print("MainClient: Cleaning up connections and resources...")
    
    -- NEW: Performance monitoring cleanup (Roblox best practice)
    print("MainClient: Final performance metrics before cleanup:")
    local finalMetrics = self:GetPerformanceMetrics()
    print("  - Final Performance Score:", finalMetrics.summary.performanceScore)
    print("  - Final System Health:", finalMetrics.current.systemHealth)
    print("  - Final Memory Usage:", finalMetrics.current.memoryUsage.total)
    print("  - Total Updates:", finalMetrics.summary.totalUpdates)
    
    -- NEW: Use ConnectionManager for proper cleanup
    connectionManager:DisposeAll()
    
    -- NEW: Use UpdateManager for proper cleanup
    updateManager:Cleanup()
    
    -- NEW: Use DataArchiver for proper cleanup
    dataArchiver:Cleanup()
    
    -- Disconnect all connections to prevent memory leaks
    for name, connection in pairs(connections) do
        if connection and typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
            print("Disconnected connection:", name)
        end
    end
    connections = {}
    
    -- Clean up child systems
    if clientState.hubUI then
        clientState.hubUI:Cleanup()
    end
    
    if clientState.plotSelector then
        clientState.plotSelector:Cleanup()
    end
    
    if clientState.multiTycoonClient then
        clientState.multiTycoonClient:Cleanup()
    end
    
    if clientState.crossTycoonClient then
        clientState.crossTycoonClient:Cleanup()
    end
    
    if clientState.advancedPlotClient then
        clientState.advancedPlotClient:Cleanup()
    end

    if clientState.competitiveManager then
        clientState.competitiveManager:Cleanup()
    end

    if clientState.guildSystem then
        clientState.guildSystem:Cleanup()
    end

    if clientState.tradingSystem then
        clientState.tradingSystem:Cleanup()
    end

    if clientState.socialSystem then
        clientState.socialSystem:Cleanup()
    end

    if clientState.securityManager then
        clientState.securityManager:Cleanup()
    end
    
    -- NEW: Clear performance monitoring data (Roblox best practice)
    performanceMetrics.updateTimes = {}
    performanceMetrics.memorySnapshots = {}
    performanceMetrics.performanceHistory = {}
    performanceMetrics.lastUpdate = 0
    performanceMetrics.averageUpdateTime = 0
    performanceMetrics.memoryUsage = 0
    performanceMetrics.systemHealth = 100
    
    -- Clear performance display references
    if clientState.performanceDisplay then
        clientState.performanceDisplay = nil
    end
    
    -- Reset state
    clientState.isInitialized = false
    print("MainClient: Cleanup completed")
end

-- NEW: Handle player leaving (Roblox best practice)
local function onPlayerRemoving()
    if MainClient.Cleanup then
        MainClient:Cleanup()
    end
end

-- Connect player leaving event
if clientState.player then
    connections.playerRemoving = clientState.player.AncestryChanged:Connect(function(_, parent)
        if not parent then
            onPlayerRemoving()
        end
    end)
end

-- Initialize when the script runs
MainClient:Initialize()

-- Return the MainClient for external use
return MainClient
