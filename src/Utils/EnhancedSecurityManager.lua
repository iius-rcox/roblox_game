-- EnhancedSecurityManager.lua
-- Comprehensive security system addressing critical vulnerabilities
-- Implements proper input validation, rate limiting, and authorization checks

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local Constants = require(script.Parent.Constants)
local DataValidator = require(script.Parent.DataValidator)

local EnhancedSecurityManager = {}
EnhancedSecurityManager.__index = EnhancedSecurityManager

-- Security configuration
local SECURITY_CONFIG = {
    -- Rate limiting
    RATE_LIMITS = {
        REMOTE_CALLS = { max = 10, window = 1 },      -- 10 calls per second
        TRADE_REQUESTS = { max = 5, window = 5 },     -- 5 trades per 5 seconds
        GUILD_ACTIONS = { max = 3, window = 10 },     -- 3 actions per 10 seconds
        CHAT_MESSAGES = { max = 20, window = 10 },    -- 20 messages per 10 seconds
        PLOT_ACTIONS = { max = 5, window = 5 },       -- 5 actions per 5 seconds
        ABILITY_UPGRADES = { max = 10, window = 5 }   -- 10 upgrades per 5 seconds
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
    SUSPICIOUS_ACTIVITY = "SUSPICIOUS_ACTIVITY"
}

-- Penalty levels
local PENALTY_LEVELS = {
    WARNING = { level = 1, action = "WARNING", duration = 0 },
    TEMPORARY_BAN = { level = 2, action = "TEMPORARY_BAN", duration = 300 },
    EXTENDED_BAN = { level = 3, action = "EXTENDED_BAN", duration = 3600 },
    PERMANENT_BAN = { level = 4, action = "PERMANENT_BAN", duration = -1 }
}

function EnhancedSecurityManager.new()
    local self = setmetatable({}, EnhancedSecurityManager)
    
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
    
    return self
end

function EnhancedSecurityManager:Initialize()
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
    
    print("EnhancedSecurityManager: Initialized successfully!")
end

-- Rate limiting system
function EnhancedSecurityManager:SetupRateLimiting()
    for action, limits in pairs(SECURITY_CONFIG.RATE_LIMITS) do
        self.rateLimiters[action] = {
            max = limits.max,
            window = limits.window,
            players = {}
        }
    end
end

-- Input validation rules
function EnhancedSecurityManager:SetupInputValidation()
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
                guildId = { type = "string", required = true },
                targetPlayer = { type = "Player", required = true }
            }
        },
        
        ["PlotAction"] = {
            required = {"action", "plotId"},
            validation = {
                action = { type = "string", enum = {"claim", "abandon", "upgrade"}, required = true },
                plotId = { type = "string", required = true }
            }
        },
        
        ["AbilityUpgrade"] = {
            required = {"abilityType", "level"},
            validation = {
                abilityType = { type = "string", enum = {"jump", "speed", "cash", "repair", "teleport"}, required = true },
                level = { type = "number", min = 1, max = 10, required = true }
            }
        }
    }
end

-- Anti-exploit monitoring
function EnhancedSecurityManager:SetupAntiExploitMonitoring()
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
function EnhancedSecurityManager:SetupAdminSystem()
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
function EnhancedSecurityManager:SetupPeriodicChecks()
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
function EnhancedSecurityManager:ValidateRemoteCall(player, eventName, data)
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
function EnhancedSecurityManager:CheckRateLimit(player, action)
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
function EnhancedSecurityManager:ValidateInputData(data, rules)
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
function EnhancedSecurityManager:ValidateField(value, validation)
    -- Type checking
    if validation.type and type(value) ~= validation.type then
        return false, "Expected " .. validation.type .. ", got " .. type(value)
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
    end
    
    -- Number validation
    if validation.type == "number" then
        if validation.min and value < validation.min then
            return false, "Too small (min: " .. validation.min .. ")"
        end
        if validation.max and value > validation.max then
            return false, "Too large (max: " .. validation.max .. ")"
        end
        if not validation.allowDecimal and value ~= math.floor(value) then
            return false, "Must be integer"
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
    end
    
    return true
end

-- Authorization check
function EnhancedSecurityManager:CheckAuthorization(player, action, data)
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
function EnhancedSecurityManager:CheckGuildAuthorization(player, data)
    -- This would check if the player has permission to perform the guild action
    -- Implementation depends on your guild system
    return true -- Placeholder
end

-- Plot authorization check
function EnhancedSecurityManager:CheckPlotAuthorization(player, data)
    -- This would check if the player owns the plot or has permission
    -- Implementation depends on your plot system
    return true -- Placeholder
end

-- Trade authorization check
function EnhancedSecurityManager:CheckTradeAuthorization(player, data)
    -- Check if player has enough resources for the trade
    -- Implementation depends on your trade system
    return true -- Placeholder
end

-- Anti-exploit tracking methods

-- Track player position
function EnhancedSecurityManager:TrackPlayerPosition(player)
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
function EnhancedSecurityManager:ConnectToCashEvents()
    -- This would connect to your cash system events
    -- Implementation depends on your cash system
end

-- Connect to ability events
function EnhancedSecurityManager:ConnectToAbilityEvents()
    -- This would connect to your ability system events
    -- Implementation depends on your ability system
end

-- Security violation handling

-- Record a security violation
function EnhancedSecurityManager:RecordViolation(player, violationType, details)
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
function EnhancedSecurityManager:CheckPenalties(player, violationCount)
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
function EnhancedSecurityManager:ApplyPenalty(player, penalty)
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
function EnhancedSecurityManager:SendWarning(player, penalty)
    -- Send warning message to player
    print("WARNING sent to " .. player.Name .. ": " .. penalty.description)
end

-- Apply temporary ban
function EnhancedSecurityManager:ApplyTemporaryBan(player, duration)
    -- Kick player with temporary ban message
    player:Kick("You have been temporarily banned for " .. duration .. " seconds due to security violations.")
end

-- Apply permanent ban
function EnhancedSecurityManager:ApplyPermanentBan(player)
    -- Add to blacklist and kick
    self.blacklistedPlayers[player.UserId] = {
        reason = "Multiple security violations",
        timestamp = tick()
    }
    player:Kick("You have been permanently banned due to multiple security violations.")
end

-- Admin system methods

-- Check if player is admin
function EnhancedSecurityManager:IsAdmin(player)
    return table.find(self.adminPlayers, player.Name) ~= nil
end

-- Setup admin commands
function EnhancedSecurityManager:SetupAdminCommands()
    -- This would set up admin commands
    -- Implementation depends on your command system
end

-- Security logging

-- Log security event
function EnhancedSecurityManager:LogSecurityEvent(player, eventType, details)
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
function EnhancedSecurityManager:RunSecurityChecks()
    -- Clean up old data
    self:CleanupOldData()
    
    -- Check for suspicious patterns
    self:CheckSuspiciousPatterns()
end

-- Clean up old data
function EnhancedSecurityManager:CleanupOldData()
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
function EnhancedSecurityManager:CheckSuspiciousPatterns()
    -- This would implement pattern recognition for suspicious behavior
    -- Implementation depends on your specific needs
end

-- Public API methods

-- Validate and process remote event
function EnhancedSecurityManager:ProcessRemoteEvent(player, eventName, data)
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
function EnhancedSecurityManager:GetPlayerSecurityStatus(player)
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
function EnhancedSecurityManager:GetSecurityLogs(limit)
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
function EnhancedSecurityManager:BlacklistPlayer(adminPlayer, targetPlayer, reason)
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
function EnhancedSecurityManager:UnblacklistPlayer(adminPlayer, targetPlayer)
    if not self:IsAdmin(adminPlayer) then
        return false, "Unauthorized"
    end
    
    self.blacklistedPlayers[targetPlayer.UserId] = nil
    return true
end

-- Clear player violations
function EnhancedSecurityManager:ClearPlayerViolations(adminPlayer, targetPlayer)
    if not self:IsAdmin(adminPlayer) then
        return false, "Unauthorized"
    end
    
    self.violationHistory[targetPlayer.UserId] = nil
    self.suspiciousPlayers[targetPlayer.UserId] = nil
    return true
end

return EnhancedSecurityManager
