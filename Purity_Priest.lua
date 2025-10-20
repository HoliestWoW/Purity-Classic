-- Purity AddOn - Priest Module

if not Purity then
    return
end

local PriestModule = {
    challenges = {}
}

local TestamentOfPurity = {
    id = "PRIEST_TESTAMENT",
    challengeName = "Testament of Purity",
    description = "A true vessel of the Light, this Priest has sworn off the corrupting and seductive whispers of the Shadow. Their Purity is a testament to their unwavering faith, relying solely on Holy and Disciplinary magic to aid their allies and smite their foes.",
    humanoidsInCombat = {},
    needsWeaponWarning = true,
    optInWarningText = "|cffff0000IMPORTANT: This challenge forbids all weapons. You must unequip your mace before you begin.|r",

    _forbiddenSpellIDs = {
        [589] = "Shadow Word: Pain (Rank 1)", [594] = "Shadow Word: Pain (Rank 2)", [970] = "Shadow Word: Pain (Rank 3)", [992] = "Shadow Word: Pain (Rank 4)", [2767] = "Shadow Word: Pain (Rank 5)", [10892] = "Shadow Word: Pain (Rank 6)", [10893] = "Shadow Word: Pain (Rank 7)", [10894] = "Shadow Word: Pain (Rank 8)",
		[2096] = "Mind Vision (Rank 1)", [10909] = "Mind Vision (Rank 2)",
		[8122] = "Psychic Scream (Rank 1)", [8124] = "Psychic Scream (Rank 2)", [10888] = "Psychic Scream (Rank 3)", [10890] = "Psychic Scream (Rank 4)",
		[586] = "Fade (Rank 1)", [9578] = "Fade (Rank 2)", [9579] = "Fade (Rank 3)", [9592] = "Fade (Rank 4)", [10941] = "Fade (Rank 5)", [10942] = "Fade (Rank 6)",
        [9035] = "Hex of Weakness (Rank 1)", [19281] = "Hex of Weakness (Rank 2)", [19282] = "Hex of Weakness (Rank 3)", [19283] = "Hex of Weakness (Rank 4)", [19284] = "Hex of Weakness (Rank 5)", [19285] = "Hex of Weakness (Rank 6)",
		[8092] = "Mind Blast (Rank 1)", [8102] = "Mind Blast (Rank 2)", [8103] = "Mind Blast (Rank 3)", [8104] = "Mind Blast (Rank 4)", [8105] = "Mind Blast (Rank 5)", [8106] = "Mind Blast (Rank 6)", [10945] = "Mind Blast (Rank 7)", [10946] = "Mind Blast (Rank 8)", [10947] = "Mind Blast (Rank 9)",
		[2652] = "Touch of Weakness (Rank 1)", [19261] = "Touch of Weakness (Rank 2)", [19262] = "Touch of Weakness (Rank 3)", [19264] = "Touch of Weakness (Rank 4)", [19265] = "Touch of Weakness (Rank 5)", [19266] = "Touch of Weakness (Rank 6)",
		[2944] = "Devouring Plague",
        [13896] = "Feedback",
		[453] = "Mind Soothe",
		[18137] = "Shadowguard",
		[8129] = "Mana Burn",
        [605] = "Mind Control",
		[976] = "Shadow Protection",
        [5019] = "Shoot",
		[6603] = "Attack",
		[5009] = "Wands"
    },
    _forbiddenTalentSpellIDs = {
        [15286] = "Vampiric Embrace",
		[15487] = "Silence",
		[15473] = "Shadowform",
		[15407] = "Mind Flay"
    },

    GetRulesText = function(self)
        return {
            "|cffffd100Key Prohibitions:|r",
            "|cff261A0D  • No weapons or physical attacks (including wands).|r",
            "|cff261A0D  • No learning or using Shadow magic spells or talents.|r",
            "|cff261A0D  • No killing Humanoid creatures.|r",
            "|cff261A0D  • Gaining experience for any Humanoid kills will break your vow.|r",
            " ",
            "|cffffd100Challenge Conditions:|r",
            "|cff261A0D  • Must be started on a level 1 Priest.|r",
            "|cff261A0D  • Must be accepted before leveling to 2.|r",
            "|cff261A0D  • An uptime of at least 96.0% must be maintained.|r",
        }
    end,

    IsSpellForbidden = function(self, spellId)
        if not spellId then return false end

        if self._forbiddenSpellIDs[spellId] or self._forbiddenTalentSpellIDs[spellId] then
            return true
        end

        local _, _, _, _, _, _, _, _, school = GetSpellInfo(spellId)
        if school and string.upper(school) == "SHADOW" then
            return true
        end

        return false
    end,

    isWeaponAllowed = function(self, itemLink)
        local _, _, _, _, _, itemType, itemSubType = GetItemInfo(itemLink)
        if (itemType == "Weapon" and itemSubType ~= "Fishing Pole") or itemSubType == "Wand" then
            return false
        end
        return true
    end,

    IsItemForbidden = function(self, itemLink)
        if not itemLink then return false end
        local _, _, _, _, _, itemType, itemSubType = GetItemInfo(itemLink)
        if (itemType == "Weapon" and itemSubType ~= "Fishing Pole") or itemSubType == "Wand" then
            return true
        end
        return false
    end,

    IsUnitForbidden = function(self, unit)
        if not UnitExists(unit) then return false end
        
        if UnitCreatureType(unit) == "Humanoid" and UnitCanAttack("player", unit) then
            return true
        end

        return false
    end,

    EventHandler = function(self, event, ...)
        if event == "CHAT_MSG_COMBAT_XP_GAIN" then
            local message = ...
            local creatureName = string.match(message, "(.+) dies")
            if creatureName and self.humanoidsInCombat[creatureName] == 1 then
                Purity:Violation("You have taken a sapient life, staining your soul and violating your sacred vow.")
                return
            end
        elseif event == "PLAYER_TARGET_CHANGED" then
            if UnitCreatureType("target") == "Humanoid" and UnitCanAttack("player", "target") then
                self.humanoidsInCombat[UnitName("target")] = 1
            end
        elseif event == "PLAYER_LEAVE_COMBAT" then
            self.humanoidsInCombat = {}
        elseif event == "PLAYER_EQUIPMENT_CHANGED" then
            Purity:CheckWeaponState()
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellId, _, spellSchool = CombatLogGetCurrentEventInfo()
            if sourceGUID == UnitGUID("player") then
                if subEvent == "SPELL_CAST_SUCCESS" then
                    local smiteIDs = { [585]=true, [594]=true,[598]=true,[984]=true,[6060]=true,[10933]=true,[10934]=true }
                    if smiteIDs[spellId] then
                        local db = Purity:GetDB()
                        if not db.challengeStats then db.challengeStats = {} end
                        db.challengeStats.smiteCasts = (db.challengeStats.smiteCasts or 0) + 1
						if _G["PurityCharacterPanel"] and _G["PurityCharacterPanel"]:IsShown() then
							_G["UpdateCharacterPurity"]()
						end
                    end
                end
                if spellSchool and (spellSchool == 6) then
                    Purity:Violation("You have channeled the whispers of the Void. Your purity is undone.")
                    return
                end
                if subEvent == "SWING_DAMAGE" or subEvent == "RANGE_DAMAGE" then
                    Purity:HandlePhysicalStrike()
                    return
                end
            end
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            local unit, castName, _, _, spellId = ...
            if unit == "player" then
                if self:IsSpellForbidden(spellId) then
                    Purity:Violation("Used a forbidden spell:\n" .. (castName or "Unknown Spell"))
                    return
                end
            end
        elseif event == "PLAYER_TALENT_UPDATE" or event == "SPELLS_CHANGED" then
            for id, name in pairs(self._forbiddenSpellIDs) do
                if IsSpellKnown(id) and id ~= 5019 and id ~= 6603 then
                    Purity:Violation("Learned a forbidden spell:\n" .. name);
                    return
                end
            end
            for id, name in pairs(self._forbiddenTalentSpellIDs) do
                if IsSpellKnown(id) then 
                    Purity:Violation("Learned a forbidden talent:\n" .. name); 
                    return 
                end
            end
        end
    end,
}
table.insert(PriestModule.challenges, TestamentOfPurity)


local CovenantOfPurity = {
    id = "PRIEST_COVENANT",
    challengeName = "Covenant of Purity",
    description = "Forsake the Light's protection and healing. You must rely on the Shadow for survival, and on raw power for destruction.",
    needsWeaponWarning = false,

    _holyWandIDs = {
        [22254] = true,
    },
    
    _allowedHolySpells = {
        -- All ranks of Smite
        [585] = true, [594] = true, [598] = true, [6060] = true, [10892] = true, [10893] = true, [10894] = true, [25364] = true,
    },

    -- This list now contains all forbidden Discipline and Holy spells for guaranteed detection.
    _forbiddenSpellIDs = {
        -- Discipline Spells
        [17] = true, [592] = true, [600] = true, [3747] = true, [6065] = true, [6066] = true, [10898] = true, [10899] = true, [10900] = true, [10901] = true, -- Power Word: Shield
        [588] = true, [7128] = true, [602] = true, [1006] = true, [10951] = true, [10952] = true, -- Inner Fire
        [1243] = true, [1244] = true, [1245] = true, [2791] = true, [10957] = true, [10958] = true, -- Power Word: Fortitude
        [1706] = true, -- Levitate
        [14751] = true, -- Inner Focus (Talent)
        [10060] = true, -- Power Infusion (Talent)
        -- Holy Healing Spells
        [2050] = true, [2052] = true, [2053] = true, [6063] = true, [10886] = true, [10887] = true, -- Lesser Heal
        [2054] = true, [2055] = true, [6064] = true, [10915] = true, [10916] = true, [10917] = true, [25299] = true, -- Heal
        [2060] = true, [2061] = true, [6074] = true, [10963] = true, [10964] = true, [10965] = true, [25314] = true, -- Greater Heal
        [139] = true, [10927] = true, [10928] = true, [10929] = true, [25303] = true, -- Renew
        [596] = true, [10960] = true, [10961] = true, [25313] = true, -- Prayer of Healing
        [2006] = true, [2010] = true, -- Resurrection
        -- Other Holy Spells
        [528] = true, [552] = true, -- Cure Disease / Abolish Disease
        [9484] = true, [9485] = true, -- Shackle Undead
        [15237] = true, [15430] = true, [15431] = true, [25305] = true, -- Holy Nova
        [14914] = true, [15261] = true, [15449] = true, [15450] = true, [25312] = true, -- Holy Fire
    },

    GetRulesText = function(self)
        return {
            "|cffffd100Key Prohibitions:|r",
            "|cff261A0D  • No using Discipline spells.|r",
            "|cff261A0D  • With the exception of Smite, no other Holy spells may be used.|r",
            "|cff261A0D  • No Holy damage wands.|r",
            " ",
            "|cffffd100Challenge Conditions:|r",
            "|cff261A0D  • Talent points may be spent in any tree, but learning active spells from the Holy or Discipline trees is forbidden.|r",
            "|cff261A0D  • Must be started on a level 1 Priest.|r",
            "|cff261A0D  • Must be accepted before leveling to 2.|r",
			"|cff261A0D  • An uptime of at least 96.0% must be maintained.|r",
        }
    end,

    IsSpellForbidden = function(self, spellId)
        if not spellId then return false end

        if self._allowedHolySpells and self._allowedHolySpells[spellId] then
            return false
        end

        if self._forbiddenSpellIDs and self._forbiddenSpellIDs[spellId] then
            return true
        end
        
        local _, _, _, _, _, _, _, _, school = GetSpellInfo(spellId)
        if school and string.upper(school) == "HOLY" then return true end
        
        return false
    end,

    IsItemForbidden = function(self, itemLink)
        if not itemLink then return false end
        local itemID = tonumber(string.match(itemLink, "item:(%d+)"))
        if not itemID then return false end
        local _, _, _, _, _, itemType, itemSubType = GetItemInfo(itemLink)
        if itemType == "Weapon" and itemSubType == "Wands" and self._holyWandIDs[itemID] then
            return true
        end
        return false
    end,

    isWeaponAllowed = function(self, itemLink)
        return true
    end,

    EventHandler = function(self, event, ...)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellId, spellName, spellSchool = CombatLogGetCurrentEventInfo()
            if sourceGUID == UnitGUID("player") then
                if subEvent == "SPELL_CAST_SUCCESS" then
                    local mindFlayIDs = { [15407]=true, [17311]=true, [17312]=true, [17313]=true, [17314]=true }
                    if mindFlayIDs[spellId] then
                        local db = Purity:GetDB()
                        if not db.challengeStats then db.challengeStats = {} end
                        db.challengeStats.mindFlayCasts = (db.challengeStats.mindFlayCasts or 0) + 1
						if _G["PurityCharacterPanel"] and _G["PurityCharacterPanel"]:IsShown() then
							_G["UpdateCharacterPurity"]()
						end
                    end
                end
                if (subEvent == "SPELL_CAST_SUCCESS" or subEvent == "SPELL_HEAL") and self:IsSpellForbidden(spellId) then
                     Purity:Violation("Used a forbidden spell: " .. (spellName or "Unknown"))
                     return
                end
                if subEvent == "RANGE_DAMAGE" and spellSchool == 2 then
                    Purity:Violation("Used a forbidden Holy wand.")
                    return
                end
            end
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            local unit, castName, _, _, spellId = ...
            if unit == "player" then
                if self:IsSpellForbidden(spellId) then
                    Purity:Violation("Used a forbidden spell:\n" .. (castName or "Unknown Spell"))
                    return
                end
            end
        elseif event == "PLAYER_TALENT_UPDATE" or event == "SPELLS_CHANGED" then
            for i = 1, GetNumSpellTabs() do
                local _, _, _, numSpells = GetSpellTabInfo(i)
                for j = 1, numSpells do
                    local spellType, id = GetSpellBookItemInfo(j, "spell")
                    if spellType == "SPELL" and id and self:IsSpellForbidden(id) then
                        Purity:Violation("Learned a forbidden spell:\n" .. GetSpellBookItemName(j, "spell"));
                        return
                    end
                end
            end
        end
    end,
}
table.insert(PriestModule.challenges, CovenantOfPurity)

Purity.ClassModules = Purity.ClassModules or {}
Purity.ClassModules.PRIEST = PriestModule