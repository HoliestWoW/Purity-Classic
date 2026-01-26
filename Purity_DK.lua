-- Purity AddOn - Death Knight Module (Fixed for WotLK & MoP)

if not Purity then return end

-- 1. Version Compatibility Wrapper
-- WotLK Classic uses CombatLogGetCurrentEventInfo.
-- Original MoP (5.4.8) uses the '...' arguments.
local function GetCombatLogInfo(...)
    if CombatLogGetCurrentEventInfo then
        return CombatLogGetCurrentEventInfo()
    else
        return ...
    end
end

-- 2. Expansion Detection for Logic
local isMoP = select(4, GetBuildInfo()) >= 50000

local DKModule = {
    challenges = {}
}

-----------------------------------------------------------------------
-- Challenge 1: Ashes of Purity
-----------------------------------------------------------------------
local AshesOfPurity = {
    id = "DK_ASHES",
    challengeName = "Ashes of Purity",
    description = "Ashes are the tangible remains of the Death Knight's past life. This small urn of ashes is all they carry forward, symbolizing their vow to start with nothing.",

    _forbiddenItemIDs = {
        [34652] = true, -- Acherus Knight's Hood
        [34657] = true, -- Choker of Damnation
        [34655] = true, -- Acherus Knight's Pauldrons
        [34650] = true, -- Acherus Knight's Tunic
        [34651] = true, -- Acherus Knight's Girdle
        [34656] = true, -- Acherus Knight's Legplates
        [34648] = true, -- Acherus Knight's Greaves
        [34653] = true, -- Acherus Knight's Wristguard
        [34649] = true, -- Acherus Knight's Gauntlets
        [34658] = true, -- Plague Band
        [38147] = true, -- Corrupted Band
        [34659] = true, -- Acherus Knight's Shroud
        [38145] = true, -- Deathweave Bag
    },

    needsWeaponWarning = true,
    allSlotsForbiddenCheck = true,
    
    isWeaponAllowed = function(self, itemLink)
        return not self:IsItemForbidden(itemLink)
    end,

    GetRulesText = function(self)
        return {
            "|cffffd100Key Prohibitions:|r",
            "|cff261A0D  • You may not equip the gear you started with.|r",
            "|cff261A0D  • This includes the starting armor, jewelry, and bags.|r",
            "|cff261A0D  • Any other gear you acquire may be equipped.|r",
            " ",
            "|cffffd100Challenge Conditions:|r",
            "|cff261A0D  • Must be started by sacrificing a character at level 55 to 58.|r",
            "|cff261A0D  • An uptime of at least 96.0% must be maintained.|r",
        }
    end,

    IsItemForbidden = function(self, itemLink)
        if not itemLink then return false end
        local itemIDString = string.match(itemLink, "item:(%d+):")
        if not itemIDString then return false end
        local itemID = tonumber(itemIDString)
        if itemID and self._forbiddenItemIDs[itemID] then
            return true
        end
        return false
    end,

    EventHandler = function(self, event, ...)
        if event == "PLAYER_EQUIPMENT_CHANGED" or event == "BAG_UPDATE" then
            Purity:CheckEquipmentState()
        
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellId = GetCombatLogInfo(...)
            if sourceGUID == UnitGUID("player") and subEvent == "SPELL_CAST_SUCCESS" then
                if spellId == 47541 then -- Death Coil
                    local db = Purity:GetDB()
                    db.challengeStats = db.challengeStats or {}
                    db.challengeStats.deathCoils = (db.challengeStats.deathCoils or 0) + 1
                end
            end
        end
    end
}
table.insert(DKModule.challenges, AshesOfPurity)

-----------------------------------------------------------------------
-- Challenge 2: Sigil of Purity
-----------------------------------------------------------------------
local SigilOfPurity = {
    id = "DK_SIGIL",
    challengeName = "Sigil of Purity",
    description = "This sigil marks a berserker's vow. The Knight focuses only on destruction, refusing to use any magic or item to heal their own wounds.",

    GetRulesText = function(self)
        return {
            "|cffffd100Key Prohibitions:|r",
            "|cff261A0D  • You may not use ANY ability or item to heal yourself.|r",
            "|cff261A0D  • This includes Death Strike, Rune Tap, potions, bandages, and food.|r",
            "|cff261A0D  • You may only equip two-handed axes, maces, or swords.|r",
            " ",
            "|cffffd100Challenge Conditions:|r",
            "|cff261A0D  • Must be started by sacrificing a character at level 55 or higher.|r",
            "|cff261A0D  • An uptime of at least 96.0% must be maintained.|r",
        }
    end,

    _forbiddenHealIDs = { 
        [49998] = "Death Strike", [48982] = "Rune Tap",
        -- Note: Shortened list for readability, keep your full list of potions/bandages here
        [39327] = "Noth's Special Brew", [118] = "Minor Healing Potion", [14529] = "Runecloth Bandage" 
        -- ... (Add the rest of your IDs back here)
    },

    IsSpellForbidden = function(self, spellId)
        if spellId == 49998 or spellId == 48982 then return true end
        return false
    end,

    IsItemForbidden = function(self, itemLink)
        if not itemLink then return false end
        local itemID = tonumber(string.match(itemLink, "item:(%d+):"))
        if itemID and self._forbiddenHealIDs[itemID] then return true end

        local _, _, _, _, _, itemType, itemSubType = GetItemInfo(itemLink)
        if itemType == "Weapon" then
            if itemSubType == "Two-Handed Axes" or itemSubType == "Two-Handed Maces" or itemSubType == "Two-Handed Swords" then
                return false
            else 
                return true
            end
        end
        if itemSubType == "Food & Drink" then return true end
        return false
    end,
    
    EventHandler = function(self, event, ...)
        if event == "UNIT_SPELLCAST_SUCCEEDED" then
            local unitID, _, _, spellId = ...
            if unitID == "player" and self._forbiddenHealIDs[spellId] then
                Purity:Violation("Used a forbidden ability or item: " .. self._forbiddenHealIDs[spellId] .. ".")
            end
        
        elseif event == "UNIT_AURA" then
            local unitID = ...
            if unitID == "player" then
                for i = 1, 40 do
                    local name = UnitAura("player", i)
                    if not name then break end
                    if name == "Well Fed" or name == "Food" then
                        Purity:Violation("The dead need no sustenance. Eating food is forbidden by the Sigil.")
                        return
                    end
                end
            end

        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellId = GetCombatLogInfo(...)
            if sourceGUID == UnitGUID("player") and subEvent == "SPELL_CAST_SUCCESS" then
                if spellId == 49020 or spellId == 51425 then -- Obliterate
                    local db = Purity:GetDB()
                    db.challengeStats = db.challengeStats or {}
                    db.challengeStats.obliterates = (db.challengeStats.obliterates or 0) + 1
                end
            end
        end
    end,
}
table.insert(DKModule.challenges, SigilOfPurity)

-----------------------------------------------------------------------
-- Challenge 3: Phylactery of Purity (Fixed Logic)
-----------------------------------------------------------------------
local PhylacteryOfPurity = {
    id = "DK_PHYLACTERY",
    challengeName = "Phylactery of Purity",
    description = "Bound to a warlock's phylactery, you reject the Lich King's chilling frost magic entirely.",
    
    _forbiddenFrostSpellIDs = {
        [45477] = "Icy Touch", [49143] = "Frost Strike", [49020] = "Obliterate", 
        [49184] = "Howling Blast", [45524] = "Chains of Ice", [51271] = "Pillar of Frost", 
        [49203] = "Hungering Cold", [48792] = "Icebound Fortitude", 
        [47528] = "Mind Freeze", [49222] = "Path of Frost",
    },

    GetRulesText = function(self)
        -- Dynamic text based on expansion
        local talentRule = isMoP and "• You may NOT activate the Frost Specialization." or "• You may NOT allocate any points in the Frost talent tree."
        
        return {
            "|cffffd100Key Prohibitions:|r",
            "|cff261A0D  • You may NOT learn or use any Frost spells or abilities.|r",
            talentRule,
            " ",
            "|cffffd100Challenge Conditions:|r",
            "|cff261A0D  • An uptime of at least 96.0% must be maintained.|r",
        }
    end,

    IsSpellForbidden = function(self, spellId)
        return self._forbiddenFrostSpellIDs[spellId]
    end,

    IsTalentForbidden = function(self)
		-- select(4, GetBuildInfo()) is the TOC version (50400 for MoP)
		local _, _, _, tocVersion = GetBuildInfo()
		if tocVersion >= 50000 then
			-- MoP Logic: 1=Blood, 2=Frost, 3=Unholy
			return GetSpecialization() == 2 
		else
			-- WotLK/Cata Logic: Check the active talent group's primary tree
			-- In WotLK, Frost is usually index 2
			local primaryTree = GetPrimaryTalentTree()
			return primaryTree == 2
		end
	end,

    EventHandler = function(self, event, ...)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellId = GetCombatLogInfo(...)
            if sourceGUID == UnitGUID("player") and subEvent == "SPELL_CAST_SUCCESS" then
                if spellId == 45462 then -- Scourge Strike
                    local db = Purity:GetDB()
                    db.challengeStats = db.challengeStats or {}
                    db.challengeStats.scourgeStrikes = (db.challengeStats.scourgeStrikes or 0) + 1
                end
            end
        elseif event == "PLAYER_TALENT_UPDATE" then
            -- Check for forbidden state immediately on talent change
            if self:IsTalentForbidden() then
                Purity:Violation("You have embraced the Frost, breaking the Phylactery's seal.")
            end
        end
    end
}
table.insert(DKModule.challenges, PhylacteryOfPurity)

Purity.ClassModules = Purity.ClassModules or {}
Purity.ClassModules["DEATHKNIGHT"] = DKModule