#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "install.sh must run as root" >&2
  exit 1
fi

if [ ! -r /etc/os-release ] || ! grep -q '^ID=debian' /etc/os-release; then
  echo "install.sh targets Debian only" >&2
  exit 1
fi

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export HERE

SCRIPTS=(
  scripts/00-base.sh
  scripts/user.sh
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
  scripts/ssh.sh
  scripts/shell.sh
  scripts/services.sh
)

for s in "${SCRIPTS[@]}"; do
  echo
  echo "=== $s ==="
  bash "$HERE/$s"
done

echo
echo "install complete."
echo "edit /etc/default/hermes, then: systemctl start hermes-gw obsidian-sync"
