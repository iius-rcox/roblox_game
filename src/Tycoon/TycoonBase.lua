-- TycoonBase.lua
-- Main tycoon structure with 3 floors, walls, owner door, and components

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Constants = require(script.Parent.Parent.Utils.Constants)
local HelperFunctions = require(script.Parent.Parent.Utils.HelperFunctions)
local CashGenerator = require(script.Parent.CashGenerator)
local AbilityButton = require(script.Parent.AbilityButton)

local TycoonBase = {}
TycoonBase.__index = TycoonBase

-- Create new tycoon base
function TycoonBase.new(tycoonId, position, owner)
    local self = setmetatable({}, TycoonBase)
    self.tycoonId = tycoonId
    self.position = position or Vector3.new(0, 0, 0)
    self.owner = owner
    self.isActive = false
    self.level = 1
    self.cashGenerated = 0
    
    -- Components
    self.cashGenerator = nil
    self.abilityButtons = {}
    self.walls = {}
    self.floors = {}
    self.ownerDoor = nil
    
    -- Create the tycoon structure
    self:CreateStructure()
    
    -- Create components
    self:CreateComponents()
    
    -- Set up wall HP system
    self:SetupWallSystem()
    
    -- Position everything
    self:PositionComponents()
    
    return self
end

-- Create the basic tycoon structure
function TycoonBase:CreateStructure()
    -- Create base plate
    local basePlate = Instance.new("Part")
    basePlate.Name = "BasePlate"
    basePlate.Size = Vector3.new(50, 1, 50)
    basePlate.Position = self.position + Vector3.new(0, -0.5, 0)
    basePlate.Anchored = true
    basePlate.Material = Enum.Material.Concrete
    basePlate.Color = Color3.fromRGB(128, 128, 128)
    basePlate.Parent = workspace
    
    -- Create floors
    for floor = 1, Constants.TYCOON.MAX_FLOORS do
        local floorPart = Instance.new("Part")
        floorPart.Name = "Floor" .. floor
        floorPart.Size = Vector3.new(40, 1, 40)
        floorPart.Position = self.position + Vector3.new(0, (floor - 1) * 10, 0)
        floorPart.Anchored = true
        floorPart.Material = Enum.Material.Wood
        floorPart.Color = Color3.fromRGB(139, 69, 19)
        floorPart.Parent = workspace
        
        table.insert(self.floors, floorPart)
    end
    
    -- Create walls
    self:CreateWalls()
    
    -- Create owner door
    self:CreateOwnerDoor()
end

-- Create walls for the tycoon
function TycoonBase:CreateWalls()
    local wallHeight = 8
    local wallThickness = 1
    local wallLength = 40
    
    -- Wall positions for each floor
    local wallPositions = {
        -- Floor 1 walls
        {Vector3.new(-20, 4, 0), Vector3.new(wallThickness, wallHeight, wallLength)}, -- Left
        {Vector3.new(20, 4, 0), Vector3.new(wallThickness, wallHeight, wallLength)}, -- Right
        {Vector3.new(0, 4, -20), Vector3.new(wallLength, wallHeight, wallThickness)}, -- Back
        {Vector3.new(0, 4, 20), Vector3.new(wallLength, wallHeight, wallThickness)}, -- Front (with door)
        
        -- Floor 2 walls
        {Vector3.new(-20, 14, 0), Vector3.new(wallThickness, wallHeight, wallLength)}, -- Left
        {Vector3.new(20, 14, 0), Vector3.new(wallThickness, wallHeight, wallLength)}, -- Right
        {Vector3.new(0, 14, -20), Vector3.new(wallLength, wallHeight, wallThickness)}, -- Back
        {Vector3.new(0, 14, 20), Vector3.new(wallLength, wallHeight, wallThickness)}, -- Front
        
        -- Floor 3 walls
        {Vector3.new(-20, 24, 0), Vector3.new(wallThickness, wallHeight, wallLength)}, -- Left
        {Vector3.new(20, 24, 0), Vector3.new(wallThickness, wallHeight, wallLength)}, -- Right
        {Vector3.new(0, 24, -20), Vector3.new(wallLength, wallHeight, wallThickness)}, -- Back
        {Vector3.new(0, 24, 20), Vector3.new(wallLength, wallHeight, wallThickness)} -- Front
    }
    
    for i, wallData in ipairs(wallPositions) do
        local wall = Instance.new("Part")
        wall.Name = "Wall" .. i
        wall.Size = wallData[2]
        wall.Position = self.position + wallData[1]
        wall.Anchored = true
        wall.Material = Enum.Material.Brick
        wall.Color = Color3.fromRGB(165, 42, 42)
        wall.Parent = workspace
        
        -- Add wall data
        local wallInfo = {
            part = wall,
            maxHP = Constants.TYCOON.WALL_HP,
            currentHP = Constants.TYCOON.WALL_HP,
            isDestroyed = false,
            repairTimer = 0
        }
        
        table.insert(self.walls, wallInfo)
    end
end

-- Create owner door
function TycoonBase:CreateOwnerDoor()
    local door = Instance.new("Part")
    door.Name = "OwnerDoor"
    door.Size = Vector3.new(6, 8, 1)
    door.Position = self.position + Vector3.new(0, 4, 20)
    door.Anchored = true
    door.Material = Enum.Material.Metal
    door.Color = Color3.fromRGB(192, 192, 192)
    door.Parent = workspace
    
    -- Add click detector for door interaction
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.Parent = door
    
    -- Handle door clicks
    clickDetector.MouseClick:Connect(function(player)
        self:OnDoorClicked(player)
    end)
    
    self.ownerDoor = door
end

-- Create tycoon components
function TycoonBase:CreateComponents()
    -- Create cash generator
    self.cashGenerator = CashGenerator.new(self.tycoonId, self.owner)
    
    -- Create ability buttons
    for i = 1, Constants.TYCOON.MAX_ABILITY_BUTTONS do
        local abilityButton = AbilityButton.new(i, self.tycoonId, self.owner)
        if abilityButton then
            table.insert(self.abilityButtons, abilityButton)
        end
    end
end

-- Set up wall HP system
function TycoonBase:SetupWallSystem()
    -- Connect to RunService for wall repair
    self.wallConnection = RunService.Heartbeat:Connect(function()
        self:UpdateWalls()
    end)
end

-- Update walls (repair, damage, etc.)
function TycoonBase:UpdateWalls()
    local currentTime = tick()
    
    for _, wall in ipairs(self.walls) do
        if wall.isDestroyed then
            -- Auto-repair walls over time
            wall.repairTimer = wall.repairTimer + RunService.Heartbeat:Wait()
            
            if wall.repairTimer >= 1 then -- Repair every second
                wall.repairTimer = 0
                self:RepairWall(wall)
            end
        end
    end
end

-- Repair a wall
function TycoonBase:RepairWall(wall)
    if not wall.isDestroyed then return end
    
    wall.currentHP = math.min(wall.currentHP + Constants.TYCOON.WALL_REPAIR_RATE, wall.maxHP)
    
    -- Update wall appearance
    local alpha = wall.currentHP / wall.maxHP
    wall.part.Transparency = 1 - alpha
    
    -- Check if fully repaired
    if wall.currentHP >= wall.maxHP then
        wall.isDestroyed = false
        wall.part.Transparency = 0
        wall.part.CanCollide = true
        wall.part.Color = Color3.fromRGB(165, 42, 42) -- Reset to original color
    end
end

-- Damage a wall
function TycoonBase:DamageWall(wall, damage)
    if wall.isDestroyed then return end
    
    wall.currentHP = math.max(0, wall.currentHP - damage)
    
    -- Update wall appearance based on damage
    local alpha = wall.currentHP / wall.maxHP
    wall.part.Transparency = 1 - alpha
    
    -- Change color based on damage level
    if wall.currentHP < wall.maxHP * 0.5 then
        wall.part.Color = Color3.fromRGB(255, 0, 0) -- Red when heavily damaged
    elseif wall.currentHP < wall.maxHP * 0.8 then
        wall.part.Color = Color3.fromRGB(255, 165, 0) -- Orange when moderately damaged
    end
    
    -- Check if destroyed
    if wall.currentHP <= 0 then
        wall.isDestroyed = true
        wall.part.Transparency = 0.8
        wall.part.CanCollide = false
        wall.part.Color = Color3.fromRGB(128, 128, 128) -- Gray when destroyed
    end
end

-- Position all components
function TycoonBase:PositionComponents()
    -- Position cash generator on first floor
    if self.cashGenerator then
        -- The cash generator doesn't have a visual part, so we just need to ensure it's active
    end
    
    -- Position ability buttons around the first floor
    local buttonRadius = 15
    local buttonsPerSide = 3
    
    for i, button in ipairs(self.abilityButtons) do
        local angle = (i - 1) * (2 * math.pi / Constants.TYCOON.MAX_ABILITY_BUTTONS)
        local x = math.cos(angle) * buttonRadius
        local z = math.sin(angle) * buttonRadius
        
        local buttonPosition = self.position + Vector3.new(x, 1, z)
        button:SetPosition(buttonPosition)
    end
end

-- Handle door clicks
function TycoonBase:OnDoorClicked(player)
    if not HelperFunctions.IsValidPlayer(player) then return end
    
    if self.owner then
        if player.UserId == self.owner.UserId then
            -- Owner clicked door - could open/close or show stats
            HelperFunctions.CreateNotification(player, "Welcome to your tycoon!", 3)
        else
            -- Non-owner clicked door
            HelperFunctions.CreateNotification(player, "This tycoon belongs to " .. self.owner.Name, 3)
        end
    else
        -- No owner - could allow claiming
        HelperFunctions.CreateNotification(player, "This tycoon is unclaimed!", 3)
    end
end

-- Set tycoon owner
function TycoonBase:SetOwner(owner)
    self.owner = owner
    
    -- Update cash generator owner
    if self.cashGenerator then
        self.cashGenerator:SetOwner(owner)
    end
    
    -- Update ability button owners
    for _, button in ipairs(self.abilityButtons) do
        button:SetOwner(owner)
    end
    
    -- Update door appearance
    if self.ownerDoor then
        if owner then
            self.ownerDoor.Color = Color3.fromRGB(0, 255, 0) -- Green for owned
        else
            self.ownerDoor.Color = Color3.fromRGB(192, 192, 192) -- Gray for unowned
        end
    end
end

-- Get tycoon owner
function TycoonBase:GetOwner()
    return self.owner
end

-- Check if player owns this tycoon
function TycoonBase:DoesPlayerOwn(player)
    if not self.owner or not HelperFunctions.IsValidPlayer(player) then
        return false
    end
    return self.owner.UserId == player.UserId
end

-- Activate tycoon
function TycoonBase:Activate()
    if self.isActive then return end
    
    self.isActive = true
    
    -- Activate cash generator
    if self.cashGenerator then
        self.cashGenerator:Start()
    end
    
    -- Activate ability buttons
    for _, button in ipairs(self.abilityButtons) do
        button:Activate()
    end
end

-- Deactivate tycoon
function TycoonBase:Deactivate()
    if not self.isActive then return end
    
    self.isActive = false
    
    -- Stop cash generator
    if self.cashGenerator then
        self.cashGenerator:Stop()
    end
    
    -- Deactivate ability buttons
    for _, button in ipairs(self.abilityButtons) do
        button:Deactivate()
    end
end

-- Get tycoon level
function TycoonBase:GetLevel()
    return self.level
end

-- Set tycoon level
function TycoonBase:SetLevel(level)
    if type(level) == "number" and level > 0 then
        self.level = level
        return true
    end
    return false
end

-- Get cash generated
function TycoonBase:GetCashGenerated()
    return self.cashGenerated
end

-- Add cash generated
function TycoonBase:AddCashGenerated(amount)
    if type(amount) == "number" and amount > 0 then
        self.cashGenerated = self.cashGenerated + amount
        return true
    end
    return false
end

-- Get all walls
function TycoonBase:GetWalls()
    return table.clone(self.walls)
end

-- Get wall by index
function TycoonBase:GetWall(index)
    if type(index) == "number" and index >= 1 and index <= #self.walls then
        return self.walls[index]
    end
    return nil
end

-- Get all ability buttons
function TycoonBase:GetAbilityButtons()
    return table.clone(self.abilityButtons)
end

-- Get ability button by number
function TycoonBase:GetAbilityButton(buttonNumber)
    for _, button in ipairs(self.abilityButtons) do
        if button.buttonNumber == buttonNumber then
            return button
        end
    end
    return nil
end

-- Get cash generator
function TycoonBase:GetCashGenerator()
    return self.cashGenerator
end

-- Show UI for player
function TycoonBase:ShowUI(player)
    if not HelperFunctions.IsValidPlayer(player) then return end
    
    -- Show ability button UIs
    for _, button in ipairs(self.abilityButtons) do
        button:ShowUI(player)
    end
end

-- Hide UI for player
function TycoonBase:HideUI(player)
    if not HelperFunctions.IsValidPlayer(player) then return end
    
    -- Hide ability button UIs
    for _, button in ipairs(self.abilityButtons) do
        button:HideUI(player)
    end
end

-- Get tycoon data for saving
function TycoonBase:GetData()
    local data = {
        TycoonId = self.tycoonId,
        Position = self.position,
        Owner = self.owner and self.owner.UserId or nil,
        IsActive = self.isActive,
        Level = self.level,
        CashGenerated = self.cashGenerated
    }
    
    -- Add component data
    if self.cashGenerator then
        data.CashGenerator = self.cashGenerator:GetData()
    end
    
    data.AbilityButtons = {}
    for _, button in ipairs(self.abilityButtons) do
        table.insert(data.AbilityButtons, button:GetData())
    end
    
    data.Walls = {}
    for _, wall in ipairs(self.walls) do
        table.insert(data.Walls, {
            MaxHP = wall.maxHP,
            CurrentHP = wall.currentHP,
            IsDestroyed = wall.isDestroyed
        })
    end
    
    return data
end

-- Load tycoon data
function TycoonBase:LoadData(data)
    if type(data) ~= "table" then return false end
    
    -- Load basic properties
    if data.Level then
        self:SetLevel(data.Level)
    end
    
    if data.CashGenerated then
        self.cashGenerated = data.CashGenerated
    end
    
    -- Load component data
    if data.CashGenerator and self.cashGenerator then
        self.cashGenerator:LoadData(data.CashGenerator)
    end
    
    if data.AbilityButtons then
        for i, buttonData in ipairs(data.AbilityButtons) do
            local button = self.abilityButtons[i]
            if button then
                button:LoadData(buttonData)
            end
        end
    end
    
    if data.Walls then
        for i, wallData in ipairs(data.Walls) do
            local wall = self.walls[i]
            if wall then
                wall.maxHP = wallData.MaxHP or wall.maxHP
                wall.currentHP = wallData.CurrentHP or wall.currentHP
                wall.isDestroyed = wallData.IsDestroyed or wall.isDestroyed
                
                -- Update wall appearance
                if wall.isDestroyed then
                    wall.part.Transparency = 0.8
                    wall.part.CanCollide = false
                else
                    local alpha = wall.currentHP / wall.maxHP
                    wall.part.Transparency = 1 - alpha
                    wall.part.CanCollide = true
                end
            end
        end
    end
    
    -- Set active state
    if data.IsActive then
        self:Activate()
    else
        self:Deactivate()
    end
    
    return true
end

-- Clean up
function TycoonBase:Destroy()
    -- Stop wall system
    if self.wallConnection then
        self.wallConnection:Disconnect()
        self.wallConnection = nil
    end
    
    -- Destroy components
    if self.cashGenerator then
        self.cashGenerator:Destroy()
        self.cashGenerator = nil
    end
    
    for _, button in ipairs(self.abilityButtons) do
        button:Destroy()
    end
    self.abilityButtons = {}
    
    -- Destroy structure parts
    for _, wall in ipairs(self.walls) do
        if wall.part then
            wall.part:Destroy()
        end
    end
    self.walls = {}
    
    for _, floor in ipairs(self.floors) do
        if floor then
            floor:Destroy()
        end
    end
    self.floors = {}
    
    if self.ownerDoor then
        self.ownerDoor:Destroy()
        self.ownerDoor = nil
    end
    
    -- Find and destroy base plate
    local basePlate = workspace:FindFirstChild("BasePlate")
    if basePlate then
        basePlate:Destroy()
    end
    
    self.tycoonId = nil
    self.owner = nil
    self.position = nil
end

return TycoonBase
