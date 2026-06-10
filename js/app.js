// Skyrim Buildnator — randomization, lock/reroll logic, and rendering.

// Display order. Categories with custom roll logic (character, skills, weapon)
// are special-cased below; the rest roll generically from their pool.
const CATEGORIES = [
  { id: "character", label: "Character" },
  { id: "race", label: "Race", pool: BUILD_DATA.race, count: 1 },
  { id: "archetype", label: "Archetype", pool: BUILD_DATA.archetype, count: 1 },
  { id: "skills", label: "Primary Skills", pool: BUILD_DATA.skills, count: 3 },
  { id: "standingStone", label: "Standing Stone", pool: BUILD_DATA.standingStone, count: 1 },
  { id: "combatStyle", label: "Combat Style", pool: BUILD_DATA.combatStyle, count: 1 },
  { id: "armor", label: "Armor", pool: BUILD_DATA.armor, count: 1 },
  { id: "weapon", label: "Weapon of Choice", pool: BUILD_DATA.weapon, count: 1 },
  { id: "magicSchools", label: "Magic Schools", pool: BUILD_DATA.magicSchools, count: () => Math.floor(Math.random() * 3) },
  { id: "affliction", label: "Affliction", pool: BUILD_DATA.affliction, count: 1 },
  { id: "faction", label: "Faction", pool: BUILD_DATA.faction, count: 1 },
  { id: "deity", label: "Deity", pool: BUILD_DATA.deity, count: 1 },
  { id: "morality", label: "Morality", pool: BUILD_DATA.morality, count: 1 },
  { id: "roleplayRules", label: "Roleplay Rules", pool: BUILD_DATA.roleplayRules, count: 2 },
  { id: "challenge", label: "Challenge", pool: BUILD_DATA.challenge, count: 1 },
];

const NONE_ENTRY = { name: "None", description: "Magic is for the weak." };

// state[id] = { items: [...], locked: boolean }
const state = {};

function sample(pool, n) {
  const copy = pool.slice();
  for (let i = copy.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [copy[i], copy[j]] = [copy[j], copy[i]];
  }
  return copy.slice(0, n);
}

function isLocked(catId) {
  return Boolean(state[catId] && state[catId].locked);
}

function setItems(catId, items) {
  state[catId] = { items, locked: isLocked(catId) };
}

function rollCategory(cat) {
  const n = typeof cat.count === "function" ? cat.count() : cat.count;
  const items = sample(cat.pool, n);
  return { items: items.length ? items : [NONE_ENTRY], locked: isLocked(cat.id) };
}

function currentSkillNames() {
  return state.skills.items.map((s) => s.name);
}

// Weapon roll. When the skills card is locked, only weapons compatible with
// those skills may come up (unrestricted weapons like Fists/Staff always can).
function rollWeapon() {
  let pool = BUILD_DATA.weapon;
  if (isLocked("skills")) {
    const skills = currentSkillNames();
    pool = pool.filter((w) => !w.skill || skills.includes(w.skill));
  }
  setItems("weapon", sample(pool, 1));
}

// Skills roll. The current weapon's governing skill is always included.
function rollSkills() {
  const required = state.weapon && state.weapon.items[0].skill;
  if (!required) {
    setItems("skills", sample(BUILD_DATA.skills, 3));
    return;
  }
  const requiredEntry = BUILD_DATA.skills.find((s) => s.name === required);
  const rest = sample(BUILD_DATA.skills.filter((s) => s.name !== required), 2);
  setItems("skills", [requiredEntry, ...rest]);
}

// After a free weapon reroll, make sure its governing skill is among the
// primary skills (swap a random one out). Only runs when skills are unlocked.
function reconcileSkillsWithWeapon() {
  const required = state.weapon.items[0].skill;
  if (!required || currentSkillNames().includes(required)) return;
  const requiredEntry = BUILD_DATA.skills.find((s) => s.name === required);
  const items = state.skills.items.slice();
  items[Math.floor(Math.random() * items.length)] = requiredEntry;
  setItems("skills", items);
}

// Name + gender, drawn from the current race's name pool.
function rollCharacter() {
  const race = state.race.items[0].name;
  const gender = Math.random() < 0.5 ? "Male" : "Female";
  const pool = BUILD_DATA.names[race][gender.toLowerCase()];
  const name = pool[Math.floor(Math.random() * pool.length)];
  setItems("character", [{ name, description: gender + " " + race }]);
}

function generateAll() {
  // Race first (character depends on it), weapon before skills (skills must
  // include the weapon's governing skill).
  for (const cat of CATEGORIES) {
    if (isLocked(cat.id) || cat.id === "character" || cat.id === "skills" || cat.id === "weapon") continue;
    state[cat.id] = rollCategory(cat);
  }
  if (!isLocked("weapon")) rollWeapon();
  if (!isLocked("skills")) rollSkills(); // locked skills need no fix: weapon roll was constrained to them
  if (!isLocked("character")) rollCharacter();
  render();
}

function rerollOne(catId) {
  if (catId === "character") {
    rollCharacter();
  } else if (catId === "skills") {
    rollSkills();
  } else if (catId === "weapon") {
    rollWeapon();
    if (!isLocked("skills")) reconcileSkillsWithWeapon();
  } else {
    const cat = CATEGORIES.find((c) => c.id === catId);
    const locked = state[catId].locked;
    state[catId] = rollCategory(cat);
    state[catId].locked = locked;
    if (catId === "race" && !isLocked("character")) rollCharacter();
  }
  render();
}

function toggleLock(catId) {
  state[catId].locked = !state[catId].locked;
  render();
}

function render() {
  const grid = document.getElementById("build-grid");
  grid.innerHTML = "";
  for (const cat of CATEGORIES) {
    const entry = state[cat.id];
    const card = document.createElement("article");
    card.className = "card" + (entry.locked ? " locked" : "");

    const header = document.createElement("div");
    header.className = "card-header";

    const label = document.createElement("h2");
    label.textContent = cat.label;

    const actions = document.createElement("div");
    actions.className = "card-actions";

    const rerollBtn = document.createElement("button");
    rerollBtn.className = "icon-btn";
    rerollBtn.title = "Reroll " + cat.label;
    rerollBtn.setAttribute("aria-label", "Reroll " + cat.label);
    rerollBtn.textContent = "\u{1F3B2}";
    rerollBtn.addEventListener("click", () => rerollOne(cat.id));

    const lockBtn = document.createElement("button");
    lockBtn.className = "icon-btn" + (entry.locked ? " active" : "");
    lockBtn.title = (entry.locked ? "Unlock " : "Lock ") + cat.label;
    lockBtn.setAttribute("aria-label", (entry.locked ? "Unlock " : "Lock ") + cat.label);
    lockBtn.textContent = entry.locked ? "\u{1F512}" : "\u{1F513}";
    lockBtn.addEventListener("click", () => toggleLock(cat.id));

    actions.append(rerollBtn, lockBtn);
    header.append(label, actions);
    card.appendChild(header);

    for (const item of entry.items) {
      const value = document.createElement("p");
      value.className = "card-value";
      value.textContent = item.name;
      card.appendChild(value);
      if (item.description) {
        const desc = document.createElement("p");
        desc.className = "card-desc";
        desc.textContent = item.description;
        card.appendChild(desc);
      }
    }

    grid.appendChild(card);
  }
}

function buildSummary() {
  const lines = ["SKYRIM BUILDNATOR — Your destiny:", ""];
  for (const cat of CATEGORIES) {
    const names = state[cat.id].items.map((i) => i.name).join(", ");
    lines.push(cat.label + ": " + names);
  }
  lines.push("", "Rolled at https://theoaked.github.io/skyrim-buildnator/");
  return lines.join("\n");
}

function copyBuild() {
  navigator.clipboard.writeText(buildSummary()).then(() => {
    const btn = document.getElementById("copy-btn");
    const original = btn.textContent;
    btn.textContent = "Copied!";
    setTimeout(() => { btn.textContent = original; }, 1500);
  });
}

document.getElementById("generate-btn").addEventListener("click", generateAll);
document.getElementById("copy-btn").addEventListener("click", copyBuild);

generateAll();
