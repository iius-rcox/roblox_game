-- AbilityButton.lua
-- Handles ability buttons with placeholder effects and ability reclaim

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Constants = require(script.Parent.Parent.Utils.Constants)
local HelperFunctions = require(script.Parent.Parent.Utils.HelperFunctions)

local AbilityButton = {}
AbilityButton.__index = AbilityButton

-- Ability button configurations
local AbilityConfigs = {
    [1] = {
        Name = "Double Jump",
        Description = "Jump twice in the air",
        AbilityType = Constants.ABILITIES.DOUBLE_JUMP,
        Color = Color3.fromRGB(0, 255, 0),
        Icon = "🦘"
    },
    [2] = {
        Name = "Speed Boost",
        Description = "Move faster",
        AbilityType = Constants.ABILITIES.SPEED_BOOST,
        Color = Color3.fromRGB(255, 255, 0),
        Icon = "⚡"
    },
    [3] = {
        Name = "Jump Boost",
        Description = "Jump higher",
        AbilityType = Constants.ABILITIES.JUMP_BOOST,
        Color = Color3.fromRGB(0, 255, 255),
        Icon = "🚀"
    },
    [4] = {
        Name = "Cash Multiplier",
        Description = "Generate more cash",
        AbilityType = Constants.ABILITIES.CASH_MULTIPLIER,
        Color = Color3.fromRGB(255, 165, 0),
        Icon = "💰"
    },
    [5] = {
        Name = "Wall Repair",
        Description = "Repair walls automatically",
        AbilityType = Constants.ABILITIES.WALL_REPAIR,
        Color = Color3.fromRGB(128, 128, 128),
        Icon = "🔧"
    },
    [6] = {
        Name = "Teleport",
        Description = "Teleport to spawn",
        AbilityType = Constants.ABILITIES.TELEPORT,
        Color = Color3.fromRGB(255, 0, 255),
        Icon = "✨"
    }
}

-- Create new ability button
function AbilityButton.new(buttonNumber, tycoonId, owner)
    if buttonNumber < 1 or buttonNumber > Constants.TYCOON.MAX_ABILITY_BUTTONS then
        warn("Invalid button number: " .. tostring(buttonNumber))
        return nil
    end
    
    local self = setmetatable({}, AbilityButton)
    self.buttonNumber = buttonNumber
    self.tycoonId = tycoonId
    self.owner = owner
    self.config = AbilityConfigs[buttonNumber]
    self.isActive = false
    self.currentLevel = 0
    self.maxLevel = Constants.ECONOMY.MAX_UPGRADE_LEVEL
    
    -- Create the button part
    self.buttonPart = self:CreateButtonPart()
    
    -- Create the button UI
    self.buttonUI = self:CreateButtonUI()
    
    -- Connect events
    self:ConnectEvents()
    
    return self
end

-- Create the button part
function AbilityButton:CreateButtonPart()
    local button = Instance.new("Part")
    button.Name = "AbilityButton" .. self.buttonNumber
    button.Size = Vector3.new(4, 1, 4)
    button.Position = Vector3.new(0, 0.5, 0) -- Will be positioned by tycoon
    button.Anchored = true
    button.CanCollide = false
    button.Material = Enum.Material.Neon
    button.Color = self.config.Color
    button.Transparency = 0.3
    
    -- Add click detector
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.Parent = button
    
    -- Add surface GUI for the icon
    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Parent = button
    surfaceGui.Face = Enum.NormalId.Top
    surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surfaceGui.PixelsPerStud = 20
    
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Parent = surfaceGui
    iconLabel.Size = UDim2.new(1, 0, 1, 0)
    iconLabel.Text = self.config.Icon
    iconLabel.TextScaled = true
    iconLabel.BackgroundTransparency = 1
    iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    iconLabel.Font = Enum.Font.SourceSansBold
    
    return button
end

-- Create the button UI
function AbilityButton:CreateButtonUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AbilityButton" .. self.buttonNumber .. "UI"
    screenGui.ResetOnSpawn = false
    
    local frame = Instance.new("Frame")
    frame.Name = "MainFrame"
    frame.Size = UDim2.new(0, 200, 0, 60)
    frame.Position = UDim2.new(0, 10 + (self.buttonNumber - 1) * 210, 0, 10)
    frame.BackgroundColor3 = self.config.Color
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.Text = self.config.Name
    nameLabel.TextScaled = true
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.Parent = frame
    
    local levelLabel = Instance.new("TextLabel")
    levelLabel.Name = "LevelLabel"
    levelLabel.Size = UDim2.new(1, 0, 0.5, 0)
    levelLabel.Position = UDim2.new(0, 0, 0.5, 0)
    levelLabel.Text = "Level: 0"
    levelLabel.TextScaled = true
    levelLabel.BackgroundTransparency = 1
    levelLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    levelLabel.Font = Enum.Font.SourceSans
    levelLabel.Parent = frame
    
    return screenGui
end

-- Connect events
function AbilityButton:ConnectEvents()
    if self.buttonPart and self.buttonPart:FindFirstChild("ClickDetector") then
        self.buttonPart.ClickDetector.MouseClick:Connect(function(player)
            self:OnButtonClicked(player)
        end)
    end
end

-- Handle button click
function AbilityButton:OnButtonClicked(player)
    if not HelperFunctions.IsValidPlayer(player) then return end
    
    -- Check if player owns this tycoon
    if not self:DoesPlayerOwnTycoon(player) then
        HelperFunctions.CreateNotification(player, "You don't own this tycoon!", 3)
        return
    end
    
    -- Check if player can afford upgrade
    local upgradeCost = self:GetUpgradeCost()
    local playerData = require(script.Parent.Parent.Player.PlayerData).GetPlayerData(player)
    
    if not playerData or not playerData:CanAfford(upgradeCost) then
        HelperFunctions.CreateNotification(player, "You can't afford this upgrade! Cost: $" .. HelperFunctions.FormatCash(upgradeCost), 3)
        return
    end
    
    -- Purchase upgrade
    if self:PurchaseUpgrade(player) then
        HelperFunctions.CreateNotification(player, "Upgraded " .. self.config.Name .. " to level " .. self.currentLevel .. "!", 3)
        
        -- Apply ability to player
        self:ApplyAbilityToPlayer(player)
    end
end

-- Check if player owns the tycoon
function AbilityButton:DoesPlayerOwnTycoon(player)
    if not self.owner then return false end
    return self.owner.UserId == player.UserId
end

-- Get upgrade cost
function AbilityButton:GetUpgradeCost()
    if self.currentLevel >= self.maxLevel then
        return math.huge -- Can't upgrade further
    end
    
    return math.floor(Constants.ECONOMY.ABILITY_BASE_COST * (Constants.ECONOMY.UPGRADE_COST_MULTIPLIER ^ self.currentLevel))
end

-- Purchase upgrade
function AbilityButton:PurchaseUpgrade(player)
    local upgradeCost = self:GetUpgradeCost()
    local playerData = require(script.Parent.Parent.Player.PlayerData).GetPlayerData(player)
    
    if not playerData then return false end
    
    -- Check if can afford
    if not playerData:CanAfford(upgradeCost) then
        return false
    end
    
    -- Check if can upgrade
    if self.currentLevel >= self.maxLevel then
        return false
    end
    
    -- Deduct cash
    if not playerData:AddCash(-upgradeCost) then
        return false
    end
    
    -- Upgrade ability
    self.currentLevel = self.currentLevel + 1
    
    -- Update UI
    self:UpdateUI()
    
    -- Update button appearance
    self:UpdateButtonAppearance()
    
    return true
end

-- Apply ability to player
function AbilityButton:ApplyAbilityToPlayer(player)
    if self.currentLevel <= 0 then return end
    
    local playerData = require(script.Parent.Parent.Player.PlayerData).GetPlayerData(player)
    if not playerData then return end
    
    -- Set ability level
    playerData:SetAbilityLevel(self.config.AbilityType, self.currentLevel)
    
    -- Apply ability effects (handled by PlayerAbilities)
    local playerAbilities = require(script.Parent.Parent.Player.PlayerAbilities).new(player)
    if playerAbilities then
        playerAbilities:ApplyAbility(self.config.AbilityType, self.currentLevel)
    end
end

-- Update UI
function AbilityButton:UpdateUI()
    if not self.buttonUI then return end
    
    local levelLabel = self.buttonUI.MainFrame.LevelLabel
    if levelLabel then
        levelLabel.Text = "Level: " .. self.currentLevel
    end
    
    -- Update button color based on level
    local frame = self.buttonUI.MainFrame
    if frame then
        local alpha = 0.2 + (self.currentLevel / self.maxLevel) * 0.8
        frame.BackgroundTransparency = 1 - alpha
    end
end

-- Update button appearance
function AbilityButton:UpdateButtonAppearance()
    if not self.buttonPart then return end
    
    -- Update transparency based on level
    local transparency = 0.3 - (self.currentLevel / self.maxLevel) * 0.2
    self.buttonPart.Transparency = math.max(0.1, transparency)
    
    -- Update size based on level
    local sizeMultiplier = 1 + (self.currentLevel / self.maxLevel) * 0.5
    self.buttonPart.Size = Vector3.new(4 * sizeMultiplier, 1, 4 * sizeMultiplier)
end

-- Set button position
function AbilityButton:SetPosition(position)
    if self.buttonPart and type(position) == "Vector3" then
        self.buttonPart.Position = position
    end
end

-- Get button position
function AbilityButton:GetPosition()
    return self.buttonPart and self.buttonPart.Position or Vector3.new(0, 0, 0)
end

-- Set button owner
function AbilityButton:SetOwner(owner)
    self.owner = owner
end

-- Get button owner
function AbilityButton:GetOwner()
    return self.owner
end

-- Get current level
function AbilityButton:GetCurrentLevel()
    return self.currentLevel
end

-- Set current level
function AbilityButton:SetCurrentLevel(level)
    if type(level) == "number" and level >= 0 and level <= self.maxLevel then
        self.currentLevel = level
        self:UpdateUI()
        self:UpdateButtonAppearance()
        return true
    end
    return false
end

-- Check if button is active
function AbilityButton:IsActive()
    return self.isActive
end

-- Activate button
function AbilityButton:Activate()
    self.isActive = true
    if self.buttonPart then
        self.buttonPart.Color = self.config.Color
    end
end

-- Deactivate button
function AbilityButton:Deactivate()
    self.isActive = false
    if self.buttonPart then
        self.buttonPart.Color = Color3.fromRGB(128, 128, 128)
    end
end

-- Get button data for saving
function AbilityButton:GetData()
    return {
        ButtonNumber = self.buttonNumber,
        TycoonId = self.tycoonId,
        Owner = self.owner and self.owner.UserId or nil,
        CurrentLevel = self.currentLevel,
        IsActive = self.isActive
    }
end

-- Load button data
function AbilityButton:LoadData(data)
    if type(data) ~= "table" then return false end
    
    if data.CurrentLevel then
        self:SetCurrentLevel(data.CurrentLevel)
    end
    
    if data.IsActive then
        if data.IsActive then
            self:Activate()
        else
            self:Deactivate()
        end
    end
    
    return true
end

-- Show UI for player
function AbilityButton:ShowUI(player)
    if not HelperFunctions.IsValidPlayer(player) then return end
    
    if self.buttonUI then
        self.buttonUI.Parent = player:FindFirstChild("PlayerGui")
    end
end

-- Hide UI for player
function AbilityButton:HideUI(player)
    if not HelperFunctions.IsValidPlayer(player) then return end
    
    if self.buttonUI then
        self.buttonUI.Parent = nil
    end
end

-- Clean up
function AbilityButton:Destroy()
    if self.buttonPart then
        self.buttonPart:Destroy()
        self.buttonPart = nil
    end
    
    if self.buttonUI then
        self.buttonUI:Destroy()
        self.buttonUI = nil
    end
    
    self.tycoonId = nil
    self.owner = nil
    self.config = nil
end

return AbilityButton
