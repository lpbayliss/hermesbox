#!/usr/bin/env bash
set -euo pipefail

GODOT_VERSION="${GODOT_VERSION:-4.6.2-stable}"
INSTALL_DIR=/opt/godot
ZIP_NAME="Godot_v${GODOT_VERSION}_mono_linux_x86_64"
URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/${ZIP_NAME}.zip"
VER="${GODOT_VERSION%-*}"

if command -v godot >/dev/null 2>&1 && godot --version 2>/dev/null | grep -qE "^${VER}\."; then
  echo "godot $GODOT_VERSION already installed"
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

curl -fL --retry 5 --retry-delay 2 --retry-all-errors -o "$TMP/godot.zip" "$URL"

rm -rf "$INSTALL_DIR"
install -d -m 0755 "$INSTALL_DIR"
unzip -q "$TMP/godot.zip" -d "$INSTALL_DIR"

BIN="$INSTALL_DIR/${ZIP_NAME}/Godot_v${GODOT_VERSION}_mono_linux.x86_64"
chmod +x "$BIN"
ln -sf "$BIN" /usr/local/bin/godot

godot --version
