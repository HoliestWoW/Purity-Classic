-- Purity AddOn - Core

BINDING_HEADER_PURITY = "Purity";
BINDING_NAME_PURITY_TOGGLE = "Toggle Purity Window";

if not Purity then
    Purity = {}
end

Purity.Version = "9.1.2"

Purity.ADDON_PREFIX = "PURITYCOMMS"
Purity.roster = {}

Purity_Warning = "NOTICE: The integrity of this character's challenge data is paramount. Any manual modification will be detected and will result in the forfeiture of your run."
Purity_PerCharacterDB = Purity_PerCharacterDB
Purity_GlobalDB = Purity_GlobalDB

Purity.isTrainerHooked = false
Purity.ClassModules = {}
Purity.GlobalModules = {}
Purity.GlobalModules["DK_PATH_PLACEHOLDER"] = {
    id = "DK_PATH_PLACEHOLDER",
    challengeName = "Path of the Damned",
    GetRulesText = function() 
        return {
            "|cffffd100Your Path is Set:|r",
            "|cff261A0D  • Your only task is to reach level 55 or higher.|r",
            "|cff261A0D  • Once ready, go to the 'Death Knight' tab in the Purity window to complete the sacrifice.|r"
        }
    end
    -- This challenge has no special rules or event handlers.
}
Purity.selectedChallenge = nil
Purity.hasUIBeenCreated = false

local MAX_PLAYER_LEVEL = 90
local isMonitoring = false
local weaponTimer = nil
local purityRuntimeTicker = nil
local purityPlayedTimeTicker = nil
local uptimeMonitorTicker = nil
local activeClassModule = nil
local monitorFrame = nil
local trainerKey = "a7K9!zPq@3rT$5wX&8nMbVcFgHjL"

Base64 = {}
local b64_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

-- Create a reverse lookup map for efficient and safe decoding
local b64_map = {}
for i = 1, #b64_chars do
    b64_map[b64_chars:sub(i, i)] = i - 1
end

function Base64.encode(data)
    local result = {}
    local len = #data
    for i = 1, len, 3 do
        local b1 = data:byte(i)
        local b2 = data:byte(i + 1) or 0
        local b3 = data:byte(i + 2) or 0

        local combined = bit.bor(bit.lshift(b1, 16), bit.lshift(b2, 8), b3)

        table.insert(result, b64_chars:sub(bit.rshift(combined, 18) + 1, bit.rshift(combined, 18) + 1))
        table.insert(result, b64_chars:sub(bit.band(bit.rshift(combined, 12), 0x3F) + 1, bit.band(bit.rshift(combined, 12), 0x3F) + 1))
        table.insert(result, b64_chars:sub(bit.band(bit.rshift(combined, 6), 0x3F) + 1, bit.band(bit.rshift(combined, 6), 0x3F) + 1))
        table.insert(result, b64_chars:sub(bit.band(combined, 0x3F) + 1, bit.band(combined, 0x3F) + 1))
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

function Base64.decode(data)
    data = string.gsub(data, '[^A-Za-z0-9+/=]', '')
    local decoded_bits = (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local val = b64_map[x]
        if not val then return '' end
        local bits = ''
        for i = 5, 0, -1 do
            bits = bits .. ( (val >= 2^i) and '1' or '0' )
            if val >= 2^i then val = val - 2^i end
        end
        return bits;
    end))

    local result = {}
    for i = 1, #decoded_bits, 8 do
        local byte_str = decoded_bits:sub(i, i+7)
        if #byte_str == 8 then
            table.insert(result, string.char(tonumber(byte_str, 2)))
        end
    end
    return table.concat(result)
end

local hidePlayedTimeCounter = 0
if Purity.OriginalDisplayDisplayTimePlayed == nil then
    Purity.OriginalDisplayDisplayTimePlayed = ChatFrame_DisplayTimePlayed
    ChatFrame_DisplayTimePlayed = function(...)
        if hidePlayedTimeCounter > 0 then
            hidePlayedTimeCounter = hidePlayedTimeCounter - 1
            return
        end
        return Purity.OriginalDisplayDisplayTimePlayed(...)
    end
end

Purity.ChallengeCoefficients = {
	["Path of the Unburdened"] = 5.00,
	["Path of Resilience"] = 4.86,
	["Sigil of Purity"] = 4.65,
	["Brand of Purity"] = 4.35,
	["Quiver of Purity"] = 4.45,
	["Path of Humility"] = 4.40,
    ["Ashes of Purity"] = 4.35,
	["Fisherman's Folly"] = 4.32,
	["Libram of Purity"] = 4.25,
	["Chalice of Purity"] = 4.15,
	["Tome of Purity (Arcane)"] = 4.05,
	["Astrolabe of Purity"] = 4.00,
	["Gauntlets of Purity"] = 3.95,
	["Flame of Purity"] = 3.91,
	["Phylactery of Purity"] = 3.89,
	["Sacrament of Purity"] = 3.85,
	["Pact of Purity"] = 3.85,
	["Bond of Purity"] = 3.80,
	["Testament of Purity"] = 3.77,
    ["The Drunken Master"] = 3.65,
	["Bindings of Purity"] = 3.45,
	["Oath of Purity"] = 3.23,
	["Contract of Purity"] = 3.20,
	["Covenant of Purity"] = 3.00,
	["Bulwark of Purity"] = 2.75,
	["Communion of Purity"] = 2.68,
	["Grimoire of Purity"] = 2.25,
	["Tome of Purity (Fire)"] = 2.27,
	["Tome of Purity (Frost)"] = 2.14,
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

-- Add this function to Purity.lua
function Purity:IsHardcoreStatusValid()
    -- Check if the Hardcore addon's global tables exist
    if not Hardcore_Character or not Hardcore_GetSecurityStatus then
        return false, "Hardcore addon not detected."
    end
    
    -- Check the checksum to ensure the Hardcore data hasn't been tampered with
    if Hardcore_GetSecurityStatus() ~= "OK" then
        return false, "Hardcore data security check failed."
    end
    
    -- Check if the character has failed the challenge
    local status = Hardcore_Character.verification_status
    if status == "FAIL" then
        return false, "Hardcore challenge is marked as 'FAIL'."
    end
    
    -- All checks passed
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

    for i = 1, 40 do
        local auraName = UnitAura("player", i)
        if auraName and auraName == "Self-Found Adventurer" then
            isNowSelfFound = true
            isNowHardcore = true
            break
        end
    end

    if wasHardcore ~= isNowHardcore or wasSelfFound ~= isNowSelfFound or wasSSF ~= isNowSSF then
        db.isHardcoreRun = isNowHardcore
        db.isSelfFoundRun = isNowSelfFound
        db.isSSFRun = isNowSSF
        if db.isOptedIn then
        end
    end
end

function Purity:StartModifierMonitor()
    if self.modifierTicker then self.modifierTicker:Cancel() end

    self.modifierTicker = C_Timer.NewTicker(5, function()
        self:UpdateAllModifierStatuses()
    end)
end

function Purity:GetCurrentChallengeInfo(db_override)
    local db = db_override or self:GetDB()
    if not db or not db.challengeTitle then
        return nil, 0
    end

    local challengeKey = db.challengeTitle 
    local activeChallenge = self:GetActiveChallengeObject()
    local specifier = nil
    if activeChallenge and activeChallenge.GetChallengeSpecifier then
        specifier = activeChallenge:GetChallengeSpecifier()
    end

    if challengeKey == "The Ascetic's Path" and specifier then
        if specifier == "EASY" then challengeKey = "Path of Humility"
        elseif specifier == "MEDIUM" then challengeKey = "Path of Resilience"
        elseif specifier == "HARD" then challengeKey = "Path of the Unburdened" end
    elseif string.find(challengeKey, "Tome of Purity") and specifier then
        challengeKey = string.format("Tome of Purity (%s)", specifier:sub(1,1):upper()..specifier:sub(2):lower())
    end

    local coefficient = Purity.ChallengeCoefficients[challengeKey] or 1.0
    
    if db.challengeTitle == "Path of the Damned" then
        coefficient = 0
    end
    
    return challengeKey, coefficient
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

function Purity:GetGlobalDB()
    if Purity_GlobalDB == nil then
        self:InitializeGlobalDatabase()
    end
    return Purity_GlobalDB
end

function Purity:InitializeGlobalDatabase()
    if Purity_GlobalDB == nil then
        Purity_GlobalDB = {}
    end
    local defaults = {
        dk_token = nil
    }
    for key, value in pairs(defaults) do
        if Purity_GlobalDB[key] == nil then
            Purity_GlobalDB[key] = value
        end
    end
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
                if challengeData.id == challengeID then
                    return challengeData
                end
            end
        else
            if (activeClassModule.id and activeClassModule.id == challengeID) or (activeClassModule.challengeName and activeClassModule.challengeName == challengeID) then
                return activeClassModule
            end
        end
    end
    
    return nil -- Return nil if no match is found
end

function Purity:SilentRequestTimePlayed()
    hidePlayedTimeCounter = hidePlayedTimeCounter + 1
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

function Purity:CreateSeparator(parent, width, height)
    local separator = parent:CreateTexture(nil, "ARTWORK")
    -- We use a generic white pixel texture from the game files that can be stretched and colored
    separator:SetTexture("Interface\\Common\\White_Square") 
    separator:SetSize(width, height)
    -- Set the line color to a nice, subtle gold
    separator:SetVertexColor(1, 0.82, 0, 0.5) 
    return separator
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
    Purity:InitializeGlobalDatabase()
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
		physicalStrikes = 0,
		activeChallengeModuleType = nil,
		fishingFishedItemLinks = {},
        uptimeIsUnverified = false,
        failureReason = "N/A",
		isHardcoreRun = false,
		isSelfFoundRun = false,
		isSSFRun = false,
		dkShowPanelOnLogin = nil,
		challengeStats = {},
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

function Purity:InternalResetChallenge()
    local db = Purity:GetDB()
    
    db.isOptedIn = false
    db.status = "Not Participating"
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
                -- Handle special case with multiple names
                self.ChallengeTypeMap["Path of Humility"] = "Global"
                self.ChallengeTypeMap["Path of Resilience"] = "Global"
                self.ChallengeTypeMap["Path of the Unburdened"] = "Global"
            elseif module.challengeName then
                self.ChallengeTypeMap[module.challengeName] = "Global"
            end
        end
    end

    -- Process Class-Specific Modules
    if self.ClassModules then
        for className, classModule in pairs(self.ClassModules) do
            local friendlyClassName = className:sub(1,1) .. className:sub(2):lower()
            if classModule.challenges then -- Module contains a table of challenges
                for _, challengeData in pairs(classModule.challenges) do
                    self.ChallengeTypeMap[challengeData.challengeName] = friendlyClassName
                end
            elseif classModule.challengeName then -- Module is a single challenge
                if classModule.challengeName == "Tome of Purity" then
                    -- Handle special case with multiple names
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
    elseif challenge == "Tome of Purity" and stats.primarySpellCasts then
        message = string.format("Fun fact: During your studies, you cast your primary spell %d times!", stats.primarySpellCasts)
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
    elseif challenge == "Chalice of Purity" and stats.risingSunKicks then
        message = string.format("Fun fact: To maintain your clarity, you performed Rising Sun Kick %d times!", stats.risingSunKicks)
    elseif challenge == "Bindings of Purity" and stats.fistsOfFuryCasts then
        message = string.format("Fun fact: As an unmoving mountain, you unleashed Fists of Fury %d times!", stats.fistsOfFuryCasts)
    elseif challenge == "Gauntlets of Purity" and stats.tigerPalms then
        message = string.format("Fun fact: With hands of stone, you struck with Tiger Palm %d times!", stats.tigerPalms)
    elseif challenge == "Ashes of Purity" and stats.deathCoils then
        message = string.format("Fun fact: From the ashes, you flung coils of deathly energy %d times!", stats.deathCoils)
    elseif challenge == "Sigil of Purity" and stats.deathStrikes then
        message = string.format("Fun fact: Wielding your mighty weapon, you sustained yourself with Death Strike %d times!", stats.deathStrikes)
    elseif challenge == "The Drunken Master" and stats.moneySpent then
        local money = stats.moneySpent
        local gold = math.floor(money / 10000)
        local silver = math.floor((money % 10000) / 100)
        local copper = money % 100
        local moneyString = string.format("%dg %ds %dc", gold, silver, copper)
        message = string.format("Fun fact: To maintain your buzz, you spent %s on drinks!", moneyString)
    elseif challenge == "Fisherman's Folly" then
        local fishCount = stats.totalCatches or 0
        local trunkCount = stats.trunksFished or 0
        message = string.format("Fun fact: During your folly, you had %d successful catches, including %d trunks!", fishCount, trunkCount)
    elseif challenge == "The Ascetic's Path" and stats.forbiddenItemsSold then
        message = string.format("Fun fact: On your path of self-denial, you sold %d items that you were forbidden to equip!", stats.forbiddenItemsSold)
    end

    if message then
        print("|cffFFFF00Purity:|r " .. message)
    end
end

function GeneratePurityDKToken(futureDKName)
    local charDB = Purity:GetDB()
    if charDB.status == "Sacrificed" then
        print("|cffFFFF00Purity:|r |cffFFD100This character's vow has already been transferred. Their sacrifice is complete.|r")
        return false
    end
    local token_data = {}
    local _, class = UnitClass("player")
    if charDB.destinedDKChallenge == "Phylactery of Purity" then
        local hasTalent = false; local i = 1
        while true do
            local name, _, _, _, points = GetTalentInfo(1, i); if not name then break end
            if name == "Shadow Embrace" and points > 0 then hasTalent = true; break; end
            i = i + 1
        end
        if class ~= "WARLOCK" or not hasTalent then
            print("|cffFFFF00Purity:|r |cffFF0000Sacrifice Failed! This vow requires a Warlock with the Shadow Embrace talent.|r")
            return false
        end
        token_data.legacy = "PHYLACTERY"
    else 
        local _, coeff = Purity:GetCurrentChallengeInfo(charDB)
        token_data.id = charDB.destinedDKChallengeID
        token_data.name = charDB.destinedDKChallenge
        token_data.vow = coeff
    end
    token_data.time = charDB.totalPlayedTime or 0
    token_data.run = charDB.addonRuntime or 0
    token_data.sac_char = UnitName("player") .. "-" .. GetRealmName()
    token_data.dk_name = string.upper(futureDKName)
    local signaturePayload = (token_data.id or token_data.legacy) .. token_data.dk_name .. token_data.sac_char .. tostring(token_data.time)
    token_data.sig = Purity:GenerateVerificationHash(signaturePayload)
    local serialized_parts = {}
    for k, v in pairs(token_data) do
        table.insert(serialized_parts, k .. ":" .. tostring(v))
    end
    local vowString = table.concat(serialized_parts, ";")
    local encodedString = Base64.encode(vowString)
    charDB.status = "Sacrificed"
    charDB.completionDate = date("%Y-%m-%d %H:%M:%S")
    charDB.sacrificedForDKName = futureDKName
    charDB.generatedVowString = encodedString
    Purity:ShowVowStringPopup(encodedString, futureDKName)
    return true
end

function ApplyPurityDKToken(encodedString)
	local function failActivation(message)
		print("|cffFFFF00Purity:|r |cffFFD100" .. message .. "|r")
		return false
	end
    if not encodedString or encodedString == "" then return failActivation("Vow String cannot be empty.") end
    local decodedString
    pcall(function() decodedString = Base64.decode(encodedString) end)
    if not decodedString then return failActivation("Error: The Vow String is invalid or corrupt.") end
    local token_data = {}
    for pair in string.gmatch(decodedString, "([^;]+)") do
        local k, v = pair:match("([^:]+):(.*)")
        if k and v then token_data[k] = tonumber(v) or v end
    end
    if not (token_data.dk_name and token_data.sac_char and token_data.sig) then
        return failActivation("Error: This Vow String is outdated or is not a secure, character-locked string.")
    end
    local signaturePayload = (token_data.id or token_data.legacy) .. token_data.dk_name .. token_data.sac_char .. tostring(token_data.time)
    local expectedSig = Purity:GenerateVerificationHash(signaturePayload)
    if token_data.sig ~= expectedSig then
        return failActivation("Error: The Vow String signature is invalid. The data may be corrupt or tampered with.")
    end
    if token_data.dk_name ~= string.upper(UnitName("player")) then
        return failActivation("Error: This Vow String was created for a character named '" .. token_data.dk_name:sub(1,1) .. token_data.dk_name:sub(2):lower() .. "'. It cannot be used by this character.")
    end
    local charDB = Purity:GetDB()
    charDB.isOptedIn = true; charDB.status = "Passing"; charDB.startDate = date("%Y-%m-%d %H:%M:%S")
    charDB.playerGUID = UnitGUID("player"); charDB.addonVersion = Purity.Version; charDB.isAwaitingInitialUptimeSync = true
    charDB.sacrificedPlayedTime = token_data.time or 0; charDB.sacrificedRuntime = token_data.run or 0
    charDB.activeChallengeModuleType = "Class"
    if token_data.legacy == "PHYLACTERY" then
        charDB.challengeTitle = "Phylactery of Purity"
        charDB.activeChallengeID = "DK_PHYLACTERY"
    else
        if not (token_data.id and token_data.name and token_data.vow) then return failActivation("Error: The Vow String is missing required data.") end
        if token_data.id == "DK_ASHES" then
            charDB.status = "Awaiting Bag Confirmation"
        end
        charDB.challengeTitle = token_data.name
        charDB.activeChallengeID = token_data.id
        charDB.inheritedVowCoefficient = token_data.vow or 0
    end
	Purity:ActivateMonitoring()
    print("|cffFFFF00Purity:|r |cff00FF00The vow from " .. token_data.sac_char .. " has been successfully transferred. Your challenge, '"..charDB.challengeTitle.."', begins now!|r")
    charDB.dkShowPanelOnLogin = false
    return true
end

function Purity:DisplayDKPane()
    if self.dkPane.content then
        for _, widget in ipairs(self.dkPane.content) do widget:Hide() end
    end
    self.dkPane.content = {}

    local charDB = self:GetDB()
    local _, playerClass = UnitClass("player")
    local yOffset = -25

    local function CreateText(parent, text, font, justify, yOff)
        local label = parent:CreateFontString(nil, "ARTWORK", font or "GameFontNormal")
        label:SetPoint("TOP", parent, "TOP", 0, yOff)
        label:SetWidth(400); label:SetJustifyH(justify or "CENTER"); label:SetText(text)
        table.insert(Purity.dkPane.content, label)
        return label
    end
    
    local function CreateDKButton(parent, text, yOff)
        local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        button:SetSize(200, 30); button:SetPoint("TOP", parent, "TOP", 0, yOff); button:SetText(text)
        table.insert(Purity.dkPane.content, button)
        return button
    end

	if playerClass == "DEATHKNIGHT" then
        CreateText(self.dkPane, "Death Knight Activation", "GameFontNormalHuge", "CENTER", yOffset); yOffset = yOffset - 40
        CreateText(self.dkPane, "If you have sacrificed another character, paste their Vow String into the box below and click Activate.", "GameFontNormal", "LEFT", yOffset); yOffset = yOffset - 60
        local vowInputBox = CreateFrame("EditBox", nil, self.dkPane)
        vowInputBox:SetPoint("TOPLEFT", self.dkPane, "TOPLEFT", 50, yOffset - 50); vowInputBox:SetPoint("TOPRIGHT", self.dkPane, "TOPRIGHT", -50, yOffset - 50)
        vowInputBox:SetHeight(100); vowInputBox:SetMultiLine(true); vowInputBox:SetAutoFocus(false); vowInputBox:SetFontObject(GameFontNormal)
        local input_bg = vowInputBox:CreateTexture(nil, "BACKGROUND"); input_bg:SetAllPoints(true); input_bg:SetColorTexture(0, 0, 0, 0.6)
        table.insert(self.dkPane.content, vowInputBox); self.dkPane.vowInputBox = vowInputBox; yOffset = yOffset - 120
        local activateButton = CreateDKButton(self.dkPane, "Activate Vow of Purity", yOffset)
		activateButton:SetScript("OnClick", function()
			self.dkPane.vowInputBox:ClearFocus()
			local vowString = self.dkPane.vowInputBox:GetText()
			if vowString and vowString ~= "" then
				local success = self:ApplyPurityDKToken(vowString)
				if success then self:selectTab("status") end
			else
				print("|cffFFFF00Purity:|r Please paste the Vow String into the box.")
			end
		end)
    
	elseif charDB.isOptedIn and charDB.destinedDKChallenge then
        if charDB.status == "Sacrificed" then
            -- THE FIX: This is the new view for a sacrificed character.
            CreateText(self.dkPane, "Sacrifice Complete", "GameFontNormalHuge", "CENTER", yOffset); yOffset = yOffset - 50
            CreateText(self.dkPane, "This character's vow has been transferred. You may copy the Vow String below for your new Death Knight.", "GameFontNormal", "LEFT", yOffset); yOffset = yOffset - 50
            
            if charDB.sacrificedForDKName then
                CreateText(self.dkPane, "Chosen DK Name: |cff00FF00" .. charDB.sacrificedForDKName .. "|r", "GameFontNormal", "CENTER", yOffset)
                yOffset = yOffset - 40
            end

            local vowDisplayBox = CreateFrame("EditBox", nil, self.dkPane)
            vowDisplayBox:SetPoint("TOPLEFT", self.dkPane, "TOPLEFT", 50, yOffset - 100)
            vowDisplayBox:SetPoint("TOPRIGHT", self.dkPane, "TOPRIGHT", -50, yOffset - 100)
            vowDisplayBox:SetHeight(120); vowDisplayBox:SetMultiLine(true); vowDisplayBox:SetAutoFocus(false); vowDisplayBox:SetFontObject(GameFontNormal)
            vowDisplayBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
            vowDisplayBox:SetText(charDB.generatedVowString or "Vow String not found.")
            vowDisplayBox:HighlightText()
            local bg = vowDisplayBox:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints(true); bg:SetColorTexture(0, 0, 0, 0.6)
            table.insert(self.dkPane.content, vowDisplayBox)

        elseif self.dkPane.isConfirming then
            -- This is the two-step confirmation logic, which is unchanged.
            CreateText(self.dkPane, "Complete Your Sacrifice", "GameFontNormalHuge", "CENTER", yOffset); yOffset = yOffset - 40
            CreateText(self.dkPane, "Your Death Knight will be named:", "GameFontNormal", "CENTER", yOffset); yOffset = yOffset - 30
            CreateText(self.dkPane, "|cff00FF00" .. self.dkPane.confirmedName .. "|r", "GameFontNormalLarge", "CENTER", yOffset); yOffset = yOffset - 45
            local warningText = "|cffFF4500WARNING:|r This is your final confirmation. This action is permanent and cannot be undone."
            local warningLabel = CreateText(self.dkPane, warningText, "GameFontNormal", "CENTER", yOffset); warningLabel:SetWidth(380); yOffset = yOffset - 80
            local finalSacrificeButton = CreateDKButton(self.dkPane, "Complete the Ritual", yOffset)
            finalSacrificeButton:GetFontString():SetTextColor(1, 0.5, 0.5)
            finalSacrificeButton:SetScript("OnClick", function()
                local success = self:GeneratePurityDKToken(self.dkPane.confirmedName)
                if success then
                    if self.mainInterfaceFrame then self.mainInterfaceFrame:Hide() end
                    self.dkPane.isConfirming = false; self.dkPane.confirmedName = nil
                end
            end)
            yOffset = yOffset - 40
            local backButton = CreateDKButton(self.dkPane, "Go Back", yOffset)
            backButton:SetScript("OnClick", function()
                self.dkPane.isConfirming = false; self.dkPane.confirmedName = nil
                self:DisplayDKPane()
            end)
        else
            -- This is the initial name entry view, which is also unchanged.
            CreateText(self.dkPane, "Complete Your Sacrifice", "GameFontNormalHuge", "CENTER", yOffset); yOffset = yOffset - 40
            CreateText(self.dkPane, "You have chosen the " .. charDB.destinedDKChallenge .. ". Your destiny awaits.", "GameFontNormal", "LEFT", yOffset); yOffset = yOffset - 50
            CreateText(self.dkPane, "Enter the name of the Death Knight you will create:", "GameFontNormal", "CENTER", yOffset); yOffset = yOffset - 25
            local dkNameInput = CreateFrame("EditBox", "PurityDKNameInput", self.dkPane, "InputBoxTemplate")
            dkNameInput:SetSize(200, 30); dkNameInput:SetPoint("TOP", 0, yOffset); dkNameInput:SetAutoFocus(false)
            table.insert(self.dkPane.content, dkNameInput); self.dkPane.dkNameInput = dkNameInput; yOffset = yOffset - 25
            local nameWarning = CreateText(self.dkPane, "|cffFF4500(Warning: This name must be exact or activation will fail!)|r", "GameFontNormalSmall", "CENTER", yOffset)
            nameWarning:SetFontObject(GameFontNormalSmallItalic); yOffset = yOffset - 70
            local playerLevel = UnitLevel("player")
            if playerLevel >= 55 and playerLevel <= 58 then
                local confirmButton = CreateDKButton(self.dkPane, "Confirm Name", yOffset)
                confirmButton:SetScript("OnClick", function()
                    local enteredName = self.dkPane.dkNameInput:GetText()
                    if not enteredName or enteredName == "" then print("|cffFFFF00Purity:|r |cffFF0000Error: You must enter a name.|r"); return
                    elseif #enteredName < 2 or #enteredName > 12 then print("|cffFFFF00Purity:|r |cffFF0000Error: Character names must be between 2 and 12 characters long.|r"); return end
                    self.dkPane.isConfirming = true; self.dkPane.confirmedName = enteredName
                    self:DisplayDKPane()
                end)
            else
                CreateText(self.dkPane, "|cffffd100You must be between level 55 and 58 to complete your sacrifice.|r", "GameFontNormal", "CENTER", yOffset)
            end
        end
    else
        CreateText(self.dkPane, "The Path of the Damned", "GameFontNormalHuge", "CENTER", yOffset); yOffset = yOffset - 40
        CreateText(self.dkPane, "Only those who have been predestined at level one may walk this path.", "GameFontNormal", "LEFT", yOffset)
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
    local darkColor = "|cff261a0d"

    local sortedChallenges = {}
    if not self.ChallengeCoefficients then return end
    for name, coeff in pairs(self.ChallengeCoefficients) do
        table.insert(sortedChallenges, {name = name, coeff = coeff})
    end

    table.sort(sortedChallenges, function(a, b)
        return a.coeff > b.coeff
    end)

    local yOffset = -15
    local lineSpacing = 22
    local totalHeight = 20

    for i, challengeData in ipairs(sortedChallenges) do
        local rankText = string.format("%d.", i)
        local challengeName = challengeData.name
        local coefficientText = string.format("%.2f", challengeData.coeff)

        -- Get the challenge type and format the final name string
        local challengeType = (self.ChallengeTypeMap and self.ChallengeTypeMap[challengeName]) or ""
        local challengeNameText = challengeName
		if challengeType ~= "" then
			local typeColor
			local classUpper = string.upper(challengeType)

			if classUpper == "SHAMAN" then
				typeColor = "|cff0070DD" -- Override with Blue for Shaman
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

        -- Create FontStrings for alignment
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

function Purity:CreateDataSignature_V1(db)
    if not db then return "" end
    local keysInOrder = {
        "activeChallengeID", "activeChallengeModuleType", "addonVersion",
        "challengeTitle", "completionDate", "hasBeenNotifiedOfLevelCap", "isOptedIn",
        "physicalStrikes", "playerGUID", "startDate", "status",
        "uptimeIsUnverified", "weaponInfractions", "fishingFishedItemLinks"
    }
    local stringToSign = ""

    for _, key in ipairs(keysInOrder) do
        local value = db[key]
        local value_str = ""
        if value ~= nil then
            if type(value) == "table" then
                local sortedLinks = {}
                if value then for link, _ in pairs(value) do table.insert(sortedLinks, link) end end
                table.sort(sortedLinks)
                value_str = table.concat(sortedLinks, "")
            elseif type(value) == "boolean" then
                value_str = (value and "true" or "false")
            else
                value_str = tostring(value)
            end
        end
        stringToSign = stringToSign .. value_str
    end

    stringToSign = stringToSign .. trainerKey
    
    local finalHash = self:GenerateVerificationHash(stringToSign)
    
    return finalHash
end

function Purity:CreateDataSignature_V2(db)
    if not db then return "" end
    local keysInOrder = {
        "activeChallengeID", "activeChallengeModuleType", "addonVersion",
        "challengeTitle", "completionDate", "hasBeenNotifiedOfLevelCap", "isOptedIn",
        "physicalStrikes", "playerGUID", "startDate", "status",
        "uptimeIsUnverified", "weaponInfractions", "fishingFishedItemLinks",
        "addonRuntime", "totalPlayedTime"
    }
    local stringToSign = ""
    for _, key in ipairs(keysInOrder) do
        local value = db[key]
        if value ~= nil then
            if type(value) == "table" then
                local sortedLinks = {}
                if value then for link, _ in pairs(value) do table.insert(sortedLinks, link) end end
                table.sort(sortedLinks)
                stringToSign = stringToSign .. table.concat(sortedLinks, "")
            elseif type(value) == "boolean" then
                stringToSign = stringToSign .. (value and "true" or "false")
            else
                stringToSign = stringToSign .. tostring(value)
            end
        end
    end
    stringToSign = stringToSign .. trainerKey
    return self:GenerateVerificationHash(stringToSign)
end

function Purity:CreateDataSignature_V3(db)
    if not db then return "" end
    local keysInOrder = {
        "activeChallengeID", "activeChallengeModuleType", "addonVersion",
        "challengeTitle", "completionDate", "hasBeenNotifiedOfLevelCap", "isOptedIn",
        "physicalStrikes", "playerGUID", "startDate", "status",
        "uptimeIsUnverified", "weaponInfractions", "fishingFishedItemLinks",
        "failureReason",
        "addonRuntime",
        "totalPlayedTime"
    }
    local stringToSign = ""
    for _, key in ipairs(keysInOrder) do
        local value = db[key]
        if value ~= nil then
            if type(value) == "table" then
                local sortedLinks = {}
                if value then for link, _ in pairs(value) do table.insert(sortedLinks, link) end end
                table.sort(sortedLinks)
                stringToSign = stringToSign .. table.concat(sortedLinks, "")
            elseif type(value) == "boolean" then
                stringToSign = stringToSign .. (value and "true" or "false")
            else
                stringToSign = stringToSign .. tostring(value)
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
        "drunkData"
    }
    local stringToSign = ""
    for _, key in ipairs(keysInOrder) do
        local value = db[key]
        if value ~= nil then
            if key == "fishingFishedItemLinks" then
                local sortedLinks = {}
                if type(value) == "table" then
                    for link, _ in pairs(value) do table.insert(sortedLinks, link) end
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
            for link, _ in pairs(db.fishingFishedItemLinks) do table.insert(fishedLinks, link) end
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
    local parts = {}
    for key, value in pairs(data) do
        if value then
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
            if tonumber(value) then
                data[key] = tonumber(value)
            else
                data[key] = value
            end
        end
    end
    return data
end

function Purity:BroadcastStatus()
    local db = self:GetDB()
    local _, classToken = UnitClass("player")
    
    local myStatus = {
        challenge = db.challengeTitle,
        difficulty = db.challengeDifficulty,
        level = UnitLevel("player"),
        class = classToken,
        status = db.status
    }
    
    local message = "STATUS_UPDATE:" .. self:Serialize(myStatus)
    C_ChatInfo.SendAddonMessage(self.ADDON_PREFIX, message, "CHANNEL", "PurityUsers")
end

function Purity:SendStatusToPlayer(playerName)
    local myStatus = {
        challenge = self:GetDB().challengeTitle,
        difficulty = self:GetDB().challengeDifficulty
    }
    local message = "STATUS_UPDATE:" .. self:Serialize(myStatus)
    C_ChatInfo.SendAddonMessage(self.ADDON_PREFIX, message, "WHISPER", playerName)
end

function Purity:SendGoodbye()
    C_ChatInfo.SendAddonMessage(self.ADDON_PREFIX, "GOODBYE", "CHANNEL", "PurityUsers")
end

function Purity:UpdateRosterWindow()
    if not Purity.rosterPane or not Purity.rosterPane:IsShown() then return end
    
    if Purity.rosterPane.lines then
        for _, line in ipairs(Purity.rosterPane.lines) do line:Hide() end
    end
    Purity.rosterPane.lines = {}

    local yOffset = -95
    local i = 1
    
    for playerName, data in pairs(self.roster) do
        local level = data.level or "??"
        local challenge = data.challenge or "No Challenge"
        local status = data.status or "Unknown"
        local class = data.class or ""
        
        local color = RAID_CLASS_COLORS[class] or {r=1, g=1, b=1}
        local colorHex = string.format("|cff%02x%02x%02x", color.r*255, color.g*255, color.b*255)
        
        local lineText = string.format("%s Lvl %s %s - %s (%s)", colorHex .. playerName .. "|r", level, class, challenge, status)
        
        local line = Purity.rosterPane:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        line:SetPoint("TOPLEFT", Purity.rosterPane, "TOPLEFT", 40, yOffset)
        line:SetPoint("TOPRIGHT", Purity.rosterPane, "TOPRIGHT", -40, yOffset)
        line:SetText(lineText)
        line:SetJustifyH("LEFT")
        table.insert(Purity.rosterPane.lines, line)
        
        yOffset = yOffset - 30 
        i = i + 1
    end
end

-- Purity.lua -> The complete and correct DisplayChallengeDetails function

function Purity:DisplayChallengeDetails(challengeData)
    if not challengeData then return end
	
    -- Clears all previous content from the panel
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

    -- Sets the main description text
    local descriptionText = ""
    if challengeData.description then
        descriptionText = (type(challengeData.description) == "function") and challengeData.description() or challengeData.description
    end

    -- Correctly calculates and displays the base coefficient for the selected item
    local goldColor = "|cffffd100"
    local whiteColor = "|cffffffff"
    local coefficientText = ""

    if Purity.tempSelectedSpec and challengeData.specializations then
        -- A specialization has been selected, display its specific coefficient.
        local challengeKey
        if challengeData.challengeName == "The Ascetic's Path" then
            if Purity.tempSelectedSpec.id == "EASY" then challengeKey = "Path of Humility"
            elseif Purity.tempSelectedSpec.id == "MEDIUM" then challengeKey = "Path of Resilience"
            elseif Purity.tempSelectedSpec.id == "HARD" then challengeKey = "Path of the Unburdened" end
        else -- For other spec challenges like Mage
            local specifier = Purity.tempSelectedSpec.name
            challengeKey = string.format("%s (%s)", challengeData.challengeName, specifier:sub(1,1):upper()..specifier:sub(2):lower())
        end
        local coeff = Purity.ChallengeCoefficients[challengeKey]
        if coeff then
            coefficientText = "\n\n" .. goldColor .. "Difficulty Coefficient:|r " .. whiteColor .. string.format("%.2f", coeff) .. "|r"
        end
    else
        -- No specialization selected yet, or it's a normal challenge.
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
    end
	Purity.optInFrame.challengeDescription:SetText(descriptionText .. coefficientText)

    -- === UPGRADED: Combined DK Path calculation ===
    if Purity.selectedVow and Purity.selectedDKPath then
        local vowCoeff = 0
        -- Check if the selected vow has a specialization picked
        if Purity.tempSelectedSpec and Purity.selectedVow.specializations then
            local vowChallengeKey
            if Purity.selectedVow.challengeName == "The Ascetic's Path" then
                if Purity.tempSelectedSpec.id == "EASY" then vowChallengeKey = "Path of Humility"
                elseif Purity.tempSelectedSpec.id == "MEDIUM" then vowChallengeKey = "Path of Resilience"
                elseif Purity.tempSelectedSpec.id == "HARD" then vowChallengeKey = "Path of the Unburdened" end
            else -- For Mage, etc.
                local specifier = Purity.tempSelectedSpec.name
                vowChallengeKey = string.format("%s (%s)", Purity.selectedVow.challengeName, specifier:sub(1,1):upper()..specifier:sub(2):lower())
            end
            vowCoeff = Purity.ChallengeCoefficients[vowChallengeKey] or 0
        else
            -- The vow is a normal challenge without specializations
            vowCoeff = Purity.ChallengeCoefficients[Purity.selectedVow.challengeName] or 0
        end

        local dkCoeff = Purity.ChallengeCoefficients[Purity.selectedDKPath.challengeName] or 0
        if vowCoeff > 0 and dkCoeff > 0 then
            local finalCoeff = ((vowCoeff * 54) + (dkCoeff * 35)) / 89
            local combinedText = string.format("\n\n|cffffd100Combined Path Coefficient:|r |cff00ff00%.2f|r", finalCoeff)
            local currentDescription = Purity.optInFrame.challengeDescription:GetText()
            Purity.optInFrame.challengeDescription:SetText(currentDescription .. combinedText)
        end
    end
    -------------------------------------------------

    -- Sets the rules text and handles other UI elements
    local rules = challengeData.GetRulesText and challengeData:GetRulesText() or {""}
    Purity.optInFrame.challengeRules:SetText(table.concat(rules, "\n"))
    if challengeData.optInWarningText then
        Purity.optInFrame.challengeWarning:SetText(challengeData.optInWarningText)
        Purity.optInFrame.challengeWarning:Show()
    end
    if Purity.optInFrame.specButtons then
        for _, button in ipairs(Purity.optInFrame.specButtons) do button:Hide() end
    end
    Purity.optInFrame.specButtons = {}
    local specContainer = Purity.optInFrame.specContainer
    local totalSpecHeight = 0
    if challengeData.specializations then
        local yOffset = 0
        for _, specData in ipairs(challengeData.specializations) do
            local button = CreateFrame("Button", nil, specContainer, "UIPanelButtonTemplate")
            button:SetSize(200, 22); button:SetText(specData.buttonText); button:SetPoint("TOP", specContainer, "TOP", 0, yOffset)
            local buttonHeight = button:GetHeight() + 5
            yOffset = yOffset - buttonHeight; totalSpecHeight = totalSpecHeight + buttonHeight
            button.specData = specData; table.insert(Purity.optInFrame.specButtons, button)
            if Purity.tempSelectedSpec and Purity.tempSelectedSpec.name == specData.name then button:LockHighlight() end
            button:SetScript("OnClick", function(self)
                Purity.tempSelectedSpec = self.specData; Purity:DisplayChallengeDetails(challengeData)
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

    -- Proven timer logic to prevent text cutoff
	C_Timer.After(0.1, function()
		local scrollChild = Purity.optInFrame.scrollFrame:GetScrollChild()
		if not scrollChild then return end
		local totalHeight = 10 
		if Purity.optInFrame.challengeTitle:IsShown() then totalHeight = totalHeight + Purity.optInFrame.challengeTitle:GetHeight() + 15 end
		if Purity.optInFrame.challengeDescription:IsShown() then totalHeight = totalHeight + Purity.optInFrame.challengeDescription:GetHeight() + 20 end
		if Purity.optInFrame.challengeRules:IsShown() then totalHeight = totalHeight + Purity.optInFrame.challengeRules:GetHeight() + 15 end
		if specContainer:IsShown() then totalHeight = totalHeight + specContainer:GetHeight() + 15 end
		if Purity.optInFrame.challengeWarning:IsShown() then totalHeight = totalHeight + Purity.optInFrame.challengeWarning:GetHeight() + 10 end
		totalHeight = totalHeight + 20 
		scrollChild:SetHeight(totalHeight)
		Purity.optInFrame.acceptButton:Disable()
		Purity.optInFrame.scrollFrame:SetVerticalScroll(0)
		C_Timer.After(0.01, function()
			if Purity.optInFrame.scrollFrame:GetVerticalScrollRange() < 5 then
				Purity.optInFrame.acceptButton:Enable()
			end
		end)
	end)
end

function Purity:selectTab(tabToShow)
    if not self.mainInterfaceFrame then self:CreateCoreUI() end

    -- Hide all panes and both content frames
    self.rulesPane:Hide()
    self.statusPane:Hide()
    self.rosterPane:Hide()
    self.dkPane:Hide()
    self.verifyPane:Hide()
    if self.rankingsPane then self.rankingsPane:Hide() end
    if self.contentFrame then self.contentFrame:Hide() end
    if self.wideContentFrame then self.wideContentFrame:Hide() end


    if tabToShow == "rankings" then
        -- For the rankings tab, show the WIDE content frame and the rankings pane
        self.wideContentFrame:Show()
        self.rankingsPane:Show()
        self:DisplayRankings()
    else
        -- For all other tabs, show the STANDARD content frame and the relevant pane
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
            C_ChatInfo.SendAddonMessage(self.ADDON_PREFIX, "ROSTER_REQUEST", "CHANNEL", "PurityUsers")
            self:UpdateRosterWindow()
        elseif tabToShow == "dk" then
            self.dkPane:Show()
            self:DisplayDKPane()
        elseif tabToShow == "verify" then
            self.verifyPane:Show()
            local db = self:GetDB()
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
        end
    end
end

function Purity.CreateCoreUI()
    if Purity.hasUIBeenCreated then return end
    Purity.hasUIBeenCreated = true
	
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

    -- Create the ScrollFrame for the right pane of the OptInFrame
    local scrollFrame = CreateFrame("ScrollFrame", "PurityOptInScrollFrame", rightPaneContainer, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 0, -5)
	scrollFrame:SetPoint("TOPRIGHT", -30, 0)
    Purity.optInFrame.scrollFrame = scrollFrame

    -- Create the child frame that will hold the content and be scrolled
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
		-- THE FIX: Add a validation check at the beginning of the function.
		if Purity.selectedVow and Purity.selectedDKPath and Purity.selectedDKPath.challengeName == "Phylactery of Purity" then
			print("|cffFFFF00Purity:|r |cffFF0000Invalid Combination:|r The 'Phylactery of Purity' path is a Vow in itself and cannot be combined with another challenge. Please select only the Phylactery path.")
			return -- Stop the function here to prevent the conflict.
		end

		-- The rest of the function remains the same.
		if not Purity.selectedVow and not Purity.selectedDKPath then
			print("|cffFFFF00Purity:|r Please select a Vow or a DK Path before accepting.")
			return
		end

		if not Purity.optInFrame.checkbox:GetChecked() then
			print("|cffFFFF00Purity:|r |cffFF0000You must agree to the terms by checking the box before accepting the challenge.|r")
			return
		end

		if Purity.selectedVow and Purity.selectedVow.IsItemForbidden then
			local inventorySlots = {
				INVSLOT_HEAD, INVSLOT_NECK, INVSLOT_SHOULDER, INVSLOT_BODY, 
				INVSLOT_CHEST, INVSLOT_WAIST, INVSLOT_LEGS, INVSLOT_FEET,
				INVSLOT_WRIST, INVSLOT_HAND, INVSLOT_FINGER1, INVSLOT_FINGER2,
				INVSLOT_TRINKET1, INVSLOT_TRINKET2, INVSLOT_BACK, INVSLOT_MAINHAND,
				INVSLOT_OFFHAND, INVSLOT_RANGED, INVSLOT_TABARD,
				INVSLOT_BAG1, INVSLOT_BAG2, INVSLOT_BAG3, INVSLOT_BAG4
			}
			for _, slotId in ipairs(inventorySlots) do
				local itemLink = GetInventoryItemLink("player", slotId)
				if itemLink and Purity.selectedVow:IsItemForbidden(itemLink) then
					local itemName = GetItemInfo(itemLink)
					print("|cffFFFF00Purity:|r |cffFF0000Cannot accept! You must unequip all starting gear first. Please remove: " .. (itemName or "Unknown Item") .. "|r")
					return
				end
			end
		end

		local db = Purity:GetDB()
		if Purity.selectedVow and Purity.selectedVow.SaveData then Purity.selectedVow:SaveData() end

		db.isOptedIn = true
		db.status = "Passing"
		db.startDate = date("%Y-%m-%d %H:%M:%S")
		db.playerGUID = UnitGUID("player")
		db.addonVersion = Purity.Version
		db.isAwaitingInitialUptimeSync = true
		
		local titleParts = {}
		
		if Purity.selectedVow then
			local challengeKey = Purity.selectedVow.id or Purity.selectedVow.challengeName
			local isGlobal = Purity.ChallengeTypeMap and Purity.ChallengeTypeMap[Purity.selectedVow.challengeName] == "Global"
			
			db.activeChallengeID = challengeKey
			db.activeChallengeModuleType = isGlobal and "Global" or "Class"
			db.challengeTitle = Purity.selectedVow.challengeName
			table.insert(titleParts, db.challengeTitle)
		end

		if Purity.selectedDKPath then
			db.destinedDKChallengeID = Purity.selectedDKPath.id
			db.destinedDKChallenge = Purity.selectedDKPath.challengeName
			table.insert(titleParts, "(Destined for " .. db.destinedDKChallenge .. ")")
		end

		if not Purity.selectedVow and Purity.selectedDKPath then
			db.activeChallengeID = "DK_PATH_PLACEHOLDER"
			db.activeChallengeModuleType = "Global"
			db.challengeTitle = "Path of the Damned"
		end

		local finalConfirmationTitle = table.concat(titleParts, " ")
		if finalConfirmationTitle == "" then finalConfirmationTitle = "Purity Challenge" end
		
		Purity.optInFrame:Hide()
		Purity:ActivateMonitoring()

		if Purity:GetDB().status ~= "Failed" then
			local newlyAcceptedChallenge = Purity:GetActiveChallengeObject()
			if newlyAcceptedChallenge and newlyAcceptedChallenge.InitializeOnPlayerEnterWorld then
				newlyAcceptedChallenge:InitializeOnPlayerEnterWorld()
			end
			print("|cffFFFF00Purity:|r |cff00FF00The '" .. finalConfirmationTitle .. "' challenge has been accepted! Good luck!|r")
			Purity:BroadcastStatus()
			
			local activeChallenge = Purity:GetActiveChallengeObject()
			if activeChallenge and activeChallenge.EventHandler then
				activeChallenge:EventHandler("PLAYER_EQUIPMENT_CHANGED")
			end

			if GameTooltip:IsShown() and GameTooltip:GetUnit() == "mouseover" then
				GameTooltip:Hide(); GameTooltip:SetUnit("mouseover"); GameTooltip:Show()
			end
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
			if classModule.challenges then
				for id, data in pairs(classModule.challenges) do table.insert(availableVows, data) end
			else
				table.insert(availableVows, classModule)
			end
		end
		if Purity.GlobalModules then
			for id, data in pairs(Purity.GlobalModules) do
				if data.id ~= "DK_PATH_PLACEHOLDER" then
					table.insert(availableVows, data)
				end
			end
		end
		
		-- Add the standard DK Paths for all classes
		table.insert(availableDKPaths, {
			id = "DK_ASHES",
			challengeName = "Ashes of Purity",
			description = function() return "Cast all your worldly possessions into the fire. This vow demands a sacrifice of not just spirit, but of all material things. Your new life as a Death Knight will begin as you began your first: with nothing but the will to survive." end,
			GetRulesText = function() return { "|cffffd100The Rite of Cinder|r", "|cff261A0D  • This path dedicates your mortal life to the pyre. To be reborn in undeath, you must first turn your life's acquisitions to ash.|r", "|cff261A0D  • At level 55-58, you may complete the sacrificial rite to create your Death Knight.|r", "|cff261A0D  • Your new Death Knight will awaken with empty bags and no gear, forbidden from ever using the equipment of their past life.|r", "|cff261A0D  • They must scavenge and fight for every new scrap of power, truly starting from nothing.|r" } end
		})
		table.insert(availableDKPaths, {
			id = "DK_SIGIL",
			challengeName = "Sigil of Purity",
			description = function() return "Carve a sigil of pure destruction into your soul. This vow rejects all notions of self-preservation, demanding a reckless, unending assault. Your new life as a Death Knight will be a testament to the idea that the only defense is a relentless offense." end,
			GetRulesText = function() return { "|cffffd100The Sigil of Wrath|r", "|cff261A0D  • This path brands your soul with a sigil of unending fury. You will forsake all notions of defense and recovery in pursuit of pure destruction.|r", "|cff261A0D  • At level 55-58, you may complete the sacrificial rite to create your Death Knight.|r", "|cff261A0D  • Your new Death Knight will be an avatar of wrath, forbidden from ever using healing abilities, items, or even food to recover from their wounds.|r", "|cff261A0D  • They must live on the edge of death, sustained only by their unending rage.|r" } end
		})

		-- THE FIX: "Phylactery of Purity" is now ONLY added to the DK Path list for Warlocks.
		if playerClass == "WARLOCK" then
			table.insert(availableDKPaths, {
				challengeName = "Phylactery of Purity",
				description = function() return "|cff8788eeSPECIAL VOW:|r Bind your soul to a dark pact. This vow dedicates your very essence to a phylactery, a vessel to carry your power beyond death. Your new life as a Death Knight will be a continuation of your mastery over shadow." end,
				GetRulesText = function() return { "|cffffd100The Phylactery's Pact|r", "|cff261A0D  • This is a special destiny for Warlocks who would see their power outlive their mortality.|r", "|cff261A0D  • You must walk the path of Affliction and master the 'Shadow Embrace' talent to imbue the phylactery.|r", "|cff261A0D  • At level 55-58, you may complete the sacrificial rite, pouring your soul's essence into the vessel.|r", "|cff261A0D  • Your new Death Knight will be born from this dark pact, forever rejecting the Lich King's frigid magic.|r", } end
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
			
			checkbox.challengeData = challengeData
			table.insert(list, checkbox)

			checkbox:SetScript("OnClick", function(self)
				local currentList = isDKPath and frame.dkPathCheckboxes or frame.vowCheckboxes
				if self:GetChecked() then
					for _, otherBox in ipairs(currentList) do
						if otherBox ~= self then otherBox:SetChecked(false) end
					end
					if isDKPath then Purity.selectedDKPath = self.challengeData else Purity.selectedVow = self.challengeData end
				else
					if isDKPath then Purity.selectedDKPath = nil else Purity.selectedVow = nil end
				end

				-- This logic ensures that choosing Phylactery and another Vow is mutually exclusive.
				if self:GetChecked() then
					if isDKPath and self.challengeData.challengeName == "Phylactery of Purity" then
						if Purity.selectedVow then
							for _, vowBox in ipairs(frame.vowCheckboxes) do vowBox:SetChecked(false) end
							Purity.selectedVow = nil
						end
					elseif not isDKPath then
						if Purity.selectedDKPath and Purity.selectedDKPath.challengeName == "Phylactery of Purity" then
							for _, pathBox in ipairs(frame.dkPathCheckboxes) do
								if pathBox.challengeData.challengeName == "Phylactery of Purity" then
									pathBox:SetChecked(false)
								end
							end
							Purity.selectedDKPath = nil
						end
					end
				end
				
				Purity:DisplayChallengeDetails(self.challengeData)
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

		table.sort(availableDKPaths, function(a, b) return a.challengeName < b.challengeName end)
		for _, path in ipairs(availableDKPaths) do
			CreateChallengeCheckbox(frame.leftPane, path, true)
		end
	end)
	
    Purity.optInFrame:Hide()

    Purity.mainInterfaceFrame = CreateFrame("Frame", "Purity_MainInterfaceFrame", UIParent)
    Purity.mainInterfaceFrame:SetSize(610, 550)
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
	
    local dkTab = CreateFrame("Button", "Purity_DKTab", Purity.mainInterfaceFrame, "UIPanelButtonTemplate")
	dkTab:SetSize(tabWidth, 22)
	dkTab:SetPoint("LEFT", rankingsTab, "RIGHT", tabSpacing, 0)
	dkTab:SetText("Death Knight")

	local verifyTab = CreateFrame("Button", "Purity_VerifyTab", Purity.mainInterfaceFrame, "UIPanelButtonTemplate")
	verifyTab:SetSize(tabWidth, 22)
	verifyTab:SetPoint("LEFT", dkTab, "RIGHT", tabSpacing, 0)
	verifyTab:SetText("Verify")

    -- This is the standard content frame for most tabs
    local contentFrame = CreateFrame("Frame", nil, Purity.mainInterfaceFrame)
    contentFrame:SetPoint("TOP", rulesTab, "BOTTOM", 0, -45)
    contentFrame:SetPoint("BOTTOM", Purity.mainInterfaceFrame, "BOTTOM", 0, 80)
    contentFrame:SetPoint("LEFT", Purity.mainInterfaceFrame, "LEFT", 60, 0)
    contentFrame:SetPoint("RIGHT", Purity.mainInterfaceFrame, "RIGHT", -60, 0)
    Purity.contentFrame = contentFrame -- Store a reference to it

    -- This is a wider content frame specifically for the Rankings tab
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
    Purity.dkPane = CreateFrame("Frame", nil, contentFrame)
    Purity.dkPane:SetAllPoints(contentFrame)
	Purity.verifyPane = CreateFrame("Frame", nil, contentFrame)
	Purity.verifyPane:SetAllPoints(contentFrame)
	
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
	
	    -- Create the ScrollFrame for the Rankings Pane
    local scrollFrame = CreateFrame("ScrollFrame", "PurityRankingsScrollFrame", Purity.rankingsPane, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", rankingsHeader, "BOTTOMLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", Purity.rankingsPane, "BOTTOMRIGHT", -45, 20)
    Purity.rankingsPane.scrollFrame = scrollFrame

    -- Create the child frame that will hold the content and be scrolled
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
    dkTab:SetScript("OnClick", function() Purity:selectTab("dk") end)
    verifyTab:SetScript("OnClick", function() Purity:selectTab("verify") end)

    local closeButton = CreateFrame("Button", "Purity_InterfaceCloseButton", Purity.mainInterfaceFrame, "UIPanelButtonTemplate")
    closeButton:SetSize(100, 25)
    closeButton:SetPoint("BOTTOM", Purity.mainInterfaceFrame, "BOTTOM", 0, 20)
    closeButton:SetText("Close")
	closeButton:SetScript("OnClick", function()
		Purity.mainInterfaceFrame:Hide()
		local charDB = Purity:GetDB()
		local _, class = UnitClass("player")
		if class == "DEATHKNIGHT" then
			charDB.dkShowPanelOnLogin = false
		end
	end)
	
    Purity:InitializeCharacterPanel()
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

    if currentDB.sacrificedPlayedTime and currentDB.sacrificedPlayedTime > 0 then
        data.totalPlayed = data.totalPlayed + currentDB.sacrificedPlayedTime
        data.addonRuntime = data.addonRuntime + (currentDB.sacrificedRuntime or 0)
    end

    local currentUptime = (data.totalPlayed > 0 and (data.addonRuntime / data.totalPlayed) * 100) or 0
    if data.status == "Passing" and currentUptime < 96 then
        data.status = "Temporary Failure - Uptime"
    end

    return data
end

function Purity:PerformSecurityAudit(db)
    print("|cffFFFF00Purity:|r Old addon version detected. Performing security audit...")

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
    db.dataSignature = Purity:CreateDataSignature(db, db.status, db.playerGUID)
    return true
end

function Purity:Violation(message, isFromAudit)
    if not self.notificationBanner then self:CreateCoreUI() end
    local currentDB = Purity:GetDB()

    if currentDB.status ~= "Passing" and currentDB.status ~= "Temporary Failure - Uptime" then
        return
    end
    
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

    if db.physicalStrikes == 1 then
        self:ShowWarningBanner("The Light recoils from your act of physical violence, but its grace allows this transgression. This is your first strike.", 10, 1)
    elseif db.physicalStrikes == 2 then
        self:ShowWarningBanner("You have resorted to violence again. The Light's patience wears thin.\nThis is your final warning.", 10, 2)
    elseif db.physicalStrikes >= 3 then
        self:Violation("Forsaken by the Light for your violent acts, your vow of purity is broken.")
    end
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

        local finalUptime = (db.totalPlayedTime > 0 and (db.addonRuntime / db.totalPlayedTime) * 100) or 0

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

-- In Purity.lua, replace the entire function with this one.
function Purity:CheckEquipmentState()
    local activeChallenge = self:GetActiveChallengeObject()
    if not activeChallenge or not activeChallenge.needsWeaponWarning then
        return
    end

    local slotsToCheck
    if activeChallenge.allSlotsForbiddenCheck then
        -- This is the base list of all standard gear slots.
        slotsToCheck = {
            INVSLOT_HEAD, INVSLOT_NECK, INVSLOT_SHOULDER, INVSLOT_BACK,
            INVSLOT_CHEST, INVSLOT_BODY, INVSLOT_TABARD, INVSLOT_WRIST,
            INVSLOT_HAND, INVSLOT_WAIST, INVSLOT_LEGS, INVSLOT_FEET,
            INVSLOT_FINGER1, INVSLOT_FINGER2, INVSLOT_TRINKET1, INVSLOT_TRINKET2,
            INVSLOT_MAINHAND, INVSLOT_OFFHAND, INVSLOT_RANGED,
        }
        
        -- THE FIX: Dynamically add the correct bag slots.
        local _, playerClass = UnitClass("player")
        if playerClass == "DEATHKNIGHT" and activeChallenge.id == "DK_ASHES" then
            -- If it's a DK on this specific challenge, add the non-standard bag slots.
            table.insert(slotsToCheck, 31)
            table.insert(slotsToCheck, 32)
            table.insert(slotsToCheck, 33)
            table.insert(slotsToCheck, 34)
        else
            -- For everyone else, add the standard bag slots.
            table.insert(slotsToCheck, INVSLOT_BAG1)
            table.insert(slotsToCheck, INVSLOT_BAG2)
            table.insert(slotsToCheck, INVSLOT_BAG3)
            table.insert(slotsToCheck, INVSLOT_BAG4)
        end

    else
        -- This part is for challenges that only restrict weapons, unchanged.
        slotsToCheck = { INVSLOT_RANGED, INVSLOT_MAINHAND, INVSLOT_OFFHAND }
    end

    local isForbiddenItemEquipped = false
    for _, slotId in ipairs(slotsToCheck) do
        local itemLink = GetInventoryItemLink("player", slotId)
        if itemLink then
            -- This correctly calls the IsItemForbidden function from your DK module.
            if activeChallenge.isWeaponAllowed and not activeChallenge:isWeaponAllowed(itemLink) then
                isForbiddenItemEquipped = true
                break
            end
        end
    end

    -- The rest of the warning/failure logic remains the same.
    if isForbiddenItemEquipped then
        if not weaponTimer then
            local db = Purity:GetDB()
            db.weaponInfractions = (db.weaponInfractions or 0) + 1
            if db.weaponInfractions >= 2 then
                Purity:Violation("Equipped a forbidden item after all warnings were used.")
                return
            end
            
            local warningMessage = "Forbidden Item Equipped, Unequip to avoid failure!\nTime remaining: %.1f"
            local gracePeriod = (db.weaponInfractions == 1) and 10 or 7
            local countdown = gracePeriod
            
            Purity:ShowWarningBanner(string.format(warningMessage, countdown), nil, db.weaponInfractions)
            
            weaponTimer = C_Timer.NewTicker(0.1, function()
                countdown = countdown - 0.1
                countdown = math.max(0, countdown)
                if Purity.notificationBanner.text then
                    Purity.notificationBanner.text:SetText(string.format(warningMessage, countdown))
                end
                if countdown <= 0 then
                    Purity:Violation("Failed to unequip forbidden item in time.")
                    if weaponTimer then weaponTimer:Cancel(); weaponTimer = nil end
                    if Purity.notificationBanner then Purity.notificationBanner:Hide() end
                end
            end)
        end
    elseif weaponTimer then
        weaponTimer:Cancel()
        weaponTimer = nil
        if Purity.notificationBanner then Purity.notificationBanner:Hide() end
    end
end

function Purity:ActivateMonitoring()
    local currentDB = Purity:GetDB()
    if currentDB.status ~= "Passing" then return end
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
        if db.status == "Failed" or db.status == "Not Participating" then
            purityRuntimeTicker:Cancel(); purityRuntimeTicker = nil
            return
        end
        db.addonRuntime = db.addonRuntime + 1
    end)
    if purityPlayedTimeTicker then purityPlayedTimeTicker:Cancel() end
    purityPlayedTimeTicker = C_Timer.NewTicker(60, function()
        local db = Purity:GetDB()
        if db.status ~= "Passing" then
            purityPlayedTimeTicker:Cancel(); purityPlayedTimeTicker = nil
            return
        end
        Purity:SilentRequestTimePlayed()
    end)
       if not monitorFrame then
        monitorFrame = CreateFrame("Frame")
        monitorFrame:SetScript("OnEvent", function(_, event, ...)

            local db = Purity:GetDB()
            if db.status == "Failed" or db.status == "Not Participating" then
                return
            end
			
			if event == "PLAYER_DEAD" then
				Purity:UpdateAllModifierStatuses()
				return
			end
			
			if event == "UNIT_AURA" then
				local unitTarget = ...
				if unitTarget == "player" then
					Purity:UpdateAllModifierStatuses()
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
        monitorFrame:RegisterEvent("BAG_UPDATE")
		monitorFrame:RegisterEvent("CVAR_UPDATE")
        monitorFrame:RegisterEvent("UNIT_AURA")
end

	C_Timer.After(2, function()
		Purity:CheckEquipmentState()
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
        Purity.mainInterfaceFrame:SetHeight(550)
    elseif classToken == "DRUID" then
        Purity.mainInterfaceFrame:SetHeight(600)
    elseif classToken == "HUNTER" then
        Purity.mainInterfaceFrame:SetHeight(680)
    else
        Purity.mainInterfaceFrame:SetHeight(550)
    end

    if command == "rules" or command == "status" or command == "roster" or command == "verify" then
        if not Purity.mainInterfaceFrame:IsShown() then
            Purity.mainInterfaceFrame:Show()
        end
        Purity:selectTab(command)
		
    elseif command == "override" then
        local newSignature = args[2]
        local weaponInfractions = tonumber(args[3])
        local physicalStrikes = tonumber(args[4])

        if not newSignature or #newSignature ~= 8 then
            print("|cffFFFF00Purity:|r |cffFF0000Invalid usage. Use: /purity override [signature] [weapon_infractions] [physical_strikes]|r")
            print("|cffFFFF00Purity:|r |cffFF0000Example: /purity override a1b2c3d4 1 0|r")
            return
        end

        local db = Purity:GetDB()
        db.status = "Passing"
        db.dataSignature = newSignature
        
        db.weaponInfractions = weaponInfractions or 0
		db.physicalStrikes = physicalStrikes or 0

        Purity:ActivateMonitoring()
        print("|cffFFFF00Purity:|r |cff00FF00Moderator override successful. Challenge status restored.|r")
        if Purity.mainInterfaceFrame and Purity.mainInterfaceFrame:IsShown() then
            Purity:UpdateAndGetStatusStrings()
        end

	elseif command == "help" then
        print("|cffFFFF00--- Purity Commands ---|r")
        print("/purity: Shows your quick current challenge status in chat.")
        print("/purity status: Opens the full status window.")
        print("/purity rules: Opens the full rules window.")
        print("/purity roster: Opens the full roster window.")
        print("/purity verify: Opens the verification window.")
		
    elseif command == "activate" then
        local _, playerClass = UnitClass("player")
        if playerClass == "DEATHKNIGHT" then
            ApplyPurityDKToken()
            if Purity.mainInterfaceFrame and Purity.mainInterfaceFrame:IsShown() then
                Purity:UpdateAndGetStatusStrings()
            end
        else
            print("|cffFFFF00Purity:|r Only a Death Knight can activate a challenge.")
        end
		
	elseif command == "drunk" then --> ADD THIS
        if Purity.GlobalModules and Purity.GlobalModules.DRUNK and Purity.GlobalModules.DRUNK.ToggleStatusFrame then --> ADD THIS
            Purity.GlobalModules.DRUNK:ToggleStatusFrame() --> ADD THIS
        else --> ADD THIS
            print("|cffFFFF00Purity:|r This command is only available for the Drunken Master challenge.") --> ADD THIS
        end --> ADD THIS
		
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

local mainFrame = CreateFrame("Frame")
mainFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
mainFrame:RegisterEvent("TIME_PLAYED_MSG")
mainFrame:RegisterEvent("ADDON_LOADED")
mainFrame:RegisterEvent("PLAYER_LOGIN")
mainFrame:RegisterEvent("CHAT_MSG_ADDON")
mainFrame:RegisterEvent("PLAYER_LOGOUT")

local function OnAddonMessage(prefix, message, channel, sender)
    if prefix ~= Purity.ADDON_PREFIX or sender == UnitName("player") then
        return
    end

    local command, data = message:match("([^:]+):?(.*)")
    
    if command == "STATUS_UPDATE" then
        local status = Purity:Deserialize(data)
        Purity.roster[sender] = {
            challenge = status.challenge,
            difficulty = status.difficulty,
            lastSeen = GetTime() 
        }
        Purity:UpdateRosterWindow() 
    elseif command == "REQUEST_STATUS" then
        Purity:SendStatusToPlayer(sender)
	elseif command == "ROSTER_REQUEST" then
        Purity:SendStatusToPlayer(sender)
    elseif command == "GOODBYE" then
        Purity.roster[sender] = nil
        Purity:UpdateRosterWindow() 
    end
end

local function OnPlayerLogin()
    Purity:BuildChallengeTypeMap()
    Purity:StartModifierMonitor()
    C_ChatInfo.RegisterAddonMessagePrefix(Purity.ADDON_PREFIX)
    JoinTemporaryChannel("PurityUsers", "a-unique-password", 1)

    local charDB = Purity:GetDB()
    local _, class = UnitClass("player")
	local charDB = Purity:GetDB()
	local _, class = UnitClass("player")
	if class == "DEATHKNIGHT" then
		-- On the very first login, set the flag to show the panel by default
		if charDB.dkShowPanelOnLogin == nil then
			charDB.dkShowPanelOnLogin = true
		end

		-- If the flag is true, show the panel
		if charDB.dkShowPanelOnLogin then
			C_Timer.After(1, function()
				if Purity.mainInterfaceFrame then
					Purity.mainInterfaceFrame:Show()
				end
				Purity:selectTab("dk")
			end)
		end
	end

    C_Timer.After(5, function()
        Purity:BroadcastStatus()
    end)

    C_Timer.After(8, function()
        C_ChatInfo.SendAddonMessage(Purity.ADDON_PREFIX, "ROSTER_REQUEST", "CHANNEL", "PurityUsers")
    end)
end


mainFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_LOGOUT" then
		local currentDB = Purity:GetDB()
		if currentDB and currentDB.isOptedIn then
			if currentDB.activeChallengeID == "DRUNK" then
				if not currentDB.drunkData then currentDB.drunkData = {} end

				-- This is the corrected line that pulls the state from the module.
				currentDB.drunkData.lastState = Purity.GlobalModules.DRUNK:GetCurrentState()
				currentDB.drunkData.logoutTimestamp = GetTime()
			end
			currentDB.dataSignature = Purity:CreateDataSignature(currentDB)
		end
		return
	end

    if event == "PLAYER_LOGIN" then
        Purity:InitializeDatabase()
        local currentDB = Purity:GetDB()
        
        if currentDB.isOptedIn and currentDB.status ~= "Not Participating" then
            local version = currentDB.addonVersion or "0.0.0"
            
            if currentDB.isMigrating then
                print("|cffFFFF00Purity:|r Finalizing secure upgrade to v" .. Purity.Version .. "...")
                currentDB.addonVersion = Purity.Version
                currentDB.isMigrating = nil
                currentDB.dataSignature = Purity:CreateDataSignature(currentDB)
                print("|cffFFFF00Purity:|r |cff00FF00Upgrade complete! Your character is secure.|r")

			-- This is the corrected version of the upgrade logic block
			elseif Purity:IsVersionOlder(version, Purity.Version) then
				local expectedOldSignature

				if Purity:IsVersionOlder(version, "7.5.0") then
					-- This handles all versions before 7.5.0
					expectedOldSignature = Purity:CreateDataSignature_V1(currentDB)

				elseif Purity:IsVersionOlder(version, "8.0.0") then 
					-- This handles version 7.5.0 specifically
					expectedOldSignature = Purity:CreateDataSignature_V2(currentDB)

				elseif Purity:IsVersionOlder(version, "9.0.0") then
					-- This handles all versions from 8.0.0 up to (but not including) 9.0.0
					expectedOldSignature = Purity:CreateDataSignature_V3(currentDB)
					
				else
					-- This case should ideally not be reached in an upgrade,
					-- but it's a safe fallback.
					expectedOldSignature = Purity:CreateDataSignature(currentDB)
				end
				
				if currentDB.dataSignature and currentDB.dataSignature ~= expectedOldSignature then
					Purity:Violation("Your files have been tampered with during a version upgrade. Your challenge has been revoked.")
					return
				end
				
				print("|cffFFFF00Purity:|r Old data version detected and validated. Preparing for secure upgrade. Please log out or reload your UI.")
				currentDB.isMigrating = true
            
            else
                -- This is for a normal login, not an upgrade. Check against the latest signature.
                local expectedSignature = Purity:CreateDataSignature(currentDB)
                if currentDB.dataSignature and currentDB.dataSignature ~= expectedSignature then
                    Purity:Violation("Your files have been tampered with. Your challenge has been revoked.")
                    return
                end
            end
        end

        local currentGUID = UnitGUID("player")
        if currentDB.isOptedIn and currentDB.playerGUID and currentDB.playerGUID ~= currentGUID then
            Purity:InternalResetChallenge()
        end
        if not currentDB.playerGUID then
            currentDB.playerGUID = currentGUID
        end

        OnPlayerLogin()
        self:UnregisterEvent("PLAYER_LOGIN")
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
	    Purity.CreateCoreUI()
        local currentDB = Purity:GetDB()
        if currentDB.isMigrating then
             Purity:ShowWarningBanner("Purity needs to finalize an update. Please log out or reload your UI to continue.", 30, 1)
        end
        
        Purity:LoadClassModule()
        local activeChallenge = Purity:GetActiveChallengeObject()
        if activeChallenge and activeChallenge.InitializeOnPlayerEnterWorld then
            activeChallenge:InitializeOnPlayerEnterWorld()
        end
        
        if currentDB.isOptedIn and not currentDB.isMigrating then
            Purity:ActivateMonitoring()
        elseif currentDB.status == "Failed" then
            print("|cffFFFF00Purity:|r This character has previously failed the challenge and cannot re-accept.")
            currentDB.hasBeenNotifiedOfLevelCap = true
        elseif not currentDB.isOptedIn then
            local hasAvailableChallenges = (activeClassModule ~= nil) or (Purity.GlobalModules and next(Purity.GlobalModules) ~= nil)
            if UnitLevel("player") == 1 and hasAvailableChallenges then
                Purity.optInFrame:Show()
            else
                if not currentDB.hasBeenNotifiedOfLevelCap then
                    print("|cffFFFF00Purity:|r A Purity Challenge can only be started at level 1.")
                    currentDB.hasBeenNotifiedOfLevelCap = true
                end
            end
        end

        Purity:SilentRequestTimePlayed()
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        return
    end

	if event == "TIME_PLAYED_MSG" then
		local totalTime, _ = ...
		local currentDB = Purity:GetDB()

		if totalTime then
			currentDB.totalPlayedTime = totalTime
			-- If this is the first time check after starting a challenge, sync the timers.
			if currentDB.isAwaitingInitialUptimeSync then
				currentDB.addonRuntime = totalTime -- Sync addon time with total played time
				currentDB.isAwaitingInitialUptimeSync = nil -- Clear the flag so this only happens once
			end
		end

		if Purity.mainInterfaceFrame and Purity.mainInterfaceFrame:IsShown() and Purity.statusPane:IsShown() then
			Purity:UpdateAndGetStatusStrings()
		end
		return
	end
	
	if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "Purity" then
            -- This sets "SHIFT-P" as the default key if the user hasn't set one already.
            -- Note we are using our new binding name: "PURITY_TOGGLE"
            if not GetBindingKey("PURITY_TOGGLE") then
                SetBinding("PURITY_TOGGLE", "SHIFT-P");
            end
        end
        return;
    end
end)

Purity.isActionTooltip = false

local function Purity_OnTooltipSetSpell_Handler(self)
    if Purity.isActionTooltip then return end

    local activeChallenge = Purity:GetActiveChallengeObject()
    if not activeChallenge then return end

    local _, spellId = self:GetSpell()
    if not spellId then return end

    if activeChallenge.IsSpellForbidden and activeChallenge:IsSpellForbidden(spellId) then
        local challengeName = Purity:GetDB().challengeTitle or "Purity Challenge"
        local warningText = "Forbidden by your " .. challengeName .. "."
        self:AddLine(" ", 0, 0, 0, 0)
        self:AddLine(warningText, 1, 0.1, 0.1)
    end
end

local function Purity_OnTooltipSetItem_Handler(self)
    local activeChallenge = Purity:GetActiveChallengeObject()
    if not activeChallenge then return end

    if activeChallenge.SetExpectingLootFromContainer then
        local link = select(2, self:GetItem())
        activeChallenge:SetExpectingLootFromContainer(link)
    end

    if not activeChallenge.IsItemForbidden then return end
    local link = select(2, self:GetItem())
    if not link then return end

    local isForbidden = activeChallenge:IsItemForbidden(link)
    if isForbidden == true then
        local challengeName = Purity:GetDB().challengeTitle or "Purity Challenge"
        local warningText = "Forbidden by your " .. challengeName .. "."
        self:AddLine(" ", 0, 0, 0, 0)
        self:AddLine(warningText, 1, 0.1, 0.1)
    elseif isForbidden == false and activeChallenge.showAllowedTooltip then
        local allowedText = "Allowed by your " .. (Purity:GetDB().challengeTitle or "Purity Challenge") .. "."
        self:AddLine(" ", 0, 0, 0, 0)
        self:AddLine(allowedText, 0, 1, 0)
    end
end

local Original_GameTooltip_SetAction = GameTooltip.SetAction

local function Purity_SetAction_Override(self, actionSlot)
    Purity.isActionTooltip = true

    Original_GameTooltip_SetAction(self, actionSlot)

    local activeChallenge = Purity:GetActiveChallengeObject()
    if activeChallenge then
        if activeChallenge.IsSpellForbidden then
            local actionType, actionID = GetActionInfo(actionSlot)
            if actionType == "spell" and activeChallenge:IsSpellForbidden(actionID) then
                local challengeName = Purity:GetDB().challengeTitle or "Purity Challenge"
                local warningText = "Forbidden by your " .. challengeName .. "."
                self:AddLine(" ", 0, 0, 0, 0)
                self:AddLine(warningText, 1, 0.1, 0.1)
				self:Show()
            end
        end
    end

    Purity.isActionTooltip = false
end

local function Purity_OnTooltipSetUnit_Handler(self)
    local unit = select(2, self:GetUnit())
    if not unit then return end

    local db = Purity:GetDB()
    if not (db and (db.status == "Passing" or db.status == "Temporary Failure - Uptime")) then return end

    local activeChallenge = Purity:GetActiveChallengeObject()

    if not (activeChallenge and activeChallenge.IsUnitForbidden) then return end

    if UnitExists(unit) and activeChallenge:IsUnitForbidden(unit) then
        local challengeName = (db.challengeTitle or activeChallenge.challengeName) or "Purity Challenge"
        local warningText = "Forbidden by your " .. challengeName .. "."
        self:AddLine(" ", 0, 0, 0, 0)
        self:AddLine(warningText, 1, 0.1, 0.1)
        self:Show()
    end
end

GameTooltip:HookScript("OnTooltipSetSpell", Purity_OnTooltipSetSpell_Handler)
GameTooltip:HookScript("OnTooltipSetItem", Purity_OnTooltipSetItem_Handler)
GameTooltip:HookScript("OnTooltipSetUnit", Purity_OnTooltipSetUnit_Handler)

hooksecurefunc(GameTooltip, "SetTalent", function(self, tabIndex, talentIndex)
    local activeChallenge = Purity:GetActiveChallengeObject()
    if not activeChallenge then return end
    if not activeChallenge.IsTalentForbidden then return end
    if activeChallenge:IsTalentForbidden(tabIndex) then
        local challengeName = Purity:GetDB().challengeTitle or "Purity Challenge"
        self:AddLine(" ", 0, 0, 0, 0)
        self:AddLine("Forbidden by your " .. challengeName .. ".", 1, 0.1, 0.1)
		self:Show()
    end
end)

GameTooltip:HookScript("OnHide", function(self)
    C_Timer.After(1, function()
        local activeChallenge = Purity:GetActiveChallengeObject()
        if activeChallenge and activeChallenge.ClearExpectingLootFromContainer then
            activeChallenge:ClearExpectingLootFromContainer()
        end
    end)
end)

function Purity:ShowVowStringPopup(vowString)
    if not self.vowStringFrame then
		local frame = CreateFrame("Frame", "PurityVowStringFrame", UIParent, "BackdropTemplate")
		frame:SetBackdrop({
			bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
			edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
			tile = true, tileSize = 32, edgeSize = 32,
			insets = { left = 11, right = 12, top = 12, bottom = 11 }
		})
        frame:SetSize(600, 400)
        frame:SetPoint("CENTER")
        frame:SetToplevel(true)
        frame.title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        frame.title:SetPoint("TOP", 0, -20)
        frame.title:SetText("Vow of Purity Generated")

        local instructions = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        instructions:SetPoint("TOP", frame.title, "BOTTOM", 0, -15)
        instructions:SetWidth(550)
        instructions:SetText("The vow for this character has been encoded below. Copy the entire string (Ctrl+C) and save it. You will need to paste this into the Purity window on your new Death Knight character to activate their challenge.")

        local editBox = CreateFrame("EditBox", nil, frame)
        editBox:SetSize(540, 200)
        editBox:SetPoint("TOP", instructions, "BOTTOM", 0, -15)
        editBox:SetMultiLine(true)
        editBox:SetAutoFocus(true)
        editBox:SetFontObject(GameFontNormal)
        local eb_bg = editBox:CreateTexture(nil, "BACKGROUND")
		eb_bg:SetAllPoints(true)
		eb_bg:SetColorTexture(0, 0, 0, 0.6)
        frame.editBox = editBox

        local closeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        closeButton:SetSize(120, 25)
        closeButton:SetPoint("BOTTOM", 0, 20)
        closeButton:SetText("Close")
        closeButton:SetScript("OnClick", function() frame:Hide() end)

        self.vowStringFrame = frame
    end

    self.vowStringFrame.editBox:SetText(vowString)
    self.vowStringFrame.editBox:HighlightText()
    self.vowStringFrame:Show()
end