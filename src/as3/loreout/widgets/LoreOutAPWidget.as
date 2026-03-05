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
     * LoreOut AP Widget v12 — Energy Bar.
     *
     * 300x32 slim panel with segmented bar:
     *   - Bolt icon + "AP" label
     *   - 15-segment bar with quarter-mark ticks
     *   - Numeric value right-aligned
     *   - VATS mode: subtle white glow pulse
     *
     * White (normal), grey (low), red (critical).
     *
     * CMD 600 (floats): currentAP, maxAP, isInVATS
     */
    public class LoreOutAPWidget extends MovieClip implements IHUDWidget {

        // ---- COMMANDS ----
        private static const CMD_AP:int = 600;

        // ---- LAYOUT ----
        private static const PANEL_W:int = 300;
        private static const PANEL_H:int = 32;
        private static const PAD:int = 6;

        // ---- BAR GEOMETRY ----
        private static const BAR_H:Number = 7;
        private static const BAR_SEGMENTS:int = 15;

        // ---- ELEMENTS ----
        private var panelBg:Shape;
        private var boltIcon:Shape;
        private var barContainer:Sprite;
        private var quarterTicks:Shape;
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
            // Panel background (dark rect + border, simple slim)
            panelBg = new Shape();
            var pg:* = panelBg.graphics;
            pg.beginFill(UIPrimitives.COL_BG, 0.85);
            pg.drawRect(0, 0, PANEL_W, PANEL_H);
            pg.endFill();
            pg.lineStyle(1, UIPrimitives.COL_BORDER, 0.40);
            pg.drawRect(0, 0, PANEL_W, PANEL_H);
            addChild(panelBg);

            // Bolt icon (left, white)
            boltIcon = UIPrimitives.drawBoltIcon(this, 12, 10, 12,
                UIPrimitives.COL_ACCENT, 0.65);

            // AP label (grey)
            apLabel = UIPrimitives.makeLabel(this, "AP", 10, 0.60,
                UIPrimitives.COL_TEXT_SEC);
            apLabel.x = 22;
            apLabel.y = 0;

            // AP value (right-aligned, white)
            apValue = UIPrimitives.makeValue(this, "0", 11, 0.95,
                0xFFFFFF);
            apValue.x = PANEL_W - 50;
            apValue.y = -1;
            apValue.width = 44;
            var vfmt:TextFormat = apValue.defaultTextFormat;
            vfmt.align = TextFormatAlign.RIGHT;
            apValue.defaultTextFormat = vfmt;
            apValue.setTextFormat(vfmt);

            // Bar layout
            barX = 24;
            barY = 16;
            barW = PANEL_W - 30;

            // Initial bar
            barContainer = UIPrimitives.drawSegmentedBar(this,
                barX, barY, barW, BAR_H, 0, BAR_SEGMENTS);

            // Quarter-mark ticks below bar (at 25%, 50%, 75%)
            quarterTicks = new Shape();
            var qg:* = quarterTicks.graphics;
            qg.lineStyle(0.5, UIPrimitives.COL_FRAME, 0.25);
            for (var q:int = 1; q <= 3; q++) {
                var qx:Number = barX + barW * (q * 0.25);
                qg.moveTo(qx, barY + BAR_H + 1);
                qg.lineTo(qx, barY + BAR_H + 3);
            }
            addChild(quarterTicks);
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

            // Color: white > grey > red
            var col:uint = UIPrimitives.COL_ACCENT;
            if (pct < 30) col = UIPrimitives.COL_WARN;
            else if (pct < 50) col = UIPrimitives.COL_AMBER;

            barContainer = UIPrimitives.drawSegmentedBar(this,
                barX, barY, barW, BAR_H, pct, BAR_SEGMENTS, col);

            // VATS pulse — subtle white glow
            if (isInVATS) {
                var vatsAlpha:Number = 0.2 +
                    Math.sin(frameCount * 0.2) * 0.2;
                barContainer.filters = [
                    new GlowFilter(0xFFFFFF, vatsAlpha, 6, 3, 1.5, 1)];
            } else if (pct < 30) {
                barContainer.filters = [
                    new GlowFilter(col, 0.3, 4, 2, 1.2, 1)];
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

            // Value color
            var col:uint;
            if (pct > 0.5) col = UIPrimitives.COL_ACCENT;
            else if (pct > 0.3) col = UIPrimitives.COL_AMBER;
            else col = UIPrimitives.COL_WARN;

            var vfmt:TextFormat = apValue.defaultTextFormat;
            vfmt.color = col;
            vfmt.align = TextFormatAlign.RIGHT;
            apValue.defaultTextFormat = vfmt;
            apValue.setTextFormat(vfmt);
        }

        // ================================================================
        // UPDATE DATA
        // ================================================================
        private function updateAP(ap:Number, apMax:Number,
            vats:Boolean):void {
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
