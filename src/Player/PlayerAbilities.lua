-- PlayerAbilities.lua
-- Manages player abilities and their effects

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Constants = require(script.Parent.Parent.Utils.Constants)
local HelperFunctions = require(script.Parent.Parent.Utils.HelperFunctions)

local PlayerAbilities = {}
PlayerAbilities.__index = PlayerAbilities

-- Store active ability effects for each player
local activeEffects = {}

-- Create new player abilities manager
function PlayerAbilities.new(player)
    if not HelperFunctions.IsValidPlayer(player) then
        warn("Invalid player provided to PlayerAbilities.new")
        return nil
    end
    
    local self = setmetatable({}, PlayerAbilities)
    self.player = player
    self.userId = player.UserId
    self.character = nil
    self.humanoid = nil
    self.humanoidRootPart = nil
    
    -- Initialize active effects
    activeEffects[self.userId] = {}
    
    -- Connect to character events
    self:ConnectToCharacter()
    
    return self
end

-- Connect to character events
function PlayerAbilities:ConnectToCharacter()
    if self.player.Character then
        self:OnCharacterAdded(self.player.Character)
    end
    
    self.player.CharacterAdded:Connect(function(character)
        self:OnCharacterAdded(character)
    end)
    
    self.player.CharacterRemoving:Connect(function(character)
        self:OnCharacterRemoving(character)
    end)
end

-- Handle character added
function PlayerAbilities:OnCharacterAdded(character)
    self.character = character
    self.humanoid = character:WaitForChild("Humanoid")
    self.humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    -- Apply current abilities
    self:ApplyAllAbilities()
    
    -- Connect to death event
    self.humanoid.Died:Connect(function()
        self:OnPlayerDied()
    end)
end

-- Handle character removing
function PlayerAbilities:OnCharacterRemoving(character)
    self.character = nil
    self.humanoid = nil
    self.humanoidRootPart = nil
    
    -- Clear all active effects
    self:ClearAllEffects()
end

-- Handle player death
function PlayerAbilities:OnPlayerDied()
    -- Remove all abilities on death
    self:ClearAllEffects()
    
    -- Notify player
    HelperFunctions.CreateNotification(self.player, "You died! All abilities removed.", 3)
end

-- Apply all abilities for the player
function PlayerAbilities:ApplyAllAbilities()
    local success, playerData = pcall(function()
        return require(script.Parent.PlayerData).GetPlayerData(self.player)
    end)
    
    if not success or not playerData then return end
    
    local abilities = playerData:GetAllAbilities()
    
    for abilityName, level in pairs(abilities) do
        if level > 0 then
            self:ApplyAbility(abilityName, level)
        end
    end
end

-- Apply a specific ability
function PlayerAbilities:ApplyAbility(abilityName, level)
    if not self.character or not self.humanoid then return end
    
    -- Clear existing effect if any
    self:ClearEffect(abilityName)
    
    local effect = self:CreateAbilityEffect(abilityName, level)
    if effect then
        activeEffects[self.userId][abilityName] = effect
    end
end

-- Create ability effect
function PlayerAbilities:CreateAbilityEffect(abilityName, level)
    if abilityName == Constants.ABILITIES.DOUBLE_JUMP then
        return self:CreateDoubleJumpEffect(level)
    elseif abilityName == Constants.ABILITIES.SPEED_BOOST then
        return self:CreateSpeedBoostEffect(level)
    elseif abilityName == Constants.ABILITIES.JUMP_BOOST then
        return self:CreateJumpBoostEffect(level)
    elseif abilityName == Constants.ABILITIES.CASH_MULTIPLIER then
        return self:CreateCashMultiplierEffect(level)
    elseif abilityName == Constants.ABILITIES.WALL_REPAIR then
        return self:CreateWallRepairEffect(level)
    elseif abilityName == Constants.ABILITIES.TELEPORT then
        return self:CreateTeleportEffect(level)
    end
    
    return nil
end

-- Create double jump effect
function PlayerAbilities:CreateDoubleJumpEffect(level)
    local effect = {}
    local canDoubleJump = false
    local hasDoubleJumped = false
    local inputConnection = nil
    local touchingConnection = nil
    
    -- Reset double jump when touching ground
    local function onTouchingChanged()
        if self.humanoid and self.humanoid.FloorMaterial ~= Enum.Material.Air then
            hasDoubleJumped = false
            canDoubleJump = true
        else
            canDoubleJump = false
        end
    end
    
    -- Handle input for double jump
    local function onInputBegan(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.Space and not hasDoubleJumped and canDoubleJump then
            if self.humanoid and self.humanoid.Jump then
                self.humanoid.Jump = true
                hasDoubleJumped = true
                
                -- Apply double jump power
                local jumpPower = Constants.PLAYER.DOUBLE_JUMP_POWER + (level * 5)
                self.humanoid.JumpPower = jumpPower
                
                -- Reset jump power after a short delay
                game:GetService("Debris"):AddItem(function()
                    if self.humanoid then
                        self.humanoid.JumpPower = Constants.PLAYER.JUMP_POWER
                    end
                end, 0.1)
            end
        end
    end
    
    -- Connect events
    if self.humanoidRootPart then
        touchingConnection = self.humanoidRootPart.Touching:Connect(onTouchingChanged)
    end
    
    inputConnection = UserInputService.InputBegan:Connect(onInputBegan)
    
    -- Store cleanup function
    effect.Cleanup = function()
        if touchingConnection then
            touchingConnection:Disconnect()
            touchingConnection = nil
        end
        if inputConnection then
            inputConnection:Disconnect()
            inputConnection = nil
        end
    end
    
    return effect
end

-- Create speed boost effect
function PlayerAbilities:CreateSpeedBoostEffect(level)
    local effect = {}
    local originalWalkSpeed = self.humanoid.WalkSpeed
    
    -- Apply speed boost
    local speedMultiplier = 1 + (level * 0.2) -- 20% increase per level
    self.humanoid.WalkSpeed = originalWalkSpeed * speedMultiplier
    
    -- Store cleanup function
    effect.Cleanup = function()
        if self.humanoid then
            self.humanoid.WalkSpeed = originalWalkSpeed
        end
    end
    
    return effect
end

-- Create jump boost effect
function PlayerAbilities:CreateJumpBoostEffect(level)
    local effect = {}
    local originalJumpPower = self.humanoid.JumpPower
    
    -- Apply jump boost
    local jumpMultiplier = 1 + (level * 0.15) -- 15% increase per level
    self.humanoid.JumpPower = originalJumpPower * jumpMultiplier
    
    -- Store cleanup function
    effect.Cleanup = function()
        if self.humanoid then
            self.humanoid.JumpPower = originalJumpPower
        end
    end
    
    return effect
end

-- Create cash multiplier effect (placeholder for now)
function PlayerAbilities:CreateCashMultiplierEffect(level)
    local effect = {}
    local multiplier = 1 + (level * 0.2) -- 1.2x at level 1, 3x at level 10
    local isActive = false
    
    -- Check if player is near their tycoon
    local function checkTycoonProximity()
        if not self.humanoidRootPart then return end
        
        local playerPos = self.humanoidRootPart.Position
        local success, playerData = pcall(function()
            return require(script.Parent.PlayerData).GetPlayerData(self.player)
        end)
        
        if not success or not playerData then return end
        
        local currentTycoonId = playerData:GetCurrentTycoon()
        if not currentTycoonId then return end
        
        -- Find tycoon in workspace (simplified - in real implementation you'd use a proper tycoon manager)
        local tycoonBase = workspace:FindFirstChild("BasePlate")
        if tycoonBase then
            local distance = (tycoonBase.Position - playerPos).Magnitude
            local isNearTycoon = distance <= 50 -- Within 50 studs of tycoon
            
            if isNearTycoon and not isActive then
                -- Activate multiplier
                isActive = true
                HelperFunctions.CreateNotification(self.player, "Cash multiplier activated! +" .. math.floor((multiplier - 1) * 100) .. "% cash", 3)
                
                -- Visual effect on player
                if self.character then
                    local highlight = Instance.new("Highlight")
                    highlight.FillColor = Color3.fromRGB(255, 215, 0) -- Gold
                    highlight.OutlineColor = Color3.fromRGB(255, 165, 0) -- Orange
                    highlight.Parent = self.character
                    
                    -- Store highlight for cleanup
                    effect.highlight = highlight
                end
            elseif not isNearTycoon and isActive then
                -- Deactivate multiplier
                isActive = false
                HelperFunctions.CreateNotification(self.player, "Cash multiplier deactivated", 2)
                
                -- Remove visual effect
                if effect.highlight then
                    effect.highlight:Destroy()
                    effect.highlight = nil
                end
            end
        end
    end
    
    -- Connect to RunService for proximity checking
    local connection = game:GetService("RunService").Heartbeat:Connect(checkTycoonProximity)
    
    -- Store cleanup function
    effect.Cleanup = function()
        if connection then
            connection:Disconnect()
            connection = nil
        end
        
        if effect.highlight then
            effect.highlight:Destroy()
            effect.highlight = nil
        end
    end
    
    -- Store multiplier info for external systems
    effect.GetMultiplier = function()
        return isActive and multiplier or 1
    end
    
    return effect
end

-- Create wall repair effect (placeholder for now)
function PlayerAbilities:CreateWallRepairEffect(level)
    local effect = {}
    local repairRadius = 20 + (level * 2) -- 22 at level 1, 40 at level 10
    local repairInterval = math.max(0.5, 2 - (level * 0.15)) -- 2s at level 1, 0.5s at level 10
    local lastRepairTime = 0
    
    -- Find and repair nearby walls
    local function repairNearbyWalls()
        local currentTime = tick()
        if currentTime - lastRepairTime < repairInterval then return end
        
        if not self.humanoidRootPart then return end
        
        local playerPos = self.humanoidRootPart.Position
        local walls = workspace:GetChildren()
        
        for _, wall in ipairs(walls) do
            if wall.Name:match("^Wall%d+$") and wall:IsA("Part") then
                local distance = (wall.Position - playerPos).Magnitude
                
                if distance <= repairRadius then
                    -- Check if wall needs repair
                    local wallData = wall:FindFirstChild("WallData")
                    if wallData and wallData.Value < 100 then -- Assuming wall HP is stored as a NumberValue
                        -- Repair the wall
                        wallData.Value = math.min(100, wallData.Value + (level * 5))
                        
                        -- Visual feedback
                        local originalColor = wall.Color
                        wall.Color = Color3.fromRGB(0, 255, 0) -- Green flash
                        
                        -- Reset color after a short delay
                        game:GetService("Debris"):AddItem(function()
                            if wall and wall.Parent then
                                wall.Color = originalColor
                            end
                        end, 0.3)
                    end
                end
            end
        end
        
        lastRepairTime = currentTime
    end
    
    -- Connect to RunService for continuous repair
    local connection = game:GetService("RunService").Heartbeat:Connect(repairNearbyWalls)
    
    -- Store cleanup function
    effect.Cleanup = function()
        if connection then
            connection:Disconnect()
            connection = nil
        end
    end
    
    return effect
end

-- Create teleport effect (placeholder for now)
function PlayerAbilities:CreateTeleportEffect(level)
    local effect = {}
    local teleportCooldown = 0
    local lastTeleportTime = 0
    
    -- Handle input for teleport
    local function onInputBegan(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.T then
            local currentTime = tick()
            if currentTime - lastTeleportTime >= teleportCooldown then
                -- Teleport to spawn
                if self.humanoidRootPart then
                    local spawnLocation = Vector3.new(0, 5, 0) -- Default spawn
                    self.humanoidRootPart.CFrame = CFrame.new(spawnLocation)
                    
                    -- Notify player
                    HelperFunctions.CreateNotification(self.player, "Teleported to spawn!", 2)
                    
                    -- Set cooldown based on level (higher level = shorter cooldown)
                    teleportCooldown = math.max(5, 15 - (level * 1)) -- 15s at level 1, 5s at level 10
                    lastTeleportTime = currentTime
                end
            else
                local remainingTime = math.ceil(teleportCooldown - (currentTime - lastTeleportTime))
                HelperFunctions.CreateNotification(self.player, "Teleport cooldown: " .. remainingTime .. "s", 2)
            end
        end
    end
    
    -- Connect input event
    local inputConnection = UserInputService.InputBegan:Connect(onInputBegan)
    
    -- Store cleanup function
    effect.Cleanup = function()
        if inputConnection then
            inputConnection:Disconnect()
            inputConnection = nil
        end
    end
    
    return effect
end

-- Clear a specific effect
function PlayerAbilities:ClearEffect(abilityName)
    local effects = activeEffects[self.userId]
    if effects and effects[abilityName] then
        if effects[abilityName].Cleanup then
            effects[abilityName].Cleanup()
        end
        effects[abilityName] = nil
    end
end

-- Clear all effects
function PlayerAbilities:ClearAllEffects()
    local effects = activeEffects[self.userId]
    if effects then
        for abilityName, effect in pairs(effects) do
            if effect.Cleanup then
                effect.Cleanup()
            end
        end
        activeEffects[self.userId] = {}
    end
end

-- Remove a specific ability
function PlayerAbilities:RemoveAbility(abilityName)
    self:ClearEffect(abilityName)
end

-- Get active effects
function PlayerAbilities:GetActiveEffects()
    return activeEffects[self.userId] or {}
end

-- Check if an ability is active
function PlayerAbilities:IsAbilityActive(abilityName)
    local effects = activeEffects[self.userId]
    return effects and effects[abilityName] ~= nil
end

-- Clean up when player leaves
function PlayerAbilities:Destroy()
    self:ClearAllEffects()
    
    if activeEffects[self.userId] then
        activeEffects[self.userId] = nil
    end
    
    self.player = nil
    self.character = nil
    self.humanoid = nil
    self.humanoidRootPart = nil
end

-- Clean up all player abilities (call when server shuts down)
function PlayerAbilities.CleanupAll()
    for userId, effects in pairs(activeEffects) do
        for abilityName, effect in pairs(effects) do
            if effect.Cleanup then
                effect.Cleanup()
            end
        end
    end
    activeEffects = {}
end

-- Auto-cleanup when players leave
Players.PlayerRemoving:Connect(function(player)
    local playerAbilities = PlayerAbilities.new(player)
    if playerAbilities then
        playerAbilities:Destroy()
    end
end)

return PlayerAbilities
