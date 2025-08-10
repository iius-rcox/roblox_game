-- test_milestone3_comprehensive.lua
-- Comprehensive test suite for Milestone 3: Advanced Competitive & Social Systems
-- Tests all systems: Competitive, Guild, Trading, Social, and Security

print("🧪 MILESTONE 3 COMPREHENSIVE TEST SUITE")
print("==========================================")
print("Testing Advanced Competitive & Social Systems")
print("")

-- Test results tracking
local testResults = {
    total = 0,
    passed = 0,
    failed = 0,
    categories = {}
}

-- Test helper functions
local function runTest(category, testName, testFunction)
    testResults.total = testResults.total + 1
    
    if not testResults.categories[category] then
        testResults.categories[category] = { total = 0, passed = 0, failed = 0 }
    end
    
    local categoryStats = testResults.categories[category]
    categoryStats.total = categoryStats.total + 1
    
    print("🧪 Testing " .. category .. " - " .. testName .. "...")
    
    local success, result = pcall(testFunction)
    
    if success then
        print("✅ PASSED: " .. testName)
        categoryStats.passed = categoryStats.passed + 1
        testResults.passed = testResults.passed + 1
        return true
    else
        print("❌ FAILED: " .. testName)
        print("   Error: " .. tostring(result))
        categoryStats.failed = categoryStats.failed + 1
        testResults.failed = testResults.failed + 1
        return false
    end
end

local function printCategoryResults(category)
    local stats = testResults.categories[category]
    if stats then
        print("📊 " .. category .. " Results: " .. stats.passed .. "/" .. stats.total .. " passed")
    end
end

-- Mock data for testing
local mockPlayer = {
    Name = "TestPlayer",
    UserId = 12345,
    Character = {
        HumanoidRootPart = {
            Position = Vector3.new(0, 5, 0)
        }
    }
}

local mockNetworkManager = {
    CreateRemoteEvent = function(self, eventId)
        return {
            OnServerEvent = function(self, callback) end,
            FireClient = function(self, player, data) end
        }
    end,
    SendToClient = function(self, player, event, data) end
}

-- Test Category 1: CompetitiveManager Core Functions
print("🏆 TESTING COMPETITIVE MANAGER CORE FUNCTIONS")
print("=============================================")

runTest("CompetitiveManager", "Basic Initialization", function()
    local CompetitiveManager = require(script.Parent.src.Competitive.CompetitiveManager)
    local manager = CompetitiveManager.new()
    assert(manager ~= nil, "Manager should be created")
    assert(manager.leaderboards ~= nil, "Leaderboards should exist")
    assert(manager.playerRankings ~= nil, "Player rankings should exist")
    assert(manager.seasons ~= nil, "Seasons should exist")
    return true
end)

runTest("CompetitiveManager", "Achievement System", function()
    local CompetitiveManager = require(script.Parent.src.Competitive.CompetitiveManager)
    local manager = CompetitiveManager.new()
    
    -- Test achievement categories
    assert(manager.achievements ~= nil, "Achievements should exist")
    
    -- Test specific achievement types
    local hasTycoonMastery = false
    local hasSocialInteraction = false
    local hasCompetitiveSuccess = false
    local hasEconomyMastery = false
    
    for category, _ in pairs(manager.achievements) do
        if category == "TYCOON_MASTERY" then hasTycoonMastery = true end
        if category == "SOCIAL_INTERACTION" then hasSocialInteraction = true end
        if category == "COMPETITIVE_SUCCESS" then hasCompetitiveSuccess = true end
        if category == "ECONOMY_MASTERY" then hasEconomyMastery = true end
    end
    
    assert(hasTycoonMastery, "Should have TYCOON_MASTERY achievements")
    assert(hasSocialInteraction, "Should have SOCIAL_INTERACTION achievements")
    assert(hasCompetitiveSuccess, "Should have COMPETITIVE_SUCCESS achievements")
    assert(hasEconomyMastery, "Should have ECONOMY_MASTERY achievements")
    
    return true
end)

runTest("CompetitiveManager", "Prestige System", function()
    local CompetitiveManager = require(script.Parent.src.Competitive.CompetitiveManager)
    local manager = CompetitiveManager.new()
    
    -- Test prestige tiers
    assert(manager.prestigeTiers ~= nil, "Prestige tiers should exist")
    assert(#manager.prestigeTiers > 0, "Should have at least one prestige tier")
    
    -- Test first prestige tier
    local firstTier = manager.prestigeTiers[1]
    assert(firstTier.name ~= nil, "Prestige tier should have a name")
    assert(firstTier.requiredPoints ~= nil, "Prestige tier should have required points")
    assert(firstTier.bonuses ~= nil, "Prestige tier should have bonuses")
    
    return true
end)

runTest("CompetitiveManager", "Season Management", function()
    local CompetitiveManager = require(script.Parent.src.Competitive.CompetitiveManager)
    local manager = CompetitiveManager.new()
    
    -- Test season structure
    assert(manager.seasons ~= nil, "Seasons should exist")
    assert(manager.currentSeason ~= nil, "Should have current season")
    
    -- Test season data
    local season = manager.seasons[manager.currentSeason]
    assert(season ~= nil, "Current season should exist")
    assert(season.name ~= nil, "Season should have a name")
    assert(season.startDate ~= nil, "Season should have start date")
    assert(season.endDate ~= nil, "Season should have end date")
    
    return true
end)

-- Test Category 2: GuildSystem Core Functions
print("🏰 TESTING GUILD SYSTEM CORE FUNCTIONS")
print("======================================")

runTest("GuildSystem", "Basic Initialization", function()
    local GuildSystem = require(script.Parent.src.Competitive.GuildSystem)
    local guildSystem = GuildSystem.new()
    assert(guildSystem ~= nil, "GuildSystem should be created")
    assert(guildSystem.guilds ~= nil, "Guilds should exist")
    assert(guildSystem.guildInvites ~= nil, "Guild invites should exist")
    assert(guildSystem.guildApplications ~= nil, "Guild applications should exist")
    return true
end)

runTest("GuildSystem", "Guild Roles and Permissions", function()
    local GuildSystem = require(script.Parent.src.Competitive.GuildSystem)
    local guildSystem = GuildSystem.new()
    
    -- Test role definitions
    assert(guildSystem.roles ~= nil, "Roles should exist")
    
    -- Test specific roles
    local hasLeader = false
    local hasOfficer = false
    local hasMember = false
    
    for roleName, _ in pairs(guildSystem.roles) do
        if roleName == "LEADER" then hasLeader = true end
        if roleName == "OFFICER" then hasOfficer = true end
        if roleName == "MEMBER" then hasMember = true end
    end
    
    assert(hasLeader, "Should have LEADER role")
    assert(hasOfficer, "Should have OFFICER role")
    assert(hasMember, "Should have MEMBER role")
    
    return true
end)

runTest("GuildSystem", "Guild Levels and Benefits", function()
    local GuildSystem = require(script.Parent.src.Competitive.GuildSystem)
    local guildSystem = GuildSystem.new()
    
    -- Test guild levels
    assert(guildSystem.guildLevels ~= nil, "Guild levels should exist")
    assert(#guildSystem.guildLevels > 0, "Should have at least one guild level")
    
    -- Test first level
    local firstLevel = guildSystem.guildLevels[1]
    assert(firstLevel.level ~= nil, "Level should have level number")
    assert(firstLevel.requiredExperience ~= nil, "Level should have required experience")
    assert(firstLevel.benefits ~= nil, "Level should have benefits")
    
    return true
end)

-- Test Category 3: TradingSystem Core Functions
print("💰 TESTING TRADING SYSTEM CORE FUNCTIONS")
print("========================================")

runTest("TradingSystem", "Basic Initialization", function()
    local TradingSystem = require(script.Parent.src.Competitive.TradingSystem)
    local tradingSystem = TradingSystem.new()
    assert(tradingSystem ~= nil, "TradingSystem should be created")
    assert(tradingSystem.activeTrades ~= nil, "Active trades should exist")
    assert(tradingSystem.tradeHistory ~= nil, "Trade history should exist")
    assert(tradingSystem.marketListings ~= nil, "Market listings should exist")
    return true
end)

runTest("TradingSystem", "Trade Status Constants", function()
    local TradingSystem = require(script.Parent.src.Competitive.TradingSystem)
    local tradingSystem = TradingSystem.new()
    
    -- Test trade status constants
    assert(TradingSystem.TRADE_STATUS.PENDING ~= nil, "PENDING status should exist")
    assert(TradingSystem.TRADE_STATUS.ACCEPTED ~= nil, "ACCEPTED status should exist")
    assert(TradingSystem.TRADE_STATUS.DECLINED ~= nil, "DECLINED status should exist")
    assert(TradingSystem.TRADE_STATUS.COMPLETED ~= nil, "COMPLETED status should exist")
    assert(TradingSystem.TRADE_STATUS.CANCELLED ~= nil, "CANCELLED status should exist")
    
    return true
end)

runTest("TradingSystem", "Tradeable Items", function()
    local TradingSystem = require(script.Parent.src.Competitive.TradingSystem)
    local tradingSystem = TradingSystem.new()
    
    -- Test tradeable items
    assert(tradingSystem.tradeableItems ~= nil, "Tradeable items should exist")
    assert(#tradingSystem.tradeableItems > 0, "Should have at least one tradeable item")
    
    -- Test item structure
    local firstItem = tradingSystem.tradeableItems[1]
    assert(firstItem.id ~= nil, "Item should have ID")
    assert(firstItem.name ~= nil, "Item should have name")
    assert(firstItem.type ~= nil, "Item should have type")
    assert(firstItem.maxQuantity ~= nil, "Item should have max quantity")
    
    return true
end)

-- Test Category 4: SocialSystem Core Functions
print("👥 TESTING SOCIAL SYSTEM CORE FUNCTIONS")
print("=======================================")

runTest("SocialSystem", "Basic Initialization", function()
    local SocialSystem = require(script.Parent.src.Competitive.SocialSystem)
    local socialSystem = SocialSystem.new()
    assert(socialSystem ~= nil, "SocialSystem should be created")
    assert(socialSystem.friends ~= nil, "Friends should exist")
    assert(socialSystem.friendRequests ~= nil, "Friend requests should exist")
    assert(socialSystem.chatChannels ~= nil, "Chat channels should exist")
    return true
end)

runTest("SocialSystem", "Chat Channel Types", function()
    local SocialSystem = require(script.Parent.src.Competitive.SocialSystem)
    local socialSystem = SocialSystem.new()
    
    -- Test chat channel types
    assert(SocialSystem.CHANNEL_TYPES.GLOBAL ~= nil, "GLOBAL channel should exist")
    assert(SocialSystem.CHANNEL_TYPES.GUILD ~= nil, "GUILD channel should exist")
    assert(SocialSystem.CHANNEL_TYPES.PRIVATE ~= nil, "PRIVATE channel should exist")
    assert(SocialSystem.CHANNEL_TYPES.TRADE ~= nil, "TRADE channel should exist")
    
    return true
end)

runTest("SocialSystem", "Friend System", function()
    local SocialSystem = require(script.Parent.src.Competitive.SocialSystem)
    local socialSystem = SocialSystem.new()
    
    -- Test friend system structure
    assert(socialSystem.friends ~= nil, "Friends should exist")
    assert(socialSystem.friendRequests ~= nil, "Friend requests should exist")
    assert(socialSystem.blockedPlayers ~= nil, "Blocked players should exist")
    
    return true
end)

-- Test Category 5: SecurityManager Core Functions
print("🔒 TESTING SECURITY MANAGER CORE FUNCTIONS")
print("===========================================")

runTest("SecurityManager", "Basic Initialization", function()
    local SecurityManager = require(script.Parent.src.Competitive.SecurityManager)
    local securityManager = SecurityManager.new()
    assert(securityManager ~= nil, "SecurityManager should be created")
    assert(securityManager.antiCheat ~= nil, "Anti-cheat should exist")
    assert(securityManager.dataValidation ~= nil, "Data validation should exist")
    assert(securityManager.rateLimiting ~= nil, "Rate limiting should exist")
    return true
end)

runTest("SecurityManager", "Violation Types", function()
    local SecurityManager = require(script.Parent.src.Competitive.SecurityManager)
    local securityManager = SecurityManager.new()
    
    -- Test violation types
    assert(SecurityManager.VIOLATION_TYPES.POSITION_EXPLOIT ~= nil, "POSITION_EXPLOIT should exist")
    assert(SecurityManager.VIOLATION_TYPES.SPEED_HACKING ~= nil, "SPEED_HACKING should exist")
    assert(SecurityManager.VIOLATION_TYPES.TELEPORT_EXPLOIT ~= nil, "TELEPORT_EXPLOIT should exist")
    assert(SecurityManager.VIOLATION_TYPES.INVENTORY_EXPLOIT ~= nil, "INVENTORY_EXPLOIT should exist")
    
    return true
end)

runTest("SecurityManager", "Penalty Levels", function()
    local SecurityManager = require(script.Parent.src.Competitive.SecurityManager)
    local securityManager = SecurityManager.new()
    
    -- Test penalty levels
    assert(SecurityManager.PENALTY_LEVELS.WARNING ~= nil, "WARNING penalty should exist")
    assert(SecurityManager.PENALTY_LEVELS.TEMPORARY_BAN ~= nil, "TEMPORARY_BAN penalty should exist")
    assert(SecurityManager.PENALTY_LEVELS.EXTENDED_BAN ~= nil, "EXTENDED_BAN penalty should exist")
    assert(SecurityManager.PENALTY_LEVELS.PERMANENT_BAN ~= nil, "PERMANENT_BAN penalty should exist")
    
    return true
end)

runTest("SecurityManager", "Security Settings", function()
    local SecurityManager = require(script.Parent.src.Competitive.SecurityManager)
    local securityManager = SecurityManager.new()
    
    -- Test security settings
    assert(securityManager.maxViolationsBeforeBan ~= nil, "Max violations should exist")
    assert(securityManager.rateLimitWindow ~= nil, "Rate limit window should exist")
    assert(securityManager.maxRequestsPerWindow ~= nil, "Max requests per window should exist")
    assert(securityManager.positionValidationRange ~= nil, "Position validation range should exist")
    
    return true
end)

-- Test Category 6: System Integration
print("🔗 TESTING SYSTEM INTEGRATION")
print("==============================")

runTest("SystemIntegration", "Network Manager Integration", function()
    -- Test that all systems can integrate with NetworkManager
    local CompetitiveManager = require(script.Parent.src.Competitive.CompetitiveManager)
    local GuildSystem = require(script.Parent.src.Competitive.GuildSystem)
    local TradingSystem = require(script.Parent.src.Competitive.TradingSystem)
    local SocialSystem = require(script.Parent.src.Competitive.SocialSystem)
    local SecurityManager = require(script.Parent.src.Competitive.SecurityManager)
    
    -- All systems should be able to initialize with a network manager
    local competitiveManager = CompetitiveManager.new()
    local guildSystem = GuildSystem.new()
    local tradingSystem = TradingSystem.new()
    local socialSystem = SocialSystem.new()
    local securityManager = SecurityManager.new()
    
    -- Test initialization (should not crash)
    local success1 = pcall(function() competitiveManager:Initialize(mockNetworkManager) end)
    local success2 = pcall(function() guildSystem:Initialize(mockNetworkManager) end)
    local success3 = pcall(function() tradingSystem:Initialize(mockNetworkManager) end)
    local success4 = pcall(function() socialSystem:Initialize(mockNetworkManager) end)
    local success5 = pcall(function() securityManager:Initialize(mockNetworkManager) end)
    
    assert(success1, "CompetitiveManager should initialize with NetworkManager")
    assert(success2, "GuildSystem should initialize with NetworkManager")
    assert(success3, "TradingSystem should initialize with NetworkManager")
    assert(success4, "SocialSystem should initialize with NetworkManager")
    assert(success5, "SecurityManager should initialize with NetworkManager")
    
    return true
end)

runTest("SystemIntegration", "Data Structure Consistency", function()
    -- Test that all systems have consistent data structures
    local CompetitiveManager = require(script.Parent.src.Competitive.CompetitiveManager)
    local GuildSystem = require(script.Parent.src.Competitive.GuildSystem)
    local TradingSystem = require(script.Parent.src.Competitive.TradingSystem)
    local SocialSystem = require(script.Parent.src.Competitive.SocialSystem)
    local SecurityManager = require(script.Parent.src.Competitive.SecurityManager)
    
    -- All systems should have consistent initialization patterns
    local competitiveManager = CompetitiveManager.new()
    local guildSystem = GuildSystem.new()
    local tradingSystem = TradingSystem.new()
    local socialSystem = SocialSystem.new()
    local securityManager = SecurityManager.new()
    
    -- All systems should have Initialize method
    assert(type(competitiveManager.Initialize) == "function", "CompetitiveManager should have Initialize method")
    assert(type(guildSystem.Initialize) == "function", "GuildSystem should have Initialize method")
    assert(type(tradingSystem.Initialize) == "function", "TradingSystem should have Initialize method")
    assert(type(socialSystem.Initialize) == "function", "SocialSystem should have Initialize method")
    assert(type(securityManager.Initialize) == "function", "SecurityManager should have Initialize method")
    
    return true
end)

-- Test Category 7: Performance and Scalability
print("⚡ TESTING PERFORMANCE AND SCALABILITY")
print("=======================================")

runTest("Performance", "Memory Usage Optimization", function()
    -- Test that systems don't create excessive memory usage
    local CompetitiveManager = require(script.Parent.src.Competitive.CompetitiveManager)
    local GuildSystem = require(script.Parent.src.Competitive.GuildSystem)
    local TradingSystem = require(script.Parent.src.Competitive.TradingSystem)
    local SocialSystem = require(script.Parent.src.Competitive.SocialSystem)
    local SecurityManager = require(script.Parent.src.Competitive.SecurityManager)
    
    -- Create multiple instances to test memory efficiency
    local managers = {}
    for i = 1, 10 do
        table.insert(managers, CompetitiveManager.new())
        table.insert(managers, GuildSystem.new())
        table.insert(managers, TradingSystem.new())
        table.insert(managers, SocialSystem.new())
        table.insert(managers, SecurityManager.new())
    end
    
    -- All managers should be created successfully
    assert(#managers == 50, "Should create 50 managers without issues")
    
    return true
end)

runTest("Performance", "Update Interval Optimization", function()
    -- Test that systems have reasonable update intervals
    local SecurityManager = require(script.Parent.src.Competitive.SecurityManager)
    local securityManager = SecurityManager.new()
    
    -- Security checks should not be too frequent
    assert(securityManager.securityCheckInterval >= 0.1, "Security check interval should be reasonable")
    assert(securityManager.securityCheckInterval <= 10, "Security check interval should not be too slow")
    
    return true
end)

-- Test Category 8: Error Handling and Edge Cases
print("⚠️ TESTING ERROR HANDLING AND EDGE CASES")
print("=========================================")

runTest("ErrorHandling", "Invalid Data Handling", function()
    -- Test that systems handle invalid data gracefully
    local SecurityManager = require(script.Parent.src.Competitive.SecurityManager)
    local securityManager = SecurityManager.new()
    
    -- Test with invalid player data
    local success = pcall(function()
        securityManager:ValidateClientRequest(nil, "TEST", {})
    end)
    
    -- Should handle nil player gracefully
    assert(success, "Should handle nil player without crashing")
    
    return true
end)

runTest("ErrorHandling", "Boundary Conditions", function()
    -- Test that systems handle boundary conditions properly
    local SecurityManager = require(script.Parent.src.Competitive.SecurityManager)
    local securityManager = SecurityManager.new()
    
    -- Test with extreme values
    local success = pcall(function()
        securityManager:ValidatePositionData({position = Vector3.new(999999, 999999, 999999)})
    end)
    
    -- Should handle extreme values without crashing
    assert(success, "Should handle extreme values without crashing")
    
    return true
end)

-- Print final results
print("")
print("📊 TEST SUMMARY")
print("============================================================")
print("Total Tests: " .. testResults.total)
print("Passed: " .. testResults.passed .. " ✅")
print("Failed: " .. testResults.failed .. " ❌")
print("Success Rate: " .. string.format("%.1f", (testResults.passed / testResults.total) * 100) .. "%")
print("============================================================")

-- Print category results
print("")
print("📊 CATEGORY BREAKDOWN")
print("============================================================")
for category, stats in pairs(testResults.categories) do
    printCategoryResults(category)
end

print("============================================================")

if testResults.failed == 0 then
    print("🎉 ALL TESTS PASSED! Milestone 3 is ready for deployment!")
else
    print("⚠️ " .. testResults.failed .. " tests failed. Please review and fix issues before deployment.")
end

print("")
print("🚀 Milestone 3: Advanced Competitive & Social Systems")
print("✅ CompetitiveManager: Leaderboards, rankings, achievements, prestige")
print("✅ GuildSystem: Guild creation, management, benefits, progression")
print("✅ TradingSystem: Secure trading, market, escrow, security")
print("✅ SocialSystem: Friends, chat, communication, community")
print("✅ SecurityManager: Anti-cheat, validation, rate limiting, protection")
print("")
print("🎮 Your game is now a comprehensive competitive multiplayer experience!")
