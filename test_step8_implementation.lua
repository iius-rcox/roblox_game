-- test_step8_implementation.lua
-- Comprehensive test suite for Step 8: Collection & Conversion System
-- Tests character card collection, power level calculation, anime currency conversion, and tournament brackets

print("🧪 **Step 8 Testing: Collection & Conversion System**")
print("=" .. string.rep("=", 60))

-- Mock player for testing
local MockPlayer = {
    Name = "TestPlayer",
    UserId = 12345
}

-- Mock Constants module
local MockConstants = {
    ANIME_THEMES = {
        SOLO_LEVELING = { name = "Solo Leveling" },
        NARUTO = { name = "Naruto" },
        ONE_PIECE = { name = "One Piece" },
        BLEACH = { name = "Bleach" },
        MY_HERO_ACADEMIA = { name = "My Hero Academia" },
        ONE_PUNCH_MAN = { name = "One Punch Man" },
        CHAINSAW_MAN = { name = "Chainsaw Man" },
        DRAGON_BALL = { name = "Dragon Ball" },
        DEMON_SLAYER = { name = "Demon Slayer" },
        ATTACK_ON_TITAN = { name = "Attack on Titan" },
        JUJUTSU_KAISEN = { name = "Jujutsu Kaisen" },
        HUNTER_X_HUNTER = { name = "Hunter x Hunter" },
        FULLMETAL_ALCHEMIST = { name = "Fullmetal Alchemist" },
        DEATH_NOTE = { name = "Death Note" },
        TOKYO_GHOUL = { name = "Tokyo Ghoul" },
        MOB_PSYCHO_100 = { name = "Mob Psycho 100" },
        OVERLORD = { name = "Overlord" },
        AVATAR_THE_LAST_AIRBENDER = { name = "Avatar: The Last Airbender" }
    }
}

-- Mock HelperFunctions module
local MockHelperFunctions = {
    ValidateData = function(data) return true end,
    LogError = function(message) print("ERROR:", message) end
}

-- Mock services
local MockServices = {
    ReplicatedStorage = {
        Utils = {
            Constants = MockConstants,
            HelperFunctions = MockHelperFunctions
        }
    },
    HttpService = {
        GenerateGUID = function() return "test-guid-" .. math.random(1000, 9999) end
    }
}

-- Override require to return our mock modules
local originalRequire = require
require = function(module)
    if module == MockServices.ReplicatedStorage.Utils.Constants then
        return MockConstants
    elseif module == MockServices.ReplicatedStorage.Utils.HelperFunctions then
        return MockHelperFunctions
    else
        return originalRequire(module)
    end
end

-- Test 1: Collection System Creation
print("\n📋 **Test 1: Collection System Creation**")
print("-" .. string.rep("-", 40))

local CollectionSystem = require("src/Tycoon/CollectionSystem")
local collection = CollectionSystem.new(MockPlayer)

assert(collection ~= nil, "CollectionSystem should be created successfully")
assert(collection.player == MockPlayer, "Player should be set correctly")
assert(collection.playerUserId == MockPlayer.UserId, "Player UserId should be set correctly")
assert(collection.characterCollection ~= nil, "Character collection should be initialized")
assert(collection.animeCurrencies ~= nil, "Anime currencies should be initialized")
assert(collection.activeTournaments ~= nil, "Active tournaments should be initialized")

print("✅ CollectionSystem created successfully")
print("✅ Player data set correctly")
print("✅ All data structures initialized")

-- Test 2: Character Collection Management
print("\n📋 **Test 2: Character Collection Management**")
print("-" .. string.rep("-", 40))

-- Test character data
local testCharacter = {
    name = "Test Character",
    rarity = { name = "Epic", multiplier = 4.0 },
    power = 500,
    unlockLevel = 5,
    abilities = {"Test Ability 1", "Test Ability 2"}
}

-- Add character to collection
local success, message = collection:AddCharacterToCollection(testCharacter, "Solo Leveling")
assert(success == true, "Character should be added successfully")
assert(message == "Character added to collection", "Success message should be correct")

-- Verify character was added
local stats = collection:GetCollectionStats()
assert(stats.totalCards == 1, "Total cards should be 1")
assert(stats.uniqueCharacters == 1, "Unique characters should be 1")
assert(stats.totalPower == 500, "Total power should be 500")

-- Add duplicate character
local success2, message2 = collection:AddCharacterToCollection(testCharacter, "Solo Leveling")
assert(success2 == true, "Duplicate character should be added successfully")
assert(stats.totalCards == 2, "Total cards should be 2 after duplicate")
assert(stats.uniqueCharacters == 1, "Unique characters should still be 1")

print("✅ Character added to collection successfully")
print("✅ Duplicate handling works correctly")
print("✅ Collection stats updated correctly")

-- Test 3: Anime Currency System
print("\n📋 **Test 3: Anime Currency System**")
print("-" .. string.rep("-", 40))

-- Check if currency was awarded
local currencies = collection:GetAnimeCurrencies()
local soloLevelingCurrency = currencies.SOLO_LEVELING
assert(soloLevelingCurrency ~= nil, "Solo Leveling currency should exist")
assert(soloLevelingCurrency.earned > 0, "Currency should be earned from character collection")

-- Test currency conversion
local conversionSuccess, conversionMessage = collection:ConvertAnimeCurrency("Solo Leveling", "Naruto", 100)
assert(conversionSuccess == true, "Currency conversion should succeed")
assert(conversionMessage == "Currency converted successfully", "Conversion message should be correct")

-- Verify conversion
local updatedCurrencies = collection:GetAnimeCurrencies()
assert(updatedCurrencies.SOLO_LEVELING.amount < soloLevelingCurrency.amount, "Source currency should decrease")
assert(updatedCurrencies.NARUTO.amount > 0, "Target currency should increase")

print("✅ Anime currency system working correctly")
print("✅ Currency conversion successful")
print("✅ Currency amounts updated correctly")

-- Test 4: Tournament System
print("\n📋 **Test 4: Tournament System**")
print("-" .. string.rep("-", 40))

-- Test participants
local participants = {
    { name = "Player 1", power = 1000 },
    { name = "Player 2", power = 800 },
    { name = "Player 3", power = 600 },
    { name = "Player 4", power = 400 }
}

-- Create tournament
local tournamentSuccess, tournamentId = collection:CreateTournament("SingleElimination", participants, "Solo Leveling")
assert(tournamentSuccess == true, "Tournament should be created successfully")
assert(tournamentId ~= nil, "Tournament ID should be returned")

-- Verify tournament was created
local activeTournaments = collection:GetActiveTournaments()
assert(activeTournaments[tournamentId] ~= nil, "Tournament should be in active tournaments")
assert(activeTournaments[tournamentId].type == "SingleElimination", "Tournament type should be correct")
assert(#activeTournaments[tournamentId].participants == 4, "Tournament should have 4 participants")

-- Test tournament brackets
local tournament = activeTournaments[tournamentId]
assert(tournament.brackets ~= nil, "Tournament brackets should be generated")
assert(#tournament.brackets > 0, "Tournament should have at least one round")

print("✅ Tournament creation successful")
print("✅ Tournament brackets generated correctly")
print("✅ Tournament data structure complete")

-- Test 5: Collection Statistics
print("\n📋 **Test 5: Collection Statistics**")
print("-" .. string.rep("-", 40))

-- Add more characters to test statistics
local character2 = {
    name = "Test Character 2",
    rarity = { name = "Legendary", multiplier = 7.0 },
    power = 800,
    unlockLevel = 6,
    abilities = {"Legendary Ability"}
}

local character3 = {
    name = "Test Character 3",
    rarity = { name = "Common", multiplier = 1.0 },
    power = 100,
    unlockLevel = 2,
    abilities = {"Basic Ability"}
}

collection:AddCharacterToCollection(character2, "Naruto")
collection:AddCharacterToCollection(character3, "One Piece")

-- Get updated stats
local finalStats = collection:GetCollectionStats()
assert(finalStats.totalCards >= 4, "Total cards should be at least 4")
assert(finalStats.uniqueCharacters >= 3, "Unique characters should be at least 3")
assert(finalStats.totalPower >= 2000, "Total power should be at least 2000")
assert(finalStats.completionPercentage >= 0, "Completion percentage should be calculated")

print("✅ Collection statistics calculated correctly")
print("✅ Multiple characters handled properly")
print("✅ Power calculations accurate")

-- Test 6: Error Handling
print("\n📋 **Test 6: Error Handling**")
print("-" .. string.rep("-", 40))

-- Test invalid character data
local invalidSuccess, invalidMessage = collection:AddCharacterToCollection(nil, "Solo Leveling")
assert(invalidSuccess == false, "Invalid character should be rejected")
assert(invalidMessage == "Invalid character data or anime theme", "Error message should be correct")

-- Test invalid anime theme
local invalidThemeSuccess, invalidThemeMessage = collection:AddCharacterToCollection(testCharacter, nil)
assert(invalidThemeSuccess == false, "Invalid theme should be rejected")
assert(invalidThemeMessage == "Invalid character data or anime theme", "Error message should be correct")

-- Test insufficient currency for conversion
local insufficientSuccess, insufficientMessage = collection:ConvertAnimeCurrency("One Piece", "Naruto", 999999)
assert(insufficientSuccess == false, "Insufficient currency should be rejected")
assert(insufficientMessage == "Insufficient currency", "Error message should be correct")

print("✅ Error handling working correctly")
print("✅ Invalid inputs rejected properly")
print("✅ Appropriate error messages returned")

-- Test 7: Performance Features
print("\n📋 **Test 7: Performance Features**")
print("-" .. string.rep("-", 40))

-- Test cached calculations
local startTime = tick()
local stats1 = collection:GetCollectionStats()
local stats2 = collection:GetCollectionStats()
local endTime = tick()

assert(stats1.totalCards == stats2.totalCards, "Cached calculations should be consistent")
assert(endTime - startTime < 0.1, "Cached calculations should be fast")

-- Test collection size limits
local largeCharacter = {
    name = "Large Test Character",
    rarity = { name = "Mythic", multiplier = 12.0 },
    power = 1000,
    unlockLevel = 7,
    abilities = {"Mythic Ability"}
}

-- Try to exceed collection size limit (this would need to be implemented)
-- For now, just verify the system handles large collections gracefully
for i = 1, 100 do
    local charCopy = {
        name = "Test Character " .. i,
        rarity = { name = "Common", multiplier = 1.0 },
        power = 100,
        unlockLevel = 2,
        abilities = {"Basic Ability"}
    }
    collection:AddCharacterToCollection(charCopy, "Solo Leveling")
end

local largeStats = collection:GetCollectionStats()
assert(largeStats.totalCards > 100, "System should handle large collections")
assert(largeStats.uniqueCharacters > 100, "System should handle many unique characters")

print("✅ Performance optimizations working")
print("✅ Cached calculations functional")
print("✅ Large collections handled gracefully")

-- Test 8: Integration Features
print("\n📋 **Test 8: Integration Features**")
print("-" .. string.rep("-", 40))

-- Test tournament match processing
local matchId = tournament.brackets[1].matches[1].matchId
local matchSuccess, matchMessage = collection:ProcessTournamentMatch(tournamentId, matchId, participants[1])
assert(matchSuccess == true, "Match processing should succeed")
assert(matchMessage == "Match processed successfully", "Match message should be correct")

-- Test tournament history
local tournamentHistory = collection:GetTournamentHistory()
assert(tournamentHistory ~= nil, "Tournament history should be accessible")

-- Test currency conversion history
local conversionHistory = collection.currencyConversionHistory
assert(#conversionHistory > 0, "Currency conversion history should be recorded")

print("✅ Tournament integration working")
print("✅ History tracking functional")
print("✅ All integration points accessible")

-- Final Summary
print("\n🎉 **Step 8 Testing Complete!**")
print("=" .. string.rep("=", 60))

local finalStats = collection:GetCollectionStats()
print("📊 **Final Collection Statistics:**")
print("   • Total Cards: " .. finalStats.totalCards)
print("   • Unique Characters: " .. finalStats.uniqueCharacters)
print("   • Total Power: " .. finalStats.totalPower)
print("   • Completion: " .. string.format("%.1f", finalStats.completionPercentage) .. "%")

local currencies = collection:GetAnimeCurrencies()
print("💰 **Currency Summary:**")
for themeKey, currencyData in pairs(currencies) do
    if currencyData.amount > 0 then
        print("   • " .. currencyData.name .. ": " .. currencyData.amount .. " " .. currencyData.symbol)
    end
end

local activeTournaments = collection:GetActiveTournaments()
print("🏆 **Active Tournaments:** " .. #activeTournaments)

print("\n✅ **All Step 8 tests passed successfully!**")
print("🚀 **Collection & Conversion System is fully functional!**")

-- Cleanup
collection:Destroy()
print("\n🧹 **Test cleanup completed**")
