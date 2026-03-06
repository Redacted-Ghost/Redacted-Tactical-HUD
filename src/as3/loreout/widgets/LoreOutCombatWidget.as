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
     * LoreOut Combat Widget v11 — Tactical panel weapon module.
     *
     * 200x96 with chamfered tactical panel, chevron header,
     * divider line with terminus dots, leader line callout,
     * simplified ammo readout, chase light on chamfered perimeter.
     * Panel outline shifts: amber(clear/caution) → red(danger).
     *
     * Layout:
     *   ┌──────────────────────────────────┐
     *   │ [header] MK18 SOPMOD        ●CLR │
     *   │──────────────────────────────────│
     *   │  030 / 030    383               │
     *   │  5.56MM ROUND          🔊×1     │
     *   └──────────────────────────────────┘
     *   ••• [WPN-01] •••
     *
     * CMD 200 (floats): magCur, magCap, reserve, spareMags, threat, hostiles
     * CMD 201 (string): weapon name
     * CMD 202 (string): ammo type name
     */
    public class LoreOutCombatWidget extends MovieClip implements IHUDWidget {

        private static const CMD_COMBAT_UPDATE:int = 200;
        private static const CMD_WEAPON_NAME:int = 201;
        private static const CMD_AMMO_TYPE:int = 202;

        private static const PANEL_W:int = 300;
        private static const PANEL_H:int = 110;
        private static const PAD:int = 6;

        // Cyber panel assembly
        private var cyberParts:Object;
        private var panelShape:Shape;
        private var headerParts:Object;

        // Content
        private var weaponField:TextField;
        private var threatDot:Shape;
        private var threatField:TextField;
        private var ammoField:TextField;
        private var ammoTypeField:TextField;
        private var hostileField:TextField;
        private var alertIcon:Shape;

        // State
        private var currentThreat:int = 0;
        private var frameCount:int = 0;

        // Chase light animation
        private var chaseContainer:Sprite;
        private var chasePos:Number = 0;
        private static const CHASE_SPEED:Number = 0.003;

        // Bottom row Y (for alert icon recreation)
        private var bottomRowY:Number = 0;

        public function LoreOutCombatWidget() {
            super();
            buildUI();
            showPlaceholder();
            addEventListener(Event.ENTER_FRAME, onFrame);
        }

        private function onFrame(e:Event):void {
            frameCount++;

            // Threat dot breathing glow
            if (currentThreat > 0) {
                var dotCol:uint = (currentThreat == 2) ? UIPrimitives.COL_WARN : UIPrimitives.COL_AMBER;
                var dotGlow:Number = UIPrimitives.pulseValue(0.5, 0.35, frameCount, 0.07);
                UIPrimitives.applyNeonGlow(threatDot, dotCol, dotGlow);
            }

            // Chase light animation
            var speed:Number = CHASE_SPEED;
            if (currentThreat == 2) speed = CHASE_SPEED * 2.5;
            else if (currentThreat == 1) speed = CHASE_SPEED * 1.5;
            chasePos = (chasePos + speed) % 1.0;
            drawChaseLight();
        }

        // ================================================================
        // CHASE LIGHT — glowing dot flowing around tactical panel perimeter
        // ================================================================
        private function drawChaseLight():void {
            var g:* = chaseContainer.graphics;
            g.clear();

            // Chamfered polygon path (tactical panel edges)
            var path:Object = UIPrimitives.getTacticalPanelPath(PANEL_W, PANEL_H, "full");
            var vx:Array = path.vx;
            var vy:Array = path.vy;

            // Calculate segment lengths
            var segLens:Array = [];
            var totalLen:Number = 0;
            var numSegs:int = vx.length - 1;
            for (var s:int = 0; s < numSegs; s++) {
                var dx:Number = Number(vx[s + 1]) - Number(vx[s]);
                var dy:Number = Number(vy[s + 1]) - Number(vy[s]);
                var len:Number = Math.sqrt(dx * dx + dy * dy);
                segLens.push(len);
                totalLen += len;
            }

            // Find position on perimeter
            var dist:Number = chasePos * totalLen;
            var accumulated:Number = 0;
            var px:Number = Number(vx[0]);
            var py:Number = Number(vy[0]);

            for (s = 0; s < numSegs; s++) {
                var segLen:Number = Number(segLens[s]);
                if (accumulated + segLen >= dist) {
                    var t:Number = (dist - accumulated) / segLen;
                    px = Number(vx[s]) + (Number(vx[s + 1]) - Number(vx[s])) * t;
                    py = Number(vy[s]) + (Number(vy[s + 1]) - Number(vy[s])) * t;
                    break;
                }
                accumulated += segLen;
            }

            var chaseCol:uint = UIPrimitives.COL_COMBAT_GREY;
            if (currentThreat == 2) chaseCol = UIPrimitives.COL_WARN;
            else if (currentThreat == 1) chaseCol = UIPrimitives.COL_AMBER;

            // Bright dot
            g.beginFill(0xFFFFFF, 0.95);
            g.drawCircle(px, py, 1.5);
            g.endFill();
            g.beginFill(chaseCol, 0.70);
            g.drawCircle(px, py, 3);
            g.endFill();

            // Trail
            for (var trail:int = 1; trail <= 4; trail++) {
                var trailPos:Number = (chasePos - trail * 0.008);
                if (trailPos < 0) trailPos += 1.0;
                var trailDist:Number = trailPos * totalLen;
                var ta:Number = 0;
                var tpx:Number = Number(vx[0]);
                var tpy:Number = Number(vy[0]);

                for (s = 0; s < numSegs; s++) {
                    segLen = Number(segLens[s]);
                    if (ta + segLen >= trailDist) {
                        t = (trailDist - ta) / segLen;
                        tpx = Number(vx[s]) + (Number(vx[s + 1]) - Number(vx[s])) * t;
                        tpy = Number(vy[s]) + (Number(vy[s + 1]) - Number(vy[s])) * t;
                        break;
                    }
                    ta += segLen;
                }

                var trailAlpha:Number = 0.5 * (1 - trail / 5);
                g.beginFill(chaseCol, trailAlpha);
                g.drawCircle(tpx, tpy, 2 - trail * 0.3);
                g.endFill();
            }

            chaseContainer.filters = [new GlowFilter(chaseCol, 0.55, 8, 8, 2, 1)];
        }

        // ================================================================
        // BUILD UI
        // ================================================================
        private function buildUI():void {
            // === CYBER PANEL (all structural layers) ===
            cyberParts = UIPrimitives.buildCyberPanel(this, PANEL_W, PANEL_H,
                UIPrimitives.COL_COMBAT_GREY, "full", true, "", "WPN-01");
            panelShape = cyberParts.panel as Shape;
            headerParts = cyberParts.header;

            var hdrY:Number = Number(cyberParts.headerY);
            var contentY:Number = Number(cyberParts.contentY);

            // Weapon name ON the header band (bold, white, centered in 26px)
            weaponField = UIPrimitives.makeValue(this, "--", 14, 0.97, 0xFFFFFF);
            weaponField.x = PAD + 2;
            weaponField.y = hdrY + 4;
            weaponField.width = PANEL_W - 100;

            // Threat indicator (on header band, right side, centered)
            threatDot = new Shape();
            threatDot.graphics.beginFill(UIPrimitives.COL_COMBAT_GREY, 0.95);
            threatDot.graphics.drawCircle(0, 0, 5);
            threatDot.graphics.endFill();
            threatDot.x = PANEL_W - 58;
            threatDot.y = hdrY + UIPrimitives.HEADER_BAND_H / 2;
            addChild(threatDot);
            UIPrimitives.applyNeonGlow(threatDot, UIPrimitives.COL_COMBAT_GREY, 0.4);

            threatField = UIPrimitives.makeLabel(this, "CLEAR", 11, 0.90, 0xFFFFFF);
            threatField.x = PANEL_W - 50;
            threatField.y = hdrY + 6;

            // === AMMO READOUT (large, readable) ===
            ammoField = UIPrimitives.makeValue(this, "--- / ---", 22, 0.95,
                UIPrimitives.COL_COMBAT_GREY);
            ammoField.x = PAD + 6;
            ammoField.y = contentY + 6;
            ammoField.width = PANEL_W - PAD * 2;

            // === BOTTOM ROW: ammo type + alert icon + hostile count ===
            bottomRowY = contentY + 40;

            ammoTypeField = UIPrimitives.makeLabel(this, "--", 10);
            ammoTypeField.x = PAD + 6;
            ammoTypeField.y = bottomRowY;
            ammoTypeField.width = 200;

            // Alert icon (speaker) for hostile count
            alertIcon = UIPrimitives.drawAlertIcon(this,
                PANEL_W - 52, bottomRowY + 7, 10,
                UIPrimitives.COL_COMBAT_GREY, 0.70);

            hostileField = UIPrimitives.makeLabel(this, "", 10);
            hostileField.x = PANEL_W - 40;
            hostileField.y = bottomRowY;
            hostileField.width = 30;

            // Chase light container (on top of everything)
            chaseContainer = new Sprite();
            addChild(chaseContainer);
        }

        private function showPlaceholder():void {
            updateNumericData(0, 0, 0, 0, 0, 0);
        }

        // ================================================================
        // UPDATE NUMERIC DATA (simplified — no MAG/RES labels)
        // ================================================================
        private function updateNumericData(magCur:int, magCap:int, reserve:int,
                                            spareMags:int, threat:int, hostiles:int):void {
            // Single ammo readout: "030 / 030    383"
            if (magCap > 0) {
                ammoField.text = padNum(magCur, 3) + " / " + padNum(magCap, 3) + "    " + String(reserve);
            } else {
                ammoField.text = "--- / ---";
            }

            // Ammo field color based on mag level
            var magPct:Number = (magCap > 0) ? (magCur / magCap) : 0;
            var ammoCol:uint = UIPrimitives.COL_COMBAT_GREY;
            if (magPct < 0.15) ammoCol = UIPrimitives.COL_WARN;
            else if (magPct < 0.35) ammoCol = UIPrimitives.COL_AMBER;
            var afmt:TextFormat = ammoField.defaultTextFormat;
            afmt.color = ammoCol;
            ammoField.defaultTextFormat = afmt;
            ammoField.setTextFormat(afmt);
            ammoField.filters = (magPct < 0.35 && magCap > 0) ?
                [new GlowFilter(ammoCol, 0.5, 4, 4, 1.2, 1)] : [];

            // Hostile count with alert icon
            if (hostiles > 0) {
                hostileField.text = "\u00D7" + hostiles;
                var hfmt:TextFormat = hostileField.defaultTextFormat;
                hfmt.color = UIPrimitives.COL_WARN;
                hostileField.defaultTextFormat = hfmt;
                hostileField.setTextFormat(hfmt);
            } else {
                hostileField.text = "\u00D7" + "0";
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
        // UPDATE THREAT VISUAL — recolor tactical panel + header + dot
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
                    col = UIPrimitives.COL_AMBER;
                    label = "CAUTION";
                    break;
                default:
                    col = UIPrimitives.COL_COMBAT_GREY;
                    label = "CLEAR";
                    break;
            }

            // V9: Panel stays grey-green always. Only elements glow with state color.

            // Threat dot — glows with state color
            threatDot.graphics.clear();
            threatDot.graphics.beginFill(col, 0.95);
            threatDot.graphics.drawCircle(0, 0, 5);
            threatDot.graphics.endFill();
            UIPrimitives.applyNeonGlow(threatDot, col, (currentThreat == 2) ? 1.0 : 0.4);

            // Threat label — glows with state color
            threatField.text = label;
            var tfmt:TextFormat = threatField.defaultTextFormat;
            tfmt.color = (currentThreat > 0) ? col : 0xFFFFFF;
            threatField.defaultTextFormat = tfmt;
            threatField.setTextFormat(tfmt);
            threatField.filters = (currentThreat > 0) ?
                [new GlowFilter(col, 0.5, 4, 4, 1.2, 1)] : [];

            // Alert icon — glows with state color
            if (alertIcon && alertIcon.parent) alertIcon.parent.removeChild(alertIcon);
            alertIcon = UIPrimitives.drawAlertIcon(this,
                PANEL_W - 52, bottomRowY + 7, 10, col, 0.70);
        }

        // ================================================================
        // PROCESS MESSAGE
        // ================================================================
        public function processMessage(command:String, params:Array):void {
            var cmd:int = parseInt(command);
            if (cmd == CMD_COMBAT_UPDATE && params && params.length >= 6) {
                updateNumericData(int(params[0]), int(params[1]), int(params[2]),
                    int(params[3]), int(params[4]), int(params[5]));
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
