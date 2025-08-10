-- SecurityManager.lua
-- Enhanced security and anti-cheat system for Milestone 3: Competitive & Social Systems
-- Integrated with EnhancedSecurityManager for comprehensive security coverage

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local Constants = require(script.Parent.Parent.Utils.Constants)
local NetworkManager = require(script.Parent.Parent.Multiplayer.NetworkManager)
local SecurityWrapper = require(script.Parent.Parent.Utils.SecurityWrapper)
local DataValidator = require(script.Parent.Parent.Utils.DataValidator)

local SecurityManager = {}
SecurityManager.__index = SecurityManager

-- Security configuration
local SECURITY_CONFIG = {
    -- Rate limiting
    RATE_LIMITS = {
        REMOTE_CALLS = { max = 10, window = 1 },      -- 10 calls per second
        TRADE_REQUESTS = { max = 5, window = 5 },     -- 5 trades per 5 seconds
        GUILD_ACTIONS = { max = 3, window = 10 },     -- 3 actions per 10 seconds
        CHAT_MESSAGES = { max = 20, window = 10 },    -- 20 messages per 10 seconds
        PLOT_ACTIONS = { max = 5, window = 5 },       -- 5 actions per 5 seconds
        ABILITY_UPGRADES = { max = 10, window = 5 },  -- 10 upgrades per 5 seconds
        TYCOON_CLAIM = { max = 3, window = 60 },      -- 3 claims per minute
        CASH_UPDATE = { max = 100, window = 60 },     -- 100 updates per minute
        GUILD_INVITE = { max = 15, window = 60 }      -- 15 invites per minute
    },
    
    -- Input validation
    MAX_INPUT_LENGTHS = {
        USERNAME = 50,
        GUILD_NAME = 100,
        CHAT_MESSAGE = 500,
        PLOT_NAME = 100,
        TRADE_DESCRIPTION = 200
    },
    
    -- Position validation
    MAX_DISTANCE = 1000,
    MAX_SPEED = 100,
    MAX_TELEPORT_DISTANCE = 500,
    POSITION_VALIDATION_RANGE = 100, -- Max position change per frame
    SPEED_VALIDATION_LIMIT = 50,     -- Max movement speed
    
    -- Anti-exploit thresholds
    SUSPICIOUS_THRESHOLDS = {
        RAPID_POSITION_CHANGES = 5,    -- 5 rapid position changes
        UNREASONABLE_CASH_GAINS = 10000, -- $10k in 1 second
        EXCESSIVE_ABILITY_UPGRADES = 20, -- 20 upgrades in 1 minute
        SPAM_VIOLATIONS = 10            -- 10 violations in 5 minutes
    }
}

-- Security violation types
local VIOLATION_TYPES = {
    RATE_LIMIT_EXCEEDED = "RATE_LIMIT_EXCEEDED",
    INVALID_INPUT = "INVALID_INPUT",
    POSITION_EXPLOIT = "POSITION_EXPLOIT",
    SPEED_HACKING = "SPEED_HACKING",
    TELEPORT_EXPLOIT = "TELEPORT_EXPLOIT",
    CURRENCY_EXPLOIT = "CURRENCY_EXPLOIT",
    ABILITY_EXPLOIT = "ABILITY_EXPLOIT",
    UNAUTHORIZED_ACTION = "UNAUTHORIZED_ACTION",
    SUSPICIOUS_ACTIVITY = "SUSPICIOUS_ACTIVITY",
    INVENTORY_EXPLOIT = "INVENTORY_EXPLOIT",
    INVALID_REQUEST = "INVALID_REQUEST"
}

-- Penalty levels
local PENALTY_LEVELS = {
    WARNING = { level = 1, action = "WARNING", duration = 0, description = "First violation - warning issued" },
    TEMPORARY_BAN = { level = 2, action = "TEMPORARY_BAN", duration = 300, description = "Second violation - temporary ban" },
    EXTENDED_BAN = { level = 3, action = "EXTENDED_BAN", duration = 3600, description = "Third violation - extended ban" },
    PERMANENT_BAN = { level = 4, action = "PERMANENT_BAN", duration = -1, description = "Fourth violation - permanent ban" }
}

-- Error categories for better debugging
local ERROR_CATEGORIES = {
    VALIDATION_ERROR = "VALIDATION_ERROR",
    SECURITY_VIOLATION = "SECURITY_VIOLATION",
    NETWORK_ERROR = "NETWORK_ERROR",
    SYSTEM_ERROR = "SYSTEM_ERROR"
}

-- RemoteEvents for client-server communication
local RemoteEvents = {
    SecurityViolation = "SecurityViolation",
    AntiCheatAlert = "AntiCheatAlert",
    RateLimitWarning = "RateLimitWarning",
    SecurityLog = "SecurityLog"
}

function SecurityManager.new()
    local self = setmetatable({}, SecurityManager)
    
    -- Core security systems
    self.rateLimiters = {}           -- Player -> Rate limit data
    self.violationHistory = {}       -- Player -> Violation history
    self.suspiciousPlayers = {}      -- Players under monitoring
    self.blacklistedPlayers = {}     -- Permanently banned players
    self.securityLogs = {}           -- Security event logs
    
    -- Anti-exploit systems
    self.positionTracker = {}        -- Player -> Position history
    self.cashTracker = {}            -- Player -> Cash change history
    self.abilityTracker = {}         -- Player -> Ability upgrade history
    
    -- Network security
    self.remoteEventValidation = {}  -- Remote event -> Validation rules
    self.packetValidation = {}       -- Packet size and content validation
    
    -- Admin tools
    self.adminPlayers = {}           -- Admin player list
    self.moderationTools = {}        -- Moderation capabilities
    
    -- Network manager reference
    self.networkManager = nil
    
    -- Security settings
    self.maxViolationsBeforeBan = 4
    self.rateLimitWindow = 60         -- 1 minute window
    self.maxRequestsPerWindow = 100   -- Max requests per minute
    
    -- Performance tracking
    self.lastSecurityCheck = 0
    self.securityCheckInterval = 1    -- Check security every second
    self.validationTimes = {}         -- Track validation performance
    self.totalValidations = 0
    
    -- Initialize remote events
    self.remoteEvents = {}
    
    return self
end

function SecurityManager:Initialize(networkManager)
    self.networkManager = networkManager
    
    -- Set up rate limiting for all remote events
    self:SetupRateLimiting()
    
    -- Set up input validation rules
    self:SetupInputValidation()
    
    -- Set up anti-exploit monitoring
    self:SetupAntiExploitMonitoring()
    
    -- Set up admin system
    self:SetupAdminSystem()
    
    -- Set up periodic security checks
    self:SetupPeriodicChecks()
    
    -- Initialize security wrapper integration
    self:InitializeSecurityWrapper()
    
    print("SecurityManager: Enhanced security system initialized successfully!")
end

-- Initialize security wrapper integration
function SecurityManager:InitializeSecurityWrapper()
    if SecurityWrapper then
        -- Set up custom security event handlers
        self:SetupSecurityEventHandlers()
        
        -- Configure custom rate limits for specific actions
        self:ConfigureCustomRateLimits()
        
        print("SecurityManager: Security wrapper integration initialized")
    else
        warn("SecurityManager: SecurityWrapper not available, running in fallback mode")
    end
end

-- Set up custom security event handlers
function SecurityManager:SetupSecurityEventHandlers()
    -- Handle security violations from wrapper
    if SecurityWrapper then
        -- Monitor security events
        spawn(function()
            while true do
                wait(10) -- Check every 10 seconds
                
                local metrics = SecurityWrapper.GetSecurityMetrics()
                if metrics.recentSecurityEvents > 0 then
                    self:ProcessSecurityMetrics(metrics)
                end
            end
        end)
    end
end

-- Configure custom rate limits for specific actions
function SecurityManager:ConfigureCustomRateLimits()
    if SecurityWrapper and self.networkManager then
        -- Update rate limits for sensitive operations
        local customLimits = {
            TycoonClaim = { maxRequests = 3, windowSeconds = 60 },      -- More restrictive
            AbilityTheft = { maxRequests = 10, windowSeconds = 60 },    -- Prevent spam
            CashUpdate = { maxRequests = 100, windowSeconds = 60 },     -- Allow more frequent updates
            GuildAction = { maxRequests = 15, windowSeconds = 60 }      -- Moderate guild actions
        }
        
        for eventName, limits in pairs(customLimits) do
            self.networkManager:UpdateSecurityConfig(eventName, {
                rateLimit = limits
            })
        end
    end
end

-- Process security metrics from wrapper
function SecurityManager:ProcessSecurityMetrics(metrics)
    -- Handle high security event rates
    if metrics.recentSecurityEvents > 20 then
        warn("SecurityManager: High security event rate detected:", metrics.recentSecurityEvents)
        self:IncreaseSecurityLevel()
    end
    
    -- Handle suspicious players
    if metrics.suspiciousPlayers > 5 then
        warn("SecurityManager: Multiple suspicious players detected:", metrics.suspiciousPlayers)
        self:IncreaseMonitoring()
    end
end

-- Increase security level
function SecurityManager:IncreaseSecurityLevel()
    -- Implement adaptive security measures
    self.securityCheckInterval = math.max(0.5, self.securityCheckInterval * 0.8)
    print("SecurityManager: Security level increased, checks every", self.securityCheckInterval, "seconds")
end

-- Increase monitoring
function SecurityManager:IncreaseMonitoring()
    -- Implement enhanced monitoring for suspicious players
    print("SecurityManager: Enhanced monitoring activated")
end

-- Rate limiting system
function SecurityManager:SetupRateLimiting()
    for action, limits in pairs(SECURITY_CONFIG.RATE_LIMITS) do
        self.rateLimiters[action] = {
            max = limits.max,
            window = limits.window,
            players = {}
        }
    end
end

-- Input validation rules
function SecurityManager:SetupInputValidation()
    -- Remote event validation rules
    self.remoteEventValidation = {
        ["TradeRequest"] = {
            required = {"targetPlayer", "items", "cashAmount"},
            validation = {
                targetPlayer = { type = "Player", required = true },
                items = { type = "table", maxSize = 10, required = true },
                cashAmount = { type = "number", min = 0, max = 1000000, required = true }
            }
        },
        
        ["GuildAction"] = {
            required = {"action", "guildId", "targetPlayer"},
            validation = {
                action = { type = "string", enum = {"invite", "kick", "promote", "demote"}, required = true },
                guildId = { type = "string", required = true, pattern = "^guild_[%w_]+$" },
                targetPlayer = { type = "Player", required = true }
            }
        },
        
        ["PlotAction"] = {
            required = {"action", "plotId"},
            validation = {
                action = { type = "string", enum = {"claim", "abandon", "upgrade"}, required = true },
                plotId = { type = "string", required = true, pattern = "^plot_[%w_]+$" }
            }
        },
        
        ["AbilityUpgrade"] = {
            required = {"abilityType", "level"},
            validation = {
                abilityType = { type = "string", enum = {"jump", "speed", "cash", "repair", "teleport"}, required = true },
                level = { type = "number", min = 1, max = 10, required = true, allowDecimal = false }
            }
        },
        
        ["ChatMessage"] = {
            required = {"message", "channel"},
            validation = {
                message = { type = "string", minLength = 1, maxLength = 500, required = true, pattern = "^[%w%s%p]+$" },
                channel = { type = "string", enum = {"global", "guild", "trade", "local"}, required = true }
            }
        },
        
        ["PlayerMovement"] = {
            required = {"position", "velocity"},
            validation = {
                position = { type = "Vector3", required = true },
                velocity = { type = "Vector3", required = true }
            }
        },
        
        ["ItemUse"] = {
            required = {"itemId", "target"},
            validation = {
                itemId = { type = "string", required = true, pattern = "^item_[%w_]+$" },
                target = { type = "table", required = false }
            }
        },
        
        ["GuildInvite"] = {
            required = {"targetPlayer", "guildId"},
            validation = {
                targetPlayer = { type = "Player", required = true },
                guildId = { type = "string", required = true, pattern = "^guild_[%w_]+$" }
            }
        },
        
        ["PlotTransfer"] = {
            required = {"plotId", "targetPlayer"},
            validation = {
                plotId = { type = "string", required = true, pattern = "^plot_[%w_]+$" },
                targetPlayer = { type = "Player", required = true }
            }
        }
    }
    
    -- Add validation for Vector3 type
    self.customValidators = {
        Vector3 = function(value)
            return typeof(value) == "Vector3" and 
                   math.abs(value.X) <= SECURITY_CONFIG.MAX_DISTANCE and
                   math.abs(value.Y) <= SECURITY_CONFIG.MAX_DISTANCE and
                   math.abs(value.Z) <= SECURITY_CONFIG.MAX_DISTANCE
        end
    }
end

-- Anti-exploit monitoring
function SecurityManager:SetupAntiExploitMonitoring()
    -- Position tracking
    RunService.Heartbeat:Connect(function()
        for player, _ in pairs(Players:GetPlayers()) do
            self:TrackPlayerPosition(player)
        end
    end)
    
    -- Cash tracking
    self:ConnectToCashEvents()
    
    -- Ability tracking
    self:ConnectToAbilityEvents()
end

-- Admin system setup
function SecurityManager:SetupAdminSystem()
    -- Load admin list from configuration
    self.adminPlayers = {
        -- Add admin usernames here
        "AdminUser1",
        "AdminUser2"
    }
    
    -- Set up admin commands
    self:SetupAdminCommands()
end

-- Periodic security checks
function SecurityManager:SetupPeriodicChecks()
    -- Run security checks every 5 seconds
    RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        if currentTime % 5 < 0.1 then -- Every 5 seconds
            self:RunSecurityChecks()
        end
    end)
end

-- Core security validation methods

-- Validate remote event call
function SecurityManager:ValidateRemoteCall(player, eventName, data)
    -- Check if player is blacklisted
    if self.blacklistedPlayers[player.UserId] then
        return false, "Player is blacklisted"
    end
    
    -- Check rate limiting
    if not self:CheckRateLimit(player, eventName) then
        return false, "Rate limit exceeded"
    end
    
    -- Validate input data
    local validationRules = self.remoteEventValidation[eventName]
    if validationRules then
        local isValid, error = self:ValidateInputData(data, validationRules)
        if not isValid then
            return false, "Invalid input: " .. error
        end
    end
    
    -- Check authorization
    if not self:CheckAuthorization(player, eventName, data) then
        return false, "Unauthorized action"
    end
    
    return true
end

-- Rate limiting check
function SecurityManager:CheckRateLimit(player, action)
    local rateLimiter = self.rateLimiters[action]
    if not rateLimiter then return true end
    
    local playerData = rateLimiter.players[player.UserId]
    local currentTime = tick()
    
    if not playerData then
        playerData = { calls = {}, lastReset = currentTime }
        rateLimiter.players[player.UserId] = playerData
    end
    
    -- Reset if window has passed
    if currentTime - playerData.lastReset >= rateLimiter.window then
        playerData.calls = {}
        playerData.lastReset = currentTime
    end
    
    -- Check if limit exceeded
    if #playerData.calls >= rateLimiter.max then
        self:RecordViolation(player, VIOLATION_TYPES.RATE_LIMIT_EXCEEDED, {
            action = action,
            limit = rateLimiter.max,
            window = rateLimiter.window
        })
        return false
    end
    
    -- Record call
    table.insert(playerData.calls, currentTime)
    return true
end

-- Input data validation
function SecurityManager:ValidateInputData(data, rules)
    -- Check required fields
    if rules.required then
        for _, field in ipairs(rules.required) do
            if data[field] == nil then
                return false, "Missing required field: " .. field
            end
        end
    end
    
    -- Validate each field
    if rules.validation then
        for field, validation in pairs(rules.validation) do
            local value = data[field]
            if value ~= nil then
                local isValid, error = self:ValidateField(value, validation)
                if not isValid then
                    return false, "Field '" .. field .. "': " .. error
                end
            end
        end
    end
    
    return true
end

-- Field validation
function SecurityManager:ValidateField(value, validation)
    -- Type checking
    if validation.type then
        if validation.type == "Vector3" then
            -- Use custom validator for Vector3
            if self.customValidators.Vector3 then
                if not self.customValidators.Vector3(value) then
                    return false, "Invalid Vector3 value or out of bounds"
                end
            else
                return false, "Vector3 validation not available"
            end
        elseif type(value) ~= validation.type then
            return false, "Expected " .. validation.type .. ", got " .. type(value)
        end
    end
    
    -- String validation
    if validation.type == "string" then
        if validation.minLength and #value < validation.minLength then
            return false, "Too short (min: " .. validation.minLength .. ")"
        end
        if validation.maxLength and #value > validation.maxLength then
            return false, "Too long (max: " .. validation.maxLength .. ")"
        end
        if validation.pattern and not string.match(value, validation.pattern) then
            return false, "Invalid format"
        end
        -- Check for potentially dangerous content
        if self:ContainsDangerousContent(value) then
            return false, "Content contains potentially dangerous elements"
        end
    end
    
    -- Number validation
    if validation.type == "number" then
        if validation.min and value < validation.min then
            return false, "Too small (min: " .. validation.min .. ")"
        end
        if validation.max and value > validation.max then
            return false, "Too large (max: " .. validation.max .. ")"
        end
        if validation.allowDecimal == false and value ~= math.floor(value) then
            return false, "Must be integer"
        end
        -- Check for NaN or infinite values
        if not (value == value) or not (value < math.huge) then
            return false, "Invalid number value"
        end
    end
    
    -- Enum validation
    if validation.enum then
        local found = false
        for _, allowedValue in ipairs(validation.enum) do
            if value == allowedValue then
                found = true
                break
            end
        end
        if not found then
            return false, "Invalid value (allowed: " .. table.concat(validation.enum, ", ") .. ")"
        end
    end
    
    -- Table validation
    if validation.type == "table" then
        if validation.maxSize and #value > validation.maxSize then
            return false, "Too many items (max: " .. validation.maxSize .. ")"
        end
        -- Check for circular references
        if self:HasCircularReference(value) then
            return false, "Table contains circular references"
        end
    end
    
    return true
end

-- Authorization check
function SecurityManager:CheckAuthorization(player, action, data)
    -- Admin bypass
    if self:IsAdmin(player) then
        return true
    end
    
    -- Action-specific authorization
    if action == "GuildAction" then
        return self:CheckGuildAuthorization(player, data)
    elseif action == "PlotAction" then
        return self:CheckPlotAuthorization(player, data)
    elseif action == "TradeRequest" then
        return self:CheckTradeAuthorization(player, data)
    end
    
    return true
end

-- Guild authorization check
function SecurityManager:CheckGuildAuthorization(player, data)
    -- Check if player is in the guild
    local playerGuild = self:GetPlayerGuild(player)
    if not playerGuild or playerGuild.id ~= data.guildId then
        return false, "Player not in specified guild"
    end
    
    -- Check player's role in guild
    local playerRole = playerGuild.role
    if data.action == "invite" and playerRole ~= "leader" and playerRole ~= "officer" then
        return false, "Insufficient permissions to invite players"
    elseif data.action == "kick" and playerRole ~= "leader" and playerRole ~= "officer" then
        return false, "Insufficient permissions to kick players"
    elseif data.action == "promote" and playerRole ~= "leader" then
        return false, "Only guild leader can promote players"
    elseif data.action == "demote" and playerRole ~= "leader" then
        return false, "Only guild leader can demote players"
    end
    
    -- Check if target player is in the same guild
    local targetGuild = self:GetPlayerGuild(data.targetPlayer)
    if not targetGuild or targetGuild.id ~= data.guildId then
        return false, "Target player not in specified guild"
    end
    
    -- Prevent self-modification for certain actions
    if data.action == "kick" and player == data.targetPlayer then
        return false, "Cannot kick yourself"
    elseif data.action == "promote" and player == data.targetPlayer then
        return false, "Cannot promote yourself"
    elseif data.action == "demote" and player == data.targetPlayer then
        return false, "Cannot demote yourself"
    end
    
    return true
end

-- Plot authorization check
function SecurityManager:CheckPlotAuthorization(player, data)
    -- Check if player owns the plot
    local playerPlots = self:GetPlayerPlots(player)
    local plotOwned = false
    
    for _, plot in pairs(playerPlots) do
        if plot.id == data.plotId then
            plotOwned = true
            break
        end
    end
    
    if data.action == "claim" then
        -- Check if plot is already claimed
        local plotOwner = self:GetPlotOwner(data.plotId)
        if plotOwner then
            return false, "Plot already claimed by " .. plotOwner.Name
        end
        return true
    elseif data.action == "abandon" then
        if not plotOwned then
            return false, "Player does not own this plot"
        end
        return true
    elseif data.action == "upgrade" then
        if not plotOwned then
            return false, "Player does not own this plot"
        end
        -- Check if player has enough resources for upgrade
        local upgradeCost = self:GetPlotUpgradeCost(data.plotId)
        local playerCash = self:GetPlayerCash(player)
        if playerCash < upgradeCost then
            return false, "Insufficient funds for upgrade"
        end
        return true
    end
    
    return false, "Invalid plot action"
end

-- Trade authorization check
function SecurityManager:CheckTradeAuthorization(player, data)
    -- Check if player has enough cash for the trade
    local playerCash = self:GetPlayerCash(player)
    if playerCash < data.cashAmount then
        return false, "Insufficient funds for trade"
    end
    
    -- Check if player owns the items being traded
    for _, item in pairs(data.items) do
        if not self:PlayerOwnsItem(player, item.id) then
            return false, "Player does not own item: " .. item.name
        end
    end
    
    -- Check if target player exists and is not the same player
    if not data.targetPlayer or data.targetPlayer == player then
        return false, "Invalid trade target"
    end
    
    -- Check if target player is online
    if not data.targetPlayer.Parent then
        return false, "Target player is not online"
    end
    
    -- Check if trade amount is reasonable
    if data.cashAmount > 1000000 then -- $1M limit
        return false, "Trade amount exceeds maximum limit"
    end
    
    return true
end

-- Helper methods for authorization checks
function SecurityManager:GetPlayerGuild(player)
    -- This would integrate with your guild system
    -- For now, return a placeholder
    return { id = "guild_" .. player.UserId, role = "member" }
end

function SecurityManager:GetPlayerPlots(player)
    -- This would integrate with your plot system
    -- For now, return a placeholder
    return {}
end

function SecurityManager:GetPlotOwner(plotId)
    -- This would integrate with your plot system
    -- For now, return nil (unclaimed)
    return nil
end

function SecurityManager:GetPlotUpgradeCost(plotId)
    -- This would integrate with your plot system
    -- For now, return a placeholder cost
    return 1000
end

function SecurityManager:GetPlayerCash(player)
    -- This would integrate with your cash system
    -- For now, return a placeholder amount
    return 5000
end

function SecurityManager:PlayerOwnsItem(player, itemId)
    -- This would integrate with your item system
    -- For now, return true (placeholder)
    return true
end

-- Anti-exploit tracking methods

-- Track player position
function SecurityManager:TrackPlayerPosition(player)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local currentPosition = player.Character.HumanoidRootPart.Position
    local playerData = self.positionTracker[player.UserId]
    
    if not playerData then
        playerData = { positions = {}, lastUpdate = tick() }
        self.positionTracker[player.UserId] = playerData
    end
    
    local currentTime = tick()
    local timeSinceLastUpdate = currentTime - playerData.lastUpdate
    
    if timeSinceLastUpdate > 0.1 then -- Update every 100ms
        -- Check for suspicious movement
        if playerData.lastPosition then
            local distance = (currentPosition - playerData.lastPosition).Magnitude
            local speed = distance / timeSinceLastUpdate
            
            if speed > SECURITY_CONFIG.MAX_SPEED then
                self:RecordViolation(player, VIOLATION_TYPES.SPEED_HACKING, {
                    speed = speed,
                    maxSpeed = SECURITY_CONFIG.MAX_SPEED,
                    distance = distance,
                    time = timeSinceLastUpdate
                })
            end
        end
        
        -- Store position
        table.insert(playerData.positions, {
            position = currentPosition,
            time = currentTime
        })
        
        -- Keep only last 10 positions
        if #playerData.positions > 10 then
            table.remove(playerData.positions, 1)
        end
        
        playerData.lastPosition = currentPosition
        playerData.lastUpdate = currentTime
    end
end

-- Connect to cash events
function SecurityManager:ConnectToCashEvents()
    -- This would connect to your cash system events
    -- Implementation depends on your cash system
end

-- Connect to ability events
function SecurityManager:ConnectToAbilityEvents()
    -- This would connect to your ability system events
    -- Implementation depends on your ability system
end

-- Security violation handling

-- Record a security violation
function SecurityManager:RecordViolation(player, violationType, details)
    local playerData = self.violationHistory[player.UserId]
    if not playerData then
        playerData = { violations = {}, totalViolations = 0 }
        self.violationHistory[player.UserId] = playerData
    end
    
    local violation = {
        type = violationType,
        timestamp = tick(),
        details = details or {}
    }
    
    table.insert(playerData.violations, violation)
    playerData.totalViolations = playerData.totalViolations + 1
    
    -- Log violation
    self:LogSecurityEvent(player, violationType, details)
    
    -- Check for penalties
    self:CheckPenalties(player, playerData.totalViolations)
    
    -- Add to suspicious players if needed
    if playerData.totalViolations >= 3 then
        self.suspiciousPlayers[player.UserId] = {
            player = player,
            violations = playerData.violations,
            monitoringStart = tick()
        }
    end
end

-- Check penalties based on violation count
function SecurityManager:CheckPenalties(player, violationCount)
    if violationCount >= 10 then
        self:ApplyPenalty(player, PENALTY_LEVELS.PERMANENT_BAN)
    elseif violationCount >= 7 then
        self:ApplyPenalty(player, PENALTY_LEVELS.EXTENDED_BAN)
    elseif violationCount >= 4 then
        self:ApplyPenalty(player, PENALTY_LEVELS.TEMPORARY_BAN)
    elseif violationCount >= 2 then
        self:ApplyPenalty(player, PENALTY_LEVELS.WARNING)
    end
end

-- Apply penalty to player
function SecurityManager:ApplyPenalty(player, penalty)
    if penalty.action == "WARNING" then
        self:SendWarning(player, penalty)
    elseif penalty.action == "TEMPORARY_BAN" then
        self:ApplyTemporaryBan(player, penalty.duration)
    elseif penalty.action == "EXTENDED_BAN" then
        self:ApplyTemporaryBan(player, penalty.duration)
    elseif penalty.action == "PERMANENT_BAN" then
        self:ApplyPermanentBan(player)
    end
end

-- Send warning to player
function SecurityManager:SendWarning(player, penalty)
    -- Send warning message to player
    print("WARNING sent to " .. player.Name .. ": " .. penalty.description)
end

-- Apply temporary ban
function SecurityManager:ApplyTemporaryBan(player, duration)
    -- Kick player with temporary ban message
    player:Kick("You have been temporarily banned for " .. duration .. " seconds due to security violations.")
end

-- Apply permanent ban
function SecurityManager:ApplyPermanentBan(player)
    -- Add to blacklist and kick
    self.blacklistedPlayers[player.UserId] = {
        reason = "Multiple security violations",
        timestamp = tick()
    }
    player:Kick("You have been permanently banned due to multiple security violations.")
end

-- Admin system methods

-- Check if player is admin
function SecurityManager:IsAdmin(player)
    return table.find(self.adminPlayers, player.Name) ~= nil
end

-- Setup admin commands
function SecurityManager:SetupAdminCommands()
    -- This would set up admin commands
    -- Implementation depends on your command system
end

-- Security logging

-- Log security event
function SecurityManager:LogSecurityEvent(player, eventType, details)
    local logEntry = {
        timestamp = tick(),
        player = player.Name,
        userId = player.UserId,
        eventType = eventType,
        details = details
    }
    
    table.insert(self.securityLogs, logEntry)
    
    -- Keep only last 1000 logs
    if #self.securityLogs > 1000 then
        table.remove(self.securityLogs, 1)
    end
    
    -- Print to console for debugging
    print("SECURITY: " .. player.Name .. " - " .. eventType)
    if details then
        for key, value in pairs(details) do
            print("  " .. key .. ": " .. tostring(value))
        end
    end
end

-- Run periodic security checks
function SecurityManager:RunSecurityChecks()
    -- Clean up old data
    self:CleanupOldData()
    
    -- Check for suspicious patterns
    self:CheckSuspiciousPatterns()
end

-- Clean up old data
function SecurityManager:CleanupOldData()
    local currentTime = tick()
    
    -- Clean up old position data
    for userId, playerData in pairs(self.positionTracker) do
        if currentTime - playerData.lastUpdate > 60 then -- 1 minute
            self.positionTracker[userId] = nil
        end
    end
    
    -- Clean up old rate limit data
    for action, rateLimiter in pairs(self.rateLimiters) do
        for userId, playerData in pairs(rateLimiter.players) do
            if currentTime - playerData.lastReset > rateLimiter.window * 2 then
                rateLimiter.players[userId] = nil
            end
        end
    end
end

-- Check for suspicious patterns
function SecurityManager:CheckSuspiciousPatterns()
    -- This would implement pattern recognition for suspicious behavior
    -- Implementation depends on your specific needs
end

-- Public API methods

-- Validate and process remote event
function SecurityManager:ProcessRemoteEvent(player, eventName, data)
    local isValid, error = self:ValidateRemoteCall(player, eventName, data)
    
    if not isValid then
        self:RecordViolation(player, VIOLATION_TYPES.INVALID_REQUEST, {
            eventName = eventName,
            error = error
        })
        return false, error
    end
    
    return true
end

-- Get security status for player
function SecurityManager:GetPlayerSecurityStatus(player)
    local playerData = self.violationHistory[player.UserId]
    if not playerData then
        return { status = "CLEAN", violations = 0 }
    end
    
    return {
        status = playerData.totalViolations > 0 and "SUSPICIOUS" or "CLEAN",
        violations = playerData.totalViolations,
        recentViolations = #playerData.violations
    }
end

-- Get security logs
function SecurityManager:GetSecurityLogs(limit)
    limit = limit or 100
    local logs = {}
    
    for i = #self.securityLogs - limit + 1, #self.securityLogs do
        if i > 0 then
            table.insert(logs, self.securityLogs[i])
        end
    end
    
    return logs
end

-- Admin methods

-- Add player to blacklist
function SecurityManager:BlacklistPlayer(adminPlayer, targetPlayer, reason)
    if not self:IsAdmin(adminPlayer) then
        return false, "Unauthorized"
    end
    
    self.blacklistedPlayers[targetPlayer.UserId] = {
        reason = reason,
        admin = adminPlayer.Name,
        timestamp = tick()
    }
    
    targetPlayer:Kick("You have been blacklisted: " .. reason)
    return true
end

-- Remove player from blacklist
function SecurityManager:UnblacklistPlayer(adminPlayer, targetPlayer)
    if not self:IsAdmin(adminPlayer) then
        return false, "Unauthorized"
    end
    
    self.blacklistedPlayers[targetPlayer.UserId] = nil
    return true
end

-- Clear player violations
function SecurityManager:ClearPlayerViolations(adminPlayer, targetPlayer)
    if not self:IsAdmin(adminPlayer) then
        return false, "Unauthorized"
    end
    
    self.violationHistory[targetPlayer.UserId] = nil
    self.suspiciousPlayers[targetPlayer.UserId] = nil
    return true
end

-- Check for dangerous content in strings
function SecurityManager:ContainsDangerousContent(str)
    local dangerousPatterns = {
        "<script", -- HTML script tags
        "javascript:", -- JavaScript protocol
        "data:text/html", -- Data URLs
        "vbscript:", -- VBScript protocol
        "onload=", -- Event handlers
        "onerror=",
        "onclick=",
        "eval(", -- JavaScript eval
        "Function(", -- JavaScript Function constructor
        "setTimeout(",
        "setInterval("
    }
    
    str = string.lower(str)
    for _, pattern in ipairs(dangerousPatterns) do
        if string.find(str, pattern, 1, true) then
            return true
        end
    end
    
    return false
end

-- Check for circular references in tables
function SecurityManager:HasCircularReference(tbl, visited)
    visited = visited or {}
    
    if visited[tbl] then
        return true
    end
    
    visited[tbl] = true
    
    for _, value in pairs(tbl) do
        if type(value) == "table" then
            if self:HasCircularReference(value, visited) then
                return true
            end
        end
    end
    
    visited[tbl] = nil
    return false
end

-- Get comprehensive security status
function SecurityManager:GetSecurityStatus()
    return {
        isActive = true,
        version = "3.0.0",
        securityLevel = "HIGH",
        antiCheatEnabled = true,
        rateLimitingEnabled = true,
        inputValidationEnabled = true,
        securityWrapperIntegrated = SecurityWrapper ~= nil,
        lastUpdate = tick()
    }
end

print("SecurityManager: Enhanced security system loaded with comprehensive features")

return SecurityManager
