-- Purity AddOn - Global Challenge: The Glass Heart

local addonName, Purity = ...

local secureGlassHeartState = { current = 0, max = 0 }

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
    partyGlassBars = {},
    groupFrameManager = nil,
    broadcasterFrame = nil,
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

    -- [[ VISUAL HELPERS (MATCHING BLOOD MAGE) ]]
    _HideDefaultHealthBar = function()
        if PlayerFrameHealthBar then PlayerFrameHealthBar:SetAlpha(0) end
        if PlayerFrameHealthBarText then PlayerFrameHealthBarText:Hide() end
        if PlayerFrameHealthBarTextLeft then PlayerFrameHealthBarTextLeft:Hide() end
        if PlayerFrameHealthBarTextRight then PlayerFrameHealthBarTextRight:Hide() end
    end,

    _ShowDefaultHealthBar = function()
        if PlayerFrameHealthBar then PlayerFrameHealthBar:SetAlpha(1) end
        
        local displayMode = GetCVar("statusTextDisplay")
        if displayMode == "BOTH" then
            if PlayerFrameHealthBarText then PlayerFrameHealthBarText:Hide() end
            if PlayerFrameHealthBarTextLeft then PlayerFrameHealthBarTextLeft:Show() end
            if PlayerFrameHealthBarTextRight then PlayerFrameHealthBarTextRight:Show() end
        elseif displayMode == "NONE" then
            if PlayerFrameHealthBarText then PlayerFrameHealthBarText:Hide() end
            if PlayerFrameHealthBarTextLeft then PlayerFrameHealthBarTextLeft:Hide() end
            if PlayerFrameHealthBarTextRight then PlayerFrameHealthBarTextRight:Hide() end
        else
            if PlayerFrameHealthBarText then PlayerFrameHealthBarText:Show() end
            if PlayerFrameHealthBarTextLeft then PlayerFrameHealthBarTextLeft:Hide() end
            if PlayerFrameHealthBarTextRight then PlayerFrameHealthBarTextRight:Hide() end
        end
    end,

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
    
    StartBroadcasting = function(self)
        if self.broadcasterFrame then return end
        self.broadcasterFrame = CreateFrame("Frame")
        
        local lastBroadcastedCurrent = -1
        local lastBroadcastedMax = -1
        local lastBroadcastTime = 0
        
        self.broadcasterFrame:SetScript("OnUpdate", function(frame, elapsed)
            if GetNumGroupMembers() == 0 then return end
            
            local db = Purity:GetDB()
            if not (db and db.activeChallengeID == self.id) then return end
            
            local current = secureGlassHeartState.current
            local max = UnitHealthMax("player")
            
            if not current or not max then return end

            -- Did the value actually change?
            if current ~= lastBroadcastedCurrent or max ~= lastBroadcastedMax then
                local now = GetTime()
                
                -- Send instantly, with a 0.1s buffer ONLY to prevent multi-hit AoE crashes
                if (now - lastBroadcastTime) >= 0.1 then
                    local data = { current = current, max = max }
                    local channel = IsInRaid() and "RAID" or "PARTY"
                    C_ChatInfo.SendAddonMessage(Purity.ADDON_PREFIX, "GLASSHEART_UPDATE:" .. Purity:Serialize(data), channel)
                    
                    lastBroadcastedCurrent = current
                    lastBroadcastedMax = max
                    lastBroadcastTime = now
                end
            end
        end)
    end,

    InitializeOnPlayerEnterWorld = function(self)
        local db = Purity:GetDB()
		secureGlassHeartState.current = db.glassHeartHP or UnitHealthMax("player")
        secureGlassHeartState.max = UnitHealthMax("player")
        local mult = db.glassHeartMultiplier or 1.5
        
        self:StartEngine(mult)
        self:StartBroadcasting()
        self:InitializeGroupFrames() -- Added this line to start target frame monitoring

        -- [[ CHARACTER FRAME HOOKS ]]
        if not self.characterFrameHooked then
            local module = self
            -- Force "Numeric" display when Character Sheet is open to see exact values
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
        if not self.portraitTextHooked then
            hooksecurefunc("CombatFeedback_OnCombatEvent", function(frame, event, flags, amount, type)
                if frame == PlayerFrame and event == "WOUND" and amount and amount > 0 then
                    local db = Purity:GetDB()
                    
                    if db and db.isOptedIn and db.activeChallengeID == self.id then
                        local multiplier = db.glassHeartMultiplier or 1.5
                        local visualDamage = math.floor(amount * multiplier)

                        frame.feedbackText:SetText("-" .. visualDamage)
                    end
                end
            end)
            self.portraitTextHooked = true
        end
    end,

    -- [[ TARGET / PARTY FRAME HANDLING ]]

    RefreshGroupFrames = function(self)
        local units = {"target", "targettarget", "party1", "party2", "party3", "party4"}
        for _, unit in ipairs(units) do
            local healthBar
            local textRegions = {} 
            
            if unit == "target" then
                healthBar = TargetFrameHealthBar
                -- Collect ALL possible text regions for the target frame
                if TargetFrameTextureFrame then
                    if TargetFrameTextureFrame.HealthBarText then table.insert(textRegions, TargetFrameTextureFrame.HealthBarText) end
                    if TargetFrameTextureFrame.HealthBarTextLeft then table.insert(textRegions, TargetFrameTextureFrame.HealthBarTextLeft) end
                    if TargetFrameTextureFrame.HealthBarTextRight then table.insert(textRegions, TargetFrameTextureFrame.HealthBarTextRight) end
                end
                -- Fallback for Classic Era naming conventions
                if #textRegions == 0 then
                    if _G["TargetFrameTextureFrameHealthBarText"] then table.insert(textRegions, _G["TargetFrameTextureFrameHealthBarText"]) end
                    if _G["TargetFrameTextureFrameHealthBarTextLeft"] then table.insert(textRegions, _G["TargetFrameTextureFrameHealthBarTextLeft"]) end
                    if _G["TargetFrameTextureFrameHealthBarTextRight"] then table.insert(textRegions, _G["TargetFrameTextureFrameHealthBarTextRight"]) end
                end
            elseif unit == "targettarget" then
                healthBar = _G["TargetFrameToTHealthBar"]
                -- Try to find standard ToT text to hide, just in case
                if _G["TargetFrameToTHealthBarText"] then table.insert(textRegions, _G["TargetFrameToTHealthBarText"]) end
            else
                local unitNum = string.sub(unit, 6)
                healthBar = _G["PartyMemberFrame" .. unitNum .. "HealthBar"]
                local text = _G["PartyMemberFrame" .. unitNum .. "HealthBarText"]
                if text then table.insert(textRegions, text) end
            end
            
            local bar = self.partyGlassBars[unit]
            
            if UnitExists(unit) and healthBar then
                local isGlassHeart = false
                
                -- 1. CHECK SELF
                if UnitIsUnit(unit, "player") then
                    local db = Purity:GetDB()
                    if db and (db.status == "Passing" or db.status == "Temporary Failure - Uptime") then
                        if db.activeChallengeID == self.id then
                            isGlassHeart = true
                        elseif db.challengeTitle and string.find(db.challengeTitle, "Glass Heart", 1, true) then
                            isGlassHeart = true
                        end
                    end
                end

                -- 2. CHECK OTHERS
                if not isGlassHeart then
                    local name = UnitName(unit)
                    for key, data in pairs(Purity.roster) do
                        local rosterPlayerName = key:match("([^-]+)")
                        if rosterPlayerName and rosterPlayerName == name and (data.status == "Passing" or data.status == "Temporary Failure - Uptime") then
                            if data.challenge and string.find(data.challenge, "Glass Heart", 1, true) then
                                isGlassHeart = true
                                break
                            end
                        end
                    end
                end
                
                if isGlassHeart then
                    if not bar then
                        -- Create our bar as a SIBLING
                        bar = CreateFrame("StatusBar", "PurityGlassGroupBar"..unit, healthBar:GetParent())
                        bar:SetAllPoints(healthBar)
                        bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
                        bar:SetStatusBarColor(0.0, 1.0, 0.0) -- Green
                        
                        -- Match level exactly
                        bar:SetFrameStrata(healthBar:GetFrameStrata())
                        bar:SetFrameLevel(healthBar:GetFrameLevel()) 
                        
                        -- [[ CHANGE 1: BLACK BACKGROUND REMOVED ]]
                        -- The code creating the black texture has been deleted here.

                        -- [[ CHANGE 2: NO TEXT FOR ToT ]]
                        -- We only create text frames if the unit is NOT targettarget
                        if unit ~= "targettarget" then
                            local tf = CreateFrame("Frame", nil, bar)
                            tf:SetAllPoints(bar)
                            tf:SetFrameLevel(bar:GetFrameLevel() + 10) 
                            
                            bar.TextCenter = tf:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
                            bar.TextCenter:SetPoint("CENTER", 0, 0)
                            
                            bar.TextLeft = tf:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
                            bar.TextLeft:SetPoint("LEFT", 2, 0)
                            
                            bar.TextRight = tf:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
                            bar.TextRight:SetPoint("RIGHT", -2, 0)
                            
                            bar.TextFrame = tf
                        end
                        
                        bar.originalHealthBar = healthBar
                        bar.originalTextRegions = textRegions

                        self.partyGlassBars[unit] = bar
                    end
                    
                    -- Initial Hide
                    healthBar:SetAlpha(0) 
                    healthBar:SetStatusBarTexture("") 
                    for _, region in ipairs(textRegions) do region:SetAlpha(0) end
                    bar:Show()
                else
                    -- Restore Original
                    healthBar:SetAlpha(1)
                    healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
                    for _, region in ipairs(textRegions) do region:SetAlpha(1) end
                    if bar then bar:Hide() end
                end
            else
                if healthBar then 
                    healthBar:SetAlpha(1) 
                    healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
                end
                for _, region in ipairs(textRegions) do region:SetAlpha(1) end
                if bar then bar:Hide() end
            end
        end
    end,

    UpdateGroupFrameValues = function(self)
        if GetNumGroupMembers() == 0 and not UnitExists("target") then return end
        
        local units = {"target", "targettarget", "party1", "party2", "party3", "party4"}
        for _, unit in ipairs(units) do
            local bar = self.partyGlassBars[unit]
            if bar and bar:IsShown() then
                
                -- FORCE HIDE
                if bar.originalHealthBar then
                    bar.originalHealthBar:SetAlpha(0)
                    bar.originalHealthBar:SetStatusBarTexture("")
                end
                if bar.originalTextRegions then
                    for _, region in ipairs(bar.originalTextRegions) do region:SetAlpha(0) end
                end

                local current, max
                
                -- 1. UPDATE SELF
                if UnitIsUnit(unit, "player") then
                    local db = Purity:GetDB()
                    if db and db.glassHeartHP then
                        current = db.glassHeartHP
                        max = UnitHealthMax("player")
                    end
                
                -- 2. UPDATE OTHERS
                else
                    local name = UnitName(unit)
                    for key, data in pairs(Purity.roster) do
                        local rosterPlayerName = key:match("([^-]+)")
                        if rosterPlayerName and rosterPlayerName == name then
                            if data.challenge and string.find(data.challenge, "Glass Heart", 1, true) then
                                if data.glassHeartMax and data.glassHeartCurrent then
                                    current = data.glassHeartCurrent
                                    max = data.glassHeartMax
                                end
                                break
                            end
                        end
                    end
                end

                -- 3. UPDATE VISUALS
                if current and max then
                    bar:SetMinMaxValues(0, max)
                    bar:SetValue(current)
                    
                    -- Only update text if the TextFrame exists (It won't exist for ToT)
                    if bar.TextFrame then
                        local mode = GetCVar("statusTextDisplay") or "NUMERIC"
                        
                        bar.TextCenter:SetText("")
                        bar.TextLeft:SetText("")
                        bar.TextRight:SetText("")
                        
                        if mode == "NUMERIC" then
                            bar.TextCenter:SetText(math.ceil(current) .. " / " .. math.ceil(max))
                        elseif mode == "PERCENT" then
                            bar.TextCenter:SetText(math.ceil((current / max) * 100) .. "%")
                        elseif mode == "BOTH" then
                            -- Percent Left, Number Right
                            bar.TextLeft:SetText(math.ceil((current / max) * 100) .. "%")
                            bar.TextRight:SetText(math.ceil(current))
                        end
                    end
                end
            end
        end
    end,

    InitializeGroupFrames = function(self)
        if self.groupFrameManager then return end
        local module = self
        self.groupFrameManager = CreateFrame("Frame")
        self.groupFrameManager:RegisterEvent("GROUP_ROSTER_UPDATE")
        self.groupFrameManager:RegisterEvent("PLAYER_TARGET_CHANGED")
        self.groupFrameManager:RegisterEvent("UNIT_TARGET") -- Detects ToT changes
        self.groupFrameManager:RegisterEvent("PLAYER_ENTERING_WORLD")
        
        self.groupFrameManager:SetScript("OnEvent", function() module:RefreshGroupFrames() end)
        self.groupFrameManager:SetScript("OnUpdate", function() module:UpdateGroupFrameValues() end)
        
        local groupFrameRestorer = CreateFrame("Frame")
        groupFrameRestorer:RegisterEvent("GROUP_LEFT")
        groupFrameRestorer:SetScript("OnEvent", function()
            for i = 1, 4 do
                local healthBar = _G["PartyMemberFrame" .. i .. "HealthBar"]
                if healthBar then healthBar:Show() end
                if module.partyGlassBars["party"..i] then module.partyGlassBars["party"..i]:Hide() end
            end
            module:RefreshGroupFrames()
        end)
        self.groupFrameManager.restorer = groupFrameRestorer
    end,
	
	InitializeNameplates = function(self)
        if self.nameplateManager then return end
        self.nameplateManager = CreateFrame("Frame")
        local lastUpdate = 0
        
        self.nameplateManager:SetScript("OnUpdate", function(frame, elapsed)
            lastUpdate = lastUpdate + elapsed
            if lastUpdate < 0.25 then return end
            lastUpdate = 0
            
            for i = 1, 40 do
                local nameplate = _G["NamePlate" .. i]
                local healthBar = _G["NamePlate" .. i .. "HealthBar"]
                
                if nameplate and nameplate:IsVisible() and nameplate.unit and healthBar then
                    local unit = nameplate.unit
                    if UnitExists(unit) and UnitIsPlayer(unit) then
                        local name = UnitName(unit)
                        local isGlassHeart = false
                        local currentHP, maxHP
                        
                        -- 1. Check Self
                        if UnitIsUnit(unit, "player") then
                            local db = Purity:GetDB()
                            if db and db.activeChallengeID == self.id and (db.status == "Passing" or db.status == "Temporary Failure - Uptime") then
                                isGlassHeart = true
                                currentHP = db.glassHeartHP
                                maxHP = UnitHealthMax("player")
                            end
                        else
                        -- 2. Check Roster
                            local shortName = name:match("([^-]+)")
                            local data = Purity.roster and (Purity.roster[name] or Purity.roster[shortName] or Purity.roster[name .. "-" .. GetRealmName()])
                            if data and data.challenge == self.challengeName and (data.status == "Passing" or data.status == "Temporary Failure - Uptime") then
                                isGlassHeart = true
                                currentHP = data.glassHeartCurrent
                                maxHP = data.glassHeartMax
                            end
                        end
                        
                        local glassBar = nameplate.purityGlassBar
                        if isGlassHeart then
                            if not glassBar then
                                glassBar = CreateFrame("StatusBar", nil, nameplate)
                                glassBar:SetAllPoints(healthBar)
                                glassBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
                                glassBar:SetStatusBarColor(0.0, 1.0, 0.0) -- Green
                                glassBar:SetFrameLevel(healthBar:GetFrameLevel() + 1)
                                local bg = glassBar:CreateTexture(nil, "BACKGROUND")
                                bg:SetAllPoints(true)
                                bg:SetColorTexture(0, 0, 0, 1)
                                nameplate.purityGlassBar = glassBar
                            end
                            healthBar:Hide()
                            glassBar:Show()
                            if maxHP and currentHP then
                                glassBar:SetMinMaxValues(0, maxHP)
                                glassBar:SetValue(currentHP)
                            end
                        else
                            healthBar:Show()
                            if glassBar then glassBar:Hide() end
                        end
                    end
                end
            end
        end)
    end,

    -- [[ GAMEPLAY ENGINE ]]

    StartEngine = function(self, multiplier)
        self.multiplier = multiplier
        self.lastRealHP = UnitHealth("player")
        secureGlassHeartState.current = UnitHealth("player")

        local db = Purity:GetDB()
        if db.glassHeartHP then secureGlassHeartState.current = db.glassHeartHP end

        -- [[ TEMPORARILY MUTE DEFAULT INCOMING DAMAGE ]]
        if db.glassHeartFCTEnabled ~= false then
            Purity:DisableDefaultIncomingDamageText()
        end

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
        self.monitorFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED") 
        
        self.monitorFrame:SetScript("OnEvent", function(frame, event, ...)
            if event == "COMBAT_LOG_EVENT_UNFILTERED" then
                -- Get standard event info
                local timestamp, subEvent, _, _, sourceName, _, _, destGUID, _, _, _, arg12, arg13, arg14, arg15, arg16 = CombatLogGetCurrentEventInfo()
                
                if destGUID == UnitGUID("player") then
                    
                    -- 1. DAMAGE TRACKING (For Log & Display)
                    if string.find(subEvent, "_DAMAGE") then
                        self.lastSource = sourceName or "Unknown"
                        
                        if subEvent == "SWING_DAMAGE" then
                            self.lastAbility = "Melee"
                        elseif subEvent == "RANGE_DAMAGE" then
                            self.lastAbility = "Auto Shot"
                        elseif subEvent == "ENVIRONMENTAL_DAMAGE" then
                            self.lastAbility = arg12 -- e.g. "Falling", "Lava"
                        else
                            self.lastAbility = arg13 or "Ability" 
                        end
                        self.lastDamageTime = GetTime()

                    -- 2. HEALING TRACKING (Overhealing Support)
                    -- If we are at 100% HP, UNIT_HEALTH won't trigger. We need to catch the Overhealing here.
                    elseif subEvent == "SPELL_HEAL" or subEvent == "SPELL_PERIODIC_HEAL" then
                        -- arg15 is amount (Effective), arg16 is Overhealing
                        local overhealing = arg16
                        
                        if overhealing and overhealing > 0 then
                            local maxHP = UnitHealthMax("player")
                            
                            -- Only apply if we actually have room to heal in the Glass Bar
                            if secureGlassHeartState.current < maxHP then
                                secureGlassHeartState.current = secureGlassHeartState.current + overhealing
                                
                                -- Clamp to Max
                                if secureGlassHeartState.current > maxHP then secureGlassHeartState.current = maxHP end
                                
                                -- Save & Update
                                local db = Purity:GetDB()
                                if db then db.glassHeartHP = secureGlassHeartState.current end
                                self:UpdateBar(maxHP)
                            end
                        end
                    end
                end

            elseif event == "PLAYER_LEVEL_UP" then
                local newMax = UnitHealthMax("player")
                secureGlassHeartState.current = newMax
                self.maxRealHP = newMax
                self.lastRealHP = UnitHealth("player")
                
                local db = Purity:GetDB()
                if db then db.glassHeartHP = newMax end
                
                self:UpdateBar(newMax)
                
            elseif event == "UNIT_MAXHEALTH" then
                local oldMax = self.maxRealHP or UnitHealthMax("player")
                local newMax = UnitHealthMax("player")
                if oldMax > 0 and newMax > 0 and oldMax ~= newMax then
                    local ratio = secureGlassHeartState.current / oldMax
                    secureGlassHeartState.current = newMax * ratio
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
        self.regenTicker = C_Timer.NewTicker(2.0, function()
            local db = Purity:GetDB()
            if not (db and db.isOptedIn and db.activeChallengeID == self.id) then return end
            if UnitIsDeadOrGhost("player") then return end
            
            local _, race = UnitRace("player")
            local isTroll = (race == "Troll")
            
            if UnitAffectingCombat("player") and not isTroll then return end

            local maxHP = UnitHealthMax("player")
            local realHP = UnitHealth("player")

            local isEating = false
            for i = 1, 40 do
                local name = UnitAura("player", i, "HELPFUL")
                if not name then break end
                if name == "Food" or name == "Eating" then 
                    isEating = true 
                    break 
                end
            end

            -- FIX: Removed the "or" clause so it ONLY simulates when Real HP is strictly capped
            if realHP >= maxHP and secureGlassHeartState.current < maxHP then
                local _, spirit = UnitStat("player", 5)
                local baseRegen = (spirit * 0.50) + 2 
                
                if isEating then
                    local foodBonus = maxHP * 0.06
                    baseRegen = baseRegen + foodBonus
                end

                if isTroll then
                    if UnitAffectingCombat("player") then
                        baseRegen = baseRegen * 0.10
                    else
                        baseRegen = baseRegen * 1.10
                    end
                end
                
                secureGlassHeartState.current = math.min(maxHP, secureGlassHeartState.current + baseRegen)
                db.glassHeartHP = secureGlassHeartState.current
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
            
            secureGlassHeartState.current = secureGlassHeartState.current - glassDamage
            
            self:LogDamage(damageTaken, glassDamage)
            
            if not db.challengeStats then db.challengeStats = {} end
            db.challengeStats.glassDamageTaken = (db.challengeStats.glassDamageTaken or 0) + glassDamage

            -- [[ CUSTOM FCT INJECTION ]]
            if db.glassHeartFCTEnabled ~= false then
                local isLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) and C_AddOns.IsAddOnLoaded("Blizzard_CombatText") or (type(IsAddOnLoaded) == "function" and IsAddOnLoaded("Blizzard_CombatText"))

                -- Force load the Blizzard Combat Text engine if it's asleep
                if not isLoaded then
                    -- Support for both modern and older Classic client APIs
                    if C_AddOns and C_AddOns.LoadAddOn then
                        C_AddOns.LoadAddOn("Blizzard_CombatText")
                    else
                        LoadAddOn("Blizzard_CombatText")
                    end
                end

                -- Now safely inject our custom message
                if CombatText_AddMessage then
                    local displayDamage = math.floor(glassDamage)
                    CombatText_AddMessage("-" .. displayDamage, CombatText_StandardScroll, 1, 0, 0)
                end
            end

        elseif delta > 0 then
            -- HEALING
            secureGlassHeartState.current = secureGlassHeartState.current + delta
        end

        if secureGlassHeartState.current > maxRealHP then secureGlassHeartState.current = maxRealHP end
        if secureGlassHeartState.current > currentRealHP then secureGlassHeartState.current = currentRealHP end

        if secureGlassHeartState.current < maxRealHP then
            local currentPct = (secureGlassHeartState.current / maxRealHP) * 100
            if not db.challengeStats then db.challengeStats = {} end
            if (not db.challengeStats.lowestGlassHP or currentPct < db.challengeStats.lowestGlassHP) and currentPct > 0 then
                db.challengeStats.lowestGlassHP = currentPct
            end
        end
        
        db.glassHeartHP = secureGlassHeartState.current
        self.lastRealHP = currentRealHP
        self:UpdateBar(maxRealHP)

        if secureGlassHeartState.current <= 0 and not UnitIsDeadOrGhost("player") then
            Purity:Violation("Succumbed to wounds (Effective HP hit 0).")
        end
    end,

    LogDamage = function(self, rawDmg, actualDmg)
        -- Removed the frame visibility check so it always logs to chat
        local sourceText = "|cffff8080" .. (self.lastSource or "Unknown") .. "'s|r"
        local abilityText = "|cffffffff" .. (self.lastAbility or "Hit") .. "|r"

        local msg = string.format("%s %s hits you for |cffff0000%.0f|r |cff888888(Base: %.0f)|r", 
            sourceText, abilityText, actualDmg, rawDmg)

        self:AddLogLine(msg)
    end,

    AddLogLine = function(self, msg)
        local db = Purity:GetDB()
        if not db.glassLogVisible then return end

        -- Send to the dynamic chat tab
        Purity:LogToChatTab("Glass Log", msg)
    end,

    -- [[ VISUAL ENGINE ]]
    
    ApplyVisuals = function(self)
        if not self.visibilityManager then
            local manager = CreateFrame("Frame")
            local module = self
            manager:SetScript("OnUpdate", function()
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
        overlay:SetStatusBarColor(0, 1, 0) -- Green
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
            local function HookHandler(textStatusBar)
                if textStatusBar == PlayerFrameHealthBar and self.overlayBar and self.overlayBar:IsShown() then
                    self:_HideDefaultHealthBar()
                end
            end

            if TextStatusBar_UpdateTextString then
                hooksecurefunc("TextStatusBar_UpdateTextString", HookHandler)
            end
            if TextStatusBar_UpdateTextStringWithValues then
                hooksecurefunc("TextStatusBar_UpdateTextStringWithValues", HookHandler)
            end
            
            PlayerFrameHealthBar:HookScript("OnValueChanged", function()
                if self.overlayBar and self.overlayBar:IsShown() then
                    self:_HideDefaultHealthBar()
                end
            end)
            
            self.hooksInitialized = true
        end
    end,

    UpdateBar = function(self, maxHP)
        if not self.overlayBar or not self.textContainer then return end
        
        local current = math.max(0, math.floor(secureGlassHeartState.current))
        -- Fallback to player max if maxHP is nil
        local max = math.max(1, maxHP or UnitHealthMax("player"))
        
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

        self:_HideDefaultHealthBar()
    end,
    
    ToggleLog = function(self)
        local db = Purity:GetDB()
        db.glassLogVisible = not db.glassLogVisible
        
        if db.glassLogVisible then
            print("|cffFFFF00Purity:|r Glass Heart Chat Logging: |cff00ff00ON|r")
            Purity:LogToChatTab("Glass Log", "|cffFFFF00Purity:|r Glass Heart Damage Log enabled.")
        else
            print("|cffFFFF00Purity:|r Glass Heart Chat Logging: |cffff0000OFF|r")
        end
    end,
    
    EventHandler = function(self, event, ...) 
        if event == "PLAYER_LOGOUT" then
            local db = Purity:GetDB()
            db.glassHeartHP = secureGlassHeartState.current
        end
	end,
	
    SyncTruth = function(self, db)
        -- Crush any HP injections every 1 second
        if db.glassHeartHP ~= secureGlassHeartState.current then
            db.glassHeartHP = secureGlassHeartState.current
            
            -- Force the UI bar to show the real (non-cheated) value
            if self.UpdateBar then self:UpdateBar() end
        end
    end,
    IsSpellForbidden = function() return false end,
    IsItemForbidden = function() return false end,
}

Purity.GlobalModules = Purity.GlobalModules or {}
Purity.GlobalModules["GLASS_HEART"] = GlassHeart