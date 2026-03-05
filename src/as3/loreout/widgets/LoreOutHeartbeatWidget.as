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
     * LoreOut Heartbeat Widget v11 — Tactical panel ECG module.
     *
     * 192x56 with chamfered tactical panel, left chevron header,
     * tactical brackets, glowing heart icon, dotted baseline,
     * ECG trace with glow. Panel outline shifts: teal→amber→red.
     *
     * CMD 300 (floats): hpPercent, radPercent, isHealing, isTakingDmg
     */
    public class LoreOutHeartbeatWidget extends MovieClip implements IHUDWidget {

        private static const CMD_HEARTBEAT:int = 300;

        private static const PANEL_W:int = 300;
        private static const PANEL_H:int = 70;
        private static const PAD:int = 6;

        // ECG
        private static const TRACE_SAMPLES:int = 80;
        private static const SCROLL_SPEED:Number = 1.5;
        private static const BEAT_LEN:int = 40;

        // Cyber panel assembly
        private var cyberParts:Object;
        private var panelShape:Shape;
        private var headerParts:Object;
        private var heartIcon:Shape;
        private var baselineDots:Shape;

        // Content
        private var traceContainer:Sprite;
        private var hpValue:TextField;

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
            // === CYBER PANEL (all structural layers) ===
            cyberParts = UIPrimitives.buildCyberPanel(this, PANEL_W, PANEL_H,
                UIPrimitives.COL_ACCENT, "medium", true, "", "VIT-01");
            panelShape = cyberParts.panel as Shape;
            headerParts = cyberParts.header;

            var hdrY:Number = Number(cyberParts.headerY);
            var contentY:Number = Number(cyberParts.contentY);

            // Heart icon on header band — GLOWS (centered in 26px)
            heartIcon = UIPrimitives.drawHeartIcon(this, 14, hdrY + 13, 10, 0xFFFFFF, 0.85);
            UIPrimitives.applyNeonGlow(heartIcon, UIPrimitives.COL_ACCENT, 0.3);

            // "VITALS" label on header band (centered in 26px)
            var headerLabel:TextField = UIPrimitives.makeValue(this, "VITALS", 11, 0.95, 0xFFFFFF);
            headerLabel.x = 24;
            headerLabel.y = hdrY + 5;

            // HP percentage on header band (right side, centered in 26px)
            hpValue = UIPrimitives.makeValue(this, "100%", 13, 0.97, 0xFFFFFF);
            hpValue.x = PANEL_W - 54;
            hpValue.y = hdrY + 3;
            hpValue.width = 48;
            var hfmt:TextFormat = hpValue.defaultTextFormat;
            hfmt.align = TextFormatAlign.RIGHT;
            hpValue.defaultTextFormat = hfmt;
            hpValue.setTextFormat(hfmt);

            // Trace area dimensions
            traceY = contentY + 2;
            traceH = PANEL_H - contentY - 10;
            traceW = PANEL_W - PAD * 2;

            // Dotted baseline at center of trace
            baselineDots = new Shape();
            var baseY:Number = traceY + traceH * 0.5;
            var dg:* = baselineDots.graphics;
            dg.lineStyle(0);
            for (var i:int = 0; i < int(traceW / 4); i++) {
                dg.beginFill(UIPrimitives.COL_BORDER, 0.25);
                dg.drawCircle(PAD + i * 4 + 1, baseY, 0.7);
                dg.endFill();
            }
            addChild(baselineDots);

            // ECG trace container
            traceContainer = new Sprite();
            traceContainer.x = PAD;
            traceContainer.y = traceY;
            addChild(traceContainer);
        }

        // ================================================================
        // ENTER_FRAME
        // ================================================================
        private function onFrame(e:Event):void {
            frameCount++;

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
                sample = 0.5;
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

            if (radPercent > 10) {
                sample += (Math.random() - 0.5) * (radPercent / 100) * 0.08;
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
            if (isTakingDmg && hpPercent > 0) traceColor = UIPrimitives.COL_WARN;

            g.lineStyle(2, traceColor, traceAlpha);

            var readPos:int = writePos;
            var stepX:Number = traceW / (TRACE_SAMPLES - 1);

            for (var i:int = 0; i < TRACE_SAMPLES; i++) {
                var idx:int = (readPos + i) % TRACE_SAMPLES;
                var val:Number = Number(waveBuffer[idx]);
                var py:Number = (1.0 - val) * traceH - traceH * 0.5 + traceH * 0.5;
                var px:Number = i * stepX;
                if (i == 0) g.moveTo(px, py);
                else g.lineTo(px, py);
            }

            // Trace glow (on the trace, not the panel)
            traceContainer.filters = [new GlowFilter(traceColor, 0.40, 4, 4, 1.2, 1)];

            // Recolor cyber panel (grey frame stays, accent trim + header shift)
            var hdrAlpha:Number = (hpPercent < 25) ? 0.65 :
                (hpPercent < 50) ? 0.55 : 0.55;
            UIPrimitives.recolorCyberPanel(cyberParts, traceColor, hdrAlpha);

            // Recolor heart icon glow to match
            UIPrimitives.applyNeonGlow(heartIcon, traceColor,
                (hpPercent < 25) ? 0.5 : 0.3);

            // HP readout
            hpValue.text = int(hpPercent) + "%";
            var vfmt:TextFormat = hpValue.defaultTextFormat;
            vfmt.color = (hpPercent < 50) ? traceColor : 0xFFFFFF;
            vfmt.align = TextFormatAlign.RIGHT;
            hpValue.defaultTextFormat = vfmt;
            hpValue.setTextFormat(vfmt);
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
