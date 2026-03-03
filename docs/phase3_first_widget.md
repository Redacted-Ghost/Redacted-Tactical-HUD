# Phase 3: First Widget — LoreOutTestWidget

## Overview

A minimal HUDFramework widget proving the full pipeline:
AS3 source → SWF → Papyrus script → PEX → ESP → deploy to MO2 → in-game HUD.

The widget draws a translucent black box with white text and responds to two commands:
- **CMD_SET_TEXT (100)** — shows "LoreOut HUD: loaded" confirmation
- **CMD_SET_COUNTER (101)** — displays an incrementing counter (arg1 = count)

## File Manifest

| File | Purpose |
|------|---------|
| `src/as3/hudframework/IHUDWidget.as` | Compile-time interface (verified via GhostHUD disassembly) |
| `src/as3/loreout/widgets/LoreOutTestWidget.as` | Widget implementation |
| `src/papyrus/LoreOutHUD_TestQuestScript.psc` | Papyrus quest script (registers widget, sends messages) |
| `tools/build_widget.ps1` | Compiles AS3 → SWF via Adobe Flex SDK 4.6.0 |
| `tools/build_papyrus.ps1` | Compiles .psc → .pex via CK PapyrusCompiler |
| `tools/build_esp.py` | Generates LoreOutHUD.esp (Quest + VMAD script attachment) |
| `tools/deploy.ps1` | Copies dist/ artifacts (ESP + SWF + PEX) to MO2 mod folder |

## Build

```powershell
# Build all three artifacts
powershell -File tools/build_widget.ps1      # AS3 → SWF
powershell -File tools/build_papyrus.ps1     # .psc → .pex
python tools/build_esp.py                     # Generate ESP
```

## Deploy

```powershell
powershell -File tools/deploy.ps1
```

Deploys to `C:/Modlists/WastelandReborn/mods/[nodelete] LoreOut Custom HUD/`:
- `LoreOutHUD.esp` → mod root
- `Interface/LoreOutTestWidget.swf`
- `Scripts/LoreOutHUD_TestQuestScript.pex`

## HUDFramework API (Verified)

Decompiled HUDFramework.pex with Champollion to get the real API:

```papyrus
; Registration
Function RegisterWidget(ScriptObject akOwner, String asSWF, Float afX, Float afY, Bool abLoadNow, Bool abAutoLoad)

; Messaging (Float params only — no strings)
Function SendMessage(String asWidgetID, Int aiCommand, Float arg1, Float arg2, Float arg3, Float arg4, Float arg5, Float arg6)

; Static accessor
HUDFramework Function GetInstance() Global
```

Key insight: `SendMessage` passes 6 Floats only. Text is hardcoded on the AS3 side.
The widget's `processMessage(command:String, params:Array)` receives command as a String
(the integer ID as text) and params as an Array of Float values.

## ESP Structure

Generated programmatically (no Creation Kit needed):
- **TES4 header**: FO4 format v1.34, master: Fallout4.esm
- **QUST record** (FormID 0x00000D62):
  - VMAD: script `LoreOutHUD_TestQuestScript` attached
  - Flags: Start Game Enabled + Run Once
  - Priority: 60

## Tools Installed

| Tool | Version | Path | Purpose |
|------|---------|------|---------|
| Champollion | 1.3.2 | `C:/dev/tools/champollion/` | PEX → PSC decompiler |
| Caprica | 0.3.0 | `C:/dev/tools/caprica/` | Standalone Papyrus compiler (backup) |

## In-Game Test Plan

1. Enable `[nodelete] LoreOut Custom HUD` in MO2 (LoreOut profile)
2. Ensure `LoreOutHUD.esp` appears in the load order after `HUDFramework.esm`
3. Launch FO4 via MO2 → F4SE
4. Expected: widget appears at screen position (30, 30)
5. Shows "LoreOut HUD: waiting..." then "LoreOut HUD: loaded"
6. Counter increments every second
7. Check `Documents/My Games/Fallout4/Logs/Script/Papyrus.0.log` for `[LoreOutHUD]` traces
