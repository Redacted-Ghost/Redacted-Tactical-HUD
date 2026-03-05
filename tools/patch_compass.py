"""
patch_compass.py — Military reskin of FallUI compass via FFDec SWF patching (v2)

Replaces:
  - Bitmap 581: Compass background (300x22 dark charcoal w/ scan lines)
  - Shape 591: Compass frame (hairline + heading ticks at intervals)
  - Shape 442: Enemy marker (diamond, 6x6)
  - Shape 428: Quest marker (chevron waypoint arrow, 12.8x35)
  - Shape 425: Player-set marker (diamond pin beacon, 12.8x35)

FFDec CLI:
  -importImages <in> <out> <folder>   — PNGs named by charID
  -importShapes <in> <out> <folder>   — SVGs named by charID
"""

import os
import struct
import zlib
import subprocess
import shutil

# --- Paths ---

PROJECT    = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
TMP        = os.path.join(PROJECT, 'tmp', 'compass_patch')
IMG_DIR    = os.path.join(TMP, 'images')
SHAPE_DIR  = os.path.join(TMP, 'shapes')
DIST_IF    = os.path.join(PROJECT, 'dist', 'Interface')

FFDEC      = r'C:\Program Files (x86)\FFDec\ffdec-cli.exe'
SOURCE_SWF = r'C:\Modlists\WastelandReborn\mods\FallUI - HUD\Interface\HUDMenu.swf'

for d in [TMP, IMG_DIR, SHAPE_DIR, DIST_IF]:
    os.makedirs(d, exist_ok=True)


# ============================================================
# 1. GENERATE REPLACEMENT ASSETS
# ============================================================

print("=== Generating replacement assets (v2) ===")


# --- PNG Helper ---

def create_png(path, width, height, pixel_func):
    """Create a minimal RGBA PNG."""
    def make_chunk(ctype, data):
        c = ctype + data
        crc = zlib.crc32(c) & 0xFFFFFFFF
        return struct.pack('>I', len(data)) + c + struct.pack('>I', crc)

    sig = b'\x89PNG\r\n\x1a\n'
    ihdr = make_chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0))

    raw = b''
    for y in range(height):
        raw += b'\x00'  # no filter
        for x in range(width):
            r, g, b, a = pixel_func(x, y)
            raw += bytes([r, g, b, a])

    idat = make_chunk(b'IDAT', zlib.compress(raw, 9))
    iend = make_chunk(b'IEND', b'')

    with open(path, 'wb') as f:
        f.write(sig + ihdr + idat + iend)


# --- Compass Background Bitmap (ID 581) ---
# 300x22 dark charcoal with scan lines + defined edges

def compass_bg_pixel(x, y):
    """V2: dark charcoal gradient + subtle scan lines + defined edges."""
    t = y / 21.0
    r = int(28 - 8 * t)
    g = int(28 - 8 * t)
    b = int(32 - 8 * t)
    a = int(205 + 30 * t)   # ~80% to ~92% opacity

    # Top edge highlight
    if y == 0:
        r, g, b, a = 50, 50, 58, 155

    # Subtle scan lines every 5px (faint horizontal bands)
    if y > 0 and y < 21 and y % 5 == 0:
        r = min(r + 3, 255)
        g = min(g + 3, 255)
        b = min(b + 4, 255)

    # Bottom edge (darker, defined)
    if y == 21:
        r, g, b, a = 18, 18, 22, 240

    return (r, g, b, a)


bg_png = os.path.join(IMG_DIR, '581.png')
create_png(bg_png, 300, 22, compass_bg_pixel)
print(f"  Created: 581.png (compass background v2, 300x22)")


# --- Military Compass Frame (Shape 591) ---
# Heading-scale design: bottom hairline + bracket ends + center heading tick
# + quarter ticks (+-76) + eighth ticks (+-38, +-114)
# Coordinate space: center at (0,0), extends x:-152..152, y:-8..0

brackets_svg = os.path.join(SHAPE_DIR, '591.svg')
with open(brackets_svg, 'w') as f:
    f.write('''<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg xmlns:ffdec="https://www.free-decompiler.com/flash" xmlns:xlink="http://www.w3.org/1999/xlink" ffdec:objectType="shape" height="8.0px" width="304.0px" xmlns="http://www.w3.org/2000/svg">
  <g transform="matrix(1.0, 0.0, 0.0, 1.0, 152.0, 8.0)">
    <path d="
      M-152.0 -1.0 L152.0 -1.0 152.0 0.0 -152.0 0.0 -152.0 -1.0
      M-152.0 -6.0 L-150.0 -6.0 -150.0 -1.0 -152.0 -1.0 -152.0 -6.0
      M150.0 -6.0 L152.0 -6.0 152.0 -1.0 150.0 -1.0 150.0 -6.0
      M-0.5 -5.0 L0.5 -5.0 0.5 -1.0 -0.5 -1.0 -0.5 -5.0
      M-76.5 -3.5 L-75.5 -3.5 -75.5 -1.0 -76.5 -1.0 -76.5 -3.5
      M75.5 -3.5 L76.5 -3.5 76.5 -1.0 75.5 -1.0 75.5 -3.5
      M-114.5 -2.5 L-113.5 -2.5 -113.5 -1.0 -114.5 -1.0 -114.5 -2.5
      M113.5 -2.5 L114.5 -2.5 114.5 -1.0 113.5 -1.0 113.5 -2.5
      M-38.5 -2.5 L-37.5 -2.5 -37.5 -1.0 -38.5 -1.0 -38.5 -2.5
      M37.5 -2.5 L38.5 -2.5 38.5 -1.0 37.5 -1.0 37.5 -2.5
    " fill="#ffffff" fill-rule="evenodd" stroke="none"/>
  </g>
</svg>
''')
print(f"  Created: 591.svg (compass frame v2 with heading ticks, 304x8)")


# --- Enemy Diamond (Shape 442) ---
# Same as v1 — 6x6 filled diamond, proven working

enemy_svg = os.path.join(SHAPE_DIR, '442.svg')
with open(enemy_svg, 'w') as f:
    f.write('''<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg xmlns:ffdec="https://www.free-decompiler.com/flash" xmlns:xlink="http://www.w3.org/1999/xlink" ffdec:objectType="shape" height="6.0px" width="6.0px" xmlns="http://www.w3.org/2000/svg">
  <g transform="matrix(1.0, 0.0, 0.0, 1.0, 3.0, 3.0)">
    <path d="M0.0 -3.0 L3.0 0.0 0.0 3.0 -3.0 0.0 0.0 -3.0" fill="#ffffff" fill-rule="evenodd" stroke="none"/>
  </g>
</svg>
''')
print(f"  Created: 442.svg (enemy diamond, 6x6)")


# --- Quest Marker — Chevron Waypoint (Shape 428) ---
# Replaces vanilla solid cross with downward-pointing chevron arrow.
# Same bounding box 12.8x35 and transform as original.
# Design: wide header bar + thin stem + arrowhead tip
#
# Local coords (transform 0.7, -0.15):
#   x: -0.7 to 12.1 (12.8 wide)
#   y: 0.15 to 35.15 (35.0 tall)
#   Center x = 5.7

quest_svg = os.path.join(SHAPE_DIR, '428.svg')
with open(quest_svg, 'w') as f:
    f.write('''<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg xmlns:ffdec="https://www.free-decompiler.com/flash" xmlns:xlink="http://www.w3.org/1999/xlink" ffdec:objectType="shape" height="35.0px" width="12.8px" xmlns="http://www.w3.org/2000/svg">
  <g transform="matrix(1.0, 0.0, 0.0, 1.0, 0.7, -0.15)">
    <path d="
      M-0.7 0.15 L12.1 0.15 12.1 3.65 6.8 3.65 6.8 26.15 9.7 26.15 5.7 35.15 1.7 26.15 4.6 26.15 4.6 3.65 -0.7 3.65 -0.7 0.15
    " fill="#ffffff" fill-rule="evenodd" stroke="none"/>
  </g>
</svg>
''')
print(f"  Created: 428.svg (quest chevron waypoint, 12.8x35)")


# --- Player-Set Marker — Diamond Pin (Shape 425) ---
# Replaces vanilla hollow cross with a hollow diamond + pin stem.
# Same bounding box 12.8x35 and transform as original.
#
# Local coords (transform 6.4, 35.0):
#   x: -6.4 to 6.4 (12.8 wide)
#   y: -35.0 to 0.0 (35.0 tall, bottom at origin)
#
# Outer path: diamond top tapering to narrow stem
# Inner path (even-odd cutout): hollow diamond center

player_svg = os.path.join(SHAPE_DIR, '425.svg')
with open(player_svg, 'w') as f:
    f.write('''<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg xmlns:ffdec="https://www.free-decompiler.com/flash" xmlns:xlink="http://www.w3.org/1999/xlink" ffdec:objectType="shape" height="35.0px" width="12.8px" xmlns="http://www.w3.org/2000/svg">
  <g transform="matrix(1.0, 0.0, 0.0, 1.0, 6.4, 35.0)">
    <path d="
      M0 -33 L5 -28 1 -23 1 0 -1 0 -1 -23 -5 -28 0 -33
      M0 -31 L3 -28 0 -25 -3 -28 0 -31
    " fill="#ffffff" fill-rule="evenodd" stroke="none"/>
  </g>
</svg>
''')
print(f"  Created: 425.svg (player diamond pin, 12.8x35)")


# ============================================================
# 2. PATCH SWF WITH FFDEC
# ============================================================

print(f"\n=== Patching FallUI HUDMenu.swf (v2) ===")
print(f"  Source: {SOURCE_SWF} ({os.path.getsize(SOURCE_SWF)} bytes)")

# Step 1: Import replacement images (bitmap 581)
step1_out = os.path.join(TMP, 'step1_images.swf')
print(f"\n  Step 1: Importing images (bitmap 581)...")
r1 = subprocess.run(
    [FFDEC, '-importImages', SOURCE_SWF, step1_out, IMG_DIR],
    capture_output=True, text=True, timeout=120
)
if r1.returncode != 0:
    print(f"    WARN: importImages returned {r1.returncode}")
    print(f"    stdout: {r1.stdout[:500]}")
    print(f"    stderr: {r1.stderr[:500]}")
    shutil.copy2(SOURCE_SWF, step1_out)
    print(f"    Falling back to unmodified SWF")
else:
    print(f"    OK: {os.path.getsize(step1_out)} bytes")
    if r1.stdout.strip():
        print(f"    {r1.stdout.strip()[:200]}")

# Step 2: Import replacement shapes (591, 442, 428, 425)
step2_out = os.path.join(TMP, 'step2_shapes.swf')
print(f"\n  Step 2: Importing shapes (591 frame + 442 enemy + 428 quest + 425 player)...")
r2 = subprocess.run(
    [FFDEC, '-importShapes', step1_out, step2_out, SHAPE_DIR],
    capture_output=True, text=True, timeout=120
)
if r2.returncode != 0:
    print(f"    WARN: importShapes returned {r2.returncode}")
    print(f"    stdout: {r2.stdout[:500]}")
    print(f"    stderr: {r2.stderr[:500]}")
    shutil.copy2(step1_out, step2_out)
    print(f"    Falling back to images-only SWF")
else:
    print(f"    OK: {os.path.getsize(step2_out)} bytes")
    if r2.stdout.strip():
        print(f"    {r2.stdout.strip()[:200]}")


# ============================================================
# 3. COPY TO DIST
# ============================================================

final_swf = os.path.join(DIST_IF, 'HUDMenu.swf')
shutil.copy2(step2_out, final_swf)

orig_size = os.path.getsize(SOURCE_SWF)
new_size = os.path.getsize(final_swf)
diff = new_size - orig_size

print(f"\n=== COMPASS PATCH COMPLETE (v2) ===")
print(f"  Output: {final_swf}")
print(f"  Size: {new_size} bytes (original: {orig_size}, diff: {diff:+d})")
print(f"  Changes:")
print(f"    - Bitmap 581: Dark charcoal background w/ scan lines + edge definition")
print(f"    - Shape 591: Heading-scale frame (bracket ends + center/quarter/eighth ticks)")
print(f"    - Shape 442: Diamond enemy marker")
print(f"    - Shape 428: Chevron waypoint quest marker (was solid cross)")
print(f"    - Shape 425: Diamond-pin player beacon (was hollow cross)")
