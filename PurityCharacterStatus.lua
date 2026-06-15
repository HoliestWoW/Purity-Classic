local addonName, Purity = ...

local CLASS_COLORS = {
	["WARRIOR"] = "C69B6D", ["MAGE"] = "3FC7EB", ["ROGUE"] = "FFF468",
	["DRUID"] = "FF7C0A", ["HUNTER"] = "AAD372", ["SHAMAN"] = "0070DD",
	["PRIEST"] = "FFFFFF", ["WARLOCK"] = "8788EE", ["PALADIN"] = "F48CBA",
}
local AceGUI = LibStub("AceGUI-3.0")
local statusRefreshTicker = nil
local UpdateCharacterPurity

Purity.characterPanel = CreateFrame("Frame", "PurityCharacterPanel", CharacterFrame)
Purity.characterPanel:SetAllPoints(true)
Purity.characterPanel:Hide()

local frameOffsetX, frameOffsetY = 2, -1

local PurityOuterFrame = CreateFrame("Frame", "PurityOuterFrame", Purity.characterPanel)
PurityOuterFrame:SetSize(400, 400)
PurityOuterFrame:SetPoint("CENTER")
local tL=PurityOuterFrame:CreateTexture(nil,"BACKGROUND");tL:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-TopLeft");tL:SetPoint("TOPLEFT",CharacterFrame,"TOPLEFT",frameOffsetX,frameOffsetY);tL:SetSize(256,256)
local tR=PurityOuterFrame:CreateTexture(nil,"BACKGROUND");tR:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-TopRight");tR:SetPoint("TOPLEFT",CharacterFrame,"TOPLEFT",frameOffsetX+256,frameOffsetY);tR:SetSize(128,256)
local bL=PurityOuterFrame:CreateTexture(nil,"BACKGROUND");bL:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-BottomLeft");bL:SetPoint("TOPLEFT",CharacterFrame,"TOPLEFT",frameOffsetX,frameOffsetY-256);bL:SetSize(256,256)
local bR=PurityOuterFrame:CreateTexture(nil,"BACKGROUND");bR:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-BottomRight");bR:SetPoint("TOPLEFT",CharacterFrame,"TOPLEFT",frameOffsetX+256,frameOffsetY-256);bR:SetSize(128,256)

local title_text = PurityOuterFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title_text:SetPoint("TOP", CharacterFrame, "TOP", 0, -44)
title_text:SetTextColor(1, 0.82, 0)
title_text:SetText("Purity Challenge")

local PurityContentFrame = AceGUI:Create("SimpleGroup")
PurityContentFrame:SetLayout("List")
PurityContentFrame.frame:SetParent(Purity.characterPanel)
PurityContentFrame.frame:SetPoint("TOPLEFT", PurityOuterFrame, "TOPLEFT", 20, -30)
PurityContentFrame.frame:SetPoint("BOTTOMRIGHT", PurityOuterFrame, "BOTTOMRIGHT", -20, 75)

-- =========================================================
-- Tab Creation & Layout Mechanics
-- =========================================================

-- Main Horizontal Tab Frame
local PurityTabGUI = CreateFrame("Button", "PurityCharacterTab", CharacterFrame)
PurityTabGUI:SetFrameStrata("MEDIUM")
PurityTabGUI:SetWidth(60)
PurityTabGUI:SetHeight(45)

PurityTabGUI.text = PurityTabGUI:CreateFontString(nil, "OVERLAY")
PurityTabGUI.text:SetFontObject(GameFontNormalSmall)
PurityTabGUI.text:SetPoint("CENTER", 0, 1)
PurityTabGUI.text:SetText("Purity")

-- Secondary Side Tab Frame (For Overflow Layouts)
local PuritySideTabGUI = CreateFrame("Button", "PurityCharacterSideTab", CharacterFrame)
PuritySideTabGUI:SetSize(60, 60)
PuritySideTabGUI:SetHitRectInsets(0, 30, 0, 0)
PuritySideTabGUI:SetFrameStrata("BACKGROUND")
PuritySideTabGUI:SetFrameLevel(1)
PuritySideTabGUI:Hide()

local sideBg = PuritySideTabGUI:CreateTexture(nil, "BACKGROUND")
sideBg:SetAllPoints()
sideBg:SetTexture("Interface\\Spellbook\\SpellBook-SkillLineTab.png")
PuritySideTabGUI.bg = sideBg

local sideIcon = PuritySideTabGUI:CreateTexture(nil, "ARTWORK")
sideIcon:SetSize(26, 26)
sideIcon:SetPoint("CENTER", PuritySideTabGUI, "CENTER", -12, 5)
sideIcon:SetTexture("Interface\\AddOns\\Purity\\Media\\PurityLogo.tga") 
PuritySideTabGUI.icon = sideIcon

local sideHighlight = PuritySideTabGUI:CreateTexture(nil, "OVERLAY")
sideHighlight:SetSize(30, 30)
sideHighlight:SetPoint("CENTER", PuritySideTabGUI, "CENTER", -12, 4)
sideHighlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
sideHighlight:SetBlendMode("ADD")
sideHighlight:Hide()
PuritySideTabGUI.highlight = sideHighlight

-- Hook Tooltips & Hover Styling
local function RegisterTabTooltips(frame, title, isSide)
	frame:SetScript("OnEnter", function(self)
		if Purity.characterPanel:IsShown() then return end
		if self.highlight then self.highlight:Show() end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("|cFFFFFFFF" .. title .. "|r")
		if isSide then
			GameTooltip:AddLine("Shift-Click + Drag to move side tab", 0.5, 0.5, 0.5)
		end
		GameTooltip:Show()
	end)
	frame:SetScript("OnLeave", function(self)
		if self.highlight and not Purity.characterPanel:IsShown() then self.highlight:Hide() end
		GameTooltip:Hide()
	end)
end
RegisterTabTooltips(PurityTabGUI, "Purity", false)
RegisterTabTooltips(PuritySideTabGUI, "Purity Challenge", true)

-- =========================================================
-- Draggable Behavior for Side Tab
-- =========================================================
local isDragging = false

local function SaveSideTabPosition(yOffset)
	local db = Purity:GetDB()
	if db then
		db.sideTabYOffset = yOffset
	end
end

local function LoadSideTabPosition()
	local db = Purity:GetDB()
	return db and db.sideTabYOffset or -320 -- Default baseline fallback position
end

local function Clamp(val, min, max)
	if val < min then return min end
	if val > max then return max end
	return val
end

PuritySideTabGUI:RegisterForDrag("LeftButton")
PuritySideTabGUI:SetScript("OnDragStart", function(self)
	if not IsShiftKeyDown() then return end
	isDragging = true
	
	self:SetScript("OnUpdate", function(s)
		if not isDragging then s:SetScript("OnUpdate", nil) return end
		
		-- Break track cycle if structural requirements drop out mid-drag
		if not IsMouseButtonDown("LeftButton") or not IsShiftKeyDown() then
			isDragging = false
			s:SetScript("OnUpdate", nil)
			local _, _, _, _, _, lastY = s:GetPoint()
			SaveSideTabPosition(lastY)
			return
		end
		
		-- Track scale calculations safely relative to UI canvas limits
		local _, cursorY = GetCursorPosition()
		local scale = UIParent:GetEffectiveScale()
		local cursorYScaled = cursorY / scale
		
		local frameTop = CharacterFrame:GetTop() or 0
		local frameHeight = CharacterFrame:GetHeight() or 0
		
		local relativeYFromTop = frameTop - cursorYScaled
		
		-- Enforce padding limits mirroring Hardcore Achievements layout constraints
		relativeYFromTop = Clamp(relativeYFromTop, 30, frameHeight - 127)
		
		s:ClearAllPoints()
		s:SetPoint("TOPRIGHT", CharacterFrame, "TOPRIGHT", 25, -relativeYFromTop)
	end)
end)

PuritySideTabGUI:SetScript("OnDragStop", function(self)
	isDragging = false
	self:SetScript("OnUpdate", nil)
	local _, _, _, _, _, finalY = self:GetPoint()
	SaveSideTabPosition(finalY)
end)

-- =========================================================
-- Texture Framework & Visual Overlays
-- =========================================================
local activeTextures = {}
local inactiveTextures = {}

activeTextures.left = PurityTabGUI:CreateTexture(nil, "ARTWORK"); activeTextures.left:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ActiveTab"); activeTextures.left:SetSize(20, 32); activeTextures.left:SetTexCoord(0, 0.3125, 0, 1); activeTextures.left:SetPoint("TOPLEFT", 0, -2); activeTextures.left:Hide()
activeTextures.right = PurityTabGUI:CreateTexture(nil, "ARTWORK"); activeTextures.right:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ActiveTab"); activeTextures.right:SetSize(20, 32); activeTextures.right:SetTexCoord(1 - 0.3125, 1, 0, 1); activeTextures.right:SetPoint("TOPRIGHT", 0, -2); activeTextures.right:Hide()
activeTextures.middle = PurityTabGUI:CreateTexture(nil, "ARTWORK"); activeTextures.middle:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ActiveTab"); activeTextures.middle:SetTexCoord(0.3125, 1 - 0.3125, 0, 1); activeTextures.middle:SetPoint("TOPLEFT", activeTextures.left, "TOPRIGHT"); activeTextures.middle:SetPoint("BOTTOMRIGHT", activeTextures.right, "BOTTOMLEFT"); activeTextures.middle:Hide()

inactiveTextures.left = PurityTabGUI:CreateTexture(nil, "ARTWORK"); inactiveTextures.left:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-InactiveTab"); inactiveTextures.left:SetSize(20, 32); inactiveTextures.left:SetTexCoord(0, 0.3125, 0, 1); inactiveTextures.left:SetPoint("TOPLEFT", 0, -6)
inactiveTextures.right = PurityTabGUI:CreateTexture(nil, "ARTWORK"); inactiveTextures.right:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-InactiveTab"); inactiveTextures.right:SetSize(20, 32); inactiveTextures.right:SetTexCoord(1 - 0.3125, 1, 0, 1); inactiveTextures.right:SetPoint("TOPRIGHT", 0, -6)
inactiveTextures.middle = PurityTabGUI:CreateTexture(nil, "ARTWORK"); inactiveTextures.middle:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-InactiveTab"); inactiveTextures.middle:SetTexCoord(0.3125, 1 - 0.3125, 0, 1); inactiveTextures.middle:SetPoint("TOPLEFT", inactiveTextures.left, "TOPRIGHT"); inactiveTextures.middle:SetPoint("BOTTOMRIGHT", inactiveTextures.right, "BOTTOMLEFT")

local purity_highlight = PurityTabGUI:CreateTexture(nil, "HIGHLIGHT")
purity_highlight:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-RealHighlight")
purity_highlight:SetSize(54, 38)
purity_highlight:SetPoint("TOP", 0, 0)
purity_highlight:SetRotation(3.14)
purity_highlight:SetTexCoord(1.0, 0.0, 1.0, 0.0)
purity_highlight:SetBlendMode("ADD")
PurityTabGUI:SetHighlightTexture(purity_highlight)

local function ShowCharacterPurity()
	for _, texture in pairs(activeTextures) do texture:Show() end
	for _, texture in pairs(inactiveTextures) do texture:Hide() end
	PurityTabGUI.text:SetFontObject(GameFontHighlightSmall)
	PurityTabGUI.text:SetPoint("CENTER", 0, 3)
	PurityTabGUI:SetFrameStrata("HIGH")
	PurityTabGUI:Disable() 
	if PuritySideTabGUI.highlight then PuritySideTabGUI.highlight:Show() end
	if GameTooltip:GetOwner() == PurityTabGUI or GameTooltip:GetOwner() == PuritySideTabGUI then GameTooltip:Hide() end   
	Purity.characterPanel:Show()
end

local function HideCharacterPurity()
	for _, texture in pairs(activeTextures) do texture:Hide() end
	for _, texture in pairs(inactiveTextures) do texture:Show() end
	PurityTabGUI.text:SetFontObject(GameFontNormalSmall)
	PurityTabGUI.text:SetPoint("CENTER", 0, 1)
	PurityTabGUI:SetFrameStrata("MEDIUM")
	PurityTabGUI:Enable()   
	if PuritySideTabGUI.highlight then PuritySideTabGUI.highlight:Hide() end
	Purity.characterPanel:Hide()
end

function Purity:AdjustCharacterTabs()
	return -10
end

-- Synchronize Highlight Selection Frames
hooksecurefunc("PanelTemplates_SelectTab", function(tab)
	if tab == PurityTabGUI and PuritySideTabGUI.highlight then
		PuritySideTabGUI.highlight:Show()
	end
end)

hooksecurefunc("PanelTemplates_DeselectTab", function(tab)
	if tab == PurityTabGUI and PuritySideTabGUI.highlight then
		PuritySideTabGUI.highlight:Hide()
	end
end)

-- =========================================================
-- Core Engine Dynamic Anchor Updates
-- =========================================================
hooksecurefunc(CharacterFrame, "Show", function()
	C_Timer.After(0.01, function()
		local ADDON_TAB_WIDTH = 55    
		local ADDON_TAB_OVERLAP = -10   
		local MAX_TAB_CONTAINER_WIDTH = 320 

		PurityTabGUI:SetWidth(ADDON_TAB_WIDTH)

		local refTab = _G["CharacterFrameTab1"]
		local rightMostTab = refTab
		local maxRight = refTab and refTab:GetRight() or 0
		local refBottom = refTab and refTab:GetBottom() or 0

		local baselineLeft = refTab and refTab:GetLeft() or 0
		local dynamicRowWidth = 0

		local children = {CharacterFrame:GetChildren()}
		for _, child in ipairs(children) do
			local name = child:GetName()
			if name and name ~= "PurityCharacterTab" and name ~= "PurityCharacterSideTab" and child:GetObjectType() == "Button" and string.find(name, "Tab", 1, true) then
				if child:IsShown() then
					local childBottom = child:GetBottom()
					if childBottom and math.abs(childBottom - refBottom) < 15 then
						local right = child:GetRight()
						if right and right > maxRight then
							maxRight = right
							rightMostTab = child
						end
					end
				end
			end
		end

		if maxRight and baselineLeft then
			dynamicRowWidth = maxRight - baselineLeft
		end

		-- Handle Overflow Switching
		if (dynamicRowWidth + ADDON_TAB_WIDTH + ADDON_TAB_OVERLAP) > MAX_TAB_CONTAINER_WIDTH then
			PurityTabGUI:Hide()
			
			PuritySideTabGUI:ClearAllPoints()
			-- Restore saved vertical coordinates from database
			local savedY = LoadSideTabPosition()
			PuritySideTabGUI:SetPoint("TOPRIGHT", CharacterFrame, "TOPRIGHT", 25, savedY)
			PuritySideTabGUI:Show()
		else
			PuritySideTabGUI:Hide()
			if rightMostTab then
				PurityTabGUI:ClearAllPoints()
				PurityTabGUI:SetPoint("LEFT", rightMostTab, "RIGHT", ADDON_TAB_OVERLAP, 0)
			end
			PurityTabGUI:Show()
		end
	end)
end)

hooksecurefunc(CharacterFrame, "Hide", function()
    PurityTabGUI:Hide()
    PuritySideTabGUI:Hide()
    if statusRefreshTicker then
        statusRefreshTicker:Cancel()
        statusRefreshTicker = nil
    end
end)

local function OnTabClickAction()
	PaperDollFrame:Hide(); PetPaperDollFrame:Hide(); HonorFrame:Hide()
	SkillFrame:Hide(); ReputationFrame:Hide(); TokenFrame:Hide()
	for i=1, 5 do
		PanelTemplates_DeselectTab(_G["CharacterFrameTab"..i])
	end
	if _G.HardcoreAchievementsFrame then _G.HardcoreAchievementsFrame:Hide() end
    if _G.HideCharacterHC then _G.HideCharacterHC() end
	ShowCharacterPurity()
	UpdateCharacterPurity()
	CharacterFrame.activeTab = 9

    if statusRefreshTicker then statusRefreshTicker:Cancel() end
    statusRefreshTicker = C_Timer.NewTicker(1, function()
        if Purity.characterPanel and Purity.characterPanel:IsShown() then
            UpdateCharacterPurity()
        else
            if statusRefreshTicker then
                statusRefreshTicker:Cancel()
                statusRefreshTicker = nil
            end
        end
    end)
end

PurityTabGUI:SetScript("OnClick", OnTabClickAction)
PuritySideTabGUI:SetScript("OnClick", OnTabClickAction)

hooksecurefunc("PanelTemplates_SetTab", function(frame, id)
	if frame == CharacterFrame and id and id ~= 9 then
		if Purity.characterPanel:IsShown() then
			HideCharacterPurity()
            if statusRefreshTicker then
                statusRefreshTicker:Cancel()
                statusRefreshTicker = nil
            end
		end
	end
end)

hooksecurefunc("CharacterFrame_ShowSubFrame", function(frameName)
	if Purity.characterPanel:IsShown() and frameName ~= "PurityCharacterPanel" then
		HideCharacterPurity()
	end
end)

UpdateCharacterPurity = function()
	PurityContentFrame:ReleaseChildren()
	Purity:SilentRequestTimePlayed()
	
	local data = Purity:GetRawStatusData()
	if not data then return end
	local db = Purity:GetDB()
	if not db then return end
	local playerClass, class_en = UnitClass("player")
	local playerName = UnitName("player")
	local playerLevel = UnitLevel("player")
	local goldColor = "|cffffd100"; local whiteColor = "|cffffffff"; local greenColor = "|cff00ff00"; local redColor = "|cffff4444"
	local statusColor = greenColor
	if data.status == "Failed" then statusColor = redColor
	elseif data.status == "Not Participating" then statusColor = "|cff888888"
	elseif data.status == "Temporary Failure - Uptime" then statusColor = "|cffffff00" end
	local meta_data_container = AceGUI:Create("SimpleGroup"); meta_data_container:SetLayout("List"); meta_data_container:SetFullWidth(true)
	PurityContentFrame:AddChild(meta_data_container)
	local function CreateLabel(text, size, height)
		local label = AceGUI:Create("Label"); label:SetText(text); label:SetFont("Fonts\\FRIZQT__.TTF", size, "OUTLINE")
		label:SetJustifyH("CENTER"); label:SetFullWidth(true); label:SetHeight(height); meta_data_container:AddChild(label)
		return label
	end

	local classColorHex = CLASS_COLORS[class_en] or "FFFFFF"
	local mod = Purity.GlobalModules and Purity.GlobalModules.BLOOD_MAGE_BARGAIN
	local rank = (mod and mod.GetOathbreakerRank) and mod:GetOathbreakerRank() or 0

	if class_en == "PALADIN" and db.activeChallengeID == "BLOOD_MAGE_BARGAIN" and rank > 0 then
		playerClass = "Oath Breaker"
		classColorHex = "FF0000"
	end
	
	local classColorStr = "|cff" .. classColorHex .. playerClass .. "|r"

	CreateLabel("", 1, 35); CreateLabel(whiteColor .. playerName, 18, 35); CreateLabel("Level " .. playerLevel .. " " .. classColorStr, 12, 20)
	CreateLabel("", 1, 20); CreateLabel("\nChallenge Status", 16, 40)
	CreateLabel(goldColor .. "Challenge:|r " .. whiteColor .. (data.challengeTitle or "None"), 12, 20)
	CreateLabel(goldColor .. "Status:|r " .. statusColor .. data.status .. "|r", 12, 20)
	
	local currentUptime = (data.totalPlayed > 0 and (data.addonRuntime / data.totalPlayed) * 100) or 0
	local uptimeDisplay = string.format("%.2f%%", math.min(100, currentUptime))
	
	CreateLabel(goldColor .. "Addon Uptime:|r " .. whiteColor .. uptimeDisplay, 12, 20)
	if data.startDate and data.startDate ~= "N/A" then CreateLabel(goldColor .. "Started:|r " .. whiteColor .. data.startDate, 12, 20) end
	CreateLabel("", 1, 20); CreateLabel("\nGameplay Modifiers", 16, 40)
	
	local isHardcoreStatusValid, validationReason = Purity:IsHardcoreStatusValid()

	local hcStatusText = db.isHardcoreRun and greenColor .. "ACTIVE" or redColor .. "INACTIVE"
	local hcLabel = CreateLabel(goldColor .. "Hardcore:|r " .. hcStatusText .. "|r", 12, 20)

	local sfStatusText = db.isSelfFoundRun and greenColor .. "ACTIVE" or redColor .. "INACTIVE"
	local sfLabel = CreateLabel(goldColor .. "Self-Found:|r " .. sfStatusText .. "|r", 12, 20)

	local ssfStatusText = (db.isSSFRun and isHardcoreStatusValid) and greenColor .. "ACTIVE" or redColor .. "INACTIVE"
	local ssfLabel = CreateLabel(goldColor .. "Solo Self-Found:|r " .. ssfStatusText .. "|r", 12, 20)

	if db.isSSFRun and not isHardcoreStatusValid then
		if not PuritySSFHitbox then
			PuritySSFHitbox = CreateFrame("Frame", "PuritySSFHitbox", UIParent)
			PuritySSFHitbox:SetScript("OnLeave", function() GameTooltip:Hide() end)
		end
		
		local ssfHitBox = PuritySSFHitbox
		ssfHitBox:SetParent(ssfLabel.frame)
		ssfHitBox:ClearAllPoints()
		ssfHitBox:SetSize(ssfLabel.label:GetStringWidth(), ssfLabel.label:GetStringHeight())
		ssfHitBox:SetPoint("CENTER", ssfLabel.frame, "CENTER", 0, 0)
		ssfHitBox:EnableMouse(true)

		ssfHitBox:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:AddLine("Invalid Hardcore Status", 1, 1, 1)
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(validationReason, 1, 0.82, 0)
			GameTooltip:Show()
		end)
	end
	
	local _, baseCoeff = Purity:GetCurrentChallengeInfo()
	local modifiers = Purity:GetGameplayModifiers()
	local multiplier = 1.0

	if modifiers.isHardcore then
		multiplier = multiplier * 2.0
	end
	if modifiers.isSelfFound then
		multiplier = multiplier * 1.5
	end
	if modifiers.isSSF then
		multiplier = multiplier * 2.0
	end
	
	local totalCoeff = baseCoeff * multiplier

	CreateLabel("", 1, 10)
	CreateLabel("\nLeaderboard Info", 16, 22)
	
	if totalCoeff == baseCoeff then
		local coeffLabel = CreateLabel(goldColor .. "Coefficient:|r " .. whiteColor .. string.format("%.2f", totalCoeff), 12, 16)
		
		if not PurityScoreHitbox then
			PurityScoreHitbox = CreateFrame("Frame", "PurityScoreHitbox", UIParent)
			PurityScoreHitbox:SetScript("OnLeave", function() GameTooltip:Hide() end)
		end
		local scoreHitBox = PurityScoreHitbox
		scoreHitBox:SetParent(coeffLabel.frame)
		scoreHitBox:ClearAllPoints()
		scoreHitBox:SetSize(coeffLabel.label:GetStringWidth(), coeffLabel.label:GetStringHeight())
		scoreHitBox:SetPoint("CENTER", coeffLabel.frame, "CENTER", 0, 0)
		scoreHitBox:EnableMouse(true)

		scoreHitBox:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:AddLine("Score Calculation", 1, 1, 1)
			GameTooltip:AddLine(" ")
			local title = data.challengeTitle or "Challenge"
			GameTooltip:AddDoubleLine(title .. " Coefficient:", string.format("%.2f", baseCoeff), 1, 1, 1, 1, 1, 1)
			GameTooltip:Show()
		end)
	else
		local baseLabel = CreateLabel(goldColor .. "Base Coefficient:|r " .. whiteColor .. string.format("%.2f", baseCoeff), 12, 16)
		local totalLabel = CreateLabel(goldColor .. "Total Coefficient:|r " .. whiteColor .. string.format("%.2f", totalCoeff), 12, 16)
		
		if not PurityScoreHitbox then
			PurityScoreHitbox = CreateFrame("Frame", "PurityScoreHitbox", UIParent)
			PurityScoreHitbox:SetScript("OnLeave", function() GameTooltip:Hide() end)
		end
		local scoreHitBox = PurityScoreHitbox
		scoreHitBox:SetParent(totalLabel.frame)
		scoreHitBox:ClearAllPoints()
		scoreHitBox:SetSize(totalLabel.label:GetStringWidth(), totalLabel.label:GetStringHeight())
		scoreHitBox:SetPoint("CENTER", totalLabel.frame, "CENTER", 0, 0)
		scoreHitBox:EnableMouse(true)
		
		scoreHitBox:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:AddLine("Score Calculation", 1, 1, 1)
			GameTooltip:AddLine(" ")
			local title = data.challengeTitle or "Challenge"
			GameTooltip:AddDoubleLine(title .. " Coefficient:", string.format("%.2f", baseCoeff), 1, 1, 1, 1, 1, 1)
			if modifiers.isHardcore then GameTooltip:AddDoubleLine("Hardcore Modifier:", "x2.0", 1, 1, 1, 1, 1, 1) end
			if modifiers.isSelfFound then GameTooltip:AddDoubleLine("Self-Found Modifier:", "x1.5", 1, 1, 1, 1, 1, 1) end
			if modifiers.isSSF then GameTooltip:AddDoubleLine("Solo Self-Found Modifier:", "x2.0", 1, 1, 1, 1, 1, 1) end
			GameTooltip:AddLine(" ", 1, 1, 1, 1, 1, 1)
			GameTooltip:AddDoubleLine("Final Score:", string.format("%.2f", totalCoeff), 1, 0.82, 0, 1, 0.82, 0)
			GameTooltip:Show()
		end)
	end
	
	if db.activeChallengeID == "BLOOD_MAGE_BARGAIN" then
		CreateLabel("", 1, 10)
		CreateLabel(" ", 16, 16)
		CreateLabel("Blood Efficiency", 16, 22)
		
		local powerType = UnitPowerType("player")
		local baseDivisor = (powerType == 0 and 200) or (powerType == 3 and 500) or 100
		local level = UnitLevel("player")
		local scaledDivisor = baseDivisor + (level * 20)
		local _, spirit = UnitStat("player", 5)
		
		local mod = Purity.GlobalModules and Purity.GlobalModules.BLOOD_MAGE_BARGAIN
		local rank = (mod and mod.GetOathbreakerRank) and mod:GetOathbreakerRank() or 0
		local spiritFactor = 12.0 + (rank * 2.4)
		
		local spiritDivisor = spirit * spiritFactor
		local totalDivisor = scaledDivisor + spiritDivisor
		
		local reduction = 0
		if totalDivisor > 0 then
			reduction = (1 - (scaledDivisor / totalDivisor)) * 100
		end
		
		local reductionText = string.format("%.1f%%", reduction)
		local reductionLine = CreateLabel(goldColor .. "Cost Reduction:|r " .. greenColor .. reductionText, 12, 16)
		
		if not PurityBloodCostHitbox then
			PurityBloodCostHitbox = CreateFrame("Frame", "PurityBloodCostHitbox", UIParent)
			PurityBloodCostHitbox:SetScript("OnLeave", function() GameTooltip:Hide() end)
		end
		
		local hitBox = PurityBloodCostHitbox
		hitBox:SetParent(reductionLine.frame)
		hitBox:ClearAllPoints()
		
		hitBox:SetSize(reductionLine.label:GetStringWidth(), reductionLine.label:GetStringHeight())
		hitBox:SetPoint("CENTER", reductionLine.frame, "CENTER", 0, 0)
		hitBox:EnableMouse(true)
		
		hitBox:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText("Blood Cost Reduction", 1, 1, 1)
			GameTooltip:AddLine("Decreases the Blood cost of your abilities and melee swings.", 1, 0.82, 0, true)
			GameTooltip:AddLine("The amount of reduction is influenced by your active resource, your level, and your Spirit.", 1, 0.82, 0, true)
			GameTooltip:AddLine(" ")
			GameTooltip:AddDoubleLine("Spirit:", spirit, 0.8, 0.8, 0.8, 1, 1, 1)
			GameTooltip:AddDoubleLine("Current cost reduction:", string.format("%.1f%%", reduction), 0.8, 0.8, 0.8, 0.1, 1, 0.1)
			GameTooltip:Show()
		end)
		
		hitBox:SetScript("OnLeave", function() GameTooltip:Hide() end)
		reductionLine.frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
	end

	if (db.challengeStats and next(db.challengeStats)) or (db.activeChallengeID == "FISHING") or (db.activeChallengeID == "DRUNK") then
		CreateLabel("", 1, 10)
		CreateLabel(" ", 16, 16)
		local statsLabel = CreateLabel("Fun Stats", 16, 22)
		
		if not PurityFunStatsHitbox then
			PurityFunStatsHitbox = CreateFrame("Frame", "PurityFunStatsHitbox", UIParent)
			PurityFunStatsHitbox:SetScript("OnLeave", function() GameTooltip:Hide() end)
		end
		
		local statsHitBox = PurityFunStatsHitbox
		statsHitBox:SetParent(statsLabel.frame)
		statsHitBox:ClearAllPoints()
		statsHitBox:SetSize(statsLabel.label:GetStringWidth(), statsLabel.label:GetStringHeight())
		statsHitBox:SetPoint("CENTER", statsLabel.frame, "CENTER", 0, 0)
		statsHitBox:EnableMouse(true)

		statsHitBox:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:AddLine("Just for Fun!", 1, 1, 1)
			GameTooltip:AddLine("This is a simple counter of an iconic action for your current challenge.", 0.8, 0.8, 0.8, true)
			GameTooltip:Show()
		end)
		
		local statValue, statName = nil, nil
		
		if db.activeChallengeID == "BLOOD_MAGE_BARGAIN" then
			statValue = db.challengeStats and db.challengeStats.closeCalls or 0
			statName = "Close Calls:"
		elseif db.challengeTitle == "Sacrament of Purity" then statValue = db.challengeStats.lifeTapCasts; statName = "Life Taps Cast:"
		elseif db.challengeTitle == "Grimoire of Purity" then statValue = db.challengeStats.immolateCasts; statName = "Immolates Cast:"
		elseif db.challengeTitle == "Brand of Purity" then statValue = db.challengeStats.chargeInterceptCasts; statName = "Charges/Intercepts:"
		elseif db.challengeTitle == "Bulwark of Purity" then statValue = db.challengeStats.blocks; statName = "Successful Blocks:"
		elseif db.challengeTitle == "Conduit of Purity" then
            statValue = math.floor(db.challengeStats.chargeAccumulatedCombat or 0)
            statName = "Combat Charge Gen:"
		elseif db.activeChallengeID == "Tome of Purity" then
			statValue = db.challengeStats and db.challengeStats.primarySpellCasts or 0
			local spec = db.mageData and db.mageData.specialization
			if spec == "Fire" then
				statName = "Fireballs Cast:"
			elseif spec == "Frost" then
				statName = "Frostbolts Cast:"
			elseif spec == "Arcane" then
				statName = "Arcane Missiles Cast:"
			else
				statName = "Primary Spells Cast:"
			end
		elseif db.challengeTitle == "Testament of Purity" then statValue = db.challengeStats.smiteCasts; statName = "Smites Cast:"
		elseif db.challengeTitle == "Covenant of Purity" then statValue = db.challengeStats.mindFlayCasts; statName = "Mind Flays Channeled:"
		elseif db.challengeTitle == "Oath of Purity" then statValue = db.challengeStats.holyLightCasts; statName = "Holy Lights Cast:"
		elseif db.challengeTitle == "Libram of Purity" then statValue = db.challengeStats.exorcismCasts; statName = "Exorcisms Cast:"
		elseif db.challengeTitle == "Communion of Purity" then statValue = db.challengeStats.lightningBoltCasts; statName = "Lightning Bolts Cast:"
		elseif db.challengeTitle == "Flame of Purity" then statValue = db.challengeStats.fireSpellCasts; statName = "Fire Spells Cast:"
		elseif db.challengeTitle == "Pact of Purity" then statValue = db.challengeStats.shapeshiftCasts; statName = "Bear Form Shifts:"
		elseif db.challengeTitle == "Astrolabe of Purity" then statValue = db.challengeStats.celestialCasts; statName = "Celestial/Nature Spells Cast:"
		elseif db.challengeTitle == "Contract of Purity" then statValue = db.challengeStats.sinisterStrikeCasts; statName = "Sinister Strikes:"
		elseif db.challengeTitle == "Foil of Purity" then statValue = db.challengeStats.riposteCasts; statName = "Ripostes:"
		elseif db.challengeTitle == "Shroud of Purity" then 
            statValue = db.challengeStats.vanishesUsed; statName = "Vanishes Used:"
        elseif db.challengeTitle == "Tether of Purity" then 
            statValue = math.floor(db.challengeStats.connectionGenerated or 0); statName = "Connection Generated:"
		elseif db.challengeTitle == "The Glass Heart" then
			if db.challengeStats and db.challengeStats.lowestGlassHP then
				statValue = string.format("%.1f%%", db.challengeStats.lowestGlassHP)
				statName = "Lowest HP Reached:"
			else
				statValue = "100.0%"
				statName = "Lowest HP Reached:"
			end
		elseif db.challengeTitle == "Bond of Purity" then statValue = db.challengeStats.mendPetCasts; statName = "Mend Pet Casts:"
		elseif db.challengeTitle == "Quiver of Purity" then statValue = db.challengeStats.aimedShotCasts; statName = "Aimed Shots Fired:"
		elseif db.challengeTitle == "The Ascetic's Path" then statValue = db.challengeStats.forbiddenItemsSold; statName = "Potential Upgrades Sold:"
		elseif db.challengeTitle == "The Drunken Master" then
			statName = "Money Spent on Drinks:"
			local moneySpent = (db.challengeStats and db.challengeStats.moneySpent) or 0
			local gold = math.floor(moneySpent / 10000)
			local silver = math.floor((moneySpent % 10000) / 100)
			local copper = moneySpent % 100
			local moneyString = ""
			if gold > 0 then moneyString = moneyString .. gold .. "|cffffd700g|r " end
			if silver > 0 or gold > 0 then moneyString = moneyString .. silver .. "|cffc7c7cfs|r " end
			moneyString = moneyString .. copper .. "|cffeda55fc|r"
			statValue = moneyString
		elseif db.challengeTitle == "The Ringbearer's Vow" then 
            local totalSeconds = db.challengeStats.timeSpentFishing or 0
            local formattedTime = ""
            
            if totalSeconds <= 90 then
                formattedTime = totalSeconds .. " sec"
            elseif totalSeconds <= 5400 then
                local m = math.floor(totalSeconds / 60)
                local s = totalSeconds % 60
                formattedTime = string.format("%d min %d sec", m, s)
            else
                local h = math.floor(totalSeconds / 3600)
                local m = math.floor((totalSeconds % 3600) / 60)
                local s = totalSeconds % 60
                formattedTime = string.format("%d hr %d min %d sec", h, m, s)
            end

            statValue = formattedTime
            statName = "Time Spent Fishing:"
            
            local campfiresBuilt = db.challengeStats.campfiresBuilt or 0
            CreateLabel(goldColor .. "Campfires Built:|r " .. whiteColor .. campfiresBuilt, 12, 16)
		end

		if statName and statValue then
			CreateLabel(goldColor .. statName .. "|r " .. whiteColor .. statValue, 12, 16)
		end

		if db.activeChallengeID == "FISHING" then
			local fishCount = (db.challengeStats and db.challengeStats.totalCatches) or 0
			local trunkCount = (db.challengeStats and db.challengeStats.trunksFished) or 0
			CreateLabel(goldColor .. "Total Catches:|r " .. whiteColor .. fishCount, 12, 16)
			CreateLabel(goldColor .. "Trunks Fished:|r " .. whiteColor .. trunkCount, 12, 16)
		end
	end
end