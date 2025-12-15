-- Purity AddOn - Mage Module (Final Merged: Tome + Conduit + Visuals)

if not Purity then
    return
end

-- ============================================================================
-- SHARED HELPERS (TOME DATA)
-- ============================================================================

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

local learnableFireSpells = {
    [133] = true, [143] = true, [145] = true, [3140] = true, [8400] = true, [8401] = true, [8402] = true, [10148] = true, [10149] = true, [10150] = true, [10151] = true, -- Fireball
    [2136] = true, [2137] = true, [2138] = true, [8403] = true, [8404] = true, [8405] = true, [10152] = true, -- Fire Blast
    [2120] = true, [2121] = true, [8422] = true, [8423] = true, [10215] = true, [10216] = true, -- Flamestrike
    [2948] = true, [8444] = true, [8445] = true, [8446] = true, [10197] = true, [10198] = true, [10199] = true, -- Scorch
    [11366] = true, [12505] = true, [18809] = true, [18810] = true, [18811] = true, [18812] = true, [18813] = true, -- Pyroblast
    [543] = true, [8457] = true, [8458] = true, [10223] = true, [10224] = true, [10225] = true, -- Fire Ward
    [11129] = true, -- Combustion
}

local learnableFrostSpells = {
    [116] = true, [205] = true, [837] = true, [7322] = true, [8406] = true, [8407] = true, [8408] = true, [10179] = true, [10180] = true, [10181] = true, -- Frostbolt
    [122] = true, [865] = true, [8412] = true, [10230] = true, -- Frost Nova
    [168] = true, [7321] = true, [8461] = true, [8462] = true, -- Frost Armor
    [7302] = true, [10219] = true, [10220] = true, -- Ice Armor
    [10] = true, [6141] = true, [8427] = true, [10185] = true, [10186] = true, [10187] = true, -- Blizzard
    [120] = true, [8492] = true, [10159] = true, [10160] = true, [10161] = true, -- Cone of Cold
    [6143] = true, [8464] = true, [8465] = true, [10175] = true, [10176] = true, [10177] = true, -- Frost Ward
    [11958] = true, -- Ice Block
}

local learnableArcaneSpells = {
    [5143] = true, [5144] = true, [5145] = true, [8416] = true, [8417] = true, [10207] = true, [10208] = true, -- Arcane Missiles
    [1449] = true, [8432] = true, [8433] = true, [10203] = true, [10204] = true, [10205] = true, -- Arcane Explosion
    [1459] = true, [1460] = true, [1461] = true, [3158] = true, [10156] = true, -- Arcane Intellect
    [23028] = true, -- Arcane Brilliance
    [6117] = true, [10221] = true, [10222] = true, -- Mage Armor
    [1463] = true, [8494] = true, [8495] = true, [10191] = true, [10192] = true, [10193] = true, -- Mana Shield
    [587] = true, [597] = true, [598] = true, [990] = true, [10144] = true, [10145] = true, -- Conjure Food
    [5504] = true, [5505] = true, [5506] = true, [6127] = true, [10138] = true, [10139] = true, [10140] = true, -- Conjure Water
    [3561] = true, [3562] = true, [3565] = true, [3567] = true, [3563] = true, [3566] = true, -- Teleports
    [10059] = true, [11416] = true, [11417] = true, [11418] = true, [11419] = true, [11420] = true, -- Portals
    [1008] = true, [8453] = true, [8454] = true, [8455] = true, [10168] = true, -- Amplify Magic
    [604] = true, [8449] = true, [8450] = true, [10173] = true, [10174] = true, -- Dampen Magic
    [305] = true, -- Detect Magic
    [475] = true, -- Remove Lesser Curse
    [118] = true, [12824] = true, [12826] = true, [12826] = true, -- Polymorph
    [1953] = true, -- Blink
    [130] = true, -- Slow Fall
    [2139] = true, [23023] = true, [23024] = true, -- Counterspell
    [12051] = true, -- Evocation
}

local MageModule = {
    challenges = {}
}

-- ============================================================================
-- CHALLENGE 1: TOME OF PURITY
-- ============================================================================

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
            if event == "PLAYER_TALENT_UPDATE" then
                self:CheckTalents()
            else
                local unit, _, _, _, _, spellId = ...
                if event == "UNIT_SPELLCAST_CHANNEL_STOP" then spellId = select(3, ...) end
                if spellId then self:EventHandler(event, unit, spellId) end
            end
        end)
    end,

    UnregisterEvents = function(self)
        if self.eventFrame then self.eventFrame:UnregisterAllEvents() end
    end,

    SaveData = function(self)
        local db = Purity:GetDB()
        if Purity.tempSelectedSpec and Purity.tempSelectedSpec.name then
            if not db.mageData then db.mageData = {} end
            db.mageData.specialization = Purity.tempSelectedSpec.name
            self.chosenSpec = Purity.tempSelectedSpec.name
            db.challengeTitle = Purity.tempSelectedSpec.title or self.challengeName
        end
    end,

    GetChallengeSpecifier = function(self)
        return self.chosenSpec or nil
    end,

    GetRulesText = function(self)
        return {
            "|cffffd100Restriction:|r",
            "|cff261A0D  • You may ONLY cast spells from your chosen school.|r",
            "|cff261A0D  • All spells from other schools are forbidden.|r",
            "|cff261A0D  • You may NOT invest talent points into other trees.|r",
            " ",
            "|cffffd100Exceptions:|r",
            "|cff261A0D  • Teleport, Portal, and Conjure spells are allowed.|r",
            "|cff261A0D  • Racials and Profession skills are allowed.|r",
        }
    end,

    IsSpellForbidden = function(self, spellId)
        if not self.chosenSpec then return false end
        
        -- Check if it's a known mage spell at all
        local isFire = learnableFireSpells[spellId]
        local isFrost = learnableFrostSpells[spellId]
        local isArcane = learnableArcaneSpells[spellId]

        if not (isFire or isFrost or isArcane) then return false end

        if self.chosenSpec == "Fire" then
            if isFrost or isArcane then return true end
        elseif self.chosenSpec == "Frost" then
            if isFire or isArcane then return true end
        elseif self.chosenSpec == "Arcane" then
            if isFire or isFrost then return true end
        end
        return false
    end,

    IsTalentForbidden = function(self, id)
        if not self.chosenSpec then return false end
        local forbidden1, forbidden2
        if self.chosenSpec == "Fire" then forbidden1 = "Frost"; forbidden2 = "Arcane"
        elseif self.chosenSpec == "Frost" then forbidden1 = "Fire"; forbidden2 = "Arcane"
        elseif self.chosenSpec == "Arcane" then forbidden1 = "Fire"; forbidden2 = "Frost" end

        if IsIDInForbiddenTree(id, forbidden1) or IsIDInForbiddenTree(id, forbidden2) then
            return true
        end
        return false
    end,

    CheckTalents = function(self)
        if not self.chosenSpec then return end
        for t = 1, GetNumTalentTabs() do
            local numTalents = GetNumTalents(t)
            for i = 1, numTalents do
                local _, _, _, _, pointsSpent = GetTalentInfo(t, i)
                if pointsSpent > 0 then
                     if self:IsTalentForbidden(t) then
                        Purity:Violation("Invested talent points in a forbidden school.")
                        return
                     end
                end
            end
        end
    end,

    EventHandler = function(self, event, unit, spellId)
        if unit ~= "player" then return end
        if self:IsSpellForbidden(spellId) then
            local spellName = GetSpellInfo(spellId)
            Purity:Violation("Cast forbidden spell: " .. (spellName or "Unknown"))
        end
    end
}

-- ============================================================================
-- CHALLENGE 2: CONDUIT OF PURITY (Updated with Lore-First Balance)
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
            "|cff261A0D  • Moving generates Charge. Standing still decays it.|r",
            "|cff261A0D  • Spells cost Charge to cast. Costs are shown on the icons.|r",
            " ",
            "|cffffd100Grace Period:|r",
            "|cff261A0D  • If you start a cast without enough Charge, you will be WARNED.|r",
            "|cff261A0D  • You must CANCEL the cast immediately to avoid failure.|r",
            "|cff261A0D  • If the spell successfully completes while you have insufficient Charge, you fail.|r",
            "|cff261A0D  • Cancelling a cast refunds the FULL Charge cost.|r",
        }
    end, 

    InitializeOnPlayerEnterWorld = function(self)
        if self.isInitialized then return end
        
        local db = Purity:GetDB()
        if not db.mageCharge then db.mageCharge = 0 end
        if db.mageBarDetached == nil then db.mageBarDetached = false end
        
        self.charge = db.mageCharge

        self:CreateChargeBar()
        self:CreateWarningUI()
        self:CheckTalents()
        self:StartMonitor()
        self:SetupTooltip()
        self:RegisterConduitEvents() 
        
        self:ApplyBarMode(db.mageBarDetached)
        self.isInitialized = true
    end,
    
    CheckTalents = function(self)
        -- Reset mods
        self.talentMods = { decay = 0, cost = 0, gen = 0 }
        
        local numTabs = GetNumTalentTabs()
        for t = 1, numTabs do
            local numTalents = GetNumTalents(t)
            for i = 1, numTalents do
                local nameTalent, _, _, _, rank = GetTalentInfo(t, i)
                
                -- ARCANE (Tier 4): Arcane Meditation
                -- Theme: The Architect -> Efficient Structuring (10% per rank / 30% total)
                if nameTalent == "Arcane Meditation" and rank > 0 then
                    self.talentMods.cost = rank * 0.10 
                end
                
                -- FROST (Tier 3): Frost Channeling
                -- Theme: The Superconductor -> Low Resistance (10% per rank / 30% total)
                if nameTalent == "Frost Channeling" and rank > 0 then
                    self.talentMods.gen = rank * 0.10 
                end
                
                -- FIRE (Tier 3): Burning Soul
                -- Theme: The Furnace -> Banked Heat (25% per rank / 50% total)
                if nameTalent == "Burning Soul" and rank > 0 then
                    self.talentMods.decay = rank * 0.25 
                end
            end
        end
    end,
    
    RegisterConduitEvents = function(self)
        if not self.eventFrame then self.eventFrame = CreateFrame("Frame") end
        self.eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player")
        self.eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player")
        self.eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
        self.eventFrame:SetScript("OnEvent", function(frame, event, ...)
            if event == "PLAYER_TALENT_UPDATE" then
                self:CheckTalents()
            else
                self:EventHandler(event, ...)
            end
        end)
    end,

    SetupTooltip = function(self)
        -- 1. Hook Spells (Standard Handler)
        GameTooltip:HookScript("OnTooltipSetSpell", function(tooltip)
            local name, id = tooltip:GetSpell()
            if not name then return end
            
            local db = Purity:GetDB()
            if not db or db.activeChallengeID ~= "Conduit of Purity" then return end

            if self.ignoredSpells[name] then return end
            
            local isMageSpell = learnableFireSpells[id] or learnableFrostSpells[id] or learnableArcaneSpells[id]
            if not isMageSpell then return end
            
            local cost = 0
            local _, _, _, castTime = GetSpellInfo(id)
            if name == "Arcane Missiles" or name == "Blizzard" or name == "Evocation" then cost = 30
            elseif castTime and castTime > 0 then cost = castTime / 100
            else cost = 15 end
            
            if self.talentMods and self.talentMods.cost > 0 then
                cost = cost * (1.0 - self.talentMods.cost)
            end
            
            tooltip:AddLine(math.floor(cost) .. " Static Charge", 0.3, 0.8, 1)
            
            if self.charge < (cost - 1) then
                tooltip:AddLine("Insufficient Charge", 1, 0.2, 0.2)
            end
            tooltip:Show()
        end)
        
        -- 2. Hook Talents (Native-Style Integration)
        if not self.talentHooked then
            hooksecurefunc(GameTooltip, "SetTalent", function(tooltip)
                local db = Purity:GetDB()
                if not db or db.activeChallengeID ~= "Conduit of Purity" then return end
                
                -- A. Get the talent name safely
                local frameName = tooltip:GetName()
                if not frameName then return end
                local line1 = _G[frameName .. "TextLeft1"]
                if not line1 then return end
                local talentName = line1:GetText()
                if not talentName then return end

                -- B. Helper: Find the rank info
                local currentRank, maxRank = 0, 0
                local found = false
                
                for t = 1, GetNumTalentTabs() do
                    for i = 1, GetNumTalents(t) do
                        local name, _, _, _, rank, max = GetTalentInfo(t, i)
                        if name == talentName then
                            currentRank = rank
                            maxRank = max
                            found = true
                            break
                        end
                    end
                    if found then break end
                end
                
                if not found then return end

                -- C. Define the native-style text format
                local perRankPct = 0
                local descFormat = ""
                
                -- We use a subtle color (light blue) so it looks distinct but integrated
                if talentName == "Arcane Meditation" then
                    perRankPct = 10 -- The Architect (30% total)
                    descFormat = " |cff55ccffReduces Static Charge cost by %d%%.|r"
                elseif talentName == "Frost Channeling" then
                    perRankPct = 10 -- The Superconductor (30% total)
                    descFormat = " |cff55ccffIncreases Static Charge gen by %d%%.|r"
                elseif talentName == "Burning Soul" then
                    perRankPct = 25 -- The Furnace (50% total)
                    descFormat = " |cff55ccffReduces Static Decay by %d%%.|r"
                else
                    return 
                end

                -- D. Locate the "Next rank" line separator
                local nextRankLineIndex = nil
                local numLines = tooltip:NumLines()
                
                for i = 2, numLines do
                    local line = _G[frameName .. "TextLeft" .. i]
                    if line and line:GetText() and string.find(line:GetText(), "Next rank") then
                        nextRankLineIndex = i
                        break
                    end
                end

                -- E. Appending Logic
                if currentRank == 0 then
                    -- RANK 0: Append Rank 1 bonus to the last line.
                    local bonus = perRankPct
                    local fontString = _G[frameName .. "TextLeft" .. numLines]
                    if fontString then
                        fontString:SetText(fontString:GetText() .. string.format(descFormat, bonus))
                    end

                elseif currentRank == maxRank then
                    -- MAX RANK: Append Max Rank bonus to the last line.
                    local bonus = currentRank * perRankPct
                    local fontString = _G[frameName .. "TextLeft" .. numLines]
                    if fontString then
                        fontString:SetText(fontString:GetText() .. string.format(descFormat, bonus))
                    end

                else
                    -- INTERMEDIATE RANK: Split description.
                    if nextRankLineIndex then
                        -- 1. Append to Current Description
                        local currentBonus = currentRank * perRankPct
                        local currentDescLine = _G[frameName .. "TextLeft" .. (nextRankLineIndex - 1)]
                        if currentDescLine then
                            currentDescLine:SetText(currentDescLine:GetText() .. string.format(descFormat, currentBonus))
                        end
                        
                        -- 2. Append to Next Rank Description
                        local nextBonus = (currentRank + 1) * perRankPct
                        local nextDescLine = _G[frameName .. "TextLeft" .. (nextRankLineIndex + 1)]
                        if nextDescLine then
                            nextDescLine:SetText(nextDescLine:GetText() .. string.format(descFormat, nextBonus))
                        end
                    end
                end
                
                tooltip:Show() -- Refresh width
            end)
            self.talentHooked = true
        end
    end,

    CreateChargeBar = function(self)
        if self.chargeFrame then return end
        
        local challenge = self 
        local f = CreateFrame("Frame", "PurityMageChargeFrame", UIParent)
        f:SetSize(200, 25) 
        f:SetMovable(true)

        f.hitbox = CreateFrame("Frame", nil, UIParent)
        f.hitbox:SetAllPoints(f) 
        f.hitbox:SetFrameStrata("DIALOG") 
        f.hitbox:EnableMouse(true)
        f.hitbox:RegisterForDrag("LeftButton")
        
        f:SetScript("OnShow", function() f.hitbox:Show() end)
        f:SetScript("OnHide", function() f.hitbox:Hide() end)
        
        f.hitbox:SetScript("OnDragStart", function(self)
            if f.isDetached then f:StartMoving() end
        end)
        f.hitbox:SetScript("OnDragStop", function(self)
            if f.isDetached then f:StopMovingOrSizing() end
        end)
        
        f.hitbox:SetScript("OnEnter", function(frame)
            GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
            GameTooltip:SetText("Charge Bar", 1, 1, 1)
            local _, spirit = UnitStat("player", 5)
            local currentGenRate = challenge.genRate + (spirit * 0.05)
            GameTooltip:AddLine("Power flows through motion. Movement generates charge based on your speed, with " .. string.format("%.1f", currentGenRate) .. " charge/sec being the base rate (1.0x speed). Standing still decays 4 charge per sec. Spells cost charge to cast. Casting with insufficient charge breaks the vow.", 1, 0.82, 0, true)
            GameTooltip:Show()
        end)
        f.hitbox:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
        
        f.bg = f:CreateTexture(nil, "BACKGROUND")
        f.bg:SetAllPoints(true)
        f.bg:SetColorTexture(0, 0, 0, 0.8)
        
        f.bar = f:CreateTexture(nil, "ARTWORK")
        f.bar:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
        f.bar:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -2)
        f.bar:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 2, 2)
        f.bar:SetWidth(196) 
        f.bar:SetVertexColor(0.0, 0.8, 1.0) 
        
        f.glow = f:CreateTexture(nil, "OVERLAY")
        f.glow:SetTexture("Interface\\TargetingFrame\\UI-StatusBar") 
        f.glow:SetAllPoints(f.bar) 
        f.glow:SetBlendMode("ADD")
        f.glow:SetVertexColor(0.8, 1.0, 1.0) 
        f.glow:SetAlpha(0) 

        f.glowAnim = f.glow:CreateAnimationGroup()
        f.glowAnim:SetLooping("REPEAT")
        local pulseIn = f.glowAnim:CreateAnimation("Alpha")
        pulseIn:SetFromAlpha(0); pulseIn:SetToAlpha(1); pulseIn:SetDuration(0.5); pulseIn:SetSmoothing("IN_OUT"); pulseIn:SetOrder(1)
        local pulseOut = f.glowAnim:CreateAnimation("Alpha")
        pulseOut:SetFromAlpha(1); pulseOut:SetToAlpha(0); pulseOut:SetDuration(0.5); pulseOut:SetSmoothing("IN_OUT"); pulseOut:SetOrder(2)
        
        f.textLeft = f:CreateFontString(nil, "OVERLAY", "GameFontNormal") 
        f.textLeft:SetFont("Fonts\\ARIALN.TTF", 13, "OUTLINE") 
        f.textLeft:SetTextColor(1, 1, 1)
        
        f.textRight = f:CreateFontString(nil, "OVERLAY", "GameFontNormal") 
        f.textRight:SetFont("Fonts\\ARIALN.TTF", 13, "OUTLINE") 
        f.textRight:SetTextColor(1, 1, 1)
        
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
        self.chargeFrame:SetParent(UIParent)
        
        if isDetached then
            self.chargeFrame:SetFrameStrata("MEDIUM")
            self.chargeFrame:SetFrameLevel(10)
            self.chargeFrame:SetSize(200, 25)
            self.chargeFrame:SetPoint("CENTER", 0, -180)
            self.chargeFrame:SetScript("OnUpdate", nil)
            self.chargeFrame:Show()
        else
            self.chargeFrame:SetFrameStrata("BACKGROUND") 
            self.chargeFrame:SetFrameLevel(1)
            self.chargeFrame:SetSize(150, 15) 
            if PlayerFrameManaBar then
                self.chargeFrame:SetPoint("TOPLEFT", PlayerFrameManaBar, "BOTTOMLEFT", -29, 0)
            else
                self.chargeFrame:SetPoint("TOPLEFT", PlayerFrame, "BOTTOMLEFT", 50, -2)
            end
            self.chargeFrame:SetScript("OnUpdate", function(f)
                if PlayerFrame and PlayerFrame:IsShown() then f:Show() else f:Hide() end
            end)
        end
        self:UpdateBar()
    end,

    UpdateBar = function(self)
        if not self.chargeFrame then return end
        
        if self.charge > self.maxCharge then self.charge = self.maxCharge end
        if self.charge < 0 then self.charge = 0 end
        
        local pct = self.charge / self.maxCharge
        local totalWidth = self.chargeFrame:GetWidth() - 4 
        local barWidth = totalWidth * pct
        if barWidth < 1 then barWidth = 1 end
        
        self.chargeFrame.bar:SetWidth(barWidth)
        self.chargeFrame.glow:SetWidth(barWidth) 
        
        local displayMode = GetCVar("statusTextDisplay")
        local currentVal = math.floor(self.charge)
        local maxVal = self.maxCharge
        local pctText = math.floor(pct * 100) .. "%"
        
        self.chargeFrame.textLeft:Hide()
        self.chargeFrame.textRight:Hide()

        if displayMode == "NUMERIC" then
            self.chargeFrame.textLeft:ClearAllPoints()
            self.chargeFrame.textLeft:SetPoint("TOPLEFT", self.chargeFrame, "TOPLEFT", 14, -2)
            self.chargeFrame.textLeft:SetPoint("BOTTOMRIGHT", self.chargeFrame, "BOTTOMRIGHT", 14, 2)
            self.chargeFrame.textLeft:SetText(currentVal .. " / " .. maxVal)
            self.chargeFrame.textLeft:SetJustifyH("CENTER") 
            self.chargeFrame.textLeft:Show()
        elseif displayMode == "PERCENT" then
            self.chargeFrame.textLeft:ClearAllPoints()
            self.chargeFrame.textLeft:SetPoint("CENTER", self.chargeFrame, "CENTER", 14, 0)
            self.chargeFrame.textLeft:SetText(pctText)
            self.chargeFrame.textLeft:Show()
        elseif displayMode == "BOTH" then
            local numericText = currentVal 
            self.chargeFrame.textLeft:SetSize(40, 15) 
            self.chargeFrame.textLeft:ClearAllPoints()
            self.chargeFrame.textLeft:SetPoint("LEFT", self.chargeFrame, "LEFT", 28, 0)
            self.chargeFrame.textLeft:SetText(pctText)
            self.chargeFrame.textLeft:Show()
            self.chargeFrame.textRight:SetSize(40, 15)
            self.chargeFrame.textRight:ClearAllPoints()
            self.chargeFrame.textRight:SetPoint("RIGHT", self.chargeFrame, "RIGHT", 7, 0)
            self.chargeFrame.textRight:SetText(numericText)
            self.chargeFrame.textRight:Show()
        end
        
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
                    if not button.purityCost then
                        button.purityCost = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
                        button.purityCost:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 2, 2)
                        button.purityCost:SetFont("Fonts\\ARIALN.TTF", 14, "OUTLINE")
                    end

                    local actionSlot = button.action
                    local actionType, spellId = GetActionInfo(actionSlot)
                    
                    if actionType == "spell" then
                        local spellName = GetSpellInfo(spellId)
                        local isMageSpell = learnableFireSpells[spellId] or learnableFrostSpells[spellId] or learnableArcaneSpells[spellId]
                        
                        if isMageSpell and spellName and not self.ignoredSpells[spellName] then
                            local cost = 0
                            local _, _, _, castTime = GetSpellInfo(spellId)
                            if spellName == "Arcane Missiles" or spellName == "Blizzard" or spellName == "Evocation" then
                                cost = 30
                            elseif castTime and castTime > 0 then
                                cost = castTime / 100
                            else
                                cost = 15
                            end
                            
                            -- [[ APPLY COST MODIFIER ]]
                            if self.talentMods and self.talentMods.cost > 0 then
                                cost = cost * (1.0 - self.talentMods.cost)
                            end

                            button.purityCost:SetText(math.floor(cost))
                            
                            if self.charge < (cost - 1) then
                                CooldownFrame_Set(cooldownFrame, GetTime(), 3600, 1)
                                if cooldownFrame.SetDrawEdge then cooldownFrame:SetDrawEdge(false) end
                                if cooldownFrame.SetDrawSwipe then cooldownFrame:SetDrawSwipe(true) end
                                if cooldownFrame.SetHideCountdownNumbers then cooldownFrame:SetHideCountdownNumbers(true) end
                                button.purityCost:SetTextColor(1, 0.1, 0.1) 
                            else
                                local start, duration, enabled = GetSpellCooldown(spellId)
                                if start and duration then
                                    CooldownFrame_Set(cooldownFrame, start, duration, enabled)
                                    if cooldownFrame.SetHideCountdownNumbers then cooldownFrame:SetHideCountdownNumbers(false) end
                                end
                                button.purityCost:SetTextColor(1, 1, 1)
                            end
                            button.purityCost:Show()
                        else
                            button.purityCost:Hide()
                            local start, duration, enabled = GetSpellCooldown(spellId)
                            if start and duration then CooldownFrame_Set(cooldownFrame, start, duration, enabled) end
                        end
                    else
                        CooldownFrame_Set(cooldownFrame, 0, 0, 0)
                        if button.purityCost then button.purityCost:Hide() end
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

            local _, spirit = UnitStat("player", 5)
            local currentGenRate = self.genRate + (spirit * 0.05)
            local currentSpeed = select(1, GetUnitSpeed("player"))
            local elapsed = 0.1
            local chargeChange = 0
            local BASE_SPEED = 7.0 

            if currentSpeed > 0 then
                -- [[ FROST BONUS: Increased Generation ]]
                local genMultiplier = 1.0 + (self.talentMods and self.talentMods.gen or 0)
                
                local velocityFactor = currentSpeed / BASE_SPEED 
                velocityFactor = math.min(velocityFactor, 2.0)
                
                chargeChange = (currentGenRate * genMultiplier * elapsed) * velocityFactor 
                self.charge = self.charge + chargeChange
            else
                -- [[ FIRE BONUS: Reduced Decay ]]
                local decayMultiplier = 1.0 - (self.talentMods and self.talentMods.decay or 0)
                if decayMultiplier < 0 then decayMultiplier = 0 end

                chargeChange = -(self.decayRate * decayMultiplier * elapsed)
                self.charge = self.charge + chargeChange
            end
            
            if UnitAffectingCombat("player") and chargeChange > 0 then
                local stats = db.challengeStats or {}
                db.challengeStats = stats 
                local newAccumulated = (stats.chargeAccumulatedCombat or 0) + chargeChange
                stats.chargeAccumulatedCombat = math.floor(newAccumulated * 10) / 10
            end
            
            db.mageCharge = self.charge
            self:UpdateBar()
        end)
    end,
    
    CreateWarningUI = function(self)
        if self.warningFrame then return end
        
        local f = CreateFrame("Frame", "PurityMageWarningFrame", UIParent)
        f:SetFrameStrata("FULLSCREEN_DIALOG")
        f:SetAllPoints(UIParent)
        f:Hide()
        
        f.bg = f:CreateTexture(nil, "BACKGROUND")
        f.bg:SetAllPoints(true)
        f.bg:SetTexture("Interface\\FullScreenTextures\\LowHealth")
        f.bg:SetBlendMode("ADD")
        f.bg:SetAlpha(0.8)

        f.anim = f:CreateAnimationGroup()
        f.anim:SetLooping("REPEAT")
        local pulseIn = f.anim:CreateAnimation("Alpha")
        pulseIn:SetFromAlpha(0.4); pulseIn:SetToAlpha(1); pulseIn:SetDuration(0.4); pulseIn:SetSmoothing("IN_OUT"); pulseIn:SetOrder(1)
        local pulseOut = f.anim:CreateAnimation("Alpha")
        pulseOut:SetFromAlpha(1); pulseOut:SetToAlpha(0.4); pulseOut:SetDuration(0.4); pulseOut:SetSmoothing("IN_OUT"); pulseOut:SetOrder(2)
        
        f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
        f.text:SetPoint("CENTER", 0, 100) 
        f.text:SetFont("Fonts\\FRIZQT__.TTF", 32, "OUTLINE, MONOCHROME")
        f.text:SetText("UNSTABLE! CANCEL CAST!")
        f.text:SetTextColor(1, 0.2, 0.2) 
        
        f.sub = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        f.sub:SetPoint("TOP", f.text, "BOTTOM", 0, -10)
        f.sub:SetText("Insufficient Charge detected")
        f.sub:SetTextColor(1, 1, 1)

        self.warningFrame = f
    end,

    ShowWarning = function(self)
        if self.warningFrame then
            self.warningFrame:Show()
            self.warningFrame.anim:Play()
        end
    end,

    HideWarning = function(self)
        if self.warningFrame then
            self.warningFrame.anim:Stop()
            self.warningFrame:Hide()
        end
    end,

    ProcessSpellCost = function(self, spellName, castTimeMs, spellId)
        local now = GetTime()
        if self.lastPaid and self.lastPaid.id == spellId and (now - self.lastPaid.time) < 0.5 then
            return "ALREADY_PAID", 0 
        end

        if self.ignoredSpells[spellName] then return "SAFE", 0 end
        
        local isMageSpell = learnableFireSpells[spellId] or learnableFrostSpells[spellId] or learnableArcaneSpells[spellId]
        if not isMageSpell then return "SAFE", 0 end
        
        local cost = 0
        if spellName == "Arcane Missiles" or spellName == "Blizzard" or spellName == "Evocation" then cost = 30
        elseif castTimeMs > 0 then cost = castTimeMs / 100
        else cost = 15 end
        
        -- [[ APPLY COST MODIFIER ]]
        if self.talentMods and self.talentMods.cost > 0 then
            cost = cost * (1.0 - self.talentMods.cost)
        end
        
        if self.charge < (cost - 1) then
            self.lastPaid = { id = spellId, time = now }
            return "VIOLATION", cost
        else
            self.charge = self.charge - cost
            Purity:GetDB().mageCharge = self.charge
            self:UpdateBar()
            self.lastPaid = { id = spellId, time = now }
            return "PAID", cost
        end
    end,
    
    EventHandler = function(self, event, ...)
        local db = Purity:GetDB()
        
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

        if event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED" then
            local unit = ... 
            if unit ~= "player" then return end
            
            local spellNameCasting = UnitCastingInfo("player")
            if spellNameCasting then return end

            if self.activeCast then
                if self.activeCast.isViolation then
                    self:HideWarning() 
                else
                    local refundAmount = self.activeCast.cost
                    if refundAmount > 0 then
                        self.charge = self.charge + refundAmount
                        db.mageCharge = self.charge
                        self:UpdateBar()
                    end
                end
                self.activeCast = nil
            end
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
                    local status, cost = self:ProcessSpellCost(spellName, castTime, spellId)
                    
                    if status == "VIOLATION" then
                        self.activeCast = { 
                            name = spellName, 
                            startTime = GetTime(), 
                            durationSec = castTime / 1000, 
                            cost = cost,
                            isViolation = true
                        }
                        self:ShowWarning()
                        PlaySound(SOUNDKIT.RAID_WARNING)
                        
                    elseif status == "PAID" then
                        self.activeCast = { 
                            name = spellName, 
                            startTime = GetTime(), 
                            durationSec = castTime / 1000, 
                            cost = cost,
                            isViolation = false
                        }
                    end
                end
            elseif subEvent == "SPELL_CAST_SUCCESS" then
                local _, _, _, castTime = GetSpellInfo(spellId)
                
                if self.activeCast and self.activeCast.name == spellName then
                    if self.activeCast.isViolation then
                        self:HideWarning()
                        Purity:Violation("Cast " .. spellName .. " with insufficient Static Charge.")
                    end
                    self.activeCast = nil
                elseif not castTime or castTime == 0 then
                    local status, cost = self:ProcessSpellCost(spellName, 0, spellId)
                    if status == "VIOLATION" then
                         Purity:Violation("Cast " .. spellName .. " with insufficient Static Charge.")
                    end
                end
            end
        end
    end,
}

Purity.ClassModules = Purity.ClassModules or {}
Purity.ClassModules.MAGE = MageModule