ScriptName BLD_Main extends Quest
{Buildnator main quest: shows the build wizard when a new game starts.}

Message Property IntroMsg Auto

Event OnInit()
    ; Give the engine a moment so the message box doesn't fight the intro.
    Utility.Wait(3.0)
    int choice = IntroMsg.Show()
    Debug.Notification("Buildnator: pipeline OK (button " + choice + ")")
EndEvent
