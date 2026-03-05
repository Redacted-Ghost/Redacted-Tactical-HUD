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
     * LoreOut AP Widget v11 — Tactical panel energy bar.
     *
     * 192x24 with chamfered slim tactical panel, blue accent,
     * glowing bolt icon, segmented bar, value readout.
     * Panel outline shifts: blue(normal) → amber(low) → red(critical).
     *
     * CMD 600 (floats): currentAP, maxAP, isInVATS, 0, 0, 0
     */
    public class LoreOutAPWidget extends MovieClip implements IHUDWidget {

        // ---- COMMANDS ----
        private static const CMD_AP:int = 600;

        // ---- LAYOUT ----
        private static const PANEL_W:int = 300;
        private static const PANEL_H:int = 28;
        private static const PAD:int = 6;

        // ---- BAR GEOMETRY ----
        private static const BAR_H:Number = 7;
        private static const BAR_SEGMENTS:int = 15;

        // ---- ELEMENTS ----
        private var cyberParts:Object;
        private var panelShape:Shape;
        private var boltIcon:Shape;
        private var barContainer:Sprite;
        private var apLabel:TextField;
        private var apValue:TextField;

        // ---- STATE ----
        private var currentAP:Number = 0;
        private var maxAP:Number = 100;
        private var isInVATS:Boolean = false;
        private var smoothAP:Number = 0;
        private var frameCount:int = 0;

        // Computed bar layout
        private var barX:Number = 0;
        private var barY:Number = 0;
        private var barW:Number = 0;

        public function LoreOutAPWidget() {
            super();
            buildUI();
            addEventListener(Event.ENTER_FRAME, onFrame);
        }

        // ================================================================
        // BUILD UI
        // ================================================================
        private function buildUI():void {
            // === CYBER PANEL (slim, minimal structural) ===
            cyberParts = UIPrimitives.buildCyberPanel(this, PANEL_W, PANEL_H,
                UIPrimitives.COL_BLUE, "slim");
            panelShape = cyberParts.panel as Shape;

            // Bolt icon (left, inside panel) — GLOWS
            boltIcon = UIPrimitives.drawBoltIcon(this, 12, 14, 12,
                UIPrimitives.COL_BLUE, 0.65);
            UIPrimitives.applyNeonGlow(boltIcon, UIPrimitives.COL_BLUE, 0.25);

            // AP label
            apLabel = UIPrimitives.makeLabel(this, "AP", 10, 0.80,
                UIPrimitives.COL_BLUE);
            apLabel.x = 22;
            apLabel.y = -3;

            // AP value (right-aligned)
            apValue = UIPrimitives.makeValue(this, "0", 11, 0.95, 0xFFFFFF);
            apValue.x = PANEL_W - 50;
            apValue.y = -4;
            apValue.width = 44;
            var vfmt:TextFormat = apValue.defaultTextFormat;
            vfmt.align = TextFormatAlign.RIGHT;
            apValue.defaultTextFormat = vfmt;
            apValue.setTextFormat(vfmt);

            // Bar layout (inside panel, wide)
            barX = 24;
            barY = 14;
            barW = PANEL_W - 30;

            // Bar container (initial empty)
            barContainer = UIPrimitives.drawSegmentedBar(this,
                barX, barY, barW, BAR_H, 0, BAR_SEGMENTS);
        }

        // ================================================================
        // ENTER_FRAME
        // ================================================================
        private function onFrame(e:Event):void {
            frameCount++;
            smoothAP += (currentAP - smoothAP) * 0.2;
            drawBar();
            updateReadout();
        }

        // ================================================================
        // DRAW BAR
        // ================================================================
        private function drawBar():void {
            if (barContainer && barContainer.parent) {
                barContainer.parent.removeChild(barContainer);
            }

            var pct:Number = (maxAP > 0) ? (smoothAP / maxAP * 100) : 0;
            if (pct > 100) pct = 100;
            if (pct < 0) pct = 0;

            // Color based on AP level
            var col:uint = UIPrimitives.COL_BLUE;
            if (pct < 30) col = UIPrimitives.COL_WARN;
            else if (pct < 50) col = UIPrimitives.COL_AMBER;

            barContainer = UIPrimitives.drawSegmentedBar(this,
                barX, barY, barW, BAR_H, pct, BAR_SEGMENTS, col);

            // VATS pulse — glow on the bar (not the panel)
            if (isInVATS) {
                var vatsAlpha:Number = 0.3 + Math.sin(frameCount * 0.2) * 0.3;
                barContainer.filters = [new GlowFilter(col, vatsAlpha, 6, 3, 1.5, 1)];
            } else if (pct < 30) {
                barContainer.filters = [new GlowFilter(col, 0.3, 4, 2, 1.2, 1)];
            } else {
                barContainer.filters = [];
            }
        }

        // ================================================================
        // UPDATE READOUT
        // ================================================================
        private function updateReadout():void {
            var pct:Number = (maxAP > 0) ? (currentAP / maxAP) : 0;

            apValue.text = String(int(currentAP));

            // Determine color for value + panel outline
            var col:uint;
            if (pct > 0.5) {
                col = UIPrimitives.COL_BLUE;
            } else if (pct > 0.3) {
                col = UIPrimitives.COL_AMBER;
            } else {
                col = UIPrimitives.COL_WARN;
            }

            var vfmt:TextFormat = apValue.defaultTextFormat;
            vfmt.color = col;
            vfmt.align = TextFormatAlign.RIGHT;
            apValue.defaultTextFormat = vfmt;
            apValue.setTextFormat(vfmt);

            // Recolor cyber panel (grey frame stays, accent trim shifts)
            UIPrimitives.recolorCyberPanel(cyberParts, col);

            // Recolor bolt icon glow to match
            UIPrimitives.applyNeonGlow(boltIcon, col, 0.25);
        }

        // ================================================================
        // UPDATE DATA
        // ================================================================
        private function updateAP(ap:Number, apMax:Number, vats:Boolean):void {
            currentAP = ap;
            if (apMax > 0) maxAP = apMax;
            isInVATS = vats;
            if (currentAP < 0) currentAP = 0;
        }

        // ================================================================
        // PROCESS MESSAGE
        // ================================================================
        public function processMessage(command:String, params:Array):void {
            var cmd:int = parseInt(command);
            if (cmd == CMD_AP && params && params.length >= 2) {
                updateAP(
                    Number(params[0]),
                    Number(params[1]),
                    (params.length >= 3 && int(params[2]) > 0)
                );
            }
        }
    }
}
