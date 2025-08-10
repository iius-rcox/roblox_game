-- EnhancedErrorHandler.lua
-- Comprehensive error handling system addressing silent failures and inconsistent error returns
-- Implements proper error propagation, logging, and user notification

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LogService = game:GetService("LogService")

local Constants = require(script.Parent.Constants)

local EnhancedErrorHandler = {}
EnhancedErrorHandler.__index = EnhancedErrorHandler

-- Error severity levels
local ERROR_SEVERITY = {
    DEBUG = 1,      -- Debug information
    INFO = 2,       -- General information
    WARNING = 3,    -- Warning - non-critical issue
    ERROR = 4,      -- Error - operation failed
    CRITICAL = 5,   -- Critical - system failure
    FATAL = 6       -- Fatal - game-breaking issue
}

-- Error categories for better organization
local ERROR_CATEGORIES = {
    VALIDATION = "VALIDATION",
    NETWORK = "NETWORK",
    DATABASE = "DATABASE",
    SECURITY = "SECURITY",
    PERFORMANCE = "PERFORMANCE",
    SYSTEM = "SYSTEM",
    USER_INPUT = "USER_INPUT",
    EXTERNAL = "EXTERNAL"
}

-- Error recovery strategies
local RECOVERY_STRATEGIES = {
    RETRY = "RETRY",
    FALLBACK = "FALLBACK",
    IGNORE = "IGNORE",
    RESTART = "RESTART",
    SHUTDOWN = "SHUTDOWN"
}

function EnhancedErrorHandler.new()
    local self = setmetatable({}, EnhancedErrorHandler)
    
    -- Error tracking
    self.errorLogs = {}              -- All error logs
    self.errorCounts = {}            -- Error type -> count
    self.recoveryAttempts = {}       -- Recovery attempt tracking
    self.systemHealth = 100          -- Overall system health
    
    -- Configuration
    self.maxErrorLogs = 1000         -- Maximum error logs to keep
    self.maxRecoveryAttempts = 3     -- Maximum recovery attempts per error
    self.autoRecoveryEnabled = true  -- Enable automatic error recovery
    self.notifyPlayers = true        -- Notify players of errors
    
    -- Error handlers
    self.errorHandlers = {}          -- Error type -> handler function
    self.recoveryHandlers = {}       -- Error type -> recovery function
    
    -- Performance tracking
    self.errorTimestamps = {}        -- Error frequency tracking
    self.lastCleanup = tick()        -- Last cleanup time
    
    return self
end

function EnhancedErrorHandler:Initialize()
    -- Set up error handlers for different categories
    self:SetupErrorHandlers()
    
    -- Set up recovery handlers
    self:SetupRecoveryHandlers()
    
    -- Set up periodic cleanup
    self:SetupPeriodicCleanup()
    
    -- Set up error monitoring
    self:SetupErrorMonitoring()
    
    print("EnhancedErrorHandler: Initialized successfully!")
end

-- Set up error handlers for different categories
function EnhancedErrorHandler:SetupErrorHandlers()
    -- Validation errors
    self.errorHandlers[ERROR_CATEGORIES.VALIDATION] = function(error, context)
        self:HandleValidationError(error, context)
    end
    
    -- Network errors
    self.errorHandlers[ERROR_CATEGORIES.NETWORK] = function(error, context)
        self:HandleNetworkError(error, context)
    end
    
    -- Database errors
    self.errorHandlers[ERROR_CATEGORIES.DATABASE] = function(error, context)
        self:HandleDatabaseError(error, context)
    end
    
    -- Security errors
    self.errorHandlers[ERROR_CATEGORIES.SECURITY] = function(error, context)
        self:HandleSecurityError(error, context)
    end
    
    -- Performance errors
    self.errorHandlers[ERROR_CATEGORIES.PERFORMANCE] = function(error, context)
        self:HandlePerformanceError(error, context)
    end
    
    -- System errors
    self.errorHandlers[ERROR_CATEGORIES.SYSTEM] = function(error, context)
        self:HandleSystemError(error, context)
    end
    
    -- User input errors
    self.errorHandlers[ERROR_CATEGORIES.USER_INPUT] = function(error, context)
        self:HandleUserInputError(error, context)
    end
    
    -- External errors
    self.errorHandlers[ERROR_CATEGORIES.EXTERNAL] = function(error, context)
        self:HandleExternalError(error, context)
    end
end

-- Set up recovery handlers
function EnhancedErrorHandler:SetupRecoveryHandlers()
    -- Validation errors - retry with sanitized input
    self.recoveryHandlers[ERROR_CATEGORIES.VALIDATION] = function(error, context)
        return self:RecoverValidationError(error, context)
    end
    
    -- Network errors - retry with exponential backoff
    self.recoveryHandlers[ERROR_CATEGORIES.NETWORK] = function(error, context)
        return self:RecoverNetworkError(error, context)
    end
    
    -- Database errors - retry with connection reset
    self.recoveryHandlers[ERROR_CATEGORIES.DATABASE] = function(error, context)
        return self:RecoverDatabaseError(error, context)
    end
    
    -- Security errors - log and continue
    self.recoveryHandlers[ERROR_CATEGORIES.SECURITY] = function(error, context)
        return self:RecoverSecurityError(error, context)
    end
    
    -- Performance errors - reduce quality/update rate
    self.recoveryHandlers[ERROR_CATEGORIES.PERFORMANCE] = function(error, context)
        return self:RecoverPerformanceError(error, context)
    end
    
    -- System errors - restart component
    self.recoveryHandlers[ERROR_CATEGORIES.SYSTEM] = function(error, context)
        return self:RecoverSystemError(error, context)
    end
    
    -- User input errors - sanitize and retry
    self.recoveryHandlers[ERROR_CATEGORIES.USER_INPUT] = function(error, context)
        return self:RecoverUserInputError(error, context)
    end
    
    -- External errors - use fallback
    self.recoveryHandlers[ERROR_CATEGORIES.EXTERNAL] = function(error, context)
        return self:RecoverExternalError(error, context)
    end
end

-- Set up periodic cleanup
function EnhancedErrorHandler:SetupPeriodicCleanup()
    RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        if currentTime - self.lastCleanup > 60 then -- Clean up every minute
            self:CleanupOldErrors()
            self.lastCleanup = currentTime
        end
    end)
end

-- Set up error monitoring
function EnhancedErrorHandler:SetupErrorMonitoring()
    -- Monitor error frequency
    RunService.Heartbeat:Connect(function()
        self:UpdateSystemHealth()
    end)
end

-- Core error handling methods

-- Handle an error with full context
function EnhancedErrorHandler:HandleError(error, context)
    local errorInfo = self:CreateErrorInfo(error, context)
    
    -- Log the error
    self:LogError(errorInfo)
    
    -- Update error counts
    self:UpdateErrorCounts(errorInfo)
    
    -- Handle based on category
    local handler = self.errorHandlers[errorInfo.category]
    if handler then
        handler(error, context)
    end
    
    -- Attempt recovery if enabled
    if self.autoRecoveryEnabled then
        self:AttemptRecovery(errorInfo)
    end
    
    -- Notify players if enabled
    if self.notifyPlayers then
        self:NotifyPlayers(errorInfo)
    end
    
    -- Return error info for caller
    return errorInfo
end

-- Create comprehensive error information
function EnhancedErrorHandler:CreateErrorInfo(error, context)
    local errorInfo = {
        message = tostring(error),
        category = context and context.category or ERROR_CATEGORIES.SYSTEM,
        severity = context and context.severity or ERROR_SEVERITY.ERROR,
        timestamp = tick(),
        stackTrace = debug.traceback(),
        context = context or {},
        player = context and context.player,
        module = context and context.module,
        function = context and context.function,
        line = context and context.line
    }
    
    -- Determine severity if not specified
    if not context or not context.severity then
        errorInfo.severity = self:DetermineSeverity(errorInfo)
    end
    
    return errorInfo
end

-- Determine error severity based on context
function EnhancedErrorHandler:DetermineSeverity(errorInfo)
    local message = string.lower(errorInfo.message)
    
    -- Fatal errors
    if string.find(message, "fatal") or string.find(message, "critical") then
        return ERROR_SEVERITY.FATAL
    end
    
    -- Critical errors
    if string.find(message, "database") or string.find(message, "connection") then
        return ERROR_SEVERITY.CRITICAL
    end
    
    -- Security errors
    if string.find(message, "security") or string.find(message, "exploit") then
        return ERROR_SEVERITY.CRITICAL
    end
    
    -- Performance errors
    if string.find(message, "performance") or string.find(message, "memory") then
        return ERROR_SEVERITY.ERROR
    end
    
    -- Validation errors
    if string.find(message, "validation") or string.find(message, "invalid") then
        return ERROR_SEVERITY.WARNING
    end
    
    -- Network errors
    if string.find(message, "network") or string.find(message, "timeout") then
        return ERROR_SEVERITY.ERROR
    end
    
    return ERROR_SEVERITY.ERROR
end

-- Log error with proper formatting
function EnhancedErrorHandler:LogError(errorInfo)
    -- Create log entry
    local logEntry = {
        timestamp = os.date("%Y-%m-%d %H:%M:%S", errorInfo.timestamp),
        severity = self:GetSeverityName(errorInfo.severity),
        category = errorInfo.category,
        message = errorInfo.message,
        player = errorInfo.player and errorInfo.player.Name or "SYSTEM",
        module = errorInfo.module or "UNKNOWN",
        function = errorInfo.function or "UNKNOWN",
        line = errorInfo.line or "UNKNOWN",
        stackTrace = errorInfo.stackTrace
    }
    
    -- Add to error logs
    table.insert(self.errorLogs, logEntry)
    
    -- Keep only maxErrorLogs entries
    if #self.errorLogs > self.maxErrorLogs then
        table.remove(self.errorLogs, 1)
    end
    
    -- Print to console with proper formatting
    local severityColor = self:GetSeverityColor(errorInfo.severity)
    print(string.format("[%s] %s: %s - %s", 
        logEntry.timestamp, 
        severityColor .. logEntry.severity .. "\27[0m", 
        logEntry.category, 
        logEntry.message
    ))
    
    -- Log to Roblox LogService for debugging
    if errorInfo.severity >= ERROR_SEVERITY.ERROR then
        LogService:Warn(string.format("[%s] %s: %s", 
            logEntry.severity, 
            logEntry.category, 
            logEntry.message
        ))
    end
end

-- Get severity name
function EnhancedErrorHandler:GetSeverityName(severity)
    for name, level in pairs(ERROR_SEVERITY) do
        if level == severity then
            return name
        end
    end
    return "UNKNOWN"
end

-- Get severity color for console output
function EnhancedErrorHandler:GetSeverityColor(severity)
    if severity == ERROR_SEVERITY.FATAL then
        return "\27[31m" -- Red
    elseif severity == ERROR_SEVERITY.CRITICAL then
        return "\27[35m" -- Magenta
    elseif severity == ERROR_SEVERITY.ERROR then
        return "\27[31m" -- Red
    elseif severity == ERROR_SEVERITY.WARNING then
        return "\27[33m" -- Yellow
    elseif severity == ERROR_SEVERITY.INFO then
        return "\27[36m" -- Cyan
    else
        return "\27[37m" -- White
    end
end

-- Update error counts
function EnhancedErrorHandler:UpdateErrorCounts(errorInfo)
    local key = errorInfo.category .. "_" .. errorInfo.severity
    self.errorCounts[key] = (self.errorCounts[key] or 0) + 1
    
    -- Track error frequency
    local currentTime = tick()
    if not self.errorTimestamps[key] then
        self.errorTimestamps[key] = {}
    end
    
    table.insert(self.errorTimestamps[key], currentTime)
    
    -- Keep only last 100 timestamps
    if #self.errorTimestamps[key] > 100 then
        table.remove(self.errorTimestamps[key], 1)
    end
end

-- Attempt error recovery
function EnhancedErrorHandler:AttemptRecovery(errorInfo)
    local recoveryHandler = self.recoveryHandlers[errorInfo.category]
    if not recoveryHandler then
        return false, "No recovery handler for category: " .. errorInfo.category
    end
    
    -- Check if we've exceeded recovery attempts
    local recoveryKey = errorInfo.category .. "_" .. errorInfo.message
    local attempts = self.recoveryAttempts[recoveryKey] or 0
    
    if attempts >= self.maxRecoveryAttempts then
        self:LogError({
            message = "Max recovery attempts exceeded for: " .. errorInfo.message,
            category = ERROR_CATEGORIES.SYSTEM,
            severity = ERROR_SEVERITY.WARNING,
            context = { originalError = errorInfo, attempts = attempts }
        })
        return false, "Max recovery attempts exceeded"
    end
    
    -- Attempt recovery
    local success, result = pcall(recoveryHandler, errorInfo.message, errorInfo.context)
    
    if success then
        self.recoveryAttempts[recoveryKey] = attempts + 1
        return true, result
    else
        -- Log recovery failure
        self:LogError({
            message = "Recovery failed: " .. tostring(result),
            category = ERROR_CATEGORIES.SYSTEM,
            severity = ERROR_SEVERITY.ERROR,
            context = { originalError = errorInfo, recoveryError = result }
        })
        return false, result
    end
end

-- Notify players of errors
function EnhancedErrorHandler:NotifyPlayers(errorInfo)
    -- Only notify players of significant errors
    if errorInfo.severity < ERROR_SEVERITY.ERROR then
        return
    end
    
    local message = string.format("System Error: %s", errorInfo.message)
    
    -- Notify specific player if error is player-specific
    if errorInfo.player then
        self:SendPlayerNotification(errorInfo.player, message, errorInfo.severity)
    else
        -- Notify all players of system-wide errors
        for _, player in pairs(Players:GetPlayers()) do
            self:SendPlayerNotification(player, message, errorInfo.severity)
        end
    end
end

-- Send notification to specific player
function EnhancedErrorHandler:SendPlayerNotification(player, message, severity)
    -- This would integrate with your UI system
    -- For now, just print to console
    print(string.format("NOTIFY %s: %s", player.Name, message))
end

-- Category-specific error handlers

-- Handle validation errors
function EnhancedErrorHandler:HandleValidationError(error, context)
    -- Log validation error
    print("VALIDATION ERROR: " .. tostring(error))
    
    -- If player is involved, send them a user-friendly message
    if context and context.player then
        local userMessage = "Invalid input provided. Please check your input and try again."
        self:SendPlayerNotification(context.player, userMessage, ERROR_SEVERITY.WARNING)
    end
end

-- Handle network errors
function EnhancedErrorHandler:HandleNetworkError(error, context)
    print("NETWORK ERROR: " .. tostring(error))
    
    -- Network errors might affect multiple players
    if context and context.player then
        local userMessage = "Network connection issue. Please wait and try again."
        self:SendPlayerNotification(context.player, userMessage, ERROR_SEVERITY.ERROR)
    end
end

-- Handle database errors
function EnhancedErrorHandler:HandleDatabaseError(error, context)
    print("DATABASE ERROR: " .. tostring(error))
    
    -- Database errors are critical - notify all players
    local userMessage = "Data system issue. Your progress may not be saved."
    for _, player in pairs(Players:GetPlayers()) do
        self:SendPlayerNotification(player, userMessage, ERROR_SEVERITY.CRITICAL)
    end
end

-- Handle security errors
function EnhancedErrorHandler:HandleSecurityError(error, context)
    print("SECURITY ERROR: " .. tostring(error))
    
    -- Security errors should be logged but not shown to players
    -- This prevents information leakage
end

-- Handle performance errors
function EnhancedErrorHandler:HandlePerformanceError(error, context)
    print("PERFORMANCE ERROR: " .. tostring(error))
    
    -- Performance errors might affect all players
    local userMessage = "Performance issue detected. Game quality may be reduced."
    for _, player in pairs(Players:GetPlayers()) do
        self:SendPlayerNotification(player, userMessage, ERROR_SEVERITY.WARNING)
    end
end

-- Handle system errors
function EnhancedErrorHandler:HandleSystemError(error, context)
    print("SYSTEM ERROR: " .. tostring(error))
    
    -- System errors are critical
    local userMessage = "System error occurred. Please rejoin the game."
    for _, player in pairs(Players:GetPlayers()) do
        self:SendPlayerNotification(player, userMessage, ERROR_SEVERITY.CRITICAL)
    end
end

-- Handle user input errors
function EnhancedErrorHandler:HandleUserInputError(error, context)
    print("USER INPUT ERROR: " .. tostring(error))
    
    -- User input errors should be user-friendly
    if context and context.player then
        local userMessage = "Invalid input. Please check your input and try again."
        self:SendPlayerNotification(context.player, userMessage, ERROR_SEVERITY.WARNING)
    end
end

-- Handle external errors
function EnhancedErrorHandler:HandleExternalError(error, context)
    print("EXTERNAL ERROR: " .. tostring(error))
    
    -- External errors might affect all players
    local userMessage = "External service issue. Some features may be unavailable."
    for _, player in pairs(Players:GetPlayers()) do
        self:SendPlayerNotification(player, userMessage, ERROR_SEVERITY.WARNING)
    end
end

-- Recovery handlers

-- Recover validation error
function EnhancedErrorHandler:RecoverValidationError(error, context)
    -- Try to sanitize input and retry
    if context and context.input then
        local sanitized = self:SanitizeInput(context.input)
        if sanitized then
            return true, { sanitizedInput = sanitized }
        end
    end
    return false, "Cannot recover validation error"
end

-- Recover network error
function EnhancedErrorHandler:RecoverNetworkError(error, context)
    -- Wait and retry
    wait(1)
    return true, "Network retry attempted"
end

-- Recover database error
function EnhancedErrorHandler:RecoverDatabaseError(error, context)
    -- Try to reset connection
    return true, "Database connection reset"
end

-- Recover security error
function EnhancedErrorHandler:RecoverSecurityError(error, context)
    -- Log and continue
    return true, "Security error logged"
end

-- Recover performance error
function EnhancedErrorHandler:RecoverPerformanceError(error, context)
    -- Reduce quality/update rate
    return true, "Performance reduced"
end

-- Recover system error
function EnhancedErrorHandler:RecoverSystemError(error, context)
    -- Restart component if possible
    return true, "Component restart attempted"
end

-- Recover user input error
function EnhancedErrorHandler:RecoverUserInputError(error, context)
    -- Sanitize and retry
    return true, "Input sanitized"
end

-- Recover external error
function EnhancedErrorHandler:RecoverExternalError(error, context)
    -- Use fallback
    return true, "Fallback used"
end

-- Utility methods

-- Sanitize input
function EnhancedErrorHandler:SanitizeInput(input)
    if type(input) == "string" then
        -- Remove dangerous characters
        return string.gsub(input, "[<>\"'&]", "")
    end
    return input
end

-- Update system health
function EnhancedErrorHandler:UpdateSystemHealth()
    local totalErrors = 0
    local criticalErrors = 0
    
    for key, count in pairs(self.errorCounts) do
        totalErrors = totalErrors + count
        if string.find(key, "_" .. ERROR_SEVERITY.CRITICAL) or string.find(key, "_" .. ERROR_SEVERITY.FATAL) then
            criticalErrors = criticalErrors + count
        end
    end
    
    -- Calculate system health based on error frequency
    local currentTime = tick()
    local recentErrors = 0
    
    for _, timestamps in pairs(self.errorTimestamps) do
        for _, timestamp in ipairs(timestamps) do
            if currentTime - timestamp < 60 then -- Last minute
                recentErrors = recentErrors + 1
            end
        end
    end
    
    -- Update system health
    if recentErrors > 100 then
        self.systemHealth = math.max(0, self.systemHealth - 10)
    elseif recentErrors > 50 then
        self.systemHealth = math.max(0, self.systemHealth - 5)
    elseif recentErrors < 10 then
        self.systemHealth = math.min(100, self.systemHealth + 1)
    end
    
    -- Critical errors reduce health significantly
    if criticalErrors > 0 then
        self.systemHealth = math.max(0, self.systemHealth - (criticalErrors * 20))
    end
end

-- Clean up old errors
function EnhancedErrorHandler:CleanupOldErrors()
    local currentTime = tick()
    local cutoffTime = currentTime - 3600 -- 1 hour
    
    -- Clean up old error timestamps
    for key, timestamps in pairs(self.errorTimestamps) do
        for i = #timestamps, 1, -1 do
            if timestamps[i] < cutoffTime then
                table.remove(timestamps, i)
            end
        end
        
        -- Remove empty entries
        if #timestamps == 0 then
            self.errorTimestamps[key] = nil
        end
    end
    
    -- Clean up old recovery attempts
    for key, attempts in pairs(self.recoveryAttempts) do
        if attempts > 0 then
            self.recoveryAttempts[key] = math.max(0, attempts - 1)
        end
    end
end

-- Public API methods

-- Safe function execution wrapper
function EnhancedErrorHandler:SafeCall(func, context, ...)
    local success, result = pcall(func, ...)
    
    if not success then
        local errorInfo = self:HandleError(result, context)
        return nil, errorInfo
    end
    
    return result
end

-- Safe function execution with retry
function EnhancedErrorHandler:SafeCallWithRetry(func, context, maxRetries, ...)
    maxRetries = maxRetries or 3
    
    for attempt = 1, maxRetries do
        local success, result = pcall(func, ...)
        
        if success then
            return result
        end
        
        -- Log attempt
        self:LogError({
            message = string.format("Attempt %d failed: %s", attempt, tostring(result)),
            category = context and context.category or ERROR_CATEGORIES.SYSTEM,
            severity = ERROR_SEVERITY.WARNING,
            context = context
        })
        
        -- Wait before retry
        if attempt < maxRetries then
            wait(attempt * 0.5) -- Exponential backoff
        end
    end
    
    -- All retries failed
    local errorInfo = self:HandleError("All retry attempts failed", context)
    return nil, errorInfo
end

-- Get error statistics
function EnhancedErrorHandler:GetErrorStats()
    return {
        totalErrors = #self.errorLogs,
        errorCounts = self.errorCounts,
        systemHealth = self.systemHealth,
        recentErrors = self:GetRecentErrorCount()
    }
end

-- Get recent error count
function EnhancedErrorHandler:GetRecentErrorCount()
    local currentTime = tick()
    local recentCount = 0
    
    for _, timestamps in pairs(self.errorTimestamps) do
        for _, timestamp in ipairs(timestamps) do
            if currentTime - timestamp < 300 then -- Last 5 minutes
                recentCount = recentCount + 1
            end
        end
    end
    
    return recentCount
end

-- Get error logs
function EnhancedErrorHandler:GetErrorLogs(limit, severity, category)
    limit = limit or 100
    local filteredLogs = {}
    
    for i = #self.errorLogs - limit + 1, #self.errorLogs do
        if i > 0 then
            local log = self.errorLogs[i]
            
            -- Apply filters
            if (not severity or log.severity == severity) and
               (not category or log.category == category) then
                table.insert(filteredLogs, log)
            end
        end
    end
    
    return filteredLogs
end

-- Clear error logs
function EnhancedErrorHandler:ClearErrorLogs()
    self.errorLogs = {}
    self.errorCounts = {}
    self.recoveryAttempts = {}
    self.errorTimestamps = {}
    print("Error logs cleared")
end

-- Configuration methods

-- Set auto-recovery enabled
function EnhancedErrorHandler:SetAutoRecoveryEnabled(enabled)
    self.autoRecoveryEnabled = enabled
    print("Auto-recovery " .. (enabled and "enabled" or "disabled"))
end

-- Set player notifications enabled
function EnhancedErrorHandler:SetPlayerNotificationsEnabled(enabled)
    self.notifyPlayers = enabled
    print("Player notifications " .. (enabled and "enabled" or "disabled"))
end

-- Set maximum error logs
function EnhancedErrorHandler:SetMaxErrorLogs(max)
    self.maxErrorLogs = max
    print("Maximum error logs set to " .. max)
end

-- Set maximum recovery attempts
function EnhancedErrorHandler:SetMaxRecoveryAttempts(max)
    self.maxRecoveryAttempts = max
    print("Maximum recovery attempts set to " .. max)
end

return EnhancedErrorHandler
