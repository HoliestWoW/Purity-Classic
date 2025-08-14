-- Purity AddOn - Hunter Module

if not Purity then
    return
end

local HunterModule = {
    challenges = {}
}

HunterModule.challenges.bond = {
    id = "HUNTER_BOND",
    challengeName = "Bond of Purity",
    description = "The Primal Savage. This Hunter has sworn a bond of purity with their animal companion, forsaking cowardly ranged weapons and clever traps. Every fight is a raw, melee struggle fought side-by-side with their pet.",
    needsWeaponWarning = true,
    optInWarningText = "|cffff0000IMPORTANT: You will spawn with a ranged weapon equipped. You must unequip it before starting the challenge.|r",
    petCheckTicker = nil,

    forbiddenSpellIDs = {
        [2480] = "Shoot Bow", [2764] = "Throw", [7918] = "Shoot Gun", [7919] = "Shoot Crossbow",
        [1978] = "Serpent Sting", [3044] = "Arcane Shot", [5116] = "Concussive Shot", [20736] = "Distracting Shot",
        [2643] = "Multi-Shot", [3043] = "Scorpid Sting", [20900] = "Aimed Shot", [3034] = "Viper Sting",
        [1510] = "Volley", [24132] = "Wyvern Sting", [13795] = "Immolation Trap", [13813] = "Explosive Trap",
        [75] = "Auto Shot", [1130] = "Hunter's Mark", [13165] = "Aspect of the Hawk", [3045] = "Rapid Fire", [20905] = "Trueshot Aura"
    },

    forbiddenPassiveSkillIDs = { [266] = "Guns", [264] = "Bows", [2567] = "Thrown", [5011] = "Crossbows" },
	
 IsSpellForbidden = function(self, spellId)
        if not spellId then return false end
        return self.forbiddenSpellIDs[spellId] ~= nil
    end,

    IsTalentForbidden = function(self, tabIndex)
        return tabIndex == 2
    end,

    IsItemForbidden = function(self, itemLink)
        if not itemLink then return false end
        local _, _, _, _, _, itemType, itemSubType = GetItemInfo(itemLink)
        if itemType == "Weapon" then
            if itemSubType == "Bows" or itemSubType == "Guns" or itemSubType == "Crossbows" or itemSubType == "Thrown" then
                return true
            end
        end
        return false
    end,
    
    isWeaponAllowed = function(self, itemLink)
        return not self:IsItemForbidden(itemLink)
    end,

GetRulesText = function()
        return {
            "|cffffd100Key Prohibitions:|r",
            "|cff261A0D  • You may not equip any ranged weapons (Bows, Guns, Crossbows).|r",
            "|cff261A0D  • You may not use any ranged shots (e.g., Auto Shot, Arcane Shot).|r",
            "|cff261A0D  • You may not use ranged-benefit Aspects or Hunter's Mark.|r",
            "|cff261A0D  • You may not use any damaging traps (e.g., Explosive Trap).|r",
            "|cff261A0D  • No learning or using Marksmanship talents.|r",
            " ",
            "|cffffd100Special Rules:|r",
            "|cff261A0D  • Your pet must be active whenever you deal damage (after Tame Beast is learned).|r",
            " ",
            "|cffffd100Challenge Conditions:|r",
            "|cff261A0D  • Must be started on a level 1 Hunter.|r",
            "|cff261A0D  • Must be accepted before leveling to 2.|r",
            "|cff261A0D  • An uptime of at least 96% must be maintained.|r",
            "|cff261A0D  • You must learn Tame Beast before reaching level 11.|r",
        }
    end,

    EventHandler = function(self, event, ...)
        if event == "SPELLS_CHANGED" then
            for id, name in pairs(self.forbiddenSpellIDs) do
                if IsSpellKnown(id) and id ~= 75 then Purity:Violation("Learned a forbidden ability:\n" .. name); return end
            end
        elseif event == "PLAYER_TALENT_UPDATE" then
            if self:IsTalentForbidden(2) then
                for j = 1, GetNumTalents(2) do
                    local _, _, _, _, pointsSpent = GetTalentInfo(2, j)
                    if pointsSpent > 0 then Purity:Violation("Allocated points in the forbidden\nMarksmanship talent tree."); return end
                end
            end
        elseif event == "PLAYER_EQUIPMENT_CHANGED" then Purity:CheckWeaponState()
        elseif event == "PLAYER_LEVEL_UP" then
            local newLevel = ...
            if newLevel == 10 then
                Purity:ShowRuleUpdate("Your Bond of Purity strengthens. You must learn Tame Beast before you grow any stronger.")
            elseif newLevel >= 11 and not IsSpellKnown(1515) then
                Purity:Violation("Failed to learn Tame Beast before level 11, breaking your bond.")
            end
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellId, spellName = CombatLogGetCurrentEventInfo()
            if sourceGUID ~= UnitGUID("player") then return end

            if subEvent == "SPELL_CAST_SUCCESS" then
                -- Stat tracking for Mend Pet
                local mendPetIDs = { [136]=true,[3111]=true,[13542]=true,[3661]=true,[3662]=true,[13543]=true,[13544]=true }
                if mendPetIDs[spellId] then
                    local db = Purity:GetDB()
                    if not db.challengeStats then db.challengeStats = {} end
                    db.challengeStats.mendPetCasts = (db.challengeStats.mendPetCasts or 0) + 1
                    if _G["PurityCharacterPanel"] and _G["PurityCharacterPanel"]:IsShown() then
                        _G["UpdateCharacterPurity"]()
                    end
                end
            end

            if (subEvent == "SPELL_CAST_SUCCESS" or subEvent == "RANGE_DAMAGE") and self:IsSpellForbidden(spellId) then
                Purity:Violation("Used a forbidden ranged ability or damaging trap:\n" .. spellName)
                return
            end
            if IsSpellKnown(1515) then
                if string.find(subEvent, "_DAMAGE") then
                    if not UnitExists("pet") then
                        Purity:Violation("Dealt damage without your animal companion by your side, breaking your sacred bond.")
                    end
                end
            end
		end
    end,
}

HunterModule.challenges.quiver = {
    id = "HUNTER_QUIVER",
    challengeName = "Quiver of Purity",
    description = "The Lone Wolf. You face the world on your own and rely only on the strength of your marksmanship. No pets or melee weapons allowed.",
    needsWeaponWarning = true,
    optInWarningText = "|cffff0000IMPORTANT: You will spawn with a melee weapon equipped. You must unequip it before starting the challenge.|r",
    petCheckTicker = nil,

    forbiddenSpellIDs = {
        [2973] = "Raptor Strike", [14260] = "Raptor Strike", [14261] = "Raptor Strike", [14262] = "Raptor Strike", 
        [14263] = "Raptor Strike", [14264] = "Raptor Strike", [27018] = "Raptor Strike", [27019] = "Raptor Strike",
        [1495] = "Mongoose Bite", [14265] = "Mongoose Bite", [14266] = "Mongoose Bite", [14267] = "Mongoose Bite", [14268] = "Mongoose Bite",
        [2974] = "Wing Clip", [14269] = "Wing Clip", [14270] = "Wing Clip",
        [1515] = "Tame Beast",
        [1514] = "Beast Training",
        [883] = "Call Pet",
        [2641] = "Dismiss Pet",
        [982] = "Revive Pet",
        [6991] = "Feed Pet",
        [1513] = "Beast Soothing",
        [136] = "Mend Pet", [13542] = "Mend Pet", [13543] = "Mend Pet", [13544] = "Mend Pet", 
        [13545] = "Mend Pet", [13546] = "Mend Pet", [13547] = "Mend Pet",
        [19577] = "Intimidation", 
        [19574] = "Bestial Wrath",
        [13161] = "Aspect of the Monkey",
    },

    GetRulesText = function()
        return {
            "|cffffd100Key Prohibitions:|r",
            "|cff261A0D  • You may not equip any melee weapons.|r",
            "|cff261A0D  • You may not use any melee abilities (e.g., Raptor Strike).|r",
            "|cff261A0D  • You may not use a Hunter Pet.|r",
            "|cff261A0D  • You may not complete the quest to learn Tame Beast.|r",
            "|cff261A0D  • No learning or using Beast Mastery talents.|r",
            " ",
            "|cffffd100Challenge Conditions:|r",
            "|cff261A0D  • Must be started on a level 1 Hunter.|r",
            "|cff261A0D  • Must be accepted before leveling to 2.|r",
            "|cff261A0D  • An uptime of at least 96.0% must be maintained.|r",
        }
    end,

    IsSpellForbidden = function(self, spellId)
        if not spellId then return false end
        return self.forbiddenSpellIDs[spellId] ~= nil
    end,

    IsTalentForbidden = function(self, tabIndex)
        return tabIndex == 1
    end,

    IsItemForbidden = function(self, itemLink)
        if not itemLink then return false end
        local _, _, _, _, _, itemType, itemSubType = GetItemInfo(itemLink)
        if itemType == "Weapon" then
            return not (itemSubType == "Bows" or itemSubType == "Guns" or itemSubType == "Crossbows" or itemSubType == "Thrown")
        end
        return false
    end,
    
    isWeaponAllowed = function(self, itemLink)
        return not self:IsItemForbidden(itemLink)
    end,

    EventHandler = function(self, event, ...)
        if event == "SPELLS_CHANGED" then
            for id, name in pairs(self.forbiddenSpellIDs) do
                if IsSpellKnown(id) then
                    if id ~= 2973 then
                        local spellName, _, _, _, _, _, spellID = GetSpellInfo(id)
                        local message = "Learned a forbidden ability:\n" .. (spellName or "Unknown Spell")
                        if spellID == 1515 then
                            message = "Completed the Tame Beast quest, breaking your vow as a Lone Wolf."
                        end
                        Purity:Violation(message)
                        return
                    end
                end
            end
        elseif event == "PLAYER_TALENT_UPDATE" then
            if self:IsTalentForbidden(1) then
                for j = 1, GetNumTalents(1) do
                    local _, _, _, _, pointsSpent = GetTalentInfo(1, j)
                    if pointsSpent > 0 then
                        Purity:Violation("Allocated points in the forbidden\nBeast Mastery talent tree.")
                        return
                    end
                end
            end
        elseif event == "PLAYER_EQUIPMENT_CHANGED" then
            Purity:CheckWeaponState()
            return
        elseif event == "PLAYER_REGEN_ENABLED" then
            if self.petCheckTicker then self.petCheckTicker:Cancel(); self.petCheckTicker = nil end
        elseif event == "PLAYER_REGEN_DISABLED" then
            if UnitLevel("player") >= 10 and not self.petCheckTicker then
                local function checkPet()
                    if UnitExists("pet") then
                        Purity:Violation("Your vow as a Lone Wolf was broken by the presence of a pet.")
                        if self.petCheckTicker then self.petCheckTicker:Cancel(); self.petCheckTicker = nil end
                    end
                end
                checkPet()
                self.petCheckTicker = C_Timer.NewTicker(2, checkPet)
            end
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellId, spellName = CombatLogGetCurrentEventInfo()
            if sourceGUID == UnitGUID("player") then
                if subEvent == "SPELL_CAST_SUCCESS" then
                    local aimedShotIDs = { [19434]=true,[20900]=true,[20902]=true,[20903]=true,[20904]=true,[20901]=true }
                    if aimedShotIDs[spellId] then
                        local db = Purity:GetDB()
                        if not db.challengeStats then db.challengeStats = {} end
                        db.challengeStats.aimedShotCasts = (db.challengeStats.aimedShotCasts or 0) + 1
						if _G["PurityCharacterPanel"] and _G["PurityCharacterPanel"]:IsShown() then
							_G["UpdateCharacterPurity"]()
						end
                    end
                end
                if string.find(subEvent, "DAMAGE") and self:IsSpellForbidden(spellId) then
                    Purity:Violation("Used a forbidden melee ability:\n" .. spellName)
                    return
                end
            end
        end
    end,
}

Purity.ClassModules = Purity.ClassModules or {}
Purity.ClassModules.HUNTER = HunterModule