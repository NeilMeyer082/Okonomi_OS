#!/usr/bin/env bash
# One-shot ISO build inside a privileged Arch container (run on Fedora host).
# Work dir lives on disk (~/archiso-tmp), NOT /tmp tmpfs, to avoid OOM.
# Usage: ./iso/build.sh [profile-dir] [out-dir]
set -euo pipefail

PROFILE_DIR="${1:-$HOME/archlive}"
OUT_DIR="${2:-$HOME/out}"
WORK_DIR="${3:-$HOME/archiso-tmp}"

mkdir -p "${OUT_DIR}" "${WORK_DIR}"
PROFILE_DIR="$(realpath "${PROFILE_DIR}")"
OUT_DIR="$(realpath "${OUT_DIR}")"
WORK_DIR="$(realpath "${WORK_DIR}")"

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
