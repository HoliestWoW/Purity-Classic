-- Purity AddOn - Shaman Module

if not Purity then
    return
end

local ShamanModule = {
    challenges = {},
    isAddonFullyLoaded = false,
}

ShamanModule.challenges.COMMUNION = {
    challengeName = "Communion of Purity",
    id = "COMMUNION",
    description = "The Spirit Walker. Your power flows purely from your spells and maintaining active totems in combat. No weapons of any kind.",
    needsWeaponWarning = true,
    optInWarningText = "|cffff0000IMPORTANT: This challenge forbids all weapons. You must unequip your mace before you begin.|r",
    KEY_TOTEM_SPELL_ID = 8071,

    activeTotemSlots = {
        [FIRE_TOTEM_SLOT] = false,
        [EARTH_TOTEM_SLOT] = false,
        [WATER_TOTEM_SLOT] = false,
        [AIR_TOTEM_SLOT] = false
    },
    totemCombatCheckTicker = nil,

    GetRulesText = function(self)
        return {
            "|cffffd100Key Prohibitions:|r",
            "|cff261A0D  • You may NOT equip any weapons of any kind.|r",
            "|cff261A0D  • You must always maintain at least one active totem while in combat (after totems unlocked).|r",
            "|cff261A0D  • You must learn your first totem spell and complete the quest before reaching Level 6.|r",
            " ",
            "|cffffd100Challenge Conditions:|r",
            "|cff261A0D  • Must be started on a level 1 Shaman.|r",
            "|cff261A0D  • Must be accepted before leveling to 2.|r",
            "|cff261A0D  • An uptime of at least 96.0% must be maintained.|r",
        }
    end,

    isWeaponAllowed = function(self, itemLink)
        if not itemLink then return true end
        local _, _, _, _, _, itemType, itemSubType = GetItemInfo(itemLink)
        if itemType == "Weapon" and itemSubType ~= "Fishing Pole" then
            return false
        end
        return true
    end,

    IsItemForbidden = function(self, itemLink)
        if not itemLink then return false end
        return not self:isWeaponAllowed(itemLink)
    end,

    CheckActiveTotems = function(self)
        if not Purity:GetDB().hasCompletedShamanTotemQuest then return end
        if not UnitAffectingCombat("player") then return end

        local hasActiveTotem = false
        for _, isActive in pairs(self.activeTotemSlots) do
            if isActive then
                hasActiveTotem = true
                break
            end
        end

        if not hasActiveTotem then
            Purity:Violation("Failed to maintain an active totem in combat.")
            if self.totemCombatCheckTicker then
                self.totemCombatCheckTicker:Cancel()
                self.totemCombatCheckTicker = nil
            end
        end
    end,

    EventHandler = function(self, event, ...)
        local currentDB = Purity:GetDB()
        if event == "PLAYER_TOTEM_UPDATE" then
            local totemSlot = ...
            local haveTotem, _, _, duration = GetTotemInfo(totemSlot)
            self.activeTotemSlots[totemSlot] = (haveTotem and duration > 0)
        elseif event == "PLAYER_EQUIPMENT_CHANGED" then
            Purity:CheckWeaponState()
        elseif event == "PLAYER_REGEN_DISABLED" then
            if currentDB.hasCompletedShamanTotemQuest and not self.totemCombatCheckTicker then
                self.totemCombatCheckTicker = C_Timer.NewTicker(1.0, function() self:CheckActiveTotems() end)
            end
        elseif event == "PLAYER_REGEN_ENABLED" then
            if self.totemCombatCheckTicker then
                self.totemCombatCheckTicker:Cancel()
                self.totemCombatCheckTicker = nil
            end
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellId = CombatLogGetCurrentEventInfo()
            if sourceGUID == UnitGUID("player") and subEvent == "SPELL_CAST_SUCCESS" then
                local lightningBoltIDs = { [403]=true, [529]=true, [548]=true, [915]=true, [943]=true, [6041]=true, [10391]=true, [10392]=true, [15207]=true, [15208]=true }
                if lightningBoltIDs[spellId] then
                    local db = Purity:GetDB()
                    if not db.challengeStats then db.challengeStats = {} end
                    db.challengeStats.lightningBoltCasts = (db.challengeStats.lightningBoltCasts or 0) + 1
					if _G["PurityCharacterPanel"] and _G["PurityCharacterPanel"]:IsShown() then
                        _G["UpdateCharacterPurity"]()
                    end
                end
            end
        end
    end
}

ShamanModule.challenges.FLAME = {
    challengeName = "Flame of Purity",
    id = "FLAME",
    description = "You begin as a normal Shaman, but at level 10 your path changes. Your spirit awakens to the flame, forsaking all other elements. From that moment on, you may only use Fire spells, Fire totems, and physical attacks.",
    needsWeaponWarning = false,

    GetRulesText = function(self)
        return {
            "|cffffd100The Awakening:|r",
            "|cff261A0D  • From level 1 to 9, you are free to use any Shaman ability.|r",
            "|cff261A0D  • Upon reaching Level 10, your vow begins and the following rules apply for the remainder of the challenge:|r",
            " ",
            "|cffffd100Level 10+ Prohibitions:|r",
            "|cff261A0D  • Only Fire spells may be cast (including weapon imbuements).|r",
            "|cff261A0D  • Only Fire totems may be used.|r",
            " ",
            "|cffffd100Challenge Conditions:|r",
            "|cff261A0D  • Must be started on a level 1 Shaman.|r",
            "|cff261A0D  • Must be accepted before leveling to 2.|r",
            "|cff261A0D  • An uptime of at least 96.0% must be maintained.|r",
        }
    end,

    IsSpellForbidden = function(self, spellId)
        if UnitLevel("player") < 10 then
            return false
        end

        if not spellId then return false end

        local allowedSpellIds = {
            [8050] = true,
			[8024] = true,
			[3599] = true,
			[1535] = true,
			[8052] = true,
			[8027] = true,
			[6363] = true,
			[8498] = true,
			[8181] = true,
			[8030] = true,
			[8190] = true,
			[8184] = true,
			[8053] = true,
			[8227] = true,
			[6364] = true,
			[8499] = true,
			[16339] = true,
			[10585] = true,
			[8249] = true,
			[10478] = true,
			[10447] = true,
			[6365] = true,
			[11314] = true,
			[10537] = true,
			[16341] = true,
			[10586] = true,
			[10526] = true,
			[10437] = true,
			[11315] = true,
			[10448] = true,
			[10479] = true,
			[16342] = true,
			[10587] = true,
			[10538] = true,
			[16387] = true,
			[2645] = true,
			[131] = true,
			[6196] = true,
			[546] = true,
			[556] = true,
        }
		
        if allowedSpellIds[spellId] then return false end
        
        local _, _, _, _, _, _, _, school = GetSpellInfo(spellId)
        if school == 1 then return false end

        return true
    end,

        IsItemForbidden = function(self, itemLink)
        return false
    end,

    EventHandler = function(self, event, ...)
        if UnitLevel("player") < 10 then return end

        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellId, spellName = CombatLogGetCurrentEventInfo()
            if sourceGUID == UnitGUID("player") and subEvent == "SPELL_CAST_SUCCESS" then
                if self:IsSpellForbidden(spellId) then
                    Purity:Violation("Used a forbidden spell after awakening: " .. (spellName or "Unknown"))
                else
                    local _, _, _, _, _, _, _, _, school = GetSpellInfo(spellId)
                    if school and school == 4 then
                        local db = Purity:GetDB()
                        if not db.challengeStats then db.challengeStats = {} end
                        db.challengeStats.fireSpellCasts = (db.challengeStats.fireSpellCasts or 0) + 1
						if _G["PurityCharacterPanel"] and _G["PurityCharacterPanel"]:IsShown() then
							_G["UpdateCharacterPurity"]()
						end
                    end
                end
            end
        elseif event == "PLAYER_TOTEM_UPDATE" then
            local totemSlot = ...
            if totemSlot ~= FIRE_TOTEM_SLOT then
                local haveTotem, _, _, _ = GetTotemInfo(totemSlot)
                if haveTotem then Purity:Violation("Used a non-Fire totem after awakening.") end
            end
        end
    end
}

function ShamanModule:GetActiveChallengeObject()
    local db = Purity:GetDB()
    if not db.isOptedIn or not db.activeChallengeID then return nil end
    return self.challenges[db.activeChallengeID]
end

function ShamanModule:GetRulesText()
    local activeChallenge = self:GetActiveChallengeObject()
    if activeChallenge and activeChallenge.GetRulesText then
        return activeChallenge:GetRulesText()
    end
    return {"No active Shaman challenge."}
end

function ShamanModule:IsItemForbidden(itemLink)
    local activeChallenge = self:GetActiveChallengeObject()
    if activeChallenge and activeChallenge.IsItemForbidden then
        return activeChallenge:IsItemForbidden(itemLink)
    end
    return false
end

function ShamanModule:IsSpellForbidden(spellId)
    local activeChallenge = self:GetActiveChallengeObject()
    if activeChallenge and activeChallenge.IsSpellForbidden then
        return activeChallenge:IsSpellForbidden(spellId)
    end
    return false
end

function ShamanModule:isWeaponAllowed(itemLink)
    local activeChallenge = self:GetActiveChallengeObject()
    if activeChallenge and activeChallenge.isWeaponAllowed then
        return activeChallenge:isWeaponAllowed(itemLink)
    end
    return true
end

function ShamanModule:EventHandler(event, ...)
    local activeChallenge = self:GetActiveChallengeObject()
    if activeChallenge and activeChallenge.EventHandler then
        activeChallenge:EventHandler(event, ...)
    end

    if event == "PLAYER_LEVEL_UP" then
        local newLevel = ...
        if newLevel == 10 and Purity:GetDB().activeChallengeID == "FLAME" then
            Purity:ShowRuleUpdate("The Call of the Flame has awakened! From this moment on, you must adhere to its rules: only Fire and Physical abilities are permitted.")
        end
    end
end

function ShamanModule:InitializeOnPlayerEnterWorld()
    self.isAddonFullyLoaded = true
    self:EventHandler("SPELLS_CHANGED") 
end

Purity.ClassModules = Purity.ClassModules or {}
Purity.ClassModules.SHAMAN = ShamanModule