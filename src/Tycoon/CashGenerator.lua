-- CashGenerator.lua
-- Handles cash generation for tycoons

local RunService = game:GetService("RunService")
local Constants = require(script.Parent.Parent.Utils.Constants)
local HelperFunctions = require(script.Parent.Parent.Utils.HelperFunctions)

local CashGenerator = {}
CashGenerator.__index = CashGenerator

-- Create new cash generator
function CashGenerator.new(tycoonId, owner)
    local self = setmetatable({}, CashGenerator)
    self.tycoonId = tycoonId
    self.owner = owner
    self.isActive = false
    self.generationRate = Constants.TYCOON.CASH_GENERATION_BASE
    self.generationInterval = Constants.TYCOON.CASH_GENERATION_INTERVAL
    self.lastGeneration = tick()
    self.totalGenerated = 0
    self.upgrades = {
        Rate = 1,
        Multiplier = 1
    }
    
    -- Start generation
    self:Start()
    
    return self
end

-- Start cash generation
function CashGenerator:Start()
    if self.isActive then return end
    
    self.isActive = true
    self.lastGeneration = tick()
    
    -- Connect to RunService for continuous generation
    self.connection = RunService.Heartbeat:Connect(function()
        self:Update()
    end)
end

-- Stop cash generation
function CashGenerator:Stop()
    if not self.isActive then return end
    
    self.isActive = false
    
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
end

-- Update cash generation
function CashGenerator:Update()
    if not self.isActive then return end
    
    local currentTime = tick()
    local timeSinceLastGeneration = currentTime - self.lastGeneration
    
    if timeSinceLastGeneration >= self.generationInterval then
        self:GenerateCash()
        self.lastGeneration = currentTime
    end
end

-- Generate cash for the owner
function CashGenerator:GenerateCash()
    if not self.owner then return end
    
    local playerData = require(script.Parent.Parent.Player.PlayerData).GetPlayerData(self.owner)
    if not playerData then return end
    
    -- Calculate cash amount
    local baseAmount = self.generationRate
    local upgradeMultiplier = self.upgrades.Multiplier
    local finalAmount = baseAmount * upgradeMultiplier
    
    -- Add cash to player
    if playerData:AddCash(finalAmount) then
        self.totalGenerated = self.totalGenerated + finalAmount
        
        -- Notify player
        HelperFunctions.CreateNotification(self.owner, "+$" .. HelperFunctions.FormatCash(finalAmount), 2)
    end
end

-- Set generation rate
function CashGenerator:SetGenerationRate(rate)
    if type(rate) == "number" and rate > 0 then
        self.generationRate = rate
        return true
    end
    return false
end

-- Get generation rate
function CashGenerator:GetGenerationRate()
    return self.generationRate
end

-- Set generation interval
function CashGenerator:SetGenerationInterval(interval)
    if type(interval) == "number" and interval > 0 then
        self.generationInterval = interval
        return true
    end
    return false
end

-- Get generation interval
function CashGenerator:GetGenerationInterval()
    return self.generationInterval
end

-- Upgrade generation rate
function CashGenerator:UpgradeRate()
    local currentLevel = self.upgrades.Rate
    local maxLevel = Constants.ECONOMY.MAX_UPGRADE_LEVEL
    
    if currentLevel < maxLevel then
        self.upgrades.Rate = currentLevel + 1
        self.generationRate = Constants.TYCOON.CASH_GENERATION_BASE * self.upgrades.Rate
        return true
    end
    
    return false
end

-- Upgrade generation multiplier
function CashGenerator:UpgradeMultiplier()
    local currentLevel = self.upgrades.Multiplier
    local maxLevel = Constants.ECONOMY.MAX_UPGRADE_LEVEL
    
    if currentLevel < maxLevel then
        self.upgrades.Multiplier = currentLevel + 1
        return true
    end
    
    return false
end

-- Get upgrade level
function CashGenerator:GetUpgradeLevel(upgradeType)
    return self.upgrades[upgradeType] or 0
end

-- Get all upgrades
function CashGenerator:GetAllUpgrades()
    return table.clone(self.upgrades)
end

-- Get total cash generated
function CashGenerator:GetTotalGenerated()
    return self.totalGenerated
end

-- Check if generator is active
function CashGenerator:IsActive()
    return self.isActive
end

-- Set owner
function CashGenerator:SetOwner(owner)
    self.owner = owner
end

-- Get owner
function CashGenerator:GetOwner()
    return self.owner
end

-- Get cash per second
function CashGenerator:GetCashPerSecond()
    if self.generationInterval <= 0 then return 0 end
    return (self.generationRate * self.upgrades.Multiplier) / self.generationInterval
end

-- Get upgrade cost for rate
function CashGenerator:GetRateUpgradeCost()
    local currentLevel = self.upgrades.Rate
    return math.floor(Constants.ECONOMY.ABILITY_BASE_COST * (Constants.ECONOMY.UPGRADE_COST_MULTIPLIER ^ currentLevel))
end

-- Get upgrade cost for multiplier
function CashGenerator:GetMultiplierUpgradeCost()
    local currentLevel = self.upgrades.Multiplier
    return math.floor(Constants.ECONOMY.ABILITY_BASE_COST * (Constants.ECONOMY.UPGRADE_COST_MULTIPLIER ^ currentLevel))
end

-- Can upgrade rate
function CashGenerator:CanUpgradeRate()
    return self.upgrades.Rate < Constants.ECONOMY.MAX_UPGRADE_LEVEL
end

-- Can upgrade multiplier
function CashGenerator:CanUpgradeMultiplier()
    return self.upgrades.Multiplier < Constants.ECONOMY.MAX_UPGRADE_LEVEL
end

-- Reset to defaults
function CashGenerator:Reset()
    self.upgrades = {
        Rate = 1,
        Multiplier = 1
    }
    self.generationRate = Constants.TYCOON.CASH_GENERATION_BASE
    self.generationInterval = Constants.TYCOON.CASH_GENERATION_INTERVAL
    self.totalGenerated = 0
end

-- Get generator data for saving
function CashGenerator:GetData()
    return {
        TycoonId = self.tycoonId,
        Owner = self.owner and self.owner.UserId or nil,
        IsActive = self.isActive,
        GenerationRate = self.generationRate,
        GenerationInterval = self.generationInterval,
        LastGeneration = self.lastGeneration,
        TotalGenerated = self.totalGenerated,
        Upgrades = table.clone(self.upgrades)
    }
end

-- Load generator data
function CashGenerator:LoadData(data)
    if type(data) ~= "table" then return false end
    
    -- Load basic properties
    if data.GenerationRate then
        self.generationRate = data.GenerationRate
    end
    
    if data.GenerationInterval then
        self.generationInterval = data.GenerationInterval
    end
    
    if data.TotalGenerated then
        self.totalGenerated = data.TotalGenerated
    end
    
    if data.Upgrades then
        for key, value in pairs(data.Upgrades) do
            if self.upgrades[key] ~= nil then
                self.upgrades[key] = value
            end
        end
    end
    
    -- Restart if it was active
    if data.IsActive then
        self:Start()
    end
    
    return true
end

-- Clean up
function CashGenerator:Destroy()
    self:Stop()
    
    self.tycoonId = nil
    self.owner = nil
    self.upgrades = nil
end

return CashGenerator
