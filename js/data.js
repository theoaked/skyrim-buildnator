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

  archetype: [
    { name: "Warrior", description: "Steel, sweat, and glory. Solve problems with sharp objects." },
    { name: "Mage", description: "Why swing a sword when reality itself obeys you?" },
    { name: "Thief", description: "If it isn't nailed down, it's yours." },
    { name: "Battlemage", description: "Heavy armor in one hand, devastation in the other." },
    { name: "Spellsword", description: "A blade backed by spellcraft — versatile and deadly." },
    { name: "Nightblade", description: "Illusion magic and a dagger from the shadows." },
    { name: "Assassin", description: "One target, one strike, no witnesses." },
    { name: "Archer", description: "If they can see you, you're doing it wrong. Loose from afar." },
    { name: "Paladin", description: "A holy warrior — restoration magic, heavy armor, no mercy for the undead." },
    { name: "Necromancer", description: "Death is not the end — it's the recruitment process." },
    { name: "Barbarian", description: "No armor crafting, no finesse. Hit things until they stop moving." },
    { name: "Monk", description: "Fists, robes, and inner peace (delivered at high velocity)." },
    { name: "Witchhunter", description: "Crossbow or bow, alchemy, and a grudge against everything magical." },
    { name: "Bard", description: "Charm, speechcraft, illusion — talk your way through Skyrim." },
    { name: "Pilgrim", description: "A wanderer visiting every shrine, surviving on wit and faith." },
    { name: "Crusader", description: "Stendarr's hammer made flesh. Smite the profane wherever it hides." },
    { name: "Knight", description: "Oath, honor, and a full set of plate. Chivalry isn't dead — you checked." },
    { name: "Ranger", description: "Bow, light armor, and the wilds for a home. Cities make you itch." },
    { name: "Hunter", description: "Track it, trap it, skin it, sell it. Hircine watches with approval." },
    { name: "Druid", description: "Alchemy, alteration, and a deep distrust of anyone who lives indoors." },
    { name: "Shaman", description: "Speak to the spirits, summon their wrath, wear their bones." },
    { name: "Warlock", description: "Forbidden tomes, dark pacts, and a tower full of regrets (other people's)." },
    { name: "Sellsword", description: "Loyalty has a price. Fortunately, so does everything else." },
    { name: "Gladiator", description: "Born for the pit. Every bandit camp is an arena, every fight a show." },
    { name: "Corsair", description: "A pirate stranded ashore. Loot coastal wrecks, drink mead, fear no man." },
    { name: "Alchemist", description: "Poison the blade, drink the experiment, sell the leftovers." },
    { name: "Healer", description: "A pacifist mender. Your allies do the killing — you keep them alive." },
    { name: "Scout", description: "First in, never seen, already gone. The map fills itself." },
    { name: "Treasure Hunter", description: "Every barrow has a hidden chest, and you have a shovel and no fear." },
    { name: "Court Wizard", description: "Enchanting, alteration, and polite contempt for the Jarl's guests." },
    { name: "Forsworn Outcast", description: "Fur, feathers, and fury. The Reach remembers what was taken." },
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
    { name: "Unarmed", description: "Fists only. Khajiit claws optional but recommended.", requires: { weaponName: "Fists" } },
    { name: "Sneak Attacks", description: "30x dagger multipliers are a lifestyle.", requires: { skill: "Sneak" } },
    { name: "Spell & Blade", description: "Weapon in one hand, spell in the other.", requires: { weaponSkill: "One-Handed", anyMagic: true } },
    { name: "Shouts First", description: "FUS RO DAH is always the answer. Lead with the Voice." },
  ],

  armor: [
    { name: "Heavy Armor", description: "Walk slow, hit hard, fear nothing." },
    { name: "Light Armor", description: "Mobility and protection in balance." },
    { name: "Mage Robes", description: "Enchanted cloth — your magicka is your armor." },
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
    { name: "Volkihar Vampires", description: "Embrace the night. Become the monster." },
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
    { name: "Nocturnal", description: "Daedric Prince of night and luck — patron of thieves." },
    { name: "Meridia", description: "Daedric Prince of life — sworn enemy of the undead." },
    { name: "Hircine", description: "Daedric Prince of the Hunt — father of werebeasts." },
    { name: "Mephala", description: "Daedric Prince of plots, lies, and webs." },
  ],

  morality: [
    { name: "Saint", description: "Never steal, never kill innocents, help everyone in need." },
    { name: "Good", description: "Do the right thing — but coin is coin." },
    { name: "Neutral", description: "Look out for yourself. The war isn't your problem." },
    { name: "Selfish", description: "Steal when convenient, help only when it pays." },
    { name: "Evil", description: "Skyrim is prey. Take what you want, burn the rest." },
  ],

  roleplayRules: [
    { name: "No fast travel", description: "Walk, ride, or take the carriage everywhere." },
    { name: "Sleep every night", description: "Find a bed before midnight, every night." },
    { name: "Eat three meals a day", description: "Breakfast, lunch, dinner — no skipping." },
    { name: "Never steal", description: "Not even that sweetroll." },
    { name: "Loot everything", description: "If it has value, it goes in the bag. Yes, all of it." },
    { name: "No looting the dead", description: "Grave-robbing is beneath you." },
    { name: "Vegetarian", description: "No meat. Cabbage soup forever." },
    { name: "Always accept a bounty", description: "Never turn down honest mercenary work." },
    { name: "No crafting", description: "Buy or find your gear — no smithing, alchemy, or enchanting." },
    { name: "Crafted gear only", description: "Only use weapons and armor you made yourself." },
    { name: "Always travel with a follower", description: "Never adventure alone." },
    { name: "Never use carriages", description: "Your own two feet (or hooves) only." },
    { name: "Return home weekly", description: "Visit your home (or an inn you call home) every in-game week." },
    { name: "No killing animals", description: "Wildlife is sacred. Run from wolves if you must." },
    { name: "Speak to every priest", description: "Visit and pray at every shrine you encounter." },
  ],

  affliction: [
    { name: "None", description: "A pure mortal. Sleep at night, walk in the sun, keep your soul." },
    { name: "Werewolf", description: "The blood of Hircine runs in your veins. Beast Form when the hunt calls." },
    { name: "Vampire", description: "A creature of the night. Feed regularly — or stop pretending to be one of them." },
    { name: "Vampire Lord", description: "Accept Harkon's gift. Float menacingly, drain life, rule the night (Dawnguard)." },
  ],

  challenge: [
    { name: "Permadeath", description: "If you die, delete the save. Start over." },
    { name: "No HUD", description: "Disable the HUD. Navigate by landmarks and instinct." },
    { name: "No followers", description: "You walk alone. No companions, no pets." },
    { name: "No potions in combat", description: "Drink before the fight or not at all." },
    { name: "Legendary difficulty", description: "Maximum difficulty from level 1. Pain." },
    { name: "No healing magic", description: "Potions, food, and patience only." },
    { name: "Sell nothing", description: "Income from quest rewards and found coin only." },
    { name: "One life per hold", description: "Die in a hold, never return to it." },
    { name: "No sprinting", description: "Dignified walking pace at all times." },
    { name: "No challenge", description: "The Divines smile upon you. Just enjoy the ride." },
  ],

  // Lore-friendly name pools per race, used to roll the character's name + gender.
  names: {
    Nord: {
      male: ["Bjorn", "Ulfgar", "Ragnar", "Sigurd", "Torvald", "Halvard", "Eirik", "Stennar"],
      female: ["Astrid", "Sigrid", "Freydis", "Ingrid", "Helga", "Runa", "Thyra", "Gerdur"],
    },
    Imperial: {
      male: ["Marcus", "Quintus", "Lucius", "Decimus", "Titus", "Cassius", "Varro", "Albano"],
      female: ["Aurelia", "Livia", "Octavia", "Vittoria", "Camilla", "Carmella", "Faustina", "Severa"],
    },
    Breton: {
      male: ["Tristan", "Alain", "Gaston", "Etienne", "Emeric", "Roland", "Maurice", "Cyrelian"],
      female: ["Colette", "Yvette", "Margaux", "Elise", "Sybille", "Aurore", "Jeanne", "Mirabelle"],
    },
    Redguard: {
      male: ["Cyrus", "Kematu", "Azhar", "Rashid", "Samir", "Jawanan", "Nazir", "Tahir"],
      female: ["Saadia", "Zaynabi", "Tahirah", "Iman", "Rayya", "Nashita", "Umana", "Sahar"],
    },
    Altmer: {
      male: ["Nelacar", "Quaranir", "Estormo", "Tandil", "Vingalmo", "Ondolemar", "Sanyon", "Rulindil"],
      female: ["Niranye", "Taarie", "Endarie", "Nirya", "Alwen", "Cirwen", "Elenya", "Faralda"],
    },
    Bosmer: {
      male: ["Faendal", "Anoriath", "Niruin", "Gwilin", "Malborn", "Elrindir", "Valindor", "Cuinanthil"],
      female: ["Nimriel", "Nivenor", "Brelas", "Anwen", "Sylgja", "Lirielle", "Ardwen", "Galathil"],
    },
    Dunmer: {
      male: ["Athis", "Sadri", "Romlyn", "Erandur", "Ralen", "Fethis", "Teldryn", "Drevis"],
      female: ["Brelyna", "Dravynea", "Irileth", "Suvaris", "Aduri", "Avrusa", "Jenassa", "Voldsea"],
    },
    Orsimer: {
      male: ["Ghorbash", "Yamarz", "Durak", "Ogol", "Mauhulakh", "Lurbuk", "Gat", "Urag"],
      female: ["Borgakh", "Ugor", "Shel", "Gharol", "Bagrak", "Atub", "Mor", "Lash"],
    },
    Argonian: {
      male: ["Veezara", "Derkeethus", "Jaree-Ra", "Madesi", "Neetrenaza", "Watches-The-Roots", "Scouts-Many-Marshes", "Teeba-Ei"],
      female: ["Shahvee", "Keerava", "Wujeeta", "Deeja", "From-Deepest-Fathoms", "Hides-Her-Eyes", "Swims-In-Starlight", "Drips-No-Sap"],
    },
    Khajiit: {
      male: ["J'zargo", "Kharjo", "Dro'marash", "Ra'jirr", "J'datharr", "Ma'dran", "Vasha", "Ri'saad"],
      female: ["Ahkari", "Atahbah", "Khayla", "Tsavani", "Ra'zhinda", "Shuravi", "Kishra-do", "Ahjisi"],
    },
  },
};
