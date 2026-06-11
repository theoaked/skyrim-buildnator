# Save-file export — specification

Goal: let the user take a generated build into the game with as little manual
setup as possible. Decided 2026-06-11.

## Decisions

| Question | Decision |
| --- | --- |
| Mechanism | **Phase 1: console batch file (now). Phase 2: real `.ess` patching (investigate later).** |
| Target version | Skyrim **Special/Anniversary Edition** (PC) first. Base-game Form IDs are identical on LE, so the batch works there too; only Dawnguard items carry an SE load-order prefix (`02`). |
| Scope | Race + sex, primary skills + standing stone, starter equipment + novice spells, affliction/faction (risk accepted). |
| Power level | "Identity without advantage": primary skills at 25, iron/hide/novice-tier gear, novice spells only. |

## Phase 1 — console batch file (`buildnator.txt`)

The site generates a downloadable text file of console commands. The player
drops it into the Skyrim folder and types `bat buildnator` in the console of
a freshly started game. Implemented in `js/batch.js`.

What each card becomes:

- **Race**: `player.setrace <EditorID>` — included as a fallback; the header
  instructs the player to pick race/sex/name during normal character
  creation, since the console cannot set the character's *name* and
  `setrace` outside `showracemenu` can leave the wrong face preset.
- **Sex**: `player.sexchange` ships commented out (it toggles, so running it
  blindly could flip a correct character).
- **Primary skills**: `player.setav <skill> 25` for the three skills.
- **Standing stone**: `player.addspell <ability id>` (UESP-verified IDs; the
  stone's power is the ability itself, no need to travel).
- **Weapon**: iron-tier `player.additem` + `player.equipitem` (Hunting Bow +
  100 iron arrows for Bow; Dawnguard Crossbow `02000801` + steel bolts;
  staff matched to the first magic school; Fists get no item).
- **Armor**: full iron set (heavy), hide set (light), school-matched Novice
  Robes + boots (Mage Robes), or Belted Tunic + boots (Clothes Only). A
  shield is added when the combat style is Sword & Shield.
- **Magic schools**: two novice spells per rolled school via
  `player.addspell`.
- **Affliction** (risk accepted by design): Vampire/Vampire Lord adds
  Sanguinare Vampiris (`000b8780`) — vampirism sets in naturally after three
  in-game days, which is the quest-safe route; Vampire Lord adds a note to
  seek Harkon (Dawnguard). Werewolf adds Beast Form (`00092c48`) plus
  `set PlayerIsWerewolf to 1` — functional, with the documented caveat that
  the Companions questline still treats you as unblooded.
- **Faction**: comments only. There is **no console command that joins a
  faction without breaking its questline** (`addtofaction` changes NPC
  disposition but never starts the quests), so the batch emits a per-faction
  "where to sign up" hint instead.
- **Dragonborn, deity, morality, roleplay rules**: no mechanical
  representation in the engine — emitted as a commented oath block so the
  file doubles as a build sheet.
- Plus 100 gold "for the road".

All Form IDs were verified against UESP (stones, novice spells per school,
iron/hide/novice-robe items, staves, ammunition, Sanguinare Vampiris).

## Phase 2 — real `.ess` save patching (future)

Embed a template save (new character just past Helgen) and patch it in the
browser. Investigation notes:

- Format: UESP "Skyrim:Save File Format". SE/AE saves compress the body with
  LZ4 (header stays plain); a JS LZ4 codec is needed both ways.
- Patchable with moderate risk: player name (header + ACHR), sex flag,
  skill actor values, gold. High risk: race (face data, racial abilities),
  affliction (Papyrus VM state), anything quest-related.
- One template per supported game version would have to be produced by hand
  in-game and shipped with the site (~5–10 MB each); version drift between
  AE patches is the main maintenance cost.
- Decision: revisit after phase 1 feedback; phase 1 already covers
  everything phase 2 could safely patch except the character name.
