#!/bin/bash

sketchybar --add item audio_device right \
  --set audio_device \
    icon="󰓃" \
    update_freq=5 \
    script="$PLUGIN_DIR/audio_device.sh" \
  --subscribe audio_device system_woke
