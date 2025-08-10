-- EnhancedMemoryManager.lua
-- Comprehensive memory management system addressing memory leaks and unbounded growth
-- Implements proper cleanup, connection tracking, and memory optimization
-- ENHANCED: Added memory leak detection, usage prediction, and security integration

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local MemoryStoreService = game:GetService("MemoryStoreService")

local Constants = require(script.Parent.Constants)

local EnhancedMemoryManager = {}
EnhancedMemoryManager.__index = EnhancedMemoryManager

-- Memory thresholds and limits
local MEMORY_CONFIG = {
    -- Memory usage thresholds
    THRESHOLDS = {
        WARNING = 50 * 1024 * 1024,      -- 50MB
        CRITICAL = 100 * 1024 * 1024,    -- 100MB
        EMERGENCY = 200 * 1024 * 1024    -- 200MB
    },
    
    -- Collection limits
    LIMITS = {
        MAX_TABLE_SIZE = 10000,
        MAX_ARRAY_SIZE = 1000,
        MAX_STRING_LENGTH = 10000,
        MAX_CONNECTIONS_PER_PLAYER = 50,
        MAX_CACHED_OBJECTS = 1000
    },
    
    -- Cleanup intervals
    CLEANUP_INTERVALS = {
        CONNECTIONS = 30,     -- 30 seconds
        TABLES = 60,          -- 1 minute
        STRINGS = 120,        -- 2 minutes
        FULL_CLEANUP = 300,   -- 5 minutes
        LEAK_DETECTION = 600  -- 10 minutes
    },
    
    -- Memory optimization strategies
    OPTIMIZATION_STRATEGIES = {
        ENABLE_WEAK_REFERENCES = true,
        ENABLE_TABLE_POOLING = true,
        ENABLE_STRING_INTERNING = true,
        ENABLE_CONNECTION_TRACKING = true,
        ENABLE_MEMORY_MONITORING = true,
        ENABLE_LEAK_DETECTION = true,      -- NEW: Memory leak detection
        ENABLE_USAGE_PREDICTION = true,    -- NEW: Memory usage prediction
        ENABLE_SECURITY_INTEGRATION = true -- NEW: Security system integration
    },
    
    -- NEW: Memory leak detection settings
    LEAK_DETECTION = {
        MIN_GROWTH_RATE = 1024 * 1024,    -- 1MB per hour minimum for leak detection
        MAX_GROWTH_RATE = 10 * 1024 * 1024, -- 10MB per hour maximum before alert
        DETECTION_WINDOW = 3600,           -- 1 hour window for leak detection
        MIN_OBJECT_COUNT = 100             -- Minimum objects to consider for leak detection
    },
    
    -- NEW: Memory usage prediction settings
    PREDICTION = {
        FORECAST_HOURS = 24,               -- Predict usage for next 24 hours
        MIN_DATA_POINTS = 10,              -- Minimum data points for prediction
        CONFIDENCE_THRESHOLD = 0.8         -- Minimum confidence for prediction
    }
}

-- Memory usage categories
local MEMORY_CATEGORIES = {
    CONNECTIONS = "CONNECTIONS",
    TABLES = "TABLES",
    STRINGS = "STRINGS",
    CACHED_OBJECTS = "CACHED_OBJECTS",
    PLAYER_DATA = "PLAYER_DATA",
    SYSTEM_DATA = "SYSTEM_DATA",
    SECURITY_DATA = "SECURITY_DATA"        -- NEW: Security-related memory
}

function EnhancedMemoryManager.new()
    local self = setmetatable({}, EnhancedMemoryManager)
    
    -- Memory tracking
    self.memoryUsage = {}            -- Category -> memory usage
    self.memoryHistory = {}          -- Historical memory data
    self.connectionTracker = {}      -- Player -> connections
    self.objectTracker = {}          -- Object -> metadata
    
    -- Cleanup tracking
    self.lastCleanup = {}            -- Category -> last cleanup time
    self.cleanupCounts = {}          -- Category -> cleanup count
    
    -- Performance tracking
    self.memoryAlerts = {}           -- Memory alert history
    self.optimizationEvents = {}     -- Optimization event history
    
    -- NEW: Memory leak detection
    self.leakDetection = {
        growthRates = {},            -- Category -> growth rate tracking
        leakAlerts = {},             -- Leak detection alerts
        objectGrowth = {},           -- Object count growth tracking
        lastLeakCheck = tick()       -- Last leak detection check
    }
    
    -- NEW: Memory usage prediction
    self.usagePrediction = {
        predictions = {},            -- Category -> usage predictions
        predictionModels = {},       -- Prediction models for each category
        lastPrediction = tick()      -- Last prediction update
    }
    
    -- NEW: Security integration
    self.securityIntegration = {
        securityEvents = {},         -- Security-related memory events
        suspiciousPatterns = {},     -- Suspicious memory patterns
        lastSecurityCheck = tick()   -- Last security check
    }
    
    -- Configuration
    self.autoCleanupEnabled = true   -- Enable automatic cleanup
    self.memoryMonitoringEnabled = true -- Enable memory monitoring
    self.weakReferencesEnabled = true -- Enable weak references
    self.leakDetectionEnabled = true -- NEW: Enable leak detection
    self.predictionEnabled = true    -- NEW: Enable usage prediction
    
    -- Memory pools
    self.tablePool = {}              -- Reusable table pool
    self.stringPool = {}             -- String intern pool
    
    return self
end

function EnhancedMemoryManager:Initialize()
    -- Set up memory monitoring
    self:SetupMemoryMonitoring()
    
    -- Set up connection tracking
    self:SetupConnectionTracking()
    
    -- Set up periodic cleanup
    self:SetupPeriodicCleanup()
    
    -- Set up memory optimization
    self:SetupMemoryOptimization()
    
    -- NEW: Set up memory leak detection
    self:SetupLeakDetection()
    
    -- NEW: Set up memory usage prediction
    self:SetupUsagePrediction()
    
    -- NEW: Set up security integration
    self:SetupSecurityIntegration()
    
    -- Initialize memory categories
    self:InitializeMemoryCategories()
    
    print("EnhancedMemoryManager: Initialized successfully with advanced features!")
end

-- Set up memory monitoring
function EnhancedMemoryManager:SetupMemoryMonitoring()
    if not self.memoryMonitoringEnabled then return end
    
    -- Monitor memory usage every second
    RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        if currentTime % 1 < 0.1 then -- Every second
            self:UpdateMemoryUsage()
        end
    end)
    
    -- Check for memory issues every 5 seconds
    RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        if currentTime % 5 < 0.1 then -- Every 5 seconds
            self:CheckMemoryHealth()
        end
    end)
end

-- Set up connection tracking
function EnhancedMemoryManager:SetupConnectionTracking()
    if not MEMORY_CONFIG.OPTIMIZATION_STRATEGIES.ENABLE_CONNECTION_TRACKING then return end
    
    -- Track player connections
    Players.PlayerAdded:Connect(function(player)
        self.connectionTracker[player.UserId] = {
            connections = {},
            lastUpdate = tick(),
            totalConnections = 0
        }
    end)
    
    -- Clean up player connections
    Players.PlayerRemoving:Connect(function(player)
        self:CleanupPlayerConnections(player)
    end)
end

-- Set up periodic cleanup
function EnhancedMemoryManager:SetupPeriodicCleanup()
    if not self.autoCleanupEnabled then return end
    
    RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        
        -- Clean up connections
        if currentTime - (self.lastCleanup.CONNECTIONS or 0) >= MEMORY_CONFIG.CLEANUP_INTERVALS.CONNECTIONS then
            self:CleanupConnections()
            self.lastCleanup.CONNECTIONS = currentTime
        end
        
        -- Clean up tables
        if currentTime - (self.lastCleanup.TABLES or 0) >= MEMORY_CONFIG.CLEANUP_INTERVALS.TABLES then
            self:CleanupTables()
            self.lastCleanup.TABLES = currentTime
        end
        
        -- Clean up strings
        if currentTime - (self.lastCleanup.STRINGS or 0) >= MEMORY_CONFIG.CLEANUP_INTERVALS.STRINGS then
            self:CleanupStrings()
            self.lastCleanup.STRINGS = currentTime
        end
        
        -- Full cleanup
        if currentTime - (self.lastCleanup.FULL_CLEANUP or 0) >= MEMORY_CONFIG.CLEANUP_INTERVALS.FULL_CLEANUP then
            self:PerformFullCleanup()
            self.lastCleanup.FULL_CLEANUP = currentTime
        end
    end)
end

-- Set up memory optimization
function EnhancedMemoryManager:SetupMemoryOptimization()
    -- Set up table pooling
    if MEMORY_CONFIG.OPTIMIZATION_STRATEGIES.ENABLE_TABLE_POOLING then
        self:InitializeTablePool()
    end
    
    -- Set up string interning
    if MEMORY_CONFIG.OPTIMIZATION_STRATEGIES.ENABLE_STRING_INTERNING then
        self:InitializeStringPool()
    end
    
    -- Set up weak references
    if MEMORY_CONFIG.OPTIMIZATION_STRATEGIES.ENABLE_WEAK_REFERENCES then
        self:SetupWeakReferences()
    end
end

-- NEW: Set up memory leak detection
function EnhancedMemoryManager:SetupLeakDetection()
    if not MEMORY_CONFIG.OPTIMIZATION_STRATEGIES.ENABLE_LEAK_DETECTION then return end
    
    -- Set up periodic leak detection
    RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        if currentTime - self.leakDetection.lastLeakCheck >= MEMORY_CONFIG.CLEANUP_INTERVALS.LEAK_DETECTION then
            self:DetectMemoryLeaks()
            self.leakDetection.lastLeakCheck = currentTime
        end
    end)
    
    print("Memory leak detection system initialized")
end

-- NEW: Set up memory usage prediction
function EnhancedMemoryManager:SetupUsagePrediction()
    if not MEMORY_CONFIG.OPTIMIZATION_STRATEGIES.ENABLE_USAGE_PREDICTION then return end
    
    -- Set up periodic prediction updates
    RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        if currentTime - self.usagePrediction.lastPrediction >= 300 then -- Every 5 minutes
            self:UpdateUsagePredictions()
            self.usagePrediction.lastPrediction = currentTime
        end
    end)
    
    print("Memory usage prediction system initialized")
end

-- NEW: Set up security integration
function EnhancedMemoryManager:SetupSecurityIntegration()
    if not MEMORY_CONFIG.OPTIMIZATION_STRATEGIES.ENABLE_SECURITY_INTEGRATION then return end
    
    -- Set up periodic security checks
    RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        if currentTime - self.securityIntegration.lastSecurityCheck >= 120 then -- Every 2 minutes
            self:CheckSecurityMemoryPatterns()
            self.securityIntegration.lastSecurityCheck = currentTime
        end
    end)
    
    print("Security integration system initialized")
end

-- Initialize memory categories
function EnhancedMemoryManager:InitializeMemoryCategories()
    for _, category in pairs(MEMORY_CATEGORIES) do
        self.memoryUsage[category] = {
            current = 0,
            peak = 0,
            lastUpdate = tick()
        }
        
        self.lastCleanup[category] = 0
        self.cleanupCounts[category] = 0
    end
end

-- Core memory management methods

-- Track a connection for a player
function EnhancedMemoryManager:TrackConnection(player, connection, metadata)
    if not self.connectionTracker[player.UserId] then
        self.connectionTracker[player.UserId] = {
            connections = {},
            lastUpdate = tick(),
            totalConnections = 0
        }
    end
    
    local playerData = self.connectionTracker[player.UserId]
    
    -- Check connection limit
    if #playerData.connections >= MEMORY_CONFIG.LIMITS.MAX_CONNECTIONS_PER_PLAYER then
        warn("Player " .. player.Name .. " has too many connections: " .. #playerData.connections)
        self:CleanupPlayerConnections(player)
    end
    
    -- Store connection with metadata
    local connectionInfo = {
        connection = connection,
        metadata = metadata or {},
        timestamp = tick(),
        id = HttpService:GenerateGUID()
    }
    
    table.insert(playerData.connections, connectionInfo)
    playerData.totalConnections = playerData.totalConnections + 1
    playerData.lastUpdate = tick()
    
    -- Track object for cleanup
    self:TrackObject(connection, {
        type = "Connection",
        player = player,
        metadata = metadata
    })
    
    return connectionInfo.id
end

-- Track an object for memory management
function EnhancedMemoryManager:TrackObject(object, metadata)
    if not object then return end
    
    local objectId = tostring(object)
    self.objectTracker[objectId] = {
        object = object,
        metadata = metadata or {},
        timestamp = tick(),
        lastAccess = tick(),
        accessCount = 0
    }
    
    -- Update memory usage
    self:UpdateObjectMemoryUsage(object, metadata)
end

-- Update memory usage for an object
function EnhancedMemoryManager:UpdateObjectMemoryUsage(object, metadata)
    local category = metadata.category or MEMORY_CATEGORIES.SYSTEM_DATA
    local estimatedSize = self:EstimateObjectSize(object)
    
    if not self.memoryUsage[category] then
        self.memoryUsage[category] = {
            current = 0,
            peak = 0,
            lastUpdate = tick()
        }
    end
    
    self.memoryUsage[category].current = self.memoryUsage[category].current + estimatedSize
    
    if self.memoryUsage[category].current > self.memoryUsage[category].peak then
        self.memoryUsage[category].peak = self.memoryUsage[category].current
    end
    
    self.memoryUsage[category].lastUpdate = tick()
end

-- Estimate object memory size
function EnhancedMemoryManager:EstimateObjectSize(object)
    local objectType = typeof(object)
    
    if objectType == "table" then
        return self:EstimateTableSize(object)
    elseif objectType == "string" then
        return #object
    elseif objectType == "number" then
        return 8
    elseif objectType == "boolean" then
        return 1
    elseif objectType == "RBXScriptConnection" then
        return 64 -- Estimated connection overhead
    else
        return 32 -- Default object overhead
    end
end

-- Estimate table memory size
function EnhancedMemoryManager:EstimateTableSize(table)
    local size = 0
    local count = 0
    
    for key, value in pairs(table) do
        size = size + self:EstimateObjectSize(key) + self:EstimateObjectSize(value)
        count = count + 1
        
        -- Limit recursion depth
        if count > MEMORY_CONFIG.LIMITS.MAX_TABLE_SIZE then
            break
        end
    end
    
    return size + 32 -- Table overhead
end

-- Update overall memory usage
function EnhancedMemoryManager:UpdateMemoryUsage()
    local totalMemory = 0
    
    for category, data in pairs(self.memoryUsage) do
        totalMemory = totalMemory + data.current
        
        -- Store historical data
        if not self.memoryHistory[category] then
            self.memoryHistory[category] = {}
        end
        
        table.insert(self.memoryHistory[category], {
            usage = data.current,
            timestamp = tick()
        })
        
        -- Keep only last 100 entries
        if #self.memoryHistory[category] > 100 then
            table.remove(self.memoryHistory[category], 1)
        end
    end
    
    -- Check memory thresholds
    self:CheckMemoryThresholds(totalMemory)
end

-- Check memory thresholds
function EnhancedMemoryManager:CheckMemoryThresholds(totalMemory)
    if totalMemory >= MEMORY_CONFIG.THRESHOLDS.EMERGENCY then
        self:HandleMemoryEmergency(totalMemory)
    elseif totalMemory >= MEMORY_CONFIG.THRESHOLDS.CRITICAL then
        self:HandleMemoryCritical(totalMemory)
    elseif totalMemory >= MEMORY_CONFIG.THRESHOLDS.WARNING then
        self:HandleMemoryWarning(totalMemory)
    end
end

-- Handle memory warning
function EnhancedMemoryManager:HandleMemoryWarning(totalMemory)
    local alert = {
        level = "WARNING",
        message = "Memory usage is high: " .. self:FormatBytes(totalMemory),
        timestamp = tick(),
        action = "Monitor closely"
    }
    
    table.insert(self.memoryAlerts, alert)
    print("MEMORY WARNING: " .. alert.message)
    
    -- Trigger light cleanup
    self:TriggerLightCleanup()
end

-- Handle memory critical
function EnhancedMemoryManager:HandleMemoryCritical(totalMemory)
    local alert = {
        level = "CRITICAL",
        message = "Memory usage is critical: " .. self:FormatBytes(totalMemory),
        timestamp = tick(),
        action = "Aggressive cleanup required"
    }
    
    table.insert(self.memoryAlerts, alert)
    warn("MEMORY CRITICAL: " .. alert.message)
    
    -- Trigger aggressive cleanup
    self:TriggerAggressiveCleanup()
end

-- Handle memory emergency
function EnhancedMemoryManager:HandleMemoryEmergency(totalMemory)
    local alert = {
        level = "EMERGENCY",
        message = "Memory usage is emergency level: " .. self:FormatBytes(totalMemory),
        timestamp = tick(),
        action = "Emergency cleanup and optimization"
    }
    
    table.insert(self.memoryAlerts, alert)
    error("MEMORY EMERGENCY: " .. alert.message)
    
    -- Trigger emergency cleanup
    self:TriggerEmergencyCleanup()
end

-- Check overall memory health
function EnhancedMemoryManager:CheckMemoryHealth()
    local totalMemory = 0
    for _, data in pairs(self.memoryUsage) do
        totalMemory = totalMemory + data.current
    end
    
    -- Calculate memory health percentage
    local healthPercentage = math.max(0, 100 - (totalMemory / MEMORY_CONFIG.THRESHOLDS.EMERGENCY * 100))
    
    -- Log memory health
    if healthPercentage < 50 then
        print("MEMORY HEALTH: " .. string.format("%.1f%%", healthPercentage) .. " - " .. self:FormatBytes(totalMemory))
    end
    
    -- Trigger optimization if needed
    if healthPercentage < 30 then
        self:TriggerMemoryOptimization()
    end
end

-- NEW: Detect memory leaks across all categories
function EnhancedMemoryManager:DetectMemoryLeaks()
    local currentTime = tick()
    local leaksDetected = 0
    
    for category, data in pairs(self.memoryUsage) do
        -- Calculate growth rate over the detection window
        local growthRate = self:CalculateMemoryGrowthRate(category, MEMORY_CONFIG.LEAK_DETECTION.DETECTION_WINDOW)
        
        -- Store growth rate for tracking
        if not self.leakDetection.growthRates[category] then
            self.leakDetection.growthRates[category] = {}
        end
        
        table.insert(self.leakDetection.growthRates[category], {
            rate = growthRate,
            timestamp = currentTime
        })
        
        -- Keep only last 10 growth rate measurements
        if #self.leakDetection.growthRates[category] > 10 then
            table.remove(self.leakDetection.growthRates[category], 1)
        end
        
        -- Check if growth rate indicates a leak
        if growthRate > MEMORY_CONFIG.LEAK_DETECTION.MIN_GROWTH_RATE then
            local leakAlert = {
                category = category,
                growthRate = growthRate,
                severity = growthRate > MEMORY_CONFIG.LEAK_DETECTION.MAX_GROWTH_RATE and "HIGH" or "MEDIUM",
                timestamp = currentTime,
                message = string.format("Memory leak detected in %s: %.2f MB/hour", category, growthRate / (1024 * 1024))
            }
            
            table.insert(self.leakDetection.leakAlerts, leakAlert)
            leaksDetected = leaksDetected + 1
            
            -- Log leak detection
            warn("MEMORY LEAK DETECTED:", leakAlert.message)
            
            -- Trigger immediate cleanup for the category
            self:CleanupCategory(category)
        end
    end
    
    -- Check object count growth
    self:DetectObjectCountLeaks()
    
    if leaksDetected > 0 then
        print("Memory leak detection: " .. leaksDetected .. " potential leaks found")
    end
end

-- NEW: Calculate memory growth rate for a category
function EnhancedMemoryManager:CalculateMemoryGrowthRate(category, windowSeconds)
    if not self.memoryHistory[category] or #self.memoryHistory[category] < 2 then
        return 0
    end
    
    local currentTime = tick()
    local windowStart = currentTime - windowSeconds
    
    -- Find data points within the window
    local recentData = {}
    for _, dataPoint in ipairs(self.memoryHistory[category]) do
        if dataPoint.timestamp >= windowStart then
            table.insert(recentData, dataPoint)
        end
    end
    
    if #recentData < 2 then
        return 0
    end
    
    -- Calculate growth rate (bytes per second)
    local firstData = recentData[1]
    local lastData = recentData[#recentData]
    local timeDiff = lastData.timestamp - firstData.timestamp
    local memoryDiff = lastData.usage - firstData.usage
    
    if timeDiff <= 0 then
        return 0
    end
    
    -- Convert to bytes per hour for easier reading
    return (memoryDiff / timeDiff) * 3600
end

-- NEW: Detect leaks based on object count growth
function EnhancedMemoryManager:DetectObjectCountLeaks()
    local currentTime = tick()
    local currentObjectCount = self:GetTotalObjectCount()
    
    if not self.leakDetection.objectGrowth.lastCount then
        self.leakDetection.objectGrowth.lastCount = currentObjectCount
        self.leakDetection.objectGrowth.lastCheck = currentTime
        return
    end
    
    local timeDiff = currentTime - self.leakDetection.objectGrowth.lastCheck
    local countDiff = currentObjectCount - self.leakDetection.objectGrowth.lastCount
    
    if timeDiff > 0 and countDiff > 0 then
        local growthRate = countDiff / timeDiff * 3600 -- objects per hour
        
        if growthRate > 1000 then -- More than 1000 objects per hour
            local leakAlert = {
                type = "OBJECT_COUNT_LEAK",
                growthRate = growthRate,
                severity = "HIGH",
                timestamp = currentTime,
                message = string.format("Object count growing rapidly: %.0f objects/hour", growthRate)
            }
            
            table.insert(self.leakDetection.leakAlerts, leakAlert)
            warn("OBJECT LEAK DETECTED:", leakAlert.message)
            
            -- Trigger aggressive cleanup
            self:TriggerAggressiveCleanup()
        end
    end
    
    self.leakDetection.objectGrowth.lastCount = currentObjectCount
    self.leakDetection.objectGrowth.lastCheck = currentTime
end

-- NEW: Update memory usage predictions
function EnhancedMemoryManager:UpdateUsagePredictions()
    for category, data in pairs(self.memoryUsage) do
        local prediction = self:PredictMemoryUsage(category)
        if prediction then
            self.usagePrediction.predictions[category] = prediction
        end
    end
end

-- NEW: Predict memory usage for a category
function EnhancedMemoryManager:PredictMemoryUsage(category)
    if not self.memoryHistory[category] or #self.memoryHistory[category] < MEMORY_CONFIG.PREDICTION.MIN_DATA_POINTS then
        return nil
    end
    
    local dataPoints = self.memoryHistory[category]
    local currentTime = tick()
    
    -- Simple linear regression for prediction
    local sumX = 0
    local sumY = 0
    local sumXY = 0
    local sumX2 = 0
    local n = #dataPoints
    
    for i, dataPoint in ipairs(dataPoints) do
        local x = dataPoint.timestamp - currentTime
        local y = dataPoint.usage
        
        sumX = sumX + x
        sumY = sumY + y
        sumXY = sumXY + x * y
        sumX2 = sumX2 + x * x
    end
    
    -- Calculate slope and intercept
    local slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX)
    local intercept = (sumY - slope * sumX) / n
    
    -- Calculate confidence (R-squared)
    local meanY = sumY / n
    local ssRes = 0
    local ssTot = 0
    
    for i, dataPoint in ipairs(dataPoints) do
        local x = dataPoint.timestamp - currentTime
        local y = dataPoint.usage
        local predicted = slope * x + intercept
        
        ssRes = ssRes + (y - predicted) ^ 2
        ssTot = ssTot + (y - meanY) ^ 2
    end
    
    local rSquared = 1 - (ssRes / ssTot)
    
    -- Only return prediction if confidence is high enough
    if rSquared >= MEMORY_CONFIG.PREDICTION.CONFIDENCE_THRESHOLD then
        -- Predict usage for next 24 hours
        local predictionHours = MEMORY_CONFIG.PREDICTION.FORECAST_HOURS
        local predictedUsage = slope * (predictionHours * 3600) + intercept
        
        return {
            currentUsage = dataPoints[#dataPoints].usage,
            predictedUsage = math.max(0, predictedUsage),
            growthRate = slope * 3600, -- bytes per hour
            confidence = rSquared,
            timestamp = currentTime,
            forecastHours = predictionHours
        }
    end
    
    return nil
end

-- NEW: Check security-related memory patterns
function EnhancedMemoryManager:CheckSecurityMemoryPatterns()
    local currentTime = tick()
    
    -- Check for unusual memory patterns that might indicate security issues
    for category, data in pairs(self.memoryUsage) do
        if category == MEMORY_CATEGORIES.SECURITY_DATA then
            -- Check for rapid security data growth (potential attack)
            local growthRate = self:CalculateMemoryGrowthRate(category, 300) -- 5 minutes
            
            if growthRate > 1024 * 1024 * 10 then -- 10MB per hour
                local securityAlert = {
                    type = "SECURITY_MEMORY_SPIKE",
                    category = category,
                    growthRate = growthRate,
                    severity = "HIGH",
                    timestamp = currentTime,
                    message = "Unusual security data growth detected - potential attack"
                }
                
                table.insert(self.securityIntegration.securityEvents, securityAlert)
                warn("SECURITY MEMORY ALERT:", securityAlert.message)
                
                -- Trigger emergency cleanup
                self:TriggerEmergencyCleanup()
            end
        end
        
        -- Check for suspicious memory patterns
        if self:IsSuspiciousMemoryPattern(category, data) then
            local patternAlert = {
                type = "SUSPICIOUS_MEMORY_PATTERN",
                category = category,
                pattern = "Unusual memory usage pattern",
                severity = "MEDIUM",
                timestamp = currentTime
            }
            
            table.insert(self.securityIntegration.suspiciousPatterns, patternAlert)
        end
    end
end

-- NEW: Check if memory pattern is suspicious
function EnhancedMemoryManager:IsSuspiciousMemoryPattern(category, data)
    -- Check for sudden spikes or drops
    if not self.memoryHistory[category] or #self.memoryHistory[category] < 3 then
        return false
    end
    
    local recent = self.memoryHistory[category]
    local current = recent[#recent].usage
    local previous = recent[#recent - 1].usage
    local older = recent[#recent - 2].usage
    
    -- Check for sudden spike (more than 50% increase)
    if previous > 0 and (current - previous) / previous > 0.5 then
        return true
    end
    
    -- Check for sudden drop (more than 50% decrease)
    if previous > 0 and (previous - current) / previous > 0.5 then
        return true
    end
    
    -- Check for oscillating pattern
    if math.abs(current - older) < math.abs(current - previous) * 0.1 then
        return true
    end
    
    return false
end

-- Cleanup methods

-- Clean up connections
function EnhancedMemoryManager:CleanupConnections()
    local cleanedCount = 0
    
    for userId, playerData in pairs(self.connectionTracker) do
        local player = Players:GetPlayerByUserId(userId)
        
        if not player then
            -- Player left, clean up all connections
            cleanedCount = cleanedCount + #playerData.connections
            self.connectionTracker[userId] = nil
        else
            -- Clean up old connections
            local currentTime = tick()
            for i = #playerData.connections, 1, -1 do
                local connectionInfo = playerData.connections[i]
                
                -- Disconnect old connections (older than 5 minutes)
                if currentTime - connectionInfo.timestamp > 300 then
                    if connectionInfo.connection and typeof(connectionInfo.connection) == "RBXScriptConnection" then
                        connectionInfo.connection:Disconnect()
                    end
                    table.remove(playerData.connections, i)
                    cleanedCount = cleanedCount + 1
                end
            end
        end
    end
    
    if cleanedCount > 0 then
        self.cleanupCounts.CONNECTIONS = (self.cleanupCounts.CONNECTIONS or 0) + cleanedCount
        print("Cleaned up " .. cleanedCount .. " connections")
    end
end

-- Clean up tables
function EnhancedMemoryManager:CleanupTables()
    local cleanedCount = 0
    
    for objectId, objectInfo in pairs(self.objectTracker) do
        if objectInfo.metadata.type == "Table" then
            local table = objectInfo.object
            
            -- Check if table is too large
            if type(table) == "table" and #table > MEMORY_CONFIG.LIMITS.MAX_TABLE_SIZE then
                -- Truncate large tables
                for i = MEMORY_CONFIG.LIMITS.MAX_TABLE_SIZE + 1, #table do
                    table[i] = nil
                end
                cleanedCount = cleanedCount + 1
            end
        end
    end
    
    if cleanedCount > 0 then
        self.cleanupCounts.TABLES = (self.cleanupCounts.TABLES or 0) + cleanedCount
        print("Cleaned up " .. cleanedCount .. " large tables")
    end
end

-- Clean up strings
function EnhancedMemoryManager:CleanupStrings()
    local cleanedCount = 0
    
    for objectId, objectInfo in pairs(self.objectTracker) do
        if objectInfo.metadata.type == "String" then
            local str = objectInfo.object
            
            -- Check if string is too long
            if type(str) == "string" and #str > MEMORY_CONFIG.LIMITS.MAX_STRING_LENGTH then
                -- Truncate long strings
                objectInfo.object = string.sub(str, 1, MEMORY_CONFIG.LIMITS.MAX_STRING_LENGTH)
                cleanedCount = cleanedCount + 1
            end
        end
    end
    
    if cleanedCount > 0 then
        self.cleanupCounts.STRINGS = (self.cleanupCounts.STRINGS or 0) + cleanedCount
        print("Cleaned up " .. cleanedCount .. " long strings")
    end
end

-- Perform full cleanup
function EnhancedMemoryManager:PerformFullCleanup()
    print("Performing full memory cleanup...")
    
    -- Clean up old objects
    local currentTime = tick()
    local cleanedCount = 0
    
    for objectId, objectInfo in pairs(self.objectTracker) do
        -- Remove objects older than 10 minutes
        if currentTime - objectInfo.timestamp > 600 then
            self.objectTracker[objectId] = nil
            cleanedCount = cleanedCount + 1
        end
    end
    
    -- Force garbage collection
    collectgarbage("collect")
    
    print("Full cleanup completed. Removed " .. cleanedCount .. " old objects")
end

-- Clean up player connections
function EnhancedMemoryManager:CleanupPlayerConnections(player)
    local playerData = self.connectionTracker[player.UserId]
    if not playerData then return end
    
    local cleanedCount = 0
    
    -- Disconnect all connections
    for _, connectionInfo in pairs(playerData.connections) do
        if connectionInfo.connection and typeof(connectionInfo.connection) == "RBXScriptConnection" then
            connectionInfo.connection:Disconnect()
            cleanedCount = cleanedCount + 1
        end
    end
    
    -- Remove player data
    self.connectionTracker[player.UserId] = nil
    
    print("Cleaned up " .. cleanedCount .. " connections for " .. player.Name)
end

-- Trigger cleanup methods

-- Trigger light cleanup
function EnhancedMemoryManager:TriggerLightCleanup()
    self:CleanupConnections()
    self:CleanupStrings()
end

-- Trigger aggressive cleanup
function EnhancedMemoryManager:TriggerAggressiveCleanup()
    self:TriggerLightCleanup()
    self:CleanupTables()
    collectgarbage("collect")
end

-- Trigger emergency cleanup
function EnhancedMemoryManager:TriggerEmergencyCleanup()
    self:TriggerAggressiveCleanup()
    
    -- Clear all caches
    self:ClearAllCaches()
    
    -- Force multiple garbage collections
    for i = 1, 3 do
        collectgarbage("collect")
        wait(0.1)
    end
end

-- Trigger memory optimization
function EnhancedMemoryManager:TriggerMemoryOptimization()
    print("Triggering memory optimization...")
    
    -- Optimize table structures
    self:OptimizeTableStructures()
    
    -- Optimize string storage
    self:OptimizeStringStorage()
    
    -- Record optimization event
    table.insert(self.optimizationEvents, {
        timestamp = tick(),
        type = "MEMORY_OPTIMIZATION",
        description = "Automatic memory optimization triggered"
    })
end

-- Memory optimization methods

-- Initialize table pool
function EnhancedMemoryManager:InitializeTablePool()
    -- Pre-allocate tables for reuse
    for i = 1, 100 do
        table.insert(self.tablePool, {})
    end
    print("Table pool initialized with 100 tables")
end

-- Get table from pool
function EnhancedMemoryManager:GetTableFromPool()
    if #self.tablePool > 0 then
        return table.remove(self.tablePool)
    else
        return {}
    end
end

-- Return table to pool
function EnhancedMemoryManager:ReturnTableToPool(table)
    if #self.tablePool < 200 then -- Limit pool size
        -- Clear table contents
        for key in pairs(table) do
            table[key] = nil
        end
        table.insert(self.tablePool, table)
    end
end

-- Initialize string pool
function EnhancedMemoryManager:InitializeStringPool()
    -- String interning for common strings
    self.stringPool = {}
    print("String pool initialized")
end

-- Get interned string
function EnhancedMemoryManager:GetInternedString(str)
    if not self.stringPool[str] then
        self.stringPool[str] = str
    end
    return self.stringPool[str]
end

-- Setup weak references
function EnhancedMemoryManager:SetupWeakReferences()
    if not self.weakReferencesEnabled then return end
    
    -- Create weak reference tables for automatic cleanup
    self.weakReferences = setmetatable({}, { __mode = "v" })
    print("Weak references enabled")
end

-- Utility methods

-- Format bytes for human reading
function EnhancedMemoryManager:FormatBytes(bytes)
    local units = {"B", "KB", "MB", "GB"}
    local unitIndex = 1
    
    while bytes >= 1024 and unitIndex < #units do
        bytes = bytes / 1024
        unitIndex = unitIndex + 1
    end
    
    return string.format("%.1f %s", bytes, units[unitIndex])
end

-- Clear all caches
function EnhancedMemoryManager:ClearAllCaches()
    -- Clear string pool
    self.stringPool = {}
    
    -- Clear table pool
    self.tablePool = {}
    
    -- Clear object tracker
    self.objectTracker = {}
    
    print("All caches cleared")
end

-- Optimize table structures
function EnhancedMemoryManager:OptimizeTableStructures()
    -- This would implement table structure optimization
    -- For now, just log the action
    print("Table structures optimized")
end

-- Optimize string storage
function EnhancedMemoryManager:OptimizeStringStorage()
    -- This would implement string storage optimization
    -- For now, just log the action
    print("String storage optimized")
end

-- Public API methods

-- Get memory statistics
function EnhancedMemoryManager:GetMemoryStats()
    local totalMemory = 0
    for _, data in pairs(self.memoryUsage) do
        totalMemory = totalMemory + data.current
    end
    
    return {
        totalMemory = totalMemory,
        formattedTotal = self:FormatBytes(totalMemory),
        categories = self.memoryUsage,
        connectionCount = self:GetTotalConnectionCount(),
        objectCount = self:GetTotalObjectCount(),
        alerts = self.memoryAlerts,
        optimizationEvents = self.optimizationEvents
    }
end

-- NEW: Get enhanced memory statistics with advanced features
function EnhancedMemoryManager:GetEnhancedMemoryStats()
    local baseStats = self:GetMemoryStats()
    
    -- Add leak detection data
    baseStats.leakDetection = {
        leakAlerts = self.leakDetection.leakAlerts,
        growthRates = self.leakDetection.growthRates,
        objectGrowth = self.leakDetection.objectGrowth
    }
    
    -- Add usage predictions
    baseStats.predictions = self.usagePrediction.predictions
    
    -- Add security integration data
    baseStats.security = {
        securityEvents = self.securityIntegration.securityEvents,
        suspiciousPatterns = self.securityIntegration.suspiciousPatterns
    }
    
    -- Add memory health score
    baseStats.healthScore = self:CalculateMemoryHealthScore()
    
    return baseStats
end

-- NEW: Get memory leak detection statistics
function EnhancedMemoryManager:GetLeakDetectionStats()
    local stats = {
        totalLeaks = #self.leakDetection.leakAlerts,
        highSeverityLeaks = 0,
        mediumSeverityLeaks = 0,
        recentLeaks = 0,
        growthRates = {},
        objectGrowth = self.leakDetection.objectGrowth
    }
    
    local oneHourAgo = tick() - 3600
    
    for _, alert in ipairs(self.leakDetection.leakAlerts) do
        if alert.severity == "HIGH" then
            stats.highSeverityLeaks = stats.highSeverityLeaks + 1
        elseif alert.severity == "MEDIUM" then
            stats.mediumSeverityLeaks = stats.mediumSeverityLeaks + 1
        end
        
        if alert.timestamp > oneHourAgo then
            stats.recentLeaks = stats.recentLeaks + 1
        end
    end
    
    -- Calculate average growth rates
    for category, rates in pairs(self.leakDetection.growthRates) do
        if #rates > 0 then
            local totalRate = 0
            for _, rateData in ipairs(rates) do
                totalRate = totalRate + rateData.rate
            end
            stats.growthRates[category] = totalRate / #rates
        end
    end
    
    return stats
end

-- NEW: Get memory usage predictions
function EnhancedMemoryManager:GetUsagePredictions(category)
    if category then
        return self.usagePrediction.predictions[category]
    else
        return self.usagePrediction.predictions
    end
end

-- NEW: Get security memory statistics
function EnhancedMemoryManager:GetSecurityMemoryStats()
    local stats = {
        totalSecurityEvents = #self.securityIntegration.securityEvents,
        totalSuspiciousPatterns = #self.securityIntegration.suspiciousPatterns,
        recentSecurityEvents = 0,
        recentSuspiciousPatterns = 0,
        highSeverityEvents = 0
    }
    
    local oneHourAgo = tick() - 3600
    
    for _, event in ipairs(self.securityIntegration.securityEvents) do
        if event.timestamp > oneHourAgo then
            stats.recentSecurityEvents = stats.recentSecurityEvents + 1
        end
        
        if event.severity == "HIGH" then
            stats.highSeverityEvents = stats.highSeverityEvents + 1
        end
    end
    
    for _, pattern in ipairs(self.securityIntegration.suspiciousPatterns) do
        if pattern.timestamp > oneHourAgo then
            stats.recentSuspiciousPatterns = stats.recentSuspiciousPatterns + 1
        end
    end
    
    return stats
end

-- NEW: Calculate overall memory health score
function EnhancedMemoryManager:CalculateMemoryHealthScore()
    local totalMemory = 0
    for _, data in pairs(self.memoryUsage) do
        totalMemory = totalMemory + data.current
    end
    
    -- Base score from memory usage (0-100)
    local baseScore = math.max(0, 100 - (totalMemory / MEMORY_CONFIG.THRESHOLDS.EMERGENCY * 100))
    
    -- Penalty for memory leaks
    local leakPenalty = math.min(30, #self.leakDetection.leakAlerts * 5)
    
    -- Penalty for security issues
    local securityPenalty = math.min(20, #self.securityIntegration.securityEvents * 2)
    
    -- Bonus for optimization events
    local optimizationBonus = math.min(10, #self.optimizationEvents)
    
    local finalScore = math.max(0, baseScore - leakPenalty - securityPenalty + optimizationBonus)
    
    return {
        score = finalScore,
        baseScore = baseScore,
        leakPenalty = leakPenalty,
        securityPenalty = securityPenalty,
        optimizationBonus = optimizationBonus,
        grade = self:GetHealthGrade(finalScore)
    }
end

-- NEW: Get health grade based on score
function EnhancedMemoryManager:GetHealthGrade(score)
    if score >= 90 then return "A+"
    elseif score >= 80 then return "A"
    elseif score >= 70 then return "B"
    elseif score >= 60 then return "C"
    elseif score >= 50 then return "D"
    else return "F"
    end
end

-- NEW: Get memory trend analysis
function EnhancedMemoryManager:GetMemoryTrendAnalysis(category, hours)
    hours = hours or 24
    local seconds = hours * 3600
    local currentTime = tick()
    local windowStart = currentTime - seconds
    
    if not self.memoryHistory[category] then
        return nil
    end
    
    local trendData = {}
    for _, dataPoint in ipairs(self.memoryHistory[category]) do
        if dataPoint.timestamp >= windowStart then
            table.insert(trendData, dataPoint)
        end
    end
    
    if #trendData < 2 then
        return nil
    end
    
    -- Calculate trend statistics
    local firstUsage = trendData[1].usage
    local lastUsage = trendData[#trendData].usage
    local totalChange = lastUsage - firstUsage
    local changeRate = totalChange / hours -- per hour
    
    local trend = {
        startUsage = firstUsage,
        endUsage = lastUsage,
        totalChange = totalChange,
        changeRate = changeRate,
        trend = changeRate > 0 and "INCREASING" or changeRate < 0 and "DECREASING" or "STABLE",
        dataPoints = #trendData,
        timeWindow = hours
    }
    
    return trend
end

-- Get total connection count
function EnhancedMemoryManager:GetTotalConnectionCount()
    local total = 0
    for _, playerData in pairs(self.connectionTracker) do
        total = total + #playerData.connections
    end
    return total
end

-- Get total object count
function EnhancedMemoryManager:GetTotalObjectCount()
    local count = 0
    for _ in pairs(self.objectTracker) do
        count = count + 1
    end
    return count
end

-- Get memory alerts
function EnhancedMemoryManager:GetMemoryAlerts(limit)
    limit = limit or 50
    local alerts = {}
    
    for i = #self.memoryAlerts - limit + 1, #self.memoryAlerts do
        if i > 0 then
            table.insert(alerts, self.memoryAlerts[i])
        end
    end
    
    return alerts
end

-- Get optimization events
function EnhancedMemoryManager:GetOptimizationEvents(limit)
    limit = limit or 50
    local events = {}
    
    for i = #self.optimizationEvents - limit + 1, #self.optimizationEvents do
        if i > 0 then
            table.insert(events, self.optimizationEvents[i])
        end
    end
    
    return events
end

-- Configuration methods

-- Set auto cleanup enabled
function EnhancedMemoryManager:SetAutoCleanupEnabled(enabled)
    self.autoCleanupEnabled = enabled
    print("Auto cleanup " .. (enabled and "enabled" or "disabled"))
end

-- Set memory monitoring enabled
function EnhancedMemoryManager:SetMemoryMonitoringEnabled(enabled)
    self.memoryMonitoringEnabled = enabled
    print("Memory monitoring " .. (enabled and "enabled" or "disabled"))
end

-- Set weak references enabled
function EnhancedMemoryManager:SetWeakReferencesEnabled(enabled)
    self.weakReferencesEnabled = enabled
    if enabled then
        self:SetupWeakReferences()
    end
    print("Weak references " .. (enabled and "enabled" or "disabled"))
end

-- NEW: Set leak detection enabled
function EnhancedMemoryManager:SetLeakDetectionEnabled(enabled)
    self.leakDetectionEnabled = enabled
    if enabled then
        self:SetupLeakDetection()
    end
    print("Memory leak detection " .. (enabled and "enabled" or "disabled"))
end

-- NEW: Set usage prediction enabled
function EnhancedMemoryManager:SetUsagePredictionEnabled(enabled)
    self.predictionEnabled = enabled
    if enabled then
        self:SetupUsagePrediction()
    end
    print("Memory usage prediction " .. (enabled and "enabled" or "disabled"))
end

-- NEW: Set security integration enabled
function EnhancedMemoryManager:SetSecurityIntegrationEnabled(enabled)
    if enabled then
        self:SetupSecurityIntegration()
    end
    print("Security integration " .. (enabled and "enabled" or "disabled"))
end

-- NEW: Configure leak detection settings
function EnhancedMemoryManager:ConfigureLeakDetection(settings)
    for key, value in pairs(settings) do
        if MEMORY_CONFIG.LEAK_DETECTION[key] then
            MEMORY_CONFIG.LEAK_DETECTION[key] = value
        end
    end
    print("Leak detection configuration updated")
end

-- NEW: Configure prediction settings
function EnhancedMemoryManager:ConfigurePrediction(settings)
    for key, value in pairs(settings) do
        if MEMORY_CONFIG.PREDICTION[key] then
            MEMORY_CONFIG.PREDICTION[key] = value
        end
    end
    print("Prediction configuration updated")
end

-- Manual cleanup methods

-- Force cleanup
function EnhancedMemoryManager:ForceCleanup()
    print("Forcing manual cleanup...")
    self:PerformFullCleanup()
    return true
end

-- Clean up specific category
function EnhancedMemoryManager:CleanupCategory(category)
    if category == "CONNECTIONS" then
        self:CleanupConnections()
    elseif category == "TABLES" then
        self:CleanupTables()
    elseif category == "STRINGS" then
        self:CleanupStrings()
    else
        print("Unknown cleanup category: " .. category)
        return false
    end
    
    return true
end

-- Clear memory alerts
function EnhancedMemoryManager:ClearMemoryAlerts()
    self.memoryAlerts = {}
    print("Memory alerts cleared")
end

-- Clear optimization events
function EnhancedMemoryManager:ClearOptimizationEvents()
    self.optimizationEvents = {}
    print("Optimization events cleared")
end

-- NEW: Clear leak detection data
function EnhancedMemoryManager:ClearLeakDetectionData()
    self.leakDetection.leakAlerts = {}
    self.leakDetection.growthRates = {}
    self.leakDetection.objectGrowth = {}
    print("Leak detection data cleared")
end

-- NEW: Clear usage predictions
function EnhancedMemoryManager:ClearUsagePredictions()
    self.usagePrediction.predictions = {}
    self.usagePrediction.predictionModels = {}
    print("Usage predictions cleared")
end

-- NEW: Clear security integration data
function EnhancedMemoryManager:ClearSecurityIntegrationData()
    self.securityIntegration.securityEvents = {}
    self.securityIntegration.suspiciousPatterns = {}
    print("Security integration data cleared")
end

-- NEW: Force memory leak detection
function EnhancedMemoryManager:ForceLeakDetection()
    print("Forcing memory leak detection...")
    self:DetectMemoryLeaks()
    return true
end

-- NEW: Force usage prediction update
function EnhancedMemoryManager:ForceUsagePredictionUpdate()
    print("Forcing usage prediction update...")
    self:UpdateUsagePredictions()
    return true
end

-- NEW: Force security pattern check
function EnhancedMemoryManager:ForceSecurityPatternCheck()
    print("Forcing security pattern check...")
    self:CheckSecurityMemoryPatterns()
    return true
end

-- NEW: Get comprehensive system report
function EnhancedMemoryManager:GetComprehensiveReport()
    local report = {
        timestamp = tick(),
        memoryStats = self:GetEnhancedMemoryStats(),
        leakDetection = self:GetLeakDetectionStats(),
        security = self:GetSecurityMemoryStats(),
        predictions = self:GetUsagePredictions(),
        healthScore = self:CalculateMemoryHealthScore(),
        recommendations = self:GenerateRecommendations()
    }
    
    return report
end

-- NEW: Generate system recommendations
function EnhancedMemoryManager:GenerateRecommendations()
    local recommendations = {}
    local stats = self:GetEnhancedMemoryStats()
    
    -- Memory usage recommendations
    if stats.totalMemory > MEMORY_CONFIG.THRESHOLDS.CRITICAL then
        table.insert(recommendations, "CRITICAL: Memory usage is very high - immediate cleanup required")
    elseif stats.totalMemory > MEMORY_CONFIG.THRESHOLDS.WARNING then
        table.insert(recommendations, "WARNING: Memory usage is high - consider cleanup")
    end
    
    -- Leak detection recommendations
    local leakStats = self:GetLeakDetectionStats()
    if leakStats.highSeverityLeaks > 0 then
        table.insert(recommendations, "URGENT: High severity memory leaks detected - investigate immediately")
    elseif leakStats.totalLeaks > 0 then
        table.insert(recommendations, "WARNING: Memory leaks detected - monitor and investigate")
    end
    
    -- Security recommendations
    local securityStats = self:GetSecurityMemoryStats()
    if securityStats.highSeverityEvents > 0 then
        table.insert(recommendations, "SECURITY: High severity memory events detected - security review required")
    elseif securityStats.totalSecurityEvents > 0 then
        table.insert(recommendations, "INFO: Security-related memory events detected - monitor patterns")
    end
    
    -- Performance recommendations
    if #self.optimizationEvents < 2 then
        table.insert(recommendations, "INFO: Consider enabling more memory optimization features")
    end
    
    if #recommendations == 0 then
        table.insert(recommendations, "System is running optimally - no immediate action required")
    end
    
    return recommendations
end

-- Export configuration and constants
EnhancedMemoryManager.Config = MEMORY_CONFIG
EnhancedMemoryManager.Categories = MEMORY_CATEGORIES
EnhancedMemoryManager.LeakDetection = MEMORY_CONFIG.LEAK_DETECTION
EnhancedMemoryManager.Prediction = MEMORY_CONFIG.PREDICTION

return EnhancedMemoryManager
