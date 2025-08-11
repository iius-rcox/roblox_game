-- HubManager.lua
-- Manages the central hub area for player spawning and tycoon selection
-- ENHANCED: Integrated with anime theme system and world generation

local HubManager = {}
HubManager.__index = HubManager

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Constants
local Constants = require(ReplicatedStorage.Utils.Constants)
local HelperFunctions = require(ReplicatedStorage.Utils.HelperFunctions)

-- Plot configuration - ENHANCED with anime-specific positioning
local PLOT_CONFIG = {
    TOTAL_PLOTS = 20,
    PLOTS_PER_ROW = 5,
    PLOT_SPACING = 200,
    PLOT_SIZE = Vector3.new(150, 50, 150),
    HUB_CENTER = Vector3.new(0, 0, 0),
    HUB_SIZE = Vector3.new(1000, 100, 1000),
    MAX_PLOTS_PER_PLAYER = 3,  -- Players can own up to 3 plots
    -- NEW: Anime-specific plot positioning (4x5 grid, 150x150 studs, 50 stud spacing)
    ANIME_PLOT_SPACING = 200,  -- 150 + 50 spacing
    ANIME_PLOT_SIZE = Vector3.new(150, 50, 150),
    ANIME_HUB_SIZE = Vector3.new(1200, 100, 1200)  -- Larger hub for anime themes
}

-- ENHANCED: Use anime themes from Constants instead of generic themes
local function GetAnimePlotThemes()
    if Constants.ANIME_THEMES then
        local themes = {}
        local themeNames = {}
        
        -- Get all anime theme names
        for themeName, _ in pairs(Constants.ANIME_THEMES) do
            if themeName ~= "AVATAR_THE_LAST_AIRBENDER" then  -- Exclude avatar theme
                table.insert(themeNames, themeName)
            end
        end
        
        -- Sort themes for consistent ordering
        table.sort(themeNames)
        
        -- Map to plot themes
        for i, themeName in ipairs(themeNames) do
            themes[i] = themeName
        end
        
        return themes
    else
        -- Fallback to original themes if anime themes not available
        return {
            "Anime", "Meme", "Gaming", "Music", "Sports",
            "Food", "Travel", "Technology", "Nature", "Space",
            "Fantasy", "SciFi", "Horror", "Comedy", "Action",
            "Romance", "Mystery", "Adventure", "Strategy", "Racing"
        }
    end
end

local PLOT_THEMES = GetAnimePlotThemes()

function HubManager.new()
    local self = setmetatable({}, HubManager)
    
    -- Initialize data structures
    self.plots = {}
    self.availablePlots = {}
    self.playerPlots = {}  -- Stores array of plot IDs per player
    self.plotQueue = {}
    self.hubWorld = nil
    self.plotSelector = nil
    
    -- ENHANCED: Anime theme integration
    self.animeThemeData = {}
    self.themeDecorations = {}
    self.plotThemeAssignments = {}
    
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
        "PlotSwitched",  -- For switching between owned plots
        "ShowOwnedPlots",  -- Show player's owned plots
        -- NEW: Anime-specific remotes
        "AnimeThemePreview",
        "PlotThemeUpdate",
        "AnimeProgressionSync",
        "ThemeDecorationUpdate"
    }
    
    -- Create RemoteFunctions for client-server communication
    local remoteFunctions = {
        "ClaimPlot",
        "SwitchToPlot",  -- Switch to a different owned plot
        "GetOwnedPlots",  -- Get list of player's owned plots
        -- NEW: Anime-specific functions
        "GetAnimeThemeData",
        "GetPlotThemeInfo",
        "RequestThemeChange",
        "GetAnimeProgression"
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
    
    -- Set up SwitchToPlot RemoteFunction handler
    if self.remotes.SwitchToPlot then
        self.remotes.SwitchToPlot.OnServerInvoke:Connect(function(player, plotId)
            print("HubManager: Player " .. player.Name .. " requesting to switch to plot " .. plotId)
            return self:SwitchPlayerToPlot(player, plotId)
        end)
    end
    
    -- Set up GetOwnedPlots RemoteFunction handler
    if self.remotes.GetOwnedPlots then
        self.remotes.GetOwnedPlots.OnServerInvoke:Connect(function(player)
            print("HubManager: Player " .. player.Name .. " requesting owned plots list")
            return self:GetPlayerOwnedPlots(player)
        end)
    end
    
    -- NEW: Set up anime-specific RemoteFunction handlers
    if self.remotes.GetAnimeThemeData then
        self.remotes.GetAnimeThemeData.OnServerInvoke:Connect(function(player, themeName)
            return self:GetAnimeThemeData(themeName)
        end)
    end
    
    if self.remotes.GetPlotThemeInfo then
        self.remotes.GetPlotThemeInfo.OnServerInvoke:Connect(function(player, plotId)
            return self:GetPlotThemeInfo(plotId)
        end)
    end
    
    if self.remotes.RequestThemeChange then
        self.remotes.RequestThemeChange.OnServerInvoke:Connect(function(player, plotId, newTheme)
            return self:RequestThemeChange(player, plotId, newTheme)
        end)
    end
    
    if self.remotes.GetAnimeProgression then
        self.remotes.GetAnimeProgression.OnServerInvoke:Connect(function(player, themeName)
            return self:GetAnimeProgression(themeName)
        end)
    end
end

function HubManager:Initialize()
    print("HubManager: Initializing enhanced hub system with anime themes...")
    
    -- Initialize anime theme system
    self:InitializeAnimeThemeSystem()
    
    -- Create hub world
    self:CreateHubWorld()
    
    -- Create all 20 plots with anime themes
    self:CreateAllPlots()
    
    -- Load saved hub data
    self:LoadHubData()
    
    -- Set up player management
    self:SetupPlayerManagement()
    
    -- Start hub systems
    self:StartHubSystems()
    
    print("HubManager: Enhanced hub system initialized successfully!")
end

-- NEW: Initialize anime theme system
function HubManager:InitializeAnimeThemeSystem()
    print("HubManager: Initializing anime theme system...")
    
    if Constants.ANIME_THEMES then
        -- Store anime theme data for quick access
        for themeName, themeData in pairs(Constants.ANIME_THEMES) do
            if themeName ~= "AVATAR_THE_LAST_AIRBENDER" then
                self.animeThemeData[themeName] = themeData
                print("HubManager: Loaded anime theme:", themeName)
            end
        end
        
        -- Initialize theme decorations
        self:InitializeThemeDecorations()
        
        print("HubManager: Anime theme system initialized with", #self.animeThemeData, "themes")
    else
        warn("HubManager: Anime themes not available, using fallback themes")
    end
end

-- NEW: Initialize theme decorations
function HubManager:InitializeThemeDecorations()
    for themeName, themeData in pairs(self.animeThemeData) do
        self.themeDecorations[themeName] = {
            colors = themeData.colors or {},
            materials = themeData.materials or {},
            effects = themeData.effects or {},
            structures = themeData.structures or {},
            props = themeData.props or {}
        }
    end
end

function HubManager:CreateHubWorld()
    print("HubManager: Creating enhanced hub world with anime themes...")
    
    -- Create hub base
    local hubBase = Instance.new("Part")
    hubBase.Name = "HubBase"
    hubBase.Size = PLOT_CONFIG.ANIME_HUB_SIZE
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
    
    -- Create hub center building with anime theme
    local centerBuilding = Instance.new("Part")
    centerBuilding.Name = "HubCenter"
    centerBuilding.Size = Vector3.new(80, 60, 80)
    centerBuilding.Position = PLOT_CONFIG.HUB_CENTER + Vector3.new(0, 30, 0)
    centerBuilding.Anchored = true
    centerBuilding.Material = Enum.Material.Brick
    centerBuilding.BrickColor = BrickColor.new("Bright yellow")
    centerBuilding.Parent = workspace
    
    -- Create welcome sign with anime theme
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
    textLabel.Text = "Welcome to Anime Tycoon Hub!"
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Parent = surfaceGui
    
    -- NEW: Create anime theme showcase area
    self:CreateAnimeThemeShowcase()
    
    self.hubWorld = {
        base = hubBase,
        spawnArea = spawnArea,
        centerBuilding = centerBuilding,
        welcomeSign = welcomeSign
    }
    
    print("HubManager: Enhanced hub world created successfully!")
end

-- NEW: Create anime theme showcase area
function HubManager:CreateAnimeThemeShowcase()
    local showcasePosition = PLOT_CONFIG.HUB_CENTER + Vector3.new(0, 80, -100)
    
    -- Create showcase base
    local showcaseBase = Instance.new("Part")
    showcaseBase.Name = "AnimeThemeShowcase"
    showcaseBase.Size = Vector3.new(200, 10, 100)
    showcaseBase.Position = showcasePosition
    showcaseBase.Anchored = true
    showcaseBase.Material = Enum.Material.Neon
    showcaseBase.BrickColor = BrickColor.new("Really black")
    showcaseBase.Transparency = 0.2
    showcaseBase.Parent = workspace
    
    -- Create theme display boards
    local displayCount = math.min(5, #PLOT_THEMES)  -- Show first 5 themes
    for i = 1, displayCount do
        local themeName = PLOT_THEMES[i]
        local themeData = self.animeThemeData[themeName]
        
        if themeData then
            local displayBoard = Instance.new("Part")
            displayBoard.Name = "ThemeDisplay_" .. themeName
            displayBoard.Size = Vector3.new(30, 40, 2)
            displayBoard.Position = showcasePosition + Vector3.new((i - 3) * 35, 25, 0)
            displayBoard.Anchored = true
            displayBoard.Material = Enum.Material.Neon
            displayBoard.BrickColor = themeData.colors and themeData.colors.primary and 
                                    BrickColor.new(themeData.colors.primary) or 
                                    BrickColor.new("Bright blue")
            displayBoard.Parent = workspace
            
            -- Add theme information
            local surfaceGui = Instance.new("SurfaceGui")
            surfaceGui.Name = "ThemeInfo"
            surfaceGui.Parent = displayBoard
            surfaceGui.Face = Enum.NormalId.Front
            
            local textLabel = Instance.new("TextLabel")
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            textLabel.BackgroundTransparency = 1
            textLabel.Text = themeName .. "\n" .. (themeData.description or "Anime Theme")
            textLabel.TextColor3 = Color3.new(1, 1, 1)
            textLabel.TextScaled = true
            textLabel.Font = Enum.Font.Gotham
            textLabel.Parent = surfaceGui
        end
    end
end

function HubManager:CreateAllPlots()
    print("HubManager: Creating " .. PLOT_CONFIG.TOTAL_PLOTS .. " anime-themed plots...")
    
    local plotsPerRow = PLOT_CONFIG.PLOTS_PER_ROW
    local rows = math.ceil(PLOT_CONFIG.TOTAL_PLOTS / plotsPerRow)
    
    for i = 1, PLOT_CONFIG.TOTAL_PLOTS do
        local row = math.ceil(i / plotsPerRow)
        local col = ((i - 1) % plotsPerRow) + 1
        
        -- Calculate plot position (arrange in a grid around the hub)
        local offsetX = (col - (plotsPerRow + 1) / 2) * PLOT_CONFIG.ANIME_PLOT_SPACING
        local offsetZ = (row - (rows + 1) / 2) * PLOT_CONFIG.ANIME_PLOT_SPACING
        
        local plotPosition = PLOT_CONFIG.HUB_CENTER + Vector3.new(offsetX, 0, offsetZ)
        
        -- Create plot with anime theme
        local plot = self:CreateAnimePlot(i, plotPosition, PLOT_THEMES[i])
        self.plots[i] = plot
        self.availablePlots[i] = plot
        
        -- Store theme assignment
        self.plotThemeAssignments[i] = PLOT_THEMES[i]
        
        print("HubManager: Created anime plot " .. i .. " with theme '" .. PLOT_THEMES[i] .. "' at position " .. tostring(plotPosition))
    end
    
    print("HubManager: All anime-themed plots created successfully!")
end

-- ENHANCED: Create anime-themed plot
function HubManager:CreateAnimePlot(plotId, position, themeName)
    local plot = {
        id = plotId,
        position = position,
        theme = themeName,
        owner = nil,
        isActive = false,
        tycoonInstance = nil,
        plotPart = nil,
        statusSign = nil,
        -- NEW: Anime-specific data
        animeThemeData = self.animeThemeData[themeName] or {},
        themeDecorations = self.themeDecorations[themeName] or {},
        progressionLevel = 1,
        characterSpawners = {},
        powerUpSystems = {},
        collectionSystems = {}
    }
    
    -- Create plot base with anime theme colors
    local plotBase = Instance.new("Part")
    plotBase.Name = "Plot_" .. plotId
    plotBase.Size = PLOT_CONFIG.ANIME_PLOT_SIZE
    plotBase.Position = position + Vector3.new(0, PLOT_CONFIG.ANIME_PLOT_SIZE.Y / 2, 0)
    plotBase.Anchored = true
    plotBase.Material = Enum.Material.Concrete
    
    -- Apply anime theme colors if available
    local themeColors = plot.animeThemeData.colors
    if themeColors and themeColors.primary then
        plotBase.BrickColor = BrickColor.new(themeColors.primary)
    else
        plotBase.BrickColor = BrickColor.new("Medium stone grey")
    end
    
    plotBase.Parent = workspace
    
    -- Create plot border with anime theme
    local plotBorder = Instance.new("Part")
    plotBorder.Name = "PlotBorder_" .. plotId
    plotBorder.Size = Vector3.new(PLOT_CONFIG.ANIME_PLOT_SIZE.X + 10, 5, PLOT_CONFIG.ANIME_PLOT_SIZE.Z + 10)
    plotBorder.Position = position + Vector3.new(0, PLOT_CONFIG.ANIME_PLOT_SIZE.Y + 2.5, 0)
    plotBorder.Anchored = true
    plotBorder.Material = Enum.Material.Neon
    
    -- Apply anime theme border color
    if themeColors and themeColors.accent then
        plotBorder.BrickColor = BrickColor.new(themeColors.accent)
    else
        plotBorder.BrickColor = BrickColor.new("Bright blue")
    end
    
    plotBorder.Parent = workspace
    
    -- Create enhanced status sign with anime theme info
    local statusSign = Instance.new("Part")
    statusSign.Name = "StatusSign_" .. plotId
    statusSign.Size = Vector3.new(25, 20, 2)
    statusSign.Position = position + Vector3.new(0, PLOT_CONFIG.ANIME_PLOT_SIZE.Y + 25, PLOT_CONFIG.ANIME_PLOT_SIZE.Z / 2 + 10)
    statusSign.Anchored = true
    statusSign.Material = Enum.Material.Neon
    
    -- Apply anime theme sign color
    if themeColors and themeColors.secondary then
        statusSign.BrickColor = BrickColor.new(themeColors.secondary)
    else
        statusSign.BrickColor = BrickColor.new("Bright green")
    end
    
    statusSign.Parent = workspace
    
    -- Add enhanced surface GUI to status sign
    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Name = "StatusSignGui"
    surfaceGui.Parent = statusSign
    surfaceGui.Face = Enum.NormalId.Front
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "Plot " .. plotId .. "\n" .. themeName .. "\nAvailable\nE-Rank"
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.Gotham
    textLabel.Parent = surfaceGui
    
    -- Create plot selection trigger
    local selectionTrigger = Instance.new("Part")
    selectionTrigger.Name = "SelectionTrigger_" .. plotId
    selectionTrigger.Size = Vector3.new(PLOT_CONFIG.ANIME_PLOT_SIZE.X + 20, 10, PLOT_CONFIG.ANIME_PLOT_SIZE.Z + 20)
    selectionTrigger.Position = position + Vector3.new(0, PLOT_CONFIG.ANIME_PLOT_SIZE.Y + 5, 0)
    selectionTrigger.Anchored = true
    selectionTrigger.Material = Enum.Material.SmoothPlastic
    selectionTrigger.BrickColor = BrickColor.new("Really black")
    selectionTrigger.Transparency = 0.9
    selectionTrigger.CanCollide = false
    selectionTrigger.Parent = workspace
    
    -- Store plot components
    plot.plotPart = plotBase
    plot.statusSign = statusSign
    plot.selectionTrigger = selectionTrigger
    
    -- NEW: Add click detection for plot selection
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.Parent = selectionTrigger
    
    -- Set up click detection
    clickDetector.MouseClick:Connect(function(player)
        self:HandlePlotSelection(player, plotId)
    end)
    
    return plot
end

-- NEW: Enhanced plot selection with anime theme preview
function HubManager:HandlePlotSelection(player, plotId)
    print("HubManager: Player " .. player.Name .. " selected anime plot " .. plotId)
    
    local plot = self.plots[plotId]
    if not plot then
        print("HubManager: Error - Plot " .. plotId .. " not found!")
        return
    end
    
    if plot.owner then
        -- Plot is owned, show owner info with anime theme details
        self:ShowAnimePlotOwnerInfo(player, plot)
    else
        -- Plot is available, show claim option with anime theme preview
        self:ShowAnimePlotClaimOption(player, plot)
    end
end

-- NEW: Show anime plot owner info
function HubManager:ShowAnimePlotOwnerInfo(player, plot)
    local owner = Players:GetPlayerByUserId(plot.owner)
    local ownerName = owner and owner.Name or "Unknown"
    
    -- Create enhanced notification with anime theme info
    local message = string.format("Plot %d (%s) is owned by %s\nProgression: %s", 
        plot.id, plot.theme, ownerName, 
        plot.progressionLevel and "Level " .. plot.progressionLevel or "E-Rank")
    
    HelperFunctions.CreateNotification(player, message, 5)
    
    -- Show detailed anime theme info
    self:ShowAnimeThemeDetails(player, plot)
end

-- NEW: Show anime plot claim option with theme preview
function HubManager:ShowAnimePlotClaimOption(player, plot)
    -- Create enhanced claim UI with anime theme preview
    local claimData = {
        plotId = plot.id,
        theme = plot.theme,
        position = plot.position,
        animeThemeData = plot.animeThemeData,
        themeDecorations = plot.themeDecorations,
        progressionInfo = self:GetAnimeProgression(plot.theme)
    }
    
    self.remotes.ShowPlotMenu:FireClient(player, claimData)
    
    -- Also fire anime theme preview event
    self.remotes.AnimeThemePreview:FireClient(player, {
        plotId = plot.id,
        theme = plot.theme,
        themeData = plot.animeThemeData,
        decorations = plot.themeDecorations
    })
end

-- NEW: Show anime theme details
function HubManager:ShowAnimeThemeDetails(player, plot)
    local themeData = plot.animeThemeData
    if not themeData then return end
    
    local details = {
        plotId = plot.id,
        theme = plot.theme,
        description = themeData.description or "Anime theme",
        colors = themeData.colors or {},
        materials = themeData.materials or {},
        effects = themeData.effects or {},
        progression = plot.progressionLevel or 1
    }
    
    self.remotes.PlotThemeUpdate:FireClient(player, details)
end

function HubManager:ClaimPlot(player, plotId)
    print("HubManager: Player " .. player.Name .. " claiming anime plot " .. plotId)
    
    local plot = self.plots[plotId]
    if not plot then
        print("HubManager: Error - Plot " .. plotId .. " not found!")
        return false
    end
    
    if plot.owner then
        print("HubManager: Error - Plot " .. plotId .. " is already owned!")
        return false
    end
    
    -- Check if player already owns maximum number of plots
    local ownedPlots = self:GetPlayerOwnedPlots(player)
    if #ownedPlots >= PLOT_CONFIG.MAX_PLOTS_PER_PLAYER then
        print("HubManager: Error - Player " .. player.Name .. " already owns maximum number of plots (" .. PLOT_CONFIG.MAX_PLOTS_PER_PLAYER .. ")")
        return false
    end
    
    -- Assign plot to player
    plot.owner = player.UserId
    plot.isActive = true
    
    -- Add to player's owned plots array
    if not self.playerPlots[player.UserId] then
        self.playerPlots[player.UserId] = {}
    end
    table.insert(self.playerPlots[player.UserId], plotId)
    
    -- Remove from available plots
    self.availablePlots[plotId] = nil
    
    -- Update plot status with anime theme info
    self:UpdateAnimePlotStatus(plotId)
    
    -- Create tycoon for the player with anime theme
    self:CreateAnimeTycoonForPlayer(player, plot)
    
    -- Notify client with enhanced data
    self.remotes.PlotClaimed:FireClient(player, {
        plotId = plotId,
        theme = plot.theme,
        animeThemeData = plot.animeThemeData,
        progressionLevel = plot.progressionLevel
    })
    
    -- Notify all clients of plot status change
    self.remotes.UpdatePlotStatus:FireAllClients({
        plotId = plotId,
        owner = player.Name,
        theme = plot.theme,
        isAvailable = false,
        progressionLevel = plot.progressionLevel
    })
    
    print("HubManager: Player " .. player.Name .. " successfully claimed anime plot " .. plotId .. " with theme '" .. plot.theme .. "'")
    return true
end

-- NEW: Enhanced plot status update with anime theme info
function HubManager:UpdateAnimePlotStatus(plotId)
    local plot = self.plots[plotId]
    if not plot then return end
    
    -- Update status sign with anime theme info
    if plot.statusSign then
        local surfaceGui = plot.statusSign:FindFirstChild("StatusSignGui")
        if surfaceGui then
            local textLabel = surfaceGui:FindFirstChild("TextLabel")
            if textLabel then
                local statusText = "Plot " .. plotId .. "\n" .. plot.theme
                
                if plot.owner then
                    local owner = Players:GetPlayerByUserId(plot.owner)
                    local ownerName = owner and owner.Name or "Unknown"
                    statusText = statusText .. "\nOwned by " .. ownerName .. "\nLevel " .. (plot.progressionLevel or 1)
                    
                    -- Apply anime theme colors to owned plot
                    local themeColors = plot.animeThemeData.colors
                    if themeColors and themeColors.owned then
                        plot.statusSign.BrickColor = BrickColor.new(themeColors.owned)
                    end
                else
                    statusText = statusText .. "\nAvailable\nE-Rank"
                    
                    -- Apply anime theme colors to available plot
                    local themeColors = plot.animeThemeData.colors
                    if themeColors and themeColors.available then
                        plot.statusSign.BrickColor = BrickColor.new(themeColors.available)
                    end
                end
                
                textLabel.Text = statusText
            end
        end
    end
end

-- NEW: Create anime tycoon for player
function HubManager:CreateAnimeTycoonForPlayer(player, plot)
    print("HubManager: Creating anime tycoon for player " .. player.Name .. " on plot " .. plot.id)
    
    -- Create proper TycoonBase instance with ability buttons
    local success, tycoonBase = pcall(function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local TycoonBase = require(ReplicatedStorage:WaitForChild("Tycoon"):WaitForChild("TycoonBase"))
        return TycoonBase.new("tycoon_" .. plot.id, plot.position, player)
    end)
    
    if not success or not tycoonBase then
        warn("HubManager: Failed to create TycoonBase for plot " .. plot.id .. ", falling back to basic structure")
        
        -- Fallback to basic structure
        local basicBase = Instance.new("Part")
        basicBase.Name = "AnimeTycoon_" .. plot.id
        basicBase.Size = Vector3.new(100, 10, 100)
        basicBase.Position = plot.position + Vector3.new(0, 30, 0)
        basicBase.Anchored = true
        basicBase.Material = Enum.Material.Brick
        
        -- Apply anime theme colors
        local themeColors = plot.animeThemeData.colors
        if themeColors and themeColors.primary then
            basicBase.BrickColor = BrickColor.new(themeColors.primary)
        else
            basicBase.BrickColor = BrickColor.new("Medium stone grey")
        end
        
        basicBase.Parent = workspace
        
        -- Create spawn location for the player
        local spawnLocation = Instance.new("Part")
        spawnLocation.Name = "SpawnLocation_" .. plot.id
        spawnLocation.Size = Vector3.new(10, 10, 10)
        spawnLocation.Position = plot.position + Vector3.new(0, 45, 0)
        spawnLocation.Anchored = true
        spawnLocation.Material = Enum.Material.Neon
        spawnLocation.BrickColor = BrickColor.new("Bright green")
        spawnLocation.Transparency = 0.3
        spawnLocation.CanCollide = false
        spawnLocation.Parent = workspace
        
        -- Store basic tycoon instance
        plot.tycoonInstance = {
            base = basicBase,
            spawnLocation = spawnLocation,
            isBasic = true
        }
        
        print("HubManager: Basic anime tycoon created for plot " .. plot.id .. " with theme '" .. plot.theme .. "'")
        return
    end
    
    -- Create spawn location for the player
    local spawnLocation = Instance.new("Part")
    spawnLocation.Name = "SpawnLocation_" .. plot.id
    spawnLocation.Size = Vector3.new(10, 10, 10)
    spawnLocation.Position = plot.position + Vector3.new(0, 45, 0)
    spawnLocation.Anchored = true
    spawnLocation.Material = Enum.Material.Neon
    spawnLocation.BrickColor = BrickColor.new("Bright green")
    spawnLocation.Transparency = 0.3
    spawnLocation.CanCollide = false
    spawnLocation.Parent = workspace
    
    -- Store proper tycoon instance
    plot.tycoonInstance = {
        base = tycoonBase,
        spawnLocation = spawnLocation,
        isBasic = false
    }
    
    -- Set owner and show UI for the player
    if tycoonBase.SetOwner then
        tycoonBase:SetOwner(player)
    end
    
    if tycoonBase.ShowUI then
        tycoonBase:ShowUI(player)
    end
    
    print("HubManager: Full anime tycoon with ability buttons created for plot " .. plot.id .. " with theme '" .. plot.theme .. "'")
end

-- NEW: Get TycoonBase instance from plot
function HubManager:GetTycoonBaseFromPlot(plotId)
    local plot = self.plots[plotId]
    if not plot or not plot.tycoonInstance then
        return nil
    end
    
    -- Return the TycoonBase instance if it exists and is not basic
    if plot.tycoonInstance.base and not plot.tycoonInstance.isBasic then
        return plot.tycoonInstance.base
    end
    
    return nil
end

-- NEW: Get all TycoonBase instances
function HubManager:GetAllTycoonBases()
    local tycoonBases = {}
    
    for plotId, plot in pairs(self.plots) do
        if plot.tycoonInstance and plot.tycoonInstance.base and not plot.tycoonInstance.isBasic then
            tycoonBases[plotId] = plot.tycoonInstance.base
        end
    end
    
    return tycoonBases
end

-- NEW: Switch player to different owned plot
function HubManager:SwitchPlayerToPlot(player, plotId)
    print("HubManager: Player " .. player.Name .. " requesting to switch to plot " .. plotId)
    
    local plot = self.plots[plotId]
    if not plot then
        print("HubManager: Error - Plot " .. plotId .. " not found!")
        return false
    end
    
    if plot.owner ~= player.UserId then
        print("HubManager: Error - Player " .. player.Name .. " doesn't own plot " .. plotId)
        return false
    end
    
    -- Check cooldown (5 seconds between switches)
    local lastSwitch = self.playerPlotSwitchCooldowns and self.playerPlotSwitchCooldowns[player.UserId] or 0
    local currentTime = time()
    
    if currentTime - lastSwitch < 5 then
        print("HubManager: Error - Plot switching cooldown active for player " .. player.Name)
        return false
    end
    
    -- Update cooldown
    if not self.playerPlotSwitchCooldowns then
        self.playerPlotSwitchCooldowns = {}
    end
    self.playerPlotSwitchCooldowns[player.UserId] = currentTime
    
    -- Teleport player to plot
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local spawnLocation = plot.tycoonInstance and plot.tycoonInstance.spawnLocation
        if spawnLocation then
            player.Character.HumanoidRootPart.CFrame = CFrame.new(spawnLocation.Position + Vector3.new(0, 3, 0))
        else
            player.Character.HumanoidRootPart.CFrame = CFrame.new(plot.position + Vector3.new(0, 10, 0))
        end
    end
    
    -- Notify client
    self.remotes.PlotSwitched:FireClient(player, {
        plotId = plotId,
        theme = plot.theme,
        animeThemeData = plot.animeThemeData,
        progressionLevel = plot.progressionLevel
    })
    
    print("HubManager: Player " .. player.Name .. " successfully switched to anime plot " .. plotId)
    return true
end

-- NEW: Get player's owned plots with anime theme info
function HubManager:GetPlayerOwnedPlots(player)
    local ownedPlotIds = self.playerPlots[player.UserId] or {}
    local ownedPlots = {}
    
    for _, plotId in ipairs(ownedPlotIds) do
        local plot = self.plots[plotId]
        if plot then
            table.insert(ownedPlots, {
                id = plotId,
                theme = plot.theme,
                animeThemeData = plot.animeThemeData,
                progressionLevel = plot.progressionLevel,
                position = plot.position,
                isActive = plot.isActive
            })
        end
    end
    
    return ownedPlots
end

-- NEW: Get plots by anime theme
function HubManager:GetPlotsByAnimeTheme(themeName)
    local themedPlots = {}
    
    for plotId, plot in pairs(self.plots) do
        if plot.theme == themeName then
            table.insert(themedPlots, {
                id = plotId,
                theme = plot.theme,
                owner = plot.owner,
                isAvailable = plot.owner == nil,
                animeThemeData = plot.animeThemeData,
                progressionLevel = plot.progressionLevel,
                position = plot.position
            })
        end
    end
    
    return themedPlots
end

-- NEW: Get all available anime themes
function HubManager:GetAllAnimeThemes()
    local themes = {}
    
    for themeName, _ in pairs(self.animeThemeData) do
        table.insert(themes, {
            name = themeName,
            description = self.animeThemeData[themeName].description or "Anime theme",
            colors = self.animeThemeData[themeName].colors or {},
            materials = self.animeThemeData[themeName].materials or {},
            effects = self.animeThemeData[themeName].effects or {},
            plotCount = #self:GetPlotsByAnimeTheme(themeName)
        })
    end
    
    return themes
end

-- NEW: Update anime progression for a plot
function HubManager:UpdateAnimeProgression(plotId, newLevel)
    local plot = self.plots[plotId]
    if not plot then return false end
    
    plot.progressionLevel = newLevel or 1
    
    -- Update plot status
    self:UpdateAnimePlotStatus(plotId)
    
    -- Notify clients of progression update
    self.remotes.AnimeProgressionSync:FireAllClients({
        plotId = plotId,
        theme = plot.theme,
        progressionLevel = plot.progressionLevel,
        owner = plot.owner
    })
    
    return true
end

-- NEW: Get anime theme statistics
function HubManager:GetAnimeThemeStats()
    local stats = {}
    
    for themeName, _ in pairs(self.animeThemeData) do
        local themedPlots = self:GetPlotsByAnimeTheme(themeName)
        local ownedPlots = 0
        local totalProgression = 0
        
        for _, plot in ipairs(themedPlots) do
            if plot.owner then
                ownedPlots = ownedPlots + 1
                totalProgression = totalProgression + (plot.progressionLevel or 1)
            end
        end
        
        stats[themeName] = {
            totalPlots = #themedPlots,
            ownedPlots = ownedPlots,
            availablePlots = #themedPlots - ownedPlots,
            averageProgression = ownedPlots > 0 and totalProgression / ownedPlots or 0
        }
    end
    
    return stats
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
    
    -- Restore plot ownership from saved data
    local ownedPlotIds = self.playerPlots[player.UserId]
    if ownedPlotIds and #ownedPlotIds > 0 then
        print("HubManager: Restoring " .. #ownedPlotIds .. " plots for " .. player.Name)
        
        -- Restore plot ownership
        for _, plotId in ipairs(ownedPlotIds) do
            if self.plots[plotId] then
                self.plots[plotId].owner = player.UserId
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
    
    -- Remove from player's owned plots
    if previousOwner and self.playerPlots[previousOwner] then
        for i, ownedPlotId in ipairs(self.playerPlots[previousOwner]) do
            if ownedPlotId == plotId then
                table.remove(self.playerPlots[previousOwner], i)
                break
            end
        end
        
        -- If player has no more plots, clean up the entry
        if #self.playerPlots[previousOwner] == 0 then
            self.playerPlots[previousOwner] = nil
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
    
    print("HubManager: Plot " .. plotId .. " freed successfully from " .. (previousOwner and Players:GetPlayerByUserId(previousOwner) and Players:GetPlayerByUserId(previousOwner).Name or "unknown"))
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
                    if not Players:GetPlayerByUserId(plot.owner) then
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
                if character and character.PrimaryPart then
                    local playerPosition = character.PrimaryPart.Position
                    local ownedPlotIds = self.playerPlots[player.UserId]
                    
                    if ownedPlotIds and #ownedPlotIds > 0 then
                        -- Check distance to all owned plots
                        for _, plotId in ipairs(ownedPlotIds) do
                            local plot = self.plots[plotId]
                            if plot then
                                local distanceToPlot = (playerPosition - plot.position).Magnitude
                                if distanceToPlot > PLOT_CONFIG.ANIME_PLOT_SPACING * 0.8 then
                                    -- Player is far from this plot, could offer to teleport back
                                    -- This could be expanded with a teleport back system
                                end
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
            position = plot.position,
            animeThemeData = plot.animeThemeData,
            themeDecorations = plot.themeDecorations
        })
    end
    return available
end

-- NEW: Get player's current active plot (first owned plot)
function HubManager:GetPlayerCurrentPlot(player)
    local ownedPlotIds = self.playerPlots[player.UserId]
    if ownedPlotIds and #ownedPlotIds > 0 then
        return self.plots[ownedPlotIds[1]]
    end
    return nil
end

function HubManager:GetPlayerPlot(player)
    -- Return first owned plot for backward compatibility
    return self:GetPlayerCurrentPlot(player)
end

function HubManager:GetAllPlots()
    return self.plots
end

-- NEW: Get plots with anime theme filtering
function HubManager:GetPlotsByFilter(filterType, filterValue)
    if filterType == "theme" then
        return self:GetPlotsByAnimeTheme(filterValue)
    elseif filterType == "status" then
        if filterValue == "available" then
            return self:GetAvailablePlots()
        elseif filterValue == "owned" then
            local ownedPlots = {}
            for plotId, plot in pairs(self.plots) do
                if plot.owner then
                    table.insert(ownedPlots, {
                        id = plotId,
                        theme = plot.theme,
                        owner = plot.owner,
                        animeThemeData = plot.animeThemeData,
                        progressionLevel = plot.progressionLevel,
                        position = plot.position
                    })
                end
            end
            return ownedPlots
        end
    end
    
    return {}
end

-- Save hub data to persistent storage
function HubManager:SaveHubData()
    print("HubManager: Saving enhanced hub data with anime themes...")
    
    local hubData = {
        plots = {},
        playerPlots = {},
        plotThemeAssignments = self.plotThemeAssignments,
        timestamp = time()
    }
    
    -- Save plot data with anime theme info
    for plotId, plot in pairs(self.plots) do
        hubData.plots[plotId] = {
            id = plot.id,
            theme = plot.theme,
            position = plot.position,
            owner = plot.owner,
            isActive = plot.isActive,
            progressionLevel = plot.progressionLevel,
            animeThemeData = plot.animeThemeData
        }
    end
    
    -- Save player-plot mappings
    for userId, plotIds in pairs(self.playerPlots) do
        hubData.playerPlots[tostring(userId)] = plotIds
    end
    
    -- TODO: Save to DataStore when SaveSystem is implemented
    print("HubManager: Enhanced hub data prepared for saving")
    
    return hubData
end

-- Load hub data from persistent storage
function HubManager:LoadHubData()
    print("HubManager: Loading enhanced hub data...")
    
    -- TODO: Load from DataStore when SaveSystem is implemented
    -- For now, use default data
    print("HubManager: Using default hub data (DataStore integration pending)")
end

-- NEW: Broadcast plot status update with anime theme info
function HubManager:BroadcastPlotStatusUpdate(plotId, isAvailable, ownerName)
    local plot = self.plots[plotId]
    if not plot then return end
    
    local updateData = {
        plotId = plotId,
        theme = plot.theme,
        isAvailable = isAvailable,
        owner = ownerName,
        animeThemeData = plot.animeThemeData,
        progressionLevel = plot.progressionLevel
    }
    
    self.remotes.UpdatePlotStatus:FireAllClients(updateData)
end

-- NEW: Get hub statistics for admin/analytics
function HubManager:GetHubStatistics()
    local stats = {
        totalPlots = PLOT_CONFIG.TOTAL_PLOTS,
        availablePlots = #self.availablePlots,
        ownedPlots = PLOT_CONFIG.TOTAL_PLOTS - #self.availablePlots,
        totalPlayers = #Players:GetPlayers(),
        playersWithPlots = 0,
        animeThemeStats = self:GetAnimeThemeStats(),
        averagePlotsPerPlayer = 0
    }
    
    -- Calculate players with plots
    for userId, plotIds in pairs(self.playerPlots) do
        if plotIds and #plotIds > 0 then
            stats.playersWithPlots = stats.playersWithPlots + 1
        end
    end
    
    -- Calculate average plots per player
    if stats.playersWithPlots > 0 then
        stats.averagePlotsPerPlayer = stats.ownedPlots / stats.playersWithPlots
    end
    
    return stats
end

-- NEW: Validate anime theme system
function HubManager:ValidateAnimeThemeSystem()
    print("HubManager: Validating anime theme system...")
    
    local validationResults = {
        success = true,
        errors = {},
        warnings = {},
        themeCount = 0,
        plotAssignments = 0
    }
    
    -- Check if anime themes are loaded
    if not self.animeThemeData or not next(self.animeThemeData) then
        validationResults.success = false
        table.insert(validationResults.errors, "No anime themes loaded")
    else
        validationResults.themeCount = 0
        for themeName, _ in pairs(self.animeThemeData) do
            if themeName ~= "AVATAR_THE_LAST_AIRBENDER" then
                validationResults.themeCount = validationResults.themeCount + 1
            end
        end
    end
    
    -- Check plot theme assignments
    if self.plotThemeAssignments then
        validationResults.plotAssignments = 0
        for plotId, theme in pairs(self.plotThemeAssignments) do
            if theme and self.animeThemeData[theme] then
                validationResults.plotAssignments = validationResults.plotAssignments + 1
            else
                table.insert(validationResults.warnings, "Plot " .. plotId .. " has invalid theme: " .. tostring(theme))
            end
        end
    end
    
    -- Check if all plots have valid themes
    if validationResults.plotAssignments < PLOT_CONFIG.TOTAL_PLOTS then
        table.insert(validationResults.warnings, "Not all plots have valid anime themes assigned")
    end
    
    if validationResults.success then
        print("HubManager: Anime theme system validation successful!")
        print("  - Themes loaded: " .. validationResults.themeCount)
        print("  - Plot assignments: " .. validationResults.plotAssignments .. "/" .. PLOT_CONFIG.TOTAL_PLOTS)
    else
        print("HubManager: Anime theme system validation failed!")
        for _, error in ipairs(validationResults.errors) do
            print("  - Error: " .. error)
        end
    end
    
    for _, warning in ipairs(validationResults.warnings) do
        print("  - Warning: " .. warning)
    end
    
    return validationResults
end

-- Initialize when the script runs
if script.Parent and script.Parent:IsA("ServerScriptService") then
    local hubManager = HubManager.new()
    hubManager:Initialize()
    
    -- Validate anime theme system
    wait(2) -- Wait for initialization to complete
    hubManager:ValidateAnimeThemeSystem()
    
    print("HubManager: Enhanced anime tycoon hub system ready!")
else
    print("HubManager: Script must be placed in ServerScriptService to run automatically")
end

return HubManager
