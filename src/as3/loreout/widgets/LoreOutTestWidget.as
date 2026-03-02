package loreout.widgets {
    import flash.display.MovieClip;
    import flash.display.Shape;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import hudframework.IHUDWidget;

    public class LoreOutTestWidget extends MovieClip implements IHUDWidget {

        private var tf:TextField;
        private var counter:int = 0;

        public function LoreOutTestWidget() {
            var box:Shape = new Shape();
            box.graphics.lineStyle(2, 0xFFFFFF, 1);
            box.graphics.beginFill(0x000000, 0.35);
            box.graphics.drawRoundRect(0, 0, 260, 48, 8, 8);
            box.graphics.endFill();
            addChild(box);

            tf = new TextField();
            tf.width = 250;
            tf.height = 40;
            tf.x = 8;
            tf.y = 6;
            tf.selectable = false;

            var fmt:TextFormat = new TextFormat();
            fmt.size = 18;
            fmt.font = "_sans";
            fmt.color = 0xFFFFFF;
            tf.defaultTextFormat = fmt;

            tf.text = "LoreOut HUD: waiting...";
            addChild(tf);
        }

        public function processMessage(command:String, params:Array):void {
            var cmd:int = parseInt(command);

            if (cmd == 100) {
                if (params && params.length > 0) {
                    tf.text = String(params[0]);
                }
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
