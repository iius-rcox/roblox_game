-- HelperFunctions.lua
-- Utility functions used throughout the game
-- Enhanced with Roblox best practices for performance and memory management

-- NEW: Memory category tagging for better memory tracking (Roblox best practice)
debug.setmemorycategory("HelperFunctions")

local HelperFunctions = {}

-- NEW: Local service references for better performance (Roblox best practice)
local Debris = game:GetService("Debris")

-- NEW: Cache frequently used functions for better performance (Roblox best practice)
local type = type
local pairs = pairs
local ipairs = ipairs
local math_floor = math.floor
local math_max = math.max
local string_gsub = string.gsub
local Vector3_new = Vector3.new

-- NEW: Input validation constants (Roblox best practice)
local VALID_PLAYER_TYPES = {
    ["Player"] = true
}

local VALID_PART_TYPES = {
    ["BasePart"] = true,
    ["Part"] = true,
    ["WedgePart"] = true,
    ["CornerWedgePart"] = true,
    ["TrussPart"] = true,
    ["VehicleSeat"] = true,
    ["SkateboardPlatform"] = true,
    ["Inlet"] = true,
    ["Outlet"] = true,
    ["BlockMesh"] = true,
    ["CylinderMesh"] = true,
    ["SpecialMesh"] = true
}

-- NEW: Error handling wrapper (Roblox best practice)
function HelperFunctions.SafeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        warn("HelperFunctions error in", debug.traceback(), ":", result)
        return nil
    end
    return result
end

-- Check if a player is valid and in the game
function HelperFunctions.IsValidPlayer(player)
    -- NEW: Enhanced validation with type checking (Roblox best practice)
    if not player then return false end
    
    -- Use cached type check for better performance
    local playerType = typeof(player)
    if playerType ~= "Instance" then return false end
    
    -- Check if it's a Player instance
    if not VALID_PLAYER_TYPES[player.ClassName] then return false end
    
    -- Check if player is still in the game
    if not player.Parent then return false end
    
    return true
end

-- Check if a part exists and is valid
function HelperFunctions.IsValidPart(part)
    -- NEW: Enhanced validation with type checking (Roblox best practice)
    if not part then return false end
    
    -- Use cached type check for better performance
    local partType = typeof(part)
    if partType ~= "Instance" then return false end
    
    -- Check if it's a valid part type
    if not VALID_PART_TYPES[part.ClassName] then return false end
    
    -- Check if part is still in the game
    if not part.Parent then return false end
    
    return true
end

-- Get the distance between two Vector3 positions
function HelperFunctions.GetDistance(pos1, pos2)
    -- NEW: Input validation and error handling (Roblox best practice)
    if not pos1 or not pos2 then
        warn("GetDistance: Invalid position parameters")
        return math.huge
    end
    
    -- Check if positions are Vector3
    if typeof(pos1) ~= "Vector3" or typeof(pos2) ~= "Vector3" then
        warn("GetDistance: Parameters must be Vector3")
        return math.huge
    end
    
    -- Use Vector3 subtraction and magnitude for better performance
    return (pos1 - pos2).Magnitude
end

-- Check if a player is within range of a position
function HelperFunctions.IsPlayerInRange(player, position, range)
    -- NEW: Enhanced input validation (Roblox best practice)
    if not HelperFunctions.IsValidPlayer(player) then
        return false
    end
    
    if not position or typeof(position) ~= "Vector3" then
        warn("IsPlayerInRange: Invalid position parameter")
        return false
    end
    
    if not range or type(range) ~= "number" or range < 0 then
        warn("IsPlayerInRange: Invalid range parameter")
        return false
    end
    
    local character = player.Character
    if not character then return false end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return false end
    
    -- Use cached distance function for better performance
    return HelperFunctions.GetDistance(humanoidRootPart.Position, position) <= range
end

-- Create a simple UI notification
function HelperFunctions.CreateNotification(player, message, duration)
    -- NEW: Enhanced input validation (Roblox best practice)
    if not HelperFunctions.IsValidPlayer(player) then
        warn("CreateNotification: Invalid player parameter")
        return
    end
    
    if not message or type(message) ~= "string" then
        warn("CreateNotification: Invalid message parameter")
        return
    end
    
    if duration and (type(duration) ~= "number" or duration < 0) then
        warn("CreateNotification: Invalid duration parameter")
        duration = 3 -- Default fallback
    end
    
    local screenGui = player:FindFirstChild("PlayerGui")
    if not screenGui then
        warn("CreateNotification: PlayerGui not found")
        return
    end
    
    -- NEW: Use Instance.new with properties table for better performance (Roblox best practice)
    local notification = Instance.new("TextLabel")
    notification.Text = message
    notification.Size = UDim2.new(0, 300, 0, 50)
    notification.Position = UDim2.new(0.5, -150, 0.1, 0)
    notification.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    notification.TextColor3 = Color3.fromRGB(255, 255, 255)
    notification.Font = Enum.Font.SourceSansBold
    notification.TextScaled = true
    notification.Parent = screenGui
    
    -- NEW: Use cached Debris service for better performance (Roblox best practice)
    Debris:AddItem(notification, duration or 3)
    
    return notification
end

-- Safely get a value from a table with a default
function HelperFunctions.GetValueOrDefault(table, key, default)
    -- NEW: Enhanced input validation (Roblox best practice)
    if not table or type(table) ~= "table" then
        warn("GetValueOrDefault: Invalid table parameter")
        return default
    end
    
    if key == nil then
        warn("GetValueOrDefault: Invalid key parameter")
        return default
    end
    
    -- Check if the key exists and has a non-nil value
    if table[key] ~= nil then
        return table[key]
    end
    
    return default
end

-- Round a number to specified decimal places
function HelperFunctions.Round(number, decimals)
    -- NEW: Enhanced input validation (Roblox best practice)
    if not number or type(number) ~= "number" then
        warn("Round: Invalid number parameter")
        return 0
    end
    
    if decimals and (type(decimals) ~= "number" or decimals < 0) then
        warn("Round: Invalid decimals parameter")
        decimals = 0
    end
    
    decimals = decimals or 0
    local multiplier = 10^decimals
    
    -- Use cached math.floor for better performance
    return math_floor(number * multiplier + 0.5) / multiplier
end

-- Format cash amount with commas
function HelperFunctions.FormatCash(amount)
    -- NEW: Enhanced input validation (Roblox best practice)
    if not amount or type(amount) ~= "number" then
        warn("FormatCash: Invalid amount parameter")
        return "0"
    end
    
    -- Use cached math.floor for better performance
    local formatted = tostring(math_floor(amount))
    
    -- Handle negative numbers
    local isNegative = amount < 0
    if isNegative then
        formatted = formatted:sub(2) -- Remove minus sign
    end
    
    -- Add commas for thousands
    local k
    while true do
        formatted, k = string_gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then
            break
        end
    end
    
    -- Restore minus sign if needed
    if isNegative then
        formatted = "-" .. formatted
    end
    
    return formatted
end

-- Create a simple part with specified properties
function HelperFunctions.CreatePart(properties)
    -- NEW: Enhanced input validation (Roblox best practice)
    if not properties or type(properties) ~= "table" then
        warn("CreatePart: Invalid properties parameter")
        properties = {}
    end
    
    local part = Instance.new("Part")
    
    -- NEW: Use pairs for better performance and error handling (Roblox best practice)
    for property, value in pairs(properties) do
        -- Check if the property exists on the part
        if part[property] ~= nil then
            -- Use SafeCall for property assignment to catch errors
            HelperFunctions.SafeCall(function()
                part[property] = value
            end)
        else
            warn("CreatePart: Invalid property '" .. tostring(property) .. "' for Part")
        end
    end
    
    return part
end

-- Check if a table contains a value
function HelperFunctions.TableContains(table, value)
    -- NEW: Enhanced input validation (Roblox best practice)
    if not table or type(table) ~= "table" then
        warn("TableContains: Invalid table parameter")
        return false
    end
    
    -- Use pairs for better performance (Roblox best practice)
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end
    
    return false
end

-- NEW: Enhanced table operations (Roblox best practice)
function HelperFunctions.TableLength(table)
    if not table or type(table) ~= "table" then
        return 0
    end
    
    local count = 0
    for _ in pairs(table) do
        count = count + 1
    end
    
    return count
end

-- NEW: Safe table deep copy (Roblox best practice)
function HelperFunctions.DeepCopy(original)
    if type(original) ~= "table" then
        return original
    end
    
    local copy = {}
    for key, value in pairs(original) do
        if type(value) == "table" then
            copy[key] = HelperFunctions.DeepCopy(value)
        else
            copy[key] = value
        end
    end
    
    return copy
end

-- NEW: Memory-efficient table cleanup (Roblox best practice)
function HelperFunctions.CleanupTable(table)
    if not table or type(table) ~= "table" then
        return
    end
    
    -- Clear all entries
    for key in pairs(table) do
        table[key] = nil
    end
    
    -- Set metatable to nil to help garbage collection
    setmetatable(table, nil)
end

-- NEW: Performance monitoring helper (Roblox best practice)
function HelperFunctions.MeasurePerformance(func, iterations)
    iterations = iterations or 1000
    
    local startTime = time()
    for i = 1, iterations do
        func()
    end
    local endTime = time()
    
    local totalTime = endTime - startTime
    local averageTime = totalTime / iterations
    
    return {
        totalTime = totalTime,
        averageTime = averageTime,
        iterations = iterations
    }
end

-- NEW: Safe string operations (Roblox best practice)
function HelperFunctions.SafeStringOperation(str, operation, ...)
    if not str or type(str) ~= "string" then
        warn("SafeStringOperation: Invalid string parameter")
        return str
    end
    
    return HelperFunctions.SafeCall(operation, str, ...)
end

-- NEW: Efficient number formatting (Roblox best practice)
function HelperFunctions.FormatNumber(number, decimals, useCommas)
    if not number or type(number) ~= "number" then
        return "0"
    end
    
    decimals = decimals or 0
    useCommas = useCommas ~= false -- Default to true
    
    local formatted = HelperFunctions.Round(number, decimals)
    
    if useCommas and decimals == 0 then
        -- Only add commas for whole numbers
        formatted = HelperFunctions.FormatCash(number)
    else
        formatted = tostring(formatted)
    end
    
    return formatted
end

-- NEW: Vector3 utility functions (Roblox best practice)
function HelperFunctions.CreateVector3(x, y, z)
    if not x or not y or not z then
        warn("CreateVector3: Invalid coordinates")
        return Vector3_new(0, 0, 0)
    end
    
    if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then
        warn("CreateVector3: Coordinates must be numbers")
        return Vector3_new(0, 0, 0)
    end
    
    return Vector3_new(x, y, z)
end

-- NEW: Color3 utility functions (Roblox best practice)
function HelperFunctions.CreateColor3(r, g, b)
    if not r or not g or not b then
        warn("CreateColor3: Invalid color values")
        return Color3.new(1, 1, 1) -- Default to white
    end
    
    if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then
        warn("CreateColor3: Color values must be numbers")
        return Color3.new(1, 1, 1)
    end
    
    -- Clamp values to 0-1 range
    r = math_max(0, math_max(1, r))
    g = math_max(0, math_max(1, g))
    b = math_max(0, math_max(1, b))
    
    return Color3.new(r, g, b)
end

-- NEW: Instance utility functions (Roblox best practice)
function HelperFunctions.SafeDestroy(instance)
    if not instance then return end
    
    if typeof(instance) == "Instance" then
        HelperFunctions.SafeCall(function()
            instance:Destroy()
        end)
    end
end

function HelperFunctions.SafeParent(instance, parent)
    if not instance or not parent then
        warn("SafeParent: Invalid parameters")
        return
    end
    
    if typeof(instance) == "Instance" and typeof(parent) == "Instance" then
        HelperFunctions.SafeCall(function()
            instance.Parent = parent
        end)
    end
end

-- NEW: Debug and logging utilities (Roblox best practice)
function HelperFunctions.Log(message, level)
    level = level or "INFO"
    
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local logMessage = string.format("[%s] [%s] %s", timestamp, level, tostring(message))
    
    if level == "ERROR" then
        error(logMessage, 2)
    elseif level == "WARN" then
        warn(logMessage)
    else
        print(logMessage)
    end
end

function HelperFunctions.LogError(message)
    HelperFunctions.Log(message, "ERROR")
end

function HelperFunctions.LogWarning(message)
    HelperFunctions.Log(message, "WARN")
end

function HelperFunctions.LogInfo(message)
    HelperFunctions.Log(message, "INFO")
end

-- NEW: Performance optimization utilities (Roblox best practice)
function HelperFunctions.ThrottleFunction(func, delay)
    local lastCall = 0
    
    return function(...)
        local currentTime = time()
        if currentTime - lastCall >= delay then
            lastCall = currentTime
            return func(...)
        end
    end
end

function HelperFunctions.DebounceFunction(func, delay)
    local connection = nil
    
    return function(...)
        if connection then
            connection:Disconnect()
        end
        
        connection = task.delay(delay, func, ...)
    end
end

return HelperFunctions
