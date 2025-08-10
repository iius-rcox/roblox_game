-- AdvancedPlotClient.lua
-- Client-side handler for advanced plot features and customization

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Constants = require(script.Parent.Parent.Utils.Constants)

local AdvancedPlotClient = {}
AdvancedPlotClient.__index = AdvancedPlotClient

-- RemoteEvents for client-server communication
local RemoteEvents = {
    PlotUpgradeRequest = "PlotUpgradeRequest",
    PlotUpgradeResponse = "PlotUpgradeResponse",
    ThemeChangeRequest = "ThemeChangeRequest",
    ThemeChangeResponse = "ThemeChangeResponse",
    PlotDecorationUpdate = "PlotDecorationUpdate",
    PlotPrestigeUpdate = "PlotPrestigeUpdate"
}

function AdvancedPlotClient.new()
    local self = setmetatable({}, AdvancedPlotClient)
    
    -- Client state
    self.player = Players.LocalPlayer
    self.plotUpgrades = {}
    self.plotThemes = {}
    self.plotDecorations = {}
    self.plotPrestige = {}
    self.plotCustomization = {}
    
    -- Remote events
    self.remoteEvents = {}
    
    -- Callbacks
    self.onPlotUpgradeResponse = nil
    self.onThemeChangeResponse = nil
    self.onDecorationUpdate = nil
    self.onPrestigeUpdate = nil
    
    return self
end

function AdvancedPlotClient:Initialize()
    -- Set up remote events
    self:SetupRemoteEvents()
    
    -- Connect to events
    self:ConnectToEvents()
    
    -- Initialize default plot data
    self:InitializeDefaultPlotData()
    
    print("AdvancedPlotClient: Initialized successfully!")
end

function AdvancedPlotClient:SetupRemoteEvents()
    -- Wait for remote events to be created by server
    for eventName, _ in pairs(RemoteEvents) do
        local remoteEvent = ReplicatedStorage:WaitForChild(eventName, 10)
        if remoteEvent then
            self.remoteEvents[eventName] = remoteEvent
        else
            warn("AdvancedPlotClient: Failed to find remote event: " .. eventName)
        end
    end
end

function AdvancedPlotClient:ConnectToEvents()
    -- Plot upgrade response
    if self.remoteEvents.PlotUpgradeResponse then
        self.remoteEvents.PlotUpgradeResponse.OnClientEvent:Connect(function(data)
            self:HandlePlotUpgradeResponse(data)
        end)
    end
    
    -- Theme change response
    if self.remoteEvents.ThemeChangeResponse then
        self.remoteEvents.ThemeChangeResponse.OnClientEvent:Connect(function(data)
            self:HandleThemeChangeResponse(data)
        end)
    end
    
    -- Plot decoration update
    if self.remoteEvents.PlotDecorationUpdate then
        self.remoteEvents.PlotDecorationUpdate.OnClientEvent:Connect(function(data)
            self:HandlePlotDecorationUpdate(data)
        end)
    end
    
    -- Plot prestige update
    if self.remoteEvents.PlotPrestigeUpdate then
        self.remoteEvents.PlotPrestigeUpdate.OnClientEvent:Connect(function(data)
            self:HandlePlotPrestigeUpdate(data)
        end)
    end
end

function AdvancedPlotClient:InitializeDefaultPlotData()
    -- Initialize all plots with default values
    for plotId = 1, Constants.HUB.TOTAL_PLOTS do
        self.plotUpgrades[plotId] = {
            level = 1,
            maxLevel = 10,
            upgradeCost = Constants.ECONOMY.ABILITY_BASE_COST
        }
        
        self.plotThemes[plotId] = Constants.PLOT_THEMES[((plotId - 1) % #Constants.PLOT_THEMES) + 1]
        self.plotDecorations[plotId] = {}
        self.plotPrestige[plotId] = 1
        self.plotCustomization[plotId] = {
            customTheme = nil,
            customDecorations = {},
            plotName = "Plot " .. plotId
        }
    end
end

-- Event Handlers

function AdvancedPlotClient:HandlePlotUpgradeResponse(data)
    if not data then return end
    
    local plotId = data.plotId
    local upgradeType = data.upgradeType
    local success = data.success
    local newLevel = data.newLevel
    local cost = data.cost
    
    if success then
        -- Update local data
        if self.plotUpgrades[plotId] then
            self.plotUpgrades[plotId].level = newLevel
        end
        
        print("AdvancedPlotClient: Successfully upgraded plot " .. plotId .. " to level " .. newLevel)
    else
        print("AdvancedPlotClient: Failed to upgrade plot " .. plotId .. ": " .. (data.reason or "Unknown error"))
    end
    
    -- Trigger callback
    if self.onPlotUpgradeResponse then
        self.onPlotUpgradeResponse(data)
    end
end

function AdvancedPlotClient:HandleThemeChangeResponse(data)
    if not data then return end
    
    local plotId = data.plotId
    local newTheme = data.newTheme
    local success = data.success
    local cost = data.cost
    
    if success then
        -- Update local data
        self.plotThemes[plotId] = newTheme
        
        print("AdvancedPlotClient: Successfully changed plot " .. plotId .. " theme to " .. newTheme)
    else
        print("AdvancedPlotClient: Failed to change plot " .. plotId .. " theme: " .. (data.reason or "Unknown error"))
    end
    
    -- Trigger callback
    if self.onThemeChangeResponse then
        self.onThemeChangeResponse(data)
    end
end

function AdvancedPlotClient:HandlePlotDecorationUpdate(data)
    if not data then return end
    
    local plotId = data.plotId
    local decorations = data.decorations
    
    -- Update local data
    self.plotDecorations[plotId] = decorations or {}
    
    -- Trigger callback
    if self.onDecorationUpdate then
        self.onDecorationUpdate(data)
    end
    
    print("AdvancedPlotClient: Updated decorations for plot " .. plotId)
end

function AdvancedPlotClient:HandlePlotPrestigeUpdate(data)
    if not data then return end
    
    local plotId = data.plotId
    local newPrestige = data.newPrestige
    local bonus = data.bonus
    
    -- Update local data
    self.plotPrestige[plotId] = newPrestige
    
    -- Trigger callback
    if self.onPrestigeUpdate then
        self.onPrestigeUpdate(data)
    end
    
    print("AdvancedPlotClient: Plot " .. plotId .. " prestige updated to " .. newPrestige)
end

-- Public API

function AdvancedPlotClient:RequestPlotUpgrade(plotId, upgradeType)
    if not self.remoteEvents.PlotUpgradeRequest then
        warn("AdvancedPlotClient: PlotUpgradeRequest remote event not available")
        return false
    end
    
    -- Validate plot ID
    if plotId < 1 or plotId > Constants.HUB.TOTAL_PLOTS then
        warn("AdvancedPlotClient: Invalid plot ID: " .. plotId)
        return false
    end
    
    -- Check upgrade level
    local plotUpgrade = self.plotUpgrades[plotId]
    if not plotUpgrade or plotUpgrade.level >= plotUpgrade.maxLevel then
        warn("AdvancedPlotClient: Plot " .. plotId .. " is at max level")
        return false
    end
    
    -- Send request to server
    self.remoteEvents.PlotUpgradeRequest:FireServer(plotId, upgradeType)
    print("AdvancedPlotClient: Sent plot upgrade request for plot " .. plotId)
    return true
end

function AdvancedPlotClient:RequestThemeChange(plotId, newTheme)
    if not self.remoteEvents.ThemeChangeRequest then
        warn("AdvancedPlotClient: ThemeChangeRequest remote event not available")
        return false
    end
    
    -- Validate plot ID
    if plotId < 1 or plotId > Constants.HUB.TOTAL_PLOTS then
        warn("AdvancedPlotClient: Invalid plot ID: " .. plotId)
        return false
    end
    
    -- Validate theme
    local validTheme = false
    for _, theme in ipairs(Constants.PLOT_THEMES) do
        if theme == newTheme then
            validTheme = true
            break
        end
    end
    
    if not validTheme then
        warn("AdvancedPlotClient: Invalid theme: " .. newTheme)
        return false
    end
    
    -- Send request to server
    self.remoteEvents.ThemeChangeRequest:FireServer(plotId, newTheme)
    print("AdvancedPlotClient: Sent theme change request for plot " .. plotId .. " to " .. newTheme)
    return true
end

function AdvancedPlotClient:GetPlotUpgrade(plotId)
    return self.plotUpgrades[plotId]
end

function AdvancedPlotClient:GetPlotTheme(plotId)
    return self.plotThemes[plotId]
end

function AdvancedPlotClient:GetPlotDecorations(plotId)
    return self.plotDecorations[plotId] or {}
end

function AdvancedPlotClient:GetPlotPrestige(plotId)
    return self.plotPrestige[plotId] or 1
end

function AdvancedPlotClient:GetPlotCustomization(plotId)
    return self.plotCustomization[plotId] or {}
end

function AdvancedPlotClient:GetAvailableThemes()
    return Constants.PLOT_THEMES
end

function AdvancedPlotClient:GetPlotStats(plotId)
    local upgrade = self:GetPlotUpgrade(plotId)
    local theme = self:GetPlotTheme(plotId)
    local prestige = self:GetPlotPrestige(plotId)
    local decorations = self:GetPlotDecorations(plotId)
    
    return {
        plotId = plotId,
        level = upgrade and upgrade.level or 1,
        maxLevel = upgrade and upgrade.maxLevel or 10,
        theme = theme,
        prestige = prestige,
        decorationCount = #decorations,
        upgradeCost = upgrade and upgrade.upgradeCost or Constants.ECONOMY.ABILITY_BASE_COST
    }
end

-- Callback Setters

function AdvancedPlotClient:SetOnPlotUpgradeResponse(callback)
    self.onPlotUpgradeResponse = callback
end

function AdvancedPlotClient:SetOnThemeChangeResponse(callback)
    self.onThemeChangeResponse = callback
end

function AdvancedPlotClient:SetOnDecorationUpdate(callback)
    self.onDecorationUpdate = callback
end

function AdvancedPlotClient:SetOnPrestigeUpdate(callback)
    self.onPrestigeUpdate = callback
end

-- Cleanup

function AdvancedPlotClient:Cleanup()
    -- Disconnect from events
    for _, remoteEvent in pairs(self.remoteEvents) do
        if remoteEvent then
            remoteEvent.OnClientEvent:Disconnect()
        end
    end
    
    -- Clear callbacks
    self.onPlotUpgradeResponse = nil
    self.onThemeChangeResponse = nil
    self.onDecorationUpdate = nil
    self.onPrestigeUpdate = nil
    
    print("AdvancedPlotClient: Cleaned up successfully!")
end

return AdvancedPlotClient
