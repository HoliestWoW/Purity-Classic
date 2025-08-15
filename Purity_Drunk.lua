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

function DrunkModule:SetDrunkState(newState, eventType)
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

local function DrunkModule_EventHandler(event, ...)
    local db = Purity:GetDB()
    if not db.challengeStats then db.challengeStats = {} end
    if not db.challengeStats.drinksConsumed then db.challengeStats.drinksConsumed = 0 end

    if event == "CHAT_MSG_LOOT" then
        local message = ...
        if string.find(message, "You drink") or string.find(message, "drinks") then
            db.challengeStats.drinksConsumed = db.challengeStats.drinksConsumed + 1
            Purity:MarkDBDirty()
        end
    end

    if event == "PLAYER_LEVEL_UP" then
        local newLevel = ...
        if newLevel == 21 then
            -- This is the profession audit.
            local professionsAtGoal = 0
            for i = 1, GetNumSkillLines() do
                local skillName, isHeader, skillRank, _, _, _, _, _, _, _, _, _, skillMax = GetSkillLineInfo(i)
                -- We check for isHeader == false to ignore categories, and skillMax > 0 to filter out secondary professions like Riding.
                if not isHeader and skillMax and skillMax > 0 then
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
		
        elseif newLevel == 20 then
            -- This is the new warning pre-check.
            local professionsAtGoal = 0
            for i = 1, GetNumSkillLines() do
                local skillName, isHeader, skillRank, _, _, _, _, _, _, _, _, _, skillMax = GetSkillLineInfo(i)
                if not isHeader and skillMax and skillMax > 0 then
                    if skillRank >= 150 then
                        professionsAtGoal = professionsAtGoal + 1
                    end
                end
            end

            if professionsAtGoal < 2 then
                local message = "Warning: You must have two primary professions at 150 skill before you reach level 21 or you will fail this challenge!"
                -- The '2' at the end makes the banner red and more urgent.
                Purity:ShowWarningBanner(message, 30, 2)
            end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local timestamp, subevent, _, sourceGUID = CombatLogGetCurrentEventInfo()
        
        if sourceGUID == playerGUID then
            if subevent == "SWING_DAMAGE" or subevent == "SPELL_DAMAGE" or subevent == "RANGE_DAMAGE" or subevent == "SPELL_MISSED" or subevent == "RANGE_MISSED" or subevent == "SWING_MISSED" then
                if UnitLevel("player") >= 21 and (drunkStateOnCombatStart == "Tipsy" or drunkStateOnCombatStart == "Sober") then
                    Purity:Violation("Attacked an enemy while " .. drunkStateOnCombatStart .. ".")
                    drunkStateOnCombatStart = "Drunk" 
                end
            end
        end

    elseif event == "PLAYER_REGEN_DISABLED" then
        isPlayerInCombat = true
        drunkStateOnCombatStart = currentDrunkState
        DrunkModule:UpdateStatusDisplay()

    elseif event == "PLAYER_REGEN_ENABLED" then
        isPlayerInCombat = false
        drunkStateOnCombatStart = "Sober"
        DrunkModule:UpdateStatusDisplay()

    elseif event == "CHAT_MSG_SYSTEM" then
        local message = ...
        
        local drunkLevels = { ["Smashed"] = 4, ["Drunk"] = 3, ["Tipsy"] = 2, ["Sober"] = 1 }
        local previousLevel = drunkLevels[currentDrunkState] or 1

        if string.find(message, "You feel drunk.") then
            local newLevel = drunkLevels["Drunk"]
            local eventType = (newLevel > previousLevel) and "BECAME_DRUNK" or "DECAY_TO_DRUNK"
            DrunkModule:SetDrunkState("Drunk", eventType)
        elseif string.find(message, "You feel tipsy.") then
            local newLevel = drunkLevels["Tipsy"]
            local eventType = (newLevel > previousLevel) and "BECAME_TIPSY" or "DECAY_TO_TIPSY"
            DrunkModule:SetDrunkState("Tipsy", eventType)
        elseif string.find(message, "You feel completely smashed.") then
            DrunkModule:SetDrunkState("Smashed", "BECAME_SMASHED")
        elseif string.find(message, "You feel sober again.") then
            DrunkModule:SetDrunkState("Sober", "BECAME_SOBER")
        end
    end
end

DrunkModuleEventHandlerFrame:SetScript("OnEvent", DrunkModule_EventHandler)

-- NOTE: All other functions (CreateStatusFrame, ToggleStatusFrame, etc.) remain unchanged.
-- They are included below for completeness.

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
    DrunkModuleEventHandlerFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    DrunkModuleEventHandlerFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    DrunkModuleEventHandlerFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    DrunkModuleEventHandlerFrame:RegisterEvent("CHAT_MSG_SYSTEM")
    DrunkModuleEventHandlerFrame:RegisterEvent("PLAYER_LEVEL_UP")
    DrunkModuleEventHandlerFrame:RegisterEvent("CHAT_MSG_LOOT")
end

function DrunkModule:EventHandler(event, ...)
    DrunkModule_EventHandler(event, ...)
end

function DrunkModule:GetChallengeSpecifier() return nil end
function DrunkModule:SaveData() end
function DrunkModule:GetCurrentState()
    return currentDrunkState
end

Purity.GlobalModules.DRUNK = DrunkModule