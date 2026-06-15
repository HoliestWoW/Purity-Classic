-- Purity AddOn - Paladin Module

local addonName, Purity = ...

local secureHostileAttackers = {}
local secureCombatants = {}
local recentNonUndeadDeathTime = 0
local recentNonUndeadDeathName = ""
local recentXPGainTime = 0

local function IsIDInForbiddenTree(id, forbiddenTreeName)
    if not id then return false end
    local forbiddenTabIndex = nil
    local numTabs = GetNumTalentTabs()
    for t = 1, numTabs do
        local r1, r2 = GetTalentTabInfo(t)
        if (r1 == forbiddenTreeName) or (r2 == forbiddenTreeName) then
            forbiddenTabIndex = t
            break
        end
    end
    if not forbiddenTabIndex then return false end
    if id == forbiddenTabIndex then return true end
    local numTalents = GetNumTalents(forbiddenTabIndex)
    for i = 1, numTalents do
        local val1 = select(1, GetTalentInfo(forbiddenTabIndex, i))
        local val12 = select(12, GetTalentInfo(forbiddenTabIndex, i))
        if (val1 == id) or (val12 == id) then return true end
    end
    return false
end

local PaladinModule = {
    challenges = {}
}

PaladinModule.challenges.oath = {
    id = "PALADIN_OATH",
    challengeName = "Oath of Purity",
    description = function()
        local gender = UnitSex("player")
        local pronoun = (gender == 3) and "She" or "He"
        return "The ultimate guardian, the Paladin's Oath is to be a selfless shield. " .. pronoun .. " has forsaken retribution and personal glory, vowing to never be the aggressor."
    end,
    needsWeaponWarning = false,

    forbiddenSpellIDs = {
        [24275] = "Hammer of Wrath",
        [20271] = "Judgement",
        [19740] = "Blessing of Might",
        [21082] = "Seal of the Crusader",
        [7294] = "Retribution Aura",
        [25782] = "Greater Blessing of Might",
        [20101] = "Benediction",
        [20042] = "Improved Blessing of Might"
    },

    GetRulesText = function()
        return {
            "|cffffd100Key Prohibitions:|r",
            "|cff261A0D  • Do not initiate combat; enemies must STRIKE first (a miss counts as a strike).|r",
            "|cff261A0D  • No learning or using Retribution spells/talents.|r",
            "|cff261A0D  • No learning or using Hammer of Wrath.|r",
            " ",
            "|cffffd100Challenge Conditions:|r",
            "|cff261A0D  • Must be started on a level 1 Paladin.|r",
            "|cff261A0D  • Must be accepted before leveling to 2.|r",
            "|cff261A0D  • An uptime of at least 96% must be maintained.|r",
        }
    end,

    IsSpellForbidden = function(self, spellId)
        return self.forbiddenSpellIDs[spellId] ~= nil
    end,

    IsTalentForbidden = function(self, id)
        return IsIDInForbiddenTree(id, "Retribution")
    end,

    EventHandler = function(self, event, ...)
        if event == "PLAYER_REGEN_ENABLED" then
            secureHostileAttackers = {}
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, subEvent, _, sourceGUID, _, sourceFlags, _, destGUID, _, destFlags, _, spellId = CombatLogGetCurrentEventInfo()

            -- Stat tracking for Holy Light (reliable method)
            if sourceGUID == UnitGUID("player") and subEvent == "SPELL_CAST_SUCCESS" then
                local holyLightIDs = { [635]=true,[639]=true,[647]=true,[1026]=true,[1042]=true,[3472]=true,[10328]=true,[10329]=true,[25292]=true }
                if holyLightIDs[spellId] then
                    local db = Purity:GetDB()
                    if not db.challengeStats then db.challengeStats = {} end
                    db.challengeStats.holyLightCasts = (db.challengeStats.holyLightCasts or 0) + 1
                    if _G["PurityCharacterPanel"] and _G["PurityCharacterPanel"]:IsShown() then
						if _G["UpdateCharacterPurity"] then
							_G["UpdateCharacterPurity"]()
						end
					end
                end
            end

            -- Rule validation for initiating combat
            if not (string.find(subEvent, "_DAMAGE") or string.find(subEvent, "_MISSED")) then return end

            if destGUID == UnitGUID("player") and sourceGUID and bit.band(sourceFlags, COMBATLOG_OBJECT_TYPE_NPC) > 0 then
                secureHostileAttackers[sourceGUID] = true
            elseif sourceGUID == UnitGUID("player") and destGUID and bit.band(destFlags, COMBATLOG_OBJECT_TYPE_NPC) > 0 then
                if not secureHostileAttackers[destGUID] then
                    Purity:Violation("Initiated combat, breaking your oath as a guardian.")
                    secureHostileAttackers[destGUID] = true 
                end
            end
		elseif event == "PLAYER_TALENT_UPDATE" then
            local numTabs = GetNumTalentTabs()
            for t = 1, numTabs do
                local _, name = GetTalentTabInfo(t)
                if name == "Retribution" then
                    for i = 1, GetNumTalents(t) do
                        local _, _, _, _, pointsSpent = GetTalentInfo(t, i)
                        if pointsSpent and pointsSpent > 0 then
                            Purity:Violation("Allocated points in the forbidden\nRetribution talent tree.")
                            return
                        end
                    end
                end
            end
		end	
    end,
}

PaladinModule.challenges.libram = {
    id = "PALADIN_UNDEADBANE",
    challengeName = "Libram of Purity",
    description = function()
        return "The Undead Bane. You dedicate your sacred might solely to purging the impure Undead from the world. You cannot land the killing blow on any other type of enemy (including unclassified type mobs)."
    end,
    needsWeaponWarning = false,

    GetRulesText = function()
        return {
            "|cffffd100Key Prohibitions:|r",
            "|cff261A0D  • You may ONLY land the killing blow on creatures of the 'Undead' type.|r",
			" ",
            "|cff261A0D  • Gaining experience for any non-Undead creature kills will break your vow.|r",
            " ",
            "|cffffd100Challenge Conditions:|r",
            "|cff261A0D  • Must be started on a level 1 Paladin.|r",
            "|cff261A0D  • Must be accepted before leveling to 2.|r",
            "|cff261A0D  • An uptime of at least 96.0% must be maintained.|r",
        }
    end,

    IsSpellForbidden = function() return false end,
    IsTalentForbidden = function() return false end,
    IsItemForbidden = function() return false end,
    isWeaponAllowed = function() return true end,
	
    IsUnitForbidden = function(self, unit)
        if not UnitExists(unit) or not UnitCanAttack("player", unit) then
            return false
        end
        if UnitCreatureType(unit) ~= "Undead" then
            return true
        end
        return false
    end,

    EventHandler = function(self, event, ...)
        if event == "PLAYER_TARGET_CHANGED" or event == "UPDATE_MOUSEOVER" then
            local unit = event == "UPDATE_MOUSEOVER" and "mouseover" or "target"
            if UnitExists(unit) and UnitCanAttack("player", unit) then
                local targetGUID = UnitGUID(unit)
                local creatureType = UnitCreatureType(unit)
                local unitName = UnitName(unit)
                
                if targetGUID and unitName then
                    -- Cache both the type and the exact name of the mob
                    secureCombatants[targetGUID] = { type = creatureType, name = unitName }
                end
            end
            
        elseif event == "PLAYER_LEAVE_COMBAT" or event == "PLAYER_REGEN_ENABLED" then
            secureCombatants = {}
            
        elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then
            local text = ...
            -- Parse the string to grab the mob's name before the word "dies"
            -- Example: "Rockjaw Raider dies, you gain 55 experience." -> "Rockjaw Raider"
            local slainMobName = text:match("^(.-) dies, you gain")
            
            if slainMobName then
                -- Check our active combat cache for this name
                for guid, data in pairs(secureCombatants) do
                    if data.name == slainMobName then
                        if data.type ~= "Undead" then
                            Purity:Violation("Gained experience from a non-Undead kill: " .. slainMobName)
                            return
                        end
                    end
                end
            end
            
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, subEvent, _, sourceGUID, _, _, _, destGUID, destName, destFlags, _, spellId = CombatLogGetCurrentEventInfo()

            -- Stat tracking for Exorcism
            if sourceGUID == UnitGUID("player") and subEvent == "SPELL_CAST_SUCCESS" then
                local exorcismIDs = { [879]=true, [5614]=true, [5615]=true, [10312]=true, [10313]=true, [10314]=true }
                if exorcismIDs[spellId] then
                    local db = Purity:GetDB()
                    if not db.challengeStats then db.challengeStats = {} end
                    db.challengeStats.exorcismCasts = (db.challengeStats.exorcismCasts or 0) + 1
                    if _G["PurityCharacterPanel"] and _G["PurityCharacterPanel"]:IsShown() then
                        Purity:UpdateCharacterStatus()
                    end
                end
            end

            -- Direct Killing Blows
            if subEvent == "PARTY_KILL" and sourceGUID == UnitGUID("player") and destGUID and bit.band(destFlags, COMBATLOG_OBJECT_TYPE_NPC) > 0 then
                if secureCombatants[destGUID] then
                    if secureCombatants[destGUID].type ~= "Undead" then
                        Purity:Violation("Landed the killing blow on a non-Undead creature: " .. destName)
                        return
                    end
                end
            end
            
            -- Clean up the cache when a mob dies to prevent bloat during long combat
            if subEvent == "UNIT_DIED" and destGUID then
                if secureCombatants[destGUID] then
                    secureCombatants[destGUID] = nil
                end
            end
        end
    end,
}

Purity.ClassModules = Purity.ClassModules or {}
Purity.ClassModules.PALADIN = PaladinModule