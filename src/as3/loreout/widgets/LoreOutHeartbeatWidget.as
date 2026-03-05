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
     * LoreOut Heartbeat Widget v12 — Vitals Monitor.
     *
     * 300x80 panel with medical monitor aesthetic:
     *   - Heart icon + "VITALS" header + HP% readout
     *   - Grid-paper background behind ECG trace
     *   - PQRST beat pattern with scrolling waveform
     *   - BPM counter (bottom-right)
     *
     * White (healthy), grey (medium), red (critical).
     *
     * CMD 300 (floats): hpPercent, radPercent, isHealing, isTakingDmg
     */
    public class LoreOutHeartbeatWidget extends MovieClip implements IHUDWidget {

        private static const CMD_HEARTBEAT:int = 300;

        private static const PANEL_W:int = 300;
        private static const PANEL_H:int = 80;
        private static const PAD:int = 6;

        // ECG
        private static const TRACE_SAMPLES:int = 80;
        private static const SCROLL_SPEED:Number = 1.5;
        private static const BEAT_LEN:int = 40;

        // Elements
        private var panelBg:Shape;
        private var heartIcon:Shape;
        private var gridBg:Shape;
        private var traceContainer:Sprite;
        private var hpValue:TextField;
        private var bpmField:TextField;

        // State
        private var hpPercent:Number = 100;
        private var radPercent:Number = 0;
        private var isHealing:Boolean = false;
        private var isTakingDmg:Boolean = false;

        // Waveform buffer
        private var waveBuffer:Array;
        private var writePos:int = 0;
        private var scrollAccum:Number = 0;
        private var beatPhase:int = 0;
        private var beatPattern:Array;

        // Timing
        private var beatInterval:int = 60;
        private var beatCounter:int = 0;
        private var isBeatActive:Boolean = false;
        private var frameCount:int = 0;

        // Trace layout
        private var traceY:Number;
        private var traceH:Number;
        private var traceW:Number;

        public function LoreOutHeartbeatWidget() {
            super();
            buildBeatPattern();
            initBuffer();
            buildUI();
            addEventListener(Event.ENTER_FRAME, onFrame);
        }

        // ================================================================
        // PQRST BEAT PATTERN
        // ================================================================
        private function buildBeatPattern():void {
            beatPattern = [
                0.5, 0.5, 0.5, 0.5, 0.5,
                0.52, 0.58, 0.62,
                0.58, 0.52, 0.5,
                0.5, 0.5,
                0.42,
                0.7, 0.95,
                0.2, 0.15,
                0.35, 0.5,
                0.5, 0.5, 0.5,
                0.52, 0.58, 0.62,
                0.60, 0.55, 0.5,
                0.5, 0.5, 0.5, 0.5, 0.5,
                0.5, 0.5, 0.5, 0.5, 0.5, 0.5
            ];
        }

        private function initBuffer():void {
            waveBuffer = [];
            for (var i:int = 0; i < TRACE_SAMPLES; i++) {
                waveBuffer.push(0.5);
            }
            writePos = 0;
        }

        // ================================================================
        // BUILD UI
        // ================================================================
        private function buildUI():void {
            // Panel background (dark rect + border)
            panelBg = new Shape();
            var pg:* = panelBg.graphics;
            pg.beginFill(UIPrimitives.COL_BG, 0.85);
            pg.drawRect(0, 0, PANEL_W, PANEL_H);
            pg.endFill();
            pg.lineStyle(1, UIPrimitives.COL_BORDER, 0.40);
            pg.drawRect(0, 0, PANEL_W, PANEL_H);
            addChild(panelBg);

            // Corner brackets
            UIPrimitives.drawCornerBrackets(this, PANEL_W, PANEL_H, 8,
                UIPrimitives.COL_ACCENT, 0.35);

            // Heart icon (white)
            heartIcon = UIPrimitives.drawHeartIcon(this,
                14, 13, 10, 0xFFFFFF, 0.85);

            // "VITALS" label
            var headerLabel:TextField = UIPrimitives.makeValue(this,
                "VITALS", 11, 0.90, 0xFFFFFF);
            headerLabel.x = 24;
            headerLabel.y = 4;

            // HP percentage (right-aligned)
            hpValue = UIPrimitives.makeValue(this, "100%", 13, 0.97,
                0xFFFFFF);
            hpValue.x = PANEL_W - 54;
            hpValue.y = 2;
            hpValue.width = 48;
            var hfmt:TextFormat = hpValue.defaultTextFormat;
            hfmt.align = TextFormatAlign.RIGHT;
            hpValue.defaultTextFormat = hfmt;
            hpValue.setTextFormat(hfmt);

            // Header divider
            UIPrimitives.drawDivider(this, PAD, 22, PANEL_W - PAD, 22, 0.25);

            // Trace area dimensions
            traceY = 24;
            traceH = PANEL_H - traceY - 18;
            traceW = PANEL_W - PAD * 2;

            // Grid-paper background (faint vertical lines + center line)
            gridBg = UIPrimitives.drawGridPattern(this,
                PAD, traceY, traceW, traceH,
                24, 0, UIPrimitives.COL_FRAME, 0.06);

            // ECG trace container
            traceContainer = new Sprite();
            traceContainer.x = PAD;
            traceContainer.y = traceY;
            addChild(traceContainer);

            // Bottom divider
            UIPrimitives.drawDivider(this, PAD, traceY + traceH + 2,
                PANEL_W - PAD, traceY + traceH + 2, 0.15);

            // BPM counter (bottom-right)
            bpmField = UIPrimitives.makeLabel(this, "72 BPM", 9, 0.50,
                UIPrimitives.COL_TEXT_SEC);
            bpmField.x = PANEL_W - 60;
            bpmField.y = PANEL_H - 16;
            bpmField.width = 54;
            var bfmt:TextFormat = bpmField.defaultTextFormat;
            bfmt.align = TextFormatAlign.RIGHT;
            bpmField.defaultTextFormat = bfmt;
            bpmField.setTextFormat(bfmt);

            // Data tag below panel
            var tag:TextField = UIPrimitives.makeDataTag(this, "VIT-01", 8,
                UIPrimitives.COL_FRAME_LIGHT, 0.30);
            tag.x = 20;
            tag.y = PANEL_H + 1;
        }

        // ================================================================
        // ENTER_FRAME
        // ================================================================
        private function onFrame(e:Event):void {
            frameCount++;

            // Beat interval scales with HP
            if (hpPercent > 75) beatInterval = 80;
            else if (hpPercent > 50) beatInterval = 55;
            else if (hpPercent > 25) beatInterval = 35;
            else if (hpPercent > 10) beatInterval = 22;
            else if (hpPercent > 0) beatInterval = 15;

            beatCounter++;
            if (!isBeatActive && beatCounter >= beatInterval) {
                isBeatActive = true;
                beatPhase = 0;
                beatCounter = 0;
            }

            var sample:Number = 0.5;
            if (hpPercent <= 0) {
                sample = 0.5; // flatline
            } else if (isBeatActive) {
                sample = Number(beatPattern[beatPhase]);
                var amplitude:Number = 0.4 + (hpPercent / 100) * 0.6;
                sample = 0.5 + (sample - 0.5) * amplitude;
                beatPhase++;
                if (beatPhase >= BEAT_LEN) {
                    isBeatActive = false;
                    beatPhase = 0;
                }
            }

            // Radiation noise
            if (radPercent > 10) {
                sample += (Math.random() - 0.5) *
                    (radPercent / 100) * 0.08;
            }

            waveBuffer[writePos] = sample;
            writePos = (writePos + 1) % TRACE_SAMPLES;
            scrollAccum += SCROLL_SPEED;

            drawTrace();
        }

        // ================================================================
        // DRAW TRACE
        // ================================================================
        private function drawTrace():void {
            var g:* = traceContainer.graphics;
            g.clear();

            // Trace color based on HP
            var traceColor:uint;
            var traceAlpha:Number = 0.90;
            if (hpPercent <= 0) {
                traceColor = UIPrimitives.COL_WARN;
                traceAlpha = 0.5;
            } else if (hpPercent < 25) {
                traceColor = UIPrimitives.COL_WARN;
            } else if (hpPercent < 50) {
                traceColor = UIPrimitives.COL_AMBER;
            } else {
                traceColor = UIPrimitives.COL_ACCENT;
            }

            if (isHealing && hpPercent > 0) traceAlpha = 0.95;
            if (isTakingDmg && hpPercent > 0) {
                traceColor = UIPrimitives.COL_WARN;
            }

            g.lineStyle(2, traceColor, traceAlpha);

            var readPos:int = writePos;
            var stepX:Number = traceW / (TRACE_SAMPLES - 1);

            for (var i:int = 0; i < TRACE_SAMPLES; i++) {
                var idx:int = (readPos + i) % TRACE_SAMPLES;
                var val:Number = Number(waveBuffer[idx]);
                var py:Number = (1.0 - val) * traceH;
                var px:Number = i * stepX;
                if (i == 0) g.moveTo(px, py);
                else g.lineTo(px, py);
            }

            // Trace glow (red only in danger)
            if (traceColor == UIPrimitives.COL_WARN) {
                traceContainer.filters = [
                    new GlowFilter(traceColor, 0.40, 4, 4, 1.2, 1)];
            } else {
                traceContainer.filters = [];
            }

            // Heart icon glow (red only in danger)
            if (hpPercent < 25) {
                heartIcon.filters = [
                    new GlowFilter(UIPrimitives.COL_WARN, 0.5, 4, 4,
                        1.5, 1)];
            } else {
                heartIcon.filters = [];
            }

            // HP readout
            hpValue.text = int(hpPercent) + "%";
            var vfmt:TextFormat = hpValue.defaultTextFormat;
            vfmt.color = (hpPercent < 50) ? traceColor : 0xFFFFFF;
            vfmt.align = TextFormatAlign.RIGHT;
            hpValue.defaultTextFormat = vfmt;
            hpValue.setTextFormat(vfmt);

            // BPM counter (assumes ~30fps)
            var bpm:int = Math.round(60 * 30 / beatInterval);
            bpmField.text = bpm + " BPM";
            var bfmt:TextFormat = bpmField.defaultTextFormat;
            bfmt.color = (hpPercent < 25) ?
                UIPrimitives.COL_WARN : UIPrimitives.COL_TEXT_SEC;
            bfmt.align = TextFormatAlign.RIGHT;
            bpmField.defaultTextFormat = bfmt;
            bpmField.setTextFormat(bfmt);
        }

        // ================================================================
        // UPDATE HP DATA
        // ================================================================
        private function updateHealth(hp:Number, rad:Number,
            healing:Boolean, damage:Boolean):void {
            hpPercent = hp;
            radPercent = rad;
            isHealing = healing;
            isTakingDmg = damage;
            if (hp < 0) hpPercent = 0;
            if (hp > 100) hpPercent = 100;
        }

        public function processMessage(command:String, params:Array):void {
            var cmd:int = parseInt(command);
            if (cmd == CMD_HEARTBEAT && params && params.length >= 4) {
                updateHealth(
                    Number(params[0]),
                    Number(params[1]),
                    int(params[2]) > 0,
                    int(params[3]) > 0
                );
            }
        }
    }
}
