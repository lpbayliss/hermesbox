#!/usr/bin/env bash
set -euo pipefail

DELTA_VER="$(curl -fsSL --retry 5 --retry-delay 2 --retry-all-errors \
  https://api.github.com/repos/dandavison/delta/releases/latest \
  | jq -r .tag_name)"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

curl -fsSL --retry 5 --retry-delay 2 --retry-all-errors \
  "https://github.com/dandavison/delta/releases/download/${DELTA_VER}/git-delta_${DELTA_VER}_amd64.deb" \
  -o "$TMP/delta.deb"
dpkg -i "$TMP/delta.deb"

delta --version | head -n1
