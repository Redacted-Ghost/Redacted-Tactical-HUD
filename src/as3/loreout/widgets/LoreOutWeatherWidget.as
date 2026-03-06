package loreout.widgets {
    import flash.display.MovieClip;
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    import flash.events.Event;
    import flash.filters.GlowFilter;
    import hudframework.IHUDWidget;
    import loreout.ui.UIPrimitives;

    /**
     * LoreOut Weather Widget — Tactical panel environment module.
     *
     * Shows current weather, day/night cycle, precipitation warnings,
     * gas mask alert (ties into Damn Apocalypse / Gas Masks 2287).
     * Panel is grey-green; elements glow with state colors.
     *
     * CMD 500 (floats): weatherClass, dayNight, hour, isHazardous, needsGasMask, 0
     *   weatherClass: 0=Clear, 1=Cloudy, 2=Rain, 3=Snow
     *   dayNight: 0=Day, 1=Dawn, 2=Dusk, 3=Night
     *   hour: game hour as float (0-24)
     *   isHazardous: 1 if taking rad damage (hazardous environment)
     *   needsGasMask: 1 if precipitation + rad weather (equip gas mask)
     * CMD 501 (string): weather name
     * CMD 502 (string): location name
     * CMD 503 (string): date string
     */
    public class LoreOutWeatherWidget extends MovieClip implements IHUDWidget {

        private static const CMD_WEATHER_UPDATE:int = 500;
        private static const CMD_WEATHER_NAME:int = 501;
        private static const CMD_LOCATION:int = 502;
        private static const CMD_DATE:int = 503;

        private static const PANEL_W:int = 200;
        private static const PANEL_H:int = 65;
        private static const PAD:int = 6;

        // Day/night icon colors
        private static const COL_SUN:uint    = 0xFFE144;
        private static const COL_DAWN:uint   = 0xFFA444;
        private static const COL_DUSK:uint   = 0xCC77B3;
        private static const COL_NIGHT:uint  = 0x6677AA;

        // Elements
        private var cyberParts:Object;
        private var timeField:TextField;
        private var weatherField:TextField;
        private var locationField:TextField;
        private var gasMaskField:TextField;
        private var dayNightIcon:Sprite;
        private var statusDot:Shape;

        // State
        private var weatherClass:int = 0;
        private var dayNight:int = 0;
        private var gameHour:Number = 12;
        private var isHazardous:Boolean = false;
        private var needsGasMask:Boolean = false;
        private var weatherName:String = "CLEAR";
        private var locationName:String = "";
        private var dateStr:String = "";
        private var frameCount:int = 0;

        public function LoreOutWeatherWidget() {
            super();
            buildUI();
            addEventListener(Event.ENTER_FRAME, onFrame);
        }

        // ================================================================
        // BUILD UI
        // ================================================================
        private function buildUI():void {
            // Grey-green panel (V9 uniform)
            cyberParts = UIPrimitives.buildCyberPanel(this, PANEL_W, PANEL_H,
                UIPrimitives.COL_COMBAT_GREY, "medium", false, "", "WTH-01");

            // Day/night icon container (left side)
            dayNightIcon = new Sprite();
            addChild(dayNightIcon);
            drawSunIcon();

            // Status dot (pulsing)
            statusDot = new Shape();
            statusDot.graphics.beginFill(UIPrimitives.COL_ACCENT, 0.9);
            statusDot.graphics.drawCircle(0, 0, 3);
            statusDot.graphics.endFill();
            statusDot.x = PAD + 3;
            statusDot.y = 50;
            addChild(statusDot);

            // Time display (large, top-right of icon)
            timeField = UIPrimitives.makeValue(this, "--:--", 18, 0.95, 0xFFFFFF);
            timeField.x = 34;
            timeField.y = 3;
            timeField.width = 90;
            timeField.filters = [new GlowFilter(COL_SUN, 0.3, 3, 3, 1, 1)];

            // Weather name (below time)
            weatherField = UIPrimitives.makeLabel(this, "CLEAR", 10, 0.80,
                UIPrimitives.COL_ACCENT);
            weatherField.x = 34;
            weatherField.y = 24;
            weatherField.width = PANEL_W - 40;

            // Location (bottom row)
            locationField = UIPrimitives.makeLabel(this, "", 8, 0.55,
                UIPrimitives.COL_TEXT_SEC);
            locationField.x = PAD + 12;
            locationField.y = 46;
            locationField.width = PANEL_W - PAD * 2 - 12;

            // Gas mask warning (overlays bottom, hidden by default)
            gasMaskField = UIPrimitives.makeValue(this, "", 10, 0.95,
                UIPrimitives.COL_WARN);
            gasMaskField.x = PANEL_W - 90;
            gasMaskField.y = 24;
            gasMaskField.width = 84;
            var gfmt:TextFormat = gasMaskField.defaultTextFormat;
            gfmt.align = TextFormatAlign.RIGHT;
            gasMaskField.defaultTextFormat = gfmt;
            gasMaskField.setTextFormat(gfmt);
            gasMaskField.visible = false;
        }

        // ================================================================
        // ENTER_FRAME
        // ================================================================
        private function onFrame(e:Event):void {
            frameCount++;

            // Pulse status dot
            var pulse:Number = 0.4 + 0.6 * (0.5 + 0.5 * Math.sin(frameCount * 0.04));
            statusDot.alpha = pulse;

            // Gas mask warning blink
            if (needsGasMask) {
                gasMaskField.visible = true;
                gasMaskField.text = "EQUIP MASK";
                var blinkAlpha:Number = 0.5 + 0.5 * Math.sin(frameCount * 0.12);
                gasMaskField.alpha = blinkAlpha;
                gasMaskField.filters = [new GlowFilter(UIPrimitives.COL_WARN, 0.6, 6, 6, 1.5, 1)];
            } else if (isHazardous) {
                gasMaskField.visible = true;
                gasMaskField.text = "HAZARD";
                gasMaskField.alpha = 0.85;
                gasMaskField.filters = [new GlowFilter(UIPrimitives.COL_AMBER, 0.4, 4, 4, 1.2, 1)];
            } else {
                gasMaskField.visible = false;
            }

            // Update day/night icon glow pulse
            if (dayNightIcon.numChildren > 0) {
                var iconPulse:Number = 0.12 + 0.33 * (0.5 + 0.5 * Math.sin(frameCount * 0.04));
                var glowChild:* = dayNightIcon.getChildAt(0);
                if (glowChild) glowChild.alpha = iconPulse;
            }
        }

        // ================================================================
        // DAY/NIGHT ICONS
        // ================================================================
        private function drawSunIcon():void {
            while (dayNightIcon.numChildren > 0) dayNightIcon.removeChildAt(0);

            var col:uint = getDayNightColor();
            var cx:Number = 16;
            var cy:Number = 14;
            var sz:Number = 10;

            // Glow circle (behind)
            var glow:Shape = new Shape();
            glow.graphics.beginFill(col, 0.25);
            glow.graphics.drawCircle(cx, cy, sz * 0.6);
            glow.graphics.endFill();
            dayNightIcon.addChild(glow);

            // Icon
            var icon:Shape = new Shape();
            var g:* = icon.graphics;

            if (dayNight == 3) {
                // Moon (crescent)
                g.beginFill(col, 1);
                g.drawCircle(cx, cy, sz * 0.35);
                g.endFill();
                g.beginFill(UIPrimitives.COL_BG, 1);
                g.drawCircle(cx + sz * 0.18, cy - sz * 0.1, sz * 0.26);
                g.endFill();
            } else {
                // Sun (circle + rays)
                var r:Number = sz * 0.25;
                g.beginFill(col, 1);
                g.drawCircle(cx, cy, r);
                g.endFill();
                g.lineStyle(2, col, 0.9);
                var rayLen:Number = sz * 0.42;
                for (var i:int = 0; i < 8; i++) {
                    var angle:Number = i * 0.7854;
                    g.moveTo(cx + Math.cos(angle) * (r + 1),
                             cy + Math.sin(angle) * (r + 1));
                    g.lineTo(cx + Math.cos(angle) * rayLen,
                             cy + Math.sin(angle) * rayLen);
                }
            }

            dayNightIcon.addChild(icon);
            UIPrimitives.applyNeonGlow(icon, col, 0.3);
        }

        private function getDayNightColor():uint {
            switch (dayNight) {
                case 1: return COL_DAWN;
                case 2: return COL_DUSK;
                case 3: return COL_NIGHT;
                default: return COL_SUN;
            }
        }

        // ================================================================
        // FORMAT TIME
        // ================================================================
        private function formatTime(hour:Number):String {
            var h:int = int(hour);
            var m:int = int((hour - h) * 60);
            var mStr:String = (m < 10) ? "0" + m : String(m);
            var period:String = (h >= 12) ? "PM" : "AM";
            var h12:int = h % 12;
            if (h12 == 0) h12 = 12;
            return h12 + ":" + mStr + " " + period;
        }

        // ================================================================
        // UPDATE VISUALS
        // ================================================================
        private function updateVisuals():void {
            // Time
            timeField.text = formatTime(gameHour);
            var dnCol:uint = getDayNightColor();
            timeField.filters = [new GlowFilter(dnCol, 0.3, 3, 3, 1, 1)];

            // Weather name — color based on weather class
            var wCol:uint = UIPrimitives.COL_ACCENT;
            if (weatherClass == 2 || weatherClass == 3) wCol = UIPrimitives.COL_AMBER;
            if (isHazardous) wCol = UIPrimitives.COL_WARN;

            weatherField.text = weatherName;
            var wfmt:TextFormat = weatherField.defaultTextFormat;
            wfmt.color = wCol;
            weatherField.defaultTextFormat = wfmt;
            weatherField.setTextFormat(wfmt);
            weatherField.filters = (weatherClass > 1 || isHazardous) ?
                [new GlowFilter(wCol, 0.4, 4, 4, 1.2, 1)] :
                [UIPrimitives.TEXT_SHADOW];

            // Location
            if (locationName.length > 0) {
                locationField.text = locationName;
            } else if (dateStr.length > 0) {
                locationField.text = dateStr;
            }

            // Status dot color
            statusDot.graphics.clear();
            var dotCol:uint = isHazardous ? UIPrimitives.COL_WARN :
                (weatherClass > 1 ? UIPrimitives.COL_AMBER : UIPrimitives.COL_ACCENT);
            statusDot.graphics.beginFill(dotCol, 0.9);
            statusDot.graphics.drawCircle(0, 0, 3);
            statusDot.graphics.endFill();

            // Redraw day/night icon
            drawSunIcon();
        }

        // ================================================================
        // PROCESS MESSAGE
        // ================================================================
        public function processMessage(command:String, params:Array):void {
            var cmd:int = parseInt(command);

            if (cmd == CMD_WEATHER_UPDATE && params && params.length >= 5) {
                weatherClass = int(params[0]);
                dayNight = int(params[1]);
                gameHour = Number(params[2]);
                isHazardous = (int(params[3]) > 0);
                needsGasMask = (int(params[4]) > 0);
                updateVisuals();
            } else if (cmd == CMD_WEATHER_NAME && params && params.length >= 1) {
                weatherName = String(params[0]);
                if (weatherName.length == 0) weatherName = "CLEAR";
                updateVisuals();
            } else if (cmd == CMD_LOCATION && params && params.length >= 1) {
                locationName = String(params[0]);
                updateVisuals();
            } else if (cmd == CMD_DATE && params && params.length >= 1) {
                dateStr = String(params[0]);
                if (locationName.length == 0) {
                    locationField.text = dateStr;
                }
            }
        }
    }
}
