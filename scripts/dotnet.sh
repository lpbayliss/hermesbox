#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

if ! dpkg -s packages-microsoft-prod >/dev/null 2>&1; then
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT
  curl -fsSL --retry 5 --retry-delay 2 --retry-all-errors \
    https://packages.microsoft.com/config/debian/13/packages-microsoft-prod.deb \
    -o "$TMP/packages-microsoft-prod.deb"
  dpkg -i "$TMP/packages-microsoft-prod.deb"
  apt-get update
fi

apt-get install -y --no-install-recommends dotnet-sdk-8.0

dotnet --version
