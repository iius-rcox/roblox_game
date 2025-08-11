-- AbilityButton.lua - FIXED VERSION
-- Handles ability buttons with improved error handling and synchronization

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

-- Wait for required modules
local Constants = require(ReplicatedStorage:WaitForChild("Utils"):WaitForChild("Constants"))
local HelperFunctions = require(ReplicatedStorage:WaitForChild("Utils"):WaitForChild("HelperFunctions"))

local AbilityButton = {}
AbilityButton.__index = AbilityButton

-- NEW: Enhanced visual and audio effects
local ButtonEffects = {
    UPGRADE = {
        ParticleColor = Color3.fromRGB(255, 215, 0), -- Gold
        SoundId = "rbxasset://sounds/electronicpingshort.wav",
        Volume = 0.5
    },
    HOVER = {
        Scale = 1.2,
        Duration = 0.2,
        EasingStyle = Enum.EasingStyle.Quad,
        EasingDirection = Enum.EasingDirection.Out
    },
    CLICK = {
        Scale = 0.9,
        Duration = 0.1,
        EasingStyle = Enum.EasingStyle.Quad,
        EasingDirection = Enum.EasingDirection.Out
    }
}

-- Enhanced ability button configurations
local AbilityConfigs = {
    [1] = {
        Name = "Double Jump",
        Description = "Jump twice in the air",
        AbilityType = Constants.ABILITIES.DOUBLE_JUMP,
        Color = Color3.fromRGB(0, 255, 0),
        Icon = "🦘",
        BaseCost = 100
    },
    [2] = {
        Name = "Speed Boost",
        Description = "Move faster",
        AbilityType = Constants.ABILITIES.SPEED_BOOST,
        Color = Color3.fromRGB(255, 255, 0),
        Icon = "⚡",
        BaseCost = 150
    },
    [3] = {
        Name = "Jump Boost",
        Description = "Jump higher",
        AbilityType = Constants.ABILITIES.JUMP_BOOST,
        Color = Color3.fromRGB(0, 255, 255),
        Icon = "🚀",
        BaseCost = 200
    },
    [4] = {
        Name = "Cash Multiplier",
        Description = "Generate more cash",
        AbilityType = Constants.ABILITIES.CASH_MULTIPLIER,
        Color = Color3.fromRGB(255, 165, 0),
        Icon = "💰",
        BaseCost = 300
    },
    [5] = {
        Name = "Wall Repair",
        Description = "Repair walls automatically",
        AbilityType = Constants.ABILITIES.WALL_REPAIR,
        Color = Color3.fromRGB(128, 128, 128),
        Icon = "🔧",
        BaseCost = 250
    },
    [6] = {
        Name = "Teleport",
        Description = "Teleport to spawn",
        AbilityType = Constants.ABILITIES.TELEPORT,
        Color = Color3.fromRGB(255, 0, 255),
        Icon = "✨",
        BaseCost = 400
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
    self.isDestroyed = false
    self.clickDebounce = false
    
    if not self.config then
        warn("No config found for button number:", buttonNumber)
        return nil
    end
    
    -- Create the button part
    self.buttonPart = self:CreateButtonPart()
    
    -- Create the button UI
    self.buttonUI = self:CreateButtonUI()
    
    -- Connect events
    self:ConnectEvents()
    
    return self
end

-- Create the button part with enhanced visuals
function AbilityButton:CreateButtonPart()
    local button = Instance.new("Part")
    button.Name = "AbilityButton" .. self.buttonNumber
    button.Size = Vector3.new(4, 1, 4)
    button.Position = Vector3.new(0, 0.5, 0)
    button.Anchored = true
    button.CanCollide = false
    button.Material = Enum.Material.Neon
    button.Color = self.config.Color
    button.Transparency = 0.3
    button.Shape = Enum.PartType.Cylinder
    
    -- NEW: Enhanced visual effects
    local particleEmitter = Instance.new("ParticleEmitter")
    particleEmitter.Name = "AmbientParticles"
    particleEmitter.Color = ColorSequence.new(self.config.Color)
    particleEmitter.Size = NumberSequence.new(0.1, 0.3)
    particleEmitter.Transparency = NumberSequence.new(0.5, 1)
    particleEmitter.Rate = 5
    particleEmitter.Speed = NumberRange.new(0.5, 1.5)
    particleEmitter.Lifetime = NumberRange.new(1, 2)
    particleEmitter.SpreadAngle = Vector2.new(0, 360)
    particleEmitter.Parent = button
    
    -- NEW: Add ambient glow effect
    local pointLight = Instance.new("PointLight")
    pointLight.Name = "AmbientGlow"
    pointLight.Color = self.config.Color
    pointLight.Brightness = 0.5
    pointLight.Range = 8
    pointLight.Parent = button
    
    -- Add click detector with better range
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 20
    clickDetector.Parent = button
    
    -- Add surface GUI for the icon
    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Parent = button
    surfaceGui.Face = Enum.NormalId.Top
    surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surfaceGui.PixelsPerStud = 50
    
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Parent = surfaceGui
    iconLabel.Size = UDim2.new(1, 0, 1, 0)
    iconLabel.Text = self.config.Icon
    iconLabel.TextScaled = true
    iconLabel.BackgroundTransparency = 1
    iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    iconLabel.Font = Enum.Font.SourceSansBold

    -- Parent button to workspace so it becomes visible in the world
    button.Parent = workspace
    
    -- NEW: Enhanced hover effects with smooth animations
    local originalSize = button.Size
    local originalTransparency = button.Transparency
    local originalLightBrightness = pointLight.Brightness
    
    clickDetector.MouseHoverEnter:Connect(function()
        if not self.isDestroyed then
            -- Scale animation
            local scaleTween = TweenService:Create(button, TweenInfo.new(
                ButtonEffects.HOVER.Duration,
                ButtonEffects.HOVER.EasingStyle,
                ButtonEffects.HOVER.EasingDirection
            ), {
                Size = originalSize * ButtonEffects.HOVER.Scale,
                Transparency = 0.1
            })
            scaleTween:Play()
            
            -- Light animation
            local lightTween = TweenService:Create(pointLight, TweenInfo.new(
                ButtonEffects.HOVER.Duration,
                ButtonEffects.HOVER.EasingStyle,
                ButtonEffects.HOVER.EasingDirection
            ), {
                Brightness = originalLightBrightness * 2
            })
            lightTween:Play()
            
            -- Particle animation
            particleEmitter.Rate = 15
        end
    end)
    
    clickDetector.MouseHoverLeave:Connect(function()
        if not self.isDestroyed then
            -- Scale animation
            local scaleTween = TweenService:Create(button, TweenInfo.new(
                ButtonEffects.HOVER.Duration,
                ButtonEffects.HOVER.EasingStyle,
                ButtonEffects.HOVER.EasingDirection
            ), {
                Size = originalSize,
                Transparency = originalTransparency
            })
            scaleTween:Play()
            
            -- Light animation
            local lightTween = TweenService:Create(pointLight, TweenInfo.new(
                ButtonEffects.HOVER.Duration,
                ButtonEffects.HOVER.EasingStyle,
                ButtonEffects.HOVER.EasingDirection
            ), {
                Brightness = originalLightBrightness
            })
            lightTween:Play()
            
            -- Particle animation
            particleEmitter.Rate = 5
        end
    end)
    
    return button
end

-- Create enhanced button UI
function AbilityButton:CreateButtonUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AbilityButton" .. self.buttonNumber .. "UI"
    screenGui.ResetOnSpawn = false
    
    local frame = Instance.new("Frame")
    frame.Name = "MainFrame"
    frame.Size = UDim2.new(0, 220, 0, 100) -- Increased size for better layout
    frame.Position = UDim2.new(0, 10 + (self.buttonNumber - 1) * 230, 0, 10) -- Adjusted spacing
    frame.BackgroundColor3 = self.config.Color
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame
    
    -- Add stroke for better visibility
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 2
    stroke.Parent = frame
    
    -- NEW: Add progress bar background
    local progressBg = Instance.new("Frame")
    progressBg.Name = "ProgressBackground"
    progressBg.Size = UDim2.new(1, -20, 0, 6)
    progressBg.Position = UDim2.new(0, 10, 0, 65)
    progressBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    progressBg.BorderSizePixel = 0
    progressBg.Parent = frame
    
    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0, 3)
    progressCorner.Parent = progressBg
    
    -- NEW: Add progress bar fill
    local progressFill = Instance.new("Frame")
    progressFill.Name = "ProgressFill"
    progressFill.Size = UDim2.new(0, 0, 1, 0) -- Will be updated based on level
    progressFill.Position = UDim2.new(0, 0, 0, 0)
    progressFill.BackgroundColor3 = Color3.fromRGB(255, 215, 0) -- Gold
    progressFill.BorderSizePixel = 0
    progressFill.Parent = progressBg
    
    local progressFillCorner = Instance.new("UICorner")
    progressFillCorner.CornerRadius = UDim.new(0, 3)
    progressFillCorner.Parent = progressFill
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0, 25)
    nameLabel.Position = UDim2.new(0, 0, 0, 5)
    nameLabel.Text = self.config.Name
    nameLabel.TextScaled = true
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = frame
    
    local levelLabel = Instance.new("TextLabel")
    levelLabel.Name = "LevelLabel"
    levelLabel.Size = UDim2.new(1, 0, 0, 20)
    levelLabel.Position = UDim2.new(0, 0, 0, 30)
    levelLabel.Text = "Level: 0"
    levelLabel.TextScaled = true
    levelLabel.BackgroundTransparency = 1
    levelLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    levelLabel.Font = Enum.Font.Gotham
    levelLabel.Parent = frame
    
    local costLabel = Instance.new("TextLabel")
    costLabel.Name = "CostLabel"
    costLabel.Size = UDim2.new(1, 0, 0, 20)
    costLabel.Position = UDim2.new(0, 0, 0, 50)
    costLabel.Text = "Cost: $" .. self:GetUpgradeCost()
    costLabel.TextScaled = true
    costLabel.BackgroundTransparency = 1
    costLabel.TextColor3 = Color3.fromRGB(200, 255, 200)
    costLabel.Font = Enum.Font.Gotham
    costLabel.Parent = frame
    
    -- NEW: Add tooltip with ability description
    local tooltip = Instance.new("TextLabel")
    tooltip.Name = "Tooltip"
    tooltip.Size = UDim2.new(0, 200, 0, 0)
    tooltip.Position = UDim2.new(0, 0, 1, 5)
    tooltip.Text = self.config.Description
    tooltip.TextWrapped = true
    tooltip.TextScaled = false
    tooltip.TextSize = 12
    tooltip.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    tooltip.BackgroundTransparency = 0.8
    tooltip.TextColor3 = Color3.fromRGB(255, 255, 255)
    tooltip.Font = Enum.Font.Gotham
    tooltip.BorderSizePixel = 0
    tooltip.Parent = frame
    tooltip.Visible = false
    
    local tooltipCorner = Instance.new("UICorner")
    tooltipCorner.CornerRadius = UDim.new(0, 5)
    tooltipCorner.Parent = tooltip
    
    -- NEW: Add hover effect for tooltip
    frame.MouseEnter:Connect(function()
        tooltip.Visible = true
        tooltip.Size = UDim2.new(0, 200, 0, 40)
    end)
    
    frame.MouseLeave:Connect(function()
        tooltip.Visible = false
        tooltip.Size = UDim2.new(0, 200, 0, 0)
    end)
    
    return screenGui
end

-- Connect events with enhanced error handling
function AbilityButton:ConnectEvents()
    if self.buttonPart and self.buttonPart:FindFirstChild("ClickDetector") then
        self.buttonPart.ClickDetector.MouseClick:Connect(function(player)
            if not self.isDestroyed and not self.clickDebounce then
                self.clickDebounce = true
                
                task.spawn(function()
                    self:OnButtonClicked(player)
                    task.wait(1) -- 1 second debounce
                    self.clickDebounce = false
                end)
            end
        end)
    end
end

-- Enhanced button click handler
function AbilityButton:OnButtonClicked(player)
    if not HelperFunctions.IsValidPlayer(player) then return end
    
    -- Check if player owns this tycoon
    if not self:DoesPlayerOwnTycoon(player) then
        HelperFunctions.CreateNotification(player, "You don't own this tycoon!", 3)
        return
    end
    
    -- Check if already at max level
    if self.currentLevel >= self.maxLevel then
        HelperFunctions.CreateNotification(player, self.config.Name .. " is already at maximum level!", 3)
        return
    end
    
    -- Get upgrade cost
    local upgradeCost = self:GetUpgradeCost()
    
    -- Get player data safely
    local success, playerData = pcall(function()
        local PlayerData = require(ReplicatedStorage:WaitForChild("Player"):WaitForChild("PlayerData"))
        return PlayerData.GetPlayerData(player)
    end)
    
    if not success or not playerData then
        HelperFunctions.CreateNotification(player, "Error: Could not access player data!", 3)
        warn("AbilityButton: Could not get player data for", player.Name)
        return
    end
    
    -- Check if player can afford upgrade
    if not playerData:CanAfford(upgradeCost) then
        HelperFunctions.CreateNotification(player, 
            "You can't afford this upgrade! Cost: $" .. HelperFunctions.FormatCash(upgradeCost) .. 
            " (You have: $" .. HelperFunctions.FormatCash(playerData:GetCash()) .. ")", 5)
        return
    end
    
    -- Purchase upgrade
    if self:PurchaseUpgrade(player) then
        HelperFunctions.CreateNotification(player, 
            "Upgraded " .. self.config.Name .. " to level " .. self.currentLevel .. "!", 3)
        
        -- Apply ability to player with delay for character loading
        task.spawn(function()
            task.wait(0.5) -- Small delay to ensure character is ready
            self:ApplyAbilityToPlayer(player)
        end)
    else
        HelperFunctions.CreateNotification(player, "Upgrade failed! Please try again.", 3)
    end
end

-- Enhanced ownership check
function AbilityButton:DoesPlayerOwnTycoon(player)
    if not self.owner then return false end
    
    -- Multiple ways to check ownership
    if self.owner.UserId == player.UserId then
        return true
    end
    
    -- Additional check through player data
    local success, playerData = pcall(function()
        local PlayerData = require(ReplicatedStorage:WaitForChild("Player"):WaitForChild("PlayerData"))
        return PlayerData.GetPlayerData(player)
    end)
    
    if success and playerData then
        local currentTycoon = playerData:GetCurrentTycoon()
        return currentTycoon == self.tycoonId
    end
    
    return false
end

-- Enhanced upgrade cost calculation
function AbilityButton:GetUpgradeCost()
    if self.currentLevel >= self.maxLevel then
        return 0 -- Already at max level
    end
    
    local baseCost = self.config.BaseCost or Constants.ECONOMY.ABILITY_BASE_COST
    local multiplier = Constants.ECONOMY.UPGRADE_COST_MULTIPLIER or 1.5
    
    return math.floor(baseCost * (multiplier ^ self.currentLevel))
end

-- Enhanced purchase upgrade with better validation
function AbilityButton:PurchaseUpgrade(player)
    local upgradeCost = self:GetUpgradeCost()
    
    -- Get player data safely
    local success, playerData = pcall(function()
        local PlayerData = require(ReplicatedStorage:WaitForChild("Player"):WaitForChild("PlayerData"))
        return PlayerData.GetPlayerData(player)
    end)
    
    if not success or not playerData then
        warn("PurchaseUpgrade: Could not get player data")
        return false
    end
    
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
    
    -- NEW: Play upgrade sound effect
    self:PlayUpgradeSound()
    
    -- NEW: Create upgrade particle effect
    self:CreateUpgradeEffect()
    
    -- Upgrade ability
    self.currentLevel = self.currentLevel + 1
    
    -- Update player data ability level
    playerData:SetAbilityLevel(self.config.AbilityType, self.currentLevel)
    
    -- Update UI
    self:UpdateUI()
    
    -- Update button appearance
    self:UpdateButtonAppearance()
    
    print("AbilityButton: Successfully upgraded", self.config.Name, "to level", self.currentLevel, "for", player.Name)
    return true
end

-- NEW: Play upgrade sound effect
function AbilityButton:PlayUpgradeSound()
    if not self.buttonPart then return end
    
    local sound = Instance.new("Sound")
    sound.Name = "UpgradeSound"
    sound.SoundId = ButtonEffects.UPGRADE.SoundId
    sound.Volume = ButtonEffects.UPGRADE.Volume
    sound.Parent = self.buttonPart
    
    sound:Play()
    
    -- Clean up sound after playing
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

-- NEW: Create upgrade particle effect
function AbilityButton:CreateUpgradeEffect()
    if not self.buttonPart then return end
    
    -- Create burst effect
    local burstEmitter = Instance.new("ParticleEmitter")
    burstEmitter.Name = "UpgradeBurst"
    burstEmitter.Color = ColorSequence.new(ButtonEffects.UPGRADE.ParticleColor)
    burstEmitter.Size = NumberSequence.new(0.5, 2)
    burstEmitter.Transparency = NumberSequence.new(0, 1)
    burstEmitter.Rate = 0 -- Single burst
    burstEmitter.EmissionDirection = Enum.NormalId.Top
    burstEmitter.Speed = NumberRange.new(5, 15)
    burstEmitter.Lifetime = NumberRange.new(0.5, 1)
    burstEmitter.SpreadAngle = Vector2.new(0, 360)
    burstEmitter.Parent = self.buttonPart
    
    -- Trigger burst
    burstEmitter:Emit(20)
    
    -- Clean up after effect
    task.delay(1, function()
        if burstEmitter and burstEmitter.Parent then
            burstEmitter:Destroy()
        end
    end)
end

-- Enhanced ability application
function AbilityButton:ApplyAbilityToPlayer(player)
    if self.currentLevel <= 0 then return end
    
    -- Get player data safely
    local success, playerData = pcall(function()
        local PlayerData = require(ReplicatedStorage:WaitForChild("Player"):WaitForChild("PlayerData"))
        return PlayerData.GetPlayerData(player)
    end)
    
    if not success or not playerData then
        warn("ApplyAbilityToPlayer: Could not get player data")
        return
    end
    
    -- Set ability level in player data
    playerData:SetAbilityLevel(self.config.AbilityType, self.currentLevel)
    
    -- Apply ability effects through PlayerAbilities with retry logic
    task.spawn(function()
        for attempt = 1, 3 do
            local success2, playerAbilities = pcall(function()
                local PlayerAbilities = require(ReplicatedStorage:WaitForChild("Player"):WaitForChild("PlayerAbilities"))
                local controller = require(ReplicatedStorage:WaitForChild("Player"):WaitForChild("PlayerController"))
                local playerController = controller.GetPlayerController(player)
                if playerController then
                    return playerController:GetPlayerAbilities()
                end
                return nil
            end)
            
            if success2 and playerAbilities then
                playerAbilities:ApplyAbility(self.config.AbilityType, self.currentLevel)
                print("AbilityButton: Applied", self.config.Name, "level", self.currentLevel, "to", player.Name)
                break
            else
                warn("AbilityButton: Attempt", attempt, "failed to apply ability to", player.Name)
                if attempt < 3 then
                    task.wait(1) -- Wait before retry
                end
            end
        end
    end)
end

-- Enhanced UI update
function AbilityButton:UpdateUI()
    if not self.buttonUI then return end
    
    local levelLabel = self.buttonUI.MainFrame:FindFirstChild("LevelLabel")
    if levelLabel then
        levelLabel.Text = "Level: " .. self.currentLevel .. "/" .. self.maxLevel
        
        -- Color code based on level
        local percentage = self.currentLevel / self.maxLevel
        if percentage >= 1.0 then
            levelLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold for max level
        elseif percentage >= 0.7 then
            levelLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White for high level
        else
            levelLabel.TextColor3 = Color3.fromRGB(200, 200, 200) -- Gray for low level
        end
    end
    
    local costLabel = self.buttonUI.MainFrame:FindFirstChild("CostLabel")
    if costLabel then
        if self.currentLevel >= self.maxLevel then
            costLabel.Text = "MAX LEVEL"
            costLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
        else
            costLabel.Text = "Cost: $" .. HelperFunctions.FormatCash(self:GetUpgradeCost())
            costLabel.TextColor3 = Color3.fromRGB(200, 255, 200)
        end
    end
    
    -- NEW: Update progress bar
    local progressFill = self.buttonUI.MainFrame.ProgressBackground:FindFirstChild("ProgressFill")
    if progressFill then
        local percentage = self.currentLevel / self.maxLevel
        local targetSize = UDim2.new(percentage, 0, 1, 0)
        
        -- Animate progress bar update
        local progressTween = TweenService:Create(progressFill, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = targetSize
        })
        progressTween:Play()
        
        -- Update progress bar color based on level
        if percentage >= 1.0 then
            progressFill.BackgroundColor3 = Color3.fromRGB(255, 215, 0) -- Gold for max
        elseif percentage >= 0.7 then
            progressFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Green for high
        elseif percentage >= 0.4 then
            progressFill.BackgroundColor3 = Color3.fromRGB(255, 165, 0) -- Orange for medium
        else
            progressFill.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Red for low
        end
    end
    
    -- Update frame transparency based on level
    local frame = self.buttonUI.MainFrame
    if frame then
        local alpha = 0.2 + (self.currentLevel / self.maxLevel) * 0.6
        frame.BackgroundTransparency = 1 - alpha
    end
end

-- Enhanced button appearance update
function AbilityButton:UpdateButtonAppearance()
    if not self.buttonPart then return end
    
    -- Update transparency based on level
    local transparency = 0.3 - (self.currentLevel / self.maxLevel) * 0.2
    self.buttonPart.Transparency = math.max(0.1, transparency)
    
    -- Update size based on level
    local sizeMultiplier = 1 + (self.currentLevel / self.maxLevel) * 0.5
    local baseSize = Vector3.new(4, 1, 4)
    self.buttonPart.Size = baseSize * sizeMultiplier
    
    -- Update color intensity based on level
    local intensity = 0.5 + (self.currentLevel / self.maxLevel) * 0.5
    local originalColor = self.config.Color
    self.buttonPart.Color = Color3.new(
        originalColor.R * intensity,
        originalColor.G * intensity,
        originalColor.B * intensity
    )
    
    -- Add special effect for max level
    if self.currentLevel >= self.maxLevel then
        self.buttonPart.Material = Enum.Material.ForceField
        
        -- Add sparkle effect
        if not self.buttonPart:FindFirstChild("Sparkle") then
            local sparkle = Instance.new("Sparkles")
            sparkle.Name = "Sparkle"
            sparkle.Color = self.config.Color
            sparkle.Parent = self.buttonPart
        end
    end
end

-- Set button position
function AbilityButton:SetPosition(position)
    if self.buttonPart and typeof(position) == "Vector3" then
        self.buttonPart.Position = position
    end
end

-- Get button position
function AbilityButton:GetPosition()
    return self.buttonPart and self.buttonPart.Position or Vector3.new(0, 0, 0)
end

-- Set button owner with validation
function AbilityButton:SetOwner(owner)
    if owner and HelperFunctions.IsValidPlayer(owner) then
        self.owner = owner
        print("AbilityButton: Set owner to", owner.Name, "for button", self.buttonNumber)
    else
        self.owner = nil
        print("AbilityButton: Cleared owner for button", self.buttonNumber)
    end
end

-- Get button owner
function AbilityButton:GetOwner()
    return self.owner
end

-- Get current level
function AbilityButton:GetCurrentLevel()
    return self.currentLevel
end

-- Set current level with validation
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
        self.buttonPart.Material = Enum.Material.Neon
    end
    print("AbilityButton: Activated button", self.buttonNumber)
end

-- Deactivate button
function AbilityButton:Deactivate()
    self.isActive = false
    if self.buttonPart then
        self.buttonPart.Color = Color3.fromRGB(128, 128, 128)
        self.buttonPart.Material = Enum.Material.Concrete
    end
    print("AbilityButton: Deactivated button", self.buttonNumber)
end

-- Get button data for saving
function AbilityButton:GetData()
    return {
        ButtonNumber = self.buttonNumber,
        TycoonId = self.tycoonId,
        Owner = self.owner and self.owner.UserId or nil,
        CurrentLevel = self.currentLevel,
        IsActive = self.isActive,
        Config = self.config
    }
end

-- Load button data with validation
function AbilityButton:LoadData(data)
    if type(data) ~= "table" then return false end
    
    if data.CurrentLevel and type(data.CurrentLevel) == "number" then
        self:SetCurrentLevel(data.CurrentLevel)
    end
    
    if data.IsActive ~= nil then
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

-- Enhanced cleanup
function AbilityButton:Destroy()
    self.isDestroyed = true
    
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
    
    print("AbilityButton: Destroyed button", self.buttonNumber)
end

return AbilityButton
