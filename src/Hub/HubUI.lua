local HubUI = {}
HubUI.__index = HubUI

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Constants
local Constants = require(ReplicatedStorage.Utils.Constants)
local HelperFunctions = require(ReplicatedStorage.Utils.HelperFunctions)

-- UI configuration
local UI_CONFIG = {
    PLAYER_LIST_SIZE = UDim2.new(0, 250, 0, 300),
    NAVIGATION_SIZE = UDim2.new(0, 200, 0, 150),
    NOTIFICATION_SIZE = UDim2.new(0, 300, 0, 80),
    ANIMATION_DURATION = 0.3
}

function HubUI.new()
    local self = setmetatable({}, HubUI)
    
    -- Initialize data structures
    self.mainUI = nil
    self.playerList = nil
    self.navigationPanel = nil
    self.notificationPanel = nil
    self.isUIVisible = true
    self.currentNotifications = {}
    
    -- RemoteEvents for server communication
    self.remotes = {}
    self:SetupRemotes()
    
    return self
end

function HubUI:SetupRemotes()
    -- Get remote events from ReplicatedStorage
    local remoteFolder = ReplicatedStorage:WaitForChild("HubRemotes")
    
    self.remotes = {
        PlayerJoinedHub = remoteFolder:WaitForChild("PlayerJoinedHub"),
        PlayerLeftHub = remoteFolder:WaitForChild("PlayerLeftHub"),
        PlotAssigned = remoteFolder:WaitForChild("PlotAssigned"),
        PlotFreed = remoteFolder:WaitForChild("PlotFreed")
    }
    
    -- Set up event handlers
    self:SetupEventHandlers()
end

function HubUI:SetupEventHandlers()
    -- Handle player joining hub
    self.remotes.PlayerJoinedHub.OnClientEvent:Connect(function(data)
        self:OnPlayerJoinedHub(data)
    end)
    
    -- Handle player leaving hub
    self.remotes.PlayerLeftHub.OnClientEvent:Connect(function(data)
        self:OnPlayerLeftHub(data)
    end)
    
    -- Handle plot assignment
    self.remotes.PlotAssigned.OnClientEvent:Connect(function(data)
        self:OnPlotAssigned(data)
    end)
    
    -- Handle plot freed
    self.remotes.PlotFreed.OnClientEvent:Connect(function(data)
        self:OnPlotFreed(data)
    end)
    
    -- Handle plot status updates
    self.remotes.UpdatePlotStatus.OnClientEvent:Connect(function(data)
        self:OnPlotStatusUpdate(data)
    end)
end

function HubUI:Initialize()
    print("HubUI: Initializing hub interface...")
    
    -- Create main UI
    self:CreateMainUI()
    
    -- Create player list
    self:CreatePlayerList()
    
    -- Create navigation panel
    self:CreateNavigationPanel()
    
    -- Create plot map
    self:CreatePlotMap()
    
    -- Create notification panel
    self:CreateNotificationPanel()
    
    -- Set up input handling
    self:SetupInputHandling()
    
    -- Start UI updates
    self:StartUIUpdates()
    
    print("HubUI: Hub interface initialized successfully!")
end

function HubUI:CreateMainUI()
    -- Create main ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "HubUI"
    screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    
    -- Create main container
    local mainContainer = Instance.new("Frame")
    mainContainer.Name = "MainContainer"
    mainContainer.Size = UDim2.new(1, 0, 1, 0)
    mainContainer.Position = UDim2.new(0, 0, 0, 0)
    mainContainer.BackgroundTransparency = 1
    mainContainer.Parent = screenGui
    
    self.mainUI = screenGui
    self.mainContainer = mainContainer
    
    print("HubUI: Created main UI container")
end

function HubUI:CreatePlayerList()
    -- Create player list frame
    local playerListFrame = Instance.new("Frame")
    playerListFrame.Name = "PlayerList"
    playerListFrame.Size = UI_CONFIG.PLAYER_LIST_SIZE
    playerListFrame.Position = UDim2.new(1, -UI_CONFIG.PLAYER_LIST_SIZE.X.Offset - 10, 0, 10)
    playerListFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    playerListFrame.BorderSizePixel = 0
    playerListFrame.Parent = self.mainContainer
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = playerListFrame
    
    -- Create title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0.1, 0)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Players Online"
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = playerListFrame
    
    -- Create player list container
    local listContainer = Instance.new("ScrollingFrame")
    listContainer.Name = "ListContainer"
    listContainer.Size = UDim2.new(1, -20, 0.85, 0)
    listContainer.Position = UDim2.new(0, 10, 0.1, 0)
    listContainer.BackgroundTransparency = 1
    listContainer.BorderSizePixel = 0
    listContainer.ScrollBarThickness = 6
    listContainer.Parent = playerListFrame
    
    -- Create player list layout
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.Name
    listLayout.Padding = UDim.new(0, 5)
    listLayout.Parent = listContainer
    
    self.playerList = {
        frame = playerListFrame,
        container = listContainer,
        layout = listLayout
    }
    
    -- Populate initial player list
    self:UpdatePlayerList()
    
    print("HubUI: Created player list")
end

function HubUI:CreateNavigationPanel()
    -- Create navigation frame
    local navFrame = Instance.new("Frame")
    navFrame.Name = "Navigation"
    navFrame.Size = UI_CONFIG.NAVIGATION_SIZE
    navFrame.Position = UDim2.new(0, 10, 0, 10)
    navFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    navFrame.BorderSizePixel = 0
    navFrame.Parent = self.mainContainer
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = navFrame
    
    -- Create title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0.2, 0)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Navigation"
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = navFrame
    
    -- Create hub button
    local hubButton = Instance.new("TextButton")
    hubButton.Name = "HubButton"
    hubButton.Size = UDim2.new(0.8, 0, 0.15, 0)
    hubButton.Position = UDim2.new(0.1, 0, 0.25, 0)
    hubButton.BackgroundColor3 = Color3.new(0.2, 0.6, 0.8)
    hubButton.Text = "Return to Hub"
    hubButton.TextColor3 = Color3.new(1, 1, 1)
    hubButton.TextScaled = true
    hubButton.Font = Enum.Font.Gotham
    hubButton.Parent = navFrame
    
    -- Add corner radius to button
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 5)
    buttonCorner.Parent = hubButton
    
    -- Create plot button
    local plotButton = Instance.new("TextButton")
    plotButton.Name = "PlotButton"
    plotButton.Size = UDim2.new(0.8, 0, 0.15, 0)
    plotButton.Position = UDim2.new(0.1, 0, 0.45, 0)
    plotButton.BackgroundColor3 = Color3.new(0.8, 0.6, 0.2)
    plotButton.Text = "Go to Plot"
    plotButton.TextColor3 = Color3.new(1, 1, 1)
    plotButton.TextScaled = true
    plotButton.Font = Enum.Font.Gotham
    plotButton.Parent = navFrame
    
    -- Add corner radius to plot button
    local plotButtonCorner = Instance.new("UICorner")
    plotButtonCorner.CornerRadius = UDim.new(0, 5)
    plotButtonCorner.Parent = plotButton
    
    -- Create plot map button
    local plotMapButton = Instance.new("TextButton")
    plotMapButton.Name = "PlotMapButton"
    plotMapButton.Size = UDim2.new(0.8, 0, 0.15, 0)
    plotMapButton.Position = UDim2.new(0.1, 0, 0.65, 0)
    plotMapButton.BackgroundColor3 = Color3.new(0.8, 0.4, 0.2)
    plotMapButton.Text = "Plot Map"
    plotMapButton.TextColor3 = Color3.new(1, 1, 1)
    plotMapButton.TextScaled = true
    plotMapButton.Font = Enum.Font.Gotham
    plotMapButton.Parent = navFrame
    
    -- Add corner radius to plot map button
    local plotMapButtonCorner = Instance.new("UICorner")
    plotMapButtonCorner.CornerRadius = UDim.new(0, 5)
    plotMapButtonCorner.Parent = plotMapButton
    
    -- NEW: Create "My Tycoons" button
    local myTycoonsButton = Instance.new("TextButton")
    myTycoonsButton.Name = "MyTycoonsButton"
    myTycoonsButton.Size = UDim2.new(0.8, 0, 0.15, 0)
    myTycoonsButton.Position = UDim2.new(0.1, 0, 0.85, 0)
    myTycoonsButton.BackgroundColor3 = Color3.new(0.6, 0.8, 0.4)  -- Green color for tycoons
    myTycoonsButton.Text = "My Tycoons"
    myTycoonsButton.TextColor3 = Color3.new(1, 1, 1)
    myTycoonsButton.TextScaled = true
    myTycoonsButton.Font = Enum.Font.Gotham
    myTycoonsButton.Parent = navFrame
    
    -- Add corner radius to my tycoons button
    local myTycoonsButtonCorner = Instance.new("UICorner")
    myTycoonsButtonCorner.CornerRadius = UDim.new(0, 5)
    myTycoonsButtonCorner.Parent = myTycoonsButton
    
    -- Create settings button (moved down)
    local settingsButton = Instance.new("TextButton")
    settingsButton.Name = "SettingsButton"
    settingsButton.Size = UDim2.new(0.8, 0, 0.15, 0)
    settingsButton.Position = UDim2.new(0.1, 0, 1.05, 0)  -- Moved down to make room
    settingsButton.BackgroundColor3 = Color3.new(0.6, 0.6, 0.6)
    settingsButton.Text = "Settings"
    settingsButton.TextColor3 = Color3.new(1, 1, 1)
    settingsButton.TextScaled = true
    settingsButton.Font = Enum.Font.Gotham
    settingsButton.Parent = navFrame
    
    -- Add corner radius to settings button
    local settingsButtonCorner = Instance.new("UICorner")
    settingsButtonCorner.CornerRadius = UDim.new(0, 5)
    settingsButtonCorner.Parent = settingsButton
    
    -- Handle button clicks
    hubButton.MouseButton1Click:Connect(function()
        self:ReturnToHub()
    end)
    
    plotButton.MouseButton1Click:Connect(function()
        self:GoToPlot()
    end)
    
    plotMapButton.MouseButton1Click:Connect(function()
        self:TogglePlotMap()
    end)
    
    -- NEW: Handle My Tycoons button click
    myTycoonsButton.MouseButton1Click:Connect(function()
        self:ShowMyTycoons()
    end)
    
    settingsButton.MouseButton1Click:Connect(function()
        self:OpenSettings()
    end)
    
    self.navigationPanel = {
        frame = navFrame,
        hubButton = hubButton,
        plotButton = plotButton,
        plotMapButton = plotMapButton,
        myTycoonsButton = myTycoonsButton,  -- NEW: Store reference
        settingsButton = settingsButton
    }
    
    print("HubUI: Created navigation panel")
end

function HubUI:CreatePlotMap()
    -- Create plot map frame
    local plotMapFrame = Instance.new("Frame")
    plotMapFrame.Name = "PlotMap"
    plotMapFrame.Size = UDim2.new(0, 400, 0, 300)
    plotMapFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
    plotMapFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    plotMapFrame.BorderSizePixel = 0
    plotMapFrame.Parent = self.mainContainer
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = plotMapFrame
    
    -- Create title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0.1, 0)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Tycoon Plot Map"
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = plotMapFrame
    
    -- Create plot grid container
    local plotGridContainer = Instance.new("Frame")
    plotGridContainer.Name = "PlotGrid"
    plotGridContainer.Size = UDim2.new(0.9, 0, 0.8, 0)
    plotGridContainer.Position = UDim2.new(0.05, 0, 0.15, 0)
    plotGridContainer.BackgroundTransparency = 1
    plotGridContainer.Parent = plotMapFrame
    
    -- Create plot grid layout
    local plotGridLayout = Instance.new("UIGridLayout")
    plotGridLayout.CellSize = UDim2.new(0.18, 0, 0.15, 0)
    plotGridLayout.CellPadding = UDim.new(0.02, 0, 0.02, 0)
    plotGridLayout.Parent = plotGridContainer
    
    -- Create 20 plot buttons (4x5 grid)
    for i = 1, 20 do
        self:CreatePlotButton(plotGridContainer, i)
    end
    
    -- Create close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseMapButton"
    closeButton.Size = UDim2.new(0.1, 0, 0.08, 0)
    closeButton.Position = UDim2.new(0.9, 0, 0, 0)
    closeButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = plotMapFrame
    
    -- Add corner radius to close button
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 5)
    closeCorner.Parent = closeButton
    
    -- Handle close button click
    closeButton.MouseButton1Click:Connect(function()
        self:TogglePlotMap()
    end)
    
    -- Store plot map reference
    self.plotMap = {
        frame = plotMapFrame,
        container = plotGridContainer,
        isVisible = true
    }
    
    print("HubUI: Created plot map")
end

function HubUI:CreatePlotButton(parent, plotId)
    -- Create plot button
    local plotButton = Instance.new("TextButton")
    plotButton.Name = "Plot_" .. plotId
    plotButton.Size = UDim2.new(1, 0, 1, 0)
    plotButton.BackgroundColor3 = Color3.new(0.3, 0.8, 0.3) -- Green for available
    plotButton.Text = plotId
    plotButton.TextColor3 = Color3.new(1, 1, 1)
    plotButton.TextScaled = true
    plotButton.Font = Enum.Font.GothamBold
    plotButton.Parent = parent
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = plotButton
    
    -- Handle plot button click
    plotButton.MouseButton1Click:Connect(function()
        self:OnPlotButtonClicked(plotId)
    end)
    
    -- Store plot button reference
    self.plotButtons = self.plotButtons or {}
    self.plotButtons[plotId] = plotButton
end

function HubUI:OnPlotButtonClicked(plotId)
    print("HubUI: Plot " .. plotId .. " clicked")
    
    -- This could trigger plot selection or show plot info
    -- For now, just show a notification
    self:ShowNotification("Plot " .. plotId .. " selected! Click on the plot in the world to claim it.", 3, "Info")
end

function HubUI:TogglePlotMap()
    if not self.plotMap then return end
    
    self.plotMap.isVisible = not self.plotMap.isVisible
    local targetTransparency = self.plotMap.isVisible and 0 or 1
    
    -- Animate plot map visibility
    local tween = TweenService:Create(self.plotMap.frame, TweenInfo.new(UI_CONFIG.ANIMATION_DURATION), {
        BackgroundTransparency = targetTransparency
    })
    tween:Play()
    
    print("HubUI: Plot map visibility toggled to " .. (self.plotMap.isVisible and "visible" or "hidden"))
end

function HubUI:UpdatePlotStatus(plotId, isAvailable, ownerName)
    if not self.plotButtons or not self.plotButtons[plotId] then return end
    
    local plotButton = self.plotButtons[plotId]
    
    if isAvailable then
        plotButton.BackgroundColor3 = Color3.new(0.3, 0.8, 0.3) -- Green for available
        plotButton.Text = plotId
    else
        plotButton.BackgroundColor3 = Color3.new(0.8, 0.3, 0.3) -- Red for owned
        plotButton.Text = plotId .. "\n" .. (ownerName or "Owned")
    end
end

function HubUI:CreateNotificationPanel()
    -- Create notification container
    local notificationContainer = Instance.new("Frame")
    notificationContainer.Name = "NotificationContainer"
    notificationContainer.Size = UDim2.new(0, 0, 1, 0)
    notificationContainer.Position = UDim2.new(0.5, 0, 0, 0)
    notificationContainer.BackgroundTransparency = 1
    notificationContainer.Parent = self.mainContainer
    
    self.notificationPanel = {
        container = notificationContainer
    }
    
    print("HubUI: Created notification panel")
end

function HubUI:SetupInputHandling()
    -- Toggle UI visibility with Tab key
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.Tab then
            self:ToggleUIVisibility()
        end
    end)
    
    print("HubUI: Set up input handling")
end

function HubUI:StartUIUpdates()
    -- Update player list every 5 seconds
    spawn(function()
        while true do
            wait(5)
            self:UpdatePlayerList()
        end
    end)
    
    print("HubUI: Started UI updates")
end

function HubUI:UpdatePlayerList()
    if not self.playerList or not self.playerList.container then return end
    
    -- Clear existing player entries
    for _, child in pairs(self.playerList.container:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Get all players
    local players = Players:GetPlayers()
    
    -- Create player entries
    for _, player in pairs(players) do
        self:CreatePlayerEntry(player)
    end
    
    print("HubUI: Updated player list with " .. #players .. " players")
end

function HubUI:CreatePlayerEntry(player)
    if not self.playerList or not self.playerList.container then return end
    
    -- Create player entry frame
    local entryFrame = Instance.new("Frame")
    entryFrame.Name = "PlayerEntry_" .. player.UserId
    entryFrame.Size = UDim2.new(1, 0, 0, 30)
    entryFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    entryFrame.BorderSizePixel = 0
    entryFrame.Parent = self.playerList.container
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = entryFrame
    
    -- Create player name label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "PlayerName"
    nameLabel.Size = UDim2.new(0.7, 0, 1, 0)
    nameLabel.Position = UDim2.new(0, 5, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = entryFrame
    
    -- Create player status indicator
    local statusIndicator = Instance.new("Frame")
    statusIndicator.Name = "StatusIndicator"
    statusIndicator.Size = UDim2.new(0.1, 0, 0.6, 0)
    statusIndicator.Position = UDim2.new(0.8, 0, 0.2, 0)
    statusIndicator.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2) -- Green for online
    statusIndicator.BorderSizePixel = 0
    statusIndicator.Parent = entryFrame
    
    -- Add corner radius to status indicator
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 3)
    statusCorner.Parent = statusIndicator
    
    -- Create player level label (placeholder)
    local levelLabel = Instance.new("TextLabel")
    levelLabel.Name = "PlayerLevel"
    levelLabel.Size = UDim2.new(0.2, 0, 1, 0)
    levelLabel.Position = UDim2.new(0.7, 0, 0, 0)
    levelLabel.BackgroundTransparency = 1
    levelLabel.Text = "Lv.1"
    levelLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    levelLabel.TextScaled = true
    levelLabel.Font = Enum.Font.Gotham
    levelLabel.Parent = entryFrame
    
    print("HubUI: Created player entry for " .. player.Name)
end

function HubUI:ShowNotification(message, duration, notificationType)
    notificationType = notificationType or "Info"
    duration = duration or 3
    
    -- Create notification frame
    local notificationFrame = Instance.new("Frame")
    notificationFrame.Name = "Notification_" .. tick()
    notificationFrame.Size = UI_CONFIG.NOTIFICATION_SIZE
    notificationFrame.Position = UDim2.new(0.5, -UI_CONFIG.NOTIFICATION_SIZE.X.Offset / 2, 0, -UI_CONFIG.NOTIFICATION_SIZE.Y.Offset)
    notificationFrame.BackgroundColor3 = self:GetNotificationColor(notificationType)
    notificationFrame.BorderSizePixel = 0
    notificationFrame.Parent = self.notificationPanel.container
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = notificationFrame
    
    -- Create notification text
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Text"
    textLabel.Size = UDim2.new(1, -20, 1, 0)
    textLabel.Position = UDim2.new(0, 10, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = message
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.Gotham
    textLabel.TextWrapped = true
    textLabel.Parent = notificationFrame
    
    -- Animate notification in
    local slideIn = TweenService:Create(notificationFrame, TweenInfo.new(UI_CONFIG.ANIMATION_DURATION, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -UI_CONFIG.NOTIFICATION_SIZE.X.Offset / 2, 0, 10)
    })
    slideIn:Play()
    
    -- Store notification reference
    table.insert(self.currentNotifications, notificationFrame)
    
    -- Auto-remove after duration
    task.delay(duration, function()
        self:RemoveNotification(notificationFrame)
    end)
    
    print("HubUI: Showed notification: " .. message)
end

function HubUI:RemoveNotification(notificationFrame)
    if not notificationFrame or not notificationFrame.Parent then return end
    
    -- Animate notification out
    local slideOut = TweenService:Create(notificationFrame, TweenInfo.new(UI_CONFIG.ANIMATION_DURATION, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Position = UDim2.new(0.5, -UI_CONFIG.NOTIFICATION_SIZE.X.Offset / 2, 0, -UI_CONFIG.NOTIFICATION_SIZE.Y.Offset)
    })
    
    slideOut.Completed:Connect(function()
        notificationFrame:Destroy()
        
        -- Remove from current notifications
        for i, notification in ipairs(self.currentNotifications) do
            if notification == notificationFrame then
                table.remove(self.currentNotifications, i)
                break
            end
        end
    end)
    
    slideOut:Play()
end

function HubUI:GetNotificationColor(notificationType)
    local colors = {
        Info = Color3.new(0.2, 0.6, 0.8),
        Success = Color3.new(0.2, 0.8, 0.2),
        Warning = Color3.new(0.8, 0.6, 0.2),
        Error = Color3.new(0.8, 0.2, 0.2)
    }
    
    return colors[notificationType] or colors.Info
end

function HubUI:ToggleUIVisibility()
    self.isUIVisible = not self.isUIVisible
    
    local targetTransparency = self.isUIVisible and 0 or 1
    
    -- Animate UI visibility
    if self.playerList and self.playerList.frame then
        local playerListTween = TweenService:Create(self.playerList.frame, TweenInfo.new(UI_CONFIG.ANIMATION_DURATION), {
            BackgroundTransparency = targetTransparency
        })
        playerListTween:Play()
    end
    
    if self.navigationPanel and self.navigationPanel.frame then
        local navTween = TweenService:Create(self.navigationPanel.frame, TweenInfo.new(UI_CONFIG.ANIMATION_DURATION), {
            BackgroundTransparency = targetTransparency
        })
        navTween:Play()
    end
    
    print("HubUI: Toggled UI visibility to " .. (self.isUIVisible and "visible" or "hidden"))
end

function HubUI:ReturnToHub()
    print("HubUI: Returning to hub...")
    
    -- This would typically teleport the player back to the hub
    -- For now, just show a notification
    self:ShowNotification("Returning to hub...", 2, "Info")
end

function HubUI:GoToPlot()
    print("HubUI: Going to plot...")
    
    -- This would typically teleport the player to their plot
    -- For now, just show a notification
    self:ShowNotification("Going to your plot...", 2, "Info")
end

function HubUI:OpenSettings()
    print("HubUI: Opening settings...")
    
    -- This would typically open a settings menu
    -- For now, just show a notification
    self:ShowNotification("Settings coming soon!", 2, "Info")
end

-- NEW: Function to show player's owned tycoons
function HubUI:ShowMyTycoons()
    print("HubUI: Showing my tycoons...")
    
    -- Get the remote function for getting owned plots
    local remoteFolder = ReplicatedStorage:WaitForChild("HubRemotes")
    local getOwnedPlotsRemote = remoteFolder:WaitForChild("GetOwnedPlots")
    
    if getOwnedPlotsRemote then
        -- Call server to get owned plots
        local ownedPlots = getOwnedPlotsRemote:InvokeServer()
        
        if ownedPlots and #ownedPlots > 0 then
            -- Show owned plots panel through PlotSelector
            local plotSelector = require(ReplicatedStorage.Hub.PlotSelector)
            if plotSelector then
                plotSelector:ShowOwnedPlotsPanel({plots = ownedPlots})
            else
                self:ShowNotification("Error: Could not load plot selector", 3, "Error")
            end
        else
            self:ShowNotification("You don't own any tycoons yet! Claim a plot to get started.", 4, "Info")
        end
    else
        self:ShowNotification("Error: Could not access tycoon data", 3, "Error")
    end
end

-- Event handlers
function HubUI:OnPlayerJoinedHub(data)
    print("HubUI: Player " .. data.playerName .. " joined the hub")
    
    -- Show notification
    self:ShowNotification(data.playerName .. " joined the hub!", 3, "Info")
    
    -- Update player list
    self:UpdatePlayerList()
end

function HubUI:OnPlayerLeftHub(data)
    print("HubUI: Player " .. data.playerName .. " left the hub")
    
    -- Show notification
    self:ShowNotification(data.playerName .. " left the hub", 3, "Warning")
    
    -- Update player list
    self:UpdatePlayerList()
end

function HubUI:OnPlotAssigned(data)
    print("HubUI: Plot " .. data.plotId .. " assigned to " .. data.playerName)
    
    -- Show notification
    self:ShowNotification("Plot " .. data.plotId .. " claimed by " .. data.playerName, 4, "Success")
end

function HubUI:OnPlotFreed(data)
    print("HubUI: Plot " .. data.plotId .. " freed")
    
    -- Show notification
    self:ShowNotification("Plot " .. data.plotId .. " is now available!", 4, "Info")
    
    -- Update plot map if available
    if self.plotMap and self.plotButtons then
        self:UpdatePlotStatus(data.plotId, true, nil)
    end
end

function HubUI:OnPlotStatusUpdate(data)
    print("HubUI: Plot " .. data.plotId .. " status updated")
    
    -- Update plot map if available
    if self.plotMap and self.plotButtons then
        self:UpdatePlotStatus(data.plotId, data.isAvailable, data.ownerName)
    end
    
    -- Show notification for status changes
    if data.isAvailable then
        self:ShowNotification("Plot " .. data.plotId .. " is now available!", 3, "Info")
    else
        self:ShowNotification("Plot " .. data.plotId .. " claimed by " .. (data.ownerName or "Unknown"), 3, "Warning")
    end
end

function HubUI:Cleanup()
    print("HubUI: Cleaning up...")
    
    -- Clean up notifications
    for _, notification in pairs(self.currentNotifications) do
        if notification and notification.Parent then
            notification:Destroy()
        end
    end
    
    -- Clean up main UI
    if self.mainUI and self.mainUI.Parent then
        self.mainUI:Destroy()
    end
    
    print("HubUI: Cleanup complete")
end

-- Create global instance
local hubUI = HubUI.new()

-- Initialize when player loads
Players.LocalPlayer.CharacterAdded:Connect(function()
    wait(1) -- Wait for character to fully load
    hubUI:Initialize()
end)

-- Cleanup when player leaves
Players.LocalPlayer.AncestryChanged:Connect(function(_, parent)
    if not parent then
        hubUI:Cleanup()
    end
end)

return hubUI
