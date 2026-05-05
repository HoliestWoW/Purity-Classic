-- Purity AddOn - Core (Final Roster Version)

BINDING_HEADER_PURITY = "Purity";
BINDING_NAME_PURITY_TOGGLE = "Toggle Purity Window";
local addonName, Purity = ...
Purity.Version = "12.0.2"
if not Purity_GlobalSettings then Purity_GlobalSettings = {} end

Purity.BLOODMAGE_CLASS_OVERRIDES = {
    ["PALADIN"] = { name = "Oath Breaker", colorHex = "FF0000" }
}

function Purity:EnforceDefaultClassColors()
    if RAID_CLASS_COLORS and RAID_CLASS_COLORS.PALADIN then
        RAID_CLASS_COLORS.PALADIN.r = 0.96
        RAID_CLASS_COLORS.PALADIN.g = 0.55
        RAID_CLASS_COLORS.PALADIN.b = 0.73
    end
end

function Purity:GetThematicClassName(className)
    local db = self:GetDB()
    local mod = Purity.GlobalModules and Purity.GlobalModules.BLOOD_MAGE_BARGAIN
    local rank = (mod and mod.GetOathbreakerRank) and mod:GetOathbreakerRank() or 0

    if db.activeChallengeID == "BLOOD_MAGE_BARGAIN" and rank > 0 and self.BLOODMAGE_CLASS_OVERRIDES[className] then
        return self.BLOODMAGE_CLASS_OVERRIDES[className].name
    end
    return className:sub(1,1) .. className:sub(2):lower()
end

function Purity:UpdateCharacterFrameClassName()
    local db = self:GetDB()
    local _, playerClass = UnitClass("player")
    if playerClass ~= "PALADIN" then return end

    local mod = Purity.GlobalModules and Purity.GlobalModules.BLOOD_MAGE_BARGAIN
    local rank = (mod and mod.GetOathbreakerRank) and mod:GetOathbreakerRank() or 0

    local levelTextFrame = _G["CharacterLevelText"]
    if not levelTextFrame then return end

    local originalText = levelTextFrame:GetText()
    if not originalText then return end
    
    if db and db.activeChallengeID == "BLOOD_MAGE_BARGAIN" and rank > 0 then
        levelTextFrame:SetText(string.gsub(originalText, "Paladin", "Oath Breaker"))
    else
        levelTextFrame:SetText(string.gsub(originalText, "Oath Breaker", "Paladin"))
    end
end

function Purity:GetThematicClassColor(className, playerData)
    if not className then return nil end
    local defaultPaladinColor = "F58CBA"
    local db = self:GetDB()
    
    local mod = Purity.GlobalModules and Purity.GlobalModules.BLOOD_MAGE_BARGAIN
    local rank = (mod and mod.GetOathbreakerRank) and mod:GetOathbreakerRank() or 0

    if className == "PALADIN" and db and db.activeChallengeID == "BLOOD_MAGE_BARGAIN" and rank > 0 then
        return self.BLOODMAGE_CLASS_OVERRIDES["PALADIN"].colorHex
    elseif className == "PALADIN" then
        return defaultPaladinColor
    end
    return nil
end

Purity.hasSentInitialPing = false
Purity.purityChannelID = nil
Purity.ADDON_PREFIX = "PURITYCOMMS"
Purity.roster = {}

local securePingFrame = CreateFrame("Frame", "PuritySecurePingFrame")
securePingFrame:RegisterForDrag("LeftButton")
function securePingFrame:SendPing(channelID)
    if channelID then
        SendChatMessage("!purity_ping", "CHANNEL", nil, channelID)
    end
end

Purity_Warning = "NOTICE: The integrity of this character's challenge data is paramount. Any manual modification will be detected and will result in the forfeiture of your run."
Purity_PerCharacterDB = Purity_PerCharacterDB

Purity.isTrainerHooked = false
Purity.ClassModules = {}
Purity.GlobalModules = {}
Purity.selectedChallenge = nil
Purity.hasUIBeenCreated = false

-- The Core Shadow Vault
local secureCoreState = {
    isActive = false,
    status = "Not Participating",
    weaponInfractions = 0,
    physicalStrikes = 0
}

function Purity:SyncSecureStateFromDB()
    local db = self:GetDB()
    secureCoreState.status = db.status or "Not Participating"
    secureCoreState.weaponInfractions = db.weaponInfractions or 0
    secureCoreState.physicalStrikes = db.physicalStrikes or 0
    secureCoreState.isActive = true
end

local _, _, _, interfaceVersion = GetBuildInfo()
local isMoP = (interfaceVersion >= 50000)
local MAX_PLAYER_LEVEL = 60 -- Default to Classic Era / SoD / Hardcore

if interfaceVersion >= 20000 and interfaceVersion < 30000 then
    MAX_PLAYER_LEVEL = 70 -- TBC Classic
elseif interfaceVersion >= 30000 and interfaceVersion < 40000 then
    MAX_PLAYER_LEVEL = 80 -- WotLK Classic
elseif interfaceVersion >= 40000 and interfaceVersion < 50000 then
	MAX_PLAYER_LEVEL = 85 -- Cata Classic
elseif interfaceVersion >= 50000 then
    MAX_PLAYER_LEVEL = 90 -- MoP Classic
end
local isMonitoring = false
local weaponTimer = nil
local purityRuntimeTicker = nil
local purityPlayedTimeTicker = nil
local uptimeMonitorTicker = nil
local activeClassModule = nil
local monitorFrame = nil
local trainerKey = "a7K9!zPq@3rT$5wX&8nMbVcFgHjL"

local Base64 = {}
local BASE64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

Purity.DRINK_LIST = {
    ["Bottle of Dalaran Noir"] = true,
    ["Cheap Beer"] = true,
	["Holiday Spirits"] = true,
	["Rhapsody Malt"] = true,
	["Thunder Ale"] = true,
	["Moonglow"] = true,
	["Evermurky"] = true,
	["Flask of Stormwind Tawny"] = true,
	["Skin of Dwarven Stout"] = true,
	["Southshore Stout"] = true,
	["Steamwheedle Fizzy Spirits"] = true,
	["Wizbang's Special Brew"] = true,
	["Cherry Grog"] = true,
	["Cuergo's Gold"] = true,
	["Flagon of Dwarven Honeymead"] = true,
	["Greatfather's Winter Ale"] = true,
	["Jug of Badlands Bourbon"] = true,
	["Junglevine Wine"] = true,
	["Molasses Firewater"] = true,
	["Volatile Rum"] = true,
	["Cuergo's Gold with Worm"] = true,
	["Dark Dwarven Lager"] = true,
	["Darkmoon Special Reserve"] = true,
}

function Base64.encode(data)
    local result = {}
    local len = #data
    for i = 1, len, 3 do
        local b1 = data:byte(i)
        local b2 = data:byte(i + 1) or 0
        local b3 = data:byte(i + 2) or 0

        local combined = bit.bor(bit.lshift(b1, 16), bit.lshift(b2, 8), b3)

        table.insert(result, BASE64_CHARS:sub(bit.rshift(combined, 18) + 1, bit.rshift(combined, 18) + 1))
        table.insert(result, BASE64_CHARS:sub(bit.band(bit.rshift(combined, 12), 0x3F) + 1, bit.band(bit.rshift(combined, 12), 0x3F) + 1))
        table.insert(result, BASE64_CHARS:sub(bit.band(bit.rshift(combined, 6), 0x3F) + 1, bit.band(bit.rshift(combined, 6), 0x3F) + 1))
        table.insert(result, BASE64_CHARS:sub(bit.band(combined, 0x3F) + 1, bit.band(combined, 0x3F) + 1))
    end

    local encoded_string = table.concat(result)

    local padding = len % 3
    if padding == 1 then
        encoded_string = encoded_string:sub(1, #encoded_string - 2) .. "=="
    elseif padding == 2 then
        encoded_string = encoded_string:sub(1, #encoded_string - 1) .. "="
    end

    return encoded_string
end

local HIDE_RTP_CHAT_MSG_BUFFER = 0
local HIDE_RTP_CHAT_MSG_BUFFER_MAX = 5

-- Filter the CHAT_MSG_SYSTEM event directly
ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", function(frame, event, message, ...)
    if HIDE_RTP_CHAT_MSG_BUFFER > 0 then
        -- Get the localized global strings and strip the "%s" variable
        -- "Total time played: %s" -> "Total time played: "
        local totalPrefix = string.gsub(TIME_PLAYED_TOTAL, "%%s", "") 
        local levelPrefix = string.gsub(TIME_PLAYED_LEVEL, "%%s", "")

        -- Check if the message starts with "Total time played"
        if string.find(message, totalPrefix, 1, true) then
            -- Hide this line, but don't decrement buffer yet (the "Level" line comes next)
            return true 
        end

        -- Check if the message starts with "Time played this level"
        if string.find(message, levelPrefix, 1, true) then
            -- This is the second message, so we decrement the buffer now
            HIDE_RTP_CHAT_MSG_BUFFER = HIDE_RTP_CHAT_MSG_BUFFER - 1
            if HIDE_RTP_CHAT_MSG_BUFFER < 0 then HIDE_RTP_CHAT_MSG_BUFFER = 0 end
            
            return true -- Hide message
        end
    end
    
    return false, message, ...
end)

Purity.ChallengeCoefficients = {
	["Path of the Unburdened"] = 5.00,
	["The Ringbearer's Vow"] = 4.90,
	["Path of Resilience"] = 4.86,
    ["The Blood Mage's Bargain"] = 4.65,
	["The Glass Heart (Extreme)"] = 4.50,
	["Quiver of Purity"] = 4.45,
	["Path of Humility"] = 4.40,
	["Brand of Purity"] = 4.35,
	["Fisherman's Folly"] = 4.32,
	["Shroud of Purity"] = 3.95,
	["Libram of Purity"] = 4.25,
	["Tether of Purity"] = 3.80,
	["Conduit of Purity"] = 4.10,
	["Crackling Tome of Purity"] = 4.05,
	["Astrolabe of Purity"] = 4.00,
	["Flame of Purity"] = 3.91,
	["Sacrament of Purity"] = 3.85,
	["Pact of Purity"] = 3.85,
	["Bond of Purity"] = 3.80,
	["Testament of Purity"] = 3.77,
    ["The Drunken Master"] = 3.65,
	["The Glass Heart (Hard)"] = 3.50,
	["Oath of Purity"] = 3.23,
	["Contract of Purity"] = 3.20,
	["Covenant of Purity"] = 3.00,
	["Bulwark of Purity"] = 2.75,
	["Communion of Purity"] = 2.68,
	["Grimoire of Purity"] = 2.25,
	["Burnt Tome of Purity"] = 2.27,
	["Frozen Tome of Purity"] = 2.14,
	["Foil of Purity"] = 2.00
}

Purity.HardcoreRealms = {
    -- NA Realms
    ["Doomhowl"] = true,
    ["Defias Pillager"] = true,
    ["Skull Rock"] = true,
    -- EU Realms
    ["Soulseeker"] = true,
    ["Nek'Rosh"] = true,
    ["Stitches"] = true
}

function Purity:IsOnCommunityHardcoreChallenge()
    if not Hardcore_Character or not Hardcore_GetSecurityStatus then
        return false
    end

    if Hardcore_Character.guid ~= UnitGUID("player") then
        return false
    end

    if Hardcore_GetSecurityStatus() ~= "OK" then
        return false
    end

    if Hardcore_Character.deaths and next(Hardcore_Character.deaths) == nil then
        return true
    end

    return false
end

function Purity:IsHardcoreStatusValid()
    if not Hardcore_Character or not Hardcore_GetSecurityStatus then
        return false, "Hardcore addon not detected."
    end
    
    if Hardcore_GetSecurityStatus() ~= "OK" then
        return false, "Hardcore data security check failed."
    end
    
    local status = Hardcore_Character.verification_status
    if status == "FAIL" then
        return false, "Hardcore challenge is marked as 'FAIL'."
    end
    
    return true
end

function Purity_TogglePanel()
    if Purity and Purity.mainInterfaceFrame then
        if Purity.mainInterfaceFrame:IsShown() then
            Purity.mainInterfaceFrame:Hide()
        else
            Purity.mainInterfaceFrame:Show()
            Purity:selectTab("status")
        end
    end
end

function Purity:UpdateAllModifierStatuses()
    local db = self:GetDB()
    if not db then return end

    local wasHardcore, wasSelfFound, wasSSF = db.isHardcoreRun, db.isSelfFoundRun, db.isSSFRun
    
    local isNowHardcore, isNowSelfFound, isNowSSF = false, false, false

    local realmName = GetRealmName()
    if realmName and Purity.HardcoreRealms[realmName] then
        isNowHardcore = true
    end

    if self:IsOnCommunityHardcoreChallenge() then
        isNowSSF = true
        isNowHardcore = true
    end

    -- Iterate through all buffs
    for i = 1, 40 do
        local name, _, _, _, _, _, _, _, _, spellId = UnitAura("player", i)
        
        if not name then 
            break
        end

        if spellId == 431567 then 
            isNowSelfFound = true
            isNowHardcore = true
        elseif spellId == 364001 then 
            isNowHardcore = true
        end
    end

    if wasHardcore ~= isNowHardcore or wasSelfFound ~= isNowSelfFound or wasSSF ~= isNowSSF then
        
        db.isHardcoreRun = isNowHardcore
        db.isSelfFoundRun = isNowSelfFound
        db.isSSFRun = isNowSSF
        
        if db.isOptedIn then
            local prefix = "|cffFFFF00Purity:|r "
            
            if wasHardcore ~= isNowHardcore then
                if isNowHardcore then
                    print(prefix .. "Hardcore status detected. |cff00FF00(Mode Enabled)|r")
                else
                    print(prefix .. "Hardcore status lost. |cffFF0000(Mode Disabled)|r")
                end
            end

            if wasSelfFound ~= isNowSelfFound then
                if isNowSelfFound then
                    print(prefix .. "Self-Found status detected. |cff00FF00(Mode Enabled)|r")
                else
                    print(prefix .. "Self-Found status lost. |cffFF0000(Mode Disabled)|r")
                end
            end

            if wasSSF ~= isNowSSF then
                if isNowSSF then
                    print(prefix .. "Community SSF status detected. |cff00FF00(Mode Enabled)|r")
                else
                    print(prefix .. "Community SSF status lost. |cffFF0000(Mode Disabled)|r")
                end
            end
        end
    end
end

function Purity:StartModifierMonitor()
    if self.modifierTicker then self.modifierTicker:Cancel() end

    self.modifierTicker = C_Timer.NewTicker(5, function()
        self:UpdateAllModifierStatuses()
    end)
end

function Purity:GetCurrentChallengeInfo()
    local db = self:GetDB()
    if not db or not db.challengeTitle then return nil, 1.0 end

    -- Helper to get coeff for a specific ID
    local function GetCoeff(name)
        return Purity.ChallengeCoefficients[name] or 1.0
    end
	
    local mainKey = db.challengeTitle
    local activeChallenge = self:GetActiveChallengeObject()
    local specifier = nil
    
    -- 1. Retrieve the specifier (e.g. "HARD", "EXTREME", "Fire", etc.)
    if activeChallenge and activeChallenge.GetChallengeSpecifier then
        specifier = activeChallenge:GetChallengeSpecifier()
    end

    -- 2. Modify mainKey based on the specifier to match Purity.ChallengeCoefficients keys
    if mainKey == "The Ascetic's Path" and specifier then
        if specifier == "EASY" then mainKey = "Path of Humility"
        elseif specifier == "MEDIUM" then mainKey = "Path of Resilience"
        elseif specifier == "HARD" then mainKey = "Path of the Unburdened" end
        
    elseif mainKey == "Tome of Purity" and specifier then
        -- Converts "Arcane" -> "Tome of Purity (Arcane)"
        mainKey = string.format("Tome of Purity (%s)", specifier:sub(1,1):upper()..specifier:sub(2):lower())
        
    elseif mainKey == "The Glass Heart" and specifier then
        -- Converts "HARD" -> "The Glass Heart (Hard)"
        local formattedSpec = specifier:sub(1,1):upper()..specifier:sub(2):lower()
        mainKey = string.format("The Glass Heart (%s)", formattedSpec)
    end

    local mainCoeff = GetCoeff(mainKey)
    local finalCoeff = mainCoeff
    local displayName = mainKey

    -- MoP Logic: Weighted Average for Death Knights
    if db.dkDestinyID then
        local destinyCoeff = GetCoeff(db.dkDestinyID)
        -- Weighted Average: (Vow + Destiny) / 2
        finalCoeff = (mainCoeff + destinyCoeff) / 2
        displayName = mainKey .. " + " .. db.dkDestinyID
    end

    return displayName, finalCoeff
end

function Purity:CalculateTotalCoefficient()
    local _, baseCoeff = self:GetCurrentChallengeInfo()
    
    -- [Insert your existing GameplayModifiers logic here (Hardcore/SSF)] --
    local multiplier = 1.0
    local modifiers = self:GetGameplayModifiers()
    
    if modifiers.isSSF then multiplier = 4.0
    elseif modifiers.isSelfFound then multiplier = 3.0
    elseif modifiers.isHardcore then multiplier = 2.0 
    end
    
    return baseCoeff * multiplier
end

function Purity:GetGameplayModifiers()
    local db = self:GetDB()
    local modifiers = {
        isHardcore = false,
        isSelfFound = false,
        isSSF = false
    }

    local isHardcoreStatusValid = self:IsHardcoreStatusValid()

    local isHC = db.isHardcoreRun
    local isSF = db.isSelfFoundRun
    local isSSF = db.isSSFRun and isHardcoreStatusValid

    if isSSF then
        modifiers.isSSF = true
        modifiers.isHardcore = true
    elseif isSF then
        modifiers.isSelfFound = true
        modifiers.isHardcore = true
    elseif isHC then
        modifiers.isHardcore = true
    end
    return modifiers
end

function Purity:GetDB()
    if Purity_PerCharacterDB == nil then
        Purity:InitializeDatabase()
    end
    return Purity_PerCharacterDB
end

function Purity:GetActiveChallengeObject()
    local db = self:GetDB()
    if not db.isOptedIn then
        return nil
    end

    local challengeID = db.activeChallengeID
    local moduleType = db.activeChallengeModuleType

    if moduleType == "Global" and Purity.GlobalModules and Purity.GlobalModules[challengeID] then
        return Purity.GlobalModules[challengeID]
    elseif moduleType == "Class" and activeClassModule then
        if activeClassModule.challenges then
            for key, challengeData in pairs(activeClassModule.challenges) do
                if challengeData.challengeName == challengeID then
                    return challengeData
                end
            end
            return nil
        else
            if activeClassModule.challengeName == challengeID then
                return activeClassModule
            end
        end
    end
    return nil
end

function Purity:SilentRequestTimePlayed()
    -- Increment the buffer so the filter knows to hide the next set of messages
    HIDE_RTP_CHAT_MSG_BUFFER = HIDE_RTP_CHAT_MSG_BUFFER + 1
    if HIDE_RTP_CHAT_MSG_BUFFER > HIDE_RTP_CHAT_MSG_BUFFER_MAX then
        HIDE_RTP_CHAT_MSG_BUFFER = HIDE_RTP_CHAT_MSG_BUFFER_MAX
    end
    RequestTimePlayed()
end

function Purity:FormatHex(n)
    local hex = ""
    for i = 7, 0, -1 do
        local nibble = bit.band(bit.rshift(n, i * 4), 0xF)
        hex = hex .. string.format("%x", nibble)
    end
    return hex
end

function Purity:CreateBackground(parent, r, g, b, a)
    local bg = parent:CreateTexture(nil, "BACKGROUND", nil, -8)
    bg:SetAllPoints(parent)
    bg:SetColorTexture(r or 0.05, g or 0.05, b or 0.1, a or 0.9)
    return bg
end

function Purity:MarkDBDirty()
end

function Purity:InitializeDatabase()
    if Purity_PerCharacterDB == nil then
        Purity_PerCharacterDB = {}
    end
    local defaults = {
		isOptedIn = false, status = "Not Participating",
		startDate = "N/A", completionDate = "N/A", addonRuntime = 0,
		totalPlayedTime = 0, finalUptime = nil, verificationCode = nil,
		hasBeenNotifiedOfLevelCap = false,
		weaponInfractions = 0,
		activeChallengeID = nil,
		challengeTitle = nil,
		playerGUID = nil,
		dataSignature = nil,
		uptimeGrace = 0,
        addonRuntimeAtLastPlayedSync = 0, -- ADDED THIS LINE
		physicalStrikes = 0,
		activeChallengeModuleType = nil,
		fishingFishedItemLinks = {},
        uptimeIsUnverified = false,
        failureReason = "N/A",
		isHardcoreRun = false,
		isSelfFoundRun = false,
		isSSFRun = false,
		challengeStats = {},
        bloodBarIsSeparate = false,
		dkDestinyID = nil,
		sequenceID = 0,
	}
    for key, value in pairs(defaults) do
        if Purity_PerCharacterDB[key] == nil then
            Purity_PerCharacterDB[key] = value
        end
    end
    if Purity_PerCharacterDB.isOptedIn == false and Purity_PerCharacterDB.status == "Passing" then
        Purity_PerCharacterDB.status = "Not Participating"
    end
end

local FCT_INCOMING_DAMAGE_EVENTS = {
    "DAMAGE",
    "DAMAGE_CRIT",
    "SPELL_DAMAGE",
    "SPELL_DAMAGE_CRIT",
    "PERIODIC_DAMAGE"
}

function Purity:DisableDefaultIncomingDamageText()
    local isLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) and C_AddOns.IsAddOnLoaded("Blizzard_CombatText") or (type(IsAddOnLoaded) == "function" and IsAddOnLoaded("Blizzard_CombatText"))

    -- Ensure the Blizzard addon is awake so we can edit its table
    if not isLoaded then
        if C_AddOns and C_AddOns.LoadAddOn then
            C_AddOns.LoadAddOn("Blizzard_CombatText")
        else
            LoadAddOn("Blizzard_CombatText")
        end
    end

    if COMBAT_TEXT_TYPE_INFO then
        for _, event in ipairs(FCT_INCOMING_DAMAGE_EVENTS) do
            if COMBAT_TEXT_TYPE_INFO[event] then
                COMBAT_TEXT_TYPE_INFO[event].show = false
            end
        end
    end
end

function Purity:RestoreDefaultIncomingDamageText()
    local isLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) and C_AddOns.IsAddOnLoaded("Blizzard_CombatText") or (type(IsAddOnLoaded) == "function" and IsAddOnLoaded("Blizzard_CombatText"))

    if isLoaded and COMBAT_TEXT_TYPE_INFO then
        for _, event in ipairs(FCT_INCOMING_DAMAGE_EVENTS) do
            if COMBAT_TEXT_TYPE_INFO[event] then
                COMBAT_TEXT_TYPE_INFO[event].show = true
            end
        end
    end
end

function Purity:InternalResetChallenge()
    local db = Purity:GetDB()
	
	Purity:RestoreDefaultIncomingDamageText()
    
    db.isOptedIn = false
    db.status = "Not Participating"
	if secureCoreState then
        secureCoreState.status = "Not Participating"
        secureCoreState.isActive = false
    end
    db.startDate = "N/A"
    db.completionDate = "N/A"
    db.addonRuntime = 0
    db.totalPlayedTime = 0
    db.finalUptime = nil
    db.verificationCode = nil
    db.hasBeenNotifiedOfLevelCap = false
    db.weaponInfractions = 0
    db.activeChallengeID = nil
    db.challengeTitle = nil
    db.playerGUID = nil
    db.dataSignature = nil
    db.uptimeSignature = nil
    db.uptimeGrace = 0
    db.addonRuntimeAtLastPlayedSync = 0 -- ADDED THIS LINE
	db.physicalStrikes = 0
	db.activeChallengeModuleType = nil
    db.uptimeIsUnverified = false
    db.addonRuntime_lastHash = 0
    db.totalPlayedTime_lastHash = 0
	db.failureReason = "N/A"
	db.isHardcoreRun = false
	db.isSelfFoundRun = false
	db.isSSFRun = false
	db.challengeStats = {}

	if db.fishingFishedItemLinks then
		wipe(db.fishingFishedItemLinks)
	end

    isMonitoring = false
    if purityRuntimeTicker then purityRuntimeTicker:Cancel(); purityRuntimeTicker = nil end
    if purityPlayedTimeTicker then purityPlayedTimeTicker:Cancel(); purityPlayedTimeTicker = nil end
	if self.communityHCTicker then self.communityHCTicker:Cancel(); self.communityHCTicker = nil end
	if uptimeMonitorTicker then uptimeMonitorTicker:Cancel(); uptimeMonitorTicker = nil end
    if weaponTimer then weaponTimer:Cancel(); weaponTimer = nil; Purity.weaponWarningFrame:Hide() end
end

function Purity:ResetChallenge()
    Purity:InternalResetChallenge()
    if Purity.mainInterfaceFrame and Purity.mainInterfaceFrame:IsShown() then
        Purity.mainInterfaceFrame:Hide()
    end
    if UnitLevel("player") == 1 then
        Purity.optInFrame:Show()
    end
end

function Purity:DisplayRules()
    local currentDB = Purity:GetDB()
    local activeChallenge = self:GetActiveChallengeObject()

    if not activeChallenge then
        Purity.rulesPane.title:SetText("No Active Challenge")
        if Purity.rulesPane.lines then
            for _, line in ipairs(Purity.rulesPane.lines) do line:Hide() end
        end
        return
    end

    Purity.rulesPane.title:SetText(currentDB.challengeTitle or activeChallenge.challengeName)
    local rules = activeChallenge:GetRulesText()
    local yOffset = -65

    if Purity.rulesPane.lines then
        for _, line in ipairs(Purity.rulesPane.lines) do
            line:Hide()
        end
    end
    Purity.rulesPane.lines = {}
    local defaultLineSpacing = 30
    local emptyLineSpacing = 10

    for _, lineText in ipairs(rules) do
        local line = Purity.rulesPane:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        line:SetPoint("TOPLEFT", Purity.rulesPane, "TOPLEFT", 40, yOffset)
        line:SetPoint("TOPRIGHT", Purity.rulesPane, "TOPRIGHT", -40, yOffset)
        line:SetText(lineText)
        line:SetJustifyH("LEFT")
        table.insert(Purity.rulesPane.lines, line)
        
        if lineText == " " then
            yOffset = yOffset - emptyLineSpacing
        else
            yOffset = yOffset - defaultLineSpacing
        end
    end
end

function Purity:BuildChallengeTypeMap()
    self.ChallengeTypeMap = {}

    -- Process Global Modules
    if self.GlobalModules then
        for _, module in pairs(self.GlobalModules) do
            if module.challengeName == "The Ascetic's Path" then
                self.ChallengeTypeMap["Path of Humility"] = "Global"
                self.ChallengeTypeMap["Path of Resilience"] = "Global"
                self.ChallengeTypeMap["Path of the Unburdened"] = "Global"
            elseif module.challengeName == "The Glass Heart" then
                self.ChallengeTypeMap["The Glass Heart (Hard)"] = "Global"
                self.ChallengeTypeMap["The Glass Heart (Extreme)"] = "Global"
            elseif module.challengeName then
                self.ChallengeTypeMap[module.challengeName] = "Global"
            end
        end
    end

    -- Process Class-Specific Modules
    if self.ClassModules then
        for className, classModule in pairs(self.ClassModules) do
            local friendlyClassName = className:sub(1,1) .. className:sub(2):lower()
            if classModule.challenges then
                for _, challengeData in pairs(classModule.challenges) do
                    self.ChallengeTypeMap[challengeData.challengeName] = friendlyClassName
                end
            elseif classModule.challengeName then
                if classModule.challengeName == "Tome of Purity" then
                    self.ChallengeTypeMap["Tome of Purity (Arcane)"] = friendlyClassName
                    self.ChallengeTypeMap["Tome of Purity (Fire)"] = friendlyClassName
                    self.ChallengeTypeMap["Tome of Purity (Frost)"] = friendlyClassName
                else
                    self.ChallengeTypeMap[classModule.challengeName] = friendlyClassName
                end
            end
        end
    end
end

function Purity:DisplayCompletionStats()
    local db = self:GetDB()
    if not db or (not db.challengeStats and not db.fishingFishedItemLinks) then return end

    local stats = db.challengeStats or {}
    local challenge = db.challengeTitle
    local message

    if challenge == "Sacrament of Purity" and stats.lifeTapCasts then
        message = string.format("Fun fact: During your challenge, you cast Life Tap %d times!", stats.lifeTapCasts)
    elseif challenge == "Grimoire of Purity" and stats.immolateCasts then
        message = string.format("Fun fact: During your demonic studies, you cast Immolate %d times!", stats.immolateCasts)
    elseif challenge == "Brand of Purity" and stats.chargeInterceptCasts then
        message = string.format("Fun fact: During your challenge, you Charged or Intercepted %d times!", stats.chargeInterceptCasts)
    elseif challenge == "Bulwark of Purity" and stats.blocks then
        message = string.format("Fun fact: As an ardent protector, you successfully blocked %d attacks!", stats.blocks)
    elseif db.activeChallengeID == "Tome of Purity" and stats.primarySpellCasts then
        message = string.format("Fun fact: During your studies, you cast your primary spell %d times!", stats.primarySpellCasts)
	elseif challenge == "Conduit of Purity" then
        local charge = stats.chargeAccumulatedCombat or 0
        message = string.format("Fun fact: Through constant motion, you generated %d Static Charge during combat!", math.floor(charge))
    elseif challenge == "Testament of Purity" and stats.smiteCasts then
        message = string.format("Fun fact: To uphold your testament, you cast Smite %d times!", stats.smiteCasts)
    elseif challenge == "Covenant of Purity" and stats.mindFlayCasts then
        message = string.format("Fun fact: Embracing the shadows, you channeled Mind Flay %d times!", stats.mindFlayCasts)
    elseif challenge == "Oath of Purity" and stats.holyLightCasts then
        message = string.format("Fun fact: As a selfless guardian, you cast Holy Light %d times!", stats.holyLightCasts)
    elseif challenge == "Libram of Purity" and stats.exorcismCasts then
        message = string.format("Fun fact: In your crusade against the undead, you cast Exorcism %d times!", stats.exorcismCasts)
    elseif challenge == "Communion of Purity" and stats.lightningBoltCasts then
        message = string.format("Fun fact: In communion with the elements, you cast Lightning Bolt %d times!", stats.lightningBoltCasts)
    elseif challenge == "Flame of Purity" and stats.fireSpellCasts then
        message = string.format("Fun fact: Your inner flame burned bright, leading you to cast %d fire spells!", stats.fireSpellCasts)
    elseif challenge == "Pact of Purity" and stats.shapeshiftCasts then
        message = string.format("Fun fact: To protect the wilds, you shapeshifted into Bear Form %d times!", stats.shapeshiftCasts)
    elseif challenge == "Astrolabe of Purity" and stats.celestialCasts then
        message = string.format("Fun fact: To maintain celestial balance, you wove %d solar and lunar spells!", stats.celestialCasts)
    elseif challenge == "Contract of Purity" and stats.sinisterStrikeCasts then
        message = string.format("Fun fact: As an honorable duelist, you used Sinister Strike %d times!", stats.sinisterStrikeCasts)
    elseif challenge == "Foil of Purity" and stats.riposteCasts then
        message = string.format("Fun fact: With your fencer's grace, you successfully Riposted %d times!", stats.riposteCasts)
    elseif challenge == "Bond of Purity" and stats.mendPetCasts then
        message = string.format("Fun fact: To maintain your bond, you mended your pet %d times!", stats.mendPetCasts)
    elseif challenge == "Quiver of Purity" and stats.aimedShotCasts then
        message = string.format("Fun fact: As a lone wolf, you took aim and fired %d Aimed Shots!", stats.aimedShotCasts)
    elseif challenge == "Fisherman's Folly" then
        local fishCount = stats.totalCatches or 0
        local trunkCount = stats.trunksFished or 0
        message = string.format("Fun fact: During your folly, you had %d successful catches, including %d trunks!", fishCount, trunkCount)        message = string.format("Fun fact: During your folly, you had %d successful catches, including %d trunks!", fishCount, trunkCount)
	elseif challenge == "The Glass Heart" and stats.lowestGlassHP then
        message = string.format("Fun fact: You walked the razor's edge! The closest your Glass Heart came to shattering was at %.1f%% integrity.", stats.lowestGlassHP)
    elseif challenge == "The Ascetic's Path" and stats.forbiddenItemsSold then
        message = string.format("Fun fact: On your path of self-denial, you sold %d items that you were forbidden to equip!", stats.forbiddenItemsSold)
    end

    if message then
        print("|cffFFFF00Purity:|r " .. message)
    end
end

function Purity:DisplayRankings()
    local pane = self.rankingsPane
    if not (pane and pane.scrollFrame and pane.scrollChild) then return end

    local scrollChild = pane.scrollChild
    local scrollFrame = pane.scrollFrame

    -- Clear existing lines from the scroll child
    if scrollChild.lines then
        for _, line in ipairs(scrollChild.lines) do
            line:Hide()
        end
    end
    scrollChild.lines = {}

    local goldColor = "|cffffd100"
    local whiteColor = "|cffffffff"
    local darkColor = "|cff261a0d"
    local greenColor = "|cff00FF00"

    local yOffset = -15
    local lineSpacing = 22
    local totalHeight = 20

    -- [SECTION 1] GAMEPLAY MODIFIERS (The missing info)
    local function AddHeader(text)
        local h = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        h:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
        h:SetText(goldColor .. text .. "|r")
        table.insert(scrollChild.lines, h)
        yOffset = yOffset - 25
        totalHeight = totalHeight + 25
    end

    local function AddModLine(name, value)
        local label = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        label:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 20, yOffset)
        label:SetText(whiteColor .. name .. "|r")
        
        local val = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        val:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -20, yOffset)
        val:SetText(greenColor .. value .. "|r")
        
        table.insert(scrollChild.lines, label)
        table.insert(scrollChild.lines, val)
        yOffset = yOffset - 18
        totalHeight = totalHeight + 18
    end

    AddHeader("Gameplay Multipliers")
    AddModLine("Hardcore (Soul of Iron)", "x2.0")
    AddModLine("Self-Found (Official Buff)", "x3.0")
    AddModLine("SSF (Hardcore AddOn)", "x4.0")

    -- Add a separator line
    yOffset = yOffset - 10
    local separator = scrollChild:CreateTexture(nil, "ARTWORK")
    separator:SetHeight(1)
    separator:SetColorTexture(1, 1, 1, 0.2)
    separator:SetPoint("LEFT", 10, 0)
    separator:SetPoint("RIGHT", -10, 0)
    separator:SetPoint("TOP", scrollChild, "TOP", 0, yOffset)
    table.insert(scrollChild.lines, separator) -- Add to lines table so it gets hidden on refresh
    yOffset = yOffset - 20
    totalHeight = totalHeight + 30

    -- [SECTION 2] CHALLENGE RANKINGS
    AddHeader("Challenge Base Coefficients")

    local sortedChallenges = {}
    if not self.ChallengeCoefficients then return end
    for name, coeff in pairs(self.ChallengeCoefficients) do
        table.insert(sortedChallenges, {name = name, coeff = coeff})
    end

    table.sort(sortedChallenges, function(a, b)
        return a.coeff > b.coeff
    end)

    for i, challengeData in ipairs(sortedChallenges) do
        local rankText = string.format("%d.", i)
        local challengeName = challengeData.name
        local coefficientText = string.format("%.2f", challengeData.coeff)

        local challengeType = (self.ChallengeTypeMap and self.ChallengeTypeMap[challengeName]) or ""
        local challengeNameText = challengeName
        if challengeType ~= "" then
            local typeColor
            local classUpper = string.upper(challengeType)

            if classUpper == "SHAMAN" then
                typeColor = "|cff0070DD"
            elseif classUpper == "PALADIN" then
                typeColor = "|cfff48cba"
            else
                local classInfo = RAID_CLASS_COLORS[classUpper]
                if classInfo and challengeType ~= "Global" then
                    typeColor = string.format("|cff%02x%02x%02x", classInfo.r*255, classInfo.g*255, classInfo.b*255)
                else
                    typeColor = "|cffb0b0b0" -- Grey fallback for "Global" or unknown
                end
            end
            challengeNameText = string.format("%s (%s%s|r)", challengeName, typeColor, challengeType)
        end

        local rankLine = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        rankLine:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 20, yOffset)
        rankLine:SetText(goldColor .. rankText .. "|r")
        table.insert(scrollChild.lines, rankLine)

        local coeffLine = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        coeffLine:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -20, yOffset)
        coeffLine:SetText(goldColor .. coefficientText .. "|r")
        table.insert(scrollChild.lines, coeffLine)

        local nameLine = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        nameLine:SetPoint("LEFT", rankLine, "RIGHT", 15, 0)
        nameLine:SetPoint("RIGHT", coeffLine, "LEFT", -10, 0) -- Prevents overlap
        nameLine:SetJustifyH("LEFT")
        nameLine:SetText(darkColor .. challengeNameText .. "|r")
        table.insert(scrollChild.lines, nameLine)

        yOffset = yOffset - lineSpacing
        totalHeight = totalHeight + lineSpacing
    end

    scrollChild:SetHeight(totalHeight)
    scrollFrame:SetVerticalScroll(0)
end

function Purity:GenerateVerificationHash(fullStringForHashing)
    local hash = 0
    for i = 1, #fullStringForHashing do
        local char_code = string.byte(fullStringForHashing, i)
        hash = (hash * 31 + char_code) % 2^32
    end
    return self:FormatHex(hash)
end

function Purity:UpdateAndGetStatusStrings()
    local data = self:GetRawStatusData()
    local statusColor = "|cff00FF00"
    if data.status == "Failed" then statusColor = "|cffFF0000"
    elseif data.status == "Not Participating" then statusColor = "|cff888888"
    elseif data.status == "Temporary Failure - Uptime" then statusColor = "|cffFFFF00"
    elseif data.status == "Passed" then statusColor = "|cff00FF00" end

    local goldColor = "|cffffd100"
    local darkColor = "|cff261a0d"

    local currentUptime = (data.totalPlayed > 0 and (data.addonRuntime / data.totalPlayed) * 100) or 0
    local uptimeDisplay = string.format("%.2f%%", currentUptime)
    local uptimeLabel = "Uptime:|r "
    
    if data.status == "Passed" or data.status == "Failed" then
        uptimeDisplay = string.format("%.2f%%", data.finalUptime or 0)
        uptimeLabel = "Final Uptime:|r "
    end
    
    for i=1, #Purity.mainInterfaceFrame.statusText do
        Purity.mainInterfaceFrame.statusText[i]:SetText("")
    end

    local activeChallenge = self:GetActiveChallengeObject()
    local lineIndex = 1

    Purity.mainInterfaceFrame.statusText[lineIndex]:SetText(goldColor .. "Status:|r " .. statusColor .. data.status .. "|r"); lineIndex = lineIndex + 1

    if (data.status == "Passed" or data.status == "Failed") and data.challengeTitle then
        Purity.mainInterfaceFrame.statusText[lineIndex]:SetText(goldColor .. "Challenge:|r " .. darkColor .. data.challengeTitle .. "|r"); lineIndex = lineIndex + 1
        if activeChallenge and activeChallenge.GetChallengeSpecifier and activeChallenge.specializations then
            local specifier = activeChallenge:GetChallengeSpecifier()
            if specifier then
                local specName = "Unknown Path"
                for _, specData in ipairs(activeChallenge.specializations) do
                    if specData.id == specifier then specName = specData.name; break; end
                end
                Purity.mainInterfaceFrame.statusText[lineIndex]:SetText(goldColor .. "Path:|r " .. darkColor .. specName .. " (" .. specifier .. ")|r"); lineIndex = lineIndex + 1
            end
        end
    end

    Purity.mainInterfaceFrame.statusText[lineIndex]:SetText(goldColor .. uptimeLabel .. darkColor .. uptimeDisplay .. "|r"); lineIndex = lineIndex + 1

    if activeChallenge and activeChallenge.needsWeaponWarning and data.status ~= "Passed" and data.status ~= "Failed" then
        Purity.mainInterfaceFrame.statusText[lineIndex]:SetText(goldColor .. "Weapon Warnings:|r " .. darkColor .. (data.weaponInfractions or 0) .. "/2|r"); lineIndex = lineIndex + 1
    end
	
	if activeChallenge and activeChallenge.challengeName == "Testament of Purity" and (data.status == "Passing" or data.status == "Temporary Failure - Uptime") then
        Purity.mainInterfaceFrame.statusText[lineIndex]:SetText(goldColor .. "Physical Strikes:|r " .. darkColor .. (data.physicalStrikes or 0) .. "/2|r"); lineIndex = lineIndex + 1
    end

    Purity.mainInterfaceFrame.statusText[lineIndex]:SetText(goldColor .. "Start Date:|r " .. darkColor .. (data.startDate or "N/A") .. "|r"); lineIndex = lineIndex + 1
    
    if data.completionDate ~= "N/A" then
        Purity.mainInterfaceFrame.statusText[lineIndex]:SetText(goldColor .. "Completion Date:|r " .. darkColor .. data.completionDate .. "|r"); lineIndex = lineIndex + 1
    end

    if data.status == "Passed" then
        Purity.mainInterfaceFrame.statusText[lineIndex]:SetText("|cff00FF00Congratulations! Challenge Passed!|r"); lineIndex = lineIndex + 1
        Purity.mainInterfaceFrame.statusText[lineIndex]:SetText("Go to the 'Verify' tab to get your code."); lineIndex = lineIndex + 1
    end
end

function Purity:IsVersionOlder(v1, v2)
    local t1 = {}
    for n in string.gmatch(v1, "%d+") do
        table.insert(t1, tonumber(n))
    end
    local t2 = {}
    for n in string.gmatch(v2, "%d+") do
        table.insert(t2, tonumber(n))
    end

    for i = 1, math.max(#t1, #t2) do
        local n1 = t1[i] or 0
        local n2 = t2[i] or 0
        if n1 < n2 then
            return true
        elseif n1 > n2 then
            return false
        end
    end
    return false
end

local function RecursiveSerialize(value)
    if type(value) == "table" then
        local serialized_table = ""
        local sorted_keys = {}
        for k in pairs(value) do table.insert(sorted_keys, k) end
        table.sort(sorted_keys)

        for _, k in ipairs(sorted_keys) do
            -- This function calls itself to handle nested keys and values
            serialized_table = serialized_table .. RecursiveSerialize(k) .. RecursiveSerialize(value[k])
        end
        return serialized_table
    elseif type(value) == "boolean" then
        return value and "true" or "false"
    else
        return tostring(value)
    end
end

function Purity:CreateDataSignature_Legacy(db)
    if not db then return "" end
    -- The old list (No sequenceID)
    local keysInOrder = {
        "activeChallengeID", "activeChallengeModuleType", "addonVersion",
        "challengeTitle", "completionDate", "hasBeenNotifiedOfLevelCap", "isOptedIn",
        "physicalStrikes", "playerGUID", "startDate", "status",
        "uptimeIsUnverified", "weaponInfractions", "fishingFishedItemLinks",
        "failureReason",
        "addonRuntime",
        "totalPlayedTime",
        "drunkData"
    }
    local stringToSign = ""
    for _, key in ipairs(keysInOrder) do
        local value = db[key]
        if value ~= nil then
            if key == "fishingFishedItemLinks" then
                local sortedLinks = {}
                if type(value) == "table" then
                    for link, _ in pairs(value) do 
                        table.insert(sortedLinks, tostring(link)) 
                    end
                end
                table.sort(sortedLinks)
                stringToSign = stringToSign .. table.concat(sortedLinks, "")
            else
                stringToSign = stringToSign .. RecursiveSerialize(value)
            end
        end
    end
    stringToSign = stringToSign .. trainerKey
    return self:GenerateVerificationHash(stringToSign)
end

function Purity:CreateDataSignature(db)
    if not db then return "" end
    local keysInOrder = {
        "activeChallengeID", "activeChallengeModuleType", "addonVersion",
        "challengeTitle", "completionDate", "hasBeenNotifiedOfLevelCap", "isOptedIn",
        "physicalStrikes", "playerGUID", "startDate", "status",
        "uptimeIsUnverified", "weaponInfractions", "fishingFishedItemLinks",
        "failureReason",
        "addonRuntime",
        "totalPlayedTime",
        "drunkData",
        "sequenceID"
    }
    local stringToSign = ""
    for _, key in ipairs(keysInOrder) do
        local value = db[key]
        if value ~= nil then
            if key == "fishingFishedItemLinks" then
                local sortedLinks = {}
                if type(value) == "table" then
                    for link, _ in pairs(value) do 
                        table.insert(sortedLinks, tostring(link)) 
                    end
                end
                table.sort(sortedLinks)
                stringToSign = stringToSign .. table.concat(sortedLinks, "")
            else
                stringToSign = stringToSign .. RecursiveSerialize(value)
            end
        end
    end
    stringToSign = stringToSign .. trainerKey
    return self:GenerateVerificationHash(stringToSign)
end

function Purity:GenerateWebVerificationString()
    local db = self:GetDB()
    if db.status ~= "Passed" then
        return "Challenge not completed."
    end

    local _, playerClass = UnitClass("player")
    local _, coefficient = self:GetCurrentChallengeInfo()
    local modifiers = self:GetGameplayModifiers()

    local data_parts = {
        guid = db.playerGUID,
        name = UnitName("player"),
        class = playerClass,
        status = db.status,
        challengeTitle = db.challengeTitle,
        finalUptime = string.format("%.2f", db.finalUptime or 0),
        completionDate = db.completionDate,
        addonVersion = Purity.Version,
        startDate = db.startDate,
        coefficient = string.format("%.2f", coefficient),
        isHardcore = (modifiers.isHardcore and "true" or "false"),
		isSelfFound = (modifiers.isSelfFound and "true" or "false"),
		isSSF = (modifiers.isSSF and "true" or "false")
    }

    local specifier = ""
    local activeChallenge = self:GetActiveChallengeObject()
    if activeChallenge and activeChallenge.GetChallengeSpecifier then
        specifier = activeChallenge:GetChallengeSpecifier() or ""
        data_parts.specifier = specifier
    end

    local fishedItemsPayload = ""
    if db.isOptedIn and db.activeChallengeModuleType == "Global" and db.activeChallengeID == "FISHING" then
        local fishedLinks = {}
        if type(db.fishingFishedItemLinks) == "table" then
            for link, _ in pairs(db.fishingFishedItemLinks) do 
                table.insert(fishedLinks, tostring(link)) 
            end
        end
        table.sort(fishedLinks)
        fishedItemsPayload = table.concat(fishedLinks, "")
        data_parts.fishedItems = fishedItemsPayload
    end

    local payload_array = {}
    for key, value in pairs(data_parts) do
        table.insert(payload_array, key .. "=" .. tostring(value))
    end
    local data_payload = table.concat(payload_array, ";")

    local string_to_sign = (
        data_parts.guid ..
        data_parts.status ..
        trainerKey ..
        data_parts.challengeTitle ..
        data_parts.addonVersion ..
        (data_parts.specifier or "") ..
        fishedItemsPayload ..
        data_parts.startDate
    )
    local signature = Purity:GenerateVerificationHash(string_to_sign)

    local combined_string = data_payload .. "|" .. signature
    local encoded_string = Base64.encode(combined_string)

    return encoded_string
end

function Purity:SyncSequence()
    local db = Purity:GetDB()
    if not db.isOptedIn then return end
    
    -- Increment local sequence
    db.sequenceID = (db.sequenceID or 0) + 1
    
    -- Update the Global Witness
    if not Purity_GlobalSettings.witnessData then Purity_GlobalSettings.witnessData = {} end
    
    local guid = UnitGUID("player")
    Purity_GlobalSettings.witnessData[guid] = db.sequenceID
end

function Purity:PerformIntegrityCheck()
			local db = Purity:GetDB()
			if not db.isOptedIn then return end

			local guid = UnitGUID("player")
			local globalSeq = Purity_GlobalSettings.witnessData and Purity_GlobalSettings.witnessData[guid] or 0
			local localSeq = db.sequenceID or 0

			-- If Global remembers a higher number than we have now, 
			-- it means we are loading an OLD file after a NEW file was already saved.
			if globalSeq > localSeq then
				Purity:Violation(string.format("Security Breach: Save file manipulation detected. (Seq %d < %d)", localSeq, globalSeq))
			end
			
			-- Sync them up so we don't loop-fail if they continue legitimately
			-- (Though usually, a Violation ends the run anyway)
			if globalSeq > localSeq then
			   db.sequenceID = globalSeq
			end
		end

function Purity:CreateChallengeButton(parent, challengeData)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetWidth(200)
    button:SetHeight(35)
    button:SetText(challengeData.challengeName)
    button.challengeData = challengeData
    button.id = challengeData.id

    return button
end

function Purity:Serialize(data)
    if not data then return "" end
    local parts = {}
    for key, value in pairs(data) do
        if value ~= nil then -- Changed from 'if value then' to handle false booleans
            table.insert(parts, key .. "=" .. tostring(value))
        end
    end
    return table.concat(parts, ";")
end

function Purity:Deserialize(str)
    local data = {}
    for pair in string.gmatch(str, "([^;]+)") do
        local key, value = pair:match("([^=]+)=(.*)")
        if key and value then
            if value == "true" then
                data[key] = true
            elseif value == "false" then
                data[key] = false
            elseif tonumber(value) then
                data[key] = tonumber(value)
            else
                data[key] = value
            end
        end
    end
    return data
end

function Purity:BroadcastStatus()
    if not Purity.purityChannelID then return end

    local db = self:GetDB()
    local _, classToken = UnitClass("player")
    
    local mod = Purity.GlobalModules and Purity.GlobalModules.BLOOD_MAGE_BARGAIN
    local rank = (mod and mod.GetOathbreakerRank) and mod:GetOathbreakerRank() or 0

    local myStatus = {
        challenge = db.challengeTitle,
        level = UnitLevel("player"),
        class = classToken,
        status = db.status,
        ob_rank = rank
    }
    
    local message = "STATUS_UPDATE:" .. self:Serialize(myStatus)
    C_ChatInfo.SendAddonMessage(self.ADDON_PREFIX, message, "CHANNEL", Purity.purityChannelID)
end

function Purity:SendStatusToPlayer(playerName)
    local db = self:GetDB()
    local _, classToken = UnitClass("player")
    
    local realTimeData = self:GetRawStatusData()
    local totalCoeff = self:CalculateTotalCoefficient()
    local uptimePercent = (db.totalPlayedTime > 0 and (db.addonRuntime / db.totalPlayedTime) * 100) or 0
    
    local mod = Purity.GlobalModules and Purity.GlobalModules.BLOOD_MAGE_BARGAIN
    local rank = (mod and mod.GetOathbreakerRank) and mod:GetOathbreakerRank() or 0

    local myStatus = {
        challenge = db.challengeTitle,
        status = realTimeData.status,
        level = UnitLevel("player"),
        class = classToken,
        coefficient = string.format("%.2f", totalCoeff),
        uptime = string.format("%.1f%%", uptimePercent),
        ob_rank = rank
    }
    
    if db.activeChallengeID == "BLOOD_MAGE_BARGAIN" then
        if db.bloodPoolCurrent and db.bloodPoolMax then
            myStatus.bp_curr = math.floor(db.bloodPoolCurrent)
            myStatus.bp_max = db.bloodPoolMax
        end
    end

    local message = "STATUS_UPDATE:" .. self:Serialize(myStatus)
    C_ChatInfo.SendAddonMessage(self.ADDON_PREFIX, message, "WHISPER", playerName)
end

function Purity:SendGoodbye()
    if Purity.purityChannelID then
        C_ChatInfo.SendAddonMessage(self.ADDON_PREFIX, "GOODBYE", "CHANNEL", Purity.purityChannelID)
    end
end

function Purity:UpdateRosterWindow()
    if not Purity.rosterPane or not Purity.rosterPane:IsShown() then return end

    if Purity.rosterPane.lines then
        for _, item in ipairs(Purity.rosterPane.lines) do
            item:Hide(); item:SetText("")
        end
    end
    if Purity.rosterPane.headers then
        for _, item in ipairs(Purity.rosterPane.headers) do
            item:Hide()
        end
    end

    Purity.rosterPane.lines = {}
    Purity.rosterPane.headers = {}

    local headerYOffset = -95
    local headerTextColor = "|cffffd100"
    local columnWidths = {160, 40, 90, 160, 80, 70, 70}
    local columnTitles = {"Name", "Lvl", "Class", "Challenge", "Status", "Coeff", "Uptime"}
    local lastHeader

    for i, title in ipairs(columnTitles) do
        local header = Purity.rosterPane:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        if i == 1 then
            header:SetPoint("TOPLEFT", Purity.rosterPane, "TOPLEFT", 20, headerYOffset)
        else
            header:SetPoint("LEFT", lastHeader, "RIGHT", 0, 0)
        end
        header:SetText(headerTextColor .. title .. "|r")
        header:SetWidth(columnWidths[i])
        header:SetJustifyH("LEFT")
        table.insert(Purity.rosterPane.headers, header)
        lastHeader = header
    end

    local yOffset = headerYOffset - 30
    local lineSpacing = 22
    local sortedRoster = {}
    for playerName, _ in pairs(self.roster) do
        table.insert(sortedRoster, playerName)
    end
    table.sort(sortedRoster)

    for _, playerName in ipairs(sortedRoster) do
        local data = self.roster[playerName]
        local coefficient = data.coefficient or "N/A"
        local uptime = data.uptime or "N/A"
        local level = data.level or "??"
        local challenge = data.challenge or "No Challenge"
        local status = data.status or "Unknown"
        local class = data.class or ""
        
        local shortName = string.match(tostring(playerName), "([^-]+)") or playerName
        
        -- FIX START: Don't modify the table directly. Copy values to local variables.
        local classColor = RAID_CLASS_COLORS[class] or {r=1, g=1, b=1}
        local r, g, b = classColor.r, classColor.g, classColor.b
        
        local displayClassName = class

        -- Check strictly for the BMB challenge AND Paladin class
        if challenge == "The Blood Mage's Bargain" and class == "PALADIN" then
            if data.ob_rank and data.ob_rank > 0 then
                if Purity.BLOODMAGE_CLASS_OVERRIDES and Purity.BLOODMAGE_CLASS_OVERRIDES["PALADIN"] then
                    displayClassName = Purity.BLOODMAGE_CLASS_OVERRIDES["PALADIN"].name
                    local hex = Purity.BLOODMAGE_CLASS_OVERRIDES["PALADIN"].colorHex
                    r = tonumber(hex:sub(1, 2), 16) / 255
                    g = tonumber(hex:sub(3, 4), 16) / 255
                    b = tonumber(hex:sub(5, 6), 16) / 255
                end
            end
        end

        local nameLabel = Purity.rosterPane:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        nameLabel:SetPoint("TOPLEFT", Purity.rosterPane, "TOPLEFT", 20, yOffset)
        nameLabel:SetWidth(columnWidths[1]); nameLabel:SetJustifyH("LEFT")
        nameLabel:SetText(shortName)
        nameLabel:SetTextColor(r, g, b) -- Use the local variables
        table.insert(Purity.rosterPane.lines, nameLabel)

        local levelLabel = Purity.rosterPane:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        levelLabel:SetPoint("LEFT", nameLabel, "RIGHT", 0, 0)
        levelLabel:SetWidth(columnWidths[2]); levelLabel:SetJustifyH("LEFT")
        levelLabel:SetText(level)
        table.insert(Purity.rosterPane.lines, levelLabel)

        local classLabel = Purity.rosterPane:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        classLabel:SetPoint("LEFT", levelLabel, "RIGHT", 0, 0)
        classLabel:SetWidth(columnWidths[3]); classLabel:SetJustifyH("LEFT")
        classLabel:SetText(string.upper(tostring(displayClassName))); 
        classLabel:SetTextColor(r, g, b) -- Use the local variables
        table.insert(Purity.rosterPane.lines, classLabel)

        local challengeLabel = Purity.rosterPane:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        challengeLabel:SetPoint("LEFT", classLabel, "RIGHT", 0, 0)
        challengeLabel:SetWidth(columnWidths[4]); challengeLabel:SetJustifyH("LEFT")
        challengeLabel:SetText(challenge)
        table.insert(Purity.rosterPane.lines, challengeLabel)

        local statusLabel = Purity.rosterPane:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        statusLabel:SetPoint("LEFT", challengeLabel, "RIGHT", 0, 0)
        statusLabel:SetWidth(columnWidths[5]); statusLabel:SetJustifyH("LEFT")
        statusLabel:SetText(status)
        table.insert(Purity.rosterPane.lines, statusLabel)
        
        if status == "Passing" then
            statusLabel:SetTextColor(0.1, 1.0, 0.1) -- Green
        elseif status == "Failed" then
            statusLabel:SetTextColor(1.0, 0.1, 0.1) -- Red
        elseif status == "Temporary Failure - Uptime" then
            statusLabel:SetTextColor(1.0, 1.0, 0.1) -- Yellow
        else
            statusLabel:SetTextColor(0.6, 0.6, 0.6) -- Gray for other statuses
        end
        
        local coeffLabel = Purity.rosterPane:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        coeffLabel:SetPoint("LEFT", statusLabel, "RIGHT", 0, 0)
        coeffLabel:SetWidth(columnWidths[6]); coeffLabel:SetJustifyH("LEFT")
        coeffLabel:SetText(coefficient)
        table.insert(Purity.rosterPane.lines, coeffLabel)
        
        local uptimeLabel = Purity.rosterPane:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        uptimeLabel:SetPoint("LEFT", coeffLabel, "RIGHT", 0, 0)
        uptimeLabel:SetWidth(columnWidths[7]); uptimeLabel:SetJustifyH("LEFT")
        uptimeLabel:SetText(uptime)
        table.insert(Purity.rosterPane.lines, uptimeLabel)
        
        yOffset = yOffset - lineSpacing
    end
end

function Purity:DisplayChallengeDetails(challengeData)
    if not challengeData then return end
	
	Purity.optInFrame.challengeTitle:SetText("")
	Purity.optInFrame.challengeDescription:SetText("")
	Purity.optInFrame.challengeRules:SetText("")
	Purity.optInFrame.challengeWarning:SetText("")
	Purity.optInFrame.challengeWarning:Hide()
	if Purity.optInFrame.specButtons then
		for _, button in ipairs(Purity.optInFrame.specButtons) do
			button:Hide()
		end
	end
	Purity.optInFrame.specContainer:Hide()

    Purity.selectedChallenge = challengeData

    Purity.optInFrame.scrollFrame:SetVerticalScroll(0)

    Purity.optInFrame.challengeTitle:SetText(challengeData.challengeName or "")

local descriptionText = ""
if challengeData.description then
    descriptionText = (type(challengeData.description) == "function") and challengeData.description() or challengeData.description
end

local goldColor = "|cffffd100"
local whiteColor = "|cffffffff"
local coefficientText = ""

	if challengeData.specializations then
		coefficientText = "\n\n" .. goldColor .. "Difficulty Coefficients:" .. "|r"
		for _, specData in ipairs(challengeData.specializations) do
			local challengeKey
			if challengeData.challengeName == "The Ascetic's Path" then
				if specData.id == "EASY" then challengeKey = "Path of Humility"
				elseif specData.id == "MEDIUM" then challengeKey = "Path of Resilience"
				elseif specData.id == "HARD" then challengeKey = "Path of the Unburdened" end
			else
				local specifier = specData.name
				challengeKey = string.format("%s (%s)", challengeData.challengeName, specifier:sub(1,1):upper()..specifier:sub(2):lower())
			end

			local coeff = Purity.ChallengeCoefficients[challengeKey]
			if coeff then
				coefficientText = coefficientText .. "\n- " .. specData.name .. ": " .. whiteColor .. string.format("%.2f", coeff) .. "|r"
			end
		end
	elseif Purity.ChallengeCoefficients[challengeData.challengeName] then
		local coeff = Purity.ChallengeCoefficients[challengeData.challengeName]
		coefficientText = "\n\n" .. goldColor .. "Difficulty Coefficient:|r " .. whiteColor .. string.format("%.2f", coeff) .. "|r"
	end

	Purity.optInFrame.challengeDescription:SetText(descriptionText .. coefficientText)

    local rules = challengeData.GetRulesText and challengeData:GetRulesText() or {""}
    local rulesString = table.concat(rules, "\n")
    Purity.optInFrame.challengeRules:SetText(rulesString)

    if challengeData.optInWarningText then
        Purity.optInFrame.challengeWarning:SetText(challengeData.optInWarningText)
        Purity.optInFrame.challengeWarning:Show()
    else
        Purity.optInFrame.challengeWarning:Hide()
    end

    if Purity.optInFrame.specButtons then
        for _, button in ipairs(Purity.optInFrame.specButtons) do
            button:Hide()
        end
    end
    Purity.optInFrame.specButtons = {}

    local specContainer = Purity.optInFrame.specContainer
    local totalSpecHeight = 0

    if challengeData.specializations then
        local yOffset = 0
        for _, specData in ipairs(challengeData.specializations) do
            local button = CreateFrame("Button", nil, specContainer, "UIPanelButtonTemplate")
            button:SetSize(200, 22)
            button:SetText(specData.buttonText)
            button:SetPoint("TOP", specContainer, "TOP", 0, yOffset)

            local buttonHeight = button:GetHeight() + 5
            yOffset = yOffset - buttonHeight
            totalSpecHeight = totalSpecHeight + buttonHeight

            button.specData = specData
            table.insert(Purity.optInFrame.specButtons, button)

            if Purity.tempSelectedSpec and Purity.tempSelectedSpec.name == specData.name then
                button:LockHighlight()
            end

            button:SetScript("OnClick", function(self)
                Purity.tempSelectedSpec = self.specData
                Purity:DisplayChallengeDetails(challengeData)
            end)
        end
    end

    specContainer:SetHeight(totalSpecHeight)
	if totalSpecHeight > 0 then specContainer:Show() end

    local warningFrame = Purity.optInFrame.challengeWarning
    warningFrame:ClearAllPoints()

    if totalSpecHeight > 0 then
        warningFrame:SetPoint("TOPLEFT", specContainer, "BOTTOMLEFT", 20, -15)
        warningFrame:SetPoint("TOPRIGHT", specContainer, "BOTTOMRIGHT", -20, -15)
    else
        warningFrame:SetPoint("TOPLEFT", Purity.optInFrame.challengeRules, "BOTTOMLEFT", 20, -15)
        warningFrame:SetPoint("TOPRIGHT", Purity.optInFrame.challengeRules, "BOTTOMRIGHT", -20, -15)
    end

	C_Timer.After(0.1, function()
		local scrollChild = Purity.optInFrame.scrollFrame:GetScrollChild()
		if not scrollChild then return end

		local title = Purity.optInFrame.challengeTitle
		local description = Purity.optInFrame.challengeDescription
		local rules = Purity.optInFrame.challengeRules
		local specContainer = Purity.optInFrame.specContainer
		local warning = Purity.optInFrame.challengeWarning
		local scrollFrame = Purity.optInFrame.scrollFrame
		local acceptButton = Purity.optInFrame.acceptButton

		local totalHeight = 10

		if title and title:IsShown() and title:GetText() and title:GetText() ~= "" then
			totalHeight = totalHeight + title:GetHeight() + 15
		end
		if description and description:IsShown() and description:GetText() and description:GetText() ~= "" then
			totalHeight = totalHeight + description:GetHeight() + 20
		end
		if rules and rules:IsShown() and rules:GetText() and rules:GetText() ~= "" then
			totalHeight = totalHeight + rules:GetHeight() + 15
		end
		if specContainer and specContainer:IsShown() and specContainer:GetHeight() > 0 then
			totalHeight = totalHeight + specContainer:GetHeight() + 15
		end
		if warning and warning:IsShown() and warning:GetText() and warning:GetText() ~= "" then
			totalHeight = totalHeight + warning:GetHeight() + 10
		end

		totalHeight = totalHeight + 20

		scrollChild:SetHeight(totalHeight)

		acceptButton:Disable()
		scrollFrame:SetVerticalScroll(0)

		C_Timer.After(0.01, function()
			local finalScrollRange = scrollFrame:GetVerticalScrollRange()
			if finalScrollRange < 5 then
				acceptButton:Enable()
			end
		end)
	end)
end

function Purity:selectTab(tabToShow)
    if not self.mainInterfaceFrame then self:CreateCoreUI() end

    self.rulesPane:Hide()
    self.statusPane:Hide()
    self.rosterPane:Hide()
    self.verifyPane:Hide()
    if self.rankingsPane then self.rankingsPane:Hide() end
    if self.contentFrame then self.contentFrame:Hide() end
    if self.wideContentFrame then self.wideContentFrame:Hide() end
	if self.optionsPane then self.optionsPane:Hide() end

    if tabToShow == "rankings" then
        self.wideContentFrame:Show()
        self.rankingsPane:Show()
        self:DisplayRankings()
    else
        self.contentFrame:Show()
        if tabToShow == "rules" then
            self.rulesPane:Show()
            self:DisplayRules()
        elseif tabToShow == "status" then
            self.statusPane:Show()
            self:SilentRequestTimePlayed()
            self:UpdateAndGetStatusStrings()
        elseif tabToShow == "roster" then
            self.rosterPane:Show()
            
            local db = Purity:GetDB()
            local _, classToken = UnitClass("player")
            local realTimeData = self:GetRawStatusData()
            local totalCoeff = self:CalculateTotalCoefficient()
            local uptimePercent = (db.totalPlayedTime > 0 and (db.addonRuntime / db.totalPlayedTime) * 100) or 0
            local playerName = UnitName("player") .. "-" .. GetRealmName()

            local mod = Purity.GlobalModules and Purity.GlobalModules.BLOOD_MAGE_BARGAIN
            local rank = (mod and mod.GetOathbreakerRank) and mod:GetOathbreakerRank() or 0

            Purity.roster[playerName] = {
                challenge = db.challengeTitle or "N/A",
                level = UnitLevel("player"),
                class = classToken,
                status = realTimeData.status,
                coefficient = string.format("%.2f", totalCoeff),
                uptime = string.format("%.1f%%", uptimePercent),
                ob_rank = rank, -- Included rank here
                lastSeen = GetTime() 
            }
            
            -- *** FIX PART 2: Restore the missing channel check ***
            local foundID
            local returned_id_as_string, _ = GetChannelName("PurityUsers")
            local numericID = tonumber(returned_id_as_string)
            if numericID and numericID > 0 then
                foundID = numericID
            end

            if foundID then
                Purity.purityChannelID = foundID
                SendChatMessage("!purity_ping", "CHANNEL", nil, foundID)
			else
            end
            
            self:UpdateRosterWindow() -- <-- THIS IS THE CORRECTED LINE
        elseif tabToShow == "verify" then
            self.verifyPane:Show()
            local db = Purity:GetDB()
            if db.status == "Passed" then
                self.verifyPane.editBox:SetText(self:GenerateWebVerificationString())
                self.verifyPane.editBox:HighlightText()
            else
                self.verifyPane.editBox:SetText("You must complete a challenge to generate a verification string.")
            end
    
            if not self.verifyPane.websiteText then
                self.verifyPane.websiteText = self.verifyPane:CreateFontString(nil, "ARTWORK", "GameFontNormal")
                self.verifyPane.websiteText:SetPoint("TOP", self.verifyPane.editBox, "BOTTOM", 0, -10)
                self.verifyPane.websiteText:SetJustifyH("CENTER")
                self.verifyPane.websiteText:SetWidth(400)
            end
            self.verifyPane.websiteText:SetText("Verify at: |cff00FFFFhttps://purity.pythonanywhere.com/|r")
            self.verifyPane.websiteText:Show()
		elseif tabToShow == "options" then
            self.optionsPane:Show()
            self:BuildOptionsMenu()
        end
    end
end

function Purity:BuildOptionsMenu()
    if not self.optionsPane then return end

    -- 1. INITIALIZATION: Create widgets only once
    if not self.optionsPane.isInitialized then
        self.optionsPane.widgets = {}
        
        -- Title
        local title = self.optionsPane:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", self.optionsPane, "TOP", 0, -15)
        title:SetTextColor(1, 0.82, 0)
        title:SetText("Purity Options")
        self.optionsPane.title = title

        -- [Minimap Checkbox]
        local minimapCheck = CreateFrame("CheckButton", "PurityMinimapIconCheck", self.optionsPane, "UICheckButtonTemplate")
        local mmText = _G[minimapCheck:GetName() .. "Text"]
        if mmText then
            mmText:SetText("Show Minimap Button")
            mmText:SetTextColor(1, 0.82, 0)
            mmText:SetFontObject(GameFontNormalSmall)
            mmText:ClearAllPoints()
            mmText:SetPoint("LEFT", minimapCheck, "RIGHT", 2, 0)
        end
        minimapCheck:SetScript("OnClick", function(btn)
            Purity_GlobalSettings.showMinimapIcon = btn:GetChecked()
            Purity:UpdateMinimapIconVisibility()
        end)
        self.optionsPane.widgets.minimap = minimapCheck
		
		-- [Member Alerts Checkbox]
        local alertCheck = CreateFrame("CheckButton", "PurityMemberAlertCheck", self.optionsPane, "UICheckButtonTemplate")
        local alText = _G[alertCheck:GetName() .. "Text"]
        if alText then
            alText:SetText("Show Member Login/Logout Alerts")
            alText:SetTextColor(1, 0.82, 0)
            alText:SetFontObject(GameFontNormalSmall)
            alText:ClearAllPoints()
            alText:SetPoint("LEFT", alertCheck, "RIGHT", 2, 0)
        end
        alertCheck:SetScript("OnClick", function(btn)
            Purity_GlobalSettings.showMemberAlerts = btn:GetChecked()
        end)
        self.optionsPane.widgets.alerts = alertCheck

        -- [Blood Mage: Bar Mode]
        local bloodBarCheck = CreateFrame("CheckButton", "PurityBloodBarModeCheck", self.optionsPane, "UICheckButtonTemplate")
        local bbText = _G[bloodBarCheck:GetName() .. "Text"]
        if bbText then
            bbText:SetText("Separate Blood Bar Frame")
            bbText:SetFontObject(GameFontNormalSmall)
            bbText:ClearAllPoints()
            bbText:SetPoint("LEFT", bloodBarCheck, "RIGHT", 2, 0)
        end
        bloodBarCheck:SetScript("OnClick", function(btn)
            local newState = btn:GetChecked()
            local status = newState and "Separate" or "Overlay"
            print("|cffFFFF00Purity:|r Blood Bar mode set to: |cff00FF00" .. status .. "|r")
            if Purity.GlobalModules.BLOOD_MAGE_BARGAIN and Purity.GlobalModules.BLOOD_MAGE_BARGAIN.ApplyBarMode then
                Purity.GlobalModules.BLOOD_MAGE_BARGAIN:ApplyBarMode(newState, true)
            end
        end)
        self.optionsPane.widgets.bloodBar = bloodBarCheck

        -- [Blood Mage: Log]
        local bloodLogCheck = CreateFrame("CheckButton", "PurityBloodLogVisibleCheck", self.optionsPane, "UICheckButtonTemplate")
        local blText = _G[bloodLogCheck:GetName() .. "Text"]
        if blText then
            blText:SetText("Show Blood Log")
            blText:SetFontObject(GameFontNormalSmall)
            blText:ClearAllPoints()
            blText:SetPoint("LEFT", bloodLogCheck, "RIGHT", 2, 0)
            blText:SetTextColor(1, 0.82, 0)
        end
        bloodLogCheck:SetScript("OnClick", function(btn)
            local makeVisible = btn:GetChecked()
            local db = Purity:GetDB()
            db.bloodLogVisible = makeVisible
            local mod = Purity.GlobalModules.BLOOD_MAGE_BARGAIN
            if mod then
                if not mod.bloodLogFrame then mod:CreateBloodLogFrame() end
                if mod.bloodLogFrame then
                    if makeVisible then mod.bloodLogFrame:Show() else mod.bloodLogFrame:Hide() end
                end
            end
        end)
        self.optionsPane.widgets.bloodLog = bloodLogCheck
		
		-- [Glass Heart: Log]
        local glassLogCheck = CreateFrame("CheckButton", "PurityGlassLogVisibleCheck", self.optionsPane, "UICheckButtonTemplate")
        local glText = _G[glassLogCheck:GetName() .. "Text"]
        if glText then
            glText:SetText("Show Glass Heart Damage Log")
            glText:SetFontObject(GameFontNormalSmall)
            glText:ClearAllPoints()
            glText:SetPoint("LEFT", glassLogCheck, "RIGHT", 2, 0)
            glText:SetTextColor(1, 0.82, 0)
        end
        glassLogCheck:SetScript("OnClick", function(btn)
            local mod = Purity.GlobalModules["GLASS_HEART"]
            if mod then
                mod:ToggleLog()
            end
        end)
        self.optionsPane.widgets.glassLog = glassLogCheck
		
		-- [Glass Heart: Custom FCT]
        local glassFCTCheck = CreateFrame("CheckButton", "PurityGlassFCTCheck", self.optionsPane, "UICheckButtonTemplate")
        local gfText = _G[glassFCTCheck:GetName() .. "Text"]
        if gfText then
            gfText:SetText("Enable Glass Heart Floating Combat Text Values")
            gfText:SetFontObject(GameFontNormalSmall)
            gfText:ClearAllPoints()
            gfText:SetPoint("LEFT", glassFCTCheck, "RIGHT", 2, 0)
            gfText:SetTextColor(1, 0.82, 0)
        end
        glassFCTCheck:SetScript("OnClick", function(btn)
            local isChecked = btn:GetChecked()
            local db = Purity:GetDB()
            db.glassHeartFCTEnabled = isChecked
            
            if db.activeChallengeID == "GLASS_HEART" then
                if isChecked then
                    Purity:DisableDefaultIncomingDamageText()
                else
                    Purity:RestoreDefaultIncomingDamageText()
                end
            end
        end)
        self.optionsPane.widgets.glassFCT = glassFCTCheck

        -- [Druid: Astrolabe]
        local astrolabeCheck = CreateFrame("CheckButton", "PurityAstrolabeNumbersCheck", self.optionsPane, "UICheckButtonTemplate")
        local asText = _G[astrolabeCheck:GetName() .. "Text"]
        if asText then
            asText:SetText("Show Astrolabe Numbers (X/2)")
            asText:SetFontObject(GameFontNormalSmall)
            asText:ClearAllPoints()
            asText:SetPoint("LEFT", astrolabeCheck, "RIGHT", 2, 0)
            asText:SetTextColor(1, 0.82, 0)
        end
        astrolabeCheck:SetScript("OnClick", function(btn)
            local isChecked = btn:GetChecked()
            local db = Purity:GetDB()
            db.showAstrolabeNumbers = isChecked
            if Purity.ClassModules and Purity.ClassModules.DRUID and Purity.ClassModules.DRUID.challenges.astrolabe then
                Purity.ClassModules.DRUID.challenges.astrolabe:UpdateBalanceFrame()
            end
        end)
        self.optionsPane.widgets.astrolabe = astrolabeCheck

        -- [Mage: Conduit Bar]
        local mageBarCheck = CreateFrame("CheckButton", "PurityMageBarDetachCheck", self.optionsPane, "UICheckButtonTemplate")
        local mbText = _G[mageBarCheck:GetName() .. "Text"]
        if mbText then
            mbText:SetText("Detach & Unlock Charge Bar")
            mbText:SetFontObject(GameFontNormalSmall)
            mbText:ClearAllPoints()
            mbText:SetPoint("LEFT", mageBarCheck, "RIGHT", 2, 0)
            mbText:SetTextColor(1, 0.82, 0)
        end
        mageBarCheck:SetScript("OnClick", function(btn)
            local isChecked = btn:GetChecked()
            local db = Purity:GetDB()
            db.mageBarDetached = isChecked
            if Purity.ClassModules.MAGE and Purity.ClassModules.MAGE.challenges.conduit then
                Purity.ClassModules.MAGE.challenges.conduit:ApplyBarMode(isChecked)
            end
        end)
        self.optionsPane.widgets.mageBar = mageBarCheck

        -- [Drunken Master Window]
        local drunkCheck = CreateFrame("CheckButton", "PurityDrunkWindowCheck", self.optionsPane, "UICheckButtonTemplate")
        local drText = _G[drunkCheck:GetName() .. "Text"]
        if drText then
            drText:SetText("Show Drunken Master Status Window")
            drText:SetFontObject(GameFontNormalSmall)
            drText:ClearAllPoints()
            drText:SetPoint("LEFT", drunkCheck, "RIGHT", 2, 0)
            drText:SetTextColor(1, 0.82, 0)
        end
        drunkCheck:SetScript("OnClick", function(btn)
            if Purity.GlobalModules.DRUNK and Purity.GlobalModules.DRUNK.ToggleStatusFrame then
                Purity.GlobalModules.DRUNK:ToggleStatusFrame()
            end
        end)
        self.optionsPane.widgets.drunk = drunkCheck

        self.optionsPane.isInitialized = true
    end

    -- 2. UPDATE: Refresh visibility and state based on current challenge
    local db = Purity:GetDB()
    local globalSettings = Purity_GlobalSettings
    local yOffset = -40
    local xOffset = 50

    -- Helper to place widgets dynamically
    local function PlaceWidget(widget)
        widget:ClearAllPoints()
        widget:SetPoint("TOPLEFT", self.optionsPane, "TOPLEFT", xOffset, yOffset)
        widget:Show()
        yOffset = yOffset - 30
    end

    -- Hide everything first to ensure clean state
    for _, widget in pairs(self.optionsPane.widgets) do
        widget:Hide()
    end

    -- [Always Visible Options]
    local minBtn = self.optionsPane.widgets.minimap
    minBtn:SetChecked(globalSettings.showMinimapIcon == nil or globalSettings.showMinimapIcon)
    PlaceWidget(minBtn)
	
	local alBtn = self.optionsPane.widgets.alerts
    alBtn:SetChecked(globalSettings.showMemberAlerts == true)
    PlaceWidget(alBtn)

    -- [Context-Sensitive Options]
    local id = db.activeChallengeID

    -- Blood Mage
    if id == "BLOOD_MAGE_BARGAIN" then
        local bbBtn = self.optionsPane.widgets.bloodBar
        bbBtn:SetChecked(db.bloodBarIsSeparate or false)
        PlaceWidget(bbBtn)

        local blBtn = self.optionsPane.widgets.bloodLog
        blBtn:SetChecked(db.bloodLogVisible or false)
        PlaceWidget(blBtn)
    end
	
	-- Glass Heart
    if id == "GLASS_HEART" then
        local glBtn = self.optionsPane.widgets.glassLog
        glBtn:SetChecked(db.glassLogVisible or false)
        PlaceWidget(glBtn)
        
        local gfBtn = self.optionsPane.widgets.glassFCT
        gfBtn:SetChecked(db.glassHeartFCTEnabled ~= false) 
        PlaceWidget(gfBtn)
    end

    -- Druid: Astrolabe
    if id == "Astrolabe of Purity" then
        local asBtn = self.optionsPane.widgets.astrolabe
        asBtn:SetChecked(db.showAstrolabeNumbers ~= false)
        PlaceWidget(asBtn)
    end

    -- Mage: Conduit
    if id == "Conduit of Purity" then
        local mbBtn = self.optionsPane.widgets.mageBar
        mbBtn:SetChecked(db.mageBarDetached == true)
        PlaceWidget(mbBtn)
    end

    -- Drunken Master
    -- FIX: Check specifically for the Drunk ID (usually "DRUNK")
    if id == "DRUNK" then
        local drBtn = self.optionsPane.widgets.drunk
        local isVisible = false
        if DrunkenMasterStatusFrame and DrunkenMasterStatusFrame:IsShown() then isVisible = true end
        drBtn:SetChecked(isVisible)
        PlaceWidget(drBtn)
    end
end

function Purity:UpdateMinimapIconVisibility()
    local showIcon = Purity_GlobalSettings.showMinimapIcon == nil or Purity_GlobalSettings.showMinimapIcon
    local LDBIcon = LibStub:GetLibrary("LibDBIcon-1.0", true)

    if LDBIcon then
        if showIcon then
            LDBIcon:Show("Purity")
        else
            LDBIcon:Hide("Purity")
        end
    elseif Purity.minimapIcon then
        if showIcon then
            Purity.minimapIcon:Show()
        else
            Purity.minimapIcon:Hide()
        end
    end
end

function Purity.CreateCoreUI()
    if Purity.hasUIBeenCreated then return end
    Purity.hasUIBeenCreated = true
	
    local LDB = LibStub:GetLibrary("LibDataBroker-1.1", true)
    local LDBIcon = LibStub:GetLibrary("LibDBIcon-1.0", true)
    local showIcon = Purity_GlobalSettings.showMinimapIcon == nil or Purity_GlobalSettings.showMinimapIcon -- Read setting first

    local ICON_PATH = "Interface\\AddOns\\Purity\\Media\\PurityLogoShort.tga"

    if LDB and LDBIcon then
        local ldbObject = LDB:NewDataObject("Purity", {
            type = "launcher",
            label = "Purity",
            icon = ICON_PATH,
            OnClick = function(self, button) Purity_TogglePanel() end,
            OnTooltipShow = function(tooltip)
                if not tooltip or not tooltip.AddLine then return end
                tooltip:AddLine("Purity")
                tooltip:AddLine("Click to open the Purity menu.")
            end
        })

        if not Purity_MinimapIconDB then Purity_MinimapIconDB = {} end
        LDBIcon:Register("Purity", ldbObject, Purity_MinimapIconDB)

        if not showIcon then
            LDBIcon:Hide("Purity")
        else
             LDBIcon:Show("Purity")
        end

    elseif showIcon then
        local iconFrame = CreateFrame("Button", "PurityMinimapButton", Minimap)
        iconFrame:SetSize(32, 32)
        iconFrame:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -30, -10)
        iconFrame:SetFrameStrata("MEDIUM")

        local iconTexture = iconFrame:CreateTexture(nil, "ARTWORK")
        iconTexture:SetTexture(ICON_PATH)
        iconTexture:SetSize(28, 28)
        iconTexture:SetPoint("CENTER")

        local mask = iconFrame:CreateMaskTexture()
        mask:SetTexture("Interface\\CharacterFrame\\TempFrame-Mask")
        mask:SetAllPoints(iconTexture)
        iconTexture:AddMaskTexture(mask)

        local overlay = iconFrame:CreateTexture(nil, "OVERLAY")
        overlay:SetTexture("Interface\\Minimap\\Minimap-TrackingBorder")
        overlay:SetAllPoints()

        iconFrame:SetScript("OnClick", Purity_TogglePanel)
        iconFrame:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_LEFT"); GameTooltip:SetText("Purity")
            GameTooltip:AddLine("Click to open the Purity menu.")
            GameTooltip:AddLine("|cffb0b0b0(Drag to move)|r"); GameTooltip:Show()
        end)
        iconFrame:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
        iconFrame:RegisterForDrag("LeftButton")
        iconFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
        iconFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
        Purity.minimapIcon = iconFrame
    else
        if Purity.minimapIcon then
             Purity.minimapIcon:Hide()
        end
    end

    if not Purity.TooltipOverlay then
        Purity.TooltipOverlay = GameTooltip:CreateFontString("PurityTooltipOverlay", "OVERLAY", "GameFontNormal")
        Purity.TooltipOverlay:Hide()
    end
	
    Purity.notificationBanner = CreateFrame("Frame", "Purity_NotificationBanner", UIParent)
    Purity.notificationBanner:SetSize(600, 96)
    Purity.notificationBanner:SetPoint("TOP", 0, -100)
    Purity.notificationBanner:SetFrameStrata("HIGH")
    Purity.notificationBanner:Hide()

    local leftCap = Purity.notificationBanner:CreateTexture(nil, "BACKGROUND")
    leftCap:SetSize(20, 96)
    leftCap:SetPoint("LEFT", Purity.notificationBanner, "LEFT", 0, 0)
    leftCap:SetTexture("Interface\\AddOns\\Purity\\Media\\Banner-Left.tga")
    Purity.notificationBanner.leftCap = leftCap

    local rightCap = Purity.notificationBanner:CreateTexture(nil, "BACKGROUND")
    rightCap:SetSize(20, 96)
    rightCap:SetPoint("RIGHT", Purity.notificationBanner, "RIGHT", 0, 0)
    rightCap:SetTexture("Interface\\AddOns\\Purity\\Media\\Banner-Right.tga")
    Purity.notificationBanner.rightCap = rightCap
    
    local middleBar = Purity.notificationBanner:CreateTexture(nil, "BACKGROUND", nil, -1)
    middleBar:SetPoint("TOPLEFT", leftCap, "TOPRIGHT")
    middleBar:SetPoint("BOTTOMRIGHT", rightCap, "BOTTOMLEFT")
    middleBar:SetTexture("Interface\\AddOns\\Purity\\Media\\Banner-Middle.tga")
    Purity.notificationBanner.middleBar = middleBar

    local crest = Purity.notificationBanner:CreateTexture(nil, "ARTWORK")
    crest:SetSize(100, 100)
    crest:SetPoint("TOP", Purity.notificationBanner, "BOTTOM", 0, 25)
    crest:SetTexture("Interface\\AddOns\\Purity\\Media\\Banner-Crest.tga")

    local title = Purity.notificationBanner:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOP", 0, -15)
    Purity.notificationBanner.title = title

    Purity.notificationBanner.text = Purity.notificationBanner:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    Purity.notificationBanner.text:SetPoint("TOP", title, "BOTTOM", 0, -8)
    Purity.notificationBanner.text:SetWidth(500)
    Purity.notificationBanner.text:SetJustifyH("CENTER")
    Purity.notificationBanner.text:SetJustifyV("TOP")
    Purity.notificationBanner.text:SetTextColor(0.15, 0.1, 0.05)
	
	local bannerCloseButton = CreateFrame("Button", nil, Purity.notificationBanner, "UIPanelCloseButton")
    bannerCloseButton:SetSize(32, 32)
    bannerCloseButton:SetPoint("TOPRIGHT", Purity.notificationBanner, "TOPRIGHT", -5, -5)
    bannerCloseButton:SetScript("OnClick", function()
        Purity.notificationBanner:Hide()
    end)
    
    Purity.weaponWarningFrame = CreateFrame("Frame", "Purity_WeaponWarningFrame", UIParent)
    Purity.weaponWarningFrame:SetSize(380, 120)
    Purity.weaponWarningFrame:SetPoint("CENTER", 0, 150)
    Purity:CreateBackground(Purity.weaponWarningFrame, 0.2, 0.1, 0)
    local title2 = Purity.weaponWarningFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title2:SetPoint("TOP", 0, -18)
    title2:SetText("Purity AddOn Challenge")
    title2:SetTextColor(1, 0.5, 0)
    Purity.weaponWarningFrame.text = Purity.weaponWarningFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    Purity.weaponWarningFrame.text:SetPoint("CENTER", 0, -5)
    Purity.weaponWarningFrame.text:SetSize(360, 80)
    Purity.weaponWarningFrame:Hide()

    Purity.optInFrame = CreateFrame("Frame", "Purity_OptInFrame", UIParent)
    Purity.optInFrame:SetSize(750, 600)
    Purity.optInFrame:SetPoint("CENTER")
    Purity:ApplyCustomArt(Purity.optInFrame)
    Purity.optInFrame:EnableMouse(true)
    Purity.optInFrame:SetMovable(true)
    Purity.optInFrame:RegisterForDrag("LeftButton")
    Purity.optInFrame:SetScript("OnDragStart", Purity.optInFrame.StartMoving)
    Purity.optInFrame:SetScript("OnDragStop", Purity.optInFrame.StopMovingOrSizing)

    local topTitle = Purity.optInFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    topTitle:SetPoint("TOP", 0, -30)
    topTitle:SetText("Choose Your Vow of Purity")
    topTitle:SetTextColor(1, 0.82, 0)

    Purity.optInFrame.leftPane = CreateFrame("Frame", nil, Purity.optInFrame)
    Purity.optInFrame.leftPane:SetSize(220, 400)
    Purity.optInFrame.leftPane:SetPoint("TOPLEFT", 70, -85)

    local separator = Purity.optInFrame:CreateTexture(nil, "ARTWORK")
    separator:SetSize(20, 430)
    separator:SetPoint("TOPLEFT", Purity.optInFrame.leftPane, "TOPRIGHT", 15, 0)
    separator:SetTexture("Interface\\AddOns\\Purity\\Media\\VerticalSeparator.tga")

	local rightPaneContainer = CreateFrame("Frame", nil, Purity.optInFrame)
	rightPaneContainer:SetSize(350, 400)
	rightPaneContainer:SetPoint("TOPLEFT", separator, "TOPRIGHT", 15, 0)
	Purity.optInFrame.rightPane = rightPaneContainer

    local scrollFrame = CreateFrame("ScrollFrame", "PurityOptInScrollFrame", rightPaneContainer, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT")
	scrollFrame:SetPoint("TOPRIGHT", -30, 0)
    Purity.optInFrame.scrollFrame = scrollFrame

    local scrollChild = CreateFrame("Frame")
    scrollChild:SetWidth(rightPaneContainer:GetWidth() - 20)
    Purity.optInFrame.scrollChild = scrollChild

    scrollFrame:SetScrollChild(scrollChild)

	scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
		if originalOnVerticalScroll then
			originalOnVerticalScroll(self, offset)
		end

		local currentScroll = self:GetVerticalScroll()
		local maxScroll = self:GetVerticalScrollRange()

		if maxScroll > 0 and (maxScroll - currentScroll) < 1 then
			Purity.optInFrame.acceptButton:Enable()
		end
	end)

	Purity.optInFrame.challengeTitle = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	Purity.optInFrame.challengeTitle:SetPoint("TOPLEFT", 10, -10)
	Purity.optInFrame.challengeTitle:SetPoint("TOPRIGHT", -10, -10)
	Purity.optInFrame.challengeTitle:SetTextColor(1, 0.82, 0)

	Purity.optInFrame.challengeDescription = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	Purity.optInFrame.challengeDescription:SetPoint("TOPLEFT", Purity.optInFrame.challengeTitle, "BOTTOMLEFT", 0, -15)
	Purity.optInFrame.challengeDescription:SetPoint("TOPRIGHT", Purity.optInFrame.challengeTitle, "BOTTOMRIGHT", 0, -15)
	Purity.optInFrame.challengeDescription:SetJustifyH("LEFT")
	Purity.optInFrame.challengeDescription:SetTextColor(1, 0.82, 0)

	Purity.optInFrame.challengeRules = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	Purity.optInFrame.challengeRules:SetPoint("TOPLEFT", Purity.optInFrame.challengeDescription, "BOTTOMLEFT", 0, -20)
	Purity.optInFrame.challengeRules:SetPoint("TOPRIGHT", Purity.optInFrame.challengeDescription, "BOTTOMRIGHT", 0, -20)
	Purity.optInFrame.challengeRules:SetJustifyH("LEFT")
	Purity.optInFrame.challengeRules:SetTextColor(1, 1, 1)

	Purity.optInFrame.specContainer = CreateFrame("Frame", nil, scrollChild)
	Purity.optInFrame.specContainer:SetPoint("TOPLEFT", Purity.optInFrame.challengeRules, "BOTTOMLEFT", 0, -15)
	Purity.optInFrame.specContainer:SetPoint("RIGHT", scrollChild, "RIGHT")

	Purity.optInFrame.challengeWarning = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	Purity.optInFrame.challengeWarning:SetPoint("TOPLEFT", Purity.optInFrame.specContainer, "BOTTOMLEFT", 20, -15)
	Purity.optInFrame.challengeWarning:SetPoint("TOPRIGHT", Purity.optInFrame.specContainer, "BOTTOMRIGHT", -20, -15)
	Purity.optInFrame.challengeWarning:SetJustifyH("LEFT")
	Purity.optInFrame.challengeWarning:Hide()

    local acceptButton = CreateFrame("Button", "Purity_AcceptButton", Purity.optInFrame, "UIPanelButtonTemplate")
    acceptButton:SetSize(120, 30)
    acceptButton:SetText("Accept Challenge")
    acceptButton:SetPoint("BOTTOMRIGHT", Purity.optInFrame.rightPane, "BOTTOM", -7.5, -20)
    Purity.optInFrame.acceptButton = acceptButton
    
    acceptButton:Disable()

    local declineButton = CreateFrame("Button", "Purity_DeclineButton", Purity.optInFrame, "UIPanelButtonTemplate")
    declineButton:SetSize(120, 30)
    declineButton:SetText("Decline")
    declineButton:SetPoint("LEFT", acceptButton, "RIGHT", 15, 0)
    Purity.optInFrame.declineButton = declineButton
    declineButton:SetScript("OnClick", function()
        Purity.optInFrame:Hide()
        local db = Purity:GetDB()
        db.hasBeenNotifiedOfLevelCap = true
        print("|cffFFFF00Purity:|r Challenge declined. You can continue playing normally. The main window can be opened with /purity.")
    end)
	
    acceptButton:SetScript("OnClick", function()
        if not Purity.selectedChallenge or not Purity.selectedChallenge.challengeName then
            print("|cffFFFF00Purity:|r Please select a challenge from the list on the left to review its rules before accepting.")
            return
        end

        if not Purity.optInFrame.checkbox:GetChecked() then
            print("|cffFFFF00Purity:|r |cffFF0000You must agree to the terms by checking the box before accepting the challenge.|r")
            return
        end

        local challengeData = Purity.selectedChallenge

        if challengeData.IsItemForbidden then
            local inventorySlots = {
                INVSLOT_HEAD, INVSLOT_NECK, INVSLOT_SHOULDER, INVSLOT_BODY, 
                INVSLOT_CHEST, INVSLOT_WAIST, INVSLOT_LEGS, INVSLOT_FEET,
                INVSLOT_WRIST, INVSLOT_HAND, INVSLOT_FINGER1, INVSLOT_FINGER2,
                INVSLOT_TRINKET1, INVSLOT_TRINKET2, INVSLOT_BACK, INVSLOT_MAINHAND,
                INVSLOT_OFFHAND, INVSLOT_RANGED, INVSLOT_TABARD
            }
            for _, slotId in ipairs(inventorySlots) do
                local itemLink = GetInventoryItemLink("player", slotId)
                if itemLink and challengeData:IsItemForbidden(itemLink) then
                    local itemName = GetItemInfo(itemLink)
                    print("|cffFFFF00Purity:|r |cffFF0000Cannot accept! You must unequip all starting gear first. Please remove: " .. (itemName or "Unknown Item") .. "|r")
                    return
                end
            end
        end
		
		local db = Purity:GetDB()
        
        -- Save Main Challenge
        db.challengeTitle = Purity.selectedChallenge.challengeName
        db.activeChallengeID = Purity.selectedChallenge.id
        
        -- NEW: Save DK Destiny (Only if MoP and selected)
        if isMoP and Purity.selectedDKPath then
            db.dkDestinyID = Purity.selectedDKPath.challengeName
            -- You might want to save the ID instead of the name depending on your preference
        end
        
        db.isOptedIn = true
        db.status = "Passing"
        db.startDate = date("%Y-%m-%d %H:%M:%S")
        db.playerGUID = UnitGUID("player")
        db.challengeTitle = challengeData.challengeName 
        if challengeData.SaveData then challengeData:SaveData() end
        db.addonVersion = Purity.Version
		db.isAwaitingInitialUptimeSync = true
		Purity:SilentRequestTimePlayed()


        local challengeKey = challengeData.challengeName
        local isGlobal = false
        if Purity.GlobalModules then
            for key, module in pairs(Purity.GlobalModules) do
                if module == challengeData then
                    isGlobal = true
                    challengeKey = key
                    break
                end
            end
        end
    
        db.activeChallengeID = challengeKey
        db.activeChallengeModuleType = isGlobal and "Global" or "Class"

		db.dataSignature = Purity:CreateDataSignature(db, "Passing", db.playerGUID)
    
        Purity.optInFrame:Hide()
		Purity:SyncSecureStateFromDB()
        Purity:ActivateMonitoring()
		local activeChallenge = Purity:GetActiveChallengeObject()
		if activeChallenge and activeChallenge.ApplyThematicClassRename then
			activeChallenge:ApplyThematicClassRename()
		end
		local newlyAcceptedChallenge = Purity:GetActiveChallengeObject()
		if newlyAcceptedChallenge and newlyAcceptedChallenge.InitializeOnPlayerEnterWorld then
			newlyAcceptedChallenge:InitializeOnPlayerEnterWorld()
		end
        print("|cffFFFF00Purity:|r |cff00FF00The '" .. db.challengeTitle .. "' challenge has been accepted! Good luck!|r")

        Purity:BroadcastStatus()
		
        local activeChallenge = Purity:GetActiveChallengeObject()
        if activeChallenge and activeChallenge.EventHandler then
            activeChallenge:EventHandler("PLAYER_EQUIPMENT_CHANGED")
        end

        if GameTooltip:IsShown() and GameTooltip:GetUnit() == "mouseover" then
            GameTooltip:Hide()
            GameTooltip:SetUnit("mouseover")
            GameTooltip:Show()
        end
	end)

    local checkbox = CreateFrame("CheckButton", "Purity_OptInCheckbox", Purity.optInFrame, "UICheckButtonTemplate")
    checkbox:SetPoint("BOTTOM", Purity.optInFrame.rightPane, "BOTTOM", -135, 5)
    Purity.optInFrame.checkbox = checkbox
	Purity.optInFrame.scrollFrame:SetPoint("BOTTOM", checkbox, "TOP", 0, 15)

    local checkboxText = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    checkboxText:SetPoint("LEFT", checkbox, "RIGHT", 0, 0)
    checkboxText:SetText("I agree to the terms of the selected challenge.")
    checkboxText:SetTextColor(1, 0.82, 0)
    Purity.optInFrame.checkboxText = checkboxText

    Purity.optInFrame:SetScript("OnShow", function(frame)
		-- ============================================================
		-- LOGIC BRANCH: MISTS OF PANDARIA (Dual Selection)
		-- ============================================================
		if isMoP then
			Purity:DisplayChallengeDetails({
				challengeName = "Welcome to the Path of Purity (MoP)",
				description = function() return "Choose your Vow and your Destiny." end,
				GetRulesText = function() 
					return {
						"|cffffd100Instruction:|r Select a Vow (Standard) and optionally a Destiny (Death Knight).",
						"Your score will be the average of the two challenges."
					} 
				end
			})

			-- clear previous widgets
			if frame.challengeWidgets then 
				for _, w in ipairs(frame.challengeWidgets) do w:Hide() end 
			end
			frame.challengeWidgets = {}
			frame.vowCheckboxes = {}
			frame.dkPathCheckboxes = {}

			local yOffset = -20
			local leftPane = frame.leftPane

			-- 1. Load Standard Vows
			local availableVows = {}
			-- [Load Global Modules]
			if Purity.GlobalModules then
				for _, data in pairs(Purity.GlobalModules) do table.insert(availableVows, data) end
			end
			-- [Load Class Modules]
			local _, class = UnitClass("player")
			if Purity.ClassModules[class] then
				for _, data in pairs(Purity.ClassModules[class].challenges) do table.insert(availableVows, data) end
			end

			-- 2. Load DK Destinies (Dynamically from Purity_DK.lua)
			local availableDKPaths = {}
			if Purity.ClassModules["DEATHKNIGHT"] then
				for _, data in ipairs(Purity.ClassModules["DEATHKNIGHT"].challenges) do
					-- Filter: Special Warlock check
					if data.id == "DK_PHYLACTERY" then
						if class == "WARLOCK" then table.insert(availableDKPaths, data) end
					else
						table.insert(availableDKPaths, data)
					end
				end
			end

			-- 3. Render Checkboxes for VOWS (Primary Challenge)
            local vowHeader = frame.leftPane:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            vowHeader:SetPoint("TOPLEFT", frame.leftPane, "TOPLEFT", 10, yOffset)
            vowHeader:SetText("|cffffd100Vows|r")
            yOffset = yOffset - 25

            for i, data in ipairs(availableVows) do
                local check = CreateFrame("CheckButton", nil, frame.leftPane, "UICheckButtonTemplate")
                check:SetSize(24, 24)
                check:SetPoint("TOPLEFT", frame.leftPane, "TOPLEFT", 15, yOffset)
                
                check.text = check:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                check.text:SetPoint("LEFT", check, "RIGHT", 5, 0)
                check.text:SetText(data.challengeName)
                
                check:SetScript("OnClick", function(self)
                    -- Radio Button Behavior: Uncheck all other Vows
                    for _, other in ipairs(frame.vowCheckboxes) do
                        if other ~= self then other:SetChecked(false) end
                    end
                    self:SetChecked(true) -- Force checked (cannot uncheck a Vow, must switch)
                    
                    Purity.selectedChallenge = data
                    Purity:DisplayChallengeDetails(data)
                end)

                table.insert(frame.vowCheckboxes, check)
                table.insert(frame.challengeWidgets, check) -- track for cleanup
                yOffset = yOffset - 30
            end

            yOffset = yOffset - 15

            -- 4. Render Checkboxes for DESTINIES (Optional DK Paths)
            if #availableDKPaths > 0 then
                local dkHeader = frame.leftPane:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
                dkHeader:SetPoint("TOPLEFT", frame.leftPane, "TOPLEFT", 10, yOffset)
                dkHeader:SetText("|cffffd100Destinies|r")
                table.insert(frame.challengeWidgets, dkHeader)
                yOffset = yOffset - 25

                for i, data in ipairs(availableDKPaths) do
                    local check = CreateFrame("CheckButton", nil, frame.leftPane, "UICheckButtonTemplate")
                    check:SetSize(24, 24)
                    check:SetPoint("TOPLEFT", frame.leftPane, "TOPLEFT", 15, yOffset)
                    
                    check.text = check:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    check.text:SetPoint("LEFT", check, "RIGHT", 5, 0)
                    check.text:SetText(data.challengeName)
                    
                    check:SetScript("OnClick", function(self)
                        local isChecked = self:GetChecked()
                        -- Radio Behavior: Uncheck all other Destinies
                        for _, other in ipairs(frame.dkPathCheckboxes) do
                            if other ~= self then other:SetChecked(false) end
                        end
                        -- Allow toggling off (Destiny is optional)
                        self:SetChecked(isChecked) 

                        if isChecked then
                            Purity.selectedDKPath = data
                            Purity:DisplayChallengeDetails(data)
                        else
                            Purity.selectedDKPath = nil
                            -- If we uncheck Destiny, show the main Vow details again
                            if Purity.selectedChallenge then 
                                Purity:DisplayChallengeDetails(Purity.selectedChallenge) 
                            end
                        end
                    end)

                    table.insert(frame.dkPathCheckboxes, check)
                    table.insert(frame.challengeWidgets, check)
                    yOffset = yOffset - 30
                end
            end
            
            -- Ensure widgets are cleaned up next time we open
            table.insert(frame.challengeWidgets, vowHeader)

		-- ============================================================
		-- LOGIC BRANCH: CLASSIC ERA / TBC (Single List)
		-- ============================================================
		else
			-- [This is your EXISTING code from the uploaded file]
			local availableChallenges = {}
			local _, playerClass = UnitClass("player")
			
			-- Load Current Class
			if Purity.ClassModules[playerClass] then
				for _, data in pairs(Purity.ClassModules[playerClass].challenges) do
					if not data.IsEligible or data:IsEligible() then
						table.insert(availableChallenges, data)
					end
				end
			end
			
			-- Load Globals
			if Purity.GlobalModules then
				for _, data in pairs(Purity.GlobalModules) do
					table.insert(availableChallenges, data)
				end
			end

			-- Create standard Buttons
			local yOffset = -20
			for _, data in ipairs(availableChallenges) do
				 local button = Purity:CreateChallengeButton(frame.leftPane, data)
				 button:SetPoint("TOP", frame.leftPane, "TOP", 0, yOffset)
				 yOffset = yOffset - button:GetHeight() - 12
				 button:SetScript("OnClick", function(self)
					Purity:DisplayChallengeDetails(self.challengeData)
				 end)
			end
		end
	end)
    Purity.optInFrame:Hide()

    Purity.mainInterfaceFrame = CreateFrame("Frame", "Purity_MainInterfaceFrame", UIParent)
    Purity.mainInterfaceFrame:SetSize(800, 550)
    Purity.mainInterfaceFrame:SetPoint("CENTER")
    Purity:ApplyCustomArt(Purity.mainInterfaceFrame)

    Purity.mainInterfaceFrame:SetMovable(true)
    Purity.mainInterfaceFrame:EnableMouse(true)
    Purity.mainInterfaceFrame:RegisterForDrag("LeftButton")
    Purity.mainInterfaceFrame:SetScript("OnDragStart", Purity.mainInterfaceFrame.StartMoving)
    Purity.mainInterfaceFrame:SetScript("OnDragStop", Purity.mainInterfaceFrame.StopMovingOrSizing)
    Purity.mainInterfaceFrame:Hide()

	local tabWidth = 85
	local tabSpacing = 5

	local rulesTab = CreateFrame("Button", "Purity_RulesTab", Purity.mainInterfaceFrame, "UIPanelButtonTemplate")
	rulesTab:SetSize(tabWidth, 22)
	rulesTab:SetPoint("TOPLEFT", 15, -15)
	rulesTab:SetText("Rules")

	local statusTab = CreateFrame("Button", "Purity_StatusTab", Purity.mainInterfaceFrame, "UIPanelButtonTemplate")
	statusTab:SetSize(tabWidth, 22)
	statusTab:SetPoint("LEFT", rulesTab, "RIGHT", tabSpacing, 0)
	statusTab:SetText("Status")

	local rosterTab = CreateFrame("Button", "Purity_RosterTab", Purity.mainInterfaceFrame, "UIPanelButtonTemplate")
	rosterTab:SetSize(tabWidth, 22)
	rosterTab:SetPoint("LEFT", statusTab, "RIGHT", tabSpacing, 0)
	rosterTab:SetText("Roster")

	local rankingsTab = CreateFrame("Button", "Purity_RankingsTab", Purity.mainInterfaceFrame, "UIPanelButtonTemplate")
	rankingsTab:SetSize(tabWidth, 22)
	rankingsTab:SetPoint("LEFT", rosterTab, "RIGHT", tabSpacing, 0)
	rankingsTab:SetText("Rankings")

	local verifyTab = CreateFrame("Button", "Purity_VerifyTab", Purity.mainInterfaceFrame, "UIPanelButtonTemplate")
	verifyTab:SetSize(tabWidth, 22)
	verifyTab:SetPoint("LEFT", rankingsTab, "RIGHT", tabSpacing, 0)
	verifyTab:SetText("Verify")
	
	local optionsTab = CreateFrame("Button", "Purity_OptionsTab", Purity.mainInterfaceFrame, "UIPanelButtonTemplate")
	optionsTab:SetSize(tabWidth, 22)
	optionsTab:SetPoint("LEFT", verifyTab, "RIGHT", tabSpacing, 0)
	optionsTab:SetText("Options")

    local contentFrame = CreateFrame("Frame", nil, Purity.mainInterfaceFrame)
    contentFrame:SetPoint("TOP", rulesTab, "BOTTOM", 0, -45)
    contentFrame:SetPoint("BOTTOM", Purity.mainInterfaceFrame, "BOTTOM", 0, 80)
    contentFrame:SetPoint("LEFT", Purity.mainInterfaceFrame, "LEFT", 60, 0)
    contentFrame:SetPoint("RIGHT", Purity.mainInterfaceFrame, "RIGHT", -60, 0)
    Purity.contentFrame = contentFrame

    Purity.wideContentFrame = CreateFrame("Frame", nil, Purity.mainInterfaceFrame)
    Purity.wideContentFrame:SetPoint("TOP", rulesTab, "BOTTOM", 0, -45)
    Purity.wideContentFrame:SetPoint("BOTTOM", Purity.mainInterfaceFrame, "BOTTOM", 0, 80)
    Purity.wideContentFrame:SetPoint("LEFT", Purity.mainInterfaceFrame, "LEFT", -20, 0)
    Purity.wideContentFrame:SetPoint("RIGHT", Purity.mainInterfaceFrame, "RIGHT", -60, 0)

    Purity.rulesPane = CreateFrame("Frame", nil, contentFrame)
    Purity.rulesPane:SetAllPoints(contentFrame)
    Purity.statusPane = CreateFrame("Frame", nil, contentFrame)
    Purity.statusPane:SetAllPoints(contentFrame)
	
	Purity.rosterPane = CreateFrame("Frame", nil, contentFrame)
	Purity.rosterPane:SetAllPoints(contentFrame)
	Purity.verifyPane = CreateFrame("Frame", nil, contentFrame)
	Purity.verifyPane:SetAllPoints(contentFrame)
	
	Purity.optionsPane = CreateFrame("Frame", nil, contentFrame)
	Purity.optionsPane:SetAllPoints(contentFrame)
	
	Purity.rankingsPane = CreateFrame("Frame", nil, Purity.wideContentFrame)
	Purity.rankingsPane:SetAllPoints(Purity.wideContentFrame)
	
	local rosterHeader = Purity.rosterPane:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	rosterHeader:SetPoint("TOP", Purity.rosterPane, "TOP", 0, -25)
	rosterHeader:SetText("Purity Addon Roster")
	rosterHeader:SetTextColor(1, 0.82, 0)
	
    local rankingsHeader = Purity.rankingsPane:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    rankingsHeader:SetPoint("TOP", Purity.rankingsPane, "TOP", 0, -25)
    rankingsHeader:SetText("Challenge Difficulty Rankings")
    rankingsHeader:SetTextColor(1, 0.82, 0)
	
    local scrollFrame = CreateFrame("ScrollFrame", "PurityRankingsScrollFrame", Purity.rankingsPane, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", rankingsHeader, "BOTTOMLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", Purity.rankingsPane, "BOTTOMRIGHT", -45, 20)
    Purity.rankingsPane.scrollFrame = scrollFrame

    local scrollChild = CreateFrame("Frame")
    scrollChild:SetWidth(scrollFrame:GetWidth() - 20)
    Purity.rankingsPane.scrollChild = scrollChild

    scrollFrame:SetScrollChild(scrollChild)

    Purity.rulesPane.title = Purity.rulesPane:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    Purity.rulesPane.title:SetPoint("TOP", Purity.rulesPane, "TOP", 0, -25)
    Purity.rulesPane.title:SetTextColor(1, 0.82, 0)
	
    local verifyHeader = Purity.verifyPane:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    verifyHeader:SetPoint("TOP", Purity.verifyPane, "TOP", 0, -25)
    verifyHeader:SetText("Challenge Verification")
    verifyHeader:SetTextColor(1, 0.82, 0)
    
    local verifyInstructions = Purity.verifyPane:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    verifyInstructions:SetPoint("TOP", verifyHeader, "BOTTOM", 0, -20)
    verifyInstructions:SetText("Your challenge is complete! Copy the entire string below and paste it into the website to be added to the leaderboard.")
    verifyInstructions:SetWidth(380)

    Purity.verifyPane.editBox = CreateFrame("EditBox", nil, Purity.verifyPane)
    Purity.verifyPane.editBox:SetSize(400, 200)
    Purity.verifyPane.editBox:SetPoint("TOP", verifyInstructions, "BOTTOM", 0, -15)
    Purity.verifyPane.editBox:SetMultiLine(true)
    Purity.verifyPane.editBox:SetAutoFocus(false)
    Purity.verifyPane.editBox:SetFontObject(GameFontNormal)
    local eb_bg = Purity.verifyPane.editBox:CreateTexture(nil,"BACKGROUND")
    eb_bg:SetAllPoints(true)
    eb_bg:SetColorTexture(0,0,0,0.5)
	
    Purity.rulesPane.rulesText = Purity.rulesPane:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    Purity.rulesPane.rulesText:SetPoint("TOPLEFT", Purity.rulesPane.title, "BOTTOMLEFT", 20, -20)
    Purity.rulesPane.rulesText:SetPoint("TOPRIGHT", Purity.rulesPane.title, "BOTTOMRIGHT", -20, -20)
    Purity.rulesPane.rulesText:SetJustifyH("LEFT")

    local statusTitle = Purity.statusPane:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    statusTitle:SetPoint("TOP", Purity.statusPane, "TOP", 0, -25)
    statusTitle:SetText("Purity Challenge Status")
    statusTitle:SetTextColor(1, 0.82, 0)

    local statusText = {}
    local statusYOffset = -65 
    for i=1, 10 do
        statusText[i] = Purity.statusPane:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        statusText[i]:SetPoint("TOP", Purity.statusPane, "TOP", 0, statusYOffset)
        statusYOffset = statusYOffset - 30
    end
    Purity.mainInterfaceFrame.statusText = statusText

    rulesTab:SetScript("OnClick", function() Purity:selectTab("rules") end)
    statusTab:SetScript("OnClick", function() Purity:selectTab("status") end)
	rosterTab:SetScript("OnClick", function() Purity:selectTab("roster") end)
	rankingsTab:SetScript("OnClick", function() Purity:selectTab("rankings") end)
    verifyTab:SetScript("OnClick", function() Purity:selectTab("verify") end)
	optionsTab:SetScript("OnClick", function() Purity:selectTab("options") end)

    local closeButton = CreateFrame("Button", "Purity_InterfaceCloseButton", Purity.mainInterfaceFrame, "UIPanelButtonTemplate")
    closeButton:SetSize(100, 25)
    closeButton:SetPoint("BOTTOM", Purity.mainInterfaceFrame, "BOTTOM", 0, 20)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function() Purity.mainInterfaceFrame:Hide() end)
	Purity:UpdateMinimapIconVisibility()
end

function Purity:ShowRuleUpdate(message)
    if not Purity.notificationBanner then return end

    Purity.notificationBanner.title:SetText("Challenge Rule Update!")
    Purity.notificationBanner.title:SetTextColor(0.9, 0.8, 0.1)
    Purity.notificationBanner.leftCap:SetVertexColor(1, 1, 1)
    Purity.notificationBanner.middleBar:SetVertexColor(1, 1, 1)
    Purity.notificationBanner.rightCap:SetVertexColor(1, 1, 1)
    Purity.notificationBanner.text:SetText(message)
    Purity.notificationBanner:Show()

    C_Timer.After(15, function()
        if Purity.notificationBanner then Purity.notificationBanner:Hide() end
    end)
end

function Purity:GetRawStatusData()
    local currentDB = Purity:GetDB()
    -- This function now purely reports data without changing it.
    -- The status is now updated live by the runtime ticker.
    local data = {
        status = currentDB.status or "Not Participating",
        addonRuntime = currentDB.addonRuntime or 0,
        totalPlayed = currentDB.totalPlayedTime or 0,
        startDate = currentDB.startDate or "N/A",
        completionDate = currentDB.completionDate or "N/A",
        finalUptime = currentDB.finalUptime,
        verificationCode = currentDB.verificationCode,
        weaponInfractions = currentDB.weaponInfractions or 0,
        physicalStrikes = currentDB.physicalStrikes or 0,
        activeChallengeID = currentDB.activeChallengeID,
        challengeTitle = currentDB.challengeTitle,
        playerGUID = currentDB.playerGUID,
    }
    return data
end

function Purity:IsOathBreaker(name)
    if not name then return false end
    local shortName = string.match(name, "([^-]+)") or name

    -- 1. Check Self
    if shortName == UnitName("player") then
        local db = Purity:GetDB()
        local mod = Purity.GlobalModules and Purity.GlobalModules.BLOOD_MAGE_BARGAIN
        -- Robust check: Challenge active AND rank > 0
        if db and db.activeChallengeID == "BLOOD_MAGE_BARGAIN" and mod and mod.GetOathbreakerRank then
            return mod:GetOathbreakerRank() > 0
        end
        return false
    end

    -- 2. Check Roster (Other players)
    local rosterData = Purity.roster and (Purity.roster[name] or Purity.roster[name .. "-" .. GetRealmName()] or Purity.roster[shortName])
    if rosterData and rosterData.class == "PALADIN" and 
       rosterData.challenge == "The Blood Mage's Bargain" and
       (rosterData.ob_rank and rosterData.ob_rank > 0) then 
        return true
    end
    return false
end

function Purity:PerformSecurityAudit(db)
    print("|cffFFFF00Purity:|r Addon update detected (v" .. (db.addonVersion or "Unknown") .. " -> v" .. Purity.Version .. "). Performing security audit...")

    local oldSignature = db.dataSignature
    local isValid = (Purity:CreateDataSignature_Legacy(db) == oldSignature)

    if not isValid then
        if Purity:CreateDataSignature(db) == oldSignature then isValid = true end
    end

    if not isValid and db.status ~= "Not Participating" then
        Purity:Violation("Update Failed: Save file signature mismatch. Data integrity cannot be verified.")
        return false
    end

    local activeChallenge = self:GetActiveChallengeObject()

    if not activeChallenge then
        print("|cffFF0000Purity:|r Audit failed: Active challenge not found.")
        return false
    end
    
    if activeChallenge.AuditKnownSpells then
        if not activeChallenge:AuditKnownSpells(Purity.Violation) then
            return false
        end
    elseif activeChallenge.IsSpellForbidden then
        for i = 1, GetNumSpellTabs() do
            local _, _, _, numSpells = GetSpellTabInfo(i)
            for j = 1, numSpells do
                local spellID = GetSpellBookItemInfo(j, "spell")
                if spellID and activeChallenge:IsSpellForbidden(spellID) then
                    Purity:Violation("Found forbidden spell '"..GetSpellInfo(spellID).."' learned under an older addon version.")
                    return false
                end
            end
        end
    end

    if activeChallenge.IsTalentForbidden then
        for i = 1, GetNumTalentTabs() do
            if activeChallenge:IsTalentForbidden(i) then
                for j = 1, GetNumTalents(i) do
                    local _, _, _, _, pointsSpent = GetTalentInfo(i, j)
                    if pointsSpent > 0 then
                        Purity:Violation("Found forbidden talents allocated under an older addon version.", true)
                        return false
                    end
                end
            end
        end
    end
    
    if db.weaponInfractions > 0 then
    end

    print("|cffFFFF00Purity:|r |cff00FF00Security audit passed. Upgrading to v" .. Purity.Version .. ".|r")
    db.addonVersion = Purity.Version
    
    if db.sequenceID == nil then db.sequenceID = 0 end
    
    db.dataSignature = Purity:CreateDataSignature(db)
    return true
end

function Purity:Violation(message, isFromAudit)
    if not self.notificationBanner then self:CreateCoreUI() end
    local currentDB = Purity:GetDB()

    if currentDB.status ~= "Passing" and currentDB.status ~= "Temporary Failure - Uptime" then
        return
    end
	
	-- [[ RESTORE FCT MEMORY & 3D DAMAGE ]]
    SHOW_COMBAT_TEXT = "1"
    SetCVar("floatingCombatTextCombatDamage", "1")
    SetCVar("CombatDamage", "1")
    
    self.notificationBanner.title:SetText("Vow of Purity Broken")
    self.notificationBanner.title:SetTextColor(1, 1, 1) 
    self.notificationBanner.leftCap:SetVertexColor(1, 0.3, 0.3)
    self.notificationBanner.middleBar:SetVertexColor(1, 0.3, 0.3)
    self.notificationBanner.rightCap:SetVertexColor(1, 0.3, 0.3)
    self.notificationBanner.text:SetText(message)
    self.notificationBanner:Show()

    print("|cffFFFF00Purity:|r |cffFF0000Your vow of purity has been broken. The challenge has Failed.|r")
	print("|cffFFFF00Purity:|r |cffFFD700Reason:|r " .. message)

    currentDB.status = "Failed"
	secureCoreState.status = "Failed"
	currentDB.failureReason = message
    currentDB.dataSignature = self:CreateDataSignature(currentDB)
    
    Purity:UpdateAndGetStatusStrings()
	Purity:BroadcastStatus()
end

function Purity:ShowWarningBanner(message, duration, warningLevel)
    if not self.notificationBanner then return end
    
    local r, g, b, title, titleColor
    if warningLevel == 1 then
        title = "|cffffd100Purity Warning|r"
        r, g, b = 1, 0.8, 0.1
    else
        title = "|cffff4500Challenge Warning!|r"
        r, g, b = 1, 0.5, 0
    end

    self.notificationBanner.title:SetText(title)
    self.notificationBanner.leftCap:SetVertexColor(r, g, b)
    self.notificationBanner.middleBar:SetVertexColor(r, g, b)
    self.notificationBanner.rightCap:SetVertexColor(r, g, b)
    self.notificationBanner.text:SetText(message)
    self.notificationBanner.text:SetTextColor(1, 1, 0)
    self.notificationBanner:Show()

    if duration and duration > 0 then
        C_Timer.After(duration, function()
            if Purity.notificationBanner and not weaponTimer then
                Purity.notificationBanner:Hide()
            end
        end)
    end
end

function Purity:HandlePhysicalStrike()
    local db = self:GetDB()
    db.physicalStrikes = (db.physicalStrikes or 0) + 1
	secureCoreState.physicalStrikes = db.physicalStrikes

    if db.physicalStrikes == 1 then
        self:ShowWarningBanner("The Light recoils from your act of physical violence, but its grace allows this transgression. This is your first strike.", 10, 1)
    elseif db.physicalStrikes == 2 then
        self:ShowWarningBanner("You have resorted to violence again. The Light's patience wears thin.\nThis is your final warning.", 10, 2)
    elseif db.physicalStrikes >= 3 then
        self:Violation("Forsaken by the Light for your violent acts, your vow of purity is broken.")
    end
end

function Purity:CalculateBloodCost(spellId)
	if not spellId then return nil end

	local powerCostTable = GetSpellPowerCost(spellId)
	local originalPowerCost = (powerCostTable and #powerCostTable > 0) and powerCostTable[1].cost or 0

	if originalPowerCost > 0 then
		local db = self:GetDB()
		if not db then return nil end

		local bloodMageModule = self.GlobalModules and self.GlobalModules.BLOOD_MAGE_BARGAIN
		if not bloodMageModule then return nil end

		local powerType = select(1, UnitPowerType("player"))
		local _, spirit = UnitStat("player", 5)
		local level = UnitLevel("player")
		local bloodPoolMax = db.bloodPoolMax or UnitHealthMax("player")

		local baseDivisor = (powerType == 0 and 200) or (powerType == 3 and 500) or 100
		local scaledDivisor = baseDivisor + (level * 20)
		local effectiveDivisor = scaledDivisor + (spirit * bloodMageModule.spiritFactor)
		
		local healthCost = 0
		if effectiveDivisor > 0 then
			healthCost = bloodPoolMax * (originalPowerCost / effectiveDivisor)
		end
		
		if healthCost > 0 then
			return math.max(1, math.floor(healthCost))
		end
	end
	return nil
end

function Purity:SyncBloodWithHealth()
    local db = self:GetDB()
    if not (db and db.isOptedIn and db.activeChallengeID == "BLOOD_MAGE_BARGAIN") then
        return
    end

    local currentHealth = UnitHealth("player")
    local maxHealth = UnitHealthMax("player")
    local changed = false

    -- Rule: Current blood can't be higher than current health.
    if db.bloodPoolCurrent > currentHealth then
        db.bloodPoolCurrent = currentHealth
        changed = true
    end

    -- Also, keep the max blood pool synced with max health.
    if db.bloodPoolMax ~= maxHealth then
        db.bloodPoolMax = maxHealth
        changed = true
    end

    return changed
end

function Purity:ShowVerificationFrame(verificationString)
    local frame = CreateFrame("Frame", "PurityVerificationFrame", UIParent, "BackdropTemplate")
    frame:SetSize(600, 150)
    frame:SetPoint("CENTER")
    frame:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -20)
    title:SetText("Challenge Complete - Verification")

    local text = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    text:SetPoint("TOP", title, "BOTTOM", 0, -10)
    text:SetText("Copy the string below and paste it into the website verifier.")

    local editBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    editBox:SetSize(500, 32)
    editBox:SetPoint("TOP", text, "BOTTOM", 0, -10)
    editBox:SetText(verificationString)
    editBox:SetAutoFocus(true)
    editBox:HighlightText()

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    closeButton:SetSize(100, 22)
    closeButton:SetPoint("BOTTOM", 0, 15)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function() frame:Hide() end)
end

function Purity:CompleteChallenge()
    local currentDB = self:GetDB()

    if currentDB.status ~= "Passing" and currentDB.status ~= "Temporary Failure - Uptime" then
        return
    end

    Purity:SilentRequestTimePlayed()

    C_Timer.After(0.1, function()
        local db = Purity:GetDB()
		
		-- [[ RESTORE FCT MEMORY & 3D DAMAGE ]]
		SHOW_COMBAT_TEXT = "1"
		SetCVar("floatingCombatTextCombatDamage", "1")
		SetCVar("CombatDamage", "1")

        local effectiveRuntime = (db.addonRuntime or 0) + (db.uptimeGrace or 0)
        local finalUptime = (db.totalPlayedTime > 0 and (effectiveRuntime / db.totalPlayedTime) * 100) or 0

        if finalUptime < 96.0 then
            db.status = "Temporary Failure - Uptime"
            return
        end

        if uptimeMonitorTicker then
            uptimeMonitorTicker:Cancel()
            uptimeMonitorTicker = nil
        end

        for i = 1, 40 do
            local auraName = UnitAura("player", i)
            if auraName and auraName == "Self-Found Adventurer" then
                db.isSelfFoundRun = true
                break
            end
        end

        PlaySoundFile("Interface\\AddOns\\Purity\\Media\\Victory-Fanfare.ogg", "Master")

        local currentDate = date("%Y-%m-%d %H:%M:%S")
        db.completionDate = currentDate
        db.status = "Passed"
		secureCoreState.status = "Passed"
        db.finalUptime = finalUptime
        db.dataSignature = Purity:CreateDataSignature(db)

        isMonitoring = false
        if purityRuntimeTicker then purityRuntimeTicker:Cancel(); purityRuntimeTicker = nil end
        if purityPlayedTimeTicker then purityPlayedTimeTicker:Cancel(); purityPlayedTimeTicker = nil end
        if self.modifierTicker then self.modifierTicker:Cancel(); self.modifierTicker = nil end

        Purity:UpdateAndGetStatusStrings()
        Purity:selectTab("status")
        if not Purity.mainInterfaceFrame:IsShown() then
            Purity.mainInterfaceFrame:Show()
        end
        Purity:BroadcastStatus()
    end)
end

function Purity:IsWeaponEquipped()
    local weaponSlots = { INVSLOT_MAINHAND, INVSLOT_OFFHAND, INVSLOT_RANGED }
    for _, slotId in ipairs(weaponSlots) do
        local itemLink = GetInventoryItemLink("player", slotId)
        if itemLink then
            local _, _, _, _, _, itemType, itemSubType = GetItemInfo(itemLink)
            if (itemType == "Weapon" and itemSubType ~= "Fishing Pole") or itemSubType == "Wand" then
                return true
            end
        end
    end
    return false
end

--- Checks all equipment slots and rejects ANY forbidden gear.
function Purity:CheckEquipmentState(slotId)
    local activeChallenge = self:GetActiveChallengeObject()
    if not activeChallenge then return end

    local dataPending = false
    
    -- All standard equippable slots: 1 (Head) through 19 (Tabard)
    local allSlots = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19 }
    
    -- If the event passes a specific slot, check only that one. 
    -- Otherwise, scan all equipment slots.
    local slotsToCheck = slotId and {slotId} or allSlots
    
    for _, slot in ipairs(slotsToCheck) do
        local itemLink = GetInventoryItemLink("player", slot)
        if itemLink then
            local itemName = GetItemInfo(itemLink)
            -- If GetItemInfo returns nil, the server hasn't sent the item data yet
            if not itemName then
                dataPending = true
            else
                local isForbidden = false
                
                -- 1. Global Item Check (Armor, Trinkets, Rings, etc.)
                if activeChallenge.IsItemForbidden and activeChallenge:IsItemForbidden(itemLink) then
                    isForbidden = true
                end
                
                -- 2. Weapon-Specific Check (Fallback for older modules that separated the logic)
                if (slot == 16 or slot == 17 or slot == 18) and activeChallenge.isWeaponAllowed then
                    if not activeChallenge:isWeaponAllowed(itemLink) then 
                        isForbidden = true 
                    end
                end

                -- THE INSTANT AUTO-UNEQUIP (Bag Bounce)
                if isForbidden then
                    ClearCursor() -- Ensure the cursor is completely empty first
                    PickupInventoryItem(slot) -- Rip the item from the equipment slot
                    
                    -- Auto-dump into the first available bag slot
                    local itemPlaced = false
                    for bag = 0, 4 do
                        for bslot = 1, C_Container.GetContainerNumSlots(bag) do
                            -- Find an empty slot
                            if not C_Container.GetContainerItemInfo(bag, bslot) then
                                C_Container.PickupContainerItem(bag, bslot) -- Drop it in
                                itemPlaced = true
                                break
                            end
                        end
                        if itemPlaced then break end
                    end
                    
                    -- Play the error sound and notify the player
                    PlaySound(847) 
                    UIErrorsFrame:AddMessage("Your vow forbids you from equipping this item.", 1.0, 0.1, 0.1, 1.0)
                end
            end
        end
    end

    -- If the item was missing from your local cache, wait for the server to send it
    if dataPending then
        C_Timer.After(1, function() Purity:CheckEquipmentState(slotId) end)
    end
end

-- Alias for backward compatibility: 
-- Any older modules calling CheckWeaponState will seamlessly route to CheckEquipmentState.
Purity.CheckWeaponState = Purity.CheckEquipmentState

function Purity:ActivateMonitoring()
    local currentDB = self:GetDB()
    if not currentDB.isOptedIn then return end
    if isMonitoring then return end; isMonitoring = true
    if currentDB.startDate == "N/A" then currentDB.startDate = date("%Y-%m-%d %H:%M:%S") end

    if currentDB.activeChallengeModuleType == "Global" then
        activeClassModule = Purity.GlobalModules[currentDB.activeChallengeID]
    else
        local _, classToken = UnitClass("player")
        local className = classToken and string.upper(classToken) or nil
        if className and Purity.ClassModules[className] then
            activeClassModule = Purity.ClassModules[className]
        else
            activeClassModule = nil
        end
    end

    local activeChallenge = self:GetActiveChallengeObject()
    if not activeChallenge then
        Purity:Violation("Could not activate monitoring. No active challenge found in database.")
        return
    end

    if purityRuntimeTicker then purityRuntimeTicker:Cancel() end
    purityRuntimeTicker = C_Timer.NewTicker(1, function()
        local db = Purity:GetDB()
        if secureCoreState.isActive then
            local tampered = false
            if db.status ~= secureCoreState.status then
                db.status = secureCoreState.status
                tampered = true
            end
            if db.weaponInfractions ~= secureCoreState.weaponInfractions then
                db.weaponInfractions = secureCoreState.weaponInfractions
                tampered = true
            end
            if db.physicalStrikes ~= secureCoreState.physicalStrikes then
                db.physicalStrikes = secureCoreState.physicalStrikes
                tampered = true
            end
            if tampered then
                db.dataSignature = Purity:CreateDataSignature(db)
                
                if Purity.mainInterfaceFrame and Purity.mainInterfaceFrame:IsShown() then
                    Purity:UpdateAndGetStatusStrings()
                end
                if _G["UpdateCharacterPurity"] and _G["PurityCharacterPanel"] and _G["PurityCharacterPanel"]:IsShown() then
                    _G["UpdateCharacterPurity"]()
                end
            end
        end

        if db.status == "Failed" or db.status == "Not Participating" then
            return
        end
        
        db.addonRuntime = db.addonRuntime + 1

        if db.totalPlayedTime > 0 then
            local currentUptime = (db.addonRuntime / db.totalPlayedTime) * 100
            if currentUptime < 96.0 then
                if db.status == "Passing" then
                    db.status = "Temporary Failure - Uptime"
                end
            else -- currentUptime is >= 96.0
                if db.status == "Temporary Failure - Uptime" then
                    db.status = "Passing"
                end
            end
        end
		local activeChallenge = Purity:GetActiveChallengeObject()
            if activeChallenge and activeChallenge.SyncTruth then
                activeChallenge:SyncTruth(db)
        end
    end)
    if purityPlayedTimeTicker then purityPlayedTimeTicker:Cancel() end
    purityPlayedTimeTicker = C_Timer.NewTicker(60, function()
        local db = Purity:GetDB()
        if db.status == "Failed" or db.status == "Not Participating" then
            if purityPlayedTimeTicker then purityPlayedTimeTicker:Cancel(); purityPlayedTimeTicker = nil end
            return
        end
        Purity:SilentRequestTimePlayed()
    end)
       if not monitorFrame then
        monitorFrame = CreateFrame("Frame")
        monitorFrame:SetScript("OnEvent", function(_, event, ...)
            local db = Purity:GetDB()
            if event == "PLAYER_LOGOUT" then
                local aChallenge = Purity:GetActiveChallengeObject()
                if aChallenge and aChallenge.EventHandler then
                    aChallenge:EventHandler(event, ...)
                end
                return
            end
            if db.status == "Failed" or db.status == "Not Participating" then
                return
            end
			
			if event == "PLAYER_DEAD" then
				Purity:UpdateAllModifierStatuses()
				return
			end
			
			if event == "UNIT_HEALTH" then
				local unitTarget = ...
				if unitTarget == "player" then
					if Purity:SyncBloodWithHealth() then
						local bloodMageModule = Purity.GlobalModules and Purity.GlobalModules.BLOOD_MAGE_BARGAIN
						if bloodMageModule and bloodMageModule.UpdateBar then
							bloodMageModule:UpdateBar()
						end
					end
				end
				return
			end
			
			if event == "UNIT_AURA" then
				local unitTarget = ...
				if unitTarget == "player" then
					Purity:UpdateAllModifierStatuses()
					local bloodMageModule = Purity.GlobalModules and Purity.GlobalModules.BLOOD_MAGE_BARGAIN
                    if bloodMageModule and bloodMageModule.ManageBloodRegen then
                        bloodMageModule:ManageBloodRegen()
                    end
				end
			end

            local aChallenge = Purity:GetActiveChallengeObject()
            if not aChallenge then return end
			
	        if event == "PLAYER_LEVEL_UP" then
                local newLevel = ...
                if newLevel == MAX_PLAYER_LEVEL then
                    if db.status == "Passing" then
                        Purity:CompleteChallenge()
                    end
                    Purity:DisplayCompletionStats()
                end
            end
			
			if event == "PLAYER_EQUIPMENT_CHANGED" then
                local slotId, hasItem = ...
                -- hasItem is true when putting an item ON. We only want to check when equipping!
                if hasItem then
                    Purity:CheckEquipmentState(slotId)
                end
            end

            local aChallenge = Purity:GetActiveChallengeObject()
            if aChallenge and aChallenge.EventHandler then
                aChallenge:EventHandler(event, ...)
            end
	end)			
        monitorFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
        monitorFrame:RegisterEvent("PLAYER_LEVEL_UP")
        monitorFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
        monitorFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        monitorFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        monitorFrame:RegisterEvent("PLAYER_TOTEM_UPDATE")
        monitorFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        monitorFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
        monitorFrame:RegisterEvent("SPELLS_CHANGED")
        monitorFrame:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")
        monitorFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
        monitorFrame:RegisterEvent("PLAYER_LEAVE_COMBAT")
		monitorFrame:RegisterEvent("CHAT_MSG_LOOT")
		monitorFrame:RegisterEvent("MERCHANT_UPDATE")
        monitorFrame:RegisterEvent("PLAYER_LOGOUT")
		monitorFrame:RegisterEvent("LOOT_READY")
		monitorFrame:RegisterEvent("LOOT_CLOSED")
		monitorFrame:RegisterEvent("INSPECT_READY")
		monitorFrame:RegisterEvent("ITEM_LOCK_CHANGED")
        monitorFrame:RegisterEvent("BAG_UPDATE")
		monitorFrame:RegisterEvent("CVAR_UPDATE")
		monitorFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
        monitorFrame:RegisterEvent("UNIT_POWER_UPDATE")
		monitorFrame:RegisterEvent("UNIT_HEALTH")
		monitorFrame:RegisterEvent("UNIT_AURA")
		monitorFrame:RegisterEvent("CHARACTER_POINTS_CHANGED")
		monitorFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
    end

    C_Timer.After(2, function()
        Purity:CheckWeaponState()
    end)

    if activeChallenge and activeChallenge.EventHandler then
        activeChallenge:EventHandler("SPELLS_CHANGED")
    end

    --[[ MODIFIED: This block now implements your suggested "limbo" logic. ]]
    -- It only starts if the player is max level AND in a temporary failure state.
    if purityRuntimeTicker and UnitLevel("player") == MAX_PLAYER_LEVEL and currentDB.status == "Temporary Failure - Uptime" then
        if uptimeMonitorTicker then uptimeMonitorTicker:Cancel() end
        print("|cffFFFF00Purity:|r Entered max-level uptime recovery mode. Re-checking status every 30 seconds.")
        
        uptimeMonitorTicker = C_Timer.NewTicker(30, function()
            local tickerDb = Purity:GetDB()

            if tickerDb.status == "Passing" then
                -- Success! The 1-second ticker has recovered the uptime. Now, complete the challenge.
                print("|cffFFFF00Purity:|r |cff00FF00Uptime has been successfully recovered! Finalizing challenge...|r")
                Purity:CompleteChallenge()
                
                -- The challenge is complete, so we can stop this timer.
                if uptimeMonitorTicker then
                    uptimeMonitorTicker:Cancel()
                    uptimeMonitorTicker = nil
                end
            elseif tickerDb.status ~= "Temporary Failure - Uptime" then
                -- The status has changed to something else (like Failed), so we should stop monitoring.
                if uptimeMonitorTicker then
                    uptimeMonitorTicker:Cancel()
                    uptimeMonitorTicker = nil
                end
            end
            -- If the status is still "Temporary Failure - Uptime", we do nothing and let the timer loop.
        end)
    elseif uptimeMonitorTicker then
        -- If we are not in a limbo state, make sure the timer is cancelled.
        uptimeMonitorTicker:Cancel()
        uptimeMonitorTicker = nil
    end
end

    C_Timer.After(3, function()
        local itemLink = GetInventoryItemLink("player", INVSLOT_MAINHAND)
        if itemLink then
            local itemName = GetItemInfo(itemLink)
            if itemName then
                Purity:CheckWeaponState()
            else
                C_Timer.After(2, function() Purity:CheckWeaponState() end)
            end
        else
            Purity:CheckWeaponState()
        end
    end)

    if activeChallenge and activeChallenge.EventHandler then
        activeChallenge:EventHandler("SPELLS_CHANGED")
    end
	if purityRuntimeTicker and UnitLevel("player") == MAX_PLAYER_LEVEL and (currentDB.status == "Passing" or currentDB.status == "Temporary Failure - Uptime") then
    if uptimeMonitorTicker then uptimeMonitorTicker:Cancel() end
    uptimeMonitorTicker = C_Timer.NewTicker(30, function()
        local tickerDb = Purity:GetDB()
        if UnitLevel("player") == MAX_PLAYER_LEVEL and (tickerDb.status == "Passing" or tickerDb.status == "Temporary Failure - Uptime") then
            Purity:CompleteChallenge()
        else
            if uptimeMonitorTicker then
                uptimeMonitorTicker:Cancel()
                uptimeMonitorTicker = nil
            end
        end
    end)
elseif uptimeMonitorTicker then
    uptimeMonitorTicker:Cancel()
    uptimeMonitorTicker = nil
end


function Purity:LoadClassModule()
    local _, class = UnitClass("player")
    local className = class and string.upper(class) or nil

    if className and Purity.ClassModules and Purity.ClassModules[className] then
        activeClassModule = Purity.ClassModules[className]
        print("|cffFFFF00Purity:|r |cff00FF00" .. class .. " module loaded.|r")
        return true
    end

    if Purity.GlobalModules and next(Purity.GlobalModules) then
         print("|cffFFFF00Purity:|r |cff00FF00Global challenge modules detected.|r")
         return true
    end

    print("|cffFFFF00Purity:|r No challenge module found for your class or any global challenges. Addon will not function.")
    activeClassModule = nil
    return false
end

function Purity:ApplyCustomArt(parentFrame)
    local sideArtAspectRatio = 451 / 2048
    local sideArtWidth = parentFrame:GetHeight() * sideArtAspectRatio

    local leftArt = parentFrame:CreateTexture(nil, "BACKGROUND")
    leftArt:SetWidth(77)
    leftArt:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, 0)
    leftArt:SetPoint("BOTTOMLEFT", parentFrame, "BOTTOMLEFT", 0, 0)
    leftArt:SetTexture("Interface\\AddOns\\Purity\\Media\\Menu-Left.tga")

    local rightArt = parentFrame:CreateTexture(nil, "BACKGROUND")
    rightArt:SetWidth(77)
    rightArt:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", 0, 0)
    rightArt:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", 0, 0)
    rightArt:SetTexture("Interface\\AddOns\\Purity\\Media\\Menu-Right.tga")
    
    local middleArt = parentFrame:CreateTexture(nil, "BACKGROUND", nil, -1)
    middleArt:SetPoint("TOPLEFT", leftArt, "TOPRIGHT")
    middleArt:SetPoint("BOTTOMRIGHT", rightArt, "BOTTOMLEFT")
    middleArt:SetTexture("Interface\\AddOns\\Purity\\Media\\Menu-Middle.tga")

    local crestArt = parentFrame:CreateTexture(nil, "ARTWORK")
    crestArt:SetSize(100, 100)
    crestArt:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", 30, 30)
    crestArt:SetTexture("Interface\\AddOns\\Purity\\Media\\Banner-Crest.tga")
end

SLASH_PURITY1 = "/purity"
SlashCmdList["PURITY"] = function(msg)
    local args = {}
    for arg in string.gmatch(msg, "[^%s]+") do table.insert(args, arg) end
    local command = args[1] and string.lower(args[1]) or nil
	
    if command == "debugstate" then
        local db = Purity:GetDB()
        print("|cffFFFF00--- Purity Debug State ---|r")
        if not db then
            print("|cffFF0000Database (Purity_PerCharacterDB) is not loaded!|r")
            return
        end
        print("Challenge Status: |cff00FF00" .. tostring(db.status) .. "|r")
        print("Active Challenge ID: |cff00FF00" .. tostring(db.activeChallengeID) .. "|r")
        print("Is Opted In: |cff00FF00" .. tostring(db.isOptedIn) .. "|r")
        return
    end
	
	    if command == "requestfrom" then
        local targetName = args[2]
        if targetName then
            print("|cffFFFF00Purity:|r Requesting status from " .. targetName .. " via whisper.")
            C_ChatInfo.SendAddonMessage(Purity.ADDON_PREFIX, "ROSTER_REQUEST", "WHISPER", targetName)
        else
            print("|cffFFFF00Purity:|r Usage: /purity requestfrom <PlayerName>")
        end
        return
    end

    if not Purity.mainInterfaceFrame then Purity:CreateCoreUI() end

    local _, classToken = UnitClass("player")
    if classToken == "MAGE" then
        Purity.mainInterfaceFrame:SetHeight(550)
    elseif classToken == "PRIEST" then
        Purity.mainInterfaceFrame:SetHeight(500)
    elseif classToken == "PALADIN" then
        Purity.mainInterfaceFrame:SetHeight(530)
    elseif classToken == "WARLOCK" then
        Purity.mainInterfaceFrame:SetHeight(700)
    elseif classToken == "WARRIOR" then
        Purity.mainInterfaceFrame:SetHeight(650)
    elseif classToken == "SHAMAN" then
        Purity.mainInterfaceFrame:SetHeight(480)
    elseif classToken == "DRUID" then
        Purity.mainInterfaceFrame:SetHeight(600)
    elseif classToken == "HUNTER" then
        Purity.mainInterfaceFrame:SetHeight(680)
    else
        Purity.mainInterfaceFrame:SetHeight(550)
    end
	
	if command == "bloodbar" then
        local db = Purity:GetDB()
        local newState = not db.bloodBarIsSeparate
        local status = newState and "Separate and Movable" or "Overlay on Health Bar"
        print("|cffFFFF00Purity:|r Blood Mage Bar mode set to: |cff00FF00" .. status .. "|r")

        if Purity.GlobalModules.BLOOD_MAGE_BARGAIN and Purity.GlobalModules.BLOOD_MAGE_BARGAIN.ApplyBarMode then
            Purity.GlobalModules.BLOOD_MAGE_BARGAIN:ApplyBarMode(newState, true) -- This is correct
        end
        return
		
		elseif command == "rules" or command == "status" or command == "roster" or command == "verify" or command == "rankings" or command == "options" then
        if not Purity.mainInterfaceFrame:IsShown() then
            Purity.mainInterfaceFrame:Show()
        end
        Purity:selectTab(command)
		
	elseif command == "override" then
        local inputSignature = args[2]
        local weaponInfractions = tonumber(args[3]) or 0
        local physicalStrikes = tonumber(args[4]) or 0

        if not inputSignature or #inputSignature < 8 then
            print("|cffFFFF00Purity:|r |cffFF0000Invalid usage. Usage: /purity override [signature] [weapons] [strikes]|r")
            return
        end

        local db = Purity:GetDB()
        
        -- *** STATIC APPEAL VERIFICATION ***
        -- We generate a hash based ONLY on fields that do not change during gameplay.
        -- This ensures the code you generate works regardless of their current playtime.
        
        local stringToSign = (
            (db.playerGUID or "") ..
            (db.activeChallengeID or "") ..
            (db.startDate or "") ..
            "Passing" .. -- We enforce that this code is for a "Passing" status
            tostring(weaponInfractions) ..
            tostring(physicalStrikes) ..
            trainerKey
        )
        
        local expectedSignature = Purity:GenerateVerificationHash(stringToSign)

        if inputSignature == expectedSignature then
            db.status = "Passing"
            db.weaponInfractions = weaponInfractions
            db.physicalStrikes = physicalStrikes
            db.failureReason = nil
            db.dataSignature = Purity:CreateDataSignature(db)
            
			Purity:SyncSecureStateFromDB()
            Purity:ActivateMonitoring()
            print("|cffFFFF00Purity:|r |cff00FF00Appeal code accepted. Challenge status restored to Passing.|r")
            
            if Purity.mainInterfaceFrame and Purity.mainInterfaceFrame:IsShown() then
                Purity:UpdateAndGetStatusStrings()
            end
        else
            print("|cffFFFF00Purity:|r |cffFF0000Invalid appeal code. This code does not match your character's static ID.|r")
        end

	elseif command == "help" then
        print("|cffFFFF00--- Purity Commands ---|r")
        print("/purity: Shows your quick current challenge status in chat.")
		print("/purity rules: Opens the full rules window.")
        print("/purity status: Opens the full status window.")
        print("/purity roster: Opens the full roster window.")
		print("/purity rankings: Opens the full rankings window.")
        print("/purity verify: Opens the verification window.")
		print("/purity options: Opens the options window.")
		print("/purity drunk: Toggles the Drunken Master status window.")
        print("/purity bloodbar: Toggles the Blood Mage bar between overlay and a movable frame.")
        print("/purity bloodlog: Toggles the Blood Log. Use '/purity bloodlog reset' to reset position.")
		
	elseif command == "drunk" then
        if Purity.GlobalModules and Purity.GlobalModules.DRUNK and Purity.GlobalModules.DRUNK.ToggleStatusFrame then
            Purity.GlobalModules.DRUNK:ToggleStatusFrame()
        else
            print("|cffFFFF00Purity:|r This command is only available for the Drunken Master challenge.")
        end
		
	elseif command == "bloodlog" then
        local db = Purity:GetDB()
        local bloodMageModule = Purity.GlobalModules and Purity.GlobalModules.BLOOD_MAGE_BARGAIN
        
        -- Check for the active challenge
        if db and db.activeChallengeID == "BLOOD_MAGE_BARGAIN" and bloodMageModule then
            
            -- If the frame doesn't exist (e.g., first use), create it now.
            if not bloodMageModule.bloodLogFrame then
                bloodMageModule:CreateBloodLogFrame()
            end
            
            local frame = bloodMageModule.bloodLogFrame
            if not frame then -- Safety check
                 print("|cffFFFF00Purity:|r Blood Log frame failed to create.")
                 return
            end

            local arg2 = args[2] and string.lower(args[2]) or nil

            if arg2 == "reset" then
                frame:ClearAllPoints()
                frame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 200)
                if db then db.bloodLogPosition = nil end
                print("|cffFFFF00Purity:|r Blood Log position has been reset.")
            elseif frame:IsShown() then
                frame:Hide()
                if db then db.bloodLogVisible = false end
            else
                frame:Show()
                if db then db.bloodLogVisible = true end
            end
        else
            print("|cffFFFF00Purity:|r Blood Log is only available for the Blood Mage challenge.")
        end
        return
		
	elseif command == "glasslog" then
        if Purity.GlobalModules["GLASS_HEART"] then
            Purity.GlobalModules["GLASS_HEART"]:ToggleLog()
        else
            print("|cffFFFF00Purity:|r Glass Heart module not loaded.")
        end
		
    else
        Purity:SilentRequestTimePlayed()
        C_Timer.After(0.2, function()
            local data = Purity:GetRawStatusData()
            
            local goldColor = "|cffffd100"
            local statusColor = "|cff00FF00"
            if data.status == "Failed" then statusColor = "|cffFF0000"
            elseif data.status == "Not Participating" then statusColor = "|cff888888"
            elseif data.status == "Temporary Failure - Uptime" then statusColor = "|cffFFFF00" end
            local whiteColor = "|cffffffff"
            local activeChallenge = Purity:GetActiveChallengeObject()

            print(goldColor .. "--- Purity Challenge Status ---|r")
            print("Challenge: " .. whiteColor .. (data.challengeTitle or "N/A") .. "|r")
            print("Status: " .. statusColor .. data.status .. "|r")

            local uptimeLabel = "Uptime:|r "
            if data.status == "Passed" or data.status == "Failed" then
                uptimeLabel = "Final Uptime:|r "
            end
            print(uptimeLabel .. whiteColor .. string.format("%.2f%%", (data.finalUptime or ((data.totalPlayed > 0 and (data.addonRuntime / data.totalPlayed) * 100) or 0))) .. "|r")

            if activeChallenge and activeChallenge.needsWeaponWarning and (data.status == "Passing" or data.status == "Temporary Failure - Uptime") then
                print("Weapon Warnings: " .. whiteColor .. (data.weaponInfractions or 0) .. "/2|r")
            end
			
			if activeChallenge and activeChallenge.challengeName == "Testament of Purity" and (data.status == "Passing" or data.status == "Temporary Failure - Uptime") then
                print("Physical Strikes: " .. whiteColor .. (data.physicalStrikes or 0) .. "/2|r")
            end
            
            print("Start Date: " .. whiteColor .. (data.startDate or "N/A") .. "|r")

            if data.completionDate ~= "N/A" then
                print("Completion Date: " .. whiteColor .. data.completionDate .. "|r")
            end
        end)
    end
end

function Purity_Tooltip_OnShow(self)
    if not Purity or not Purity.GetDB then return end
    local db = Purity:GetDB()

    if not (db and db.isOptedIn and db.activeChallengeID == "BLOOD_MAGE_BARGAIN") then
        return
    end

    local spellName, spellId = self:GetSpell()
    if spellId then
        local bloodMageModule = Purity.GlobalModules and Purity.GlobalModules.BLOOD_MAGE_BARGAIN
        if not bloodMageModule then return end

        if bloodMageModule.healingSpells[spellName] then
            return
        end

        local powerCostTable = GetSpellPowerCost(spellId)
        local originalPowerCost = (powerCostTable and #powerCostTable > 0) and powerCostTable[1].cost or 0

        if originalPowerCost > 0 then
            local _, spirit = UnitStat("player", 5)
            local bloodPoolMax = db.bloodPoolMax or UnitHealthMax("player")
            local powerType = select(1, UnitPowerType("player"))
            local baseDivisor = (powerType == 0 and 200) or (powerType == 3 and 500) or 100
            local effectiveDivisor = baseDivisor + (spirit * bloodMageModule.spiritFactor)
            local healthCost = (effectiveDivisor > 0) and (bloodPoolMax * (originalPowerCost / effectiveDivisor)) or 0

            if healthCost > 0 then
                local finalCost = math.max(1, math.floor(healthCost))
                local weakenedCost = math.max(1, math.floor(finalCost * 2.0))

                local costText = bloodMageModule.sanguineWeaknessActive
                    and string.format("|cffFF0000%d|r (Normally %d)", weakenedCost, finalCost)
                    or string.format("%d (|cffFF0000%d|r while Weakened)", finalCost, weakenedCost)

                self:AddLine(" ", 0, 0, 0, 0)
                self:AddLine("Blood Cost: " .. costText, 1.0, 0.2, 0.2)
                self:Show()
            end
        end
        return
    end

    local left1 = _G[self:GetName() .. "TextLeft1"]
    if left1 then
        local text = left1:GetText()
        if text then
            if text == STAT_SPIRIT or text:find("Spirit") then
                self:AddLine("Reduces blood cost of your spells.")
                self:Show()
            elseif text == STAT_STAMINA or text:find("Stamina") then
                self:AddLine("Increases your total Blood Pool.")
                self:Show()
            end
        end
    end
end

local function Purity_TooltipOnUpdateHandler(self)
    local _, unit = self:GetUnit()
    if not unit or not UnitIsPlayer(unit) then return end

    local isOathBreaker = false
    local isBloodMage = false
    local isGlassHeart = false
    local currentVal, maxVal

    -- 1. Identify Challenge Type (Self or Roster)
    if UnitIsUnit(unit, "player") then
        local db = Purity:GetDB()
        if db and (db.status == "Passing" or db.status == "Temporary Failure - Uptime") then
            if db.activeChallengeID == "BLOOD_MAGE_BARGAIN" then
                local _, class = UnitClass("player")
                if class == "PALADIN" and Purity:IsOathBreaker(UnitName("player")) then
                    isOathBreaker = true
                else
                    isBloodMage = true
                end
                currentVal = db.bloodPoolCurrent
                maxVal = db.bloodPoolMax
            elseif db.activeChallengeID == "GLASS_HEART" then
                isGlassHeart = true
                currentVal = db.glassHeartHP
                maxVal = UnitHealthMax("player")
            end
        end
    else
        local name = UnitName(unit)
        local shortName = name and name:match("([^-]+)")
        local data = Purity.roster and (Purity.roster[name] or Purity.roster[shortName] or Purity.roster[name .. "-" .. GetRealmName()])
        
        if data and (data.status == "Passing" or data.status == "Temporary Failure - Uptime") then
            if data.challenge == "The Blood Mage's Bargain" then
                if data.class == "PALADIN" then
                    isOathBreaker = true
                else
                    isBloodMage = true
                end
                currentVal = data.bloodPoolCurrent
                maxVal = data.bloodPoolMax
            elseif data.challenge == "The Glass Heart" then
                isGlassHeart = true
                currentVal = data.glassHeartCurrent
                maxVal = data.glassHeartMax
            end
        end
    end

    -- 2. Apply Health Bar Visuals
    -- All three types get a custom health bar override in the tooltip
    if isOathBreaker or isBloodMage or isGlassHeart then
        local statusBar = GameTooltipStatusBar
        if statusBar then
            if not statusBar:IsShown() then statusBar:Show() end
            
            if isOathBreaker or isBloodMage then
                statusBar:SetStatusBarColor(0.8, 0.1, 0.1) -- Red for Blood Mages
            else
                statusBar:SetStatusBarColor(0.0, 1.0, 0.0) -- Green for Glass Heart
            end
            
            if currentVal and maxVal and maxVal > 0 then
                statusBar:SetMinMaxValues(0, maxVal)
                statusBar:SetValue(currentVal)
                if statusBar.Text then
                    statusBar.Text:SetText(math.floor(currentVal) .. " / " .. maxVal)
                    statusBar.Text:Show() 
                end
            end
        end
    end

    -- 3. Apply Oath Breaker Specific Text Overrides (ONLY for Paladins)
    if isOathBreaker then
        -- Name Color -> Red
        local line1 = _G[self:GetName() .. "TextLeft1"]
        if line1 then
            local text = line1:GetText()
            if text and not text:find("ffFF0000") then
                 local cleanText = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
                 line1:SetText("|cffFF0000" .. cleanText .. "|r")
            end
        end

        -- Class Name -> Oath Breaker
        for i = 2, self:NumLines() do
            local line = _G[self:GetName() .. "TextLeft" .. i]
            if line then
                local text = line:GetText()
                if text and text:find("Paladin") then
                     local override = Purity.BLOODMAGE_CLASS_OVERRIDES["PALADIN"]
                     local newText = text:gsub("Paladin", "|cff" .. override.colorHex .. override.name .. "|r")
                     line:SetText(newText)
                end
            end
        end
        
        -- Resize to fit "Oath Breaker" if necessary
        local padding = 20
        local maxWidth = 0
        for i = 1, self:NumLines() do
            local leftLine = _G[self:GetName() .. "TextLeft" .. i]
            if leftLine and leftLine:IsShown() then
                local w = leftLine:GetStringWidth()
                if w > maxWidth then maxWidth = w end
            end
        end
        if maxWidth > 0 and (maxWidth + padding) > self:GetWidth() then
            self:SetWidth(maxWidth + padding)
        end
    end
end

local mainFrame = CreateFrame("Frame")
mainFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
mainFrame:RegisterEvent("PLAYER_LOGIN")
mainFrame:RegisterEvent("CHAT_MSG_ADDON")
mainFrame:RegisterEvent("PLAYER_LOGOUT")
mainFrame:RegisterEvent("CHAT_MSG_CHANNEL")
mainFrame:RegisterEvent("PLAYER_ALIVE")
mainFrame:RegisterEvent("TIME_PLAYED_MSG")
mainFrame:RegisterEvent("ADDON_LOADED")

local function OnAddonMessage(prefix, message, channel, sender)
    if prefix ~= Purity.ADDON_PREFIX or sender == UnitName("player") .. "-" .. GetRealmName() then
        return
    end
    
    -- Strip realm name for cleaner chat display
    local shortName = string.match(sender, "([^-]+)") or sender
    
    local command, data = message:match("([^:]+):?(.*)")

	if command == "STATUS_UPDATE" then
		local statusData = Purity:Deserialize(data)
		Purity.roster[sender] = {
			challenge = statusData.challenge,
			status = statusData.status,
			level = statusData.level,
			class = statusData.class,
			coefficient = statusData.coefficient,
			uptime = statusData.uptime,
			ob_rank = tonumber(statusData.ob_rank) or 0,
			lastSeen = GetTime() 
		}
		Purity:UpdateRosterWindow()

    elseif command == "GOODBYE" then
        -- Remove from roster
        Purity.roster[sender] = nil
        Purity:UpdateRosterWindow()

        -- ALERT: LOGOUT
        if Purity_GlobalSettings.showMemberAlerts then
            local color = "|cff888888" -- Grey for offline
            print("|cffFFFF00Purity:|r " .. color .. shortName .. " has gone offline.|r")
        end

    elseif command == "BLOODPOOL_UPDATE" then
        if Purity.roster[sender] then
            local bloodData = Purity:Deserialize(data)
            Purity.roster[sender].bloodPoolCurrent = bloodData.current
            Purity.roster[sender].bloodPoolMax = bloodData.max
        end
    elseif command == "GLASSHEART_UPDATE" then
        if Purity.roster[sender] then
            local glassData = Purity:Deserialize(data)
            Purity.roster[sender].glassHeartCurrent = glassData.current
            Purity.roster[sender].glassHeartMax = glassData.max
        end
    elseif command == "ROSTER_REQUEST" then
        Purity:SendStatusToPlayer(sender)
    end
    -- Refresh frames if either module is active
    if Purity.GlobalModules.BLOOD_MAGE_BARGAIN and Purity.GlobalModules.BLOOD_MAGE_BARGAIN.RefreshGroupFrames then
        Purity.GlobalModules.BLOOD_MAGE_BARGAIN:RefreshGroupFrames()
    end
    if Purity.GlobalModules.GLASS_HEART and Purity.GlobalModules.GLASS_HEART.RefreshGroupFrames then
        Purity.GlobalModules.GLASS_HEART:RefreshGroupFrames()
    end
end

local function OnPlayerLogin()
    Purity:EnforceDefaultClassColors()
    Purity:BuildChallengeTypeMap()
    Purity:StartModifierMonitor()
    C_ChatInfo.RegisterAddonMessagePrefix(Purity.ADDON_PREFIX)
    
    -- Hook ALL Chat Frames (1 through 10) to catch Prat/LTP windows
    for i = 1, NUM_CHAT_WINDOWS do
        local frame = _G["ChatFrame"..i]
        if frame then
            if not frame.PurityOriginalAddMessage then
                frame.PurityOriginalAddMessage = frame.AddMessage
            end

            frame.AddMessage = function(self, text, ...)
                -- 1. Hide "Time Played" spam
                if HIDE_RTP_CHAT_MSG_BUFFER > 0 and text then
                     local totalPrefix = string.gsub(TIME_PLAYED_TOTAL, "%%s", "") 
                     local levelPrefix = string.gsub(TIME_PLAYED_LEVEL, "%%s", "")
                     if string.find(text, totalPrefix, 1, true) then return end
                     if string.find(text, levelPrefix, 1, true) then
                         HIDE_RTP_CHAT_MSG_BUFFER = HIDE_RTP_CHAT_MSG_BUFFER - 1
                         if HIDE_RTP_CHAT_MSG_BUFFER < 0 then HIDE_RTP_CHAT_MSG_BUFFER = 0 end
                         return 
                     end
                end

                -- 2. Recolor Oath Breakers
                -- We iterate over ANY color code (|cff......) 
                if text and string.find(text, "|cff%x%x%x%x%x%x") then
                    text = string.gsub(text, "(|cff%x%x%x%x%x%x)(.-)(|r)", function(colorCode, content, resetCode)
                        -- 'content' is the text inside the color. 
                        -- In your log, the name was exactly: "Oathbreakerr" inside the color tags.
                        
                        -- 1. Strip potential brackets or spaces just in case
                        local cleanName = content:gsub("[%[%]%(%)<>]", ""):gsub("^%s*(.-)%s*$", "%1")

                        -- 2. Check if this specific text is an Oath Breaker
                        if Purity:IsOathBreaker(cleanName) then
                            -- It is! Return RED + Content + Reset
                            return "|cffFF0000" .. content .. resetCode
                        end
                        
                        -- Not an Oath Breaker? Return the original color and content
                        return colorCode .. content .. resetCode
                    end)
                end

                return frame.PurityOriginalAddMessage(self, text, ...)
            end
        end
    end
    
    CharacterFrame:HookScript("OnShow", function() Purity:UpdateCharacterFrameClassName() end)
    CharacterFrameTab1:HookScript("OnClick", function() C_Timer.After(0.01, function() Purity:UpdateCharacterFrameClassName() end) end)
    
    C_Timer.NewTicker(60, function()
        local currentTime = GetTime()
        local playersToRemove = {}
        for playerName, data in pairs(Purity.roster) do
            if currentTime - (data.lastSeen or 0) > 125 then table.insert(playersToRemove, playerName) end
        end
        if #playersToRemove > 0 then
            for _, name in ipairs(playersToRemove) do Purity.roster[name] = nil end
            Purity:UpdateRosterWindow()
        end
    end)
end

mainFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "CHAT_MSG_CHANNEL" then
        local msg = select(1, ...)
        local sender = select(2, ...)
        local channelName, channelID = select(9, ...) -- GRAB THE CHANNEL ID HERE

        if channelName == "PurityUsers" then
            Purity.purityChannelID = channelID -- SAVE THE CHANNEL ID
            
            if msg == "!purity_ping" then
            end

            local selfName = UnitName("player")
            local isSelf = false
            if sender then
                if sender == selfName then
                    isSelf = true
                elseif sender:find(selfName .. "-", 1, true) == 1 then
                    isSelf = true
                end
            end
			
			if not isSelf and msg == "!purity_ping" and Purity_GlobalSettings.showMemberAlerts then
                 local shortName = string.match(sender, "([^-]+)") or sender
                 -- Check lastSeen to prevent spam if they spam the macro (60 second throttle)
                 local lastSeen = Purity.roster[sender] and Purity.roster[sender].lastSeen or 0
                 if (GetTime() - lastSeen) > 60 then
                      print("|cffFFFF00Purity:|r |cff00FF00" .. shortName .. " has come online.|r")
                 end
            end

            if (msg == "!purity_ping" or msg == "joins channel") and sender and not isSelf then
                Purity:SendStatusToPlayer(sender)
                C_ChatInfo.SendAddonMessage(Purity.ADDON_PREFIX, "ROSTER_REQUEST", "WHISPER", sender)
            else
                if msg == "!purity_ping" then
                end
            end
        end
        return

    elseif event == "CHAT_MSG_ADDON" then
        OnAddonMessage(...)
        return

    elseif event == "PLAYER_LOGOUT" then
		Purity:RestoreDefaultIncomingDamageText()
		Purity:SendGoodbye()
		local currentDB = Purity:GetDB()
		if currentDB and currentDB.isOptedIn then
			if secureCoreState and secureCoreState.isActive then
                currentDB.status = secureCoreState.status
                currentDB.weaponInfractions = secureCoreState.weaponInfractions
                currentDB.physicalStrikes = secureCoreState.physicalStrikes
            end
			Purity:SyncSequence()
			if currentDB.activeChallengeID == "DRUNK" then
				if not currentDB.drunkData then currentDB.drunkData = {} end
				currentDB.drunkData.lastState = Purity.GlobalModules.DRUNK:GetCurrentState()
				currentDB.drunkData.logoutTimestamp = GetTime()
			end
			if currentDB.activeChallengeID == "BLOOD_MAGE_BARGAIN" then
                local bloodMageModule = Purity.GlobalModules and Purity.GlobalModules.BLOOD_MAGE_BARGAIN
                if bloodMageModule and bloodMageModule.bloodLogFrame then
                    currentDB.bloodLogVisible = bloodMageModule.bloodLogFrame:IsShown()
                end
            end
            if currentDB.totalPlayedTime and currentDB.addonRuntimeAtLastPlayedSync then
                currentDB.uptimeGrace = currentDB.totalPlayedTime - currentDB.addonRuntimeAtLastPlayedSync
            end
			currentDB.dataSignature = Purity:CreateDataSignature(currentDB)
		end
		return

    elseif event == "PLAYER_LOGIN" then
        OnPlayerLogin()
        self:UnregisterEvent("PLAYER_LOGIN")
        return

    elseif event == "PLAYER_ENTERING_WORLD" then
        Purity:EnforceDefaultClassColors()
        local currentDB = Purity:GetDB()
        local currentGUID = UnitGUID("player")

        Purity:PerformIntegrityCheck()
		
		if Purity.GlobalModules["GLASS_HEART"] then
             local gh = Purity.GlobalModules["GLASS_HEART"]
             if gh.InitializeGroupFrames then gh:InitializeGroupFrames() end
             if gh.InitializeNameplates then gh:InitializeNameplates() end
        end

		if currentDB.isOptedIn and currentDB.addonVersion ~= Purity.Version then
            Purity:PerformSecurityAudit(currentDB)
        end

        -- MIGRATION LOGIC: Check for GUID Mismatch (Transfer)
        if currentDB.playerGUID and currentDB.playerGUID ~= currentGUID then
            -- Instead of resetting immediately, we attempt to migrate the data
            Purity:AttemptDataMigration(currentDB, currentGUID)
        end
    
        Purity.CreateCoreUI()
        
        Purity:SyncSecureStateFromDB()
        
        C_Timer.After(7, function()
             JoinChannelByName("PurityUsers", "a-unique-password")
             
             Purity.secretPing = "purity_id_ping_" .. tostring(math.random(1000, 9999))
             SendChatMessage(Purity.secretPing, "CHANNEL", nil, "PurityUsers")
        end)
        
        local currentDB = Purity:GetDB()
        if currentDB.isMigrating then
             Purity:ShowWarningBanner("Purity needs to finalize an update. Please log out or reload your UI to continue.", 30, 1)
        end
        
        if Purity.GlobalModules and Purity.GlobalModules.BLOOD_MAGE_BARGAIN then
            local bloodMageModule = Purity.GlobalModules.BLOOD_MAGE_BARGAIN
            if bloodMageModule.StartBroadcasting then bloodMageModule:StartBroadcasting() end
            if bloodMageModule.InitializeGroupFrames then bloodMageModule:InitializeGroupFrames() end
            if bloodMageModule.InitializeNameplates then bloodMageModule:InitializeNameplates() end
        end
        
        if not currentDB.isOptedIn and not currentDB.isMigrating then
            local hasAvailableChallenges = Purity:LoadClassModule()
            if UnitLevel("player") == 1 and hasAvailableChallenges then
                Purity.optInFrame:Show()
            else
                if not currentDB.hasBeenNotifiedOfLevelCap then
                    print("|cffFFFF00Purity:|r A Purity Challenge can only be started at level 1.")
                    currentDB.hasBeenNotifiedOfLevelCap = true
                end
            end
        end

        local currentDB = Purity:GetDB()
        if not currentDB.isMigrating then
             Purity:SilentRequestTimePlayed()
        end
        
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        return

	elseif event == "TIME_PLAYED_MSG" then
        local totalTime, _ = ...
        local currentDB = Purity:GetDB()
        
        -- MIGRATION LOGIC: Handle the time check
        if currentDB.isMigrating then
            local storedTime = currentDB.totalPlayedTime or 0
            local diff = totalTime - storedTime
            
            -- 4. Check for 15 minutes (900 seconds) max missing time
            -- We allow a small negative diff just in case of slight server clock variations, but mostly check positive gap.
            if diff <= 900 then
                -- 5. Update GUID and Hash
                currentDB.playerGUID = UnitGUID("player")
                currentDB.addonVersion = Purity.Version
                
                -- Regenerate the signature with the NEW GUID and NEW Version
                currentDB.dataSignature = Purity:CreateDataSignature(currentDB)
                
                -- Clear migration flag
                currentDB.isMigrating = nil
                
                print("|cff00FF00Purity:|r Data successfully migrated to TBC! Your GUID has been updated and your challenge continues.")
            else
                -- Fail: Too much missing time implies unmonitored play during transfer
                print("|cffFF0000Purity:|r Migration failed! Time discrepancy is too large (" .. diff .. " seconds). Limit is 15 minutes. Challenge reset.")
                currentDB.isMigrating = nil
                Purity:InternalResetChallenge()
                currentDB.playerGUID = UnitGUID("player") -- Set new GUID for fresh start
            end
            return -- Stop processing standard time updates for this specific event
        end
		if totalTime then
			currentDB.totalPlayedTime = totalTime
            currentDB.addonRuntimeAtLastPlayedSync = currentDB.addonRuntime
			if currentDB.isAwaitingInitialUptimeSync then
				currentDB.addonRuntime = totalTime
				currentDB.isAwaitingInitialUptimeSync = nil
			end
		end
		if Purity.mainInterfaceFrame and Purity.mainInterfaceFrame:IsShown() and Purity.statusPane:IsShown() then
			Purity:UpdateAndGetStatusStrings()
		end
		return
	
    elseif event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "Purity" then
            if not GetBindingKey("PURITY_TOGGLE") then
                SetBinding("PURITY_TOGGLE", "SHIFT-P");
            end
            local db = Purity:GetDB()
            if db and db.isOptedIn then
                Purity:LoadClassModule()
                Purity:ActivateMonitoring()
                local activeChallenge = Purity:GetActiveChallengeObject()
                if activeChallenge and activeChallenge.InitializeOnPlayerEnterWorld then
                    activeChallenge:InitializeOnPlayerEnterWorld()
                end
				local bloodMageModule = Purity.GlobalModules and Purity.GlobalModules.BLOOD_MAGE_BARGAIN
                if bloodMageModule and bloodMageModule.ManageBloodRegen then
                    bloodMageModule:ManageBloodRegen()
                end
            end
        end
        return
    end
end)

function Purity:AttemptDataMigration(db, newGUID)
    -- 1. Check if the stored data is valid (integrity check using OLD GUID)
    -- We must verify the data signature matches the OLD GUID before we allow a transfer.
    -- We try the current signature method and older versions just in case.
    
    local oldSignature = db.dataSignature
    local isValid = false

    -- Try checking integrity using Current and Legacy signatures
    if Purity:CreateDataSignature(db) == oldSignature then isValid = true end
    if not isValid and Purity:CreateDataSignature_Legacy(db) == oldSignature then isValid = true end

    -- 2. "Make sure it's an era file" (Check version/format validity)
    -- If the hash validation passed, we know it's a valid Purity file. 
    -- We can also check if the status is active.
    if db.status == "Failed" or db.status == "Not Participating" then
        isValid = false 
    end

    if not isValid then
        print("|cffFF0000Purity:|r Transfer detected, but data verification failed (Hash Mismatch or Inactive Run). Challenge reset.")
        Purity:InternalResetChallenge()
        -- Update to new GUID after reset so they can start fresh
        db.playerGUID = newGUID
        return
    end

    -- 3. Trigger Time Check
    -- If hash is good, we flag for migration and request time played to ensure no gaps.
    print("|cffFFFF00Purity:|r Character transfer detected. Verifying play time integrity...")
    db.isMigrating = true 
    Purity:SilentRequestTimePlayed() 
end

Purity.isActionTooltip = false

local function Purity_AdjustTooltipWidth(self)
    local padding = 30 
    local maxWidth = 0

    for i = 1, self:NumLines() do
        local leftLine = _G[self:GetName() .. "TextLeft" .. i]
        
        if leftLine and leftLine:IsShown() then
            local textWidth = leftLine:GetStringWidth()
            if textWidth > maxWidth then
                maxWidth = textWidth
            end
        end
    end

    if maxWidth > 0 and (maxWidth + padding) > self:GetWidth() then
        self:SetWidth(maxWidth + padding)
    end
end

local function Purity_OnTooltipSetUnit_Handler(self)
    local unit = select(2, self:GetUnit())
    if not unit or not UnitIsPlayer(unit) then return end

    local unitName = UnitName(unit)
    local rosterData
    for key, data in pairs(Purity.roster) do
        if key:match("([^-]+)") == unitName then
            rosterData = data
            break
        end
    end

    if not (rosterData and rosterData.challenge == "The Blood Mage's Bargain" 
            and (rosterData.status == "Passing" or rosterData.status == "Temporary Failure - Uptime")
            and (rosterData.ob_rank and rosterData.ob_rank > 0)) then
        return
    end

    local _, unitClass = UnitClass(unit)
    if string.upper(unitClass or "") == "PALADIN" then
        local line = _G[self:GetName() .. "TextLeft2"]
        if line then
            local originalText = line:GetText()
            if originalText and originalText:find(unitClass) then
                local overrideData = Purity.BLOODMAGE_CLASS_OVERRIDES["PALADIN"]
                local replacementString = "|cff" .. overrideData.colorHex .. overrideData.name .. "|r"
                line:SetText(string.gsub(originalText, unitClass, replacementString))
            end
        end
    end
end

function Purity:Serialize(data)
    if not data then return "" end
    local parts = {}
    for key, value in pairs(data) do
        if value ~= nil then 
            table.insert(parts, key .. "=" .. tostring(value))
        end
    end
    return table.concat(parts, ";")
end

function Purity:Deserialize(str)
    local data = {}
    for pair in string.gmatch(str, "([^;]+)") do
        local key, value = pair:match("([^=]+)=(.*)")
        if key and value then
            if value == "true" then
                data[key] = true
            elseif value == "false" then
                data[key] = false
            elseif tonumber(value) then
                data[key] = tonumber(value)
            else
                data[key] = value
            end
        end
    end
    return data
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", function(self, event, ...)
    local msg = select(1, ...)
    local channelName = select(9, ...)

    if msg == "!purity_ping" and channelName == "PurityUsers" then
        return true 
    end

    return false 
end)

local function Purity_OnTooltipSetSpell_Handler(self)
    if Purity.isActionTooltip then return end

    local activeChallenge = Purity:GetActiveChallengeObject()
    if not activeChallenge then return end

    local spellName, spellId = self:GetSpell()
    if not spellId then return end

    -- [[ 1. FORBIDDEN SPELLS ]]
    if activeChallenge.IsSpellForbidden and activeChallenge:IsSpellForbidden(spellId) then
        local challengeName = Purity:GetDB().challengeTitle or "Purity Challenge"
        self:AddLine(" ")
        self:AddLine("Forbidden by your " .. challengeName .. ".", 1, 0.1, 0.1)
        self:Show()
    end

    -- [[ 2. BLOOD MAGE COSTS ]]
    local bloodMageModule = Purity.GlobalModules and Purity.GlobalModules.BLOOD_MAGE_BARGAIN
    if bloodMageModule and activeChallenge.id == bloodMageModule.id then
        if spellName and not bloodMageModule.healingSpells[spellName] then
            local bloodCost = bloodMageModule:GetBloodCostForSpell(spellId)
            if bloodCost and bloodCost > 0 then
                local weakenedCost = math.max(1, math.floor(bloodCost * 2.0))
                local costToDisplay = bloodMageModule.sanguineWeaknessActive and weakenedCost or bloodCost

                self:AddLine(" ")
                self:AddLine(costToDisplay .. " Blood", 1.0, 0.2, 0.2)
                self:Show()
            end
        end
    end

    -- [[ 3. CONDUIT: BLINK ]]
    if activeChallenge.challengeName == "Conduit of Purity" and spellName == "Blink" then
        -- Loop through lines to find the description and append to it
        for i = 1, self:NumLines() do
            local line = _G[self:GetName() .. "TextLeft" .. i]
            if line then
                local text = line:GetText()
                -- Blink's description always starts with "Teleports"
                if text and string.find(text, "Teleports") then
                    line:SetText(text .. " Instantly generates 20 Static Charge.")
                    self:Show() -- Force the tooltip to resize for the wider text
                    break
                end
            end
        end
    end
end

local function Purity_OnTooltipSetItem_Handler(self)
    if Purity.isActionTooltip then return end

    local activeChallenge = Purity:GetActiveChallengeObject()
    if not activeChallenge or not activeChallenge.IsItemForbidden then return end
    
    local db = Purity:GetDB()
    if not db then return end

    local _, itemLink = self:GetItem()
    
    if itemLink and activeChallenge:IsItemForbidden(itemLink) then
        local challengeName = db.challengeTitle or "Purity Challenge"
        
        self:AddLine(" ")
        self:AddLine("Forbidden by your " .. challengeName .. ".", 1, 0.1, 0.1)
        
        self:Show()
    end
end

GameTooltip:HookScript("OnTooltipSetItem", Purity_OnTooltipSetItem_Handler)
GameTooltip:HookScript("OnTooltipSetSpell", Purity_OnTooltipSetSpell_Handler)

local function Purity_GeneralTooltip_OnShow_Handler(self)
    if Purity.isActionTooltip then return end

    local activeChallenge = Purity:GetActiveChallengeObject()
    if not activeChallenge or activeChallenge.id ~= "BLOOD_MAGE_BARGAIN" then return end

    -- Keep only the Blood Mage / Stat logic here
    local left1 = _G[self:GetName() .. "TextLeft1"]
    if left1 then
        local text = left1:GetText()
        if text then
            if text == STAT_SPIRIT or (text.find and text:find("Spirit")) then
                self:AddLine("Reduces blood cost of your spells.")
                self:Show()
            elseif text == STAT_STAMINA or (text.find and text:find("Stamina")) then
                self:AddLine("Increases your blood pool.")
                self:Show()
            end
        end
    end
end

hooksecurefunc(GameTooltip, "SetTalent", function(self, tabIndex, talentIndex)
    local activeChallenge = Purity:GetActiveChallengeObject()
    if not (activeChallenge and activeChallenge.IsTalentForbidden) then return end

    if activeChallenge:IsTalentForbidden(tabIndex) then
        local challengeName = Purity:GetDB().challengeTitle or "Purity Challenge"
        self:AddLine(" ", 0, 0, 0, 0)
        self:AddLine("Forbidden by your " .. challengeName .. ".", 1, 0.1, 0.1)
        self:Show()
    end
	
	if activeChallenge.GetCustomTalentTooltip then
        local title, description = activeChallenge:GetCustomTalentTooltip(tabIndex, talentIndex)
        if title then
            self:ClearLines()
            self:AddLine(title, 1, 0, 0)
            self:AddLine(description, 1, 0.82, 0, true)
            self:Show()
        end
    end
end)

if not Original_GameTooltip_SetAction then
    Original_GameTooltip_SetAction = GameTooltip.SetAction
end

GameTooltip.SetAction = function(self, actionSlot)
    Purity.isActionTooltip = true
    Original_GameTooltip_SetAction(self, actionSlot)

    local activeChallenge = Purity:GetActiveChallengeObject()
    if not activeChallenge then
        Purity.isActionTooltip = false
        return
    end

    local actionType, id, subType = GetActionInfo(actionSlot)
    local spellId = nil

    -- Resolve the actual Spell ID from the Action Slot
    if actionType == "spell" then
        spellId = id
    elseif actionType == "macro" then
        -- WoW's API changed in 8.0.1. Modern/Classic clients return the ID first.
        -- Older clients returned: name, rank, ID. This covers all versions.
        local v1, v2, v3 = GetMacroSpell(id)
        if type(v1) == "number" then
            spellId = v1
        elseif type(v3) == "number" then
            spellId = v3
        end
    end

    if spellId then
        local spellName = GetSpellInfo(spellId)

        -- [[ 1. FORBIDDEN SPELLS ]]
        if activeChallenge.IsSpellForbidden and activeChallenge:IsSpellForbidden(spellId) then
            local challengeName = Purity:GetDB().challengeTitle or "Purity Challenge"
            self:AddLine(" ")
            self:AddLine("Forbidden by your " .. challengeName .. ".", 1, 0.1, 0.1)
            self:Show()
        end

        -- [[ 2. BLOOD MAGE COSTS (Macro Support) ]]
        local bloodMageModule = Purity.GlobalModules and Purity.GlobalModules.BLOOD_MAGE_BARGAIN
        if bloodMageModule and activeChallenge.id == bloodMageModule.id then
            if spellName and not bloodMageModule.healingSpells[spellName] then
                local bloodCost = bloodMageModule:GetBloodCostForSpell(spellId)
                if bloodCost and bloodCost > 0 then
                    local weakenedCost = math.max(1, math.floor(bloodCost * 2.0))
                    local costToDisplay = bloodMageModule.sanguineWeaknessActive and weakenedCost or bloodCost

                    self:AddLine(" ")
                    self:AddLine(costToDisplay .. " Blood", 1.0, 0.2, 0.2)
                    self:Show()
                end
            end
        end

        -- [[ 3. CONDUIT: BLINK ]]
        if activeChallenge.challengeName == "Conduit of Purity" and spellName == "Blink" then
            -- Loop through lines to find the description
            for i = 1, self:NumLines() do
                local line = _G[self:GetName() .. "TextLeft" .. i]
                if line then
                    local text = line:GetText()
                    if text and string.find(text, "Teleports") then
                        line:SetText(text .. " Instantly generates 20 Static Charge.")
                        self:Show()
                        break
                    end
                end
            end
        end
    end
    
    Purity.isActionTooltip = false
end

GameTooltip:HookScript("OnUpdate", Purity_TooltipOnUpdateHandler)

-- Export ONLY harmless UI functions to the global environment
_G.Purity_UI = {
    TogglePanel = Purity.TogglePanel,
    -- Add any other purely visual functions here if necessary
}

-- Make sure your Slash Command points to the local table, not a global one
SLASH_PURITY1 = "/purity"
SlashCmdList["PURITY"] = function(msg)
    Purity:SlashCommand(msg)
end