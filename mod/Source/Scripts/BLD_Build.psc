ScriptName BLD_Build extends Quest
{Buildnator v2 build state and roll logic - a function-by-function port of
the site's js/app.js (locks, direct choices, reconcile, Dragonborn, character,
narrative). Pools come from BLD_Data, generated from js/data.js. Function names
mirror app.js so the two can be diffed by eye; tools/check-oracle.js checks the
port against the real app.js using builds this script logs in game.}

Spell Property PowerSpell Auto

; ---- category ids: same order as app.js CATEGORIES ----
Int Property CAT_CHARACTER = 0 AutoReadOnly Hidden
Int Property CAT_RACE = 1 AutoReadOnly Hidden
Int Property CAT_ARCH = 2 AutoReadOnly Hidden
Int Property CAT_SKILLS = 3 AutoReadOnly Hidden
Int Property CAT_STONE = 4 AutoReadOnly Hidden
Int Property CAT_STYLE = 5 AutoReadOnly Hidden
Int Property CAT_ARMOR = 6 AutoReadOnly Hidden
Int Property CAT_WEAPON = 7 AutoReadOnly Hidden
Int Property CAT_SCHOOLS = 8 AutoReadOnly Hidden
Int Property CAT_AFFL = 9 AutoReadOnly Hidden
Int Property CAT_FACTION = 10 AutoReadOnly Hidden
Int Property CAT_DEITY = 11 AutoReadOnly Hidden
Int Property CAT_MORAL = 12 AutoReadOnly Hidden
Int Property CAT_RULES = 13 AutoReadOnly Hidden
Int Property CAT_COUNT = 14 AutoReadOnly Hidden

Int Property MAX_SKILLS = 3 AutoReadOnly Hidden
Int Property MAX_SCHOOLS = 2 AutoReadOnly Hidden
Int Property MAX_RULES = 8 AutoReadOnly Hidden
Int Property MIN_RULES = 3 AutoReadOnly Hidden

; ---- pools (cached from BLD_Data; reloaded when the data hash changes) ----
String LoadedHash
String[] Property RaceN Auto Hidden
String[] Property RaceD Auto Hidden
String[] Property ArchN Auto Hidden
String[] Property ArchD Auto Hidden
String[] ArchReqWeaponName
String[] ArchReqWeaponSkill
String[] ArchReqWeaponSkillIn
String[] ArchReqSkill
String[] ArchReqSkillIn
String[] ArchReqExcludeSkills
String[] ArchReqMagicSchool
String[] ArchReqMagicSchoolIn
Bool[] ArchReqAnyMagic
String[] ArchReqArmorIn
Bool[] ArchReqDragonborn
String[] Property SkillN Auto Hidden
String[] Property StoneN Auto Hidden
String[] Property StoneD Auto Hidden
String[] Property StyleN Auto Hidden
String[] Property StyleD Auto Hidden
String[] StyleReqWeaponName
String[] StyleReqWeaponSkill
String[] StyleReqWeaponSkillIn
String[] StyleReqSkill
String[] StyleReqSkillIn
String[] StyleReqExcludeSkills
String[] StyleReqMagicSchool
String[] StyleReqMagicSchoolIn
Bool[] StyleReqAnyMagic
String[] StyleReqArmorIn
Bool[] StyleReqDragonborn
String[] Property ArmorN Auto Hidden
String[] Property ArmorD Auto Hidden
Bool[] ArmorAnyMagic
String[] ArmorWeaponSkillNot
String[] Property WeaponN Auto Hidden
String[] Property WeaponD Auto Hidden
String[] WeaponSk
String[] Property SchoolN Auto Hidden
String[] Property SchoolD Auto Hidden
String[] Property AfflN Auto Hidden
String[] Property AfflD Auto Hidden
Bool[] AfflDaedric
String[] AfflIncompatF
String[] Property FactionN Auto Hidden
String[] Property FactionD Auto Hidden
Bool[] FactionDaedric
String[] Property DeityN Auto Hidden
String[] Property DeityD Auto Hidden
Bool[] DeityDaedric
String[] Property MoralN Auto Hidden
String[] Property MoralD Auto Hidden
String[] Property RuleN Auto Hidden
String[] Property RuleD Auto Hidden
Bool[] RuleReqMagic
Bool[] RuleReqNoMagic
Bool[] RuleNoDaedra
String[] RuleIncompatW
String[] RuleIncompatD
String[] RuleIncompatF
String[] SkillConflictGroups
String[] RuleConflictGroups
String MagicSkillList  ; app.js MAGIC_SKILLS, pipe-joined

; ---- the build (app.js `state`; pool indices, -1 = none) ----
Int Property RaceIdx Auto Hidden
Int Property Arch Auto Hidden
Int Property Stone Auto Hidden
Int Property Style Auto Hidden
Int Property ArmorIdx Auto Hidden
Int Property WeaponIdx Auto Hidden
Int Property Affl Auto Hidden
Int Property FactionIdx Auto Hidden
Int Property Deity Auto Hidden
Int Property Moral Auto Hidden
Int[] Property Skills Auto Hidden
Int Property SkillCount Auto Hidden
Int[] Property Schools Auto Hidden
Int Property SchoolCount Auto Hidden
Int[] Property Rules Auto Hidden
Int Property RuleCount Auto Hidden
String Property CharName Auto Hidden
Bool Property Female Auto Hidden
Int CharRace                         ; the race the character card was rolled for
String Property CustomName Auto Hidden   ; app.js customName ("" = null)
Int Property CustomGender = -1 Auto Hidden ; app.js customGender (-1 null, 0 Male, 1 Female)
Bool Property IsDragonborn Auto Hidden
Bool[] Property Locked Auto Hidden
String Property NarrativeText Auto Hidden
Bool Property Applied Auto Hidden
Float Property AppliedDay Auto Hidden

; ---- lockedRuleFlags() results (refreshed by LockedRuleFlags()) ----
Bool LRReqMagic
Bool LRReqNoMagic
Bool LRNoDaedra
String LRIncW
String LRIncD
String LRIncF

; =========================================================================
; lifecycle
; =========================================================================

Event OnInit()
    Locked = new Bool[14]
    Skills = new Int[3]
    Schools = new Int[5]
    Rules = new Int[8]
    CustomGender = -1
    LoadPools()
    GenerateAll()
    Game.GetPlayer().AddSpell(PowerSpell, False)
    RegisterForSingleUpdate(8.0)
EndEvent

Event OnUpdate()
    If PendingReshape
        PendingReshape = False
        RegisterForMenu("RaceSex Menu")
        Game.ShowRaceMenu()
        Return
    EndIf
    Debug.Notification("Your destiny awaits - Mod Configuration > Buildnator.")
EndEvent

; ---- the player's body vs the destiny ----
; Character creation happens before the MCM can be opened, so the first time
; the menu opens the destiny adopts the body the player made (race locked).
; "Reshape my body" goes the other way: it reopens the race menu, and the
; destiny follows whatever the player settles on there.

Bool Property BodyAdopted Auto Hidden
Bool PendingReshape

String Function VanillaRaceName(String r)
    If r == "Altmer"
        Return "High Elf"
    ElseIf r == "Bosmer"
        Return "Wood Elf"
    ElseIf r == "Dunmer"
        Return "Dark Elf"
    ElseIf r == "Orsimer"
        Return "Orc"
    EndIf
    Return r
EndFunction

Int Function PlayerRaceIdx()
    String have = Game.GetPlayer().GetRace().GetName()
    Int i = 0
    While i < RaceN.Length
        If have == RaceN[i] || have == VanillaRaceName(RaceN[i])
            Return i
        EndIf
        i += 1
    EndWhile
    Return -1
EndFunction

Function AdoptPlayerBody()
    Int r = PlayerRaceIdx()
    If r >= 0
        If r != RaceIdx
            ChooseSingle(CAT_RACE, r)
        EndIf
        Locked[CAT_RACE] = True
    EndIf
    SetGender(Game.GetPlayer().GetActorBase().GetSex() == 1)
    BodyAdopted = True
EndFunction

; Opens the race menu as soon as the player leaves the menus (OnUpdate only
; runs outside menu mode).
Function RequestReshape()
    PendingReshape = True
    RegisterForSingleUpdate(0.5)
EndFunction

Event OnMenuClose(String menuName)
    If menuName == "RaceSex Menu"
        UnregisterForMenu("RaceSex Menu")
        AdoptPlayerBody()
        Debug.Notification("Your destiny now follows your new body.")
    EndIf
EndEvent

; Called by the MCM on every game load: a rebuilt data layer invalidates
; cached indices, so the destiny is re-rolled (locks cleared).
Function CheckData()
    If !Ready()
        Return ; OnInit hasn't run yet; it loads the pools itself
    EndIf
    If LoadedHash != BLD_Data.DataHash()
        LoadPools()
        Int c = 0
        While c < CAT_COUNT
            Locked[c] = False
            c += 1
        EndWhile
        If !Applied
            GenerateAll()
        EndIf
    EndIf
EndFunction

; True once OnInit has loaded the pools and rolled the first destiny.
Bool Function Ready()
    Return Locked && NarrativeText != ""
EndFunction

Function LoadPools()
    RaceN = BLD_Data.RaceNames()
    RaceD = BLD_Data.RaceDescs()
    ArchN = BLD_Data.ArchNames()
    ArchD = BLD_Data.ArchDescs()
    ArchReqWeaponName = BLD_Data.ArchReqWeaponName()
    ArchReqWeaponSkill = BLD_Data.ArchReqWeaponSkill()
    ArchReqWeaponSkillIn = BLD_Data.ArchReqWeaponSkillIn()
    ArchReqSkill = BLD_Data.ArchReqSkill()
    ArchReqSkillIn = BLD_Data.ArchReqSkillIn()
    ArchReqExcludeSkills = BLD_Data.ArchReqExcludeSkills()
    ArchReqMagicSchool = BLD_Data.ArchReqMagicSchool()
    ArchReqMagicSchoolIn = BLD_Data.ArchReqMagicSchoolIn()
    ArchReqAnyMagic = BLD_Data.ArchReqAnyMagic()
    ArchReqArmorIn = BLD_Data.ArchReqArmorIn()
    ArchReqDragonborn = BLD_Data.ArchReqDragonborn()
    SkillN = BLD_Data.SkillNames()
    StoneN = BLD_Data.StoneNames()
    StoneD = BLD_Data.StoneDescs()
    StyleN = BLD_Data.StyleNames()
    StyleD = BLD_Data.StyleDescs()
    StyleReqWeaponName = BLD_Data.StyleReqWeaponName()
    StyleReqWeaponSkill = BLD_Data.StyleReqWeaponSkill()
    StyleReqWeaponSkillIn = BLD_Data.StyleReqWeaponSkillIn()
    StyleReqSkill = BLD_Data.StyleReqSkill()
    StyleReqSkillIn = BLD_Data.StyleReqSkillIn()
    StyleReqExcludeSkills = BLD_Data.StyleReqExcludeSkills()
    StyleReqMagicSchool = BLD_Data.StyleReqMagicSchool()
    StyleReqMagicSchoolIn = BLD_Data.StyleReqMagicSchoolIn()
    StyleReqAnyMagic = BLD_Data.StyleReqAnyMagic()
    StyleReqArmorIn = BLD_Data.StyleReqArmorIn()
    StyleReqDragonborn = BLD_Data.StyleReqDragonborn()
    ArmorN = BLD_Data.ArmorNames()
    ArmorD = BLD_Data.ArmorDescs()
    ArmorAnyMagic = BLD_Data.ArmorAnyMagic()
    ArmorWeaponSkillNot = BLD_Data.ArmorWeaponSkillNot()
    WeaponN = BLD_Data.WeaponNames()
    WeaponD = BLD_Data.WeaponDescs()
    WeaponSk = BLD_Data.WeaponSkills()
    SchoolN = BLD_Data.SchoolNames()
    SchoolD = BLD_Data.SchoolDescs()
    AfflN = BLD_Data.AfflictionNames()
    AfflD = BLD_Data.AfflictionDescs()
    AfflDaedric = BLD_Data.AfflictionDaedric()
    AfflIncompatF = BLD_Data.AfflictionIncompatFactions()
    FactionN = BLD_Data.FactionNames()
    FactionD = BLD_Data.FactionDescs()
    FactionDaedric = BLD_Data.FactionDaedric()
    DeityN = BLD_Data.DeityNames()
    DeityD = BLD_Data.DeityDescs()
    DeityDaedric = BLD_Data.DeityDaedric()
    MoralN = BLD_Data.MoralityNames()
    MoralD = BLD_Data.MoralityDescs()
    RuleN = BLD_Data.RuleNames()
    RuleD = BLD_Data.RuleDescs()
    RuleReqMagic = BLD_Data.RuleRequiresMagic()
    RuleReqNoMagic = BLD_Data.RuleRequiresNoMagic()
    RuleNoDaedra = BLD_Data.RuleNoDaedra()
    RuleIncompatW = BLD_Data.RuleIncompatWeapon()
    RuleIncompatD = BLD_Data.RuleIncompatDeities()
    RuleIncompatF = BLD_Data.RuleIncompatFactions()
    SkillConflictGroups = BLD_Data.SkillConflictGroups()
    RuleConflictGroups = BLD_Data.RuleConflictGroups()
    String[] magic = BLD_Data.MagicSkills()
    MagicSkillList = ""
    Int i = 0
    While i < magic.Length
        If i > 0
            MagicSkillList += "|"
        EndIf
        MagicSkillList += magic[i]
        i += 1
    EndWhile
    LoadedHash = BLD_Data.DataHash()
EndFunction

; =========================================================================
; helpers (app.js sample / pick / isLocked / current*)
; =========================================================================

Bool Function Contains(String[] arr, String s) Global
    Int i = 0
    While i < arr.Length
        If arr[i] == s
            Return True
        EndIf
        i += 1
    EndWhile
    Return False
EndFunction

Bool Function InList(String asName, String asList)
    Return BLD_Data.InList(asName, asList)
EndFunction

Int Function IndexOf(String[] arr, String s)
    Int i = 0
    While i < arr.Length
        If arr[i] == s
            Return i
        EndIf
        i += 1
    EndWhile
    Return -1
EndFunction

; A random permutation of 0..n-1 (app.js sample(pool, pool.length)).
Int[] Function Shuffled(Int n)
    Int[] a = new Int[32]
    Int i = 0
    While i < n
        a[i] = i
        i += 1
    EndWhile
    i = n - 1
    While i > 0
        Int j = Utility.RandomInt(0, i)
        Int t = a[i]
        a[i] = a[j]
        a[j] = t
        i -= 1
    EndWhile
    Return a
EndFunction

; Uniform pick from the first `count` entries of buf; -1 when empty.
Int Function PickFrom(Int[] buf, Int count)
    If count <= 0
        Return -1
    EndIf
    Return buf[Utility.RandomInt(0, count - 1)]
EndFunction

Bool Function IsLocked(Int cat)
    Return Locked[cat]
EndFunction

Bool Function HasSkillName(String n)
    Int i = 0
    While i < SkillCount
        If SkillN[Skills[i]] == n
            Return True
        EndIf
        i += 1
    EndWhile
    Return False
EndFunction

Bool Function SkillsAnyIn(String list)
    Int i = 0
    While i < SkillCount
        If InList(SkillN[Skills[i]], list)
            Return True
        EndIf
        i += 1
    EndWhile
    Return False
EndFunction

Bool Function HasSchoolName(String n)
    Int i = 0
    While i < SchoolCount
        If SchoolN[Schools[i]] == n
            Return True
        EndIf
        i += 1
    EndWhile
    Return False
EndFunction

Bool Function SchoolsAnyIn(String list)
    Int i = 0
    While i < SchoolCount
        If InList(SchoolN[Schools[i]], list)
            Return True
        EndIf
        i += 1
    EndWhile
    Return False
EndFunction

Bool Function HasRuleIdx(Int r)
    Int i = 0
    While i < RuleCount
        If Rules[i] == r
            Return True
        EndIf
        i += 1
    EndWhile
    Return False
EndFunction

; The current weapon's governing skill ("" for Staff / Fists).
String Function CurWeaponSkill()
    If WeaponIdx < 0
        Return ""
    EndIf
    Return WeaponSk[WeaponIdx]
EndFunction

Bool Function SkillsNeedMagic()
    Return SkillsAnyIn(MagicSkillList)
EndFunction

; Locked-card requirement sources (-1 when that card is not locked).
Int Function LS()
    If Locked[CAT_STYLE]
        Return Style
    EndIf
    Return -1
EndFunction

Int Function LA()
    If Locked[CAT_ARCH]
        Return Arch
    EndIf
    Return -1
EndFunction

Int Function LArm()
    If Locked[CAT_ARMOR]
        Return ArmorIdx
    EndIf
    Return -1
EndFunction

; app.js lockedRuleFlags()
Function LockedRuleFlags()
    LRReqMagic = False
    LRReqNoMagic = False
    LRNoDaedra = False
    LRIncW = ""
    LRIncD = ""
    LRIncF = ""
    If !Locked[CAT_RULES]
        Return
    EndIf
    Int i = 0
    While i < RuleCount
        Int r = Rules[i]
        LRReqMagic = LRReqMagic || RuleReqMagic[r]
        LRReqNoMagic = LRReqNoMagic || RuleReqNoMagic[r]
        LRNoDaedra = LRNoDaedra || RuleNoDaedra[r]
        LRIncW = JoinPipe(LRIncW, RuleIncompatW[r])
        LRIncD = JoinPipe(LRIncD, RuleIncompatD[r])
        LRIncF = JoinPipe(LRIncF, RuleIncompatF[r])
        i += 1
    EndWhile
EndFunction

String Function JoinPipe(String a, String b)
    If b == ""
        Return a
    ElseIf a == ""
        Return b
    EndIf
    Return a + "|" + b
EndFunction

Bool Function DeityAllowedByLockedRules(Int d)
    LockedRuleFlags()
    If LRNoDaedra && DeityDaedric[d]
        Return False
    EndIf
    Return !InList(DeityN[d], LRIncD)
EndFunction

Bool Function FactionAllowedByLockedRules(Int f)
    LockedRuleFlags()
    If LRNoDaedra && FactionDaedric[f]
        Return False
    EndIf
    Return !InList(FactionN[f], LRIncF)
EndFunction

Bool Function SkillsConflict(String a, String b)
    Int g = 0
    While g < SkillConflictGroups.Length
        If InList(a, SkillConflictGroups[g]) && InList(b, SkillConflictGroups[g])
            Return True
        EndIf
        g += 1
    EndWhile
    Return False
EndFunction

Bool Function RulesConflict(String a, String b)
    Int g = 0
    While g < RuleConflictGroups.Length
        If InList(a, RuleConflictGroups[g]) && InList(b, RuleConflictGroups[g])
            Return True
        EndIf
        g += 1
    EndWhile
    Return False
EndFunction

; True when skill index s duplicates or conflicts with any of buf[0..count).
Bool Function SkillClashes(Int[] buf, Int count, Int s)
    Int i = 0
    While i < count
        If buf[i] == s || SkillsConflict(SkillN[buf[i]], SkillN[s])
            Return True
        EndIf
        i += 1
    EndWhile
    Return False
EndFunction

Bool Function RuleClashes(Int[] buf, Int count, Int r)
    Int i = 0
    While i < count
        If buf[i] == r || RulesConflict(RuleN[buf[i]], RuleN[r])
            Return True
        EndIf
        i += 1
    EndWhile
    Return False
EndFunction

Bool Function AnyRuleFlag(Int[] buf, Int count, Bool wantNoMagic)
    Int i = 0
    While i < count
        If (wantNoMagic && RuleReqNoMagic[buf[i]]) || (!wantNoMagic && RuleReqMagic[buf[i]])
            Return True
        EndIf
        i += 1
    EndWhile
    Return False
EndFunction

Function SetSkills(Int[] buf, Int count)
    Int i = 0
    While i < MAX_SKILLS
        If i < count
            Skills[i] = buf[i]
        Else
            Skills[i] = -1
        EndIf
        i += 1
    EndWhile
    SkillCount = count
EndFunction

Function SetSchools(Int[] buf, Int count)
    Int i = 0
    While i < count
        Schools[i] = buf[i]
        i += 1
    EndWhile
    SchoolCount = count
EndFunction

Function SetRules(Int[] buf, Int count)
    Int i = 0
    While i < MAX_RULES
        If i < count
            Rules[i] = buf[i]
        Else
            Rules[i] = -1
        EndIf
        i += 1
    EndWhile
    RuleCount = count
EndFunction

; =========================================================================
; rolls (app.js roll*)
; =========================================================================

Function RollWeapon()
    Int[] buf = new Int[32]
    Int c = 0
    Int ls = LS()
    Int la = LA()
    Int lar = LArm()
    LockedRuleFlags()
    Int w = 0
    While w < WeaponN.Length
        Bool ok = True
        String sk = WeaponSk[w]
        If Locked[CAT_SKILLS] && sk != "" && !HasSkillName(sk)
            ok = False
        EndIf
        If ls >= 0
            If StyleReqWeaponName[ls] != "" && WeaponN[w] != StyleReqWeaponName[ls]
                ok = False
            EndIf
            If StyleReqWeaponSkill[ls] != "" && sk != StyleReqWeaponSkill[ls]
                ok = False
            EndIf
        EndIf
        If la >= 0
            If ArchReqWeaponName[la] != "" && WeaponN[w] != ArchReqWeaponName[la]
                ok = False
            EndIf
            If ArchReqWeaponSkillIn[la] != "" && !InList(sk, ArchReqWeaponSkillIn[la])
                ok = False
            EndIf
        EndIf
        If lar >= 0 && ArmorWeaponSkillNot[lar] != "" && InList(sk, ArmorWeaponSkillNot[lar])
            ok = False
        EndIf
        If LRIncW != "" && InList(WeaponN[w], LRIncW)
            ok = False
        EndIf
        If ok
            buf[c] = w
            c += 1
        EndIf
        w += 1
    EndWhile
    Int pickW = PickFrom(buf, c)
    If pickW < 0
        ; app.js would leave the card empty and crash; contradictory locks
        ; fall back to an unconstrained weapon instead.
        pickW = Utility.RandomInt(0, WeaponN.Length - 1)
    EndIf
    WeaponIdx = pickW
EndFunction

Function RollSkills()
    LockedRuleFlags()
    Bool noMagicSkills = LRReqNoMagic || (Locked[CAT_SCHOOLS] && SchoolCount == 0)
    Int[] req = new Int[8]
    Int rc = 0
    String weaponSkill = CurWeaponSkill()
    If weaponSkill != ""
        req[rc] = IndexOf(SkillN, weaponSkill)
        rc += 1
    EndIf
    Int ls = LS()
    String styleSkill = ""
    String excluded = ""
    If ls >= 0
        styleSkill = StyleReqSkill[ls]
        excluded = StyleReqExcludeSkills[ls]
    EndIf
    If styleSkill != "" && styleSkill != weaponSkill
        req[rc] = IndexOf(SkillN, styleSkill)
        rc += 1
    EndIf
    Int la = LA()
    If la >= 0 && ArchReqSkillIn[la] != ""
        String archSkillIn = ArchReqSkillIn[la]
        Bool covered = False
        Int i = 0
        While i < rc
            If InList(SkillN[req[i]], archSkillIn)
                covered = True
            EndIf
            i += 1
        EndWhile
        If !covered
            String[] names = StringUtil.Split(archSkillIn, "|")
            Int[] opts = new Int[32]
            Int oc = 0
            i = 0
            While i < names.Length
                Int s = IndexOf(SkillN, names[i])
                If !SkillClashes(req, rc, s) && !(noMagicSkills && InList(names[i], MagicSkillList))
                    opts[oc] = s
                    oc += 1
                EndIf
                i += 1
            EndWhile
            If oc > 0
                req[rc] = PickFrom(opts, oc)
                rc += 1
            EndIf
        EndIf
    EndIf
    ; required skills come first, then fill from a shuffled pool
    Int[] picked = new Int[8]
    Int pc = 0
    While pc < rc
        picked[pc] = req[pc]
        pc += 1
    EndWhile
    Int[] order = Shuffled(SkillN.Length)
    Int k = 0
    While k < SkillN.Length && pc < 3
        Int cand = order[k]
        String cn = SkillN[cand]
        If !InList(cn, excluded) && !(noMagicSkills && InList(cn, MagicSkillList)) && !SkillClashes(picked, pc, cand)
            picked[pc] = cand
            pc += 1
        EndIf
        k += 1
    EndWhile
    If pc > MAX_SKILLS
        pc = MAX_SKILLS
    EndIf
    SetSkills(picked, pc)
EndFunction

Function RollMagicSchools()
    LockedRuleFlags()
    If LRReqNoMagic
        SchoolCount = 0
        Return
    EndIf
    Int ls = LS()
    Int la = LA()
    Int lar = LArm()
    Int[] must = new Int[5]
    Int mc = 0
    If ls >= 0 && StyleReqMagicSchool[ls] != ""
        must[mc] = IndexOf(SchoolN, StyleReqMagicSchool[ls])
        mc += 1
    EndIf
    If la >= 0 && ArchReqMagicSchool[la] != ""
        Int s = IndexOf(SchoolN, ArchReqMagicSchool[la])
        If !IntIn(must, mc, s)
            must[mc] = s
            mc += 1
        EndIf
    EndIf
    If la >= 0 && ArchReqMagicSchoolIn[la] != ""
        Bool covered = False
        Int i = 0
        While i < mc
            If InList(SchoolN[must[i]], ArchReqMagicSchoolIn[la])
                covered = True
            EndIf
            i += 1
        EndWhile
        If !covered
            String[] opts = StringUtil.Split(ArchReqMagicSchoolIn[la], "|")
            must[mc] = IndexOf(SchoolN, opts[Utility.RandomInt(0, opts.Length - 1)])
            mc += 1
        EndIf
    EndIf
    Int n = Utility.RandomInt(0, 2)
    Bool needAny = LRReqMagic || SkillsNeedMagic()
    If ls >= 0 && StyleReqAnyMagic[ls]
        needAny = True
    EndIf
    If la >= 0 && ArchReqAnyMagic[la]
        needAny = True
    EndIf
    If lar >= 0 && ArmorAnyMagic[lar]
        needAny = True
    EndIf
    If (needAny || mc > 0) && n == 0
        n = 1
    EndIf
    If n < mc
        n = mc
    EndIf
    Int[] result = new Int[5]
    Int c = 0
    While c < mc
        result[c] = must[c]
        c += 1
    EndWhile
    Int[] order = Shuffled(SchoolN.Length)
    Int k = 0
    While k < SchoolN.Length && c < n
        If !IntIn(must, mc, order[k])
            result[c] = order[k]
            c += 1
        EndIf
        k += 1
    EndWhile
    SetSchools(result, c)
EndFunction

Bool Function IntIn(Int[] buf, Int count, Int v)
    Int i = 0
    While i < count
        If buf[i] == v
            Return True
        EndIf
        i += 1
    EndWhile
    Return False
EndFunction

; app.js fitsBuild(entry) over the unified requires fields.
Bool Function FitsReq(String wName, String wSkill, String wSkillIn, String skill, String skillIn, String excl, String school, String schoolIn, Bool anyMagic, String armorIn, Bool dragonborn)
    String ws = CurWeaponSkill()
    If wName != "" && WeaponN[WeaponIdx] != wName
        Return False
    EndIf
    If wSkill != "" && ws != wSkill
        Return False
    EndIf
    If wSkillIn != "" && !InList(ws, wSkillIn)
        Return False
    EndIf
    If skill != "" && !HasSkillName(skill)
        Return False
    EndIf
    If skillIn != "" && !SkillsAnyIn(skillIn)
        Return False
    EndIf
    If excl != "" && SkillsAnyIn(excl)
        Return False
    EndIf
    If school != "" && !HasSchoolName(school)
        Return False
    EndIf
    If schoolIn != "" && !SchoolsAnyIn(schoolIn)
        Return False
    EndIf
    If anyMagic && SchoolCount == 0
        Return False
    EndIf
    If armorIn != "" && !InList(ArmorN[ArmorIdx], armorIn)
        Return False
    EndIf
    If dragonborn && !IsDragonborn
        Return False
    EndIf
    Return True
EndFunction

Bool Function StyleFits(Int i)
    Return FitsReq(StyleReqWeaponName[i], StyleReqWeaponSkill[i], StyleReqWeaponSkillIn[i], StyleReqSkill[i], StyleReqSkillIn[i], StyleReqExcludeSkills[i], StyleReqMagicSchool[i], StyleReqMagicSchoolIn[i], StyleReqAnyMagic[i], StyleReqArmorIn[i], StyleReqDragonborn[i])
EndFunction

Bool Function ArchFits(Int i)
    Return FitsReq(ArchReqWeaponName[i], ArchReqWeaponSkill[i], ArchReqWeaponSkillIn[i], ArchReqSkill[i], ArchReqSkillIn[i], ArchReqExcludeSkills[i], ArchReqMagicSchool[i], ArchReqMagicSchoolIn[i], ArchReqAnyMagic[i], ArchReqArmorIn[i], ArchReqDragonborn[i])
EndFunction

Function RollCombatStyle()
    Int[] buf = new Int[32]
    Int c = 0
    Int i = 0
    While i < StyleN.Length
        If StyleFits(i)
            buf[c] = i
            c += 1
        EndIf
        i += 1
    EndWhile
    Style = PickFrom(buf, c)
EndFunction

Function RollArchetype()
    Int[] buf = new Int[32]
    Int c = 0
    Int i = 0
    While i < ArchN.Length
        If ArchFits(i)
            buf[c] = i
            c += 1
        EndIf
        i += 1
    EndWhile
    Arch = PickFrom(buf, c)
EndFunction

Bool Function ArmorFits(Int a)
    If ArmorAnyMagic[a] && SchoolCount == 0
        Return False
    EndIf
    If ArmorWeaponSkillNot[a] != "" && InList(CurWeaponSkill(), ArmorWeaponSkillNot[a])
        Return False
    EndIf
    Return True
EndFunction

Function RollArmor()
    Int la = LA()
    Int[] buf = new Int[8]
    Int c = 0
    Int a = 0
    While a < ArmorN.Length
        Bool ok = ArmorFits(a)
        If ok && la >= 0 && ArchReqArmorIn[la] != "" && !InList(ArmorN[a], ArchReqArmorIn[la])
            ok = False
        EndIf
        If ok
            buf[c] = a
            c += 1
        EndIf
        a += 1
    EndWhile
    Int pickA = PickFrom(buf, c)
    If pickA < 0
        pickA = 0 ; Heavy Armor always fits armorFits; only contradictory locks land here
    EndIf
    ArmorIdx = pickA
EndFunction

Function RollFaction()
    Int[] buf = new Int[16]
    Int c = 0
    Int f = 0
    While f < FactionN.Length
        Bool ok = FactionAllowedByLockedRules(f)
        If ok && Locked[CAT_AFFL] && InList(FactionN[f], AfflIncompatF[Affl])
            ok = False
        EndIf
        If ok
            buf[c] = f
            c += 1
        EndIf
        f += 1
    EndWhile
    FactionIdx = PickFrom(buf, c)
EndFunction

Function RollAffliction()
    LockedRuleFlags()
    Int[] buf = new Int[8]
    Int c = 0
    Int a = 0
    While a < AfflN.Length
        Bool ok = !InList(FactionN[FactionIdx], AfflIncompatF[a])
        If ok && LRNoDaedra && AfflDaedric[a]
            ok = False
        EndIf
        If ok
            buf[c] = a
            c += 1
        EndIf
        a += 1
    EndWhile
    Affl = PickFrom(buf, c)
EndFunction

Bool Function BuildHasDaedra()
    Return DeityDaedric[Deity] || AfflDaedric[Affl] || FactionDaedric[FactionIdx]
EndFunction

; The per-rule checks shared by roll / remove / choose (rules that fit the
; current build's magic, weapon, daedric ties, deity and faction).
Bool Function RuleFitsBuild(Int r, Bool hasMagic)
    If RuleReqMagic[r] && !hasMagic
        Return False
    EndIf
    If RuleReqNoMagic[r] && hasMagic
        Return False
    EndIf
    If RuleIncompatW[r] != "" && RuleIncompatW[r] == WeaponN[WeaponIdx]
        Return False
    EndIf
    If RuleNoDaedra[r] && BuildHasDaedra()
        Return False
    EndIf
    If InList(DeityN[Deity], RuleIncompatD[r])
        Return False
    EndIf
    If InList(FactionN[FactionIdx], RuleIncompatF[r])
        Return False
    EndIf
    Return True
EndFunction

Function RollRoleplayRules()
    Bool hasMagic = SchoolCount > 0
    Int[] picked = new Int[8]
    Int pc = 0
    Int[] order = Shuffled(RuleN.Length)
    Int k = 0
    While k < RuleN.Length && pc < 4
        Int cand = order[k]
        If RuleFitsBuild(cand, hasMagic) && !RuleClashes(picked, pc, cand)
            picked[pc] = cand
            pc += 1
        EndIf
        k += 1
    EndWhile
    SetRules(picked, pc)
EndFunction

Function RollCharacter()
    Female = Utility.RandomInt(0, 1) == 1
    If CustomGender >= 0
        Female = CustomGender == 1
    EndIf
    If CustomName != ""
        CharName = CustomName
    Else
        CharName = BLD_Data.PickName(RaceN[RaceIdx], Female)
    EndIf
    CharRace = RaceIdx
EndFunction

; =========================================================================
; generate / lock (app.js generateAll / toggleLock)
; =========================================================================

Function GenerateAll()
    If !Locked[CAT_RACE]
        RaceIdx = Utility.RandomInt(0, RaceN.Length - 1)
    EndIf
    If !Locked[CAT_STONE]
        Stone = Utility.RandomInt(0, StoneN.Length - 1)
    EndIf
    If !Locked[CAT_DEITY]
        Deity = Utility.RandomInt(0, DeityN.Length - 1)
    EndIf
    If !Locked[CAT_MORAL]
        Moral = Utility.RandomInt(0, MoralN.Length - 1)
    EndIf
    If !Locked[CAT_DEITY] && !DeityAllowedByLockedRules(Deity)
        RollDeityAllowed()
    EndIf
    If !Locked[CAT_FACTION]
        RollFaction()
    EndIf
    If !Locked[CAT_AFFL]
        RollAffliction()
    EndIf
    If !Locked[CAT_WEAPON]
        RollWeapon()
    EndIf
    If !Locked[CAT_SKILLS]
        RollSkills()
    EndIf
    If !Locked[CAT_SCHOOLS]
        RollMagicSchools()
    EndIf
    If !Locked[CAT_ARMOR]
        RollArmor()
    EndIf
    If !Locked[CAT_RULES]
        RollRoleplayRules()
    EndIf
    If !Locked[CAT_STYLE]
        RollCombatStyle()
    EndIf
    If !Locked[CAT_ARCH]
        RollArchetype()
    EndIf
    If !Locked[CAT_CHARACTER]
        RollCharacter()
    EndIf
    NarrativeText = BuildNarrative()
EndFunction

Function RollDeityAllowed()
    Int[] buf = new Int[32]
    Int c = 0
    Int d = 0
    While d < DeityN.Length
        If DeityAllowedByLockedRules(d)
            buf[c] = d
            c += 1
        EndIf
        d += 1
    EndWhile
    Deity = PickFrom(buf, c)
EndFunction

Function ToggleLock(Int cat)
    Locked[cat] = !Locked[cat]
EndFunction

; =========================================================================
; direct choices (app.js *FitsNow, choose*, remove*, reconcile, applyChoice)
; =========================================================================

Bool Function WeaponFitsNow()
    String ws = CurWeaponSkill()
    If ws != "" && !HasSkillName(ws)
        Return False
    EndIf
    Int ls = LS()
    If ls >= 0
        If StyleReqWeaponName[ls] != "" && WeaponN[WeaponIdx] != StyleReqWeaponName[ls]
            Return False
        EndIf
        If StyleReqWeaponSkill[ls] != "" && ws != StyleReqWeaponSkill[ls]
            Return False
        EndIf
    EndIf
    Int la = LA()
    If la >= 0
        If ArchReqWeaponName[la] != "" && WeaponN[WeaponIdx] != ArchReqWeaponName[la]
            Return False
        EndIf
        If ArchReqWeaponSkillIn[la] != "" && !InList(ws, ArchReqWeaponSkillIn[la])
            Return False
        EndIf
    EndIf
    Int lar = LArm()
    If lar >= 0 && ArmorWeaponSkillNot[lar] != "" && InList(ws, ArmorWeaponSkillNot[lar])
        Return False
    EndIf
    LockedRuleFlags()
    If LRIncW != "" && InList(WeaponN[WeaponIdx], LRIncW)
        Return False
    EndIf
    Return True
EndFunction

Bool Function SkillsFitNow()
    String ws = CurWeaponSkill()
    If ws != "" && !HasSkillName(ws)
        Return False
    EndIf
    Int ls = LS()
    If ls >= 0
        If StyleReqSkill[ls] != "" && !HasSkillName(StyleReqSkill[ls])
            Return False
        EndIf
        If StyleReqExcludeSkills[ls] != "" && SkillsAnyIn(StyleReqExcludeSkills[ls])
            Return False
        EndIf
    EndIf
    Int la = LA()
    If la >= 0 && ArchReqSkillIn[la] != "" && !SkillsAnyIn(ArchReqSkillIn[la])
        Return False
    EndIf
    LockedRuleFlags()
    Bool noMagic = LRReqNoMagic || (Locked[CAT_SCHOOLS] && SchoolCount == 0)
    If noMagic && SkillsNeedMagic()
        Return False
    EndIf
    Return True
EndFunction

Bool Function MagicFitsNow()
    LockedRuleFlags()
    If LRReqNoMagic && SchoolCount > 0
        Return False
    EndIf
    If LRReqMagic && SchoolCount == 0
        Return False
    EndIf
    Int ls = LS()
    Int la = LA()
    Int lar = LArm()
    If ls >= 0 && StyleReqMagicSchool[ls] != "" && !HasSchoolName(StyleReqMagicSchool[ls])
        Return False
    EndIf
    If la >= 0
        If ArchReqMagicSchool[la] != "" && !HasSchoolName(ArchReqMagicSchool[la])
            Return False
        EndIf
        If ArchReqMagicSchoolIn[la] != "" && !SchoolsAnyIn(ArchReqMagicSchoolIn[la])
            Return False
        EndIf
    EndIf
    Bool needAny = SkillsNeedMagic()
    If ls >= 0 && StyleReqAnyMagic[ls]
        needAny = True
    EndIf
    If la >= 0 && ArchReqAnyMagic[la]
        needAny = True
    EndIf
    If lar >= 0 && ArmorAnyMagic[lar]
        needAny = True
    EndIf
    If needAny && SchoolCount == 0
        Return False
    EndIf
    Return True
EndFunction

Bool Function ArmorFitsNow()
    If !ArmorFits(ArmorIdx)
        Return False
    EndIf
    Int la = LA()
    If la >= 0 && ArchReqArmorIn[la] != "" && !InList(ArmorN[ArmorIdx], ArchReqArmorIn[la])
        Return False
    EndIf
    Return True
EndFunction

Bool Function RulesFitNow()
    Bool hasMagic = SchoolCount > 0
    Int i = 0
    While i < RuleCount
        If !RuleFitsBuild(Rules[i], hasMagic)
            Return False
        EndIf
        i += 1
    EndWhile
    Return True
EndFunction

Function ChooseSkill(Int option)
    Int[] picked = new Int[8]
    picked[0] = option
    Int pc = 1
    Int[] cands = new Int[32]
    Int cc = 0
    Int i = 0
    While i < SkillCount
        cands[cc] = Skills[i]
        cc += 1
        i += 1
    EndWhile
    Int[] order = Shuffled(SkillN.Length)
    i = 0
    While i < SkillN.Length && cc < 32
        cands[cc] = order[i]
        cc += 1
        i += 1
    EndWhile
    Int k = 0
    While k < cc && pc < 3
        If !SkillClashes(picked, pc, cands[k])
            picked[pc] = cands[k]
            pc += 1
        EndIf
        k += 1
    EndWhile
    SetSkills(picked, pc)
EndFunction

Function ChooseMagicSchool(Int option)
    If option < 0
        SchoolCount = 0
        Return
    EndIf
    Int other = -1
    Int i = 0
    While i < SchoolCount
        If other < 0 && Schools[i] != option
            other = Schools[i]
        EndIf
        i += 1
    EndWhile
    Schools[0] = option
    SchoolCount = 1
    If other >= 0
        Schools[1] = other
        SchoolCount = 2
    EndIf
EndFunction

Function RemoveSkill(Int s)
    Int[] picked = new Int[8]
    Int pc = 0
    Int i = 0
    While i < SkillCount
        If Skills[i] != s
            picked[pc] = Skills[i]
            pc += 1
        EndIf
        i += 1
    EndWhile
    Int[] order = Shuffled(SkillN.Length)
    Int k = 0
    While k < SkillN.Length && pc < MAX_SKILLS
        Int cand = order[k]
        If cand != s && !SkillClashes(picked, pc, cand)
            picked[pc] = cand
            pc += 1
        EndIf
        k += 1
    EndWhile
    SetSkills(picked, pc)
EndFunction

Function RemoveMagicSchool(Int s)
    Int[] kept = new Int[5]
    Int kc = 0
    Int i = 0
    While i < SchoolCount
        If Schools[i] != s
            kept[kc] = Schools[i]
            kc += 1
        EndIf
        i += 1
    EndWhile
    SetSchools(kept, kc)
EndFunction

Function RemoveRule(Int r)
    Int[] picked = new Int[8]
    Int pc = 0
    Int i = 0
    While i < RuleCount
        If Rules[i] != r
            picked[pc] = Rules[i]
            pc += 1
        EndIf
        i += 1
    EndWhile
    Bool hasMagic = SchoolCount > 0
    Int[] order = Shuffled(RuleN.Length)
    Int k = 0
    While k < RuleN.Length && pc < MIN_RULES
        Int cand = order[k]
        Bool ok = cand != r && !RuleClashes(picked, pc, cand)
        If ok && RuleReqMagic[cand] && (!hasMagic || AnyRuleFlag(picked, pc, True))
            ok = False
        EndIf
        If ok && RuleReqNoMagic[cand] && (hasMagic || AnyRuleFlag(picked, pc, False))
            ok = False
        EndIf
        If ok && !RuleFitsBuild(cand, hasMagic)
            ok = False
        EndIf
        If ok
            picked[pc] = cand
            pc += 1
        EndIf
        k += 1
    EndWhile
    SetRules(picked, pc)
EndFunction

Function ChooseRule(Int option)
    If HasRuleIdx(option)
        Return
    EndIf
    Int target = RuleCount + 1
    If target > MAX_RULES
        target = MAX_RULES
    EndIf
    Bool hasMagic = SchoolCount > 0
    Int[] picked = new Int[8]
    picked[0] = option
    Int pc = 1
    Int[] cands = new Int[40]
    Int cc = 0
    Int i = 0
    While i < RuleCount
        cands[cc] = Rules[i]
        cc += 1
        i += 1
    EndWhile
    Int[] order = Shuffled(RuleN.Length)
    i = 0
    While i < RuleN.Length
        cands[cc] = order[i]
        cc += 1
        i += 1
    EndWhile
    Int k = 0
    While k < cc && pc < target
        Int cand = cands[k]
        Bool ok = !RuleClashes(picked, pc, cand)
        If ok && RuleReqMagic[cand] && AnyRuleFlag(picked, pc, True)
            ok = False
        EndIf
        If ok && RuleReqNoMagic[cand] && AnyRuleFlag(picked, pc, False)
            ok = False
        EndIf
        If ok && cand != option && !RuleFitsBuild(cand, hasMagic)
            ok = False
        EndIf
        If ok
            picked[pc] = cand
            pc += 1
        EndIf
        k += 1
    EndWhile
    SetRules(picked, pc)
EndFunction

; After a choice, reroll whatever stopped fitting. The chosen card is pinned
; (temporarily locked); every other lock is suspended for the pass.
Function Reconcile(Int chosen)
    Bool[] saved = new Bool[14]
    Int c = 0
    While c < CAT_COUNT
        saved[c] = Locked[c]
        Locked[c] = c == chosen
        c += 1
    EndWhile

    If chosen == CAT_RACE && CharRace != RaceIdx
        RollCharacter()
    EndIf
    If chosen != CAT_DEITY && !DeityAllowedByLockedRules(Deity)
        RollDeityAllowed()
    EndIf
    If chosen != CAT_FACTION && !FactionAllowedByLockedRules(FactionIdx)
        RollFaction()
    EndIf
    LockedRuleFlags()
    If chosen != CAT_AFFL && LRNoDaedra && AfflDaedric[Affl]
        RollAffliction()
    EndIf
    If InList(FactionN[FactionIdx], AfflIncompatF[Affl])
        If chosen == CAT_AFFL
            RollFaction()
        Else
            RollAffliction()
        EndIf
    EndIf
    If chosen != CAT_WEAPON && !WeaponFitsNow()
        RollWeapon()
    EndIf
    If chosen != CAT_SKILLS && !SkillsFitNow()
        RollSkills()
    EndIf
    If chosen != CAT_SCHOOLS && !MagicFitsNow()
        RollMagicSchools()
    EndIf
    If chosen != CAT_ARMOR && !ArmorFitsNow()
        RollArmor()
    EndIf
    If chosen != CAT_RULES && !RulesFitNow()
        RollRoleplayRules()
    EndIf
    If chosen != CAT_STYLE && !StyleFits(Style)
        RollCombatStyle()
    EndIf
    If chosen != CAT_ARCH && !ArchFits(Arch)
        RollArchetype()
    EndIf

    c = 0
    While c < CAT_COUNT
        Locked[c] = saved[c]
        c += 1
    EndWhile
EndFunction

; app.js applyChoice for the single-option cards. Picking the current value
; is a no-op (the card always needs one option).
Function ChooseSingle(Int cat, Int option)
    If CurrentSingle(cat) == option
        Return
    EndIf
    If cat == CAT_RACE
        RaceIdx = option
    ElseIf cat == CAT_ARCH
        Arch = option
    ElseIf cat == CAT_STONE
        Stone = option
    ElseIf cat == CAT_STYLE
        Style = option
        ; choosing "Shouts First" makes the character Dragonborn
        If StyleReqDragonborn[option]
            IsDragonborn = True
        EndIf
    ElseIf cat == CAT_ARMOR
        ArmorIdx = option
    ElseIf cat == CAT_WEAPON
        WeaponIdx = option
    ElseIf cat == CAT_AFFL
        Affl = option
    ElseIf cat == CAT_FACTION
        FactionIdx = option
    ElseIf cat == CAT_DEITY
        Deity = option
    ElseIf cat == CAT_MORAL
        Moral = option
    EndIf
    Reconcile(cat)
    NarrativeText = BuildNarrative()
EndFunction

Int Function CurrentSingle(Int cat)
    If cat == CAT_RACE
        Return RaceIdx
    ElseIf cat == CAT_ARCH
        Return Arch
    ElseIf cat == CAT_STONE
        Return Stone
    ElseIf cat == CAT_STYLE
        Return Style
    ElseIf cat == CAT_ARMOR
        Return ArmorIdx
    ElseIf cat == CAT_WEAPON
        Return WeaponIdx
    ElseIf cat == CAT_AFFL
        Return Affl
    ElseIf cat == CAT_FACTION
        Return FactionIdx
    ElseIf cat == CAT_DEITY
        Return Deity
    ElseIf cat == CAT_MORAL
        Return Moral
    EndIf
    Return -1
EndFunction

; app.js applyChoice for the multi-option cards (skills / schools / rules):
; picking a current option removes it (refilling to the card's floor), any
; other adds it. option -1 is the schools card's "None". Returns the notice
; app.js shows in the options modal ("" for none).
String Function ToggleMulti(Int cat, Int option)
    String before = ItemsText(cat, "|")
    Bool isCurrent
    String optName
    If cat == CAT_SKILLS
        optName = SkillN[option]
        isCurrent = HasSkillName(optName)
    ElseIf cat == CAT_SCHOOLS
        If option < 0
            optName = "None"
            isCurrent = SchoolCount == 0
        Else
            optName = SchoolN[option]
            isCurrent = HasSchoolName(optName)
        EndIf
    Else
        optName = RuleN[option]
        isCurrent = HasRuleIdx(option)
    EndIf

    If isCurrent
        If option < 0
            Return "Nothing to remove - pick a school to add it."
        EndIf
        If cat == CAT_SKILLS
            RemoveSkill(option)
        ElseIf cat == CAT_SCHOOLS
            RemoveMagicSchool(option)
        Else
            RemoveRule(option)
        EndIf
    Else
        If cat == CAT_SKILLS
            ChooseSkill(option)
        ElseIf cat == CAT_SCHOOLS
            ChooseMagicSchool(option)
        Else
            ChooseRule(option)
        EndIf
    EndIf
    Reconcile(cat)
    NarrativeText = BuildNarrative()

    String after = ItemsText(cat, "|")
    If isCurrent
        String added = PipeMinus(after, before)
        If added != ""
            Return "Removed " + optName + " - this card always carries " + MinPicks(cat) + ", so " + added + " took its place."
        EndIf
        Return "Removed " + optName + "."
    EndIf
    String dropped = PipeMinus(before, after)
    If optName != "None" && dropped != ""
        Return "Only " + MaxPicks(cat) + " fit on this card - replaced " + dropped + "."
    EndIf
    Return ""
EndFunction

Int Function MinPicks(Int cat)
    If cat == CAT_SKILLS
        Return 3
    ElseIf cat == CAT_RULES
        Return MIN_RULES
    EndIf
    Return 0
EndFunction

Int Function MaxPicks(Int cat)
    If cat == CAT_SKILLS
        Return MAX_SKILLS
    ElseIf cat == CAT_SCHOOLS
        Return MAX_SCHOOLS
    ElseIf cat == CAT_RULES
        Return MAX_RULES
    EndIf
    Return 1
EndFunction

; Names in pipe-list a that are not in pipe-list b, comma-joined.
String Function PipeMinus(String a, String b)
    If a == ""
        Return ""
    EndIf
    String[] names = StringUtil.Split(a, "|")
    String t = ""
    Int i = 0
    While i < names.Length
        If !InList(names[i], b)
            If t != ""
                t += ", "
            EndIf
            t += names[i]
        EndIf
        i += 1
    EndWhile
    Return t
EndFunction

; app.js setDragonborn. Turning it off while a locked "Shouts First" depends
; on it is refused (returns False).
Bool Function SetDragonborn(Bool value)
    IsDragonborn = value
    If !value && StyleReqDragonborn[Style]
        If Locked[CAT_STYLE]
            IsDragonborn = True
            Return False
        EndIf
        RollCombatStyle()
        If !ArchFits(Arch) && !Locked[CAT_ARCH]
            RollArchetype()
        EndIf
    EndIf
    NarrativeText = BuildNarrative()
    Return True
EndFunction

; ---- character editor (app.js openCharacterModal) ----

Bool Function ShownFemale()
    If CustomGender >= 0
        Return CustomGender == 1
    EndIf
    Return Female
EndFunction

Function ApplyCharacterEdit()
    Bool f = ShownFemale()
    String n = CustomName
    If n == ""
        n = BLD_Data.PickName(RaceN[RaceIdx], f)
    EndIf
    CharName = n
    Female = f
    CharRace = RaceIdx
    NarrativeText = BuildNarrative()
EndFunction

Function RollNameDice()
    CustomName = BLD_Data.PickName(RaceN[RaceIdx], ShownFemale())
    ApplyCharacterEdit()
EndFunction

Function SetGender(Bool f)
    If f
        CustomGender = 1
    Else
        CustomGender = 0
    EndIf
    ApplyCharacterEdit()
EndFunction

Function UseName(String n)
    CustomName = n
    ApplyCharacterEdit()
EndFunction

Function RandomizeCharacter()
    CustomName = ""
    CustomGender = -1
    RollCharacter()
    NarrativeText = BuildNarrative()
EndFunction

; =========================================================================
; narrative (app.js buildNarrative)
; =========================================================================

String Function ReplaceAll(String s, String token, String value)
    Int len = StringUtil.GetLength(token)
    Int at = StringUtil.Find(s, token)
    While at >= 0
        ; SKSE Substring treats len 0 as "to the end", so a token at index 0
        ; needs an explicit empty prefix
        String head = ""
        If at > 0
            head = StringUtil.Substring(s, 0, at)
        EndIf
        s = head + value + StringUtil.Substring(s, at + len)
        at = StringUtil.Find(s, token, at + StringUtil.GetLength(value))
    EndWhile
    Return s
EndFunction

String Function PickStr(String[] arr)
    Return arr[Utility.RandomInt(0, arr.Length - 1)]
EndFunction

String[] NarrVars

String Function Fill(String t)
    t = ReplaceAll(t, "{moral}", NarrVars[12])
    t = ReplaceAll(t, "{name}", NarrVars[0])
    t = ReplaceAll(t, "{sub}", NarrVars[1])
    t = ReplaceAll(t, "{obj}", NarrVars[2])
    t = ReplaceAll(t, "{pos}", NarrVars[3])
    t = ReplaceAll(t, "{origin}", NarrVars[4])
    t = ReplaceAll(t, "{archetype}", NarrVars[5])
    t = ReplaceAll(t, "{skills}", NarrVars[6])
    t = ReplaceAll(t, "{stone}", NarrVars[7])
    t = ReplaceAll(t, "{weapon}", NarrVars[8])
    t = ReplaceAll(t, "{style}", NarrVars[9])
    t = ReplaceAll(t, "{deity}", NarrVars[10])
    t = ReplaceAll(t, "{faction}", NarrVars[11])
    Return t
EndFunction

String Function BuildNarrative()
    NarrVars = new String[13]
    NarrVars[0] = CharName
    If Female
        NarrVars[1] = "she"
        NarrVars[2] = "her"
        NarrVars[3] = "her"
    Else
        NarrVars[1] = "he"
        NarrVars[2] = "him"
        NarrVars[3] = "his"
    EndIf
    NarrVars[4] = BLD_Data.NarrOrigin(RaceN[RaceIdx])
    NarrVars[5] = ArchN[Arch]
    NarrVars[6] = SkillsText(", ", " and ")
    NarrVars[7] = StoneN[Stone]
    If WeaponN[WeaponIdx] == "Fists"
        NarrVars[8] = "bare fists"
    Else
        NarrVars[8] = "the " + WeaponN[WeaponIdx]
    EndIf
    NarrVars[9] = StyleN[Style]
    NarrVars[10] = DeityN[Deity]
    NarrVars[11] = FactionN[FactionIdx]
    NarrVars[12] = ""
    NarrVars[12] = Fill(BLD_Data.NarrMoral(MoralN[Moral]))

    String t = Fill(PickStr(BLD_Data.NarrOpenings()))
    t += " " + Fill(PickStr(BLD_Data.NarrPaths()))
    t += " " + Fill(PickStr(BLD_Data.NarrCreeds()))
    String afflictionLine = BLD_Data.NarrAffliction(AfflN[Affl])
    If afflictionLine != ""
        t += " " + Fill(afflictionLine)
    EndIf
    If IsDragonborn
        t += " " + Fill(PickStr(BLD_Data.NarrDragonborn()))
    EndIf
    If FactionN[FactionIdx] == "None"
        t += " " + Fill(PickStr(BLD_Data.NarrFatesAlone()))
    Else
        t += " " + Fill(PickStr(BLD_Data.NarrFates()))
    EndIf
    Return t
EndFunction

; =========================================================================
; text helpers for the MCM, the power and the oracle log
; =========================================================================

String Function SkillsText(String sep, String lastSep)
    String t = ""
    Int i = 0
    While i < SkillCount
        If i > 0
            If i == SkillCount - 1
                t += lastSep
            Else
                t += sep
            EndIf
        EndIf
        t += SkillN[Skills[i]]
        i += 1
    EndWhile
    Return t
EndFunction

String Function ItemsText(Int cat, String sep)
    String t = ""
    Int i = 0
    If cat == CAT_SKILLS
        Return SkillsText(sep, sep)
    ElseIf cat == CAT_SCHOOLS
        If SchoolCount == 0
            Return "None"
        EndIf
        While i < SchoolCount
            If i > 0
                t += sep
            EndIf
            t += SchoolN[Schools[i]]
            i += 1
        EndWhile
        Return t
    ElseIf cat == CAT_RULES
        While i < RuleCount
            If i > 0
                t += sep
            EndIf
            t += RuleN[Rules[i]]
            i += 1
        EndWhile
        Return t
    ElseIf cat == CAT_CHARACTER
        Return CharName
    EndIf
    Return SingleName(cat, CurrentSingle(cat))
EndFunction

String Function SingleName(Int cat, Int i)
    If i < 0
        Return ""
    ElseIf cat == CAT_RACE
        Return RaceN[i]
    ElseIf cat == CAT_ARCH
        Return ArchN[i]
    ElseIf cat == CAT_STONE
        Return StoneN[i]
    ElseIf cat == CAT_STYLE
        Return StyleN[i]
    ElseIf cat == CAT_ARMOR
        Return ArmorN[i]
    ElseIf cat == CAT_WEAPON
        Return WeaponN[i]
    ElseIf cat == CAT_AFFL
        Return AfflN[i]
    ElseIf cat == CAT_FACTION
        Return FactionN[i]
    ElseIf cat == CAT_DEITY
        Return DeityN[i]
    ElseIf cat == CAT_MORAL
        Return MoralN[i]
    EndIf
    Return ""
EndFunction

String Function GenderWord()
    If Female
        Return "Female"
    EndIf
    Return "Male"
EndFunction

; app.js buildSummary()
String Function BuildSummary()
    String t = CharName + " - " + GenderWord() + " " + RaceN[RaceIdx]
    If IsDragonborn
        t += ", Dragonborn"
    EndIf
    t += "\n" + ArchN[Arch] + " - " + StyleN[Style]
    t += "\n\nSkills: " + SkillsText(", ", ", ")
    t += "\nStone: " + StoneN[Stone]
    t += "\nWeapon: " + WeaponN[WeaponIdx] + "   Armor: " + ArmorN[ArmorIdx]
    t += "\nMagic: " + ItemsText(CAT_SCHOOLS, ", ")
    t += "\nDeity: " + DeityN[Deity] + "   Morality: " + MoralN[Moral]
    t += "\nFaction: " + FactionN[FactionIdx] + "   Affliction: " + AfflN[Affl]
    t += "\n\nOath: " + ItemsText(CAT_RULES, ", ")
    Return t
EndFunction

String Function CatId(Int cat)
    String[] ids = new String[14]
    ids[0] = "character"
    ids[1] = "race"
    ids[2] = "archetype"
    ids[3] = "skills"
    ids[4] = "standingStone"
    ids[5] = "combatStyle"
    ids[6] = "armor"
    ids[7] = "weapon"
    ids[8] = "magicSchools"
    ids[9] = "affliction"
    ids[10] = "faction"
    ids[11] = "deity"
    ids[12] = "morality"
    ids[13] = "roleplayRules"
    Return ids[cat]
EndFunction

; The build as one JSON object (names, not indices) for the oracle log.
String Function StateJson()
    String t = "{\"character\":\"" + CharName + "|" + GenderWord() + "|" + RaceN[CharRace] + "\""
    Int c = 1
    While c < CAT_COUNT
        t += ",\"" + CatId(c) + "\":\"" + ItemsText(c, "|") + "\""
        c += 1
    EndWhile
    t += ",\"dragonborn\":" + (IsDragonborn as Int)
    t += ",\"locks\":\""
    c = 0
    While c < CAT_COUNT
        t += (Locked[c] as Int)
        c += 1
    EndWhile
    t += "\"}"
    Return t
EndFunction

; =========================================================================
; oracle self-test: random rolls, locks and choices, logged before/after to
; Documents\My Games\Skyrim Special Edition\Logs\Script\User\Buildnator.0.log
; (needs [Papyrus] bEnableLogging=1). Restores the player's build after.
; =========================================================================

Int Property SelfTestDone Auto Hidden

; menu (optional) gets a progress update every 5 steps. Papyrus stops while the
; game window is unfocused, so the test only advances with Skyrim in front.
Function SelfTest(Int n, BLD_MCM menu = None)
    ; snapshot the player's build so the test leaves it untouched
    Int[] snap = new Int[10]
    snap[0] = RaceIdx
    snap[1] = Arch
    snap[2] = Stone
    snap[3] = Style
    snap[4] = ArmorIdx
    snap[5] = WeaponIdx
    snap[6] = Affl
    snap[7] = FactionIdx
    snap[8] = Deity
    snap[9] = Moral
    Int[] snapSkills = new Int[3]
    Int[] snapSchools = new Int[5]
    Int[] snapRules = new Int[8]
    CopyInts(Skills, snapSkills, 3)
    CopyInts(Schools, snapSchools, 5)
    CopyInts(Rules, snapRules, 8)
    Int snapSkillCount = SkillCount
    Int snapSchoolCount = SchoolCount
    Int snapRuleCount = RuleCount
    Bool[] snapLocks = new Bool[14]
    Int c = 0
    While c < CAT_COUNT
        snapLocks[c] = Locked[c]
        c += 1
    EndWhile
    String snapName = CharName
    Bool snapFemale = Female
    Int snapCharRace = CharRace
    String snapCustomName = CustomName
    Int snapCustomGender = CustomGender
    Bool snapDb = IsDragonborn
    String snapNarr = NarrativeText

    Debug.OpenUserLog("Buildnator")
    Debug.TraceUser("Buildnator", "BEGIN|" + BLD_Data.DataHash() + "|" + n)
    SelfTestDone = 0
    c = 0
    While c < CAT_COUNT
        Locked[c] = False
        c += 1
    EndWhile
    GenerateAll()
    Int i = 0
    Int mode
    Int cat
    Int o
    String before
    String opt
    Bool v
    While i < n
        mode = Utility.RandomInt(0, 9)
        before = StateJson()
        If mode <= 4
            ; generate with random locks
            c = 0
            While c < CAT_COUNT
                Locked[c] = Utility.RandomInt(0, 4) == 0
                c += 1
            EndWhile
            before = StateJson()
            GenerateAll()
            Debug.TraceUser("Buildnator", "T|gen||" + before + "|" + StateJson())
        ElseIf mode <= 8
            ; a direct choice on a random card (multi cards toggle)
            cat = Utility.RandomInt(1, CAT_COUNT - 1)
            If cat == CAT_SCHOOLS
                o = Utility.RandomInt(-1, SchoolN.Length - 1)
            Else
                o = Utility.RandomInt(0, PoolSize(cat) - 1)
            EndIf
            If cat == CAT_SKILLS || cat == CAT_SCHOOLS || cat == CAT_RULES
                If o < 0
                    opt = "None"
                ElseIf cat == CAT_SKILLS
                    opt = SkillN[o]
                ElseIf cat == CAT_SCHOOLS
                    opt = SchoolN[o]
                Else
                    opt = RuleN[o]
                EndIf
                ToggleMulti(cat, o)
            Else
                opt = SingleName(cat, o)
                ChooseSingle(cat, o)
            EndIf
            Debug.TraceUser("Buildnator", "T|choose|" + CatId(cat) + ":" + opt + "|" + before + "|" + StateJson())
        Else
            v = !IsDragonborn
            SetDragonborn(v)
            Debug.TraceUser("Buildnator", "T|dragonborn|" + (v as Int) + "|" + before + "|" + StateJson())
        EndIf
        Debug.TraceUser("Buildnator", "N|" + NarrativeText)
        i += 1
        SelfTestDone = i
        If menu && i % 5 == 0
            menu.ShowSelfTestProgress(i, n)
        EndIf
    EndWhile
    Debug.TraceUser("Buildnator", "END")

    RaceIdx = snap[0]
    Arch = snap[1]
    Stone = snap[2]
    Style = snap[3]
    ArmorIdx = snap[4]
    WeaponIdx = snap[5]
    Affl = snap[6]
    FactionIdx = snap[7]
    Deity = snap[8]
    Moral = snap[9]
    CopyInts(snapSkills, Skills, 3)
    CopyInts(snapSchools, Schools, 5)
    CopyInts(snapRules, Rules, 8)
    SkillCount = snapSkillCount
    SchoolCount = snapSchoolCount
    RuleCount = snapRuleCount
    c = 0
    While c < CAT_COUNT
        Locked[c] = snapLocks[c]
        c += 1
    EndWhile
    CharName = snapName
    Female = snapFemale
    CharRace = snapCharRace
    CustomName = snapCustomName
    CustomGender = snapCustomGender
    IsDragonborn = snapDb
    NarrativeText = snapNarr
EndFunction

Function CopyInts(Int[] src, Int[] dst, Int n)
    Int i = 0
    While i < n
        dst[i] = src[i]
        i += 1
    EndWhile
EndFunction

Int Function PoolSize(Int cat)
    If cat == CAT_RACE
        Return RaceN.Length
    ElseIf cat == CAT_ARCH
        Return ArchN.Length
    ElseIf cat == CAT_STONE
        Return StoneN.Length
    ElseIf cat == CAT_STYLE
        Return StyleN.Length
    ElseIf cat == CAT_ARMOR
        Return ArmorN.Length
    ElseIf cat == CAT_WEAPON
        Return WeaponN.Length
    ElseIf cat == CAT_AFFL
        Return AfflN.Length
    ElseIf cat == CAT_FACTION
        Return FactionN.Length
    ElseIf cat == CAT_DEITY
        Return DeityN.Length
    ElseIf cat == CAT_MORAL
        Return MoralN.Length
    ElseIf cat == CAT_SKILLS
        Return SkillN.Length
    ElseIf cat == CAT_SCHOOLS
        Return SchoolN.Length
    ElseIf cat == CAT_RULES
        Return RuleN.Length
    EndIf
    Return 0
EndFunction

; =========================================================================
; applying the destiny (from v1 BLD_Main.ApplyBuild; returns the report text)
; =========================================================================

String Function ApplyBuild()
    Actor p = Game.GetPlayer()
    Float level = BLD_Data.SkillLevel() as Float
    String school0 = ""
    If SchoolCount > 0
        school0 = SchoolN[Schools[0]]
    EndIf

    Int i = 0
    While i < SkillCount
        p.SetActorValue(BLD_Data.SkillAv(SkillN[Skills[i]]), level)
        i += 1
    EndWhile

    p.AddSpell(BLD_Data.StoneAbility(StoneN[Stone]) as Spell, False)

    String weaponName = WeaponN[WeaponIdx]
    If weaponName == "Staff"
        Form staff = BLD_Data.StaffForSchool(school0)
        p.AddItem(staff, 1)
        p.EquipItem(staff)
    ElseIf weaponName != "Fists"
        Form w = BLD_Data.WeaponItem(weaponName)
        p.AddItem(w, 1)
        p.EquipItem(w)
        Form arrows = BLD_Data.WeaponAmmo(weaponName)
        If arrows
            p.AddItem(arrows, BLD_Data.WeaponAmmoCount(weaponName))
        EndIf
    EndIf
    If StyleN[Style] == "Sword & Shield"
        Form sh = BLD_Data.ShieldForArmor(ArmorN[ArmorIdx])
        p.AddItem(sh, 1)
        p.EquipItem(sh)
    EndIf

    If ArmorN[ArmorIdx] == "Mage Robes"
        Form robes = BLD_Data.RobesForSchool(school0)
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
            Form piece = BLD_Data.ArmorPiece(ArmorN[ArmorIdx], i)
            If piece
                p.AddItem(piece, 1)
                p.EquipItem(piece)
            EndIf
            i += 1
        EndWhile
    EndIf

    i = 0
    While i < SchoolCount
        p.AddSpell(BLD_Data.SchoolSpell(SchoolN[Schools[i]], 0) as Spell, False)
        p.AddSpell(BLD_Data.SchoolSpell(SchoolN[Schools[i]], 1) as Spell, False)
        i += 1
    EndWhile

    String afflName = AfflN[Affl]
    If afflName == "Vampire" || afflName == "Vampire Lord"
        p.AddSpell(Game.GetFormFromFile(0x000B8780, "Skyrim.esm") as Spell, False)
    ElseIf afflName == "Werewolf"
        p.AddSpell(Game.GetFormFromFile(0x00092C48, "Skyrim.esm") as Spell, False)
        GlobalVariable wolf = Game.GetFormFromFile(0x000ED06C, "Skyrim.esm") as GlobalVariable
        If wolf
            wolf.SetValue(1.0)
        EndIf
    EndIf

    p.AddItem(Game.GetFormFromFile(0x0000000F, "Skyrim.esm"), 100)

    BLD_Enforcer enf = GetAlias(0) as BLD_Enforcer
    If enf
        enf.Configure(RuleNames())
    EndIf

    Applied = True
    AppliedDay = Utility.GetCurrentGameTime()

    String report = "It is done. Skills honed, " + StoneN[Stone] + "'s blessing granted, gear donned, 100 gold in your purse.\n\nLive as " + ArchN[Arch] + " - " + StyleN[Style] + ", and honor your oath."
    If afflName == "Vampire" || afflName == "Vampire Lord"
        report += "\n\nA cold fever stirs: Sanguinare Vampiris runs in your blood. Vampirism takes hold in about three days."
        If afflName == "Vampire Lord"
            report += " For the Vampire Lord form, seek Harkon's gift (Dawnguard)."
        EndIf
    ElseIf afflName == "Werewolf"
        report += "\n\nHircine's gift prowls beneath your skin - Beast Form waits in your Powers menu."
    EndIf
    If FactionN[FactionIdx] != "None"
        report += "\n\nYour road leads to the " + FactionN[FactionIdx] + ". " + BLD_Data.FactionHint(FactionN[FactionIdx])
    EndIf
    Return report
EndFunction

String[] Function RuleNames()
    String[] a = new String[8]
    Int i = 0
    While i < RuleCount
        a[i] = RuleN[Rules[i]]
        i += 1
    EndWhile
    Return a
EndFunction

; Forsake an applied destiny: rules stop being enforced and the build becomes
; editable again (granted skills and gear stay - they were earned).
Function Forsake()
    BLD_Enforcer enf = GetAlias(0) as BLD_Enforcer
    If enf
        String[] noRules = new String[1]
        enf.Configure(noRules)
    EndIf
    Applied = False
EndFunction

; The lesser power: shows the destiny sheet and the story.
Function OnPowerUsed()
    String head = "Your destiny"
    If !Applied
        head += " (not yet accepted - Mod Configuration > Buildnator)"
    EndIf
    Debug.MessageBox(head + "\n\n" + BuildSummary())
    Utility.Wait(0.1)
    Debug.MessageBox(NarrativeText)
EndFunction
