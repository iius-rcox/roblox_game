-- NetworkManager.lua
-- Handles all multiplayer networking and RemoteEvents
-- Enhanced with comprehensive security wrapper integration

local NetworkManager = {}
NetworkManager.__index = NetworkManager

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Security and validation
local SecurityWrapper = require(script.Parent.Parent.Utils.SecurityWrapper)
local DataValidator = require(script.Parent.Parent.Utils.DataValidator)

-- Create RemoteEvents folder
local remoteEvents = Instance.new("Folder")
remoteEvents.Name = "RemoteEvents"
remoteEvents.Parent = ReplicatedStorage

-- RemoteEvents for different systems with security configurations
local remotes = {
    -- Player system
    PlayerJoin = Instance.new("RemoteEvent"),
    PlayerLeave = Instance.new("RemoteEvent"),
    PlayerDataUpdate = Instance.new("RemoteEvent"),
    
    -- Tycoon system
    TycoonClaim = Instance.new("RemoteEvent"),
    TycoonDataUpdate = Instance.new("RemoteEvent"),
    TycoonSwitch = Instance.new("RemoteEvent"),
    
    -- Ability system
    AbilityUpdate = Instance.new("RemoteEvent"),
    AbilityTheft = Instance.new("RemoteEvent"),
    
    -- Economy system
    CashUpdate = Instance.new("RemoteEvent"),
    PurchaseUpdate = Instance.new("RemoteEvent"),
    
    -- General
    Notification = Instance.new("RemoteEvent"),
    ErrorMessage = Instance.new("RemoteEvent")
}

-- Security configurations for each remote event
local securityConfigs = {
    PlayerJoin = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.NONE,
        requireValidation = false
    },
    
    PlayerLeave = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = false
    },
    
    PlayerDataUpdate = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = DataValidator.Schemas.USERNAME,
            [2] = { type = "table" }
        }
    },
    
    TycoonClaim = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.TYCOON_CLAIM,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 100 }
        }
    },
    
    TycoonDataUpdate = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.TYCOON_OWNER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 100 },
            [2] = { type = "table" }
        }
    },
    
    TycoonSwitch = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.TYCOON_CLAIM,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 100 }
        }
    },
    
    AbilityUpdate = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.ABILITY_UPDATE,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = DataValidator.Schemas.ABILITY_LEVEL,
            [2] = { type = "string", minLength = 1, maxLength = 50 }
        }
    },
    
    AbilityTheft = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.ABILITY_UPDATE,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = DataValidator.Schemas.USERNAME,
            [2] = { type = "string", minLength = 1, maxLength = 50 }
        }
    },
    
    CashUpdate = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.CASH_UPDATE,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = DataValidator.Schemas.CASH_AMOUNT
        }
    },
    
    PurchaseUpdate = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 100 },
            [2] = DataValidator.Schemas.CASH_AMOUNT
        }
    },
    
    Notification = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 500 }
        }
    },
    
    ErrorMessage = {
        rateLimit = SecurityWrapper.Config.RATE_LIMITS.DEFAULT,
        authorizationLevel = SecurityWrapper.AuthorizationLevels.PLAYER,
        requireValidation = true,
        inputSchema = {
            [1] = { type = "string", minLength = 1, maxLength = 500 }
        }
    }
}

-- Set up RemoteEvents with security
for name, remote in pairs(remotes) do
    remote.Name = name
    remote.Parent = remoteEvents
    
    -- Apply security wrapper
    local config = securityConfigs[name] or securityConfigs.PlayerJoin
    SecurityWrapper.WrapRemoteEvent(remote, config)
end

-- Store references
NetworkManager.Remotes = remotes
NetworkManager.SecurityConfigs = securityConfigs

-- Network event handlers
local eventHandlers = {}

-- Register event handler with security validation
function NetworkManager:RegisterHandler(eventName, handler)
    if remotes[eventName] then
        eventHandlers[eventName] = handler
        
        -- Set up the event handler with additional security
        local config = securityConfigs[eventName]
        if config then
            print("NetworkManager: Registered secure handler for", eventName, "with config:", 
                  "rateLimit:", config.rateLimit.maxRequests, "/", config.rateLimit.windowSeconds, "s",
                  "authLevel:", config.authorizationLevel)
        end
    else
        warn("NetworkManager: Invalid event name:", eventName)
    end
end

-- Fire event to client with security logging
function NetworkManager:FireClient(player, eventName, ...)
    if remotes[eventName] then
        local args = {...}
        
        -- Log outgoing events for security monitoring
        if SecurityWrapper then
            SecurityWrapper.LogSecurityEvent("OUTGOING_EVENT", player, {
                eventName = eventName,
                dataSize = SecurityWrapper.CalculateDataSize(args)
            })
        end
        
        remotes[eventName]:FireClient(player, ...)
    else
        warn("NetworkManager: Invalid event name:", eventName)
    end
end

-- Fire event to all clients with security logging
function NetworkManager:FireAllClients(eventName, ...)
    if remotes[eventName] then
        local args = {...}
        
        -- Log outgoing events for security monitoring
        if SecurityWrapper then
            SecurityWrapper.LogSecurityEvent("OUTGOING_EVENT_ALL", nil, {
                eventName = eventName,
                dataSize = SecurityWrapper.CalculateDataSize(args)
            })
        end
        
        remotes[eventName]:FireAllClients(...)
    else
        warn("NetworkManager: Invalid event name:", eventName)
    end
end

-- Fire event to server with security validation
function NetworkManager:FireServer(eventName, ...)
    if remotes[eventName] then
        local args = {...}
        
        -- Validate input before sending to server
        local config = securityConfigs[eventName]
        if config and config.requireValidation and config.inputSchema then
            local isValid, validatedArgs, error = SecurityWrapper.ValidateInput(args, config.inputSchema)
            if not isValid then
                warn("NetworkManager: Invalid input for", eventName, ":", error)
                return
            end
            args = validatedArgs
        end
        
        remotes[eventName]:FireServer(...)
    else
        warn("NetworkManager: Invalid event name:", eventName)
    end
end

-- Connect client event with security wrapper
function NetworkManager:ConnectClient(eventName, callback)
    if remotes[eventName] then
        -- Wrap callback with security validation
        local wrappedCallback = function(...)
            local args = {...}
            
            -- Validate input if schema exists
            local config = securityConfigs[eventName]
            if config and config.requireValidation and config.inputSchema then
                local isValid, validatedArgs, error = SecurityWrapper.ValidateInput(args, config.inputSchema)
                if not isValid then
                    warn("NetworkManager: Client received invalid data for", eventName, ":", error)
                    return
                end
                args = validatedArgs
            end
            
            -- Execute callback with validated args
            callback(unpack(args))
        end
        
        return remotes[eventName].OnClientEvent:Connect(wrappedCallback)
    else
        warn("NetworkManager: Invalid event name:", eventName)
        return nil
    end
end

-- Connect server event with security wrapper
function NetworkManager:ConnectServer(eventName, callback)
    if remotes[eventName] then
        -- Server events are already wrapped by SecurityWrapper
        return remotes[eventName].OnServerEvent:Connect(callback)
    else
        warn("NetworkManager: Invalid event name:", eventName)
        return nil
    end
end

-- Get security metrics
function NetworkManager:GetSecurityMetrics()
    if SecurityWrapper then
        return SecurityWrapper.GetSecurityMetrics()
    end
    return {}
end

-- Validate network data
function NetworkManager:ValidateData(data, schema)
    if DataValidator then
        return DataValidator.Validate(data, schema)
    end
    return true, data
end

-- Get security configuration for an event
function NetworkManager:GetSecurityConfig(eventName)
    return securityConfigs[eventName]
end

-- Update security configuration for an event
function NetworkManager:UpdateSecurityConfig(eventName, newConfig)
    if securityConfigs[eventName] then
        -- Merge configurations
        for key, value in pairs(newConfig) do
            securityConfigs[eventName][key] = value
        end
        
        -- Re-apply security wrapper
        local remote = remotes[eventName]
        if remote then
            SecurityWrapper.WrapRemoteEvent(remote, securityConfigs[eventName])
        end
        
        print("NetworkManager: Updated security config for", eventName)
    else
        warn("NetworkManager: Cannot update config for unknown event:", eventName)
    end
end

-- Create a new secure remote event
function NetworkManager:CreateSecureRemoteEvent(eventName, config)
    if remotes[eventName] then
        warn("NetworkManager: Remote event already exists:", eventName)
        return remotes[eventName]
    end
    
    -- Create new remote event
    local remote = Instance.new("RemoteEvent")
    remote.Name = eventName
    remote.Parent = remoteEvents
    
    -- Store in remotes table
    remotes[eventName] = remote
    
    -- Apply security wrapper
    local securityConfig = config or securityConfigs.PlayerJoin
    securityConfigs[eventName] = securityConfig
    SecurityWrapper.WrapRemoteEvent(remote, securityConfig)
    
    print("NetworkManager: Created secure remote event:", eventName)
    return remote
end

-- Cleanup function
function NetworkManager:Cleanup()
    -- Clean up all remote events
    for name, remote in pairs(remotes) do
        if remote and remote.Parent then
            remote:Destroy()
        end
    end
    
    -- Clear tables
    remotes = {}
    securityConfigs = {}
    eventHandlers = {}
    
    print("NetworkManager: Cleanup completed")
end

-- Initialize security monitoring
spawn(function()
    while true do
        wait(30) -- Check every 30 seconds
        
        -- Get security metrics
        local metrics = NetworkManager:GetSecurityMetrics()
        
        -- Log if there are security concerns
        if metrics.recentSecurityEvents > 10 then
            warn("NetworkManager: High security event rate detected:", metrics.recentSecurityEvents, "events in last hour")
        end
        
        if metrics.suspiciousPlayers > 0 then
            warn("NetworkManager: Suspicious players detected:", metrics.suspiciousPlayers)
        end
    end
end)

print("NetworkManager: Initialized with comprehensive security wrapper")

return NetworkManager
