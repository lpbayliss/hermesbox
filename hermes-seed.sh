#!/usr/bin/env bash
set -euo pipefail

CONFIG="${HERMES_CONFIG:-$HOME/.hermes/config.yaml}"
MARKER="$HOME/.hermes/.seed-applied"

if [ ! -f "$CONFIG" ]; then
  echo "hermes-seed: $CONFIG missing — run 'hermes setup' first" >&2
  exit 0
fi

if [ -f "$MARKER" ] && [ "${HERMES_SEED_FORCE:-0}" != "1" ]; then
  exit 0
fi

set_kv() {
  hermes config set "$1" "$2" >/dev/null && echo "  set $1 = $2" || echo "  FAIL $1" >&2
}

echo "hermes-seed: applying overrides"

set_kv model.provider              openrouter
set_kv model.name                  moonshotai/kimi-k2.6

set_kv fallback_model.provider     openrouter
set_kv fallback_model.model        minimax/minimax-m2.5:free

set_kv delegation.model            openrouter/google/gemini-3.1-flash-lite-preview

set_kv compression.enabled         true
set_kv compression.threshold       0.30
set_kv compression.target_ratio    0.2
set_kv compression.model           openrouter/openai/gpt-5.4-nano

set_kv prompt_caching.cache_ttl    1h

set_kv agent.max_turns             60
set_kv agent.reasoning_effort      low

set_kv session_reset.mode          both
set_kv session_reset.idle_minutes  360
set_kv session_reset.at_hour       4

set_kv browser.inactivity_timeout  300

set_kv streaming.enabled           true
set_kv display.streaming           true

hermes config unset model.default 2>/dev/null || true

touch "$MARKER"
echo "hermes-seed: done"
