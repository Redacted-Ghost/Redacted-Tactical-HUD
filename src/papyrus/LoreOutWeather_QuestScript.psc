Scriptname LoreOutWeather_QuestScript extends Quest
{ LoreOut Weather Widget controller.
  Shows current weather, day/night, precipitation warnings, gas mask alert.
  Uses vanilla Weather API + Lighthouse for hazard detection.
  Ties into Damn Apocalypse / Gas Masks 2287 for gas mask warnings.

  CMD 500 (float): weatherClass, dayNight, hour, isHazardous, needsGasMask, 0
  CMD 501 (string): weather name
  CMD 502 (string): location name
  CMD 503 (string): date string }

; Log name
String LOG_NAME = "LoreOutWeather" Const

; Command IDs
Int Property CMD_WEATHER_UPDATE = 500 Auto Const
Int Property CMD_WEATHER_NAME = 501 Auto Const
Int Property CMD_LOCATION = 502 Auto Const
Int Property CMD_DATE = 503 Auto Const

; Widget SWF filename
String Property WIDGET_FILE = "LoreOutWeatherWidget.swf" Auto Const

; Timer IDs
Int TIMER_REGISTER = 0 Const
Int TIMER_UPDATE = 1 Const

; Position: V9 under minimap (top-right area). 200x65 → (1050, 250)
Float Property WIDGET_X = 1050.0 Auto Const
Float Property WIDGET_Y = 250.0 Auto Const

; Poll interval (weather changes slowly)
Float POLL_INTERVAL = 5.0 Const

; State
HUDFramework hud
Bool bRegistered = false
Bool bLoaded = false
Int iLastWeather = -1
Int iLastDayNight = -1
String sLastLocation = ""
String sLastDate = ""

; === LIFECYCLE ===

Event OnInit()
    Debug.OpenUserLog(LOG_NAME)
    Debug.TraceUser(LOG_NAME, "=== OnInit ===")
    Actor player = Game.GetPlayer()
    RegisterForRemoteEvent(player, "OnPlayerLoadGame")
    StartTimer(4.0, TIMER_REGISTER)
EndEvent

Event Actor.OnPlayerLoadGame(Actor akSender)
    Debug.OpenUserLog(LOG_NAME)
    Debug.TraceUser(LOG_NAME, "=== OnPlayerLoadGame ===")
    bLoaded = false
    bRegistered = false
    iLastWeather = -1
    iLastDayNight = -1
    sLastLocation = ""
    sLastDate = ""
    StartTimer(4.0, TIMER_REGISTER)
EndEvent

Event OnTimer(Int aiTimerID)
    if aiTimerID == TIMER_REGISTER
        AttemptRegister()
    elseif aiTimerID == TIMER_UPDATE
        SendWeatherData()
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

    SendWeatherData()

    StartTimer(POLL_INTERVAL, TIMER_UPDATE)
    Debug.TraceUser(LOG_NAME, "Weather update loop started (" + POLL_INTERVAL + "s)")
EndFunction

; === DATA ===
; CMD 500: weatherClass, dayNight, hour, isHazardous, needsGasMask, 0

Function SendWeatherData()
    if !hud || !bLoaded
        return
    endif

    Actor player = Game.GetPlayer()

    ; === GAME TIME ===
    float fGameTime = Utility.GetCurrentGameTime()
    float fDayFraction = fGameTime - Math.Floor(fGameTime) as float
    float fHour = fDayFraction * 24.0
    int iHour = fHour as int

    ; === DAY/NIGHT STATE ===
    ; 0=Day, 1=Dawn, 2=Dusk, 3=Night
    int iDayNight = 0
    if iHour >= 5 && iHour < 7
        iDayNight = 1
    elseif iHour >= 18 && iHour < 20
        iDayNight = 2
    elseif iHour >= 20 || iHour < 5
        iDayNight = 3
    endif

    ; === WEATHER ===
    int iWeatherClass = 0
    Weather kCurrent = Weather.GetCurrentWeather()
    if kCurrent
        iWeatherClass = kCurrent.GetClassification()
    endif

    ; === HAZARD DETECTION (Lighthouse) ===
    float fIsHazardous = 0.0
    if Lighthouse.IsTakingRadDamage(player)
        fIsHazardous = 1.0
    endif

    ; === GAS MASK NEEDED ===
    ; Precipitation weather (rain/snow) + any hazardous condition = equip gas mask
    float fNeedsGasMask = 0.0
    if (iWeatherClass == 2 || iWeatherClass == 3) && fIsHazardous > 0
        fNeedsGasMask = 1.0
    endif

    ; Send numeric data
    hud.SendMessage(WIDGET_FILE, CMD_WEATHER_UPDATE, iWeatherClass as float, iDayNight as float, fHour, fIsHazardous, fNeedsGasMask, 0.0)

    ; === WEATHER NAME (string, only on change) ===
    if iWeatherClass != iLastWeather
        iLastWeather = iWeatherClass
        string sName = "Clear"
        if iWeatherClass == 1
            sName = "Cloudy"
        elseif iWeatherClass == 2
            sName = "Rain"
        elseif iWeatherClass == 3
            sName = "Snow"
        endif

        ; Try Lighthouse for detailed precipitation type
        if kCurrent && iWeatherClass >= 2
            string sPrecip = Lighthouse.GetPrecipitationType(kCurrent)
            if sPrecip != ""
                sName = sPrecip
            endif
        endif

        hud.SendMessageString(WIDGET_FILE, CMD_WEATHER_NAME as string, sName, True, False)
        Debug.TraceUser(LOG_NAME, "Weather: " + sName + " (class " + iWeatherClass + ")")
    endif

    ; === LOCATION (string, only on change) ===
    Location kLoc = player.GetCurrentLocation()
    string sLoc = "The Commonwealth"
    if kLoc
        string sLocName = kLoc.GetName()
        if sLocName != ""
            sLoc = sLocName
        endif
    endif

    if sLoc != sLastLocation
        sLastLocation = sLoc
        hud.SendMessageString(WIDGET_FILE, CMD_LOCATION as string, sLoc, True, False)
    endif

    ; === DATE (string, only on change) ===
    string sDate = CalcGameDate(fGameTime)
    if sDate != sLastDate
        sLastDate = sDate
        hud.SendMessageString(WIDGET_FILE, CMD_DATE as string, sDate, True, False)
    endif
EndFunction

; === DATE CALCULATION (same as GhostHUD) ===

String Function CalcGameDate(float fGameTime)
    int iElapsed = Math.Floor(fGameTime)
    int iDay = 23 + iElapsed
    int iMonth = 10
    int iYear = 2287
    int iDaysThisMonth = GetDaysInMonth(iMonth)

    while iDay > iDaysThisMonth
        iDay -= iDaysThisMonth
        iMonth += 1
        if iMonth > 12
            iMonth = 1
            iYear += 1
        endif
        iDaysThisMonth = GetDaysInMonth(iMonth)
    endwhile

    string sMon = "" + iMonth as string
    if iMonth < 10
        sMon = "0" + iMonth as string
    endif
    string sDay = "" + iDay as string
    if iDay < 10
        sDay = "0" + iDay as string
    endif
    return sMon + "." + sDay + "." + iYear as string
EndFunction

Int Function GetDaysInMonth(int iMonth)
    if iMonth == 1 || iMonth == 3 || iMonth == 5 || iMonth == 7 || iMonth == 8 || iMonth == 10 || iMonth == 12
        return 31
    elseif iMonth == 4 || iMonth == 6 || iMonth == 9 || iMonth == 11
        return 30
    elseif iMonth == 2
        return 28
    endif
    return 30
EndFunction
