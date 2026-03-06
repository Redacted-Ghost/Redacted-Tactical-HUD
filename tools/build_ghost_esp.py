"""
build_ghost_esp.py — Generate Ghost_HUD Widgets.esp

Builds the GhostHUD companion ESP with ONLY the widget quest.
The PanelFrame quest has been removed (orphaned — no PEX exists).
"""

import struct
import os

# --- Helpers (same as build_esp.py) ---

def wstring(s):
    b = s.encode('utf-8')
    return struct.pack('<H', len(b)) + b

def make_subrecord(tag, data):
    return struct.pack('<4sH', tag, len(data)) + data

def make_record(tag, flags, form_id, form_version, body):
    return struct.pack('<4sIIIIHH',
        tag, len(body), flags, form_id, 0, form_version, 0
    ) + body

def make_top_grup(record_type_tag, records_bytes):
    group_size = 24 + len(records_bytes)
    return (
        struct.pack('<4sI', b'GRUP', group_size)
        + record_type_tag
        + struct.pack('<iHHI', 0, 0, 0, 0)
    ) + records_bytes

def make_quest(form_id, editor_id, display_name, script_name, priority=50):
    form_version = 0x0083
    edid = make_subrecord(b'EDID', (editor_id + '\x00').encode('ascii'))
    vmad_body = struct.pack('<hhH', 5, 2, 1)
    vmad_body += wstring(script_name)
    vmad_body += struct.pack('<BH', 0, 0)
    vmad = make_subrecord(b'VMAD', vmad_body)
    full = make_subrecord(b'FULL', (display_name + '\x00').encode('ascii'))
    dnam = make_subrecord(b'DNAM', struct.pack('<BBBBII', 0x01, 0x01, priority, 0, 0, 0))
    next_sub = make_subrecord(b'NEXT', b'')
    anam = make_subrecord(b'ANAM', struct.pack('<I', 0))
    return make_record(b'QUST', 0, form_id, form_version,
        edid + vmad + full + dnam + next_sub + anam
    )

# --- Quest Definition (PanelFrame REMOVED) ---

quests = [
    {
        'form_id':     0x01000001,
        'editor_id':   'GhostHUDWidgetQuest',
        'display_name': 'GhostHUD Widget Controller',
        'script_name':  'GhostHUDWidget',
        'priority':     50,
    },
    # PanelFrame quest REMOVED — PEX was deleted, caused repeated bind errors
    # Was: FormID 0x01000002, script GhostHUDPanelFrame
]

# --- TES4 Header ---

FORM_VERSION = 0x0083
next_obj_id = max(q['form_id'] for q in quests) + 1

hedr = make_subrecord(b'HEDR', struct.pack('<fII',
    1.00, len(quests), next_obj_id & 0x00FFFFFF
))
cnam = make_subrecord(b'CNAM', b'GhostHUD\x00')
mast1 = make_subrecord(b'MAST', b'HUDFramework.esm\x00')
data1 = make_subrecord(b'DATA', struct.pack('<Q', 0))

tes4 = make_record(b'TES4', 0, 0, FORM_VERSION,
    hedr + cnam + mast1 + data1
)

# --- Build ---

qust_bytes = b''
for q in quests:
    qust_bytes += make_quest(**q)

qust_grup = make_top_grup(b'QUST', qust_bytes)

# --- Write ---

out_dir = os.path.join(os.path.dirname(__file__), '..', 'dist')
os.makedirs(out_dir, exist_ok=True)
out_path = os.path.join(out_dir, 'Ghost_HUD Widgets.esp')

with open(out_path, 'wb') as f:
    f.write(tes4)
    f.write(qust_grup)

total = len(tes4) + len(qust_grup)
print(f"BUILD SUCCESS: {os.path.abspath(out_path)} ({total} bytes)")
print(f"  {len(quests)} quest(s): {', '.join(q['editor_id'] for q in quests)}")
