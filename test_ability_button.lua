-- Test script to verify AbilityButton loading
-- Place this in ServerScriptService to test

print("🧪 Testing AbilityButton Loading...")

-- Wait for systems to initialize
wait(2)

-- Try to load AbilityButton module
local success, AbilityButton = pcall(require, script.Parent.Tycoon.AbilityButton)

if success then
    print("✅ AbilityButton loaded successfully!")
    print("   Module type:", typeof(AbilityButton))
    print("   Has 'new' function:", AbilityButton.new ~= nil)
    
    -- Try to create an instance
    local testButton = AbilityButton.new(1, "test_tycoon", "test_player")
    if testButton then
        print("✅ AbilityButton instance created successfully!")
        print("   Button name:", testButton.buttonPart.Name)
        print("   Button color:", testButton.config.Color)
        print("   Button icon:", testButton.config.Icon)
    else
        print("❌ Failed to create AbilityButton instance")
    end
else
    print("❌ Failed to load AbilityButton:")
    print("   Error:", AbilityButton)
    
    -- Check what's in the Tycoon folder
    print("\n🔍 Checking Tycoon folder contents...")
    local tycoonFolder = script.Parent:FindFirstChild("Tycoon")
    if tycoonFolder then
        print("✅ Tycoon folder found")
        for _, child in pairs(tycoonFolder:GetChildren()) do
            print("   - " .. child.Name .. " (" .. child.ClassName .. ")")
        end
    else
        print("❌ Tycoon folder not found!")
    end
end

print("\n🎯 Test complete!")
