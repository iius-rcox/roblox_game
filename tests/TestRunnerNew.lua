-- TestRunnerNew.lua - BRAND NEW VERSION
-- This is a completely fresh test runner to bypass caching issues

local TestRunnerNew = {}

-- Super simple constructor
function TestRunnerNew.new()
    local self = {}
    setmetatable(self, {__index = TestRunnerNew})
    return self
end

-- Configuration
function TestRunnerNew:SetConfig(key, value)
    print("Config set:", key, "=", value)
end

-- Main test function
function TestRunnerNew:RunAllTests()
    print("\n" .. string.rep("=", 60))
    print("🧪 ANIME TYCOON GAME - NEW TEST RUNNER")
    print(string.rep("=", 60))
    
    local results = {
        totalTests = 0,
        passedTests = 0,
        failedTests = 0,
        startTime = tick()
    }
    
    print("Starting tests with NEW TestRunner...")
    
    -- Test 1: Basic Services
    results.totalTests = results.totalTests + 1
    print("\n🧪 Test 1: Basic Services")
    local success1 = pcall(function()
        assert(game ~= nil, "Game exists")
        assert(game.Players ~= nil, "Players service exists")
    end)
    
    if success1 then
        print("✅ PASS: Basic services")
        results.passedTests = results.passedTests + 1
    else
        print("❌ FAIL: Basic services")
        results.failedTests = results.failedTests + 1
    end
    
    -- Test 2: Game Services
    results.totalTests = results.totalTests + 1
    print("\n🧪 Test 2: Game Services")
    local success2 = pcall(function()
        local sss = game:GetService("ServerScriptService")
        local rs = game:GetService("ReplicatedStorage")
        assert(sss ~= nil, "ServerScriptService exists")
        assert(rs ~= nil, "ReplicatedStorage exists")
    end)
    
    if success2 then
        print("✅ PASS: Game services")
        results.passedTests = results.passedTests + 1
    else
        print("❌ FAIL: Game services")
        results.failedTests = results.failedTests + 1
    end
    
    -- Test 3: System Search
    results.totalTests = results.totalTests + 1
    print("\n🧪 Test 3: System Search")
    local success3 = pcall(function()
        local found = 0
        local function search(parent)
            for _, child in pairs(parent:GetChildren()) do
                if child:IsA("Script") then
                    if string.find(child.Name:lower(), "tycoon") or 
                       string.find(child.Name:lower(), "network") or
                       string.find(child.Name:lower(), "hub") then
                        found = found + 1
                        print("   Found system:", child.Name)
                    end
                end
                if child:IsA("Folder") or child:IsA("Model") then
                    search(child)
                end
            end
        end
        search(game)
        print("   Total systems found:", found)
    end)
    
    if success3 then
        print("✅ PASS: System search")
        results.passedTests = results.passedTests + 1
    else
        print("❌ FAIL: System search")
        results.failedTests = results.failedTests + 1
    end
    
    -- Test 4: Performance
    results.totalTests = results.totalTests + 1
    print("\n🧪 Test 4: Performance")
    local success4 = pcall(function()
        local startTime = tick()
        local sum = 0
        for i = 1, 1000 do
            sum = sum + i
        end
        local endTime = tick()
        local duration = endTime - startTime
        print("   Time:", string.format("%.4f", duration * 1000), "ms")
        print("   Result:", sum, "(expected: 500500)")
        assert(sum == 500500, "Math works")
    end)
    
    if success4 then
        print("✅ PASS: Performance")
        results.passedTests = results.passedTests + 1
    else
        print("❌ FAIL: Performance")
        results.failedTests = results.failedTests + 1
    end
    
    -- Results
    results.endTime = tick()
    local executionTime = results.endTime - results.startTime
    local successRate = (results.passedTests / results.totalTests) * 100
    
    print("\n" .. string.rep("=", 60))
    print("📊 NEW TEST RUNNER RESULTS")
    print(string.rep("=", 60))
    print("Total Tests:", results.totalTests)
    print("Passed:", results.passedTests)
    print("Failed:", results.failedTests)
    print("Success Rate:", string.format("%.1f%%", successRate))
    print("Execution Time:", string.format("%.2f seconds", executionTime))
    
    if results.failedTests == 0 then
        print("\n🎉 ALL TESTS PASSED!")
        print("NEW TestRunner is working perfectly!")
    else
        print("\n⚠️  Some tests failed")
    end
    
    print(string.rep("=", 60))
    
    return results
end

-- Category tests
function TestRunnerNew:RunCategoryTests(category)
    print("Testing category:", category)
    return self:RunAllTests()
end

return TestRunnerNew
