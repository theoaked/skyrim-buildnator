ScriptName BLD_Enforcer extends ReferenceAlias
{Buildnator player-alias script: enforces the accepted build's roleplay rules.
Configure() is called by BLD_Main when the build is applied (and again on re-rolls).}

; --- Properties filled by the esp generator (names must match Program.cs) ---
Spell Property AbNoMagicka Auto      ; constant: magicka floor (Born without magicka)
Spell Property AbAnemic Auto         ; constant: stamina floor (Anemic)
Spell Property AbNausea Auto         ; timed: bad food / potions
Spell Property AbGuilt Auto          ; timed: broke a conduct rule
Spell Property AbExhausted Auto      ; until sleep: Creature of Habit
Spell Property AbHungry Auto         ; daily: Hearty Appetite
Spell Property AbNightTerror Auto    ; while outside at night: Afraid of the Dark
Spell Property AbUnease Auto         ; while follower rule violated
FormList Property MeatList Auto
GlobalVariable Property FollowerCount Auto
GlobalVariable Property GameHourGlobal Auto
GlobalVariable Property DaysPassed Auto
Keyword Property KwWeapDaedric Auto
Keyword Property KwArmorDaedric Auto
Keyword Property KwDaedricArtifact Auto
Keyword Property KwWeapIron Auto
Keyword Property KwWeapWood Auto
Keyword Property KwArmorIron Auto
Keyword Property KwArmorIronBanded Auto
Keyword Property KwArmorHide Auto
Keyword Property KwArmorStudded Auto
Keyword Property KwArmorLeather Auto
Keyword Property KwArmorJewelry Auto
Keyword Property KwArmorClothing Auto
Keyword Property KwWeapStaff Auto

; --- Rule flags (set in Configure) ---
Bool RuleWanderlust
Bool RuleCreatureOfHabit
Bool RuleHeartyAppetite
Bool RuleHonestHands
Bool RuleRespectDead
Bool RuleHerbivore
Bool RuleAllThumbs
Bool RuleNeverAlone
Bool RuleFriendForest
Bool RuleNoMagicka
Bool RuleSensitiveStomach
Bool RuleAfraidDark
Bool RuleAgnostic
Bool RuleHeartOfIron
Bool RuleLoneWolf
Bool RuleVigilant
Bool RuleAnemic

; --- Runtime state ---
String[] ActiveRules
Bool Configured
Float NauseaUntil      ; real-time seconds (Utility.GetCurrentRealTime)
Float GuiltUntil
Int MealDay            ; game day the meal counter belongs to
Int MealsToday
Int LastSleepDay
Bool NightActive
Bool UneaseActive
Bool ExhaustedActive
Bool HungryActive

Bool Function HasRule(String asName)
    Return ActiveRules && BLD_Roller.Contains(ActiveRules, asName)
EndFunction

Function Configure(String[] rules)
    ActiveRules = rules
    RuleWanderlust = HasRule("Wanderlust")
    RuleCreatureOfHabit = HasRule("Creature of Habit")
    RuleHeartyAppetite = HasRule("Hearty Appetite")
    RuleHonestHands = HasRule("Honest Hands")
    RuleRespectDead = HasRule("Respect the Dead")
    RuleHerbivore = HasRule("Herbivore")
    RuleAllThumbs = HasRule("All Thumbs")
    RuleNeverAlone = HasRule("Never Alone")
    RuleFriendForest = HasRule("Friend of the Forest")
    RuleNoMagicka = HasRule("Born without magicka")
    RuleSensitiveStomach = HasRule("Sensitive Stomach")
    RuleAfraidDark = HasRule("Afraid of the Dark")
    RuleAgnostic = HasRule("Agnostic")
    RuleHeartOfIron = HasRule("Heart of Iron")
    RuleLoneWolf = HasRule("Lone Wolf")
    RuleVigilant = HasRule("Vigilant of Stendarr")
    RuleAnemic = HasRule("Anemic")

    Actor player = GetActorReference()

    ; Constant attribute rules
    SetConstant(player, AbNoMagicka, RuleNoMagicka)
    SetConstant(player, AbAnemic, RuleAnemic)

    ; Hard block: fast travel
    Game.EnableFastTravel(!RuleWanderlust)

    ; Reset every timed/state debuff (covers re-rolled destinies)
    player.RemoveSpell(AbNausea)
    player.RemoveSpell(AbGuilt)
    player.RemoveSpell(AbExhausted)
    player.RemoveSpell(AbHungry)
    player.RemoveSpell(AbNightTerror)
    player.RemoveSpell(AbUnease)
    NauseaUntil = 0.0
    GuiltUntil = 0.0
    NightActive = False
    UneaseActive = False
    ExhaustedActive = False
    HungryActive = False
    Int today = DaysPassed.GetValue() as Int
    MealDay = today
    MealsToday = 0
    LastSleepDay = today

    Configured = True
    RegisterForSleep()
    RegisterForSingleUpdate(8.0)
    Debug.Trace("[Buildnator] enforcer configured: " + rules)

    ; SKSE-only registration last: if SKSE is absent the native call aborts this
    ; function, but everything above has already taken effect.
    If RuleHonestHands || RuleFriendForest || RuleAllThumbs
        RegisterForTrackedStatsEvent()
    EndIf
EndFunction

Function SetConstant(Actor player, Spell ability, Bool active)
    If active
        If !player.HasSpell(ability)
            player.AddSpell(ability, False)
        EndIf
    Else
        player.RemoveSpell(ability)
    EndIf
EndFunction

Function StartNausea(String asReason)
    Actor player = GetActorReference()
    NauseaUntil = Utility.GetCurrentRealTime() + 120.0
    If !player.HasSpell(AbNausea)
        player.AddSpell(AbNausea, False)
    EndIf
    Debug.Notification(asReason)
EndFunction

Function StartGuilt(String asReason)
    Actor player = GetActorReference()
    GuiltUntil = Utility.GetCurrentRealTime() + 180.0
    If !player.HasSpell(AbGuilt)
        player.AddSpell(AbGuilt, False)
    EndIf
    Debug.Notification(asReason)
EndFunction

Function Reject(Form akItem, String asReason)
    GetActorReference().UnequipItem(akItem, False, True)
    Debug.MessageBox(asReason)
EndFunction

Bool Function IsDaedric(Form akItem)
    Return akItem.HasKeyword(KwWeapDaedric) || akItem.HasKeyword(KwArmorDaedric) || akItem.HasKeyword(KwDaedricArtifact)
EndFunction

Bool Function IronAllowed(Weapon akWeap, Armor akArm)
    If akWeap
        Return akWeap.HasKeyword(KwWeapIron) || akWeap.HasKeyword(KwWeapWood)
    EndIf
    Return akArm.HasKeyword(KwArmorIron) || akArm.HasKeyword(KwArmorIronBanded) \
        || akArm.HasKeyword(KwArmorHide) || akArm.HasKeyword(KwArmorStudded) \
        || akArm.HasKeyword(KwArmorLeather) || akArm.HasKeyword(KwArmorJewelry) \
        || akArm.HasKeyword(KwArmorClothing)
EndFunction

; ============================ Events ============================

Event OnObjectEquipped(Form akBaseObject, ObjectReference akReference)
    If !Configured
        Return
    EndIf

    ; Eating / drinking (food fires OnObjectEquipped too)
    Potion drink = akBaseObject as Potion
    If drink
        If drink.IsFood()
            MealsToday += 1
            If RuleHerbivore && MeatList.HasForm(akBaseObject)
                StartNausea("Meat! Your herbivore stomach rebels.")
            EndIf
        ElseIf RuleSensitiveStomach && !drink.IsPoison()
            StartNausea("Your sensitive stomach churns - no potions for you.")
        EndIf
        Return
    EndIf

    Weapon weap = akBaseObject as Weapon
    Armor arm = akBaseObject as Armor
    If !weap && !arm
        Return
    EndIf

    If RuleVigilant && IsDaedric(akBaseObject)
        Reject(akBaseObject, "A Vigilant of Stendarr does not wield Daedric filth. Destroy it.")
        Return
    EndIf
    If RuleHeartOfIron && !IronAllowed(weap, arm)
        Reject(akBaseObject, "Heart of Iron: if it's metal, it must be iron - hide and leather otherwise.")
        Return
    EndIf
    If RuleAgnostic
        Enchantment ench = None
        If weap
            ench = weap.GetEnchantment()
        Else
            ench = arm.GetEnchantment()
        EndIf
        If ench || (weap && weap.HasKeyword(KwWeapStaff))
            Reject(akBaseObject, "Magic is a trick you want no part of - not even baked into your gear.")
        EndIf
    EndIf
EndEvent

Event OnItemAdded(Form akBaseItem, Int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
    If !Configured || !RuleRespectDead
        Return
    EndIf
    Actor source = akSourceContainer as Actor
    If source && source.IsDead()
        StartGuilt("Grave-robbing. The dead deserve better from you.")
    EndIf
EndEvent

Event OnSleepStop(Bool abInterrupted)
    If !Configured
        Return
    EndIf
    If !abInterrupted
        LastSleepDay = DaysPassed.GetValue() as Int
        If ExhaustedActive
            ExhaustedActive = False
            GetActorReference().RemoveSpell(AbExhausted)
            Debug.Notification("Rested at last - your routine is restored.")
        EndIf
    EndIf
EndEvent

Event OnTrackedStatsEvent(String arStatName, Int aiStatValue)
    If !Configured || aiStatValue < 1
        Return
    EndIf
    If RuleHonestHands && (arStatName == "Items Stolen" || arStatName == "Pickpockets")
        StartGuilt("Honest Hands: that wasn't yours to take.")
    ElseIf RuleFriendForest && arStatName == "Animals Killed"
        StartGuilt("Friend of the Forest: you swore never to harm wildlife.")
    ElseIf RuleAllThumbs && (arStatName == "Weapons Made" || arStatName == "Armor Made" \
            || arStatName == "Weapons Improved" || arStatName == "Armor Improved" \
            || arStatName == "Potions Mixed" || arStatName == "Poisons Mixed" \
            || arStatName == "Magic Items Made")
        StartGuilt("All Thumbs: crafting is not your craft. Buy or find your gear.")
    EndIf
EndEvent

Event OnUpdate()
    If !Configured
        Return
    EndIf
    Actor player = GetActorReference()
    Float now = Utility.GetCurrentRealTime()

    ; Timed debuff expiry
    If NauseaUntil > 0.0 && now >= NauseaUntil
        NauseaUntil = 0.0
        player.RemoveSpell(AbNausea)
        Debug.Notification("Your stomach settles.")
    EndIf
    If GuiltUntil > 0.0 && now >= GuiltUntil
        GuiltUntil = 0.0
        player.RemoveSpell(AbGuilt)
        Debug.Notification("Your conscience quiets down.")
    EndIf

    ; Afraid of the Dark: outside between 20h and 6h
    If RuleAfraidDark
        Float hour = GameHourGlobal.GetValue()
        Bool night = (hour >= 20.0 || hour < 6.0) && !player.IsInInterior()
        If night && !NightActive
            NightActive = True
            player.AddSpell(AbNightTerror, False)
            Debug.Notification("Night falls and the terror takes hold - find shelter or wait for dawn.")
        ElseIf !night && NightActive
            NightActive = False
            player.RemoveSpell(AbNightTerror)
            Debug.Notification("The terror passes. You can breathe again.")
        EndIf
    EndIf

    ; Follower rules
    If RuleLoneWolf || RuleNeverAlone
        Int followers = FollowerCount.GetValue() as Int
        Bool violated = (RuleLoneWolf && followers > 0) || (RuleNeverAlone && followers < 1)
        If violated && !UneaseActive
            UneaseActive = True
            player.AddSpell(AbUnease, False)
            If RuleLoneWolf
                Debug.Notification("Lone Wolf: company makes your skin crawl. Dismiss your follower.")
            Else
                Debug.Notification("Never Alone: the solitude gnaws at you. Find a companion.")
            EndIf
        ElseIf !violated && UneaseActive
            UneaseActive = False
            player.RemoveSpell(AbUnease)
            Debug.Notification("You feel at ease again.")
        EndIf
    EndIf

    ; Game-day rollover: meals and sleep routine
    Int today = DaysPassed.GetValue() as Int
    If today > MealDay
        If RuleHeartyAppetite
            If MealsToday < 3 && !HungryActive
                HungryActive = True
                player.AddSpell(AbHungry, False)
                Debug.Notification("Hearty Appetite: you skipped meals yesterday. Eat three today!")
            ElseIf MealsToday >= 3 && HungryActive
                HungryActive = False
                player.RemoveSpell(AbHungry)
                Debug.Notification("Well fed - your strength returns.")
            EndIf
        EndIf
        MealsToday = 0
        MealDay = today
    EndIf
    If RuleCreatureOfHabit && today > LastSleepDay + 1 && !ExhaustedActive
        ExhaustedActive = True
        player.AddSpell(AbExhausted, False)
        Debug.Notification("Creature of Habit: you skipped your bedtime. Exhaustion sets in.")
    EndIf

    RegisterForSingleUpdate(8.0)
EndEvent
