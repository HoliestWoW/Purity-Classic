if not Purity then return end

local isPlayerInCombat = false
local currentDrunkState = "Sober"
local DrunkModuleEventHandlerFrame = CreateFrame("Frame")
local LOGOUT_BUFFER_TIME = 900
local playerGUID = UnitGUID("player")
local drunkStateOnCombatStart = "Sober" 

local DrunkModule = {
    challengeName = "The Drunken Master",
    description = "The Way of the Staggering Fist. Years spent as the town drunk were not wasted. Countless barroom brawls have honed your clumsy stumbles into an unpredictable martial art. Your enemies see a swaying fool, but you are a master of chaotic grace, turning staggering into evasion and slurred shouts into battle cries. To fight with a clear head would be to forget your training; only in the haze of ale can you find true focus.",
    isGlobalChallenge = true,
    needsWeaponWarning = false,
}

function DrunkModule:SetDrunkState(newState)
    if currentDrunkState == newState then return end
    currentDrunkState = newState
    self:UpdateStatusDisplay()

    local db = Purity:GetDB()
    if not db.drunkData then db.drunkData = {} end
    db.drunkData.lastState = currentDrunkState
end

function DrunkModule:UpdateStatusDisplay()
    if not DrunkenMasterStatusFrame or not DrunkenMasterStatusFrame:IsShown() then return end
    
    local frame = DrunkenMasterStatusFrame
    frame.currentText:SetText(currentDrunkState)
    
    if currentDrunkState == "Drunk" or currentDrunkState == "Smashed" then
        frame.currentText:SetTextColor(0.1, 1, 0.1)
        frame.combatAllowedText:SetText("Combat: Allowed")
        frame.combatAllowedText:SetTextColor(0.1, 1, 0.1)
    else
        frame.currentText:SetTextColor(1, 0.1, 0.1)
        frame.combatAllowedText:SetText("Combat: Not Allowed")
        frame.combatAllowedText:SetTextColor(1, 0.1, 0.1)
    end
end

function DrunkModule:GetRulesText()
    return {
        "|cffffd100The Path of the Citizen (Levels 1-20):|r",
        "|cff261A0D• Before level 21, you must prove yourself as a productive citizen.",
        "|cff261A0D• You must achieve a skill of |cffffff00150|r in at least |cffffff00TWO|r primary professions.",
        " ",
        "|cffffd100The Drunken Master (Level 21+):|r",
        "|cff261A0D• At level 21, your professions are checked. If you fail, the challenge ends.",
        "|cff261A0D• From level 21 on, you must be 'Drunk' or 'Smashed' to initiate combat.",
    }
end

-- This is our single, unified event handler
local function DrunkModule_EventHandler(event, ...)
    local db = Purity:GetDB()

<<<<<<< HEAD
    -- This is the fixed logic for detecting drunk status
    if event == "UI_INFO_MESSAGE" then
        local messageTable = ...
        
        -- Check if the event is valid and has the message data
        if messageTable and messageTable.message then
            local message = messageTable.message
            
            -- *** THE SECURE FIX ***
            -- We check if the message starts with "You". 
            -- This ignores all messages about other players.
            if string.find(message, "You", 1, true) == 1 then
                
                -- Check for status changes (e.g., "You feel tipsy.")
                if message == "You feel completely smashed." then
                    DrunkModule:SetDrunkState("Smashed")
                elseif message == "You feel drunk.  Woah!" then
                    DrunkModule:SetDrunkState("Drunk")
                elseif message == "You feel tipsy.  Whee!" then
                    DrunkModule:SetDrunkState("Tipsy")
                elseif message == "You feel sober again." then
                    DrunkModule:SetDrunkState("Sober")
                end

                -- *** REMOVED: The logic for "You drink " was here. ***
                -- As you correctly pointed out, this message doesn't exist.
=======
    -- FIXED: Switched to CHAT_MSG_SYSTEM to correctly catch chat log text
    if event == "CHAT_MSG_SYSTEM" then
        -- FIXED: ... expands to individual args, not a table. 
        -- The first arg of CHAT_MSG_SYSTEM is the message string.
        local message = ... 
        
        if message then
            -- Check if the message starts with "You" to filter out other players
            -- Using ^ anchor ensures it is at the start of the string
            if string.find(message, "^You") then
                
                -- Check for status changes
                -- Using string.find is safer than exact equality (==) for chat messages
                if string.find(message, "completely smashed") then
                    DrunkModule:SetDrunkState("Smashed")
                elseif string.find(message, "feel drunk") then
                    DrunkModule:SetDrunkState("Drunk")
                elseif string.find(message, "feel tipsy") then
                    DrunkModule:SetDrunkState("Tipsy")
                elseif string.find(message, "sober again") then
                    DrunkModule:SetDrunkState("Sober")
                end
>>>>>>> f28ad53db299149245eebdada78e99360d0aeda0
            end
        end
    
    elseif event == "PLAYER_LEVEL_UP" then
        local newLevel = ...
        
        -- IDs for the "Apprentice" rank of each primary profession.
        -- These IDs return the localized name (e.g., "Alchemy" or "Alchemie")
        local professionSpellIDs = {
            2259, -- Alchemy
            2018, -- Blacksmithing
            7411, -- Enchanting
            4036, -- Engineering
            2366, -- Herbalism
            2108, -- Leatherworking
            2575, -- Mining
            8613, -- Skinning
            3908, -- Tailoring
        }

        -- Build the validProfessions table dynamically based on client language
        local validProfessions = {}
        for _, spellID in ipairs(professionSpellIDs) do
            local spellName = GetSpellInfo(spellID)
            if spellName then
                validProfessions[spellName] = true
            end
        end

        if newLevel == 20 then
            local professionsAtGoal = 0
            for i = 1, GetNumSkillLines() do
                -- CORRECTED: Rank is 4th, Max is 7th
                local skillName, isHeader, _, skillRank, _, _, skillMax = GetSkillLineInfo(i)
                
                if not isHeader and validProfessions[skillName] then
                    if skillRank >= 150 then
                        professionsAtGoal = professionsAtGoal + 1
                    end
                end
            end

            if professionsAtGoal < 2 then
                local message = "Warning: You must have two primary professions at 150 skill before you reach level 21 or you will fail this challenge!"
                Purity:ShowWarningBanner(message, 30, 2)
            end

        elseif newLevel == 21 then
            local professionsAtGoal = 0
            for i = 1, GetNumSkillLines() do
                -- CORRECTED: Rank is 4th, Max is 7th
                local skillName, isHeader, _, skillRank, _, _, skillMax = GetSkillLineInfo(i)
                
                if not isHeader and validProfessions[skillName] then
                    if skillRank >= 150 then
                        professionsAtGoal = professionsAtGoal + 1
                    end
                end
            end

            if professionsAtGoal < 2 then
                Purity:Violation("Failed the profession audit at level 21. Required: 2 professions at 150 skill. Found: " .. professionsAtGoal)
                return
            else
                Purity:ShowWarningBanner("Profession audit passed! The Drunken Master challenge is now active!", 20, 1)
                if DrunkenMasterStatusFrame and not DrunkenMasterStatusFrame:IsShown() then
                    DrunkenMasterStatusFrame:Show()
                    local db = Purity:GetDB()
                    if not db.drunkFrame then db.drunkFrame = {} end
                    db.drunkFrame.shown = true
                end
            end
        end
    
    -- This is the clean combat violation logic
    elseif event == "PLAYER_REGEN_DISABLED" then -- This event fires when you ENTER combat.
        if isPlayerInCombat then return end
        isPlayerInCombat = true
        
        if UnitLevel("player") >= 21 and (currentDrunkState == "Tipsy" or currentDrunkState == "Sober") then
            Purity:Violation("Entered combat while " .. currentDrunkState .. ".")
        end

        DrunkModule:UpdateStatusDisplay()

    elseif event == "PLAYER_REGEN_ENABLED" then -- This event fires when you LEAVE combat.
        isPlayerInCombat = false
        DrunkModule:UpdateStatusDisplay()
    end
end

DrunkModuleEventHandlerFrame:SetScript("OnEvent", DrunkModule_EventHandler)

function DrunkModule:CreateStatusFrame()
    if DrunkenMasterStatusFrame then return end
    local frame = CreateFrame("Frame", "DrunkenMasterStatusFrame", UIParent, "BackdropTemplate")
    frame:SetSize(220, 80)
    frame:SetBackdrop({ bgFile = "Interface/DialogFrame/UI-DialogBox-Background", edgeFile = "Interface/DialogFrame/UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = { left = 11, right = 12, top = 12, bottom = 11 }})
    frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local db = Purity:GetDB()
        if not db.drunkFrame then db.drunkFrame = {} end
        db.drunkFrame.point, _, db.drunkFrame.relativePoint, db.drunkFrame.x, db.drunkFrame.y = self:GetPoint()
    end)
    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal"); title:SetPoint("TOP", 0, -12); title:SetText("Drunken Master Status")
    frame.currentText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge"); frame.currentText:SetPoint("CENTER", 0, 0);
    frame.combatAllowedText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    frame.combatAllowedText:SetPoint("TOP", frame.currentText, "BOTTOM", 0, -5)
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton"); closeButton:SetPoint("TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        frame:Hide()
        local db = Purity:GetDB()
        if not db.drunkFrame then db.drunkFrame = {} end
        db.drunkFrame.shown = false
    end)
    frame:Hide()
end

function DrunkModule:ToggleStatusFrame()
    if not DrunkenMasterStatusFrame then return end
    local db = Purity:GetDB()
    if not db.drunkFrame then db.drunkFrame = {} end
    if DrunkenMasterStatusFrame:IsShown() then
        DrunkenMasterStatusFrame:Hide()
        db.drunkFrame.shown = false
    else
        DrunkenMasterStatusFrame:Show()
        db.drunkFrame.shown = true
        self:UpdateStatusDisplay()
    end
end

function DrunkModule:InitializeOnPlayerEnterWorld()
    self:CreateStatusFrame()
    local db = Purity:GetDB()
    currentDrunkState = "Sober"
    if db and db.drunkData and db.drunkData.lastState then
        local timeElapsed = GetTime() - (db.drunkData.logoutTimestamp or GetTime())
        if timeElapsed < LOGOUT_BUFFER_TIME then
            currentDrunkState = db.drunkData.lastState
        else
            currentDrunkState = "Sober"
        end
    else
        currentDrunkState = "Sober"
    end
    
    -- This is the correct logic to restore the window
    if db and db.drunkFrame then
        local point = db.drunkFrame.point or "CENTER"
        local relativePoint = db.drunkFrame.relativePoint or "CENTER"
        local x = db.drunkFrame.x or 0
        local y = db.drunkFrame.y or 200
        DrunkenMasterStatusFrame:ClearAllPoints()
        DrunkenMasterStatusFrame:SetPoint(point, UIParent, relativePoint, x, y)
        if db.drunkFrame.shown then
            DrunkenMasterStatusFrame:Show()
        end
    else
        DrunkenMasterStatusFrame:SetPoint("CENTER", 0, 200)
    end
    self:UpdateStatusDisplay()
    
    -- Registering all the events our handler needs
<<<<<<< HEAD
    DrunkModuleEventHandlerFrame:RegisterEvent("UI_INFO_MESSAGE") -- For drunk status
=======
    -- FIXED: Changed from UI_INFO_MESSAGE to CHAT_MSG_SYSTEM
    DrunkModuleEventHandlerFrame:RegisterEvent("CHAT_MSG_SYSTEM") -- For drunk status
>>>>>>> f28ad53db299149245eebdada78e99360d0aeda0
    DrunkModuleEventHandlerFrame:RegisterEvent("PLAYER_REGEN_DISABLED") -- For combat check
    DrunkModuleEventHandlerFrame:RegisterEvent("PLAYER_REGEN_ENABLED") -- For leaving combat
    DrunkModuleEventHandlerFrame:RegisterEvent("PLAYER_LEVEL_UP") -- For profession check
end

function DrunkModule:EventHandler(event, ...)
    -- This function allows the main Purity addon to forward events to our handler
    DrunkModule_EventHandler(event, ...)
end

function DrunkModule:GetChallengeSpecifier() return nil end
function DrunkModule:SaveData() end
function DrunkModule:GetCurrentState()
    return currentDrunkState
end

Purity.GlobalModules.DRUNK = DrunkModule