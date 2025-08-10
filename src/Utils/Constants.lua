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
    CACHE_SIZE_LIMIT = 1000
}

-- NEW: Memory management constants (Roblox best practice)
Constants.MEMORY = {
    MAX_TABLE_SIZE = 10000,
    MAX_STRING_LENGTH = 10000,
    MAX_ARRAY_SIZE = 1000,
    CLEANUP_INTERVAL = 10, -- seconds
    REFERENCE_CLEANUP_DELAY = 5, -- seconds
    WEAK_REFERENCE_ENABLED = true,
    METATABLE_CLEANUP = true
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
    return Constants.OPTIMIZATION_LEVELS[Constants.DEVICE_SPECIFIC[deviceType].QUALITY] or Constants.OPTIMIZATION_LEVELS.MEDIUM
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
    PERFORMANCE_MONITORING = "Performance monitoring settings"
}

-- NEW: Initialize constants validation on load (Roblox best practice)
if Constants.ValidateConstants() then
    print("Constants validation passed")
else
    warn("Constants validation failed - check warnings above")
end

return Constants
