--[[
    WorldGenerator.lua
    Step 2: World Generation Core System
    
    Handles the generation of the anime tycoon world including:
    - Central hub generation (200x200 studs) with anime-style architecture
    - 20 plot grid generation with proper CFrame positioning
    - Performance-optimized part combining and batching
    - Memory-efficient world regeneration capabilities
    
    Best Practices:
    - Streaming and LOD systems for large worlds
    - Memory category tagging for performance monitoring
    - Efficient part combining and batching
    - CFrame positioning for optimal performance
]]

local WorldGenerator = {}
WorldGenerator.__index = WorldGenerator

-- Services
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")

-- Constants
local Constants = require(script.Parent.Parent.Utils.Constants)

-- Memory optimization
debug.setmemorycategory("WorldGeneration")

-- Private variables
local worldContainer = nil
local hubContainer = nil
local plotContainers = {}
local isGenerating = false
local generationQueue = {}
local performanceMetrics = {
    totalParts = 0,
    generationTime = 0,
    memoryUsage = 0,
    lastOptimization = 0
}

--[[
    Initialize the WorldGenerator
    @param parent - Parent container for the world
    @return WorldGenerator instance
]]
function WorldGenerator.new(parent)
    local self = setmetatable({}, WorldGenerator)
    
    -- Set memory category for this instance
    debug.setmemorycategory("WorldGeneratorInstance")
    
    self.parent = parent or workspace
    self.worldContainer = Instance.new("Folder")
    self.worldContainer.Name = "AnimeTycoonWorld"
    self.worldContainer.Parent = self.parent
    
    -- Create sub-containers
    self.hubContainer = Instance.new("Folder")
    self.hubContainer.Name = "Hub"
    self.hubContainer.Parent = self.worldContainer
    
    self.plotContainer = Instance.new("Folder")
    self.plotContainer.Name = "Plots"
    self.plotContainer.Parent = self.worldContainer
    
    self.decorationContainer = Instance.new("Folder")
    self.decorationContainer.Name = "Decorations"
    self.decorationContainer.Parent = self.worldContainer
    
    -- Initialize performance monitoring
    self:InitializePerformanceMonitoring()
    
    return self
end

--[[
    Initialize performance monitoring systems
]]
function WorldGenerator:InitializePerformanceMonitoring()
    debug.setmemorycategory("PerformanceMonitoring")
    
    -- Create performance monitoring folder
    self.performanceFolder = Instance.new("Folder")
    self.performanceFolder.Name = "PerformanceMetrics"
    self.performanceFolder.Parent = self.worldContainer
    
    -- Performance display
    self.performanceDisplay = Instance.new("ScreenGui")
    self.performanceDisplay.Name = "PerformanceDisplay"
    self.performanceDisplay.Parent = game:GetService("StarterGui")
    
    -- Performance label
    self.performanceLabel = Instance.new("TextLabel")
    self.performanceLabel.Name = "PerformanceLabel"
    self.performanceLabel.Size = UDim2.new(0, 200, 0, 50)
    self.performanceLabel.Position = UDim2.new(0, 10, 0, 10)
    self.performanceLabel.BackgroundTransparency = 0.5
    self.performanceLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    self.performanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.performanceLabel.Text = "Performance: Loading..."
    self.performanceLabel.Parent = self.performanceDisplay
    
    -- Start performance update loop
    self:StartPerformanceUpdate()
end

--[[
    Start performance update loop
]]
function WorldGenerator:StartPerformanceUpdate()
    debug.setmemorycategory("PerformanceUpdateLoop")
    
    local lastUpdate = tick()
    local updateInterval = Constants.WORLD_GENERATION.PERFORMANCE.UPDATE_INTERVAL
    
    RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        if currentTime - lastUpdate >= updateInterval then
            self:UpdatePerformanceDisplay()
            lastUpdate = currentTime
        end
    end)
end

--[[
    Update performance display
]]
function WorldGenerator:UpdatePerformanceDisplay()
    debug.setmemorycategory("PerformanceDisplayUpdate")
    
    local memoryUsage = math.floor(game:GetService("Stats").PhysicalMemory / (1024 * 1024)) -- MB
    local fps = math.floor(1 / RunService.Heartbeat:Wait())
    
    self.performanceLabel.Text = string.format(
        "Parts: %d | Memory: %d MB | FPS: %d",
        performanceMetrics.totalParts,
        memoryUsage,
        fps
    )
    
    -- Color coding based on performance
    if fps < 30 then
        self.performanceLabel.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Red
    elseif fps < 50 then
        self.performanceLabel.BackgroundColor3 = Color3.fromRGB(255, 165, 0) -- Orange
    else
        self.performanceLabel.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Green
    end
end

--[[
    Generate the complete anime tycoon world
    @param options - Generation options
    @return success, error message
]]
function WorldGenerator:GenerateWorld(options)
    debug.setmemorycategory("WorldGeneration")
    
    if isGenerating then
        return false, "World generation already in progress"
    end
    
    local startTime = tick()
    isGenerating = true
    
    -- Clear existing world
    self:ClearWorld()
    
    -- Generate world components
    local success, error = pcall(function()
        self:GenerateHub()
        self:GeneratePlotGrid()
        self:ApplyLighting()
        self:OptimizeWorld()
    end)
    
    isGenerating = false
    performanceMetrics.generationTime = tick() - startTime
    
    if not success then
        warn("World generation failed:", error)
        return false, error
    end
    
    print("World generation completed in", performanceMetrics.generationTime, "seconds")
    return true
end

--[[
    Generate the central hub area
]]
function WorldGenerator:GenerateHub()
    debug.setmemorycategory("HubGeneration")
    
    local hubConfig = Constants.WORLD_GENERATION.HUB
    local hubSize = hubConfig.SIZE
    local centerPos = hubConfig.CENTER
    local spawnHeight = hubConfig.SPAWN_HEIGHT
    local buildingHeight = hubConfig.BUILDING_HEIGHT
    
    -- Create hub base platform
    local hubBase = Instance.new("Part")
    hubBase.Name = "HubBase"
    hubBase.Size = Vector3.new(hubSize, 10, hubSize)
    hubBase.Position = centerPos
    hubBase.Anchored = true
    hubBase.Material = Constants.WORLD_GENERATION.MATERIALS.PRIMARY
    hubBase.BrickColor = BrickColor.new("Really black")
    hubBase.Parent = self.hubContainer
    
    -- Create hub building
    local hubBuilding = Instance.new("Part")
    hubBuilding.Name = "HubBuilding"
    hubBuilding.Size = Vector3.new(hubSize * 0.8, buildingHeight, hubSize * 0.8)
    hubBuilding.Position = centerPos + Vector3.new(0, buildingHeight/2 + 5, 0)
    hubBuilding.Anchored = true
    hubBuilding.Material = Constants.WORLD_GENERATION.MATERIALS.SECONDARY
    hubBuilding.BrickColor = BrickColor.new("Deep blue")
    hubBuilding.Parent = self.hubContainer
    
    -- Create spawn point
    local spawnPoint = Instance.new("SpawnLocation")
    spawnPoint.Name = "PlayerSpawn"
    spawnPoint.Size = Vector3.new(10, 1, 10)
    spawnPoint.Position = centerPos + Vector3.new(0, spawnHeight, 0)
    spawnPoint.Anchored = true
    spawnPoint.Material = Constants.WORLD_GENERATION.MATERIALS.ACCENT
    spawnPoint.BrickColor = BrickColor.new("Bright green")
    spawnPoint.Parent = self.hubContainer
    
    -- Create hub paths
    self:CreateHubPaths(centerPos, hubSize)
    
    -- Create anime-themed hub decorations
    self:CreateHubDecorations(centerPos, hubSize)
    
    performanceMetrics.totalParts = performanceMetrics.totalParts + 4 -- Base, building, spawn, paths
end

--[[
    Create hub paths connecting to plots
]]
function WorldGenerator:CreateHubPaths(centerPos, hubSize)
    debug.setmemorycategory("HubPathGeneration")
    
    local pathWidth = Constants.WORLD_GENERATION.PATH_WIDTH
    local pathHeight = 2
    
    -- Create paths to each plot row
    for row = 1, Constants.WORLD_GENERATION.PLOT_GRID.PLOTS_PER_ROW do
        local path = Instance.new("Part")
        path.Name = "HubPath_" .. row
        path.Size = Vector3.new(pathWidth, pathHeight, hubSize * 0.6)
        path.Position = centerPos + Vector3.new(0, pathHeight/2, 0)
        path.Anchored = true
        path.Material = Constants.WORLD_GENERATION.MATERIALS.PRIMARY
        path.BrickColor = BrickColor.new("Medium stone grey")
        path.Parent = self.hubContainer
        
        performanceMetrics.totalParts = performanceMetrics.totalParts + 1
    end
end

--[[
    Create anime-themed hub decorations
]]
function WorldGenerator:CreateHubDecorations(centerPos, hubSize)
    debug.setmemorycategory("HubDecorationGeneration")
    
    local decorationCount = 0
    
    -- Create anime banners around the hub
    for i = 1, 8 do
        local angle = (i - 1) * (math.pi / 4)
        local radius = hubSize * 0.6
        
        local banner = Instance.new("Part")
        banner.Name = "AnimeBanner_" .. i
        banner.Size = Vector3.new(2, 8, 0.1)
        banner.Position = centerPos + Vector3.new(
            math.cos(angle) * radius,
            4,
            math.sin(angle) * radius
        )
        banner.CFrame = CFrame.new(banner.Position) * CFrame.Angles(0, angle, 0)
        banner.Anchored = true
        banner.Material = Constants.WORLD_GENERATION.MATERIALS.ACCENT
        banner.BrickColor = BrickColor.new("Bright blue")
        banner.Parent = self.hubContainer
        
        decorationCount = decorationCount + 1
    end
    
    performanceMetrics.totalParts = performanceMetrics.totalParts + decorationCount
end

--[[
    Generate the 20-plot grid system
]]
function WorldGenerator:GeneratePlotGrid()
    debug.setmemorycategory("PlotGridGeneration")
    
    local plotConfig = Constants.WORLD_GENERATION.PLOT_GRID
    local plotSize = plotConfig.PLOT_SIZE
    local plotSpacing = plotConfig.PLOT_SPACING
    
    -- Create plot containers
    for plotId = 1, plotConfig.TOTAL_PLOTS do
        local plotPosition = Constants.GetPlotPosition(plotId)
        local gridPos = Constants.GetPlotGridPosition(plotId)
        
        if plotPosition then
            self:CreatePlot(plotId, plotPosition, plotSize, gridPos)
        end
    end
    
    print("Generated", plotConfig.TOTAL_PLOTS, "plots")
end

--[[
    Create an individual plot
    @param plotId - Plot identifier (1-20)
    @param position - Vector3 position for the plot
    @param size - Vector3 size of the plot
    @param gridPos - Table with row and column
]]
function WorldGenerator:CreatePlot(plotId, position, size, gridPos)
    debug.setmemorycategory("PlotGeneration")
    
    -- Create plot container
    local plotContainer = Instance.new("Folder")
    plotContainer.Name = "Plot_" .. plotId
    plotContainer.Parent = self.plotContainer
    
    -- Create plot base
    local plotBase = Instance.new("Part")
    plotBase.Name = "PlotBase"
    plotBase.Size = size
    plotBase.Position = position
    plotBase.Anchored = true
    plotBase.Material = Constants.WORLD_GENERATION.MATERIALS.PRIMARY
    plotBase.BrickColor = BrickColor.new("Brown")
    plotBase.Parent = plotContainer
    
    -- Create plot border
    local borderHeight = 2
    local borderThickness = 1
    
    -- Top border
    local topBorder = Instance.new("Part")
    topBorder.Name = "TopBorder"
    topBorder.Size = Vector3.new(size.X + borderThickness * 2, borderHeight, borderThickness)
    topBorder.Position = position + Vector3.new(0, size.Y/2 + borderHeight/2, size.Z/2 + borderThickness/2)
    topBorder.Anchored = true
    topBorder.Material = Constants.WORLD_GENERATION.MATERIALS.ACCENT
    topBorder.BrickColor = BrickColor.new("Bright yellow")
    topBorder.Parent = plotContainer
    
    -- Bottom border
    local bottomBorder = Instance.new("Part")
    bottomBorder.Name = "BottomBorder"
    bottomBorder.Size = Vector3.new(size.X + borderThickness * 2, borderHeight, borderThickness)
    bottomBorder.Position = position + Vector3.new(0, size.Y/2 + borderHeight/2, -size.Z/2 - borderThickness/2)
    bottomBorder.Anchored = true
    bottomBorder.Material = Constants.WORLD_GENERATION.MATERIALS.ACCENT
    bottomBorder.BrickColor = BrickColor.new("Bright yellow")
    bottomBorder.Parent = plotContainer
    
    -- Left border
    local leftBorder = Instance.new("Part")
    leftBorder.Name = "LeftBorder"
    leftBorder.Size = Vector3.new(borderThickness, borderHeight, size.Z + borderThickness * 2)
    leftBorder.Position = position + Vector3.new(-size.X/2 - borderThickness/2, size.Y/2 + borderHeight/2, 0)
    leftBorder.Anchored = true
    leftBorder.Material = Constants.WORLD_GENERATION.MATERIALS.ACCENT
    leftBorder.BrickColor = BrickColor.new("Bright yellow")
    leftBorder.Parent = plotContainer
    
    -- Right border
    local rightBorder = Instance.new("Part")
    rightBorder.Name = "RightBorder"
    rightBorder.Size = Vector3.new(borderThickness, borderHeight, size.Z + borderThickness * 2)
    rightBorder.Position = position + Vector3.new(size.X/2 + borderThickness/2, size.Y/2 + borderHeight/2, 0)
    rightBorder.Anchored = true
    rightBorder.Material = Constants.WORLD_GENERATION.MATERIALS.ACCENT
    rightBorder.BrickColor = BrickColor.new("Bright yellow")
    rightBorder.Parent = plotContainer
    
    -- Create plot label
    local plotLabel = Instance.new("Part")
    plotLabel.Name = "PlotLabel"
    plotLabel.Size = Vector3.new(8, 2, 1)
    plotLabel.Position = position + Vector3.new(0, size.Y/2 + 3, 0)
    plotLabel.Anchored = true
    plotLabel.Material = Constants.WORLD_GENERATION.MATERIALS.ACCENT
    plotLabel.BrickColor = BrickColor.new("Bright blue")
    plotLabel.Parent = plotContainer
    
    -- Create plot info
    local plotInfo = Instance.new("StringValue")
    plotInfo.Name = "PlotInfo"
    plotInfo.Value = string.format("Plot %d (Row %d, Col %d)", plotId, gridPos.row, gridPos.column)
    plotInfo.Parent = plotContainer
    
    -- Create plot status
    local plotStatus = Instance.new("StringValue")
    plotStatus.Name = "PlotStatus"
    plotStatus.Value = "Available"
    plotStatus.Parent = plotContainer
    
    -- Create plot theme
    local plotTheme = Instance.new("StringValue")
    plotTheme.Name = "PlotTheme"
    plotTheme.Value = "None"
    plotTheme.Parent = plotContainer
    
    -- Store plot container reference
    plotContainers[plotId] = plotContainer
    
    -- Update part count
    performanceMetrics.totalParts = performanceMetrics.totalParts + 8 -- Base + 4 borders + label + 3 StringValues
    
    -- Apply plot-specific optimizations
    self:OptimizePlot(plotContainer, plotId)
end

--[[
    Optimize individual plot for performance
    @param plotContainer - Plot container folder
    @param plotId - Plot identifier
]]
function WorldGenerator:OptimizePlot(plotContainer, plotId)
    debug.setmemorycategory("PlotOptimization")
    
    -- Set streaming distance for plot parts
    for _, part in pairs(plotContainer:GetChildren()) do
        if part:IsA("BasePart") then
            part.StreamingEnabled = true
            part.StreamingDistance = Constants.WORLD_GENERATION.PERFORMANCE.STREAMING_DISTANCE
        end
    end
    
    -- Create plot-specific LOD system
    local plotLOD = Instance.new("Folder")
    plotLOD.Name = "LODSystem"
    plotLOD.Parent = plotContainer
    
    -- High detail (close range)
    local highDetail = Instance.new("Folder")
    highDetail.Name = "HighDetail"
    highDetail.Parent = plotLOD
    
    -- Medium detail (medium range)
    local mediumDetail = Instance.new("Folder")
    mediumDetail.Name = "MediumDetail"
    mediumDetail.Parent = plotLOD
    
    -- Low detail (far range)
    local lowDetail = Instance.new("Folder")
    lowDetail.Name = "LowDetail"
    lowDetail.Parent = plotLOD
end

--[[
    Apply world lighting and atmosphere
]]
function WorldGenerator:ApplyLighting()
    debug.setmemorycategory("LightingApplication")
    
    local lightingConfig = Constants.WORLD_GENERATION.LIGHTING
    
    -- Set ambient lighting
    Lighting.Ambient = lightingConfig.AMBIENT_COLOR
    Lighting.Brightness = lightingConfig.BRIGHTNESS
    Lighting.ShadowQuality = lightingConfig.SHADOW_QUALITY
    
    -- Create day/night cycle
    if lightingConfig.DAY_NIGHT_CYCLE_ENABLED then
        self:CreateDayNightCycle()
    end
    
    -- Create world atmosphere
    Lighting.Atmosphere = Instance.new("Atmosphere")
    Lighting.Atmosphere.Density = 0.3
    Lighting.Atmosphere.Offset = 0.25
    Lighting.Atmosphere.Color = Color3.fromRGB(199, 199, 199)
    Lighting.Atmosphere.Decay = Color3.fromRGB(106, 112, 125)
    Lighting.Atmosphere.Glare = 0
    Lighting.Atmosphere.Haze = 0
end

--[[
    Create day/night cycle system
]]
function WorldGenerator:CreateDayNightCycle()
    debug.setmemorycategory("DayNightCycle")
    
    local cycleDuration = Constants.WORLD_GENERATION.LIGHTING.DAY_NIGHT_CYCLE_DURATION
    local startTime = tick()
    
    RunService.Heartbeat:Connect(function()
        local elapsed = tick() - startTime
        local cycleProgress = (elapsed % cycleDuration) / cycleDuration
        
        -- Calculate sun position
        local sunAngle = cycleProgress * math.pi * 2
        local sunHeight = math.sin(sunAngle)
        local sunBrightness = math.max(0, sunHeight)
        
        -- Update lighting
        Lighting.Brightness = 0.5 + sunBrightness * 0.5
        Lighting.ClockTime = cycleProgress * 24
        
        -- Update sky
        if Lighting:FindFirstChild("Sky") then
            local sky = Lighting.Sky
            sky.SkyboxBk = "rbxassetid://6444884337"
            sky.SkyboxDn = "rbxassetid://6444884356"
            sky.SkyboxFt = "rbxassetid://6444884337"
            sky.SkyboxLf = "rbxassetid://6444884337"
            sky.SkyboxRt = "rbxassetid://6444884337"
            sky.SkyboxUp = "rbxassetid://6444884356"
        end
    end)
end

--[[
    Optimize the entire world for performance
]]
function WorldGenerator:OptimizeWorld()
    debug.setmemorycategory("WorldOptimization")
    
    local optimizationStart = tick()
    
    -- Combine parts where possible
    self:CombineSimilarParts()
    
    -- Apply streaming optimizations
    self:ApplyStreamingOptimizations()
    
    -- Apply LOD optimizations
    self:ApplyLODOptimizations()
    
    -- Memory cleanup (Roblox handles garbage collection automatically)
    task.wait() -- Allow frame to complete
    
    local optimizationTime = tick() - optimizationStart
    performanceMetrics.lastOptimization = optimizationTime
    
    print("World optimization completed in", optimizationTime, "seconds")
end

--[[
    Combine similar parts for better performance
]]
function WorldGenerator:CombineSimilarParts()
    debug.setmemorycategory("PartCombining")
    
    local batchSize = Constants.WORLD_GENERATION.PERFORMANCE.BATCH_SIZE
    local processedParts = 0
    
    -- Process plots in batches
    for plotId, plotContainer in pairs(plotContainers) do
        if processedParts % batchSize == 0 then
            RunService.Heartbeat:Wait() -- Yield to prevent lag
        end
        
        -- Combine plot borders
        local borders = {}
        for _, child in pairs(plotContainer:GetChildren()) do
            if child.Name:find("Border") and child:IsA("BasePart") then
                table.insert(borders, child)
            end
        end
        
        if #borders >= 2 then
            self:CombineBorders(borders, plotContainer)
        end
        
        processedParts = processedParts + 1
    end
end

--[[
    Combine plot borders for better performance
    @param borders - Table of border parts
    @param plotContainer - Plot container
]]
function WorldGenerator:CombineBorders(borders, plotContainer)
    debug.setmemorycategory("BorderCombining")
    
    -- Create combined border
    local combinedBorder = Instance.new("Part")
    combinedBorder.Name = "CombinedBorder"
    combinedBorder.Size = Vector3.new(150, 2, 150)
    combinedBorder.Position = plotContainer.PlotBase.Position + Vector3.new(0, 26, 0)
    combinedBorder.Anchored = true
    combinedBorder.Material = Constants.WORLD_GENERATION.MATERIALS.ACCENT
    combinedBorder.BrickColor = BrickColor.new("Bright yellow")
    combinedBorder.Parent = plotContainer
    
    -- Remove individual borders
    for _, border in pairs(borders) do
        border:Destroy()
    end
    
    -- Update part count
    performanceMetrics.totalParts = performanceMetrics.totalParts - #borders + 1
end

--[[
    Apply streaming optimizations
]]
function WorldGenerator:ApplyStreamingOptimizations()
    debug.setmemorycategory("StreamingOptimization")
    
    -- Set streaming for all world parts
    for _, container in pairs({self.hubContainer, self.plotContainer, self.decorationContainer}) do
        for _, child in pairs(container:GetDescendants()) do
            if child:IsA("BasePart") then
                child.StreamingEnabled = true
                child.StreamingDistance = Constants.WORLD_GENERATION.PERFORMANCE.STREAMING_DISTANCE
            end
        end
    end
end

--[[
    Apply Level of Detail optimizations
]]
function WorldGenerator:ApplyLODOptimizations()
    debug.setmemorycategory("LODOptimization")
    
    local lodDistance = Constants.WORLD_GENERATION.PERFORMANCE.LOD_DISTANCE
    
    -- Create LOD system for plots
    for plotId, plotContainer in pairs(plotContainers) do
        local plotLOD = plotContainer:FindFirstChild("LODSystem")
        if plotLOD then
            self:SetupPlotLOD(plotLOD, plotContainer, plotId)
        end
    end
end

--[[
    Setup LOD system for individual plot
    @param plotLOD - LOD system folder
    @param plotContainer - Plot container
    @param plotId - Plot identifier
]]
function WorldGenerator:SetupPlotLOD(plotLOD, plotContainer, plotId)
    debug.setmemorycategory("PlotLODSetup")
    
    local highDetail = plotLOD:FindFirstChild("HighDetail")
    local mediumDetail = plotLOD:FindFirstChild("MediumDetail")
    local lowDetail = plotLOD:FindFirstChild("LowDetail")
    
    if not (highDetail and mediumDetail and lowDetail) then
        return
    end
    
    -- Move plot parts to appropriate LOD levels
    for _, child in pairs(plotContainer:GetChildren()) do
        if child:IsA("BasePart") and child.Name ~= "PlotBase" then
            if child.Name:find("Border") then
                child.Parent = highDetail
            elseif child.Name:find("Label") then
                child.Parent = mediumDetail
            else
                child.Parent = lowDetail
            end
        end
    end
end

--[[
    Clear the entire world
]]
function WorldGenerator:ClearWorld()
    debug.setmemorycategory("WorldClearing")
    
    if self.worldContainer then
        self.worldContainer:Destroy()
        self.worldContainer = nil
    end
    
    -- Reset containers
    self.hubContainer = nil
    self.plotContainer = nil
    self.decorationContainer = nil
    plotContainers = {}
    
    -- Reset performance metrics
    performanceMetrics.totalParts = 0
    performanceMetrics.generationTime = 0
    performanceMetrics.lastOptimization = 0
    
    -- Force cleanup (Roblox handles garbage collection automatically)
    task.wait() -- Allow frame to complete
end

--[[
    Regenerate specific plot
    @param plotId - Plot identifier to regenerate
    @return success, error message
]]
function WorldGenerator:RegeneratePlot(plotId)
    debug.setmemorycategory("PlotRegeneration")
    
    if not Constants.IsValidPlotId(plotId) then
        return false, "Invalid plot ID"
    end
    
    local plotContainer = plotContainers[plotId]
    if plotContainer then
        plotContainer:Destroy()
        plotContainers[plotId] = nil
    end
    
    local plotPosition = Constants.GetPlotPosition(plotId)
    local gridPos = Constants.GetPlotGridPosition(plotId)
    
    if plotPosition then
        self:CreatePlot(plotId, plotPosition, Constants.WORLD_GENERATION.PLOT_GRID.PLOT_SIZE, gridPos)
        return true
    end
    
    return false, "Failed to get plot position"
end

--[[
    Get world statistics
    @return table of world statistics
]]
function WorldGenerator:GetWorldStats()
    debug.setmemorycategory("WorldStats")
    
    return {
        totalParts = performanceMetrics.totalParts,
        generationTime = performanceMetrics.generationTime,
        lastOptimization = performanceMetrics.lastOptimization,
        plotCount = #plotContainers,
        hubGenerated = self.hubContainer ~= nil,
        worldGenerated = self.worldContainer ~= nil
    }
end

--[[
    Check if world generation is in progress
    @return boolean
]]
function WorldGenerator:IsGenerating()
    return isGenerating
end

--[[
    Get plot container by ID
    @param plotId - Plot identifier
    @return plot container or nil
]]
function WorldGenerator:GetPlotContainer(plotId)
    return plotContainers[plotId]
end

--[[
    Get all plot containers
    @return table of plot containers
]]
function WorldGenerator:GetAllPlotContainers()
    return plotContainers
end

--[[
    Destroy the WorldGenerator instance
]]
function WorldGenerator:Destroy()
    debug.setmemorycategory("WorldGeneratorDestruction")
    
    self:ClearWorld()
    
    if self.performanceDisplay then
        self.performanceDisplay:Destroy()
        self.performanceDisplay = nil
    end
    
    -- Clear references
    self.parent = nil
    setmetatable(self, nil)
end

return WorldGenerator
