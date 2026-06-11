using Mutagen.Bethesda;
using Mutagen.Bethesda.Plugins;
using Mutagen.Bethesda.Skyrim;

// Buildnator.esp generator — phase 1 (pipeline proof): a Start Game Enabled
// quest with a scripted player alias and one intro message box.

var outPath = args.Length > 0 ? args[0] : "Buildnator.esp";

var skyrimEsm = ModKey.FromNameAndExtension("Skyrim.esm");
var playerRef = new FormKey(skyrimEsm, 0x000014);

var mod = new SkyrimMod(ModKey.FromNameAndExtension("Buildnator.esp"), SkyrimRelease.SkyrimSE);
mod.IsSmallMaster = true;
mod.ModHeader.Author = "Buildnator";
mod.ModHeader.Description = "Skyrim Buildnator — random character builds, rolled and enforced in-game.";

// ---- Intro message ----
var introMsg = mod.Messages.AddNew("BLD_IntroMsg");
introMsg.Flags = Message.Flag.MessageBox;
introMsg.Description =
    "The Divines are rolling the dice...\n\nBuildnator pipeline is alive. This is the hello-world message.";
introMsg.MenuButtons.Add(new MessageButton { Text = "Roll my fate" });
introMsg.MenuButtons.Add(new MessageButton { Text = "Choose myself" });
introMsg.MenuButtons.Add(new MessageButton { Text = "Not now" });

// ---- Main quest ----
var quest = mod.Quests.AddNew("BLD_MainQuest");
quest.Name = "Buildnator";
quest.Flags = Quest.Flag.StartGameEnabled;
quest.Priority = 60;

var playerAlias = new QuestAlias { ID = 0, Name = "BLD_PlayerAlias" };
playerAlias.ForcedReference.SetTo(playerRef);
quest.Aliases.Add(playerAlias);

// ---- Scripts (VMAD) ----
var adapter = new QuestAdapter();

var mainScript = new ScriptEntry { Name = "BLD_Main", Flags = ScriptEntry.Flag.Local };
var msgProp = new ScriptObjectProperty { Name = "IntroMsg", Flags = ScriptProperty.Flag.Edited };
msgProp.Object.SetTo(introMsg.FormKey);
mainScript.Properties.Add(msgProp);
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
var count = reread.EnumerateMajorRecords().Count();
var editorIds = reread.EnumerateMajorRecords().Select(r => r.EditorID).Where(e => e != null).OrderBy(e => e).ToList();
Console.WriteLine($"Wrote {outPath}: {count} records [{string.Join(", ", editorIds)}]");

string[] expected = ["BLD_IntroMsg", "BLD_MainQuest"];
foreach (var ed in expected)
{
    if (!editorIds.Contains(ed)) throw new Exception($"Round-trip check failed: missing {ed}");
}
Console.WriteLine("Round-trip OK.");

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
