-- MainClient.lua
-- Main client script for Milestone 0: Single tycoon prototype

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(script.Parent.Parent.Utils.Constants)
local HelperFunctions = require(script.Parent.Parent.Utils.HelperFunctions)

local MainClient = {}

-- Client state
local clientState = {
    isInitialized = false,
    player = Players.LocalPlayer,
    playerGui = nil,
    mainUI = nil,
    cashDisplay = nil,
    abilityDisplay = nil,
    playerData = {
        Cash = 0,
        Abilities = {},
        CurrentTycoon = nil,
        Level = 1,
        Experience = 0
    },
    tycoonData = {
        TycoonId = nil,
        Owner = "None",
        Level = 1,
        CashGenerated = 0,
        IsActive = false
    },
    tycoonInfoDisplay = nil
}

-- Initialize the client
function MainClient:Initialize()
    if clientState.isInitialized then return end
    
    print("Initializing Client...")
    
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
    
    -- Create main UI
    self:CreateMainUI()
    
    -- Set up input handling
    self:SetupInputHandling()
    
    -- Set up player monitoring
    self:SetupPlayerMonitoring()
    
    clientState.isInitialized = true
    print("Client initialized successfully!")
end

-- Create main UI
function MainClient:CreateMainUI()
    -- Create main ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MainTycoonUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = clientState.playerGui
    
    clientState.mainUI = screenGui
    
    -- Create cash display
    self:CreateCashDisplay(screenGui)
    
    -- Create ability display
    self:CreateAbilityDisplay(screenGui)
    
    -- Create help button
    self:CreateHelpButton(screenGui)
end

-- Create cash display
function MainClient:CreateCashDisplay(parent)
    local frame = Instance.new("Frame")
    frame.Name = "CashDisplay"
    frame.Size = UDim2.new(0, 200, 0, 60)
    frame.Position = UDim2.new(1, -210, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = parent
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0.4, 0)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.Text = "CASH"
    titleLabel.TextScaled = true
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Parent = frame
    
    local cashLabel = Instance.new("TextLabel")
    cashLabel.Name = "CashLabel"
    cashLabel.Size = UDim2.new(1, 0, 0.6, 0)
    cashLabel.Position = UDim2.new(0, 0, 0.4, 0)
    cashLabel.Text = "$0"
    cashLabel.TextScaled = true
    cashLabel.BackgroundTransparency = 1
    cashLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    cashLabel.Font = Enum.Font.SourceSansBold
    cashLabel.Parent = frame
    
    clientState.cashDisplay = cashLabel
end

-- Create ability display
function MainClient:CreateAbilityDisplay(parent)
    local frame = Instance.new("Frame")
    frame.Name = "AbilityDisplay"
    frame.Size = UDim2.new(0, 200, 0, 120)
    frame.Position = UDim2.new(1, -210, 0, 80)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 255)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = parent
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim2.new(0, 8)
    corner.Parent = frame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0.2, 0)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.Text = "ABILITIES"
    titleLabel.TextScaled = true
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Parent = frame
    
    local abilityList = Instance.new("TextLabel")
    abilityList.Name = "AbilityList"
    abilityList.Size = UDim2.new(1, 0, 0.8, 0)
    abilityList.Position = UDim2.new(0, 0, 0.2, 0)
    abilityList.Text = "No abilities yet"
    abilityList.TextScaled = true
    abilityList.BackgroundTransparency = 1
    abilityList.TextColor3 = Color3.fromRGB(255, 255, 255)
    abilityList.Font = Enum.Font.SourceSans
    abilityList.TextWrapped = true
    abilityList.Parent = frame
    
    clientState.abilityDisplay = abilityList
    
    -- Create tycoon info display
    self:CreateTycoonInfoDisplay(parent)
end

-- Create tycoon info display
function MainClient:CreateTycoonInfoDisplay(parent)
    local frame = Instance.new("Frame")
    frame.Name = "TycoonInfoDisplay"
    frame.Size = UDim2.new(0, 200, 0, 100)
    frame.Position = UDim2.new(1, -210, 0, 210)
    frame.BackgroundColor3 = Color3.fromRGB(128, 0, 128)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = parent
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim2.new(0, 8)
    corner.Parent = frame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0.2, 0)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.Text = "TYCOON INFO"
    titleLabel.TextScaled = true
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Parent = frame
    
    local tycoonInfo = Instance.new("TextLabel")
    tycoonInfo.Name = "TycoonInfo"
    tycoonInfo.Size = UDim2.new(1, 0, 0.8, 0)
    tycoonInfo.Position = UDim2.new(0, 0, 0.2, 0)
    tycoonInfo.Text = "No tycoon assigned"
    tycoonInfo.TextScaled = true
    tycoonInfo.BackgroundTransparency = 1
    tycoonInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
    tycoonInfo.Font = Enum.Font.SourceSans
    tycoonInfo.TextWrapped = true
    tycoonInfo.Parent = frame
    
    clientState.tycoonInfoDisplay = tycoonInfo
end

-- Create help button
function MainClient:CreateHelpButton(parent)
    local button = Instance.new("TextButton")
    button.Name = "HelpButton"
    button.Size = UDim2.new(0, 50, 0, 50)
    button.Position = UDim2.new(0, 10, 0, 10)
    button.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
    button.BackgroundTransparency = 0.2
    button.BorderSizePixel = 0
    button.Text = "?"
    button.TextScaled = true
    button.TextColor3 = Color3.fromRGB(0, 0, 0)
    button.Font = Enum.Font.SourceSansBold
    button.Parent = parent
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 25)
    corner.Parent = button
    
    -- Handle click
    button.MouseButton1Click:Connect(function()
        self:ShowHelp()
    end)
end

-- Show help information
function MainClient:ShowHelp()
    local helpText = [[
TYCOON GAME HELP

CONTROLS:
- WASD: Move
- Space: Jump
- Click: Interact with buttons

FEATURES:
- Cash Generator: Earns money automatically
- Ability Buttons: Upgrade your abilities
- Walls: Protect your tycoon
- 3 Floors: Build up your empire

TIPS:
- Click ability buttons to upgrade
- Walls auto-repair over time
- Each tycoon can have one owner
- Save your progress regularly
    ]]
    
    -- Create help popup
    local popup = Instance.new("Frame")
    popup.Name = "HelpPopup"
    popup.Size = UDim2.new(0, 400, 0, 300)
    popup.Position = UDim2.new(0.5, -200, 0.5, -150)
    popup.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    popup.BackgroundTransparency = 0.1
    popup.BorderSizePixel = 0
    popup.Parent = clientState.mainUI
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = popup
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0.15, 0)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.Text = "HELP"
    titleLabel.TextScaled = true
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Parent = popup
    
    local contentLabel = Instance.new("TextLabel")
    contentLabel.Name = "ContentLabel"
    contentLabel.Size = UDim2.new(0.9, 0, 0.7, 0)
    contentLabel.Position = UDim2.new(0.05, 0, 0.2, 0)
    contentLabel.Text = helpText
    contentLabel.TextScaled = true
    contentLabel.BackgroundTransparency = 1
    contentLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    contentLabel.Font = Enum.Font.SourceSans
    contentLabel.TextWrapped = true
    contentLabel.TextXAlignment = Enum.TextXAlignment.Left
    contentLabel.TextYAlignment = Enum.TextYAlignment.Top
    contentLabel.Parent = popup
    
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 100, 0, 30)
    closeButton.Position = UDim2.new(0.5, -50, 0.85, 0)
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    closeButton.BackgroundTransparency = 0.2
    closeButton.BorderSizePixel = 0
    closeButton.Text = "Close"
    closeButton.TextScaled = true
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.Parent = popup
    
    -- Add corner rounding
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton
    
    -- Handle close
    closeButton.MouseButton1Click:Connect(function()
        popup:Destroy()
    end)
    
    -- Auto-close after 10 seconds
    game:GetService("Debris"):AddItem(popup, 10)
end

-- Setup input handling
function MainClient:SetupInputHandling()
    -- Handle key presses
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.H then
            self:ShowHelp()
        end
    end)
end

-- Setup player monitoring
function MainClient:SetupPlayerMonitoring()
    -- Monitor player stats
    local connection
    connection = game:GetService("RunService").Heartbeat:Connect(function()
        self:UpdateUI()
    end)
    
    -- Set up server communication
    self:SetupServerCommunication()
    
    -- Clean up connection when player leaves
    clientState.player.AncestryChanged:Connect(function(_, parent)
        if not parent then
            if connection then
                connection:Disconnect()
            end
        end
    end)
end

-- Setup server communication
function MainClient:SetupServerCommunication()
    -- Wait for RemoteEvents to be available
    local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
    
    -- Handle player data updates
    local updatePlayerDataEvent = remoteEvents:WaitForChild("UpdatePlayerData")
    updatePlayerDataEvent.OnClientEvent:Connect(function(data)
        self:OnPlayerDataReceived(data)
    end)
    
    -- Handle tycoon data updates
    local updateTycoonDataEvent = remoteEvents:WaitForChild("UpdateTycoonData")
    updateTycoonDataEvent.OnClientEvent:Connect(function(data)
        self:OnTycoonDataReceived(data)
    end)
    
    -- Request initial data
    local requestPlayerDataEvent = remoteEvents:WaitForChild("RequestPlayerData")
    requestPlayerDataEvent:FireServer()
end

-- Handle received player data
function MainClient:OnPlayerDataReceived(data)
    if type(data) == "table" then
        clientState.playerData = data
        self:UpdateUI()
    end
end

-- Handle received tycoon data
function MainClient:OnTycoonDataReceived(data)
    if type(data) == "table" then
        clientState.tycoonData = data
        self:UpdateUI()
    end
end

-- Update UI
function MainClient:UpdateUI()
    if not clientState.player or not clientState.player.Character then return end
    
    -- Update cash display
    self:UpdateCashDisplay()
    
    -- Update ability display
    self:UpdateAbilityDisplay()
    
    -- Update tycoon info display
    self:UpdateTycoonInfoDisplay()
end

-- Update cash display
function MainClient:UpdateCashDisplay()
    if not clientState.cashDisplay then return end
    
    -- Display real cash data
    local cash = clientState.playerData.Cash or 0
    clientState.cashDisplay.Text = "$" .. HelperFunctions.FormatCash(cash)
end

-- Update ability display
function MainClient:UpdateAbilityDisplay()
    if not clientState.abilityDisplay then return end
    
    -- Display real ability data
    local abilities = clientState.playerData.Abilities or {}
    local abilityText = ""
    
    if next(abilities) then
        for abilityName, level in pairs(abilities) do
            if level > 0 then
                abilityText = abilityText .. abilityName .. ": Level " .. level .. "\n"
            end
        end
    else
        abilityText = "No abilities yet"
    end
    
    clientState.abilityDisplay.Text = abilityText
end

-- Update tycoon info display
function MainClient:UpdateTycoonInfoDisplay()
    if not clientState.tycoonInfoDisplay then return end
    
    local tycoonInfo = clientState.tycoonData
    local ownerText = tycoonInfo.Owner or "None"
    local levelText = "Level " .. (tycoonInfo.Level or 1)
    local cashGeneratedText = HelperFunctions.FormatCash(tycoonInfo.CashGenerated or 0)
    local isActiveText = tycoonInfo.IsActive and "Active" or "Inactive"
    
    clientState.tycoonInfoDisplay.Text = "Owner: " .. ownerText .. "\nLevel: " .. levelText .. "\nCash Generated: " .. cashGeneratedText .. "\nStatus: " .. isActiveText
end

-- Show notification
function MainClient:ShowNotification(message, duration)
    if not clientState.mainUI then return end
    
    local notification = Instance.new("Frame")
    notification.Name = "Notification"
    notification.Size = UDim2.new(0, 300, 0, 50)
    notification.Position = UDim2.new(0.5, -150, 0, -60)
    notification.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    notification.BackgroundTransparency = 0.2
    notification.BorderSizePixel = 0
    notification.Parent = clientState.mainUI
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notification
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "TextLabel"
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Position = UDim2.new(0, 0, 0, 0)
    textLabel.Text = message
    textLabel.TextScaled = true
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Parent = notification
    
    -- Animate in
    notification.Position = UDim2.new(0.5, -150, 0, -60)
    
    -- Animate to center
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
    local tween = game:GetService("TweenService"):Create(notification, tweenInfo, {
        Position = UDim2.new(0.5, -150, 0.1, 0)
    })
    tween:Play()
    
    -- Auto-destroy after duration
    game:GetService("Debris"):AddItem(notification, duration or 3)
end

-- Get client state
function MainClient:GetClientState()
    return table.clone(clientState)
end

-- Clean up client
function MainClient:Cleanup()
    if clientState.mainUI then
        clientState.mainUI:Destroy()
        clientState.mainUI = nil
    end
    
    clientState.cashDisplay = nil
    clientState.abilityDisplay = nil
    clientState.tycoonInfoDisplay = nil
    clientState.isInitialized = false
end

-- Initialize when the script runs
MainClient:Initialize()

-- Clean up when player leaves
if clientState.player then
    clientState.player.AncestryChanged:Connect(function(_, parent)
        if not parent then
            MainClient:Cleanup()
        end
    end)
end

return MainClient
