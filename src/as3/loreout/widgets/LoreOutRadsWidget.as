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
     * LoreOut Rads Widget v12 — Concentric Ring Scanner.
     *
     * 160x160 square ring-centric design:
     *   - Outer tick ring (R=65, 36 ticks, major every 9th)
     *   - Data arc ring (R=56, 6px, 270deg sweep)
     *   - Rotating inner detail ring (R=46, 6 segmented arcs)
     *   - Innermost dotted ring (R=38, static)
     *   - Center readout + needle + Geiger jitter
     *   - Trefoil icon + rate indicator
     *
     * White/grey monochrome, red at >=75%.
     *
     * CMD 400 (floats): rads, maxRads, isTakingRads, radRate
     */
    public class LoreOutRadsWidget extends MovieClip implements IHUDWidget {

        private static const CMD_RADS:int = 400;

        private static const PANEL_W:int = 160;
        private static const PANEL_H:int = 160;

        // Ring geometry
        private static const ARC_START:Number = 135;
        private static const ARC_END:Number = 405;
        private static const ARC_SWEEP:Number = 270;

        // Ring radii
        private static const R_TICK:Number = 65;
        private static const R_DATA:Number = 56;
        private static const R_INNER:Number = 46;
        private static const R_DOT:Number = 38;

        // Center of rings (slightly below center for title space)
        private static const CX:Number = 80;
        private static const CY:Number = 88;

        // Elements
        private var panelBg:Shape;
        private var bgRing:Shape;
        private var fillRing:Shape;
        private var tickMarks:Shape;
        private var innerRingSp:Sprite;
        private var dotRing:Shape;
        private var needleContainer:Sprite;
        private var trefoilSp:Sprite;

        // Text
        private var radValue:TextField;
        private var radLabel:TextField;
        private var rateLabel:TextField;

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

        // Inner ring rotation
        private var innerRotation:Number = 0;

        public function LoreOutRadsWidget() {
            super();
            buildUI();
            addEventListener(Event.ENTER_FRAME, onFrame);
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

            // "RADIATION" label top-center
            var titleLabel:TextField = UIPrimitives.makeLabel(this,
                "RADIATION", 9, 0.50, UIPrimitives.COL_TEXT_SEC);
            titleLabel.width = PANEL_W;
            var tFmt:TextFormat = titleLabel.defaultTextFormat;
            tFmt.align = TextFormatAlign.CENTER;
            titleLabel.defaultTextFormat = tFmt;
            titleLabel.setTextFormat(tFmt);
            titleLabel.x = 0;
            titleLabel.y = 4;

            // Outer tick ring (36 ticks, major every 9th)
            tickMarks = UIPrimitives.drawRingTicks(this,
                CX, CY, R_TICK,
                ARC_START, ARC_END,
                36, 4, 2,
                UIPrimitives.COL_BORDER, 0.40, 9);

            // Background ring (dim arc at data radius)
            bgRing = UIPrimitives.drawRingArc(this,
                CX, CY, R_DATA,
                ARC_START, ARC_END,
                UIPrimitives.COL_FRAME, 0.20, 6, 48);

            // Fill ring (dynamic, redrawn each frame)
            fillRing = new Shape();
            addChild(fillRing);

            // Rotating inner detail ring (6 segmented arcs)
            innerRingSp = new Sprite();
            innerRingSp.x = CX;
            innerRingSp.y = CY;
            drawInnerDetailRing();
            addChild(innerRingSp);

            // Innermost dotted ring (static)
            dotRing = new Shape();
            var dg:* = dotRing.graphics;
            var dotCount:int = 48;
            for (var i:int = 0; i < dotCount; i++) {
                var angle:Number = (i / dotCount) * Math.PI * 2;
                dg.beginFill(UIPrimitives.COL_FRAME, 0.15);
                dg.drawCircle(CX + Math.cos(angle) * R_DOT,
                    CY + Math.sin(angle) * R_DOT, 0.7);
                dg.endFill();
            }
            addChild(dotRing);

            // Needle container
            needleContainer = new Sprite();
            addChild(needleContainer);

            // Center readout — value (22px, white)
            radValue = UIPrimitives.makeValue(this, "0", 22, 0.97, 0xFFFFFF);
            radValue.width = 60;
            radValue.x = CX - 30;
            radValue.y = CY - 16;
            var vfmt:TextFormat = radValue.defaultTextFormat;
            vfmt.align = TextFormatAlign.CENTER;
            radValue.defaultTextFormat = vfmt;
            radValue.setTextFormat(vfmt);

            // Center readout — "RAD" label (8px, grey)
            radLabel = UIPrimitives.makeLabel(this, "RAD", 8, 0.50,
                UIPrimitives.COL_TEXT_SEC);
            radLabel.width = 40;
            radLabel.x = CX - 20;
            radLabel.y = CY + 6;
            var lfmt:TextFormat = radLabel.defaultTextFormat;
            lfmt.align = TextFormatAlign.CENTER;
            radLabel.defaultTextFormat = lfmt;
            radLabel.setTextFormat(lfmt);

            // Trefoil icon (bottom-left corner)
            trefoilSp = new Sprite();
            drawTrefoil(trefoilSp, 16, PANEL_H - 14, 6);
            addChild(trefoilSp);

            // Rate indicator (right side, hidden by default)
            rateLabel = UIPrimitives.makeLabel(this, "", 8, 0.70,
                UIPrimitives.COL_TEXT_SEC);
            rateLabel.x = PANEL_W - 50;
            rateLabel.y = PANEL_H - 18;
            rateLabel.width = 46;
            rateLabel.visible = false;

            // Data tag below panel
            var tag:TextField = UIPrimitives.makeDataTag(this, "RAD-01", 8,
                UIPrimitives.COL_FRAME_LIGHT, 0.30);
            tag.x = PANEL_W * 0.5 - 20;
            tag.y = PANEL_H + 1;
        }

        // 6 segmented arcs with gaps (drawn at origin, sprite positioned at CX,CY)
        private function drawInnerDetailRing():void {
            var g:* = innerRingSp.graphics;
            g.clear();

            var segCount:int = 6;
            var gapDeg:Number = 8;
            var segSweep:Number = (360 - segCount * gapDeg) / segCount;

            g.lineStyle(1.5, UIPrimitives.COL_BORDER, 0.25);

            for (var seg:int = 0; seg < segCount; seg++) {
                var startDeg:Number = seg * (segSweep + gapDeg);
                var endDeg:Number = startDeg + segSweep;
                var steps:int = 12;

                for (var i:int = 0; i <= steps; i++) {
                    var t:Number = i / steps;
                    var angleDeg:Number = startDeg + t * (endDeg - startDeg);
                    var angleRad:Number = angleDeg * Math.PI / 180;
                    var px:Number = Math.cos(angleRad) * R_INNER;
                    var py:Number = Math.sin(angleRad) * R_INNER;
                    if (i == 0) g.moveTo(px, py);
                    else g.lineTo(px, py);
                }
            }
        }

        // Trefoil (radiation symbol) icon
        private function drawTrefoil(container:Sprite,
            cx:Number, cy:Number, radius:Number):void {
            var g:* = container.graphics;
            var col:uint = UIPrimitives.COL_BORDER;
            var r:Number = radius * 0.35;
            var dist:Number = radius * 0.45;

            g.beginFill(col, 0.5);
            g.drawCircle(cx, cy, r * 0.6);
            g.endFill();

            for (var i:int = 0; i < 3; i++) {
                var angle:Number = (i * 120 - 90) * Math.PI / 180;
                g.beginFill(col, 0.35);
                g.drawCircle(cx + Math.cos(angle) * dist,
                    cy + Math.sin(angle) * dist, r);
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

            // Geiger tick jitter
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

            // Rotate inner detail ring (speed scales with radiation)
            var rotSpeed:Number = 0.15;
            if (isTakingRads) rotSpeed = 1.2;
            else if (pct > 0.5) rotSpeed = 0.5;
            else if (pct > 0.25) rotSpeed = 0.3;
            innerRotation += rotSpeed;
            innerRingSp.rotation = innerRotation;

            drawFillRing(pct);
            drawNeedle(pct);
            drawStaticNoise(pct);
            updateReadout(pct);
        }

        // ================================================================
        // FILL RING (data arc — 6px thick, 270deg)
        // ================================================================
        private function drawFillRing(pct:Number):void {
            var g:* = fillRing.graphics;
            g.clear();
            if (pct <= 0) {
                fillRing.filters = [];
                return;
            }

            var col:uint = getRadColor(pct);
            var fillEnd:Number = ARC_START + pct * ARC_SWEEP;
            var startRad:Number = (ARC_START - 90) * Math.PI / 180;
            var endRad:Number = (fillEnd - 90) * Math.PI / 180;
            var steps:int = int(pct * 48);
            if (steps < 2) steps = 2;

            g.lineStyle(6, col, 0.85);
            for (var i:int = 0; i <= steps; i++) {
                var t:Number = i / steps;
                var angle:Number = startRad + t * (endRad - startRad);
                var px:Number = CX + Math.cos(angle) * R_DATA;
                var py:Number = CY + Math.sin(angle) * R_DATA;
                if (i == 0) g.moveTo(px, py);
                else g.lineTo(px, py);
            }

            // Glow: subtle at mid, strong red at high
            if (pct >= 0.75) {
                fillRing.filters = [new GlowFilter(col, 0.45, 6, 6, 1.5, 1)];
            } else if (pct > 0.3) {
                fillRing.filters = [new GlowFilter(col, 0.20, 4, 4, 1.0, 1)];
            } else {
                fillRing.filters = [];
            }
        }

        // ================================================================
        // NEEDLE (from inner ring to data ring)
        // ================================================================
        private function drawNeedle(pct:Number):void {
            var g:* = needleContainer.graphics;
            g.clear();

            var angleRad:Number = (needleCurrent - 90) * Math.PI / 180;
            var tipX:Number = CX + Math.cos(angleRad) * (R_DATA + 3);
            var tipY:Number = CY + Math.sin(angleRad) * (R_DATA + 3);
            var baseX:Number = CX + Math.cos(angleRad) * (R_DOT - 2);
            var baseY:Number = CY + Math.sin(angleRad) * (R_DOT - 2);
            var col:uint = getRadColor(pct);

            // Needle line
            g.lineStyle(1.5, col, 0.80);
            g.moveTo(baseX, baseY);
            g.lineTo(tipX, tipY);

            // Tip dot
            g.lineStyle();
            g.beginFill(col, 0.90);
            g.drawCircle(tipX, tipY, 2);
            g.endFill();

            // Center hub
            g.beginFill(UIPrimitives.COL_BORDER, 0.50);
            g.drawCircle(CX, CY, 2.5);
            g.endFill();
        }

        // ================================================================
        // STATIC NOISE (scattered dots when irradiated)
        // ================================================================
        private function drawStaticNoise(pct:Number):void {
            while (needleContainer.numChildren > 0) {
                needleContainer.removeChildAt(0);
            }
            if (!isTakingRads && pct < 0.3) return;

            var count:int = int(pct * 10);
            if (isTakingRads) count += 6;
            var ng:* = needleContainer.graphics;
            var startRad:Number = (ARC_START - 90) * Math.PI / 180;
            var endRad:Number = (ARC_END - 90) * Math.PI / 180;

            for (var i:int = 0; i < count; i++) {
                var t:Number = Math.random();
                var angle:Number = startRad + t * (endRad - startRad);
                var r:Number = R_DOT + Math.random() * (R_TICK - R_DOT);
                var dotAlpha:Number = 0.10 + Math.random() * 0.25;
                var dotColor:uint = (pct >= 0.75) ?
                    UIPrimitives.COL_WARN : UIPrimitives.COL_ACCENT;
                ng.lineStyle();
                ng.beginFill(dotColor, dotAlpha);
                ng.drawCircle(CX + Math.cos(angle) * r,
                    CY + Math.sin(angle) * r,
                    0.5 + Math.random() * 1.0);
                ng.endFill();
            }
        }

        // ================================================================
        // UPDATE READOUT
        // ================================================================
        private function updateReadout(pct:Number):void {
            var col:uint = getRadColor(pct);

            // Center value (pulses alpha when taking rads)
            var valAlpha:Number = 0.97;
            if (isTakingRads) {
                valAlpha = 0.6 + Math.sin(frameCount * 0.15) * 0.4;
            }
            radValue.text = String(int(currentRads));
            radValue.alpha = valAlpha;
            var vfmt:TextFormat = radValue.defaultTextFormat;
            vfmt.color = col;
            vfmt.align = TextFormatAlign.CENTER;
            radValue.defaultTextFormat = vfmt;
            radValue.setTextFormat(vfmt);

            // Rate indicator (appears when taking rads)
            if (isTakingRads && radRate > 0) {
                rateLabel.visible = true;
                rateLabel.text = "+" + radRate.toFixed(1) + "/s";
                var rfmt:TextFormat = rateLabel.defaultTextFormat;
                rfmt.color = col;
                rateLabel.defaultTextFormat = rfmt;
                rateLabel.setTextFormat(rfmt);
            } else {
                rateLabel.visible = false;
            }
        }

        // White < 50%, grey 50-75%, red >= 75%
        private function getRadColor(pct:Number):uint {
            if (pct >= 0.75) return UIPrimitives.COL_WARN;
            if (pct >= 0.50) return UIPrimitives.COL_AMBER;
            return UIPrimitives.COL_ACCENT;
        }

        // ================================================================
        // UPDATE DATA
        // ================================================================
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
