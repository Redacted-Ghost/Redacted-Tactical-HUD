# Deploy Paths

## Build Output
All build outputs go to `dist/` in the project root.

## MO2 Deploy Target
**Mod folder:** `C:/Modlists/WastelandReborn/mods/[nodelete] LoreOut Custom HUD/`

### Deploy Rule
```
dist/Interface/*.swf  →  [mod folder]/Interface/
dist/Textures/*       →  [mod folder]/Textures/
```

### How to deploy
Copy contents of `dist/` into the MO2 mod folder. MO2's virtual filesystem will overlay these files at runtime.

Do NOT copy directly into `Stock Game/Data/` — MO2 manages the virtual filesystem.

## Reference Paths
| Path | Purpose |
|------|---------|
| `C:/Modlists/WastelandReborn/Stock Game/` | Actual game runtime (1.10.163.0) |
| `C:/Modlists/WastelandReborn/mods/HUDFramework/` | HUDFramework ESM + BA2 |
| `C:/Modlists/WastelandReborn/mods/FallUI - HUD/Interface/` | FallUI HUD SWFs |
| `C:/Modlists/WastelandReborn/mods/[nodelete] GhostHUD Widget/` | Reference: full widget pattern |
| `C:/Modlists/WastelandReborn/profiles/LoreOut/` | Active MO2 profile |

## Tool Paths
| Tool | Path |
|------|------|
| RABCDAsm | `C:/dev/tools/rabcdasm/` |
| Adobe Flex SDK 4.6.0 | `C:/dev/tools/flex-sdk/` |
| ImageMagick | `C:/dev/tools/imagemagick/` |
| FFDec | `C:/Program Files (x86)/FFDec/` |
| Archive2 | `C:/steam games/steam/steamapps/common/Fallout 4/Tools/Archive2/` |
