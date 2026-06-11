ScriptName BLD_PowerFX extends ActiveMagicEffect
{Effect script of the "Buildnator: Destiny" lesser power - forwards the cast
to the main quest.}

Quest Property MainQuest Auto

Event OnEffectStart(Actor akTarget, Actor akCaster)
    (MainQuest as BLD_Main).OnPowerUsed()
EndEvent
