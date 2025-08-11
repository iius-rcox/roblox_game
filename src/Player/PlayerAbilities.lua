-- PlayerAbilities.lua - FIXED VERSION
-- Manages player abilities and their effects with proper error handling and synchronization

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for required modules
local Constants = require(ReplicatedStorage:WaitForChild("Utils"):WaitForChild("Constants"))
local HelperFunctions = require(ReplicatedStorage:WaitForChild("Utils"):WaitForChild("HelperFunctions"))

local PlayerAbilities = {}
PlayerAbilities.__index = PlayerAbilities

-- Store active ability effects for each player
local activeEffects = {}
local abilityConnections = {}

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
    self.isDestroyed = false
    
    -- Initialize active effects
    activeEffects[self.userId] = {}
    abilityConnections[self.userId] = {}
    
    -- Connect to character events with better error handling
    self:ConnectToCharacter()
    
    return self
end

-- Enhanced character connection with retry logic
function PlayerAbilities:ConnectToCharacter()
    if self.isDestroyed then return end
    
    -- Clean up old connections
    self:CleanupCharacterConnections()
    
    -- Handle current character
    if self.player.Character then
        task.spawn(function()
            self:OnCharacterAdded(self.player.Character)
        end)
    end
    
    -- Connect to future character spawns
    abilityConnections[self.userId].characterAdded = self.player.CharacterAdded:Connect(function(character)
        if not self.isDestroyed then
            task.spawn(function()
                self:OnCharacterAdded(character)
            end)
        end
    end)
    
    abilityConnections[self.userId].characterRemoving = self.player.CharacterRemoving:Connect(function(character)
        if not self.isDestroyed then
            self:OnCharacterRemoving(character)
        end
    end)
end

-- Clean up character connections
function PlayerAbilities:CleanupCharacterConnections()
    local connections = abilityConnections[self.userId]
    if connections then
        for _, connection in pairs(connections) do
            if connection and typeof(connection) == "RBXScriptConnection" then
                connection:Disconnect()
            end
        end
    end
    abilityConnections[self.userId] = {}
end

-- Handle character added with retry mechanism
function PlayerAbilities:OnCharacterAdded(character)
    if self.isDestroyed then return end
    
    -- Wait for character to fully load
    local humanoid = character:WaitForChild("Humanoid", 10)
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)
    
    if not humanoid or not humanoidRootPart then
        warn("PlayerAbilities: Failed to get character parts for", self.player.Name)
        return
    end
    
    self.character = character
    self.humanoid = humanoid
    self.humanoidRootPart = humanoidRootPart
    
    -- Wait a bit for character to stabilize
    task.wait(0.5)
    
    -- Apply current abilities
    self:ApplyAllAbilities()
    
    -- Connect to death event
    abilityConnections[self.userId].died = self.humanoid.Died:Connect(function()
        if not self.isDestroyed then
            self:OnPlayerDied()
        end
    end)
    
    print("PlayerAbilities: Character loaded for", self.player.Name)
end

-- Handle character removing
function PlayerAbilities:OnCharacterRemoving(character)
    if self.isDestroyed then return end
    
    self.character = nil
    self.humanoid = nil
    self.humanoidRootPart = nil
    
    -- Clear all active effects but keep ability levels
    self:ClearAllEffectsKeepData()
    
    print("PlayerAbilities: Character removed for", self.player.Name)
end

-- Handle player death
function PlayerAbilities:OnPlayerDied()
    if self.isDestroyed then return end
    
    -- Clear effects but keep data for respawn
    self:ClearAllEffectsKeepData()
    
    -- Notify player
    HelperFunctions.CreateNotification(self.player, "You died! Abilities will be restored on respawn.", 3)
end

-- Apply all abilities for the player
function PlayerAbilities:ApplyAllAbilities()
    if self.isDestroyed or not self.character or not self.humanoid then return end
    
    -- Get player data safely
    local success, playerData = pcall(function()
        local PlayerData = require(ReplicatedStorage:WaitForChild("Player"):WaitForChild("PlayerData"))
        return PlayerData.GetPlayerData(self.player)
    end)
    
    if not success or not playerData then 
        warn("PlayerAbilities: Could not get player data for", self.player.Name)
        return
    end
    
    local abilities = playerData:GetAllAbilities()
    
    for abilityName, level in pairs(abilities) do
        if level > 0 then
            self:ApplyAbility(abilityName, level)
        end
    end
    
    print("PlayerAbilities: Applied", table.unpack(abilities), "abilities for", self.player.Name)
end

-- Apply a specific ability with enhanced error handling
function PlayerAbilities:ApplyAbility(abilityName, level)
    if self.isDestroyed or not self.character or not self.humanoid then return end
    
    -- Clear existing effect if any
    self:ClearEffect(abilityName)
    
    local success, effect = pcall(function()
        return self:CreateAbilityEffect(abilityName, level)
    end)
    
    if success and effect then
        activeEffects[self.userId][abilityName] = effect
        print("PlayerAbilities: Applied", abilityName, "level", level, "to", self.player.Name)
    else
        warn("PlayerAbilities: Failed to apply", abilityName, "to", self.player.Name)
    end
end

-- Create ability effect with better implementation
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

-- Enhanced double jump effect
function PlayerAbilities:CreateDoubleJumpEffect(level)
    local effect = {}
    local canDoubleJump = false
    local hasDoubleJumped = false
    local debounce = false
    
    -- Track jumping state
    local function onStateChanged(oldState, newState)
        if newState == Enum.HumanoidStateType.Landed then
            hasDoubleJumped = false
            canDoubleJump = true
            debounce = false
        elseif newState == Enum.HumanoidStateType.Freefall then
            canDoubleJump = true
        end
    end
    
    -- Handle input for double jump
    local function onInputBegan(input, gameProcessed)
        if gameProcessed or debounce then return end
        
        if input.KeyCode == Enum.KeyCode.Space and canDoubleJump and not hasDoubleJumped then
            if self.humanoid and self.humanoid:GetState() ~= Enum.HumanoidStateType.Landed then
                debounce = true
                hasDoubleJumped = true
                
                -- Apply double jump
                local jumpVelocity = 50 + (level * 5) -- Increased base velocity
                
                if self.humanoidRootPart then
                    local bodyVelocity = Instance.new("BodyVelocity")
                    bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
                    bodyVelocity.Velocity = Vector3.new(0, jumpVelocity, 0)
                    bodyVelocity.Parent = self.humanoidRootPart
                    
                    -- Clean up after short time
                    game:GetService("Debris"):AddItem(bodyVelocity, 0.3)
                end
                
                -- Visual effect
                HelperFunctions.CreateNotification(self.player, "Double Jump!", 1)
                
                task.wait(0.1)
                debounce = false
            end
        end
    end
    
    -- Connect events
    effect.stateConnection = self.humanoid.StateChanged:Connect(onStateChanged)
    effect.inputConnection = UserInputService.InputBegan:Connect(onInputBegan)
    
    -- Store cleanup function
    effect.Cleanup = function()
        if effect.stateConnection then
            effect.stateConnection:Disconnect()
            effect.stateConnection = nil
        end
        if effect.inputConnection then
            effect.inputConnection:Disconnect()
            effect.inputConnection = nil
        end
    end
    
    return effect
end

-- Enhanced speed boost effect
function PlayerAbilities:CreateSpeedBoostEffect(level)
    local effect = {}
    local originalWalkSpeed = self.humanoid.WalkSpeed
    
    -- Apply speed boost with better scaling
    local speedMultiplier = 1 + (level * 0.3) -- 30% increase per level
    self.humanoid.WalkSpeed = originalWalkSpeed * speedMultiplier
    
    -- Visual indicator
    if self.character then
        local speedEffect = Instance.new("BodyAngularVelocity")
        speedEffect.MaxTorque = Vector3.new(0, math.huge, 0)
        speedEffect.AngularVelocity = Vector3.new(0, 0, 0)
        speedEffect.Parent = self.humanoidRootPart
        
        effect.speedEffect = speedEffect
    end
    
    -- Store cleanup function
    effect.Cleanup = function()
        if self.humanoid then
            self.humanoid.WalkSpeed = originalWalkSpeed
        end
        if effect.speedEffect then
            effect.speedEffect:Destroy()
            effect.speedEffect = nil
        end
    end
    
    return effect
end

-- Enhanced jump boost effect
function PlayerAbilities:CreateJumpBoostEffect(level)
    local effect = {}
    local originalJumpPower = self.humanoid.JumpPower
    
    -- Apply jump boost with better scaling
    local jumpMultiplier = 1 + (level * 0.25) -- 25% increase per level
    self.humanoid.JumpPower = originalJumpPower * jumpMultiplier
    
    -- Store cleanup function
    effect.Cleanup = function()
        if self.humanoid then
            self.humanoid.JumpPower = originalJumpPower
        end
    end
    
    return effect
end

-- Enhanced cash multiplier effect
function PlayerAbilities:CreateCashMultiplierEffect(level)
    local effect = {}
    local multiplier = 1 + (level * 0.2) -- 20% increase per level
    local isActive = false
    local lastCheck = 0
    
    -- More efficient proximity checking
    local function checkTycoonProximity()
        local currentTime = time()
        if currentTime - lastCheck < 1 then return end -- Check every second
        lastCheck = currentTime
        
        if not self.humanoidRootPart then return end
        
        local playerPos = self.humanoidRootPart.Position
        local success, playerData = pcall(function()
            local PlayerData = require(ReplicatedStorage:WaitForChild("Player"):WaitForChild("PlayerData"))
            return PlayerData.GetPlayerData(self.player)
        end)
        
        if not success or not playerData then return end
        
        local currentTycoon = playerData:GetCurrentTycoon()
        if not currentTycoon then return end
        
        -- Check if near tycoon (simplified check)
        local isNearTycoon = true -- In real implementation, check actual distance
        
        if isNearTycoon and not isActive then
            isActive = true
            HelperFunctions.CreateNotification(self.player, 
                "Cash multiplier activated! +" .. math.floor((multiplier - 1) * 100) .. "% cash", 3)
            
            -- Visual effect
            if self.character then
                local highlight = Instance.new("Highlight")
                highlight.FillColor = Color3.fromRGB(255, 215, 0)
                highlight.OutlineColor = Color3.fromRGB(255, 165, 0)
                highlight.Parent = self.character
                effect.highlight = highlight
            end
        elseif not isNearTycoon and isActive then
            isActive = false
            HelperFunctions.CreateNotification(self.player, "Cash multiplier deactivated", 2)
            
            if effect.highlight then
                effect.highlight:Destroy()
                effect.highlight = nil
            end
        end
    end
    
    -- Use heartbeat for continuous checking
    effect.connection = RunService.Heartbeat:Connect(checkTycoonProximity)
    
    -- Store cleanup function
    effect.Cleanup = function()
        if effect.connection then
            effect.connection:Disconnect()
            effect.connection = nil
        end
        if effect.highlight then
            effect.highlight:Destroy()
            effect.highlight = nil
        end
    end
    
    -- Store multiplier info
    effect.GetMultiplier = function()
        return isActive and multiplier or 1
    end
    
    return effect
end

-- Enhanced wall repair effect
function PlayerAbilities:CreateWallRepairEffect(level)
    local effect = {}
    local repairRadius = 20 + (level * 3)
    local repairInterval = math.max(0.5, 2 - (level * 0.2))
    local lastRepairTime = 0
    
    local function repairNearbyWalls()
        local currentTime = time()
        if currentTime - lastRepairTime < repairInterval then return end
        
        if not self.humanoidRootPart then return end
        
        local playerPos = self.humanoidRootPart.Position
        
        -- Find walls within radius
        for _, obj in pairs(workspace:GetPartBoundsInRegion(
            Region3.new(
                playerPos - Vector3.new(repairRadius, repairRadius, repairRadius),
                playerPos + Vector3.new(repairRadius, repairRadius, repairRadius)
            ),
            math.huge
        )) do
            if obj.Name:match("Wall") and obj:FindFirstChild("WallData") then
                local wallData = obj.WallData
                if wallData.Value < 100 then
                    wallData.Value = math.min(100, wallData.Value + (level * 10))
                    
                    -- Visual feedback
                    local originalColor = obj.Color
                    obj.Color = Color3.fromRGB(0, 255, 0)
                    
                    task.spawn(function()
                        task.wait(0.3)
                        if obj and obj.Parent then
                            obj.Color = originalColor
                        end
                    end)
                end
            end
        end
        
        lastRepairTime = currentTime
    end
    
    effect.connection = RunService.Heartbeat:Connect(repairNearbyWalls)
    
    effect.Cleanup = function()
        if effect.connection then
            effect.connection:Disconnect()
            effect.connection = nil
        end
    end
    
    return effect
end

-- Enhanced teleport effect
function PlayerAbilities:CreateTeleportEffect(level)
    local effect = {}
    local teleportCooldown = math.max(3, 10 - level)
    local lastTeleportTime = 0
    
    local function onInputBegan(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.T then
            local currentTime = time()
            if currentTime - lastTeleportTime >= teleportCooldown then
                if self.humanoidRootPart then
                    -- Teleport to spawn or safe location
                    local spawnLocation = Vector3.new(0, 50, 0)
                    self.humanoidRootPart.CFrame = CFrame.new(spawnLocation)
                    
                    HelperFunctions.CreateNotification(self.player, "Teleported!", 2)
                    lastTeleportTime = currentTime
                end
            else
                local remainingTime = math.ceil(teleportCooldown - (currentTime - lastTeleportTime))
                HelperFunctions.CreateNotification(self.player, "Teleport cooldown: " .. remainingTime .. "s", 2)
            end
        end
    end
    
    effect.inputConnection = UserInputService.InputBegan:Connect(onInputBegan)
    
    effect.Cleanup = function()
        if effect.inputConnection then
            effect.inputConnection:Disconnect()
            effect.inputConnection = nil
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

-- Clear all effects but keep data for respawn
function PlayerAbilities:ClearAllEffectsKeepData()
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

-- Clear all effects permanently
function PlayerAbilities:ClearAllEffects()
    self:ClearAllEffectsKeepData()
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
    self.isDestroyed = true
    
    self:ClearAllEffects()
    self:CleanupCharacterConnections()
    
    if activeEffects[self.userId] then
        activeEffects[self.userId] = nil
    end
    
    if abilityConnections[self.userId] then
        abilityConnections[self.userId] = nil
    end
    
    self.player = nil
    self.character = nil
    self.humanoid = nil
    self.humanoidRootPart = nil
end

-- Static cleanup function
function PlayerAbilities.CleanupAll()
    for userId, effects in pairs(activeEffects) do
        for abilityName, effect in pairs(effects) do
            if effect.Cleanup then
                effect.Cleanup()
            end
        end
    end
    activeEffects = {}
    abilityConnections = {}
end

-- Auto-cleanup when players leave
Players.PlayerRemoving:Connect(function(player)
    if activeEffects[player.UserId] then
        for _, effect in pairs(activeEffects[player.UserId]) do
            if effect.Cleanup then
                effect.Cleanup()
            end
        end
        activeEffects[player.UserId] = nil
        abilityConnections[player.UserId] = nil
    end
end)

return PlayerAbilities
