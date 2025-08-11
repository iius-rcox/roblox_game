-- FindTestRunner.lua
-- Simple script to find and test your TestRunner.lua
-- Place this in ServerScriptService (same level as Tests folder)

print("🔍 FINDING YOUR TESTRUNNER")
print("Looking for TestRunner.lua in ServerScriptService/Tests...")

-- Wait for systems to initialize
wait(1)

-- Method 1: Look in Tests folder
local testsFolder = game.ServerScriptService:FindFirstChild("Tests")
if testsFolder then
    print("✅ Found Tests folder in ServerScriptService")
    
    local testRunner = testsFolder:FindFirstChild("TestRunner")
    if testRunner then
        print("✅ Found TestRunner.lua script")
        print("   Location:", testRunner:GetFullName())
        print("   Type:", testRunner.ClassName)
        
        -- Try to require it
        local success, TestRunner = pcall(require, testRunner)
        if success then
            print("✅ Successfully loaded TestRunner module")
            
            -- Try to create an instance
            local success2, runner = pcall(function()
                return TestRunner.new()
            end)
            
            if success2 then
                print("✅ Successfully created TestRunner instance")
                
                -- Try to run tests
                local success3, results = pcall(function()
                    return runner:RunAllTests()
                end)
                
                if success3 then
                    print("✅ Successfully ran tests!")
                    print("   Results:", results)
                else
                    print("❌ Failed to run tests:", results)
                end
            else
                print("❌ Failed to create TestRunner instance:", runner)
            end
        else
            print("❌ Failed to load TestRunner module:", TestRunner)
        end
    else
        print("❌ TestRunner.lua not found in Tests folder")
        print("   Available files in Tests folder:")
        for _, child in pairs(testsFolder:GetChildren()) do
            print("   - " .. child.Name .. " (" .. child.ClassName .. ")")
        end
    end
else
    print("❌ Tests folder not found in ServerScriptService")
    print("   Available items in ServerScriptService:")
    for _, child in pairs(game.ServerScriptService:GetChildren()) do
        print("   - " .. child.Name .. " (" .. child.ClassName .. ")")
    end
end

print("\n🎯 FINDING COMPLETE!")
print("Check the output above to see what was found.")
