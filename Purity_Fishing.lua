-- Purity AddOn - Fishing Module

if not Purity then
    return
end

local FishingModule = {
    challengeName = "Fisherman's Folly",
    description = "The devoted angler. You have forsaken all worldly possessions in pursuit of the perfect catch. Your only tools are your fishing pole, bait, and the treasures of the deep.",
    needsWeaponWarning = true,
    isGlobalChallenge = true,
    isExpectingLootFromContainer = false,
    hasPerformedInitialPurge = false,
	bankedItemNames = {},
	showAllowedTooltip = true,
}

local DIRECT_FISHED_EQUIPPABLES = {
    [6292] = true, [6294] = true, [6364] = true, [13882] = true,
    [13915] = true, [13905] = true, [8350] = true, [6360] = true,
}
local FISHABLE_CONTAINER_IDS = {
    [20708] = true, [21113] = true, [21150] = true, [21228] = true,
    [6351] = true, [6352] = true, [6357] = true, [13874] = true,
}
local VENDOR_PURCHASABLE_FISHING_POLES = {
    [6256] = true, [6365] = true, [6367] = true,
    [19970] = true, [6366] = true, [12225] = true,
}

--- Cleans an item name to ensure consistent lookups.
function FishingModule:SanitizeItemName(itemName)
    if not itemName then return nil end
    local trimmed = itemName:match("^%s*(.-)%s*$")
    if trimmed then
        return trimmed:gsub("[^%w%s']", "")
    end
    return nil
end

--- Checks if a spell is forbidden.
function FishingModule:IsSpellForbidden(spellId)
    return false
end

--- Checks directly against the database if an item is forbidden.
function FishingModule:IsItemForbidden(itemLink)
    if not itemLink then return nil end
    local db = Purity:GetDB()
    local itemName, _, _, _, _, itemType = GetItemInfo(itemLink)
    local itemID = itemLink and tonumber(string.match(itemLink, "item:(%d+)"))
    if not itemID then return nil end

    local cleanItemName = self:SanitizeItemName(itemName)
    
    if cleanItemName and db.fishingFishedItemLinks and db.fishingFishedItemLinks[cleanItemName] then 
        return false -- It's allowed.
    end
    
    if DIRECT_FISHED_EQUIPPABLES[itemID] then return false end
    if VENDOR_PURCHASABLE_FISHING_POLES[itemID] then return false end
    if itemType ~= "Armor" and itemType ~= "Weapon" then return nil end
    
    return true -- It's forbidden.
end

--- Checks if a weapon is allowed.
function FishingModule:isWeaponAllowed(itemLink)
    if not itemLink then return false end
    local db = Purity:GetDB()
    local itemName, _, _, _, _, _, itemSubType = GetItemInfo(itemLink)
    local itemID = tonumber(string.match(itemLink, "item:(%d+)"))
    local cleanItemName = self:SanitizeItemName(itemName)

    if cleanItemName and db.fishingFishedItemLinks and db.fishingFishedItemLinks[cleanItemName] then return true end
    if itemSubType == "Fishing Pole" then return true end
    if itemID and DIRECT_FISHED_EQUIPPABLES[itemID] then return true end

    return false
end

--- Returns the rules text for the UI.
function FishingModule:GetRulesText()
    return {
        "|cffffd100Key Prohibitions:|r",
        "|cff261A0D  • You may ONLY equip items that were fished (exceptions: Fishing Poles).|r",
        " ",
        "|cffffd100Challenge Conditions:|r",
        "|cff261A0D  • Must be started on a level 1 character of ANY class.|r",
        "|cff261A0D  • Must be accepted before leveling to 2.|r",
        "|cff261A0D  • An uptime of at least 96.0% must be maintained.|r",
    }
end

--- These functions now only update the data signature. The data itself is modified directly.
function FishingModule:SaveData()
    Purity:GetDB().dataSignature = Purity:CreateDataSignature(Purity:GetDB())
end
function FishingModule:SaveDataOnLogout()
    Purity:GetDB().dataSignature = Purity:CreateDataSignature(Purity:GetDB())
end

function FishingModule:EventHandler(event, ...)
    local currentDB = Purity:GetDB()
    if not currentDB.isOptedIn or currentDB.status == "Not Participating" then return end

    if event == "ITEM_LOCK_CHANGED" then
        local bagId, slotId = ...
        if type(bagId) == "number" and type(slotId) == "number" then
            local itemLink = C_Container.GetContainerItemLink(bagId, slotId)
            if itemLink then
                local itemID = tonumber(string.match(itemLink, "item:(%d+)"))
                if itemID and FISHABLE_CONTAINER_IDS[itemID] then
                    self.isExpectingLootFromContainer = true
                end
            end
        end
    elseif event == "LOOT_READY" then
        if self.isExpectingLootFromContainer then
            local numItems = GetNumLootItems()
            for i = 1, numItems do
                local itemLink = GetLootSlotLink(i)
                if itemLink then
                    local itemName, _, _, _, _, itemType = GetItemInfo(itemLink)
                    if itemName and (itemType == "Armor" or itemType == "Weapon") then
                        local cleanItemName = self:SanitizeItemName(itemName)
                        if cleanItemName then currentDB.fishingFishedItemLinks[cleanItemName] = true end
                    end
                end
            end
        end
    elseif event == "LOOT_CLOSED" then
        self.isExpectingLootFromContainer = false
    elseif event == "CHAT_MSG_LOOT" then
        local message = ...
        local itemLink = string.match(message, "You receive loot: (.+).")
        if not itemLink then return end
        local itemName, _, _, _, _, itemType = GetItemInfo(itemLink)
        local itemID = tonumber(string.match(itemLink, "item:(%d+)"))
        if not itemName or not itemID then return end

        -- Increment total catches for every valid item looted from fishing
        local db = Purity:GetDB()
        db.challengeStats = db.challengeStats or {}
        db.challengeStats.totalCatches = (db.challengeStats.totalCatches or 0) + 1

        if DIRECT_FISHED_EQUIPPABLES[itemID] then
            local cleanItemName = self:SanitizeItemName(itemName)
            if cleanItemName then currentDB.fishingFishedItemLinks[cleanItemName] = true end
        end
        
        -- Stat tracking for trunks
        if itemName and string.find(itemName, "Trunk") then
            db.challengeStats.trunksFished = (db.challengeStats.trunksFished or 0) + 1
        end

        if _G["PurityCharacterPanel"] and _G["PurityCharacterPanel"]:IsShown() then
            _G["UpdateCharacterPurity"]()
        end
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        Purity:CheckWeaponState()
        local inventorySlots = { INSLOT_HEAD, INSLOT_NECK, INSLOT_SHOULDER, INSLOT_CHEST, INSLOT_WAIST, INSLOT_LEGS, INSLOT_FEET, INSLOT_WRIST, INSLOT_HAND, INSLOT_FINGER1, INSLOT_FINGER2, INSLOT_TRINKET1, INSLOT_TRINKET2, INSLOT_BACK, INSLOT_MAINHAND, INSLOT_OFFHAND, INSLOT_RANGED, INSLOT_TABARD }
        for _, slotId in ipairs(inventorySlots) do
            local itemLink = GetInventoryItemLink("player", slotId)
            if itemLink and self:IsItemForbidden(itemLink) then
                local itemName = GetItemInfo(itemLink)
                Purity:Violation("Equipped a forbidden item: " .. (itemName or "Unknown Item"))
                return
            end
        end
    elseif event == "PLAYER_LOGOUT" then
        self:SaveData()
    end
end

function FishingModule:ScanAndPurgeAllowedList()
    local db = Purity:GetDB()
    local currentPossessedNames = {}
    local inventorySlots = {
        INVSLOT_HEAD, INVSLOT_NECK, INVSLOT_SHOULDER, INVSLOT_CHEST,
        INVSLOT_WAIST, INVSLOT_LEGS, INVSLOT_FEET, INVSLOT_WRIST,
        INVSLOT_HAND, INVSLOT_FINGER1, INVSLOT_FINGER2, INVSLOT_TRINKET1,
        INVSLOT_TRINKET2, INVSLOT_BACK, INVSLOT_MAINHAND, INVSLOT_OFFHAND,
        INVSLOT_RANGED, INVSLOT_TABARD
    }

    for _, slotId in ipairs(inventorySlots) do
        local link = GetInventoryItemLink("player", slotId)
        if link then 
            local name = self:SanitizeItemName(GetItemInfo(link))
            if name then currentPossessedNames[name] = true; end
        end
    end
    
    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
            if itemInfo and itemInfo.hyperlink then
                local name = self:SanitizeItemName(GetItemInfo(itemInfo.hyperlink))
                if name then currentPossessedNames[name] = true; end
            end
        end
    end

    for name, _ in pairs(self.bankedItemNames) do
        currentPossessedNames[name] = true
    end

    local allowedItems = db.fishingFishedItemLinks or {}
    local namesToPurge = {}
    for allowedName, _ in pairs(allowedItems) do
        if not currentPossessedNames[allowedName] then
            table.insert(namesToPurge, allowedName)
        end
    end

    if #namesToPurge > 0 then
        for _, nameToPurge in ipairs(namesToPurge) do
            db.fishingFishedItemLinks[nameToPurge] = nil
        end
        self:SaveData()
    end
end

function FishingModule:InitializeOnPlayerEnterWorld()
    local db = Purity:GetDB()
    if not db.fishingFishedItemLinks then
        db.fishingFishedItemLinks = {}
    end

    if not self.hasPerformedInitialPurge then
        local cleanFishedItems = {}
        for dirtyItemName, value in pairs(db.fishingFishedItemLinks) do
            local cleanName = self:SanitizeItemName(dirtyItemName)
            if cleanName then
                cleanFishedItems[cleanName] = value
            end
        end
        db.fishingFishedItemLinks = cleanFishedItems
        self.hasPerformedInitialPurge = true
        self:SaveData()
    end
    
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("BANKFRAME_OPENED")
    eventFrame:RegisterEvent("BANKFRAME_CLOSED")
    eventFrame:SetScript("OnEvent", function(_, event)
        if event == "BANKFRAME_OPENED" then
            self.bankedItemNames = {}
            for slot = 1, C_Bank.GetNumBankSlots() do
                local itemLink = C_Bank.GetBankSlotItemLink(slot)
                if itemLink then
                    local name = self:SanitizeItemName(GetItemInfo(itemLink))
                    if name then self.bankedItemNames[name] = true; end
                end
            end
        elseif event == "BANKFRAME_CLOSED" then
            self:ScanAndPurgeAllowedList()
        end
    end)
end

function FishingModule:SetExpectingLootFromContainer(itemLink)
    local wasExpectingLoot = self.isExpectingLootFromContainer
    local isNowExpectingLoot = false
    if itemLink then
        local itemID = tonumber(string.match(itemLink, "item:(%d+)"))
        if itemID and FISHABLE_CONTAINER_IDS[itemID] then
            isNowExpectingLoot = true
        end
    end
    if wasExpectingLoot ~= isNowExpectingLoot then
        self.isExpectingLootFromContainer = isNowExpectingLoot
    end
end
function FishingModule:ClearExpectingLootFromContainer()
    if self.isExpectingLootFromContainer then
        self.isExpectingLootFromContainer = false
    end
end

Purity.GlobalModules = Purity.GlobalModules or {}
Purity.GlobalModules.FISHING = FishingModule