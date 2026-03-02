# Phase 3: First Widget — LoreOutTestWidget

## Overview

A minimal HUDFramework widget that proves the full pipeline:
AS3 source → mxmlc compile → SWF → deploy to MO2 → Papyrus loader → in-game HUD.

The widget draws a translucent black box with white text and responds to two commands:
- **CMD_SET_TEXT (100)** — sets arbitrary text
- **CMD_SET_COUNTER (101)** — displays an incrementing counter

## File Manifest

| File | Purpose |
|------|---------|
| `src/as3/hudframework/IHUDWidget.as` | Compile-time interface (matches real HUDFramework API) |
| `src/as3/loreout/widgets/LoreOutTestWidget.as` | Widget implementation |
| `src/papyrus/LoreOutHUD_TestQuestScript.psc` | Papyrus quest script (registers widget, sends messages) |
| `tools/build_widget.ps1` | Compiles AS3 → SWF via Adobe Flex SDK 4.6.0 |
| `tools/deploy.ps1` | Copies dist/ artifacts to MO2 mod folder |
| `dist/Interface/LoreOutTestWidget.swf` | Compiled output (1318 bytes, gitignored) |

## Build

```powershell
# From project root
powershell -File tools/build_widget.ps1
```

Or manually:
```bash
java -jar "C:/dev/tools/flex-sdk/lib/mxmlc.jar" \
  +flexlib="C:/dev/tools/flex-sdk/frameworks" \
  -target-player=11.1 \
  -static-link-runtime-shared-libraries=true \
  "-source-path+=src/as3" \
  "src/as3/loreout/widgets/LoreOutTestWidget.as" \
  -output "dist/Interface/LoreOutTestWidget.swf"
```

## Deploy

```powershell
powershell -File tools/deploy.ps1
```

Copies `dist/Interface/*.swf` → `C:/Modlists/WastelandReborn/mods/[nodelete] LoreOut Custom HUD/Interface/`

## SWF Validation (FFDec)

Confirmed tags in compiled SWF:
- `DoABC2` (tag 82) — bytecode present
- `SymbolClass` (tag 76) — maps to `loreout.widgets.LoreOutTestWidget`
- AS3 classes: `hudframework.IHUDWidget`, `loreout.widgets.LoreOutTestWidget`

## IHUDWidget Interface

Verified by disassembling GhostHUDWidget.swf (a working HUDFramework widget in the modlist):

```actionscript
package hudframework {
    public interface IHUDWidget {
        function processMessage(command:String, params:Array):void;
    }
}
```

- `command` is a String (the integer command ID as text)
- `params` is an Array of values passed from Papyrus via `hud.SendMessage()`

## Papyrus Script Notes

`LoreOutHUD_TestQuestScript.psc` is source-only for now. Compilation requires:
1. The Papyrus compiler (from Creation Kit)
2. HUDFramework.psc import files

The ESP (plugin) that attaches this script to a quest must be created in the Creation Kit.

## Remaining Steps (not in this PR)

- [ ] Create ESP with a test quest that runs the Papyrus script
- [ ] Compile .psc → .pex using the Papyrus compiler
- [ ] In-game test: launch FO4 via MO2, verify widget appears at (30, 30) with counter
- [ ] Iterate on widget layout/style once baseline is confirmed
