"""
build_esp.py — Generate LoreOutHUD.esp (minimal Fallout 4 plugin)

Creates a Quest record with the LoreOutHUD_TestQuestScript attached.
Structure modeled after GhostHUD's proven working ESP:
  - Master: HUDFramework.esm (establishes load order dependency)
  - VMAD version 5 (matching GhostHUD; v6 may cause issues)
  - FormID 0x01000001 (index 0x01 = this plugin's own record space)
  - FULL subrecord (display name)
  - NEXT subrecord (quest stages terminator)
"""

import struct
import os

# --- Helpers ---

def wstring(s):
    """VMAD length-prefixed string (uint16 + UTF-8 bytes, no null terminator)."""
    b = s.encode('utf-8')
    return struct.pack('<H', len(b)) + b

def make_subrecord(tag, data):
    """6-byte subrecord header + data."""
    return struct.pack('<4sH', tag, len(data)) + data

def make_record(tag, flags, form_id, form_version, body):
    """24-byte record header + body."""
    return struct.pack('<4sIIIIHH',
        tag,
        len(body),
        flags,
        form_id,
        0,              # revision
        form_version,
        0               # unknown
    ) + body

def make_top_grup(record_type_tag, records_bytes):
    """Wrap records in a Top Group (groupType=0)."""
    group_size = 24 + len(records_bytes)
    return (
        struct.pack('<4sI', b'GRUP', group_size)
        + record_type_tag
        + struct.pack('<iHHI', 0, 0, 0, 0)
    ) + records_bytes

# --- Configuration ---
# Modeled after GhostHUD's working ESP structure

SCRIPT_NAME     = 'LoreOutHUD_TestQuestScript'
QUEST_EDITOR_ID = 'LoreOutHUD_TestQuest'
QUEST_FULL_NAME = 'LoreOut HUD Widget Controller'

# FormID: high byte 0x01 = this plugin's own space (1 master = index 0x01 for own records)
QUEST_FORM_ID   = 0x01000001
FORM_VERSION    = 0x0083        # 131 decimal, standard FO4

# --- TES4 (file header) ---
# Match GhostHUD: HEDR version 1.00, master = HUDFramework.esm

hedr = make_subrecord(b'HEDR', struct.pack('<fII',
    1.00,           # Plugin format version (GhostHUD uses 1.00)
    1,              # numRecords (1 quest)
    0x00000002      # nextObjectID (next available in our space: 0x01000002)
))
cnam = make_subrecord(b'CNAM', b'LoreOut\x00')

# Master: HUDFramework.esm (NOT Fallout4.esm — we don't reference Fallout4 forms)
# This also ensures our ESP loads AFTER HUDFramework
mast1 = make_subrecord(b'MAST', b'HUDFramework.esm\x00')
data1 = make_subrecord(b'DATA', struct.pack('<Q', 0))

tes4 = make_record(b'TES4', 0, 0, FORM_VERSION,
    hedr + cnam + mast1 + data1
)

# --- VMAD (Papyrus script attachment) ---
# GhostHUD uses VMAD version 5, objFormat 2

vmad_body = struct.pack('<hhH', 5, 2, 1)   # version=5, objFormat=2, scriptCount=1
vmad_body += wstring(SCRIPT_NAME)
vmad_body += struct.pack('<BH', 0, 0)       # status=0 (local), propertyCount=0

vmad = make_subrecord(b'VMAD', vmad_body)

# --- QUST record ---

edid = make_subrecord(b'EDID', (QUEST_EDITOR_ID + '\x00').encode('ascii'))

# FULL: display name (GhostHUD has this, ours was missing)
full = make_subrecord(b'FULL', (QUEST_FULL_NAME + '\x00').encode('ascii'))

# DNAM: quest flags and metadata
# Match GhostHUD: Start Game Enabled + Run Once, priority 50
dnam = make_subrecord(b'DNAM', struct.pack('<BBBBII',
    0x01,   # flags1: Start Game Enabled
    0x01,   # flags2: Run Once (matching GhostHUD — lifecycle handles re-init via OnPlayerLoadGame)
    50,     # priority (matching GhostHUD)
    0,      # pad
    0,      # unknown
    0       # questType: None
))

# NEXT: quest stages terminator (GhostHUD has this, marks end of stage data)
# Even with no stages, this empty marker may be required by the engine
next_sub = make_subrecord(b'NEXT', b'')

# ANAM: next alias ID (0 = no aliases)
anam = make_subrecord(b'ANAM', struct.pack('<I', 0))

qust = make_record(b'QUST', 0, QUEST_FORM_ID, FORM_VERSION,
    edid + vmad + full + dnam + next_sub + anam
)

# --- Wrap in GRUP and write ---

qust_grup = make_top_grup(b'QUST', qust)

out_dir = os.path.join(os.path.dirname(__file__), '..', 'dist')
os.makedirs(out_dir, exist_ok=True)
out_path = os.path.join(out_dir, 'LoreOutHUD.esp')

with open(out_path, 'wb') as f:
    f.write(tes4)
    f.write(qust_grup)

total = len(tes4) + len(qust_grup)
print(f"BUILD SUCCESS: {os.path.abspath(out_path)} ({total} bytes)")
