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

var menus = JsonSerializer.Deserialize<DataFile>(File.ReadAllText(dataJsonPath))!.menus;

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
aliasFragment.Scripts.Add(new ScriptEntry { Name = "BLD_Enforcer", Flags = ScriptEntry.Flag.Local });
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
Console.WriteLine($"Round-trip OK ({propCount} quest script properties).");

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
