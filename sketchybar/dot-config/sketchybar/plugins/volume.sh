#!/bin/bash

if [ "$SENDER" = "mouse.clicked" ]; then
  osascript -e 'set volume output muted (not (output muted of (get volume settings)))'
  exit 0
fi

if [ "$SENDER" = "volume_change" ]; then
  VOLUME="$INFO"
else
  VOLUME=$(osascript -e 'output volume of (get volume settings)')
fi

MUTED=$(osascript -e 'output muted of (get volume settings)')

if [ "$MUTED" = "true" ]; then
  ICON="󰝟"
  ICON_COLOR="0xff565f89"
elif [ "$VOLUME" -ge 66 ]; then
  ICON="󰕾"
  ICON_COLOR="0xffc0caf5"
elif [ "$VOLUME" -ge 33 ]; then
  ICON="󰖀"
  ICON_COLOR="0xffc0caf5"
elif [ "$VOLUME" -ge 1 ]; then
  ICON="󰕿"
  ICON_COLOR="0xffc0caf5"
else
  ICON="󰝟"
  ICON_COLOR="0xff565f89"
fi

sketchybar --set "$NAME" icon="$ICON" icon.color="$ICON_COLOR" label="${VOLUME}%"
