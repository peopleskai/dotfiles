#!/bin/bash

# Remove all old popup items in one shot via regex
sketchybar --remove '/audio_device\./' 2>/dev/null

DEVICES=$(SwitchAudioSource -a -t output 2>/dev/null)
if [ -z "$DEVICES" ]; then
  exit 0
fi

CURRENT=$(SwitchAudioSource -c 2>/dev/null)

# Build everything in one batch: add items + show popup
ARGS=()
while IFS= read -r DEVICE; do
  ITEM_NAME="audio_device.$(echo "$DEVICE" | tr ' ' '_' | tr -cd '[:alnum:]_')"

  if [ "$DEVICE" = "$CURRENT" ]; then
    ICON_COLOR="0xff9ece6a"
    LABEL_COLOR="0xffc0caf5"
  else
    ICON_COLOR="0xff565f89"
    LABEL_COLOR="0xffa9b1d6"
  fi

  ARGS+=(--add item "$ITEM_NAME" popup.audio_device)
  ARGS+=(--set "$ITEM_NAME"
    icon="󰓃"
    icon.color="$ICON_COLOR"
    label="$DEVICE"
    label.color="$LABEL_COLOR"
    click_script="SwitchAudioSource -s '$DEVICE'; sketchybar --set audio_device popup.drawing=off label='${DEVICE:0:15}'"
  )
done <<< "$DEVICES"

ARGS+=(--set audio_device popup.drawing=toggle)

sketchybar "${ARGS[@]}"
