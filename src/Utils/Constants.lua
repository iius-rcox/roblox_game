-- Constants.lua
-- Game constants and configuration values
-- Enhanced with Roblox best practices for performance and memory management

-- NEW: Memory category tagging for better memory tracking (Roblox best practice)
debug.setmemorycategory("Constants")

-- NEW: Use local variables for better performance (Roblox best practice)
local Constants = {}

-- NEW: Game configuration constants (Roblox best practice)
Constants.GAME_CONFIG = {
    VERSION = "3.0.0",
    BUILD_NUMBER = 300,
    SUPPORTED_PLATFORMS = {"PC", "Mobile", "Console"},
    MIN_PLAYERS = 1,
    MAX_PLAYERS = 50,
    AUTO_SAVE_INTERVAL = 30, -- seconds
    MAX_SAVE_SIZE = 1024 * 1024, -- 1MB
    DEBUG_MODE = false,
    PERFORMANCE_MONITORING = true
}

-- NEW: Performance optimization constants (Roblox best practice)
Constants.PERFORMANCE = {
    MAX_UPDATE_FREQUENCY = 60, -- Hz
    MIN_UPDATE_FREQUENCY = 10, -- Hz
    MEMORY_WARNING_THRESHOLD = 100 * 1024 * 1024, -- 100MB
    GARBAGE_COLLECTION_INTERVAL = 5, -- seconds
    MAX_PART_COUNT = 10000,
    MAX_SCRIPT_COUNT = 1000,
    MAX_CONNECTION_COUNT = 1000,
    THROTTLE_DELAY = 0.1, -- seconds
    DEBOUNCE_DELAY = 0.5, -- seconds
    CACHE_SIZE_LIMIT = 1000,
    -- NEW: Critical performance fixes
    MAX_UPDATES_PER_FRAME = 100, -- Prevent frame overload
    UPDATE_BATCH_SIZE = 10, -- Batch updates for efficiency
    CRITICAL_UPDATE_INTERVAL = 0.016, -- 60 FPS target
    BACKGROUND_UPDATE_INTERVAL = 1.0, -- Background tasks every second
    PERFORMANCE_MONITORING_INTERVAL = 0.5 -- Performance checks every 500ms
}

-- NEW: Memory management constants (Roblox best practice)
Constants.MEMORY = {
    MAX_TABLE_SIZE = 10000,
    MAX_STRING_LENGTH = 10000,
    MAX_ARRAY_SIZE = 1000,
    CLEANUP_INTERVAL = 10, -- seconds
    REFERENCE_CLEANUP_DELAY = 5, -- seconds
    WEAK_REFERENCE_ENABLED = true,
    METATABLE_CLEANUP = true,
    -- NEW: Critical memory fixes
    MAX_HISTORY_SIZE = 100, -- Maximum entries in history arrays
    MAX_SNAPSHOT_SIZE = 50, -- Maximum memory snapshots
    MAX_PERFORMANCE_DATA = 200, -- Maximum performance data points
    MAX_PLAYER_DATA_AGE = 3600, -- Archive player data older than 1 hour
    MAX_TYCOON_DATA_AGE = 7200, -- Archive tycoon data older than 2 hours
    ARCHIVE_RETENTION = 24 * 3600, -- Keep archives for 24 hours
    COMPRESSION_THRESHOLD = 1000, -- Compress data larger than 1000 entries
    MEMORY_WARNING_THRESHOLD = 50 * 1024 * 1024 -- 50MB warning
}

-- NEW: Error handling constants (Roblox best practice)
Constants.ERROR_HANDLING = {
    MAX_ERROR_COUNT = 100,
    ERROR_LOG_RETENTION = 24 * 60 * 60, -- 24 hours in seconds
    ERROR_REPORTING_ENABLED = true,
    CRASH_RECOVERY_ENABLED = true,
    MAX_RECOVERY_ATTEMPTS = 3,
    RECOVERY_COOLDOWN = 60 -- seconds
}

-- NEW: Network optimization constants (Roblox best practice)
Constants.NETWORK = {
    MAX_REMOTE_EVENT_SIZE = 1024 * 1024, -- 1MB
    MAX_REMOTE_FUNCTION_SIZE = 512 * 1024, -- 512KB
    NETWORK_UPDATE_RATE = 20, -- Hz
    INTERPOLATION_DELAY = 0.1, -- seconds
    EXTRAPOLATION_ENABLED = true,
    COMPRESSION_ENABLED = true,
    ENCRYPTION_ENABLED = false, -- For performance
    MAX_PACKET_SIZE = 8192 -- bytes
}

-- NEW: UI performance constants (Roblox best practice)
Constants.UI = {
    MAX_UI_ELEMENTS = 1000,
    UI_UPDATE_RATE = 30, -- Hz
    ANIMATION_FRAME_RATE = 60, -- Hz
    MAX_ANIMATION_DURATION = 5, -- seconds
    UI_CACHING_ENABLED = true,
    TEXT_RENDERING_OPTIMIZATION = true,
    IMAGE_COMPRESSION_ENABLED = true
}

-- NEW: Physics optimization constants (Roblox best practice)
Constants.PHYSICS = {
    MAX_PHYSICS_OBJECTS = 5000,
    PHYSICS_UPDATE_RATE = 60, -- Hz
    COLLISION_DETECTION_OPTIMIZATION = true,
    SPATIAL_HASHING_ENABLED = true,
    QUADTREE_DEPTH = 8,
    MAX_COLLISION_GROUPS = 32,
    PHYSICS_CACHING_ENABLED = true
}

-- NEW: Audio optimization constants (Roblox best practice)
Constants.AUDIO = {
    MAX_AUDIO_SOURCES = 100,
    AUDIO_CACHING_ENABLED = true,
    SPATIAL_AUDIO_OPTIMIZATION = true,
    AUDIO_COMPRESSION_ENABLED = true,
    MAX_AUDIO_DISTANCE = 1000,
    AUDIO_FADE_DISTANCE = 500
}

-- NEW: Rendering optimization constants (Roblox best practice)
Constants.RENDERING = {
    MAX_RENDER_DISTANCE = 1000,
    LOD_ENABLED = true,
    OCCLUSION_CULLING_ENABLED = true,
    SHADOW_QUALITY = "Medium",
    TEXTURE_QUALITY = "Medium",
    PARTICLE_LIMIT = 1000,
    MAX_LIGHT_SOURCES = 100
}

-- NEW: Security constants (Roblox best practice)
Constants.SECURITY = {
    MAX_REMOTE_CALLS_PER_SECOND = 100,
    MAX_REMOTE_CALL_SIZE = 1024 * 1024, -- 1MB
    INPUT_VALIDATION_ENABLED = true,
    SANITIZATION_ENABLED = true,
    MAX_SCRIPT_EXECUTION_TIME = 1, -- seconds
    ANTI_EXPLOIT_ENABLED = true,
    RATE_LIMITING_ENABLED = true
}

-- NEW: Logging and monitoring constants (Roblox best practice)
Constants.LOGGING = {
    LOG_LEVEL = "INFO", -- DEBUG, INFO, WARN, ERROR
    MAX_LOG_ENTRIES = 10000,
    LOG_RETENTION_PERIOD = 7 * 24 * 60 * 60, -- 7 days in seconds
    PERFORMANCE_METRICS_ENABLED = true,
    MEMORY_USAGE_TRACKING = true,
    ERROR_TRACKING_ENABLED = true,
    USER_ANALYTICS_ENABLED = false -- Privacy compliance
}

-- NEW: Caching constants (Roblox best practice)
Constants.CACHING = {
    ENABLED = true,
    MAX_CACHE_SIZE = 100 * 1024 * 1024, -- 100MB
    CACHE_TTL = 300, -- 5 minutes in seconds
    CACHE_CLEANUP_INTERVAL = 60, -- seconds
    PERSISTENT_CACHE_ENABLED = true,
    MEMORY_CACHE_ENABLED = true,
    DISK_CACHE_ENABLED = false -- Not available in Roblox
}

-- NEW: Optimization level constants (Roblox best practice)
Constants.OPTIMIZATION_LEVELS = {
    LOW = {
        UPDATE_RATE = 10,
        MAX_OBJECTS = 1000,
        QUALITY = "Low"
    },
    MEDIUM = {
        UPDATE_RATE = 30,
        MAX_OBJECTS = 5000,
        QUALITY = "Medium"
    },
    HIGH = {
        UPDATE_RATE = 60,
        MAX_OBJECTS = 10000,
        QUALITY = "High"
    },
    ULTRA = {
        UPDATE_RATE = 120,
        MAX_OBJECTS = 20000,
        QUALITY = "Ultra"
    }
}

-- NEW: Device-specific constants (Roblox best practice)
Constants.DEVICE_SPECIFIC = {
    MOBILE = {
        MAX_OBJECTS = 2000,
        UPDATE_RATE = 30,
        QUALITY = "Low"
    },
    PC = {
        MAX_OBJECTS = 10000,
        UPDATE_RATE = 60,
        QUALITY = "High"
    },
    CONSOLE = {
        MAX_OBJECTS = 8000,
        UPDATE_RATE = 60,
        QUALITY = "Medium"
    }
}

-- NEW: Feature flags for gradual rollout (Roblox best practice)
Constants.FEATURE_FLAGS = {
    NEW_UI_ENABLED = true,
    ADVANCED_PHYSICS_ENABLED = true,
    REAL_TIME_SHADOWS_ENABLED = false,
    PARTICLE_SYSTEMS_ENABLED = true,
    AUDIO_3D_ENABLED = true,
    NETWORK_OPTIMIZATION_ENABLED = true,
    MEMORY_OPTIMIZATION_ENABLED = true,
    PERFORMANCE_MONITORING_ENABLED = true
}

-- NEW: Environment-specific constants (Roblox best practice)
Constants.ENVIRONMENT = {
    DEVELOPMENT = {
        DEBUG_MODE = true,
        LOG_LEVEL = "DEBUG",
        PERFORMANCE_MONITORING = true,
        ERROR_REPORTING = true
    },
    STAGING = {
        DEBUG_MODE = false,
        LOG_LEVEL = "INFO",
        PERFORMANCE_MONITORING = true,
        ERROR_REPORTING = true
    },
    PRODUCTION = {
        DEBUG_MODE = false,
        LOG_LEVEL = "WARN",
        PERFORMANCE_MONITORING = false,
        ERROR_REPORTING = false
    }
}

-- NEW: Performance thresholds for auto-optimization (Roblox best practice)
Constants.PERFORMANCE_THRESHOLDS = {
    FRAME_RATE_WARNING = 30,
    FRAME_RATE_CRITICAL = 15,
    MEMORY_WARNING = 50 * 1024 * 1024, -- 50MB
    MEMORY_CRITICAL = 100 * 1024 * 1024, -- 100MB
    CPU_WARNING = 80, -- percentage
    CPU_CRITICAL = 95, -- percentage
    NETWORK_LATENCY_WARNING = 100, -- ms
    NETWORK_LATENCY_CRITICAL = 500 -- ms
}

-- NEW: Auto-optimization constants (Roblox best practice)
Constants.AUTO_OPTIMIZATION = {
    ENABLED = true,
    CHECK_INTERVAL = 5, -- seconds
    OPTIMIZATION_COOLDOWN = 30, -- seconds
    MAX_OPTIMIZATION_ATTEMPTS = 5,
    OPTIMIZATION_STRATEGIES = {
        "REDUCE_UPDATE_RATE",
        "REDUCE_OBJECT_COUNT",
        "ENABLE_LOD",
        "REDUCE_QUALITY",
        "ENABLE_CULLING"
    }
}

-- NEW: Memory leak detection constants (Roblox best practice)
Constants.MEMORY_LEAK_DETECTION = {
    ENABLED = true,
    CHECK_INTERVAL = 10, -- seconds
    MEMORY_GROWTH_THRESHOLD = 10 * 1024 * 1024, -- 10MB
    MAX_MEMORY_GROWTH_RATE = 1024 * 1024, -- 1MB per second
    SUSPICIOUS_OBJECT_TYPES = {
        "Connection",
        "BindableEvent",
        "BindableFunction",
        "RemoteEvent",
        "RemoteFunction"
    }
}

-- NEW: Error recovery constants (Roblox best practice)
Constants.ERROR_RECOVERY = {
    MAX_RECOVERY_ATTEMPTS = 3,
    RECOVERY_COOLDOWN = 60, -- seconds
    AUTO_RESTART_ENABLED = true,
    GRACEFUL_DEGRADATION_ENABLED = true,
    FALLBACK_MODE_ENABLED = true,
    RECOVERY_STRATEGIES = {
        "RESTART_SYSTEM",
        "CLEAR_CACHE",
        "REDUCE_QUALITY",
        "DISABLE_FEATURES"
    }
}

-- NEW: Performance monitoring constants (Roblox best practice)
Constants.PERFORMANCE_MONITORING = {
    ENABLED = true,
    METRICS_INTERVAL = 1, -- seconds
    METRICS_RETENTION = 60, -- seconds
    ALERT_THRESHOLDS = {
        FRAME_RATE = 30,
        MEMORY_USAGE = 100 * 1024 * 1024, -- 100MB
        CPU_USAGE = 80, -- percentage
        NETWORK_LATENCY = 200 -- ms
    },
    REPORTING_ENABLED = false -- Privacy compliance
}

-- NEW: Utility functions for constants (Roblox best practice)
function Constants.GetOptimizationLevel(deviceType)
    deviceType = deviceType or "PC"
    local deviceConfig = Constants.DEVICE_SPECIFIC[deviceType]
    if deviceConfig and deviceConfig.QUALITY then
        local qualityKey = string.upper(deviceConfig.QUALITY)
        return Constants.OPTIMIZATION_LEVELS[qualityKey] or Constants.OPTIMIZATION_LEVELS.MEDIUM
    end
    return Constants.OPTIMIZATION_LEVELS.MEDIUM
end

function Constants.IsFeatureEnabled(featureName)
    return Constants.FEATURE_FLAGS[featureName] == true
end

function Constants.GetEnvironmentConfig()
    -- Auto-detect environment based on game settings
    if Constants.GAME_CONFIG.DEBUG_MODE then
        return Constants.ENVIRONMENT.DEVELOPMENT
    else
        return Constants.ENVIRONMENT.PRODUCTION
    end
end

function Constants.ShouldOptimize(performanceMetrics)
    if not Constants.AUTO_OPTIMIZATION.ENABLED then
        return false
    end
    
    local frameRate = performanceMetrics.frameRate or 60
    local memoryUsage = performanceMetrics.memoryUsage or 0
    
    return frameRate < Constants.PERFORMANCE_THRESHOLDS.FRAME_RATE_WARNING or
           memoryUsage > Constants.PERFORMANCE_THRESHOLDS.MEMORY_WARNING
end

function Constants.GetPerformanceThreshold(metricName)
    return Constants.PERFORMANCE_THRESHOLDS[metricName] or 0
end

-- NEW: Constants validation (Roblox best practice)
function Constants.ValidateConstants()
    local errors = {}
    
    -- Validate numeric constants
    for category, constants in pairs(Constants) do
        if type(constants) == "table" then
            for key, value in pairs(constants) do
                if type(value) == "number" and value < 0 then
                    table.insert(errors, string.format("Invalid negative value: %s.%s = %s", category, key, value))
                end
            end
        end
    end
    
    -- Validate required constants
    local requiredConstants = {"GAME_CONFIG", "PERFORMANCE", "MEMORY"}
    for _, constantName in ipairs(requiredConstants) do
        if not Constants[constantName] then
            table.insert(errors, string.format("Missing required constant: %s", constantName))
        end
    end
    
    if #errors > 0 then
        warn("Constants validation errors:")
        for _, error in ipairs(errors) do
            warn("  " .. error)
        end
        return false
    end
    
    return true
end

-- NEW: Constants documentation (Roblox best practice)
Constants.DOCUMENTATION = {
    GAME_CONFIG = "Core game configuration settings",
    PERFORMANCE = "Performance optimization settings",
    MEMORY = "Memory management settings",
    ERROR_HANDLING = "Error handling and recovery settings",
    NETWORK = "Network optimization settings",
    UI = "User interface performance settings",
    PHYSICS = "Physics engine optimization settings",
    AUDIO = "Audio system optimization settings",
    RENDERING = "Rendering quality and performance settings",
    SECURITY = "Security and anti-exploit settings",
    LOGGING = "Logging and monitoring settings",
    CACHING = "Caching system settings",
    OPTIMIZATION_LEVELS = "Performance optimization levels",
    DEVICE_SPECIFIC = "Device-specific optimization settings",
    FEATURE_FLAGS = "Feature enable/disable flags",
    ENVIRONMENT = "Environment-specific settings",
    PERFORMANCE_THRESHOLDS = "Performance warning thresholds",
    AUTO_OPTIMIZATION = "Automatic optimization settings",
    MEMORY_LEAK_DETECTION = "Memory leak detection settings",
    ERROR_RECOVERY = "Error recovery settings",
    PERFORMANCE_MONITORING = "Performance monitoring settings",
    ANIME_THEMES = "Anime series theme configurations",
    WORLD_GENERATION = "World generation and plot positioning constants",
    PLOT_SYSTEM = "Plot management and theme assignment constants"
}

-- NEW: Initialize constants validation on load (Roblox best practice)
if Constants.ValidateConstants() then
    print("Constants validation passed")
else
    warn("Constants validation failed - check warnings above")
end

-- NEW: Initialize plot themes from anime themes (Roblox best practice)
Constants.InitializePlotThemes()

-- NEW: Anime Theme System Constants (Roblox best practice)
Constants.ANIME_THEMES = {
    -- 20 popular anime series themes with color schemes and progression data
    SOLO_LEVELING = {
        name = "Solo Leveling",
        displayName = "Solo Leveling",
        description = "Shadow monarch theme with dark aura effects",
        colors = {
            primary = Color3.fromRGB(75, 0, 130),    -- Dark purple
            secondary = Color3.fromRGB(25, 25, 112), -- Midnight blue
            accent = Color3.fromRGB(138, 43, 226),   -- Blue violet
            highlight = Color3.fromRGB(255, 215, 0)  -- Gold
        },
        progression = {
            ranks = {"E", "D", "C", "B", "A", "S", "National", "Imperial"},
            powerMultipliers = {1, 2, 5, 10, 25, 50, 100, 200},
            maxLevel = 8,
            basePower = 100
        },
        materials = {
            primary = Enum.Material.DarkStone,
            secondary = Enum.Material.Neon,
            accent = Enum.Material.ForceField
        },
        effects = {
            shadowAura = true,
            darkParticles = true,
            purpleGlow = true
        }
    },
    
    NARUTO = {
        name = "Naruto",
        displayName = "Naruto",
        description = "Hidden Leaf Village with ninja training grounds",
        colors = {
            primary = Color3.fromRGB(34, 139, 34),   -- Forest green
            secondary = Color3.fromRGB(255, 140, 0),  -- Dark orange
            accent = Color3.fromRGB(255, 215, 0),     -- Gold
            highlight = Color3.fromRGB(220, 20, 60)   -- Crimson
        },
        progression = {
            ranks = {"Academy", "Genin", "Chunin", "Jonin", "Kage"},
            powerMultipliers = {1, 3, 8, 15, 30},
            maxLevel = 5,
            basePower = 150
        },
        materials = {
            primary = Enum.Material.Grass,
            secondary = Enum.Material.Wood,
            accent = Enum.Material.Neon
        },
        effects = {
            chakraGlow = true,
            leafParticles = true,
            ninjaSmoke = true
        }
    },
    
    ONE_PIECE = {
        name = "One Piece",
        displayName = "One Piece",
        description = "Pirate theme with devil fruit trees and treasure chests",
        colors = {
            primary = Color3.fromRGB(0, 100, 0),     -- Dark green
            secondary = Color3.fromRGB(139, 69, 19),  -- Saddle brown
            accent = Color3.fromRGB(255, 215, 0),     -- Gold
            highlight = Color3.fromRGB(255, 0, 0)     -- Red
        },
        progression = {
            ranks = {"East Blue", "Grand Line", "New World", "Yonko", "Pirate King"},
            powerMultipliers = {1, 5, 15, 40, 100},
            maxLevel = 5,
            basePower = 200
        },
        materials = {
            primary = Enum.Material.Wood,
            secondary = Enum.Material.Metal,
            accent = Enum.Material.Neon
        },
        effects = {
            oceanWaves = true,
            treasureGlow = true,
            pirateFlags = true
        }
    },
    
    BLEACH = {
        name = "Bleach",
        displayName = "Bleach",
        description = "Soul Society architecture with spiritual pressure effects",
        colors = {
            primary = Color3.fromRGB(255, 255, 255),  -- White
            secondary = Color3.fromRGB(0, 191, 255),  -- Deep sky blue
            accent = Color3.fromRGB(138, 43, 226),    -- Blue violet
            highlight = Color3.fromRGB(255, 20, 147)  -- Deep pink
        },
        progression = {
            ranks = {"Human", "Soul Reaper", "Lieutenant", "Captain", "Commander"},
            powerMultipliers = {1, 4, 12, 25, 60},
            maxLevel = 5,
            basePower = 180
        },
        materials = {
            primary = Enum.Material.Marble,
            secondary = Enum.Material.Glass,
            accent = Enum.Material.ForceField
        },
        effects = {
            spiritualPressure = true,
            blueAura = true,
            soulParticles = true
        }
    },
    
    ONE_PUNCH_MAN = {
        name = "One Punch Man",
        displayName = "One Punch Man",
        description = "Hero Association with destroyed cityscape props",
        colors = {
            primary = Color3.fromRGB(128, 128, 128),  -- Gray
            secondary = Color3.fromRGB(255, 0, 0),    -- Red
            accent = Color3.fromRGB(255, 215, 0),     -- Gold
            highlight = Color3.fromRGB(0, 0, 0)       -- Black
        },
        progression = {
            ranks = {"C-Class", "B-Class", "A-Class", "S-Class", "Above S-Class"},
            powerMultipliers = {1, 3, 10, 25, 100},
            maxLevel = 5,
            basePower = 300
        },
        materials = {
            primary = Enum.Material.Concrete,
            secondary = Enum.Material.Metal,
            accent = Enum.Material.Neon
        },
        effects = {
            heroAura = true,
            destructionParticles = true,
            cityRubble = true
        }
    },
    
    CHAINSAW_MAN = {
        name = "Chainsaw Man",
        displayName = "Chainsaw Man",
        description = "Devil hunter office with urban cityscape",
        colors = {
            primary = Color3.fromRGB(47, 79, 79),     -- Dark slate gray
            secondary = Color3.fromRGB(255, 69, 0),   -- Red orange
            accent = Color3.fromRGB(255, 0, 0),       -- Red
            highlight = Color3.fromRGB(255, 255, 255) -- White
        },
        progression = {
            ranks = {"D-Class", "C-Class", "B-Class", "A-Class", "Special Class"},
            powerMultipliers = {1, 2, 6, 15, 35},
            maxLevel = 5,
            basePower = 120
        },
        materials = {
            primary = Enum.Material.Asphalt,
            secondary = Enum.Material.Metal,
            accent = Enum.Material.Neon
        },
        effects = {
            devilAura = true,
            chainsawEffects = true,
            urbanNeon = true
        }
    },
    
    MY_HERO_ACADEMIA = {
        name = "My Hero Academia",
        displayName = "My Hero Academia",
        description = "U.A. High School with hero training facilities",
        colors = {
            primary = Color3.fromRGB(0, 0, 139),      -- Dark blue
            secondary = Color3.fromRGB(255, 215, 0),  -- Gold
            accent = Color3.fromRGB(255, 0, 0),       -- Red
            highlight = Color3.fromRGB(0, 255, 0)     -- Green
        },
        progression = {
            ranks = {"Student", "Hero Student", "Pro Hero", "Top Hero", "Symbol of Peace"},
            powerMultipliers = {1, 4, 12, 25, 50},
            maxLevel = 5,
            basePower = 160
        },
        materials = {
            primary = Enum.Material.Brick,
            secondary = Enum.Material.Metal,
            accent = Enum.Material.Neon
        },
        effects = {
            quirkEffects = true,
            heroAura = true,
            trainingGrounds = true
        }
    },
    
    KAIJU_NO_8 = {
        name = "Kaiju No. 8",
        displayName = "Kaiju No. 8",
        description = "Defense Force headquarters with military equipment",
        colors = {
            primary = Color3.fromRGB(105, 105, 105),  -- Dim gray
            secondary = Color3.fromRGB(0, 100, 0),    -- Dark green
            accent = Color3.fromRGB(255, 0, 0),       -- Red
            highlight = Color3.fromRGB(255, 215, 0)   -- Gold
        },
        progression = {
            ranks = {"Recruit", "Officer", "Captain", "Commander", "General"},
            powerMultipliers = {1, 3, 8, 18, 40},
            maxLevel = 5,
            basePower = 140
        },
        materials = {
            primary = Enum.Material.Metal,
            secondary = Enum.Material.Concrete,
            accent = Enum.Material.Neon
        },
        effects = {
            militaryAura = true,
            kaijuEffects = true,
            defenseSystems = true
        }
    },
    
    BAKI_HANMA = {
        name = "Baki Hanma",
        displayName = "Baki Hanma",
        description = "Underground fighting arenas with traditional dojo",
        colors = {
            primary = Color3.fromRGB(139, 69, 19),    -- Saddle brown
            secondary = Color3.fromRGB(255, 215, 0),  -- Gold
            accent = Color3.fromRGB(220, 20, 60),     -- Crimson
            highlight = Color3.fromRGB(0, 0, 0)       -- Black
        },
        progression = {
            ranks = {"Beginner", "Amateur", "Professional", "Champion", "Legend"},
            powerMultipliers = {1, 2, 5, 12, 25},
            maxLevel = 5,
            basePower = 100
        },
        materials = {
            primary = Enum.Material.Wood,
            secondary = Enum.Material.Metal,
            accent = Enum.Material.Neon
        },
        effects = {
            fightingAura = true,
            dojoAtmosphere = true,
            strengthIndicators = true
        }
    },
    
    DRAGON_BALL = {
        name = "Dragon Ball",
        displayName = "Dragon Ball Z/Super",
        description = "Capsule Corp with gravity training chambers",
        colors = {
            primary = Color3.fromRGB(0, 0, 139),      -- Dark blue
            secondary = Color3.fromRGB(255, 0, 0),    -- Red
            accent = Color3.fromRGB(255, 215, 0),     -- Gold
            highlight = Color3.fromRGB(0, 255, 255)   -- Cyan
        },
        progression = {
            ranks = {"Human", "Saiyan", "Super Saiyan", "SSGSS", "Ultra Instinct"},
            powerMultipliers = {1, 10, 50, 100, 500},
            maxLevel = 5,
            basePower = 500
        },
        materials = {
            primary = Enum.Material.Metal,
            secondary = Enum.Material.Neon,
            accent = Enum.Material.ForceField
        },
        effects = {
            kiAura = true,
            gravityEffects = true,
            transformationGlow = true
        }
    },
    
    DEMON_SLAYER = {
        name = "Demon Slayer",
        displayName = "Demon Slayer",
        description = "Demon slayer corps with traditional Japanese elements",
        colors = {
            primary = Color3.fromRGB(139, 0, 0),      -- Dark red
            secondary = Color3.fromRGB(255, 215, 0),  -- Gold
            accent = Color3.fromRGB(0, 0, 139),       -- Dark blue
            highlight = Color3.fromRGB(255, 255, 255) -- White
        },
        progression = {
            ranks = {"Mizunoto", "Mizunoe", "Kanoto", "Kanoe", "Hashira"},
            powerMultipliers = {1, 2, 5, 12, 30},
            maxLevel = 5,
            basePower = 130
        },
        materials = {
            primary = Enum.Material.Wood,
            secondary = Enum.Material.Metal,
            accent = Enum.Material.Neon
        },
        effects = {
            breathingEffects = true,
            demonAura = true,
            traditionalAtmosphere = true
        }
    },
    
    ATTACK_ON_TITAN = {
        name = "Attack on Titan",
        displayName = "Attack on Titan",
        description = "Wall Maria theme with military structures",
        colors = {
            primary = Color3.fromRGB(128, 128, 128),  -- Gray
            secondary = Color3.fromRGB(139, 69, 19),  -- Saddle brown
            accent = Color3.fromRGB(255, 0, 0),       -- Red
            highlight = Color3.fromRGB(0, 0, 0)       -- Black
        },
        progression = {
            ranks = {"Cadet", "Soldier", "Veteran", "Elite", "Commander"},
            powerMultipliers = {1, 3, 8, 18, 40},
            maxLevel = 5,
            basePower = 110
        },
        materials = {
            primary = Enum.Material.Stone,
            secondary = Enum.Material.Metal,
            accent = Enum.Material.Neon
        },
        effects = {
            militaryAura = true,
            wallStructures = true,
            titanEffects = true
        }
    },
    
    JUJUTSU_KAISEN = {
        name = "Jujutsu Kaisen",
        displayName = "Jujutsu Kaisen",
        description = "Jujutsu High with cursed energy effects",
        colors = {
            primary = Color3.fromRGB(75, 0, 130),     -- Dark purple
            secondary = Color3.fromRGB(255, 0, 0),    -- Red
            accent = Color3.fromRGB(0, 255, 255),     -- Cyan
            highlight = Color3.fromRGB(255, 215, 0)   -- Gold
        },
        progression = {
            ranks = {"Grade 4", "Grade 3", "Grade 2", "Grade 1", "Special Grade"},
            powerMultipliers = {1, 2, 6, 15, 35},
            maxLevel = 5,
            basePower = 140
        },
        materials = {
            primary = Enum.Material.DarkStone,
            secondary = Enum.Material.Neon,
            accent = Enum.Material.ForceField
        },
        effects = {
            cursedEnergy = true,
            barrierEffects = true,
            supernaturalAtmosphere = true
        }
    },
    
    HUNTER_X_HUNTER = {
        name = "Hunter x Hunter",
        displayName = "Hunter x Hunter",
        description = "Hunter Association with nen training facilities",
        colors = {
            primary = Color3.fromRGB(0, 100, 0),      -- Dark green
            secondary = Color3.fromRGB(255, 215, 0),  -- Gold
            accent = Color3.fromRGB(138, 43, 226),    -- Blue violet
            highlight = Color3.fromRGB(255, 0, 0)     -- Red
        },
        progression = {
            ranks = {"D-Class", "C-Class", "B-Class", "A-Class", "S-Class"},
            powerMultipliers = {1, 3, 8, 18, 40},
            maxLevel = 5,
            basePower = 150
        },
        materials = {
            primary = Enum.Material.Grass,
            secondary = Enum.Material.Wood,
            accent = Enum.Material.Neon
        },
        effects = {
            nenAura = true,
            trainingGrounds = true,
            hunterAtmosphere = true
        }
    },
    
    FULLMETAL_ALCHEMIST = {
        name = "Fullmetal Alchemist",
        displayName = "Fullmetal Alchemist",
        description = "Amestris military with alchemy circles",
        colors = {
            primary = Color3.fromRGB(139, 69, 19),    -- Saddle brown
            secondary = Color3.fromRGB(255, 215, 0),  -- Gold
            accent = Color3.fromRGB(0, 0, 139),       -- Dark blue
            highlight = Color3.fromRGB(255, 0, 0)     -- Red
        },
        progression = {
            ranks = {"Student", "State Alchemist", "Major", "Colonel", "General"},
            powerMultipliers = {1, 4, 10, 20, 45},
            maxLevel = 5,
            basePower = 120
        },
        materials = {
            primary = Enum.Material.Metal,
            secondary = Enum.Material.Stone,
            accent = Enum.Material.Neon
        },
        effects = {
            alchemyCircles = true,
            militaryAura = true,
            transmutationEffects = true
        }
    },
    
    DEATH_NOTE = {
        name = "Death Note",
        displayName = "Death Note",
        description = "Modern detective theme with supernatural elements",
        colors = {
            primary = Color3.fromRGB(0, 0, 0),        -- Black
            secondary = Color3.fromRGB(128, 128, 128), -- Gray
            accent = Color3.fromRGB(255, 0, 0),        -- Red
            highlight = Color3.fromRGB(255, 255, 255)  -- White
        },
        progression = {
            ranks = {"Civilian", "Detective", "Investigator", "Special Agent", "Master Detective"},
            powerMultipliers = {1, 2, 5, 12, 25},
            maxLevel = 5,
            basePower = 80
        },
        materials = {
            primary = Enum.Material.Concrete,
            secondary = Enum.Material.Metal,
            accent = Enum.Material.Neon
        },
        effects = {
            detectiveAura = true,
            supernaturalGlow = true,
            modernAtmosphere = true
        }
    },
    
    TOKYO_GHOUL = {
        name = "Tokyo Ghoul",
        displayName = "Tokyo Ghoul",
        description = "Urban cityscape with ghoul investigation themes",
        colors = {
            primary = Color3.fromRGB(47, 79, 79),     -- Dark slate gray
            secondary = Color3.fromRGB(255, 0, 0),    -- Red
            accent = Color3.fromRGB(0, 0, 0),         -- Black
            highlight = Color3.fromRGB(255, 255, 255) -- White
        },
        progression = {
            ranks = {"Human", "Ghoul", "A-Class", "S-Class", "SSS-Class"},
            powerMultipliers = {1, 3, 8, 18, 40},
            maxLevel = 5,
            basePower = 100
        },
        materials = {
            primary = Enum.Material.Asphalt,
            secondary = Enum.Material.Metal,
            accent = Enum.Material.Neon
        },
        effects = {
            ghoulAura = true,
            urbanAtmosphere = true,
            investigationEffects = true
        }
    },
    
    MOB_PSYCHO_100 = {
        name = "Mob Psycho 100",
        displayName = "Mob Psycho 100",
        description = "Psychic research with supernatural effects",
        colors = {
            primary = Color3.fromRGB(75, 0, 130),     -- Dark purple
            secondary = Color3.fromRGB(0, 255, 255),  -- Cyan
            accent = Color3.fromRGB(255, 215, 0),     -- Gold
            highlight = Color3.fromRGB(255, 0, 255)   -- Magenta
        },
        progression = {
            ranks = {"Normal", "Psychic", "High Psychic", "Ultra Psychic", "???%"},
            powerMultipliers = {1, 5, 15, 35, 100},
            maxLevel = 5,
            basePower = 200
        },
        materials = {
            primary = Enum.Material.DarkStone,
            secondary = Enum.Material.Neon,
            accent = Enum.Material.ForceField
        },
        effects = {
            psychicAura = true,
            supernaturalEffects = true,
            researchAtmosphere = true
        }
    },
    
    OVERLORD = {
        name = "Overlord",
        displayName = "Overlord",
        description = "Fantasy castle theme with magical elements",
        colors = {
            primary = Color3.fromRGB(139, 69, 19),    -- Saddle brown
            secondary = Color3.fromRGB(255, 215, 0),  -- Gold
            accent = Color3.fromRGB(138, 43, 226),    -- Blue violet
            highlight = Color3.fromRGB(0, 0, 0)       -- Black
        },
        progression = {
            ranks = {"Commoner", "Adventurer", "Hero", "Legendary Hero", "Overlord"},
            powerMultipliers = {1, 3, 8, 18, 50},
            maxLevel = 5,
            basePower = 160
        },
        materials = {
            primary = Enum.Material.Stone,
            secondary = Enum.Material.Metal,
            accent = Enum.Material.Neon
        },
        effects = {
            magicalAura = true,
            castleAtmosphere = true,
            fantasyElements = true
        }
    },
    
    AVATAR = {
        name = "Avatar",
        displayName = "Avatar",
        description = "Player avatar customization with unique abilities and progression",
        colors = {
            primary = Color3.fromRGB(128, 128, 128),  -- Gray
            secondary = Color3.fromRGB(192, 192, 192), -- Silver
            accent = Color3.fromRGB(255, 215, 0),      -- Gold
            highlight = Color3.fromRGB(0, 255, 255)    -- Cyan
        },
        progression = {
            ranks = {"Beginner", "Intermediate", "Advanced", "Expert", "Master"},
            powerMultipliers = {1, 2, 5, 12, 25},
            maxLevel = 5,
            basePower = 100
        },
        materials = {
            primary = Enum.Material.Plastic,
            secondary = Enum.Material.Metal,
            accent = Enum.Material.Neon
        },
        effects = {
            avatarAura = true,
            playerCustomization = true,
            dynamicElements = true
        }
    }
}

-- NEW: World Generation Constants (Roblox best practice)
Constants.WORLD_GENERATION = {
    -- Central Hub Configuration
    HUB = {
        CENTER = Vector3.new(0, 0, 0),
        SIZE = Vector3.new(200, 50, 200),
        SPAWN_HEIGHT = 10,
        BUILDING_HEIGHT = 30,
        PATH_WIDTH = 20
    },
    
    -- Plot Grid Configuration
    PLOT_GRID = {
        TOTAL_PLOTS = 20,
        PLOTS_PER_ROW = 5,
        PLOTS_PER_COLUMN = 4,
        PLOT_SIZE = Vector3.new(150, 50, 150),
        PLOT_SPACING = 50,
        PLOT_BORDER_HEIGHT = 10,
        PLOT_BORDER_THICKNESS = 2
    },
    
    -- Plot Positioning (4x5 grid formation)
    PLOT_POSITIONS = {
        -- Row 1 (Front)
        {1, Vector3.new(-300, 0, -300), "Front-Left"},
        {2, Vector3.new(-150, 0, -300), "Front-Left-Center"},
        {3, Vector3.new(0, 0, -300), "Front-Center"},
        {4, Vector3.new(150, 0, -300), "Front-Right-Center"},
        {5, Vector3.new(300, 0, -300), "Front-Right"},
        
        -- Row 2
        {6, Vector3.new(-300, 0, -150), "Mid-Left-Front"},
        {7, Vector3.new(-150, 0, -150), "Mid-Left-Center"},
        {8, Vector3.new(0, 0, -150), "Mid-Center-Front"},
        {9, Vector3.new(150, 0, -150), "Mid-Right-Center"},
        {10, Vector3.new(300, 0, -150), "Mid-Right-Front"},
        
        -- Row 3
        {11, Vector3.new(-300, 0, 0), "Mid-Left-Center"},
        {12, Vector3.new(-150, 0, 0), "Center-Left"},
        {13, Vector3.new(0, 0, 0), "Center-Center"},
        {14, Vector3.new(150, 0, 0), "Center-Right"},
        {15, Vector3.new(300, 0, 0), "Mid-Right-Center"},
        
        -- Row 4 (Back)
        {16, Vector3.new(-300, 0, 150), "Mid-Left-Back"},
        {17, Vector3.new(-150, 0, 150), "Back-Left-Center"},
        {18, Vector3.new(0, 0, 150), "Back-Center"},
        {19, Vector3.new(150, 0, 150), "Back-Right-Center"},
        {20, Vector3.new(300, 0, 150), "Mid-Right-Back"}
    },
    
    -- Performance Optimization
    PERFORMANCE = {
        MAX_PARTS_PER_PLOT = 500,
        MAX_DECORATIONS_PER_PLOT = 100,
        STREAMING_DISTANCE = 300,
        LOD_DISTANCE = 150,
        BATCH_SIZE = 10,
        UPDATE_INTERVAL = 0.1
    },
    
    -- Material and Effect Settings
    MATERIALS = {
        DEFAULT_GROUND = Enum.Material.Grass,
        DEFAULT_WALL = Enum.Material.Brick,
        DEFAULT_DECORATION = Enum.Material.Plastic,
        TRANSPARENT = Enum.Material.Glass,
        GLOWING = Enum.Material.Neon,
        FORCE_FIELD = Enum.Material.ForceField
    },
    
    -- Lighting Configuration
    LIGHTING = {
        AMBIENT_COLOR = Color3.fromRGB(100, 100, 100),
        BRIGHTNESS = 2,
        SHADOW_QUALITY = Enum.ShadowQuality.Medium,
        DAY_NIGHT_CYCLE = true,
        CYCLE_DURATION = 600 -- 10 minutes
    }
}

-- NEW: Plot System Constants (Roblox best practice)
Constants.PLOT_SYSTEM = {
    -- Plot Management
    MANAGEMENT = {
        MAX_PLOTS_PER_PLAYER = 3,
        PLOT_CLAIM_COOLDOWN = 30, -- seconds
        PLOT_ABANDON_COOLDOWN = 300, -- 5 minutes
        PLOT_SWITCH_COOLDOWN = 60, -- 1 minute
        AUTO_SAVE_INTERVAL = 30 -- seconds
    },
    
    -- Plot Themes
    THEMES = {
        AVAILABLE_THEMES = {}, -- Will be populated from ANIME_THEMES
        DEFAULT_THEME = "AVATAR",
        THEME_CHANGE_COST = 1000,
        THEME_PREVIEW_ENABLED = true,
        SEASONAL_THEMES_ENABLED = true
    },
    
    -- Plot Features
    FEATURES = {
        BUILDING_ENABLED = true,
        DECORATION_ENABLED = true,
        LIGHTING_ENABLED = true,
        SOUND_ENABLED = true,
        PARTICLE_EFFECTS_ENABLED = true,
        ANIMATION_ENABLED = true
    },
    
    -- Plot Progression
    PROGRESSION = {
        STARTING_LEVEL = 1,
        MAX_LEVEL = 100,
        LEVEL_UP_EXPERIENCE = 1000,
        EXPERIENCE_MULTIPLIER = 1.5,
        BONUS_EXPERIENCE_RATE = 0.1 -- 10% bonus
    },
    
    -- Plot Economy
    ECONOMY = {
        STARTING_CASH = 1000,
        CASH_GENERATION_RATE = 10, -- per second
        CASH_MULTIPLIER_CAP = 100,
        UPGRADE_COST_MULTIPLIER = 1.2,
        DECORATION_COST_MULTIPLIER = 0.8
    }
}

-- NEW: Anime Progression System Constants (Roblox best practice)
Constants.ANIME_PROGRESSION = {
    -- Character Spawning
    CHARACTER_SPAWNING = {
        SPAWN_INTERVAL = {2, 4}, -- Random range in seconds
        MAX_CHARACTERS_PER_PLOT = 50,
        CHARACTER_LIFETIME = 300, -- 5 minutes
        RARITY_WEIGHTS = {
            COMMON = 0.6,      -- 60%
            RARE = 0.25,       -- 25%
            EPIC = 0.1,        -- 10%
            LEGENDARY = 0.04,  -- 4%
            MYTHIC = 0.01      -- 1%
        }
    },
    
    -- Power Scaling
    POWER_SCALING = {
        BASE_POWER_MULTIPLIER = 1.0,
        MAX_POWER_MULTIPLIER = 1000,
        POWER_GROWTH_RATE = 1.1,
        POWER_DECAY_RATE = 0.95,
        POWER_CAP_ENABLED = true
    },
    
    -- Collection System
    COLLECTION = {
        MAX_COLLECTIONS_PER_PLAYER = 1000,
        COLLECTION_DISPLAY_LIMIT = 100,
        TRADE_ENABLED = true,
        TRADE_COOLDOWN = 60, -- 1 minute
        GIFT_ENABLED = true,
        GIFT_COOLDOWN = 300 -- 5 minutes
    },
    
    -- Seasonal Events
    SEASONAL_EVENTS = {
        ENABLED = true,
        EVENT_DURATION = 7 * 24 * 60 * 60, -- 1 week
        EVENT_COOLDOWN = 30 * 24 * 60 * 60, -- 1 month
        MAX_ACTIVE_EVENTS = 3,
        EVENT_BONUS_MULTIPLIER = 2.0
    }
}

-- NEW: Utility functions for anime themes (Roblox best practice)
function Constants.GetAnimeTheme(themeName)
    return Constants.ANIME_THEMES[themeName] or Constants.ANIME_THEMES.AVATAR
end

function Constants.GetAllAnimeThemes()
    local themes = {}
    for themeName, themeData in pairs(Constants.ANIME_THEMES) do
        if themeName ~= "AVATAR" then
            table.insert(themes, {
                name = themeName,
                displayName = themeData.displayName,
                description = themeData.description,
                colors = themeData.colors
            })
        end
    end
    return themes
end

function Constants.GetPlotPosition(plotId)
    for _, plotData in ipairs(Constants.WORLD_GENERATION.PLOT_POSITIONS) do
        if plotData[1] == plotId then
            return plotData[2], plotData[3]
        end
    end
    return Vector3.new(0, 0, 0), "Unknown"
end

function Constants.GetPlotGridPosition(plotId)
    local row = math.ceil(plotId / Constants.WORLD_GENERATION.PLOT_GRID.PLOTS_PER_ROW)
    local col = ((plotId - 1) % Constants.WORLD_GENERATION.PLOT_GRID.PLOTS_PER_ROW) + 1
    return row, col
end

function Constants.IsValidPlotId(plotId)
    return plotId >= 1 and plotId <= Constants.WORLD_GENERATION.PLOT_GRID.TOTAL_PLOTS
end

function Constants.GetAnimeThemeColors(themeName)
    local theme = Constants.GetAnimeTheme(themeName)
    return theme and theme.colors or Constants.ANIME_THEMES.AVATAR.colors
end

function Constants.GetAnimeProgression(themeName)
    local theme = Constants.GetAnimeTheme(themeName)
    return theme and theme.progression or Constants.ANIME_THEMES.AVATAR.progression
end

-- NEW: Initialize plot themes from anime themes (Roblox best practice)
function Constants.InitializePlotThemes()
    Constants.PLOT_SYSTEM.THEMES.AVAILABLE_THEMES = Constants.GetAllAnimeThemes()
    print("Initialized " .. #Constants.PLOT_SYSTEM.THEMES.AVAILABLE_THEMES .. " anime themes for plot system")
end

-- Production mode configuration
Constants.PRODUCTION = {
    ENABLED = false, -- Set to true for production deployment
    
    -- Performance settings for production
    PERFORMANCE = {
        MAX_UPDATE_FREQUENCY = 30, -- Hz (reduced from 60 for production)
        MIN_UPDATE_FREQUENCY = 5,  -- Hz (reduced from 10 for production)
        MEMORY_WARNING_THRESHOLD = 50 * 1024 * 1024, -- 50MB (reduced from 100MB)
        GARBAGE_COLLECTION_INTERVAL = 10, -- seconds (increased from 5 for production)
        MAX_PART_COUNT = 5000,     -- Reduced from 10000 for production
        MAX_SCRIPT_COUNT = 500     -- Reduced from 1000 for production
    },
    
    -- Memory management for production
    MEMORY = {
        MAX_TABLE_SIZE = 5000,     -- Reduced from 10000 for production
        MAX_STRING_LENGTH = 5000,  -- Reduced from 10000 for production
        CLEANUP_INTERVAL = 20,     -- seconds (increased from 10 for production)
        WEAK_REFERENCE_ENABLED = true,
        AGGRESSIVE_CLEANUP = true  -- Enable aggressive cleanup in production
    },
    
    -- Auto-optimization for production
    AUTO_OPTIMIZATION = {
        ENABLED = true,
        CHECK_INTERVAL = 10,       -- seconds (increased from 5 for production)
        OPTIMIZATION_STRATEGIES = {
            "REDUCE_UPDATE_RATE",
            "REDUCE_OBJECT_COUNT",
            "ENABLE_LOD",
            "REDUCE_QUALITY",
            "AGGRESSIVE_MEMORY_CLEANUP" -- NEW: Production-specific strategy
        }
    },
    
    -- Security settings for production
    SECURITY = {
        STRICT_VALIDATION = true,  -- Enable strict input validation
        RATE_LIMITING_ENABLED = true,
        ANTI_EXPLOIT_ENABLED = true,
        AUDIT_LOGGING_ENABLED = true,
        MAX_LOG_SIZE = 1000,       -- Reduced log size for production
        LOG_RETENTION_HOURS = 24   -- Keep logs for 24 hours only
    },
    
    -- Monitoring for production
    MONITORING = {
        ENABLED = true,
        METRICS_INTERVAL = 5,      -- seconds (increased from 1 for production)
        ALERT_THRESHOLDS = {
            MEMORY_USAGE = 80,     -- Alert at 80% memory usage
            CPU_USAGE = 70,        -- Alert at 70% CPU usage
            NETWORK_LATENCY = 200  -- Alert at 200ms latency
        },
        DASHBOARD_ENABLED = false  -- Disable dashboard in production for performance
    },
    
    -- Error handling for production
    ERROR_HANDLING = {
        GRACEFUL_DEGRADATION = true,
        MAX_RETRY_ATTEMPTS = 3,    -- Reduced from 5 for production
        ERROR_RECOVERY_TIMEOUT = 10, -- seconds (reduced from 30 for production)
        SUPPRESS_ERROR_MESSAGES = true, -- Hide detailed errors from players
        LOG_ERRORS_ONLY = true     -- Only log errors, not warnings
    }
}

return Constants
