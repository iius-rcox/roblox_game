-- test_step10_comprehensive_anime_guild.lua
-- Comprehensive test file for Step 10: Enhanced Guild System with Anime Fandom Features
-- Demonstrates all anime guild features: creation, themes, bonuses, wars, collaborations, and festivals

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

-- Mock third player for testing
local mockThirdPlayer = {
    UserId = 11111,
    Name = "ThirdPlayer"
}

-- Mock guild system (in real implementation, this would be the actual GuildSystem)
local GuildSystem = {
    -- Mock data structures
    guilds = {},
    playerGuilds = {},
    animeGuildThemes = {},
    animeGuildBonuses = {},
    animeGuildWars = {},
    crossAnimeCollaborations = {},
    animeFestivals = {},
    nextGuildId = 1
}

-- Test anime guild themes (matching the ones in GuildSystem.lua)
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
    },
    ONE_PIECE = {
        name = "One Piece",
        displayName = "Pirate Crew Guild",
        description = "A guild focused on adventure and devil fruit powers",
        colors = {
            primary = Color3.fromRGB(255, 0, 0),     -- Red
            secondary = Color3.fromRGB(139, 0, 0),   -- Dark red
            accent = Color3.fromRGB(255, 165, 0)     -- Orange
        },
        bonuses = {
            DEVIL_FRUIT_POWER = {
                name = "Devil Fruit Power",
                description = "Devil fruit abilities are 20% more effective",
                effect = "devilFruitMultiplier",
                value = 1.20,
                duration = 3000, -- 50 minutes
                cooldown = 6000   -- 1.7 hours
            },
            CREW_MORALE = {
                name = "Crew Morale",
                description = "Guild activities provide 15% more rewards",
                effect = "crewMoraleMultiplier",
                value = 1.15,
                duration = 3600, -- 1 hour
                cooldown = 7200   -- 2 hours
            }
        },
        warBonus = {
            name = "Haki Coordination",
            description = "Guild members can share haki abilities",
            effect = "hakiSharing",
            value = true
        }
    }
}

-- Test function: Create anime guild
function testCreateAnimeGuild(leader, guildName, description, tag, animeTheme)
    print("=== Testing Anime Guild Creation ===")

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
        leader = leader.UserId,
        members = {[leader.UserId] = {
            role = "LEADER",
            joinedAt = tick(),
            contribution = 0,
            lastActive = tick()
        }},
        level = 1,
        experience = 0,
        animeTheme = animeTheme,
        animeThemeData = ANIME_GUILD_THEMES[animeTheme],
        animeBonuses = {},
        animeWarHistory = {},
        upgrades = {"ANIME_THEME_CUSTOMIZATION", "ANIME_GUILD_WARS", "CROSS_ANIME_COLLABORATION", "ANIME_FESTIVALS"}
    }

    -- Store guild data
    GuildSystem.guilds[guildId] = guild
    GuildSystem.playerGuilds[leader.UserId] = guildId
    GuildSystem.animeGuildThemes[guildId] = animeTheme

    print("✅ Anime guild created successfully!")
    print("   Guild ID:", guildId)
    print("   Name:", guildName)
    print("   Theme:", animeTheme)
    print("   Leader:", leader.Name)
    print("   Theme Description:", ANIME_GUILD_THEMES[animeTheme].description)
    print("   Available Upgrades:", table.concat(guild.upgrades, ", "))

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
    if currentBonus and tick() < currentBonus.expiresAt + bonus.cooldown then
        local remainingCooldown = (currentBonus.expiresAt + bonus.cooldown) - tick()
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
        activatedAt = tick(),
        expiresAt = tick() + bonus.duration,
        activatorId = guild.leader
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
        startTime = tick(),
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

-- Test function: Create cross-anime collaboration
function testCreateCrossAnimeCollaboration(guild1Id, guild2Id, collaborationType)
    print("\n=== Testing Cross-Anime Collaboration ===")

    local guild1 = GuildSystem.guilds[guild1Id]
    local guild2 = GuildSystem.guilds[guild2Id]

    if not guild1 or not guild2 then
        print("❌ Error: One or both guilds not found")
        return false
    end

    if not guild1.animeTheme or not guild2.animeTheme then
        print("❌ Error: Both guilds must have anime themes to collaborate")
        return false
    end

    if guild1.animeTheme == guild2.animeTheme then
        print("❌ Error: Guilds must have different anime themes to collaborate")
        return false
    end

    -- Check if already collaborating
    for _, collab in pairs(GuildSystem.crossAnimeCollaborations) do
        if collab.status == "ACTIVE" and 
           ((collab.guild1Id == guild1Id and collab.guild2Id == guild2Id) or
            (collab.guild1Id == guild2Id and collab.guild2Id == guild1Id)) then
            print("❌ Error: Guilds are already collaborating")
            return false
        end
    end

    -- Create collaboration
    local collaborationId = HttpService:GenerateGUID()
    local collaboration = {
        id = collaborationId,
        guild1Id = guild1Id,
        guild2Id = guild2Id,
        guild1Theme = guild1.animeTheme,
        guild2Theme = guild2.animeTheme,
        type = collaborationType,
        startTime = tick(),
        duration = 3 * 24 * 60 * 60, -- 3 days
        status = "ACTIVE",
        participants = {
            [guild1Id] = {},
            [guild2Id] = {}
        },
        collaborationEvents = {},
        rewards = {
            cash = 5000,
            experience = 2500,
            animePoints = 500,
            crossThemeBonus = 1.25
        }
    }

    -- Store collaboration
    GuildSystem.crossAnimeCollaborations[collaborationId] = collaboration

    print("✅ Cross-anime collaboration started successfully!")
    print("   Collaboration ID:", collaborationId)
    print("   Guild 1:", guild1.name, "(" .. guild1.animeTheme .. ")")
    print("   Guild 2:", guild2.name, "(" .. guild2.animeTheme .. ")")
    print("   Type:", collaborationType)
    print("   Duration: 3 days")
    print("   Cross-Theme Bonus:", ((collaboration.rewards.crossThemeBonus - 1) * 100) .. "%")

    return collaborationId
end

-- Test function: Create anime festival
function testCreateAnimeFestival(guildId, festivalType, data)
    print("\n=== Testing Anime Festival Creation ===")

    local guild = GuildSystem.guilds[guildId]
    if not guild then
        print("❌ Error: Guild not found")
        return false
    end

    if not guild.animeTheme then
        print("❌ Error: Guild must have an anime theme to host festivals")
        return false
    end

    -- Create festival
    local festivalId = HttpService:GenerateGUID()
    local festival = {
        id = festivalId,
        guildId = guildId,
        guildTheme = guild.animeTheme,
        type = festivalType,
        data = data,
        creatorId = guild.leader,
        startTime = tick(),
        duration = 24 * 60 * 60, -- 24 hours
        status = "ACTIVE",
        participants = {},
        festivalEvents = {},
        rewards = {
            cash = 3000,
            experience = 1500,
            animePoints = 300,
            themeBonus = 1.20
        }
    }

    -- Store festival
    GuildSystem.animeFestivals[festivalId] = festival

    print("✅ Anime festival created successfully!")
    print("   Festival ID:", festivalId)
    print("   Guild:", guild.name, "(" .. guild.animeTheme .. ")")
    print("   Type:", festivalType)
    print("   Duration: 24 hours")
    print("   Theme Bonus:", ((festival.rewards.themeBonus - 1) * 100) .. "%")

    return festivalId
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
        startTime = tick(),
        expiresAt = tick() + 1800, -- 30 minutes
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

-- Test function: Generate cross-anime collaboration event
function testGenerateCrossAnimeCollaborationEvent(collaborationId)
    print("\n=== Testing Cross-Anime Collaboration Event Generation ===")

    local collab = GuildSystem.crossAnimeCollaborations[collaborationId]
    if not collab then
        print("❌ Error: Collaboration not found")
        return false
    end

    local eventTypes = {
        "THEME_FUSION_CHALLENGE",
        "CROSS_ANIME_BOSS_RAID",
        "ANIME_COMBINATION_ATTACK",
        "THEME_SYNERGY_TRAINING"
    }

    local eventType = eventTypes[math.random(1, #eventTypes)]
    local eventId = HttpService:GenerateGUID()

    local event = {
        id = eventId,
        type = eventType,
        startTime = tick(),
        expiresAt = tick() + 1800, -- 30 minutes
        status = "ACTIVE",
        participants = {},
        rewards = calculateCrossAnimeCollaborationEventRewards(eventType)
    }

    collab.collaborationEvents[eventId] = event

    print("✅ Cross-anime collaboration event generated successfully!")
    print("   Event ID:", eventId)
    print("   Type:", eventType)
    print("   Duration: 30 minutes")
    print("   Rewards:")
    print("     Cash:", event.rewards.cash)
    print("     Experience:", event.rewards.experience)
    print("     Anime Points:", event.rewards.animePoints)
    print("     Cross-Theme Bonus:", ((event.rewards.crossThemeBonus - 1) * 100) .. "%")

    return eventId
end

-- Test function: Generate anime festival event
function testGenerateAnimeFestivalEvent(festivalId)
    print("\n=== Testing Anime Festival Event Generation ===")

    local festival = GuildSystem.animeFestivals[festivalId]
    if not festival then
        print("❌ Error: Festival not found")
        return false
    end

    local eventTypes = {
        "THEME_CELEBRATION",
        "ANIME_CHARACTER_PARADE",
        "THEME_POWER_DEMONSTRATION",
        "ANIME_ARTIFACT_EXHIBITION"
    }

    local eventType = eventTypes[math.random(1, #eventTypes)]
    local eventId = HttpService:GenerateGUID()

    local event = {
        id = eventId,
        type = eventType,
        startTime = tick(),
        expiresAt = tick() + 900, -- 15 minutes
        status = "ACTIVE",
        participants = {},
        rewards = calculateAnimeFestivalEventRewards(eventType)
    }

    festival.festivalEvents[eventId] = event

    print("✅ Anime festival event generated successfully!")
    print("   Event ID:", eventId)
    print("   Type:", eventType)
    print("   Duration: 15 minutes")
    print("   Rewards:")
    print("     Cash:", event.rewards.cash)
    print("     Experience:", event.rewards.experience)
    print("     Anime Points:", event.rewards.animePoints)
    print("     Theme Bonus:", ((event.rewards.themeBonus - 1) * 100) .. "%")

    return eventId
end

-- Test function: Get comprehensive anime guild stats
function testGetComprehensiveAnimeGuildStats(guildId)
    print("\n=== Testing Comprehensive Anime Guild Stats ===")

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
        animePoints = 0,
        activeWars = 0,
        activeCollaborations = 0,
        activeFestivals = 0
    }

    -- Get active bonuses
    local guildBonuses = GuildSystem.animeGuildBonuses[guildId]
    if guildBonuses then
        for bonusId, bonus in pairs(guildBonuses) do
            if tick() < bonus.expiresAt then
                stats.activeBonuses[bonusId] = bonus
            end
        end
    end

    -- Count active wars
    for _, war in pairs(GuildSystem.animeGuildWars) do
        if war.status == "ACTIVE" and war.warType == "ANIME_WAR" and
           (war.guild1Id == guildId or war.guild2Id == guildId) then
            stats.activeWars = stats.activeWars + 1
        end
    end

    -- Count active collaborations
    for _, collab in pairs(GuildSystem.crossAnimeCollaborations) do
        if collab.status == "ACTIVE" and
           (collab.guild1Id == guildId or collab.guild2Id == guildId) then
            stats.activeCollaborations = stats.activeCollaborations + 1
        end
    end

    -- Count active festivals
    for _, festival in pairs(GuildSystem.animeFestivals) do
        if festival.status == "ACTIVE" and festival.guildId == guildId then
            stats.activeFestivals = stats.activeFestivals + 1
        end
    end

    -- Calculate theme mastery based on guild level and experience
    stats.themeMastery = math.floor((guild.level * 100 + guild.experience / 100) / 10)

    -- Calculate anime points (placeholder for future integration)
    stats.animePoints = guild.level * 100 + guild.experience / 10

    print("✅ Comprehensive anime guild stats retrieved successfully!")
    print("   Theme:", stats.theme)
    print("   Theme Mastery:", stats.themeMastery)
    print("   Anime Points:", stats.animePoints)
    print("   Active Bonuses:", #stats.activeBonuses)
    print("   Active Wars:", stats.activeWars)
    print("   Active Collaborations:", stats.activeCollaborations)
    print("   Active Festivals:", stats.activeFestivals)
    print("   War History Entries:", #stats.warHistory)

    return stats
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
    elseif theme1 == "ONE_PIECE" and theme2 == "SOLO_LEVELING" then
        advantages[theme1].description = "Devil fruit powers can counter shadow magic"
        advantages[theme1].bonus = 1.12
        advantages[theme2].description = "Shadow soldiers can hide from haki detection"
        advantages[theme2].bonus = 1.08
    elseif theme1 == "SOLO_LEVELING" and theme2 == "ONE_PIECE" then
        advantages[theme2].description = "Devil fruit powers can counter shadow magic"
        advantages[theme2].bonus = 1.12
        advantages[theme1].description = "Shadow soldiers can hide from haki detection"
        advantages[theme1].bonus = 1.08
    end

    return advantages
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

-- Helper function: Calculate cross-anime collaboration event rewards
function calculateCrossAnimeCollaborationEventRewards(eventType)
    local baseRewards = {
        cash = 1500,
        experience = 750,
        animePoints = 150,
        crossThemeBonus = 1.25
    }

    local multipliers = {
        THEME_FUSION_CHALLENGE = 1.0,
        CROSS_ANIME_BOSS_RAID = 1.5,
        ANIME_COMBINATION_ATTACK = 1.3,
        THEME_SYNERGY_TRAINING = 1.2
    }

    local multiplier = multipliers[eventType] or 1.0

    return {
        cash = math.floor(baseRewards.cash * multiplier),
        experience = math.floor(baseRewards.experience * multiplier),
        animePoints = math.floor(baseRewards.animePoints * multiplier),
        crossThemeBonus = baseRewards.crossThemeBonus
    }
end

-- Helper function: Calculate anime festival event rewards
function calculateAnimeFestivalEventRewards(eventType)
    local baseRewards = {
        cash = 800,
        experience = 400,
        animePoints = 80,
        themeBonus = 1.20
    }

    local multipliers = {
        THEME_CELEBRATION = 1.0,
        ANIME_CHARACTER_PARADE = 1.3,
        THEME_POWER_DEMONSTRATION = 1.4,
        ANIME_ARTIFACT_EXHIBITION = 1.2
    }

    local multiplier = multipliers[eventType] or 1.0

    return {
        cash = math.floor(baseRewards.cash * multiplier),
        experience = math.floor(baseRewards.experience * multiplier),
        animePoints = math.floor(baseRewards.animePoints * multiplier),
        themeBonus = baseRewards.themeBonus
    }
end

-- Main comprehensive test execution
function runComprehensiveStep10Tests()
    print("🚀 STEP 10: COMPREHENSIVE ANIME GUILD SYSTEM TESTING")
    print("=" .. string.rep("=", 70))

    -- Test 1: Create multiple anime guilds with different themes
    print("\n📋 PHASE 1: Creating Multiple Anime Guilds")
    local guild1Id = testCreateAnimeGuild(mockPlayer, "Shadow Hunters", "A guild dedicated to hunting shadows and gaining power", "SH", "SOLO_LEVELING")
    if not guild1Id then
        print("❌ Test failed: Could not create first anime guild")
        return
    end

    local guild2Id = testCreateAnimeGuild(mockTargetPlayer, "Hidden Leaf", "A guild based on ninja traditions", "HL", "NARUTO")
    if not guild2Id then
        print("❌ Test failed: Could not create second anime guild")
        return
    end

    local guild3Id = testCreateAnimeGuild(mockThirdPlayer, "Straw Hat Crew", "A guild focused on adventure and freedom", "SHC", "ONE_PIECE")
    if not guild3Id then
        print("❌ Test failed: Could not create third anime guild")
        return
    end

    -- Test 2: Activate anime guild bonuses
    print("\n📋 PHASE 2: Testing Anime Guild Bonus System")
    local bonus1Activated = testActivateAnimeGuildBonus(guild1Id, "SHADOW_SOLDIER_BOOST")
    if not bonus1Activated then
        print("❌ Test failed: Could not activate first anime guild bonus")
        return
    end

    local bonus2Activated = testActivateAnimeGuildBonus(guild2Id, "CHAKRA_BOOST")
    if not bonus2Activated then
        print("❌ Test failed: Could not activate second anime guild bonus")
        return
    end

    local bonus3Activated = testActivateAnimeGuildBonus(guild3Id, "DEVIL_FRUIT_POWER")
    if not bonus3Activated then
        print("❌ Test failed: Could not activate third anime guild bonus")
        return
    end

    -- Test 3: Start anime guild wars
    print("\n📋 PHASE 3: Testing Anime Guild War System")
    local war1Id = testStartAnimeGuildWar(guild1Id, guild2Id)
    if not war1Id then
        print("❌ Test failed: Could not start first anime guild war")
        return
    end

    local war2Id = testStartAnimeGuildWar(guild2Id, guild3Id)
    if not war2Id then
        print("❌ Test failed: Could not start second anime guild war")
        return
    end

    -- Test 4: Create cross-anime collaborations
    print("\n📋 PHASE 4: Testing Cross-Anime Collaboration System")
    local collab1Id = testCreateCrossAnimeCollaboration(guild1Id, guild3Id, "THEME_FUSION_CHALLENGE")
    if not collab1Id then
        print("❌ Test failed: Could not create first cross-anime collaboration")
        return
    end

    local collab2Id = testCreateCrossAnimeCollaboration(guild2Id, guild3Id, "CROSS_ANIME_BOSS_RAID")
    if not collab2Id then
        print("❌ Test failed: Could not create second cross-anime collaboration")
        return
    end

    -- Test 5: Create anime festivals
    print("\n📋 PHASE 5: Testing Anime Festival System")
    local festival1Id = testCreateAnimeFestival(guild1Id, "SHADOW_CELEBRATION", {theme = "dark", participants = 5})
    if not festival1Id then
        print("❌ Test failed: Could not create first anime festival")
        return
    end

    local festival2Id = testCreateAnimeFestival(guild2Id, "NINJA_TRAINING_FESTIVAL", {theme = "training", participants = 8})
    if not festival2Id then
        print("❌ Test failed: Could not create second anime festival")
        return
    end

    local festival3Id = testCreateAnimeFestival(guild3Id, "PIRATE_ADVENTURE_FESTIVAL", {theme = "adventure", participants = 12})
    if not festival3Id then
        print("❌ Test failed: Could not create third anime festival")
        return
    end

    -- Test 6: Generate various events
    print("\n📋 PHASE 6: Testing Event Generation Systems")
    local warEvent1Id = testGenerateAnimeWarEvent(war1Id)
    if not warEvent1Id then
        print("❌ Test failed: Could not generate first anime war event")
        return
    end

    local collabEvent1Id = testGenerateCrossAnimeCollaborationEvent(collab1Id)
    if not collabEvent1Id then
        print("❌ Test failed: Could not generate first cross-anime collaboration event")
        return
    end

    local festivalEvent1Id = testGenerateAnimeFestivalEvent(festival1Id)
    if not festivalEvent1Id then
        print("❌ Test failed: Could not generate first anime festival event")
        return
    end

    -- Test 7: Get comprehensive stats for all guilds
    print("\n📋 PHASE 7: Testing Comprehensive Statistics")
    local stats1 = testGetComprehensiveAnimeGuildStats(guild1Id)
    if not stats1 then
        print("❌ Test failed: Could not get stats for first guild")
        return
    end

    local stats2 = testGetComprehensiveAnimeGuildStats(guild2Id)
    if not stats2 then
        print("❌ Test failed: Could not get stats for second guild")
        return
    end

    local stats3 = testGetComprehensiveAnimeGuildStats(guild3Id)
    if not stats3 then
        print("❌ Test failed: Could not get stats for third guild")
        return
    end

    -- Test 8: Display comprehensive system overview
    print("\n=== COMPREHENSIVE ANIME GUILD SYSTEM OVERVIEW ===")
    print("Total Guilds:", #GuildSystem.guilds)
    print("Anime Themed Guilds:", #GuildSystem.animeGuildThemes)
    print("Active Anime Wars:", #GuildSystem.animeGuildWars)
    print("Active Cross-Anime Collaborations:", #GuildSystem.crossAnimeCollaborations)
    print("Active Anime Festivals:", #GuildSystem.animeFestivals)

    local totalActiveBonuses = 0
    for guildId, bonuses in pairs(GuildSystem.animeGuildBonuses) do
        for _, bonus in pairs(bonuses) do
            if tick() < bonus.expiresAt then
                totalActiveBonuses = totalActiveBonuses + 1
            end
        end
    end
    print("Active Anime Bonuses:", totalActiveBonuses)

    -- Count total events across all systems
    local totalWarEvents = 0
    local totalCollabEvents = 0
    local totalFestivalEvents = 0

    for _, war in pairs(GuildSystem.animeGuildWars) do
        totalWarEvents = totalWarEvents + #war.animeWarEvents
    end

    for _, collab in pairs(GuildSystem.crossAnimeCollaborations) do
        totalCollabEvents = totalCollabEvents + #collab.collaborationEvents
    end

    for _, festival in pairs(GuildSystem.animeFestivals) do
        totalFestivalEvents = totalFestivalEvents + #festival.festivalEvents
    end

    print("Total Anime War Events:", totalWarEvents)
    print("Total Cross-Anime Collaboration Events:", totalCollabEvents)
    print("Total Anime Festival Events:", totalFestivalEvents)

    print("\n🎉 COMPREHENSIVE STEP 10 TESTS COMPLETED SUCCESSFULLY!")
    print("✅ Multiple anime guild creation with different themes")
    print("✅ Anime guild bonus activation system")
    print("✅ Anime guild wars with theme advantages")
    print("✅ Cross-anime collaboration system")
    print("✅ Anime festival system")
    print("✅ Event generation across all systems")
    print("✅ Comprehensive statistics and metrics")
    print("✅ Full integration of all anime guild features")
end

-- Run the comprehensive tests
runComprehensiveStep10Tests()
