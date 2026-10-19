# Buildnator v2 — setup on a fresh Skyrim install

Everything needed to go from a clean Skyrim Special/Anniversary Edition to a
working Buildnator — first as a **player** (install and play), then as a
**developer** (build the mod from this repo).

---

## Part 1 — Playing

### 1. Requirements

| What | Why | Where |
| --- | --- | --- |
| Skyrim SE/AE **1.6.x** (Steam or GOG) | The game. All DLCs used by the mod (Dawnguard, Dragonborn) ship with SE/AE. | — |
| **SKSE64** matching your game version | SkyUI and the mod's scripts call SKSE functions (`StringUtil`, `Utility.CreateIntArray`, menu events). | [skse.silverlock.org](https://skse.silverlock.org/) |
| **SkyUI SE** (5.2) | The Buildnator menu is a SkyUI MCM page. | Nexus Mods, mod 12604 |

No other dependency: no SKSE plugin DLL, no Address Library, no
UIExtensions, no PapyrusUtil.

Check your game version (right-click `SkyrimSE.exe` → Properties → Details)
and download the SKSE build made for exactly that version.

### 2. Install SKSE

1. Extract the SKSE archive.
2. Copy `skse64_loader.exe` and the `skse64_*.dll` files next to `SkyrimSE.exe`.
3. Copy SKSE's `Data\Scripts` folder into the game's `Data` folder (merge). This
   includes the `.pex` files **and** `Data\Scripts\Source` (needed only if you
   build the mod yourself).
4. From now on, always launch the game with **`skse64_loader.exe`**.
   On Steam you can start it through your mod manager or a desktop shortcut.

> Never replace SKSE's own scripts (`StringUtil.pex`, `Utility.pex`, ...) with
> files from another mod. If unsure, reinstall SKSE — it fixes them.

### 3. Install SkyUI SE

With a mod manager (Vortex / MO2): install the downloaded archive and enable
**SkyUI_SE.esp**.

Manually: copy `SkyUI_SE.esp` and `SkyUI_SE.bsa` into `Data`, then enable the
plugin (see step 5).

### 4. Install Buildnator

Get `buildnator-mod.zip` — build it with `.\mod\build.ps1 -Zip` (Part 2); it
lands in `dist\`, which is not committed. Make sure it's a v2 build: it must
contain `BLD_MCM.pex`. It contains:

```
Buildnator.esp          (ESL-flagged: does not use a full load-order slot)
Scripts\BLD_Build.pex
Scripts\BLD_Data.pex
Scripts\BLD_Enforcer.pex
Scripts\BLD_MCM.pex
Scripts\BLD_PowerFX.pex
Seq\Buildnator.seq      (required: makes the quests start on a new game)
```

With a mod manager: install the zip and enable **Buildnator.esp**.
Manually: extract it into `Data`, keeping the folders.

### 5. Enable the plugins

A mod manager does this for you. Manually, edit
`%LOCALAPPDATA%\Skyrim Special Edition\Plugins.txt` and make sure these lines
exist (the `*` means enabled), with SkyUI before Buildnator:

```
*SkyUI_SE.esp
*Buildnator.esp
```

### 6. First game

1. Launch with `skse64_loader.exe` and start a **new game**. Saves made with
   the v1 (message-box) Buildnator are not compatible with v2.
2. Create your character as usual. The menu cannot be opened during
   character creation; that's expected.
3. A few seconds after you gain control, the notification *"Your destiny
   awaits"* appears. Open **Esc → Mod Configuration → Buildnator**
   (SkyUI may take up to a minute to register a new menu on a fresh save).
4. The first time it opens, the destiny adopts the race and sex you created
   (Race is locked). Unlock it and roll if you want the dice to choose, then use
   **Reshape my body** to change your character to match — before accepting.
5. Roll, lock and pick until you like the destiny, then **Accept this
   destiny**: primary skills at 25, standing stone, gear, spells, affliction,
   100 gold, and the roleplay rules start being enforced.
6. The lesser power **Buildnator: Destiny** shows your destiny sheet and story
   at any time.

### Compatibility

- **Alternate Start — Live Another Life**: works; open the menu once you're in
  the prison cell or after choosing your start.
- **Skyrim Together Reborn**: installed alongside during testing without
  conflicts, but v2 was not tested in a multiplayer session.
- **Achievements**: unaffected (no console commands are used).

### Troubleshooting

| Symptom | Fix |
| --- | --- |
| No "Mod Configuration" entry at all | SkyUI isn't loaded: check `SkyUI_SE.esp` is enabled and the game was started with `skse64_loader.exe`. |
| Mod Configuration exists but no Buildnator | Wait a minute, or save and reload. Check `Buildnator.esp` is enabled and `Data\Seq\Buildnator.seq` exists. |
| Menu says "still waking up" | The mod's quest hasn't finished its first roll yet — close and reopen in a few seconds. |
| Self-test progress stops | Scripts pause while Skyrim isn't the focused window. Keep the game in front. |

### Uninstall

Forsake your destiny in the menu first (stops rule enforcement), then disable
`Buildnator.esp` and delete the files listed in step 4. Removing a scripted mod
mid-playthrough can leave orphaned script data in that save; prefer starting a
new game.

---

## Part 2 — Building from source

### 1. Tools

| Tool | Used for |
| --- | --- |
| Everything in Part 1 (game + SKSE + SkyUI) | Testing, and SKSE's script sources for compiling. |
| **Creation Kit** (free, Steam → Tools) | Provides `Papyrus Compiler\PapyrusCompiler.exe` in the game folder. |
| **.NET SDK 8** | Builds `Buildnator.esp` with Mutagen (`mod/Generator`). |
| **Node.js** (18+) | `tools/gen-data.js` and `tools/check-oracle.js`. |
| PowerShell 5.1+ | Runs `build.ps1`. |
| Git | Clone the repo. |

### 2. One-time setup

1. **Vanilla script sources.** Launch the Creation Kit once; it offers to
   extract `Data\Scripts.zip`. Accept, so that `Data\Source\Scripts` contains
   the vanilla `.psc` files (`Actor.psc`, `Quest.psc`, ...). If it doesn't ask,
   extract `Data\Scripts.zip` into `Data` yourself.
2. **SKSE script sources** must be in `Data\Scripts\Source` (`SKSE.psc`,
   `StringUtil.psc`, `Utility.psc`, ...). They come with the SKSE archive
   (Part 1, step 2.3). The build stops with a clear error if they're missing.
3. **SkyUI SDK sources** are already in this repo (`mod/Source/Imports/SKI_*.psc`).
   They are compile-time only; the build never ships them — SkyUI provides the
   real scripts.
4. **Game path.** `build.ps1` assumes the Steam default:
   `C:\Program Files (x86)\Steam\steamapps\common\Skyrim Special Edition`.
   Edit `$gameDir` at the top of `build.ps1` if yours differs (also the default
   `Skyrim.esm` path in `Generator/Program.cs`, used only when run by hand).
5. Make sure `node` is on your PATH (in PowerShell: `node --version`).

### 3. Build

```powershell
.\mod\build.ps1            # gen-data -> esp -> Papyrus compile -> deploy to Data
.\mod\build.ps1 -NoDeploy  # build only, into mod\out
.\mod\build.ps1 -Zip       # also write dist\buildnator-mod.zip
```

What it does:

1. `tools/gen-data.js` reads the site's `js/data.js` + `js/batch.js` (the single
   source of truth) and writes `generated/BLD_Data.psc`.
2. `Generator` (Mutagen) writes `out/Buildnator.esp` and `out/Seq/Buildnator.seq`,
   resolving vanilla forms from your own `Skyrim.esm`, and validates the result.
3. Compiles `Source/Scripts/*.psc` + `generated/BLD_Data.psc` into `out/Scripts`.
4. Deploy (unless `-NoDeploy`): on the first deploy, backs up any installed
   Buildnator files to `mod/backup-installed/`, then copies the esp, the
   `BLD_*.pex` scripts and the seq file into `Data`, and adds
   `*Buildnator.esp` to `Plugins.txt` if missing. Only `BLD_*.pex` is ever
   copied, so the build can't overwrite SKSE or SkyUI scripts.

Close the game before deploying.

### 4. Verify fidelity with the site (optional, recommended after logic changes)

1. Enable Papyrus logging in
   `Documents\My Games\Skyrim Special Edition\Skyrim.ini` (on OneDrive setups:
   `OneDrive\Documents\...`):
   ```ini
   [Papyrus]
   bEnableLogging=1
   bEnableTrace=1
   ```
   Keep the file's Windows (CRLF) line endings — with LF-only endings the game
   wrote no log in our tests. If Vortex manages your inis, change
   `Skyrim.ini.base` too, or Vortex will revert it.
2. In game: **Buildnator → Self-test → Run**. Keep Skyrim focused for about
   7 minutes until it reaches 200/200.
3. Quit the game (logs are flushed on exit), then run:
   ```powershell
   node mod\tools\check-oracle.js
   ```
   It replays each logged roll, lock and choice on the real `js/app.js` and
   prints `ORACLE: PASS` or the exact transitions that differ. It refuses a log
   made from a different `data.js` — rebuild and rerun the self-test after
   changing the data.

### Papyrus pitfalls met while building this mod

- `None`, and type names such as `Race`, `Armor`, `Weapon`, `Faction`, `UI`,
  can't be used as variable/property names (names are case-insensitive).
- `StringUtil.Substring(s, 0, 0)` returns the whole string (length 0 means
  "to the end").
- The VM's string table is case-insensitive: the first spelling of a word wins
  everywhere (logged keys like `"WEAPON"`, `male`). Compare case-insensitively.
