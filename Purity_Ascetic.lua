-- Purity AddOn - The Ascetic's Path Challenge

if not Purity then return end

-- Create a dedicated, hidden tooltip for internal checks to avoid UI interference.
PurityCheckTooltip = CreateFrame("GameTooltip", "PurityCheckTooltip", UIParent, "GameTooltipTemplate")
PurityCheckTooltip:Hide()

local DIFFICULTY_COLORS = {
    EASY = "|cff0070dd",
    MEDIUM = "|cffa335ee",
    HARD = "|cffff8000"
}

-- Define the module table FIRST, so other functions can see it.
local AsceticModule = {
    challengeName = "The Ascetic's Path",
    description = "A challenge of self-denial. You must limit your reliance on material possessions, choosing a path of increasing difficulty to prove your conviction.",
    isGlobalChallenge = true,
    needsWeaponWarning = false,
    selectedDifficultyId = nil,
    lastItemSaleAttempt = nil, -- For two-step sale confirmation

    specializations = {
        -- ... (specialization data remains the same) ...
        { name = "Path of Humility", buttonText = "Path of Humility", id = "EASY", description = "Only items of Common (white) quality or lower may be equipped.", IsItemForbidden = function(itemLink) if not itemLink then return false end local _, _, itemRarity, _, _, itemType = GetItemInfo(itemLink) if itemType ~= "Armor" and itemType ~= "Weapon" then return false end return itemRarity and itemRarity > 1 end },
        { name = "Path of Resilience", buttonText = "Path of Resilience", id = "MEDIUM", description = "No armor may be worn. Weapons and shields are permitted.", IsItemForbidden = function(itemLink) if not itemLink then return false end local _, _, _, _, _, itemType = GetItemInfo(itemLink) return itemType == "Armor" end },
        { name = "Path of the Unburdened", buttonText = "Path of the Unburdened", id = "HARD", description = "No items may be equipped whatsoever. You must face the world with nothing.", IsItemForbidden = function(itemLink) if not itemLink then return false end local _, _, _, _, _, itemType, _, _, equipSlot = GetItemInfo(itemLink) if itemType == "Armor" or itemType == "Weapon" then return true end if equipSlot and equipSlot ~= "INVTYPE_NON_EQUIP" then return true end return false end }
    },

    EventHandler = function(self, event, ...)
        if event == "MERCHANT_UPDATE" then
            -- If a merchant window update happens and we were expecting a sale,
            -- we can confirm the sale was successful.
            if self.lastItemSaleAttempt then
                local itemLink = self.lastItemSaleAttempt
                local db = Purity:GetDB()
                
                -- Check if this unique item has been counted before.
                if not db.asceticChallengeData.soldItemHistory[itemLink] then
                    db.challengeStats = db.challengeStats or {}
                    db.challengeStats.forbiddenItemsSold = (db.challengeStats.forbiddenItemsSold or 0) + 1
                    
                    -- Add to history to prevent re-counting
                    db.asceticChallengeData.soldItemHistory[itemLink] = true
                    
                    if _G["PurityCharacterPanel"] and _G["PurityCharacterPanel"]:IsShown() then
                        _G["UpdateCharacterPurity"]()
                    end
                end
                
                -- Clear the attempt variable immediately after processing.
                self.lastItemSaleAttempt = nil
            end
        end
    end,
}

-- Define CanPlayerEquip before CheckSoldItem, as it is a dependency.
local function CanPlayerEquip(itemLink)
    if not itemLink then return false end

    local _, _, _, _, _, itemType, itemSubType = GetItemInfo(itemLink)
    local _, playerClassToken = UnitClass("player")
    local playerLevel = UnitLevel("player")

    -- FIX: Immediately filter out any item that is not equippable gear.
    if itemType ~= "Armor" and itemType ~= "Weapon" then
        return false
    end

    -- 1. Direct check for armor & shield proficiency
    if itemType == "Armor" then
        if (itemSubType == "Leather" and not (playerClassToken == "ROGUE" or playerClassToken == "DRUID" or playerClassToken == "HUNTER" or playerClassToken == "SHAMAN" or playerClassToken == "WARRIOR" or playerClassToken == "PALADIN")) or
           (itemSubType == "Mail" and not (playerClassToken == "WARRIOR" or playerClassToken == "PALADIN" or ((playerClassToken == "HUNTER" or playerClassToken == "SHAMAN") and playerLevel >= 40))) or
           (itemSubType == "Plate" and not ((playerClassToken == "WARRIOR" or playerClassToken == "PALADIN") and playerLevel >= 40)) or
           (itemSubType == "Shields" and not (playerClassToken == "WARRIOR" or playerClassToken == "SHAMAN" or playerClassToken == "PALADIN")) then
            return false
        end
    end

    -- 2. Fallback to our private tooltip scan for other restrictions.
    PurityCheckTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    PurityCheckTooltip:SetHyperlink(itemLink)

    local canEquip = true
    for i = 2, PurityCheckTooltip:NumLines() do
        local line = _G["PurityCheckTooltipTextLeft" .. i]
        if line and line:GetText() then
            local r, g, b = line:GetTextColor()
            if r > 0.9 and g < 0.2 and b < 0.2 then
                canEquip = false
                break
            end
        end
    end

    PurityCheckTooltip:Hide()
    return canEquip
end

-- This function now only flags a potential sale attempt. The EventHandler confirms it.
local function CheckSoldItem(bag, slot)
    if MerchantFrame and MerchantFrame:IsShown() then
        local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
        if itemInfo and itemInfo.hyperlink then
            if AsceticModule:IsItemForbidden(itemInfo.hyperlink) and CanPlayerEquip(itemInfo.hyperlink) then
                AsceticModule.lastItemSaleAttempt = itemInfo.hyperlink
            end
        end
    end
end

-- All module methods must be defined after the main table.
function AsceticModule:isWeaponAllowed(itemLink)
    local difficulty = self.selectedDifficultyId
    if not difficulty and Purity.tempSelectedSpec and Purity.tempSelectedSpec.id then
        difficulty = Purity.tempSelectedSpec.id
    end
    if difficulty == "HARD" then return false end
    return true
end

function AsceticModule:IsItemForbidden(itemLink)
    if not self.selectedDifficultyId then
        if Purity.tempSelectedSpec and Purity.tempSelectedSpec.id then
            self.selectedDifficultyId = Purity.tempSelectedSpec.id
        else
            self.selectedDifficultyId = "EASY"
        end
    end
    for _, spec in ipairs(self.specializations) do
        if spec.id == self.selectedDifficultyId then
            return spec.IsItemForbidden(itemLink)
        end
    end
    return self.specializations[3].IsItemForbidden(itemLink)
end

function AsceticModule:GetRulesText()
    local currentDifficultyId = self.selectedDifficultyId
    if Purity.optInFrame and Purity.optInFrame:IsShown() and Purity.tempSelectedSpec then
        currentDifficultyId = Purity.tempSelectedSpec.id
    end
    local selectedSpec = self.specializations[1]
    for _, spec in ipairs(self.specializations) do
        if spec.id == currentDifficultyId then
            selectedSpec = spec
            break
        end
    end
    local difficultyColor = DIFFICULTY_COLORS[selectedSpec.id] or "|cff261A0D"
    return {
        "|cffffd100Selected Path:|r", difficultyColor .. (selectedSpec.name or "None") .. "|r", " ",
        "|cffffd100Rule:|r", difficultyColor .. "• " .. (selectedSpec.description or "Select a difficulty to see its rules.") .. "|r", " ",
        "|cffffd100Challenge Conditions:|r", "|cff261A0D  • Must be started on a level 1 character of ANY class.|r",
        "|cff261A0D  • Must be accepted before leveling to 2.|r", "|cff261A0D  • An uptime of at least 96.0% must be maintained.|r",
    }
end

function AsceticModule:GetChallengeSpecifier()
    return self.selectedDifficultyId or nil
end

function AsceticModule:InitializeOnPlayerEnterWorld()
    local db = Purity:GetDB()
    if not db.asceticChallengeData then
        db.asceticChallengeData = {}
    end
    -- FIX: Initialize the unique item history table on login.
    db.asceticChallengeData.soldItemHistory = db.asceticChallengeData.soldItemHistory or {}
    self.selectedDifficultyId = db.asceticChallengeData.difficulty
    self.needsWeaponWarning = (self.selectedDifficultyId == "HARD")
	hooksecurefunc(C_Container, "UseContainerItem", CheckSoldItem)
end

function AsceticModule:SaveData()
    local db = Purity:GetDB()
    db.asceticChallengeData = db.asceticChallengeData or {}
    if Purity.tempSelectedSpec and Purity.tempSelectedSpec.id then
        db.asceticChallengeData.difficulty = Purity.tempSelectedSpec.id
        self.selectedDifficultyId = Purity.tempSelectedSpec.id
    end
    self.needsWeaponWarning = (db.asceticChallengeData.difficulty == "HARD")
end

Purity.GlobalModules = Purity.GlobalModules or {}
Purity.GlobalModules.ASCETIC = AsceticModule