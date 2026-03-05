package loreout.ui {
    import flash.display.DisplayObjectContainer;
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.filters.DropShadowFilter;
    import flash.filters.GlowFilter;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;

    /**
     * UIPrimitives v12 — LoreOut HUD monochrome design system.
     *
     * White/grey monochrome palette with red for danger only.
     * Elaborate detail: corner brackets, grid patterns, ring gauges.
     * Simple rectangular panels with thin borders.
     *
     * Scaleform GFx 4.x safe:
     *   - drawRect, drawCircle, moveTo/lineTo/curveTo only
     *   - $MAIN_Font only
     *   - GlowFilter / DropShadowFilter
     */
    public class UIPrimitives {

        // ---- GRID ----
        public static const GRID:int = 8;

        // ---- COLORS — Monochrome palette ----
        public static const COL_BG:uint         = 0x0D0D12;   // near-black panel fill
        public static const COL_BORDER:uint     = 0x667788;   // dark grey structural
        public static const COL_ACCENT:uint     = 0xE8E8E8;   // white (primary data)
        public static const COL_GREEN:uint      = 0xE8E8E8;   // alias
        public static const COL_BLUE:uint       = 0xE8E8E8;   // alias
        public static const COL_AMBER:uint      = 0x8899AA;   // grey (was amber)
        public static const COL_ORANGE:uint     = 0x8899AA;   // alias
        public static const COL_WARN:uint       = 0xE53935;   // red (danger — only color)
        public static const COL_TEXT_PRI:uint   = 0xE8E8E8;   // bright text
        public static const COL_TEXT_SEC:uint   = 0x8899AA;   // dim text
        public static const COL_TEXT_VAL:uint   = 0xFFFFFF;   // value readouts
        public static const COL_BAR_BG:uint     = 0x1A1A22;   // bar background
        public static const COL_BAR_FILL:uint   = 0xBBBBBB;   // bar fill default
        public static const COL_FRAME:uint      = 0x334455;   // structural frame
        public static const COL_FRAME_LIGHT:uint = 0x667788;  // panel borders

        // ---- LINE WEIGHT TIERS ----
        public static const W_PRIMARY:Number   = 3;
        public static const W_SECONDARY:Number = 2;
        public static const W_TERTIARY:Number  = 1;

        // ---- HEADER BAND ----
        public static const HEADER_BAND_H:int = 26;

        // ---- FONT ----
        public static const FONT:String = "$MAIN_Font";

        // ---- STATES ----
        public static const STATE_IDLE:int   = 0;
        public static const STATE_ACTIVE:int = 1;
        public static const STATE_WARN:int   = 2;

        // ---- TEXT SHADOW ----
        private static var _textShadow:DropShadowFilter;
        public static function get TEXT_SHADOW():DropShadowFilter {
            if (!_textShadow) {
                _textShadow = new DropShadowFilter(0, 0, 0x000000, 0.7, 4, 4, 2, 1);
            }
            return _textShadow;
        }

        // ================================================================
        // CYBER PANEL BUILDER: rectangular panel with corner brackets
        // ================================================================
        public static function buildCyberPanel(
            parent:DisplayObjectContainer,
            w:Number, h:Number,
            accent:uint,
            style:String = "full",
            hasHeader:Boolean = true,
            headerLabel:String = "",
            tag:String = ""):Object {

            var result:Object = {};
            var isSlim:Boolean = (style == "slim");
            if (isSlim) hasHeader = false;
            var pad:Number = 6;

            result.w = w;
            result.h = h;
            result.style = style;

            // L1: Panel shape (simple rectangle)
            var panelShape:Shape = new Shape();
            _drawCyberPanelGfx(panelShape.graphics, w, h, accent, style);
            parent.addChild(panelShape);
            result.panel = panelShape;

            // L2: Corner brackets (thin white L-brackets)
            if (!isSlim) {
                drawCornerBrackets(parent, w, h, 8, COL_ACCENT, 0.35);
            }

            // L3: Header divider (thin grey line, no colored band)
            result.header = null;
            result.headerY = 2;
            var contentTop:Number = pad;

            if (hasHeader) {
                var headerDivY:Number = HEADER_BAND_H + 2;
                var divLine:Shape = new Shape();
                divLine.graphics.lineStyle(1, COL_BORDER, 0.40);
                divLine.graphics.moveTo(pad, headerDivY);
                divLine.graphics.lineTo(w - pad, headerDivY);
                parent.addChild(divLine);

                result.header = {band: null, divider: divLine};
                result.headerY = 2;
                contentTop = HEADER_BAND_H + 5;
            }

            // Content zone
            result.contentX = pad;
            result.contentY = contentTop;
            result.contentW = w - pad * 2;
            result.contentH = h - contentTop - pad;

            // Data tag below panel
            if (tag.length > 0) {
                var tagField:TextField = makeDataTag(parent, tag, 8,
                    COL_FRAME_LIGHT, 0.30);
                tagField.x = 20;
                tagField.y = h + 1;
            }

            return result;
        }

        // ================================================================
        // RECOLOR CYBER PANEL
        // ================================================================
        public static function recolorCyberPanel(
            parts:Object, accent:uint,
            headerAlpha:Number = 0.55):void {

            if (!parts) return;

            if (parts.panel) {
                var g:* = (parts.panel as Shape).graphics;
                g.clear();
                _drawCyberPanelGfx(g,
                    Number(parts.w), Number(parts.h),
                    accent, String(parts.style));
                (parts.panel as Shape).filters = [];
            }
        }

        // Internal: simple rectangle panel
        private static function _drawCyberPanelGfx(
            g:*, w:Number, h:Number,
            accent:uint, style:String):void {

            var wi:int = int(w);
            var hi:int = int(h);

            // Fill
            g.beginFill(COL_BG, 0.85);
            g.drawRect(0, 0, wi, hi);
            g.endFill();

            // 1px border
            g.lineStyle(1, COL_BORDER, 0.40);
            g.drawRect(0, 0, wi, hi);
        }

        // ================================================================
        // CORNER BRACKETS: thin L-brackets at 4 corners
        // ================================================================
        public static function drawCornerBrackets(
            parent:DisplayObjectContainer,
            w:Number, h:Number,
            size:Number = 8,
            color:uint = 0,
            alpha:Number = 0.35):Shape {

            if (color == 0) color = COL_ACCENT;
            var s:Shape = new Shape();
            var g:* = s.graphics;

            g.lineStyle(W_TERTIARY, color, alpha);
            // Top-left
            g.moveTo(0, size); g.lineTo(0, 0); g.lineTo(size, 0);
            // Top-right
            g.moveTo(w - size, 0); g.lineTo(w, 0); g.lineTo(w, size);
            // Bottom-right
            g.moveTo(w, h - size); g.lineTo(w, h); g.lineTo(w - size, h);
            // Bottom-left
            g.moveTo(size, h); g.lineTo(0, h); g.lineTo(0, h - size);

            parent.addChild(s);
            return s;
        }

        // ================================================================
        // GRID PATTERN: faint grid lines for monitor backgrounds
        // ================================================================
        public static function drawGridPattern(
            parent:DisplayObjectContainer,
            x:Number, y:Number,
            w:Number, h:Number,
            spacingX:Number = 24,
            spacingY:Number = 0,
            color:uint = 0,
            alpha:Number = 0.06):Shape {

            if (color == 0) color = COL_FRAME;
            if (spacingY <= 0) spacingY = spacingX;
            var s:Shape = new Shape();
            var g:* = s.graphics;

            // Vertical lines
            g.lineStyle(0.5, color, alpha);
            for (var vx:Number = x; vx <= x + w; vx += spacingX) {
                g.moveTo(vx, y);
                g.lineTo(vx, y + h);
            }

            // Horizontal center line (dotted style via short segments)
            var centerY:Number = y + h * 0.5;
            g.lineStyle(0.5, color, alpha * 1.5);
            for (var dx:Number = x; dx < x + w; dx += 4) {
                g.moveTo(dx, centerY);
                g.lineTo(dx + 2, centerY);
            }

            parent.addChild(s);
            return s;
        }

        // ================================================================
        // STATUS BADGE: text in thin bordered box
        // ================================================================
        public static function drawStatusBadge(
            parent:DisplayObjectContainer,
            text:String,
            x:Number, y:Number,
            color:uint,
            alpha:Number = 0.85):Sprite {

            var sp:Sprite = new Sprite();
            sp.x = x; sp.y = y;

            var fmt:TextFormat = new TextFormat();
            fmt.font = FONT; fmt.size = 9; fmt.color = color;
            fmt.letterSpacing = 1;

            var tf:TextField = new TextField();
            tf.defaultTextFormat = fmt;
            tf.textColor = color;
            tf.alpha = alpha;
            tf.selectable = false;
            tf.mouseEnabled = false;
            tf.text = text;
            tf.width = tf.textWidth + 12;
            tf.height = tf.textHeight + 6;
            tf.x = 0; tf.y = -2;

            var badgeW:Number = tf.textWidth + 14;
            var badgeH:Number = tf.textHeight + 8;

            // Border box
            var bg:Shape = new Shape();
            bg.graphics.lineStyle(1, color, alpha * 0.5);
            bg.graphics.beginFill(COL_BG, 0.4);
            bg.graphics.drawRect(0, 0, badgeW, badgeH);
            bg.graphics.endFill();

            sp.addChild(bg);
            sp.addChild(tf);

            parent.addChild(sp);
            return sp;
        }

        // ================================================================
        // DIVIDER LINE: separator with optional terminus dots
        // ================================================================
        public static function drawDividerLine(
            parent:DisplayObjectContainer,
            x:Number, y:Number,
            w:Number, color:uint,
            alpha:Number = 0.30,
            thickness:Number = 0.5,
            terminusDots:Boolean = true,
            dotRadius:Number = 1.5):Shape {

            var s:Shape = new Shape();
            var g:* = s.graphics;

            g.lineStyle(thickness, color, alpha);
            g.moveTo(x, y);
            g.lineTo(x + w, y);

            if (terminusDots) {
                g.lineStyle();
                g.beginFill(color, alpha * 1.5);
                g.drawCircle(x, y, dotRadius);
                g.drawCircle(x + w, y, dotRadius);
                g.endFill();
            }

            parent.addChild(s);
            return s;
        }

        // ================================================================
        // RING ARC: arc segment for ring gauges
        // ================================================================
        public static function drawRingArc(
            parent:DisplayObjectContainer,
            cx:Number, cy:Number,
            radius:Number,
            startAngle:Number, endAngle:Number,
            color:uint, alpha:Number = 0.80,
            thickness:Number = 5,
            steps:int = 48):Shape {

            var s:Shape = new Shape();
            var g:* = s.graphics;
            g.lineStyle(thickness, color, alpha);

            var startRad:Number = (startAngle - 90) * Math.PI / 180;
            var endRad:Number = (endAngle - 90) * Math.PI / 180;

            for (var i:int = 0; i <= steps; i++) {
                var t:Number = i / steps;
                var angle:Number = startRad + t * (endRad - startRad);
                var px:Number = cx + Math.cos(angle) * radius;
                var py:Number = cy + Math.sin(angle) * radius;
                if (i == 0) g.moveTo(px, py);
                else g.lineTo(px, py);
            }

            parent.addChild(s);
            return s;
        }

        // ================================================================
        // RING TICKS: tick marks around a ring
        // ================================================================
        public static function drawRingTicks(
            parent:DisplayObjectContainer,
            cx:Number, cy:Number,
            radius:Number,
            startAngle:Number, endAngle:Number,
            tickCount:int, innerLen:Number, outerLen:Number,
            color:uint, alpha:Number = 0.35,
            majorEvery:int = 5):Shape {

            var s:Shape = new Shape();
            var g:* = s.graphics;

            for (var i:int = 0; i <= tickCount; i++) {
                var tVal:Number = i / tickCount;
                var angleDeg:Number = startAngle + tVal * (endAngle - startAngle);
                var angleRad:Number = (angleDeg - 90) * Math.PI / 180;
                var isMajor:Boolean = (i % majorEvery == 0);
                var inner:Number = radius - (isMajor ? innerLen * 1.5 : innerLen);
                var outer:Number = radius + outerLen;

                g.lineStyle(isMajor ? W_SECONDARY : W_TERTIARY, color,
                    isMajor ? alpha * 1.5 : alpha);
                g.moveTo(cx + Math.cos(angleRad) * inner,
                         cy + Math.sin(angleRad) * inner);
                g.lineTo(cx + Math.cos(angleRad) * outer,
                         cy + Math.sin(angleRad) * outer);
            }

            parent.addChild(s);
            return s;
        }

        // ================================================================
        // SEGMENTED BAR
        // ================================================================
        public static function drawSegmentedBar(
            parent:DisplayObjectContainer,
            x:Number, y:Number,
            w:Number, h:Number,
            pct:Number,
            segments:int = 10,
            fillColor:uint = 0,
            bgColor:uint = 0):Sprite {

            if (fillColor == 0) fillColor = COL_BAR_FILL;
            if (bgColor == 0) bgColor = COL_BAR_BG;
            if (pct < 0) pct = 0;
            if (pct > 100) pct = 100;

            var bar:Sprite = new Sprite();
            bar.x = x; bar.y = y;
            var gap:Number = 1;
            var segW:Number = (w - (segments - 1) * gap) / segments;
            var fillCount:int = int(Math.ceil(pct / 100 * segments));

            for (var i:int = 0; i < segments; i++) {
                var sx:Number = i * (segW + gap);
                var isFilled:Boolean = (i < fillCount);
                bar.graphics.beginFill(isFilled ? fillColor : bgColor,
                    isFilled ? 0.85 : 0.30);
                bar.graphics.drawRect(sx, 0, segW, h);
                bar.graphics.endFill();
            }

            // Separator ticks
            bar.graphics.lineStyle(0.5, 0xFFFFFF, 0.06);
            for (var j:int = 1; j < segments; j++) {
                var tx:Number = j * (segW + gap) - gap * 0.5;
                bar.graphics.moveTo(tx, 0);
                bar.graphics.lineTo(tx, h);
            }

            parent.addChild(bar);
            return bar;
        }

        // ================================================================
        // MICRO BAR STRIP
        // ================================================================
        public static function drawMicroBarStrip(
            parent:DisplayObjectContainer,
            x:Number, y:Number,
            count:int, barW:Number, barMaxH:Number,
            spacing:Number, pct:Number,
            color:uint, bgColor:uint = 0,
            alpha:Number = 0.70):Sprite {

            if (bgColor == 0) bgColor = COL_BAR_BG;
            var sp:Sprite = new Sprite();
            sp.x = x; sp.y = y;
            var g:* = sp.graphics;
            var fillCount:int = int(Math.ceil((pct / 100) * count));
            if (fillCount > count) fillCount = count;

            for (var i:int = 0; i < count; i++) {
                var sx:Number = i * (barW + spacing);
                var filled:Boolean = (i < fillCount);
                g.beginFill(filled ? color : bgColor, filled ? alpha : 0.25);
                g.drawRect(sx, 0, barW, barMaxH);
                g.endFill();
            }
            parent.addChild(sp);
            return sp;
        }

        // ================================================================
        // SIGNAL BARS: 4-bar strength indicator
        // ================================================================
        public static function drawSignalBars(
            parent:DisplayObjectContainer,
            x:Number, y:Number,
            level:int, maxLevel:int,
            color:uint,
            alpha:Number = 0.75):Sprite {

            var sp:Sprite = new Sprite();
            sp.x = x; sp.y = y;
            var g:* = sp.graphics;
            var barCount:int = maxLevel;
            var barW:Number = 3;
            var spacing:Number = 2;
            var maxH:Number = 14;

            for (var i:int = 0; i < barCount; i++) {
                var barH:Number = maxH * ((i + 1) / barCount);
                var filled:Boolean = (i < level);
                g.beginFill(filled ? color : COL_BORDER, filled ? alpha : 0.15);
                g.drawRect(i * (barW + spacing), maxH - barH, barW, barH);
                g.endFill();
            }
            parent.addChild(sp);
            return sp;
        }

        // ================================================================
        // ICONS
        // ================================================================

        public static function drawSunIcon(
            parent:DisplayObjectContainer,
            cx:Number, cy:Number,
            size:Number, color:uint,
            alpha:Number = 0.85):Shape {

            var s:Shape = new Shape();
            var g:* = s.graphics;
            var r:Number = size * 0.3;

            g.beginFill(color, alpha);
            g.drawCircle(cx, cy, r);
            g.endFill();

            g.lineStyle(W_TERTIARY, color, alpha * 0.7);
            for (var i:int = 0; i < 8; i++) {
                var angle:Number = i * Math.PI / 4;
                var inner:Number = r + 1;
                var outer:Number = r + size * 0.35;
                g.moveTo(cx + Math.cos(angle) * inner,
                         cy + Math.sin(angle) * inner);
                g.lineTo(cx + Math.cos(angle) * outer,
                         cy + Math.sin(angle) * outer);
            }

            parent.addChild(s);
            return s;
        }

        public static function drawMoonIcon(
            parent:DisplayObjectContainer,
            cx:Number, cy:Number,
            size:Number, color:uint,
            alpha:Number = 0.85):Shape {

            var s:Shape = new Shape();
            var g:* = s.graphics;
            var r:Number = size * 0.4;

            g.beginFill(color, alpha);
            g.drawCircle(cx, cy, r);
            g.endFill();

            g.beginFill(COL_BG, 0.95);
            g.drawCircle(cx + r * 0.55, cy - r * 0.1, r * 0.8);
            g.endFill();

            parent.addChild(s);
            return s;
        }

        public static function drawAlertIcon(
            parent:DisplayObjectContainer,
            cx:Number, cy:Number,
            size:Number, color:uint,
            alpha:Number = 0.85):Shape {

            var s:Shape = new Shape();
            var g:* = s.graphics;
            var h2:Number = size * 0.5;

            g.beginFill(color, alpha);
            g.moveTo(cx - h2 * 0.6, cy - h2 * 0.3);
            g.lineTo(cx - h2 * 0.2, cy - h2 * 0.3);
            g.lineTo(cx + h2 * 0.2, cy - h2 * 0.65);
            g.lineTo(cx + h2 * 0.2, cy + h2 * 0.65);
            g.lineTo(cx - h2 * 0.2, cy + h2 * 0.3);
            g.lineTo(cx - h2 * 0.6, cy + h2 * 0.3);
            g.lineTo(cx - h2 * 0.6, cy - h2 * 0.3);
            g.endFill();

            for (var w:int = 1; w <= 2; w++) {
                var waveR:Number = h2 * (0.4 + w * 0.25);
                var waveAlpha:Number = alpha * (0.6 - w * 0.15);
                g.lineStyle(1, color, waveAlpha);
                var arcSteps:int = 8;
                for (var ai:int = 0; ai <= arcSteps; ai++) {
                    var at:Number = ai / arcSteps;
                    var aAngle:Number = (-0.35 + at * 0.70) * Math.PI;
                    var px:Number = cx + h2 * 0.2 + Math.cos(aAngle) * waveR;
                    var py:Number = cy + Math.sin(aAngle) * waveR;
                    if (ai == 0) g.moveTo(px, py);
                    else g.lineTo(px, py);
                }
            }

            parent.addChild(s);
            return s;
        }

        public static function drawBoltIcon(
            parent:DisplayObjectContainer,
            cx:Number, cy:Number,
            size:Number, color:uint,
            alpha:Number = 0.85):Shape {

            var s:Shape = new Shape();
            var g:* = s.graphics;
            var h2:Number = size * 0.5;
            var w2:Number = size * 0.28;
            g.beginFill(color, alpha);
            g.moveTo(cx + w2 * 0.2, cy - h2);
            g.lineTo(cx - w2 * 0.6, cy + h2 * 0.1);
            g.lineTo(cx + w2 * 0.1, cy + h2 * 0.1);
            g.lineTo(cx - w2 * 0.2, cy + h2);
            g.lineTo(cx + w2 * 0.6, cy - h2 * 0.1);
            g.lineTo(cx - w2 * 0.1, cy - h2 * 0.1);
            g.lineTo(cx + w2 * 0.2, cy - h2);
            g.endFill();
            parent.addChild(s);
            return s;
        }

        public static function drawHeartIcon(
            parent:DisplayObjectContainer,
            cx:Number, cy:Number,
            size:Number, color:uint,
            alpha:Number = 0.85):Shape {

            var s:Shape = new Shape();
            var g:* = s.graphics;
            var h2:Number = size * 0.5;
            g.beginFill(color, alpha);
            g.moveTo(cx, cy + h2 * 0.7);
            g.lineTo(cx - h2 * 0.95, cy - h2 * 0.1);
            g.curveTo(cx - h2 * 0.5, cy - h2 * 0.95, cx, cy - h2 * 0.25);
            g.curveTo(cx + h2 * 0.5, cy - h2 * 0.95, cx + h2 * 0.95, cy - h2 * 0.1);
            g.lineTo(cx, cy + h2 * 0.7);
            g.endFill();
            parent.addChild(s);
            return s;
        }

        // ================================================================
        // TEXT
        // ================================================================

        public static function makeLabel(
            parent:DisplayObjectContainer,
            text:String, size:int = 11,
            alpha:Number = 0.70,
            color:uint = 0):TextField {

            if (color == 0) color = COL_TEXT_SEC;
            var fmt:TextFormat = new TextFormat();
            fmt.font = FONT; fmt.size = size; fmt.color = color;
            var tf:TextField = new TextField();
            tf.defaultTextFormat = fmt;
            tf.textColor = color;
            tf.alpha = alpha;
            tf.selectable = false;
            tf.mouseEnabled = false;
            tf.text = text;
            tf.width = tf.textWidth + 8;
            tf.height = tf.textHeight + 4;
            tf.filters = [TEXT_SHADOW];
            parent.addChild(tf);
            return tf;
        }

        public static function makeValue(
            parent:DisplayObjectContainer,
            text:String, size:int = 22,
            alpha:Number = 0.97,
            color:uint = 0):TextField {

            if (color == 0) color = COL_TEXT_VAL;
            var fmt:TextFormat = new TextFormat();
            fmt.font = FONT; fmt.size = size; fmt.color = color;
            var tf:TextField = new TextField();
            tf.defaultTextFormat = fmt;
            tf.textColor = color;
            tf.alpha = alpha;
            tf.selectable = false;
            tf.mouseEnabled = false;
            tf.text = text;
            tf.width = tf.textWidth + 8;
            tf.height = tf.textHeight + 4;
            tf.filters = [TEXT_SHADOW];
            parent.addChild(tf);
            return tf;
        }

        public static function makeDataTag(
            parent:DisplayObjectContainer,
            text:String, size:int = 7,
            color:uint = 0,
            alpha:Number = 0.35):TextField {

            if (color == 0) color = COL_TEXT_SEC;
            var fmt:TextFormat = new TextFormat();
            fmt.font = FONT; fmt.size = size; fmt.color = color;
            fmt.letterSpacing = 1;
            var tf:TextField = new TextField();
            tf.defaultTextFormat = fmt;
            tf.textColor = color;
            tf.alpha = alpha;
            tf.selectable = false;
            tf.mouseEnabled = false;
            tf.text = text;
            tf.width = tf.textWidth + 8;
            tf.height = tf.textHeight + 4;
            tf.filters = [TEXT_SHADOW];
            parent.addChild(tf);
            return tf;
        }

        // ================================================================
        // DIVIDER: simple line
        // ================================================================
        public static function drawDivider(
            parent:DisplayObjectContainer,
            x1:Number, y1:Number,
            x2:Number, y2:Number,
            alpha:Number = 0.30,
            thickness:Number = 1):Shape {

            var s:Shape = new Shape();
            s.graphics.lineStyle(thickness, COL_BORDER, alpha);
            s.graphics.moveTo(x1, y1);
            s.graphics.lineTo(x2, y2);
            parent.addChild(s);
            return s;
        }

        // ================================================================
        // GLOW: danger-only neon glow
        // ================================================================
        public static function applyNeonGlow(target:*, color:uint,
                                              intensity:Number = 1.0):void {
            if (color == COL_WARN) {
                // Red danger glow only
                var blur:Number = 3 + intensity * 4;
                var str:Number = 1.0 + intensity * 0.5;
                var a:Number = 0.3 + intensity * 0.2;
                target.filters = [new GlowFilter(color, a, blur, blur, str, 1)];
            } else {
                target.filters = [];
            }
        }
    }
}
