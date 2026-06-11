ScriptName BLD_Enforcer extends ReferenceAlias
{Buildnator player-alias script: enforces the accepted build's roleplay rules.
Configure() is called by BLD_Main when the build is applied.}

String[] ActiveRules

Bool Function HasRule(String name)
    Return ActiveRules && BLD_Roller.Contains(ActiveRules, name)
EndFunction

Function Configure(String[] rules)
    ActiveRules = rules
    Debug.Trace("[Buildnator] enforcer configured: " + rules)
EndFunction
