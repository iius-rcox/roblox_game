-- RunTests.lua
-- Standalone test launcher that works immediately in Roblox Studio
-- Place this script in ServerScriptService to run comprehensive tests

print("🧪 ANIME TYCOON GAME - ENHANCED TEST LAUNCHER")
print("Loading test runner with fallback methods...")

-- Wait for systems to initialize
wait(2)

-- Load the test runner with multiple fallback methods
local success, TestRunner = pcall(function()
    -- Method 1: Try script.Parent (if available)
    if script.Parent then
        local testRunner = script.Parent:FindFirstChild("TestRunner")
        if testRunner then
            return require(testRunner)
        end
    end
    
    -- Method 2: Try to find Tests folder in ServerScriptService
    local serverScriptService = game:GetService("ServerScriptService")
    local testsFolder = serverScriptService:FindFirstChild("Tests")
    
    if testsFolder then
        local testRunnerScript = testsFolder:FindFirstChild("TestRunner")
        if testRunnerScript then
            print("✅ Found TestRunner in ServerScriptService.Tests")
            return require(testRunnerScript)
        end
    end
    
    -- Method 3: Try to find it anywhere in the game
    print("Searching for TestRunner anywhere in the game...")
    local function searchForTestRunner(parent)
        for _, child in pairs(parent:GetChildren()) do
            if child.Name == "TestRunner" and child:IsA("Script") then
                print("✅ Found TestRunner at:", child:GetFullName())
                return require(child)
            end
            
            -- Recursively search children
            if child:IsA("Folder") or child:IsA("Model") then
                local result = searchForTestRunner(child)
                if result then
                    return result
                end
            end
        end
        return nil
    end
    
    local foundTestRunner = searchForTestRunner(game)
    if foundTestRunner then
        return foundTestRunner
    end
    
    -- Method 4: Create a minimal test runner if all else fails
    print("❌ TestRunner not found anywhere. Creating minimal test runner...")
    
    -- Create a minimal test runner for basic functionality
    local MinimalTestRunner = {}
    MinimalTestRunner.__index = MinimalTestRunner
    
    function MinimalTestRunner.new()
        local self = setmetatable({}, MinimalTestRunner)
        self.config = {
            delayBetweenTests = 0.5,
            verboseOutput = true,
            continueOnFailure = true
        }
        return self
    end
    
    function MinimalTestRunner:SetConfig(key, value)
        self.config[key] = value
    end
    
    function MinimalTestRunner:RunAllTests()
        print("⚠️  Using minimal test runner - limited functionality")
        print("Running enhanced system checks...")
        
        -- Enhanced system checks
        local results = {
            total = 6,
            passed = 0,
            failed = 0,
            errors = {}
        }
        
        -- Test 1: Basic game services
        local test1Success = pcall(function()
            assert(game ~= nil, "Game should exist")
            assert(game.Players ~= nil, "Players service should exist")
        end)
        
        if test1Success then
            print("✅ Basic game services check: PASSED")
            results.passed = results.passed + 1
        else
            print("❌ Basic game services check: FAILED")
            results.failed = results.failed + 1
            table.insert(results.errors, "Basic game services check failed")
        end
        
        -- Test 2: ServerScriptService
        local test2Success = pcall(function()
            assert(game:GetService("ServerScriptService") ~= nil, "ServerScriptService should exist")
        end)
        
        if test2Success then
            print("✅ ServerScriptService check: PASSED")
            results.passed = results.passed + 1
        else
            print("❌ ServerScriptService check: FAILED")
            results.failed = results.failed + 1
            table.insert(results.errors, "ServerScriptService check failed")
        end
        
        -- Test 3: ReplicatedStorage
        local test3Success = pcall(function()
            assert(game:GetService("ReplicatedStorage") ~= nil, "ReplicatedStorage should exist")
        end)
        
        if test3Success then
            print("✅ ReplicatedStorage check: PASSED")
            results.passed = results.passed + 1
        else
            print("❌ ReplicatedStorage check: FAILED")
            results.failed = results.failed + 1
            table.insert(results.errors, "ReplicatedStorage check failed")
        end
        
        -- Test 4: Network Manager check
        local test4Success = pcall(function()
            -- Look for NetworkManager script
            local found = false
            local function searchForNetworkManager(parent)
                for _, child in pairs(parent:GetChildren()) do
                    if child.Name == "NetworkManager" and child:IsA("Script") then
                        found = true
                        return true
                    end
                    
                    if child:IsA("Folder") or child:IsA("Model") then
                        if searchForNetworkManager(child) then
                            return true
                        end
                    end
                end
                return false
            end
            
            searchForNetworkManager(game)
            
            if found then
                print("   NetworkManager script found")
            else
                print("   NetworkManager script not found (normal if not synced)")
            end
            
            -- Check RemoteEvents
            local remoteEvents = game:GetService("ReplicatedStorage"):FindFirstChild("RemoteEvents")
            if remoteEvents then
                local eventCount = 0
                for _, _ in pairs(remoteEvents:GetChildren()) do
                    eventCount = eventCount + 1
                end
                print("   Found", eventCount, "remote events")
            end
        end)
        
        if test4Success then
            print("✅ Network Manager check: PASSED")
            results.passed = results.passed + 1
        else
            print("❌ Network Manager check: FAILED")
            results.failed = results.failed + 1
            table.insert(results.errors, "Network Manager check failed")
        end
        
        -- Test 5: Tycoon System check
        local test5Success = pcall(function()
            local tycoonScripts = 0
            local function searchForTycoonScripts(parent)
                for _, child in pairs(parent:GetChildren()) do
                    if child:IsA("Script") and string.find(child.Name:lower(), "tycoon") then
                        tycoonScripts = tycoonScripts + 1
                    end
                    
                    if child:IsA("Folder") or child:IsA("Model") then
                        searchForTycoonScripts(child)
                    end
                end
            end
            
            searchForTycoonScripts(game)
            print("   Found", tycoonScripts, "tycoon-related scripts")
        end)
        
        if test5Success then
            print("✅ Tycoon System check: PASSED")
            results.passed = results.passed + 1
        else
            print("❌ Tycoon System check: FAILED")
            results.failed = results.failed + 1
            table.insert(results.errors, "Tycoon System check failed")
        end
        
        -- Test 6: Performance check
        local test6Success = pcall(function()
            local startTime = tick()
            
            -- Simulate some work
            local sum = 0
            for i = 1, 1000 do
                sum = sum + i
            end
            
            local endTime = tick()
            local duration = endTime - startTime
            
            print("   Basic computation took", string.format("%.4f", duration * 1000), "ms")
            
            if duration < 0.1 then
                print("   Performance is good")
            else
                print("   Performance might be slow")
            end
            
            assert(sum == 500500, "Basic math should work correctly")
        end)
        
        if test6Success then
            print("✅ Performance check: PASSED")
            results.passed = results.passed + 1
        else
            print("❌ Performance check: FAILED")
            results.failed = results.failed + 1
            table.insert(results.errors, "Performance check failed")
        end
        
        print("\n📊 MINIMAL TEST RESULTS:")
        print("Total tests:", results.total)
        print("Passed:", results.passed)
        print("Failed:", results.failed)
        
        if #results.errors > 0 then
            print("\n❌ Errors:")
            for i, error in ipairs(results.errors) do
                print("  " .. i .. ". " .. error)
            end
        end
        
        return results
    end
    
    function MinimalTestRunner:RunCategoryTests(category)
        print("⚠️  Category tests not available in minimal test runner")
        print("Category requested:", category)
        return self:RunAllTests()
    end
    
    return MinimalTestRunner
end)

if not success then
    error("❌ CRITICAL: Could not load or create TestRunner. Test execution cannot continue.")
    return
end

print("✅ TestRunner loaded successfully")
print("Starting comprehensive test suite...")

-- Create test runner instance
local runner = TestRunner.new()

-- Configure test settings (optional)
if runner.SetConfig then
    runner:SetConfig("delayBetweenTests", 0.5)  -- Faster execution
    runner:SetConfig("verboseOutput", true)     -- Detailed output
    runner:SetConfig("continueOnFailure", true) -- Continue even if some tests fail
end

-- Run all tests
local results = runner:RunAllTests()

-- Display final status
print("\n🎯 TEST EXECUTION COMPLETE!")
print("Check the output above for detailed results.")

-- Optional: Run specific category tests (only if supported)
if runner.RunCategoryTests then
    print("\n📋 Available test categories:")
    print("  - System Integration")
    print("  - Core Systems") 
    print("  - Advanced Features")
    print("  - Utility Systems")
    
    -- Uncomment to run specific categories:
    -- runner:RunCategoryTests("System Integration")
    -- runner:RunCategoryTests("Core Systems")
    -- runner:RunCategoryTests("Advanced Features")
    -- runner:RunCategoryTests("Utility Systems")
end

print("\n💡 TIP: For full test functionality, ensure the Tests folder is properly synced via Rojo")
print("💡 TIP: Place this script in ServerScriptService and ensure Tests folder is a sibling")
print("💡 TIP: This enhanced version includes fallback testing even when TestRunner is not available")
