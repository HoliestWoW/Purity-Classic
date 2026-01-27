-- Purity AddOn - Global Challenge: The Glass Heart
-- Mechanics: Replaces Player Health Bar. Damage is Multiplied.
-- Features: Smart Spirit-Based Regen, BMB-Style Log (Option Controlled), Native UI.

if not Purity then return end

local GlassHeart = {
    id = "GLASS_HEART",
    challengeName = "The Glass Heart",
    description = "Your resilience is shattered. While your body appears intact, your tolerance for trauma is significantly reduced. This penalty is permanent for the duration of the challenge.",
    needsWeaponWarning = false,

    specializations = {
        { id = "HARD", name = "Hard", buttonText = "Hard (1.5x Damage)", coeffKey = "The Glass Heart (Hard)" },
        { id = "EXTREME", name = "Extreme", buttonText = "Extreme (2.0x Damage)", coeffKey = "The Glass Heart (Extreme)" }
    },

    -- [[ RUNTIME VARIABLES ]]
    currentHP = 0, 
    lastRealHP = 0,
    overlayBar = nil,
    textContainer = nil,
    visibilityManager = nil,
    logFrame = nil,
    regenTicker = nil,
    hooksInitialized = false,
    characterFrameHooked = false,
    forceNumericDisplay = false,

    -- [[ CORE METHODS ]]
    
    SaveData = function(self)
        local db = Purity:GetDB()
        if Purity.tempSelectedSpec then
            db.glassHeartDifficulty = Purity.tempSelectedSpec.id
            db.glassHeartMultiplier = (Purity.tempSelectedSpec.id == "EXTREME") and 2.0 or 1.5
        else
            -- Default fallback
            db.glassHeartDifficulty = "HARD"
            db.glassHeartMultiplier = 1.5
        end
        
        db.glassHeartHP = UnitHealth("player")
        if not db.challengeStats then db.challengeStats = {} end
        db.challengeStats.lowestGlassHP = 100.0
        db.glassLogVisible = false -- Log off by default
    end,

    -- This ensures the Purity core knows which coefficient to pick
    GetChallengeSpecifier = function(self)
        local db = Purity:GetDB()
        return db.glassHeartDifficulty or "HARD"
    end,

    GetChallengeSpecifier = function(self)
        local db = Purity:GetDB()
        return db.glassHeartDifficulty or "HARD"
    end,

    GetRulesText = function(self)
        local mult = "1.5"
        local diffName = "Hard"
        
        if Purity.tempSelectedSpec then
            if Purity.tempSelectedSpec.id == "EXTREME" then mult = "2.0"; diffName = "Extreme" end
        elseif Purity:GetDB().glassHeartMultiplier == 2.0 then
            mult = "2.0"; diffName = "Extreme"
        end

        return {
            "|cffffd100Selected Difficulty: " .. diffName .. "|r",
            "|cff261A0D  • Damage Taken: " .. mult .. "x|r",
            " ",
            "|cffff0000FAIL CONDITION:|r",
            "|cff261A0D  • If your Health reaches 0, you die.|r",
        }
    end,

    InitializeOnPlayerEnterWorld = function(self)
        local db = Purity:GetDB()
        local mult = db.glassHeartMultiplier or 1.5
        
        self:StartEngine(mult)
        self:CreateGlassLogFrame()

        -- [[ LOG VISIBILITY CHECK ]]
        -- Matches BMB behavior: Only show if the option is enabled in DB
        if db.glassLogVisible and self.logFrame then
            self.logFrame:Show()
        end

        -- [[ CHARACTER FRAME HOOKS ]]
        if not self.characterFrameHooked then
            local module = self
            CharacterFrame:HookScript("OnShow", function()
                local db = Purity:GetDB()
                if not (db and db.isOptedIn and db.activeChallengeID == module.id) then return end
                module.forceNumericDisplay = true
                module:UpdateBar(UnitHealthMax("player"))
            end)
            
            CharacterFrame:HookScript("OnHide", function()
                local db = Purity:GetDB()
                if not (db and db.isOptedIn and db.activeChallengeID == module.id) then return end
                module.forceNumericDisplay = false
                module:UpdateBar(UnitHealthMax("player"))
            end)
            self.characterFrameHooked = true
        end
    end,

    -- [[ GAMEPLAY ENGINE ]]

    StartEngine = function(self, multiplier)
        self.multiplier = multiplier
        self.lastRealHP = UnitHealth("player")
        self.currentHP = UnitHealth("player")

        local db = Purity:GetDB()
        if db.glassHeartHP then self.currentHP = db.glassHeartHP end

        self:ApplyVisuals()
        self:StartMonitor()
        self:StartSmartRegen()
        self:UpdateBar(UnitHealthMax("player"))
    end,

    StartMonitor = function(self)
        if self.monitorFrame then return end
        self.monitorFrame = CreateFrame("Frame")
        self.monitorFrame:RegisterEvent("UNIT_HEALTH")
        self.monitorFrame:RegisterEvent("UNIT_MAXHEALTH")
        self.monitorFrame:RegisterEvent("PLAYER_LEVEL_UP")
        self.monitorFrame:RegisterEvent("CVAR_UPDATE") 
        self.monitorFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED") -- [[ NEW: Listen for combat data ]]
        
        self.monitorFrame:SetScript("OnEvent", function(frame, event, ...)
            if event == "COMBAT_LOG_EVENT_UNFILTERED" then
                -- [[ NEW: Capture the 'Who' and 'What' ]]
                local _, subEvent, _, _, sourceName, _, _, destGUID, _, _, _, arg12, arg13 = CombatLogGetCurrentEventInfo()
                
                -- Check if the event is damage directed at the player
                if destGUID == UnitGUID("player") and string.find(subEvent, "_DAMAGE") then
                    self.lastSource = sourceName or "Unknown"
                    
                    if subEvent == "SWING_DAMAGE" then
                        self.lastAbility = "Melee"
                    elseif subEvent == "RANGE_DAMAGE" then
                        self.lastAbility = "Auto Shot"
                    elseif subEvent == "ENVIRONMENTAL_DAMAGE" then
                        self.lastAbility = arg12 -- e.g. "Falling", "Lava"
                    else
                        self.lastAbility = arg13 or "Ability" -- The Spell Name
                    end
                    self.lastDamageTime = GetTime()
                end

            elseif event == "PLAYER_LEVEL_UP" or event == "UNIT_MAXHEALTH" then
                local oldMax = self.maxRealHP or UnitHealthMax("player")
                local newMax = UnitHealthMax("player")
                if oldMax > 0 and newMax > 0 then
                    local ratio = self.currentHP / oldMax
                    self.currentHP = newMax * ratio
                end
                self.maxRealHP = newMax
                self.lastRealHP = UnitHealth("player")
                self:UpdateBar(newMax)
            elseif event == "CVAR_UPDATE" then
                self:UpdateBar(self.maxRealHP or UnitHealthMax("player"))
            else
                self:OnHealthChange()
            end
        end)
    end,

    StartSmartRegen = function(self)
        if self.regenTicker then return end
        
        -- [[ REGEN LOGIC ]]
        -- Fires every 2 seconds (Standard Tick) to simulate natural regen
        self.regenTicker = C_Timer.NewTicker(2.0, function()
            local db = Purity:GetDB()
            if not (db and db.isOptedIn and db.activeChallengeID == self.id) then return end
            if UnitIsDeadOrGhost("player") then return end
            
            -- Trolls regen 10% in combat, others regen 0% in combat (vanilla rules)
            local _, race = UnitRace("player")
            local isTroll = (race == "Troll")
            
            if UnitAffectingCombat("player") and not isTroll then return end

            local maxHP = UnitHealthMax("player")
            local realHP = UnitHealth("player")

            -- If Real HP is full (meaning natural regen stopped), but Glass HP is missing...
            if (realHP >= maxHP and self.currentHP < maxHP) or (UnitAffectingCombat("player") and isTroll) then
                -- ...we manually continue regenerating using Spirit
                local _, spirit = UnitStat("player", 5)
                
                -- Approx formula: (Spirit * 0.5) + 2 per tick
                local baseRegen = (spirit * 0.50) + 2 
                
                -- Apply Troll 10% Bonus
                if isTroll then
                    if UnitAffectingCombat("player") then
                        -- In combat, Trolls get 10% of normal regen
                        baseRegen = baseRegen * 0.10
                    else
                        -- Out of combat, Trolls get 10% BONUS to normal regen
                        baseRegen = baseRegen * 1.10
                    end
                end
                
                self.currentHP = math.min(maxHP, self.currentHP + baseRegen)
                
                db.glassHeartHP = self.currentHP
                self:UpdateBar(maxHP)
            end
        end)
    end,

    OnHealthChange = function(self)
        local currentRealHP = UnitHealth("player")
        local maxRealHP = UnitHealthMax("player")
        self.maxRealHP = maxRealHP 
        
        local delta = currentRealHP - self.lastRealHP
        local db = Purity:GetDB()
        
        if delta < 0 then
            -- DAMAGE
            local damageTaken = math.abs(delta)
            local glassDamage = damageTaken * self.multiplier
            
            self.currentHP = self.currentHP - glassDamage
            
            -- Log the event
            self:LogDamage(damageTaken, glassDamage)
            
            if not db.challengeStats then db.challengeStats = {} end
            db.challengeStats.glassDamageTaken = (db.challengeStats.glassDamageTaken or 0) + glassDamage

        elseif delta > 0 then
            -- HEALING (1:1)
            self.currentHP = self.currentHP + delta
        end

        -- [[ 1. Cap at Max Health ]]
        if self.currentHP > maxRealHP then self.currentHP = maxRealHP end
        
        -- [[ 2. NEW: Safety Clamp (Cannot exceed current real HP) ]]
        if self.currentHP > currentRealHP then 
            self.currentHP = currentRealHP 
        end

        -- Lowest Point Tracking
        if self.currentHP < maxRealHP then
            local currentPct = (self.currentHP / maxRealHP) * 100
            if not db.challengeStats then db.challengeStats = {} end
            if (not db.challengeStats.lowestGlassHP or currentPct < db.challengeStats.lowestGlassHP) and currentPct > 0 then
                db.challengeStats.lowestGlassHP = currentPct
            end
        end
        
        db.glassHeartHP = self.currentHP
        self.lastRealHP = currentRealHP
        self:UpdateBar(maxRealHP)

        if self.currentHP <= 0 and not UnitIsDeadOrGhost("player") then
            Purity:Violation("Succumbed to wounds (Effective HP hit 0).")
        end
    end,

    -- [[ LOGGING SYSTEM (Matches BMB Implementation) ]]
    
    CreateGlassLogFrame = function(self)
        if self.logFrame then return end

        local frame = CreateFrame("Frame", "PurityGlassLogFrame", UIParent)
        local db = Purity:GetDB()
        
        local width = (db and db.glassLogDimensions and db.glassLogDimensions.width) or 300
        local height = (db and db.glassLogDimensions and db.glassLogDimensions.height) or 150
        frame:SetSize(width, height)
        frame:SetResizable(true)
        frame:SetClampedToScreen(true)
        frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
        
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", function(f)
            f:StopMovingOrSizing()
            local point, _, relativePoint, x, y = f:GetPoint()
            if not db.glassLogPosition then db.glassLogPosition = {} end
            db.glassLogPosition = { point = point, relativePoint = relativePoint, x = x, y = y }
        end)
        
        frame:SetScript("OnSizeChanged", function(self, w, h)
            if self.scrollChild then self.scrollChild:SetWidth(w - 30) end
            if self.logLines then for _, line in ipairs(self.logLines) do line:SetWidth(w - 30) end end
            if not db.glassLogDimensions then db.glassLogDimensions = {} end
            db.glassLogDimensions.width = w; db.glassLogDimensions.height = h
        end)

        frame.bg = frame:CreateTexture(nil, "BACKGROUND")
        frame.bg:SetAllPoints(true); frame.bg:SetColorTexture(0, 0, 0, 0.6)
        
        -- Scroll Area
        local scrollFrame = CreateFrame("ScrollFrame", "PurityGlassLogScroll", frame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 5, -5); scrollFrame:SetPoint("BOTTOMRIGHT", -25, 5)
        
        local scrollChild = CreateFrame("Frame")
        scrollChild:SetWidth(frame:GetWidth() - 30)
        scrollChild:SetHeight(1) 
        scrollFrame:SetScrollChild(scrollChild)
        
        frame.scrollFrame = scrollFrame; frame.scrollChild = scrollChild
        frame.logLines = {}
        frame.maxLogLines = 50
        
        -- Resize Handle
        local resize = CreateFrame("Button", nil, frame)
        resize:SetSize(16, 16); resize:SetPoint("BOTTOMRIGHT", -1, 1)
        resize:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeHandle-Up")
        resize:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeHandle-Down")
        resize:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeHandle-Highlight")
        resize:SetScript("OnMouseDown", function() frame:StartSizing("BOTTOMRIGHT") end)
        resize:SetScript("OnMouseUp", function() frame:StopMovingOrSizing() end)
        
        self.logFrame = frame
        
        -- Restore Position or Default to above Chat
        if db.glassLogPosition then
            frame:SetPoint(db.glassLogPosition.point, UIParent, db.glassLogPosition.relativePoint, db.glassLogPosition.x, db.glassLogPosition.y)
        else
            frame:SetPoint("BOTTOMLEFT", ChatFrame1, "TOPLEFT", 0, 40)
        end
        
        -- Hidden by default, controlled by Option Toggle
        frame:Hide()
    end,

    LogDamage = function(self, rawDmg, actualDmg)
        -- Only log if the window is open
        if not self.logFrame or not self.logFrame:IsShown() then return end
        
        local extra = actualDmg - rawDmg
        local sourceText = "|cffff8080Unknown|r"
        local abilityText = "Hit"

        -- [[ NEW: Check for combat log data from the last 0.2 seconds ]]
        if self.lastDamageTime and (GetTime() - self.lastDamageTime < 0.2) then
            sourceText = "|cffff8080" .. (self.lastSource or "Unknown") .. "'s|r"
            abilityText = "|cffffffff" .. (self.lastAbility or "Hit") .. "|r"
        end

        local timestamp = date("|cffc0c0c0[%H:%M:%S]|r ")
        
        -- [[ NEW: Formatted Message ]]
        -- Example: [12:00] Plainstrider's Melee hits you for 50 (Base: 33)
        local msg = string.format("%s%s %s hits you for |cffff0000%.0f|r |cff888888(Base: %.0f)|r", 
            timestamp, sourceText, abilityText, actualDmg, rawDmg)

        self:AddLogLine(msg)
    end,

    AddLogLine = function(self, msg)
        local frame = self.logFrame
        local lines = frame.logLines
        local child = frame.scrollChild
        
        local line = child:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        line:SetJustifyH("LEFT")
        line:SetWidth(child:GetWidth())
        line:SetText(msg)
        
        local prev = lines[#lines]
        if prev then
            line:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -2)
        else
            line:SetPoint("TOPLEFT", child, "TOPLEFT", 0, 0)
        end
        
        table.insert(lines, line)
        
        if #lines > frame.maxLogLines then
            local old = table.remove(lines, 1)
            old:Hide()
            -- Re-anchor first line
            if lines[1] then lines[1]:SetPoint("TOPLEFT", child, "TOPLEFT", 0, 0) end
        end
        
        -- Update Height
        local h = 0
        for _, l in ipairs(lines) do h = h + l:GetHeight() + 2 end
        child:SetHeight(math.max(frame:GetHeight(), h))
        
        -- Scroll to bottom
        frame.scrollFrame:UpdateScrollChildRect()
        frame.scrollFrame:SetVerticalScroll(frame.scrollFrame:GetVerticalScrollRange())
    end,

    -- [[ VISUAL ENGINE ]]
    
    _HideDefaultHealthBar = function()
        if PlayerFrameHealthBar then PlayerFrameHealthBar:SetAlpha(0) end
        if PlayerFrameHealthBarText then PlayerFrameHealthBarText:Hide() end
        if PlayerFrameHealthBarTextLeft then PlayerFrameHealthBarTextLeft:Hide() end
        if PlayerFrameHealthBarTextRight then PlayerFrameHealthBarTextRight:Hide() end
    end,

    ApplyVisuals = function(self)
        if not self.visibilityManager then
            local manager = CreateFrame("Frame")
            local module = self
            manager:SetScript("OnUpdate", function(frame, sinceLastUpdate)
                if module.overlayBar and module.overlayBar:IsShown() then
                    module:_HideDefaultHealthBar()
                end
            end)
            self.visibilityManager = manager
        end

        if self.overlayBar then 
            self.overlayBar:Show()
            if self.textContainer then self.textContainer:Show() end
            return 
        end
        
        if not PlayerFrame or not PlayerFrameHealthBar then return end

        local overlay = CreateFrame("StatusBar", "PurityGlassHeartOverlay", PlayerFrame)
        overlay:SetFrameLevel(PlayerFrameHealthBar:GetFrameLevel()) 
        overlay:SetAllPoints(PlayerFrameHealthBar)
        overlay:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        self.overlayBar = overlay

        local textFrame = CreateFrame("Frame", "PurityGlassHeartText", UIParent)
        textFrame:SetFrameStrata("HIGH") 
        textFrame:SetAllPoints(overlay)
        self.textContainer = textFrame
        
        textFrame.Text = textFrame:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
        textFrame.Text:SetPoint("CENTER", textFrame, "CENTER", 0, 0)
        textFrame.Text:SetTextColor(1, 1, 1)
        
        textFrame.TextLeft = textFrame:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
        textFrame.TextLeft:SetPoint("LEFT", textFrame, "LEFT", 4, 0)
        textFrame.TextLeft:SetTextColor(1, 1, 1)
        
        textFrame.TextRight = textFrame:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
        textFrame.TextRight:SetPoint("RIGHT", textFrame, "RIGHT", -2, 0)
        textFrame.TextRight:SetTextColor(1, 1, 1)

        self:_HideDefaultHealthBar()
        
        if not self.hooksInitialized then
            if TextStatusBar_UpdateTextString then
                hooksecurefunc("TextStatusBar_UpdateTextString", function(textStatusBar)
                    if textStatusBar == PlayerFrameHealthBar and self.overlayBar and self.overlayBar:IsShown() then
                        self:_HideDefaultHealthBar()
                    end
                end)
            elseif TextStatusBar_UpdateTextStringWithValues then
                hooksecurefunc("TextStatusBar_UpdateTextStringWithValues", function(textStatusBar)
                    if textStatusBar == PlayerFrameHealthBar and self.overlayBar and self.overlayBar:IsShown() then
                        self:_HideDefaultHealthBar()
                    end
                end)
            end
            
            PlayerFrameHealthBar:HookScript("OnValueChanged", function()
                if self.overlayBar and self.overlayBar:IsShown() then
                    PlayerFrameHealthBar:SetAlpha(0)
                    self:_HideDefaultHealthBar()
                end
            end)
            
            self.hooksInitialized = true
        end
    end,

    UpdateBar = function(self, maxHP)
        if not self.overlayBar or not self.textContainer then return end
        
        local current = math.max(0, math.floor(self.currentHP))
        local max = math.max(1, maxHP)
        
        self.overlayBar:SetMinMaxValues(0, max)
        self.overlayBar:SetValue(current)
        
        local mode
        if self.forceNumericDisplay then
            mode = "NUMERIC"
        else
            mode = GetCVar("statusTextDisplay") or "NUMERIC"
        end
        
        local textString = ""
        local leftString = ""
        local rightString = ""

        if mode == "NUMERIC" then
            textString = current .. " / " .. max
        elseif mode == "PERCENT" then
            textString = math.ceil((current / max) * 100) .. "%"
        elseif mode == "BOTH" then
            leftString = math.ceil((current / max) * 100) .. "%"
            rightString = current
        end

        self.textContainer.Text:SetText(textString)
        self.textContainer.TextLeft:SetText(leftString)
        self.textContainer.TextRight:SetText(rightString)

        if textString ~= "" then self.textContainer.Text:Show() else self.textContainer.Text:Hide() end
        if leftString ~= "" then self.textContainer.TextLeft:Show() else self.textContainer.TextLeft:Hide() end
        if rightString ~= "" then self.textContainer.TextRight:Show() else self.textContainer.TextRight:Hide() end

        local pct = current / max
        self.overlayBar:SetStatusBarColor(0, 1, 0)
    end,
	
	-- [[ TOGGLE FUNCTION ]]
    ToggleLog = function(self)
        local db = Purity:GetDB()
        db.glassLogVisible = not db.glassLogVisible
        
        if db.glassLogVisible then
            if not self.logFrame then self:CreateGlassLogFrame() end
            self.logFrame:Show()
            print("|cffFFFF00Purity:|r Glass Heart Log: |cff00ff00ON|r")
        else
            if self.logFrame then self.logFrame:Hide() end
            print("|cffFFFF00Purity:|r Glass Heart Log: |cffff0000OFF|r")
        end
    end,
    
    EventHandler = function(self, event, ...) end,
    IsSpellForbidden = function() return false end,
    IsItemForbidden = function() return false end,
}

Purity.GlobalModules = Purity.GlobalModules or {}
Purity.GlobalModules["GLASS_HEART"] = GlassHeart