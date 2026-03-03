Scriptname LoreOutHUD_TestQuestScript extends Quest
{ LoreOut HUD test widget loader — GhostHUD-grade lifecycle.
  Delayed init + retry + state flags + OnPlayerLoadGame re-init. }

; Command IDs — must match AS3 widget processMessage expectations
; SendMessage passes these as Floats: processMessage(cmd_as_string, [arg1..arg6])
Int Property CMD_SET_TEXT = 100 Auto Const
Int Property CMD_SET_COUNTER = 101 Auto Const

; Widget filename (must match SWF in Interface/)
String Property WIDGET_FILE = "LoreOutTestWidget.swf" Auto Const

; Timer IDs
Int TIMER_REGISTER = 0 Const
Int TIMER_UPDATE = 1 Const

; State
HUDFramework hud
Bool bRegistered = false
Bool bLoaded = false
Int counter = 0

; === LIFECYCLE ===

Event OnInit()
    Debug.Trace("[LoreOutHUD] OnInit — delaying registration 4 seconds")
    RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")
    StartTimer(4.0, TIMER_REGISTER)
EndEvent

Event Actor.OnPlayerLoadGame(Actor akSender)
    Debug.Trace("[LoreOutHUD] OnPlayerLoadGame — resetting state")
    bLoaded = false
    bRegistered = false
    StartTimer(4.0, TIMER_REGISTER)
EndEvent

Event OnTimer(Int aiTimerID)
    if aiTimerID == TIMER_REGISTER
        AttemptRegister()
    elseif aiTimerID == TIMER_UPDATE
        UpdateCounter()
        StartTimer(1.0, TIMER_UPDATE)
    endif
EndEvent

; === REGISTRATION (with retry) ===

Function AttemptRegister()
    hud = HUDFramework.GetInstance()

    if hud == None
        Debug.Trace("[LoreOutHUD] HUDFramework not ready — retrying in 5s")
        StartTimer(5.0, TIMER_REGISTER)
        return
    endif

    if !bRegistered
        Debug.Trace("[LoreOutHUD] Registering widget: " + WIDGET_FILE)
        ; loadNow=False, autoLoad=False — we control loading manually
        hud.RegisterWidget(Self as ScriptObject, WIDGET_FILE, 30.0, 30.0, False, False)
        bRegistered = true
    endif

    Debug.Trace("[LoreOutHUD] Loading widget...")
    hud.LoadWidget(WIDGET_FILE)
EndFunction

; === WIDGET LOADED CALLBACK ===

Function HUD_WidgetLoaded(String asWidgetID)
    if asWidgetID != WIDGET_FILE
        return
    endif

    bLoaded = true
    Debug.Trace("[LoreOutHUD] Widget loaded: " + asWidgetID)

    ; CMD_SET_TEXT (100): tells widget to show "loaded" state
    hud.SendMessage(WIDGET_FILE, CMD_SET_TEXT, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)

    ; Start counter test loop
    counter = 0
    StartTimer(1.0, TIMER_UPDATE)
EndFunction

; === UPDATE LOOP ===

Function UpdateCounter()
    if !hud || !bLoaded
        return
    endif

    counter += 1
    hud.SendMessage(WIDGET_FILE, CMD_SET_COUNTER, counter as Float, 0.0, 0.0, 0.0, 0.0, 0.0)
EndFunction
