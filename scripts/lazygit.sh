#!/usr/bin/env bash
set -euo pipefail

LG_VER="$(curl -sLo /dev/null -w '%{url_effective}' \
  https://github.com/jesseduffield/lazygit/releases/latest \
  | sed 's|.*/v||')"
[ -n "$LG_VER" ] || { echo "lazygit: failed to resolve latest version" >&2; exit 1; }

if command -v lazygit >/dev/null 2>&1 && lazygit --version 2>/dev/null | grep -q "version=$LG_VER"; then
  echo "lazygit $LG_VER already installed"
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

curl -fsSL --retry 5 --retry-delay 2 --retry-all-errors \
  "https://github.com/jesseduffield/lazygit/releases/download/v${LG_VER}/lazygit_${LG_VER}_Linux_x86_64.tar.gz" \
  -o "$TMP/lazygit.tar.gz"
tar -xzf "$TMP/lazygit.tar.gz" -C /usr/local/bin lazygit

lazygit --version | head -n1
