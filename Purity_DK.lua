-- Purity AddOn - Death Knight Module (Corrected Version)

if not Purity then
    return
end

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

    -- This is the list of all DK starting gear IDs, taken from your debug log.
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
        
        -- THE FIX: Correctly extract the numerical item ID from the link string.
        local itemIDString = string.match(itemLink, "item:(%d+):")
        if not itemIDString then return false end

        local itemID = tonumber(itemIDString)

        -- Check if the item's ID exists in our table of forbidden starting gear.
        if itemID and self._forbiddenItemIDs[itemID] then
            return true -- It's a starting item, so it IS forbidden.
        end
        
        return false -- It's not a starting item, so it's allowed.
    end,

    EventHandler = function(self, event, ...)
        -- Check for equipment changes or bag updates
        if event == "PLAYER_EQUIPMENT_CHANGED" or event == "BAG_UPDATE" then
            Purity:CheckEquipmentState()
        
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellId = CombatLogGetCurrentEventInfo()
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
-- Challenge 2: Sigil of Purity (Corrected)
-----------------------------------------------------------------------

local SigilOfPurity = {
    id = "DK_SIGIL",
    challengeName = "Sigil of Purity",
    description = "This sigil marks a berserker's vow. The Knight focuses only on destruction, refusing to use any magic or item to heal their own wounds, relying only on natural recovery.",

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

    -- This list is now understood as containing SPELL IDs for abilities
    -- and ITEM IDs for all consumables.
    _forbiddenHealIDs = { 
        -- Class Abilities (Spell IDs)
        [49998] = "Death Strike", 
        [48982] = "Rune Tap",
        -- Potions (Item IDs)
        [39327] = "Noth's Special Brew", [40087] = "Powerful Rejuvenation Potion", [22850] = "Super Rejuvenation Potion", [18253] = "Major Rejuvenation Potion", [2456] = "Minor Rejuvenation Potion", [63144] = "Baradin's Wardens Healing Potion", [43569] = "Endless Healing Potion", [64994] = "Hellscream's Reach Healing Potion", [858] = "Lesser Healing Potion", [4596] = "Discolored Healing Potion", [118] = "Minor Healing Potion", [929] = "Healing Potion", [1710] = "Greater Healing Potion", [18839] = "Combat Healing Potion", [3928] = "Superior Healing Potion", [13446] = "Major Healing Potion", [32947] = "Auchenai Healing Potion", [23822] = "Healing Potion Injector", [28100] = "Volatile Healing Potion", [43531] = "Argent Healing Potion", [33934] = "Crystal Healing Potion", [33092] = "Healing Potion Injector", [22829] = "Super Healing Potion", [31852] = "Major Combat Healing Potion", [31853] = "Major Combat Healing Potion", [31839] = "Major Combat Healing Potion", [31838] = "Major Combat Healing Potion", [39671] = "Resurgent Healing Potion", [33447] = "Runic Healing Potion", [44698] = "Intravenous Healing Potion", [57191] = "Mythical Healing Potion", [80040] = "Endless Master Healing Potion", [76097] = "Master Healing Potion",
        -- Bandages (Item IDs)
		[14529] = "Runecloth Bandage", [14530] = "Heavy Runecloth Bandage", [21990] = "Netherweave Bandage", [21991] = "Heavy Netherweave Bandage", [34721] = "Frostweave Bandage", [38643] = "Thick Frostweave Bandage", [34722] = "Heavy Frostweave Bandage", [53049] = "Embersilk Bandage", [53050] = "Heavy Embersilk Bandage", [63391] = "Baradin's Wardens Bandage", [38640] = "Dense Frostweave Bandage", [64995] = "Hellscream's Reach Bandage", [53051] = "Dense Embersilk Bandage", [82829] = "Windwool Bandage", [72985] = "Windwool Bandage", [82830] = "Heavy Windwool Bandage", [72986] = "Heavy Windwool Bandage",
    },

    IsSpellForbidden = function(self, spellId)
        if spellId == 49998 or spellId == 48982 then
            return true
        end
        return false
    end,

    IsItemForbidden = function(self, itemLink)
        if not itemLink then return false end

        local itemID = tonumber(string.match(itemLink, "item:(%d+):"))
        if itemID and self._forbiddenHealIDs[itemID] then
            return true
        end

        local _, _, _, _, _, itemType, itemSubType = GetItemInfo(itemLink)
        if itemType == "Weapon" then
            if itemSubType == "Two-Handed Axes" or itemSubType == "Two-Handed Maces" or itemSubType == "Two-Handed Swords" then
                return false
            else 
                return true
            end
        end
        
        if itemSubType == "Food & Drink" then
            return true
        end

        return false
    end,
    
    EventHandler = function(self, event, ...)
        -- Rule 1: Detect forbidden healing
        if event == "UNIT_SPELLCAST_SUCCEEDED" then
            local unitID, _, _, spellId = ...
            if unitID == "player" then
                if self._forbiddenHealIDs[spellId] then
                    local name = self._forbiddenHealIDs[spellId]
                    Purity:Violation("Used a forbidden ability or item: " .. name .. ".")
                    return
                end
            end
        end
        
        -- Rule 2: Detect forbidden food buffs
        if event == "UNIT_AURA" then
            local unitID = ...
            if unitID == "player" then
                for i = 1, 40 do
                    local auraName = UnitAura("player", i)
                    if not auraName then break end
                    if auraName == "Well Fed" or auraName == "Food" then
                        Purity:Violation("The dead need no sustenance. Eating food is forbidden by the Sigil.")
                        return
                    end
                end
            end
        end

        -- THE FIX: Add stat tracking for Obliterate
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellId = CombatLogGetCurrentEventInfo()
            if sourceGUID == UnitGUID("player") and subEvent == "SPELL_CAST_SUCCESS" then
                -- Check for any rank of Obliterate
                if spellId == 49020 or spellId == 51425 then
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
-- Challenge 3: Phylactery of Purity
-----------------------------------------------------------------------

-- In Purity_DK.lua

local PhylacteryOfPurity = {
    id = "DK_PHYLACTERY",
    challengeName = "Phylactery of Purity",
    description = "The soul of a sacrificed Shadow Council Warlock is bound into this phylactery. It grants you power, but binds you to their dark legacy, forcing you to reject the Lich King's chilling frost magic entirely.",
    
    _forbiddenFrostSpellIDs = {
        -- Core Frost Abilities
        [45477] = "Icy Touch", [49143] = "Frost Strike", [49020] = "Obliterate", [49184] = "Howling Blast", [45524] = "Chains of Ice", [51271] = "Pillar of Frost", [49203] = "Hungering Cold",
        -- Frost Defensive & Utility
        [48792] = "Icebound Fortitude", [47528] = "Mind Freeze", [49222] = "Path of Frost",
    },

    -- THE FIX: This function has been rewritten to be more flavorful.
    GetRulesText = function(self)
        return {
            "|cffffd100The Phylactery's Vow:|r",
            "|cff261A0D  • Your soul is bound to a phylactery containing the spirit of a Shadow Council Warlock, sacrificed to grant you power.|r",
            "|cff261A0D  • Their legacy of shadow magic rejects the Lich King's chilling influence, binding you to a new path.|r",
            " ",
            "|cffffd100Your Inherited Prohibitions:|r",
            "|cff261A0D  • You may NOT learn or use any Frost spells or abilities.|r",
            "|cff261A0D  • You may NOT allocate any points in the Frost talent tree.|r",
            " ",
            "|cffffd100Challenge Conditions:|r",
            "|cff261A0D  • An uptime of at least 96.0% must be maintained.|r",
        }
    end,

    IsSpellForbidden = function(self, spellId)
        return self._forbiddenFrostSpellIDs[spellId]
    end,

    IsTalentForbidden = function(self, tabIndex)-- In Purity.lua, replace the entire "OnShow" function with this one.

Purity.optInFrame:SetScript("OnShow", function(frame)
    Purity:DisplayChallengeDetails({
        challengeName = "Welcome to the Path of Purity",
        description = function() 
            return "Your journey begins here. Choose your path from the options on the left, then check the box and accept."
        end,
        GetRulesText = function() 
            return {
                "|cffffd100How to Begin:|r",
                " ",
                "|cff261A0D• |cffffd100Choose a Vow:|r Select a single challenge to undertake from level 1.",
                "|cff261A0D• |cffC41E3ADestine for a DK Path:|r Optionally, choose a Death Knight path to commit this character to a future sacrifice.",
                "|cff261A0D• You may choose to undertake one Vow, one DK path, or one from each.",
                "|cff261A0D• Alternatively, click the Decline button to play normally without a challenge.|r",
                " ",
                "|cffffd100Leaderboard Scoring:|r",
                " ",
                "|cff261A0D• If you choose both a Vow and a DK Path, your final score will be a weighted average of both challenges, representing your entire journey.",
            }
        end
    })
    Purity.selectedVow = nil
    Purity.selectedDKPath = nil
    
    local _, playerClass = UnitClass("player")
    local playerClassName = playerClass and string.upper(playerClass) or nil

    local availableVows = {}
    local availableDKPaths = {}

    local classModule = Purity.ClassModules and Purity.ClassModules[playerClassName]
    if classModule then
        for id, data in pairs(classModule.challenges) do table.insert(availableVows, data) end
    end
    if Purity.GlobalModules then
        for id, data in pairs(Purity.GlobalModules) do table.insert(availableVows, data) end
    end
    
    local dkModule = Purity.ClassModules and Purity.ClassModules["DEATHKNIGHT"]
    if dkModule then
        for _, data in ipairs(dkModule.challenges) do
            -- THE FIX: This 'if' statement prevents the standard Phylactery challenge
            -- from being added to the general list for all classes.
            if data.id ~= "DK_PHYLACTERY" then
                table.insert(availableDKPaths, data)
            end
        end
    end

    -- This block now correctly adds the SPECIAL version, only for Warlocks.
    if playerClass == "WARLOCK" then
        table.insert(availableDKPaths, {
            challengeName = "Phylactery of Purity",
            description = function() return "|cff8788eeSPECIAL VOW:|r Dedicate this Warlock to a future sacrifice. If the vow is completed with the 'Shadow Embrace' talent learned, your new Death Knight will inherit the Phylactery of Purity challenge, forbidding the use of Frost magic." end,
            GetRulesText = function()
                return {
                    "|cffffd100A Warlock's Legacy|r",
                    "|cff261A0D  • This is a special destiny path for Warlocks only.|r",
                    "|cff261A0D  • You must level this character and take the 'Shadow Embrace' talent from the Affliction tree.|r",
                    "|cff261A0D  • When you are ready, use the Death Knight panel to perform the sacrifice.|r",
                    "|cff261A0D  • Your new Death Knight will be forbidden from using Frost spells and talents.|r"
                }
            end
        })
    end

    if frame.challengeWidgets then
        for _, widget in ipairs(frame.challengeWidgets) do widget:Hide() end
    end
    frame.challengeWidgets = {}
    frame.vowCheckboxes = {}
    frame.dkPathCheckboxes = {}

    local yOffset = -20
    
    local function CreateChallengeCheckbox(parent, challengeData, isDKPath)
        local list = isDKPath and frame.dkPathCheckboxes or frame.vowCheckboxes
        local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", 15, yOffset)
        local text = checkbox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        text:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
        text:SetText(challengeData.challengeName)
        if isDKPath then text:SetTextColor(0.8, 0.4, 0.4) end
        table.insert(list, checkbox)
        checkbox:SetScript("OnClick", function(self)
            local list = isDKPath and frame.dkPathCheckboxes or frame.vowCheckboxes
            if self:GetChecked() then
                for _, otherBox in ipairs(list) do
                    if otherBox ~= self then otherBox:SetChecked(false) end
                end
                if isDKPath then Purity.selectedDKPath = challengeData else Purity.selectedVow = challengeData end
            else
                if isDKPath then Purity.selectedDKPath = nil else Purity.selectedVow = nil end
            end
            Purity:DisplayChallengeDetails(challengeData)
        end)
        yOffset = yOffset - 30
        table.insert(frame.challengeWidgets, checkbox)
        table.insert(frame.challengeWidgets, text)
    end

    local vowHeader = frame.leftPane:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    vowHeader:SetPoint("TOPLEFT", 15, yOffset)
    vowHeader:SetText("Choose a Vow")
    table.insert(frame.challengeWidgets, vowHeader)
    yOffset = yOffset - 35
    
    table.sort(availableVows, function(a, b) return a.challengeName < b.challengeName end)
    for _, vow in ipairs(availableVows) do
        CreateChallengeCheckbox(frame.leftPane, vow, false)
    end
    
    yOffset = yOffset - 20
    local dkHeader = frame.leftPane:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    dkHeader:SetPoint("TOPLEFT", 15, yOffset)
    dkHeader:SetText("|cffC41E3ADestine for a DK|r")
    table.insert(frame.challengeWidgets, dkHeader)
    yOffset = yOffset - 35

    for _, path in ipairs(availableDKPaths) do
        CreateChallengeCheckbox(frame.leftPane, path, true)
    end
end)
        return tabIndex == 2
    end,

    EventHandler = function(self, event, ...)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellId = CombatLogGetCurrentEventInfo()
            if sourceGUID == UnitGUID("player") and subEvent == "SPELL_CAST_SUCCESS" then
                if spellId == 45462 then -- Scourge Strike
                    local db = Purity:GetDB()
                    db.challengeStats = db.challengeStats or {}
                    db.challengeStats.scourgeStrikes = (db.challengeStats.scourgeStrikes or 0) + 1
                end
            end
        end
    end
}
table.insert(DKModule.challenges, PhylacteryOfPurity)

-----------------------------------------------------------------------
-- Register the Module
-----------------------------------------------------------------------
Purity.ClassModules = Purity.ClassModules or {}
Purity.ClassModules["DEATHKNIGHT"] = DKModule