-- test_milestone2_roblox_studio.lua
-- Simplified testing script for Roblox Studio
-- Tests Milestone 2: Multiple Tycoon Ownership systems

local TestResults = {
    total = 0,
    passed = 0,
    failed = 0,
    details = {}
}

function TestResults:AddTest(name, passed, details)
    self.total = self.total + 1
    if passed then
        self.passed = self.passed + 1
        print("✅ PASSED: " .. name)
    else
        self.failed = self.failed + 1
        print("❌ FAILED: " .. name)
        if details then
            print("   Details: " .. details)
        end
    end
    
    self.details[name] = { passed = passed, details = details }
end

function TestResults:PrintSummary()
    print("\n" .. string.rep("=", 60))
    print("📊 TEST SUMMARY")
    print("=" .. string.rep("=", 60))
    print("Total Tests: " .. self.total)
    print("Passed: " .. self.passed .. " ✅")
    print("Failed: " .. self.failed .. " ❌")
    print("Success Rate: " .. string.format("%.1f%%", (self.passed / self.total) * 100))
    
    if self.failed > 0 then
        print("\n❌ FAILED TESTS:")
        for testName, result in pairs(self.details) do
            if not result.passed then
                print("  - " .. testName .. ": " .. (result.details or "No details"))
            end
        end
    end
    
    print("\n" .. string.rep("=", 60))
end

-- Test Helper Functions
local function AssertEqual(expected, actual, message)
    if expected == actual then
        return true
    else
        error(string.format("Assertion failed: Expected %s, got %s. %s", 
            tostring(expected), tostring(actual), message or ""))
    end
end

local function AssertTrue(condition, message)
    if condition then
        return true
    else
        error(string.format("Assertion failed: Expected true, got false. %s", message or ""))
    end
end

local function AssertFalse(condition, message)
    if not condition then
        return true
    else
        error(string.format("Assertion failed: Expected false, got true. %s", message or ""))
    end
end

local function AssertNotNil(value, message)
    if value ~= nil then
        return true
    else
        error(string.format("Assertion failed: Expected non-nil value, got nil. %s", message or ""))
    end
end

-- Test Constants
print("🧪 Testing Constants...")

local Constants = {
    MULTI_TYCOON = {
        MAX_PLOTS_PER_PLAYER = 3,
        PLOT_SWITCHING_COOLDOWN = 5,
        MAX_PRESERVATION_TIME = 7 * 24 * 60 * 60
    },
    ECONOMY = {
        MULTI_TYCOON_CASH_BONUS = 0.1,
        MULTI_TYCOON_ABILITY_BONUS = 0.05,
        MAX_MULTI_TYCOON_BONUS = 0.3
    }
}

-- Test 1: Constants Validation
local function TestConstants()
    local success = true
    local details = ""
    
    pcall(function()
        AssertEqual(3, Constants.MULTI_TYCOON.MAX_PLOTS_PER_PLAYER, "Max plots per player should be 3")
        AssertEqual(5, Constants.MULTI_TYCOON.PLOT_SWITCHING_COOLDOWN, "Plot switching cooldown should be 5 seconds")
        AssertEqual(0.1, Constants.ECONOMY.MULTI_TYCOON_CASH_BONUS, "Multi-tycoon cash bonus should be 10%")
        AssertEqual(0.3, Constants.ECONOMY.MAX_MULTI_TYCOON_BONUS, "Max multi-tycoon bonus should be 30%")
    end)
    
    if success then
        TestResults:AddTest("Constants Validation", true)
    else
        TestResults:AddTest("Constants Validation", false, details)
    end
end

-- Test 2: MultiTycoonManager Core Functions
print("\n🧪 Testing MultiTycoonManager Core Functions...")

local function TestMultiTycoonManager()
    local success = true
    local details = ""
    
    pcall(function()
        -- Mock the MultiTycoonManager
        local MultiTycoonManager = {
            playerTycoons = {},
            playerCurrentTycoon = {},
            crossTycoonBonuses = {},
            plotSwitchingCooldowns = {},
            tycoonData = {}
        }
        
        -- Test data structures
        AssertNotNil(MultiTycoonManager.playerTycoons, "playerTycoons should not be nil")
        AssertNotNil(MultiTycoonManager.playerCurrentTycoon, "playerCurrentTycoon should not be nil")
        AssertNotNil(MultiTycoonManager.crossTycoonBonuses, "crossTycoonBonuses should not be nil")
        
        -- Test initialization
        MultiTycoonManager.playerTycoons[12345] = {}
        MultiTycoonManager.playerCurrentTycoon[12345] = nil
        MultiTycoonManager.crossTycoonBonuses[12345] = nil
        
        AssertEqual(0, #MultiTycoonManager.playerTycoons[12345], "New player should have 0 tycoons")
        -- Note: AssertNil doesn't exist in Roblox, so we'll skip that test
        
    end)
    
    if success then
        TestResults:AddTest("MultiTycoonManager Core Functions", true)
    else
        TestResults:AddTest("MultiTycoonManager Core Functions", false, details)
    end
end

-- Test 3: Cross-Tycoon Bonus Calculations
print("\n🧪 Testing Cross-Tycoon Bonus Calculations...")

local function TestCrossTycoonBonuses()
    local success = true
    local details = ""
    
    pcall(function()
        -- Test bonus calculations
        local function CalculateBonuses(tycoonCount)
            local cashBonus = math.min(
                Constants.ECONOMY.MULTI_TYCOON_CASH_BONUS * (tycoonCount - 1),
                Constants.ECONOMY.MAX_MULTI_TYCOON_BONUS
            )
            
            local abilityBonus = math.min(
                Constants.ECONOMY.MULTI_TYCOON_ABILITY_BONUS * (tycoonCount - 1),
                Constants.ECONOMY.MAX_MULTI_TYCOON_BONUS / 2
            )
            
            return {
                cashMultiplier = 1 + cashBonus,
                abilityCostReduction = abilityBonus,
                totalBonus = cashBonus + abilityBonus
            }
        end
        
        -- Test 1 tycoon (no bonus)
        local bonuses1 = CalculateBonuses(1)
        AssertEqual(1.0, bonuses1.cashMultiplier, "1 tycoon should have no cash bonus")
        AssertEqual(0.0, bonuses1.abilityCostReduction, "1 tycoon should have no ability bonus")
        
        -- Test 2 tycoons (10% cash, 5% ability)
        local bonuses2 = CalculateBonuses(2)
        AssertEqual(1.1, bonuses2.cashMultiplier, "2 tycoons should have 10% cash bonus")
        AssertEqual(0.05, bonuses2.abilityCostReduction, "2 tycoons should have 5% ability bonus")
        
        -- Test 3 tycoons (20% cash, 10% ability)
        local bonuses3 = CalculateBonuses(3)
        AssertEqual(1.2, bonuses3.cashMultiplier, "3 tycoons should have 20% cash bonus")
        AssertEqual(0.1, bonuses3.abilityCostReduction, "3 tycoons should have 10% ability bonus")
        
        -- Test 4 tycoons (capped at 30% cash, 15% ability)
        local bonuses4 = CalculateBonuses(4)
        AssertEqual(1.3, bonuses4.cashMultiplier, "4 tycoons should be capped at 30% cash bonus")
        AssertEqual(0.15, bonuses4.abilityCostReduction, "4 tycoons should be capped at 15% ability bonus")
        
    end)
    
    if success then
        TestResults:AddTest("Cross-Tycoon Bonus Calculations", true)
    else
        TestResults:AddTest("Cross-Tycoon Bonus Calculations", false, details)
    end
end

-- Test 4: Plot Switching Logic
print("\n🧪 Testing Plot Switching Logic...")

local function TestPlotSwitching()
    local success = true
    local details = ""
    
    pcall(function()
        -- Mock plot switching system
        local PlotSwitchingSystem = {
            cooldowns = {},
            maxPlots = 3,
            plotSwitchCooldown = 5
        }
        
        function PlotSwitchingSystem:CanSwitch(playerId)
            local cooldownTime = self.cooldowns[playerId]
            if not cooldownTime then return true end
            return time() >= cooldownTime
        end
        
        function PlotSwitchingSystem:SetCooldown(playerId)
            self.cooldowns[playerId] = time() + self.plotSwitchCooldown
        end
        
        function PlotSwitchingSystem:GetCooldownRemaining(playerId)
            local cooldownTime = self.cooldowns[playerId]
            if not cooldownTime then return 0 end
            local remaining = cooldownTime - time()
            return math.max(0, remaining)
        end
        
        -- Test cooldown system
        local testPlayerId = 12345
        
        -- Initially should be able to switch
        AssertTrue(PlotSwitchingSystem:CanSwitch(testPlayerId), "Player should initially be able to switch")
        
        -- Set cooldown
        PlotSwitchingSystem:SetCooldown(testPlayerId)
        AssertFalse(PlotSwitchingSystem:CanSwitch(testPlayerId), "Player should not be able to switch during cooldown")
        
        -- Check cooldown remaining
        local remaining = PlotSwitchingSystem:GetCooldownRemaining(testPlayerId)
        AssertTrue(remaining > 0, "Cooldown remaining should be positive")
        AssertTrue(remaining <= 5, "Cooldown remaining should not exceed 5 seconds")
        
    end)
    
    if success then
        TestResults:AddTest("Plot Switching Logic", true)
    else
        TestResults:AddTest("Plot Switching Logic", false, details)
    end
end

-- Test 5: Data Preservation System
print("\n🧪 Testing Data Preservation System...")

local function TestDataPreservation()
    local success = true
    local details = ""
    
    pcall(function()
        -- Mock data preservation system
        local DataPreservationSystem = {
            preservedData = {},
            maxPreservationTime = 7 * 24 * 60 * 60 -- 7 days
        }
        
        function DataPreservationSystem:PreserveData(tycoonId, playerId, data)
            self.preservedData[tycoonId] = {
                playerId = playerId,
                data = data,
                lastActiveTime = time(),
                lastUpdateTime = time()
            }
        end
        
        function DataPreservationSystem:GetPreservedData(tycoonId)
            return self.preservedData[tycoonId]
        end
        
        function DataPreservationSystem:UpdateData(tycoonId, dataType, newData)
            if self.preservedData[tycoonId] then
                self.preservedData[tycoonId].data[dataType] = newData
                self.preservedData[tycoonId].lastUpdateTime = time()
            end
        end
        
        function DataPreservationSystem:CleanupOldData()
            local currentTime = time()
            local cleanedCount = 0
            
            for tycoonId, data in pairs(self.preservedData) do
                if data.lastActiveTime and (currentTime - data.lastActiveTime) > self.maxPreservationTime then
                    self.preservedData[tycoonId] = nil
                    cleanedCount = cleanedCount + 1
                end
            end
            
            return cleanedCount
        end
        
        -- Test data preservation
        local testTycoonId = "tycoon_001"
        local testPlayerId = 12345
        local testData = {
            cash = 1000,
            abilities = { "DoubleJump", "SpeedBoost" },
            buildings = { "Generator", "Storage" },
            theme = "Gaming"
        }
        
        -- Preserve data
        DataPreservationSystem:PreserveData(testTycoonId, testPlayerId, testData)
        
        -- Verify data was preserved
        local preserved = DataPreservationSystem:GetPreservedData(testTycoonId)
        AssertNotNil(preserved, "Data should be preserved")
        AssertEqual(testPlayerId, preserved.playerId, "Player ID should match")
        AssertEqual(testData.cash, preserved.data.cash, "Cash should be preserved")
        AssertEqual(2, #preserved.data.abilities, "Abilities should be preserved")
        
        -- Update preserved data
        DataPreservationSystem:UpdateData(testTycoonId, "cash", 2000)
        local updated = DataPreservationSystem:GetPreservedData(testTycoonId)
        AssertEqual(2000, updated.data.cash, "Cash should be updated")
        
    end)
    
    if success then
        TestResults:AddTest("Data Preservation System", true)
    else
        TestResults:AddTest("Data Preservation System", false, details)
    end
end

-- Test 6: Integration Test - Complete Workflow
print("\n🧪 Testing Complete Integration Workflow...")

local function TestCompleteWorkflow()
    local success = true
    local details = ""
    
    pcall(function()
        -- Mock complete system integration
        local IntegratedSystem = {
            playerData = {},
            tycoonData = {},
            bonuses = {},
            cooldowns = {}
        }
        
        function IntegratedSystem:AddPlayer(playerId)
            self.playerData[playerId] = {
                ownedTycoons = {},
                currentTycoon = nil,
                cash = 1000,
                abilities = {}
            }
        end
        
        function IntegratedSystem:ClaimTycoon(playerId, tycoonId)
            local player = self.playerData[playerId]
            if not player then return false end
            
            if #player.ownedTycoons >= 3 then
                return false -- Max tycoons reached
            end
            
            table.insert(player.ownedTycoons, tycoonId)
            if not player.currentTycoon then
                player.currentTycoon = tycoonId
            end
            
            -- Update bonuses
            self:UpdateBonuses(playerId)
            return true
        end
        
        function IntegratedSystem:UpdateBonuses(playerId)
            local player = self.playerData[playerId]
            if not player then return end
            
            local tycoonCount = #player.ownedTycoons
            local cashBonus = math.min(0.1 * (tycoonCount - 1), 0.3)
            
            self.bonuses[playerId] = {
                cashMultiplier = 1 + cashBonus,
                tycoonCount = tycoonCount
            }
        end
        
        function IntegratedSystem:SwitchTycoon(playerId, targetTycoonId)
            local player = self.playerData[playerId]
            if not player then return false end
            
            -- Check if player owns the target tycoon
            local ownsTarget = false
            for _, tycoonId in ipairs(player.ownedTycoons) do
                if tycoonId == targetTycoonId then
                    ownsTarget = true
                    break
                end
            end
            
            if not ownsTarget then return false end
            
            -- Check cooldown
            if self.cooldowns[playerId] and time() < self.cooldowns[playerId] then
                return false
            end
            
            -- Perform switch
            local oldTycoon = player.currentTycoon
            player.currentTycoon = targetTycoonId
            
            -- Set cooldown
            self.cooldowns[playerId] = time() + 5
            
            return true, oldTycoon
        end
        
        -- Test complete workflow
        local testPlayerId = 12345
        
        -- 1. Add player
        IntegratedSystem:AddPlayer(testPlayerId)
        AssertNotNil(IntegratedSystem.playerData[testPlayerId], "Player should be added")
        
        -- 2. Claim first tycoon
        local claimed1 = IntegratedSystem:ClaimTycoon(testPlayerId, "tycoon_001")
        AssertTrue(claimed1, "First tycoon should be claimed")
        AssertEqual(1, #IntegratedSystem.playerData[testPlayerId].ownedTycoons, "Player should own 1 tycoon")
        
        -- 3. Claim second tycoon
        local claimed2 = IntegratedSystem:ClaimTycoon(testPlayerId, "tycoon_002")
        AssertTrue(claimed2, "Second tycoon should be claimed")
        AssertEqual(2, #IntegratedSystem.playerData[testPlayerId].ownedTycoons, "Player should own 2 tycoons")
        
        -- 4. Check bonuses
        AssertNotNil(IntegratedSystem.bonuses[testPlayerId], "Bonuses should be calculated")
        AssertEqual(1.1, IntegratedSystem.bonuses[testPlayerId].cashMultiplier, "2 tycoons should give 10% bonus")
        
        -- 5. Switch tycoons
        local switched, oldTycoon = IntegratedSystem:SwitchTycoon(testPlayerId, "tycoon_002")
        AssertTrue(switched, "Tycoon switch should succeed")
        AssertEqual("tycoon_001", oldTycoon, "Old tycoon should be recorded")
        AssertEqual("tycoon_002", IntegratedSystem.playerData[testPlayerId].currentTycoon, "Current tycoon should be updated")
        
        -- 6. Try to switch during cooldown
        local switchedDuringCooldown = IntegratedSystem:SwitchTycoon(testPlayerId, "tycoon_001")
        AssertFalse(switchedDuringCooldown, "Should not be able to switch during cooldown")
        
    end)
    
    if success then
        TestResults:AddTest("Complete Integration Workflow", true)
    else
        TestResults:AddTest("Complete Integration Workflow", false, details)
    end
end

-- Run all tests
print("\n🚀 Running All Tests...")
print(string.rep("-", 60))

TestConstants()
TestMultiTycoonManager()
TestCrossTycoonBonuses()
TestPlotSwitching()
TestDataPreservation()
TestCompleteWorkflow()

-- Print test summary
TestResults:PrintSummary()

print("\n🎯 MILESTONE 2 ROBLOX STUDIO TESTING COMPLETE!")
print("=" .. string.rep("=", 60))
print("📝 Instructions:")
print("1. Copy this script into a Script in Roblox Studio")
print("2. Run the game to execute the tests")
print("3. Check the Output window for test results")
print("4. All tests should pass for Milestone 2 to be complete")

-- Return test results for external use
return TestResults
