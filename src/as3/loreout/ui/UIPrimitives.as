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
     * UIPrimitives v10 — LoreOut HUD flat panel design system.
     *
     * Flat monochromatic panels:
     *   - Solid charcoal fill (COL_BG, ~85% alpha)
     *   - 1-2px accent-color outline (no glow on panels)
     *   - Full-width colored header bands (18px)
     *   - Glow ONLY on icons, gauges, and active indicators
     *   - Simple rectangles, 8px grid alignment
     *   - Micro details: corner brackets, dots, ticks
     *   - 3-tier line weight hierarchy (3px / 2px / 1px)
     *   - Teal/Amber/Red/Blue color system
     *
     * Scaleform GFx 4.x safe:
     *   - drawRect, drawCircle, moveTo/lineTo/curveTo only
     *   - $MAIN_Font only
     *   - GlowFilter / DropShadowFilter
     */
    public class UIPrimitives {

        // ---- GRID ----
        public static const GRID:int = 8;

        // ---- COLORS — Cyberpunk palette (locked) ----
        public static const COL_BG:uint       = 0x0D0D12;   // near-black
        public static const COL_BORDER:uint   = 0x445566;   // steel grey
        public static const COL_ACCENT:uint   = 0x22C1C3;   // teal (safe)
        public static const COL_GREEN:uint    = 0x22C1C3;   // teal = green in our scheme
        public static const COL_BLUE:uint     = 0x4488CC;   // energy/info (true blue)
        public static const COL_AMBER:uint    = 0xF2A900;   // amber (alert)
        public static const COL_ORANGE:uint   = 0xF2A900;   // alias
        public static const COL_WARN:uint     = 0xE53935;   // red (danger)
        public static const COL_TEXT_PRI:uint  = 0xE8E8E8;   // bright text
        public static const COL_TEXT_SEC:uint  = 0x8899AA;   // dim text
        public static const COL_TEXT_VAL:uint  = 0xFFFFFF;   // value readouts
        public static const COL_BAR_BG:uint   = 0x1A1A22;   // bar background
        public static const COL_BAR_FILL:uint = 0xBBBBBB;   // bar fill default
        public static const COL_FRAME:uint    = 0x334455;   // structural frame lines
        public static const COL_FRAME_LIGHT:uint = 0x8899AA; // light grey for panel borders

        // ---- LINE WEIGHT TIERS (3-tier hierarchy) ----
        public static const W_PRIMARY:Number   = 3;    // header bars, main spines
        public static const W_SECONDARY:Number = 2;    // dividers, frames
        public static const W_TERTIARY:Number  = 1;    // details, dots, micro

        // ---- HEADER BAND ----
        public static const HEADER_BAND_H:int = 26;

        // ---- TACTICAL PANEL CHAMFERS ----
        public static const CHAMFER_FULL:Number  = 14;   // bold angular silhouette (14px TL, 10px BR)
        public static const CHAMFER_SLIM:Number  = 3;    // subtle for slim panels
        public static const CHAMFER_RATIO:Number = 0.71; // BR chamfer = TL * ratio (14*0.71≈10)

        // ---- ACCENT BLOCK SIZES ----
        public static const ACCENT_V_W:int = 6;    // vertical accent block width
        public static const ACCENT_V_H:int = 18;   // vertical accent block height
        public static const ACCENT_H_W:int = 8;    // horizontal accent slab width
        public static const ACCENT_H_H:int = 3;    // horizontal accent slab height

        // ---- FONT ----
        public static const FONT:String = "$MAIN_Font";

        // ---- STATES ----
        public static const STATE_IDLE:int   = 0;
        public static const STATE_ACTIVE:int = 1;
        public static const STATE_WARN:int   = 2;

        // ---- EDGE CONSTANTS ----
        public static const EDGE_NONE:int   = 0;
        public static const EDGE_LEFT:int   = 1;
        public static const EDGE_RIGHT:int  = 2;
        public static const EDGE_TOP:int    = 3;
        public static const EDGE_BOTTOM:int = 4;

        // ---- TEXT SHADOW for readability ----
        private static var _textShadow:DropShadowFilter;
        public static function get TEXT_SHADOW():DropShadowFilter {
            if (!_textShadow) {
                _textShadow = new DropShadowFilter(0, 0, 0x000000, 0.7, 4, 4, 2, 1);
            }
            return _textShadow;
        }

        // ================================================================
        // HEADER BAND: full-width colored rectangle
        // The signature element — bold, authoritative, color-shifting.
        // ================================================================
        public static function drawHeaderBand(
            parent:DisplayObjectContainer,
            x:Number, y:Number,
            w:Number, h:Number,
            color:uint,
            alpha:Number = 0.85):Shape {

            var s:Shape = new Shape();
            var g:* = s.graphics;
            // Main band fill
            g.beginFill(color, alpha);
            g.drawRect(x, y, w, h);
            g.endFill();
            // Bright bottom edge
            g.lineStyle(1, 0xFFFFFF, 0.15);
            g.moveTo(x, y + h);
            g.lineTo(x + w, y + h);
            // Top highlight
            g.lineStyle(1, 0xFFFFFF, 0.08);
            g.moveTo(x + 2, y);
            g.lineTo(x + w - 2, y);
            parent.addChild(s);
            return s;
        }

        // ================================================================
        // ANGULAR FRAME: dual-chamfer filled panel
        // Creates the Cyberpunk angular panel silhouette with fill.
        // Top-left big chamfer + bottom-right small chamfer.
        // ================================================================
        public static function drawAngularFrame(
            parent:DisplayObjectContainer,
            w:Number, h:Number,
            chamfer:Number = 12,
            color:uint = 0,
            alpha:Number = 0.50,
            thickness:Number = 2,
            fillColor:uint = 0,
            fillAlpha:Number = 0.40):Shape {

            if (color == 0) color = COL_FRAME_LIGHT;
            var s:Shape = new Shape();
            var g:* = s.graphics;
            var c:Number = chamfer;
            var c2:Number = chamfer * 0.6; // smaller bottom-right chamfer

            // Filled background (dark grey panel)
            if (fillAlpha > 0) {
                if (fillColor == 0) fillColor = COL_BG;
                g.beginFill(fillColor, fillAlpha);
                g.moveTo(c, 0);
                g.lineTo(w, 0);
                g.lineTo(w, h - c2);
                g.lineTo(w - c2, h);
                g.lineTo(0, h);
                g.lineTo(0, c);
                g.lineTo(c, 0);
                g.endFill();
            }

            // Stroke outline (light grey)
            g.lineStyle(thickness, color, alpha);
            g.moveTo(c, 0);
            g.lineTo(w, 0);
            g.lineTo(w, h - c2);
            g.lineTo(w - c2, h);
            g.lineTo(0, h);
            g.lineTo(0, c);
            g.lineTo(c, 0);

            // Inner detail line (1px, 3px inside, very subtle — adds panel depth)
            var inset:Number = 3;
            var ic:Number = c > inset ? c - inset : 1;
            var ic2:Number = c2 > inset ? c2 - inset : 1;
            g.lineStyle(1, color, alpha * 0.30);
            g.moveTo(ic + inset, inset);
            g.lineTo(w - inset, inset);
            g.lineTo(w - inset, h - ic2 - inset);
            g.lineTo(w - ic2 - inset, h - inset);
            g.lineTo(inset, h - inset);
            g.lineTo(inset, ic + inset);
            g.lineTo(ic + inset, inset);

            parent.addChild(s);
            return s;
        }

        // ================================================================
        // RECOLOR ANGULAR FRAME: redraw with new color + fill
        // ================================================================
        public static function recolorAngularFrame(
            frame:Shape, w:Number, h:Number,
            chamfer:Number, color:uint, alpha:Number,
            thickness:Number = 2,
            fillColor:uint = 0, fillAlpha:Number = 0.40):void {

            if (!frame) return;
            var g:* = frame.graphics;
            g.clear();
            var c:Number = chamfer;
            var c2:Number = chamfer * 0.6;

            if (fillAlpha > 0) {
                if (fillColor == 0) fillColor = COL_BG;
                g.beginFill(fillColor, fillAlpha);
                g.moveTo(c, 0);
                g.lineTo(w, 0);
                g.lineTo(w, h - c2);
                g.lineTo(w - c2, h);
                g.lineTo(0, h);
                g.lineTo(0, c);
                g.lineTo(c, 0);
                g.endFill();
            }

            g.lineStyle(thickness, color, alpha);
            g.moveTo(c, 0);
            g.lineTo(w, 0);
            g.lineTo(w, h - c2);
            g.lineTo(w - c2, h);
            g.lineTo(0, h);
            g.lineTo(0, c);
            g.lineTo(c, 0);

            // Inner detail line
            var inset:Number = 3;
            var ic:Number = c > inset ? c - inset : 1;
            var ic2:Number = c2 > inset ? c2 - inset : 1;
            g.lineStyle(1, color, alpha * 0.30);
            g.moveTo(ic + inset, inset);
            g.lineTo(w - inset, inset);
            g.lineTo(w - inset, h - ic2 - inset);
            g.lineTo(w - ic2 - inset, h - inset);
            g.lineTo(inset, h - inset);
            g.lineTo(inset, ic + inset);
            g.lineTo(ic + inset, inset);
        }

        // ================================================================
        // GLOW PANEL: filled polygon + GlowFilter (replaces angular frame)
        // The glow IS the border — no hard outlines.
        // Styles: "banner" (wing notches), "card" (chamfers+notch), "slim"
        // ================================================================
        public static function drawGlowPanel(
            parent:DisplayObjectContainer,
            w:Number, h:Number,
            glowColor:uint,
            style:String = "card",
            glowIntensity:Number = 0.30,
            fillAlpha:Number = 0.65):Shape {

            var s:Shape = new Shape();
            var g:* = s.graphics;

            // Ultra-thin hint stroke (barely visible)
            g.lineStyle(0.5, glowColor, 0.12);
            g.beginFill(COL_BG, fillAlpha);

            if (style == "banner") {
                // Banner: wing notches at top corners, mounting indents on sides
                var wn:Number = 8;   // wing notch width
                var wd:Number = 3;   // wing notch depth
                var mi:Number = 2;   // mounting indent depth
                var mw:Number = 6;   // mounting indent width
                var mh:Number = h * 0.45; // mounting indent Y position

                g.moveTo(0, wd);           // start below TL wing
                g.lineTo(wn, wd);          // TL wing horizontal
                g.lineTo(wn, 0);           // TL wing up
                g.lineTo(w - wn, 0);       // top edge
                g.lineTo(w - wn, wd);      // TR wing down
                g.lineTo(w, wd);           // TR wing horizontal
                g.lineTo(w, mh);           // right edge to mount
                g.lineTo(w - mi, mh + 2);  // right mount in
                g.lineTo(w - mi, mh + mw + 2); // right mount down
                g.lineTo(w, mh + mw + 4);  // right mount out
                g.lineTo(w, h - wd);       // right edge to BR wing
                g.lineTo(w - wn, h - wd);  // BR wing horizontal
                g.lineTo(w - wn, h);       // BR wing down
                g.lineTo(wn, h);           // bottom edge
                g.lineTo(wn, h - wd);      // BL wing up
                g.lineTo(0, h - wd);       // BL wing horizontal
                g.lineTo(0, mh + mw + 4);  // left edge to mount
                g.lineTo(mi, mh + mw + 2); // left mount in
                g.lineTo(mi, mh + 2);      // left mount up
                g.lineTo(0, mh);           // left mount out
                g.lineTo(0, wd);           // close to start
            } else if (style == "card") {
                // Card: TL chamfer, BR chamfer, side notch near top
                var c1:Number = 8;   // TL chamfer
                var c2:Number = 5;   // BR chamfer
                var nx:Number = 2;   // notch depth
                var ny:Number = h * 0.25; // notch Y position
                var nw:Number = 5;   // notch width

                g.moveTo(c1, 0);           // start at TL chamfer
                g.lineTo(w, 0);            // top edge
                g.lineTo(w, ny);           // right edge to notch
                g.lineTo(w - nx, ny + 1);  // right notch in
                g.lineTo(w - nx, ny + nw + 1); // right notch down
                g.lineTo(w, ny + nw + 2);  // right notch out
                g.lineTo(w, h - c2);       // right edge to BR chamfer
                g.lineTo(w - c2, h);       // BR chamfer
                g.lineTo(0, h);            // bottom edge
                g.lineTo(0, ny + nw + 2);  // left edge to notch
                g.lineTo(nx, ny + nw + 1); // left notch in
                g.lineTo(nx, ny + 1);      // left notch up
                g.lineTo(0, ny);           // left notch out
                g.lineTo(0, c1);           // left edge to TL chamfer
                g.lineTo(c1, 0);           // TL chamfer
            } else {
                // Slim: subtle chamfers only
                var sc:Number = 3;
                g.moveTo(sc, 0);
                g.lineTo(w - sc, 0);
                g.lineTo(w, sc);
                g.lineTo(w, h - sc);
                g.lineTo(w - sc, h);
                g.lineTo(sc, h);
                g.lineTo(0, h - sc);
                g.lineTo(0, sc);
                g.lineTo(sc, 0);
            }

            g.endFill();

            // Apply glow — THIS defines the panel edges
            s.filters = [new GlowFilter(glowColor, glowIntensity, 8, 8, 1.5, 2)];

            parent.addChild(s);
            return s;
        }

        // ================================================================
        // RECOLOR GLOW PANEL: redraw fill + update glow
        // ================================================================
        public static function recolorGlowPanel(
            panel:Shape, w:Number, h:Number,
            glowColor:uint, style:String = "card",
            glowIntensity:Number = 0.30,
            fillAlpha:Number = 0.65):void {

            if (!panel) return;
            var g:* = panel.graphics;
            g.clear();

            g.lineStyle(0.5, glowColor, 0.12);
            g.beginFill(COL_BG, fillAlpha);

            if (style == "banner") {
                var wn:Number = 8;
                var wd:Number = 3;
                var mi:Number = 2;
                var mw:Number = 6;
                var mh:Number = h * 0.45;

                g.moveTo(0, wd);
                g.lineTo(wn, wd);
                g.lineTo(wn, 0);
                g.lineTo(w - wn, 0);
                g.lineTo(w - wn, wd);
                g.lineTo(w, wd);
                g.lineTo(w, mh);
                g.lineTo(w - mi, mh + 2);
                g.lineTo(w - mi, mh + mw + 2);
                g.lineTo(w, mh + mw + 4);
                g.lineTo(w, h - wd);
                g.lineTo(w - wn, h - wd);
                g.lineTo(w - wn, h);
                g.lineTo(wn, h);
                g.lineTo(wn, h - wd);
                g.lineTo(0, h - wd);
                g.lineTo(0, mh + mw + 4);
                g.lineTo(mi, mh + mw + 2);
                g.lineTo(mi, mh + 2);
                g.lineTo(0, mh);
                g.lineTo(0, wd);
            } else if (style == "card") {
                var c1:Number = 8;
                var c2:Number = 5;
                var nx:Number = 2;
                var ny:Number = h * 0.25;
                var nw:Number = 5;

                g.moveTo(c1, 0);
                g.lineTo(w, 0);
                g.lineTo(w, ny);
                g.lineTo(w - nx, ny + 1);
                g.lineTo(w - nx, ny + nw + 1);
                g.lineTo(w, ny + nw + 2);
                g.lineTo(w, h - c2);
                g.lineTo(w - c2, h);
                g.lineTo(0, h);
                g.lineTo(0, ny + nw + 2);
                g.lineTo(nx, ny + nw + 1);
                g.lineTo(nx, ny + 1);
                g.lineTo(0, ny);
                g.lineTo(0, c1);
                g.lineTo(c1, 0);
            } else {
                var sc:Number = 3;
                g.moveTo(sc, 0);
                g.lineTo(w - sc, 0);
                g.lineTo(w, sc);
                g.lineTo(w, h - sc);
                g.lineTo(w - sc, h);
                g.lineTo(sc, h);
                g.lineTo(0, h - sc);
                g.lineTo(0, sc);
                g.lineTo(sc, 0);
            }

            g.endFill();

            panel.filters = [new GlowFilter(glowColor, glowIntensity, 8, 8, 1.5, 2)];
        }

        // ================================================================
        // GET GLOW PANEL PATH: returns polygon vertices for chase light
        // ================================================================
        public static function getGlowPanelPath(w:Number, h:Number,
            style:String = "card"):Object {

            var vx:Array = [];
            var vy:Array = [];

            if (style == "banner") {
                var wn:Number = 8;
                var wd:Number = 3;
                vx = [wn, w - wn, w - wn, w, w, w, w - wn, w - wn, wn, wn, 0, 0, 0, wn];
                vy = [0, 0, wd, wd, h - wd, h - wd, h - wd, h, h, h - wd, h - wd, wd, wd, 0];
            } else if (style == "card") {
                var c1:Number = 8;
                var c2:Number = 5;
                vx = [c1, w, w, w - c2, 0, 0, c1];
                vy = [0, 0, h - c2, h, h, c1, 0];
            } else {
                var sc:Number = 3;
                vx = [sc, w - sc, w, w, w - sc, sc, 0, 0, sc];
                vy = [0, 0, sc, h - sc, h, h, h - sc, sc, 0];
            }

            return {vx: vx, vy: vy};
        }

        // ================================================================
        // FLAT PANEL: simple dark rectangle + thin accent-color outline.
        // The v10 replacement for glow panels.
        // No shaped polygons. No GlowFilter on the panel itself.
        // ================================================================
        public static function drawFlatPanel(
            parent:DisplayObjectContainer,
            w:Number, h:Number,
            accentColor:uint,
            fillAlpha:Number = 0.85,
            outlineWeight:Number = 1.5):Shape {

            var s:Shape = new Shape();
            var g:* = s.graphics;

            // Solid charcoal fill
            g.beginFill(COL_BG, fillAlpha);
            g.drawRect(0, 0, w, h);
            g.endFill();

            // Thin accent-color outline
            g.lineStyle(outlineWeight, accentColor, 0.55);
            g.drawRect(0, 0, w, h);

            parent.addChild(s);
            return s;
        }

        // ================================================================
        // RECOLOR FLAT PANEL: redraw with new accent color
        // ================================================================
        public static function recolorFlatPanel(
            panel:Shape, w:Number, h:Number,
            accentColor:uint,
            fillAlpha:Number = 0.85,
            outlineWeight:Number = 1.5):void {

            if (!panel) return;
            var g:* = panel.graphics;
            g.clear();

            g.beginFill(COL_BG, fillAlpha);
            g.drawRect(0, 0, w, h);
            g.endFill();

            g.lineStyle(outlineWeight, accentColor, 0.55);
            g.drawRect(0, 0, w, h);

            // Flat panel: no glow filter, ever
            panel.filters = [];
        }

        // ================================================================
        // CORNER BRACKETS: L-shaped marks at panel corners
        // ================================================================
        public static function drawCornerBrackets(
            parent:DisplayObjectContainer,
            w:Number, h:Number,
            size:Number = 6,
            color:uint = 0,
            alpha:Number = 0.30):Shape {

            if (color == 0) color = COL_FRAME_LIGHT;
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
        // TACTICAL PANEL: chamfered polygon with multi-layer borders
        // Replaces drawFlatPanel with structured military C2 panel.
        // Layers: fill → outer stroke → inner detail stroke → scan lines
        // ================================================================
        public static function drawTacticalPanel(
            parent:DisplayObjectContainer,
            w:Number, h:Number,
            accentColor:uint,
            style:String = "full",
            fillAlpha:Number = 0.85):Shape {

            var s:Shape = new Shape();
            var g:* = s.graphics;
            _drawTacticalPanelGraphics(g, w, h, accentColor, style, fillAlpha);
            parent.addChild(s);
            return s;
        }

        // ================================================================
        // RECOLOR TACTICAL PANEL: clear and redraw with new accent
        // ================================================================
        public static function recolorTacticalPanel(
            panel:Shape, w:Number, h:Number,
            accentColor:uint,
            style:String = "full",
            fillAlpha:Number = 0.85):void {

            if (!panel) return;
            var g:* = panel.graphics;
            g.clear();
            _drawTacticalPanelGraphics(g, w, h, accentColor, style, fillAlpha);
            panel.filters = [];
        }

        // Internal: shared drawing logic for tactical panel
        // Chamfered polygon with multi-layer borders + edge accents.
        private static function _drawTacticalPanelGraphics(
            g:*, w:Number, h:Number,
            accentColor:uint, style:String,
            fillAlpha:Number):void {

            var c:Number = (style == "slim") ? CHAMFER_SLIM : CHAMFER_FULL;
            var c2:Number = Math.round(c * CHAMFER_RATIO);
            var inset:Number = (style == "slim") ? 2 : 3;

            // -- Layer 1: Filled chamfered polygon --
            g.beginFill(COL_BG, fillAlpha);
            g.moveTo(c, 0);
            g.lineTo(w, 0);
            g.lineTo(w, h - c2);
            g.lineTo(w - c2, h);
            g.lineTo(0, h);
            g.lineTo(0, c);
            g.lineTo(c, 0);
            g.endFill();

            // -- Layer 2: Outer stroke (primary border, crisp) --
            g.lineStyle(1.5, accentColor, 0.45);
            g.moveTo(c, 0);
            g.lineTo(w, 0);
            g.lineTo(w, h - c2);
            g.lineTo(w - c2, h);
            g.lineTo(0, h);
            g.lineTo(0, c);
            g.lineTo(c, 0);

            // -- Layer 3: Inner detail stroke (depth cue) --
            var ic:Number = (c > inset) ? (c - inset) : 1;
            var ic2:Number = (c2 > inset) ? (c2 - inset) : 1;
            g.lineStyle(0.5, accentColor, 0.12);
            g.moveTo(ic + inset, inset);
            g.lineTo(w - inset, inset);
            g.lineTo(w - inset, h - ic2 - inset);
            g.lineTo(w - ic2 - inset, h - inset);
            g.lineTo(inset, h - inset);
            g.lineTo(inset, ic + inset);
            g.lineTo(ic + inset, inset);

            // -- Layer 4: TL chamfer highlight (subtle white edge) --
            if (style != "slim") {
                g.lineStyle(0.5, 0xFFFFFF, 0.06);
                g.moveTo(c, 0);
                g.lineTo(0, c);
            }

            // -- Layer 5: Edge accent marks (tiny colored ticks at edge midpoints) --
            if (style != "slim") {
                g.lineStyle(0);
                // Top edge center tick
                g.beginFill(accentColor, 0.30);
                g.drawRect(w * 0.5 - 2, 0, 4, 1);
                g.endFill();
                // Bottom edge center tick
                g.beginFill(accentColor, 0.30);
                g.drawRect(w * 0.5 - 2, h - 1, 4, 1);
                g.endFill();
                // Left edge mid tick
                g.beginFill(accentColor, 0.20);
                g.drawRect(0, h * 0.5 - 1, 1, 3);
                g.endFill();
                // Right edge mid tick
                g.beginFill(accentColor, 0.20);
                g.drawRect(w - 1, h * 0.5 - 1, 1, 3);
                g.endFill();
            }
        }

        // ================================================================
        // GET TACTICAL PANEL PATH: vertex arrays for chase light
        // Returns {vx:Array, vy:Array} for perimeter walking.
        // ================================================================
        public static function getTacticalPanelPath(
            w:Number, h:Number,
            style:String = "full"):Object {

            var c:Number = (style == "slim") ? CHAMFER_SLIM : CHAMFER_FULL;
            var c2:Number = Math.round(c * CHAMFER_RATIO);
            return {
                vx: [c, w, w, w - c2, 0, 0, c],
                vy: [0, 0, h - c2, h, h, c, 0]
            };
        }

        // ================================================================
        // CYBER PANEL BUILDER: complete tactical panel assembly
        // ================================================================
        // Draws all structural layers (L1-L12). Widgets add content only.
        //
        // Styles: "full" (200x96, 192x96) — header, brackets, spine,
        //         ruler, measurement marks, leader lines, bottom decor
        //         "medium" (192x56, 200x48) — brackets, ruler, leader,
        //         bottom decor, header optional
        //         "slim" (192x24) — panel + leader line only
        //
        // Returns: {panel, header, headerY, contentX, contentY,
        //           contentW, contentH, w, h, style}
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
            var isFull:Boolean = (style == "full");
            var isSlim:Boolean = (style == "slim");
            if (isSlim) hasHeader = false;
            var pad:Number = 6;
            var c:Number = isSlim ? CHAMFER_SLIM : CHAMFER_FULL;

            // Store for recoloring
            result.w = w;
            result.h = h;
            result.style = style;

            // === L1-L5: Panel shape (fill + grey frame + accent trim) ===
            var panelShape:Shape = new Shape();
            _drawCyberPanelGfx(panelShape.graphics, w, h, accent, style);
            parent.addChild(panelShape);
            result.panel = panelShape;

            // === L6: Header band (accent — the bold color element) ===
            result.header = null;
            result.headerY = 2;
            var contentTop:Number = pad;

            if (hasHeader) {
                var header:Object = drawLayeredHeader(
                    parent, w - 4, accent, headerLabel, 0.55);
                if (header.band) {
                    (header.band as Shape).x = 2;
                    (header.band as Shape).y = 2;
                }
                result.header = header;

                // Header divider (grey, structural, 1px bold with terminus dots)
                drawDividerLine(parent, pad, HEADER_BAND_H + 2,
                    w - pad * 2, COL_BORDER, 0.55, 1.0, true, 1.0);

                // Terminus dots at divider endpoints (bold)
                var divDots:Shape = new Shape();
                var ddg:* = divDots.graphics;
                ddg.lineStyle(0);
                ddg.beginFill(COL_BORDER, 0.60);
                ddg.drawCircle(pad, HEADER_BAND_H + 2, 2);
                ddg.endFill();
                ddg.beginFill(COL_BORDER, 0.60);
                ddg.drawCircle(w - pad, HEADER_BAND_H + 2, 2);
                ddg.endFill();
                parent.addChild(divDots);

                contentTop = HEADER_BAND_H + 5;
            }

            // Content zone
            result.contentX = pad;
            result.contentY = contentTop;
            result.contentW = w - pad * 2;
            result.contentH = h - contentTop - pad;

            // === L7: Inner instrument frame (bold panel-in-panel) ===
            if (!isSlim) {
                var insetFrame:Shape = new Shape();
                var ifg:* = insetFrame.graphics;
                var insetPad:Number = 4;
                ifg.lineStyle(1, COL_BORDER, 0.40);
                ifg.drawRect(
                    Number(result.contentX) + insetPad,
                    Number(result.contentY) + insetPad,
                    Number(result.contentW) - insetPad * 2,
                    Number(result.contentH) - insetPad * 2);
                parent.addChild(insetFrame);
            }

            // === L8: Corner brackets (grey, bold structural) ===
            if (!isSlim) {
                var bracketSize:Number = isFull ? 10 : 8;
                drawTacticalBrackets(parent, w, h, bracketSize,
                    COL_FRAME_LIGHT, 0.50);
            }

            // === L9: Ruler ticks (bottom of content area) ===
            if (!isSlim) {
                var rulerY:Number = h - pad;
                var rulerShape:Shape = new Shape();
                var rg:* = rulerShape.graphics;
                var rulerStart:Number = pad + 8;
                var rulerEnd:Number = w - pad - 4;
                var tickIdx:int = 0;
                for (var rx:Number = rulerStart; rx <= rulerEnd;
                     rx += GRID) {
                    var isMajR:Boolean = (tickIdx % 4 == 0);
                    rg.beginFill(COL_BORDER, isMajR ? 0.45 : 0.22);
                    rg.drawRect(rx, rulerY, 1, isMajR ? 5 : 3);
                    rg.endFill();
                    tickIdx++;
                }
                parent.addChild(rulerShape);
            }

            // === L10: Right-edge measurement marks (full only) ===
            if (isFull) {
                var measShape:Shape = new Shape();
                var mg:* = measShape.graphics;
                var measX:Number = w - pad;
                var measTop:Number = contentTop + 4;
                var measBot:Number = h - pad - 4;
                var measIdx:int = 0;
                for (var my:Number = measTop; my <= measBot;
                     my += GRID) {
                    var isMajM:Boolean = (measIdx % 3 == 0);
                    mg.beginFill(COL_BORDER, isMajM ? 0.40 : 0.18);
                    mg.drawRect(measX, my, isMajM ? 5 : 3, 1);
                    mg.endFill();
                    measIdx++;
                }
                parent.addChild(measShape);
            }

            // === L13: Micro instrument bars (bottom of content, full only) ===
            if (isFull) {
                var microShape:Shape = new Shape();
                var mcg:* = microShape.graphics;
                var microY:Number = h - pad - 5;
                var microCount:int = 8;
                var microStart:Number = pad + 8;
                mcg.lineStyle(0);
                for (var mi:int = 0; mi < microCount; mi++) {
                    var barH:Number = 3 + (mi % 3);
                    mcg.beginFill(COL_BORDER, 0.50);
                    mcg.drawRect(microStart + mi * 5, microY - barH, 3, barH);
                    mcg.endFill();
                }
                parent.addChild(microShape);
            }

            // === L14: Interior dot cluster (TR of content area, bold) ===
            if (!isSlim) {
                drawDotCluster(parent,
                    w - pad - 14, contentTop + 3,
                    2, 3, 4, COL_BORDER, 0.40);
            }

            // === L11: Leader line from TL chamfer (bold) ===
            if (isSlim) {
                drawLeaderLine(parent, 0, c, -6, c,
                    COL_BORDER, 0.30, 1.0, 1.0);
            } else {
                drawLeaderLine(parent, 0, c, -8, c,
                    COL_BORDER, 0.35);
            }

            // === L12: Below-panel decorations ===
            if (!isSlim) {
                drawDotCluster(parent, pad, h + 3, 2, 3, 4,
                    COL_FRAME_LIGHT, 0.35);
                drawDotCluster(parent, w - 18, h + 3, 2, 3, 4,
                    COL_FRAME_LIGHT, 0.35);

                if (isFull) {
                    drawTickStrip(parent, int(w * 0.35), h + 4,
                        6, 3, 4, 2, COL_FRAME_LIGHT, 0.30);
                }

                if (tag.length > 0) {
                    var tagField:TextField = makeDataTag(parent, tag, 8,
                        COL_FRAME_LIGHT, 0.40);
                    tagField.x = 20;
                    tagField.y = h + 1;
                }
            }

            // BR leader line (full only, bolder)
            if (isFull) {
                var c2br:Number = Math.round(c * CHAMFER_RATIO);
                drawLeaderLine(parent, w - c2br, h,
                    w - c2br, h + 12, COL_BORDER, 0.30);
            }

            return result;
        }

        // ================================================================
        // RECOLOR CYBER PANEL: accent trim + header band shift
        // ================================================================
        public static function recolorCyberPanel(
            parts:Object, accent:uint,
            headerAlpha:Number = 0.55):void {

            if (!parts) return;

            // Recolor panel (grey frame stays, accent trim shifts)
            if (parts.panel) {
                var g:* = (parts.panel as Shape).graphics;
                g.clear();
                _drawCyberPanelGfx(g,
                    Number(parts.w), Number(parts.h),
                    accent, String(parts.style));
                (parts.panel as Shape).filters = [];
            }

            // Recolor header band
            if (parts.header) {
                recolorLayeredHeader(parts.header,
                    Number(parts.w) - 4, accent, headerAlpha);
            }
        }

        // Internal: cyber panel shape drawing
        // Separate edge segments — no miter join artifacts.
        // All coordinates snapped to integers.
        private static function _drawCyberPanelGfx(
            g:*, w:Number, h:Number,
            accent:uint, style:String):void {

            var isSlim:Boolean = (style == "slim");
            var c:int = int(isSlim ? CHAMFER_SLIM : CHAMFER_FULL);
            var c2:int = int(Math.round((isSlim ? CHAMFER_SLIM : CHAMFER_FULL) * CHAMFER_RATIO));
            var inset:int = isSlim ? 2 : 3;
            var wi:int = int(w);
            var hi:int = int(h);

            // -- L1: Fill (chamfered polygon, canonical clockwise) --
            g.beginFill(COL_BG, 0.88);
            g.moveTo(c, 0);
            g.lineTo(wi, 0);
            g.lineTo(wi, hi - c2);
            g.lineTo(wi - c2, hi);
            g.lineTo(0, hi);
            g.lineTo(0, c);
            g.lineTo(c, 0);
            g.endFill();

            // -- L2: Outer structural frame (2px grey, separate edges — no joins) --
            g.lineStyle(2, COL_FRAME_LIGHT, 0.50);
            g.moveTo(c, 0);    g.lineTo(wi, 0);         // top
            g.moveTo(wi, 0);   g.lineTo(wi, hi - c2);   // right
            g.moveTo(wi, hi - c2); g.lineTo(wi - c2, hi);// BR chamfer
            g.moveTo(wi - c2, hi); g.lineTo(0, hi);      // bottom
            g.moveTo(0, hi);   g.lineTo(0, c);           // left
            g.moveTo(0, c);    g.lineTo(c, 0);           // TL chamfer

            // -- L3: Inner structural frame (2px grey, separate edges) --
            var ic:int = (c > inset) ? (c - inset) : 1;
            var ic2v:int = (c2 > inset) ? (c2 - inset) : 1;
            var ix:int = inset;
            var iy:int = inset;
            var iw:int = wi - inset;
            var ih:int = hi - inset;

            g.lineStyle(2, COL_BORDER, 0.55);
            g.moveTo(ic + ix, iy);    g.lineTo(iw, iy);            // top
            g.moveTo(iw, iy);         g.lineTo(iw, ih - ic2v);     // right
            g.moveTo(iw, ih - ic2v);  g.lineTo(iw - ic2v, ih);     // BR chamfer
            g.moveTo(iw - ic2v, ih);  g.lineTo(ix, ih);            // bottom
            g.moveTo(ix, ih);         g.lineTo(ix, ic + iy);       // left
            g.moveTo(ix, ic + iy);    g.lineTo(ic + ix, iy);       // TL chamfer

            // -- L4: Edge accent marks --
            if (!isSlim) {
                g.lineStyle(0);
                var mx:int = int(wi * 0.5);
                var my:int = int(hi * 0.5);
                // Top center
                g.beginFill(accent, 0.30);
                g.drawRect(mx - 4, 0, 8, 2);
                g.endFill();
                // Bottom center
                g.beginFill(accent, 0.30);
                g.drawRect(mx - 4, hi - 2, 8, 2);
                g.endFill();
                // Left mid
                g.beginFill(COL_BORDER, 0.45);
                g.drawRect(0, my - 3, 2, 6);
                g.endFill();
                // Right mid
                g.beginFill(COL_BORDER, 0.45);
                g.drawRect(wi - 2, my - 3, 2, 6);
                g.endFill();
            }
        }

        // ================================================================
        // CHEVRON HEADER: header band with angled V-cut on one end
        // chevronSide: "right" for right-side widgets, "left" for left-side
        // Returns: {band:Shape, bottomY:Number}
        // ================================================================
        public static function drawChevronHeader(
            parent:DisplayObjectContainer,
            w:Number, color:uint,
            label:String = "",
            bandAlpha:Number = 0.80,
            chevronSide:String = "right",
            chevronDepth:Number = 6):Object {

            var result:Object = {};
            var s:Shape = new Shape();
            var g:* = s.graphics;
            var hh:Number = HEADER_BAND_H;
            var mid:Number = hh * 0.5;

            _drawChevronHeaderGraphics(g, w, hh, mid, color, bandAlpha, chevronSide, chevronDepth);

            parent.addChild(s);
            result.band = s;
            result.chevronSide = chevronSide;
            result.chevronDepth = chevronDepth;

            // Label on the band
            if (label.length > 0) {
                var labelX:Number = (chevronSide == "left") ? chevronDepth + 4 : 6;
                var lbl:TextField = makeLabel(parent, label, 10, 0.95, 0xFFFFFF);
                lbl.x = labelX;
                lbl.y = 1;
            }

            result.bottomY = hh + 2;
            return result;
        }

        // ================================================================
        // RECOLOR CHEVRON HEADER
        // ================================================================
        public static function recolorChevronHeader(
            parts:Object, w:Number, color:uint,
            bandAlpha:Number = 0.80):void {

            if (!parts || !parts.band) return;
            var g:* = (parts.band as Shape).graphics;
            g.clear();
            var hh:Number = HEADER_BAND_H;
            var mid:Number = hh * 0.5;
            var side:String = parts.chevronSide || "right";
            var depth:Number = parts.chevronDepth || 6;
            _drawChevronHeaderGraphics(g, w, hh, mid, color, bandAlpha, side, depth);
        }

        // Internal: shared chevron header drawing
        private static function _drawChevronHeaderGraphics(
            g:*, w:Number, hh:Number, mid:Number,
            color:uint, bandAlpha:Number,
            chevronSide:String, chevronDepth:Number):void {

            var d:Number = chevronDepth;

            // Main band fill (chevron polygon)
            g.beginFill(color, bandAlpha);
            if (chevronSide == "left") {
                g.moveTo(d, 0);
                g.lineTo(w, 0);
                g.lineTo(w, hh);
                g.lineTo(d, hh);
                g.lineTo(0, mid);
                g.lineTo(d, 0);
            } else {
                g.moveTo(0, 0);
                g.lineTo(w - d, 0);
                g.lineTo(w, mid);
                g.lineTo(w - d, hh);
                g.lineTo(0, hh);
                g.lineTo(0, 0);
            }
            g.endFill();

            // Bottom edge highlight
            g.lineStyle(1, 0xFFFFFF, 0.15);
            if (chevronSide == "left") {
                g.moveTo(d, hh);
                g.lineTo(w, hh);
            } else {
                g.moveTo(0, hh);
                g.lineTo(w - d, hh);
            }

            // Top edge highlight
            g.lineStyle(1, 0xFFFFFF, 0.08);
            if (chevronSide == "left") {
                g.moveTo(d + 2, 0);
                g.lineTo(w - 2, 0);
            } else {
                g.moveTo(2, 0);
                g.lineTo(w - d - 2, 0);
            }
        }

        // ================================================================
        // DIVIDER LINE: separator with terminus dots
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

            // Main line
            g.lineStyle(thickness, color, alpha);
            g.moveTo(x, y);
            g.lineTo(x + w, y);

            // Terminus dots
            if (terminusDots) {
                g.lineStyle(0);
                g.beginFill(color, alpha * 1.5);
                g.drawCircle(x, y, dotRadius);
                g.drawCircle(x + w, y, dotRadius);
                g.endFill();
            }

            parent.addChild(s);
            return s;
        }

        // ================================================================
        // LEADER LINE: callout line extending from panel edge
        // ================================================================
        public static function drawLeaderLine(
            parent:DisplayObjectContainer,
            startX:Number, startY:Number,
            endX:Number, endY:Number,
            color:uint,
            alpha:Number = 0.30,
            thickness:Number = 0.5,
            terminusDotRadius:Number = 1.5):Shape {

            var s:Shape = new Shape();
            var g:* = s.graphics;

            g.lineStyle(thickness, color, alpha);
            g.moveTo(startX, startY);
            g.lineTo(endX, endY);

            // Terminus dot
            g.lineStyle(0);
            g.beginFill(color, alpha * 1.5);
            g.drawCircle(endX, endY, terminusDotRadius);
            g.endFill();

            parent.addChild(s);
            return s;
        }

        // ================================================================
        // TACTICAL BRACKETS: double-line L-brackets at panel corners
        // ================================================================
        public static function drawTacticalBrackets(
            parent:DisplayObjectContainer,
            w:Number, h:Number,
            size:Number = 8,
            color:uint = 0,
            alpha:Number = 0.30):Shape {

            if (color == 0) color = COL_FRAME_LIGHT;
            var s:Shape = new Shape();
            var g:* = s.graphics;

            // Outer brackets (1px)
            g.lineStyle(W_TERTIARY, color, alpha);
            // Top-left
            g.moveTo(0, size); g.lineTo(0, 0); g.lineTo(size, 0);
            // Top-right
            g.moveTo(w - size, 0); g.lineTo(w, 0); g.lineTo(w, size);
            // Bottom-right
            g.moveTo(w, h - size); g.lineTo(w, h); g.lineTo(w - size, h);
            // Bottom-left
            g.moveTo(size, h); g.lineTo(0, h); g.lineTo(0, h - size);

            // Inner brackets (0.5px, inset 2px, half alpha)
            g.lineStyle(0.5, color, alpha * 0.5);
            var i:Number = 2;
            // Top-left
            g.moveTo(i, size - i); g.lineTo(i, i); g.lineTo(size - i, i);
            // Top-right
            g.moveTo(w - size + i, i); g.lineTo(w - i, i); g.lineTo(w - i, size - i);
            // Bottom-right
            g.moveTo(w - i, h - size + i); g.lineTo(w - i, h - i); g.lineTo(w - size + i, h - i);
            // Bottom-left
            g.moveTo(size - i, h - i); g.lineTo(i, h - i); g.lineTo(i, h - size + i);

            parent.addChild(s);
            return s;
        }

        // ================================================================
        // SUN ICON: filled circle + 8 rays (daytime weather)
        // ================================================================
        public static function drawSunIcon(
            parent:DisplayObjectContainer,
            cx:Number, cy:Number,
            size:Number, color:uint,
            alpha:Number = 0.85):Shape {

            var s:Shape = new Shape();
            var g:* = s.graphics;
            var r:Number = size * 0.3;

            // Core circle
            g.beginFill(color, alpha);
            g.drawCircle(cx, cy, r);
            g.endFill();

            // 8 rays
            g.lineStyle(W_TERTIARY, color, alpha * 0.7);
            for (var i:int = 0; i < 8; i++) {
                var angle:Number = i * Math.PI / 4;
                var inner:Number = r + 1;
                var outer:Number = r + size * 0.35;
                g.moveTo(cx + Math.cos(angle) * inner, cy + Math.sin(angle) * inner);
                g.lineTo(cx + Math.cos(angle) * outer, cy + Math.sin(angle) * outer);
            }

            parent.addChild(s);
            return s;
        }

        // ================================================================
        // MOON ICON: crescent via overlapping circles (nighttime weather)
        // ================================================================
        public static function drawMoonIcon(
            parent:DisplayObjectContainer,
            cx:Number, cy:Number,
            size:Number, color:uint,
            alpha:Number = 0.85):Shape {

            var s:Shape = new Shape();
            var g:* = s.graphics;
            var r:Number = size * 0.4;

            // Main moon circle
            g.beginFill(color, alpha);
            g.drawCircle(cx, cy, r);
            g.endFill();

            // Cut-out circle (offset right) in background color
            g.beginFill(COL_BG, 0.95);
            g.drawCircle(cx + r * 0.55, cy - r * 0.1, r * 0.8);
            g.endFill();

            parent.addChild(s);
            return s;
        }

        // ================================================================
        // WARNING BADGE: pentagon shape with triangle icon (@deprecated v10)
        // ================================================================
        public static function drawWarningBadge(
            parent:DisplayObjectContainer,
            x:Number, y:Number,
            size:Number = 28,
            level:int = 0):Sprite {

            var sp:Sprite = new Sprite();
            sp.x = x; sp.y = y;

            if (level <= 0) {
                sp.alpha = 0;
                parent.addChild(sp);
                return sp;
            }

            var g:* = sp.graphics;
            var col:uint = (level >= 2) ? COL_WARN : COL_AMBER;
            var hw:Number = size * 0.5;
            var hh:Number = size * 0.5;

            // Pentagon shape (arrow pointing left)
            g.beginFill(COL_BG, 0.80);
            g.lineStyle(0.5, col, 0.25);
            g.moveTo(-hw * 0.3, -hh);     // top-left
            g.lineTo(hw, -hh);             // top-right
            g.lineTo(hw, hh);              // bottom-right
            g.lineTo(-hw * 0.3, hh);       // bottom-left
            g.lineTo(-hw, 0);              // arrow point
            g.lineTo(-hw * 0.3, -hh);      // close
            g.endFill();

            // Warning triangle inside
            var triSize:Number = size * 0.35;
            var triCx:Number = hw * 0.3;
            var triCy:Number = 0;
            g.lineStyle(1, col, 0.85);
            g.beginFill(col, 0.15);
            g.moveTo(triCx, triCy - triSize);
            g.lineTo(triCx + triSize * 0.8, triCy + triSize * 0.5);
            g.lineTo(triCx - triSize * 0.8, triCy + triSize * 0.5);
            g.lineTo(triCx, triCy - triSize);
            g.endFill();

            // Exclamation mark
            g.lineStyle(0);
            g.beginFill(col, 0.90);
            g.drawRect(triCx - 0.75, triCy - triSize * 0.45, 1.5, triSize * 0.45);
            g.endFill();
            g.beginFill(col, 0.90);
            g.drawCircle(triCx, triCy + triSize * 0.25, 1);
            g.endFill();

            // Glow on badge
            if (level >= 2) {
                sp.filters = [new GlowFilter(col, 0.55, 8, 8, 2, 1)];
            } else {
                sp.filters = [new GlowFilter(col, 0.30, 6, 6, 1.2, 1)];
            }

            parent.addChild(sp);
            return sp;
        }

        // ================================================================
        // MAGAZINE ICON: silhouette with vertical fill level
        // ================================================================
        public static function drawMagIcon(
            parent:DisplayObjectContainer,
            x:Number, y:Number,
            w:Number = 10, h:Number = 24,
            fillPct:Number = 100,
            color:uint = 0,
            bgColor:uint = 0):Sprite {

            if (color == 0) {
                if (fillPct > 50) color = COL_ACCENT;
                else if (fillPct > 25) color = COL_AMBER;
                else color = COL_WARN;
            }
            if (bgColor == 0) bgColor = COL_BAR_BG;

            var sp:Sprite = new Sprite();
            sp.x = x; sp.y = y;
            var g:* = sp.graphics;
            var bodyH:Number = h - 4; // room for base plate

            // Background (empty mag body)
            g.beginFill(bgColor, 0.45);
            g.drawRect(0, 0, w, bodyH);
            g.endFill();

            // Fill level (bottom-up)
            if (fillPct > 0) {
                var fillH:Number = bodyH * (fillPct / 100);
                if (fillH > bodyH) fillH = bodyH;
                g.beginFill(color, 0.80);
                g.drawRect(0, bodyH - fillH, w, fillH);
                g.endFill();
            }

            // Outline hint
            g.lineStyle(0.5, color, 0.30);
            g.drawRect(0, 0, w, bodyH);

            // Base plate (wider, below body)
            g.lineStyle(0);
            g.beginFill(color, 0.50);
            g.drawRect(-1, bodyH + 1, w + 2, 3);
            g.endFill();

            // Glow when low
            if (fillPct < 30) {
                sp.filters = [new GlowFilter(color, 0.35, 4, 4, 1.5, 1)];
            }

            parent.addChild(sp);
            return sp;
        }

        // ================================================================
        // DOT CLUSTER: small grid of decorative dots
        // ================================================================
        public static function drawDotCluster(
            parent:DisplayObjectContainer,
            x:Number, y:Number,
            rows:int = 2, cols:int = 3,
            spacing:Number = 3,
            color:uint = 0,
            alpha:Number = 0.30):Shape {

            if (color == 0) color = COL_FRAME_LIGHT;
            var s:Shape = new Shape();
            var g:* = s.graphics;
            for (var r:int = 0; r < rows; r++) {
                for (var c:int = 0; c < cols; c++) {
                    g.beginFill(color, alpha);
                    g.drawCircle(x + c * spacing, y + r * spacing, 0.8);
                    g.endFill();
                }
            }
            parent.addChild(s);
            return s;
        }

        // ================================================================
        // TICK STRIP: row of tiny vertical bars (decorative density)
        // ================================================================
        public static function drawTickStrip(
            parent:DisplayObjectContainer,
            x:Number, y:Number,
            count:int = 8, tickW:Number = 2,
            tickH:Number = 4, spacing:Number = 2,
            color:uint = 0, alpha:Number = 0.25):Shape {

            if (color == 0) color = COL_FRAME_LIGHT;
            var s:Shape = new Shape();
            var g:* = s.graphics;
            for (var i:int = 0; i < count; i++) {
                g.beginFill(color, alpha);
                g.drawRect(x + i * (tickW + spacing), y, tickW, tickH);
                g.endFill();
            }
            parent.addChild(s);
            return s;
        }

        // ================================================================
        // ALERT ICON: speaker/megaphone with sound waves
        // ================================================================
        public static function drawAlertIcon(
            parent:DisplayObjectContainer,
            cx:Number, cy:Number,
            size:Number, color:uint,
            alpha:Number = 0.85):Shape {

            var s:Shape = new Shape();
            var g:* = s.graphics;
            var h2:Number = size * 0.5;

            // Speaker body (trapezoid)
            g.beginFill(color, alpha);
            g.moveTo(cx - h2 * 0.6, cy - h2 * 0.3);
            g.lineTo(cx - h2 * 0.2, cy - h2 * 0.3);
            g.lineTo(cx + h2 * 0.2, cy - h2 * 0.65);
            g.lineTo(cx + h2 * 0.2, cy + h2 * 0.65);
            g.lineTo(cx - h2 * 0.2, cy + h2 * 0.3);
            g.lineTo(cx - h2 * 0.6, cy + h2 * 0.3);
            g.lineTo(cx - h2 * 0.6, cy - h2 * 0.3);
            g.endFill();

            // Sound waves (arcs)
            for (var w:int = 1; w <= 2; w++) {
                var waveR:Number = h2 * (0.4 + w * 0.25);
                var waveAlpha:Number = alpha * (0.6 - w * 0.15);
                g.lineStyle(1, color, waveAlpha);
                var arcSteps:int = 8;
                for (var i:int = 0; i <= arcSteps; i++) {
                    var t:Number = i / arcSteps;
                    var angle:Number = (-0.35 + t * 0.70) * Math.PI;
                    var px:Number = cx + h2 * 0.2 + Math.cos(angle) * waveR;
                    var py:Number = cy + Math.sin(angle) * waveR;
                    if (i == 0) g.moveTo(px, py);
                    else g.lineTo(px, py);
                }
            }

            parent.addChild(s);
            return s;
        }

        // ================================================================
        // DOT GRID ROW: 2px circles evenly spaced
        // Layering element — sits under header bands.
        // ================================================================
        public static function drawDotGrid(
            parent:DisplayObjectContainer,
            x:Number, y:Number,
            w:Number,
            spacing:Number = 6,
            dotRadius:Number = 1.2,
            color:uint = 0,
            alpha:Number = 0.30):Shape {

            if (color == 0) color = COL_BORDER;
            var s:Shape = new Shape();
            var g:* = s.graphics;
            var count:int = int(w / spacing);
            for (var i:int = 0; i < count; i++) {
                g.beginFill(color, (i % 3 == 0) ? alpha * 1.5 : alpha);
                g.drawCircle(x + i * spacing + dotRadius, y, dotRadius);
                g.endFill();
            }
            parent.addChild(s);
            return s;
        }

        // ================================================================
        // MICRO BAR STRIP: tiny vertical bars in a row
        // Data density element — bar graph visualization.
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
        // SIGNAL BARS: WiFi/detection strength indicator
        // 4 bars of increasing height.
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
        // ACCENT BLOCK: bold colored rectangle (replaces thin ticks)
        // ================================================================
        public static function drawAccentBlock(
            parent:DisplayObjectContainer,
            x:Number, y:Number,
            w:Number, h:Number,
            color:uint,
            alpha:Number = 0.85):Shape {

            var s:Shape = new Shape();
            s.graphics.beginFill(color, alpha);
            s.graphics.drawRect(x, y, w, h);
            s.graphics.endFill();
            parent.addChild(s);
            return s;
        }

        // ================================================================
        // LAYERED HEADER: header band only (clean, no black lines)
        // Returns: {band:Shape, bottomY:Number}
        // ================================================================
        public static function drawLayeredHeader(
            parent:DisplayObjectContainer,
            w:Number, color:uint,
            label:String = "",
            bandAlpha:Number = 0.80):Object {

            var result:Object = {};

            // Header band (26px tall, full width, bold)
            var band:Shape = drawHeaderBand(parent, 0, 0, w, HEADER_BAND_H, color, bandAlpha);
            result.band = band;

            // Label on the band (centered vertically in 26px)
            if (label.length > 0) {
                var lbl:TextField = makeLabel(parent, label, 11, 0.95, 0xFFFFFF);
                lbl.x = 6;
                lbl.y = 5;
            }

            result.bottomY = HEADER_BAND_H + 2;
            return result;
        }

        // ================================================================
        // RECOLOR LAYERED HEADER (band only)
        // ================================================================
        public static function recolorLayeredHeader(
            parts:Object, w:Number, color:uint, bandAlpha:Number = 0.80):void {

            if (!parts) return;

            // Recolor band
            if (parts.band) {
                var bg:* = (parts.band as Shape).graphics;
                bg.clear();
                bg.beginFill(color, bandAlpha);
                bg.drawRect(0, 0, w, HEADER_BAND_H);
                bg.endFill();
                bg.lineStyle(1, 0xFFFFFF, 0.15);
                bg.moveTo(0, HEADER_BAND_H);
                bg.lineTo(w, HEADER_BAND_H);
                bg.lineStyle(1, 0xFFFFFF, 0.08);
                bg.moveTo(2, 0);
                bg.lineTo(w - 2, 0);
            }
        }

        // ================================================================
        // RING ARC: draw an arc segment (for ring gauges)
        // startAngle/endAngle in degrees, clockwise from top (0=top)
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
        // TICK MARKS around a ring
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
                var t:Number = i / tickCount;
                var angleDeg:Number = startAngle + t * (endAngle - startAngle);
                var angleRad:Number = (angleDeg - 90) * Math.PI / 180;
                var isMajor:Boolean = (i % majorEvery == 0);
                var inner:Number = radius - (isMajor ? innerLen * 1.5 : innerLen);
                var outer:Number = radius + outerLen;

                g.lineStyle(isMajor ? W_SECONDARY : W_TERTIARY, color, isMajor ? alpha * 1.5 : alpha);
                g.moveTo(cx + Math.cos(angleRad) * inner, cy + Math.sin(angleRad) * inner);
                g.lineTo(cx + Math.cos(angleRad) * outer, cy + Math.sin(angleRad) * outer);
            }

            parent.addChild(s);
            return s;
        }

        // ================================================================
        // SEGMENTED BAR
        // ================================================================
        public static function drawSegmentedBar(parent:DisplayObjectContainer,
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
                bar.graphics.beginFill(isFilled ? fillColor : bgColor, isFilled ? 0.85 : 0.30);
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
        // CONTINUOUS BAR
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
            bar.x = x; bar.y = y;
            bar.graphics.beginFill(bgColor, 0.45);
            bar.graphics.drawRect(0, 0, w, h);
            bar.graphics.endFill();
            if (pct > 0) {
                bar.graphics.beginFill(fillColor, 0.85);
                bar.graphics.drawRect(0, 0, w * (pct / 100), h);
                bar.graphics.endFill();
            }
            parent.addChild(bar);
            return bar;
        }

        // ================================================================
        // TECH BAR GRAPH
        // ================================================================
        public static function drawTechBarGraph(parent:DisplayObjectContainer,
            x:Number, y:Number, w:Number, h:Number,
            pct:Number, segments:int = 20,
            color:uint = 0, bgColor:uint = 0):Sprite {
            if (color == 0) color = COL_BAR_FILL;
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
                var filled:Boolean = (i < fillCount);
                bar.graphics.beginFill(filled ? color : bgColor, filled ? 0.80 : 0.25);
                bar.graphics.drawRect(sx, 0, segW, h);
                bar.graphics.endFill();
            }
            bar.graphics.lineStyle(0.5, color, 0.30);
            bar.graphics.drawRect(-1, -1, w + 2, h + 2);
            parent.addChild(bar);
            return bar;
        }

        // ================================================================
        // SCAN LINE
        // ================================================================
        public static function drawScanLine(parent:DisplayObjectContainer,
                                             w:Number,
                                             color:uint = 0,
                                             alpha:Number = 0.08):Shape {
            if (color == 0) color = COL_ACCENT;
            var s:Shape = new Shape();
            var g:* = s.graphics;
            g.beginFill(color, alpha * 0.3);
            g.drawRect(0, -2, w, 5);
            g.endFill();
            g.beginFill(color, alpha);
            g.drawRect(0, 0, w, 1);
            g.endFill();
            parent.addChild(s);
            return s;
        }

        // ================================================================
        // LABEL
        // ================================================================
        public static function makeLabel(parent:DisplayObjectContainer,
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

        // ================================================================
        // VALUE
        // ================================================================
        public static function makeValue(parent:DisplayObjectContainer,
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

        // ================================================================
        // DATA TAG
        // ================================================================
        public static function makeDataTag(parent:DisplayObjectContainer,
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
        // DIVIDER
        // ================================================================
        public static function drawDivider(parent:DisplayObjectContainer,
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
        // DOT PATTERN
        // ================================================================
        public static function drawDotPattern(parent:DisplayObjectContainer,
                                               x:Number, y:Number,
                                               count:int = 3,
                                               spacing:Number = 4,
                                               color:uint = 0,
                                               alpha:Number = 0.30):Shape {
            if (color == 0) color = COL_BORDER;
            var s:Shape = new Shape();
            var g:* = s.graphics;
            for (var i:int = 0; i < count; i++) {
                g.beginFill(color, (i == 0) ? alpha * 1.4 : alpha);
                g.drawCircle(x + i * spacing, y, 1.2);
                g.endFill();
            }
            parent.addChild(s);
            return s;
        }

        // ================================================================
        // EYE ICON
        // ================================================================
        public static function drawEyeIcon(parent:DisplayObjectContainer,
                                            cx:Number, cy:Number,
                                            size:Number, color:uint,
                                            alpha:Number = 0.9):Shape {
            var s:Shape = new Shape();
            var g:* = s.graphics;
            var hw:Number = size * 0.5;
            var hh:Number = size * 0.28;
            g.lineStyle(W_TERTIARY, color, alpha);
            g.moveTo(cx - hw, cy);
            g.curveTo(cx, cy - hh * 2.2, cx + hw, cy);
            g.moveTo(cx - hw, cy);
            g.curveTo(cx, cy + hh * 2.2, cx + hw, cy);
            g.lineStyle(0);
            g.beginFill(color, alpha * 0.65);
            g.drawCircle(cx, cy, hh * 0.85);
            g.endFill();
            g.beginFill(COL_BG, 0.95);
            g.drawCircle(cx, cy, hh * 0.35);
            g.endFill();
            parent.addChild(s);
            return s;
        }

        // ================================================================
        // ICONS: crosshair, bolt, heart, warning
        // ================================================================
        public static function drawCrosshairIcon(parent:DisplayObjectContainer,
            cx:Number, cy:Number, size:Number, color:uint, alpha:Number = 0.85):Shape {
            var s:Shape = new Shape(); var g:* = s.graphics;
            var r:Number = size * 0.5; var gap:Number = size * 0.18;
            g.lineStyle(1, color, alpha * 0.6);
            var steps:int = 32;
            for (var i:int = 0; i <= steps; i++) {
                var angle:Number = (i / steps) * Math.PI * 2;
                var px:Number = cx + Math.cos(angle) * r;
                var py:Number = cy + Math.sin(angle) * r;
                if (i == 0) g.moveTo(px, py); else g.lineTo(px, py);
            }
            g.lineStyle(1, color, alpha);
            g.moveTo(cx - r, cy); g.lineTo(cx - gap, cy);
            g.moveTo(cx + gap, cy); g.lineTo(cx + r, cy);
            g.moveTo(cx, cy - r); g.lineTo(cx, cy - gap);
            g.moveTo(cx, cy + gap); g.lineTo(cx, cy + r);
            g.lineStyle(0); g.beginFill(color, alpha * 0.7);
            g.drawCircle(cx, cy, 1); g.endFill();
            parent.addChild(s); return s;
        }

        public static function drawBoltIcon(parent:DisplayObjectContainer,
            cx:Number, cy:Number, size:Number, color:uint, alpha:Number = 0.85):Shape {
            var s:Shape = new Shape(); var g:* = s.graphics;
            var h2:Number = size * 0.5; var w2:Number = size * 0.28;
            g.beginFill(color, alpha);
            g.moveTo(cx + w2 * 0.2, cy - h2);
            g.lineTo(cx - w2 * 0.6, cy + h2 * 0.1);
            g.lineTo(cx + w2 * 0.1, cy + h2 * 0.1);
            g.lineTo(cx - w2 * 0.2, cy + h2);
            g.lineTo(cx + w2 * 0.6, cy - h2 * 0.1);
            g.lineTo(cx - w2 * 0.1, cy - h2 * 0.1);
            g.lineTo(cx + w2 * 0.2, cy - h2);
            g.endFill();
            parent.addChild(s); return s;
        }

        public static function drawHeartIcon(parent:DisplayObjectContainer,
            cx:Number, cy:Number, size:Number, color:uint, alpha:Number = 0.85):Shape {
            var s:Shape = new Shape(); var g:* = s.graphics;
            var h2:Number = size * 0.5;
            g.beginFill(color, alpha);
            g.moveTo(cx, cy + h2 * 0.7);
            g.lineTo(cx - h2 * 0.95, cy - h2 * 0.1);
            g.curveTo(cx - h2 * 0.5, cy - h2 * 0.95, cx, cy - h2 * 0.25);
            g.curveTo(cx + h2 * 0.5, cy - h2 * 0.95, cx + h2 * 0.95, cy - h2 * 0.1);
            g.lineTo(cx, cy + h2 * 0.7);
            g.endFill();
            parent.addChild(s); return s;
        }

        public static function drawWarningIcon(parent:DisplayObjectContainer,
            cx:Number, cy:Number, size:Number, color:uint, alpha:Number = 0.85):Shape {
            var s:Shape = new Shape(); var g:* = s.graphics;
            var h2:Number = size * 0.5;
            g.lineStyle(1, color, alpha);
            g.beginFill(color, alpha * 0.12);
            g.moveTo(cx, cy - h2);
            g.lineTo(cx + h2 * 0.9, cy + h2 * 0.6);
            g.lineTo(cx - h2 * 0.9, cy + h2 * 0.6);
            g.lineTo(cx, cy - h2);
            g.endFill();
            g.lineStyle(0);
            g.beginFill(color, alpha);
            g.drawRect(cx - 0.75, cy - h2 * 0.25, 1.5, h2 * 0.45);
            g.endFill();
            g.beginFill(color, alpha);
            g.drawCircle(cx, cy + h2 * 0.35, 1);
            g.endFill();
            parent.addChild(s); return s;
        }

        // ================================================================
        // GLOW / STATE / PULSE
        // ================================================================
        public static function applyState(target:*, state:int):void {
            switch (state) {
                case STATE_ACTIVE:
                    target.filters = [new GlowFilter(COL_ACCENT, 0.45, 6, 6, 1.2, 2)];
                    break;
                case STATE_WARN:
                    target.filters = [new GlowFilter(COL_WARN, 0.55, 8, 8, 1.5, 2)];
                    break;
                default:
                    target.filters = [];
            }
        }

        public static function applyNeonGlow(target:*, color:uint,
                                              intensity:Number = 1.0):void {
            var blur:Number = 4 + intensity * 8;
            var str:Number = 1.2 + intensity * 1.2;
            var a:Number = 0.45 + intensity * 0.35;
            target.filters = [new GlowFilter(color, a, blur, blur, str, 2)];
        }

        public static function pulseValue(base:Number, amp:Number,
                                           frame:int, speed:Number = 0.05):Number {
            return base + Math.sin(frame * speed) * amp;
        }

        public static function drawRingIndicator(parent:DisplayObjectContainer,
            cx:Number, cy:Number, radius:Number, pct:Number,
            color:uint, alpha:Number = 0.6):Shape {
            var s:Shape = new Shape(); var g:* = s.graphics;
            if (pct > 1) pct = 1; if (pct < 0) pct = 0;
            var bgSteps:int = 32;
            g.lineStyle(1.5, COL_BORDER, 0.15);
            for (var b:int = 0; b <= bgSteps; b++) {
                var ba:Number = (b / bgSteps) * Math.PI * 2 - Math.PI * 0.5;
                var bx:Number = cx + Math.cos(ba) * radius;
                var by:Number = cy + Math.sin(ba) * radius;
                if (b == 0) g.moveTo(bx, by); else g.lineTo(bx, by);
            }
            if (pct > 0) {
                var fillSteps:int = int(pct * 32);
                if (fillSteps < 1) fillSteps = 1;
                g.lineStyle(2, color, alpha);
                for (var f:int = 0; f <= fillSteps; f++) {
                    var fa:Number = (f / 32) * Math.PI * 2 - Math.PI * 0.5;
                    var fx:Number = cx + Math.cos(fa) * radius;
                    var fy:Number = cy + Math.sin(fa) * radius;
                    if (f == 0) g.moveTo(fx, fy); else g.lineTo(fx, fy);
                }
            }
            parent.addChild(s); return s;
        }
    }
}
