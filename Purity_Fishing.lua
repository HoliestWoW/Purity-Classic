-- Purity AddOn - Fishing Module

local addonName, Purity = ...

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

local recentlyFished = false
local lastCatchTime = 0
local secureAllowedItems = {}

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
    
    local itemID, _, _, _, _, itemClassID, itemSubClassID = GetItemInfoInstant(itemLink)
    if not itemID then return nil end

    if itemClassID == 2 and itemSubClassID == 20 then return false end

    local itemName = GetItemInfo(itemLink)
    local cleanItemName = self:SanitizeItemName(itemName)
    
    if cleanItemName and secureAllowedItems[cleanItemName] then return false end
    if secureAllowedItems[itemID] then return false end
    
    if DIRECT_FISHED_EQUIPPABLES[itemID] then return false end
    if VENDOR_PURCHASABLE_FISHING_POLES[itemID] then return false end
    
    if itemClassID ~= 4 and itemClassID ~= 2 then return nil end
    
    return true
end

--- Checks if a weapon is allowed.
function FishingModule:isWeaponAllowed(itemLink)
    if not itemLink then return false end
    
    local itemID, _, _, _, _, itemClassID, itemSubClassID = GetItemInfoInstant(itemLink)

    if itemClassID == 2 and itemSubClassID == 20 then return true end

    local itemName = GetItemInfo(itemLink)
    local cleanItemName = self:SanitizeItemName(itemName)

    if cleanItemName and secureAllowedItems[cleanItemName] then return true end
    if itemID and secureAllowedItems[itemID] then return true end
    
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
    local db = Purity:GetDB()
    
    -- Copy our secure memory over to the global save file
    db.fishingFishedItemLinks = {}
    for name, value in pairs(secureAllowedItems) do
        db.fishingFishedItemLinks[name] = value
    end

    -- Hash and lock it
    db.dataSignature = Purity:CreateDataSignature(db)
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
        -- 1. Handle Fishing Loot
        if IsFishingLoot and IsFishingLoot() then
            local db = Purity:GetDB()
            db.challengeStats = db.challengeStats or {}
            
            local now = GetTime()
            if now - lastCatchTime > 1.5 then
                db.challengeStats.totalCatches = (db.challengeStats.totalCatches or 0) + 1
                lastCatchTime = now
            end
            
            local numItems = GetNumLootItems()
            for i = 1, numItems do
                local itemLink = GetLootSlotLink(i)
                if itemLink then
                    local itemID, _, _, _, _, itemClassID = GetItemInfoInstant(itemLink)
                    local itemName = GetItemInfo(itemLink)
                    
                    -- Track trunks
                    if itemName and string.find(itemName, "Trunk") then
                        db.challengeStats.trunksFished = (db.challengeStats.trunksFished or 0) + 1
                    end
                    
                    -- Add fished gear to the allowed items list (2 = Weapon, 4 = Armor)
                    if itemClassID == 2 or itemClassID == 4 then
                        -- Always save the itemID as a fallback for cache misses
                        if itemID then secureAllowedItems[itemID] = true end 
                        
                        if itemName then
                            local cleanItemName = self:SanitizeItemName(itemName)
                            if cleanItemName then secureAllowedItems[cleanItemName] = true end
                        end
                    end
                end
            end
            
            if _G["PurityCharacterPanel"] and _G["PurityCharacterPanel"]:IsShown() then
                if _G["UpdateCharacterPurity"] then
                    _G["UpdateCharacterPurity"]()
                end
            end
        end

        -- 2. Handle Container Loot (e.g., Opening Trunks)
        if self.isExpectingLootFromContainer then
            local numItems = GetNumLootItems()
            for i = 1, numItems do
                local itemLink = GetLootSlotLink(i)
                if itemLink then
                    local itemID, _, _, _, _, itemClassID = GetItemInfoInstant(itemLink)
                    local itemName = GetItemInfo(itemLink)
                    
                    if itemClassID == 2 or itemClassID == 4 then
                        if itemID then secureAllowedItems[itemID] = true end
                        
                        if itemName then
                            local cleanItemName = self:SanitizeItemName(itemName)
                            if cleanItemName then secureAllowedItems[cleanItemName] = true end
                        end
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
        
        local itemID = tonumber(string.match(itemLink, "item:(%d+)"))
        local itemName = GetItemInfo(itemLink)
        if not itemID then return end

        if DIRECT_FISHED_EQUIPPABLES[itemID] then
            secureAllowedItems[itemID] = true
            if itemName then
                local cleanItemName = self:SanitizeItemName(itemName)
                if cleanItemName then secureAllowedItems[cleanItemName] = true end
            end
        end
        
        -- Stat tracking for trunks
        if itemName and string.find(itemName, "Trunk") then
            local db = Purity:GetDB()
            db.challengeStats = db.challengeStats or {}
            db.challengeStats.trunksFished = (db.challengeStats.trunksFished or 0) + 1
        end

        if _G["PurityCharacterPanel"] and _G["PurityCharacterPanel"]:IsShown() then
            if _G["UpdateCharacterPurity"] then
                _G["UpdateCharacterPurity"]()
            end
        end
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        Purity:CheckWeaponState()
    elseif event == "PLAYER_LOGOUT" then
        self:SaveData()
    end
end

function FishingModule:ScanAndPurgeAllowedList()
    local currentPossessed = {}
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
            local itemID = tonumber(string.match(link, "item:(%d+)"))
            if itemID then currentPossessed[itemID] = true end
            
            local name = self:SanitizeItemName(GetItemInfo(link))
            if name then currentPossessed[name] = true end
        end
    end
    
    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
            if itemInfo and itemInfo.hyperlink then
                local itemID = tonumber(string.match(itemInfo.hyperlink, "item:(%d+)"))
                if itemID then currentPossessed[itemID] = true end
                
                local name = self:SanitizeItemName(GetItemInfo(itemInfo.hyperlink))
                if name then currentPossessed[name] = true end
            end
        end
    end

    for nameOrId, _ in pairs(self.bankedItemNames) do
        currentPossessed[nameOrId] = true
    end

    local itemsToPurge = {}
    for allowedItem, _ in pairs(secureAllowedItems) do
        if not currentPossessed[allowedItem] then
            table.insert(itemsToPurge, allowedItem)
        end
    end

    if #itemsToPurge > 0 then
        for _, itemToPurge in ipairs(itemsToPurge) do
            secureAllowedItems[itemToPurge] = nil
        end
        self:SaveData()
    end
end

function FishingModule:InitializeOnPlayerEnterWorld()
    local db = Purity:GetDB()
    if not db.fishingFishedItemLinks then
        db.fishingFishedItemLinks = {}
    end
	
	wipe(secureAllowedItems)
	
    -- Safely load numbers and strings
	for dirtyItemName, value in pairs(db.fishingFishedItemLinks) do
        if type(dirtyItemName) == "number" or tonumber(dirtyItemName) then
            local id = tonumber(dirtyItemName)
            secureAllowedItems[id] = value
        else
            local cleanName = self:SanitizeItemName(dirtyItemName)
            if cleanName then
                secureAllowedItems[cleanName] = value
            end
        end
    end

    if not self.hasPerformedInitialPurge then
        local cleanFishedItems = {}
        for dirtyItemName, value in pairs(db.fishingFishedItemLinks) do
            if type(dirtyItemName) == "number" or tonumber(dirtyItemName) then
                local id = tonumber(dirtyItemName)
                cleanFishedItems[id] = value
            else
                local cleanName = self:SanitizeItemName(dirtyItemName)
                if cleanName then
                    cleanFishedItems[cleanName] = value
                end
            end
        end
        db.fishingFishedItemLinks = cleanFishedItems
        self.hasPerformedInitialPurge = true
        self:SaveData()
    end
    
    local eventFrame = CreateFrame("Frame")

    local function fullBankScan(self)
        self.bankedItemNames = {}

        for slot = 1, 28 do
            local itemLink = C_Container.GetContainerItemLink(BANK_CONTAINER, slot)
            if itemLink then
                local itemID = tonumber(string.match(itemLink, "item:(%d+)"))
                if itemID then self.bankedItemNames[itemID] = true end

                local name = self:SanitizeItemName(GetItemInfo(itemLink))
                if name then self.bankedItemNames[name] = true end
            end
        end

        for bag = (NUM_BAG_SLOTS + 1), (NUM_BAG_SLOTS + GetNumBankSlots()) do
            for slot = 1, C_Container.GetContainerNumSlots(bag) do
                local itemLink = C_Container.GetContainerItemLink(bag, slot)
                if itemLink then
                    local itemID = tonumber(string.match(itemLink, "item:(%d+)"))
                    if itemID then self.bankedItemNames[itemID] = true end

                    local name = self:SanitizeItemName(GetItemInfo(itemLink))
                    if name then self.bankedItemNames[name] = true end
                end
            end
        end
    end

    eventFrame:SetScript("OnEvent", function(frame, event)
        if event == "BANKFRAME_OPENED" then
            frame:SetScript("OnUpdate", function(self_frame)
                fullBankScan(self) 
                self_frame:SetScript("OnUpdate", nil) 
            end)
        elseif event == "BANKFRAME_CLOSED" then
            self:ScanAndPurgeAllowedList()
        end
    end)

    eventFrame:RegisterEvent("BANKFRAME_OPENED")
    eventFrame:RegisterEvent("BANKFRAME_CLOSED")
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