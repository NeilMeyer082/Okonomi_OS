#!/usr/bin/env bash
# Arch Rice firstboot: clone repo as the real user, prepare bootstrap.
# Runs once via arch-rice-firstboot.service. Never runs bootstrap.sh
# itself: systemd has no TTY for the 18x dialog menus, and yay + ~/.config
# deploys must run as a non-root user.
set -euo pipefail

REPO_URL="https://github.com/NeilMeyer082/neil-arch-rice.git"

TARGET_USER="$(getent passwd 1000 | cut -d: -f1 || true)"
if [ -z "${TARGET_USER}" ]; then
  TARGET_USER="$(ls /home 2>/dev/null | head -n1 || true)"
fi
if [ -z "${TARGET_USER}" ]; then
  echo "arch-rice-firstboot: no non-root user found, aborting." >&2
  exit 1
fi
TARGET_HOME="$(getent passwd "${TARGET_USER}" | cut -d: -f6)"
DEST="${TARGET_HOME}/arch-rice"

if [ ! -d "${DEST}/.git" ]; then
  sudo -u "${TARGET_USER}" git clone "${REPO_URL}" "${DEST}"
else
  sudo -u "${TARGET_USER}" git -C "${DEST}" pull --ff-only || true
fi

chmod +x "${DEST}/bootstrap.sh"
chown -R "${TARGET_USER}:${TARGET_USER}" "${DEST}"

rm -f /opt/arch-rice-firstboot.pending
systemctl disable arch-rice-firstboot.service || true

echo "Run ~/arch-rice/bootstrap.sh to start ricing" > /etc/motd
echo "arch-rice-firstboot: done. Log in as ${TARGET_USER} and run ~/arch-rice/bootstrap.sh"
