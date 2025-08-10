-- PowerUpSystem.lua
-- Anime-specific power progression systems with efficient upgrade calculations
-- Implements series-specific power scaling and anime progression paths
-- Performance-optimized with upgrade cost optimization and balancing

local PowerUpSystem = {}
PowerUpSystem.__index = PowerUpSystem

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Constants
local Constants = require(ReplicatedStorage.Utils.Constants)
local HelperFunctions = require(ReplicatedStorage.Utils.HelperFunctions)

-- Power-up type constants
local POWER_UP_TYPES = {
    CHARACTER_ENHANCEMENT = "CharacterEnhancement",
    ABILITY_UPGRADE = "AbilityUpgrade",
    STAT_BOOST = "StatBoost",
    SPECIAL_TECHNIQUE = "SpecialTechnique",
    ULTIMATE_MOVE = "UltimateMove"
}

-- Power-up tier constants
local POWER_UP_TIERS = {
    BASIC = "Basic",
    ADVANCED = "Advanced",
    ELITE = "Elite",
    MASTER = "Master",
    GRANDMASTER = "Grandmaster",
    LEGENDARY = "Legendary"
}

-- Anime-specific power progression systems
local ANIME_POWER_SYSTEMS = {
    SOLO_LEVELING = {
        name = "Solo Leveling",
        progression = {
            { level = 1, name = "E-Rank Hunter", powerMultiplier = 1.0, cost = 100, requirements = {} },
            { level = 2, name = "D-Rank Hunter", powerMultiplier = 2.0, cost = 250, requirements = { power = 100 } },
            { level = 3, name = "C-Rank Hunter", powerMultiplier = 5.0, cost = 500, requirements = { power = 250, kills = 50 } },
            { level = 4, name = "B-Rank Hunter", powerMultiplier = 10.0, cost = 1000, requirements = { power = 500, kills = 100, rank = "C" } },
            { level = 5, name = "A-Rank Hunter", powerMultiplier = 25.0, cost = 2500, requirements = { power = 1000, kills = 200, rank = "B" } },
            { level = 6, name = "S-Rank Hunter", powerMultiplier = 50.0, cost = 5000, requirements = { power = 2500, kills = 500, rank = "A" } },
            { level = 7, name = "Shadow Monarch", powerMultiplier = 100.0, cost = 10000, requirements = { power = 5000, kills = 1000, rank = "S" } }
        },
        specialAbilities = {
            "Shadow Extraction",
            "Monarch's Domain",
            "Shadow Soldiers",
            "Dimensional Rift",
            "Absolute Territory"
        },
        powerScaling = {
            baseMultiplier = 2.0,
            levelBonus = 0.5,
            maxMultiplier = 100.0
        }
    },
    NARUTO = {
        name = "Naruto",
        progression = {
            { level = 1, name = "Academy Student", powerMultiplier = 1.0, cost = 100, requirements = {} },
            { level = 2, name = "Genin", powerMultiplier = 3.0, cost = 300, requirements = { chakra = 100, jutsu = 1 } },
            { level = 3, name = "Chunin", powerMultiplier = 8.0, cost = 800, requirements = { chakra = 250, jutsu = 3, rank = "Genin" } },
            { level = 4, name = "Jonin", powerMultiplier = 20.0, cost = 2000, requirements = { chakra = 500, jutsu = 5, rank = "Chunin" } },
            { level = 5, name = "ANBU", powerMultiplier = 40.0, cost = 4000, requirements = { chakra = 1000, jutsu = 8, rank = "Jonin" } },
            { level = 6, name = "Kage", powerMultiplier = 80.0, cost = 8000, requirements = { chakra = 2000, jutsu = 10, rank = "ANBU" } },
            { level = 7, name = "Hokage", powerMultiplier = 150.0, cost = 15000, requirements = { chakra = 5000, jutsu = 15, rank = "Kage" } }
        },
        specialAbilities = {
            "Rasengan",
            "Chidori",
            "Shadow Clone Jutsu",
            "Summoning Jutsu",
            "Kage Bunshin no Jutsu"
        },
        powerScaling = {
            baseMultiplier = 3.0,
            levelBonus = 0.8,
            maxMultiplier = 150.0
        }
    },
    ONE_PIECE = {
        name = "One Piece",
        progression = {
            { level = 1, name = "East Blue Pirate", powerMultiplier = 1.0, cost = 100, requirements = {} },
            { level = 2, name = "Grand Line Rookie", powerMultiplier = 4.0, cost = 400, requirements = { bounty = 100, devilFruit = false } },
            { level = 3, name = "Paradise Veteran", powerMultiplier = 12.0, cost = 1200, requirements = { bounty = 500, devilFruit = true, haki = 1 } },
            { level = 4, name = "New World Captain", powerMultiplier = 30.0, cost = 3000, requirements = { bounty = 1000, devilFruit = true, haki = 2 } },
            { level = 5, name = "Yonko Commander", powerMultiplier = 60.0, cost = 6000, requirements = { bounty = 2000, devilFruit = true, haki = 3 } },
            { level = 6, name = "Yonko", powerMultiplier = 120.0, cost = 12000, requirements = { bounty = 5000, devilFruit = true, haki = 3 } },
            { level = 7, name = "Pirate King", powerMultiplier = 200.0, cost = 20000, requirements = { bounty = 10000, devilFruit = true, haki = 3 } }
        },
        specialAbilities = {
            "Devil Fruit Powers",
            "Haki Mastery",
            "Gear Transformations",
            "Conqueror's Haki",
            "Awakened Powers"
        },
        powerScaling = {
            baseMultiplier = 4.0,
            levelBonus = 1.0,
            maxMultiplier = 200.0
        }
    },
    BLEACH = {
        name = "Bleach",
        progression = {
            { level = 1, name = "Shinigami Student", powerMultiplier = 1.0, cost = 100, requirements = {} },
            { level = 2, name = "Unseated Officer", powerMultiplier = 3.0, cost = 300, requirements = { reiatsu = 100, zanpakuto = 1 } },
            { level = 3, name = "Seated Officer", powerMultiplier = 8.0, cost = 800, requirements = { reiatsu = 250, zanpakuto = 2, rank = "Unseated" } },
            { level = 4, name = "Lieutenant", powerMultiplier = 18.0, cost = 1800, requirements = { reiatsu = 500, zanpakuto = 3, rank = "Seated" } },
            { level = 5, name = "Captain", powerMultiplier = 35.0, cost = 3500, requirements = { reiatsu = 1000, zanpakuto = 4, rank = "Lieutenant" } },
            { level = 6, name = "Bankai Master", powerMultiplier = 70.0, cost = 7000, requirements = { reiatsu = 2000, zanpakuto = 5, rank = "Captain" } },
            { level = 7, name = "Soul King", powerMultiplier = 150.0, cost = 15000, requirements = { reiatsu = 5000, zanpakuto = 6, rank = "Bankai" } }
        },
        specialAbilities = {
            "Zanpakuto Release",
            "Bankai",
            "Kido Mastery",
            "Hollow Powers",
            "Soul King Powers"
        },
        powerScaling = {
            baseMultiplier = 3.0,
            levelBonus = 0.7,
            maxMultiplier = 150.0
        }
    },
    MY_HERO_ACADEMIA = {
        name = "My Hero Academia",
        progression = {
            { level = 1, name = "Quirkless Student", powerMultiplier = 1.0, cost = 100, requirements = {} },
            { level = 2, name = "Quirk User", powerMultiplier = 4.0, cost = 400, requirements = { quirk = 1, training = 100 } },
            { level = 3, name = "Hero Student", powerMultiplier = 10.0, cost = 1000, requirements = { quirk = 2, training = 250, license = false } },
            { level = 4, name = "Pro Hero", powerMultiplier = 25.0, cost = 2500, requirements = { quirk = 3, training = 500, license = true } },
            { level = 5, name = "Top 10 Hero", powerMultiplier = 50.0, cost = 5000, requirements = { quirk = 4, training = 1000, rank = "Pro" } },
            { level = 6, name = "Number 1 Hero", powerMultiplier = 100.0, cost = 10000, requirements = { quirk = 5, training = 2000, rank = "Top10" } },
            { level = 7, name = "Symbol of Peace", powerMultiplier = 200.0, cost = 20000, requirements = { quirk = 6, training = 5000, rank = "Number1" } }
        },
        specialAbilities = {
            "Quirk Mastery",
            "Full Cowl",
            "Plus Ultra",
            "Hero Techniques",
            "Symbol of Peace"
        },
        powerScaling = {
            baseMultiplier = 4.0,
            levelBonus = 0.9,
            maxMultiplier = 200.0
        }
    }
}

-- Power-up configuration
local POWER_UP_CONFIG = {
    baseUpgradeCost = 100,
    costMultiplier = 1.5,
    maxUpgradeLevel = 10,
    powerIncreasePerLevel = 0.25, -- 25% increase per level
    abilityUnlockThresholds = { 3, 5, 7, 9, 10 },
    specialTechniqueUnlock = 5,
    ultimateMoveUnlock = 8,
    efficiencyDecay = 0.05, -- 5% efficiency loss per level
    minEfficiency = 0.3, -- Minimum 30% efficiency
    upgradeTime = 5, -- 5 seconds per upgrade
    batchUpgradeLimit = 3 -- Maximum 3 upgrades at once
}

-- Constructor
function PowerUpSystem.new(powerUpData, player)
    local self = setmetatable({}, PowerUpSystem)
    
    -- Core data
    self.powerUpData = powerUpData
    self.player = player
    self.animeTheme = powerUpData.animeTheme
    self.animePowerSystem = self:LoadAnimePowerSystem()
    
    -- Power-up state
    self.currentLevel = powerUpData.level or 1
    self.currentPower = powerUpData.currentPower or 100
    self.maxPower = powerUpData.maxPower or 1000
    self.powerMultiplier = 1.0
    self.efficiency = 1.0
    
    -- Upgrade tracking
    self.upgradeHistory = {}
    self.activeUpgrades = {}
    self.upgradeQueue = {}
    self.lastUpgradeTime = 0
    
    -- Performance optimization
    self.cachedCalculations = {}
    self.lastUpdate = tick()
    self.updateInterval = 0.1 -- 10 updates per second
    
    -- Memory management
    self.memoryCategory = "PowerUpSystem"
    
    -- Initialize power-up system
    self:InitializePowerUpSystem()
    
    print("PowerUpSystem: Created for " .. self.animeTheme .. " theme, level " .. self.currentLevel)
    
    return self
end

-- Load anime power system for current theme
function PowerUpSystem:LoadAnimePowerSystem()
    local themeKey = self.animeTheme:upper():gsub(" ", "_")
    return ANIME_POWER_SYSTEMS[themeKey] or ANIME_POWER_SYSTEMS.SOLO_LEVELING
end

-- Initialize power-up system
function PowerUpSystem:InitializePowerUpSystem()
    -- Calculate initial power multiplier
    self.powerMultiplier = self:CalculatePowerMultiplier()
    
    -- Calculate initial efficiency
    self.efficiency = self:CalculateEfficiency()
    
    -- Update max power based on current level
    self.maxPower = self:CalculateMaxPower()
    
    print("PowerUpSystem: Initialized with power multiplier " .. self.powerMultiplier .. " and efficiency " .. self.efficiency)
end

-- Calculate power multiplier based on current level
function PowerUpSystem:CalculatePowerMultiplier()
    local progression = self.animePowerSystem.progression
    local currentProgression = nil
    
    -- Find current progression level
    for _, level in ipairs(progression) do
        if level.level <= self.currentLevel then
            currentProgression = level
        else
            break
        end
    end
    
    if not currentProgression then
        return 1.0
    end
    
    -- Apply power scaling
    local scaling = self.animePowerSystem.powerScaling
    local baseMultiplier = currentProgression.powerMultiplier
    local levelBonus = (self.currentLevel - currentProgression.level) * scaling.levelBonus
    
    return math.min(scaling.maxMultiplier, baseMultiplier + levelBonus)
end

-- Calculate efficiency based on current level
function PowerUpSystem:CalculateEfficiency()
    local baseEfficiency = 1.0
    local efficiencyLoss = (self.currentLevel - 1) * POWER_UP_CONFIG.efficiencyDecay
    
    return math.max(POWER_UP_CONFIG.minEfficiency, baseEfficiency - efficiencyLoss)
end

-- Calculate maximum power based on current level
function PowerUpSystem:CalculateMaxPower()
    local basePower = 100
    local levelMultiplier = 1 + (self.currentLevel - 1) * 0.5 -- 50% increase per level
    local powerMultiplier = self.powerMultiplier
    
    return math.floor(basePower * levelMultiplier * powerMultiplier)
end

-- Get upgrade cost for next level
function PowerUpSystem:GetUpgradeCost()
    local baseCost = POWER_UP_CONFIG.baseUpgradeCost
    local costMultiplier = POWER_UP_CONFIG.costMultiplier
    
    if self.currentLevel == 1 then
        return baseCost
    else
        return math.floor(baseCost * (costMultiplier ^ (self.currentLevel - 1)))
    end
end

-- Check if player can upgrade
function PowerUpSystem:CanUpgrade()
    -- Check if at max level
    if self.currentLevel >= POWER_UP_CONFIG.maxUpgradeLevel then
        return false, "Maximum upgrade level reached"
    end
    
    -- Check upgrade cooldown
    local currentTime = tick()
    if currentTime - self.lastUpgradeTime < POWER_UP_CONFIG.upgradeTime then
        return false, "Upgrade cooldown active"
    end
    
    -- Check if upgrade queue is full
    if #self.upgradeQueue >= POWER_UP_CONFIG.batchUpgradeLimit then
        return false, "Upgrade queue is full"
    end
    
    -- Check requirements
    local canUpgrade, requirementMessage = self:CheckUpgradeRequirements()
    if not canUpgrade then
        return false, requirementMessage
    end
    
    return true, "Can upgrade"
end

-- Check upgrade requirements
function PowerUpSystem:CheckUpgradeRequirements()
    local progression = self.animePowerSystem.progression
    local nextLevel = self.currentLevel + 1
    local nextProgression = nil
    
    -- Find next progression level
    for _, level in ipairs(progression) do
        if level.level == nextLevel then
            nextProgression = level
            break
        end
    end
    
    if not nextProgression then
        return true, "No requirements for next level"
    end
    
    -- Check each requirement
    for requirement, value in pairs(nextProgression.requirements) do
        if requirement == "power" and self.currentPower < value then
            return false, "Insufficient power: " .. self.currentPower .. "/" .. value
        elseif requirement == "rank" and not self:HasRank(value) then
            return false, "Rank requirement not met: " .. value
        elseif requirement == "kills" and not self:HasKills(value) then
            return false, "Kill requirement not met: " .. value
        elseif requirement == "chakra" and not self:HasChakra(value) then
            return false, "Chakra requirement not met: " .. value
        elseif requirement == "jutsu" and not self:HasJutsu(value) then
            return false, "Jutsu requirement not met: " .. value
        elseif requirement == "bounty" and not self:HasBounty(value) then
            return false, "Bounty requirement not met: " .. value
        elseif requirement == "devilFruit" and not self:HasDevilFruit() then
            return false, "Devil Fruit required"
        elseif requirement == "haki" and not self:HasHaki(value) then
            return false, "Haki requirement not met: " .. value
        elseif requirement == "reiatsu" and not self:HasReiatsu(value) then
            return false, "Reiatsu requirement not met: " .. value
        elseif requirement == "zanpakuto" and not self:HasZanpakuto(value) then
            return false, "Zanpakuto requirement not met: " .. value
        elseif requirement == "quirk" and not self:HasQuirk(value) then
            return false, "Quirk requirement not met: " .. value
        elseif requirement == "training" and not self:HasTraining(value) then
            return false, "Training requirement not met: " .. value
        elseif requirement == "license" and not self:HasLicense() then
            return false, "Hero license required"
        end
    end
    
    return true, "All requirements met"
end

-- Requirement check helper functions (placeholder implementations)
function PowerUpSystem:HasRank(rank)
    -- TODO: Integrate with actual rank system
    return self.currentLevel >= 2
end

function PowerUpSystem:HasKills(kills)
    -- TODO: Integrate with actual kill tracking
    return self.currentLevel >= 3
end

function PowerUpSystem:HasChakra(chakra)
    -- TODO: Integrate with actual chakra system
    return self.currentLevel >= 2
end

function PowerUpSystem:HasJutsu(jutsu)
    -- TODO: Integrate with actual jutsu system
    return self.currentLevel >= 2
end

function PowerUpSystem:HasBounty(bounty)
    -- TODO: Integrate with actual bounty system
    return self.currentLevel >= 2
end

function PowerUpSystem:HasDevilFruit()
    -- TODO: Integrate with actual devil fruit system
    return self.currentLevel >= 2
end

function PowerUpSystem:HasHaki(haki)
    -- TODO: Integrate with actual haki system
    return self.currentLevel >= 3
end

function PowerUpSystem:HasReiatsu(reiatsu)
    -- TODO: Integrate with actual reiatsu system
    return self.currentLevel >= 2
end

function PowerUpSystem:HasZanpakuto(zanpakuto)
    -- TODO: Integrate with actual zanpakuto system
    return self.currentLevel >= 2
end

function PowerUpSystem:HasQuirk(quirk)
    -- TODO: Integrate with actual quirk system
    return self.currentLevel >= 2
end

function PowerUpSystem:HasTraining(training)
    -- TODO: Integrate with actual training system
    return self.currentLevel >= 2
end

function PowerUpSystem:HasLicense()
    -- TODO: Integrate with actual license system
    return self.currentLevel >= 3
end

-- Start upgrade process
function PowerUpSystem:StartUpgrade()
    local canUpgrade, message = self:CanUpgrade()
    if not canUpgrade then
        warn("PowerUpSystem: Cannot upgrade - " .. message)
        return false
    end
    
    -- Add to upgrade queue
    local upgradeData = {
        startTime = tick(),
        targetLevel = self.currentLevel + 1,
        cost = self:GetUpgradeCost(),
        requirements = self:GetUpgradeRequirements()
    }
    
    table.insert(self.upgradeQueue, upgradeData)
    
    print("PowerUpSystem: Started upgrade to level " .. upgradeData.targetLevel)
    
    return true
end

-- Get upgrade requirements for next level
function PowerUpSystem:GetUpgradeRequirements()
    local progression = self.animePowerSystem.progression
    local nextLevel = self.currentLevel + 1
    
    for _, level in ipairs(progression) do
        if level.level == nextLevel then
            return level.requirements
        end
    end
    
    return {}
end

-- Process upgrade queue
function PowerUpSystem:ProcessUpgradeQueue()
    local currentTime = tick()
    
    for i = #self.upgradeQueue, 1, -1 do
        local upgradeData = self.upgradeQueue[i]
        if upgradeData then
            local timeElapsed = currentTime - upgradeData.startTime
            
            if timeElapsed >= POWER_UP_CONFIG.upgradeTime then
                -- Complete upgrade
                self:CompleteUpgrade(upgradeData)
                
                -- Remove from queue
                table.remove(self.upgradeQueue, i)
            end
        end
    end
end

-- Complete upgrade
function PowerUpSystem:CompleteUpgrade(upgradeData)
    local oldLevel = self.currentLevel
    local oldPower = self.currentPower
    local oldMultiplier = self.powerMultiplier
    local oldEfficiency = self.efficiency
    
    -- Update level
    self.currentLevel = upgradeData.targetLevel
    
    -- Recalculate values
    self.powerMultiplier = self:CalculatePowerMultiplier()
    self.efficiency = self:CalculateEfficiency()
    self.maxPower = self:CalculateMaxPower()
    
    -- Update current power
    local powerIncrease = self.maxPower - oldPower
    self.currentPower = self.maxPower
    
    -- Record upgrade history
    table.insert(self.upgradeHistory, {
        timestamp = tick(),
        oldLevel = oldLevel,
        newLevel = self.currentLevel,
        oldPower = oldPower,
        newPower = self.currentPower,
        powerIncrease = powerIncrease,
        oldMultiplier = oldMultiplier,
        newMultiplier = self.powerMultiplier,
        oldEfficiency = oldEfficiency,
        newEfficiency = self.efficiency
    })
    
    -- Update last upgrade time
    self.lastUpgradeTime = tick()
    
    -- Check for ability unlocks
    self:CheckAbilityUnlocks()
    
    print("PowerUpSystem: Upgraded from level " .. oldLevel .. " to " .. self.currentLevel .. 
          " (Power: " .. oldPower .. " → " .. self.currentPower .. 
          ", Multiplier: " .. oldMultiplier .. " → " .. self.powerMultiplier .. ")")
end

-- Check for ability unlocks
function PowerUpSystem:CheckAbilityUnlocks()
    local unlockedAbilities = {}
    
    -- Check special technique unlock
    if self.currentLevel >= POWER_UP_CONFIG.specialTechniqueUnlock then
        table.insert(unlockedAbilities, "Special Technique")
    end
    
    -- Check ultimate move unlock
    if self.currentLevel >= POWER_UP_CONFIG.ultimateMoveUnlock then
        table.insert(unlockedAbilities, "Ultimate Move")
    end
    
    -- Check level-based ability unlocks
    for _, threshold in ipairs(POWER_UP_CONFIG.abilityUnlockThresholds) do
        if self.currentLevel >= threshold then
            local ability = self:GetAbilityForLevel(threshold)
            if ability then
                table.insert(unlockedAbilities, ability)
            end
        end
    end
    
    -- Notify about new abilities
    if #unlockedAbilities > 0 then
        print("PowerUpSystem: Unlocked new abilities: " .. table.concat(unlockedAbilities, ", "))
    end
end

-- Get ability for specific level
function PowerUpSystem:GetAbilityForLevel(level)
    local abilities = self.animePowerSystem.specialAbilities
    local abilityIndex = math.floor((level - 1) / 2) + 1
    
    if abilityIndex <= #abilities then
        return abilities[abilityIndex]
    end
    
    return nil
end

-- Get current progression level
function PowerUpSystem:GetCurrentProgressionLevel()
    local progression = self.animePowerSystem.progression
    
    for i = #progression, 1, -1 do
        if self.currentLevel >= progression[i].level then
            return progression[i]
        end
    end
    
    return progression[1]
end

-- Get next progression level
function PowerUpSystem:GetNextProgressionLevel()
    local progression = self.animePowerSystem.progression
    local currentIndex = nil
    
    for i, level in ipairs(progression) do
        if level.level == self.currentLevel then
            currentIndex = i
            break
        end
    end
    
    if not currentIndex or currentIndex >= #progression then
        return nil -- Already at max level
    end
    
    return progression[currentIndex + 1]
end

-- Get power-up statistics
function PowerUpSystem:GetStats()
    return {
        currentLevel = self.currentLevel,
        currentPower = self.currentPower,
        maxPower = self.maxPower,
        powerMultiplier = self.powerMultiplier,
        efficiency = self.efficiency,
        upgradeHistory = self.upgradeHistory,
        activeUpgrades = self.activeUpgrades,
        upgradeQueue = self.upgradeQueue,
        animeTheme = self.animeTheme,
        progressionLevel = self:GetCurrentProgressionLevel(),
        nextProgression = self:GetNextProgressionLevel()
    }
end

-- Get upgrade progress
function PowerUpSystem:GetUpgradeProgress()
    local currentProgression = self:GetCurrentProgressionLevel()
    local nextProgression = self:GetNextProgressionLevel()
    
    if not nextProgression then
        return {
            currentLevel = self.currentLevel,
            maxLevel = POWER_UP_CONFIG.maxUpgradeLevel,
            progress = 100,
            nextLevel = nil,
            requirements = {}
        }
    end
    
    local progress = ((self.currentLevel - currentProgression.level) / 
                     (nextProgression.level - currentProgression.level)) * 100
    
    return {
        currentLevel = self.currentLevel,
        maxLevel = POWER_UP_CONFIG.maxUpgradeLevel,
        progress = math.min(100, progress),
        nextLevel = nextProgression,
        requirements = nextProgression.requirements
    }
end

-- Update power-up system
function PowerUpSystem:Update()
    local currentTime = tick()
    
    -- Check if it's time to update
    if currentTime - self.lastUpdate < self.updateInterval then
        return
    end
    
    self.lastUpdate = currentTime
    
    -- Process upgrade queue
    self:ProcessUpgradeQueue()
    
    -- Clean up cached calculations periodically
    if currentTime % 60 < self.updateInterval then -- Every minute
        self:CleanupCachedCalculations()
    end
end

-- Clean up cached calculations
function PowerUpSystem:CleanupCachedCalculations()
    self.cachedCalculations = {}
end

-- Destroy power-up system and clean up
function PowerUpSystem:Destroy()
    -- Clear upgrade queue
    self.upgradeQueue = {}
    
    -- Clear active upgrades
    self.activeUpgrades = {}
    
    -- Clear upgrade history
    self.upgradeHistory = {}
    
    -- Clear cached data
    self.cachedCalculations = {}
    
    print("PowerUpSystem: Destroyed")
end

-- Start update loop
function PowerUpSystem:StartUpdateLoop()
    if self.updateConnection then
        self.updateConnection:Disconnect()
    end
    
    self.updateConnection = RunService.Heartbeat:Connect(function()
        self:Update()
    end)
    
    print("PowerUpSystem: Started update loop")
end

-- Stop update loop
function PowerUpSystem:StopUpdateLoop()
    if self.updateConnection then
        self.updateConnection:Disconnect()
        self.updateConnection = nil
    end
    
    print("PowerUpSystem: Stopped update loop")
end

return PowerUpSystem
