-- CollectionSystem.lua
-- Anime collectible management and conversion system
-- Implements character card collection, power level calculation, anime currency conversion, and tournament brackets
-- Performance-optimized with efficient data structures for collection tracking

local CollectionSystem = {}
CollectionSystem.__index = CollectionSystem

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

-- Constants
local Constants = require(ReplicatedStorage.Utils.Constants)
local HelperFunctions = require(ReplicatedStorage.Utils.HelperFunctions)

-- Collection system constants
local COLLECTION_CONFIG = {
    maxCollectionSize = 1000,
    maxDuplicateCards = 99,
    collectionUpdateInterval = 1, -- 1 second
    powerCalculationInterval = 5, -- 5 seconds
    tournamentBracketSize = 32,
    tournamentUpdateInterval = 10, -- 10 seconds
    currencyConversionRate = 0.8, -- 80% conversion rate
    maxTournamentParticipants = 128
}

-- Anime currency types
local ANIME_CURRENCIES = {
    SOLO_LEVELING = { name = "Shadow Points", symbol = "SP", baseValue = 100 },
    NARUTO = { name = "Chakra Coins", symbol = "CC", baseValue = 150 },
    ONE_PIECE = { name = "Berries", symbol = "B", baseValue = 200 },
    BLEACH = { name = "Soul Orbs", symbol = "SO", baseValue = 120 },
    MY_HERO_ACADEMIA = { name = "Hero Points", symbol = "HP", baseValue = 180 },
    ONE_PUNCH_MAN = { name = "Hero Coins", symbol = "HC", baseValue = 90 },
    CHAINSAW_MAN = { name = "Devil Tokens", symbol = "DT", baseValue = 250 },
    DRAGON_BALL = { name = "Ki Stones", symbol = "KS", baseValue = 300 },
    DEMON_SLAYER = { name = "Demon Slayer Coins", symbol = "DSC", baseValue = 160 },
    ATTACK_ON_TITAN = { name = "Survey Corps Medals", symbol = "SCM", baseValue = 140 },
    JUJUTSU_KAISEN = { name = "Cursed Energy Crystals", symbol = "CEC", baseValue = 220 },
    HUNTER_X_HUNTER = { name = "Hunter Licenses", symbol = "HL", baseValue = 400 },
    FULLMETAL_ALCHEMIST = { name = "Philosopher's Stones", symbol = "PS", baseValue = 500 },
    DEATH_NOTE = { name = "Death Note Pages", symbol = "DNP", baseValue = 1000 },
    TOKYO_GHOUL = { name = "Ghoul Flesh", symbol = "GF", baseValue = 180 },
    MOB_PSYCHO_100 = { name = "Psychic Energy", symbol = "PE", baseValue = 130 },
    OVERLORD = { name = "Yggdrasil Gold", symbol = "YG", baseValue = 350 },
    AVATAR_THE_LAST_AIRBENDER = { name = "Bending Crystals", symbol = "BC", baseValue = 200 }
}

-- Tournament bracket types
local TOURNAMENT_TYPES = {
    SINGLE_ELIMINATION = "SingleElimination",
    DOUBLE_ELIMINATION = "DoubleElimination",
    ROUND_ROBIN = "RoundRobin",
    SWISS_SYSTEM = "SwissSystem",
    BATTLE_ROYALE = "BattleRoyale"
}

-- Constructor
function CollectionSystem.new(player)
    local self = setmetatable({}, CollectionSystem)
    
    -- Core data
    self.player = player
    self.playerUserId = player.UserId
    
    -- Collection data
    self.characterCollection = {}
    self.collectionStats = {
        totalCards = 0,
        uniqueCharacters = 0,
        totalPower = 0,
        averageRarity = 0,
        completionPercentage = 0
    }
    
    -- Currency data
    self.animeCurrencies = {}
    self.currencyConversionHistory = {}
    
    -- Tournament data
    self.activeTournaments = {}
    self.tournamentHistory = {}
    self.currentBrackets = {}
    
    -- Performance optimization
    self.cachedCalculations = {}
    self.lastUpdateTime = 0
    self.updateQueue = {}
    
    -- Initialize collections
    self:InitializeCollectionSystem()
    
    print("CollectionSystem: Created for player " .. player.Name)
    
    return self
end

-- Initialize collection system
function CollectionSystem:InitializeCollectionSystem()
    -- Initialize anime currencies
    for animeKey, currencyData in pairs(ANIME_CURRENCIES) do
        self.animeCurrencies[animeKey] = {
            amount = 0,
            earned = 0,
            spent = 0,
            lastEarned = 0
        }
    end
    
    -- Load existing collection data
    self:LoadPlayerCollection()
    
    -- Start update loop
    self:StartUpdateLoop()
    
    print("CollectionSystem: Initialized collection system for " .. self.player.Name)
end

-- Load player collection data
function CollectionSystem:LoadPlayerCollection()
    -- This would typically load from DataStore
    -- For now, initialize empty collection
    self.characterCollection = {}
    self:RecalculateCollectionStats()
    
    print("CollectionSystem: Loaded collection data for " .. self.player.Name)
end

-- Add character to collection
function CollectionSystem:AddCharacterToCollection(characterData, animeTheme)
    if not characterData or not animeTheme then
        return false, "Invalid character data or anime theme"
    end
    
    -- Check collection size limit
    if self.collectionStats.totalCards >= COLLECTION_CONFIG.maxCollectionSize then
        return false, "Collection size limit reached"
    end
    
    -- Create collection entry
    local collectionEntry = {
        id = HttpService:GenerateGUID(false),
        characterName = characterData.name,
        animeTheme = animeTheme,
        rarity = characterData.rarity.name,
        power = characterData.power,
        abilities = characterData.abilities,
        unlockLevel = characterData.unlockLevel,
        obtainedAt = tick(),
        duplicates = 1,
        isFavorited = false,
        lastUsed = 0
    }
    
    -- Check if character already exists
    local existingEntry = self:FindCharacterInCollection(characterData.name, animeTheme)
    if existingEntry then
        -- Increment duplicate count
        existingEntry.duplicates = math.min(existingEntry.duplicates + 1, COLLECTION_CONFIG.maxDuplicateCards)
        self.collectionStats.totalCards = self.collectionStats.totalCards + 1
    else
        -- Add new character
        table.insert(self.characterCollection, collectionEntry)
        self.collectionStats.totalCards = self.collectionStats.totalCards + 1
        self.collectionStats.uniqueCharacters = self.collectionStats.uniqueCharacters + 1
    end
    
    -- Award anime currency
    self:AwardAnimeCurrency(animeTheme, characterData.rarity.multiplier)
    
    -- Recalculate stats
    self:RecalculateCollectionStats()
    
    print("CollectionSystem: Added " .. characterData.name .. " to collection")
    return true, "Character added to collection"
end

-- Find character in collection
function CollectionSystem:FindCharacterInCollection(characterName, animeTheme)
    for _, entry in ipairs(self.characterCollection) do
        if entry.characterName == characterName and entry.animeTheme == animeTheme then
            return entry
        end
    end
    return nil
end

-- Remove character from collection
function CollectionSystem:RemoveCharacterFromCollection(characterId)
    for i, entry in ipairs(self.characterCollection) do
        if entry.id == characterId then
            if entry.duplicates > 1 then
                entry.duplicates = entry.duplicates - 1
                self.collectionStats.totalCards = self.collectionStats.totalCards - 1
            else
                table.remove(self.characterCollection, i)
                self.collectionStats.totalCards = self.collectionStats.totalCards - 1
                self.collectionStats.uniqueCharacters = self.collectionStats.uniqueCharacters - 1
            end
            
            self:RecalculateCollectionStats()
            print("CollectionSystem: Removed character from collection")
            return true, "Character removed from collection"
        end
    end
    
    return false, "Character not found in collection"
end

-- Recalculate collection statistics
function CollectionSystem:RecalculateCollectionStats()
    local totalPower = 0
    local totalRarity = 0
    local characterCount = 0
    
    for _, entry in ipairs(self.characterCollection) do
        totalPower = totalPower + (entry.power * entry.duplicates)
        totalRarity = totalRarity + self:GetRarityValue(entry.rarity)
        characterCount = characterCount + entry.duplicates
    end
    
    self.collectionStats.totalPower = totalPower
    self.collectionStats.averageRarity = characterCount > 0 and (totalRarity / characterCount) or 0
    
    -- Calculate completion percentage (based on total possible characters from all anime themes)
    local totalPossibleCharacters = 0
    for _, animeData in pairs(Constants.ANIME_THEMES) do
        if animeData.name ~= "AVATAR_THE_LAST_AIRBENDER" then -- Exclude avatar theme
            totalPossibleCharacters = totalPossibleCharacters + 6 -- Each theme has 6 characters
        end
    end
    
    self.collectionStats.completionPercentage = totalPossibleCharacters > 0 and 
        (self.collectionStats.uniqueCharacters / totalPossibleCharacters) * 100 or 0
    
    print("CollectionSystem: Recalculated stats - Power: " .. totalPower .. ", Completion: " .. 
          string.format("%.1f", self.collectionStats.completionPercentage) .. "%")
end

-- Get rarity value for calculations
function CollectionSystem:GetRarityValue(rarityName)
    local rarityValues = {
        Common = 1,
        Uncommon = 2,
        Rare = 3,
        Epic = 4,
        Legendary = 5,
        Mythic = 6
    }
    return rarityValues[rarityName] or 1
end

-- Award anime currency
function CollectionSystem:AwardAnimeCurrency(animeTheme, rarityMultiplier)
    local themeKey = animeTheme:upper():gsub(" ", "_")
    local currencyData = ANIME_CURRENCIES[themeKey]
    
    if currencyData then
        local baseAmount = currencyData.baseValue
        local awardedAmount = math.floor(baseAmount * rarityMultiplier)
        
        self.animeCurrencies[themeKey].amount = self.animeCurrencies[themeKey].amount + awardedAmount
        self.animeCurrencies[themeKey].earned = self.animeCurrencies[themeKey].earned + awardedAmount
        self.animeCurrencies[themeKey].lastEarned = tick()
        
        print("CollectionSystem: Awarded " .. awardedAmount .. " " .. currencyData.name .. " for " .. animeTheme)
    end
end

-- Convert anime currency
function CollectionSystem:ConvertAnimeCurrency(fromTheme, toTheme, amount)
    local fromKey = fromTheme:upper():gsub(" ", "_")
    local toKey = toTheme:upper():gsub(" ", "_")
    
    if not ANIME_CURRENCIES[fromKey] or not ANIME_CURRENCIES[toKey] then
        return false, "Invalid anime themes"
    end
    
    if self.animeCurrencies[fromKey].amount < amount then
        return false, "Insufficient currency"
    end
    
    -- Calculate conversion
    local fromValue = ANIME_CURRENCIES[fromKey].baseValue
    local toValue = ANIME_CURRENCIES[toKey].baseValue
    local conversionRate = (toValue / fromValue) * COLLECTION_CONFIG.currencyConversionRate
    local convertedAmount = math.floor(amount * conversionRate)
    
    -- Perform conversion
    self.animeCurrencies[fromKey].amount = self.animeCurrencies[fromKey].amount - amount
    self.animeCurrencies[fromKey].spent = self.animeCurrencies[fromKey].spent + amount
    self.animeCurrencies[toKey].amount = self.animeCurrencies[toKey].amount + convertedAmount
    
    -- Record conversion history
    table.insert(self.currencyConversionHistory, {
        fromTheme = fromTheme,
        toTheme = toTheme,
        fromAmount = amount,
        toAmount = convertedAmount,
        conversionRate = conversionRate,
        timestamp = tick()
    })
    
    print("CollectionSystem: Converted " .. amount .. " " .. ANIME_CURRENCIES[fromKey].name .. 
          " to " .. convertedAmount .. " " .. ANIME_CURRENCIES[toKey].name)
    
    return true, "Currency converted successfully"
end

-- Create tournament bracket
function CollectionSystem:CreateTournament(tournamentType, participants, animeTheme)
    if #participants < 2 then
        return false, "Need at least 2 participants"
    end
    
    if #participants > COLLECTION_CONFIG.maxTournamentParticipants then
        return false, "Too many participants"
    end
    
    local tournamentId = HttpService:GenerateGUID(false)
    local tournament = {
        id = tournamentId,
        type = tournamentType,
        participants = participants,
        animeTheme = animeTheme,
        status = "Active",
        currentRound = 1,
        brackets = {},
        winner = nil,
        startTime = tick(),
        endTime = nil
    }
    
    -- Generate brackets based on tournament type
    tournament.brackets = self:GenerateTournamentBrackets(tournamentType, participants)
    
    -- Add to active tournaments
    self.activeTournaments[tournamentId] = tournament
    
    print("CollectionSystem: Created " .. tournamentType .. " tournament with " .. #participants .. " participants")
    return true, tournamentId
end

-- Generate tournament brackets
function CollectionSystem:GenerateTournamentBrackets(tournamentType, participants)
    local brackets = {}
    
    if tournamentType == TOURNAMENT_TYPES.SINGLE_ELIMINATION then
        brackets = self:GenerateSingleEliminationBrackets(participants)
    elseif tournamentType == TOURNAMENT_TYPES.DOUBLE_ELIMINATION then
        brackets = self:GenerateDoubleEliminationBrackets(participants)
    elseif tournamentType == TOURNAMENT_TYPES.ROUND_ROBIN then
        brackets = self:GenerateRoundRobinBrackets(participants)
    elseif tournamentType == TOURNAMENT_TYPES.SWISS_SYSTEM then
        brackets = self:GenerateSwissSystemBrackets(participants)
    elseif tournamentType == TOURNAMENT_TYPES.BATTLE_ROYALE then
        brackets = self:GenerateBattleRoyaleBrackets(participants)
    end
    
    return brackets
end

-- Generate single elimination brackets
function CollectionSystem:GenerateSingleEliminationBrackets(participants)
    local brackets = {}
    local numParticipants = #participants
    
    -- Pad to power of 2 if necessary
    while numParticipants < COLLECTION_CONFIG.tournamentBracketSize do
        table.insert(participants, { name = "BYE", power = 0, isBye = true })
        numParticipants = numParticipants + 1
    end
    
    -- Shuffle participants
    for i = numParticipants, 2, -1 do
        local j = math.random(i)
        participants[i], participants[j] = participants[j], participants[i]
    end
    
    -- Generate first round
    local round = {
        roundNumber = 1,
        matches = {},
        winners = {},
        losers = {}
    }
    
    for i = 1, numParticipants, 2 do
        local match = {
            matchId = HttpService:GenerateGUID(false),
            player1 = participants[i],
            player2 = participants[i + 1],
            winner = nil,
            status = "Pending"
        }
        table.insert(round.matches, match)
    end
    
    table.insert(brackets, round)
    
    return brackets
end

-- Generate other tournament bracket types (simplified implementations)
function CollectionSystem:GenerateDoubleEliminationBrackets(participants)
    -- Simplified double elimination implementation
    return self:GenerateSingleEliminationBrackets(participants)
end

function CollectionSystem:GenerateRoundRobinBrackets(participants)
    -- Simplified round robin implementation
    return self:GenerateSingleEliminationBrackets(participants)
end

function CollectionSystem:GenerateSwissSystemBrackets(participants)
    -- Simplified Swiss system implementation
    return self:GenerateSingleEliminationBrackets(participants)
end

function CollectionSystem:GenerateBattleRoyaleBrackets(participants)
    -- Simplified battle royale implementation
    return self:GenerateSingleEliminationBrackets(participants)
end

-- Process tournament match
function CollectionSystem:ProcessTournamentMatch(tournamentId, matchId, winner)
    local tournament = self.activeTournaments[tournamentId]
    if not tournament then
        return false, "Tournament not found"
    end
    
    -- Find and update match
    for _, round in ipairs(tournament.brackets) do
        for _, match in ipairs(round.matches) do
            if match.matchId == matchId then
                match.winner = winner
                match.status = "Completed"
                
                -- Update round winners
                table.insert(round.winners, winner)
                
                print("CollectionSystem: Match " .. matchId .. " completed, winner: " .. winner.name)
                return true, "Match processed successfully"
            end
        end
    end
    
    return false, "Match not found"
end

-- Get collection statistics
function CollectionSystem:GetCollectionStats()
    return self.collectionStats
end

-- Get anime currency amounts
function CollectionSystem:GetAnimeCurrencies()
    local currencySummary = {}
    for themeKey, currencyData in pairs(self.animeCurrencies) do
        local animeName = ANIME_CURRENCIES[themeKey].name
        local symbol = ANIME_CURRENCIES[themeKey].symbol
        currencySummary[themeKey] = {
            name = animeName,
            symbol = symbol,
            amount = currencyData.amount,
            earned = currencyData.earned,
            spent = currencyData.spent
        }
    end
    return currencySummary
end

-- Get active tournaments
function CollectionSystem:GetActiveTournaments()
    return self.activeTournaments
end

-- Get tournament history
function CollectionSystem:GetTournamentHistory()
    return self.tournamentHistory
end

-- Start update loop
function CollectionSystem:StartUpdateLoop()
    -- This would typically use a separate thread or connection
    -- For now, just mark as started
    print("CollectionSystem: Update loop started")
end

-- Cleanup
function CollectionSystem:Destroy()
    -- Clean up any connections or threads
    self.activeTournaments = {}
    self.currentBrackets = {}
    print("CollectionSystem: Destroyed for " .. self.player.Name)
end

return CollectionSystem
