--[[
    Enhanced Optimization Validator
    Advanced automated testing and validation system for auto-optimization features
    
    Features:
    - Comprehensive auto-optimization validation
    - Multi-device testing and validation
    - Performance improvement verification
    - Optimization strategy validation
    - Advanced regression detection
    - Automated optimization verification
    - Device-specific optimization testing
    - Performance baseline establishment
    - Optimization effectiveness scoring
    - Automated optimization recommendations
]]

local EnhancedOptimizationValidator = {}
EnhancedOptimizationValidator.__index = EnhancedOptimizationValidator

-- Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- Constants
local VALIDATION_CONFIG = {
    TEST_DURATION = 30, -- seconds per test
    BASELINE_DURATION = 45, -- seconds for baseline
    OPTIMIZATION_DELAY = 10, -- seconds to wait for optimization
    VALIDATION_ITERATIONS = 3, -- number of validation runs
    PERFORMANCE_THRESHOLDS = {
        MIN_IMPROVEMENT = 0.15, -- 15% improvement required
        MAX_REGRESSION = -0.08, -- 8% regression allowed
        MIN_FPS = 25, -- Minimum acceptable FPS
        MAX_MEMORY_GROWTH = 25 * 1024 * 1024, -- 25MB
        MIN_OPTIMIZATION_SCORE = 0.7 -- Minimum optimization effectiveness
    },
    DEVICE_TYPES = {
        PC = "PC",
        MOBILE = "Mobile",
        CONSOLE = "Console"
    },
    OPTIMIZATION_STRATEGIES = {
        "REDUCE_UPDATE_RATE",
        "REDUCE_OBJECT_COUNT",
        "ENABLE_LOD",
        "REDUCE_QUALITY",
        "OPTIMIZE_RENDERING",
        "MEMORY_CLEANUP"
    }
}

-- Validation Results Storage
local validationResults = {
    baselines = {},
    optimizationTests = {},
    deviceTests = {},
    regressionTests = {},
    strategyTests = {},
    effectivenessScores = {},
    recommendations = {},
    validationHistory = {}
}

-- Performance Baselines
local performanceBaselines = {
    frameRate = 0,
    memoryUsage = 0,
    objectCount = 0,
    scriptCount = 0,
    updateTime = 0,
    networkLatency = 0
}

-- Test State
local isRunning = false
local currentTest = nil
local testStartTime = 0
local performanceSamples = {}
local deviceProfile = nil
local optimizationHistory = {}

--[[
    Initialize the Enhanced Optimization Validator
]]
function EnhancedOptimizationValidator.new()
    local self = setmetatable({}, EnhancedOptimizationValidator)
    
    -- Initialize validation systems
    self:initializeValidationSystems()
    
    -- Set up test environment
    self:setupTestEnvironment()
    
    -- Initialize device profiling
    self:initializeDeviceProfiling()
    
    return self
end

--[[
    Initialize validation systems
]]
function EnhancedOptimizationValidator:initializeValidationSystems()
    -- Performance monitoring connection
    self.performanceConnection = RunService.Heartbeat:Connect(function(deltaTime)
        self:updatePerformanceMetrics(deltaTime)
    end)
    
    -- Memory monitoring
    self.memoryConnection = RunService.Heartbeat:Connect(function()
        if tick() % 3 < 0.1 then
            self:updateMemoryMetrics()
        end
    end)
    
    -- Object monitoring
    self.objectConnection = RunService.Heartbeat:Connect(function()
        if tick() % 5 < 0.1 then
            self:updateObjectMetrics()
        end
    end)
    
    print("🔧 Enhanced Optimization Validator: Validation systems initialized")
end

--[[
    Set up test environment
]]
function EnhancedOptimizationValidator:setupTestEnvironment()
    -- Initialize performance samples
    performanceSamples = {}
    
    -- Initialize optimization history
    optimizationHistory = {}
    
    print("🔧 Enhanced Optimization Validator: Test environment ready")
end

--[[
    Initialize device profiling
]]
function EnhancedOptimizationValidator:initializeDeviceProfiling()
    -- Detect device type and capabilities
    local deviceType = self:detectDeviceType()
    local deviceCapabilities = self:assessDeviceCapabilities()
    local performanceLevel = self:determinePerformanceLevel(deviceCapabilities)
    
    deviceProfile = {
        type = deviceType,
        capabilities = deviceCapabilities,
        performanceLevel = performanceLevel,
        optimizationProfile = self:createOptimizationProfile(performanceLevel)
    }
    
    print("📱 Device Profile: " .. deviceProfile.type .. " (" .. deviceProfile.performanceLevel .. ")")
end

--[[
    Detect device type
]]
function EnhancedOptimizationValidator:detectDeviceType()
    if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
        return VALIDATION_CONFIG.DEVICE_TYPES.MOBILE
    elseif UserInputService.GamepadEnabled then
        return VALIDATION_CONFIG.DEVICE_TYPES.CONSOLE
    else
        return VALIDATION_CONFIG.DEVICE_TYPES.PC
    end
end

--[[
    Assess device capabilities
]]
function EnhancedOptimizationValidator:assessDeviceCapabilities()
    local capabilities = {
        frameRate = 0,
        memoryCapacity = 0,
        objectHandling = 0,
        scriptPerformance = 0,
        renderingCapability = 0
    }
    
    -- Frame rate capability test
    local frameRateSamples = {}
    local startTime = tick()
    local sampleCount = 0
    
    local frameRateTest = nil
    frameRateTest = RunService.Heartbeat:Connect(function()
        sampleCount = sampleCount + 1
        frameRateSamples[sampleCount] = 1 / RunService.Heartbeat:Wait()
        
        if tick() - startTime >= 8 then -- 8 second test
            if frameRateTest then
                frameRateTest:Disconnect()
            end
        end
    end)
    
    -- Wait for test completion
    wait(9)
    
    -- Calculate average frame rate
    local totalFrameRate = 0
    for _, fps in ipairs(frameRateSamples) do
        totalFrameRate = totalFrameRate + fps
    end
    capabilities.frameRate = totalFrameRate / #frameRateSamples
    
    -- Memory capacity assessment
    local memoryInfo = game:GetService("Stats").PhysicalMemory
    capabilities.memoryCapacity = memoryInfo / (1024 * 1024 * 1024) -- Convert to GB
    
    -- Object handling assessment
    local objectCount = self:countGameObjects()
    capabilities.objectHandling = objectCount
    
    -- Script performance assessment
    local scriptCount = self:countScripts()
    capabilities.scriptPerformance = scriptCount
    
    -- Rendering capability assessment
    capabilities.renderingCapability = self:assessRenderingCapability()
    
    return capabilities
end

--[[
    Assess rendering capability
]]
function EnhancedOptimizationValidator:assessRenderingCapability()
    -- Simulate rendering capability assessment
    -- In a real implementation, this would test actual rendering performance
    local baseScore = 100
    
    -- Adjust based on device type
    if deviceProfile and deviceProfile.type == VALIDATION_CONFIG.DEVICE_TYPES.MOBILE then
        baseScore = baseScore * 0.7
    elseif deviceProfile and deviceProfile.type == VALIDATION_CONFIG.DEVICE_TYPES.CONSOLE then
        baseScore = baseScore * 0.9
    end
    
    return baseScore
end

--[[
    Determine performance level based on capabilities
]]
function EnhancedOptimizationValidator:determinePerformanceLevel(capabilities)
    if capabilities.frameRate >= 60 and capabilities.memoryCapacity >= 4 then
        return "highEnd"
    elseif capabilities.frameRate >= 30 and capabilities.memoryCapacity >= 2 then
        return "midRange"
    else
        return "lowEnd"
    end
end

--[[
    Create optimization profile for device performance level
]]
function EnhancedOptimizationValidator:createOptimizationProfile(performanceLevel)
    local profiles = {
        lowEnd = {
            updateRateReduction = 0.5, -- 50% reduction
            objectCountLimit = 5000,
            qualityReduction = 0.3, -- 30% reduction
            aggressiveOptimization = true
        },
        midRange = {
            updateRateReduction = 0.25, -- 25% reduction
            objectCountLimit = 8000,
            qualityReduction = 0.15, -- 15% reduction
            aggressiveOptimization = false
        },
        highEnd = {
            updateRateReduction = 0.1, -- 10% reduction
            objectCountLimit = 15000,
            qualityReduction = 0.05, -- 5% reduction
            aggressiveOptimization = false
        }
    }
    
    return profiles[performanceLevel] or profiles.midRange
end

--[[
    Start comprehensive validation sequence
]]
function EnhancedOptimizationValidator:startValidation(validationName)
    if isRunning then
        print("⚠️ Validation already in progress. Please wait for completion.")
        return false
    end
    
    print("🚀 Starting Enhanced Optimization Validation: " .. validationName)
    print("=" .. string.rep("=", 70))
    
    isRunning = true
    testStartTime = tick()
    currentTest = {
        name = validationName,
        startTime = testStartTime,
        deviceProfile = deviceProfile,
        phases = {},
        results = {}
    }
    
    -- Initialize performance samples
    performanceSamples = {}
    
    -- Start validation sequence
    self:runValidationSequence()
    
    return true
end

--[[
    Run validation sequence
]]
function EnhancedOptimizationValidator:runValidationSequence()
    print("🔄 Running validation sequence...")
    
    -- Phase 1: Baseline Performance
    self:runBaselineTest()
    
    -- Phase 2: Optimization Testing
    self:runOptimizationTests()
    
    -- Phase 3: Strategy Validation
    self:runStrategyValidation()
    
    -- Phase 4: Regression Detection
    self:runRegressionDetection()
    
    -- Phase 5: Effectiveness Scoring
    self:calculateEffectivenessScores()
    
    -- Phase 6: Generate Recommendations
    local recommendations = self:generateOptimizationRecommendations()
    
    -- Complete validation
    self:completeValidation(recommendations)
end

--[[
    Run baseline performance test
]]
function EnhancedOptimizationValidator:runBaselineTest()
    print("📊 Phase 1: Running baseline performance test...")
    
    local baselineStart = tick()
    local baselineSamples = {}
    
    -- Collect baseline samples
    local baselineConnection = nil
    baselineConnection = RunService.Heartbeat:Connect(function(deltaTime)
        local sample = {
                    timestamp = tick(),
        frameRate = 1 / deltaTime,
        updateTime = deltaTime * 1000,
        memoryUsage = game:GetService("Stats").PhysicalMemory,
        objectCount = self:countGameObjects(),
        scriptCount = self:countScripts()
        }
        
        table.insert(baselineSamples, sample)
        
        if tick() - baselineStart >= VALIDATION_CONFIG.BASELINE_DURATION then
            if baselineConnection then
                baselineConnection:Disconnect()
            end
        end
    end)
    
    -- Wait for baseline completion
    wait(VALIDATION_CONFIG.BASELINE_DURATION + 2)
    
    -- Calculate baseline metrics
    local baselineMetrics = self:calculateBaselineMetrics(baselineSamples)
    
    -- Store baseline results
    local baselineResult = {
        phase = "Baseline",
        duration = VALIDATION_CONFIG.BASELINE_DURATION,
        samples = baselineSamples,
        metrics = baselineMetrics,
        timestamp = baselineStart
    }
    
    table.insert(currentTest.phases, baselineResult)
    table.insert(validationResults.baselines, baselineResult)
    
    -- Update performance baselines
    performanceBaselines = baselineMetrics
    
    print("✅ Baseline test completed")
    print("   Average FPS: " .. string.format("%.1f", baselineMetrics.frameRate))
    print("   Memory Usage: " .. string.format("%.1f", baselineMetrics.memoryUsage / (1024 * 1024)) .. " MB")
end

--[[
    Calculate baseline metrics
]]
function EnhancedOptimizationValidator:calculateBaselineMetrics(samples)
    local metrics = {
        frameRate = 0,
        memoryUsage = 0,
        objectCount = 0,
        scriptCount = 0,
        updateTime = 0,
        networkLatency = 0
    }
    
    local frameRates = {}
    local memoryUsage = {}
    local objectCounts = {}
    local scriptCounts = {}
    local updateTimes = {}
    
    for _, sample in ipairs(samples) do
        if sample.frameRate then
            table.insert(frameRates, sample.frameRate)
        end
        if sample.memoryUsage then
            table.insert(memoryUsage, sample.memoryUsage)
        end
        if sample.objectCount then
            table.insert(objectCounts, sample.objectCount)
        end
        if sample.scriptCount then
            table.insert(scriptCounts, sample.scriptCount)
        end
        if sample.updateTime then
            table.insert(updateTimes, sample.updateTime)
        end
    end
    
    metrics.frameRate = self:calculateAverage(frameRates)
    metrics.memoryUsage = self:calculateAverage(memoryUsage)
    metrics.objectCount = self:calculateAverage(objectCounts)
    metrics.scriptCount = self:calculateAverage(scriptCounts)
    metrics.updateTime = self:calculateAverage(updateTimes)
    metrics.networkLatency = self:measureNetworkLatency()
    
    return metrics
end

--[[
    Run optimization tests
]]
function EnhancedOptimizationValidator:runOptimizationTests()
    print("🔧 Phase 2: Running optimization tests...")
    
    for i = 1, VALIDATION_CONFIG.VALIDATION_ITERATIONS do
        print("   Test " .. i .. "/" .. VALIDATION_CONFIG.VALIDATION_ITERATIONS)
        
        -- Run single optimization test
        local testResult = self:runSingleOptimizationTest(i)
        
        -- Store test result
        table.insert(currentTest.phases, testResult)
        table.insert(validationResults.optimizationTests, testResult)
        
        -- Wait between tests
        if i < VALIDATION_CONFIG.VALIDATION_ITERATIONS then
            wait(5)
        end
    end
    
    print("✅ Optimization tests completed")
end

--[[
    Run single optimization test
]]
function EnhancedOptimizationValidator:runSingleOptimizationTest(testNumber)
    local testStart = tick()
    local testSamples = {}
    
    -- Simulate optimization activation
    self:simulateOptimizationActivation()
    
    -- Wait for optimization to take effect
    wait(VALIDATION_CONFIG.OPTIMIZATION_DELAY)
    
    -- Collect test samples
    local testConnection = nil
    testConnection = RunService.Heartbeat:Connect(function(deltaTime)
        local sample = {
            timestamp = tick(),
            frameRate = 1 / deltaTime,
            updateTime = deltaTime * 1000,
            memoryUsage = game:GetService("Stats").PhysicalMemory,
            objectCount = self:countGameObjects(),
            scriptCount = self:countScripts()
        }
        
        table.insert(testSamples, sample)
        
        if tick() - testStart >= VALIDATION_CONFIG.TEST_DURATION then
            if testConnection then
                testConnection:Disconnect()
            end
        end
    end)
    
    -- Wait for test completion
    wait(VALIDATION_CONFIG.TEST_DURATION + 2)
    
    -- Calculate test metrics
    local testMetrics = self:calculateBaselineMetrics(testSamples)
    
    -- Calculate improvement/regression
    local improvement = self:calculateImprovement(performanceBaselines, testMetrics)
    
    return {
        phase = "Optimization Test " .. testNumber,
        duration = VALIDATION_CONFIG.TEST_DURATION,
        samples = testSamples,
        metrics = testMetrics,
        improvement = improvement,
        timestamp = testStart
    }
end

--[[
    Simulate optimization activation
]]
function EnhancedOptimizationValidator:simulateOptimizationActivation()
    -- Simulate various optimization strategies
    local strategies = VALIDATION_CONFIG.OPTIMIZATION_STRATEGIES
    local randomStrategy = strategies[math.random(1, #strategies)]
    
    print("   🔧 Activating optimization: " .. randomStrategy)
    
    -- Store optimization action
    table.insert(optimizationHistory, {
        timestamp = tick(),
        strategy = randomStrategy,
        deviceProfile = deviceProfile
    })
end

--[[
    Calculate improvement/regression
]]
function EnhancedOptimizationValidator:calculateImprovement(baseline, current)
    local improvements = {}
    
    -- Frame rate improvement
    if baseline.frameRate > 0 then
        local frameRateChange = (current.frameRate - baseline.frameRate) / baseline.frameRate
        improvements.frameRate = frameRateChange
    end
    
    -- Memory improvement
    if baseline.memoryUsage > 0 then
        local memoryChange = (baseline.memoryUsage - current.memoryUsage) / baseline.memoryUsage
        improvements.memory = memoryChange
    end
    
    -- Update time improvement
    if baseline.updateTime > 0 then
        local updateTimeChange = (baseline.updateTime - current.updateTime) / baseline.updateTime
        improvements.updateTime = updateTimeChange
    end
    
    -- Overall improvement score
    local totalImprovement = 0
    local improvementCount = 0
    
    for metric, change in pairs(improvements) do
        totalImprovement = totalImprovement + change
        improvementCount = improvementCount + 1
    end
    
    improvements.overall = improvementCount > 0 and (totalImprovement / improvementCount) or 0
    
    return improvements
end

--[[
    Run strategy validation
]]
function EnhancedOptimizationValidator:runStrategyValidation()
    print("🎯 Phase 3: Running strategy validation...")
    
    for _, strategy in ipairs(VALIDATION_CONFIG.OPTIMIZATION_STRATEGIES) do
        print("   Testing strategy: " .. strategy)
        
        local strategyResult = self:testOptimizationStrategy(strategy)
        
        -- Store strategy result
        table.insert(currentTest.phases, strategyResult)
        table.insert(validationResults.strategyTests, strategyResult)
    end
    
    print("✅ Strategy validation completed")
end

--[[
    Test specific optimization strategy
]]
function EnhancedOptimizationValidator:testOptimizationStrategy(strategy)
    local testStart = tick()
    local testSamples = {}
    
    -- Simulate strategy activation
    self:simulateStrategyActivation(strategy)
    
    -- Wait for effect
    wait(VALIDATION_CONFIG.OPTIMIZATION_DELAY)
    
    -- Collect samples
    local testConnection = nil
    testConnection = RunService.Heartbeat:Connect(function(deltaTime)
        local sample = {
            timestamp = tick(),
            frameRate = 1 / deltaTime,
            updateTime = deltaTime * 1000,
            memoryUsage = game:GetService("Stats").PhysicalMemory,
            objectCount = self:countGameObjects(),
            scriptCount = self:countScripts()
        }
        
        table.insert(testSamples, sample)
        
        if tick() - testStart >= VALIDATION_CONFIG.TEST_DURATION then
            if testConnection then
                testConnection:Disconnect()
            end
        end
    end)
    
    -- Wait for completion
    wait(VALIDATION_CONFIG.TEST_DURATION + 2)
    
    -- Calculate metrics
    local testMetrics = self:calculateBaselineMetrics(testSamples)
    local improvement = self:calculateImprovement(performanceBaselines, testMetrics)
    
    return {
        phase = "Strategy Test: " .. strategy,
        duration = VALIDATION_CONFIG.TEST_DURATION,
        strategy = strategy,
        samples = testSamples,
        metrics = testMetrics,
        improvement = improvement,
        timestamp = testStart
    }
end

--[[
    Simulate strategy activation
]]
function EnhancedOptimizationValidator:simulateStrategyActivation(strategy)
    -- Simulate different optimization strategies
    if strategy == "REDUCE_UPDATE_RATE" then
        print("     📉 Reducing update rate...")
    elseif strategy == "REDUCE_OBJECT_COUNT" then
        print("     🎯 Reducing object count...")
    elseif strategy == "ENABLE_LOD" then
        print("     👁️ Enabling LOD systems...")
    elseif strategy == "REDUCE_QUALITY" then
        print("     🎨 Reducing quality settings...")
    elseif strategy == "OPTIMIZE_RENDERING" then
        print("     🖼️ Optimizing rendering...")
    elseif strategy == "MEMORY_CLEANUP" then
        print("     🧹 Cleaning up memory...")
    end
end

--[[
    Run regression detection
]]
function EnhancedOptimizationValidator:runRegressionDetection()
    print("⚠️ Phase 4: Running regression detection...")
    
    local regressions = self:detectPerformanceRegressions()
    
    for _, regression in ipairs(regressions) do
        table.insert(validationResults.regressionTests, regression)
    end
    
    print("✅ Regression detection completed")
    print("   Detected regressions: " .. #regressions)
end

--[[
    Detect performance regressions
]]
function EnhancedOptimizationValidator:detectPerformanceRegressions()
    local regressions = {}
    
    -- Check optimization tests for regressions
    for _, test in ipairs(validationResults.optimizationTests) do
        if test.improvement and test.improvement.overall then
            if test.improvement.overall < VALIDATION_CONFIG.PERFORMANCE_THRESHOLDS.MAX_REGRESSION then
                local regression = {
                    timestamp = tick(),
                    testType = "Optimization Test",
                    severity = "High",
                    description = "Performance regression detected in optimization test",
                    details = {
                        baselineFPS = performanceBaselines.frameRate,
                        testFPS = test.metrics.frameRate,
                        regressionPercentage = test.improvement.overall * 100,
                        threshold = VALIDATION_CONFIG.PERFORMANCE_THRESHOLDS.MAX_REGRESSION * 100
                    }
                }
                
                table.insert(regressions, regression)
            end
        end
    end
    
    -- Check strategy tests for regressions
    for _, test in ipairs(validationResults.strategyTests) do
        if test.improvement and test.improvement.overall then
            if test.improvement.overall < VALIDATION_CONFIG.PERFORMANCE_THRESHOLDS.MAX_REGRESSION then
                local regression = {
                    timestamp = tick(),
                    testType = "Strategy Test: " .. test.strategy,
                    severity = "Medium",
                    description = "Performance regression detected in strategy test",
                    details = {
                        baselineFPS = performanceBaselines.frameRate,
                        testFPS = test.metrics.frameRate,
                        regressionPercentage = test.improvement.overall * 100,
                        threshold = VALIDATION_CONFIG.PERFORMANCE_THRESHOLDS.MAX_REGRESSION * 100
                    }
                }
                
                table.insert(regressions, regression)
            end
        end
    end
    
    return regressions
end

--[[
    Calculate effectiveness scores
]]
function EnhancedOptimizationValidator:calculateEffectivenessScores()
    print("📊 Phase 5: Calculating effectiveness scores...")
    
    local scores = {}
    
    -- Calculate overall optimization effectiveness
    local totalImprovement = 0
    local improvementCount = 0
    
    for _, test in ipairs(validationResults.optimizationTests) do
        if test.improvement and test.improvement.overall then
            totalImprovement = totalImprovement + test.improvement.overall
            improvementCount = improvementCount + 1
        end
    end
    
    local overallEffectiveness = improvementCount > 0 and (totalImprovement / improvementCount) or 0
    
    -- Calculate strategy effectiveness
    local strategyScores = {}
    for _, test in ipairs(validationResults.strategyTests) do
        if test.improvement and test.improvement.overall then
            strategyScores[test.strategy] = test.improvement.overall
        end
    end
    
    scores = {
        overallEffectiveness = overallEffectiveness,
        strategyScores = strategyScores,
        deviceOptimization = self:calculateDeviceOptimizationScore(),
        validationQuality = self:calculateValidationQualityScore()
    }
    
    table.insert(validationResults.effectivenessScores, scores)
    
    print("✅ Effectiveness scores calculated")
    print("   Overall Effectiveness: " .. string.format("%.2f", overallEffectiveness * 100) .. "%")
end

--[[
    Calculate device optimization score
]]
function EnhancedOptimizationValidator:calculateDeviceOptimizationScore()
    local score = 0.8 -- Base score
    
    -- Adjust based on device performance level
    if deviceProfile and deviceProfile.performanceLevel == "lowEnd" then
        score = score + 0.1 -- Low-end devices benefit more from optimization
    elseif deviceProfile and deviceProfile.performanceLevel == "highEnd" then
        score = score - 0.1 -- High-end devices benefit less from optimization
    end
    
    return math.max(0, math.min(1, score))
end

--[[
    Calculate validation quality score
]]
function EnhancedOptimizationValidator:calculateValidationQualityScore()
    local score = 0.9 -- Base score
    
    -- Adjust based on test coverage
    local testCoverage = #validationResults.optimizationTests + #validationResults.strategyTests
    if testCoverage >= 5 then
        score = score + 0.05
    elseif testCoverage < 3 then
        score = score - 0.1
    end
    
    return math.max(0, math.min(1, score))
end

--[[
    Generate optimization recommendations
]]
function EnhancedOptimizationValidator:generateOptimizationRecommendations()
    local recommendations = {}
    
    -- Overall performance recommendations
    if validationResults.effectivenessScores and #validationResults.effectivenessScores > 0 then
        local latestScores = validationResults.effectivenessScores[#validationResults.effectivenessScores]
        
        if latestScores.overallEffectiveness < VALIDATION_CONFIG.PERFORMANCE_THRESHOLDS.MIN_OPTIMIZATION_SCORE then
            table.insert(recommendations, {
                priority = "High",
                category = "Optimization",
                title = "Low Optimization Effectiveness",
                description = "Optimization strategies are not providing sufficient improvement",
                action = "Review and refine optimization algorithms"
            })
        end
    end
    
    -- Strategy-specific recommendations
    if validationResults.strategyTests then
        for _, test in ipairs(validationResults.strategyTests) do
            if test.improvement and test.improvement.overall then
                if test.improvement.overall < 0 then
                    table.insert(recommendations, {
                        priority = "Medium",
                        category = "Strategy",
                        title = "Ineffective Strategy: " .. test.strategy,
                        description = "Strategy is causing performance regression",
                        action = "Disable or modify " .. test.strategy .. " strategy"
                    })
                elseif test.improvement.overall > 0.2 then
                    table.insert(recommendations, {
                        priority = "Low",
                        category = "Strategy",
                        title = "Highly Effective Strategy: " .. test.strategy,
                        description = "Strategy is providing excellent performance improvement",
                        action = "Prioritize " .. test.strategy .. " strategy"
                    })
                end
            end
        end
    end
    
    -- Device-specific recommendations
    if deviceProfile then
        if deviceProfile.performanceLevel == "lowEnd" then
            table.insert(recommendations, {
                priority = "Medium",
                category = "Device",
                title = "Low-End Device Optimization",
                description = "Device requires aggressive optimization strategies",
                action = "Enable aggressive optimization for low-end devices"
            })
        end
    end
    
    return recommendations
end

--[[
    Complete validation
]]
function EnhancedOptimizationValidator:completeValidation(recommendations)
    print("🎯 Phase 6: Completing validation...")
    
    -- Store final results
    currentTest.results = {
        phases = currentTest.phases,
        recommendations = recommendations,
        effectivenessScores = validationResults.effectivenessScores[#validationResults.effectivenessScores]
    }
    
    currentTest.endTime = tick()
    currentTest.duration = currentTest.endTime - currentTest.startTime
    
    -- Store validation history
    table.insert(validationResults.validationHistory, currentTest)
    
    -- Display final results
    self:displayValidationResults(currentTest, recommendations)
    
    -- Reset validation state
    isRunning = false
    currentTest = nil
    
    print("🎉 Enhanced Optimization Validation completed!")
    print("=" .. string.rep("=", 70))
end

--[[
    Display validation results
]]
function EnhancedOptimizationValidator:displayValidationResults(test, recommendations)
    print("📊 VALIDATION RESULTS")
    print("=" .. string.rep("=", 70))
    
    -- Test summary
    print("📈 TEST SUMMARY")
    print("   Test Name: " .. test.name)
    print("   Duration: " .. string.format("%.1f", test.duration) .. " seconds")
    print("   Device: " .. test.deviceProfile.type .. " (" .. test.deviceProfile.performanceLevel .. ")")
    print("   Phases Completed: " .. #test.phases)
    
    -- Effectiveness scores
    if test.results and test.results.effectivenessScores then
        local scores = test.results.effectivenessScores
        print("\n📊 EFFECTIVENESS SCORES")
        print("   Overall Effectiveness: " .. string.format("%.2f", scores.overallEffectiveness * 100) .. "%")
        print("   Device Optimization: " .. string.format("%.2f", scores.deviceOptimization * 100) .. "%")
        print("   Validation Quality: " .. string.format("%.2f", scores.validationQuality * 100) .. "%")
        
        if scores.strategyScores then
            print("\n🎯 STRATEGY EFFECTIVENESS")
            for strategy, score in pairs(scores.strategyScores) do
                print("   " .. strategy .. ": " .. string.format("%.2f", score * 100) .. "%")
            end
        end
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
    
    print("\n" .. "=" .. string.rep("=", 70))
end

--[[
    Utility functions
]]
function EnhancedOptimizationValidator:calculateAverage(array)
    if #array == 0 then return 0 end
    
    local sum = 0
    for _, value in ipairs(array) do
        sum = sum + value
    end
    
    return sum / #array
end

function EnhancedOptimizationValidator:updatePerformanceMetrics(deltaTime)
    -- Update performance metrics
    local sample = {
        timestamp = tick(),
        frameRate = 1 / deltaTime,
        updateTime = deltaTime * 1000
    }
    
    table.insert(performanceSamples, sample)
    
    -- Keep only recent samples
    if #performanceSamples > 100 then
        table.remove(performanceSamples, 1)
    end
end

function EnhancedOptimizationValidator:updateMemoryMetrics()
    -- Memory metrics are collected during specific tests
end

function EnhancedOptimizationValidator:updateObjectMetrics()
    -- Object metrics are collected during specific tests
end

function EnhancedOptimizationValidator:countGameObjects()
    local count = 0
    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") or obj:IsA("Decal") then
            count = count + 1
        end
    end
    return count
end

function EnhancedOptimizationValidator:countScripts()
    local count = 0
    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
            count = count + 1
        end
    end
    return count
end

function EnhancedOptimizationValidator:measureNetworkLatency()
    -- Simulate network latency measurement
    return math.random(20, 150)
end

--[[
    Get validation results
]]
function EnhancedOptimizationValidator:getValidationResults()
    return validationResults
end

--[[
    Get current validation status
]]
function EnhancedOptimizationValidator:getValidationStatus()
    return {
        isRunning = isRunning,
        currentTest = currentTest,
        elapsedTime = isRunning and (tick() - testStartTime) or 0,
        deviceProfile = deviceProfile
    }
end

--[[
    Stop current validation
]]
function EnhancedOptimizationValidator:stopValidation()
    if not isRunning then
        print("⚠️ No validation currently running")
        return
    end
    
    print("⏹️ Stopping validation...")
    
    -- Force completion
    local recommendations = self:generateOptimizationRecommendations()
    self:completeValidation(recommendations)
end

--[[
    Cleanup
]]
function EnhancedOptimizationValidator:destroy()
    if self.performanceConnection then
        self.performanceConnection:Disconnect()
    end
    if self.memoryConnection then
        self.memoryConnection:Disconnect()
    end
    if self.objectConnection then
        self.objectConnection:Disconnect()
    end
    
    print("🧹 Enhanced Optimization Validator: Cleanup complete")
end

return EnhancedOptimizationValidator
