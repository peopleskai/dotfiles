#!/bin/bash

sketchybar --remove '/amphetamine\./' 2>/dev/null

IS_RUNNING=$(pgrep -x "Amphetamine" 2>/dev/null)
if [ -z "$IS_RUNNING" ]; then
  exit 0
fi

SESSION_ACTIVE=$(osascript -e 'tell application "Amphetamine" to return session is active' 2>/dev/null)

UNTIL6PM_SCRIPT='MINS=$(( ($(date -j -f "%H:%M" "18:00" "+%s") - $(date "+%s")) / 60 )); if [ $MINS -gt 0 ]; then osascript -e "tell application \"Amphetamine\" to start new session with options {duration:$MINS, interval:minutes, displaySleepAllowed:false}"; fi; sketchybar --set amphetamine popup.drawing=off'

ARGS=()

if [ "$SESSION_ACTIVE" = "true" ]; then
  ARGS+=(--add item amphetamine.until6 popup.amphetamine)
  ARGS+=(--set amphetamine.until6
    icon="󰥔"
    icon.color=0xff7aa2f7
    label="Until 6 PM"
    label.color=0xffa9b1d6
    click_script="$UNTIL6PM_SCRIPT"
  )

  ARGS+=(--add item amphetamine.add1h popup.amphetamine)
  ARGS+=(--set amphetamine.add1h
    icon="󰁪"
    icon.color=0xff7aa2f7
    label="+1 hour"
    label.color=0xffa9b1d6
    click_script="osascript -e 'tell application \"Amphetamine\" to start new session with options {duration:60, interval:minutes, displaySleepAllowed:false}'; sketchybar --set amphetamine popup.drawing=off"
  )

  ARGS+=(--add item amphetamine.add2h popup.amphetamine)
  ARGS+=(--set amphetamine.add2h
    icon="󰁪"
    icon.color=0xff7aa2f7
    label="+2 hours"
    label.color=0xffa9b1d6
    click_script="osascript -e 'tell application \"Amphetamine\" to start new session with options {duration:120, interval:minutes, displaySleepAllowed:false}'; sketchybar --set amphetamine popup.drawing=off"
  )

  ARGS+=(--add item amphetamine.add4h popup.amphetamine)
  ARGS+=(--set amphetamine.add4h
    icon="󰁪"
    icon.color=0xff7aa2f7
    label="+4 hours"
    label.color=0xffa9b1d6
    click_script="osascript -e 'tell application \"Amphetamine\" to start new session with options {duration:240, interval:minutes, displaySleepAllowed:false}'; sketchybar --set amphetamine popup.drawing=off"
  )

  ARGS+=(--add item amphetamine.end popup.amphetamine)
  ARGS+=(--set amphetamine.end
    icon="󰅖"
    icon.color=0xfff7768e
    label="End session"
    label.color=0xffc0caf5
    click_script="osascript -e 'tell application \"Amphetamine\" to end session'; sketchybar --set amphetamine popup.drawing=off"
  )
else
  ARGS+=(--add item amphetamine.until6 popup.amphetamine)
  ARGS+=(--set amphetamine.until6
    icon="󰥔"
    icon.color=0xff9ece6a
    label="Until 6 PM"
    label.color=0xffc0caf5
    click_script="$UNTIL6PM_SCRIPT"
  )

  ARGS+=(--add item amphetamine.start1h popup.amphetamine)
  ARGS+=(--set amphetamine.start1h
    icon="󰒲"
    icon.color=0xff9ece6a
    label="1 hour"
    label.color=0xffc0caf5
    click_script="osascript -e 'tell application \"Amphetamine\" to start new session with options {duration:60, interval:minutes, displaySleepAllowed:false}'; sketchybar --set amphetamine popup.drawing=off"
  )

  ARGS+=(--add item amphetamine.start2h popup.amphetamine)
  ARGS+=(--set amphetamine.start2h
    icon="󰒲"
    icon.color=0xff9ece6a
    label="2 hours"
    label.color=0xffc0caf5
    click_script="osascript -e 'tell application \"Amphetamine\" to start new session with options {duration:120, interval:minutes, displaySleepAllowed:false}'; sketchybar --set amphetamine popup.drawing=off"
  )

  ARGS+=(--add item amphetamine.start4h popup.amphetamine)
  ARGS+=(--set amphetamine.start4h
    icon="󰒲"
    icon.color=0xff9ece6a
    label="4 hours"
    label.color=0xffc0caf5
    click_script="osascript -e 'tell application \"Amphetamine\" to start new session with options {duration:240, interval:minutes, displaySleepAllowed:false}'; sketchybar --set amphetamine popup.drawing=off"
  )

  ARGS+=(--add item amphetamine.start8h popup.amphetamine)
  ARGS+=(--set amphetamine.start8h
    icon="󰒲"
    icon.color=0xff9ece6a
    label="8 hours"
    label.color=0xffc0caf5
    click_script="osascript -e 'tell application \"Amphetamine\" to start new session with options {duration:480, interval:minutes, displaySleepAllowed:false}'; sketchybar --set amphetamine popup.drawing=off"
  )

  ARGS+=(--add item amphetamine.startinf popup.amphetamine)
  ARGS+=(--set amphetamine.startinf
    icon="󰒲"
    icon.color=0xffe0af68
    label="Indefinite"
    label.color=0xffc0caf5
    click_script="osascript -e 'tell application \"Amphetamine\" to start new session with options {displaySleepAllowed:false}'; sketchybar --set amphetamine popup.drawing=off"
  )
fi

ARGS+=(--set amphetamine popup.drawing=toggle)

sketchybar "${ARGS[@]}"
