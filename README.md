# Purity Challenge AddOn for World of Warcraft: Classic Era

Purity is a hardcore challenge addon for World of Warcraft: Classic Era that allows players to opt into strict, class-specific and global challenges. These challenges are designed to be completed from level 1 to 60, testing your knowledge of the game and forcing you to play in new and interesting ways.

The addon is lightweight, modular, and designed to provide a verifiable path for proving your accomplishment.

## Links

* [Download on CurseForge](https://www.curseforge.com/wow/addons/purity)
* [Join our Discord Community](https://discord.gg/5m74Kw27AE)
* **[Official Purity Challenge Leaderboard & Verification Website](https://purity.pythonanywhere.com/)**

## Features

* **Global & Class-Specific Challenges:** Unique, thematic challenges available to all players, plus specific vows for all nine original classes.
* **Live Player Roster:** See other Purity players on your server, their class, level, and current challenge status in real-time.
* **Specialization Paths:** Many challenges require you to choose a specific sub-path, further restricting gameplay and offering diverse experiences.
* **Real-Time Violation Monitoring:** The addon actively monitors your actions, talents, and spells to ensure the rules are being followed.
* **In-Game Status UI:** Use `/purity status` to view your current standing, uptime, and other important information.
* **Web-Based Verification System:** Upon challenge completion, a unique verification code is generated. Post this code on our official [Verification Website](https://purity.pythonanywhere.com/) to have your run automatically verified and posted to the public leaderboard.

## How to Use

The addon will automatically present the challenge selection screen to you at level 1. If you decline, you can use the `/purity` slash commands to interact with the UI.

* `/purity` : Shows a summary of your current challenge status in the chat window.
* `/purity status` : Opens the main interface to the Status tab.
* `/purity rules` : Opens the main interface to the Rules tab.
* `/purity roster` : Opens the Roster tab.
* `/purity verify` : Opens the verification window with your completion code.
* `/purity bloodbar` : Toggles the Blood Mage's bar between an overlay and a movable frame.
* `/purity bloodlog` : Toggles the Blood Mage's real-time combat log.

---
## Global Challenges

### The Ascetic's Path
A challenge of self-denial where you must limit your reliance on material possessions by choosing one of three paths.
* **Path of Humility (EASY):** Only items of Common (white) quality or lower may be equipped.
* **Path of Resilience (MEDIUM):** No armor may be worn. Weapons and shields are permitted.
* **Path of the Unburdened (HARD):** No items may be equipped whatsoever.

### The Blood Mage's Bargain
A pact for power where you use your own life force as a resource. Your health becomes a "Blood Pool," depleted by damage and the use of your own abilities.
* **Key Prohibition:** Healing yourself incurs "Sanguine Weakness," doubling all Blood costs for 15 seconds.

### The Drunken Master
Embrace the way of the wandering brewmaster, finding clarity and strength only through inebriation.
* **Key Prohibition:** You must remain "Drunk" (or a higher state of inebriation) at all times. Only specific alcoholic beverages from vendors count.

### Fisherman's Folly
The devoted angler. You have forsaken all worldly possessions in pursuit of the perfect catch.
* **Key Prohibition:** You may ONLY equip items that you have personally fished from the water (vendor-purchased fishing poles are an exception).

---
## Class-Specific Challenges

### Druid
* **Pact of Purity: The Avenger of Nature**
    * Forsake the celestial balance, relying only on feral instincts. You may not kill Beasts or use Balance spells.
* **Astrolabe of Purity: The Celestial Weaver**
    * Forsake your primal connection to alternate between Nature and Arcane damaging spells. You may not use Bear Form, Cat Form, or Restoration healing spells.

### Hunter
* **Bond of Purity: The Primal Savage**
    * Forsake cowardly ranged weapons to fight in melee side-by-side with your pet. You may not equip any ranged weapons.
* **Quiver of Purity: The Lone Wolf**
    * Face the world on your own, relying only on marksmanship. You may not equip melee weapons or use a Hunter Pet.

### Mage - The Tome of Purity
* **Description:** Dedicate yourself to a single school of magic, forsaking all others. This decision is permanent.
* **Key Prohibition:** You may ONLY use spells and talents from your chosen school of magic (Fire, Frost, or Arcane).

### Paladin
* **Oath of Purity: The Selfless Shield**
    * Forsake retribution, vowing to never be the aggressor. You may not initiate combat or use Retribution spells/talents.
* **Libram of Purity: The Undead Bane**
    * Dedicate your might solely to purging Undead from the world. You may ONLY land the killing blow on creatures of the 'Undead' type.

### Priest
* **Testament of Purity: The Vessel of Light**
    * A true vessel of the Light, sworn off Shadow magic, physical attacks, and killing Humanoids.
* **Covenant of Purity: The Shadow Ascendant**
    * Embrace the whispers of the Shadow, forsaking the protective grace of the Light. You may not learn or use any Holy or Discipline spells/talents.

### Rogue
* **Contract of Purity: The Honorable Duelist**
    * Forsake the shadows and underhanded tactics. You may not initiate combat from Stealth or use poisons and stuns.
* **Foil of Purity: The Master Duelist**
    * A master of single-blade combat. You may not equip any item in your off-hand or ranged weapon slots.

### Shaman
* **Communion of Purity: The Spirit Walker**
    * Your power flows purely from spells and totems. You may not equip or use any weapons of any kind.
* **Flame of Purity: The Avatar of Flame**
    * Become a conduit of raw elemental fury. You may not cast any damaging or healing spells, relying only on melee and fire totems.

### Warlock
* **Grimoire of Purity: The Demonologist**
    * A crazed demonologist focused on fire, brimstone, and demons. You may not use Shadow magic or Affliction talents. Soul Shards may only be used for summoning.
* **Sacrament of Purity: The Master of Shadow**
    * Forsake the enslavement of demons to master the purest form of shadow and affliction magic. You may not summon demons or use Destruction spells.

### Warrior
* **Brand of Purity: The Berserker**
    * No shields or defensive stance. All combat must be initiated with Charge. Two-handed weapons are forbidden after level 20.
* **Bulwark of Purity: The Ardent Protector**
    * Forsake two-handed weapons and the Fury talent tree to become a bastion of defense.

---
## Installation

1.  Download the latest version from [CurseForge](https://www.curseforge.com/wow/addons/purity).
2.  Unzip the package.
3.  Copy the `Purity` folder into your `World of Warcraft/_classic_era_/Interface/AddOns/` directory.

    ```
    .../Interface/AddOns/
        └── Purity/
            ├── Purity.lua
            ├── Purity_BloodMage.lua
            ├── Purity_DrunkenMaster.lua
            ├── ... (other class and challenge files) ...
            └── README.md
    ```

## License

This addon is licensed under the MIT License. See the `LICENSE` file for more details.
