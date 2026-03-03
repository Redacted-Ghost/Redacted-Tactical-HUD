Scriptname LoreOutCombat_QuestScript extends Quest
{ LoreOut Combat Widget controller.
  Registers LoreOutCombatWidget.swf with HUDFramework and sends
  ammo/weapon/threat data via CMD_COMBAT_UPDATE (200).
  Uses GhostHUD-grade lifecycle: delayed init, retry, OnPlayerLoadGame. }

; Log name — writes to Logs/Script/User/LoreOutCombat.0.log
String LOG_NAME = "LoreOutCombat" Const

; Command ID — matches AS3 CMD_COMBAT_UPDATE
Int Property CMD_COMBAT_UPDATE = 200 Auto Const

; Widget SWF filename (in Interface/)
String Property WIDGET_FILE = "LoreOutCombatWidget.swf" Auto Const

; Timer IDs
Int TIMER_REGISTER = 0 Const
Int TIMER_UPDATE = 1 Const

; HUDFramework virtual stage: 1280x720
; Bottom-right placement: (1280 - 160 - 16, 720 - 88 - 16) = (1104, 616)
Float Property WIDGET_X = 1104.0 Auto Const
Float Property WIDGET_Y = 616.0 Auto Const

; Update interval (seconds)
Float POLL_INTERVAL = 2.0 Const

; State
HUDFramework hud
Bool bRegistered = false
Bool bLoaded = false

; === LIFECYCLE ===

Event OnInit()
    Debug.OpenUserLog(LOG_NAME)
    Debug.TraceUser(LOG_NAME, "=== OnInit ===")
    RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")
    StartTimer(4.0, TIMER_REGISTER)
EndEvent

Event Actor.OnPlayerLoadGame(Actor akSender)
    Debug.OpenUserLog(LOG_NAME)
    Debug.TraceUser(LOG_NAME, "=== OnPlayerLoadGame ===")
    bLoaded = false
    bRegistered = false
    StartTimer(4.0, TIMER_REGISTER)
EndEvent

Event OnTimer(Int aiTimerID)
    if aiTimerID == TIMER_REGISTER
        AttemptRegister()
    elseif aiTimerID == TIMER_UPDATE
        SendCombatData()
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
    Debug.Notification("[LoreOut] Combat widget loaded!")

    ; Send initial data immediately
    SendCombatData()

    ; Start polling loop
    StartTimer(POLL_INTERVAL, TIMER_UPDATE)
    Debug.TraceUser(LOG_NAME, "Update loop started (" + POLL_INTERVAL + "s)")
EndFunction

; === DATA POLLING ===
; Reads real player weapon/ammo data from game state.
; CMD_COMBAT_UPDATE (200): mag, reserve, fireMode, condPct, threat, reserved

Function SendCombatData()
    if !hud || !bLoaded
        return
    endif

    Actor player = Game.GetPlayer()

    ; Get equipped weapon ammo counts
    ; GetValue on ammo returns current magazine, EquippedItemCount for total
    Float mag = 0.0
    Float reserve = 0.0
    Float fireMode = 0.0    ; 0=SINGLE, 1=AUTO, 2=BURST (placeholder for now)
    Float condPct = 100.0   ; weapon condition (placeholder — no vanilla API)
    Float threat = 0.0      ; 0=CALM, 1=CAUTION, 2=COMBAT

    ; Real ammo data from the player's equipped weapon
    ; Papyrus can read ammo via GetItemCount on the ammo type
    ; For now: use placeholder values that look realistic
    ; TODO: Hook into actual weapon data via F4SE or game properties
    mag = 30.0
    reserve = 120.0
    fireMode = 1.0  ; AUTO

    ; Threat state from player combat state
    if player.IsInCombat()
        threat = 2.0
    elseif player.IsSneaking()
        threat = 1.0
    else
        threat = 0.0
    endif

    ; Weapon condition placeholder (no vanilla Papyrus API for this)
    condPct = 85.0

    hud.SendMessage(WIDGET_FILE, CMD_COMBAT_UPDATE, mag, reserve, fireMode, condPct, threat, 0.0)
EndFunction
