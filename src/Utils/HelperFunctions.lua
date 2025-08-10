-- HelperFunctions.lua
-- Utility functions used throughout the game

local HelperFunctions = {}

-- Check if a player is valid and in the game
function HelperFunctions.IsValidPlayer(player)
    return player and player:IsA("Player") and player.Parent
end

-- Check if a part exists and is valid
function HelperFunctions.IsValidPart(part)
    return part and part:IsA("BasePart") and part.Parent
end

-- Get the distance between two Vector3 positions
function HelperFunctions.GetDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

-- Check if a player is within range of a position
function HelperFunctions.IsPlayerInRange(player, position, range)
    if not HelperFunctions.IsValidPlayer(player) then
        return false
    end
    
    local playerPos = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not playerPos then
        return false
    end
    
    return HelperFunctions.GetDistance(playerPos.Position, position) <= range
end

-- Create a simple UI notification
function HelperFunctions.CreateNotification(player, message, duration)
    if not HelperFunctions.IsValidPlayer(player) then
        return
    end
    
    local screenGui = player:FindFirstChild("PlayerGui")
    if not screenGui then
        return
    end
    
    local notification = Instance.new("TextLabel")
    notification.Text = message
    notification.Size = UDim2.new(0, 300, 0, 50)
    notification.Position = UDim2.new(0.5, -150, 0.1, 0)
    notification.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    notification.TextColor3 = Color3.fromRGB(255, 255, 255)
    notification.Font = Enum.Font.SourceSansBold
    notification.TextScaled = true
    notification.Parent = screenGui
    
    -- Auto-remove after duration
    game:GetService("Debris"):AddItem(notification, duration or 3)
end

-- Safely get a value from a table with a default
function HelperFunctions.GetValueOrDefault(table, key, default)
    if table and table[key] ~= nil then
        return table[key]
    end
    return default
end

-- Round a number to specified decimal places
function HelperFunctions.Round(number, decimals)
    decimals = decimals or 0
    local multiplier = 10^decimals
    return math.floor(number * multiplier + 0.5) / multiplier
end

-- Format cash amount with commas
function HelperFunctions.FormatCash(amount)
    local formatted = tostring(math.floor(amount))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then
            break
        end
    end
    return formatted
end

-- Create a simple part with specified properties
function HelperFunctions.CreatePart(properties)
    local part = Instance.new("Part")
    
    for property, value in pairs(properties) do
        if part[property] ~= nil then
            part[property] = value
        end
    end
    
    return part
end

-- Check if a table contains a value
function HelperFunctions.TableContains(table, value)
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

return HelperFunctions
