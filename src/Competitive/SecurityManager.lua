-- SecurityManager.lua
-- Advanced security and anti-cheat system for Milestone 3: Competitive & Social Systems
-- Enhanced with comprehensive security wrapper integration and improved rate limiting

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Constants = require(script.Parent.Parent.Utils.Constants)
local NetworkManager = require(script.Parent.Parent.Multiplayer.NetworkManager)
local SecurityWrapper = require(script.Parent.Parent.Utils.SecurityWrapper)
local DataValidator = require(script.Parent.Parent.Utils.DataValidator)

local SecurityManager = {}
SecurityManager.__index = SecurityManager

-- Utility functions for enhanced validation (Roblox best practices)
local function isNaN(n: number): boolean
    -- NaN is never equal to itself
    return n ~= n
end

local function isInf(n: number): boolean
    -- Number could be -inf or inf
    return math.abs(n) == math.huge
end

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

-- Security violation types
local VIOLATION_TYPES = {
    POSITION_EXPLOIT = "POSITION_EXPLOIT",
    SPEED_HACKING = "SPEED_HACKING",
    TELEPORT_EXPLOIT = "TELEPORT_EXPLOIT",
    INVENTORY_EXPLOIT = "INVENTORY_EXPLOIT",
    CURRENCY_EXPLOIT = "CURRENCY_EXPLOIT",
    RATE_LIMIT_EXCEEDED = "RATE_LIMIT_EXCEEDED",
    INVALID_REQUEST = "INVALID_REQUEST",
    SUSPICIOUS_ACTIVITY = "SUSPICIOUS_ACTIVITY"
}

-- Penalty levels and actions
local PENALTY_LEVELS = {
    WARNING = {
        level = 1,
        action = "WARNING",
        duration = 0,
        description = "First violation - warning issued"
    },
    TEMPORARY_BAN = {
        level = 2,
        action = "TEMPORARY_BAN",
        duration = 300, -- 5 minutes
        description = "Second violation - temporary ban"
    },
    EXTENDED_BAN = {
        level = 3,
        action = "EXTENDED_BAN",
        duration = 3600, -- 1 hour
        description = "Third violation - extended ban"
    },
    PERMANENT_BAN = {
        level = 4,
        action = "PERMANENT_BAN",
        duration = -1, -- Permanent
        description = "Fourth violation - permanent ban"
    }
}

function SecurityManager.new()
    local self = setmetatable({}, SecurityManager)
    
    -- Core data structures
    self.antiCheat = {}               -- Anti-cheat systems
    self.dataValidation = {}           -- Input validation
    self.rateLimiting = {}            -- Request limiting
    self.securityLogs = {}            -- Security event logging
    self.moderationTools = {}         -- Admin and moderation
    self.playerViolations = {}        -- Player -> Violation History
    self.suspiciousPlayers = {}       -- Players under monitoring
    
    -- Network manager reference
    self.networkManager = nil
    
    -- Initialize remote events
    self.remoteEvents = {}
    
    -- Security settings
    self.maxViolationsBeforeBan = 4
    self.rateLimitWindow = 60         -- 1 minute window
    self.maxRequestsPerWindow = 100   -- Max requests per minute
    self.positionValidationRange = 100 -- Max position change per frame
    self.speedValidationLimit = 50    -- Max movement speed
    
    -- Performance tracking
    self.lastSecurityCheck = 0
    self.securityCheckInterval = 1    -- Check security every second
    self.validationTimes = {}         -- Track validation performance
    self.totalValidations = 0
    
    return self
end

-- Initialize security manager with network integration
function SecurityManager:Initialize(networkManager)
    self.networkManager = networkManager
    
    -- Set up remote events with security wrapper
    self:SetupRemoteEvents()
    
    -- Connect to player events
    self:ConnectPlayerEvents()
    
    -- Initialize anti-cheat systems
    self:InitializeAntiCheat()
    
    -- Set up periodic security checks
    self:SetupPeriodicChecks()
    
    -- Initialize security wrapper integration
    self:InitializeSecurityWrapper()
    
    print("SecurityManager: Initialized successfully with security wrapper integration!")
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
    if metrics.suspiciousPlayers > 0 then
        for userId, _ in pairs(metrics.suspiciousPlayers) do
            local player = Players:GetPlayerByUserId(userId)
            if player then
                self:MonitorPlayer(player)
            end
        end
    end
end

-- Increase security level when threats detected
function SecurityManager:IncreaseSecurityLevel()
    -- Reduce rate limits temporarily
    if SecurityWrapper then
        local currentLimits = SecurityWrapper.Config.RATE_LIMITS
        
        for eventName, limits in pairs(currentLimits) do
            if eventName ~= "DEFAULT" then
                -- Reduce limits by 50%
                local newLimits = {
                    maxRequests = math.floor(limits.maxRequests * 0.5),
                    windowSeconds = limits.windowSeconds
                }
                
                if self.networkManager then
                    self.networkManager:UpdateSecurityConfig(eventName, {
                        rateLimit = newLimits
                    })
                end
            end
        end
        
        print("SecurityManager: Security level increased - rate limits reduced")
    end
end

-- Monitor a suspicious player
function SecurityManager:MonitorPlayer(player)
    local userId = player.UserId
    
    if not self.suspiciousPlayers[userId] then
        self.suspiciousPlayers[userId] = {
            startTime = tick(),
            violations = 0,
            lastCheck = tick()
        }
    end
    
    local playerData = self.suspiciousPlayers[userId]
    playerData.violations = playerData.violations + 1
    playerData.lastCheck = tick()
    
    -- Log monitoring action
    self:LogSecurityEvent(VIOLATION_TYPES.SUSPICIOUS_ACTIVITY, player, {
        reason = "Player under monitoring",
        violations = playerData.violations
    })
    
    -- Take action if violations exceed threshold
    if playerData.violations > 5 then
        self:ApplyPenalty(player, PENALTY_LEVELS.WARNING)
    end
end

-- Apply penalty to player
function SecurityManager:ApplyPenalty(player, penaltyLevel)
    local userId = player.UserId
    
    if not self.playerViolations[userId] then
        self.playerViolations[userId] = {
            violations = {},
            isBanned = false,
            banExpiry = 0
        }
    end
    
    local playerData = self.playerViolations[userId]
    
    -- Add violation
    table.insert(playerData.violations, {
        type = penaltyLevel.action,
        timestamp = tick(),
        level = penaltyLevel.level,
        description = penaltyLevel.description
    })
    
    -- Apply ban if necessary
    if penaltyLevel.duration > 0 then
        playerData.isBanned = true
        playerData.banExpiry = tick() + penaltyLevel.duration
        
        -- Kick player if banned
        if penaltyLevel.duration > 0 then
            player:Kick("Security violation: " .. penaltyLevel.description)
        end
    end
    
    -- Log penalty
    self:LogSecurityEvent(VIOLATION_TYPES.SECURITY_VIOLATION, player, {
        penalty = penaltyLevel.action,
        level = penaltyLevel.level,
        description = penaltyLevel.description
    })
    
    print("SecurityManager: Applied penalty to", player.Name, ":", penaltyLevel.action)
end

-- Check rate limiting for a player (improved implementation)
function SecurityManager:CheckRateLimit(player, requestType)
    local userId = player.UserId
    local currentTime = tick()
    
    -- Initialize player data if needed
    if not self.playerViolations[userId] then
        self.playerViolations[userId] = {
            violations = {},
            requestCount = 0,
            lastRequestTime = currentTime,
            lastPosition = Vector3.new(0, 0, 0),
            lastPositionTime = currentTime,
            isBanned = false,
            banExpiry = 0,
            suspiciousActions = 0
        }
    end
    
    local playerData = self.playerViolations[userId]
    local timeSinceLastRequest = currentTime - playerData.lastRequestTime
    
    -- Reset counter if window has passed
    if timeSinceLastRequest > self.rateLimitWindow then
        playerData.requestCount = 0
        playerData.lastRequestTime = currentTime
    end
    
    -- Check if limit exceeded
    if playerData.requestCount >= self.maxRequestsPerWindow then
        self:LogSecurityEvent(VIOLATION_TYPES.RATE_LIMIT_EXCEEDED, player, {
            requestType = requestType,
            requestCount = playerData.requestCount,
            limit = self.maxRequestsPerWindow
        })
        return false
    end
    
    -- Increment counter
    playerData.requestCount = playerData.requestCount + 1
    playerData.lastRequestTime = currentTime
    
    return true
end

-- Log validation time for performance monitoring
function SecurityManager:LogValidationTime(startTime, validationType)
    local endTime = tick()
    local duration = endTime - startTime
    
    if not self.validationTimes[validationType] then
        self.validationTimes[validationType] = {
            totalTime = 0,
            count = 0,
            minTime = math.huge,
            maxTime = 0
        }
    end
    
    local stats = self.validationTimes[validationType]
    stats.totalTime = stats.totalTime + duration
    stats.count = stats.count + 1
    stats.minTime = math.min(stats.minTime, duration)
    stats.maxTime = math.max(stats.maxTime, duration)
    
    self.totalValidations = self.totalValidations + 1
end

-- Get performance metrics for monitoring
function SecurityManager:GetPerformanceMetrics()
    local metrics = {
        activePlayers = 0,
        securityChecksPerSecond = 1 / self.securityCheckInterval,
        totalValidations = self.totalValidations,
        averageValidationTime = 0,
        validationBreakdown = {},
        memoryUsage = self:GetMemoryUsage()
    }
    
    -- Calculate active players
    for userId, _ in pairs(self.playerViolations) do
        if Players:GetPlayerByUserId(userId) then
            metrics.activePlayers = metrics.activePlayers + 1
        end
    end
    
    -- Calculate validation performance
    local totalTime = 0
    local totalCount = 0
    for validationType, stats in pairs(self.validationTimes) do
        totalTime = totalTime + stats.totalTime
        totalCount = totalCount + stats.count
        
        metrics.validationBreakdown[validationType] = {
            averageTime = stats.count > 0 and stats.totalTime / stats.count or 0,
            minTime = stats.minTime,
            maxTime = stats.maxTime,
            count = stats.count
        }
    end
    
    metrics.averageValidationTime = totalCount > 0 and totalTime / totalCount or 0
    
    return metrics
end

-- Get memory usage information
function SecurityManager:GetMemoryUsage()
    local memoryInfo = {
        playerViolations = 0,
        securityLogs = 0,
        antiCheat = 0,
        suspiciousPlayers = 0
    }
    
    -- Count entries in major data structures
    for _ in pairs(self.playerViolations) do
        memoryInfo.playerViolations = memoryInfo.playerViolations + 1
    end
    
    for _ in pairs(self.securityLogs) do
        memoryInfo.securityLogs = memoryInfo.securityLogs + 1
    end
    
    for _ in pairs(self.antiCheat) do
        memoryInfo.antiCheat = memoryInfo.antiCheat + 1
    end
    
    for _ in pairs(self.suspiciousPlayers) do
        memoryInfo.suspiciousPlayers = memoryInfo.suspiciousPlayers + 1
    end
    
    return memoryInfo
end

-- Public API for performance monitoring
function SecurityManager:GetSecurityMetrics()
    local baseMetrics = {
        performance = self:GetPerformanceMetrics(),
        violations = self:GetViolationSummary(),
        systemHealth = self:GetSystemHealth()
    }
    
    -- Add security wrapper metrics if available
    if SecurityWrapper then
        baseMetrics.wrapperMetrics = SecurityWrapper.GetSecurityMetrics()
    end
    
    return baseMetrics
end

-- Get violation summary for monitoring
function SecurityManager:GetViolationSummary()
    local summary = {
        totalViolations = 0,
        violationsByType = {},
        activeBans = 0,
        suspiciousPlayers = 0
    }
    
    -- Count violations by type
    for userId, playerData in pairs(self.playerViolations) do
        if playerData.violations then
            for _, violation in ipairs(playerData.violations) do
                summary.totalViolations = summary.totalViolations + 1
                summary.violationsByType[violation.type] = (summary.violationsByType[violation.type] or 0) + 1
            end
        end
        
        if playerData.isBanned then
            summary.activeBans = summary.activeBans + 1
        end
        
        if playerData.suspiciousActions > 5 then
            summary.suspiciousPlayers = summary.suspiciousPlayers + 1
        end
    end
    
    return summary
end

-- Get system health status
function SecurityManager:GetSystemHealth()
    local health = {
        status = "HEALTHY",
        issues = {},
        recommendations = {}
    }
    
    -- Check for potential issues
    local currentTime = tick()
    local lastCheck = self.lastSecurityCheck
    
    if currentTime - lastCheck > 10 then
        health.status = "WARNING"
        table.insert(health.issues, "Security checks may be delayed")
        table.insert(health.recommendations, "Check server performance")
    end
    
    -- Check memory usage
    local memoryUsage = self:GetMemoryUsage()
    if memoryUsage.playerViolations > 1000 then
        health.status = "WARNING"
        table.insert(health.issues, "High memory usage in player violations")
        table.insert(health.recommendations, "Consider cleanup of old violation data")
    end
    
    -- Check validation performance
    local metrics = self:GetPerformanceMetrics()
    if metrics.averageValidationTime > 0.01 then
        health.status = "WARNING"
        table.insert(health.issues, "Slow validation performance")
        table.insert(health.recommendations, "Optimize validation algorithms")
    end
    
    -- Check security wrapper health
    if SecurityWrapper then
        local wrapperMetrics = SecurityWrapper.GetSecurityMetrics()
        if wrapperMetrics.recentSecurityEvents > 50 then
            health.status = "WARNING"
            table.insert(health.issues, "High security event rate")
            table.insert(health.recommendations, "Review security policies")
        end
    end
    
    return health
end

-- Set up remote events for client-server communication
function SecurityManager:SetupRemoteEvents()
    if self.networkManager then
        -- Create security-specific remote events
        for eventName, eventId in pairs(RemoteEvents) do
            local remote = self.networkManager:CreateSecureRemoteEvent(eventId, {
                rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
                authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
                requireValidation = true
            })
            self.remoteEvents[eventName] = remote
        end
    end
end

-- Connect to player events for monitoring
function SecurityManager:ConnectPlayerEvents()
    Players.PlayerAdded:Connect(function(player)
        self:InitializePlayerSecurity(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:CleanupPlayerSecurity(player)
    end)
end

-- Initialize security monitoring for a player
function SecurityManager:InitializePlayerSecurity(player)
    local playerData = {
        violations = {},
        requestCount = 0,
        lastRequestTime = 0,
        lastPosition = Vector3.new(0, 0, 0),
        lastPositionTime = 0,
        isBanned = false,
        banExpiry = 0,
        suspiciousActions = 0
    }
    
    self.playerViolations[player.UserId] = playerData
    self.antiCheat[player.UserId] = {}
    
    print("SecurityManager: Initialized security for player " .. player.Name)
end

-- Clean up security data for a player
function SecurityManager:CleanupPlayerSecurity(player)
    local userId = player.UserId
    self.playerViolations[userId] = nil
    self.antiCheat[userId] = nil
    self.suspiciousPlayers[userId] = nil
    
    print("SecurityManager: Cleaned up security for player " .. player.Name)
end

-- Initialize anti-cheat systems
function SecurityManager:InitializeAntiCheat()
    -- Position validation
    self.antiCheat.positionValidation = true
    
    -- Speed validation
    self.antiCheat.speedValidation = true
    
    -- Inventory validation
    self.antiCheat.inventoryValidation = true
    
    -- Currency validation
    self.antiCheat.currencyValidation = true
    
    -- Request validation
    self.antiCheat.requestValidation = true
    
    print("SecurityManager: Anti-cheat systems initialized")
end

-- Set up periodic security checks
function SecurityManager:SetupPeriodicChecks()
    RunService.Heartbeat:Connect(function()
        self:PerformSecurityChecks()
    end)
end

-- Perform periodic security checks
function SecurityManager:PerformSecurityChecks()
    local currentTime = tick()
    
    -- Only check every interval
    if currentTime - self.lastSecurityCheck < self.securityCheckInterval then
        return
    end
    
    self.lastSecurityCheck = currentTime
    
    -- Check all players for suspicious activity
    for userId, playerData in pairs(self.playerViolations) do
        local player = Players:GetPlayerByUserId(userId)
        if player then
            self:CheckPlayerSecurity(player, playerData)
        end
    end
    
    -- Reset rate limiting counters
    self:ResetRateLimitCounters()
end

-- Check security for a specific player
function SecurityManager:CheckPlayerSecurity(player, playerData)
    -- Check if player is banned
    if playerData.isBanned then
        if playerData.banExpiry > 0 and tick() > playerData.banExpiry then
            -- Ban expired, remove ban
            playerData.isBanned = false
            playerData.banExpiry = 0
            print("SecurityManager: Ban expired for player " .. player.Name)
        else
            -- Player is still banned, kick if they somehow rejoined
            if player.Parent then
                player:Kick("You are banned for security violations")
            end
        end
    end
    
    -- Check for suspicious position changes
    if self.antiCheat.positionValidation then
        self:ValidatePlayerPosition(player, playerData)
    end
    
    -- Check for suspicious speed
    if self.antiCheat.speedValidation then
        self:ValidatePlayerSpeed(player, playerData)
    end
end

-- Validate player position for anti-cheat
function SecurityManager:ValidatePlayerPosition(player, playerData)
    local currentPosition = player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart.Position
    
    if currentPosition then
        local lastPosition = playerData.lastPosition
        local distance = (currentPosition - lastPosition).Magnitude
        local timeDiff = tick() - playerData.lastPositionTime
        
        -- Check if movement is suspicious
        if timeDiff > 0 and distance > self.positionValidationRange then
            local speed = distance / timeDiff
            
            if speed > self.speedValidationLimit then
                -- Log suspicious movement
                self:LogSecurityEvent(VIOLATION_TYPES.SPEED_HACKING, player, {
                    speed = speed,
                    distance = distance,
                    timeDiff = timeDiff
                })
                
                playerData.suspiciousActions = playerData.suspiciousActions + 1
            end
        end
        
        -- Update position tracking
        playerData.lastPosition = currentPosition
        playerData.lastPositionTime = tick()
    end
end

-- Validate player speed for anti-cheat
function SecurityManager:ValidatePlayerSpeed(player, playerData)
    local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
    
    if humanoid then
        local speed = humanoid.MoveSpeed
        
        -- Check for unrealistic speed values
        if speed > 100 then
            self:LogSecurityEvent(VIOLATION_TYPES.SPEED_HACKING, player, {
                speed = speed,
                reason = "Unrealistic movement speed"
            })
            
            playerData.suspiciousActions = playerData.suspiciousActions + 1
        end
    end
end

-- Reset rate limiting counters
function SecurityManager:ResetRateLimitCounters()
    local currentTime = tick()
    
    for userId, playerData in pairs(self.playerViolations) do
        if currentTime - playerData.lastRequestTime > self.rateLimitWindow then
            playerData.requestCount = 0
        end
    end
end

-- Log security event
function SecurityManager:LogSecurityEvent(eventType, player, details)
    local logEntry = {
        timestamp = tick(),
        eventType = eventType,
        playerId = player and player.UserId or 0,
        playerName = player and player.Name or "Unknown",
        details = details or {}
    }
    
    table.insert(self.securityLogs, logEntry)
    
    -- Keep only last 1000 log entries
    if #self.securityLogs > 1000 then
        table.remove(self.securityLogs, 1)
    end
    
    -- Log to console for debugging
    if player then
        warn("SecurityManager:", eventType, "by", player.Name, ":", HttpService:JSONEncode(details))
    else
        warn("SecurityManager:", eventType, ":", HttpService:JSONEncode(details))
    end
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

print("SecurityManager: Enhanced security system loaded with wrapper integration")

return SecurityManager
