# Buildnator — Player's Guide

A step-by-step walkthrough of the in-game mod from first launch to your first
dungeon.

---

## Table of Contents

1. [What Buildnator Does](#what-buildnator-does)
2. [Requirements & Installation](#requirements--installation)
3. [Starting the Wizard](#starting-the-wizard)
4. [Roll My Fate vs. Forge It Myself](#roll-my-fate-vs-forge-it-myself)
5. [Category Reference](#category-reference)
6. [Build Application — What Gets Added](#build-application--what-gets-added)
7. [Rule Enforcement in Practice](#rule-enforcement-in-practice)
8. [Re-rolling and Changing Builds](#re-rolling-and-changing-builds)
9. [Compatibility Notes](#compatibility-notes)
10. [FAQ](#faq)

---

## What Buildnator Does

Buildnator randomly generates a coherent Skyrim character build and enforces it
in-game. A build consists of 14 linked categories:

| Category | What it decides |
|---|---|
| Race | Your suggested race (set it yourself in the race menu) |
| Archetype | Your roleplay identity (Assassin, Battlemage, Pilgrim, etc.) |
| Standing Stone | Which stone blessing to apply |
| Deity | Who you worship (honor system) |
| Morality | Your alignment (Saint → Evil) |
| Faction | Which guild/faction to join |
| Affliction | Vampire / Werewolf / none |
| Weapon | Your primary weapon type |
| Skills | Three skills set to level 25 |
| Magic Schools | 0–2 schools of magic with starting spells |
| Armor | Your armor category with starting gear |
| Rules | 3–8 roleplay rules, some enforced in-game |
| Combat Style | How you prefer to fight |
| Name | A lore-friendly name suggestion for your race |

Categories are not chosen independently — Buildnator's constraint engine
prevents contradictions (no One-Handed + Two-Handed, no vampire in Dawnguard,
no enchanted gear on an Agnostic, etc.).

---

## Requirements & Installation

**Requirements:**
- Skyrim Special Edition or Anniversary Edition 1.6.x
- [SKSE64](https://skse.silverlock.org/) — needed for stat-tracked rule
  enforcement (potion detection, equipment checks, follower count, etc.)

> Without SKSE the wizard, build application, Wanderlust fast-travel lock, and
> equipment-rejection rules still work. Only the stat-tracked debuff rules
> (Sensitive Stomach, Herbivore, Honest Hands, etc.) silently disable.

**Install steps:**

1. Grab `dist/buildnator-mod.zip` from the repo's `dist/` folder, or build it
   yourself with `.\mod\build.ps1 -Zip`.
2. Open Vortex → **Mods** → **Install From File** and select the zip.  
   *(MO2: drag the zip into the left panel, then enable it.)*
3. Enable **Buildnator.esp** in your load order. It is ESL-flagged and uses no
   full plugin slot.
4. Launch through SKSE64 (not the default Skyrim launcher).
5. Start a **new game** — the mod hooks into the new-game event. It will not
   fire mid-save.

---

## Starting the Wizard

About four seconds after character creation ends, a message box appears
automatically:

```
Welcome, traveller. Your destiny awaits.
> Roll my fate        ← let the dice decide everything
> Forge it myself     ← pick every category yourself
> Not now             ← dismiss; open later with your power
```

If you pick **Not now** (or the wizard loses the race to Alternate Start), open
your **Magic** menu → **Powers** → cast **Buildnator: Destiny** at any time to
bring it back.

After the opening choice you are asked:

```
Are you the Dragonborn?
> Yes   ← unlocks the "Shouts First" combat style
> No    ← that style is excluded from the pool
```

---

## Roll My Fate vs. Forge It Myself

### Roll My Fate

Buildnator randomizes everything in dependency order:

1. Weapon (no conflicts possible — picked first)
2. Skills (slot 1 locked to weapon's governing skill; slots 2–3 free, no
   Heavy/Light Armor conflict, no One/Two-Handed conflict)
3. Magic Schools (0–2; forced ≥ 1 if any magic skill is primary)
4. Armor (filtered by weapon + magic combo — no Mage Robes with
   Two-Handed/Archery, etc.)
5. Rules (3–8; conflict-checked — Lone Wolf and Never Alone never coexist, etc.)
6. Combat Style (must fit weapon and magic setup)
7. Archetype (must match skills / armor / combat style)

A summary is shown. You can then:
- **Accept** the build → skills, gear, spells, and stone are applied
- **Roll again** → keep rolling until something clicks
- **Customize** → switch to the manual path with the rolled values pre-filled

### Forge It Myself

A forward-only sequence of paginated menus. Each menu shows only the options
valid given your choices so far.

Order: **Gender → Race → Stone → Deity → Morality → Faction → Affliction →
Weapon → Skills → Magic → Armor → Rules → Style → Archetype**

Each menu has a **Roll the dice** button that picks randomly from the remaining
valid options for that slot. You can mix-and-match: pick race and weapon
manually, roll everything else.

> **Tip:** Once you confirm a category it cannot be changed without starting the
> wizard over. Plan the early slots (Race, Weapon) before locking them in.

After all categories are set you reach the same confirm screen as Roll My Fate.

---

## Category Reference

### Race
The wizard tells you which race was rolled and suggests a name. You must apply
these yourself during character creation — the mod never forces a race change
(scripted `SetRace` is famously unstable).

### Standing Stone
Applied automatically when you accept the build. The existing (Dragonborn)
stone passive is replaced.

### Deity
An honor-system choice — no in-game mechanic enforces it. Use it to guide
roleplay (which shrines you visit, which quests you accept).

### Faction
A "where to sign up" pointer. The mod does not auto-join factions; that would
break questlines. Afflictions are the exception — see below.

### Affliction

| Value | What happens |
|---|---|
| None | Nothing |
| Werewolf | Receive Beast Form ability (same as The Companions ritual) |
| Vampire | Contract Sanguinare Vampiris (progresses to full vampirism in 3 days) |
| Vampire Lord | Contract Sanguinare Vampiris via the Volkihar path |

Affliction and Faction are cross-checked: Dawnguard membership never rolls with
vampirism; Companions/Dawnguard never roll with werewolf via Volkihar.

### Weapon
Sets which weapon you receive and which skill occupies skill slot 1.

| Weapon | Governing Skill | Starting gear |
|---|---|---|
| Sword / War Axe / Mace | One-Handed | Iron weapon |
| Greatsword / Battleaxe / Warhammer | Two-Handed | Iron weapon |
| Bow | Archery | Iron bow + 100 iron arrows |
| Crossbow | Archery | Crossbow + 100 steel bolts |
| Staff | — | Apprentice staff (school matches magic roll) |
| Fists (Unarmed) | — | No weapon item |
| Dagger | One-Handed | Iron dagger |

### Skills
Three skills set to level 25. Slot 1 is always the weapon's governing skill.
The other two are rolled freely from the 18 available, avoiding direct conflicts
(One-Handed ↔ Two-Handed; Heavy Armor ↔ Light Armor).

### Magic Schools
0–2 schools. You receive two novice spells per school. At least one school is
always rolled if a magic skill appears in your primary skills.

### Armor

| Category | What you receive | Restriction |
|---|---|---|
| Heavy Armor | Iron helmet, cuirass, gauntlets, boots | — |
| Light Armor | Hide helmet, armor, bracers, boots | — |
| Mage Robes | Apprentice robes per school + shoes | Requires ≥ 1 magic school; incompatible with Two-Handed / Archery |
| Clothes Only | Belted tunic + boots | No protection — pure roleplay |

### Rules
3–8 roleplay rules are attached to the build. Some are enforced with debuffs or
equipment rejection; others are honor-system only. See
[Rule Enforcement in Practice](#rule-enforcement-in-practice) below.

### Combat Style
Guides how you should fight. **Shouts First** requires the Dragonborn flag.
**Spell & Blade** requires at least one magic school. The engine picks styles
compatible with your weapon and armor.

### Archetype
Your roleplay identity — the archetype's requirements are always a subset of
your rolled build, so it always fits (e.g., Paladin needs Restoration + Heavy
Armor + One-Handed or Two-Handed, and will only roll when all three are
present).

---

## Build Application — What Gets Added

When you **Accept** the build, the following happens immediately:

- Primary skills raised to **level 25**
- Standing stone power added (existing Dragonborn stone replaced)
- Starting weapon added to inventory (and equipped)
- Shield added if Combat Style is **Sword & Shield**
- Armor pieces added (type depends on your armor roll)
- Two novice spells per magic school added
- Affliction applied (Sanguinare Vampiris or Beast Form, as appropriate)
- **100 gold** added
- Roleplay rules handed to the enforcement engine (active immediately)

The wizard then tells you which race and name were rolled and prompts you to
finish character creation before entering the world.

---

## Rule Enforcement in Practice

Rules fall into four enforcement tiers:

### Tier 1 — Hard blocks (permanent while rule is active)

| Rule | Effect |
|---|---|
| **Wanderlust** | Fast travel disabled. Carriages and walking still work. |

### Tier 2 — Constant attribute penalties

| Rule | Effect |
|---|---|
| **Born Without Magicka** | Magicka set to 0 permanently (ability stays on). |
| **Anemic** | Stamina floored to ~10 permanently. |

### Tier 3 — Event-driven debuffs (temporary, ~2–3 minutes)

| Rule | Trigger | Debuff |
|---|---|---|
| **Sensitive Stomach** | Drink any potion | Nausea: –25% magicka/stamina regen + magic weakness |
| **Herbivore** | Eat any meat | Nausea |
| **Honest Hands** | Steal or pickpocket | Guilt: minor combat penalty |
| **Friend of the Forest** | Kill wildlife | Guilt |
| **All Thumbs** | Use any crafting station | Guilt |
| **Respect the Dead** | Loot a corpse | Guilt |

### Tier 4 — Ongoing state checks

| Rule | Condition | Effect |
|---|---|---|
| **Lone Wolf** | Follower count > 0 | Unease debuff until follower dismissed |
| **Never Alone** | No followers | Unease debuff until a follower is hired |
| **Hearty Appetite** | < 3 meals the previous in-game day | Hungry debuff all next day |
| **Creature of Habit** | No sleep in past 2 in-game days | Exhausted debuff until next sleep |
| **Afraid of the Dark** | Outdoors between 20:00–06:00 | Heavy terror debuff |

### Tier 5 — Equipment rejection (SKSE)

| Rule | Blocked items | What happens |
|---|---|---|
| **Vigilant of Stendarr** | Daedric weapons, armor, artifacts | Auto-unequipped with a warning |
| **Heart of Iron** | Any metal other than iron (steel, elven, orcish, etc.) | Auto-unequipped with a warning |
| **Agnostic** | Enchanted gear and staves | Auto-unequipped with a warning |

### Honor system (no in-game enforcement)

Pack Rat, Mercenary's Code, Artisan's Pride, Sore Feet, Homesick, Devout,
Sentimental Value, Thalmor Sympathizer — these are printed in your destiny
summary. You track them yourself.

> **Note:** All debuffs are temporary abilities (no permanent damage, no death).
> They fade on their own — they are a nudge, not a punishment.

---

## Re-rolling and Changing Builds

Cast **Buildnator: Destiny** from your Powers menu at any time after accepting a
build.

- All active debuffs from the previous build are cleared.
- All enforced rules from the previous build are removed.
- The wizard starts fresh (Roll / Forge / Not now).
- Accepting a new build re-applies skills, gear, and rules.

> Re-rolling does **not** un-apply things already in the world (vampirism, items
> in your inventory, skill levels). It only resets the enforcement state and
> applies the new build on top.

---

## Compatibility Notes

| Mod | Status |
|---|---|
| **Alternate Start — Live Another Life** | Fully compatible. If LAL wins the startup race, just cast Buildnator: Destiny after picking your start. |
| **Skyrim Together** | Works without SKSE. Wizard, build apply, hard blocks and equipment rejection all function. Stat-tracked debuffs (Tier 3 above) silently skip. |
| **Any mod that changes starting gear** | No conflict — Buildnator adds to your inventory, it never clears it. |
| **SkyUI / UIExtensions** | Not required. The UI is plain vanilla message boxes. |
| **Achievement mods (SKSE)** | No conflict — no console commands are used, so vanilla achievements are unaffected. |
| **Survival Mode** | Compatible. Survival's own hunger/sleep penalties stack with Buildnator's. If you have Hearty Appetite + Survival enabled, you will feel it. |

---

## FAQ

**The wizard didn't appear after character creation.**  
Open **Magic → Powers** and cast **Buildnator: Destiny**. Some start mods
(Alternate Start, Realm of Lorkhan) replace the new-game event — cast the power
after choosing your start.

**I accepted a build but nothing happened.**  
The build is staged. Cast **Buildnator: Destiny** once more to trigger
application. The two-step design prevents accidental application during
character creation.

**My fast travel is disabled even though I didn't roll Wanderlust.**  
Some other mod (Survival Mode, Frostfall, etc.) may have disabled it. Check
your active rules in the destiny summary — if Wanderlust is not listed,
Buildnator is not the cause.

**Equipment rejection isn't working.**  
Equipment rejection (Vigilant of Stendarr, Heart of Iron, Agnostic) requires
SKSE64. Confirm SKSE is active: open the console and type `GetSKSEVersion`.
If nothing returns, SKSE is not loaded.

**Can I use the website build on the in-game mod?**  
Yes. Generate a build on the website, note your choices, then pick **Forge it
myself** in the mod and match each category manually.

**Does re-rolling ruin my playthrough?**  
The mod re-applies skills, gear, and rules on the new build. Your quests, items,
and existing skill levels are untouched. Think of it as your character having a
change of heart.

**Can I play without the mod (website only)?**  
Yes — the website works standalone. Download `buildnator.txt` from the
**Skyrim Setup File** button and run `bat buildnator` from the in-game console
after character creation. Skills, gear, stone, and gold are applied, but no
rule enforcement.
