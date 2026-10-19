using Mutagen.Bethesda;
using Mutagen.Bethesda.Plugins;
using Mutagen.Bethesda.Skyrim;

// Buildnator.esp generator (v2, MCM). Records: the "Buildnator: Destiny"
// lesser power, the enforcement debuff abilities, and two Start Game Enabled
// quests - BLD_MainQuest (BLD_Build + the BLD_Enforcer player alias) and
// BLD_MCMQuest (BLD_MCM, the SkyUI config menu, with the
// SKI_PlayerLoadGameAlias player alias) - with all script properties filled.

var outPath = args.Length > 0 ? args[0] : "Buildnator.esp";
var esmPath = args.Length > 2
    ? args[2]
    : @"C:\Program Files (x86)\Steam\steamapps\common\Skyrim Special Edition\Data\Skyrim.esm";

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

// ---- Quests (created first so scripts can link to them) ----

QuestAlias PlayerAlias()
{
    var alias = new QuestAlias { ID = 0, Name = "BLD_PlayerAlias" };
    alias.ForcedReference.SetTo(playerRef);
    return alias;
}

var quest = mod.Quests.AddNew("BLD_MainQuest");
quest.Name = "Buildnator";
quest.Flags = Quest.Flag.StartGameEnabled;
quest.Priority = 60;
quest.Aliases.Add(PlayerAlias());

var mcmQuest = mod.Quests.AddNew("BLD_MCMQuest");
mcmQuest.Name = "Buildnator MCM";
mcmQuest.Flags = Quest.Flag.StartGameEnabled;
mcmQuest.Priority = 60;
mcmQuest.Aliases.Add(PlayerAlias());

// ---- Lesser power: shows the destiny sheet and story ----

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
power.Description = "Read your Buildnator destiny and its story.";
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

// ---- Main quest scripts (VMAD) ----

ScriptObjectProperty ObjProp(string name, FormKey target)
{
    var prop = new ScriptObjectProperty { Name = name, Flags = ScriptProperty.Flag.Edited };
    prop.Object.SetTo(target);
    return prop;
}

var adapter = new QuestAdapter();
var buildScript = new ScriptEntry { Name = "BLD_Build", Flags = ScriptEntry.Flag.Local };
buildScript.Properties.Add(ObjProp("PowerSpell", power.FormKey));
adapter.Scripts.Add(buildScript);

var aliasFragment = new QuestFragmentAlias();
aliasFragment.Property.Object.SetTo(quest.FormKey);
aliasFragment.Property.Alias = 0;
var enforcerScript = new ScriptEntry { Name = "BLD_Enforcer", Flags = ScriptEntry.Flag.Local };
void AddEnforcerProp(string name, FormKey target) => enforcerScript.Properties.Add(ObjProp(name, target));

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

// ---- MCM quest: BLD_MCM + SkyUI's reload hook on the player alias ----

var mcmAdapter = new QuestAdapter();
var mcmScript = new ScriptEntry { Name = "BLD_MCM", Flags = ScriptEntry.Flag.Local };
mcmScript.Properties.Add(ObjProp("Build", quest.FormKey));
mcmAdapter.Scripts.Add(mcmScript);
var mcmAlias = new QuestFragmentAlias();
mcmAlias.Property.Object.SetTo(mcmQuest.FormKey);
mcmAlias.Property.Alias = 0;
mcmAlias.Scripts.Add(new ScriptEntry { Name = "SKI_PlayerLoadGameAlias", Flags = ScriptEntry.Flag.Local });
mcmAdapter.Aliases.Add(mcmAlias);
mcmQuest.VirtualMachineAdapter = mcmAdapter;

// ---- Write + round-trip validation ----

Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(outPath))!);
mod.WriteToBinary(outPath);

var reread = SkyrimMod.CreateFromBinaryOverlay(outPath, SkyrimRelease.SkyrimSE);
var editorIds = reread.EnumerateMajorRecords().Select(r => r.EditorID).Where(e => e != null).ToHashSet();
Console.WriteLine($"Wrote {outPath}: {editorIds.Count} records.");

foreach (var ed in new[] { "BLD_MainQuest", "BLD_MCMQuest", "BLD_Power", "BLD_PowerEffect", "BLD_MeatList" })
    if (!editorIds.Contains(ed)) throw new Exception($"Round-trip check failed: missing {ed}");

var rq = reread.Quests.First(q => q.EditorID == "BLD_MainQuest");
if (rq.VirtualMachineAdapter!.Scripts.Single(s => s.Name == "BLD_Build").Properties.Count != 1)
    throw new Exception("Round-trip: BLD_Build should have 1 property");
var enforcerProps = rq.VirtualMachineAdapter!.Aliases.First().Scripts.First(s => s.Name == "BLD_Enforcer").Properties.Count;
if (enforcerProps != 25) throw new Exception($"Round-trip: expected 25 enforcer props, got {enforcerProps}");
var mq = reread.Quests.First(q => q.EditorID == "BLD_MCMQuest");
if (mq.VirtualMachineAdapter!.Scripts.Single(s => s.Name == "BLD_MCM").Properties.Count != 1)
    throw new Exception("Round-trip: BLD_MCM should have 1 property");
if (mq.VirtualMachineAdapter!.Aliases.First().Scripts.Single().Name != "SKI_PlayerLoadGameAlias")
    throw new Exception("Round-trip: MCM alias script missing");
Console.WriteLine($"Round-trip OK (2 quests, {enforcerProps} enforcer properties).");

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
