ScriptName BLD_Roller Hidden
{Port of the site's roll pipeline (js/app.js generateAll) as stateless global
functions. Rolls happen in dependency order - weapon, skills, magic schools,
armor, rules, combat style, archetype - so every roll only needs the values
already fixed upstream. Schools/rules arrays use "" for unused slots.}

; ---------- generic helpers ----------

; Fisher-Yates shuffled 0..n-1 (n <= 64).
Int[] Function ShuffledIndexes(Int n) Global
    Int[] idx = new Int[64]
    Int i = 0
    While i < n
        idx[i] = i
        i += 1
    EndWhile
    i = n - 1
    While i > 0
        Int j = Utility.RandomInt(0, i)
        Int tmp = idx[i]
        idx[i] = idx[j]
        idx[j] = tmp
        i -= 1
    EndWhile
    Return idx
EndFunction

Int Function IndexOf(String[] arr, String value) Global
    Int i = 0
    While i < arr.Length
        If arr[i] == value
            Return i
        EndIf
        i += 1
    EndWhile
    Return -1
EndFunction

; Count of non-empty slots in a ""-padded array.
Int Function CountFilled(String[] arr) Global
    Int n = 0
    Int i = 0
    While i < arr.Length
        If arr[i] != ""
            n += 1
        EndIf
        i += 1
    EndWhile
    Return n
EndFunction

Bool Function Contains(String[] arr, String value) Global
    Return IndexOf(arr, value) >= 0
EndFunction

; Whether any element of arr appears in the pipe-list.
Bool Function AnyInList(String[] arr, String asList) Global
    Int i = 0
    While i < arr.Length
        If arr[i] != "" && BLD_Data.InList(arr[i], asList)
            Return True
        EndIf
        i += 1
    EndWhile
    Return False
EndFunction

String Function PickRandom(String[] pool) Global
    Return pool[Utility.RandomInt(0, pool.Length - 1)]
EndFunction

; ---------- conflicts & magic skills ----------

Bool Function SkillsConflict(String a, String b) Global
    String[] groups = BLD_Data.SkillConflictGroups()
    Int i = 0
    While i < groups.Length
        If BLD_Data.InList(a, groups[i]) && BLD_Data.InList(b, groups[i])
            Return True
        EndIf
        i += 1
    EndWhile
    Return False
EndFunction

Bool Function RulesConflict(String a, String b) Global
    String[] groups = BLD_Data.RuleConflictGroups()
    Int i = 0
    While i < groups.Length
        If BLD_Data.InList(a, groups[i]) && BLD_Data.InList(b, groups[i])
            Return True
        EndIf
        i += 1
    EndWhile
    Return False
EndFunction

Bool Function IsMagicSkill(String skill) Global
    Return Contains(BLD_Data.MagicSkills(), skill)
EndFunction

Bool Function AnyMagicSkill(String[] skills) Global
    Int i = 0
    While i < skills.Length
        If skills[i] != "" && IsMagicSkill(skills[i])
            Return True
        EndIf
        i += 1
    EndWhile
    Return False
EndFunction

; ---------- simple rolls ----------

String Function RollRace() Global
    Return PickRandom(BLD_Data.RaceNames())
EndFunction

String Function RollStone() Global
    Return PickRandom(BLD_Data.StoneNames())
EndFunction

String Function RollDeity() Global
    Return PickRandom(BLD_Data.DeityNames())
EndFunction

String Function RollMorality() Global
    Return PickRandom(BLD_Data.MoralityNames())
EndFunction

String Function RollFaction() Global
    Return PickRandom(BLD_Data.FactionNames())
EndFunction

; Affliction respects the rolled faction (Vampires never roll for Dawnguard...).
String Function RollAffliction(String factionName) Global
    String[] names = BLD_Data.AfflictionNames()
    String[] incompat = BLD_Data.AfflictionIncompatFactions()
    Int[] order = ShuffledIndexes(names.Length)
    Int i = 0
    While i < names.Length
        Int c = order[i]
        If !BLD_Data.InList(factionName, incompat[c])
            Return names[c]
        EndIf
        i += 1
    EndWhile
    Return "None"
EndFunction

String Function RollWeapon() Global
    Return PickRandom(BLD_Data.WeaponNames())
EndFunction

String Function WeaponSkillOf(String weaponName) Global
    String[] names = BLD_Data.WeaponNames()
    Return BLD_Data.WeaponSkills()[IndexOf(names, weaponName)]
EndFunction

; ---------- skills ----------

; 3 distinct skills; the weapon's governing skill is always included and
; conflict-group skills never roll together.
String[] Function RollSkills(String weaponSkill) Global
    String[] picked = new String[3]
    Int n = 0
    If weaponSkill != ""
        picked[0] = weaponSkill
        n = 1
    EndIf
    String[] pool = BLD_Data.SkillNames()
    Int[] order = ShuffledIndexes(pool.Length)
    Int i = 0
    While i < pool.Length && n < 3
        String candidate = pool[order[i]]
        If CanAddSkill(picked, candidate)
            picked[n] = candidate
            n += 1
        EndIf
        i += 1
    EndWhile
    Return picked
EndFunction

; Validation shared with the manual wizard: distinct + no conflict pair.
Bool Function CanAddSkill(String[] picked, String candidate) Global
    Int i = 0
    While i < picked.Length
        If picked[i] != ""
            If picked[i] == candidate || SkillsConflict(picked[i], candidate)
                Return False
            EndIf
        EndIf
        i += 1
    EndWhile
    Return True
EndFunction

; ---------- magic schools ----------

; 0-2 schools, ""-padded String[2]. Magic-touched primaries force >= 1.
String[] Function RollSchools(String[] skills) Global
    String[] schools = new String[2]
    Int n = Utility.RandomInt(0, 2)
    If AnyMagicSkill(skills) && n == 0
        n = 1
    EndIf
    If n == 0
        Return schools
    EndIf
    String[] pool = BLD_Data.SchoolNames()
    Int[] order = ShuffledIndexes(pool.Length)
    Int i = 0
    While i < n
        schools[i] = pool[order[i]]
        i += 1
    EndWhile
    Return schools
EndFunction

; ---------- armor ----------

Bool Function ArmorFits(Int idx, String weaponSkill, Bool hasMagic) Global
    If BLD_Data.ArmorAnyMagic()[idx] && !hasMagic
        Return False
    EndIf
    If weaponSkill != "" && BLD_Data.InList(weaponSkill, BLD_Data.ArmorWeaponSkillNot()[idx])
        Return False
    EndIf
    Return True
EndFunction

String Function RollArmor(String weaponSkill, Bool hasMagic) Global
    String[] names = BLD_Data.ArmorNames()
    Int[] order = ShuffledIndexes(names.Length)
    Int i = 0
    While i < names.Length
        If ArmorFits(order[i], weaponSkill, hasMagic)
            Return names[order[i]]
        EndIf
        i += 1
    EndWhile
    Return "Clothes Only"
EndFunction

; ---------- roleplay rules ----------

Bool Function BuildHasDaedra(String deityName, String afflictionName, String factionName) Global
    If BLD_Data.DeityDaedric()[IndexOf(BLD_Data.DeityNames(), deityName)]
        Return True
    EndIf
    If BLD_Data.AfflictionDaedric()[IndexOf(BLD_Data.AfflictionNames(), afflictionName)]
        Return True
    EndIf
    Return BLD_Data.FactionDaedric()[IndexOf(BLD_Data.FactionNames(), factionName)]
EndFunction

; Whether one rule fits the build (ignoring the other picked rules).
Bool Function RuleFits(Int idx, Bool hasMagic, String weaponName, Bool hasDaedra, String deityName, String factionName) Global
    If BLD_Data.RuleRequiresMagic()[idx] && !hasMagic
        Return False
    EndIf
    If BLD_Data.RuleRequiresNoMagic()[idx] && hasMagic
        Return False
    EndIf
    If BLD_Data.RuleIncompatWeapon()[idx] == weaponName && weaponName != ""
        Return False
    EndIf
    If BLD_Data.RuleNoDaedra()[idx] && hasDaedra
        Return False
    EndIf
    If BLD_Data.InList(deityName, BLD_Data.RuleIncompatDeities()[idx])
        Return False
    EndIf
    Return !BLD_Data.InList(factionName, BLD_Data.RuleIncompatFactions()[idx])
EndFunction

; Shared with the manual wizard: candidate vs. already-picked rules.
Bool Function CanAddRule(String[] picked, String candidate) Global
    Int i = 0
    While i < picked.Length
        If picked[i] != ""
            If picked[i] == candidate || RulesConflict(picked[i], candidate)
                Return False
            EndIf
        EndIf
        i += 1
    EndWhile
    Return True
EndFunction

; 4 rules, ""-padded String[8] (the wizard can grow the set to 8).
String[] Function RollRules(Bool hasMagic, String weaponName, Bool hasDaedra, String deityName, String factionName) Global
    String[] picked = new String[8]
    String[] names = BLD_Data.RuleNames()
    Int[] order = ShuffledIndexes(names.Length)
    Int n = 0
    Int i = 0
    While i < names.Length && n < 4
        Int c = order[i]
        If RuleFits(c, hasMagic, weaponName, hasDaedra, deityName, factionName) && CanAddRule(picked, names[c])
            picked[n] = names[c]
            n += 1
        EndIf
        i += 1
    EndWhile
    Return picked
EndFunction

; ---------- combat style ----------

Bool Function StyleFits(Int idx, String weaponName, String weaponSkill, String[] skills, String[] schools, Bool isDragonborn) Global
    String reqWeapon = BLD_Data.StyleWeaponName()[idx]
    If reqWeapon != "" && weaponName != reqWeapon
        Return False
    EndIf
    String reqWeaponSkill = BLD_Data.StyleWeaponSkill()[idx]
    If reqWeaponSkill != "" && weaponSkill != reqWeaponSkill
        Return False
    EndIf
    String reqSkill = BLD_Data.StyleSkill()[idx]
    If reqSkill != "" && !Contains(skills, reqSkill)
        Return False
    EndIf
    If AnyInList(skills, BLD_Data.StyleExcludeSkills()[idx])
        Return False
    EndIf
    String reqSchool = BLD_Data.StyleMagicSchool()[idx]
    If reqSchool != "" && !Contains(schools, reqSchool)
        Return False
    EndIf
    If BLD_Data.StyleAnyMagic()[idx] && CountFilled(schools) == 0
        Return False
    EndIf
    Return !BLD_Data.StyleDragonborn()[idx] || isDragonborn
EndFunction

; Never empty: Opportunist has no requirements.
String Function RollStyle(String weaponName, String weaponSkill, String[] skills, String[] schools, Bool isDragonborn) Global
    String[] names = BLD_Data.StyleNames()
    Int[] order = ShuffledIndexes(names.Length)
    Int i = 0
    While i < names.Length
        If StyleFits(order[i], weaponName, weaponSkill, skills, schools, isDragonborn)
            Return names[order[i]]
        EndIf
        i += 1
    EndWhile
    Return "Opportunist"
EndFunction

; ---------- archetype ----------

Bool Function ArchFits(Int idx, String weaponName, String weaponSkill, String[] skills, String[] schools, String armorName) Global
    String reqWeapon = BLD_Data.ArchWeaponName()[idx]
    If reqWeapon != "" && weaponName != reqWeapon
        Return False
    EndIf
    String weaponSkillIn = BLD_Data.ArchWeaponSkillIn()[idx]
    If weaponSkillIn != "" && !BLD_Data.InList(weaponSkill, weaponSkillIn)
        Return False
    EndIf
    String skillIn = BLD_Data.ArchSkillIn()[idx]
    If skillIn != "" && !AnyInList(skills, skillIn)
        Return False
    EndIf
    String reqSchool = BLD_Data.ArchMagicSchool()[idx]
    If reqSchool != "" && !Contains(schools, reqSchool)
        Return False
    EndIf
    String schoolIn = BLD_Data.ArchMagicSchoolIn()[idx]
    If schoolIn != "" && !AnyInList(schools, schoolIn)
        Return False
    EndIf
    If BLD_Data.ArchAnyMagic()[idx] && CountFilled(schools) == 0
        Return False
    EndIf
    String armorIn = BLD_Data.ArchArmorIn()[idx]
    Return armorIn == "" || BLD_Data.InList(armorName, armorIn)
EndFunction

; Never empty: Pilgrim has no requirements.
String Function RollArchetype(String weaponName, String weaponSkill, String[] skills, String[] schools, String armorName) Global
    String[] names = BLD_Data.ArchNames()
    Int[] order = ShuffledIndexes(names.Length)
    Int i = 0
    While i < names.Length
        If ArchFits(order[i], weaponName, weaponSkill, skills, schools, armorName)
            Return names[order[i]]
        EndIf
        i += 1
    EndWhile
    Return "Pilgrim"
EndFunction
