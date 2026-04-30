#!/usr/bin/env bash
set -euo pipefail

curl -fsSL --retry 5 --retry-delay 2 --retry-all-errors \
  https://starship.rs/install.sh | sh -s -- -y -b /usr/local/bin

starship --version | head -n1
