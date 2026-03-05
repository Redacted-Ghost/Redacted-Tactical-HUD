Scriptname LoreOutRads_QuestScript extends Quest
{ Redacted Tactical HUD — Rads Counter Widget controller.
  Displays accumulated radiation as a counter + fill bar.
  Uses vanilla ActorValue for rads, Lighthouse for rad damage detection.

  CMD 400 (float): rads, maxRads, isTakingRads, radRate }

; Log name
String LOG_NAME = "LoreOutRads" Const

; Command ID
Int Property CMD_RADS = 400 Auto Const

; Widget SWF filename
String Property WIDGET_FILE = "LoreOutRadsWidget.swf" Auto Const

; Timer IDs
Int TIMER_REGISTER = 0 Const
Int TIMER_UPDATE = 1 Const

; Position: bottom-left. v12: 160x160 ring scanner → (20, 540)
Float Property WIDGET_X = 20.0 Auto Const
Float Property WIDGET_Y = 540.0 Auto Const

; Poll interval
Float POLL_INTERVAL = 0.5 Const

; Max rads constant (FO4 default = 1000)
Float MAX_RADS = 1000.0 Const

; State
HUDFramework hud
Bool bRegistered = false
Bool bLoaded = false
Float fLastRads = -1.0

; ActorValue forms (resolved at runtime)
ActorValue avRads

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
    fLastRads = -1.0
    ResolveActorValues()
    StartTimer(4.0, TIMER_REGISTER)
EndEvent

Function ResolveActorValues()
    ; Rads ActorValue: Fallout4.esm FormID 0x000002E1
    avRads = Game.GetForm(0x000002E1) as ActorValue
    if avRads
        Debug.TraceUser(LOG_NAME, "Rads AV resolved OK")
    else
        Debug.TraceUser(LOG_NAME, "WARNING: Rads AV not found!")
    endif
EndFunction

Event OnTimer(Int aiTimerID)
    if aiTimerID == TIMER_REGISTER
        AttemptRegister()
    elseif aiTimerID == TIMER_UPDATE
        SendRadsData()
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

    SendRadsData()

    StartTimer(POLL_INTERVAL, TIMER_UPDATE)
    Debug.TraceUser(LOG_NAME, "Rads update loop started (" + POLL_INTERVAL + "s)")
EndFunction

; === DATA ===
; CMD 400: rads, maxRads, isTakingRads, radRate

Function SendRadsData()
    if !hud || !bLoaded || !avRads
        return
    endif

    Actor player = Game.GetPlayer()

    ; === Current rads (vanilla ActorValue) ===
    float rads = player.GetValue(avRads)
    if rads < 0
        rads = 0.0
    endif

    ; === Rad rate estimate (change since last poll) ===
    float radRate = 0.0
    if fLastRads >= 0
        radRate = rads - fLastRads
    endif
    fLastRads = rads

    ; === Taking rad damage (Lighthouse) ===
    float isTakingRads = 0.0
    if Lighthouse.IsTakingRadDamage(player)
        isTakingRads = 1.0
    endif

    hud.SendMessage(WIDGET_FILE, CMD_RADS, rads, MAX_RADS, isTakingRads, radRate, 0.0, 0.0)
EndFunction
