-- MultiTycoonClient.lua
-- Client-side handler for multiple tycoon ownership

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Constants = require(script.Parent.Parent.Utils.Constants)

local MultiTycoonClient = {}
MultiTycoonClient.__index = MultiTycoonClient

-- RemoteEvents for client-server communication
local RemoteEvents = {
    PlayerTycoonUpdate = "PlayerTycoonUpdate",
    PlotSwitchRequest = "PlotSwitchRequest",
    PlotSwitchResponse = "PlotSwitchResponse",
    CrossTycoonBonusUpdate = "CrossTycoonBonusUpdate",
    MultiTycoonDataSync = "MultiTycoonDataSync"
}

function MultiTycoonClient.new()
    local self = setmetatable({}, MultiTycoonClient)
    
    -- Client state
    self.player = Players.LocalPlayer
    self.ownedTycoons = {}
    self.currentTycoon = nil
    self.crossTycoonBonuses = {}
    self.plotSwitchCooldown = 0
    
    -- Remote events
    self.remoteEvents = {}
    
    -- Callbacks
    self.onTycoonDataUpdate = nil
    self.onPlotSwitchResponse = nil
    self.onBonusUpdate = nil
    
    return self
end

function MultiTycoonClient:Initialize()
    -- Set up remote events
    self:SetupRemoteEvents()
    
    -- Connect to events
    self:ConnectToEvents()
    
    print("MultiTycoonClient: Initialized successfully!")
end

function MultiTycoonClient:SetupRemoteEvents()
    -- Wait for remote events to be created by server
    for eventName, _ in pairs(RemoteEvents) do
        local remoteEvent = ReplicatedStorage:WaitForChild(eventName, 10)
        if remoteEvent then
            self.remoteEvents[eventName] = remoteEvent
        else
            warn("MultiTycoonClient: Failed to find remote event: " .. eventName)
        end
    end
end

function MultiTycoonClient:ConnectToEvents()
    -- Multi-tycoon data sync
    if self.remoteEvents.MultiTycoonDataSync then
        self.remoteEvents.MultiTycoonDataSync.OnClientEvent:Connect(function(data)
            self:HandleMultiTycoonDataSync(data)
        end)
    end
    
    -- Plot switch response
    if self.remoteEvents.PlotSwitchResponse then
        self.remoteEvents.PlotSwitchResponse.OnClientEvent:Connect(function(data)
            self:HandlePlotSwitchResponse(data)
        end)
    end
    
    -- Cross-tycoon bonus update
    if self.remoteEvents.CrossTycoonBonusUpdate then
        self.remoteEvents.CrossTycoonBonusUpdate.OnClientEvent:Connect(function(bonuses)
            self:HandleCrossTycoonBonusUpdate(bonuses)
        end)
    end
    
    -- Player tycoon update (broadcast)
    if self.remoteEvents.PlayerTycoonUpdate then
        self.remoteEvents.PlayerTycoonUpdate.OnClientEvent:Connect(function(data)
            self:HandlePlayerTycoonUpdate(data)
        end)
    end
end

-- Event Handlers

function MultiTycoonClient:HandleMultiTycoonDataSync(data)
    if not data then return end
    
    -- Update client state
    self.ownedTycoons = data.ownedTycoons or {}
    self.currentTycoon = data.currentTycoon
    self.crossTycoonBonuses = data.crossTycoonBonuses or {}
    self.plotSwitchCooldown = data.plotSwitchCooldown or 0
    
    -- Trigger callback
    if self.onTycoonDataUpdate then
        self.onTycoonDataUpdate(data)
    end
    
    print("MultiTycoonClient: Received data sync, owned tycoons: " .. #self.ownedTycoons)
end

function MultiTycoonClient:HandlePlotSwitchResponse(data)
    if not data then return end
    
    if data.success then
        print("MultiTycoonClient: Successfully switched to tycoon " .. data.targetTycoonId)
        self.currentTycoon = data.targetTycoonId
    else
        print("MultiTycoonClient: Failed to switch tycoons, cooldown remaining: " .. data.cooldownRemaining)
    end
    
    -- Trigger callback
    if self.onPlotSwitchResponse then
        self.onPlotSwitchResponse(data)
    end
end

function MultiTycoonClient:HandleCrossTycoonBonusUpdate(bonuses)
    if not bonuses then return end
    
    self.crossTycoonBonuses = bonuses
    
    -- Trigger callback
    if self.onBonusUpdate then
        self.onBonusUpdate(bonuses)
    end
    
    print("MultiTycoonClient: Received bonus update, total bonus: " .. (bonuses.totalBonus or 0))
end

function MultiTycoonClient:HandlePlayerTycoonUpdate(data)
    if not data then return end
    
    -- Handle broadcast updates from other players
    if data.type == "PlotSwitch" then
        print("MultiTycoonClient: Player " .. data.playerName .. " switched from tycoon " .. 
              tostring(data.oldTycoonId) .. " to " .. data.newTycoonId)
    end
end

-- Public API

function MultiTycoonClient:RequestPlotSwitch(targetTycoonId)
    if not self.remoteEvents.PlotSwitchRequest then
        warn("MultiTycoonClient: PlotSwitchRequest remote event not available")
        return false
    end
    
    -- Check if player owns the target tycoon
    local ownsTycoon = false
    for _, tycoonId in ipairs(self.ownedTycoons) do
        if tycoonId == targetTycoonId then
            ownsTycoon = true
            break
        end
    end
    
    if not ownsTycoon then
        warn("MultiTycoonClient: Player doesn't own tycoon " .. targetTycoonId)
        return false
    end
    
    -- Check cooldown
    if self.plotSwitchCooldown > 0 then
        warn("MultiTycoonClient: Plot switch on cooldown, remaining: " .. self.plotSwitchCooldown)
        return false
    end
    
    -- Send request to server
    self.remoteEvents.PlotSwitchRequest:FireServer(targetTycoonId)
    print("MultiTycoonClient: Sent plot switch request to tycoon " .. targetTycoonId)
    return true
end

function MultiTycoonClient:GetOwnedTycoons()
    return self.ownedTycoons
end

function MultiTycoonClient:GetCurrentTycoon()
    return self.currentTycoon
end

function MultiTycoonClient:GetCrossTycoonBonuses()
    return self.crossTycoonBonuses
end

function MultiTycoonClient:GetPlotSwitchCooldown()
    return self.plotSwitchCooldown
end

function MultiTycoonClient:CanSwitchPlots()
    return self.plotSwitchCooldown <= 0
end

function MultiTycoonClient:GetTycoonCount()
    return #self.ownedTycoons
end

-- Callback Setters

function MultiTycoonClient:SetOnTycoonDataUpdate(callback)
    self.onTycoonDataUpdate = callback
end

function MultiTycoonClient:SetOnPlotSwitchResponse(callback)
    self.onPlotSwitchResponse = callback
end

function MultiTycoonClient:SetOnBonusUpdate(callback)
    self.onBonusUpdate = callback
end

-- Cleanup

function MultiTycoonClient:Cleanup()
    -- Disconnect from events
    for _, remoteEvent in pairs(self.remoteEvents) do
        if remoteEvent then
            remoteEvent.OnClientEvent:Disconnect()
        end
    end
    
    -- Clear callbacks
    self.onTycoonDataUpdate = nil
    self.onPlotSwitchResponse = nil
    self.onBonusUpdate = nil
    
    print("MultiTycoonClient: Cleaned up successfully!")
end

return MultiTycoonClient
