FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    HERMES_NONINTERACTIVE=1 \
    CURL_RETRY="--retry 5 --retry-delay 2 --retry-all-errors --connect-timeout 15"

RUN apt-get update && apt-get install -y --no-install-recommends \
        git curl ca-certificates locales bash tini xz-utils gnupg \
        openssh-server sudo vim nano less tmux ripgrep fd-find jq tree fzf \
        bash-completion zoxide direnv build-essential python3 make unzip zip \
        wget htop procps iproute2 file tzdata libatomic1 ncurses-term \
    && locale-gen en_US.UTF-8 \
    && ln -s "$(command -v fdfind)" /usr/local/bin/fd \
    && mkdir -p -m 755 /etc/apt/keyrings \
    && curl $CURL_RETRY -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
       | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
       > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y --no-install-recommends gh \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && npm install -g @anthropic-ai/claude-code \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux \
    && curl $CURL_RETRY -fsSL https://starship.rs/install.sh | sh -s -- -y -b /usr/local/bin

RUN set -eux \
    && ARCH="$(dpkg --print-architecture)" \
    && case "$ARCH" in \
         amd64) LG_ARCH=x86_64 ;; \
         arm64) LG_ARCH=arm64 ;; \
         *) echo "unsupported arch: $ARCH" && exit 1 ;; \
       esac \
    && LG_VER="$(curl $CURL_RETRY -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest | jq -r .tag_name | sed 's/^v//')" \
    && curl $CURL_RETRY -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${LG_VER}/lazygit_${LG_VER}_Linux_${LG_ARCH}.tar.gz" \
         -o /tmp/lazygit.tar.gz \
    && tar -xzf /tmp/lazygit.tar.gz -C /usr/local/bin lazygit \
    && rm /tmp/lazygit.tar.gz

RUN set -eux \
    && ARCH="$(dpkg --print-architecture)" \
    && DELTA_VER="$(curl $CURL_RETRY -fsSL https://api.github.com/repos/dandavison/delta/releases/latest | jq -r .tag_name)" \
    && curl $CURL_RETRY -fsSL "https://github.com/dandavison/delta/releases/download/${DELTA_VER}/git-delta_${DELTA_VER}_${ARCH}.deb" \
         -o /tmp/delta.deb \
    && dpkg -i /tmp/delta.deb \
    && rm /tmp/delta.deb

RUN set -eux \
    && ARCH="$(dpkg --print-architecture)" \
    && case "$ARCH" in \
         amd64) EZA_ARCH=x86_64-unknown-linux-gnu ;; \
         arm64) EZA_ARCH=aarch64-unknown-linux-gnu ;; \
         *) echo "unsupported arch: $ARCH" && exit 1 ;; \
       esac \
    && curl $CURL_RETRY -fsSL "https://github.com/eza-community/eza/releases/latest/download/eza_${EZA_ARCH}.tar.gz" \
         -o /tmp/eza.tar.gz \
    && tar -xzf /tmp/eza.tar.gz -C /usr/local/bin \
    && rm /tmp/eza.tar.gz

RUN npm install -g obsidian-headless

RUN mkdir -p /var/run/sshd /etc/ssh/keys \
    && sed -i 's/#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config \
    && sed -i 's/#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's|^#\?HostKey /etc/ssh/ssh_host_\(.*\)_key|HostKey /etc/ssh/keys/ssh_host_\1_key|' /etc/ssh/sshd_config \
    && echo "AcceptEnv TZ LANG LC_*" >> /etc/ssh/sshd_config

RUN mkdir -p /var/lib/bash-history \
    && chmod 1777 /var/lib/bash-history \
    && git config --system --add safe.directory '*'

RUN useradd -m -s /bin/bash -u 1000 hermes \
    && usermod -aG sudo hermes \
    && echo "hermes ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/90-hermes \
    && chmod 0440 /etc/sudoers.d/90-hermes \
    && mkdir -p /home/hermes/.ssh /home/hermes/.config/git /home/hermes/.config/gh /home/hermes/.claude /home/hermes/.hermes \
    && chmod 700 /home/hermes/.ssh \
    && chown -R hermes:hermes /home/hermes

RUN printf '%s\n' \
      'export HISTFILE=/var/lib/bash-history/${USER:-anon}.history' \
      'export HISTSIZE=10000' \
      'export HISTFILESIZE=20000' \
      'shopt -s histappend 2>/dev/null || true' \
      '' \
      '[ -f /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion' \
      '[ -f /usr/share/doc/fzf/examples/key-bindings.bash ] && . /usr/share/doc/fzf/examples/key-bindings.bash' \
      '[ -f /usr/share/doc/fzf/examples/completion.bash ] && . /usr/share/doc/fzf/examples/completion.bash' \
      '' \
      'command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"' \
      'command -v zoxide   >/dev/null 2>&1 && eval "$(zoxide init bash)"' \
      'command -v direnv   >/dev/null 2>&1 && eval "$(direnv hook bash)"' \
      '' \
      'if command -v eza >/dev/null 2>&1; then' \
      '  alias ls="eza"' \
      '  alias ll="eza -lah --git"' \
      '  alias la="eza -a"' \
      '  alias tree="eza --tree"' \
      'fi' \
      > /etc/profile.d/zz-hermes-box.sh \
    && chmod +x /etc/profile.d/zz-hermes-box.sh

RUN printf '%s\n' \
      '[ -f ~/.bashrc ] && source ~/.bashrc' \
      '. /etc/profile.d/zz-hermes-box.sh 2>/dev/null || true' \
      | tee /root/.bash_profile /home/hermes/.bash_profile >/dev/null \
    && chown hermes:hermes /home/hermes/.bash_profile

USER hermes
WORKDIR /home/hermes

ARG HERMES_CACHEBUST=unset
RUN echo "cachebust=${HERMES_CACHEBUST}" \
    && curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh -o /tmp/install-hermes.sh \
    && bash /tmp/install-hermes.sh </dev/null \
    && rm /tmp/install-hermes.sh

USER root
ENV PATH="/usr/local/bin:/home/hermes/.local/bin:${PATH}"

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY hermes-seed.sh /usr/local/bin/hermes-seed
COPY hermes-gw.sh /usr/local/bin/hermes-gw
COPY config.seed.yaml /etc/hermes/config.seed.yaml
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/hermes-seed /usr/local/bin/hermes-gw

WORKDIR /workspace

EXPOSE 22

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD []
