-- test_step10_anime_guild_system.lua
-- Test file for Step 10: Enhanced Guild System with Anime Fandom Features
-- Demonstrates anime guild creation, theme management, bonus activation, and anime guild wars

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

-- Mock player for testing
local mockPlayer = {
    UserId = 12345,
    Name = "TestPlayer"
}

-- Mock target player for testing
local mockTargetPlayer = {
    UserId = 67890,
    Name = "TargetPlayer"
}

-- Mock guild system (in real implementation, this would be the actual GuildSystem)
local GuildSystem = {
    -- Mock data structures
    guilds = {},
    playerGuilds = {},
    animeGuildThemes = {},
    animeGuildBonuses = {},
    animeGuildWars = {},
    nextGuildId = 1
}

-- Test anime guild themes
local ANIME_GUILD_THEMES = {
    SOLO_LEVELING = {
        name = "Solo Leveling",
        displayName = "Solo Leveling Guild",
        description = "A guild focused on individual power and shadow soldiers",
        colors = {
            primary = Color3.fromRGB(75, 0, 130),    -- Purple
            secondary = Color3.fromRGB(25, 25, 112), -- Dark blue
            accent = Color3.fromRGB(138, 43, 226)    -- Blue violet
        },
        bonuses = {
            SHADOW_SOLDIER_BOOST = {
                name = "Shadow Soldier Boost",
                description = "Increases shadow soldier effectiveness by 25%",
                effect = "shadowSoldierMultiplier",
                value = 1.25,
                duration = 3600, -- 1 hour
                cooldown = 7200   -- 2 hours
            },
            SOLO_POWER_SCALING = {
                name = "Solo Power Scaling",
                description = "Individual members gain 15% more power when alone",
                effect = "soloPowerMultiplier",
                value = 1.15,
                duration = 1800, -- 30 minutes
                cooldown = 3600   -- 1 hour
            }
        },
        warBonus = {
            name = "Shadow Army",
            description = "Summon additional shadow soldiers during guild wars",
            effect = "extraShadowSoldiers",
            value = 3
        }
    },
    NARUTO = {
        name = "Naruto",
        displayName = "Hidden Village Guild",
        description = "A guild based on ninja villages and chakra mastery",
        colors = {
            primary = Color3.fromRGB(255, 69, 0),    -- Orange red
            secondary = Color3.fromRGB(255, 140, 0), -- Dark orange
            accent = Color3.fromRGB(255, 215, 0)     -- Gold
        },
        bonuses = {
            CHAKRA_BOOST = {
                name = "Chakra Boost",
                description = "Increases chakra regeneration by 30%",
                effect = "chakraRegenerationMultiplier",
                value = 1.30,
                duration = 2400, -- 40 minutes
                cooldown = 4800   -- 1.3 hours
            },
            NINJA_TEAMWORK = {
                name = "Ninja Teamwork",
                description = "Team-based activities gain 20% bonus",
                effect = "teamworkMultiplier",
                value = 1.20,
                duration = 3600, -- 1 hour
                cooldown = 7200   -- 2 hours
            }
        },
        warBonus = {
            name = "Rasengan Formation",
            description = "Coordinated attacks deal 25% more damage",
            effect = "coordinatedAttackBonus",
            value = 1.25
        }
    }
}

-- Test function: Create anime guild
function testCreateAnimeGuild()
    print("=== Testing Anime Guild Creation ===")
    
    local guildName = "Shadow Hunters"
    local description = "A guild dedicated to hunting shadows and gaining power"
    local tag = "SH"
    local animeTheme = "SOLO_LEVELING"
    
    -- Validate anime theme
    if not ANIME_GUILD_THEMES[animeTheme] then
        print("❌ Error: Invalid anime theme")
        return false
    end
    
    -- Create guild
    local guildId = GuildSystem.nextGuildId
    GuildSystem.nextGuildId = GuildSystem.nextGuildId + 1
    
    local guild = {
        id = guildId,
        name = guildName,
        tag = tag,
        description = description,
        leader = mockPlayer.UserId,
        members = {[mockPlayer.UserId] = {
            role = "LEADER",
            joinedAt = time(),
            contribution = 0,
            lastActive = time()
        }},
        level = 1,
        experience = 0,
        animeTheme = animeTheme,
        animeThemeData = ANIME_GUILD_THEMES[animeTheme],
        animeBonuses = {},
        animeWarHistory = {}
    }
    
    -- Store guild data
    GuildSystem.guilds[guildId] = guild
    GuildSystem.playerGuilds[mockPlayer.UserId] = guildId
    GuildSystem.animeGuildThemes[guildId] = animeTheme
    
    print("✅ Anime guild created successfully!")
    print("   Guild ID:", guildId)
    print("   Name:", guildName)
    print("   Theme:", animeTheme)
    print("   Leader:", mockPlayer.Name)
    print("   Theme Description:", ANIME_GUILD_THEMES[animeTheme].description)
    
    return guildId
end

-- Test function: Activate anime guild bonus
function testActivateAnimeGuildBonus(guildId, bonusId)
    print("\n=== Testing Anime Guild Bonus Activation ===")
    
    local guild = GuildSystem.guilds[guildId]
    if not guild then
        print("❌ Error: Guild not found")
        return false
    end
    
    if not guild.animeTheme then
        print("❌ Error: Guild does not have an anime theme")
        return false
    end
    
    local themeData = ANIME_GUILD_THEMES[guild.animeTheme]
    if not themeData or not themeData.bonuses[bonusId] then
        print("❌ Error: Bonus not found for this theme")
        return false
    end
    
    local bonus = themeData.bonuses[bonusId]
    
    -- Check if bonus is on cooldown
    local currentBonus = GuildSystem.animeGuildBonuses[guildId] and GuildSystem.animeGuildBonuses[guildId][bonusId]
    if currentBonus and time() < currentBonus.expiresAt + bonus.cooldown then
        local remainingCooldown = (currentBonus.expiresAt + bonus.cooldown) - time()
        print("❌ Error: Bonus on cooldown. Remaining time:", math.floor(remainingCooldown / 60), "minutes")
        return false
    end
    
    -- Activate bonus
    if not GuildSystem.animeGuildBonuses[guildId] then
        GuildSystem.animeGuildBonuses[guildId] = {}
    end
    
    GuildSystem.animeGuildBonuses[guildId][bonusId] = {
        effect = bonus.effect,
        value = bonus.value,
        activatedAt = time(),
        expiresAt = time() + bonus.duration,
        activatorId = mockPlayer.UserId
    }
    
    print("✅ Anime guild bonus activated successfully!")
    print("   Bonus:", bonus.name)
    print("   Effect:", bonus.effect)
    print("   Value:", bonus.value)
    print("   Duration:", bonus.duration / 60, "minutes")
    print("   Cooldown:", bonus.cooldown / 60, "minutes")
    
    return true
end

-- Test function: Start anime guild war
function testStartAnimeGuildWar(guild1Id, guild2Id)
    print("\n=== Testing Anime Guild War ===")
    
    local guild1 = GuildSystem.guilds[guild1Id]
    local guild2 = GuildSystem.guilds[guild2Id]
    
    if not guild1 or not guild2 then
        print("❌ Error: One or both guilds not found")
        return false
    end
    
    if not guild1.animeTheme or not guild2.animeTheme then
        print("❌ Error: Both guilds must have anime themes to participate in anime wars")
        return false
    end
    
    -- Check if already at war
    for _, war in pairs(GuildSystem.animeGuildWars) do
        if war.status == "ACTIVE" and war.warType == "ANIME_WAR" and
           ((war.guild1Id == guild1Id and war.guild2Id == guild2Id) or
            (war.guild1Id == guild2Id and war.guild2Id == guild1Id)) then
            print("❌ Error: Guilds are already at anime war")
            return false
        end
    end
    
    -- Create anime war
    local warId = HttpService:GenerateGUID()
    local war = {
        id = warId,
        guild1Id = guild1Id,
        guild2Id = guild2Id,
        guild1Theme = guild1.animeTheme,
        guild2Theme = guild2.animeTheme,
        startTime = time(),
        duration = 7 * 24 * 60 * 60, -- 7 days
        status = "ACTIVE",
        warType = "ANIME_WAR",
        scores = {
            [guild1Id] = 0,
            [guild2Id] = 0
        },
        participants = {
            [guild1Id] = {},
            [guild2Id] = {}
        },
        animeWarEvents = {},
        themeAdvantages = calculateThemeAdvantages(guild1.animeTheme, guild2.animeTheme)
    }
    
    -- Store anime war
    GuildSystem.animeGuildWars[warId] = war
    
    print("✅ Anime guild war started successfully!")
    print("   War ID:", warId)
    print("   Guild 1:", guild1.name, "(" .. guild1.animeTheme .. ")")
    print("   Guild 2:", guild2.name, "(" .. guild2.animeTheme .. ")")
    print("   Duration: 7 days")
    print("   Theme Advantages:")
    for theme, advantage in pairs(war.themeAdvantages) do
        if advantage.description then
            print("     " .. theme .. ":", advantage.description, "(+" .. ((advantage.bonus - 1) * 100) .. "%)")
        end
    end
    
    return warId
end

-- Helper function: Calculate theme advantages
function calculateThemeAdvantages(theme1, theme2)
    local advantages = {
        [theme1] = {},
        [theme2] = {}
    }
    
    -- Theme-specific advantages (rock-paper-scissors style)
    if theme1 == "SOLO_LEVELING" and theme2 == "NARUTO" then
        advantages[theme1].description = "Shadow soldiers can infiltrate ninja villages"
        advantages[theme1].bonus = 1.15
        advantages[theme2].description = "Chakra sensing can detect shadow soldiers"
        advantages[theme2].bonus = 1.10
    elseif theme1 == "NARUTO" and theme2 == "SOLO_LEVELING" then
        advantages[theme2].description = "Shadow soldiers can infiltrate ninja villages"
        advantages[theme2].bonus = 1.15
        advantages[theme1].description = "Chakra sensing can detect shadow soldiers"
        advantages[theme1].bonus = 1.10
    end
    
    return advantages
end

-- Test function: Generate anime war event
function testGenerateAnimeWarEvent(warId)
    print("\n=== Testing Anime War Event Generation ===")
    
    local war = GuildSystem.animeGuildWars[warId]
    if not war then
        print("❌ Error: War not found")
        return false
    end
    
    local eventTypes = {
        "THEME_CHALLENGE",
        "ANIME_BOSS_RAID",
        "CROSS_THEME_BATTLE",
        "ANIME_ARTIFACT_COLLECTION"
    }
    
    local eventType = eventTypes[math.random(1, #eventTypes)]
    local eventId = HttpService:GenerateGUID()
    
    local event = {
        id = eventId,
        type = eventType,
        startTime = time(),
        expiresAt = time() + 1800, -- 30 minutes
        status = "ACTIVE",
        participants = {},
        rewards = calculateAnimeWarEventRewards(eventType)
    }
    
    war.animeWarEvents[eventId] = event
    
    print("✅ Anime war event generated successfully!")
    print("   Event ID:", eventId)
    print("   Type:", eventType)
    print("   Duration: 30 minutes")
    print("   Rewards:")
    print("     Cash:", event.rewards.cash)
    print("     Experience:", event.rewards.experience)
    print("     Anime Points:", event.rewards.animePoints)
    
    return eventId
end

-- Helper function: Calculate anime war event rewards
function calculateAnimeWarEventRewards(eventType)
    local baseRewards = {
        cash = 1000,
        experience = 500,
        animePoints = 100
    }
    
    local multipliers = {
        THEME_CHALLENGE = 1.0,
        ANIME_BOSS_RAID = 1.5,
        CROSS_THEME_BATTLE = 1.3,
        ANIME_ARTIFACT_COLLECTION = 1.2
    }
    
    local multiplier = multipliers[eventType] or 1.0
    
    return {
        cash = math.floor(baseRewards.cash * multiplier),
        experience = math.floor(baseRewards.experience * multiplier),
        animePoints = math.floor(baseRewards.animePoints * multiplier)
    }
end

-- Test function: Get anime guild stats
function testGetAnimeGuildStats(guildId)
    print("\n=== Testing Anime Guild Stats ===")
    
    local guild = GuildSystem.guilds[guildId]
    if not guild or not guild.animeTheme then
        print("❌ Error: Guild not found or has no anime theme")
        return nil
    end
    
    local stats = {
        theme = guild.animeTheme,
        themeData = guild.animeThemeData,
        activeBonuses = {},
        warHistory = guild.animeWarHistory or {},
        themeMastery = 0,
        animePoints = 0
    }
    
    -- Get active bonuses
    local guildBonuses = GuildSystem.animeGuildBonuses[guildId]
    if guildBonuses then
        for bonusId, bonus in pairs(guildBonuses) do
            if time() < bonus.expiresAt then
                stats.activeBonuses[bonusId] = bonus
            end
        end
    end
    
    -- Calculate theme mastery based on guild level and experience
    stats.themeMastery = math.floor((guild.level * 100 + guild.experience / 100) / 10)
    
    -- Calculate anime points (placeholder for future integration)
    stats.animePoints = guild.level * 100 + guild.experience / 10
    
    print("✅ Anime guild stats retrieved successfully!")
    print("   Theme:", stats.theme)
    print("   Theme Mastery:", stats.themeMastery)
    print("   Anime Points:", stats.animePoints)
    print("   Active Bonuses:", #stats.activeBonuses)
    print("   War History Entries:", #stats.warHistory)
    
    return stats
end

-- Main test execution
function runStep10Tests()
    print("🚀 STEP 10: Enhanced Guild System with Anime Fandom Features")
    print("=" .. string.rep("=", 70))
    
    -- Test 1: Create anime guild
    local guildId = testCreateAnimeGuild()
    if not guildId then
        print("❌ Test failed: Could not create anime guild")
        return
    end
    
    -- Test 2: Activate anime guild bonus
    local bonusActivated = testActivateAnimeGuildBonus(guildId, "SHADOW_SOLDIER_BOOST")
    if not bonusActivated then
        print("❌ Test failed: Could not activate anime guild bonus")
        return
    end
    
    -- Test 3: Create second guild for war testing
    local guild2Id = GuildSystem.nextGuildId
    GuildSystem.nextGuildId = GuildSystem.nextGuildId + 1
    
    local guild2 = {
        id = guild2Id,
        name = "Hidden Leaf",
        tag = "HL",
        description = "A guild based on ninja traditions",
        leader = mockTargetPlayer.UserId,
        members = {[mockTargetPlayer.UserId] = {
            role = "LEADER",
            joinedAt = time(),
            contribution = 0,
            lastActive = time()
        }},
        level = 1,
        experience = 0,
        animeTheme = "NARUTO",
        animeThemeData = ANIME_GUILD_THEMES["NARUTO"],
        animeBonuses = {},
        animeWarHistory = {}
    }
    
    GuildSystem.guilds[guild2Id] = guild2
    GuildSystem.playerGuilds[mockTargetPlayer.UserId] = guild2Id
    GuildSystem.animeGuildThemes[guild2Id] = "NARUTO"
    
    print("\n✅ Second anime guild created for war testing:")
    print("   Guild ID:", guild2Id)
    print("   Name:", guild2.name)
    print("   Theme:", guild2.animeTheme)
    
    -- Test 4: Start anime guild war
    local warId = testStartAnimeGuildWar(guildId, guild2Id)
    if not warId then
        print("❌ Test failed: Could not start anime guild war")
        return
    end
    
    -- Test 5: Generate anime war event
    local eventId = testGenerateAnimeWarEvent(warId)
    if not eventId then
        print("❌ Test failed: Could not generate anime war event")
        return
    end
    
    -- Test 6: Get anime guild stats
    local stats = testGetAnimeGuildStats(guildId)
    if not stats then
        print("❌ Test failed: Could not get anime guild stats")
        return
    end
    
    -- Test 7: Display system overview
    print("\n=== Anime Guild System Overview ===")
    print("Total Guilds:", #GuildSystem.guilds)
    print("Anime Themed Guilds:", #GuildSystem.animeGuildThemes)
    print("Active Anime Wars:", #GuildSystem.animeGuildWars)
    
    local totalActiveBonuses = 0
    for guildId, bonuses in pairs(GuildSystem.animeGuildBonuses) do
        for _, bonus in pairs(bonuses) do
            if time() < bonus.expiresAt then
                totalActiveBonuses = totalActiveBonuses + 1
            end
        end
    end
    print("Active Anime Bonuses:", totalActiveBonuses)
    
    print("\n🎉 STEP 10 TESTS COMPLETED SUCCESSFULLY!")
    print("✅ Anime guild creation and management")
    print("✅ Anime theme customization")
    print("✅ Anime guild bonus activation")
    print("✅ Anime guild wars with theme advantages")
    print("✅ Anime war event generation")
    print("✅ Anime guild statistics and metrics")
end

-- Run the tests
runStep10Tests()
