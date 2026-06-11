// Skyrim Buildnator — console batch export (phase 1 of docs/SAVE_EXPORT.md).
// Builds a Skyrim SE/AE console batch file from the current build: the
// player saves it as buildnator.txt in the Skyrim folder and runs
// `bat buildnator` in the console of a freshly started game.
// Form IDs verified against UESP; base-game IDs are identical on LE, and
// Dawnguard items use the standard SE load-order prefix (02).

const SKILL_LEVEL = 25;

const CONSOLE_DATA = {
  raceIds: {
    Nord: "NordRace", Imperial: "ImperialRace", Breton: "BretonRace",
    Redguard: "RedguardRace", Altmer: "HighElfRace", Bosmer: "WoodElfRace",
    Dunmer: "DarkElfRace", Orsimer: "OrcRace", Argonian: "ArgonianRace",
    Khajiit: "KhajiitRace",
  },
  skillAvs: {
    "One-Handed": "onehanded", "Two-Handed": "twohanded", Archery: "marksman",
    Block: "block", Smithing: "smithing", "Heavy Armor": "heavyarmor",
    "Light Armor": "lightarmor", Pickpocket: "pickpocket",
    Lockpicking: "lockpicking", Sneak: "sneak", Alchemy: "alchemy",
    Speech: "speechcraft", Alteration: "alteration", Conjuration: "conjuration",
    Destruction: "destruction", Illusion: "illusion",
    Restoration: "restoration", Enchanting: "enchanting",
  },
  stoneAbilities: {
    "The Warrior": "000e5f4c", "The Mage": "000e5f47", "The Thief": "000e5f45",
    "The Lover": "000e5f5a", "The Lord": "000e5f58", "The Lady": "000e5f54",
    "The Steed": "000e5f5e", "The Apprentice": "000e5f4e",
    "The Atronach": "000e5f51", "The Ritual": "000e7329",
    "The Serpent": "000e5f61", "The Shadow": "000e732a", "The Tower": "000e7328",
  },
  schoolSpells: {
    Destruction: [["Flames", "00012fcd"], ["Sparks", "0002dd2a"]],
    Conjuration: [["Conjure Familiar", "000640b6"], ["Raise Zombie", "0007e8e1"]],
    Illusion: [["Courage", "0004dee8"], ["Fury", "0004deeb"]],
    Alteration: [["Oakflesh", "0005ad5c"], ["Candlelight", "00043324"]],
    Restoration: [["Healing", "00012fcc"], ["Lesser Ward", "00013018"]],
  },
  // Weapon name -> [item name, form id, count][]
  weapons: {
    Sword: [["Iron Sword", "00012eb7", 1]],
    "War Axe": [["Iron War Axe", "00013790", 1]],
    Mace: [["Iron Mace", "00013982", 1]],
    Dagger: [["Iron Dagger", "0001397e", 1]],
    Greatsword: [["Iron Greatsword", "0001359d", 1]],
    Battleaxe: [["Iron Battleaxe", "00013980", 1]],
    Warhammer: [["Iron Warhammer", "00013981", 1]],
    Bow: [["Hunting Bow", "00013985", 1], ["Iron Arrow", "0001397d", 100]],
    Crossbow: [["Crossbow (Dawnguard)", "02000801", 1], ["Steel Bolt (Dawnguard)", "0200f1a0", 100]],
  },
  staffBySchool: {
    Destruction: ["Staff of Flames", "0004dee0"],
    Illusion: ["Staff of Courage", "00029b88"],
  },
  staffDefault: ["Staff of Magelight", "000be121"],
  armorSets: {
    "Heavy Armor": [["Iron Armor", "00012e49"], ["Iron Boots", "00012e4b"], ["Iron Gauntlets", "00012e46"], ["Iron Helmet", "00012e4d"]],
    "Light Armor": [["Hide Armor", "00013911"], ["Hide Boots", "00013910"], ["Hide Bracers", "00013912"], ["Hide Helmet", "00013913"]],
    "Clothes Only": [["Belted Tunic", "0001be1a"], ["Boots", "0001be1b"]],
  },
  robesBySchool: {
    Alteration: "0010d669", Conjuration: "0010d66a", Destruction: "0010d668",
    Illusion: "0010d671", Restoration: "0010d66b",
  },
  shields: {
    "Heavy Armor": ["Iron Shield", "00012eb6"],
    default: ["Hide Shield", "00013914"],
  },
  // No console command joins a faction without breaking its questline, so
  // factions become "where to sign up" hints.
  factionHints: {
    "The Companions": "Walk into Jorrvaskr in Whiterun and ask to join.",
    "College of Winterhold": "Pass the gate test at the bridge to Winterhold's College.",
    "Thieves Guild": "Find Brynjolf in Riften's marketplace and play along.",
    "Dark Brotherhood": "Murder an innocent, then sleep. They will find you.",
    "Imperial Legion": "Report to Legate Rikke in Castle Dour, Solitude.",
    Stormcloaks: "Seek Ulfric Stormcloak in the Palace of the Kings, Windhelm.",
    Dawnguard: "Travel to Fort Dawnguard, southeast of Riften, and speak to Isran.",
    "Volkihar Vampires": "Complete Dawnguard's opening quests and accept Harkon's gift.",
    "Bards College": "Ask Viarmo in Solitude to join the Bards College.",
    None: "You walk alone. No hall, no oath, no master.",
  },
};

function buildBatchFile() {
  const c = state.character.items[0];
  const race = state.race.items[0].name;
  const female = c.description.startsWith("Female");
  const skills = state.skills.items.map((s) => s.name);
  const schools = currentMagicSchools();
  const weapon = state.weapon.items[0].name;
  const armor = state.armor.items[0].name;
  const style = state.combatStyle.items[0].name;
  const stone = state.standingStone.items[0].name;
  const affliction = state.affliction.items[0].name;
  const faction = state.faction.items[0].name;

  const L = [];
  const sect = (title) => { L.push("", "; --- " + title + " ---"); };
  const give = (items, equip) => {
    for (const [name, id, count] of items) {
      L.push("player.additem " + id + " " + (count || 1) + " ; " + name);
      if (equip) L.push("player.equipitem " + id);
    }
  };

  L.push(
    "; ===================================================",
    "; SKYRIM BUILDNATOR — " + c.name + " (" + c.description + ")",
    "; " + state.archetype.items[0].name + " · generated at https://theoaked.github.io/skyrim-buildnator/",
    "; For Skyrim Special/Anniversary Edition (PC).",
    "; ---------------------------------------------------",
    "; HOW TO USE",
    "; 1. Save this file as buildnator.txt in your Skyrim folder",
    ";    (next to SkyrimSE.exe).",
    "; 2. Start a NEW game. In character creation, pick race, sex",
    ";    and the name " + c.name + " yourself - the console cannot set names.",
    "; 3. Once you can move freely, open the console (~ key) and type:",
    ";       bat buildnator",
    "; 4. Close the console and live your destiny.",
    "; Lines starting with ; are comments - the game ignores them.",
    "; ==================================================="
  );

  sect("Race: " + race + " (fallback - prefer picking it in character creation)");
  L.push("player.setrace " + CONSOLE_DATA.raceIds[race]);
  L.push("; Character is " + (female ? "female" : "male") + ". sexchange TOGGLES the sex,");
  L.push("; so only uncomment the next line if yours doesn't match:");
  L.push("; player.sexchange");

  sect("Primary skills at " + SKILL_LEVEL + ": " + skills.join(", "));
  for (const s of skills) L.push("player.setav " + CONSOLE_DATA.skillAvs[s] + " " + SKILL_LEVEL);

  sect("Standing stone: " + stone);
  L.push("player.addspell " + CONSOLE_DATA.stoneAbilities[stone] + " ; " + stone + " Stone ability");

  sect("Weapon of choice: " + weapon);
  if (weapon === "Fists") {
    L.push("; Fists need no steel. Hit things.");
  } else if (weapon === "Staff") {
    const staff = CONSOLE_DATA.staffBySchool[schools[0]] || CONSOLE_DATA.staffDefault;
    give([[staff[0], staff[1], 1]], true);
  } else {
    const items = CONSOLE_DATA.weapons[weapon];
    give([items[0]], true);
    if (items[1]) give([items[1]], false);
    if (weapon === "Crossbow") L.push("; Requires the Dawnguard DLC (always present on SE/AE).");
  }
  if (style === "Sword & Shield") {
    const shield = CONSOLE_DATA.shields[armor] || CONSOLE_DATA.shields.default;
    give([[shield[0], shield[1], 1]], true);
  }

  sect("Armor: " + armor);
  if (armor === "Mage Robes") {
    const school = schools[0];
    give([["Novice Robes of " + school, CONSOLE_DATA.robesBySchool[school], 1], ["Boots", "0001be1b", 1]], true);
  } else {
    give(CONSOLE_DATA.armorSets[armor], true);
  }

  sect("Magic schools: " + (schools.length ? schools.join(", ") : "None"));
  if (schools.length === 0) {
    L.push("; Magic is for the weak.");
  } else {
    for (const school of schools) {
      for (const [name, id] of CONSOLE_DATA.schoolSpells[school]) {
        L.push("player.addspell " + id + " ; " + name + " (" + school + ")");
      }
    }
  }

  sect("Affliction: " + affliction);
  if (affliction === "Vampire" || affliction === "Vampire Lord") {
    L.push("player.addspell 000b8780 ; Sanguinare Vampiris");
    L.push("; Vampirism sets in naturally after ~3 in-game days (quest-safe).");
    if (affliction === "Vampire Lord") {
      L.push("; For the Vampire Lord form, accept Harkon's gift (Dawnguard).");
    }
  } else if (affliction === "Werewolf") {
    L.push("player.addspell 00092c48 ; Beast Form");
    L.push("set PlayerIsWerewolf to 1");
    L.push("; Note: the Companions questline will still treat you as unblooded.");
  } else {
    L.push("; A pure mortal. Nothing to inject.");
  }

  sect("Faction: " + faction);
  L.push("; " + CONSOLE_DATA.factionHints[faction]);

  sect("Gold for the road");
  L.push("player.additem f 100 ; 100 gold");

  // Rules that carry a mechanical penalty (Born without magicka, Anemic...)
  const enforced = state.roleplayRules.items.filter((r) => r.consoleCmds);
  if (enforced.length) {
    sect("Roleplay rules, enforced by the engine");
    for (const r of enforced) {
      for (const cmd of r.consoleCmds) L.push(cmd + " ; " + r.name);
    }
  }

  sect("Your oath (no console command can enforce honor)");
  if (isDragonborn) L.push("; Dragonborn: the Voice awakens with the main quest. FUS RO DAH.");
  L.push("; Combat style: " + style);
  L.push("; Deity: " + state.deity.items[0].name);
  L.push("; Morality: " + state.morality.items[0].name + " - " + state.morality.items[0].description);
  for (const r of state.roleplayRules.items) {
    L.push("; Rule - " + r.name + ": " + r.description);
  }

  return L.join("\n") + "\n";
}

// Tutorial popup shown alongside the download, reusing the options modal
// shell (its close button, overlay click, and Escape already work).
function openBatchTutorial() {
  const c = state.character.items[0];
  const female = c.description.startsWith("Female");
  const race = state.race.items[0].name;
  const affliction = state.affliction.items[0].name;
  document.getElementById("modal-title").textContent = "Skyrim Setup File — how to use";
  const hint = document.getElementById("modal-hint");
  hint.textContent = "buildnator.txt is downloading. It sets " + c.name + " up in a new game — Skyrim SE/AE on PC only.";
  hint.className = "modal-hint";
  const body = document.getElementById("modal-body");
  body.innerHTML = "";

  const steps = [
    ["1 · Put the file in the Skyrim folder",
      "Move the downloaded buildnator.txt to the folder that contains SkyrimSE.exe — usually C:\\Program Files (x86)\\Steam\\steamapps\\common\\Skyrim Special Edition."],
    ["2 · Start a new game",
      "In character creation, pick what the console can't set for you: race " + race + ", " + (female ? "female" : "male") + ", and the name " + c.name + ". Appearance is all yours."],
    ["3 · Run the batch",
      "Once you can move freely, open the console with the ` / ~ key (below Esc) and type: bat buildnator — then press Enter and close the console with the same key."],
    ["4 · Live your destiny",
      "Skills, standing stone, gear, spells and gold are applied instantly."
      + (affliction === "Vampire" || affliction === "Vampire Lord"
        ? " You've been infected with Sanguinare Vampiris — vampirism sets in after ~3 in-game days."
        : affliction === "Werewolf" ? " Beast blood already runs in your veins — transform via the Powers menu." : "")
      + " The file itself is your build sheet: faction directions and your roleplay oath are written in its comments."],
    ["A note on achievements",
      "Using the console disables achievements for that session on SE/AE. Save after running the batch and reload — achievements come back."],
  ];

  for (const [title, text] of steps) {
    const row = document.createElement("div");
    row.className = "modal-step";
    const name = document.createElement("p");
    name.className = "card-value";
    name.textContent = title;
    row.appendChild(name);
    const desc = document.createElement("p");
    desc.className = "card-desc";
    desc.textContent = text;
    row.appendChild(desc);
    body.appendChild(row);
  }
  document.getElementById("modal-overlay").classList.remove("hidden");
}

function downloadBatch() {
  const blob = new Blob([buildBatchFile()], { type: "text/plain" });
  const a = document.createElement("a");
  a.href = URL.createObjectURL(blob);
  a.download = "buildnator.txt";
  document.body.appendChild(a);
  a.click();
  a.remove();
  URL.revokeObjectURL(a.href);
  openBatchTutorial();
}

document.getElementById("batch-btn").addEventListener("click", downloadBatch);
