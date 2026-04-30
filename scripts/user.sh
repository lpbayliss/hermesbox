#!/usr/bin/env bash
set -euo pipefail

if ! id hermes >/dev/null 2>&1; then
  useradd -m -s /bin/bash -u 1000 hermes
fi

usermod -aG sudo,adm,systemd-journal hermes

cat > /etc/sudoers.d/90-hermes <<'EOF'
hermes ALL=(ALL) NOPASSWD: ALL
Defaults:hermes !requiretty
EOF
chmod 0440 /etc/sudoers.d/90-hermes
visudo -cf /etc/sudoers.d/90-hermes >/dev/null

install -d -o hermes -g hermes -m 0755 \
  /home/hermes/.config/git \
  /home/hermes/.config/gh \
  /home/hermes/.claude \
  /home/hermes/.hermes \
  /home/hermes/.local/bin
install -d -o hermes -g hermes -m 0700 /home/hermes/.ssh

install -d -m 0755 /etc/hermes
install -d -m 1777 /var/lib/bash-history
install -d -m 0755 /workspace /vault
chown hermes:hermes /workspace /vault

git config --system --add safe.directory '*'
