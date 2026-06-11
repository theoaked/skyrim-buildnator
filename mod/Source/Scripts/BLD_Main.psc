ScriptName BLD_Main extends Quest
{Buildnator main quest: the build wizard (roll or forge), the build sheet,
and the build application. Menu option order matches BLD_Data pool order -
both are generated from the site's js/data.js.}

; ---- menu pages, filled by the esp generator ----
Message[] Property MenuRace Auto
Message[] Property MenuStone Auto
Message[] Property MenuDeity Auto
Message[] Property MenuMorality Auto
Message[] Property MenuFaction Auto
Message[] Property MenuAffliction Auto
Message[] Property MenuWeapon Auto
Message[] Property MenuSkills Auto
Message[] Property MenuSchools Auto
Message[] Property MenuArmor Auto
Message[] Property MenuRules Auto
Message[] Property MenuStyle Auto
Message[] Property MenuArch Auto

; ---- structural messages ----
Message Property MsgIntro Auto
Message Property MsgDragonborn Auto
Message Property MsgGender Auto
Message Property MsgConfirm Auto
Message Property MsgPostApply Auto

Spell Property PowerSpell Auto

; ---- the build ----
String RaceName
Bool Female
String CharName
String StoneName
String DeityName
String MoralityName
String FactionName
String AfflictionName
String WeaponName
String WeaponSkill
String[] Skills
String[] Schools
String ArmorName
String[] Rules
String StyleName
String ArchName
Bool IsDragonborn
Bool BuildAccepted
Bool BuildApplied

Event OnInit()
    Game.GetPlayer().AddSpell(PowerSpell, False)
    Utility.Wait(4.0)
    ShowIntro()
EndEvent

; Cast of the "Buildnator: Destiny" lesser power (via BLD_PowerFX).
Function OnPowerUsed()
    If !BuildAccepted
        ShowIntro()
    ElseIf !BuildApplied
        ApplyBuild()
    Else
        ShowBlocking(BuildSummary())
        If MsgPostApply.Show() == 1
            BuildAccepted = False
            BuildApplied = False
            ShowIntro()
        EndIf
    EndIf
EndFunction

; ---------- UI helpers ----------

; Debug.MessageBox is fire-and-forget; wait until the player closes it so
; sequential boxes and Message.Show calls don't pile up.
Function ShowBlocking(String text)
    Debug.MessageBox(text)
    Utility.WaitMenuMode(0.6)
    While Utility.IsInMenuMode()
        Utility.WaitMenuMode(0.3)
    EndWhile
    Utility.Wait(0.1)
EndFunction

; Generic paginated chooser. Page layout (generated): up to 7 options,
; then "- More choices -" (only when multipage), "- Roll the dice -",
; and "- Done -" (only for multi-pick menus).
; Returns the option index, -1 for Roll, -2 for Done.
Int Function ShowMenu(Message[] pages, Int total, Bool hasDone)
    Int page = 0
    Int pageCount = (total + 6) / 7
    While True
        Int k = total - page * 7
        If k > 7
            k = 7
        EndIf
        Int choice = pages[page].Show()
        If choice < k
            Return page * 7 + choice
        EndIf
        Int nav = choice - k
        If pageCount > 1
            If nav == 0
                page += 1
                If page == pageCount
                    page = 0
                EndIf
            ElseIf nav == 1
                Return -1
            Else
                Return -2
            EndIf
        Else
            If nav == 0
                Return -1
            Else
                Return -2
            EndIf
        EndIf
    EndWhile
    Return -1
EndFunction

; ---------- wizard flow ----------

Function ShowIntro()
    Int choice = MsgIntro.Show()
    If choice == 2
        ShowBlocking("As you wish. When destiny calls, cast the lesser power 'Buildnator: Destiny' from your magic menu (Powers).")
        Return
    EndIf
    IsDragonborn = MsgDragonborn.Show() == 0
    If choice == 0
        RollAll()
    Else
        CustomizeAll()
    EndIf
    ConfirmLoop()
EndFunction

Function ConfirmLoop()
    Bool deciding = True
    While deciding
        ShowBlocking(BuildSummary())
        Int c = MsgConfirm.Show()
        If c == 0
            BuildAccepted = True
            deciding = False
            ShowBlocking("Your destiny is sealed.\n\nShape your body now: race " + RaceName + ", " + GenderWord() + ", and take the name " + CharName + " if it pleases you.\n\nWhen you stand free in Skyrim, cast the lesser power 'Buildnator: Destiny' to receive your skills, gear and oath.")
        ElseIf c == 1
            RollAll()
        ElseIf c == 2
            CustomizeAll()
        Else
            deciding = False
        EndIf
    EndWhile
EndFunction

String Function GenderWord()
    If Female
        Return "female"
    EndIf
    Return "male"
EndFunction

Bool Function HasMagic()
    Return BLD_Roller.CountFilled(Schools) > 0
EndFunction

Bool Function HasDaedra()
    Return BLD_Roller.BuildHasDaedra(DeityName, AfflictionName, FactionName)
EndFunction

; ---------- roll path ----------

Function RollAll()
    RaceName = BLD_Roller.RollRace()
    StoneName = BLD_Roller.RollStone()
    DeityName = BLD_Roller.RollDeity()
    MoralityName = BLD_Roller.RollMorality()
    FactionName = BLD_Roller.RollFaction()
    AfflictionName = BLD_Roller.RollAffliction(FactionName)
    WeaponName = BLD_Roller.RollWeapon()
    WeaponSkill = BLD_Roller.WeaponSkillOf(WeaponName)
    Skills = BLD_Roller.RollSkills(WeaponSkill)
    Schools = BLD_Roller.RollSchools(Skills)
    ArmorName = BLD_Roller.RollArmor(WeaponSkill, HasMagic())
    Rules = BLD_Roller.RollRules(HasMagic(), WeaponName, HasDaedra(), DeityName, FactionName)
    StyleName = BLD_Roller.RollStyle(WeaponName, WeaponSkill, Skills, Schools, IsDragonborn)
    ArchName = BLD_Roller.RollArchetype(WeaponName, WeaponSkill, Skills, Schools, ArmorName)
    Female = Utility.RandomInt(0, 1) == 1
    CharName = BLD_Data.PickName(RaceName, Female)
EndFunction

; ---------- forge (customize) path ----------
; Forward-only dependency order: every menu only needs what's already fixed,
; so each visible state stays coherent without any reconciliation pass.

Function CustomizeAll()
    Int g = MsgGender.Show()
    If g == 2
        Female = Utility.RandomInt(0, 1) == 1
    Else
        Female = g == 1
    EndIf

    ChooseRace()
    ChooseStone()
    ChooseDeity()
    ChooseMorality()
    ChooseFaction()
    ChooseAffliction()
    ChooseWeapon()
    ChooseSkills()
    ChooseSchools()
    ChooseArmor()
    ChooseRules()
    ChooseStyle()
    ChooseArchetype()
    CharName = BLD_Data.PickName(RaceName, Female)
EndFunction

Function ChooseRace()
    String[] pool = BLD_Data.RaceNames()
    Int i = ShowMenu(MenuRace, pool.Length, False)
    If i >= 0
        RaceName = pool[i]
    Else
        RaceName = BLD_Roller.RollRace()
    EndIf
EndFunction

Function ChooseStone()
    String[] pool = BLD_Data.StoneNames()
    Int i = ShowMenu(MenuStone, pool.Length, False)
    If i >= 0
        StoneName = pool[i]
    Else
        StoneName = BLD_Roller.RollStone()
    EndIf
EndFunction

Function ChooseDeity()
    String[] pool = BLD_Data.DeityNames()
    Int i = ShowMenu(MenuDeity, pool.Length, False)
    If i >= 0
        DeityName = pool[i]
    Else
        DeityName = BLD_Roller.RollDeity()
    EndIf
EndFunction

Function ChooseMorality()
    String[] pool = BLD_Data.MoralityNames()
    Int i = ShowMenu(MenuMorality, pool.Length, False)
    If i >= 0
        MoralityName = pool[i]
    Else
        MoralityName = BLD_Roller.RollMorality()
    EndIf
EndFunction

Function ChooseFaction()
    String[] pool = BLD_Data.FactionNames()
    Int i = ShowMenu(MenuFaction, pool.Length, False)
    If i >= 0
        FactionName = pool[i]
    Else
        FactionName = BLD_Roller.RollFaction()
    EndIf
EndFunction

Function ChooseAffliction()
    String[] pool = BLD_Data.AfflictionNames()
    String[] incompat = BLD_Data.AfflictionIncompatFactions()
    While True
        Int i = ShowMenu(MenuAffliction, pool.Length, False)
        If i < 0
            AfflictionName = BLD_Roller.RollAffliction(FactionName)
            Return
        EndIf
        If !BLD_Data.InList(FactionName, incompat[i])
            AfflictionName = pool[i]
            Return
        EndIf
        ShowBlocking(pool[i] + " cannot walk with " + FactionName + " - choose another affliction.")
    EndWhile
EndFunction

Function ChooseWeapon()
    String[] pool = BLD_Data.WeaponNames()
    Int i = ShowMenu(MenuWeapon, pool.Length, False)
    If i >= 0
        WeaponName = pool[i]
    Else
        WeaponName = BLD_Roller.RollWeapon()
    EndIf
    WeaponSkill = BLD_Roller.WeaponSkillOf(WeaponName)
EndFunction

Function ChooseSkills()
    Skills = new String[3]
    Int n = 0
    If WeaponSkill != ""
        Skills[0] = WeaponSkill
        n = 1
        ShowBlocking("Your " + WeaponName + " demands " + WeaponSkill + " - it claims the first of your three skill slots.")
    EndIf
    String[] pool = BLD_Data.SkillNames()
    While n < 3
        Int i = ShowMenu(MenuSkills, pool.Length, False)
        If i < 0
            Skills = BLD_Roller.FillSkills(Skills)
            n = 3
        ElseIf BLD_Roller.CanAddSkill(Skills, pool[i])
            Skills[n] = pool[i]
            n += 1
        Else
            ShowBlocking(pool[i] + " clashes with a skill you already picked (duplicates and rival skills never share a build).")
        EndIf
    EndWhile
EndFunction

Function ChooseSchools()
    Schools = new String[2]
    String[] pool = BLD_Data.SchoolNames()
    Bool needMagic = BLD_Roller.AnyMagicSkill(Skills)
    While True
        Int i = ShowMenu(MenuSchools, pool.Length, True)
        If i == -1
            Schools = BLD_Roller.RollSchools(Skills)
            Return
        ElseIf i == -2
            If needMagic && BLD_Roller.CountFilled(Schools) == 0
                ShowBlocking("Your primary skills are touched by magic - you need at least one school.")
            Else
                Return
            EndIf
        ElseIf BLD_Roller.Contains(Schools, pool[i])
            ; toggle off
            If Schools[0] == pool[i]
                Schools[0] = Schools[1]
            EndIf
            Schools[1] = ""
            ShowBlocking("Removed " + pool[i] + ". Schools now: " + SchoolsText())
        ElseIf BLD_Roller.CountFilled(Schools) == 2
            ShowBlocking("Two schools is the limit - remove one first (pick it again) or press Done.")
        Else
            Schools[BLD_Roller.CountFilled(Schools)] = pool[i]
            ShowBlocking("Schools now: " + SchoolsText() + "\n\nPick another, or Done.")
        EndIf
    EndWhile
EndFunction

Function ChooseArmor()
    String[] pool = BLD_Data.ArmorNames()
    While True
        Int i = ShowMenu(MenuArmor, pool.Length, False)
        If i < 0
            ArmorName = BLD_Roller.RollArmor(WeaponSkill, HasMagic())
            Return
        EndIf
        If BLD_Roller.ArmorFits(i, WeaponSkill, HasMagic())
            ArmorName = pool[i]
            Return
        EndIf
        ShowBlocking(pool[i] + " doesn't fit this build - it needs magic in your veins and a weapon you can cast around.")
    EndWhile
EndFunction

Function ChooseRules()
    Rules = new String[8]
    String[] pool = BLD_Data.RuleNames()
    While True
        Int i = ShowMenu(MenuRules, pool.Length, True)
        If i == -1
            Rules = BLD_Roller.FillRules(Rules, 4, HasMagic(), WeaponName, HasDaedra(), DeityName, FactionName)
            ShowBlocking("The dice spoke. Your oath now:\n" + RulesText() + "\n\nAdd or remove rules, or press Done.")
        ElseIf i == -2
            Int n = BLD_Roller.CountFilled(Rules)
            If n < 3
                ShowBlocking("An oath needs at least 3 rules - yours has " + n + ". Add more or roll the dice.")
            Else
                Return
            EndIf
        ElseIf BLD_Roller.Contains(Rules, pool[i])
            RemoveRule(pool[i])
            ShowBlocking("Removed " + pool[i] + ". Your oath now:\n" + RulesText())
        ElseIf BLD_Roller.CountFilled(Rules) == 8
            ShowBlocking("Your oath is full (8 rules) - remove one first by picking it again.")
        ElseIf !RuleAllowed(i)
            ShowBlocking(pool[i] + " doesn't fit this build or contradicts a rule you already swore.")
        Else
            Rules[BLD_Roller.CountFilled(Rules)] = pool[i]
            ShowBlocking("Sworn. Your oath now:\n" + RulesText() + "\n\nAdd more, or press Done (3 to 8 rules).")
        EndIf
    EndWhile
EndFunction

Bool Function RuleAllowed(Int idx)
    If !BLD_Roller.RuleFits(idx, HasMagic(), WeaponName, HasDaedra(), DeityName, FactionName)
        Return False
    EndIf
    Return BLD_Roller.CanAddRule(Rules, BLD_Data.RuleNames()[idx])
EndFunction

Function RemoveRule(String name)
    Int i = 0
    Int w = 0
    While i < Rules.Length
        If Rules[i] != name && Rules[i] != ""
            Rules[w] = Rules[i]
            w += 1
        EndIf
        i += 1
    EndWhile
    While w < Rules.Length
        Rules[w] = ""
        w += 1
    EndWhile
EndFunction

Function ChooseStyle()
    String[] pool = BLD_Data.StyleNames()
    While True
        Int i = ShowMenu(MenuStyle, pool.Length, False)
        If i < 0
            StyleName = BLD_Roller.RollStyle(WeaponName, WeaponSkill, Skills, Schools, IsDragonborn)
            Return
        EndIf
        If BLD_Roller.StyleFits(i, WeaponName, WeaponSkill, Skills, Schools, IsDragonborn)
            StyleName = pool[i]
            Return
        EndIf
        ShowBlocking(pool[i] + " doesn't match your weapon, skills or magic - choose another style or roll.")
    EndWhile
EndFunction

Function ChooseArchetype()
    String[] pool = BLD_Data.ArchNames()
    While True
        Int i = ShowMenu(MenuArch, pool.Length, False)
        If i < 0
            ArchName = BLD_Roller.RollArchetype(WeaponName, WeaponSkill, Skills, Schools, ArmorName)
            Return
        EndIf
        If BLD_Roller.ArchFits(i, WeaponName, WeaponSkill, Skills, Schools, ArmorName)
            ArchName = pool[i]
            Return
        EndIf
        ShowBlocking(pool[i] + " doesn't fit this build's weapon, skills, magic or armor - choose another or roll.")
    EndWhile
EndFunction

; ---------- build sheet ----------

String Function SchoolsText()
    If BLD_Roller.CountFilled(Schools) == 0
        Return "None - magic is for the weak"
    EndIf
    String t = Schools[0]
    If Schools[1] != ""
        t += ", " + Schools[1]
    EndIf
    Return t
EndFunction

String Function RulesText()
    String t = ""
    Int i = 0
    While i < Rules.Length
        If Rules[i] != ""
            If t != ""
                t += "\n"
            EndIf
            t += "- " + Rules[i]
        EndIf
        i += 1
    EndWhile
    Return t
EndFunction

String Function BuildSummary()
    String t = CharName + " - " + GenderWord() + " " + RaceName
    If IsDragonborn
        t += ", Dragonborn"
    EndIf
    t += "\n" + ArchName + " - " + StyleName
    t += "\n\nSkills: " + Skills[0] + ", " + Skills[1] + ", " + Skills[2]
    t += "\nStone: " + StoneName
    t += "\nWeapon: " + WeaponName + "  Armor: " + ArmorName
    t += "\nMagic: " + SchoolsText()
    t += "\nDeity: " + DeityName + "  Morality: " + MoralityName
    t += "\nFaction: " + FactionName + "  Affliction: " + AfflictionName
    t += "\n\nOath:\n" + RulesText()
    Return t
EndFunction

; ---------- application ----------

Function ApplyBuild()
    Actor p = Game.GetPlayer()
    Float level = BLD_Data.SkillLevel() as Float

    ; primary skills
    Int i = 0
    While i < 3
        p.SetActorValue(BLD_Data.SkillAv(Skills[i]), level)
        i += 1
    EndWhile

    ; standing stone blessing
    p.AddSpell(BLD_Data.StoneAbility(StoneName) as Spell, False)

    ; weapon of choice
    If WeaponName == "Staff"
        Form staff = BLD_Data.StaffForSchool(Schools[0])
        p.AddItem(staff, 1)
        p.EquipItem(staff)
    ElseIf WeaponName != "Fists"
        Form w = BLD_Data.WeaponItem(WeaponName)
        p.AddItem(w, 1)
        p.EquipItem(w)
        Form arrows = BLD_Data.WeaponAmmo(WeaponName)
        If arrows
            p.AddItem(arrows, BLD_Data.WeaponAmmoCount(WeaponName))
        EndIf
    EndIf
    If StyleName == "Sword & Shield"
        Form sh = BLD_Data.ShieldForArmor(ArmorName)
        p.AddItem(sh, 1)
        p.EquipItem(sh)
    EndIf

    ; armor
    If ArmorName == "Mage Robes"
        Form robes = BLD_Data.RobesForSchool(Schools[0])
        If robes
            p.AddItem(robes, 1)
            p.EquipItem(robes)
        EndIf
        Form boots = Game.GetFormFromFile(0x0001BE1B, "Skyrim.esm")
        p.AddItem(boots, 1)
        p.EquipItem(boots)
    Else
        i = 0
        While i < 4
            Form piece = BLD_Data.ArmorPiece(ArmorName, i)
            If piece
                p.AddItem(piece, 1)
                p.EquipItem(piece)
            EndIf
            i += 1
        EndWhile
    EndIf

    ; starter spells per school
    i = 0
    While i < 2
        If Schools[i] != ""
            p.AddSpell(BLD_Data.SchoolSpell(Schools[i], 0) as Spell, False)
            p.AddSpell(BLD_Data.SchoolSpell(Schools[i], 1) as Spell, False)
        EndIf
        i += 1
    EndWhile

    ; affliction (quest-safe, mirrors the site's setup file)
    If AfflictionName == "Vampire" || AfflictionName == "Vampire Lord"
        p.AddSpell(Game.GetFormFromFile(0x000B8780, "Skyrim.esm") as Spell, False)
    ElseIf AfflictionName == "Werewolf"
        p.AddSpell(Game.GetFormFromFile(0x00092C48, "Skyrim.esm") as Spell, False)
        GlobalVariable wolf = Game.GetFormFromFile(0x000ED06C, "Skyrim.esm") as GlobalVariable
        If wolf
            wolf.SetValue(1.0)
        EndIf
    EndIf

    ; gold for the road
    p.AddItem(Game.GetFormFromFile(0x0000000F, "Skyrim.esm"), 100)

    ; hand the rules to the enforcer
    BLD_Enforcer enf = GetAlias(0) as BLD_Enforcer
    If enf
        enf.Configure(Rules)
    EndIf

    BuildApplied = True
    ShowBlocking("It is done. Skills honed, " + StoneName + "'s blessing granted, gear donned, " + GoldWord() + " in your purse.\n\nLive as " + ArchName + " - " + StyleName + ", and honor your oath.")
    If AfflictionName == "Vampire" || AfflictionName == "Vampire Lord"
        ShowBlocking("A cold fever stirs: Sanguinare Vampiris runs in your blood. Vampirism takes hold in about three days." + VampireLordNote())
    ElseIf AfflictionName == "Werewolf"
        ShowBlocking("Hircine's gift prowls beneath your skin - Beast Form waits in your Powers menu. The Companions will still treat you as unblooded.")
    EndIf
    If FactionName != "None"
        ShowBlocking("Your road leads to the " + FactionName + ".\n\n" + BLD_Data.FactionHint(FactionName))
    EndIf
EndFunction

String Function GoldWord()
    Return "100 gold"
EndFunction

String Function VampireLordNote()
    If AfflictionName == "Vampire Lord"
        Return " For the Vampire Lord form, seek Harkon's gift (Dawnguard)."
    EndIf
    Return ""
EndFunction
