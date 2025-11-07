# Purity Challenge AddOn for World of Warcraft: Classic Era

Purity is a hardcore challenge addon for World of Warcraft: Classic Era that allows players to opt into strict, class-specific and global challenges. These challenges are designed to be completed from level 1 to 60, testing your knowledge of the game and forcing you to play in new and interesting ways.

The addon is lightweight, modular, and designed to provide a verifiable path for proving your accomplishment.

## Links

* [Download on CurseForge](https://www.curseforge.com/wow/addons/purity)
* [Join our Discord Community](https://discord.gg/5m74Kw27AE)
* **[Official Purity Challenge Leaderboard & Verification Website](https://purity.pythonanywhere.com/)**

## Features

* **Global & Class-Specific Challenges:** Unique, thematic challenges available to all players, plus specific vows for all nine original classes.
* **Live Player Roster:** See other Purity players on your server, their class, level, and current challenge status in real-time. The roster automatically refreshes when you view it.
* **Specialization Paths:** Many challenges require you to choose a specific sub-path, further restricting gameplay and offering diverse experiences.
* **Real-Time Violation Monitoring:** The addon actively monitors your actions, talents, and spells to ensure the rules are being followed. A single violation fails the challenge permanently for that character.
* **In-Game Status UI:** Use `/purity status` to view your current standing, uptime, and other important information.
* **Web-Based Verification System:** Upon challenge completion, a unique verification code is generated. **Post this code on our official [Verification Website](https://purity.pythonanywhere.com/) to have your run automatically verified and posted to the public leaderboard.**
* **Extensible Design:** The addon is built to be expanded with new class and global modules.

## How to Use

The addon will automatically present the challenge selection screen to you at level 1. If you decline, you can use the `/purity` slash commands to interact with the UI.

* `/purity` : Shows a summary of your current challenge status in the chat window.
* `/purity status` : Opens the main interface to the Status tab.
* `/purity rules` : Opens the main interface to the Rules tab.
* `/purity roster` : Opens the Roster tab and automatically refreshes the list of online players.
* `/purity verify` : Opens the verification window with your completion code.
* `/purity bloodbar` : Detaches the blood bar for Blood Mage's Bargain challenge players from unit frame to drag and place where desired.
* `/purity bloodlog` : Gives you a draggable, resizable 'combat log' of Blood spent and lost.

---

## Global Challenges

### The Ascetic's Path

A challenge of self-denial where you must limit your reliance on material possessions by choosing one of three paths.

* **Path of Humility (EASY):** Only items of Common (white) quality or lower may be equipped.
* **Path of Endurance (MEDIUM):** No armor may be worn. Weapons and shields are permitted.
* **Path of the Unburdened (HARD):** No items may be equipped whatsoever.

### The Blood Mage's Bargain

You have made a pact for power, allowing you to fuel your abilities with your own life force. Your vitality is your true power, but this pact is a double-edged sword: the more you heal and protect your life force, the weaker your bargain becomes.

* **The Bargain:**
    * Your life force is a resource for combat, represented by a Blood Pool.
    * All abilities, attacks, and damage taken deplete your Blood Pool.
    * If your Blood Pool is depleted, your vow is broken.
* **The Price of Weakness:**
    * After restoring your own health, you become 'Weakened' for 15 seconds.
    * While 'Weakened', all Blood Pool costs are doubled.

### Fisherman's Folly

The devoted angler. You have forsaken all worldly possessions in pursuit of the perfect catch.

* **Key Prohibition:** You may ONLY equip items that you have personally fished from the water (vendor-purchased fishing poles are an exception).

### The Drunken Master

The Way of the Staggering Fist. Years spent as the town drunk were not wasted. Countless barroom brawls have honed your clumsy stumbles into an unpredictable martial art. Your enemies see a swaying fool, but you are a master of chaotic grace, turning staggering into evasion and slurred shouts into battle cries. To fight with a clear head would be to forget your training; only in the haze of ale can you find true focus.

* **The Path of the Citizen (Levels 1-20):**
    * Before level 21, you must prove yourself as a productive citizen.
    * You must achieve a skill of 150 in at least TWO primary professions.
* **The Drunken Master (Level 21+):**
    * At level 21, your professions are checked. If you fail, the challenge ends.
    * From level 21 on, you must be 'Drunk' or 'Smashed' to initiate combat.

---

## Class-Specific Challenges

### Druid

* **Pact of Purity**
    * **Description:** Forsake the celestial balance of the moon, relying only on feral instincts and restorative powers.
    * **Criteria:**
        * You may not kill any creature of the 'Beast' type.
        * After level 10, you may not use any Balance spells.
        * You may not equip any Leather armor.

* **Astrolabe of Purity**
    * **Description:** Forsake your primal connection to focus on a cosmic balance, alternating between Nature and Arcane damaging spells.
    * **Criteria:**
        * You may not use Bear Form or Cat Form.
        * You may not learn or use any Restoration healing spells.
        * You must alternate between Nature and Arcane damaging spells.

### Hunter

* **Bond of Purity**
    * **Description:** Forsake cowardly ranged weapons and clever traps to fight in melee side-by-side with your pet.
    * **Criteria:**
        * You may not equip any ranged weapons or use ranged shots.
        * Your pet must be active during all combat.

* **Quiver of Purity**
    * **Description:** Face the world on your own, relying only on marksmanship. No pets or melee weapons allowed.
    * **Criteria:**
        * You may not equip any melee weapons or use melee abilities.
        * You may not use a Hunter Pet or complete the Tame Beast quest.

### Mage

* **Tome of Purity**
    * **Description:** Choose a tome to dedicate yourself to a single school of magic (Burnt, Frozen, or Crackling), forsaking all others. This decision is permanent.
* **Key Prohibition:** You may ONLY use spells and talents from your chosen school of magic (Fire, Frost, or Arcane).

### Paladin

* **Oath of Purity**
    * **Description:** Forsake retribution and personal glory, vowing to never be the aggressor.
    * **Criteria:**
        * Do not initiate combat; enemies must strike first.
        * No learning or using Retribution spells or talents.

* **Libram of Purity**
    * **Description:** Dedicate your sacred might solely to purging the impure Undead from the world.
    * **Key Prohibition:** You may ONLY land the killing blow on creatures of the 'Undead' type.

### Priest

* **Testament of Purity**
    * **Description:** A true vessel of the Light, this Priest has sworn off the corrupting and seductive whispers of the Shadow. Their Purity is a testament to their unwavering faith, relying solely on Holy and Disciplinary magic to aid their allies and smite their foes.
    * **Key Prohibitions:**
        * No weapons or physical attacks (including wands).
        * No learning or using Shadow magic spells or talents.
        * No killing Humanoid creatures.
        * Gaining experience for any Humanoid kills will break your vow.

* **Covenant of Purity**
    * **Description:** Forsake the Light's protection and healing. You must rely on the Shadow for survival, and on raw power for destruction.
    * **Key Prohibitions:**
        * No using Discipline spells.
        * With the exception of Smite, no other Holy spells may be used.
        * No Holy damage wands.

### Rogue

* **Contract of Purity**
    * **Description:** Forsake the shadows and underhanded tactics. Every fight is a fair duel.
    * **Criteria:**
        * You may not initiate combat from Stealth.
        * You may not learn or use any Poisons.
        * You may not use "cheap shots" like Backstab, Gouge, Kidney Shot, etc.

* **Foil of Purity**
    * **Description:** A master of single-blade combat, forsaking the use of an off-hand weapon and all ranged weapons.
    * **Criteria:**
        * You may not equip any item in your off-hand slot.
        * You may not equip any ranged weapon.

### Shaman

* **Communion of Purity**
    * **Description:** The Spirit Walker. Your power flows purely from your spells and maintaining active totems in combat. No weapons of any kind.
    * **Key Prohibitions:**
        * You may NOT equip any weapons of any kind.
        * You must always maintain at least one active totem while in combat (after totems unlocked).
        * You must learn your first totem spell and complete the quest before reaching Level 6.

* **Flame of Purity**
    * **Description:** You begin as a normal Shaman, but at level 10 your path changes. Your spirit awakens to the flame, forsaking all other elements. From that moment on, you may only use Fire spells, Fire totems, and physical attacks.
    * **The Awakening:**
        * From level 1 to 9, you are free to use any Shaman ability.
        * Upon reaching Level 10, your vow begins and the following rules apply for the remainder of the challenge:
    * **Level 10+ Prohibitions:**
        * Only Fire spells may be cast (including weapon imbuements).
        * Only Fire totems may be used.

### Warlock

* **Grimoire of Purity**
    * **Description:** A crazed demonologist focused on fire, brimstone, and demons. Souls are fuel for summoning and nothing else.
    * **Key Prohibitions:**
        * No learning or using forbidden spells (Shadow, Curses, etc.).
        * No spending points in the Affliction talent tree.
        * No non-Fire wands may be equipped or used.
    * **Special Rules:**
        * Soul Shards may ONLY be used to summon or subjugate demons.
        * Healthstones and Soulstones are FORBIDDEN.
        * Drain Soul (Rank 1) is the only rank allowed.
        * Drain Soul may only be cast on targets below 20% health.

* **Sacrament of Purity**
    * **Description:** Forsake demonic pacts and all external mana sources (drinks, potions). You must rely on your own life force, using Life Tap and Drain Mana as your only way to restore mana, and then regain your health through drains and crafted Healthstones.
    * **Key Prohibitions:**
        * No demon pets may be summoned (Felsteed is allowed).
        * No drinking or using mana potions to restore mana.
        * No spending points in the Demonology talent tree.
    * **Challenge Conditions:**
        * Mana must only be regained passively, via Life Tap, or via Drain Mana.

### Warrior

* **Brand of Purity**
    * **Description:** No shields or defensive stance. All combat must be initiated with Charge.
    * **Criteria:**
        * You may NOT use shields or Defensive Stance.
        * After level 4, you must initiate combat with Charge.
        * After level 20, equipping two-handed weapons is forbidden.

* **Bulwark of Purity**
    * **Description:** Forsake two-handed weapons and the Fury talent tree to become a bastion of defense.
    * **Criteria:**
        * You may NOT equip Two-Handed weapons at any time.
        * You may NOT allocate any talent points in the Fury talent tree.

---

## Installation

1.  Download the latest version from [CurseForge](https://www.curseforge.com/wow/addons/purity).
2.  Unzip the package.
3.  Copy the `Purity` folder into your `World of Warcraft/_classic_era_/Interface/AddOns/` directory. The final structure should look like this:

    ```
    .../Interface/AddOns/
        |-- Purity/
            |-- Purity.lua
            |-- Purity_Ascetic.lua
            |-- Purity_BloodMage.lua
            |-- Purity_Druid.lua
            |-- Purity_Drunk.lua
            |-- Purity_Fishing.lua
            |-- Purity_Hunter.lua
            |-- Purity_Mage.lua
            |-- Purity_Paladin.lua
            |-- Purity_Priest.lua
            |-- Purity_Rogue.lua
            |-- Purity_Shaman.lua
            |-- Purity_Warlock.lua
            |-- Purity_Warrior.lua
            |-- README.md
            |-- LICENSE
    ```

## License

This addon is licensed under the MIT License. See the `LICENSE` file for more details.