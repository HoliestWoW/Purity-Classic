-- Purity AddOn - Druid Module (Final Merged Build)

local addonName, Purity = ...

-- HELPER: Precision Scan for Anniversary API
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

local DruidModule = {
    challenges = {}
}

local secureAstrolabeBalance = 0

DruidModule.challenges.pact = {
    id = "Pact of Purity",
    challengeName = "Pact of Purity",
    description = function()
        return "The Avenger of Nature. This Druid has sworn a pact to protect wild beasts and has forsaken the celestial balance of the moon, relying only on their feral instincts and restorative powers. They have shed their leather armor, embracing a more primal connection to the wild."
    end,
    needsWeaponWarning = false,
    beastsInCombat = {},
    forbiddenBalanceSpells = {[5176]=true,[8921]=true,[467]=true,[5177]=true,[339]=true,[8924]=true,[5178]=true,[782]=true,[8925]=true,[1062]=true,[770]=true,[2637]=true,[2912]=true,[2908]=true,[5179]=true,[8926]=true,[1075]=true,[8949]=true,[5195]=true,[8927]=true,[5180]=true,[778]=true,[8914]=true,[8950]=true,[8928]=true,[6780]=true,[8955]=true,[18657]=true,[5196]=true,[16914]=true,[8929]=true,[9749]=true,[8951]=true,[22812]=true,[9756]=true,[8905]=true,[9833]=true,[9852]=true,[9875]=true,[17401]=true,[9834]=true,[9907]=true,[9912]=true,[9910]=true,[9901]=true,[9835]=true,[9853]=true,[18658]=true,[9876]=true},

    GetRulesText = function()
        return {
            "|cffffd100Key Prohibitions:|r",
            "|cff261A0D  • You may not kill any creature of the 'Beast' type.|r",
            "|cff261A0D  • Gaining experience for any Beast kills will break your vow.|r",
            "|cff261A0D  • After level 10, you may not cast any Balance spells.|r",
            "|cff261A0D  • You may not equip any Leather armor.|r",
            " ",
            "|cffffd100Challenge Conditions:|r",
            "|cff261A0D  • Must be started on a level 1 Druid.|r",
            "|cff261A0D  • Must be accepted before leveling to 2.|r",
            "|cff261A0D  • An uptime of at least 96.0% must be maintained.|r",
        }
    end,

    IsSpellForbidden = function(self, spellId) return false end, -- Casting check is in EventHandler
    IsTalentForbidden = function(self, id) 
        if UnitLevel("player") < 10 then return false end
        return IsIDInForbiddenTree(id, "Balance")
    end,
    IsItemForbidden = function(self, itemLink)
		if not itemLink then return false end
		local _, _, _, _, _, _, _, _, _, _, _, classID, subclassID = GetItemInfo(itemLink)
		return classID == 4 and subclassID == 2
	end,
    isWeaponAllowed = function(self, itemLink) return true end,
	IsUnitForbidden = function(self, unit)
        if not unit or not UnitExists(unit) then return false end
        return UnitCreatureType(unit) == "Beast" and UnitCanAttack("player", unit)
    end,

    EventHandler = function(self, event, ...)
        if event == "PLAYER_EQUIPMENT_CHANGED" then
            Purity:CheckEquipmentState()
        elseif event == "PLAYER_TARGET_CHANGED" then
            if UnitExists("target") and UnitCanAttack("player", "target") then
                local targetGUID = UnitGUID("target")
                local creatureType = UnitCreatureType("target")
                if targetGUID and creatureType then
                    self.beastsInCombat[targetGUID] = creatureType
                end
            end
        elseif event == "PLAYER_LEAVE_COMBAT" or event == "PLAYER_REGEN_ENABLED" then
            self.beastsInCombat = {}
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
-- ... (keep the rest of your combat log logic intact)
            local _, subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellId, spellName = CombatLogGetCurrentEventInfo()
            if sourceGUID == UnitGUID("player") and subEvent == "SPELL_CAST_SUCCESS" then
                local bearFormIDs = { [5487]=true, [9634]=true }
                if bearFormIDs[spellId] then
                    local db = Purity:GetDB()
                    if not db.challengeStats then db.challengeStats = {} end
                    db.challengeStats.shapeshiftCasts = (db.challengeStats.shapeshiftCasts or 0) + 1
					if _G["PurityCharacterPanel"] and _G["PurityCharacterPanel"]:IsShown() then
						if _G["UpdateCharacterPurity"] then
							_G["UpdateCharacterPurity"]()
						end
					end
                end
            end

            if UnitLevel("player") >= 10 then
                if sourceGUID == UnitGUID("player") and (subEvent == "SPELL_CAST_SUCCESS" or subEvent == "SPELL_AURA_APPLIED") then
                    if self.forbiddenBalanceSpells[spellId] then
                        Purity:Violation("Used a forbidden Balance spell after level 10:\n" .. spellName); return;
                    end
                end
            end
            local _, subEvent, _, _, _, _, _, destGUID, destName, destFlags = CombatLogGetCurrentEventInfo()
            if subEvent == "UNIT_DIED" and destGUID and bit.band(destFlags, COMBATLOG_OBJECT_TYPE_NPC) > 0 then
                local creatureType = self.beastsInCombat[destGUID]
                if UnitAffectingCombat("player") and creatureType then
                    if creatureType == "Beast" then
                        Purity:Violation("You have broken your pact with the wilds.\nThe spirit of the slain beast cries out against you.")
                        return
                    end
                end
            end
        elseif event == "PLAYER_TALENT_UPDATE" then
            if UnitLevel("player") >= 10 then
                local numTabs = GetNumTalentTabs()
                for t = 1, numTabs do
                    local _, name = GetTalentTabInfo(t)
                    if name == "Balance" then
                        for i = 1, GetNumTalents(t) do
                            local _, _, _, _, pointsSpent = GetTalentInfo(t, i)
                            if pointsSpent and pointsSpent > 0 then
                                Purity:Violation("Allocated points in the forbidden\nBalance talent tree.")
                                return
                            end
                        end
                    end
                end
            end
        end
    end,
}

DruidModule.challenges.astrolabe = {
    id = "Astrolabe of Purity",
    challengeName = "Astrolabe of Purity",
    description = function()
        return "The Celestial Weaver. This Druid's power is bound to an Astrolabe of Purity, an instrument that demands perfect equilibrium between solar (Nature) and lunar (Arcane) forces. They have forsaken their primal connection to the beasts and the nurturing essence of life to focus on this cosmic balance. To keep the astrolabe aligned, they must weave their spells in a precise sequence, never allowing one celestial force to overpower the other."
    end,
    needsWeaponWarning = false,
    lastDamageSpellSchool = nil,
    isInitialized = false, -- Flag for original visual hook

    natureDamageSpells = {
        [27013] = true,	[33786] = true,	[26991] = true,	[27012] = true,	[26990] = true,	[26995] = true,	[26983] = true,	[26979] = true,	[26994] = true,	[26982] = true,	[26985] = true,	[27009] = true,	[26989] = true,	[27011] = true,	[26993] = true,	[26980] = true,	[33763] = true,	[26992] = true,	[26981] = true,	[26978] = true,	[26984] = true,	[24977] = true,	[21850] = true,	[25297] = true,	[17402] = true,	[9885] = true,	[20748] = true,	[9858] = true,	[25299] = true,	[9863] = true,	[17329] = true,	[9853] = true,	[18658] = true,	[9841] = true,	[9889] = true,	[17392] = true,	[9907] = true,	[9857] = true,	[9901] = true,	[9910] = true,	[9912] = true,	[9840] = true,	[24976] = true,	[21849] = true,	[9888] = true,	[17401] = true,	[9884] = true,	[20747] = true,	[9862] = true,	[16813] = true,	[9852] = true,	[9856] = true,	[9839] = true,	[8905] = true,	[22812] = true,	[9758] = true,	[9756] = true,	[17391] = true,	[9749] = true,	[9750] = true,	[24975] = true,	[16914] = true,	[29166] = true,	[8907] = true,	[20742] = true,	[8910] = true,	[8918] = true,	[16812] = true,	[5196] = true,	[8903] = true,	[18657] = true,	[8955] = true,	[6780] = true,	[8941] = true,	[3627] = true,	[8914] = true,	[6778] = true,	[17390] = true,	[24974] = true,	[778] = true,	[5234] = true,	[20739] = true,	[8940] = true,	[740] = true,	[5180] = true,	[16811] = true,	[5195] = true,	[2091] = true,	[2893] = true,	[5189] = true,	[8939] = true,	[1075] = true,	[2090] = true,	[2908] = true,	[5179] = true,	[5188] = true,	[6756] = true,	[20484] = true,	[16810] = true,	[1062] = true,	[770] = true,	[2637] = true,	[8938] = true,	[1430] = true,	[8946] = true,	[5187] = true,	[782] = true,	[5178] = true,	[8936] = true,	[5232] = true,	[1058] = true,	[339] = true,	[5186] = true,	[467] = true,	[5177] = true,	[774] = true,	[5185] = true,	[1126] = true,	[5176] = true,	[16857] = true,	[33831] = true,	[5570] = true,	[16689] = true,	[16864] = true,	[18562] = true,
    },
    arcaneDamageSpells = {
        [26988] = true,	[26986] = true,	[26987] = true,	[25298] = true,	[9835] = true,	[9876] = true,	[9834] = true,	[9875] = true,	[9833] = true,	[8951] = true,	[8929] = true,	[8928] = true,	[8950] = true,	[8927] = true,	[8949] = true,	[2782] = true,	[8926] = true,	[2912] = true,	[8925] = true,	[8924] = true,	[18960] = true,	[8921] = true,
    },
    
    forbiddenFeralSpells = {[768]=true,[5487]=true,[9634]=true,[1079]=true,[5221]=true,[6807]=true,[779]=true,[780]=true,[99]=true,[1735]=true,[5229]=true,[5211]=true,[6795]=true,[8983]=true,[9005]=true,[9827]=true,[9846]=true,[9866]=true,[9892]=true,[9896]=true,[9908]=true,[9913]=true},
    forbiddenRestoSpells = {[5185]=true,[8936]=true,[774]=true,[20739]=true,[5186]=true,[5187]=true,[5188]=true,[5189]=true,[9758]=true,[9888]=true,[9889]=true,[8938]=true,[8939]=true,[8940]=true,[8941]=true,[9759]=true,[9856]=true,[9857]=true,[9858]=true,[8903]=true,[9760]=true,[9839]=true,[9840]=true,[9841]=true,[1058]=true, [26989]=true, [1126]=true},
    ignoredStartSpells = {[5185] = true, [1126] = true},

    GetRulesText = function()
        return {
            "|cffffd100Key Prohibitions:|r", "|cff261A0D  • You may not use Bear Form or Cat Form.|r", "|cff261A0D  • You may not learn or use any Restoration healing spells.|r", "|cff261A0D  • You may not allocate points in the Feral or Restoration talent trees.|r", " ", "|cffffd100Special Vow:|r", "|cff261A0D  • You must keep your Balance Bar in equalibrium.|r", "|cff261A0D  • Casting a damaging spell from the same school too many times in a row will break your vow.|r", " ", "|cffffd100Challenge Conditions:|r", "|cff261A0D  • Must be started on a level 1 Druid.|r", "|cff261A0D  • Must be accepted before leveling to 2.|r", "|cff261A0D  • An uptime of at least 96.0% must be maintained.|r",
        }
    end,
	
	StartForcedUpdates = function(self)
        if self.updateFrame then return end 

        self.updateFrame = CreateFrame("Frame")
        self.updateTimer = 0
        
        local challenge = self
        
        self.updateFrame:SetScript("OnUpdate", function(f, elapsed)
            if UnitAffectingCombat("player") then
                challenge.updateTimer = challenge.updateTimer + elapsed
                
                if challenge.updateTimer > 0.1 then
                    challenge:UpdateActionbarOverlay()
                    challenge.updateTimer = 0
                end
            end
        end)
    end,
    
    InitializeOnPlayerEnterWorld = function(self)
        if self.isInitialized then return end
        
        -- Load from DB (Persists across reloads)
        local db = Purity:GetDB()
        if not db.astrolabeBalance then 
            db.astrolabeBalance = 0 
        end
		
		secureAstrolabeBalance = db.astrolabeBalance
        
        self:CreateBalanceFrame()
        self:CreateVignetteFrame()
		self:UpdateVignette()
        self:StartForcedUpdates()

        -- (Keep your existing tooltip hooks here)
        local barNames = {"ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton", "MultiBarRightButton", "MultiBarLeftButton"}
        for _, barName in ipairs(barNames) do
            for i = 1, 12 do
                local button = _G[barName..i]
                if button then
                    local function onHover()
                        self:UpdateActionbarOverlay()
                    end
                    button:HookScript("OnEnter", onHover)
                    button:HookScript("OnLeave", onHover)
                end
            end
        end
        self.isInitialized = true
    end,

    UpdateActionbarOverlay = function(self)
        local db = Purity:GetDB()
        local balance = db and db.astrolabeBalance or 0
        
        -- Cap logic for Astrolabe mechanics
        local dimNature = (balance >= 2)
        local dimArcane = (balance <= -2)

        local barNames = {
            "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton", 
            "MultiBarRightButton", "MultiBarLeftButton"
        }

        for _, barName in ipairs(barNames) do
            for i = 1, 12 do
                local button = _G[barName..i]
                local cooldownFrame = _G[barName..i.."Cooldown"]
                
                if button and cooldownFrame then
                    local actionSlot = button.action
                    local actionType, spellId = GetActionInfo(actionSlot)
                    
                    if actionType == "spell" then
                        -- 1. Check Astrolabe Dynamic Bans (Balance Cap)
                        local isNature = self.natureDamageSpells[spellId]
                        local isArcane = self.arcaneDamageSpells[spellId]
                        local isForbiddenByBalance = (dimNature and isNature) or (dimArcane and isArcane)

                        -- 2. Check Permanent Bans (Resto/Feral)
                        local isForbiddenPermanently = self.forbiddenFeralSpells[spellId] or self.forbiddenRestoSpells[spellId]

                        if isForbiddenByBalance or isForbiddenPermanently then
                            -- FORCE RED OVERLAY
                            -- We use GetTime() as start to force the 'swipe' to always be full
                            CooldownFrame_Set(cooldownFrame, GetTime(), 3600, 1)
                            if cooldownFrame.SetDrawEdge then cooldownFrame:SetDrawEdge(false) end
                            if cooldownFrame.SetDrawSwipe then cooldownFrame:SetDrawSwipe(true) end
                            if cooldownFrame.SetHideCountdownNumbers then cooldownFrame:SetHideCountdownNumbers(true) end
                        else
                            -- RESTORE REAL COOLDOWN
                            local start, duration, enabled = GetSpellCooldown(spellId)
                            if start and duration then
                                CooldownFrame_Set(cooldownFrame, start, duration, enabled)
                                if cooldownFrame.SetHideCountdownNumbers then cooldownFrame:SetHideCountdownNumbers(false) end
                            else
                                CooldownFrame_Set(cooldownFrame, 0, 0, 0)
                            end
                        end
                    else
                        CooldownFrame_Set(cooldownFrame, 0, 0, 0)
                    end
                end
            end
        end
    end,

    StartForcedUpdates = function(self)
        if self.updateFrame then return end 

        self.updateFrame = CreateFrame("Frame")
        self.updateTimer = 0
        
        local challenge = self
        
        self.updateFrame:SetScript("OnUpdate", function(f, elapsed)
            challenge.updateTimer = challenge.updateTimer + elapsed
            
            if challenge.updateTimer > 0.1 then
                challenge:UpdateActionbarOverlay()
                challenge.updateTimer = 0
            end
        end)
    end,

    IsSpellForbidden = function(self, spellId) 
        if self.forbiddenFeralSpells[spellId] or self.forbiddenRestoSpells[spellId] then return true end
        
        if not UnitAffectingCombat("player") then return false end

        local balance = Purity:GetDB().astrolabeBalance or 0

        if balance >= 2 and self.natureDamageSpells[spellId] then
            return true
        end
        if balance <= -2 and self.arcaneDamageSpells[spellId] then
            return true
        end

        return false 
    end,

    AuditKnownSpells = function(self, violationFunc)
        for i = 1, GetNumSpellTabs() do
            local _, _, _, numSpells = GetSpellTabInfo(i)
            for j = 1, numSpells do
                local spellID = GetSpellBookItemInfo(j, "spell")
                if spellID and not self.ignoredStartSpells[spellID] then
                    if self:IsSpellForbidden(spellID) then
                        violationFunc("Found forbidden spell '"..GetSpellInfo(spellID).."' known at time of challenge acceptance.")
                        return false
                    end
                end
            end
        end
        return true
    end,
    IsTalentForbidden = function(self, id)
        return IsIDInForbiddenTree(id, "Feral Combat") or IsIDInForbiddenTree(id, "Restoration")
    end,
    IsItemForbidden = function(self, itemLink) return false end,
    isWeaponAllowed = function(self, itemLink) return true end,
    IsUnitForbidden = function(self, unit) return false end,

    CreateBalanceFrame = function(self)
        if self.balanceFrame then return end
        
        -- 1. Create the Main Container
        local f = CreateFrame("Frame", "PurityAstrolabeFrame", UIParent)
        f:SetSize(256, 64) 
        f:SetPoint("CENTER", 0, -180)
        f:EnableMouse(true)
        f:Show() 
        
        -- TOOLTIP SCRIPT
        f:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Balance Bar", 1, 1, 1)
            GameTooltip:AddLine("The stars demand equilibrium. You may hold a maximum of 2 consecutive charges of one school before the Astrolabe shatters, and you fail the challenge.", 1, 0.82, 0, true)
            GameTooltip:Show()
        end)

        f:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
        
        -- 2. BACKGROUND LAYER
        f.backing = f:CreateTexture(nil, "BACKGROUND")
        f.backing:SetSize(235, 40)
        f.backing:SetPoint("CENTER")
        f.backing:SetColorTexture(0, 0, 0, 0.8) 

        -- 3. MIDDLE LAYER: The Pips
        local barTexture = "Interface\\TargetingFrame\\UI-StatusBar"

        -- LEFT SIDE (Arcane)
        self.pipsArcane = {}
        for i = 1, 2 do
            local p = f:CreateTexture(nil, "BORDER") 
            p:SetSize(55, 42) 
            p:SetTexture(barTexture)
            p:SetBlendMode("BLEND") 
            p:SetPoint("RIGHT", f, "CENTER", 0 - ((i-1)*57), 0)
            p:SetVertexColor(0.6, 0.2, 1.0, 0.2) 
            table.insert(self.pipsArcane, p)
        end

        -- RIGHT SIDE (Nature)
        self.pipsNature = {}
        for i = 1, 2 do
            local p = f:CreateTexture(nil, "BORDER") 
            p:SetSize(55, 42) 
            p:SetTexture(barTexture)
            p:SetBlendMode("BLEND") 
            p:SetPoint("LEFT", f, "CENTER", 0 + ((i-1)*57), 0)
            p:SetVertexColor(0.2, 1.0, 0.2, 0.2)
            table.insert(self.pipsNature, p)
        end

        -- 4. TOP LAYER: Your Custom Frame Art
        f.bg = f:CreateTexture(nil, "ARTWORK")
        f.bg:SetAllPoints(true)
        f.bg:SetTexture("Interface\\AddOns\\Purity\\Media\\AstrolabeFrame.tga") 

        -- 5. TEXT LAYER: The Numbers (X/2)
        -- Arcane Text (Left Side)
        f.arcaneText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        f.arcaneText:SetPoint("CENTER", -60, 0) -- Positioned over left bars
        f.arcaneText:SetText("0/2")

        -- Nature Text (Right Side)
        f.natureText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        f.natureText:SetPoint("CENTER", 60, 0) -- Positioned over right bars
        f.natureText:SetText("0/2")

        self.balanceFrame = f
        self:UpdateBalanceFrame()
    end,
	
	UpdateBalanceFrame = function(self)
        if not self.balanceFrame then return end
        
        self.balanceFrame:Show()
        
        -- GET DATABASE
        local db = Purity:GetDB()
        local score = db.astrolabeBalance or 0
        local absScore = math.abs(score)
        local f = self.balanceFrame

        -- 1. UPDATE PIPS (Visual Bars)
        for i, pip in ipairs(self.pipsArcane) do
            if score < 0 and i <= absScore then
                pip:SetVertexColor(0.8, 0.2, 1.0, 1.0)
            else
                pip:SetVertexColor(0.3, 0.1, 0.5, 0.3)
            end
        end

        for i, pip in ipairs(self.pipsNature) do
            if score > 0 and i <= absScore then
                pip:SetVertexColor(0.1, 1.0, 0.1, 1.0)
            else
                pip:SetVertexColor(0.0, 0.4, 0.0, 0.3)
            end
        end

        -- 2. UPDATE TEXT NUMBERS (X/2)
        -- Only show if the setting is enabled (defaults to true)
        if db.showAstrolabeNumbers ~= false then
            f.arcaneText:Show()
            f.natureText:Show()

            if score < 0 then
                -- ARCANE ACTIVE
                f.arcaneText:SetText(absScore .. "/2")
                f.arcaneText:SetTextColor(1, 1, 1) -- White
                f.natureText:SetText("0/2")
                f.natureText:SetTextColor(0.5, 0.5, 0.5) -- Gray
            elseif score > 0 then
                -- NATURE ACTIVE
                f.arcaneText:SetText("0/2")
                f.arcaneText:SetTextColor(0.5, 0.5, 0.5) -- Gray
                f.natureText:SetText(absScore .. "/2")
                f.natureText:SetTextColor(1, 1, 1) -- White
            else
                -- NEUTRAL
                f.arcaneText:SetText("0/2")
                f.arcaneText:SetTextColor(0.5, 0.5, 0.5)
                f.natureText:SetText("0/2")
                f.natureText:SetTextColor(0.5, 0.5, 0.5)
            end
        else
            -- HIDE IF DISABLED
            f.arcaneText:Hide()
            f.natureText:Hide()
        end
    end,
	
	CreateVignetteFrame = function(self)
        if self.vignetteFrame then return end
        
        local f = CreateFrame("Frame", "PurityVignetteFrame", UIParent)
        f:SetAllPoints(UIParent)
        f:SetFrameStrata("BACKGROUND")
        f:EnableMouse(false)
        f:Show()
        
        local texFile = "Interface\\FullScreenTextures\\LowHealth"

        -- HELPER: Function to create a glow layer
        local function CreateLayer(colorR, colorG, colorB)
            local t = f:CreateTexture(nil, "ARTWORK")
            t:SetAllPoints(true)
            t:SetTexture(texFile)
            t:SetDesaturated(true)
            t:SetBlendMode("ADD") 
            t:SetVertexColor(colorR, colorG, colorB)
            t:SetAlpha(0)
            return t
        end

        -- NATURE LAYERS (Green)
        -- We create 3 separate layers. Stacking them makes the glow 3x brighter.
        self.natureLayers = {}
        for i = 1, 4 do
            table.insert(self.natureLayers, CreateLayer(0.2, 1.0, 0.2))
        end

        -- ARCANE LAYERS (Purple)
        self.arcaneLayers = {}
        for i = 1, 4 do
            table.insert(self.arcaneLayers, CreateLayer(1.0, 0.3, 1.0))
        end

        self.vignetteFrame = f
    end,
	
	UpdateVignette = function(self)
        if not self.vignetteFrame then return end
        
        local score = Purity:GetDB().astrolabeBalance or 0
        local f = self.vignetteFrame

        -- Helper to control layers
        local function SetLayers(layers, count)
            for i, tex in ipairs(layers) do
                if i <= count then
                    tex:SetAlpha(1.0) -- Full brightness
                else
                    tex:SetAlpha(0) -- Off
                end
            end
        end

        if score == 0 then
            SetLayers(self.natureLayers, 0)
            SetLayers(self.arcaneLayers, 0)
            
        elseif score > 0 then
            -- NATURE
            SetLayers(self.arcaneLayers, 0)
            
            if score == 1 then
                SetLayers(self.natureLayers, 1)
            elseif score >= 2 then
                SetLayers(self.natureLayers, 4)
            end
            
        elseif score < 0 then
            -- ARCANE
            SetLayers(self.natureLayers, 0)
            
            local absScore = math.abs(score)
            if absScore == 1 then
                SetLayers(self.arcaneLayers, 1)
            elseif absScore >= 2 then
                SetLayers(self.arcaneLayers, 4)
            end
        end
    end,

    EventHandler = function(self, event, ...)
        local db = Purity:GetDB()

        -- Reset only on death
        if event == "PLAYER_UNGHOST" or event == "PLAYER_ALIVE" then
            db.astrolabeBalance = 0
            self:UpdateBalanceFrame()
            self:UpdateVignette()

        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellId, spellName, _, missType = CombatLogGetCurrentEventInfo()

            if sourceGUID ~= UnitGUID("player") then return end

            local isNature = self.natureDamageSpells[spellId]
            local isArcane = self.arcaneDamageSpells[spellId]
            
            if not (isNature or isArcane) then return end
            
            if not db.astrolabeBalance then db.astrolabeBalance = 0 end

            if subEvent == "SPELL_CAST_SUCCESS" then
                
                if isNature then
                    secureAstrolabeBalance = secureAstrolabeBalance + 1
                    self.lastDamageSpellSchool = "Nature"
                elseif isArcane then
                    secureAstrolabeBalance = secureAstrolabeBalance - 1
                    self.lastDamageSpellSchool = "Arcane"
                end

                self:UpdateBalanceFrame()
                self:UpdateVignette()
                self:UpdateActionbarOverlay()

                if secureAstrolabeBalance > 2 then
                    Purity:Violation("Nature Overload! The Astrolabe shattered.\nMax 2 consecutive charges allowed.")
                elseif secureAstrolabeBalance < -2 then
                    Purity:Violation("Arcane Overload! The Astrolabe shattered.\nMax 2 consecutive charges allowed.")
                end
                
                if not db.challengeStats then db.challengeStats = {} end
                db.challengeStats.celestialCasts = (db.challengeStats.celestialCasts or 0) + 1

            elseif subEvent == "SPELL_MISSED" then
                if isNature then
                    secureAstrolabeBalance = secureAstrolabeBalance - 1
                elseif isArcane then
                    secureAstrolabeBalance = secureAstrolabeBalance + 1
                end
                
                self:UpdateBalanceFrame()
                self:UpdateVignette()
                self:UpdateActionbarOverlay()
            end
        elseif event == "PLAYER_LOGOUT" then
            self:SaveData()
        end
	end,
	SyncTruth = function(self, db)
        if db.astrolabeBalance ~= secureAstrolabeBalance then
            db.astrolabeBalance = secureAstrolabeBalance
            self:UpdateBalanceFrame()
        end
    end,
	SaveData = function(self)
        local db = Purity:GetDB()
        db.astrolabeBalance = secureAstrolabeBalance
    end,
}

Purity.ClassModules = Purity.ClassModules or {}
Purity.ClassModules.DRUID = DruidModule