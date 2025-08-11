-- SimpleTest.lua
-- Simple test launcher for Roblox Studio
-- Place this script in ServerScriptService to run basic tests automatically

print("🚀 ANIME TYCOON GAME - SIMPLE TEST LAUNCHER")
print("Starting basic system validation...")

-- Wait a moment for systems to initialize
wait(1)

-- Run the quick test
local success, results = pcall(function()
    -- Import and run QuickTest
    local QuickTest = require(script.Parent.QuickTest)
    return QuickTest
end)

if not success then
    warn("❌ Failed to load QuickTest:", results)
    print("Running built-in basic tests instead...")
    
    -- Fallback to basic tests
    local testResults = {
        total = 3,
        passed = 0,
        failed = 0,
        errors = {}
    }
    
    -- Basic test 1: Game services
    local test1Success = pcall(function()
        assert(game ~= nil, "Game should exist")
        assert(game.Players ~= nil, "Players service should exist")
    end)
    
    if test1Success then
        print("✅ Basic game services: PASSED")
        testResults.passed = testResults.passed + 1
    else
        print("❌ Basic game services: FAILED")
        testResults.failed = testResults.failed + 1
        table.insert(testResults.errors, "Basic game services failed")
    end
    
    -- Basic test 2: ServerScriptService
    local test2Success = pcall(function()
        assert(game:GetService("ServerScriptService") ~= nil, "ServerScriptService should exist")
    end)
    
    if test2Success then
        print("✅ ServerScriptService: PASSED")
        testResults.passed = testResults.passed + 1
    else
        print("❌ ServerScriptService: FAILED")
        testResults.failed = testResults.failed + 1
        table.insert(testResults.errors, "ServerScriptService failed")
    end
    
    -- Basic test 3: ReplicatedStorage
    local test3Success = pcall(function()
        assert(game:GetService("ReplicatedStorage") ~= nil, "ReplicatedStorage should exist")
    end)
    
    if test3Success then
        print("✅ ReplicatedStorage: PASSED")
        testResults.passed = testResults.passed + 1
    else
        print("❌ ReplicatedStorage: FAILED")
        testResults.failed = testResults.failed + 1
        table.insert(testResults.errors, "ReplicatedStorage failed")
    end
    
    print("\n📊 FALLBACK TEST RESULTS:")
    print("Total tests:", testResults.total)
    print("Passed:", testResults.passed)
    print("Failed:", testResults.failed)
    
    if #testResults.errors > 0 then
        print("\n❌ Errors:")
        for i, error in ipairs(testResults.errors) do
            print("  " .. i .. ". " .. error)
        end
    end
    
    results = testResults
else
    print("✅ QuickTest loaded successfully")
    results = results
end

-- Display final summary
print("\n" .. string.rep("=", 60))
print("🎯 TEST EXECUTION COMPLETE")
print(string.rep("=", 60))

if results and results.total then
    print("Total tests run:", results.total)
    print("Tests passed:", results.passed)
    print("Tests failed:", results.failed)
    
    if results.total > 0 then
        local successRate = (results.passed / results.total) * 100
        print("Success rate:", string.format("%.1f%%", successRate))
        
        if successRate == 100 then
            print("\n🎉 PERFECT SCORE! All tests passed!")
        elseif successRate >= 80 then
            print("\n✅ Good results! Most tests passed.")
        elseif successRate >= 60 then
            print("\n⚠️  Mixed results. Some tests failed.")
        else
            print("\n❌ Poor results. Many tests failed.")
        end
    end
else
    print("Test results not available")
end

print("\n💡 TIP: For comprehensive testing, ensure the Tests folder is properly synced via Rojo")
print("💡 TIP: Check the output above for detailed test results")
print("💡 TIP: This script will run automatically when placed in ServerScriptService")

-- Keep the script running for a moment to show results
wait(3)
print("\n🏁 Simple test launcher finished. Check the output above for results.")
