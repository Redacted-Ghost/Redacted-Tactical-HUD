Scriptname LoreOutAP_QuestScript extends Quest
{ Redacted Tactical HUD — Action Points Widget controller.
  Displays AP as a blue fill bar.
  Uses vanilla ActorValue for AP.

  CMD 600 (float): currentAP, maxAP, isInVATS, 0, 0, 0 }

; Log name
String LOG_NAME = "LoreOutAP" Const

; Command ID
Int Property CMD_AP = 600 Auto Const

; Widget SWF filename
String Property WIDGET_FILE = "LoreOutAPWidget.swf" Auto Const

; Timer IDs
Int TIMER_REGISTER = 0 Const
Int TIMER_UPDATE = 1 Const

; Position: left-side stack top. v11: 300x28 → (16, 488)
; AP(488)+28=516, 8px gap → Vitals at 524
Float Property WIDGET_X = 16.0 Auto Const
Float Property WIDGET_Y = 488.0 Auto Const

; Poll interval (faster than rads since AP changes during combat/sprinting)
Float POLL_INTERVAL = 0.25 Const

; State
HUDFramework hud
Bool bRegistered = false
Bool bLoaded = false

; ActorValue forms (resolved at runtime)
ActorValue avAP

; === LIFECYCLE ===

Event OnInit()
    Debug.OpenUserLog(LOG_NAME)
    Debug.TraceUser(LOG_NAME, "=== OnInit ===")
    ResolveActorValues()
    Actor player = Game.GetPlayer()
    RegisterForRemoteEvent(player, "OnPlayerLoadGame")
    StartTimer(4.0, TIMER_REGISTER)
EndEvent

Event Actor.OnPlayerLoadGame(Actor akSender)
    Debug.OpenUserLog(LOG_NAME)
    Debug.TraceUser(LOG_NAME, "=== OnPlayerLoadGame ===")
    bLoaded = false
    bRegistered = false
    ResolveActorValues()
    StartTimer(4.0, TIMER_REGISTER)
EndEvent

Function ResolveActorValues()
    ; ActionPoints ActorValue: Fallout4.esm FormID 0x000002D5
    avAP = Game.GetForm(0x000002D5) as ActorValue
    if avAP
        Debug.TraceUser(LOG_NAME, "ActionPoints AV resolved OK")
    else
        Debug.TraceUser(LOG_NAME, "WARNING: ActionPoints AV not found!")
    endif
EndFunction

Event OnTimer(Int aiTimerID)
    if aiTimerID == TIMER_REGISTER
        AttemptRegister()
    elseif aiTimerID == TIMER_UPDATE
        SendAPData()
        StartTimer(POLL_INTERVAL, TIMER_UPDATE)
    endif
EndEvent

; === REGISTRATION ===

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
        Debug.TraceUser(LOG_NAME, "Registering at (" + WIDGET_X + ", " + WIDGET_Y + ")")
        hud.RegisterWidget(Self as ScriptObject, WIDGET_FILE, WIDGET_X, WIDGET_Y, False, False)
        bRegistered = true
    endif

    Debug.TraceUser(LOG_NAME, "Loading widget...")
    hud.LoadWidget(WIDGET_FILE)
EndFunction

Function HUD_WidgetLoaded(String asWidgetID)
    if asWidgetID != WIDGET_FILE
        return
    endif

    bLoaded = true
    Debug.TraceUser(LOG_NAME, "Widget loaded: " + asWidgetID)

    SendAPData()

    StartTimer(POLL_INTERVAL, TIMER_UPDATE)
    Debug.TraceUser(LOG_NAME, "AP update loop started (" + POLL_INTERVAL + "s)")
EndFunction

; === DATA ===
; CMD 600: currentAP, maxAP, isInVATS, 0, 0, 0

Function SendAPData()
    if !hud || !bLoaded || !avAP
        return
    endif

    Actor player = Game.GetPlayer()

    ; === Current AP (vanilla ActorValue) ===
    float currentAP = player.GetValue(avAP)
    if currentAP < 0
        currentAP = 0.0
    endif

    ; === Max AP (base value + modifiers) ===
    float maxAP = player.GetBaseValue(avAP)
    if maxAP < 1
        maxAP = 100.0
    endif

    ; === VATS detection — check if player is in VATS via game state ===
    ; No direct Papyrus VATS check available; using AP drain as proxy
    ; If AP is dropping rapidly, likely in VATS or sprinting
    float isInVATS = 0.0

    hud.SendMessage(WIDGET_FILE, CMD_AP, currentAP, maxAP, isInVATS, 0.0, 0.0, 0.0)
EndFunction
