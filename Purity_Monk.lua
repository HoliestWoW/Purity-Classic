-- Purity AddOn - Monk Module (Corrected API)

local addonName, Purity = ...

-- Compatibility Wrapper for MoP 5.4.8 support
local function GetCombatLogInfo(...)
    if CombatLogGetCurrentEventInfo then
        return CombatLogGetCurrentEventInfo()
    else
        return ...
    end
end

local MonkModule = {
    challenges = {}
}

-----------------------------------------------------------------------
-- Challenge 1: Chalice of Purity
-----------------------------------------------------------------------
local ChaliceOfPurity = {
    id = "MONK_CHALICE",
    challengeName = "Chalice of Purity",
    description = "The Monk symbolically forsakes the alcoholic and magical brews they would normally rely on.",
    
    _forbiddenSpellIDs = {
        [115308] = "Elusive Brew", [122278] = "Fortifying Brew", [119582] = "Purifying Brew", 
        [115399] = "Keg Smash", [116680] = "Mana Tea", [116740] = "Thunder Focus Tea",
    },

    GetRulesText = function(self)
        return {
            "|cffffd100Key Prohibitions:|r",
            "|cff261A0D  • You may not use any abilities with 'Brew' or 'Tea' in the name.|r",
            " ",
            "|cffffd100Conditions:|r",
            "|cff261A0D  • Must be started on a level 1 Monk.|r",
        }
    end,

    IsSpellForbidden = function(self, spellId)
        return self._forbiddenSpellIDs[spellId]
    end,
    
    EventHandler = function(self, event, ...)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellId = GetCombatLogInfo(...)
            if sourceGUID == UnitGUID("player") and subEvent == "SPELL_CAST_SUCCESS" then
                if spellId == 107428 then -- Rising Sun Kick
                    local db = Purity:GetDB()
                    db.challengeStats = db.challengeStats or {}
                    db.challengeStats.risingSunKicks = (db.challengeStats.risingSunKicks or 0) + 1
                end
            end
        end
    end
}
table.insert(MonkModule.challenges, ChaliceOfPurity)

-----------------------------------------------------------------------
-- Challenge 2: Bindings of Purity
-----------------------------------------------------------------------
local BindingsOfPurity = {
    id = "MONK_BINDINGS",
    challengeName = "Bindings of Purity",
    description = "This Monk has sworn to be a mountain—unmoving, patient, and resolute.",
    
    _forbiddenSpellIDs = {
        [101545] = "Flying Serpent Kick", [109132] = "Roll", [119996] = "Chi Torpedo",
        [115008] = "Transcendence", [101643] = "Transcendence: Transfer",
    },

    GetRulesText = function(self)
        return {
            "|cffffd100Key Prohibitions:|r",
            "|cff261A0D  • You may not use any high-mobility abilities (Roll, Flying Serpent Kick).|r",
        }
    end,

    IsSpellForbidden = function(self, spellId)
        return self._forbiddenSpellIDs[spellId]
    end,
    
    EventHandler = function(self, event, ...)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellId = GetCombatLogInfo(...)
            if sourceGUID == UnitGUID("player") and subEvent == "SPELL_CAST_SUCCESS" then
                if spellId == 113656 then -- Fists of Fury
                    local db = Purity:GetDB()
                    db.challengeStats = db.challengeStats or {}
                    db.challengeStats.fistsOfFuryCasts = (db.challengeStats.fistsOfFuryCasts or 0) + 1
                end
            end
        end
    end
}
table.insert(MonkModule.challenges, BindingsOfPurity)

-----------------------------------------------------------------------
-- Challenge 3: Gauntlets of Purity
-----------------------------------------------------------------------
local GauntletsOfPurity = {
    id = "MONK_GAUNTLETS",
    challengeName = "Gauntlets of Purity",
    description = "These gauntlets symbolize a vow to never use a crafted weapon in combat.",
    needsWeaponWarning = false,

    GetRulesText = function(self)
        return {
            "|cffffd100Key Prohibitions:|r",
            "|cff261A0D  • You may not deal any damage while a weapon is equipped.|r",
        }
    end,

    EventHandler = function(self, event, ...)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellId = GetCombatLogInfo(...)
            if sourceGUID == UnitGUID("player") then
                if string.find(subEvent, "_DAMAGE") then
                    local mainHand = GetInventoryItemLink("player", 16)
                    if mainHand and select(6, GetItemInfo(mainHand)) == "Weapon" then
                        Purity:Violation("Dealt damage with a weapon equipped.")
                        return
                    end
                end
                
                if subEvent == "SPELL_CAST_SUCCESS" and spellId == 100780 then -- Tiger Palm
                    local db = Purity:GetDB()
                    db.challengeStats = db.challengeStats or {}
                    db.challengeStats.tigerPalms = (db.challengeStats.tigerPalms or 0) + 1
                end
            end
        end
    end
}
table.insert(MonkModule.challenges, GauntletsOfPurity)

Purity.ClassModules = Purity.ClassModules or {}
Purity.ClassModules.MONK = MonkModule