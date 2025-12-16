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
    -- Fireball (Ranks 1-12)
    [133] = true, [143] = true, [145] = true, [3140] = true, [8400] = true, [8401] = true, [8402] = true, [10148] = true, [10149] = true, [10150] = true, [10151] = true, [25306] = true,
    -- Fire Blast (Ranks 1-7)
    [2136] = true, [2137] = true, [2138] = true, [8412] = true, [8404] = true, [8413] = true, [10197] = true, [10199] = true,
    -- Flamestrike (Ranks 1-6)
    [2120] = true, [2121] = true, [8422] = true, [8423] = true, [10215] = true, [10216] = true,
    -- Scorch (Ranks 1-7)
    [2948] = true, [8444] = true, [8445] = true, [8446] = true, [10205] = true, [10206] = true, [10207] = true,
    -- Pyroblast (Ranks 1-8)
    [11366] = true, [12505] = true, [12522] = true, [12523] = true, [12524] = true, [12525] = true, [12526] = true, [18809] = true,
    -- Blast Wave (Ranks 1-5)
    [11113] = true, [13018] = true, [13019] = true, [13020] = true, [13021] = true,
    -- Fire Ward (Ranks 1-5)
    [543] = true, [8457] = true, [8458] = true, [10223] = true, [10225] = true,
    -- Combustion
    [11129] = true,
}

local learnableFrostSpells = {
    -- Frostbolt (Ranks 1-11)
    [116] = true, [205] = true, [837] = true, [7322] = true, [8406] = true, [8407] = true, [8408] = true, [10179] = true, [10180] = true, [10181] = true, [25304] = true,
    -- Frost Nova (Ranks 1-4)
    [122] = true, [865] = true, [6131] = true, [10230] = true,
    -- Frost Armor (Ranks 1-3)
    [168] = true, [7300] = true, [7301] = true,
    -- Ice Armor (Ranks 1-4)
    [7302] = true, [7320] = true, [10219] = true, [10220] = true,
    -- Blizzard (Ranks 1-6)
    [10] = true, [6141] = true, [8427] = true, [10185] = true, [10186] = true, [10187] = true,
    -- Cone of Cold (Ranks 1-5)
    [120] = true, [8492] = true, [10159] = true, [10160] = true, [10161] = true,
    -- Frost Ward (Ranks 1-5)
    [6143] = true, [8461] = true, [8462] = true, [10177] = true, [28609] = true,
    -- Ice Barrier (Ranks 1-4)
    [11426] = true, [13031] = true, [13032] = true, [13033] = true,
    -- Ice Block
    [11958] = true,
}

local learnableArcaneSpells = {
    -- Arcane Missiles (Ranks 1-8)
    [5143] = true, [5144] = true, [5145] = true, [8416] = true, [8417] = true, [10211] = true, [10212] = true, [25345] = true,
    -- Arcane Explosion (Ranks 1-6)
    [1449] = true, [8437] = true, [8438] = true, [8439] = true, [10201] = true, [10202] = true,
    -- Arcane Intellect (Ranks 1-5)
    [1459] = true, [1460] = true, [1461] = true, [10156] = true, [10157] = true,
    -- Arcane Brilliance
    [23028] = true,
    -- Mage Armor
    [6117] = true, [22782] = true, [22783] = true,
    -- Mana Shield (Ranks 1-6)
    [1463] = true, [8494] = true, [8495] = true, [10191] = true, [10192] = true, [10193] = true,
    -- Conjure Food (Ranks 1-7)
    [587] = true, [1113] = true, [1114] = true, [1487] = true, [8075] = true, [8076] = true, [22895] = true,
    -- Conjure Water (Ranks 1-7)
    [5504] = true, [2288] = true, [2136] = true, [3772] = true, [8077] = true, [8078] = true, [8079] = true,
    -- Conjure Mana Gems (Agate, Jade, Citrine, Ruby)
    [759] = true, [3552] = true, [10053] = true, [10054] = true,
    -- Teleports (SW, IF, Darn, Org, UC, TB)
    [3561] = true, [3562] = true, [3565] = true, [3567] = true, [3563] = true, [3566] = true,
    -- Portals (SW, IF, Darn, Org, UC, TB)
    [10059] = true, [11416] = true, [11419] = true, [11417] = true, [11418] = true, [11420] = true,
    -- Amplify Magic (Ranks 1-4)
    [1008] = true, [8455] = true, [10169] = true, [10170] = true,
    -- Dampen Magic (Ranks 1-5)
    [604] = true, [8450] = true, [8451] = true, [10173] = true, [10174] = true,
    -- Detect Magic
    [2855] = true,
    -- Remove Lesser Curse
    [475] = true,
    -- Polymorph (Sheep Ranks 1-4, Pig, Turtle)
    [118] = true, [12824] = true, [12825] = true, [12826] = true, [28272] = true, [28271] = true,
    -- Blink
    [1953] = true,
    -- Slow Fall
    [130] = true,
    -- Counterspell
    [2139] = true,
    -- Evocation
    [12051] = true,
    -- Presence of Mind
    [12043] = true,
    -- Arcane Power
    [12042] = true,
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
        
        hooksecurefunc("ActionButton_UpdateCooldown", function(button)
            if Purity and Purity.ClassModules.MAGE and Purity.ClassModules.MAGE.challenges.conduit then
                Purity.ClassModules.MAGE.challenges.conduit:UpdateSingleButtonVisual(button)
            end
        end)
		
		hooksecurefunc(GameTooltip, "SetSpellByID", function(self, spellID)
            local db = Purity:GetDB()
            if db.activeChallengeID == "Conduit of Purity" then
                local spellName = GetSpellInfo(spellID)
                if spellName == "Blink" then
                    self:AddLine("Generates instant Static Charge.")
                    self:Show()
                end
            end
        end)
        
        self.isInitialized = true
    end,
    
    CheckTalents = function(self)
        self.talentMods = { decay = 0, cost = 0, gen = 0, refund = 0, grace = 0 }
        self.maxCharge = 100 
        
        local numTabs = GetNumTalentTabs()
        for t = 1, numTabs do
            local numTalents = GetNumTalents(t)
            for i = 1, numTalents do
                local nameTalent, _, _, _, rank = GetTalentInfo(t, i)
                
                -- ARCANE: Arcane Meditation (Passive Decay Reduction)
                -- "Meditation stabilizes the flow." -> Reduces decay by 10/20/30%
                if nameTalent == "Arcane Meditation" and rank > 0 then
                    self.talentMods.decay = rank * 0.10 
                end
                
                -- ARCANE: Arcane Mind (Capacity)
                -- "Expands the vessel." -> +2 Max Charge per rank
                if nameTalent == "Arcane Mind" and rank > 0 then
                    self.maxCharge = 100 + (rank * 2)
                end
                
                -- FROST: Frost Channeling (Generation Speed)
                -- "Low Resistance = Fast Flow." -> +10/20/30% Gen
                if nameTalent == "Frost Channeling" and rank > 0 then
                    self.talentMods.gen = rank * 0.10 
                end
                
                -- FROST: Permafrost (Efficiency / Cost)
                -- "Superconductor = No Waste." -> -10/20/30% Cost
                if nameTalent == "Permafrost" and rank > 0 then
                    self.talentMods.cost = rank * 0.10
                end
                
                -- FIRE: Burning Soul (Grace Period)
                -- "High Resistance = Stops Discharge." -> 0.33/0.66/1.0s Grace
                if nameTalent == "Burning Soul" and rank > 0 then
                    local values = { 0.33, 0.66, 1.0 }
                    self.talentMods.grace = values[rank]
                end

                -- FIRE: Master of Elements (Crit Refund)
                -- "Pressure Release." -> 10/20/30% Refund on Crit
                if nameTalent == "Master of Elements" and rank > 0 then
                    self.talentMods.refund = rank * 0.10
                end
            end
        end
        self:UpdateBar()
    end,
    
    RegisterConduitEvents = function(self)
        if not self.eventFrame then self.eventFrame = CreateFrame("Frame") end
        self.eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
        self.eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
        self.eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player")
        self.eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player")
        self.eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
        self.eventFrame:RegisterEvent("UNIT_AURA")
        self.eventFrame:SetScript("OnEvent", function(frame, event, ...)
            if event == "PLAYER_TALENT_UPDATE" then
                self:CheckTalents()
            else
                self:EventHandler(event, ...)
            end
        end)
    end,

    SetupTooltip = function(self)
        -- 1. Standard Spell Cost Hook
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
            elseif string.find(name, "Teleport:") then cost = 90
            elseif castTime and castTime > 0 then cost = castTime / 100
            else cost = 15 end
            
            -- Apply Cost Mod (Now includes Permafrost)
            if self.talentMods and self.talentMods.cost > 0 then
                cost = cost * (1.0 - self.talentMods.cost)
            end
            
            tooltip:AddLine(math.floor(cost) .. " Static Charge", 1, 1, 1)
            if self.charge < (cost - 1) then tooltip:AddLine("Insufficient Charge", 1, 0.2, 0.2) end
            tooltip:Show()
        end)
        
        -- 2. Talent Description Hook
        if not self.talentHooked then
            hooksecurefunc(GameTooltip, "SetTalent", function(tooltip)
                local db = Purity:GetDB()
                if not db or db.activeChallengeID ~= "Conduit of Purity" then return end
                
                local frameName = tooltip:GetName()
                if not frameName then return end
                local line1 = _G[frameName .. "TextLeft1"]
                if not line1 then return end
                local talentName = line1:GetText()
                if not talentName then return end

                local currentRank, maxRank = 0, 0
                local found = false
                
                for t = 1, GetNumTalentTabs() do
                    for i = 1, GetNumTalents(t) do
                        local name, _, _, _, rank, max = GetTalentInfo(t, i)
                        if name == talentName then
                            currentRank = rank; maxRank = max; found = true; break
                        end
                    end
                    if found then break end
                end
                
                if not found then return end

                local descFormat = ""
                local isFlat = false
                
                if talentName == "Arcane Meditation" then
                    descFormat = " Reduces Static Decay by %d%%." -- Changed to Decay
                elseif talentName == "Frost Channeling" then
                    descFormat = " Increases Static Charge generation by %d%%."
                elseif talentName == "Permafrost" then
                     descFormat = " Reduces Static Charge cost by %d%%." -- Changed to Cost
                elseif talentName == "Burning Soul" then
                    isFlat = true -- Grace Period
                elseif talentName == "Arcane Mind" then
                    descFormat = " Increases Max Static Charge by %d."
                elseif talentName == "Master of Elements" then
                    descFormat = " Additionally, criticals refund %d%% of Charge cost."
				elseif talentName == "Arcane Concentration" then
                    -- [[ ARCANE CONCENTRATION TEXT REPLACEMENT ]]
                    for i = 2, tooltip:NumLines() do
                        local line = _G[frameName .. "TextLeft" .. i]
                        if line then
                            local text = line:GetText()
                            -- Use [Mm] to match "Mana" or "mana"
                            if text and string.find(text, "[Mm]ana cost") then
                                local newText = string.gsub(text, "[Mm]ana cost", "mana and Static Charge cost")
                                line:SetText(newText)
                            end
                        end
                    end
                    tooltip:Show()
                    return
                else
                    return 
                end

                local numLines = tooltip:NumLines()
                local nextRankLineIndex = nil
                for i = 2, numLines do
                    local line = _G[frameName .. "TextLeft" .. i]
                    if line and line:GetText() and string.find(line:GetText(), "Next rank") then nextRankLineIndex = i; break end
                end

                if isFlat and talentName == "Burning Soul" then
                    local values = { "0.33", "0.66", "1.0" }
                    local fmt = " Delays Static Decay by %s sec."
                    
                    if currentRank == 0 then
                        local fontString = _G[frameName .. "TextLeft" .. numLines]
                        if fontString then fontString:SetText(fontString:GetText() .. string.format(fmt, values[1])) end
                    elseif currentRank == maxRank then
                        local fontString = _G[frameName .. "TextLeft" .. numLines]
                        if fontString then fontString:SetText(fontString:GetText() .. string.format(fmt, values[3])) end
                    else
                        if nextRankLineIndex then
                            local currentDescLine = _G[frameName .. "TextLeft" .. (nextRankLineIndex - 1)]
                            if currentDescLine then currentDescLine:SetText(currentDescLine:GetText() .. string.format(fmt, values[currentRank])) end
                            local nextDescLine = _G[frameName .. "TextLeft" .. (nextRankLineIndex + 1)]
                            if nextDescLine then nextDescLine:SetText(nextDescLine:GetText() .. string.format(fmt, values[currentRank+1])) end
                        end
                    end
                else
                    local perRankPct = 0
                    if talentName == "Arcane Meditation" then perRankPct = 10
                    elseif talentName == "Frost Channeling" then perRankPct = 10
                    elseif talentName == "Permafrost" then perRankPct = 10
                    elseif talentName == "Arcane Mind" then perRankPct = 2
                    elseif talentName == "Master of Elements" then perRankPct = 10 end

                    if currentRank == 0 then
                        local bonus = perRankPct
                        local fontString = _G[frameName .. "TextLeft" .. numLines]
                        if fontString then fontString:SetText(fontString:GetText() .. string.format(descFormat, bonus)) end
                    elseif currentRank == maxRank then
                        local bonus = currentRank * perRankPct
                        local fontString = _G[frameName .. "TextLeft" .. numLines]
                        if fontString then fontString:SetText(fontString:GetText() .. string.format(descFormat, bonus)) end
                    else
                        if nextRankLineIndex then
                            local currentBonus = currentRank * perRankPct
                            local currentDescLine = _G[frameName .. "TextLeft" .. (nextRankLineIndex - 1)]
                            if currentDescLine then currentDescLine:SetText(currentDescLine:GetText() .. string.format(descFormat, currentBonus)) end
                            local nextBonus = (currentRank + 1) * perRankPct
                            local nextDescLine = _G[frameName .. "TextLeft" .. (nextRankLineIndex + 1)]
                            if nextDescLine then nextDescLine:SetText(nextDescLine:GetText() .. string.format(descFormat, nextBonus)) end
                        end
                    end
                end
                tooltip:Show() 
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
        self.chargeFrame.textLeft:ClearAllPoints()
        self.chargeFrame.textRight:ClearAllPoints()

        if displayMode == "NUMERIC" then
            if self.chargeFrame.isDetached then
                self.chargeFrame.textLeft:SetPoint("CENTER", self.chargeFrame, "CENTER", 0, 0)
                self.chargeFrame.textLeft:SetJustifyH("CENTER")
            else
                self.chargeFrame.textLeft:SetPoint("LEFT", self.chargeFrame, "LEFT", 35, 0)
                self.chargeFrame.textLeft:SetJustifyH("LEFT")
            end
            self.chargeFrame.textLeft:SetText(currentVal .. " / " .. maxVal)
            self.chargeFrame.textLeft:Show()

        elseif displayMode == "PERCENT" then
            if self.chargeFrame.isDetached then
                self.chargeFrame.textLeft:SetPoint("CENTER", self.chargeFrame, "CENTER", 0, 0)
                self.chargeFrame.textLeft:SetJustifyH("CENTER")
            else
                self.chargeFrame.textLeft:SetPoint("LEFT", self.chargeFrame, "LEFT", 35, 0)
                self.chargeFrame.textLeft:SetJustifyH("LEFT")
            end
            self.chargeFrame.textLeft:SetText(pctText)
            self.chargeFrame.textLeft:Show()

        elseif displayMode == "BOTH" then
            if self.chargeFrame.isDetached then
                self.chargeFrame.textLeft:SetPoint("LEFT", self.chargeFrame, "LEFT", 5, 0)
                self.chargeFrame.textRight:SetPoint("RIGHT", self.chargeFrame, "RIGHT", -5, 0)
            else
                self.chargeFrame.textLeft:SetPoint("LEFT", self.chargeFrame, "LEFT", 32.5, 0)
                self.chargeFrame.textRight:SetPoint("RIGHT", self.chargeFrame, "RIGHT", -3, 0)
            end
            
            self.chargeFrame.textLeft:SetText(pctText)
            self.chargeFrame.textLeft:Show()
            self.chargeFrame.textRight:SetText(currentVal)
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
	
    UpdateSingleButtonVisual = function(self, button)
        if not button or not button.action then return end
        local actionType, spellId = GetActionInfo(button.action)
        
        if actionType == "spell" then
            local spellName = GetSpellInfo(spellId)
            local isMageSpell = learnableFireSpells[spellId] or learnableFrostSpells[spellId] or learnableArcaneSpells[spellId]
            
            if isMageSpell and spellName and not self.ignoredSpells[spellName] then
                local cost = 0
                local _, _, _, castTime = GetSpellInfo(spellId)
                
                if spellName == "Arcane Missiles" or spellName == "Blizzard" or spellName == "Evocation" then 
                    cost = 30
                elseif string.find(spellName, "Teleport:") then 
                    cost = 90
                elseif castTime and castTime > 0 then 
                    cost = castTime / 100
                else 
                    cost = 15 
                end
                
                if self.talentMods and self.talentMods.cost > 0 then
                    cost = cost * (1.0 - self.talentMods.cost)
                end

                -- [[ CLEARCASTING VISUAL CHECK ]]
                local isClearcasting = false
                for i=1, 40 do
                    local buffName = UnitBuff("player", i)
                    if not buffName then break end
                    if buffName == "Clearcasting" then isClearcasting = true; break end
                end
                if isClearcasting then cost = 0 end

                if not button.purityCost then
                    button.purityCost = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
                    button.purityCost:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 2, 2)
                    button.purityCost:SetFont("Fonts\\ARIALN.TTF", 14, "OUTLINE")
                end
                button.purityCost:SetText(math.floor(cost))

                if self.charge < (cost - 1) and cost > 0 then
                    local cooldownFrame = _G[button:GetName().."Cooldown"]
                    if cooldownFrame then
                        CooldownFrame_Set(cooldownFrame, GetTime(), 3600, 1)
                        if cooldownFrame.SetDrawEdge then cooldownFrame:SetDrawEdge(false) end
                        if cooldownFrame.SetDrawSwipe then cooldownFrame:SetDrawSwipe(true) end
                        if cooldownFrame.SetHideCountdownNumbers then cooldownFrame:SetHideCountdownNumbers(true) end
                    end
                    button.purityCost:SetTextColor(1, 0.1, 0.1)
                    button.purityCost:Show()
                else
                    if cost == 0 and isClearcasting then
                        button.purityCost:SetTextColor(0.2, 1, 0.2) -- Green for free spell
                    else
                        button.purityCost:SetTextColor(1, 1, 1)
                    end
                    button.purityCost:Show()
                end
            elseif button.purityCost then
                button.purityCost:Hide()
            end
        elseif button.purityCost then
            button.purityCost:Hide()
        end
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
                            elseif string.find(spellName, "Teleport:") then
                                cost = 90
                            elseif castTime and castTime > 0 then
                                cost = castTime / 100
                            else
                                cost = 15
                            end
                            
                            -- [[ APPLY COST MODIFIER ]]
                            if self.talentMods and self.talentMods.cost > 0 then
                                cost = cost * (1.0 - self.talentMods.cost)
                            end

                            -- [[ CLEARCASTING VISUAL CHECK ]]
                            local isClearcasting = false
                            for i=1, 40 do
                                local buffName = UnitBuff("player", i)
                                if not buffName then break end
                                if buffName == "Clearcasting" then isClearcasting = true; break end
                            end
                            if isClearcasting then cost = 0 end

                            button.purityCost:SetText(math.floor(cost))
                            
                            if self.charge < (cost - 1) and cost > 0 then
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
                                if cost == 0 and isClearcasting then
                                    button.purityCost:SetTextColor(0.2, 1, 0.2) -- Green for free
                                else
                                    button.purityCost:SetTextColor(1, 1, 1)
                                end
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

    SetupTooltip = function(self)
        -- 1. Standard Spell Cost Hook
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
            elseif string.find(name, "Teleport:") then cost = 90
            elseif castTime and castTime > 0 then cost = castTime / 100
            else cost = 15 end
            
            -- Apply Cost Mod
            if self.talentMods and self.talentMods.cost > 0 then
                cost = cost * (1.0 - self.talentMods.cost)
            end
            
            -- [[ CLEARCASTING CHECK ]]
            local isClearcasting = false
            for i=1, 40 do
                local buffName = UnitBuff("player", i)
                if not buffName then break end
                if buffName == "Clearcasting" then isClearcasting = true; break end
            end
            
            if isClearcasting then
                cost = 0
                tooltip:AddLine(math.floor(cost) .. " Static Charge (Clearcasting)")
            else
                tooltip:AddLine(math.floor(cost) .. " Static Charge", 1, 1, 1)
                if self.charge < (cost - 1) then tooltip:AddLine("Insufficient Charge", 1, 0.2, 0.2) end
            end
            
            tooltip:Show()
        end)
        
        -- 2. Talent Description Hook
        if not self.talentHooked then
            hooksecurefunc(GameTooltip, "SetTalent", function(tooltip)
                local db = Purity:GetDB()
                if not db or db.activeChallengeID ~= "Conduit of Purity" then return end
                
                local frameName = tooltip:GetName()
                if not frameName then return end
                local line1 = _G[frameName .. "TextLeft1"]
                if not line1 then return end
                local talentName = line1:GetText()
                if not talentName then return end

                local currentRank, maxRank = 0, 0
                local found = false
                
                for t = 1, GetNumTalentTabs() do
                    for i = 1, GetNumTalents(t) do
                        local name, _, _, _, rank, max = GetTalentInfo(t, i)
                        if name == talentName then
                            currentRank = rank; maxRank = max; found = true; break
                        end
                    end
                    if found then break end
                end
                
                if not found then return end

                local descFormat = ""
                local isFlat = false
                
                if talentName == "Arcane Meditation" then
                    descFormat = " Reduces Static Decay by %d%%." 
                elseif talentName == "Frost Channeling" then
                    descFormat = " Increases Static Charge generation by %d%%."
                elseif talentName == "Permafrost" then
                     descFormat = " Reduces Static Charge cost by %d%%."
                elseif talentName == "Burning Soul" then
                    isFlat = true 
                elseif talentName == "Arcane Mind" then
                    descFormat = " Increases Max Static Charge by %d."
                elseif talentName == "Master of Elements" then
                    descFormat = " Additionally, criticals refund %d%% of Charge cost."
				elseif talentName == "Arcane Concentration" then
                    -- [[ ARCANE CONCENTRATION TEXT REPLACEMENT ]]
                    for i = 2, tooltip:NumLines() do
                        local line = _G[frameName .. "TextLeft" .. i]
                        if line then
                            local text = line:GetText()
                            -- Use [Mm] to match "Mana" or "mana"
                            if text and string.find(text, "[Mm]ana cost") then
                                local newText = string.gsub(text, "[Mm]ana cost", "mana and Static Charge cost")
                                line:SetText(newText)
                            end
                        end
                    end
                    tooltip:Show()
                    return
                else
                    return 
                end

                local numLines = tooltip:NumLines()
                local nextRankLineIndex = nil
                for i = 2, numLines do
                    local line = _G[frameName .. "TextLeft" .. i]
                    if line and line:GetText() and string.find(line:GetText(), "Next rank") then nextRankLineIndex = i; break end
                end

                if isFlat and talentName == "Burning Soul" then
                    local values = { "0.33", "0.66", "1.0" }
                    local fmt = " Delays Static Decay by %s sec."
                    
                    if currentRank == 0 then
                        local fontString = _G[frameName .. "TextLeft" .. numLines]
                        if fontString then fontString:SetText(fontString:GetText() .. string.format(fmt, values[1])) end
                    elseif currentRank == maxRank then
                        local fontString = _G[frameName .. "TextLeft" .. numLines]
                        if fontString then fontString:SetText(fontString:GetText() .. string.format(fmt, values[3])) end
                    else
                        if nextRankLineIndex then
                            local currentDescLine = _G[frameName .. "TextLeft" .. (nextRankLineIndex - 1)]
                            if currentDescLine then currentDescLine:SetText(currentDescLine:GetText() .. string.format(fmt, values[currentRank])) end
                            local nextDescLine = _G[frameName .. "TextLeft" .. (nextRankLineIndex + 1)]
                            if nextDescLine then nextDescLine:SetText(nextDescLine:GetText() .. string.format(fmt, values[currentRank+1])) end
                        end
                    end
                else
                    local perRankPct = 0
                    if talentName == "Arcane Meditation" then perRankPct = 10
                    elseif talentName == "Frost Channeling" then perRankPct = 10
                    elseif talentName == "Permafrost" then perRankPct = 10
                    elseif talentName == "Arcane Mind" then perRankPct = 2
                    elseif talentName == "Master of Elements" then perRankPct = 10 end

                    if currentRank == 0 then
                        local bonus = perRankPct
                        local fontString = _G[frameName .. "TextLeft" .. numLines]
                        if fontString then fontString:SetText(fontString:GetText() .. string.format(descFormat, bonus)) end
                    elseif currentRank == maxRank then
                        local bonus = currentRank * perRankPct
                        local fontString = _G[frameName .. "TextLeft" .. numLines]
                        if fontString then fontString:SetText(fontString:GetText() .. string.format(descFormat, bonus)) end
                    else
                        if nextRankLineIndex then
                            local currentBonus = currentRank * perRankPct
                            local currentDescLine = _G[frameName .. "TextLeft" .. (nextRankLineIndex - 1)]
                            if currentDescLine then currentDescLine:SetText(currentDescLine:GetText() .. string.format(descFormat, currentBonus)) end
                            local nextBonus = (currentRank + 1) * perRankPct
                            local nextDescLine = _G[frameName .. "TextLeft" .. (nextRankLineIndex + 1)]
                            if nextDescLine then nextDescLine:SetText(nextDescLine:GetText() .. string.format(descFormat, nextBonus)) end
                        end
                    end
                end
                tooltip:Show() 
            end)
            self.talentHooked = true
        end
    end,

    StartMonitor = function(self)
        if self.monitorTicker then return end
        
        self.lastMoveTime = GetTime()

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
            local now = GetTime()

            if currentSpeed > 0 then
                self.lastMoveTime = now
                -- [[ FROST BONUS: Gen Speed ]]
                local genMultiplier = 1.0 + (self.talentMods and self.talentMods.gen or 0)
                
                local velocityFactor = currentSpeed / BASE_SPEED 
                velocityFactor = math.min(velocityFactor, 2.0)
                
                chargeChange = (currentGenRate * genMultiplier * elapsed) * velocityFactor 
                self.charge = self.charge + chargeChange
            else
                -- [[ FIRE BONUS: Grace Period ]]
                local grace = self.talentMods and self.talentMods.grace or 0
                local timeStopped = now - self.lastMoveTime
                
                if timeStopped < grace then
                    chargeChange = 0 
                else
                    -- [[ ARCANE BONUS: Passive Decay Reduction ]]
                    local decayMultiplier = 1.0 - (self.talentMods and self.talentMods.decay or 0)
                    if decayMultiplier < 0 then decayMultiplier = 0 end

                    chargeChange = -(self.decayRate * decayMultiplier * elapsed)
                end

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
        
        -- Create the frame (Banner sized, not fullscreen)
        local f = CreateFrame("Frame", "PurityMageWarningFrame", UIParent)
        f:SetSize(150, 225) -- Standard banner size, adjust if your TGA is different
        f:SetPoint("TOP", 0, -180) -- Positioned near the top-center
        f:SetFrameStrata("HIGH")
        f:Hide()
        
        -- [[ LAYER 1: The Base Banner ]]
        f.bg = f:CreateTexture(nil, "BACKGROUND")
        f.bg:SetAllPoints(true)
        f.bg:SetTexture("Interface\\AddOns\\Purity\\Media\\ConduitBanner.tga")
        f.bg:SetVertexColor(1, 1, 1, 1)

        -- [[ LAYER 2: The Lightning Overlay ]]
        -- We reuse the SAME texture but set it to "ADD" mode.
        -- This makes the bright parts of your banner glow/crackle on top of the base.
        f.overlay = f:CreateTexture(nil, "ARTWORK")
        f.overlay:SetAllPoints(true)
        f.overlay:SetTexture("Interface\\AddOns\\Purity\\Media\\ConduitBanner.tga")
        f.overlay:SetBlendMode("ADD") -- This creates the lighting effect
        f.overlay:SetAlpha(0)

        -- [[ ANIMATION 1: Slight Alpha Pulse (Breathing) ]]
        -- This pulses the entire banner gently (0.8 to 1.0 opacity)
        f.anim = f:CreateAnimationGroup()
        f.anim:SetLooping("REPEAT")
        local pulseIn = f.anim:CreateAnimation("Alpha")
        pulseIn:SetFromAlpha(0.85); pulseIn:SetToAlpha(1); pulseIn:SetDuration(1.0); pulseIn:SetSmoothing("IN_OUT"); pulseIn:SetOrder(1)
        local pulseOut = f.anim:CreateAnimation("Alpha")
        pulseOut:SetFromAlpha(1); pulseOut:SetToAlpha(0.85); pulseOut:SetDuration(1.0); pulseOut:SetSmoothing("IN_OUT"); pulseOut:SetOrder(2)

        f.lightningAnim = f.overlay:CreateAnimationGroup()
        f.lightningAnim:SetLooping("REPEAT")
        
        local flash1 = f.lightningAnim:CreateAnimation("Alpha")
        flash1:SetFromAlpha(0); flash1:SetToAlpha(0.4); flash1:SetDuration(0.1); flash1:SetOrder(1)
        local fade1 = f.lightningAnim:CreateAnimation("Alpha")
        fade1:SetFromAlpha(0.4); fade1:SetToAlpha(0); fade1:SetDuration(0.2); fade1:SetOrder(2)
        
        local gap = f.lightningAnim:CreateAnimation("Alpha")
        gap:SetFromAlpha(0); gap:SetToAlpha(0); gap:SetDuration(1.5); gap:SetOrder(3)

        local flash2 = f.lightningAnim:CreateAnimation("Alpha")
        flash2:SetFromAlpha(0); flash2:SetToAlpha(0.25); flash2:SetDuration(0.5); flash2:SetOrder(4)
        local fade2 = f.lightningAnim:CreateAnimation("Alpha")
        fade2:SetFromAlpha(0.25); fade2:SetToAlpha(0); fade2:SetDuration(0.5); fade2:SetOrder(5)
        
        f.sub = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        f.sub:SetPoint("TOP", f.text, "BOTTOM", 0, -5)
        f.sub:SetText("Insufficient Charge")
        f.sub:SetTextColor(0.8, 0.8, 0.8)

        self.warningFrame = f
    end,

    ShowWarning = function(self)
        if self.warningFrame then
            -- Only play audio if the warning isn't already visible (prevents spam)
            if not self.warningFrame:IsShown() then
                
                -- [[ SOUND KIT ID LOOKUP TABLE ]]
                -- IDs provided by user for "Spell Not Ready"
                local voiceLines = {
                    ["Gnome"]    = { Male = 1717, Female = 1772 },
                    ["Human"]    = { Male = 1883, Female = 2584 },
                    ["Dwarf"]    = { Male = 1607, Female = 1662 }, -- Added 1607 for Male (Standard Match)
                    ["NightElf"] = { Male = 2126, Female = 2237 },
                    ["Scourge"]  = { Male = 2181, Female = 2182 }, -- Undead
                    ["Tauren"]   = { Male = 2412, Female = 2413 },
                    ["Orc"]      = { Male = 2292, Female = 2349 },
                    ["Troll"]    = { Male = 1828, Female = 1938 },
                }

                local _, raceEn = UnitRace("player")
                local sex = UnitSex("player")
                local genderKey = (sex == 3) and "Female" or "Male"

                -- Fallback for Undead (UnitRace can return "Undead" or "Scourge")
                if raceEn == "Undead" then raceEn = "Scourge" end

                local raceTable = voiceLines[raceEn]
                if raceTable and raceTable[genderKey] then
                    -- Play the internal Sound Kit ID (automatically cycles variations)
                    PlaySound(raceTable[genderKey], "Master") 
                end
            end

            self.warningFrame:Show()
            self.warningFrame.anim:Play()
            self.warningFrame.lightningAnim:Play()
        end
    end,

    HideWarning = function(self)
        if self.warningFrame then
            self.warningFrame.anim:Stop()
            self.warningFrame.lightningAnim:Stop()
            self.warningFrame:Hide()
        end
    end,

    GetProjectedCost = function(self, spellName, castTimeMs, spellId)
        if self.ignoredSpells[spellName] then return "SAFE", 0 end
        
        local isMageSpell = learnableFireSpells[spellId] or learnableFrostSpells[spellId] or learnableArcaneSpells[spellId]
        if not isMageSpell then return "SAFE", 0 end
        
        local cost = 0
        if spellName == "Arcane Missiles" or spellName == "Blizzard" or spellName == "Evocation" then 
            cost = 30
        elseif string.find(spellName, "Teleport:") then 
            cost = 90
        elseif castTimeMs > 0 then 
            cost = castTimeMs / 100
        else 
            cost = 15 
        end
        
        if self.talentMods and self.talentMods.cost > 0 then
            cost = cost * (1.0 - self.talentMods.cost)
        end
        
        -- [[ Clearcasting Projection ]]
        -- If we have the buff now, we assume it will be used.
        local isClearcasting = false
        for i=1, 40 do
            local name = UnitBuff("player", i)
            if name == "Clearcasting" then isClearcasting = true; break end
        end
        if isClearcasting then cost = 0 end

        if self.charge < (cost - 1) then
            return "VIOLATION", cost
        else
            return "SAFE", cost
        end
    end,
    
    EventHandler = function(self, event, ...)
        local db = Purity:GetDB()
        
        -- VISUALS UPDATE
        if event == "SPELL_UPDATE_COOLDOWN" or event == "UNIT_AURA" then
            self:UpdateActionbarOverlay()
            return
        end
        
        -- RESET ON LEVEL UP
        if event == "PLAYER_LEVEL_UP" then
            self.charge = self.maxCharge
            db.mageCharge = self.charge
            self:UpdateBar()
            return
        end

        -- SPELL FAILURE / INTERRUPT
        if event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED" then
            local unit = ... 
            if unit ~= "player" then return end
            if self.activeCast and self.activeCast.isViolation then self:HideWarning() end
            self.activeCast = nil
            return
        end
        
        -- COMBAT LOG (For Refund/Bonus only)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellId, spellName, _, _, _, _, _, _, _, critical = CombatLogGetCurrentEventInfo()
            if sourceGUID == UnitGUID("player") then
                -- Master of Elements Refund
                if subEvent == "SPELL_DAMAGE" and critical and self.talentMods and self.talentMods.refund > 0 then
                    local isMageSpell = learnableFireSpells[spellId] or learnableFrostSpells[spellId] or learnableArcaneSpells[spellId]
                    if isMageSpell then
                        local cost = 15 -- Base proxy
                        local _, _, _, castTime = GetSpellInfo(spellId)
                        if spellName == "Arcane Missiles" or spellName == "Blizzard" or spellName == "Evocation" then cost = 30
                        elseif string.find(spellName, "Teleport:") then cost = 90
                        elseif castTime and castTime > 0 then cost = castTime / 100 end
                        if self.talentMods.cost > 0 then cost = cost * (1.0 - self.talentMods.cost) end
                        
                        self.charge = self.charge + (cost * self.talentMods.refund)
                        db.mageCharge = self.charge
                        self:UpdateBar()
                    end
                end
                
                -- Blink Bonus
                if subEvent == "SPELL_CAST_SUCCESS" and spellName == "Blink" then
                    self.charge = self.charge + self.blinkBonus
                    db.mageCharge = self.charge
                    self:UpdateBar()
                end
            end
        end

        -- MAIN SPELLCAST MONITORING
        if event == "UNIT_SPELLCAST_START" then
            local unit, _, spellId = ...
            if unit ~= "player" then return end
            local spellName, _, _, castTime = GetSpellInfo(spellId)
            
            -- SNAPSHOT MANA (Used for Clearcasting Check)
            self.manaAtStart = UnitPower("player", 0) 

            if castTime and castTime > 0 then
                local status, cost = self:GetProjectedCost(spellName, castTime, spellId)
                if status == "VIOLATION" then
                    self.activeCast = { name = spellName, cost = cost, isViolation = true }
                    self:ShowWarning()
                    PlaySound(SOUNDKIT.RAID_WARNING)
                else
                    self.activeCast = { name = spellName, cost = cost, isViolation = false }
                end
            end

        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            local unit, _, spellId = ...
            if unit ~= "player" then return end
            
            local spellName = GetSpellInfo(spellId)
            local _, _, _, castTime = GetSpellInfo(spellId)
            
            -- 1. Check if ignored
            if self.ignoredSpells[spellName] then 
                self.activeCast = nil
                return 
            end

            -- 2. Check if Mage Spell
            local isMageSpell = learnableFireSpells[spellId] or learnableFrostSpells[spellId] or learnableArcaneSpells[spellId]
            if not isMageSpell then 
                self.activeCast = nil
                return 
            end

            -- 3. Calculate Base Cost (Standard Purity Logic)
            local purityCost = 0
            if spellName == "Arcane Missiles" or spellName == "Blizzard" or spellName == "Evocation" then purityCost = 30
            elseif string.find(spellName, "Teleport:") then purityCost = 90
            elseif castTime and castTime > 0 then purityCost = castTime / 100
            else purityCost = 15 end
            
            if self.talentMods and self.talentMods.cost > 0 then
                purityCost = purityCost * (1.0 - self.talentMods.cost)
            end

            -- 4. MANA CHECK (Did we actually spend mana?)
            -- If we had Clearcasting, the mana spent will be 0.
            local currentMana = UnitPower("player", 0)
            local manaSpent = (self.manaAtStart or currentMana) - currentMana
            
            -- Note: We check if manaSpent <= 0 to account for mana ticks happening simultaneously.
            if manaSpent <= 0 then
                purityCost = 0
            end

            -- 5. Deduct Charge or Punish
            if self.activeCast and self.activeCast.isViolation then
                -- Even if it turned out free, you started it without charge -> Violation
                self:HideWarning()
                Purity:Violation("Started cast " .. spellName .. " with insufficient Static Charge.")
            else
                if self.charge < (purityCost - 1) then
                    Purity:Violation("Cast " .. spellName .. " with insufficient Static Charge.")
                else
                    self.charge = self.charge - purityCost
                    db.mageCharge = self.charge
                    self:UpdateBar()
                end
            end
            
            self.activeCast = nil
        end
    end,
}

Purity.ClassModules = Purity.ClassModules or {}
Purity.ClassModules.MAGE = MageModule