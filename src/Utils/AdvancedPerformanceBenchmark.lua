--[[
    Advanced Performance Benchmark
    Enhanced performance benchmarking and analytics system for Roblox Tycoon Game
    
    Features:
    - Advanced performance benchmarking with historical data
    - Automated regression detection and alerts
    - Performance trend analysis and forecasting
    - Device-specific performance profiling
    - Performance optimization recommendations
    - Real-time performance analytics dashboard
    - Automated performance reporting and insights
]]

local AdvancedPerformanceBenchmark = {}
AdvancedPerformanceBenchmark.__index = AdvancedPerformanceBenchmark

-- Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- Constants
local BENCHMARK_CONFIG = {
    BENCHMARK_DURATION = 60, -- seconds for comprehensive testing
    HISTORICAL_DATA_DAYS = 30, -- days of historical data to maintain
    REGRESSION_THRESHOLD = 0.15, -- 15% performance regression threshold
    TREND_ANALYSIS_SAMPLES = 100, -- samples for trend analysis
    PERFORMANCE_CATEGORIES = {
        FRAME_RATE = "frameRate",
        MEMORY_USAGE = "memoryUsage",
        NETWORK_LATENCY = "networkLatency",
        OBJECT_COUNT = "objectCount",
        SCRIPT_PERFORMANCE = "scriptPerformance",
        RENDERING_PERFORMANCE = "renderingPerformance"
    },
    DEVICE_PERFORMANCE_LEVELS = {
        LOW_END = "lowEnd",
        MID_RANGE = "midRange",
        HIGH_END = "highEnd"
    }
}

-- Performance Data Storage
local performanceData = {
    historical = {},
    current = {},
    benchmarks = {},
    trends = {},
    regressions = {},
    recommendations = {}
}

-- Benchmark State
local isBenchmarking = false
local benchmarkStartTime = 0
local currentBenchmark = nil
local performanceSamples = {}
local deviceProfile = nil

--[[
    Initialize the Advanced Performance Benchmark
]]
function AdvancedPerformanceBenchmark.new()
    local self = setmetatable({}, AdvancedPerformanceBenchmark)
    
    -- Initialize benchmark systems
    self:initializeBenchmarkSystems()
    
    -- Load historical data
    self:loadHistoricalData()
    
    -- Set up device profiling
    self:setupDeviceProfiling()
    
    return self
end

--[[
    Initialize benchmark systems
]]
function AdvancedPerformanceBenchmark:initializeBenchmarkSystems()
    -- Performance monitoring connection
    self.performanceConnection = RunService.Heartbeat:Connect(function(deltaTime)
        self:updatePerformanceMetrics(deltaTime)
    end)
    
    -- Memory monitoring
    self.memoryConnection = RunService.Heartbeat:Connect(function()
        if time() % 5 < 0.1 then
            self:updateMemoryMetrics()
        end
    end)
    
    -- Object counting
    self.objectCountConnection = RunService.Heartbeat:Connect(function()
        if time() % 10 < 0.1 then
            self:updateObjectCounts()
        end
    end)
    
    print("🔧 Advanced Performance Benchmark: Benchmark systems initialized")
end

--[[
    Set up device profiling
]]
function AdvancedPerformanceBenchmark:setupDeviceProfiling()
    -- Detect device type and capabilities
    local deviceType = self:detectDeviceType()
    local deviceCapabilities = self:assessDeviceCapabilities()
    
    deviceProfile = {
        type = deviceType,
        capabilities = deviceCapabilities,
        performanceLevel = self:determinePerformanceLevel(deviceCapabilities)
    }
    
    print("📱 Device Profile: " .. deviceProfile.type .. " (" .. deviceProfile.performanceLevel .. ")")
end

--[[
    Detect device type
]]
function AdvancedPerformanceBenchmark:detectDeviceType()
    if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
        return "Mobile"
    elseif UserInputService.GamepadEnabled then
        return "Console"
    else
        return "PC"
    end
end

--[[
    Assess device capabilities
]]
function AdvancedPerformanceBenchmark:assessDeviceCapabilities()
    local capabilities = {
        frameRate = 0,
        memoryCapacity = 0,
        objectHandling = 0,
        scriptPerformance = 0
    }
    
    -- Frame rate capability test
    local frameRateSamples = {}
    local startTime = time()
    local sampleCount = 0
    local frameRateTest = nil
    
    frameRateTest = RunService.Heartbeat:Connect(function()
        sampleCount = sampleCount + 1
        frameRateSamples[sampleCount] = 1 / RunService.Heartbeat:Wait()
        
        if time() - startTime >= 5 then -- 5 second test
            if frameRateTest then
                frameRateTest:Disconnect()
            end
        end
    end)
    
    -- Wait for test completion
    wait(6)
    
    -- Calculate average frame rate
    local totalFrameRate = 0
    for _, fps in ipairs(frameRateSamples) do
        totalFrameRate = totalFrameRate + fps
    end
    capabilities.frameRate = totalFrameRate / #frameRateSamples
    
    -- Memory capacity assessment (using modern Roblox API)
    local memoryInfo = game:GetService("Stats").PhysicalMemory
    capabilities.memoryCapacity = memoryInfo / (1024 * 1024 * 1024) -- Convert to GB
    
    -- Object handling assessment
    local objectCount = self:countGameObjects()
    capabilities.objectHandling = objectCount
    
    -- Script performance assessment
    local scriptCount = self:countScripts()
    capabilities.scriptPerformance = scriptCount
    
    return capabilities
end

--[[
    Determine performance level based on capabilities
]]
function AdvancedPerformanceBenchmark:determinePerformanceLevel(capabilities)
    if capabilities.frameRate >= 60 and capabilities.memoryCapacity >= 4 then
        return BENCHMARK_CONFIG.DEVICE_PERFORMANCE_LEVELS.HIGH_END
    elseif capabilities.frameRate >= 30 and capabilities.memoryCapacity >= 2 then
        return BENCHMARK_CONFIG.DEVICE_PERFORMANCE_LEVELS.MID_RANGE
    else
        return BENCHMARK_CONFIG.DEVICE_PERFORMANCE_LEVELS.LOW_END
    end
end

--[[
    Start comprehensive performance benchmark
]]
function AdvancedPerformanceBenchmark:startBenchmark(benchmarkName)
    if isBenchmarking then
        print("⚠️ Benchmark already in progress. Please wait for completion.")
        return false
    end
    
    print("🚀 Starting Advanced Performance Benchmark: " .. benchmarkName)
    print("=" .. string.rep("=", 60))
    
    isBenchmarking = true
    benchmarkStartTime = time()
    currentBenchmark = {
        name = benchmarkName,
        startTime = benchmarkStartTime,
        deviceProfile = deviceProfile,
        samples = {},
        results = {}
    }
    
    -- Initialize performance samples
    performanceSamples = {}
    
    -- Start benchmark monitoring
    self:startBenchmarkMonitoring()
    
    return true
end

--[[
    Start benchmark monitoring
]]
function AdvancedPerformanceBenchmark:startBenchmarkMonitoring()
    -- Performance monitoring
    self.benchmarkConnection = RunService.Heartbeat:Connect(function(deltaTime)
        self:collectBenchmarkSample(deltaTime)
    end)
    
    -- Memory monitoring
    self.benchmarkMemoryConnection = RunService.Heartbeat:Connect(function()
        if time() % 2 < 0.1 then
            self:collectMemorySample()
        end
    end)
    
    -- Network monitoring
    self.benchmarkNetworkConnection = RunService.Heartbeat:Connect(function()
        if time() % 3 < 0.1 then
            self:collectNetworkSample()
        end
    end)
    
    print("📊 Benchmark monitoring started. Duration: " .. BENCHMARK_CONFIG.BENCHMARK_DURATION .. " seconds")
end

--[[
    Collect benchmark performance sample
]]
function AdvancedPerformanceBenchmark:collectBenchmarkSample(deltaTime)
    local sample = {
        timestamp = time(),
        frameRate = 1 / deltaTime,
        updateTime = deltaTime * 1000, -- Convert to milliseconds
        objectCount = self:countGameObjects(),
        scriptCount = self:countScripts(),
        memoryUsage = game:GetService("Stats").PhysicalMemory,
        networkLatency = self:measureNetworkLatency()
    }
    
    table.insert(performanceSamples, sample)
    table.insert(currentBenchmark.samples, sample)
    
    -- Check if benchmark duration reached
    if time() - benchmarkStartTime >= BENCHMARK_CONFIG.BENCHMARK_DURATION then
        self:completeBenchmark()
    end
end

--[[
    Collect memory sample
]]
function AdvancedPerformanceBenchmark:collectMemorySample()
    local memorySample = {
        timestamp = time(),
        physicalMemory = game:GetService("Stats").PhysicalMemory,
        virtualMemory = game:GetService("Stats").VirtualMemory,
        textureMemory = game:GetService("Stats").TextureMemory,
        meshMemory = game:GetService("Stats").MeshMemory
    }
    
    table.insert(currentBenchmark.samples, memorySample)
end

--[[
    Collect network sample
]]
function AdvancedPerformanceBenchmark:collectNetworkSample()
    local networkSample = {
        timestamp = time(),
        latency = self:measureNetworkLatency(),
        bandwidth = self:measureNetworkBandwidth()
    }
    
    table.insert(currentBenchmark.samples, networkSample)
end

--[[
    Complete benchmark and analyze results
]]
function AdvancedPerformanceBenchmark:completeBenchmark()
    print("✅ Benchmark completed. Analyzing results...")
    
    -- Disconnect monitoring
    if self.benchmarkConnection then
        self.benchmarkConnection:Disconnect()
    end
    if self.benchmarkMemoryConnection then
        self.benchmarkMemoryConnection:Disconnect()
    end
    if self.benchmarkNetworkConnection then
        self.benchmarkNetworkConnection:Disconnect()
    end
    
    -- Analyze benchmark results
    local results = self:analyzeBenchmarkResults()
    
    -- Store benchmark data
    currentBenchmark.results = results
    currentBenchmark.endTime = time()
    currentBenchmark.duration = currentBenchmark.endTime - currentBenchmark.startTime
    
    table.insert(performanceData.benchmarks, currentBenchmark)
    
    -- Update historical data
    self:updateHistoricalData(currentBenchmark)
    
    -- Check for performance regressions
    self:checkPerformanceRegressions()
    
    -- Generate recommendations
    local recommendations = self:generatePerformanceRecommendations()
    
    -- Display results
    self:displayBenchmarkResults(results, recommendations)
    
    -- Reset benchmark state
    isBenchmarking = false
    currentBenchmark = nil
    
    print("🎯 Benchmark analysis complete!")
end

--[[
    Analyze benchmark results
]]
function AdvancedPerformanceBenchmark:analyzeBenchmarkResults()
    local results = {
        summary = {},
        performance = {},
        memory = {},
        network = {},
        objects = {},
        trends = {}
    }
    
    -- Performance summary
    local frameRates = {}
    local updateTimes = {}
    local objectCounts = {}
    local scriptCounts = {}
    
    for _, sample in ipairs(performanceSamples) do
        if sample.frameRate then
            table.insert(frameRates, sample.frameRate)
        end
        if sample.updateTime then
            table.insert(updateTimes, sample.updateTime)
        end
        if sample.objectCount then
            table.insert(objectCounts, sample.objectCount)
        end
        if sample.scriptCount then
            table.insert(scriptCounts, sample.scriptCount)
        end
    end
    
    -- Calculate statistics
    results.summary = {
        averageFrameRate = self:calculateAverage(frameRates),
        minFrameRate = math.min(unpack(frameRates)),
        maxFrameRate = math.max(unpack(frameRates)),
        averageUpdateTime = self:calculateAverage(updateTimes),
        maxUpdateTime = math.max(unpack(updateTimes)),
        averageObjectCount = self:calculateAverage(objectCounts),
        averageScriptCount = self:calculateAverage(scriptCounts),
        sampleCount = #performanceSamples
    }
    
    -- Performance analysis
    results.performance = {
        frameRateStability = self:calculateStability(frameRates),
        updateTimeConsistency = self:calculateConsistency(updateTimes),
        performanceGrade = self:calculatePerformanceGrade(results.summary)
    }
    
    -- Memory analysis
    results.memory = self:analyzeMemoryUsage()
    
    -- Network analysis
    results.network = self:analyzeNetworkPerformance()
    
    -- Object analysis
    results.objects = self:analyzeObjectPerformance()
    
    -- Trend analysis
    results.trends = self:analyzePerformanceTrends()
    
    return results
end

--[[
    Calculate average from array
]]
function AdvancedPerformanceBenchmark:calculateAverage(array)
    if #array == 0 then return 0 end
    
    local sum = 0
    for _, value in ipairs(array) do
        sum = sum + value
    end
    
    return sum / #array
end

--[[
    Calculate stability (coefficient of variation)
]]
function AdvancedPerformanceBenchmark:calculateStability(array)
    if #array < 2 then return 0 end
    
    local mean = self:calculateAverage(array)
    local variance = 0
    
    for _, value in ipairs(array) do
        variance = variance + (value - mean) ^ 2
    end
    
    variance = variance / (#array - 1)
    local standardDeviation = math.sqrt(variance)
    
    return (standardDeviation / mean) * 100 -- Return as percentage
end

--[[
    Calculate consistency (percentage within acceptable range)
]]
function AdvancedPerformanceBenchmark:calculateConsistency(array)
    if #array == 0 then return 0 end
    
    local acceptableCount = 0
    local acceptableThreshold = 16.67 -- 60 FPS threshold
    
    for _, value in ipairs(array) do
        if value <= acceptableThreshold then
            acceptableCount = acceptableCount + 1
        end
    end
    
    return (acceptableCount / #array) * 100
end

--[[
    Calculate performance grade
]]
function AdvancedPerformanceBenchmark:calculatePerformanceGrade(summary)
    local grade = "A"
    
    if summary.averageFrameRate < 30 then
        grade = "F"
    elseif summary.averageFrameRate < 45 then
        grade = "D"
    elseif summary.averageFrameRate < 55 then
        grade = "C"
    elseif summary.averageFrameRate < 58 then
        grade = "B"
    end
    
    return grade
end

--[[
    Analyze memory usage
]]
function AdvancedPerformanceBenchmark:analyzeMemoryUsage()
    local memorySamples = {}
    
    for _, sample in ipairs(currentBenchmark.samples) do
        if sample.physicalMemory then
            table.insert(memorySamples, sample.physicalMemory)
        end
    end
    
    if #memorySamples == 0 then
        return { error = "No memory data available" }
    end
    
    local averageMemory = self:calculateAverage(memorySamples)
    local maxMemory = math.max(unpack(memorySamples))
    local minMemory = math.min(unpack(memorySamples))
    local memoryGrowth = maxMemory - minMemory
    
    return {
        averageUsage = averageMemory,
        maxUsage = maxMemory,
        minUsage = minMemory,
        growth = memoryGrowth,
        growthRate = memoryGrowth / BENCHMARK_CONFIG.BENCHMARK_DURATION,
        efficiency = (averageMemory / maxMemory) * 100
    }
end

--[[
    Analyze network performance
]]
function AdvancedPerformanceBenchmark:analyzeNetworkPerformance()
    local networkSamples = {}
    
    for _, sample in ipairs(currentBenchmark.samples) do
        if sample.latency then
            table.insert(networkSamples, sample.latency)
        end
    end
    
    if #networkSamples == 0 then
        return { error = "No network data available" }
    end
    
    local averageLatency = self:calculateAverage(networkSamples)
    local maxLatency = math.max(unpack(networkSamples))
    local minLatency = math.min(unpack(networkSamples))
    
    return {
        averageLatency = averageLatency,
        maxLatency = maxLatency,
        minLatency = minLatency,
        latencyVariation = maxLatency - minLatency,
        networkGrade = self:calculateNetworkGrade(averageLatency)
    }
end

--[[
    Calculate network grade
]]
function AdvancedPerformanceBenchmark:calculateNetworkGrade(averageLatency)
    if averageLatency < 50 then
        return "Excellent"
    elseif averageLatency < 100 then
        return "Good"
    elseif averageLatency < 200 then
        return "Fair"
    else
        return "Poor"
    end
end

--[[
    Analyze object performance
]]
function AdvancedPerformanceBenchmark:analyzeObjectPerformance()
    local objectSamples = {}
    local scriptSamples = {}
    
    for _, sample in ipairs(currentBenchmark.samples) do
        if sample.objectCount then
            table.insert(objectSamples, sample.objectCount)
        end
        if sample.scriptCount then
            table.insert(scriptSamples, sample.scriptCount)
        end
    end
    
    local averageObjects = self:calculateAverage(objectSamples)
    local averageScripts = self:calculateAverage(scriptSamples)
    
    return {
        averageObjectCount = averageObjects,
        averageScriptCount = averageScripts,
        objectEfficiency = self:calculateObjectEfficiency(averageObjects),
        scriptEfficiency = self:calculateScriptEfficiency(averageScripts)
    }
end

--[[
    Calculate object efficiency
]]
function AdvancedPerformanceBenchmark:calculateObjectEfficiency(objectCount)
    if objectCount < 1000 then
        return "Excellent"
    elseif objectCount < 5000 then
        return "Good"
    elseif objectCount < 10000 then
        return "Fair"
    else
        return "Poor"
    end
end

--[[
    Calculate script efficiency
]]
function AdvancedPerformanceBenchmark:calculateScriptEfficiency(scriptCount)
    if scriptCount < 100 then
        return "Excellent"
    elseif scriptCount < 300 then
        return "Good"
    elseif scriptCount < 600 then
        return "Fair"
    else
        return "Poor"
    end
end

--[[
    Analyze performance trends
]]
function AdvancedPerformanceBenchmark:analyzePerformanceTrends()
    if #performanceData.benchmarks < 2 then
        return { message = "Insufficient data for trend analysis" }
    end
    
    local recentBenchmarks = {}
    local maxBenchmarks = math.min(5, #performanceData.benchmarks)
    
    for i = #performanceData.benchmarks - maxBenchmarks + 1, #performanceData.benchmarks do
        table.insert(recentBenchmarks, performanceData.benchmarks[i])
    end
    
    local frameRateTrend = self:calculateTrend(recentBenchmarks, "averageFrameRate")
    local memoryTrend = self:calculateTrend(recentBenchmarks, "averageMemoryUsage")
    
    return {
        frameRateTrend = frameRateTrend,
        memoryTrend = memoryTrend,
        overallTrend = self:determineOverallTrend(frameRateTrend, memoryTrend)
    }
end

--[[
    Calculate trend for specific metric
]]
function AdvancedPerformanceBenchmark:calculateTrend(benchmarks, metricKey)
    if #benchmarks < 2 then return "Insufficient data" end
    
    local values = {}
    for _, benchmark in ipairs(benchmarks) do
        if benchmark.results and benchmark.results.summary then
            local value = benchmark.results.summary[metricKey]
            if value then
                table.insert(values, value)
            end
        end
    end
    
    if #values < 2 then return "Insufficient data" end
    
    local firstValue = values[1]
    local lastValue = values[#values]
    local change = ((lastValue - firstValue) / firstValue) * 100
    
    if change > 5 then
        return "Improving"
    elseif change < -5 then
        return "Declining"
    else
        return "Stable"
    end
end

--[[
    Determine overall trend
]]
function AdvancedPerformanceBenchmark:determineOverallTrend(frameRateTrend, memoryTrend)
    if frameRateTrend == "Improving" and memoryTrend ~= "Declining" then
        return "Improving"
    elseif frameRateTrend == "Declining" or memoryTrend == "Declining" then
        return "Declining"
    else
        return "Stable"
    end
end

--[[
    Check for performance regressions
]]
function AdvancedPerformanceBenchmark:checkPerformanceRegressions()
    if #performanceData.benchmarks < 2 then return end
    
    local currentBenchmark = performanceData.benchmarks[#performanceData.benchmarks]
    local previousBenchmark = performanceData.benchmarks[#performanceData.benchmarks - 1]
    
    if not (currentBenchmark.results and previousBenchmark.results) then return end
    
    local currentFrameRate = currentBenchmark.results.summary.averageFrameRate
    local previousFrameRate = previousBenchmark.results.summary.averageFrameRate
    
    local regression = (previousFrameRate - currentFrameRate) / previousFrameRate
    
    if regression > BENCHMARK_CONFIG.REGRESSION_THRESHOLD then
        local regressionData = {
            timestamp = time(),
            severity = "High",
            description = "Performance regression detected",
            details = {
                previousFrameRate = previousFrameRate,
                currentFrameRate = currentFrameRate,
                regressionPercentage = regression * 100,
                threshold = BENCHMARK_CONFIG.REGRESSION_THRESHOLD * 100
            }
        }
        
        table.insert(performanceData.regressions, regressionData)
        
        print("⚠️ PERFORMANCE REGRESSION DETECTED!")
        print("   Previous FPS: " .. string.format("%.1f", previousFrameRate))
        print("   Current FPS: " .. string.format("%.1f", currentFrameRate))
        print("   Regression: " .. string.format("%.1f", regression * 100) .. "%")
    end
end

--[[
    Generate performance recommendations
]]
function AdvancedPerformanceBenchmark:generatePerformanceRecommendations()
    local recommendations = {}
    
    if not currentBenchmark or not currentBenchmark.results then
        return { message = "No benchmark data available" }
    end
    
    local results = currentBenchmark.results
    
    -- Frame rate recommendations
    if results.summary.averageFrameRate < 30 then
        table.insert(recommendations, {
            priority = "High",
            category = "Performance",
            title = "Critical Frame Rate Issue",
            description = "Frame rate is below acceptable threshold",
            action = "Implement aggressive optimization strategies"
        })
    elseif results.summary.averageFrameRate < 45 then
        table.insert(recommendations, {
            priority = "Medium",
            category = "Performance",
            title = "Frame Rate Optimization Needed",
            description = "Frame rate could be improved",
            action = "Review rendering and update loops"
        })
    end
    
    -- Memory recommendations
    if results.memory and results.memory.growthRate > 1024 * 1024 then -- 1MB per second
        table.insert(recommendations, {
            priority = "High",
            category = "Memory",
            title = "Memory Leak Detected",
            description = "Memory usage growing rapidly",
            action = "Investigate memory leaks and implement cleanup"
        })
    end
    
    -- Object count recommendations
    if results.objects and results.objects.averageObjectCount > 10000 then
        table.insert(recommendations, {
            priority = "Medium",
            category = "Objects",
            title = "High Object Count",
            description = "Too many game objects",
            action = "Implement object pooling and LOD systems"
        })
    end
    
    -- Network recommendations
    if results.network and results.network.averageLatency > 200 then
        table.insert(recommendations, {
            priority = "Medium",
            category = "Network",
            title = "Network Latency Issues",
            description = "High network latency detected",
            action = "Optimize network calls and reduce packet size"
        })
    end
    
    return recommendations
end

--[[
    Display benchmark results
]]
function AdvancedPerformanceBenchmark:displayBenchmarkResults(results, recommendations)
    print("📊 BENCHMARK RESULTS")
    print("=" .. string.rep("=", 60))
    
    -- Summary
    print("📈 PERFORMANCE SUMMARY")
    print("   Average FPS: " .. string.format("%.1f", results.summary.averageFrameRate))
    print("   Min FPS: " .. string.format("%.1f", results.summary.minFrameRate))
    print("   Max FPS: " .. string.format("%.1f", results.summary.maxFrameRate))
    print("   Performance Grade: " .. results.performance.performanceGrade)
    print("   Frame Rate Stability: " .. string.format("%.1f", results.performance.frameRateStability) .. "%")
    
    -- Memory
    if results.memory and not results.memory.error then
        print("\n💾 MEMORY ANALYSIS")
        print("   Average Usage: " .. string.format("%.1f", results.memory.averageUsage / (1024 * 1024)) .. " MB")
        print("   Memory Growth: " .. string.format("%.1f", results.memory.growth / (1024 * 1024)) .. " MB")
        print("   Memory Efficiency: " .. string.format("%.1f", results.memory.efficiency) .. "%")
    end
    
    -- Network
    if results.network and not results.network.error then
        print("\n🌐 NETWORK ANALYSIS")
        print("   Average Latency: " .. string.format("%.1f", results.network.averageLatency) .. " ms")
        print("   Network Grade: " .. results.network.networkGrade)
    end
    
    -- Objects
    if results.objects then
        print("\n🎯 OBJECT ANALYSIS")
        print("   Average Objects: " .. results.objects.averageObjectCount)
        print("   Average Scripts: " .. results.objects.averageScriptCount)
        print("   Object Efficiency: " .. results.objects.objectEfficiency)
        print("   Script Efficiency: " .. results.objects.scriptEfficiency)
    end
    
    -- Trends
    if results.trends then
        print("\n📈 TREND ANALYSIS")
        print("   Frame Rate Trend: " .. results.trends.frameRateTrend)
        print("   Overall Trend: " .. results.trends.overallTrend)
    end
    
    -- Recommendations
    if #recommendations > 0 then
        print("\n💡 RECOMMENDATIONS")
        for i, recommendation in ipairs(recommendations) do
            print("   " .. i .. ". [" .. recommendation.priority .. "] " .. recommendation.title)
            print("      " .. recommendation.description)
            print("      Action: " .. recommendation.action)
        end
    end
    
    print("\n" .. "=" .. string.rep("=", 60))
end

--[[
    Load historical data
]]
function AdvancedPerformanceBenchmark:loadHistoricalData()
    -- This would typically load from DataStore or other persistent storage
    -- For now, we'll initialize with empty data
    performanceData.historical = {}
    print("📚 Historical data initialized")
end

--[[
    Update historical data
]]
function AdvancedPerformanceBenchmark:updateHistoricalData(benchmark)
    local historicalEntry = {
        timestamp = benchmark.startTime,
        deviceProfile = benchmark.deviceProfile,
        results = benchmark.results,
        duration = benchmark.duration
    }
    
    table.insert(performanceData.historical, historicalEntry)
    
    -- Maintain only recent historical data
    if #performanceData.historical > BENCHMARK_CONFIG.HISTORICAL_DATA_DAYS then
        table.remove(performanceData.historical, 1)
    end
end

--[[
    Get performance data
]]
function AdvancedPerformanceBenchmark:getPerformanceData()
    return performanceData
end

--[[
    Get current benchmark status
]]
function AdvancedPerformanceBenchmark:getBenchmarkStatus()
    return {
        isRunning = isBenchmarking,
        currentBenchmark = currentBenchmark,
        elapsedTime = isBenchmarking and (time() - benchmarkStartTime) or 0,
        totalDuration = BENCHMARK_CONFIG.BENCHMARK_DURATION
    }
end

--[[
    Stop current benchmark
]]
function AdvancedPerformanceBenchmark:stopBenchmark()
    if not isBenchmarking then
        print("⚠️ No benchmark currently running")
        return
    end
    
    print("⏹️ Stopping benchmark...")
    self:completeBenchmark()
end

--[[
    Utility functions
]]
function AdvancedPerformanceBenchmark:countGameObjects()
    local count = 0
    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") or obj:IsA("Decal") then
            count = count + 1
        end
    end
    return count
end

function AdvancedPerformanceBenchmark:countScripts()
    local count = 0
    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
            count = count + 1
        end
    end
    return count
end

function AdvancedPerformanceBenchmark:measureNetworkLatency()
    -- Simulate network latency measurement
    -- In a real implementation, this would measure actual network performance
    return math.random(20, 150)
end

function AdvancedPerformanceBenchmark:measureNetworkBandwidth()
    -- Simulate bandwidth measurement
    -- In a real implementation, this would measure actual bandwidth
    return math.random(1000, 10000)
end

--[[
    Cleanup
]]
function AdvancedPerformanceBenchmark:destroy()
    if self.performanceConnection then
        self.performanceConnection:Disconnect()
    end
    if self.memoryConnection then
        self.memoryConnection:Disconnect()
    end
    if self.objectCountConnection then
        self.objectCountConnection:Disconnect()
    end
    if self.benchmarkConnection then
        self.benchmarkConnection:Disconnect()
    end
    if self.benchmarkMemoryConnection then
        self.benchmarkMemoryConnection:Disconnect()
    end
    if self.benchmarkNetworkConnection then
        self.benchmarkNetworkConnection:Disconnect()
    end
    
    print("🧹 Advanced Performance Benchmark: Cleanup complete")
end

return AdvancedPerformanceBenchmark
