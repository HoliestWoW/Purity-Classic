-- Purity AddOn - Warlock Module

if not Purity then
    return
end

local WarlockModule = {
    challenges = {}
}


local GrimoireOfPurity = {
    id = "WARLOCK_GRIMOIRE",
    challengeName = "Grimoire of Purity",
    description = function()
        return "A crazed demonologist focused on fire, brimstone, and demons. Souls are fuel for summoning and nothing else."
    end,
    needsWeaponWarning = true,

    _forbiddenSpellIDs = {
        [686]=true,[695]=true,[705]=true,[1088]=true,[1106]=true,[7641]=true,[11659]=true,[11660]=true,[17942]=true,[17943]=true, -- Shadow Bolt
        [172]=true,[6222]=true,[6223]=true,[7648]=true,[11671]=true,[11672]=true, -- Corruption
        [980]=true,[1014]=true,[6217]=true,[11711]=true,[11712]=true,[11713]=true, -- Curse of Agony
        [689]=true,[699]=true,[709]=true,[7651]=true,[11699]=true,[11700]=true, -- Drain Life
        [8288]=true,[8289]=true,[11675]=true, -- Drain Soul (Ranks 2+)
        [5138]=true,[6226]=true,[11703]=true,[11704]=true, -- Drain Mana
        [17877]=true,[18867]=true,[18868]=true,[18869]=true,[18870]=true,[18871]=true, -- Shadowburn
        [6229]=true,[11739]=true,[11740]=true, -- Shadow Ward
        [18265]=true,[18879]=true,[18880]=true,[18881]=true, -- Siphon Life
        [6789]=true,[17925]=true,[17926]=true, -- Death Coil
        [17862]=true,[17937]=true, -- Curse of Shadow
        [6353]=true,[17924]=true, -- Soul Fire
        [18220]=true,[18937]=true, -- Dark Pact
        [6201]=true,[6202]=true,[5699]=true,[11729]=true,[11730]=true, -- Create Healthstone
        [693]=true,[20752]=true,[20755]=true,[20756]=true, -- Create Soulstone
        [6366]=true,[17951]=true,[17952]=true,[17953]=true, -- Create Firestone
        [2362]=true,[17727]=true, -- Create Spellstone
    },
    _summoningSpellIDs = {
        [688] = true, [697] = true, [691] = true, [712] = true, -- Summons
        [1098] = true, [11725] = true, [11726] = true, -- Subjugate Demon
    },
    _allowedFireWandIDs = {
        [5069]=true,[5242]=true,[5356]=true,[5212]=true,[5326]=true,[5241]=true,[5208]=true,[5240]=true,[5243]=true,[8071]=true,[5092]=true,[5250]=true,[5210]=true,[5246]=true,[8184]=true,[6806]=true,[6729]=true,[5236]=true,[5253]=true,[5249]=true,[5213]=true,[5215]=true,[13064]=true,[5238]=true,[9483]=true,[11748]=true,[13004]=true,[16993]=true,[15282]=true,[17077]=true,[19367]=true,
    },

    IsSpellForbidden = function(self, spellId)
        return self._forbiddenSpellIDs[spellId] or false
    end,

    IsTalentForbidden = function(self, tabIndex)
        return tabIndex == 1
    end,

    isWeaponAllowed = function(self, itemLink)
        if not itemLink then return true end
        local itemID = tonumber(string.match(itemLink, "item:(%d+)"))
        if not itemID then return true end
		local _, _, _, _, _, itemType, itemSubType = GetItemInfo(itemLink)

        if itemSubType == "Fishing Pole" then return true end
        if itemType == "Weapon" and itemSubType ~= "Wands" then return true end
        if itemSubType == "Wands" then return self._allowedFireWandIDs[itemID] == true end
        return true
    end,

    IsItemForbidden = function(self, itemLink)
        if not itemLink then return false end
        if GetItemInfo(itemLink) then
            local _, _, _, _, _, itemType, itemSubType = GetItemInfo(itemLink)
            if itemType == "Weapon" and itemSubType == "Wands" then
                return not self:isWeaponAllowed(itemLink)
            end
        end
        return false
    end,

    GetRulesText = function(self)
        return {
            "|cffffd100Key Prohibitions:|r",
            "|cff261A0D  • No learning or using forbidden spells (Shadow, Curses, etc.).|r",
            "|cff261A0D  • No spending points in the Affliction talent tree.|r",
            "|cff261A0D  • No non-Fire wands may be equipped or used.|r",
            " ",
            "|cffffd100Special Rules:|r",
            "|cff261A0D  • Soul Shards may |cffFF4500ONLY|r be used to summon or subjugate demons.|r",
            "|cff261A0D  • Healthstones and Soulstones are |cffFF4500FORBIDDEN|r.|r",
            "|cff261A0D  • |cff8788eeDrain Soul (Rank 1)|r is the only rank allowed.|r",
            "|cff261A0D  • |cff8788eeDrain Soul|r may only be cast on targets below 20% health.|r",
			" ",
            "|cffffd100Challenge Conditions:|r",
            "|cff261A0D  • Must be started on a level 1 Warlock.|r",
            "|cff261A0D  • Must be accepted before leveling to 2.|r",
            "|cff261A0D  • An uptime of at least 96.0% must be maintained.|r",
        }
    end,

    EventHandler = function(self, event, ...)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, subEvent, _, sourceGUID, _, _, _, destGUID, _, _, _, spellId, spellName = CombatLogGetCurrentEventInfo()
            if sourceGUID ~= UnitGUID("player") then return end

			if subEvent == "SPELL_CAST_SUCCESS" then
                local immolateIDs = { [348]=true, [707]=true, [1094]=true, [2941]=true, [11665]=true, [11667]=true, [25309]=true, [11668]=true }
                if immolateIDs[spellId] then
                    local db = Purity:GetDB()
                    if not db.challengeStats then db.challengeStats = {} end
                    db.challengeStats.immolateCasts = (db.challengeStats.immolateCasts or 0) + 1
					if _G["PurityCharacterPanel"] and _G["PurityCharacterPanel"]:IsShown() then
                        _G["UpdateCharacterPurity"]()
					end
                end
            end

            if subEvent == "RANGE_DAMAGE" and not self:isWeaponAllowed(GetInventoryItemLink("player", INVSLOT_RANGED)) then
                Purity:Violation("Used a non-Fire wand.")
            elseif (subEvent == "SPELL_CAST_SUCCESS" or subEvent == "SPELL_AURA_APPLIED") then
                if self:IsSpellForbidden(spellId) then
                    Purity:Violation("Used a forbidden spell:\n" .. (spellName or "Unknown Spell"))
                elseif spellId == 1120 then -- Drain Soul (Rank 1)
                    if destGUID and UnitExists(destGUID) and (UnitHealth(destGUID) / UnitHealthMax(destGUID)) > 0.20 then
                        Purity:Violation("Used Drain Soul on a target above 20% health.")
                    end
                end
            elseif (subEvent == "SPELL_SUMMON" or subEvent == "SPELL_CREATE") then
                 local _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, resourceType, amount = CombatLogGetCurrentEventInfo()
                 if resourceType == "SOUL_SHARD" and amount < 0 and not self._summoningSpellIDs[spellId] then
                     Purity:Violation("Used a Soul Shard for a non-summoning spell:\n" .. (spellName or "Unknown Spell"))
                 end
            end
        elseif event == "PLAYER_TALENT_UPDATE" then
            if self:IsTalentForbidden(1) then
                local points = 0
                for i=1,GetNumTalents(1) do local _,_,_,_,p=GetTalentInfo(1,i) points=points+p end
                if points > 0 then Purity:Violation("Allocated points in the forbidden\nAffliction talent tree.") end
            end
        elseif event == "SPELLS_CHANGED" then
            for i=1,GetNumSpellTabs() do
                local _,_,_,n=GetSpellTabInfo(i)
                for j=1,n do
                    local id=GetSpellBookItemInfo(j,"spell")
                    if id and self:IsSpellForbidden(id) then
                        Purity:Violation("Learned a forbidden spell:\n" .. GetSpellInfo(id))
                    end
                end
            end
        end
    end,
}
table.insert(WarlockModule.challenges, GrimoireOfPurity)

local SacramentOfPurity = {
    id = "WARLOCK_SACRAMENT",
    challengeName = "Sacrament of Purity",
    description = function()
        return "Forsake demonic pacts and all external mana sources (drinks, potions). You must rely on your own life force, using Life Tap and Drain Mana as your only way to restore mana, and then regain your health through drains and crafted Healthstones."
    end,
    needsWeaponWarning = false,
	allowedTooltipTypes = { ["Consumable"] = true },

    _forbiddenSpellIDs = {
        [688]=true, -- Summon Imp
        [697]=true, -- Summon Voidwalker
        [691]=true, -- Summon Felhunter
        [712]=true, -- Summon Succubus
        [713]=true, -- Summon Incubus
        [1122]=true, -- Inferno
        [755]=true,[3698]=true,[3699]=true,[3700]=true,[11693]=true,[11694]=true,[11695]=true, -- Health Funnel
        [18220]=true,[18937]=true, -- Dark Pact
    },
    _manaItemSpellIDs = {
        [2455]=true,[3385]=true,[3827]=true,[6149]=true,[13443]=true,[18841]=true,[13444]=true,[2456]=true,[9144]=true,[20007]=true,[18253]=true,[12190]=true,-- Mana Potions
        [23172]=true,[1072]=true,[5350]=true,[159]=true,[1179]=true,[2682]=true,[2288]=true,[17404]=true,[3448]=true,[21072]=true,[1205]=true,[2136]=true,[9451]=true,[19299]=true,[4791]=true,[1708]=true,[10841]=true,[3772]=true,[21217]=true,[1645]=true,[8077]=true,[19300]=true,[21215]=true,[13724]=true,[8766]=true,[8078]=true,--Food/Drink
    },

    IsSpellForbidden = function(self, spellId)
        if not spellId then return false end
        return self._forbiddenSpellIDs[spellId] or self._manaItemSpellIDs[spellId]
    end,

    IsTalentForbidden = function(self, tabIndex)
        return tabIndex == 2
    end,

    isWeaponAllowed = function(self, itemLink)
        return true
    end,

	IsItemForbidden = function(self, itemLink)
		if not itemLink then return false end
		local _, _, _, _, _, _, _, _, _, _, spellId = GetItemSpell(itemLink)
		local itemID = tonumber(string.match(itemLink, "item:(%d+)"))
				if (spellId and self._manaItemSpellIDs[spellId]) or (itemID and self._manaItemSpellIDs[itemID]) then
			return true
		end
		
		return false
	end,

    GetRulesText = function(self)
        return {
            "|cffffd100Key Prohibitions:|r",
            "|cff261A0D  • No demon pets may be summoned (|cff00FF00Felsteed is allowed|r).|r",
            "|cff261A0D  • No drinking or using mana potions to restore mana.|r",
            "|cff261A0D  • No spending points in the Demonology talent tree.|r",
            " ",
            "|cffffd100Challenge Conditions:|r",
            "|cff261A0D  • Mana must only be regained passively, via |cff8788eeLife Tap|r, or via |cff8788eeDrain Mana|r.|r",
            "|cff261A0D  • Must be started on a level 1 Warlock.|r",
            "|cff261A0D  • Must be accepted before leveling to 2.|r",
            "|cff261A0D  • An uptime of at least 96.0% must be maintained.|r",
        }
    end,

    EventHandler = function(self, event, ...)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            local _, subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellId, spellName = CombatLogGetCurrentEventInfo()
            if sourceGUID ~= UnitGUID("player") then return end

            -- Stat tracking for Life Tap
            if subEvent == "SPELL_CAST_SUCCESS" then
                local lifeTapIDs = { [1454]=true, [1455]=true, [1456]=true, [11687]=true, [11688]=true, [11689]=true }
                if lifeTapIDs[spellId] then
                    local db = Purity:GetDB()
                    if not db.challengeStats then db.challengeStats = {} end
                    db.challengeStats.lifeTapCasts = (db.challengeStats.lifeTapCasts or 0) + 1
					if _G["PurityCharacterPanel"] and _G["PurityCharacterPanel"]:IsShown() then
                        _G["UpdateCharacterPurity"]()
                    end
                end
            end

            if (subEvent == "SPELL_CAST_SUCCESS" or subEvent == "SPELL_SUMMON") then
                if self:IsSpellForbidden(spellId) then
                    Purity:Violation("Used a forbidden spell or item:\n" .. (spellName or "Unknown"))
                end
            end
        elseif event == "PLAYER_TALENT_UPDATE" then
            if self:IsTalentForbidden(2) then
                local points = 0
                for i=1,GetNumTalents(2) do local _,_,_,_,p=GetTalentInfo(2,i) points=points+p end
                if points > 0 then
                    local _, treeName = GetTalentTabInfo(2)
                    Purity:Violation("Allocated points in the forbidden\n" .. treeName .. " talent tree.")
                end
            end
        elseif event == "SPELLS_CHANGED" then
            for i=1,GetNumSpellTabs() do
                local _,_,_,n=GetSpellTabInfo(i)
                for j=1,n do
                    local id=GetSpellBookItemInfo(j,"spell")
                    if id and self:IsSpellForbidden(id) then
                        Purity:Violation("Learned a forbidden spell:\n" .. GetSpellInfo(id))
                    end
                end
            end
        end
    end,
}
table.insert(WarlockModule.challenges, SacramentOfPurity)

Purity.ClassModules = Purity.ClassModules or {}
Purity.ClassModules.WARLOCK = WarlockModule