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

---

## Global Challenges

### The Ascetic's Path

A challenge of self-denial where you must limit your reliance on material possessions by choosing one of three paths.

* **Path of Humility (EASY):** Only items of Common (white) quality or lower may be equipped.
* **Path of Endurance (MEDIUM):** No armor may be worn. Weapons and shields are permitted.
* **Path of the Unburdened (HARD):** No items may be equipped whatsoever.

### Fisherman's Folly

The devoted angler. You have forsaken all worldly possessions in pursuit of the perfect catch.

* **Key Prohibition:** You may ONLY equip items that you have personally fished from the water (vendor-purchased fishing poles are an exception).

---

## Class-Specific Challenges

### Druid

* **Pact of Purity: The Avenger of Nature**
    * **Description:** Forsake the celestial balance of the moon, relying only on feral instincts and restorative powers.
    * **Criteria:**
        * You may not kill any creature of the 'Beast' type.
        * After level 10, you may not use any Balance spells.
        * You may not equip any Leather armor.

* **Astrolabe of Purity: The Celestial Weaver**
    * **Description:** Forsake your primal connection to focus on a cosmic balance, alternating between Nature and Arcane damaging spells.
    * **Criteria:**
        * You may not use Bear Form or Cat Form.
        * You may not learn or use any Restoration healing spells.
        * You must alternate between Nature and Arcane damaging spells.

### Hunter

* **Bond of Purity: The Primal Savage**
    * **Description:** Forsake cowardly ranged weapons and clever traps to fight in melee side-by-side with your pet.
    * **Criteria:**
        * You may not equip any ranged weapons or use ranged shots.
        * Your pet must be active during all combat.

* **Quiver of Purity: The Lone Wolf**
    * **Description:** Face the world on your own, relying only on marksmanship. No pets or melee weapons allowed.
    * **Criteria:**
        * You may not equip any melee weapons or use melee abilities.
        * You may not use a Hunter Pet or complete the Tame Beast quest.

### Mage - The Tome of Purity

* **Description:** Choose a tome to dedicate yourself to a single school of magic, forsaking all others. This decision is permanent.
* **Key Prohibition:** You may ONLY use spells and talents from your chosen school of magic (Fire, Frost, or Arcane).

### Paladin

* **Oath of Purity: The Selfless Shield**
    * **Description:** Forsake retribution and personal glory, vowing to never be the aggressor.
    * **Criteria:**
        * Do not initiate combat; enemies must strike first.
        * No learning or using Retribution spells or talents.

* **Libram of Purity: The Undead Bane**
    * **Description:** Dedicate your sacred might solely to purging the impure Undead from the world.
    * **Key Prohibition:** You may ONLY land the killing blow on creatures of the 'Undead' type.

### Priest - The Testament of Purity

* **Description:** A true vessel of the Light, sworn off the corrupting whispers of the Shadow.
* **Key Prohibitions:**
    * No weapons or physical attacks (including wands).
    * No learning or using Shadow magic spells or talents.
    * No killing Humanoid creatures.

### Rogue

* **Contract of Purity: The Honorable Duelist**
    * **Description:** Forsake the shadows and underhanded tactics. Every fight is a fair duel.
    * **Criteria:**
        * You may not initiate combat from Stealth.
        * You may not learn or use any Poisons.
        * You may not use "cheap shots" like Backstab, Gouge, Kidney Shot, etc.

* **Foil of Purity: A master of single-blade combat**
    * **Description:** Forsake the use of an off-hand weapon and all ranged weapons.
    * **Criteria:**
        * You may not equip any item in your off-hand slot.
        * You may not equip any ranged weapon.

### Shaman - Communion of Purity

* **Description:** The Spirit Walker. Your power flows purely from your spells and maintaining active totems in combat. No weapons of any kind.
* **Key Prohibitions:**
    * You may NOT equip any weapons of any kind.
    * You must always maintain at least one active totem while in combat (after totems are unlocked).

### Warlock - Grimoire of Purity

* **Description:** A crazed demonologist focused on fire, brimstone, and demons. Souls are fuel for summoning and nothing else.
* **Key Prohibitions:**
    * No learning or using forbidden spells (Shadow, most Curses, etc.).
    * No spending points in the Affliction talent tree.
    * Soul Shards may ONLY be used to summon or subjugate demons.
    * Healthstones and Soulstones are forbidden.

### Warrior

* **Brand of Purity: The Berserker**
    * **Description:** No shields or defensive stance. All combat must be initiated with Charge.
    * **Criteria:**
        * You may NOT use shields or Defensive Stance.
        * After level 4, you must initiate combat with Charge.
        * After level 20, equipping two-handed weapons is forbidden.

* **Bulwark of Purity: The Ardent Protector**
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
            |-- Purity_Druid.lua
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