-- Purity AddOn - Shaman Module: The Totemic Tether (Final)

local addonName, Purity = ...

local ShamanModule = {
    challenges = {},
    isAddonFullyLoaded = false,
}

local secureConnection = 100
local function GetTotemSpawnOffset(slot, facing)
    local dist = 2.5
    local angle = facing or 0
    
    if slot == 1 then -- Fire
        angle = angle + (math.pi / 4)
    elseif slot == 2 then -- Earth
        angle = angle - (math.pi / 4)
    elseif slot == 3 then -- Water
        angle = angle + (3 * math.pi / 4)
    elseif slot == 4 then -- Air
        angle = angle - (3 * math.pi / 4)
    end
    
    local dx = math.cos(angle) * dist
    local dy = math.sin(angle) * dist
    
    return dx, dy
end

-- ============================================================================
-- CHALLENGE 1: COMMUNION OF PURITY (Weaponless)
-- ============================================================================
ShamanModule.challenges.COMMUNION = {
    challengeName = "Communion of Purity",
    id = "COMMUNION",
    description = "The Spirit Walker. Your power flows purely from your spells and maintaining active totems in combat. No weapons of any kind.",
    needsWeaponWarning = true,
    optInWarningText = "|cffff0000IMPORTANT: This challenge forbids all weapons. You must unequip your mace before you begin.|r",
    KEY_TOTEM_SPELL_ID = 8071, -- Earth Totem

    activeTotemSlots = {
        [FIRE_TOTEM_SLOT] = false,
        [EARTH_TOTEM_SLOT] = false,
        [WATER_TOTEM_SLOT] = false,
        [AIR_TOTEM_SLOT] = false
    },

    GetRulesText = function(self)
        return {
            "|cffffd100Key Prohibitions:|r",
            "|cff261A0D  • You may NOT equip any weapons of any kind.|r",
            "|cff261A0D  • You must always maintain at least one active totem while in combat.|r",
            "|cff261A0D  • You must learn your first totem spell before Level 6.|r",
        }
    end,

    isWeaponAllowed = function(self, itemLink)
        if not itemLink then return true end
        local _, _, _, _, _, itemType, itemSubType = GetItemInfo(itemLink)
        if itemType == "Weapon" and (itemSubType ~= "Fishing Pole" and itemSubType ~= "Fishing Poles") then return false end
        return true
    end,

    IsItemForbidden = function(self, itemLink)
        if not itemLink then return false end
        return not self:isWeaponAllowed(itemLink)
    end,

    CheckActiveTotems = function(self)
        if not Purity:GetDB().hasCompletedShamanTotemQuest then return true end
        for _, isActive in pairs(self.activeTotemSlots) do
            if isActive then return true end
        end
        return false
    end,

    EventHandler = function(self, event, ...)
        local currentDB = Purity:GetDB()
        if event == "SPELLS_CHANGED" then
            if not currentDB.hasCompletedShamanTotemQuest and IsSpellKnown(self.KEY_TOTEM_SPELL_ID) then
                currentDB.hasCompletedShamanTotemQuest = true
            end
        elseif event == "PLAYER_TOTEM_UPDATE" then
            local totemSlot = ...
            local haveTotem, _, _, duration = GetTotemInfo(totemSlot)
            self.activeTotemSlots[totemSlot] = (haveTotem and duration > 0)
        elseif event == "PLAYER_EQUIPMENT_CHANGED" then
            Purity:CheckWeaponState()
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, subEvent, _, sourceGUID, _, _, _, _, _, destFlags, _, spellId, spellName = CombatLogGetCurrentEventInfo()
            if sourceGUID == UnitGUID("player") then
                local isOffensive = (subEvent == "SWING_DAMAGE")
                if subEvent == "SPELL_CAST_SUCCESS" then
                    local offensiveSpells = { ["Lightning Bolt"]=true, ["Chain Lightning"]=true, ["Earth Shock"]=true, ["Flame Shock"]=true, ["Frost Shock"]=true }
                    if offensiveSpells[spellName] or (destFlags and bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) ~= 0) then
                        isOffensive = true
                    end
                    if spellName == "Lightning Bolt" then
                        if not currentDB.challengeStats then currentDB.challengeStats = {} end
                        currentDB.challengeStats.lightningBoltCasts = (currentDB.challengeStats.lightningBoltCasts or 0) + 1
                    end
                end
                if isOffensive and not self:CheckActiveTotems() then
                    Purity:Violation("Offensive action taken without an active totem!")
                end
            end
        elseif event == "PLAYER_LEVEL_UP" then
            local newLevel = ...
            if newLevel == 6 and not IsSpellKnown(self.KEY_TOTEM_SPELL_ID) then
                Purity:Violation("Failed to learn the first totem spell before reaching Level 6.")
            end
        end
    end,
}

-- ============================================================================
-- CHALLENGE 2: FLAME OF PURITY (Fire Only)
-- ============================================================================
ShamanModule.challenges.FLAME = {
    challengeName = "Flame of Purity",
    id = "FLAME",
    description = "You begin as a normal Shaman, but at level 10 your path changes. Your spirit awakens to the flame. From that moment on, you may only use Fire spells, Fire totems, and physical attacks.",
    needsWeaponWarning = false,

    GetRulesText = function(self)
        return {
            "|cffffd100Level 10+ Prohibitions:|r",
            "|cff261A0D  • Only Fire spells may be cast.|r",
            "|cff261A0D  • Only Fire totems may be used.|r",
        }
    end,

    -- [[ 1. SMART AUTO-AMNESTY (The Retroactive Fix) ]] --
    InitializeOnPlayerEnterWorld = function(self)
        local db = Purity:GetDB()
        
        -- Only check if they are failed with a specific reason recorded
        if db.isOptedIn and db.status == "Failed" and db.failureReason then
            
            -- Extract the text of what killed them (e.g. "Linen Bandage")
            local spellName = string.match(db.failureReason, "Used a forbidden spell: (.*)")
            
            if spellName then
                local shouldForgive = false
                
                -- A. Ask the game what school this spell/item belongs to
                local _, _, _, _, _, _, _, school = GetSpellInfo(spellName)
                
                -- B. Evaluate the School
                -- If school is nil or 0, it is a trade skill/item (Safe).
                -- If school is Physical (1) or Fire (4), it is Safe.
                if not school or school == 0 or school == 1 or school == 4 then
                    shouldForgive = true
                end

                -- C. Safety Check: If it's explicitly Forbidden Magic, DO NOT forgive.
                -- Mask 122 = Holy(2) + Nature(8) + Frost(16) + Shadow(32) + Arcane(64)
                if school and bit.band(school, 122) > 0 then
                    shouldForgive = false
                end

                -- D. Execute Revival
                if shouldForgive then
                    db.status = "Passing"
                    db.failureReason = nil
                    
                    -- Re-sign the data so the new status is valid
                    if Purity.CreateDataSignature then
                        db.dataSignature = Purity:CreateDataSignature(db)
                    end
                    
                    -- Notify the user
                    C_Timer.After(4, function() 
                        print("|cff00ff00[Purity] RECOVERY:|r The spirits have recognized an error.")
                        print("|cff00ff00Your failure due to '".. spellName .."' has been overturned. Your run is valid.|r")
                    end)
                end
            end
        end
    end,

    -- [[ 2. SPELL BLACKLIST (The Prevention Fix) ]] --
    IsSpellForbidden = function(self, spellId)
        if UnitLevel("player") < 10 then return false end
        if not spellId then return false end
        
        -- 1. Whitelist of specific IDs (Totems/Overrides)
        local allowed = { [8050]=true, [8024]=true, [3599]=true, [1535]=true, [8052]=true, [8027]=true, [6363]=true, [8498]=true, [8181]=true, [8030]=true, [8190]=true, [8184]=true, [8053]=true, [8227]=true, [6364]=true, [8499]=true, [16339]=true, [10585]=true, [8249]=true, [10478]=true, [10447]=true, [6365]=true, [11314]=true, [10537]=true, [16341]=true, [10586]=true, [10526]=true, [10437]=true, [11315]=true, [10448]=true, [10479]=true, [16342]=true, [10587]=true, [10538]=true, [16387]=true, [2645]=true, [131]=true, [6196]=true, [546]=true, [556]=true }
        if allowed[spellId] then return false end

        -- 2. Get School Info
        local _, _, _, _, _, _, _, school = GetSpellInfo(spellId)

        -- 3. Allow "None" or "Physical"
        -- Trade skills, Crafting, and Items usually return nil, 0, or 1.
        if not school or school == 0 or school == 1 then return false end
        
        -- 4. Allow Fire (4)
        if school == 4 then return false end

        -- 5. The Blacklist (Forbid everything else)
        -- We block Holy(2), Nature(8), Frost(16), Shadow(32), Arcane(64).
        -- 2 + 8 + 16 + 32 + 64 = 122
        local forbiddenMask = 122 
        
        if bit.band(school, forbiddenMask) > 0 then 
            return true 
        end

        return false
    end,

    IsItemForbidden = function(self, itemLink) return false end,

    EventHandler = function(self, event, ...)
        if UnitLevel("player") < 10 then return end
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellId, spellName = CombatLogGetCurrentEventInfo()
            if sourceGUID == UnitGUID("player") and subEvent == "SPELL_CAST_SUCCESS" then
                if self:IsSpellForbidden(spellId) then
                    Purity:Violation("Used a forbidden spell: " .. (spellName or "Unknown"))
                else
                    local _, _, _, _, _, _, _, _, school = GetSpellInfo(spellId)
                    if school and school == 4 then
                        local db = Purity:GetDB()
                        if not db.challengeStats then db.challengeStats = {} end
                        db.challengeStats.fireSpellCasts = (db.challengeStats.fireSpellCasts or 0) + 1
                    end
                end
            end
        elseif event == "PLAYER_TOTEM_UPDATE" then
            local totemSlot = ...
            if totemSlot ~= FIRE_TOTEM_SLOT then
                local have, _, _, _ = GetTotemInfo(totemSlot)
                if have then Purity:Violation("Used a non-Fire totem.") end
            end
        end
    end
}

-- ============================================================================
-- CHALLENGE 3: TETHER OF PURITY (Strict Distance Check)
-- ============================================================================
ShamanModule.challenges.tether = {
    id = "Tether of Purity",
    challengeName = "Tether of Purity",
    description = "You are a conduit for the spirits. Planting totems creates a 'Tether' zone. If you stray too far from your totems, your connection snaps. Casting spells without an active connection will break your vow.",
    
    maxRange = 30,      
    KEY_TOTEM_SPELL_ID = 8071, -- Earth Totem (Rank 1)
	currentDisplayPct = 1.0,
    
    activeTotems = {},  
    talentMods = { range = 0, wolfGen = false, cost = 0 },

    ignoredSpells = {
        ["Attack"] = true, ["Hearthstone"] = true, ["Astral Recall"] = true, 
        ["Ghost Wolf"] = true, ["War Stomp"] = true, ["Ancestral Spirit"] = true,
        ["Lightning Shield"] = true, 
        ["Rockbiter Weapon"] = true, ["Windfury Weapon"] = true, ["Flametongue Weapon"] = true, ["Frostbrand Weapon"] = true,
        ["LOGINEFFECT"] = true,
        ["Find Minerals"] = true, ["Find Herbs"] = true, ["Find Fish"] = true,
        ["Smelting"] = true, ["Mining"] = true, ["Skinning"] = true, 
        ["Herbalism"] = true, ["Alchemy"] = true, ["Blacksmithing"] = true,
        ["Cooking"] = true, ["Basic Campfire"] = true, ["First Aid"] = true,
        ["Fishing"] = true, ["Enchanting"] = true, ["Disenchant"] = true,
        ["Tailoring"] = true, ["Leatherworking"] = true, ["Engineering"] = true,
    },

    InitializeOnPlayerEnterWorld = function(self)
        if self.isInitialized then return end
        
        local db = Purity:GetDB()
        if not db.tetherTotems then db.tetherTotems = {} end
        
        for slot = 1, 4 do
            local haveTotem, _, _, duration = GetTotemInfo(slot)
            if not haveTotem or duration == 0 then
                db.tetherTotems[slot] = nil
            end
        end

        self:CreateConnectionBar()
        self:CreateWarningUI()
        
        C_Timer.After(1.0, function() 
            self:CheckTalents()
            self:SetupTooltips()
        end)
        self:StartMonitor()
        self:RegisterEvents()
        self.isInitialized = true
    end,
	
	CreateConnectionBar = function(self)
        if self.barFrame then return end
        local f = CreateFrame("Frame", "PurityShamanTetherFrame", UIParent)
        f:SetSize(200, 25)
        f:SetPoint("CENTER", 0, -180)
        f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop", f.StopMovingOrSizing)
        
        f.bg = f:CreateTexture(nil, "BACKGROUND")
        f.bg:SetAllPoints(true)
        f.bg:SetColorTexture(0, 0, 0, 0.8)
        
        f.bar = f:CreateTexture(nil, "ARTWORK")
        f.bar:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
        f.bar:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -2)
        f.bar:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 2, 2)
        f.bar:SetWidth(196)
        f.bar:SetVertexColor(0, 0.5, 1)
        
        f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        f.text:SetPoint("CENTER")
        f.text:SetText("Tether: 100%")
        
        f.border = CreateFrame("Frame", nil, f, "BackdropTemplate")
        f.border:SetPoint("TOPLEFT", -2, 2)
        f.border:SetPoint("BOTTOMRIGHT", 2, -2)
        f.border:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12 })
        
        self.barFrame = f
    end,

    UpdateBar = function(self, pct)
        if not self.barFrame then return end
        
        pct = math.max(0, math.min(1, pct))
        
        local totalWidth = self.barFrame:GetWidth() - 4
        self.barFrame.bar:SetWidth(math.max(1, totalWidth * pct))
        
        self.barFrame.text:SetText(string.format("Tether: %d%%", math.floor(pct * 100)))
        
        if pct <= 0 then self.barFrame.bar:SetVertexColor(0.5, 0.5, 0.5)
        elseif pct < 0.3 then self.barFrame.bar:SetVertexColor(1, 0.2, 0.2)
        elseif pct < 0.6 then self.barFrame.bar:SetVertexColor(1, 1, 0)
        else self.barFrame.bar:SetVertexColor(0, 0.5, 1) end
    end,

    SetupTooltips = function(self)
        local function AppendToDescription(tooltip, keyword, textToAppend)
            local frameName = tooltip:GetName()
            for i = 2, tooltip:NumLines() do 
                local line = _G[frameName .. "TextLeft" .. i]
                if line then
                    local text = line:GetText()
                    if text and string.find(string.lower(text), string.lower(keyword)) then
                        line:SetText(text .. "|cffffd100" .. textToAppend .. "|r")
                        tooltip:Show() 
                        return true
                    end
                end
            end
            return false
        end

        local function OnTooltipSetSpell(tooltip)
            local db = Purity:GetDB()
            if db.activeChallengeID ~= "Tether of Purity" then return end

            local name = tooltip:GetSpell()
            if not name then return end

            if name == "Ghost Wolf" then
                if self.talentMods.wolfGen then
                    AppendToDescription(tooltip, "Wolf", " Sustains Connection while moving.")
                end
            elseif string.find(name, "Totem") then
                local range = self.maxRange or 20
                AppendToDescription(tooltip, "Summons", " Creates a Tether Zone (" .. range .. " yds).")
            end
        end

        local function OnSetTalent(tooltip)
            local db = Purity:GetDB()
            if db.activeChallengeID ~= "Tether of Purity" then return end

            local frameName = tooltip:GetName()
            if not frameName then return end

            local line1 = _G[frameName .. "TextLeft1"]
            if not line1 then return end
            
            local name = line1:GetText()
            if not name then return end

            if name == "Totemic Mastery" then
                AppendToDescription(tooltip, "radius", " Increases Tether Connection range by 10 yards.")
            elseif name == "Improved Ghost Wolf" then
                AppendToDescription(tooltip, "cast", " Allows Ghost Wolf to maintain Connection away from totems.")
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
            "|cffffd100Status:|r",
            "|cff261A0D  • Levels 1-4: Your spirit is Unbound. The Tether is not yet forged.|r",
            "|cff261A0D  • Earth Totem Unlock: The Tether activates immediately.|r",
            " ",
            "|cffffd100Strict Distance Connection:|r",
            "|cff261A0D  • You must be within range of an active Totem to cast spells.|r",
            "|cff261A0D  • If you leave the zone entirely, the Tether instantly snaps.|r",
            " ",
            "|cffff0000FAIL CONDITION:|r",
            "|cff261A0D  • Casting a spell (Bolt, Shock, Heal) while outside Totem range is a violation.|r",
            "|cff261A0D  (You may still drop Totems or Auto-Attack out of range to recover).|r",
        }
    end,
    
    HasUnlockedTotems = function(self)
        return IsSpellKnown(self.KEY_TOTEM_SPELL_ID)
    end,

    CheckTalents = function(self)
        self.talentMods = { range = 0, wolfGen = false, cost = 0 }
        local numTabs = GetNumTalentTabs()
        for t = 1, numTabs do
            local numTalents = GetNumTalents(t)
            for i = 1, numTalents do
                local name, _, _, _, rank = GetTalentInfo(t, i)
                if name == "Totemic Mastery" and rank > 0 then self.talentMods.range = 10 end 
                if name == "Improved Ghost Wolf" and rank > 0 then self.talentMods.wolfGen = true end
                if name == "Totemic Focus" and rank > 0 then self.talentMods.cost = rank * 0.05 end
            end
        end
        self.maxRange = 20 + self.talentMods.range
    end,

    RegisterEvents = function(self)
        if not self.eventFrame then self.eventFrame = CreateFrame("Frame") end
        
        self.eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        self.eventFrame:RegisterEvent("PLAYER_TOTEM_UPDATE")
        self.eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
        self.eventFrame:RegisterEvent("PLAYER_LEVEL_UP")
        self.eventFrame:RegisterEvent("SPELLS_CHANGED")
        self.eventFrame:SetScript("OnEvent", function(frame, event, ...)
            if event == "PLAYER_TALENT_UPDATE" then self:CheckTalents()
            else self:EventHandler(event, ...) end
        end)
    end,

    EventHandler = function(self, event, ...)
        if not self:HasUnlockedTotems() then return end
        local db = Purity:GetDB()
        if not db.tetherTotems then db.tetherTotems = {} end
        
        if event == "PLAYER_TOTEM_UPDATE" then
            local totemSlot = ...
            local haveTotem, totemName, startTime, duration = GetTotemInfo(totemSlot)
            
            if haveTotem and duration > 0 then
                local mapID = C_Map.GetBestMapForUnit("player")
                if mapID then
                    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
                    if pos then
                        local _, worldPos = C_Map.GetWorldPosFromMapPos(mapID, pos)
                        if worldPos then
                            local wX, wY = worldPos:GetXY()
                            local facing = GetPlayerFacing()
                            local dx, dy = GetTotemSpawnOffset(totemSlot, facing)
                            
                            -- Save the offset coordinates instead of the player's center
                            db.tetherTotems[totemSlot] = { x = wX + dx, y = wY + dy, map = mapID, name = totemName }
                        end
                    end
                end
            else
                db.tetherTotems[totemSlot] = nil
            end
			
		elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            local unit, _, spellId = ...
            if unit == "player" then
                local spellName = GetSpellInfo(spellId)
                if not spellName then return end
                
                if spellName == "Lightning Shield" then
                    local db = Purity:GetDB()
                    if not db.tetherTotems then db.tetherTotems = {} end
                    
                    local closestDistSq = 9999
                    for slot, data in pairs(db.tetherTotems) do
                        local d2 = self:GetDistanceSquaredToTotem(data)
                        if d2 < closestDistSq then closestDistSq = d2 end
                    end

                    local rangeCapSq = self.talentMods.range > 0 and 900 or 400
                    local failureLimitSq = rangeCapSq * 1.21 
                    
                    local hasGhostWolf = false
                    if self.talentMods.wolfGen then
                        for i=1,40 do if UnitBuff("player", i) == "Ghost Wolf" then hasGhostWolf = true; break end end
                    end

                    if not hasGhostWolf and closestDistSq > failureLimitSq then
                        Purity:Violation("Cast '" .. spellName .. "' outside of Tether range.")
                    end
                end
            end
            
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local timestamp, subEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceFlags2, destGUID, destName, destFlags, destFlags2, spellId, spellName = CombatLogGetCurrentEventInfo()
            
            if sourceGUID == UnitGUID("player") then
                if subEvent == "SWING_DAMAGE" or subEvent == "SWING_MISSED" then return end
                
                -- Ignore passive Lightning Shield damage procs from hitting enemies automatically
                if spellName == "Lightning Shield" then return end
                
                local isSpellDamage = subEvent == "SPELL_DAMAGE" or subEvent == "SPELL_PERIODIC_DAMAGE"
                local isRangedDamage = subEvent == "RANGE_DAMAGE"
                local isHealing = subEvent == "SPELL_HEAL" or subEvent == "SPELL_PERIODIC_HEAL"
                
                if isSpellDamage or isRangedDamage or isHealing then
                    local db = Purity:GetDB()
                    if not db.tetherTotems then db.tetherTotems = {} end
                    
                    local closestDistSq = 9999
                    for slot, data in pairs(db.tetherTotems) do
                        local d2 = self:GetDistanceSquaredToTotem(data)
                        if d2 < closestDistSq then closestDistSq = d2 end
                    end

                    local rangeCapSq = self.talentMods.range > 0 and 900 or 400
                    local failureLimitSq = rangeCapSq * 1.21 
                    
                    local hasGhostWolf = false
                    if self.talentMods.wolfGen then
                        for i=1,40 do if UnitBuff("player", i) == "Ghost Wolf" then hasGhostWolf = true; break end end
                    end

                    if not hasGhostWolf and closestDistSq > failureLimitSq then
                        Purity:Violation("Performed combat action outside of Tether range.")
                    end
                end
            end
        end
    end,

    GetDistanceSquaredToTotem = function(self, totemData)
        local mapID = C_Map.GetBestMapForUnit("player")
        if not mapID or mapID ~= totemData.map then return 9999 end 
        local pos = C_Map.GetPlayerMapPosition(mapID, "player")
        if not pos then return 9999 end
        
        local _, worldPos = C_Map.GetWorldPosFromMapPos(mapID, pos)
        if not worldPos then return 9999 end
        
        local pX, pY = worldPos:GetXY()
        local dx, dy = (pX - totemData.x), (pY - totemData.y)
        
        return (dx * dx) + (dy * dy)
    end,

    StartMonitor = function(self)
        if self.monitorTicker then return end
        
        self.monitorTicker = C_Timer.NewTicker(0.05, function() -- Pushed to 0.05s for higher framerate polling
            if UnitIsDeadOrGhost("player") or not self:HasUnlockedTotems() then 
                if self.barFrame then self.barFrame:Hide() end
                self:HideWarning()
                return 
            end

            if self.barFrame and not self.barFrame:IsShown() then self.barFrame:Show() end

            local db = Purity:GetDB()
            if not db.tetherTotems then db.tetherTotems = {} end

            local closestDistSq = 9999
            local hasGhostWolf = false
            
            if self.talentMods.wolfGen then
                for i=1,40 do if UnitBuff("player", i) == "Ghost Wolf" then hasGhostWolf = true; break end end
            end

            for slot, data in pairs(db.tetherTotems) do
                local d2 = self:GetDistanceSquaredToTotem(data)
                if d2 < closestDistSq then closestDistSq = d2 end
            end
            
            local rangeCapSq = self.talentMods.range > 0 and 900 or 400
            local failureLimitSq = rangeCapSq * 1.21 
            local warningLimitSq = rangeCapSq * 0.64 
            
            local rawPct = 0
            if hasGhostWolf then
                rawPct = 1.0
            else
                local rawDist = math.sqrt(closestDistSq)
                local maxDist = math.sqrt(rangeCapSq)
                rawPct = 1.0 - (rawDist / maxDist)
            end

            -- Smooth Interpolation (LERP): Glides the bar toward the target value
            if not self.currentDisplayPct then self.currentDisplayPct = rawPct end
            self.currentDisplayPct = self.currentDisplayPct + (rawPct - self.currentDisplayPct) * 0.3

            self:UpdateBar(self.currentDisplayPct)
            
            if not hasGhostWolf and closestDistSq > warningLimitSq and closestDistSq <= failureLimitSq then
                self:ShowWarning()
            else
                self:HideWarning()
            end
        end)
    end,

    CreateWarningUI = function(self)
        if self.warningFrame then return end
        local f = CreateFrame("Frame", "PurityShamanWarning", UIParent)
        f:SetSize(300, 100)
        f:SetPoint("TOP", 0, -200)
        f:Hide()
        f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
        f.text:SetPoint("CENTER")
        f.text:SetText("APPROACHING TETHER LIMIT")
        f.text:SetTextColor(1, 0.5, 0)
        self.warningFrame = f
    end,

    ShowWarning = function(self) if self.warningFrame and not self.warningFrame:IsShown() then self.warningFrame:Show() end end,
    HideWarning = function(self) if self.warningFrame then self.warningFrame:Hide() end end,
    SyncTruth = function(self, db) end,
    SaveData = function(self) end,
}

function ShamanModule:GetActiveChallengeObject()
    local db = Purity:GetDB()
    if not db.isOptedIn or not db.activeChallengeID then return nil end
    return self.challenges[db.activeChallengeID]
end

function ShamanModule:GetRulesText()
    local activeChallenge = self:GetActiveChallengeObject()
    if activeChallenge and activeChallenge.GetRulesText then return activeChallenge:GetRulesText() end
    return {"No active Shaman challenge."}
end

function ShamanModule:IsItemForbidden(itemLink)
    local activeChallenge = self:GetActiveChallengeObject()
    if activeChallenge and activeChallenge.IsItemForbidden then return activeChallenge:IsItemForbidden(itemLink) end
    return false
end

function ShamanModule:IsSpellForbidden(spellId)
    local activeChallenge = self:GetActiveChallengeObject()
    if activeChallenge and activeChallenge.IsSpellForbidden then return activeChallenge:IsSpellForbidden(spellId) end
    return false
end

function ShamanModule:isWeaponAllowed(itemLink)
    local activeChallenge = self:GetActiveChallengeObject()
    if activeChallenge and activeChallenge.isWeaponAllowed then return activeChallenge:isWeaponAllowed(itemLink) end
    return true
end

function ShamanModule:EventHandler(event, ...)
    local activeChallenge = self:GetActiveChallengeObject()
    if activeChallenge and activeChallenge.EventHandler then activeChallenge:EventHandler(event, ...) end
    if event == "PLAYER_LEVEL_UP" then
        local newLevel = ...
        if newLevel == 10 and Purity:GetDB().activeChallengeID == "FLAME" then
            Purity:ShowRuleUpdate("The Call of the Flame has awakened! From this moment on, you must adhere to its rules: only Fire and Physical abilities are permitted.")
        end
    end
end

function ShamanModule:InitializeOnPlayerEnterWorld()
    self.isAddonFullyLoaded = true

    -- [[ 1. AUTO-AMNESTY FOR PROFESSION BUG ]]
    local db = Purity:GetDB()
    
    -- We only check if they are currently Failed and have a Reason recorded
    if db.isOptedIn and db.status == "Failed" and db.failureReason then
        
        -- List of "spells" that caused false failures
        local innocentErrors = {
            ["Alchemy"] = true, ["Herbalism"] = true, ["Find Herbs"] = true,
            ["Mining"] = true, ["Find Minerals"] = true, ["Smelting"] = true,
            ["Skinning"] = true, ["Leatherworking"] = true,
            ["Engineering"] = true, ["Tailoring"] = true,
            ["Blacksmithing"] = true, ["Enchanting"] = true, ["Disenchant"] = true,
            ["Cooking"] = true, ["Basic Campfire"] = true,
            ["First Aid"] = true, ["Fishing"] = true
        }

        -- The failure reason usually looks like: "Used a forbidden spell: Skinning"
        -- We scan the reason string to see if it contains an innocent keyword
        for innocentName, _ in pairs(innocentErrors) do
            if string.find(db.failureReason, innocentName) then
                -- FALSE POSITIVE DETECTED
                
                -- A. Reverse the failure
                db.status = "Passing"
                db.failureReason = nil
                
                -- B. REGENERATE SIGNATURE 
                -- This is crucial. We must re-sign the data so the new "Passing" status 
                -- is considered valid by the website/future checks.
                if Purity.CreateDataSignature then
                    db.dataSignature = Purity:CreateDataSignature(db)
                end
                
                -- C. Notify the user
                C_Timer.After(4, function() 
                    print("|cff00ff00[Purity] RECOVERY:|r The spirits have recognized an error.")
                    print("|cff00ff00Your failure due to '".. innocentName .."' has been overturned. Your run is valid.|r")
                end)
                break 
            end
        end
    end

    -- [[ 2. NORMAL INITIALIZATION ]]
    local commChallenge = self.challenges.COMMUNION
    if IsSpellKnown(commChallenge.KEY_TOTEM_SPELL_ID) then Purity:GetDB().hasCompletedShamanTotemQuest = true end
    
    -- Run an initial check on spells/talents
    self:EventHandler("SPELLS_CHANGED")
    
    local active = self:GetActiveChallengeObject()
    if active and active.InitializeOnPlayerEnterWorld then active:InitializeOnPlayerEnterWorld() end
end

Purity.ClassModules = Purity.ClassModules or {}
Purity.ClassModules.SHAMAN = ShamanModule