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
    MAX_UPGRADE_LEVEL = 10
}

-- Save Settings
Constants.SAVE = {
    AUTO_SAVE_INTERVAL = 30, -- seconds
    MAX_SAVE_ATTEMPTS = 3
}

return Constants
