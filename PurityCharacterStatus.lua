function Purity:InitializeCharacterPanel()
	local CLASS_COLORS = {
		["WARRIOR"] = "C69B6D", ["MAGE"] = "3FC7EB", ["ROGUE"] = "FFF468",
		["DRUID"] = "FF7C0A", ["HUNTER"] = "AAD372", ["SHAMAN"] = "0070DD",
		["PRIEST"] = "FFFFFF", ["WARLOCK"] = "8788EE", ["PALADIN"] = "F48CBA",
		["MONK"] = "00FF96", ["DEATH KNIGHT"] = "C41F3B",
	}
	local AceGUI = LibStub("AceGUI-3.0")

	local PurityPanel = CreateFrame("Frame", "PurityCharacterPanel", CharacterFrame)
	PurityPanel:SetAllPoints(true)
	PurityPanel:Hide()

	local frameOffsetX, frameOffsetY = 2, -1

	local PurityOuterFrame = CreateFrame("Frame", "PurityOuterFrame", PurityPanel)
	PurityOuterFrame:SetSize(400, 400)
	PurityOuterFrame:SetPoint("CENTER")
	local tL=PurityOuterFrame:CreateTexture(nil,"BACKGROUND");tL:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-TopLeft")
	local tR=PurityOuterFrame:CreateTexture(nil,"BACKGROUND");tR:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-TopRight")
	local bL=PurityOuterFrame:CreateTexture(nil,"BACKGROUND");bL:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-BottomLeft")
	local bR=PurityOuterFrame:CreateTexture(nil,"BACKGROUND");bR:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-BottomRight")

	local title_text = PurityOuterFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title_text:SetPoint("TOP", CharacterFrame, "TOP", 0, -44)
	title_text:SetTextColor(1, 0.82, 0)
	title_text:SetText("Purity Challenge")

	local PurityContentFrame = AceGUI:Create("SimpleGroup")
	PurityContentFrame:SetLayout("List")
	PurityContentFrame.frame:SetParent(PurityPanel)
	PurityContentFrame.frame:SetPoint("TOPLEFT", PurityOuterFrame, "TOPLEFT", 20, -65)
	PurityContentFrame.frame:SetPoint("BOTTOMRIGHT", PurityOuterFrame, "BOTTOMRIGHT", -20, 75)

	local PurityTabGUI = CreateFrame("Button", "PurityCharacterTab", CharacterFrame)
	PurityTabGUI:SetFrameStrata("MEDIUM")

	PurityTabGUI:SetWidth(60)
	PurityTabGUI:SetHeight(45)

	PurityTabGUI.text = PurityTabGUI:CreateFontString(nil, "OVERLAY")
	PurityTabGUI.text:SetFontObject(GameFontNormalSmall)
	PurityTabGUI.text:SetPoint("CENTER", 0, 1)
	PurityTabGUI.text:SetText("Purity")

	local activeTextures = {}
	local inactiveTextures = {}

	activeTextures.left = PurityTabGUI:CreateTexture(nil, "ARTWORK"); activeTextures.left:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ActiveTab"); activeTextures.left:SetSize(20, 70); activeTextures.left:SetRotation(3.14); activeTextures.left:SetTexCoord(0.8, 1.0, 1.0, 0.0); activeTextures.left:SetPoint("TOPLEFT", 0, -5); activeTextures.left:Hide()
	activeTextures.middle = PurityTabGUI:CreateTexture(nil, "ARTWORK"); activeTextures.middle:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ActiveTab"); activeTextures.middle:SetSize(20, 70); activeTextures.middle:SetRotation(3.14); activeTextures.middle:SetTexCoord(0.8, 0.2, 1.0, 0.0); activeTextures.middle:SetPoint("TOP", 0, -5); activeTextures.middle:Hide()
	activeTextures.right = PurityTabGUI:CreateTexture(nil, "ARTWORK"); activeTextures.right:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ActiveTab"); activeTextures.right:SetSize(20, 70); activeTextures.right:SetRotation(3.14); activeTextures.right:SetTexCoord(0.0, 0.2, 1.0, 0.0); activeTextures.right:SetPoint("TOPRIGHT", 0, -5); activeTextures.right:Hide()

	inactiveTextures.left = PurityTabGUI:CreateTexture(nil, "ARTWORK"); inactiveTextures.left:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-InactiveTab"); inactiveTextures.left:SetSize(20, 32); inactiveTextures.left:SetRotation(3.14); inactiveTextures.left:SetTexCoord(0.8, 1.0, 1.0, 0.0); inactiveTextures.left:SetPoint("TOPLEFT", 0, -9)
	inactiveTextures.middle = PurityTabGUI:CreateTexture(nil, "ARTWORK"); inactiveTextures.middle:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-InactiveTab"); inactiveTextures.middle:SetSize(20, 32); inactiveTextures.middle:SetRotation(3.14); inactiveTextures.middle:SetTexCoord(0.8, 0.2, 1.0, 0.0); inactiveTextures.middle:SetPoint("TOP", 0, -9)
	inactiveTextures.right = PurityTabGUI:CreateTexture(nil, "ARTWORK"); inactiveTextures.right:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-InactiveTab"); inactiveTextures.right:SetSize(20, 32); inactiveTextures.right:SetRotation(3.14); inactiveTextures.right:SetTexCoord(0.0, 0.2, 1.0, 0.0); inactiveTextures.right:SetPoint("TOPRIGHT", 0, -9)

	local purity_highlight = PurityTabGUI:CreateTexture(nil, "HIGHLIGHT")
	purity_highlight:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-RealHighlight")

	purity_highlight:SetSize(58, 43)

	purity_highlight:SetPoint("TOP", 0, 0)

	purity_highlight:SetRotation(3.14)
	purity_highlight:SetTexCoord(1.0, 0.0, 1.0, 0.0)
	purity_highlight:SetBlendMode("ADD")

	PurityTabGUI:SetHighlightTexture(purity_highlight)

	PurityTabGUI:SetHighlightTexture(purity_highlight)

	function ShowCharacterPurity()
		purity_highlight:SetDrawLayer("BACKGROUND")
		for _, texture in pairs(activeTextures) do texture:Show() end
		for _, texture in pairs(inactiveTextures) do texture:Hide() end
		PurityTabGUI.text:SetFontObject(GameFontHighlightSmall)
		PurityTabGUI.text:SetPoint("CENTER", 0, -1)
		PurityTabGUI:SetFrameStrata("HIGH")
		PurityPanel:Show()
	end

	function HideCharacterPurity()
		purity_highlight:SetDrawLayer("HIGHLIGHT")
		for _, texture in pairs(activeTextures) do texture:Hide() end
		for _, texture in pairs(inactiveTextures) do texture:Show() end
		PurityTabGUI.text:SetFontObject(GameFontNormalSmall)
		PurityTabGUI.text:SetPoint("CENTER", 0, 1)
		PurityTabGUI:SetFrameStrata("MEDIUM")
		PurityPanel:Hide()
	end

	hooksecurefunc(CharacterFrame, "Show", function()
		-- This new function performs the final bag check for the Ashes of Purity challenge.
		local function FinalizeAshesBagCheck()
			local db = Purity and Purity:GetDB()
			if not db or db.status ~= "Awaiting Bag Confirmation" or db.activeChallengeID ~= "DK_ASHES" then
				return -- Not in the state we need, so do nothing.
			end

			local bagSlots = { INVSLOT_BAG1, INVSLOT_BAG2, INVSLOT_BAG3, INVSLOT_BAG4 }
			local hasBagsEquipped = false
			for _, slotId in ipairs(bagSlots) do
				if GetInventoryItemID("player", slotId) and GetInventoryItemID("player", slotId) > 0 then
					hasBagsEquipped = true
					break -- Found a bag, no need to check further.
				end
			end

			if hasBagsEquipped then
				-- If bags are found, the challenge fails.
				Purity:Violation("Failed final activation check: Bags were equipped.")
			else
				-- If no bags are found, the challenge is fully activated.
				db.status = "Passing"
				print("|cffFFFF00Purity:|r |cff00ff00Bag check successful! Your 'Ashes of Purity' challenge is now fully active. Good luck!|r")
			end
		end
		
		-- Run our new check every time the character frame is shown.
		FinalizeAshesBagCheck()

		-- The original code from this hook to manage the Purity tab.
		local anchorFrame = nil
		for i = 5, 1, -1 do
			local tab = _G["CharacterFrameTab" .. i]
			if tab and tab:IsShown() then
				anchorFrame = tab
				break
			end
		end

		if _G["HardcoreCharacterTab"] and _G["HardcoreCharacterTab"]:IsShown() then
			anchorFrame = _G["HardcoreCharacterTab"]
		end
		
		if anchorFrame then
			PurityTabGUI:ClearAllPoints()
			PurityTabGUI:SetPoint("LEFT", anchorFrame, "RIGHT", -10, 2.5)
		end

		PurityTabGUI:Show()
	end)

	hooksecurefunc(CharacterFrame, "Hide", function() PurityTabGUI:Hide() end)

	PurityTabGUI:SetScript("OnClick", function()
		-- Use the proper Blizzard function to handle changing the active tab
		PanelTemplates_SetTab(CharacterFrame, 9)

		-- Hide the content panes of the other default tabs
		PaperDollFrame:Hide(); PetPaperDollFrame:Hide(); HonorFrame:Hide()
		SkillFrame:Hide(); ReputationFrame:Hide(); TokenFrame:Hide()
		
		-- Explicitly hide the Hardcore tab's content and update its visual state
		if _G.HideCharacterHC then _G.HideCharacterHC() end

		-- Manually show the Purity tab's visuals and content
		ShowCharacterPurity()
		UpdateCharacterPurity()
	end)

	hooksecurefunc("PanelTemplates_SetTab", function(frame, id)
		if frame == CharacterFrame and id and id ~= 9 then
			if PurityPanel:IsShown() then
				HideCharacterPurity()
			end
		end
	end)

	function UpdateCharacterPurity()
		PurityContentFrame:ReleaseChildren()
		Purity:SilentRequestTimePlayed()
		C_Timer.After(0.2, function()
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
			local classColorHex = CLASS_COLORS[class_en] or "FFFFFF"; local classColorStr = "|cff" .. classColorHex .. playerClass .. "|r"
			CreateLabel("", 1, 35); CreateLabel(whiteColor .. playerName, 18, 35); CreateLabel("Level " .. playerLevel .. " " .. classColorStr, 12, 20)
			CreateLabel("", 1, 20); CreateLabel("\nChallenge Status", 16, 40)
			CreateLabel(goldColor .. "Challenge:|r " .. whiteColor .. (data.challengeTitle or "None"), 12, 20)
			CreateLabel(goldColor .. "Status:|r " .. statusColor .. data.status .. "|r", 12, 20)
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
				local function addTooltip(this) GameTooltip:SetOwner(this, "ANCHOR_RIGHT"); GameTooltip:AddLine("Invalid Hardcore Status", 1, 1, 1); GameTooltip:AddLine(" "); GameTooltip:AddLine(validationReason, 1, 0.82, 0); GameTooltip:Show() end
				local function hideTooltip() GameTooltip:Hide() end
				ssfLabel.frame:SetScript("OnEnter", addTooltip); ssfLabel.frame:SetScript("OnLeave", hideTooltip)
			end
			
			local baseCoeff, totalCoeff
			local displayTitle = data.challengeTitle or "None"

			if db.status == "Not Participating" or db.status == "Failed" then
				baseCoeff = 0; totalCoeff = 0
			else
				-- THE FIX: Add a special case for the Phylactery challenge calculation.
				if (db.destinedDKChallenge == "Phylactery of Purity" and db.challengeTitle == "Path of the Damned") or (data.challengeTitle == "Phylactery of Purity") then
					-- This handles both the Warlock on the path and the DK who inherited it.
					baseCoeff = Purity.ChallengeCoefficients["Phylactery of Purity"] or 0
					totalCoeff = baseCoeff
					displayTitle = "Phylactery of Purity"
				elseif db.inheritedVowCoefficient and db.inheritedVowCoefficient >= 0 then
					-- Standard DK weighted calculation
					local vowCoeff = db.inheritedVowCoefficient
					local _, dkCoeff = Purity:GetCurrentChallengeInfo()
					baseCoeff = ((vowCoeff * 55) + (dkCoeff * 35)) / 90
					totalCoeff = baseCoeff
				else
					-- Standard non-DK character
					displayTitle, totalCoeff = Purity:GetCurrentChallengeInfo()
					baseCoeff = totalCoeff
				end

				local modifiers = Purity:GetGameplayModifiers()
				local multiplier = 1.0
				if modifiers.isHardcore then multiplier = multiplier * 2.0 end
				if modifiers.isSelfFound then multiplier = multiplier * 1.5 end
				if modifiers.isSSF then multiplier = multiplier * 2.0 end
				totalCoeff = totalCoeff * multiplier
			end

			CreateLabel("", 1, 10)
			CreateLabel("\nLeaderboard Info", 16, 22)
			
			if totalCoeff == baseCoeff then
				local coeffLabel = CreateLabel(goldColor .. "Coefficient:|r " .. whiteColor .. string.format("%.2f", totalCoeff), 12, 16)
				coeffLabel.frame:SetScript("OnEnter", function(self)
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:AddLine("Score Calculation", 1, 1, 1); GameTooltip:AddLine(" ");
					GameTooltip:AddDoubleLine(displayTitle .. " Coefficient:", string.format("%.2f", baseCoeff), 1, 1, 1, 1, 1, 1); GameTooltip:Show()
				end)
				coeffLabel.frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
			else
				local baseLabel = CreateLabel(goldColor .. "Base Coefficient:|r " .. whiteColor .. string.format("%.2f", baseCoeff), 12, 16)
				local totalLabel = CreateLabel(goldColor .. "Total Coefficient:|r " .. whiteColor .. string.format("%.2f", totalCoeff), 12, 16)
				totalLabel.frame:SetScript("OnEnter", function(self)
					local modifiers = Purity:GetGameplayModifiers()
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:AddLine("Score Calculation", 1, 1, 1); GameTooltip:AddLine(" ")
					GameTooltip:AddDoubleLine("Base Coefficient:", string.format("%.2f", baseCoeff), 1, 1, 1, 1, 1, 1)
					if modifiers.isHardcore then GameTooltip:AddDoubleLine("Hardcore Modifier:", "x2.0", 1, 1, 1, 1, 1, 1) end
					if modifiers.isSelfFound then GameTooltip:AddDoubleLine("Self-Found Modifier:", "x1.5", 1, 1, 1, 1, 1, 1) end
					if modifiers.isSSF then GameTooltip:AddDoubleLine("Solo Self-Found Modifier:", "x2.0", 1, 1, 1, 1, 1, 1) end
					GameTooltip:AddLine(" ", 1, 1, 1, 1, 1, 1)
					GameTooltip:AddDoubleLine("Final Score:", string.format("%.2f", totalCoeff), 1, 0.82, 0, 1, 0.82, 0); GameTooltip:Show()
				end)
				totalLabel.frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
			end

			if (db.challengeStats and next(db.challengeStats)) or (db.challengeTitle == "Fisherman's Folly") then
				CreateLabel("", 1, 10); local statsLabel = CreateLabel("\nFun Stats", 16, 22)
				statsLabel.frame:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:AddLine("Just for Fun!", 1, 1, 1); GameTooltip:AddLine("This is a simple counter of an iconic action for your current challenge.", 0.8, 0.8, 0.8, true); GameTooltip:Show() end)
				statsLabel.frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
				local statValue, statName = nil, nil;
				if db.challengeTitle == "Sacrament of Purity" then statValue = db.challengeStats.lifeTapCasts; statName = "Life Taps Cast:"
				elseif db.challengeTitle == "Grimoire of Purity" then statValue = db.challengeStats.immolateCasts; statName = "Immolates Cast:"
				elseif db.challengeTitle == "Brand of Purity" then statValue = db.challengeStats.chargeInterceptCasts; statName = "Charges/Intercepts:"
				elseif db.challengeTitle == "Bulwark of Purity" then statValue = db.challengeStats.blocks; statName = "Successful Blocks:"
				elseif string.find(db.challengeTitle or "", "Tome of Purity") then
					statValue = db.challengeStats and db.challengeStats.primarySpellCasts or 0; local spec = db.mageData and db.mageData.specialization
					if spec == "Fire" then statName = "Fireballs Cast:"
					elseif spec == "Frost" then statName = "Frostbolts Cast:"
					elseif spec == "Arcane" then statName = "Arcane Missiles Cast:"
					else statName = "Primary Spells Cast:" end
				elseif db.challengeTitle == "Testament of Purity" then statValue = db.challengeStats.smiteCasts; statName = "Smites Cast:"
				elseif db.challengeTitle == "Covenant of Purity" then statValue = db.challengeStats.mindFlayCasts; statName = "Mind Flays Channeled:"
				elseif db.challengeTitle == "Oath of Purity" then statValue = db.challengeStats.holyLightCasts; statName = "Holy Lights Cast:"
				elseif db.challengeTitle == "Libram of Purity" then statValue = db.challengeStats.exorcismCasts; statName = "Exorcisms Cast:"
				elseif db.challengeTitle == "Communion of Purity" then statValue = db.challengeStats.lightningBoltCasts; statName = "Lightning Bolts Cast:"
				elseif db.challengeTitle == "Flame of Purity" then statValue = db.challengeStats.fireSpellCasts; statName = "Fire Spells Cast:"
				elseif db.challengeTitle == "Pact of Purity" then statValue = db.challengeStats.shapeshiftCasts; statName = "Bear Form Shifts:"
				elseif db.challengeTitle == "Astrolabe of Purity" then statValue = db.challengeStats.celestialCasts; statName = "Celestial Spells Cast:"
				elseif db.challengeTitle == "Contract of Purity" then statValue = db.challengeStats.sinisterStrikeCasts; statName = "Sinister Strikes:"
				elseif db.challengeTitle == "Foil of Purity" then statValue = db.challengeStats.riposteCasts; statName = "Ripostes:"
				elseif db.challengeTitle == "Bond of Purity" then statValue = db.challengeStats.mendPetCasts; statName = "Mend Pet Casts:"
				elseif db.challengeTitle == "Quiver of Purity" then statValue = db.challengeStats.aimedShotCasts; statName = "Aimed Shots Fired:"
				elseif db.challengeTitle == "The Ascetic's Path" then statValue = db.challengeStats.forbiddenItemsSold; statName = "Potential Upgrades Sold:"
				elseif db.challengeTitle == "The Drunken Master" then
					statName = "Money Spent on Drinks:"; local moneySpent = (db.challengeStats and db.challengeStats.moneySpent) or 0
					local gold = math.floor(moneySpent / 10000); local silver = math.floor((moneySpent % 10000) / 100); local copper = moneySpent % 100; local moneyString = ""
					if gold > 0 then moneyString = moneyString .. gold .. "|cffffd700g|r " end
					if silver > 0 or gold > 0 then moneyString = moneyString .. silver .. "|cffc7c7cfs|r " end
					moneyString = moneyString .. copper .. "|cffeda55fc|r"; statValue = moneyString
				elseif db.challengeTitle == "Ashes of Purity" then statValue = db.challengeStats.deathCoils; statName = "Death Coils Cast:"
				elseif db.challengeTitle == "Sigil of Purity" then statValue = db.challengeStats.obliterates; statName = "Obliterates:"
				elseif db.challengeTitle == "Phylactery of Purity" then statValue = db.challengeStats.scourgeStrikes; statName = "Scourge Strikes:"
				end
				if statName and statValue then CreateLabel(goldColor .. statName .. "|r " .. whiteColor .. statValue, 12, 16) end
				if db.challengeTitle == "Fisherman's Folly" then
					local fishCount = (db.challengeStats and db.challengeStats.totalCatches) or 0
					local trunkCount = (db.challengeStats and db.challengeStats.trunksFished) or 0
					CreateLabel(goldColor .. "Total Catches:|r " .. whiteColor .. fishCount, 12, 16)
					CreateLabel(goldColor .. "Trunks Fished:|r " .. whiteColor .. trunkCount, 12, 16)
				end
			end
		end)
	end
end