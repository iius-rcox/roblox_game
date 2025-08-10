-- PlotSelector.lua
-- Handles tycoon plot selection and claiming system

local PlotSelector = {}
PlotSelector.__index = PlotSelector

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Constants
local Constants = require(ReplicatedStorage.Utils.Constants)
local HelperFunctions = require(ReplicatedStorage.Utils.HelperFunctions)

-- Plot selection configuration
local SELECTION_CONFIG = {
    PREVIEW_DISTANCE = 100,
    PREVIEW_HEIGHT = 50,
    PREVIEW_DURATION = 3,
    CLAIM_BUTTON_SIZE = UDim2.new(0, 200, 0, 50),
    PLOT_INFO_SIZE = UDim2.new(0, 300, 0, 200),
    OWNED_PLOTS_PANEL_SIZE = UDim2.new(0, 400, 0, 300),  -- NEW: Panel for owned plots
    PLOT_BUTTON_SIZE = UDim2.new(0, 180, 0, 40)  -- NEW: Size for plot switching buttons
}

function PlotSelector.new()
    local self = setmetatable({}, PlotSelector)
    
    -- Initialize data structures
    self.currentPlayer = nil
    self.selectedPlot = nil
    self.plotPreview = nil
    self.plotInfoUI = nil
    self.claimButton = nil
    self.isPreviewActive = false
    self.ownedPlotsPanel = nil  -- NEW: Panel showing owned plots
    self.ownedPlots = {}  -- NEW: List of plots owned by current player
    
    -- RemoteEvents for server communication
    self.remotes = {}
    self:SetupRemotes()
    
    return self
end

function PlotSelector:SetupRemotes()
    -- Get remote events from ReplicatedStorage
    local remoteFolder = ReplicatedStorage:WaitForChild("HubRemotes")
    
    self.remotes = {
        ShowPlotMenu = remoteFolder:WaitForChild("ShowPlotMenu"),
        PlotClaimed = remoteFolder:WaitForChild("PlotClaimed"),
        UpdatePlotStatus = remoteFolder:WaitForChild("UpdatePlotStatus"),
        PlotSwitched = remoteFolder:WaitForChild("PlotSwitched"),  -- NEW: Handle plot switching
        ShowOwnedPlots = remoteFolder:WaitForChild("ShowOwnedPlots")  -- NEW: Show owned plots
    }
    
    -- Set up event handlers
    self:SetupEventHandlers()
end

function PlotSelector:SetupEventHandlers()
    -- Handle plot menu display from server
    self.remotes.ShowPlotMenu.OnClientEvent:Connect(function(plotData)
        self:ShowPlotSelectionMenu(plotData)
    end)
    
    -- Handle plot claimed confirmation
    self.remotes.PlotClaimed.OnClientEvent:Connect(function(plotData)
        self:OnPlotClaimed(plotData)
    end)
    
    -- Handle plot status updates
    self.remotes.UpdatePlotStatus.OnClientEvent:Connect(function(plotData)
        self:OnPlotStatusUpdate(plotData)
    end)
    
    -- NEW: Handle plot switching confirmation
    self.remotes.PlotSwitched.OnClientEvent:Connect(function(plotData)
        self:OnPlotSwitched(plotData)
    end)
    
    -- NEW: Handle owned plots display
    self.remotes.ShowOwnedPlots.OnClientEvent:Connect(function(ownedPlotsData)
        self:ShowOwnedPlotsPanel(ownedPlotsData)
    end)
end

function PlotSelector:ShowPlotSelectionMenu(plotData)
    print("PlotSelector: Showing plot selection menu for plot " .. plotData.plotId)
    
    -- Store current plot data
    self.selectedPlot = plotData
    
    -- Create plot preview
    self:CreatePlotPreview(plotData)
    
    -- Create plot information UI
    self:CreatePlotInfoUI(plotData)
    
    -- Create claim button
    self:CreateClaimButton(plotData)
    
    -- Start preview timer
    self:StartPreviewTimer()
end

function PlotSelector:CreatePlotPreview(plotData)
    if self.plotPreview then
        self.plotPreview:Destroy()
    end
    
    -- Create preview camera position
    local previewPosition = plotData.position + Vector3.new(0, SELECTION_CONFIG.PREVIEW_HEIGHT, SELECTION_CONFIG.PREVIEW_DISTANCE)
    
    -- Create preview part (invisible)
    local previewPart = Instance.new("Part")
    previewPart.Name = "PlotPreview_" .. plotData.plotId
    previewPart.Size = Vector3.new(1, 1, 1)
    previewPart.Position = previewPosition
    previewPart.Anchored = true
    previewPart.CanCollide = false
    previewPart.Transparency = 1
    previewPart.Parent = workspace
    
    -- Create camera effect (could be expanded with actual camera manipulation)
    local cameraEffect = Instance.new("Part")
    cameraEffect.Name = "CameraEffect_" .. plotData.plotId
    cameraEffect.Size = Vector3.new(10, 10, 10)
    cameraEffect.Position = previewPosition
    cameraEffect.Anchored = true
    cameraEffect.Material = Enum.Material.Neon
    cameraEffect.BrickColor = BrickColor.new("Bright yellow")
    cameraEffect.Transparency = 0.5
    cameraEffect.CanCollide = false
    cameraEffect.Parent = workspace
    
    -- Animate camera effect
    local tween = TweenService:Create(cameraEffect, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        Transparency = 0.8
    })
    tween:Play()
    
    self.plotPreview = {
        part = previewPart,
        effect = cameraEffect,
        tween = tween
    }
    
    print("PlotSelector: Created plot preview for plot " .. plotData.plotId)
end

function PlotSelector:CreatePlotInfoUI(plotData)
    if self.plotInfoUI then
        self.plotInfoUI:Destroy()
    end
    
    -- Create main UI frame
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PlotInfoUI"
    screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = SELECTION_CONFIG.PLOT_INFO_SIZE
    mainFrame.Position = UDim2.new(0.5, -SELECTION_CONFIG.PLOT_INFO_SIZE.X.Offset / 2, 0.3, 0)
    mainFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame
    
    -- Create title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0.2, 0)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Plot " .. plotData.plotId .. " - " .. plotData.theme
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = mainFrame
    
    -- Create plot details
    local detailsLabel = Instance.new("TextLabel")
    detailsLabel.Name = "Details"
    detailsLabel.Size = UDim2.new(1, 0, 0.6, 0)
    detailsLabel.Position = UDim2.new(0, 0, 0.2, 0)
    detailsLabel.BackgroundTransparency = 1
    detailsLabel.Text = "Theme: " .. plotData.theme .. "\n\n" ..
                       "Location: " .. math.floor(plotData.position.X) .. ", " .. math.floor(plotData.position.Z) .. "\n\n" ..
                       "Status: Available\n\n" ..
                       "Click 'Claim Plot' to start building your tycoon!"
    detailsLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    detailsLabel.TextScaled = true
    detailsLabel.Font = Enum.Font.Gotham
    detailsLabel.TextXAlignment = Enum.TextXAlignment.Left
    detailsLabel.TextYAlignment = Enum.TextYAlignment.Top
    detailsLabel.Parent = mainFrame
    
    -- Create close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0.1, 0, 0.1, 0)
    closeButton.Position = UDim2.new(0.9, 0, 0, 0)
    closeButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = mainFrame
    
    -- Add corner radius to close button
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 5)
    closeCorner.Parent = closeButton
    
    -- Handle close button click
    closeButton.MouseButton1Click:Connect(function()
        self:ClosePlotSelectionMenu()
    end)
    
    self.plotInfoUI = screenGui
    
    print("PlotSelector: Created plot info UI for plot " .. plotData.plotId)
end

function PlotSelector:CreateClaimButton(plotData)
    if self.claimButton then
        self.claimButton:Destroy()
    end
    
    -- Create claim button
    local claimButton = Instance.new("TextButton")
    claimButton.Name = "ClaimPlotButton"
    claimButton.Size = SELECTION_CONFIG.CLAIM_BUTTON_SIZE
    claimButton.Position = UDim2.new(0.5, -SELECTION_CONFIG.CLAIM_BUTTON_SIZE.X.Offset / 2, 0.7, 0)
    claimButton.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
    claimButton.Text = "Claim Plot " .. plotData.plotId
    claimButton.TextColor3 = Color3.new(1, 1, 1)
    claimButton.TextScaled = true
    claimButton.Font = Enum.Font.GothamBold
    claimButton.Parent = self.plotInfoUI
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = claimButton
    
    -- Handle claim button click
    claimButton.MouseButton1Click:Connect(function()
        self:ClaimPlot(plotData.plotId)
    end)
    
    self.claimButton = claimButton
    
    print("PlotSelector: Created claim button for plot " .. plotData.plotId)
end

function PlotSelector:ClaimPlot(plotId)
    print("PlotSelector: Player attempting to claim plot " .. plotId)
    
    -- Disable claim button to prevent multiple clicks
    if self.claimButton then
        self.claimButton.Enabled = false
        self.claimButton.Text = "Claiming..."
    end
    
    -- Send claim request to server through RemoteFunction
    local success, result = pcall(function()
        -- Create a RemoteFunction for plot claiming
        local remoteFolder = ReplicatedStorage:WaitForChild("HubRemotes")
        local claimFunction = remoteFolder:WaitForChild("ClaimPlot")
        
        if claimFunction then
            return claimFunction:InvokeServer(plotId)
        else
            -- Fallback: try to create the RemoteFunction
            local newClaimFunction = Instance.new("RemoteFunction")
            newClaimFunction.Name = "ClaimPlot"
            newClaimFunction.Parent = remoteFolder
            
            return newClaimFunction:InvokeServer(plotId)
        end
    end)
    
    if success and result then
        -- Plot claimed successfully
        if self.claimButton then
            self.claimButton.Text = "Claimed!"
            self.claimButton.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
        end
        
        -- Show success notification
        HelperFunctions.CreateNotification(Players.LocalPlayer, "Plot " .. plotId .. " claimed successfully!", 3)
        
        -- Close menu after delay
        wait(2)
        self:ClosePlotSelectionMenu()
        
        print("PlotSelector: Plot " .. plotId .. " claimed successfully!")
    else
        -- Plot claiming failed
        if self.claimButton then
            self.claimButton.Enabled = true
            self.claimButton.Text = "Claim Failed - Try Again"
            self.claimButton.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
        end
        
        -- Show error notification
        HelperFunctions.CreateNotification(Players.LocalPlayer, "Failed to claim plot " .. plotId .. ". Please try again.", 3)
        
        -- Reset button after delay
        wait(3)
        if self.claimButton then
            self.claimButton.Text = "Claim Plot " .. plotId
            self.claimButton.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
            self.claimButton.Enabled = true
        end
        
        print("PlotSelector: Plot " .. plotId .. " claiming failed!")
    end
end

function PlotSelector:StartPreviewTimer()
    if self.previewTimer then
        self.previewTimer:Disconnect()
    end
    
    self.isPreviewActive = true
    
    -- Auto-close preview after duration
    self.previewTimer = spawn(function()
        wait(SELECTION_CONFIG.PREVIEW_DURATION)
        if self.isPreviewActive then
            self:ClosePlotSelectionMenu()
        end
    end)
end

function PlotSelector:ClosePlotSelectionMenu()
    print("PlotSelector: Closing plot selection menu")
    
    self.isPreviewActive = false
    
    -- Clean up preview
    if self.plotPreview then
        if self.plotPreview.tween then
            self.plotPreview.tween:Cancel()
        end
        if self.plotPreview.part then
            self.plotPreview.part:Destroy()
        end
        if self.plotPreview.effect then
            self.plotPreview.effect:Destroy()
        end
        self.plotPreview = nil
    end
    
    -- Clean up UI
    if self.plotInfoUI then
        self.plotInfoUI:Destroy()
        self.plotInfoUI = nil
    end
    
    -- Clean up claim button
    if self.claimButton then
        self.claimButton:Destroy()
        self.claimButton = nil
    end
    
    -- Clear selected plot
    self.selectedPlot = nil
    
    print("PlotSelector: Plot selection menu closed")
end

function PlotSelector:OnPlotClaimed(plotData)
    print("PlotSelector: Plot " .. plotData.plotId .. " claimed by " .. Players.LocalPlayer.Name)
    
    -- Show confirmation
    HelperFunctions.CreateNotification(Players.LocalPlayer, "Welcome to your new tycoon on plot " .. plotData.plotId .. "!", 5)
    
    -- Close any open menus
    self:ClosePlotSelectionMenu()
end

function PlotSelector:OnPlotStatusUpdate(plotData)
    print("PlotSelector: Plot " .. plotData.plotId .. " status updated")
    
    -- Update any relevant UI elements
    -- This could update plot lists, status displays, etc.
end

function PlotSelector:GetSelectedPlot()
    return self.selectedPlot
end

function PlotSelector:IsPreviewActive()
    return self.isPreviewActive
end

function PlotSelector:Cleanup()
    print("PlotSelector: Cleaning up...")
    
    -- Close any open menus
    self:ClosePlotSelectionMenu()
    
    -- Disconnect events
    if self.previewTimer then
        self.previewTimer:Disconnect()
    end
    
    print("PlotSelector: Cleanup complete")
end

-- NEW: Function to show owned plots panel
function PlotSelector:ShowOwnedPlotsPanel(ownedPlotsData)
    print("PlotSelector: Showing owned plots panel")
    
    -- Store owned plots data
    self.ownedPlots = ownedPlotsData.plots or {}
    
    -- Create or update owned plots panel
    self:CreateOwnedPlotsPanel()
end

-- NEW: Function to create owned plots panel
function PlotSelector:CreateOwnedPlotsPanel()
    if self.ownedPlotsPanel then
        self.ownedPlotsPanel:Destroy()
    end
    
    -- Create main panel
    local panel = Instance.new("Frame")
    panel.Name = "OwnedPlotsPanel"
    panel.Size = SELECTION_CONFIG.OWNED_PLOTS_PANEL_SIZE
    panel.Position = UDim2.new(0.5, -SELECTION_CONFIG.OWNED_PLOTS_PANEL_SIZE.X.Offset/2, 0.5, -SELECTION_CONFIG.OWNED_PLOTS_PANEL_SIZE.Y.Offset/2)
    panel.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    panel.BorderSizePixel = 0
    panel.Parent = game.StarterGui
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = panel
    
    -- Create title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    title.Text = "Your Tycoons (" .. #self.ownedPlots .. "/3)"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = panel
    
    -- Add corner radius to title
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = title
    
    -- Create close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = title
    
    -- Add corner radius to close button
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeButton
    
    -- Handle close button click
    closeButton.MouseButton1Click:Connect(function()
        panel:Destroy()
        self.ownedPlotsPanel = nil
    end)
    
    -- Create plots container
    local plotsContainer = Instance.new("Frame")
    plotsContainer.Name = "PlotsContainer"
    plotsContainer.Size = UDim2.new(1, -20, 1, -50)
    plotsContainer.Position = UDim2.new(0, 10, 0, 45)
    plotsContainer.BackgroundTransparency = 1
    plotsContainer.Parent = panel
    
    -- Create plot buttons
    if #self.ownedPlots > 0 then
        for i, plotId in ipairs(self.ownedPlots) do
            self:CreatePlotButton(plotsContainer, plotId, i)
        end
    else
        -- Show "no plots" message
        local noPlotsLabel = Instance.new("TextLabel")
        noPlotsLabel.Name = "NoPlotsLabel"
        noPlotsLabel.Size = UDim2.new(1, 0, 0, 50)
        noPlotsLabel.Position = UDim2.new(0, 0, 0.5, -25)
        noPlotsLabel.BackgroundTransparency = 1
        noPlotsLabel.Text = "You don't own any tycoons yet!\nClaim a plot to get started."
        noPlotsLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        noPlotsLabel.TextScaled = true
        noPlotsLabel.Font = Enum.Font.Gotham
        noPlotsLabel.Parent = plotsContainer
    end
    
    -- Store reference
    self.ownedPlotsPanel = panel
end

-- NEW: Function to create individual plot button
function PlotSelector:CreatePlotButton(container, plotId, index)
    local button = Instance.new("TextButton")
    button.Name = "PlotButton_" .. plotId
    button.Size = SELECTION_CONFIG.PLOT_BUTTON_SIZE
    button.Position = UDim2.new(0, 10, 0, (index - 1) * (SELECTION_CONFIG.PLOT_BUTTON_SIZE.Y.Offset + 10) + 10)
    button.BackgroundColor3 = Color3.fromRGB(70, 120, 200)
    button.Text = "Tycoon " .. plotId .. " - Click to Switch"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextScaled = true
    button.Font = Enum.Font.Gotham
    button.Parent = container
    
    -- Add corner radius
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = button
    
    -- Handle button click - switch to this plot
    button.MouseButton1Click:Connect(function()
        self:SwitchToPlot(plotId)
    end)
    
    -- Add hover effect
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(90, 140, 220)}):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 120, 200)}):Play()
    end)
end

-- NEW: Function to switch to a specific plot
function PlotSelector:SwitchToPlot(plotId)
    print("PlotSelector: Player requesting to switch to plot " .. plotId)
    
    -- Get the remote function for switching plots
    local remoteFolder = ReplicatedStorage:WaitForChild("HubRemotes")
    local switchToPlotRemote = remoteFolder:WaitForChild("SwitchToPlot")
    
    if switchToPlotRemote then
        -- Call server to switch plots
        local success = switchToPlotRemote:InvokeServer(plotId)
        if success then
            print("PlotSelector: Successfully switched to plot " .. plotId)
        else
            print("PlotSelector: Failed to switch to plot " .. plotId)
        end
    else
        print("PlotSelector: Error - SwitchToPlot remote not found")
    end
end

-- NEW: Function to handle plot switching confirmation
function PlotSelector:OnPlotSwitched(plotData)
    print("PlotSelector: Successfully switched to plot " .. plotData.plotId)
    
    -- Show success notification
    HelperFunctions.CreateNotification(game.Players.LocalPlayer, "Switched to " .. plotData.theme .. " tycoon!", 3)
    
    -- Close any open UI panels
    if self.plotInfoUI then
        self.plotInfoUI:Destroy()
        self.plotInfoUI = nil
    end
    
    if self.plotPreview then
        self.plotPreview:Destroy()
        self.plotPreview = nil
    end
    
    if self.claimButton then
        self.claimButton:Destroy()
        self.claimButton = nil
    end
end

-- Create global instance
local plotSelector = PlotSelector.new()

-- Cleanup when player leaves
Players.LocalPlayer.AncestryChanged:Connect(function(_, parent)
    if not parent then
        plotSelector:Cleanup()
    end
end)

return plotSelector
