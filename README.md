# Purity Challenge AddOn for World of Warcraft

Purity is a hardcore challenge addon for World of Warcraft (Classic Era, WotLK, and MoP) that allows players to opt into strict, class-specific and global challenges. These challenges are designed to be completed from level 1 to level cap, testing your knowledge of the game and forcing you to play in new and interesting ways.

The addon is modular and designed to provide a verifiable path for proving your accomplishment.

## Links

* [Download on CurseForge](https://www.curseforge.com/wow/addons/purity)
* [Join our Discord Community](https://discord.gg/5m74Kw27AE)
* **[Official Purity Challenge Leaderboard & Verification Website](https://purity.pythonanywhere.com/)**

## Features

* **Global & Class-Specific Challenges:** Unique, thematic challenges available to all players, plus specific vows for all classes (including expansion-specific classes).
* **Live Player Roster:** See other Purity players on your server, their class, level, and current challenge status in real-time. The roster automatically refreshes when you view it.
* **Specialization Paths:** Many challenges require you to choose a specific sub-path or difficulty, further restricting gameplay and offering diverse experiences.
* **Real-Time Violation Monitoring:** The addon actively monitors your actions, talents, and spells to ensure the rules are being followed. A single violation fails the challenge permanently for that character.
* **In-Game Status UI:** Use `/purity status` to view your current standing, uptime, and other important information.
* **Web-Based Verification System:** Upon challenge completion, a unique verification code is generated. **Post this code on our official [Verification Website](https://purity.pythonanywhere.com/) to have your run automatically verified and posted to the public leaderboard.**
* **Extensible Design:** The addon is built to be expanded with new class and global modules.

## How to Use

The addon will automatically present the challenge selection screen to you at level 1. If you decline, you can use the `/purity` slash commands to interact with the UI.

**General Commands:**
* `/purity` : Shows a summary of your current challenge status in the chat window.
* `/purity status` : Opens the main interface to the Status tab.
* `/purity rules` : Opens the main interface to the Rules tab.
* `/purity roster` : Opens the Roster tab and automatically refreshes the list of online players.
* `/purity rankings` : Opens the Rankings tab to see difficulty coefficients.
* `/purity verify` : Opens the verification window with your completion code.
* `/purity options` : Opens the Options menu.
* `/purity requestfrom <PlayerName>` : Manually requests challenge status from a specific player via whisper.

**Challenge-Specific Commands:**
* `/purity bloodbar` : (Blood Mage) Toggles the Blood bar between overlay mode and a separate, movable frame.
* `/purity bloodlog [reset]` : (Blood Mage) Toggles the Blood Log window. Add `reset` to reset its position.
* `/purity glasslog` : (Glass Heart) Toggles the damage log window.
* `/purity drunk` : (Drunken Master) Toggles the Drunken Master status window.

---

## Global Challenges

### The Ascetic's Path
A challenge of self-denial where you must limit your reliance on material possessions by choosing one of three paths.
* **Path of Humility (EASY):** Only items of Common (white) quality or lower may be equipped.
* **Path of Endurance (MEDIUM):** No armor may be worn. Weapons and shields are permitted.
* **Path of the Unburdened (HARD):** No items may be equipped whatsoever.

### The Blood Mage's Bargain
You have made a pact for power, allowing you to fuel your abilities with your own life force.
* **The Bargain:** Your life force is a resource (Blood Pool). All abilities, attacks, and damage taken deplete it. If it hits 0, you fail.
* **The Price:** Healing yourself causes "Sanguine Weakness" for 15s, doubling the blood cost of all abilities.

### The Drunken Master
The Way of the Staggering Fist. You are a master of chaotic grace, fighting best when in a haze of ale.
* **Levels 1-20:** You must achieve a skill of 150 in at least TWO primary professions (The Path of the Citizen).
* **Level 21+:** You must be 'Drunk' or 'Smashed' to initiate combat.

### Fisherman's Folly
The devoted angler. You have forsaken all worldly possessions in pursuit of the perfect catch.
* **Key Prohibition:** You may ONLY equip items that you have personally fished from the water (vendor-purchased fishing poles are an exception).

### The Glass Heart
Your resilience is shattered. While your body appears intact, your tolerance for trauma is significantly reduced. This penalty is permanent.
* **The Rules:** Your Health Bar is replaced by a "Glass Heart" bar. You take significantly increased damage from all sources.
* **Smart Regen:** Natural regeneration is disabled; Spirit-based regeneration only kicks in when not taking damage (or out of combat).
* **Difficulties:**
    * **Hard:** 1.5x Damage Taken.
    * **Extreme:** 2.0x Damage Taken.

---

## Class-Specific Challenges (Classic Era & Onward)

### Druid

* **Pact of Purity: The Avenger of Nature**
    * **Description:** Forsake the celestial balance of the moon, relying only on feral instincts and restorative powers.
    * **Criteria:**
        * You may not kill any creature of the 'Beast' type.
        * After level 10, you may not use any Balance spells.
        * You may not equip any Leather armor.

* **Astrolabe of Purity: The Celestial Weaver**
    * **Description:** Forsake your primal connection to focus on a cosmic balance. You are bound to an Astrolabe that tracks your spellcasting equilibrium.
    * **Criteria:**
        * You may not use Bear Form or Cat Form.
        * You may not learn or use any Restoration healing spells.
        * **The Balance:** Casting Nature spells charges the Astrolabe positively; Arcane spells charge it negatively. You may never hold more than 2 consecutive charges of one type. Overloading the Astrolabe shatters it and fails the challenge.

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

### Mage

* **Tome of Purity**
    * **Description:** Choose a tome to dedicate yourself to a single school of magic, forsaking all others. This decision is permanent.
    * **Criteria:**
        * You may ONLY use spells and talents from your chosen school of magic (Fire, Frost, or Arcane).

* **Conduit of Purity: The Ley-Walker**
    * **Description:** You have forsaken the stationary study of the arcane, becoming a living conduit for the world's latent energy. You draw power only through motion.
    * **Criteria:**
        * **Static Charge:** A custom bar tracks your energy. Moving generates Charge; standing still causes it to decay.
        * **The Cost:** All spells cost Static Charge to cast (paid upfront).
        * **The Vow:** Attempting to cast a spell without enough Static Charge breaks the vow.

### Paladin

* **Oath of Purity: The Selfless Shield**
    * **Description:** Forsake retribution and personal glory, vowing to never be the aggressor.
    * **Criteria:**
        * Do not initiate combat; enemies must strike first.
        * No learning or using Retribution spells or talents.

* **Libram of Purity: The Undead Bane**
    * **Description:** Dedicate your sacred might solely to purging the impure Undead from the world.
    * **Criteria:**
        * You may ONLY land the killing blow on creatures of the 'Undead' type.

### Priest

* **Testament of Purity**
    * **Description:** A true vessel of the Light, sworn off the corrupting whispers of the Shadow.
    * **Criteria:**
        * No weapons or physical attacks (including wands).
        * No learning or using Shadow magic spells or talents.
        * No killing Humanoid creatures.

* **Covenant of Purity**
    * **Description:** Forsake the Light's protection and healing. You must rely on the Shadow for survival.
    * **Criteria:**
        * No using Discipline spells.
        * No using Holy spells (except Smite).
        * No Holy damage wands.

### Rogue

* **Contract of Purity: The Honorable Duelist**
    * **Description:** Forsake the shadows and underhanded tactics. Every fight is a fair duel.
    * **Criteria:**
        * You may not initiate combat from Stealth.
        * You may not learn or use any Poisons.
        * You may not use "cheap shots" like Backstab, Gouge, Kidney Shot, etc.

* **Foil of Purity: The Fencer**
    * **Description:** A master of single-blade combat.
    * **Criteria:**
        * You may not equip any item in your off-hand slot.
        * You may not equip any ranged weapon (Bows, Guns, or Thrown).

* **Shroud of Purity: The Stalker**
    * **Description:** Prolonged open combat leaves you vulnerable. You must strike from the shadows and vanish before your enemies can focus on you.
    * **Criteria:**
        * **Exposure:** A bar builds constantly while you are in combat and visible.
        * **The Vow:** If Exposure reaches 100%, you are Revealed and fail the challenge.
        * **Mitigation:** Use abilities like Vanish, Evasion, and Feint to reduce your Exposure. Incapacitating enemies (Gouge, Blind, Stun) pauses generation.

### Shaman

* **Communion of Purity**
    * **Description:** The Spirit Walker. Your power flows purely from your spells and maintaining active totems.
    * **Criteria:**
        * You may NOT equip any weapons of any kind.
        * You must always maintain at least one active totem while in combat (after totems are unlocked).

* **Flame of Purity**
    * **Description:** Your spirit awakens to the flame, forsaking all other elements.
    * **Criteria:**
        * **Level 1-9:** Free to use any ability.
        * **Level 10+:** Only Fire spells and Fire totems may be used. Physical attacks are allowed.

* **Tether of Purity**
    * **Description:** You are a conduit for the spirits. Planting totems creates a "Tether" zone. The strength of your connection scales purely with distance.
    * **Criteria:**
        * **Analog Connection:** Standing on a Totem = 100% Signal. Max Range (30y) = 0% Signal.
        * **The Vow:** Casting a spell (Bolt, Shock, Heal) while at 0% Connection is a violation.

### Warlock

* **Grimoire of Purity**
    * **Description:** A crazed demonologist focused on fire, brimstone, and demons.
    * **Criteria:**
        * No learning or using Shadow spells or Curses.
        * No spending points in the Affliction talent tree.
        * Soul Shards may ONLY be used to summon or subjugate demons.
        * Healthstones and Soulstones are forbidden.

* **Sacrament of Purity**
    * **Description:** Forsake demonic pacts and all external mana sources.
    * **Criteria:**
        * No demon pets may be summoned (Felsteed allowed).
        * No drinking or using mana potions.
        * No Demonology talents.
        * Mana must be regained passively, via Life Tap, or Drain Mana.

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

## Expansion-Specific Classes

### Death Knight (WotLK & MoP Only)

* **Ashes of Purity**
    * **Description:** Ashes are the tangible remains of the Death Knight's past life. You vow to start with nothing.
    * **Criteria:**
        * Must be started by sacrificing a character at level 55-58.
        * You may NOT equip the gear you started with (Acherus set).

* **Sigil of Purity**
    * **Description:** The sigil marks a berserker's vow. Focus only on destruction; refuse to use any magic or item to heal wounds.
    * **Criteria:**
        * No self-healing abilities (Death Strike, Rune Tap) or items (Potions, Food, Bandages).
        * You may only equip Two-Handed Axes, Maces, or Swords.

* **Phylactery of Purity**
    * **Description:** Bound to a warlock's phylactery, you reject the Lich King's chilling frost magic entirely.
    * **Criteria:**
        * You may NOT learn or use any Frost spells.
        * You may NOT allocate points in the Frost talent tree (or activate Frost specialization in MoP).

### Monk (MoP Only)

* **Chalice of Purity**
    * **Description:** The Monk symbolically forsakes the alcoholic and magical brews they would normally rely on.
    * **Criteria:**
        * You may not use any abilities with 'Brew' or 'Tea' in the name.

* **Bindings of Purity**
    * **Description:** This Monk has sworn to be a mountain—unmoving, patient, and resolute.
    * **Criteria:**
        * You may not use high-mobility abilities (Roll, Flying Serpent Kick, Transcendence).

* **Gauntlets of Purity**
    * **Description:** These gauntlets symbolize a vow to never use a crafted weapon in combat.
    * **Criteria:**
        * You may not deal any damage while a weapon is equipped (you must fight unarmed).

---

## Installation

1.  Download the latest version from [CurseForge](https://www.curseforge.com/wow/addons/purity).
2.  Unzip the package.
3.  Copy the `Purity` folder into your `World of Warcraft/_retail_/Interface/AddOns/` (or `_classic_` / `_classic_era_`) directory depending on your game version.

## License

This addon is licensed under the MIT License. See the `LICENSE` file for more details.