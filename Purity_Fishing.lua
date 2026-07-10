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
	toastQueue = {},
    isToasting = false,
}

local recentlyFished = false
local lastCatchTime = 0
local secureAllowedItems = {}

local DIRECT_FISHED_EQUIPPABLES = {
    [6292] = true, [6294] = true, [6364] = true, [13882] = true,
    [13915] = true, [13905] = true, [8350] = true, [6360] = true,
	[19979] = true, [19972] = true, [19969] = true, [19022] = true,
	[6292] = true, [6294] = true, [6295] = true, [13901] = true,
	[6309] = true, [13902] = true, [6310] = true, [6311] = true,
	[13903] = true, [13904] = true, [6363] = true, [13905] = true,
	[6364] = true, [13885] = true, [13886] = true, [13882] = true,
	[13883] = true, [13884] = true, [13887] = true,
}
local FISHABLE_CONTAINER_IDS = {
    [20708] = true, [21113] = true, [21150] = true, [21228] = true,
    [6351] = true, [6352] = true, [6357] = true, [13874] = true,
}
local ACQUIRED_POLES_LIST = {
    [6256] = true,  -- Fishing Pole
    [6365] = true,  -- Strong Fishing Pole
    [12225] = true, -- Blump Family Fishing Pole
    [19022] = true, -- Nat Pagle's Extreme Angler FC-5000
    [19970] = true, -- Arcanite Fishing Pole
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
    if ACQUIRED_POLES_LIST[itemID] then return false end
    
    if itemClassID ~= 4 and itemClassID ~= 2 then return nil end
    
    return true
end

-- Helper function to provide zone and source context for the tooltip
function FishingModule:GetItemZoneText(itemID)
    local overrides = {
        -- Trunks
        [20708] = "Caught in Darkshore, Loch Modan, Silverpine Forest, The Barrens, Westfall",
        [21113] = "Caught in Ashenvale, Hillsbrad Foothills, Stonetalon Mountains, Wetlands",
        [21150] = "Caught in Alterac Mountains, Arathi Highlands, Desolace, Dustwallow Marsh, Stranglethorn Vale, The Barrens",
        [21228] = "Caught in Azshara, Feralas, Stranglethorn Vale, Tanaris",
        
        -- Crates
        [6351]  = "Caught in Darkshore, Silverpine Forest, The Barrens, Westfall",
        [6352]  = "Caught in Ashenvale, Hillsbrad Foothills, Wetlands",
        [6357]  = "Caught in Arathi Highlands, Desolace, Dustwallow Marsh, Stranglethorn Vale, Swamp of Sorrows",
        [13874] = "Caught in Azshara, Feralas, Tanaris, The Hinterlands",
        
        -- Specific Bags from Trunks
        [856]  = "Tightly Sealed Trunk.",
        [5573] = "Tightly Sealed Trunk.",
        [2657] = "Tightly Sealed Trunk.",
        [5574] = "Tightly Sealed Trunk.",
        [804]  = "Watertight Trunk.",
        [5576] = "Watertight Trunk.",
        [5575] = "Watertight Trunk.",
        [857]  = "Watertight Trunk.",
        [1725] = "Iron Bound Trunk.",
        [3914] = "Mithril Bound Trunk.",
        [1685] = "Mithril Bound Trunk.",

        -- Rumsey Rum
        [20709] = "Caught in Darkshore, Silverpine Forest, The Barrens, Westfall",
        [21114] = "Caught in Ashenvale, Hillsbrad Foothills, Stonetalon Mountains, Wetlands",
        [21151] = "Caught in Alterac Mountains, Azshara, Arathi Highlands, Desolace, Dustwallow Marsh, Feralas, Stranglethorn Vale, Tanaris, The Barrens",
        
        -- Fishing Poles
        [19970] = "STV Fishing Tournament Reward",
        [19022] = "Horde only quest reward from Snapjaws, Mon! in The Hinterlands",
        [6367]  = "Rare loot from Shellfish Traps in Desolace",
        [6366]  = "Rare fishing catch in 10-20 zones",
        [6365]  = "Sold by Fishing Suppliers",
        [12225] = "Alliance only quest reward from The Family and the Fishing Pole in Darkshore",
        [6256]  = "Sold by Fishing Suppliers",
        
        -- STV Tournament Gear & Rewards
        [19971] = "Reward from completing the quest Rare Fish - Dezian Queenfish during STV Fishing Tournament",
        [19972] = "Reward from completing the quest Rare Fish - Keefer's Angelfish during STV Fishing Tournament",
        [19969] = "Reward from completing the quest Rare Fish - Brownell's Blue Striped Racer during STV Fishing Tournament",
        [19979] = "Reward from completing the quest Master Angler during the STV Fishing Tournament",
        
        -- Existing unique overrides
        [13898] = "Orgrimmar", -- Old Crafty
        [13883] = "Ironforge", -- Old Ironjaw
		
		[6360] = "Extremely rare catch in Ashenvale, Hillsbrad Foothills, Wetlands",
		[8350] = "Extremely rare catch in Westfall, Darkshore, The Barrens, Darnassus, Stormwind, Thunder Bluff, Orgrimmar, Silverpine, Undercity",
		[6301] = "Caught in Tirisfal and Undercity",
		[19808] = "Caught in School of Tastyfish pools during STV Fishing Tournament",
		
		-- Fish
		[6292] = "Fished in Dun Morogh, Elwynn Forest, Mulgore, Tirisfal Glades, Durotar, Teldrassil, Duskwood, Westfall",
		[6294] = "Fished in Dun Morogh, Elwynn Forest, Mulgore, Tirisfal Glades, Durotar, Teldrassil, Duskwood, Westfall",
		[6295] = "Fished in Dun Morogh, Elwynn Forest, Mulgore, Tirisfal Glades, Durotar, Teldrassil, Duskwood, Westfall",
		[6309] = "Fished in most zones and cities",
		[6310] = "Fished in most zones and cities",
		[6311] = "Fished in most zones and cities",
		[6363] = "Fished in most zones and cities",
		[6364] = "Fished in most zones and cities",
		[13907] = "Fished in Azshara or Eastern Plaguelands",
		[13908] = "Fished in Azshara or Eastern Plaguelands",
		[13909] = "Fished in Azshara or Eastern Plaguelands",
		[13910] = "Fished in Azshara or Eastern Plaguelands",
		[13911] = "Fished in Azshara or Eastern Plaguelands",
		[13912] = "Fished in Azshara or Eastern Plaguelands",
		[13913] = "Fished in Azshara or Eastern Plaguelands",
		[13876] = "Fished in Tanaris, The Hinterlands, Azshara, Feralas, Stranglethorn Vale",
		[13877] = "Fished in Tanaris, The Hinterlands, Azshara, Feralas, Stranglethorn Vale",
		[13878] = "Fished in Tanaris, The Hinterlands, Azshara, Feralas, Stranglethorn Vale",
		[13879] = "Fished in Tanaris, The Hinterlands, Azshara, Feralas, Stranglethorn Vale",
		[13880] = "Fished in Tanaris, The Hinterlands, Azshara, Feralas, Stranglethorn Vale",
		[13885] = "Fished in Moonglade, Desolace, The Hinterlands, Felwood, Azshara, Un'Goro Crater, Western Plaguelands, Eastern Plaguelands, Feralas",
		[13886] = "Fished in Moonglade, Desolace, The Hinterlands, Felwood, Azshara, Un'Goro Crater, Western Plaguelands, Eastern Plaguelands, Feralas",
		[13882] = "Fished in Moonglade, Desolace, The Hinterlands, Felwood, Azshara, Un'Goro Crater, Western Plaguelands, Eastern Plaguelands, Feralas",
		[13883] = "Fished in Moonglade, Desolace, The Hinterlands, Felwood, Azshara, Un'Goro Crater, Western Plaguelands, Eastern Plaguelands, Feralas",
		[13884] = "Fished in Moonglade, Desolace, The Hinterlands, Felwood, Azshara, Un'Goro Crater, Western Plaguelands, Eastern Plaguelands, Feralas",
		[13887] = "Fished in Moonglade, Desolace, The Hinterlands, Felwood, Azshara, Un'Goro Crater, Western Plaguelands, Eastern Plaguelands, Feralas",
		[13901] = "Fished in Deadwind Pass, Eastern Plaguelands, Alterac Valley, Winterspring, Duskwood, Feralas",
		[13902] = "Fished in Deadwind Pass, Eastern Plaguelands, Alterac Valley, Winterspring, Duskwood, Feralas",
		[13903] = "Fished in Deadwind Pass, Eastern Plaguelands, Alterac Valley, Winterspring, Duskwood, Feralas",
		[13904] = "Fished in Deadwind Pass, Eastern Plaguelands, Alterac Valley, Winterspring, Duskwood, Feralas",
		[13905] = "Fished in Deadwind Pass, Eastern Plaguelands, Alterac Valley, Winterspring, Duskwood, Feralas",
		[13906] = "Fished in Deadwind Pass, Eastern Plaguelands, Alterac Valley, Winterspring, Duskwood, Feralas",
		[13914] = "Fished in Azshara",
		[13915] = "Fished in Azshara",
		[13916] = "Fished in Azshara",
		[13917] = "Fished in Azshara",
		[19803] = "Caught in School of Tastyfish pools during STV Fishing Tournament",
		[19806] = "Caught in School of Tastyfish pools during STV Fishing Tournament",
		[19805] = "Caught in School of Tastyfish pools during STV Fishing Tournament",
		[12238] = "Caught in Darkshore",
		[6522] = "Caught in The Barrens",
		[16967] = "Caught in Feralas",
		[16970] = "Caught in Swamp of Sorrows",
		[6458] = "Caught in Stonetalon Mountains or The Barrens in oil slicks",
		[13754] = "Caught in Tanaris, The Hinterlands, Azshara, Feralas, STV",
		[21153] = "Caught in Alterac Mountains or STV",
		[6317] = "Caught in Loch Modan",
		[21071] = "Caught in Hillsbrad Foothills, Loch Modan, Stonetalon Mountains, Ashenvale, Silverpine Forest",
		[13422] = "Caught in Tanaris, Azshara, Eastern Plaguelands, Feralas, STV, and The Hinterlands",
		[13755] = "Caught in Azshara, Tanaris, The Hinterlands,  Feralas, and STV",
    }
    if overrides[itemID] then return overrides[itemID] end
    
    -- Ordered categorical checks. Trunks/Crates are checked FIRST 
    -- so generic mats properly display their container source.
    local catMap = {
        [7] = "Tightly Sealed Trunk.",
        [8] = "Watertight Trunk.",
        [9] = "Iron Bound Trunk.",
        [10] = "Mithril Bound Trunk.",
        [11] = "Dented Crate.",
        [12] = "Waterlogged Crate.",
        [13] = "Sealed Crate.",
        [14] = "Heavy Crate.",
        [5] = "Can be opened to yield valuable gems or raw materials.",
    }
    
    for catIndex, text in pairs(catMap) do
        for _, id in ipairs(self.FishLogCategories[catIndex].items) do
            if id == itemID then return text end
        end
    end
    
    return "Random world catch near appropriately leveled zones."
end

function FishingModule:IsItemFound(itemID)
    local db = Purity:GetDB()
    if db.fishingLifetimeLog and db.fishingLifetimeLog[itemID] then 
        return true 
    end
    
    if secureAllowedItems[itemID] then return true end
    
    local itemName = GetItemInfo(itemID)
    local cleanItemName = self:SanitizeItemName(itemName)
    if cleanItemName then 
        if db.fishingLifetimeLog and db.fishingLifetimeLog[cleanItemName] then return true end
        if secureAllowedItems[cleanItemName] then return true end 
    end
    
    return false
end

FishingModule.FishLogCategories = {
    {
        name = "Fishing Poles",
        items = { 6256, 6365, 6366, 6367, 12225, 19022, 19970 }
    },
    {
        name = "Bags & Containers",
        items = { 804, 805, 828, 856, 857, 1685, 1725, 2657, 3914, 4500, 5571, 5572, 5573, 5574, 5575, 5576, 6351, 6352, 6357, 13874, 20708, 21113, 21150, 21228 }
    },
    {
        name = "Raw Fish",
        items = { 1467, 4603, 6289, 6291, 6299, 6303, 6308, 6317, 6361, 6362, 6458, 6522, 8365, 12238, 13422, 13754, 13755, 13756, 13757, 13758, 13759, 13760, 13876, 13877, 13878, 13879, 13880, 13888, 13889, 13890, 13893, 13907, 13908, 13909, 13910, 13911, 13912, 13913, 16968, 16969, 16970, 19803, 19805, 19806, 19807, 19975, 21071, 21153 }
    },
    {
        name = "Alchemical Fish",
        items = { 6358, 6359, 8365 }
    },
    {
        name = "Bloated Fish",
        items = { 6643, 6645, 6647, 8366, 13881, 13891 }
    },
    {
        name = "Fun Items & Oddities",
        items = { 3820, 6292, 6294, 6295, 6301, 6309, 6310, 6311, 6360, 6363, 6364, 8350, 13882, 13883, 13884, 13885, 13886, 13887, 13901, 13902, 13903, 13904, 13905, 13906, 13914, 13915, 13916, 13917, 19808, 19969, 19971, 19972, 19979, 20709, 21114, 21151, 16967 }
    },
    {
        name = "Tightly Sealed Trunk Loot",
        items = { 2996, 2318, 2319, 2997, 858, 2455, 856, 6546, 5573, 5574, 2078, 5207, 4689, 818, 15268, 6539, 2987, 6541, 2657, 4564, 2970, 6537, 14166, 2140, 3036, 4701, 9752, 4690, 9745, 9742, 9746, 3643, 4577, 2632, 3196, 5069, 15248, 3040, 2986, 4567, 6563, 6540, 9751, 9744, 2979, 9779, 14168, 8180, 4575, 6271, 2075, 6585, 2983, 6548, 4571, 6555, 6552, 5212, 2974, 2408, 9788, 9784, 9783, 4561, 9747, 4677, 6558, 6557, 6554, 6553, 3184, 2973, 4293, 6269, 3609, 15210, 4408, 6545, 6550, 9755, 6521, 4684, 9777, 3195, 14174, 2961, 9763, 7288, 2407, 9786, 2555, 4409, 6378, 2984, 2969, 6542, 9754, 3207, 6510, 9780, 15222, 4570, 14167, 6267, 6347, 2988, 9787, 9790, 3645, 3192, 6547, 2978, 4678, 9775, 6559, 14173, 6266, 2073, 6342, 2406, 4292, 4346, 2982, 5071, 6551, 6560, 4566, 6538, 1210, 1206 }
    },
    {
        name = "Watertight Trunk Loot",
        items = { 2997, 2319, 4305, 929, 3385, 5576, 804, 5575, 4698, 3206, 3066, 6399, 3039, 857, 10407, 3201, 3199, 3210, 15212, 3193, 6562, 14170, 3058, 15249, 3740, 15269, 6581, 6586, 4536, 3067, 6580, 15242, 9796, 3049, 4707, 9827, 9829, 2819, 6577, 7415, 7356, 6398, 9795, 6454, 6394, 4713, 4714, 9802, 9803, 10405, 6588, 9781, 4661, 9811, 15259, 9792, 15223, 3212, 4576, 2077, 15230, 6587, 6568, 9809, 3647, 6574, 2072, 4049, 8184, 9794, 3048, 8183, 6613, 6583, 9808, 4694, 6579, 6566, 9837, 6595, 15224, 14172, 2991, 11993, 6578, 6601, 6602, 6604, 9821, 6383, 3055, 4709, 3056, 790, 11038, 9814, 9812, 9815, 4568, 4296, 6612, 6716, 4412, 6584, 6565, 12047, 789, 9807, 4700, 3198, 2989, 3057, 3202, 4072, 3045, 3047, 3870, 4037, 4234, 1705, 1206, 1529 }
    },
    {
        name = "Iron Bound Trunk Loot",
        items = { 4305, 4339, 1725, 2080, 1207, 15225, 865, 3041, 864, 15286, 15214, 3197, 3042, 15250, 15234, 15233, 5213, 15261, 1465, 15285, 1990, 7367, 11997, 15213, 9834, 7447, 15260, 3037, 15243, 7409, 4054, 15322, 5214, 9856, 9863, 7368, 6396, 4048, 15226, 15232, 9835, 9875, 7436, 7437, 7609, 8188, 9886, 6406, 10288, 7433, 3185, 4042, 9839, 9846, 7357, 863, 6420, 4732, 4731, 7413, 6409, 4722, 6403, 4040, 6407, 7416, 3872, 9833, 4416, 9880, 9876, 15231, 7438, 7432, 7435, 11971, 9857, 9858, 10409, 9848, 9849, 9845, 9820, 9825, 9824, 7355, 7370, 4073, 12029, 7407, 7410, 7455, 6404, 4719, 7086, 7453, 7476, 9864, 9870, 7446, 11986, 7431, 4044, 7330, 7408, 6410, 4718, 7434, 4234, 4304, 1710, 3827, 3864, 1529, 1705 }
    },
    {
        name = "Mithril Bound Trunk Loot",
        items = { 4339, 8170, 14048, 6149, 5215, 1625, 1639, 8199, 866, 15215, 15270, 8029, 15262, 1640, 15323, 15244, 15263, 5216, 1685, 4088, 3187, 15235, 1994, 7470, 1608, 3430, 4087, 15245, 15287, 15227, 8194, 6430, 1613, 15252, 9937, 7539, 8248, 7989, 7469, 4089, 9938, 9939, 9940, 7531, 3208, 8196, 9970, 4058, 7523, 4063, 12031, 12012, 6428, 4736, 8389, 10315, 9909, 9908, 9925, 9936, 9942, 9930, 7535, 7527, 7532, 9947, 9955, 8139, 7552, 11204, 11202, 7524, 7521, 15251, 8108, 8111, 8112, 9894, 4738, 4062, 4047, 4045, 7993, 7481, 7478, 7477, 9295, 7475, 10071, 9907, 9910, 9915, 9911, 8259, 9881, 8281, 8273, 12024, 9945, 7533, 7544, 9949, 10059, 7519, 10090, 11973, 8124, 6433, 12042, 8390, 10131, 9924, 4304, 3928, 3914, 7909, 7910, 3864, 7990, 9298 }
    },
    {
        name = "Dented Crate Loot",
        items = { 4359, 4361, 4363, 4364 }
    },
    {
        name = "Waterlogged Crate Loot",
        items = { 4363, 4364, 4371, 4377, 4382 }
    },
    {
        name = "Sealed Crate Loot",
        items = { 4377, 4382, 4387, 4389 }
    },
    {
        name = "Heavy Crate Loot",
        items = { 7974, 9060, 9061, 10505, 10561 }
    }
}

function FishingModule:CreateFishLogUI()
    -- Main Frame
    local logFrame = CreateFrame("Frame", "PurityFishLogFrame", UIParent)
	tinsert(UISpecialFrames, "PurityFishLogFrame")
    logFrame:SetSize(750, 600)
    logFrame:SetPoint("CENTER")
    
    Purity:ApplyCustomArt(logFrame)
    
    logFrame:EnableMouse(true)
    logFrame:SetMovable(true)
    logFrame:RegisterForDrag("LeftButton")
    logFrame:SetScript("OnDragStart", logFrame.StartMoving)
    logFrame:SetScript("OnDragStop", logFrame.StopMovingOrSizing)
    logFrame:Hide()

    local topTitle = logFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    topTitle:SetPoint("TOP", 0, -30)
    topTitle:SetText("Fisherman's Log")
    topTitle:SetTextColor(1, 0.82, 0)

    -- Left Pane: Category Menu Scroll Frame
    -- Size narrowed to 190 to allow the outer scrollbar room to breathe
    local leftScrollFrame = CreateFrame("ScrollFrame", "PurityFishLogCategoryScroll", logFrame, "UIPanelScrollFrameTemplate")
    leftScrollFrame:SetSize(190, 400) 
    leftScrollFrame:SetPoint("TOPLEFT", 70, -88)

    local leftPane = CreateFrame("Frame")
    leftPane:SetWidth(190)
    leftScrollFrame:SetScrollChild(leftPane)

    -- Vertical Separator Texture (Hard-anchored to the logFrame to avoid scrollbar overlap)
    local separator = logFrame:CreateTexture(nil, "ARTWORK")
    separator:SetSize(20, 430)
    separator:SetPoint("TOPLEFT", logFrame, "TOPLEFT", 290, -87)
    separator:SetTexture("Interface\\AddOns\\Purity\\Media\\VerticalSeparator.tga")

    local rightPaneContainer = CreateFrame("Frame", nil, logFrame)
    rightPaneContainer:SetSize(350, 400)
    rightPaneContainer:SetPoint("TOPLEFT", separator, "TOPRIGHT", 15, -5)

    local defaultText = logFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    defaultText:SetPoint("CENTER", rightPaneContainer, "CENTER", 0, 0)
    defaultText:SetText("Pick a category from the left\nto see the items from that source.")
    defaultText:SetTextColor(1, 0.82, 0)
    defaultText:SetJustifyH("CENTER")

    local scrollFrame = CreateFrame("ScrollFrame", "PurityFishLogScrollFrame", rightPaneContainer, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT")
    scrollFrame:SetPoint("TOPRIGHT", -30, 0)
    scrollFrame:SetPoint("BOTTOM", rightPaneContainer, "BOTTOM", 0, 0)
    scrollFrame:Hide()

    local scrollChild = CreateFrame("Frame")
    scrollChild:SetWidth(rightPaneContainer:GetWidth() - 20)
    scrollFrame:SetScrollChild(scrollChild)
    
    local itemRows = {}

    local function SelectCategory(categoryIndex, isRefresh, targetItemID)
        FishingModule.currentCategoryIndex = categoryIndex
        defaultText:Hide()
        scrollFrame:Show()
		
		if FishingModule.categoryButtons then
            for i, btn in ipairs(FishingModule.categoryButtons) do
                if i == categoryIndex then
                    btn:LockHighlight()
                else
                    btn:UnlockHighlight()
                end
            end
        end
        
        local category = FishingModule.FishLogCategories[categoryIndex]
        local displayItems = {}
        
        for _, itemID in ipairs(category.items) do
            local itemName, link, itemRarity, _, _, _, _, _, _, itemIcon = GetItemInfo(itemID)
            if not itemName then
                itemName = "Retrieving Data... ("..itemID..")"
                itemIcon = GetItemIcon(itemID) 
                itemRarity = 1
            end
            
            table.insert(displayItems, {
                id = itemID,
                name = itemName,
                link = link,
                icon = itemIcon,
                rarity = itemRarity,
                found = FishingModule:IsItemFound(itemID)
            })
        end
        
        table.sort(displayItems, function(a, b)
            if a.found ~= b.found then return a.found end
            local function GetSortComponents(str)
                local numStr, baseStr = string.match(str, "^(%d+)%s*(.*)")
                if numStr and numStr ~= "" then
                    if baseStr == "" then baseStr = str end
                    return tonumber(numStr), baseStr
                end
                return -1, str 
            end
            local numA, baseA = GetSortComponents(a.name)
            local numB, baseB = GetSortComponents(b.name)
            local lowerA = string.lower(baseA)
            local lowerB = string.lower(baseB)
            
            if lowerA ~= lowerB then return lowerA < lowerB end
            return numA < numB
        end)
        
        for _, row in ipairs(itemRows) do row:Hide() end
        
        local yOffset = -5
        local targetRowIndex = nil
        
        for i, item in ipairs(displayItems) do
            -- Tag the row if it matches our clicked toast
            if item.id == targetItemID then targetRowIndex = i end
            
            local row = itemRows[i]
            if not row then
                row = CreateFrame("Frame", nil, scrollChild)
                row:SetSize(330, 40)
                row:EnableMouse(true)
                
                row.highlight = row:CreateTexture(nil, "BACKGROUND")
                row.highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
                row.highlight:SetAllPoints(row)
                row.highlight:SetBlendMode("ADD")
                row.highlight:Hide()
                
                row.icon = row:CreateTexture(nil, "ARTWORK")
                row.icon:SetSize(36, 36)
                row.icon:SetPoint("LEFT", row, "LEFT", 0, 0)
                
                row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                row.name:SetPoint("LEFT", row.icon, "RIGHT", 15, 0)
                row.name:SetJustifyH("LEFT")
                
                table.insert(itemRows, row)
            end
            
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 5, yOffset)
            
            row.icon:SetTexture(item.icon)
            row.name:SetText(item.name)
            
            if item.found then
                row.icon:SetDesaturated(false)
                local r, g, b = GetItemQualityColor(item.rarity or 1)
                row.name:SetTextColor(r, g, b)
                row.highlight:SetVertexColor(1, 0.82, 0, 0.4)
            else
                row.icon:SetDesaturated(true)
                row.name:SetTextColor(0.5, 0.5, 0.5) 
                row.highlight:SetVertexColor(0.8, 0.2, 0.2, 0.4)
            end
            
            row:SetScript("OnEnter", function(self)
                self.highlight:Show() 
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink("item:" .. item.id)
                local zoneText = FishingModule:GetItemZoneText(item.id)
                if zoneText then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine("Source: " .. zoneText, 1, 0.82, 0)
                end
                GameTooltip:Show()
            end)
            
            row:SetScript("OnLeave", function(self) 
                self.highlight:Hide() 
                GameTooltip:Hide() 
            end)
            
            row:SetScript("OnMouseDown", function(self, button)
                if IsModifiedClick("CHATLINK") then
                    local _, liveLink = GetItemInfo(item.id)
                    if liveLink and ChatEdit_GetActiveWindow() then
                        ChatEdit_InsertLink(liveLink)
                    end
                end
            end)
            
            row:Show()
            yOffset = yOffset - 45
        end
        scrollChild:SetHeight(math.abs(yOffset) + 10)

        -- AUTO-SCROLL LOGIC
        if targetRowIndex then
            -- We must wait 1 frame for the scrollChild height to physically update in WoW's UI engine
            C_Timer.After(0.01, function()
                local maxScroll = scrollFrame:GetVerticalScrollRange()
                local scrollHeight = (targetRowIndex - 1) * 45
                if scrollHeight > maxScroll then scrollHeight = maxScroll end
                
                scrollFrame:SetVerticalScroll(scrollHeight)
                
                -- Flash the highlight so the user sees exactly which item triggered the toast
                local targetRow = itemRows[targetRowIndex]
                if targetRow and targetRow.highlight then
                    targetRow.highlight:Show()
                    C_Timer.After(1.5, function()
                        if not targetRow:IsMouseOver() then
                            targetRow.highlight:Hide()
                        end
                    end)
                end
            end)
        elseif not isRefresh then
            scrollFrame:SetVerticalScroll(0)
        end
    end

    -- ITEM CACHE EVENT LISTENER (Auto-refreshes the list when missing data arrives)
    logFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    logFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "GET_ITEM_INFO_RECEIVED" then
            if self:IsShown() and FishingModule.currentCategoryIndex then
                -- Throttle the update using a 0.15s timer so the UI doesn't lag
                -- when the server sends 50 items back on the exact same frame.
                if not self.isUpdating then
                    self.isUpdating = true
                    C_Timer.After(0.15, function()
                        if FishingModule.currentCategoryIndex then
                            SelectCategory(FishingModule.currentCategoryIndex, true)
                        end
                        self.isUpdating = false
                    end)
                end
            end
        end
    end)

    -- Populate Left Pane Buttons & Dynamically Set Height
	FishingModule.categoryButtons = {}
    local btnYOffset = -10
    for i, category in ipairs(FishingModule.FishLogCategories) do
        local btn = CreateFrame("Button", nil, leftPane, "UIPanelButtonTemplate")
        btn:SetSize(170, 35) 
        btn:SetPoint("TOP", leftPane, "TOP", 0, btnYOffset)
        btn:SetText(category.name)
		
		table.insert(FishingModule.categoryButtons, btn)
        
        btn:SetScript("OnClick", function() SelectCategory(i, false) end)
        btnYOffset = btnYOffset - 40
    end
    
    leftPane:SetHeight(math.abs(btnYOffset) + 10)
    
    local closeButton = CreateFrame("Button", nil, logFrame, "UIPanelButtonTemplate")
    closeButton:SetSize(120, 30)
    closeButton:SetPoint("BOTTOM", logFrame, "BOTTOM", 0, 25)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function() logFrame:Hide() end)
	
	FishingModule.SelectCategory = function(self, categoryIndex, isRefresh, targetItemID)
        SelectCategory(categoryIndex, isRefresh, targetItemID)
    end
    
    self.FishLogFrame = logFrame
end

-- Call this during your Addon's initialization phase
function FishingModule:ToggleFishLog()
    if not self.FishLogFrame then
        self:CreateFishLogUI()
    end
    
    if self.FishLogFrame:IsShown() then
        self.FishLogFrame:Hide()
    else
        self.FishLogFrame:Show()
    end
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
                    
                    if itemName and string.find(itemName, "Trunk") and (currentLootGUID ~= lastLootGUID) then
						db.challengeStats.trunksFished = (db.challengeStats.trunksFished or 0) + 1
						lastLootGUID = currentLootGUID
					end
                    
                    if itemID then
                        db.fishingLifetimeLog = db.fishingLifetimeLog or {}
                        if not db.fishingLifetimeLog[itemID] then
                            db.fishingLifetimeLog[itemID] = true
                            self:ShowDiscoveryToast(itemID)
                        end
                    end
                    
                    if itemClassID == 2 or itemClassID == 4 then
                        if itemID then secureAllowedItems[itemID] = true end 
                        if itemName then
                            local cleanItemName = self:SanitizeItemName(itemName)
                            if cleanItemName then secureAllowedItems[cleanItemName] = true end
                        end
                    end
                end
            end
            
            if _G["PurityCharacterPanel"] and _G["PurityCharacterPanel"]:IsShown() then
                if _G["UpdateCharacterPurity"] then _G["UpdateCharacterPurity"]() end
            end
        end

        -- 2. Handle Container Loot (Opening Trunks)
        if self.isExpectingLootFromContainer then
            local db = Purity:GetDB()
            local numItems = GetNumLootItems()
            for i = 1, numItems do
                local itemLink = GetLootSlotLink(i)
                if itemLink then
                    local itemID, _, _, _, _, itemClassID = GetItemInfoInstant(itemLink)
                    local itemName = GetItemInfo(itemLink)
                    
                    if itemID then
                        db.fishingLifetimeLog = db.fishingLifetimeLog or {}
                        if not db.fishingLifetimeLog[itemID] then
                            db.fishingLifetimeLog[itemID] = true
                            self:ShowDiscoveryToast(itemID)
                        end
                    end
                    
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

    elseif event == "CHAT_MSG_LOOT" then
        local message = ...
        local itemLink = string.match(message, "You receive loot: (.+).")
        if not itemLink then return end
        
        local itemID = tonumber(string.match(itemLink, "item:(%d+)"))
        local itemName = GetItemInfo(itemLink)
        if not itemID then return end
        
        local db = Purity:GetDB()
        
        local now = GetTime()
        local isFromFishing = (now - lastCatchTime < 3) or self.isExpectingLootFromContainer
        
        if isFromFishing then
            db.fishingLifetimeLog = db.fishingLifetimeLog or {}
            if not db.fishingLifetimeLog[itemID] then
                db.fishingLifetimeLog[itemID] = true
                self:ShowDiscoveryToast(itemID)
            end
        end

        if DIRECT_FISHED_EQUIPPABLES[itemID] then
            secureAllowedItems[itemID] = true
            if itemName then
                local cleanItemName = self:SanitizeItemName(itemName)
                if cleanItemName then secureAllowedItems[cleanItemName] = true end
            end
        end
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        Purity:CheckWeaponState()
    elseif event == "PLAYER_LOGOUT" then
        self:SaveData()
	elseif event == "MERCHANT_SHOW" then
		self.checkInventoryOnClose = true
	elseif event == "MERCHANT_CLOSED" then
		if self.checkInventoryOnClose then
			self.checkInventoryOnClose = false
			local db = Purity:GetDB()
			for i = 1, 100 do
			end
		end
    end
end

function FishingModule:PlayNextToast()
    if #self.toastQueue == 0 then
        self.isToasting = false
        return
    end
    
    self.isToasting = true
    local itemID = table.remove(self.toastQueue, 1)
    
    local itemName, _, itemRarity, _, _, _, _, _, _, itemIcon = GetItemInfo(itemID)
    if not itemName then
        itemName = "Unknown Discovery"
        itemIcon = GetItemIcon(itemID) or 136116
        itemRarity = 1
    end

    if not self.toastFrame then
        -- 1. CHANGED TO A "Button" SO WE CAN CLICK IT
        local f = CreateFrame("Button", "PurityFishDiscoveryToast", UIParent)
        f:SetSize(320, 92)
        f:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 150)
        f:SetFrameStrata("DIALOG")
        f:Hide()

        local bg = f:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Alert-Background")
        bg:SetTexCoord(0, 0.605, 0, 0.703)

        local iconFrame = CreateFrame("Frame", nil, f)
        iconFrame:SetSize(40, 40)
        iconFrame:SetPoint("LEFT", f, "LEFT", 15, 0)

        local icon = iconFrame:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        f.icon = icon

        local iconOverlay = iconFrame:CreateTexture(nil, "OVERLAY")
        iconOverlay:SetTexture("Interface\\AchievementFrame\\UI-Achievement-IconFrame")
        iconOverlay:SetTexCoord(0, 0.5625, 0, 0.5625)
        iconOverlay:SetSize(72, 72)
        iconOverlay:SetPoint("CENTER", iconFrame, "CENTER", -1, 2)

        local unlocked = f:CreateFontString(nil, "OVERLAY", "GameFontBlackTiny")
        unlocked:SetPoint("TOP", f, "TOP", 7, -26)
        unlocked:SetText("New Catch Discovered!")

        local name = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        name:SetPoint("CENTER", f, "CENTER", 10, -5)
        name:SetJustifyH("CENTER")
        f.name = name

        f.anim = f:CreateAnimationGroup()
        local fadein = f.anim:CreateAnimation("Alpha")
        fadein:SetFromAlpha(0); fadein:SetToAlpha(1); fadein:SetDuration(0.5); fadein:SetOrder(1)

        local hold = f.anim:CreateAnimation("Alpha")
        hold:SetFromAlpha(1); hold:SetToAlpha(1); hold:SetDuration(3.5); hold:SetOrder(2)

        local fadeout = f.anim:CreateAnimation("Alpha")
        fadeout:SetFromAlpha(1); fadeout:SetToAlpha(0); fadeout:SetDuration(0.5); fadeout:SetOrder(3)

        f.anim:SetScript("OnFinished", function() 
            f:Hide()
            FishingModule:PlayNextToast() 
        end)
        
        -- 2. NEW CLICK NAVIGATION LOGIC
        f:SetScript("OnClick", function(self)
            if not self.itemID then return end
            
            -- Find the category index containing this item
            local foundCategoryIndex = nil
            for catIdx, category in ipairs(FishingModule.FishLogCategories) do
                for _, id in ipairs(category.items) do
                    if id == self.itemID then
                        foundCategoryIndex = catIdx
                        break
                    end
                end
                if foundCategoryIndex then break end
            end
            
            -- Open UI if it isn't generated yet
            if not FishingModule.FishLogFrame then
                FishingModule:CreateFishLogUI()
            end
            FishingModule.FishLogFrame:Show()
            
            -- Command the UI to navigate to that exact item
            if foundCategoryIndex and FishingModule.SelectCategory then
                FishingModule:SelectCategory(foundCategoryIndex, false, self.itemID)
            end
            
            -- Safely terminate the animation to trigger the next toast in the queue
            self.anim:Stop()
            self:Hide()
            FishingModule:PlayNextToast()
        end)
        
        self.toastFrame = f
    end

    -- Save the itemID to the frame so OnClick knows what to look for
    self.toastFrame.itemID = itemID

    self.toastFrame.icon:SetTexture(itemIcon)
    self.toastFrame.name:SetText(itemName)
    
    if itemRarity then
        local r, g, b = GetItemQualityColor(itemRarity)
        self.toastFrame.name:SetTextColor(r, g, b)
    else
        self.toastFrame.name:SetTextColor(1, 1, 1)
    end
    
    self.toastFrame:Show()
    self.toastFrame.anim:Stop()
    self.toastFrame.anim:Play()

    if SOUNDKIT and SOUNDKIT.UI_ACHIEVEMENT_AWARD then
        PlaySound(SOUNDKIT.UI_ACHIEVEMENT_AWARD)
    else
        PlaySound(3175) 
    end
end

function FishingModule:ShowDiscoveryToast(itemID)
    table.insert(self.toastQueue, itemID)
    if not self.isToasting then
        self:PlayNextToast()
    end
end

function FishingModule:ScanInventoryForPoles()
    local db = Purity:GetDB()
    db.fishingLifetimeLog = db.fishingLifetimeLog or {}
    
    -- Check equipped main-hand and off-hand
    local inventorySlots = { INVSLOT_MAINHAND, INVSLOT_OFFHAND }
    for _, slotId in ipairs(inventorySlots) do
        local link = GetInventoryItemLink("player", slotId)
        if link then
            local itemID = tonumber(link:match("item:(%d+)"))
            if ACQUIRED_POLES_LIST[itemID] and not db.fishingLifetimeLog[itemID] then
                db.fishingLifetimeLog[itemID] = true
                self:ShowDiscoveryToast(itemID)
            end
        end
    end
    
    -- Check all bag slots (0 to 4)
    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemLink = C_Container.GetContainerItemLink(bag, slot)
            if itemLink then
                local itemID = tonumber(itemLink:match("item:(%d+)"))
                if ACQUIRED_POLES_LIST[itemID] and not db.fishingLifetimeLog[itemID] then
                    db.fishingLifetimeLog[itemID] = true
                    self:ShowDiscoveryToast(itemID)
                end
            end
        end
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
	for _, category in ipairs(self.FishLogCategories) do
        for _, itemID in ipairs(category.items) do
            GetItemInfo(itemID)
        end
    end
    for itemID in pairs(ACQUIRED_POLES_LIST) do GetItemInfo(itemID) end
    for itemID in pairs(FISHABLE_CONTAINER_IDS) do GetItemInfo(itemID) end
    for itemID in pairs(DIRECT_FISHED_EQUIPPABLES) do GetItemInfo(itemID) end
	
    local db = Purity:GetDB()
    if not db.fishingLifetimeLog then
        db.fishingLifetimeLog = {}
    end

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
	
	local poleScanner = CreateFrame("Frame")
    poleScanner:RegisterEvent("BAG_UPDATE")
    poleScanner:RegisterEvent("MERCHANT_CLOSED")
    poleScanner:RegisterEvent("PLAYER_REGEN_ENABLED")
    poleScanner:SetScript("OnEvent", function()
        self:ScanInventoryForPoles()
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