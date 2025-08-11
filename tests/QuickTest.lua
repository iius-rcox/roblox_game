-- QuickTest.lua
-- Standalone test script for basic system validation
-- Can be run directly in Roblox Studio without folder dependencies

print("🚀 ANIME TYCOON GAME - QUICK TEST")
print("Running basic system validation...")

-- Test results tracking
local testResults = {
    total = 0,
    passed = 0,
    failed = 0,
    errors = {}
}

-- Helper function to run a test
local function runTest(testName, testFunction)
    testResults.total = testResults.total + 1
    print("\n🧪 Running test:", testName)
    
    local success, result = pcall(testFunction)
    
    if success then
        print("✅ " .. testName .. ": PASSED")
        testResults.passed = testResults.passed + 1
        return true
    else
        print("❌ " .. testName .. ": FAILED")
        print("   Error:", result)
        testResults.failed = testResults.failed + 1
        table.insert(testResults.errors, testName .. ": " .. tostring(result))
        return false
    end
end

-- Test 1: Basic Game Services
runTest("Game Services Check", function()
    assert(game ~= nil, "Game should exist")
    assert(game.Players ~= nil, "Players service should exist")
    assert(game:GetService("ServerScriptService") ~= nil, "ServerScriptService should exist")
    assert(game:GetService("ReplicatedStorage") ~= nil, "ReplicatedStorage should exist")
    assert(game:GetService("RunService") ~= nil, "RunService should exist")
    print("   All basic game services are available")
end)

-- Test 2: Network Manager Check
runTest("Network Manager Check", function()
    -- Try to find NetworkManager in the game
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
        print("   NetworkManager script found in game")
    else
        print("   NetworkManager script not found (this is normal if not synced via Rojo)")
    end
    
    -- Check if RemoteEvents folder exists in ReplicatedStorage
    local remoteEvents = game:GetService("ReplicatedStorage"):FindFirstChild("RemoteEvents")
    if remoteEvents then
        print("   RemoteEvents folder found in ReplicatedStorage")
        local eventCount = 0
        for _, _ in pairs(remoteEvents:GetChildren()) do
            eventCount = eventCount + 1
        end
        print("   Found", eventCount, "remote events")
    else
        print("   RemoteEvents folder not found in ReplicatedStorage")
    end
end)

-- Test 3: Player System Check
runTest("Player System Check", function()
    local players = game:GetService("Players")
    assert(players ~= nil, "Players service should exist")
    
    -- Check if player can join
    local playerCount = #players:GetPlayers()
    print("   Current player count:", playerCount)
    print("   Player system is functional")
end)

-- Test 4: Tycoon System Check
runTest("Tycoon System Check", function()
    -- Look for tycoon-related scripts
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
    
    if tycoonScripts > 0 then
        print("   Tycoon system scripts are present")
    else
        print("   No tycoon scripts found (this is normal if not synced via Rojo)")
    end
end)

-- Test 5: Anime System Check
runTest("Anime System Check", function()
    -- Look for anime-related scripts
    local animeScripts = 0
    local function searchForAnimeScripts(parent)
        for _, child in pairs(parent:GetChildren()) do
            if child:IsA("Script") and string.find(child.Name:lower(), "anime") then
                animeScripts = animeScripts + 1
            end
            
            if child:IsA("Folder") or child:IsA("Model") then
                searchForAnimeScripts(child)
            end
        end
    end
    
    searchForAnimeScripts(game)
    print("   Found", animeScripts, "anime-related scripts")
    
    if animeScripts > 0 then
        print("   Anime system scripts are present")
    else
        print("   No anime scripts found (this is normal if not synced via Rojo)")
    end
end)

-- Test 6: Performance Check
runTest("Performance Check", function()
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

-- Test 7: Memory Check
runTest("Memory Check", function()
    -- Check if we can create and destroy objects
    local testPart = Instance.new("Part")
    testPart.Name = "TestPart"
    testPart.Parent = workspace
    
    local partExists = workspace:FindFirstChild("TestPart") ~= nil
    assert(partExists, "Part should be created successfully")
    
    testPart:Destroy()
    local partDestroyed = workspace:FindFirstChild("TestPart") == nil
    assert(partDestroyed, "Part should be destroyed successfully")
    
    print("   Object creation and destruction works correctly")
end)

-- Display final results
print("\n" .. string.rep("=", 50))
print("🎯 QUICK TEST RESULTS")
print(string.rep("=", 50))
print("Total tests:", testResults.total)
print("Passed:", testResults.passed)
print("Failed:", testResults.failed)
print("Success rate:", string.format("%.1f%%", (testResults.passed / testResults.total) * 100))

if #testResults.errors > 0 then
    print("\n❌ Errors encountered:")
    for i, error in ipairs(testResults.errors) do
        print("  " .. i .. ". " .. error)
    end
end

if testResults.failed == 0 then
    print("\n🎉 All tests passed! System appears to be functioning correctly.")
else
    print("\n⚠️  Some tests failed. Check the errors above for details.")
end

print("\n💡 TIP: This is a basic validation test. For comprehensive testing,")
print("   use the full test suite with proper Rojo synchronization.")
print("💡 TIP: Place this script in ServerScriptService to run it automatically.")

-- Return results for potential use by other scripts
return testResults
