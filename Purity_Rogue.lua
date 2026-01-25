-- Purity AddOn - Rogue Module (Multi-Challenge Build)

if not Purity then
    return
end

local RogueModule = {
    challenges = {}
}

-- ============================================================================
-- CHALLENGE 1: CONTRACT OF PURITY (The Duelist)
-- ============================================================================
RogueModule.challenges.contract = {
    id = "ROGUE_CONTRACT",
    challengeName = "Contract of Purity",
    description = function() 
        return "The Honorable Duelist. This Rogue has sworn a contract of Purity, forsaking the shadows and all underhanded tactics. Every fight is a fair duel, relying on pure skill with blades, not poisons or cheap shots."
    end,
    needsWeaponWarning = false,
    initiatedFromStealth = false,
    forbiddenSpellIDs = {
        -- Poisons
        [3775] = "Crippling Poison", [6947] = "Instant Poison", [2842] = "Poisons",
        [5237] = "Mind-numbing Poison", [6949] = "Instant Poison II", [2892] = "Deadly Poison",
        [10918] = "Wound Poison", [6950] = "Instant Poison III", [2893] = "Deadly Poison II",
        [6951] = "Mind-numbing Poison II", [13228] = "Wound Poison II", [8926] = "Instant Poison IV",
        [8984] = "Deadly Poison III", [10921] = "Wound Poison III", [3776] = "Crippling Poison II",
        [8927] = "Instant Poison V", [9186] = "Mind-numbing Poison III", [8985] = "Deadly Poison IV",
        [10922] = "Wound Poison IV",
        -- Stealth Openers
        [6770] = "Sap (Rank 1)", [8676] = "Ambush (Rank 1)", [703] = "Garrote (Rank 1)",
        [8724] = "Ambush (Rank 2)", [1833] = "Cheap Shot", [2070] = "Sap (Rank 2)",
        [8631] = "Garrote (Rank 2)", [8632] = "Garrote (Rank 3)", [8725] = "Ambush (Rank 3)",
        [11267] = "Ambush (Rank 4)", [8818] = "Garrote (Rank 4)", [11289] = "Garrote (Rank 5)",
        [11297] = "Sap (Rank 3)", [11268] = "Ambush (Rank 5)", [11290] = "Garrote (Rank 6)",
        [11269] = "Ambush (Rank 6)",
        -- Dishonorables
        [53] = "Backstab (Rank 1)", [1776] = "Gouge (Rank 1)", [2589] = "Backstab (Rank 2)",
        [1777] = "Gouge (Rank 2)", [2590] = "Backstab (Rank 3)", [2591] = "Backstab (Rank 4)",
        [921] = "Pick Pocket", [1724] = "Distract", [408] = "Kidney Shot (Rank 1)",
        [2094] = "Blind", [8721] = "Backstab (Rank 5)", [11279] = "Backstab (Rank 6)",
        [8629] = "Gouge (Rank 3)", [11285] = "Gouge (Rank 4)", [8643] = "Kidney Shot (Rank 2)",
        [11280] = "Backstab (Rank 7)",
    },

    GetRulesText = function(self)
        return {
            "|cffffd100The Duelist's Contract:|r",
            "|cff261A0D  • All combat must be faced head-on. Initiating fights from Stealth is forbidden.|r",
            "|cff261A0D  • Your blades must be clean. The learning or use of all Poisons is forbidden.|r",
            "|cff261A0D  • Fight with honor. All 'cheap shots' and tricks are forbidden.|r",
            "|cff261A0D     (Includes: Backstab, Gouge, Kidney Shot, Blind, Sap, Distract, and Pick Pocket).|r",
        }
    end,

    IsSpellForbidden = function(self, spellId)
        if not spellId then return false end
        return self.forbiddenSpellIDs[spellId] ~= nil
    end,
    
    IsItemForbidden = function(self, itemLink) return false end,

    EventHandler = function(self, event, ...)
        if event == "SPELLS_CHANGED" or event == "PLAYER_TALENT_UPDATE" then
            for id, name in pairs(self.forbiddenSpellIDs) do
                if IsSpellKnown(id) then
                    Purity:Violation("Learned a forbidden ability:\n" .. name)
                    return
                end
            end
        elseif event == "PLAYER_REGEN_ENABLED" then
            self.initiatedFromStealth = false
        elseif event == "PLAYER_REGEN_DISABLED" then
            if self.initiatedFromStealth then
                Purity:Violation("Initiated combat from a stealthed state.")
            end
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            local unit, _, _, _, spellId = ...
            if unit == "player" then
                if not UnitAffectingCombat("player") then
                    local isStealthed = false
                    for i=1, 40 do
                        local auraName = UnitAura("player", i)
                        if not auraName then break end
                        if auraName == "Stealth" then isStealthed = true; break; end
                    end
                    if isStealthed and UnitCanAttack("player", "target") and not self:IsSpellForbidden(spellId) then
                        self.initiatedFromStealth = true
                    end
                end
            end
		elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellId, spellName = CombatLogGetCurrentEventInfo()
            if sourceGUID == UnitGUID("player") and subEvent == "SPELL_CAST_SUCCESS" then
                if self:IsSpellForbidden(spellId) then
                    Purity:Violation("Used a forbidden ability:\n" .. spellName)
                end
                -- Stat tracking for Sinister Strike
                local sinisterStrikeIDs = { [1752]=true, [1757]=true, [1758]=true, [1759]=true, [1760]=true, [8621]=true, [11293]=true, [11294]=true }
                if sinisterStrikeIDs[spellId] then
                    local db = Purity:GetDB()
                    if not db.challengeStats then db.challengeStats = {} end
                    db.challengeStats.sinisterStrikeCasts = (db.challengeStats.sinisterStrikeCasts or 0) + 1
					if _G["PurityCharacterPanel"] and _G["PurityCharacterPanel"]:IsShown() then
                        _G["UpdateCharacterPurity"]()
                    end
                end
            end
		end
    end,
}

-- ============================================================================
-- CHALLENGE 2: FOIL OF PURITY (Single Blade)
-- ============================================================================
RogueModule.challenges.foil = {
    id = "ROGUE_FOIL",
    challengeName = "Foil of Purity",
    description = function()
        return "A master of single-blade combat, this Rogue accepts the Foil of Purity, a vow to fight with the grace and precision of a fencer. They forsake the use of an off-hand weapon and all ranged weapons, proving that true skill lies not in a barrage of attacks, but in the perfection of one."
    end,
    needsWeaponWarning = true,
    optInWarningText = "|cffff0000IMPORTANT: This challenge forbids ranged weapons. You must unequip your thrown weapon before you begin.|r",

    forbiddenSpellIDs = {
        [30798] = "Dual Wield" 
    },

    GetRulesText = function(self)
        return {
            "|cffffd100The Foil of Purity:|r",
            "|cff261A0D  • You may not learn Dual Wield.|r",
            "|cff261A0D  • You may not equip any ranged weapon (Bows, Guns, Crossbows, or Thrown).|r",
        }
    end,
    
    IsSpellForbidden = function(self, spellId)
        if not spellId then return false end
        return self.forbiddenSpellIDs and self.forbiddenSpellIDs[spellId] ~= nil
    end,

    isWeaponAllowed = function(self, itemLink)
        if not itemLink then return true end
        
        local _, _, _, _, _, itemType, itemSubType = GetItemInfo(itemLink)
        if itemType == "Weapon" then
            if itemSubType == "Bows" or itemSubType == "Guns" or itemSubType == "Crossbows" or itemSubType == "Thrown" then
                return false
            end
        end
        return true
    end,

    IsItemForbidden = function(self, itemLink)
        if not itemLink then return false end
        return not self:isWeaponAllowed(itemLink)
    end,

    EventHandler = function(self, event, ...)
        if event == "SPELLS_CHANGED" then
            if self:IsSpellForbidden(30798) and IsSpellKnown(30798) then
                 Purity:Violation("Learned the forbidden Dual Wield skill.")
                 return
            end
        elseif event == "PLAYER_EQUIPMENT_CHANGED" then
            Purity:CheckWeaponState()
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellId = CombatLogGetCurrentEventInfo()
            if sourceGUID == UnitGUID("player") and subEvent == "SPELL_CAST_SUCCESS" then
                if spellId == 14251 then
                    local db = Purity:GetDB()
                    if not db.challengeStats then db.challengeStats = {} end
                    db.challengeStats.riposteCasts = (db.challengeStats.riposteCasts or 0) + 1
					if _G["PurityCharacterPanel"] and _G["PurityCharacterPanel"]:IsShown() then
                        _G["UpdateCharacterPurity"]()
                    end
                end
            end
        end
    end,
}

-- ============================================================================
-- CHALLENGE 3: SHROUD OF PURITY (Exposure / Active Mitigation)
-- ============================================================================
RogueModule.challenges.shroud = {
    id = "Shroud of Purity",
    challengeName = "Shroud of Purity",
    description = "You are a stalker, not a soldier. Prolonged open combat leaves you vulnerable. You must strike from the shadows and vanish before your enemies can focus on you. Manage your 'Exposure' to survive.",
    
    exposure = 0,
    maxExposure = 100,
    genRate = 5,    -- Base gain 5 Exposure per sec in combat (20s limit)
    decayRate = 10, -- Base loss 10 Exposure per sec while out of combat
    
    talentMods = { genReduction = 0 },

    controlBonuses = {
        ["Vanish"] = 100,      -- Full Reset
        ["Evasion"] = 40,      -- Massive Mitigation (Active Defense)
        ["Kidney Shot"] = 25,  -- Heavy Control
        ["Blind"] = 20,        -- Disorient
        ["Gouge"] = 15,        -- Incapacitate
        ["Feint"] = 10,        -- Threat Drop
        ["Cheap Shot"] = 10,   -- Stun
        ["Sap"] = 10,          -- CC
    },

    -- Defines spells that "Pause" exposure generation
    hardCCs = {
        ["Gouge"] = true,
        ["Blind"] = true,
        ["Sap"] = true,
        ["Kidney Shot"] = true,
        ["Cheap Shot"] = true,
    },

    InitializeOnPlayerEnterWorld = function(self)
        if self.isInitialized then return end
        
        local db = Purity:GetDB()
        if not db.rogueExposure then db.rogueExposure = 0 end
        self.exposure = db.rogueExposure

        self:CreateExposureBar()
        self:CreateWarningUI()
        
        C_Timer.After(1.0, function() 
            self:CheckTalents() 
            self:SetupTooltips()
        end)
        
        self:StartMonitor()
        self:RegisterEvents()
        
        self.isInitialized = true
    end, -- << COMMA ADDED HERE

    SetupTooltips = function(self)
        local function OnTooltipSetSpell(tooltip)
            local db = Purity:GetDB()
            if db.activeChallengeID ~= "Shroud of Purity" then return end

            local name = tooltip:GetSpell()
            if not name then return end

            local r, g, b = 1, 0.82, 0

            if name == "Vanish" then
                tooltip:AddLine("Instantly resets Exposure to 0.", r, g, b)
            elseif name == "Evasion" then
                tooltip:AddLine("Instantly reduces Exposure by 40.", r, g, b)
            elseif name == "Feint" then
                tooltip:AddLine("Instantly reduces Exposure by 10.", r, g, b)
            elseif self.controlBonuses[name] then
                 local amount = self.controlBonuses[name]
                 tooltip:AddLine("Reduces Exposure by " .. amount .. ".", r, g, b)
            end
            tooltip:Show()
        end
        
        local function OnSetTalent(tooltip, tabIndex, talentIndex)
            local db = Purity:GetDB()
            if db.activeChallengeID ~= "Shroud of Purity" then return end

            local name = GetTalentInfo(tabIndex, talentIndex)
            if not name then return end

            -- Color: Light Blue for Talents
            local r, g, b = 0.6, 0.8, 1.0

            if name == "Master of Deception" then
                tooltip:AddLine("Reduces Exposure generation while visible.", r, g, b)
            elseif name == "Camouflage" then
                 tooltip:AddLine("Increases Exposure decay rate while Stealthed.", r, g, b)
            end
            tooltip:Show()
        end

        if not self.tooltipsHooked then
            GameTooltip:HookScript("OnTooltipSetSpell", OnTooltipSetSpell)
            hooksecurefunc(GameTooltip, "SetTalent", OnSetTalent)
            self.tooltipsHooked = true
        end
    end,

    GetRulesText = function()
        return {
            "|cffffd100Key Mechanics:|r",
            "|cff261A0D  • 'Exposure' builds constantly while you are in combat and visible.|r",
            "|cff261A0D  • Incapacitating enemies (Gouge, Blind, Stun) PAUSES Exposure generation.|r",
            " ",
            "|cffff0000FAIL CONDITION:|r",
            "|cff261A0D  • If Exposure reaches 100%, you are 'Revealed' and the challenge fails immediately.|r",
            " ",
            "|cffffd100Active Mitigation:|r",
            "|cff261A0D  • Evasion: Greatly reduces Exposure.|r",
            "|cff261A0D  • Feint: Slightly reduces Exposure.|r",
            "|cff261A0D  • Vanish: Instantly resets Exposure to 0.|r",
        }
    end,

    CheckTalents = function(self)
        self.talentMods = { genReduction = 0 }
        local numTabs = GetNumTalentTabs()
        for t = 1, numTabs do
            local numTalents = GetNumTalents(t)
            for i = 1, numTalents do
                local name, _, _, _, rank = GetTalentInfo(t, i)
                -- Master of Deception: Rank 5 = 25% slower generation.
                if name == "Master of Deception" and rank > 0 then 
                    self.talentMods.genReduction = rank * 0.05 
                end
            end
        end
    end,

    RegisterEvents = function(self)
        if not self.eventFrame then self.eventFrame = CreateFrame("Frame") end
        self.eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        self.eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        self.eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
        self.eventFrame:SetScript("OnEvent", function(frame, event, ...)
            if event == "PLAYER_TALENT_UPDATE" then
                self:CheckTalents()
            else
                self:EventHandler(event, ...)
            end
        end)
    end,

    EventHandler = function(self, event, ...)
        local db = Purity:GetDB()
        
        if event == "UNIT_SPELLCAST_SUCCEEDED" then
            local unit, _, spellId = ...
            if unit == "player" then
                local spellName = GetSpellInfo(spellId)
                
                if self.controlBonuses[spellName] then
                    -- [[ FIX: Throttle duplicate events ]]
                    -- UNIT_SPELLCAST_SUCCEEDED often fires twice for instants.
                    -- We ignore the second event if it happens within 0.5 seconds of the first.
                    local now = GetTime()
                    if self.lastReductionTime and (now - self.lastReductionTime < 0.5) and (self.lastReductionSpell == spellName) then
                        return
                    end
                    
                    -- Update timestamp to lock this spell out for 0.5s
                    self.lastReductionTime = now
                    self.lastReductionSpell = spellName

                    local reduction = self.controlBonuses[spellName]
                    self.exposure = math.max(0, self.exposure - reduction)
                    self:UpdateBar()
                    
                    if spellName == "Vanish" then
                        self:HideWarning()
                        if not db.challengeStats then db.challengeStats = {} end
                        db.challengeStats.vanishesUsed = (db.challengeStats.vanishesUsed or 0) + 1
                    end
                end
            end
        end
        
        if event == "PLAYER_REGEN_ENABLED" then
            self:HideWarning()
        end
    end,

    IsTargetControlled = function(self)
        if not UnitExists("target") then return false end
        for i = 1, 40 do
            local name = UnitDebuff("target", i)
            if not name then break end
            if self.hardCCs[name] then return true end
        end
        return false
    end,
	
	IsUnitControlled = function(self, unit)
        if not UnitExists(unit) then return false end
        for i = 1, 40 do
            local name = UnitDebuff(unit, i)
            if not name then break end
            if self.hardCCs[name] then return true end
        end
        return false
    end,

    AreAllThreatsControlled = function(self)
        local threatFound = false

        -- Helper to check a specific unit
        local function CheckUnit(unit)
            if UnitExists(unit) and not UnitIsDead(unit) then
                -- API Call: Is the player on this mob's threat table?
                -- Returns 0-3 if yes, nil if no.
                local isThreat = UnitThreatSituation("player", unit)
                
                if isThreat then
                    threatFound = true
                    -- If this mob is angry at us, is it CC'd?
                    if not self:IsUnitControlled(unit) then 
                        return false -- Found an angry mob that is NOT CC'd. Not safe.
                    end
                end
            end
            return true -- This unit is either not a threat or is controlled. Keep checking.
        end

        -- 1. Check Target
        if not CheckUnit("target") then return false end

        -- 2. Check Nameplates (Visible Enemies)
        for i = 1, 40 do
            if not CheckUnit("nameplate"..i) then return false end
        end

        -- 3. Anti-Cheese / Safety Check
        -- If we are in combat but found ZERO mobs on our threat table (e.g. they are off-screen),
        -- we default to "Unsafe" so the bar keeps running.
        if not threatFound then return false end

        -- If we found threats, and ALL of them were CC'd, we are safe.
        return true
    end,

    StartMonitor = function(self)
        if self.monitorTicker then return end
        
        self.monitorTicker = C_Timer.NewTicker(0.1, function()
            local db = Purity:GetDB()
            if UnitIsDeadOrGhost("player") then 
                self.exposure = 0; self:UpdateBar(); return 
            end

            local inCombat = UnitAffectingCombat("player")
            local isStealthed = IsStealthed() or self:HasStealthBuff()
            
            if inCombat and not isStealthed then
                -- [[ UPDATED LOGIC ]]
                -- Only pause if ALL mobs actively threatening you are CC'd.
                if self:AreAllThreatsControlled() then
                    -- PAUSED (Exposure does not increase)
                else
                    -- RUNNING (Apply Talent Reduction if applicable)
                    local rate = self.genRate * (1.0 - self.talentMods.genReduction)
                    self.exposure = self.exposure + (rate * 0.1)
                end
            else
                local decayMult = isStealthed and 2.0 or 1.0
                self.exposure = self.exposure - (self.decayRate * decayMult * 0.1)
            end

            if self.exposure < 0 then self.exposure = 0 end
            if self.exposure > self.maxExposure then self.exposure = self.maxExposure end

            if self.exposure >= self.maxExposure then
                Purity:Violation("You remained exposed for too long.")
                self.exposure = 0 
            end
            
            if self.exposure > 80 then
                self:ShowWarning()
            else
                self:HideWarning()
            end

            db.rogueExposure = self.exposure
            self:UpdateBar()
        end)
    end,

    HasStealthBuff = function(self)
        for i=1,40 do
            local name = UnitBuff("player", i)
            if name == "Stealth" or name == "Vanish" or name == "Shadowmeld" then return true end
        end
        return false
    end,

    CreateExposureBar = function(self)
        if self.barFrame then return end
        
        local f = CreateFrame("Frame", "PurityRogueExposureFrame", UIParent)
        f:SetSize(200, 25)
        f:SetPoint("CENTER", 0, -180)
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)
        
        f.bg = f:CreateTexture(nil, "BACKGROUND")
        f.bg:SetAllPoints(true)
        f.bg:SetColorTexture(0, 0, 0, 0.8)
        
        f.bar = f:CreateTexture(nil, "ARTWORK")
        f.bar:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
        f.bar:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -2)
        f.bar:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 2, 2)
        f.bar:SetWidth(0) 
        f.bar:SetVertexColor(1, 0.8, 0) 
        
        f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        f.text:SetPoint("CENTER")
        f.text:SetText("Exposure: 0%")
        
        f.border = CreateFrame("Frame", nil, f, "BackdropTemplate")
        f.border:SetPoint("TOPLEFT", -2, 2)
        f.border:SetPoint("BOTTOMRIGHT", 2, -2)
        f.border:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12 })
        
        self.barFrame = f
    end,

    UpdateBar = function(self)
        if not self.barFrame then return end
        
        local pct = self.exposure / self.maxExposure
        local totalWidth = self.barFrame:GetWidth() - 4
        
        self.barFrame.bar:SetWidth(math.max(1, totalWidth * pct))
        self.barFrame.text:SetText(string.format("Exposure: %.0f%%", self.exposure))
        
        if pct < 0.5 then
            self.barFrame.bar:SetVertexColor(1, 0.8, 0) 
        elseif pct < 0.8 then
            self.barFrame.bar:SetVertexColor(1, 0.5, 0) 
        else
            self.barFrame.bar:SetVertexColor(1, 0, 0) 
        end
    end,

    CreateWarningUI = function(self)
        if self.warningFrame then return end
        local f = CreateFrame("Frame", "PurityRogueWarning", UIParent)
        f:SetSize(256, 128)
        f:SetPoint("TOP", 0, -200)
        f:Hide()
        
        f.tex = f:CreateTexture(nil, "ARTWORK")
        f.tex:SetAllPoints(true)
        f.tex:SetTexture("Interface\\Icons\\Ability_Stealth") 
        f.tex:SetAlpha(0.5)
        
        f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
        f.text:SetPoint("BOTTOM", f, "TOP", 0, 5)
        f.text:SetText("EXPOSED!")
        f.text:SetTextColor(1, 0, 0)
        
        self.warningFrame = f
    end,

    ShowWarning = function(self)
        if self.warningFrame and not self.warningFrame:IsShown() then
            self.warningFrame:Show()
            PlaySound(8959)
        end
    end,

    HideWarning = function(self)
        if self.warningFrame then self.warningFrame:Hide() end
    end,
}

Purity.ClassModules = Purity.ClassModules or {}
Purity.ClassModules.ROGUE = RogueModule