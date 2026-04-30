#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends \
  ca-certificates curl wget gnupg locales tzdata \
  git openssh-server sudo bash bash-completion \
  vim nano less tmux ripgrep fd-find jq tree fzf \
  zoxide direnv build-essential python3 make unzip zip xz-utils \
  htop procps iproute2 file libatomic1 ncurses-term

if ! locale -a 2>/dev/null | grep -qi '^en_US.utf8$'; then
  sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
  locale-gen
fi

if [ ! -e /usr/local/bin/fd ] && command -v fdfind >/dev/null 2>&1; then
  ln -s "$(command -v fdfind)" /usr/local/bin/fd
fi

install -d -m 0755 /etc/apt/keyrings
