#!/bin/bash
#
# Manages a `caffeinate` keep-awake session for the sketchybar caffeinate item.
#
# Usage:
#   caffeinate_session.sh until6        # keep awake until 6 PM today
#   caffeinate_session.sh add <seconds> # extend (or start) by <seconds>
#   caffeinate_session.sh end           # stop the session
#
# State is tracked in $STATE_DIR: the caffeinate PID and the session end epoch.

STATE_DIR="/tmp/sketchybar_caffeinate"
PID_FILE="$STATE_DIR/pid"
END_FILE="$STATE_DIR/end"

mkdir -p "$STATE_DIR"

is_active() {
  [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null
}

stop() {
  if [ -f "$PID_FILE" ]; then
    kill "$(cat "$PID_FILE")" 2>/dev/null
  fi
  rm -f "$PID_FILE" "$END_FILE"
}

# Start a session that runs until the given end epoch. Replaces any current one.
start_until() {
  local end=$1
  local now secs
  now=$(date "+%s")
  secs=$((end - now))
  [ "$secs" -le 0 ] && return 1

  stop
  # -d display, -i idle, -s system, -u user-active; -t bounds the assertion.
  caffeinate -disu -t "$secs" &
  echo $! >"$PID_FILE"
  echo "$end" >"$END_FILE"
}

case "$1" in
  until6)
    start_until "$(date -j -f "%H:%M" "18:00" "+%s")"
    ;;
  add)
    seconds=$2
    if is_active; then
      base=$(cat "$END_FILE")
    else
      base=$(date "+%s")
    fi
    start_until $((base + seconds))
    ;;
  end)
    stop
    ;;
  *)
    echo "usage: $0 {until6|add <seconds>|end}" >&2
    exit 1
    ;;
esac

sketchybar --set caffeinate popup.drawing=off 2>/dev/null
exit 0
