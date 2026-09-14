#!/usr/bin/env bash
# Live-ISO convenience loader: install archinstall if needed and launch
# the guided installer pre-seeded with the Arch Rice partial config.
# The repo itself is NOT baked into the ISO; it is cloned on first boot
# of the installed system so `main` stays live without ISO rebuilds.
set -euo pipefail

CONFIG_URL="https://raw.githubusercontent.com/NeilMeyer082/neil-arch-rice/main/archinstall/rice.json"

if ! command -v archinstall >/dev/null 2>&1; then
  pacman -Sy --noconfirm archinstall
fi

# Partial config: disk, users, locale etc. still prompt interactively.
exec archinstall --config-url "${CONFIG_URL}"
