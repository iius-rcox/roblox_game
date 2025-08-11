-- CharacterSpawner.lua
-- Anime character spawning system with collectible functionality
-- Implements 20 anime series character spawners with rarity systems
-- Performance-optimized with efficient spawning algorithms and memory management

local CharacterSpawner = {}
CharacterSpawner.__index = CharacterSpawner

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- Constants
local Constants = require(ReplicatedStorage.Utils.Constants)
local HelperFunctions = require(ReplicatedStorage.Utils.HelperFunctions)

-- Rarity system constants
local RARITY_LEVELS = {
    COMMON = { name = "Common", color = Color3.fromRGB(150, 150, 150), multiplier = 1.0, spawnChance = 0.6 },
    UNCOMMON = { name = "Uncommon", color = Color3.fromRGB(0, 255, 0), multiplier = 1.5, spawnChance = 0.25 },
    RARE = { name = "Rare", color = Color3.fromRGB(0, 100, 255), multiplier = 2.5, spawnChance = 0.1 },
    EPIC = { name = "Epic", color = Color3.fromRGB(150, 0, 255), multiplier = 4.0, spawnChance = 0.04 },
    LEGENDARY = { name = "Legendary", color = Color3.fromRGB(255, 165, 0), multiplier = 7.0, spawnChance = 0.008 },
    MYTHIC = { name = "Mythic", color = Color3.fromRGB(255, 0, 255), multiplier = 12.0, spawnChance = 0.002 }
}

-- Anime series character data
local ANIME_CHARACTERS = {
    SOLO_LEVELING = {
        name = "Solo Leveling",
        characters = {
            { name = "Sung Jin-Woo", rarity = RARITY_LEVELS.MYTHIC, power = 1000, unlockLevel = 7, abilities = {"Shadow Extraction", "Monarch's Domain"} },
            { name = "Cha Hae-In", rarity = RARITY_LEVELS.LEGENDARY, power = 800, unlockLevel = 6, abilities = {"Sword Mastery", "Enhanced Senses"} },
            { name = "Baek Yoonho", rarity = RARITY_LEVELS.EPIC, power = 600, unlockLevel = 5, abilities = {"Beast Transformation", "Enhanced Strength"} },
            { name = "Choi Jong-In", rarity = RARITY_LEVELS.RARE, power = 400, unlockLevel = 4, abilities = {"Fire Magic", "Mage Mastery"} },
            { name = "Yoo Jinho", rarity = RARITY_LEVELS.UNCOMMON, power = 250, unlockLevel = 3, abilities = {"Support Magic", "Team Coordination"} },
            { name = "Hwang Dongsoo", rarity = RARITY_LEVELS.COMMON, power = 150, unlockLevel = 2, abilities = {"Basic Combat", "Durability"} }
        }
    },
    NARUTO = {
        name = "Naruto",
        characters = {
            { name = "Naruto Uzumaki", rarity = RARITY_LEVELS.MYTHIC, power = 1000, unlockLevel = 7, abilities = {"Nine-Tails Chakra", "Rasengan"} },
            { name = "Sasuke Uchiha", rarity = RARITY_LEVELS.LEGENDARY, power = 900, unlockLevel = 6, abilities = {"Sharingan", "Chidori"} },
            { name = "Kakashi Hatake", rarity = RARITY_LEVELS.EPIC, power = 700, unlockLevel = 5, abilities = {"Copy Ninja", "Lightning Blade"} },
            { name = "Sakura Haruno", rarity = RARITY_LEVELS.RARE, power = 500, unlockLevel = 4, abilities = {"Medical Ninjutsu", "Super Strength"} },
            { name = "Rock Lee", rarity = RARITY_LEVELS.UNCOMMON, power = 300, unlockLevel = 3, abilities = {"Taijutsu Mastery", "Eight Gates"} },
            { name = "Shikamaru Nara", rarity = RARITY_LEVELS.COMMON, power = 200, unlockLevel = 2, abilities = {"Shadow Possession", "Intelligence"} }
        }
    },
    ONE_PIECE = {
        name = "One Piece",
        characters = {
            { name = "Monkey D. Luffy", rarity = RARITY_LEVELS.MYTHIC, power = 1000, unlockLevel = 7, abilities = {"Gum-Gum Fruit", "Haki"} },
            { name = "Roronoa Zoro", rarity = RARITY_LEVELS.LEGENDARY, power = 850, unlockLevel = 6, abilities = {"Three Sword Style", "Conqueror's Haki"} },
            { name = "Sanji Vinsmoke", rarity = RARITY_LEVELS.EPIC, power = 650, unlockLevel = 5, abilities = {"Diable Jambe", "Observation Haki"} },
            { name = "Nami", rarity = RARITY_LEVELS.RARE, power = 450, unlockLevel = 4, abilities = {"Weather Control", "Navigation"} },
            { name = "Usopp", rarity = RARITY_LEVELS.UNCOMMON, power = 280, unlockLevel = 3, abilities = {"Sniper", "Pop Green"} },
            { name = "Tony Tony Chopper", rarity = RARITY_LEVELS.COMMON, power = 180, unlockLevel = 2, abilities = {"Transformation", "Medical"} }
        }
    },
    BLEACH = {
        name = "Bleach",
        characters = {
            { name = "Ichigo Kurosaki", rarity = RARITY_LEVELS.MYTHIC, power = 1000, unlockLevel = 7, abilities = {"Bankai", "Hollow Powers"} },
            { name = "Rukia Kuchiki", rarity = RARITY_LEVELS.LEGENDARY, power = 750, unlockLevel = 6, abilities = {"Sode no Shirayuki", "Kido Mastery"} },
            { name = "Renji Abarai", rarity = RARITY_LEVELS.EPIC, power = 600, unlockLevel = 5, abilities = {"Zabimaru", "Bankai"} },
            { name = "Byakuya Kuchiki", rarity = RARITY_LEVELS.RARE, power = 500, unlockLevel = 4, abilities = {"Senbonzakura", "Noble Techniques"} },
            { name = "Kenpachi Zaraki", rarity = RARITY_LEVELS.UNCOMMON, power = 350, unlockLevel = 3, abilities = {"Nozarashi", "Battle Instinct"} },
            { name = "Yachiru Kusajishi", rarity = RARITY_LEVELS.COMMON, power = 220, unlockLevel = 2, abilities = {"Basic Combat", "Speed"} }
        }
    },
    MY_HERO_ACADEMIA = {
        name = "My Hero Academia",
        characters = {
            { name = "Izuku Midoriya", rarity = RARITY_LEVELS.MYTHIC, power = 1000, unlockLevel = 7, abilities = {"One For All", "Full Cowl"} },
            { name = "Katsuki Bakugo", rarity = RARITY_LEVELS.LEGENDARY, power = 850, unlockLevel = 6, abilities = {"Explosion", "AP Shot"} },
            { name = "All Might", rarity = RARITY_LEVELS.EPIC, power = 700, unlockLevel = 5, abilities = {"One For All", "United States of Smash"} },
            { name = "Shoto Todoroki", rarity = RARITY_LEVELS.RARE, power = 550, unlockLevel = 4, abilities = {"Half-Cold Half-Hot", "Ice Wall"} },
            { name = "Ochaco Uraraka", rarity = RARITY_LEVELS.UNCOMMON, power = 320, unlockLevel = 3, abilities = {"Zero Gravity", "Combat Training"} },
            { name = "Tenya Iida", rarity = RARITY_LEVELS.COMMON, power = 200, unlockLevel = 2, abilities = {"Engine", "Speed"} }
        }
    },
    ONE_PUNCH_MAN = {
        name = "One Punch Man",
        characters = {
            { name = "Saitama", rarity = RARITY_LEVELS.MYTHIC, power = 1000, unlockLevel = 7, abilities = {"One Punch", "Limitless Strength"} },
            { name = "Genos", rarity = RARITY_LEVELS.LEGENDARY, power = 800, unlockLevel = 6, abilities = {"Cyborg Body", "Incinerate"} },
            { name = "Tatsumaki", rarity = RARITY_LEVELS.EPIC, power = 650, unlockLevel = 5, abilities = {"Psychic Powers", "Tornado Control"} },
            { name = "King", rarity = RARITY_LEVELS.RARE, power = 500, unlockLevel = 4, abilities = {"King Engine", "Intimidation"} },
            { name = "Metal Bat", rarity = RARITY_LEVELS.UNCOMMON, power = 300, unlockLevel = 3, abilities = {"Fighting Spirit", "Bat Mastery"} },
            { name = "Mumen Rider", rarity = RARITY_LEVELS.COMMON, power = 180, unlockLevel = 2, abilities = {"Justice Crash", "Courage"} }
        }
    },
    CHAINSAW_MAN = {
        name = "Chainsaw Man",
        characters = {
            { name = "Denji", rarity = RARITY_LEVELS.MYTHIC, power = 1000, unlockLevel = 7, abilities = {"Chainsaw Form", "Devil Contract"} },
            { name = "Power", rarity = RARITY_LEVELS.LEGENDARY, power = 750, unlockLevel = 6, abilities = {"Blood Manipulation", "Devil Powers"} },
            { name = "Aki Hayakawa", rarity = RARITY_LEVELS.EPIC, power = 600, unlockLevel = 5, abilities = {"Future Devil", "Curse Sword"} },
            { name = "Makima", rarity = RARITY_LEVELS.RARE, power = 450, unlockLevel = 4, abilities = {"Control Devil", "Manipulation"} },
            { name = "Kobeni", rarity = RARITY_LEVELS.UNCOMMON, power = 280, unlockLevel = 3, abilities = {"Devil Contract", "Survival"} },
            { name = "Himeno", rarity = RARITY_LEVELS.COMMON, power = 200, unlockLevel = 2, abilities = {"Ghost Devil", "Team Support"} }
        }
    },
    KAIJU_NO_8 = {
        name = "Kaiju No. 8",
        characters = {
            { name = "Kafka Hibino", rarity = RARITY_LEVELS.MYTHIC, power = 1000, unlockLevel = 7, abilities = {"Kaiju Form", "Monster Strength"} },
            { name = "Reno Ichikawa", rarity = RARITY_LEVELS.LEGENDARY, power = 800, unlockLevel = 6, abilities = {"Numbers Weapon", "Combat Training"} },
            { name = "Kikoru Shinomiya", rarity = RARITY_LEVELS.EPIC, power = 650, unlockLevel = 5, abilities = {"Numbers Weapon", "Elite Training"} },
            { name = "Soshiro Hoshina", rarity = RARITY_LEVELS.RARE, power = 500, unlockLevel = 4, abilities = {"Vice Captain", "Leadership"} },
            { name = "Mina Ashiro", rarity = RARITY_LEVELS.UNCOMMON, power = 320, unlockLevel = 3, abilities = {"Captain", "Strategic Mind"} },
            { name = "Isao Shinomiya", rarity = RARITY_LEVELS.COMMON, power = 220, unlockLevel = 2, abilities = {"Commander", "Experience"} }
        }
    },
    BAKI_HANMA = {
        name = "Baki Hanma",
        characters = {
            { name = "Baki Hanma", rarity = RARITY_LEVELS.MYTHIC, power = 1000, unlockLevel = 7, abilities = {"Demon Back", "Martial Arts"} },
            { name = "Yujiro Hanma", rarity = RARITY_LEVELS.LEGENDARY, power = 950, unlockLevel = 6, abilities = {"Ogre", "Unstoppable Force"} },
            { name = "Jack Hanma", rarity = RARITY_LEVELS.EPIC, power = 700, unlockLevel = 5, abilities = {"Goudou", "Brutal Strength"} },
            { name = "Katsumi Orochi", rarity = RARITY_LEVELS.RARE, power = 550, unlockLevel = 4, abilities = {"Retsu Kaioh", "Karate Mastery"} },
            { name = "Doppo Orochi", rarity = RARITY_LEVELS.UNCOMMON, power = 350, unlockLevel = 3, abilities = {"Karate Master", "Discipline"} },
            { name = "Shunsei Kaku", rarity = RARITY_LEVELS.COMMON, power = 250, unlockLevel = 2, abilities = {"Kung Fu", "Traditional Arts"} }
        }
    },
    DRAGON_BALL = {
        name = "Dragon Ball",
        characters = {
            { name = "Goku", rarity = RARITY_LEVELS.MYTHIC, power = 1000, unlockLevel = 7, abilities = {"Super Saiyan", "Kamehameha"} },
            { name = "Vegeta", rarity = RARITY_LEVELS.LEGENDARY, power = 900, unlockLevel = 6, abilities = {"Prince of Saiyans", "Galick Gun"} },
            { name = "Gohan", rarity = RARITY_LEVELS.EPIC, power = 700, unlockLevel = 5, abilities = {"Hybrid Power", "Masenko"} },
            { name = "Piccolo", rarity = RARITY_LEVELS.RARE, power = 550, unlockLevel = 4, abilities = {"Namekian", "Special Beam Cannon"} },
            { name = "Trunks", rarity = RARITY_LEVELS.UNCOMMON, power = 350, unlockLevel = 3, abilities = {"Future Warrior", "Sword Mastery"} },
            { name = "Krillin", rarity = RARITY_LEVELS.COMMON, power = 250, unlockLevel = 2, abilities = {"Human Fighter", "Destructo Disc"} }
        }
    },
    DEMON_SLAYER = {
        name = "Demon Slayer",
        characters = {
            { name = "Tanjiro Kamado", rarity = RARITY_LEVELS.MYTHIC, power = 1000, unlockLevel = 7, abilities = {"Water Breathing", "Sun Breathing"} },
            { name = "Nezuko Kamado", rarity = RARITY_LEVELS.LEGENDARY, power = 800, unlockLevel = 6, abilities = {"Demon Form", "Blood Art"} },
            { name = "Zenitsu Agatsuma", rarity = RARITY_LEVELS.EPIC, power = 650, unlockLevel = 5, abilities = {"Thunder Breathing", "Sleep Fighting"} },
            { name = "Inosuke Hashibira", rarity = RARITY_LEVELS.RARE, power = 500, unlockLevel = 4, abilities = {"Beast Breathing", "Wild Instinct"} },
            { name = "Kyojuro Rengoku", rarity = RARITY_LEVELS.UNCOMMON, power = 320, unlockLevel = 3, abilities = {"Flame Hashira", "Flame Breathing"} },
            { name = "Giyu Tomioka", rarity = RARITY_LEVELS.COMMON, power = 220, unlockLevel = 2, abilities = {"Water Hashira", "Water Breathing"} }
        }
    },
    ATTACK_ON_TITAN = {
        name = "Attack on Titan",
        characters = {
            { name = "Eren Yeager", rarity = RARITY_LEVELS.MYTHIC, power = 1000, unlockLevel = 7, abilities = {"Titan Form", "Founding Titan"} },
            { name = "Mikasa Ackerman", rarity = RARITY_LEVELS.LEGENDARY, power = 850, unlockLevel = 6, abilities = {"Ackerman Blood", "Combat Mastery"} },
            { name = "Levi Ackerman", rarity = RARITY_LEVELS.EPIC, power = 700, unlockLevel = 5, abilities = {"Humanity's Strongest", "3D Maneuver"} },
            { name = "Armin Arlert", rarity = RARITY_LEVELS.RARE, power = 500, unlockLevel = 4, abilities = {"Colossal Titan", "Strategic Mind"} },
            { name = "Jean Kirstein", rarity = RARITY_LEVELS.UNCOMMON, power = 320, unlockLevel = 3, abilities = {"Scout Regiment", "Leadership"} },
            { name = "Connie Springer", rarity = RARITY_LEVELS.COMMON, power = 220, unlockLevel = 2, abilities = {"Scout Regiment", "Team Player"} }
        }
    },
    JUJUTSU_KAISEN = {
        name = "Jujutsu Kaisen",
        characters = {
            { name = "Yuji Itadori", rarity = RARITY_LEVELS.MYTHIC, power = 1000, unlockLevel = 7, abilities = {"Sukuna's Power", "Divergent Fist"} },
            { name = "Megumi Fushiguro", rarity = RARITY_LEVELS.LEGENDARY, power = 800, unlockLevel = 6, abilities = {"Ten Shadows", "Shikigami"} },
            { name = "Nobara Kugisaki", rarity = RARITY_LEVELS.EPIC, power = 650, unlockLevel = 5, abilities = {"Straw Doll", "Resonance"} },
            { name = "Gojo Satoru", rarity = RARITY_LEVELS.RARE, power = 500, unlockLevel = 4, abilities = {"Limitless", "Infinity"} },
            { name = "Nanami Kento", rarity = RARITY_LEVELS.UNCOMMON, power = 320, unlockLevel = 3, abilities = {"Ratio Technique", "7:3"} },
            { name = "Maki Zenin", rarity = RARITY_LEVELS.COMMON, power = 220, unlockLevel = 2, abilities = {"Cursed Tools", "Physical Strength"} }
        }
    },
    HUNTER_X_HUNTER = {
        name = "Hunter x Hunter",
        characters = {
            { name = "Gon Freecss", rarity = RARITY_LEVELS.MYTHIC, power = 1000, unlockLevel = 7, abilities = {"Nen Mastery", "Jajanken"} },
            { name = "Killua Zoldyck", rarity = RARITY_LEVELS.LEGENDARY, power = 850, unlockLevel = 6, abilities = {"Lightning Nen", "Assassin Skills"} },
            { name = "Kurapika", rarity = RARITY_LEVELS.EPIC, power = 700, unlockLevel = 5, abilities = {"Chain Jail", "Scarlet Eyes"} },
            { name = "Leorio Paradinight", rarity = RARITY_LEVELS.RARE, power = 500, unlockLevel = 4, abilities = {"Medical Nen", "Punch"} },
            { name = "Hisoka", rarity = RARITY_LEVELS.UNCOMMON, power = 320, unlockLevel = 3, abilities = {"Bungee Gum", "Texture Surprise"} },
            { name = "Chrollo Lucilfer", rarity = RARITY_LEVELS.COMMON, power = 220, unlockLevel = 2, abilities = {"Skill Hunter", "Bandit's Secret"} }
        }
    },
    FULLMETAL_ALCHEMIST = {
        name = "Fullmetal Alchemist",
        characters = {
            { name = "Edward Elric", rarity = RARITY_LEVELS.MYTHIC, power = 1000, unlockLevel = 7, abilities = {"Alchemy", "Automail"} },
            { name = "Alphonse Elric", rarity = RARITY_LEVELS.LEGENDARY, power = 800, unlockLevel = 6, abilities = {"Soul Binding", "Armor Body"} },
            { name = "Roy Mustang", rarity = RARITY_LEVELS.EPIC, power = 650, unlockLevel = 5, abilities = {"Flame Alchemy", "Fire Control"} },
            { name = "Winry Rockbell", rarity = RARITY_LEVELS.RARE, power = 500, unlockLevel = 4, abilities = {"Automail Engineer", "Mechanical Genius"} },
            { name = "Riza Hawkeye", rarity = RARITY_LEVELS.UNCOMMON, power = 320, unlockLevel = 3, abilities = {"Sharpshooter", "Military Training"} },
            { name = "Maes Hughes", rarity = RARITY_LEVELS.COMMON, power = 220, unlockLevel = 2, abilities = {"Military Intelligence", "Family Man"} }
        }
    },
    DEATH_NOTE = {
        name = "Death Note",
        characters = {
            { name = "Light Yagami", rarity = RARITY_LEVELS.MYTHIC, power = 1000, unlockLevel = 7, abilities = {"Death Note", "Kira's Justice"} },
            { name = "L", rarity = RARITY_LEVELS.LEGENDARY, power = 800, unlockLevel = 6, abilities = {"Detective Genius", "Analytical Mind"} },
            { name = "Misa Amane", rarity = RARITY_LEVELS.EPIC, power = 650, unlockLevel = 5, abilities = {"Second Death Note", "Shinigami Eyes"} },
            { name = "Near", rarity = RARITY_LEVELS.RARE, power = 500, unlockLevel = 4, abilities = {"L's Successor", "Logical Thinking"} },
            { name = "Mello", rarity = RARITY_LEVELS.UNCOMMON, power = 320, unlockLevel = 3, abilities = {"Chocolate Lover", "Strategic Mind"} },
            { name = "Ryuk", rarity = RARITY_LEVELS.COMMON, power = 220, unlockLevel = 2, abilities = {"Shinigami", "Apple Addiction"} }
        }
    },
    TOKYO_GHOUL = {
        name = "Tokyo Ghoul",
        characters = {
            { name = "Kaneki Ken", rarity = RARITY_LEVELS.MYTHIC, power = 1000, unlockLevel = 7, abilities = {"Half-Ghoul", "Kagune Mastery"} },
            { name = "Touka Kirishima", rarity = RARITY_LEVELS.LEGENDARY, power = 800, unlockLevel = 6, abilities = {"Rabbit", "Speed & Agility"} },
            { name = "Ayato Kirishima", rarity = RARITY_LEVELS.EPIC, power = 650, unlockLevel = 5, abilities = {"Black Rabbit", "Kagune Control"} },
            { name = "Hideyoshi Nagachika", rarity = RARITY_LEVELS.RARE, power = 500, unlockLevel = 4, abilities = {"Human Investigator", "Intelligence"} },
            { name = "Kishou Arima", rarity = RARITY_LEVELS.UNCOMMON, power = 320, unlockLevel = 3, abilities = {"CCG Investigator", "Quinque Master"} },
            { name = "Koutarou Amon", rarity = RARITY_LEVELS.COMMON, power = 220, unlockLevel = 2, abilities = {"CCG Investigator", "Justice"} }
        }
    },
    MOB_PSYCHO_100 = {
        name = "Mob Psycho 100",
        characters = {
            { name = "Shigeo Kageyama", rarity = RARITY_LEVELS.MYTHIC, power = 1000, unlockLevel = 7, abilities = {"Psychic Powers", "100% Emotion"} },
            { name = "Arataka Reigen", rarity = RARITY_LEVELS.LEGENDARY, power = 800, unlockLevel = 6, abilities = {"Spirit Consultant", "Manipulation"} },
            { name = "Ritsu Kageyama", rarity = RARITY_LEVELS.EPIC, power = 650, unlockLevel = 5, abilities = {"Psychic Powers", "Emotional Control"} },
            { name = "Teruki Hanazawa", rarity = RARITY_LEVELS.RARE, power = 500, unlockLevel = 4, abilities = {"Psychic Powers", "Aura Control"} },
            { name = "Dimple", rarity = RARITY_LEVELS.UNCOMMON, power = 320, unlockLevel = 3, abilities = {"Evil Spirit", "Possession"} },
            { name = "Tome Kurata", rarity = RARITY_LEVELS.COMMON, power = 220, unlockLevel = 2, abilities = {"Occult Club", "Knowledge"} }
        }
    },
    OVERLORD = {
        name = "Overlord",
        characters = {
            { name = "Ainz Ooal Gown", rarity = RARITY_LEVELS.MYTHIC, power = 1000, unlockLevel = 7, abilities = {"Overlord", "Magic Mastery"} },
            { name = "Albedo", rarity = RARITY_LEVELS.LEGENDARY, power = 800, unlockLevel = 6, abilities = {"Guardian Overseer", "Combat Skills"} },
            { name = "Shalltear Bloodfallen", rarity = RARITY_LEVELS.EPIC, power = 650, unlockLevel = 5, abilities = {"Vampire", "Blood Magic"} },
            { name = "Demiurge", rarity = RARITY_LEVELS.RARE, power = 500, unlockLevel = 4, abilities = {"Demon", "Strategic Mind"} },
            { name = "Cocytus", rarity = RARITY_LEVELS.UNCOMMON, power = 320, unlockLevel = 3, abilities = {"Warrior", "Weapon Mastery"} },
            { name = "Aura Bella Fiora", rarity = RARITY_LEVELS.COMMON, power = 220, unlockLevel = 2, abilities = {"Ranger", "Beast Control"} }
        }
    },
    AVATAR_THE_LAST_AIRBENDER = {
        name = "Avatar: The Last Airbender",
        characters = {
            { name = "Aang", rarity = RARITY_LEVELS.MYTHIC, power = 1000, unlockLevel = 7, abilities = {"Avatar State", "All Four Elements"} },
            { name = "Korra", rarity = RARITY_LEVELS.MYTHIC, power = 1000, unlockLevel = 7, abilities = {"Avatar State", "Metal Bending"} },
            { name = "Zuko", rarity = RARITY_LEVELS.LEGENDARY, power = 850, unlockLevel = 6, abilities = {"Fire Bending", "Lightning Generation"} },
            { name = "Katara", rarity = RARITY_LEVELS.EPIC, power = 700, unlockLevel = 5, abilities = {"Water Bending", "Blood Bending"} },
            { name = "Toph", rarity = RARITY_LEVELS.RARE, power = 550, unlockLevel = 4, abilities = {"Earth Bending", "Metal Bending"} },
            { name = "Sokka", rarity = RARITY_LEVELS.COMMON, power = 250, unlockLevel = 2, abilities = {"Warrior Skills", "Boomerang Mastery"} }
        }
    }
}

-- Spawner configuration
local SPAWNER_CONFIG = {
    baseSpawnInterval = { min = 2, max = 4 }, -- 2-4 seconds
    levelBonus = 0.1, -- 0.1 second reduction per level
    minSpawnInterval = 0.5, -- Minimum spawn time
    maxSpawnCapacity = 10, -- Maximum characters per spawner
    spawnRadius = 15, -- Radius around spawner for character placement
    characterLifetime = 30, -- How long characters exist before despawning
    rarityBonusChance = 0.1, -- 10% chance for rarity bonus on spawn
    collectionRange = 20 -- Range for collecting characters
}

-- Constructor
function CharacterSpawner.new(spawnerData, player)
    local self = setmetatable({}, CharacterSpawner)
    
    -- Core data
    self.spawnerData = spawnerData
    self.player = player
    self.animeTheme = spawnerData.animeTheme
    self.animeCharacters = self:LoadAnimeCharacters()
    
    -- Spawner state
    self.isActive = true
    self.currentLevel = spawnerData.level or 1
    self.spawnInterval = self:CalculateSpawnInterval()
    self.lastSpawnTime = time()
    self.spawnedCharacters = {}
    self.spawnCount = 0
    
    -- Performance optimization
    self.spawnQueue = {}
    self.despawnQueue = {}
    self.lastUpdate = time()
    self.updateInterval = 0.1 -- 10 updates per second
    
    -- Memory management
    self.memoryCategory = "CharacterSpawner"
    self.cachedSpawnData = {}
    
    -- Initialize spawner
    self:InitializeSpawner()
    
    print("CharacterSpawner: Created for " .. self.animeTheme .. " theme, level " .. self.currentLevel)
    
    return self
end

-- Load anime characters for current theme
function CharacterSpawner:LoadAnimeCharacters()
    local themeKey = self.animeTheme:upper():gsub(" ", "_")
    return ANIME_CHARACTERS[themeKey] or ANIME_CHARACTERS.SOLO_LEVELING
end

-- Initialize spawner
function CharacterSpawner:InitializeSpawner()
    -- Create spawner visual if it doesn't exist
    if not self.spawnerData.visualModel then
        self:CreateSpawnerVisual()
    end
    
    -- Start spawn loop
    self:StartSpawnLoop()
end

-- Create spawner visual representation
function CharacterSpawner:CreateSpawnerVisual()
    local model = Instance.new("Model")
    model.Name = "CharacterSpawner_" .. self.animeTheme
    
    -- Create spawner base
    local base = Instance.new("Part")
    base.Name = "SpawnerBase"
    base.Size = Vector3.new(8, 2, 8)
    base.Position = self.spawnerData.position
    base.Anchored = true
    base.Material = Enum.Material.Neon
    base.BrickColor = BrickColor.new("Bright blue")
    base.Parent = model
    
    -- Create spawner core
    local core = Instance.new("Part")
    core.Name = "SpawnerCore"
    core.Size = Vector3.new(4, 6, 4)
    core.Position = self.spawnerData.position + Vector3.new(0, 4, 0)
    core.Anchored = true
    core.Material = Enum.Material.Neon
    core.BrickColor = BrickColor.new("Bright yellow")
    core.Parent = model
    
    -- Add spawner effects
    self:AddSpawnerEffects(model)
    
    self.spawnerData.visualModel = model
    model.Parent = workspace
end

-- Add spawner visual effects
function CharacterSpawner:AddSpawnerEffects(model)
    -- Add pulsing effect to core
    local core = model:FindFirstChild("SpawnerCore")
    if core then
        local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
        local tween = TweenService:Create(core, tweenInfo, {Transparency = 0.3})
        tween:Play()
    end
    
    -- Add level indicator
    local levelIndicator = Instance.new("Part")
    levelIndicator.Name = "LevelIndicator"
    levelIndicator.Size = Vector3.new(2, 2, 2)
    levelIndicator.Position = self.spawnerData.position + Vector3.new(0, 12, 0)
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
    textLabel.Text = "Lv." .. self.currentLevel
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Parent = billboardGui
end

-- Calculate spawn interval based on level
function CharacterSpawner:CalculateSpawnInterval()
    local baseInterval = SPAWNER_CONFIG.baseSpawnInterval
    local levelBonus = SPAWNER_CONFIG.levelBonus
    
    local minInterval = math.max(
        SPAWNER_CONFIG.minSpawnInterval,
        baseInterval.min - (self.currentLevel - 1) * levelBonus
    )
    local maxInterval = math.max(
        SPAWNER_CONFIG.minSpawnInterval,
        baseInterval.max - (self.currentLevel - 1) * levelBonus
    )
    
    return { min = minInterval, max = maxInterval }
end

-- Check if spawner can spawn
function CharacterSpawner:CanSpawn()
    if not self.isActive then return false end
    
    local currentTime = time()
    local timeSinceLastSpawn = currentTime - self.lastSpawnTime
    
    -- Check spawn interval
    local spawnInterval = self.spawnInterval
    if timeSinceLastSpawn < spawnInterval.min then return false end
    
    -- Check spawn capacity
    if #self.spawnedCharacters >= SPAWNER_CONFIG.maxSpawnCapacity then return false end
    
    return true
end

-- Spawn a character
function CharacterSpawner:SpawnCharacter()
    if not self:CanSpawn() then return nil end
    
    -- Select character based on rarity and level
    local character = self:SelectCharacterToSpawn()
    if not character then return nil end
    
    -- Generate spawn position
    local spawnPosition = self:GenerateSpawnPosition()
    
    -- Create character instance
    local characterInstance = self:CreateCharacterInstance(character, spawnPosition)
    if not characterInstance then return nil end
    
    -- Add to spawned characters
    local characterData = {
        instance = characterInstance,
        data = character,
        spawnTime = time(),
        rarity = character.rarity,
        power = character.power,
        abilities = character.abilities
    }
    
    table.insert(self.spawnedCharacters, characterData)
    self.spawnCount = self.spawnCount + 1
    
    -- Update spawn time
    self.lastSpawnTime = time()
    
    -- Add to spawn queue for processing
    table.insert(self.spawnQueue, characterData)
    
    print("CharacterSpawner: Spawned " .. character.name .. " (" .. character.rarity.name .. ") at level " .. self.currentLevel)
    
    return characterData
end

-- Select character to spawn based on rarity and level
function CharacterSpawner:SelectCharacterToSpawn()
    local availableCharacters = {}
    
    -- Filter characters by unlock level
    for _, character in ipairs(self.animeCharacters.characters) do
        if character.unlockLevel <= self.currentLevel then
            table.insert(availableCharacters, character)
        end
    end
    
    if #availableCharacters == 0 then return nil end
    
    -- Apply rarity bonus chance
    local rarityBonus = math.random() < SPAWNER_CONFIG.rarityBonusChance
    
    -- Weight characters by rarity
    local weightedCharacters = {}
    for _, character in ipairs(availableCharacters) do
        local weight = 1.0 / character.rarity.spawnChance
        if rarityBonus and character.rarity.multiplier > 1.5 then
            weight = weight * 2.0 -- Double chance for rare characters during bonus
        end
        
        for i = 1, math.floor(weight) do
            table.insert(weightedCharacters, character)
        end
    end
    
    -- Select random character from weighted list
    if #weightedCharacters > 0 then
        return weightedCharacters[math.random(1, #weightedCharacters)]
    end
    
    return availableCharacters[math.random(1, #availableCharacters)]
end

-- Generate spawn position around spawner
function CharacterSpawner:GenerateSpawnPosition()
    local spawnerPos = self.spawnerData.position
    local radius = SPAWNER_CONFIG.spawnRadius
    
    -- Generate random angle and distance
    local angle = math.random() * 2 * math.pi
    local distance = math.random() * radius
    
    -- Calculate position
    local offsetX = math.cos(angle) * distance
    local offsetZ = math.sin(angle) * distance
    
    return Vector3.new(
        spawnerPos.X + offsetX,
        spawnerPos.Y + 2, -- Slightly above ground
        spawnerPos.Z + offsetZ
    )
end

-- Create character visual instance
function CharacterSpawner:CreateCharacterInstance(character, position)
    local model = Instance.new("Model")
    model.Name = character.name .. "_" .. self.spawnCount
    
    -- Create character body
    local body = Instance.new("Part")
    body.Name = "Body"
    body.Size = Vector3.new(2, 4, 1)
    body.Position = position
    body.Anchored = true
    body.Material = Enum.Material.Neon
    body.BrickColor = BrickColor.new("Bright blue")
    body.Parent = model
    
    -- Apply rarity color
    body.Color = character.rarity.color
    
    -- Create character head
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(1.5, 1.5, 1.5)
    head.Position = position + Vector3.new(0, 2.75, 0)
    head.Anchored = true
    head.Material = Enum.Material.Neon
    head.Color = character.rarity.color
    head.Parent = model
    
    -- Add character info
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 200, 0, 60)
    billboardGui.Parent = head
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = character.name
    nameLabel.TextColor3 = character.rarity.color
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = billboardGui
    
    local rarityLabel = Instance.new("TextLabel")
    rarityLabel.Size = UDim2.new(1, 0, 0.5, 0)
    rarityLabel.Position = UDim2.new(0, 0, 0.5, 0)
    rarityLabel.BackgroundTransparency = 1
    rarityLabel.Text = character.rarity.name
    rarityLabel.TextColor3 = character.rarity.color
    rarityLabel.TextScaled = true
    rarityLabel.Font = Enum.Font.Gotham
    rarityLabel.Parent = billboardGui
    
    -- Add floating effect
    local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
    local tween = TweenService:Create(model, tweenInfo, {Position = position + Vector3.new(0, 0.5, 0)})
    tween:Play()
    
    -- Set lifetime
    Debris:AddItem(model, SPAWNER_CONFIG.characterLifetime)
    
    model.Parent = workspace
    return model
end

-- Update spawner system
function CharacterSpawner:Update()
    local currentTime = time()
    
    -- Check if it's time to update
    if currentTime - self.lastUpdate < self.updateInterval then
        return
    end
    
    self.lastUpdate = currentTime
    
    -- Check if we should spawn
    if self:CanSpawn() then
        self:SpawnCharacter()
    end
    
    -- Process spawn queue
    self:ProcessSpawnQueue()
    
    -- Process despawn queue
    self:ProcessDespawnQueue()
    
    -- Clean up expired characters
    self:CleanupExpiredCharacters()
end

-- Process spawn queue
function CharacterSpawner:ProcessSpawnQueue()
    for i = #self.spawnQueue, 1, -1 do
        local characterData = self.spawnQueue[i]
        if characterData then
            -- Process character spawn effects
            self:ProcessCharacterSpawnEffects(characterData)
            
            -- Remove from queue
            table.remove(self.spawnQueue, i)
        end
    end
end

-- Process despawn queue
function CharacterSpawner:ProcessDespawnQueue()
    for i = #self.despawnQueue, 1, -1 do
        local characterData = self.despawnQueue[i]
        if characterData then
            -- Process character despawn effects
            self:ProcessCharacterDespawnEffects(characterData)
            
            -- Remove from queue
            table.remove(self.despawnQueue, i)
        end
    end
end

-- Process character spawn effects
function CharacterSpawner:ProcessCharacterSpawnEffects(characterData)
    if characterData.instance then
        -- Determine reference part for effect positioning
        local primaryPart = characterData.instance.PrimaryPart
            or characterData.instance:FindFirstChild("Body")
        if not primaryPart then
            return
        end

        -- Add spawn particle effect
        local spawnEffect = Instance.new("Part")
        spawnEffect.Name = "SpawnEffect"
        spawnEffect.Size = Vector3.new(1, 1, 1)
        spawnEffect.Position = primaryPart.Position
        spawnEffect.Anchored = true
        spawnEffect.Material = Enum.Material.Neon
        spawnEffect.Color = characterData.data.rarity.color
        spawnEffect.Transparency = 0.5
        spawnEffect.Parent = workspace
        
        -- Animate spawn effect
        local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(spawnEffect, tweenInfo, {
            Size = Vector3.new(10, 10, 10),
            Transparency = 1
        })
        tween:Play()
        
        -- Clean up effect
        Debris:AddItem(spawnEffect, 1)
    end
end

-- Process character despawn effects
function CharacterSpawner:ProcessCharacterDespawnEffects(characterData)
    if characterData.instance then
        -- Determine reference part for effect positioning
        local primaryPart = characterData.instance.PrimaryPart
            or characterData.instance:FindFirstChild("Body")
        if not primaryPart then
            return
        end

        -- Add despawn particle effect
        local despawnEffect = Instance.new("Part")
        despawnEffect.Name = "DespawnEffect"
        despawnEffect.Size = Vector3.new(1, 1, 1)
        despawnEffect.Position = primaryPart.Position
        despawnEffect.Anchored = true
        despawnEffect.Material = Enum.Material.Neon
        despawnEffect.Color = Color3.new(1, 0, 0) -- Red for despawn
        despawnEffect.Transparency = 0.5
        despawnEffect.Parent = workspace
        
        -- Animate despawn effect
        local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        local tween = TweenService:Create(despawnEffect, tweenInfo, {
            Size = Vector3.new(5, 5, 5),
            Transparency = 1
        })
        tween:Play()
        
        -- Clean up effect
        Debris:AddItem(despawnEffect, 0.5)
    end
end

-- Clean up expired characters
function CharacterSpawner:CleanupExpiredCharacters()
    local currentTime = time()
    
    for i = #self.spawnedCharacters, 1, -1 do
        local characterData = self.spawnedCharacters[i]
        if characterData then
            local timeAlive = currentTime - characterData.spawnTime
            
            if timeAlive >= SPAWNER_CONFIG.characterLifetime then
                -- Add to despawn queue
                table.insert(self.despawnQueue, characterData)
                
                -- Remove from spawned characters
                table.remove(self.spawnedCharacters, i)
                
                -- Destroy instance
                if characterData.instance then
                    characterData.instance:Destroy()
                end
            end
        end
    end
end

-- Upgrade spawner
function CharacterSpawner:Upgrade()
    self.currentLevel = self.currentLevel + 1
    
    -- Recalculate spawn interval
    self.spawnInterval = self:CalculateSpawnInterval()
    
    -- Update visual
    if self.spawnerData.visualModel then
        local levelIndicator = self.spawnerData.visualModel:FindFirstChild("LevelIndicator")
        if levelIndicator then
            local billboardGui = levelIndicator:FindFirstChild("BillboardGui")
            if billboardGui then
                local textLabel = billboardGui:FindFirstChild("TextLabel")
                if textLabel then
                    textLabel.Text = "Lv." .. self.currentLevel
                end
            end
        end
    end
    
    print("CharacterSpawner: Upgraded to level " .. self.currentLevel)
end

-- Get spawner statistics
function CharacterSpawner:GetStats()
    return {
        level = self.currentLevel,
        isActive = self.isActive,
        spawnCount = self.spawnCount,
        spawnedCharacters = #self.spawnedCharacters,
        spawnInterval = self.spawnInterval,
        animeTheme = self.animeTheme,
        lastSpawnTime = self.lastSpawnTime
    }
end

-- Get spawned characters
function CharacterSpawner:GetSpawnedCharacters()
    return self.spawnedCharacters
end

-- Set spawner active state
function CharacterSpawner:SetActive(active)
    self.isActive = active
    print("CharacterSpawner: Set active state to " .. tostring(active))
end

-- Start spawn loop
function CharacterSpawner:StartSpawnLoop()
    if self.updateConnection then
        self.updateConnection:Disconnect()
    end
    
    self.updateConnection = RunService.Heartbeat:Connect(function()
        self:Update()
    end)
    
    print("CharacterSpawner: Started spawn loop")
end

-- Stop spawn loop
function CharacterSpawner:StopSpawnLoop()
    if self.updateConnection then
        self.updateConnection:Disconnect()
        self.updateConnection = nil
    end
    
    print("CharacterSpawner: Stopped spawn loop")
end

-- Destroy spawner and clean up
function CharacterSpawner:Destroy()
    -- Stop update loop
    self:StopSpawnLoop()
    
    -- Remove all spawned characters
    for _, characterData in ipairs(self.spawnedCharacters) do
        if characterData.instance then
            characterData.instance:Destroy()
        end
    end
    
    -- Clear queues
    self.spawnQueue = {}
    self.despawnQueue = {}
    self.spawnedCharacters = {}
    
    -- Clear cached data
    self.cachedSpawnData = {}
    
    print("CharacterSpawner: Destroyed")
end

return CharacterSpawner
