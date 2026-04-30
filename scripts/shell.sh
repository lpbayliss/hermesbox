#!/usr/bin/env bash
set -euo pipefail

cat > /etc/profile.d/zz-hermes-box.sh <<'EOF'
export HISTFILE=/var/lib/bash-history/${USER:-anon}.history
export HISTSIZE=10000
export HISTFILESIZE=20000
shopt -s histappend 2>/dev/null || true

[ -f /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion
[ -f /usr/share/doc/fzf/examples/key-bindings.bash ] && . /usr/share/doc/fzf/examples/key-bindings.bash
[ -f /usr/share/doc/fzf/examples/completion.bash ] && . /usr/share/doc/fzf/examples/completion.bash

command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"
command -v zoxide   >/dev/null 2>&1 && eval "$(zoxide init bash)"
command -v direnv   >/dev/null 2>&1 && eval "$(direnv hook bash)"

if command -v eza >/dev/null 2>&1; then
  alias ls="eza"
  alias ll="eza -lah --git"
  alias la="eza -a"
  alias tree="eza --tree"
fi

case ":$PATH:" in
  *:/home/hermes/.local/bin:*) ;;
  *) [ "$(id -un)" = "hermes" ] && export PATH="/home/hermes/.local/bin:$PATH" ;;
esac
EOF
chmod 0644 /etc/profile.d/zz-hermes-box.sh

for u in root hermes; do
  home="$(getent passwd "$u" | cut -d: -f6)"
  [ -n "$home" ] || continue
  cat > "$home/.bash_profile" <<'EOF'
[ -f ~/.bashrc ] && source ~/.bashrc
. /etc/profile.d/zz-hermes-box.sh 2>/dev/null || true
EOF
  chown "$u:$u" "$home/.bash_profile" 2>/dev/null || true
done
