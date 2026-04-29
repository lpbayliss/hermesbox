#!/usr/bin/env bash
set -euo pipefail

HERMES_DIR="${HERMES_DIR:-$HOME/.hermes}"
PID_FILE="$HERMES_DIR/gateway.pid"
LOG_FILE="$HERMES_DIR/gateway.log"

mkdir -p "$HERMES_DIR"

is_running() {
  [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null
}

start() {
  if is_running; then
    echo "hermes gateway already running (pid $(cat "$PID_FILE"))"
    return 0
  fi
  echo "starting hermes gateway (logs: $LOG_FILE)"
  nohup hermes gateway run >>"$LOG_FILE" 2>&1 &
  echo $! > "$PID_FILE"
  disown || true
  sleep 1
  if is_running; then
    echo "started (pid $(cat "$PID_FILE"))"
  else
    echo "failed to start, see $LOG_FILE" >&2
    return 1
  fi
}

stop() {
  if ! is_running; then
    echo "hermes gateway not running"
    rm -f "$PID_FILE"
    return 0
  fi
  pid="$(cat "$PID_FILE")"
  echo "stopping hermes gateway (pid $pid)"
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
  *) echo "usage: hermes-gw {start|stop|restart|status|logs [N]}" >&2; exit 2 ;;
esac
