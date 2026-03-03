"""
build_esp.py — Generate LoreOutHUD.esp (Fallout 4 plugin)

Creates Quest records with Papyrus scripts attached.
Structure modeled after GhostHUD's proven working ESP:
  - Master: HUDFramework.esm (establishes load order dependency)
  - VMAD version 5 (matching GhostHUD)
  - FormIDs 0x01xxxxxx (this plugin's own record space)
  - FULL + NEXT subrecords (matching GhostHUD)
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

def make_quest(form_id, editor_id, display_name, script_name, priority=50):
    """Build a complete QUST record matching GhostHUD format."""
    form_version = 0x0083  # 131 decimal, standard FO4

    edid = make_subrecord(b'EDID', (editor_id + '\x00').encode('ascii'))

    # VMAD: script attachment (version=5, objFormat=2, matching GhostHUD)
    vmad_body = struct.pack('<hhH', 5, 2, 1)  # version=5, objFormat=2, scriptCount=1
    vmad_body += wstring(script_name)
    vmad_body += struct.pack('<BH', 0, 0)       # status=0, propertyCount=0
    vmad = make_subrecord(b'VMAD', vmad_body)

    full = make_subrecord(b'FULL', (display_name + '\x00').encode('ascii'))

    # DNAM: Start Game Enabled + Run Once, priority
    dnam = make_subrecord(b'DNAM', struct.pack('<BBBBII',
        0x01,       # flags1: Start Game Enabled
        0x01,       # flags2: Run Once
        priority,   # priority
        0,          # pad
        0,          # unknown
        0           # questType: None
    ))

    next_sub = make_subrecord(b'NEXT', b'')  # stage terminator
    anam = make_subrecord(b'ANAM', struct.pack('<I', 0))  # no aliases

    return make_record(b'QUST', 0, form_id, form_version,
        edid + vmad + full + dnam + next_sub + anam
    )

# --- Quest Definitions ---

quests = [
    {
        'form_id':     0x01000001,
        'editor_id':   'LoreOutHUD_TestQuest',
        'display_name': 'LoreOut HUD Test Widget',
        'script_name':  'LoreOutHUD_TestQuestScript',
        'priority':     50,
    },
    {
        'form_id':     0x01000002,
        'editor_id':   'LoreOutCombat_Quest',
        'display_name': 'LoreOut Combat Widget Controller',
        'script_name':  'LoreOutCombat_QuestScript',
        'priority':     50,
    },
    {
        'form_id':     0x01000003,
        'editor_id':   'LoreOutStatus_Quest',
        'display_name': 'LoreOut Status Widget Controller',
        'script_name':  'LoreOutStatus_QuestScript',
        'priority':     50,
    },
    {
        'form_id':     0x01000004,
        'editor_id':   'LoreOut_LighthouseProbe',
        'display_name': 'LoreOut Lighthouse API Probe',
        'script_name':  'LighthouseProbe',
        'priority':     50,
    },
]

# --- TES4 (file header) ---

FORM_VERSION = 0x0083
next_obj_id = max(q['form_id'] for q in quests) + 1  # 0x01000003

hedr = make_subrecord(b'HEDR', struct.pack('<fII',
    1.00,                           # Plugin format version (matching GhostHUD)
    len(quests),                    # numRecords
    next_obj_id & 0x00FFFFFF        # nextObjectID (strip index byte)
))
cnam = make_subrecord(b'CNAM', b'LoreOut\x00')

# Master: HUDFramework.esm (establishes load order + gives us index 0x01)
mast1 = make_subrecord(b'MAST', b'HUDFramework.esm\x00')
data1 = make_subrecord(b'DATA', struct.pack('<Q', 0))

tes4 = make_record(b'TES4', 0, 0, FORM_VERSION,
    hedr + cnam + mast1 + data1
)

# --- Build all QUST records ---

qust_bytes = b''
for q in quests:
    qust_bytes += make_quest(**q)

qust_grup = make_top_grup(b'QUST', qust_bytes)

# --- Write ---

out_dir = os.path.join(os.path.dirname(__file__), '..', 'dist')
os.makedirs(out_dir, exist_ok=True)
out_path = os.path.join(out_dir, 'LoreOutHUD.esp')

with open(out_path, 'wb') as f:
    f.write(tes4)
    f.write(qust_grup)

total = len(tes4) + len(qust_grup)
print(f"BUILD SUCCESS: {os.path.abspath(out_path)} ({total} bytes)")
print(f"  {len(quests)} quest(s): {', '.join(q['editor_id'] for q in quests)}")
