#!/bin/bash

SSID="$(ipconfig getsummary en0 | awk -F' SSID : ' '{if ($2) print $2}')"

if [ -z "$SSID" ]; then
  ICON="󰖪"
  LABEL="N/A"
else
  ICON="󰖩"
  LABEL="$SSID"
fi

sketchybar --set "$NAME" icon="$ICON" label="$LABEL"
