Scriptname LoreOutStatus_QuestScript extends Quest
{ Redacted Tactical HUD — Status Widget controller.
  Animated eye icon + cycling awareness messages + weather/time/location.
  Sends LIVE threat/detection/hostile data via Lighthouse.

  CMD 100 (float): threat, hostileCount, isDetected
  CMD 101 (string): time + weather (e.g. "7:58 PM CLEAR")
  CMD 102 (string): location name
  Eye states: 0=CLOSED (calm), 1=SCANNING (sneak), 2=OPEN (combat) }

; Log name
String LOG_NAME = "LoreOutStatus" Const

; Command IDs — match AS3 constants
Int Property CMD_STATUS_UPDATE = 100 Auto Const
Int Property CMD_WEATHER_TIME = 101 Auto Const
Int Property CMD_LOCATION = 102 Auto Const

; Widget SWF filename
String Property WIDGET_FILE = "LoreOutStatusWidget.swf" Auto Const

; Timer IDs
Int TIMER_REGISTER = 0 Const
Int TIMER_UPDATE = 1 Const
Int TIMER_WEATHER = 2 Const

; Position: right-side above combat. v12: 300x70 → (964, 502)
Float Property WIDGET_X = 964.0 Auto Const
Float Property WIDGET_Y = 502.0 Auto Const

; Poll intervals
Float POLL_INTERVAL = 0.5 Const
Float WEATHER_INTERVAL = 5.0 Const

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

; Instant update on combat state change (no poll delay)
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
    elseif aiTimerID == TIMER_WEATHER
        SendWeatherData()
        StartTimer(WEATHER_INTERVAL, TIMER_WEATHER)
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

    SendStatusData()
    SendWeatherData()

    StartTimer(POLL_INTERVAL, TIMER_UPDATE)
    StartTimer(WEATHER_INTERVAL, TIMER_WEATHER)
    Debug.TraceUser(LOG_NAME, "Status + weather loops started")
EndFunction

; === DATA ===
; CMD 100: threat(0/1/2), hostileCount, isDetected(0/1)

Function SendStatusData()
    if !hud || !bLoaded
        return
    endif

    Actor player = Game.GetPlayer()

    ; === Threat state ===
    float threat = 0.0
    if player.IsInCombat()
        threat = 2.0
    elseif player.IsSneaking()
        threat = 1.0
    endif

    ; === Hostile count (Lighthouse — bool check first for perf) ===
    float hostileCount = 0.0
    if Lighthouse.AreHostileActorsInRange(player, 3000)
        Actor[] hostiles = Lighthouse.GetActorsHostileToActor(player, 3000, false)
        if hostiles
            hostileCount = hostiles.Length
        endif
    endif

    ; === Detection state (Lighthouse) ===
    float isDetected = 0.0
    if Lighthouse.IsPlayerDetectedByHostile()
        isDetected = 1.0
    endif

    hud.SendMessage(WIDGET_FILE, CMD_STATUS_UPDATE, threat, hostileCount, isDetected, 0.0, 0.0, 0.0)
EndFunction

; CMD 101: time + weather string
; CMD 102: location name string

Function SendWeatherData()
    if !hud || !bLoaded
        return
    endif

    ; === Game time ===
    float gameTime = Utility.GetCurrentGameTime()
    float dayFraction = gameTime - Math.Floor(gameTime)
    int totalMinutes = (dayFraction * 1440) as Int
    int hours24 = totalMinutes / 60
    int minutes = totalMinutes % 60

    ; Convert to 12hr format
    String ampm = "AM"
    int hours12 = hours24
    if hours24 >= 12
        ampm = "PM"
        if hours24 > 12
            hours12 = hours24 - 12
        endif
    endif
    if hours12 == 0
        hours12 = 12
    endif

    String minStr = minutes as String
    if minutes < 10
        minStr = "0" + minStr
    endif
    String timeStr = hours12 + ":" + minStr + " " + ampm

    ; === Weather ===
    Weather currentWeather = Weather.GetCurrentWeather()
    String weatherStr = "CLEAR"
    if currentWeather
        ; Use classification flags to determine weather type
        int classFlags = currentWeather.GetClassification()
        ; 0=Pleasant, 1=Cloudy, 2=Rainy, 3=Snow
        if classFlags == 3
            weatherStr = "SNOW"
        elseif classFlags == 2
            weatherStr = "RAIN"
        elseif classFlags == 1
            weatherStr = "CLOUDY"
        else
            weatherStr = "CLEAR"
        endif
    endif

    hud.SendMessageString(WIDGET_FILE, CMD_WEATHER_TIME as String, timeStr + "  " + weatherStr, true, false)

    ; === Location ===
    Location playerLoc = Game.GetPlayer().GetCurrentLocation()
    if playerLoc
        String locName = playerLoc.GetName()
        if locName != ""
            hud.SendMessageString(WIDGET_FILE, CMD_LOCATION as String, locName, true, false)
        endif
    endif
EndFunction
