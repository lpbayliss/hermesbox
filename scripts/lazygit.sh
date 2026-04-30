#!/usr/bin/env bash
set -euo pipefail

LG_VER="$(curl -fsSL --retry 5 --retry-delay 2 --retry-all-errors \
  https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
  | jq -r .tag_name | sed 's/^v//')"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

curl -fsSL --retry 5 --retry-delay 2 --retry-all-errors \
  "https://github.com/jesseduffield/lazygit/releases/download/v${LG_VER}/lazygit_${LG_VER}_Linux_x86_64.tar.gz" \
  -o "$TMP/lazygit.tar.gz"
tar -xzf "$TMP/lazygit.tar.gz" -C /usr/local/bin lazygit

lazygit --version | head -n1
