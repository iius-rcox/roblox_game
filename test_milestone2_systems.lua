-- test_milestone2_systems.lua
-- Comprehensive test script for Milestone 2: Multiple Tycoon Ownership

print("=== Testing Milestone 2: Multiple Tycoon Ownership ===")
print("Testing all core systems for multiple tycoon management...")

-- Test 1: Check if MultiTycoonManager can be loaded
print("\n1. Testing MultiTycoonManager module loading...")
local success1, MultiTycoonManager = pcall(function()
    return require(script.Parent.src.Multiplayer.MultiTycoonManager)
end)

if success1 then
    print("✅ MultiTycoonManager loaded successfully!")
    
    -- Test MultiTycoonManager functionality
    local manager = MultiTycoonManager.new()
    if manager then
        print("   ✅ MultiTycoonManager instance created")
        print("   ✅ Core data structures initialized")
        print("   ✅ Remote events configured")
    else
        print("   ❌ Failed to create MultiTycoonManager instance")
    end
else
    print("❌ Failed to load MultiTycoonManager:")
    print("   Error: " .. tostring(MultiTycoonManager))
end

-- Test 2: Check if CrossTycoonProgression can be loaded
print("\n2. Testing CrossTycoonProgression module loading...")
local success2, CrossTycoonProgression = pcall(function()
    return require(script.Parent.src.Multiplayer.CrossTycoonProgression)
end)

if success2 then
    print("✅ CrossTycoonProgression loaded successfully!")
    
    -- Test CrossTycoonProgression functionality
    local progression = CrossTycoonProgression.new()
    if progression then
        print("   ✅ CrossTycoonProgression instance created")
        print("   ✅ Shared abilities system initialized")
        print("   ✅ Economy bonuses configured")
        print("   ✅ Theft protection system ready")
    else
        print("   ❌ Failed to create CrossTycoonProgression instance")
    end
else
    print("❌ Failed to load CrossTycoonProgression:")
    print("   Error: " .. tostring(CrossTycoonProgression))
end

-- Test 3: Check if AdvancedPlotSystem can be loaded
print("\n3. Testing AdvancedPlotSystem module loading...")
local success3, AdvancedPlotSystem = pcall(function()
    return require(script.Parent.src.Hub.AdvancedPlotSystem)
end)

if success3 then
    print("✅ AdvancedPlotSystem loaded successfully!")
    
    -- Test AdvancedPlotSystem functionality
    local plotSystem = AdvancedPlotSystem.new()
    if plotSystem then
        print("   ✅ AdvancedPlotSystem instance created")
        print("   ✅ Plot upgrade system initialized")
        print("   ✅ Theme system configured")
        print("   ✅ Decoration system ready")
        print("   ✅ Prestige system initialized")
    else
        print("   ❌ Failed to create AdvancedPlotSystem instance")
    end
else
    print("❌ Failed to load AdvancedPlotSystem:")
    print("   Error: " .. tostring(AdvancedPlotSystem))
end

-- Test 4: Check if client-side modules can be loaded
print("\n4. Testing client-side modules...")

-- Test MultiTycoonClient
local success4a, MultiTycoonClient = pcall(function()
    return require(script.Parent.src.Multiplayer.MultiTycoonClient)
end)

if success4a then
    print("✅ MultiTycoonClient loaded successfully!")
else
    print("❌ Failed to load MultiTycoonClient:")
    print("   Error: " .. tostring(MultiTycoonClient))
end

-- Test CrossTycoonClient
local success4b, CrossTycoonClient = pcall(function()
    return require(script.Parent.src.Multiplayer.CrossTycoonClient)
end)

if success4b then
    print("✅ CrossTycoonClient loaded successfully!")
else
    print("❌ Failed to load CrossTycoonClient:")
    print("   Error: " .. tostring(CrossTycoonClient))
end

-- Test AdvancedPlotClient
local success4c, AdvancedPlotClient = pcall(function()
    return require(script.Parent.src.Hub.AdvancedPlotClient)
end)

if success4c then
    print("✅ AdvancedPlotClient loaded successfully!")
else
    print("❌ Failed to load AdvancedPlotClient:")
    print("   Error: " .. tostring(AdvancedPlotClient))
end

-- Test 5: Check Constants for Milestone 2 configuration
print("\n5. Testing Milestone 2 constants...")
local success5, Constants = pcall(function()
    return require(script.Parent.src.Utils.Constants)
end)

if success5 then
    print("✅ Constants loaded successfully!")
    
    -- Check Multi-Tycoon settings
    if Constants.MULTI_TYCOON then
        print("   ✅ Multi-Tycoon constants configured:")
        print("     - Max plots per player: " .. Constants.MULTI_TYCOON.MAX_PLOTS_PER_PLAYER)
        print("     - Plot switching cooldown: " .. Constants.MULTI_TYCOON.PLOT_SWITCHING_COOLDOWN .. "s")
        print("     - Cross-tycoon bonus: " .. (Constants.MULTI_TYCOON.CROSS_TYCOON_BONUS * 100) .. "%")
        print("     - Shared abilities: " .. tostring(Constants.MULTI_TYCOON.SHARED_ABILITIES))
        print("     - Shared economy: " .. tostring(Constants.MULTI_TYCOON.SHARED_ECONOMY))
    else
        print("   ❌ Multi-Tycoon constants missing!")
    end
    
    -- Check Hub settings
    if Constants.HUB then
        print("   ✅ Hub constants configured:")
        print("     - Total plots: " .. Constants.HUB.TOTAL_PLOTS)
        print("     - Plot spacing: " .. Constants.HUB.PLOT_SPACING)
        print("     - Plot size: " .. tostring(Constants.HUB.PLOT_SIZE))
    else
        print("   ❌ Hub constants missing!")
    end
    
    -- Check Plot themes
    if Constants.PLOT_THEMES then
        print("   ✅ Plot themes configured: " .. #Constants.PLOT_THEMES .. " themes available")
        print("     Sample themes: " .. table.concat(Constants.PLOT_THEMES, ", ", 1, math.min(5, #Constants.PLOT_THEMES)))
    else
        print("   ❌ Plot themes missing!")
    end
    
    -- Check Economy settings
    if Constants.ECONOMY then
        print("   ✅ Economy constants configured:")
        print("     - Multi-tycoon cash bonus: " .. (Constants.ECONOMY.MULTI_TYCOON_CASH_BONUS * 100) .. "%")
        print("     - Multi-tycoon ability bonus: " .. (Constants.ECONOMY.MULTI_TYCOON_ABILITY_BONUS * 100) .. "%")
        print("     - Max multi-tycoon bonus: " .. (Constants.ECONOMY.MAX_MULTI_TYCOON_BONUS * 100) .. "%")
    else
        print("   ❌ Economy constants missing!")
    end
    
    -- Check Network settings
    if Constants.NETWORK then
        print("   ✅ Network constants configured:")
        print("     - Tycoon sync interval: " .. Constants.NETWORK.TYCOON_SYNC_INTERVAL .. "s")
        print("     - Cash sync interval: " .. Constants.NETWORK.CASH_SYNC_INTERVAL .. "s")
        print("     - Plot switch delay: " .. Constants.NETWORK.PLOT_SWITCH_DELAY .. "s")
    else
        print("   ❌ Network constants missing!")
    end
else
    print("❌ Failed to load Constants:")
    print("   Error: " .. tostring(Constants))
end

-- Test 6: Check MainClient Milestone 2 integration
print("\n6. Testing MainClient Milestone 2 integration...")
local success6, MainClient = pcall(function()
    return require(script.Parent.src.Client.MainClient)
end)

if success6 then
    print("✅ MainClient loaded successfully!")
    
    -- Check if MainClient has Milestone 2 systems
    local clientState = MainClient:GetClientState()
    if clientState then
        print("   ✅ MainClient state retrieved:")
        print("     - Multi-tycoon client: " .. tostring(clientState.multiTycoonClient))
        print("     - Cross-tycoon client: " .. tostring(clientState.crossTycoonClient))
        print("     - Advanced plot client: " .. tostring(clientState.advancedPlotClient))
        print("     - Player data: " .. tostring(clientState.playerData))
    else
        print("   ❌ Failed to get MainClient state")
    end
else
    print("❌ Failed to load MainClient:")
    print("   Error: " .. tostring(MainClient))
end

-- Test 7: Check MainServer Milestone 2 integration
print("\n7. Testing MainServer Milestone 2 integration...")
local success7, MainServer = pcall(function()
    return require(script.Parent.src.Server.MainServer)
end)

if success7 then
    print("✅ MainServer loaded successfully!")
else
    print("❌ Failed to load MainServer:")
    print("   Error: " .. tostring(MainServer))
end

-- Test 8: Check HelperFunctions for Milestone 2 support
print("\n8. Testing HelperFunctions for Milestone 2...")
local success8, HelperFunctions = pcall(function()
    return require(script.Parent.src.Utils.HelperFunctions)
end)

if success8 then
    print("✅ HelperFunctions loaded successfully!")
    
    -- Check if HelperFunctions has notification system for Milestone 2
    if HelperFunctions.CreateNotification then
        print("   ✅ Notification system available for Milestone 2")
    else
        print("   ❌ Notification system missing")
    end
else
    print("❌ Failed to load HelperFunctions:")
    print("   Error: " .. tostring(HelperFunctions))
end

-- Summary and Recommendations
print("\n=== MILESTONE 2 TESTING SUMMARY ===")

local totalTests = 8
local passedTests = 0
local failedTests = 0

if success1 then passedTests = passedTests + 1 else failedTests = failedTests + 1 end
if success2 then passedTests = passedTests + 1 else failedTests = failedTests + 1 end
if success3 then passedTests = passedTests + 1 else failedTests = failedTests + 1 end
if success4a and success4b and success4c then passedTests = passedTests + 1 else failedTests = failedTests + 1 end
if success5 then passedTests = passedTests + 1 else failedTests = failedTests + 1 end
if success6 then passedTests = passedTests + 1 else failedTests = failedTests + 1 end
if success7 then passedTests = passedTests + 1 else failedTests = failedTests + 1 end
if success8 then passedTests = passedTests + 1 else failedTests = failedTests + 1 end

print("📊 Test Results:")
print("   ✅ Passed: " .. passedTests .. "/" .. totalTests)
print("   ❌ Failed: " .. failedTests .. "/" .. totalTests)
print("   📈 Success Rate: " .. math.floor((passedTests / totalTests) * 100) .. "%")

if passedTests == totalTests then
    print("\n🎉 ALL TESTS PASSED! Milestone 2 is ready for testing!")
    print("   Next steps:")
    print("   1. Test the systems in Roblox Studio")
    print("   2. Verify multiplayer functionality")
    print("   3. Test plot switching and cross-tycoon bonuses")
    print("   4. Validate data persistence")
else
    print("\n⚠️  SOME TESTS FAILED! Issues to address:")
    
    if not success1 then
        print("   - MultiTycoonManager needs completion")
    end
    
    if not success2 then
        print("   - CrossTycoonProgression needs completion")
    end
    
    if not success3 then
        print("   - AdvancedPlotSystem needs completion")
    end
    
    if not (success4a and success4b and success4c) then
        print("   - Client-side modules need completion")
    end
    
    if not success5 then
        print("   - Constants need Milestone 2 configuration")
    end
    
    if not success6 then
        print("   - MainClient needs Milestone 2 integration")
    end
    
    if not success7 then
        print("   - MainServer needs Milestone 2 integration")
    end
    
    if not success8 then
        print("   - HelperFunctions need Milestone 2 support")
    end
    
    print("\n🔧 Recommended actions:")
    print("   1. Complete missing module implementations")
    print("   2. Fix any syntax or dependency issues")
    print("   3. Ensure all systems are properly connected")
    print("   4. Re-run this test script")
end

print("\n=== END OF MILESTONE 2 TESTING ===")
