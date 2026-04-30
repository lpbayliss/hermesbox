#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "upgrade.sh must run as root" >&2
  exit 1
fi

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export HERE

SCRIPTS=(
  scripts/00-base.sh
  scripts/shell.sh
  scripts/node.sh
  scripts/dotnet.sh
  scripts/godot.sh
  scripts/gh.sh
  scripts/lefthook.sh
  scripts/claude-code.sh
  scripts/obsidian-headless.sh
  scripts/starship.sh
  scripts/lazygit.sh
  scripts/delta.sh
  scripts/eza.sh
  scripts/hermes.sh
  scripts/services.sh
)

for s in "${SCRIPTS[@]}"; do
  echo
  echo "=== $s ==="
  bash "$HERE/$s"
done

systemctl daemon-reload
for u in hermes-gw.service obsidian-sync.service; do
  if systemctl is-enabled --quiet "$u"; then
    systemctl restart "$u" || echo "$u restart failed (continuing)" >&2
  fi
done

echo
echo "upgrade complete."
