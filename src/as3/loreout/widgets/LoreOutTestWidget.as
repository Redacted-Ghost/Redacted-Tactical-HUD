package loreout.widgets {
    import flash.display.MovieClip;
    import flash.display.Shape;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import hudframework.IHUDWidget;

    /**
     * LoreOut HUD test widget — Scaleform-compatible rendering.
     * Uses $MAIN_Font (game-embedded font) and drawRect (not drawRoundRect)
     * to match GhostHUD's proven rendering approach.
     */
    public class LoreOutTestWidget extends MovieClip implements IHUDWidget {

        private var tf:TextField;
        private var counter:int = 0;

        public function LoreOutTestWidget() {
            super();

            // Background box — use drawRect (Scaleform-safe, not drawRoundRect)
            var box:Shape = new Shape();
            box.graphics.lineStyle(2, 0xFFFFFF, 0.8);
            box.graphics.beginFill(0x0A0A0A, 0.75);
            box.graphics.drawRect(0, 0, 260, 48);
            box.graphics.endFill();
            addChild(box);

            // Text field — use $MAIN_Font (Scaleform embedded font, not _sans)
            tf = new TextField();
            tf.x = 8;
            tf.y = 6;
            tf.width = 244;
            tf.height = 36;
            tf.selectable = false;
            tf.mouseEnabled = false;

            var fmt:TextFormat = new TextFormat();
            fmt.font = "$MAIN_Font";
            fmt.size = 18;
            fmt.color = 0xDDDDDD;
            tf.defaultTextFormat = fmt;
            tf.textColor = 0xDDDDDD;
            tf.text = "LoreOut HUD: waiting...";
            addChild(tf);
        }

        public function processMessage(command:String, params:Array):void {
            var cmd:int = parseInt(command);

            if (cmd == 100) {
                // SET_TEXT: HUDFramework SendMessage passes Floats only,
                // so we hardcode the "loaded" confirmation text here
                tf.text = "LoreOut HUD: loaded";
                return;
            }

            if (cmd == 101) {
                if (params && params.length > 0) {
                    counter = int(params[0]);
                } else {
                    counter++;
                }
                tf.text = "LoreOut HUD counter: " + counter;
                return;
            }

            tf.text = "Unknown cmd=" + command + " params=" + (params ? params.length : 0);
        }
    }
}
