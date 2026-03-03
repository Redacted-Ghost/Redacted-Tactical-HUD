"""
check_noclobber.py — Safety check: ensure dist/ never contains files
that would overwrite FallUI, HUDFramework, or other mods.

Run before deploy. Fails with exit code 1 if forbidden files are found.
"""

import os
import sys

DIST_DIR = os.path.join(os.path.dirname(__file__), '..', 'dist')

# Files/dirs that must NEVER exist in our dist/
FORBIDDEN = [
    'Interface/HUDMenu.swf',           # FallUI HUD replacement — never ship this
    'Interface/FallUI HUD',             # FallUI config/layouts folder
    'Interface/HUDFramework.swf',       # HUDFramework's own SWF
    'MCM',                              # MCM configs (until we intentionally add our own)
    'Interface/PromptMenu.swf',         # FallUI prompt replacement
    'Interface/Workshop.swf',           # FallUI workshop replacement
]

def check():
    dist = os.path.abspath(DIST_DIR)
    if not os.path.isdir(dist):
        print("SKIP: dist/ directory does not exist yet.")
        return True

    violations = []
    for forbidden in FORBIDDEN:
        path = os.path.join(dist, forbidden.replace('/', os.sep))
        if os.path.exists(path):
            violations.append(forbidden)

    if violations:
        print("NO-CLOBBER CHECK FAILED!")
        print("The following forbidden files/dirs were found in dist/:")
        for v in violations:
            print(f"  BLOCKED: {v}")
        print()
        print("These would overwrite FallUI/HUDFramework files when deployed.")
        print("Remove them from dist/ before deploying.")
        return False

    # Also list what IS in dist/ for visibility
    print("NO-CLOBBER CHECK PASSED")
    print("dist/ contents:")
    for root, dirs, files in os.walk(dist):
        for f in files:
            rel = os.path.relpath(os.path.join(root, f), dist)
            print(f"  OK: {rel}")

    return True

if __name__ == '__main__':
    if not check():
        sys.exit(1)
