// Skyrim Buildnator — randomization, lock/reroll logic, and rendering.

// Display order. Categories with custom roll logic (see SPECIAL_IDS) are
// special-cased below; the rest roll generically from their pool.
const CATEGORIES = [
  { id: "character", label: "Character" },
  { id: "race", label: "Race", pool: BUILD_DATA.race, count: 1 },
  { id: "archetype", label: "Archetype", pool: BUILD_DATA.archetype, count: 1 },
  { id: "skills", label: "Primary Skills" },
  { id: "standingStone", label: "Standing Stone", pool: BUILD_DATA.standingStone, count: 1 },
  { id: "combatStyle", label: "Combat Style" },
  { id: "armor", label: "Armor", pool: BUILD_DATA.armor, count: 1 },
  { id: "weapon", label: "Weapon of Choice" },
  { id: "magicSchools", label: "Magic Schools" },
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

function lockedStyleRequires() {
  if (!isLocked("combatStyle")) return {};
  return state.combatStyle.items[0].requires || {};
}

function currentMagicSchools() {
  return state.magicSchools.items.map((i) => i.name).filter((n) => n !== "None");
}

// Weapon roll, constrained by whatever is locked: a locked skills card only
// allows compatible weapons (unrestricted ones like Fists/Staff always fit),
// and a locked combat style enforces its weapon requirements.
function rollWeapon() {
  let pool = BUILD_DATA.weapon;
  if (isLocked("skills")) {
    const skills = currentSkillNames();
    pool = pool.filter((w) => !w.skill || skills.includes(w.skill));
  }
  const req = lockedStyleRequires();
  if (req.weaponName) pool = pool.filter((w) => w.name === req.weaponName);
  if (req.weaponSkill) pool = pool.filter((w) => w.skill === req.weaponSkill);
  setItems("weapon", sample(pool, 1));
}

function skillsConflict(a, b) {
  return BUILD_DATA.skillConflicts.some((group) => group.includes(a) && group.includes(b));
}

// Skills roll. The current weapon's governing skill and a locked combat
// style's required skill are always included, and skills from the same
// conflict group never roll together.
function rollSkills() {
  const requiredNames = [];
  const weaponSkill = state.weapon && state.weapon.items[0].skill;
  if (weaponSkill) requiredNames.push(weaponSkill);
  const styleSkill = lockedStyleRequires().skill;
  if (styleSkill && !requiredNames.includes(styleSkill)) requiredNames.push(styleSkill);
  const picked = requiredNames.map((n) => BUILD_DATA.skills.find((s) => s.name === n));
  for (const candidate of sample(BUILD_DATA.skills, BUILD_DATA.skills.length)) {
    if (picked.length === 3) break;
    if (picked.some((p) => p.name === candidate.name || skillsConflict(p.name, candidate.name))) continue;
    picked.push(candidate);
  }
  setItems("skills", picked);
}

// Magic schools roll (0-2 schools). A locked combat style can force a
// specific school in, or at least one school for anyMagic styles.
function rollMagicSchools() {
  const req = lockedStyleRequires();
  const mustHave = req.magicSchool
    ? [BUILD_DATA.magicSchools.find((s) => s.name === req.magicSchool)]
    : [];
  let n = Math.floor(Math.random() * 3);
  if ((req.anyMagic || mustHave.length) && n === 0) n = 1;
  const rest = sample(
    BUILD_DATA.magicSchools.filter((s) => !mustHave.some((m) => m.name === s.name)),
    Math.max(0, n - mustHave.length)
  );
  const items = mustHave.concat(rest);
  setItems("magicSchools", items.length ? items : [NONE_ENTRY]);
}

// A style fits when every requirement it declares holds for the current build.
function styleFits(style) {
  const r = style.requires || {};
  const weapon = state.weapon.items[0];
  if (r.weaponName && weapon.name !== r.weaponName) return false;
  if (r.weaponSkill && weapon.skill !== r.weaponSkill) return false;
  if (r.skill && !currentSkillNames().includes(r.skill)) return false;
  const schools = currentMagicSchools();
  if (r.magicSchool && !schools.includes(r.magicSchool)) return false;
  if (r.anyMagic && schools.length === 0) return false;
  return true;
}

// Combat style rolls last, from the styles the rest of the build supports.
// Never empty: "Shouts First" has no requirements.
function rollCombatStyle() {
  setItems("combatStyle", sample(BUILD_DATA.combatStyle.filter(styleFits), 1));
}

// Name + gender, drawn from the current race's name pool.
function rollCharacter() {
  const race = state.race.items[0].name;
  const gender = Math.random() < 0.5 ? "Male" : "Female";
  const pool = BUILD_DATA.names[race][gender.toLowerCase()];
  const name = pool[Math.floor(Math.random() * pool.length)];
  setItems("character", [{ name, description: gender + " " + race }]);
}

// Categories with custom roll logic, handled in dependency order below.
const SPECIAL_IDS = ["character", "skills", "weapon", "magicSchools", "combatStyle"];

function generateAll() {
  // Plain categories first (race before character), then the dependent chain:
  // weapon -> skills (must include the weapon's skill) -> magic schools ->
  // combat style (picked from what the build supports) -> character name.
  for (const cat of CATEGORIES) {
    if (isLocked(cat.id) || SPECIAL_IDS.includes(cat.id)) continue;
    state[cat.id] = rollCategory(cat);
  }
  if (!isLocked("weapon")) rollWeapon();
  if (!isLocked("skills")) rollSkills(); // locked skills need no fix: weapon roll was constrained to them
  if (!isLocked("magicSchools")) rollMagicSchools();
  if (!isLocked("combatStyle")) rollCombatStyle();
  if (!isLocked("character")) rollCharacter();
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

    const lockBtn = document.createElement("button");
    lockBtn.className = "icon-btn" + (entry.locked ? " active" : "");
    lockBtn.title = (entry.locked ? "Unlock " : "Lock ") + cat.label;
    lockBtn.setAttribute("aria-label", (entry.locked ? "Unlock " : "Lock ") + cat.label);
    lockBtn.textContent = entry.locked ? "\u{1F512}" : "\u{1F513}";
    lockBtn.addEventListener("click", () => toggleLock(cat.id));

    actions.append(lockBtn);
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
