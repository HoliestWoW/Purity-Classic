-- Purity AddOn - Warrior Module

if not Purity then return end

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

local WarriorModule = {
    challenges = {}
}

local CHARGE_SPELL_IDS = {
    [100] = true,
    [6178] = true,
    [11578] = true,
    [20252] = true,
    [20616] = true,
    [20617] = true,
}
local DEFENSIVE_STANCE_ID = 71
local DUAL_WIELD_PASSIVE_ID = 674

WarriorModule.challenges.brand = {
    id = "WARRIOR_BRAND",
    challengeName = "Brand of Purity",
    description = "The Berserker. No shields or defensive stance. All combat must be initiated with Charge or Intercept, forsaking all caution.",
    needsWeaponWarning = true,
    optInWarningText = "|cffff0000IMPORTANT: Most Warriors begin with a shield. This challenge forbids shields at all times. You must unequip your shield before you begin.|r",
    hasChargedForCombat = false,

    GetRulesText = function()
        return {
            "|cffffd100Key Prohibitions:|r",
            "|cff261A0D  • You may NOT use shields at any time.|r",
            "|cff261A0D  • You may NOT use Defensive Stance.|r",
            "|cff261A0D  • After level 4, you may NOT initiate combat without using Charge or Intercept.|r",
            "|cff261A0D  • After level 20, equipping two-handed weapons is forbidden. Fishing poles are allowed.|r",
            " ",
            "|cffffd100Challenge Conditions:|r",
            "|cff261A0D  • Must be started on a level 1 Warrior.|r",
            "|cff261A0D  • Must be accepted before leveling to 2.|r",
            "|cff261A0D  • Must learn Charge before level 5.|r",
            "|cff261A0D  • Must learn Dual Wield before level 21.|r",
            "|cff261A0D  • You must transition to dual-wielding after level 20.|r",
            "|cff261A0D  • An uptime of at least 96.0% must be maintained.|r",
        }
    end,

    IsItemForbidden = function(self, itemLink)
        if not itemLink then return false end
        
        local itemName, _, _, _, _, itemType, itemSubType = GetItemInfo(itemLink)

        if itemSubType == "Shields" then
            return true
        end
		
		if itemSubType == "Fishing Pole" or itemSubType == "Fishing Poles" then
			return false
		end

        if UnitLevel("player") >= 20 then
            if itemType == "Weapon" and (itemSubType == "Two-Handed Axes" or itemSubType == "Two-Handed Maces" or itemSubType == "Two-Handed Swords" or itemSubType == "Polearms" or itemSubType == "Staves") then
                return true
            end
        end

        return false
    end,

    IsSpellForbidden = function(self, spellId)
        if not spellId then return false end
        return spellId == DEFENSIVE_STANCE_ID
    end,
    
    IsTalentForbidden = function(self, tabIndex)
        return false
    end,

    isWeaponAllowed = function(self)
        local playerLevel = UnitLevel("player")
        local mainHandLink = GetInventoryItemLink("player", INVSLOT_MAINHAND)
        local offHandLink = GetInventoryItemLink("player", INVSLOT_OFFHAND)

        if offHandLink then
            local _, _, _, _, _, _, offHandSubType = GetItemInfo(offHandLink)
            if offHandSubType == "Shields" then
                return false
            end
        end

        if playerLevel >= 20 then
            if mainHandLink then
                local _, _, _, _, _, mainHandType, mainHandSubType = GetItemInfo(mainHandLink)
                
                if mainHandSubType == "Fishing Poles" or mainHandSubType == "Fishing Pole" then
                    return true
                end

                if mainHandType == "Weapon" and (mainHandSubType == "Two-Handed Axes" or mainHandSubType == "Two-Handed Maces" or mainHandSubType == "Two-Handed Swords" or mainHandSubType == "Polearms" or mainSubType == "Staves") then
                    return false
                end
            end
        end

        return true
    end,

EventHandler = function(self, event, ...)
        local playerLevel = UnitLevel("player")
        
        if event == "PLAYER_EQUIPMENT_CHANGED" then
            Purity:CheckWeaponState()
        
        elseif event == "PLAYER_LEVEL_UP" then
            local newLevel = ...
            if newLevel == 5 and not IsSpellKnown(100) then
                Purity:Violation("Failed to learn Charge before level 5.")
            elseif newLevel == 21 and not IsSpellKnown(DUAL_WIELD_PASSIVE_ID) then
                Purity:Violation("Failed to learn Dual Wield before level 21.")
            elseif newLevel == 4 then
                Purity:ShowRuleUpdate("The Brand of Purity awakens. Your vow demands you learn Charge before you grow any stronger and use it to initiate all combat henceforth.")
            elseif newLevel == 20 then
                Purity:ShowRuleUpdate("Your Brand of Purity sears with power. It now rejects the slow might of a two-handed weapon, demanding the pure fury of a blade in each hand.")
            end
            Purity:CheckWeaponState()
        
        elseif event == "PLAYER_REGEN_ENABLED" then
            self.hasChargedForCombat = false
        
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, subEvent, _, sourceGUID, _, _, _, destGUID, _, _, _, spellId = CombatLogGetCurrentEventInfo()

            if sourceGUID == UnitGUID("player") and subEvent == "SPELL_CAST_SUCCESS" then
                if CHARGE_SPELL_IDS[spellId] then
                    local db = Purity:GetDB()
                    if not db.challengeStats then db.challengeStats = {} end
                    db.challengeStats.chargeInterceptCasts = (db.challengeStats.chargeInterceptCasts or 0) + 1
                    self.hasChargedForCombat = true
                end
            end
            
            if GetShapeshiftForm() == 2 then
                Purity:Violation("Used the forbidden Defensive Stance.")
                return
            end
            
            if playerLevel >= 4 then
                if UnitAffectingCombat("player") then
                    if sourceGUID == UnitGUID("player") and not self.hasChargedForCombat then
                        
                        local isSafeSpell = false
                        if subEvent == "SPELL_CAST_SUCCESS" then
                            if spellId == 2457 or spellId == 2458 or spellId == 2687 or spellId == 6673 or spellId == 5242 or spellId == 6192 or spellId == 11549 or spellId == 11550 or spellId == 11551 then
                                isSafeSpell = true
                            end
                        end

                        if not isSafeSpell and (subEvent == "SWING_DAMAGE" or subEvent == "SPELL_DAMAGE" or subEvent == "SPELL_CAST_SUCCESS") then
                            Purity:Violation("Initiated combat with an attack without using Charge first.")
                        end
                    end
                end
            end
        end
    end,
}


WarriorModule.challenges.bulwark = {
    id = "WARRIOR_BULWARK",
    challengeName = "Bulwark of Purity",
    description = "The Ardent Protector. You are not allowed to wield Two-Handed Weapons. Your conviction of protecting others gives you a calm mind. No talent points can be allocated in Fury Tree.",
    needsWeaponWarning = true,
    optInWarningText = "|cffff0000IMPORTANT: Some Warriors begin with a Two-Handed Weapon. This challenge forbids them at all times. You must unequip it before you begin.|r",

    GetRulesText = function()
        return {
            "|cffffd100Key Prohibitions:|r",
            "|cff261A0D  • You may NOT equip Two-Handed weapons at any time.|r",
            "|cff261A0D  • You may NOT allocate any talent points in the Fury talent tree.|r",
            " ",
            "|cffffd100Challenge Conditions:|r",
            "|cff261A0D  • Must be started on a level 1 Warrior.|r",
            "|cff261A0D  • Must be accepted before leveling to 2.|r",
            "|cff261A0D  • An uptime of at least 96.0% must be maintained.|r",
        }
    end,

    IsItemForbidden = function(self, itemLink)
        if not itemLink then return false end
        local _, _, _, _, _, itemType, itemSubType = GetItemInfo(itemLink)

        if itemType == "Weapon" then
            if  itemSubType == "Two-Handed Axes" or 
                itemSubType == "Two-Handed Maces" or 
                itemSubType == "Two-Handed Swords" or 
                itemSubType == "Polearms" or 
                itemSubType == "Staves" 
            then
                return true
            end
        end
        return false
    end,

    IsTalentForbidden = function(self, id)
        return IsIDInForbiddenTree(id, "Fury")
    end,

    IsSpellForbidden = function(self, spellId)
        return false
    end,

    isWeaponAllowed = function(self)
        return true
    end,

    EventHandler = function(self, event, ...)
        if event == "PLAYER_EQUIPMENT_CHANGED" then
            Purity:CheckWeaponState()
            
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, subEvent, _, _, _, _, _, destGUID, _, _, _, missType = CombatLogGetCurrentEventInfo()
            if destGUID == UnitGUID("player") and subEvent == "SWING_MISSED" and missType == "BLOCK" then
                local db = Purity:GetDB()
                db.challengeStats = db.challengeStats or {}
                db.challengeStats.blocks = (db.challengeStats.blocks or 0) + 1
				if _G["PurityCharacterPanel"] and _G["PurityCharacterPanel"]:IsShown() then
                    _G["UpdateCharacterPurity"]()
                end
            end
		elseif event == "PLAYER_TALENT_UPDATE" then
            local numTabs = GetNumTalentTabs()
            for t = 1, numTabs do
                local _, name = GetTalentTabInfo(t)
                if name == "Fury" then
                    for i = 1, GetNumTalents(t) do
                        local _, _, _, _, pointsSpent = GetTalentInfo(t, i)
                        if pointsSpent and pointsSpent > 0 then
                            Purity:Violation("Allocated points in the forbidden\nFury talent tree.")
                            return
                        end
                    end
                end
            end
        end
    end,
}

Purity.ClassModules = Purity.ClassModules or {}
Purity.ClassModules.WARRIOR = WarriorModule