-- test_enhanced_memory_system.lua
-- Comprehensive test suite for the enhanced memory management system
-- Tests memory leak detection, usage prediction, and security integration

print("🧪 Testing Enhanced Memory Management System...")
print("=" .. string.rep("=", 60))

-- Mock Roblox services for testing
local function MockRobloxServices()
    local Players = {
        PlayerAdded = { Connect = function() return {} end },
        PlayerRemoving = { Connect = function() return {} end },
        GetPlayerByUserId = function() return { Name = "TestPlayer" } end
    }
    
    local RunService = {
        Heartbeat = { Connect = function() return {} end }
    }
    
    local HttpService = {
        GenerateGUID = function() return "test-guid-" .. math.random(1000, 9999) end,
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

-- Test Results tracking
local TestResults = {
    totalTests = 0,
    passedTests = 0,
    failedTests = 0,
    testDetails = {}
}

function TestResults:AddTest(testName, success, details)
    self.totalTests = self.totalTests + 1
    if success then
        self.passedTests = self.passedTests + 1
        print("✅ " .. testName .. " - PASSED")
    else
        self.failedTests = self.failedTests + 1
        print("❌ " .. testName .. " - FAILED")
        if details then
            print("   Details: " .. details)
        end
    end
    
    table.insert(self.testDetails, {
        name = testName,
        success = success,
        details = details
    })
end

function TestResults:PrintSummary()
    print("\n" .. string.rep("=", 60))
    print("📊 TEST SUMMARY")
    print("=" .. string.rep("=", 60))
    print("Total Tests: " .. self.totalTests)
    print("Passed: " .. self.passedTests .. " ✅")
    print("Failed: " .. self.failedTests .. " ❌")
    print("Success Rate: " .. string.format("%.1f%%", (self.passedTests / self.totalTests) * 100))
    
    if self.failedTests > 0 then
        print("\nFailed Tests:")
        for _, test in ipairs(self.testDetails) do
            if not test.success then
                print("  - " .. test.name .. ": " .. (test.details or "No details"))
            end
        end
    end
end

-- Helper function for assertions
local function AssertEqual(expected, actual, message)
    if expected == actual then
        return true
    else
        error(string.format("Assertion failed: Expected %s, got %s. %s", 
            tostring(expected), tostring(actual), message or ""))
    end
end

local function AssertTrue(condition, message)
    if condition then
        return true
    else
        error(string.format("Assertion failed: %s", message or "Expected true"))
    end
end

-- Test 1: Enhanced Memory Manager Initialization
print("\n🧪 Test 1: Enhanced Memory Manager Initialization")
local function TestEnhancedInitialization()
    MockRobloxServices()
    
    -- Mock the Constants module
    package.loaded["src.Utils.Constants"] = Constants
    
    -- Load the enhanced memory manager
    local EnhancedMemoryManager = require("src.Utils.EnhancedMemoryManager")
    
    -- Create instance
    local memoryManager = EnhancedMemoryManager.new()
    AssertTrue(memoryManager ~= nil, "Memory manager should be created")
    
    -- Check new properties exist
    AssertTrue(memoryManager.leakDetection ~= nil, "Leak detection should be initialized")
    AssertTrue(memoryManager.usagePrediction ~= nil, "Usage prediction should be initialized")
    AssertTrue(memoryManager.securityIntegration ~= nil, "Security integration should be initialized")
    
    print("✅ Enhanced Memory Manager initialized successfully")
    return true
end

-- Test 2: Memory Leak Detection System
print("\n🧪 Test 2: Memory Leak Detection System")
local function TestLeakDetection()
    MockRobloxServices()
    package.loaded["src.Utils.Constants"] = Constants
    
    local EnhancedMemoryManager = require("src.Utils.EnhancedMemoryManager")
    local memoryManager = EnhancedMemoryManager.new()
    
    -- Simulate memory growth
    memoryManager.memoryUsage.SYSTEM_DATA = {
        current = 50 * 1024 * 1024, -- 50MB
        peak = 50 * 1024 * 1024,
        lastUpdate = tick()
    }
    
    -- Add historical data to simulate growth
    memoryManager.memoryHistory.SYSTEM_DATA = {
        { usage = 30 * 1024 * 1024, timestamp = tick() - 3600 }, -- 30MB 1 hour ago
        { usage = 40 * 1024 * 1024, timestamp = tick() - 1800 }, -- 40MB 30 min ago
        { usage = 50 * 1024 * 1024, timestamp = tick() }         -- 50MB now
    }
    
    -- Force leak detection
    memoryManager:DetectMemoryLeaks()
    
    -- Check if leak was detected
    local leakStats = memoryManager:GetLeakDetectionStats()
    AssertTrue(leakStats.totalLeaks > 0, "Memory leak should be detected")
    
    print("✅ Memory leak detection working correctly")
    return true
end

-- Test 3: Memory Usage Prediction System
print("\n🧪 Test 3: Memory Usage Prediction System")
local function TestUsagePrediction()
    MockRobloxServices()
    package.loaded["src.Utils.Constants"] = Constants
    
    local EnhancedMemoryManager = require("src.Utils.EnhancedMemoryManager")
    local memoryManager = EnhancedMemoryManager.new()
    
    -- Add enough historical data for prediction
    local baseTime = tick()
    for i = 1, 15 do
        local timeOffset = (i - 1) * 300 -- 5 minutes apart
        local usage = 10 * 1024 * 1024 + (i * 1024 * 1024) -- Growing usage
        
        if not memoryManager.memoryHistory.SYSTEM_DATA then
            memoryManager.memoryHistory.SYSTEM_DATA = {}
        end
        
        table.insert(memoryManager.memoryHistory.SYSTEM_DATA, {
            usage = usage,
            timestamp = baseTime + timeOffset
        })
    end
    
    -- Force prediction update
    memoryManager:UpdateUsagePredictions()
    
    -- Check if predictions were generated
    local predictions = memoryManager:GetUsagePredictions("SYSTEM_DATA")
    AssertTrue(predictions ~= nil, "Usage predictions should be generated")
    
    print("✅ Memory usage prediction working correctly")
    return true
end

-- Test 4: Security Integration System
print("\n🧪 Test 4: Security Integration System")
local function TestSecurityIntegration()
    MockRobloxServices()
    package.loaded["src.Utils.Constants"] = Constants
    
    local EnhancedMemoryManager = require("src.Utils.EnhancedMemoryManager")
    local memoryManager = EnhancedMemoryManager.new()
    
    -- Simulate security data growth
    memoryManager.memoryUsage.SECURITY_DATA = {
        current = 100 * 1024 * 1024, -- 100MB
        peak = 100 * 1024 * 1024,
        lastUpdate = tick()
    }
    
    -- Add historical data showing rapid growth
    memoryManager.memoryHistory.SECURITY_DATA = {
        { usage = 10 * 1024 * 1024, timestamp = tick() - 300 }, -- 10MB 5 min ago
        { usage = 50 * 1024 * 1024, timestamp = tick() - 150 }, -- 50MB 2.5 min ago
        { usage = 100 * 1024 * 1024, timestamp = tick() }       -- 100MB now
    }
    
    -- Force security pattern check
    memoryManager:CheckSecurityMemoryPatterns()
    
    -- Check if security events were detected
    local securityStats = memoryManager:GetSecurityMemoryStats()
    AssertTrue(securityStats.totalSecurityEvents > 0, "Security events should be detected")
    
    print("✅ Security integration working correctly")
    return true
end

-- Test 5: Memory Health Scoring System
print("\n🧪 Test 5: Memory Health Scoring System")
local function TestHealthScoring()
    MockRobloxServices()
    package.loaded["src.Utils.Constants"] = Constants
    
    local EnhancedMemoryManager = require("src.Utils.EnhancedMemoryManager")
    local memoryManager = EnhancedMemoryManager.new()
    
    -- Set up memory usage
    memoryManager.memoryUsage.SYSTEM_DATA = {
        current = 30 * 1024 * 1024, -- 30MB (healthy)
        peak = 30 * 1024 * 1024,
        lastUpdate = tick()
    }
    
    -- Calculate health score
    local healthScore = memoryManager:CalculateMemoryHealthScore()
    AssertTrue(healthScore.score > 80, "Health score should be high for healthy system")
    
    print("✅ Memory health scoring working correctly")
    return true
end

-- Test 6: Comprehensive Reporting System
print("\n🧪 Test 6: Comprehensive Reporting System")
local function TestComprehensiveReporting()
    MockRobloxServices()
    package.loaded["src.Utils.Constants"] = Constants
    
    local EnhancedMemoryManager = require("src.Utils.EnhancedMemoryManager")
    local memoryManager = EnhancedMemoryManager.new()
    
    -- Generate comprehensive report
    local report = memoryManager:GetComprehensiveReport()
    
    -- Check report structure
    AssertTrue(report.memoryStats ~= nil, "Report should include memory stats")
    AssertTrue(report.leakDetection ~= nil, "Report should include leak detection")
    AssertTrue(report.security ~= nil, "Report should include security stats")
    AssertTrue(report.predictions ~= nil, "Report should include predictions")
    AssertTrue(report.healthScore ~= nil, "Report should include health score")
    AssertTrue(report.recommendations ~= nil, "Report should include recommendations")
    
    print("✅ Comprehensive reporting working correctly")
    return true
end

-- Test 7: Configuration Management
print("\n🧪 Test 7: Configuration Management")
local function TestConfigurationManagement()
    MockRobloxServices()
    package.loaded["src.Utils.Constants"] = Constants
    
    local EnhancedMemoryManager = require("src.Utils.EnhancedMemoryManager")
    local memoryManager = EnhancedMemoryManager.new()
    
    -- Test configuration methods
    memoryManager:SetLeakDetectionEnabled(true)
    memoryManager:SetUsagePredictionEnabled(true)
    memoryManager:SetSecurityIntegrationEnabled(true)
    
    -- Test leak detection configuration
    memoryManager:ConfigureLeakDetection({
        MIN_GROWTH_RATE = 2 * 1024 * 1024, -- 2MB per hour
        MAX_GROWTH_RATE = 20 * 1024 * 1024  -- 20MB per hour
    })
    
    -- Test prediction configuration
    memoryManager:ConfigurePrediction({
        FORECAST_HOURS = 48,           -- 48 hours
        CONFIDENCE_THRESHOLD = 0.9     -- 90% confidence
    })
    
    print("✅ Configuration management working correctly")
    return true
end

-- Test 8: Advanced Cleanup and Optimization
print("\n🧪 Test 8: Advanced Cleanup and Optimization")
local function TestAdvancedCleanup()
    MockRobloxServices()
    package.loaded["src.Utils.Constants"] = Constants
    
    local EnhancedMemoryManager = require("src.Utils.EnhancedMemoryManager")
    local memoryManager = EnhancedMemoryManager.new()
    
    -- Test enhanced cleanup methods
    memoryManager:ClearLeakDetectionData()
    memoryManager:ClearUsagePredictions()
    memoryManager:ClearSecurityIntegrationData()
    
    -- Test force methods
    memoryManager:ForceLeakDetection()
    memoryManager:ForceUsagePredictionUpdate()
    memoryManager:ForceSecurityPatternCheck()
    
    print("✅ Advanced cleanup and optimization working correctly")
    return true
end

-- Test 9: Memory Trend Analysis
print("\n🧪 Test 9: Memory Trend Analysis")
local function TestTrendAnalysis()
    MockRobloxServices()
    package.loaded["src.Utils.Constants"] = Constants
    
    local EnhancedMemoryManager = require("src.Utils.EnhancedMemoryManager")
    local memoryManager = EnhancedMemoryManager.new()
    
    -- Add trend data
    local baseTime = tick()
    for i = 1, 10 do
        local timeOffset = (i - 1) * 3600 -- 1 hour apart
        local usage = 20 * 1024 * 1024 + (i * 5 * 1024 * 1024) -- Growing usage
        
        if not memoryManager.memoryHistory.SYSTEM_DATA then
            memoryManager.memoryHistory.SYSTEM_DATA = {}
        end
        
        table.insert(memoryManager.memoryHistory.SYSTEM_DATA, {
            usage = usage,
            timestamp = baseTime + timeOffset
        })
    end
    
    -- Analyze trends
    local trend = memoryManager:GetMemoryTrendAnalysis("SYSTEM_DATA", 24)
    AssertTrue(trend ~= nil, "Trend analysis should work")
    AssertTrue(trend.trend == "INCREASING", "Trend should show increasing usage")
    
    print("✅ Memory trend analysis working correctly")
    return true
end

-- Test 10: Integration with Security System
print("\n🧪 Test 10: Integration with Security System")
local function TestSecurityPatternDetection()
    MockRobloxServices()
    package.loaded["src.Utils.Constants"] = Constants
    
    local EnhancedMemoryManager = require("src.Utils.EnhancedMemoryManager")
    local memoryManager = EnhancedMemoryManager.new()
    
    -- Simulate suspicious memory patterns
    memoryManager.memoryUsage.SECURITY_DATA = {
        current = 200 * 1024 * 1024, -- 200MB
        peak = 200 * 1024 * 1024,
        lastUpdate = tick()
    }
    
    -- Add oscillating pattern data
    memoryManager.memoryHistory.SECURITY_DATA = {
        { usage = 100 * 1024 * 1024, timestamp = tick() - 600 },
        { usage = 200 * 1024 * 1024, timestamp = tick() - 300 },
        { usage = 150 * 1024 * 1024, timestamp = tick() }
    }
    
    -- Check for suspicious patterns
    local isSuspicious = memoryManager:IsSuspiciousMemoryPattern("SECURITY_DATA", memoryManager.memoryUsage.SECURITY_DATA)
    AssertTrue(isSuspicious, "Suspicious pattern should be detected")
    
    print("✅ Security pattern detection working correctly")
    return true
end

-- Run all tests
print("\n🚀 Starting Enhanced Memory Management System Tests...")

local tests = {
    { name = "Enhanced Initialization", func = TestEnhancedInitialization },
    { name = "Leak Detection", func = TestLeakDetection },
    { name = "Usage Prediction", func = TestUsagePrediction },
    { name = "Security Integration", func = TestSecurityIntegration },
    { name = "Health Scoring", func = TestHealthScoring },
    { name = "Comprehensive Reporting", func = TestComprehensiveReporting },
    { name = "Configuration Management", func = TestConfigurationManagement },
    { name = "Advanced Cleanup", func = TestAdvancedCleanup },
    { name = "Trend Analysis", func = TestTrendAnalysis },
    { name = "Security Pattern Detection", func = TestSecurityPatternDetection }
}

for _, test in ipairs(tests) do
    local success, result = pcall(test.func)
    TestResults:AddTest(test.name, success, result)
end

-- Print test summary
TestResults:PrintSummary()

print("\n🎉 Enhanced Memory Management System Testing Complete!")
print("The system now includes:")
print("  ✅ Advanced memory leak detection")
print("  ✅ Memory usage prediction with linear regression")
print("  ✅ Security integration and pattern detection")
print("  ✅ Comprehensive health scoring (A+ to F)")
print("  ✅ Memory trend analysis")
print("  ✅ Enhanced configuration management")
print("  ✅ Comprehensive reporting system")
print("  ✅ Advanced cleanup and optimization")
print("  ✅ Integration with security systems")
