// Oracle check: compares the in-game port (BLD_Build.psc) with the site's
// real js/app.js. BLD_Build.SelfTest logs transitions to the Papyrus user log
//   T|<gen|choose|dragonborn>|<arg>|<before json>|<after json>
// and this script replays every transition on the site, from the same
// starting state, many times. A mod result is accepted when:
//   - locked cards survived a Generate untouched (the site never touches them);
//   - every card value (each item, for multi cards) is one the site produced
//     from that same start in at least one replay;
//   - every coherence check that fails on the mod's result (weaponFitsNow,
//     fitsBuild, ...) also fails in at least one site replay - i.e. the site
//     has the same blind spot and the port is faithful to it.
// Usage: node mod/tools/check-oracle.js [path-to-Buildnator.0.log] [replays]

const fs = require("fs");
const os = require("os");
const path = require("path");
const crypto = require("crypto");

const repo = path.join(__dirname, "..", "..");
// Documents may live under OneDrive.
const logPath = process.argv[2] || ["OneDrive/Documents", "Documents"]
  .map((d) => path.join(os.homedir(), d, "My Games", "Skyrim Special Edition", "Logs", "Script", "User", "Buildnator.0.log"))
  .find((p) => fs.existsSync(p)) || "Buildnator.0.log";
const REPLAYS = Number(process.argv[3] || 300);

// ---------- load the real site logic with a do-nothing DOM ----------

function domStub() {
  const p = new Proxy(() => p, {
    get: (t, k) => (k === Symbol.toPrimitive ? () => "" : k === Symbol.iterator ? [][Symbol.iterator] : p),
    set: () => true,
    apply: () => p,
  });
  return p;
}

function loadSite() {
  const src = ["data.js", "app.js"].map((f) => fs.readFileSync(path.join(repo, "js", f), "utf8")).join("\n");
  const expose = `
    return {
      BUILD_DATA, CATEGORIES, NONE_ENTRY, state, optionsFor,
      generateAll, applyChoice, setDragonborn,
      weaponFitsNow, skillsFitNow, magicFitsNow, armorFitsNow, rulesFitNow, fitsBuild,
      deityAllowedByLockedRules, factionAllowedByLockedRules, skillsConflict, rulesConflict,
      getDB: () => isDragonborn, setDB: (v) => { isDragonborn = v; },
      setCustom: (n, g) => { customName = n; customGender = g; },
    };`;
  return new Function("document", "navigator", src + expose)(domStub(), domStub());
}

const S = loadSite();
const D = S.BUILD_DATA;
const dataHash = crypto.createHash("sha1")
  .update(fs.readFileSync(path.join(repo, "js", "data.js"))).digest("hex").slice(0, 10);

// ---------- mod state <-> site state ----------

const ci = (a, b) => a.toLowerCase() === b.toLowerCase(); // Papyrus strings are case-insensitive
const poolOf = (id) => (id === "magicSchools" ? [S.NONE_ENTRY].concat(D.magicSchools) : D[id]);
const findIn = (pool, name) => pool.find((e) => ci(e.name, name));

function toSite(json) {
  // Papyrus' string table is case-insensitive: the first spelling it saw wins
  // ("WEAPON", "Skills", "male"), so keys and values are matched ignoring case.
  const raw = JSON.parse(json);
  const m = {};
  for (const [k, v] of Object.entries(raw)) m[k.toLowerCase()] = v;
  for (const cat of S.CATEGORIES) if (cat.id.toLowerCase() in m) m[cat.id] = m[cat.id.toLowerCase()];
  for (const cat of S.CATEGORIES) {
    const locked = m.locks[S.CATEGORIES.indexOf(cat)] === "1";
    let items;
    if (cat.id === "character") {
      const [name, g, race] = m.character.split("|");
      const gender = g.charAt(0).toUpperCase() + g.slice(1).toLowerCase();
      items = [{ name, description: gender + " " + race }];
    } else {
      items = m[cat.id].split("|").filter(Boolean).map((n) => {
        const e = findIn(poolOf(cat.id), n);
        if (!e) throw new Error(`unknown ${cat.id} value "${n}"`);
        return e;
      });
      if (cat.id === "magicSchools" && items.length === 0) items = [S.NONE_ENTRY];
    }
    S.state[cat.id] = { items, locked };
  }
  S.setDB(m.dragonborn === 1);
  S.setCustom(null, null);
  return m;
}

const names = (id) => S.state[id].items.map((i) => i.name);
const valueKey = (id) => names(id).slice().sort().join("|");
const MULTI = ["skills", "magicSchools", "roleplayRules"];

// Coherence checks, all from app.js, evaluated under the given lock set.
function checks(lockedIds) {
  const saved = {};
  for (const cat of S.CATEGORIES) {
    saved[cat.id] = S.state[cat.id].locked;
    S.state[cat.id].locked = lockedIds.includes(cat.id);
  }
  const affl = S.state.affliction.items[0];
  const sk = names("skills");
  const rules = names("roleplayRules");
  const res = {
    weaponFitsNow: S.weaponFitsNow(),
    skillsFitNow: S.skillsFitNow(),
    magicFitsNow: S.magicFitsNow(),
    armorFitsNow: S.armorFitsNow(),
    rulesFitNow: S.rulesFitNow(),
    styleFits: S.fitsBuild(S.state.combatStyle.items[0]),
    archetypeFits: S.fitsBuild(S.state.archetype.items[0]),
    deityAllowed: S.deityAllowedByLockedRules(S.state.deity.items[0]),
    factionAllowed: S.factionAllowedByLockedRules(S.state.faction.items[0]),
    afflictionPair: !(affl.incompatibleFactions || []).includes(S.state.faction.items[0].name),
    threeSkills: sk.length === 3,
    skillsNoConflict: !sk.some((a, i) => sk.some((b, j) => i < j && S.skillsConflict(a, b))),
    rulesNoConflict: !rules.some((a, i) => rules.some((b, j) => i < j && S.rulesConflict(a, b))),
    rulesCount: rules.length >= 3 && rules.length <= 8,
  };
  for (const cat of S.CATEGORIES) S.state[cat.id].locked = saved[cat.id];
  return res;
}

function lockedIdsOf(m) {
  return S.CATEGORIES.filter((c, i) => m.locks[i] === "1").map((c) => c.id);
}

// Run one logged operation on the site from the current state.
function runOp(kind, arg) {
  if (kind === "gen") S.generateAll();
  else if (kind === "dragonborn") S.setDragonborn(arg === "1");
  else {
    const sep = arg.indexOf(":");
    const cat = S.CATEGORIES.find((c) => c.id === arg.slice(0, sep));
    const option = findIn(S.optionsFor(cat.id), arg.slice(sep + 1));
    S.applyChoice(cat, option);
  }
}

// Locks the post-op checks run under, mirroring the regime the site's own
// rolls guarantee: Generate keeps the user's locks; a choice reconciles with
// only the chosen card pinned.
function checkLocks(kind, arg, before) {
  if (kind === "choose") return [arg.slice(0, arg.indexOf(":"))];
  return lockedIdsOf(before);
}

// ---------- main ----------

if (!fs.existsSync(logPath)) {
  console.error("No log at " + logPath + " - run the MCM self-test with [Papyrus] bEnableLogging=1 first.");
  process.exit(2);
}
const lines = fs.readFileSync(logPath, "utf8").split(/\r?\n/);
const begin = lines.find((l) => l.includes("BEGIN|"));
if (begin) {
  const h = begin.split("BEGIN|")[1].split("|")[0];
  if (h !== dataHash) {
    console.error(`Log was made from data hash ${h}, site data.js is ${dataHash}. Rebuild/redeploy the mod and rerun the self-test.`);
    process.exit(2);
  }
}

const findings = [];
const tally = { gen: 0, choose: 0, dragonborn: 0 };
let narratives = 0;
for (const raw of lines) {
  const nm = raw.match(/(?:^|\] )N\|(.*)$/);
  if (nm) {
    const text = nm[1];
    narratives++;
    if (/[{}]/.test(text) || text.length < 80) findings.push({ kind: "narrative", detail: text });
    continue;
  }
  const tm = raw.match(/(?:^|\] )T\|(.*)$/);
  if (!tm) continue;
  const body = tm[1];
  const p1 = body.indexOf("|");
  const p2 = body.indexOf("|", p1 + 1);
  const kind = body.slice(0, p1);
  let arg = body.slice(p1 + 1, p2);
  if (kind === "choose") {
    // restore the canonical category id (Papyrus may log "WEAPON:Staff")
    const sep = arg.indexOf(":");
    const cat = S.CATEGORIES.find((c) => ci(c.id, arg.slice(0, sep)));
    arg = cat.id + arg.slice(sep);
  }
  const [beforeJson, afterJson] = body.slice(p2 + 1).split("}|{").map((s, i) => (i === 0 ? s + "}" : "{" + s));
  tally[kind]++;

  // the mod's result
  const before = toSite(beforeJson);
  const regime = checkLocks(kind, arg, before);
  const after = toSite(afterJson);
  const modVals = {};
  for (const c of S.CATEGORIES) modVals[c.id] = names(c.id);
  const modChecks = checks(regime);

  // site replays from the same start
  const seenVals = {};
  const seenItems = {};
  const siteFails = {};
  for (const c of S.CATEGORIES) { seenVals[c.id] = new Set(); seenItems[c.id] = new Set(); }
  // Replays until every mod value has been seen or the budget runs out:
  // rare-but-legal values need more samples than common ones.
  const modSeen = () => S.CATEGORIES.every((c) => c.id === "character" ||
    (MULTI.includes(c.id) ? modVals[c.id].every((nm) => seenItems[c.id].has(nm)) : seenVals[c.id].has(modVals[c.id].join("|"))));
  for (let r = 0; r < REPLAYS * 10 && (r < REPLAYS || !modSeen()); r++) {
    toSite(beforeJson);
    runOp(kind, arg);
    for (const c of S.CATEGORIES) {
      if (c.id === "character") continue;
      seenVals[c.id].add(valueKey(c.id));
      for (const nm of names(c.id)) seenItems[c.id].add(nm);
    }
    for (const [k, ok] of Object.entries(checks(regime))) if (!ok) siteFails[k] = true;
  }

  const where = `${kind}${arg ? " " + arg : ""}`;
  if (kind === "gen") {
    for (const id of lockedIdsOf(before)) {
      if (id === "character") continue;
      toSite(beforeJson);
      const b = valueKey(id);
      toSite(afterJson);
      if (b !== valueKey(id)) findings.push({ kind: "lock-broken", where, detail: `${id}: ${b} -> ${valueKey(id)}` });
    }
  }
  for (const c of S.CATEGORIES) {
    if (c.id === "character") continue;
    if (MULTI.includes(c.id)) {
      for (const nm of modVals[c.id]) {
        if (!seenItems[c.id].has(nm)) findings.push({ kind: "unseen-item", where, detail: `${c.id}: ${nm}` });
      }
    } else if (!seenVals[c.id].has(modVals[c.id].join("|"))) {
      findings.push({ kind: "unseen-value", where, detail: `${c.id}: ${modVals[c.id].join("|")} (site: ${[...seenVals[c.id]].join(", ")})` });
    }
  }
  for (const [k, ok] of Object.entries(modChecks)) {
    if (!ok && !siteFails[k]) findings.push({ kind: "incoherent", where, detail: `${k} fails on the mod result; never on the site` });
  }
  void after;
}

const total = tally.gen + tally.choose + tally.dragonborn;
console.log(`Checked ${total} transitions (gen ${tally.gen}, choose ${tally.choose}, dragonborn ${tally.dragonborn}), ${narratives} narratives, ${REPLAYS} site replays each.`);
if (total === 0) {
  console.error("No transitions found in the log.");
  process.exit(2);
}
const byKind = {};
for (const f of findings) (byKind[f.kind] = byKind[f.kind] || []).push(f);
for (const [k, list] of Object.entries(byKind)) {
  console.log(`\n${k}: ${list.length}`);
  for (const f of list.slice(0, 15)) console.log(`  [${f.where || ""}] ${f.detail}`);
}
console.log(findings.length ? `\nORACLE: ${findings.length} finding(s)` : "\nORACLE: PASS - every transition matches the site's behavior.");
process.exit(findings.length ? 1 : 0);
