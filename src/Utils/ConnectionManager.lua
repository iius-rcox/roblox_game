-- ConnectionManager.lua
-- Unified connection management system to prevent memory leaks
-- Implements Roblox best practices for connection lifecycle management

local RunService = game:GetService("RunService")

-- Memory category for better tracking
debug.setmemorycategory("ConnectionManager")

local ConnectionManager = {}
ConnectionManager.__index = ConnectionManager

-- Connection tracking
local activeConnections = {}
local connectionGroups = {}
local cleanupCallbacks = {}

-- Performance monitoring
local performanceMetrics = {
    totalConnections = 0,
    activeConnections = 0,
    disposedConnections = 0,
    lastCleanup = 0,
    cleanupInterval = 10 -- seconds
}

function ConnectionManager.new()
    local self = setmetatable({}, ConnectionManager)
    self.connections = {}
    self.cleanupCallbacks = {}
    return self
end

-- Create and track a connection
function ConnectionManager:CreateConnection(event, callback, groupName, priority)
    if not event or not callback then
        warn("ConnectionManager: Invalid connection parameters")
        return nil
    end
    
    local connection = event:Connect(callback)
    
    -- Track connection
    local connectionId = #activeConnections + 1
    activeConnections[connectionId] = {
        connection = connection,
        event = event,
        callback = callback,
        groupName = groupName or "default",
        priority = priority or 1,
        createdAt = time(),
        lastUsed = time()
    }
    
    -- Group connections
    if not connectionGroups[groupName or "default"] then
        connectionGroups[groupName or "default"] = {}
    end
    table.insert(connectionGroups[groupName or "default"], connectionId)
    
    -- Update metrics
    performanceMetrics.totalConnections = performanceMetrics.totalConnections + 1
    performanceMetrics.activeConnections = performanceMetrics.activeConnections + 1
    
    return connectionId
end

-- Create a throttled connection (runs at specified interval)
function ConnectionManager:CreateThrottledConnection(event, callback, interval, groupName)
    local lastRun = 0
    local wrappedCallback = function(...)
        local currentTime = time()
        if currentTime - lastRun >= interval then
            lastRun = currentTime
            callback(...)
        end
    end
    
    return self:CreateConnection(event, wrappedCallback, groupName, 2)
end

-- Create a debounced connection (waits for pause in calls)
function ConnectionManager:CreateDebouncedConnection(event, callback, delay, groupName)
    local timeoutId = nil
    local wrappedCallback = function(...)
        if timeoutId then
            timeoutId:Cancel()
        end
        
        -- Capture the arguments properly
        local args = {...}
        timeoutId = task.delay(delay, function()
            callback(unpack(args))
        end)
    end
    
    return self:CreateConnection(event, wrappedCallback, groupName, 3)
end

-- Dispose a specific connection
function ConnectionManager:DisposeConnection(connectionId)
    if not activeConnections[connectionId] then
        return false
    end
    
    local connectionData = activeConnections[connectionId]
    
    -- Disconnect
    if connectionData.connection and typeof(connectionData.connection) == "RBXScriptConnection" then
        connectionData.connection:Disconnect()
    end
    
    -- Remove from groups
    if connectionData.groupName and connectionGroups[connectionData.groupName] then
        for i, id in ipairs(connectionGroups[connectionData.groupName]) do
            if id == connectionId then
                table.remove(connectionGroups[connectionData.groupName], i)
                break
            end
        end
    end
    
    -- Remove from active connections
    activeConnections[connectionId] = nil
    
    -- Update metrics
    performanceMetrics.activeConnections = performanceMetrics.activeConnections - 1
    performanceMetrics.disposedConnections = performanceMetrics.disposedConnections + 1
    
    return true
end

-- Dispose all connections in a group
function ConnectionManager:DisposeGroup(groupName)
    if not connectionGroups[groupName] then
        return 0
    end
    
    local disposedCount = 0
    local groupConnections = connectionGroups[groupName]
    
    for i = #groupConnections, 1, -1 do
        local connectionId = groupConnections[i]
        if self:DisposeConnection(connectionId) then
            disposedCount = disposedCount + 1
        end
    end
    
    connectionGroups[groupName] = nil
    return disposedCount
end

-- Dispose all connections
function ConnectionManager:DisposeAll()
    local disposedCount = 0
    
    for connectionId, _ in pairs(activeConnections) do
        if self:DisposeConnection(connectionId) then
            disposedCount = disposedCount + 1
        end
    end
    
    -- Clear groups
    connectionGroups = {}
    
    -- Run cleanup callbacks
    for _, callback in pairs(cleanupCallbacks) do
        pcall(callback)
    end
    
    return disposedCount
end

-- Add cleanup callback
function ConnectionManager:AddCleanupCallback(callback)
    if type(callback) == "function" then
        table.insert(cleanupCallbacks, callback)
    end
end

-- Get connection statistics
function ConnectionManager:GetStats()
    local groupStats = {}
    for groupName, connections in pairs(connectionGroups) do
        groupStats[groupName] = #connections
    end
    
    return {
        totalConnections = performanceMetrics.totalConnections,
        activeConnections = performanceMetrics.activeConnections,
        disposedConnections = performanceMetrics.disposedConnections,
        groupStats = groupStats,
        lastCleanup = performanceMetrics.lastCleanup
    }
end

-- Automatic cleanup of old connections
function ConnectionManager:AutoCleanup()
    local currentTime = time()
    if currentTime - performanceMetrics.lastCleanup < performanceMetrics.cleanupInterval then
        return
    end
    
    performanceMetrics.lastCleanup = currentTime
    
    local disposedCount = 0
    local maxAge = 300 -- 5 minutes
    
    for connectionId, connectionData in pairs(activeConnections) do
        if currentTime - connectionData.lastUsed > maxAge then
            if self:DisposeConnection(connectionId) then
                disposedCount = disposedCount + 1
            end
        end
    end
    
    if disposedCount > 0 then
        print("ConnectionManager: Auto-cleaned", disposedCount, "old connections")
    end
    
    return disposedCount
end

-- Set up automatic cleanup
local autoCleanupConnection = RunService.Heartbeat:Connect(function()
    ConnectionManager:AutoCleanup()
end)

-- Cleanup when script is destroyed
game:BindToClose(function()
    ConnectionManager:DisposeAll()
    if autoCleanupConnection then
        autoCleanupConnection:Disconnect()
    end
end)

return ConnectionManager
