#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

KEY=/etc/apt/keyrings/githubcli-archive-keyring.gpg
LIST=/etc/apt/sources.list.d/github-cli.list

if [ ! -f "$KEY" ]; then
  curl -fsSL --retry 5 --retry-delay 2 --retry-all-errors \
    https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | tee "$KEY" >/dev/null
  chmod go+r "$KEY"
fi

ARCH="$(dpkg --print-architecture)"
echo "deb [arch=$ARCH signed-by=$KEY] https://cli.github.com/packages stable main" > "$LIST"

apt-get update
apt-get install -y --no-install-recommends gh

gh --version | head -n1
