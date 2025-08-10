-- SecurityManager.lua
-- Advanced security and anti-cheat system for Milestone 3: Competitive & Social Systems
-- Handles anti-cheat, data validation, rate limiting, and security monitoring

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Constants = require(script.Parent.Parent.Utils.Constants)
local NetworkManager = require(script.Parent.Parent.Multiplayer.NetworkManager)

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
    return {
        performance = self:GetPerformanceMetrics(),
        violations = self:GetViolationSummary(),
        systemHealth = self:GetSystemHealth()
    }
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
    
    return health
end

function SecurityManager:Initialize(networkManager)
    self.networkManager = networkManager
    
    -- Set up remote events
    self:SetupRemoteEvents()
    
    -- Connect to player events
    self:ConnectPlayerEvents()
    
    -- Initialize anti-cheat systems
    self:InitializeAntiCheat()
    
    -- Set up periodic security checks
    self:SetupPeriodicChecks()
    
    print("SecurityManager: Initialized successfully!")
end

-- Set up remote events for client-server communication
function SecurityManager:SetupRemoteEvents()
    for eventName, eventId in pairs(RemoteEvents) do
        self.remoteEvents[eventName] = self.networkManager:CreateRemoteEvent(eventId)
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
            self:UnbanPlayer(player)
        else
            return -- Player is still banned
        end
    end
    
    -- Check for suspicious behavior patterns
    if playerData.suspiciousActions > 5 then
        self:FlagSuspiciousPlayer(player)
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

-- Validate client request
function SecurityManager:ValidateClientRequest(player, requestType, data)
    local userId = player.UserId
    local playerData = self.playerViolations[userId]
    
    if not playerData then
        return false, "Player security data not found"
    end
    
    -- Check if player is banned
    if playerData.isBanned then
        return false, "Player is banned"
    end
    
    -- Rate limiting check
    if not self:CheckRateLimit(player, requestType) then
        return false, "Rate limit exceeded"
    end
    
    -- Request validation
    if not self:ValidateRequestData(requestType, data) then
        return false, "Invalid request data"
    end
    
    -- Update request tracking
    playerData.requestCount = playerData.requestCount + 1
    playerData.lastRequestTime = tick()
    
    return true, "Request validated"
end

-- Check rate limiting for a player
function SecurityManager:CheckRateLimit(player, requestType)
    local userId = player.UserId
    local playerData = self.playerViolations[userId]
    
    if not playerData then
        return false
    end
    
    local currentTime = tick()
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
    
    return true
end

-- Validate request data
function SecurityManager:ValidateRequestData(requestType, data)
    local startTime = tick()
    
    -- Basic data validation
    if not data then
        self:LogValidationTime(startTime, "BASIC_VALIDATION")
        return false, "No data provided"
    end
    
    -- Enhanced data validation (Roblox best practices)
    local validationResult, errorMessage = self:ValidateDataStructure(data)
    if not validationResult then
        self:LogValidationTime(startTime, "STRUCTURE_VALIDATION")
        return false, errorMessage
    end
    
    -- Type-specific validation
    if requestType == "POSITION_UPDATE" then
        local result = self:ValidatePositionData(data)
        self:LogValidationTime(startTime, "POSITION_VALIDATION")
        return result
    elseif requestType == "INVENTORY_UPDATE" then
        local result = self:ValidateInventoryData(data)
        self:LogValidationTime(startTime, "INVENTORY_VALIDATION")
        return result
    elseif requestType == "CURRENCY_UPDATE" then
        local result = self:ValidateCurrencyData(data)
        self:LogValidationTime(startTime, "CURRENCY_VALIDATION")
        return result
    end
    
    self:LogValidationTime(startTime, "GENERAL_VALIDATION")
    return true, "Request validated successfully"
end

-- Enhanced data structure validation (Roblox best practices)
function SecurityManager:ValidateDataStructure(data)
    -- Check for NaN/Inf values in numeric fields
    if type(data) == "table" then
        for key, value in pairs(data) do
            -- Validate table indices (Roblox best practice)
            if key == nil or (type(key) == "number" and (isNaN(key) or isInf(key))) then
                return false, "Invalid table indices detected"
            end
            
            -- Validate numeric values
            if type(value) == "number" then
                if isNaN(value) or isInf(value) then
                    return false, "Invalid numeric values (NaN/Inf) detected"
                end
            end
            
            -- Recursively validate nested tables
            if type(value) == "table" then
                local nestedResult, nestedError = self:ValidateDataStructure(value)
                if not nestedResult then
                    return false, "Nested data validation failed: " .. nestedError
                end
            end
        end
    end
    
    -- Validate strings for UTF-8 compliance (Roblox best practice)
    if type(data) == "string" then
        if not utf8.len(data) then
            return false, "Invalid UTF-8 characters detected"
        end
    end
    
    return true, "Data structure validated successfully"
end

-- Validate position data
function SecurityManager:ValidatePositionData(data)
    if not data.position or typeof(data.position) ~= "Vector3" then
        return false
    end
    
    -- Check for reasonable position values
    local position = data.position
    if position.X < -10000 or position.X > 10000 or
       position.Y < -1000 or position.Y > 1000 or
       position.Z < -10000 or position.Z > 10000 then
        return false
    end
    
    return true
end

-- Validate inventory data
function SecurityManager:ValidateInventoryData(data)
    if not data.items or typeof(data.items) ~= "table" then
        return false
    end
    
    -- Check for reasonable item quantities
    for itemId, quantity in pairs(data.items) do
        if type(quantity) ~= "number" or quantity < 0 or quantity > 1000000 then
            return false
        end
    end
    
    return true
end

-- Validate currency data
function SecurityManager:ValidateCurrencyData(data)
    if not data.amount or type(data.amount) ~= "number" then
        return false
    end
    
    -- Check for reasonable currency amounts
    if data.amount < 0 or data.amount > 1000000000 then
        return false
    end
    
    return true
end

-- Verify player position
function SecurityManager:VerifyPlayerPosition(player, newPosition)
    local userId = player.UserId
    local playerData = self.playerViolations[userId]
    
    if not playerData then
        return false
    end
    
    local currentTime = tick()
    local lastPosition = playerData.lastPosition
    local lastPositionTime = playerData.lastPositionTime
    
    -- Calculate distance and time
    local distance = (newPosition - lastPosition).Magnitude
    local timeDelta = currentTime - lastPositionTime
    
    -- Check for teleport exploits
    if distance > self.positionValidationRange and timeDelta < 0.1 then
        self:LogSecurityEvent(VIOLATION_TYPES.TELEPORT_EXPLOIT, player, {
            distance = distance,
            timeDelta = timeDelta,
            fromPosition = lastPosition,
            toPosition = newPosition
        })
        return false
    end
    
    -- Check for speed exploits
    local speed = distance / timeDelta
    if speed > self.speedValidationLimit then
        self:LogSecurityEvent(VIOLATION_TYPES.SPEED_HACKING, player, {
            speed = speed,
            distance = distance,
            timeDelta = timeDelta
        })
        return false
    end
    
    -- Update position tracking
    playerData.lastPosition = newPosition
    playerData.lastPositionTime = currentTime
    
    return true
end

-- Validate player actions
function SecurityManager:ValidatePlayerActions(player, actions)
    local userId = player.UserId
    local playerData = self.playerViolations[userId]
    
    if not playerData then
        return false
    end
    
    -- Check for suspicious action patterns
    for _, action in ipairs(actions) do
        if not self:ValidateAction(action) then
            playerData.suspiciousActions = playerData.suspiciousActions + 1
            return false
        end
    end
    
    return true
end

-- Validate individual action
function SecurityManager:ValidateAction(action)
    -- Basic action validation
    if not action.type or not action.data then
        return false
    end
    
    -- Type-specific validation
    if action.type == "BUILD" then
        return self:ValidateBuildAction(action.data)
    elseif action.type == "UPGRADE" then
        return self:ValidateUpgradeAction(action.data)
    elseif action.type == "TRADE" then
        return self:ValidateTradeAction(action.data)
    end
    
    return true
end

-- Validate build action
function SecurityManager:ValidateBuildAction(data)
    if not data.buildingType or not data.position then
        return false
    end
    
    -- Check for reasonable building positions
    local position = data.position
    if position.Y < -100 or position.Y > 1000 then
        return false
    end
    
    return true
end

-- Validate upgrade action
function SecurityManager:ValidateUpgradeAction(data)
    if not data.upgradeType or not data.cost then
        return false
    end
    
    -- Check for reasonable upgrade costs
    if data.cost < 0 or data.cost > 10000000 then
        return false
    end
    
    return true
end

-- Validate trade action
function SecurityManager:ValidateTradeAction(data)
    if not data.tradeId or not data.items then
        return false
    end
    
    -- Check for reasonable trade items
    for itemId, quantity in pairs(data.items) do
        if quantity < 0 or quantity > 100000 then
            return false
        end
    end
    
    return true
end

-- Check for exploits
function SecurityManager:CheckForExploits(player, data)
    local userId = player.UserId
    local playerData = self.playerViolations[userId]
    
    if not playerData then
        return false
    end
    
    -- Check for common exploit patterns
    if self:DetectInventoryExploit(player, data) then
        self:LogSecurityEvent(VIOLATION_TYPES.INVENTORY_EXPLOIT, player, data)
        return true
    end
    
    if self:DetectCurrencyExploit(player, data) then
        self:LogSecurityEvent(VIOLATION_TYPES.CURRENCY_EXPLOIT, player, data)
        return true
    end
    
    return false
end

-- Detect inventory exploits
function SecurityManager:DetectInventoryExploit(player, data)
    -- Check for unreasonable inventory changes
    if data.inventoryChange and data.inventoryChange > 1000000 then
        return true
    end
    
    return false
end

-- Detect currency exploits
function SecurityManager:DetectCurrencyExploit(player, data)
    -- Check for unreasonable currency changes
    if data.currencyChange and data.currencyChange > 10000000 then
        return true
    end
    
    return false
end

-- Apply penalties for violations
function SecurityManager:ApplyPenalties(player, violationType)
    local userId = player.UserId
    local playerData = self.playerViolations[userId]
    
    if not playerData then
        return
    end
    
    -- Add violation to history
    table.insert(playerData.violations, {
        type = violationType,
        timestamp = tick(),
        description = "Security violation detected"
    })
    
    -- Determine penalty level
    local violationCount = #playerData.violations
    local penaltyLevel = math.min(violationCount, #PENALTY_LEVELS)
    local penalty = PENALTY_LEVELS[penaltyLevel]
    
    -- Apply penalty
    if penalty.action == "WARNING" then
        self:IssueWarning(player, violationType)
    elseif penalty.action == "TEMPORARY_BAN" then
        self:TemporarilyBanPlayer(player, penalty.duration)
    elseif penalty.action == "EXTENDED_BAN" then
        self:TemporarilyBanPlayer(player, penalty.duration)
    elseif penalty.action == "PERMANENT_BAN" then
        self:PermanentlyBanPlayer(player)
    end
    
    -- Log the penalty
    self:LogSecurityEvent("PENALTY_APPLIED", player, {
        violationType = violationType,
        penaltyLevel = penaltyLevel,
        penaltyAction = penalty.action,
        violationCount = violationCount
    })
    
    print("SecurityManager: Applied " .. penalty.action .. " to player " .. player.Name)
end

-- Issue warning to player
function SecurityManager:IssueWarning(player, violationType)
    -- Send warning through network
    if self.networkManager then
        self.networkManager:SendToClient(player, RemoteEvents.SecurityViolation, {
            type = "WARNING",
            message = "Security violation detected: " .. violationType,
            timestamp = tick()
        })
    end
end

-- Temporarily ban player
function SecurityManager:TemporarilyBanPlayer(player, duration)
    local userId = player.UserId
    local playerData = self.playerViolations[userId]
    
    if playerData then
        playerData.isBanned = true
        playerData.banExpiry = tick() + duration
        
        -- Kick player with ban message
        player:Kick("You have been temporarily banned for security violations. Duration: " .. duration .. " seconds")
    end
end

-- Permanently ban player
function SecurityManager:PermanentlyBanPlayer(player)
    local userId = player.UserId
    local playerData = self.playerViolations[userId]
    
    if playerData then
        playerData.isBanned = true
        playerData.banExpiry = -1
        
        -- Kick player with permanent ban message
        player:Kick("You have been permanently banned for repeated security violations.")
    end
end

-- Unban player
function SecurityManager:UnbanPlayer(player)
    local userId = player.UserId
    local playerData = self.playerViolations[userId]
    
    if playerData then
        playerData.isBanned = false
        playerData.banExpiry = 0
        
        print("SecurityManager: Unbanned player " .. player.Name)
    end
end

-- Flag suspicious player
function SecurityManager:FlagSuspiciousPlayer(player)
    local userId = player.UserId
    self.suspiciousPlayers[userId] = {
        player = player,
        flagTime = tick(),
        reason = "Multiple suspicious actions detected"
    }
    
    -- Increase monitoring for this player
    print("SecurityManager: Flagged player " .. player.Name .. " as suspicious")
end

-- Log security event
function SecurityManager:LogSecurityEvent(eventType, player, data)
    local logEntry = {
        eventType = eventType,
        playerName = player.Name,
        playerUserId = player.UserId,
        timestamp = tick(),
        data = data or {}
    }
    
    table.insert(self.securityLogs, logEntry)
    
    -- Keep only last 1000 log entries
    if #self.securityLogs > 1000 then
        table.remove(self.securityLogs, 1)
    end
    
    -- Send to admins if available
    self:NotifyAdmins(eventType, player, data)
    
    print("SecurityManager: Logged security event: " .. eventType .. " for player " .. player.Name)
end

-- Notify admins of security events
function SecurityManager:NotifyAdmins(eventType, player, data)
    -- This would integrate with your admin system
    -- For now, just print to console
    print("SECURITY ALERT: " .. eventType .. " - Player: " .. player.Name .. " - Data: " .. HttpService:JSONEncode(data))
end

-- Get security statistics
function SecurityManager:GetSecurityStats()
    local stats = {
        totalViolations = 0,
        bannedPlayers = 0,
        suspiciousPlayers = 0,
        recentEvents = 0
    }
    
    -- Count violations
    for userId, playerData in pairs(self.playerViolations) do
        stats.totalViolations = stats.totalViolations + #playerData.violations
        if playerData.isBanned then
            stats.bannedPlayers = stats.bannedPlayers + 1
        end
    end
    
    -- Count suspicious players
    stats.suspiciousPlayers = 0
    for userId, _ in pairs(self.suspiciousPlayers) do
        stats.suspiciousPlayers = stats.suspiciousPlayers + 1
    end
    
    -- Count recent events (last hour)
    local oneHourAgo = tick() - 3600
    stats.recentEvents = 0
    for _, logEntry in ipairs(self.securityLogs) do
        if logEntry.timestamp > oneHourAgo then
            stats.recentEvents = stats.recentEvents + 1
        end
    end
    
    return stats
end

-- Clean up old security logs
function SecurityManager:CleanupOldLogs()
    local oneDayAgo = tick() - 86400
    local cleanedCount = 0
    
    for i = #self.securityLogs, 1, -1 do
        if self.securityLogs[i].timestamp < oneDayAgo then
            table.remove(self.securityLogs, i)
            cleanedCount = cleanedCount + 1
        end
    end
    
    if cleanedCount > 0 then
        print("SecurityManager: Cleaned up " .. cleanedCount .. " old security logs")
    end
end

-- Export SecurityManager
return SecurityManager
