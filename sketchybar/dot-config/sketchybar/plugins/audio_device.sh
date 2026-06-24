#!/bin/bash

# Run device detection in background to avoid blocking events
(
  CURRENT_DEVICE=$(SwitchAudioSource -c 2>/dev/null)

  if [ -z "$CURRENT_DEVICE" ]; then
    sketchybar --set audio_device label="--" icon.color=0xff565f89
    exit 0
  fi

  TRUNCATED="${CURRENT_DEVICE:0:15}"
  if [ ${#CURRENT_DEVICE} -gt 15 ]; then
    TRUNCATED="${TRUNCATED}…"
  fi

  DEVICE_COUNT=$(SwitchAudioSource -a -t output 2>/dev/null | wc -l | tr -d ' ')
  if [ "$DEVICE_COUNT" -gt 1 ]; then
    ICON_COLOR="0xff7aa2f7"
  else
    ICON_COLOR="0xff565f89"
  fi

  sketchybar --set audio_device label="$TRUNCATED" icon.color="$ICON_COLOR"
) &
