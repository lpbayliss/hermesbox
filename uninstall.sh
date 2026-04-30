#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "uninstall.sh must run as root" >&2
  exit 1
fi

PURGE_USER=0
PURGE_DATA=0
for arg in "$@"; do
  case "$arg" in
    --purge-user) PURGE_USER=1 ;;
    --purge-data) PURGE_DATA=1 ;;
    --purge)      PURGE_USER=1; PURGE_DATA=1 ;;
    *) echo "unknown flag: $arg" >&2; exit 2 ;;
  esac
done

for u in hermes-gw.service obsidian-sync.service; do
  systemctl disable --now "$u" 2>/dev/null || true
  rm -f "/etc/systemd/system/$u"
done
systemctl daemon-reload || true

rm -f /etc/sudoers.d/90-hermes
rm -f /etc/profile.d/zz-hermes-box.sh
rm -f /etc/default/hermes
rm -rf /etc/hermes

apt-get remove -y gh nodejs git-delta || true
rm -f /etc/apt/sources.list.d/github-cli.list /etc/apt/sources.list.d/nodesource.list
rm -f /etc/apt/keyrings/githubcli-archive-keyring.gpg /etc/apt/keyrings/nodesource.gpg
apt-get update || true

rm -f /usr/local/bin/lazygit /usr/local/bin/eza /usr/local/bin/starship

if [ "$PURGE_DATA" -eq 1 ]; then
  rm -rf /workspace /vault /var/lib/bash-history
fi

if [ "$PURGE_USER" -eq 1 ] && id hermes >/dev/null 2>&1; then
  pkill -u hermes 2>/dev/null || true
  userdel -r hermes 2>/dev/null || userdel hermes 2>/dev/null || true
fi

echo "uninstall complete."
[ "$PURGE_USER" -eq 0 ] && echo "hermes user retained (pass --purge-user to remove)"
[ "$PURGE_DATA" -eq 0 ] && echo "/workspace and /vault retained (pass --purge-data to remove)"
