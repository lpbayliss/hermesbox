#!/usr/bin/env bash
set -euo pipefail

if ! id hermes >/dev/null 2>&1; then
  echo "hermes user missing — run scripts/user.sh first" >&2
  exit 1
fi

chown -R hermes:hermes /home/hermes

sudo -u hermes -H bash -lc '
  set -euo pipefail
  export HERMES_NONINTERACTIVE=1
  export PATH="$HOME/.local/bin:$PATH"
  TMP="$(mktemp -d)"
  trap "rm -rf $TMP" EXIT
  curl -fsSL --retry 5 --retry-delay 2 --retry-all-errors \
    https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh \
    -o "$TMP/install-hermes.sh"
  bash "$TMP/install-hermes.sh" </dev/null
'
