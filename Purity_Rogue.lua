-- Purity AddOn - Rogue Module (Multi-Challenge Build)

if not Purity then
    return
end

local RogueModule = {
    challenges = {}
}

RogueModule.challenges.contract = {
    id = "ROGUE_CONTRACT",
    challengeName = "Contract of Purity",
    description = function() 
        return "The Honorable Duelist. This Rogue has sworn a contract of Purity, forsaking the shadows and all underhanded tactics. Every fight is a fair duel, relying on pure skill with blades, not poisons or cheap shots."
    end,
    needsWeaponWarning = false,
    initiatedFromStealth = false,
    forbiddenSpellIDs = {
        -- Poisons
        [3775] = "Crippling Poison", [6947] = "Instant Poison", [2842] = "Poisons",
        [5237] = "Mind-numbing Poison", [6949] = "Instant Poison II", [2892] = "Deadly Poison",
        [10918] = "Wound Poison", [6950] = "Instant Poison III", [2893] = "Deadly Poison II",
        [6951] = "Mind-numbing Poison II", [13228] = "Wound Poison II", [8926] = "Instant Poison IV",
        [8984] = "Deadly Poison III", [10921] = "Wound Poison III", [3776] = "Crippling Poison II",
        [8927] = "Instant Poison V", [9186] = "Mind-numbing Poison III", [8985] = "Deadly Poison IV",
        [10922] = "Wound Poison IV",
        -- Stealth Openers
        [6770] = "Sap (Rank 1)", [8676] = "Ambush (Rank 1)", [703] = "Garrote (Rank 1)",
        [8724] = "Ambush (Rank 2)", [1833] = "Cheap Shot", [2070] = "Sap (Rank 2)",
        [8631] = "Garrote (Rank 2)", [8632] = "Garrote (Rank 3)", [8725] = "Ambush (Rank 3)",
        [11267] = "Ambush (Rank 4)", [8818] = "Garrote (Rank 4)", [11289] = "Garrote (Rank 5)",
        [11297] = "Sap (Rank 3)", [11268] = "Ambush (Rank 5)", [11290] = "Garrote (Rank 6)",
        [11269] = "Ambush (Rank 6)",
        -- Dishonorables
        [53] = "Backstab (Rank 1)", [1776] = "Gouge (Rank 1)", [2589] = "Backstab (Rank 2)",
        [1777] = "Gouge (Rank 2)", [2590] = "Backstab (Rank 3)", [2591] = "Backstab (Rank 4)",
        [921] = "Pick Pocket", [1724] = "Distract", [408] = "Kidney Shot (Rank 1)",
        [2094] = "Blind", [8721] = "Backstab (Rank 5)", [11279] = "Backstab (Rank 6)",
        [8629] = "Gouge (Rank 3)", [11285] = "Gouge (Rank 4)", [8643] = "Kidney Shot (Rank 2)",
        [11280] = "Backstab (Rank 7)",
    },

    GetRulesText = function(self)
        return {
            "|cffffd100The Duelist's Contract:|r",
            "|cff261A0D  • All combat must be faced head-on. Initiating fights from Stealth is forbidden.|r",
            "|cff261A0D  • Your blades must be clean. The learning or use of all Poisons is forbidden.|r",
            "|cff261A0D  • Fight with honor. All 'cheap shots' and tricks are forbidden.|r",
            "|cff261A0D     (Includes: Backstab, Gouge, Kidney Shot, Blind, Sap, Distract, and Pick Pocket).|r",
            " ",
            "|cffffd100Challenge Conditions:|r",
            "|cff261A0D  • Must be started on a level 1 Rogue.|r",
            "|cff261A0D  • Must be accepted before leveling to 2.|r",
            "|cff261A0D  • An uptime of at least 96.0% must be maintained.|r",
        }
    end,

    IsSpellForbidden = function(self, spellId)
        if not spellId then return false end
        return self.forbiddenSpellIDs[spellId] ~= nil
    end,
    
    IsItemForbidden = function(self, itemLink) return false end,

    EventHandler = function(self, event, ...)
        if event == "SPELLS_CHANGED" or event == "PLAYER_TALENT_UPDATE" then
            for id, name in pairs(self.forbiddenSpellIDs) do
                if IsSpellKnown(id) then
                    Purity:Violation("Learned a forbidden ability:\n" .. name)
                    return
                end
            end
        elseif event == "PLAYER_REGEN_ENABLED" then
            self.initiatedFromStealth = false
        elseif event == "PLAYER_REGEN_DISABLED" then
            if self.initiatedFromStealth then
                Purity:Violation("Initiated combat from a stealthed state.")
            end
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            local unit, _, _, _, spellId = ...
            if unit == "player" then
                if not UnitAffectingCombat("player") then
                    local isStealthed = false
                    for i=1, 40 do
                        local auraName = UnitAura("player", i)
                        if not auraName then break end
                        if auraName == "Stealth" then isStealthed = true; break; end
                    end
                    if isStealthed and UnitCanAttack("player", "target") and not self:IsSpellForbidden(spellId) then
                        self.initiatedFromStealth = true
                    end
                end
            end
		elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellId, spellName = CombatLogGetCurrentEventInfo()
            if sourceGUID == UnitGUID("player") and subEvent == "SPELL_CAST_SUCCESS" then
                if self:IsSpellForbidden(spellId) then
                    Purity:Violation("Used a forbidden ability:\n" .. spellName)
                end
                -- Stat tracking for Sinister Strike
                local sinisterStrikeIDs = { [1752]=true, [1757]=true, [1758]=true, [1759]=true, [1760]=true, [8621]=true, [11293]=true, [11294]=true }
                if sinisterStrikeIDs[spellId] then
                    local db = Purity:GetDB()
                    if not db.challengeStats then db.challengeStats = {} end
                    db.challengeStats.sinisterStrikeCasts = (db.challengeStats.sinisterStrikeCasts or 0) + 1
					if _G["PurityCharacterPanel"] and _G["PurityCharacterPanel"]:IsShown() then
                        _G["UpdateCharacterPurity"]()
                    end
                end
            end
		end
    end,
}

RogueModule.challenges.foil = {
    id = "ROGUE_FOIL",
    challengeName = "Foil of Purity",
    description = function()
        return "A master of single-blade combat, this Rogue accepts the Foil of Purity, a vow to fight with the grace and precision of a fencer. They forsake the use of an off-hand weapon and all ranged weapons, proving that true skill lies not in a barrage of attacks, but in the perfection of one."
    end,
    needsWeaponWarning = true,
    optInWarningText = "|cffff0000IMPORTANT: This challenge forbids ranged weapons. You must unequip your thrown weapon before you begin.|r",

    forbiddenSpellIDs = {
        [30798] = "Dual Wield" 
    },

    GetRulesText = function(self)
        return {
            "|cffffd100The Foil of Purity:|r",
            "|cff261A0D  • You may not learn Dual Wield.|r",
            "|cff261A0D  • You may not equip any ranged weapon (Bows, Guns, Crossbows, or Thrown).|r",
            " ",
            "|cffffd100Challenge Conditions:|r",
            "|cff261A0D  • Must be started on a level 1 Rogue.|r",
            "|cff261A0D  • Must be accepted before leveling to 2.|r",
            "|cff261A0D  • An uptime of at least 96.0% must be maintained.|r",
        }
    end,
    
    IsSpellForbidden = function(self, spellId)
        if not spellId then return false end
        return self.forbiddenSpellIDs and self.forbiddenSpellIDs[spellId] ~= nil
    end,

    IsTalentForbidden = function(self, tabIndex) return false end,

    isWeaponAllowed = function(self, itemLink)
        if not itemLink then return true end
        
        local _, _, _, _, _, itemType, itemSubType = GetItemInfo(itemLink)
        if itemType == "Weapon" then
            if itemSubType == "Bows" or itemSubType == "Guns" or itemSubType == "Crossbows" or itemSubType == "Thrown" then
                return false
            end
        end
        return true
    end,

    IsItemForbidden = function(self, itemLink)
        if not itemLink then return false end
        return not self:isWeaponAllowed(itemLink)
    end,

    EventHandler = function(self, event, ...)
        if event == "SPELLS_CHANGED" then
            if self:IsSpellForbidden(30798) and IsSpellKnown(30798) then
                 Purity:Violation("Learned the forbidden Dual Wield skill.")
                 return
            end
        elseif event == "PLAYER_EQUIPMENT_CHANGED" then
            Purity:CheckWeaponState()
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellId = CombatLogGetCurrentEventInfo()
            if sourceGUID == UnitGUID("player") and subEvent == "SPELL_CAST_SUCCESS" then
                if spellId == 14251 then
                    local db = Purity:GetDB()
                    if not db.challengeStats then db.challengeStats = {} end
                    db.challengeStats.riposteCasts = (db.challengeStats.riposteCasts or 0) + 1
					if _G["PurityCharacterPanel"] and _G["PurityCharacterPanel"]:IsShown() then
                        _G["UpdateCharacterPurity"]()
                    end
                end
            end
        end
    end,
}

Purity.ClassModules = Purity.ClassModules or {}
Purity.ClassModules.ROGUE = RogueModule