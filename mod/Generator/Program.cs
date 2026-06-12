using System.Text.Json;
using Mutagen.Bethesda;
using Mutagen.Bethesda.Plugins;
using Mutagen.Bethesda.Skyrim;

// Buildnator.esp generator. Records: the wizard's menu Message forms
// (paginated, generated from data.json), structural messages, the
// "Buildnator: Destiny" lesser power, and the Start Game Enabled quest
// wired to BLD_Main/BLD_Enforcer with all properties filled.

var outPath = args.Length > 0 ? args[0] : "Buildnator.esp";
var dataJsonPath = args.Length > 1
    ? args[1]
    : Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", "generated", "data.json");
var esmPath = args.Length > 2
    ? args[2]
    : @"C:\Program Files (x86)\Steam\steamapps\common\Skyrim Special Edition\Data\Skyrim.esm";

var menus = JsonSerializer.Deserialize<DataFile>(File.ReadAllText(dataJsonPath))!.menus;

// Vanilla forms are resolved from the real Skyrim.esm by EditorID - no
// memorized FormIDs for keywords/globals.
var esm = SkyrimMod.CreateFromBinaryOverlay(esmPath, SkyrimRelease.SkyrimSE);
FormKey KwKey(string edid) =>
    esm.Keywords.First(k => string.Equals(k.EditorID, edid, StringComparison.OrdinalIgnoreCase)).FormKey;
FormKey GlobalKey(string edid) =>
    esm.Globals.First(g => string.Equals(g.EditorID, edid, StringComparison.OrdinalIgnoreCase)).FormKey;

var skyrimEsm = ModKey.FromNameAndExtension("Skyrim.esm");
FormKey Esm(uint id) => new(skyrimEsm, id);
var playerRef = Esm(0x000014);
var voiceEquipType = Esm(0x025BEE);

var mod = new SkyrimMod(ModKey.FromNameAndExtension("Buildnator.esp"), SkyrimRelease.SkyrimSE);
mod.IsSmallMaster = true;
mod.ModHeader.Author = "Buildnator";
mod.ModHeader.Description = "Skyrim Buildnator - random character builds, rolled and enforced in-game.";

const int PageSize = 7;

Message MakeMessage(string edid, string desc, IEnumerable<string> buttons)
{
    var msg = mod.Messages.AddNew(edid);
    msg.Flags = Message.Flag.MessageBox;
    msg.Description = desc;
    foreach (var b in buttons)
        msg.MenuButtons.Add(new MessageButton { Text = b });
    return msg;
}

// ---- Wizard menus (paginated; option order MUST match BLD_Data pool order) ----

var specs = new (string Prop, string Title, string JsonKey, bool HasDone)[]
{
    ("MenuRace", "Race", "race", false),
    ("MenuStone", "Standing Stone", "standingStone", false),
    ("MenuDeity", "Deity", "deity", false),
    ("MenuMorality", "Morality", "morality", false),
    ("MenuFaction", "Faction", "faction", false),
    ("MenuAffliction", "Affliction", "affliction", false),
    ("MenuWeapon", "Weapon of Choice", "weapon", false),
    ("MenuSkills", "Primary Skills", "skills", false),
    ("MenuSchools", "Magic Schools", "magicSchools", true),
    ("MenuArmor", "Armor", "armor", false),
    ("MenuRules", "Roleplay Rules", "roleplayRules", true),
    ("MenuStyle", "Combat Style", "combatStyle", false),
    ("MenuArch", "Archetype", "archetype", false),
};

var menuPages = new Dictionary<string, List<Message>>();
foreach (var spec in specs)
{
    var options = menus[spec.JsonKey];
    var pageCount = (options.Length + PageSize - 1) / PageSize;
    var pages = new List<Message>();
    for (var p = 0; p < pageCount; p++)
    {
        var chunk = options.Skip(p * PageSize).Take(PageSize).ToList();
        var buttons = new List<string>(chunk);
        if (pageCount > 1) buttons.Add("- More choices -");
        buttons.Add("- Roll the dice -");
        if (spec.HasDone) buttons.Add("- Done -");
        var pageNote = pageCount > 1 ? $" ({p + 1}/{pageCount})" : "";
        pages.Add(MakeMessage($"BLD_{spec.Prop}{p}", $"{spec.Title}{pageNote} - make your pick.", buttons));
    }
    menuPages[spec.Prop] = pages;
}

// ---- Structural messages ----

var msgIntro = MakeMessage("BLD_MsgIntro",
    "A new soul enters Skyrim. Shall the Buildnator weave its destiny?",
    new[] { "Roll my fate", "Forge it myself", "Not now" });

var msgDragonborn = MakeMessage("BLD_MsgDragonborn",
    "Does the dragon's blood burn within you? (Dragonborn destinies may lead with the Voice.)",
    new[] { "I am Dragonborn", "I am but mortal" });

var msgGender = MakeMessage("BLD_MsgGender",
    "What body will you wear?",
    new[] { "Male", "Female", "Let fate decide" });

var msgConfirm = MakeMessage("BLD_MsgConfirm",
    "Stand by this destiny?",
    new[] { "Accept this destiny", "Roll again", "Customize it", "Not now" });

var msgPostApply = MakeMessage("BLD_MsgPostApply",
    "That was your build sheet. Your destiny is sealed and applied.",
    new[] { "Close", "Roll a new destiny" });

// ---- Quest (created before the power's effect so its script can link back) ----

var quest = mod.Quests.AddNew("BLD_MainQuest");
quest.Name = "Buildnator";
quest.Flags = Quest.Flag.StartGameEnabled;
quest.Priority = 60;

var playerAlias = new QuestAlias { ID = 0, Name = "BLD_PlayerAlias" };
playerAlias.ForcedReference.SetTo(playerRef);
quest.Aliases.Add(playerAlias);

// ---- Lesser power: reopens the wizard / applies the build ----

var mgef = mod.MagicEffects.AddNew("BLD_PowerEffect");
mgef.Name = "Buildnator: Destiny";
mgef.Flags = MagicEffect.Flag.HideInUI | MagicEffect.Flag.NoDuration
    | MagicEffect.Flag.NoMagnitude | MagicEffect.Flag.NoArea | MagicEffect.Flag.Painless;
mgef.CastType = CastType.FireAndForget;
mgef.TargetType = TargetType.Self;
mgef.Archetype = new MagicEffectArchetype { Type = MagicEffectArchetype.TypeEnum.Script };
var powerFx = new ScriptEntry { Name = "BLD_PowerFX", Flags = ScriptEntry.Flag.Local };
var questProp = new ScriptObjectProperty { Name = "MainQuest", Flags = ScriptProperty.Flag.Edited };
questProp.Object.SetTo(quest.FormKey);
powerFx.Properties.Add(questProp);
mgef.VirtualMachineAdapter = new VirtualMachineAdapter();
mgef.VirtualMachineAdapter.Scripts.Add(powerFx);

var power = mod.Spells.AddNew("BLD_Power");
power.Name = "Buildnator: Destiny";
power.Description = "Roll, review, and receive your Buildnator destiny.";
power.Type = SpellType.LesserPower;
power.CastType = CastType.FireAndForget;
power.TargetType = TargetType.Self;
power.EquipmentType.SetTo(voiceEquipType);
var powerEffect = new Effect { Data = new EffectData() };
powerEffect.BaseEffect.SetTo(mgef.FormKey);
power.Effects.Add(powerEffect);

// ---- Enforcement: debuff abilities (constant, value-modifier effects) ----

Spell MakeAbility(string edid, string name, string desc, params (ActorValue Av, float Mag)[] effects)
{
    var ability = mod.Spells.AddNew(edid);
    ability.Name = name;
    ability.Description = desc;
    ability.Type = SpellType.Ability;
    ability.CastType = CastType.ConstantEffect;
    ability.TargetType = TargetType.Self;
    var n = 0;
    foreach (var (av, mag) in effects)
    {
        var fx = mod.MagicEffects.AddNew($"{edid}Fx{n++}");
        fx.Name = name;
        fx.Description = desc;
        fx.Flags = MagicEffect.Flag.Detrimental | MagicEffect.Flag.Recover | MagicEffect.Flag.Painless
            | MagicEffect.Flag.NoDeathDispel;
        fx.CastType = CastType.ConstantEffect;
        fx.TargetType = TargetType.Self;
        fx.Archetype = new MagicEffectArchetype { Type = MagicEffectArchetype.TypeEnum.ValueModifier, ActorValue = av };
        var eff = new Effect { Data = new EffectData { Magnitude = mag } };
        eff.BaseEffect.SetTo(fx.FormKey);
        ability.Effects.Add(eff);
    }
    return ability;
}

var abNoMagicka = MakeAbility("BLD_AbNoMagicka", "Born without Magicka",
    "Your veins carry no magicka of your own.", (ActorValue.Magicka, 1000));
var abAnemic = MakeAbility("BLD_AbAnemic", "Anemic",
    "Thin blood, weak heart - your stamina is a flicker.", (ActorValue.Stamina, 90));
var abNausea = MakeAbility("BLD_AbNausea", "Nausea",
    "Your stomach rebels against what you swallowed.",
    (ActorValue.StaminaRateMult, 100), (ActorValue.MagickaRateMult, 50));
var abGuilt = MakeAbility("BLD_AbGuilt", "Guilty Conscience",
    "You broke your oath. The weight of it slows your step.",
    (ActorValue.CarryWeight, 50), (ActorValue.HealRateMult, 25));
var abExhausted = MakeAbility("BLD_AbExhausted", "Exhausted",
    "No bed before midnight - your body keeps the score.",
    (ActorValue.StaminaRateMult, 50), (ActorValue.HealRateMult, 50));
var abHungry = MakeAbility("BLD_AbHungry", "Hungry",
    "Too few meals today. Your strength wanes.", (ActorValue.StaminaRateMult, 50));
var abNightTerror = MakeAbility("BLD_AbNightTerror", "Night Terror",
    "The dark presses in. You should not be out here.",
    (ActorValue.SpeedMult, 20), (ActorValue.StaminaRateMult, 50), (ActorValue.CarryWeight, 1));
var abUnease = MakeAbility("BLD_AbUnease", "Oathbreaker's Unease",
    "Your company - or the lack of it - violates your oath.", (ActorValue.HealRateMult, 50));

// ---- Enforcement: meat list for Herbivore (from the real esm) ----

var meatWords = new[] { "Beef", "Venison", "Horse", "Pheasant", "Rabbit", "Chicken", "Horker",
    "Mammoth", "Dog", "Skeever", "Salmon", "Goat", "Mudcrab", "Slaughterfish", "Clam" };
var meatList = mod.FormLists.AddNew("BLD_MeatList");
var meatCount = 0;
foreach (var food in esm.Ingestibles)
{
    var ed = food.EditorID ?? "";
    if (!ed.StartsWith("Food", StringComparison.OrdinalIgnoreCase)) continue;
    if (!meatWords.Any(w => ed.Contains(w, StringComparison.OrdinalIgnoreCase))) continue;
    meatList.Items.Add(food.ToLink());
    meatCount++;
}
Console.WriteLine($"Meat list: {meatCount} foods.");

// ---- Quest scripts (VMAD) ----

var adapter = new QuestAdapter();
var mainScript = new ScriptEntry { Name = "BLD_Main", Flags = ScriptEntry.Flag.Local };

foreach (var spec in specs)
{
    var listProp = new ScriptObjectListProperty { Name = spec.Prop, Flags = ScriptProperty.Flag.Edited };
    foreach (var page in menuPages[spec.Prop])
    {
        var element = new ScriptObjectProperty();
        element.Object.SetTo(page.FormKey);
        listProp.Objects.Add(element);
    }
    mainScript.Properties.Add(listProp);
}

void AddObjectProp(string name, FormKey target)
{
    var prop = new ScriptObjectProperty { Name = name, Flags = ScriptProperty.Flag.Edited };
    prop.Object.SetTo(target);
    mainScript.Properties.Add(prop);
}

AddObjectProp("MsgIntro", msgIntro.FormKey);
AddObjectProp("MsgDragonborn", msgDragonborn.FormKey);
AddObjectProp("MsgGender", msgGender.FormKey);
AddObjectProp("MsgConfirm", msgConfirm.FormKey);
AddObjectProp("MsgPostApply", msgPostApply.FormKey);
AddObjectProp("PowerSpell", power.FormKey);

adapter.Scripts.Add(mainScript);

var aliasFragment = new QuestFragmentAlias();
aliasFragment.Property.Object.SetTo(quest.FormKey);
aliasFragment.Property.Alias = 0;
var enforcerScript = new ScriptEntry { Name = "BLD_Enforcer", Flags = ScriptEntry.Flag.Local };

void AddEnforcerProp(string name, FormKey target)
{
    var prop = new ScriptObjectProperty { Name = name, Flags = ScriptProperty.Flag.Edited };
    prop.Object.SetTo(target);
    enforcerScript.Properties.Add(prop);
}

AddEnforcerProp("AbNoMagicka", abNoMagicka.FormKey);
AddEnforcerProp("AbAnemic", abAnemic.FormKey);
AddEnforcerProp("AbNausea", abNausea.FormKey);
AddEnforcerProp("AbGuilt", abGuilt.FormKey);
AddEnforcerProp("AbExhausted", abExhausted.FormKey);
AddEnforcerProp("AbHungry", abHungry.FormKey);
AddEnforcerProp("AbNightTerror", abNightTerror.FormKey);
AddEnforcerProp("AbUnease", abUnease.FormKey);
AddEnforcerProp("MeatList", meatList.FormKey);
AddEnforcerProp("FollowerCount", GlobalKey("PlayerFollowerCount"));
AddEnforcerProp("GameHourGlobal", GlobalKey("GameHour"));
AddEnforcerProp("DaysPassed", GlobalKey("GameDaysPassed"));
AddEnforcerProp("KwWeapDaedric", KwKey("WeapMaterialDaedric"));
AddEnforcerProp("KwArmorDaedric", KwKey("ArmorMaterialDaedric"));
AddEnforcerProp("KwDaedricArtifact", KwKey("VendorItemDaedricArtifact"));
AddEnforcerProp("KwWeapIron", KwKey("WeapMaterialIron"));
AddEnforcerProp("KwWeapWood", KwKey("WeapMaterialWood"));
AddEnforcerProp("KwArmorIron", KwKey("ArmorMaterialIron"));
AddEnforcerProp("KwArmorIronBanded", KwKey("ArmorMaterialIronBanded"));
AddEnforcerProp("KwArmorHide", KwKey("ArmorMaterialHide"));
AddEnforcerProp("KwArmorStudded", KwKey("ArmorMaterialStudded"));
AddEnforcerProp("KwArmorLeather", KwKey("ArmorMaterialLeather"));
AddEnforcerProp("KwArmorJewelry", KwKey("ArmorJewelry"));
AddEnforcerProp("KwArmorClothing", KwKey("ArmorClothing"));
AddEnforcerProp("KwWeapStaff", KwKey("WeapTypeStaff"));

aliasFragment.Scripts.Add(enforcerScript);
adapter.Aliases.Add(aliasFragment);

quest.VirtualMachineAdapter = adapter;

// ---- Write + round-trip validation ----

Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(outPath))!);
mod.WriteToBinary(outPath);

var reread = SkyrimMod.CreateFromBinaryOverlay(outPath, SkyrimRelease.SkyrimSE);
var editorIds = reread.EnumerateMajorRecords().Select(r => r.EditorID).Where(e => e != null).ToHashSet();
Console.WriteLine($"Wrote {outPath}: {editorIds.Count} records.");

var expected = new List<string> { "BLD_MainQuest", "BLD_Power", "BLD_PowerEffect", "BLD_MsgIntro", "BLD_MsgConfirm" };
expected.AddRange(specs.Select(s => $"BLD_{s.Prop}0"));
foreach (var ed in expected)
    if (!editorIds.Contains(ed)) throw new Exception($"Round-trip check failed: missing {ed}");

var rereadQuest = reread.Quests.First();
var scriptNames = rereadQuest.VirtualMachineAdapter!.Scripts.Select(s => s.Name).ToList();
if (!scriptNames.Contains("BLD_Main")) throw new Exception("Round-trip: BLD_Main script missing on quest");
var propCount = rereadQuest.VirtualMachineAdapter!.Scripts.First(s => s.Name == "BLD_Main").Properties.Count;
if (propCount != specs.Length + 6) throw new Exception($"Round-trip: expected {specs.Length + 6} props, got {propCount}");
var enforcerProps = rereadQuest.VirtualMachineAdapter!.Aliases
    .First().Scripts.First(s => s.Name == "BLD_Enforcer").Properties.Count;
if (enforcerProps != 25) throw new Exception($"Round-trip: expected 25 enforcer props, got {enforcerProps}");
Console.WriteLine($"Round-trip OK ({propCount} quest + {enforcerProps} enforcer script properties).");

// ---- SEQ file: required for Start Game Enabled quests to fire on new game ----
var masterCount = reread.ModHeader.MasterReferences.Count;
var seqDir = Path.Combine(Path.GetDirectoryName(Path.GetFullPath(outPath))!, "Seq");
Directory.CreateDirectory(seqDir);
var seqPath = Path.Combine(seqDir, Path.GetFileNameWithoutExtension(outPath) + ".seq");
using (var seq = new BinaryWriter(File.Create(seqPath)))
{
    foreach (var q in reread.Quests)
    {
        if (!q.Flags.HasFlag(Quest.Flag.StartGameEnabled)) continue;
        seq.Write((uint)((uint)masterCount << 24 | q.FormKey.ID));
    }
}
Console.WriteLine($"Wrote {seqPath} ({masterCount} masters).");

record DataFile(Dictionary<string, string[]> menus);
