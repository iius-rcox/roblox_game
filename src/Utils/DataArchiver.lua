-- DataArchiver.lua
-- Data archiving and cleanup system to prevent unbounded growth
-- Implements Roblox best practices for data lifecycle management

local RunService = game:GetService("RunService")
local ConnectionManager = require(script.Parent.ConnectionManager)

-- Memory category for better tracking
debug.setmemorycategory("DataArchiver")

local DataArchiver = {}
DataArchiver.__index = DataArchiver

-- Archive configuration
local ARCHIVE_CONFIG = {
    MAX_HISTORY_SIZE = 100,           -- Maximum entries in history arrays
    MAX_SNAPSHOT_SIZE = 50,           -- Maximum memory snapshots
    MAX_PERFORMANCE_DATA = 200,       -- Maximum performance data points
    MAX_PLAYER_DATA_AGE = 3600,       -- Archive player data older than 1 hour
    MAX_TYCOON_DATA_AGE = 7200,      -- Archive tycoon data older than 2 hours
    CLEANUP_INTERVAL = 30,            -- Cleanup every 30 seconds
    ARCHIVE_RETENTION = 24 * 3600,   -- Keep archives for 24 hours
    COMPRESSION_THRESHOLD = 1000,    -- Compress data larger than 1000 entries
    MEMORY_WARNING_THRESHOLD = 50 * 1024 * 1024 -- 50MB warning
}

-- Archive storage
local archives = {}
local cleanupCallbacks = {}
local performanceMetrics = {
    totalArchived = 0,
    totalCompressed = 0,
    totalCleaned = 0,
    lastCleanup = 0,
    memoryUsage = 0
}

function DataArchiver.new()
    local self = setmetatable({}, DataArchiver)
    self.archives = {}
    self.cleanupCallbacks = {}
    return self
end

-- Archive data with automatic size management
function DataArchiver:ArchiveData(dataKey, data, maxSize, compressionEnabled)
    if not data or type(data) ~= "table" then
        warn("DataArchiver: Invalid data for archiving")
        return false
    end
    
    maxSize = maxSize or ARCHIVE_CONFIG.MAX_HISTORY_SIZE
    compressionEnabled = compressionEnabled ~= false -- Default to true
    
    -- Check if data needs archiving
    if #data <= maxSize then
        return false -- No archiving needed
    end
    
    local archiveData = {
        timestamp = time(),
        data = {},
        originalSize = #data,
        compressed = false
    }
    
    -- Archive excess data
    local excessCount = #data - maxSize
    for i = 1, excessCount do
        table.insert(archiveData.data, data[1])
        table.remove(data, 1)
    end
    
    -- Compress if enabled and data is large
    if compressionEnabled and #archiveData.data > ARCHIVE_CONFIG.COMPRESSION_THRESHOLD then
        archiveData.data = self:CompressData(archiveData.data)
        archiveData.compressed = true
        performanceMetrics.totalCompressed = performanceMetrics.totalCompressed + 1
    end
    
    -- Store archive
    if not archives[dataKey] then
        archives[dataKey] = {}
    end
    
    table.insert(archives[dataKey], archiveData)
    
    -- Clean old archives
    self:CleanOldArchives(dataKey)
    
    performanceMetrics.totalArchived = performanceMetrics.totalArchived + 1
    
    print("DataArchiver: Archived", excessCount, "entries for", dataKey, "(" .. (#archives[dataKey]) .. " archives)")
    return true
end

-- Compress data by removing redundant information
function DataArchiver:CompressData(data)
    if #data == 0 then
        return {}
    end
    
    local compressed = {}
    local sampleRate = math.max(1, math.floor(#data / ARCHIVE_CONFIG.MAX_HISTORY_SIZE))
    
    for i = 1, #data, sampleRate do
        table.insert(compressed, data[i])
    end
    
    return compressed
end

-- Restore archived data
function DataArchiver:RestoreData(dataKey, targetData, maxRestore)
    if not archives[dataKey] or #archives[dataKey] == 0 then
        return 0
    end
    
    maxRestore = maxRestore or ARCHIVE_CONFIG.MAX_HISTORY_SIZE
    
    local restoredCount = 0
    local archivesToRemove = {}
    
    for i, archive in ipairs(archives[dataKey]) do
        if restoredCount >= maxRestore then
            break
        end
        
        -- Decompress if needed
        local dataToRestore = archive.data
        if archive.compressed then
            dataToRestore = self:DecompressData(archive.data, archive.originalSize)
        end
        
        -- Restore data
        for _, item in ipairs(dataToRestore) do
            table.insert(targetData, item)
            restoredCount = restoredCount + 1
        end
        
        table.insert(archivesToRemove, i)
    end
    
    -- Remove used archives
    for i = #archivesToRemove, 1, -1 do
        table.remove(archives[dataKey], archivesToRemove[i])
    end
    
    if restoredCount > 0 then
        print("DataArchiver: Restored", restoredCount, "entries for", dataKey)
    end
    
    return restoredCount
end

-- Decompress data (simple expansion)
function DataArchiver:DecompressData(compressedData, originalSize)
    if #compressedData == 0 then
        return {}
    end
    
    local decompressed = {}
    local expansionFactor = originalSize / #compressedData
    
    for i, item in ipairs(compressedData) do
        table.insert(decompressed, item)
        
        -- Interpolate additional points if needed
        if i < #compressedData then
            local nextItem = compressedData[i + 1]
            local interpolatedCount = math.floor(expansionFactor) - 1
            
            for j = 1, interpolatedCount do
                local ratio = j / (interpolatedCount + 1)
                local interpolatedItem = self:InterpolateData(item, nextItem, ratio)
                table.insert(decompressed, interpolatedItem)
            end
        end
    end
    
    return decompressed
end

-- Simple data interpolation
function DataArchiver:InterpolateData(item1, item2, ratio)
    if type(item1) == "number" and type(item2) == "number" then
        return item1 + (item2 - item1) * ratio
    elseif type(item1) == "table" and type(item2) == "table" then
        local interpolated = {}
        for key, value1 in pairs(item1) do
            local value2 = item2[key]
            if type(value1) == "number" and type(value2) == "number" then
                interpolated[key] = value1 + (value2 - value1) * ratio
            else
                interpolated[key] = value1
            end
        end
        return interpolated
    else
        return item1
    end
end

-- Clean old archives
function DataArchiver:CleanOldArchives(dataKey)
    if not archives[dataKey] then
        return
    end
    
    local currentTime = time()
    local archivesToRemove = {}
    
    for i, archive in ipairs(archives[dataKey]) do
        if currentTime - archive.timestamp > ARCHIVE_CONFIG.ARCHIVE_RETENTION then
            table.insert(archivesToRemove, i)
        end
    end
    
    -- Remove old archives
    for i = #archivesToRemove, 1, -1 do
        table.remove(archives[dataKey], archivesToRemove[i])
    end
    
    if #archivesToRemove > 0 then
        print("DataArchiver: Cleaned", #archivesToRemove, "old archives for", dataKey)
    end
end

-- Perform comprehensive cleanup
function DataArchiver:PerformCleanup()
    local currentTime = time()
    if currentTime - performanceMetrics.lastCleanup < ARCHIVE_CONFIG.CLEANUP_INTERVAL then
        return
    end
    
    performanceMetrics.lastCleanup = currentTime
    local cleanedCount = 0
    
    -- Clean old archives for all data keys
    for dataKey, _ in pairs(archives) do
        self:CleanOldArchives(dataKey)
        cleanedCount = cleanedCount + 1
    end
    
    -- Clean empty archive entries
    for dataKey, archiveList in pairs(archives) do
        if #archiveList == 0 then
            archives[dataKey] = nil
        end
    end
    
    -- Update memory usage
    performanceMetrics.memoryUsage = self:CalculateMemoryUsage()
    
    -- Memory warning
    if performanceMetrics.memoryUsage > ARCHIVE_CONFIG.MEMORY_WARNING_THRESHOLD then
        warn("DataArchiver: High memory usage:", math.floor(performanceMetrics.memoryUsage / 1024 / 1024), "MB")
        self:EmergencyCleanup()
    end
    
    performanceMetrics.totalCleaned = performanceMetrics.totalCleaned + cleanedCount
    
    if cleanedCount > 0 then
        print("DataArchiver: Cleanup completed, cleaned", cleanedCount, "data keys")
    end
end

-- Emergency cleanup for high memory usage
function DataArchiver:EmergencyCleanup()
    print("DataArchiver: Performing emergency cleanup")
    
    local removedArchives = 0
    local currentTime = time()
    
    for dataKey, archiveList in pairs(archives) do
        -- Remove archives older than 1 hour
        for i = #archiveList, 1, -1 do
            if currentTime - archiveList[i].timestamp > 3600 then
                table.remove(archiveList, i)
                removedArchives = removedArchives + 1
            end
        end
        
        -- If still too many archives, remove oldest
        if #archiveList > ARCHIVE_CONFIG.MAX_HISTORY_SIZE then
            local toRemove = #archiveList - ARCHIVE_CONFIG.MAX_HISTORY_SIZE
            for i = 1, toRemove do
                table.remove(archiveList, 1)
                removedArchives = removedArchives + 1
            end
        end
    end
    
    if removedArchives > 0 then
        print("DataArchiver: Emergency cleanup removed", removedArchives, "archives")
    end
end

-- Calculate current memory usage
function DataArchiver:CalculateMemoryUsage()
    local totalMemory = 0
    
    for dataKey, archiveList in pairs(archives) do
        for _, archive in ipairs(archiveList) do
            totalMemory = totalMemory + self:EstimateTableMemory(archive)
        end
    end
    
    return totalMemory
end

-- Estimate table memory usage
function DataArchiver:EstimateTableMemory(tbl)
    if type(tbl) ~= "table" then
        return 0
    end
    
    local memory = 0
    for key, value in pairs(tbl) do
        memory = memory + 50 -- Base cost for key-value pair
        
        if type(value) == "table" then
            memory = memory + self:EstimateTableMemory(value)
        elseif type(value) == "string" then
            memory = memory + #value
        elseif type(value) == "number" then
            memory = memory + 8
        elseif type(value) == "boolean" then
            memory = memory + 1
        end
    end
    
    return memory
end

-- Get archive statistics
function DataArchiver:GetStats()
    local archiveStats = {}
    local totalArchives = 0
    local totalMemory = 0
    
    for dataKey, archiveList in pairs(archives) do
        local dataKeyMemory = 0
        for _, archive in ipairs(archiveList) do
            dataKeyMemory = dataKeyMemory + self:EstimateTableMemory(archive)
        end
        
        archiveStats[dataKey] = {
            archiveCount = #archiveList,
            memoryUsage = dataKeyMemory
        }
        
        totalArchives = totalArchives + #archiveList
        totalMemory = totalMemory + dataKeyMemory
    end
    
    return {
        totalArchived = performanceMetrics.totalArchived,
        totalCompressed = performanceMetrics.totalCompressed,
        totalCleaned = performanceMetrics.totalCleaned,
        lastCleanup = performanceMetrics.lastCleanup,
        currentMemoryUsage = performanceMetrics.memoryUsage,
        archiveStats = archiveStats,
        totalArchives = totalArchives,
        totalMemory = totalMemory
    }
end

-- Add cleanup callback
function DataArchiver:AddCleanupCallback(callback)
    if type(callback) == "function" then
        table.insert(cleanupCallbacks, callback)
    end
end

-- Cleanup
function DataArchiver:Cleanup()
    -- Run cleanup callbacks
    for _, callback in pairs(cleanupCallbacks) do
        pcall(callback)
    end
    
    -- Clear all archives
    archives = {}
    
    -- Reset metrics
    performanceMetrics.totalArchived = 0
    performanceMetrics.totalCompressed = 0
    performanceMetrics.totalCleaned = 0
    performanceMetrics.lastCleanup = 0
    performanceMetrics.memoryUsage = 0
    
    print("DataArchiver: Cleanup completed")
end

-- Set up automatic cleanup
local cleanupConnection = ConnectionManager:CreateThrottledConnection(
    RunService.Heartbeat,
    function()
        DataArchiver:PerformCleanup()
    end,
    ARCHIVE_CONFIG.CLEANUP_INTERVAL,
    "DataArchiver_Cleanup"
)

-- Auto-cleanup when script is destroyed
game:BindToClose(function()
    DataArchiver:Cleanup()
    if cleanupConnection then
        ConnectionManager:DisposeConnection(cleanupConnection)
    end
end)

return DataArchiver
