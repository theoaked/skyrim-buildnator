# Buildnator — In-Game Mod (Skyrim SE/AE)

The Buildnator character wizard, inside the game. On a new game a message-box
wizard lets you **roll a destiny** or **forge a build by hand** — race, standing
stone, deity, morality, faction, affliction, weapon, skills, magic schools,
armor, roleplay rules, combat style and archetype, with the same coherence
rules as the website. Accepting the build applies it to your character
(skills at 25, stone power, gear, spells, gold) and **enforces the roleplay
rules** that a console batch never could.

## Requirements

- Skyrim Special Edition / Anniversary Edition 1.6.x
- [SKSE64](https://skse.silverlock.org/) — required for rule enforcement
  (stat tracking, food/poison detection, enchantment checks)
- No other dependencies — the UI is plain vanilla message boxes (no SkyUI,
  no UIExtensions)

## Install

1. Build or grab `dist/buildnator-mod.zip` (repo: `.\mod\build.ps1 -Zip`).
2. Install the zip with Vortex (or MO2: "Install from file"), enable
   **Buildnator.esp** (ESL-flagged — it does not use a full plugin slot).
3. Start a **new game**. After character creation the wizard appears.

You also receive the lesser power **"Buildnator: Destiny"**:

- If you picked *Not now* at the start, cast it to open the wizard later.
- After accepting a build, cast it to re-read your destiny — or roll a new one.

## How it works

- **Roll my fate** — rolls everything in the same dependency order as the
  site (weapon → skills → schools → armor → rules → style → archetype),
  honoring skill conflicts, magic requirements, no-Daedra constraints, deity /
  faction / affliction compatibility and rule conflicts. Review the summary,
  then *Accept*, *Roll again*, or *Customize*.
- **Forge it myself** — paginated menus for every category, validated as you
  go (you can only pick options that fit what you already chose).
- **Race and sex** are part of the rolled destiny but are *not* scripted —
  set them yourself in the race menu (scripted SetRace is famously buggy).
  The wizard tells you what was rolled, including a suggested name.
- **Faction** is given as a "where to sign up" hint; afflictions set up the
  real thing (Sanguinare Vampiris for vampires, Beast Form for werewolves).

## Rule enforcement

| Rule | What happens |
| --- | --- |
| Wanderlust | Fast travel is disabled (carriages still work) |
| Vigilant of Stendarr | Daedric weapons/armor/artifacts are auto-unequipped |
| Heart of Iron | Non-iron metal gear is auto-unequipped (hide/leather/clothing fine) |
| Agnostic | Enchanted gear and staves are auto-unequipped |
| Born without magicka | Constant ability: magicka is gone |
| Anemic | Constant ability: stamina floored at ~10 |
| Sensitive Stomach | Drinking a potion ⇒ nausea debuff (weakened regen) |
| Herbivore | Eating meat ⇒ nausea debuff |
| Honest Hands | Stealing/pickpocketing ⇒ guilt debuff |
| Friend of the Forest | Killing wildlife ⇒ guilt debuff |
| All Thumbs | Crafting anything ⇒ guilt debuff |
| Respect the Dead | Looting corpses ⇒ guilt debuff |
| Lone Wolf / Never Alone | Wrong follower count ⇒ unease debuff until fixed |
| Hearty Appetite | Under 3 meals a day ⇒ hungry debuff next day |
| Creature of Habit | A day without sleep ⇒ exhausted until you sleep |
| Afraid of the Dark | Outside between 20:00–06:00 ⇒ heavy terror debuff |
| Pack Rat, Mercenary's Code, Artisan's Pride, Sore Feet, Homesick, Devout, Sentimental Value, Thalmor Sympathizer | Honor system — listed in your destiny summary |

Debuffs are themed temporary abilities (no permanent damage); re-rolling a new
destiny resets all of them.

## Compatibility

- **Alternate Start — Live Another Life**: works. The wizard waits a few
  seconds on new game; if LAL's menu wins the race, just pick your start and
  cast **Buildnator: Destiny** afterwards.
- **Skyrim Together**: runs without SKSE — the wizard, build application and
  hard blocks still work, but SKSE-based penalties (tracked stats, potion
  detection, enchantment checks) silently disable.
- **Achievements**: unaffected — no console commands are used.

## Building from source

```powershell
.\mod\build.ps1          # gen-data -> esp (Mutagen) -> Papyrus -> deploy to game Data
.\mod\build.ps1 -NoDeploy
.\mod\build.ps1 -Zip     # also writes dist/buildnator-mod.zip
```

Needs: .NET SDK 8, Node.js, the game's own `Papyrus Compiler` (ships with
Skyrim SE when Creation Kit is installed). `js/data.js` on the website side is
the single source of truth — `mod/tools/gen-data.js` derives the Papyrus data
layer and the generator's JSON from it, and the generator resolves all vanilla
FormIDs by EditorID from your `Skyrim.esm` at build time.

`mod/tools/test-roller.js` runs a 5000-roll parity harness over the Papyrus
roll logic (ported 1:1 to JS) checking every site invariant.
