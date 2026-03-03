Scriptname LoreOutStatus_QuestScript extends Quest
{ LoreOut Status Widget controller.
  Eye icon + cycling status messages based on stealth/combat state.
  Uses GhostHUD-grade lifecycle: delayed init, retry, OnPlayerLoadGame.
  OnCombatStateChanged provides instant threat updates. }

; Log name — writes to Logs/Script/User/LoreOutStatus.0.log
String LOG_NAME = "LoreOutStatus" Const

; Command ID — matches AS3 CMD_STATUS_UPDATE
Int Property CMD_STATUS_UPDATE = 201 Auto Const

; Widget SWF filename (in Interface/)
String Property WIDGET_FILE = "LoreOutStatusWidget.swf" Auto Const

; Timer IDs
Int TIMER_REGISTER = 0 Const
Int TIMER_UPDATE = 1 Const

; Position: directly above combat widget (1104, 616 - 28 - 4 = 584)
Float Property WIDGET_X = 1104.0 Auto Const
Float Property WIDGET_Y = 584.0 Auto Const

; Background poll interval
Float POLL_INTERVAL = 0.5 Const

; State
HUDFramework hud
Bool bRegistered = false
Bool bLoaded = false

; === LIFECYCLE ===

Event OnInit()
    Debug.OpenUserLog(LOG_NAME)
    Debug.TraceUser(LOG_NAME, "=== OnInit ===")
    Actor player = Game.GetPlayer()
    RegisterForRemoteEvent(player, "OnPlayerLoadGame")
    RegisterForRemoteEvent(player, "OnCombatStateChanged")
    StartTimer(4.0, TIMER_REGISTER)
EndEvent

Event Actor.OnPlayerLoadGame(Actor akSender)
    Debug.OpenUserLog(LOG_NAME)
    Debug.TraceUser(LOG_NAME, "=== OnPlayerLoadGame ===")
    bLoaded = false
    bRegistered = false
    RegisterForRemoteEvent(Game.GetPlayer(), "OnCombatStateChanged")
    StartTimer(4.0, TIMER_REGISTER)
EndEvent

; Instant threat update on combat state change
Event Actor.OnCombatStateChanged(Actor akSender, Actor akTarget, int aeCombatState)
    if bLoaded
        Debug.TraceUser(LOG_NAME, "Combat state changed: " + aeCombatState)
        SendStatusData()
    endif
EndEvent

Event OnTimer(Int aiTimerID)
    if aiTimerID == TIMER_REGISTER
        AttemptRegister()
    elseif aiTimerID == TIMER_UPDATE
        SendStatusData()
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

    ; Send initial state
    SendStatusData()

    ; Start background poll for sneak state (no event for sneak enter/exit)
    StartTimer(POLL_INTERVAL, TIMER_UPDATE)
    Debug.TraceUser(LOG_NAME, "Status update loop started (" + POLL_INTERVAL + "s)")
EndFunction

; === DATA ===
; CMD_STATUS_UPDATE (201): threat state
;   param[0] = threat (0=CALM, 1=STEALTH, 2=COMBAT)

Function SendStatusData()
    if !hud || !bLoaded
        return
    endif

    Actor player = Game.GetPlayer()

    ; Threat state — REAL data from player state
    Float threat = 0.0
    if player.IsInCombat()
        threat = 2.0
    elseif player.IsSneaking()
        threat = 1.0
    endif

    hud.SendMessage(WIDGET_FILE, CMD_STATUS_UPDATE, threat, 0.0, 0.0, 0.0, 0.0, 0.0)
EndFunction
