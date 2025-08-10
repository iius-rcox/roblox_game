-- MainClient.lua
-- Main client script for Milestone 1: Multiplayer Hub with Plot System

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(script.Parent.Parent.Utils.Constants)
local HelperFunctions = require(script.Parent.Parent.Utils.HelperFunctions)

-- New Hub and Multiplayer systems
local HubUI = require(script.Parent.Parent.Hub.HubUI)
local PlotSelector = require(script.Parent.Parent.Hub.PlotSelector)

local MainClient = {}

-- Client state for Milestone 1
local clientState = {
    isInitialized = false,
    player = Players.LocalPlayer,
    playerGui = nil,
    hubUI = nil,
    plotSelector = nil,
    playerData = {
        Cash = 0,
        Abilities = {},
        CurrentPlot = nil,
        Level = 1,
        Experience = 0
    },
    hubData = {
        AvailablePlots = {},
        PlayerCount = 0,
        IsInHub = true
    }
}

-- Initialize the client
function MainClient:Initialize()
    if clientState.isInitialized then return end
    
    print("Initializing Client - Milestone 1: Multiplayer Hub...")
    
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
    
    -- Initialize Hub UI
    self:InitializeHubUI()
    
    -- Initialize Plot Selector
    self:InitializePlotSelector()
    
    -- Set up input handling
    self:SetupInputHandling()
    
    -- Set up player monitoring
    self:SetupPlayerMonitoring()
    
    clientState.isInitialized = true
    print("Milestone 1 client initialized successfully!")
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
🎮 Tycoon Hub - Milestone 1

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

Good luck building your tycoon empire!
    ]]
    
    -- Create help popup
    HelperFunctions.CreateNotification(clientState.player, helpMessage, 10)
end

-- Set up input handling
function MainClient:SetupInputHandling()
    -- Toggle hub UI with H key
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.H then
            self:ToggleHubUI()
        elseif input.KeyCode == Enum.KeyCode.P then
            self:ShowPlotMenu()
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
    -- Monitor player data changes
    spawn(function()
        while true do
            wait(1)
            self:UpdatePlayerDisplay()
        end
    end)
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

-- Get client state
function MainClient:GetClientState()
    return {
        isInitialized = clientState.isInitialized,
        playerName = clientState.player and clientState.player.Name or "Unknown",
        hubUIActive = clientState.hubUI ~= nil,
        plotSelectorActive = clientState.plotSelector ~= nil,
        currentPlot = clientState.playerData.CurrentPlot,
        cash = clientState.playerData.Cash,
        level = clientState.playerData.Level
    }
end

-- Initialize when the script runs
MainClient:Initialize()

-- Return the MainClient for external use
return MainClient
