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
     * LoreOut Combat Widget v12 — Tactical Data Panel.
     *
     * 320x130 Cyberpunk-style layered data panel:
     *   - Coordinate references above panel
     *   - Weapon name + threat status badge header
     *   - Large ammo readout (MAG) + reserve count
     *   - Ammo type + hostile count + threat dot
     *   - Animated "SCANNING" status line
     *
     * White/grey monochrome, red for danger only.
     *
     * CMD 200 (floats): magCur, magCap, reserve, spareMags, threat, hostiles
     * CMD 201 (string): weapon name
     * CMD 202 (string): ammo type name
     */
    public class LoreOutCombatWidget extends MovieClip implements IHUDWidget {

        private static const CMD_COMBAT_UPDATE:int = 200;
        private static const CMD_WEAPON_NAME:int = 201;
        private static const CMD_AMMO_TYPE:int = 202;

        private static const PANEL_W:int = 320;
        private static const PANEL_H:int = 130;
        private static const PAD:int = 10;

        // Elements
        private var panelBg:Shape;
        private var threatBadge:Sprite;
        private var threatDot:Shape;
        private var alertIcon:Shape;

        // Text fields
        private var weaponField:TextField;
        private var ammoField:TextField;
        private var magLabel:TextField;
        private var reserveField:TextField;
        private var reserveLabel:TextField;
        private var ammoTypeField:TextField;
        private var hostileField:TextField;
        private var scanField:TextField;

        // State
        private var currentThreat:int = 0;
        private var frameCount:int = 0;
        private var scanPhase:int = 0;

        // Smooth ammo transition
        private var displayMag:Number = 0;
        private var targetMag:Number = 0;
        private var displayReserve:Number = 0;
        private var targetReserve:Number = 0;
        private var magCap:int = 0;

        public function LoreOutCombatWidget() {
            super();
            buildUI();
            showPlaceholder();
            addEventListener(Event.ENTER_FRAME, onFrame);
        }

        // ================================================================
        // BUILD UI
        // ================================================================
        private function buildUI():void {
            // === TOP COORDINATES (above panel, cyberpunk style) ===
            var coordL:TextField = UIPrimitives.makeDataTag(this,
                "56.34  65.45", 7, UIPrimitives.COL_FRAME, 0.25);
            coordL.x = 6;
            coordL.y = -12;

            var crossX:TextField = UIPrimitives.makeDataTag(this,
                "X", 7, UIPrimitives.COL_FRAME, 0.30);
            crossX.x = PANEL_W * 0.5 - 4;
            crossX.y = -12;

            var coordR:TextField = UIPrimitives.makeDataTag(this,
                "56.34  65.45", 7, UIPrimitives.COL_FRAME, 0.25);
            coordR.x = PANEL_W - 80;
            coordR.y = -12;

            // === PANEL BACKGROUND ===
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

            // === HEADER ZONE (weapon name + threat badge) ===
            weaponField = UIPrimitives.makeValue(this, "--", 12, 0.95, 0xFFFFFF);
            weaponField.x = PAD;
            weaponField.y = 5;
            weaponField.width = PANEL_W - 100;

            // Threat status badge (right side of header)
            threatBadge = UIPrimitives.drawStatusBadge(this, "CLEAR",
                PANEL_W - 70, 6, UIPrimitives.COL_BORDER, 0.60);

            // Header divider
            UIPrimitives.drawDivider(this, PAD, 28, PANEL_W - PAD, 28, 0.25);

            // === MAIN ZONE (large ammo + reserve) ===
            ammoField = UIPrimitives.makeValue(this, "--- / ---", 18, 0.95,
                0xFFFFFF);
            ammoField.x = PAD;
            ammoField.y = 34;
            ammoField.width = 180;

            magLabel = UIPrimitives.makeLabel(this, "MAG", 8, 0.45,
                UIPrimitives.COL_TEXT_SEC);
            magLabel.x = PAD;
            magLabel.y = 60;

            reserveField = UIPrimitives.makeValue(this, "---", 14, 0.70,
                UIPrimitives.COL_TEXT_SEC);
            reserveField.x = PANEL_W - 80;
            reserveField.y = 38;
            reserveField.width = 70;
            var rfmt:TextFormat = reserveField.defaultTextFormat;
            rfmt.align = TextFormatAlign.RIGHT;
            reserveField.defaultTextFormat = rfmt;
            reserveField.setTextFormat(rfmt);

            reserveLabel = UIPrimitives.makeLabel(this, "RESERVE", 8, 0.35,
                UIPrimitives.COL_FRAME);
            reserveLabel.x = PANEL_W - 66;
            reserveLabel.y = 60;

            // Main/bottom divider
            UIPrimitives.drawDivider(this, PAD, 78, PANEL_W - PAD, 78, 0.20);

            // === BOTTOM ZONE (ammo type + hostiles) ===
            ammoTypeField = UIPrimitives.makeLabel(this, "--", 9, 0.55,
                UIPrimitives.COL_TEXT_SEC);
            ammoTypeField.x = PAD;
            ammoTypeField.y = 82;
            ammoTypeField.width = 180;

            // Threat dot (breathing glow in combat)
            threatDot = new Shape();
            threatDot.graphics.beginFill(UIPrimitives.COL_BORDER, 0.60);
            threatDot.graphics.drawCircle(0, 0, 3);
            threatDot.graphics.endFill();
            threatDot.x = PANEL_W - 70;
            threatDot.y = 90;
            addChild(threatDot);

            // Alert icon
            alertIcon = UIPrimitives.drawAlertIcon(this,
                PANEL_W - 52, 90, 10, UIPrimitives.COL_BORDER, 0.50);

            // Hostile count
            hostileField = UIPrimitives.makeLabel(this, "\u00D70", 10, 0.55,
                UIPrimitives.COL_TEXT_SEC);
            hostileField.x = PANEL_W - 38;
            hostileField.y = 82;
            hostileField.width = 30;

            // Bottom divider
            UIPrimitives.drawDivider(this, PAD, 102, PANEL_W - PAD, 102, 0.15);

            // Scanning status text (animated dots)
            scanField = UIPrimitives.makeLabel(this, "SCANNING", 7, 0.30,
                UIPrimitives.COL_FRAME);
            scanField.width = PANEL_W;
            var sfmt:TextFormat = scanField.defaultTextFormat;
            sfmt.align = TextFormatAlign.CENTER;
            sfmt.letterSpacing = 2;
            scanField.defaultTextFormat = sfmt;
            scanField.setTextFormat(sfmt);
            scanField.x = 0;
            scanField.y = 108;

            // Data tag below panel
            var tag:TextField = UIPrimitives.makeDataTag(this, "WPN-01", 8,
                UIPrimitives.COL_FRAME_LIGHT, 0.30);
            tag.x = PANEL_W * 0.5 - 20;
            tag.y = PANEL_H + 1;
        }

        private function showPlaceholder():void {
            updateNumericData(0, 0, 0, 0, 0, 0);
        }

        // ================================================================
        // ENTER_FRAME
        // ================================================================
        private function onFrame(e:Event):void {
            frameCount++;

            // Smooth ammo transitions
            displayMag += (targetMag - displayMag) * 0.25;
            displayReserve += (targetReserve - displayReserve) * 0.25;

            // Threat dot breathing glow
            if (currentThreat > 0) {
                var dotCol:uint = (currentThreat == 2) ?
                    UIPrimitives.COL_WARN : UIPrimitives.COL_ACCENT;
                var glowA:Number = 0.3 + Math.sin(frameCount * 0.07) * 0.2;
                threatDot.filters = [
                    new GlowFilter(dotCol, glowA, 4, 4, 1.5, 1)];
            } else {
                threatDot.filters = [];
            }

            // Scanning dots animation (cycle every 20 frames)
            if (frameCount % 20 == 0) {
                scanPhase = (scanPhase + 1) % 4;
            }
            var dots:String;
            switch (scanPhase) {
                case 0: dots = ". SCANNING ."; break;
                case 1: dots = ". . SCANNING . ."; break;
                case 2: dots = ". . . SCANNING . . ."; break;
                default: dots = ". . SCANNING . ."; break;
            }
            scanField.text = dots;

            updateAmmoDisplay();
        }

        // ================================================================
        // UPDATE AMMO DISPLAY (smooth values)
        // ================================================================
        private function updateAmmoDisplay():void {
            var showMag:int = int(Math.round(displayMag));
            var showRes:int = int(Math.round(displayReserve));

            if (magCap > 0) {
                ammoField.text = padNum(showMag, 3) + " / " +
                    padNum(magCap, 3);
                reserveField.text = String(showRes);
            } else {
                ammoField.text = "--- / ---";
                reserveField.text = "---";
            }

            // Color: red if mag < 15%
            var magPct:Number = (magCap > 0) ? (displayMag / magCap) : 1;
            var ammoCol:uint = (magPct < 0.15) ?
                UIPrimitives.COL_WARN : UIPrimitives.COL_ACCENT;

            var afmt:TextFormat = ammoField.defaultTextFormat;
            afmt.color = ammoCol;
            ammoField.defaultTextFormat = afmt;
            ammoField.setTextFormat(afmt);
        }

        // ================================================================
        // UPDATE NUMERIC DATA
        // ================================================================
        private function updateNumericData(magCur:int, cap:int, reserve:int,
            spareMags:int, threat:int, hostiles:int):void {

            targetMag = magCur;
            magCap = cap;
            targetReserve = reserve;

            // Hostile count
            if (hostiles > 0) {
                hostileField.text = "\u00D7" + hostiles;
                var hfmt:TextFormat = hostileField.defaultTextFormat;
                hfmt.color = UIPrimitives.COL_WARN;
                hostileField.defaultTextFormat = hfmt;
                hostileField.setTextFormat(hfmt);
            } else {
                hostileField.text = "\u00D70";
                var hfmt2:TextFormat = hostileField.defaultTextFormat;
                hfmt2.color = UIPrimitives.COL_TEXT_SEC;
                hostileField.defaultTextFormat = hfmt2;
                hostileField.setTextFormat(hfmt2);
            }

            currentThreat = threat;
            updateThreatVisual();
        }

        private function updateWeaponName(name:String):void {
            weaponField.text = (name.length > 0) ? name : "--";
        }

        private function updateAmmoType(name:String):void {
            var cleaned:String = name;
            var bracketEnd:int = name.indexOf("] ");
            if (bracketEnd >= 0 && name.charAt(0) == "[") {
                cleaned = name.substring(bracketEnd + 2);
            }
            ammoTypeField.text = (cleaned.length > 0) ? cleaned : "--";
        }

        // ================================================================
        // UPDATE THREAT VISUAL
        // ================================================================
        private function updateThreatVisual():void {
            var col:uint;
            var label:String;
            switch (currentThreat) {
                case 2:
                    col = UIPrimitives.COL_WARN;
                    label = "DANGER";
                    break;
                case 1:
                    col = UIPrimitives.COL_ACCENT;
                    label = "CAUTION";
                    break;
                default:
                    col = UIPrimitives.COL_BORDER;
                    label = "CLEAR";
                    break;
            }

            // Rebuild threat badge
            if (threatBadge && threatBadge.parent) {
                threatBadge.parent.removeChild(threatBadge);
            }
            threatBadge = UIPrimitives.drawStatusBadge(this, label,
                PANEL_W - 70, 6, col,
                (currentThreat == 2) ? 0.90 : 0.60);

            // Threat dot
            threatDot.graphics.clear();
            threatDot.graphics.beginFill(col, 0.85);
            threatDot.graphics.drawCircle(0, 0, 3);
            threatDot.graphics.endFill();

            // Recolor alert icon
            if (alertIcon && alertIcon.parent) {
                alertIcon.parent.removeChild(alertIcon);
            }
            alertIcon = UIPrimitives.drawAlertIcon(this,
                PANEL_W - 52, 90, 10, col, 0.50);
        }

        // ================================================================
        // PROCESS MESSAGE
        // ================================================================
        public function processMessage(command:String, params:Array):void {
            var cmd:int = parseInt(command);
            if (cmd == CMD_COMBAT_UPDATE && params && params.length >= 6) {
                updateNumericData(int(params[0]), int(params[1]),
                    int(params[2]), int(params[3]),
                    int(params[4]), int(params[5]));
            } else if (cmd == CMD_WEAPON_NAME && params && params.length >= 1) {
                updateWeaponName(String(params[0]));
            } else if (cmd == CMD_AMMO_TYPE && params && params.length >= 1) {
                updateAmmoType(String(params[0]));
            }
        }

        private function padNum(n:int, digits:int):String {
            var s:String = String(n);
            while (s.length < digits) s = "0" + s;
            return s;
        }
    }
}
