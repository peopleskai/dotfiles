#!/bin/bash

if [ "$SENDER" = "mouse.exited.global" ]; then
  sketchybar --set "$NAME" popup.drawing=off
  exit 0
fi

(
  STATE_DIR="/tmp/sketchybar_caffeinate"
  PID_FILE="$STATE_DIR/pid"
  END_FILE="$STATE_DIR/end"

  # Inactive unless a caffeinate process we started is still alive.
  if [ ! -f "$PID_FILE" ] || ! kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    rm -f "$PID_FILE" "$END_FILE"
    sketchybar --set caffeinate icon="󰛊" icon.color=0xff565f89 label=""
    exit 0
  fi

  REMAINING=$(( $(cat "$END_FILE" 2>/dev/null || echo 0) - $(date "+%s") ))
  if [ "$REMAINING" -le 0 ]; then
    sketchybar --set caffeinate icon="󰛊" icon.color=0xff9ece6a label="∞"
  else
    HOURS=$((REMAINING / 3600))
    MINS=$(((REMAINING % 3600) / 60))
    if [ "$HOURS" -gt 0 ]; then
      LABEL="${HOURS}h${MINS}m"
    else
      LABEL="${MINS}m"
    fi
    sketchybar --set caffeinate icon="󰛊" icon.color=0xff9ece6a label="$LABEL"
  fi
) &
