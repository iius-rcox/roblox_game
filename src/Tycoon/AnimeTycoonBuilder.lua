-- AnimeTycoonBuilder.lua
-- Modular anime-themed tycoon building system
-- Provides 4 building types with anime-specific progression mechanics
-- Performance-optimized with efficient building updates and memory management

local AnimeTycoonBuilder = {}
AnimeTycoonBuilder.__index = AnimeTycoonBuilder

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Constants
local Constants = require(ReplicatedStorage.Utils.Constants)
local HelperFunctions = require(ReplicatedStorage.Utils.HelperFunctions)

-- Building type constants
local BUILDING_TYPES = {
    CHARACTER_SPAWNER = "CharacterSpawner",
    POWER_UP_SYSTEM = "PowerUpSystem", 
    COLLECTION_SYSTEM = "CollectionSystem",
    SPECIAL_BUILDING = "SpecialBuilding"
}

-- Building tier constants
local BUILDING_TIERS = {
    BASIC = "Basic",
    ADVANCED = "Advanced",
    ELITE = "Elite",
    LEGENDARY = "Legendary",
    MYTHIC = "Mythic"
}

-- Anime progression constants
local ANIME_PROGRESSION = {
    SOLO_LEVELING = {
        name = "Solo Leveling",
        progression = {
            { level = 1, name = "E-Rank Hunter", power = 1, cost = 100 },
            { level = 2, name = "D-Rank Hunter", power = 2, cost = 250 },
            { level = 3, name = "C-Rank Hunter", power = 5, cost = 500 },
            { level = 4, name = "B-Rank Hunter", power = 10, cost = 1000 },
            { level = 5, name = "A-Rank Hunter", power = 25, cost = 2500 },
            { level = 6, name = "S-Rank Hunter", power = 50, cost = 5000 },
            { level = 7, name = "Shadow Monarch", power = 100, cost = 10000 }
        }
    },
    NARUTO = {
        name = "Naruto",
        progression = {
            { level = 1, name = "Academy Student", power = 1, cost = 100 },
            { level = 2, name = "Genin", power = 3, cost = 300 },
            { level = 3, name = "Chunin", power = 8, cost = 800 },
            { level = 4, name = "Jonin", power = 20, cost = 2000 },
            { level = 5, name = "ANBU", power = 40, cost = 4000 },
            { level = 6, name = "Kage", power = 80, cost = 8000 },
            { level = 7, name = "Hokage", power = 150, cost = 15000 }
        }
    },
    ONE_PIECE = {
        name = "One Piece",
        progression = {
            { level = 1, name = "East Blue Pirate", power = 1, cost = 100 },
            { level = 2, name = "Grand Line Rookie", power = 4, cost = 400 },
            { level = 3, name = "Paradise Veteran", power = 12, cost = 1200 },
            { level = 4, name = "New World Captain", power = 30, cost = 3000 },
            { level = 5, name = "Yonko Commander", power = 60, cost = 6000 },
            { level = 6, name = "Yonko", power = 120, cost = 12000 },
            { level = 7, name = "Pirate King", power = 200, cost = 20000 }
        }
    },
    BLEACH = {
        name = "Bleach",
        progression = {
            { level = 1, name = "Shinigami Student", power = 1, cost = 100 },
            { level = 2, name = "Unseated Officer", power = 3, cost = 300 },
            { level = 3, name = "Seated Officer", power = 8, cost = 800 },
            { level = 4, name = "Lieutenant", power = 18, cost = 1800 },
            { level = 5, name = "Captain", power = 35, cost = 3500 },
            { level = 6, name = "Bankai Master", power = 70, cost = 7000 },
            { level = 7, name = "Soul King", power = 150, cost = 15000 }
        }
    },
    MY_HERO_ACADEMIA = {
        name = "My Hero Academia",
        progression = {
            { level = 1, name = "Quirkless Student", power = 1, cost = 100 },
            { level = 2, name = "Quirk User", power = 4, cost = 400 },
            { level = 3, name = "Hero Student", power = 10, cost = 1000 },
            { level = 4, name = "Pro Hero", power = 25, cost = 2500 },
            { level = 5, name = "Top 10 Hero", power = 50, cost = 5000 },
            { level = 6, name = "Number 1 Hero", power = 100, cost = 10000 },
            { level = 7, name = "Symbol of Peace", power = 200, cost = 20000 }
        }
    }
}

-- Building configuration
local BUILDING_CONFIG = {
    [BUILDING_TYPES.CHARACTER_SPAWNER] = {
        name = "Character Spawner",
        description = "Spawns anime characters for collection",
        baseCost = 500,
        upgradeMultiplier = 1.5,
        maxLevel = 10,
        spawnInterval = { min = 2, max = 4 },
        capacity = { base = 5, perLevel = 2 },
        visualEffects = true,
        animeSpecific = true
    },
    [BUILDING_TYPES.POWER_UP_SYSTEM] = {
        name = "Power-Up System",
        description = "Enhances character power and abilities",
        baseCost = 1000,
        upgradeMultiplier = 2.0,
        maxLevel = 8,
        powerMultiplier = { base = 1.5, perLevel = 0.5 },
        efficiency = { base = 0.8, perLevel = 0.1 },
        visualEffects = true,
        animeSpecific = true
    },
    [BUILDING_TYPES.COLLECTION_SYSTEM] = {
        name = "Collection System",
        description = "Manages and organizes collected characters",
        baseCost = 750,
        upgradeMultiplier = 1.8,
        maxLevel = 12,
        storageCapacity = { base = 20, perLevel = 10 },
        organizationBonus = { base = 1.0, perLevel = 0.2 },
        visualEffects = true,
        animeSpecific = true
    },
    [BUILDING_TYPES.SPECIAL_BUILDING] = {
        name = "Special Building",
        description = "Unique anime-specific structures and effects",
        baseCost = 2000,
        upgradeMultiplier = 2.5,
        maxLevel = 6,
        specialEffects = true,
        animeSpecific = true,
        uniqueAbilities = true
    }
}

-- Constructor
function AnimeTycoonBuilder.new(plotData, player)
    local self = setmetatable({}, AnimeTycoonBuilder)
    
    -- Core data
    self.plotData = plotData
    self.player = player
    self.animeTheme = plotData.theme
    self.animeThemeData = plotData.animeThemeData or {}
    
    -- Building management
    self.buildings = {}
    self.buildingCounts = {}
    self.totalPower = 0
    self.totalEarnings = 0
    
    -- Performance optimization
    self.updateQueue = {}
    self.lastUpdate = tick()
    self.updateInterval = 0.1 -- 10 updates per second
    self.batchSize = 10
    
    -- Memory management
    self.memoryCategory = "AnimeTycoonBuilder"
    self.cachedCalculations = {}
    
    -- Initialize building counts
    for buildingType, _ in pairs(BUILDING_TYPES) do
        self.buildingCounts[buildingType] = 0
    end
    
    -- Load anime progression data
    self.animeProgression = self:LoadAnimeProgression()
    
    print("AnimeTycoonBuilder: Created for player " .. player.Name .. " on anime theme: " .. self.animeTheme)
    
    return self
end

-- Load anime progression data for the current theme
function AnimeTycoonBuilder:LoadAnimeProgression()
    local themeKey = self.animeTheme:upper():gsub(" ", "_")
    return ANIME_PROGRESSION[themeKey] or ANIME_PROGRESSION.SOLO_LEVELING
end

-- Get building cost for a specific type and level
function AnimeTycoonBuilder:GetBuildingCost(buildingType, level)
    local config = BUILDING_CONFIG[buildingType]
    if not config then return 0 end
    
    local baseCost = config.baseCost
    local multiplier = config.upgradeMultiplier
    
    if level == 1 then
        return baseCost
    else
        return math.floor(baseCost * (multiplier ^ (level - 1)))
    end
end

-- Get upgrade cost for existing building
function AnimeTycoonBuilder:GetUpgradeCost(buildingId)
    local building = self.buildings[buildingId]
    if not building then return 0 end
    
    local config = BUILDING_CONFIG[building.type]
    if not config then return 0 end
    
    if building.level >= config.maxLevel then
        return 0 -- Max level reached
    end
    
    return self:GetBuildingCost(building.type, building.level + 1)
end

-- Check if player can afford building/upgrade
function AnimeTycoonBuilder:CanAfford(cost)
    -- TODO: Integrate with player economy system
    -- For now, assume player can afford everything
    return true
end

-- Create a new building
function AnimeTycoonBuilder:CreateBuilding(buildingType, position, level)
    level = level or 1
    
    local config = BUILDING_CONFIG[buildingType]
    if not config then
        warn("AnimeTycoonBuilder: Invalid building type: " .. tostring(buildingType))
        return nil
    end
    
    if level > config.maxLevel then
        warn("AnimeTycoonBuilder: Level " .. level .. " exceeds max level " .. config.maxLevel .. " for " .. buildingType)
        return nil
    end
    
    local cost = self:GetBuildingCost(buildingType, level)
    if not self:CanAfford(cost) then
        warn("AnimeTycoonBuilder: Player cannot afford building cost: " .. cost)
        return nil
    end
    
    -- Generate unique building ID
    local buildingId = self:GenerateBuildingId(buildingType)
    
    -- Create building data structure
    local building = {
        id = buildingId,
        type = buildingType,
        level = level,
        position = position,
        cost = cost,
        power = self:CalculateBuildingPower(buildingType, level),
        earnings = self:CalculateBuildingEarnings(buildingType, level),
        lastUpdate = tick(),
        isActive = true,
        animeTheme = self.animeTheme,
        animeSpecific = config.animeSpecific,
        visualEffects = config.visualEffects,
        uniqueAbilities = config.uniqueAbilities or false
    }
    
    -- Add anime-specific properties
    if config.animeSpecific then
        building.animeProperties = self:GetAnimeSpecificProperties(buildingType, level)
    end
    
    -- Create visual representation
    local success, visualModel = pcall(function()
        return self:CreateBuildingVisual(building)
    end)
    
    if success and visualModel then
        building.visualModel = visualModel
        building.visualModel.Parent = workspace
    else
        warn("AnimeTycoonBuilder: Failed to create visual for building " .. buildingId)
    end
    
    -- Store building
    self.buildings[buildingId] = building
    self.buildingCounts[buildingType] = self.buildingCounts[buildingType] + 1
    
    -- Update totals
    self.totalPower = self.totalPower + building.power
    self.totalEarnings = self.totalEarnings + building.earnings
    
    -- Add to update queue
    table.insert(self.updateQueue, buildingId)
    
    print("AnimeTycoonBuilder: Created " .. buildingType .. " level " .. level .. " for player " .. self.player.Name)
    
    return building
end

-- Generate unique building ID
function AnimeTycoonBuilder:GenerateBuildingId(buildingType)
    local timestamp = math.floor(tick() * 1000)
    local random = math.random(1000, 9999)
    return buildingType .. "_" .. self.player.UserId .. "_" .. timestamp .. "_" .. random
end

-- Calculate building power based on type and level
function AnimeTycoonBuilder:CalculateBuildingPower(buildingType, level)
    local config = BUILDING_CONFIG[buildingType]
    if not config then return 0 end
    
    local basePower = 1
    
    if buildingType == BUILDING_TYPES.CHARACTER_SPAWNER then
        basePower = 5
    elseif buildingType == BUILDING_TYPES.POWER_UP_SYSTEM then
        basePower = 10
    elseif buildingType == BUILDING_TYPES.COLLECTION_SYSTEM then
        basePower = 3
    elseif buildingType == BUILDING_TYPES.SPECIAL_BUILDING then
        basePower = 15
    end
    
    return basePower * level
end

-- Calculate building earnings based on type and level
function AnimeTycoonBuilder:CalculateBuildingEarnings(buildingType, level)
    local config = BUILDING_CONFIG[buildingType]
    if not config then return 0 end
    
    local baseEarnings = 10
    
    if buildingType == BUILDING_TYPES.CHARACTER_SPAWNER then
        baseEarnings = 15
    elseif buildingType == BUILDING_TYPES.POWER_UP_SYSTEM then
        baseEarnings = 25
    elseif buildingType == BUILDING_TYPES.COLLECTION_SYSTEM then
        baseEarnings = 20
    elseif buildingType == BUILDING_TYPES.SPECIAL_BUILDING then
        baseEarnings = 50
    end
    
    return baseEarnings * level
end

-- Get anime-specific properties for building
function AnimeTycoonBuilder:GetAnimeSpecificProperties(buildingType, level)
    local properties = {}
    
    if buildingType == BUILDING_TYPES.CHARACTER_SPAWNER then
        properties.spawnRate = self:GetAnimeSpawnRate(level)
        properties.characterPool = self:GetAnimeCharacterPool(level)
        properties.rarityBonus = self:GetAnimeRarityBonus(level)
    elseif buildingType == BUILDING_TYPES.POWER_UP_SYSTEM then
        properties.powerMultiplier = self:GetAnimePowerMultiplier(level)
        properties.specialAbilities = self:GetAnimeSpecialAbilities(level)
        properties.efficiency = self:GetAnimeEfficiency(level)
    elseif buildingType == BUILDING_TYPES.COLLECTION_SYSTEM then
        properties.storageBonus = self:GetAnimeStorageBonus(level)
        properties.organizationBonus = self:GetAnimeOrganizationBonus(level)
        properties.tradeBonus = self:GetAnimeTradeBonus(level)
    elseif buildingType == BUILDING_TYPES.SPECIAL_BUILDING then
        properties.uniqueEffect = self:GetAnimeUniqueEffect(level)
        properties.animeSynergy = self:GetAnimeSynergy(level)
        properties.eventBonus = self:GetAnimeEventBonus(level)
    end
    
    return properties
end

-- Get anime-specific spawn rate
function AnimeTycoonBuilder:GetAnimeSpawnRate(level)
    local baseRate = 2.0 -- Base 2 seconds
    local levelBonus = level * 0.1 -- 0.1 second reduction per level
    return math.max(0.5, baseRate - levelBonus) -- Minimum 0.5 seconds
end

-- Get anime character pool for current theme
function AnimeTycoonBuilder:GetAnimeCharacterPool(level)
    local themeCharacters = self.animeThemeData.characters or {}
    local availableCharacters = {}
    
    for _, character in ipairs(themeCharacters) do
        if character.unlockLevel <= level then
            table.insert(availableCharacters, character)
        end
    end
    
    return availableCharacters
end

-- Get anime rarity bonus
function AnimeTycoonBuilder:GetAnimeRarityBonus(level)
    local baseBonus = 1.0
    local levelBonus = level * 0.05 -- 5% increase per level
    return baseBonus + levelBonus
end

-- Get anime power multiplier
function AnimeTycoonBuilder:GetAnimePowerMultiplier(level)
    local baseMultiplier = 1.5
    local levelBonus = level * 0.25 -- 25% increase per level
    return baseMultiplier + levelBonus
end

-- Get anime special abilities
function AnimeTycoonBuilder:GetAnimeSpecialAbilities(level)
    local abilities = {}
    
    if level >= 3 then
        table.insert(abilities, "Enhanced Power")
    end
    if level >= 5 then
        table.insert(abilities, "Special Technique")
    end
    if level >= 7 then
        table.insert(abilities, "Ultimate Move")
    end
    
    return abilities
end

-- Get anime efficiency
function AnimeTycoonBuilder:GetAnimeEfficiency(level)
    local baseEfficiency = 0.8
    local levelBonus = level * 0.05 -- 5% increase per level
    return math.min(1.0, baseEfficiency + levelBonus)
end

-- Get anime storage bonus
function AnimeTycoonBuilder:GetAnimeStorageBonus(level)
    local baseBonus = 1.0
    local levelBonus = level * 0.1 -- 10% increase per level
    return baseBonus + levelBonus
end

-- Get anime organization bonus
function AnimeTycoonBuilder:GetAnimeOrganizationBonus(level)
    local baseBonus = 1.0
    local levelBonus = level * 0.15 -- 15% increase per level
    return baseBonus + levelBonus
end

-- Get anime trade bonus
function AnimeTycoonBuilder:GetAnimeTradeBonus(level)
    local baseBonus = 1.0
    local levelBonus = level * 0.2 -- 20% increase per level
    return baseBonus + levelBonus
end

-- Get anime unique effect
function AnimeTycoonBuilder:GetAnimeUniqueEffect(level)
    local effects = {
        [1] = "Basic Theme Effect",
        [3] = "Enhanced Theme Effect", 
        [5] = "Advanced Theme Effect",
        [6] = "Legendary Theme Effect"
    }
    
    return effects[level] or "No Effect"
end

-- Get anime synergy
function AnimeTycoonBuilder:GetAnimeSynergy(level)
    local baseSynergy = 1.0
    local levelBonus = level * 0.1 -- 10% increase per level
    return baseSynergy + levelBonus
end

-- Get anime event bonus
function AnimeTycoonBuilder:GetAnimeEventBonus(level)
    local baseBonus = 1.0
    local levelBonus = level * 0.15 -- 15% increase per level
    return baseBonus + levelBonus
end

-- Create building visual representation
function AnimeTycoonBuilder:CreateBuildingVisual(building)
    local model = Instance.new("Model")
    model.Name = building.id
    
    -- Create base platform
    local base = Instance.new("Part")
    base.Name = "Base"
    base.Size = Vector3.new(10, 2, 10)
    base.Position = building.position
    base.Anchored = true
    base.Material = Enum.Material.Brick
    
    -- Apply anime theme colors
    local themeColors = self.animeThemeData.colors
    if themeColors and themeColors.primary then
        base.BrickColor = BrickColor.new(themeColors.primary)
    else
        base.BrickColor = BrickColor.new("Medium stone grey")
    end
    
    base.Parent = model
    
    -- Create building structure based on type
    local structure = self:CreateBuildingStructure(building)
    if structure then
        structure.Parent = model
    end
    
    -- Add visual effects if enabled
    if building.visualEffects then
        self:AddVisualEffects(model, building)
    end
    
    return model
end

-- Create building structure based on type
function AnimeTycoonBuilder:CreateBuildingStructure(building)
    local structure = Instance.new("Part")
    
    if building.type == BUILDING_TYPES.CHARACTER_SPAWNER then
        structure.Name = "Spawner"
        structure.Size = Vector3.new(6, 8, 6)
        structure.Position = building.position + Vector3.new(0, 5, 0)
        structure.Material = Enum.Material.Neon
        structure.BrickColor = BrickColor.new("Bright blue")
        
    elseif building.type == BUILDING_TYPES.POWER_UP_SYSTEM then
        structure.Name = "PowerCore"
        structure.Size = Vector3.new(8, 10, 8)
        structure.Position = building.position + Vector3.new(0, 6, 0)
        structure.Material = Enum.Material.Neon
        structure.BrickColor = BrickColor.new("Bright red")
        
    elseif building.type == BUILDING_TYPES.COLLECTION_SYSTEM then
        structure.Name = "CollectionHub"
        structure.Size = Vector3.new(12, 6, 12)
        structure.Position = building.position + Vector3.new(0, 4, 0)
        structure.Material = Enum.Material.Neon
        structure.BrickColor = BrickColor.new("Bright green")
        
    elseif building.type == BUILDING_TYPES.SPECIAL_BUILDING then
        structure.Name = "SpecialStructure"
        structure.Size = Vector3.new(10, 12, 10)
        structure.Position = building.position + Vector3.new(0, 7, 0)
        structure.Material = Enum.Material.Neon
        structure.BrickColor = BrickColor.new("Bright yellow")
    end
    
    structure.Anchored = true
    return structure
end

-- Add visual effects to building
function AnimeTycoonBuilder:AddVisualEffects(model, building)
    -- Add level indicator
    local levelIndicator = Instance.new("Part")
    levelIndicator.Name = "LevelIndicator"
    levelIndicator.Size = Vector3.new(2, 2, 2)
    levelIndicator.Position = building.position + Vector3.new(0, 15, 0)
    levelIndicator.Anchored = true
    levelIndicator.Material = Enum.Material.Neon
    levelIndicator.BrickColor = BrickColor.new("Bright white")
    levelIndicator.Parent = model
    
    -- Add level text
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 100, 0, 40)
    billboardGui.Parent = levelIndicator
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "Lv." .. building.level
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Parent = billboardGui
    
    -- Add pulsing effect
    local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
    local tween = TweenService:Create(levelIndicator, tweenInfo, {Transparency = 0.3})
    tween:Play()
end

-- Upgrade existing building
function AnimeTycoonBuilder:UpgradeBuilding(buildingId)
    local building = self.buildings[buildingId]
    if not building then
        warn("AnimeTycoonBuilder: Building " .. buildingId .. " not found for upgrade")
        return false
    end
    
    local config = BUILDING_CONFIG[building.type]
    if not config then
        warn("AnimeTycoonBuilder: Invalid building type for upgrade")
        return false
    end
    
    if building.level >= config.maxLevel then
        warn("AnimeTycoonBuilder: Building " .. buildingId .. " already at max level")
        return false
    end
    
    local upgradeCost = self:GetUpgradeCost(buildingId)
    if not self:CanAfford(upgradeCost) then
        warn("AnimeTycoonBuilder: Player cannot afford upgrade cost: " .. upgradeCost)
        return false
    end
    
    -- Update building level
    local oldLevel = building.level
    building.level = building.level + 1
    
    -- Update building properties
    building.power = self:CalculateBuildingPower(building.type, building.level)
    building.earnings = self:CalculateBuildingEarnings(building.type, building.level)
    
    -- Update anime-specific properties
    if building.animeSpecific then
        building.animeProperties = self:GetAnimeSpecificProperties(building.type, building.level)
    end
    
    -- Update visual representation
    if building.visualModel then
        self:UpdateBuildingVisual(building)
    end
    
    -- Update totals
    self.totalPower = self.totalPower - self:CalculateBuildingPower(building.type, oldLevel) + building.power
    self.totalEarnings = self.totalEarnings - self:CalculateBuildingEarnings(building.type, oldLevel) + building.earnings
    
    print("AnimeTycoonBuilder: Upgraded " .. building.type .. " from level " .. oldLevel .. " to " .. building.level)
    
    return true
end

-- Update building visual after upgrade
function AnimeTycoonBuilder:UpdateBuildingVisual(building)
    if not building.visualModel then return end
    
    -- Update level indicator
    local levelIndicator = building.visualModel:FindFirstChild("LevelIndicator")
    if levelIndicator then
        local billboardGui = levelIndicator:FindFirstChild("BillboardGui")
        if billboardGui then
            local textLabel = billboardGui:FindFirstChild("TextLabel")
            if textLabel then
                textLabel.Text = "Lv." .. building.level
            end
        end
    end
    
    -- Update structure size based on level
    local structure = building.visualModel:FindFirstChild("Spawner") or 
                     building.visualModel:FindFirstChild("PowerCore") or
                     building.visualModel:FindFirstChild("CollectionHub") or
                     building.visualModel:FindFirstChild("SpecialStructure")
    
    if structure then
        local sizeMultiplier = 1 + (building.level - 1) * 0.1 -- 10% size increase per level
        structure.Size = structure.Size * sizeMultiplier
    end
end

-- Remove building
function AnimeTycoonBuilder:RemoveBuilding(buildingId)
    local building = self.buildings[buildingId]
    if not building then
        warn("AnimeTycoonBuilder: Building " .. buildingId .. " not found for removal")
        return false
    end
    
    -- Remove visual model
    if building.visualModel then
        building.visualModel:Destroy()
    end
    
    -- Update totals
    self.totalPower = self.totalPower - building.power
    self.totalEarnings = self.totalEarnings - building.earnings
    
    -- Update building counts
    self.buildingCounts[building.type] = self.buildingCounts[building.type] - 1
    
    -- Remove from buildings
    self.buildings[buildingId] = nil
    
    -- Remove from update queue
    for i, queuedId in ipairs(self.updateQueue) do
        if queuedId == buildingId then
            table.remove(self.updateQueue, i)
            break
        end
    end
    
    print("AnimeTycoonBuilder: Removed building " .. buildingId)
    
    return true
end

-- Get building information
function AnimeTycoonBuilder:GetBuildingInfo(buildingId)
    return self.buildings[buildingId]
end

-- Get all buildings of a specific type
function AnimeTycoonBuilder:GetBuildingsByType(buildingType)
    local buildings = {}
    
    for buildingId, building in pairs(self.buildings) do
        if building.type == buildingType then
            table.insert(buildings, building)
        end
    end
    
    return buildings
end

-- Get building statistics
function AnimeTycoonBuilder:GetBuildingStats()
    local stats = {
        totalBuildings = 0,
        totalPower = self.totalPower,
        totalEarnings = self.totalEarnings,
        buildingCounts = self.buildingCounts,
        animeTheme = self.animeTheme,
        animeProgression = self.animeProgression
    }
    
    for _, count in pairs(self.buildingCounts) do
        stats.totalBuildings = stats.totalBuildings + count
    end
    
    return stats
end

-- Get anime progression data
function AnimeTycoonBuilder:GetAnimeProgressionData()
    return self.animeProgression
end

-- Get current progression level
function AnimeTycoonBuilder:GetCurrentProgressionLevel()
    local totalPower = self.totalPower
    local progression = self.animeProgression.progression
    
    for i = #progression, 1, -1 do
        if totalPower >= progression[i].power then
            return progression[i]
        end
    end
    
    return progression[1] -- Return first level if none reached
end

-- Check if player can progress to next level
function AnimeTycoonBuilder:CanProgressToNextLevel()
    local currentLevel = self:GetCurrentProgressionLevel()
    local currentIndex = nil
    
    for i, level in ipairs(self.animeProgression.progression) do
        if level.level == currentLevel.level then
            currentIndex = i
            break
        end
    end
    
    if not currentIndex or currentIndex >= #self.animeProgression.progression then
        return false -- Already at max level
    end
    
    local nextLevel = self.animeProgression.progression[currentIndex + 1]
    return self.totalPower >= nextLevel.power
end

-- Get next progression level requirements
function AnimeTycoonBuilder:GetNextProgressionRequirements()
    local currentLevel = self:GetCurrentProgressionLevel()
    local currentIndex = nil
    
    for i, level in ipairs(self.animeProgression.progression) do
        if level.level == currentLevel.level then
            currentIndex = i
            break
        end
    end
    
    if not currentIndex or currentIndex >= #self.animeProgression.progression then
        return nil -- Already at max level
    end
    
    local nextLevel = self.animeProgression.progression[currentIndex + 1]
    local currentPower = self.totalPower
    
    return {
        nextLevel = nextLevel,
        powerRequired = nextLevel.power,
        powerCurrent = currentPower,
        powerNeeded = nextLevel.power - currentPower,
        progressPercentage = math.min(100, (currentPower / nextLevel.power) * 100)
    }
end

-- Update building system (called regularly)
function AnimeTycoonBuilder:Update()
    local currentTime = tick()
    
    -- Check if it's time to update
    if currentTime - self.lastUpdate < self.updateInterval then
        return
    end
    
    self.lastUpdate = currentTime
    
    -- Process update queue in batches
    local processedCount = 0
    local batchSize = math.min(self.batchSize, #self.updateQueue)
    
    for i = 1, batchSize do
        local buildingId = self.updateQueue[i]
        if buildingId then
            self:UpdateBuilding(buildingId)
            processedCount = processedCount + 1
        end
    end
    
    -- Remove processed buildings from queue
    for i = 1, processedCount do
        table.remove(self.updateQueue, 1)
    end
    
    -- Clean up cached calculations periodically
    if currentTime % 60 < self.updateInterval then -- Every minute
        self:CleanupCachedCalculations()
    end
end

-- Update individual building
function AnimeTycoonBuilder:UpdateBuilding(buildingId)
    local building = self.buildings[buildingId]
    if not building or not building.isActive then return end
    
    local currentTime = tick()
    local timeSinceLastUpdate = currentTime - building.lastUpdate
    
    -- Update based on building type
    if building.type == BUILDING_TYPES.CHARACTER_SPAWNER then
        self:UpdateCharacterSpawner(building, timeSinceLastUpdate)
    elseif building.type == BUILDING_TYPES.POWER_UP_SYSTEM then
        self:UpdatePowerUpSystem(building, timeSinceLastUpdate)
    elseif building.type == BUILDING_TYPES.COLLECTION_SYSTEM then
        self:UpdateCollectionSystem(building, timeSinceLastUpdate)
    elseif building.type == BUILDING_TYPES.SPECIAL_BUILDING then
        self:UpdateSpecialBuilding(building, timeSinceLastUpdate)
    end
    
    building.lastUpdate = currentTime
end

-- Update character spawner
function AnimeTycoonBuilder:UpdateCharacterSpawner(building, timeSinceLastUpdate)
    local spawnInterval = building.animeProperties and building.animeProperties.spawnRate or 2.0
    
    if timeSinceLastUpdate >= spawnInterval then
        -- TODO: Implement character spawning logic
        -- This will be integrated with CharacterSpawner system in Step 6
        print("AnimeTycoonBuilder: Character spawner " .. building.id .. " ready to spawn")
    end
end

-- Update power-up system
function AnimeTycoonBuilder:UpdatePowerUpSystem(building, timeSinceLastUpdate)
    -- TODO: Implement power-up logic
    -- This will be integrated with PowerUpSystem in Step 7
    print("AnimeTycoonBuilder: Power-up system " .. building.id .. " processing")
end

-- Update collection system
function AnimeTycoonBuilder:UpdateCollectionSystem(building, timeSinceLastUpdate)
    -- TODO: Implement collection logic
    -- This will be integrated with CollectionSystem in Step 8
    print("AnimeTycoonBuilder: Collection system " .. building.id .. " organizing")
end

-- Update special building
function AnimeTycoonBuilder:UpdateSpecialBuilding(building, timeSinceLastUpdate)
    -- TODO: Implement special building logic
    -- This will be integrated with future systems
    print("AnimeTycoonBuilder: Special building " .. building.id .. " activating")
end

-- Clean up cached calculations
function AnimeTycoonBuilder:CleanupCachedCalculations()
    self.cachedCalculations = {}
end

-- Destroy tycoon builder and clean up
function AnimeTycoonBuilder:Destroy()
    -- Remove all buildings
    for buildingId, _ in pairs(self.buildings) do
        self:RemoveBuilding(buildingId)
    end
    
    -- Clear update queue
    self.updateQueue = {}
    
    -- Clear cached data
    self.cachedCalculations = {}
    
    print("AnimeTycoonBuilder: Destroyed for player " .. self.player.Name)
end

-- Start update loop
function AnimeTycoonBuilder:StartUpdateLoop()
    if self.updateConnection then
        self.updateConnection:Disconnect()
    end
    
    self.updateConnection = RunService.Heartbeat:Connect(function()
        self:Update()
    end)
    
    print("AnimeTycoonBuilder: Started update loop for player " .. self.player.Name)
end

-- Stop update loop
function AnimeTycoonBuilder:StopUpdateLoop()
    if self.updateConnection then
        self.updateConnection:Disconnect()
        self.updateConnection = nil
    end
    
    print("AnimeTycoonBuilder: Stopped update loop for player " .. self.player.Name)
end

return AnimeTycoonBuilder
