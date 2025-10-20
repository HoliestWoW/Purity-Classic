-- Purity AddOn - Druid Module (Final Bugfix Build)

if not Purity then
    return
end

local DruidModule = {
    challenges = {}
}

DruidModule.challenges.pact = {
    id = "Pact of Purity",
    challengeName = "Pact of Purity",
    description = function()
        return "The Avenger of Nature. This Druid has sworn a pact to protect wild beasts and has forsaken the celestial balance of the moon, relying only on their feral instincts and restorative powers. They have shed their leather armor, embracing a more primal connection to the wild."
    end,
    needsWeaponWarning = false,
    beastsInCombat = {},
    forbiddenBalanceSpells = {[5176]=true,[8921]=true,[467]=true,[5177]=true,[339]=true,[8924]=true,[5178]=true,[782]=true,[8925]=true,[1062]=true,[770]=true,[2637]=true,[2912]=true,[2908]=true,[5179]=true,[8926]=true,[1075]=true,[8949]=true,[5195]=true,[8927]=true,[5180]=true,[778]=true,[8914]=true,[8950]=true,[8928]=true,[6780]=true,[8955]=true,[18657]=true,[5196]=true,[16914]=true,[8929]=true,[9749]=true,[8951]=true,[22812]=true,[9756]=true,[8905]=true,[9833]=true,[9852]=true,[9875]=true,[17401]=true,[9834]=true,[9907]=true,[9912]=true,[9910]=true,[9901]=true,[9835]=true,[9853]=true,[18658]=true,[9876]=true},

    GetRulesText = function()
        return {
            "|cffffd100Key Prohibitions:|r",
            "|cff261A0D  • You may not kill any creature of the 'Beast' type.|r",
            "|cff261A0D  • Gaining experience for any Beast kills will break your vow.|r",
            "|cff261A0D  • After level 10, you may not cast any Balance spells.|r",
            "|cff261A0D  • You may not equip any Leather armor.|r",
            " ",
            "|cffffd100Challenge Conditions:|r",
            "|cff261A0D  • Must be started on a level 1 Druid.|r",
            "|cff261A0D  • Must be accepted before leveling to 2.|r",
            "|cff261A0D  • An uptime of at least 96.0% must be maintained.|r",
        }
    end,

    IsSpellForbidden = function(self, spellId) return false end, -- Casting check is in EventHandler
    IsTalentForbidden = function(self, tabIndex) return UnitLevel("player") >= 10 and tabIndex == 1 end,
    IsItemForbidden = function(self, itemLink)
        if not itemLink then return false end
        local _, _, _, _, _, itemType, itemSubType = GetItemInfo(itemLink)
        return itemType == "Armor" and itemSubType == "Leather"
    end,
    isWeaponAllowed = function(self, itemLink) return true end,
	IsUnitForbidden = function(self, unit)
        if not unit or not UnitExists(unit) then return false end
        return UnitCreatureType(unit) == "Beast" and UnitCanAttack("player", unit)
    end,

    EventHandler = function(self, event, ...)
        if event == "PLAYER_TARGET_CHANGED" then
            if UnitExists("target") and UnitCanAttack("player", "target") then
                local targetGUID = UnitGUID("target")
                local creatureType = UnitCreatureType("target")
                if targetGUID and creatureType then
                    self.beastsInCombat[targetGUID] = creatureType
                end
            end
        elseif event == "PLAYER_LEAVE_COMBAT" or event == "PLAYER_REGEN_ENABLED" then
            self.beastsInCombat = {}
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellId, spellName = CombatLogGetCurrentEventInfo()
            if sourceGUID == UnitGUID("player") and subEvent == "SPELL_CAST_SUCCESS" then
                local bearFormIDs = { [5487]=true, [9634]=true }
                if bearFormIDs[spellId] then
                    local db = Purity:GetDB()
                    if not db.challengeStats then db.challengeStats = {} end
                    db.challengeStats.shapeshiftCasts = (db.challengeStats.shapeshiftCasts or 0) + 1
					if _G["PurityCharacterPanel"] and _G["PurityCharacterPanel"]:IsShown() then
                        _G["UpdateCharacterPurity"]()
                    end
                end
            end

            if UnitLevel("player") >= 10 then
                if sourceGUID == UnitGUID("player") and (subEvent == "SPELL_CAST_SUCCESS" or subEvent == "SPELL_AURA_APPLIED") then
                    if self.forbiddenBalanceSpells[spellId] then
                        Purity:Violation("Used a forbidden Balance spell after level 10:\n" .. spellName); return;
                    end
                end
            end
            local _, subEvent, _, _, _, _, _, destGUID, destName, destFlags = CombatLogGetCurrentEventInfo()
            if subEvent == "UNIT_DIED" and destGUID and bit.band(destFlags, COMBATLOG_OBJECT_TYPE_NPC) > 0 then
                local creatureType = self.beastsInCombat[destGUID]
                if UnitAffectingCombat("player") and creatureType then
                    if creatureType == "Beast" then
                        Purity:Violation("You have broken your pact with the wilds.\nThe spirit of the slain beast cries out against you.")
                        return
                    end
                end
            end
        end
    end,
}

DruidModule.challenges.astrolabe = {
    id = "Astrolabe of Purity",
    challengeName = "Astrolabe of Purity",
    description = function()
        return "The Celestial Weaver. This Druid's power is bound to an Astrolabe of Purity, an instrument that demands perfect equilibrium between solar (Nature) and lunar (Arcane) forces. They have forsaken their primal connection to the beasts and the nurturing essence of life to focus on this cosmic balance. To keep the astrolabe aligned, they must weave their spells in a precise sequence, never allowing one celestial force to overpower the other."
    end,
    needsWeaponWarning = false,
    lastDamageSpellSchool = nil,

    natureDamageSpells = {
        [5176] = true, [5177] = true, [5178] = true, [5179] = true, [5180] = true, [8905] = true, [9756] = true, [9912] = true,
        [5570] = true,
        [16914] = true, [17401] = true, [17402] = true,
    },
    arcaneDamageSpells = {
        [8921] = true, [8924] = true, [8925] = true, [8926] = true, [8927] = true, [9833] = true, [9834] = true, [9835] = true, [9850] = true, [9851] = true, [9852] = true, [9853] = true,
        [2912] = true, [8949] = true, [8950] = true, [8951] = true, [9875] = true, [9876] = true, [25299] = true,
    },
    
    forbiddenFeralSpells = {[768]=true,[5487]=true,[9634]=true,[1079]=true,[5221]=true,[6807]=true,[779]=true,[780]=true,[99]=true,[1735]=true,[5229]=true,[5211]=true,[6795]=true,[8983]=true,[9005]=true,[9827]=true,[9846]=true,[9866]=true,[9892]=true,[9896]=true,[9908]=true,[9913]=true},
    forbiddenRestoSpells = {[5185]=true,[8936]=true,[774]=true,[20739]=true,[5186]=true,[5187]=true,[5188]=true,[5189]=true,[9758]=true,[9888]=true,[9889]=true,[8938]=true,[8939]=true,[8940]=true,[8941]=true,[9759]=true,[9856]=true,[9857]=true,[9858]=true,[8903]=true,[9760]=true,[9839]=true,[9840]=true,[9841]=true,[1058]=true,[467]=true,[26989]=true, [1126]=true},
    ignoredStartSpells = {[5185] = true, [1126] = true},

    GetRulesText = function()
        return {
            "|cffffd100Key Prohibitions:|r", "|cff261A0D  • You may not use Bear Form or Cat Form.|r", "|cff261A0D  • You may not learn or use any Restoration healing spells.|r", "|cff261A0D  • You may not allocate points in the Feral or Restoration talent trees.|r", " ", "|cffffd100Special Vow:|r", "|cff261A0D  • You must alternate between Nature and Arcane damaging spells.|r", "|cff261A0D  • Casting a damaging spell from the same school twice in a row will break your vow (resets each combat).|r", " ", "|cffffd100Challenge Conditions:|r", "|cff261A0D  • Must be started on a level 1 Druid.|r", "|cff261A0D  • Must be accepted before leveling to 2.|r", "|cff261A0D  • An uptime of at least 96.0% must be maintained.|r",
        }
    end,
    
    IsSpellForbidden = function(self, spellId) return self.forbiddenFeralSpells[spellId] or self.forbiddenRestoSpells[spellId] end,
    AuditKnownSpells = function(self, violationFunc)
        for i = 1, GetNumSpellTabs() do
            local _, _, _, numSpells = GetSpellTabInfo(i)
            for j = 1, numSpells do
                local spellID = GetSpellBookItemInfo(j, "spell")
                if spellID and not self.ignoredStartSpells[spellID] then
                    if self:IsSpellForbidden(spellID) then
                        violationFunc("Found forbidden spell '"..GetSpellInfo(spellID).."' known at time of challenge acceptance.")
                        return false
                    end
                end
            end
        end
        return true
    end,
    IsTalentForbidden = function(self, tabIndex) return tabIndex == 2 or tabIndex == 3 end,
    IsItemForbidden = function(self, itemLink) return false end,
    isWeaponAllowed = function(self, itemLink) return true end,
    IsUnitForbidden = function(self, unit) return false end,

    EventHandler = function(self, event, ...)
        if event == "PLAYER_LEAVE_COMBAT" or event == "PLAYER_REGEN_ENABLED" then
            self.lastDamageSpellSchool = nil
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
			local _, subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellId, spellName = CombatLogGetCurrentEventInfo()

			-- Stat tracking for celestial casts (reliable method)
			if sourceGUID == UnitGUID("player") and subEvent == "SPELL_CAST_SUCCESS" then
				if self.natureDamageSpells[spellId] or self.arcaneDamageSpells[spellId] then
					local db = Purity:GetDB()
					if not db.challengeStats then db.challengeStats = {} end
					db.challengeStats.celestialCasts = (db.challengeStats.celestialCasts or 0) + 1
					if _G["PurityCharacterPanel"] and _G["PurityCharacterPanel"]:IsShown() then
                        _G["UpdateCharacterPurity"]()
                    end
				end
			end

			-- Rule validation for alternating spell schools
			if sourceGUID ~= UnitGUID("player") or (subEvent ~= "SPELL_DAMAGE" and subEvent ~= "SPELL_PERIODIC_DAMAGE") then return end

			local currentSchool = nil
			if self.natureDamageSpells[spellId] then
				currentSchool = "Nature"
			elseif self.arcaneDamageSpells[spellId] then
				currentSchool = "Arcane"
			end

			if not currentSchool then return end

			if self.lastDamageSpellSchool == currentSchool then
				Purity:Violation("Broke the celestial balance by casting from the same magic school twice:\n" .. spellName)
				return
			end
			self.lastDamageSpellSchool = currentSchool
		end
	end,
}

Purity.ClassModules = Purity.ClassModules or {}
Purity.ClassModules.DRUID = DruidModule