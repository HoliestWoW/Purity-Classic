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
    [33933] = true,	[33043] = true,	[33938] = true,	[27079] = true,	[38692] = true,	[27074] = true,	[27128] = true,	[27132] = true,	[27070] = true,	[27133] = true,	[27073] = true,	[33042] = true,	[27086] = true,	[30482] = true,	[27078] = true,	[13021] = true,	[18809] = true,	[10225] = true,	[10151] = true,	[25306] = true,	[10207] = true,	[33041] = true,	[10216] = true,	[12526] = true,	[10199] = true,	[10150] = true,	[13020] = true,	[10206] = true,	[10223] = true,	[12525] = true,	[10149] = true,	[10215] = true,	[10197] = true,	[10205] = true,	[13019] = true,	[12524] = true,	[10148] = true,	[8458] = true,	[8423] = true,	[8446] = true,	[8413] = true,	[13018] = true,	[12523] = true,	[8402] = true,	[8445] = true,	[8422] = true,	[12522] = true,	[8412] = true,	[8457] = true,	[8401] = true,	[8444] = true,	[12505] = true,	[8400] = true,	[2121] = true,	[2138] = true,	[2948] = true,	[543] = true,	[3140] = true,	[2120] = true,	[2137] = true,	[145] = true,	[2136] = true,	[143] = true,	[133] = true,	[11113] = true,	[31641] = true,	[31642] = true,	[11083] = true,	[12351] = true,	[11129] = true,	[11115] = true,	[11367] = true,	[11368] = true,	[31661] = true,	[31656] = true,	[31657] = true,	[31658] = true,	[31659] = true,	[31660] = true,	[11124] = true,	[12378] = true,	[12398] = true,	[12399] = true,	[12400] = true,	[11100] = true,	[12353] = true,	[11103] = true,	[12357] = true,	[12358] = true,	[12359] = true,	[12360] = true,	[11069] = true,	[12338] = true,	[12339] = true,	[12340] = true,	[12341] = true,	[29074] = true,	[29075] = true,	[29076] = true,	[31638] = true,	[31639] = true,	[31640] = true,	[11366] = true,	[34293] = true,	[34295] = true,	[34296] = true,
}

local learnableFrostSpells = {
    [33405] = true,	[32796] = true,	[38697] = true,	[27072] = true,	[27124] = true,	[27085] = true,	[27088] = true,	[30455] = true,	[27087] = true,	[27134] = true,	[27071] = true,	[10187] = true,	[28609] = true,	[25304] = true,	[10220] = true,	[13033] = true,	[10161] = true,	[10181] = true,	[10230] = true,	[13032] = true,	[10186] = true,	[10177] = true,	[10160] = true,	[10180] = true,	[10219] = true,	[13031] = true,	[10185] = true,	[10179] = true,	[10159] = true,	[8462] = true,	[6131] = true,	[7320] = true,	[8408] = true,	[8427] = true,	[8492] = true,	[8461] = true,	[8407] = true,	[7302] = true,	[45438] = true,	[6141] = true,	[120] = true,	[865] = true,	[8406] = true,	[6143] = true,	[10] = true,	[7301] = true,	[7322] = true,	[837] = true,	[7300] = true,	[122] = true,	[205] = true,	[116] = true,	[168] = true,	[11958] = true,	[31682] = true,	[31683] = true,	[31684] = true,	[31685] = true,	[31686] = true,	[11160] = true,	[12518] = true,	[12519] = true,	[11071] = true,	[12496] = true,	[12497] = true,	[11426] = true,	[11207] = true,	[12672] = true,	[15047] = true,	[15052] = true,	[15053] = true,	[12472] = true,	[11151] = true,	[12952] = true,	[12953] = true,	[31687] = true,
}

local learnableArcaneSpells = {
    [27127] = true,	[27082] = true,	[27126] = true,	[38704] = true,	[33717] = true,	[27090] = true,	[43987] = true,	[30449] = true,	[33946] = true,	[38699] = true,	[27125] = true,	[27101] = true,	[66] = true,	[27131] = true,	[33944] = true,	[37420] = true,	[33691] = true,	[35717] = true,	[30451] = true,	[27130] = true,	[27075] = true,	[27080] = true,	[25345] = true,	[28612] = true,	[10140] = true,	[10174] = true,	[10193] = true,	[12826] = true,	[28271] = true,	[28272] = true,	[33690] = true,	[35715] = true,	[10054] = true,	[22783] = true,	[23028] = true,	[10157] = true,	[10212] = true,	[10170] = true,	[10202] = true,	[10145] = true,	[10192] = true,	[10139] = true,	[11419] = true,	[11420] = true,	[10211] = true,	[10053] = true,	[10173] = true,	[10201] = true,	[22782] = true,	[10191] = true,	[10169] = true,	[10156] = true,	[10144] = true,	[8417] = true,	[10138] = true,	[12825] = true,	[32266] = true,	[11416] = true,	[11417] = true,	[32267] = true,	[10059] = true,	[11418] = true,	[8439] = true,	[3552] = true,	[8451] = true,	[8495] = true,	[49361] = true,	[49360] = true,	[49358] = true,	[49359] = true,	[6117] = true,	[8416] = true,	[6129] = true,	[8455] = true,	[8438] = true,	[6127] = true,	[3565] = true,	[3566] = true,	[1461] = true,	[759] = true,	[8494] = true,	[5145] = true,	[2139] = true,	[8450] = true,	[8437] = true,	[990] = true,	[1953] = true,	[5506] = true,	[12051] = true,	[1463] = true,	[12824] = true,	[32271] = true,	[3562] = true,	[3567] = true,	[32272] = true,	[3561] = true,	[3563] = true,	[1008] = true,	[475] = true,	[5144] = true,	[1449] = true,	[1460] = true,	[597] = true,	[604] = true,	[130] = true,	[5505] = true,	[5143] = true,	[118] = true,	[587] = true,	[5504] = true,	[1459] = true,	[11213] = true,	[12574] = true,	[12575] = true,	[12576] = true,	[12577] = true,	[11222] = true,	[12839] = true,	[12840] = true,	[12841] = true,	[12842] = true,	[11232] = true,	[12500] = true,	[12501] = true,	[12502] = true,	[12503] = true,	[12042] = true,	[11210] = true,	[12592] = true,	[29438] = true,	[29439] = true,	[29440] = true,	[29441] = true,	[29444] = true,	[29445] = true,	[29446] = true,	[29447] = true,	[31589] = true,
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
        self.eventFrame:RegisterEvent("UNIT_SPELLCAST_SENT", "player")
        self.eventFrame:RegisterEvent("UNIT_SPELLCAST_START", "player")
        self.eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
        self.eventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", "player")
        self.eventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED", "player")
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

    EventHandler = function(self, event, unit, ...)
        if unit ~= "player" then return end
        
        local spellId
        if event == "UNIT_SPELLCAST_SENT" then
             local _, _, id = ...
             spellId = id
        else
             local _, id = ...
             spellId = id
        end

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
        ["Shoot"] = true, ["Attack"] = true, ["Hearthstone"] = true, ["Astral Recall"] = true, ["Blink"] = true, ["Evocation"] = true,
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
        
        -- [[ 1. BLOCKING INFRASTRUCTURE ]]
        -- The "Black Hole" button that eats clicks
        if not self.dummyButton then
            self.dummyButton = CreateFrame("Button", "PurityDummyButton", UIParent, "SecureActionButtonTemplate")
            self.dummyButton:Hide()
        end
        -- The frame that holds the override bindings
        if not self.bindFrame then 
            self.bindFrame = CreateFrame("Frame", "PurityBindFrame", UIParent) 
        end
        
        -- Delay execution to ensure ActionBars are loaded
        C_Timer.After(1.0, function()
            self:CreateBlockers()
        end)
        
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
                if nameTalent == "Arcane Meditation" and rank > 0 then
                    self.talentMods.decay = rank * 0.10 
                end
                
                -- ARCANE: Arcane Mind (Capacity)
                if nameTalent == "Arcane Mind" and rank > 0 then
                    self.maxCharge = 100 + (rank * 2)
                end
                
                -- FROST: Frost Channeling (Generation Speed)
                if nameTalent == "Frost Channeling" and rank > 0 then
                    self.talentMods.gen = rank * 0.10 
                end
                
                -- FROST: Permafrost (Efficiency / Cost)
                -- "Superconductor = No Waste." -> -10/20/30% Cost (Applied to Frost Spells only)
                if nameTalent == "Permafrost" and rank > 0 then
                    self.talentMods.cost = rank * 0.10
                end
                
                -- FIRE: Burning Soul (Grace Period)
                if nameTalent == "Burning Soul" and rank > 0 then
                    local values = { 0.75, 1.5 }
                    self.talentMods.grace = values[rank]
                end

                -- FIRE: Master of Elements (Crit Refund)
                if nameTalent == "Master of Elements" and rank > 0 then
                    self.talentMods.refund = rank * 0.20
                end
            end
        end
        self:UpdateBar()
    end,
    
    RegisterConduitEvents = function(self)
        if not self.eventFrame then self.eventFrame = CreateFrame("Frame") end
        self.eventFrame:RegisterEvent("UNIT_SPELLCAST_START", "player")
        self.eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
        self.eventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", "player")
        self.eventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED", "player")
        self.eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED") 
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
            
            if name == "Arcane Missiles" or name == "Blizzard" then cost = 30
            elseif string.find(name, "Teleport:") then cost = 90
            elseif castTime and castTime > 0 then cost = castTime / 100
            else cost = 15 end
            
            -- Apply Cost Mod (FROST SPELLS ONLY)
            if self.talentMods and self.talentMods.cost > 0 and learnableFrostSpells[id] then
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
        
        -- 2. Talent Description Rewrite (Manual Replacement)
        if not self.talentHooked then
            hooksecurefunc(GameTooltip, "SetTalent", function(tooltip)
                local db = Purity:GetDB()
                if not db or db.activeChallengeID ~= "Conduit of Purity" then return end
                
                local frameName = tooltip:GetName()
                if not frameName then return end
                
                -- Get Talent Name
                local line1 = _G[frameName .. "TextLeft1"]
                if not line1 then return end
                local talentName = line1:GetText()
                if not talentName then return end

                -- Get Current Rank
                local currentRank = 0
                for t = 1, GetNumTalentTabs() do
                    for i = 1, GetNumTalents(t) do
                        local name, _, _, _, rank = GetTalentInfo(t, i)
                        if name == talentName then
                            currentRank = rank
                            break
                        end
                    end
                end

                -- [[ REWRITE DATA ]]
                local talentData = {
                    ["Arcane Meditation"] = {
                        match = "Mana regeneration to continue",
                        text = "Allows %d%% of your Mana regeneration to continue while casting. Reduces Static Decay by %d%%.",
                        vars = function(r) return r*5, r*10 end
                    },
                    ["Frost Channeling"] = {
                        match = "threat caused by your Frost spells",
                        text = "Reduces the mana cost of your Frost spells by %d%% and reduces the threat caused by your Frost spells by %d%%. Increases Static Charge generation by %d%%.",
                        vars = function(r) return r*5, r*10, r*10 end
                    },
                    ["Permafrost"] = {
                        match = "target's speed",
                        text = "Increases the duration of your Chill effects by %d sec and reduces the target's speed by an additional %d%%. Reduces Static Charge cost of Frost spells by %d%%.",
                        vars = function(r) return r*1, r*4, r*10 end
                    },
                    ["Arcane Mind"] = {
                        match = "maximum Mana",
                        text = "Increases your maximum Mana by %d%%. Increases Max Static Charge by %d.",
                        vars = function(r) return r*2, r*2 end
                    },
                    ["Master of Elements"] = {
                        match = "base mana cost",
                        text = "Your Fire and Frost spell criticals will refund %d%% of their base mana cost. Additionally, criticals refund %d%% of Charge cost.",
                        vars = function(r) return r*10, r*20 end
                    },
                    ["Burning Soul"] = {
                        match = "not lose casting time",
                        text = "Gives your Fire spells a %d%% chance to not lose casting time when you take damage and reduces the threat caused by your Fire spells by %d%%. Delays Static Decay by %s sec.",
                        vars = function(r) 
                            local p = {35, 70}
                            local t = {15, 30}
                            local d = {"0.75", "1.5"} -- Updated text values
                            return p[r] or 0, t[r] or 0, d[r] or "0"
                        end
                    }
                }

                if talentName == "Arcane Concentration" then
                    for i = 2, tooltip:NumLines() do
                        local line = _G[frameName .. "TextLeft" .. i]
                        if line then
                            local text = line:GetText()
                            if text and string.find(text, "[Mm]ana cost") then
                                line:SetText(string.gsub(text, "[Mm]ana cost", "mana and Static Charge cost"))
                            end
                        end
                    end
                    tooltip:Show()
                    return
                end

                local data = talentData[talentName]
                if data then
                    local passedNextRank = false
                    
                    for i = 2, tooltip:NumLines() do
                        local line = _G[frameName .. "TextLeft" .. i]
                        if line then
                            local text = line:GetText()
                            if text then
                                if text == "Next rank:" then
                                    passedNextRank = true
                                elseif string.find(text, data.match, 1, true) then
                                    local rankToUse = currentRank
                                    if currentRank == 0 then
                                        rankToUse = 1 
                                    elseif passedNextRank then
                                        rankToUse = currentRank + 1 
                                    end
                                    
                                    local v1, v2, v3 = data.vars(rankToUse)
                                    local newText = string.format(data.text, v1, v2, v3)
                                    line:SetText(newText)
                                end
                            end
                        end
                    end
                    tooltip:Show()
                end
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
            
            local baseGen = challenge.genRate + (spirit * 0.05)
            local genMult = 1.0 + (challenge.talentMods and challenge.talentMods.gen or 0)
            local currentGen = baseGen * genMult

            local baseDecay = challenge.decayRate
            local decayMult = 1.0 - (challenge.talentMods and challenge.talentMods.decay or 0)
            local currentDecay = baseDecay * decayMult
            
            GameTooltip:AddLine("Power flows through motion. Movement generates charge based on your speed, with " .. string.format("%.1f", currentGen) .. " charge/sec being the base rate (1.0x speed). Standing still decays " .. string.format("%.1f", currentDecay) .. " charge per sec. Spells cost charge to cast. Casting with insufficient charge breaks the vow.", 1, 0.82, 0, true)
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
	
	PlayLowChargeSound = function(self)
		local now = GetTime()
        -- If we played a sound less than 2 seconds ago, do nothing
        if self.lastSoundTime and (now - self.lastSoundTime) < 2.0 then
            return
        end
        self.lastSoundTime = now
        local voiceLines = {
                    ["Gnome"]    = { Male = 1717, Female = 1772 },
                    ["Human"]    = { Male = 1883, Female = 2584 },
                    ["Dwarf"]    = { Male = 1607, Female = 1662 },
                    ["NightElf"] = { Male = 2126, Female = 2237 },
					["Draenei"] = { Male = 9485 , Female = 9484 },
                    ["Scourge"]  = { Male = 2181, Female = 2182 }, -- Undead
                    ["Tauren"]   = { Male = 2412, Female = 2413 },
                    ["Orc"]      = { Male = 2292, Female = 2349 },
                    ["Troll"]    = { Male = 1828, Female = 1938 },
					["BloodElf"] = { Male = 9569 , Female = 9570 },
                }

        local _, raceEn = UnitRace("player")
        local sex = UnitSex("player")
        local genderKey = (sex == 3) and "Female" or "Male"

        -- Fallback for Undead
        if raceEn == "Undead" then raceEn = "Scourge" end

        local raceTable = voiceLines[raceEn]
        if raceTable and raceTable[genderKey] then
            PlaySound(raceTable[genderKey], "Master") 
        end
    end,
	
	CreateBlockers = function(self)
        local barNames = { "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton", "MultiBarRightButton", "MultiBarLeftButton" }
        
        for _, barName in ipairs(barNames) do
            for i = 1, 12 do
                local buttonName = barName .. i
                local button = _G[buttonName]
                
                if button then
                    if not button.purityBlocker then 
                        local blocker = CreateFrame("Frame", nil, button)
                        blocker:SetAllPoints(button)
                        
                        blocker:SetFrameStrata("FULLSCREEN_DIALOG") 
                        blocker:SetFrameLevel(9999) 
                        
                        blocker:EnableMouse(true) 
                        blocker:Hide() 
                        
                        blocker.bg = blocker:CreateTexture(nil, "OVERLAY")
                        blocker.bg:SetAllPoints(true)
                        blocker.bg:SetColorTexture(0, 0, 0, 0.7) 
                        
                        blocker:SetScript("OnEnter", function(self)
                            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                            GameTooltip:SetText("Insufficient Charge", 1, 0.2, 0.2)
                            GameTooltip:Show()
                        end)
                        blocker:SetScript("OnLeave", function(self)
                            GameTooltip:Hide()
                        end)
                        
                        blocker:SetScript("OnMouseDown", function()
                            self:PlayLowChargeSound()
                        end)

                        button.purityBlocker = blocker
                    end
                end
            end
        end
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
                
                if spellName == "Arcane Missiles" or spellName == "Blizzard" then 
                    cost = 30
                elseif string.find(spellName, "Teleport:") then 
                    cost = 90
                elseif castTime and castTime > 0 then 
                    cost = castTime / 100
                else 
                    cost = 15 
                end
                
                -- [[ COST MODIFIER (Frost Spells Only) ]]
                if self.talentMods and self.talentMods.cost > 0 and learnableFrostSpells[spellId] then
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
        
        -- [[ STEP 1: RESET ALL BINDS (Out of Combat Only) ]]
        -- We wipe the slate clean every update (while safe) to handle rapid charge changes.
        if self.bindFrame and not InCombatLockdown() then
            ClearOverrideBindings(self.bindFrame)
        end

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
                    local shouldBlock = false 

                    if actionType == "spell" then
                        local spellName = GetSpellInfo(spellId)
                        local isMageSpell = learnableFireSpells[spellId] or learnableFrostSpells[spellId] or learnableArcaneSpells[spellId]
                        
                        if isMageSpell and spellName and not self.ignoredSpells[spellName] then
                            local cost = 0
                            local _, _, _, castTime = GetSpellInfo(spellId)
                            
                            if spellName == "Arcane Missiles" or spellName == "Blizzard" then cost = 30
                            elseif string.find(spellName, "Teleport:") then cost = 90
                            elseif castTime and castTime > 0 then cost = castTime / 100
                            else cost = 15 end
                            
                            if self.talentMods and self.talentMods.cost > 0 and learnableFrostSpells[spellId] then
                                cost = cost * (1.0 - self.talentMods.cost)
                            end

                            local isClearcasting = false
                            for j=1, 40 do
                                local buffName = UnitBuff("player", j)
                                if not buffName then break end
                                if buffName == "Clearcasting" then isClearcasting = true; break end
                            end
                            if isClearcasting then cost = 0 end

                            button.purityCost:SetText(math.floor(cost))
                            
                            if self.charge < cost and cost > 0 then
                                shouldBlock = true
                                -- VISUALS
                                CooldownFrame_Set(cooldownFrame, GetTime(), 3600, 1)
                                if cooldownFrame.SetDrawEdge then cooldownFrame:SetDrawEdge(false) end
                                if cooldownFrame.SetDrawSwipe then cooldownFrame:SetDrawSwipe(true) end
                                if cooldownFrame.SetHideCountdownNumbers then cooldownFrame:SetHideCountdownNumbers(true) end
                                button.purityCost:SetTextColor(1, 0.1, 0.1) 
                            else
                                -- RESET VISUALS
                                local start, duration, enabled = GetSpellCooldown(spellId)
                                if start and duration then
                                    CooldownFrame_Set(cooldownFrame, start, duration, enabled)
                                    if cooldownFrame.SetHideCountdownNumbers then cooldownFrame:SetHideCountdownNumbers(false) end
                                end
                                if cost == 0 and isClearcasting then
                                    button.purityCost:SetTextColor(0.2, 1, 0.2)
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

                    -- [[ STEP 2: VISUAL BLOCKER (Always Safe) ]]
                    if button.purityBlocker then
                        if button.purityBlocker:IsShown() ~= shouldBlock then
                            button.purityBlocker:SetShown(shouldBlock)
                        end
                    end

                    -- [[ STEP 3: KEYBIND BLOCKER (OOC ONLY) ]]
                    if shouldBlock and self.bindFrame and not InCombatLockdown() then
                        -- Check for Keybind
                        local key = GetBindingKey("ACTIONBUTTON"..i)
                        
                        -- Add Multibar Support if needed
                        if barName == "MultiBarBottomLeftButton" then key = GetBindingKey("MULTIACTIONBAR1BUTTON"..i) end
                        if barName == "MultiBarBottomRightButton" then key = GetBindingKey("MULTIACTIONBAR2BUTTON"..i) end
                        if barName == "MultiBarRightButton" then key = GetBindingKey("MULTIACTIONBAR3BUTTON"..i) end
                        if barName == "MultiBarLeftButton" then key = GetBindingKey("MULTIACTIONBAR4BUTTON"..i) end

                        if key then
                            -- Redirect to dummy button
                            SetOverrideBindingClick(self.bindFrame, true, key, "PurityDummyButton")
                        end
                    end
                end
            end
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
                self:PlayLowChargeSound()
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
        local BUFFER = 2.0 -- The tolerance margin (prevents instant failure on tiny dips)

        if self.ignoredSpells[spellName] then return "SAFE", 0 end
        
        local isMageSpell = learnableFireSpells[spellId] or learnableFrostSpells[spellId] or learnableArcaneSpells[spellId]
        if not isMageSpell then return "SAFE", 0 end
        
        local cost = 0
        if spellName == "Arcane Missiles" or spellName == "Blizzard" then 
            cost = 30
        elseif string.find(spellName, "Teleport:") then 
            cost = 90
        elseif castTimeMs > 0 then 
            cost = castTimeMs / 100
        else 
            cost = 15 
        end
        
        if self.talentMods and self.talentMods.cost > 0 and learnableFrostSpells[spellId] then
            cost = cost * (1.0 - self.talentMods.cost)
        end
        
        local isClearcasting = false
        for i=1, 40 do
            local name = UnitBuff("player", i)
            if name == "Clearcasting" then isClearcasting = true; break end
        end
        if isClearcasting then cost = 0 end

        local effectiveThreshold = math.max(0, cost - BUFFER)

        if self.charge < effectiveThreshold then
            return "VIOLATION", cost
        else
            return "SAFE", cost
        end
    end,
    
    EventHandler = function(self, event, ...)
        local db = Purity:GetDB()
        local BUFFER = 2.0 -- The tolerance margin
        
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

        -- SPELL FAILURE / INTERRUPT (REFUND)
        if event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED" then
            local unit = ...
            if unit ~= "player" then return end
            
            if self.activeCast then
                if self.activeCast.isViolation then
                    self:HideWarning()
                elseif self.activeCast.paid and self.activeCast.paid > 0 then
                    self.charge = self.charge + self.activeCast.paid
                    db.mageCharge = self.charge
                    self:UpdateBar()
                end
            end
            self.activeCast = nil
            self.manaSnapshot = nil
            return
        end
        
        -- COMBAT LOG
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, subEvent, _, sourceGUID, _, _, _, destGUID, _, _, _, logSpellId, spellName, _, _, _, _, _, _, _, critical = CombatLogGetCurrentEventInfo()
            
            if destGUID == UnitGUID("player") and subEvent == "SPELL_AURA_REMOVED" and spellName == "Clearcasting" then
                self.lastClearcastRemoveTime = GetTime()
            end

            if sourceGUID == UnitGUID("player") then
                -- Master of Elements Refund
                if subEvent == "SPELL_DAMAGE" and critical and self.talentMods and self.talentMods.refund > 0 then
                    local refundSpells = {
                        ["Pyroblast"] = true, ["Fireball"] = true, ["Scorch"] = true, 
                        ["Fire Blast"] = true, ["Flamestrike"] = true, ["Blast Wave"] = true,
                        ["Frostbolt"] = true, ["Cone of Cold"] = true, ["Blizzard"] = true
                    }

                    if refundSpells[spellName] then
                        local cost = 0
                        local _, _, _, castTime = GetSpellInfo(logSpellId)
                        
                        if not castTime or castTime == 0 then
                            _, _, _, castTime = GetSpellInfo(spellName)
                        end

                        if spellName == "Arcane Missiles" or spellName == "Blizzard" then cost = 30
                        elseif string.find(spellName, "Teleport:") then cost = 90
                        elseif castTime and castTime > 0 then cost = castTime / 100
                        else cost = 15 end
                        
                        local isFrost = (spellName == "Frostbolt" or spellName == "Cone of Cold" or spellName == "Blizzard")
                        if self.talentMods.cost > 0 and isFrost then 
                             cost = cost * (1.0 - self.talentMods.cost) 
                        end
                        
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
            return
        end

        -- HANDLE START & CHANNEL START
        if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
            local unit, _, spellId = ...
            if unit ~= "player" then return end
            
            local spellName, _, _, castTime = GetSpellInfo(spellId)
            
            local isChannel = (event == "UNIT_SPELLCAST_CHANNEL_START")
            if (castTime and castTime > 0) or isChannel then
                local status, cost = self:GetProjectedCost(spellName, castTime, spellId)
                
                local isFree = false
                for i=1, 40 do
                    local name = UnitBuff("player", i)
                    if name == "Clearcasting" then isFree = true; break end
                end

                if not isFree and self.lastClearcastRemoveTime and (GetTime() - self.lastClearcastRemoveTime) < 0.5 then
                    isFree = true
                end

                if isFree then cost = 0 end

                if status == "VIOLATION" and cost > 0 then
                    self.activeCast = { name = spellName, cost = cost, isViolation = true, paid = 0, isClearcast = isFree }
                    self:ShowWarning()
                    PlaySound(SOUNDKIT.RAID_WARNING)
                else
                    self.charge = self.charge - cost
                    if self.charge < 0 then self.charge = 0 end -- Clamp to 0
                    db.mageCharge = self.charge
                    self:UpdateBar()
                    self.activeCast = { name = spellName, cost = cost, isViolation = false, paid = cost, isClearcast = isFree }
                end
            end

        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            local unit, _, spellId = ...
            if unit ~= "player" then return end
            
            local now = GetTime()
            if self.lastSuccessID == spellId and self.lastSuccessTime and (now - self.lastSuccessTime) < 0.5 then return end
            self.lastSuccessID = spellId
            self.lastSuccessTime = now
            
            local spellName = GetSpellInfo(spellId)
            local _, _, _, castTime = GetSpellInfo(spellId)
            
            local isMageSpell = learnableFireSpells[spellId] or learnableFrostSpells[spellId] or learnableArcaneSpells[spellId]
            if not spellName or self.ignoredSpells[spellName] or not isMageSpell then 
                self.activeCast = nil
                self.manaSnapshot = nil
                return 
            end

            local wasFree = false
            
            if self.activeCast then
                if self.activeCast.isClearcast then wasFree = true end
                if not wasFree and self.lastClearcastRemoveTime and (now - self.lastClearcastRemoveTime) < 0.5 then
                    wasFree = true
                end
            else
                for i=1, 40 do
                    local name = UnitBuff("player", i)
                    if name == "Clearcasting" then wasFree = true; break end
                end
                
                if not wasFree and self.lastClearcastRemoveTime and (now - self.lastClearcastRemoveTime) < 0.5 then
                    wasFree = true
                end
            end

            if self.activeCast then
                if self.activeCast.isViolation then
                    self:HideWarning()
                    Purity:Violation("Started cast " .. spellName .. " with insufficient Static Charge.")
                else
                    if wasFree and self.activeCast.paid > 0 then
                        self.charge = self.charge + self.activeCast.paid
                        db.mageCharge = self.charge
                        self:UpdateBar()
                    elseif not wasFree and self.activeCast.paid == 0 then
                        local lateFee = 30 
                        if self.activeCast.cost > 0 then lateFee = self.activeCast.cost end
                        self.charge = self.charge - lateFee
                        if self.charge < 0 then self.charge = 0 end -- Clamp to 0
                        db.mageCharge = self.charge
                        self:UpdateBar()
                    end
                end
            else
                -- INSTANT SPELL PATH
                if castTime and castTime > 0 then
                    self.activeCast = nil; self.manaSnapshot = nil; return
                end

                local purityCost = 0
                if spellName == "Arcane Missiles" or spellName == "Blizzard" then purityCost = 30
                else purityCost = 15 end 
                
                if self.talentMods and self.talentMods.cost > 0 and learnableFrostSpells[spellId] then 
                    purityCost = purityCost * (1.0 - self.talentMods.cost) 
                end
                
                if wasFree then purityCost = 0 end

                if purityCost > 0 then
                    -- [[ BUFFER LOGIC ]]
                    local effectiveThreshold = math.max(0, purityCost - BUFFER)

                    if self.charge < effectiveThreshold then
                        -- You were significantly below cost (e.g. 0 charge for 15 cost).
                        Purity:Violation("Cast " .. spellName .. " with insufficient Static Charge.")
                    else
                        -- You were within the buffer (e.g. 14 charge for 15 cost).
                        -- Allow cast, but clamp charge to 0.
                        self.charge = self.charge - purityCost
                        if self.charge < 0 then self.charge = 0 end
                        db.mageCharge = self.charge
                        self:UpdateBar()
                    end
                end
            end
            self.activeCast = nil
            self.manaSnapshot = nil
        end
    end,
}

Purity.ClassModules = Purity.ClassModules or {}
Purity.ClassModules.MAGE = MageModule