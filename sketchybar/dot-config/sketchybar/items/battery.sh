#!/bin/bash

sketchybar --add item battery right \
  --set battery \
    icon="󰁹" \
    update_freq=120 \
    script="$PLUGIN_DIR/battery.sh" \
  --subscribe battery power_source_change system_woke
