-- Purity AddOn - Rogue Module (Multi-Challenge Build)

local addonName, Purity = ...

local RogueModule = {
    challenges = {}
}

local secureExposure = 0
local lockedRingStateOnLogin = false

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
                        Purity:UpdateCharacterStatus()
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
                        Purity:UpdateCharacterStatus()
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
    description = "You are a stalker, not a soldier. Prolonged open combat leaves you vulnerable. You must strike from the shadows and vanish before your enemies can focus on you. Manage your Exposure to survive.",
    
    exposure = 0,
    maxExposure = 100,
    genRate = 2.5,    -- Base gain 5 Exposure per sec in combat (20s limit)
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
        secureExposure = db.rogueExposure

        self:CreateExposureBar()
        self:CreateWarningUI()
        
        C_Timer.After(1.0, function() 
            self:CheckTalents() 
            self:SetupTooltips()
        end)
        
        self:StartMonitor()
        self:RegisterEvents()
        
        self.isInitialized = true
    end,

    SetupTooltips = function(self)
        -- 1. SPELL TOOLTIP HOOK
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
        
        -- 2. TALENT TOOLTIP HOOK (Seamless Integration)
        -- We scan existing lines for specific keywords and append our text in GOLD.
        local function OnSetTalent(tooltip)
            local db = Purity:GetDB()
            if db.activeChallengeID ~= "Shroud of Purity" then return end

            -- Safe Name Retrieval (Avoiding Crash API)
            local frameName = tooltip:GetName()
            if not frameName then return end

            local line1 = _G[frameName .. "TextLeft1"]
            if not line1 then return end
            
            local name = line1:GetText()
            if not name then return end

            -- Define what to search for and what to append
            local appendData = nil
            
            if name == "Master of Deception" then
                appendData = {
                    keyword = "detect you", -- Matches standard description text
                    text = " Reduces Exposure generation while visible."
                }
            elseif name == "Camouflage" then
                appendData = {
                    keyword = "stealthed", -- Matches "speed while stealthed"
                    text = " Increases Exposure decay rate while Stealthed."
                }
            end

            if appendData then
                for i = 2, tooltip:NumLines() do
                    local line = _G[frameName .. "TextLeft" .. i]
                    if line then
                        local text = line:GetText()
                        if text and string.find(string.lower(text), appendData.keyword) then
                            -- Append text in GOLD (|cffffd100)
                            line:SetText(text .. "|cffffd100" .. appendData.text .. "|r")
                        end
                    end
                end
                tooltip:Show() -- Refresh frame size
            end
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
                    secureExposure = math.max(0, secureExposure - reduction)
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
                secureExposure = 0; self:UpdateBar(); return 
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
                    secureExposure = secureExposure + (rate * 0.1)
                end
            else
                local decayMult = isStealthed and 2.0 or 1.0
                secureExposure = secureExposure - (self.decayRate * decayMult * 0.1)
            end

            if secureExposure < 0 then secureExposure = 0 end
            if secureExposure > self.maxExposure then secureExposure = self.maxExposure end

            if secureExposure >= self.maxExposure then
                Purity:Violation("You remained exposed for too long.")
                secureExposure = 0 
            end
            
            if secureExposure > 80 then
                self:ShowWarning()
            else
                self:HideWarning()
            end

            db.rogueExposure = secureExposure
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
        
        local pct = secureExposure / self.maxExposure
        local totalWidth = self.barFrame:GetWidth() - 4
        
        self.barFrame.bar:SetWidth(math.max(1, totalWidth * pct))
        self.barFrame.text:SetText(string.format("Exposure: %.0f%%", secureExposure))
        
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
	SyncTruth = function(self, db)
        if db.rogueExposure ~= secureExposure then
            db.rogueExposure = secureExposure
            if self.UpdateBar then self:UpdateBar() end
        end
    end,
    SaveData = function(self)
        local db = Purity:GetDB()
        db.rogueExposure = secureExposure
    end,
}

-- ============================================================================

-- CHALLENGE 4: THE RINGBEARER'S VOW (The Halfling)

-- ============================================================================

local RING_ID = 8350 -- The 1 Ring
local secureCorruption = 0

RogueModule.challenges.ringbearer = {
    id = "ROGUE_RINGBEARER",
    challengeName = "The Ringbearer's Vow",
    description = "You carry a burden not meant for mortal hands. You must find The 1 Ring, rely on its dark power to hide from your enemies, and carry it to the fires of Blackrock Mountain to destroy it at Level 60.",
    needsWeaponWarning = true,
    optInWarningText = "|cffff0000IMPORTANT: This challenge requires a Gnome Rogue. You must wield only Daggers or 1H Swords. You cannot use Stealth without The 1 Ring equipped.|r",
	
	IsEligible = function(self)
        local _, race = UnitRace("player")
        return race == "Gnome"
    end,

    GetRulesText = function(self)
        return {
            "|cffffd100The Burden:|r",
            "|cff261A0D  • You must fish up and equip The 1 Ring.|r",
            "|cff261A0D  • You cannot use Stealth unless The 1 Ring is equipped.|r",
            "|cff261A0D  • Equipping the Ring builds Corruption. 100% Corruption fails the challenge.|r",
            "|cff261A0D  • You may only equip a 1H Sword or Dagger in your main hand.|r",
            "|cff261A0D  • No Dual Wielding: Your off-hand must remain empty or hold a non-weapon frill.|r",
            "|cff261A0D  • At Level 60, you must carry the Ring to Blackrock Mountain and destroy it.|r",
        }
    end,

    -- [WEAPON LOCK: Only Swords and Daggers]
    isWeaponAllowed = function(self, itemLink)
        if not itemLink then return true end
        local _, _, _, _, _, itemType, itemSubType = GetItemInfo(itemLink)
        if itemType == "Weapon" then
            if itemSubType == "One-Handed Swords" or itemSubType == "Daggers" or itemSubType == "Fishing Pole" or itemSubType == "Fishing Poles" then
                return true
            end
            return false
        end
        return true
    end,

    IsItemForbidden = function(self, itemLink)
        if not itemLink then return false end
        return not self:isWeaponAllowed(itemLink)
    end,

    InitializeOnPlayerEnterWorld = function(self)
        if self.isInitialized then return end
        local db = Purity:GetDB()
        secureCorruption = db.ringCorruption or 0
		
		if db.challengeStats then
            lockedRingStateOnLogin = db.challengeStats.ringFound or false
        end

        self:CreateCorruptionUI()
        self:CreateShadowRejectUI()
        self:CreateStingGlowUI()
        self:CreateMountDoomUI()
        self:CreateWraithWorldUI()
        
        self:SetupChallengeTooltips() 
        self:StartMonitor()
        
        -- [NEW: The Ring refuses to be discarded manually]
        if not self.deleteMonitor then
            self.deleteMonitor = CreateFrame("Frame")
            self.deleteMonitor:RegisterEvent("DELETE_ITEM_CONFIRM")
            self.deleteMonitor:SetScript("OnEvent", function(_, event, itemName)
                -- If the item being deleted is our ring...
                if itemName and itemName:find("The 1 Ring") then
                    -- Drop it safely back into the bag
                    ClearCursor()
                    
                    -- Instantly close the Blizzard confirmation dialogs (Auto-clicks "No")
                    StaticPopup_Hide("DELETE_ITEM")
                    StaticPopup_Hide("DELETE_GOOD_ITEM")
                    
                    -- Taunt the player
                    UIErrorsFrame:AddMessage("The Ring is yours. You cannot bear to part with it.", 1.0, 0.1, 0.1, 1.0)
                    PlaySound(847)
                    print("|cffFF0000Purity:|r You pull your hand back. The burden must be cast into the fires of Mount Doom.")
                end
            end)
        end
		
        C_Timer.After(4.0, function()
            local isRingEquipped = IsEquippedItem(RING_ID)
            local hasRingInBags = GetItemCount(RING_ID) > 0
            local hasRing = isRingEquipped or hasRingInBags
            
            if lockedRingStateOnLogin and not hasRing then
                Purity:Violation("The Ring is missing. You discarded the burden while unmonitored.")
                return
            end

            if UnitLevel("player") > 10 and not hasRing then
                Purity:Violation("You are past Level 10 without The 1 Ring. You cannot outrun your burden.")
            end
        end)
        
        self.isInitialized = true
    end,

    SetupChallengeTooltips = function(self)
        if self.tooltipsHooked then return end

        -- [1. THE RING ITEM TOOLTIP]
        local function OnTooltipSetItem(tooltip)
            local db = Purity:GetDB()
            if db.activeChallengeID ~= "The Ringbearer's Vow" then return end

            local _, link = tooltip:GetItem()
            if not link then return end

            local itemID = tonumber(link:match("item:(%d+)"))
            if itemID == RING_ID then
                tooltip:AddLine(" ") 
                tooltip:AddLine("Equip: The ring slowly corrupts the bearer's mind. Stealthing is allowed while wearing, but greatly accelerates the corruption.", 0, 1, 0, true)
                tooltip:AddLine("\"The load lightens when resting at an Inn or when near a Campfire.\"", 1, 0.82, 0, true)
                tooltip:Show() 
            end
        end

        -- [2. THE STEALTH SPELL TOOLTIP]
        local function OnTooltipSetSpell(tooltip)
            local db = Purity:GetDB()
            if db.activeChallengeID ~= "The Ringbearer's Vow" then return end

            local spellName = tooltip:GetSpell()
            if spellName == "Stealth" then
                local isRingEquipped = IsEquippedItem(RING_ID)
                
                if not isRingEquipped then
                    local frameName = tooltip:GetName()
                    
                    -- Scan the tooltip lines to find the yellow description
                    for i = 2, tooltip:NumLines() do
                        local fontString = _G[frameName .. "TextLeft" .. i]
                        if fontString then
                            local text = fontString:GetText()
                            local r, g, b = fontString:GetTextColor()
                            
                            -- Detect the standard Blizzard Yellow (r ~ 1.0, g ~ 0.82, b ~ 0.0)
                            if text and r > 0.9 and g > 0.7 and b < 0.2 then
                                
                                -- Prevent the text from stacking infinitely if the tooltip refreshes
                                if not text:find("Requires The 1 Ring equipped") then
                                    -- Splice our red text above the yellow text using a line break
                                    fontString:SetText("|cffFF1919Requires The 1 Ring|r\n" .. text)
                                    tooltip:Show() -- Force the tooltip to resize to fit the new height
                                end
                                break -- We found the description, stop the loop
                            end
                        end
                    end
                end
            end
        end

        -- Hook both systems
        GameTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
        ItemRefTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
        GameTooltip:HookScript("OnTooltipSetSpell", OnTooltipSetSpell)
        
        self.tooltipsHooked = true
    end,

    EventHandler = function(self, event, ...)
        local db = Purity:GetDB()
        
        -- [CAMPFIRE CREATION TRACKING]
        if event == "UNIT_SPELLCAST_SUCCEEDED" then
            local unit, _, spellId = ...
            if unit == "player" then
                local spellName = GetSpellInfo(spellId)
                if spellName == "Basic Campfire" then
                    db.challengeStats = db.challengeStats or {}
                    db.challengeStats.campfiresBuilt = (db.challengeStats.campfiresBuilt or 0) + 1
                end
            end
			
		-- [THE VOW OF THE BEARER: ANTI-VENDOR TRAP]
        elseif event == "MERCHANT_UPDATE" then
            for i = 1, GetNumBuybackItems() do
                local itemLink = GetBuybackItemLink(i)
                if itemLink and itemLink:find("item:" .. RING_ID .. ":") then
                    -- Force the player to immediately buy the ring back
                    BuybackItem(i)
                    
                    -- Taunt the player
                    UIErrorsFrame:AddMessage("The Ring's corrupting influence forces you to take it back.", 1.0, 0.1, 0.1, 1.0)
                    PlaySound(847)
                    print("|cffFF0000Purity:|r The merchant looks terrified and shoves the cursed object back into your hands.")
                    break
                end
            end
			
		-- [THE VOW OF THE BEARER: ANTI-BANK TRAP]
        elseif event == "PLAYERBANKSLOTS_CHANGED" or event == "BAG_UPDATE" then
            -- Prevent multiple trackers from running simultaneously
            if self.isHuntingBank then return end
            self.isHuntingBank = true
            
            local function HuntTheRing()
                local ringFound = false
                local foundBag, foundSlot
                local isLocked = false
                
                -- Sweep the entire bank system (-1 is the main vault, 5-11 are bank bags)
                local bankBags = {-1, 5, 6, 7, 8, 9, 10, 11}
                for _, bag in ipairs(bankBags) do
                    local numSlots = C_Container.GetContainerNumSlots(bag)
                    if numSlots and numSlots > 0 then
                        for slot = 1, numSlots do
                            if C_Container.GetContainerItemID(bag, slot) == RING_ID then
                                ringFound = true
                                foundBag = bag
                                foundSlot = slot
                                local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
                                if itemInfo and itemInfo.isLocked then isLocked = true end
                                break
                            end
                        end
                    end
                    if ringFound then break end
                end

                if ringFound then
                    if not isLocked then
                        ClearCursor()
                        C_Container.PickupContainerItem(foundBag, foundSlot)
                        
                        -- CRITICAL FIX: Verify the server actually allowed us to pick it up!
                        if CursorHasItem() then
                            local itemPlaced = false
                            -- Find an empty slot in the player's personal bags (0-4)
                            for bag = 0, 4 do
                                for bslot = 1, C_Container.GetContainerNumSlots(bag) do
                                    if not C_Container.GetContainerItemInfo(bag, bslot) then
                                        C_Container.PickupContainerItem(bag, bslot)
                                        itemPlaced = true
                                        break
                                    end
                                end
                                if itemPlaced then break end
                            end
                            
                            if itemPlaced then
                                UIErrorsFrame:AddMessage("The burden is yours, and yours alone.", 1.0, 0.1, 0.1)
                                PlaySound(847)
                                self.isHuntingBank = false -- Successfully moved, stop hunting
                                return
                            else
                                ClearCursor()
                                UIErrorsFrame:AddMessage("Your bags are full! You cannot leave The Ring here.", 1.0, 0.1, 0.1)
                                PlaySound(847)
                                self.isHuntingBank = false -- Bags full, stop hunting
                                return
                            end
                        end
                    end
                    
                    -- If the item was locked, OR if CursorHasItem() was false (API rejected the pickup), 
                    -- we do not give up. We try again in exactly 0.1 seconds.
                    C_Timer.After(0.1, HuntTheRing)
                else
                    -- The ring is not in the bank. Stand down.
                    self.isHuntingBank = false
                end
            end
            
            -- Initiate the hunt
            HuntTheRing()
			
		-- [THE VOW OF THE BEARER: LEVEL DEADLINE]
        elseif event == "PLAYER_LEVEL_UP" then
            local newLevel = ...
            
            local isRingEquipped = IsEquippedItem(RING_ID)
            local hasRing = (GetItemCount(RING_ID) > 0) or isRingEquipped
            
            -- 1. The Final Warning (Level 10)
            if newLevel == 10 and not hasRing then
                -- Flash a prominent yellow warning in the center of the screen for 5 seconds
                UIErrorsFrame:AddMessage("WARNING: You must obtain The 1 Ring before Level 11!", 1.0, 0.82, 0.0)
                
                -- Print a permanent message to their chat box
                print("|cffFF0000Purity Warning:|r Your time is running out. You must fish up and carry The 1 Ring before reaching Level 11, or the challenge will fail.")
                
                -- Play the loud "Raid Warning" sound so they physically hear it happen
                PlaySound(8959) 

            -- 2. The Trap Springs (Level 11+)
            elseif newLevel > 10 and not hasRing then
                Purity:Violation("You reached Level 11 without claiming The 1 Ring. You refused the burden.")
                PlaySound(847) -- Harsh Quest Failed sound
            end

        -- [SHADOW REJECT MECHANIC]
        elseif event == "UNIT_AURA" then
            local unitTarget = ...
            if unitTarget ~= "player" then return end
            
            if self.droppingStealthIntentionally then return end
            
            local hasStealth = false
            for i = 1, 40 do
                local auraName = C_UnitAuras.GetBuffDataByIndex("player", i) and C_UnitAuras.GetBuffDataByIndex("player", i).name
                if not auraName then
                    local debuffData = C_UnitAuras.GetDebuffDataByIndex("player", i)
                    auraName = debuffData and debuffData.name
                end
                
                if auraName == "Stealth" then
                    hasStealth = true
                    
                    if not IsEquippedItem(RING_ID) then
                        -- Check if the Ring is physically in their inventory
                        local hasRingInBags = GetItemCount(RING_ID) > 0
                        
                        if hasRingInBags then
                            -- THEY HAVE THE RING: Enforce the burden
                            if UnitAffectingCombat("player") or InCombatLockdown() then
                                -- IN COMBAT: Vanish used. Queue auto-equip.
                                self.pendingVanishEquip = true
                            else
                                -- OUT OF COMBAT: Instant Auto-Equip
                                for bag = 0, 4 do
                                    for slot = 1, C_Container.GetContainerNumSlots(bag) do
                                        if C_Container.GetContainerItemID(bag, slot) == RING_ID then
                                            C_Container.UseContainerItem(bag, slot)
                                            UIErrorsFrame:AddMessage("You donned The 1 Ring to enter the shadows.", 1.0, 0.5, 0.0)
                                            PlaySound(847)
                                            return
                                        end
                                    end
                                end
                            end
                        else
                            -- THEY DO NOT HAVE THE RING: The early-game trap
                            if self.shadowRejectFrame and not self.shadowRejectFrame:IsShown() then
                                self.shadowRejectFrame:Show()
                                UIErrorsFrame:AddMessage("THE SHADOWS REJECT YOU! You must bear the burden first.", 1.0, 0.1, 0.1)
                                PlaySound(847)
                            end
                        end
                    end
                    break
                end
            end
			
		elseif event == "PLAYER_REGEN_ENABLED" then
            -- Check if they used Vanish without manually equipping the Ring
            if self.pendingVanishEquip then
                self.pendingVanishEquip = false 
                
                -- Combat dropped. Force-equip to match the narrative reality.
                for bag = 0, 4 do
                    for slot = 1, C_Container.GetContainerNumSlots(bag) do
                        if C_Container.GetContainerItemID(bag, slot) == RING_ID then
                            C_Container.UseContainerItem(bag, slot)
                            UIErrorsFrame:AddMessage("To survive, you donned The 1 Ring.", 1.0, 0.5, 0.0)
                            PlaySound(847) 
                            return
                        end
                    end
                end
            end
            			
		-- [RARESCANNER COMBAT LOG SENSOR]
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, _, _, _, sourceName, _, _, _, destName = CombatLogGetCurrentEventInfo()
            
            local function IsOrcOrTroll(name)
                return name and (name:find("Orc") or name:find("Troll") or name:find("Grunt"))
            end

            -- Catch them if they cast a spell OR if they get hit by something else nearby
            if IsOrcOrTroll(sourceName) or IsOrcOrTroll(destName) then
                self.recentOrcActivity = GetTime()
            end
            
        -- [WEAPON CHECK & RING UNEQUIP]
        elseif event == "PLAYER_EQUIPMENT_CHANGED" then
            local slotId = ...
            Purity:CheckWeaponState(slotId) 
            
            -- [NEW: Instant Auto-Unstealth if Ring is removed]
            if (slotId == 11 or slotId == 12) and not IsEquippedItem(RING_ID) then
                local isStealthed = false
                for i = 1, 40 do 
                    if UnitAura("player", i) == "Stealth" then 
                        isStealthed = true 
                        break 
                    end 
                end
                
                if isStealthed then
                    -- Flag to tell the rest of the addon we are intentionally unstealthing
                    self.droppingStealthIntentionally = true
                    
                    -- Instantly drop Stealth using the fastest available API functions
                    if CancelShapeshiftForm then CancelShapeshiftForm() end
                    for i = 1, 40 do
                        local name = UnitBuff("player", i)
                        if name == "Stealth" then
                            if CancelUnitBuff then CancelUnitBuff("player", i) end
                            break
                        end
                    end
                    
                    UIErrorsFrame:AddMessage("You stepped out of the shadows by removing The 1 Ring.", 1.0, 0.5, 0.0)
                    
                    -- Clear the flag after 1 second (giving the server time to catch up)
                    C_Timer.After(1.0, function() self.droppingStealthIntentionally = false end)
                end
            end
            
            -- [EXISTING: Dual Wield Prevention]
            local offhandLink = GetInventoryItemLink("player", 17)
            if offhandLink then
                local _, _, _, _, _, itemType = GetItemInfo(offhandLink)
                if itemType == "Weapon" then
                    -- The Instant Auto-Unequip (Bag Bounce)
                    ClearCursor() 
                    PickupInventoryItem(17) 
                    
                    local itemPlaced = false
                    for bag = 0, 4 do
                        for bslot = 1, C_Container.GetContainerNumSlots(bag) do
                            if not C_Container.GetContainerItemInfo(bag, bslot) then
                                C_Container.PickupContainerItem(bag, bslot)
                                itemPlaced = true
                                break
                            end
                        end
                        if itemPlaced then break end
                    end
                    
                    if not itemPlaced then
                        UIErrorsFrame:AddMessage("Bags Full! Swap the forbidden item back manually!", 1.0, 0.1, 0.1, 1.0)
                    end
                    
                    PlaySound(847) 
                    UIErrorsFrame:AddMessage("Ringbearers do not dual wield.", 1.0, 0.1, 0.1, 1.0)
                    print("|cffFF0000Purity:|r The Ringbearer cannot wield a second weapon.")
                end
            end
        end
    end,

    StartMonitor = function(self)
        if self.monitorTicker then return end
        self.monitorTicker = C_Timer.NewTicker(1, function()
            local db = Purity:GetDB()
            if UnitIsDeadOrGhost("player") then return end

            local isRingEquipped = IsEquippedItem(RING_ID)
            local hasRing = (GetItemCount(RING_ID) > 0) or isRingEquipped 
            local isStealthed = false
            for i = 1, 40 do if UnitAura("player", i) == "Stealth" then isStealthed = true; break end end
            
            -- [1. SHADOW REJECT: Blindness] (Stealthed without ring equipped)
            if isStealthed and not isRingEquipped then
                -- Bypass everything if we are in the middle of unstealthing
                if self.droppingStealthIntentionally then
                    -- Do nothing here, just wait patiently for the server to drop the aura
                else
                    local hasRingInBags = GetItemCount(RING_ID) > 0
                    if hasRingInBags then
                        -- They have the ring, it's just taking a split second to equip (or pending Vanish).
                        -- If they are out of combat, force equip it to close the manual unequip loophole.
                        if not UnitAffectingCombat("player") and not InCombatLockdown() then
                            for bag = 0, 4 do
                                for slot = 1, C_Container.GetContainerNumSlots(bag) do
                                    if C_Container.GetContainerItemID(bag, slot) == RING_ID then
                                        C_Container.UseContainerItem(bag, slot)
                                    end
                                end
                            end
                        else
                            self.pendingVanishEquip = true
                        end
                        
                        -- Suppress the black screen while we wait for the server to equip it
                        if self.shadowRejectFrame and self.shadowRejectFrame:IsShown() then
                            self:TriggerShadowReject(false)
                        end
                    else
                        -- No ring in possession at all! Throw the black screen.
                        if not (self.shadowRejectFrame and self.shadowRejectFrame:IsShown()) then
                            self:TriggerShadowReject(true)
                        end
                    end
                end
            else
                if self.shadowRejectFrame and self.shadowRejectFrame:IsShown() then
                    self:TriggerShadowReject(false)
                end
            end

            -- [2. WRAITH WORLD: Visual/Audio] (Stealthed with ring anywhere in possession)
            if isStealthed and hasRing then
                self:TriggerWraithWorld(true)
            else
                self:TriggerWraithWorld(false)
            end
			
            if hasRing and not self.mountDoomCompleted then
                if self.barFrame and not self.barFrame:IsShown() then
                    self.barFrame:Show()
                end
            else
                if self.barFrame and self.barFrame:IsShown() then
                    self.barFrame:Hide()
                end
            end

            -- Check for the Campfire aura
            local hasCampfire = false
            for i = 1, 40 do
                local buffName = UnitBuff("player", i)
                if buffName == "Cozy Fire" then 
                    hasCampfire = true 
                    break 
                end
            end
			
			-- [NEW STATS TRACKING]
            db.challengeStats = db.challengeStats or {}
			
			if hasRing and not db.challengeStats.ringFound then
                db.challengeStats.ringFound = true
            end

            -- 1. Time Spent Fishing
            local channelSpell = UnitChannelInfo("player")
            if channelSpell == "Fishing" then
				if db.challengeStats.ringFound ~= true then
					db.challengeStats.timeSpentFishing = (db.challengeStats.timeSpentFishing or 0) + 1
				end
            end
            
            -- 2. The Burden Shouldered (Times Equipped)
            if isRingEquipped and not self.wasRingEquipped then
                db.challengeStats.timesEquipped = (db.challengeStats.timesEquipped or 0) + 1
            end
            self.wasRingEquipped = isRingEquipped

            -- [1. CORRUPTION GENERATION]
            local burdenRate = 0
            
            -- Calculate the active burden of the Ring
            if isRingEquipped then
                if isStealthed then
                    burdenRate = 0.08 -- The Wraith World
                else
                    burdenRate = 0.03 -- Worn Openly
                end
            elseif hasRing then
                burdenRate = 0.01 -- Normal Travel (Carrying in bags)
            end

            -- [NEW: AUTO-SIT & RP LOGIC]
            local currentSpeed = GetUnitSpeed("player")
            local inCombat = UnitAffectingCombat("player")
            
            -- Only allow auto-sit if standing still, near a fire, CARRYING the ring, AND NOT IN COMBAT
            if currentSpeed == 0 and hasCampfire and hasRing and not inCombat then
                self.stationaryTime = (self.stationaryTime or 0) + 1
                
                -- Trigger the RP Emote and Auto-Sit after 5 seconds of standing still
                if self.stationaryTime == 5 and not self.isAutoSitting then
                    DoEmote("SIT")
                    self.isAutoSitting = true
                    -- Sends the custom orange emote to the chat log
                    SendChatMessage("stares into the flames, finding a momentary peace from the burden.", "EMOTE")
                end
            else
                -- They moved, lost the ring, the fire died, OR entered combat
                self.stationaryTime = 0
                self.isAutoSitting = false
            end

            -- Calculate the active cleanse of the environment
            local cleanseRate = 0
            if IsResting() then
                cleanseRate = 1.5 -- Inn/Sanctuary
            elseif hasCampfire then
                if self.isAutoSitting then
                    cleanseRate = 1.0 -- Doubled for resting by the fire!
                else
                    cleanseRate = 0.5 -- Wilderness Campfire
                end
            end

            -- The Ring fights back! If equipped, the comfort of the fire/inn is heavily suppressed.
            if isRingEquipped and cleanseRate > 0 then
                if IsResting() then
                    cleanseRate = 0.06 
                elseif self.isAutoSitting then
                    cleanseRate = 0.08 -- Doubled!
                else
                    cleanseRate = 0.04 
                end
            end

            -- Apply the net change
            if hasRing then
                local netChange = burdenRate - cleanseRate
                if netChange > 0 then
                    secureCorruption = math.min(100, secureCorruption + netChange)
                else
                    secureCorruption = math.max(0, secureCorruption + netChange)
                end
            else
                -- Ring is banked/destroyed
                if IsResting() then
                    secureCorruption = math.max(0, secureCorruption - 1.5)
                end
            end

            db.ringCorruption = secureCorruption
            self:UpdateCorruptionBar()

            if secureCorruption >= 100 then
                Purity:Violation("Your mind has been entirely consumed by the Ring. You have become a Wraith.")
                return
            end

            if hasRing and secureCorruption < 100 and UnitLevel("player") == 60 then
                local zone = GetZoneText()
                if zone == "Blackrock Mountain" then
                    
                    -- 1. Grab their X and Y Map Coordinates
                    local mapID = C_Map.GetBestMapForUnit("player")
                    local pos = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
                    local x, y = 0, 0
                    if pos then x, y = pos:GetXY() end

                    -- 2. Define the "Forge" Sweet Spot (Dead center of the lava pit)
                    local isAtForge = (x > 0.45 and x < 0.55) and (y > 0.45 and y < 0.55)

                    if not self.mountDoomCompleted and not self.mountDoomDismissed then
                        if self.mountDoomFrame and not self.mountDoomFrame:IsShown() then
                            self.mountDoomFrame:Show()
                        end

                        -- 3. Dynamically update the UI based on location
                        if isAtForge then
                            self.mountDoomFrame.title:SetText("|cffFF4400THE FIRES OF BLACKROCK MOUNTAIN|r\nThe time has come to fulfill your vow.")
                            self.mountDoomFrame.castBtn:Enable()
                            self.mountDoomFrame.castBtn:SetAlpha(1.0)
                        else
                            self.mountDoomFrame.title:SetText("|cffFF4400THE FIRES OF BLACKROCK MOUNTAIN|r\nSeek the central column suspended above the lava.")
                            self.mountDoomFrame.castBtn:Disable()
                            self.mountDoomFrame.castBtn:SetAlpha(0.3)
                        end
                    end
                else
                    -- They left the zone. Reset the dismissal.
                    self.mountDoomDismissed = false 
                    if self.mountDoomFrame and self.mountDoomFrame:IsShown() then
                        self.mountDoomFrame:Hide()
                    end
                end
            else
                -- Failsafe: Hide the frame if they drop the ring
                self.mountDoomDismissed = false
                if self.mountDoomFrame and self.mountDoomFrame:IsShown() then
                    self.mountDoomFrame:Hide()
                end
            end

            -- [3. RARESCANNER-STYLE PROXIMITY SENSOR]
            local orcsNearby = false
            local unitsToScan = {"target", "mouseover", "focus", "targettarget"}
            
            -- Pool all available Nameplates
            for _, nameplate in pairs(C_NamePlate.GetNamePlates()) do
                if nameplate.namePlateUnitToken then
                    table.insert(unitsToScan, nameplate.namePlateUnitToken)
                end
            end

            -- Scan the aggregated units
            for _, unit in ipairs(unitsToScan) do
                if UnitExists(unit) and UnitCanAttack("player", unit) then
                    local name = UnitName(unit)
                    -- In Classic, UnitCreatureType sometimes returns "Orc" instead of Humanoid
                    local creatureType = UnitCreatureType(unit) or "" 
                    if (name and (name:find("Orc") or name:find("Troll") or name:find("Grunt"))) or creatureType == "Orc" then
                        orcsNearby = true
                        break
                    end
                end
            end

            -- Check our Combat Log Cache (10 second decay)
            if not orcsNearby and self.recentOrcActivity then
                if GetTime() - self.recentOrcActivity < 10 then
                    orcsNearby = true
                else
                    self.recentOrcActivity = nil -- Cache expired
                end
            end

            -- [4. TRIGGER STING GLOW]
            if orcsNearby then
                if not self.stingActive then
                    self.stingActive = true
                    self:TriggerStingGlow(true)
                end
            else
                if self.stingActive then
                    self.stingActive = false
                    self:TriggerStingGlow(false)
                end
            end
        end)
    end,

    CreateShadowRejectUI = function(self)
        if self.shadowRejectFrame then return end
        
        -- Create a SecureActionButton instead of a standard Frame
        local f = CreateFrame("Button", "PurityShadowRejectButton", UIParent, "SecureActionButtonTemplate") 
        f:SetAllPoints(UIParent)
        f:SetFrameStrata("FULLSCREEN_DIALOG") 
        
        -- Make the button respond to any mouse click
        f:RegisterForClicks("AnyUp")
        
        -- Assign the secure macro logic
        f:SetAttribute("type", "macro")
        f:SetAttribute("macrotext", "/cancelaura Stealth")

        -- Create the pitch-black texture
        local tex = f:CreateTexture(nil, "BACKGROUND")
        tex:SetAllPoints()
        tex:SetColorTexture(0, 0, 0, 1) -- 100% Black

        -- Warning Text
        f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
        f.text:SetPoint("CENTER", 0, 50)
        f.text:SetText("|cffFF0000THE SHADOWS BLIND YOU!|r")
        
        -- Instructional Text 1
        f.subtext1 = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        f.subtext1:SetPoint("CENTER", 0, 30)
        f.subtext1:SetText("You do not have the ring on you!")

        -- Instructional Text 2
        f.subtext2 = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        f.subtext2:SetPoint("CENTER", 0, 10)
        f.subtext2:SetText("Click anywhere to return to the light.")

        f:Hide()
        self.shadowRejectFrame = f
    end,

    TriggerShadowReject = function(self, enable)
        if enable then
            self.shadowRejectFrame:Show()
        else
            self.shadowRejectFrame:Hide()
        end
    end,
	
	CreateWraithWorldUI = function(self)
        if self.wraithFrame then return end
        
        local f = CreateFrame("Frame", nil, UIParent)
        f:SetAllPoints()
        f:SetFrameStrata("BACKGROUND") 
        
        f.tex = f:CreateTexture(nil, "BACKGROUND")
        f.tex:SetAllPoints()
        -- Changed to BLEND mode for a softer overlay with a spectral teal tint
        f.tex:SetColorTexture(0.05, 0.2, 0.15, 0.35) 
        f.tex:SetBlendMode("BLEND") 
        
        f:Hide()
        self.wraithFrame = f
    end,

    TriggerWraithWorld = function(self, enable)
        if enable then
            if not self.wraithFrame:IsShown() then
                self.wraithFrame:Show()
                
                -- Play immediately and capture the Handle
                local willPlay, soundHandle = PlaySound(4160, "Ambience")
                if willPlay then
                    self.ghostSoundHandle = soundHandle
                end
                
                -- Loop the sound every 48 seconds
                self.ghostSoundTicker = C_Timer.NewTicker(48, function()
                    local wp, sh = PlaySound(4160, "Ambience")
                    if wp then 
                        self.ghostSoundHandle = sh 
                    end
                end)
            end
        else
            if self.wraithFrame:IsShown() then
                self.wraithFrame:Hide()
                
                -- Cancel the looping timer
                if self.ghostSoundTicker then
                    self.ghostSoundTicker:Cancel()
                    self.ghostSoundTicker = nil
                end
                
                -- Kill the currently playing audio instantly
                if self.ghostSoundHandle then
                    StopSound(self.ghostSoundHandle)
                    self.ghostSoundHandle = nil
                end
            end
        end
    end,

    CreateStingGlowUI = function(self)
        if self.stingGlowFrame then return end
        local f = CreateFrame("Frame", nil, UIParent)
        f:SetAllPoints(UIParent)
        f:SetFrameStrata("FULLSCREEN")
        f.tex = f:CreateTexture(nil, "BACKGROUND")
        f.tex:SetAllPoints()
        f.tex:SetTexture("Interface\\FullScreenTextures\\OutofControl")
        f.tex:SetVertexColor(0, 0.5, 1, 0.8)
        f.tex:SetBlendMode("ADD")
        f:Hide()
        self.stingGlowFrame = f
    end,

    TriggerStingGlow = function(self, enable)
        if enable then
            self.stingGlowFrame:Show()
            PlaySound(1210) -- Magical click
        else
            self.stingGlowFrame:Hide()
        end
    end,

    CreateCorruptionUI = function(self)
        if self.barFrame then return end
        local f = CreateFrame("Frame", nil, UIParent)
        f:SetSize(200, 25)
        f:SetPoint("CENTER", 0, -150)
        f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop", f.StopMovingOrSizing)
        
        f.bg = f:CreateTexture(nil, "BACKGROUND")
        f.bg:SetAllPoints(true); f.bg:SetColorTexture(0, 0, 0, 0.8)
        
        f.bar = f:CreateTexture(nil, "ARTWORK")
        f.bar:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
        f.bar:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -2)
        f.bar:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 2, 2)
        f.bar:SetVertexColor(0.5, 0, 0.8)
        
        f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        f.text:SetPoint("CENTER")
        f.text:SetText("Corruption: 0%")
        f:Hide()
        self.barFrame = f
    end,

    CreateMountDoomUI = function(self)
        if self.mountDoomFrame then return end
        local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        f:SetSize(400, 150)
        f:SetPoint("TOP", 0, -150)
        f:SetFrameStrata("DIALOG")
        
        f.bg = f:CreateTexture(nil, "BACKGROUND")
        f.bg:SetAllPoints()
        f.bg:SetColorTexture(0.15, 0.02, 0.0, 0.95)
        
        f:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16 })
        f:SetBackdropBorderColor(1, 0.4, 0) 
        
        f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
        f.title:SetPoint("TOP", 0, -20)
        f.title:SetText("|cffFF4400THE FIRES OF BLACKROCK MOUNTAIN|r\nThe time has come to fulfill your vow.")
        
        -- 1. The "Cast It" Button
        f.castBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        local btn = f.castBtn
        btn:SetSize(240, 50) -- Shrunk width slightly to make room for the second button
        
        -- To perfectly center the group (240 width + 10 gap + 80 width = 330 total width).
        -- We offset the left edge by half the total width (-165).
        btn:SetPoint("BOTTOMLEFT", f, "BOTTOM", -165, 20) 
        btn:SetText("CAST IT INTO THE FIRE!")
        
        local btnText = btn:GetFontString()
        if btnText then
            btnText:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE") -- Font size adjusted to fit 240px
            btnText:SetTextColor(1, 0.5, 0)
        end
        
        btn:SetScript("OnClick", function()
            -- 1. Final verification
            local isRingEquipped = IsEquippedItem(RING_ID)
            local hasRing = (GetItemCount(RING_ID) > 0) or isRingEquipped

            if not hasRing then
                UIErrorsFrame:AddMessage("You do not possess the Ring!", 1.0, 0.1, 0.1, 1.0)
                print("|cffFF0000Purity:|r You reach for the burden, but your hands are empty. It must be cast into the fire.")
                return
            end

            -- 2. Hunt down the physical item and destroy it
            local ringDestroyed = false
            for _, slot in ipairs({11, 12}) do
                if GetInventoryItemID("player", slot) == RING_ID then
                    PickupInventoryItem(slot); DeleteCursorItem()
                    ringDestroyed = true; break
                end
            end
            if not ringDestroyed then
                for bag = 0, 4 do
                    for slot = 1, C_Container.GetContainerNumSlots(bag) do
                        if C_Container.GetContainerItemID(bag, slot) == RING_ID then
                            C_Container.PickupContainerItem(bag, slot); DeleteCursorItem()
                            ringDestroyed = true; break
                        end
                    end
                    if ringDestroyed then break end
                end
            end

            -- 3. Execute Victory Sequence
            local db = Purity:GetDB()
            if db.status == "Passing" or db.status == "Temporary Failure - Uptime" then
                Purity:CompleteChallenge()
                self.mountDoomCompleted = true
                f:Hide()
                self:TriggerShadowReject(false)
                if self.barFrame then self.barFrame:Hide() end
                PlaySound(118)
                print("|cffFFFF00Purity:|r |cffFF8800The Ring has been cast into the fire. The burden is lifted!|r")
            end
        end)

        -- 2. The "Isildur" Dismiss Button
        local closeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        closeBtn:SetSize(80, 50) -- Matched the 50px height of the Cast button
        closeBtn:SetPoint("LEFT", btn, "RIGHT", 10, 0) -- Anchored exactly 10 pixels to the right of the Cast button
        closeBtn:SetText("No.")
        
        local closeText = closeBtn:GetFontString()
        if closeText then
            closeText:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
            closeText:SetTextColor(1, 0.2, 0)
        end

        closeBtn:SetScript("OnClick", function()
            f:Hide()
            self.mountDoomDismissed = true 
            print("|cffFF0000Purity:|r You turn away from the fire. The burden remains.")
        end)
        
        f:Hide()
        self.mountDoomFrame = f
    end,

    UpdateCorruptionBar = function(self)
        if not self.barFrame then return end
        local pct = secureCorruption / 100
        local totalWidth = self.barFrame:GetWidth() - 4
        self.barFrame.bar:SetWidth(math.max(1, totalWidth * pct))
        self.barFrame.text:SetText(string.format("Corruption: %.0f%%", secureCorruption))
    end,
}

Purity.ClassModules = Purity.ClassModules or {}
Purity.ClassModules.ROGUE = RogueModule