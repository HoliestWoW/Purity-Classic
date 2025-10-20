-- Purity AddOn - Mage Module (Definitive Version - Audited with Transport Spells)

if not Purity then
    return
end

local learnableFireSpells = {
    --- Fireball (11 Ranks) ---
    [133] = true, [143] = true, [145] = true, [3140] = true, [8400] = true, [8401] = true, [8402] = true, [10148] = true, [10149] = true, [10150] = true, [10151] = true,
    --- Fire Blast (7 Ranks) ---
    [2136] = true, [2137] = true, [2138] = true, [8403] = true, [8404] = true, [8405] = true, [10152] = true,
    --- Flamestrike (6 Ranks) ---
    [2120] = true, [2121] = true, [8422] = true, [8423] = true, [10215] = true, [10216] = true,
    --- Scorch (7 Ranks) ---
    [2948] = true, [8444] = true, [8445] = true, [8446] = true, [10197] = true, [10198] = true, [10199] = true,
    --- Pyroblast (7 Ranks) ---
    [11366] = true, [12505] = true, [18809] = true, [18810] = true, [18811] = true, [18812] = true, [18813] = true,
    --- Fire Ward (6 Ranks) ---
    [543] = true, [8457] = true, [8458] = true, [10223] = true, [10224] = true, [10225] = true,
    --- Combustion (1 Rank) ---
    [11129] = true,
}

local learnableFrostSpells = {
    --- Frostbolt (10 Ranks) ---
    [116] = true, [205] = true, [837] = true, [7322] = true, [8406] = true, [8407] = true, [8408] = true, [10179] = true, [10180] = true, [10181] = true,
    --- Frost Nova (4 Ranks) ---
    [122] = true, [865] = true, [8412] = true, [10230] = true,
    --- Frost Armor / Ice Armor (7 Ranks Total) ---
    [168] = true, [7321] = true, [8461] = true, [8462] = true, -- Frost Armor R1-4
    [7302] = true, [10219] = true, [10220] = true,           -- Ice Armor R1-3
    --- Blizzard (6 Ranks) ---
    [10] = true, [6141] = true, [8427] = true, [10185] = true, [10186] = true, [10187] = true,
    --- Cone of Cold (5 Ranks) ---
    [120] = true, [8492] = true, [10159] = true, [10160] = true, [10161] = true,
    --- Frost Ward (6 Ranks) ---
    [6143] = true, [8464] = true, [8465] = true, [10175] = true, [10176] = true, [10177] = true,
    --- Ice Block (1 Rank) ---
    [11958] = true,
}

local learnableArcaneSpells = {
    --- Arcane Missiles (7 Ranks) ---
    [5143] = true, [5144] = true, [5145] = true, [8416] = true, [8417] = true, [10207] = true, [10208] = true,
    --- Arcane Explosion (6 Ranks) ---
    [1449] = true, [8432] = true, [8433] = true, [10203] = true, [10204] = true, [10205] = true,
    --- Arcane Intellect (5 Ranks) ---
    [1459] = true, [1460] = true, [1461] = true, [3158] = true, [10156] = true,
    --- Arcane Brilliance (1 Rank) ---
    [23028] = true,
    --- Mage Armor (3 Ranks) ---
    [6117] = true, [10221] = true, [10222] = true,
    --- Mana Shield (6 Ranks) ---
    [1463] = true, [8494] = true, [8495] = true, [10191] = true, [10192] = true, [10193] = true,
    --- Conjuration Spells ---
    [587] = true, [597] = true, [598] = true, [990] = true, [10144] = true, [10145] = true, -- Conjure Food (Ranks 1-6)
    [5504] = true, [5505] = true, [5506] = true, [6127] = true, [10138] = true, [10139] = true, [10140] = true, -- Conjure Water (Ranks 1-7)
    --- Teleportation Spells ---
    [3561] = true, [3562] = true, [3565] = true, [3567] = true, [3563] = true, [3566] = true, -- Teleports
    [10059] = true, [11416] = true, [11417] = true, [11418] = true, [11419] = true, [11420] = true, -- Portals
    --- Misc Arcane ---
    [1008] = true, [8453] = true, [8454] = true, [8455] = true, [10168] = true, -- Amplify Magic
    [604] = true, [8449] = true, [8450] = true, [10173] = true, [10174] = true, -- Dampen Magic
    [305] = true, -- Detect Magic
    [475] = true,  -- Remove Lesser Curse
    [118] = true, [12824] = true, [12825] = true, [12826] = true, -- Polymorph
    [1953] = true, -- Blink
    [130] = true,  -- Slow Fall
    [2139] = true, [23023] = true, [23024] = true, -- Counterspell
    [12051] = true, -- Evocation
}

local MageModule = {
    challengeName = "Tome of Purity",
    description = "Choose a tome to dedicate yourself to a single school of magic, forsaking all others. This decision is permanent.",
    specializations = {
        { name = "Fire",   title = "Burnt Tome of Purity",    buttonText = "Burnt Tome (Fire)",    color = "|cffff4444" },
        { name = "Frost",  title = "Frozen Tome of Purity",   buttonText = "Frozen Tome (Frost)",  color = "|cff55ccff" },
        { name = "Arcane", title = "Crackling Tome of Purity", buttonText = "Crackling Tome (Arcane)", color = "|cffcc66ff" }
    }
}

function MageModule:InitializeOnPlayerEnterWorld()
    local db = Purity:GetDB()
    if not db.mageData then db.mageData = {} end
    self.chosenSpec = db.mageData.specialization
    self:RegisterEvents() -- This will set up our new event listeners
end

function MageModule:RegisterEvents()
    -- Create a frame to listen for our events
    if not self.eventFrame then
        self.eventFrame = CreateFrame("Frame")
    end
    
    self.eventFrame:UnregisterAllEvents() -- Clear any old events
    
    -- Register the event for standard casts (Fireball, Frostbolt)
    self.eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    -- Register the event for channeled casts (Arcane Missiles)
    self.eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")

    -- ############# THIS IS THE CORRECTED SCRIPT #############
    self.eventFrame:SetScript("OnEvent", function(frame, event, ...)
        local unit, spellId
        unit = ... -- The first argument is always the unit ID

        if event == "UNIT_SPELLCAST_SUCCEEDED" then
            -- For this event, the spell ID is the 6th argument
            local _, _, _, _, _, id = ...
            spellId = id
        elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
            -- For this event, the spell ID is the 3rd argument
            local _, _, id = ...
            spellId = id
        end
        
        if spellId then
            self:EventHandler(event, unit, spellId)
        end
    end)
end

function MageModule:UnregisterEvents()
    if self.eventFrame then
        self.eventFrame:UnregisterAllEvents()
    end
end

function MageModule:SaveData()
    local db = Purity:GetDB()
    if Purity.tempSelectedSpec and Purity.tempSelectedSpec.name then
        if not db.mageData then db.mageData = {} end
        db.mageData.specialization = Purity.tempSelectedSpec.name
        self.chosenSpec = Purity.tempSelectedSpec.name
        db.challengeTitle = Purity.tempSelectedSpec.title or self.challengeName
    end
end

function MageModule:GetChallengeSpecifier()
    return self.chosenSpec or nil
end

function MageModule:GetRulesText()
    local currentDB = Purity:GetDB()
    local chosenSpecName = currentDB.mageData and currentDB.mageData.specialization
    local chosenSpec
    if chosenSpecName then
        for _, spec in ipairs(MageModule.specializations) do
            if spec.name == chosenSpecName then
                chosenSpec = spec
                break
            end
        end
    elseif Purity.tempSelectedSpec then
        chosenSpec = Purity.tempSelectedSpec
    end
    if not chosenSpec then
        return { "|cffffd100Key Prohibitions:|r", "|cff261A0D  • Once a school is chosen, you may NOT use spells or talents from the other two schools.|r", "|cff261A0D  • You may NOT use your starting spells if they do not match your chosen school.|r", " ", "|cffffd100Challenge Conditions:|r", "|cff261A0D  • Must be started on a level 1 Mage.|r", "|cff261A0D  • Must be accepted before leveling to 2.|r", "|cff261A0D  • An uptime of at least 96.0% must be maintained.|r" }
    else
        local statusMessage
        if currentDB.specialization then statusMessage = chosenSpec.color .. "The " .. chosenSpec.title .. " is bound to you.|r" else statusMessage = chosenSpec.color .. "You pick up the " .. chosenSpec.title .. ". It will be bound to you if you Accept.|r" end
        local rules = { statusMessage, " ", "|cffffd100Key Prohibitions:|r", "|cff261A0D  • You may ONLY use spells and talents from the " .. chosenSpec.name .. " school.|r" }
        if chosenSpec.name ~= "Fire" then table.insert(rules, "|cff261A0D  • You may NOT use your starting Fireball spell or learn new Fire spells.|r") end
        if chosenSpec.name ~= "Frost" then table.insert(rules, "|cff261A0d  • You may NOT use your starting Frost Armor spell or learn new Frost spells.|r") end
        if chosenSpec.name ~= "Arcane" then table.insert(rules, "|cff261A0D  • You may NOT learn any Arcane spells.|r") end
        table.insert(rules, " ") table.insert(rules, "|cffffd100Challenge Conditions:|r") table.insert(rules, "|cff261A0D  • Must be started on a level 1 Mage.|r") table.insert(rules, "|cff261A0D  • Must be accepted before leveling to 2.|r") table.insert(rules, "|cff261A0D  • An uptime of at least 96.0% must be maintained.|r")
        return rules
    end
end

function MageModule:IsSpellForbidden(spellId)
    if not spellId then return false end
    local currentDB = Purity:GetDB()
    local chosenSpec = currentDB.mageData and currentDB.mageData.specialization
    if not chosenSpec then return false end
    if chosenSpec == "Fire" then
        if learnableFrostSpells[spellId] or learnableArcaneSpells[spellId] then return true end
    elseif chosenSpec == "Frost" then
        if learnableFireSpells[spellId] or learnableArcaneSpells[spellId] then return true end
    elseif chosenSpec == "Arcane" then
        if learnableFireSpells[spellId] or learnableFrostSpells[spellId] then return true end
    end
    return false
end

function MageModule:IsTalentForbidden(tabIndex)
    if not tabIndex then return false end
    
    local currentDB = Purity:GetDB()
    local chosenSpec = currentDB.mageData and currentDB.mageData.specialization
    if not chosenSpec then return false end

    local allowedTabIndex
    if chosenSpec == "Arcane" then
        allowedTabIndex = 1
    elseif chosenSpec == "Fire" then
        allowedTabIndex = 2
    elseif chosenSpec == "Frost" then
        allowedTabIndex = 3
    end

    if allowedTabIndex and tabIndex ~= allowedTabIndex then
        return true
    end

    return false
end

function MageModule:EventHandler(event, unit, spellId)
    if unit ~= "player" or not spellId then return end
    
    local db = Purity:GetDB()
    if not db or not db.isOptedIn then return end

    local chosenSpec = db.mageData and db.mageData.specialization
    if not chosenSpec then return end
    
    local isPrimarySpell = false

    if chosenSpec == "Arcane" and event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        local arcaneSpells = { [5143]=true, [5144]=true, [5145]=true, [8416]=true, [8417]=true, [10207]=true, [10208]=true }
        if arcaneSpells[spellId] then
            isPrimarySpell = true
        end
    elseif (chosenSpec == "Fire" or chosenSpec == "Frost") and event == "UNIT_SPELLCAST_SUCCEEDED" then
        local fireSpells = { [133]=true, [143]=true, [145]=true, [3140]=true, [8400]=true, [8401]=true, [8402]=true, [10148]=true, [10149]=true, [10150]=true, [10151]=true }
        local frostSpells = { [116]=true, [205]=true, [837]=true, [7322]=true, [8406]=true, [8407]=true, [8408]=true, [10179]=true, [10180]=true, [10181]=true }
        if chosenSpec == "Fire" and fireSpells[spellId] then
            isPrimarySpell = true
        elseif chosenSpec == "Frost" and frostSpells[spellId] then
            isPrimarySpell = true
        end
    end
    
    if isPrimarySpell then
        if not db.challengeStats then db.challengeStats = {} end
        db.challengeStats.primarySpellCasts = (db.challengeStats.primarySpellCasts or 0) + 1
        
        if _G["PurityCharacterPanel"] and _G["PurityCharacterPanel"]:IsShown() then
            UpdateCharacterPurity()
        end
    end
end

Purity.ClassModules = Purity.ClassModules or {}
Purity.ClassModules.MAGE = MageModule