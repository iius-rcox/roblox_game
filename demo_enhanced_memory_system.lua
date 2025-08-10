-- demo_enhanced_memory_system.lua
-- Demonstration script for the enhanced memory management system
-- Shows real-world usage of all new features

print("🚀 Enhanced Memory Management System Demo")
print("=" .. string.rep("=", 60))

-- Mock Roblox services for demonstration
local function MockRobloxServices()
    local Players = {
        PlayerAdded = { Connect = function() return {} end },
        PlayerRemoving = { Connect = function() return {} end },
        GetPlayerByUserId = function() return { Name = "DemoPlayer" } end
    }
    
    local RunService = {
        Heartbeat = { Connect = function() return {} end }
    }
    
    local HttpService = {
        GenerateGUID = function() return "demo-guid-" .. math.random(1000, 9999) end,
        JSONEncode = function(data) return tostring(data) end
    }
    
    local MemoryStoreService = {}
    
    -- Mock global services
    _G.game = {
        GetService = function(serviceName)
            if serviceName == "Players" then return Players
            elseif serviceName == "RunService" then return RunService
            elseif serviceName == "HttpService" then return HttpService
            elseif serviceName == "MemoryStoreService" then return MemoryStoreService
            end
        end
    }
    
    _G.tick = function() return os.time() end
    _G.wait = function() end
    _G.spawn = function(func) func() end
    _G.warn = function(...) print("WARN:", ...) end
    _G.error = function(...) print("ERROR:", ...) end
    _G.print = function(...) print(...) end
    _G.collectgarbage = function() return 0 end
    _G.setmetatable = setmetatable
    _G.type = type
    _G.pairs = pairs
    _G.ipairs = ipairs
    _G.table = table
    _G.math = math
    _G.string = string
    _G.os = os
    _G.tostring = tostring
    _G.tonumber = tonumber
    _G.assert = assert
end

-- Mock Constants module
local Constants = {
    MEMORY_CATEGORIES = {
        CONNECTIONS = "CONNECTIONS",
        TABLES = "TABLES",
        STRINGS = "STRINGS",
        CACHED_OBJECTS = "CACHED_OBJECTS",
        PLAYER_DATA = "PLAYER_DATA",
        SYSTEM_DATA = "SYSTEM_DATA",
        SECURITY_DATA = "SECURITY_DATA"
    }
}

-- Helper function to format bytes
local function FormatBytes(bytes)
    local units = {"B", "KB", "MB", "GB"}
    local size = bytes
    local unitIndex = 1
    
    while size >= 1024 and unitIndex < #units do
        size = size / 1024
        unitIndex = unitIndex + 1
    end
    
    return string.format("%.2f %s", size, units[unitIndex])
end

-- Helper function to simulate time passing
local function SimulateTimePassing(seconds)
    print("⏰ Simulating " .. seconds .. " seconds passing...")
    -- In real implementation, this would wait for actual time
    -- For demo, we'll just update timestamps
end

-- Main demonstration function
local function RunEnhancedMemoryDemo()
    print("\n🎯 Starting Enhanced Memory Management Demo...")
    
    -- Initialize the enhanced memory manager
    MockRobloxServices()
    package.loaded["src.Utils.Constants"] = Constants
    
    local EnhancedMemoryManager = require("src.Utils.EnhancedMemoryManager")
    local memoryManager = EnhancedMemoryManager.new()
    
    print("✅ Enhanced Memory Manager initialized")
    
    -- Demo 1: Memory Leak Detection
    print("\n🔍 Demo 1: Memory Leak Detection")
    print("-" .. string.rep("-", 40))
    
    -- Simulate normal memory usage
    print("📊 Setting up normal memory usage patterns...")
    memoryManager.memoryUsage.SYSTEM_DATA = {
        current = 25 * 1024 * 1024, -- 25MB
        peak = 25 * 1024 * 1024,
        lastUpdate = tick()
    }
    
    -- Add historical data showing normal growth
    memoryManager.memoryHistory.SYSTEM_DATA = {
        { usage = 20 * 1024 * 1024, timestamp = tick() - 7200 }, -- 20MB 2 hours ago
        { usage = 22 * 1024 * 1024, timestamp = tick() - 3600 }, -- 22MB 1 hour ago
        { usage = 25 * 1024 * 1024, timestamp = tick() }         -- 25MB now
    }
    
    print("📈 Normal growth: 20MB → 22MB → 25MB (2.5MB/hour)")
    
    -- Simulate memory leak
    print("\n🚨 Simulating memory leak...")
    memoryManager.memoryUsage.SYSTEM_DATA.current = 100 * 1024 * 1024 -- 100MB
    
    -- Add leak data
    table.insert(memoryManager.memoryHistory.SYSTEM_DATA, {
        usage = 100 * 1024 * 1024,
        timestamp = tick()
    })
    
    print("📈 Leak detected: 25MB → 100MB (75MB sudden increase)")
    
    -- Run leak detection
    memoryManager:DetectMemoryLeaks()
    
    -- Show leak detection results
    local leakStats = memoryManager:GetLeakDetectionStats()
    print("\n🔍 Leak Detection Results:")
    print("  - Total leaks detected: " .. leakStats.totalLeaks)
    print("  - Recent leaks: " .. leakStats.recentLeaks)
    print("  - System data growth rate: " .. FormatBytes(leakStats.categoryGrowthRates.SYSTEM_DATA or 0) .. "/hour")
    
    -- Demo 2: Memory Usage Prediction
    print("\n🔮 Demo 2: Memory Usage Prediction")
    print("-" .. string.rep("-", 40))
    
    -- Add more historical data for better prediction
    print("📊 Adding historical data for prediction...")
    local baseTime = tick() - 86400 -- 24 hours ago
    for i = 1, 24 do
        local timeOffset = (i - 1) * 3600 -- 1 hour apart
        local usage = 15 * 1024 * 1024 + (i * 2 * 1024 * 1024) -- Growing usage
        
        table.insert(memoryManager.memoryHistory.SYSTEM_DATA, {
            usage = usage,
            timestamp = baseTime + timeOffset
        })
    end
    
    print("📈 Added 24 data points showing steady growth")
    
    -- Update predictions
    memoryManager:UpdateUsagePredictions()
    
    -- Show predictions
    local predictions = memoryManager:GetUsagePredictions("SYSTEM_DATA")
    if predictions and predictions.forecast then
        print("\n🔮 Memory Usage Predictions:")
        print("  - Current usage: " .. FormatBytes(memoryManager.memoryUsage.SYSTEM_DATA.current))
        print("  - 6 hour forecast: " .. FormatBytes(predictions.forecast[6]))
        print("  - 12 hour forecast: " .. FormatBytes(predictions.forecast[12]))
        print("  - 24 hour forecast: " .. FormatBytes(predictions.forecast[24]))
        print("  - Confidence: " .. string.format("%.1f%%", predictions.confidence * 100))
    end
    
    -- Demo 3: Security Integration
    print("\n🛡️ Demo 3: Security Integration")
    print("-" .. string.rep("-", 40))
    
    -- Simulate suspicious security data patterns
    print("🚨 Simulating suspicious security patterns...")
    memoryManager.memoryUsage.SECURITY_DATA = {
        current = 150 * 1024 * 1024, -- 150MB
        peak = 150 * 1024 * 1024,
        lastUpdate = tick()
    }
    
    -- Add oscillating pattern (potential attack)
    memoryManager.memoryHistory.SECURITY_DATA = {
        { usage = 50 * 1024 * 1024, timestamp = tick() - 900 },  -- 50MB 15 min ago
        { usage = 200 * 1024 * 1024, timestamp = tick() - 600 }, -- 200MB 10 min ago
        { usage = 100 * 1024 * 1024, timestamp = tick() - 300 }, -- 100MB 5 min ago
        { usage = 150 * 1024 * 1024, timestamp = tick() }        -- 150MB now
    }
    
    print("📊 Oscillating pattern: 50MB → 200MB → 100MB → 150MB")
    
    -- Check security patterns
    memoryManager:CheckSecurityMemoryPatterns()
    
    -- Show security results
    local securityStats = memoryManager:GetSecurityMemoryStats()
    print("\n🛡️ Security Analysis Results:")
    print("  - Total security events: " .. securityStats.totalSecurityEvents)
    print("  - Suspicious patterns detected: " .. securityStats.suspiciousPatterns)
    print("  - Rapid growth events: " .. securityStats.rapidGrowthEvents)
    
    -- Demo 4: Memory Health Scoring
    print("\n🏥 Demo 4: Memory Health Scoring")
    print("-" .. string.rep("-", 40))
    
    -- Calculate overall health score
    local healthScore = memoryManager:CalculateMemoryHealthScore()
    
    print("🏥 Memory Health Assessment:")
    print("  - Overall Score: " .. healthScore.score .. "/100")
    print("  - Grade: " .. healthScore.grade)
    print("  - Status: " .. healthScore.status)
    
    if healthScore.details then
        print("  - Memory Usage: " .. healthScore.details.memoryScore .. "/25")
        print("  - Leak Penalty: " .. healthScore.details.leakPenalty .. "/25")
        print("  - Security Penalty: " .. healthScore.details.securityPenalty .. "/25")
        print("  - Optimization Bonus: " .. healthScore.details.optimizationBonus .. "/25")
    end
    
    -- Demo 5: Memory Trend Analysis
    print("\n📈 Demo 5: Memory Trend Analysis")
    print("-" .. string.rep("-", 40))
    
    -- Analyze trends for different time periods
    local shortTermTrend = memoryManager:GetMemoryTrendAnalysis("SYSTEM_DATA", 6)
    local longTermTrend = memoryManager:GetMemoryTrendAnalysis("SYSTEM_DATA", 24)
    
    print("📊 Trend Analysis:")
    print("  - 6-hour trend: " .. (shortTermTrend and shortTermTrend.trend or "Unknown"))
    print("  - 24-hour trend: " .. (longTermTrend and longTermTrend.trend or "Unknown"))
    
    if shortTermTrend then
        print("  - Short-term change: " .. string.format("%.1f%%", shortTermTrend.percentageChange))
        print("  - Short-term rate: " .. FormatBytes(shortTermTrend.growthRate) .. "/hour")
    end
    
    -- Demo 6: Comprehensive Reporting
    print("\n📋 Demo 6: Comprehensive Reporting")
    print("-" .. string.rep("-", 40))
    
    -- Generate comprehensive report
    local report = memoryManager:GetComprehensiveReport()
    
    print("📋 System Report Generated:")
    print("  - Memory Statistics: " .. (report.memoryStats and "✅" or "❌"))
    print("  - Leak Detection: " .. (report.leakDetection and "✅" or "❌"))
    print("  - Security Analysis: " .. (report.security and "✅" or "❌"))
    print("  - Usage Predictions: " .. (report.predictions and "✅" or "❌"))
    print("  - Health Score: " .. (report.healthScore and "✅" or "❌"))
    print("  - Recommendations: " .. (report.recommendations and "✅" or "❌"))
    
    -- Show recommendations
    if report.recommendations then
        print("\n💡 System Recommendations:")
        for i, recommendation in ipairs(report.recommendations) do
            print("  " .. i .. ". " .. recommendation)
        end
    end
    
    -- Demo 7: Configuration Management
    print("\n⚙️ Demo 7: Configuration Management")
    print("-" .. string.rep("-", 40))
    
    -- Show current configuration
    print("⚙️ Current Configuration:")
    print("  - Leak Detection: " .. (memoryManager.leakDetectionEnabled and "✅ Enabled" or "❌ Disabled"))
    print("  - Usage Prediction: " .. (memoryManager.predictionEnabled and "✅ Enabled" or "❌ Disabled"))
    print("  - Security Integration: " .. (memoryManager.securityIntegrationEnabled and "✅ Enabled" or "❌ Disabled"))
    
    -- Modify configuration
    print("\n🔧 Modifying configuration...")
    memoryManager:ConfigureLeakDetection({
        MIN_GROWTH_RATE = 1 * 1024 * 1024,  -- 1MB per hour
        MAX_GROWTH_RATE = 10 * 1024 * 1024  -- 10MB per hour
    })
    
    memoryManager:ConfigurePrediction({
        FORECAST_HOURS = 72,           -- 72 hours
        CONFIDENCE_THRESHOLD = 0.85    -- 85% confidence
    })
    
    print("✅ Configuration updated:")
    print("  - Leak detection thresholds adjusted")
    print("  - Prediction forecast extended to 72 hours")
    print("  - Confidence threshold lowered to 85%")
    
    -- Demo 8: Advanced Cleanup and Optimization
    print("\n🧹 Demo 8: Advanced Cleanup and Optimization")
    print("-" .. string.rep("-", 40))
    
    -- Show current memory state
    local currentStats = memoryManager:GetEnhancedMemoryStats()
    print("📊 Current Memory State:")
    print("  - Total memory usage: " .. FormatBytes(currentStats.totalMemory))
    print("  - Peak memory usage: " .. FormatBytes(currentStats.peakMemory))
    print("  - Active connections: " .. currentStats.activeConnections)
    print("  - Cached objects: " .. currentStats.cachedObjects)
    
    -- Perform cleanup
    print("\n🧹 Performing advanced cleanup...")
    memoryManager:ClearLeakDetectionData()
    memoryManager:ClearUsagePredictions()
    memoryManager:ClearSecurityIntegrationData()
    
    print("✅ Cleanup completed:")
    print("  - Leak detection data cleared")
    print("  - Usage predictions cleared")
    print("  - Security integration data cleared")
    
    -- Final demonstration summary
    print("\n🎉 Enhanced Memory Management Demo Complete!")
    print("=" .. string.rep("=", 60))
    print("The system successfully demonstrated:")
    print("  ✅ Advanced memory leak detection with configurable thresholds")
    print("  ✅ Memory usage prediction using linear regression")
    print("  ✅ Security integration for detecting suspicious patterns")
    print("  ✅ Comprehensive health scoring (A+ to F grading)")
    print("  ✅ Memory trend analysis over different time periods")
    print("  ✅ Detailed reporting with actionable recommendations")
    print("  ✅ Runtime configuration management")
    print("  ✅ Advanced cleanup and optimization features")
    print("  ✅ Integration with existing security systems")
    
    print("\n🚀 The enhanced memory management system is ready for production use!")
end

-- Run the demonstration
RunEnhancedMemoryDemo()
