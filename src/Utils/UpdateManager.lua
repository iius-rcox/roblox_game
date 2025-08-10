-- UpdateManager.lua
-- Unified update management system to consolidate RunService loops
-- Implements Roblox best practices for update batching and prioritization

local RunService = game:GetService("RunService")
local ConnectionManager = require(script.Parent.ConnectionManager)

-- Memory category for better tracking
debug.setmemorycategory("UpdateManager")

local UpdateManager = {}
UpdateManager.__index = UpdateManager

-- Update priorities (higher = more important)
local UPDATE_PRIORITIES = {
    CRITICAL = 1,      -- Player input, physics, core game logic
    HIGH = 2,          -- UI updates, animations, networking
    MEDIUM = 3,        -- Performance monitoring, cleanup
    LOW = 4,           -- Background tasks, analytics
    BACKGROUND = 5     -- Non-critical maintenance
}

-- Update groups
local updateGroups = {
    [UPDATE_PRIORITIES.CRITICAL] = {},
    [UPDATE_PRIORITIES.HIGH] = {},
    [UPDATE_PRIORITIES.MEDIUM] = {},
    [UPDATE_PRIORITIES.LOW] = {},
    [UPDATE_PRIORITIES.BACKGROUND] = {}
}

-- Performance tracking
local performanceMetrics = {
    totalUpdates = 0,
    updatesThisFrame = 0,
    averageUpdateTime = 0,
    lastUpdateTime = 0,
    frameCount = 0,
    updateTimes = {},
    maxUpdatesPerFrame = 100 -- Prevent frame overload
}

-- Update batching
local updateBatch = {}
local batchSize = 10
local batchDelay = 0.016 -- 60 FPS target

function UpdateManager.new()
    local self = setmetatable({}, UpdateManager)
    self.isRunning = false
    self.updateConnections = {}
    return self
end

-- Register an update function
function UpdateManager:RegisterUpdate(updateFunc, priority, groupName, interval)
    if not updateFunc or type(updateFunc) ~= "function" then
        warn("UpdateManager: Invalid update function")
        return nil
    end
    
    priority = priority or UPDATE_PRIORITIES.MEDIUM
    groupName = groupName or "default"
    interval = interval or 0 -- 0 = every frame
    
    local updateId = #updateGroups[priority] + 1
    
    local updateData = {
        id = updateId,
        func = updateFunc,
        priority = priority,
        groupName = groupName,
        interval = interval,
        lastRun = 0,
        isActive = true,
        executionCount = 0,
        totalExecutionTime = 0,
        averageExecutionTime = 0
    }
    
    table.insert(updateGroups[priority], updateData)
    
    -- Start the update loop if not already running
    if not self.isRunning then
        self:StartUpdateLoop()
    end
    
    return updateId
end

-- Unregister an update function
function UpdateManager:UnregisterUpdate(updateId, priority)
    priority = priority or UPDATE_PRIORITIES.MEDIUM
    
    if not updateGroups[priority] then
        return false
    end
    
    for i, updateData in ipairs(updateGroups[priority]) do
        if updateData.id == updateId then
            table.remove(updateGroups[priority], i)
            return true
        end
    end
    
    return false
end

-- Unregister all updates in a group
function UpdateManager:UnregisterGroup(groupName)
    local unregisteredCount = 0
    
    for priority, updates in pairs(updateGroups) do
        for i = #updates, 1, -1 do
            if updates[i].groupName == groupName then
                table.remove(updates, i)
                unregisteredCount = unregisteredCount + 1
            end
        end
    end
    
    return unregisteredCount
end

-- Start the main update loop
function UpdateManager:StartUpdateLoop()
    if self.isRunning then
        return
    end
    
    self.isRunning = true
    print("UpdateManager: Starting unified update loop")
    
    -- Main update loop using Heartbeat
    self.updateConnections.main = ConnectionManager:CreateConnection(
        RunService.Heartbeat,
        function(deltaTime)
            self:ProcessUpdates(deltaTime)
        end,
        "UpdateManager_Main",
        UPDATE_PRIORITIES.CRITICAL
    )
    
    -- Background update loop using task.spawn for non-critical tasks
    self.updateConnections.background = ConnectionManager:CreateThrottledConnection(
        RunService.Heartbeat,
        function()
            self:ProcessBackgroundUpdates()
        end,
        1, -- Every second
        "UpdateManager_Background"
    )
end

-- Stop the update loop
function UpdateManager:StopUpdateLoop()
    if not self.isRunning then
        return
    end
    
    self.isRunning = false
    
    -- Dispose connections
    for _, connectionId in pairs(self.updateConnections) do
        ConnectionManager:DisposeConnection(connectionId)
    end
    self.updateConnections = {}
    
    print("UpdateManager: Stopped update loop")
end

-- Process all updates for current frame
function UpdateManager:ProcessUpdates(deltaTime)
    local startTime = tick()
    local updatesProcessed = 0
    
    -- Process updates by priority
    for priority = UPDATE_PRIORITIES.CRITICAL, UPDATE_PRIORITIES.BACKGROUND do
        local updates = updateGroups[priority]
        if updates then
            for _, updateData in ipairs(updates) do
                if updateData.isActive and self:ShouldRunUpdate(updateData, deltaTime) then
                    local success, executionTime = self:ExecuteUpdate(updateData, deltaTime)
                    if success then
                        updatesProcessed = updatesProcessed + 1
                        updateData.lastRun = tick()
                        updateData.executionCount = updateData.executionCount + 1
                        updateData.totalExecutionTime = updateData.totalExecutionTime + executionTime
                        updateData.averageExecutionTime = updateData.totalExecutionTime / updateData.executionCount
                    end
                    
                    -- Prevent frame overload
                    if updatesProcessed >= performanceMetrics.maxUpdatesPerFrame then
                        break
                    end
                end
            end
        end
        
        if updatesProcessed >= performanceMetrics.maxUpdatesPerFrame then
            break
        end
    end
    
    -- Update performance metrics
    local endTime = tick()
    local updateTime = endTime - startTime
    
    performanceMetrics.totalUpdates = performanceMetrics.totalUpdates + updatesProcessed
    performanceMetrics.updatesThisFrame = updatesProcessed
    performanceMetrics.lastUpdateTime = updateTime
    performanceMetrics.frameCount = performanceMetrics.frameCount + 1
    
    -- Track update times for averaging
    table.insert(performanceMetrics.updateTimes, updateTime)
    if #performanceMetrics.updateTimes > 60 then -- Keep last 60 frames
        table.remove(performanceMetrics.updateTimes, 1)
    end
    
    -- Calculate average update time
    local totalTime = 0
    for _, time in ipairs(performanceMetrics.updateTimes) do
        totalTime = totalTime + time
    end
    performanceMetrics.averageUpdateTime = totalTime / #performanceMetrics.updateTimes
    
    -- Performance warning
    if updateTime > 0.016 then -- More than 16ms (60 FPS target)
        warn("UpdateManager: Frame took", math.floor(updateTime * 1000), "ms, processed", updatesProcessed, "updates")
    end
end

-- Process background updates
function UpdateManager:ProcessBackgroundUpdates()
    local startTime = tick()
    
    -- Process low priority updates
    for priority = UPDATE_PRIORITIES.LOW, UPDATE_PRIORITIES.BACKGROUND do
        local updates = updateGroups[priority]
        if updates then
            for _, updateData in ipairs(updates) do
                if updateData.isActive and self:ShouldRunUpdate(updateData, 1) then
                    self:ExecuteUpdate(updateData, 1)
                    updateData.lastRun = tick()
                end
            end
        end
    end
    
    local endTime = tick()
    if endTime - startTime > 0.1 then -- Background updates shouldn't take more than 100ms
        warn("UpdateManager: Background updates took", math.floor((endTime - startTime) * 1000), "ms")
    end
end

-- Check if an update should run
function UpdateManager:ShouldRunUpdate(updateData, deltaTime)
    if not updateData.isActive then
        return false
    end
    
    if updateData.interval <= 0 then
        return true -- Run every frame
    end
    
    local currentTime = tick()
    return currentTime - updateData.lastRun >= updateData.interval
end

-- Execute a single update
function UpdateManager:ExecuteUpdate(updateData, deltaTime)
    local startTime = tick()
    local success, result = pcall(updateData.func, deltaTime)
    local executionTime = tick() - startTime
    
    if not success then
        warn("UpdateManager: Update function error:", result)
        return false, executionTime
    end
    
    return true, executionTime
end

-- Get update statistics
function UpdateManager:GetStats()
    local groupStats = {}
    local priorityStats = {}
    
    for priority, updates in pairs(updateGroups) do
        priorityStats[priority] = {
            count = #updates,
            active = 0,
            totalExecutionTime = 0,
            averageExecutionTime = 0
        }
        
        for _, updateData in ipairs(updates) do
            if updateData.isActive then
                priorityStats[priority].active = priorityStats[priority].active + 1
                priorityStats[priority].totalExecutionTime = priorityStats[priority].totalExecutionTime + updateData.totalExecutionTime
            end
        end
        
        if priorityStats[priority].active > 0 then
            priorityStats[priority].averageExecutionTime = priorityStats[priority].totalExecutionTime / priorityStats[priority].active
        end
    end
    
    return {
        isRunning = self.isRunning,
        totalUpdates = performanceMetrics.totalUpdates,
        updatesThisFrame = performanceMetrics.updatesThisFrame,
        averageUpdateTime = performanceMetrics.averageUpdateTime,
        lastUpdateTime = performanceMetrics.lastUpdateTime,
        frameCount = performanceMetrics.frameCount,
        priorityStats = priorityStats,
        groupStats = groupStats
    }
end

-- Cleanup
function UpdateManager:Cleanup()
    self:StopUpdateLoop()
    
    -- Clear all update groups
    for priority, updates in pairs(updateGroups) do
        updateGroups[priority] = {}
    end
    
    print("UpdateManager: Cleanup completed")
end

-- Auto-cleanup when script is destroyed
game:BindToClose(function()
    UpdateManager:Cleanup()
end)

return UpdateManager
