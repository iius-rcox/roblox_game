-- Constants.lua
-- Game configuration and constants

local Constants = {}

-- Tycoon Settings
Constants.TYCOON = {
    MAX_FLOORS = 3,
    WALL_HP = 100,
    WALL_REPAIR_RATE = 10, -- HP per second
    CASH_GENERATION_BASE = 10,
    CASH_GENERATION_INTERVAL = 1, -- seconds
    MAX_ABILITY_BUTTONS = 6
}

-- Player Settings
Constants.PLAYER = {
    WALK_SPEED = 16,
    JUMP_POWER = 50,
    DOUBLE_JUMP_POWER = 40,
    MAX_HEALTH = 100,
    RESPAWN_TIME = 3
}

-- NEW: Multiple Tycoon Ownership Settings
Constants.MULTI_TYCOON = {
    MAX_PLOTS_PER_PLAYER = 3,  -- Maximum number of plots a player can own
    PLOT_SWITCHING_COOLDOWN = 5,  -- Seconds between plot switches
    CROSS_TYCOON_BONUS = 1.2,  -- 20% bonus for owning multiple tycoons
    SHARED_ABILITIES = true,  -- Abilities are shared across all tycoons
    SHARED_ECONOMY = true,  -- Cash is shared across all tycoons
    PLOT_SWITCHING_ENABLED = true  -- Whether players can switch between plots
}

-- NEW: Hub and Plot Settings
Constants.HUB = {
    TOTAL_PLOTS = 20,
    PLOTS_PER_ROW = 5,
    PLOT_SPACING = 200,
    PLOT_SIZE = Vector3.new(150, 50, 150),
    HUB_CENTER = Vector3.new(0, 0, 0),
    HUB_SIZE = Vector3.new(1000, 100, 1000)
}

-- NEW: Plot Themes
Constants.PLOT_THEMES = {
    "Anime", "Meme", "Gaming", "Music", "Sports",
    "Food", "Travel", "Technology", "Nature", "Space",
    "Fantasy", "SciFi", "Horror", "Comedy", "Action",
    "Romance", "Mystery", "Adventure", "Strategy", "Racing"
}

-- Ability Settings
Constants.ABILITIES = {
    DOUBLE_JUMP = "DoubleJump",
    SPEED_BOOST = "SpeedBoost",
    JUMP_BOOST = "JumpBoost",
    CASH_MULTIPLIER = "CashMultiplier",
    WALL_REPAIR = "WallRepair",
    TELEPORT = "Teleport"
}

-- Economy Settings
Constants.ECONOMY = {
    STARTING_CASH = 100,
    ABILITY_BASE_COST = 50,
    UPGRADE_COST_MULTIPLIER = 1.5,
    MAX_UPGRADE_LEVEL = 10,
    -- NEW: Multi-tycoon economy bonuses
    MULTI_TYCOON_CASH_BONUS = 0.1,  -- 10% bonus per additional tycoon owned
    MULTI_TYCOON_ABILITY_BONUS = 0.05,  -- 5% ability cost reduction per additional tycoon
    MAX_MULTI_TYCOON_BONUS = 0.3  -- Maximum 30% bonus (3 tycoons)
}

-- Save Settings
Constants.SAVE = {
    AUTO_SAVE_INTERVAL = 30, -- seconds
    MAX_SAVE_ATTEMPTS = 3
}

-- NEW: Network and Sync Settings
Constants.NETWORK = {
    TYCOON_SYNC_INTERVAL = 0.2,  -- Sync tycoon data every 200ms
    CASH_SYNC_INTERVAL = 1.0,  -- Sync cash every 1 second
    OWNERSHIP_SYNC_INTERVAL = 0.5,  -- Sync ownership every 500ms
    PLOT_SWITCH_DELAY = 0.1  -- Delay before allowing plot switch
}

return Constants
