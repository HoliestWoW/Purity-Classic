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

local PurityTabGUI = CreateFrame("Button", "PurityCharacterTab", CharacterFrame)
PurityTabGUI:SetFrameStrata("MEDIUM")

PurityTabGUI:SetWidth(60)
PurityTabGUI:SetHeight(42)

PurityTabGUI.text = PurityTabGUI:CreateFontString(nil, "OVERLAY")
PurityTabGUI.text:SetFontObject(GameFontNormalSmall)
PurityTabGUI.text:SetPoint("CENTER", 0, 1)
PurityTabGUI.text:SetText("Purity")

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

purity_highlight:SetSize(60, 38)
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
	Purity.characterPanel:Show()
end

local function HideCharacterPurity()
	for _, texture in pairs(activeTextures) do texture:Hide() end
	for _, texture in pairs(inactiveTextures) do texture:Show() end
	PurityTabGUI.text:SetFontObject(GameFontNormalSmall)
	PurityTabGUI.text:SetPoint("CENTER", 0, 1)
	PurityTabGUI:SetFrameStrata("MEDIUM")
	Purity.characterPanel:Hide()
end

-- Add this new function after the HideCharacterPurity() function.

function Purity:AdjustCharacterTabs()
	-- Define standard and shrunk sizes for the tabs
	local DEFAULT_TAB_WIDTH = 60
	local SHRUNK_TAB_WIDTH = 52 -- Slightly smaller width
	local DEFAULT_TAB_OVERLAP = -10
	local SHRUNK_TAB_OVERLAP = -12 -- A bit more overlap to save space
	local MAX_TAB_CONTAINER_WIDTH = 345 -- The approximate available width for tabs

	-- List of all tabs to check, including Purity's and potentially Hardcore's
	local tabsToCheck = {
		"CharacterFrameTab1", "CharacterFrameTab2", "CharacterFrameTab3",
		"CharacterFrameTab4", "CharacterFrameTab5", "HardcoreCharacterTab",
		"PurityCharacterTab"
	}

	local totalWidth = 0
	local visibleTabs = {}

	-- Calculate the total width required by all visible tabs
	for _, tabName in ipairs(tabsToCheck) do
		local tab = _G[tabName]
		if tab and tab:IsShown() then
			table.insert(visibleTabs, tab)
			-- For all but the first tab, factor in the overlap
			if totalWidth > 0 then
				totalWidth = totalWidth + DEFAULT_TAB_WIDTH + DEFAULT_TAB_OVERLAP
			else
				totalWidth = totalWidth + DEFAULT_TAB_WIDTH
			end
		end
	end

	-- Decide whether to shrink the tabs
	if totalWidth > MAX_TAB_CONTAINER_WIDTH then
		-- Apply shrunk size to all tabs
		for _, tabName in ipairs(tabsToCheck) do
			local tab = _G[tabName]
			if tab then
				tab:SetWidth(SHRUNK_TAB_WIDTH)
			end
		end
		return SHRUNK_TAB_OVERLAP -- Return the new overlap for positioning
	else
		-- Restore default size to all tabs
		for _, tabName in ipairs(tabsToCheck) do
			local tab = _G[tabName]
			if tab then
				tab:SetWidth(DEFAULT_TAB_WIDTH)
			end
		end
		return DEFAULT_TAB_OVERLAP -- Return the default overlap
	end
end

hooksecurefunc(CharacterFrame, "Show", function()
	-- More aggressive shrinking to ensure tabs fit
	local ADDON_TAB_WIDTH = 45      -- Was 45
	local ADDON_TAB_OVERLAP = -10   -- Was -10

	-- Safely shrink the Hardcore Tab if it exists
	local hcTab = _G["HardcoreCharacterTab"]
	if hcTab then
		hcTab:SetWidth(ADDON_TAB_WIDTH)
	end

	-- Shrink our own Purity Tab
	PurityTabGUI:SetWidth(ADDON_TAB_WIDTH)

	-- A list of all possible tabs to check, in order.
	local tabs_to_check = {
		"CharacterFrameTab1",
		"CharacterFrameTab2",
		"CharacterFrameTab3",
		"CharacterFrameTab4",
		"CharacterFrameTab5",
		"PetPaperDollFrameTab", -- Detects the Pet tab
		"HardcoreCharacterTab"
	}

	local anchorFrame = _G["CharacterFrameTab1"] -- Start with a safe default

	-- Find the actual right-most visible tab to anchor to
	for _, tabName in ipairs(tabs_to_check) do
		local tab = _G[tabName]
		if tab and tab:IsShown() then
			anchorFrame = tab
		end
	end

	-- Position the Purity tab next to the final anchor using the new overlap
	if anchorFrame then
		PurityTabGUI:ClearAllPoints()
		PurityTabGUI:SetPoint("LEFT", anchorFrame, "RIGHT", ADDON_TAB_OVERLAP, 0)
	end
	
	PurityTabGUI:Show()
end)

hooksecurefunc(CharacterFrame, "Hide", function()
    PurityTabGUI:Hide()
    if statusRefreshTicker then
        statusRefreshTicker:Cancel()
        statusRefreshTicker = nil
    end
end)

PurityTabGUI:SetScript("OnClick", function()
	PaperDollFrame:Hide(); PetPaperDollFrame:Hide(); HonorFrame:Hide()
	SkillFrame:Hide(); ReputationFrame:Hide(); TokenFrame:Hide()
	for i=1, 5 do
		PanelTemplates_DeselectTab(_G["CharacterFrameTab"..i])
	end
    if _G.HideCharacterHC then _G.HideCharacterHC() end
	ShowCharacterPurity()
	UpdateCharacterPurity()
	CharacterFrame.activeTab = 9

    -- Start the refresh timer when the tab is clicked.
    if statusRefreshTicker then statusRefreshTicker:Cancel() end
    statusRefreshTicker = C_Timer.NewTicker(1, function()
        if Purity.characterPanel and Purity.characterPanel:IsShown() then
            UpdateCharacterPurity()
        else
            -- If the panel is no longer visible for any reason, stop the timer.
            if statusRefreshTicker then
                statusRefreshTicker:Cancel()
                statusRefreshTicker = nil
            end
        end
    end)
end)

-- Stop the refresh timer when another tab is selected.
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
	
	--[[ MODIFIED: Removed effectiveRuntime and using direct addonRuntime / totalPlayedTime calculation ]]
	local uptimeDisplay = string.format("%.2f%%", (data.totalPlayed > 0 and (data.addonRuntime / data.totalPlayed) * 100) or 0)
	
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
                -- Greater than 90 seconds, up to 90 minutes (5400 seconds)
                local m = math.floor(totalSeconds / 60)
                local s = totalSeconds % 60
                formattedTime = string.format("%d min %d sec", m, s)
            else
                -- Greater than 90 minutes
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