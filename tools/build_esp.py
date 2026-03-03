"""
build_esp.py — Generate LoreOutHUD.esp (minimal Fallout 4 plugin)

Creates a Quest record with the LoreOutHUD_TestQuestScript attached.
The quest is Start Game Enabled + Run Once, so OnInit fires on game load.
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

SCRIPT_NAME    = 'LoreOutHUD_TestQuestScript'
QUEST_EDITOR_ID = 'LoreOutHUD_TestQuest'
QUEST_FORM_ID  = 0x00000D63    # bumped: old 0x0D62 is "spent" on existing saves
FORM_VERSION   = 0x0083        # 131 decimal, standard FO4

# --- TES4 (file header) ---

hedr = make_subrecord(b'HEDR', struct.pack('<fII',
    1.34,           # FO4 plugin format version
    1,              # numRecords (1 quest)
    0x00000D64      # nextObjectID
))
cnam = make_subrecord(b'CNAM', b'LoreOut\x00')

# Master: Fallout4.esm (required base)
mast1 = make_subrecord(b'MAST', b'Fallout4.esm\x00')
data1 = make_subrecord(b'DATA', struct.pack('<Q', 0))

tes4 = make_record(b'TES4', 0, 0, FORM_VERSION,
    hedr + cnam + mast1 + data1
)

# --- VMAD (Papyrus script attachment) ---

vmad_body = struct.pack('<hhH', 6, 2, 1)   # version=6, objFormat=2, scriptCount=1
vmad_body += wstring(SCRIPT_NAME)
vmad_body += struct.pack('<BH', 0, 0)       # status=0 (local), propertyCount=0

vmad = make_subrecord(b'VMAD', vmad_body)

# --- QUST record ---

edid = make_subrecord(b'EDID', (QUEST_EDITOR_ID + '\x00').encode('ascii'))

# DNAM: quest flags and metadata
# flags1: 0x01 = Start Game Enabled
# flags2: 0x00 = NOT Run Once (removed — lifecycle handles re-init via OnPlayerLoadGame)
# priority: 60
# questType: 0 = None
dnam = make_subrecord(b'DNAM', struct.pack('<BBBBII',
    0x01,   # flags1: Start Game Enabled
    0x00,   # flags2: no Run Once — quest persists, script handles lifecycle
    60,     # priority
    0,      # pad
    0,      # unknown
    0       # questType: None
))

# ANAM: next alias ID (0 = no aliases)
anam = make_subrecord(b'ANAM', struct.pack('<I', 0))

qust = make_record(b'QUST', 0, QUEST_FORM_ID, FORM_VERSION,
    edid + vmad + dnam + anam
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
