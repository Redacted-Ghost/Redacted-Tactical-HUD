package loreout.widgets {
    import flash.display.MovieClip;
    import flash.display.Shape;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.utils.Timer;
    import flash.events.TimerEvent;
    import hudframework.IHUDWidget;
    import loreout.ui.UIPrimitives;

    /**
     * LoreOut Status Widget — stealth/awareness indicator.
     *
     * Displays a programmatic eye icon with cycling contextual messages.
     * State-driven: CALM / STEALTH / COMBAT.
     * Positioned directly above the combat widget panel.
     *
     * CMD_STATUS_UPDATE (201): 1 float
     *   param[0] = threat enum (0=CALM, 1=STEALTH, 2=COMBAT)
     *
     * Inspired by the target concept: eye icon + "SAFE" / "CONCEALED" / "DANGER"
     */
    public class LoreOutStatusWidget extends MovieClip implements IHUDWidget {

        // ---- COMMANDS ----
        private static const CMD_STATUS_UPDATE:int = 201;

        // ---- LAYOUT (matches combat widget width) ----
        private static const PANEL_W:int = 160;
        private static const PANEL_H:int = 28;
        private static const PAD:int = 8;

        // ---- MESSAGE CYCLE INTERVAL (ms) ----
        private static const CYCLE_MS:int = 3000;

        // ---- MESSAGE POOLS ----
        private static const MSG_CALM:Array = [
            "SECTOR CLEAR",
            "NO CONTACTS",
            "SAFE"
        ];
        private static const MSG_STEALTH:Array = [
            "CONCEALED",
            "UNDETECTED",
            "GHOST ACTIVE"
        ];
        private static const MSG_COMBAT:Array = [
            "DANGER - TAKE COVER",
            "HOSTILE CONTACT",
            "ENGAGING"
        ];

        // ---- DISPLAY ELEMENTS ----
        private var panelBg:Shape;
        private var eyeIcon:Shape;
        private var statusText:TextField;

        // ---- STATE ----
        private var currentThreat:int = 0;
        private var msgIndex:int = 0;
        private var cycleTimer:Timer;

        // ---- EYE POSITION ----
        private static const EYE_CX:Number = PAD + 10;
        private static const EYE_CY:Number = PANEL_H * 0.5;
        private static const EYE_SIZE:Number = 16;

        public function LoreOutStatusWidget() {
            super();
            buildUI();
            setThreatState(0);
            startCycling();
        }

        // ================================================================
        // BUILD UI
        // ================================================================
        private function buildUI():void {
            // Panel background (same style as combat widget)
            panelBg = UIPrimitives.drawPanel(this, PANEL_W, PANEL_H);

            // Corner ticks (shorter than combat for compact feel)
            UIPrimitives.drawCornerTicks(this, PANEL_W, PANEL_H, 4);

            // Eye icon — centered left area
            eyeIcon = UIPrimitives.drawEyeIcon(this,
                EYE_CX, EYE_CY, EYE_SIZE,
                UIPrimitives.COL_ACCENT);

            // Status text — right of eye
            var fmt:TextFormat = new TextFormat();
            fmt.font = UIPrimitives.FONT;
            fmt.size = 11;
            fmt.color = UIPrimitives.COL_ACCENT;
            fmt.letterSpacing = 1;

            statusText = new TextField();
            statusText.defaultTextFormat = fmt;
            statusText.textColor = UIPrimitives.COL_ACCENT;
            statusText.alpha = UIPrimitives.TEXT_PRI_ALPHA;
            statusText.selectable = false;
            statusText.mouseEnabled = false;
            statusText.x = PAD + 24;
            statusText.y = (PANEL_H - 18) * 0.5;
            statusText.width = PANEL_W - PAD - 24;
            statusText.height = 20;
            statusText.text = "SECTOR CLEAR";
            addChild(statusText);
        }

        // ================================================================
        // CYCLING TIMER
        // ================================================================
        private function startCycling():void {
            cycleTimer = new Timer(CYCLE_MS);
            cycleTimer.addEventListener(TimerEvent.TIMER, onCycle);
            cycleTimer.start();
        }

        private function onCycle(e:TimerEvent):void {
            var pool:Array = getMessagePool();
            msgIndex = (msgIndex + 1) % pool.length;
            statusText.text = pool[msgIndex];
        }

        private function getMessagePool():Array {
            switch (currentThreat) {
                case 2:  return MSG_COMBAT;
                case 1:  return MSG_STEALTH;
                default: return MSG_CALM;
            }
        }

        // ================================================================
        // THREAT STATE — recolor eye + text + panel glow
        // ================================================================
        private function setThreatState(threat:int):void {
            if (threat == currentThreat && msgIndex > 0) {
                return; // Same state, let cycling continue
            }

            currentThreat = threat;
            msgIndex = 0;

            // Update text from new pool
            var pool:Array = getMessagePool();
            statusText.text = pool[0];

            // State color
            var col:uint;
            switch (threat) {
                case 2:  col = UIPrimitives.COL_WARN;   break;   // red
                case 1:  col = UIPrimitives.COL_ACCENT;  break;   // teal
                default: col = UIPrimitives.COL_ACCENT;  break;   // teal
            }

            // Recolor text
            statusText.textColor = col;

            // Redraw eye with new color
            if (eyeIcon && eyeIcon.parent) {
                eyeIcon.parent.removeChild(eyeIcon);
            }
            eyeIcon = UIPrimitives.drawEyeIcon(this,
                EYE_CX, EYE_CY, EYE_SIZE, col);

            // Panel glow state
            if (threat == 2) {
                UIPrimitives.applyState(panelBg, UIPrimitives.STATE_WARN);
            } else if (threat == 1) {
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

            if (cmd == CMD_STATUS_UPDATE && params && params.length >= 1) {
                setThreatState(int(params[0]));
            }
        }
    }
}
