-- SecurityWrapper.lua
-- Comprehensive security wrapper for all remote events
-- Implements rate limiting, input validation, and authorization checks

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local DataValidator = require(script.Parent.DataValidator)

local SecurityWrapper = {}

-- Security configuration
local SECURITY_CONFIG = {
    -- Rate limiting settings
    RATE_LIMITS = {
        DEFAULT = { maxRequests = 100, windowSeconds = 60 },
        TYCOON_CLAIM = { maxRequests = 5, windowSeconds = 60 },
        ABILITY_UPDATE = { maxRequests = 50, windowSeconds = 60 },
        CASH_UPDATE = { maxRequests = 200, windowSeconds = 60 },
        CHAT_MESSAGE = { maxRequests = 30, windowSeconds = 60 },
        GUILD_ACTION = { maxRequests = 20, windowSeconds = 60 },
        TRADE_ACTION = { maxRequests = 30, windowSeconds = 60 }
    },
    
    -- Authorization levels
    AUTHORIZATION_LEVELS = {
        NONE = 0,           -- No authorization required
        PLAYER = 1,         -- Must be a valid player
        TYCOON_OWNER = 2,   -- Must own the tycoon
        GUILD_MEMBER = 3,   -- Must be guild member
        GUILD_LEADER = 4,   -- Must be guild leader
        ADMIN = 5           -- Must be admin
    },
    
    -- Maximum data sizes
    MAX_DATA_SIZE = 1024 * 1024, -- 1MB
    
    -- Suspicious activity thresholds
    SUSPICIOUS_THRESHOLDS = {
        RAPID_REQUESTS = 10,    -- Requests per second
        LARGE_DATA = 100 * 1024, -- 100KB
        UNUSUAL_PATTERNS = 5     -- Pattern violations
    }
}

-- Security state tracking
local securityState = {
    playerRequests = {},      -- Player -> Request tracking
    suspiciousPlayers = {},   -- Players under monitoring
    blockedPlayers = {},      -- Temporarily blocked players
    securityLogs = {},        -- Security event logs
    rateLimitCounters = {},   -- Rate limiting counters
    lastCleanup = tick()      -- Last cleanup time
}

-- Security event types
local SECURITY_EVENTS = {
    RATE_LIMIT_EXCEEDED = "RATE_LIMIT_EXCEEDED",
    INVALID_INPUT = "INVALID_INPUT",
    UNAUTHORIZED_ACCESS = "UNAUTHORIZED_ACCESS",
    SUSPICIOUS_ACTIVITY = "SUSPICIOUS_ACTIVITY",
    DATA_SIZE_VIOLATION = "DATA_SIZE_VIOLATION",
    PATTERN_VIOLATION = "PATTERN_VIOLATION"
}

-- Create security wrapper for a remote event
function SecurityWrapper.WrapRemoteEvent(remoteEvent, config)
    config = config or {}
    
    -- Default configuration
    local defaultConfig = {
        eventName = remoteEvent.Name or "Unknown",
        rateLimit = SECURITY_CONFIG.RATE_LIMITS.DEFAULT,
        authorizationLevel = SECURITY_CONFIG.AUTHORIZATION_LEVELS.PLAYER,
        inputSchema = nil,
        maxDataSize = SECURITY_CONFIG.MAX_DATA_SIZE,
        requireValidation = true
    }
    
    -- Merge configurations
    for key, value in pairs(config) do
        defaultConfig[key] = value
    end
    
    -- Store original OnServerEvent
    local originalOnServerEvent = remoteEvent.OnServerEvent
    
    -- Create wrapped event handler
    remoteEvent.OnServerEvent:Connect(function(player, ...)
        local args = {...}
        
        -- Security check 1: Basic player validation
        if not SecurityWrapper.ValidatePlayer(player) then
            SecurityWrapper.LogSecurityEvent(SECURITY_EVENTS.UNAUTHORIZED_ACCESS, player, {
                eventName = defaultConfig.eventName,
                reason = "Invalid player"
            })
            return
        end
        
        -- Security check 2: Rate limiting
        if not SecurityWrapper.CheckRateLimit(player, defaultConfig.eventName, defaultConfig.rateLimit) then
            SecurityWrapper.LogSecurityEvent(SECURITY_EVENTS.RATE_LIMIT_EXCEEDED, player, {
                eventName = defaultConfig.eventName,
                rateLimit = defaultConfig.rateLimit
            })
            return
        end
        
        -- Security check 3: Data size validation
        if not SecurityWrapper.ValidateDataSize(args, defaultConfig.maxDataSize) then
            SecurityWrapper.LogSecurityEvent(SECURITY_EVENTS.DATA_SIZE_VIOLATION, player, {
                eventName = defaultConfig.eventName,
                dataSize = SecurityWrapper.CalculateDataSize(args)
            })
            return
        end
        
        -- Security check 4: Input validation
        if defaultConfig.requireValidation and defaultConfig.inputSchema then
            local isValid, validatedArgs, error = SecurityWrapper.ValidateInput(args, defaultConfig.inputSchema)
            if not isValid then
                SecurityWrapper.LogSecurityEvent(SECURITY_EVENTS.INVALID_INPUT, player, {
                    eventName = defaultConfig.eventName,
                    error = error
                })
                return
            end
            args = validatedArgs
        end
        
        -- Security check 5: Authorization
        if not SecurityWrapper.CheckAuthorization(player, defaultConfig.authorizationLevel, args) then
            SecurityWrapper.LogSecurityEvent(SECURITY_EVENTS.UNAUTHORIZED_ACCESS, player, {
                eventName = defaultConfig.eventName,
                requiredLevel = defaultConfig.authorizationLevel
            })
            return
        end
        
        -- Security check 6: Suspicious activity detection
        if SecurityWrapper.DetectSuspiciousActivity(player, defaultConfig.eventName, args) then
            SecurityWrapper.LogSecurityEvent(SECURITY_EVENTS.SUSPICIOUS_ACTIVITY, player, {
                eventName = defaultConfig.eventName,
                reason = "Suspicious pattern detected"
            })
            -- Don't block, just log for monitoring
        end
        
        -- All security checks passed, execute original handler
        local success, result = pcall(originalOnServerEvent, player, unpack(args))
        if not success then
            warn("SecurityWrapper: Error in wrapped event handler:", result)
            SecurityWrapper.LogSecurityEvent("HANDLER_ERROR", player, {
                eventName = defaultConfig.eventName,
                error = result
            })
        end
        
        return result
    end)
    
    print("SecurityWrapper: Wrapped remote event:", defaultConfig.eventName)
    return remoteEvent
end

-- Validate player object
function SecurityWrapper.ValidatePlayer(player)
    if not player or typeof(player) ~= "Instance" then
        return false
    end
    
    if not player:IsA("Player") then
        return false
    end
    
    if not player.Parent then
        return false
    end
    
    if player.UserId <= 0 then
        return false
    end
    
    return true
end

-- Check rate limiting for a player
function SecurityWrapper.CheckRateLimit(player, eventName, rateLimit)
    local userId = player.UserId
    local currentTime = tick()
    
    -- Initialize player tracking if needed
    if not securityState.rateLimitCounters[userId] then
        securityState.rateLimitCounters[userId] = {}
    end
    
    if not securityState.rateLimitCounters[userId][eventName] then
        securityState.rateLimitCounters[userId][eventName] = {
            requestCount = 0,
            windowStart = currentTime
        }
    end
    
    local counter = securityState.rateLimitCounters[userId][eventName]
    
    -- Check if window has expired
    if currentTime - counter.windowStart >= rateLimit.windowSeconds then
        counter.requestCount = 0
        counter.windowStart = currentTime
    end
    
    -- Check if limit exceeded
    if counter.requestCount >= rateLimit.maxRequests then
        return false
    end
    
    -- Increment counter
    counter.requestCount = counter.requestCount + 1
    
    return true
end

-- Validate data size
function SecurityWrapper.ValidateDataSize(data, maxSize)
    local dataSize = SecurityWrapper.CalculateDataSize(data)
    return dataSize <= maxSize
end

-- Calculate approximate data size
function SecurityWrapper.CalculateDataSize(data)
    local size = 0
    
    if type(data) == "string" then
        size = #data
    elseif type(data) == "number" then
        size = 8
    elseif type(data) == "boolean" then
        size = 1
    elseif type(data) == "table" then
        for key, value in pairs(data) do
            size = size + SecurityWrapper.CalculateDataSize(key)
            size = size + SecurityWrapper.CalculateDataSize(value)
        end
    elseif typeof(data) == "Vector3" then
        size = 24
    elseif typeof(data) == "CFrame" then
        size = 48
    else
        size = 100 -- Default size for unknown types
    end
    
    return size
end

-- Validate input against schema
function SecurityWrapper.ValidateInput(input, schema)
    if type(schema) == "table" then
        return DataValidator.ValidateBatch(input, schema)
    else
        return DataValidator.Validate(input, schema)
    end
end

-- Check authorization level
function SecurityWrapper.CheckAuthorization(player, requiredLevel, args)
    if requiredLevel == SECURITY_CONFIG.AUTHORIZATION_LEVELS.NONE then
        return true
    end
    
    if requiredLevel == SECURITY_CONFIG.AUTHORIZATION_LEVELS.PLAYER then
        return SecurityWrapper.ValidatePlayer(player)
    end
    
    -- Additional authorization checks can be implemented here
    -- For now, return true for higher levels (to be implemented)
    return true
end

-- Detect suspicious activity
function SecurityWrapper.DetectSuspiciousActivity(player, eventName, args)
    local userId = player.UserId
    local currentTime = tick()
    
    -- Initialize player tracking
    if not securityState.playerRequests[userId] then
        securityState.playerRequests[userId] = {
            requestCount = 0,
            lastRequestTime = 0,
            requestHistory = {},
            patternViolations = 0
        }
    end
    
    local playerData = securityState.playerRequests[userId]
    
    -- Check for rapid requests
    local timeSinceLastRequest = currentTime - playerData.lastRequestTime
    if timeSinceLastRequest < 0.1 then -- Less than 100ms between requests
        playerData.patternViolations = playerData.patternViolations + 1
    end
    
    -- Check for large data patterns
    local dataSize = SecurityWrapper.CalculateDataSize(args)
    if dataSize > SECURITY_CONFIG.SUSPICIOUS_THRESHOLDS.LARGE_DATA then
        playerData.patternViolations = playerData.patternViolations + 1
    end
    
    -- Update tracking
    playerData.requestCount = playerData.requestCount + 1
    playerData.lastRequestTime = currentTime
    
    -- Add to history (keep last 10 requests)
    table.insert(playerData.requestHistory, {
        time = currentTime,
        eventName = eventName,
        dataSize = dataSize
    })
    
    if #playerData.requestHistory > 10 then
        table.remove(playerData.requestHistory, 1)
    end
    
    -- Check if suspicious
    if playerData.patternViolations > SECURITY_CONFIG.SUSPICIOUS_THRESHOLDS.UNUSUAL_PATTERNS then
        return true
    end
    
    return false
end

-- Log security events
function SecurityWrapper.LogSecurityEvent(eventType, player, details)
    local logEntry = {
        timestamp = tick(),
        eventType = eventType,
        playerId = player.UserId,
        playerName = player.Name,
        details = details or {}
    }
    
    table.insert(securityState.securityLogs, logEntry)
    
    -- Keep only last 1000 log entries
    if #securityState.securityLogs > 1000 then
        table.remove(securityState.securityLogs, 1)
    end
    
    -- Log to console for debugging
    warn("SecurityWrapper:", eventType, "by", player.Name, ":", HttpService:JSONEncode(details))
end

-- Get security metrics
function SecurityWrapper.GetSecurityMetrics()
    local metrics = {
        totalPlayers = 0,
        suspiciousPlayers = 0,
        blockedPlayers = 0,
        totalSecurityEvents = #securityState.securityLogs,
        recentSecurityEvents = 0
    }
    
    -- Count active players
    for userId, _ in pairs(securityState.playerRequests) do
        if Players:GetPlayerByUserId(userId) then
            metrics.totalPlayers = metrics.totalPlayers + 1
        end
    end
    
    -- Count suspicious players
    for userId, _ in pairs(securityState.suspiciousPlayers) do
        if Players:GetPlayerByUserId(userId) then
            metrics.suspiciousPlayers = metrics.suspiciousPlayers + 1
        end
    end
    
    -- Count blocked players
    for userId, _ in pairs(securityState.blockedPlayers) do
        if Players:GetPlayerByUserId(userId) then
            metrics.blockedPlayers = metrics.blockedPlayers + 1
        end
    end
    
    -- Count recent events (last hour)
    local oneHourAgo = tick() - 3600
    for _, logEntry in ipairs(securityState.securityLogs) do
        if logEntry.timestamp > oneHourAgo then
            metrics.recentSecurityEvents = metrics.recentSecurityEvents + 1
        end
    end
    
    return metrics
end

-- Cleanup old data
function SecurityWrapper.Cleanup()
    local currentTime = tick()
    
    -- Clean up old rate limit counters
    for userId, eventCounters in pairs(securityState.rateLimitCounters) do
        for eventName, counter in pairs(eventCounters) do
            if currentTime - counter.windowStart > 300 then -- 5 minutes
                eventCounters[eventName] = nil
            end
        end
        
        -- Remove empty player entries
        if not next(eventCounters) then
            securityState.rateLimitCounters[userId] = nil
        end
    end
    
    -- Clean up old request history
    for userId, playerData in pairs(securityState.playerRequests) do
        if playerData.requestHistory then
            for i = #playerData.requestHistory, 1, -1 do
                if currentTime - playerData.requestHistory[i].time > 300 then
                    table.remove(playerData.requestHistory, i)
                end
            end
        end
    end
    
    securityState.lastCleanup = currentTime
end

-- Set up periodic cleanup
spawn(function()
    while true do
        wait(60) -- Clean up every minute
        SecurityWrapper.Cleanup()
    end
end)

-- Export configuration and constants
SecurityWrapper.Config = SECURITY_CONFIG
SecurityWrapper.SecurityEvents = SECURITY_EVENTS
SecurityWrapper.AuthorizationLevels = SECURITY_CONFIG.AUTHORIZATION_LEVELS

return SecurityWrapper
