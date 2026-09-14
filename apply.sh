#!/usr/bin/env bash
# Merge iso/airootfs overlay into a releng-derived profile (~/archlive)
# and ensure profiledef.sh file_permissions cover the new files.
# Run on the HOST (Fedora) before building, or inside the Arch container.
# Usage: ./iso/apply.sh [profile-dir]  (default: $HOME/archlive)
set -euo pipefail

PROFILE_DIR="${1:-$HOME/archlive}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="${REPO_ROOT}/airootfs"

if [ ! -d "${PROFILE_DIR}/airootfs" ]; then
  echo "error: ${PROFILE_DIR}/airootfs not found. Copy releng first:" >&2
  echo "  cp -r /usr/share/archiso/configs/releng ${PROFILE_DIR}" >&2
  exit 1
fi

cp -a "${SRC}/." "${PROFILE_DIR}/airootfs/"
chmod 755 "${PROFILE_DIR}/airootfs/usr/local/bin/arch-rice-loader.sh"
chmod 644 "${PROFILE_DIR}/airootfs/root/.bash_profile" "${PROFILE_DIR}/airootfs/root/.zprofile" 2>/dev/null || true
chmod 644 "${PROFILE_DIR}/airootfs/etc/motd" 2>/dev/null || true

# Patch profiledef.sh file_permissions idempotently via python3
python3 - "${PROFILE_DIR}/profiledef.sh" <<'PY'
import sys, re
path = sys.argv[1]
wanted = {
  "/usr/local/bin/arch-rice-loader.sh": "0:0:755",
  "/root/.bash_profile": "0:0:644",
  "/root/.zprofile": "0:0:644",
  "/etc/motd": "0:0:644",
}
src = open(path).read()
missing = [f'  ["{k}"]="{v}"' for k, v in wanted.items() if k not in src]
if not missing:
    print("profiledef.sh: permissions already present")
    sys.exit(0)
anchor = "file_permissions=("
if anchor not in src:
    print(f"error: {anchor} not found in {path}", file=sys.stderr)
    sys.exit(1)
src = src.replace(anchor, anchor + "\n" + "\n".join(missing), 1)
open(path, "w").write(src)
print("profiledef.sh: added", ", ".join(missing))
PY

echo "overlay applied to ${PROFILE_DIR}"
