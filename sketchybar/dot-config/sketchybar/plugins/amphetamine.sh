#!/bin/bash

if [ "$SENDER" = "mouse.exited.global" ]; then
  sketchybar --set "$NAME" popup.drawing=off
  exit 0
fi

(
  IS_RUNNING=$(pgrep -x "Amphetamine" 2>/dev/null)
  if [ -z "$IS_RUNNING" ]; then
    sketchybar --set amphetamine icon="󰛊" icon.color=0xff565f89 label=""
    exit 0
  fi

  SESSION_ACTIVE=$(osascript -e 'tell application "Amphetamine" to return session is active' 2>/dev/null)

  if [ "$SESSION_ACTIVE" = "true" ]; then
    REMAINING=$(osascript -e 'tell application "Amphetamine" to return session time remaining' 2>/dev/null)

    if [ "$REMAINING" = "-1" ] || [ "$REMAINING" = "0" ]; then
      sketchybar --set amphetamine icon="󰛊" icon.color=0xff9ece6a label="∞"
    else
      HOURS=$((REMAINING / 3600))
      MINS=$(((REMAINING % 3600) / 60))
      if [ "$HOURS" -gt 0 ]; then
        LABEL="${HOURS}h${MINS}m"
      else
        LABEL="${MINS}m"
      fi
      sketchybar --set amphetamine icon="󰛊" icon.color=0xff9ece6a label="$LABEL"
    fi
  else
    sketchybar --set amphetamine icon="󰛊" icon.color=0xff565f89 label=""
  fi
) &
