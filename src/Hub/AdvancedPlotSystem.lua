-- AdvancedPlotSystem.lua
-- Enhanced plot management with upgrades, themes, and seamless switching

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Constants = require(script.Parent.Parent.Utils.Constants)
local NetworkManager = require(script.Parent.Parent.Multiplayer.NetworkManager)

local AdvancedPlotSystem = {}
AdvancedPlotSystem.__index = AdvancedPlotSystem

-- RemoteEvents for client-server communication
local RemoteEvents = {
    PlotUpgradeRequest = "PlotUpgradeRequest",
    PlotUpgradeResponse = "PlotUpgradeResponse",
    ThemeChangeRequest = "ThemeChangeRequest",
    ThemeChangeResponse = "ThemeChangeResponse",
    PlotDecorationUpdate = "PlotDecorationUpdate",
    PlotPrestigeUpdate = "PlotPrestigeUpdate"
}

function AdvancedPlotSystem.new()
    local self = setmetatable({}, AdvancedPlotSystem)
    
    -- Core data structures
    self.plotUpgrades = {}            -- Plot ID -> Upgrade Data
    self.plotThemes = {}              -- Plot ID -> Theme Data
    self.plotDecorations = {}         -- Plot ID -> [Decoration Data]
    self.plotPrestige = {}            -- Plot ID -> Prestige Level
    self.plotSwitchHistory = {}       -- Player -> [Switch History]
    self.plotCustomization = {}       -- Plot ID -> Customization Data
    
    -- Network manager reference
    self.networkManager = nil
    
    -- Initialize remote events
    self.remoteEvents = {}
    
    return self
end

function AdvancedPlotSystem:Initialize(networkManager)
    self.networkManager = networkManager
    
    -- Set up remote events
    self:SetupRemoteEvents()
    
    -- Connect to player events
    self:ConnectPlayerEvents()
    
    -- Initialize plot system
    self:InitializePlotSystem()
    
    print("AdvancedPlotSystem: Initialized successfully!")
end

function AdvancedPlotSystem:SetupRemoteEvents()
    -- Create remote events in ReplicatedStorage
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    
    for eventName, _ in pairs(RemoteEvents) do
        local remoteEvent = Instance.new("RemoteEvent")
        remoteEvent.Name = eventName
        remoteEvent.Parent = ReplicatedStorage
        self.remoteEvents[eventName] = remoteEvent
    end
    
    -- Set up event handlers
    self.remoteEvents.PlotUpgradeRequest.OnServerEvent:Connect(function(player, plotId, upgradeType)
        self:HandlePlotUpgradeRequest(player, plotId, upgradeType)
    end)
    
    self.remoteEvents.ThemeChangeRequest.OnServerEvent:Connect(function(player, plotId, newTheme)
        self:HandleThemeChangeRequest(player, plotId, newTheme)
    end)
    
    print("AdvancedPlotSystem: Remote events configured!")
end

function AdvancedPlotSystem:ConnectPlayerEvents()
    -- Handle player joining
    Players.PlayerAdded:Connect(function(player)
        self:HandlePlayerJoined(player)
    end)
    
    -- Handle player leaving
    Players.PlayerRemoving:Connect(function(player)
        self:HandlePlayerLeaving(player)
    end)
    
    print("AdvancedPlotSystem: Player events connected!")
end

function AdvancedPlotSystem:InitializePlotSystem()
    -- Initialize all plots with default values
    for plotId = 1, Constants.HUB.TOTAL_PLOTS do
        self.plotUpgrades[plotId] = {
            level = 1,
            maxLevel = 10,
            upgradeCost = Constants.ECONOMY.ABILITY_BASE_COST,
            lastUpgraded = tick()
        }
        
        self.plotThemes[plotId] = {
            current = Constants.PLOT_THEMES[plotId] or "Default",
            available = {Constants.PLOT_THEMES[plotId] or "Default"},
            lastChanged = tick()
        }
        
        self.plotDecorations[plotId] = {}
        self.plotPrestige[plotId] = {
            level = 1,
            experience = 0,
            experienceRequired = 1000,
            lastUpdated = tick()
        }
        
        self.plotCustomization[plotId] = {
            buildings = {},
            layout = "default",
            colorScheme = "default",
            lastModified = tick()
        }
    end
    
    print("AdvancedPlotSystem: Plot system initialized for " .. Constants.HUB.TOTAL_PLOTS .. " plots!")
end

-- Plot Enhancement System

function AdvancedPlotSystem:UpgradePlot(plotId, upgradeType)
    if not plotId or not upgradeType then
        warn("UpgradePlot: Invalid parameters")
        return false
    end
    
    local upgradeData = self.plotUpgrades[plotId]
    if not upgradeData then
        warn("UpgradePlot: Plot " .. plotId .. " not found")
        return false
    end
    
    -- Check if upgrade is possible
    if upgradeData.level >= upgradeData.maxLevel then
        warn("UpgradePlot: Plot " .. plotId .. " is already at maximum level")
        return false
    end
    
    -- Calculate upgrade cost
    local upgradeCost = self:CalculateUpgradeCost(plotId, upgradeType)
    
    -- Perform upgrade
    upgradeData.level = upgradeData.level + 1
    upgradeData.lastUpgraded = tick()
    upgradeData.upgradeCost = self:CalculateNextUpgradeCost(plotId)
    
    -- Update plot prestige
    self:UpdatePlotPrestige(plotId, upgradeType)
    
    print("AdvancedPlotSystem: Upgraded plot " .. plotId .. " to level " .. upgradeData.level)
    return true, upgradeCost
end

function AdvancedPlotSystem:GetPlotUpgrade(plotId)
    if not plotId then return nil end
    return self.plotUpgrades[plotId]
end

function AdvancedPlotSystem:CalculateUpgradeCost(plotId, upgradeType)
    local upgradeData = self.plotUpgrades[plotId]
    if not upgradeData then return 0 end
    
    local baseCost = upgradeData.upgradeCost
    local levelMultiplier = 1 + (upgradeData.level * 0.1)
    local typeMultiplier = self:GetUpgradeTypeMultiplier(upgradeType)
    
    return math.floor(baseCost * levelMultiplier * typeMultiplier)
end

function AdvancedPlotSystem:CalculateNextUpgradeCost(plotId)
    local upgradeData = self.plotUpgrades[plotId]
    if not upgradeData then return 0 end
    
    local baseCost = Constants.ECONOMY.ABILITY_BASE_COST
    local levelMultiplier = 1 + (upgradeData.level * 0.1)
    
    return math.floor(baseCost * levelMultiplier)
end

function AdvancedPlotSystem:GetUpgradeTypeMultiplier(upgradeType)
    local multipliers = {
        ["speed"] = 1.0,
        ["efficiency"] = 1.2,
        ["capacity"] = 1.5,
        ["quality"] = 1.3,
        ["default"] = 1.0
    }
    
    return multipliers[upgradeType] or multipliers["default"]
end

-- Plot Theme System

function AdvancedPlotSystem:ChangePlotTheme(plotId, newTheme)
    if not plotId or not newTheme then
        warn("ChangePlotTheme: Invalid parameters")
        return false
    end
    
    local themeData = self.plotThemes[plotId]
    if not themeData then
        warn("ChangePlotTheme: Plot " .. plotId .. " theme data not found")
        return false
    end
    
    -- Check if theme is available
    local themeAvailable = false
    for _, availableTheme in ipairs(themeData.available) do
        if availableTheme == newTheme then
            themeAvailable = true
            break
        end
    end
    
    if not themeAvailable then
        -- Add theme to available themes (unlock system)
        table.insert(themeData.available, newTheme)
        print("AdvancedPlotSystem: Unlocked new theme '" .. newTheme .. "' for plot " .. plotId)
    end
    
    -- Change theme
    local oldTheme = themeData.current
    themeData.current = newTheme
    themeData.lastChanged = tick()
    
    -- Apply theme-specific bonuses
    self:ApplyThemeBonuses(plotId, newTheme)
    
    print("AdvancedPlotSystem: Changed plot " .. plotId .. " theme from '" .. oldTheme .. "' to '" .. newTheme .. "'")
    return true
end

function AdvancedPlotSystem:GetPlotTheme(plotId)
    if not plotId then return nil end
    return self.plotThemes[plotId]
end

function AdvancedPlotSystem:GetAvailableThemes(plotId)
    local themeData = self.plotThemes[plotId]
    if not themeData then return {} end
    return themeData.available
end

function AdvancedPlotSystem:ApplyThemeBonuses(plotId, theme)
    -- Apply theme-specific bonuses to the plot
    local bonuses = self:GetThemeBonuses(theme)
    
    -- This will be expanded to apply actual bonuses to plot performance
    print("AdvancedPlotSystem: Applied theme bonuses for '" .. theme .. "' to plot " .. plotId)
end

function AdvancedPlotSystem:GetThemeBonuses(theme)
    local themeBonuses = {
        ["Anime"] = {cashMultiplier = 1.1, experienceBonus = 1.2},
        ["Meme"] = {cashMultiplier = 1.05, experienceBonus = 1.15},
        ["Gaming"] = {cashMultiplier = 1.15, experienceBonus = 1.25},
        ["Music"] = {cashMultiplier = 1.08, experienceBonus = 1.18},
        ["Sports"] = {cashMultiplier = 1.12, experienceBonus = 1.22},
        ["Food"] = {cashMultiplier = 1.06, experienceBonus = 1.16},
        ["Travel"] = {cashMultiplier = 1.09, experienceBonus = 1.19},
        ["Technology"] = {cashMultiplier = 1.14, experienceBonus = 1.24},
        ["Nature"] = {cashMultiplier = 1.07, experienceBonus = 1.17},
        ["Space"] = {cashMultiplier = 1.13, experienceBonus = 1.23},
        ["Fantasy"] = {cashMultiplier = 1.11, experienceBonus = 1.21},
        ["SciFi"] = {cashMultiplier = 1.16, experienceBonus = 1.26},
        ["Horror"] = {cashMultiplier = 1.04, experienceBonus = 1.14},
        ["Comedy"] = {cashMultiplier = 1.03, experienceBonus = 1.13},
        ["Action"] = {cashMultiplier = 1.10, experienceBonus = 1.20},
        ["Romance"] = {cashMultiplier = 1.02, experienceBonus = 1.12},
        ["Mystery"] = {cashMultiplier = 1.08, experienceBonus = 1.18},
        ["Adventure"] = {cashMultiplier = 1.09, experienceBonus = 1.19},
        ["Strategy"] = {cashMultiplier = 1.12, experienceBonus = 1.22},
        ["Racing"] = {cashMultiplier = 1.11, experienceBonus = 1.21}
    }
    
    return themeBonuses[theme] or {cashMultiplier = 1.0, experienceBonus = 1.0}
end

-- Plot Decoration System

function AdvancedPlotSystem:AddPlotDecoration(plotId, decorationId, decorationData)
    if not plotId or not decorationId or not decorationData then
        warn("AddPlotDecoration: Invalid parameters")
        return false
    end
    
    local decorations = self.plotDecorations[plotId] or {}
    
    -- Add decoration
    decorations[decorationId] = {
        id = decorationId,
        data = decorationData,
        addedAt = tick(),
        lastModified = tick()
    }
    
    self.plotDecorations[plotId] = decorations
    
    -- Update plot prestige
    self:UpdatePlotPrestige(plotId, "decoration")
    
    -- Sync to client
    self:BroadcastPlotDecorationUpdate(plotId, decorationId, decorationData)
    
    print("AdvancedPlotSystem: Added decoration " .. decorationId .. " to plot " .. plotId)
    return true
end

function AdvancedPlotSystem:RemovePlotDecoration(plotId, decorationId)
    if not plotId or not decorationId then
        warn("RemovePlotDecoration: Invalid parameters")
        return false
    end
    
    local decorations = self.plotDecorations[plotId] or {}
    
    if decorations[decorationId] then
        decorations[decorationId] = nil
        self.plotDecorations[plotId] = decorations
        
        -- Sync to client
        self:BroadcastPlotDecorationUpdate(plotId, decorationId, nil)
        
        print("AdvancedPlotSystem: Removed decoration " .. decorationId .. " from plot " .. plotId)
        return true
    end
    
    return false
end

function AdvancedPlotSystem:GetPlotDecorations(plotId)
    if not plotId then return {} end
    return self.plotDecorations[plotId] or {}
end

-- Plot Prestige System

function AdvancedPlotSystem:UpdatePlotPrestige(plotId, actionType)
    if not plotId or not actionType then return end
    
    local prestigeData = self.plotPrestige[plotId]
    if not prestigeData then return end
    
    -- Calculate experience gain based on action
    local experienceGain = self:CalculateExperienceGain(actionType)
    prestigeData.experience = prestigeData.experience + experienceGain
    
    -- Check for level up
    while prestigeData.experience >= prestigeData.experienceRequired do
        prestigeData.experience = prestigeData.experience - prestigeData.experienceRequired
        prestigeData.level = prestigeData.level + 1
        prestigeData.experienceRequired = self:CalculateNextLevelExperience(prestigeData.level)
        
        print("AdvancedPlotSystem: Plot " .. plotId .. " reached prestige level " .. prestigeData.level .. "!")
    end
    
    prestigeData.lastUpdated = tick()
    
    -- Sync to client
    self:BroadcastPlotPrestigeUpdate(plotId, prestigeData)
end

function AdvancedPlotSystem:CalculateExperienceGain(actionType)
    local experienceValues = {
        ["upgrade"] = 100,
        ["theme_change"] = 50,
        ["decoration"] = 25,
        ["plot_switch"] = 10,
        ["default"] = 5
    }
    
    return experienceValues[actionType] or experienceValues["default"]
end

function AdvancedPlotSystem:CalculateNextLevelExperience(level)
    return math.floor(1000 * (1.5 ^ (level - 1)))
end

function AdvancedPlotSystem:GetPlotPrestige(plotId)
    if not plotId then return nil end
    return self.plotPrestige[plotId]
end

function AdvancedPlotSystem:CalculatePlotPrestige(plotId)
    local prestigeData = self.plotPrestige[plotId]
    if not prestigeData then return 0 end
    
    -- Calculate prestige score
    local baseScore = prestigeData.level * 1000
    local experienceBonus = prestigeData.experience
    local levelBonus = prestigeData.level * 100
    
    return baseScore + experienceBonus + levelBonus
end

-- Plot Switching System

function AdvancedPlotSystem:SwitchPlayerToPlot(player, plotId)
    if not player or not plotId then
        warn("SwitchPlayerToPlot: Invalid parameters")
        return false
    end
    
    -- Validate plot switch
    if not self:ValidatePlotSwitch(player, plotId) then
        return false
    end
    
    -- Handle plot switch cooldown
    if not self:HandlePlotSwitchCooldown(player) then
        return false
    end
    
    -- Preserve current plot data
    local currentPlotId = self:GetPlayerCurrentPlot(player)
    if currentPlotId then
        self:PreservePlotData(player, currentPlotId)
    end
    
    -- Perform the switch
    self:SetPlayerCurrentPlot(player, plotId)
    
    -- Update plot switch history
    self:UpdatePlotSwitchHistory(player, plotId)
    
    -- Update plot prestige
    self:UpdatePlotPrestige(plotId, "plot_switch")
    
    print("AdvancedPlotSystem: Player " .. player.Name .. " switched to plot " .. plotId)
    return true
end

function AdvancedPlotSystem:ValidatePlotSwitch(player, plotId)
    -- Check if plot exists
    if plotId < 1 or plotId > Constants.HUB.TOTAL_PLOTS then
        warn("ValidatePlotSwitch: Invalid plot ID " .. plotId)
        return false
    end
    
    -- Check if player owns the plot (this will be integrated with MultiTycoonManager)
    -- For now, assume all plots are accessible
    
    return true
end

function AdvancedPlotSystem:HandlePlotSwitchCooldown(player)
    -- This will be integrated with MultiTycoonManager's cooldown system
    -- For now, return true (no cooldown)
    return true
end

function AdvancedPlotSystem:PreservePlotData(player, plotId)
    if not player or not plotId then return end
    
    -- This function will preserve all plot data during switches
    -- including cash, abilities, buildings, decorations, etc.
    
    print("AdvancedPlotSystem: Preserved data for plot " .. plotId .. " (player: " .. player.Name .. ")")
end

function AdvancedPlotSystem:GetPlayerCurrentPlot(player)
    -- This will be integrated with MultiTycoonManager
    -- For now, return nil
    return nil
end

function AdvancedPlotSystem:SetPlayerCurrentPlot(player, plotId)
    -- This will be integrated with MultiTycoonManager
    -- For now, just log the action
    print("AdvancedPlotSystem: Set " .. player.Name .. " current plot to " .. plotId)
end

function AdvancedPlotSystem:UpdatePlotSwitchHistory(player, plotId)
    if not player or not plotId then return end
    
    local userId = player.UserId
    if not self.plotSwitchHistory[userId] then
        self.plotSwitchHistory[userId] = {}
    end
    
    table.insert(self.plotSwitchHistory[userId], {
        plotId = plotId,
        timestamp = tick(),
        action = "switch_to"
    })
    
    -- Keep only last 10 switches
    if #self.plotSwitchHistory[userId] > 10 then
        table.remove(self.plotSwitchHistory[userId], 1)
    end
end

-- Data Synchronization

function AdvancedPlotSystem:BroadcastPlotDecorationUpdate(plotId, decorationId, decorationData)
    local data = {
        plotId = plotId,
        decorationId = decorationId,
        decorationData = decorationData,
        timestamp = tick()
    }
    
    -- Send to all clients
    self.remoteEvents.PlotDecorationUpdate:FireAllClients(data)
    
    print("AdvancedPlotSystem: Broadcasted decoration update for plot " .. plotId)
end

function AdvancedPlotSystem:BroadcastPlotPrestigeUpdate(plotId, prestigeData)
    local data = {
        plotId = plotId,
        prestigeData = prestigeData,
        timestamp = tick()
    }
    
    -- Send to all clients
    self.remoteEvents.PlotPrestigeUpdate:FireAllClients(data)
    
    print("AdvancedPlotSystem: Broadcasted prestige update for plot " .. plotId)
end

-- Event Handlers

function AdvancedPlotSystem:HandlePlayerJoined(player)
    -- Initialize player data
    self.plotSwitchHistory[player.UserId] = {}
    
    print("AdvancedPlotSystem: Player " .. player.Name .. " joined, initialized plot data")
end

function AdvancedPlotSystem:HandlePlayerLeaving(player)
    local userId = player.UserId
    
    -- Clean up player data
    self.plotSwitchHistory[userId] = nil
    
    print("AdvancedPlotSystem: Player " .. player.Name .. " left, cleaned up plot data")
end

function AdvancedPlotSystem:HandlePlotUpgradeRequest(player, plotId, upgradeType)
    print("AdvancedPlotSystem: Received upgrade request from " .. player.Name .. " for plot " .. plotId .. " (" .. upgradeType .. ")")
    
    local success, cost = self:UpgradePlot(plotId, upgradeType)
    
    -- Send response to client
    self.remoteEvents.PlotUpgradeResponse:FireClient(player, {
        success = success,
        plotId = plotId,
        upgradeType = upgradeType,
        cost = cost,
        newLevel = success and self.plotUpgrades[plotId].level or nil
    })
end

function AdvancedPlotSystem:HandleThemeChangeRequest(player, plotId, newTheme)
    print("AdvancedPlotSystem: Received theme change request from " .. player.Name .. " for plot " .. plotId .. " to '" .. newTheme .. "'")
    
    local success = self:ChangePlotTheme(plotId, newTheme)
    
    -- Send response to client
    self.remoteEvents.ThemeChangeResponse:FireClient(player, {
        success = success,
        plotId = plotId,
        newTheme = newTheme,
        availableThemes = success and self:GetAvailableThemes(plotId) or nil
    })
end

-- Utility Functions

function AdvancedPlotSystem:GetAllPlotData()
    local allData = {}
    
    for plotId = 1, Constants.HUB.TOTAL_PLOTS do
        allData[plotId] = {
            upgrades = self.plotUpgrades[plotId],
            theme = self.plotThemes[plotId],
            decorations = self.plotDecorations[plotId],
            prestige = self.plotPrestige[plotId],
            customization = self.plotCustomization[plotId]
        }
    end
    
    return allData
end

function AdvancedPlotSystem:GetSystemStats()
    local totalUpgrades = 0
    local totalPrestige = 0
    local totalDecorations = 0
    local averageUpgradeLevel = 0
    local averagePrestigeLevel = 0
    
    for plotId = 1, Constants.HUB.TOTAL_PLOTS do
        local upgradeData = self.plotUpgrades[plotId]
        local prestigeData = self.plotPrestige[plotId]
        local decorations = self.plotDecorations[plotId]
        
        if upgradeData then
            totalUpgrades = totalUpgrades + upgradeData.level
        end
        
        if prestigeData then
            totalPrestige = totalPrestige + prestigeData.level
        end
        
        totalDecorations = totalDecorations + #decorations
    end
    
    averageUpgradeLevel = Constants.HUB.TOTAL_PLOTS > 0 and (totalUpgrades / Constants.HUB.TOTAL_PLOTS) or 0
    averagePrestigeLevel = Constants.HUB.TOTAL_PLOTS > 0 and (totalPrestige / Constants.HUB.TOTAL_PLOTS) or 0
    
    return {
        totalPlots = Constants.HUB.TOTAL_PLOTS,
        totalUpgrades = totalUpgrades,
        totalPrestige = totalPrestige,
        totalDecorations = totalDecorations,
        averageUpgradeLevel = averageUpgradeLevel,
        averagePrestigeLevel = averagePrestigeLevel
    }
end

-- Cleanup

function AdvancedPlotSystem:Cleanup()
    -- Clean up remote events
    for _, remoteEvent in pairs(self.remoteEvents) do
        if remoteEvent and remoteEvent.Parent then
            remoteEvent:Destroy()
        end
    end
    
    -- Clear data
    self.plotUpgrades = {}
    self.plotThemes = {}
    self.plotDecorations = {}
    self.plotPrestige = {}
    self.plotSwitchHistory = {}
    self.plotCustomization = {}
    
    print("AdvancedPlotSystem: Cleaned up successfully!")
end

return AdvancedPlotSystem
