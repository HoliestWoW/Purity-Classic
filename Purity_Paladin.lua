-- Purity AddOn - Paladin Module (v5.1 Update)

if not Purity then
    return
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
    hostileAttackers = {},

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

    IsTalentForbidden = function(self, tabIndex)
        return tabIndex == 3
    end,

    EventHandler = function(self, event, ...)
        if event == "PLAYER_REGEN_ENABLED" then
            self.hostileAttackers = {}
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
                        _G["UpdateCharacterPurity"]()
                    end
                end
            end

            -- Rule validation for initiating combat
            if not (string.find(subEvent, "_DAMAGE") or string.find(subEvent, "_MISSED")) then return end

            if destGUID == UnitGUID("player") and sourceGUID and bit.band(sourceFlags, COMBATLOG_OBJECT_TYPE_NPC) > 0 then
                self.hostileAttackers[sourceGUID] = true
            elseif sourceGUID == UnitGUID("player") and destGUID and bit.band(destFlags, COMBATLOG_OBJECT_TYPE_NPC) > 0 then
                if not self.hostileAttackers[destGUID] then
                    Purity:Violation("Initiated combat, breaking your oath as a guardian.")
                    self.hostileAttackers[destGUID] = true 
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
    combatants = {},

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
        if event == "PLAYER_TARGET_CHANGED" then
            if UnitExists("target") and UnitCanAttack("player", "target") then
                local targetGUID = UnitGUID("target")
                local creatureType = UnitCreatureType("target")
                if targetGUID then
                    self.combatants[targetGUID] = creatureType
                end
            end
        elseif event == "PLAYER_LEAVE_COMBAT" or event == "PLAYER_REGEN_ENABLED" then
            self.combatants = {}
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, subEvent, _, sourceGUID, _, _, _, destGUID, destName, destFlags, _, spellId = CombatLogGetCurrentEventInfo()

            if sourceGUID == UnitGUID("player") and subEvent == "SPELL_CAST_SUCCESS" then
                local exorcismIDs = { [879]=true, [5614]=true, [5615]=true, [10312]=true, [10313]=true, [10314]=true }
                if exorcismIDs[spellId] then
                    local db = Purity:GetDB()
                    if not db.challengeStats then db.challengeStats = {} end
                    db.challengeStats.exorcismCasts = (db.challengeStats.exorcismCasts or 0) + 1
					if _G["PurityCharacterPanel"] and _G["PurityCharacterPanel"]:IsShown() then
                        _G["UpdateCharacterPurity"]()
                    end
                end
            end

            if subEvent == "UNIT_DIED" and destGUID and bit.band(destFlags, COMBATLOG_OBJECT_TYPE_NPC) > 0 then
                if UnitAffectingCombat("player") and self.combatants[destGUID] then
                    if self.combatants[destGUID] ~= "Undead" then
                        Purity:Violation("Landed the killing blow on a non-Undead creature: " .. destName)
                        return
                    end
                end
            end
        end
    end,
}

Purity.ClassModules = Purity.ClassModules or {}
Purity.ClassModules.PALADIN = PaladinModule