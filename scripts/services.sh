#!/usr/bin/env bash
set -euo pipefail

HERE="${HERE:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"

install -m 0644 "$HERE/systemd/hermes-gw.service"      /etc/systemd/system/hermes-gw.service
install -m 0644 "$HERE/systemd/obsidian-sync.service"  /etc/systemd/system/obsidian-sync.service

if [ ! -f /etc/default/hermes ]; then
  install -m 0640 -o root -g hermes "$HERE/etc/default/hermes.example" /etc/default/hermes
  echo "seeded /etc/default/hermes (edit before starting services)"
fi

systemctl daemon-reload
systemctl enable hermes-gw.service obsidian-sync.service
