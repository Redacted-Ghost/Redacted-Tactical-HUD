package loreout.widgets {
    import flash.display.MovieClip;
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.utils.Timer;
    import flash.events.TimerEvent;
    import flash.events.Event;
    import flash.filters.GlowFilter;
    import hudframework.IHUDWidget;
    import loreout.ui.UIPrimitives;

    /**
     * LoreOut Status Widget v11 — Tactical panel surveillance module.
     *
     * 200x48 with chamfered tactical panel, amber accent,
     * animated iris eye, dual rotating rings, signal bars,
     * sun/moon icon with glow, two text rows.
     * Panel outline shifts with threat state.
     *
     * CMD 100 (floats): threat, hostileCount, isDetected
     * CMD 101 (string): time + weather (e.g. "7:58 PM CLEAR")
     * CMD 102 (string): location name (e.g. "SANCTUARY HILLS")
     */
    public class LoreOutStatusWidget extends MovieClip implements IHUDWidget {

        // ---- COMMANDS ----
        private static const CMD_STATUS_UPDATE:int = 100;
        private static const CMD_WEATHER_TIME:int = 101;
        private static const CMD_LOCATION:int = 102;

        // ---- LAYOUT ----
        private static const PANEL_W:int = 300;
        private static const PANEL_H:int = 54;

        // ---- EYE GEOMETRY (centered in 54px) ----
        private static const EYE_CX:Number = 28;
        private static const EYE_CY:Number = 27;
        private static const EYE_SIZE:Number = 20;
        private static const EYE_HW:Number = EYE_SIZE * 0.5;
        private static const EYE_HH:Number = EYE_SIZE * 0.28;

        // ---- ANIMATION ----
        private static const SCAN_SPEED:Number = 0.04;
        private static const SCAN_RANGE:Number = 3.0;
        private static const OPEN_SPEED:Number = 0.08;
        private static const RING_SPEED:Number = 0.015;

        // ---- MESSAGE POOLS ----
        private static const MSG_CALM:Array = ["SECTOR CLEAR", "NO CONTACTS", "SAFE"];
        private static const MSG_STEALTH:Array = ["CONCEALED", "UNDETECTED", "GHOST ACTIVE"];
        private static const MSG_COMBAT:Array = ["HOSTILE CONTACT", "ENGAGING", "DANGER"];
        private static const CYCLE_MS:int = 3000;

        // ---- ELEMENTS ----
        private var cyberParts:Object;
        private var panelShape:Shape;
        private var eyeContainer:Sprite;
        private var ringContainer:Sprite;
        private var outerRingContainer:Sprite;
        private var signalBars:Sprite;
        private var statusText:TextField;
        private var weatherText:TextField;
        private var sunMoonIcon:Shape;

        // ---- ANIMATION STATE ----
        private var currentThreat:int = 0;
        private var targetOpenness:Number = 0;
        private var currentOpenness:Number = 0;
        private var scanPhase:Number = 0;
        private var irisOffsetX:Number = 0;
        private var eyeColor:uint = UIPrimitives.COL_AMBER;
        private var frameCount:int = 0;
        private var ringAngle:Number = 0;
        private var outerRingAngle:Number = 0;

        // blink
        private var blinkTimer:int = 0;
        private var isBlinking:Boolean = false;
        private var blinkProgress:Number = 0;

        // cycling
        private var msgIndex:int = 0;
        private var cycleTimer:Timer;

        // data
        private var hostileCount:int = 0;
        private var isDetected:Boolean = false;
        private var weatherTimeStr:String = "";
        private var locationStr:String = "";
        private var isDaytime:Boolean = true;

        public function LoreOutStatusWidget() {
            super();
            buildUI();
            setThreatState(0, 0, false);
            startCycling();
            addEventListener(Event.ENTER_FRAME, onFrame);
        }

        // ================================================================
        // BUILD UI
        // ================================================================
        private function buildUI():void {
            // === CYBER PANEL (no header — eye is focal point) ===
            cyberParts = UIPrimitives.buildCyberPanel(this, PANEL_W, PANEL_H,
                UIPrimitives.COL_AMBER, "medium", false, "", "SRV-01");
            panelShape = cyberParts.panel as Shape;

            // Divider between text rows (inside content area, 1px bold)
            UIPrimitives.drawDividerLine(this, 52, 27, PANEL_W - 104,
                UIPrimitives.COL_BORDER, 0.40, 1.0, true, 1.0);

            // Outer rotating ring (counter-rotates, 2 segments)
            outerRingContainer = new Sprite();
            addChild(outerRingContainer);

            // Inner rotating ring container (around eye, 4 segments)
            ringContainer = new Sprite();
            addChild(ringContainer);

            // Eye container (animated iris)
            eyeContainer = new Sprite();
            addChild(eyeContainer);

            // Row 1: Status text (threat message)
            var fmt1:TextFormat = new TextFormat();
            fmt1.font = UIPrimitives.FONT;
            fmt1.size = 11;
            fmt1.color = UIPrimitives.COL_AMBER;
            fmt1.letterSpacing = 1;

            statusText = new TextField();
            statusText.defaultTextFormat = fmt1;
            statusText.textColor = UIPrimitives.COL_AMBER;
            statusText.alpha = 0.90;
            statusText.selectable = false;
            statusText.mouseEnabled = false;
            statusText.x = 52;
            statusText.y = 7;
            statusText.width = PANEL_W - 104;
            statusText.height = 20;
            statusText.text = "SECTOR CLEAR";
            statusText.filters = [UIPrimitives.TEXT_SHADOW];
            addChild(statusText);

            // Row 2: Weather/time text (cycling with location)
            var fmt2:TextFormat = new TextFormat();
            fmt2.font = UIPrimitives.FONT;
            fmt2.size = 8;
            fmt2.color = UIPrimitives.COL_TEXT_SEC;
            fmt2.letterSpacing = 0.5;

            weatherText = new TextField();
            weatherText.defaultTextFormat = fmt2;
            weatherText.textColor = UIPrimitives.COL_TEXT_SEC;
            weatherText.alpha = 0.65;
            weatherText.selectable = false;
            weatherText.mouseEnabled = false;
            weatherText.x = 52;
            weatherText.y = 30;
            weatherText.width = PANEL_W - 104;
            weatherText.height = 14;
            weatherText.text = "";
            weatherText.filters = [UIPrimitives.TEXT_SHADOW];
            addChild(weatherText);

            // Signal bars (right side, top)
            signalBars = UIPrimitives.drawSignalBars(this,
                PANEL_W - 28, 12, 0, 4, UIPrimitives.COL_AMBER, 0.75);

            // Sun/moon icon (right side, below signal bars) — GLOWS
            sunMoonIcon = UIPrimitives.drawSunIcon(this,
                PANEL_W - 22, 40, 7, UIPrimitives.COL_AMBER, 0.85);
            UIPrimitives.applyNeonGlow(sunMoonIcon, UIPrimitives.COL_AMBER, 0.3);
        }

        // ================================================================
        // ENTER_FRAME
        // ================================================================
        private function onFrame(e:Event):void {
            frameCount++;

            // Eye openness
            currentOpenness += (targetOpenness - currentOpenness) * OPEN_SPEED;

            // Iris scanning (stealth)
            if (currentThreat == 1) {
                scanPhase += SCAN_SPEED;
                irisOffsetX = Math.sin(scanPhase) * SCAN_RANGE;
            } else {
                irisOffsetX *= 0.9;
                if (Math.abs(irisOffsetX) < 0.1) irisOffsetX = 0;
            }

            // Blinking (combat)
            if (currentThreat == 2) {
                blinkTimer++;
                if (blinkTimer > 120 && !isBlinking) {
                    isBlinking = true;
                    blinkProgress = 0;
                }
                if (isBlinking) {
                    blinkProgress += 0.15;
                    if (blinkProgress >= 1.0) {
                        isBlinking = false;
                        blinkTimer = 0;
                    }
                }
            } else {
                blinkTimer = 0;
                isBlinking = false;
                blinkProgress = 0;
            }

            // Ring rotation speed
            if (currentThreat == 2) {
                ringAngle += RING_SPEED * 3;
                outerRingAngle -= RING_SPEED * 2;
            } else if (currentThreat == 1) {
                ringAngle += RING_SPEED;
                outerRingAngle -= RING_SPEED * 0.7;
            } else {
                ringAngle += RING_SPEED * 0.3;
                outerRingAngle -= RING_SPEED * 0.15;
            }

            drawEye();
            drawRing();
            drawOuterRing();
        }

        // ================================================================
        // DRAW EYE
        // ================================================================
        private function drawEye():void {
            var g:* = eyeContainer.graphics;
            g.clear();

            var cx:Number = EYE_CX;
            var cy:Number = EYE_CY;
            var hw:Number = EYE_HW;
            var hh:Number = EYE_HH;

            var openness:Number = currentOpenness;
            if (isBlinking) {
                openness *= (1.0 - Math.sin(blinkProgress * Math.PI) * 0.9);
            }

            var lidHeight:Number = hh * 2.2 * openness;
            var eyeAlpha:Number = 0.4 + openness * 0.5;

            g.lineStyle(UIPrimitives.W_TERTIARY, eyeColor, eyeAlpha);
            g.moveTo(cx - hw, cy);
            g.curveTo(cx, cy - lidHeight, cx + hw, cy);
            g.moveTo(cx - hw, cy);
            g.curveTo(cx, cy + lidHeight, cx + hw, cy);

            if (openness > 0.15) {
                var irisAlpha:Number = (openness - 0.15) / 0.85 * 0.65;
                var irisRadius:Number = hh * 0.85 * openness;
                var pupilRadius:Number = hh * 0.35 * openness;
                var maxOff:Number = hw * 0.4 * openness;
                var clampOff:Number = irisOffsetX;
                if (clampOff > maxOff) clampOff = maxOff;
                if (clampOff < -maxOff) clampOff = -maxOff;

                g.lineStyle(0);
                g.beginFill(eyeColor, irisAlpha);
                g.drawCircle(cx + clampOff, cy, irisRadius);
                g.endFill();
                g.beginFill(UIPrimitives.COL_BG, 0.95);
                g.drawCircle(cx + clampOff, cy, pupilRadius);
                g.endFill();
            }
        }

        // ================================================================
        // DRAW ROTATING RING (4 segments)
        // ================================================================
        private function drawRing():void {
            var g:* = ringContainer.graphics;
            g.clear();

            var cx:Number = EYE_CX;
            var cy:Number = EYE_CY;
            var radius:Number = 14;
            var segments:int = 4;
            var gapAngle:Number = 0.25;
            var segAngle:Number = (Math.PI * 2 - segments * gapAngle) / segments;
            var ringAlpha:Number = (currentThreat > 0) ? 0.50 : 0.15;

            for (var s:int = 0; s < segments; s++) {
                var startA:Number = ringAngle + s * (segAngle + gapAngle);
                g.lineStyle(UIPrimitives.W_SECONDARY, eyeColor, ringAlpha);
                var steps:int = 12;
                for (var i:int = 0; i <= steps; i++) {
                    var t:Number = i / steps;
                    var a:Number = startA + t * segAngle;
                    var px:Number = cx + Math.cos(a) * radius;
                    var py:Number = cy + Math.sin(a) * radius;
                    if (i == 0) g.moveTo(px, py);
                    else g.lineTo(px, py);
                }
            }
        }

        // ================================================================
        // DRAW OUTER RING (2 segments, counter-rotating)
        // ================================================================
        private function drawOuterRing():void {
            var g:* = outerRingContainer.graphics;
            g.clear();

            var cx:Number = EYE_CX;
            var cy:Number = EYE_CY;
            var radius:Number = 16;
            var segments:int = 2;
            var gapAngle:Number = 0.6;
            var segAngle:Number = (Math.PI * 2 - segments * gapAngle) / segments;
            var ringAlpha:Number = (currentThreat > 0) ? 0.35 : 0.08;

            for (var s:int = 0; s < segments; s++) {
                var startA:Number = outerRingAngle + s * (segAngle + gapAngle);
                g.lineStyle(UIPrimitives.W_TERTIARY, eyeColor, ringAlpha);
                var steps:int = 10;
                for (var i:int = 0; i <= steps; i++) {
                    var t:Number = i / steps;
                    var a:Number = startA + t * segAngle;
                    var px:Number = cx + Math.cos(a) * radius;
                    var py:Number = cy + Math.sin(a) * radius;
                    if (i == 0) g.moveTo(px, py);
                    else g.lineTo(px, py);
                }

                // Tick marks at segment ends
                var endA:Number = startA + segAngle;
                var tickLen:Number = 3;
                g.lineStyle(UIPrimitives.W_TERTIARY, eyeColor, ringAlpha * 1.5);
                g.moveTo(cx + Math.cos(startA) * radius,
                         cy + Math.sin(startA) * radius);
                g.lineTo(cx + Math.cos(startA) * (radius + tickLen),
                         cy + Math.sin(startA) * (radius + tickLen));
                g.moveTo(cx + Math.cos(endA) * radius,
                         cy + Math.sin(endA) * radius);
                g.lineTo(cx + Math.cos(endA) * (radius + tickLen),
                         cy + Math.sin(endA) * (radius + tickLen));
            }
        }

        // ================================================================
        // CYCLING
        // ================================================================
        private function startCycling():void {
            cycleTimer = new Timer(CYCLE_MS);
            cycleTimer.addEventListener(TimerEvent.TIMER, onCycle);
            cycleTimer.start();
        }

        private function onCycle(e:TimerEvent):void {
            var pool:Array = getMessagePool();
            msgIndex = (msgIndex + 1) % pool.length;
            statusText.text = pool[msgIndex];

            // Cycle weather row between time/weather and location
            if (weatherTimeStr.length > 0 || locationStr.length > 0) {
                if (msgIndex % 2 == 0 && weatherTimeStr.length > 0) {
                    weatherText.text = weatherTimeStr;
                } else if (locationStr.length > 0) {
                    weatherText.text = locationStr;
                } else {
                    weatherText.text = weatherTimeStr;
                }
            }
        }

        private function getMessagePool():Array {
            switch (currentThreat) {
                case 2:  return MSG_COMBAT;
                case 1:  return MSG_STEALTH;
                default: return MSG_CALM;
            }
        }

        // ================================================================
        // SUN/MOON ICON — parse time, draw day/night indicator
        // ================================================================
        private function updateSunMoon():void {
            // Remove old icon
            if (sunMoonIcon && sunMoonIcon.parent) {
                sunMoonIcon.parent.removeChild(sunMoonIcon);
            }

            var hour:int = parseHour(weatherTimeStr);
            isDaytime = (hour >= 6 && hour < 18);

            var iconColor:uint = isDaytime ? UIPrimitives.COL_AMBER : UIPrimitives.COL_BLUE;
            if (isDaytime) {
                sunMoonIcon = UIPrimitives.drawSunIcon(this,
                    PANEL_W - 22, 40, 7, iconColor, 0.85);
            } else {
                sunMoonIcon = UIPrimitives.drawMoonIcon(this,
                    PANEL_W - 22, 40, 7, iconColor, 0.85);
            }
            UIPrimitives.applyNeonGlow(sunMoonIcon, iconColor, 0.3);
        }

        private function parseHour(timeStr:String):int {
            if (timeStr.length == 0) return 12;
            var colonIdx:int = timeStr.indexOf(":");
            if (colonIdx <= 0) return 12;
            var hourStr:String = timeStr.substring(0, colonIdx);
            var hour:int = parseInt(hourStr);
            var upper:String = timeStr.toUpperCase();
            var isPM:Boolean = (upper.indexOf("PM") >= 0);
            var isAM:Boolean = (upper.indexOf("AM") >= 0);
            if (isPM && hour < 12) hour += 12;
            if (isAM && hour == 12) hour = 0;
            return hour;
        }

        // ================================================================
        // THREAT STATE
        // ================================================================
        private function setThreatState(threat:int, hostiles:int, detected:Boolean):void {
            var changed:Boolean = (threat != currentThreat);
            currentThreat = threat;
            hostileCount = hostiles;
            isDetected = detected;

            switch (threat) {
                case 2:
                    targetOpenness = 1.0;
                    eyeColor = UIPrimitives.COL_WARN;
                    break;
                case 1:
                    targetOpenness = 0.55;
                    eyeColor = UIPrimitives.COL_ACCENT;
                    break;
                default:
                    targetOpenness = 0.0;
                    eyeColor = UIPrimitives.COL_AMBER;
                    break;
            }

            // Recolor cyber panel (grey frame stays, accent trim shifts)
            UIPrimitives.recolorCyberPanel(cyberParts, eyeColor);

            // Update text colors
            statusText.textColor = eyeColor;
            var tfmt:TextFormat = statusText.defaultTextFormat;
            tfmt.color = eyeColor;
            statusText.defaultTextFormat = tfmt;

            // Eye glow
            if (threat > 0) {
                eyeContainer.filters = [new GlowFilter(eyeColor, 0.5, 8, 8, 1.5, 1)];
            } else {
                eyeContainer.filters = [];
            }

            // Redraw signal bars
            if (signalBars && signalBars.parent) {
                signalBars.parent.removeChild(signalBars);
            }
            var sigLevel:int = (threat == 2) ? 4 : (threat == 1) ? 2 : 0;
            signalBars = UIPrimitives.drawSignalBars(this,
                PANEL_W - 28, 12, sigLevel, 4, eyeColor, 0.75);

            if (changed) {
                msgIndex = 0;
                statusText.text = getMessagePool()[0];
            }
        }

        // ================================================================
        // PROCESS MESSAGE
        // ================================================================
        public function processMessage(command:String, params:Array):void {
            var cmd:int = parseInt(command);
            if (cmd == CMD_STATUS_UPDATE && params && params.length >= 3) {
                setThreatState(int(params[0]), int(params[1]), int(params[2]) > 0);
            } else if (cmd == CMD_WEATHER_TIME && params && params.length >= 1) {
                weatherTimeStr = String(params[0]);
                if (weatherText.text.length == 0) {
                    weatherText.text = weatherTimeStr;
                }
                updateSunMoon();
            } else if (cmd == CMD_LOCATION && params && params.length >= 1) {
                locationStr = String(params[0]);
            }
        }
    }
}
