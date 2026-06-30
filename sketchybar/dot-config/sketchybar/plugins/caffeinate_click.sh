#!/bin/bash

sketchybar --remove '/caffeinate\./' 2>/dev/null

CAFFEINATE="$CONFIG_DIR/plugins/caffeinate_session.sh"

STATE_DIR="/tmp/sketchybar_caffeinate"
PID_FILE="$STATE_DIR/pid"

if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
  SESSION_ACTIVE="true"
else
  SESSION_ACTIVE="false"
fi

ARGS=()

if [ "$SESSION_ACTIVE" = "true" ]; then
  ICON_COLOR=0xff7aa2f7
  LABEL_COLOR=0xffa9b1d6
else
  ICON_COLOR=0xff9ece6a
  LABEL_COLOR=0xffc0caf5
fi

ARGS+=(--add item caffeinate.until6 popup.caffeinate)
ARGS+=(--set caffeinate.until6
  icon="󰥔"
  icon.color="$ICON_COLOR"
  label="Until 6 PM"
  label.color="$LABEL_COLOR"
  click_script="$CAFFEINATE until6"
)

ARGS+=(--add item caffeinate.add1h popup.caffeinate)
ARGS+=(--set caffeinate.add1h
  icon="󰁪"
  icon.color="$ICON_COLOR"
  label="Add 1 hour"
  label.color="$LABEL_COLOR"
  click_script="$CAFFEINATE add 3600"
)

ARGS+=(--add item caffeinate.add3h popup.caffeinate)
ARGS+=(--set caffeinate.add3h
  icon="󰁪"
  icon.color="$ICON_COLOR"
  label="Add 3 hours"
  label.color="$LABEL_COLOR"
  click_script="$CAFFEINATE add 10800"
)

if [ "$SESSION_ACTIVE" = "true" ]; then
  ARGS+=(--add item caffeinate.end popup.caffeinate)
  ARGS+=(--set caffeinate.end
    icon="󰅖"
    icon.color=0xfff7768e
    label="End session"
    label.color=0xffc0caf5
    click_script="$CAFFEINATE end"
  )
fi

ARGS+=(--set caffeinate popup.drawing=toggle)

sketchybar "${ARGS[@]}"
