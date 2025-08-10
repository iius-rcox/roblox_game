-- NetworkManager.lua
-- Handles all multiplayer networking and RemoteEvents

local NetworkManager = {}
NetworkManager.__index = NetworkManager

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Create RemoteEvents folder
local remoteEvents = Instance.new("Folder")
remoteEvents.Name = "RemoteEvents"
remoteEvents.Parent = ReplicatedStorage

-- RemoteEvents for different systems
local remotes = {
    -- Player system
    PlayerJoin = Instance.new("RemoteEvent"),
    PlayerLeave = Instance.new("RemoteEvent"),
    PlayerDataUpdate = Instance.new("RemoteEvent"),
    
    -- Tycoon system
    TycoonClaim = Instance.new("RemoteEvent"),
    TycoonDataUpdate = Instance.new("RemoteEvent"),
    TycoonSwitch = Instance.new("RemoteEvent"),
    
    -- Ability system
    AbilityUpdate = Instance.new("RemoteEvent"),
    AbilityTheft = Instance.new("RemoteEvent"),
    
    -- Economy system
    CashUpdate = Instance.new("RemoteEvent"),
    PurchaseUpdate = Instance.new("RemoteEvent"),
    
    -- General
    Notification = Instance.new("RemoteEvent"),
    ErrorMessage = Instance.new("RemoteEvent")
}

-- Set up RemoteEvents
for name, remote in pairs(remotes) do
    remote.Name = name
    remote.Parent = remoteEvents
end

-- Store references
NetworkManager.Remotes = remotes

-- Network event handlers
local eventHandlers = {}

-- Register event handler
function NetworkManager:RegisterHandler(eventName, handler)
    if remotes[eventName] then
        eventHandlers[eventName] = handler
    else
        warn("NetworkManager: Invalid event name:", eventName)
    end
end

-- Fire event to client
function NetworkManager:FireClient(player, eventName, ...)
    if remotes[eventName] then
        remotes[eventName]:FireClient(player, ...)
    else
        warn("NetworkManager: Invalid event name:", eventName)
    end
end

-- Fire event to all clients
function NetworkManager:FireAllClients(eventName, ...)
    if remotes[eventName] then
        remotes[eventName]:FireAllClients(...)
    else
        warn("NetworkManager: Invalid event name:", eventName)
    end
end

-- Fire event to server
function NetworkManager:FireServer(eventName, ...)
    if remotes[eventName] then
        remotes[eventName]:FireServer(...)
    else
        warn("NetworkManager: Invalid event name:", eventName)
    end
end

-- Connect client event
function NetworkManager:ConnectClient(eventName, callback)
    if remotes[eventName] then
        return remotes[eventName].OnClientEvent:Connect(callback)
    else
        warn("NetworkManager: Invalid event name:", eventName)
        return nil
    end
end

-- Connect server event
function NetworkManager:ConnectServer(eventName, callback)
    if remotes[eventName] then
        return remotes[eventName].OnServerEvent:Connect(callback)
    else
        warn("NetworkManager: Invalid event name:", eventName)
        return nil
    end
end

-- Send notification to client
function NetworkManager:NotifyClient(player, message, notificationType)
    self:FireClient(player, "Notification", message, notificationType or "Info")
end

-- Send error to client
function NetworkManager:SendError(player, message)
    self:FireClient(player, "ErrorMessage", message)
end

-- Send notification to all clients
function NetworkManager:NotifyAllClients(message, notificationType)
    self:FireAllClients("Notification", message, notificationType or "Info")
end

-- Initialize network manager
function NetworkManager:Initialize()
    print("NetworkManager initialized with", #remotes, "RemoteEvents")
    
    -- Set up default handlers
    self:SetupDefaultHandlers()
end

-- Set up default event handlers
function NetworkManager:SetupDefaultHandlers()
    -- Player join handler
    remotes.PlayerJoin.OnServerEvent:Connect(function(player)
        if eventHandlers.PlayerJoin then
            eventHandlers.PlayerJoin(player)
        end
    end)
    
    -- Player leave handler
    Players.PlayerRemoving:Connect(function(player)
        if eventHandlers.PlayerLeave then
            eventHandlers.PlayerLeave(player)
        end
    end)
    
    -- Tycoon claim handler
    remotes.TycoonClaim.OnServerEvent:Connect(function(player, tycoonId)
        if eventHandlers.TycoonClaim then
            eventHandlers.TycoonClaim(player, tycoonId)
        end
    end)
    
    -- Ability theft handler
    remotes.AbilityTheft.OnServerEvent:Connect(function(player, targetPlayer, abilityName)
        if eventHandlers.AbilityTheft then
            eventHandlers.AbilityTheft(player, targetPlayer, abilityName)
        end
    end)
end

-- Get remote event by name
function NetworkManager:GetRemote(eventName)
    return remotes[eventName]
end

-- Check if remote exists
function NetworkManager:HasRemote(eventName)
    return remotes[eventName] ~= nil
end

-- Get all remote names
function NetworkManager:GetRemoteNames()
    local names = {}
    for name, _ in pairs(remotes) do
        table.insert(names, name)
    end
    return names
end

return NetworkManager
