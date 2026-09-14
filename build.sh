#!/usr/bin/env bash
# One-shot ISO build inside a privileged Arch container (run on Fedora host).
# Work dir lives on disk (~/archiso-tmp), NOT /tmp tmpfs, to avoid OOM.
# Usage: ./build.sh [profile-dir] [out-dir] [work-dir]
# Defaults auto-detect ~/archlive/releng (nested copy), then ~/archlive.
set -euo pipefail

if [ $# -ge 1 ]; then
  PROFILE_DIR="$1"
elif [ -f "$HOME/archlive/releng/profiledef.sh" ]; then
  PROFILE_DIR="$HOME/archlive/releng"
else
  PROFILE_DIR="$HOME/archlive"
fi
OUT_DIR="${2:-$HOME/out}"
WORK_DIR="${3:-$HOME/archiso-tmp}"

# Resolve apply.sh location (this script's directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "${OUT_DIR}" "${WORK_DIR}"
PROFILE_DIR="$(realpath "${PROFILE_DIR}")"
OUT_DIR="$(realpath "${OUT_DIR}")"
WORK_DIR="$(realpath "${WORK_DIR}")"

# Apply overlay to the host profile dir first (no docker needed for this).
# Extra packages may be pulled by pacman inside the container at build time,
# but the overlay copy + profiledef patch run here on the host.
"${SCRIPT_DIR}/apply.sh" "${PROFILE_DIR}"

sudo docker run --rm -it --privileged \
  -v /dev:/dev \
  -v "${PROFILE_DIR}:/profile" \
  -v "${OUT_DIR}:/out" \
  -v "${WORK_DIR}:/work" \
  archlinux:latest bash -c "
    set -euo pipefail
    pacman -Sy --noconfirm archiso
    mkarchiso -v -w /work -o /out /profile
  "

echo "ISO written to ${OUT_DIR}"
