-- Purity AddOn - Global Module: The Blood Mage's Bargain (Final Dual-Mode Version)

if not Purity then
    return
end

local function GetBloodCostPercentForSpeed(speed)
    if not speed or speed < 2.0 then
        return 0.01
    elseif speed < 3.0 then
        return 0.02
    else
        return 0.03
    end
end

local BloodMageModule = {
    id = "BLOOD_MAGE_BARGAIN",
    challengeName = "The Blood Mage's Bargain",
	wasBelowThreshold = false,
    visibilityManager = nil,
    originalStatusTextDisplay = nil,
    characterFrameHooked = false,
	forceNumericDisplay = false,
	lastOathbreakerRank = 0,
	talentTooltipHooked = false,
	
	GetOathbreakerRank = function(self)
		local _, class = UnitClass("player")
		if class ~= "PALADIN" then return 0 end
		
		local tab, index = 3, 5
		local name, _, _, _, rank = GetTalentInfo(tab, index, nil, nil, GetActiveTalentGroup())
		
		if name == "Benediction" then
			return rank or 0
		end
		return 0
	end,
	
	CreateOathBrokenBanner = function(self)
		if self.oathBrokenFrame then return end

		local f = CreateFrame("Frame", "PurityOathBrokenBanner", UIParent)
		f:SetSize(512, 172)
		f:SetPoint("TOP", 0, -150)
		f:SetFrameStrata("HIGH")
		f:Hide()

		local tex = f:CreateTexture(nil, "ARTWORK")
		tex:SetAllPoints(true)
		tex:SetTexture("Interface\\AddOns\\Purity\\Media\\Oath-Broken.tga")
		f.texture = tex

		f.animGroup = f:CreateAnimationGroup()
		
		local fadeIn = f.animGroup:CreateAnimation("Alpha")
		fadeIn:SetFromAlpha(0); fadeIn:SetToAlpha(1); fadeIn:SetDuration(0.8); fadeIn:SetOrder(1)

		local stay = f.animGroup:CreateAnimation("Alpha")
		stay:SetFromAlpha(1); stay:SetToAlpha(1); stay:SetDuration(3.0); stay:SetOrder(2)

		local fadeOut = f.animGroup:CreateAnimation("Alpha")
		fadeOut:SetFromAlpha(1); fadeOut:SetToAlpha(0); fadeOut:SetDuration(1.5); fadeOut:SetOrder(3)

		f.animGroup:SetScript("OnFinished", function() f:Hide() end)

		self.oathBrokenFrame = f
	end,

	ShowOathBrokenBanner = function(self)
		if not self.oathBrokenFrame then self:CreateOathBrokenBanner() end
		
		PlaySound(8647, "Master")
		self.oathBrokenFrame:Show()
		self.oathBrokenFrame.animGroup:Play()
	end,
	
	SetupTalentIconHook = function(self)
		if self.talentIconHooked then return end

		local function ApplyCustomIcon()
			local _, class = UnitClass("player")
			if class ~= "PALADIN" then return end
			
			local db = Purity:GetDB()
			if not db or db.activeChallengeID ~= self.id then return end

			if PlayerTalentFrame and PlayerTalentFrame:IsShown() then
				if PanelTemplates_GetSelectedTab(PlayerTalentFrame) == 3 then
					local icon = _G["PlayerTalentFrameTalent5IconTexture"]
					if icon then
						icon:SetTexture("Interface\\AddOns\\Purity\\Media\\Oath-Breaker-Talent.tga")
					end
				end
			end
		end

		if IsAddOnLoaded("Blizzard_TalentUI") then
			hooksecurefunc("TalentFrame_Update", ApplyCustomIcon)
		else
			local f = CreateFrame("Frame")
			f:RegisterEvent("ADDON_LOADED")
			f:SetScript("OnEvent", function(_, _, name)
				if name == "Blizzard_TalentUI" then
					hooksecurefunc("TalentFrame_Update", ApplyCustomIcon)
					f:UnregisterAllEvents()
				end
			end)
		end
		self.talentIconHooked = true
	end,
	
	-- Replace the SetupTalentTooltip function in Purity_BloodMage.lua
SetupTalentTooltip = function(self)
    if self.talentTooltipHooked then return end

    hooksecurefunc(GameTooltip, "SetTalent", function(tooltip)
        local db = Purity:GetDB()
        if not db or db.activeChallengeID ~= self.id then return end
        
        local frameName = tooltip:GetName()
        if not frameName then return end
        
        local line1 = _G[frameName .. "TextLeft1"]
        if not line1 then return end
        local talentName = line1:GetText()
        if not talentName then return end

        -- Identify the talent (using both names for compatibility)
        if talentName == "Benediction" or talentName == "Oath Breaker" then
            local currentRank = 0
            local maxRank = 5
            for i = 1, 30 do
                local name, _, _, _, rank, mRank = GetTalentInfo(3, i)
                if name == "Benediction" then
                    currentRank = rank or 0
                    maxRank = mRank or 5
                    break
                end
            end

            line1:SetText("|cffFF0000Oath Breaker|r")

            local passedNextRank = false
            local matchText = "Mana cost of your Judgement" 

            for i = 2, tooltip:NumLines() do
                local line = _G[frameName .. "TextLeft" .. i]
                if line then
                    local text = line:GetText()
                    if text then
                        if text == "Next rank:" or text == "Next Rank:" then
                            passedNextRank = true
                        elseif string.find(text, matchText) then
                            local rankToUse = currentRank
                            if currentRank == 0 then
                                rankToUse = 1 
                            elseif passedNextRank then
                                rankToUse = currentRank + 1 
                            end
                            rankToUse = math.min(rankToUse, maxRank)

                            local manaReduc = rankToUse * 3     -- Original: 3/6/9/12/15%
                            local bloodReduc = rankToUse * 5    -- Custom: 5/10/15/20/25%
                            local spiritBonus = rankToUse * 20  -- Custom: 20/40/60/80/100%

                            local newDesc = string.format(
                                "You turn your back to your vow to the Light and become an Oath Breaker. Reduces the Mana cost of your Judgement and Seal spells by %d%%, reduces the Blood cost of melee swings by %d%%, and increases the effectiveness of your Spirit at reducing costs by %d%%.", 
                                manaReduc, bloodReduc, spiritBonus
                            )
                            line:SetText(newDesc)
                        end
                    end
                end
            end
            tooltip:Show()
        end
    end)
    self.talentTooltipHooked = true
end,

	_HideDefaultHealthBar = function()
		PlayerFrameHealthBar:SetAlpha(0)
		
		PlayerFrameHealthBarText:Hide()
		if PlayerFrameHealthBarTextRight then
			PlayerFrameHealthBarTextRight:Hide()
		end
		if PlayerFrameHealthBarTextLeft then
			PlayerFrameHealthBarTextLeft:Hide()
		end
	end,

	_ShowDefaultHealthBar = function()
		PlayerFrameHealthBar:SetAlpha(1)

		local displayMode = GetCVar("statusTextDisplay")

		if displayMode == "BOTH" then
			PlayerFrameHealthBarText:Hide()
			if PlayerFrameHealthBarTextLeft then PlayerFrameHealthBarTextLeft:Show() end
			if PlayerFrameHealthBarTextRight then PlayerFrameHealthBarTextRight:Show() end
		elseif displayMode == "NONE" then
			PlayerFrameHealthBarText:Hide()
			if PlayerFrameHealthBarTextLeft then PlayerFrameHealthBarTextLeft:Hide() end
			if PlayerFrameHealthBarTextRight then PlayerFrameHealthBarTextRight:Hide() end
		else
			PlayerFrameHealthBarText:Show()
			if PlayerFrameHealthBarTextLeft then PlayerFrameHealthBarTextLeft:Hide() end
			if PlayerFrameHealthBarTextRight then PlayerFrameHealthBarTextRight:Hide() end
		end
	end,
	
    _ShowBloodPoolTooltip = function(self, frame)
        GameTooltip_SetDefaultAnchor(GameTooltip, frame)

        GameTooltip:SetText("Blood", 1, 1, 1)
        
        local description = "The amount of life force you currently have. Your blood is depleted by taking damage and by using your own abilities. If your blood reaches zero, your vow is broken. Melee and ranged auto-attacks cost a percentage of your max blood when not weakened. Your ability blood costs increase when your max blood increases, and are only decreased by increasing your Spirit stat. Blood automatically regenerates when you are out of combat."
        GameTooltip:AddLine(description, 1, 0.82, 0, true)

        GameTooltip:Show()
    end,
    
    _UpdateDefaultHealthBarVisibility = function(self)
        local db = Purity:GetDB()
        local challengeIsActive = db and db.isOptedIn and db.activeChallengeID == self.id and (db.status == "Passing" or db.status == "Temporary Failure - Uptime")
        
        if challengeIsActive and not db.bloodBarIsSeparate then
            self:_HideDefaultHealthBar()
        else
            self:_ShowDefaultHealthBar()
        end
    end,
	
    healingSpells = {
        ["Lesser Heal"] = true, ["Heal"] = true, ["Greater Heal"] = true, ["Flash Heal"] = true, ["Prayer of Healing"] = true, ["Renew"] = true,
        ["Holy Light"] = true, ["Flash of Light"] = true,
        ["Healing Touch"] = true, ["Rejuvenation"] = true, ["Regrowth"] = true,
        ["Healing Wave"] = true, ["Lesser Healing Wave"] = true, ["Chain Heal"] = true, ["Drain Life"] = true, ["Death Coil"] = true, ["Siphon Life"] = true, ["Vampiric Embrace"] = true, ["Devouring Plague"] = true,
    },
	
	bloodRegenTicker = nil,
    PurityScanTooltip = nil,

    allowedPeriodicHeals = {
		["Demon Skin"] = true,
        ["Demon Armor"] = true,
        ["Food"] = true,
        ["Blood Craze"] = true,
		["Regeneration"] = true,
		["Cannibalize"] = true,
    },
    
    sanguineWeaknessActive = false,
    sanguineWeaknessExpires = 0,
    spiritFactor = 12.0,
    bloodPoolCurrent = 0,
    bloodPoolMax = 0,
    bloodBarFrame = nil,
    debuffFrame = nil,
    regenFrame = nil,
    isDragging = false,
    partyBloodBars = {},
    groupFrameManager = nil,

    description = function()
        return "You have made a pact for power, allowing you to fuel your abilities with your own life force. Your vitality is your true power, but this pact is a double-edged sword: the more you heal and protect your life force, the weaker your bargain becomes."
    end,

    GetRulesText = function()
        return {
            "|cffffd100The Bargain:|r",
            "|cff261A0D  • Your life force is a resource for combat, represented by a Blood Pool.|r",
            "|cff261A0D  • All abilities, attacks, and damage taken deplete your Blood Pool.|r",
            "|cff261A0D  • If your Blood Pool is depleted, your vow is broken.|r",
            " ",
            "|cffffd100The Price of Weakness:|r",
            "|cff261A0D  • After restoring your own health, you become 'Weakened' for 15 seconds.",
            "|cff261A0D  • While 'Weakened', all Blood Pool costs are doubled.",
        }
    end,
	
	ApplyBarMode = function(self, isSeparate, isToggle)
		local bar = self.bloodBarFrame
		if not bar then
            return
        end

		local db = Purity:GetDB()
        local wasSeparate = db.bloodBarIsSeparate

		if isSeparate then
			bar:SetParent(UIParent)
			bar:SetFrameStrata("MEDIUM")
			bar:ClearAllPoints()

			if (isToggle and not wasSeparate) or not db.bloodBarX or not db.bloodBarY or type(db.bloodBarX) ~= "number" or type(db.bloodBarY) ~= "number" then
				bar:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
				db.bloodBarX = 0
				db.bloodBarY = 0
			else
				bar:SetPoint("CENTER", UIParent, "CENTER", db.bloodBarX, db.bloodBarY)
			end

			bar:SetSize(200, 20)
			bar:SetMovable(true)
			bar:EnableMouse(true)
			bar:RegisterForDrag("LeftButton")
			bar:SetScript("OnDragStart", function(frame) frame:StartMoving() end)
			bar:SetScript("OnDragStop", function(frame)
				frame:StopMovingOrSizing()
				local scale = UIParent:GetEffectiveScale()
				local x, y = frame:GetCenter()
                local screenCenterX = GetScreenWidth() / 2
                local screenCenterY = GetScreenHeight() / 2
				db.bloodBarX = (x / scale) - screenCenterX
				db.bloodBarY = (y / scale) - screenCenterY
			end)

            if not bar.background then
                bar.background = bar:CreateTexture(nil, "BACKGROUND")
                bar.background:SetAllPoints(bar)
                bar.background:SetColorTexture(0.1, 0.1, 0.1, 0.7)
            end
            bar.background:Show()
            bar:GetStatusBarTexture():SetAlpha(0.85)

            bar:SetAlpha(1)
            bar:Show()

            C_Timer.After(0.1, function()
                if bar:IsShown() then
                     local p1, _, p2, x, y = bar:GetPoint()
                else
                end
            end)

		else
			bar:SetParent(PlayerFrame)
			bar:SetFrameStrata("LOW")
			bar:SetFrameLevel(PlayerFrameHealthBar:GetFrameLevel())
			bar:ClearAllPoints()
			bar:SetPoint("TOPLEFT", PlayerFrameHealthBar, "TOPLEFT", 2, 0)
			bar:SetPoint("BOTTOMRIGHT", PlayerFrameHealthBar, "BOTTOMRIGHT", 0, 0)
			bar:SetSize(1, 1)
			bar:SetMovable(false)
			bar:EnableMouse(false)
			bar:SetScript("OnDragStart", nil)
			bar:SetScript("OnDragStop", nil)

            if bar.background then
                bar.background:Hide()
            end
            bar:GetStatusBarTexture():SetAlpha(1)
		end

        db.bloodBarIsSeparate = isSeparate

		self:_UpdateDefaultHealthBarVisibility()
	end,

	UpdateBarText = function(self)
		local bar = self.bloodBarFrame
		local container = self.textContainer

		local db = Purity:GetDB()
		if not (db and db.isOptedIn and (db.status == "Passing" or db.status == "Temporary Failure - Uptime")) then
			if container then container:Hide() end
			return
		end

		if not bar or not bar:IsShown() then
			if container then container:Hide() end
			return
		end

		if container then container:Show() end

		local textLeft = self.textLeft
		local textRight = self.textRight
		if not textLeft or not textRight then return end

        local displayMode
        if self.forceNumericDisplay then
            displayMode = "NUMERIC"
        else
            displayMode = GetCVar("statusTextDisplay")
        end

		local currentVal = math.floor(db.bloodPoolCurrent)
		local maxVal = db.bloodPoolMax
		
		textLeft:Hide()
		textRight:Hide()
		
		if displayMode == "NUMERIC" then
			local numericText = currentVal .. " / " .. maxVal
			textLeft:ClearAllPoints()
			textLeft:SetPoint("CENTER", bar, "CENTER", 0, 0)
			textLeft:SetText(numericText)
			textLeft:Show()
		elseif displayMode == "PERCENT" then
			local percent = (maxVal > 0) and math.floor((currentVal / maxVal) * 100) or 0
			local percentText = percent .. "%"
			textLeft:ClearAllPoints()
			textLeft:SetPoint("CENTER", bar, "CENTER", 0, 0)
			textLeft:SetText(percentText)
			textLeft:Show()
		elseif displayMode == "BOTH" then
			local percent = (maxVal > 0) and math.floor((currentVal / maxVal) * 100) or 0
			local percentText = percent .. "%"
			local numericText = currentVal 
			
			textLeft:ClearAllPoints()
			textRight:ClearAllPoints()
			textLeft:SetPoint("LEFT", bar, "LEFT", 1.25, 0)
			textRight:SetPoint("RIGHT", bar, "RIGHT", -0.5, 0)

			textLeft:SetText(percentText)
			textRight:SetText(numericText)
			textLeft:Show()
			textRight:Show()
		end
	end,
	
	CreateBloodLogFrame = function(self)
		if self.bloodLogFrame then return end

		local frame = CreateFrame("Frame", "PurityBloodLogFrame", UIParent)
        
        local db = Purity:GetDB()
        local width = (db and db.bloodLogDimensions and db.bloodLogDimensions.width) or 350
        local height = (db and db.bloodLogDimensions and db.bloodLogDimensions.height) or 150
        frame:SetSize(width, height)
		frame:SetResizable(true)

		frame:SetClampedToScreen(true)
		frame:SetMovable(true)
		frame:EnableMouse(true)
		frame:RegisterForDrag("LeftButton")
		frame:SetScript("OnDragStart", frame.StartMoving)
		frame:SetScript("OnDragStop", function(f)
			f:StopMovingOrSizing()
			local point, _, relativePoint, x, y = f:GetPoint()
			local db = Purity:GetDB()
			if not db.bloodLogPosition then db.bloodLogPosition = {} end
			db.bloodLogPosition = { point = point, relativePoint = relativePoint, x = x, y = y }
		end)

        frame:SetScript("OnSizeChanged", function(self, width, height)
            if self.scrollChild then
                self.scrollChild:SetWidth(width - 40) -- Account for padding and scrollbar
            end
            if self.logLines then
                for _, line in ipairs(self.logLines) do
                    line:SetWidth(width - 40)
                end
            end
        end)

		frame.bg = frame:CreateTexture(nil, "BACKGROUND")
		frame.bg:SetAllPoints(true)
        local fixedOpacity = 0.7 -- Set your desired fixed opacity here
		frame.bg:SetColorTexture(0, 0, 0, fixedOpacity)
		
		-- Create the scrollable area
		local scrollFrame = CreateFrame("ScrollFrame", "PurityBloodLogScrollFrame", frame, "UIPanelScrollFrameTemplate")
		scrollFrame:SetPoint("TOPLEFT", 5, -5)
		scrollFrame:SetPoint("BOTTOMRIGHT", -25, 5) -- Reverted to original padding

		-- Create the child frame that will hold the text lines and grow
		local scrollChild = CreateFrame("Frame")
		scrollChild:SetWidth(frame:GetWidth() - 40) -- Account for padding and scrollbar
		scrollFrame:SetScrollChild(scrollChild)
		
		self.bloodLogFrame = frame
		frame.scrollFrame = scrollFrame
		frame.scrollChild = scrollChild
		frame.logLines = {}
		frame.maxLogLines = 100 -- We'll keep a history of 100 lines

        -- Add Resize Handle
        local resizeHandle = CreateFrame("Button", "PurityBloodLogResizeButton", frame)
        resizeHandle:SetSize(16, 16) -- Back to original size
        resizeHandle:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 2, 2) -- Changed Anchor Point
        resizeHandle:SetFrameLevel(frame:GetFrameLevel() + 5)
        resizeHandle:SetFrameStrata("HIGH")
        -- Restore original textures
        resizeHandle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeHandle-Up")
        resizeHandle:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeHandle-Down")
        resizeHandle:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeHandle-Highlight")

        resizeHandle:RegisterForDrag("LeftButton")

        resizeHandle:SetScript("OnDragStart", function(self)
            frame:StartSizing("BOTTOMLEFT") -- Changed Sizing Corner
            if frame.scrollFrame then frame.scrollFrame:Hide() end
            frame:SetScript("OnDragStart", nil)
        end)

        resizeHandle:SetScript("OnDragStop", function(self)
            frame:StopMovingOrSizing()
            if frame.scrollFrame then frame.scrollFrame:Show() end
            frame:SetScript("OnDragStart", frame.StartMoving)

            local db = Purity:GetDB()
            if not db.bloodLogDimensions then db.bloodLogDimensions = {} end
            db.bloodLogDimensions.width = frame:GetWidth()
            db.bloodLogDimensions.height = frame:GetHeight()
        end)
        frame.resizeHandle = resizeHandle
        resizeHandle:Show()
		
		resizeHandle:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
            GameTooltip:SetText("Resize Blood Log")
            GameTooltip:AddLine("Click: Resize freely.")
            GameTooltip:Show()
        end)
        resizeHandle:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)

		if db.bloodLogPosition then
			frame:SetPoint(db.bloodLogPosition.point, UIParent, db.bloodLogPosition.relativePoint, db.bloodLogPosition.x, db.bloodLogPosition.y)
		else
			frame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 200)
		end
		frame:Hide()
	end,

	_AddNewLogMessage = function(self, message)
		if not self.bloodLogFrame or not self.bloodLogFrame:IsShown() then return end

		local frame = self.bloodLogFrame
		local scrollFrame = frame.scrollFrame
		local scrollChild = frame.scrollChild
		local logLines = frame.logLines

		local newLine = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		newLine:SetJustifyH("LEFT")
		newLine:SetWidth(scrollChild:GetWidth() - 10)
		newLine:SetText(message)
		
		local lastLine = logLines[#logLines]
		
		if lastLine then
			newLine:SetPoint("TOPLEFT", lastLine, "BOTTOMLEFT", 0, -2)
		else
			newLine:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 5, -5)
		end
		
		table.insert(logLines, newLine)
		
		if #logLines > frame.maxLogLines then
			local oldLine = table.remove(logLines, 1)
			oldLine:Hide()

			if logLines[1] then
				logLines[1]:ClearAllPoints()
				logLines[1]:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 5, -5)
			end
		end
		
		local totalHeight = 0
		for _, line in ipairs(logLines) do
			totalHeight = totalHeight + line:GetHeight() + 2
		end
		scrollChild:SetHeight(math.max(scrollFrame:GetHeight(), totalHeight))
		
		scrollFrame:UpdateScrollChildRect()
		
		local scrollBar = _G[scrollFrame:GetName() .. "ScrollBar"]
		if scrollBar then
			local _, maxValue = scrollBar:GetMinMaxValues()
			scrollBar:SetValue(maxValue)
		end
	end,
	
	LogBloodLoss = function(self, spellName, cost)
		local timestamp = date("|cffc0c0c0[%H:%M:%S]|r ")
		local spellText = "|cffffffff[" .. spellName .. "]|r"
		local costText = " costs |cffFF4D4D" .. math.floor(cost) .. "|r Blood."
		
		self:_AddNewLogMessage(timestamp .. spellText .. costText)
	end,

	LogDamageTaken = function(self, sourceName, spellName, amount)
		local timestamp = date("|cffc0c0c0[%H:%M:%S]|r ")
		local sourceText = "|cffff8080" .. (sourceName or "Unknown") .. "'s|r"
		local abilityText = " |cffffffff" .. ((spellName and spellName ~= -1) and spellName or "Melee") .. "|r"
		local damageText = " hits you for |cffFF4D4D" .. math.floor(amount) .. "|r Blood."

		self:_AddNewLogMessage(timestamp .. sourceText .. abilityText .. damageText)
	end,
	
	LogSanguineWeakness = function(self, healSourceName)
		local timestamp = date("|cffc0c0c0[%H:%M:%S]|r ")
		local effectText = "|cffff00ff[Sanguine Weakness]|r"
		local description = " applied for 15s from |cffffffff[" .. (healSourceName or "Unknown Heal") .. "]|r."

		self:_AddNewLogMessage(timestamp .. effectText .. description)
	end,
	
	ApplyBloodRegen = function(self, hps)
        local db = Purity:GetDB()
        if not (db and db.isOptedIn and db.activeChallengeID == self.id and (db.status == "Passing" or db.status == "Temporary Failure - Uptime")) then
            if self.bloodRegenTicker then self.bloodRegenTicker:Cancel(); self.bloodRegenTicker = nil; end
            return
        end

        local newBlood = db.bloodPoolCurrent + hps
        local cappedBlood = math.min(newBlood, UnitHealth("player"), db.bloodPoolMax)
        
        if cappedBlood > db.bloodPoolCurrent then
            db.bloodPoolCurrent = cappedBlood
            if self.UpdateBarText then self:UpdateBarText() end
        end
    end,

ManageBloodRegen = function(self)
        if not self.PurityScanTooltip then 
            self.PurityScanTooltip = CreateFrame("GameTooltip", "PurityScanTooltip", UIParent, "GameTooltipTemplate") 
        end

        local totalHPS = 0
        
        for i = 1, 40 do
            local buffName = UnitAura("player", i)
            
            if buffName then
                self.PurityScanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
                self.PurityScanTooltip:SetUnitAura("player", i)
                
                for j = 1, self.PurityScanTooltip:NumLines() do
                    local lineText = _G["PurityScanTooltipTextLeft"..j]:GetText()
                    if lineText then
                        local hps_found_on_line = 0

                        -- 1. Exact Match for Demon Skin ("restores Y Health per 5 sec")
                        -- Handles "Health" (Capital H) and "per"
                        local skinHP = lineText:match("restores (%d+) Health per 5 sec")
                        if skinHP then
                            hps_found_on_line = tonumber(skinHP) / 5
                        end

                        -- 2. Exact Match for Demon Armor ("restores P health every 5 sec")
                        -- Handles "health" (lowercase h) and "every"
                        if hps_found_on_line == 0 then
                            local armorHP = lineText:match("restores (%d+) health every 5 sec")
                            if armorHP then
                                hps_found_on_line = tonumber(armorHP) / 5
                            end
                        end

                        -- 3. Generic/Fallback matches (Potions, Trolls, other items)
                        -- Covers case-insensitivity and "sec" vs "secs" just in case
                        if hps_found_on_line == 0 then
                            local genericHP = lineText:match("[Rr]estores (%d+) [Hh]ealth every 5 secs?") or 
                                              lineText:match("[Rr]estores (%d+) [Hh]ealth per 5 secs?") or
                                              lineText:match("[Rr]egenerate (%d+) [Hh]ealth every 5 secs?")
                            if genericHP then
                                hps_found_on_line = tonumber(genericHP) / 5
                            end
                        end

                        -- 4. "Restores X health per second" (Fast HoTs/Items)
                        if hps_found_on_line == 0 then
                            local hps = lineText:match("[Rr]estores (%d+) [Hh]ealth per second")
                            if hps then
                                hps_found_on_line = tonumber(hps)
                            end
                        end

                        -- 5. Percentage based regen (Evocation / Spirit Tap)
                        if hps_found_on_line == 0 then
                            local percent, duration = lineText:match("[Rr]egenerates (%d+)%% of your total [Hh]ealth over (%d+) secs?")
                            if percent and duration and tonumber(duration) > 0 then
                                local totalHealth = UnitHealthMax("player")
                                local regenAmount = totalHealth * (tonumber(percent) / 100)
                                hps_found_on_line = regenAmount / tonumber(duration)
                            end
                        end
                        
                        -- 6. "Regenerates X% of your Health and Mana per second"
                        if hps_found_on_line == 0 then
                            local percent = lineText:match("[Rr]egenerates (%d+)%% of your [Hh]ealth and [Mm]ana per second")
                            if percent then
                                local totalHealth = UnitHealthMax("player")
                                hps_found_on_line = totalHealth * (tonumber(percent) / 100)
                            end
                        end

                        if hps_found_on_line > 0 then
                            totalHPS = totalHPS + hps_found_on_line
                            break 
                        end
                    end
                end
                self.PurityScanTooltip:Hide()
            end
        end

        -- Restart the ticker with the new total HPS
        if self.bloodRegenTicker then self.bloodRegenTicker:Cancel(); self.bloodRegenTicker = nil; end

        if totalHPS > 0 then
            -- Apply the calculated health-per-second every 1 second
            self.bloodRegenTicker = C_Timer.NewTicker(1, function() self:ApplyBloodRegen(totalHPS) end)
        end
    end,
	
	_GetBloodCostInternal = function(self, spellId)
		local db = Purity:GetDB()
		if not db then return 0 end

		local powerCostTable = GetSpellPowerCost(spellId)
		local originalPowerCost = (powerCostTable and #powerCostTable > 0) and powerCostTable[1].cost or 0
		
		if originalPowerCost > 0 then
			local powerType = select(1, UnitPowerType("player"))
			local _, spirit = UnitStat("player", 5)
			local level = UnitLevel("player")
			local bloodPoolMax = db.bloodPoolMax or UnitHealthMax("player")

			local currentSpiritFactor = 12.0
			local oathbreakerRank = self:GetOathbreakerRank()
			
			if oathbreakerRank > 0 then
				currentSpiritFactor = 12.0 + (oathbreakerRank * 2.4) 
			end

			local baseDivisor = (powerType == 0 and 200) or (powerType == 3 and 500) or 100
			local scaledDivisor = baseDivisor + (level * 20)
			local effectiveDivisor = scaledDivisor + (spirit * currentSpiritFactor)
			
			if effectiveDivisor > 0 then
				local healthCost = bloodPoolMax * (originalPowerCost / effectiveDivisor)
				return math.max(1, healthCost)
			end
		end
		return 0
	end,
	
	GetBloodCostForSpell = function(self, spellId)
        local decimalCost = self:_GetBloodCostInternal(spellId)
		return math.floor(decimalCost)
	end,
	
    RefreshGroupFrames = function(self)
        local units = {"target", "targettarget", "party1", "party2", "party3", "party4"}
        for _, unit in ipairs(units) do
            local healthBar
            local textRegions = {} 
            
            if unit == "target" then
                healthBar = TargetFrameHealthBar
                -- Use the exact TargetFrame text hierarchy from Glass Heart
                if TargetFrameTextureFrame then
                    if TargetFrameTextureFrame.HealthBarText then table.insert(textRegions, TargetFrameTextureFrame.HealthBarText) end
                    if TargetFrameTextureFrame.HealthBarTextLeft then table.insert(textRegions, TargetFrameTextureFrame.HealthBarTextLeft) end
                    if TargetFrameTextureFrame.HealthBarTextRight then table.insert(textRegions, TargetFrameTextureFrame.HealthBarTextRight) end
                end
                -- Fallback for older naming/Private Servers
                if #textRegions == 0 then
                    if _G["TargetFrameTextureFrameHealthBarText"] then table.insert(textRegions, _G["TargetFrameTextureFrameHealthBarText"]) end
                    if _G["TargetFrameTextureFrameHealthBarTextLeft"] then table.insert(textRegions, _G["TargetFrameTextureFrameHealthBarTextLeft"]) end
                    if _G["TargetFrameTextureFrameHealthBarTextRight"] then table.insert(textRegions, _G["TargetFrameTextureFrameHealthBarTextRight"]) end
                end
            elseif unit == "targettarget" then
                healthBar = _G["TargetFrameToTHealthBar"]
                if _G["TargetFrameToTHealthBarText"] then table.insert(textRegions, _G["TargetFrameToTHealthBarText"]) end
            else
                local unitNum = string.sub(unit, 6)
                healthBar = _G["PartyMemberFrame" .. unitNum .. "HealthBar"]
                -- Support Party text variations
                local tMain = _G["PartyMemberFrame" .. unitNum .. "HealthBarText"]
                local tLeft = _G["PartyMemberFrame" .. unitNum .. "HealthBarTextLeft"]
                local tRight = _G["PartyMemberFrame" .. unitNum .. "HealthBarTextRight"]
                if tMain then table.insert(textRegions, tMain) end
                if tLeft then table.insert(textRegions, tLeft) end
                if tRight then table.insert(textRegions, tRight) end
            end
            
            local bar = self.partyBloodBars[unit]
            if UnitExists(unit) and healthBar then
                local isBloodMage = false
                
                if UnitIsUnit(unit, "player") then
                    local db = Purity:GetDB()
                    if db and db.activeChallengeID == self.id and (db.status == "Passing" or db.status == "Temporary Failure - Uptime") then
                        isBloodMage = true
                    end
                end

                if not isBloodMage then
                    local name = UnitName(unit)
                    for key, data in pairs(Purity.roster) do
                        local rosterPlayerName = key:match("([^-]+)")
                        if rosterPlayerName and rosterPlayerName == name and data.challenge == self.challengeName and (data.status == "Passing" or data.status == "Temporary Failure - Uptime") then
                            isBloodMage = true
                            break
                        end
                    end
                end
                
                if isBloodMage then
                    if not bar then
                        -- Create as a SIBLING at the SAME frame level
                        bar = CreateFrame("StatusBar", "PurityGroupBloodBar"..unit, healthBar:GetParent())
                        bar:SetAllPoints(healthBar)
                        bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
                        bar:SetStatusBarColor(0.8, 0.1, 0.1) -- Blood Red
                        bar:SetFrameStrata(healthBar:GetFrameStrata())
                        bar:SetFrameLevel(healthBar:GetFrameLevel()) -- Match Glass Heart
                        
                        -- Removed Black Background entirely
                        
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
                        self.partyBloodBars[unit] = bar
                    end
                    
                    healthBar:SetAlpha(0)
                    healthBar:SetStatusBarTexture("") 
                    for _, region in ipairs(textRegions) do region:SetAlpha(0); region:Hide() end
                    bar:Show()
                else
                    healthBar:SetAlpha(1)
                    healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
                    for _, region in ipairs(textRegions) do region:SetAlpha(1); region:Show() end
                    if bar then bar:Hide() end
                end
            else
                if healthBar then healthBar:SetAlpha(1); healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar") end
                for _, region in ipairs(textRegions) do region:SetAlpha(1); region:Show() end
                if bar then bar:Hide() end
            end
        end
    end,

    UpdateGroupFrameValues = function(self)
        if GetNumGroupMembers() == 0 and not UnitExists("target") then return end
        
        local units = {"target", "targettarget", "party1", "party2", "party3", "party4"}
        for _, unit in ipairs(units) do
            local bar = self.partyBloodBars[unit]
            if bar and bar:IsShown() then
                
                -- Force suppression of default UI visuals (Glass Heart Style)
                if bar.originalHealthBar then
                    bar.originalHealthBar:SetAlpha(0)
                    bar.originalHealthBar:SetStatusBarTexture("")
                end
                if bar.originalTextRegions then
                    for _, region in ipairs(bar.originalTextRegions) do 
                        region:SetAlpha(0) 
                        region:Hide()
                    end
                end

                local current, max
                if UnitIsUnit(unit, "player") then
                    local db = Purity:GetDB()
                    if db and db.bloodPoolMax and db.bloodPoolCurrent then
                        current = db.bloodPoolCurrent
                        max = db.bloodPoolMax
                    end
                else
                    local name = UnitName(unit)
                    for key, data in pairs(Purity.roster) do
                        local rosterPlayerName = key:match("([^-]+)")
                        if rosterPlayerName and rosterPlayerName == name and data.challenge == self.challengeName then
                            current = data.bloodPoolCurrent
                            max = data.bloodPoolMax
                            break
                        end
                    end
                end

                if current and max then
                    bar:SetMinMaxValues(0, max)
                    bar:SetValue(current)
                    
                    if bar.TextFrame then
                        local mode = GetCVar("statusTextDisplay") or "NUMERIC"
                        bar.TextCenter:SetText(""); bar.TextLeft:SetText(""); bar.TextRight:SetText("")
                        
                        if mode == "NUMERIC" then
                            bar.TextCenter:SetText(math.floor(current) .. " / " .. math.floor(max))
                        elseif mode == "PERCENT" then
                            bar.TextCenter:SetText(math.floor((current / max) * 100) .. "%")
                        elseif mode == "BOTH" then
                            bar.TextLeft:SetText(math.floor((current / max) * 100) .. "%")
                            bar.TextRight:SetText(math.floor(current))
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
        self.groupFrameManager:RegisterEvent("UNIT_TARGET") -- NEW: Detects ToT changes
        self.groupFrameManager:RegisterEvent("PLAYER_ENTERING_WORLD")
        self.groupFrameManager:SetScript("OnEvent", function() module:RefreshGroupFrames() end)
        self.groupFrameManager:SetScript("OnUpdate", function() module:UpdateGroupFrameValues() end)
        local groupFrameRestorer = CreateFrame("Frame")
        groupFrameRestorer:RegisterEvent("GROUP_LEFT")
        groupFrameRestorer:SetScript("OnEvent", function()
            for i = 1, 4 do
                local healthBar = _G["PartyMemberFrame" .. i .. "HealthBar"]
                if healthBar then healthBar:Show() end
                if module.partyBloodBars["party"..i] then module.partyBloodBars["party"..i]:Hide() end
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
                
                -- Ensure we have a valid nameplate with a Unit ID
                if nameplate and nameplate:IsVisible() and nameplate.unit and healthBar then
                    local unit = nameplate.unit
                    
                    if UnitExists(unit) and UnitIsPlayer(unit) then
                        local name = UnitName(unit)
                        local isBloodMage = false
                        local currentBlood, maxBlood
                        
                        -- 1. CHECK SELF (Use Local DB)
                        if UnitIsUnit(unit, "player") then
                            local db = Purity:GetDB()
                            if db and db.activeChallengeID == self.id and (db.status == "Passing" or db.status == "Temporary Failure - Uptime") then
                                isBloodMage = true
                                currentBlood = db.bloodPoolCurrent
                                maxBlood = db.bloodPoolMax
                            end
                        else
                        -- 2. CHECK ROSTER (Use robust lookup)
                            local shortName = name:match("([^-]+)")
                            -- Try exact name, then ShortName, then Name-Realm
                            local data = Purity.roster and (Purity.roster[name] or Purity.roster[shortName] or Purity.roster[name .. "-" .. GetRealmName()])
                            
                            if data and data.challenge == self.challengeName and (data.status == "Passing" or data.status == "Temporary Failure - Uptime") then
                                isBloodMage = true
                                currentBlood = data.bloodPoolCurrent
                                maxBlood = data.bloodPoolMax
                            end
                        end
                        
                        local bloodBar = nameplate.purityBloodBar
                        
                        if isBloodMage then
                            -- Create the Red Blood Bar if it doesn't exist
                            if not bloodBar then
                                bloodBar = CreateFrame("StatusBar", nil, nameplate)
                                bloodBar:SetAllPoints(healthBar)
                                bloodBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
                                bloodBar:SetStatusBarColor(0.8, 0.1, 0.1) -- Blood Red
                                bloodBar:SetFrameLevel(healthBar:GetFrameLevel() + 1)
                                
                                local bg = bloodBar:CreateTexture(nil, "BACKGROUND")
                                bg:SetAllPoints(true)
                                bg:SetColorTexture(0, 0, 0, 1)
                                
                                nameplate.purityBloodBar = bloodBar
                            end
                            
                            -- Hide standard green/class bar, Show Red Bar
                            healthBar:Hide()
                            bloodBar:Show()
                            
                            if maxBlood and currentBlood then
                                bloodBar:SetMinMaxValues(0, maxBlood)
                                bloodBar:SetValue(currentBlood)
                            end
                        else
                            -- Revert to standard behavior
                            healthBar:Show()
                            if bloodBar then bloodBar:Hide() end
                        end
                    end
                end
            end
        end)
    end,
	
    StartBroadcasting = function(self)
        if self.broadcasterFrame then return end
        self.broadcasterFrame = CreateFrame("Frame")
        local lastUpdate = 0
        self.broadcasterFrame:SetScript("OnUpdate", function(frame, elapsed)
            lastUpdate = lastUpdate + elapsed
            if lastUpdate > 0.1 and GetNumGroupMembers() > 0 then
                lastUpdate = 0
                local db = Purity:GetDB()
                if db and db.activeChallengeID == self.id then
                    local data = { current = db.bloodPoolCurrent, max = db.bloodPoolMax }
                    C_ChatInfo.SendAddonMessage(Purity.ADDON_PREFIX, "BLOODPOOL_UPDATE:" .. Purity:Serialize(data), "PARTY")
                end
            end
        end)
    end,

	InitializeOnPlayerEnterWorld = function(self)
        self.sanguineWeaknessActive = false
        self.sanguineWeaknessExpires = 0
		self.wasBelowThreshold = false
		self.lastOathbreakerRank = self:GetOathbreakerRank()
		self:SetupTalentTooltip()
		self:SetupTalentIconHook()
		self:CreateOathBrokenBanner()
        
        local db = Purity:GetDB()
        if db.isOptedIn and db.activeChallengeID == self.id then
            if not db.bloodPoolMax then
                db.bloodPoolMax = UnitHealthMax("player")
                db.bloodPoolCurrent = UnitHealth("player")
            end
        end

        if not self.visibilityManager then
            local manager = CreateFrame("Frame")
            local module = self

            manager:SetScript("OnUpdate", function(frame, sinceLastUpdate)
                module:_UpdateDefaultHealthBarVisibility()
            end)
            self.visibilityManager = manager
        end

        if not self.bloodBarFrame then
            self.bloodBarFrame = CreateFrame("StatusBar", "PurityBloodMageBar", UIParent) 
            self.bloodBarFrame:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
            self.bloodBarFrame:GetStatusBarTexture():SetHorizTile(true)
            self.bloodBarFrame:SetStatusBarColor(0.8, 0.1, 0.1, 1)
            local mask = self.bloodBarFrame:CreateMaskTexture(); mask:SetTexture("Interface\\ChatFrame\\ChatFrameBackground"); mask:SetBlendMode("BLEND"); mask:SetAllPoints(self.bloodBarFrame)
            self.bloodBarFrame:Hide()
        end
        
        if not self.textContainer then
            self.textContainer = CreateFrame("Frame", "PurityBloodMageTextContainer", UIParent)
            self.textContainer:SetFrameStrata("MEDIUM")
            self.textContainer:SetAllPoints(self.bloodBarFrame)
            
            self.textLeft = self.textContainer:CreateFontString("PurityBloodMageBarTextLeft", "OVERLAY", "GameFontNormal")
            self.textLeft:SetFont("Fonts\\ARIALN.TTF", 14, "OUTLINE")
            self.textLeft:SetTextColor(1, 1, 1)
            self.textLeft:SetPoint("LEFT", self.bloodBarFrame, "LEFT", 5, 0)

            self.textRight = self.textContainer:CreateFontString("PurityBloodMageBarTextRight", "OVERLAY", "GameFontNormal")
            self.textRight:SetFont("Fonts\\ARIALN.TTF", 14, "OUTLINE")
            self.textRight:SetTextColor(1, 1, 1)
            self.textRight:SetPoint("RIGHT", self.bloodBarFrame, "RIGHT", -5, 0)
        end
        
        self:ApplyBarMode(db.bloodBarIsSeparate)
        
        if not self.debuffFrame then
            self.debuffFrame = CreateFrame("Button", "PuritySanguineWeaknessDebuff", UIParent)
            self.debuffFrame:SetSize(30, 30)
            self.debuffFrame:SetFrameStrata("MEDIUM")
            local icon = self.debuffFrame:CreateTexture(nil, "BACKGROUND"); icon:SetAllPoints(true); icon:SetTexture("Interface\\AddOns\\Purity\\Media\\SanguineWeakness.tga")
            local border = self.debuffFrame:CreateTexture(nil, "OVERLAY")
            border:SetAllPoints(true)
            border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
            border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
            border:SetVertexColor(0.75, 0, 0)
			local countText = self.debuffFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
            countText:SetPoint("CENTER", self.debuffFrame, "BOTTOM", 0, -6)
            countText:SetTextColor(1, 1, 1, 1)
            countText:SetJustifyH("CENTER")
            self.debuffFrame.timerText = countText
			self.debuffFrame:SetScript("OnEnter", function(frame)
                GameTooltip:SetOwner(frame, "ANCHOR_RIGHT"); GameTooltip:SetText("|cffffd700Sanguine Weakness|r")
                GameTooltip:AddLine("Your pact is weakened after healing.", 1.0, 1.0, 1.0, true); GameTooltip:AddLine("All Blood Pool costs are doubled.", 1.0, 1.0, 1.0, true)
				local remaining = self.sanguineWeaknessExpires - GetTime()
                if remaining > 0 then
                    GameTooltip:AddLine(string.format("|cffffd700%d sec remaining|r", remaining), 1.0, 1.0, 1.0, true)
                end
                GameTooltip:Show()
            end)
            self.debuffFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)
            local module = self 
            local module = self
            self.debuffFrame:SetScript("OnUpdate", function(frame, elapsed)
                local now = GetTime()
                local remaining = module.sanguineWeaknessExpires - now

                if remaining <= 0 then
                    frame:Hide(); module.sanguineWeaknessActive = false
                    if frame.timerText then frame.timerText:Hide() end
                    if module.screenGlowFrame then module.screenGlowFrame:Hide() end
                    if GameTooltip:IsShown() and GameTooltip:GetOwner() == frame then
                        GameTooltip:Hide()
                    end
                    return
                end

                -- [START OF POSITIONING LOGIC]
                frame:ClearAllPoints() -- Necessary to prevent "Too Many Anchors" error in OnUpdate
                
                -- Check for Modern Retail/Anniversary UI Structure
                if DebuffFrame and DebuffFrame.AuraContainer then
                    -- === MODERN / EDIT MODE LOGIC ===
                    local anchored = false
                    local minLeft = 99999
                    local targetBtn = nil
                    
                    -- Scan the AuraContainer for the left-most visible debuff (End of the row)
                    local children = { DebuffFrame.AuraContainer:GetChildren() }
                    for _, child in ipairs(children) do
                        if child:IsShown() then
                            local left = child:GetLeft()
                            if left and left < minLeft then
                                minLeft = left
                                targetBtn = child
                            end
                        end
                    end

                    if targetBtn then
                        -- Found a debuff: Snap to its left
                        frame:SetPoint("TOPRIGHT", targetBtn, "TOPLEFT", -5, 0)
                        anchored = true
                    end
                    
                    -- Fallback: If no debuffs found, anchor to the main container start
                    if not anchored then
                         frame:SetPoint("TOPRIGHT", DebuffFrame, "TOPRIGHT", 0, 0)
                    end

                else
                    -- === CLASSIC ERA LOGIC (Exact Original Behavior) ===
                    local numDebuffs = 0
                    for i = 1, 40 do 
                        if select(1, UnitDebuff("player", i)) then 
                            numDebuffs = numDebuffs + 1 
                        else 
                            break 
                        end 
                    end
                    
                    if numDebuffs == 0 then 
                        frame:SetPoint("TOPRIGHT", BuffFrame, "TOPRIGHT", -4, -99)
                    else 
                        local lastDebuff = _G["DebuffButton" .. numDebuffs]
                        if lastDebuff then 
                            frame:SetPoint("TOPRIGHT", lastDebuff, "TOPLEFT", -4, 1) 
                        end 
                    end
                end
                -- [END OF POSITIONING LOGIC]

                -- [Animation/Timer Logic]
                if remaining <= 30 then
                    local pulse = math.cos(now * 4.1) 
                    local alpha = 0.7 + (0.3 * pulse) 
                    frame:SetAlpha(alpha)
                else
                    frame:SetAlpha(1.0)
                end

                if frame.timerText then
                    local ceilRemaining = math.ceil(remaining)
                    local minutes = math.floor(ceilRemaining / 60)
                    local seconds = ceilRemaining % 60
                    local timerString

                    if minutes >= 1 then
                        timerString = string.format("|cffffd700%d|r m", minutes)
                    else
                        timerString = string.format("|cffffffff%d|r s", seconds)
                    end
                    frame.timerText:SetText(timerString)
                    frame.timerText:Show()
                end

                if GameTooltip:IsShown() and GameTooltip:GetOwner() == frame then
                    local numLines = GameTooltip:NumLines()
                    if numLines >= 4 then
                        local line4 = _G["GameTooltipTextLeft4"]
                        if line4 then
                            line4:SetText(string.format("|cffffd700%d sec remaining|r", math.ceil(remaining)))
                        end
                    end
                end
            end)
            self.debuffFrame:Hide()
        end

        if not self.regenFrame then
            self.regenFrame = CreateFrame("Frame")
            self.regenFrame.lastTick = 0
            local module = self
            self.regenFrame:SetScript("OnUpdate", function(frame, elapsed)
                local db = Purity:GetDB()
                if (db and db.isOptedIn and (db.status == "Passing" or db.status == "Temporary Failure - Uptime")) then
                    local currentMaxHealth = UnitHealthMax("player")
                    if currentMaxHealth <= 1 then
                        return 
                    end
                    if module.bloodBarFrame then
                        db.bloodPoolMax = UnitHealthMax("player")
                        db.bloodPoolCurrent = math.min(db.bloodPoolCurrent, db.bloodPoolMax)

                        if not module.bloodBarFrame:IsShown() then 
                            module.bloodBarFrame:Show()
                            if module.textContainer then module.textContainer:Show() end
                        end
                        module.bloodBarFrame:SetMinMaxValues(0, db.bloodPoolMax)
                        module.bloodBarFrame:SetValue(db.bloodPoolCurrent)
                        module:UpdateBarText()
                    end
                    if not UnitAffectingCombat("player") then
                        frame.lastTick = frame.lastTick + elapsed
                        if frame.lastTick > 2 then
                            frame.lastTick = 0
                            if db.bloodPoolCurrent < db.bloodPoolMax then
                                local spirit = select(2, UnitStat("player", 5))
                                local regenAmount = (spirit * 0.25) + 3
                                db.bloodPoolCurrent = math.min(db.bloodPoolMax, db.bloodPoolCurrent + regenAmount)
                            end
                        end
                    end
                else
                    -- FIX: Cleanup if we fail/reset while this loop is running
                    if module.bloodBarFrame then module.bloodBarFrame:Hide() end
                    if module.textContainer then module.textContainer:Hide() end
                end
            end)
        end
        
        if not self.screenGlowFrame then
            self.screenGlowFrame = CreateFrame("Frame", "PurityBloodMageGlow", UIParent)
            self.screenGlowFrame:SetAllPoints(UIParent)
            self.screenGlowFrame:SetFrameStrata("BACKGROUND")
            self.screenGlowFrame:EnableMouse(false)
            self.screenGlowFrame:Hide()

            local texFile = "Interface\\FullScreenTextures\\LowHealth"

            -- Create 4 layers for a deep, thick crimson (matching Astrolabe's stacking)
            self.natureLayers = {} -- Keeping the name convention from your Druid module for logic consistency
            for i = 1, 10 do
                local t = self.screenGlowFrame:CreateTexture(nil, "ARTWORK")
                t:SetAllPoints(true)
                t:SetTexture(texFile)
                t:SetDesaturated(true)
                t:SetBlendMode("ADD") 
                t:SetVertexColor(1, 0, 0) -- Dark Red
                t:SetAlpha(0)
                table.insert(self.natureLayers, t)
            end

            self.screenGlowFrame:SetScript("OnUpdate", function(f, elapsed)
				local now = GetTime()
				local remaining = self.sanguineWeaknessExpires - now

				if remaining <= 0 then
					f:Hide()
					return
				end

				local progress = math.max(0, remaining / 15)
				local numLayers = #self.natureLayers -- Dynamically get the count

				for i, tex in ipairs(self.natureLayers) do
					-- Divide progress by the ACTUAL number of layers you created
					local layerThreshold = (i - 1) / numLayers 
					local layerAlpha = math.max(0, math.min(1, (progress - layerThreshold) * numLayers))
					
					-- Apply the alpha to each physical layer
					tex:SetAlpha(layerAlpha * 0.8)
				end
			end)
        end

        self:StartBroadcasting()
        self:InitializeGroupFrames()

        if not self.characterFrameHooked then
            local module = self 
            
            hooksecurefunc(CharacterFrame, "Show", function()
                local db = Purity:GetDB()
                if not (db and db.isOptedIn and db.activeChallengeID == module.id) then return end
                
                module.forceNumericDisplay = true
                module:UpdateBarText()
            end)
            
            hooksecurefunc(CharacterFrame, "Hide", function()
                local db = Purity:GetDB()
                if not (db and db.isOptedIn and db.activeChallengeID == module.id) then return end
                
                module.forceNumericDisplay = false
                module:UpdateBarText()
            end)
            
            self.characterFrameHooked = true
        end
		self:CreateBloodLogFrame()
		local db = Purity:GetDB()
        if db and db.bloodLogVisible and self.bloodLogFrame then
            self.bloodLogFrame:Show()
        end
        if not self.playerFrameTooltipHooked then
            local originalOnEnter = PlayerFrameHealthBar:GetScript("OnEnter")
            local originalOnLeave = PlayerFrameHealthBar:GetScript("OnLeave")

            PlayerFrameHealthBar:SetScript("OnEnter", function(frame)
                local db = Purity:GetDB()
                local challengeActive = db and db.isOptedIn and db.activeChallengeID == self.id and (db.status == "Passing" or db.status == "Temporary Failure - Uptime")
                
                if challengeActive and not db.bloodBarIsSeparate then
                    self:_ShowBloodPoolTooltip(frame)
                elseif originalOnEnter then
                    originalOnEnter(frame)
                end
            end)

            PlayerFrameHealthBar:SetScript("OnLeave", function(frame)
                GameTooltip:Hide()
                if originalOnLeave then
                    originalOnLeave(frame)
                end
            end)

            self.bloodBarFrame:SetScript("OnEnter", function(frame)
                local db = Purity:GetDB()
                local challengeActive = db and db.isOptedIn and db.activeChallengeID == self.id and (db.status == "Passing" or db.status == "Temporary Failure - Uptime")

                if challengeActive and db.bloodBarIsSeparate then
                    self:_ShowBloodPoolTooltip(frame)
                end
            end)

            self.bloodBarFrame:SetScript("OnLeave", function(frame)
                GameTooltip:Hide()
            end)
            self.playerFrameTooltipHooked = true
        end
        -- [[ STAT TOOLTIP HOOKS (Cross-Version: Vanilla & TBC & Era 1.15) ]]
        if not self.statTooltipHooked then
            local module = self
            
            -- Logic to replace the Spirit Tooltip
            local function ReplaceSpiritInfo(frame)
                local db = Purity:GetDB()
                if db and db.isOptedIn and db.activeChallengeID == module.id then
                    local level = UnitLevel("player")
                    local _, spirit = UnitStat("player", 5)
                    local powerType = UnitPowerType("player")
                    
					local rank = module:GetOathbreakerRank()
					local spiritFactor = 12.0 + (rank * 2.4)

                    local baseDivisor = (powerType == 0 and 200) or (powerType == 3 and 500) or 100
                    local scaledDivisor = baseDivisor + (level * 20) 
                    local totalDivisor = scaledDivisor + (spirit * spiritFactor)

                    if totalDivisor > 0 then
                        local reduction = (1 - (scaledDivisor / totalDivisor)) * 100
                        GameTooltip:ClearLines()
                        GameTooltip:AddLine("Spirit", 1, 1, 1)
                        GameTooltip:AddLine(string.format("Increases blood and mana regeneration rates. Reduces Blood costs by %.1f%%.", reduction), 1, 0.82, 0, true)
                        GameTooltip:Show()
                    end
                end
            end

            -- Logic to replace the Stamina Tooltip
            local function ReplaceStaminaInfo(frame)
                local db = Purity:GetDB()
                if db and db.isOptedIn and db.activeChallengeID == module.id then
                    GameTooltip:ClearLines()
                    GameTooltip:AddLine("Stamina", 1, 1, 1)
                    GameTooltip:AddLine("Increases blood points.", 1, 0.82, 0, true)
                    GameTooltip:Show()
                end
            end

            -- Apply the hooks based on the user's game version
            if _G["PlayerStatFrameLeft5"] then -- TBC Classic
                _G["PlayerStatFrameLeft5"]:HookScript("OnEnter", ReplaceSpiritInfo)
                _G["PlayerStatFrameLeft3"]:HookScript("OnEnter", ReplaceStaminaInfo)
            
            elseif _G["CharacterStatFrame5"] then -- Classic Era 1.15.x
                _G["CharacterStatFrame5"]:HookScript("OnEnter", ReplaceSpiritInfo)
                _G["CharacterStatFrame3"]:HookScript("OnEnter", ReplaceStaminaInfo)

            else -- Fallback Global Hook (Old Vanilla / Private Servers)
                hooksecurefunc("PaperDollStatTooltip", function(unit, stat)
                    if unit == "player" then
                        if stat == 5 then -- Spirit
                            ReplaceSpiritInfo()
                        elseif stat == 3 then -- Stamina
                            ReplaceStaminaInfo()
                        end
                    end
                end)
            end
            self.statTooltipHooked = true
        end
    end,
    
    IsSpellForbidden = function(self, spellId) return false end,
    IsTalentForbidden = function(self, tabIndex) return false end,
    IsItemForbidden = function(self, itemLink) return false end,
    isWeaponAllowed = function(self, itemLink) return true end,
    IsUnitForbidden = function(self, unit) return false end,

EventHandler = function(self, event, ...)
        local db = Purity:GetDB()
        -- If not opted in or not passing, cleanup everything and return
        if not (db and db.isOptedIn and (db.status == "Passing" or db.status == "Temporary Failure - Uptime")) then
            if self.bloodBarFrame then self.bloodBarFrame:Hide() end
            if self.textContainer then self.textContainer:Hide() end -- FIX: Hide the numbers
            if self.regenFrame then self.regenFrame:Hide() end
            return
        end
	
	local function spendBlood(amount, sourceName)
        local finalAmount = amount
        if self.sanguineWeaknessActive then 
            finalAmount = amount * 2 
        end
            
        self:LogBloodLoss(sourceName, finalAmount)

        db.bloodPoolCurrent = db.bloodPoolCurrent - finalAmount
        if db.bloodPoolCurrent <= 0 then
            Purity:Violation("Your life force has been expended by the bargain.")
        end
    end

    if event == "PLAYER_LEVEL_UP" then
        local newMaxBlood = UnitHealthMax("player")
        db.bloodPoolMax = newMaxBlood
        db.bloodPoolCurrent = newMaxBlood
    end

	if self.bloodBarFrame then
		if not db.bloodPoolMax or db.bloodPoolMax == 0 then db.bloodPoolMax = UnitHealthMax("player") end
        db.bloodPoolCurrent = math.min(db.bloodPoolCurrent, db.bloodPoolMax)

		self.bloodBarFrame:SetMinMaxValues(0, db.bloodPoolMax)
		self.bloodBarFrame:SetValue(db.bloodPoolCurrent)
		self:UpdateBarText()
	end

	--[[if event == "UNIT_SPELLCAST_CHANNEL_START" then
        local unitTarget, castGUID, spellId = ...
        if unitTarget == "player" and spellId then
			local spellName = GetSpellInfo(spellId)
            if spellId and not self.healingSpells[spellName] then
                local healthCost = self:_GetBloodCostInternal(spellId)
                if healthCost > 0 then
                    spendBlood(healthCost, spellName)
                end
            end
        end
	end--]]

        if event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_ENTER_COMBAT" then
            if self.regenFrame then self.regenFrame:Hide() end
        elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_LEAVE_COMBAT" then
            if self.regenFrame then self.regenFrame:Show() end
        end

        if self.sanguineWeaknessActive and GetTime() > self.sanguineWeaknessExpires then
            self.sanguineWeaknessActive = false
            if self.debuffFrame then self.debuffFrame:Hide() end
        end

        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, subEvent, _, sourceGUID, _, sourceFlags, _, destGUID, _, _, _, spellId, spellName = CombatLogGetCurrentEventInfo()
            local playerGUID = UnitGUID("player")

			if subEvent == "SPELL_CAST_SUCCESS" and sourceGUID == playerGUID then
                if not self.healingSpells[spellName] then
                    local healthCost = self:_GetBloodCostInternal(spellId)
                    if healthCost > 0 then
						spendBlood(healthCost, spellName)
                    end
                end
			elseif string.find(subEvent, "_DAMAGE") then
                local sourceName = select(5, CombatLogGetCurrentEventInfo())
                local spellName = select(13, CombatLogGetCurrentEventInfo())
                local amount = (subEvent == "SWING_DAMAGE" or subEvent == "RANGE_DAMAGE") and select(12, CombatLogGetCurrentEventInfo()) or select(15, CombatLogGetCurrentEventInfo())
                
                if amount and amount > 0 then
                    if destGUID == playerGUID and sourceGUID ~= playerGUID then
                        self:LogDamageTaken(sourceName, spellName, amount)

                        db.bloodPoolCurrent = db.bloodPoolCurrent - amount
                        if db.bloodPoolCurrent <= 0 then Purity:Violation("Your life force has been depleted by your enemies.") end
                    elseif sourceGUID == playerGUID then
						if subEvent == "SWING_DAMAGE" then
                            local targetCPS = 0.005
                            local attackCostPercent = 0.01

                            local mainSpeed, offSpeed = UnitAttackSpeed("player")
                            if not mainSpeed or mainSpeed == 0 then mainSpeed = 1.9 end

                            if offSpeed and offSpeed > 0 then
                                local mainHitCostPercent = mainSpeed * targetCPS
                                local offHitCostPercent = (offSpeed * targetCPS) / 2
                                attackCostPercent = (mainHitCostPercent + offHitCostPercent) / 2
                            else
                                attackCostPercent = mainSpeed * targetCPS
                            end
                            
                            local attackCost = math.max(1, db.bloodPoolMax * attackCostPercent)                            
                            local rank = self:GetOathbreakerRank()
                            if rank > 0 then
                                local multiplier = 1.0 - (rank * 0.05)
                                attackCost = math.max(1, attackCost * multiplier)
                            end
                            spendBlood(attackCost, "Melee Swing")

                        elseif subEvent == "RANGE_DAMAGE" then
                            local targetCPS = 0.005
                            
                            local rangedSpeed = UnitRangedDamage("player")
                            if not rangedSpeed or rangedSpeed == 0 then rangedSpeed = 2.0 end
                            local attackCostPercent = rangedSpeed * targetCPS
                            
                            local attackType = "Auto Shot"
                            local rangedLink = GetInventoryItemLink("player", INVSLOT_RANGED)
                            if rangedLink then
                                 local _, _, _, _, _, _, itemSubType = GetItemInfo(rangedLink)
                                 if itemSubType and itemSubType == "Wand" then
                                    attackType = "Wand Bolt"
                                 end
                            end
                            
                            local attackCost = math.max(1, db.bloodPoolMax * attackCostPercent)
                            spendBlood(attackCost, attackType)
						end
                    end
                end
			elseif string.find(subEvent, "_HEAL") and destGUID == playerGUID then
                local healAmount = select(15, CombatLogGetCurrentEventInfo())
                local sourceGUID = select(4, CombatLogGetCurrentEventInfo())
                local playerGUID = UnitGUID("player")

                if healAmount and healAmount > 0 then
                    -- 1. ALWAYS ADD BLOOD (Regardless of who healed you)
                    db.bloodPoolCurrent = math.min(db.bloodPoolMax, db.bloodPoolCurrent + healAmount)
                    
                    -- 2. APPLY PENALTY ONLY IF YOU HEALED YOURSELF
                    if sourceGUID == playerGUID then
                        -- Check if the specific spell is exempt (like Demon Armor or Food)
                        if not self.allowedPeriodicHeals[spellName] then
                            self.sanguineWeaknessActive = true
                            self.sanguineWeaknessExpires = GetTime() + 15
                            
                            self:LogSanguineWeakness(spellName)
                            
                            if self.debuffFrame then
                                self.debuffFrame:Show()
                                if self.debuffFrame.timerText then
                                    self.debuffFrame.timerText:Show()
                                end
                            end
                            if self.screenGlowFrame then
                                self.screenGlowFrame:Show()
                            end
                        end
                    end
                end
            end
        end

        if db.bloodPoolMax and db.bloodPoolMax > 0 and db.bloodPoolCurrent then
            local bloodPercent = (db.bloodPoolCurrent / db.bloodPoolMax) * 100
            local threshold = 10
            if bloodPercent < threshold and not self.wasBelowThreshold then
                self.wasBelowThreshold = true
            elseif bloodPercent >= threshold and self.wasBelowThreshold then
                if not db.challengeStats then db.challengeStats = {} end
                db.challengeStats.closeCalls = (db.challengeStats.closeCalls or 0) + 1
                self.wasBelowThreshold = false
            end
        end

		if event == "CHARACTER_POINTS_CHANGED" or event == "PLAYER_TALENT_UPDATE" then
			local currentRank = self:GetOathbreakerRank()
			
			if currentRank > 0 and (self.lastOathbreakerRank or 0) == 0 then
				self:ShowOathBrokenBanner()
				
				print("|cffFFFF00Purity:|r |cffFF0000You have broken your vows. You are now an Oath Breaker.|r")
				if Purity.UpdateCharacterFrameClassName then Purity:UpdateCharacterFrameClassName() end
			
			elseif currentRank == 0 and (self.lastOathbreakerRank or 0) > 0 then
				 if Purity.UpdateCharacterFrameClassName then Purity:UpdateCharacterFrameClassName() end
			end
			
			self.lastOathbreakerRank = currentRank
		end
    end,
}

Purity.GlobalModules = Purity.GlobalModules or {}
Purity.GlobalModules.BLOOD_MAGE_BARGAIN = BloodMageModule