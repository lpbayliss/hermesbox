#!/usr/bin/env bash
set -euo pipefail

DELTA_VER="$(curl -sLo /dev/null -w '%{url_effective}' \
  https://github.com/dandavison/delta/releases/latest \
  | sed 's|.*/||')"
[ -n "$DELTA_VER" ] || { echo "delta: failed to resolve latest version" >&2; exit 1; }

if command -v delta >/dev/null 2>&1 && delta --version 2>/dev/null | grep -qE "^delta ${DELTA_VER}$"; then
  echo "delta $DELTA_VER already installed"
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

curl -fsSL --retry 5 --retry-delay 2 --retry-all-errors \
  "https://github.com/dandavison/delta/releases/download/${DELTA_VER}/git-delta_${DELTA_VER}_amd64.deb" \
  -o "$TMP/delta.deb"
dpkg -i "$TMP/delta.deb"

delta --version | head -n1
