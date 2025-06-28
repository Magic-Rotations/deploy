-------------------------------------------------------------------------------
-- Protection Warrior Rotation
-------------------------------------------------------------------------------
local _G, setmetatable = _G, setmetatable
local TMW = _G.TMW
local A = _G.Action

-- Initialize spec at the top level
A.Spec = A.Spec or {}
local spec = A.Spec

local Create = A.Create
local Unit = A.Unit
local CONST = A.Const
local CONST_AUTOTARGET = CONST.AUTOTARGET
local CONST_FOCUS_PLAYER = CONST.FOCUS_PLAYER
local CONST_FOCUS_PARTY = CONST.FOCUS_PARTY
local CONST_STOPCAST = CONST.STOPCAST
local Player = A.Player
local Pet = A.Pet
local LoC = A.LossOfControl
local EnemyTeam = A.EnemyTeam
local FriendlyTeam = A.FriendlyTeam
local Party = A.Party
local Raid = A.Raid
local Listener = A.Listener
local GetToggle = A.GetToggle
local GameLocale = A.FormatGameLocale(_G.GetLocale())
local player = "player"
local target = "target"
local StdUi = A.StdUi
local Factory = StdUi.Factory
local C_Spell = _G.C_Spell
local GetSpellInfo = C_Spell and C_Spell.GetSpellInfo or _G.GetSpellInfo
local GetSpellCooldown = C_Spell and C_Spell.GetCooldown or _G.GetSpellCooldown
local AOE_THRESHOLD = 3
local FIGHT_REMAINS_CD = 20
local MetaEngine = A.MetaEngine



-- State management system for tracking rotation state between calls
local StateTable = {}

-- Function to get state value with optional default
local function GetState(key, default)
    if StateTable[key] == nil then
        return default
    end
    return StateTable[key]
end

-- Function to set state value
local function SetState(key, value)
    StateTable[key] = value
    return value
end

-- Function to reset all states (useful on target change or combat end)
local function ResetStates()
    wipe(StateTable)
end

-- Create a frame to handle events
local eventFrame = CreateFrame("Frame")

-- Initialize spec functions if they don't exist
if not spec.RegisterSettings then
    spec.RegisterSettings = function(settings)
        A.Data = A.Data or {}
        A.Data.Settings = A.Data.Settings or {}
        A.Data.Settings[A.CurrentProfile] = settings
    end
end

if not spec.RegisterRanges then
    spec.RegisterRanges = function(...) end
end

if not spec.RegisterEvents then
    spec.RegisterEvents = function(...) end
end

if not spec.RegisterAuras then
    spec.RegisterAuras = function(...) end
end

if not spec.RegisterCombatLogEvent then
    spec.RegisterCombatLogEvent = function(...) end
end

-- Set up event handling directly
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_REGEN_DISABLED" then
            -- Reset states when entering combat
            ResetStates()
        elseif event == "PLAYER_REGEN_ENABLED" then
            -- Reset states when leaving combat
            ResetStates()
        end
end)

-- Fix 1: Add Unit.Exists function if it doesn't exist
if not Unit.Exists then
    Unit.Exists = function(self, unit)
        return UnitExists(unit)
    end
end





-- Add a last cast tracking system
local lastCastSpellID = 0
local lastCastTime = 0

-- Helper function to check if a spell was last cast
local function WasLastCast(spellObj)
    if not spellObj then return false end
    
    -- Check if the spell has a built-in WasLastCast method
    if spellObj.WasLastCast and type(spellObj.WasLastCast) == "function" then
        return spellObj:WasLastCast()
    end
    
    -- Fallback to our custom implementation
    if spellObj.ID and lastCastSpellID == spellObj.ID and GetTime() - lastCastTime < 1.5 then
        return true
    end
    
    return false
end

-- Register combat log events
spec:RegisterCombatLogEvent(function(...)
    local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = ...
    if sourceGUID == UnitGUID("player") then
        if subevent == "SPELL_CAST_SUCCESS" then
            -- Track successful spell casts
            local spellID, spellName = select(12, ...)
            lastCastSpellID = spellID
            lastCastTime = GetTime()
        end
    end
end)


-- Constants for specializations
if not _G.ACTION_CONST_WARRIOR_PROTECTION then
    _G.ACTION_CONST_WARRIOR_PROTECTION = 73
end

-- Talent IDs for Protection
local TALENT = {
    -- Protection Core
    anger_management = 152278,
    avatar = 107574,
    battle_stance = 386164,
    barbaric_training = 386028,
    berserker_rage = 18499,
    berserker_shout = 384100,
    bitter_immunity = 383762,
    booming_voice = 202743,
    bolster = 280001,
    bounding_stride = 202163,
    challenging_shout = 1161,
    champions_bulwark = 386328,
    champions_spear = 376079,
    crashing_thunder = 335070,
    defensive_stance = 386208,
    demoralizing_shout = 1160,
    devastate = 20243,
    disrupting_shout = 386071,
    dragon_charge = 206572,
    heavy_repercussions = 203177,
    ignore_pain = 190456,
    immovable_object = 394307,
    impenetrable_wall = 384072,
    impending_victory = 202168,
    intervene = 3411,
    intimidating_shout = 5246,
    last_stand = 12975,
    massacre = 281001,
    pummel = 6552,
    rallying_cry = 97462,
    ravager = 228920,
    rend = 394062,
    revenge = 6572,
    seismic_reverberation = 382956,
    shield_block = 2565,
    shield_charge = 385952,
    shield_slam = 23922,
    shield_wall = 871,
    shockwave = 46968,
    spell_block = 392966,
    spell_reflection = 23920,
    storm_bolt = 107570,
    sudden_death = 29725,
    taunt = 355,
    thunder_clap = 6343,
    thunderous_roar = 384318,
    unnerving_focus = 384042,
    unstoppable_force = 275336,
    victory_rush = 34428,
    whirlwind = 1680,
    wrecking_throw = 384110,
    devastator = 236279,
    
    -- Mountain Thane
    avatar_of_the_storm = 437134,
    burst_of_power = 437118,
    flashing_skies = 437079,
    gathering_clouds = 436201,
    ground_current = 436148,
    keep_your_feet_on_the_ground = 438590,
    lightning_strikes = 434969,
    snap_induction = 456270,
    steadfast_as_the_peaks = 434970,
    storm_bolts = 436162,
    storm_shield = 438597,
    strength_of_the_mountain = 437068,
    thorims_might = 436152,
    thunder_blast = 435607,
    
    -- Colossus
    arterial_bleed = 440995,
    boneshaker = 429639,
    colossal_might = 429634,
    demolish = 436358,
    dominance_of_the_colossus = 429636,
    earthquaker = 440992,
    martial_expert = 429638,
    mountain_of_muscle_and_scars = 429642,
    no_stranger_to_pain = 429644,
    one_against_many = 429637,
    practiced_strikes = 429647,
    precise_might = 431548,
    tide_of_battle = 429641,
}

-- Buff IDs for Protection
local BUFF = {
    -- Protection Buffs
    avatar = 107574,
    battle_stance = 386164,
    berserker_rage = 18499,
    berserker_shout = 384100,
    bounding_stride = 202164,
    defensive_stance = 386208,
    ignore_pain = 190456,
    last_stand = 12975,
    rallying_cry = 97463,
    ravager = 228920,
    revenge = 5302, -- Revenge proc buff
    seeing_red = 437517, -- Seeing Red buff
    shield_block = 132404,
    shield_wall = 871,
    spell_block = 392966,
    spell_reflection = 23920,
    sudden_death = 52437, -- Sudden Death buff
    victorious = 32216,
    battle_shout = 6673,
    devastator = 236279,
    violent_outburst = 388539, -- Added missing Violent Outburst buff ID
    
    -- Mountain Thane Buffs
    thunder_blast = 435615,
    burst_of_power = 437121,
    keep_your_feet_on_the_ground = 438591,
    
    -- Colossus Buffs
    colossal_might = 440989,
    
    -- Set Bonuses
    fervid = 425517,
    fervid_opposition = 427413,
    earthen_tenacity = 410218,
    luck_of_the_draw = 1218163,
    -- Trinket Buffs
    InnerResilience = 450706, -- Tome of Light's Devotion defensive buff
    InnerRadiance = 450720,   -- Tome of Light's Devotion offensive buff
}

-- Debuff IDs for Protection
local DEBUFF = {
    -- Protection Debuffs
    berserker_rage = 18499,
    berserker_shout = 384100,
    bounding_stride = 202164,
    defensive_stance = 386208,
    demoralizing_shout = 1160,
    devastate = 20243,
    disrupting_shout = 386071,
    dragon_charge = 206572,
    ignore_pain = 190456,
    impending_victory = 202168,
    intervene = 3411,
    intimidating_shout = 5246,
    last_stand = 12975,
    pummel = 6552,
    rallying_cry = 97462,
    ravager = 228920,
    rend = 394062,
    revenge = 6572,
    shield_block = 2565,
    shield_charge = 385952,
    shield_slam = 23922,
    shield_wall = 871,
    shockwave = 46968,
    spell_block = 392966,
    spell_reflection = 23920,
    storm_bolt = 107570,
    taunt = 355,
    thunder_clap = 6343,
    thunderous_roar = 384318,
    victory_rush = 34428,
    whirlwind = 1680,
    wrecking_throw = 384110,
    
    -- Additional Debuffs
    deep_wounds = 115767,
    concussive_blows = 383116,
    punish = 275335,
    focused_assault = 206891,
}

-- Initialize Protection Warrior spells
Action[ACTION_CONST_WARRIOR_PROTECTION] = {
    -- Basic abilities
    Avatar = Create({ Type = "Spell", ID = 107574 }),
    BattleShout = Create({ Type = "Spell", ID = 6673 }),
    BattleShoutMeta = Create({ Type = "Spell", ID = 6673, FixedTexture = 133667, Macro = "/cast Battle Shout" }),
    BattleStance = Create({ Type = "Spell", ID = 386164 }),
    BerserkerRage = Create({ Type = "Spell", ID = 18499 }),
    BerserkerShout = Create({ Type = "Spell", ID = 384100 }),
    BitterImmunity = Create({ Type = "Spell", ID = 383762 }),
    ChallengingShout = Create({ Type = "Spell", ID = 1161 }),
    ChallengingShoutMeta = Create({ Type = "Spell", ID = 1161, FixedTexture = 133658, Macro = "/cast Challenging Shout" }),
    ChampionsSpear = Create({ Type = "Spell", ID = 376079 }),
    Charge = Create({ Type = "Spell", ID = 100 }),
    DefensiveStance = Create({ Type = "Spell", ID = 386208 }),
    DemoralizingShout = Create({ Type = "Spell", ID = 1160 }),
    Devastate = Create({ Type = "Spell", ID = 20243 }),
    DisruptingShout = Create({ Type = "Spell", ID = 386071 }),
    Execute = Create({ Type = "Spell", ID = 163201 }),
    HeroicLeap = Create({ Type = "Spell", ID = 6544 }),
    HeroicThrow = Create({ Type = "Spell", ID = 57755 }),
    IgnorePain = Create({ Type = "Spell", ID = 190456 }),
    ImpendingVictory = Create({ Type = "Spell", ID = 202168 }),
    Intervene = Create({ Type = "Spell", ID = 3411 }),
    IntimidatingShout = Create({ Type = "Spell", ID = 5246 }),
    LastStand = Create({ Type = "Spell", ID = 12975 }),
    PiercingHowl = Create({ Type = "Spell", ID = 12323 }),
    Pummel = Create({ Type = "Spell", ID = 6552 }),
    RallyingCry = Create({ Type = "Spell", ID = 97462 }),
    Ravager = Create({ Type = "Spell", ID = 228920 }),
    Rend = Create({ Type = "Spell", ID = 394062 }),
    Revenge = Create({ Type = "Spell", ID = 6572 }),
    ShieldBlock = Create({ Type = "Spell", ID = 2565 }),
    ShieldCharge = Create({ Type = "Spell", ID = 385952 }),
    ShieldSlam = Create({ Type = "Spell", ID = 23922 }),
    ShieldWall = Create({ Type = "Spell", ID = 871 }),
    Shockwave = Create({ Type = "Spell", ID = 46968 }),
    Slam = Create({ Type = "Spell", ID = 1464 }),  -- Add Slam definition
    SpellBlock = Create({ Type = "Spell", ID = 392966 }),
    SpellReflection = Create({ Type = "Spell", ID = 23920 }),
    StormBolt = Create({ Type = "Spell", ID = 107570 }),
    Taunt = Create({ Type = "Spell", ID = 355 }),
    ThunderClap = Create({ Type = "Spell", ID = 6343 }),
    ThunderousRoar = Create({ Type = "Spell", ID = 384318 }),
    VictoryRush = Create({ Type = "Spell", ID = 34428 }),
    Whirlwind = Create({ Type = "Spell", ID = 1680 }),
    WreckingThrow = Create({ Type = "Spell", ID = 384110 }),
    -- Add missing active spells
    -- Thunder Blast
    ThunderBlast = Create({ Type = "Spell", ID = 435615, FixedTexture = 136105 }),
    ThunderBlastMeta = Create({ Type = "Spell", ID = 435615, FixedTexture = 133663, Macro = "/cast Thunder Blast", Desc = "Thunder Blast" }),
    -- Demolish
    Demolish = Create({ Type = "Spell", ID = 436358 }),
    -- Lightning Strikes (passive, but included for completeness)
    LightningStrikes = Create({ Type = "Spell", ID = 434969 }),

}

-- Setup local A reference to Protection spells for cleaner code
local A = setmetatable(Action[ACTION_CONST_WARRIOR_PROTECTION], { __index = Action })

-- Table for auto-switch nearest target spell
local AutoSwitchNearest = {
    RangeSpell = "Slam",  -- Changed to ThunderClap which is definitely in the spell list
}


local TrinketTypes = {
    NONE = 0,
    DEFENSIVE = 1,
    BURST = 2,
}

-- Define Interrupts table
local Interrupts = {
    {spellID = 6552, spell = A.Pummel, useKick = true, useCC = false, useRacial = false, Boss = true, NeedTarget = true}, -- Pummel
    {spellID = 46968, spell = A.Shockwave, useKick = true, useCC = true, useRacial = false, Boss = false, NeedTarget = false, Range = 8}, -- Shockwave
    {spellID = 107570, spell = A.StormBolt, useKick = true, useCC = true, useRacial = false, Boss = false, NeedTarget = true}, -- Storm Bolt
}

-- Define defensive actions
local DefensiveActions = {
    Trinket1 = {
        Type = "Personal",
        SpellType = "Trinket",
        UseHP = function() 
            return GetToggle(2, "Trinket1HP") or 60
        end,
        Priority = 6,
        Spell = A.Trinket1,
        ShouldUse = function()
            local trinketTypes = GetToggle(2, "TrinketsTypes")
            -- Only use if configured as defensive
            if not trinketTypes or trinketTypes[1] ~= TrinketTypes.DEFENSIVE then
                return false
            end
            
            -- Check if trinket is enabled in toggles
            if not GetToggle(1, "Trinkets")[1] then
                return false
            end
            
            -- Use in emergency situations
            if A.is_critical then return true end
            
            -- Use for dangerous mechanics
            if A.dangerous_cast_incoming then return true end
            
            -- Use in emergency threat situations
            if A.threat_emergency then return true end
            
            return false
        end,
        UseFor = {
            -- Tank buster abilities
            [422245] = { type = "targeted", name = "Binding Grasp" },
            [448515] = { type = "targeted", name = "Charged Smash" },
            [435165] = { type = "targeted", name = "Ground Slam" },
            [473351] = { type = "targeted", name = "Crushing Strike" },
            [469478] = { type = "targeted", name = "Devastating Slam" },
            [465666] = { type = "targeted", name = "Earth Shatter" },
            [1215065] = { type = "targeted", name = "Brutal Haymaker" },
            [291878] = { type = "targeted", name = "Aerial Dash" },
            [263628] = { type = "targeted", name = "Arcane Burst" },
            [320069] = { type = "targeted", name = "Mortal Strike" },
            [323515] = { type = "targeted", name = "Hateful Strike" },
            [324079] = { type = "targeted", name = "Reaping Scythe" },
            [331316] = { type = "targeted", name = "Hammer of Death" }
        }
    },
    Trinket2 = {
        Type = "Personal",
        SpellType = "Trinket",
        UseHP = function() 
            return GetToggle(2, "Trinket2HP") or 60
        end,
        Priority = 6,
        Spell = A.Trinket2,
        ShouldUse = function()
            local trinketTypes = GetToggle(2, "TrinketsTypes")
            -- Only use if configured as defensive
            if not trinketTypes or trinketTypes[2] ~= TrinketTypes.DEFENSIVE then
                return false
            end
            
            -- Check if trinket is enabled in toggles
            if not GetToggle(1, "Trinkets")[2] then
                return false
            end
            
            -- Use in emergency situations
            if A.is_critical then return true end
            
            -- Use for dangerous mechanics
            if A.dangerous_cast_incoming then return true end
            
            -- Use in emergency threat situations
            if A.threat_emergency then return true end
            
            return false
        end,
        UseFor = {
            -- Tank buster abilities
            [422245] = { type = "targeted", name = "Binding Grasp" },
            [448515] = { type = "targeted", name = "Charged Smash" },
            [435165] = { type = "targeted", name = "Ground Slam" },
            [473351] = { type = "targeted", name = "Crushing Strike" },
            [469478] = { type = "targeted", name = "Devastating Slam" },
            [465666] = { type = "targeted", name = "Earth Shatter" },
            [1215065] = { type = "targeted", name = "Brutal Haymaker" },
            [291878] = { type = "targeted", name = "Aerial Dash" },
            [263628] = { type = "targeted", name = "Arcane Burst" },
            [320069] = { type = "targeted", name = "Mortal Strike" },
            [323515] = { type = "targeted", name = "Hateful Strike" },
            [324079] = { type = "targeted", name = "Reaping Scythe" },
            [331316] = { type = "targeted", name = "Hammer of Death" }
        }
    },
    ShieldWall = {
        Type = "Personal",
        SpellType = "Defensive",
        UseHP = function()
            return GetToggle(2, "ShieldWallHP") or 40
        end,
        Priority = 5,
        Spell = A.ShieldWall,
        UseFor = {
            -- Tank buster abilities
            [422245] = { type = "targeted", name = "Binding Grasp" },
            [448515] = { type = "targeted", name = "Charged Smash" },
            [435165] = { type = "targeted", name = "Ground Slam" },
            [473351] = { type = "targeted", name = "Crushing Strike" },
            [469478] = { type = "targeted", name = "Devastating Slam" },
            [465666] = { type = "targeted", name = "Earth Shatter" },
            [1215065] = { type = "targeted", name = "Brutal Haymaker" },
            [291878] = { type = "targeted", name = "Aerial Dash" },
            [263628] = { type = "targeted", name = "Arcane Burst" },
            [320069] = { type = "targeted", name = "Mortal Strike" },
            [323515] = { type = "targeted", name = "Hateful Strike" },
            [324079] = { type = "targeted", name = "Reaping Scythe" },
            [331316] = { type = "targeted", name = "Hammer of Death" }
        }
    },
    ImpendingVictory = {
        Type = "Personal",
        SpellType = "Defensive",
        UseHP = function()
            return GetToggle(2, "ImpendingVictoryHP") or 70
        end,
        Priority = 4,
        Spell = A.ImpendingVictory,
    },
    LastStand = {
        Type = "Personal",
        SpellType = "Defensive",
        UseHP = function()
            return GetToggle(2, "LastStandHP") or 30
        end,
        Priority = 3,
        Spell = A.LastStand,
    },
}

-- Helper function for stance management
local function ManageStances(icon)
    -- Don't switch stances if not in combat
    if not A.IsInValidCombat() then return false end
    
    local hp = Unit(player):HealthPercent()
    local hasShieldBlock = (BUFF.shield_block and Unit(player):HasBuffs(BUFF.shield_block)) or 0
    local hasShieldWall = (BUFF.shield_wall and Unit(player):HasBuffs(BUFF.shield_wall)) or 0
    local hasAvatar = (BUFF.avatar and Unit(player):HasBuffs(BUFF.avatar)) or 0
    
    -- Check current stance
    local inDefensiveStance = Unit(player):HasBuffs(BUFF.defensive_stance) > 0
    local inBattleStance = Unit(player):HasBuffs(BUFF.battle_stance) > 0
    
    
    -- Conditions to switch to Battle Stance
    local switchToBattle = hp >= 80 and 
                          hasShieldBlock > 0 and 
                          (hasShieldWall > 0 or hasAvatar > 0)
    
    -- Conditions to stay/switch to Defensive Stance
    local needDefensive = hp < 70 or 
                         hasShieldBlock == 0
    
       
    -- Make stance switches
    if needDefensive and not inDefensiveStance then
        if A.DefensiveStance:IsReady(player) then
            return A.DefensiveStance:Show(icon)
        end
    elseif switchToBattle and not inBattleStance then
        if A.BattleStance:IsReady(player) then
            return A.BattleStance:Show(icon)
        end
    end
    
    return false
end
-- Enhanced useTrinkets function for Vengeance
local function handleTrinketUsage()
    -- Get trinket configuration
    local trinket1Type = GetToggle(2, "Trinket1Type") or 0
    local trinket2Type = GetToggle(2, "Trinket2Type") or 0
    local trinketToggles = GetToggle(1, "Trinkets") or {false, false}
    
    -- Early exit if trinkets are disabled
    if not trinketToggles[1] and not trinketToggles[2] then
        return false
    end
    
    
    -- Get burst mode setting
    local burstMode = GetToggle(1, "Burst") or "Auto"
    
    -- Check if we should use burst trinkets
    local shouldUseBurst = false
    if burstMode == "Everything" then
        shouldUseBurst = true
    elseif burstMode == "Auto" then
        -- Use burst trinkets on boss or player targets
        shouldUseBurst = UnitExists("target") and (Unit("target"):IsBoss() or UnitIsPlayer("target"))
    end
    
    -- Tank-specific conditions for using burst trinkets
    local healthPercent = UnitHealth("player") / UnitHealthMax("player") * 100
    local canUseBurst = healthPercent > 50 -- Only use burst trinkets when above 50% health
    
    -- Special handling for Tome of Light's Devotion trinket
    local hasTomeOfLightsDevotionTrinket = false
    local tomeSlot = nil
    
    -- Check trinket 1 for Tome of Light's Devotion
    local trinket1ID = GetInventoryItemID("player", 13)
    if trinket1ID == 219309 then
        hasTomeOfLightsDevotionTrinket = true
        tomeSlot = 1
    end
    
    -- Check trinket 2 for Tome of Light's Devotion
    local trinket2ID = GetInventoryItemID("player", 14)
    if trinket2ID == 219309 then
        hasTomeOfLightsDevotionTrinket = true
        tomeSlot = 2
    end
    
    -- Special logic for Tome of Light's Devotion
    if hasTomeOfLightsDevotionTrinket and tomeSlot then
        -- Check for buffs
        local hasResilience = Unit("player"):HasBuffs(BUFF.InnerResilience, true) > 0
        local has50Verses = Unit("player"):HasBuffs(450696, true) > 0
        
        -- Check trinket cooldown directly using GetInventoryItemCooldown
        local itemSlot = tomeSlot == 1 and 13 or 14
        local itemStart, itemDuration, itemEnabled = GetInventoryItemCooldown("player", itemSlot)
        local itemCDRemaining = itemStart > 0 and (itemStart + itemDuration - GetTime()) or 0
        local isTrinketReady = itemCDRemaining <= 0 and itemEnabled == 1
        
        -- If we have Inner Resilience buff, use the trinket to swap to Inner Radiance
        if (hasResilience or has50Verses) and isTrinketReady then
            if tomeSlot == 1 then
                return A.Trinket1
            elseif tomeSlot == 2 then
                return A.Trinket2
            end
        end
        
        -- Skip normal trinket logic for the Tome slot
        if tomeSlot == 1 then
            trinketToggles[1] = false
        elseif tomeSlot == 2 then
            trinketToggles[2] = false
        end
    end
    
    -- Handle Trinket 1
    if trinketToggles[1] and A.Trinket1:IsReady("player") then
        if trinket1Type == TrinketTypes.BURST and shouldUseBurst and canUseBurst then
            return A.Trinket1
        elseif trinket1Type == TrinketTypes.DEFENSIVE and healthPercent <= GetToggle(2, "Trinket1HP") then
            return A.Trinket1
        end
    end
    
    -- Handle Trinket 2
    if trinketToggles[2] and A.Trinket2:IsReady("player") then
        if trinket2Type == TrinketTypes.BURST and shouldUseBurst and canUseBurst then
            return A.Trinket2
        elseif trinket2Type == TrinketTypes.DEFENSIVE and healthPercent <= GetToggle(2, "Trinket2HP") then
            return A.Trinket2
        end
    end
    
    return false
end


local function BattleShoutCheck(icon)
    if A.BattleShout:IsReady("player") then
        local groupSize = IsInGroup() and GetNumGroupMembers() or 1
        local validMembers = 0
        
        -- Check player first
        if BUFF.battle_shout and A.Unit("player"):HasBuffs(BUFF.battle_shout) == 0 and A.Unit("player"):GetRange() <= 40 then
            validMembers = validMembers + 1
        end
        
        -- Check party members
        if IsInGroup() then
            for i = 1, groupSize do
                local unit = IsInRaid() and "raid"..i or "party"..i
                if UnitExists(unit) and not UnitIsDeadOrGhost(unit) then
                    if A.Unit(unit):GetRange() <= 40 and BUFF.battle_shout and A.Unit(unit):HasBuffs(BUFF.battle_shout) == 0 then
                        validMembers = validMembers + 1
                    end
                end
            end
        end
        
        -- Cast if at least 1 valid member needs buff
        if validMembers >= 1 then
            if MetaEngine and MetaEngine.IsHealthy and MetaEngine:IsHealthy() then
                return A.BattleShoutMeta:Show(icon)
            else
                return A.BattleShout:Show(icon)
            end
        end
    end
end

-- Helper function to determine number of targets
local function GetNumEnemies()
    -- Safely get enemy count with fallback
    local enemyCount = A.GetEnemyCount()
    if not enemyCount then
        return 0
    end
    
    -- Validate the count is a number
    if type(enemyCount) ~= "number" then
        return 0
    end
    
    -- Ensure the count is non-negative
    if enemyCount < 0 then
        return 0
    end
    
    return enemyCount
end

-- Add these helper functions for raid event simulation with safe checks
function A.RaidEventAddsIn()
    return 999 -- Default to a large number if no adds expected
end

function A.RaidEventAddsRemains()
    return 0 -- Default to 0 if no adds present
end

function A.RaidEventAddsUp()
    local numEnemies = GetNumEnemies()
    return numEnemies > 1
end

function A.RaidEventAddsCount()
    return 0 -- Default to 0
end

function A.TimeToFightRemains()
    return 999 -- Default to a large number
end

-- Add this function to validate if spell is actually usable
function A.IsSpellUsable(spellObject, unit)
    unit = unit or "target"
    
    if not spellObject then
        return false
    end
    
    if not spellObject.ID then
        return false
    end
    
    -- Check if spell is actually in spellbook
    local spellName = GetSpellInfo(spellObject.ID)
    if not spellName then
        return false
    end
    
    -- Check if spell is usable
    local isUsable, notEnoughResources = IsUsableSpell(spellObject.ID)
    if not isUsable then
        return false
    end
    
    -- Check if on cooldown
    local start, duration, enabled = GetSpellCooldown(spellObject.ID)
    local onCooldown = start > 0 and duration > 0
    if onCooldown then
        return false
    end
    
    return true
end

-- Update the IsReady function to use our validation
local originalIsReady = A.IsReady
if type(originalIsReady) == "function" then
    function A:IsReady(unit, checkRange, checkUsable)
        local result = originalIsReady(self, unit, checkRange, checkUsable)
        if not result and A.IsSpellUsable(self, unit) then
            return true
        end
        return result
    end
end

-- Helper function to check for melee range properly
local function InMeleeRange(unit)
    -- Default to target if no unit specified
    unit = unit or "target"
    
    -- Validate unit exists and is valid
    if not unit or not UnitExists(unit) then
        return false
    end
    
    -- Check if we can attack the unit
    if not UnitCanAttack("player", unit) then
        return false
    end
    
    -- Safely get range with fallback
    local unitObj = Unit(unit)
    if not unitObj then
        return false
    end
    
    local range = unitObj:GetRange()
    if not range then
        return false
    end
    
    return range <= 5
end


-- Helper function to safely get player rage using WoW's native functions
local function GetPlayerRage()
    -- Use WoW's native UnitPower function with POWER_RAGE (1)
    local rage = UnitPower("player", 1)
    local maxRage = UnitPowerMax("player", 1)
    
    -- Validate the values
    if not rage or not maxRage then
        return 0
    end
    
    -- Convert to percentage if needed
    -- local ragePercent = (rage / maxRage) * 100
    
    return rage
end

-- Helper function to safely check unit buffs/debuffs
local function SafeUnitCheck(unit, checkType, spellID)
    if not unit or not UnitExists(unit) then return 0 end
    if not spellID then return 0 end
    
    if checkType == "buff" then
        return Unit(unit):HasBuffs(spellID) or 0
    elseif checkType == "debuff" then
        return Unit(unit):HasDeBuffs(spellID) or 0
    end
    return 0
end

-- Helper function for aggro management
local function AggroManagement(icon)
    -- Check if we're in a group
    if not IsInGroup() then return false end
    
    -- Get mouseover target info
    local mouseoverTarget = "mouseover"
    if not UnitExists(mouseoverTarget) or not UnitCanAttack("player", mouseoverTarget) or UnitIsDead(mouseoverTarget) then
        return false
    end
    
    -- Get mouseover target threat status with safe check
    local threatStatus = UnitThreatSituation("player", mouseoverTarget)
    if not threatStatus then threatStatus = -1 end
    
    -- If we don't have aggro (threat status < 2)
    if threatStatus < 2 then
        local distance = A.Unit(mouseoverTarget):GetRange() or 100
        
        -- Check if we can use Heroic Throw (8-30 yard range)
        if distance >= 8 and distance <= 30 and A.HeroicThrow:IsReady() then
            return A.HeroicThrow:Show(icon)
        end
        
        -- Check if we can use Taunt (30 yard range) - but never in raids
        if distance <= 30 and A.Taunt:IsReady() and not IsInRaid() then
            return A.Taunt:Show(icon)
        end
    end
    
    -- Check for multiple targets in range
    local targetsInRange = 0
    local targetsWithoutAggro = 0
    
    -- Scan through all nameplates with safe checks
    for i = 1, 40 do
        local unit = "nameplate" .. i
        if UnitExists(unit) and UnitCanAttack("player", unit) and not UnitIsDead(unit) then
            local distance = A.Unit(unit):GetRange() or 100
            local threatStatus = UnitThreatSituation("player", unit)
            if not threatStatus then threatStatus = -1 end
            
            -- Count targets in range
            if distance <= 10 then
                targetsInRange = targetsInRange + 1
                if threatStatus < 2 then -- Less than 2 means we don't have aggro
                    targetsWithoutAggro = targetsWithoutAggro + 1
                end
            end
        end
    end
    
    -- Handle multiple targets without aggro
    if targetsWithoutAggro > 1 and targetsInRange > 1 then
        if A.ChallengingShout:IsReady() then
            if MetaEngine and MetaEngine.IsHealthy and MetaEngine:IsHealthy() then
                return A.ChallengingShoutMeta:Show(icon)
            else
                return A.ChallengingShout:Show(icon)
            end
        end
    end
    
    return false
end

-- Table of important spell IDs to reflect
local SpellsToReflect = {
    
    -- Cinderbrew Meadery
    436640, -- Burning Ricochet (Goldie Baronbottom)
    437733, -- Boiling Flames (Venture Co. Pyromaniac)
    
    -- Liberation of Undermine
    1219386, -- Scrap Rockets (Scrapmaster)
    460847, -- Electric Blast (Reel Assistant)
    
    -- Operation: Floodgate
    473126, -- Mudslide
    469811, -- Backwash
    465871, -- Blood Bolt
    1214468, -- Trickshot
    474388, -- Flamethrower
    465595, -- Lightning Bolt
    462776, -- Surveying Beam
    
    -- Cinderbrew Vault 
    436640, -- Censoring Gear (Turned Speaker)
    437733, -- Boiling Flames (Venture Co. Pyromaniac)
    
    -- Darkflame Cleft
    422700, -- Extinguishing Gust
    421638, --  Wicklighter Barrage
    469620, --  Creeping Shadow
    428563, --  Flame Bolt
    443694, --  Crude Weapons
    423479, --  Wicklighter Bolt
    426677, --  Candleflame Bolt
    
    -- The Rookery
    430805, -- Arcing Void
    430186, -- Seeping Corruption
    430238, -- Void Bolt
    430109, -- Lightning Bolt
    427616, -- Energized Barrage
    467907, -- Festering Void
    
    -- Priory of the Sacred Flame
    424420, -- Cinderblast
    424421, -- Fireball
    423015, -- Castigator's Shield
    423536, -- Holy Smite
    427357, -- Holy Smite
    427469, -- Fireball
    427900, -- Molten Pool
    427951, -- Seal of Flame

    -- The MOTHERLODE!!
    260323, -- Alpha Cannon
    263628, -- Charged Shield
    280604, -- Iced Spritzer
    262270, -- Caustic Compound
    1215934, -- Rock Lance
    1215916, -- Mind Lash
    268846, -- Echo Blade

    
    -- Theater of Pain
    1216475, -- Necrotic Bolt (Battlefield Ritualist)
    1222949, -- Well of Darkness
    323608, -- Dark Devastation
    324589, -- Death Bolt
    341969, -- Withering Discharge
    330697, -- Decaying Strike
    330784, -- Necrotic Bolt
    333299, -- Curse of Desolation
    330875, -- Spirit Frost
    330810, -- Bind Soul
    
    -- Operation: Mechagon - Workshop
    294195, -- Arcing Zap
    293827, -- Giga-Wallop
}

local SpellsToBlock = {
    -- Undermine
    460388, -- Backfire (Magic)
    1214190, -- Eruption Stomp (Magic) - Tankbuster from godzilla
    465466, -- Fiery Wave (Magic)
    1217933, -- Lightning Bash (Physical and Magic) - Tankbuster from kong, both hits are blockable
    473652, -- Scrapbomb (Magic) - Group soak
    1217126, -- Lingering Voltage (Magic) - Damage from clicking pillar
    1217964, -- Meltdown (Magic) - Initial hit and DoT are spell blockable
    1219386, -- Scrap Rockets (Magic) - Deflect
    1214910, -- Pyro Party Pack (Magic)
    460847, -- Electric Blast (Magic) - Deflect
    460427, -- Pay-Line (Magic)
    474731, -- Traveling Flames (Magic)
    
    -- Cinderbrew Meadery
    432198, -- Blazing Belch (Magic) - Frontal cast
    432196, -- Hot Honey (Magic) - Ground AoE
    439991, -- Spouting Stout (Magic) - Circle AoE on ground
    440141, -- Honey Marinade (Magic)
    436640, -- Burning Ricochet (Magic)
    435788, -- Cinder-BOOM! (Magic)
    442484, -- Let It Hail! (Magic)
    441344, -- Bee-Zooka (Magic) - From Bee Wrangler
    453810, -- Explosive Brew (Magic) - Initial hit only, DoT not blockable
    463218, -- Volatile Keg (Magic) - Initial hit only, DoT not blockable
    440687, -- Honey Volley (Magic) - From Royal Jelly Purveyor
    440887, -- Rain of Honey (Magic) - From Royal Jelly Purveyor
    441242, -- Free Samples? (Magic) - From Taste Tester
    434707, -- Cinderbrew Toss (Magic) - Ground AoE, causes disorientation
    442589, -- Beeswax (Magic) - From Venture Co. Honey Harvester
    437733, -- Boiling Flames (Magic) - From Venture Co. Pyromaniac, reflects damage
    443491, -- Final Sting (Magic) - From Worker Bee

    -- Darkflame Cleft
    422274, -- Cave-In (Magic)
    425394, -- Dousing Breath (Magic)
    422700, -- Extinguishing Gust (Magic) - Deflectable
    421638, -- Wicklighter Barrage (Magic) - Deflectable
    420919, -- Eerie Molds (Magic)
    427100, -- Umbral Slash (Magic)
    424322, -- Explosive Flame (Magic) - From Blazing Fiend
    428563, -- Flame Bolt (Magic) - Reflects damage to mob - From Kobold Flametender
    423479, -- Wicklighter Bolt (Magic) - Reflects damage to mob - From Royal Wicklighter
    422393, -- Suffocating Darkness (Magic) - Swirly after mob dies - From Skittering Darkness
    426677, -- Candleflame Bolt (Magic) - Reflects damage to mob - From Sootsnout
    1218117, -- Massive Stomp (Magic) - From Torchsnarl
    430171, -- Quenching Blast (Magic) - From Wandering Candle

    -- Operation: Mechagon - Workshop
    294961, -- Blazing Chomp (Magic) - Initial hit only, follow-up DoT not blockable
    292035, -- Explosive Leap (Magic)
    291949, -- Venting Flames (Magic) - Can hide behind fresh box
    294860, -- Blossom Blast (Magic) - Targets closest player, reflects 1 tick back
    291928, -- Giga-Zap (Magic) - Initial hit only, follow-up DoT not blockable
    291878, -- Pulse Blast (Magic) - Reflects damage back to boss
    473440, -- High Explosive Rockets (Magic) - From Blastatron X-80
    294195, -- Arcing Zap (Magic) - From Defense Bot Mk III
    297127, -- Short Out (Magic) - From Defense Bot Mk III
    293827, -- Giga-Wallop (Magic) - From Mechagon Tinkerer
    1215412, -- Corrosive Gunk (Magic) - From Metal Gunk
    473440, -- High Explosive Rockets (Magic) - From Spider Tank
    1215410, -- Mega Drill (Magic) - From Waste Processing Unit

    -- The MOTHERLODE!!
    1217294, -- Shocking Claw (Magic)
    259474, -- Searing Reagent (Magic) - Boss 'autoattack'
    260323, -- Alpha Cannon (Magic) - Reflects damage back to boss
    276234, -- Micro Missiles (Magic)
    263628, -- Charged Shield (Magic) - From Mechanized Peacekeeper
    280604, -- Iced Spritzer (Magic)
    262270, -- Caustic Compound (Magic) - From Venture Co. Alchemist, initial hit only, DoT not blockable
    1215934, -- Rock Lance (Magic) - From Venture Co. Earthshaper, reflects damage to mob
    1215916, -- Mind Lash (Magic) - From Venture Co. Mastermind, reflects damage to mob
    269100, -- Charged Shot (Magic) - From Venture Co. War Machine
    268846, -- Echo Blade (Magic) - From Weapons Tester, reflects damage to mob

    -- Operation: Floodgate
    473351, -- Electrocrush (Magic) - Initial hit blockable, follow-up DoT is not
    473081, -- Awaken the Swamp (Magic)
    473126, -- Mudslide (Magic) - Deflectable
    472794, -- Razorchoke Vines (Magic)
    465982, -- Turbo Bolt (Magic) - Stuns for 1sec
    465462, -- Turbo Charge (Magic)
    469819, -- Bubble Burp (Magic)
    465871, -- Blood Bolt (Magic) - Does huge damage back to mob
    465830, -- Warp Blood (Magic)
    1216611, -- Battery Discharge (Magic)
    465666, -- Sparkslam (Magic)
    468727, -- Seaforium Charge (Magic)
    465595, -- Lightning Bolt (Magic) - Reflects damage back to mob
    462776, -- Surveying Beam (Magic) - Reflects damage back to mob

    -- Priory of the Sacred Flame
    424460, -- Ember Storm (Magic)
    424421, -- Fireball (Magic) - Reflects damage back to mini-boss
    423015, -- Castigator's Shield (Magic) - Reflects damage back to boss
    423019, -- Castigator's Detonation (Magic)
    423665, -- Embrace the Light (Magic)
    451606, -- Holy Flame (Magic)
    423536, -- Holy Smite (Magic) - Reflects damage back to boss
    423547, -- Inner Fire (Magic)
    425554, -- Purify (Magic)
    435156, -- Light Expulsion (Magic) - 60yd AoE when Risen mobs die
    427597, -- Seal of Light's Fury (Magic) - From Ardent Paladin
    448791, -- Sacred Toll (Magic) - From Ardent Paladin
    427357, -- Holy Smite (Magic) - From Devout Priest, reflects damage back
    427469, -- Fireball (Magic) - From Fanatical Conjuror, reflects damage back
    427472, -- Flamestrike (Magic) - From Fanatical Conjuror
    427897, -- Heat Wave (Magic) - From Forge Master Damian
    427900, -- Molten Pool (Magic) - From Forge Master Damian
    427951, -- Seal of Flame (Magic) - From Forge Master Damian, reflects damage back
    448492, -- Thunderclap (Magic) - From Guard Captain Suleyman
    427601, -- Burst of Light (Magic) - From Lightspawn, heals mobs in circle
    435148, -- Blazing Strike (Magic) - From Risen Footman, initial hit only, DoT not blockable
    427469, -- Fireball (Magic) - From Risen Mage, reflects damage back
    444743, -- Fireball Volley (Magic) - From Risen Mage
    435165, -- Blazing Strike (Magic) - From Sir Braunpyke, initial hit only, DoT not blockable
    427597,  -- Seal of Light's Fury (Magic) - From Zealous Templar

    -- Theater of Pain
    1215741, -- Mighty Smash (Magic)
    1217138, -- Necrotic Bolt (Magic) - Reflects damage to boss
    1215636, -- Noxious Spores (Magic)
    473519, -- Death Spiral (Magic)
    1216475, -- Necrotic Bolt (Magic) - Reflects damage to boss
    474084, -- Necrotic Eruption (Magic)
    1222949, -- Well of Darkness (Magic) - Deflectable
    324589, -- Death Bolt (Magic)
    324079, -- Reaping Scythe (Magic) - Both physical and magical portions blockable
    330697, -- Decaying Strike (Magic) - From Diseased Horror, reflects damage to mob
    330784, -- Necrotic Bolt (Magic) - From Maniacal Soulbinder
    330875, -- Spirit Frost (Magic) - From Nefarious Deathspeaker, reflects damage to mob
    330720, -- Soulstorm (Magic) - From Portal Guardian
    465830,  -- Warp Blood (Magic)

    -- The Rookery
    1214326, -- Crashing Thunder (Magic)
    419871, -- Lightning Dash (Magic)
    444250, -- Lightning Torrent (Magic) - Stuns
    425113, -- Crush Reality (Magic)
    445537, -- Oblivion Wave (Magic) - Frontal on tank
    443847, -- Instability (Magic) - Void zone when mob dies
    430805, -- Arcing Void (Magic) - From Coalescing Void Diffuser, reflects damage to mob
    430186, -- Seeping Corruption (Magic) - From Corrupted Oracle, initial hit only, deflectable
    430238, -- Void Bolt (Magic) - From Corrupted Oracle, reflects damage to mob
    430758, -- Void Shell (Magic) - From Corrupted Oracle, can block thorns damage
    430109, -- Lightning Bolt (Magic) - From Cursed Thunderer, reflects damage to mob
    426968, -- Bounding Void (Magic) - From Quartermaster Koratite, orbs movement
    432903, -- Embrace the Void (Magic) - From Radiating Voidstone
    427616, -- Energized Barrage (Magic) - From Unruly Stormrook
    430013, -- Thunderstrike (Magic) - From Unruly Stormrook
    474032, -- Void Crush (Magic) - From Void-Cursed Crusher
    427439, -- Localized Storm (Magic) - From Voidrider
    432959, -- Void Volley (Magic) - From Void Ascendant
    442192, -- Oppressive Void (Magic) - From Void Mass
}

-- Helper function for spell reflection
local function ShouldUseSpellReflection(icon)
    -- Check if Spell Reflection is ready
    if not A.SpellReflection or not A.SpellReflection:IsReady() then
        return false
    end
    
    -- Loop through all visible enemies
    for i = 1, 40 do
        local unit = "nameplate" .. i
        
        -- Check if unit exists and is attackable
        if UnitExists(unit) and UnitCanAttack("player", unit) then
            -- Get the spell being cast by this unit
            local castName, _, _, _, endTime, _, _, notInterruptible = UnitCastingInfo(unit)
            local channelName, _, _, _, channelEndTime, _, notInterruptibleChannel = UnitChannelInfo(unit)
            
            -- Only proceed if the unit is casting or channeling and it's not uninterruptible
            if (castName and not notInterruptible) or (channelName and not notInterruptibleChannel) then
                -- Get the spell ID of what's being cast
                local spellID
                if castName then
                    spellID = select(9, UnitCastingInfo(unit))
                elseif channelName then
                    spellID = select(9, UnitChannelInfo(unit))
                end
                
                -- If we have a valid spell ID and it's in our reflect list
                if spellID and SpellsToReflect then
                    for _, reflectSpellID in ipairs(SpellsToReflect) do
                        if spellID == reflectSpellID then
                            return A.SpellReflection:Show(icon)
                        end
                    end
                end
            end
        end
    end
    
    -- Also check our current target explicitly
    if UnitExists("target") and UnitCanAttack("player", "target") then
        local castName, _, _, _, endTime, _, _, notInterruptible = UnitCastingInfo("target")
        local channelName, _, _, _, channelEndTime, _, notInterruptibleChannel = UnitChannelInfo("target")
        
        if (castName and not notInterruptible) or (channelName and not notInterruptibleChannel) then
            local spellID
            if castName then
                spellID = select(9, UnitCastingInfo("target"))
            elseif channelName then
                spellID = select(9, UnitChannelInfo("target"))
            end
            
            -- If we have a valid spell ID and it's in our reflect list
            if spellID and SpellsToReflect then
                for _, reflectSpellID in ipairs(SpellsToReflect) do
                    if spellID == reflectSpellID then
                        return A.SpellReflection:Show(icon)
                    end
                end
            end
        end
    end
    
    return false
end

-- Helper function for spell block
local function ShouldUseSpellBlock(icon)
    -- Don't use if not ready
    if not A.SpellBlock or not A.SpellBlock:IsReady() then
        return false
    end
    
    -- Loop through all visible enemies
    for i = 1, 40 do
        local unit = "nameplate" .. i
        
        -- Check if unit exists and is attackable
        if UnitExists(unit) and UnitCanAttack("player", unit) then
            -- Get the spell being cast by this unit
            local castName, _, _, _, endTime, _, _, notInterruptible = UnitCastingInfo(unit)
            local channelName, _, _, _, channelEndTime, _, notInterruptibleChannel = UnitChannelInfo(unit)
            
            -- Only proceed if the unit is casting or channeling
            if (castName and not notInterruptible) or (channelName and not notInterruptibleChannel) then
                -- Get the spell ID of what's being cast
                local spellID
                if castName then
                    spellID = select(9, UnitCastingInfo(unit))
                elseif channelName then
                    spellID = select(9, UnitChannelInfo(unit))
                end
                
                -- If we have a valid spell ID
                if spellID and SpellsToBlock then
                    -- Check if this spell is in our block list
                    for _, blockSpellID in ipairs(SpellsToBlock) do
                        if spellID == blockSpellID then
                            return A.SpellBlock:Show(icon)
                        end
                    end
                end
            end
        end
    end
    
    -- Also check our current target explicitly
    if UnitExists("target") and UnitCanAttack("player", "target") then
        local castName, _, _, _, endTime, _, _, notInterruptible = UnitCastingInfo("target")
        local channelName, _, _, _, channelEndTime, _, notInterruptibleChannel = UnitChannelInfo("target")
        
        if (castName and not notInterruptible) or (channelName and not notInterruptibleChannel) then
            local spellID
            if castName then
                spellID = select(9, UnitCastingInfo("target"))
            elseif channelName then
                spellID = select(9, UnitChannelInfo("target"))
            end
            
            if spellID and SpellsToBlock then
                for _, blockSpellID in ipairs(SpellsToBlock) do
                    if spellID == blockSpellID then
                        return A.SpellBlock:Show(icon)
                    end
                end
            end
        end
    end
    
    return false
end

-- Core rotation function
local function ThaneRotation(icon)
    -- Use global function for combat and target validation
    if not A.IsInValidCombat() then
        return false
    end
    
    -- Check aggro management first
    if AggroManagement(icon) then
        return true
    end
    
    -- Target validation
    if not UnitExists("target") then
        return false
    end
    
    -- Get target info and player state
    local inMelee = InMeleeRange()
    local numEnemies = GetNumEnemies()
    local rage = Player:Rage()
    local rageDeficit = Player:RageDeficit()
    local targetHealthPct = Unit(target):HealthPercent()
    
    -- Safely check buffs with nil protection
    local hasAvatar = (BUFF.avatar and SafeUnitCheck("player", "buff", BUFF.avatar)) or 0
    local hasViolentOutburst = (BUFF.violent_outburst and SafeUnitCheck("player", "buff", BUFF.violent_outburst)) or 0
    local hasBurstOfPower = (BUFF.burst_of_power and SafeUnitCheck("player", "buff", BUFF.burst_of_power)) or 0
    local hasDeepWounds = (DEBUFF.deep_wounds and SafeUnitCheck("target", "debuff", DEBUFF.deep_wounds)) or 0
    local hasThunderBlast = (BUFF.thunder_blast and SafeUnitCheck("player", "buff", BUFF.thunder_blast)) or 0
    local hasRevengeBuff = (BUFF.revenge and SafeUnitCheck("player", "buff", BUFF.revenge)) or 0
    local hasLastStand = (BUFF.last_stand and SafeUnitCheck("player", "buff", BUFF.last_stand)) or 0
    local hasShieldBlock = (BUFF.shield_block and SafeUnitCheck("player", "buff", BUFF.shield_block)) or 0
    local hasSuddenDeath = (BUFF.sudden_death and SafeUnitCheck("player", "buff", BUFF.sudden_death)) or 0
    local rendRemains = (DEBUFF.rend and SafeUnitCheck("target", "debuff", DEBUFF.rend)) or 0
    
    -- Get cooldown states
    local shieldSlamCD = A.ShieldSlam:GetCooldown()
    local shieldChargeCD = A.ShieldCharge:GetCooldown()
    local demoShoutCD = A.DemoralizingShout:GetCooldown()
    local avatarCD = A.Avatar:GetCooldown()
    
    -- If not in melee range, try to close distance
    if not inMelee then
        if A.Charge:IsReady() then
            return A.Charge:Show(icon)
        end
        return false -- Don't continue rotation if not in melee range
    end
    
    -- Core rotation based on APL (action priority list)
    
    -- Avatar
    if UseBurst() and A.Avatar:IsReady() and (not BUFF.thunder_blast or hasThunderBlast == 0 or hasThunderBlast <= 2) then
        return A.Avatar:Show(icon)
    end
    

    
    -- Ignore Pain
    if A.IgnorePain:IsReady() and (
        -- Complex ignore pain logic for normal phase
        (targetHealthPct >= 20 and (
            (rageDeficit <= 15 and shieldSlamCD == 0) or
            (rageDeficit <= 40 and shieldChargeCD == 0 and A.IsTalentLearned(TALENT.champions_bulwark)) or
            (rageDeficit <= 20 and shieldChargeCD == 0) or
            (rageDeficit <= 30 and demoShoutCD == 0 and A.IsTalentLearned(TALENT.booming_voice)) or
            (rageDeficit <= 20 and avatarCD == 0) or
            (rageDeficit <= 45 and demoShoutCD == 0 and A.IsTalentLearned(TALENT.booming_voice) and hasLastStand > 0 and A.IsTalentLearned(TALENT.unnerving_focus)) or
            (rageDeficit <= 30 and avatarCD == 0 and hasLastStand > 0 and A.IsTalentLearned(TALENT.unnerving_focus)) or
            (rageDeficit <= 20) or
            (rageDeficit <= 40 and shieldSlamCD == 0 and hasViolentOutburst > 0 and A.IsTalentLearned(TALENT.heavy_repercussions) and A.IsTalentLearned(TALENT.impenetrable_wall)) or
            (rageDeficit <= 55 and shieldSlamCD == 0 and hasViolentOutburst > 0 and hasLastStand > 0 and A.IsTalentLearned(TALENT.unnerving_focus) and A.IsTalentLearned(TALENT.heavy_repercussions) and A.IsTalentLearned(TALENT.impenetrable_wall)) or
            (rageDeficit <= 17 and shieldSlamCD == 0 and A.IsTalentLearned(TALENT.heavy_repercussions)) or
            (rageDeficit <= 18 and shieldSlamCD == 0 and A.IsTalentLearned(TALENT.impenetrable_wall))
        )) or
        -- Logic for using at high rage
        ((rage >= 70 or (BUFF.seeing_red and SafeUnitCheck("player", "buff", BUFF.seeing_red) == 7 and rage >= 35)) and 
         shieldSlamCD <= 1 and hasShieldBlock >= 4)
    ) then
        return A.IgnorePain:Show(icon)
    end
    

    
    -- Ravager
    if UseBurst() and A.Ravager:IsReady() then
        return A.Ravager:Show(icon)
    end
    
    -- Demoralizing Shout with Booming Voice
    if A.DemoralizingShout:IsReady() and A.IsTalentLearned(TALENT.booming_voice) then
        return A.DemoralizingShout:Show(icon)
    end
    
    -- Champion's Spear
    if A.ChampionsSpear:IsReady() then
        return A.ChampionsSpear:Show(icon)
    end
    
    -- Thunder Blast for AoE with 2 stacks
    if A.ThunderBlast:IsReady() and numEnemies >= 2 and hasThunderBlast == 2 then
        if MetaEngine and MetaEngine.IsHealthy and MetaEngine:IsHealthy() then
            return A.ThunderBlastMeta:Show(icon)
        else
            return A.ThunderBlast:Show(icon)
        end
    end
    
    -- Demolish with 3+ stacks of Colossal Might
    if UseBurst() and A.Demolish:IsReady() and hasColossalMight >= 3 then
        return A.Demolish:Show(icon)
    end
    
    -- Thunderous Roar
    if UseBurst() and A.ThunderousRoar:IsReady() then
        return A.ThunderousRoar:Show(icon)
    end
    
    -- Shield Charge
    if A.ShieldCharge:IsReady() then
        return A.ShieldCharge:Show(icon)
    end
    
    -- Shield Block maintenance
    if A.ShieldBlock:IsReady() and hasShieldBlock <= 10 then
        return A.ShieldBlock:Show(icon)
    end
    

    
    -- AoE rotation for 3+ targets
    if numEnemies >= 3 then
        -- Thunder Blast for Rend refreshing
        if A.ThunderBlast:IsReady() and rendRemains <= 1 then
            if MetaEngine and MetaEngine.IsHealthy and MetaEngine:IsHealthy() then
                return A.ThunderBlastMeta:Show(icon)
            else
                return A.ThunderBlast:Show(icon)
            end
        end
        
        -- Thunder Clap for Rend refreshing
        if A.ThunderClap:IsReady() and rendRemains <= 1 then
            return A.ThunderClap:Show(icon)
        end
        
        -- Thunder Blast with Violent Outburst + Avatar + Unstoppable Force
        if A.ThunderBlast:IsReady() and hasViolentOutburst > 0 and numEnemies >= 2 and 
           hasAvatar > 0 and A.IsTalentLearned(TALENT.unstoppable_force) then
            if MetaEngine and MetaEngine.IsHealthy and MetaEngine:IsHealthy() then
                return A.ThunderBlastMeta:Show(icon)
            else
                return A.ThunderBlast:Show(icon)
            end
        end
        
        -- Thunder Clap with Violent Outburst, Avatar and talents
        if A.ThunderClap:IsReady() and hasViolentOutburst > 0 and hasAvatar > 0 and 
           A.IsTalentLearned(TALENT.unstoppable_force) and
           ((numEnemies >= 4 and A.IsTalentLearned(TALENT.crashing_thunder)) or numEnemies > 6) then
            return A.ThunderClap:Show(icon)
        end
        
        -- Revenge with high rage and Seismic Reverberation
        if A.Revenge:IsReady() and rage >= 70 and A.IsTalentLearned(TALENT.seismic_reverberation) and numEnemies >= 3 then
            return A.Revenge:Show(icon)
        end
        
        -- Shield Slam with rage management or Violent Outburst
        if A.ShieldSlam:IsReady() and (rage <= 60 or (hasViolentOutburst > 0 and numEnemies <= 4 and A.IsTalentLearned(TALENT.crashing_thunder))) then
            return A.ShieldSlam:Show(icon)
        end
        
        -- Thunder Blast
        if A.ThunderBlast:IsReady() then
            if MetaEngine and MetaEngine.IsHealthy and MetaEngine:IsHealthy() then
                return A.ThunderBlastMeta:Show(icon)
            else
                return A.ThunderBlast:Show(icon)
            end
        end
        
        -- Thunder Clap
        if A.ThunderClap:IsReady() then
            return A.ThunderClap:Show(icon)
        end
        
        -- Revenge with sufficient rage
        if A.Revenge:IsReady() and (rage >= 30 or (rage >= 40 and A.IsTalentLearned(TALENT.barbaric_training))) then
            return A.Revenge:Show(icon)
        end
    else
        -- Single target/generic rotation
        
        -- Thunder Blast with specific conditions
        if A.ThunderBlast:IsReady() and hasThunderBlast == 2 and hasBurstOfPower <= 1 and 
           hasAvatar > 0 and A.IsTalentLearned(TALENT.unstoppable_force) then
            if MetaEngine and MetaEngine.IsHealthy and MetaEngine:IsHealthy() then
                return A.ThunderBlastMeta:Show(icon)
            else
                return A.ThunderBlast:Show(icon)
            end
        end
        
        -- Shield Slam with conditions
        if A.ShieldSlam:IsReady() and ((hasBurstOfPower == 2 and hasThunderBlast <= 1) or hasViolentOutburst > 0 or
                                     (rage <= 70 and A.IsTalentLearned(TALENT.demolish))) then
            return A.ShieldSlam:Show(icon)
        end
        
        -- Execute with rage conditions
        if A.Execute:IsReady() and (rage >= 70 or 
                                  (rage >= 40 and shieldSlamCD > 0 and A.IsTalentLearned(TALENT.demolish)) or
                                  (rage >= 50 and shieldSlamCD > 0) or
                                  (hasSuddenDeath > 0 and A.IsTalentLearned(TALENT.sudden_death))) then
            return A.Execute:Show(icon)
        end
        
        -- Shield Slam
        if A.ShieldSlam:IsReady() then
            return A.ShieldSlam:Show(icon)
        end
        
        -- Thunder Blast for Rend management
        if A.ThunderBlast:IsReady() and rendRemains <= 2 and hasViolentOutburst == 0 then
            if MetaEngine and MetaEngine.IsHealthy and MetaEngine:IsHealthy() then
                return A.ThunderBlastMeta:Show(icon)
            else
                return A.ThunderBlast:Show(icon)
            end
        end
        
        -- Thunder Blast
        if A.ThunderBlast:IsReady() then
            if MetaEngine and MetaEngine.IsHealthy and MetaEngine:IsHealthy() then
                return A.ThunderBlastMeta:Show(icon)
            else
                return A.ThunderBlast:Show(icon)
            end
        end
        
        -- Thunder Clap for Rend management
        if A.ThunderClap:IsReady() and rendRemains <= 2 and hasViolentOutburst == 0 then
            return A.ThunderClap:Show(icon)
        end
        
        -- Thunder Blast for cleave or when Shield Slam is on CD
        if A.ThunderBlast:IsReady() and (numEnemies > 1 or (shieldSlamCD > 0 and hasViolentOutburst == 0)) then
            if MetaEngine and MetaEngine.IsHealthy and MetaEngine:IsHealthy() then
                return A.ThunderBlastMeta:Show(icon)
            else
                return A.ThunderBlast:Show(icon)
            end
        end
        
        -- Thunder Clap for cleave or when Shield Slam is on CD
        if A.ThunderClap:IsReady() and (numEnemies > 1 or (shieldSlamCD > 0 and hasViolentOutburst == 0)) then
            return A.ThunderClap:Show(icon)
        end
        
        -- Revenge with various conditions
        if A.Revenge:IsReady() and (
            -- Normal targets
            (rage >= 80 and targetHealthPct > 20) or 
            (hasRevengeBuff > 0 and targetHealthPct <= 20 and rage <= 18 and shieldSlamCD > 0) or
            (hasRevengeBuff > 0 and targetHealthPct > 20) or
            -- With Massacre talent
            ((rage >= 80 and targetHealthPct > 35) or 
             (hasRevengeBuff > 0 and targetHealthPct <= 35 and rage <= 18 and shieldSlamCD > 0) or
             (hasRevengeBuff > 0 and targetHealthPct > 35)) and A.IsTalentLearned(TALENT.massacre)
        ) then
            return A.Revenge:Show(icon)
        end
        
        -- Execute
        if A.Execute:IsReady() then
            return A.Execute:Show(icon)
        end
        
        -- Revenge
        if A.Revenge:IsReady() then
            return A.Revenge:Show(icon)
        end
        
        -- Thunder Blast as a filler
        if A.ThunderBlast:IsReady() and (numEnemies >= 1 or (shieldSlamCD > 0 and hasViolentOutburst > 0)) then
            if MetaEngine and MetaEngine.IsHealthy and MetaEngine:IsHealthy() then
                return A.ThunderBlastMeta:Show(icon)
            else
                return A.ThunderBlast:Show(icon)
            end
        end
        
        -- Thunder Clap as a filler
        if A.ThunderClap:IsReady() and (numEnemies >= 1 or (shieldSlamCD > 0 and hasViolentOutburst > 0)) then
            return A.ThunderClap:Show(icon)
        end
        
        -- Devastate as last resort
        if A.Devastate:IsReady() and not A.IsTalentLearned(236279) then
            return A.Devastate:Show(icon)
        end
    end
    
    return false
end

-- Add function to determine which rotation to use based on talents
local function GetActiveRotation()
    -- Check for Colossus talents (Demolish talent)
    if A.IsTalentLearned(TALENT.demolish) or A.IsTalentLearned(436358) then
        return "Colossus"
    -- Check for Mountain Thane talents
    elseif A.IsTalentLearned(TALENT.thunder_blast) or A.IsTalentLearned(343969) then
        return "Thane"
    -- Fallback to basic Protection
    else
        return "Protection"
    end
end

-- Colossus rotation function
local function ColossusRotation(icon)
    -- Use global function for combat and target validation
    if not A.IsInValidCombat() then
        return false
    end
    
    -- Check aggro management first
    if AggroManagement(icon) then
        return true
    end
    
    -- Target validation
    if not UnitExists("target") then
        return false
    end
    
    -- Get target info and player state
    local inMelee = InMeleeRange()
    local numEnemies = GetNumEnemies()
    local rage = Player:Rage()
    local rageDeficit = Player:RageDeficit()
    local targetHealthPct = Unit(target):HealthPercent()
    
    -- Safely check buffs with nil protection
    local hasAvatar = (BUFF.avatar and SafeUnitCheck("player", "buff", BUFF.avatar)) or 0
    local hasViolentOutburst = (BUFF.violent_outburst and SafeUnitCheck("player", "buff", BUFF.violent_outburst)) or 0
    local hasBurstOfPower = (BUFF.burst_of_power and SafeUnitCheck("player", "buff", BUFF.burst_of_power)) or 0
    local hasDeepWounds = (DEBUFF.deep_wounds and SafeUnitCheck("target", "debuff", DEBUFF.deep_wounds)) or 0
    local hasThunderBlast = (BUFF.thunder_blast and SafeUnitCheck("player", "buff", BUFF.thunder_blast)) or 0
    local hasRevengeBuff = (BUFF.revenge and SafeUnitCheck("player", "buff", BUFF.revenge)) or 0
    local hasLastStand = (BUFF.last_stand and SafeUnitCheck("player", "buff", BUFF.last_stand)) or 0
    local hasShieldBlock = (BUFF.shield_block and SafeUnitCheck("player", "buff", BUFF.shield_block)) or 0
    local hasColossalMight = (BUFF.colossal_might and SafeUnitCheck("player", "buff", BUFF.colossal_might)) or 0
    local hasSuddenDeath = (BUFF.sudden_death and SafeUnitCheck("player", "buff", BUFF.sudden_death)) or 0
    local rendRemains = (DEBUFF.rend and SafeUnitCheck("target", "debuff", DEBUFF.rend)) or 0
    
    -- Get cooldown states
    local shieldSlamCD = A.ShieldSlam:GetCooldown()
    local shieldChargeCD = A.ShieldCharge:GetCooldown()
    local demoShoutCD = A.DemoralizingShout:GetCooldown()
    local avatarCD = A.Avatar:GetCooldown()
    
    -- If not in melee range, try to close distance
    if not inMelee then
        if A.Charge:IsReady() then
            return A.Charge:Show(icon)
        end
        return false -- Don't continue rotation if not in melee range
    end
    
    -- Core rotation based on APL (action priority list)
    
    -- Avatar
    if UseBurst() and A.Avatar:IsReady() and (not BUFF.thunder_blast or hasThunderBlast == 0 or hasThunderBlast <= 2) then
        return A.Avatar:Show(icon)
    end

    
    -- Ignore Pain
    if A.IgnorePain:IsReady() and (
        -- Complex ignore pain logic for normal phase
        (targetHealthPct >= 20 and (
            (rageDeficit <= 15 and shieldSlamCD == 0) or
            (rageDeficit <= 40 and shieldChargeCD == 0 and A.IsTalentLearned(TALENT.champions_bulwark)) or
            (rageDeficit <= 20 and shieldChargeCD == 0) or
            (rageDeficit <= 30 and demoShoutCD == 0 and A.IsTalentLearned(TALENT.booming_voice)) or
            (rageDeficit <= 20 and avatarCD == 0) or
            (rageDeficit <= 45 and demoShoutCD == 0 and A.IsTalentLearned(TALENT.booming_voice) and hasLastStand > 0 and A.IsTalentLearned(TALENT.unnerving_focus)) or
            (rageDeficit <= 30 and avatarCD == 0 and hasLastStand > 0 and A.IsTalentLearned(TALENT.unnerving_focus)) or
            (rageDeficit <= 20) or
            (rageDeficit <= 40 and shieldSlamCD == 0 and hasViolentOutburst > 0 and A.IsTalentLearned(TALENT.heavy_repercussions) and A.IsTalentLearned(TALENT.impenetrable_wall)) or
            (rageDeficit <= 55 and shieldSlamCD == 0 and hasViolentOutburst > 0 and hasLastStand > 0 and A.IsTalentLearned(TALENT.unnerving_focus) and A.IsTalentLearned(TALENT.heavy_repercussions) and A.IsTalentLearned(TALENT.impenetrable_wall)) or
            (rageDeficit <= 17 and shieldSlamCD == 0 and A.IsTalentLearned(TALENT.heavy_repercussions)) or
            (rageDeficit <= 18 and shieldSlamCD == 0 and A.IsTalentLearned(TALENT.impenetrable_wall))
        )) or
        -- Logic for using at high rage
        ((rage >= 70 or (BUFF.seeing_red and SafeUnitCheck("player", "buff", BUFF.seeing_red) == 7 and rage >= 35)) and 
         shieldSlamCD <= 1 and hasShieldBlock >= 4)
    ) then
        return A.IgnorePain:Show(icon)
    end
    

    
    -- Ravager
    if UseBurst() and A.Ravager:IsReady() then
        return A.Ravager:Show(icon)
    end
    
    -- Demoralizing Shout with Booming Voice
    if A.DemoralizingShout:IsReady() and A.IsTalentLearned(TALENT.booming_voice) then
        return A.DemoralizingShout:Show(icon)
    end
    
    -- Champion's Spear
    if A.ChampionsSpear:IsReady() then
        return A.ChampionsSpear:Show(icon)
    end
    
    -- Thunder Blast for AoE with 2 stacks
    if A.ThunderBlast:IsReady() and numEnemies >= 2 and hasThunderBlast == 2 then
        if MetaEngine and MetaEngine.IsHealthy and MetaEngine:IsHealthy() then
            return A.ThunderBlastMeta:Show(icon)
        else
            return A.ThunderBlast:Show(icon)
        end
    end
    
    -- Demolish with 3+ stacks of Colossal Might
    if UseBurst() and A.Demolish:IsReady() and hasColossalMight >= 3 then
        return A.Demolish:Show(icon)
    end
    
    -- Thunderous Roar
    if UseBurst() and A.ThunderousRoar:IsReady() then
        return A.ThunderousRoar:Show(icon)
    end
    
    -- Shield Charge
    if A.ShieldCharge:IsReady() then
        return A.ShieldCharge:Show(icon)
    end
    
    -- Shield Block maintenance
    if A.ShieldBlock:IsReady() and hasShieldBlock <= 10 then
        return A.ShieldBlock:Show(icon)
    end
    

    
    -- AoE rotation for 3+ targets
    if numEnemies >= 3 then
        -- Thunder Blast for Rend refreshing
        if A.ThunderBlast:IsReady() and rendRemains <= 1 then
            if MetaEngine and MetaEngine.IsHealthy and MetaEngine:IsHealthy() then
                return A.ThunderBlastMeta:Show(icon)
            else
                return A.ThunderBlast:Show(icon)
            end
        end
        
        -- Thunder Clap for Rend refreshing
        if A.ThunderClap:IsReady() and rendRemains <= 1 then
            return A.ThunderClap:Show(icon)
        end
        
        -- Thunder Blast with Violent Outburst + Avatar + Unstoppable Force
        if A.ThunderBlast:IsReady() and hasViolentOutburst > 0 and numEnemies >= 2 and 
           hasAvatar > 0 and A.IsTalentLearned(TALENT.unstoppable_force) then
            if MetaEngine and MetaEngine.IsHealthy and MetaEngine:IsHealthy() then
                return A.ThunderBlastMeta:Show(icon)
            else
                return A.ThunderBlast:Show(icon)
            end
        end
        
        -- Thunder Clap with Violent Outburst, Avatar and talents
        if A.ThunderClap:IsReady() and hasViolentOutburst > 0 and hasAvatar > 0 and 
           A.IsTalentLearned(TALENT.unstoppable_force) and
           ((numEnemies >= 4 and A.IsTalentLearned(TALENT.crashing_thunder)) or numEnemies > 6) then
            return A.ThunderClap:Show(icon)
        end
        
        -- Revenge with high rage and Seismic Reverberation
        if A.Revenge:IsReady() and rage >= 70 and A.IsTalentLearned(TALENT.seismic_reverberation) and numEnemies >= 3 then
            return A.Revenge:Show(icon)
        end
        
        -- Shield Slam with rage management or Violent Outburst
        if A.ShieldSlam:IsReady() and (rage <= 60 or (hasViolentOutburst > 0 and numEnemies <= 4 and A.IsTalentLearned(TALENT.crashing_thunder))) then
            return A.ShieldSlam:Show(icon)
        end
        
        -- Thunder Blast
        if A.ThunderBlast:IsReady() then
            if MetaEngine and MetaEngine.IsHealthy and MetaEngine:IsHealthy() then
                return A.ThunderBlastMeta:Show(icon)
            else
                return A.ThunderBlast:Show(icon)
            end
        end
        
        -- Thunder Clap
        if A.ThunderClap:IsReady() then
            return A.ThunderClap:Show(icon)
        end
        
        -- Revenge with sufficient rage
        if A.Revenge:IsReady() and (rage >= 30 or (rage >= 40 and A.IsTalentLearned(TALENT.barbaric_training))) then
            return A.Revenge:Show(icon)
        end
    else
        -- Single target/generic rotation
        
        -- Thunder Blast with specific conditions
        if A.ThunderBlast:IsReady() and hasThunderBlast == 2 and hasBurstOfPower <= 1 and 
           hasAvatar > 0 and A.IsTalentLearned(TALENT.unstoppable_force) then
            if MetaEngine and MetaEngine.IsHealthy and MetaEngine:IsHealthy() then
                return A.ThunderBlastMeta:Show(icon)
            else
                return A.ThunderBlast:Show(icon)
            end
        end
        
        -- Shield Slam with conditions
        if A.ShieldSlam:IsReady() and ((hasBurstOfPower == 2 and hasThunderBlast <= 1) or hasViolentOutburst > 0 or
                                     (rage <= 70 and A.IsTalentLearned(TALENT.demolish))) then
            return A.ShieldSlam:Show(icon)
        end
        
        -- Execute with rage conditions
        if A.Execute:IsReady() and (rage >= 70 or 
                                  (rage >= 40 and shieldSlamCD > 0 and A.IsTalentLearned(TALENT.demolish)) or
                                  (rage >= 50 and shieldSlamCD > 0) or
                                  (hasSuddenDeath > 0 and A.IsTalentLearned(TALENT.sudden_death))) then
            return A.Execute:Show(icon)
        end
        
        -- Shield Slam
        if A.ShieldSlam:IsReady() then
            return A.ShieldSlam:Show(icon)
        end
        
        -- Thunder Blast for Rend management
        if A.ThunderBlast:IsReady() and rendRemains <= 2 and hasViolentOutburst == 0 then
            if MetaEngine and MetaEngine.IsHealthy and MetaEngine:IsHealthy() then
                return A.ThunderBlastMeta:Show(icon)
            else
                return A.ThunderBlast:Show(icon)
            end
        end
        
        -- Thunder Blast
        if A.ThunderBlast:IsReady() then
            if MetaEngine and MetaEngine.IsHealthy and MetaEngine:IsHealthy() then
                return A.ThunderBlastMeta:Show(icon)
            else
                return A.ThunderBlast:Show(icon)
            end
        end
        
        -- Thunder Clap for Rend management
        if A.ThunderClap:IsReady() and rendRemains <= 2 and hasViolentOutburst == 0 then
            return A.ThunderClap:Show(icon)
        end
        
        -- Thunder Blast for cleave or when Shield Slam is on CD
        if A.ThunderBlast:IsReady() and (numEnemies > 1 or (shieldSlamCD > 0 and hasViolentOutburst == 0)) then
            if MetaEngine and MetaEngine.IsHealthy and MetaEngine:IsHealthy() then
                return A.ThunderBlastMeta:Show(icon)
            else
                return A.ThunderBlast:Show(icon)
            end
        end
        
        -- Thunder Clap for cleave or when Shield Slam is on CD
        if A.ThunderClap:IsReady() and (numEnemies > 1 or (shieldSlamCD > 0 and hasViolentOutburst == 0)) then
            return A.ThunderClap:Show(icon)
        end
        
        -- Revenge with various conditions
        if A.Revenge:IsReady() and (
            -- Normal targets
            (rage >= 80 and targetHealthPct > 20) or 
            (hasRevengeBuff > 0 and targetHealthPct <= 20 and rage <= 18 and shieldSlamCD > 0) or
            (hasRevengeBuff > 0 and targetHealthPct > 20) or
            -- With Massacre talent
            ((rage >= 80 and targetHealthPct > 35) or 
             (hasRevengeBuff > 0 and targetHealthPct <= 35 and rage <= 18 and shieldSlamCD > 0) or
             (hasRevengeBuff > 0 and targetHealthPct > 35)) and A.IsTalentLearned(TALENT.massacre)
        ) then
            return A.Revenge:Show(icon)
        end
        
        -- Execute
        if A.Execute:IsReady() then
            return A.Execute:Show(icon)
        end
        
        -- Revenge
        if A.Revenge:IsReady() then
            return A.Revenge:Show(icon)
        end
        
        -- Thunder Blast as a filler
        if A.ThunderBlast:IsReady() and (numEnemies >= 1 or (shieldSlamCD > 0 and hasViolentOutburst > 0)) then
            if MetaEngine and MetaEngine.IsHealthy and MetaEngine:IsHealthy() then
                return A.ThunderBlastMeta:Show(icon)
            else
                return A.ThunderBlast:Show(icon)
            end
        end
        
        -- Thunder Clap as a filler
        if A.ThunderClap:IsReady() and (numEnemies >= 1 or (shieldSlamCD > 0 and hasViolentOutburst > 0)) then
            return A.ThunderClap:Show(icon)
        end
        
        -- Devastate as last resort
        if A.Devastate:IsReady() and not A.IsTalentLearned(236279) then
            return A.Devastate:Show(icon)
        end
    end
    
    return false
end

-- Update the A[3] function to check for Spell Reflection first
A[3] = function(icon)
    -- Check Spell Reflection first as highest priority defense
    if ShouldUseSpellReflection(icon) then
        return true
    end

    if ShouldUseSpellBlock(icon) then
        return true
    end

    -- Add stance management check here
    if ManageStances(icon) then
        return true
    end

    -- Check defensive actions
    if A.DefensiveSystem(icon, DefensiveActions) then
        return true
    end
    
    local activeRotation = GetActiveRotation()
    if A.IsInValidCombat() then
        if activeRotation == "Colossus" then
            if ColossusRotation(icon) then
                return true
            end
        elseif activeRotation == "Thane" then
            if ThaneRotation(icon) then
                return true
            end
        else
            -- Fallback to basic Protection rotation
            if ThaneRotation(icon) then  -- Currently using Thane as base rotation
                return true
            end
        end
    end
    
    local trinketAction = handleTrinketUsage()
    if A.IsInValidCombat() and trinketAction then
        return trinketAction:Show(icon)
    end
    
    -- Common functions regardless of rotation
    if BattleShoutCheck(icon) then
        return true
    end
    
    if A.IsInValidCombat() and A.CheckInterrupts(icon, Interrupts) then 
        return true 
    end
    
    return false
end

-- Register auto-target
A[6] = function(icon)
    if A.IsInValidCombat() then
        if A.AutoTargetNearest(icon, AutoSwitchNearest) then
            return true
        end
    end
    return false
end

