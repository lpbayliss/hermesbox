#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

if ! command -v node >/dev/null 2>&1 || [ "$(node -v 2>/dev/null | cut -c2- | cut -d. -f1)" -lt 22 ]; then
  curl -fsSL --retry 5 --retry-delay 2 --retry-all-errors https://deb.nodesource.com/setup_22.x | bash -
  apt-get install -y --no-install-recommends nodejs
fi

node --version
npm --version
