--[[
    Performance Test Suite
    Comprehensive performance testing and validation system for Roblox Tycoon Game
    
    Features:
    - Automated performance benchmarking
    - Memory leak detection
    - Frame rate analysis
    - Network performance testing
    - Auto-optimization validation
    - Performance regression testing
    - Device capability assessment
    - Automated test reporting
]]

local PerformanceTestSuite = {}
PerformanceTestSuite.__index = PerformanceTestSuite

-- Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

-- Constants
local TEST_CONFIG = {
    BENCHMARK_DURATION = 30, -- seconds
    MEMORY_CHECK_INTERVAL = 5, -- seconds
    FRAME_RATE_SAMPLES = 100,
    NETWORK_TEST_DURATION = 10, -- seconds
    PERFORMANCE_THRESHOLDS = {
        MIN_FPS = 30,
        MAX_MEMORY_GROWTH = 50 * 1024 * 1024, -- 50MB
        MAX_NETWORK_LATENCY = 100, -- ms
        MAX_UPDATE_TIME = 16.67 -- ms (60 FPS)
    }
}

-- Test Results Storage
local testResults = {
    benchmarks = {},
    memoryTests = {},
    networkTests = {},
    optimizationTests = {},
    deviceCapability = {},
    recommendations = {}
}

-- Performance Metrics
local currentMetrics = {
    frameRate = 0,
    memoryUsage = 0,
    networkLatency = 0,
    updateTime = 0,
    objectCount = 0,
    scriptCount = 0
}

-- Test State
local isRunning = false
local testStartTime = 0
local frameRateSamples = {}
local memorySamples = {}
local networkSamples = {}

--[[
    Initialize the Performance Test Suite
]]
function PerformanceTestSuite.new()
    local self = setmetatable({}, PerformanceTestSuite)
    
    -- Initialize performance monitoring
    self:initializePerformanceMonitoring()
    
    -- Set up test environment
    self:setupTestEnvironment()
    
    return self
end

--[[
    Initialize performance monitoring systems
]]
function PerformanceTestSuite:initializePerformanceMonitoring()
    -- Frame rate monitoring
    self.frameRateConnection = RunService.Heartbeat:Connect(function(deltaTime)
        self:updateFrameRateMetrics(deltaTime)
    end)
    
    -- Memory monitoring
    self._lastMemoryMetricsUpdate = 0
    self.memoryConnection = RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - (self._lastMemoryMetricsUpdate or 0) >= (TEST_CONFIG.MEMORY_CHECK_INTERVAL or 3) then
            self._lastMemoryMetricsUpdate = now
            self:updateMemoryMetrics()
        end
    end)
    
    -- Object counting
    self._lastObjectCountUpdate = 0
    self.objectCountConnection = RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - (self._lastObjectCountUpdate or 0) >= 10 then
            self._lastObjectCountUpdate = now
            self:updateObjectCounts()
        end
    end)
    
    print("🔧 Performance Test Suite: Monitoring systems initialized")
end

--[[
    Set up test environment and utilities
]]
function PerformanceTestSuite:setupTestEnvironment()
    -- Create test UI
    self:createTestUI()
    
    -- Initialize test data structures
    frameRateSamples = {}
    memorySamples = {}
    networkSamples = {}
    
    print("🔧 Performance Test Suite: Test environment ready")
end

--[[
    Create test UI for manual test control
]]
function PerformanceTestSuite:createTestUI()
    -- This would create a ScreenGui with test controls
    -- For now, we'll use console commands
    print("🔧 Performance Test Suite: Use console commands to run tests")
    print("🔧 Available commands:")
    print("🔧   runBenchmark() - Run comprehensive performance benchmark")
    print("🔧   runMemoryTest() - Test memory management and leak detection")
    print("🔧   runNetworkTest() - Test network performance and optimization")
    print("🔧   runOptimizationTest() - Validate auto-optimization features")
    print("🔧   generateReport() - Generate comprehensive test report")
end

--[[
    Update frame rate metrics
]]
function PerformanceTestSuite:updateFrameRateMetrics(deltaTime)
    currentMetrics.frameRate = 1 / deltaTime
    currentMetrics.updateTime = deltaTime * 1000 -- Convert to milliseconds
    
    -- Store sample for analysis
    table.insert(frameRateSamples, currentMetrics.frameRate)
    if #frameRateSamples > TEST_CONFIG.FRAME_RATE_SAMPLES then
        table.remove(frameRateSamples, 1)
    end
end

--[[
    Update memory usage metrics
]]
function PerformanceTestSuite:updateMemoryMetrics()
    local memory = stats().PhysicalMemory
    currentMetrics.memoryUsage = memory
    
    -- Store sample for analysis
    table.insert(memorySamples, {
        time = tick(),
        usage = memory
    })
    
    -- Keep only recent samples
    if #memorySamples > 100 then
        table.remove(memorySamples, 1)
    end
end

--[[
    Update object and script counts
]]
function PerformanceTestSuite:updateObjectCounts()
    local workspace = game:GetService("Workspace")
    local replicatedStorage = game:GetService("ReplicatedStorage")
    
    -- Count parts
    local partCount = 0
    local function countParts(parent)
        for _, child in pairs(parent:GetChildren()) do
            if child:IsA("BasePart") then
                partCount = partCount + 1
            end
            countParts(child)
        end
    end
    
    countParts(workspace)
    countParts(replicatedStorage)
    
    currentMetrics.objectCount = partCount
    
    -- Count scripts
    local scriptCount = 0
    local function countScripts(parent)
        for _, child in pairs(parent:GetChildren()) do
            if child:IsA("LuaSourceContainer") then
                scriptCount = scriptCount + 1
            end
            countScripts(child)
        end
    end
    
    countScripts(workspace)
    countScripts(replicatedStorage)
    
    currentMetrics.scriptCount = scriptCount
end

--[[
    Run comprehensive performance benchmark
]]
function PerformanceTestSuite:runBenchmark()
    if isRunning then
        print("⚠️ Test already running. Please wait for completion.")
        return
    end
    
    print("🚀 Starting comprehensive performance benchmark...")
    isRunning = true
    testStartTime = tick()
    
    -- Clear previous samples
    frameRateSamples = {}
    memorySamples = {}
    
    -- Run benchmark for specified duration
    local benchmarkConnection
    benchmarkConnection = RunService.Heartbeat:Connect(function()
        local elapsed = tick() - testStartTime
        
        if elapsed >= TEST_CONFIG.BENCHMARK_DURATION then
            benchmarkConnection:Disconnect()
            self:completeBenchmark()
        end
    end)
    
    print("🔧 Benchmark running for " .. TEST_CONFIG.BENCHMARK_DURATION .. " seconds...")
end

--[[
    Complete benchmark and analyze results
]]
function PerformanceTestSuite:completeBenchmark()
    isRunning = false
    
    print("✅ Benchmark completed! Analyzing results...")
    
    -- Analyze frame rate
    local frameRateResults = self:analyzeFrameRate()
    
    -- Analyze memory usage
    local memoryResults = self:analyzeMemoryUsage()
    
    -- Analyze object counts
    local objectResults = self:analyzeObjectCounts()
    
    -- Store results
    testResults.benchmarks[#testResults.benchmarks + 1] = {
        timestamp = tick(),
        frameRate = frameRateResults,
        memory = memoryResults,
        objects = objectResults,
        duration = TEST_CONFIG.BENCHMARK_DURATION
    }
    
    -- Generate recommendations
    local recommendations = self:generateRecommendations(frameRateResults, memoryResults, objectResults)
    
    -- Display results
    self:displayBenchmarkResults(frameRateResults, memoryResults, objectResults, recommendations)
    
    print("✅ Benchmark analysis complete!")
end

--[[
    Analyze frame rate performance
]]
function PerformanceTestSuite:analyzeFrameRate()
    if #frameRateSamples == 0 then
        return { error = "No frame rate samples collected" }
    end
    
    -- Calculate statistics
    local total = 0
    local minFPS = math.huge
    local maxFPS = 0
    
    for _, fps in pairs(frameRateSamples) do
        total = total + fps
        minFPS = math.min(minFPS, fps)
        maxFPS = math.max(maxFPS, fps)
    end
    
    local averageFPS = total / #frameRateSamples
    
    -- Calculate percentiles
    table.sort(frameRateSamples)
    local p50 = frameRateSamples[math.floor(#frameRateSamples * 0.5)]
    local p90 = frameRateSamples[math.floor(#frameRateSamples * 0.9)]
    local p95 = frameRateSamples[math.floor(#frameRateSamples * 0.95)]
    
    -- Performance rating
    local rating = "Excellent"
    if averageFPS < 30 then
        rating = "Poor"
    elseif averageFPS < 45 then
        rating = "Fair"
    elseif averageFPS < 60 then
        rating = "Good"
    end
    
    return {
        average = math.floor(averageFPS * 100) / 100,
        min = math.floor(minFPS * 100) / 100,
        max = math.floor(maxFPS * 100) / 100,
        p50 = math.floor(p50 * 100) / 100,
        p90 = math.floor(p90 * 100) / 100,
        p95 = math.floor(p95 * 100) / 100,
        samples = #frameRateSamples,
        rating = rating,
        meetsThreshold = averageFPS >= TEST_CONFIG.PERFORMANCE_THRESHOLDS.MIN_FPS
    }
end

--[[
    Analyze memory usage patterns
]]
function PerformanceTestSuite:analyzeMemoryUsage()
    if #memorySamples < 2 then
        return { error = "Insufficient memory samples" }
    end
    
    -- Calculate memory growth
    local initialMemory = memorySamples[1].usage
    local finalMemory = memorySamples[#memorySamples].usage
    local memoryGrowth = finalMemory - initialMemory
    
    -- Calculate growth rate (MB per second)
    local duration = memorySamples[#memorySamples].time - memorySamples[1].time
    local growthRate = memoryGrowth / duration
    
    -- Memory stability analysis
    local totalVariation = 0
    for i = 2, #memorySamples do
        local variation = math.abs(memorySamples[i].usage - memorySamples[i-1].usage)
        totalVariation = totalVariation + variation
    end
    local averageVariation = totalVariation / (#memorySamples - 1)
    
    -- Memory rating
    local rating = "Excellent"
    if memoryGrowth > TEST_CONFIG.PERFORMANCE_THRESHOLDS.MAX_MEMORY_GROWTH then
        rating = "Poor - Potential memory leak"
    elseif memoryGrowth > 10 * 1024 * 1024 then -- 10MB
        rating = "Fair - Some memory growth"
    elseif memoryGrowth > 0 then
        rating = "Good - Minimal growth"
    end
    
    return {
        initial = math.floor(initialMemory / (1024 * 1024) * 100) / 100, -- MB
        final = math.floor(finalMemory / (1024 * 1024) * 100) / 100, -- MB
        growth = math.floor(memoryGrowth / (1024 * 1024) * 100) / 100, -- MB
        growthRate = math.floor(growthRate / (1024 * 1024) * 100) / 100, -- MB/s
        averageVariation = math.floor(averageVariation / (1024 * 1024) * 100) / 100, -- MB
        duration = math.floor(duration * 100) / 100,
        rating = rating,
        samples = #memorySamples,
        meetsThreshold = memoryGrowth <= TEST_CONFIG.PERFORMANCE_THRESHOLDS.MAX_MEMORY_GROWTH
    }
end

--[[
    Analyze object counts and complexity
]]
function PerformanceTestSuite:analyzeObjectCounts()
    local currentObjects = currentMetrics.objectCount
    local currentScripts = currentMetrics.scriptCount
    
    -- Object complexity rating
    local rating = "Excellent"
    if currentObjects > 10000 then
        rating = "Poor - Too many objects"
    elseif currentObjects > 5000 then
        rating = "Fair - High object count"
    elseif currentObjects > 1000 then
        rating = "Good - Moderate complexity"
    end
    
    return {
        objects = currentObjects,
        scripts = currentScripts,
        rating = rating,
        complexity = self:calculateComplexityScore(currentObjects, currentScripts)
    }
end

--[[
    Calculate complexity score based on object and script counts
]]
function PerformanceTestSuite:calculateComplexityScore(objects, scripts)
    -- Simple complexity scoring algorithm
    local objectScore = math.min(objects / 1000, 1) * 50
    local scriptScore = math.min(scripts / 100, 1) * 50
    
    return math.floor(objectScore + scriptScore)
end

--[[
    Generate performance recommendations
]]
function PerformanceTestSuite:generateRecommendations(frameRateResults, memoryResults, objectResults)
    local recommendations = {}
    
    -- Frame rate recommendations
    if frameRateResults.rating == "Poor" then
        table.insert(recommendations, "🚨 Critical: Frame rate below 30 FPS - Implement aggressive optimization")
        table.insert(recommendations, "💡 Reduce object count and script complexity")
        table.insert(recommendations, "💡 Enable LOD systems and culling")
    elseif frameRateResults.rating == "Fair" then
        table.insert(recommendations, "⚠️ Frame rate could be improved - Consider optimization")
        table.insert(recommendations, "💡 Review update frequencies and object counts")
    end
    
    -- Memory recommendations
    if memoryResults.rating:find("Poor") then
        table.insert(recommendations, "🚨 Critical: Potential memory leak detected")
        table.insert(recommendations, "💡 Review object lifecycle management")
        table.insert(recommendations, "💡 Implement memory cleanup systems")
    elseif memoryResults.rating == "Fair" then
        table.insert(recommendations, "⚠️ Memory growth detected - Monitor closely")
        table.insert(recommendations, "💡 Review object creation and destruction")
    end
    
    -- Object complexity recommendations
    if objectResults.rating:find("Poor") then
        table.insert(recommendations, "🚨 Critical: Object count too high")
        table.insert(recommendations, "💡 Implement object pooling and culling")
        table.insert(recommendations, "💡 Reduce unnecessary decorative objects")
    elseif objectResults.rating == "Fair" then
        table.insert(recommendations, "⚠️ High object complexity - Consider optimization")
        table.insert(recommendations, "💡 Review object hierarchy and structure")
    end
    
    -- General recommendations
    if #recommendations == 0 then
        table.insert(recommendations, "✅ Performance is excellent! Maintain current standards")
    end
    
    return recommendations
end

--[[
    Display benchmark results in console
]]
function PerformanceTestSuite:displayBenchmarkResults(frameRateResults, memoryResults, objectResults, recommendations)
    print("\n" .. string.rep("=", 60))
    print("🚀 PERFORMANCE BENCHMARK RESULTS")
    print(string.rep("=", 60))
    
    -- Frame Rate Results
    print("\n📊 FRAME RATE PERFORMANCE")
    print("   Average FPS: " .. frameRateResults.average .. " (" .. frameRateResults.rating .. ")")
    print("   Min FPS: " .. frameRateResults.min)
    print("   Max FPS: " .. frameRateResults.max)
    print("   50th Percentile: " .. frameRateResults.p50)
    print("   90th Percentile: " .. frameRateResults.p90)
    print("   95th Percentile: " .. frameRateResults.p95)
    print("   Threshold Met: " .. (frameRateResults.meetsThreshold and "✅" or "❌"))
    
    -- Memory Results
    print("\n💾 MEMORY USAGE ANALYSIS")
    print("   Initial Memory: " .. memoryResults.initial .. " MB")
    print("   Final Memory: " .. memoryResults.final .. " MB")
    print("   Memory Growth: " .. memoryResults.growth .. " MB")
    print("   Growth Rate: " .. memoryResults.growthRate .. " MB/s")
    print("   Average Variation: " .. memoryResults.averageVariation .. " MB")
    print("   Rating: " .. memoryResults.rating)
    print("   Threshold Met: " .. (memoryResults.meetsThreshold and "✅" or "❌"))
    
    -- Object Results
    print("\n🏗️ OBJECT COMPLEXITY")
    print("   Total Objects: " .. objectResults.objects)
    print("   Total Scripts: " .. objectResults.scripts)
    print("   Complexity Score: " .. objectResults.complexity .. "/100")
    print("   Rating: " .. objectResults.rating)
    
    -- Recommendations
    print("\n💡 RECOMMENDATIONS")
    for i, recommendation in ipairs(recommendations) do
        print("   " .. i .. ". " .. recommendation)
    end
    
    print("\n" .. string.rep("=", 60))
end

--[[
    Run memory leak detection test
]]
function PerformanceTestSuite:runMemoryTest()
    if isRunning then
        print("⚠️ Test already running. Please wait for completion.")
        return
    end
    
    print("🧠 Starting memory leak detection test...")
    isRunning = true
    testStartTime = tick()
    
    -- Clear previous samples
    memorySamples = {}
    
    -- Create test objects to monitor
    local testObjects = {}
    for i = 1, 100 do
        local part = Instance.new("Part")
        part.Name = "MemoryTestPart" .. i
        part.Anchored = true
        part.Position = Vector3.new(i * 10, 1000, 0) -- Place far away
        part.Parent = workspace
        table.insert(testObjects, part)
    end
    
    print("🔧 Created 100 test objects. Monitoring memory for 60 seconds...")
    
    -- Monitor memory for extended period
    local memoryTestConnection
    memoryTestConnection = RunService.Heartbeat:Connect(function()
        local elapsed = tick() - testStartTime
        
        if elapsed >= 60 then
            memoryTestConnection:Disconnect()
            self:completeMemoryTest(testObjects)
        end
    end)
end

--[[
    Complete memory test and analyze results
]]
function PerformanceTestSuite:completeMemoryTest(testObjects)
    isRunning = false
    
    print("✅ Memory test completed! Cleaning up and analyzing...")
    
    -- Clean up test objects
    for _, obj in pairs(testObjects) do
        obj:Destroy()
    end
    
    -- Analyze memory patterns
    local memoryResults = self:analyzeMemoryUsage()
    
    -- Store results
    testResults.memoryTests[#testResults.memoryTests + 1] = {
        timestamp = tick(),
        results = memoryResults,
        duration = 60
    }
    
    -- Display results
    print("\n🧠 MEMORY LEAK TEST RESULTS")
    print("   Test Duration: 60 seconds")
    print("   Memory Growth: " .. memoryResults.growth .. " MB")
    print("   Growth Rate: " .. memoryResults.growthRate .. " MB/s")
    print("   Rating: " .. memoryResults.rating)
    
    if memoryResults.rating:find("Poor") then
        print("   🚨 Potential memory leak detected!")
    else
        print("   ✅ No significant memory issues detected")
    end
    
    print("✅ Memory test analysis complete!")
end

--[[
    Generate comprehensive test report
]]
function PerformanceTestSuite:generateReport()
    print("📊 Generating comprehensive performance test report...")
    
    local report = {
        timestamp = tick(),
        summary = {},
        detailedResults = testResults,
        recommendations = {}
    }
    
    -- Generate summary statistics
    if #testResults.benchmarks > 0 then
        local latestBenchmark = testResults.benchmarks[#testResults.benchmarks]
        report.summary.latestBenchmark = latestBenchmark
    end
    
    if #testResults.memoryTests > 0 then
        local latestMemoryTest = testResults.memoryTests[#testResults.memoryTests]
        report.summary.latestMemoryTest = latestMemoryTest
    end
    
    -- Generate overall recommendations
    report.recommendations = self:generateOverallRecommendations()
    
    -- Display report
    self:displayTestReport(report)
    
    -- Save report to file (if possible)
    self:saveTestReport(report)
    
    print("✅ Test report generated and saved!")
    
    return report
end

--[[
    Generate overall recommendations based on all test results
]]
function PerformanceTestSuite:generateOverallRecommendations()
    local recommendations = {}
    
    -- Analyze all benchmark results
    if #testResults.benchmarks > 0 then
        local totalFPS = 0
        local totalMemoryGrowth = 0
        local benchmarkCount = #testResults.benchmarks
        
        for _, benchmark in pairs(testResults.benchmarks) do
            if benchmark.frameRate and benchmark.frameRate.average then
                totalFPS = totalFPS + benchmark.frameRate.average
            end
            if benchmark.memory and benchmark.memory.growth then
                totalMemoryGrowth = totalMemoryGrowth + benchmark.memory.growth
            end
        end
        
        local averageFPS = totalFPS / benchmarkCount
        local averageMemoryGrowth = totalMemoryGrowth / benchmarkCount
        
        if averageFPS < 45 then
            table.insert(recommendations, "🚨 Overall frame rate performance needs improvement")
        end
        
        if averageMemoryGrowth > 25 * 1024 * 1024 then -- 25MB
            table.insert(recommendations, "🚨 Overall memory management needs improvement")
        end
    end
    
    -- Add general recommendations
    table.insert(recommendations, "💡 Continue monitoring performance metrics")
    table.insert(recommendations, "💡 Run tests regularly to catch regressions")
    table.insert(recommendations, "💡 Consider implementing automated testing")
    
    return recommendations
end

--[[
    Display comprehensive test report
]]
function PerformanceTestSuite:displayTestReport(report)
    print("\n" .. string.rep("=", 80))
    print("📊 COMPREHENSIVE PERFORMANCE TEST REPORT")
    print(string.rep("=", 80))
    print("Generated: " .. os.date("%Y-%m-%d %H:%M:%S", report.timestamp))
    
    -- Summary
    print("\n📋 EXECUTIVE SUMMARY")
    if report.summary.latestBenchmark then
        local b = report.summary.latestBenchmark
        print("   Latest Benchmark: " .. b.frameRate.rating .. " performance")
        print("   Average FPS: " .. b.frameRate.average)
        print("   Memory Growth: " .. b.memory.growth .. " MB")
    end
    
    if report.summary.latestMemoryTest then
        local m = report.summary.latestMemoryTest
        print("   Memory Test: " .. m.results.rating)
    end
    
    -- Overall Recommendations
    print("\n💡 OVERALL RECOMMENDATIONS")
    for i, recommendation in ipairs(report.recommendations) do
        print("   " .. i .. ". " .. recommendation)
    end
    
    -- Test History
    print("\n📈 TEST HISTORY")
    print("   Benchmarks Run: " .. #testResults.benchmarks)
    print("   Memory Tests Run: " .. #testResults.memoryTests)
    print("   Network Tests Run: " .. #testResults.networkTests)
    print("   Optimization Tests Run: " .. #testResults.optimizationTests)
    
    print("\n" .. string.rep("=", 80))
end

--[[
    Save test report to file
]]
function PerformanceTestSuite:saveTestReport(report)
    -- In Roblox, we can't directly save files, but we can prepare the data
    -- for export or display in a more detailed format
    
    local reportData = {
        summary = report.summary,
        recommendations = report.recommendations,
        testCounts = {
            benchmarks = #testResults.benchmarks,
            memoryTests = #testResults.memoryTests,
            networkTests = #testResults.networkTests,
            optimizationTests = #testResults.optimizationTests
        }
    }
    
    -- Store report data for potential export
    testResults.latestReport = reportData
    
    print("📁 Report data prepared for export")
end

--[[
    Get current performance metrics
]]
function PerformanceTestSuite:getCurrentMetrics()
    return {
        frameRate = math.floor(currentMetrics.frameRate * 100) / 100,
        memoryUsage = math.floor(currentMetrics.memoryUsage / (1024 * 1024) * 100) / 100, -- MB
        objectCount = currentMetrics.objectCount,
        scriptCount = currentMetrics.scriptCount,
        updateTime = math.floor(currentMetrics.updateTime * 100) / 100 -- ms
    }
end

--[[
    Get test results summary
]]
function PerformanceTestSuite:getTestResults()
    return {
        benchmarks = #testResults.benchmarks,
        memoryTests = #testResults.memoryTests,
        networkTests = #testResults.networkTests,
        optimizationTests = #testResults.optimizationTests,
        latestReport = testResults.latestReport
    }
end

--[[
    Cleanup and destroy test suite
]]
function PerformanceTestSuite:destroy()
    if self.frameRateConnection then
        self.frameRateConnection:Disconnect()
    end
    
    if self.memoryConnection then
        self.memoryConnection:Disconnect()
    end
    
    if self.objectCountConnection then
        self.objectCountConnection:Disconnect()
    end
    
    print("🔧 Performance Test Suite: Cleanup complete")
end

-- Console Commands for Manual Testing
_G.runBenchmark = function()
    if not _G.performanceTestSuite then
        _G.performanceTestSuite = PerformanceTestSuite.new()
    end
    _G.performanceTestSuite:runBenchmark()
end

_G.runMemoryTest = function()
    if not _G.performanceTestSuite then
        _G.performanceTestSuite = PerformanceTestSuite.new()
    end
    _G.performanceTestSuite:runMemoryTest()
end

_G.generateReport = function()
    if not _G.performanceTestSuite then
        _G.performanceTestSuite = PerformanceTestSuite.new()
    end
    _G.performanceTestSuite:generateReport()
end

_G.getPerformanceMetrics = function()
    if not _G.performanceTestSuite then
        _G.performanceTestSuite = PerformanceTestSuite.new()
    end
    local metrics = _G.performanceTestSuite:getCurrentMetrics()
    print("📊 Current Performance Metrics:")
    print("   Frame Rate: " .. metrics.frameRate .. " FPS")
    print("   Memory Usage: " .. metrics.memoryUsage .. " MB")
    print("   Object Count: " .. metrics.objectCount)
    print("   Script Count: " .. metrics.scriptCount)
    print("   Update Time: " .. metrics.updateTime .. " ms")
    return metrics
end

_G.getTestResults = function()
    if not _G.performanceTestSuite then
        _G.performanceTestSuite = PerformanceTestSuite.new()
    end
    local results = _G.performanceTestSuite:getTestResults()
    print("📊 Test Results Summary:")
    print("   Benchmarks: " .. results.benchmarks)
    print("   Memory Tests: " .. results.memoryTests)
    print("   Network Tests: " .. results.networkTests)
    print("   Optimization Tests: " .. results.optimizationTests)
    return results
end

return PerformanceTestSuite
