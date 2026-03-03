Scriptname LoreOutCombat_QuestScript extends Quest
{ LoreOut Combat Widget controller.
  Registers LoreOutCombatWidget.swf with HUDFramework and sends
  LIVE ammo/weapon/threat data via Lighthouse Papyrus Extender.

  CMD 200 (float): magCur, magCap, reserve, spareMags, threat, hostiles
  CMD 201 (string): weapon name
  CMD 202 (string): ammo type name

  Uses GhostHUD-grade lifecycle: delayed init, retry, OnPlayerLoadGame.
  OnCombatStateChanged provides instant threat updates (no poll delay). }

; Log name — writes to Logs/Script/User/LoreOutCombat.0.log
String LOG_NAME = "LoreOutCombat" Const

; Command IDs — match AS3 constants
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

; Background poll interval (for ammo data that has no event)
Float POLL_INTERVAL = 0.5 Const

; State
HUDFramework hud
Bool bRegistered = false
Bool bLoaded = false
String sLastWeaponName = ""

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
    sLastWeaponName = ""
    RegisterForRemoteEvent(Game.GetPlayer(), "OnCombatStateChanged")
    StartTimer(4.0, TIMER_REGISTER)
EndEvent

; Instant threat state update — fires immediately on combat state change
Event Actor.OnCombatStateChanged(Actor akSender, Actor akTarget, int aeCombatState)
    if bLoaded
        Debug.TraceUser(LOG_NAME, "Combat state changed: " + aeCombatState)
        SendCombatData()
    endif
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

    ; Send initial data immediately
    SendCombatData()

    ; Start background poll for ammo data (no event for ammo changes)
    StartTimer(POLL_INTERVAL, TIMER_UPDATE)
    Debug.TraceUser(LOG_NAME, "Update loop started (" + POLL_INTERVAL + "s)")
EndFunction

; === DATA ===
; All numeric data via Lighthouse Papyrus Extender (validated by probe)
; String data (weapon/ammo names) via SendMessageString

Function SendCombatData()
    if !hud || !bLoaded
        return
    endif

    Actor player = Game.GetPlayer()

    ; === Magazine data (Lighthouse — validated: tracks live!) ===
    float magCur = Lighthouse.GetWeaponAmmoCount(player)
    float magCap = Lighthouse.GetWeaponAmmoCapacity(player)

    ; === Reserve ammo (inventory count) ===
    float reserve = 0.0
    Ammo ammoType = Lighthouse.GetWeaponAmmoType(player)
    if ammoType
        reserve = player.GetItemCount(ammoType as Form)
    endif

    ; === Spare magazines (Lighthouse) ===
    float spareMags = Lighthouse.GetWeaponMagCount(player, true)

    ; === Threat state (vanilla + Lighthouse) ===
    float threat = 0.0
    if player.IsInCombat()
        threat = 2.0
    elseif player.IsSneaking()
        threat = 1.0
    endif

    ; === Hostile count (Lighthouse — lightweight bool check first) ===
    float hostileCount = 0.0
    if Lighthouse.AreHostileActorsInRange(player, 3000)
        Actor[] hostiles = Lighthouse.GetActorsHostileToActor(player, 3000, false)
        if hostiles
            hostileCount = hostiles.Length
        endif
    endif

    ; Send numeric data (6 floats via CMD 200)
    hud.SendMessage(WIDGET_FILE, CMD_COMBAT_UPDATE, magCur, magCap, reserve, spareMags, threat, hostileCount)

    ; === Weapon name (string — only send when weapon changes) ===
    String weapName = ""
    Weapon equippedWeapon = player.GetEquippedWeapon(0)
    if equippedWeapon
        weapName = equippedWeapon.GetName()
    endif

    if weapName != sLastWeaponName
        sLastWeaponName = weapName
        hud.SendMessageString(WIDGET_FILE, "201", weapName, false, false)

        ; Also send ammo type when weapon changes
        if ammoType
            hud.SendMessageString(WIDGET_FILE, "202", ammoType.GetName(), false, false)
        else
            hud.SendMessageString(WIDGET_FILE, "202", "", false, false)
        endif

        Debug.TraceUser(LOG_NAME, "Weapon changed: " + weapName)
    endif
EndFunction
