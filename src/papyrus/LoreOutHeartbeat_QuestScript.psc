Scriptname LoreOutHeartbeat_QuestScript extends Quest
{ Redacted Tactical HUD — Heartbeat ECG Widget controller.
  Sends HP/rads/healing/damage data to the scrolling ECG waveform widget.
  Uses Lighthouse for damage detection, vanilla ActorValues for HP/rads.

  CMD 300 (float): hpPercent, radPercent, isHealing, isTakingDmg }

; Log name
String LOG_NAME = "LoreOutHeartbeat" Const

; Command ID
Int Property CMD_HEARTBEAT = 300 Auto Const

; Widget SWF filename
String Property WIDGET_FILE = "LoreOutHeartbeatWidget.swf" Auto Const

; Timer IDs
Int TIMER_REGISTER = 0 Const
Int TIMER_UPDATE = 1 Const

; Position: left-side stack middle. v11: 300x70 → (16, 524)
; Vitals(524)+70=594, 8px gap → Rads at 602
Float Property WIDGET_X = 16.0 Auto Const
Float Property WIDGET_Y = 524.0 Auto Const

; Poll interval (faster for responsive ECG)
Float POLL_INTERVAL = 0.25 Const

; State
HUDFramework hud
Bool bRegistered = false
Bool bLoaded = false
Float fLastHP = -1.0

; ActorValue forms (resolved at runtime from Fallout4.esm FormIDs)
ActorValue avHealth

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
    fLastHP = -1.0
    ResolveActorValues()
    StartTimer(4.0, TIMER_REGISTER)
EndEvent

Function ResolveActorValues()
    ; Health ActorValue: Fallout4.esm FormID 0x000002D4
    avHealth = Game.GetForm(0x000002D4) as ActorValue
    if avHealth
        Debug.TraceUser(LOG_NAME, "Health AV resolved OK")
    else
        Debug.TraceUser(LOG_NAME, "WARNING: Health AV not found!")
    endif
EndFunction

Event OnTimer(Int aiTimerID)
    if aiTimerID == TIMER_REGISTER
        AttemptRegister()
    elseif aiTimerID == TIMER_UPDATE
        SendHeartbeatData()
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

    SendHeartbeatData()

    StartTimer(POLL_INTERVAL, TIMER_UPDATE)
    Debug.TraceUser(LOG_NAME, "Heartbeat update loop started (" + POLL_INTERVAL + "s)")
EndFunction

; === DATA ===
; CMD 300: hpPercent, radPercent, isHealing, isTakingDmg

Function SendHeartbeatData()
    if !hud || !bLoaded || !avHealth
        return
    endif

    Actor player = Game.GetPlayer()

    ; === HP Percentage (vanilla ActorValue via resolved form) ===
    float maxHP = player.GetBaseValue(avHealth)
    float curHP = player.GetValue(avHealth)
    float hpPct = 0.0
    if maxHP > 0
        hpPct = (curHP / maxHP) * 100.0
    endif
    if hpPct < 0
        hpPct = 0.0
    endif
    if hpPct > 100
        hpPct = 100.0
    endif

    ; === Rads: use Lighthouse for rad damage detection ===
    ; Rad percentage = proportion of HP bar consumed by rads
    ; In FO4, rads reduce effective max HP. We approximate via:
    ; radPct = ((baseHP - effectiveMaxHP) / baseHP) * 100
    ; But GetValue already returns post-rad HP, so we use the flag approach
    float radPct = 0.0
    if Lighthouse.IsTakingRadDamage(player)
        radPct = 25.0  ; flag for visual noise in ECG
    endif

    ; === Healing detection (HP went up since last poll) ===
    float isHealing = 0.0
    if fLastHP >= 0 && curHP > fLastHP
        isHealing = 1.0
    endif

    ; === Damage detection (Lighthouse) ===
    float isTakingDmg = 0.0
    if Lighthouse.IsTakingHealthDamage(player)
        isTakingDmg = 1.0
    endif

    fLastHP = curHP

    hud.SendMessage(WIDGET_FILE, CMD_HEARTBEAT, hpPct, radPct, isHealing, isTakingDmg, 0.0, 0.0)
EndFunction
