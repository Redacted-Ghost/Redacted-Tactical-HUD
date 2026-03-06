Scriptname LoreOutCompass_QuestScript extends Quest
{ Redacted Tactical HUD — Compass Widget controller.
  Military heading tape with hostile bearings + map marker locations.
  Uses vanilla GetAngleZ for heading, Lighthouse for hostiles/markers.

  CMD 500 (float): headingDeg, h1, h2, h3, h4, h5
    headingDeg = player heading in DEGREES (0-360)
    h1-h5 = hostile bearings in degrees (-180 to 180), 999 = empty

  CMD 501 (string): "bearing:name|bearing:name|..." (location markers) }

; Log name
String LOG_NAME = "LoreOutCompass" Const

; Command IDs — match AS3 constants
Int Property CMD_COMPASS = 500 Auto Const
Int Property CMD_LOCATIONS = 501 Auto Const

; Widget SWF filename
String Property WIDGET_FILE = "LoreOutCompassWidget.swf" Auto Const

; Timer IDs
Int TIMER_REGISTER = 0 Const
Int TIMER_UPDATE = 1 Const
Int TIMER_MARKERS = 2 Const

; Position: top-center of screen
; HUDFramework virtual stage: 1280x720
; Center: (1280/2 - 420/2) = 430, top with small pad
Float Property WIDGET_X = 430.0 Auto Const
Float Property WIDGET_Y = 8.0 Auto Const

; Poll intervals
Float POLL_INTERVAL = 0.05 Const       ; heading + hostiles (50ms — fastest reliable Papyrus timer)
Float MARKER_INTERVAL = 3.0 Const      ; location markers (slow — expensive call)

; Detection ranges (int — Lighthouse takes int distances)
Int HOSTILE_RANGE = 3000 Const
Int MARKER_RANGE = 8000 Const           ; map markers visible further out

; State
HUDFramework hud
Bool bRegistered = false
Bool bLoaded = false

; Sentinel for empty hostile slots
Float EMPTY_SLOT = 999.0 Const

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
    StartTimer(4.0, TIMER_REGISTER)
EndEvent

Event OnTimer(Int aiTimerID)
    if aiTimerID == TIMER_REGISTER
        AttemptRegister()
    elseif aiTimerID == TIMER_UPDATE
        SendHeadingData()
        StartTimer(POLL_INTERVAL, TIMER_UPDATE)
    elseif aiTimerID == TIMER_MARKERS
        SendMarkerData()
        StartTimer(MARKER_INTERVAL, TIMER_MARKERS)
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

    SendHeadingData()
    SendMarkerData()

    StartTimer(POLL_INTERVAL, TIMER_UPDATE)
    StartTimer(MARKER_INTERVAL, TIMER_MARKERS)
    Debug.TraceUser(LOG_NAME, "Compass loops started (heading=" + POLL_INTERVAL + "s, markers=" + MARKER_INTERVAL + "s)")
EndFunction

; === DATA: HEADING + HOSTILES ===
; CMD 500: headingDeg (0-360), h1, h2, h3, h4, h5
; h1-h5 = relative bearing to hostiles (-180 to 180 degrees), 999 = empty

Function SendHeadingData()
    if !hud || !bLoaded
        return
    endif

    Actor player = Game.GetPlayer()

    ; Player heading in DEGREES — vanilla GetAngleZ()
    ; This is the actor's Z rotation which tracks the camera in first person.
    ; Returns 0-360 degrees. In FO4: 0=South, 90=West, 180=North, 270=East
    ; We need to remap so 0=North: compassDeg = (180 - angleZ + 360) % 360
    ; Actually, FO4 convention may be: 0=N, increases CW. Let's send raw and
    ; handle mapping in AS3 where we can iterate quickly.
    float headingDeg = player.GetAngleZ()

    ; Hostile bearings — up to 5 nearest hostiles
    float h1 = EMPTY_SLOT
    float h2 = EMPTY_SLOT
    float h3 = EMPTY_SLOT
    float h4 = EMPTY_SLOT
    float h5 = EMPTY_SLOT

    if Lighthouse.AreHostileActorsInRange(player, HOSTILE_RANGE)
        Actor[] hostiles = Lighthouse.GetActorsHostileToActor(player, HOSTILE_RANGE, false)
        if hostiles
            int count = hostiles.Length
            if count > 5
                count = 5
            endif

            ; GetHeadingAngle returns -180 to 180 (degrees relative to player facing)
            if count > 0 && hostiles[0]
                h1 = player.GetHeadingAngle(hostiles[0])
            endif
            if count > 1 && hostiles[1]
                h2 = player.GetHeadingAngle(hostiles[1])
            endif
            if count > 2 && hostiles[2]
                h3 = player.GetHeadingAngle(hostiles[2])
            endif
            if count > 3 && hostiles[3]
                h4 = player.GetHeadingAngle(hostiles[3])
            endif
            if count > 4 && hostiles[4]
                h5 = player.GetHeadingAngle(hostiles[4])
            endif
        endif
    endif

    hud.SendMessage(WIDGET_FILE, CMD_COMPASS, headingDeg, h1, h2, h3, h4, h5)
EndFunction

; === DATA: LOCATION MARKERS ===
; CMD 501 (string): "bearing:name|bearing:name|..."
; Only sends nearby discovered map markers within MARKER_RANGE

Function SendMarkerData()
    if !hud || !bLoaded
        return
    endif

    Actor player = Game.GetPlayer()
    ObjectReference[] markers = Lighthouse.GetAllMapMarkers()

    if !markers || markers.Length == 0
        hud.SendMessageString(WIDGET_FILE, "501", "", false, false)
        return
    endif

    String result = ""
    int sent = 0
    int maxMarkers = 8   ; cap to avoid string overflow

    int i = 0
    while i < markers.Length && sent < maxMarkers
        ObjectReference marker = markers[i]
        if marker
            float dist = player.GetDistance(marker)
            if dist <= MARKER_RANGE && dist > 0
                float bearing = player.GetHeadingAngle(marker)
                String markerName = Lighthouse.GetMapMarkerName(marker)
                if markerName != ""
                    if result != ""
                        result += "|"
                    endif
                    result += bearing + ":" + markerName
                    sent += 1
                endif
            endif
        endif
        i += 1
    endwhile

    hud.SendMessageString(WIDGET_FILE, "501", result, false, false)
EndFunction
