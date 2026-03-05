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
     * LoreOut Rads Widget v11 — Tactical panel radiation module.
     *
     * 192x96 chamfered tactical panel with teal accent,
     * centered 270-degree ring gauge, header band inside,
     * Geiger needle, static noise, DNA helix.
     * Panel outline shifts: teal(low) → amber(mid) → red(high).
     *
     * CMD 400 (floats): rads, maxRads, isTakingRads, radRate
     */
    public class LoreOutRadsWidget extends MovieClip implements IHUDWidget {

        private static const CMD_RADS:int = 400;

        private static const PANEL_W:int = 300;
        private static const PANEL_H:int = 110;

        // Ring gauge geometry
        private static const ARC_START:Number = 135;
        private static const ARC_END:Number = 405;
        private static const ARC_SWEEP:Number = 270;

        // Cyber panel assembly
        private var cyberParts:Object;
        private var panelShape:Shape;
        private var headerParts:Object;
        private var radIconSp:Sprite;

        // Gauge elements
        private var bgRing:Shape;
        private var fillRing:Shape;
        private var innerRing:Shape;
        private var tickMarks:Shape;
        private var needleContainer:Sprite;
        private var microBarStrip:Sprite;

        // Content
        private var radValue:TextField;
        private var radLabel:TextField;

        // State
        private var currentRads:Number = 0;
        private var maxRads:Number = 1000;
        private var isTakingRads:Boolean = false;
        private var radRate:Number = 0;

        // Needle animation
        private var needleCurrent:Number = 135;
        private var tickJitter:Number = 0;
        private var tickTimer:int = 0;
        private var tickCooldown:int = 60;
        private var frameCount:int = 0;

        // DNA helix
        private var dnaContainer:Sprite;
        private var dnaPhase:Number = 0;
        private static const DNA_SPEED:Number = 0.03;

        // Ring center + radius
        private var ringCX:Number = 0;
        private var ringCY:Number = 0;
        private var ringR:Number = 0;
        private var innerR:Number = 0;

        public function LoreOutRadsWidget() {
            super();
            buildUI();
            addEventListener(Event.ENTER_FRAME, onFrame);
        }

        private function buildUI():void {
            // === CYBER PANEL (all structural layers) ===
            cyberParts = UIPrimitives.buildCyberPanel(this, PANEL_W, PANEL_H,
                UIPrimitives.COL_ACCENT, "full", true, "RADIATION", "RAD-01");
            panelShape = cyberParts.panel as Shape;
            headerParts = cyberParts.header;

            var contentY:Number = Number(cyberParts.contentY);

            // Trefoil icon on header — GLOWS (centered in 26px band)
            radIconSp = new Sprite();
            drawRadIcon(radIconSp, PANEL_W - 24, 15, 7);
            addChild(radIconSp);
            UIPrimitives.applyNeonGlow(radIconSp, UIPrimitives.COL_ACCENT, 0.3);

            // === RING GAUGE (bigger, readable) ===
            var availH:Number = PANEL_H - contentY - 4;
            ringR = (availH * 0.48);
            if (ringR > 38) ringR = 38;
            innerR = ringR - 7;
            ringCX = PANEL_W * 0.30;
            ringCY = contentY + availH * 0.52;

            bgRing = UIPrimitives.drawRingArc(this,
                ringCX, ringCY, ringR,
                ARC_START, ARC_END,
                UIPrimitives.COL_FRAME_LIGHT, 0.35, 6, 48);

            innerRing = UIPrimitives.drawRingArc(this,
                ringCX, ringCY, innerR,
                ARC_START, ARC_END,
                UIPrimitives.COL_BORDER, 0.20, 1.5, 48);

            tickMarks = UIPrimitives.drawRingTicks(this,
                ringCX, ringCY, ringR,
                ARC_START, ARC_END,
                27, 4, 2,
                UIPrimitives.COL_FRAME_LIGHT, 0.50, 9);

            fillRing = new Shape();
            addChild(fillRing);

            needleContainer = new Sprite();
            addChild(needleContainer);

            // === CENTER READOUT (bigger, readable) ===
            radValue = UIPrimitives.makeValue(this, "0", 22, 0.97, UIPrimitives.COL_ACCENT);
            radValue.width = 60;
            radValue.x = ringCX - 30;
            radValue.y = ringCY - 16;
            var vfmt:TextFormat = radValue.defaultTextFormat;
            vfmt.align = TextFormatAlign.CENTER;
            radValue.defaultTextFormat = vfmt;
            radValue.setTextFormat(vfmt);

            radLabel = UIPrimitives.makeLabel(this, "RAD", 9, 0.65, UIPrimitives.COL_ACCENT);
            radLabel.width = 40;
            radLabel.x = ringCX - 20;
            radLabel.y = ringCY + 6;
            var lfmt:TextFormat = radLabel.defaultTextFormat;
            lfmt.align = TextFormatAlign.CENTER;
            radLabel.defaultTextFormat = lfmt;
            radLabel.setTextFormat(lfmt);

            // Center hub dot
            var hub:Shape = new Shape();
            hub.graphics.beginFill(UIPrimitives.COL_BORDER, 0.4);
            hub.graphics.drawCircle(ringCX, ringCY, 2);
            hub.graphics.endFill();
            addChild(hub);

            // === MICRO BAR STRIP (right side) ===
            var barX:Number = ringCX + ringR + 12;
            microBarStrip = UIPrimitives.drawMicroBarStrip(this,
                barX, contentY + 6,
                12, 3, availH - 14, 2, 0,
                UIPrimitives.COL_ACCENT, UIPrimitives.COL_BAR_BG, 0.65);

            // DNA helix container
            dnaContainer = new Sprite();
            addChild(dnaContainer);
            setChildIndex(dnaContainer, getChildIndex(bgRing));

        }

        private function drawRadIcon(container:Sprite, cx:Number, cy:Number, radius:Number):void {
            var g:* = container.graphics;
            var col:uint = 0xFFFFFF;
            var r:Number = radius * 0.35;
            var dist:Number = radius * 0.45;
            g.beginFill(col, 0.7);
            g.drawCircle(cx, cy, r * 0.6);
            g.endFill();
            for (var i:int = 0; i < 3; i++) {
                var angle:Number = (i * 120 - 90) * Math.PI / 180;
                g.beginFill(col, 0.5);
                g.drawCircle(cx + Math.cos(angle) * dist, cy + Math.sin(angle) * dist, r);
                g.endFill();
            }
        }

        // ================================================================
        // ENTER_FRAME
        // ================================================================
        private function onFrame(e:Event):void {
            frameCount++;

            var pct:Number = (maxRads > 0) ? currentRads / maxRads : 0;
            if (pct > 1) pct = 1;
            if (pct < 0) pct = 0;

            var needleTarget:Number = ARC_START + pct * ARC_SWEEP;

            // Geiger tick
            tickTimer++;
            if (isTakingRads) tickCooldown = 3 + int(Math.random() * 5);
            else if (pct > 0.75) tickCooldown = 8 + int(Math.random() * 12);
            else if (pct > 0.50) tickCooldown = 15 + int(Math.random() * 25);
            else if (pct > 0.25) tickCooldown = 30 + int(Math.random() * 40);
            else if (pct > 0.05) tickCooldown = 50 + int(Math.random() * 60);
            else tickCooldown = 120 + int(Math.random() * 90);

            if (tickTimer >= tickCooldown) {
                tickTimer = 0;
                tickJitter = (Math.random() - 0.5) * (3 + pct * 12);
            }
            tickJitter *= 0.85;

            needleCurrent += (needleTarget + tickJitter - needleCurrent) * 0.15;
            if (needleCurrent < ARC_START - 5) needleCurrent = ARC_START - 5;
            if (needleCurrent > ARC_END + 5) needleCurrent = ARC_END + 5;

            dnaPhase += DNA_SPEED * (1 + pct * 3 + (isTakingRads ? 3 : 0));

            drawFillRing(pct);
            drawNeedle(pct);
            drawStaticNoise(pct);
            drawDNA(pct);
            updateMicroBar(pct);
            updateReadout(pct);
        }

        // ================================================================
        // FILL RING — GLOWS (glow on the gauge, not the panel)
        // ================================================================
        private function drawFillRing(pct:Number):void {
            var g:* = fillRing.graphics;
            g.clear();
            if (pct <= 0) return;

            var col:uint = getRadColor(pct);
            var fillEnd:Number = ARC_START + pct * ARC_SWEEP;
            var startRad:Number = (ARC_START - 90) * Math.PI / 180;
            var endRad:Number = (fillEnd - 90) * Math.PI / 180;
            var steps:int = int(pct * 48);
            if (steps < 2) steps = 2;

            g.lineStyle(5, col, 0.85);
            for (var i:int = 0; i <= steps; i++) {
                var t:Number = i / steps;
                var angle:Number = startRad + t * (endRad - startRad);
                var px:Number = ringCX + Math.cos(angle) * ringR;
                var py:Number = ringCY + Math.sin(angle) * ringR;
                if (i == 0) g.moveTo(px, py);
                else g.lineTo(px, py);
            }

            if (pct > 0.3) {
                fillRing.filters = [new GlowFilter(col, 0.45, 6, 6, 1.5, 1)];
            } else {
                fillRing.filters = [];
            }
        }

        // ================================================================
        // NEEDLE
        // ================================================================
        private function drawNeedle(pct:Number):void {
            var g:* = needleContainer.graphics;
            g.clear();

            var angleRad:Number = (needleCurrent - 90) * Math.PI / 180;
            var tipX:Number = ringCX + Math.cos(angleRad) * (ringR - 3);
            var tipY:Number = ringCY + Math.sin(angleRad) * (ringR - 3);
            var col:uint = getRadColor(pct);

            g.lineStyle(2, col, 0.95);
            g.moveTo(ringCX, ringCY);
            g.lineTo(tipX, tipY);

            g.lineStyle(0);
            g.beginFill(col, 0.90);
            g.drawCircle(tipX, tipY, 2.5);
            g.endFill();
        }

        // ================================================================
        // STATIC NOISE
        // ================================================================
        private function drawStaticNoise(pct:Number):void {
            while (needleContainer.numChildren > 0) {
                needleContainer.removeChildAt(0);
            }
            if (!isTakingRads && pct < 0.3) return;

            var count:int = int(pct * 12);
            if (isTakingRads) count += 8;
            var ng:* = needleContainer.graphics;
            var startRad:Number = (ARC_START - 90) * Math.PI / 180;
            var endRad:Number = (ARC_END - 90) * Math.PI / 180;

            for (var i:int = 0; i < count; i++) {
                var t:Number = Math.random();
                var angle:Number = startRad + t * (endRad - startRad);
                var r:Number = ringR * (0.3 + Math.random() * 0.7);
                var dotAlpha:Number = 0.15 + Math.random() * 0.35;
                var dotColor:uint = (Math.random() > 0.5) ? UIPrimitives.COL_WARN : UIPrimitives.COL_AMBER;
                ng.lineStyle(0);
                ng.beginFill(dotColor, dotAlpha);
                ng.drawCircle(ringCX + Math.cos(angle) * r,
                    ringCY + Math.sin(angle) * r,
                    0.5 + Math.random() * 1.2);
                ng.endFill();
            }
        }

        // ================================================================
        // DNA HELIX — GLOWS
        // ================================================================
        private function drawDNA(pct:Number):void {
            var g:* = dnaContainer.graphics;
            g.clear();

            var col:uint = getRadColor(pct);
            var dnaAlpha:Number = 0.12 + pct * 0.50;

            var dnaX:Number = ringCX + ringR + 14;
            var dnaTopY:Number = 24;
            var dnaBotY:Number = PANEL_H - 8;
            var dnaH:Number = dnaBotY - dnaTopY;
            var dnaW:Number = 20;
            var steps:int = 40;
            var rungEvery:int = 3;
            var twists:Number = 4;

            var s1x:Array = [];
            var s1y:Array = [];
            var s2x:Array = [];
            var s2y:Array = [];

            for (var i:int = 0; i <= steps; i++) {
                var t:Number = i / steps;
                var y:Number = dnaTopY + t * dnaH;
                var angle:Number = dnaPhase + t * Math.PI * 2 * twists;
                var x1:Number = dnaX + Math.sin(angle) * dnaW * 0.5;
                var x2:Number = dnaX + Math.sin(angle + Math.PI) * dnaW * 0.5;
                s1x.push(x1); s1y.push(y);
                s2x.push(x2); s2y.push(y);
            }

            g.lineStyle(2, col, dnaAlpha);
            g.moveTo(Number(s1x[0]), Number(s1y[0]));
            for (i = 1; i <= steps; i++) {
                g.lineTo(Number(s1x[i]), Number(s1y[i]));
            }

            g.lineStyle(2, col, dnaAlpha * 0.65);
            g.moveTo(Number(s2x[0]), Number(s2y[0]));
            for (i = 1; i <= steps; i++) {
                g.lineTo(Number(s2x[i]), Number(s2y[i]));
            }

            for (i = 0; i <= steps; i += rungEvery) {
                var rungAlpha:Number = dnaAlpha * 0.35;
                var rungAngle:Number = dnaPhase + (i / steps) * Math.PI * 2 * twists;
                var depth:Number = Math.abs(Math.cos(rungAngle));
                if (depth > 0.3) {
                    g.lineStyle(1, col, rungAlpha * depth);
                    g.moveTo(Number(s1x[i]), Number(s1y[i]));
                    g.lineTo(Number(s2x[i]), Number(s2y[i]));
                    g.lineStyle(0);
                    g.beginFill(col, rungAlpha * depth * 1.5);
                    g.drawCircle(Number(s1x[i]), Number(s1y[i]), 1.5);
                    g.endFill();
                    g.beginFill(col, rungAlpha * depth * 1.5);
                    g.drawCircle(Number(s2x[i]), Number(s2y[i]), 1.5);
                    g.endFill();
                }
            }

            if (pct > 0.15) {
                dnaContainer.filters = [new GlowFilter(col, 0.2 + pct * 0.4, 4, 4, 1.2, 1)];
            } else {
                dnaContainer.filters = [];
            }
        }

        // ================================================================
        // UPDATE MICRO BAR
        // ================================================================
        private function updateMicroBar(pct:Number):void {
            if (microBarStrip && microBarStrip.parent) microBarStrip.parent.removeChild(microBarStrip);

            var barX:Number = ringCX + ringR + 12;
            var contentY:Number = 22;
            var availH:Number = PANEL_H - contentY - 4;
            var col:uint = getRadColor(pct);

            microBarStrip = UIPrimitives.drawMicroBarStrip(this,
                barX, contentY + 6,
                12, 3, availH - 14, 2, pct * 100,
                col, UIPrimitives.COL_BAR_BG, 0.65);
        }

        // ================================================================
        // UPDATE READOUT
        // ================================================================
        private function updateReadout(pct:Number):void {
            var col:uint = getRadColor(pct);

            // Recolor cyber panel (grey frame stays, accent trim + header shift)
            var hdrAlpha:Number = (pct > 0.75) ? 0.65 : 0.55;
            UIPrimitives.recolorCyberPanel(cyberParts, col, hdrAlpha);

            // Recolor trefoil icon glow
            UIPrimitives.applyNeonGlow(radIconSp, col, (pct > 0.5) ? 0.5 : 0.3);

            // Rad value
            var valAlpha:Number = 0.97;
            if (isTakingRads) valAlpha = 0.6 + Math.sin(frameCount * 0.15) * 0.4;
            radValue.text = String(int(currentRads));
            radValue.alpha = valAlpha;
            var vfmt:TextFormat = radValue.defaultTextFormat;
            vfmt.color = col;
            vfmt.align = TextFormatAlign.CENTER;
            radValue.defaultTextFormat = vfmt;
            radValue.setTextFormat(vfmt);

            var lfmt:TextFormat = radLabel.defaultTextFormat;
            lfmt.color = col;
            lfmt.align = TextFormatAlign.CENTER;
            radLabel.defaultTextFormat = lfmt;
            radLabel.setTextFormat(lfmt);
        }

        private function getRadColor(pct:Number):uint {
            if (pct < 0.25) return UIPrimitives.COL_ACCENT;
            if (pct < 0.50) return 0x88CC22;
            if (pct < 0.75) return UIPrimitives.COL_AMBER;
            return UIPrimitives.COL_WARN;
        }

        private function updateRads(rads:Number, maxR:Number,
                                     taking:Boolean, rate:Number):void {
            currentRads = rads;
            if (maxR > 0) maxRads = maxR;
            isTakingRads = taking;
            radRate = rate;
            if (currentRads < 0) currentRads = 0;
        }

        public function processMessage(command:String, params:Array):void {
            var cmd:int = parseInt(command);
            if (cmd == CMD_RADS && params && params.length >= 4) {
                updateRads(Number(params[0]), Number(params[1]),
                    int(params[2]) > 0, Number(params[3]));
            }
        }
    }
}
