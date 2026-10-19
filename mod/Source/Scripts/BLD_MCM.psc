ScriptName BLD_MCM extends SKI_ConfigBase
{Buildnator v2 menu (SkyUI MCM). Mirrors the site's cards: every category is
a row with its value (pick from the full option list) and a lock; the
multi-option cards (skills, schools, rules) get their own pages of toggles.
All logic lives in BLD_Build; this script only lays out and dispatches.}

BLD_Build Property Build Auto

; option kinds (OptKind[oid % 256])
Int Property K_GENERATE = 1 AutoReadOnly Hidden
Int Property K_DRAGONBORN = 2 AutoReadOnly Hidden
Int Property K_CHAR = 3 AutoReadOnly Hidden
Int Property K_SEX = 4 AutoReadOnly Hidden
Int Property K_NAME_DICE = 5 AutoReadOnly Hidden
Int Property K_MY_NAME = 6 AutoReadOnly Hidden
Int Property K_RANDOMIZE = 7 AutoReadOnly Hidden
Int Property K_SINGLE = 8 AutoReadOnly Hidden
Int Property K_LOCK = 9 AutoReadOnly Hidden
Int Property K_MULTI_ROW = 10 AutoReadOnly Hidden
Int Property K_MULTI_ITEM = 11 AutoReadOnly Hidden
Int Property K_ACCEPT = 12 AutoReadOnly Hidden
Int Property K_STORY = 13 AutoReadOnly Hidden
Int Property K_FORSAKE = 14 AutoReadOnly Hidden
Int Property K_SELFTEST = 15 AutoReadOnly Hidden
Int Property K_RESHAPE = 16 AutoReadOnly Hidden

Int[] OptKind
Int[] OptCat
Int[] OptIdx

; ---------------------------------------------------------------------------

Int Function GetVersion()
    Return 1
EndFunction

Event OnConfigInit()
    ModName = "Buildnator"
    Pages = new String[5]
    Pages[0] = "Destiny"
    Pages[1] = "Skills & Magic"
    Pages[2] = "Roleplay Rules"
    Pages[3] = "Story"
    Pages[4] = "Self-test"
    OptKind = new Int[128]
    OptCat = new Int[128]
    OptIdx = new Int[128]
EndEvent

Event OnGameReload()
    Parent.OnGameReload()
    Build.CheckData()
EndEvent

; Character creation is over by the time the MCM can open: the first time,
; the destiny adopts the race and sex the player made.
Event OnConfigOpen()
    If Build.Ready() && !Build.BodyAdopted && !Build.Applied
        Build.AdoptPlayerBody()
    EndIf
EndEvent

Function Track(Int oid, Int kind, Int cat = -1, Int idx = -1)
    Int slot = oid % 256
    OptKind[slot] = kind
    OptCat[slot] = cat
    OptIdx[slot] = idx
EndFunction

Function ClearTracking()
    Int i = 0
    While i < 128
        OptKind[i] = 0
        i += 1
    EndWhile
EndFunction

Int Function EditFlags()
    If Build.Applied
        Return OPTION_FLAG_DISABLED
    EndIf
    Return OPTION_FLAG_NONE
EndFunction

; ---------------------------------------------------------------------------
; pages
; ---------------------------------------------------------------------------

Event OnPageReset(String page)
    ClearTracking()
    If !Build.Ready()
        AddHeaderOption("The Buildnator is still waking up - reopen this menu in a moment.")
        Return
    EndIf
    If page == "" || page == "Destiny"
        PageDestiny()
    ElseIf page == "Skills & Magic"
        PageSkillsMagic()
    ElseIf page == "Roleplay Rules"
        PageRules()
    ElseIf page == "Story"
        PageStory()
    ElseIf page == "Self-test"
        PageSelfTest()
    EndIf
EndEvent

Function PageDestiny()
    Int f = EditFlags()
    SetCursorFillMode(LEFT_TO_RIGHT)
    If Build.Applied
        AddHeaderOption("Destiny accepted - day " + (Build.AppliedDay as Int))
        Track(AddTextOption("Forsake this destiny", "..."), K_FORSAKE)
    Else
        AddHeaderOption("Your destiny")
        AddHeaderOption("")
        Track(AddTextOption("Generate destiny", "ROLL", f), K_GENERATE)
        Track(AddToggleOption("Dragonborn", Build.IsDragonborn, f), K_DRAGONBORN)
    EndIf

    ; character card
    Track(AddTextOption("Character", Build.CharName, f), K_CHAR)
    Track(AddToggleOption("Lock", Build.Locked[Build.CAT_CHARACTER], f), K_LOCK, Build.CAT_CHARACTER)
    Track(AddMenuOption("   Sex", Build.GenderWord(), f), K_SEX)
    Track(AddTextOption("   Roll a name", "ROLL", f), K_NAME_DICE)
    Track(AddTextOption("   Use my name", PlayerName(), f), K_MY_NAME)
    Track(AddTextOption("   Randomize name & sex", "ROLL", f), K_RANDOMIZE)
    Track(AddTextOption("   Reshape my body", "RACE MENU", f), K_RESHAPE)
    AddEmptyOption()

    ; the cards, in the site's display order
    Int cat = 1
    While cat < Build.CAT_COUNT
        If cat == Build.CAT_SKILLS || cat == Build.CAT_SCHOOLS || cat == Build.CAT_RULES
            AddMultiRows(cat, f)
        Else
            Track(AddMenuOption(CatLabel(cat), Build.SingleName(cat, Build.CurrentSingle(cat)), f), K_SINGLE, cat)
            Track(AddToggleOption("Lock", Build.Locked[cat], f), K_LOCK, cat)
        EndIf
        cat += 1
    EndWhile

    AddEmptyOption()
    AddEmptyOption()
    If !Build.Applied
        Track(AddTextOption("Accept this destiny", "ACCEPT"), K_ACCEPT)
    Else
        AddEmptyOption()
    EndIf
    Track(AddTextOption("Read my story", "READ"), K_STORY)
EndFunction

; A multi-option card on the Destiny page: one row per item, the first
; carrying the card's label and lock. Editing happens on its own page.
Function AddMultiRows(Int cat, Int f)
    String[] items = StringUtil.Split(Build.ItemsText(cat, "|"), "|")
    Int i = 0
    While i < items.Length
        If i == 0
            Track(AddTextOption(CatLabel(cat), items[i], f), K_MULTI_ROW, cat)
            Track(AddToggleOption("Lock", Build.Locked[cat], f), K_LOCK, cat)
        Else
            Track(AddTextOption("", items[i], f), K_MULTI_ROW, cat)
            AddEmptyOption()
        EndIf
        i += 1
    EndWhile
EndFunction

Function PageSkillsMagic()
    Int f = EditFlags()
    SetCursorFillMode(TOP_TO_BOTTOM)
    AddHeaderOption("Primary Skills - exactly 3")
    Track(AddToggleOption("Lock Primary Skills", Build.Locked[Build.CAT_SKILLS], f), K_LOCK, Build.CAT_SKILLS)
    Int i = 0
    While i < Build.SkillN.Length
        Track(AddToggleOption(Build.SkillN[i], Build.HasSkillName(Build.SkillN[i]), f), K_MULTI_ITEM, Build.CAT_SKILLS, i)
        i += 1
    EndWhile

    SetCursorPosition(1)
    AddHeaderOption("Magic Schools - 0 to 2")
    Track(AddToggleOption("Lock Magic Schools", Build.Locked[Build.CAT_SCHOOLS], f), K_LOCK, Build.CAT_SCHOOLS)
    Track(AddToggleOption("None", Build.SchoolCount == 0, f), K_MULTI_ITEM, Build.CAT_SCHOOLS, -1)
    i = 0
    While i < Build.SchoolN.Length
        Track(AddToggleOption(Build.SchoolN[i], Build.HasSchoolName(Build.SchoolN[i]), f), K_MULTI_ITEM, Build.CAT_SCHOOLS, i)
        i += 1
    EndWhile
EndFunction

Function PageRules()
    Int f = EditFlags()
    SetCursorFillMode(LEFT_TO_RIGHT)
    AddHeaderOption("Roleplay Rules - 3 to 8")
    Track(AddToggleOption("Lock Roleplay Rules", Build.Locked[Build.CAT_RULES], f), K_LOCK, Build.CAT_RULES)
    Int i = 0
    While i < Build.RuleN.Length
        Track(AddToggleOption(Build.RuleN[i], Build.HasRuleIdx(i), f), K_MULTI_ITEM, Build.CAT_RULES, i)
        i += 1
    EndWhile
EndFunction

Function PageStory()
    SetCursorFillMode(TOP_TO_BOTTOM)
    AddHeaderOption(Build.CharName + ", " + Build.GenderWord() + " " + Build.RaceN[Build.RaceIdx])
    String[] lines = Wrap(Build.NarrativeText, 44)
    Int i = 0
    While i < lines.Length && i < 60
        If i == 24
            SetCursorPosition(1)
            AddHeaderOption("")
        EndIf
        AddTextOption(lines[i], "")
        i += 1
    EndWhile
EndFunction

Int SelfTestOid

; Called by BLD_Build.SelfTest while it runs.
Function ShowSelfTestProgress(Int done, Int total)
    SetTextOptionValue(SelfTestOid, done + "/" + total)
EndFunction

Function PageSelfTest()
    SetCursorFillMode(TOP_TO_BOTTOM)
    AddHeaderOption("Oracle self-test")
    Track(AddTextOption("Run 200 random rolls & choices", "RUN"), K_SELFTEST)
    AddTextOption("Last run progress", Build.SelfTestDone)
    AddTextOption("Data hash", BLD_Data.DataHash())
    AddEmptyOption()
    AddTextOption("Needs [Papyrus] bEnableLogging=1.", "")
    AddTextOption("Log: My Games\\...\\Logs\\Script\\User", "")
    AddTextOption("Check with mod\\tools\\check-oracle.js", "")
EndFunction

; ---------------------------------------------------------------------------
; events
; ---------------------------------------------------------------------------

Event OnOptionHighlight(Int oid)
    Int slot = oid % 256
    Int kind = OptKind[slot]
    Int cat = OptCat[slot]
    If kind == K_SINGLE
        SetInfoText(Desc(cat, Build.CurrentSingle(cat)))
    ElseIf kind == K_MULTI_ITEM
        SetInfoText(Desc(cat, OptIdx[slot]))
    ElseIf kind == K_MULTI_ROW
        SetInfoText("Edit this card on the " + MultiPage(cat) + " page.")
    ElseIf kind == K_LOCK
        SetInfoText("A locked card keeps its value when you Generate. A direct choice still rerolls anything it contradicts.")
    ElseIf kind == K_GENERATE
        SetInfoText("Roll a new destiny. Locked cards are kept and constrain the rest.")
    ElseIf kind == K_DRAGONBORN
        SetInfoText("Dragonborn destinies may lead with the Voice (the 'Shouts First' combat style).")
    ElseIf kind == K_CHAR
        SetInfoText("Race and sex are not changed by the mod - set them in the race menu. The name is a suggestion.")
    ElseIf kind == K_MY_NAME
        SetInfoText("Use your character's actual name in the destiny and story.")
    ElseIf kind == K_RESHAPE
        SetInfoText("Reopen the race menu to make your body match this destiny's race and sex. Afterwards the destiny follows whatever you pick there.")
    ElseIf kind == K_SINGLE && cat == Build.CAT_RACE && Build.Locked[cat]
        SetInfoText(Desc(cat, Build.CurrentSingle(cat)) + " (Locked to your character - unlock to roll a race, then 'Reshape my body'.)")
    ElseIf kind == K_ACCEPT
        SetInfoText("Apply the destiny: primary skills at 25, standing stone, gear, spells, affliction, 100 gold - and start enforcing the roleplay rules.")
    ElseIf kind == K_FORSAKE
        SetInfoText("Stop enforcing the rules and make the destiny editable again. Granted skills and gear stay.")
    ElseIf kind == K_SELFTEST
        SetInfoText("Developer check: logs 200 random rolls/choices for comparison with the website's own logic. Your destiny is restored afterwards.")
    EndIf
EndEvent

Event OnOptionSelect(Int oid)
    Int slot = oid % 256
    Int kind = OptKind[slot]
    Int cat = OptCat[slot]
    If kind == K_GENERATE
        Build.GenerateAll()
        ForcePageReset()
    ElseIf kind == K_DRAGONBORN
        If !Build.SetDragonborn(!Build.IsDragonborn)
            ShowMessage("Your locked combat style (Shouts First) needs the dragon's blood. Unlock it first.", False)
        EndIf
        ForcePageReset()
    ElseIf kind == K_LOCK
        Build.ToggleLock(cat)
        SetToggleOptionValue(oid, Build.Locked[cat])
    ElseIf kind == K_MULTI_ITEM
        String notice = Build.ToggleMulti(cat, OptIdx[slot])
        If notice != ""
            ShowMessage(notice, False)
        EndIf
        ForcePageReset()
    ElseIf kind == K_MULTI_ROW
        ShowMessage("Pick " + CatLabel(cat) + " on the " + MultiPage(cat) + " page.", False)
    ElseIf kind == K_NAME_DICE
        Build.RollNameDice()
        ForcePageReset()
    ElseIf kind == K_MY_NAME
        Build.UseName(PlayerName())
        ForcePageReset()
    ElseIf kind == K_RESHAPE
        If ShowMessage("Close all menus and the race menu will open, so you can become a " + Build.GenderWord() + " " + Build.RaceN[Build.RaceIdx] + ". Do this before accepting the destiny. Afterwards the destiny follows the race and sex you pick.", True, "Reshape", "Cancel")
            Build.RequestReshape()
        EndIf
    ElseIf kind == K_RANDOMIZE
        Build.RandomizeCharacter()
        ForcePageReset()
    ElseIf kind == K_CHAR
        ShowMessage(Build.CharName + " - " + Build.GenderWord() + " " + Build.RaceN[Build.RaceIdx] + "\n\n" + Build.RaceD[Build.RaceIdx], False)
    ElseIf kind == K_STORY
        ShowMessage(Build.NarrativeText, False)
    ElseIf kind == K_ACCEPT
        AcceptDestiny()
    ElseIf kind == K_FORSAKE
        If ShowMessage("Forsake this destiny? Your rules stop being enforced and you can roll a new one. Skills and gear already granted stay.", True, "Forsake", "Keep it")
            Build.Forsake()
            ForcePageReset()
        EndIf
    ElseIf kind == K_SELFTEST
        If ShowMessage("Run the oracle self-test now? It takes about 7 minutes. Keep this menu open and Skyrim in focus - scripts pause while you alt-tab.", True, "Run", "Cancel")
            SelfTestOid = oid
            SetTextOptionValue(oid, "0/200")
            Build.SelfTest(200, Self)
            SetTextOptionValue(oid, "DONE")
            ForcePageReset()
        EndIf
    EndIf
EndEvent

Event OnOptionMenuOpen(Int oid)
    Int slot = oid % 256
    Int kind = OptKind[slot]
    If kind == K_SEX
        String[] sexes = new String[2]
        sexes[0] = "Male"
        sexes[1] = "Female"
        SetMenuDialogOptions(sexes)
        SetMenuDialogStartIndex(Build.Female as Int)
        SetMenuDialogDefaultIndex(Build.Female as Int)
    ElseIf kind == K_SINGLE
        Int cat = OptCat[slot]
        SetMenuDialogOptions(Pool(cat))
        SetMenuDialogStartIndex(Build.CurrentSingle(cat))
        SetMenuDialogDefaultIndex(Build.CurrentSingle(cat))
    EndIf
EndEvent

Event OnOptionMenuAccept(Int oid, Int index)
    If index < 0
        Return
    EndIf
    Int slot = oid % 256
    Int kind = OptKind[slot]
    If kind == K_SEX
        Build.SetGender(index == 1)
    ElseIf kind == K_SINGLE
        Build.ChooseSingle(OptCat[slot], index)
    EndIf
    ForcePageReset()
EndEvent

; ---------------------------------------------------------------------------
; accept
; ---------------------------------------------------------------------------

Function AcceptDestiny()
    String q = Build.BuildSummary() + "\n\nAccept this destiny?"
    String mismatch = BodyMismatch()
    If mismatch != ""
        q = mismatch + "\n\n" + q
    EndIf
    If !ShowMessage(q, True, "Accept", "Not yet")
        Return
    EndIf
    String report = Build.ApplyBuild()
    ForcePageReset()
    ShowMessage(report, False)
EndFunction

; Race/sex are set in the race menu, not by script: warn when the player's
; body differs from the destiny.
String Function BodyMismatch()
    Actor p = Game.GetPlayer()
    String raceWant = Build.RaceN[Build.RaceIdx]
    String raceHave = p.GetRace().GetName()
    Bool sameRace = raceHave == raceWant || raceHave == Build.VanillaRaceName(raceWant)
    Bool sameSex = (p.GetActorBase().GetSex() == 1) == Build.Female
    If sameRace && sameSex
        Return ""
    EndIf
    Return "Note: your character is a " + raceHave + "; this destiny calls for a " + Build.GenderWord() + " " + raceWant + ". The mod does not change race or sex (scripted race changes are buggy) - you can still accept."
EndFunction

; ---------------------------------------------------------------------------
; helpers
; ---------------------------------------------------------------------------

String Function PlayerName()
    Return Game.GetPlayer().GetActorBase().GetName()
EndFunction

String Function CatLabel(Int cat)
    String[] l = new String[14]
    l[0] = "Character"
    l[1] = "Race"
    l[2] = "Archetype"
    l[3] = "Primary Skills"
    l[4] = "Standing Stone"
    l[5] = "Combat Style"
    l[6] = "Armor"
    l[7] = "Weapon of Choice"
    l[8] = "Magic Schools"
    l[9] = "Affliction"
    l[10] = "Faction"
    l[11] = "Deity"
    l[12] = "Morality"
    l[13] = "Roleplay Rules"
    Return l[cat]
EndFunction

String Function MultiPage(Int cat)
    If cat == Build.CAT_RULES
        Return "Roleplay Rules"
    EndIf
    Return "Skills & Magic"
EndFunction

String[] Function Pool(Int cat)
    If cat == Build.CAT_RACE
        Return Build.RaceN
    ElseIf cat == Build.CAT_ARCH
        Return Build.ArchN
    ElseIf cat == Build.CAT_STONE
        Return Build.StoneN
    ElseIf cat == Build.CAT_STYLE
        Return Build.StyleN
    ElseIf cat == Build.CAT_ARMOR
        Return Build.ArmorN
    ElseIf cat == Build.CAT_WEAPON
        Return Build.WeaponN
    ElseIf cat == Build.CAT_AFFL
        Return Build.AfflN
    ElseIf cat == Build.CAT_FACTION
        Return Build.FactionN
    ElseIf cat == Build.CAT_DEITY
        Return Build.DeityN
    EndIf
    Return Build.MoralN
EndFunction

String Function Desc(Int cat, Int i)
    If i < 0
        If cat == Build.CAT_SCHOOLS
            Return "Magic is for the weak."
        EndIf
        Return ""
    ElseIf cat == Build.CAT_RACE
        Return Build.RaceD[i]
    ElseIf cat == Build.CAT_ARCH
        Return Build.ArchD[i]
    ElseIf cat == Build.CAT_STONE
        Return Build.StoneD[i]
    ElseIf cat == Build.CAT_STYLE
        Return Build.StyleD[i]
    ElseIf cat == Build.CAT_ARMOR
        Return Build.ArmorD[i]
    ElseIf cat == Build.CAT_WEAPON
        Return Build.WeaponD[i]
    ElseIf cat == Build.CAT_AFFL
        Return Build.AfflD[i]
    ElseIf cat == Build.CAT_FACTION
        Return Build.FactionD[i]
    ElseIf cat == Build.CAT_DEITY
        Return Build.DeityD[i]
    ElseIf cat == Build.CAT_MORAL
        Return Build.MoralD[i]
    ElseIf cat == Build.CAT_SCHOOLS
        Return Build.SchoolD[i]
    ElseIf cat == Build.CAT_RULES
        Return Build.RuleD[i]
    EndIf
    Return ""
EndFunction

; Greedy word wrap at `width` characters.
String[] Function Wrap(String text, Int width)
    String[] words = StringUtil.Split(text, " ")
    String[] lines = new String[64]
    Int n = 0
    String cur = ""
    Int i = 0
    While i < words.Length && n < 63
        If cur == ""
            cur = words[i]
        ElseIf StringUtil.GetLength(cur) + 1 + StringUtil.GetLength(words[i]) <= width
            cur += " " + words[i]
        Else
            lines[n] = cur
            n += 1
            cur = words[i]
        EndIf
        i += 1
    EndWhile
    If cur != ""
        lines[n] = cur
        n += 1
    EndIf
    Return Utility.ResizeStringArray(lines, n)
EndFunction
