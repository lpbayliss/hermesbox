#!/usr/bin/env bash
set -euo pipefail

HERMES_DIR="${HERMES_DIR:-$HOME/.hermes}"
PID_FILE="$HERMES_DIR/obsidian-sync.pid"
LOG_FILE="$HERMES_DIR/obsidian-sync.log"
VAULT_PATH="/vault"

export XDG_CONFIG_HOME="$HERMES_DIR/obsidian-config"
mkdir -p "$HERMES_DIR" "$XDG_CONFIG_HOME"

is_running() {
  [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null
}

have_creds() {
  [ -n "${OBSIDIAN_EMAIL:-}" ] && [ -n "${OBSIDIAN_PASSWORD:-}" ] \
    && [ -n "${OBSIDIAN_VAULT:-}" ] && [ -n "${OBSIDIAN_VAULT_KEY:-}" ]
}

ensure_login() {
  ob login --email "$OBSIDIAN_EMAIL" --password "$OBSIDIAN_PASSWORD" >>"$LOG_FILE" 2>&1
}

ensure_setup() {
  if ! ob sync-status --path "$VAULT_PATH" >/dev/null 2>&1; then
    ob sync-setup --vault "$OBSIDIAN_VAULT" --path "$VAULT_PATH" --password "$OBSIDIAN_VAULT_KEY" >>"$LOG_FILE" 2>&1
  fi
}

start() {
  if ! have_creds; then
    echo "obsidian-sync: required env vars missing, skipping"
    return 0
  fi
  if is_running; then
    echo "obsidian-sync already running (pid $(cat "$PID_FILE"))"
    return 0
  fi
  mkdir -p "$VAULT_PATH"
  echo "obsidian-sync: logging in"
  ensure_login || { echo "obsidian-sync: login failed, see $LOG_FILE" >&2; return 1; }
  echo "obsidian-sync: ensuring vault setup at $VAULT_PATH"
  ensure_setup || { echo "obsidian-sync: setup failed, see $LOG_FILE" >&2; return 1; }
  echo "obsidian-sync: starting continuous sync (logs: $LOG_FILE)"
  nohup ob sync --continuous --path "$VAULT_PATH" >>"$LOG_FILE" 2>&1 &
  echo $! > "$PID_FILE"
  disown || true
  sleep 1
  if is_running; then
    echo "obsidian-sync: started (pid $(cat "$PID_FILE"))"
  else
    echo "obsidian-sync: failed to start, see $LOG_FILE" >&2
    return 1
  fi
}

stop() {
  if ! is_running; then
    echo "obsidian-sync not running"
    rm -f "$PID_FILE"
    return 0
  fi
  pid="$(cat "$PID_FILE")"
  echo "stopping obsidian-sync (pid $pid)"
  kill "$pid" 2>/dev/null || true
  for _ in $(seq 1 20); do
    kill -0 "$pid" 2>/dev/null || break
    sleep 1
  done
  kill -0 "$pid" 2>/dev/null && kill -9 "$pid" || true
  rm -f "$PID_FILE"
  echo "stopped"
}

status() {
  if is_running; then
    echo "running (pid $(cat "$PID_FILE"))"
  else
    echo "stopped"
    return 1
  fi
}

logs() {
  tail -n "${1:-100}" -F "$LOG_FILE"
}

case "${1:-}" in
  start)   start ;;
  stop)    stop ;;
  restart) stop; start ;;
  status)  status ;;
  logs)    shift || true; logs "${1:-100}" ;;
  *) echo "usage: obsidian-sync {start|stop|restart|status|logs [N]}" >&2; exit 2 ;;
esac
