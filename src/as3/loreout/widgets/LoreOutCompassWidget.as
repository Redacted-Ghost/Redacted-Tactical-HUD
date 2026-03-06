package loreout.widgets {
    import flash.display.MovieClip;
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    import flash.events.Event;
    import hudframework.IHUDWidget;
    import loreout.ui.UIPrimitives;

    /**
     * LoreOut Compass Widget — pre-built scrolling heading tape.
     *
     * KEY DESIGN: The tick tape is drawn ONCE at build time covering
     * -180° to 540° (720° total). Per-frame, ONLY tapeContainer.x is
     * updated to scroll the pre-built tape — zero per-frame drawing.
     * This matches how the vanilla compass works (engine scrolls
     * CompassBar_mc.x, the strip is pre-built).
     *
     * NATIVE HEADING: Reads CompassBar_mc.x from the game engine on
     * ENTER_FRAME for frame-perfect rotation. Falls back to Papyrus
     * velocity prediction before calibration completes.
     *
     * Hostile/location markers are placed at ABSOLUTE compass degrees
     * so they scroll naturally with the tape between Papyrus updates.
     * Only rebuilt when new Papyrus data arrives, not per-frame.
     *
     * CMD 500 (floats): headingDeg, h1, h2, h3, h4, h5
     * CMD "501" (string): "bearing:name|bearing:name|..."
     */
    public class LoreOutCompassWidget extends MovieClip implements IHUDWidget {

        // ---- COMMANDS ----
        private static const CMD_COMPASS:int = 500;
        private static const CMD_LOCATIONS:String = "501";

        // ---- LAYOUT ----
        private static const PANEL_W:int = 420;
        private static const PANEL_H:int = 20;
        private static const PAD:int = 6;
        private static const TAPE_CY:Number = 10;

        // ---- TAPE GEOMETRY ----
        private static const VISIBLE_ARC:Number = 180;
        private static const TAPE_W:Number = PANEL_W - PAD * 2;   // 408
        private static const DEG_TO_PX:Number = TAPE_W / VISIBLE_ARC;  // ~2.267

        // Extended tape range for seamless wrapping at 0°/360°
        private static const TAPE_MIN_DEG:int = -180;
        private static const TAPE_MAX_DEG:int = 540;

        // Center of visible window in parent coords
        private static const CX:Number = PANEL_W * 0.5;  // 210

        // ---- DISPLAY LAYERS ----
        private var tapeContainer:Sprite;   // scrolled via .x per-frame
        private var tickLayer:Sprite;       // pre-built ONCE (ticks + cardinals)
        private var markerLayer:Sprite;     // rebuilt only on Papyrus data
        private var clipMask:Shape;
        private var headingField:TextField;

        // ---- HEADING STATE ----
        private var smoothHeading:Number = 0;

        // ---- NATIVE HEADING (reads CompassBar_mc.x from engine) ----
        private var compassBarRef:* = null;
        private var nativeSearched:Boolean = false;
        private var nativeCalibrated:Boolean = false;
        private var calScale:Number = 0;
        private var calOffset:Number = 0;
        private var calSamples:Array = [];

        // ---- FALLBACK: velocity prediction ----
        private var currentHeading:Number = 0;
        private var lastHeading:Number = 0;
        private var angularVelocity:Number = 0;
        private var framesSinceUpdate:int = 0;
        private var hasFirstUpdate:Boolean = false;

        // ---- MARKER DATA (absolute compass degrees) ----
        private var hostileAbsBearings:Array = [];
        private var locationAbsMarkers:Array = [];
        private var lastPapyrusHeading:Number = 0;

        public function LoreOutCompassWidget() {
            super();
            buildUI();
            addEventListener(Event.ENTER_FRAME, onFrame);
        }

        // ================================================================
        // BUILD UI — tape drawn ONCE, only .x changes per-frame
        // ================================================================
        private function buildUI():void {
            // Clip mask (fixed position — defines the visible window)
            clipMask = new Shape();
            clipMask.graphics.beginFill(0x000000);
            clipMask.graphics.drawRect(PAD, 0, TAPE_W, PANEL_H);
            clipMask.graphics.endFill();
            addChild(clipMask);

            // Tape container (ONLY .x changes per-frame)
            tapeContainer = new Sprite();
            tapeContainer.mask = clipMask;
            addChild(tapeContainer);

            // Pre-built tick layer (NEVER redrawn)
            tickLayer = new Sprite();
            tapeContainer.addChild(tickLayer);
            buildTicks();

            // Marker layer (rebuilt only on Papyrus data)
            markerLayer = new Sprite();
            tapeContainer.addChild(markerLayer);

            // Center pointer — fixed triangles (NOT in tape, don't scroll)
            var cm:Shape = new Shape();
            var cg:* = cm.graphics;
            cg.lineStyle(0);
            // Top pointer
            cg.beginFill(UIPrimitives.COL_TEXT_VAL, 0.9);
            cg.moveTo(CX - 3, 0);
            cg.lineTo(CX + 3, 0);
            cg.lineTo(CX, 4);
            cg.lineTo(CX - 3, 0);
            cg.endFill();
            // Bottom pointer
            cg.beginFill(UIPrimitives.COL_TEXT_VAL, 0.9);
            cg.moveTo(CX - 3, PANEL_H);
            cg.lineTo(CX + 3, PANEL_H);
            cg.lineTo(CX, PANEL_H - 4);
            cg.lineTo(CX - 3, PANEL_H);
            cg.endFill();
            addChild(cm);

            // Heading readout (fixed, below tape)
            headingField = makeLabel("000\u00B0", 9, UIPrimitives.COL_TEXT_VAL);
            headingField.width = 40;
            headingField.x = (PANEL_W - 40) * 0.5;
            headingField.y = PANEL_H + 1;
            var hfmt:TextFormat = headingField.defaultTextFormat;
            hfmt.align = TextFormatAlign.CENTER;
            headingField.defaultTextFormat = hfmt;
            headingField.setTextFormat(hfmt);
            addChild(headingField);
        }

        // ================================================================
        // BUILD TICKS — called ONCE at init. Draws all tick marks and
        // cardinal labels from -180° to 540° (720° of content).
        // The mask only shows ~180° at a time. NEVER redrawn.
        // ================================================================
        private function buildTicks():void {
            var g:* = tickLayer.graphics;

            for (var deg:int = TAPE_MIN_DEG; deg <= TAPE_MAX_DEG; deg += 5) {
                var px:Number = deg * DEG_TO_PX;
                var normDeg:int = ((deg % 360) + 360) % 360;

                var isCardinal:Boolean = (normDeg % 90 == 0);
                var isMajor:Boolean = (normDeg % 45 == 0);
                var isMedium:Boolean = (normDeg % 15 == 0);

                if (isCardinal) {
                    g.lineStyle(1, UIPrimitives.COL_BORDER, 0.5);
                    g.moveTo(px, 2);
                    g.lineTo(px, PANEL_H - 2);
                } else if (isMajor) {
                    g.lineStyle(1, UIPrimitives.COL_BORDER, 0.30);
                    g.moveTo(px, TAPE_CY - 5);
                    g.lineTo(px, TAPE_CY + 5);
                } else if (isMedium) {
                    g.lineStyle(1, UIPrimitives.COL_BORDER, 0.18);
                    g.moveTo(px, TAPE_CY - 3);
                    g.lineTo(px, TAPE_CY + 3);
                } else {
                    g.lineStyle(0);
                    g.beginFill(UIPrimitives.COL_BORDER, 0.10);
                    g.drawCircle(px, TAPE_CY, 0.5);
                    g.endFill();
                }
            }

            // Cardinal labels — placed at each occurrence in extended range
            var cardinals:Array = [
                {letter: "N", deg: 0, isNorth: true},
                {letter: "E", deg: 90, isNorth: false},
                {letter: "S", deg: 180, isNorth: false},
                {letter: "W", deg: 270, isNorth: false}
            ];

            for (var ci:int = 0; ci < cardinals.length; ci++) {
                var card:Object = cardinals[ci];
                var baseDeg:int = int(card.deg);
                // Place at baseDeg-360, baseDeg, and baseDeg+360
                for (var rep:int = -1; rep <= 1; rep++) {
                    var d:int = baseDeg + rep * 360;
                    if (d >= TAPE_MIN_DEG && d <= TAPE_MAX_DEG) {
                        var lpx:Number = d * DEG_TO_PX;
                        var col:uint = card.isNorth ? UIPrimitives.COL_WARN : UIPrimitives.COL_TEXT_PRI;
                        var alph:Number = card.isNorth ? 0.95 : 0.75;

                        var tf:TextField = makeLabel(String(card.letter), 11, col);
                        tf.alpha = alph;
                        tf.x = lpx - tf.textWidth * 0.5 - 2;
                        tf.y = TAPE_CY - tf.textHeight * 0.5 - 2;
                        tickLayer.addChild(tf);
                    }
                }
            }
        }

        // ================================================================
        // REBUILD MARKERS — called ONLY when Papyrus data arrives.
        // Markers placed at absolute compass degrees so they scroll
        // naturally with the tape between updates.
        // ================================================================
        private function rebuildMarkers():void {
            var g:* = markerLayer.graphics;
            g.clear();
            while (markerLayer.numChildren > 0) {
                markerLayer.removeChildAt(0);
            }

            // Hostile markers (red pips at absolute bearings)
            for (var hi:int = 0; hi < hostileAbsBearings.length; hi++) {
                drawMarkerCopies(Number(hostileAbsBearings[hi]), true);
            }

            // Location markers (teal diamonds at absolute bearings)
            for (var li:int = 0; li < locationAbsMarkers.length; li++) {
                drawMarkerCopies(Number(locationAbsMarkers[li].absDeg), false);
            }
        }

        // Draw a marker at degree + wrapping copies (-360, 0, +360)
        private function drawMarkerCopies(absDeg:Number, isHostile:Boolean):void {
            var g:* = markerLayer.graphics;
            for (var rep:int = -1; rep <= 1; rep++) {
                var d:Number = absDeg + rep * 360;
                if (d >= TAPE_MIN_DEG && d <= TAPE_MAX_DEG) {
                    var px:Number = d * DEG_TO_PX;
                    g.lineStyle(0);
                    if (isHostile) {
                        // Red triangle (bottom edge)
                        g.beginFill(UIPrimitives.COL_WARN, 0.9);
                        g.moveTo(px - 3, PANEL_H - 3);
                        g.lineTo(px + 3, PANEL_H - 3);
                        g.lineTo(px, PANEL_H - 7);
                        g.lineTo(px - 3, PANEL_H - 3);
                        g.endFill();
                    } else {
                        // Teal diamond (top edge)
                        g.beginFill(UIPrimitives.COL_ACCENT, 0.55);
                        g.moveTo(px, 3);
                        g.lineTo(px + 3, 6);
                        g.lineTo(px, 9);
                        g.lineTo(px - 3, 6);
                        g.lineTo(px, 3);
                        g.endFill();
                    }
                }
            }
        }

        // ================================================================
        // FIND COMPASS BAR — for native heading
        // ================================================================
        private function findCompassBar():void {
            nativeSearched = true;
            try {
                if (!stage) return;
                var root:* = stage.getChildAt(0);
                if (!root) return;
                var bcg:* = root["BottomCenterGroup_mc"];
                if (!bcg) return;
                var cw:* = bcg["CompassWidget_mc"];
                if (!cw) return;
                var bar:* = cw["CompassBar_mc"];
                if (bar) { compassBarRef = bar; }
            } catch (e:*) {}
        }

        // ================================================================
        // ENTER_FRAME — just scroll the pre-built tape. That's it.
        // ================================================================
        private function onFrame(e:Event):void {
            if (!nativeSearched) { findCompassBar(); }

            // ---- NATIVE PATH: read heading from engine ----
            if (nativeCalibrated && compassBarRef) {
                try {
                    var rawX:Number = Number(compassBarRef["x"]);
                    var nativeHeading:Number = rawX * calScale + calOffset;
                    nativeHeading = ((nativeHeading % 360) + 360) % 360;
                    smoothHeading = nativeHeading;
                    scrollTape();
                    return;
                } catch (e:*) {}
            }

            // ---- FALLBACK: velocity prediction ----
            framesSinceUpdate++;
            var predicted:Number = currentHeading;
            if (hasFirstUpdate) {
                predicted = currentHeading + angularVelocity * framesSinceUpdate;
                predicted = ((predicted % 360) + 360) % 360;
            }
            var diff:Number = angleDiff(predicted, smoothHeading);
            var lerpFactor:Number = 0.5;
            var absDiff:Number = (diff < 0) ? -diff : diff;
            if (absDiff > 15) { lerpFactor = 0.75; }
            else if (absDiff < 1) { lerpFactor = 0.35; }
            smoothHeading += diff * lerpFactor;
            smoothHeading = ((smoothHeading % 360) + 360) % 360;
            scrollTape();
        }

        // ================================================================
        // SCROLL TAPE — the ONLY per-frame operation.
        // Moves the pre-built tape so current heading is at center.
        // ================================================================
        private function scrollTape():void {
            tapeContainer.x = CX - smoothHeading * DEG_TO_PX;
            var hdg:int = ((int(smoothHeading + 0.5) % 360) + 360) % 360;
            headingField.text = padDeg(hdg) + "\u00B0";
        }

        // ================================================================
        // CALIBRATE — uses Papyrus heading + compassBar.x to compute
        // linear conversion from engine x to degrees
        // ================================================================
        private function tryCalibrate(papyrusHeading:Number):void {
            if (!compassBarRef || nativeCalibrated) return;
            try {
                var rawX:Number = Number(compassBarRef["x"]);
                calSamples.push({x: rawX, heading: papyrusHeading});
                if (calSamples.length >= 2) {
                    var s0:Object = calSamples[0];
                    var s1:Object = calSamples[calSamples.length - 1];
                    var dx:Number = s1.x - s0.x;
                    var dh:Number = angleDiff(Number(s1.heading), Number(s0.heading));
                    if (dx > 10 || dx < -10) {
                        calScale = dh / dx;
                        calOffset = Number(s0.heading) - Number(s0.x) * calScale;
                        nativeCalibrated = true;
                    }
                }
            } catch (e:*) {}
        }

        // ================================================================
        // HELPERS
        // ================================================================
        private function angleDiff(a:Number, center:Number):Number {
            var d:Number = a - center;
            while (d > 180) d -= 360;
            while (d < -180) d += 360;
            return d;
        }

        private function makeLabel(text:String, size:int, color:uint):TextField {
            var fmt:TextFormat = new TextFormat();
            fmt.font = UIPrimitives.FONT;
            fmt.size = size;
            fmt.color = color;
            fmt.letterSpacing = 1;
            var tf:TextField = new TextField();
            tf.defaultTextFormat = fmt;
            tf.textColor = color;
            tf.selectable = false;
            tf.mouseEnabled = false;
            tf.text = text;
            tf.width = tf.textWidth + 6;
            tf.height = tf.textHeight + 4;
            return tf;
        }

        private function padDeg(deg:int):String {
            if (deg < 10) return "00" + deg;
            if (deg < 100) return "0" + deg;
            return String(deg);
        }

        // ================================================================
        // UPDATE DATA — from Papyrus
        // ================================================================
        private function updateCompass(headingDeg:Number, h1:Number, h2:Number,
                                        h3:Number, h4:Number, h5:Number):void {
            var newHeading:Number = ((headingDeg) + 360) % 360;
            lastPapyrusHeading = newHeading;

            // Try native calibration
            tryCalibrate(newHeading);

            // Velocity prediction (fallback before calibration)
            if (hasFirstUpdate && framesSinceUpdate > 0) {
                var headingDelta:Number = angleDiff(newHeading, lastHeading);
                var newVelocity:Number = headingDelta / framesSinceUpdate;
                angularVelocity = angularVelocity * 0.15 + newVelocity * 0.85;
                if (angularVelocity > 8) angularVelocity = 8;
                if (angularVelocity < -8) angularVelocity = -8;
                if (headingDelta > -0.3 && headingDelta < 0.3) {
                    angularVelocity *= 0.3;
                }
            }
            lastHeading = newHeading;
            currentHeading = newHeading;
            framesSinceUpdate = 0;
            hasFirstUpdate = true;

            // Convert relative hostile bearings → absolute compass degrees
            // so they scroll with the tape between Papyrus updates
            hostileAbsBearings = [];
            var hArr:Array = [h1, h2, h3, h4, h5];
            for (var i:int = 0; i < hArr.length; i++) {
                if (Number(hArr[i]) < 900) {
                    var absBearing:Number = ((newHeading + Number(hArr[i])) + 360) % 360;
                    hostileAbsBearings.push(absBearing);
                }
            }
            rebuildMarkers();
        }

        private function updateLocations(data:String):void {
            locationAbsMarkers = [];
            if (!data || data.length == 0) {
                rebuildMarkers();
                return;
            }
            var entries:Array = data.split("|");
            for (var i:int = 0; i < entries.length; i++) {
                var parts:Array = String(entries[i]).split(":");
                if (parts.length >= 2) {
                    var relBearing:Number = parseFloat(String(parts[0]));
                    var absDeg:Number = ((lastPapyrusHeading + relBearing) + 360) % 360;
                    locationAbsMarkers.push({
                        absDeg: absDeg,
                        name: String(parts[1])
                    });
                }
            }
            rebuildMarkers();
        }

        // ================================================================
        // PROCESS MESSAGE — from HUDFramework
        // ================================================================
        public function processMessage(command:String, params:Array):void {
            var cmd:int = parseInt(command);

            if (cmd == CMD_COMPASS && params && params.length >= 6) {
                updateCompass(
                    Number(params[0]),
                    Number(params[1]),
                    Number(params[2]),
                    Number(params[3]),
                    Number(params[4]),
                    Number(params[5])
                );
            } else if (command == CMD_LOCATIONS && params && params.length >= 1) {
                updateLocations(String(params[0]));
            }
        }
    }
}
