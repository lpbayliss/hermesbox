#!/usr/bin/env bash
set -euo pipefail

HERE="${HERE:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"

install -m 0644 "$HERE/systemd/hermes-gw.service"      /etc/systemd/system/hermes-gw.service
install -m 0644 "$HERE/systemd/obsidian-sync.service"  /etc/systemd/system/obsidian-sync.service

if [ ! -f /etc/default/hermes ]; then
  install -m 0640 -o root -g hermes "$HERE/etc/default/hermes.example" /etc/default/hermes
  echo "seeded /etc/default/hermes (edit before starting services)"
fi

if [ -r /etc/default/hermes ]; then
  TZ_VAL="$(awk -F= '/^TZ=/ {gsub(/"/,"",$2); print $2}' /etc/default/hermes)"
  if [ -n "$TZ_VAL" ] && [ -d "/usr/share/zoneinfo/$TZ_VAL" ]; then
    timedatectl set-timezone "$TZ_VAL" 2>/dev/null || true
  fi
fi

systemctl daemon-reload

for u in hermes-gw.service obsidian-sync.service; do
  state="$(systemctl is-enabled "$u" 2>/dev/null || echo unknown)"
  if [ "$state" = "disabled" ]; then
    echo "$u manually disabled — leaving as-is"
  else
    systemctl enable "$u"
  fi
done
