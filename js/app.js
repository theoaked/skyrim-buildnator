// Skyrim Buildnator — randomization, lock/reroll logic, and rendering.

// Display order. Categories with custom roll logic (see SPECIAL_IDS) are
// special-cased below; the rest roll generically from their pool.
const CATEGORIES = [
  { id: "character", label: "Character" },
  { id: "race", label: "Race", pool: BUILD_DATA.race, count: 1 },
  { id: "archetype", label: "Archetype" },
  { id: "dragonborn", label: "Dragonborn" },
  { id: "skills", label: "Primary Skills" },
  { id: "standingStone", label: "Standing Stone", pool: BUILD_DATA.standingStone, count: 1 },
  { id: "combatStyle", label: "Combat Style" },
  { id: "armor", label: "Armor", pool: BUILD_DATA.armor, count: 1 },
  { id: "weapon", label: "Weapon of Choice" },
  { id: "magicSchools", label: "Magic Schools" },
  { id: "affliction", label: "Affliction" },
  { id: "faction", label: "Faction" },
  { id: "deity", label: "Deity", pool: BUILD_DATA.deity, count: 1 },
  { id: "morality", label: "Morality", pool: BUILD_DATA.morality, count: 1 },
  { id: "roleplayRules", label: "Roleplay Rules" },
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

function lockedArchetypeRequires() {
  if (!isLocked("archetype")) return {};
  return state.archetype.items[0].requires || {};
}

function lockedArmorRequires() {
  if (!isLocked("armor")) return {};
  return state.armor.items[0].requires || {};
}

// Aggregated constraints imposed by a locked roleplay rules card.
function lockedRuleFlags() {
  if (!isLocked("roleplayRules")) return { incompatibleWeapons: [] };
  const items = state.roleplayRules.items;
  return {
    requiresMagic: items.some((r) => r.requiresMagic),
    requiresNoMagic: items.some((r) => r.requiresNoMagic),
    incompatibleWeapons: items.map((r) => r.incompatibleWeapon).filter(Boolean),
  };
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
  const archReq = lockedArchetypeRequires();
  if (archReq.weaponName) pool = pool.filter((w) => w.name === archReq.weaponName);
  if (archReq.weaponSkillIn) pool = pool.filter((w) => archReq.weaponSkillIn.includes(w.skill));
  const armorReq = lockedArmorRequires();
  if (armorReq.weaponSkillNot) pool = pool.filter((w) => !armorReq.weaponSkillNot.includes(w.skill));
  const ruleWeapons = lockedRuleFlags().incompatibleWeapons;
  if (ruleWeapons.length) pool = pool.filter((w) => !ruleWeapons.includes(w.name));
  setItems("weapon", sample(pool, 1));
}

function skillsConflict(a, b) {
  return BUILD_DATA.skillConflicts.some((group) => group.includes(a) && group.includes(b));
}

// Skills roll. The current weapon's governing skill, a locked combat style's
// required skill, and one of a locked archetype's skillIn are always
// included; skills from the same conflict group never roll together.
function rollSkills() {
  const requiredNames = [];
  const weaponSkill = state.weapon && state.weapon.items[0].skill;
  if (weaponSkill) requiredNames.push(weaponSkill);
  const styleSkill = lockedStyleRequires().skill;
  if (styleSkill && !requiredNames.includes(styleSkill)) requiredNames.push(styleSkill);
  const archSkillIn = lockedArchetypeRequires().skillIn;
  if (archSkillIn && !requiredNames.some((n) => archSkillIn.includes(n))) {
    const options = archSkillIn.filter(
      (n) => !requiredNames.some((rn) => rn === n || skillsConflict(rn, n))
    );
    if (options.length) requiredNames.push(pick(options));
  }
  const excluded = lockedStyleRequires().excludeSkills || [];
  const picked = requiredNames.map((n) => BUILD_DATA.skills.find((s) => s.name === n));
  for (const candidate of sample(BUILD_DATA.skills, BUILD_DATA.skills.length)) {
    if (picked.length === 3) break;
    if (excluded.includes(candidate.name)) continue;
    if (picked.some((p) => p.name === candidate.name || skillsConflict(p.name, candidate.name))) continue;
    picked.push(candidate);
  }
  setItems("skills", picked);
}

// Magic schools roll (0-2 schools). Locked cards can force specific schools
// in (combat style, archetype), demand at least one (anyMagic styles, Mage
// Robes, magic-bound rules and archetypes), or force zero (Agnostic rule).
function rollMagicSchools() {
  const ruleFlags = lockedRuleFlags();
  if (ruleFlags.requiresNoMagic) {
    setItems("magicSchools", [NONE_ENTRY]);
    return;
  }
  const req = lockedStyleRequires();
  const archReq = lockedArchetypeRequires();
  const mustNames = [];
  if (req.magicSchool) mustNames.push(req.magicSchool);
  if (archReq.magicSchool && !mustNames.includes(archReq.magicSchool)) mustNames.push(archReq.magicSchool);
  if (archReq.magicSchoolIn && !mustNames.some((n) => archReq.magicSchoolIn.includes(n))) {
    mustNames.push(pick(archReq.magicSchoolIn));
  }
  const mustHave = mustNames.map((n) => BUILD_DATA.magicSchools.find((s) => s.name === n));
  let n = Math.floor(Math.random() * 3);
  const needAny = req.anyMagic || archReq.anyMagic || lockedArmorRequires().anyMagic || ruleFlags.requiresMagic;
  if ((needAny || mustHave.length) && n === 0) n = 1;
  if (n < mustHave.length) n = mustHave.length;
  const rest = sample(
    BUILD_DATA.magicSchools.filter((s) => !mustNames.includes(s.name)),
    Math.max(0, n - mustHave.length)
  );
  const items = mustHave.concat(rest);
  setItems("magicSchools", items.length ? items : [NONE_ENTRY]);
}

// Shared requirement check: an entry fits when every requirement it declares
// holds for the current build. Plain fields are exact; *In fields mean "at
// least one of".
function fitsBuild(entry) {
  const r = entry.requires;
  if (!r) return true;
  const weapon = state.weapon.items[0];
  const sk = currentSkillNames();
  const schools = currentMagicSchools();
  if (r.weaponName && weapon.name !== r.weaponName) return false;
  if (r.weaponSkill && weapon.skill !== r.weaponSkill) return false;
  if (r.weaponSkillIn && !r.weaponSkillIn.includes(weapon.skill)) return false;
  if (r.skill && !sk.includes(r.skill)) return false;
  if (r.skillIn && !sk.some((s) => r.skillIn.includes(s))) return false;
  if (r.excludeSkills && sk.some((s) => r.excludeSkills.includes(s))) return false;
  if (r.magicSchool && !schools.includes(r.magicSchool)) return false;
  if (r.magicSchoolIn && !schools.some((s) => r.magicSchoolIn.includes(s))) return false;
  if (r.anyMagic && schools.length === 0) return false;
  if (r.armorIn && !r.armorIn.includes(state.armor.items[0].name)) return false;
  if (r.dragonborn && state.dragonborn.items[0].name !== "Dragonborn") return false;
  return true;
}

// Dragonborn rolls before combat style: a locked "Shouts First" style means
// the character must be Dragonborn.
function rollDragonborn() {
  let pool = BUILD_DATA.dragonborn;
  if (lockedStyleRequires().dragonborn) pool = pool.filter((d) => d.name === "Dragonborn");
  setItems("dragonborn", sample(pool, 1));
}

// Combat style rolls from the styles the rest of the build supports.
// Never empty: "Opportunist" has no requirements.
function rollCombatStyle() {
  setItems("combatStyle", sample(BUILD_DATA.combatStyle.filter(fitsBuild), 1));
}

// Archetype rolls last, from the archetypes the finished build supports
// (e.g. Necromancer only for Conjuration casters, Monk only for Fists).
// Never empty: "Pilgrim" has no requirements.
function rollArchetype() {
  setItems("archetype", sample(BUILD_DATA.archetype.filter(fitsBuild), 1));
}

// Armor rolls after weapon and magic schools: Mage Robes (and any future
// conditional armor) only fit builds that meet their requirements.
function armorFits(entry) {
  const r = entry.requires || {};
  if (r.anyMagic && currentMagicSchools().length === 0) return false;
  if (r.weaponSkillNot && r.weaponSkillNot.includes(state.weapon.items[0].skill)) return false;
  return true;
}

function rollArmor() {
  let pool = BUILD_DATA.armor.filter(armorFits);
  const archArmorIn = lockedArchetypeRequires().armorIn;
  if (archArmorIn) pool = pool.filter((a) => archArmorIn.includes(a.name));
  setItems("armor", sample(pool, 1));
}

// Faction and affliction roll as a coherent pair: a locked affliction keeps
// incompatible factions out of the pool, and the affliction roll always
// respects the current faction.
function rollFaction() {
  let pool = BUILD_DATA.faction;
  if (isLocked("affliction")) {
    const incompatible = state.affliction.items[0].incompatibleFactions || [];
    pool = pool.filter((f) => !incompatible.includes(f.name));
  }
  setItems("faction", sample(pool, 1));
}

function rollAffliction() {
  const faction = state.faction.items[0].name;
  const pool = BUILD_DATA.affliction.filter(
    (a) => !(a.incompatibleFactions || []).includes(faction)
  );
  setItems("affliction", sample(pool, 1));
}

function rulesConflict(a, b) {
  return BUILD_DATA.ruleConflicts.some((group) => group.includes(a) && group.includes(b));
}

// Roleplay rules roll after magic schools: rules flagged requiresMagic only
// fit magic-oriented builds, rules incompatible with the rolled weapon are
// skipped, and contradicting rules never roll together.
function rollRoleplayRules() {
  const hasMagic = currentMagicSchools().length > 0;
  const weaponName = state.weapon.items[0].name;
  const picked = [];
  for (const candidate of sample(BUILD_DATA.roleplayRules, BUILD_DATA.roleplayRules.length)) {
    if (picked.length === 4) break;
    if (candidate.requiresMagic && !hasMagic) continue;
    if (candidate.requiresNoMagic && hasMagic) continue;
    if (candidate.incompatibleWeapon === weaponName) continue;
    if (picked.some((p) => rulesConflict(p.name, candidate.name))) continue;
    picked.push(candidate);
  }
  setItems("roleplayRules", picked);
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
const SPECIAL_IDS = ["character", "skills", "weapon", "magicSchools", "armor", "combatStyle", "archetype", "dragonborn", "roleplayRules", "faction", "affliction"];

let narrativeText = "";

function pick(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

function fill(template, vars) {
  return template.replace(/\{(\w+)\}/g, (_, key) => vars[key]);
}

// Compose a short backstory from the rolled build. Sentences are picked from
// the template pools in BUILD_DATA.narrative.
function buildNarrative() {
  const N = BUILD_DATA.narrative;
  const character = state.character.items[0];
  const male = character.description.startsWith("Male");
  const sk = currentSkillNames();
  const weaponName = state.weapon.items[0].name;
  const faction = state.faction.items[0].name;
  const vars = {
    name: character.name,
    sub: male ? "he" : "she",
    obj: male ? "him" : "her",
    pos: male ? "his" : "her",
    origin: N.origins[state.race.items[0].name],
    archetype: state.archetype.items[0].name.toLowerCase(),
    skills: sk.slice(0, -1).join(", ") + " and " + sk[sk.length - 1],
    stone: state.standingStone.items[0].name,
    weapon: weaponName === "Fists" ? "bare fists" : "the " + weaponName.toLowerCase(),
    style: state.combatStyle.items[0].name.toLowerCase(),
    deity: state.deity.items[0].name,
    faction: faction,
  };
  vars.moral = fill(N.morals[state.morality.items[0].name], vars);

  const sentences = [pick(N.openings), pick(N.paths), pick(N.creeds)];
  const afflictionLine = N.afflictions[state.affliction.items[0].name];
  if (afflictionLine) sentences.push(afflictionLine);
  if (state.dragonborn.items[0].name === "Dragonborn") sentences.push(pick(N.dragonborn));
  sentences.push(pick(faction === "None" ? N.fatesAlone : N.fates));

  return sentences
    .map((s) => fill(s, vars))
    .join(" ")
    .replace(/(^|\.\s+)([a-z])/g, (m, sep, ch) => sep + ch.toUpperCase());
}

function generateAll() {
  // Plain categories first (race before character), then the dependent chain:
  // weapon -> skills (must include the weapon's skill) -> magic schools ->
  // armor and roleplay rules (both magic-aware) -> dragonborn -> combat style
  // and archetype (both picked from what the build supports) -> character
  // name -> backstory.
  for (const cat of CATEGORIES) {
    if (isLocked(cat.id) || SPECIAL_IDS.includes(cat.id)) continue;
    state[cat.id] = rollCategory(cat);
  }
  if (!isLocked("faction")) rollFaction();
  if (!isLocked("affliction")) rollAffliction();
  if (!isLocked("weapon")) rollWeapon();
  if (!isLocked("skills")) rollSkills(); // locked skills need no fix: weapon roll was constrained to them
  if (!isLocked("magicSchools")) rollMagicSchools();
  if (!isLocked("armor")) rollArmor();
  if (!isLocked("roleplayRules")) rollRoleplayRules();
  if (!isLocked("dragonborn")) rollDragonborn();
  if (!isLocked("combatStyle")) rollCombatStyle();
  if (!isLocked("archetype")) rollArchetype();
  if (!isLocked("character")) rollCharacter();
  narrativeText = buildNarrative();
  render();
}

function toggleLock(catId) {
  state[catId].locked = !state[catId].locked;
  render();
}

// All options shown by the per-card 📜 button (the character card has none —
// its name pools are too long to be useful in a list).
function optionsFor(catId) {
  if (catId === "magicSchools") return [NONE_ENTRY].concat(BUILD_DATA.magicSchools);
  return BUILD_DATA[catId];
}

function openOptionsModal(cat) {
  document.getElementById("modal-title").textContent = cat.label + " — all options";
  const body = document.getElementById("modal-body");
  body.innerHTML = "";
  for (const option of optionsFor(cat.id)) {
    const row = document.createElement("div");
    row.className = "modal-option";
    const name = document.createElement("p");
    name.className = "card-value";
    name.textContent = option.name;
    row.appendChild(name);
    if (option.description) {
      const desc = document.createElement("p");
      desc.className = "card-desc";
      desc.textContent = option.description;
      row.appendChild(desc);
    }
    body.appendChild(row);
  }
  document.getElementById("modal-overlay").classList.remove("hidden");
}

function closeOptionsModal() {
  document.getElementById("modal-overlay").classList.add("hidden");
}

function render() {
  document.getElementById("narrative").textContent = narrativeText;
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

    if (cat.id !== "character") {
      const optionsBtn = document.createElement("button");
      optionsBtn.className = "icon-btn";
      optionsBtn.title = "View all " + cat.label + " options";
      optionsBtn.setAttribute("aria-label", "View all " + cat.label + " options");
      optionsBtn.textContent = "\u{1F4DC}";
      optionsBtn.addEventListener("click", () => openOptionsModal(cat));
      actions.append(optionsBtn);
    }

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
  lines.push("", narrativeText);
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
document.getElementById("modal-close").addEventListener("click", closeOptionsModal);
document.getElementById("modal-overlay").addEventListener("click", (e) => {
  if (e.target === e.currentTarget) closeOptionsModal();
});
document.addEventListener("keydown", (e) => {
  if (e.key === "Escape") closeOptionsModal();
});

generateAll();
