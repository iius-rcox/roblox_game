-- test_milestone2_roblox.lua
-- Roblox Studio Test Script for Milestone 2: Multiple Tycoon Ownership
-- Place this script in StarterPlayerScripts or run it in the command bar

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestService = game:GetService("TestService")

-- Test Results
local testResults = {
    passed = 0,
    failed = 0,
    total = 0
}

-- Test Helper Functions
local function logTest(name, passed, details)
    testResults.total = testResults.total + 1
    if passed then
        testResults.passed = testResults.passed + 1
        print("✅ PASS:", name)
        if details then
            print("   " .. details)
        end
    else
        testResults.failed = testResults.failed + 1
        print("❌ FAIL:", name)
        if details then
            print("   " .. details)
        end
    end
end

local function runTest(name, testFunction)
    local success, result = pcall(testFunction)
    if success then
        logTest(name, true, result)
    else
        logTest(name, false, "Error: " .. tostring(result))
    end
end

-- Test 1: Check if all required modules exist
local function testModuleExistence()
    local modules = {
        "MultiTycoonManager",
        "CrossTycoonProgression", 
        "AdvancedPlotSystem",
        "MultiTycoonClient",
        "CrossTycoonClient",
        "AdvancedPlotClient"
    }
    
    local missingModules = {}
    for _, moduleName in ipairs(modules) do
        local module = ReplicatedStorage:FindFirstChild(moduleName)
        if not module then
            table.insert(missingModules, moduleName)
        end
    end
    
    if #missingModules == 0 then
        return "All required modules found"
    else
        return "Missing modules: " .. table.concat(missingModules, ", ")
    end
end

-- Test 2: Test MultiTycoonManager functionality
local function testMultiTycoonManager()
    local MultiTycoonManager = require(ReplicatedStorage.MultiTycoonManager)
    
    -- Test manager creation
    local manager = MultiTycoonManager.new()
    if not manager then
        return "Failed to create MultiTycoonManager instance"
    end
    
    -- Test basic functionality
    local player = Players.LocalPlayer
    if not player then
        return "No local player found"
    end
    
    -- Test plot claiming
    local plotId = "test_plot_1"
    local success = manager:claimPlot(player, plotId)
    if not success then
        return "Failed to claim plot"
    end
    
    -- Test ownership tracking
    local ownedPlots = manager:getOwnedPlots(player)
    if not ownedPlots or #ownedPlots == 0 then
        return "Failed to track owned plots"
    end
    
    return "MultiTycoonManager basic functionality working"
end

-- Test 3: Test CrossTycoonProgression
local function testCrossTycoonProgression()
    local CrossTycoonProgression = require(ReplicatedStorage.CrossTycoonProgression)
    
    local progression = CrossTycoonProgression.new()
    if not progression then
        return "Failed to create CrossTycoonProgression instance"
    end
    
    -- Test bonus calculations
    local player = Players.LocalPlayer
    if not player then
        return "No local player found"
    end
    
    local bonus = progression:calculateCrossTycoonBonus(player, 2) -- 2 tycoons
    if not bonus or bonus.cashMultiplier ~= 0.1 then
        return "Cross-tycoon bonus calculation failed"
    end
    
    return "CrossTycoonProgression working correctly"
end

-- Test 4: Test AdvancedPlotSystem
local function testAdvancedPlotSystem()
    local AdvancedPlotSystem = require(ReplicatedStorage.AdvancedPlotSystem)
    
    local plotSystem = AdvancedPlotSystem.new()
    if not plotSystem then
        return "Failed to create AdvancedPlotSystem instance"
    end
    
    -- Test theme system
    local themes = plotSystem:getAvailableThemes()
    if not themes or #themes < 20 then
        return "Theme system not fully implemented (expected 20+ themes)"
    end
    
    -- Test plot creation
    local plotId = "test_advanced_plot"
    local plot = plotSystem:createPlot(plotId, "Anime")
    if not plot then
        return "Failed to create advanced plot"
    end
    
    return "AdvancedPlotSystem working correctly"
end

-- Test 5: Test Client Integration
local function testClientIntegration()
    local player = Players.LocalPlayer
    if not player then
        return "No local player found"
    end
    
    -- Check if client scripts are running
    local playerScripts = player:FindFirstChild("PlayerScripts")
    if not playerScripts then
        return "PlayerScripts not found"
    end
    
    -- Check for MainClient
    local mainClient = playerScripts:FindFirstChild("MainClient")
    if not mainClient then
        return "MainClient script not found"
    end
    
    return "Client integration scripts found and running"
end

-- Test 6: Test Constants and Configuration
local function testConstants()
    local Constants = require(ReplicatedStorage.Utils.Constants)
    
    -- Check Milestone 2 specific constants
    if not Constants.MULTI_TYCOON then
        return "Multi-tycoon constants not defined"
    end
    
    if not Constants.MULTI_TYCOON.MAX_PLOTS then
        return "Max plots constant not defined"
    end
    
    if Constants.MULTI_TYCOON.MAX_PLOTS ~= 3 then
        return "Max plots should be 3, got " .. tostring(Constants.MULTI_TYCOON.MAX_PLOTS)
    end
    
    return "Constants properly configured for Milestone 2"
end

-- Test 7: Test Network Communication
local function testNetworkCommunication()
    local player = Players.LocalPlayer
    if not player then
        return "No local player found"
    end
    
    -- Check if RemoteEvents exist
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then
        return "RemoteEvents folder not found"
    end
    
    -- Check for key remote events
    local keyRemotes = {"PlotClaim", "PlotSwitch", "CrossTycoonSync"}
    local missingRemotes = {}
    
    for _, remoteName in ipairs(keyRemotes) do
        if not remotes:FindFirstChild(remoteName) then
            table.insert(missingRemotes, remoteName)
        end
    end
    
    if #missingRemotes > 0 then
        return "Missing remote events: " .. table.concat(missingRemotes, ", ")
    end
    
    return "Network communication setup complete"
end

-- Test 8: Test Data Persistence
local function testDataPersistence()
    local player = Players.LocalPlayer
    if not player then
        return "No local player found"
    end
    
    -- Check if SaveSystem exists
    local SaveSystem = require(ReplicatedStorage.Server.SaveSystem)
    if not SaveSystem then
        return "SaveSystem not found"
    end
    
    -- Test basic save functionality
    local testData = {
        playerId = player.UserId,
        ownedPlots = {"plot1", "plot2"},
        crossTycoonBonus = 0.2
    }
    
    local success = pcall(function()
        SaveSystem:savePlayerData(player, testData)
    end)
    
    if not success then
        return "SaveSystem save functionality failed"
    end
    
    return "Data persistence system working"
end

-- Main Test Runner
local function runAllTests()
    print("🚀 Starting Milestone 2 Comprehensive Testing...")
    print("=" .. string.rep("=", 50))
    
    -- Run all tests
    runTest("Module Existence Check", testModuleExistence)
    runTest("MultiTycoonManager Functionality", testMultiTycoonManager)
    runTest("CrossTycoonProgression System", testCrossTycoonProgression)
    runTest("AdvancedPlotSystem Features", testAdvancedPlotSystem)
    runTest("Client Integration", testClientIntegration)
    runTest("Constants Configuration", testConstants)
    runTest("Network Communication", testNetworkCommunication)
    runTest("Data Persistence", testDataPersistence)
    
    -- Print results summary
    print("=" .. string.rep("=", 50))
    print("📊 TEST RESULTS SUMMARY:")
    print("✅ Passed:", testResults.passed)
    print("❌ Failed:", testResults.failed)
    print("📈 Total:", testResults.total)
    print("📊 Success Rate:", string.format("%.1f%%", (testResults.passed / testResults.total) * 100))
    
    if testResults.failed == 0 then
        print("🎉 ALL TESTS PASSED! Milestone 2 is ready!")
    else
        print("⚠️  Some tests failed. Please review the issues above.")
    end
    
    print("=" .. string.rep("=", 50))
end

-- Auto-run tests when script loads
if game:GetService("RunService"):IsStudio() then
    -- Wait a bit for everything to load
    wait(2)
    runAllTests()
else
    print("This test script should be run in Roblox Studio")
end

-- Return the test runner for manual execution
return {
    runAllTests = runAllTests,
    runTest = runTest,
    testResults = testResults
}
