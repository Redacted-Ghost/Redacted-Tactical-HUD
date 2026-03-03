package loreout.ui {
    import flash.display.DisplayObjectContainer;
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.filters.GlowFilter;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;

    /**
     * UIPrimitives — LoreOut HUD design system.
     *
     * All visual elements are built from these primitives.
     * No exceptions. No imported bitmaps. No timeline animations.
     *
     * Scaleform GFx 4.x safe:
     *   - drawRect, drawCircle, moveTo/lineTo only (no drawRoundRect)
     *   - $MAIN_Font only (no _sans, no _serif)
     *   - State-driven property changes (alpha, scaleX/Y, glow)
     */
    public class UIPrimitives {

        // ---- GRID ----
        public static const GRID:int = 8;

        // ---- COLORS (uint) ----
        public static const COL_BG:uint       = 0x0A0A0A;   // charcoal panel fill
        public static const COL_BORDER:uint   = 0xCCCCCC;   // hairline border
        public static const COL_ACCENT:uint   = 0x33A5B3;   // teal accent (active state)
        public static const COL_WARN:uint     = 0xCC4422;   // warn/critical state
        public static const COL_TEXT_PRI:uint  = 0xE8E8E8;   // primary text
        public static const COL_TEXT_SEC:uint  = 0xAAAAAA;   // secondary/dim text
        public static const COL_TEXT_VAL:uint  = 0xFFFFFF;   // value readouts
        public static const COL_BAR_BG:uint   = 0x333333;   // bar background track
        public static const COL_BAR_FILL:uint = 0xCCCCCC;   // bar fill (normal)

        // ---- ALPHA ----
        public static const FILL_ALPHA:Number      = 0.42;
        public static const BORDER_ALPHA:Number    = 0.18;
        public static const TEXT_PRI_ALPHA:Number   = 0.92;
        public static const TEXT_SEC_ALPHA:Number   = 0.58;

        // ---- LINE WEIGHTS ----
        public static const LINE_HAIR:Number   = 1;
        public static const LINE_ACTIVE:Number = 2;

        // ---- CORNER RADII (for drawRect, no actual rounding) ----
        public static const RADIUS_S:int = 6;
        public static const RADIUS_M:int = 8;

        // ---- FONT ----
        public static const FONT:String = "$MAIN_Font";

        // ---- STATES ----
        public static const STATE_IDLE:int   = 0;
        public static const STATE_ACTIVE:int = 1;
        public static const STATE_WARN:int   = 2;

        // ================================================================
        // PANEL: translucent charcoal plate with hairline border
        // ================================================================
        public static function drawPanel(parent:DisplayObjectContainer,
                                          w:Number, h:Number,
                                          fillAlpha:Number = -1,
                                          borderAlpha:Number = -1):Shape {
            if (fillAlpha < 0) fillAlpha = FILL_ALPHA;
            if (borderAlpha < 0) borderAlpha = BORDER_ALPHA;

            var s:Shape = new Shape();
            s.graphics.lineStyle(LINE_HAIR, COL_BORDER, borderAlpha);
            s.graphics.beginFill(COL_BG, fillAlpha);
            s.graphics.drawRect(0, 0, w, h);
            s.graphics.endFill();
            parent.addChild(s);
            return s;
        }

        // ================================================================
        // DIVIDER: thin horizontal or vertical rule
        // ================================================================
        public static function drawDivider(parent:DisplayObjectContainer,
                                            x1:Number, y1:Number,
                                            x2:Number, y2:Number,
                                            alpha:Number = -1):Shape {
            if (alpha < 0) alpha = BORDER_ALPHA;
            var s:Shape = new Shape();
            s.graphics.lineStyle(LINE_HAIR, COL_BORDER, alpha);
            s.graphics.moveTo(x1, y1);
            s.graphics.lineTo(x2, y2);
            parent.addChild(s);
            return s;
        }

        // ================================================================
        // CORNER TICKS: subtle tech-feel corner marks
        // ================================================================
        public static function drawCornerTicks(parent:DisplayObjectContainer,
                                                w:Number, h:Number,
                                                tickLen:Number = 6,
                                                alpha:Number = -1):Shape {
            if (alpha < 0) alpha = BORDER_ALPHA * 1.5;
            var s:Shape = new Shape();
            var g:* = s.graphics;
            g.lineStyle(LINE_HAIR, COL_BORDER, alpha);

            // top-left
            g.moveTo(0, tickLen); g.lineTo(0, 0); g.lineTo(tickLen, 0);
            // top-right
            g.moveTo(w - tickLen, 0); g.lineTo(w, 0); g.lineTo(w, tickLen);
            // bottom-right
            g.moveTo(w, h - tickLen); g.lineTo(w, h); g.lineTo(w - tickLen, h);
            // bottom-left
            g.moveTo(tickLen, h); g.lineTo(0, h); g.lineTo(0, h - tickLen);

            parent.addChild(s);
            return s;
        }

        // ================================================================
        // LABEL: secondary text (headers, field names)
        // ================================================================
        public static function makeLabel(parent:DisplayObjectContainer,
                                          text:String, size:int = 11,
                                          alpha:Number = -1,
                                          color:uint = 0):TextField {
            if (alpha < 0) alpha = TEXT_SEC_ALPHA;
            if (color == 0) color = COL_TEXT_SEC;

            var fmt:TextFormat = new TextFormat();
            fmt.font = FONT;
            fmt.size = size;
            fmt.color = color;

            var tf:TextField = new TextField();
            tf.defaultTextFormat = fmt;
            tf.textColor = color;
            tf.alpha = alpha;
            tf.selectable = false;
            tf.mouseEnabled = false;
            tf.text = text;
            tf.width = tf.textWidth + 8;
            tf.height = tf.textHeight + 4;
            parent.addChild(tf);
            return tf;
        }

        // ================================================================
        // VALUE: primary readout text (numbers, status)
        // ================================================================
        public static function makeValue(parent:DisplayObjectContainer,
                                          text:String, size:int = 22,
                                          alpha:Number = -1,
                                          color:uint = 0):TextField {
            if (alpha < 0) alpha = TEXT_PRI_ALPHA;
            if (color == 0) color = COL_TEXT_VAL;

            var fmt:TextFormat = new TextFormat();
            fmt.font = FONT;
            fmt.size = size;
            fmt.color = color;

            var tf:TextField = new TextField();
            tf.defaultTextFormat = fmt;
            tf.textColor = color;
            tf.alpha = alpha;
            tf.selectable = false;
            tf.mouseEnabled = false;
            tf.text = text;
            tf.width = tf.textWidth + 8;
            tf.height = tf.textHeight + 4;
            parent.addChild(tf);
            return tf;
        }

        // ================================================================
        // BAR: thin horizontal progress/condition bar
        // ================================================================
        public static function drawBar(parent:DisplayObjectContainer,
                                        x:Number, y:Number,
                                        w:Number, h:Number,
                                        pct:Number,
                                        fillColor:uint = 0,
                                        bgColor:uint = 0):Sprite {
            if (fillColor == 0) fillColor = COL_BAR_FILL;
            if (bgColor == 0) bgColor = COL_BAR_BG;
            if (pct < 0) pct = 0;
            if (pct > 100) pct = 100;

            var bar:Sprite = new Sprite();
            bar.x = x;
            bar.y = y;

            // background track
            bar.graphics.beginFill(bgColor, 0.5);
            bar.graphics.drawRect(0, 0, w, h);
            bar.graphics.endFill();

            // fill
            if (pct > 0) {
                bar.graphics.beginFill(fillColor, 0.85);
                bar.graphics.drawRect(0, 0, w * (pct / 100), h);
                bar.graphics.endFill();
            }

            parent.addChild(bar);
            return bar;
        }

        // ================================================================
        // EYE ICON: stealth/awareness indicator (bezier curves)
        // ================================================================
        public static function drawEyeIcon(parent:DisplayObjectContainer,
                                            cx:Number, cy:Number,
                                            size:Number,
                                            color:uint,
                                            alpha:Number = 0.9):Shape {
            var s:Shape = new Shape();
            var g:* = s.graphics;
            var hw:Number = size * 0.5;    // half width
            var hh:Number = size * 0.28;   // half height (eye is ~1.8:1 aspect)

            // Outer eye shape — two quadratic bezier curves
            g.lineStyle(LINE_HAIR, color, alpha);

            // Top lid
            g.moveTo(cx - hw, cy);
            g.curveTo(cx, cy - hh * 2.2, cx + hw, cy);

            // Bottom lid
            g.moveTo(cx - hw, cy);
            g.curveTo(cx, cy + hh * 2.2, cx + hw, cy);

            // Iris (filled circle)
            g.lineStyle(0);
            g.beginFill(color, alpha * 0.65);
            g.drawCircle(cx, cy, hh * 0.85);
            g.endFill();

            // Pupil (dark center)
            g.beginFill(COL_BG, 0.95);
            g.drawCircle(cx, cy, hh * 0.35);
            g.endFill();

            parent.addChild(s);
            return s;
        }

        // ================================================================
        // STATE GLOW: apply glow filter based on state
        // ================================================================
        public static function applyState(target:*, state:int):void {
            switch (state) {
                case STATE_ACTIVE:
                    target.filters = [new GlowFilter(COL_ACCENT, 0.3, 4, 4, 1, 1)];
                    break;
                case STATE_WARN:
                    target.filters = [new GlowFilter(COL_WARN, 0.4, 6, 6, 1, 1)];
                    break;
                default:
                    target.filters = [];
            }
        }
    }
}
