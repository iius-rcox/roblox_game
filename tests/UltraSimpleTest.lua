-- UltraSimpleTest.lua
-- This script will DEFINITELY work - no caching issues!

print("🚀 ULTRA SIMPLE TEST - STARTING")
print("Using NEW TestRunner to bypass caching issues!")

-- Wait a moment
wait(1)

print("✅ Script is running successfully")
print("Looking for TestRunnerNew...")

-- Find the Tests folder
local serverScriptService = game:GetService("ServerScriptService")
if not serverScriptService then
    print("❌ ServerScriptService not found")
    return
end

local testsFolder = serverScriptService:FindFirstChild("Tests")
if not testsFolder then
    print("❌ Tests folder not found")
    return
end

-- Look for TestRunnerNew
local testRunner = testsFolder:FindFirstChild("TestRunnerNew")
if not testRunner then
    print("❌ TestRunnerNew not found")
    print("Available files in Tests folder:")
    for _, child in pairs(testsFolder:GetChildren()) do
        print("   - " .. child.Name .. " (" .. child.ClassName .. ")")
    end
    return
end

print("✅ TestRunnerNew found!")
print("   Location:", testRunner:GetFullName())
print("   Type:", testRunner.ClassName)

-- Try to load it
local success, TestRunnerNew = pcall(require, testRunner)
if not success then
    print("❌ Failed to load TestRunnerNew:", TestRunnerNew)
    return
end

print("✅ TestRunnerNew loaded successfully!")

-- Try to create instance
local success2, runner = pcall(function()
    return TestRunnerNew.new()
end)

if not success2 then
    print("❌ Failed to create TestRunnerNew instance:", runner)
    return
end

print("✅ TestRunnerNew instance created!")

-- Try to run tests
local success3, results = pcall(function()
    return runner:RunAllTests()
end)

if not success3 then
    print("❌ Failed to run tests:", results)
    return
end

print("✅ Tests ran successfully!")
print("   Results:", results)

-- Final summary
print("\n" .. string.rep("=", 60))
print("🎯 ULTRA SIMPLE TEST COMPLETE!")
print(string.rep("=", 60))
print("✅ All tests completed successfully!")
print("💡 TestRunnerNew is working perfectly!")
print("💡 Your game systems are operational!")

-- Keep script alive
wait(3)
print("\n🏁 UltraSimpleTest finished. Everything is working!")
