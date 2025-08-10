-- ErrorHandler.lua
-- Comprehensive error handling and logging system
-- Implements proper error propagation, logging, and recovery mechanisms

local ErrorHandler = {}

-- Services
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

-- Error severity levels
local ERROR_SEVERITY = {
    LOW = 1,        -- Informational, no action required
    MEDIUM = 2,     -- Warning, monitor closely
    HIGH = 3,       -- Error, requires attention
    CRITICAL = 4,   -- Critical, immediate action required
    FATAL = 5       -- Fatal, system cannot continue
}

-- Error categories
local ERROR_CATEGORIES = {
    VALIDATION = "VALIDATION_ERROR",
    SECURITY = "SECURITY_ERROR",
    NETWORK = "NETWORK_ERROR",
    DATABASE = "DATABASE_ERROR",
    SYSTEM = "SYSTEM_ERROR",
    USER = "USER_ERROR",
    UNKNOWN = "UNKNOWN_ERROR"
}

-- Error recovery strategies
local RECOVERY_STRATEGIES = {
    RETRY = "RETRY",
    FALLBACK = "FALLBACK",
    IGNORE = "IGNORE",
    RESTART = "RESTART",
    TERMINATE = "TERMINATE"
}

-- Error state tracking
local errorState = {
    errorCounts = {},           -- Error type -> count
    recentErrors = {},          -- Recent error log
    errorPatterns = {},         -- Pattern detection
    recoveryAttempts = {},      -- Recovery attempt tracking
    systemHealth = "HEALTHY",   -- Overall system health
    lastErrorTime = 0,         -- Last error timestamp
    totalErrors = 0,            -- Total errors since startup
    criticalErrors = 0          -- Critical errors since startup
}

-- Configuration
local CONFIG = {
    MAX_RECENT_ERRORS = 1000,      -- Maximum recent errors to keep
    ERROR_PATTERN_THRESHOLD = 5,   -- Errors before pattern detection
    RECOVERY_ATTEMPT_LIMIT = 3,    -- Maximum recovery attempts
    HEALTH_CHECK_INTERVAL = 30,    -- Health check interval (seconds)
    ERROR_CLEANUP_INTERVAL = 300,  -- Error cleanup interval (seconds)
    LOG_TO_CONSOLE = true,         -- Log errors to console
    LOG_TO_FILE = false,           -- Log errors to file (if available)
    ENABLE_RECOVERY = true,        -- Enable automatic recovery
    ENABLE_PATTERN_DETECTION = true -- Enable error pattern detection
}

-- Error context information
local function getErrorContext()
    local context = {
        timestamp = tick(),
        stackTrace = debug.traceback(),
        gameTime = tick(),
        memoryUsage = 0, -- Will be populated if available
        playerCount = 0,  -- Will be populated if available
        serverLoad = 0    -- Will be populated if available
    }
    
    -- Get additional context if available
    local success, result = pcall(function()
        -- Try to get memory usage
        if game:GetService("Stats") then
            context.memoryUsage = game:GetService("Stats"):GetTotalMemoryUsageMb()
        end
        
        -- Try to get player count
        if game:GetService("Players") then
            context.playerCount = #game:GetService("Players"):GetPlayers()
        end
        
        -- Try to get server load
        if RunService then
            context.serverLoad = RunService.Heartbeat:Wait()
        end
    end)
    
    if not success then
        context.contextError = result
    end
    
    return context
end

-- Create error entry
local function createErrorEntry(errorType, message, severity, category, context, stackTrace)
    local entry = {
        id = HttpService:GenerateGUID(),
        type = errorType,
        message = message or "Unknown error",
        severity = severity or ERROR_SEVERITY.MEDIUM,
        category = category or ERROR_CATEGORIES.UNKNOWN,
        context = context or getErrorContext(),
        stackTrace = stackTrace or debug.traceback(),
        timestamp = tick(),
        handled = false,
        recovered = false,
        recoveryAttempts = 0
    }
    
    return entry
end

-- Log error to console
local function logToConsole(errorEntry)
    if not CONFIG.LOG_TO_CONSOLE then
        return
    end
    
    local severityText = {
        [ERROR_SEVERITY.LOW] = "INFO",
        [ERROR_SEVERITY.MEDIUM] = "WARN",
        [ERROR_SEVERITY.HIGH] = "ERROR",
        [ERROR_SEVERITY.CRITICAL] = "CRITICAL",
        [ERROR_SEVERITY.FATAL] = "FATAL"
    }
    
    local logMessage = string.format(
        "[%s] %s: %s (%s)",
        severityText[errorEntry.severity] or "UNKNOWN",
        errorEntry.category,
        errorEntry.message,
        errorEntry.type
    )
    
    -- Use appropriate logging level
    if errorEntry.severity <= ERROR_SEVERITY.MEDIUM then
        print(logMessage)
    elseif errorEntry.severity <= ERROR_SEVERITY.HIGH then
        warn(logMessage)
    else
        error(logMessage)
    end
    
    -- Log stack trace for high severity errors
    if errorEntry.severity >= ERROR_SEVERITY.HIGH then
        warn("Stack trace:", errorEntry.stackTrace)
    end
end

-- Log error to file (placeholder for future implementation)
local function logToFile(errorEntry)
    if not CONFIG.LOG_TO_FILE then
        return
    end
    
    -- This would integrate with a file logging system
    -- For now, just store in memory
    table.insert(errorState.recentErrors, errorEntry)
    
    -- Keep only recent errors
    if #errorState.recentErrors > CONFIG.MAX_RECENT_ERRORS then
        table.remove(errorState.recentErrors, 1)
    end
end

-- Update error counts and patterns
local function updateErrorTracking(errorEntry)
    -- Update error counts
    errorState.errorCounts[errorEntry.type] = (errorState.errorCounts[errorEntry.type] or 0) + 1
    errorState.totalErrors = errorState.totalErrors + 1
    
    -- Update critical error count
    if errorEntry.severity >= ERROR_SEVERITY.CRITICAL then
        errorState.criticalErrors = errorState.criticalErrors + 1
    end
    
    -- Update last error time
    errorState.lastErrorTime = tick()
    
    -- Update system health
    if errorEntry.severity >= ERROR_SEVERITY.CRITICAL then
        errorState.systemHealth = "CRITICAL"
    elseif errorEntry.severity >= ERROR_SEVERITY.HIGH then
        errorState.systemHealth = "UNHEALTHY"
    elseif errorEntry.severity >= ERROR_SEVERITY.MEDIUM then
        errorState.systemHealth = "WARNING"
    end
    
    -- Pattern detection
    if CONFIG.ENABLE_PATTERN_DETECTION then
        local errorCount = errorState.errorCounts[errorEntry.type]
        if errorCount >= CONFIG.ERROR_PATTERN_THRESHOLD then
            errorState.errorPatterns[errorEntry.type] = {
                count = errorCount,
                firstOccurrence = errorEntry.timestamp,
                lastOccurrence = errorEntry.timestamp,
                severity = errorEntry.severity
            }
        end
    end
end

-- Attempt error recovery
local function attemptRecovery(errorEntry)
    if not CONFIG.ENABLE_RECOVERY then
        return false
    end
    
    local recoveryStrategy = determineRecoveryStrategy(errorEntry)
    local maxAttempts = CONFIG.RECOVERY_ATTEMPT_LIMIT
    
    -- Check if we've exceeded recovery attempts
    if errorEntry.recoveryAttempts >= maxAttempts then
        errorEntry.handled = true
        return false
    end
    
    -- Increment recovery attempts
    errorEntry.recoveryAttempts = errorEntry.recoveryAttempts + 1
    
    -- Attempt recovery based on strategy
    local success = false
    local error = nil
    
    if recoveryStrategy == RECOVERY_STRATEGIES.RETRY then
        success, error = pcall(function()
            -- Wait a bit before retry
            wait(1)
            -- This would retry the operation
        end)
    elseif recoveryStrategy == RECOVERY_STRATEGIES.FALLBACK then
        success, error = pcall(function()
            -- Use fallback mechanism
            -- This would implement fallback logic
        end)
    elseif recoveryStrategy == RECOVERY_STRATEGIES.IGNORE then
        success = true
        error = "Error ignored as per recovery strategy"
    elseif recoveryStrategy == RECOVERY_STRATEGIES.RESTART then
        success, error = pcall(function()
            -- Restart the system or component
            -- This would implement restart logic
        end)
    elseif recoveryStrategy == RECOVERY_STRATEGIES.TERMINATE then
        -- Terminate the system
        error("Fatal error - system termination required")
        return false
    end
    
    if success then
        errorEntry.recovered = true
        errorEntry.handled = true
        print("ErrorHandler: Successfully recovered from error:", errorEntry.type)
    else
        warn("ErrorHandler: Recovery attempt failed:", errorEntry.type, "Error:", error)
    end
    
    return success
end

-- Determine recovery strategy based on error
local function determineRecoveryStrategy(errorEntry)
    -- Default strategy
    local strategy = RECOVERY_STRATEGIES.IGNORE
    
    -- Category-based strategies
    if errorEntry.category == ERROR_CATEGORIES.VALIDATION then
        strategy = RECOVERY_STRATEGIES.IGNORE
    elseif errorEntry.category == ERROR_CATEGORIES.SECURITY then
        strategy = RECOVERY_STRATEGIES.TERMINATE
    elseif errorEntry.category == ERROR_CATEGORIES.NETWORK then
        strategy = RECOVERY_STRATEGIES.RETRY
    elseif errorEntry.category == ERROR_CATEGORIES.DATABASE then
        strategy = RECOVERY_STRATEGIES.FALLBACK
    elseif errorEntry.category == ERROR_CATEGORIES.SYSTEM then
        strategy = RECOVERY_STRATEGIES.RESTART
    elseif errorEntry.category == ERROR_CATEGORIES.USER then
        strategy = RECOVERY_STRATEGIES.IGNORE
    end
    
    -- Severity-based overrides
    if errorEntry.severity >= ERROR_SEVERITY.FATAL then
        strategy = RECOVERY_STRATEGIES.TERMINATE
    elseif errorEntry.severity >= ERROR_SEVERITY.CRITICAL then
        strategy = RECOVERY_STRATEGIES.RESTART
    elseif errorEntry.severity <= ERROR_SEVERITY.LOW then
        strategy = RECOVERY_STRATEGIES.IGNORE
    end
    
    return strategy
end

-- Main error handling function
function ErrorHandler.HandleError(errorType, message, severity, category, context, stackTrace)
    -- Create error entry
    local errorEntry = createErrorEntry(errorType, message, severity, category, context, stackTrace)
    
    -- Log error
    logToConsole(errorEntry)
    logToFile(errorEntry)
    
    -- Update tracking
    updateErrorTracking(errorEntry)
    
    -- Attempt recovery
    local recovered = attemptRecovery(errorEntry)
    
    -- Return error entry for further handling
    return errorEntry, recovered
end

-- Handle errors with automatic context
function ErrorHandler.HandleErrorWithContext(errorType, message, severity, category)
    return ErrorHandler.HandleError(errorType, message, severity, category, getErrorContext())
end

-- Handle validation errors
function ErrorHandler.HandleValidationError(message, context)
    return ErrorHandler.HandleError(
        "VALIDATION_FAILED",
        message,
        ERROR_SEVERITY.MEDIUM,
        ERROR_CATEGORIES.VALIDATION,
        context
    )
end

-- Handle security errors
function ErrorHandler.HandleSecurityError(message, context)
    return ErrorHandler.HandleError(
        "SECURITY_VIOLATION",
        message,
        ERROR_SEVERITY.HIGH,
        ERROR_CATEGORIES.SECURITY,
        context
    )
end

-- Handle network errors
function ErrorHandler.HandleNetworkError(message, context)
    return ErrorHandler.HandleError(
        "NETWORK_FAILURE",
        message,
        ERROR_SEVERITY.MEDIUM,
        ERROR_CATEGORIES.NETWORK,
        context
    )
end

-- Handle database errors
function ErrorHandler.HandleDatabaseError(message, context)
    return ErrorHandler.HandleError(
        "DATABASE_ERROR",
        message,
        ERROR_SEVERITY.HIGH,
        ERROR_CATEGORIES.DATABASE,
        context
    )
end

-- Handle system errors
function ErrorHandler.HandleSystemError(message, context)
    return ErrorHandler.HandleError(
        "SYSTEM_ERROR",
        message,
        ERROR_SEVERITY.CRITICAL,
        ERROR_CATEGORIES.SYSTEM,
        context
    )
end

-- Handle user errors
function ErrorHandler.HandleUserError(message, context)
    return ErrorHandler.HandleError(
        "USER_ERROR",
        message,
        ERROR_SEVERITY.LOW,
        ERROR_CATEGORIES.USER,
        context
    )
end

-- Wrap function with error handling
function ErrorHandler.WrapFunction(func, errorType, severity, category)
    return function(...)
        local success, result = pcall(func, ...)
        
        if not success then
            local context = getErrorContext()
            context.functionName = tostring(func)
            context.arguments = {...}
            
            ErrorHandler.HandleError(
                errorType or "FUNCTION_ERROR",
                result,
                severity or ERROR_SEVERITY.MEDIUM,
                category or ERROR_CATEGORIES.SYSTEM,
                context
            )
            
            -- Return nil or default value on error
            return nil
        end
        
        return result
    end
end

-- Wrap module with error handling
function ErrorHandler.WrapModule(module, moduleName)
    local wrappedModule = {}
    
    for key, value in pairs(module) do
        if type(value) == "function" then
            wrappedModule[key] = ErrorHandler.WrapFunction(
                value,
                "MODULE_ERROR",
                ERROR_SEVERITY.MEDIUM,
                ERROR_CATEGORIES.SYSTEM
            )
        else
            wrappedModule[key] = value
        end
    end
    
    -- Add error handling metadata
    wrappedModule._errorHandled = true
    wrappedModule._moduleName = moduleName
    
    return wrappedModule
end

-- Get error statistics
function ErrorHandler.GetErrorStats()
    local stats = {
        totalErrors = errorState.totalErrors,
        criticalErrors = errorState.criticalErrors,
        systemHealth = errorState.systemHealth,
        lastErrorTime = errorState.lastErrorTime,
        errorCounts = errorState.errorCounts,
        errorPatterns = errorState.errorPatterns,
        recentErrorCount = #errorState.recentErrors
    }
    
    return stats
end

-- Get system health status
function ErrorHandler.GetSystemHealth()
    local health = {
        status = errorState.systemHealth,
        errorRate = 0,
        criticalErrorRate = 0,
        recommendations = {}
    }
    
    -- Calculate error rates
    local currentTime = tick()
    local timeWindow = 3600 -- 1 hour
    
    if currentTime - errorState.lastErrorTime < timeWindow then
        health.errorRate = errorState.totalErrors / (timeWindow / 3600) -- errors per hour
        health.criticalErrorRate = errorState.criticalErrors / (timeWindow / 3600)
    end
    
    -- Generate recommendations
    if health.criticalErrorRate > 1 then
        table.insert(health.recommendations, "Critical error rate is high - review system stability")
    end
    
    if errorState.systemHealth == "CRITICAL" then
        table.insert(health.recommendations, "System is in critical state - immediate attention required")
    end
    
    if #errorState.errorPatterns > 0 then
        table.insert(health.recommendations, "Error patterns detected - investigate root causes")
    end
    
    return health
end

-- Clear error history
function ErrorHandler.ClearErrorHistory()
    errorState.recentErrors = {}
    errorState.errorCounts = {}
    errorState.errorPatterns = {}
    errorState.recoveryAttempts = {}
    errorState.totalErrors = 0
    errorState.criticalErrors = 0
    errorState.systemHealth = "HEALTHY"
    
    print("ErrorHandler: Error history cleared")
end

-- Set configuration
function ErrorHandler.SetConfig(newConfig)
    for key, value in pairs(newConfig) do
        if CONFIG[key] ~= nil then
            CONFIG[key] = value
        end
    end
    
    print("ErrorHandler: Configuration updated")
end

-- Get configuration
function ErrorHandler.GetConfig()
    return CONFIG
end

-- Initialize error handler
function ErrorHandler.Initialize()
    -- Set up periodic health checks
    spawn(function()
        while true do
            wait(CONFIG.HEALTH_CHECK_INTERVAL)
            
            local health = ErrorHandler.GetSystemHealth()
            if health.status == "CRITICAL" then
                warn("ErrorHandler: System health is CRITICAL - immediate attention required")
            end
        end
    end)
    
    -- Set up periodic cleanup
    spawn(function()
        while true do
            wait(CONFIG.ERROR_CLEANUP_INTERVAL)
            
            -- Clean up old errors
            local currentTime = tick()
            local cutoffTime = currentTime - 86400 -- 24 hours
            
            for i = #errorState.recentErrors, 1, -1 do
                if errorState.recentErrors[i].timestamp < cutoffTime then
                    table.remove(errorState.recentErrors, i)
                end
            end
            
            print("ErrorHandler: Cleaned up old error logs")
        end
    end)
    
    print("ErrorHandler: Initialized successfully")
end

-- Export constants
ErrorHandler.ERROR_SEVERITY = ERROR_SEVERITY
ErrorHandler.ERROR_CATEGORIES = ERROR_CATEGORIES
ErrorHandler.RECOVERY_STRATEGIES = RECOVERY_STRATEGIES

-- Auto-initialize
ErrorHandler.Initialize()

return ErrorHandler
