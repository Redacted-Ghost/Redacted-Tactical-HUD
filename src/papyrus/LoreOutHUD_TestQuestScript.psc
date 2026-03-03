Scriptname LoreOutHUD_TestQuestScript extends Quest

; Command IDs — must match AS3 widget expectations
; SendMessage signature: (String widgetID, Int command, Float arg1..arg6)
Int Property CMD_SET_TEXT = 100 Auto Const
Int Property CMD_SET_COUNTER = 101 Auto Const

; Widget filename (must match SWF in Interface/)
String Property WIDGET_FILE = "LoreOutTestWidget.swf" Auto Const

HUDFramework hud
Int counter = 0

Event OnInit()
    hud = HUDFramework.GetInstance()
    if hud == None
        Debug.Trace("[LoreOutHUD] ERROR: HUDFramework not loaded.")
        return
    endif

    Debug.Trace("[LoreOutHUD] Registering widget: " + WIDGET_FILE)
    ; RegisterWidget(ScriptObject owner, String swf, Float x, Float y, Bool loadNow, Bool autoLoad)
    hud.RegisterWidget(Self as ScriptObject, WIDGET_FILE, 30.0, 30.0, True, True)
EndEvent

Function HUD_WidgetLoaded(String asWidgetID)
    if asWidgetID != WIDGET_FILE
        return
    endif

    Debug.Trace("[LoreOutHUD] Widget loaded: " + asWidgetID)

    ; CMD_SET_TEXT (100): tells widget to show "loaded" state
    ; SendMessage only passes Floats, so the AS3 side handles the text
    hud.SendMessage(WIDGET_FILE, CMD_SET_TEXT, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)

    ; Start counter test — fires every second
    StartTimer(1.0, 1)
EndFunction

Event OnTimer(Int aiTimerID)
    if aiTimerID != 1
        return
    endif

    counter += 1
    ; CMD_SET_COUNTER (101): arg1 = counter value
    hud.SendMessage(WIDGET_FILE, CMD_SET_COUNTER, counter as Float, 0.0, 0.0, 0.0, 0.0, 0.0)

    ; Continue the loop
    StartTimer(1.0, 1)
EndEvent
