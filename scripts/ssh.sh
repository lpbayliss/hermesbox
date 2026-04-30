#!/usr/bin/env bash
set -euo pipefail

install -d -m 0755 /var/run/sshd

sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

if ! grep -q '^AcceptEnv TZ LANG LC_\*' /etc/ssh/sshd_config; then
  echo "AcceptEnv TZ LANG LC_*" >> /etc/ssh/sshd_config
fi

systemctl enable --now ssh
systemctl reload ssh || systemctl restart ssh
