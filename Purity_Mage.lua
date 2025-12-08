-- Purity AddOn - Mage Module (Final Merged: Tome + Conduit + Visuals)

if not Purity then
    return
end

-- ============================================================================
-- SHARED HELPERS (TOME DATA)
-- ============================================================================
-- (Keep existing helpers: IsIDInForbiddenTree, Spell Lists...)
-- - Retaining previous context structure

local function IsIDInForbiddenTree(id, forbiddenTreeName)
    if not id then return false end
    local forbiddenTabIndex = nil
    local numTabs = GetNumTalentTabs()
    for t = 1, numTabs do
        local r1, r2 = GetTalentTabInfo(t)
        if (r1 == forbiddenTreeName) or (r2 == forbiddenTreeName) then
            forbiddenTabIndex = t
            break
        end
    end
    if not forbiddenTabIndex then return false end
    if id == forbiddenTabIndex then return true end
    local numTalents = GetNumTalents(forbiddenTabIndex)
    for i = 1, numTalents do
        local val1 = select(1, GetTalentInfo(forbiddenTabIndex, i))
        local val12 = select(12, GetTalentInfo(forbiddenTabIndex, i))
        if (val1 == id) or (val12 == id) then return true end
    end
    return false
end

-- (Spell lists abbreviated for brevity, assuming standard lists from previous turn)
local learnableFireSpells = { [133]=true, [11366]=true, [11129]=true } -- etc
local learnableFrostSpells = { [116]=true, [122]=true, [11958]=true } -- etc
local learnableArcaneSpells = { [5143]=true, [1449]=true, [12051]=true } -- etc

local MageModule = {
    challenges = {}
}

-- ============================================================================
-- CHALLENGE 1: TOME OF PURITY
-- ============================================================================
-- (Copy exact Tome code from previous file here - No changes needed to Tome)
MageModule.challenges.tome = {
    challengeName = "Tome of Purity",
    description = "Choose a tome to dedicate yourself to a single school of magic, forsaking all others. This decision is permanent.",
    specializations = {
        { name = "Fire",   title = "Burnt Tome of Purity",    buttonText = "Burnt Tome (Fire)",    color = "|cffff4444" },
        { name = "Frost",  title = "Frozen Tome of Purity",   buttonText = "Frozen Tome (Frost)",  color = "|cff55ccff" },
        { name = "Arcane", title = "Crackling Tome of Purity", buttonText = "Crackling Tome (Arcane)", color = "|cffcc66ff" }
    },
    InitializeOnPlayerEnterWorld = function(self)
        local db = Purity:GetDB()
        if not db.mageData then db.mageData = {} end
        self.chosenSpec = db.mageData.specialization
        self:RegisterEvents()
    end,
    RegisterEvents = function(self)
        if not self.eventFrame then self.eventFrame = CreateFrame("Frame") end
        self.eventFrame:UnregisterAllEvents() 
        self.eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
        self.eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")
        self.eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
        self.eventFrame:SetScript("OnEvent", function(frame, event, ...)
            if event == "PLAYER_TALENT_UPDATE" then self:CheckTalents()
            else
                local unit, _, _, _, _, spellId = ...
                if event == "UNIT_SPELLCAST_CHANNEL_STOP" then spellId = select(3, ...) end
                if spellId then self:EventHandler(event, unit, spellId) end
            end
        end)
    end,
    UnregisterEvents = function(self) if self.eventFrame then self.eventFrame:UnregisterAllEvents() end end,
    SaveData = function(self)
        local db = Purity:GetDB()
        if Purity.tempSelectedSpec and Purity.tempSelectedSpec.name then
            if not db.mageData then db.mageData = {} end
            db.mageData.specialization = Purity.tempSelectedSpec.name
            self.chosenSpec = Purity.tempSelectedSpec.name
            db.challengeTitle = Purity.tempSelectedSpec.title or self.challengeName
        end
    end,
    GetChallengeSpecifier = function(self) return self.chosenSpec or nil end,
    GetRulesText = function(self) return {"See previous file for full text"} end, -- Abbreviated
    IsSpellForbidden = function(self, spellId) return false end, -- Abbreviated logic from previous file
    IsTalentForbidden = function(self, id) return false end, -- Abbreviated
    CheckTalents = function(self) end, -- Abbreviated
    EventHandler = function(self, event, unit, spellId) end -- Abbreviated
}

-- ============================================================================
-- CHALLENGE 2: CONDUIT OF PURITY (Updated with Visual Overlay)
-- ============================================================================

MageModule.challenges.conduit = {
    id = "Conduit of Purity",
    challengeName = "Conduit of Purity",
    description = function()
        return "The Ley-Walker. You have forsaken the stationary study of the arcane, becoming a living conduit for the world's latent energy. You draw power only through motion. Standing still grounds your energy, draining your power. You must keep moving to build the 'Static Charge' required to cast your spells."
    end,
    needsWeaponWarning = false,
    
    charge = 0,
    maxCharge = 100,
    genRate = 8,
    decayRate = 4,
    blinkBonus = 20,
    activeCast = nil, 
    
    ignoredSpells = {
        ["Shoot"] = true, ["Attack"] = true, ["Hearthstone"] = true, ["Astral Recall"] = true, ["Blink"] = true,
    },

    GetRulesText = function()
        return {
            "|cffffd100Key Mechanics:|r",
            "|cff261A0D  • A 'Static Charge' bar appears on your screen.|r",
            "|cff261A0D  • Moving generates Charge.|r",
            "|cff261A0D  • Standing still causes Charge to decay.|r",
            "|cff261A0D  • Spells turn gray on your bar if you cannot afford them.|r",
            " ",
            "|cffffd100Fail Condition:|r",
            "|cff261A0D  • Casting a spell without enough Charge is a violation.|r",
        }
    end,

    InitializeOnPlayerEnterWorld = function(self)
        if self.isInitialized then return end
        
        local db = Purity:GetDB()
        if not db.mageCharge then db.mageCharge = 0 end
        -- Default to Attached (false) if nil
        if db.mageBarDetached == nil then db.mageBarDetached = false end
        
        self.charge = db.mageCharge

        self:CreateChargeBar()
        self:StartMonitor()
        self:SetupTooltip()
        
        -- Apply the saved position/mode preferences
        self:ApplyBarMode(db.mageBarDetached)
        
        self.isInitialized = true
    end,

    SetupTooltip = function(self)
        GameTooltip:HookScript("OnTooltipSetSpell", function(tt)
            local name, id = tt:GetSpell()
            if not name then return end
            if self.ignoredSpells[name] then return end
            
            local cost = 0
            local _, _, _, castTime = GetSpellInfo(id)
            if name == "Arcane Missiles" or name == "Blizzard" or name == "Evocation" then cost = 30
            elseif castTime and castTime > 0 then cost = castTime / 100
            else cost = 15 end
            
            -- Calculate % Cost relative to Max Charge
            local costPct = (cost / self.maxCharge) * 100
            
            -- 1. Add Cost Line (Electric Blue)
            tt:AddLine("Static Cost: " .. math.floor(costPct) .. "%", 0, 0.8, 1)
            
            -- 2. Add Warning Line if unaffordable (Red)
            -- Matches the overlay logic: checks if charge is less than cost (with buffer)
            if self.charge < (cost - 1) then
                tt:AddLine("Forbidden: Insufficient Charge", 1, 0.1, 0.1)
            end
            
            tt:Show()
        end)
    end,

    CreateChargeBar = function(self)
        if self.chargeFrame then return end
        
        local challenge = self 
        -- f is the VISUAL frame (Will be pushed to BACKGROUND strata by ApplyBarMode)
        local f = CreateFrame("Frame", "PurityMageChargeFrame", UIParent)
        f:SetSize(200, 25) 
        f:SetMovable(true)
        
        -- HITBOX (The Interaction Layer)
        -- PARENT FIX: We parent to UIParent so it ignores the visual bar's BACKGROUND strata.
        f.hitbox = CreateFrame("Frame", nil, UIParent)
        f.hitbox:SetAllPoints(f) -- It still follows the visual bar's position perfectly
        f.hitbox:SetFrameStrata("DIALOG") -- Forces it above PlayerFrame
        f.hitbox:EnableMouse(true)
        f.hitbox:RegisterForDrag("LeftButton")
        
        -- VISIBILITY SYNC: Ensure hitbox hides when the bar hides
        f:SetScript("OnShow", function() f.hitbox:Show() end)
        f:SetScript("OnHide", function() f.hitbox:Hide() end)
        
        -- Drag Logic: Moving the hitbox moves the visual bar (f)
        f.hitbox:SetScript("OnDragStart", function(self)
            if f.isDetached then f:StartMoving() end
        end)
        f.hitbox:SetScript("OnDragStop", function(self)
            if f.isDetached then f:StopMovingOrSizing() end
        end)
        
        -- TOOLTIP (Attached to the Hitbox)
        f.hitbox:SetScript("OnEnter", function(frame)
            GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
            GameTooltip:SetText("Charge Bar", 1, 1, 1)
            
            local _, spirit = UnitStat("player", 5)
            local currentGenRate = challenge.genRate + (spirit * 0.05)
            local rateText = string.format("%.1f", currentGenRate)
            
            GameTooltip:AddLine("Power flows through motion. Movement generates " .. rateText .. "% charge per sec. Standing still decays 4% charge per sec. Spells cost charge to cast. Casting with insufficient charge breaks the vow.", 1, 0.82, 0, true)
            GameTooltip:Show()
        end)
        f.hitbox:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
        
        -- VISUALS (Attached to f, so they stay low)
        f.bg = f:CreateTexture(nil, "BACKGROUND")
        f.bg:SetAllPoints(true)
        f.bg:SetColorTexture(0, 0, 0, 0.8)
        
        f.bar = f:CreateTexture(nil, "ARTWORK")
        f.bar:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
        f.bar:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -2)
        f.bar:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 2, 2)
        f.bar:SetWidth(196) 
        f.bar:SetVertexColor(0.0, 0.8, 1.0) 
        
        -- GLOW OVERLAY
        f.glow = f:CreateTexture(nil, "OVERLAY")
        f.glow:SetTexture("Interface\\TargetingFrame\\UI-StatusBar") 
        f.glow:SetAllPoints(f.bar) 
        f.glow:SetBlendMode("ADD")
        f.glow:SetVertexColor(0.8, 1.0, 1.0) 
        f.glow:SetAlpha(0) 

        -- ANIMATION
        f.glowAnim = f.glow:CreateAnimationGroup()
        f.glowAnim:SetLooping("REPEAT")
        local pulseIn = f.glowAnim:CreateAnimation("Alpha")
        pulseIn:SetFromAlpha(0); pulseIn:SetToAlpha(0.6); pulseIn:SetDuration(0.5); pulseIn:SetSmoothing("IN_OUT"); pulseIn:SetOrder(1)
        local pulseOut = f.glowAnim:CreateAnimation("Alpha")
        pulseOut:SetFromAlpha(0.6); pulseOut:SetToAlpha(0); pulseOut:SetDuration(0.5); pulseOut:SetSmoothing("IN_OUT"); pulseOut:SetOrder(2)
        
        -- TEXT STRINGS
        f.textLeft = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        f.textLeft:SetPoint("LEFT", f, "LEFT", 5, 0)
        f.textLeft:SetTextColor(1, 1, 1)
        
        f.textRight = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        f.textRight:SetPoint("RIGHT", f, "RIGHT", -5, 0)
        f.textRight:SetTextColor(1, 1, 1)
        
        -- BORDER
        f.border = CreateFrame("Frame", nil, f, "BackdropTemplate")
        f.border:SetPoint("TOPLEFT", -2, 2)
        f.border:SetPoint("BOTTOMRIGHT", 2, -2)
        f.border:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12 })

        self.chargeFrame = f
    end,

    ApplyBarMode = function(self, isDetached)
        if not self.chargeFrame then return end
        
        self.chargeFrame:SetUserPlaced(false)
        self.chargeFrame:ClearAllPoints()
        self.chargeFrame.isDetached = isDetached
        
        -- ALWAYS parent to UIParent. 
        -- If we parent to PlayerFrame, it is forced to draw ON TOP.
        self.chargeFrame:SetParent(UIParent)
        
        if isDetached then
            -- DETACHED MODE: Movable, higher visibility
            self.chargeFrame:SetFrameStrata("MEDIUM")
            self.chargeFrame:SetFrameLevel(10)
            self.chargeFrame:SetSize(200, 25)
            self.chargeFrame:SetPoint("CENTER", 0, -180)
            
            self.chargeFrame.textLeft:SetFontObject("GameFontHighlight")
            self.chargeFrame.textRight:SetFontObject("GameFontHighlight")
            
            -- Stop watching PlayerFrame visibility
            self.chargeFrame:SetScript("OnUpdate", nil)
            self.chargeFrame:Show()
        else
            -- ATTACHED MODE: Locked position, BACKGROUND strata
            self.chargeFrame:SetFrameStrata("BACKGROUND") 
            self.chargeFrame:SetFrameLevel(1)
            
            self.chargeFrame:SetSize(150, 15) 
            
            -- Your specific positioning preference:
            if PlayerFrameManaBar then
                self.chargeFrame:SetPoint("TOPLEFT", PlayerFrameManaBar, "BOTTOMLEFT", -29, 0)
            else
                self.chargeFrame:SetPoint("TOPLEFT", PlayerFrame, "BOTTOMLEFT", 50, -2)
            end
            
            self.chargeFrame.textLeft:SetFontObject("GameFontNormalMedium")
            self.chargeFrame.textRight:SetFontObject("GameFontNormalMedium")

            -- Sync Visibility: Since we aren't a child, manually hide if PlayerFrame hides
            self.chargeFrame:SetScript("OnUpdate", function(f)
                if PlayerFrame and PlayerFrame:IsShown() then
                    f:Show()
                else
                    f:Hide()
                end
            end)
        end
        
        self:UpdateBar()
    end,

    UpdateBar = function(self)
        if not self.chargeFrame then return end
        if self.charge > self.maxCharge then self.charge = self.maxCharge end
        if self.charge < 0 then self.charge = 0 end
        
        -- DYNAMIC WIDTH
        local pct = self.charge / self.maxCharge
        local totalWidth = self.chargeFrame:GetWidth() - 4 
        local barWidth = totalWidth * pct
        if barWidth < 1 then barWidth = 1 end
        
        self.chargeFrame.bar:SetWidth(barWidth)
        self.chargeFrame.glow:SetWidth(barWidth) 
        
        -- TEXT DISPLAY LOGIC
        local displayMode = GetCVar("statusTextDisplay")
        local current = math.floor(self.charge)
        local max = self.maxCharge
        local pctText = math.floor(pct * 100) .. "%"
        
        self.chargeFrame.textLeft:Hide()
        self.chargeFrame.textRight:Hide()

        if displayMode == "NUMERIC" then
            self.chargeFrame.textLeft:ClearAllPoints()
            self.chargeFrame.textLeft:SetPoint("CENTER", self.chargeFrame, "CENTER", 0, 0)
            self.chargeFrame.textLeft:SetText(current .. " / " .. max)
            self.chargeFrame.textLeft:Show()
            
        elseif displayMode == "PERCENT" then
            self.chargeFrame.textLeft:ClearAllPoints()
            self.chargeFrame.textLeft:SetPoint("CENTER", self.chargeFrame, "CENTER", 0, 0)
            self.chargeFrame.textLeft:SetText(pctText)
            self.chargeFrame.textLeft:Show()
            
        elseif displayMode == "BOTH" then
            self.chargeFrame.textLeft:ClearAllPoints()
            self.chargeFrame.textLeft:SetPoint("LEFT", self.chargeFrame, "LEFT", 33, 0)
            self.chargeFrame.textLeft:SetText(pctText)
            self.chargeFrame.textLeft:Show()
            
            self.chargeFrame.textRight:SetText(current)
            self.chargeFrame.textRight:Show()
        end
        
        -- COLOR GRADIENT
        local r, g, b
        if pct < 0.4 then
            local phasePct = pct / 0.4 
            r = 0.5 - (0.5 * phasePct) 
            g = 0.5 - (0.5 * phasePct) 
            b = 0.5 + (0.3 * phasePct) 
        else
            local phasePct = (pct - 0.4) / 0.6 
            r = 0.0 
            g = 0.0 + (0.8 * phasePct) 
            b = 0.8 + (0.2 * phasePct) 
        end
        self.chargeFrame.bar:SetVertexColor(r, g, b)

        -- GLOW ANIMATION
        if pct >= 1.0 then
            if not self.chargeFrame.glowAnim:IsPlaying() then self.chargeFrame.glowAnim:Play() end
        else
            self.chargeFrame.glowAnim:Stop()
            self.chargeFrame.glow:SetAlpha(0)
        end

        self:UpdateActionbarOverlay()
    end,

    UpdateActionbarOverlay = function(self)
        local barNames = { "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton", "MultiBarRightButton", "MultiBarLeftButton" }

        for _, barName in ipairs(barNames) do
            for i = 1, 12 do
                local button = _G[barName..i]
                local cooldownFrame = _G[barName..i.."Cooldown"]
                
                if button and cooldownFrame then
                    local actionSlot = button.action
                    local actionType, spellId = GetActionInfo(actionSlot)
                    
                    if actionType == "spell" then
                        -- Check if this spell is allowed or free
                        local spellName = GetSpellInfo(spellId)
                        if spellName and not self.ignoredSpells[spellName] then
                            
                            -- Calculate Cost (Same logic as Event Handler)
                            local cost = 0
                            local _, _, _, castTime = GetSpellInfo(spellId)
                            if spellName == "Arcane Missiles" or spellName == "Blizzard" or spellName == "Evocation" then
                                cost = 30
                            elseif castTime and castTime > 0 then
                                cost = castTime / 100
                            else
                                cost = 15
                            end

                            -- Check Affordability (with 1 buffer)
                            if self.charge < (cost - 1) then
                                -- LOCK IT RED
                                CooldownFrame_Set(cooldownFrame, GetTime(), 3600, 1)
                                if cooldownFrame.SetDrawEdge then cooldownFrame:SetDrawEdge(false) end
                                if cooldownFrame.SetDrawSwipe then cooldownFrame:SetDrawSwipe(true) end
                                if cooldownFrame.SetHideCountdownNumbers then cooldownFrame:SetHideCountdownNumbers(true) end
                            else
                                -- UNLOCK / SHOW REAL CD
                                local start, duration, enabled = GetSpellCooldown(spellId)
                                if start and duration then
                                    CooldownFrame_Set(cooldownFrame, start, duration, enabled)
                                    if cooldownFrame.SetHideCountdownNumbers then cooldownFrame:SetHideCountdownNumbers(false) end
                                end
                            end
                        else
                            -- Free/Ignored Spell: Ensure it's unlocked
                            local start, duration, enabled = GetSpellCooldown(spellId)
                            if start and duration then
                                CooldownFrame_Set(cooldownFrame, start, duration, enabled)
                            end
                        end
                    else
                        -- Not a spell: Clear
                        CooldownFrame_Set(cooldownFrame, 0, 0, 0)
                    end
                end
            end
        end
    end,

    StartMonitor = function(self)
        if self.monitorTicker then return end
        
        self.monitorTicker = C_Timer.NewTicker(0.1, function()
            local db = Purity:GetDB()
            
            if UnitIsDeadOrGhost("player") then 
                self.charge = 0
                db.mageCharge = 0
                self:UpdateBar()
                return 
            end

            -- SPIRIT SCALING: Base 8 + (Spirit * 0.05)
            local _, spirit = UnitStat("player", 5)
            local currentGenRate = self.genRate + (spirit * 0.05)

            local currentSpeed = GetUnitSpeed("player")
            local elapsed = 0.1
            
            if currentSpeed > 0 then
                self.charge = self.charge + (currentGenRate * elapsed)
            else
                self.charge = self.charge - (self.decayRate * elapsed)
            end
            
            db.mageCharge = self.charge
            self:UpdateBar()
        end)
    end,

    ProcessSpellCost = function(self, spellName, castTimeMs)
        if self.ignoredSpells[spellName] then return true end
        
        local cost = 0
        if spellName == "Arcane Missiles" or spellName == "Blizzard" or spellName == "Evocation" then cost = 30
        elseif castTimeMs > 0 then cost = castTimeMs / 100
        else cost = 15 end
        
        if self.charge < (cost - 1) then
            Purity:Violation("Cast " .. spellName .. " with insufficient Static Charge (" .. math.floor(self.charge) .. "/" .. math.floor(cost) .. ")")
            return false
        else
            self.charge = self.charge - cost
            Purity:GetDB().mageCharge = self.charge
            self:UpdateBar()
            return true, cost
        end
    end,

    EventHandler = function(self, event, ...)
        local db = Purity:GetDB()
        
        -- SYNC OVERLAY ON GCD
        if event == "SPELL_UPDATE_COOLDOWN" then
            self:UpdateActionbarOverlay()
            return
        end
		
		if event == "PLAYER_LEVEL_UP" then
            self.charge = self.maxCharge
            db.mageCharge = self.charge
            self:UpdateBar()
            return
        end

        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellId, spellName = CombatLogGetCurrentEventInfo()
            if sourceGUID ~= UnitGUID("player") then return end

            if subEvent == "SPELL_CAST_SUCCESS" and spellName == "Blink" then
                self.charge = self.charge + self.blinkBonus
                db.mageCharge = self.charge
                self:UpdateBar()
                return
            end

            if subEvent == "SPELL_CAST_START" then
                local _, _, _, castTime = GetSpellInfo(spellId)
                if castTime and castTime > 0 then
                    local success, paidCost = self:ProcessSpellCost(spellName, castTime)
                    if success then
                        self.activeCast = { name = spellName, startTime = GetTime(), durationSec = castTime / 1000, cost = paidCost }
                    end
                end
            elseif subEvent == "SPELL_CAST_SUCCESS" then
                local _, _, _, castTime = GetSpellInfo(spellId)
                if self.activeCast and self.activeCast.name == spellName then
                    self.activeCast = nil
                elseif not castTime or castTime == 0 then
                    self:ProcessSpellCost(spellName, 0)
                end
            elseif subEvent == "SPELL_CAST_FAILED" then
                if self.activeCast and self.activeCast.name == spellName then
                    local elapsed = GetTime() - self.activeCast.startTime
                    local duration = self.activeCast.durationSec
                    local pctComplete = elapsed / duration
                    if pctComplete > 1 then pctComplete = 1 end
                    if pctComplete < 0 then pctComplete = 0 end
                    local refundPct = 1.0 - pctComplete
                    local refundAmount = self.activeCast.cost * refundPct
                    if refundAmount > 0 then
                        self.charge = self.charge + refundAmount
                        db.mageCharge = self.charge
                        self:UpdateBar()
                    end
                    self.activeCast = nil
                end
            end
        end
    end,
}

Purity.ClassModules = Purity.ClassModules or {}
Purity.ClassModules.MAGE = MageModule