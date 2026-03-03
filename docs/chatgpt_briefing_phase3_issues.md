# ChatGPT Briefing: Phase 3 Issues & GhostHUD Analysis

## Issue 1: FallUI Layout MCM Page Missing

After deploying our test widget mod, the FallUI HUD "Layout" page disappeared from
its MCM submenu. This is the visual layout editor that lets users reposition HUD
elements.

### Our deployed files:
- `LoreOutHUD.esp` (235 bytes) — quest with Start Game Enabled + Run Once
- `Interface/LoreOutTestWidget.swf` (1316 bytes) — simple test widget
- `Scripts/LoreOutHUD_TestQuestScript.pex` (1571 bytes) — Papyrus loader

### Root cause analysis:
Our mod does NOT touch any MCM files, FallUI files, or HUDMenu.swf. The FallUI
Layout page is defined in `MCM/Config/FallUIHUD/config.json` and uses a SWF class
`M8r.Controller.FallUIHUD` from `lib.swf` — none of which we modify.

**Likely cause: Quest registration timing.**

Our script calls `HUDFramework.GetInstance()` directly in `OnInit()` and immediately
calls `RegisterWidget()` with `loadNow=True, autoLoad=True`. This is aggressive —
if HUDFramework hasn't fully initialized yet, it could corrupt the widget registry,
cascading to FallUI's Layout page (which depends on HUDFramework's widget system).

Compare to GhostHUD (which works perfectly):
- GhostHUD waits 3-4 seconds via `StartTimer(3.0, 0)` before first registration
- Uses `loadNow=False, autoLoad=False` and manually calls `LoadWidget()` separately
- Has retry logic: if HUDFramework.GetInstance() returns None, retries in 5 seconds
- Registers for `OnPlayerLoadGame` to re-register on every save/load cycle

**Our script is missing ALL of these safety patterns.**

### Proposed fix:
1. Add timer delay before registration (3-4 seconds, matching GhostHUD)
2. Use `loadNow=False, autoLoad=False` + explicit `LoadWidget()` call
3. Add retry logic if HUDFramework isn't ready
4. Add `OnPlayerLoadGame` handler
5. Add proper bRegistered/bLoaded state tracking

## Issue 2: What We Learned from GhostHUD

### Architecture (2 widgets, 2 scripts):
- **GhostHUDWidget** — weather, time, date, location display
- **GhostHUDPanelFrame** — hairline border overlays on FallUI elements

### Registration Pattern (proven working):
```
OnInit → StartTimer(3.0) → AttemptRegister()
  → HUDFramework.GetInstance()
  → RegisterWidget(Self, SWF, x, y, False, False)  ← NO auto-load
  → LoadWidget(WIDGET_ID)                           ← explicit load
  → HUD_WidgetLoaded callback fires
  → ApplyWidgetSettings() + start update loop
```

### Messaging Pattern:
- `SendMessage()` — for numeric data ONLY (6 Floats: weather class, hour, frame positions)
- `SendMessageString()` — for text data (weather name, date, location, frame titles)
- The AS3 widget handles BOTH paths in processMessage()

### MCM Integration:
- `config.json` + `settings.ini` in `MCM/Config/GhostHUD/`
- Uses `mcm.GetModSettingFloat/Bool()` to read settings at runtime
- Registers for `OnMCMSettingChange|GhostHUD` external event
- Reapplies widget position/scale/opacity on settings change

### Key Constants:
- **HUDFramework virtual stage: 1280x720** (Scaleform scales 1.5x to 1080p)
- GhostHUD Weather default position: (1121, 249) — under minimap area
- GhostHUD PanelFrame position: (0, 0) — full screen overlay
- Color palette: Health=#33A373, AP=#87CEEB, Crit=#FFD700, Rads=#A8E000

## Questions for ChatGPT

1. **HUD Design Direction**: The user explicitly does NOT want:
   - Same positioning as GhostHUD (screw-ups from prior attempts)
   - Same basic art style (rounded rect with white text)
   - Copy-pasted implementation

   What design philosophy should we adopt for LoreOut HUD?
   - Minimalist/clean vs tactical/military vs Pip-Boy themed?
   - Where should our elements live on screen to complement (not conflict with) FallUI + GhostHUD?
   - Should we use the FallUI panel frame approach or something completely different?

2. **Widget Architecture**: GhostHUD uses 2 widgets (info display + frame overlay).
   Should LoreOut follow a similar multi-widget pattern or consolidate?

3. **What data should LoreOut display?** GhostHUD already covers weather, time, date,
   location. LoreOut needs its own identity — what unique data/features should it provide?

4. **Innovation opportunities** beyond what GhostHUD does:
   - Animated transitions?
   - Context-sensitive display (show/hide based on game state)?
   - Integration with other mods in the modlist?
   - Custom fonts/icon sets?

## Technical Constraints
- HUDFramework virtual stage is 1280x720
- SWF compiled with Adobe Flex SDK 4.6.0 (Scaleform GFx 4.x subset)
- Must coexist with: FallUI HUD, GhostHUD Widget, Immersive HUD, DEF Mods
- ESP generated programmatically (no CK needed)
- Full build pipeline: AS3→SWF + PSC→PEX + Python→ESP + deploy→MO2
