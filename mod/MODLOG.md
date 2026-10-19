# Buildnator v2 (MCM) — mod journal

Branch `mcm-v2`. Goal: bring the site's character generator into Skyrim with a
SkyUI MCM menu, faithful to `js/app.js`, verified in game.

## Why v2 (user feedback on v1, 2026-10-18)
- message-box wizard was slow/ugly to navigate
- roll logic diverged from the site (no locks, no direct-choice reconcile, ...)
- never properly tested in game

## Decisions
- UI: SkyUI MCM (`BLD_MCM extends SKI_ConfigBase`). SkyUI SDK sources live in
  `Source/Imports` (compile-only; SkyUI ships the real pex).
- Logic: `BLD_Build.psc` is a function-by-function port of `app.js`
  (generateAll, locks, applyChoice/reconcile, setDragonborn, character editor,
  buildNarrative). Kept from v1: data generator, Mutagen esp generator,
  ApplyBuild, BLD_Enforcer.
- The SDK in use has no text-input option: the name is rolled or taken from
  the player's actual name ("Use my name"). Race/sex are not scripted (as v1).
- Fidelity is proven with an oracle: `SelfTest(200)` logs transitions to the
  Papyrus user log, `tools/check-oracle.js` replays each on the real `app.js`.
  Oracle validated offline: 3 site-generated logs PASS; a log with an injected
  weapon bug produced 161 findings.

## Environment facts
- Game: SE/AE 1.6.1170, SKSE 2.2.6 (skse64_1_6_1170.dll), Steam path.
- SKSE script sources: `Data\Scripts\Source`; vanilla: `Data\Source\Scripts`.
- Papyrus compiler MISSING (Creation Kit not installed) — blocks compile.
- SkyUI NOT installed — blocks the MCM at runtime.
- Node: `C:\Program Files\nodejs\node.exe` (not on PATH in Git Bash).
- Other mods: Alternate Start LAL, Skyrim Together Reborn, USSEP.

## 2026-10-18 install round
- SkyUI SE (F:\Downloads\SkyUI-12604-6-11-...zip: SkyUI_SE.esp + .bsa) copied
  into Data by hand (not via Vortex) and added to Plugins.txt before Buildnator.
- Creation Kit installed -> `Papyrus Compiler\PapyrusCompiler.exe` present.
- Skyrim.ini + Skyrim.ini.base (Vortex regenerates the ini from .base):
  [Papyrus] bEnableLogging=1, bEnableTrace=1. Active My Games folder is
  OneDrive\Documents (an empty OneDrive\Documentos one also exists).
- Backup before first v2 launch: C:\Users\eduar\SkyrimBackups\2026-10-18-before-buildnator-v2
  (222 saves, Skyrim.ini, Skyrim.ini.base, Plugins.txt). Installed v1 files: mod\backup-installed.
- Compile pitfalls hit: `none` is reserved; Race/Armor/Weapon/Faction are type
  names (state props renamed *Idx).
- INCIDENT (from v1, June): deploy copied out\Scripts\*.pex, which included a
  compiled compile-time STUB StringUtil.pex (Find/GetLength/Substring only),
  over SKSE's real one - and through Vortex's hardlink also over the SKSE
  staging copy. Restored the genuine 1116-byte file from the SKSE 2.2.6 archive
  (all 62 SKSE pex now match the archive). Deploy now copies BLD_*.pex only.
- v1 orphans left in Data\Scripts: BLD_Main.pex, BLD_Roller.pex (unreferenced).

## 2026-10-18 first in-game test (user)
- "funciona" - MCM works. Bug: race is chosen in character creation before the
  MCM can be opened. User chose BOTH fixes: (1) first MCM open adopts the
  player's race+sex (race locked) - BLD_MCM.OnConfigOpen -> AdoptPlayerBody;
  (2) "Reshape my body" -> Game.ShowRaceMenu() after menus close (OnUpdate),
  then OnMenuClose("RaceSex Menu") re-adopts. Disabled after Accept
  (ShowRaceMenu may reset skills).
- No Papyrus log was written that session. My sed had turned Skyrim.ini /
  .base from CRLF to LF; restored CRLF (sizes match originals). Unconfirmed
  whether that was the cause.

## 2026-10-18 first oracle run (in game)
- Logging works after restoring CRLF in Skyrim.ini.
- Self-test "stuck at RUNNING": Papyrus pauses while Skyrim is unfocused
  (gaps exactly when the user alt-tabbed); ~2 s/step focused. Logs are
  buffered - the file ends mid-line until flushed/exit.
- ORACLE on 200 transitions (gen 104 / choose 84 / dragonborn 12, 300 site
  replays each): 0 logic findings. 151 narrative findings = ReplaceAll bug
  (SKSE Substring(s, 0, 0) means "to end" -> token at index 0 duplicated the
  sentence). Fixed, not yet deployed/re-verified.
- Papyrus' case-insensitive string table mangles logged keys ("WEAPON",
  "Skills", "male"); oracle now matches keys/values/category ids ignoring case.
- Self-test now shows progress (n/200) via BLD_MCM.ShowSelfTestProgress.
  (`ui` can't be a variable name - clashes with SKSE's UI script.)

## 2026-10-19 second oracle run (in game)
- Deployed narrative fix + progress counter. User: "parece que tudo foi bem".
- ORACLE PASS: 200 transitions (gen 95 / choose 85 / dragonborn 20), 200
  narratives clean, 300 site replays each. Papyrus.0.log: no BLD_ errors.

## Status
- [x] gen-data v2 fields (unified requires, descs, narrative, DataHash)
- [x] BLD_Build.psc, BLD_MCM.psc written (NOT compiled yet)
- [x] esp generator v2 builds + round-trip OK (2 quests)
- [x] oracle checker written and validated offline
- [x] compile (all 5 scripts, 0 errors)
- [x] deploy (v1 backed up to `mod/backup-installed/`)
- [x] in game: MCM appears, roll/lock/choose work (user-confirmed)
- [x] in game: self-test + oracle PASS (2026-10-19)

## REFINE LATER
- Narrative lowercasing ("the warrior") — Papyrus has no ToLower and its
  string table is case-insensitive; names render capitalized mid-sentence.
- Optional "match race & sex" via RaceMenu before accepting.
- Hide the Self-test page in release builds.
