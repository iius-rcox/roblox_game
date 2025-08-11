-- StandardizedErrorHandler.lua
-- Provides consistent error handling across all modules
-- Implements standardized error types, logging, and recovery strategies

local HttpService = game:GetService("HttpService")
local Constants = require(script.Parent.Constants)

local StandardizedErrorHandler = {}
StandardizedErrorHandler.__index = StandardizedErrorHandler

-- Error severity levels
local ERROR_SEVERITY = {
    LOW = { level = 1, color = "BLUE", action = "LOG_ONLY" },
    MEDIUM = { level = 2, color = "YELLOW", action = "LOG_AND_WARN" },
    HIGH = { level = 3, color = "ORANGE", action = "LOG_WARN_AND_RECOVER" },
    CRITICAL = { level = 4, color = "RED", action = "LOG_WARN_RECOVER_AND_ALERT" },
    FATAL = { level = 5, color = "RED", action = "LOG_WARN_RECOVER_ALERT_AND_RESTART" }
}

-- Error categories
local ERROR_CATEGORIES = {
    SECURITY = "SECURITY",
    PERFORMANCE = "PERFORMANCE",
    MEMORY = "MEMORY",
    NETWORK = "NETWORK",
    DATA = "DATA",
    SYSTEM = "SYSTEM",
    USER_INPUT = "USER_INPUT",
    EXTERNAL_SERVICE = "EXTERNAL_SERVICE"
}

-- Error recovery strategies
local RECOVERY_STRATEGIES = {
    RETRY = "RETRY",
    FALLBACK = "FALLBACK",
    DEGRADE = "DEGRADE",
    RESTART = "RESTART",
    IGNORE = "IGNORE"
}

function StandardizedErrorHandler.new()
    local self = setmetatable({}, StandardizedErrorHandler)
    
    self.errorLog = {}
    self.errorCounts = {}
    self.recoveryAttempts = {}
    self.errorHandlers = {}
    self.recoveryStrategies = {}
    
    -- Initialize error handlers for each category
    self:InitializeErrorHandlers()
    
    -- Initialize recovery strategies
    self:InitializeRecoveryStrategies()
    
    return self
end

function StandardizedErrorHandler:Initialize()
    print("StandardizedErrorHandler: Initialized successfully!")
end

-- Initialize error handlers for each category
function StandardizedErrorHandler:InitializeErrorHandlers()
    self.errorHandlers = {
        [ERROR_CATEGORIES.SECURITY] = function(error, context)
            return self:HandleSecurityError(error, context)
        end,
        
        [ERROR_CATEGORIES.PERFORMANCE] = function(error, context)
            return self:HandlePerformanceError(error, context)
        end,
        
        [ERROR_CATEGORIES.MEMORY] = function(error, context)
            return self:HandleMemoryError(error, context)
        end,
        
        [ERROR_CATEGORIES.NETWORK] = function(error, context)
            return self:HandleNetworkError(error, context)
        end,
        
        [ERROR_CATEGORIES.DATA] = function(error, context)
            return self:HandleDataError(error, context)
        end,
        
        [ERROR_CATEGORIES.SYSTEM] = function(error, context)
            return self:HandleSystemError(error, context)
        end,
        
        [ERROR_CATEGORIES.USER_INPUT] = function(error, context)
            return self:HandleUserInputError(error, context)
        end,
        
        [ERROR_CATEGORIES.EXTERNAL_SERVICE] = function(error, context)
            return self:HandleExternalServiceError(error, context)
        end
    }
end

-- Initialize recovery strategies
function StandardizedErrorHandler:InitializeRecoveryStrategies()
    self.recoveryStrategies = {
        [RECOVERY_STRATEGIES.RETRY] = function(error, context)
            return self:AttemptRetry(error, context)
        end,
        
        [RECOVERY_STRATEGIES.FALLBACK] = function(error, context)
            return self:AttemptFallback(error, context)
        end,
        
        [RECOVERY_STRATEGIES.DEGRADE] = function(error, context)
            return self:AttemptDegradation(error, context)
        end,
        
        [RECOVERY_STRATEGIES.RESTART] = function(error, context)
            return self:AttemptRestart(error, context)
        end,
        
        [RECOVERY_STRATEGIES.IGNORE] = function(error, context)
            return self:IgnoreError(error, context)
        end
    }
end

-- Main error handling method
function StandardizedErrorHandler:HandleError(error, context)
    context = context or {}
    
    -- Create standardized error object
    local errorObj = self:CreateErrorObject(error, context)
    
    -- Log the error
    self:LogError(errorObj)
    
    -- Handle based on category
    local handler = self.errorHandlers[errorObj.category]
    if handler then
        local success, result = pcall(handler, errorObj, context)
        if not success then
            warn("Error handler failed:", result)
        end
    end
    
    -- Attempt recovery
    local recoveryResult = self:AttemptRecovery(errorObj, context)
    
    -- Update error counts
    self:UpdateErrorCounts(errorObj)
    
    -- Return error object and recovery result
    return errorObj, recoveryResult
end

-- Create standardized error object
function StandardizedErrorHandler:CreateErrorObject(error, context)
    local errorObj = {
        id = HttpService:GenerateGUID(),
        timestamp = time(),
        message = tostring(error),
        category = context.category or ERROR_CATEGORIES.SYSTEM,
        severity = context.severity or ERROR_SEVERITY.MEDIUM,
        module = context.module or "UNKNOWN",
        functionName = context.functionName or "UNKNOWN",
        stackTrace = debug.traceback(),
        context = context.additionalContext or {},
        userId = context.userId,
        playerName = context.playerName,
        recoverable = context.recoverable ~= false,
        maxRetries = context.maxRetries or 3
    }
    
    return errorObj
end

-- Log error
function StandardizedErrorHandler:LogError(errorObj)
    -- Add to error log
    table.insert(self.errorLog, errorObj)
    
    -- Keep only last 1000 errors
    if #self.errorLog > 1000 then
        table.remove(self.errorLog, 1)
    end
    
    -- Format error message
    local severityColor = errorObj.severity.color
    local logMessage = string.format(
        "[%s] %s: %s in %s.%s",
        severityColor,
        errorObj.category,
        errorObj.message,
        errorObj.module,
        errorObj.functionName
    )
    
    -- Log based on severity
    if errorObj.severity.level >= ERROR_SEVERITY.HIGH.level then
        warn(logMessage)
    else
        print(logMessage)
    end
    
    -- Log additional context if available
    if next(errorObj.context) then
        print("  Context:", HttpService:JSONEncode(errorObj.context))
    end
end

-- Handle security errors
function StandardizedErrorHandler:HandleSecurityError(error, context)
    -- Security errors are always critical
    error.severity = ERROR_SEVERITY.CRITICAL
    
    -- Log security violation
    warn("SECURITY VIOLATION:", error.message)
    
    -- Trigger security alert
    self:TriggerSecurityAlert(error)
    
    return false, "Security violation detected"
end

-- Handle performance errors
function StandardizedErrorHandler:HandlePerformanceError(error, context)
    -- Performance errors are usually medium severity
    if not error.severity then
        error.severity = ERROR_SEVERITY.MEDIUM
    end
    
    -- Trigger performance optimization
    self:TriggerPerformanceOptimization(error)
    
    return true, "Performance optimization triggered"
end

-- Handle memory errors
function StandardizedErrorHandler:HandleMemoryError(error, context)
    -- Memory errors are usually high severity
    if not error.severity then
        error.severity = ERROR_SEVERITY.HIGH
    end
    
    -- Trigger memory cleanup
    self:TriggerMemoryCleanup(error)
    
    return true, "Memory cleanup triggered"
end

-- Handle network errors
function StandardizedErrorHandler:HandleNetworkError(error, context)
    -- Network errors are usually medium severity
    if not error.severity then
        error.severity = ERROR_SEVERITY.MEDIUM
    end
    
    -- Trigger network recovery
    self:TriggerNetworkRecovery(error)
    
    return true, "Network recovery triggered"
end

-- Handle data errors
function StandardizedErrorHandler:HandleDataError(error, context)
    -- Data errors are usually high severity
    if not error.severity then
        error.severity = ERROR_SEVERITY.HIGH
    end
    
    -- Trigger data recovery
    self:TriggerDataRecovery(error)
    
    return true, "Data recovery triggered"
end

-- Handle system errors
function StandardizedErrorHandler:HandleSystemError(error, context)
    -- System errors are usually critical
    if not error.severity then
        error.severity = ERROR_SEVERITY.CRITICAL
    end
    
    -- Trigger system recovery
    self:TriggerSystemRecovery(error)
    
    return false, "System recovery triggered"
end

-- Handle user input errors
function StandardizedErrorHandler:HandleUserInputError(error, context)
    -- User input errors are usually low severity
    if not error.severity then
        error.severity = ERROR_SEVERITY.LOW
    end
    
    -- Log user input error
    print("User input error:", error.message)
    
    return true, "User input error logged"
end

-- Handle external service errors
function StandardizedErrorHandler:HandleExternalServiceError(error, context)
    -- External service errors are usually medium severity
    if not error.severity then
        error.severity = ERROR_SEVERITY.MEDIUM
    end
    
    -- Trigger external service recovery
    self:TriggerExternalServiceRecovery(error)
    
    return true, "External service recovery triggered"
end

-- Attempt recovery
function StandardizedErrorHandler:AttemptRecovery(error, context)
    if not error.recoverable then
        return false, "Error not recoverable"
    end
    
    local recoveryStrategy = context.recoveryStrategy or RECOVERY_STRATEGIES.RETRY
    local strategy = self.recoveryStrategies[recoveryStrategy]
    
    if strategy then
        local success, result = pcall(strategy, error, context)
        if success then
            return result
        else
            warn("Recovery strategy failed:", result)
            return false, "Recovery strategy failed"
        end
    end
    
    return false, "No recovery strategy available"
end

-- Attempt retry
function StandardizedErrorHandler:AttemptRetry(error, context)
    local retryCount = self.recoveryAttempts[error.id] or 0
    local maxRetries = error.maxRetries or 3
    
    if retryCount >= maxRetries then
        return false, "Max retries exceeded"
    end
    
    self.recoveryAttempts[error.id] = retryCount + 1
    
    -- Wait before retry
    task.wait(2 ^ retryCount) -- Exponential backoff
    
    return true, "Retry attempt " .. (retryCount + 1)
end

-- Attempt fallback
function StandardizedErrorHandler:AttemptFallback(error, context)
    if context.fallbackFunction then
        local success, result = pcall(context.fallbackFunction, context.fallbackArgs)
        if success then
            return true, "Fallback successful"
        else
            return false, "Fallback failed: " .. tostring(result)
        end
    end
    
    return false, "No fallback available"
end

-- Attempt degradation
function StandardizedErrorHandler:AttemptDegradation(error, context)
    -- Reduce functionality to maintain basic operation
    print("Degrading functionality due to error:", error.message)
    
    return true, "Functionality degraded"
end

-- Attempt restart
function StandardizedErrorHandler:AttemptRestart(error, context)
    if context.restartFunction then
        local success, result = pcall(context.restartFunction, context.restartArgs)
        if success then
            return true, "Restart successful"
        else
            return false, "Restart failed: " .. tostring(result)
        end
    end
    
    return false, "No restart function available"
end

-- Ignore error
function StandardizedErrorHandler:IgnoreError(error, context)
    print("Ignoring error:", error.message)
    
    return true, "Error ignored"
end

-- Update error counts
function StandardizedErrorHandler:UpdateErrorCounts(error)
    local category = error.category
    local severity = error.severity.level
    
    if not self.errorCounts[category] then
        self.errorCounts[category] = { total = 0, bySeverity = {} }
    end
    
    self.errorCounts[category].total = self.errorCounts[category].total + 1
    
    if not self.errorCounts[category].bySeverity[severity] then
        self.errorCounts[category].bySeverity[severity] = 0
    end
    
    self.errorCounts[category].bySeverity[severity] = self.errorCounts[category].bySeverity[severity] + 1
end

-- Trigger security alert
function StandardizedErrorHandler:TriggerSecurityAlert(error)
    -- This would integrate with your security system
    print("SECURITY ALERT TRIGGERED:", error.message)
end

-- Trigger performance optimization
function StandardizedErrorHandler:TriggerPerformanceOptimization(error)
    -- This would integrate with your performance system
    print("PERFORMANCE OPTIMIZATION TRIGGERED:", error.message)
end

-- Trigger memory cleanup
function StandardizedErrorHandler:TriggerMemoryCleanup(error)
    -- This would integrate with your memory manager
    print("MEMORY CLEANUP TRIGGERED:", error.message)
end

-- Trigger network recovery
function StandardizedErrorHandler:TriggerNetworkRecovery(error)
    -- This would integrate with your network manager
    print("NETWORK RECOVERY TRIGGERED:", error.message)
end

-- Trigger data recovery
function StandardizedErrorHandler:TriggerDataRecovery(error)
    -- This would integrate with your data system
    print("DATA RECOVERY TRIGGERED:", error.message)
end

-- Trigger system recovery
function StandardizedErrorHandler:TriggerSystemRecovery(error)
    -- This would integrate with your system manager
    print("SYSTEM RECOVERY TRIGGERED:", error.message)
end

-- Trigger external service recovery
function StandardizedErrorHandler:TriggerExternalServiceRecovery(error)
    -- This would integrate with your external service manager
    print("EXTERNAL SERVICE RECOVERY TRIGGERED:", error.message)
end

-- Get error statistics
function StandardizedErrorHandler:GetErrorStatistics()
    return {
        totalErrors = #self.errorLog,
        errorCounts = self.errorCounts,
        recentErrors = self:GetRecentErrors(10)
    }
end

-- Get recent errors
function StandardizedErrorHandler:GetRecentErrors(count)
    count = count or 10
    local recent = {}
    
    for i = math.max(1, #self.errorLog - count + 1), #self.errorLog do
        table.insert(recent, self.errorLog[i])
    end
    
    return recent
end

-- Clear error log
function StandardizedErrorHandler:ClearErrorLog()
    self.errorLog = {}
    self.errorCounts = {}
    self.recoveryAttempts = {}
    print("Error log cleared")
end

-- Safe function wrapper
function StandardizedErrorHandler:SafeCall(func, context, ...)
    context = context or {}
    
    local success, result = pcall(func, ...)
    if not success then
        return self:HandleError(result, context)
    end
    
    return true, result
end

return StandardizedErrorHandler
