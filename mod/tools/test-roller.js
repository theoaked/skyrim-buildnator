// Offline parity check for BLD_Roller.psc: simulates the mod's forward-only
// roll pipeline (same algorithm, same data) and asserts the site's coherence
// invariants over many rolls. The Papyrus compiler validates syntax; this
// validates the algorithm.

const fs = require("fs");
const path = require("path");

const repo = path.join(__dirname, "..", "..");
const dataSrc = fs.readFileSync(path.join(repo, "js", "data.js"), "utf8");
const D = new Function(dataSrc + "\nreturn BUILD_DATA;")();

const MAGIC_SKILLS = ["Alteration", "Conjuration", "Destruction", "Illusion", "Restoration", "Enchanting"];
const rand = (n) => Math.floor(Math.random() * n);
const pickFrom = (arr) => arr[rand(arr.length)];
const shuffled = (arr) => {
  const a = arr.slice();
  for (let i = a.length - 1; i > 0; i--) {
    const j = rand(i + 1);
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
};

const skillsConflict = (a, b) =>
  D.skillConflicts.some((g) => g.includes(a) && g.includes(b));
const rulesConflict = (a, b) =>
  D.ruleConflicts.some((g) => g.includes(a) && g.includes(b));

// Mirrors BLD_Roller roll order and filters exactly.
function rollBuild() {
  const b = {};
  b.race = pickFrom(D.race).name;
  b.stone = pickFrom(D.standingStone).name;
  b.deity = pickFrom(D.deity);
  b.morality = pickFrom(D.morality).name;
  b.faction = pickFrom(D.faction);
  b.affliction = shuffled(D.affliction).find(
    (a) => !(a.incompatibleFactions || []).includes(b.faction.name)
  );
  b.weapon = pickFrom(D.weapon);
  const weaponSkill = b.weapon.skill || "";

  // skills
  b.skills = weaponSkill ? [weaponSkill] : [];
  for (const c of shuffled(D.skills)) {
    if (b.skills.length === 3) break;
    if (b.skills.some((s) => s === c.name || skillsConflict(s, c.name))) continue;
    b.skills.push(c.name);
  }

  // schools
  let n = rand(3);
  if (b.skills.some((s) => MAGIC_SKILLS.includes(s)) && n === 0) n = 1;
  b.schools = shuffled(D.magicSchools).slice(0, n).map((s) => s.name);

  // armor
  b.armor = shuffled(D.armor).find((a) => {
    const r = a.requires || {};
    if (r.anyMagic && b.schools.length === 0) return false;
    if (r.weaponSkillNot && r.weaponSkillNot.includes(weaponSkill)) return false;
    return true;
  }).name;

  // rules
  const hasMagic = b.schools.length > 0;
  const hasDaedra = Boolean(b.deity.daedric || b.affliction.daedric || b.faction.daedric);
  b.rules = [];
  for (const c of shuffled(D.roleplayRules)) {
    if (b.rules.length === 4) break;
    if (c.requiresMagic && !hasMagic) continue;
    if (c.requiresNoMagic && hasMagic) continue;
    if (c.incompatibleWeapon === b.weapon.name) continue;
    if (c.noDaedra && hasDaedra) continue;
    if ((c.incompatibleDeities || []).includes(b.deity.name)) continue;
    if ((c.incompatibleFactions || []).includes(b.faction.name)) continue;
    if (b.rules.some((p) => rulesConflict(p.name, c.name))) continue;
    b.rules.push(c);
  }

  b.dragonborn = Math.random() < 0.5;

  const fits = (entry) => {
    const r = entry.requires;
    if (!r) return true;
    if (r.weaponName && b.weapon.name !== r.weaponName) return false;
    if (r.weaponSkill && weaponSkill !== r.weaponSkill) return false;
    if (r.weaponSkillIn && !r.weaponSkillIn.includes(weaponSkill)) return false;
    if (r.skill && !b.skills.includes(r.skill)) return false;
    if (r.skillIn && !b.skills.some((s) => r.skillIn.includes(s))) return false;
    if (r.excludeSkills && b.skills.some((s) => r.excludeSkills.includes(s))) return false;
    if (r.magicSchool && !b.schools.includes(r.magicSchool)) return false;
    if (r.magicSchoolIn && !b.schools.some((s) => r.magicSchoolIn.includes(s))) return false;
    if (r.anyMagic && b.schools.length === 0) return false;
    if (r.armorIn && !r.armorIn.includes(b.armor)) return false;
    if (r.dragonborn && !b.dragonborn) return false;
    return true;
  };

  b.style = shuffled(D.combatStyle).find(fits);
  b.archetype = shuffled(D.archetype).find(fits);
  b.fits = fits;
  return b;
}

let failures = 0;
const fail = (msg, b) => {
  failures++;
  console.error("FAIL: " + msg, JSON.stringify({
    weapon: b.weapon.name, skills: b.skills, schools: b.schools, armor: b.armor,
    style: b.style && b.style.name, archetype: b.archetype && b.archetype.name,
    rules: b.rules.map((r) => r.name), deity: b.deity.name,
    faction: b.faction.name, affliction: b.affliction.name,
  }));
};

const seen = { styles: new Set(), archetypes: new Set(), rules: new Set() };

for (let i = 0; i < 5000; i++) {
  const b = rollBuild();
  seen.styles.add(b.style.name);
  seen.archetypes.add(b.archetype.name);
  b.rules.forEach((r) => seen.rules.add(r.name));

  if (b.weapon.skill && !b.skills.includes(b.weapon.skill)) fail("weapon skill not primary", b);
  if (new Set(b.skills).size !== 3) fail("skills not 3 distinct", b);
  for (const s of b.skills) for (const t of b.skills)
    if (s !== t && skillsConflict(s, t)) fail("conflicting skills", b);
  if (b.skills.some((s) => MAGIC_SKILLS.includes(s)) && b.schools.length === 0)
    fail("magic skill without school", b);
  if (b.armor === "Mage Robes" && (b.schools.length === 0 || ["Two-Handed", "Archery"].includes(b.weapon.skill)))
    fail("Mage Robes misfit", b);
  if (!b.style || !b.fits(b.style)) fail("style misfit", b);
  if (!b.archetype || !b.fits(b.archetype)) fail("archetype misfit", b);
  if (b.rules.length !== 4) fail("rules not 4", b);
  const hasMagic = b.schools.length > 0;
  const hasDaedra = Boolean(b.deity.daedric || b.affliction.daedric || b.faction.daedric);
  for (const r of b.rules) {
    if (r.requiresMagic && !hasMagic) fail("requiresMagic broken: " + r.name, b);
    if (r.requiresNoMagic && hasMagic) fail("requiresNoMagic broken: " + r.name, b);
    if (r.incompatibleWeapon === b.weapon.name) fail("incompatibleWeapon broken: " + r.name, b);
    if (r.noDaedra && hasDaedra) fail("noDaedra broken: " + r.name, b);
    if ((r.incompatibleDeities || []).includes(b.deity.name)) fail("incompatibleDeities broken", b);
    if ((r.incompatibleFactions || []).includes(b.faction.name)) fail("incompatibleFactions broken", b);
    for (const o of b.rules)
      if (o !== r && rulesConflict(r.name, o.name)) fail("conflicting rules", b);
  }
  if ((b.affliction.incompatibleFactions || []).includes(b.faction.name))
    fail("affliction-faction incompatible", b);
}

// Reachability: everything in each pool should roll eventually.
for (const s of D.combatStyle) if (!seen.styles.has(s.name)) fail("style never rolled: " + s.name, { weapon: {}, skills: [], schools: [], rules: [], deity: {}, faction: {}, affliction: {} });
for (const a of D.archetype) if (!seen.archetypes.has(a.name)) fail("archetype never rolled: " + a.name, { weapon: {}, skills: [], schools: [], rules: [], deity: {}, faction: {}, affliction: {} });
for (const r of D.roleplayRules) if (!seen.rules.has(r.name)) fail("rule never rolled: " + r.name, { weapon: {}, skills: [], schools: [], rules: [], deity: {}, faction: {}, affliction: {} });

if (failures) {
  console.error(failures + " FAILURES");
  process.exit(1);
}
console.log("ROLLER PARITY OK — 5000 rolls, all invariants hold, all pool entries reachable");
