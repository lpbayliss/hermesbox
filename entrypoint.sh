#!/usr/bin/env bash
set -euo pipefail

mkdir -p /etc/ssh/keys /var/lib/bash-history /workspace /vault \
         /home/hermes/.ssh /home/hermes/.config/git /home/hermes/.config/gh \
         /home/hermes/.claude /home/hermes/.hermes
chmod 700 /home/hermes/.ssh
chmod 1777 /var/lib/bash-history
chown -R hermes:hermes /home/hermes /workspace /vault

for kt in rsa ecdsa ed25519; do
  key="/etc/ssh/keys/ssh_host_${kt}_key"
  [ -f "$key" ] || ssh-keygen -q -t "$kt" -f "$key" -N ''
done

HERMES_PASSWORD="${HERMES_PASSWORD:-hermes}"
echo "hermes:${HERMES_PASSWORD}" | chpasswd
unset HERMES_PASSWORD

env_passthrough_script=/etc/profile.d/zz-hermes-env.sh
: > "$env_passthrough_script"
chmod 644 "$env_passthrough_script"
while IFS='=' read -r key val; do
  case "$key" in
    OPENROUTER_API_KEY|ANTHROPIC_API_KEY|ANTHROPIC_TOKEN|OPENAI_API_KEY|\
    GOOGLE_API_KEY|GEMINI_API_KEY|DEEPSEEK_API_KEY|DASHSCOPE_API_KEY|\
    GLM_API_KEY|ZAI_API_KEY|KIMI_API_KEY|MINIMAX_API_KEY|XAI_API_KEY|\
    GROQ_API_KEY|HF_TOKEN|OLLAMA_API_KEY|\
    TAVILY_API_KEY|EXA_API_KEY|FIRECRAWL_API_KEY|PARALLEL_API_KEY|\
    FAL_KEY|BROWSERBASE_API_KEY|BROWSERBASE_PROJECT_ID|\
    VOICE_TOOLS_OPENAI_KEY|HONCHO_API_KEY|GITHUB_TOKEN|\
    TELEGRAM_BOT_TOKEN|TELEGRAM_ALLOWED_USERS|TELEGRAM_HOME_CHANNEL|\
    DISCORD_BOT_TOKEN|SLACK_BOT_TOKEN|SLACK_APP_TOKEN|SLACK_ALLOWED_USERS|\
    EMAIL_ADDRESS|EMAIL_PASSWORD|TINKER_API_KEY|WANDB_API_KEY|TZ)
      [ -n "$val" ] && printf 'export %s=%q\n' "$key" "$val" >> "$env_passthrough_script"
      ;;
  esac
done < <(env)

if [ -n "${GH_PAT:-}" ]; then
  printf '%s' "$GH_PAT" | sudo -u hermes -H bash -lc 'gh auth login --with-token && gh auth setup-git' || true
  unset GH_PAT
fi

if [ -f /home/hermes/.hermes/config.yaml ]; then
  sudo -u hermes -H bash -lc 'hermes-seed' || true
fi

sudo -u hermes -H bash -lc 'hermes-gw start' || echo "hermes-gw start failed (continuing)" >&2

echo "sshd starting on :22 (user: hermes)"
exec /usr/sbin/sshd -D -e
