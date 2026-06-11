// All randomization data pools for the Skyrim Buildnator.
// Each entry: { name, description? }. Categories are consumed generically by app.js.

const BUILD_DATA = {
  race: [
    { name: "Nord", description: "Children of the Sky — resistant to frost, born to battle." },
    { name: "Imperial", description: "Diplomats and traders, with a knack for finding coin." },
    { name: "Breton", description: "Innate resistance to magic and a talent for conjuration." },
    { name: "Redguard", description: "The most naturally talented warriors in Tamriel." },
    { name: "Altmer", description: "High Elves — gifted in the arcane arts, extra magicka." },
    { name: "Bosmer", description: "Wood Elves — masters of bow and stealth." },
    { name: "Dunmer", description: "Dark Elves — fire-resistant, balanced in blade and spell." },
    { name: "Orsimer", description: "Orcs — fearsome berserkers and master smiths." },
    { name: "Argonian", description: "Lizard-folk — waterbreathing, disease-resistant, slippery." },
    { name: "Khajiit", description: "Feline nomads — night eyes and deadly claws." },
  ],

  // Archetypes roll last, from those whose `requires` fit the build (same
  // vocabulary as combat styles, plus *In variants meaning "at least one of"
  // and armorIn). Pilgrim has no requirements, so the pool is never empty.
  archetype: [
    { name: "Warrior", description: "Steel, sweat, and glory. Solve problems with sharp objects.", requires: { weaponSkillIn: ["One-Handed", "Two-Handed"] } },
    { name: "Mage", description: "Why swing a sword when reality itself obeys you?", requires: { anyMagic: true } },
    { name: "Thief", description: "If it isn't nailed down, it's yours.", requires: { skillIn: ["Sneak", "Pickpocket", "Lockpicking"] } },
    { name: "Battlemage", description: "Heavy armor in one hand, devastation in the other.", requires: { anyMagic: true, armorIn: ["Heavy Armor"] } },
    { name: "Spellsword", description: "A blade backed by spellcraft — versatile and deadly.", requires: { anyMagic: true, weaponSkillIn: ["One-Handed"] } },
    { name: "Nightblade", description: "Illusion magic and a dagger from the shadows.", requires: { anyMagic: true, skillIn: ["Sneak"] } },
    { name: "Assassin", description: "One target, one strike, no witnesses.", requires: { skillIn: ["Sneak"] } },
    { name: "Archer", description: "If they can see you, you're doing it wrong. Loose from afar.", requires: { weaponSkillIn: ["Archery"] } },
    { name: "Paladin", description: "A holy warrior — restoration magic, heavy armor, no mercy for the undead.", requires: { magicSchool: "Restoration", armorIn: ["Heavy Armor"] } },
    { name: "Necromancer", description: "Death is not the end — it's the recruitment process.", requires: { magicSchool: "Conjuration" } },
    { name: "Barbarian", description: "No armor crafting, no finesse. Hit things until they stop moving.", requires: { weaponSkillIn: ["Two-Handed"] } },
    { name: "Monk", description: "Fists, robes, and inner peace (delivered at high velocity).", requires: { weaponName: "Fists" } },
    { name: "Witchhunter", description: "Crossbow or bow, alchemy, and a grudge against everything magical.", requires: { weaponSkillIn: ["Archery"] } },
    { name: "Bard", description: "Charm, speechcraft, illusion — talk your way through Skyrim.", requires: { skillIn: ["Speech"] } },
    { name: "Pilgrim", description: "A wanderer visiting every shrine, surviving on wit and faith." },
    { name: "Crusader", description: "Stendarr's hammer made flesh. Smite the profane wherever it hides.", requires: { magicSchool: "Restoration", weaponSkillIn: ["One-Handed", "Two-Handed"] } },
    { name: "Knight", description: "Oath, honor, and a full set of plate. Chivalry isn't dead — you checked.", requires: { armorIn: ["Heavy Armor"], weaponSkillIn: ["One-Handed", "Two-Handed"] } },
    { name: "Ranger", description: "Bow, light armor, and the wilds for a home. Cities make you itch.", requires: { weaponSkillIn: ["Archery"], armorIn: ["Light Armor"] } },
    { name: "Hunter", description: "Track it, trap it, skin it, sell it. Hircine watches with approval.", requires: { weaponSkillIn: ["Archery"] } },
    { name: "Druid", description: "Alchemy, alteration, and a deep distrust of anyone who lives indoors.", requires: { skillIn: ["Alchemy", "Alteration"] } },
    { name: "Shaman", description: "Speak to the spirits, summon their wrath, wear their bones.", requires: { magicSchoolIn: ["Conjuration", "Restoration"] } },
    { name: "Warlock", description: "Forbidden tomes, dark pacts, and a tower full of regrets (other people's).", requires: { magicSchoolIn: ["Conjuration", "Destruction"] } },
    { name: "Sellsword", description: "Loyalty has a price. Fortunately, so does everything else.", requires: { weaponSkillIn: ["One-Handed", "Two-Handed"] } },
    { name: "Gladiator", description: "Born for the pit. Every bandit camp is an arena, every fight a show.", requires: { weaponSkillIn: ["One-Handed", "Two-Handed"] } },
    { name: "Corsair", description: "A pirate stranded ashore. Loot coastal wrecks, drink mead, fear no man.", requires: { weaponSkillIn: ["One-Handed"] } },
    { name: "Alchemist", description: "Poison the blade, drink the experiment, sell the leftovers.", requires: { skillIn: ["Alchemy"] } },
    { name: "Healer", description: "A pacifist mender. Your allies do the killing — you keep them alive.", requires: { magicSchool: "Restoration" } },
    { name: "Scout", description: "First in, never seen, already gone. The map fills itself.", requires: { skillIn: ["Sneak", "Light Armor"] } },
    { name: "Treasure Hunter", description: "Every barrow has a hidden chest, and you have a shovel and no fear.", requires: { skillIn: ["Lockpicking"] } },
    { name: "Court Wizard", description: "Enchanting, alteration, and polite contempt for the Jarl's guests.", requires: { anyMagic: true, skillIn: ["Enchanting", "Alteration", "Illusion"] } },
    { name: "Forsworn Outcast", description: "Fur, feathers, and fury. The Reach remembers what was taken.", requires: { armorIn: ["Light Armor", "Clothes Only"] } },
  ],

  skills: [
    { name: "One-Handed" }, { name: "Two-Handed" }, { name: "Archery" },
    { name: "Block" }, { name: "Smithing" }, { name: "Heavy Armor" },
    { name: "Light Armor" }, { name: "Pickpocket" }, { name: "Lockpicking" },
    { name: "Sneak" }, { name: "Alchemy" }, { name: "Speech" },
    { name: "Alteration" }, { name: "Conjuration" }, { name: "Destruction" },
    { name: "Illusion" }, { name: "Restoration" }, { name: "Enchanting" },
  ],

  // Skills in the same group compete in gameplay and never roll together.
  skillConflicts: [
    ["One-Handed", "Two-Handed"],
    ["Heavy Armor", "Light Armor"],
  ],

  standingStone: [
    { name: "The Warrior", description: "Combat skills improve 20% faster." },
    { name: "The Mage", description: "Magic skills improve 20% faster." },
    { name: "The Thief", description: "Stealth skills improve 20% faster." },
    { name: "The Lover", description: "All skills improve 15% faster." },
    { name: "The Lord", description: "+50 armor rating and 25% magic resistance." },
    { name: "The Lady", description: "Health and stamina regenerate 25% faster." },
    { name: "The Steed", description: "+100 carry weight, no armor speed penalty." },
    { name: "The Apprentice", description: "Double magicka regen — but double weakness to magic." },
    { name: "The Atronach", description: "+50 magicka, 50% spell absorption, no magicka regen." },
    { name: "The Ritual", description: "Once a day, raise all nearby corpses to fight for you." },
    { name: "The Serpent", description: "Once a day, paralyze and poison a target." },
    { name: "The Shadow", description: "Once a day, become invisible for 60 seconds." },
    { name: "The Tower", description: "Once a day, unlock any expert-or-lower lock." },
  ],

  // `requires` ties a style to the rest of the build — every declared field
  // must hold for the style to be rolled (or to constrain rolls when locked):
  // weaponSkill: the weapon's governing skill; weaponName: an exact weapon;
  // skill: a primary skill; magicSchool: a rolled school; anyMagic: >=1 school.
  combatStyle: [
    { name: "Sword & Shield", description: "The classic. Block, bash, stab, repeat.", requires: { weaponSkill: "One-Handed" } },
    { name: "Dual Wield", description: "Two weapons, zero defense, maximum carnage.", requires: { weaponSkill: "One-Handed" } },
    { name: "Two-Handed", description: "Big weapon. Big swings. Big problems for everyone else.", requires: { weaponSkill: "Two-Handed" } },
    { name: "Archery", description: "Death from a distance — preferably while sneaking.", requires: { weaponSkill: "Archery" } },
    { name: "Destruction Magic", description: "Fire, frost, and shock until nothing moves.", requires: { magicSchool: "Destruction" } },
    { name: "Conjuration Summons", description: "Let your minions do the dirty work.", requires: { magicSchool: "Conjuration" } },
    { name: "Unarmed", description: "Fists only. Khajiit claws optional but recommended.", requires: { weaponName: "Fists", excludeSkills: ["One-Handed", "Two-Handed", "Archery"] } },
    { name: "Sneak Attacks", description: "30x dagger multipliers are a lifestyle.", requires: { skill: "Sneak" } },
    { name: "Spell & Blade", description: "Weapon in one hand, spell in the other.", requires: { weaponSkill: "One-Handed", anyMagic: true } },
    { name: "Shouts First", description: "FUS RO DAH is always the answer. Lead with the Voice.", requires: { dragonborn: true } },
    { name: "Opportunist", description: "No doctrine, no dogma — use whatever wins the fight." },
  ],

  // Armor `requires` works like combat style requirements: Mage Robes only
  // roll for casters whose weapon isn't a two-hander or a bow.
  armor: [
    { name: "Heavy Armor", description: "Walk slow, hit hard, fear nothing." },
    { name: "Light Armor", description: "Mobility and protection in balance." },
    { name: "Mage Robes", description: "Enchanted cloth — your magicka is your armor.", requires: { anyMagic: true, weaponSkillNot: ["Two-Handed", "Archery"] } },
    { name: "Clothes Only", description: "No armor at all. Fashion over function. Good luck." },
  ],

  // `skill` ties the weapon to a primary skill — the app guarantees that skill
  // is among the rolled Primary Skills. Weapons without `skill` are unrestricted.
  weapon: [
    { name: "Sword", description: "Fast, reliable, classic.", skill: "One-Handed" },
    { name: "War Axe", description: "Make them bleed.", skill: "One-Handed" },
    { name: "Mace", description: "Armor means nothing to you.", skill: "One-Handed" },
    { name: "Greatsword", description: "Elegant, enormous, exhausting.", skill: "Two-Handed" },
    { name: "Battleaxe", description: "For when subtlety is not on the menu.", skill: "Two-Handed" },
    { name: "Warhammer", description: "The biggest, slowest, most satisfying option.", skill: "Two-Handed" },
    { name: "Dagger", description: "Small blade, huge sneak multipliers.", skill: "One-Handed" },
    { name: "Bow", description: "The ol' reliable of Skyrim.", skill: "Archery" },
    { name: "Crossbow", description: "Slow to reload, brutal on impact (Dawnguard).", skill: "Archery" },
    { name: "Staff", description: "Channel destruction without lifting a spellbook." },
    { name: "Fists", description: "Weapons are a crutch." },
  ],

  magicSchools: [
    { name: "Destruction", description: "Flames, frostbite, sparks — applied liberally." },
    { name: "Conjuration", description: "Summon atronachs, raise the dead, bind weapons." },
    { name: "Illusion", description: "Fury, fear, calm, invisibility — the puppeteer's school." },
    { name: "Alteration", description: "Mage armor, paralysis, and bending the rules of reality." },
    { name: "Restoration", description: "Heal yourself, ward off spells, turn the undead." },
  ],

  faction: [
    { name: "The Companions", description: "Honor, glory, and a furry little secret in Jorrvaskr." },
    { name: "College of Winterhold", description: "Skyrim's last bastion of magical learning." },
    { name: "Thieves Guild", description: "Restore the Guild's former glory, one heist at a time." },
    { name: "Dark Brotherhood", description: "Hail Sithis. The contracts won't fulfill themselves." },
    { name: "Imperial Legion", description: "Unite Skyrim under the Empire's banner." },
    { name: "Stormcloaks", description: "Skyrim belongs to the Nords!" },
    { name: "Dawnguard", description: "Vampire hunters with very large crossbows." },
    { name: "Volkihar Vampires", description: "Embrace the night. Become the monster.", daedric: true },
    { name: "Bards College", description: "Poems, drums, flutes — and the occasional tomb raid." },
    { name: "None", description: "A lone wanderer. Factions are for people with friends." },
  ],

  deity: [
    { name: "Akatosh", description: "Dragon God of Time, chief of the Divines." },
    { name: "Talos", description: "Hero-god of mankind. Worship at your own risk." },
    { name: "Kynareth", description: "Goddess of the air, wind, and sky." },
    { name: "Mara", description: "Goddess of love and compassion." },
    { name: "Dibella", description: "Goddess of beauty and artistry." },
    { name: "Stendarr", description: "God of mercy and righteous might." },
    { name: "Zenithar", description: "God of work and commerce." },
    { name: "Julianos", description: "God of wisdom and logic." },
    { name: "Arkay", description: "God of the cycle of life and death." },
    { name: "Nocturnal", description: "Daedric Prince of night and luck — patron of thieves.", daedric: true },
    { name: "Meridia", description: "Daedric Prince of life — sworn enemy of the undead.", daedric: true },
    { name: "Hircine", description: "Daedric Prince of the Hunt — father of werebeasts.", daedric: true },
    { name: "Mephala", description: "Daedric Prince of plots, lies, and webs.", daedric: true },
  ],

  morality: [
    { name: "Saint", description: "Never steal, never kill innocents, help everyone in need." },
    { name: "Good", description: "Do the right thing — but coin is coin." },
    { name: "Neutral", description: "Look out for yourself. The war isn't your problem." },
    { name: "Selfish", description: "Steal when convenient, help only when it pays." },
    { name: "Evil", description: "Skyrim is prey. Take what you want, burn the rest." },
  ],

  // Each rule has a contextual title; the description carries the mechanic.
  // Optional flags: requiresMagic / requiresNoMagic gate the rule on the
  // build's magic schools; incompatibleWeapon keeps contradicting
  // combinations from rolling together (in both directions when the rules
  // card is locked); noDaedra keeps the rule away from builds with a
  // daedric deity, affliction, or faction (entries flagged `daedric`).
  roleplayRules: [
    { name: "Wanderlust", description: "Fast travel is for cowards — walk, ride, or take the carriage everywhere." },
    { name: "Creature of Habit", description: "Find a bed before midnight, every single night." },
    { name: "Hearty Appetite", description: "Breakfast, lunch, dinner — three meals a day, no skipping." },
    { name: "Honest Hands", description: "Never steal. Not even that sweetroll." },
    { name: "Pack Rat", description: "If it has value, it goes in the bag. Yes, all of it." },
    { name: "Respect the Dead", description: "Never loot a corpse. Grave-robbing is beneath you." },
    { name: "Herbivore", description: "No meat. Cabbage soup forever." },
    { name: "Mercenary's Code", description: "Never turn down a bounty or honest mercenary work." },
    { name: "All Thumbs", description: "Buy or find your gear — no smithing, alchemy, or enchanting." },
    { name: "Artisan's Pride", description: "Only use weapons and armor you crafted yourself." },
    { name: "Never Alone", description: "Always travel with a follower. Never adventure solo." },
    { name: "Sore Feet", description: "Never use carriages. Your own two feet (or hooves) only." },
    { name: "Homesick", description: "Visit your home (or the inn you call home) every in-game week." },
    { name: "Friend of the Forest", description: "Never kill wildlife. Run from wolves if you must." },
    { name: "Devout", description: "Visit and pray at every shrine you encounter." },
    { name: "Born without magicka", description: "Your veins carry no magicka of your own — every spell must come from a staff or scroll.", requiresMagic: true },
    { name: "Sensitive Stomach", description: "Potions churn your guts — no drinking them; healing and buffs come from food alone." },
    { name: "Afraid of the Dark", description: "When night falls you freeze up — wait, sleep, or sit by a fire until dawn before doing anything." },
    { name: "Agnostic", description: "Magic is a trick you want no part of: no spells, no scrolls, no staffs, no enchanted gear.", requiresNoMagic: true, incompatibleWeapon: "Staff" },
    { name: "Heart of Iron", description: "If it's metal, it must be iron — weapons and armor of iron (or hide and leather) only." },
    { name: "Sentimental Value", description: "Never sell anything — your coin comes from quest rewards and what you find." },
    { name: "Lone Wolf", description: "No followers, no companions, no pets. You walk alone." },
    { name: "Vigilant of Stendarr", description: "Daedra are abominations — never use, carry, or craft Daedric weapons, armor, or artifacts, and destroy them where you find them.", noDaedra: true },
  ],

  // Rules in the same group contradict each other and never roll together.
  ruleConflicts: [
    ["All Thumbs", "Artisan's Pride"],
    ["Pack Rat", "Respect the Dead"],
    ["Never Alone", "Lone Wolf"],
  ],

  // `incompatibleFactions` keeps lore-breaking pairs from rolling together
  // (in both directions when either card is locked).
  affliction: [
    { name: "None", description: "A pure mortal. Sleep at night, walk in the sun, keep your soul." },
    { name: "Werewolf", description: "The blood of Hircine runs in your veins. Beast Form when the hunt calls.", incompatibleFactions: ["Volkihar Vampires"], daedric: true },
    { name: "Vampire", description: "A creature of the night. Feed regularly — or stop pretending to be one of them.", incompatibleFactions: ["Dawnguard", "The Companions"], daedric: true },
    { name: "Vampire Lord", description: "Accept Harkon's gift. Float menacingly, drain life, rule the night (Dawnguard).", incompatibleFactions: ["Dawnguard", "The Companions"], daedric: true },
  ],

  // Sentence templates for the character backstory. Placeholders are filled
  // from the rolled build: {name} {origin} {archetype} {skills} {stone}
  // {weapon} {style} {deity} {faction} {moral} and pronouns {sub}/{obj}/{pos}.
  narrative: {
    origins: {
      Nord: "under the bitter skies of Skyrim",
      Imperial: "amid the bustle of Cyrodiil's great cities",
      Breton: "in the feuding courts of High Rock",
      Redguard: "on the scorched sands of Hammerfell",
      Altmer: "in the gilded spires of the Summerset Isles",
      Bosmer: "beneath the ancient boughs of Valenwood",
      Dunmer: "in the ash-choked wastes of Morrowind",
      Orsimer: "behind the palisades of an Orc stronghold",
      Argonian: "among the misty marshes of Black Marsh",
      Khajiit: "in a trade caravan crossing the deserts of Elsweyr",
    },
    openings: [
      "{name} was born {origin}.",
      "Born {origin}, {name} learned early that destiny favors the bold.",
      "{name} first drew breath {origin}, beneath omens no priest could read.",
    ],
    paths: [
      "The long road of the {archetype} shaped {obj}, honing {skills} through lean years and worse company.",
      "Trained as a {archetype}, {sub} earned every scar while mastering {skills}.",
      "Life as a {archetype} came at a price — one paid in full while learning {skills}.",
    ],
    creeds: [
      "Under the sign of {stone}, {sub} trusts {weapon} above all, and {style} is less a tactic than a creed.",
      "Blessed by {stone}, {sub} settles most arguments with {weapon} — {style}, always.",
      "{stone} watches over {obj}; {weapon} does the talking, and {style} writes the ending.",
    ],
    afflictions: {
      "Werewolf": "And when the moons rise, Hircine's blood howls in {pos} veins.",
      "Vampire": "Since one cold night went wrong, {sub} thirsts in silence and keeps to the shadows before dawn.",
      "Vampire Lord": "Harkon's gift runs in {pos} veins now — and the night kneels to its new lord.",
    },
    dragonborn: [
      "But the truth burns deeper still: {sub} is Dragonborn, and when {sub} Shouts, the very mountains answer.",
      "And beneath it all sleeps a secret the Greybeards already whisper — {name} is Dovahkiin, born with the dragon's blood.",
    ],
    fates: [
      "Sworn to {deity} and bound for {faction}, {sub} {moral}",
      "With {deity}'s name on {pos} lips and an oath owed to {faction}, {sub} {moral}",
    ],
    fatesAlone: [
      "Sworn to no banner, trusting only {deity}, {sub} {moral}",
      "No guild holds {pos} oath; only {deity} hears {pos} prayers, and {sub} {moral}",
    ],
    morals: {
      Saint: "walks Skyrim as its quiet conscience.",
      Good: "tries to leave the world a little better — for a fair price.",
      Neutral: "owes nothing to anyone, and intends to keep it that way.",
      Selfish: "looks after number one; everyone else can hire a guard.",
      Evil: "leaves burned villages and empty pockets in {pos} wake.",
    },
  },

  // Lore-friendly name pools per race, used to roll the character's name + gender.
  names: {
    Nord: {
      male: ["Bjorn", "Ulfgar", "Ragnar", "Sigurd", "Torvald", "Halvard", "Eirik", "Stennar", "Hadvar", "Ralof", "Vilkas", "Farkas", "Skjor", "Kodlak", "Galmar", "Brunwulf", "Torygg", "Asgeir"],
      female: ["Astrid", "Sigrid", "Freydis", "Ingrid", "Helga", "Runa", "Thyra", "Gerdur", "Lydia", "Jordis", "Hulda", "Karita", "Frea", "Borghild", "Solveig", "Yrsa", "Tova", "Bryling"],
    },
    Imperial: {
      male: ["Marcus", "Quintus", "Lucius", "Decimus", "Titus", "Cassius", "Varro", "Albano", "Hadrian", "Severio", "Amaund", "Tullius", "Proventus", "Gaius", "Octavian", "Silus", "Atticus", "Vantus"],
      female: ["Aurelia", "Livia", "Octavia", "Vittoria", "Camilla", "Carmella", "Faustina", "Severa", "Carlotta", "Adrianne", "Severia", "Lucilla", "Antonia", "Claudia", "Valeria", "Marcella", "Flavia", "Iulia"],
    },
    Breton: {
      male: ["Tristan", "Alain", "Gaston", "Etienne", "Emeric", "Roland", "Maurice", "Cyrelian", "Belethor", "Delvin", "Mercer", "Adrien", "Bastien", "Corentin", "Damien", "Gaspard", "Lucien", "Thierry"],
      female: ["Colette", "Yvette", "Margaux", "Elise", "Sybille", "Aurore", "Jeanne", "Mirabelle", "Babette", "Muiri", "Bothela", "Senna", "Vivienne", "Adeline", "Camille", "Giselle", "Noelle", "Rosaline"],
    },
    Redguard: {
      male: ["Cyrus", "Kematu", "Azhar", "Rashid", "Samir", "Jawanan", "Nazir", "Tahir", "Ahtar", "Amren", "Endon", "Falion", "Isran", "Sayyid", "Khalid", "Omar", "Yusuf", "Zafir"],
      female: ["Saadia", "Zaynabi", "Tahirah", "Iman", "Rayya", "Nashita", "Umana", "Sahar", "Faleen", "Kerah", "Seren", "Yisra", "Najla", "Basira", "Halima", "Samira", "Zahra", "Marwa"],
    },
    Altmer: {
      male: ["Nelacar", "Quaranir", "Estormo", "Tandil", "Vingalmo", "Ondolemar", "Sanyon", "Rulindil", "Ancano", "Calcelmo", "Aicantar", "Runil", "Nerien", "Valmir", "Earmil", "Quarion", "Larethor", "Sinderion"],
      female: ["Niranye", "Taarie", "Endarie", "Nirya", "Alwen", "Cirwen", "Elenya", "Faralda", "Elenwen", "Arivanya", "Naryelle", "Calienne", "Synwe", "Elarie", "Mirilwen", "Anariel", "Quelinde", "Tanriel"],
    },
    Bosmer: {
      male: ["Faendal", "Anoriath", "Niruin", "Gwilin", "Malborn", "Elrindir", "Valindor", "Cuinanthil", "Enthir", "Aringoth", "Thaeryn", "Caelon", "Faelor", "Dorthil", "Elsyor", "Nathir", "Gwaelor", "Erithor"],
      female: ["Nimriel", "Nivenor", "Brelas", "Anwen", "Sylgja", "Lirielle", "Ardwen", "Galathil", "Faelwen", "Caemlin", "Nelwith", "Sorileth", "Adanya", "Mirenel", "Lethiel", "Wenaya", "Cuiniel", "Dorwen"],
    },
    Dunmer: {
      male: ["Athis", "Sadri", "Romlyn", "Erandur", "Ralen", "Fethis", "Teldryn", "Drevis", "Brand-Shei", "Revyn", "Malthyr", "Ambarys", "Belyn", "Faryl", "Adril", "Geldis", "Tythis", "Drovas"],
      female: ["Brelyna", "Dravynea", "Irileth", "Suvaris", "Aduri", "Avrusa", "Jenassa", "Voldsea", "Aranea", "Mirri", "Dreyla", "Cindiri", "Elynea", "Varona", "Selveni", "Tilisu", "Nilara", "Sadrith"],
    },
    Orsimer: {
      male: ["Ghorbash", "Yamarz", "Durak", "Ogol", "Mauhulakh", "Lurbuk", "Gat", "Urag", "Borkul", "Moth", "Larak", "Gularzob", "Dushnamub", "Oglub", "Grogmar", "Umurn", "Nagrub", "Garakh"],
      female: ["Borgakh", "Ugor", "Shel", "Gharol", "Bagrak", "Atub", "Mor", "Lash", "Urzoga", "Murbul", "Sharamph", "Yatul", "Bolar", "Arob", "Batum", "Ghak", "Shuftharz", "Urog"],
    },
    Argonian: {
      male: ["Veezara", "Derkeethus", "Jaree-Ra", "Madesi", "Neetrenaza", "Watches-The-Roots", "Scouts-Many-Marshes", "Teeba-Ei", "Talen-Jei", "Gulum-Ei", "Stands-In-Shallows", "Walks-Softly", "Seven-Scales", "Drinks-Deep-Water", "Basks-In-Sun", "Green-Tail", "Swift-Current", "Iron-Jaw"],
      female: ["Shahvee", "Keerava", "Wujeeta", "Deeja", "From-Deepest-Fathoms", "Hides-Her-Eyes", "Swims-In-Starlight", "Drips-No-Sap", "Sings-To-Rivers", "Sees-All-Colors", "Whispers-Of-Reeds", "Watches-The-Tides", "Nine-Fins", "Glides-Through-Mist", "Pale-Scales", "Marsh-Daughter", "Two-Rivers", "Bright-Throat"],
    },
    Khajiit: {
      male: ["J'zargo", "Kharjo", "Dro'marash", "Ra'jirr", "J'datharr", "Ma'dran", "Vasha", "Ri'saad", "M'aiq", "J'darr", "Ra'kheran", "Jo'khar", "Dro'zhirr", "Ma'tasarr", "S'rashi", "J'baasim", "Ra'virr", "Dar'khazu"],
      female: ["Ahkari", "Atahbah", "Khayla", "Tsavani", "Ra'zhinda", "Shuravi", "Kishra-do", "Ahjisi", "Ki'sharra", "La'shuni", "Daro'vasora", "Anjheri", "Tsabhi", "Shazara", "Mirzin", "Baira", "Inari", "Zhanara"],
    },
  },
};
