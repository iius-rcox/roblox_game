-- HubManager.lua
-- Manages the central hub area for player spawning and tycoon selection

local HubManager = {}
HubManager.__index = HubManager

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Constants
local Constants = require(ReplicatedStorage.Utils.Constants)
local HelperFunctions = require(ReplicatedStorage.Utils.HelperFunctions)

-- Plot configuration
local PLOT_CONFIG = {
    TOTAL_PLOTS = 20,
    PLOTS_PER_ROW = 5,
    PLOT_SPACING = 200,
    PLOT_SIZE = Vector3.new(150, 50, 150),
    HUB_CENTER = Vector3.new(0, 0, 0),
    HUB_SIZE = Vector3.new(1000, 100, 1000),
    MAX_PLOTS_PER_PLAYER = 3  -- NEW: Players can own up to 3 plots
}

-- Plot themes for variety
local PLOT_THEMES = {
    "Anime", "Meme", "Gaming", "Music", "Sports",
    "Food", "Travel", "Technology", "Nature", "Space",
    "Fantasy", "SciFi", "Horror", "Comedy", "Action",
    "Romance", "Mystery", "Adventure", "Strategy", "Racing"
}

function HubManager.new()
    local self = setmetatable({}, HubManager)
    
    -- Initialize data structures
    self.plots = {}
    self.availablePlots = {}
    self.playerPlots = {}  -- Changed: Now stores array of plot IDs per player
    self.plotQueue = {}
    self.hubWorld = nil
    self.plotSelector = nil
    
    -- RemoteEvents for client communication
    self.remotes = {}
    self:SetupRemotes()
    
    return self
end

function HubManager:SetupRemotes()
    -- Create RemoteEvents for client-server communication
    local remoteFolder = Instance.new("Folder")
    remoteFolder.Name = "HubRemotes"
    remoteFolder.Parent = ReplicatedStorage
    
    local remotes = {
        "PlayerJoinedHub",
        "PlayerLeftHub", 
        "PlotAssigned",
        "PlotFreed",
        "UpdatePlotStatus",
        "ShowPlotMenu",
        "PlotSelected",
        "PlotClaimed",
        "PlotSwitched",  -- NEW: For switching between owned plots
        "ShowOwnedPlots"  -- NEW: Show player's owned plots
    }
    
    -- Create RemoteFunctions for client-server communication
    local remoteFunctions = {
        "ClaimPlot",
        "SwitchToPlot",  -- NEW: Switch to a different owned plot
        "GetOwnedPlots"  -- NEW: Get list of player's owned plots
    }
    
    for _, remoteName in ipairs(remoteFunctions) do
        local remoteFunction = Instance.new("RemoteFunction")
        remoteFunction.Name = remoteName
        remoteFunction.Parent = remoteFolder
        self.remotes[remoteName] = remoteFunction
    end
    
    for _, remoteName in ipairs(remotes) do
        local remote = Instance.new("RemoteEvent")
        remote.Name = remoteName
        remote.Parent = remoteFolder
        self.remotes[remoteName] = remote
    end
    
    -- Set up RemoteFunction handlers
    self:SetupRemoteFunctionHandlers()
end

function HubManager:SetupRemoteFunctionHandlers()
    -- Set up ClaimPlot RemoteFunction handler
    if self.remotes.ClaimPlot then
        self.remotes.ClaimPlot.OnServerInvoke:Connect(function(player, plotId)
            print("HubManager: Player " .. player.Name .. " requesting to claim plot " .. plotId)
            return self:ClaimPlot(player, plotId)
        end)
    end
    
    -- NEW: Set up SwitchToPlot RemoteFunction handler
    if self.remotes.SwitchToPlot then
        self.remotes.SwitchToPlot.OnServerInvoke:Connect(function(player, plotId)
            print("HubManager: Player " .. player.Name .. " requesting to switch to plot " .. plotId)
            return self:SwitchPlayerToPlot(player, plotId)
        end)
    end
    
    -- NEW: Set up GetOwnedPlots RemoteFunction handler
    if self.remotes.GetOwnedPlots then
        self.remotes.GetOwnedPlots.OnServerInvoke:Connect(function(player)
            print("HubManager: Player " .. player.Name .. " requesting owned plots list")
            return self:GetPlayerOwnedPlots(player)
        end)
    end
end

function HubManager:Initialize()
    print("HubManager: Initializing hub system...")
    
    -- Create hub world
    self:CreateHubWorld()
    
    -- Create all 20 plots
    self:CreateAllPlots()
    
    -- Load saved hub data (NEW: DataStore integration)
    self:LoadHubData()
    
    -- Set up player management
    self:SetupPlayerManagement()
    
    -- Start hub systems
    self:StartHubSystems()
    
    print("HubManager: Hub system initialized successfully!")
end

function HubManager:CreateHubWorld()
    print("HubManager: Creating hub world...")
    
    -- Create hub base
    local hubBase = Instance.new("Part")
    hubBase.Name = "HubBase"
    hubBase.Size = PLOT_CONFIG.HUB_SIZE
    hubBase.Position = PLOT_CONFIG.HUB_CENTER
    hubBase.Anchored = true
    hubBase.Material = Enum.Material.Grass
    hubBase.BrickColor = BrickColor.new("Bright green")
    hubBase.Parent = workspace
    
    -- Create hub spawn area
    local spawnArea = Instance.new("Part")
    spawnArea.Name = "HubSpawnArea"
    spawnArea.Size = Vector3.new(50, 10, 50)
    spawnArea.Position = PLOT_CONFIG.HUB_CENTER + Vector3.new(0, 55, 0)
    spawnArea.Anchored = true
    spawnArea.Material = Enum.Material.Neon
    spawnArea.BrickColor = BrickColor.new("Bright blue")
    spawnArea.Transparency = 0.3
    spawnArea.Parent = workspace
    
    -- Create hub center building
    local centerBuilding = Instance.new("Part")
    centerBuilding.Name = "HubCenter"
    centerBuilding.Size = Vector3.new(80, 60, 80)
    centerBuilding.Position = PLOT_CONFIG.HUB_CENTER + Vector3.new(0, 30, 0)
    centerBuilding.Anchored = true
    centerBuilding.Material = Enum.Material.Brick
    centerBuilding.BrickColor = BrickColor.new("Bright yellow")
    centerBuilding.Parent = workspace
    
    -- Create welcome sign
    local welcomeSign = Instance.new("Part")
    welcomeSign.Name = "WelcomeSign"
    welcomeSign.Size = Vector3.new(60, 20, 5)
    welcomeSign.Position = PLOT_CONFIG.HUB_CENTER + Vector3.new(0, 70, 40)
    welcomeSign.Anchored = true
    welcomeSign.Material = Enum.Material.Neon
    welcomeSign.BrickColor = BrickColor.new("Bright orange")
    welcomeSign.Parent = workspace
    
    -- Add surface GUI to welcome sign
    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Name = "WelcomeSignGui"
    surfaceGui.Parent = welcomeSign
    surfaceGui.Face = Enum.NormalId.Front
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "Welcome to Tycoon Hub!"
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Parent = surfaceGui
    
    self.hubWorld = {
        base = hubBase,
        spawnArea = spawnArea,
        centerBuilding = centerBuilding,
        welcomeSign = welcomeSign
    }
    
    print("HubManager: Hub world created successfully!")
end

function HubManager:CreateAllPlots()
    print("HubManager: Creating " .. PLOT_CONFIG.TOTAL_PLOTS .. " plots...")
    
    local plotsPerRow = PLOT_CONFIG.PLOTS_PER_ROW
    local rows = math.ceil(PLOT_CONFIG.TOTAL_PLOTS / plotsPerRow)
    
    for i = 1, PLOT_CONFIG.TOTAL_PLOTS do
        local row = math.ceil(i / plotsPerRow)
        local col = ((i - 1) % plotsPerRow) + 1
        
        -- Calculate plot position (arrange in a grid around the hub)
        local offsetX = (col - (plotsPerRow + 1) / 2) * PLOT_CONFIG.PLOT_SPACING
        local offsetZ = (row - (rows + 1) / 2) * PLOT_CONFIG.PLOT_SPACING
        
        local plotPosition = PLOT_CONFIG.HUB_CENTER + Vector3.new(offsetX, 0, offsetZ)
        
        -- Create plot
        local plot = self:CreatePlot(i, plotPosition, PLOT_THEMES[i])
        self.plots[i] = plot
        self.availablePlots[i] = plot
        
        print("HubManager: Created plot " .. i .. " at position " .. tostring(plotPosition))
    end
    
    print("HubManager: All plots created successfully!")
end

function HubManager:CreatePlot(plotId, position, theme)
    local plot = {
        id = plotId,
        position = position,
        theme = theme,
        owner = nil,
        isActive = false,
        tycoonInstance = nil,
        plotPart = nil,
        statusSign = nil
    }
    
    -- Create plot base
    local plotBase = Instance.new("Part")
    plotBase.Name = "Plot_" .. plotId
    plotBase.Size = PLOT_CONFIG.PLOT_SIZE
    plotBase.Position = position + Vector3.new(0, PLOT_CONFIG.PLOT_SIZE.Y / 2, 0)
    plotBase.Anchored = true
    plotBase.Material = Enum.Material.Concrete
    plotBase.BrickColor = BrickColor.new("Medium stone grey")
    plotBase.Parent = workspace
    
    -- Create plot border
    local plotBorder = Instance.new("Part")
    plotBorder.Name = "PlotBorder_" .. plotId
    plotBorder.Size = Vector3.new(PLOT_CONFIG.PLOT_SIZE.X + 10, 5, PLOT_CONFIG.PLOT_SIZE.Z + 10)
    plotBorder.Position = position + Vector3.new(0, PLOT_CONFIG.PLOT_SIZE.Y + 2.5, 0)
    plotBorder.Anchored = true
    plotBorder.Material = Enum.Material.Neon
    plotBorder.BrickColor = BrickColor.new("Bright blue")
    plotBorder.Parent = workspace
    
    -- Create status sign
    local statusSign = Instance.new("Part")
    statusSign.Name = "StatusSign_" .. plotId
    statusSign.Size = Vector3.new(20, 15, 2)
    statusSign.Position = position + Vector3.new(0, PLOT_CONFIG.PLOT_SIZE.Y + 20, PLOT_CONFIG.PLOT_SIZE.Z / 2 + 10)
    statusSign.Anchored = true
    statusSign.Material = Enum.Material.Neon
    statusSign.BrickColor = BrickColor.new("Bright green")
    statusSign.Parent = workspace
    
    -- Add surface GUI to status sign
    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Name = "StatusSignGui"
    surfaceGui.Parent = statusSign
    surfaceGui.Face = Enum.NormalId.Front
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "Plot " .. plotId .. "\n" .. theme .. "\nAvailable"
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.Gotham
    textLabel.Parent = surfaceGui
    
    -- Create plot selection trigger
    local selectionTrigger = Instance.new("Part")
    selectionTrigger.Name = "SelectionTrigger_" .. plotId
    selectionTrigger.Size = Vector3.new(PLOT_CONFIG.PLOT_SIZE.X + 20, 10, PLOT_CONFIG.PLOT_SIZE.Z + 20)
    selectionTrigger.Position = position + Vector3.new(0, PLOT_CONFIG.PLOT_SIZE.Y + 5, 0)
    selectionTrigger.Anchored = true
    selectionTrigger.Material = Enum.Material.ForceField
    selectionTrigger.BrickColor = BrickColor.new("Bright blue")
    selectionTrigger.Transparency = 0.8
    selectionTrigger.CanCollide = false
    selectionTrigger.Parent = workspace
    
    -- Add click detection
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.Parent = selectionTrigger
    
    -- Store plot components
    plot.plotPart = plotBase
    plot.statusSign = statusSign
    plot.selectionTrigger = selectionTrigger
    plot.clickDetector = clickDetector
    
    -- Set up click detection
    clickDetector.MouseClick:Connect(function(player)
        self:HandlePlotSelection(player, plotId)
    end)
    
    return plot
end

function HubManager:HandlePlotSelection(player, plotId)
    print("HubManager: Player " .. player.Name .. " selected plot " .. plotId)
    
    local plot = self.plots[plotId]
    if not plot then
        print("HubManager: Error - Plot " .. plotId .. " not found!")
        return
    end
    
    if plot.owner then
        -- Plot is owned, show owner info
        self:ShowPlotOwnerInfo(player, plot)
    else
        -- Plot is available, show claim option
        self:ShowPlotClaimOption(player, plot)
    end
end

function HubManager:ShowPlotOwnerInfo(player, plot)
    -- Create notification for owned plot
    local message = "Plot " .. plot.id .. " is owned by " .. plot.owner.Name
    HelperFunctions.CreateNotification(player, message, 3)
    
    -- Could also show a detailed UI here
end

function HubManager:ShowPlotClaimOption(player, plot)
    -- Create claim UI for available plot
    self.remotes.ShowPlotMenu:FireClient(player, {
        plotId = plot.id,
        theme = plot.theme,
        position = plot.position
    })
end

function HubManager:ClaimPlot(player, plotId)
    print("HubManager: Player " .. player.Name .. " claiming plot " .. plotId)
    
    local plot = self.plots[plotId]
    if not plot then
        print("HubManager: Error - Plot " .. plotId .. " not found!")
        return false
    end
    
    if plot.owner then
        print("HubManager: Error - Plot " .. plotId .. " is already owned!")
        return false
    end
    
    -- NEW: Check if player already owns maximum number of plots
    local ownedPlots = self:GetPlayerOwnedPlots(player)
    if #ownedPlots >= PLOT_CONFIG.MAX_PLOTS_PER_PLAYER then
        print("HubManager: Error - Player " .. player.Name .. " already owns maximum number of plots (" .. PLOT_CONFIG.MAX_PLOTS_PER_PLAYER .. ")")
        return false
    end
    
    -- Assign plot to player
    plot.owner = player
    plot.isActive = true
    
    -- NEW: Add to player's owned plots array
    if not self.playerPlots[player.UserId] then
        self.playerPlots[player.UserId] = {}
    end
    table.insert(self.playerPlots[player.UserId], plotId)
    
    -- Remove from available plots
    self.availablePlots[plotId] = nil
    
    -- Update plot status
    self:UpdatePlotStatus(plotId)
    
    -- Create tycoon for the player
    self:CreateTycoonForPlayer(player, plot)
    
    -- Notify client
    self.remotes.PlotClaimed:FireClient(player, {
        plotId = plotId,
        theme = plot.theme
    })
    
    -- Notify all clients of plot status change
    self.remotes.UpdatePlotStatus:FireAllClients({
        plotId = plotId,
        owner = player.Name,
        isAvailable = false
    })
    
    -- Broadcast updated plot status to all clients for UI updates
    self:BroadcastPlotStatusUpdate(plotId, false, player.Name)
    
    print("HubManager: Plot " .. plotId .. " successfully claimed by " .. player.Name .. " (Total owned: " .. #self.playerPlots[player.UserId] .. ")")
    return true
end

-- NEW: Function to switch player to a different owned plot
function HubManager:SwitchPlayerToPlot(player, plotId)
    print("HubManager: Player " .. player.Name .. " switching to plot " .. plotId)
    
    local plot = self.plots[plotId]
    if not plot then
        print("HubManager: Error - Plot " .. plotId .. " not found!")
        return false
    end
    
    -- Check if player owns this plot
    local ownedPlots = self:GetPlayerOwnedPlots(player)
    local ownsPlot = false
    for _, ownedPlotId in ipairs(ownedPlots) do
        if ownedPlotId == plotId then
            ownsPlot = true
            break
        end
    end
    
    if not ownsPlot then
        print("HubManager: Error - Player " .. player.Name .. " doesn't own plot " .. plotId)
        return false
    end
    
    -- Teleport player to the plot
    self:TeleportPlayerToPlot(player, plotId)
    
    -- Notify client
    self.remotes.PlotSwitched:FireClient(player, {
        plotId = plotId,
        theme = plot.theme
    })
    
    print("HubManager: Player " .. player.Name .. " successfully switched to plot " .. plotId)
    return true
end

-- NEW: Function to get all plots owned by a player
function HubManager:GetPlayerOwnedPlots(player)
    if not self.playerPlots[player.UserId] then
        return {}
    end
    return table.clone(self.playerPlots[player.UserId])
end

-- NEW: Function to get player's current active plot
function HubManager:GetPlayerCurrentPlot(player)
    local ownedPlots = self:GetPlayerOwnedPlots(player)
    if #ownedPlots > 0 then
        -- For now, return the first owned plot (could be enhanced to track "current" plot)
        return ownedPlots[1]
    end
    return nil
end

function HubManager:CreateTycoonForPlayer(player, plot)
    print("HubManager: Creating tycoon for player " .. player.Name .. " on plot " .. plot.id)
    
    -- Use a deferred require to avoid circular dependency
    local success, TycoonBase = pcall(function()
        return require(ReplicatedStorage.Tycoon.TycoonBase)
    end)
    
    if not success then
        print("HubManager: Error - Failed to load TycoonBase module!")
        return
    end
    
    -- Create tycoon instance
    local tycoon = TycoonBase.new(plot.position, player)
    if tycoon then
        plot.tycoonInstance = tycoon
        print("HubManager: Tycoon created successfully for plot " .. plot.id)
    else
        print("HubManager: Error - Failed to create tycoon for plot " .. plot.id)
    end
end

function HubManager:UpdatePlotStatus(plotId)
    local plot = self.plots[plotId]
    if not plot then return end
    
    local statusSign = plot.statusSign
    if not statusSign then return end
    
    -- Update status sign text
    local surfaceGui = statusSign:FindFirstChild("StatusSignGui")
    if surfaceGui then
        local textLabel = surfaceGui:FindFirstChild("TextLabel")
        if textLabel then
            if plot.owner then
                textLabel.Text = "Plot " .. plot.id .. "\n" .. plot.theme .. "\nOwned by " .. plot.owner.Name
                statusSign.BrickColor = BrickColor.new("Bright red")
            else
                textLabel.Text = "Plot " .. plot.id .. "\n" .. plot.theme .. "\nAvailable"
                statusSign.BrickColor = BrickColor.new("Bright green")
            end
        end
    end
end

function HubManager:SetupPlayerManagement()
    print("HubManager: Setting up player management...")
    
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

function HubManager:HandlePlayerJoined(player)
    print("HubManager: Player " .. player.Name .. " joined the hub")
    
    -- NEW: Restore plot ownership from saved data
    local ownedPlotIds = self.playerPlots[player.UserId]
    if ownedPlotIds and #ownedPlotIds > 0 then
        print("HubManager: Restoring " .. #ownedPlotIds .. " plots for " .. player.Name)
        
        -- Restore plot ownership
        for _, plotId in ipairs(ownedPlotIds) do
            if self.plots[plotId] then
                self.plots[plotId].owner = player
                self.availablePlots[plotId] = nil
                print("HubManager: Restored plot " .. plotId .. " to " .. player.Name)
            end
        end
        
        -- Spawn player at their first owned plot
        local firstPlot = self.plots[ownedPlotIds[1]]
        if firstPlot then
            self:TeleportPlayerToPlot(player, ownedPlotIds[1])
        end
    else
        -- New player, spawn in hub center
        self:SpawnPlayerInHub(player)
    end
    
    -- Get current owned plots (after restoration)
    local ownedPlots = self:GetPlayerOwnedPlots(player)
    
    -- Notify client
    self.remotes.PlayerJoinedHub:FireClient(player, {
        playerName = player.Name,
        ownedPlots = ownedPlots,
        currentPlot = #ownedPlots > 0 and ownedPlots[1] or nil
    })
    
    -- Notify other clients
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player then
            self.remotes.PlayerJoinedHub:FireClient(otherPlayer, {
                playerName = player.Name,
                ownedPlots = ownedPlots,
                currentPlot = #ownedPlots > 0 and ownedPlots[1] or nil
            })
        end
    end
end

function HubManager:HandlePlayerLeft(player)
    print("HubManager: Player " .. player.Name .. " left the hub")
    
    -- Free up player's plot if they own one
    local ownedPlotId = self.playerPlots[player.UserId]
    if ownedPlotId then
        self:FreePlot(ownedPlotId)
    end
    
    -- Remove from player plots
    self.playerPlots[player.UserId] = nil
    
    -- Notify other clients
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player then
            self.remotes.PlayerLeftHub:FireClient(otherPlayer, {
                playerName = player.Name
            })
        end
    end
end

function HubManager:SpawnPlayerInHub(player)
    -- Wait for character to spawn
    local character = player.Character or player.CharacterAdded:Wait()
    
    -- Spawn in hub spawn area
    local spawnPosition = self.hubWorld.spawnArea.Position + Vector3.new(0, 10, 0)
    character:SetPrimaryPartCFrame(CFrame.new(spawnPosition))
    
    print("HubManager: Player " .. player.Name .. " spawned in hub at " .. tostring(spawnPosition))
end

function HubManager:TeleportPlayerToPlot(player, plotId)
    local plot = self.plots[plotId]
    if not plot or not plot.tycoonInstance then
        print("HubManager: Error - Cannot teleport to plot " .. plotId .. " (no tycoon instance)")
        return
    end
    
    -- Teleport player to their tycoon
    local character = player.Character
    if character then
        local tycoonPosition = plot.position + Vector3.new(0, PLOT_CONFIG.PLOT_SIZE.Y + 10, 0)
        character:SetPrimaryPartCFrame(CFrame.new(tycoonPosition))
        print("HubManager: Player " .. player.Name .. " teleported to plot " .. plotId)
    end
end

function HubManager:FreePlot(plotId)
    print("HubManager: Freeing plot " .. plotId)
    
    local plot = self.plots[plotId]
    if not plot then return end
    
    local previousOwner = plot.owner
    
    -- Clean up tycoon instance
    if plot.tycoonInstance then
        -- Could add cleanup logic here
        plot.tycoonInstance = nil
    end
    
    -- NEW: Remove from player's owned plots
    if previousOwner and self.playerPlots[previousOwner.UserId] then
        for i, ownedPlotId in ipairs(self.playerPlots[previousOwner.UserId]) do
            if ownedPlotId == plotId then
                table.remove(self.playerPlots[previousOwner.UserId], i)
                break
            end
        end
        
        -- If player has no more plots, clean up the entry
        if #self.playerPlots[previousOwner.UserId] == 0 then
            self.playerPlots[previousOwner.UserId] = nil
        end
    end
    
    -- Reset plot ownership
    plot.owner = nil
    plot.isActive = false
    
    -- Add back to available plots
    self.availablePlots[plotId] = plot
    
    -- Update plot status
    self:UpdatePlotStatus(plotId)
    
    -- Notify all clients
    self.remotes.PlotFreed:FireAllClients({
        plotId = plotId
    })
    
    -- Broadcast updated plot status to all clients for UI updates
    self:BroadcastPlotStatusUpdate(plotId, true, nil)
    
    print("HubManager: Plot " .. plotId .. " freed successfully from " .. (previousOwner and previousOwner.Name or "unknown"))
end

function HubManager:BroadcastPlotStatusUpdate(plotId, isAvailable, ownerName)
    -- Send plot status update to all clients for UI synchronization
    for _, player in ipairs(Players:GetPlayers()) do
        if player and player.Parent then
            -- Use a custom remote event for plot status updates
            local plotStatusRemote = self.remotes.UpdatePlotStatus
            if plotStatusRemote then
                plotStatusRemote:FireClient(player, {
                    plotId = plotId,
                    isAvailable = isAvailable,
                    ownerName = ownerName
                })
            end
        end
    end
    
    print("HubManager: Broadcasted plot " .. plotId .. " status update to all clients")
end

function HubManager:StartHubSystems()
    print("HubManager: Starting hub systems...")
    
    -- Start plot monitoring
    self:StartPlotMonitoring()
    
    -- Start player monitoring
    self:StartPlayerMonitoring()
    
    print("HubManager: Hub systems started successfully!")
end

function HubManager:StartPlotMonitoring()
    -- Monitor plot status and update as needed
    spawn(function()
        while true do
            wait(10) -- Check every 10 seconds
            
            for plotId, plot in pairs(self.plots) do
                if plot.owner then
                    -- Check if owner is still in game
                    if not plot.owner.Parent then
                        print("HubManager: Owner of plot " .. plotId .. " left, freeing plot")
                        self:FreePlot(plotId)
                    end
                end
            end
        end
    end)
end

function HubManager:StartPlayerMonitoring()
    -- Monitor player positions and handle plot switching
    spawn(function()
        while true do
            wait(5) -- Check every 5 seconds
            
            for _, player in ipairs(Players:GetPlayers()) do
                local character = player.Character
                if character then
                    local playerPosition = character.PrimaryPart.Position
                    local ownedPlotId = self.playerPlots[player.UserId]
                    
                    if ownedPlotId then
                        local plot = self.plots[ownedPlotId]
                        if plot then
                            -- Check if player is near their plot
                            local distanceToPlot = (playerPosition - plot.position).Magnitude
                            if distanceToPlot > PLOT_CONFIG.PLOT_SPACING * 0.8 then
                                -- Player is far from their plot, could offer to teleport back
                                -- This could be expanded with a teleport back system
                            end
                        end
                    end
                end
            end
        end
    end)
end

function HubManager:GetAvailablePlots()
    local available = {}
    for plotId, plot in pairs(self.availablePlots) do
        table.insert(available, {
            id = plotId,
            theme = plot.theme,
            position = plot.position
        })
    end
    return available
end

function HubManager:GetPlayerPlot(player)
    local plotId = self.playerPlots[player.UserId]
    if plotId then
        return self.plots[plotId]
    end
    return nil
end

function HubManager:GetAllPlots()
    return self.plots
end

-- Save hub data to persistent storage
function HubManager:SaveHubData()
    print("HubManager: Saving hub data...")
    
    local hubData = {
        plots = {},
        playerPlots = {},
        timestamp = tick()
    }
    
    -- Save plot data
    for plotId, plot in pairs(self.plots) do
        hubData.plots[plotId] = {
            id = plot.id,
            theme = plot.theme,
            position = plot.position,
            owner = plot.owner and plot.owner.UserId or nil,
            isActive = plot.isActive
        }
    end
    
    -- Save player-plot mappings
    for userId, plotIds in pairs(self.playerPlots) do
        hubData.playerPlots[tostring(userId)] = plotIds
    end
    
    -- Save to DataStore using SaveSystem
    local SaveSystem = require(game:GetService("ServerScriptService").SaveSystem)
    if SaveSystem then
        local success = SaveSystem:SaveHubData(hubData)
        if success then
            print("HubManager: Hub data saved to DataStore successfully!")
        else
            warn("HubManager: Failed to save hub data to DataStore!")
        end
    else
        warn("HubManager: SaveSystem not found, cannot save hub data!")
    end
    
    print("HubManager: Saved " .. #self.plots .. " plots and " .. #self.playerPlots .. " player mappings")
    
    return hubData
end

-- Load hub data from persistent storage
function HubManager:LoadHubData()
    print("HubManager: Loading hub data...")
    
    -- Load from DataStore using SaveSystem
    local SaveSystem = require(game:GetService("ServerScriptService").SaveSystem)
    if SaveSystem then
        local hubData = SaveSystem:LoadHubData()
        if hubData then
            -- Restore plot data
            if hubData.plots then
                for plotId, plotData in pairs(hubData.plots) do
                    if self.plots[plotId] then
                        -- Update existing plot with saved data
                        self.plots[plotId].theme = plotData.theme
                        self.plots[plotId].isActive = plotData.isActive
                        
                                    -- Note: Plot ownership will be restored when players join
            -- This prevents issues with players who are no longer in the game
            -- and ensures proper synchronization
                    end
                end
            end
            
            -- Restore player-plot mappings
            if hubData.playerPlots then
                for userId, plotIds in pairs(hubData.playerPlots) do
                    self.playerPlots[tonumber(userId)] = plotIds
                    
                    -- Mark plots as unavailable
                    for _, plotId in ipairs(plotIds) do
                        if self.plots[plotId] then
                            self.availablePlots[plotId] = nil
                        end
                    end
                end
            end
            
            print("HubManager: Hub data loaded from DataStore successfully!")
            print("HubManager: Restored " .. (hubData.plots and #hubData.plots or 0) .. " plots and " .. (hubData.playerPlots and #hubData.playerPlots or 0) .. " player mappings")
            return true
        else
            print("HubManager: No saved hub data found, starting fresh")
            return false
        end
    else
        warn("HubManager: SaveSystem not found, cannot load hub data!")
        return false
    end
end

-- Get hub statistics
function HubManager:GetHubStats()
    local stats = {
        totalPlots = #self.plots,
        availablePlots = #self.availablePlots,
        ownedPlots = #self.plots - #self.availablePlots,
        totalPlayers = #Players:GetPlayers(),
        playersWithPlots = #self.playerPlots
    }
    
    return stats
end

-- Check if a plot is available
function HubManager:IsPlotAvailable(plotId)
    return self.availablePlots[plotId] ~= nil
end

-- Get plot by ID
function HubManager:GetPlotById(plotId)
    return self.plots[plotId]
end

-- Get all available plot themes
function HubManager:GetAvailableThemes()
    local themes = {}
    for plotId, plot in pairs(self.availablePlots) do
        table.insert(themes, plot.theme)
    end
    return themes
end

-- Get plots by theme
function HubManager:GetPlotsByTheme(theme)
    local themedPlots = {}
    for plotId, plot in pairs(self.plots) do
        if plot.theme == theme then
            table.insert(themedPlots, plot)
        end
    end
    return themedPlots
end

-- Initialize when the script runs
local hubManager = HubManager.new()
hubManager:Initialize()

return hubManager
