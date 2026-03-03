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
     * LoreOut Combat Widget — ammo/weapon status panel.
     *
     * Bottom-right placement. Minimal C2 dashboard aesthetic.
     * All rendering via UIPrimitives. Zero imported assets.
     *
     * CMD_COMBAT_UPDATE (200): 6 floats
     *   param[0] = mag count
     *   param[1] = reserve count
     *   param[2] = fire mode enum (0=SINGLE, 1=AUTO, 2=BURST)
     *   param[3] = condition percent (0-100)
     *   param[4] = threat enum (0=CALM, 1=CAUTION, 2=COMBAT)
     *   param[5] = reserved
     */
    public class LoreOutCombatWidget extends MovieClip implements IHUDWidget {

        // ---- COMMANDS ----
        private static const CMD_COMBAT_UPDATE:int = 200;

        // ---- LAYOUT (snapped to 8px grid) ----
        private static const PANEL_W:int = 160;   // 20 grid units
        private static const PANEL_H:int = 88;    // 11 grid units
        private static const PAD:int = 8;          // 1 grid unit

        // ---- FIRE MODE LABELS ----
        private static const FIRE_MODES:Array = ["SINGLE", "AUTO", "BURST"];

        // ---- THREAT STATE NAMES ----
        private static const THREAT_NAMES:Array = ["CALM", "CAUTION", "COMBAT"];

        // ---- DISPLAY ELEMENTS ----
        private var panelBg:Shape;
        private var cornerTicks:Shape;
        private var divider:Shape;

        private var magLabel:TextField;
        private var magValue:TextField;
        private var reserveLabel:TextField;
        private var reserveValue:TextField;
        private var modeLabel:TextField;
        private var condBar:Sprite;
        private var condLabel:TextField;
        private var threatDot:Shape;

        // ---- STATE ----
        private var currentThreat:int = 0;
        private var condBarW:Number = PANEL_W - PAD * 2;

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

            // ---- TOP ROW: mag count (big) + reserve (small) ----

            // "MAG" label
            magLabel = UIPrimitives.makeLabel(this, "MAG", 9);
            magLabel.x = PAD;
            magLabel.y = PAD - 2;

            // Magazine count — large readout
            magValue = UIPrimitives.makeValue(this, "---", 28);
            magValue.x = PAD;
            magValue.y = PAD + 10;
            magValue.width = 72;

            // Vertical divider between mag and reserve
            divider = UIPrimitives.drawDivider(this,
                PAD + 72, PAD + 4,
                PAD + 72, PAD + 44,
                UIPrimitives.BORDER_ALPHA * 1.5);

            // "RES" label
            reserveLabel = UIPrimitives.makeLabel(this, "RES", 9);
            reserveLabel.x = PAD + 80;
            reserveLabel.y = PAD - 2;

            // Reserve count
            reserveValue = UIPrimitives.makeValue(this, "---", 16);
            reserveValue.x = PAD + 80;
            reserveValue.y = PAD + 12;
            reserveValue.width = 56;

            // Fire mode below reserve
            modeLabel = UIPrimitives.makeLabel(this, "SINGLE", 10, -1, UIPrimitives.COL_ACCENT);
            modeLabel.x = PAD + 80;
            modeLabel.y = PAD + 32;
            modeLabel.width = 64;

            // ---- HORIZONTAL DIVIDER ----
            UIPrimitives.drawDivider(this,
                PAD, PAD + 52,
                PANEL_W - PAD, PAD + 52,
                UIPrimitives.BORDER_ALPHA);

            // ---- BOTTOM ROW: condition bar + label ----

            // "COND" label
            condLabel = UIPrimitives.makeLabel(this, "COND", 9);
            condLabel.x = PAD;
            condLabel.y = PAD + 55;

            // Condition bar (initially 100%)
            condBar = UIPrimitives.drawBar(this,
                PAD, PAD + 68,
                condBarW, 3,
                100);

            // Threat state dot (small circle, left of COND label)
            threatDot = new Shape();
            threatDot.graphics.beginFill(UIPrimitives.COL_ACCENT, 0.8);
            threatDot.graphics.drawCircle(0, 0, 3);
            threatDot.graphics.endFill();
            threatDot.x = PANEL_W - PAD - 3;
            threatDot.y = PAD + 62;
            addChild(threatDot);
        }

        // ================================================================
        // PLACEHOLDER — show before Papyrus sends real data
        // ================================================================
        private function showPlaceholder():void {
            updateDisplay(30, 120, 1, 85, 0);
        }

        // ================================================================
        // UPDATE — called when CMD_COMBAT_UPDATE arrives
        // ================================================================
        private function updateDisplay(mag:int, reserve:int, fireMode:int,
                                        condPct:Number, threat:int):void {
            // Mag count
            magValue.text = padNum(mag, 3);

            // Reserve count
            reserveValue.text = padNum(reserve, 3);

            // Fire mode
            if (fireMode >= 0 && fireMode < FIRE_MODES.length) {
                modeLabel.text = FIRE_MODES[fireMode];
            }

            // Condition bar — redraw
            if (condBar && condBar.parent) {
                condBar.parent.removeChild(condBar);
            }
            var barColor:uint = UIPrimitives.COL_BAR_FILL;
            if (condPct < 25) {
                barColor = UIPrimitives.COL_WARN;
            } else if (condPct < 50) {
                barColor = 0xCC8822; // amber warning
            }
            condBar = UIPrimitives.drawBar(this,
                PAD, PAD + 68,
                condBarW, 3,
                condPct,
                barColor);

            // Threat state
            currentThreat = threat;
            updateThreatVisual();
        }

        private function updateThreatVisual():void {
            // Redraw threat dot with state color
            threatDot.graphics.clear();
            var col:uint;
            switch (currentThreat) {
                case 2:  col = UIPrimitives.COL_WARN;   break;  // COMBAT
                case 1:  col = 0xCC8822;                break;  // CAUTION
                default: col = UIPrimitives.COL_ACCENT;  break;  // CALM
            }
            threatDot.graphics.beginFill(col, 0.85);
            threatDot.graphics.drawCircle(0, 0, 3);
            threatDot.graphics.endFill();

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

            if (cmd == CMD_COMBAT_UPDATE && params && params.length >= 5) {
                updateDisplay(
                    int(params[0]),     // mag
                    int(params[1]),     // reserve
                    int(params[2]),     // fireMode
                    Number(params[3]),  // condPct
                    int(params[4])      // threat
                );
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
