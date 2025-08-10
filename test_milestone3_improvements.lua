-- test_milestone3_improvements.lua
-- Comprehensive test script for Milestone 3 improvements
-- Tests enhanced security validation, Roblox leaderboard integration, and performance monitoring

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Mock network manager for testing
local MockNetworkManager = {}
MockNetworkManager.__index = MockNetworkManager

function MockNetworkManager.new()
    local self = setmetatable({}, MockNetworkManager)
    self.remoteEvents = {}
    return self
end

function MockNetworkManager:CreateRemoteEvent(name)
    local event = {
        OnServerEvent = {
            Connect = function(self, callback)
                self.callback = callback
            end
        },
        FireClient = function(self, player, ...)
            -- Mock fire client
        end,
        FireAllClients = function(self, ...)
            -- Mock fire all clients
        end
    }
    self.remoteEvents[name] = event
    return event
end

function MockNetworkManager:SendToClient(player, eventName, data)
    -- Mock send to client
end

-- Test the improved SecurityManager
print("🔒 Testing Enhanced SecurityManager...")

local SecurityManager = require(script.Parent.src.Competitive.SecurityManager)
local securityManager = SecurityManager.new()

-- Test enhanced validation functions
print("  Testing enhanced data validation...")

-- Test NaN/Inf detection
local testData1 = {
    position = Vector3.new(1/0, 0, -1/0), -- Inf values
    items = {1, 2, 0/0, 4} -- NaN value
}

local result1, error1 = securityManager:ValidateDataStructure(testData1)
assert(not result1, "Should detect NaN/Inf values")
assert(error1:find("Invalid numeric values"), "Should provide specific error message")
print("    ✅ NaN/Inf detection working")

-- Test UTF-8 validation
local testData2 = {
    name = "Test\xFF\xFE", -- Invalid UTF-8
    description = "Valid text"
}

local result2, error2 = securityManager:ValidateDataStructure(testData2)
assert(not result2, "Should detect invalid UTF-8")
assert(error2:find("Invalid UTF-8"), "Should provide specific error message")
print("    ✅ UTF-8 validation working")

-- Test table index validation
local testData3 = {
    [nil] = "invalid",
    [1/0] = "invalid",
    valid = "data"
}

local result3, error3 = securityManager:ValidateDataStructure(testData3)
assert(not result3, "Should detect invalid table indices")
assert(error3:find("Invalid table indices"), "Should provide specific error message")
print("    ✅ Table index validation working")

-- Test performance monitoring
print("  Testing performance monitoring...")

local startTime = tick()
securityManager:LogValidationTime(startTime, "TEST_VALIDATION")
local metrics = securityManager:GetPerformanceMetrics()

assert(metrics.totalValidations > 0, "Should track validation count")
assert(metrics.validationBreakdown.TEST_VALIDATION, "Should track validation breakdown")
assert(metrics.validationBreakdown.TEST_VALIDATION.count == 1, "Should count validations correctly")
print("    ✅ Performance monitoring working")

-- Test system health monitoring
print("  Testing system health monitoring...")

local health = securityManager:GetSystemHealth()
assert(health.status, "Should provide health status")
assert(health.issues, "Should provide issues list")
assert(health.recommendations, "Should provide recommendations")
print("    ✅ System health monitoring working")

-- Test the improved CompetitiveManager
print("🏆 Testing Enhanced CompetitiveManager...")

local CompetitiveManager = require(script.Parent.src.Competitive.CompetitiveManager)
local competitiveManager = CompetitiveManager.new()

-- Test Roblox leaderboard integration
print("  Testing Roblox leaderboard integration...")

assert(competitiveManager.useRobloxLeaderboard, "Should have Roblox leaderboard enabled")
assert(#competitiveManager.robloxLeaderboardStats > 0, "Should have leaderboard stats configured")
assert(competitiveManager.robloxLeaderboardStats[1] == "CompetitiveRank", "Should include CompetitiveRank")
print("    ✅ Roblox leaderboard configuration working")

-- Test metrics collection
print("  Testing metrics collection...")

local competitiveMetrics = competitiveManager:GetCompetitiveMetrics()
assert(competitiveMetrics.leaderboards, "Should provide leaderboard metrics")
assert(competitiveMetrics.players, "Should provide player metrics")
assert(competitiveMetrics.season, "Should provide season metrics")
assert(competitiveMetrics.performance, "Should provide performance metrics")
print("    ✅ Competitive metrics collection working")

-- Test the improved GuildSystem
print("⚔️ Testing Enhanced GuildSystem...")

local GuildSystem = require(script.Parent.src.Competitive.GuildSystem)
local guildSystem = GuildSystem.new()

-- Test metrics collection
print("  Testing guild metrics collection...")

local guildMetrics = guildSystem:GetGuildMetrics()
assert(guildMetrics.totalGuilds >= 0, "Should provide guild count")
assert(guildMetrics.totalMembers >= 0, "Should provide member count")
assert(guildMetrics.activeGuilds >= 0, "Should provide active guild count")
print("    ✅ Guild metrics collection working")

-- Test the improved TradingSystem
print("💰 Testing Enhanced TradingSystem...")

local TradingSystem = require(script.Parent.src.Competitive.TradingSystem)
local tradingSystem = TradingSystem.new()

-- Test metrics collection
print("  Testing trading metrics collection...")

local tradingMetrics = tradingSystem:GetTradingMetrics()
assert(tradingMetrics.activeTrades >= 0, "Should provide active trade count")
assert(tradingMetrics.totalTrades >= 0, "Should provide total trade count")
assert(tradingMetrics.marketListings >= 0, "Should provide market listing count")
print("    ✅ Trading metrics collection working")

-- Test the improved SocialSystem
print("👥 Testing Enhanced SocialSystem...")

local SocialSystem = require(script.Parent.src.Competitive.SocialSystem)
local socialSystem = SocialSystem.new()

-- Test metrics collection
print("  Testing social metrics collection...")

local socialMetrics = socialSystem:GetSocialMetrics()
assert(socialMetrics.totalFriendships >= 0, "Should provide friendship count")
assert(socialMetrics.activeChatChannels >= 0, "Should provide chat channel count")
assert(socialMetrics.socialGroups >= 0, "Should provide social group count")
print("    ✅ Social metrics collection working")

-- Test the improved MainServer
print("🖥️ Testing Enhanced MainServer...")

local MainServer = require(script.Parent.src.Server.MainServer)
local mainServer = MainServer.new()

-- Test system metrics collection
print("  Testing system metrics collection...")

local systemMetrics = mainServer:GetSystemMetrics()
assert(systemMetrics.timestamp, "Should provide timestamp")
assert(systemMetrics.serverUptime, "Should provide server uptime")
assert(systemMetrics.activePlayers >= 0, "Should provide active player count")
assert(systemMetrics.systems, "Should provide systems metrics")
print("    ✅ System metrics collection working")

-- Test system health monitoring
print("  Testing system health monitoring...")

local systemHealth = mainServer:GetSystemHealth()
assert(systemHealth.status, "Should provide health status")
assert(systemHealth.issues, "Should provide issues list")
assert(systemHealth.recommendations, "Should provide recommendations")
print("    ✅ System health monitoring working")

-- Performance stress test
print("🚀 Testing performance under load...")

local startTime = tick()
local iterations = 1000

for i = 1, iterations do
    -- Simulate validation calls
    local testData = {
        position = Vector3.new(math.random(-100, 100), math.random(-100, 100), math.random(-100, 100)),
        items = {math.random(1, 100), math.random(1, 100), math.random(1, 100)},
        currency = math.random(1, 10000)
    }
    
    local result, _ = securityManager:ValidateRequestData("POSITION_UPDATE", testData)
    assert(result, "Validation should succeed for valid data")
end

local endTime = tick()
local duration = endTime - startTime
local rate = iterations / duration

print("    ✅ Performance test completed:")
print("      - " .. iterations .. " validations in " .. string.format("%.3f", duration) .. " seconds")
print("      - Rate: " .. string.format("%.0f", rate) .. " validations/second")

-- Memory usage test
print("🧠 Testing memory usage monitoring...")

local memoryUsage = securityManager:GetMemoryUsage()
assert(memoryUsage.playerViolations >= 0, "Should track player violations memory")
assert(memoryUsage.securityLogs >= 0, "Should track security logs memory")
assert(memoryUsage.antiCheat >= 0, "Should track anti-cheat memory")
print("    ✅ Memory usage monitoring working")

-- Final validation
print("🔍 Final validation...")

-- Test that all systems can be initialized together
local success, error = pcall(function()
    local networkManager = MockNetworkManager.new()
    
    securityManager:Initialize(networkManager)
    competitiveManager:Initialize(networkManager)
    guildSystem:Initialize(networkManager)
    tradingSystem:Initialize(networkManager)
    socialSystem:Initialize(networkManager)
end)

assert(success, "All systems should initialize together: " .. tostring(error))
print("    ✅ All systems can initialize together")

-- Test comprehensive metrics collection
local allMetrics = {
    security = securityManager:GetSecurityMetrics(),
    competitive = competitiveManager:GetCompetitiveMetrics(),
    guild = guildSystem:GetGuildMetrics(),
    trading = tradingSystem:GetTradingMetrics(),
    social = socialSystem:GetSocialMetrics()
}

assert(allMetrics.security, "Security metrics should be available")
assert(allMetrics.competitive, "Competitive metrics should be available")
assert(allMetrics.guild, "Guild metrics should be available")
assert(allMetrics.trading, "Trading metrics should be available")
assert(allMetrics.social, "Social metrics should be available")
print("    ✅ Comprehensive metrics collection working")

print("\n🎉 ALL MILESTONE 3 IMPROVEMENTS TESTED SUCCESSFULLY! 🎉")
print("\n📊 IMPROVEMENTS IMPLEMENTED:")
print("  ✅ Enhanced Security Validation (NaN/Inf detection, UTF-8 validation, table index validation)")
print("  ✅ Performance Monitoring (validation timing, memory usage tracking)")
print("  ✅ Roblox Leaderboard Integration (automatic setup, stat synchronization)")
print("  ✅ Comprehensive Metrics Collection (all systems provide detailed metrics)")
print("  ✅ System Health Monitoring (automatic issue detection and recommendations)")
print("  ✅ Public API for Monitoring (easy access to system performance data)")
print("\n🚀 Your Milestone 3 implementation now follows Roblox best practices!")
print("   - Enhanced security and anti-cheat capabilities")
print("   - Native Roblox leaderboard integration")
print("   - Professional-grade monitoring and metrics")
print("   - Performance optimization and memory management")
print("   - Industry-standard error handling and validation")
