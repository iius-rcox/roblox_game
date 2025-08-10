-- PlayerController.lua
-- Manages player spawning, movement, and basic player management

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local Constants = require(script.Parent.Parent.Utils.Constants)
local HelperFunctions = require(script.Parent.Parent.Utils.HelperFunctions)
local PlayerData = require(script.Parent.PlayerData)
local PlayerAbilities = require(script.Parent.PlayerAbilities)

local PlayerController = {}
PlayerController.__index = PlayerController

-- Store player controllers
local playerControllers = {}

-- Create new player controller
function PlayerController.new(player)
    if not HelperFunctions.IsValidPlayer(player) then
        warn("Invalid player provided to PlayerController.new")
        return nil
    end
    
    local self = setmetatable({}, PlayerController)
    self.player = player
    self.userId = player.UserId
    self.character = nil
    self.humanoid = nil
    self.humanoidRootPart = nil
    self.playerData = nil
    self.playerAbilities = nil
    self.spawnLocation = Vector3.new(0, 5, 0) -- Default spawn location
    
    -- Initialize player data and abilities
    self.playerData = PlayerData.new(player)
    self.playerAbilities = PlayerAbilities.new(player)
    
    -- Store in global store
    playerControllers[self.userId] = self
    
    -- Connect to player events
    self:ConnectToPlayer()
    
    return self
end

-- Get player controller by player or userId
function PlayerController.GetPlayerController(playerOrUserId)
    local userId = type(playerOrUserId) == "number" and playerOrUserId or playerOrUserId.UserId
    return playerControllers[userId]
end

-- Connect to player events
function PlayerController:ConnectToPlayer()
    -- Handle character spawning
    if self.player.Character then
        self:OnCharacterAdded(self.player.Character)
    end
    
    self.player.CharacterAdded:Connect(function(character)
        self:OnCharacterAdded(character)
    end)
    
    self.player.CharacterRemoving:Connect(function(character)
        self:OnCharacterRemoving(character)
    end)
    
    -- Handle player leaving
    self.player.AncestryChanged:Connect(function(_, parent)
        if not parent then
            self:Destroy()
        end
    end)
end

-- Handle character added
function PlayerController:OnCharacterAdded(character)
    self.character = character
    self.humanoid = character:WaitForChild("Humanoid")
    self.humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    -- Set up character properties
    self:SetupCharacter()
    
    -- Connect to character events
    self:ConnectToCharacter()
    
    -- Apply player data
    self:ApplyPlayerData()
end

-- Handle character removing
function PlayerController:OnCharacterRemoving(character)
    self.character = nil
    self.humanoid = nil
    self.humanoidRootPart = nil
end

-- Set up character properties
function PlayerController:SetupCharacter()
    if not self.humanoid then return end
    
    -- Set basic properties
    self.humanoid.WalkSpeed = Constants.PLAYER.WALK_SPEED
    self.humanoid.JumpPower = Constants.PLAYER.JUMP_POWER
    self.humanoid.MaxHealth = Constants.PLAYER.MAX_HEALTH
    self.humanoid.Health = Constants.PLAYER.MAX_HEALTH
    
    -- Set spawn location
    if self.humanoidRootPart then
        self.humanoidRootPart.CFrame = CFrame.new(self.spawnLocation)
    end
end

-- Connect to character events
function PlayerController:ConnectToCharacter()
    if not self.humanoid then return end
    
    -- Handle death
    self.humanoid.Died:Connect(function()
        self:OnPlayerDied()
    end)
    
    -- Handle health change
    self.humanoid.HealthChanged:Connect(function(health)
        self:OnHealthChanged(health)
    end)
    
    -- Handle falling
    self.humanoid.StateChanged:Connect(function(oldState, newState)
        if newState == Enum.HumanoidStateType.Freefall then
            self:OnPlayerFalling()
        end
    end)
end

-- Apply player data to character
function PlayerController:ApplyPlayerData()
    if not self.playerData then return end
    
    -- Apply abilities (this will be handled by PlayerAbilities)
    -- The abilities are automatically applied when the character is ready
    
    -- Set spawn location based on current tycoon
    local currentTycoon = self.playerData:GetCurrentTycoon()
    if currentTycoon then
        -- Get tycoon spawn location from the tycoon system
        local spawnLocation = self:GetTycoonSpawnLocation(currentTycoon)
        if spawnLocation then
            self:SetSpawnLocation(spawnLocation)
            print("PlayerController: Set spawn location for tycoon", currentTycoon, "to", spawnLocation)
        else
            -- Fallback to default spawn location
            local defaultSpawn = Constants.PLAYER.DEFAULT_SPAWN or Vector3.new(0, 5, 0)
            self:SetSpawnLocation(defaultSpawn)
            print("PlayerController: Using default spawn location", defaultSpawn)
        end
    else
        -- No current tycoon, use default spawn
        local defaultSpawn = Constants.PLAYER.DEFAULT_SPAWN or Vector3.new(0, 5, 0)
        self:SetSpawnLocation(defaultSpawn)
        print("PlayerController: No tycoon, using default spawn location", defaultSpawn)
    end
end

-- Handle player death
function PlayerController:OnPlayerDied()
    -- Notify player
    HelperFunctions.CreateNotification(self.player, "You died! Respawning in " .. Constants.PLAYER.RESPAWN_TIME .. " seconds...", 3)
    
    -- Schedule respawn
    game:GetService("Debris"):AddItem(function()
        self:RespawnPlayer()
    end, Constants.PLAYER.RESPAWN_TIME)
end

-- Handle health change
function PlayerController:OnHealthChanged(health)
    -- You can add health-related effects here
    -- For example, visual effects when health is low
end

-- Handle player falling
function PlayerController:OnPlayerFalling()
    -- You can add falling-related effects here
    -- For example, checking if player fell out of bounds
end

-- Respawn player
function PlayerController:RespawnPlayer()
    if not self.player then return end
    
    -- Load character
    self.player:LoadCharacter()
    
    -- Reset abilities (they will be reapplied when character loads)
    if self.playerAbilities then
        self.playerAbilities:ClearAllEffects()
    end
end

-- Set spawn location
function PlayerController:SetSpawnLocation(location)
    if type(location) == "Vector3" then
        self.spawnLocation = location
        
        -- Update current character if it exists
        if self.humanoidRootPart then
            self.humanoidRootPart.CFrame = CFrame.new(location)
        end
    end
end

-- Get spawn location
function PlayerController:GetSpawnLocation()
    return self.spawnLocation
end

-- Teleport player to location
function PlayerController:TeleportTo(location)
    if not self.humanoidRootPart or type(location) ~= "Vector3" then
        return false
    end
    
    self.humanoidRootPart.CFrame = CFrame.new(location)
    return true
end

-- Check if player is alive
function PlayerController:IsAlive()
    return self.humanoid and self.humanoid.Health > 0
end

-- Get player health
function PlayerController:GetHealth()
    return self.humanoid and self.humanoid.Health or 0
end

-- Get player max health
function PlayerController:GetMaxHealth()
    return self.humanoid and self.humanoid.MaxHealth or Constants.PLAYER.MAX_HEALTH
end

-- Set player health
function PlayerController:SetHealth(health)
    if self.humanoid and type(health) == "number" then
        health = math.max(0, math.min(health, self:GetMaxHealth()))
        self.humanoid.Health = health
        return true
    end
    return false
end

-- Heal player
function PlayerController:Heal(amount)
    if type(amount) == "number" and amount > 0 then
        local currentHealth = self:GetHealth()
        local maxHealth = self:GetMaxHealth()
        local newHealth = math.min(currentHealth + amount, maxHealth)
        return self:SetHealth(newHealth)
    end
    return false
end

-- Damage player
function PlayerController:Damage(amount)
    if type(amount) == "number" and amount > 0 then
        local currentHealth = self:GetHealth()
        local newHealth = math.max(currentHealth - amount, 0)
        return self:SetHealth(newHealth)
    end
    return false
end

-- Get player data
function PlayerController:GetPlayerData()
    return self.playerData
end

-- Get player abilities
function PlayerController:GetPlayerAbilities()
    return self.playerAbilities
end

-- Clean up when player leaves
function PlayerController:Destroy()
    if self.playerAbilities then
        self.playerAbilities:Destroy()
    end
    
    if self.playerData then
        self.playerData:Destroy()
    end
    
    if playerControllers[self.userId] then
        playerControllers[self.userId] = nil
    end
    
    self.player = nil
    self.character = nil
    self.humanoid = nil
    self.humanoidRootPart = nil
    self.playerData = nil
    self.playerAbilities = nil
end

-- Clean up all player controllers (call when server shuts down)
function PlayerController.CleanupAll()
    for userId, controller in pairs(playerControllers) do
        if controller.Destroy then
            controller:Destroy()
        end
    end
    playerControllers = {}
end

-- Auto-cleanup when players leave
Players.PlayerRemoving:Connect(function(player)
    local controller = PlayerController.GetPlayerController(player)
    if controller then
        controller:Destroy()
    end
end)

-- Auto-create controllers for new players
Players.PlayerAdded:Connect(function(player)
    PlayerController.new(player)
end)

-- Get tycoon spawn location
function PlayerController:GetTycoonSpawnLocation(tycoonId)
    if not tycoonId then
        return nil
    end
    
    -- Try to get spawn location from the tycoon system
    -- This would integrate with your existing tycoon system
    local success, spawnLocation = pcall(function()
        -- Example integration - replace with your actual tycoon system
        if game:GetService("Workspace"):FindFirstChild("Tycoons") then
            local tycoonFolder = game.Workspace.Tycoons:FindFirstChild(tycoonId)
            if tycoonFolder then
                local spawnPart = tycoonFolder:FindFirstChild("SpawnPart")
                if spawnPart and spawnPart:IsA("BasePart") then
                    return spawnPart.Position + Vector3.new(0, 3, 0) -- Offset above spawn part
                end
            end
        end
        return nil
    end)
    
    if success and spawnLocation then
        return spawnLocation
    end
    
    -- Fallback: try to find any spawn location in the tycoon area
    local fallbackLocation = self:FindFallbackSpawnLocation(tycoonId)
    if fallbackLocation then
        return fallbackLocation
    end
    
    return nil
end

-- Find fallback spawn location for tycoon
function PlayerController:FindFallbackSpawnLocation(tycoonId)
    if not tycoonId then
        return nil
    end
    
    local success, fallbackLocation = pcall(function()
        -- Look for any suitable spawn location in the tycoon area
        if game:GetService("Workspace"):FindFirstChild("Tycoons") then
            local tycoonFolder = game.Workspace.Tycoons:FindFirstChild(tycoonId)
            if tycoonFolder then
                -- Look for spawn-related parts
                for _, part in pairs(tycoonFolder:GetChildren()) do
                    if part:IsA("BasePart") then
                        local partName = part.Name:lower()
                        if partName:find("spawn") or partName:find("start") or partName:find("entrance") then
                            return part.Position + Vector3.new(0, 3, 0)
                        end
                    end
                end
                
                -- If no spawn parts found, use the tycoon folder position
                if tycoonFolder:IsA("BasePart") then
                    return tycoonFolder.Position + Vector3.new(0, 5, 0)
                end
            end
        end
        return nil
    end)
    
    return success and fallbackLocation or nil
end

return PlayerController
