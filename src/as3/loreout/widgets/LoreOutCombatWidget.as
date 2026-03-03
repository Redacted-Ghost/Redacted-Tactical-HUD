package loreout.widgets {
    import flash.display.MovieClip;
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    import hudframework.IHUDWidget;
    import loreout.ui.UIPrimitives;

    /**
     * LoreOut Combat Widget — live ammo/weapon/threat status panel.
     *
     * Bottom-right placement. Minimal C2 dashboard aesthetic.
     * All rendering via UIPrimitives. Zero imported assets.
     * Data sourced from Lighthouse Papyrus Extender (validated by probe).
     *
     * Layout:
     *   ┌──────────────────────────────────┐
     *   │ MK18                    ● CLEAR  │  weapon + threat
     *   ├──────────────────────────────────┤
     *   │ MAG            │ RES             │
     *   │  012/030       │    470          │  mag current/max + reserve
     *   │                │  15 MAGS        │  spare magazines
     *   ├──────────────────────────────────┤
     *   │ ▌▌▌▌▌▌▌░░░░░░░░░░░░░░░░░░░░░░ │  mag fill bar
     *   │ 5.56mm                     ×0   │  ammo type + hostile count
     *   └──────────────────────────────────┘
     *
     * CMD 200 (floats): magCur, magCap, reserve, spareMags, threat, hostiles
     * CMD 201 (string): weapon name
     * CMD 202 (string): ammo type name
     */
    public class LoreOutCombatWidget extends MovieClip implements IHUDWidget {

        // ---- COMMANDS ----
        private static const CMD_COMBAT_UPDATE:int = 200;
        private static const CMD_WEAPON_NAME:int = 201;
        private static const CMD_AMMO_TYPE:int = 202;

        // ---- LAYOUT (snapped to 8px grid) ----
        private static const PANEL_W:int = 160;   // 20 grid units
        private static const PANEL_H:int = 88;    // 11 grid units
        private static const PAD:int = 8;          // 1 grid unit

        // ---- DISPLAY ELEMENTS ----
        private var panelBg:Shape;
        private var cornerTicks:Shape;

        // Top row: weapon name + threat indicator
        private var weaponField:TextField;
        private var threatDot:Shape;
        private var threatField:TextField;

        // Middle: ammo data
        private var magLabel:TextField;
        private var magValue:TextField;
        private var reserveLabel:TextField;
        private var reserveValue:TextField;
        private var spareMagsField:TextField;

        // Bottom: mag bar + ammo type + hostiles
        private var magBar:Sprite;
        private var ammoTypeField:TextField;
        private var hostileField:TextField;

        // ---- STATE ----
        private var currentThreat:int = 0;
        private var barW:Number = PANEL_W - PAD * 2;

        public function LoreOutCombatWidget() {
            super();
            buildUI();
            showPlaceholder();
        }

        // ================================================================
        // BUILD UI — all via UIPrimitives
        // ================================================================
        private function buildUI():void {
            // Panel background
            panelBg = UIPrimitives.drawPanel(this, PANEL_W, PANEL_H);

            // Corner ticks (subtle tech feel)
            cornerTicks = UIPrimitives.drawCornerTicks(this, PANEL_W, PANEL_H, 5);

            // ── TOP ROW: weapon name + threat ──

            // Weapon name (accent color, left-aligned)
            weaponField = UIPrimitives.makeLabel(this, "--", 10, -1, UIPrimitives.COL_ACCENT);
            weaponField.x = PAD;
            weaponField.y = PAD - 5;
            weaponField.width = 92;

            // Threat dot (small circle)
            threatDot = new Shape();
            threatDot.graphics.beginFill(UIPrimitives.COL_ACCENT, 0.85);
            threatDot.graphics.drawCircle(0, 0, 3);
            threatDot.graphics.endFill();
            threatDot.x = PANEL_W - PAD - 38;
            threatDot.y = PAD + 2;
            addChild(threatDot);

            // Threat state text
            threatField = UIPrimitives.makeLabel(this, "CLEAR", 8);
            threatField.x = PANEL_W - PAD - 32;
            threatField.y = PAD - 6;
            threatField.width = 40;

            // Horizontal divider after top row
            UIPrimitives.drawDivider(this,
                PAD, PAD + 12,
                PANEL_W - PAD, PAD + 12,
                UIPrimitives.BORDER_ALPHA);

            // ── MIDDLE: ammo data ──

            // "MAG" label
            magLabel = UIPrimitives.makeLabel(this, "MAG", 9);
            magLabel.x = PAD;
            magLabel.y = PAD + 13;

            // Magazine count — "012/030" format
            magValue = UIPrimitives.makeValue(this, "---/---", 20);
            magValue.x = PAD;
            magValue.y = PAD + 23;
            magValue.width = 76;

            // Vertical divider between mag and reserve
            UIPrimitives.drawDivider(this,
                PAD + 76, PAD + 16,
                PAD + 76, PAD + 52,
                UIPrimitives.BORDER_ALPHA * 1.5);

            // "RES" label
            reserveLabel = UIPrimitives.makeLabel(this, "RES", 9);
            reserveLabel.x = PAD + 84;
            reserveLabel.y = PAD + 13;

            // Reserve count
            reserveValue = UIPrimitives.makeValue(this, "---", 16);
            reserveValue.x = PAD + 84;
            reserveValue.y = PAD + 25;
            reserveValue.width = 56;

            // Spare mags count
            spareMagsField = UIPrimitives.makeLabel(this, "-- MAGS", 9);
            spareMagsField.x = PAD + 84;
            spareMagsField.y = PAD + 42;
            spareMagsField.width = 56;

            // Horizontal divider before bottom section
            UIPrimitives.drawDivider(this,
                PAD, PAD + 54,
                PANEL_W - PAD, PAD + 54,
                UIPrimitives.BORDER_ALPHA);

            // ── BOTTOM: mag bar + ammo type + hostiles ──

            // Magazine fill bar (visual mag percentage)
            magBar = UIPrimitives.drawBar(this,
                PAD, PAD + 58,
                barW, 3,
                0);

            // Ammo type name (secondary text)
            ammoTypeField = UIPrimitives.makeLabel(this, "--", 9);
            ammoTypeField.x = PAD;
            ammoTypeField.y = PAD + 64;
            ammoTypeField.width = 90;

            // Hostile count (right-aligned)
            hostileField = UIPrimitives.makeLabel(this, "", 9);
            hostileField.x = PANEL_W - PAD - 40;
            hostileField.y = PAD + 64;
            hostileField.width = 40;
            var hfmt:TextFormat = hostileField.defaultTextFormat;
            hfmt.align = TextFormatAlign.RIGHT;
            hostileField.defaultTextFormat = hfmt;
            hostileField.setTextFormat(hfmt);
        }

        // ================================================================
        // PLACEHOLDER — show before Papyrus sends real data
        // ================================================================
        private function showPlaceholder():void {
            updateNumericData(0, 0, 0, 0, 0, 0);
        }

        // ================================================================
        // NUMERIC UPDATE — called when CMD_COMBAT_UPDATE (200) arrives
        // ================================================================
        private function updateNumericData(magCur:int, magCap:int, reserve:int,
                                            spareMags:int, threat:int,
                                            hostiles:int):void {
            // Mag count (current/capacity)
            if (magCap > 0) {
                magValue.text = padNum(magCur, 3) + "/" + padNum(magCap, 3);
            } else {
                magValue.text = "---/---";
            }

            // Reserve ammo
            if (reserve > 0 || magCap > 0) {
                reserveValue.text = String(reserve);
            } else {
                reserveValue.text = "---";
            }

            // Spare magazines
            spareMagsField.text = spareMags + " MAGS";

            // Mag fill bar — redraw with percentage
            if (magBar && magBar.parent) {
                magBar.parent.removeChild(magBar);
            }
            var magPct:Number = (magCap > 0) ? (magCur / magCap * 100) : 0;
            var barCol:uint = UIPrimitives.COL_BAR_FILL;
            if (magPct <= 0) {
                barCol = UIPrimitives.COL_BAR_FILL;
            } else if (magPct < 25) {
                barCol = UIPrimitives.COL_WARN;
            } else if (magPct < 50) {
                barCol = 0xCC8822;  // amber warning
            }
            magBar = UIPrimitives.drawBar(this,
                PAD, PAD + 58,
                barW, 3,
                magPct,
                barCol);

            // Hostile count
            var hostFmt:TextFormat = hostileField.defaultTextFormat;
            hostFmt.align = TextFormatAlign.RIGHT;
            if (hostiles > 0) {
                hostileField.text = "\u00D7" + hostiles;
                hostFmt.color = UIPrimitives.COL_WARN;
            } else {
                hostileField.text = "\u00D7" + "0";
                hostFmt.color = UIPrimitives.COL_TEXT_SEC;
            }
            hostileField.defaultTextFormat = hostFmt;
            hostileField.setTextFormat(hostFmt);

            // Threat state visual
            currentThreat = threat;
            updateThreatVisual();
        }

        // ================================================================
        // STRING UPDATES — weapon name and ammo type
        // ================================================================
        private function updateWeaponName(name:String):void {
            weaponField.text = (name.length > 0) ? name : "--";
        }

        private function updateAmmoType(name:String):void {
            // Strip "[Category] " prefix from mod ammo names
            var cleaned:String = name;
            var bracketEnd:int = name.indexOf("] ");
            if (bracketEnd >= 0 && name.charAt(0) == "[") {
                cleaned = name.substring(bracketEnd + 2);
            }
            ammoTypeField.text = (cleaned.length > 0) ? cleaned : "--";
        }

        // ================================================================
        // THREAT VISUAL — dot color + panel glow
        // ================================================================
        private function updateThreatVisual():void {
            // Redraw threat dot with state color
            threatDot.graphics.clear();
            var col:uint;
            var label:String;
            switch (currentThreat) {
                case 2:
                    col = UIPrimitives.COL_WARN;
                    label = "DANGER";
                    break;
                case 1:
                    col = 0xCC8822;
                    label = "CAUTION";
                    break;
                default:
                    col = UIPrimitives.COL_ACCENT;
                    label = "CLEAR";
                    break;
            }
            threatDot.graphics.beginFill(col, 0.85);
            threatDot.graphics.drawCircle(0, 0, 3);
            threatDot.graphics.endFill();

            // Update threat label text and color
            threatField.text = label;
            var tfmt:TextFormat = threatField.defaultTextFormat;
            tfmt.color = col;
            threatField.defaultTextFormat = tfmt;
            threatField.setTextFormat(tfmt);

            // Panel glow state
            if (currentThreat == 2) {
                UIPrimitives.applyState(panelBg, UIPrimitives.STATE_WARN);
            } else if (currentThreat == 1) {
                UIPrimitives.applyState(panelBg, UIPrimitives.STATE_ACTIVE);
            } else {
                UIPrimitives.applyState(panelBg, UIPrimitives.STATE_IDLE);
            }
        }

        // ================================================================
        // PROCESS MESSAGE — HUDFramework callback
        // ================================================================
        public function processMessage(command:String, params:Array):void {
            var cmd:int = parseInt(command);

            if (cmd == CMD_COMBAT_UPDATE && params && params.length >= 6) {
                updateNumericData(
                    int(params[0]),     // magCurrent
                    int(params[1]),     // magCapacity
                    int(params[2]),     // reserve
                    int(params[3]),     // spareMags
                    int(params[4]),     // threat
                    int(params[5])      // hostiles
                );
            } else if (cmd == CMD_WEAPON_NAME && params && params.length >= 1) {
                updateWeaponName(String(params[0]));
            } else if (cmd == CMD_AMMO_TYPE && params && params.length >= 1) {
                updateAmmoType(String(params[0]));
            }
        }

        // ================================================================
        // UTILITY
        // ================================================================
        private function padNum(n:int, digits:int):String {
            var s:String = String(n);
            while (s.length < digits) s = "0" + s;
            return s;
        }
    }
}
