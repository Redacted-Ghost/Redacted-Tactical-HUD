Scriptname LoreOutHUD_TestQuestScript extends Quest
{ LoreOut HUD test widget loader — GhostHUD-grade lifecycle.
  Delayed init + retry + state flags + OnPlayerLoadGame re-init.
  Uses Debug.TraceUser for logging (works without Papyrus INI logging). }

; Log name for Debug.TraceUser / Debug.OpenUserLog
; Writes to: Documents/My Games/Fallout4/Logs/Script/User/LoreOutHUD.0.log
String LOG_NAME = "LoreOutHUD" Const

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
    Debug.OpenUserLog(LOG_NAME)
    Debug.TraceUser(LOG_NAME, "=== OnInit ===")
    Debug.TraceUser(LOG_NAME, "Delaying registration 4 seconds")
    RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")
    StartTimer(4.0, TIMER_REGISTER)
EndEvent

Event Actor.OnPlayerLoadGame(Actor akSender)
    Debug.OpenUserLog(LOG_NAME)
    Debug.TraceUser(LOG_NAME, "=== OnPlayerLoadGame ===")
    Debug.TraceUser(LOG_NAME, "Resetting state for re-registration")
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
    Debug.TraceUser(LOG_NAME, "AttemptRegister() called")
    hud = HUDFramework.GetInstance()

    if hud == None
        Debug.TraceUser(LOG_NAME, "HUDFramework not ready - retrying in 5s")
        StartTimer(5.0, TIMER_REGISTER)
        return
    endif

    Debug.TraceUser(LOG_NAME, "HUDFramework instance obtained")

    if !bRegistered
        Debug.TraceUser(LOG_NAME, "Registering widget: " + WIDGET_FILE + " at (30, 30)")
        ; loadNow=False, autoLoad=False — we control loading manually
        hud.RegisterWidget(Self as ScriptObject, WIDGET_FILE, 30.0, 30.0, False, False)
        bRegistered = true
        Debug.TraceUser(LOG_NAME, "Widget registered successfully")
    else
        Debug.TraceUser(LOG_NAME, "Widget already registered, skipping")
    endif

    Debug.TraceUser(LOG_NAME, "Calling LoadWidget...")
    hud.LoadWidget(WIDGET_FILE)
EndFunction

; === WIDGET LOADED CALLBACK ===

Function HUD_WidgetLoaded(String asWidgetID)
    if asWidgetID != WIDGET_FILE
        return
    endif

    bLoaded = true
    Debug.TraceUser(LOG_NAME, "Widget loaded: " + asWidgetID)
    Debug.Notification("[LoreOutHUD] Widget loaded!")

    ; CMD_SET_TEXT (100): tells widget to show "loaded" state
    hud.SendMessage(WIDGET_FILE, CMD_SET_TEXT, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)

    ; Start counter test loop
    counter = 0
    StartTimer(1.0, TIMER_UPDATE)
    Debug.TraceUser(LOG_NAME, "Counter test loop started")
EndFunction

; === UPDATE LOOP ===

Function UpdateCounter()
    if !hud || !bLoaded
        return
    endif

    counter += 1
    hud.SendMessage(WIDGET_FILE, CMD_SET_COUNTER, counter as Float, 0.0, 0.0, 0.0, 0.0, 0.0)
EndFunction
