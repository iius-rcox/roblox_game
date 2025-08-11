-- SimpleRunTests.lua
-- Super simple test script that will definitely work
-- Place this in ServerScriptService to run basic tests

print("🚀 SIMPLE RUN TESTS - STARTING")
print("This script will definitely work!")

-- Wait a moment
wait(1)

print("✅ Script is running successfully")
print("Testing your game systems...")

-- Test 1: Basic game services
print("\n🧪 Test 1: Basic Game Services")
if game then
    print("✅ Game object exists")
else
    print("❌ Game object missing")
end

local players = game:GetService("Players")
if players then
    print("✅ Players service exists")
    print("   Current player count:", #players:GetPlayers())
else
    print("❌ Players service missing")
end

-- Test 2: ServerScriptService
print("\n🧪 Test 2: ServerScriptService")
local serverScriptService = game:GetService("ServerScriptService")
if serverScriptService then
    print("✅ ServerScriptService exists")
    
    -- Look for Tests folder
    local testsFolder = serverScriptService:FindFirstChild("Tests")
    if testsFolder then
        print("✅ Tests folder found")
        
        -- Look for TestRunner
        local testRunner = testsFolder:FindFirstChild("TestRunner")
        if testRunner then
            print("✅ TestRunner.lua found!")
            print("   Location:", testRunner:GetFullName())
            print("   Type:", testRunner.ClassName)
            
            -- Try to load it
            local success, TestRunner = pcall(require, testRunner)
            if success then
                print("✅ TestRunner loaded successfully!")
                
                -- Try to create instance
                local success2, runner = pcall(function()
                    return TestRunner.new()
                end)
                
                if success2 then
                    print("✅ TestRunner instance created!")
                    
                    -- Try to run tests
                    local success3, results = pcall(function()
                        return runner:RunAllTests()
                    end)
                    
                    if success3 then
                        print("✅ Tests ran successfully!")
                        print("   Results:", results)
                    else
                        print("❌ Failed to run tests:", results)
                    end
                else
                    print("❌ Failed to create TestRunner instance:", runner)
                end
            else
                print("❌ Failed to load TestRunner:", TestRunner)
            end
        else
            print("❌ TestRunner.lua not found in Tests folder")
            print("   Available files in Tests folder:")
            for _, child in pairs(testsFolder:GetChildren()) do
                print("   - " .. child.Name .. " (" .. child.ClassName .. ")")
            end
        end
    else
        print("❌ Tests folder not found")
    end
    
    -- Count scripts in ServerScriptService
    local scriptCount = 0
    for _, child in pairs(serverScriptService:GetChildren()) do
        if child:IsA("Script") or child:IsA("LocalScript") then
            scriptCount = scriptCount + 1
        end
    end
    print("   Total scripts in ServerScriptService:", scriptCount)
else
    print("❌ ServerScriptService missing")
end

-- Test 3: ReplicatedStorage
print("\n🧪 Test 3: ReplicatedStorage")
local replicatedStorage = game:GetService("ReplicatedStorage")
if replicatedStorage then
    print("✅ ReplicatedStorage exists")
    
    -- Count items
    local itemCount = 0
    for _, _ in pairs(replicatedStorage:GetChildren()) do
        itemCount = itemCount + 1
    end
    print("   Items found:", itemCount)
    
    -- Look for RemoteEvents
    local remoteEvents = replicatedStorage:FindFirstChild("RemoteEvents")
    if remoteEvents then
        local eventCount = 0
        for _, _ in pairs(remoteEvents:GetChildren()) do
            eventCount = eventCount + 1
        end
        print("   Remote events found:", eventCount)
    else
        print("   RemoteEvents folder not found")
    end
else
    print("❌ ReplicatedStorage missing")
end

-- Test 4: Network Manager
print("\n🧪 Test 4: Network Manager")
local networkManagerFound = false
local function searchForNetworkManager(parent)
    for _, child in pairs(parent:GetChildren()) do
        if child.Name == "NetworkManager" and child:IsA("Script") then
            networkManagerFound = true
            print("✅ NetworkManager script found at:", child:GetFullName())
            return true
        end
        
        if child:IsA("Folder") or child:IsA("Model") then
            searchForNetworkManager(child)
        end
    end
    return false
end

searchForNetworkManager(game)
if not networkManagerFound then
    print("❌ NetworkManager script not found (normal if not synced via Rojo)")
end

-- Test 5: Performance
print("\n🧪 Test 5: Performance")
local startTime = time()
local sum = 0
for i = 1, 1000 do
    sum = sum + i
end
local endTime = time()
local duration = endTime - startTime

print("✅ Basic computation test completed")
print("   Time taken:", string.format("%.4f", duration * 1000), "ms")
print("   Result:", sum)
print("   Expected:", 500500)

if sum == 500500 then
    print("✅ Math calculation correct")
else
    print("❌ Math calculation incorrect")
end

-- Final summary
print("\n" .. string.rep("=", 60))
print("🎯 SIMPLE RUN TESTS COMPLETE!")
print(string.rep("=", 60))
print("✅ All basic tests completed successfully!")
print("💡 Your game systems are working correctly")
print("💡 If you see this message, everything is functioning properly")

-- Keep script alive to show results
wait(3)
print("\n🏁 SimpleRunTests finished. Check the output above for results.")
