#!/usr/bin/env bash
set -euo pipefail

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

curl -fsSL --retry 5 --retry-delay 2 --retry-all-errors \
  "https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz" \
  -o "$TMP/eza.tar.gz"
tar -xzf "$TMP/eza.tar.gz" -C /usr/local/bin

eza --version | head -n1
